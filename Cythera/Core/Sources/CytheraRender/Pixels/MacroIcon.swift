import Foundation
import CytheraCore

/// Macro icon n = segment 0x8A00 + n: 512 raw bytes (no LZ) = 32×16 8-bit, drawn by
/// `DrawAMacro__FR4RectsUc @ 100373a0` (data-format §1.5, engine-classes §5 — HIGH). 62 ship (p03, p04).
public struct MacroIcon: Equatable, Sendable {
    public static let width = 32
    public static let height = 16

    public let number: Int
    public let image: IndexedImage

    /// Macro icon n, 0…0xFF; an absent segment throws `.absent`.
    public init(number n: Int, file: SegmentFile) throws {
        guard (0...0xFF).contains(n) else { throw PixelError.number("macro icon", n) }
        let id = UInt16(0x8A00 + n)
        number = n
        image = try Self.decode(try PixelSegments.segment(id, in: file), id: id)
    }

    /// The segment's bytes as the image; the length must be exactly 512.
    public static func decode(_ data: Data, id: UInt16) throws -> IndexedImage {
        guard data.count == width * height else {
            throw PixelError.length(id: id, expected: width * height, actual: data.count)
        }
        return try IndexedImage(width: width, height: height, rowBytes: width, pixels: [UInt8](data))
    }
}
