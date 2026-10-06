import Foundation
import HectorResources

/// The 0x80-byte segment-file header (data-format §1.1). Opaque to `TSegFile` (`ReadHeader` reads it whole);
/// the named fields are the ones the engine reads elsewhere:
/// +0x00 Pascal title; +0x40 i16 data-format version (0x1300, checked by `OpenScenFile` through
/// `CompatibleVersions`); +0x42 i16 scenario version (0x0200, matched by patch and player files);
/// +0x48 i16 maximum map dimension (0x0200; 0 means 0x400 to `InitWorld`). +0x20 is a player file's
/// character name; +0x44, +0x46, +0x4A–0x7F have no reader. All kept verbatim in `rawHeader`.
public struct SegmentFileHeader: Equatable, Sendable {
    public static let size = 0x80
    /// The title is a Str31: the field at +0x20 follows it (data-format §1.1).
    public static let maxTitleLength = 31

    public let title: String
    public let formatVersion: Int16
    public let scenarioVersion: Int16
    public let maxMapDimension: Int16
    /// The whole 0x80 bytes as stored (zero-based).
    public let rawHeader: Data

    /// `raw` must hold at least 0x80 bytes; only the first 0x80 are read.
    public init(raw: Data) throws {
        guard raw.count >= Self.size else { throw SegmentFileError.truncated(need: Self.size, have: raw.count) }
        let bytes = [UInt8](raw.prefix(Self.size))
        let titleLength = Int(bytes[0])
        guard titleLength <= Self.maxTitleLength else { throw SegmentFileError.titleTooLong(titleLength) }
        title = MacRoman.decode(bytes[1..<(1 + titleLength)])
        func i16(_ o: Int) -> Int16 { Int16(bitPattern: UInt16(bytes[o]) << 8 | UInt16(bytes[o + 1])) }
        formatVersion = i16(0x40)
        scenarioVersion = i16(0x42)
        maxMapDimension = i16(0x48)
        rawHeader = Data(bytes)
    }
}
