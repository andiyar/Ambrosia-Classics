// Enemy actions (plan §Task 9c; Research note 33; enemies-ai.md §4e): `_TryRemoveGo @ 0001305e`,
// `_TryEnemyPushBlock @ 000131fd`, `_TryEnemyCreateBalloon @ 00013441`, `_ToastBubble @ 00012ef2`, transcribed from
// the decompile. Callers: `_FigureEnemyMove` / `_MoveEnemyRandomly` (Task 9b — the `_CanDoNormalPop` /
// `_CanDoNormalOtherPop` gates and the shark-only balloon test live in the callers, not here).
//
// The direction is `Direction?` (nil = 0) only so the pending-action dispatch can pass the raw `+0x23` byte; a 0 can
// never reach these four actions. `_ToastBubble` writes the direction when it pops (00013040 `movb %bl,0x23(%esi)`)
// and sets 1 when nothing pops (0001304f); `+0x23` is zeroed only transiently while deciding (00013cdc in
// `_FigureEnemyMove`, 000139bb in `_MoveEnemyRandomly`) and every exit of those sets it non-zero; spawn draws `(1,4)`;
// balloon capture/release never write `+0x23`. The nil arms are therefore unreachable defensive transcription of the
// originals' own 0 exits: `_TryRemoveGo` → `_LocationErrorInt(0x7d8,3)`; `_TryEnemyPushBlock` →
// `_LocationErrorInt(0x7d8,5)`; `_TryEnemyCreateBalloon` returns 0 first when the hero is trapped (`hero+0x4c`), else
// `_LocationErrorInt(0x7d8,5)`. `_LocationErrorInt` quits (NR-7 / C11) → the replica records `.originalWouldAbort`
// and returns false.
//
// The wait thresholds test the sprite set (`+0x3a == 0x1e`, starfish), not the type byte, exactly as the original.

extension GameState {
    /// Pop mask `0x18400` (bits 10, 15, 16): normal, blue, purple — never jewels (20/30), pop blocks, dynamite (52).
    private static func enemyCanPop(_ code: UInt8) -> Bool {
        code < 0x11 && (1 << UInt32(code)) & 0x18400 != 0
    }

    /// `_GetCurrLevelNum()` as the original's `short`.
    private var currLevelNum: Int16 { Int16(truncatingIfNeeded: level) }

    /// `_TryRemoveGo(i, d) @ 0001305e`: the cell next to the enemy in `d` (`_GetNextObject`) must pass the pop mask
    /// (10/15/16), else 0. Wait = 10 for sprite set 0x1e (starfish), else `max(5, 40 − level)`. While `+0x52 < wait`:
    /// `+0x58 = 2`, `+0x52++`, `dir = d`, pause. Else `+0x52 = 0`, `+0x58 = 0`, `_CrushBlock(col, row, d, 0)` (no
    /// score), `dir = d`, pause, `+0x5a = frame`. Returns 1 whenever the mask passed. `d` = 0 →
    /// `_LocationErrorInt(0x7d8,3)` (the original quits).
    mutating func tryRemoveGo(_ slot: Int, _ dir: Direction?) -> Bool {
        guard let d = dir else {
            pendingStops.insert(.originalWouldAbort("LocationErrorInt 0x7d8/3"))
            return false
        }
        let next = getNextObject(d, col: Int(enemies[slot].col), row: Int(enemies[slot].row))
        guard Self.enemyCanPop(next) else { return false }
        var wait: Int16
        if enemies[slot].spriteSet == 0x1e {
            wait = 10
        } else {
            wait = 0x28 &- currLevelNum
            if wait < 5 { wait = 5 }
        }
        if enemies[slot].actionWait < wait {
            enemies[slot].pendingAction = 2
            enemies[slot].actionWait &+= 1
            enemies[slot].direction = d
            enemies[slot].paused = true
        } else {
            enemies[slot].actionWait = 0
            enemies[slot].pendingAction = 0
            crushBlock(col: Int(enemies[slot].col), row: Int(enemies[slot].row), direction: d, score: false)
            enemies[slot].direction = d
            enemies[slot].paused = true
            enemies[slot].lastPop = frame
        }
        return true
    }

    /// `_TryEnemyPushBlock(i, d) @ 000131fd`: edge limits first, before any maze read (down: row > 8 → 0; up: row < 2
    /// → 0; left: col < 2 → 0; right: col > 13 → 0); then `next = _GetNextObject(d)`, `far = _GetDistantObject(d)`;
    /// only `next == 10` with `far` 0 or 'F' (70) passes, else 0. Wait = 10 for sprite set 0x1e, else
    /// `max(5, 70 − 2·level)`. While `+0x52 < wait`: `+0x58 = 1`, `+0x52++`, `dir = d`, pause. Else `+0x52 = 0`,
    /// `+0x58 = 0`, pause cleared, `_PushBlock(col, row, d, 10)`, `dir = d`, pause, `+0x5a = frame`. Returns 1.
    /// `d` = 0 → `_LocationErrorInt(0x7d8,5)` (the original quits).
    mutating func tryEnemyPushBlock(_ slot: Int, _ dir: Direction?) -> Bool {
        guard let d = dir else {
            pendingStops.insert(.originalWouldAbort("LocationErrorInt 0x7d8/5"))
            return false
        }
        let col = enemies[slot].col, row = enemies[slot].row
        switch d {
        case .down: if 8 < row { return false }
        case .up: if row < 2 { return false }
        case .left: if col < 2 { return false }
        case .right: if 13 < col { return false }
        }
        let next = getNextObject(d, col: Int(col), row: Int(row))
        let far = getDistantObject(d, col: Int(col), row: Int(row))
        guard next == CellCode.normal, far == CellCode.empty || far == CellCode.passableF else { return false }
        var wait: Int16
        if enemies[slot].spriteSet == 0x1e {
            wait = 10
        } else {
            wait = 0x46 &- 2 &* currLevelNum
            if wait < 5 { wait = 5 }
        }
        if enemies[slot].actionWait < wait {
            enemies[slot].pendingAction = 1
            enemies[slot].actionWait &+= 1
            enemies[slot].direction = d
            enemies[slot].paused = true
        } else {
            enemies[slot].actionWait = 0
            enemies[slot].pendingAction = 0
            enemies[slot].paused = false
            pushBlock(col: Int(enemies[slot].col), row: Int(enemies[slot].row), direction: d, type: CellCode.normal)
            enemies[slot].direction = d
            enemies[slot].paused = true
            enemies[slot].lastPop = frame
        }
        return true
    }

    /// `_TryEnemyCreateBalloon(i, d) @ 00013441`: hero trapped (`hero+0x4c`) → 0. Then a scan from the enemy's own
    /// cell along `d` (down while k < 10, up while k > 0, left while k > 0, right while k < 15): each step reads
    /// `_GetNextObject(d)` from cell k, then tests whether the hero's (col,row) is cell k → found; else steps on and
    /// stops after a non-empty read. Not found: proceed only when the last read was 'F' (0x46) — a scan that never
    /// read (sentinel 0x4d2) or ended on a 0 or another code → 0. Wait = `max(5, 70 − 3·level)` (no starfish case).
    /// While `+0x52 < wait`: `+0x58 = 3`, `+0x52++`, `dir = d`, pause, `+0x5a = frame` (every waiting frame). Else
    /// `+0x52 = 0`, `+0x58 = 0`, `dir = d`, pause, `+0x5a = frame`, `_Balloons_New(i)`. Returns 1. `d` = 0 (hero not
    /// trapped) → `_LocationErrorInt(0x7d8,5)` (the original quits).
    mutating func tryEnemyCreateBalloon(_ slot: Int, _ dir: Direction?) -> Bool {
        if hero.trapped { return false }
        guard let d = dir else {
            pendingStops.insert(.originalWouldAbort("LocationErrorInt 0x7d8/5"))
            return false
        }
        let eCol = enemies[slot].col, eRow = enemies[slot].row
        var last: Int16 = 0x4d2
        var found = false
        switch d {
        case .down, .up:
            var k = Int16(eRow)
            while d == .down ? k < 10 : 0 < k {
                let c = getNextObject(d, col: Int(eCol), row: Int(Int8(truncatingIfNeeded: k)))
                last = Int16(Int8(bitPattern: c))
                if eCol == hero.col && k == Int16(hero.row) { found = true; break }
                k += d == .down ? 1 : -1
                if c != 0 { break }
            }
        case .left, .right:
            var k = Int16(eCol)
            while d == .right ? k < 0xf : 0 < k {
                let c = getNextObject(d, col: Int(Int8(truncatingIfNeeded: k)), row: Int(eRow))
                last = Int16(Int8(bitPattern: c))
                if k == Int16(hero.col) && eRow == hero.row { found = true; break }
                k += d == .right ? 1 : -1
                if c != 0 { break }
            }
        }
        if !found && last != 0x46 { return false }
        var wait = 0x46 &- 3 &* currLevelNum
        if wait < 5 { wait = 5 }
        if enemies[slot].actionWait < wait {
            enemies[slot].pendingAction = 3
            enemies[slot].actionWait &+= 1
            enemies[slot].direction = d
            enemies[slot].paused = true
            enemies[slot].lastPop = frame
        } else {
            enemies[slot].actionWait = 0
            enemies[slot].pendingAction = 0
            enemies[slot].direction = d
            enemies[slot].paused = true
            enemies[slot].lastPop = frame
            balloonsNew(enemy: slot)
        }
        return true
    }

    /// `_ToastBubble(i) @ 00012ef2` (the random walk's stuck fallback): tests up (row > 0), then down (row ≤ 9), then
    /// left (col > 0) — the loop counter passes 3 straight to the "none" exit, so **right is never tested**
    /// (Invariant 18). The first neighbour passing the pop mask (10/15/16) is popped: `_CrushBlock(col, row, d, 0)`,
    /// stuck (`+0x48`) = 0, `dir = d`, pause. None → `dir = 1` (up), pause.
    mutating func toastBubble(_ slot: Int) {
        let col = Int(enemies[slot].col), row = Int(enemies[slot].row)
        for d in [Direction.up, .down, .left] {
            switch d {
            case .up: if !(0 < row) { continue }
            case .down: if 9 < row { continue }
            case .left: if !(0 < col) { continue }
            case .right: continue
            }
            if Self.enemyCanPop(getNextObject(d, col: col, row: row)) {
                crushBlock(col: col, row: row, direction: d, score: false)
                enemies[slot].stuck = 0
                enemies[slot].direction = d
                enemies[slot].paused = true
                return
            }
        }
        enemies[slot].direction = .up
        enemies[slot].paused = true
    }
}
