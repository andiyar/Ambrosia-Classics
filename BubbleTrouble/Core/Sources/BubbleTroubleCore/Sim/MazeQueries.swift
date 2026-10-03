// Maze queries (plan §Task 5a.1): `_GetNextObject @ 00025f34`, `_GetDistantObject @ 00025fed`,
// `_NormalBlockCount @ 000260a8`, transcribed from the decompile.

extension GameState {
    /// `_GetNextObject(dir, col, row) @ 00025f34`: the maze byte one cell away in `dir`, or 0x32 (50, "wall", never
    /// stored) at the grid edge — down at row 10, up at row 0, left at col 0, right at col 15. Reads the flat
    /// `gMaze[col + 16·row ± 16 / ± 1]` exactly as the original does. (An unknown direction is the original's
    /// `_DebugValues` + `_CleanUp` quit; `Direction` cannot express one.)
    func getNextObject(_ dir: Direction, col: Int, row: Int) -> UInt8 {
        let offset: Int
        switch dir {
        case .down:
            if row == 10 { return CellCode.wall }
            offset = 0x10
        case .up:
            if row == 0 { return CellCode.wall }
            offset = -0x10
        case .left:
            if col == 0 { return CellCode.wall }
            offset = -1
        case .right:
            if col == 15 { return CellCode.wall }
            offset = 1
        }
        return flatMazeByte(col + row * 0x10 + offset)
    }

    /// `_GetDistantObject(dir, col, row) @ 00025fed`: the maze byte two cells away in `dir`. The original's only
    /// edge checks are down at row 9, up at row 1, left at col 1, right at col 14 → 0x32 (50). Any other position
    /// reads the flat `gMaze[col + 16·row ± 32 / ± 2]` unchecked — so right at col 15 reads the next row's col 1
    /// and left at col 0 the previous row's col 14 (replicated, Invariant 18). An index that falls outside the
    /// 176-byte maze (up at row 0, down at row 10, the two corner wraps) reads adjacent globals in the original
    /// (`gMenuStars` before, `gNumEnemiesActive`/`gNumNormalBlocks` after — `nm`); the replica returns 50 there
    /// (plan §Task 5a.1 "off-grid → 50").
    func getDistantObject(_ dir: Direction, col: Int, row: Int) -> UInt8 {
        let offset: Int
        switch dir {
        case .down:
            if row == 9 { return CellCode.wall }
            offset = 0x20
        case .up:
            if row == 1 { return CellCode.wall }
            offset = -0x20
        case .left:
            if col == 1 { return CellCode.wall }
            offset = -2
        case .right:
            if col == 14 { return CellCode.wall }
            offset = 2
        }
        return flatMazeByte(col + row * 0x10 + offset)
    }

    /// `gMaze[i]` as a flat 176-byte array; an index outside it is off-grid → 50 (see `getDistantObject`).
    private func flatMazeByte(_ i: Int) -> UInt8 {
        maze.cells.indices.contains(i) ? maze.cells[i] : CellCode.wall
    }

    /// `_NormalBlockCount @ 000260a8`: the number of normal bubbles (cell code 10) in all 11 × 16 cells of `gMaze`,
    /// as a `short`.
    func normalBlockCount() -> Int16 {
        var count: Int16 = 0
        for row in 0..<Maze.rows {
            for col in 0..<Maze.columns where maze.cells[col + row * Maze.columns] == CellCode.normal {
                count &+= 1
            }
        }
        return count
    }
}
