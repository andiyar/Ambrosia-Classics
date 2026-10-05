import BubbleTroubleCore
import Foundation

/// A 32-bit offscreen buffer in the App's present format: one `UInt32` per pixel reading 0xAARRGGBB,
/// row 0 = TOP, row-major — the same layout as HectorShell `ShellBitmap.pixels` (k = 1), so the App can
/// present `Compositor.screen` with one copy (plan S2). Decoded art (cicn, PICT) is converted to this
/// format once, with the decoder's alpha kept in the top byte (cicn: mask; PICT: region/matte or 0xFF).
public struct RGBAImage: Equatable, Sendable {
    public let width: Int
    public let height: Int
    /// `width * height` pixels, 0xAARRGGBB, top row first.
    public var pixels: [UInt32]

    public static let opaqueBlack: UInt32 = 0xFF00_0000
    public static let opaqueWhite: UInt32 = 0xFFFF_FFFF

    public init(width: Int, height: Int, fill: UInt32 = opaqueBlack) {
        precondition(width > 0 && height > 0, "RGBAImage needs a positive size, got \(width)×\(height)")
        self.width = width
        self.height = height
        pixels = Array(repeating: fill, count: width * height)
    }

    /// From decoder bytes R,G,B,A (top row first): HectorGraphics `CIcon.rgba` / `PICT.rgba`.
    /// `forceOpaque` sets every alpha to 0xFF (a plain raster PICT: QuickDraw ignores the 4th component).
    public init(width: Int, height: Int, rgba: Data, forceOpaque: Bool = false) {
        precondition(rgba.count == width * height * 4, "RGBA byte count \(rgba.count) ≠ \(width)×\(height)×4")
        self.width = width
        self.height = height
        var out = [UInt32](repeating: 0, count: width * height)
        rgba.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            let b = raw.bindMemory(to: UInt8.self)
            for i in 0..<(width * height) {
                let a: UInt32 = forceOpaque ? 0xFF : UInt32(b[4 * i + 3])
                out[i] = a << 24 | UInt32(b[4 * i]) << 16 | UInt32(b[4 * i + 1]) << 8 | UInt32(b[4 * i + 2])
            }
        }
        pixels = out
    }

    public subscript(h: Int, v: Int) -> UInt32 {
        get { pixels[v * width + h] }
        set { pixels[v * width + h] = newValue }
    }

    /// The whole buffer as a `QDRect` (0, 0, height, width).
    public var bounds: QDRect {
        QDRect(top: 0, left: 0, bottom: Int16(truncatingIfNeeded: height), right: Int16(truncatingIfNeeded: width))
    }

    /// FNV-1a (64-bit) over the pixels' little-endian bytes — the golden fingerprint of a buffer.
    public var fnv1a: UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for p in pixels {
            var v = p
            for _ in 0..<4 {
                hash ^= UInt64(v & 0xFF)
                hash = hash &* 0x0000_0100_0000_01B3
                v >>= 8
            }
        }
        return hash
    }
}
