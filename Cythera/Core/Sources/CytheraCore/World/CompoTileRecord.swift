/// One 0x20-byte 0xF013 compo-tile record, 4×4 u16 entries (data-format §3.4, HIGH): each entry picks an 8×8
/// quadrant of a source tile — `BuildCompoTile__FPUcP15CompoTileRecord @ 100051a8`, entry bits 0–11 the tile,
/// bits 12–13 the quadrant row, bits 14–15 the quadrant column. Pixels are CytheraRender's (C5).
public struct CompoTileRecord: Equatable, Sendable {
    public static let size = 0x20
    /// 16 entries, row-major.
    public let entries: [UInt16]
    init(entries: [UInt16]) { self.entries = entries }
    public var isEmpty: Bool { entries.allSatisfy { $0 == 0 } }
}
