import Foundation

/// `.CastSpell(player) @ 10051d1c` (M l. 46653–46980; raw `10051d1c..10052964`; spells-items §2, spells-detail §2.3),
/// called by row 31 of `.HandlePlayerSprite` at wand step 4 while magic > 0 (`Player.wand`).
public enum CastSpell {
    /// `*_DAT_100a0424` = snd 300 (the cast sound of every spell; pickups-boxes-2 §1.2).
    public static let sound: Int16 = 300

    /// The per-case cost (`G+0xe −=`, no floor) and the damage stored into `+0xa4` (`unaff_r23`), ids 0…7
    /// (M l. 46726–46892).
    static let costs: [(cost: Int16, damage: Int16)] = [(8, 100), (0x20, 200), (10, 100), (0x1e, 300), (8, 100),
                                                         (8, 100), (8, 0x96), (0xc, 0x96)]

    /// The cast, in the binary's order:
    /// 1. the facing `+0x17e` of the player record (last frame's mirror — row 34 writes it later); the spell = the
    ///    selected slot's id (`G + 0x24 + 10·G+0x172`; slot −1 reads 0); power = 1 + the count of item 0x13 —
    ///    the count alone while the loss timer `_DAT_100a073c > 1` (M l. 46699–46708); type = id·256 + power;
    /// 2. the carried speed |ridden vx| on a magic carpet (`PTR_DAT_100a05a4` ∧ `PTR_DAT_100a0558`); the offsets
    ///    (0x1e, 0x23) on the glider, gy 8 on a rope; exertion `_DAT_100a06a4 += 0x19`; `_DAT_100a0768 = 0`;
    /// 3. per case: `.STPlay3DSoundRand(snd 300, 1, 0x100, player +0xe)` — its FastRand(10000) first (plan hazard
    ///    "The cast sound comes first") —, the cost, `MTNewSprite(type, x + gx + 0x26, y + gy + 0x33 (0x42 crouching),
    ///    0xb, −1, .SetupPlayerShotSprite)` (case 5: + 0x20 / 0x32), then vx = |pvx >> 1| + FastRand(100) + carried +
    ///    0xd2f (case 5: 0xed8), vy = pvy >> 1 (case 5: − 0x80); case 6 (V Blade): two spawns at (centre x + gx − 0x14,
    ///    y + gy + 0x2a / 0x34 (crouching 0x34 / 0x39)) — the lower of type 0x3c00 + power —, vx = FastRand(256) − 0x80
    ///    each, vy −4000 / +4000, the lower's `+0xa4` 0x96, `_DAT_100a0768 = 1`; any other id: no case (the stores
    ///    through the null shot are dropped);
    /// 4. `_DAT_100a0760 = 1`; the first shot's `+0xa4`; UP (action 2) → vy −= 0x5dc, vx −= 0x2ee; ids 0, 1, 3, 4 →
    ///    vy −= 0x5dc (1000 crouching); vy += FastRand(0x4b) − 0x28; the facing inverted while clinging to a wall
    ///    side 1 / 2 (`_DAT_100a0758 ≠ 0`, `(u16)(PTR_DAT_100a074c − 1) < 2`);
    /// 5. the Shadow Double copy (`shadowCopy`) while `_DAT_100a0658 ≠ 0`;
    /// 6. facing left → the first shot's vx negated (the lower V Blade keeps its own).
    /// A spawn that finds no free record (Ruling 16) runs no Setup; every store to it is dropped and the later draws are
    /// still made.
    public static func cast(world w: SpriteWorld, player pID: Int, keys: InputActions) {
        guard let p = w.active.record(id: pID) else { return }
        var left = p.mirrored
        let g = w.globals
        let sel = Int(g.selectedSlot)
        let spell = g.inventory.indices.contains(sel) ? g.inventory[sel].id : 0
        var power: Int16 = 1
        if let k = g.hasItemWhichSlot(0x13) {
            let n = g.inventory[k].count
            power = n &+ 1
            if 1 < w.player.countdown073c { power = n }
        }
        let type = Int16(truncatingIfNeeded: Int32(spell) &* 0x100 &+ Int32(power))
        var carried: Int32 = 0
        if w.player.carpet, let r = w.player.ridden {
            let v = w.active.record(id: r)?.vx ?? 0
            carried = v < 1 ? 0 &- v : v
        }
        var gx = 0, gy = 0
        if w.player.glider {
            gx = 0x1e
            gy = 0x23
        }
        if w.player.rope { gy = 8 }
        w.player.exertion &+= 0x19
        w.player.vBladeCast = false
        let crouching = w.player.crouch != 0
        let px = Int(Int16(truncatingIfNeeded: p.x)), py = Int(Int16(truncatingIfNeeded: p.y))
        var shot: Int?
        var lower: Int?
        var damage: Int16 = 0
        if (0...7).contains(spell) {
            w.player.cue(PlayerCue(call: .threeDRand, snd: sound, priority: 1, volume: 0x100, position: p.centre,
                                   rate: w.rng.soundRate()))
            damage = costs[Int(spell)].damage
            w.globals.magic &-= costs[Int(spell)].cost
            let ax = p.vx >> 1, half = ax < 1 ? 0 &- ax : ax
            switch spell {
            case 5:
                shot = PlayerShot.spawn(w, type: type, x: px + gx + 0x26, y: py + gy + (crouching ? 0x32 : 0x20))
                let r = Int32(w.rng.next(100))
                if let shot {
                    w.active.update(id: shot) { s in
                        s.vx = half &+ r &+ carried &+ 0xed8
                        s.vy = (p.vy >> 1) &- 0x80
                    }
                }
            case 6:
                let x = Int(Int16(truncatingIfNeeded: p.centre.x)) + gx - 0x14
                shot = PlayerShot.spawn(w, type: type, x: x, y: py + gy + (crouching ? 0x34 : 0x2a))
                lower = PlayerShot.spawn(w, type: Int16(truncatingIfNeeded: Int32(power) &+ 0x3c00), x: x,
                                         y: py + gy + (crouching ? 0x39 : 0x34))
                let ru = Int32(w.rng.next(0x100))
                if let shot {
                    w.active.update(id: shot) { s in
                        s.vx = ru &- 0x80
                        s.vy = -4000
                    }
                }
                let rl = Int32(w.rng.next(0x100))
                if let lower {
                    w.active.update(id: lower) { s in
                        s.vx = rl &- 0x80
                        s.vy = 4000
                        s.hp = 0x96
                    }
                }
                w.player.vBladeCast = true
            default:
                shot = PlayerShot.spawn(w, type: type, x: px + gx + 0x26, y: py + gy + (crouching ? 0x42 : 0x33))
                let r = Int32(w.rng.next(100))
                if let shot {
                    w.active.update(id: shot) { s in
                        s.vx = half &+ r &+ carried &+ 0xd2f
                        s.vy = p.vy >> 1
                    }
                }
            }
        }
        w.player.useDebounce = true
        let up = keys.contains(.up)
        let arc = UInt16(bitPattern: spell) < 2 || UInt16(bitPattern: spell &- 3) < 2
        let jitter = Int32(w.rng.next(0x4b))
        if let shot {
            w.active.update(id: shot) { s in
                s.hp = damage
                if up {
                    s.vy &-= 0x5dc
                    s.vx &-= 0x2ee
                }
                if arc { s.vy &-= crouching ? 1000 : 0x5dc }
                s.vy = jitter &+ s.vy &- 0x28
            }
        }
        if w.player.climb != 0 && UInt16(bitPattern: w.player.wallSide &- 1) < 2 { left = !left }
        if let dbl = w.player.shadowDoubleSprite {
            let copyType = type &- power &+ 1
            shadowCopy(w, of: shot, type: copyType, player: p, double: dbl)
            if let lower { shadowCopy(w, of: lower, type: copyType, player: p, double: dbl) }
        }
        if left, let shot { w.active.update(id: shot) { $0.vx = 0 &- $0.vx } }
    }

    /// The Shadow Double's copy of a shot (M l. 46914–46973; raw `10052700..10052930`; spells-detail §2.3): `MTNewSprite(
    /// id·256 + 1, player x, y, 0xb, −1, .SetupPlayerShotSprite)` — the lower V Blade's copy is the upper's type too
    /// (the type is computed once) —; its spawn point (`+6`/`+8`) = the shot's moved by double − player (16-bit), the
    /// position `+0xa`/`+0xc` and 24.8 from it; vx = the shot's (before the facing flip); vy = the shot's, − 0x44c when
    /// the double's replayed history entry (`PTR_DAT_100a0520[PTR_DAT_100a0590 >> 1]` byte +4) is grounded and the shot
    /// has gravity; `+0x17e` 0; vx negated when the double faces left. No `+0xa4` store: its damage stays 0. A shot whose
    /// spawn failed reads as zeros [LOW: the binary reads low memory].
    /// // later: SD — the double, its ring and its facing (no writer of `_DAT_100a0658` yet).
    static func shadowCopy(_ w: SpriteWorld, of shotID: Int?, type: Int16, player p: SpriteSlot, double dID: Int) {
        let src = shotID.flatMap { w.active.record(id: $0) } ?? SpriteSlot(type: 0, x: 0, y: 0)
        let d = w.active.record(id: dID) ?? SpriteSlot(type: 0, x: 0, y: 0)
        let ring = Int(w.player.rideRamp >> 1)
        let grounded = w.player.shadowRingGrounded.indices.contains(ring) && w.player.shadowRingGrounded[ring]
            && 0 < src.gravity
        guard let copy = PlayerShot.spawn(w, type: type, x: Int(Int16(truncatingIfNeeded: p.x)),
                                          y: Int(Int16(truncatingIfNeeded: p.y))) else { return }
        func h16(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }
        let ox = h16(h16(src.oldPosition.x) - h16(h16(p.x) - h16(d.x)))
        let oy = h16(h16(src.oldPosition.y) - h16(h16(p.y) - h16(d.y)))
        w.active.update(id: copy) { c in
            c.oldPosition = SpriteSlot.Point(x: ox, y: oy)
            c.x = ox
            c.y = oy
            c.x256 = Int32(ox) << 8
            c.y256 = Int32(oy) << 8
            c.vx = src.vx
            c.vy = src.vy &+ (grounded ? -0x44c : 0)
            c.mirrored = false
            if d.mirrored { c.vx = 0 &- c.vx }
        }
    }
}
