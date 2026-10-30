import Foundation

/// The Crawler (type 1712) and the Roach (type 1720) (CR; enemies-ground §4, §5; enemies-ground-2 §2): `.InitCrawlerSprite
/// @ 10065828` (M l. 56123–56151, the faces), `.SetupCrawlerSprite @ 100659a0` (M l. 56153–56246, `setupCrawler`),
/// `.HandleCrawlerSprite @ 10065c00` (M l. 56247–56519, `handleCrawler`), `.HitCrawlerSprite @ 100665bc` (M l.
/// 56556–56682, `hitCrawler`), `.KillCrawler @ 10066a2c` (M l. 56683–56704), `.HitCrawlerTileSprite @ 10066aa4` (M l.
/// 56706–56745, `hitTile`); `.InitRoachSprite @ 10077868` (M l. 64886–64897), `.SetupRoachSprite @ 10077914` (M l.
/// 64899–64957, `setupRoach`), `.HandleRoachSprite @ 10077a88` (M l. 64959–65116, `handleRoach`), `.HitRoachSprite @
/// 1007801c` (M l. 65118–65199, `hitRoach`), `.KillRoach @ 100782f8` (M l. 65201–65222), `.HitRoachTileSprite @
/// 10078384` (M l. 65224–65262, the same body as the Crawler's — `hitTile`).
///
/// Neither Setup stores a Kill proc `+0x50`: the Handles call `.KillCrawler` / `.KillRoach` themselves. Neither class
/// stores `+0x188`…`+0x18b`; both Kills store `+0xea = 1`; the falling Crawler writes record p1 := 1 (a reload makes it
/// a floor crawler).
///
/// Fields (`SpriteSlot`): `+0xb0` the state `subtype` (Crawler 0 ceiling, 1 falling, 2 floor, 3 flee, 4 dying; Roach 2
/// patrol, 3 the unreachable hop-flee, 4 dying); `+0xb2` the Crawler's wind-up `subState`; `+0x46` the face counter
/// `phase`; `+0xa6` the cooldown `counterA6` (the Crawler's live; the Roach's write-only, enemies-ground-2 §2);
/// `+0x14c` the stored flee / leap vx `classTimer`; `+0x150` the death counter `classWord150`; `+0x154` the Crawler's
/// max HP / the Roach's home x `classWord154`; `+0x158` the Crawler's speed cap `classWord158`; `+0x15c` its flee HP
/// `classWord15c`.
public enum CrawlerRoach {
    /// The types (`+4`).
    public static let crawler: Int16 = 0x6b0, roach: Int16 = 0x6b8

    /// The faces (`.InitCrawlerSprite` M l. 56136–56144): `PTR_DAT_100a09b0[0…3]` = the singles 0x5dc…0x5df (absent
    /// from every shipped file: nil, `BootFaces`), `*_DAT_100a09ac` = the ceiling single 0x6b0 (boot), and the cache
    /// sets `_DAT_100a09a8` 0x6ae walk, `_DAT_100a09a4` 0x6af jump, `_DAT_100a09a0` 0x6b1 death (6 × 0x40×0x2c each).
    /// `.InitRoachSprite` (M l. 64893–64894): the cache sets `_DAT_100a0b7c` 0x6b8 walk and `_DAT_100a0b78` 0x6b9 death
    /// (6 × 100×0x36). The Setups mark the cache sets (M l. 56188–56190, 64931–64932; `CachedFaces`).
    public static let ceilingFace: Int16 = 0x6b0, walkSet: Int16 = 0x6ae, jumpSet: Int16 = 0x6af,
                      deathSet: Int16 = 0x6b1, roachWalk: Int16 = 0x6b8, roachDeath: Int16 = 0x6b9

    /// The snd slots (`SoundSlots`): `*_DAT_100a0278` 700 'Crawler jump', `*_DAT_100a0274` 701 'Crawler Ouch',
    /// `*_DAT_100a0270` 702 'Crawler uh oh', `*_DAT_100a026c` 703 'crawler death'.
    static let jumpSound: Int16 = 700, ouchSound: Int16 = 701, uhOhSound: Int16 = 702, deathSound: Int16 = 703

    /// 0.65 (f64 `0x100a1a90`): the Crawler's knockback factor; 0.97 (`0x100a1aa0`): its dying friction.
    static let knock65 = Double(bitPattern: 0x3fe4_cccc_cccc_cccd)
    static let friction97 = Double(bitPattern: 0x3fef_0a3d_70a3_d70a)

    @inline(__always) static func h16(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }
    @inline(__always) static func face(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }
    @inline(__always) static func abs32(_ v: Int) -> Int { v < 1 ? -v : v }

    // MARK: - Setup

    /// `.SetupCrawlerSprite(s)` (M l. 56153–56246) after `.InitSprite`, in order: `+0x84`/`+0x86` 0; layer 0xb; the
    /// Crawler Handle, hit and tile callbacks (no Kill proc); `+0xa6 = 3`; `+0xb2 = −1`; record p1 0 → state 0, gravity
    /// −0x151 (the ceiling), ≠ 0 → state 2, gravity 0x151 (the caller's face: the absent 0x5dc / 0x5dd — nil);
    /// `+0x15c = 300`; the tier by record p2 (`tier`); `+0xc ← +8`, `+0xa ← +6`; rect (0x14, 0xc, 0x2c, 0x21); `+0x150
    /// = −1`; the counting window; the 24.8 position from `+8`/`+6`. No draw, no idle margins, no save flag.
    public static func setupCrawler(_ s: inout SpriteSlot, record p: Placement, counting: inout EnemyCounting) {
        s.particleOffsetY = 0
        s.particleOffsetX = 0
        s.layer = 0xb
        s.handler = .crawler
        s.hasHit = true                                                 // `+0x5c` = `.HitCrawlerSprite`
        s.hasTileHit = true                                             // `+0x1f8` = `.HitCrawlerTileSprite`
        s.counterA6 = 3
        s.subState = -1
        if p.p1 == 0 {
            s.subtype = 0
            s.gravity = -0x151
        } else {
            s.subtype = 2
            s.gravity = 0x151
        }
        s.classWord15c = 300
        if let k = tier(p2: p.p2) {
            s.mode = k.mode                                             // tier 0 stores none (`.InitSprite`: 0)
            s.hp = k.hp
            s.classWord154 = Int32(k.hp)
            s.classWord158 = k.cap
            if let f = k.flee { s.classWord15c = f }
        }
        s.oldPosition = SpriteSlot.Point(x: s.x, y: s.y)                // `+8` / `+6` = the spawn position
        s.hotRect = IdleSprites.Rect(top: 0xc, left: 0x14, bottom: 0x21, right: 0x2c)
        s.classWord150 = -1
        counting.countIfWindow(&s)                                      // M l. 56236–56240
        s.x256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.y)) << 8
    }

    /// The Crawler tiers by record p2 (M l. 56204–56231; enemies-ground §4): (`+0xb8`, HP = max `+0x154`, the speed cap
    /// `+0x158`, the flee HP `+0x15c` when stored). 0: (—, 500, 0x4b0); 1: (0x10002, 300, 0x352, 100); 2: (0x10003,
    /// 1000, 0x60e); 3: (0x1000f, 0x640, 2000, 200); any other p2: nil (nothing stored — HP 0, dies at once).
    public static func tier(p2: Int16) -> (mode: UInt32, hp: Int16, cap: Int32, flee: Int32?)? {
        switch p2 {
        case 0: return (0, 500, 0x4b0, nil)
        case 1: return (0x10002, 300, 0x352, 100)
        case 2: return (0x10003, 1000, 0x60e, nil)
        case 3: return (0x1000f, 0x640, 2000, 200)
        default: return nil
        }
    }

    /// `.SetupRoachSprite(s)` (M l. 64899–64957) after `.InitSprite`, in order: `+0x84`/`+0x86` 0; layer 0xb; the
    /// Roach Handle, hit and tile callbacks (no Kill proc); `+0xa6 = 3`; state 2; gravity 0x151; `+0xc0` = the cache
    /// 0x6b8's face 0 (the caller's); HP 200; `+0xc ← +8`, `+0xa ← +6`; rect (0x23, 0x1b, 0x44, 0x2d); `+0x150 = −1`;
    /// the live record's p3 0 → 0xaa written back; `+0x154` = `+8` (the spawn x); vx 0x4b0 (M l. 64945–64946); the
    /// counting window; the 24.8 position. No draw, no idle margins, no save flag. Returns the record as left.
    public static func setupRoach(_ s: inout SpriteSlot, record p: Placement, counting: inout EnemyCounting) -> Placement {
        s.particleOffsetY = 0
        s.particleOffsetX = 0
        s.layer = 0xb
        s.handler = .roach
        s.hasHit = true                                                 // `+0x5c` = `.HitRoachSprite`
        s.hasTileHit = true                                             // `+0x1f8` = `.HitRoachTileSprite`
        s.counterA6 = 3
        s.subtype = 2
        s.gravity = 0x151
        s.hp = 200
        s.oldPosition = SpriteSlot.Point(x: s.x, y: s.y)
        s.hotRect = IdleSprites.Rect(top: 0x1b, left: 0x23, bottom: 0x2d, right: 0x44)
        s.classWord150 = -1
        var record = p
        if p.p3 == 0 {                                                  // M l. 64940–64944
            record = Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: p.p1, p2: p.p2,
                               p3: 0xaa, p4: p.p4, y: p.y, x: p.x)
        }
        s.classWord154 = Int32(Int16(truncatingIfNeeded: s.oldPosition.x))
        s.vx = 0x4b0
        counting.countIfWindow(&s)                                      // M l. 64947–64951
        s.x256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.y)) << 8
        return record
    }

    // MARK: - Handles

    /// The tile callback both classes' `+0x1f8` names (nil = 0).
    public static func pass(_ s: SpriteSlot) -> TileHit? {
        guard s.hasTileHit else { return nil }
        return { solver, id, cell, kind, layer in hitTile(solver, id: id, pos: cell, kind: kind, layer: layer) }
    }

    /// `.HandleCrawlerSprite(s)` (M l. 56247–56519), unless `+0xe9` or `+0x1b2`. P = `*_DAT_1009fd94` / `fd90` (the
    /// player's centre), c = the hot-rect centre `+0x10` / `+0xe`:
    /// 1. `.StandardSpriteHandles`; layer 0xb; the face — not falling: winding up (state 2, `+0xb2 > 0`) → 0x6af[min(6 −
    ///    `+0xb2`, 4)]; else, unless the face is 0x6af[5] while airborne, `+0x46` + 1 (wrapped past 11) and 0x6ae[`+0x46
    ///    >> 1`];
    /// 2. by state — 2 (floor): gravity 0x151; `+0xb2 > 0` → − 1; at 0 the leap (snd 700, `.SetSpriteSpeed(0, −2000 −
    ///    R(1000))`, `.AccelerateBasedOnSlope(−R(500) − cap, 2·cap)`, `+0xa6 = 10 + R(10)`, `+0x14c` = vx, negated with
    ///    vx when c.x < P.x, `+0xb2 = −1`); on ground: P beyond c.x ± 60 → accelerate ±250 (cap `+0x158`); `+0xa6 > 0` →
    ///    − 1; `+0xa6 == 0` and `+0xb2 == −1` with |c.x − P.x| < 70 and |c.y − P.y| < 100 → `+0xb2 = 5`; HP ≤ `+0x15c`
    ///    with `+0xb2 == −1` → state 3. 3 (flee): gravity 0x151; `+0xa6 == 0` on ground → the hop (`.SetSpriteSpeed(0,
    ///    −900 − R(400))`, `.AccelerateBasedOnSlope(−0x6a4 − R(800), 2000)`, `+0x14c` = vx, negated with vx when P.x <
    ///    c.x, `+0xa6 = 20 + R(30)`); airborne → vx = `+0x14c`; on ground → vx halved while moving toward P (vx < 0 with
    ///    P right, vx > 300 with P left), else `+0xa6` − 1 (no floor); HP < 300 → state 3. 4: gravity 0x151. 1 (falling):
    ///    record p1 := 1, gravity 0x151, on ground → state 2. 0 (ceiling): gravity −0x151; |c.x − P.x| < 140 with P
    ///    below by ≤ 219, or HP ≤ `+0x154` − 100 → state 1; vx halved;
    /// 3. HP < 1 → state 4; state 0 → `+0x46` + 1 (wrapped past 1), face 0x6b0; state 4 → `dying`;
    /// 4. the facing: c.x < P.x → flip 1, P.x < c.x → flip 0;
    /// 5. winding up (state 2, `+0xb2 ≥ 0`): vx kept aside (as an i16) and 0 through `.ApplyGravityAndSeparateFromTiles`
    ///    and the liquids (`EnemyCommon.liquids`, the Crawler row), then restored; `.StandardSpriteCleanup`.
    /// - Parameters: `lights` / `effects` reach the coins' Setups; `faceWidth` the Cleanup's face `+6`.
    public static func handleCrawler(world w: SpriteWorld, id: Int, solver: TileSolver, lights: inout LightTable,
                                     effects: Int16, faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right }) {
        guard let s0 = w.active.record(id: id), !s0.dead, !s0.handleSkip else { return }
        w.standardSpriteHandles(id)
        guard var s = w.active.record(id: id) else { return }
        let px = Int(w.player.centreX), py = Int(w.player.centreY)
        s.layer = 0xb
        if s.subtype != 1 {
            if s.subtype == 2 && 0 < s.subState {
                var i = 6 - Int(s.subState)
                if 3 < i { i = 4 }
                s.face = face(jumpSet, i)
            } else if s.face != face(jumpSet, 5) || s.groundKind != 0 {
                s.phase &+= 1
                if 0xb < s.phase { s.phase = 0 }
                s.face = face(walkSet, Int(s.phase >> 1))
            }
        }
        let cx = h16(s.centre.x), cy = h16(s.centre.y)
        let state = s.subtype
        if state == 2 {
            s.gravity = 0x151
            if 0 < s.subState { s.subState &-= 1 }
            if s.subState == 0 {
                w.player.cue(PlayerCue(call: .threeD, snd: jumpSound, priority: 1, volume: 0x100, position: s.centre))
                let r = Int(w.rng.next(1000))
                Walker.setSpriteSpeed(&s, 0, Int16(truncatingIfNeeded: -2000 - r))
                let r2 = Int(w.rng.next(500))
                s.accelerateBasedOnSlope(Int16(truncatingIfNeeded: -r2 - Int(s.classWord158)), cap: s.classWord158 << 1)
                s.counterA6 = w.rng.next(10) &+ 10
                s.classTimer = s.vx
                if cx < px {
                    s.vx = 0 &- s.vx
                    s.classTimer = s.vx
                }
                s.subState = -1
            }
            if s.groundKind != 0 {
                if cx + 0x3c < px {
                    s.accelerateBasedOnSlope(0xfa, cap: s.classWord158)
                } else if px < cx - 0x3c {
                    s.accelerateBasedOnSlope(-0xfa, cap: s.classWord158)
                }
                if 0 < s.counterA6 { s.counterA6 &-= 1 }
                if s.counterA6 == 0 && s.subState == -1 && abs32(cx - px) < 0x46 && abs32(cy - py) < 100 {
                    s.subState = 5
                }
                if Int32(s.hp) <= s.classWord15c && s.subState == -1 { s.subtype = 3 }
            }
        } else if 1 < state {
            if state == 4 {
                s.gravity = 0x151
            } else if state < 4 {
                flee(w, &s, px: px, cx: cx)
                if s.groundKind != 0 && s.hp < 300 { s.subtype = 3 }
            }
        } else if state != 0 {
            if -1 < state {                                             // state 1 (falling)
                let i = Int(s.recordIndex)                              // record p1 := 1 (M l. 56398)
                if w.records.indices.contains(i) {
                    let q = w.records[i]
                    w.records[i] = Placement(index: q.index, flag: q.flag, byte1: q.byte1, type: q.type, p1: 1,
                                             p2: q.p2, p3: q.p3, p4: q.p4, y: q.y, x: q.x)
                }
                s.gravity = 0x151
                if s.groundKind != 0 { s.subtype = 2 }
            }
        } else {                                                        // state 0 (the ceiling)
            s.gravity = -0x151
            var drop = false
            if abs32(cx - px) < 0x8c {
                let dy = cy - py
                if !(0xdb < abs32(dy) || -1 < dy) { drop = true }
            }
            if !drop && Int32(s.hp) <= s.classWord154 &- 100 { drop = true }
            if drop { s.subtype = 1 }
            if 0 < (s.vx < 1 ? 0 &- s.vx : s.vx) { s.vx /= 2 }          // `srawi 1; addze`: toward zero
        }
        if s.hp < 1 { s.subtype = 4 }
        if s.subtype == 0 {
            s.phase &+= 1
            if 1 < s.phase { s.phase = 0 }
            s.face = face(ceilingFace, 0)
        } else if s.subtype == 4 {
            w.active.update(id: id) { $0 = s }
            dying(w, id: id, lights: &lights, effects: effects, death: deathSet, friction: true)
            guard let t = w.active.record(id: id) else { return }
            s = t
        }
        if cx < px {
            s.mirrored = true
        } else if px < cx {
            s.mirrored = false
        }
        let windUp = s.subtype == 2 && -1 < s.subState
        var kept: Int16 = 0
        if windUp {
            kept = Int16(truncatingIfNeeded: s.vx)
            s.vx = 0
        }
        w.active.update(id: id) { $0 = s }
        if let t = w.active.record(id: id) { solver.applyGravityAndSeparate(id, pass: pass(t)) }
        EnemyCommon.liquids(w, id: id, class: .crawler)
        if let t = w.active.record(id: id), t.subtype == 2 && -1 < t.subState {
            w.active.update(id: id) { $0.vx = Int32(kept) }
        }
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
    }

    /// The hop-flee arm (state 3) both Handles share (Crawler M l. 56351–56389, Roach 64986–65023): gravity 0x151;
    /// `+0xa6 == 0` on ground → the hop; airborne → vx = `+0x14c`; on ground → vx halved toward zero while moving
    /// toward P, else `+0xa6` − 1. The caller's HP test (Crawler < 300, Roach < 3) follows on ground.
    static func flee(_ w: SpriteWorld, _ s: inout SpriteSlot, px: Int, cx: Int) {
        s.gravity = 0x151
        if s.counterA6 == 0 && s.groundKind != 0 {
            let r = Int(w.rng.next(400))
            Walker.setSpriteSpeed(&s, 0, Int16(truncatingIfNeeded: -900 - r))
            let r2 = Int(w.rng.next(800))
            s.accelerateBasedOnSlope(Int16(truncatingIfNeeded: -0x6a4 - r2), cap: 2000)
            s.classTimer = s.vx
            if px < cx {
                s.vx = 0 &- s.vx
                s.classTimer = s.vx
            }
            s.counterA6 = w.rng.next(0x1e) &+ 0x14
        }
        if s.groundKind == 0 {
            s.vx = s.classTimer
        } else if cx < px && s.vx < 0 {
            s.vx /= 2
        } else if px < cx && 300 < s.vx {
            s.vx /= 2
        } else {
            s.counterA6 &-= 1
        }
    }

    /// The dying state 4 both Handles share (Crawler M l. 56443–56482, Roach 65060–65100): `FastRand(3)` drawn every
    /// frame; `+0x5c = 0`; `+0x150` −1 → 1; then while `+0x150 > 0`: + 1, face death[min((`+0x150` − 2) >> 1, 5)], the
    /// Crawler's vx × 0.97; past 21: snd 703, face 0, the class Kill, score + 500, 2 + R(3) coins 0x516
    /// (`MTNewSprite(0x516, c.x − 4, c.y − 4, 2, −1, .SetupBonusSprite)`, vy −1400 − R(1600), vx R(1000) − 500; no free
    /// record: the stores dropped, the draws made), 100 particles `NewParticle(2, 0x50, (c.y + 6, c.x − 1), 4, R(600) −
    /// 300, −350 − R(700), 0, 1)` (R(700) drawn first).
    static func dying(_ w: SpriteWorld, id: Int, lights: inout LightTable, effects: Int16, death: Int16,
                      friction: Bool) {
        guard var s = w.active.record(id: id) else { return }
        let n = w.rng.next(3)
        s.hasHit = false
        if s.classWord150 == -1 { s.classWord150 = 1 }
        guard 0 < s.classWord150 else {
            w.active.update(id: id) { $0 = s }
            return
        }
        s.classWord150 &+= 1
        var f = Int16(truncatingIfNeeded: (s.classWord150 &- 2) >> 1)
        if 5 < f { f = 5 }
        s.face = face(death, Int(f))
        if friction { s.vx = TileSolver.fctiwz(Double(s.vx) * friction97) }
        guard 0x15 < s.classWord150 else {
            w.active.update(id: id) { $0 = s }
            return
        }
        w.player.cue(PlayerCue(call: .threeD, snd: deathSound, priority: 1, volume: 0x100, position: s.centre))
        s.face = nil
        if s.handler == .roach { killRoach(w, &s) } else { killCrawler(w, &s) }
        w.globals.score &+= 500
        w.active.update(id: id) { $0 = s }
        let cx = h16(s.centre.x), cy = h16(s.centre.y)
        let pl = w.playerID.flatMap { w.active.record(id: $0) }?.layer ?? 0
        for _ in 0..<Int(n &+ 2) {
            let x = h16(cx - 4), y = h16(cy - 4)
            let c = w.newSprite(type: 0x516, x: x, y: y, layer: 2, handler: .bonus) { c in
                // Cannot throw: `BonusSprite.setup` throws only for 0xc25 and items past 0xc9a.
                _ = try! BonusSprite.setup(&c, x: x, y: y, level: w.level, records: w.records, effects: effects,
                                           lightCount: lights.count, counting: false, playerLayer: pl,
                                           rng: &w.rng) { lf, lh, lv, col in
                    lights.add(face: lf, x: Int16(truncatingIfNeeded: lh), y: Int16(truncatingIfNeeded: lv), vx: 0,
                               vy: 0, accelY: 0, colour: col)
                }
            }
            let vy = -0x578 - Int32(w.rng.next(0x640))
            let vx = Int32(w.rng.next(1000)) - 500
            if let c {
                w.active.update(id: c) { t in
                    t.vy = vy
                    t.vx = vx
                }
            }
        }
        for _ in 0..<100 {
            let a = Int(w.rng.next(700))
            let b = Int(w.rng.next(600))
            w.particles.newParticle(kind: 2, gravity: 0x50, v: h16(cy + 6), h: h16(cx - 1), shape: 4, vx: b - 300,
                                    vy: -0x15e - a, delay: 0, mode: 1)
        }
    }

    /// `.KillCrawler(s)` (M l. 56683–56704): the counting Kill (`EnemyCounting.kill`), `+0xe9 = 1`, `+0xea = 1`.
    static func killCrawler(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        w.enemies.kill(&s, globals: &w.globals, level: w.levelIndex, forGood: true)
    }

    /// `.KillRoach(s)` (M l. 65201–65222): the counting Kill; `+0xe9 == 0` → score + 100; `+0xe9 = 1`, `+0xea = 1`.
    static func killRoach(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        let first = s.killCount == 0
        w.enemies.kill(&s, globals: &w.globals, level: w.levelIndex, forGood: true)
        if first { w.globals.score &+= 100 }
    }

    /// `.HandleRoachSprite(s)` (M l. 64959–65116), unless `+0xe9` or `+0x1b2`: `.StandardSpriteHandles`; layer 0xb; not
    /// state 1 → `+0x46` + 1 (wrapped past 11), face 0x6b8[`+0x46 >> 1`]; by state — 3 (the hop-flee, `flee`; HP < 3 →
    /// state 3 — reachable only from itself, enemies-ground §5); 2: gravity 0x151 and on ground the patrol: w = record p3
    /// / 2 (toward zero); c.x < home `+0x154` − w → accelerate +100 (cap 0x4b0), flip 1; c.x > home + w → −100, flip 0;
    /// inside: flip 0 with vx > −0x4b0 → −100, flip 1 with vx > 0x4b0 → +100; `+0xa6 > 0` → − 1 (no reader); 4: gravity
    /// 0x151. HP < 1 → state 4; state 4 → `dying` (no friction); `.ApplyGravityAndSeparateFromTiles`; the liquids (the
    /// Roach row: every kind hurts); `.StandardSpriteCleanup`.
    public static func handleRoach(world w: SpriteWorld, id: Int, solver: TileSolver, lights: inout LightTable,
                                   effects: Int16, faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right }) {
        guard let s0 = w.active.record(id: id), !s0.dead, !s0.handleSkip else { return }
        w.standardSpriteHandles(id)
        guard var s = w.active.record(id: id) else { return }
        let px = Int(w.player.centreX)
        s.layer = 0xb
        if s.subtype != 1 {
            s.phase &+= 1
            if 0xb < s.phase { s.phase = 0 }
            s.face = face(roachWalk, Int(s.phase >> 1))
        }
        let cx = h16(s.centre.x)
        let state = s.subtype
        if state == 3 {
            flee(w, &s, px: px, cx: cx)
            if s.groundKind != 0 && s.hp < 3 { s.subtype = 3 }
        } else if state < 3 {
            if 1 < state {
                s.gravity = 0x151
                if s.groundKind != 0 {
                    let i = Int(s.recordIndex)
                    let p3 = Int(w.records.indices.contains(i) ? w.records[i].p3 : 0)
                    let half = p3 / 2
                    var moved = false
                    if cx < Int(s.classWord154) - half {
                        s.accelerateBasedOnSlope(100, cap: 0x4b0)
                        s.mirrored = true
                        moved = true
                    } else if Int(s.classWord154) + half < cx {
                        s.accelerateBasedOnSlope(-100, cap: 0x4b0)
                        s.mirrored = false
                        moved = true
                    }
                    if !moved {
                        if !s.mirrored && -0x4b0 < s.vx {
                            s.accelerateBasedOnSlope(-100, cap: 0x4b0)
                        } else if s.mirrored && 0x4b0 < s.vx {
                            s.accelerateBasedOnSlope(100, cap: 0x4b0)
                        }
                    }
                    if 0 < s.counterA6 { s.counterA6 &-= 1 }
                }
            }
        } else if state < 5 {
            s.gravity = 0x151
        }
        if s.hp < 1 { s.subtype = 4 }
        w.active.update(id: id) { $0 = s }
        if s.subtype == 4 { dying(w, id: id, lights: &lights, effects: effects, death: roachDeath, friction: false) }
        if let t = w.active.record(id: id) { solver.applyGravityAndSeparate(id, pass: pass(t)) }
        EnemyCommon.liquids(w, id: id, class: .roach)
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
    }

    // MARK: - hits

    /// `.HitCrawlerSprite(s, other)` (M l. 56556–56682). Every Handle comparison is `+0x4c ==` (`BackgroundSprite.runs`):
    /// - a player shot with `+0xa6 == 0`: `.KillPlayerShot(o, 0, 0)` first (its stale r29 is the shot, `or r29,r4,r4`
    ///   raw `100665d4`: its own `+0x9a`), then a shot of type 1 → `.TurnIntoStatue(s)`; else `.HurtSprite(s, o.+0xa4,
    ///   (int)(0.65 · o.vx), −1000, 4, 10)` → `hurtTail` (the "vx = 0.9 · o.vx" block compares |vx| with itself and never
    ///   runs, raw `1006668c–100666c0`);
    /// - a Statue or Box: `.PlatformBounce(s, o, the hot-rect centre, 0, +0x34, 0)` == 2 and the solid falls or we stand
    ///   (`EnemyCommon.crushesSmall`) → HP 0, `+0x150 = 0x16`;
    /// - an Effect 0x4b7 at `+0x46 < 8` (the Ring of Smiting's explosion) or a 0x5a0 with `+0x14c == 1 || +0x150 == 2`
    ///   (as read) → `.HurtSprite(s, 100, (int)(0.65 · o.vx), −1000, 4, 10)` → `hurtTail`.
    public static func hitCrawler(_ w: SpriteWorld, id: Int, other oID: Int, lights: inout LightTable,
                                  effects: Int16 = 1, faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                                  faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard w.active.record(id: id) != nil, let o = w.active.record(id: oID) else { return }
        let runs = BackgroundSprite.runs
        func knock(_ vx: Int32) -> Int16 { Int16(truncatingIfNeeded: TileSolver.fctiwz(knock65 * Double(vx))) }
        if runs(o, .playerShot) && o.counterA6 == 0 {
            PlayerShotHits.kill(w, shot: oID, sound: false, effect: false, effects: effects, lights: &lights,
                                faceWidth: faceWidth, faceBounds: faceBounds, staleSlot: o.light)
            guard let shot = w.active.record(id: oID) else { return }
            if shot.type == 1 {
                EnemyCommon.turnIntoStatue(w, id: id)
            } else if HurtSprite.apply(w, id: id, damage: shot.hp, dvx: knock(shot.vx), dvy: -1000, invulnerable: 4,
                                       flash: 10) {
                hurtTail(w, id: id, other: oID, uhOhBelow: 0xc9)
            }
        } else if runs(o, .statue) || runs(o, .box) {
            crush(w, id: id, other: oID)
        } else if EnemyCommon.environmentalHazard(o, crawlerFields: true) {
            if HurtSprite.apply(w, id: id, damage: 100, dvx: knock(o.vx), dvy: -1000, invulnerable: 4, flash: 10) {
                hurtTail(w, id: id, other: oID, uhOhBelow: 0xc9)
            }
        }
    }

    /// `.HitRoachSprite(s, other)` (M l. 65118–65199): as the Crawler's, with the knockback `(i16)(o.vx >> 1)`, flash 8,
    /// the geyser test `+0x14c` 1 or 2 (`EnemyCommon.environmentalHazard`) and snd 702 below HP 3.
    public static func hitRoach(_ w: SpriteWorld, id: Int, other oID: Int, lights: inout LightTable,
                                effects: Int16 = 1, faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                                faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard w.active.record(id: id) != nil, let o = w.active.record(id: oID) else { return }
        let runs = BackgroundSprite.runs
        func knock(_ vx: Int32) -> Int16 { Int16(truncatingIfNeeded: vx >> 1) }
        if runs(o, .playerShot) && o.counterA6 == 0 {
            PlayerShotHits.kill(w, shot: oID, sound: false, effect: false, effects: effects, lights: &lights,
                                faceWidth: faceWidth, faceBounds: faceBounds, staleSlot: o.light)
            guard let shot = w.active.record(id: oID) else { return }
            if shot.type == 1 {
                EnemyCommon.turnIntoStatue(w, id: id)
            } else if HurtSprite.apply(w, id: id, damage: shot.hp, dvx: knock(shot.vx), dvy: -1000, invulnerable: 4,
                                       flash: 8) {
                hurtTail(w, id: id, other: oID, uhOhBelow: 3)
            }
        } else if runs(o, .statue) || runs(o, .box) {
            crush(w, id: id, other: oID)
        } else if EnemyCommon.environmentalHazard(o) {
            if HurtSprite.apply(w, id: id, damage: 100, dvx: knock(o.vx), dvy: -1000, invulnerable: 4, flash: 8) {
                hurtTail(w, id: id, other: oID, uhOhBelow: 3)
            }
        }
    }

    /// After a hurt: `.BloodSpray(s, o, 0x28, 400, 0x96, 2)`; HP below `uhOhBelow` (Crawler 0xc9, Roach 3) → snd 702,
    /// else HP > 0 → snd 701 (vol 0x100, no draw).
    static func hurtTail(_ w: SpriteWorld, id: Int, other oID: Int, uhOhBelow: Int16) {
        BloodSpray.spray(w, victim: id, attacker: oID, count: 0x28, speed: 400, spread: 0x96, kind: 2)
        guard let t = w.active.record(id: id) else { return }
        if t.hp < uhOhBelow {
            w.player.cue(PlayerCue(call: .threeD, snd: uhOhSound, priority: 1, volume: 0x100, position: t.centre))
        } else if 0 < t.hp {
            w.player.cue(PlayerCue(call: .threeD, snd: ouchSound, priority: 1, volume: 0x100, position: t.centre))
        }
    }

    /// The crush (Crawler M l. 56620–56634, Roach 65136–65151): `.PlatformBounce` with the hot-rect centre; 2 with the
    /// solid falling or the enemy on ground → HP 0, `+0x150 = 0x16` (the next Handle dies at once).
    static func crush(_ w: SpriteWorld, id: Int, other oID: Int) {
        guard let s = w.active.record(id: id) else { return }
        let r = s.hotRect
        let centre = SpriteSlot.Point(x: h16(r.left + h16((r.right - r.left) >> 1)),
                                      y: h16(r.top + h16((r.bottom - r.top) >> 1)))
        let b = w.platformBounce(mover: id, solid: oID, centre: centre, factor: 0, rect: r, bounce: false)
        guard let m = w.active.record(id: id), let o = w.active.record(id: oID),
              EnemyCommon.crushesSmall(bounce: b, solid: o, mover: m) else { return }
        w.active.update(id: id) { t in
            t.hp = 0
            t.classWord150 = 0x16
        }
    }

    /// `.HitCrawlerTileSprite` / `.HitRoachTileSprite(s, pos, kind, layer)` (M l. 56706–56745, 65224–65262; the debug
    /// no-clip key not built): FG (layer 1) or BG kinds < 100 → `.WallBounce(s, kind, &pos, vCentre, 0, +0x34, 0, 0)`;
    /// BG < 200 → `.WallBounceBG(kind − 100, …)`; water → `.HandleUnderWater` unless `+0x140`.
    public static func hitTile(_ solver: TileSolver, id: Int, pos posIn: TilePos, kind: Int, layer: TileLayer) {
        let w = solver.world
        guard let s = w.active.record(id: id) else { return }
        var pos = posIn
        let r = s.hotRect
        let vCentre = h16(r.top + h16((r.bottom - r.top) >> 1))
        let k = Int16(truncatingIfNeeded: kind)
        if layer == .foreground || k < 100 {
            solver.wallBounce(id, kind: kind, tile: &pos, vCentre: vCentre, factor: 0, rect: r, bounce: false)
        } else if k < 200 {
            solver.wallBounceBG(id, kind: kind - 100, tile: &pos, vCentre: vCentre, factor: 0, rect: r, bounce: false)
        } else if UnderWater.isWaterTile(kind), !s.underwaterDone {
            UnderWater.handle(world: w, id: id, pos: pos)
        }
    }
}
