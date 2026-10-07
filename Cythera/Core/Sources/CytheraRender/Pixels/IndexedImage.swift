import Foundation
import CytheraCore

/// Why a pixel segment or picture did not decode (plan Invariants 4–5: named errors, never a trap).
public enum PixelError: Error, Equatable, Sendable {
    /// The segment is absent (TOC length 0, data-format §1.1).
    case absent(UInt16)
    /// The segment's (decoded) length is not the one its layout requires.
    case length(id: UInt16, expected: Int, actual: Int)
    /// The LZ stream ended before the segment did, or ran past it (all 378 shipped streams consume exactly, p04).
    case consumed(id: UInt16, expected: Int, actual: Int)
    /// The LZ stream is malformed.
    case lz(id: UInt16, LZError)
    /// A pix header with a zero dimension.
    case header(UInt16)
    /// A number outside the band's id range (e.g. portrait 0, sky 256).
    case number(String, Int)
    /// A compo-tile entry naming a tile past the store's 0xA00.
    case tileOutOfRange(Int)
    /// A compo-tile record that is not 16 entries.
    case compoEntries(Int)
    /// An image whose buffer does not match its dimensions.
    case image(String)
    /// A resource the caller asked for is not in the file.
    case missingResource(String)
}

/// An 8-bit indexed image: one byte per pixel, `rowBytes` per row (≥ width; the pix images pad rows to a
/// multiple of 4 — plan Research note 6), `pixels.count == rowBytes × height`. Index 0 is an ordinary colour
/// here; transparency is a blitter rule (engine-classes §5, plan S3).
public struct IndexedImage: Equatable, Sendable {
    public let width: Int
    public let height: Int
    public let rowBytes: Int
    public let pixels: [UInt8]

    public init(width: Int, height: Int, rowBytes: Int, pixels: [UInt8]) throws {
        guard width > 0, height > 0, rowBytes >= width else {
            throw PixelError.image("\(width)×\(height) rowBytes \(rowBytes)")
        }
        let (size, overflow) = rowBytes.multipliedReportingOverflow(by: height)
        guard !overflow, pixels.count == size else {
            throw PixelError.image("\(width)×\(height) rowBytes \(rowBytes) has \(pixels.count) bytes")
        }
        self.width = width; self.height = height; self.rowBytes = rowBytes; self.pixels = pixels
    }

    /// The pixel at (x, y); nil outside the image (row padding is outside).
    public func pixel(x: Int, y: Int) -> UInt8? {
        guard x >= 0, y >= 0, x < width, y < height else { return nil }
        return pixels[y * rowBytes + x]
    }
}

/// Shared segment readers for the LZ bands (data-format §1.5, §2).
enum PixelSegments {
    /// The segment's bytes, or `.absent`.
    static func segment(_ id: UInt16, in file: SegmentFile) throws -> Data {
        guard let data = file.segment(id) else { throw PixelError.absent(id) }
        return data
    }

    /// LZ-decodes `data` (a whole segment, or its tail after a header) and requires exactly `expected` bytes out
    /// and the whole input consumed — the shape all 378 shipped streams have (p04; Invariant 4).
    static func unLZ(_ data: Data, id: UInt16, expected: Int) throws -> [UInt8] {
        let decoded: (bytes: [UInt8], consumed: Int)
        do { decoded = try LZ.decode(data) } catch let e as LZError { throw PixelError.lz(id: id, e) }
        guard decoded.bytes.count == expected else {
            throw PixelError.length(id: id, expected: expected, actual: decoded.bytes.count)
        }
        guard decoded.consumed == data.count else {
            throw PixelError.consumed(id: id, expected: data.count, actual: decoded.consumed)
        }
        return decoded.bytes
    }
}
