import Foundation
import CytheraCore

/// Portrait p (1-based) = segment 0x87FF + p, LZ → 64×64 8-bit, drawn by `DrawPortrait__Fssss @ 100086c4`
/// with `CopyBits` at rowBytes 0x40 (data-format §6.2 / §1.5, HIGH). 142 ship, p = 1…251 with 109 gaps (p03).
public struct Portrait: Equatable, Sendable {
    public static let side = 64

    /// The segment id of portrait p.
    public static func segmentID(_ p: Int) -> UInt16 { UInt16(truncatingIfNeeded: 0x87FF + p) }

    public let number: Int
    public let image: IndexedImage

    /// Portrait p, 1…256 (the ids 0x8800…0x88FF); an absent segment throws `.absent`.
    public init(number p: Int, file: SegmentFile) throws {
        guard (1...256).contains(p) else { throw PixelError.number("portrait", p) }
        let id = Self.segmentID(p)
        let pixels = try PixelSegments.unLZ(try PixelSegments.segment(id, in: file), id: id,
                                            expected: Self.side * Self.side)
        number = p
        image = try IndexedImage(width: Self.side, height: Self.side, rowBytes: Self.side, pixels: pixels)
    }
}
