import Foundation
import CytheraCore

/// Portrait p (1-based) = segment 0x87FF + p, LZ → 64×64 8-bit, drawn by `DrawPortrait__Fssss @ 100086c4`
/// with `CopyBits` at rowBytes 0x40 (data-format §6.2 / §1.5, HIGH). 142 ship, p = 1…251 with 109 gaps (p03).
public struct Portrait: Equatable, Sendable {
    public static let side = 64
    /// The portrait numbers whose ids fall in the portrait page, 0x8800…0x88FF.
    public static let numbers: ClosedRange<Int> = 1...256

    /// The segment id of portrait p; p outside 1…256 is refused (`.number`), never wrapped.
    public static func segmentID(_ p: Int) throws -> UInt16 {
        guard numbers.contains(p) else { throw PixelError.number("portrait", p) }
        return UInt16(0x87FF + p)
    }

    public let number: Int
    public let image: IndexedImage

    /// Portrait p, 1…256; an absent segment throws `.absent`.
    public init(number p: Int, file: SegmentFile) throws {
        let id = try Self.segmentID(p)
        number = p
        image = try Self.decode(try PixelSegments.segment(id, in: file), id: id)
    }

    /// One portrait segment: exactly 4,096 LZ bytes consuming the whole segment.
    public static func decode(_ data: Data, id: UInt16) throws -> IndexedImage {
        let pixels = try PixelSegments.unLZ(data, id: id, expected: side * side)
        return try IndexedImage(width: side, height: side, rowBytes: side, pixels: pixels)
    }
}
