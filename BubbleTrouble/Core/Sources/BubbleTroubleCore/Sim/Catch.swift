// Hero catches (plan §Task 5a.1; Research note 27; INDEX C1; B6), transcribed from `_IsHeroCaught @ 00021c79`,
// `_HeroCaught @ 00021dfa`, `_StopAllEnemies @ 000110c8`, `_SetHeroInvisibility @ 00021bee` (with `_MyInsetRect
// @ 0000c3f1` = `QDRect.inset` and `_RectsCollide @ 0000c398` = `QDRect.collides`).

extension GameState {
    /// `_IsHeroCaught(rect, protectInvisible, bigInset) @ 00021c79`: only in hero state 2, and not when
    /// `protectInvisible` and the invisibility bonus (`+0x50`) is on. The rect (by value) is inset by 4 (11 when
    /// `bigInset`) on both axes; the hero rect is inset by 8 when `bigInset`; then the strict `_RectsCollide(hero,
    /// rect)`. Because state 3 is set first by `_HeroCaught`, at most one catch fires per frame (C1).
    func isHeroCaught(_ rect: QDRect, protectInvisible: Bool, bigInset: Bool) -> Bool {
        guard hero.state == 2, !protectInvisible || !hero.invisible else { return false }
        var rect = rect
        let d: Int16 = bigInset ? 0xb : 4
        rect.inset(dx: d, dy: d)
        var heroRect = hero.rect
        if bigInset {
            heroRect.inset(dx: 8, dy: 8)
        }
        return heroRect.collides(rect)
    }

    /// `_HeroCaught(kind) @ 00021dfa`: hero state 3 **first**, stateStart = frame, `_StopAllEnemies`, `_NewOuch`
    /// (display only). Kind 1: one `GetRandomFast(0,1)` (the "ouch" sound choice: 0 → 37, else 10). Kind 2: sound 0,
    /// then one `GetRandomFast(0,1)` (0 → 45, else 11, +5 frames), `_Splats_NewSplat(hero.left, hero.top, 1)`, `_NewStarGroup(col·40, row·40, 0xe)` (14 hop stars, C2),
    /// then `hero[0x4a] = 0` — the **visible** flag, not the invisibility bonus `+0x50` (B6). Any other kind: nothing
    /// more. Also latches `heroCaughtThisFrame` (the replica's report flag, Task 10).
    mutating func heroCaught(kind: Int) {
        hero.state = 3
        hero.stateStart = frame
        stopAllEnemies()
        heroCaughtThisFrame = true
        if kind == 1 {
            // 00021e80: the draw picks "Ayeeee" (0) or "Oooer" — no extra draw.
            playMySnd(rng.fast(0, 1) == 0 ? 0x25 : 10, priority: 0x14)
        } else if kind == 2 {
            playMySnd(0, priority: 0x14)                            // 00021ea1 "Squish"
            // 00021eef: the draw picks "Yeow" (0) or "Zoiks", delayed 5 frames — no extra draw.
            playMySnd(rng.fast(0, 1) == 0 ? 0x2d : 0xb, priority: 0x14, delay: 5)
            splats.newSplat(x: hero.rect.left, y: hero.rect.top, kind: 1, frame: frame)
            let x = Int16(hero.col) &* 0x28, y = Int16(hero.row) &* 0x28
            stars.newGroup(x: x, y: y, group: 0xe, hero: heroAnchor, frame: frame, prefs: config.prefs, rng: &rng)
            hero.visible = false
        }
    }

    /// `_StopAllEnemies @ 000110c8`: every enemy slot 0…29 whose state is 1, 2, 3, 4 or 6 (mask 0x5e) → state 5,
    /// stateStart = frame.
    mutating func stopAllEnemies() {
        for i in enemies.indices {
            let s = enemies[i].state
            if s < 7 && (1 << s) & 0x5e != 0 {
                enemies[i].state = 5
                enemies[i].stateStart = frame
            }
        }
    }

    /// `_SetHeroInvisibility(on) @ 00021bee`: on → `+0x50` = 1, start = frame, draw-transparent = 1, blink counter 0,
    /// blink toggle 0; off → `+0x50` = 0, draw-transparent = 0.
    mutating func setHeroInvisibility(_ on: Bool) {
        if on {
            hero.invisible = true
            hero.invisibleStart = frame
            hero.drawTransparent = true
            hero.blinkCounter = 0
            hero.blinkToggle = false
        } else {
            hero.invisible = false
            hero.drawTransparent = false
        }
    }
}
