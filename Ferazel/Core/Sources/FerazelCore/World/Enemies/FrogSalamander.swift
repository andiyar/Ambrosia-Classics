import Foundation

/// The Frog (types 1800…1809) and the Salamander (1810…1819) (FR; enemies-water-cave §0–§2, §5–§7):
/// `.InitFrogSprite @ 10081df4` (M l. 70111–70118, the cache set 0x708), `.STPlay3DSoundRandFrog @ 10081e68` (M l.
/// 70121–70136, `playRandFrog`), `.SetupFrogSprite @ 10081f14` (M l. 70137–70220, `setupFrog`), `.HandleFrogSprite @
/// 1008214c` (M l. 70223–70459, `handleFrog`), `.HitFrogSprite @ 100828cc` (M l. 70462–70560, `hitFrog`), `.KillFrog
/// @ 10082c14` (M l. 70556–70602, `killFrog`), `.HitFrogTileSprite @ 10082d04` (M l. 70604–70640, `hitFrogTile`);
/// `.InitSalamanderSprite @ 10082ea8` (M l. 70642–70652, the cache set 0x712), `.SetupSalamanderSprite @ 10082f20` (M
/// l. 70654–70703, `setupSalamander`), `.HandleSalamanderSprite @ 10083074` (M l. 70705–70857, `handleSalamander`),
/// `.HitSalamanderSprite @ 1008350c` (M l. 70859–70911, `hitSalamander`), `.KillSalamander @ 10083724` (M l.
/// 70913–70937, `killSalamander`), `.HitSalamanderTileSprite @ 100837b8` (M l. 70939–70980, `hitSalamanderTile`).
///
/// Both Setups store a Kill proc `+0x50` (`.KillFrog` / `.KillSalamander`), called only by the burn's end
/// (`.HandleBurn` → `EnemyCommon.killProc`). Neither class stores `+0x188`…`+0x18b`; both Kills store `+0xea = 1`.
/// Both are counted enemies (the Setups' window test). The spit 0x709 and the fireball 0x712 are EnemyShot types
/// (`EnemyShot.spawn`), their faces the enemy-shot boot sets 0x454…0x457.
///
/// Both Handles test the water contact `+0x11c` right after `.StandardSpriteHandles`, which has just zeroed it (§0.1):
/// their water blocks are transcribed as written and are dead (§7.4) — no lava damage, no healing, no buoyancy.
///
/// Fields (`SpriteSlot`): `+0xb0` the state `subtype` (Frog 0xb idle, 9 crouch, 10 airborne, 2 spit, 4 dying;
/// Salamander 0xc idle, 10 leap, 2 spit, 0xb hop, 4 dying); `+0x46` the face counter `phase`; `+0x14c` the decision
/// delay `classTimer`; `+0x150` −1 / the crush 0x16 `classWord150` (never read for these classes, §7.2); `+0x154` the
/// Frog's hop chain `classWord154`; `+0x158` the Frog's launch vx `classWord158`; `+0x15c` the Frog's p1 variant
/// `classWord15c`; `+0xf0` the Frog's voice pitch `voicePitch`; `+0xa6` the Salamander's write-only 21 `counterA6`
/// (§7.1); `+0x8e` the Frog's burn particle kind `burnStyle`.
public enum FrogSalamander {
    /// The types (`+4`).
    public static let frog: Int16 = 0x708, salamander: Int16 = 0x712

    /// The cache sets (`.CacheEncFaceSetFromPICT`, flag 0): `PTR_DAT_100a0cd0` 0x708 (8 × 0x78×100, one row; M l.
    /// 70116) and `_DAT_100a0ce0` 0x712 (9 × 0x50×100, one row; M l. 70649). Each Setup marks its set (`slot[1] = 1`,
    /// M l. 70211 / 70680; `CachedFaces`).
    public static let frogSet: Int16 = 0x708, salamanderSet: Int16 = 0x712

    /// The snd slots (`SoundSlots`): `*_DAT_100a0294` 613 frogjump, `*_DAT_100a0290` 614 froghit, `*_DAT_100a028c` 615
    /// frogdie, `*_DAT_100a0274` 701 'Crawler Ouch', `*_DAT_100a0270` 702 'Crawler uh oh'.
    static let jumpSound: Int16 = 613, hitSound: Int16 = 614, dieSound: Int16 = 615, ouchSound: Int16 = 701,
               uhOhSound: Int16 = 702

    /// 0.9 (f64 `0x100a1bd0`): the dying Frog's vx factor; 0.7 (`0x100a1bd8`): the far launch's factor.
    static let friction90 = Double(bitPattern: 0x3fec_cccc_cccc_cccd)
    static let far70 = Double(bitPattern: 0x3fe6_6666_6666_6666)

    @inline(__always) static func h16(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }
    @inline(__always) static func face(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }
    @inline(__always) static func abs32(_ v: Int) -> Int { v < 1 ? -v : v }

    /// `.STPlay3DSoundRandFrog(s, snd, prio, vol, pos) @ 10081e68` (M l. 70121–70136): `FastRand(10000)` drawn at the
    /// call (sound on or off), then `.STPlay3DSoundPitched` at `+0xf0 + R − 5000`.
    static func playRandFrog(_ w: SpriteWorld, _ s: SpriteSlot, snd: Int16, priority: Int16, volume: Int16) {
        let r = Int32(w.rng.next(10000))
        w.player.cue(PlayerCue(call: .threeDPitched, snd: snd, priority: priority, volume: volume, position: s.centre,
                               rate: s.voicePitch &+ r &- 5000))
    }

    // MARK: - Setup

    /// `.SetupFrogSprite(s)` (M l. 70137–70219) after `.InitSprite`; `+8` / `+6` (`oldPosition`) hold the spawn point.
    /// In order: `+0x84` / `+0x86` 0; layer 0xb; the Frog Handle, hit, tile callbacks and Kill proc; gravity 0; face 0;
    /// HP 500; `+0xb0 = 0xb`; `+0x14c = −0x14 − R(0x1e)`; `+0xc ← +8`, `+0xa ← +6`; rect SetRect(0xb, 0x14, 0x48,
    /// 0x49); `+0x150 = −1`; `+0xa6 = 0`; gravity 0x8c; `+0x15c` = the live record's p1; `+0xf0 = R(0x5fff)·2 +
    /// 0xbfff`; by p1 (HP, `+0xb8`): 0 (0x15e, 0), 1 (500, 0x1000c), 2 (0x15e, 0x10017), 3 (0x5dc, 0x1000f), 4 (1000,
    /// 0x1000b), any other none; hdr+0x26cd ≠ 0 (`freezing`) → `+0x8e = 1`; the set 0x708 marked and `+0xc0` = its
    /// face 0 (the caller's); the counting window; the 24.8 position from `+8` / `+6`. No save flag.
    public static func setupFrog(_ s: inout SpriteSlot, record p: Placement, freezing: Bool, rng: inout FastRand,
                                 counting: inout EnemyCounting) {
        s.particleOffsetY = 0
        s.particleOffsetX = 0
        s.layer = 0xb
        s.handler = .frog
        s.hasHit = true                                                 // `+0x5c` = `.HitFrogSprite`
        s.hasTileHit = true                                             // `+0x1f8` = `.HitFrogTileSprite`
        s.gravity = 0
        s.face = nil
        s.hp = 500
        s.subtype = 0xb
        s.classTimer = -0x14 - Int32(rng.next(0x1e))
        s.x = s.oldPosition.x
        s.y = s.oldPosition.y
        s.hotRect = IdleSprites.Rect(top: 0x14, left: 0xb, bottom: 0x49, right: 0x48)
        s.classWord150 = -1
        s.counterA6 = 0
        s.gravity = 0x8c
        s.classWord15c = Int32(p.p1)
        s.voicePitch = Int32(rng.next(0x5fff)) * 2 + 0xbfff
        switch p.p1 {
        case 0: s.hp = 0x15e; s.mode = 0
        case 1: s.hp = 500; s.mode = 0x1000c
        case 2: s.hp = 0x15e; s.mode = 0x10017
        case 3: s.hp = 0x5dc; s.mode = 0x1000f
        case 4: s.hp = 1000; s.mode = 0x1000b
        default: break
        }
        if freezing { s.burnStyle = true }                              // `+0x8e = 1` (M l. 70207–70208)
        counting.countIfWindow(&s)                                      // M l. 70212–70215
        s.x256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.y)) << 8
    }

    /// `.SetupSalamanderSprite(s)` (M l. 70654–70703) after `.InitSprite`, in order: `+0x84` / `+0x86` 0; layer 0xb; the
    /// Salamander Handle, hit and tile callbacks; gravity 0; the set 0x712 marked; face 0 (none until the first
    /// Handle); HP 500; `+0xb0 = 0xc`; `+0x14c = −0x14 − R(0x1e)`; `+0xc ← +8`, `+0xa ← +6`; rect SetRect(0xe, 0x14,
    /// 0x42, 0x49); `+0x150 = −1`; `+0xa6 = 0`; gravity 0x8c; the Kill proc; the counting window; the 24.8 position.
    /// No record read, no save flag.
    public static func setupSalamander(_ s: inout SpriteSlot, rng: inout FastRand, counting: inout EnemyCounting) {
        s.particleOffsetY = 0
        s.particleOffsetX = 0
        s.layer = 0xb
        s.handler = .salamander
        s.hasHit = true                                                 // `+0x5c` = `.HitSalamanderSprite`
        s.hasTileHit = true                                             // `+0x1f8` = `.HitSalamanderTileSprite`
        s.gravity = 0
        s.face = nil
        s.hp = 500
        s.subtype = 0xc
        s.classTimer = -0x14 - Int32(rng.next(0x1e))
        s.x = s.oldPosition.x
        s.y = s.oldPosition.y
        s.hotRect = IdleSprites.Rect(top: 0x14, left: 0xe, bottom: 0x49, right: 0x42)
        s.classWord150 = -1
        s.counterA6 = 0
        s.gravity = 0x8c
        counting.countIfWindow(&s)                                      // M l. 70692–70698
        s.x256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.y)) << 8
    }

    // MARK: - the Frog's Handle

    /// The Frog's tile callback `+0x1f8` (nil = 0).
    static func passFrog(_ s: SpriteSlot) -> TileHit? {
        guard s.hasTileHit else { return nil }
        return { solver, id, cell, kind, layer in hitFrogTile(solver, id: id, pos: cell, kind: kind, layer: layer) }
    }

    /// `.HandleFrogSprite(s)` (M l. 70223–70459), unless `+0xe9` or `+0x1b2`. P = `*_DAT_1009fd94` / `fd90` (the
    /// player's centre), c = the hot-rect centre `+0x10` / `+0xe` as it stands at each read:
    /// 1. `.StandardSpriteHandles`; the water block (dead: `+0x11c` was just zeroed) — `+0x11c ≠ 0`: vy > −800 → vy −=
    ///    100; (`+0x11c == 1` with kind 0, or kind > 0): kind 3 → HP + 2 below 500; kind 2 with `+0x116 == 0` → `+0x116
    ///    = 0x13`, HP − 100, `+0xaa = 0x11`, snd 701 vol 0x55;
    /// 2. not on ground (`+0xce == 0`) → `.ApplyGravityAndSeparateFromTiles`;
    /// 3. by state (`frogState`);
    /// 4. HP < 1 with state ≠ 4 → `+0x46 = 0`, state 4, frogdie 615 (vol 0x100, the frog's pitch);
    /// 5. `x += vx`, `y += vy` (24.8, no collision); `.ApplyGravityAndSeparateFromTiles`; `.StandardSpriteCleanup`.
    public static func handleFrog(world w: SpriteWorld, id: Int, solver: TileSolver,
                                  faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right }) {
        guard let s0 = w.active.record(id: id), !s0.dead, !s0.handleSkip else { return }
        w.standardSpriteHandles(id)
        guard var s = w.active.record(id: id) else { return }
        if s.waterRow != 0 {                                            // M l. 70245–70265: dead (§0.1)
            if -800 < s.vy { s.vy &-= 100 }
            if (s.waterRow == 1 && s.waterKind == 0) || 0 < s.waterKind {
                let k = s.waterKind
                if k == 3 {
                    if s.hp < 500 { s.hp &+= 2 }
                } else if k < 3 && 1 < k && s.invulnerable == 0 {
                    s.invulnerable = 0x13
                    s.hp &-= 100
                    s.flash = 0x11
                    w.player.cue(PlayerCue(call: .threeD, snd: ouchSound, priority: 1, volume: 0x55, position: s.centre))
                }
            }
        }
        if s.groundKind == 0 {
            w.active.update(id: id) { $0 = s }
            solver.applyGravityAndSeparate(id, pass: passFrog(s))
            guard let t = w.active.record(id: id) else { return }
            s = t
        }
        frogState(w, id: id, &s)
        if s.hp < 1 && s.subtype != 4 {
            s.phase = 0
            s.subtype = 4
            playRandFrog(w, s, snd: dieSound, priority: 1, volume: 0x100)
        }
        s.x256 &+= s.vx
        s.y256 &+= s.vy
        w.active.update(id: id) { $0 = s }
        if let t = w.active.record(id: id) { solver.applyGravityAndSeparate(id, pass: passFrog(t)) }
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
    }

    /// The Frog's state switch (M l. 70269–70446):
    /// - 2 (spit): k = `+0x46 / 3`; vx 0; k < 5 → face 0x708[5 + (k ≤ 2 ? k : 4 − k)], and at `+0x46 == 6` the spit
    ///   (`frogSpit`); k ≥ 5 → `+0x14c = −10 − R(10)`, state 0xb, face 0; `+0x46` + 1.
    /// - 4 (dying): vx × 0.9; face 4; `+0x1a2 < 1` → 1 (the burn, from the Cleanup).
    /// - 9 (crouch): face min(`+0x46 / 3`, 2), vx 0; `+0x46 > 7` → the launch: face 3, state 10; R(100) > 0x37 →
    ///   frogjump 613 (vol 0x80, the frog's pitch); `+0xce = 0`; vx = −0x28a − R(200), vy = −0x514 − R(400); `+0x154 <
    ///   0` → + 1 and `+0x14c = 0`, else `+0x14c = −10 − R(10)`; the aim: P.y < c.y − 0x28 → vy −= R(0x96) + 200; else
    ///   |c.x − P.x| < 0xfb → R(100) > 0x50 → vy −= 0x15e, vx −= 200; else vx, vy × 0.7 and `+0x14c = −4 − R(4)`;
    ///   gravity 0x5a; facing right → vx = −vx; `+0x158 = vx`. `+0x46` + 1.
    /// - 10 (airborne): face 3 while vy < 0, else 4; vx = `+0x158`; gravity 0x5a; on ground → face 5, state 0xb.
    /// - 0xb (idle): vx 0; `+0x14c` + 1; `+0x17e = c.x < P.x` (signed); face 0; `+0x14c ≥ 0`: |c.x − P.x| < 0xfa → R =
    ///   R(100); 10 < R < 0x47 with P.y < c.y − 0x32 → R = 100; R < 0x47 with `+0x154 ≥ 0` → R < 8: state 9, `+0x154
    ///   = −3 − R(3)`, `+0x46 = 0`; else `+0x46 = 0`, state 2; otherwise (R ≥ 0x47 or `+0x154 < 0`, or far) `+0x46 = 0`,
    ///   state 9.
    static func frogState(_ w: SpriteWorld, id: Int, _ s: inout SpriteSlot) {
        let px = Int(w.player.centreX), py = Int(w.player.centreY)
        switch s.subtype {
        case 2:
            var k = s.phase / 3
            s.vx = 0
            if k < 5 {
                if 2 < k { k = 4 - k }
                s.face = face(frogSet, Int(k) + 5)
                if s.phase == 6 { frogSpit(w, id: id, &s) }
            } else {
                s.classTimer = -10 - Int32(w.rng.next(10))
                s.subtype = 0xb
                s.face = face(frogSet, 0)
            }
            s.phase &+= 1
        case 4:
            s.vx = TileSolver.fctiwz(Double(s.vx) * friction90)
            s.face = face(frogSet, 4)
            if s.burnRow < 1 { s.burnRow = 1 }
        case 9:
            var i = Int(s.phase) / 3
            if 1 < i { i = 2 }
            s.vx = 0
            s.face = face(frogSet, i)
            if 7 < s.phase {
                s.face = face(frogSet, 3)
                s.subtype = 10
                if 0x37 < w.rng.next(100) { playRandFrog(w, s, snd: jumpSound, priority: 1, volume: 0x80) }
                s.groundKind = 0
                s.vx = -0x28a - Int32(w.rng.next(200))
                s.vy = -0x514 - Int32(w.rng.next(400))
                if s.classWord154 < 0 {
                    s.classWord154 &+= 1
                    s.classTimer = 0
                } else {
                    s.classTimer = -10 - Int32(w.rng.next(10))
                }
                let cx = h16(s.centre.x), cy = h16(s.centre.y)
                if py < cy - 0x28 {
                    s.vy &-= Int32(w.rng.next(0x96)) + 200
                } else if abs32(cx - px) < 0xfb {
                    if 0x50 < w.rng.next(100) {
                        s.vy &-= 0x15e
                        s.vx &-= 200
                    }
                } else {
                    s.vx = TileSolver.fctiwz(Double(s.vx) * far70)
                    s.vy = TileSolver.fctiwz(Double(s.vy) * far70)
                    s.classTimer = -4 - Int32(w.rng.next(4))
                }
                s.gravity = 0x5a
                if s.mirrored { s.vx = 0 &- s.vx }
                s.classWord158 = s.vx
            }
            s.phase &+= 1
        case 10:
            s.face = face(frogSet, s.vy < 0 ? 3 : 4)
            s.vx = s.classWord158
            s.gravity = 0x5a
            if s.groundKind != 0 {
                s.face = face(frogSet, 5)
                s.subtype = 0xb
            }
        case 0xb:
            s.vx = 0
            s.classTimer &+= 1
            let cx = h16(s.centre.x), cy = h16(s.centre.y)
            s.mirrored = cx < px                                        // the signed-compare idiom (M l. 70409–70411)
            s.face = face(frogSet, 0)
            if -1 < s.classTimer {
                if abs32(cx - px) < 0xfa {
                    var r = w.rng.next(100)
                    if 10 < r && r < 0x47 && py < cy - 0x32 { r = 100 }
                    if r < 0x47 && -1 < s.classWord154 {
                        if r < 8 {
                            s.subtype = 9
                            s.classWord154 = -3 - Int32(w.rng.next(3))
                            s.phase = 0
                        } else {
                            s.phase = 0
                            s.subtype = 2
                        }
                    } else {
                        s.subtype = 9
                        s.phase = 0
                    }
                } else {
                    s.phase = 0
                    s.subtype = 9
                }
            }
        default:
            break
        }
    }

    /// The spit (M l. 70280–70316): `MTNewSprite(0x709, c.x + flip·0x5a − 0x2d, c.y − 0x14, layer + 1, −1,
    /// .SetupEnemyShotSprite)` (`EnemyShot.spawn`); vx 2000 facing right, else −2000; by p1 (`+0x15c`): 3 → `+0xb8 =
    /// 0x1000f`, `+0xa4 <<= 2`; 1 → `+0xa4 <<= 1`, `+0xb8 = 0x1000c`; 2 → `+0xb8 = 0x10017`; 4 → `+0xb8 = 0x1000b`,
    /// `+0xa4 × 3` (the shot's `+0xa4` is 0: `.SetupEnemyShotSprite`'s first 0x709 arm stores none, §1.4). No free
    /// record: the stores are dropped.
    static func frogSpit(_ w: SpriteWorld, id: Int, _ s: inout SpriteSlot) {
        let x = h16(h16(s.centre.x) + (s.mirrored ? 0x5a : 0) - 0x2d)
        let y = h16(h16(s.centre.y) - 0x14)
        w.active.update(id: id) { $0 = s }
        let shot = EnemyShot.spawn(w, type: EnemyShot.frogSpit, x: x, y: y, layer: Int16(truncatingIfNeeded: s.layer &+ 1))
        s = w.active.record(id: id) ?? s
        guard let shot else { return }
        let vx: Int32 = s.mirrored ? 2000 : -2000
        let p1 = s.classWord15c
        w.active.update(id: shot) { c in
            c.vx = vx
            switch p1 {
            case 3:
                c.mode = 0x1000f
                c.hp = c.hp << 2
            case 1:
                c.hp = c.hp << 1
                c.mode = 0x1000c
            case 2:
                c.mode = 0x10017
            case 4:
                c.mode = 0x1000b
                c.hp = c.hp &* 3
            default:
                break
            }
        }
    }

    // MARK: - the Salamander's Handle

    /// The Salamander's tile callback `+0x1f8` (nil = 0).
    static func passSalamander(_ s: SpriteSlot) -> TileHit? {
        guard s.hasTileHit else { return nil }
        return { solver, id, cell, kind, layer in
            hitSalamanderTile(solver, id: id, pos: cell, kind: kind, layer: layer)
        }
    }

    /// `.HandleSalamanderSprite(s)` (M l. 70705–70857), unless `+0xe9` or `+0x1b2`:
    /// 1. `.StandardSpriteHandles`; the water block (dead, §0.1) — `+0x11c ≠ 0`: vy > −800 → vy −= 100; (`+0x11c == 1`
    ///    with kind 0, or kind > 0) with `+0x116 == 0` → `+0x116 = 0x13`, HP − 100, `+0xaa = 0x11`, snd 701 vol 0x55;
    /// 2. `.ApplyGravityAndSeparateFromTiles` (always — the frame's only call); vx = 0;
    /// 3. by state (`salamanderState`);
    /// 4. HP < 1 with state ≠ 4 → `+0x46 = 0`, state 4 (no sound);
    /// 5. `x += vx`, `y += vy` (24.8, no collision); `.StandardSpriteCleanup`.
    public static func handleSalamander(world w: SpriteWorld, id: Int, solver: TileSolver,
                                        faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right }) {
        guard let s0 = w.active.record(id: id), !s0.dead, !s0.handleSkip else { return }
        w.standardSpriteHandles(id)
        guard var s = w.active.record(id: id) else { return }
        if s.waterRow != 0 {                                            // M l. 70722–70735: dead (§0.1)
            if -800 < s.vy { s.vy &-= 100 }
            if ((s.waterRow == 1 && s.waterKind == 0) || 0 < s.waterKind) && s.invulnerable == 0 {
                s.invulnerable = 0x13
                s.hp &-= 100
                s.flash = 0x11
                w.player.cue(PlayerCue(call: .threeD, snd: ouchSound, priority: 1, volume: 0x55, position: s.centre))
            }
        }
        w.active.update(id: id) { $0 = s }
        solver.applyGravityAndSeparate(id, pass: passSalamander(s))
        guard var t = w.active.record(id: id) else { return }
        t.vx = 0
        salamanderState(w, id: id, &t)
        if t.hp < 1 && t.subtype != 4 {
            t.phase = 0
            t.subtype = 4
        }
        t.x256 &+= t.vx
        t.y256 &+= t.vy
        w.active.update(id: id) { $0 = t }
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
    }

    /// The Salamander's state switch (M l. 70737–70846):
    /// - 2 (spit): vx 0; `+0x17e = c.x < P.x`; k = `+0x46 / 3`; `+0x14c < 0` → face 0, `+0x46 = 0`, `+0x14c` + 1 (the
    ///   pause); else k < 6 → face 0x712[3 + k], and at `+0x46 == 12` the fireball (`fireball`); k ≥ 6 → R(10) < 7:
    ///   `+0x46 = 0`, `+0x14c = −10 − R(10)`; else `+0x14c = −10 − R(10)`, state 0xb, face 1, vy = −0x708 − R(600);
    ///   then `+0x46` + 1.
    /// - 4 (dying): face 5; `+0x1a2 < 1` → 1.
    /// - 10 (leap): face 2 while vy < 0, else 1; gravity 0xaa; on ground: face 0; `+0x11c` 0 or > 1 → state 2; == 1 →
    ///   state 0xc, `+0x14c = −0x14 − R(0x1e)`.
    /// - 0xb (hop): face 2 / 1 by vy; gravity 0xd2; on ground: face 0, state 0xc.
    /// - 0xc (idle): vx 0; `+0x14c` + 1; `+0x17e = c.x < P.x`; face 0; `+0x14c ≥ 0` with |c.x − P.x| < 0xfa → `+0x46 =
    ///   0`, face 1, state 10, vy = −0xc80 − R(700).
    static func salamanderState(_ w: SpriteWorld, id: Int, _ s: inout SpriteSlot) {
        let px = Int(w.player.centreX)
        let cx = h16(s.centre.x)
        switch s.subtype {
        case 2:
            let k = Int(s.phase / 3)
            s.vx = 0
            s.mirrored = cx < px                                        // M l. 70741–70743
            if s.classTimer < 0 {
                s.face = face(salamanderSet, 0)
                s.phase = 0
                s.classTimer &+= 1
            } else {
                if k < 6 {
                    s.face = face(salamanderSet, k + 3)
                    if s.phase == 0xc { fireball(w, id: id, &s) }
                } else if w.rng.next(10) < 7 {
                    s.phase = 0
                    s.classTimer = -10 - Int32(w.rng.next(10))
                } else {
                    s.classTimer = -10 - Int32(w.rng.next(10))
                    s.subtype = 0xb
                    s.face = face(salamanderSet, 1)
                    s.vy = -0x708 - Int32(w.rng.next(600))
                }
                s.phase &+= 1
            }
        case 4:
            s.face = face(salamanderSet, 5)
            if s.burnRow < 1 { s.burnRow = 1 }
        case 10:
            s.face = face(salamanderSet, s.vy < 0 ? 2 : 1)
            s.gravity = 0xaa
            if s.groundKind != 0 {
                s.face = face(salamanderSet, 0)
                if s.waterRow == 0 || 1 < s.waterRow {
                    s.subtype = 2
                } else {
                    s.subtype = 0xc
                    s.classTimer = -0x14 - Int32(w.rng.next(0x1e))
                }
            }
        case 0xb:
            s.face = face(salamanderSet, s.vy < 0 ? 2 : 1)
            s.gravity = 0xd2
            if s.groundKind != 0 {
                s.face = face(salamanderSet, 0)
                s.subtype = 0xc
            }
        case 0xc:
            s.vx = 0
            s.classTimer &+= 1
            s.mirrored = cx < px                                        // M l. 70829–70831
            s.face = face(salamanderSet, 0)
            if -1 < s.classTimer && abs32(cx - px) < 0xfa {
                s.phase = 0
                s.face = face(salamanderSet, 1)
                s.subtype = 10
                s.vy = -0xc80 - Int32(w.rng.next(700))
            }
        default:
            break
        }
    }

    /// The fireball (M l. 70754–70766): `MTNewSprite(0x712, c.x + flip·0x3c − 0x2d, c.y − 0x19, layer + 1, −1,
    /// .SetupEnemyShotSprite)` (`EnemyShot.spawn`), vx 2000 facing right, else −2000. No free record: dropped.
    static func fireball(_ w: SpriteWorld, id: Int, _ s: inout SpriteSlot) {
        let x = h16(h16(s.centre.x) + (s.mirrored ? 0x3c : 0) - 0x2d)
        let y = h16(h16(s.centre.y) - 0x19)
        w.active.update(id: id) { $0 = s }
        let shot = EnemyShot.spawn(w, type: EnemyShot.spit, x: x, y: y, layer: Int16(truncatingIfNeeded: s.layer &+ 1))
        s = w.active.record(id: id) ?? s
        guard let shot else { return }
        let vx: Int32 = s.mirrored ? 2000 : -2000
        w.active.update(id: shot) { $0.vx = vx }
    }

    // MARK: - hits

    /// `.HitFrogSprite(s, other)` (M l. 70462–70553); state 4 → return. Every Handle comparison is `+0x4c ==`:
    /// - a player shot with `+0xa6 == 0`: `.KillPlayerShot(o, 0, 0)` (its stale r29 is the Frog, `or r29,r3,r3` raw
    ///   `100828e4`: the Frog's own `+0x9a`); type 1 → `.TurnIntoStatue(s)`; else `.HurtSprite(s, o.+0xa4, (i16)(o.vx
    ///   >> 3), (i16)(o.vy >> 3), 8, 8)`, and on a hurt: R(100) < 0x2e → 701, else froghit 614 (vol 0x100, the frog's
    ///   pitch); state 9 unless 10; `+0x46 = 3`; HP > 0 → `.BloodSpray(s, o, 0x28, 400, 0x96, 2)`;
    /// - a Statue or Box: the crush (`CrawlerRoach.crush`: `.PlatformBounce` 2 with the solid falling or the Frog on
    ///   ground → HP 0, `+0x150 = 0x16`);
    /// - an Effect 0x4b7 at `+0x46 < 8` or a 0x5a0 with `+0x14c == 1 || +0x150 == 2`: `.HurtSprite(s, 100, (i16)(o.vx
    ///   >> 3), (i16)(o.vy >> 3), 8, 8)`, and on a hurt: state 9 unless 10; `+0x46 = 3`; HP > 0 → blood; HP < 0xc9 →
    ///   702, else HP > 0 → 701 (vol 0x100, no draw).
    public static func hitFrog(_ w: SpriteWorld, id: Int, other oID: Int, lights: inout LightTable, effects: Int16 = 1,
                               faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                               faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard let s = w.active.record(id: id), let o = w.active.record(id: oID) else { return }
        guard s.subtype != 4 else { return }
        let runs = BackgroundSprite.runs
        func reel(_ w: SpriteWorld) {
            w.active.update(id: id) { t in
                if t.subtype != 10 { t.subtype = 9 }
                t.phase = 3
            }
        }
        if runs(o, .playerShot) && o.counterA6 == 0 {
            PlayerShotHits.kill(w, shot: oID, sound: false, effect: false, effects: effects, lights: &lights,
                                faceWidth: faceWidth, faceBounds: faceBounds, staleSlot: s.light)
            guard let shot = w.active.record(id: oID) else { return }
            if shot.type == 1 {
                EnemyCommon.turnIntoStatue(w, id: id)
                return
            }
            guard HurtSprite.apply(w, id: id, damage: shot.hp, dvx: Int16(truncatingIfNeeded: shot.vx >> 3),
                                   dvy: Int16(truncatingIfNeeded: shot.vy >> 3), invulnerable: 8, flash: 8),
                  let t = w.active.record(id: id) else { return }
            let snd = w.rng.next(100) < 0x2e ? ouchSound : hitSound
            playRandFrog(w, t, snd: snd, priority: 1, volume: 0x100)
            reel(w)
            guard let u = w.active.record(id: id), 0 < u.hp else { return }
            BloodSpray.spray(w, victim: id, attacker: oID, count: 0x28, speed: 400, spread: 0x96, kind: 2)
        } else if runs(o, .statue) || runs(o, .box) {
            CrawlerRoach.crush(w, id: id, other: oID)
        } else if EnemyCommon.environmentalHazard(o, crawlerFields: true) {
            guard HurtSprite.apply(w, id: id, damage: 100, dvx: Int16(truncatingIfNeeded: o.vx >> 3),
                                   dvy: Int16(truncatingIfNeeded: o.vy >> 3), invulnerable: 8, flash: 8) else { return }
            reel(w)
            if let t = w.active.record(id: id), 0 < t.hp {
                BloodSpray.spray(w, victim: id, attacker: oID, count: 0x28, speed: 400, spread: 0x96, kind: 2)
            }
            guard let t = w.active.record(id: id) else { return }
            if t.hp < 0xc9 {
                w.player.cue(PlayerCue(call: .threeD, snd: uhOhSound, priority: 1, volume: 0x100, position: t.centre))
            } else if 0 < t.hp {
                w.player.cue(PlayerCue(call: .threeD, snd: ouchSound, priority: 1, volume: 0x100, position: t.centre))
            }
        }
    }

    /// The test-only form (no light table).
    static func hitFrog(_ w: SpriteWorld, id: Int, other oID: Int) {
        var scratch = LightTable()
        hitFrog(w, id: id, other: oID, lights: &scratch)
    }

    /// `.HitSalamanderSprite(s, other)` (M l. 70859–70911), no state guard:
    /// - a player shot with `+0xa6 == 0`: `.KillPlayerShot(o, 0, 0)` (r29 is never written here — the caller's,
    ///   unknown: nil [LOW]); type 1 → `.TurnIntoStatue(s)`; else `.HurtSprite(s, o.+0xa4, (i16)(o.vx >> 5), (i16)(o.vy
    ///   >> 3), 2, 8)`, and on a hurt: `+0xa6 < 2` → 0x15 (write-only, §7.1); HP > 0 → `.BloodSpray(s, o, 0x28, 400,
    ///   0x96, 2)`; HP < 0xc9 → 702, else HP > 0 → 701 (vol 0x100, no draw);
    /// - a Statue or Box: the crush (`CrawlerRoach.crush`).
    /// No Effect 0x4b7 or geyser arm.
    public static func hitSalamander(_ w: SpriteWorld, id: Int, other oID: Int, lights: inout LightTable,
                                     effects: Int16 = 1, faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                                     faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard w.active.record(id: id) != nil, let o = w.active.record(id: oID) else { return }
        let runs = BackgroundSprite.runs
        if runs(o, .playerShot) && o.counterA6 == 0 {
            PlayerShotHits.kill(w, shot: oID, sound: false, effect: false, effects: effects, lights: &lights,
                                faceWidth: faceWidth, faceBounds: faceBounds, staleSlot: nil)
            guard let shot = w.active.record(id: oID) else { return }
            if shot.type == 1 {
                EnemyCommon.turnIntoStatue(w, id: id)
            } else if HurtSprite.apply(w, id: id, damage: shot.hp, dvx: Int16(truncatingIfNeeded: shot.vx >> 5),
                                       dvy: Int16(truncatingIfNeeded: shot.vy >> 3), invulnerable: 2, flash: 8) {
                w.active.update(id: id) { t in if t.counterA6 < 2 { t.counterA6 = 0x15 } }
                if let t = w.active.record(id: id), 0 < t.hp {
                    BloodSpray.spray(w, victim: id, attacker: oID, count: 0x28, speed: 400, spread: 0x96, kind: 2)
                }
                guard let t = w.active.record(id: id) else { return }
                if t.hp < 0xc9 {
                    w.player.cue(PlayerCue(call: .threeD, snd: uhOhSound, priority: 1, volume: 0x100, position: t.centre))
                } else if 0 < t.hp {
                    w.player.cue(PlayerCue(call: .threeD, snd: ouchSound, priority: 1, volume: 0x100, position: t.centre))
                }
            }
        } else if runs(o, .statue) || runs(o, .box) {
            CrawlerRoach.crush(w, id: id, other: oID)
        }
    }

    // MARK: - Kills

    /// `.KillFrog(s)` (M l. 70556–70602), the Kill proc `+0x50`: the counting Kill (`EnemyCounting.kill`), `+0xe9 =
    /// +0xea = 1`, then the score `G+0` by p1 (`+0x15c`) — unconditional (no `+0xe9` test): 0 → 500, 1 → 600, 2 →
    /// 600, 3 → 2000, 4 → 1000, any other none.
    static func killFrog(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        w.enemies.kill(&s, globals: &w.globals, level: w.levelIndex, forGood: true)
        switch s.classWord15c {
        case 0: w.globals.score &+= 500
        case 1, 2: w.globals.score &+= 600
        case 3: w.globals.score &+= 2000
        case 4: w.globals.score &+= 1000
        default: break
        }
    }

    /// `.KillSalamander(s)` (M l. 70913–70937), the Kill proc `+0x50`: the counting Kill; `+0xe9 == 0` → score + 400;
    /// `+0xe9 = +0xea = 1`.
    static func killSalamander(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        let first = s.killCount == 0
        w.enemies.kill(&s, globals: &w.globals, level: w.levelIndex, forGood: true)
        if first { w.globals.score &+= 400 }
    }

    // MARK: - tile hits

    /// `.HitFrogTileSprite(s, pos, kind, layer)` (M l. 70604–70640): FG (layer 1) → `.WallBounce(s, kind, &pos,
    /// vCentre, 0, +0x34, 0, 0)`, then on ground (`+0xce`) gravity 400; BG kinds < 100 → `.WallBounce`; < 200 →
    /// `.WallBounceBG(kind − 100, …)`; water → `.HandleUnderWater` unless `+0x140`.
    static func hitFrogTile(_ solver: TileSolver, id: Int, pos posIn: TilePos, kind: Int, layer: TileLayer) {
        let w = solver.world
        guard let s = w.active.record(id: id) else { return }
        var pos = posIn
        let r = s.hotRect
        let vCentre = h16(r.top + h16((r.bottom - r.top) >> 1))
        let k = Int16(truncatingIfNeeded: kind)
        if layer == .foreground {
            solver.wallBounce(id, kind: kind, tile: &pos, vCentre: vCentre, factor: 0, rect: r, bounce: false)
            if let t = w.active.record(id: id), t.groundKind != 0 { w.active.update(id: id) { $0.gravity = 400 } }
        } else if k < 100 {
            solver.wallBounce(id, kind: kind, tile: &pos, vCentre: vCentre, factor: 0, rect: r, bounce: false)
        } else if k < 200 {
            solver.wallBounceBG(id, kind: kind - 100, tile: &pos, vCentre: vCentre, factor: 0, rect: r, bounce: false)
        } else if UnderWater.isWaterTile(kind), !s.underwaterDone {
            UnderWater.handle(world: w, id: id, pos: pos)
        }
    }

    /// `.HitSalamanderTileSprite(s, pos, kind, layer)` (M l. 70939–70980): FG → `.WallBounce`; BG kind < 100 with state
    /// ≠ 0xb → `.WallBounce`; else BG kind < 200 with state ≠ 0xb → `.WallBounceBG(kind − 100, …)`; else water →
    /// `.HandleUnderWater` unless `+0x140` (so in state 0xb the solid BG and the BG ledges are passed through). Then
    /// on ground (`+0xce`) gravity 0x15e.
    static func hitSalamanderTile(_ solver: TileSolver, id: Int, pos posIn: TilePos, kind: Int, layer: TileLayer) {
        let w = solver.world
        guard let s = w.active.record(id: id) else { return }
        var pos = posIn
        let r = s.hotRect
        let vCentre = h16(r.top + h16((r.bottom - r.top) >> 1))
        let k = Int16(truncatingIfNeeded: kind)
        if layer == .foreground {
            solver.wallBounce(id, kind: kind, tile: &pos, vCentre: vCentre, factor: 0, rect: r, bounce: false)
        } else if k < 100 && s.subtype != 0xb {
            solver.wallBounce(id, kind: kind, tile: &pos, vCentre: vCentre, factor: 0, rect: r, bounce: false)
        } else if k < 200 && s.subtype != 0xb {
            solver.wallBounceBG(id, kind: kind - 100, tile: &pos, vCentre: vCentre, factor: 0, rect: r, bounce: false)
        } else if UnderWater.isWaterTile(kind), !s.underwaterDone {
            UnderWater.handle(world: w, id: id, pos: pos)
        }
        if let t = w.active.record(id: id), t.groundKind != 0 { w.active.update(id: id) { $0.gravity = 0x15e } }
    }
}
