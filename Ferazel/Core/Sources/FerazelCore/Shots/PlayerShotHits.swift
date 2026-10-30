import Foundation

/// What happens to a player shot when it hits something: `.KillPlayerShot` (`kill`; CS fix round 2, first called by the
/// spring arm of `.HitBackgroundSprite`, M l. 63718–63720) and `.HitPlayerShotSprite` (`hit`; SH). The tile callback
/// `.HitPlayerShotTileSprite` is `PlayerShot.hitTile`; the container arm of `.HitBonusSprite` is `BonusSprite.container`.
public enum PlayerShotHits {
    /// The snd slots `.KillPlayerShot` reads (`SoundSlots`): `*_DAT_100a0420` = 301 (the generic hit), `*_DAT_100a01e4`
    /// = 423 (the orb struck), `*_DAT_100a01e0` = 424 (the orb broken), `*_DAT_1009fdec` = 435 (the seed bursts),
    /// `*_DAT_100a03e4` = 419 (an id ≥ 100).
    static let hitSound: Int16 = 301, orbHitSound: Int16 = 423, orbBreakSound: Int16 = 424, seedSound: Int16 = 435,
               highSound: Int16 = 419
    /// `*_DAT_100a01fc` = 302 (the Tree Trunk's growth, `.STPlay3DSound`), `*_DAT_100a03e4` = 419 (the 2941's pitched
    /// hit, `.STPlay3DSoundPitched`).
    static let trunkSound: Int16 = 302, iceWallSound: Int16 = 419

    /// `.KillPlayerShot(shot, sound, effect) @ 1005ac34` (M l. 51076–51215; raw `1005ac34..1005b094`), in order:
    /// 1. `.StandardSpriteCleanup(shot)` (raw `1005ac58`, r3 = the shot — the decompile drops the argument);
    /// 2. id 100: nothing more;
    /// 3. power `+0x170` > 1: the four followers `+0x1d4…+0x1e0` get `+0xe9 = 1` (every id but 100, the orb included);
    /// 4. id ≥ 100 (≠ 0x5a — always true): `+0xa6 == 0` → `.STPlay3DSoundRand(419, 1, 0xab, +0xa)` (the position, not
    ///    the centre; no `sound` test); then `+0xa6 = −6`. The shot is **not** killed;
    /// 5. ids < 100: the effect flag is cleared when the face `+0xc0` is wholly outside the clip window
    ///    (`+0x1b6 ≥ face right` or `+0x1b8 ≤ face left`, the face's `+0xe` / `+0xa`), then by id —
    ///    - 0: `sound` → snd 301 at the centre `+0xe`; `effect` → `MTNewSprite(0, x − 8, y − 0xc, 0xb, −1,
    ///      .SetupEffectSprite)`; killed;
    ///    - 0x50 (the orb): `+0x168` − 1; below 1 → `sound` → snd 424, `.ExplodeFaceIntoParticles(+0xc0, +0xa, 2, 1, 7,
    ///      0x50, 0x65)`, killed; else `sound` → snd 423 and the orb lives (neither flag gates more);
    ///    - 0x5a (the seed): snd 435 (no `sound` test), the mask flash `*_DAT_100a00fc = 3`, the shake `*_DAT_1009ffa0
    ///      = 0x14`, `MTNewSprite(0x4b7, x − 0x2a, y − 0x2a, 0xc, −1, .SetupEffectSprite)` (`+0xf4` → its `+0xb8 =
    ///      0x10004`); `+0xf0` clear → a 4 × 4 walk over (x − 4 + 8i, y − 10 + 8j), i outer, a counter from 0 that spawns
    ///      at every second cell: `MTNewSprite(0x442, cx − 0x18, cy − 0x18, 0xc, −1, .SetupEffectSprite)`, `FastRand(
    ///      0x96)`, `FUN_1003f218(smoke, .FindDesiredDirectionGeneric((cy, cx), centre), R + 400)`, smoke `+0x46 =
    ///      FastRand(7)`; killed (no `effect` test);
    ///    - any other id: effect type 5 (id 4: 2); `sound` → snd 301; `effect` → `MTNewSprite(type, x − 5, y − 0xc, 0xb,
    ///      −1, .SetupEffectSprite)`; ids 1 / 2 → `.ChangeLightColor(effect +0x9a, 0x21)`, 3 → 0x4d, 4 → 0x42; killed.
    /// Every `.STPlay3DSoundRand` draws its `FastRand(10000)` at the call (Invariant 4). A spawn that finds no free
    /// record (Ruling 16) runs no Setup and its stores are dropped; the later draws are still made.
    /// Ids 1…4 with no effect sprite made: the binary changes the colour of the light named by `r29 + 0x9a`
    /// (`lha r3,0x9a(r29)`, raw `1005b044` / `1005b058` / `1005b06c`) — r29 is set only by the effect's `MTNewSprite`
    /// (raw `1005b018`), so on this path it still holds the **caller's** r29 (`stmw` saves it, nothing in between
    /// writes it). Per call site (SH, traced in the raw), `staleSlot` is that short:
    /// - the spring arm of `.HitBackgroundSprite`: the Background Handle's descriptor `PTR_PTR_100a0480` (raw
    ///   `10075060`) + 0x9a — a relocated word, load-address dependent [LOW]: nil, no light changed;
    /// - `.HitPlayerShotSprite`: r29 = the snd-303 slot (`lwz r29,-0x7424(r2)`, raw `1005a810`, the TOC word
    ///   0x21b19c → 0x102ba9dc) + 0x9a = 0x102baa76, the low half of the snd-432 Handle in the slot at 0x102baa74 (TOC
    ///   `a03b8`) — a Memory Manager address [LOW]: nil;
    /// - `.HitPlayerShotTileSprite`: r29 = the bounce factor (`li r29,0` / `li r29,0xa0`, raw `1005b0d8` /
    ///   `1005b130`), 0 for every id but the seed — the short at low-memory address 0x9a [LOW]: nil;
    /// - the container arm of `.HitBonusSprite`: r29 = G + 4 (`addi r29,r31,0x4`, raw `1005fdc0`) — the short at G + 0x9e,
    ///   inventory slot 12's count (`BonusSprite.container` passes it);
    /// - `.HitBoxSprite`'s crate arm (BX1): r29 = the shot itself (`or r29,r4,r4`, raw `10070038`) — its own light.
    /// `.ChangeLightColor` ignores a slot outside 0…199 (M l. 14419–14432).
    /// - Parameters: `sound` / `effect` the two flags; `effects` prefs+6 (the effect's Setup); `faceWidth` (face `+6`,
    ///   the Cleanup) and `faceBounds` (face `+8`, the clip test) — Core has no face records; `staleSlot` the caller's
    ///   `r29 + 0x9a` (nil: no light changed).
    public static func kill(_ w: SpriteWorld, shot id: Int, sound: Bool, effect effectFlag: Bool, effects: Int16,
                            lights: inout LightTable,
                            faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                            faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect,
                            staleSlot: Int16? = nil) {
        guard w.active.record(id: id) != nil else { return }
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
        guard let s = w.active.record(id: id), s.type != 100 else { return }
        if 1 < s.power {
            for f in PlayerShot.followers(s).compactMap({ $0 }) { w.active.update(id: f) { $0.dead = true } }
        }
        let x = PlayerShot.h16(s.x), y = PlayerShot.h16(s.y)
        func play(_ snd: Int16, volume: Int16 = 0x100, at position: SpriteSlot.Point) {
            w.player.cue(PlayerCue(call: .threeDRand, snd: snd, priority: 1, volume: volume, position: position,
                                   rate: w.rng.soundRate()))
        }
        func killed() { w.active.update(id: id) { $0.dead = true } }
        func spawn(_ type: Int16, _ x: Int, _ y: Int, layer: Int16) -> Int? {
            EffectSprite.spawn(w, type: type, x: x, y: y, layer: layer, effects: effects, lights: &lights)
        }
        guard s.type < 100 || s.type == PlayerShot.seed else {
            // 4.
            if s.counterA6 == 0 { play(highSound, volume: 0xab, at: SpriteSlot.Point(x: x, y: y)) }   // the i16 pair `+0xa`/`+0xc`
            w.active.update(id: id) { $0.counterA6 = -6 }
            return
        }
        // 5.
        var effect = effectFlag
        if let f = s.face {
            let b = faceBounds(f)
            if b.right <= s.clip.left || s.clip.right <= b.left { effect = false }
        }
        switch s.type {
        case 0:
            if sound { play(hitSound, at: s.centre) }
            if effect { _ = spawn(0, x - 8, y - 0xc, layer: 0xb) }
            killed()
        case PlayerShot.orb:
            w.active.update(id: id) { $0.stackX &-= 1 }
            if w.active.record(id: id)!.stackX < 1 {
                if sound { play(orbBreakSound, at: s.centre) }
                ExplodeFace.explode(w, face: s.face.flatMap(w.particleFaces.sprite), v: Int16(truncatingIfNeeded: y),
                                    h: Int16(truncatingIfNeeded: x), xStep: 2, yStep: 1, shape: 7, gravity: 0x50,
                                    style: 0x65)
                killed()
            } else if sound {
                play(orbHitSound, at: s.centre)
            }
        case PlayerShot.seed:
            play(seedSound, at: s.centre)
            w.flash.count = 3
            w.shakeStore = 0x14
            let big = spawn(EffectSprite.bigExplosion, x - 0x2a, y - 0x2a, layer: 0xc)
            if s.classWordF4 != 0, let big { w.active.update(id: big) { $0.mode = 0x10004 } }
            if s.seedHidden == 0 {
                var counter: Int16 = 0
                for i in 0..<4 {
                    for j in 0..<4 {
                        counter -= 1
                        let cx = Int16(truncatingIfNeeded: x + 8 * i - 4), cy = Int16(truncatingIfNeeded: y + 8 * j - 10)
                        guard counter < 1 else { continue }
                        counter = 2
                        let smoke = spawn(EffectSprite.smoke, Int(cx) - 0x18, Int(cy) - 0x18, layer: 0xc)
                        let m = Int32(w.rng.next(0x96)) + 400
                        let dir = BloodSpray.direction(target: (v: cy, h: cx),
                                                       from: (v: Int16(truncatingIfNeeded: s.centre.y),
                                                              h: Int16(truncatingIfNeeded: s.centre.x)))
                        if let smoke { w.active.update(id: smoke) { PlayerShot.addDirImpulse(&$0, dir: dir, magnitude: m) } }
                        let phase = w.rng.next(7)
                        if let smoke { w.active.update(id: smoke) { $0.phase = phase } }
                    }
                }
            }
            killed()
        default:
            let type: Int16 = s.type == 4 ? 2 : 5
            if sound { play(hitSound, at: s.centre) }
            let colour: Int16? = s.type == 3 ? 0x4d : s.type == 4 ? 0x42 : (1...2).contains(s.type) ? 0x21 : nil
            if effect {
                // r29 = the new effect (nil: no free record — the binary reads low memory, Ruling 16: dropped).
                let e = spawn(type, x - 5, y - 0xc, layer: 0xb)
                if let colour, let e, let light = w.active.record(id: e)?.light { lights.changeColor(light, colour) }
            } else if let colour, let staleSlot {
                lights.changeColor(staleSlot, colour)                       // the caller's r29 + 0x9a
            }
            killed()
        }
    }

    /// `.HitPlayerShotSprite(shot, other) @ 1005a7fc` (M l. 50947–51071; raw `1005a7fc..1005ac08`), in order:
    /// 1. other = the player (`PTR_PTR_100a052c`), id 5, age `+0x14c` > 10 → the Boomerang is caught: `+0xe9 = 1`, magic
    ///    `G+0xe` + 8 (no clamp), power > 1 → the four followers `+0xe9 = 1` — no `.KillPlayerShot` (no sound, no
    ///    effect); the routine goes on;
    /// 2. other an enemy shot (`PTR_PTR_100a0488`) of type 0x77b → `.STPlay3DSound(303, 1, 0xab, other +0xe)`,
    ///    `.KillPlayerShot(s, 0, 1)` (and on); then the orb 0x50 vs any enemy shot → `.STPlay3DSound(303, 1, 0x55, other
    ///    +0xe)`, `.KillPlayerShot(s, 1, 1)`, `.KillEnemyShot(other)` (`EnemyShot.kill`) and return (ES);
    /// 3. the orb vs the gate 0xb7c → nothing;
    /// 4. a Box (`PTR_PTR_100a0484`) of type 0x2c8 / 0x2c9 (a tree trunk): id 4 grows it (`trunkGrowth`), any other id
    ///    nothing;
    /// 5. the player or an Effect (`PTR_PTR_100a0460`) → nothing; a Bonus (`PTR_PTR_100a047c`) 0x517 / 0x51b with
    ///    `+0xb0 ≠ 0` and id ≠ 0x50 → `.KillPlayerShot(s, 1, 1)`; a Statue (`PTR_PTR_100a01f8`, SW — a platform the
    ///    Statue spell froze keeps its one-way top) or a Box: no one-way top (`+0x185`) and no surface function (`+0x1e8`;
    ///    only the rope bridge, // later: Phase 6) → the 2941 test (type 0xb7d, `+0x116 < 1`, the shot's `+0xa4 ==
    ///    300`, `cmpwi r0,0x12c` raw `1005ab7c` → HP − 0x50, `+0xaa = 10`, `+0x116 = 10`,
    ///    `.STPlay3DSoundPitched(419, 1, 0x100, shot +0xa, 35000)`) then `.KillPlayerShot(s, 1, 1)`; with one →
    ///    `.PlatformBounce(s, other, the hot-rect centre offset, 0, +0x34, 0)`, a contact (≠ 0) →
    ///    `.KillPlayerShot(s, 1, 1)`; the Crawler (`PTR_PTR_100a04b8`, CR) → `.KillPlayerShot(s, 0, 0)` (any `+0xa6`);
    ///    any other Handle nothing.
    /// Every Handle comparison is `+0x4c == Handle`, so an idled record (`+0x4c` 0, `handleCleared`) matches none
    /// (`BackgroundSprite.runs`); the orb-vs-0xb7c test reads the type only.
    /// No `+0xe9` test: `.MTCollideSprites` calls both sides of a contact, so a shot killed by the other side's Hit in
    /// the same dispatch still runs this one (the container then sees `+0xb0` already cleared).
    /// `.KillPlayerShot`'s stale r29 at every call here is the snd-303 slot (`kill`): no light changed [LOW].
    public static func hit(_ w: SpriteWorld, shot id: Int, other oID: Int, effects: Int16, lights: inout LightTable,
                           faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                           faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard let s = w.active.record(id: id), let o = w.active.record(id: oID) else { return }
        func killShot(_ sound: Bool, _ effect: Bool) {
            kill(w, shot: id, sound: sound, effect: effect, effects: effects, lights: &lights, faceWidth: faceWidth,
                 faceBounds: faceBounds)
        }
        // An idled record (`+0x4c` 0, `handleCleared`) matches none of the Handle comparisons below (`runs`); only the
        // type test of step 3 still reads it.
        let runs = BackgroundSprite.runs
        // 1. (M l. 50972: `+0x4c == PTR_PTR_100a052c`)
        if runs(o, .player) && s.type == 5 && 10 < s.shotAge {
            w.active.update(id: id) { $0.dead = true }
            w.globals.magic &+= 8
            if 1 < s.power {
                for f in PlayerShot.followers(s).compactMap({ $0 }) { w.active.update(id: f) { $0.dead = true } }
            }
        }
        // 2. the enemy shot 0x77b → snd 303 vol 0xab, `.KillPlayerShot(s, 0, 1)` (M l. 50991–50994); the orb vs any
        // enemy shot → snd 303 vol 0x55, `.KillPlayerShot(s, 1, 1)`, `.KillEnemyShot(other)`, return (M l. 50997–51001).
        func metal(_ volume: Int16) {
            let c = w.active.record(id: oID)?.centre ?? o.centre
            w.player.cue(PlayerCue(call: .threeD, snd: EnemyShot.metalSound, priority: 1, volume: volume, position: c))
        }
        if runs(o, .enemyShot) && o.type == EnemyShot.chiefBoulder {
            metal(0xab)
            killShot(false, true)
        }
        if let o = w.active.record(id: oID), runs(o, .enemyShot), s.type == PlayerShot.orb {
            metal(0x55)
            killShot(true, true)
            EnemyShot.kill(w, shot: oID, lights: &lights, effects: effects)
            return
        }
        // 3. (M l. 51004: a type test, no Handle)
        if s.type == PlayerShot.orb && o.type == 0xb7c { return }
        // 4. (M l. 51005: `+0x4c == PTR_PTR_100a0484`, the Box Handle)
        if runs(o, .box) && (o.type == 0x2c8 || o.type == 0x2c9) {
            if s.type == 4 { trunkGrowth(w, shot: id, trunk: oID, effects: effects, lights: &lights) }
            return
        }
        // 5. (M l. 51031–51066) the player / Effect Handles → nothing; then by Handle:
        if runs(o, .bonus) {
            if (o.type == 0x517 || o.type == 0x51b) && s.type != PlayerShot.orb && o.pickupDelay != 0 { killShot(true, true) }
        } else if runs(o, .statue) || runs(o, .box) {
            // The Statue Handle `PTR_PTR_100a01f8` or the Box's (M l. 51038; SW the Statue half).
            if !o.oneWay {                                                  // `+0x1e8` 0 for every Box built
                // The 2941 test, for a Box or a Statue (M l. 51040–51047).
                if o.type == 0xb7d && o.invulnerable < 1 && s.hp == 300 {
                    w.active.update(id: oID) { b in
                        b.hp &-= 0x50
                        b.flash = 10
                        b.invulnerable = 10
                    }
                    w.player.cue(PlayerCue(call: .threeDPitched, snd: iceWallSound, priority: 1, volume: 0x100,
                                           position: SpriteSlot.Point(x: PlayerShot.h16(s.x), y: PlayerShot.h16(s.y)),
                                           rate: 35000))
                }
                killShot(true, true)
            } else {
                let r = s.hotRect
                let h = PlayerShot.h16
                let centre = SpriteSlot.Point(x: h(r.left + h((r.right - r.left) >> 1)),
                                              y: h(r.top + h((r.bottom - r.top) >> 1)))
                if w.platformBounce(mover: id, solid: oID, centre: centre, factor: 0, rect: r, bounce: false) != 0 {
                    killShot(true, true)
                }
            }
        } else if runs(o, .crawler) {
            // The Crawler Handle `PTR_PTR_100a04b8` → `.KillPlayerShot(s, 0, 0)` (M l. 51062–51064; CR).
            killShot(false, false)
        }
        // Any other Handle (or none): nothing.
    }

    /// The Tree Trunk's growth (`.HitPlayerShotSprite` M l. 51007–51030; raw `1005a984..1005aa58`; spells-detail §3.5):
    /// the trunk is walked up its `+0x1d4` links to the top segment; `MTNewSprite(0x2c9, top +0xc, top +0xa − 0x10, 2,
    /// −1, .SetupBoxSprite)` (`BoxSprite.newTrunk`; the 0x2c9 arm draws nothing, M l. 58967–58972) linked as `top
    /// +0x1d4` with `+0xa6 = *_DAT_1009fd30 + 0x78` (SW); the old top's `+0xa6` raised to ≥ 0x23;
    /// `MTNewSprite(2, segment +0xc − 6, segment +0xa − 9, 0xb, −1, .SetupEffectSprite)` (its package draws), `+0x46 =
    /// 8`, `.ChangeLightColor(+0x9a, 0x42)`; the shot `+0xe9 = 1` directly (the followers fly on); `.STPlay3DSound(302,
    /// 1, 0x100, effect +0xe)` — the effect's centre word, still 0 (no Handle has run). With no free record for the
    /// segment (Ruling 16) the link stores nil and the effect goes where the segment would have stood.
    static func trunkGrowth(_ w: SpriteWorld, shot id: Int, trunk: Int, effects: Int16, lights: inout LightTable) {
        var top = trunk
        while let next = w.active.record(id: top)?.siblings.first { top = next }
        guard let t = w.active.record(id: top) else { return }
        var sx = PlayerShot.h16(t.x), sy = PlayerShot.h16(t.y - 0x10)          // the new segment's `+0xc` / `+0xa`
        let seg = BoxSprite.newTrunk(w, type: BoxSprite.trunkSegment, x: sx, y: sy)
        w.active.update(id: top) { $0.siblings.first = seg }
        if let seg {
            w.active.update(id: seg) { $0.counterA6 = (w.parity ? 1 : 0) + 0x78 }
            if let k = w.active.record(id: seg) {
                sx = PlayerShot.h16(k.x)
                sy = PlayerShot.h16(k.y)
            }
        }
        w.active.update(id: top) { if $0.counterA6 < 0x23 { $0.counterA6 = 0x23 } }
        let e = EffectSprite.spawn(w, type: 2, x: sx - 6, y: sy - 9, layer: 0xb, effects: effects, lights: &lights)
        if let e {
            w.active.update(id: e) { $0.phase = 8 }
            if let light = w.active.record(id: e)?.light { lights.changeColor(light, 0x42) }
        }
        w.active.update(id: id) { $0.dead = true }
        w.player.cue(PlayerCue(call: .threeD, snd: trunkSound, priority: 1, volume: 0x100,
                               position: e.flatMap { w.active.record(id: $0)?.centre } ?? SpriteSlot.Point()))
    }
}
