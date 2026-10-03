// Rubber (blue/purple) block shutdown (plan §Task 8.1), transcribed from `_Blocks_DeactivateRubberBlocks @ 0001c2c7`.

extension GameState {
    /// `_Blocks_DeactivateRubberBlocks @ 0001c2c7`: every slot 0…34 with a non-zero state and type 15 or 16
    /// (`(byte)(type − 15) < 2`) → retired (freed by the draw pass — Invariant 8) and `gMaze[col + 16·row]` = type,
    /// at its col/row even when mid-cell. Neither the moving nor the retired flag is tested.
    mutating func blocksDeactivateRubberBlocks() {
        for i in blocks.indices where blocks[i].state != 0 {
            let type = blocks[i].type
            guard type == CellCode.blue || type == CellCode.purple else { continue }
            blocks[i].retired = true
            maze.cells[Int(blocks[i].col) + Int(blocks[i].row) * Maze.columns] = type
        }
    }
}
