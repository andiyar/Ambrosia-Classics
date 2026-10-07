import Foundation
import CytheraCore

/// Sky strip n = segment 0x8400 + n, LZ → 288×32 8-bit, loaded by `ChangeOutdoor__13TStatusWindowFUcs`
/// (`LoadPixs(…, 0x120, 0x20)`; data-format §1.5, engine-classes §3.3 — HIGH). 18 ship (p03, p04).
public struct SkyStrip: Equatable, Sendable {
    public static let width = 288
    public static let height = 32

    public let number: Int
    public let image: IndexedImage

    /// Sky strip n, 0…0xFF; an absent segment throws `.absent`.
    public init(number n: Int, file: SegmentFile) throws {
        guard (0...0xFF).contains(n) else { throw PixelError.number("sky", n) }
        let id = UInt16(0x8400 + n)
        let pixels = try PixelSegments.unLZ(try PixelSegments.segment(id, in: file), id: id,
                                            expected: Self.width * Self.height)
        number = n
        image = try IndexedImage(width: Self.width, height: Self.height, rowBytes: Self.width, pixels: pixels)
    }
}
