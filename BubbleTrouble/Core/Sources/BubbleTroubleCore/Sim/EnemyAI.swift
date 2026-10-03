// Enemy AI (plan §Task 9b.1; Research notes 31, 32; Invariants 8, 9, 18; INDEX C11; enemies-ai.md §4, §4b, §4d),
// transcribed from `_EnemyAI @ 00014296`, `_FigureEnemyMove @ 00013bd4` (disasm 00013bd4…00013d97 for the part
// before the tail jump into the folded `_MoveEnemyRandomly`), `_FigureEnemyRandomness @ 00012d65`, `_CanDoNormalPop
// @ 00012cf4`, `_CanDoNormalOtherPop @ 00012c83` and `_EnemyCheckBurstingBubble @ 00012e01`. Movement, the random
// walk and the turn checks live in `EnemyMove.swift`; the actions (pop, push, balloon, toast) are Task 9c's
// (`EnemyActions.swift`).

extension GameState {
    /// `_LocationErrorInt(0x7d8, 1)` from `_FigureEnemyMove`'s homing branch with old direction 0: the original
    /// shows the error, `_StopAlert`s and `_CleanUp` → `_ExitToShell` (C11).
    static let homingOldDirZeroStop = StopReason.originalWouldAbort("LocationErrorInt 0x7d8/1")

    /// `_EnemyAI(i) @ 00014296`: aligned = left % 40 == 0 && top % 40 == 0 (stored in `+0x31`); aligned →
    /// `_FigureEnemyMove(i)`; paused (`+0x4a`) → return; else tail-jump `_MoveEnemy(i)`. When a callee hit one of the
    /// original's quits (`.originalWouldAbort`), nothing after it runs.
    mutating func enemyAI(_ slot: Int) {
        correctEnemyAligned(slot)
        if enemies[slot].aligned {
            figureEnemyMove(slot)
            if pendingStops.contains(where: { if case .originalWouldAbort = $0 { true } else { false } }) { return }
        }
        if enemies[slot].paused { return }
        moveEnemy(slot)
    }

    /// `_FigureEnemyMove(i) @ 00013bd4` (aligned enemies), Research note 32 / enemies-ai.md §4b, §4d:
    ///
    /// 1. `u = _Get0To6()`; pending action (`+0x58`) when `u ≤ 7` (always): 2 → `_TryRemoveGo(dir)`, 1 →
    ///    `_TryEnemyPushBlock(dir)`, 3 → `_TryEnemyCreateBalloon(dir)` — success → pause, return; 4 → `+0x52 < 10`:
    ///    `+0x52++`, pause, return; else clear both.
    /// 2. `old = dir; dir = 0`. old ≠ 0: next cell bursting (0x28) and paused → `dir = old`, return; not bursting,
    ///    paused and `_TryAndTurnEnemy(old)` → unpause, return.
    /// 3. Clear the pause; `r = _FigureEnemyRandomness(i)`; `roll = GetRandomFast(1, r)`.
    /// 4. `roll ≠ 1` and bonus > 0 → `dir = old`, tail-jump `_MoveEnemyRandomly(i)`.
    /// 5. Homing with SIGNED dx = e.col − hero.col, dy = e.row − hero.row (negated only when `u == −1`, which
    ///    `_Get0To6` never returns); the unregistered dummy `GetRandomFast(0,7)` when `u + 9 ≤ level` (settled by the
    ///    disasm: 00013d43–49 stores `−0x2c = u − 1`, 00013df8 adds `+0xa` before the compare — inert while
    ///    `gAIRegistered` is set); `back = opposite(old)`
    ///    — old 0 → `_LocationErrorInt(0x7d8,1)` → the original quits (C11) → `.originalWouldAbort`, enemy unmoved;
    ///    then the (p, s) table and the try-sequence of §4d.
    mutating func figureEnemyMove(_ slot: Int) {
        let u = config.latches.u
        var tried = [Bool](repeating: false, count: 5)               // local_24/local_22: tried[d], d = 1…4

        if UInt32(truncatingIfNeeded: u) <= 7, dispatchPendingEnemyAction(slot) { return }

        let old = enemies[slot].direction                            // LAB_00013cca
        enemies[slot].direction = nil
        if let old {
            if enemyCheckBurstingBubble(slot, old) && enemies[slot].paused {
                enemies[slot].direction = old
                return
            }
            if !enemyCheckBurstingBubble(slot, old) && enemies[slot].paused && tryAndTurnEnemy(slot, old) {
                enemies[slot].paused = false
                return
            }
        }
        if enemies[slot].paused {
            enemies[slot].paused = false
        }
        let r = figureEnemyRandomness(slot)
        let roll = Int16(truncatingIfNeeded: rng.fast(1, r))
        if !(roll == 1 || timeBonus < 1) {
            enemies[slot].direction = old
            moveEnemyRandomly(slot)                                  // tail jump 00013d97
            return
        }

        // Homing (00013da0…).
        let dx = Int16(enemies[slot].col) &- Int16(hero.col)         // sVar7
        let dy = Int16(enemies[slot].row) &- Int16(hero.row)         // sVar4
        var cy = dy                                                  // local_3c
        if dy < 0 && u == -1 { cy = -dy }
        var cx = dx                                                  // local_3a
        if dx < 0 && u == -1 { cx = -dx }
        let lvl = Int16(truncatingIfNeeded: level)
        if UInt32(truncatingIfNeeded: u) &+ 9 <= UInt32(truncatingIfNeeded: Int32(lvl)) && !aiRegistered {
            _ = rng.fast(0, 7)
        }
        guard let old else {
            pendingStops.insert(Self.homingOldDirZeroStop)
            return
        }
        let back = old.opposite                                      // local_3e

        let p: Direction, s: Direction                               // local_20[0], local_20[1]
        if dy < 0 {
            if dx < 0 {
                if cx < cy { p = .down; s = .right } else { p = .right; s = .down }
            } else if dx == 0 {
                p = .down
                s = rng.fast(1, 2) != 1 ? .right : .left             // LAB_00013f0a: (r ≠ 1) + 3
            } else if cy <= cx {
                p = .left; s = .down
            } else {
                p = .down; s = .left
            }
        } else if dy == 0 {
            if dx < 1 {
                if dx == 0 {
                    p = .right; s = .up                              // LAB_00013f74
                } else {
                    p = .right
                    s = rng.fast(1, 2) != 1 ? .down : .up            // (r ≠ 1) + 1
                }
            } else {
                p = .left
                s = rng.fast(1, 2) != 1 ? .down : .up
            }
        } else {
            if dx < 1 {
                if dx == 0 {
                    p = .up
                    s = rng.fast(1, 2) != 1 ? .right : .left
                } else if cx < cy {
                    p = .up; s = .right
                } else {
                    p = .right; s = .up                              // LAB_00013f74
                }
            } else if cx < cy {
                p = .up; s = .left
            } else {
                p = .left; s = .up
            }
        }

        if back != p && enemies[slot].tier < 6 {
            if enemies[slot].spriteSet == 0x1d && canDoNormalPop(slot) && tryEnemyCreateBalloon(slot, p) { return }
            if tryAndTurnEnemy(slot, p) { return }
            if enemies[slot].spriteSet == 0x1e && tryEnemyPushBlock(slot, p) { return }
            if canDoNormalPop(slot) {
                if UInt16(bitPattern: enemies[slot].spriteSet &- 0x1c) < 2 && tryEnemyPushBlock(slot, p) { return }
                if tryRemoveGo(slot, p) { return }
            }
            tried[Int(p.rawValue)] = true
        }
        if back != s {
            if tryAndTurnEnemy(slot, s) { return }
            if canDoNormalPop(slot) {
                let set = enemies[slot].spriteSet
                if (set == 0x1e || set == 0x1c || set == 0x1d) && tryEnemyPushBlock(slot, p) { return }   // p, not s
                if tryRemoveGo(slot, s) { return }
            }
            tried[Int(s.rawValue)] = true
        }
        let k: Direction? = back == p ? s : (back == s ? p : nil)
        if let k {
            if tryAndTurnEnemy(slot, k.opposite) { return }
            tried[Int(k.opposite.rawValue)] = true
        }
        for d in [Direction.up, .down, .left, .right]                // LAB_00014180
        where !tried[Int(d.rawValue)] && back != d {
            if tryAndTurnEnemy(slot, d) { return }
            if canDoNormalOtherPop(slot) && tryRemoveGo(slot, d) { return }
            tried[Int(d.rawValue)] = true
        }
        for d in [Direction.up, .down, .left, .right] where !tried[Int(d.rawValue)] {
            if tryAndTurnEnemy(slot, d) { return }
            tried[Int(d.rawValue)] = true
        }
        tried = [Bool](repeating: false, count: 5)
        if tryRemoveGo(slot, p) { return }
        tried[Int(p.rawValue)] = true
        if tryRemoveGo(slot, s) { return }
        tried[Int(s.rawValue)] = true
        for _ in 0..<2 {
            for d in [Direction.up, .down, .left, .right] where !tried[Int(d.rawValue)] {
                if tryRemoveGo(slot, d) { return }
                tried[Int(d.rawValue)] = true
            }
        }
        enemies[slot].direction = old
        enemies[slot].paused = true
    }

    /// The pending-action dispatch shared by `_FigureEnemyMove` (00013bd4…, behind the `u ≤ 7` gate) and the folded
    /// `_MoveEnemyRandomly` (0001396f…): `+0x58` 2 → `_TryRemoveGo(dir)`, 1 → `_TryEnemyPushBlock(dir)`, 3 →
    /// `_TryEnemyCreateBalloon(dir)` — success → pause; 4 → `+0x52 < 10`: `+0x58 = 4`, `+0x52++`, pause; else
    /// `+0x52 = 0`, `+0x58 = 0` and carry on; any other value → carry on. Returns true when the caller returns. The raw
    /// `+0x23` byte is passed (nil = 0; see `EnemyActions.swift`).
    mutating func dispatchPendingEnemyAction(_ slot: Int) -> Bool {
        let dir = enemies[slot].direction
        let acted: Bool
        switch enemies[slot].pendingAction {
        case 2: acted = tryRemoveGo(slot, dir)
        case 1: acted = tryEnemyPushBlock(slot, dir)
        case 3: acted = tryEnemyCreateBalloon(slot, dir)
        case 4:
            if enemies[slot].actionWait < 10 {
                enemies[slot].pendingAction = 4
                enemies[slot].actionWait &+= 1
                enemies[slot].paused = true
                return true
            }
            enemies[slot].actionWait = 0
            enemies[slot].pendingAction = 0
            return false
        default:
            return false
        }
        if acted {
            enemies[slot].paused = true
            return true
        }
        return false
    }

    /// `_FigureEnemyRandomness(i) @ 00012d65`: base by sprite set — starfish 0x1e `(short)(750 − 15·level)`, eel
    /// 0x1c 120, shark 0x1d 180, debug 0x3039 1200 / 0x303a 30, else (piranha) 600; `r = base / (frame − stateStart)
    /// + 1` (C `int` division, the frame difference taken as `int` without wrapping — Invariant 9); `(short)r < 1` → 1.
    func figureEnemyRandomness(_ slot: Int) -> Int {
        let base: Int
        switch enemies[slot].spriteSet {
        case 0x1e: base = Int(Int16(truncatingIfNeeded: level &* -0xf &+ 0x2ee))
        case 0x1c: base = 0x78
        case 0x1d: base = 0xb4
        case 0x3039: base = 0x4b0
        case 0x303a: base = 0x1e
        default: base = 600
        }
        let age = Int(Int32(truncatingIfNeeded: Int(frame) - Int(enemies[slot].stateStart)))
        precondition(age != 0, "FigureEnemyRandomness: frame == stateStart — the original divides by zero")
        let r = Int32(truncatingIfNeeded: base / age + 1)
        if 0 < Int16(truncatingIfNeeded: r) {
            return Int(UInt16(truncatingIfNeeded: r))
        }
        return 1
    }

    /// `_CanDoNormalPop(i) @ 00012cf4`: `lastPop + 0x78 < frame && (short)(10 − frame) < (short)((int)(frame −
    /// stateStart) / 0x1e)` — the `short` truncation is kept (the window closes again from frame 32778).
    func canDoNormalPop(_ slot: Int) -> Bool {
        canDoPop(slot, lead: 10)
    }

    /// `_CanDoNormalOtherPop(i) @ 00012c83`: the same with 4.
    func canDoNormalOtherPop(_ slot: Int) -> Bool {
        canDoPop(slot, lead: 4)
    }

    private func canDoPop(_ slot: Int, lead: Int) -> Bool {
        let f = Int(frame)
        guard Int(enemies[slot].lastPop) + 0x78 < f else { return false }
        let lhs = Int16(truncatingIfNeeded: lead - f)
        let rhs = Int16(truncatingIfNeeded: Int(Int32(truncatingIfNeeded: f - Int(enemies[slot].stateStart))) / 0x1e)
        return lhs < rhs
    }

    /// `_EnemyCheckBurstingBubble(i, d) @ 00012e01`: `_GetNextObject(d, col, row) == 0x28` (a popping bubble). (Any
    /// other `d` is the original's `_LocationErrorInt(0x7d8, 4)`; `Direction` cannot express one.)
    func enemyCheckBurstingBubble(_ slot: Int, _ dir: Direction) -> Bool {
        getNextObject(dir, col: Int(enemies[slot].col), row: Int(enemies[slot].row)) == CellCode.popping
    }
}
