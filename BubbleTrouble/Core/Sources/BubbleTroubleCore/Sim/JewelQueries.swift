// Jewel queries (plan §Task 5a.1, B1 — Task 6's push table and Task 8's jewel movement call them), transcribed from
// `_IsTargetJewelFound @ 0001c9b9`, `_IsJewelTheTarget @ 0001c8fb`, `_IsJewelTheDistantTarget @ 0001c95a`.

extension GameState {
    /// (`gTargetJewelXLoc`, `gTargetJewelYLoc`) as the original's `char` bytes; `nil` is (0xff, 0xff) = (−1, −1).
    private var targetJewelBytes: CellRef {
        targetJewel ?? CellRef(col: -1, row: -1)
    }

    /// `_IsTargetJewelFound @ 0001c9b9`: returns `gJewelFound`.
    func isTargetJewelFound() -> Bool {
        jewelFound
    }

    /// `_IsJewelTheTarget(dir, col, row) @ 0001c8fb`: false unless `gJewelFound`; steps (col, row) one cell in `dir`
    /// (3 → col − 1, 4 → col + 1, 1 → row − 1, 2 → row + 1, `char` arithmetic) and returns whether that cell is the
    /// target jewel.
    func isJewelTheTarget(_ dir: Direction, col: Int8, row: Int8) -> Bool {
        jewelTargetStep(dir, col: col, row: row, by: 1)
    }

    /// `_IsJewelTheDistantTarget(dir, col, row) @ 0001c95a`: as `isJewelTheTarget`, two cells.
    func isJewelTheDistantTarget(_ dir: Direction, col: Int8, row: Int8) -> Bool {
        jewelTargetStep(dir, col: col, row: row, by: 2)
    }

    private func jewelTargetStep(_ dir: Direction, col: Int8, row: Int8, by step: Int8) -> Bool {
        guard jewelFound else { return false }
        var col = col, row = row
        switch dir {
        case .left: col &-= step
        case .right: col &+= step
        case .up: row &-= step
        case .down: row &+= step
        }
        let target = targetJewelBytes
        return col == target.col && row == target.row
    }
}
