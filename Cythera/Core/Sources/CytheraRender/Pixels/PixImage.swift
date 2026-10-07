import Foundation
import CytheraCore

/// Pix image n = segment 0x8F00 + n — backdrop patterns (0x8F00+, `LoadPattern__13TBackdropWindFv`) and
/// status-window artwork (0x8F80+, `__ct__13TStatusWindowFv`): {u16 w, u16 h} big-endian, then an LZ stream
/// (data-format §1.5, HIGH). **Rows are padded to a multiple of 4 bytes**: the stream decodes to
/// `((w + 3) & ~3) × h` bytes in all 59 shipped images (plan Research note 6, Bank correction 2 — corrects
/// §1.5's implied w × h; 11 of the 59 have w % 4 ≠ 0). Decoded as the original reads it: `rowBytes` keeps the
/// padding.
public struct PixImage: Equatable, Sendable {
    public let number: Int
    public let image: IndexedImage

    /// Pix image n, 0…0xFF; an absent segment throws `.absent`.
    public init(number n: Int, file: SegmentFile) throws {
        guard (0...0xFF).contains(n) else { throw PixelError.number("pix", n) }
        let id = UInt16(0x8F00 + n)
        number = n
        image = try Self.decode(try PixelSegments.segment(id, in: file), id: id)
    }

    /// One pix segment: the header, then exactly `((w+3)&~3) × h` LZ bytes consuming the rest of the segment.
    public static func decode(_ data: Data, id: UInt16) throws -> IndexedImage {
        let b = [UInt8](data.prefix(4))
        guard b.count == 4 else { throw PixelError.shortHeader(id) }
        let w = Int(b[0]) << 8 | Int(b[1]), h = Int(b[2]) << 8 | Int(b[3])
        guard w > 0, h > 0 else { throw PixelError.header(id) }
        let rowBytes = (w + 3) & ~3
        let pixels = try PixelSegments.unLZ(data.dropFirst(4), id: id, expected: rowBytes * h)
        return try IndexedImage(width: w, height: h, rowBytes: rowBytes, pixels: pixels)
    }
}
