import Foundation

/// Why a TGA (`im16`) was refused. Every case is a shape the shipped 45 TGAs never show
/// (plan Research note 19); the original's QuickTime importer would have tried them anyway.
public enum TGAError: Error, Equatable, Sendable {
    /// Fewer than the 18 header bytes.
    case truncatedHeader(Int)
    /// Image type other than 2 (uncompressed true-colour). RLE (10), colour-mapped (1/9) and
    /// greyscale (3/11) never ship.
    case unsupportedImageType(UInt8)
    /// Colour-map type other than 0. (With type 0 the colour-map *spec* bytes are ignored — 18 of
    /// the 45 shipped files carry a stray `0x18` there, plan Known delta 3.)
    case unsupportedColorMapType(UInt8)
    /// Pixel depth other than 16. The original logs "FILE WARNING: unsupported pixel depth (%i)"
    /// and imports anyway (sprite-manager-resource-image.md §6.1 step 3); refused here (plan invariant 4).
    case unsupportedPixelDepth(UInt8)
    /// Descriptor attribute bits (0–3) other than 0 or 1 for a 16-bit A1R5G5B5 image.
    case unsupportedAttributeBits(UInt8)
    /// Descriptor bits 6–7 (interleaving) set; carries the whole descriptor byte.
    case unsupportedInterleave(UInt8)
    /// Descriptor bit 4 set (pixels stored right-to-left).
    case rightToLeft
    /// Width or height 0 (the original's NewGWorld would fail).
    case emptyImage(width: Int, height: Int)
    /// `18 + idLength + 2·w·h` exceeds the file size.
    case truncatedPixels(needed: Int, available: Int)
}

/// An `im16` tag: a 16-bit Truevision TGA decoded to the buffer the original's GWorld held.
///
/// The original (`FUN_10020f00`, U_Image.cc; sprite-manager-resource-image.md §6.1) hands the file to
/// QuickTime's `'grip'`/`'TGA '` graphics importer and draws it into a 16-bit GWorld at the file's
/// own size; the game itself never flips rows. The shipped files all have descriptor `0x01`
/// (bit 5 = 0, rows stored bottom-up), and the title screen read upright on the Mac, so QuickTime
/// honoured bit 5 — **row 0 of `pixels` is the visual top** [MED, one inferred link: INDEX #10, the
/// title-screen check is Ben's eye item]. The media-mask lookup (`FUN_1000fee0`, §6.2) indexes
/// `pixels[(y/5)·w + x/5]` in these same top-down coordinates, and map and mask are stored in the
/// same orientation (§6.3), so a replica is consistent either way.
///
/// Pixels are little-endian A1R5G5B5 in the file; `pixels` holds QuickDraw x1R5G5B5 with bit 15
/// cleared (no shipped pixel has it set, plan note 19). Anything after the pixel block (the 26-byte
/// TGA 2.0 footer on 14 files) is ignored.
public struct TGAImage: Sendable, Equatable {
    public let width: Int
    public let height: Int
    /// `width × height` RGB555, row-major, row 0 = visual top.
    public let pixels: [UInt16]

    public init(data: Data) throws {
        let count = data.count
        guard count >= 18 else { throw TGAError.truncatedHeader(count) }
        let base = data.startIndex
        func byte(_ i: Int) -> UInt8 { data[base + i] }
        func le16(_ i: Int) -> Int { Int(byte(i)) | Int(byte(i + 1)) << 8 }

        let idLength = Int(byte(0))
        let colorMapType = byte(1)
        let imageType = byte(2)
        let w = le16(12), h = le16(14)
        let bpp = byte(16)
        let descriptor = byte(17)

        guard imageType == 2 else { throw TGAError.unsupportedImageType(imageType) }
        guard colorMapType == 0 else { throw TGAError.unsupportedColorMapType(colorMapType) }
        guard bpp == 16 else { throw TGAError.unsupportedPixelDepth(bpp) }
        guard descriptor & 0x0F <= 1 else { throw TGAError.unsupportedAttributeBits(descriptor & 0x0F) }
        guard descriptor & 0xC0 == 0 else { throw TGAError.unsupportedInterleave(descriptor) }
        guard descriptor & 0x10 == 0 else { throw TGAError.rightToLeft }
        guard w > 0, h > 0 else { throw TGAError.emptyImage(width: w, height: h) }

        let start = 18 + idLength
        let needed = start + 2 * w * h          // ≤ 18 + 255 + 2·65535² — no overflow on 64-bit
        guard needed <= count else { throw TGAError.truncatedPixels(needed: needed, available: count) }

        let topDown = descriptor & 0x20 != 0
        var out = [UInt16](repeating: 0, count: w * h)
        data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            out.withUnsafeMutableBufferPointer { dst in
                for storedRow in 0..<h {
                    let row = topDown ? storedRow : h - 1 - storedRow
                    var src = start + storedRow * w * 2
                    var d = row * w
                    for _ in 0..<w {
                        dst[d] = (UInt16(raw[src]) | UInt16(raw[src + 1]) << 8) & 0x7FFF
                        src += 2
                        d += 1
                    }
                }
            }
        }
        width = w
        height = h
        pixels = out
    }
}
