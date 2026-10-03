// Regenerate bubbles (plan §Task 7b.1; Research note 45; Invariants 7, 18), transcribed from
// `_RegenerateBlocks @ 0001c3db`. The screen/background restores are presentation only.

extension GameState {
    /// `_RegenerateBlocks @ 0001c3db` (the type-2 bonus). Six attempts; each draws `(col, row) = (GetRandomFast(1,14),
    /// GetRandomFast(1,9))` (`char`s) and walks: pre-increment col; col > 14 → row + 1 and col 1, but row ≥ 10 → (1, 1)
    /// the first time and **give up this attempt** the second; cells on the hero's column or row are stepped over;
    /// the walk stops on a cell with `gMaze == 0` and `gMazeCopy == 10`. That cell becomes blue (15) below level 11,
    /// else `GetRandomFast(0,1)`: 0 → purple (16), 1 → blue (15). The cell rect inset by 3 → `_WasEnemySquished`
    /// (dead not tested, Invariant 7) → `_SquishEnemy(e, 1)`. `_SquishEnemy @ 0001131b` zeroes
    /// `gMaze[enemy col (+0x24) + enemy row (+0x30) · 16]` — the **enemy's** cell, not the new bubble's. Only when
    /// the enemy's col/row bytes name the bubble's cell (an enemy aligned on it) does the squish clear the bubble just
    /// placed, making that cell a candidate again for the remaining attempts. An enemy halfway between cells still
    /// overlaps the inset-3 rect (`_WasEnemySquished` is a strict rect overlap), so it is squished, but its own other
    /// cell is zeroed and the new bubble survives. A later attempt landing on the same cell hands the (now dead,
    /// still state-1) enemy out again and `_SquishEnemy` ignores it, so a re-placed bubble stays. All replicated.
    mutating func regenerateBlocks() {
        let currentLevel = level
        var attempts: Int8 = 6
        repeat {
            var col = Int8(truncatingIfNeeded: rng.fast(1, 0xe))
            var row = Int8(truncatingIfNeeded: rng.fast(1, 9))
            var wrapped = false
            var found = true
            walk: while true {
                repeat {
                    col &+= 1
                    if 0xe < col {
                        row &+= 1
                        if row < 0xa {
                            col = 1
                        } else {
                            if wrapped {
                                found = false
                                break walk          // LAB_0001c532
                            }
                            col = 1
                            row = 1
                            wrapped = true
                        }
                    }
                } while col == hero.col || row == hero.row
                if maze[Int(col), Int(row)] == CellCode.empty && mazeCopy[Int(col), Int(row)] == CellCode.normal {
                    break
                }
            }
            if found {
                if currentLevel < 0xb {
                    maze[Int(col), Int(row)] = CellCode.blue
                } else {
                    maze[Int(col), Int(row)] = rng.fast(0, 1) == 0 ? CellCode.purple : CellCode.blue
                }
                var r = QDRect.cell(col: Int(col), row: Int(row))
                r.inset(dx: 3, dy: 3)
                let e = wasEnemySquished(r)
                if e != -1 {
                    squishEnemy(e, count: 1)
                }
            }
            attempts -= 1
        } while attempts != 0
    }
}
