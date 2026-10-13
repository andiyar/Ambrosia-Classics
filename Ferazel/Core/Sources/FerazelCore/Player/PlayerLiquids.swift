import Foundation

/// The player's liquid and hazard rows of `.HandlePlayerSprite @ 1004d5fc` (plan P4; player-states §3, physics-sprites
/// §8.6/§8.8): row 17 (liquid damage / heal), row 28's damaging surface (material 2), row 35 (oxygen, drowning,
/// bubbles), row 41 (the death trigger, the breath refill) and `.EmitBubble @ 1004ba74`. `G` = the game globals
/// (`_DAT_1009ffc0`): `+4` health, `+6` oxygen, `+8` suffocation countdown, `+0xa` max health, `+0xc` max magic,
/// `+0xe` magic. The sound ids are the `_DAT_100a0xxx` / `_DAT_1009fxxx` slots' (pickups-boxes-2 §1). Every call here
/// is `.STPlayRegSound` (no `FastRand` draw); the only draw is row 35's bubble timer `FastRand(0x96)`.
public enum PlayerLiquids {
    /// The bubble (`.EmitBubble`'s `MTNewSprite(0x410, …)`; PICT 1040, 4 faces 8×8, `.InitEffectSprite` l. 53656).
    public static let bubble: Int16 = 0x410

    /// Row 17 (l. 44856–44908), after `.StandardSpriteHandles` and row 15:
    /// - out of liquid (`+0x120 == 0 ∧ +0x11c == 0`), or kind `+0x128` < 1 on a level whose hdr 0x26cd is 0 → the counter
    ///   `PTR_DAT_100a0538` = 0;
    /// - else counter < 2 → +1 (frames 1 and 2 in the liquid do nothing more);
    /// - else kind 3 (healing): while `+0xa4 > 0`: oxygen G+6 += 8 (capped at G+0xa); healing = G+4 < G+0xa → `+0xa4`
    ///   += 4 (no cap on `+0xa4`); G+0xe < G+0xc → magic += 4, healing; then healing → 803 (`*_DAT_1009fe5c`, prio 1,
    ///   vol 0xab) **only if it is not playing** (`FUN_100916dc`); nothing heals → 803 stopped (`FUN_10091504`, no
    ///   playing test);
    /// - else kind 0…2 (0 only reaches here on a 0x26cd level; negative kinds do nothing), not invulnerable, the
    ///   cooldown `_DAT_100a06d8` 0 and `+0xa4 > 4` → 407 (`*_DAT_100a0404`, prio 1, vol 0x100), cooldown 0x23, flash
    ///   `+0xaa` 0xd, HP −0x70, invulnerable 0x3c. Row 18 counts the cooldown down the same frame.
    static func liquidDamage(_ w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id) else { return }
        let kind = s.waterKind
        if (s.lastWater == 0 && s.waterRow == 0) || (kind < 1 && w.level.header.inLiquid == 0) {
            w.player.liquidCounter = 0
        } else if w.player.liquidCounter < 2 {
            w.player.liquidCounter += 1
        } else if kind == 3 {
            var healing = false                                         // `bStack_6c`
            if 0 < s.hp {
                var g = w.globals
                g.breath &+= 8
                if g.maxHealth < g.breath { g.breath = g.maxHealth }
                healing = g.health < g.maxHealth
                if healing { w.active.update(id: id) { $0.hp &+= 4 } }
                if g.magic < g.maxMagic {
                    g.magic &+= 4
                    healing = true
                }
                w.globals = g
            }
            if healing {
                w.player.cues.append(PlayerCue(call: .reg, snd: 803, priority: 1, volume: 0xab, onlyIfIdle: true))
            } else {
                w.player.cues.append(PlayerCue(call: .stop, snd: 803))
            }
        } else if kind < 3 && 0 <= kind {
            if s.invulnerable == 0 && w.player.countdown06d8 == 0 && 4 < s.hp {
                w.player.cues.append(PlayerCue(call: .reg, snd: 407, priority: 1, volume: 0x100))
                w.player.countdown06d8 = 0x23
                w.active.update(id: id) { p in
                    p.flash = 0xd
                    p.hp &-= 0x70
                    p.invulnerable = 0x3c
                }
            }
        }
    }

    /// Row 28's material-2 arm (l. 45106–45123; raw `1004eb24..1004ebc4`): a damaging surface under the move
    /// (`+0xd8 == 2`, FG kind 2xx). Not invulnerable and not dying (`_DAT_100a069c`): damage = hdr 0x270e (0 → 0x70);
    /// stun `_DAT_100a0748` = 1; spin `PTR_DAT_100a0668` = 0; 427 (`*_DAT_100a03cc`, r25) stopped if it is playing;
    /// 450 (`*_DAT_100a02dc`, prio 1, vol 0x100); invulnerable 0x3c; flash 0x12; HP −damage. The ice globals are left
    /// as they are on this arm.
    static func damagingSurface(_ w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id), s.invulnerable == 0, w.player.dying == 0 else { return }
        var damage = w.level.header.landingDamage                       // `sStack_6e`
        if damage == 0 { damage = 0x70 }
        w.player.stun = 1
        w.player.spin = false
        w.player.cues.append(PlayerCue(call: .stopIfPlaying, snd: 427))
        w.player.cues.append(PlayerCue(call: .reg, snd: 450, priority: 1, volume: 0x100))
        w.active.update(id: id) { p in
            p.invulnerable = 0x3c
            p.flash = 0x12
            p.hp &-= damage
        }
    }

    /// Row 35 (l. 46204–46241), while `.ShouldEmitBubbles` (not dying, `0 < +0x120 < 0xf`): oxygen −8 in kind 5, else
    /// −1; oxygen < 1 and not invulnerable → the countdown G+8 == 0: oxygen 0, 443 (`*_DAT_100a0394`, prio 1, vol
    /// 0x100), HP −0x70, invulnerable 0x28, G+8 = 0xf in kind 5 else 0x1e; else G+8 −1. Then the bubble timer
    /// `_DAT_100a5f56`: 0 → `.EmitBubble` unless kind 5, and the timer = `FastRand(0x96) + 200` (drawn in kind 5 too);
    /// else −1.
    static func bubbles(_ w: SpriteWorld, id: Int) {
        guard Breathing.shouldEmitBubbles(world: w, id: id), let s = w.active.record(id: id) else { return }
        let quicksand = s.waterKind == 5
        w.globals.breath &-= quicksand ? 8 : 1
        if w.globals.breath < 1 && s.invulnerable == 0 {
            if w.globals.suffocation == 0 {
                w.globals.breath = 0
                w.player.cues.append(PlayerCue(call: .reg, snd: 443, priority: 1, volume: 0x100))
                w.active.update(id: id) { p in
                    p.hp &-= 0x70
                    p.invulnerable = 0x28
                }
                w.globals.suffocation = quicksand ? 0xf : 0x1e
            } else {
                w.globals.suffocation &-= 1
            }
        }
        if w.player.bubbleTimer == 0 {
            if !quicksand { emitBubble(w, id: id) }
            w.player.bubbleTimer = w.rng.next(0x96) &+ 200
        } else {
            w.player.bubbleTimer &-= 1
        }
    }

    /// `.EmitBubble(s) @ 1004ba74` (l. 43284–43312), from row 35 and `.HandleBreathing`: not in kind 5 — the cooldown
    /// `PTR_DAT_100a06f4` < 1 → `MTNewSprite(0x410, +0x10 ± 0x10, +0xe − 0x10, 0xb, −1, .SetupEffectSprite)` (+0x10
    /// while `+0x17e` is clear, −0x10 while set; i16 sums), cooldown 2, 415 (`*_DAT_100a03f4`, prio 1, vol 0xab); else
    /// cooldown −1. Neither the 0x410 Setup (it skips the particle package and the light, l. 53745–53752) nor the
    /// sound draws `FastRand`.
    static func emitBubble(_ w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id), s.waterKind != 5 else { return }
        if w.player.bubbleCooldown < 1 {
            let dx = s.mirrored ? -0x10 : 0x10
            let x = Int(Int16(truncatingIfNeeded: s.centre.x + dx))
            let y = Int(Int16(truncatingIfNeeded: s.centre.y - 0x10))
            w.newSprite(type: bubble, x: x, y: y, layer: 0xb, handler: .effect) { EffectSprite.setup(&$0) }
            w.player.bubbleCooldown = 2
            w.player.cues.append(PlayerCue(call: .reg, snd: 415, priority: 1, volume: 0xab))
        } else {
            w.player.bubbleCooldown -= 1
        }
    }

    /// Row 41 (l. 46438–46488), after the end pass:
    /// - the death trigger: `+0xa4 < 1`, not dying, not stunned → wind scale `+0x90` 0, died-in-liquid
    ///   `PTR_DAT_100a0560` = (`+0x11c ≠ 0 ∨ +0x120 ≠ 0`), 417 (`*_DAT_100a03ec`, prio 1, vol 0x100), dying
    ///   `_DAT_100a069c` = 1 (row 33's dying arm then runs from the next frame; its end sets the game-over flag
    ///   `DAT_100a5106` for W4);
    /// - the liquid screen tint (`+0x11c` 1…9 → `.TintScreen(kind 0 blue / 1 green / 2 red / else black, 15)` and
    ///   `PTR_DAT_100a066c` 1; `+0x11c` > 10, or 0 with the flag set → `.TintScreen(0, 0)`, flag 0; lighting-tables
    ///   §10) // later: no Phase-2 seam carries a screen tint (`.TintScreen @ 10034e88`);
    /// - not `.ShouldEmitBubbles` (tested after the trigger): oxygen < `+0xa4` → +8; < 0 → 1; > `+0xa4` → `+0xa4`;
    ///   G+8 = 0x1e.
    static func deathAndRefill(_ w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id) else { return }
        if s.hp < 1 && w.player.dying == 0 && w.player.stun == 0 {
            w.active.update(id: id) { $0.windScale = 0 }
            w.player.diedInLiquid = !(s.waterRow == 0 && s.lastWater == 0)
            w.player.cues.append(PlayerCue(call: .reg, snd: 417, priority: 1, volume: 0x100))
            w.player.dying = 1
        }
        if !Breathing.shouldEmitBubbles(world: w, id: id) {
            let hp = s.hp
            if w.globals.breath < hp { w.globals.breath &+= 8 }
            if w.globals.breath < 0 { w.globals.breath = 1 }
            if hp < w.globals.breath { w.globals.breath = hp }
            w.globals.suffocation = 0x1e
        }
    }
}
