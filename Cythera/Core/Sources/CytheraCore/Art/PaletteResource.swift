import Foundation

/// A `pltt` resource as stored (Palette Manager palette: pmEntries u16, 14 reserved bytes (pmDataFields), then
/// pmEntries × 16-byte `ColorInfo` {RGBColor 3 × u16, ciUsage u16, ciTolerance u16, 6 private bytes}). The one
/// shipped, `pltt 130` in `Cythera.rsrc`, has 256 entries (plan Research note 10, p07/p19). Counted and parsed
/// only: no reader of it is in the bank (plan S2) — the screen palette is `clut 256` (`ColorTableRecord`).
public struct PaletteResource: Equatable, Sendable {
    /// One `ColorInfo` as stored.
    public struct Entry: Equatable, Sendable {
        public let r: UInt16
        public let g: UInt16
        public let b: UInt16
        public let usage: UInt16
        public let tolerance: UInt16
        /// ciDataFields, 6 bytes as stored.
        public let privateFields: [UInt8]
    }

    /// pmEntries as stored.
    public let count: Int
    /// The 14 bytes after the count, as stored.
    public let reserved: [UInt8]
    public let entries: [Entry]

    /// Parses a `pltt`; the length must be exactly 16 + 16 × count, and count 0 is refused (Invariant 4).
    public init(data: Data) throws {
        let b = ArtBytes(data, type: "pltt")
        count = Int(try b.u16(0, "pmEntries"))
        guard count > 0 else { throw ArtRecordError.shape("pltt pmEntries 0") }
        try b.require(2, 14, "reserved")
        reserved = Array(b.bytes[2..<16])
        try b.require(16, 16 * count, "ColorInfo")
        guard b.count == 16 + 16 * count else {
            throw ArtRecordError.length("pltt", expected: 16 + 16 * count, actual: b.count)
        }
        var entries: [Entry] = []
        entries.reserveCapacity(count)
        for k in 0..<count {
            let o = 16 + 16 * k
            entries.append(Entry(r: try b.u16(o, "r"), g: try b.u16(o + 2, "g"), b: try b.u16(o + 4, "b"),
                                 usage: try b.u16(o + 6, "usage"), tolerance: try b.u16(o + 8, "tolerance"),
                                 privateFields: Array(b.bytes[(o + 10)..<(o + 16)])))
        }
        self.entries = entries
    }
}
