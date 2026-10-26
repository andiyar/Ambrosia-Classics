import Foundation

/// The power-up timers (plan PU; spells-items §5, held-item-melee §3): `.TickTock @ 1004c1bc` (M l. 43583–43663), row
/// 14 of `.HandlePlayerSprite` (M l. 44748–44808) and `.DoubleSpeedTrail @ 1004d370` (M l. 44302–44395). The spheres
/// that set the timers are PK's (`HitPlayerSprite.sphere`, M l. 49023–49121). The flags' readers (dump; the plan's
/// "rows 5, 8, 9, 23, 36" is wrong — rows 8 and 23 read none): `.HandlePlayerSprite` row 5 (`0620`, M l. 44559), row 9
/// (`0638` / `062c`, M l. 44662–44665), row 11 (`0654`, M l. 44674), row 33 (`0620` M l. 45893 / 45924, `062c` M l.
/// 46116), row 36 (the blink flags with their actives, M l. 46255–46258); `.HandleKeys` (`0620`, M l. 47418–47709);
/// `.HandleShadowSprite` (`0654`, M l. 43072); `.HitPlayerTileSprite`'s walk-on-liquid rewrite (`0648`, M l. 48166);
/// `.HitPlayerSprite` (`0648` with `063c`, M l. 49314–49319 / 49774–49780).
public enum PowerUps {
    /// `*_DAT_100a03c8` = 428 (the warning tick and the time-up sound) / `*_DAT_100a03c4` = 429 (the tock).
    static let tickSound: Int16 = 428
    static let tockSound: Int16 = 429

    /// `.TickTock(t)` (M l. 43583–43663; raw `1004c1bc..`): `t > 0` → `t −= 1`; reaching 0 →
    /// `.STPlay3DSoundPitched(428, 0x14, 0x100, *_DAT_100a1998, 32000)` and the shared flag `cRam100a5fd4` = 1 (the
    /// position word at `0x100a1998` is 0 in the PEF data: (0, 0)). Then, on the value now held: 210, 180, 150, 120,
    /// 90, 60, 30 → `.STPlayRegSound(428, 1, 0x100)` and the flag toggled; 195, 165, 135, 105, 75, 45, 15 → snd 429 and
    /// toggled. Returns the flag. The flag is the byte `0x100a5fd4` (`r2 − 0x186c`), which `.ClearPlayerVars` sets to 1
    /// (raw `1004ad30 stb`): `PlayerState.flag5fd4`, shared by every timer.
    @discardableResult
    static func tickTock(_ p: inout PlayerState, _ timer: WritableKeyPath<PlayerState, Int16>) -> Bool {
        if 0 < p[keyPath: timer] {
            p[keyPath: timer] -= 1
            if p[keyPath: timer] == 0 {
                p.cue(PlayerCue(call: .threeDPitched, snd: tickSound, priority: 0x14, volume: 0x100,
                                position: SpriteSlot.Point(x: 0, y: 0), rate: 32000))
                p.flag5fd4 = true
            }
        }
        // A negative timer would pass the mark test below (Swift `%` keeps the sign); no writer makes one.
        let t = p[keyPath: timer]
        if t != 0, t <= 210, t % 15 == 0 {
            p.cue(PlayerCue(call: .reg, snd: t % 30 == 0 ? tickSound : tockSound, priority: 1, volume: 0x100))
            p.flag5fd4.toggle()
        }
        return p.flag5fd4
    }

    /// Row 14 (M l. 44748–44808): `.TickTock` of `0650` (Invincibility — no flag of its own; the player's `+0x116`
    /// counts itself down in `.StandardSpriteHandles`), `064c` (the Shadow Double: `0654` = timer ≥ 1 ∧ the shared
    /// flag — the double itself is row 11's, `ShadowDouble.row11`), `0640` (walk-on-liquid: `0648` = timer ≥ 1, `0644` = the
    /// flag while it runs), `0630` (High Jump: `0638` / `0634`), `0624` (Feather Fall: `062c` / `0628`), `0618` (Double
    /// Speed: `0620` / `061c`). A blink flag is written only while its timer runs (left as it was at 0).
    static func tickTimers(_ p: inout PlayerState) {
        tickTock(&p, \.invincibleTimer)
        tickTock(&p, \.shadowTimer)
        p.shadowDouble = 0 < p.shadowTimer && p.flag5fd4
        tickTock(&p, \.walkOnLiquidTimer)
        p.walkOnLiquid = 0 < p.walkOnLiquidTimer
        if p.walkOnLiquid { p.tint0644 = p.flag5fd4 }
        tickTock(&p, \.highJumpTimer)
        p.highJump = 0 < p.highJumpTimer
        if p.highJump { p.tint0634 = p.flag5fd4 }
        tickTock(&p, \.featherFallTimer)
        p.featherFall = 0 < p.featherFallTimer
        if p.featherFall { p.tint0628 = p.flag5fd4 }
        tickTock(&p, \.doubleSpeedTimer)
        p.doubleSpeed = 0 < p.doubleSpeedTimer
        if p.doubleSpeed { p.tint061c = p.flag5fd4 }
    }

    /// `.DoubleSpeedTrail(s)` (M l. 44302–44395; held-item-melee §3), from row 42 (M l. 46615) and the player's
    /// `.HandleCannonedSprite` (M l. 50038). The ring `PTR_DAT_100a051c` shifts (entry n ← n + 1), entry 4 = the
    /// player's (y, x) `+0xa`, face `+0xc0`, mirror `+0x17e`. Double Speed off (`0620` 0): each trail sprite's face 0 and
    /// `+0x88` 0. On: trail i takes entry s = (i >> 1) + 2 — even i its position, odd i the midpoint of s and
    /// min(s + 1, 4) (`(a + b) >> 1` on the i16 values) — then `+0x14`/`+0x1c` = x, y << 8, the entry's mirror and face,
    /// `+0x88` 0, and `+0xb8` 0xb0002 / 0xb0000 / 0xb0001 / 0 / 0 for i 0…4. A trail slot whose sprite is 0 is skipped.
    static func doubleSpeedTrail(_ w: SpriteWorld, player id: Int) {
        guard let s = w.active.record(id: id) else { return }
        var ring = w.player.trailPoses
        ring.removeFirst()
        ring.append(PlayerState.TrailPose(face: s.face, y: Int16(truncatingIfNeeded: s.y),
                                          x: Int16(truncatingIfNeeded: s.x), mirrored: s.mirrored))
        w.player.trailPoses = ring
        let sprites = w.player.trail
        guard w.player.doubleSpeed else {
            for t in sprites.compactMap({ $0 }) {
                w.active.update(id: t) { c in
                    c.face = nil
                    c.lightOverlay = false
                }
            }
            return
        }
        for (i, t) in sprites.enumerated() {
            guard let t else { continue }
            let e = (i >> 1) + 2
            let a = ring[e]
            var y = a.y, x = a.x
            if i & 1 != 0 {
                let b = ring[min(e + 1, 4)]
                x = Int16(truncatingIfNeeded: (Int32(a.x) + Int32(b.x)) >> 1)
                y = Int16(truncatingIfNeeded: (Int32(a.y) + Int32(b.y)) >> 1)
            }
            let mode: UInt32
            switch i {
            case 0: mode = 0xb0002
            case 1: mode = 0xb0000
            case 2: mode = 0xb0001
            default: mode = 0
            }
            w.active.update(id: t) { c in
                c.y = Int(y)
                c.x = Int(x)
                c.x256 = Int32(x) << 8
                c.y256 = Int32(y) << 8
                c.mirrored = a.mirrored
                c.face = a.face
                c.lightOverlay = false
                c.mode = mode
            }
        }
    }
}
