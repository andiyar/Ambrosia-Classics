// The per-frame block pass (plan §Task 8.1; Research note 37; Invariants 8, 9; bubbles-items-scoring.md §1.5),
// transcribed from `_ProcessBlocks @ 0001d2b8`. `_AddRectToBgnd` (dirty rects) and the sounds are not modelled.

extension GameState {
    /// `_ProcessBlocks @ 0001d2b8`. Nothing when `_gNumActiveBlocks` is 0. Per slot 0…34 with a non-zero state:
    /// `_MoveBlock` when moving; then by the type read **after** the move:
    /// - 40 (pop): frame + 1; `> 8` → retired, maze cell 0.
    /// - 30 (cluster): anim counter + 1; `> 4` → counter 0 and, with `gJewelAnimDir` 0, frame − 1 and `< 2` →
    ///   dir 1; with dir 1, frame + 1 and `> 3` → dir 0; on either turn, `gJewelsDone` → retired, frame 1.
    /// - 52 (dynamite), static only: maze cell = 52 every call; `start + 60 < frame` → `_ExplodeBombBlock`, else
    ///   anim counter + 1, `> 3` → counter 0, frame + 1, `> 3` → frame 2.
    /// - 60 (egg): state 3 → while `frame < start + w8`: anim counter + 1, `> 8` → counter 0 and the toggle flips;
    ///   toggle 0 → sprite set 0x11, frame 1, else 0x1f, frame = the egg enemy's type; otherwise state 4, start =
    ///   frame. Then state 4 and `start + popDelay(15) < frame` → type 40, state 2, start = frame, sprite set 0x18,
    ///   frame 1, maze cell 40.
    /// Timer compares promote to `Int` (Invariant 9).
    ///
    /// Then the block–block pass (§1.5) with a per-frame reversed flag per slot: for each i in state ≠ 0, moving,
    /// not retired, the first j > i in state ≠ 0, moving, not retired whose rect strictly overlaps → i reverses
    /// unless bouncing or already flagged, j likewise, then both are flagged (sound 0x14 not modelled).
    mutating func processBlocks() {
        var reversed = [Bool](repeating: false, count: Self.blockCapacity)
        guard numActiveBlocks != 0 else { return }
        for i in blocks.indices {
            guard blocks[i].state != 0 else { continue }
            if blocks[i].moving {
                moveBlock(i)
            }
            let cellIndex = Int(blocks[i].col) + Int(blocks[i].row) * Maze.columns
            switch blocks[i].type {
            case CellCode.popping:
                blocks[i].frame &+= 1
                if 8 < blocks[i].frame {
                    blocks[i].retired = true
                    maze.cells[cellIndex] = 0
                }
            case CellCode.cluster:
                blocks[i].animCounter &+= 1
                guard 4 < blocks[i].animCounter else { break }
                blocks[i].animCounter = 0
                var turned = false
                if !jewelAnimDir {
                    blocks[i].frame &-= 1
                    if blocks[i].frame < 2 {
                        jewelAnimDir = true
                        turned = true
                    }
                } else {
                    blocks[i].frame &+= 1
                    if 3 < blocks[i].frame {
                        jewelAnimDir = false
                        turned = true
                    }
                }
                if turned, jewelsDone {
                    blocks[i].retired = true
                    blocks[i].frame = 1
                }
            case CellCode.dynamite:
                guard !blocks[i].moving else { break }
                maze.cells[cellIndex] = CellCode.dynamite
                if Int(blocks[i].startFrame) + 0x3c < Int(frame) {
                    explodeBombBlock(i)
                } else {
                    blocks[i].animCounter &+= 1
                    if 3 < blocks[i].animCounter {
                        blocks[i].animCounter = 0
                        blocks[i].frame &+= 1
                        if 3 < blocks[i].frame {
                            blocks[i].frame = 2
                        }
                    }
                }
            case CellCode.egg:
                if blocks[i].state == 3 {
                    if Int(frame) < Int(blocks[i].startFrame) + Int(levelRecord.words[8]) {
                        blocks[i].animCounter &+= 1
                        if 8 < blocks[i].animCounter {
                            blocks[i].animCounter = 0
                            blocks[i].eggToggle.toggle()
                        }
                        if !blocks[i].eggToggle {
                            blocks[i].spriteSet = 0x11
                            blocks[i].frame = 1
                        } else {
                            blocks[i].spriteSet = 0x1f
                            blocks[i].frame = Int16(enemies[Int(blocks[i].enemy)].type)
                        }
                    } else {
                        blocks[i].state = 4
                        blocks[i].startFrame = frame
                    }
                }
                if blocks[i].state == 4, Int(blocks[i].startFrame) + Int(blocks[i].eggPopDelay) < Int(frame) {
                    blocks[i].type = CellCode.popping
                    blocks[i].state = 2
                    blocks[i].startFrame = frame
                    blocks[i].spriteSet = 0x18
                    blocks[i].frame = 1
                    maze.cells[cellIndex] = CellCode.popping
                }
            default:
                break
            }
        }

        for i in blocks.indices {
            guard blocks[i].state != 0, blocks[i].moving, !blocks[i].retired else { continue }
            guard let j = ((i + 1)..<Self.blockCapacity).first(where: {
                blocks[$0].state != 0 && blocks[$0].moving && !blocks[$0].retired
                    && blocks[i].rect.collides(blocks[$0].rect)
            }) else { continue }
            if !blocks[i].bouncing, !reversed[i] {
                blocks[i].direction = blocks[i].direction?.opposite
            }
            if !blocks[j].bouncing, !reversed[j] {
                blocks[j].direction = blocks[j].direction?.opposite
            }
            reversed[j] = true
            reversed[i] = true
        }
    }
}
