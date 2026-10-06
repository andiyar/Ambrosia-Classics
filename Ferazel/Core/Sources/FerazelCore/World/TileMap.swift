/// One `Mlvl` tile map: `width × height` raw big-endian u16 cells, row-major (`cell = map[row·w + col]`;
/// world-data §3.3). Reads take **(column, row)** and clamp both into the map as `.ConstrainXY @ 1003be0c`
/// does (no wrap). Cell meaning is per map — decoded by `LevelFile`'s accessors.
public struct TileMap: Sendable, Equatable {
    public let width: Int
    public let height: Int
    public let cells: [UInt16]

    public init(width: Int, height: Int, cells: [UInt16]) {
        precondition(width >= 0 && height >= 0 && cells.count == width * height, "TileMap \(width)×\(height)")
        self.width = width
        self.height = height
        self.cells = cells
    }

    /// The raw cell at (col, row), both clamped into 0..width−1 / 0..height−1. An empty map reads 0.
    public func cell(col: Int, row: Int) -> UInt16 {
        guard width > 0, height > 0 else { return 0 }
        let c = min(max(col, 0), width - 1)
        let r = min(max(row, 0), height - 1)
        return cells[r * width + c]
    }
}
