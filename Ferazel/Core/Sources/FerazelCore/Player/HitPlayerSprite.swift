import Foundation

/// `.HitPlayerSprite(player, other) @ 100556f4` (decompile l. 48450–49929), reached only through the player pass
/// `.MTCollideSpecialSprite(player, .HitPlayerSprite)` (platforms-ropes-radial-2 §8.3). The arms built so far: the
/// entry gates, the **Platform** arm (W1) and the **Background** arm's pendulum part (W2a). // later: the Bonus arm
/// (Phase 4), the Box / see-saw segment arm (W3), the rest of the Background arm (W2b), the enemy and shot arms
/// (Phase 4–5).
public enum HitPlayerSprite {
    /// The entry gates (l. 48565–48570): dying (`_DAT_100a069c > 0`) → nothing; in spirit form (`_DAT_100a0578 > 0`)
    /// only a Bonus reaches its arm. Then the Platform arm (l. 49124–49147; `+0x4c == .HandlePlatformSprite`, so an
    /// idled record — `+0x4c = 0` — is no Platform):
    /// - the player's hot-rect centre offset (x = left + (right − left) >> 1, y = top + (bottom − top) >> 1);
    ///   the bumped / landed latches `_DAT_100a0720` / `_DAT_100a0724` cleared;
    /// - a catapult 0x582 / 0x583 whose record p1 == 2 is walk-through: return;
    /// - `.PlatformBounce(player, platform, centre, 0, player rect, 0)` — the player is the mover (a landing sets his
    ///   `+0xdc` and the platform's `+0xe0`, `+0x186`, sag);
    /// - the spiked underside 0x57d: when the player's centre y is at or below the platform's (`+0xe`), or he rises
    ///   faster than 0x200, not invulnerable and not riding it → `.STPlayRegSound(450, 1, 0xab)` (`_DAT_100a02dc`), HP
    ///   −0x70, invulnerable 0x3c, flash 0xc, return;
    /// - `.CheckGroundCeilingHitEffects(player)`.
    public static func hit(_ w: SpriteWorld, player pID: Int, other oID: Int) {
        guard w.player.dying <= 0 else { return }
        guard let o = w.active.record(id: oID) else { return }
        if 0 < w.player.spiritTimer {
            // later: Phase 4 — only the Bonus handler (`PTR_PTR_100a047c`) passes; no Phase-2 Bonus arm.
            return
        }
        guard !o.handleCleared else { return }                          // `+0x4c == 0`: no arm
        switch o.handler {
        case .platform: break
        case .background:
            background(w, player: pID, other: oID)
            return
        default: return                                                 // later: the other arms
        }
        guard let p = w.active.record(id: pID) else { return }
        let r = p.hotRect
        let h = { (v: Int) in Int(Int16(truncatingIfNeeded: v)) }
        let centre = SpriteSlot.Point(x: h(r.left + h((r.right - r.left) >> 1)), y: h(r.top + h((r.bottom - r.top) >> 1)))
        w.player.bumpedLatch = false                                    // `*_DAT_100a0720 = 0`
        w.player.landedLatch = false                                    // `*_DAT_100a0724 = 0`
        if o.type == 0x582 || o.type == 0x583, PlatformSprite.record(w, o)?.p1 == 2 { return }
        w.platformBounce(mover: pID, solid: oID, centre: centre, factor: 0, rect: r, bounce: false)
        guard let p1 = w.active.record(id: pID), let o1 = w.active.record(id: oID) else { return }
        if o1.type == PlatformSprite.spiked,
           Int16(truncatingIfNeeded: o1.centre.y) <= Int16(truncatingIfNeeded: p1.centre.y) || p1.vy < -0x200,
           p1.invulnerable < 1, p1.ridden != oID {
            w.player.cues.append(PlayerCue(call: .reg, snd: 450, priority: 1, volume: 0xab))
            w.active.update(id: pID) { s in
                s.hp &-= 0x70
                s.invulnerable = 0x3c
                s.flash = 0xc
            }
            return
        }
        GroundCeilingEffects.check(w, id: pID)
    }
}

extension HitPlayerSprite {
    /// The Background arm (`+0x4c == PTR_PTR_100a0480`, decompile l. 49573–49592) as far as W2a builds it:
    /// - d = (player `+0x10` − other `+0xc`, player `+0xe` − other `+0xa`) — the player's centre against the other's
    ///   origin, as written (the point `.PlatformBounce` gets);
    /// - // later: fire 0x4b8 / 0x4bb…0x4bd → `.HurtPlayer(…, 0xe0, 1, 0x3c, 0)` unless `HasItem(0x18)` and
    ///   `+0x14c < 1` (Phase 4: the inventory) — none placed on levels 1–2;
    /// - **the pendulum arm** (0x5c8…0x5d1, l. 49583–49592): player `+0x116 == 0` and other `+0x170 == 1` →
    ///   `.HurtPlayer(player, other, 0xe0, blood 1, invul 0x3c, coins 5)` and then `+0x116 = 0x1e` — **whether or not
    ///   the hurt landed**; then, if the other's one-way `+0x185` is 0, `.PlatformBounce(player, other, d, 0, player
    ///   `+0x34`, 0)` (modes 10–14 set it, so only a mode-0 / 3–9 / 15+ bar is solid); return.
    /// - // later: W2b — passages 0xb54 / 0xb55 (l. 49594–49690), cannons, springs, tunnels.
    static func background(_ w: SpriteWorld, player pID: Int, other oID: Int) {
        guard let p = w.active.record(id: pID), let o = w.active.record(id: oID) else { return }
        let h = { (v: Int) in Int(Int16(truncatingIfNeeded: v)) }
        let d = SpriteSlot.Point(x: h(p.centre.x - o.x), y: h(p.centre.y - o.y))
        guard BackgroundSprite.maces.contains(o.type) else { return }    // later: W2b
        if p.invulnerable == 0 && o.classWord170 == 1 {
            HurtPlayer.hurt(w, player: pID, attacker: oID, damage: 0xe0, blood: true, invulnerable: 0x3c, coins: 5)
            w.active.update(id: pID) { $0.invulnerable = 0x1e }
        }
        guard let o1 = w.active.record(id: oID), !o1.oneWay, let p1 = w.active.record(id: pID) else { return }
        w.platformBounce(mover: pID, solid: oID, centre: d, factor: 0, rect: p1.hotRect, bounce: false)
    }
}

/// `.HurtPlayer(player, attacker, damage, blood, invul, coins) @ 1005473c` (decompile l. 47955–48105;
/// enemy-shots-and-damage §3.7). Returns whether the hurt landed.
/// 1. **The attacker gate** (l. 47983–47985, raw `10054768..10054794`): an attacker with HP `+0xa4` < 1 whose Handle is
///    neither `.HandleEnemyShotSprite` (`PTR_PTR_100a0488`) nor `.HandleBoxSprite` (`PTR_PTR_100a0484`) hurts not at
///    all (0, no draw). [Plan W2a named "Platform / Background" — the dump and the bank (review A3) say EnemyShot /
///    Box.] Core has no EnemyShot Handle yet: // later: Phase 4 (enemy shots are `inert` until then).
/// 2. `.HurtSprite(player, damage, (i16) attacker vx, −1000, invul, 0xc)` (`HurtSprite.apply`); 0 → return 0.
/// 3. // later: Phase 4 — item 0x13 (`HasItemWhichSlot(0x13)`, the attacker not a Blob nor a Background 0x730…0x733):
///    `_DAT_100a073c = 0xf`, snd 507, `PTR_DAT_1009fda8 = 0xf`, four 0x4bf + i sprites with 3 draws each. No Phase-2
///    inventory holds it.
/// 4. `_DAT_100a059c = 5`; on a magic carpet (`PTR_DAT_100a05a4`) a rising ridden sprite (`PTR_DAT_100a0558`
///    `+0x2c < 0`) stops; `_DAT_100a05b0 = 0`, stun `_DAT_100a0748 = 1`, spin `PTR_DAT_100a0668 = 0`, pull-up
///    `_DAT_100a06a0 = 0`, climb `_DAT_100a0758 = 0`, exertion `_DAT_100a06a4 += 0x50`.
/// 5. blood → `.BloodSpray(player, attacker, 0x28, 500, 0x96, 2)` (`bloodSpray`, the E1a seam).
/// 6. The cues (snd slots: 508 `a02b8`, 450 `a02dc`, 401 `a0414`, 402 `a0410`, 403 `a040c`): damage < 0xe0 →
///    `.STPlayRegSoundPitched(508, 1, 0x97, FastRand(10000) + 65000)`, then R = `FastRand(3)`: 1 → `.STPlayRegSound(402,
///    1, 0xab)`, 0 → 401, 2 → 403; else `.STPlayRegSound(450, 1, 0xab)`, `.STPlayRegSoundPitched(508, 1, 0x100,
///    FastRand(10000) + 50000)`, `…(508, 1, 0x100, FastRand(10000) + 65000)`. The rates are drawn here, sound on or
///    off (Invariant 4; S1 does the volume arithmetic only).
/// 7. coins n ≠ 0: n > 2 → n = FastRand(3) + n − 1; capped at `G+0x10`; `G+0x10 −= n`; n > 0 →
///    `.STPlay3DSoundRand(489, 1, 0x100, player +0xe)`; per coin `FastRand(8)` (dy), `FastRand(8)` (dx), the Bonus
///    0x516 at (cx + dx − 8, cy + dy − 2), layer 0x14, `+0xb0 = 0xc`, vx = `FastRand(0x640)` + 600 (negated when
///    `FastRand(100)` > 0x31), vy = −2000 − `FastRand(0xdac)`, `+0x16c = −0xf0`. The coins are counted in
///    `PlayerState.coinsLost`, **not spawned** (// later: Phase 4); the five draws per coin are made.
public enum HurtPlayer {
    @discardableResult
    public static func hurt(_ w: SpriteWorld, player pID: Int, attacker aID: Int, damage: Int16, blood: Bool,
                            invulnerable: Int16, coins: Int16) -> Bool {
        guard let a = w.active.record(id: aID) else { return false }
        if a.hp < 1 && a.handler != .box { return false }               // later: Phase 4 — or the EnemyShot Handle
        guard HurtSprite.apply(w, id: pID, damage: damage, dvx: Int16(truncatingIfNeeded: a.vx), dvy: -1000,
                               invulnerable: invulnerable, flash: 0xc) else { return false }
        // later: Phase 4 — the item-0x13 arm (no Phase-2 inventory).
        w.player.carpetLock = 5
        if w.player.carpet, let r = w.player.ridden, let rs = w.active.record(id: r), rs.vy < 0 {
            w.active.update(id: r) { $0.vy = 0 }
        }
        w.player.potion = 0
        w.player.stun = 1
        w.player.spin = false
        w.player.pullUp = 0
        w.player.climb = 0
        w.player.exertion &+= 0x50
        if blood { bloodSpray(w, player: pID, attacker: aID, count: 0x28, speed: 500, spread: 0x96, kind: 2) }
        func cue(_ c: PlayerCue.Call, _ snd: Int16, _ vol: Int16, rate: Int32? = nil, pos: SpriteSlot.Point? = nil) {
            w.player.cues.append(PlayerCue(call: c, snd: snd, priority: 1, volume: vol, position: pos, rate: rate))
        }
        if damage < 0xe0 {
            cue(.regPitched, 508, 0x97, rate: Int32(w.rng.next(10000)) + 65000)
            switch w.rng.next(3) {
            case 1: cue(.reg, 402, 0xab)
            case 0: cue(.reg, 401, 0xab)
            case 2: cue(.reg, 403, 0xab)
            default: break
            }
        } else {
            cue(.reg, 450, 0xab)
            cue(.regPitched, 508, 0x100, rate: Int32(w.rng.next(10000)) + 50000)
            cue(.regPitched, 508, 0x100, rate: Int32(w.rng.next(10000)) + 65000)
        }
        if coins != 0 {
            var n = coins
            if 2 < n { n = w.rng.next(3) &+ n &- 1 }
            if w.globals.coins < n { n = w.globals.coins }
            w.globals.coins &-= n
            if 0 < n {
                let pos = w.active.record(id: pID)?.centre
                cue(.threeDRand, 489, 0x100, rate: w.rng.soundRate(), pos: pos)
            }
            var k: Int16 = 0
            while k < n {
                _ = w.rng.next(8)                                       // dy
                _ = w.rng.next(8)                                       // dx
                // later: Phase 4 — `MTNewSprite(0x516, …, .SetupBonusSprite)` (its Setup's draws come here).
                _ = w.rng.next(0x640)                                   // vx − 600
                _ = w.rng.next(100)                                     // vx sign
                _ = w.rng.next(0xdac)                                   // −vy − 2000
                k += 1
            }
            w.player.coinsLost &+= n
        }
        return true
    }

    /// The E1a seam: `.BloodSpray(s, attacker, count, speed, spread, kind) @ 100425f8` (particles §; 40 particles and
    /// their `FastRand` draws). // later: E1a builds it here — until then a hurt with blood draws less than the
    /// original (the stream diverges after the first bloody hit).
    static func bloodSpray(_ w: SpriteWorld, player: Int, attacker: Int, count: Int16, speed: Int16, spread: Int16,
                           kind: Int16) {}
}

/// `.HurtSprite(s, damage, dvx, dvy, invul, flash) @ 10037034` (decompile l. 32705–32726): damage < 1 or HP `+0xa4`
/// < 1 or `+0x116` ≠ 0 → 0; else HP −= damage, vx += dvx, vy += dvy, `+0x116 = invul`, `+0xaa = flash`, 1.
public enum HurtSprite {
    @discardableResult
    public static func apply(_ w: SpriteWorld, id: Int, damage: Int16, dvx: Int16, dvy: Int16, invulnerable: Int16,
                             flash: Int16) -> Bool {
        guard 0 < damage, let s = w.active.record(id: id), 0 < s.hp, s.invulnerable == 0 else { return false }
        w.active.update(id: id) { c in
            c.hp &-= damage
            c.vx &+= Int32(dvx)
            c.vy &+= Int32(dvy)
            c.invulnerable = invulnerable
            c.flash = flash
        }
        return true
    }
}
