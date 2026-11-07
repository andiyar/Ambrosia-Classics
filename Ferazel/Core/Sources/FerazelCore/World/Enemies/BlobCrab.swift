import Foundation

/// The Blob (types 1730…1739) and the Crab (1890…1899) (BL; enemies-water-cave §0, §3–§7):
/// `.InitBlobSprite @ 1007cd3c` (M l. 67661–67668, the cache set 0x6c2), `.SetupBlobSprite @ 1007cdb0` (M l.
/// 67671–67735, `setupBlob`), `.HandleDeadBlobSprite @ 1007cf64` (M l. 67738–67763, `handleDeadBlob`),
/// `.HandleBlobSprite @ 1007d044` (M l. 67766–67978, `handleBlob`), `.HitBlobSprite @ 1007d6e0` (M l. 67981–68028,
/// `hitBlob`), `.KillBlob @ 1007d8dc` (M l. 68031–68054, `killBlob`), `.HitBlobTileSprite @ 1007d968` (M l.
/// 68057–68089 — the shape `CrawlerRoach.hitTile` already has); `.InitCrabSprite @ 10089454` (M l. 73957–73967, the
/// cache set 0x762 and the cache single 0x767), `.SetupCrabSprite @ 100894e4` (M l. 73970–74093, `setupCrab`),
/// `.HandleCrabSprite @ 10089828` (M l. 74096–74293, `handleCrab`), `.HandleCrabSegSprite @ 10089dec` (M l.
/// 74296–74305, `handleCrabSegment`), `.HitCrabSprite @ 10089e24` (M l. 74308–74321, `hitCrab`).
///
/// Neither Setup stores a Kill proc `+0x50` (`.InitSprite` 0): the Blob dies through `.KillBlob`, called from its dead
/// puddle's Handle; the Crab never dies. Neither Setup stores `+0x188`…`+0x18b` or `+0xea`; the dead puddle stores
/// `+0xea = 1` every frame (M l. 67745) and `.KillBlob` again (M l. 68052). The Blob is a counted enemy (the window
/// test, M l. 67728–67731); the Crab is not.
///
/// Fields (`SpriteSlot`): `+0xb0` the state `subtype` (Blob 6 pulse, 2 lunge, 5 brake, 4 dying; Crab 0 aim, 1 strike,
/// 3 dead — never reached); `+0xb2` the Blob's pulse phase `subState`; `+0x46` `phase` (the Blob's face counter; the
/// Crab's angle in degrees); `+0xa6` `counterA6` (the Blob's pause / rest; the Crab's strike frame and cooldown);
/// `+0x14c` `classTimer` (the Blob's lunge side, then its dying count; the Crab's reach); `+0x150` / `+0x154`
/// `classWord150` / `classWord154` (the Blob's −1 / the crush 0x16; the Crab's anchor); `+0x15c` `classWord15c` (the
/// dead puddle's frame count); `+0x16c` / `+0x170` `classWord16c` / `classWord170` (the Crab's in-water flag, then
/// its strike vector); `+0x9c` `crabLinks`; `+0x1aa` `rotation` (the claw's face rotation).
public enum BlobCrab {
    /// The types (`+4`).
    public static let blob: Int16 = 0x6c2, crab: Int16 = 0x764, linkType: Int16 = 0x767

    /// The cache sets (`.CacheEncFaceSetFromPICT`, flag 0): `PTR_DAT_100a0c64` 0x6c2 (16 × 0x40×0x2c, one row; M l.
    /// 67666), `PTR_DAT_100a0d60` 0x762 (6 × 100×100, one row; M l. 73964); the cache single `_DAT_100a0d5c` 0x767 (M
    /// l. 73965). The Blob Setup marks 0x6c2 (M l. 67726), the Crab Setup both Crab records (M l. 74007–74008) — the
    /// links' Setup too.
    public static let blobSet: Int16 = 0x6c2, clawSet: Int16 = 0x762, linkFace: Int16 = 0x767

    /// The snd slots (`SoundSlots`): `*_DAT_100a02ac` 607 slimemove, `*_DAT_100a0274` 701 'Crawler Ouch',
    /// `*_DAT_100a0270` 702 'Crawler uh oh', `*_DAT_100a026c` 703 'crawler death', `*_DAT_100a041c` 303 'metal hit'.
    static let slimeSound: Int16 = 607, ouchSound: Int16 = 701, uhOhSound: Int16 = 702, deathSound: Int16 = 703,
               metalSound: Int16 = 303

    /// 0.8 (f64 `0x100a1b78`, read with `const.py`): the Blob's vx factor in states 4, 5 and 6.
    static let friction80 = Double(bitPattern: 0x3fe9_9999_9999_999a)

    @inline(__always) static func h16(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }
    @inline(__always) static func face(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }
    @inline(__always) static func abs32(_ v: Int) -> Int { v < 1 ? -v : v }

    // MARK: - the Blob's Setup

    /// `.SetupBlobSprite(s)` (M l. 67671–67735) after `.InitSprite`; `+8` / `+6` (`oldPosition`) hold the spawn point.
    /// In order: `+0x84` / `+0x86` 0; layer 8; the Blob Handle, hit and tile callbacks; gravity 0xfa; `+0xc0 = 0`; by
    /// TYPE (HP, `+0xb8`): 0x6c4 (0x5dc, 0x1000c), 0x6c2 (700, 0), 0x6c3 (0x44c, 0x10004), 0x6c5 (2000, 0x1000f), any
    /// other type none (HP 0 from `.InitSprite` — it dies on its first frame); `+0xc ← +8`, `+0xa ← +6`; SetRect(0xe,
    /// 0xc, 0x2f, 0x21); `+0x150 = −1`, `+0xb0 = 6`, `+0xb2 = 0`, `+0x46 = 2`, `+0x14c = 0`; the set 0x6c2 marked and
    /// `+0xc0` = its face 0 (the caller's); the counting window; the 24.8 position from `+8` / `+6`. No draw, no record
    /// read, no save flag.
    public static func setupBlob(_ s: inout SpriteSlot, counting: inout EnemyCounting) {
        s.particleOffsetY = 0
        s.particleOffsetX = 0
        s.layer = 8
        s.handler = .blob
        s.hasHit = true                                                 // `+0x5c` = `.HitBlobSprite`
        s.hasTileHit = true                                             // `+0x1f8` = `.HitBlobTileSprite`
        s.gravity = 0xfa
        s.face = nil
        switch s.type {
        case 0x6c4: s.hp = 0x5dc; s.mode = 0x1000c
        case 0x6c2: s.hp = 700; s.mode = 0
        case 0x6c3: s.hp = 0x44c; s.mode = 0x10004
        case 0x6c5: s.hp = 2000; s.mode = 0x1000f
        default: break
        }
        s.x = s.oldPosition.x
        s.y = s.oldPosition.y
        s.hotRect = IdleSprites.Rect(top: 0xc, left: 0xe, bottom: 0x21, right: 0x2f)
        s.classWord150 = -1
        s.subtype = 6
        s.subState = 0
        s.phase = 2
        s.classTimer = 0
        counting.countIfWindow(&s)                                      // M l. 67728–67731
        s.x256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.y)) << 8
    }

    // MARK: - the Blob's Handle

    /// The Blob's tile callback `+0x1f8` (nil = 0): `.HitBlobTileSprite` (M l. 68057–68089) — FG (layer 1) or BG kinds
    /// < 100 → `.WallBounce(s, kind, &pos, the hot-rect centre, 0, +0x34, 0, 0)`; < 200 → `.WallBounceBG(kind − 100,
    /// …)`; water → `.HandleUnderWater` unless `+0x140` — the Crawler's shape (`CrawlerRoach.hitTile`).
    static func passBlob(_ s: SpriteSlot) -> TileHit? {
        guard s.hasTileHit else { return nil }
        return { solver, id, cell, kind, layer in CrawlerRoach.hitTile(solver, id: id, pos: cell, kind: kind, layer: layer) }
    }

    /// `.HandleBlobSprite(s)` (M l. 67766–67978), unless `+0xe9` or `+0x1b2`. P = `*_DAT_1009fd94` / `fd90` (the
    /// player's centre), c = the hot-rect centre `+0x10` / `+0xe` as it stands at each read:
    /// 1. `.StandardSpriteHandles`; `+0x17e = 1` if c.x < P.x, 0 if P.x < c.x, kept if equal (M l. 67792–67797);
    /// 2. by state (`blobState`);
    /// 3. HP < 1 → state 4 (M l. 67946–67948);
    /// 4. `.ApplyGravityAndSeparateFromTiles` (the frame's only call); the liquids after it (M l. 67950–67966; live, as
    ///    the Frog's are not — §0.1): in liquid and fully under kind 0 or in any kind > 0 — kind 3 HP + 4 below 500,
    ///    kind 2 with `+0x116 == 0` → `+0x116 = 0x13`, HP − 100, `+0xaa = 0x11`, snd 701 vol 0x55 (`EnemyCommon.liquids`
    ///    `.blob`); no self-buoyancy;
    /// 5. the face: state 4 → 0x6c2[10 + (`+0x46` >> 2)], else 0x6c2[`+0x46` >> 1] (M l. 67967–67974);
    ///    `.StandardSpriteCleanup`.
    public static func handleBlob(world w: SpriteWorld, id: Int, solver: TileSolver,
                                  faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right }) {
        guard let s0 = w.active.record(id: id), !s0.dead, !s0.handleSkip else { return }
        w.standardSpriteHandles(id)
        guard var s = w.active.record(id: id) else { return }
        let px = Int(w.player.centreX), cx = h16(s.centre.x)
        if cx < px {
            s.mirrored = true
        } else if px < cx {
            s.mirrored = false
        }
        blobState(w, id: id, &s)
        if s.hp < 1 { s.subtype = 4 }
        w.active.update(id: id) { $0 = s }
        solver.applyGravityAndSeparate(id, pass: passBlob(s))
        EnemyCommon.liquids(w, id: id, class: .blob)
        w.active.update(id: id) { t in
            t.face = t.subtype == 4 ? face(blobSet, 10 + Int(t.phase >> 2)) : face(blobSet, Int(t.phase >> 1))
        }
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
    }

    /// The Blob's state switch (M l. 67799–67945), on `s` (the caller writes it back); P, c as `handleBlob`:
    /// - 4 (dying, M l. 67800–67833): the entry block for `+0x14c == −1` (`+0x46 = 0`, score + 200, snd 703 vol 0x100,
    ///   the record's flag cleared) — **dead**: no Blob routine stores −1 to `+0x14c` (Setup 0, the lunge 0 / 1, this
    ///   arm + 1; transcribed as written); `+0x14c` + 1; vx × 0.8, |vx| < 200 → 0; `+0x46` + 1; above 19 → 20 and, with
    ///   vy 0 or `+0xcd` set, the Handle becomes `.HandleDeadBlobSprite`; `+0x5c = 0` either way.
    /// - 2 (lunge, M l. 67835–67883): side = P.x > c.x; side ≠ `+0x14c`, or vx against it → state 5; `+0x14c = side`.
    ///   `+0xa6 == 0`: a = 400 if c.x < P.x else −400; `+0x46 < 20` → at `+0x46 == 4` slimemove 607 vol 0x55 at 50000 +
    ///   R(30000), then `+0x46` + 1; 8…13 → vx + a; 14…19 → vx − a; at 20 → `+0x46 = 0`, `+0xa6 = R(20)`, R(100) >
    ///   0x5c → state 6. Else `+0xa6` − 1.
    /// - 6 (pulse, M l. 67885–67929): `+0x17e = 0`; `+0xa6 > 0` → − 1; `+0xb2 == 1`: `+0xa6 == 1` → `+0xb2 = 0`, else
    ///   `+0xa6 == 0` → `+0x46` − 1, below 3 → 2 and `+0xa6 = 2 + R(14)`; `+0xb2 ≠ 1`: `+0x46` + 1, above 8 → 9 and `+0xb2
    ///   = 1`. |P.x − c.x| < 200, |P.y − c.y| < 0xdc, P.y > c.y − 0x80 and `+0xa6 == 1` → `+0xa6 = 0`, state 2. Then vx ×
    ///   0.8 and vx < 100 (signed, `cmpwi r0,0x64 @1007d234`) → 0.
    /// - 5 (brake, M l. 67930–67944): vx × 0.8; `+0x46` + 1, above 19 → 0; |vx| < 200 → vx 0, state 2.
    static func blobState(_ w: SpriteWorld, id: Int, _ s: inout SpriteSlot) {
        let px = Int(w.player.centreX), py = Int(w.player.centreY)
        func brake() { s.vx = TileSolver.fctiwz(Double(s.vx) * friction80) }
        switch s.subtype {
        case 4:
            if s.classTimer == -1 {                                     // dead: no writer stores −1 (see above)
                s.phase = 0
                w.globals.score &+= 200
                w.player.cue(PlayerCue(call: .threeD, snd: deathSound, priority: 1, volume: 0x100, position: s.centre))
                let r = Int(s.recordIndex)
                if -1 < r && r < 0x1ff && r < w.records.count {
                    let p = w.records[r]
                    w.records[r] = Placement(index: p.index, flag: 0, byte1: p.byte1, type: p.type, p1: p.p1, p2: p.p2,
                                             p3: p.p3, p4: p.p4, y: p.y, x: p.x)
                }
            }
            s.classTimer &+= 1
            brake()
            if abs32(Int(s.vx)) < 200 { s.vx = 0 }
            s.phase &+= 1
            if 0x13 < s.phase {
                s.phase = 0x14
                if s.vy == 0 || s.onSprite != 0 { s.handler = .deadBlob }   // `+0x4c` = `PTR_PTR_100a0c58`
                s.hasHit = false
            }
        case 2:
            let cx = h16(s.centre.x)
            let side: Int32 = px > cx ? 1 : 0                           // the unsigned-compare idiom, signed (M l. 67838)
            if side != s.classTimer || (side != 0 && s.vx < 0) || (side == 0 && 0 < s.vx) { s.subtype = 5 }
            s.classTimer = side
            if s.counterA6 == 0 {
                let a: Int32 = cx < px ? 400 : -400
                if s.phase < 0x14 {
                    if s.phase == 4 {
                        let r = Int32(w.rng.next(30000))
                        w.player.cue(PlayerCue(call: .threeDPitched, snd: slimeSound, priority: 1, volume: 0x55,
                                               position: s.centre, rate: r + 50000))
                    }
                    s.phase &+= 1
                }
                let k = s.phase
                if 8 <= k && k <= 0xd {
                    s.vx &+= a
                } else if 0xd < k && k < 0x14 {
                    s.vx &-= a
                }
                if s.phase == 0x14 {
                    s.phase = 0
                    s.counterA6 = w.rng.next(0x14)
                    if 0x5c < w.rng.next(100) { s.subtype = 6 }
                }
            } else {
                s.counterA6 &-= 1
            }
        case 6:
            s.mirrored = false
            if 0 < s.counterA6 { s.counterA6 &-= 1 }
            if s.subState == 1 {
                if s.counterA6 == 1 {
                    s.subState = 0
                } else if s.counterA6 == 0 {
                    s.phase &-= 1
                    if s.phase < 3 {
                        s.phase = 2
                        s.counterA6 = w.rng.next(0xe) + 2
                    }
                }
            } else {
                s.phase &+= 1
                if 8 < s.phase {
                    s.phase = 9
                    s.subState = 1
                }
            }
            let cx = h16(s.centre.x), cy = h16(s.centre.y)
            if abs32(px - cx) < 200 && abs32(py - cy) < 0xdc && cy - 0x80 < py && s.counterA6 == 1 {
                s.counterA6 = 0
                s.subtype = 2
            }
            brake()
            if s.vx < 100 { s.vx = 0 }
        case 5:
            brake()
            s.phase &+= 1
            if 0x13 < s.phase { s.phase = 0 }
            if abs32(Int(s.vx)) < 200 {
                s.vx = 0
                s.subtype = 2
            }
        default:
            break
        }
    }

    // MARK: - the dead puddle and the Kill

    /// `.HandleDeadBlobSprite(s)` (M l. 67738–67763) — no `+0xe9` test, no `.StandardSpriteHandles`, no motion: `+0x15c`
    /// + 1 (from 0), `+0xaa = 0`, `+0xea = 1`; > 0x3c → `+0x88 = 0` (out of the light-overlay pass); > 0x42 → `+0xb8 =
    /// 0xb0001`; > 0x48 → 0xb0000; > 0x4e → 0xb0002 (the translucency steps); > 0x54 → `.KillBlob`, `+0xc0 = 0`. Its
    /// `+0x5c` is 0 (state 4 cleared it): no hit.
    public static func handleDeadBlob(world w: SpriteWorld, id: Int) {
        guard var s = w.active.record(id: id) else { return }
        s.classWord15c &+= 1
        s.flash = 0
        s.killedForGood = true
        if 0x3c < s.classWord15c { s.lightOverlay = false }
        if 0x42 < s.classWord15c { s.mode = 0xb0001 }
        if 0x48 < s.classWord15c { s.mode = 0xb0000 }
        if 0x4e < s.classWord15c { s.mode = 0xb0002 }
        if 0x54 < s.classWord15c {
            killBlob(w, &s)
            s.face = nil
        }
        w.active.update(id: id) { $0 = s }
    }

    /// `.KillBlob(s)` (M l. 68031–68054): `+0xe9 == 0` → score + 250 (0xfa); the counting Kill (`EnemyCounting.kill`:
    /// `+0xe9 == 0 && +0x1b5` → live − 1, the stat + 1); `+0xe9 = +0xea = 1`. Called by the dead puddle only — the Blob
    /// stores no Kill proc `+0x50`.
    static func killBlob(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        if s.killCount == 0 { w.globals.score &+= 0xfa }
        w.enemies.kill(&s, globals: &w.globals, level: w.levelIndex, forGood: true)
    }

    // MARK: - the Blob's hit

    /// `.HitBlobSprite(s, other)` (M l. 67981–68028), no state guard. Every Handle comparison is `+0x4c ==`:
    /// - a player shot with `+0xa6 == 0` while the Blob's HP > 0: `.KillPlayerShot(o, 0, 0)` (r29 is never written here
    ///   — the caller's, unknown: nil [LOW], raw `1007d6e0..1007d730`); type 1 → `.TurnIntoStatue(s)`; else
    ///   `.HurtSprite(s, o.+0xa4, (i16)(o.vx >> 1), −1000, 2, 8)` (`li r6,-0x3e8 @1007d760`), and on a hurt: state 5,
    ///   `.BloodSpray(s, o, 0x28, 400, 0x96, 0xc9)` (alive or not), HP < 0xc9 → 702, else HP > 0 → 701 (vol 0x100, no
    ///   draw). The Ring of Smiting reaches a Blob through this arm: its seeds are player shots (`Smite`); there is no
    ///   Effect 0x4b7 arm here;
    /// - a Statue or Box: the crush (`CrawlerRoach.crush`: `.PlatformBounce` 2 with the solid falling or the Blob on
    ///   ground → HP 0, `+0x150 = 0x16` — never read for a Blob, §7.2).
    public static func hitBlob(_ w: SpriteWorld, id: Int, other oID: Int, lights: inout LightTable, effects: Int16 = 1,
                               faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                               faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard let s = w.active.record(id: id), let o = w.active.record(id: oID) else { return }
        let runs = BackgroundSprite.runs
        if runs(o, .playerShot) && o.counterA6 == 0 && 0 < s.hp {
            PlayerShotHits.kill(w, shot: oID, sound: false, effect: false, effects: effects, lights: &lights,
                                faceWidth: faceWidth, faceBounds: faceBounds, staleSlot: nil) // nil: unverified [LOW]
            guard let shot = w.active.record(id: oID) else { return }
            if shot.type == 1 {
                EnemyCommon.turnIntoStatue(w, id: id)
                return
            }
            guard HurtSprite.apply(w, id: id, damage: shot.hp, dvx: Int16(truncatingIfNeeded: shot.vx >> 1), dvy: -1000,
                                   invulnerable: 2, flash: 8) else { return }
            w.active.update(id: id) { $0.subtype = 5 }
            BloodSpray.spray(w, victim: id, attacker: oID, count: 0x28, speed: 400, spread: 0x96, kind: 0xc9)
            guard let t = w.active.record(id: id) else { return }
            if t.hp < 0xc9 {
                w.player.cue(PlayerCue(call: .threeD, snd: uhOhSound, priority: 1, volume: 0x100, position: t.centre))
            } else if 0 < t.hp {
                w.player.cue(PlayerCue(call: .threeD, snd: ouchSound, priority: 1, volume: 0x100, position: t.centre))
            }
        } else if runs(o, .statue) || runs(o, .box) {
            CrawlerRoach.crush(w, id: id, other: oID)
        }
    }

    /// The test-only form (no light table).
    static func hitBlob(_ w: SpriteWorld, id: Int, other oID: Int) {
        var scratch = LightTable()
        hitBlob(w, id: id, other: oID, lights: &scratch)
    }

    // MARK: - the Crab's Setup

    /// `.SetupCrabSprite(s)` (M l. 73970–74093) after `.InitSprite`, for the claw and (through its own `.MTNewSprite`s)
    /// its links. `+8` / `+6` (`oldPosition`) hold the spawn point. In order: `+0x84` / `+0x86` 0; layer 8; the Crab
    /// Handle and hit, no tile callback; HP 1000; gravity 0; `+0xc ← +8`, `+0xa ← +6`; SetRect(0x18, 0x18, 0x4c, 0x4c);
    /// `+0x150 = −1`; `+0xb0 = 0`, `+0xb2 = 0`, `+0x46 = 2`; both Crab caches marked; `+0xc0 = 0`; `+0x16c` = 1 when
    /// `.IsWaterTile(.LookupBGTileKind(.GetBGTile(+0xc >> 5, +0xa >> 5)))` (`water(col, row)`), else 0. Then:
    /// - type > 0x766: 0x767 (a link) → empty rect, no hit, no tile callback, the Handle `.HandleCrabSegSprite`; every
    ///   type then jumps to the 24.8 position (0x768…0x76b keep the claw's Handle with no block — `SetupFaces` refuses
    ///   them, unplaced);
    /// - else: reach `+0x14c` = the live record's p1 (`reach`), 0 → 100; anchor `+0x150` / `+0x154` = `+0xc` / `+0xa`;
    ///   the block `+0x9c` with n = min((reach + 23) / 24, 12) links `MTNewSprite(0x767, +0xc + 0x1e, +0xa + 0x1e,
    ///   +0x80 − 1, 0x1ff, .SetupCrabSprite)` (`newLink(x, y, layer, in water)` — the link's own Setup, then `+0xb8 =
    ///   0x90000` when the claw is in water; nil = no free record), the rest 0; in water `+0xb8 = 0x90000`; the angle
    ///   `+0x46` by type: 0x762 0, 0x763 0xb4, 0x764 / 0x766 0x5a, 0x765 0x10e; `+0xa6 = 0`, `+0xb0 = 0`, `+0x15c = 0`;
    ///   the 24.8 position from `+8` / `+6`. No count, no draw, no save flag.
    public static func setupCrab(_ s: inout SpriteSlot, reach: Int16, water: (Int, Int) -> Bool,
                                 newLink: (_ x: Int, _ y: Int, _ layer: Int32, _ clawInWater: Bool) -> Int?) {
        s.particleOffsetY = 0
        s.particleOffsetX = 0
        s.layer = 8
        s.handler = .crab
        s.hasHit = true                                                 // `+0x5c` = `.HitCrabSprite`
        s.hasTileHit = false
        s.hp = 1000
        s.gravity = 0
        s.x = s.oldPosition.x
        s.y = s.oldPosition.y
        s.hotRect = IdleSprites.Rect(top: 0x18, left: 0x18, bottom: 0x4c, right: 0x4c)
        s.classWord150 = -1
        s.subtype = 0
        s.subState = 0
        s.phase = 2
        s.face = nil
        s.classWord16c = water(h16(s.x) >> 5, h16(s.y) >> 5) ? 1 : 0   // M l. 74010–74018
        if 0x766 < s.type {
            if s.type == linkType {
                s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0)
                s.hasHit = false
                s.hasTileHit = false
                s.handler = .crabSegment                                // `PTR_PTR_100a0d54`
            }
        } else {
            s.classTimer = Int32(reach)
            if s.classTimer == 0 { s.classTimer = 100 }
            s.classWord150 = Int32(Int16(truncatingIfNeeded: s.x))
            s.classWord154 = Int32(Int16(truncatingIfNeeded: s.y))
            let q = (Int(s.classTimer) + 0x17) / 0x18
            let n: Int16 = q < 0xc ? Int16(truncatingIfNeeded: q) : 0xc
            let wet = s.classWord16c != 0
            var links = [Int?](repeating: nil, count: 0xc)
            var i = 0
            while i < Int(n) {
                links[i] = newLink(h16(h16(s.x) + 0x1e), h16(h16(s.y) + 0x1e), s.layer &- 1, wet)
                i += 1
            }
            s.crabLinks = SpriteSlot.CrabBlock(links: links, count: n)
            if wet { s.mode = 0x90000 }
            switch s.type {
            case 0x764, 0x766: s.phase = 0x5a
            case 0x762: s.phase = 0
            case 0x763: s.phase = 0xb4
            case 0x765: s.phase = 0x10e
            default: break
            }
            s.counterA6 = 0
            s.subtype = 0
            s.classWord15c = 0
        }
        s.x256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.y)) << 8
    }

    /// One link as the claw's Setup makes it: `.MTNewSprite(0x767, x, y, layer, 0x1ff, .SetupCrabSprite)` — the record
    /// cleared, the position stores, layer `layer`, the Setup (whose `+0x80 = 8` is the layer the insert uses), `+0x48`
    /// re-stored — then `+0xb8 = 0x90000` when the claw is in water (M l. 74050–74056).
    static func makeLink(x: Int, y: Int, layer: Int32, clawInWater: Bool, water: (Int, Int) -> Bool) -> SpriteSlot {
        var k = SpriteWorld.newRecord(type: linkType, x: x, y: y, layer: Int16(truncatingIfNeeded: layer),
                                      handler: .crab, record: 0x1ff) { k in
            setupCrab(&k, reach: 0, water: water) { _, _, _, _ in nil }
        }
        if clawInWater { k.mode = 0x90000 }
        return k
    }

    // MARK: - the Crab's Handle

    /// The allowed target directions by type (raw `@100898b8..10089974`, M l. 74189–74212): 0x762 unless 8 < d < 0x1c;
    /// 0x763 9 < d < 0x1b; 0x764 0 < d < 0x12; 0x765 0x12 < d < 0x24; 0x766 any; every other type none.
    static func crabAllowed(type t: Int16, direction d: Int) -> Bool {
        switch t {
        case 0x762: return !(8 < d && d < 0x1c)
        case 0x763: return 9 < d && d < 0x1b
        case 0x764: return 0 < d && d < 0x12
        case 0x765: return 0x12 < d && d < 0x24
        case 0x766: return true
        default: return false
        }
    }

    /// `.HandleCrabSprite(s)` (M l. 74096–74293), unless `+0xe9` or `+0x1b2`: `.StandardSpriteHandles`; state 1 → the
    /// strike (`strike`); state 0 → d = `.FindDesiredDirectionGeneric(+0xe, the player sprite's +0xe)` (the claw's
    /// stored centre to the player's; `BloodSpray.direction`, claw → player: 0 right, 9 up, 18 left, 27 down — its own
/// labels, 0 left, 9 down, are of the player → claw vector) and the aim (`aim`);
    /// any other state nothing. Then every link i (0…n − 1) at `+0x150 + (+0xc − +0x150)·i / (n + 1) + 0x1e`, `+0x154
    /// + (+0xa − +0x154)·i / (n + 1) + 0x1e` (C division; `+0xc` / `+0xa` only — the links' 24.8 position is not
    /// written, M l. 74274–74286); HP < 1 → state 3 (nothing hurts it); `.StandardSpriteCleanup`. No gravity, no tile
    /// callback, no draw.
    public static func handleCrab(world w: SpriteWorld, id: Int,
                                  faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right }) {
        guard let s0 = w.active.record(id: id), !s0.dead, !s0.handleSkip else { return }
        w.standardSpriteHandles(id)
        guard var s = w.active.record(id: id) else { return }
        switch s.subtype {
        case 1:
            strike(&s)
        case 0:
            // `*_DAT_1009fdd8 + 0xe` — with no player sprite the original reads low memory [LOW]: (0, 0) here.
            let p = w.playerID.flatMap { w.active.record(id: $0) }?.centre ?? SpriteSlot.Point()
            let d = BloodSpray.direction(target: (v: Int16(truncatingIfNeeded: s.centre.y),
                                                  h: Int16(truncatingIfNeeded: s.centre.x)),
                                         from: (v: Int16(truncatingIfNeeded: p.y), h: Int16(truncatingIfNeeded: p.x)))
            aim(w, &s, direction: d)
        default:
            break
        }
        if let b = s.crabLinks {
            let n = Int(b.count)
            var i = 0
            while i < n {
                if i < b.links.count, let l = b.links[i] {
                    let ax = Int(s.classWord150), ay = Int(s.classWord154)
                    let x = h16(ax + (h16(s.x) - ax) * i / (n + 1) + 0x1e)
                    let y = h16(ay + (h16(s.y) - ay) * i / (n + 1) + 0x1e)
                    w.active.update(id: l) { k in
                        k.x = x
                        k.y = y
                    }
                }
                i += 1
            }
        }
        if s.hp < 1 { s.subtype = 3 }
        w.active.update(id: id) { $0 = s }
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
    }

    /// The aim, state 0 (M l. 74185–74272), toward direction `d`: allowed (`crabAllowed`) → the angle `+0x46` steps 5°
    /// toward T = 10·d — the short way while |angle − T| < 0xb4, else the other way (an exact half turn goes the long
    /// way) — wrapped into 0…0x167; type 0x763 → `+0x17e = 1` and `+0x1aa` = (angle + 0xb4) mod 0x168, every other
    /// type `+0x1aa` = angle; `+0xa6 < 1` → angle == T (whether d was allowed or not) and `.PEDistance(P.x − c.x, P.y −
    /// c.y) ≤ reach + 0x36` (`addi r0,r4,0x36 @10089ad4`) → `+0xa6 = 0`, state 1; else `+0xa6` − 1; face 0x762[0].
    static func aim(_ w: SpriteWorld, _ s: inout SpriteSlot, direction d: Int) {
        let target = Int(Int16(truncatingIfNeeded: d * 10))
        if crabAllowed(type: s.type, direction: d) {
            let a = Int(s.phase)
            if a < target {
                s.phase &+= abs32(a - target) < 0xb4 ? 5 : -5
            } else if target < a {
                s.phase &+= abs32(a - target) < 0xb4 ? -5 : 5
            }
            if s.phase < 0 {
                s.phase &+= 0x168
            } else if 0x167 < s.phase {
                s.phase &-= 0x168
            }
        }
        if s.type == 0x763 {
            s.mirrored = true
            s.rotation = Int16(truncatingIfNeeded: (Int(s.phase) + 0xb4) % 0x168)
        } else {
            s.rotation = s.phase
        }
        if s.counterA6 < 1 {
            let dist = StereoVolume.peDistance(Int(w.player.centreX) - h16(s.centre.x),
                                               Int(w.player.centreY) - h16(s.centre.y))
            if Int(s.phase) == target && dist <= Int(s.classTimer) + 0x36 {
                s.counterA6 = 0
                s.subtype = 1
            }
        } else {
            s.counterA6 &-= 1
        }
        s.face = face(clawSet, 0)
    }

    /// The strike, state 1 (M l. 74124–74184), 30 frames: t = ++`+0xa6`; t ≤ 5 → face 0x762[t] (the claw opens); else u
    /// = t − 5: u == 1 → `(+0x16c, +0x170)` = `FUN_100417bc((angle / 10 + 0x12) mod 0x24, (f32) reach)` truncated
    /// (`fctiwz`; `BloodSpray.vector`, index 0 = (−r, 0) — so the strike points along the aim); u ≤ 12 → `+0xc` /
    /// `+0xa` = anchor + v·u² / 0x90 (C division), the 24.8 position from them; 13 ≤ u ≤ 24 → face 0x762[max(0x11 − u,
    /// 0)], position = anchor + v·(0x90 − (u − 12)²) / 0x90; u ≥ 25 → state 0, `+0xa6 = 10`. The face is not written
    /// for u ≤ 12.
    static func strike(_ s: inout SpriteSlot) {
        s.counterA6 &+= 1
        let t = Int(s.counterA6)
        if t < 6 {
            s.face = face(clawSet, 4 < t ? 5 : t)
            return
        }
        let u = h16(t - 5)
        if u == 1 {
            let k = Int(s.phase) / 10 + 0x12
            let v = BloodSpray.vector(h16(k - (k / 0x24) * 0x24), magnitude: Float(s.classTimer))
            s.classWord16c = TileSolver.fctiwz(Double(v.x))
            s.classWord170 = TileSolver.fctiwz(Double(v.y))
        }
        func place(_ m: Int32) {
            let ax = Int(Int16(truncatingIfNeeded: s.classWord150)), ay = Int(Int16(truncatingIfNeeded: s.classWord154))
            s.x = h16(ax + Int(s.classWord16c &* m) / 0x90)
            s.y = h16(ay + Int(s.classWord170 &* m) / 0x90)
            s.x256 = Int32(Int16(truncatingIfNeeded: s.x)) << 8
            s.y256 = Int32(Int16(truncatingIfNeeded: s.y)) << 8
        }
        if u < 0xd {
            place(Int32(u) &* Int32(u))
        } else if u < 0x19 {
            var f = 0x11 - u
            if f < 1 { f = 0 }
            s.face = face(clawSet, f)
            let e = h16(t - 0x11)
            place(Int32(0x90 - e * e))
        } else {
            s.subtype = 0
            s.counterA6 = 10
        }
    }

    /// `.HandleCrabSegSprite(s)` (M l. 74296–74305): `+0xc0` = the cache single 0x767 — nothing else (no `+0xe9` test;
    /// the claw places it).
    public static func handleCrabSegment(world w: SpriteWorld, id: Int) {
        w.active.update(id: id) { $0.face = face(linkFace, 0) }
    }

    // MARK: - the Crab's hit

    /// `.HitCrabSprite(s, other)` (M l. 74308–74321): a player shot with `+0xa6 == 0` while the claw's HP > 0 →
    /// `.KillPlayerShot(o, 1, 1)` (the impact sound and effect; r29 never written here — nil [LOW]) and metal hit 303
    /// vol 0xab at the claw's centre (`.STPlay3DSound`, no draw). No damage, no Statue test, no other arm. The Crab is
    /// not in `.SmiteEnemies`' list (`Smite`).
    public static func hitCrab(_ w: SpriteWorld, id: Int, other oID: Int, lights: inout LightTable, effects: Int16 = 1,
                               faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                               faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard let s = w.active.record(id: id), let o = w.active.record(id: oID) else { return }
        guard BackgroundSprite.runs(o, .playerShot), o.counterA6 == 0, 0 < s.hp else { return }
        PlayerShotHits.kill(w, shot: oID, sound: true, effect: true, effects: effects, lights: &lights,
                            faceWidth: faceWidth, faceBounds: faceBounds, staleSlot: nil)    // nil: unverified [LOW]
        let c = w.active.record(id: id)?.centre ?? s.centre
        w.player.cue(PlayerCue(call: .threeD, snd: metalSound, priority: 1, volume: 0xab, position: c))
    }
}
