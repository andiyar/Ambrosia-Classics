import Foundation

/// The window's x1R5G5B5 pixels → 32-bit 0xAARRGGBB for the shell (`ShellBitmap.pixels`, row 0 top, alpha 0xFF).
/// Each 5-bit channel widens by bit replication, `(c << 3) | (c >> 2)` (plan S4); bit 15 is ignored.
public enum ScreenRGBA {
    /// Writes `screen.width × screen.height` words to `out`.
    public static func convert(_ screen: Pixmap555, into out: UnsafeMutablePointer<UInt32>) {
        screen.pixels.withUnsafeBufferPointer { src in
            for i in 0..<src.count {
                let p = UInt32(src[i])
                let r = (p >> 10) & 31, g = (p >> 5) & 31, b = p & 31
                out[i] = 0xFF00_0000
                    | (((r << 3) | (r >> 2)) << 16)
                    | (((g << 3) | (g >> 2)) << 8)
                    | ((b << 3) | (b >> 2))
            }
        }
    }
}
