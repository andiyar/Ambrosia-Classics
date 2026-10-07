/// One map cell, a big-endian u16, row-major `cell = map[y*W + x]` (data-format §3.2, HIGH).
public struct MapCell: Equatable, Sendable {
    public let raw: UInt16
    public init(_ raw: UInt16) { self.raw = raw }

    /// Bits 0–11: the tile index (0..0xFFF; 0..0x9FF have pixels). For a compo cell, the CompoTileRecord index.
    public var tile: Int { Int(raw & 0x0FFF) }
    /// Bit 12 (0x1000): compo tile — the low 12 bits index a `CompoTileRecord` in 0xF013
    /// (`MaskAnyTile__7TViewerFUsll @ 10063b9c`).
    public var isCompo: Bool { raw & 0x1000 != 0 }
    /// The CompoTileRecord index of a compo cell, else nil.
    public var compoIndex: Int? { isCompo ? Int(raw & 0x0FFF) : nil }
    /// Bit 13 (0x2000): draw the transposed (diagonally flipped) tile — render.md §2.3 (no shipped cell has it).
    public var isTransposed: Bool { raw & 0x2000 != 0 }
    /// Bit 15 (0x8000): "seen" (automap), runtime only, restored from 0x8200+L by `LoadLevelMap`.
    public var isSeen: Bool { raw & 0x8000 != 0 }
}
