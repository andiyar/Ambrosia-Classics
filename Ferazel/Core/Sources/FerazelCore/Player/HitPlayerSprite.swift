import Foundation

/// `.HitPlayerSprite(player, other) @ 100556f4` (decompile l. 48450–49929), reached only through the player pass
/// `.MTCollideSpecialSprite(player, .HitPlayerSprite)` (platforms-ropes-radial-2 §8.3). The arms built so far: the
/// entry gates and the **Platform** arm (W1). // later: the Bonus arm (Phase 4), the Box / see-saw segment arm (W3),
/// the Background arm (W2a), the enemy and shot arms (Phase 4–5).
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
        guard o.handler == .platform, !o.handleCleared else { return }   // later: the other arms
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
