import Foundation

/// The Gremlin (types 1770…1779) and the Floater, the Wraith (1780…1799) (GF; enemies-flyers §1, §4–§7):
/// `.InitGremlinSprite @ 1007faac` (M l. 69080–69150: the cache sets 0x6ea / 0x6eb / 0x6ec and the wing table, 22
/// shorts from data 0x100a6dd0 — `wings`), `.SetupGremlinSprite @ 1007fc88` (M l. 69153–69234, `setupGremlin`),
/// `.HandleGremlinSprite @ 1007feec` (M l. 69237–69637, `handleGremlin`: the body arm M l. 69281–69461, the rider arm
/// M l. 69462–69633), `.HitGremlinSprite @ 10080d34` (M l. 69640–69721, `hitGremlin`), `.KillGremlinSprite @ 100810d4`
/// (M l. 69724–69758, `killGremlin`), `.HitGremlinTileSprite @ 100811a4` (M l. 69761–69817, `hitGremlinTile`);
/// `.InitFloaterSprite @ 100813dc` (M l. 69820–69831: 0x6f4, 0x6fe, 0x6ff), `.SetupFloaterSprite @ 100814b8` (M l.
/// 69834–69907, `setupFloater`), `.HandleFloaterSprite @ 100816d8` (M l. 69910–70031, `handleFloater`),
/// `.HitFloaterSprite @ 10081aa4` (M l. 70034–70073, `hitFloater`), `.HitFloaterTileSprite @ 10081c60` (M l.
/// 70076–70108 — the Crawler's shape, `CrawlerRoach.hitTile`). The Gremlin's path is `ProgrammedPath`
/// (`World/Movers/ProgrammedPath.swift`, audit ruling 3).
///
/// A Gremlin is three sprites, each running `.SetupGremlinSprite` and the Gremlin Handle / hit / Kill: the body (the
/// record, `+0xec` 0), its back layer (`+0x1d4`, `+0xec` 1 — its Handle arm is empty: the body places it) and the rider
/// (`+0x1d8`, `+0xec` 2, backlink `+0x1d4`). Every part stores `+0x188 = 1` (M l. 69232 — no record write-back); the
/// Kill stores `+0xea` (M l. 69746). The Floater stores no write-back flag, has no Kill and no death path (its HP is
/// never tested). Neither class's hit has an Effect 0x4b7 (Smiting explosion) or geyser arm, nor any liquids row: the
/// Ring of Smiting reaches both through its seeds (player shots); the Gremlin body's water block is dead as shipped.
///
/// Fields (`SpriteSlot`): `+0xec` `partIndex`; `+0x14c` `classTimer` (the rider state — 0 mounted, 1 dislodged, 2 dead
/// — copied from the body to the rider each frame; the Wraith's hidden period); `+0x150` `classWord150` (−1, the crush
/// 0x16); `+0x154` `classWord154` (the rider's firing frame t; the Wraith's teleport box); `+0x158` `classWord158` (the
/// rider's shot direction; the Wraith's home x); `+0x15c` `classWord15c` (the rider's cooldown; the Wraith's home y);
/// `+0xa6` `counterA6` (the wing index; the Wraith's hidden countdown); `+0xb0` `subtype` (7, 4 dying); `+0xb2`
/// `subState` (9 firing); `+0x46` `phase` (the Wraith's cycle); `+0x1d4` / `+0x1d8` `siblings.first` / `.second`;
/// `+0x30` `previousVY`; `+0x1bc` `clip.top` (the burn row the parts copy).
public enum GremlinFloater {
    /// The cache sets (`.CacheEncFaceSetFromPICT`, flag 0): `PTR_DAT_100a0cac` 0x6ea (10 × 0x84×0x78, one row: the
    /// body), `_DAT_100a0ca8` 0x6eb (the same: the back layer), `_DAT_100a0ca4` 0x6ec (4 × 0x20×0x20: the rider) (M l.
    /// 69118–69120); `PTR_DAT_100a0cc0` 0x6f4 (6 × 100×0x50: the Wraith), `_DAT_100a0cbc` 0x6fe / `_DAT_100a0cb8` 0x6ff
    /// (8 × 0x58×100 — absent from the data: the unplaced 1790 variant) (M l. 69827–69829).
    public static let bodySet: Int16 = 0x6ea, backSet: Int16 = 0x6eb, riderSet: Int16 = 0x6ec, wraithSet: Int16 = 0x6f4

    /// `.InitGremlinSprite`'s table (M l. 69121–69148; `const.py 100a6dd0`): the body / back-layer frame for each wing
    /// index `+0xa6` 0…21; the count `*psVar7 = 0x16`.
    static let wings: [Int] = [0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9]

    /// The snd slots (`SoundSlots`): `*_DAT_100a0274` 701 'Crawler Ouch', `*_DAT_100a0270` 702 'Crawler uh oh',
    /// `*_DAT_100a026c` 703 'crawler death', `*_DAT_100a0320`[0…1] 477 / 478 'monster1/2Sound', `*_DAT_100a02f4` 494
    /// 'flap', `*_DAT_100a02ec` 496 'firehiss2', `*_DAT_100a02f0` 495 'firehiss', `*_DAT_100a02c8` 504 'elecshot'.
    static let ouchSound: Int16 = 701, uhOhSound: Int16 = 702, deathSound: Int16 = 703, monsterSound: Int16 = 477,
               flapSound: Int16 = 494, hiss2Sound: Int16 = 496, hissSound: Int16 = 495, elecSound: Int16 = 504

    /// f64 `0x100a1bb0` 0.8, `0x100a1ba8` 0.7, `0x100a1bc0` 0.65, `0x100a1bb8` 0.5 (`const.py`).
    static let f80 = Double(bitPattern: 0x3fe9_9999_9999_999a), f70 = Double(bitPattern: 0x3fe6_6666_6666_6666),
               f65 = Double(bitPattern: 0x3fe4_cccc_cccc_cccd), f50 = Double(bitPattern: 0x3fe0_0000_0000_0000)

    @inline(__always) static func h16(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }
    @inline(__always) static func face(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }
    @inline(__always) static func scaled(_ v: Int32, _ f: Double) -> Int32 { TileSolver.fctiwz(Double(v) * f) }

    /// `.CalcCenterPos(s)`: the hot-rect centre from `+0xc` / `+0xa`.
    static func calcCentre(_ s: inout SpriteSlot) {
        let r = s.hotRect
        s.centre.x = h16(s.x + r.left + h16((r.right - r.left) >> 1))
        s.centre.y = h16(s.y + r.top + h16((r.bottom - r.top) >> 1))
    }

    /// The body / back-layer frame of wing index `a6` (in 0…21 on every path: the wrap at 22, the hit's 0x15).
    static func wing(_ a6: Int16) -> Int { wings.indices.contains(Int(a6)) ? wings[Int(a6)] : 0 }

    // MARK: - the Gremlin's Setup

    /// `.MTNewSprite(type, x, y, layer, 0x1ff, .SetupGremlinSprite)` for a part: the part's own Setup runs inside it,
    /// then `store` (the parent's writes into the child, M l. 69205–69223 — nothing runs in between); returns its id
    /// (nil: no free record — the stores are dropped).
    public typealias NewPart = (_ x: Int, _ y: Int, _ layer: Int32, _ store: (inout SpriteSlot) -> Void) -> Int?

    /// `.SetupGremlinSprite(s)` (M l. 69153–69234) after `.InitSprite`; `+8` / `+6` (`oldPosition`) hold the spawn
    /// point. In order: `+0x84` / `+0x86` 0; the Gremlin Handle `+0x4c`, Kill `+0x50`, hit `+0x5c`, `+0x1f8 = 0`; the
    /// three sets marked (`CachedFaces.marks`); gravity 0; `+0xc0 = 0`; HP 500; `+0xc ← +8`, `+0xa ← +6`; SetRect(0x28,
    /// 0x26, 0x59, 0x50); `+0x14c = 0`, `+0x150 = −1`, `+0xa6 = 0`, `+0xb0 = 7`; the 24.8 position; `.CalcCenterPos`.
    /// A child (`+0x48 == 0x1ff`): an empty rect, `+0x5c = 0`, `+0x1b5 = 0`, `+0x188 = 1`. Else (the body): layer 10,
    /// `+0xec = 0`; the back layer `MTNewSprite(type, +0xc, +0xa, 9, 0x1ff)` → `+0xec = 1`, `+0xb8 = 0xb0000`, `+0x88 =
    /// 0`, `+0x5c = 0`, into `+0x1d4`; the rider `MTNewSprite(type, +0xc + 0x26, +0xa + 0x1b, 12, 0x1ff)` → `+0xec = 2`,
    /// SetRect(6, 3, 0x1a, 0x1b) then bottom − 5, the tile callback `.HitGremlinTileSprite`, into `+0x1d8` — its backlink
    /// `+0x1d4` is the caller's (`linkRider`: the body has no id before its insert); `+0x188 = 1`;
    /// `.SetupProgrammedPath(s, −1, 0)` (`ProgrammedPath.setup`; modes 10 / 11 `ProgrammedPath.makeRadial` after the
    /// insert); the counting window. Last, every part: `+0x188 = 1`. No draw.
    public static func setupGremlin(_ s: inout SpriteSlot, record p: Placement?, counting: inout EnemyCounting,
                                    newPart: NewPart) {
        s.particleOffsetY = 0
        s.particleOffsetX = 0
        s.handler = .gremlin                                            // `+0x4c`; the Kill `+0x50` (`killGremlin`)
        s.hasHit = true                                                 // `+0x5c` = `.HitGremlinSprite`
        s.hasTileHit = false                                            // `+0x1f8 = 0`
        s.gravity = 0
        s.face = nil
        s.hp = 500
        s.x = s.oldPosition.x
        s.y = s.oldPosition.y
        s.hotRect = IdleSprites.Rect(top: 0x26, left: 0x28, bottom: 0x50, right: 0x59)
        s.classTimer = 0
        s.classWord150 = -1
        s.counterA6 = 0
        s.subtype = 7
        s.x256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.y)) << 8
        calcCentre(&s)
        if s.recordIndex == 0x1ff {
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0)
            s.hasHit = false
            s.countedInTotals = false
            s.keepRecord = true
        } else {
            s.layer = 10
            s.partIndex = 0
            let x = s.x, y = s.y, layer = s.layer
            let back = newPart(x, y, layer &- 1) { c in
                c.partIndex = 1
                c.mode = 0xb0000
                c.lightOverlay = false                                  // `+0x88 = 0`
                c.hasHit = false                                        // `+0x5c = 0`
            }
            let rider = newPart(h16(x + 0x26), h16(y + 0x1b), layer &+ 2) { c in
                c.partIndex = 2
                c.hotRect = IdleSprites.Rect(top: 3, left: 6, bottom: 0x1b - 5, right: 0x1a)
                c.hasTileHit = true                                     // `+0x1f8` = `.HitGremlinTileSprite`
            }
            s.siblings.first = back
            s.siblings.second = rider
            s.keepRecord = true
            ProgrammedPath.setup(&s, record: p)
            counting.countIfWindow(&s)                                  // M l. 69227–69230
        }
        s.keepRecord = true                                             // M l. 69232
    }

    /// The rider's backlink `rider +0x1d4 = s` (M l. 69219), made once the body `id` is in the list.
    public static func linkRider(_ w: SpriteWorld, parent id: Int) {
        guard let r = w.active.record(id: id)?.siblings.second else { return }
        w.active.update(id: r) { $0.siblings.first = id }
    }

    // MARK: - the Gremlin's Handle

    /// The tile callback `+0x1f8` (nil = 0): `.HitGremlinTileSprite` (`hitGremlinTile`).
    static func passGremlin(_ s: SpriteSlot) -> TileHit? {
        guard s.hasTileHit else { return nil }
        return { solver, id, cell, kind, layer in hitGremlinTile(solver, id: id, pos: cell, kind: kind, layer: layer) }
    }

    /// `.HandleGremlinSprite(s)` (M l. 69237–69637), unless `+0xe9` or `+0x1b2`: the body arm (`+0xec == 0`, `body`),
    /// the rider arm (`+0xec == 2`, `rider`); the back layer (`+0xec == 1`) has none — the body places it.
    /// - Parameters: `lights` / `effects` reach the coins' and the shot's Setups (`effects` also the rider's blood
    ///   count, prefs+6); `faceWidth` the Cleanup's face `+6`.
    public static func handleGremlin(world w: SpriteWorld, id: Int, solver: TileSolver, lights: inout LightTable,
                                     effects: Int16, faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right }) {
        guard let s0 = w.active.record(id: id), !s0.dead, !s0.handleSkip else { return }
        if s0.partIndex == 0 {
            body(w, id: id, solver: solver, lights: &lights, effects: effects, faceWidth: faceWidth)
        } else if s0.partIndex == 2 {
            rider(w, id: id, solver: solver, effects: effects)
        }
    }

    /// The body arm (M l. 69281–69461). P.x = `*_DAT_1009fd94`, c = the stored centre:
    /// 1. the rider's `+0x14c` = the body's; `.StandardSpriteHandles`;
    /// 2. the water block (M l. 69286–69306) — **dead as shipped**: `.StandardSpriteHandles` has just zeroed `+0x11c`
    ///    (raw `1008061c..10080628`; enemies-flyers §4.2); transcribed as written: vy > −800 → − 100; fully under
    ///    plain water or in any liquid kind > 0, `+0x116 == 0` → `+0x116 = 0x13`, HP − 100, `+0xaa = 0x11`, 701 (Rand,
    ///    0x55), R(100) < 0x12 → 477 / 478 by R(2) pitched 84000 + R(5000) (the R(5000) first), 0xab;
    /// 3. `.HandleProgrammedPath` (`ProgrammedPath.handle`);
    /// 4. by state — 4 (dying): R(3) first; `+0x5c = 0`, path off, vx · 0.8, gravity 0x5a, the tile callback; `+0x1a2 <
    ///    1` → `+0x1a2 = 1` (the burn), score + 1200, R(3) + 1 coins `MTNewSprite(0x516, c.x − 4, c.y − 4, 2, −1,
    ///    .SetupBonusSprite)` with vy −0x578 − R(0x640), vx R(1000) − 500, then vy = 0 and, the rider mounted
    ///    (`+0x14c == 0`), 477 / 478 by R(2) (Rand, 0x100); path mode 1: `+0xa6` + 1 while vy < `+0x30` or mid-cycle,
    ///    vx · 0.8, the facing by P.x (kept when equal); any other mode: `+0xa6` + 1; mode 2 faces by vx (vx < 1 →
    ///    left) and vy · 0.7; the rest face P.x;
    /// 5. `+0xa6 ≥ 22` → 0 and 494 'flap' (Rand, 0x55); the face 0x6ea[`wings[+0xa6]`]; HP < 1 → state 4;
    /// 6. `+0x14 += vx`, `+0x1c += vy`, `.ApplyGravityAndSeparateFromTiles` (2·v a frame); `.StandardSpriteCleanup`;
    /// 7. the back layer: `+0xc` / `+0xa`, `+0x17e`, the face 0x6eb[`wings[+0xa6]`], `+0x1bc` = the body's; the rider
    ///    mounted (`+0x14c == 0`): `+0x17e`, `+0xaa`, `+0xb8` = the body's, `+0x1bc` > 0x1b → − 0x1b, at the body +
    ///    (0x26 facing left | 0x3e facing right, 0x1b), 24.8 from them; not mounted: the rider's hit `.HitGremlinSprite`
    ///    and, while HP > 0, the saddle's blood (`saddleBlood`).
    static func body(_ w: SpriteWorld, id: Int, solver: TileSolver, lights: inout LightTable, effects: Int16,
                     faceWidth: (FaceRef) -> Int) {
        guard let s0 = w.active.record(id: id) else { return }
        if let r = s0.siblings.second {
            let state = s0.classTimer
            w.active.update(id: r) { $0.classTimer = state }
        }
        w.standardSpriteHandles(id)
        guard var s = w.active.record(id: id) else { return }
        if s.waterRow != 0 {                                            // M l. 69286–69306: dead (see above)
            if -800 < s.vy { s.vy &-= 100 }
            if ((s.waterRow == 1 && s.waterKind == 0) || 0 < s.waterKind) && s.invulnerable == 0 {
                s.invulnerable = 0x13
                s.hp &-= 100
                s.flash = 0x11
                w.player.cue(PlayerCue(call: .threeDRand, snd: ouchSound, priority: 1, volume: 0x55, position: s.centre,
                                       rate: w.rng.soundRate()))
                if w.rng.next(100) < 0x12 {
                    let p = Int32(w.rng.next(5000))
                    let k = w.rng.next(2)
                    w.player.cue(PlayerCue(call: .threeDPitched, snd: monsterSound &+ k, priority: 1, volume: 0xab,
                                           position: s.centre, rate: p + 84000))
                }
            }
        }
        ProgrammedPath.handle(w, id: id, slot: &s)
        let px = Int(w.player.centreX), cx = h16(s.centre.x)
        func faceThePlayer() {
            if cx < px {
                s.mirrored = true
            } else if px < cx {
                s.mirrored = false
            }
        }
        if s.subtype == 4 {
            let n = w.rng.next(3)
            s.hasHit = false                                            // `+0x5c = 0`
            s.pathMode = 0
            s.vx = scaled(s.vx, f80)
            s.gravity = 0x5a
            s.hasTileHit = true                                         // `+0x1f8` = `.HitGremlinTileSprite`
            if s.burnRow < 1 {
                s.burnRow = 1
                w.globals.score &+= 0x4b0
                w.active.update(id: id) { [s] in $0 = s }
                coins(w, at: s.centre, count: n &+ 1, lights: &lights, effects: effects)
                s.vy = 0
                if s.classTimer == 0 {
                    let k = w.rng.next(2)
                    w.player.cue(PlayerCue(call: .threeDRand, snd: monsterSound &+ k, priority: 1, volume: 0x100,
                                           position: s.centre, rate: w.rng.soundRate()))
                }
            }
        } else if s.pathMode == 1 {
            if s.vy < s.previousVY {
                s.counterA6 &+= 1
            } else if s.counterA6 != 0 {
                s.counterA6 &+= 1
            }
            s.vx = scaled(s.vx, f80)
            faceThePlayer()
        } else {
            s.counterA6 &+= 1
            if s.pathMode == 2 {
                s.mirrored = !(s.vx < 1)
                s.vy = scaled(s.vy, f70)
            } else {
                faceThePlayer()
            }
        }
        if 0x16 <= s.counterA6 {
            s.counterA6 = 0
            w.player.cue(PlayerCue(call: .threeDRand, snd: flapSound, priority: 1, volume: 0x55, position: s.centre,
                                   rate: w.rng.soundRate()))
        }
        let frame = wing(s.counterA6)
        s.face = face(bodySet, frame)
        if s.hp < 1 { s.subtype = 4 }
        s.x256 &+= s.vx
        s.y256 &+= s.vy
        w.active.update(id: id) { [s] in $0 = s }
        solver.applyGravityAndSeparate(id, pass: passGremlin(s))
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
        guard let t = w.active.record(id: id) else { return }
        if let b = t.siblings.first {
            w.active.update(id: b) { c in
                c.x = t.x
                c.y = t.y
                c.mirrored = t.mirrored
                c.face = face(backSet, frame)
                c.clip.top = t.clip.top
            }
        }
        if t.classTimer == 0, let r = t.siblings.second {
            w.active.update(id: r) { c in
                c.mirrored = t.mirrored
                c.flash = t.flash
                c.mode = t.mode
                if 0x1b < t.clip.top { c.clip.top = t.clip.top - 0x1b }
                c.x = h16(t.x + (t.mirrored ? 0x3e : 0x26))
                c.y = h16(t.y + 0x1b)
                c.x256 = Int32(c.x) << 8
                c.y256 = Int32(c.y) << 8
            }
        } else {
            if let r = t.siblings.second { w.active.update(id: r) { $0.hasHit = true } }   // `+0x5c` = `.HitGremlinSprite`
            if 0 < t.hp { saddleBlood(w, t) }
        }
    }

    /// The dying body's coins (M l. 69320–69330): `count` × `MTNewSprite(0x516, c.x − 4, c.y − 4, 2, −1,
    /// .SetupBonusSprite)` (its Setup's draws inside), then vy −0x578 − R(0x640), vx R(1000) − 500 (no free record: the
    /// stores dropped, the draws made) — the Bat's coins.
    static func coins(_ w: SpriteWorld, at c: SpriteSlot.Point, count: Int16, lights: inout LightTable, effects: Int16) {
        let pl = w.playerID.flatMap { w.active.record(id: $0) }?.layer ?? 0
        var i: Int16 = 0
        while i < count {
            let x = h16(c.x - 4), y = h16(c.y - 4)
            let k = w.newSprite(type: 0x516, x: x, y: y, layer: 2, handler: .bonus) { b in
                // Cannot throw: `BonusSprite.setup` throws only for 0xc25 and items past 0xc9a.
                _ = try! BonusSprite.setup(&b, x: x, y: y, level: w.level, records: w.records, effects: effects,
                                           lightCount: lights.count, counting: false, playerLayer: pl,
                                           rng: &w.rng) { lf, lh, lv, col in
                    lights.add(face: lf, x: Int16(truncatingIfNeeded: lh), y: Int16(truncatingIfNeeded: lv), vx: 0,
                               vy: 0, accelY: 0, colour: col)
                }
            }
            let vy = -0x578 - Int32(w.rng.next(0x640))
            let vx = Int32(w.rng.next(1000)) - 500
            if let k {
                w.active.update(id: k) { t in
                    t.vy = vy
                    t.vx = vx
                }
            }
            i += 1
        }
    }

    /// The empty saddle's blood (M l. 69424–69461), the body `t` after its Cleanup: n = R(5) + 8; the point (y + R(3) +
    /// 0x2f, x + R(3) + 0x3a facing left | 0x4a facing right) (the h draw first), a = −400 facing left else 400; each
    /// particle: d = R(3), 0 → −0x32 − R(0x46); then R(0x3c) for vy, R(0x3c) for vx: `NewParticle(2, 100, point, 4, a +
    /// vx + R − 0x1e, vy + R − 0x1e0, d, 1)`.
    static func saddleBlood(_ w: SpriteWorld, _ t: SpriteSlot) {
        let n = w.rng.next(5)
        let rh = Int(w.rng.next(3))
        let rv = Int(w.rng.next(3))
        let h = h16(t.x + rh + (t.mirrored ? 0x4a : 0x3a)), v = h16(t.y + rv + 0x2f)
        let a: Int32 = t.mirrored ? 400 : -400
        let vx = t.vx, vy = t.vy
        var i: Int32 = 0
        while i < Int32(n &+ 8) {
            var d = Int32(w.rng.next(3))
            if Int16(truncatingIfNeeded: d) == 0 { d = -0x32 - Int32(w.rng.next(0x46)) }
            let r16 = Int32(w.rng.next(0x3c))
            let r14 = Int32(w.rng.next(0x3c))
            w.particles.newParticle(kind: 2, gravity: 100, v: v, h: h, shape: 4, vx: Int(a &+ vx &+ r14 &- 0x1e),
                                    vy: Int(vy &+ r16 &- 0x1e0), delay: Int(d), mode: 1)
            i += 1
        }
    }

    /// The rider arm (M l. 69462–69633). P = the player sprite's stored centre (`*_DAT_1009fdd8 + 0xe`; (0, 0) with no
    /// player sprite [LOW: low memory in the original]), P.x also the global `*_DAT_1009fd94`; c = the stored centre:
    /// 1. dislodged or alone (`+0x14c ≠ 0`): `.StandardSpriteHandles`; `hdr+0xb282 << 5 < +0xa` → HP −1; HP < 1 → the
    ///    death (`riderDeath`) — and the arm runs on;
    /// 2. `+0x15c` − 1; < 1 → 0 and, unless firing (`+0xb2 == 9`), the aim: d = `.FindDesiredDirectionGeneric(c, P)`
    ///    into `+0x158`; facing left: d 18 or 16…17 → 18, 19…24 → 22, each a shot; then `+0x14c == 1` → 18, no shot
    ///    with c.x < P.x; facing right: 0 or 1…2 → 0, 30…35 → 32; `+0x14c == 1` → 0, no shot with P.x < c.x. No body
    ///    (`+0x1d4` 0): the shot stands; the body's HP < 1: no shot; else no shot unless `PtInRect(body centre, (scroll h
    ///    − 0x20, v − 0x20, h + 0x280, v + 0x1a0))`. A shot with `+0x14c ≠ 2`: `+0x158 = (d + 18) mod 36`, `+0x154 = 0`,
    ///    `+0xb2 = 9`. Then, with `+0x14c ≠ 2`, the face 0x6ec[0] is written to the sprite at the rider's own
    ///    `+0x1d8` — always 0 (raw `10080354`): never made;
    /// 3. firing (`+0xb2 == 9`), t = `+0x154`: a body in path mode 1 with the rider mounted → its vx, vy · 0.65; the
    ///    face 0x6ec[t >> 1] for t < 8, else [6 − (t >> 1)]; t == 1 → R(100) < 0x33 → 496 else 495 (Rand, 0xab); t ==
    ///    7 → the shot (`shoot`); t > 11 → `+0x154 = 0`, `+0xb2 = 0`, `+0x15c = R(0x1e) + 0x1e`; `+0x154` + 1;
    /// 4. `+0x14 += vx`, `+0x1c += vy`, `.ApplyGravityAndSeparateFromTiles`; on ground (`+0xce`) vx · 0.5.
    static func rider(_ w: SpriteWorld, id: Int, solver: TileSolver, effects: Int16) {
        guard var s = w.active.record(id: id) else { return }
        if s.classTimer != 0 {
            w.standardSpriteHandles(id)
            guard let t = w.active.record(id: id) else { return }
            s = t
            if Int32(w.level.header.gridHeight) << 5 < Int32(h16(s.y)) { s.hp = -1 }
            if s.hp < 1 { riderDeath(w, &s, effects: effects) }
        }
        s.classWord15c &-= 1
        if s.classWord15c < 1 {
            s.classWord15c = 0
            if s.subState != 9 { aim(w, &s) }
        }
        if s.subState == 9 {
            if let b = s.siblings.first, let body = w.active.record(id: b), body.pathMode == 1, s.classTimer == 0 {
                w.active.update(id: b) { c in
                    c.vx = scaled(c.vx, f65)
                    c.vy = scaled(c.vy, f65)
                }
            }
            let t = s.classWord154
            let half = Int(t >> 1)
            s.face = face(riderSet, t < 8 ? half : 6 - half)
            if s.classWord154 == 1 {
                let snd = w.rng.next(100) < 0x33 ? hiss2Sound : hissSound
                w.player.cue(PlayerCue(call: .threeDRand, snd: snd, priority: 1, volume: 0xab, position: s.centre,
                                       rate: w.rng.soundRate()))
            }
            if s.classWord154 == 7 { shoot(w, s) }
            if 0xb < s.classWord154 {
                s.classWord154 = 0
                s.subState = 0
                s.classWord15c = Int32(w.rng.next(0x1e)) + 0x1e
            }
            s.classWord154 &+= 1
        }
        s.x256 &+= s.vx
        s.y256 &+= s.vy
        w.active.update(id: id) { [s] in $0 = s }
        solver.applyGravityAndSeparate(id, pass: passGremlin(s))
        w.active.update(id: id) { c in
            if c.groundKind != 0 { c.vx = scaled(c.vx, f50) }
        }
    }

    /// The rider's aim (M l. 69506–69566), on `s` (see `rider` step 2).
    static func aim(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        var shot = false
        let p = w.playerID.flatMap { w.active.record(id: $0) }?.centre ?? SpriteSlot.Point()
        let d = BloodSpray.direction(target: (v: Int16(truncatingIfNeeded: s.centre.y),
                                              h: Int16(truncatingIfNeeded: s.centre.x)),
                                     from: (v: Int16(truncatingIfNeeded: p.y), h: Int16(truncatingIfNeeded: p.x)))
        s.classWord158 = Int32(d)
        let px = Int(w.player.centreX), cx = h16(s.centre.x)
        if !s.mirrored {
            if d == 0x12 || (0x10...0x11).contains(d) {
                s.classWord158 = 0x12
                shot = true
            } else if (0x13...0x18).contains(d) {
                s.classWord158 = 0x16
                shot = true
            }
            if s.classTimer == 1 {
                s.classWord158 = 0x12
                if cx < px { shot = false }
            }
        } else {
            if d == 0 || (1...2).contains(d) {
                s.classWord158 = 0
                shot = true
            } else if (0x1e...0x23).contains(d) {
                s.classWord158 = 0x20
                shot = true
            }
            if s.classTimer == 1 {
                s.classWord158 = 0
                if px < cx { shot = false }
            }
        }
        if let b = s.siblings.first {
            // A link to a record no longer held reads as HP 0 [LOW: the original reads the freed record].
            if let body = w.active.record(id: b), 0 < body.hp {
                let h = w.player.scrollH, v = w.player.scrollV
                let bx = h16(body.centre.x), by = h16(body.centre.y)
                // `PtInRect`: left ≤ h < right, top ≤ v < bottom.
                if !(h16(h - 0x20) <= bx && bx < h16(h + 0x280) && h16(v - 0x20) <= by && by < h16(v + 0x1a0)) {
                    shot = false
                }
            } else {
                shot = false
            }
        }
        if shot && s.classTimer != 2 {
            s.classWord158 = (s.classWord158 &+ 0x12) % 0x24
            s.classWord154 = 0
            s.subState = 9
        }
        if let o = s.siblings.second, s.classTimer != 2 {
            // The rider's own `+0x1d8` is never set (raw `10080354`): this store is never made.
            w.active.update(id: o) { $0.face = face(riderSet, 0) }
        }
    }

    /// The shot at t == 7 (M l. 69601–69617): `MTNewSprite(0x712, +0xc + 4, +0xa + 6, +0x80 − 1, −1,
    /// .SetupEnemyShotSprite)`, `FUN_1003f218(shot, (i16) +0x158, 0x708)`, a body (`+0x1d4`) → shot vx + its vx; the
    /// shot's rect bottom − 3; dir 4 → `+0x17e = 1`, `+0x1aa = 0xdc`; dir 14 → `+0x1aa = 0x140` (no free record: the
    /// stores dropped).
    static func shoot(_ w: SpriteWorld, _ s: SpriteSlot) {
        let k = EnemyShot.spawn(w, type: EnemyShot.spit, x: h16(s.x + 4), y: h16(s.y + 6),
                                layer: Int16(truncatingIfNeeded: s.layer &- 1))
        guard let k else { return }
        let d = s.classWord158
        let bodyVX = s.siblings.first.flatMap { w.active.record(id: $0) }?.vx
        w.active.update(id: k) { c in
            PlayerShot.addDirImpulse(&c, dir: Int(Int16(truncatingIfNeeded: d)), magnitude: 0x708)
            if let bodyVX { c.vx &+= bodyVX }
            c.hotRect.bottom -= 3
            if d == 4 {
                c.mirrored = true
                c.rotation = 0xdc
            }
            if d == 0xe { c.rotation = 0x140 }
        }
    }

    /// The fallen rider's death (M l. 69468–69503), on `s`: N = 0xaa with prefs+6 Effects == 1, else 100; a body
    /// (`+0x1d4`) → its `+0x14c = 2`, `+0x1d8 = 0`; 703 (3D, 0x100); `+0xc0 = 0`, `+0xe9 = 1`; score + 500; N particles
    /// `NewParticle(2, 0x78, (c.y + R(6) + 0x10, c.x + R(6) − 3), 4, R(0x28a) − 0x145, −0x352 − R(700) − R(200), 0, 1)`
    /// (the h offset first, then the v offset, R(700), R(200), R(0x28a)); N >> 3 with R(900), R(300), R(900) − 0x1c2.
    /// No count, no stat.
    static func riderDeath(_ w: SpriteWorld, _ s: inout SpriteSlot, effects: Int16) {
        let n: Int16 = effects == 1 ? 0xaa : 100
        if let b = s.siblings.first {
            w.active.update(id: b) { c in
                c.classTimer = 2
                c.siblings.second = nil
            }
        }
        w.player.cue(PlayerCue(call: .threeD, snd: deathSound, priority: 1, volume: 0x100, position: s.centre))
        s.face = nil
        s.dead = true
        w.globals.score &+= 500
        let cx = h16(s.centre.x), cy = h16(s.centre.y)
        func blood(_ a: Int16, _ b: Int16, _ c: Int16, _ off: Int) {
            let hOff = Int(w.rng.next(6))
            let vOff = Int(w.rng.next(6))
            let ra = Int(w.rng.next(a))
            let rb = Int(w.rng.next(b))
            let rc = Int(w.rng.next(c))
            w.particles.newParticle(kind: 2, gravity: 0x78, v: h16(cy + vOff + 0x10), h: h16(cx + hOff - 3), shape: 4,
                                    vx: rc - off, vy: -0x352 - ra - rb, delay: 0, mode: 1)
        }
        for _ in 0..<Int(n) { blood(700, 200, 0x28a, 0x145) }
        for _ in 0..<Int(n >> 3) { blood(900, 300, 900, 0x1c2) }
    }

    // MARK: - the Gremlin's hit, tiles and Kill

    /// `.HitGremlinSprite(s, other)` (M l. 69640–69721), unless `+0xe9` or `+0xea`; by the other's `+0x4c`:
    /// - a player shot with `+0xa6 == 0`: `.KillPlayerShot(o, 0, 0)` (r29 untouched — `.MTCollideSprites`' stale value,
    ///   raw `10080d34..10080d94`: nil, as the Bat's); type 1 → `.TurnIntoStatue(s)`; else `.HurtSprite(s, o.+0xa4,
    ///   (i16)(o.vx >> 3), (i16)(o.vy >> 3), 2, 8)` and on a hurt: `+0xa6 < 2 → 0x15`; HP > 0 → `.BloodSpray(s, o, 0x28,
    ///   400, 0x96, 2)`; HP < 0xc9 and (`+0x14c == 0` or `+0xec ≠ 0`) → 702 (3D, 0x100); else HP > 0 → 701 (Rand,
    ///   0x55), then R(100) < 0x12 with `+0x14c == 0` → 477 / 478 by R(2) pitched 84000 + R(5000) (the R(5000) first),
    ///   0xab; then `+0x14c == 0`, `+0xec == 0`, a rider and R(100) > 0x50: the dislodge — 703 (Rand, 0x55), `+0x14c =
    ///   1`, the rider's HP R(300) + 300, vx −(R(200) + 300) facing left / + facing right, vy −0x226 − R(200), gravity
    ///   0x96;
    /// - a Statue or a Box: the crush (`CrawlerRoach.crush`: HP 0, `+0x150 = 0x16`).
    public static func hitGremlin(_ w: SpriteWorld, id: Int, other oID: Int, lights: inout LightTable, effects: Int16 = 1,
                                  faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                                  faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard let s = w.active.record(id: id), let o = w.active.record(id: oID), !s.dead, !s.killedForGood else { return }
        let runs = BackgroundSprite.runs
        if runs(o, .playerShot) && o.counterA6 == 0 {
            PlayerShotHits.kill(w, shot: oID, sound: false, effect: false, effects: effects, lights: &lights,
                                faceWidth: faceWidth, faceBounds: faceBounds, staleSlot: nil)
            guard let shot = w.active.record(id: oID) else { return }
            if shot.type == 1 {
                EnemyCommon.turnIntoStatue(w, id: id)
                return
            }
            guard HurtSprite.apply(w, id: id, damage: shot.hp, dvx: Int16(truncatingIfNeeded: shot.vx >> 3),
                                   dvy: Int16(truncatingIfNeeded: shot.vy >> 3), invulnerable: 2, flash: 8) else { return }
            if let t = w.active.record(id: id), t.counterA6 < 2 { w.active.update(id: id) { $0.counterA6 = 0x15 } }
            if let t = w.active.record(id: id), 0 < t.hp {
                BloodSpray.spray(w, victim: id, attacker: oID, count: 0x28, speed: 400, spread: 0x96, kind: 2)
            }
            guard let u = w.active.record(id: id) else { return }
            if u.hp < 0xc9 && (u.classTimer == 0 || u.partIndex != 0) {
                w.player.cue(PlayerCue(call: .threeD, snd: uhOhSound, priority: 1, volume: 0x100, position: u.centre))
            } else if 0 < u.hp {
                w.player.cue(PlayerCue(call: .threeDRand, snd: ouchSound, priority: 1, volume: 0x55, position: u.centre,
                                       rate: w.rng.soundRate()))
                if w.rng.next(100) < 0x12 && u.classTimer == 0 {
                    let p = Int32(w.rng.next(5000))
                    let k = w.rng.next(2)
                    w.player.cue(PlayerCue(call: .threeDPitched, snd: monsterSound &+ k, priority: 1, volume: 0xab,
                                           position: u.centre, rate: p + 84000))
                }
            }
            if u.classTimer == 0 && u.partIndex == 0, let r = u.siblings.second, 0x50 < w.rng.next(100) {
                w.player.cue(PlayerCue(call: .threeDRand, snd: deathSound, priority: 1, volume: 0x55, position: u.centre,
                                       rate: w.rng.soundRate()))
                w.active.update(id: id) { $0.classTimer = 1 }
                let hp = w.rng.next(300) &+ 300
                let vx: Int32 = u.mirrored ? Int32(w.rng.next(200)) + 300 : -(Int32(w.rng.next(200)) + 300)
                let vy = -0x226 - Int32(w.rng.next(200))
                w.active.update(id: r) { c in
                    c.hp = hp
                    c.vx = vx
                    c.vy = vy
                    c.gravity = 0x96
                }
            }
        } else if runs(o, .statue) || runs(o, .box) {
            CrawlerRoach.crush(w, id: id, other: oID)
        }
    }

    /// The test-only form (no light table).
    static func hitGremlin(_ w: SpriteWorld, id: Int, other oID: Int) {
        var scratch = LightTable()
        hitGremlin(w, id: id, other: oID, lights: &scratch)
    }

    /// `.HitGremlinTileSprite(s, pos, kind, layer)` (M l. 69761–69817): a dying body (`+0xb0 == 4`) or the rider
    /// (`+0xec == 2`) → vx · 0.8 on every call and the bounce factor 0xa0; FG (layer 1) → `.WallBounce(s, kind, &pos,
    /// the hot-rect centre, factor, +0x34, 0, factor ≠ 0)` and on a hit |vy| < 0x100 → 0; the BG kinds — < 100
    /// `.WallBounce(…, 0, …, 0)`, < 200 `.WallBounceBG(kind − 100, …)`, water `.HandleUnderWater` unless `+0x140` — are
    /// the Crawler's (`CrawlerRoach.hitTile`).
    static func hitGremlinTile(_ solver: TileSolver, id: Int, pos posIn: TilePos, kind: Int, layer: TileLayer) {
        let w = solver.world
        guard let s0 = w.active.record(id: id) else { return }
        var factor: Int16 = 0
        if s0.subtype == 4 || s0.partIndex == 2 {
            factor = 0xa0
            w.active.update(id: id) { $0.vx = scaled($0.vx, f80) }
        }
        guard layer == .foreground else {
            CrawlerRoach.hitTile(solver, id: id, pos: posIn, kind: kind, layer: layer)
            return
        }
        guard let s = w.active.record(id: id) else { return }
        var pos = posIn
        let r = s.hotRect
        let vCentre = h16(r.top + h16((r.bottom - r.top) >> 1))
        if solver.wallBounce(id, kind: kind, tile: &pos, vCentre: vCentre, factor: factor, rect: r, bounce: factor != 0) {
            w.active.update(id: id) { c in
                let v = c.vy < 1 ? 0 &- c.vy : c.vy
                if v < 0x100 { c.vy = 0 }
            }
        }
    }

    /// `.KillGremlinSprite(s)` (M l. 69724–69758), the Kill proc `+0x50` (`EnemyCommon.killProc`): `+0xe9 ≠ 0` → return;
    /// the counting Kill (`EnemyCounting.kill`: `+0x1b5` → live − 1, the stat `G+0x306+2·L` + 1); score + 2000; `+0xe9 =
    /// +0xea = 1`; the back layer `+0xe9 = 1`; a mounted rider (`+0x14c == 0`) `+0xe9 = 1`; the rider's backlink 0.
    static func killGremlin(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        guard s.killCount == 0 else { return }                         // raw 100810e0 `bnelr`
        w.enemies.kill(&s, globals: &w.globals, level: w.levelIndex, forGood: true)
        w.globals.score &+= 2000
        if let b = s.siblings.first { w.active.update(id: b) { $0.dead = true } }
        if let r = s.siblings.second, s.classTimer == 0 { w.active.update(id: r) { $0.dead = true } }
        if let r = s.siblings.second { w.active.update(id: r) { $0.siblings.first = nil } }
    }

    // MARK: - the Floater

    /// `.SetupFloaterSprite(s)` (M l. 69834–69907) after `.InitSprite`; `+8` / `+6` (`oldPosition`) hold the spawn point.
    /// In order: `+0x84` / `+0x86` 0; layer 0xb; the Floater Handle, hit and tile callbacks; gravity 0; `+0xc0 = 0`; HP
    /// 500; `+0xc ← +8`, `+0xa ← +6`; by type — 0x6f4…0x6fd: the set 0x6f4 marked, SetRect(0x23, 1, 0x3e, 0x4b),
    /// `+0x1f8 = 0`, the hidden period `+0x14c` = the record's p1 (0 → 0x41), the first delay `+0xa6` = p2, the teleport
    /// box `+0x154` = p3 (0 → 0x50), home `+0x158` / `+0x15c` = `+0xc` / `+0xa`, `+0x46 = 0`, gravity 0, `+0x88 = 0`;
    /// 0x6fe…0x707 (the unfinished variant): the sets 0x6fe / 0x6ff marked, SetRect(0x17, 2, 0x38, 0x5c) — nothing
    /// else (home and box stay 0: its Handle's `FastRand(0)` reseeds from the clock); `+0xb0 = 7`; the counting window;
    /// the 24.8 position. No draw, no save flag. `record` nil (`+0x48 == −1`): its p1…p3 read 0 [LOW: the original
    /// reads before the records].
    public static func setupFloater(_ s: inout SpriteSlot, record p: Placement?, counting: inout EnemyCounting) {
        s.particleOffsetY = 0
        s.particleOffsetX = 0
        s.layer = 0xb
        s.handler = .floater
        s.hasHit = true                                                 // `+0x5c` = `.HitFloaterSprite`
        s.hasTileHit = true                                             // `+0x1f8` = `.HitFloaterTileSprite`
        s.gravity = 0
        s.face = nil
        s.hp = 500
        s.x = s.oldPosition.x
        s.y = s.oldPosition.y
        let t = s.type
        if (0x6f4...0x6fd).contains(t) {
            s.hotRect = IdleSprites.Rect(top: 1, left: 0x23, bottom: 0x4b, right: 0x3e)
            s.hasTileHit = false                                        // `+0x1f8 = 0`
            s.classTimer = Int32(p?.p1 ?? 0)
            if s.classTimer == 0 { s.classTimer = 0x41 }
            s.counterA6 = p?.p2 ?? 0
            s.classWord154 = Int32(p?.p3 ?? 0)
            if s.classWord154 == 0 { s.classWord154 = 0x50 }
            s.classWord158 = Int32(h16(s.x))
            s.classWord15c = Int32(h16(s.y))
            s.phase = 0
            s.gravity = 0
            s.lightOverlay = false                                      // `+0x88 = 0`
        } else if (0x6fe...0x707).contains(t) {
            s.hotRect = IdleSprites.Rect(top: 2, left: 0x17, bottom: 0x5c, right: 0x38)
        }
        s.subtype = 7
        counting.countIfWindow(&s)                                      // M l. 69900–69903
        s.x256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.y)) << 8
    }

    /// The tile callback `+0x1f8` (nil = 0): `.HitFloaterTileSprite` — the Crawler's (`CrawlerRoach.hitTile`).
    static func passFloater(_ s: SpriteSlot) -> TileHit? {
        guard s.hasTileHit else { return nil }
        return { solver, id, cell, kind, layer in CrawlerRoach.hitTile(solver, id: id, pos: cell, kind: kind, layer: layer) }
    }

    /// `.HandleFloaterSprite(s)` (M l. 69910–70031), unless `+0xe9` or `+0x1b2`. P = `*_DAT_1009fd94` / `fd90`:
    /// 1. `.StandardSpriteHandles`;
    /// 2. `+0xa6 > 0` → − 1 and `+0xc0 = 0`; else by the phase p = `+0x46` (then `+0x46` + 1):
    ///    - p < 12: p == 0 → the teleport: x = home x − box / 2 + R(box) (C division), y likewise (the x draw first),
    ///      the 24.8 position from them, vx = R(600) − 300, vy = R(600) − 300; the facing; the face 0x6f4[0]; `+0xb8` =
    ///      0xb0002 (p < 4), 0xb0000 (< 8), 0xb0001;
    ///    - p < 20: the facing; `+0xb8 = 0`;
    ///    - p < 29: the face [(p − 18) >> 1];
    ///    - p == 29: the shot (`fire`);
    ///    - 30…64: nothing;
    ///    - p < 75: the face [(10 − (p − 65)) >> 1]; p < 87: `+0xb8` = 0xb0001 (p < 79), 0xb0000 (< 83), 0xb0002, and
    ///      while hurt-flashing (`+0xaa > 0`) `+0x46 = 0x4a`, `+0xb8 = 0`; else `+0xc0 = 0`, `+0xb8 = 0`, `+0x46 = −1`,
    ///      `+0xa6` = the hidden period `+0x14c`;
    ///    the facing: `+0x17e` = P.x ≥ the stored centre x (signed; the carry idiom, raw `10081810..10081824`);
    /// 3. `.ApplyGravityAndSeparateFromTiles` (one displacement); `.StandardSpriteCleanup`. HP is never tested.
    public static func handleFloater(world w: SpriteWorld, id: Int, solver: TileSolver,
                                     faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right }) {
        guard let s0 = w.active.record(id: id), !s0.dead, !s0.handleSkip else { return }
        w.standardSpriteHandles(id)
        guard var s = w.active.record(id: id) else { return }
        let px = w.player.centreX
        func faceThePlayer() { s.mirrored = Int16(truncatingIfNeeded: s.centre.x) <= px }
        if s.counterA6 < 1 {
            let p = s.phase
            if p < 0xc {
                if p == 0 {
                    let box = Int16(truncatingIfNeeded: s.classWord154)
                    let half = Int(Int16(truncatingIfNeeded: s.classWord154 / 2))
                    let rx = Int(w.rng.next(box))
                    s.x = h16(Int(Int16(truncatingIfNeeded: s.classWord158)) - half + rx)
                    let ry = Int(w.rng.next(box))
                    s.y = h16(Int(Int16(truncatingIfNeeded: s.classWord15c)) - half + ry)
                    s.x256 = Int32(s.x) << 8
                    s.y256 = Int32(s.y) << 8
                    s.vx = Int32(w.rng.next(600)) - 300
                    s.vy = Int32(w.rng.next(600)) - 300
                }
                faceThePlayer()
                s.face = face(wraithSet, 0)
                s.mode = p < 4 ? 0xb0002 : (p < 8 ? 0xb0000 : 0xb0001)
            } else if p < 0x14 {
                faceThePlayer()
                s.mode = 0
            } else if p < 0x1d {
                s.face = face(wraithSet, Int(Int16(truncatingIfNeeded: p &- 0x12) >> 1))
            } else if p == 0x1d {
                w.active.update(id: id) { [s] in $0 = s }
                fire(w, s)
            } else if 0x40 < p {
                if p < 0x4b {
                    s.face = face(wraithSet, Int(Int16(truncatingIfNeeded: 10 - (p &- 0x41)) >> 1))
                } else if p < 0x57 {
                    s.mode = p < 0x4f ? 0xb0001 : (p < 0x53 ? 0xb0000 : 0xb0002)
                    if 0 < s.flash {
                        s.phase = 0x4a
                        s.mode = 0
                    }
                } else {
                    s.face = nil
                    s.mode = 0
                    s.phase = -1
                    s.counterA6 = Int16(truncatingIfNeeded: s.classTimer)
                }
            }
            s.phase &+= 1
        } else {
            s.counterA6 &-= 1
            s.face = nil
        }
        w.active.update(id: id) { [s] in $0 = s }
        solver.applyGravityAndSeparate(id, pass: passFloater(s))
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
    }

    /// The Wraith's bolt at phase 0x1d (M l. 69976–69992): off = 6 facing left / 0x5e facing right;
    /// `MTNewSprite(+4, +0xc + off − 12, +0xa + 10, 0, −1, .SetupEnemyShotSprite)` (its own type); 504 'elecshot' (3D,
    /// 0xab) at (y + 0x16, x + off); the shot's `+0x15c` = `.FindDesiredDirectionGeneric((P.y + 8, P.x), (y + 0x16, x +
    /// off))` (no free record: dropped).
    static func fire(_ w: SpriteWorld, _ s: SpriteSlot) {
        let off = s.mirrored ? 0x5e : 6
        let k = EnemyShot.spawn(w, type: s.type, x: h16(s.x + off - 0xc), y: h16(s.y + 10), layer: 0)
        let pos = SpriteSlot.Point(x: h16(s.x + off), y: h16(s.y + 0x16))
        w.player.cue(PlayerCue(call: .threeD, snd: elecSound, priority: 1, volume: 0xab, position: pos))
        let d = BloodSpray.direction(target: (v: w.player.centreY &+ 8, h: w.player.centreX),
                                     from: (v: Int16(truncatingIfNeeded: pos.y), h: Int16(truncatingIfNeeded: pos.x)))
        if let k { w.active.update(id: k) { $0.classWord15c = Int32(d) } }
    }

    /// `.HitFloaterSprite(s, other)` (M l. 70034–70073), no state guard; by the other's `+0x4c`:
    /// - a player shot with `+0xa6 == 0` while visible (`+0xc0 ≠ 0`): `.KillPlayerShot(o, 0, 0)` (r29 untouched, raw
    ///   `10081aa4..10081af4`: nil); type 1 → `.TurnIntoStatue(s)` — no HP damage;
    /// - an EnemyShot of the Wraith's own type while visible: 701 (3D, 0x100), HP − 100, `+0xaa = 10`, `.KillEnemyShot`;
    /// - a Statue or a Box (visible or not): the crush (`CrawlerRoach.crush`: HP 0, `+0x150 = 0x16`).
    public static func hitFloater(_ w: SpriteWorld, id: Int, other oID: Int, lights: inout LightTable, effects: Int16 = 1,
                                  faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                                  faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard let s = w.active.record(id: id), let o = w.active.record(id: oID) else { return }
        let runs = BackgroundSprite.runs
        if runs(o, .playerShot) && o.counterA6 == 0 && s.face != nil {
            PlayerShotHits.kill(w, shot: oID, sound: false, effect: false, effects: effects, lights: &lights,
                                faceWidth: faceWidth, faceBounds: faceBounds, staleSlot: nil)
            guard let shot = w.active.record(id: oID) else { return }
            if shot.type == 1 { EnemyCommon.turnIntoStatue(w, id: id) }
        } else if runs(o, .enemyShot) && o.type == s.type && s.face != nil {
            w.player.cue(PlayerCue(call: .threeD, snd: ouchSound, priority: 1, volume: 0x100, position: s.centre))
            w.active.update(id: id) { c in
                c.hp &-= 100
                c.flash = 10
            }
            EnemyShot.kill(w, shot: oID, lights: &lights, effects: effects)
        } else if runs(o, .statue) || runs(o, .box) {
            CrawlerRoach.crush(w, id: id, other: oID)
        }
    }

    /// The test-only form (no light table).
    static func hitFloater(_ w: SpriteWorld, id: Int, other oID: Int) {
        var scratch = LightTable()
        hitFloater(w, id: id, other: oID, lights: &scratch)
    }
}
