/// 0xF004, the tile names (data-format §5, HIGH): {u16 last-tile-of-range, C string}… ended by an id > 0x2000
/// (0x7FFF shipped). A tile without its own entry takes the next higher entry's name (`GetTileName`). The
/// strings keep their `/` (plural-only) and `\` (singular-only) markers for `SingPlur__FPcPcUc` (Phase 1).
/// Bytes after the terminator have no reader and are kept in `trailing` (6 shipped).
public struct TileNameTable: Equatable, Sendable {
    public struct Entry: Equatable, Sendable {
        public let lastTile: UInt16
        public let name: String
    }
    public let entries: [Entry]
    /// The terminating id (> 0x2000).
    public let terminator: UInt16
    /// Byte offset of the terminating id.
    public let terminatorOffset: Int
    /// The unread bytes after the terminator.
    public let trailing: [UInt8]

    init(entries: [Entry], terminator: UInt16, terminatorOffset: Int, trailing: [UInt8]) {
        self.entries = entries; self.terminator = terminator
        self.terminatorOffset = terminatorOffset; self.trailing = trailing
    }

    /// The name of tile `t`: the first entry whose last tile is ≥ t; nil past the last entry.
    public func name(forTile t: Int) -> String? {
        entries.first { Int($0.lastTile) >= t }?.name
    }
}
