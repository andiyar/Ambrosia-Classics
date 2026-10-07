import Foundation

public enum PropSegmentError: Error, Equatable, Sendable {
    /// Segment 0x8100 + L is absent (0x8125 in the shipped data).
    case absent(UInt16)
    /// A level outside 0...0xFF (ids 0x8100–0x81FF); refused, not wrapped.
    case levelOutOfRange(Int)
    /// A segment whose length is not a whole number of 16-byte records (`LoadLevelProps` counts `len >> 4`).
    case lengthNotMultipleOf16(Int)
}

/// A level's props, segment 0x8100 + L (data-format §4.1–§4.2, HIGH): `len >> 4` records that `LoadLevelProps`
/// copies to global prop index 0x100 on.
public struct PropSegment: Sendable {
    public let records: [PropRecord]

    public init(file: some SegmentStore, level: Int) throws {
        guard (0...0xFF).contains(level) else { throw PropSegmentError.levelOutOfRange(level) }
        let id = UInt16(0x8100 + level)
        guard let data = file.segment(id) else { throw PropSegmentError.absent(id) }
        try self.init(data: data)
    }

    /// Parses one prop segment (any start index). Every shipped length is a multiple of 16; others are refused
    /// (Invariant 4) rather than truncated as `len >> 4` would.
    public init(data: Data) throws {
        guard data.count % PropRecord.size == 0 else { throw PropSegmentError.lengthNotMultipleOf16(data.count) }
        let b = [UInt8](data)
        records = stride(from: 0, to: b.count, by: PropRecord.size).map {
            PropRecord(record: b[$0..<($0 + PropRecord.size)])
        }
    }
}
