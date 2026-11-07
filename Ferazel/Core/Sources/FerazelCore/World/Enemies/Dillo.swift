import Foundation

/// The Dillo (types 1870…1879, "armadillopine") (DL; enemies-ground §6, enemies-ground-2 §7): `.InitDilloSprite @
/// 10086120` (M l. 72276–72288, the four cache sets), `.SetupDilloSprite @ 1008622c` (M l. 72291–72378, `setup`),
/// `.ShootSpines @ 1008648c` (M l. 72381–72470, `shootSpines`), `.DilloLayEgg @ 1008678c` (M l. 72473–72485,
/// `layEgg`), `.RandomDilloAttack @ 100867fc` (M l. 72488–72537, `randomAttack`), `.HandleDilloSprite @ 1008697c` (M l.
/// 72540–72847, `handle`), `.HitDilloSprite @ 10087334` (M l. 72850–72913, `hit`), `.KillDillo @ 100875bc` (M l.
/// 72916–72937, `killDillo`), `.HitDilloTileSprite @ 1008763c` (M l. 72940–72972 — the Crawler's body,
/// `CrawlerRoach.hitTile`).
///
/// The Setup stores a Kill proc `+0x50` (`.KillDillo`), called only by the burn's end (`.HandleBurn` →
/// `EnemyCommon.killProc`); the Kill stores `+0xea = 1`. The Setup stores `+0x188 = 1` (no record write-back: a Dillo
/// always respawns at its placement, `.UpdateSprites` M l. 4959) and none of `+0x189`…`+0x18b`. A counted enemy (the
/// Setup's window test). The egg 0x753 and the spines 0x754 are EnemyShot types (`EnemyShot.spawn`), their faces the
/// boot sets (`BootFaces`). No Smite reaction of its own: the Ring's seeds are player shots, met by the armour; no
/// Effect 0x4b7 / geyser 0x5a0 arm in `.HitDilloSprite`.
///
/// Fields (`SpriteSlot`): `+0xb0` the state `subtype` (6 idle, 7 walk, 8 attack, 4 dying); `+0xb2` the attack phase
/// `subState` (0 curl, 1 hold / fire, 2 uncurl, 3 airborne); `+0x46` the face counter `phase`; `+0xa6` the timer
/// `counterA6`; `+0x14c` the walk speed / volley count `classTimer`; `+0x150` −1 / the crush 0x16 `classWord150` (no
/// Dillo reader); `+0x154` the attack mode `classWord154` (0 spines, 1 jump, 2 egg, 3 roll); `+0x15c` / `+0x160` the
/// patrol bounds `classWord15c` / `classWord160`; `+0x164` the roll speed `launchSpeed`; `+0x168` the max HP `bonusP4`;
/// `+0x1aa` the roll's spin angle `rotation`; `+0x17e` facing right `mirrored`.
public enum Dillo {
    /// The types (`+4`) and the cache sets (`.InitDilloSprite` M l. 72283–72286, `.CacheEncFaceSetFromPICT`, 100×0x50
    /// cells, one row each, flag 0): `PTR_DAT_100a0d38` 0x74e walk (6), `_DAT_100a0d34` 0x74f curl (5), `_DAT_100a0d30`
    /// 0x750 death (5), `_DAT_100a0d2c` 0x751 jump (2). The Setup marks all four (M l. 72330–72333; `CachedFaces`).
    public static let walkType: Int16 = 0x74e, curlType: Int16 = 0x74f, deathType: Int16 = 0x750, jumpType: Int16 = 0x751

    /// The snd slots (`SoundSlots`): `*_DAT_100a0358` 463 (the spines), `*_DAT_100a02e4` 498 (the egg),
    /// `*_DAT_100a03f8` 414 (the jump), `*_DAT_100a041c` 303 'metal hit', `*_DAT_100a0274` 701 'Crawler Ouch',
    /// `*_DAT_100a0270` 702 'Crawler uh oh', `*_DAT_100a026c` 703 'crawler death'.
    static let spineSound: Int16 = 463, eggSound: Int16 = 498, jumpSound: Int16 = 414, metalSound: Int16 = 303,
               ouchSound: Int16 = 701, uhOhSound: Int16 = 702, deathSound: Int16 = 703

    /// f64 `0x100a1c10` 0.5 (idle / attack vx), `0x100a1c00` 0.9 (dying vx), `0x100a1c08` 150.796447368 (the roll's
    /// vx per `+0x164`), `0x100a1c20` 0.7 (the diagonal spines).
    static let half = Double(bitPattern: 0x3fe0_0000_0000_0000)
    static let friction90 = Double(bitPattern: 0x3fec_cccc_cccc_cccd)
    static let rollFactor = Double(bitPattern: 0x4062_d97c_7f30_d173)
    static let diagonal = Double(bitPattern: 0x3fe6_6666_6666_6666)

    @inline(__always) static func h16(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }
    @inline(__always) static func face(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }

    // MARK: - Setup

    /// `.SetupDilloSprite(s)` (M l. 72291–72378) after `.InitSprite`; `+8` / `+6` (`oldPosition`) hold the spawn point.
    /// In order: `+0x84` / `+0x86` 0; layer 8; the Dillo Handle, hit, tile callbacks and Kill proc; gravity 0x122; the
    /// four sets marked; `+0xc0 = 0`; HP 1870 → 500, 1871 → 1100 with `+0xb8 = 0x1000b` (any other type none);
    /// `+0x168` = HP; `+0x188 = 1`; `+0xc ← +8`, `+0xa ← +6`; rect SetRect(0x1a, 0x17, 0x4a, 0x3a); `+0x150 = −1`; state
    /// 6, `+0xb2 = 0`, `+0x46 = 2`, `+0x14c = 0`; `+0xa6 = R(10)`; the live record's p2 0 → 150 written back; `+0x15c` /
    /// `+0x160` = `+0xc` ∓ p2 >> 1; `+0x164 = 0`; R(100) ≥ 51 → facing right (the signed-compare idiom, raw
    /// `100863f4`); `+0xc0` = the walk set's face 0 as the last Handle left the global `PTR_DAT_100a0d1c` (the caller's);
    /// the counting window; the 24.8 position. Returns the record as left.
    public static func setup(_ s: inout SpriteSlot, record p: Placement, rng: inout FastRand,
                             counting: inout EnemyCounting) -> Placement {
        s.particleOffsetY = 0
        s.particleOffsetX = 0
        s.layer = 8
        s.handler = .dillo
        s.hasHit = true                                                 // `+0x5c` = `.HitDilloSprite`
        s.hasTileHit = true                                             // `+0x1f8` = `.HitDilloTileSprite`
        s.gravity = 0x122
        s.face = nil
        if s.type == walkType {
            s.hp = 500
        } else if s.type == curlType {
            s.hp = 0x44c
            s.mode = 0x1000b
        }
        s.bonusP4 = Int32(s.hp)                                         // `+0x168` (M l. 72342)
        s.keepRecord = true                                             // `+0x188 = 1` (M l. 72343)
        s.x = s.oldPosition.x
        s.y = s.oldPosition.y
        s.hotRect = IdleSprites.Rect(top: 0x17, left: 0x1a, bottom: 0x3a, right: 0x4a)
        s.classWord150 = -1
        s.subtype = 6
        s.subState = 0
        s.phase = 2
        s.classTimer = 0
        s.counterA6 = rng.next(10)
        var record = p
        if p.p2 == 0 {                                                  // M l. 72354–72357
            record = Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: p.p1, p2: 0x96,
                               p3: p.p3, p4: p.p4, y: p.y, x: p.x)
        }
        let x = Int32(h16(s.x)), w = Int32(record.p2) >> 1
        s.classWord15c = x - w
        s.classWord160 = x + w
        s.launchSpeed = 0
        s.mirrored = 0x32 < rng.next(100)
        counting.countIfWindow(&s)                                      // M l. 72371–72374
        s.x256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.y)) << 8
        return record
    }

    // MARK: - Handle

    /// The tile callback `+0x1f8` (nil = 0): `.HitDilloTileSprite`, the Crawler's body.
    static func pass(_ s: SpriteSlot) -> TileHit? {
        guard s.hasTileHit else { return nil }
        return { solver, id, cell, kind, layer in CrawlerRoach.hitTile(solver, id: id, pos: cell, kind: kind, layer: layer) }
    }

    /// `.HandleDilloSprite(s)` (M l. 72540–72847), unless `+0xe9` or `+0x1b2`: `.StandardSpriteHandles`; by state (6
    /// `idle`, 4 `dying`, 8 `attack`, 7 `walk`; any other nothing); HP < 1 with state ≠ 4 → state 4, `+0x46 = +0xa6 =
    /// 0`, snd 703 (3D, 1, 0x100); `.ApplyGravityAndSeparateFromTiles`; the liquids (`EnemyCommon.liquids`, the Dillo
    /// row); `.StandardSpriteCleanup`.
    /// - Parameters: `faceWidth` the Cleanup's face `+6`; `faceBounds` the face rect the egg's x reads (`+0xa` /
    ///   `+0xe`).
    public static func handle(world w: SpriteWorld, id: Int, solver: TileSolver,
                              faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                              faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard let s0 = w.active.record(id: id), !s0.dead, !s0.handleSkip else { return }
        w.standardSpriteHandles(id)
        guard var s = w.active.record(id: id) else { return }
        switch s.subtype {
        case 6: idle(w, &s)
        case 4: dying(&s)
        case 8: attack(w, id: id, &s, faceBounds: faceBounds)
        case 7: walk(w, &s)
        default: break
        }
        if s.hp < 1 && s.subtype != 4 {                                 // M l. 72819–72824
            s.subtype = 4
            s.phase = 0
            s.counterA6 = 0
            w.player.cue(PlayerCue(call: .threeD, snd: deathSound, priority: 1, volume: 0x100, position: s.centre))
        }
        w.active.update(id: id) { $0 = s }
        solver.applyGravityAndSeparate(id, pass: pass(s))
        EnemyCommon.liquids(w, id: id, class: .dillo)
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
    }

    /// State 6 (M l. 72566–72609): face 0x74e[0]; `+0xa6 > 0` → − 1; at < 1: r = R(100), t = (i16)(R(16) − (i16)(HP·100
    /// / max) + 0x5c); t < r → walk: state 7, `+0x46 = 1`, face 0x74e[0], `+0xa6 = 2 + R(3)`; R(100) > 100 − t → fast
    /// (`+0x14c = 1`), else slow (`0`) and R(100) > 0x50 → `.DilloLayEgg`; the turn: `+0x160 < S.x` → facing left,
    /// else `S.x < +0x15c` → right. Else `.RandomDilloAttack`. Then vx × 0.5 (truncated).
    static func idle(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        s.face = face(walkType, 0)
        if 0 < s.counterA6 { s.counterA6 &-= 1 }
        if s.counterA6 < 1 {
            let r = Int(w.rng.next(100))
            let share = h16(Int(s.hp) * 100 / Int(s.bonusP4))           // `divw` (raw 10086a48): toward zero
            let t = h16(Int(w.rng.next(16)) - share + 0x5c)
            if t < r {
                s.subtype = 7
                s.phase = 1
                s.face = face(walkType, 0)
                s.counterA6 = w.rng.next(3) + 2
                if 100 - t < Int(w.rng.next(100)) {
                    s.classTimer = 1
                } else {
                    s.classTimer = 0
                    if 0x50 < w.rng.next(100) { layEgg(w, &s) }
                }
                let x = Int32(h16(s.x))
                if s.classWord160 < x {
                    s.mirrored = false
                } else if x < s.classWord15c {
                    s.mirrored = true
                }
            } else {
                randomAttack(w, &s)
            }
        }
        s.vx = TileSolver.fctiwz(Double(s.vx) * half)
    }

    /// State 4 (M l. 72611–72625): vx × 0.9; face 0x750[`+0x46 / 3`]; `+0x46` + 1, capped at 14; `+0xa6` + 1; at 45
    /// `+0x1a2 = 1` (the burn; `.KillDillo` at its end).
    static func dying(_ s: inout SpriteSlot) {
        s.vx = TileSolver.fctiwz(Double(s.vx) * friction90)
        s.face = face(deathType, Int(s.phase) / 3)
        s.phase &+= 1
        if 0xe < s.phase { s.phase = 0xe }
        s.counterA6 &+= 1
        if s.counterA6 == 0x2d { EnemyCommon.startBurn(&s) }
    }

    /// State 7 (M l. 72769–72818): slow (`+0x14c == 0`) face 0x74e[`+0x46 >> 1`], past 10 → the cycle's end, vx ±0x400;
    /// fast face 0x74e[`+0x46`], past 4, vx ±0x800. The cycle's end: `+0x46 = 0`, `+0xa6` − 1, outside the bounds (`S.x
    /// > +0x160` or `< +0x15c`) → 0; at 0 → state 6, `+0xa6 = 8 + R(20)`. Then `+0x46` + 1; vx by the facing.
    static func walk(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        let fast = s.classTimer != 0
        s.face = face(walkType, fast ? Int(s.phase) : Int(s.phase >> 1))
        if (fast ? 4 : 10) < s.phase {
            s.phase = 0
            s.counterA6 &-= 1
            let x = Int32(h16(s.x))
            if s.classWord160 < x || x < s.classWord15c { s.counterA6 = 0 }
            if s.counterA6 == 0 {
                s.subtype = 6
                s.counterA6 = w.rng.next(0x14) + 8
            }
        }
        s.phase &+= 1
        let v: Int32 = fast ? 0x800 : 0x400
        s.vx = s.mirrored ? v : -v
    }

    /// State 8 (M l. 72626–72768): vx × 0.5; by `+0xb2` —
    /// - 0 (curl): face 0x74f[`+0x46 >> 1`], `+0x46` + 1; past 8 → 9, `+0xb2 = 1`, `+0x14c` + 1;
    /// - 1: `+0xa6 < 16` → face 0x74f[4]; `+0xa6` − 1; at < 1: `+0x14c > 1` → the mode (`+0x154`): 0 spines (face
    ///   0x74f[3], `+0xa6 = 16`, `.ShootSpines(S, 0)`), 1 jump (`+0xa6 = 16`, face 0x751[1], `+0xb2 = 3`, vy −0xed8,
    ///   `+0xce = 0`, snd 414 pitched prio 0x14 vol 0xab at 75000 + R(4000)), 2 egg (`egg`), 3 roll (`roll`); then
    ///   `+0x14c` − 1, below 1 → `+0xb2 = 2`;
    /// - 2 (uncurl): face 0x74f[`+0x46 >> 1`], `+0x46` − 1, `+0x164 = 0`, `+0x1aa = 0`; below 0 → state 6, `+0xa6 = 6 +
    ///   R(12)` with `+0x14c == 2` (unreachable from the Handle), else `12 + R(30)`;
    /// - 3 (airborne): face 0x751[1] rising, [0] falling; vy < 0 ≤ vy + gravity (the apex) → face 0x751[1] and
    ///   `.ShootSpines(S, 1)`; on ground (`+0xce ≠ 0`) → `+0xb2 = 1`.
    static func attack(_ w: SpriteWorld, id: Int, _ s: inout SpriteSlot, faceBounds: (FaceRef) -> IdleSprites.Rect) {
        s.vx = TileSolver.fctiwz(Double(s.vx) * half)
        switch s.subState {
        case 2:
            s.face = face(curlType, Int(s.phase >> 1))
            s.phase &-= 1
            s.launchSpeed = 0
            s.rotation = 0
            if s.phase < 0 {
                s.subtype = 6
                s.counterA6 = s.classTimer == 2 ? w.rng.next(0xc) + 6 : w.rng.next(0x1e) + 0xc
            }
        case 0:
            s.face = face(curlType, Int(s.phase >> 1))
            s.phase &+= 1
            if 8 < s.phase {
                s.phase = 9
                s.subState = 1
                s.classTimer &+= 1
            }
        case 1:
            if s.counterA6 < 0x10 { s.face = face(curlType, 4) }
            s.counterA6 &-= 1
            guard s.counterA6 < 1 else { break }
            if 1 < s.classTimer {
                switch s.classWord154 {
                case 0:
                    s.face = face(curlType, 3)
                    s.counterA6 = 0x10
                    shootSpines(w, id: id, &s, extra: false)
                case 1:
                    s.counterA6 = 0x10
                    s.face = face(jumpType, 1)
                    s.subState = 3
                    s.vy = -0xed8
                    s.groundKind = 0
                    let p = Int32(w.rng.next(4000))
                    w.player.cue(PlayerCue(call: .threeDPitched, snd: jumpSound, priority: 0x14, volume: 0xab,
                                           position: s.centre, rate: p + 75000))
                case 2:
                    egg(w, id: id, &s, faceBounds: faceBounds)
                case 3:
                    roll(&s)
                default:
                    break
                }
            }
            s.classTimer &-= 1
            if s.classTimer < 1 { s.subState = 2 }
        case 3:
            s.face = face(jumpType, s.vy < 0 ? 1 : 0)
            if -1 < s.vy &+ Int32(s.gravity) && s.vy < 0 {
                s.face = face(jumpType, 1)
                shootSpines(w, id: id, &s, extra: true)
            }
            if s.groundKind != 0 { s.subState = 1 }
        default:
            break
        }
    }

    /// Mode 2 (M l. 72663–72698): x = S.x + face.right − 0x17 facing left (vx +0x200), S.x + face.left + 5 facing right
    /// (vx −0x200), the face the one shown; R(4000); snd 498 pitched (prio 0x14, vol 0x100, 63000 + R); face 0x74f[3],
    /// `+0xa6 = 16`, `+0x14c = 0`; `MTNewSprite(0x753, x, c.y − 8, 0, −1, .SetupEnemyShotSprite)` (`EnemyShot.spawn`),
    /// moved to layer S − 1; vx, vy −800; `+0xa4` 0xe0 (1870) / 0x1c0 with `+0xb8 = 0x1000b`. No free record: the
    /// stores dropped.
    static func egg(_ w: SpriteWorld, id: Int, _ s: inout SpriteSlot, faceBounds: (FaceRef) -> IdleSprites.Rect) {
        let b = s.face.map(faceBounds) ?? IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0)
        let vx: Int32 = s.mirrored ? -0x200 : 0x200
        let x = s.mirrored ? h16(s.x) + b.left + 5 : h16(s.x) + b.right - 0x17
        let y = h16(s.centre.y) - 8
        let p = Int32(w.rng.next(4000))
        w.player.cue(PlayerCue(call: .threeDPitched, snd: eggSound, priority: 0x14, volume: 0x100, position: s.centre,
                               rate: p + 63000))
        s.face = face(curlType, 3)
        s.counterA6 = 0x10
        s.classTimer = 0
        w.active.update(id: id) { $0 = s }
        let e = EnemyShot.spawn(w, type: EnemyShot.egg, x: x, y: y, layer: 0)
        s = w.active.record(id: id) ?? s
        guard let e else { return }
        w.changeLayer(id: e, layer: Int16(truncatingIfNeeded: s.layer &- 1))
        let walker = s.type == walkType
        w.active.update(id: e) { c in
            c.vx = vx
            c.vy = -800
            if walker {
                c.hp = 0xe0
            } else {
                c.hp = 0x1c0
                c.mode = 0x1000b
            }
        }
    }

    /// Mode 3, the roll (M l. 72714–72745): `+0x164 = 15`; vx = (int)(150.796447·15) = 2261, negated facing left; the
    /// spin `+0x1aa` + 15 facing left (below 360 → `+0x14c` + 1, else − 360) or − 15 facing right (below 0 → + 360, else
    /// `+0x14c` + 1) — so the caller's `+0x14c` − 1 lands once per full turn.
    static func roll(_ s: inout SpriteSlot) {
        s.launchSpeed = 0xf
        s.vx = TileSolver.fctiwz(rollFactor * Double(s.launchSpeed))
        if !s.mirrored { s.vx = 0 &- s.vx }
        var a = Int(s.rotation)
        if !s.mirrored {
            a = h16(a + Int(Int16(truncatingIfNeeded: s.launchSpeed)))
            if a < 0x168 { s.classTimer &+= 1 } else { a = h16(a - 0x168) }
        } else {
            a = h16(a - Int(Int16(truncatingIfNeeded: s.launchSpeed)))
            if a < 0 { a = h16(a + 0x168) } else { s.classTimer &+= 1 }
        }
        s.rotation = Int16(truncatingIfNeeded: a)
    }

    /// `.ShootSpines(S, extra)` (M l. 72381–72470): v 0x900 / damage 0x38 / `+0xb8` 0 for 1870, else 0xbb3 / 0xe0 /
    /// 0x1000b; snd 463 (3D, 1, 0x100, S centre); five `MTNewSprite(0x754, c + offset, 0, −1, .SetupEnemyShotSprite)`
    /// (`EnemyShot.spawn`): (−10, −8) (−v, 0) `+0x46` 0; (+10, −8) (v, 0) 4; (−7, −15) (−d, −d) 1; (+7, −15) (d, −d) 3;
    /// (0, −18) (0, −v) 2 — d = (int)(0.7·v) and −d = (int)(0.7·−v), toward zero (1612 / 2096); `extra`: (−7, −15) (−d,
    /// d) 7 and (+7, −15) (d, d) 5. Each with `+0xa4` and `+0xb8`. No free record: that spine's stores dropped.
    static func shootSpines(_ w: SpriteWorld, id: Int, _ s: inout SpriteSlot, extra: Bool) {
        let walker = s.type == walkType
        let v: Int32 = walker ? 0x900 : 0xbb3
        let damage: Int16 = walker ? 0x38 : 0xe0
        let mode: UInt32 = walker ? 0 : 0x1000b
        w.player.cue(PlayerCue(call: .threeD, snd: spineSound, priority: 1, volume: 0x100, position: s.centre))
        let neg = TileSolver.fctiwz(diagonal * Double(0 &- v)), pos = TileSolver.fctiwz(diagonal * Double(v))
        var table: [(dx: Int, dy: Int, vx: Int32, vy: Int32, phase: Int16)] = [
            (-10, -8, 0 &- v, 0, 0), (10, -8, v, 0, 4), (-7, -15, neg, neg, 1), (7, -15, pos, neg, 3), (0, -18, 0, 0 &- v, 2),
        ]
        if extra { table += [(-7, -15, neg, pos, 7), (7, -15, pos, pos, 5)] }
        let cx = h16(s.centre.x), cy = h16(s.centre.y)
        w.active.update(id: id) { $0 = s }
        for k in table {
            guard let c = EnemyShot.spawn(w, type: EnemyShot.spine, x: h16(cx + k.dx), y: h16(cy + k.dy), layer: 0)
            else { continue }
            w.active.update(id: c) { t in
                t.phase = k.phase
                t.vx = k.vx
                t.vy = k.vy
                t.hp = damage
                t.mode = mode
            }
        }
        s = w.active.record(id: id) ?? s
    }

    /// `.DilloLayEgg(S)` (M l. 72473–72485): `+0x154 = 2`, `+0xa6 = 5`, `+0x14c = 1 + R(2)`.
    static func layEgg(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        s.classWord154 = 2
        s.counterA6 = 5
        s.classTimer = Int32(w.rng.next(2)) + 1
    }

    /// `.RandomDilloAttack(S)` (M l. 72488–72537): r = R(100); state 8, `+0x46 = 0`, `+0xb2 = 0`; r ≥ 0x4c with the
    /// live record's p1 ≠ 0 → the roll: facing right = P.x > c.x (`*_DAT_1009fd94` against `+0x10`, the signed-compare
    /// idiom), `+0x154 = 3`, `+0x14c` = 1 (`+0x160 − +0x15c < 150`) or 2, + 1 facing right; else r < 0x24 → `+0x154 =
    /// 0`, `+0xa6 = 16`, `+0x14c = 1 + R(2)`; r < 0x33 → `.DilloLayEgg`; else `+0x154 = 1`, `+0xa6 = 16`, `+0x14c = 1 +
    /// R(2)`.
    static func randomAttack(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        let r = w.rng.next(100)
        s.subtype = 8
        s.phase = 0
        s.subState = 0
        let i = Int(s.recordIndex)
        let p1 = w.records.indices.contains(i) ? w.records[i].p1 : 0
        if r < 0x4c || p1 == 0 {
            if r < 0x33 {
                if r < 0x24 {
                    s.classWord154 = 0
                    s.counterA6 = 0x10
                    s.classTimer = Int32(w.rng.next(2)) + 1
                } else {
                    layEgg(w, &s)
                }
            } else {
                s.classWord154 = 1
                s.counterA6 = 0x10
                s.classTimer = Int32(w.rng.next(2)) + 1
            }
        } else {
            s.mirrored = Int16(truncatingIfNeeded: s.centre.x) < w.player.centreX
            s.classWord154 = 3
            s.classTimer = s.classWord160 &- s.classWord15c < 0x96 ? 1 : 2
            if s.mirrored { s.classTimer &+= 1 }
        }
    }

    // MARK: - hit

    /// `.HitDilloSprite(s, other)` (M l. 72850–72913). Every Handle comparison is `+0x4c ==` (`BackgroundSprite.runs`):
    /// - a player shot with `+0xa6 == 0` while HP > 0: the front test — states 6 / 7 only, the shot's centre `+0x10`
    ///   left of the Dillo's facing left or right of it facing right (strict, i16). Front: `.KillPlayerShot(o, 0, 0)`;
    ///   the shot's type 1 → `.TurnIntoStatue(s)`; else `.HurtSprite(s, o.+0xa4, (i16)(o.vx >> 1), −1000, 2, 8)` and on a
    ///   hurt `.BloodSpray(s, o, 0x28, 400, 0x96, 2)`, HP < 201 → snd 702, else HP > 0 → 701 (3D, 1, 0x100),
    ///   `.RandomDilloAttack(s)`. Not front (the Statue spell too): `.KillPlayerShot(o, 0, 1)`, snd 303 (3D, 1, 0x100)
    ///   at the shot's centre. The `.KillPlayerShot` r29 is the caller's (`.HitDilloSprite` saves r30 / r31 only, raw
    ///   `10087334..`): nil — no light changed [LOW];
    /// - a Statue or Box: the crush (`CrawlerRoach.crush`: `.PlatformBounce` 2 with the solid falling or the Dillo on
    ///   ground → HP 0, `+0x150 = 0x16`).
    /// No Effect 0x4b7 / geyser 0x5a0 arm.
    public static func hit(_ w: SpriteWorld, id: Int, other oID: Int, lights: inout LightTable, effects: Int16 = 1,
                           faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                           faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard let s = w.active.record(id: id), let o = w.active.record(id: oID) else { return }
        let runs = BackgroundSprite.runs
        if runs(o, .playerShot) && o.counterA6 == 0 && 0 < s.hp {
            let ox = Int16(truncatingIfNeeded: o.centre.x), sx = Int16(truncatingIfNeeded: s.centre.x)
            let front = (s.subtype == 7 || s.subtype == 6) && ((ox < sx && !s.mirrored) || (sx < ox && s.mirrored))
            guard front else {
                PlayerShotHits.kill(w, shot: oID, sound: false, effect: true, effects: effects, lights: &lights,
                                    faceWidth: faceWidth, faceBounds: faceBounds, staleSlot: nil)
                let c = (w.active.record(id: oID) ?? o).centre
                w.player.cue(PlayerCue(call: .threeD, snd: metalSound, priority: 1, volume: 0x100, position: c))
                return
            }
            PlayerShotHits.kill(w, shot: oID, sound: false, effect: false, effects: effects, lights: &lights,
                                faceWidth: faceWidth, faceBounds: faceBounds, staleSlot: nil)
            let shot = w.active.record(id: oID) ?? o                    // the dead shot's record, as the dump reads it
            if shot.type == 1 {
                EnemyCommon.turnIntoStatue(w, id: id)
                return
            }
            guard HurtSprite.apply(w, id: id, damage: shot.hp, dvx: Int16(truncatingIfNeeded: shot.vx >> 1), dvy: -1000,
                                   invulnerable: 2, flash: 8) else { return }
            BloodSpray.spray(w, victim: id, attacker: oID, count: 0x28, speed: 400, spread: 0x96, kind: 2)
            guard var t = w.active.record(id: id) else { return }
            if t.hp < 0xc9 {
                w.player.cue(PlayerCue(call: .threeD, snd: uhOhSound, priority: 1, volume: 0x100, position: t.centre))
            } else if 0 < t.hp {
                w.player.cue(PlayerCue(call: .threeD, snd: ouchSound, priority: 1, volume: 0x100, position: t.centre))
            }
            randomAttack(w, &t)
            w.active.update(id: id) { $0 = t }
        } else if runs(o, .statue) || runs(o, .box) {
            CrawlerRoach.crush(w, id: id, other: oID)
        }
    }

    // MARK: - Kill

    /// `.KillDillo(s)` (M l. 72916–72937): the counting Kill (`+0xe9 == 0 && +0x1b5` → live − 1, the enemies stat + 1);
    /// score + 1500 unconditionally; `+0xe9 = 1`, `+0xea = 1`.
    static func killDillo(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        w.enemies.kill(&s, globals: &w.globals, level: w.levelIndex, forGood: true)
        w.globals.score &+= 0x5dc
    }
}
