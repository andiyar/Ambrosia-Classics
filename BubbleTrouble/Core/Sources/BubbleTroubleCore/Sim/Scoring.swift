// Score, lives and the squish multiplier (plan §Task 5a.1; Research notes 28, 43; INDEX C8), transcribed from
// `_AddToScore @ 000280dd`, `_AddHero @ 00022d62`, `_Bonus_SetNumEnemySquishes @ 0001a818`,
// `_Multiplier_Change @ 00019ceb`, `_Multiplier_Reset @ 00019e68`. Sounds, the reserve-hero redraw flags and the
// multiplier draw are presentation only and not modelled; none of these functions draws from the RNG.

extension GameState {
    /// `_AddToScore(v, multiply) @ 000280dd`: `v ×= gBonusMultiplier` when flagged (the original also skips the
    /// multiply for one blacklisted licence code — not the modelled licence state, Research note 6); `_AddScore(v)`
    /// (`int` add); then, once per call, if `score >= gNextExtraLifeScore`: `_AddHero(1, 1)` and next = 40000 when
    /// below 40000, else next + 40000.
    mutating func addToScore(_ v: Int32, multiply: Bool) {
        var v = v
        if multiply {
            v = Int32(multiplier) &* v
        }
        score &+= v
        if nextExtraLifeScore <= score {
            addHero()
            if nextExtraLifeScore < 40000 {
                nextExtraLifeScore = 40000
            } else {
                nextExtraLifeScore &+= 40000
            }
        }
    }

    /// `_AddHero(1, 1) @ 00022d62` (every caller passes (1, 1)): lives += 1, capped at 9; then "Extra Life" twice
    /// (00022dab, 00022dc7). (The reserve-hero redraw/animate flags are presentation only.)
    mutating func addHero() {
        lives &+= 1
        if 9 < lives {
            lives = 9
        }
        playMySnd(0xd, priority: 0x14)
        playMySnd(0xd, priority: 0x14)
    }

    /// `_Bonus_SetNumEnemySquishes(n) @ 0001a818` — the multiplier step on a block that squished n enemies at once.
    /// n < 3 → nothing (C8). Otherwise by (n, multiplier): n = 3: 1→2, 2→3, 3→4, 4→5; n = 4: 1,2→3, 3→4, 4→5;
    /// n = 5: 1…3→4, 4→5; n ≥ 6: 1…4→5 (each via `_Multiplier_Change`); at 5: level < 9 → `_AddToScore(2000, 1)`,
    /// point sprite 0xc, else `_AddToScore(4000, 1)`, sprite 0xe, then `_NewPoint(hero.left, hero.top, sprite, 0)`,
    /// multiplier unchanged; any other multiplier → nothing. `gBonus_NumEnemiesSquishedAtOnce` is set to n on entry
    /// and 0 on every exit.
    mutating func bonusSetNumEnemySquishes(_ n: Int) {
        let n = Int16(truncatingIfNeeded: n)
        bonusSquishedAtOnce = n
        defer { bonusSquishedAtOnce = 0 }
        if n < 3 { return }
        // The decompile's four switches on gBonusMultiplier (n = 4, n = 5, n ≥ 6, n = 3); case 5 is the award in each.
        let next: Int16?
        switch (n, multiplier) {
        case (_, 5): next = nil
        case (4, 1), (4, 2): next = 3
        case (4, 3): next = 4
        case (4, 4): next = 5
        case (5, 1), (5, 2), (5, 3): next = 4
        case (5, 4): next = 5
        case (3, 1): next = 2
        case (3, 2): next = 3
        case (3, 3): next = 4
        case (3, 4): next = 5
        case (_, 1), (_, 2), (_, 3), (_, 4): next = 5       // n ≥ 6 (3, 4, 5 matched above)
        default:
            return      // a multiplier outside 1…5: each switch's default — no change
        }
        if let next {
            multiplierChange(next)
            return
        }
        let sprite: Int16
        if level < 9 {
            addToScore(2000, multiply: true)
            sprite = 0xc
        } else {
            addToScore(4000, multiply: true)
            sprite = 0xe
        }
        points.newPoint(x: hero.rect.left, y: hero.rect.top, sprite: sprite, delay: 0, level: level,
                        notRegistered: config.pointsNotRegistered)
    }

    /// `_Multiplier_Change(v) @ 00019ceb`: multiplier = v; (draw); animate on, timer = frame, anim counter 0.
    mutating func multiplierChange(_ v: Int16) {
        multiplier = v
        multiplierAnimating = true
        multiplierTimer = frame
        multiplierAnimCounter = 0
    }

    /// `_Multiplier_Reset(draw) @ 00019e68`: multiplier = 1 (the flag only triggers a redraw).
    mutating func multiplierReset() {
        multiplier = 1
    }
}
