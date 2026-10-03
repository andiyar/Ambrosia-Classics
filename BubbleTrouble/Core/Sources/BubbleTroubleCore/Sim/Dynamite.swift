// Dynamite (plan §Task 5b.1; Research note 38; Invariant 7; INDEX C1), transcribed from
// `_ExplodeBombBlock @ 0001c032` and `_CheckForBombKills @ 000116eb`. Sounds are not modelled (no RNG).

extension GameState {
    /// `_ExplodeBombBlock(i) @ 0001c032`: copy the block rect, sprite set −1 (0xffff), frame 1, retired (the slot is
    /// freed by the draw pass — Invariant 8), maze cell = 0. Level < 12: `_NewStarGroup(col·40, row·40, 0xf)`, rect
    /// grown by 40 on every side (`_InsetRect(−40, −40)`), one `_CheckForBombKills(rect, 0)`. Level ≥ 12:
    /// `_NewStarGroup(…, 0x10)`, then A = (top − 80, left − 40, bottom − 40, right + 40) with base 0 → n_A,
    /// B = (top + 80, left − 40, bottom + 80, right + 40) with base n_A → n_B, C = (top − 40, left − 80, bottom + 40,
    /// right + 80) with base `(short)(n_A + n_B)` (passed as a `char`).
    mutating func explodeBombBlock(_ slot: Int) {
        let r = blocks[slot].rect
        blocks[slot].spriteSet = -1
        blocks[slot].frame = 1
        blocks[slot].retired = true
        let col = Int(blocks[slot].col), row = Int(blocks[slot].row)
        maze.cells[col + row * Maze.columns] = 0
        let x = Int16(truncatingIfNeeded: col * 0x28), y = Int16(truncatingIfNeeded: row * 0x28)
        if level < 0xc {
            stars.newGroup(x: x, y: y, group: 0xf, hero: heroAnchor, frame: frame, prefs: config.prefs, rng: &rng)
            var blast = r
            blast.inset(dx: -0x28, dy: -0x28)
            _ = checkForBombKills(blast, base: 0)
        } else {
            stars.newGroup(x: x, y: y, group: 0x10, hero: heroAnchor, frame: frame, prefs: config.prefs, rng: &rng)
            let a = QDRect(top: r.top &- 0x50, left: r.left &- 0x28, bottom: r.bottom &- 0x28, right: r.right &+ 0x28)
            let nA = Int16(truncatingIfNeeded: checkForBombKills(a, base: 0))
            let b = QDRect(top: r.top &+ 0x50, left: r.left &- 0x28, bottom: r.bottom &+ 0x50, right: r.right &+ 0x28)
            let nB = Int16(truncatingIfNeeded: checkForBombKills(b, base: Int(nA)))
            let c = QDRect(top: r.top &- 0x28, left: r.left &- 0x50, bottom: r.bottom &+ 0x28, right: r.right &+ 0x50)
            _ = checkForBombKills(c, base: Int(nA &+ nB))
        }
    }

    /// `_CheckForBombKills(rect, base) @ 000116eb`: per enemy slot 0…29 in state 1, 4, 5, 6 or 3 whose rect strictly
    /// overlaps: a state-6 enemy's balloon is popped, then `count += 1; _SquishEnemy(i, (char)(base + count))`. The
    /// dead flag is **not** tested (Invariant 7): a dead-but-unfreed enemy advances the count while `_SquishEnemy`
    /// ignores it — the blast double count, replicated. Then `_IsHeroCaught(rect, 1, 1)` → `_HeroCaught(2)` (at most
    /// once per frame — C1). Returns the count (a `short`).
    mutating func checkForBombKills(_ rect: QDRect, base: Int) -> Int {
        var count: Int16 = 0
        let base = Int8(truncatingIfNeeded: base)
        for i in enemies.indices {
            let s = enemies[i].state
            guard s == 1 || s == 4 || s == 5 || s == 6 || s == 3 else { continue }
            guard rect.collides(enemies[i].rect) else { continue }
            if s == 6 {
                balloonsPopBalloon(Int(enemies[i].balloonIndex))
            }
            count &+= 1
            squishEnemy(i, count: Int(base &+ Int8(truncatingIfNeeded: count)))
        }
        if isHeroCaught(rect, protectInvisible: true, bigInset: true) {
            heroCaught(kind: 2)
        }
        return Int(count)
    }
}
