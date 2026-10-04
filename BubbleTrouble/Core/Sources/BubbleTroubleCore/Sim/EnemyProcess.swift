// Per-frame enemy processing (plan §Task 9a.1; Research note 30; Invariants 8, 9, 18; INDEX C10), transcribed from
// `_ProcessEnemies @ 00011ad3` (incl. the per-type animation cycles) and `_CorrectEnemyAligned @ 00012596`.
// `_AddRectToBgnd` (00011bbf) is recorded at its site (C3, `DrawOps.swift`). The hatch's licence checksum (`RT3_CheckLicenseName`,
// `RT3_ExtractLicenseBlock1`, `_TimerGetSeconds`, `_IsPlatformOpen` — no RNG) is reduced to its result in the
// modelled licence state (Research note 6): `+0x22` = 1.

extension GameState {
    /// `_ProcessEnemies @ 00011ad3`, slots 0…29 in order (Invariant 8); free slots (state 0) are skipped.
    ///
    /// - State 1: post-hatch flag `+0x4b` set → `+0x44++`, and when it exceeds 15 the flag and the counter clear;
    ///   flag clear → `_EnemyAI(i)`. Then the animation by sprite set (after the AI, on the direction it left):
    ///   eel 0x1c — tick > 3 → tick 0, frame++; frame kept in dir 1 → 1…5, 2 → 6…10, 3 → 11…15, 4 → 16…20 (out of
    ///   range → the range's first frame); piranha 0x1b / shark 0x1d — tick > 2 → tick 0, frame++; dir 1 → 1…3,
    ///   2 → 4…6, 3 → 7…9, 4 → 10…12; starfish 0x1e — tick > 3 → tick 0, frame++, and an old frame above 6 → 1
    ///   (frames 1…7, any direction); any other sprite set → `_DebugValues("ProcessEnemies() - unknown enemy
    ///   type.")` + `_CleanUp` (quit) → `.originalWouldAbort`. Only this state arms the catch test below.
    /// - State 2: `start + w10 < frame` → state 3, start = frame.
    /// - State 3: `start + 10 + w8 < frame` → hatch: licence flag `+0x22` (1 here), marker `+0x3e` = 0x17 (an
    ///   invalid licence on a registered slot draws `GetRandomFast(1,0x1e)` instead — unreachable in the modelled
    ///   state, transcribed), state 1, start = frame, drawn, post-hatch flag 1, counter 0.
    /// - States 4/5/6: nothing. A state byte above 6 ends the whole call (`switchD default: return`).
    ///
    /// Then, every non-free slot: `_CorrectEnemyAligned(i)`; not aligned → the cell being entered — dir 1/3:
    /// `gMaze[col + 16·row]`, dir 2: `_GetNextObject(2, col, row)`, dir 4: `_GetNextObject(4, col, row)` — holding
    /// 10/15/16/20/30 → `_SquishEnemy(i, 1)`. Finally (state-1 iterations only): hero state 2,
    /// `_IsHeroCaught(rect, 1, 1)` and the enemy's state byte ≠ 4 → `_HeroCaught(1)`. The dead flag is not tested,
    /// so an enemy squished on entry in this very call still catches the hero (C10), and its squish draws precede
    /// the catch's `(0,1)`.
    mutating func processEnemies() {
        let now = frame
        for i in 0..<Self.enemyCapacity {
            if enemies[i].state == 0 { continue }
            var armed = false
            switch enemies[i].state {
            case 1:
                if !enemies[i].postHatchDelay {
                    enemyAI(i)
                } else {
                    enemies[i].postHatchCounter &+= 1
                    if 0xf < UInt16(bitPattern: enemies[i].postHatchCounter) {
                        enemies[i].postHatchDelay = false
                        enemies[i].postHatchCounter = 0
                    }
                }
                if !animateEnemy(i) {
                    pendingStops.insert(.originalWouldAbort("ProcessEnemies() - unknown enemy type."))
                    return
                }
                armed = true
            case 2:
                if Int(enemies[i].stateStart) + Int(levelRecord.words[10]) < Int(now) {
                    enemies[i].state = 3
                    enemies[i].stateStart = now
                }
            case 3:
                if Int(enemies[i].stateStart) + 10 + Int(levelRecord.words[8]) < Int(now) {
                    hatchEnemy(i, now: now)
                }
            case 4, 5, 6:
                break
            default:
                return
            }

            addRectToBgnd(enemies[i].prevRect)                  // 00011bbf (LAB_00011baa), every state 1…6
            correctEnemyAligned(i)
            if !enemies[i].aligned {
                let e = enemies[i]
                let entering: UInt8?
                switch e.direction {
                case .up, .left: entering = maze.cells[Int(e.col) + Int(e.row) * 0x10]
                case .down: entering = getNextObject(.down, col: Int(e.col), row: Int(e.row))
                case .right: entering = getNextObject(.right, col: Int(e.col), row: Int(e.row))
                case nil: entering = nil
                }
                if let cell = entering, [CellCode.normal, CellCode.blue, CellCode.purple, CellCode.jewel,
                                         CellCode.cluster].contains(cell) {
                    squishEnemy(i, count: 1)
                }
            }
            if armed && hero.state == 2 && isHeroCaught(enemies[i].rect, protectInvisible: true, bigInset: true)
                && enemies[i].state != 4 {
                heroCaught(kind: 1)
            }
        }
    }

    /// `_CorrectEnemyAligned(i) @ 00012596`: aligned = left and top are both multiples of 40 (C truncating
    /// division, `short` arithmetic).
    mutating func correctEnemyAligned(_ slot: Int) {
        let r = enemies[slot].rect
        enemies[slot].aligned = r.left == (r.left / 0x28) &* 0x28 && r.top == (r.top / 0x28) &* 0x28
    }

    /// The state-1 animation step inside `_ProcessEnemies` (00011b8b–00011d50). Returns false for an unknown sprite
    /// set (the original's `_DebugValues` + `_CleanUp`).
    private mutating func animateEnemy(_ i: Int) -> Bool {
        switch enemies[i].spriteSet {
        case 0x1c:                                   // eel: 5-frame cycles, every 4 ticks
            enemies[i].animTick &+= 1
            if 3 < enemies[i].animTick {
                enemies[i].animTick = 0
                enemies[i].animFrame &+= 1
            }
            switch enemies[i].direction {
            case .up: keepAnimFrame(i, first: 1, span: 4)
            case .down: keepAnimFrame(i, first: 6, span: 4)
            case .left: keepAnimFrame(i, first: 0xb, span: 4)
            case .right: keepAnimFrame(i, first: 0x10, span: 4)
            case nil: break
            }
        case 0x1b, 0x1d:                             // piranha / shark: 3-frame cycles, every 3 ticks
            enemies[i].animTick &+= 1
            if 2 < enemies[i].animTick {
                enemies[i].animTick = 0
                enemies[i].animFrame &+= 1
            }
            switch enemies[i].direction {
            case .up: keepAnimFrame(i, first: 1, span: 2)
            case .down: keepAnimFrame(i, first: 4, span: 2)
            case .left: keepAnimFrame(i, first: 7, span: 2)
            case .right: keepAnimFrame(i, first: 10, span: 2)
            case nil: break
            }
        case 0x1e:                                   // starfish: 7 frames, every 4 ticks
            enemies[i].animTick &+= 1
            if 3 < enemies[i].animTick {
                enemies[i].animTick = 0
                let old = UInt16(bitPattern: enemies[i].animFrame)
                enemies[i].animFrame = Int16(bitPattern: old &+ 1)
                if !(old <= 6) {
                    enemies[i].animFrame = 1
                }
            }
        default:
            return false
        }
        return true
    }

    /// `if (span < (ushort)(frame − first)) frame = first` — the unsigned range test of each direction's cycle.
    private mutating func keepAnimFrame(_ i: Int, first: Int16, span: UInt16) {
        if span < UInt16(bitPattern: enemies[i].animFrame &- first) {
            enemies[i].animFrame = first
        }
    }

    /// The state-3 hatch branch of `_ProcessEnemies` (00011e19–000120a0).
    private mutating func hatchEnemy(_ i: Int, now: UInt16) {
        enemies[i].licenceValid = true               // modelled licence state: checksum valid (Research note 6)
        enemies[i].state = 1
        enemies[i].stateStart = now
        enemies[i].drawn = true
        enemies[i].postHatchDelay = true
        enemies[i].postHatchCounter = 0
        let cracked = !enemies[i].licenceValid && enemyRegistered[i]
        if cracked {
            let r = rng.fast(1, 0x1e)
            enemies[i].marker = 0x13 - (r < 2 ? 1 : 0)
        } else {
            enemies[i].marker = 0x17
        }
        if cracked {
            enemies[i].marker &+= 1
        }
    }
}
