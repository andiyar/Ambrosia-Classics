import Foundation

/// Why an art resource record did not parse (plan Invariants 4–5: malformed input throws, never traps; a shape
/// the census has not shown is refused by name).
public enum ArtRecordError: Error, Equatable, Sendable {
    /// The resource ended before a field the layout requires (`what` names the resource type and field).
    case truncated(String)
    /// The resource's length is not the one its own count fields imply.
    case length(String, expected: Int, actual: Int)
    /// A count or size field outside the measured corpus (`what` names it).
    case shape(String)
}

/// Big-endian reads over a resource's bytes (zero-based copy), every read bounds-checked.
struct ArtBytes {
    let bytes: [UInt8]
    let type: String

    init(_ data: Data, type: String) {
        bytes = [UInt8](data)
        self.type = type
    }

    var count: Int { bytes.count }

    func require(_ offset: Int, _ length: Int, _ field: String) throws {
        guard offset >= 0, length >= 0, length <= bytes.count - offset else {
            throw ArtRecordError.truncated("\(type) \(field)")
        }
    }

    func u8(_ offset: Int, _ field: String) throws -> UInt8 {
        try require(offset, 1, field)
        return bytes[offset]
    }

    func u16(_ offset: Int, _ field: String) throws -> UInt16 {
        try require(offset, 2, field)
        return UInt16(bytes[offset]) << 8 | UInt16(bytes[offset + 1])
    }

    func u32(_ offset: Int, _ field: String) throws -> UInt32 {
        try require(offset, 4, field)
        return UInt32(bytes[offset]) << 24 | UInt32(bytes[offset + 1]) << 16
            | UInt32(bytes[offset + 2]) << 8 | UInt32(bytes[offset + 3])
    }
}

/// A `clut` resource as stored (QuickDraw `ColorTable`: ctSeed u32, ctFlags u16, ctSize i16 = count − 1, then
/// count × `ColorSpec` {value u16, r16, g16, b16}) — 8 + 256 × 8 bytes for both shipped `clut 256`.
///
/// The game's palette is `GetCTable(0x100)` (engine-classes §5, ui-toolkit §0). **Two different `clut 256`
/// exist** — `Cythera.rsrc` and `Cythera Data.rsrc`, differing in entries 0, 16, 252, 253 (plan Research note 12,
/// p07/p19); which one the original's chain returned is MED (data file first by the lookup order). Every
/// consumer names which one it used (plan Landmine (f)); this record does not know its origin.
/// 251 (data) / 250 (app) entries are not byte-replicated 16-bit values (e.g. entry 1 = (0, 0, 0xA800)), so
/// the 8-bit colour is the HIGH byte of each channel, as QuickDraw's `Color2Index` table build uses it.
public struct ColorTableRecord: Equatable, Sendable {
    /// One `ColorSpec` as stored.
    public struct Entry: Equatable, Sendable {
        public let value: UInt16
        public let r: UInt16
        public let g: UInt16
        public let b: UInt16
        public init(value: UInt16, r: UInt16, g: UInt16, b: UInt16) {
            self.value = value; self.r = r; self.g = g; self.b = b
        }
    }

    public let seed: UInt32
    public let flags: UInt16
    /// ctSize + 1 entries in stored order (both shipped tables: values 0…255 ascending, so position = value).
    public let entries: [Entry]

    /// Parses a `clut`; the length must be exactly 8 + 8 × (ctSize + 1).
    public init(data: Data) throws {
        let b = ArtBytes(data, type: "clut")
        seed = try b.u32(0, "ctSeed")
        flags = try b.u16(4, "ctFlags")
        let ctSize = Int(Int16(bitPattern: try b.u16(6, "ctSize")))
        guard ctSize >= 0, ctSize <= 255 else { throw ArtRecordError.shape("clut ctSize \(ctSize)") }
        let count = ctSize + 1
        try b.require(8, 8 * count, "ColorSpecs")
        guard b.count == 8 + 8 * count else {
            throw ArtRecordError.length("clut", expected: 8 + 8 * count, actual: b.count)
        }
        var entries: [Entry] = []
        entries.reserveCapacity(count)
        for k in 0..<count {
            let o = 8 + 8 * k
            entries.append(Entry(value: try b.u16(o, "value"), r: try b.u16(o + 2, "r"),
                                 g: try b.u16(o + 4, "g"), b: try b.u16(o + 6, "b")))
        }
        self.entries = entries
    }

    /// The 8-bit colour of entry `index` by position (= value in both shipped tables): the high byte of each
    /// 16-bit channel. nil outside the table.
    public func rgb8(_ index: Int) -> (r: UInt8, g: UInt8, b: UInt8)? {
        guard index >= 0, index < entries.count else { return nil }
        let e = entries[index]
        return (UInt8(e.r >> 8), UInt8(e.g >> 8), UInt8(e.b >> 8))
    }
}
