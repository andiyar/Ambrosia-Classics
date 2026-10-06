import Foundation
import FerazelCore
import HectorGraphics

public enum ConvertedPictureError: Error, Equatable {
    /// An indexed pixel whose value no entry of the picture's colour table claims.
    case noColorTableEntry(id: Int16, value: Int)
}

/// A `PICT` as the loaders leave it in their 8-bit port: one index per frame pixel under the conversion CLUT
/// (sprites-backgrounds §2 "Conversion path": `GetPicture`, then `DrawPicture` into the shared back port after
/// `.ChangeBlitPortClut(port, *_DAT_1009ff94)` when the frame fits 640×416, else into an 8-bit `NewGWorld` with
/// CTable `*_DAT_1009ff94`). QuickDraw's colour matching is modelled by `ColorSearch` (plan bank correction 1:
/// the sheets are not authored in the conversion CLUT, so every face index comes out of `Color2Index` [LOW]):
/// - indexed: once per colour-table value, its stored 16-bit RGB searched in the CLUT;
/// - DirectBits (mode 64 ditherCopy): per pixel, 8-bit components × 257, through `DitherModel`;
/// - a 1-bit v1 BitMap bypasses the search under every model: set bits → 0xff, clear bits → 0x00 (the FG
///   water mask 183 and the PxMid mask sheets need K == 0xFF exactly, rendering-omnipx-titles §1.2).
///
/// The shared back port's CLUT is `.ChangeBlitPortClut`'s copy of entries 0..254 only (lighting-tables §1.2);
/// entry 0xff is black in every conversion CLUT used (p06), so converting against all 256 entries is the same.
///
/// ⚠️ `DrawPicture` into the non-GWorld back port may match through the current GDevice's inverse table rather
/// than the port's CLUT (sprites-backgrounds §2) — the replica cannot tell which; the model stays a parameter.
public struct ConvertedPicture: Sendable, Equatable {
    public let id: Int16
    public let width: Int
    public let height: Int
    /// `width × height` indices, row-major from the frame's top-left.
    public let pixels: [UInt8]
    /// The conversion CLUT's id.
    public let clutId: Int16
    /// The source picFrame's top-left (`PictureSource.frameTop`/`frameLeft`).
    public let frameTop: Int16
    public let frameLeft: Int16

    public init(id: Int16, width: Int, height: Int, pixels: [UInt8], clutId: Int16, frameTop: Int16 = 0,
                frameLeft: Int16 = 0) {
        precondition(pixels.count == width * height, "pixels \(pixels.count) ≠ \(width)×\(height)")
        self.id = id; self.width = width; self.height = height; self.pixels = pixels; self.clutId = clutId
        self.frameTop = frameTop; self.frameLeft = frameLeft
    }

    public init(source: PictureSource, clut: ColorLUT, search: ColorSearch,
                dither: DitherModel = .errorDiffusion) throws {
        switch source.pixels {
        case .indexed(let p):
            guard let table = p.colorTable else {
                self.init(id: source.id, width: p.width, height: p.height,
                          pixels: p.pixels.map { $0 == 0 ? 0x00 : 0xff }, clutId: clut.id,
                          frameTop: source.frameTop, frameLeft: source.frameLeft)
                return
            }
            let prepared = search.prepared(for: clut)
            var map = [UInt8](repeating: 0, count: 256)
            var known = [Bool](repeating: false, count: 256)
            for v in 0..<256 {
                guard let c = table.rgb16(index: v) else { continue }
                map[v] = prepared.index(of: RGB16(c.r, c.g, c.b))
                known[v] = true
            }
            if let bad = p.pixels.first(where: { !known[Int($0)] }) {
                throw ConvertedPictureError.noColorTableEntry(id: source.id, value: Int(bad))
            }
            self.init(id: source.id, width: p.width, height: p.height, pixels: p.pixels.map { map[Int($0)] },
                      clutId: clut.id, frameTop: source.frameTop, frameLeft: source.frameLeft)
        case .direct(let p):
            let out = Dither.convert(rgb: p.rgb, width: p.width, height: p.height, clut: clut,
                                     search: search.prepared(for: clut), model: dither)
            self.init(id: source.id, width: p.width, height: p.height, pixels: out, clutId: clut.id,
                      frameTop: source.frameTop, frameLeft: source.frameLeft)
        }
    }

    /// The index at (x, y); 0 outside the frame (a cell reaching past the frame reads 0 there — design §11).
    @inline(__always) public func pixel(x: Int, y: Int) -> UInt8 {
        guard x >= 0, y >= 0, x < width, y < height else { return 0 }
        return pixels[y * width + x]
    }

    /// The rect's pixels row-major (`(right − left) × (bottom − top)`), 0 outside the frame.
    public func cell(_ rect: EncodedFace.Rect) -> [UInt8] {
        let w = Int(rect.right) - Int(rect.left), h = Int(rect.bottom) - Int(rect.top)
        var out = [UInt8](repeating: 0, count: max(0, w) * max(0, h))
        for y in 0..<max(0, h) {
            let sy = Int(rect.top) + y
            guard sy >= 0, sy < height else { continue }
            for x in 0..<max(0, w) {
                let sx = Int(rect.left) + x
                if sx >= 0, sx < width { out[y * w + x] = pixels[sy * width + sx] }
            }
        }
        return out
    }

    /// The number of the rect's rows that lie below the frame (0 when the rect fits).
    public func rowsPastFrame(_ rect: EncodedFace.Rect) -> Int {
        max(0, Int(rect.bottom) - max(height, Int(rect.top)))
    }

    /// The colours the conversion searches, with their pixel counts: the stored 16-bit RGB of each pixel's
    /// colour-table entry (indexed) or its components × 257 (DirectBits). Nil for a 1-bit BitMap (no search).
    public static func sourceColors(_ source: PictureSource) throws -> [RGB16: Int]? {
        var counts: [RGB16: Int] = [:]
        switch source.pixels {
        case .indexed(let p):
            guard let table = p.colorTable else { return nil }
            var perValue = [Int](repeating: 0, count: 256)
            for v in p.pixels { perValue[Int(v)] += 1 }
            for v in 0..<256 where perValue[v] > 0 {
                guard let c = table.rgb16(index: v) else {
                    throw ConvertedPictureError.noColorTableEntry(id: source.id, value: v)
                }
                counts[RGB16(c.r, c.g, c.b), default: 0] += perValue[v]
            }
        case .direct(let p):
            for i in 0..<(p.width * p.height) {
                counts[RGB16(UInt16(p.rgb[3 * i]) * 257, UInt16(p.rgb[3 * i + 1]) * 257,
                             UInt16(p.rgb[3 * i + 2]) * 257), default: 0] += 1
            }
        }
        return counts
    }
}
