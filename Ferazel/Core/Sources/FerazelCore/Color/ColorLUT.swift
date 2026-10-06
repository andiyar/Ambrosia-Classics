import Foundation
import HectorResources

public enum ColorLUTError: Error, Equatable {
    /// The `clut` is shorter than its header or its declared entries.
    case truncated(id: Int16, bytes: Int)
    /// The `clut` does not hold 256 entries (every shipped one does; plan invariant 6).
    case entryCount(id: Int16, count: Int)
    /// No `clut` of that id on the chain.
    case missing(id: Int16)
    /// A non-zero `ctFlags` (every shipped `clut` has 0; plan invariant 6).
    case unexpectedFlags(id: Int16, flags: UInt16)
}

/// A `clut` resource (QuickDraw ColorTable, big-endian): `ctSeed` u32, `ctFlags` u16, `ctSize` i16 (count − 1),
/// then `ctSize + 1` ColorSpecs of (value, red, green, blue) u16 (sprites-backgrounds §4, lighting-tables §1).
/// `entries` carry each value field rewritten to its index, as `.SetScreenClut @ 1000faa8` does before
/// `SetEntries` (lighting-tables §1.2); the values as stored stay in `storedValues`.
public struct ColorLUT: Sendable, Equatable {
    /// One ColorSpec. Channels are 16-bit QuickDraw RGB.
    public struct Entry: Sendable, Equatable {
        public var value: UInt16
        public var red: UInt16
        public var green: UInt16
        public var blue: UInt16

        public init(value: UInt16, red: UInt16, green: UInt16, blue: UInt16) {
            self.value = value
            self.red = red
            self.green = green
            self.blue = blue
        }

        /// The colour without the value field.
        public var rgb: [UInt16] { [red, green, blue] }
    }

    public static let entryCount = 256

    public let id: Int16
    public let name: String?
    public let seed: UInt32
    public let flags: UInt16
    /// 256 entries, `value` == index (the `.SetScreenClut` rewrite).
    public let entries: [Entry]
    /// The value fields as stored in the resource.
    public let storedValues: [UInt16]

    public init(id: Int16, name: String?, data: Data) throws {
        let b = [UInt8](data)
        func u16(_ o: Int) -> UInt16 { UInt16(b[o]) << 8 | UInt16(b[o + 1]) }
        guard b.count >= 8 else { throw ColorLUTError.truncated(id: id, bytes: b.count) }
        let count = Int(Int16(bitPattern: u16(6))) + 1
        guard count == Self.entryCount else { throw ColorLUTError.entryCount(id: id, count: count) }
        guard u16(4) == 0 else { throw ColorLUTError.unexpectedFlags(id: id, flags: u16(4)) }
        guard b.count >= 8 + count * 8 else { throw ColorLUTError.truncated(id: id, bytes: b.count) }
        self.id = id
        self.name = name
        seed = UInt32(u16(0)) << 16 | UInt32(u16(2))
        flags = u16(4)
        var stored: [UInt16] = []
        var out: [Entry] = []
        stored.reserveCapacity(count)
        out.reserveCapacity(count)
        for i in 0..<count {
            let o = 8 + i * 8
            stored.append(u16(o))
            out.append(Entry(value: UInt16(i), red: u16(o + 2), green: u16(o + 4), blue: u16(o + 6)))
        }
        storedValues = stored
        entries = out
    }

    public init(resource: Resource) throws {
        try self.init(id: resource.id, name: resource.name, data: resource.data)
    }

    /// `GetCTable(id)` along `chain` (first file holding the `clut`).
    public static func load(id: Int16, from resources: FerazelResources, chain: ResourceChain) throws -> ColorLUT {
        guard let r = resources.resource(type: "clut", id: id, chain: chain) else { throw ColorLUTError.missing(id: id) }
        return try ColorLUT(resource: r)
    }

    /// The level+base CLUT a level names: header `0x285e`, 0 → 202 (`.SetupLevel`; lighting-tables §1.1).
    public static func screenClutId(_ header: LevelHeader) -> Int16 {
        header.screenClut == 0 ? 202 : header.screenClut
    }
}
