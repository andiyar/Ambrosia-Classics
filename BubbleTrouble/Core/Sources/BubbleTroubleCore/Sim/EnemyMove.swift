// Enemy movement (plan §Task 9b.1; Research notes 31, 32; Invariants 8, 9, 18; enemies-ai.md §4a, §4c), transcribed
// from the folded `_MoveEnemy @ 00012786` (tail `jmp` from `_EnemyAI` at 0001436e; Ghidra folds it into `_EnemyAI`'s
// decompile), the folded `_CorrectEnemyMazeY @ 00012682` / `_CorrectEnemyMazeX @ 00012704` (tail jumps at
// 00012c55 / 00012c76), the folded `_MoveEnemyRandomly @ 0001396f` (tail `jmp` from `_FigureEnemyMove` at 00013d97;
// read from `otool -tV` 0001396f…00013bd3), `_TryAndTurnEnemy @ 000138fe` and `_CheckUp @ 000136e6`, `_CheckDown @
// 000137f2`, `_CheckLeft @ 0001376c`, `_CheckRight @ 00013878`.
//
// The tier (`+0x3c`) is 4 for every real enemy, so the `tier < 4` arms and the debug sprite sets 0x3039 / 0x303a
// are unreachable in play; they are transcribed anyway (house rule: transcribe, never prune).

extension GameState {
    /// `_MoveEnemy(i)` (folded @ 00012786): the speed by sprite set — recomputed only on aligned calls — then the move
    /// by that speed in the current direction and `_CorrectEnemyMazeY/X`. Direction 0 → no move.
    ///
    /// Tier 4 (enemies-ai.md §4a): piranha 0x1b — speed kept in `+0x4e`: 2; with the bonus gone, 4 when |dcol| > 1
    /// or |drow| > 1 from the hero. Eel 0x1c — bonus > 0: 2 within 2 cells on both axes, else 4; bonus ≤ 0: 2 within
    /// 1, else 8. Shark 0x1d — c = ++`+0x4e`: c ≤ 1 keep (initial 2); 2–3 → 4; 4–5 → 2 (8 if bonus ≤ 0); 6–7 → 4;
    /// 8–9 → 2/8; 10 → 4; 11 → 8; 12 → 4; ≥ 13 → 2, c = 0. Starfish 0x1e — c = ++`+0x4e`: bonus > 0: 1–3 → 4,
    /// 4–6 → 8, 7 → 4, > 7 → 2 and c = 0; bonus ≤ 0: 1–2 → 4, 3–6 → 8, 7 → 4, > 7 → 2 and c = 0. Any other sprite
    /// set → `_LocationError(0x7d8, 6)` → the original quits → `.originalWouldAbort`.
    mutating func moveEnemy(_ slot: Int) {
        var e = enemies[slot]
        let bonus = timeBonus
        let heroCol = Int16(hero.col), heroRow = Int16(hero.row)
        var si: Int16

        switch e.spriteSet {
        case 0x1d:                                                   // shark
            if e.tier < 4 {
                e.speed = 8
            } else if e.speed == 0 {
                e.speed = 2
            }
            si = e.speed
            if si < 2 || 3 < e.tier {
                if e.aligned {
                    let old = e.speedCounter
                    let c = old &+ 1
                    e.speedCounter = c
                    let next: Int16?
                    if 12 < c {
                        e.speedCounter = 0
                        next = 2
                    } else if c == 12 || c == 10 {
                        next = 4
                    } else if 10 < c {                               // 11
                        next = 8
                    } else if 7 < c || (c < 6 && 3 < c) {             // 8–9, 4–5 (LAB_00012a27)
                        next = 0 < bonus ? 2 : 8
                    } else if c < 6 && (old == 0 || c < 1) {          // keep (LAB_00012a4e)
                        next = nil
                    } else {                                         // 2–3, 6–7
                        next = 4
                    }
                    if let next {
                        e.speed = next
                        si = next
                    }
                }
            } else {
                si = si &+ 6
                e.speed = si
            }
            if e.tier < 4 && -1 < si {                               // LAB_00012a4e
                si = si &+ 6
                e.speed = si
            }

        case 0x1b:                                                   // piranha: speed in +0x4e
            var at1282e = false
            if e.tier < 4 {
                e.speedCounter = 8
                at1282e = true
            } else if e.speedCounter == 0 {
                e.speedCounter = 2
                at1282e = true
            }
            var at1283c = !at1282e
            var at128a3 = false
            if at1282e {
                if 3 < e.tier {
                    at1283c = true
                } else {
                    e.speedCounter &+= 6
                    at128a3 = true
                }
            }
            if at1283c && e.aligned {
                e.speedCounter = 2
                if bonus < 1 {
                    var dc = Int16(e.col) &- heroCol
                    if dc < 0 && 0 < e.tier { dc = -dc }
                    var dr = Int16(e.row) &- heroRow
                    if dr < 0 && 0 < e.tier { dr = -dr }
                    if 1 < dc || 1 < dr { e.speedCounter = 4 }
                }
                at128a3 = true
            }
            if at128a3 && e.tier < 4 {                               // LAB_000128a3
                e.speedCounter &+= 6
            }
            si = e.speedCounter

        case 0x1c:                                                   // eel
            if e.tier < 4 {
                e.speed = 6
            } else if e.speed == 0 {
                e.speed = 2
            }
            var s6 = e.tier
            if e.aligned && 3 < s6 {
                var dc = Int16(e.col) &- heroCol
                if dc < 0 { dc = -dc }
                var dr = Int16(e.row) &- heroRow
                if dr < 0 { dr = -dr }
                if bonus < 1 || e.tier < 4 {
                    e.speed = dc < 2 && dr < 2 ? 2 : 8
                } else {
                    e.speed = dc < 3 && dr < 3 ? 2 : 4
                }
            }
            s6 = e.tier                                              // LAB_00012954
            if !(3 < s6) {
                if e.row < 4 || 6 < e.col {
                    e.speed &+= s6 &* 2
                } else {
                    e.speed &+= 6
                }
                let sum = e.tier &* 3 &+ e.speed
                e.speed = sum
                if e.tier == 3 { e.speed = sum &- 1 }
            }
            si = e.speed

        case 0x1e:                                                   // starfish
            if e.tier < 4 {
                e.speed = 7
                e.speed &+= 7                                        // LAB_00012a84 (tier < 4)
            } else if e.speed == 0 {
                e.speed = 2
            }
            var at12af9 = false
            if !e.aligned {
                at12af9 = !(3 < e.tier)
            } else if e.tier < 4 {
                at12af9 = true
            } else {
                e.speedCounter &+= 1
                let c = e.speedCounter
                if bonus < 1 {
                    if 7 < c {
                        e.speed = 2
                        e.speedCounter = 0
                    } else if c == 7 {
                        e.speed = 4
                    } else if c <= 2 {
                        if 0 < c { e.speed = 4 }
                    } else {
                        e.speed = 8
                    }
                } else {
                    if 7 < c {
                        e.speed = 2
                        e.speedCounter = 0
                    } else if c == 7 {
                        e.speed = 4
                    } else if c <= 3 {
                        if 0 < c { e.speed = 4 }
                    } else {
                        e.speed = 8
                    }
                }
            }
            if at12af9 { e.speed &+= 7 }
            if e.tier == 3 { e.speed &-= 1 }                         // LAB_00012afe
            si = e.speed

        case 0x3039:                                                 // debug type (never spawned)
            if e.tier < 4 {
                e.speedCounter = e.tier &* 10
            } else if e.speed == 0 {
                e.speed = 2
            }
            if e.aligned && 3 < e.tier {
                var dc = Int16(e.col) &- heroCol
                if dc < 0 { dc = -dc }
                var dr = Int16(e.row) &- heroRow
                if dr < 0 { dr = -dr }
                e.speed = dc < 5 && dr < 2 ? 8 : 2
            }
            if !(3 < e.tier) { e.speed &-= 10 }                      // LAB_00012b89
            si = e.speed

        case 0x303a:                                                 // debug type (never spawned)
            if e.tier == 3 {
                e.speed = 9
            } else if e.speed == 0 {
                e.speed = 4
            }
            let s6 = e.tier
            if s6 < 4 {
                e.tier = s6 &+ 0xd                                   // LAB_00012c0b
            } else if e.aligned {
                e.speedCounter &+= 1
                let c = e.speedCounter
                if 12 < c {
                    e.speed = 4
                    e.speedCounter = 0
                } else if 8 < c {
                    e.speed = 0x10
                } else if c == 8 {
                    e.speed = 1
                }
            }
            if e.tier == 3 { e.speed &-= 2 }
            si = e.speed

        default:
            enemies[slot] = e
            pendingStops.insert(.originalWouldAbort("LocationError 0x7d8/6"))
            return
        }

        switch e.direction {                                         // LAB_000127e2
        case .down:
            e.rect.top &+= si
            e.rect.bottom &+= si
            enemies[slot] = e
            correctEnemyMazeY(slot)
        case .up:
            e.rect.top &-= si
            e.rect.bottom &-= si
            enemies[slot] = e
            correctEnemyMazeY(slot)
        case .left:
            e.rect.left &-= si
            e.rect.right &-= si
            enemies[slot] = e
            correctEnemyMazeX(slot)
        case .right:
            e.rect.left &+= si
            e.rect.right &+= si
            enemies[slot] = e
            correctEnemyMazeX(slot)
        case nil:
            enemies[slot] = e
        }
    }

    /// `_CorrectEnemyMazeY(i)` (folded @ 00012682): `yOffset = (char)(top % 40)`, `row = (char)((top − rem) / 40)`
    /// (`short` arithmetic, C truncating `%` and `/`).
    mutating func correctEnemyMazeY(_ slot: Int) {
        let top = enemies[slot].rect.top
        let rem = top % 0x28
        enemies[slot].yOffset = Int8(truncatingIfNeeded: rem)
        enemies[slot].row = Int8(truncatingIfNeeded: (top &- rem) / 0x28)
    }

    /// `_CorrectEnemyMazeX(i)` (folded @ 00012704): `xOffset = (char)(left % 40)`, `col = (char)((left − rem) / 40)`.
    mutating func correctEnemyMazeX(_ slot: Int) {
        let left = enemies[slot].rect.left
        let rem = left % 0x28
        enemies[slot].xOffset = Int8(truncatingIfNeeded: rem)
        enemies[slot].col = Int8(truncatingIfNeeded: (left &- rem) / 0x28)
    }

    /// `_MoveEnemyRandomly(i)` (folded @ 0001396f, disasm): the pending-action dispatch of `_FigureEnemyMove` again
    /// (without the `_Get0To6` gate; success → pause, return; wait → pause, return); `old = dir; dir = 0`; 16 draws —
    /// 8 × {`a = (0,3)`, `b = (0,3)`, swap `order[a]` ↔ `order[b]`} on `[3,4,1,2]`; each `d ≠ opposite(old)` in order
    /// through `_TryAndTurnEnemy`; then the reverse (old ≠ 0); then the stuck fallback: `stuck > 0` →
    /// `_ToastBubble(i)`, stuck = 0, return (no pause here); else stuck++, dir = 3 (left), pause.
    mutating func moveEnemyRandomly(_ slot: Int) {
        if dispatchPendingEnemyAction(slot) { return }

        let old = enemies[slot].direction                            // 000139b4
        enemies[slot].direction = nil
        var order: [Int8] = [3, 4, 1, 2]
        for _ in 0..<8 {
            let a = rng.fast(0, 3)
            let b = rng.fast(0, 3)
            order.swapAt(a, b)
        }
        for raw in order {
            guard let d = Direction(rawValue: raw) else { continue }
            if old == d.opposite { continue }
            if tryAndTurnEnemy(slot, d) { return }
        }
        if let old, tryAndTurnEnemy(slot, old.opposite) { return }   // reverse as last resort
        if 0 < enemies[slot].stuck {                                 // 00013b98
            toastBubble(slot)
            enemies[slot].stuck = 0
            return
        }
        enemies[slot].stuck &+= 1
        enemies[slot].direction = .left
        enemies[slot].paused = true
    }

    /// `_TryAndTurnEnemy(i, d) @ 000138fe` → `_CheckUp/Down/Left/Right(i)`. (Any other `d` is the original's
    /// `_LocationErrorInt(0x7d8, 1)`; `Direction` cannot express one.)
    mutating func tryAndTurnEnemy(_ slot: Int, _ dir: Direction) -> Bool {
        switch dir {
        case .down: checkDown(slot)
        case .up: checkUp(slot)
        case .left: checkLeft(slot)
        case .right: checkRight(slot)
        }
    }

    /// `_CheckUp(i) @ 000136e6`.
    mutating func checkUp(_ slot: Int) -> Bool { checkTurn(slot, .up) }
    /// `_CheckDown(i) @ 000137f2`.
    mutating func checkDown(_ slot: Int) -> Bool { checkTurn(slot, .down) }
    /// `_CheckLeft(i) @ 0001376c`.
    mutating func checkLeft(_ slot: Int) -> Bool { checkTurn(slot, .left) }
    /// `_CheckRight(i) @ 00013878`.
    mutating func checkRight(_ slot: Int) -> Bool { checkTurn(slot, .right) }

    /// The common body of the four `_CheckXxx`: only with direction 0, and only when `_GetNextObject(d, col, row)` is
    /// 0, 'F' (70) or 'P' (80) → direction = d, true.
    private mutating func checkTurn(_ slot: Int, _ d: Direction) -> Bool {
        guard enemies[slot].direction == nil else { return false }
        let next = getNextObject(d, col: Int(enemies[slot].col), row: Int(enemies[slot].row))
        guard next == CellCode.empty || next == CellCode.passableF || next == CellCode.passableP else { return false }
        enemies[slot].direction = d
        return true
    }
}
