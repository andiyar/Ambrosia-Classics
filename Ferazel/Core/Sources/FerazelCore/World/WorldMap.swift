import Foundation
import HectorResources

/// `Mmap 200` — the world-map graph (world-data §4.2): 128 node slots of 0x128 bytes, then 256 zero bytes
/// (38,144 B). A resource of any other length is refused.
public struct WorldMap: Sendable, Equatable {
    public static let slotCount = 128
    public static let slotSize = 0x128
    public static let tailSize = 256
    public static let length = slotCount * slotSize + tailSize

    /// One existing node (slot byte +0x000 ≠ 0).
    public struct Node: Sendable, Equatable {
        /// Slot index (the link value other nodes use).
        public let index: Int
        /// +0x001 pstr — empty in the data (names come from `STR# 1000`).
        public let name: String
        /// +0x102 — level entered from this node (`.ShowWorldMap`'s return value).
        public let level: Int16
        /// +0x104 / +0x106 — map position v, h (px within the 608×384 map PICT).
        public let v: Int16
        public let h: Int16
        /// +0x108 — the seven link slots as stored (node indices; 0 = none).
        public let links: [Int16]
        /// +0x116 — node face (1 on the boss nodes).
        public let face: Int16
    }

    /// Existing nodes in slot order.
    public let nodes: [Node]
    /// The 256 bytes after the last slot (zero in the data).
    public let tail: [UInt8]

    public init(id: Int16 = 200, data: Data) throws {
        let b = BigEndianBytes(data, type: "Mmap", id: id)
        guard b.count == Self.length else {
            throw WorldDataError.wrongLength(type: "Mmap", id: id, expected: Self.length, actual: b.count)
        }
        var nodes: [Node] = []
        for i in 0..<Self.slotCount {
            let o = i * Self.slotSize
            guard try b.u8(o) != 0 else { continue }
            nodes.append(Node(index: i, name: try b.pascalString(at: o + 0x001), level: try b.i16(o + 0x102),
                              v: try b.i16(o + 0x104), h: try b.i16(o + 0x106),
                              links: try b.i16Array(at: o + 0x108, count: 7), face: try b.i16(o + 0x116)))
        }
        self.nodes = nodes
        self.tail = Array(b.bytes[(Self.slotCount * Self.slotSize)...])
    }

    /// `Mmap <id>` (200 in the shipped game) from World Data (`.OpenDefaultWorldMap`).
    public static func load(from resources: FerazelResources, id: Int16 = 200) throws -> WorldMap {
        guard let r = resources.world.resource(type: "Mmap", id: id) else {
            throw WorldDataError.missing(type: "Mmap", id: id)
        }
        return try WorldMap(id: r.id, data: r.data)
    }
}
