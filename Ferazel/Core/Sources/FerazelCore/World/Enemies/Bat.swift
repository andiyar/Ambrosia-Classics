import Foundation

/// The Bat class (BA; enemies-flyers §1, §3, §6, §7.1–§7.5): bats 1740…1749, the 1850 family 1850…1854, insects
/// 1860…1868 and the swarm 1869 — `.InitBatSprite @ 1007daf8` (M l. 68092–68104, the five cache sets),
/// `.SetupBatSprite @ 1007dc30` (M l. 68108–68316, `setup`), `.SetupSwarmMemberSprite @ 1007e220` (M l. 68318–68334,
/// `setupSwarmMember`), `.HandleSwarmMemberSprite @ 1007e2c8` (M l. 68337–68444, `handleSwarmMember`),
/// `.HandleBatSprite @ 1007e6b0` (M l. 68447–68905, `handle`), `.SetupInsectBodySprite @ 1007f440` (M l. 68908–68916),
/// `.HandleInsectBodySprite @ 1007f4a0` (M l. 68919–68927, `handleInsectBody`), `.HitBatSprite @ 1007f508` (M l.
/// 68930–68982, `hit`), `.HitSwarmMemberSprite @ 1007f734` (M l. 68985–69015, `hitSwarmMember`), `.KillBat @ 1007f874`
/// (M l. 69018–69042, `killBat`), `.HitBatTileSprite @ 1007f91c` (M l. 69045–69078 — the Crawler's body less its debug
/// key: `CrawlerRoach.hitTile`). The programmed path the path bats run is `ProgrammedPath` (below).
///
/// No Setup stores a Kill proc `+0x50` (the Handle calls `.KillBat` itself; the swarm members burn away to `+0xe9`),
/// any idle margin, `+0x189`, `+0x18a` or `+0x18b`. `+0x188` is stored for the path bats 0x6cd (and 0x6ce, retyped) and
/// for the whole 0x73a family; `+0xea` by `.KillBat`. The Hit routines have no Effect 0x4b7 (Smiting explosion) or
/// geyser arm — the Ring of Smiting reaches a Bat only through the seeds it plants (`Smite`, a player shot).
///
/// Fields (`SpriteSlot`): `+0xa6` the awake / animation counter `counterA6`; `+0xb0` the state `subtype` (7 turn, 8
/// thrust, 6 / 5 unreachable, 4 dying); `+0x46` the heading 0…35 `phase` (the members' face counter); `+0x14c` the
/// spitter flag `classTimer` (a member's centre x); `+0x150` −1 / the crush 0x16 `classWord150` (a member's centre y);
/// `+0x154` the spit cooldown `classWord154` (the swarm's radius, counted down by the Handle's spit tail); `+0x158` the
/// thrust `classWord158`; `+0x15c` 0 `classWord15c`; `+0x160` the 1850 family's background flag `classWord160`;
/// `+0x164` the 0x73a family's surface line `surfaceLine`; `+0x9c` the swarm block `swarm`; `+0x1d4` the insect body
/// `siblings.first`; `+0x84` / `+0x86` the always-0 pair `particleOffsetY` / `particleOffsetX` (§7.1); the path fields
/// `pathMode` … `pathHigh`.
public enum Bat {
    /// The cache sets (`.InitBatSprite` M l. 68099–68103, `.CacheEncFaceSetFromPICT`, flag 0): `PTR_DAT_100a0c90` 0x6cc
    /// (11 × 0x38×0x34), `_DAT_100a0c8c` 0x744 (9 × 0x30×0x2c; 0…7 the head, 8 the body), `_DAT_100a0c88` 0x74d (8 ×
    /// 0x18×0x16, the members), `_DAT_100a0c84` 0x73a and `_DAT_100a0c80` 0x73b (12 × 0x40×0x50 each), one a column.
    public static let batSet: Int16 = 0x6cc, insectSet: Int16 = 0x744, memberSet: Int16 = 0x74d,
                      familySet: Int16 = 0x73a, familyBackSet: Int16 = 0x73b
    /// The swarm centre type and the members' default type (p1 0).
    public static let swarm: Int16 = 0x74d, defaultMember: Int16 = 0x74c

    /// The snd slots (`SoundSlots`): `*_DAT_100a02a8` 608 'batdisturb', `*_DAT_100a02a4` 609 'bathit',
    /// `*_DAT_100a0274` 701 'Crawler Ouch', `*_DAT_100a0270` 702 'Crawler uh oh', `*_DAT_100a026c` 703 'crawler death',
    /// `*_DAT_100a031c` 480 'swarmMemberDieSound'.
    static let disturbSound: Int16 = 608, hitSound: Int16 = 609, ouchSound: Int16 = 701, uhOhSound: Int16 = 702,
               deathSound: Int16 = 703, memberSound: Int16 = 480

    /// 0.85 (f64 `0x100a1b90`): a dead member's vx factor; 2430.0 (`0x100a1b98`) its re-scatter offset.
    static let memberFriction = Double(bitPattern: 0x3feb_3333_3333_3333)

    @inline(__always) static func h16(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }
    @inline(__always) static func face(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }
    @inline(__always) static func abs32(_ v: Int) -> Int { v < 1 ? -v : v }

    /// The cells of each cache set (`.InitBatSprite`'s counts) — the out-of-range test of the PICT-151 guard.
    static func cells(_ pict: Int16) -> Int? {
        switch pict {
        case batSet: return 0xb
        case insectSet: return 9
        case memberSet: return 8
        case familySet, familyBackSet: return 0xc
        default: return nil
        }
    }

    /// `.MTNewSprite(type, x, y, layer, 0x200, setup)` as the Setup calls it for a child: the Setup closure runs inside
    /// it, then the child is inserted; returns its id (nil: no free record). The parent's stores into the child right
    /// after the call (the swarm's `+0x14c` / `+0x150`, the insect body's `+0x4c`) are made inside the closure, after
    /// the child's own Setup — nothing runs in between.
    public typealias NewChild = (_ type: Int16, _ x: Int, _ y: Int, _ layer: Int32, _ handler: SpriteHandler,
                                 _ setup: (inout SpriteSlot) -> Void) -> Int?

    // MARK: - Setup

    /// `.SetupBatSprite(s)` (M l. 68108–68316), after `.InitSprite`; `+8` / `+6` (`oldPosition`) hold the spawn point.
    /// Common head: `+0x84` / `+0x86` 0; layer 0xb; the Bat Handle, hit and tile callbacks; gravity 0; face 0;
    /// `+0xc ← +8`, `+0xa ← +6`; `+0x150 = −1`. By type —
    /// - 0x6cc…0x6d5: HP 500, rect (0xc, 0xf, 0x2b, 0x2f), the counting window, the 0x6cc set marked; 0x6ce → 0x6cd with
    ///   `+0x188 = 1`, `+0x14c = 1`, `+0xb8 = 0x1000c`, `+0x154 = R(0x50) + 0x32`; then 0x6cc `+0xa6 = 0`; 0x6cd `+0x188 =
    ///   1`, `+0xa6 = 1`, gravity 0, `.SetupProgrammedPath(s, −1, 0)`; 0x6d1 `+0xa6 = 1`; `+0x158 = 0x1e`, `+0x15c = 0`,
    ///   `+0xb0 = 7` (M l. 68279–68310);
    /// - 0x73a…0x743: the 0x73a set marked, `+0x188 = 1`, HP 100, rect (0x10, 0x1e, 0x30, 0x32); 0x73c → 0x73b as 0x6ce;
    ///   0x73a `+0xa6 = 0`; 0x73b `+0xa6 = 1`, gravity 0, the path; `+0x158 = 0x1e`, `+0x15c = 0`; record p1 < 0 → layer
    ///   8, `+0x160 = 1`, the 0x73b set marked (not counted); else `+0x160 = 0`, the counting window; `+0xb0 = 7` (M l.
    ///   68240–68277);
    /// - 0x74d (the swarm): the 0x74d set marked; `+0xc` / `+0xa` + 0x40 (the 24.8 position keeps the spawn point); the
    ///   block (`swarm`); member type = p1 (0 → 0x74c), count = p2 (0 → 8), radius `+0x154` = p3 (0 → 0x4b); HP 100, no
    ///   hit callback, rect 0; each member `MTNewSprite(type, +0xc + R(2r) − r, +0xa + R(2r) − r, layer − 1, 0x200,
    ///   .SetupSwarmMemberSprite)` (the y draw first) with `+0x14c` / `+0x150` = `+0xc` / `+0xa`; alive < 1 → `+0xe9 =
    ///   1`; rect (−r/2, −r/2, r/2, r/2); the counting window (M l. 68155–68214). Out of memory ("Out of memory creating
    ///   swarm!", `ExitToShell`) is not modelled;
    /// - 0x744…0x74c (insects): rect (6, 6, 0x2a, 0x26), the 0x744 set marked, face = its cell 3 (the caller's), HP 200,
    ///   `+0xb0 = 7`, `+0xa6 = 3`, `+0x46 = 3`, `+0xb8 = 0xb0004`, `+0x158 = 0x28`, `+0x15c = 0`, `+0x88 = 0`; the body
    ///   `MTNewSprite(type, +0xc, +0xa, layer − 1, 0x200, .SetupInsectBodySprite)` into `+0x1d4`, its `+0x4c` =
    ///   `.HandleInsectBodySprite`; the counting window (M l. 68215–68238);
    /// - any other type: the head only.
    /// Tail: `+0x14 = +8 << 8`, `+0x1c = +6 << 8`. No draw. The marks are `CachedFaces.marks`.
    /// - Parameters: `record` the live record `+0x48` names (nil = none; its p1…p3 then read 0); `newChild` makes the
    ///   swarm members and the insect body.
    public static func setup(_ s: inout SpriteSlot, record p: Placement?, rng: inout FastRand,
                             counting: inout EnemyCounting, newChild: NewChild) {
        s.particleOffsetY = 0
        s.particleOffsetX = 0
        s.layer = 0xb
        s.handler = .bat
        s.hasHit = true                                                 // `+0x5c` = `.HitBatSprite`
        s.hasTileHit = true                                             // `+0x1f8` = `.HitBatTileSprite`
        s.gravity = 0
        s.face = nil
        s.x = s.oldPosition.x
        s.y = s.oldPosition.y
        s.classWord150 = -1
        let t = s.type
        let p1 = p?.p1 ?? 0, p2 = p?.p2 ?? 0, p3 = p?.p3 ?? 0
        if (0x6cc...0x6d5).contains(t) {
            s.hp = 500
            s.hotRect = IdleSprites.Rect(top: 0xf, left: 0xc, bottom: 0x2f, right: 0x2b)
            counting.countIfWindow(&s)                                  // M l. 68282–68285
            if s.type == 0x6ce {
                s.keepRecord = true
                s.type = 0x6cd
                s.classTimer = 1
                s.mode = 0x1000c
                s.classWord154 = Int32(rng.next(0x50)) + 0x32
            }
            if s.type == 0x6cc {
                s.counterA6 = 0
            } else if s.type == 0x6cd {
                s.keepRecord = true
                s.counterA6 = 1
                s.gravity = 0
                ProgrammedPath.setup(&s, record: p)
            } else if s.type == 0x6d1 {
                s.counterA6 = 1
            }
            s.classWord158 = 0x1e
            s.classWord15c = 0
            s.subtype = 7
        } else if (0x73a...0x743).contains(t) {
            s.keepRecord = true
            s.hp = 100
            s.hotRect = IdleSprites.Rect(top: 0x1e, left: 0x10, bottom: 0x32, right: 0x30)
            if s.type == 0x73c {
                s.keepRecord = true
                s.type = 0x73b
                s.classTimer = 1
                s.mode = 0x1000c
                s.classWord154 = Int32(rng.next(0x50)) + 0x32
            }
            if s.type == 0x73a {
                s.counterA6 = 0
            } else if s.type == 0x73b {
                s.counterA6 = 1
                s.gravity = 0
                ProgrammedPath.setup(&s, record: p)
            }
            s.classWord158 = 0x1e
            s.classWord15c = 0
            if p1 < 0 {
                s.layer = 8
                s.classWord160 = 1
            } else {
                s.classWord160 = 0
                counting.countIfWindow(&s)                              // M l. 68270–68273
            }
            s.subtype = 7
        } else if t == swarm {
            s.x = h16(s.x + 0x40)
            s.y = h16(s.y + 0x40)
            let type: Int16 = p1 == 0 ? defaultMember : p1
            let count: Int16 = p2 == 0 ? 8 : p2
            let r = Int(p3 == 0 ? 0x4b : p3)
            s.classWord154 = Int32(r)
            s.swarm = SpriteSlot.SwarmBlock(members: [], alive: count, total: count)
            s.hp = 100
            s.hasHit = false                                            // `+0x5c = 0`
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0)
            let span = Int16(truncatingIfNeeded: r << 1)
            let cx = s.x, cy = s.y, layer = s.layer &- 1
            var i: Int16 = 0
            while i < count {
                let a = Int(rng.next(span))
                let b = Int(rng.next(span))
                let phase = rng.next(7)                                 // `.SetupSwarmMemberSprite`'s R(7)
                let m = newChild(type, cx + b - r, cy + a - r, layer, .swarmMember) { c in
                    setupSwarmMember(&c, phase: phase)
                    c.classTimer = Int32(cx)                            // `+0x14c` = the centre `+0xc`
                    c.classWord150 = Int32(cy)                          // `+0x150` = `+0xa`
                }
                s.swarm?.members.append(m)
                i += 1
            }
            if count < 1 { s.dead = true }                             // alive < 1 → `+0xe9 = 1` (M l. 68205–68207)
            let half = r / 2                                            // `srawi 1; addze`: toward zero
            s.hotRect = IdleSprites.Rect(top: -half, left: -half, bottom: half, right: half)
            counting.countIfWindow(&s)                                  // M l. 68210–68213
        } else if (0x744...0x74c).contains(t) {
            s.hotRect = IdleSprites.Rect(top: 6, left: 6, bottom: 0x26, right: 0x2a)
            s.face = face(insectSet, 3)                                 // `+0xc0 = *(set + 0x10)`: cell 3 (M l. 68219)
            s.hp = 200
            s.subtype = 7
            s.counterA6 = 3
            s.phase = 3
            s.mode = 0xb0004
            s.classWord158 = 0x28
            s.classWord15c = 0
            s.lightOverlay = false                                      // `+0x88 = 0`
            s.siblings.first = newChild(t, s.x, s.y, s.layer &- 1, .insectBody) { c in
                setupInsectBody(&c)
                c.handler = .insectBody                                 // `+0x4c = PTR_PTR_100a0c6c` (M l. 68233)
            }
            counting.countIfWindow(&s)                                  // M l. 68234–68237
        }
        s.x256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.y)) << 8
    }

    /// `.SetupSwarmMemberSprite(s)` (M l. 68318–68334), after `.InitSprite`: the member Handle, `+0x46 = R(7)` (drawn by
    /// the caller, `phase`), rect (0, 0, 0x18, 0x16), the member hit, HP 100, `+0x184 = 1`. No position store: the
    /// `.MTNewSprite` pixel copies stand (`SpriteWorld.newSprite`'s quirk — `+0xc` = y, `+0xa` = 0 — read by the first
    /// Handle's near-centre test and direction).
    static func setupSwarmMember(_ s: inout SpriteSlot, phase: Int16) {
        s.handler = .swarmMember
        s.phase = phase
        s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x16, right: 0x18)
        s.hasHit = true                                                 // `+0x5c` = `.HitSwarmMemberSprite`
        s.hp = 100
        s.sameHandlerExempt = true
    }

    /// `.SetupInsectBodySprite(s)` (M l. 68908–68916): `.InitSprite`, the body Handle. No callbacks, empty rect.
    static func setupInsectBody(_ s: inout SpriteSlot) {
        s.handler = .insectBody
    }

    /// The live record of `s` (`*_DAT_100a0058 + 4 + 16·(+0x48)`; nil for −1). `.KillCrate`'s 0x200 lies past the 511
    /// records: read as zeros [LOW: no shipped crate drops a Bat].
    public static func record(_ records: [Placement], index: Int16) -> Placement? {
        guard index != -1 else { return nil }
        if records.indices.contains(Int(index)) { return records[Int(index)] }
        return Placement(index: Int(index), flag: 0, byte1: 0, type: 0, p1: 0, p2: 0, p3: 0, p4: 0, y: 0, x: 0)
    }

    // MARK: - Handles

    /// The tile callback `+0x1f8` (`.HitBatTileSprite`, the Crawler's body; nil = 0).
    public static func pass(_ s: SpriteSlot) -> TileHit? {
        guard s.hasTileHit else { return nil }
        return { solver, id, cell, kind, layer in CrawlerRoach.hitTile(solver, id: id, pos: cell, kind: kind, layer: layer) }
    }

    /// The insect body copies (M l. 68478–68496 before, 68887–68903 after): types 0x744…0x74c with `+0x1d4` set — for
    /// 0x744…0x746 the body's face = the 0x744 set's cell 8; the body's `+0xa` / `+0xc` (one word), `+0x11c`, `+0x17e`
    /// and `+0x1ba` = the head's.
    static func copyToBody(_ w: SpriteWorld, _ s: SpriteSlot) {
        guard (0x744...0x74d).contains(s.type), let b = s.siblings.first else { return }
        w.active.update(id: b) { c in
            if (0x744...0x746).contains(s.type) { c.face = face(insectSet, 8) }
            c.y = s.y
            c.x = s.x
            c.waterRow = s.waterRow
            c.mirrored = s.mirrored
            c.clip.bottom = s.clip.bottom
        }
    }

    /// `.HandleBatSprite(s)` (M l. 68447–68905). P = `*_DAT_1009fd94` / `fd90`, c = the hot-rect centre `+0x10` / `+0xe`,
    /// T = (P.y − 15, P.x), d = `.FindDesiredDirectionGeneric(T, c)`:
    /// 1. the body copy (`copyToBody`); `+0xe9` or `+0x1b2` → return; `.StandardSpriteHandles`;
    /// 2. by type — the chasers 0x6cc / 0x6d1 / 0x73a / 0x744: awake (`+0xa6 > 0`): 0x6cc → 0x6d1; c.x < P.x → flip 1
    ///    and vx < −0x100 with c.x < P.x − 40 → vx + 0x48; P.x < c.x → flip 0 and vx > 0x100 with c.x > P.x + 40 → vx −
    ///    0x48. Last frame in liquid (`+0x120 ≠ 0`): vy > −800 → − 100; fully under plain water or in a liquid of kind
    ///    > 0 other than 3, with `+0x116 == 0` → `+0x116 = 0x13`, HP − 100, `+0xaa = 0x11`, snd 701 (vol 0x55). Asleep
    ///    (`+0xa6 < 1`): |c.x − P.x| < 0x9c and c.y + 0x20 < P.y < c.y + 200 → `.STPlay3DSoundRand(608, 1, 0xab)`,
    ///    `+0xa6 = 0x14`. Awake, by state: 7 — d == heading → 8, else heading + 1 when d > h by less than 18, − 1
    ///    otherwise, wrapped 0…35; 5 — heading = d; 6 — `+0x86`, `+0x84` both under 0x9c → state 7, both 0 and on to
    ///    the spit tail, else each × `+0x15c` and `+0xa6` + 1 (§7.1: the pair is always 0); 8 — d within ±2 of the
    ///    heading (also ±36) → state 8 and `FUN_1003f218(s, heading, +0x158)` unless gated (1740 family: |`+0x86`|,
    ///    |`+0x84`| > 0xb3; 1850 family > 0x4f; others |vx|, |vy| > 0x1c1), else state 6. The swarm 0x74d:
    ///    `.StandardSpriteHandles` again, `FUN_1003f218(s, .FindDesiredDirectionGeneric((P.y, P.x), (y, x)), R(6) +
    ///    0x14)`, `.EnforceMaxSpeed(400)`, `+0xb8 = 0x10009`, each member's `+0x14c` / `+0x150` = x, y and a member with
    ///    `+0xe9` dropped (alive − 1; ≤ 0 → `+0xe9 = 1`). Every other type (the path arm): `+0x8a = 0`; path mode 2 →
    ///    vy toward 0 by 0x100 (0 inside ±0x100), flip = vx > 0; else the facing of the chasers; `.HandleProgrammedPath`;
    /// 3. the spit tail: `+0x154 > 0` → − 1; `+0x14c == 1`, `+0x154 == 0` and |P.y − c.y| < 0x1e →
    ///    `MTNewSprite(0x712, c.x − 12, c.y − 7, layer + 1, −1, .SetupEnemyShotSprite)`, its vx ±0x708 by the flip, its
    ///    integer x + (i16) vx and y + (i16) the bat's vy, its vy = the bat's vy >> 2; `+0x154 = R(0x4b) + 0x3c`;
    /// 4. state 4 (dying): `dying`;
    /// 5. the animation: 0x6cc…0x6d5 — `+0xa6 > 0` → + 1, > 0x15 → 2, face 0x6cc[`+0xa6 >> 1`]; 0x744 / 0x745 — `+0xa6 >
    ///    0` → + 1, > 8 → − 8, > 8 → 8, face 0x744[`+0xa6` − 1]; 0x73a…0x743 — `+0xa6` + 1, > 0x12 → 0, face 0x73a /
    ///    0x73b (by `+0x160`)[`+0xa6 >> 1`];
    /// 6. HP < 1 → state 4; `+0x14 += vx`, `+0x1c += vy`, `.ApplyGravityAndSeparateFromTiles` (so 2·v a frame);
    ///    0x73a…0x743: `+0x11c ≠ 1` → `+0x164` = y; y < `+0x164` → y = `+0x164`, vy = 0;
    /// 7. the PICT-151 guard (an out-of-range face → `+0xa6 += 0x45`, §7.3: never fires); `.StandardSpriteCleanup`;
    ///    the body copy again.
    /// - Parameters: `lights` / `effects` reach the coins' and the spit's Setups; `faceWidth` the Cleanup's face `+6`.
    public static func handle(world w: SpriteWorld, id: Int, solver: TileSolver, lights: inout LightTable,
                              effects: Int16, faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right }) {
        guard let s0 = w.active.record(id: id) else { return }
        copyToBody(w, s0)
        guard !s0.dead, !s0.handleSkip else { return }
        w.standardSpriteHandles(id)
        guard var s = w.active.record(id: id) else { return }
        let px = Int(w.player.centreX), py = Int(w.player.centreY)
        func dir(_ c: SpriteSlot.Point) -> Int {
            BloodSpray.direction(target: (v: Int16(truncatingIfNeeded: py - 0xf), h: Int16(truncatingIfNeeded: px)),
                                 from: (v: Int16(truncatingIfNeeded: c.y), h: Int16(truncatingIfNeeded: c.x)))
        }
        func faceThePlayer(_ s: inout SpriteSlot, cx: Int) {
            if cx < px {
                s.mirrored = true
            } else if px < cx {
                s.mirrored = false
            }
        }
        let t = s.type
        let cx = h16(s.centre.x), cy = h16(s.centre.y)
        if t == 0x6cc || t == 0x6d1 || t == 0x73a || t == 0x744 {
            if 0 < s.counterA6 {
                if t == 0x6cc { s.type = 0x6d1 }
                if cx < px {
                    s.mirrored = true
                    if s.vx < -0x100 && cx < px - 0x28 { s.vx &+= 0x48 }
                } else if px < cx {
                    s.mirrored = false
                    if 0x100 < s.vx && px + 0x28 < cx { s.vx &-= 0x48 }
                }
            }
            if s.lastWater != 0 {
                if -800 < s.vy { s.vy &-= 100 }
                if ((s.lastWater == 1 && s.waterKind == 0) || (0 < s.waterKind && s.waterKind != 3))
                    && s.invulnerable == 0 {
                    s.invulnerable = 0x13
                    s.hp &-= 100
                    s.flash = 0x11
                    w.player.cue(PlayerCue(call: .threeD, snd: ouchSound, priority: 1, volume: 0x55, position: s.centre))
                }
            }
            if s.counterA6 < 1 {
                if abs32(cx - px) < 0x9c && py - cy < 200 && cy + 0x20 < py {
                    let rate = w.rng.soundRate()
                    w.player.cue(PlayerCue(call: .threeDRand, snd: disturbSound, priority: 1, volume: 0xab,
                                           position: s.centre, rate: rate))
                    s.counterA6 = 0x14
                }
            } else {
                steer(&s, dir: dir(s.centre))
            }
        } else if t == swarm {
            w.active.update(id: id) { $0 = s }
            w.standardSpriteHandles(id)
            guard let t2 = w.active.record(id: id) else { return }
            s = t2
            let d = BloodSpray.direction(target: (v: Int16(truncatingIfNeeded: py), h: Int16(truncatingIfNeeded: px)),
                                         from: (v: Int16(truncatingIfNeeded: s.y), h: Int16(truncatingIfNeeded: s.x)))
            let r = Int32(w.rng.next(6))
            PlayerShot.addDirImpulse(&s, dir: d, magnitude: r + 0x14)
            s.enforceMaxSpeed(400)
            s.mode = 0x10009
            if var block = s.swarm {
                var k = 0
                while k < Int(block.total) {
                    if k < block.members.count, let m = block.members[k] {
                        let x = Int32(h16(s.x)), y = Int32(h16(s.y))
                        w.active.update(id: m) { c in
                            c.classTimer = x
                            c.classWord150 = y
                        }
                        // A member freed by `.UpdateSprites` reads as killed [LOW: §7.5 NR 10, a centre idle while it died].
                        if w.active.record(id: m)?.dead ?? true {
                            block.members[k] = nil
                            block.alive &-= 1
                            if block.alive < 1 { s.dead = true }
                        }
                    }
                    k += 1
                }
                s.swarm = block
            }
        } else {
            s.currentApplies = false                                    // `+0x8a = 0`
            if s.pathMode == 2 {
                let vy = s.vy
                if abs32(Int(vy)) < 0x101 {
                    if vy != 0 { s.vy = 0 }
                } else {
                    s.vy &+= (vy < 0 ? -1 : 1) &* -0x100
                }
                s.mirrored = 0 < s.vx
            } else {
                faceThePlayer(&s, cx: cx)
            }
            ProgrammedPath.handle(&s)
        }
        // The spit tail (M l. 68756–68781).
        if 0 < s.classWord154 { s.classWord154 &-= 1 }
        if s.classTimer == 1 && s.classWord154 == 0 && abs32(py - cy) < 0x1e {
            w.active.update(id: id) { $0 = s }
            let spit = EnemyShot.spawn(w, type: EnemyShot.spit, x: h16(cx - 0xc), y: h16(cy - 7),
                                       layer: Int16(truncatingIfNeeded: s.layer &+ 1))
            if let spit {
                let vx: Int32 = s.mirrored ? 0x708 : -0x708
                let bvy = s.vy
                w.active.update(id: spit) { c in
                    c.vx = vx
                    c.x = h16(c.x + Int(Int16(truncatingIfNeeded: vx)))
                    c.y = h16(c.y + Int(Int16(truncatingIfNeeded: bvy)))
                    c.vy = bvy >> 2
                }
            }
            s = w.active.record(id: id) ?? s
            s.classWord154 = Int32(w.rng.next(0x4b)) + 0x3c
        }
        if s.subtype == 4 {
            w.active.update(id: id) { $0 = s }
            dying(w, id: id, lights: &lights, effects: effects)
            guard let t2 = w.active.record(id: id) else { return }
            s = t2
        }
        // The animation (M l. 68826–68866).
        if (0x6cc...0x6d5).contains(s.type) {
            if 0 < s.counterA6 { s.counterA6 &+= 1 }
            if 0x15 < s.counterA6 { s.counterA6 = 2 }
            s.face = face(batSet, Int(s.counterA6 >> 1))
        }
        if !(0x73a...0x743).contains(s.type) {
            if s.type == 0x744 || s.type == 0x745 {
                if 0 < s.counterA6 { s.counterA6 &+= 1 }
                if 8 < s.counterA6 { s.counterA6 &-= 8 }
                if 8 < s.counterA6 { s.counterA6 = 8 }
                s.face = face(insectSet, Int(s.counterA6) - 1)          // `*(set + 4·a6)`: no `+4` — cell a6 − 1
            }
        } else {
            s.counterA6 &+= 1
            if 0x12 < s.counterA6 { s.counterA6 = 0 }
            s.face = face(s.classWord160 == 0 ? familySet : familyBackSet, Int(s.counterA6 >> 1))
        }
        if s.hp < 1 { s.subtype = 4 }
        s.x256 &+= s.vx
        s.y256 &+= s.vy
        w.active.update(id: id) { $0 = s }
        if let t2 = w.active.record(id: id) { solver.applyGravityAndSeparate(id, pass: pass(t2)) }
        if let t2 = w.active.record(id: id), (0x73a...0x743).contains(t2.type) {
            w.active.update(id: id) { c in
                if c.waterRow != 1 { c.surfaceLine = Int32(h16(c.y)) }
                if Int32(h16(c.y)) < c.surfaceLine {
                    c.y = h16(Int(c.surfaceLine))
                    c.vy = 0
                }
            }
        }
        if let t2 = w.active.record(id: id), let f = t2.face, let n = cells(f.pict), n <= f.index {
            w.active.update(id: id) { $0.counterA6 &+= 0x45 }           // PICT 151 (M l. 68882–68884; §7.3)
        }
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
        if let t2 = w.active.record(id: id) { copyToBody(w, t2) }
    }

    /// The awake chasers' states (M l. 68555–68683): 7 turn, 8 thrust, 5 aim (no writer), 6 the `+0x84` / `+0x86`
    /// rescale (always drops to 7, §7.1). `dir` is d.
    static func steer(_ s: inout SpriteSlot, dir d: Int) {
        let state = s.subtype
        if state == 7 {
            let h = Int(s.phase)
            if d == h {
                s.subtype = 8
            } else {
                if h < d && d - h < 0x12 {
                    s.phase &+= 1
                } else {
                    s.phase &-= 1
                }
                if s.phase < 0x24 {
                    if s.phase < 0 { s.phase = 0x23 }
                } else {
                    s.phase = 0
                }
            }
        } else if state < 7 {
            if state == 5 {
                s.phase = Int16(truncatingIfNeeded: d)
            } else if 4 < state {
                if abs32(Int(s.particleOffsetX)) < 0x9c && abs32(Int(s.particleOffsetY)) < 0x9c {
                    s.subtype = 7
                    s.particleOffsetY = 0
                    s.particleOffsetX = 0
                    return
                }
                s.particleOffsetX = s.particleOffsetX &* Int16(truncatingIfNeeded: s.classWord15c)
                s.particleOffsetY = s.particleOffsetY &* Int16(truncatingIfNeeded: s.classWord15c)
                s.counterA6 &+= 1
            }
        } else if state < 9 {
            let h = Int(s.phase)
            if 2 < abs32(d - h) && 2 < abs32(d + 0x24 - h) && 2 < abs32(d - 0x24 - h) {
                s.subtype = 6
                return
            }
            s.subtype = 8
            let gate: Bool
            if (0x6cc...0x6d5).contains(s.type) {
                gate = 0xb3 < abs32(Int(s.particleOffsetX)) && 0xb3 < abs32(Int(s.particleOffsetY))
            } else if (0x73a...0x743).contains(s.type) {
                gate = 0x4f < abs32(Int(s.particleOffsetX)) && 0x4f < abs32(Int(s.particleOffsetY))
            } else {
                gate = 0x1c1 < abs32(Int(s.vx)) && 0x1c1 < abs32(Int(s.vy))
            }
            if !gate { PlayerShot.addDirImpulse(&s, dir: h, magnitude: s.classWord158) }
        }
    }

    /// The dying state 4 (M l. 68782–68825): R(3) first; N = 0xaa with prefs+6 Effects == 1, else 100; `+0x5c = 0`; snd
    /// 703 (vol 0x100); face 0; `.KillBat`; score + 500; R(3) + 1 coins `MTNewSprite(0x516, c.x − 4, c.y − 4, 2, −1,
    /// .SetupBonusSprite)` with vy −0x578 − R(0x640) then vx R(1000) − 500 (no free record: the stores dropped, the draws
    /// made); N particles `NewParticle(2, 0x78, (c.y + R − 3, c.x + R − 3), 4, R(0x28a) − 0x145, −0x352 − R(700) −
    /// R(200), 0, 1)` (the h offset R(6) first, then the v offset, R(700), R(200), R(0x28a)); N >> 3 more with R(900),
    /// R(300), R(900) − 0x1c2. The Handle then runs on (the animation, the integration, the Cleanup) — the next frame
    /// returns at `+0xe9`.
    static func dying(_ w: SpriteWorld, id: Int, lights: inout LightTable, effects: Int16) {
        guard var s = w.active.record(id: id) else { return }
        let n = w.rng.next(3)
        let count: Int16 = effects == 1 ? 0xaa : 100
        s.hasHit = false
        w.player.cue(PlayerCue(call: .threeD, snd: deathSound, priority: 1, volume: 0x100, position: s.centre))
        s.face = nil
        w.active.update(id: id) { $0 = s }
        killBat(w, id: id)
        w.globals.score &+= 500
        guard let k = w.active.record(id: id) else { return }
        s = k
        let cx = h16(s.centre.x), cy = h16(s.centre.y)
        let pl = w.playerID.flatMap { w.active.record(id: $0) }?.layer ?? 0
        var i: Int16 = 0
        while i < Int16(truncatingIfNeeded: n &+ 1) {
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
            i += 1
        }
        func blood(_ a: Int16, _ b: Int16, _ c: Int16, _ cOff: Int) {
            let hOff = Int(w.rng.next(6))
            let vOff = Int(w.rng.next(6))
            let ra = Int(w.rng.next(a))
            let rb = Int(w.rng.next(b))
            let rc = Int(w.rng.next(c))
            w.particles.newParticle(kind: 2, gravity: 0x78, v: h16(cy + vOff - 3), h: h16(cx + hOff - 3), shape: 4,
                                    vx: rc - cOff, vy: -0x352 - ra - rb, delay: 0, mode: 1)
        }
        for _ in 0..<Int(count) { blood(700, 200, 0x28a, 0x145) }
        for _ in 0..<Int(count >> 3) { blood(900, 300, 900, 0x1c2) }
    }

    /// `.KillBat(s)` (M l. 69018–69042): the counting Kill (`EnemyCounting.kill`: `+0xe9 == 0` and `+0x1b5` → live − 1,
    /// the enemies stat + 1); score + 100; `+0xe9 = +0xea = 1`; `+0x1d4` set → `.KillBat` on it (the insect body: +100).
    static func killBat(_ w: SpriteWorld, id: Int) {
        guard var s = w.active.record(id: id) else { return }
        w.enemies.kill(&s, globals: &w.globals, level: w.levelIndex, forGood: true)
        w.globals.score &+= 100
        w.active.update(id: id) { $0 = s }
        if let b = s.siblings.first { killBat(w, id: b) }
    }

    /// `.HandleSwarmMemberSprite(s)` (M l. 68337–68444) — no `+0xe9` or `+0x1b2` test. C = (`+0x14c`, `+0x150`):
    /// `.StandardSpriteHandles`; the position made relative to C (pixel and 24.8); `+0x46` + 1 (past 7 → 0), face
    /// 0x74d[`+0x46`]; dead (HP < 1): vx = (int)(vx · 0.85), vy = max(vy, 0) + 0x32, the tile callback `.HitBatTileSprite`
    /// (never called — the member runs no tile routine); alive: `FUN_1003f218(s, .FindDesiredDirectionGeneric((0, 0), (y +
    /// 12, x + 12)), R(0x96) + 0x172)` (the target the word at `0x100a1b80`, 0), `.EnforceMaxSpeed(0xa8c)`; |x|, |y| < 8
    /// and |vx|, |vy| < 0x578 → vx = R(0x12fc) − 2430, vy = R(0x12fc) − 2430; then vx + R(400) − 200, vy + R(400) − 200;
    /// `+0x14 += vx`, `+0x1c += vy` (once), the pixel copies from them, C added back; flip = x + 12 < P.x; HP < 1 with
    /// `+0x1a2 < 1` → `+0x1a2 = 1`, vy = 0; `.StandardSpriteCleanup` (the burn-away, `Burn`).
    public static func handleSwarmMember(world w: SpriteWorld, id: Int,
                                         faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right }) {
        guard w.active.record(id: id) != nil else { return }
        w.standardSpriteHandles(id)
        guard var s = w.active.record(id: id) else { return }
        let ccx = s.classTimer, ccy = s.classWord150
        s.x = h16(s.x - Int(Int16(truncatingIfNeeded: ccx)))
        s.y = h16(s.y - Int(Int16(truncatingIfNeeded: ccy)))
        s.x256 &+= ccx &* -0x100
        s.y256 &+= ccy &* -0x100
        let from = (v: Int16(truncatingIfNeeded: s.y + 0xc), h: Int16(truncatingIfNeeded: s.x + 0xc))
        s.phase &+= 1
        if 7 < s.phase { s.phase = 0 }
        s.face = face(memberSet, Int(s.phase))
        if s.hp < 1 {
            s.vx = TileSolver.fctiwz(Double(s.vx) * memberFriction)
            if s.vy < 0 { s.vy = 0 }
            s.vy &+= 0x32
            s.hasTileHit = true                                         // `+0x1f8 = .HitBatTileSprite`
        } else {
            let d = BloodSpray.direction(target: (v: 0, h: 0), from: from)
            let r = Int32(w.rng.next(0x96))
            PlayerShot.addDirImpulse(&s, dir: d, magnitude: r + 0x172)
            s.enforceMaxSpeed(0xa8c)
            if abs32(h16(s.x)) < 8 && abs32(h16(s.y)) < 8 && abs32(Int(s.vx)) < 0x578 && abs32(Int(s.vy)) < 0x578 {
                s.vx = Int32(w.rng.next(0x12fc)) - 2430
                s.vy = Int32(w.rng.next(0x12fc)) - 2430
            }
            s.vx = Int32(w.rng.next(400)) &+ s.vx &- 200
            s.vy = Int32(w.rng.next(400)) &+ s.vy &- 200
        }
        let px = Int(w.player.centreX)
        s.x256 &+= s.vx
        s.y256 &+= s.vy
        s.x = h16(Int(s.x256 >> 8))
        s.y = h16(Int(s.y256 >> 8))
        s.x = h16(s.x + Int(Int16(truncatingIfNeeded: ccx)))
        s.y = h16(s.y + Int(Int16(truncatingIfNeeded: ccy)))
        s.x256 &+= ccx &* 0x100
        s.y256 &+= ccy &* 0x100
        s.mirrored = h16(s.x) + 0xc < px
        if s.hp < 1 && s.burnRow < 1 {
            s.burnRow = 1
            s.vy = 0
        }
        w.active.update(id: id) { $0 = s }
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
    }

    /// `.HandleInsectBodySprite(s)` (M l. 68919–68927): `.StandardSpriteHandles`, `.StandardSpriteCleanup`. Its place and
    /// face are the head's copies (`copyToBody`).
    public static func handleInsectBody(world w: SpriteWorld, id: Int,
                                        faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right }) {
        w.standardSpriteHandles(id)
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
    }

    // MARK: - hits

    /// `.HitBatSprite(s, other)` (M l. 68930–68982), by the other's `+0x4c`:
    /// - a player shot with `+0xa6 == 0`: `.KillPlayerShot(o, 0, 0)` (its stale r29 is `.MTCollideSprites`' 360, `lha
    ///   r29,0x1c(r3)` raw `100326e8` — a slot outside 0…199, no light changed); a shot of type 1 → `.TurnIntoStatue(s)`;
    ///   else `.HurtSprite(s, o.+0xa4, (i16)(o.vx >> 3), (i16)(o.vy >> 3), 2, 8)` and on a hurt:
    ///   `.STPlay3DSoundRand(609, 1, 0xab)`, `+0xa6 < 2 → 0x15` (wakes a sleeper, §7.3), HP > 0 → `.BloodSpray(s, o,
    ///   0x28, 400, 0x96, 2)`, HP < 0xc9 → snd 702, else HP > 0 → snd 701 (vol 0x100);
    /// - a Statue or a Box: the crush (`CrawlerRoach.crush`: `.PlatformBounce` 2 with the solid falling or the bat on
    ///   ground → HP 0, `+0x150 = 0x16`, which no Bat routine reads).
    public static func hit(_ w: SpriteWorld, id: Int, other oID: Int, lights: inout LightTable, effects: Int16 = 1,
                           faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                           faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard w.active.record(id: id) != nil, let o = w.active.record(id: oID) else { return }
        let runs = BackgroundSprite.runs
        if runs(o, .playerShot) && o.counterA6 == 0 {
            PlayerShotHits.kill(w, shot: oID, sound: false, effect: false, effects: effects, lights: &lights,
                                faceWidth: faceWidth, faceBounds: faceBounds, staleSlot: nil)
            guard let shot = w.active.record(id: oID) else { return }
            if shot.type == 1 {
                EnemyCommon.turnIntoStatue(w, id: id)
            } else if HurtSprite.apply(w, id: id, damage: shot.hp, dvx: Int16(truncatingIfNeeded: shot.vx >> 3),
                                       dvy: Int16(truncatingIfNeeded: shot.vy >> 3), invulnerable: 2, flash: 8) {
                guard let t = w.active.record(id: id) else { return }
                let rate = w.rng.soundRate()
                w.player.cue(PlayerCue(call: .threeDRand, snd: hitSound, priority: 1, volume: 0xab, position: t.centre,
                                       rate: rate))
                if t.counterA6 < 2 { w.active.update(id: id) { $0.counterA6 = 0x15 } }
                if 0 < t.hp {
                    BloodSpray.spray(w, victim: id, attacker: oID, count: 0x28, speed: 400, spread: 0x96, kind: 2)
                }
                guard let u = w.active.record(id: id) else { return }
                if u.hp < 0xc9 {
                    w.player.cue(PlayerCue(call: .threeD, snd: uhOhSound, priority: 1, volume: 0x100, position: u.centre))
                } else if 0 < u.hp {
                    w.player.cue(PlayerCue(call: .threeD, snd: ouchSound, priority: 1, volume: 0x100, position: u.centre))
                }
            }
        } else if runs(o, .statue) || runs(o, .box) {
            CrawlerRoach.crush(w, id: id, other: oID)
        }
    }

    /// `.HitSwarmMemberSprite(s, other)` (M l. 68985–69015): the other's type ≠ 0x74d and a player shot (no `+0xa6`
    /// test): `.KillPlayerShot(o, 0, 0)`; type 1 → `.TurnIntoStatue(s)`; else `.HurtSprite(s, o.+0xa4, (i16)(o.vx >> 3),
    /// (i16)(o.vy >> 3), 2, 8)` and on a hurt: HP > 0 → `.BloodSpray(s, o, 0x28, 400, 0x96, 2)`; then
    /// `.STPlay3DSoundPitched(480, 1, 0xab, +0xe, R(20000) + 58000)`.
    public static func hitSwarmMember(_ w: SpriteWorld, id: Int, other oID: Int, lights: inout LightTable,
                                      effects: Int16 = 1,
                                      faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                                      faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard w.active.record(id: id) != nil, let o = w.active.record(id: oID) else { return }
        guard o.type != swarm, BackgroundSprite.runs(o, .playerShot) else { return }
        PlayerShotHits.kill(w, shot: oID, sound: false, effect: false, effects: effects, lights: &lights,
                            faceWidth: faceWidth, faceBounds: faceBounds, staleSlot: nil)
        guard let shot = w.active.record(id: oID) else { return }
        if shot.type == 1 {
            EnemyCommon.turnIntoStatue(w, id: id)
        } else if HurtSprite.apply(w, id: id, damage: shot.hp, dvx: Int16(truncatingIfNeeded: shot.vx >> 3),
                                   dvy: Int16(truncatingIfNeeded: shot.vy >> 3), invulnerable: 2, flash: 8) {
            if let t = w.active.record(id: id), 0 < t.hp {
                BloodSpray.spray(w, victim: id, attacker: oID, count: 0x28, speed: 400, spread: 0x96, kind: 2)
            }
            let r = Int32(w.rng.next(20000))
            let pos = w.active.record(id: id)?.centre
            w.player.cue(PlayerCue(call: .threeDPitched, snd: memberSound, priority: 1, volume: 0xab, position: pos,
                                   rate: r + 58000))
        }
    }
}

/// The programmed path (physics §8.5): `.SetupProgrammedPath @ 10044c58` (M l. 39288–39381) and `.HandleProgrammedPath
/// @ 10044fe8` (M l. 39384–39468), as the path bats run them (BA). Modes 1 (vertical) and 2 (horizontal) shuttle
/// between two 24.8 bounds; 3 is stores only (its Handle has no arm); 10 / 11 (`.MakeRadial`, `.UpdateRadialPos`,
/// `.MakeRadiusSprites`) are refused at the Setups that would reach them (no Bat places them).
public enum ProgrammedPath {
    /// `.SetupProgrammedPath(s, −1, 0)` (M l. 39288–39381) — `record` the live record of `+0x48` (nil = −1): mode
    /// `+0xf0` = |p1| (100…199 → − 100, the radial "no radius" flag), `+0xfc` = p3; `+0xf8 = 1`; then mode 3: rect (7,
    /// 0, 0x46, 0x1e), `+0x19e = 0x50`, gravity 0x15e, `+0x13a = 0x2d`, `+0x138 = 0x3c`, `+0xf8 = 0`; mode 1: (with a
    /// record) `+0x100 = +0x1c + 8·p3`, `+0x104 = +0x1c + 256·p2 − 8·p3`, vy = `+0xfc`, vx = 0, `+0x13a = 0`; mode 2:
    /// the same on `+0x14`, vx = `+0xfc`, vy = 0; modes 10 / 11 (with a record): `+0xf8 = 0` // later: Phase 6 —
    /// `.MakeRadial` and `.MakeRadiusSprites` (no Bat or Gremlin places them; the Setups refuse them).
    public static func setup(_ s: inout SpriteSlot, record p: Placement?) {
        if let p {
            s.pathMode = Int32(p.p1 < 1 ? -p.p1 : p.p1)
            if 99 < s.pathMode && s.pathMode < 200 { s.pathMode -= 100 }
            s.pathSpeed = Int32(p.p3)
        }
        s.pathDirection = 1
        let mode = s.pathMode
        if mode == 3 {
            s.hotRect = IdleSprites.Rect(top: 0, left: 7, bottom: 0x1e, right: 0x46)
            s.buoyancy = 0x50
            s.gravity = 0x15e
            s.sag = 0x2d
            s.pushMass = 0x3c
            s.pathDirection = 0
        } else if mode < 3 {
            if mode == 1 {
                if let p {
                    s.pathLow = s.y256 &+ s.pathSpeed &* 8
                    s.pathHigh = s.y256 &+ Int32(p.p2) &* 0x100 &+ s.pathSpeed &* -8
                }
                s.vy = s.pathSpeed
                s.vx = 0
                s.sag = 0
            } else if 0 < mode {
                if let p {
                    s.pathLow = s.x256 &+ s.pathSpeed &* 8
                    s.pathHigh = s.x256 &+ Int32(p.p2) &* 0x100 &+ s.pathSpeed &* -8
                }
                s.vx = s.pathSpeed
                s.vy = 0
            }
        } else if mode < 0xc && 9 < mode && p != nil {
            s.pathDirection = 0
        }
    }

    /// `.HandleProgrammedPath(s)` (M l. 39384–39468): mode 2 — direction 1: past `+0x104` (`+0x104 < +0x14`) → −1, else
    /// vx + `+0xfc >> 4` while below `+0xfc`, capped at `+0xfc`; direction ≠ 1: before `+0x100` → 1, else vx − `+0xfc
    /// >> 4` while above −`+0xfc`, floored at −`+0xfc`; then `+0x194 = 0`. Mode 1 the same on `+0x1c` / vy. Modes 10 /
    /// 11 // later: Phase 6 (`.UpdateRadialPos`, `.UpdateRadiusSprites`; refused at Setup). Any other mode: nothing.
    public static func handle(_ s: inout SpriteSlot) {
        let mode = s.pathMode
        func run(_ pos: Int32, _ v: inout Int32) {
            if s.pathDirection == 1 {
                if s.pathHigh < pos {
                    s.pathDirection = -1
                } else {
                    if v < s.pathSpeed { v &+= s.pathSpeed >> 4 }
                    if s.pathSpeed < v { v = s.pathSpeed }
                }
            } else if pos < s.pathLow {
                s.pathDirection = 1
            } else {
                if 0 &- s.pathSpeed < v { v &-= s.pathSpeed >> 4 }
                if v < 0 &- s.pathSpeed { v = 0 &- s.pathSpeed }
            }
            s.jumpBonus = 0
        }
        if mode == 2 {
            var v = s.vx
            run(s.x256, &v)
            s.vx = v
        } else if mode == 1 {
            var v = s.vy
            run(s.y256, &v)
            s.vy = v
        }
    }
}
