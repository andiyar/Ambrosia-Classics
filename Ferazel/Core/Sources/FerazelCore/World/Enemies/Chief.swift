import Foundation

/// The Goblin Chief (types 0x776…0x77f, level 18's boss; bosses-2 §3, phase6-boss-contracts §3): the Init's records
/// (`.InitChiefSprite`, M l. 75008–75028 — registered by 6A-CF in `CachedFaces`), the Setup (`.SetupChiefSprite @
/// 1008b538`, M l. 75031–75115), the Handle (`.HandleChiefSprite @ 1008b878`, M l. 75162–75441), the cry
/// (`.GoblinChiefRandomCry @ 1008b724`, M l. 75118–75159) and the tile callback (`.HitChiefTileSprite @ 1008c434`, M l.
/// 75535–75567) — 6A-CH1; his Hit (`.HitChiefSprite`, M l. 75444–75499) and Kill (`.KillChief`, M l. 75502–75532) —
/// 6A-CH2: the session's hit row and `EnemyCommon.killProc`'s `.chief` arm call them.
/// Field map: `+0x170` the boss flag (record p4) = `classWord170`; `+0x15c` the lane (1 left, 2 middle, 3 right) =
/// `classWord15c`; `+0x158` the throws left = `classWord158`; `+0x168` the starting HP = `bonusP4`; `+0x164` =
/// `launchSpeed`; `+0xf0` = `voicePitch` (stored 0x1e, no reader here); `+0x17e` facing right = `mirrored`; `+0xb0` the
/// state `subtype`; `+0x46` the frame counter `phase`; `+0xa6` the timer `counterA6`; `+0xb2` the hit counter
/// `subState`; `+0x14c` = `classTimer`; `+0x8d` = `burnSpeed`.
public enum Chief {
    /// `.InitChiefSprite` (M l. 75020–75026): four cache sets of 4 faces, 0x100 × 0xfe, 4 a row — `PTR_DAT_100a0da4`
    /// 0x777 throw A, `_DAT_100a0da0` 0x778 throw B, `_DAT_100a0d9c` 0x779 jump, `_DAT_100a0d98` 0x77a death — and the
    /// single `_DAT_100a0d94` 0x776 (standing), all under the cache flag 1. The Setup also marks `_DAT_100a083c`, the
    /// boulder set 0x77b (`.InitEnemyShotSprite`).
    public static let standing: Int16 = 0x776, throwA: Int16 = 0x777, throwB: Int16 = 0x778, jumpSet: Int16 = 0x779,
                      deathSet: Int16 = 0x77a

    // MARK: - Setup

    /// `.SetupChiefSprite(s)` (M l. 75031–75115) after `.InitSprite`, inside `.MTNewSprite` before `.MTInsertSprite`.
    /// `+8` / `+6` (`oldPosition`) hold the spawn point. In the dump's order: `+0x84` / `+0x86` 0, layer `+0x80 = 0xc`;
    /// the Handle `+0x4c` (`PTR_PTR_100a04bc`), hit `+0x5c` (`0d90`), tile callback `+0x1f8` (`0d8c`), Kill `+0x50`
    /// (`0d88`); the five records marked (`CachedFaces.markedRecords`); `+0x170` = record p4 (`+0xe`); gravity 0x276;
    /// `+0xc0 = 0` (no face until the first Handle frame); `+0x8d = 1` (the burn takes two rows a frame); p4 = 0 → HP
    /// 0x4b0; else HP 2000, `*_DAT_1009fed0 = 0` (returned) and `+0x88 = 0`; `+0x168` = HP; the re-seat `+0xc ← +8`,
    /// `+0xa ← +6`; hot rect SetRect(0x5e, 0x55, 0xa5, 0xd4); state `+0xb0` 6, `+0xb2 = 0`, `+0x46 = 2`, `+0x14c = 0`;
    /// `+0xa6 = R(10)` — drawn, then overwritten; lane `+0x15c = 2`; `+0x164 = 0`; `+0x17e = 1`; `+0xf0 = 0x1e`; `+0x46
    /// = 0`; `+0xa6 = 0`, then −40; the counting window; `+0x14` / `+0x1c` = `+8` / `+6` << 8. **No `+0x18a`** (his
    /// record follows him, `.UpdateSprites`) and **no `+0x1b4`**. Returns whether the Setup cleared "no boss alive".
    public static func setup(_ s: inout SpriteSlot, record p: Placement, rng: inout FastRand,
                             counting: inout EnemyCounting) -> Bool {
        s.particleOffsetY = 0                                           // `+0x84`
        s.particleOffsetX = 0                                           // `+0x86`
        s.layer = 0xc
        s.handler = .chief
        s.hasHit = true                                                 // `+0x5c` = `.HitChiefSprite` (6A-CH2)
        s.hasTileHit = true                                             // `+0x1f8` = `.HitChiefTileSprite`
        s.classWord170 = Int32(p.p4)                                    // `+0x170` = record `+0xe`
        s.gravity = 0x276
        s.face = nil                                                    // `+0xc0 = 0`
        s.burnSpeed = 1                                                 // `+0x8d = 1`
        var clears = false
        if s.classWord170 == 0 {
            s.hp = 0x4b0
        } else {
            s.hp = 2000
            clears = true                                               // `*_DAT_1009fed0 = 0`
            s.lightOverlay = false                                      // `+0x88 = 0`
        }
        s.bonusP4 = Int32(s.hp)                                         // `+0x168` = HP
        s.x = s.oldPosition.x                                           // `+0xc ← +8`
        s.y = s.oldPosition.y                                           // `+0xa ← +6`
        s.hotRect = IdleSprites.Rect(top: 0x55, left: 0x5e, bottom: 0xd4, right: 0xa5)
        s.subtype = 6
        s.subState = 0
        s.phase = 2
        s.classTimer = 0
        s.counterA6 = rng.next(10)                                      // drawn, then overwritten (M l. 75098–75107)
        s.classWord15c = 2                                              // the middle lane
        s.launchSpeed = 0                                               // `+0x164`
        s.mirrored = true                                               // `+0x17e = 1`
        s.voicePitch = 0x1e                                             // `+0xf0`
        s.phase = 0
        s.counterA6 = 0
        s.counterA6 = -40                                               // `0xffd8`
        counting.countIfWindow(&s)                                      // M l. 75108–75111
        s.x256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.y)) << 8
        return clears
    }

    // MARK: - Handle

    /// The snd slots (`SoundSlots`): `*_DAT_100a03f8` 414 (the jump), `*_DAT_1009fdec` 435 (the landing),
    /// `*_DAT_100a0268` 704 (the throw), `*_DAT_100a026c` 703 (the death).
    static let jumpSound: Int16 = 414, landSound: Int16 = 435, throwSound: Int16 = 704, deathSound: Int16 = 703

    /// The boulder `MTNewSprite(0x77b, …, PTR_PTR_100a0830)` — the EnemyShot Setup (`EnemyShot.chiefBoulder`).
    static let boulder: Int16 = EnemyShot.chiefBoulder

    /// f64 `0x100a1c88` 0.9 (dying), `0x100a1c98` 0.8 (a boulder thrown at a near player), `0x100a1c90` 0.5 (the
    /// unreachable nearer branch) — read in the binary's unpacked data section (3fec cccc cccc cccd, 3fe9 9999 9999
    /// 999a, 3fe0 0000 0000 0000).
    static let friction90 = Double(bitPattern: 0x3fec_cccc_cccc_cccd)
    static let nearThrow = Double(bitPattern: 0x3fe9_9999_9999_999a)
    static let nearerThrow = Double(bitPattern: 0x3fe0_0000_0000_0000)

    /// The stagger his landing gives a player on the ground (`*_DAT_100a0570 = 0x18`, M l. 75374).
    public static let stagger: Int16 = 0x18

    @inline(__always) static func h16(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }
    @inline(__always) static func face(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }

    /// The tile callback `+0x1f8` (nil = 0): `.HitChiefTileSprite @ 1008c434` (M l. 75535–75567), line for line the
    /// Warrior's and so the Crawler's body (`CrawlerRoach.hitTile`): FG (layer 1) or a kind < 100 → `.WallBounce(s,
    /// kind, &pos, vCentre, 0, +0x34, 0, 0)`; < 200 → `.WallBounceBG(kind − 100, …)`; water with `+0x140 == 0` →
    /// `.HandleUnderWater`.
    static func pass(_ s: SpriteSlot) -> TileHit? {
        guard s.hasTileHit else { return nil }
        return { solver, id, cell, kind, layer in CrawlerRoach.hitTile(solver, id: id, pos: cell, kind: kind, layer: layer) }
    }

    /// `.HandleChiefSprite @ 1008b878` (M l. 75162–75441). `+0xe9` or `+0x1b2` → nothing at all;
    /// `.StandardSpriteHandles`; the hot rect SetRect(0x58, 0x73, 0xac, 0xd2) (M l. 75190); the state (`+0xb0`): 4
    /// `dying`, 2 `throwing`, 1 `jump`, 3 `land`, 6 `wait`; 0, 5 and > 6 nothing. Then the tail (M l. 75419–75438): `+0xb2
    /// > 0` → `< 5` ? + 1 : 0 (a hit counter nothing reads); HP < 1 with state ≠ 4 → state 4, `+0x46 = +0xa6 = 0`, R(100)
    /// < 0x3c → `randomCry` first, then snd 703 (3D, 1, 0x100, no draw); `.ApplyGravityAndSeparateFromTiles` with
    /// `pass`; `.StandardSpriteCleanup`. No liquids test and no glow. His HP falls only by his Hit (`hit`).
    public static func handle(world w: SpriteWorld, id: Int, solver: TileSolver,
                              faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right }) {
        guard let s0 = w.active.record(id: id), !s0.dead, !s0.emerging else { return }
        w.standardSpriteHandles(id)
        w.active.update(id: id) { $0.hotRect = IdleSprites.Rect(top: 0x73, left: 0x58, bottom: 0xd2, right: 0xac) }
        guard var s = w.active.record(id: id) else { return }
        switch s.subtype {
        case 4: dying(&s)
        case 2: throwing(w, id: id, &s)
        case 1: jump(w, &s)
        case 3: land(w, &s)
        case 6: wait(w, &s)
        default: break
        }
        if 0 < s.subState {                                             // M l. 75419–75426
            s.subState = s.subState < 5 ? s.subState &+ 1 : 0
        }
        if s.hp < 1 && s.subtype != 4 {                                 // M l. 75427–75436
            s.subtype = 4
            s.phase = 0
            s.counterA6 = 0
            if w.rng.next(100) < 0x3c { randomCry(w, at: s.centre) }
            w.player.cue(PlayerCue(call: .threeD, snd: deathSound, priority: 1, volume: 0x100, position: s.centre))
        }
        w.active.update(id: id) { $0 = s }
        solver.applyGravityAndSeparate(id, pass: pass(s))
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
    }

    /// State 6, the wait (M l. 75407–75418): vx 0, face 0x776; the arena locked (`*PTR_DAT_1009fed4`) → `+0xa6` + 1;
    /// `+0xa6 > 15` on the ground (`+0xcd`) → `+0x46 = +0xa6 = 0`, state 1. From the Setup's −40 the first jump comes on
    /// the 56th locked frame; later ones on the 16th after a throw cycle.
    static func wait(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        s.vx = 0
        s.face = face(standing, 0)
        if w.arena.locked { s.counterA6 &+= 1 }
        if 0xf < s.counterA6 && s.onSprite != 0 {
            s.phase = 0
            s.counterA6 = 0
            s.subtype = 1
        }
    }

    /// State 1, the jump (M l. 75293–75361): i = the old `+0x46` / 2 (toward 0), `+0x46` + 1, i capped at 2, face
    /// 0x779[i]. The new `+0x46` == 3 (the third jump frame) → R(100) r, then R(6000) p, snd 414 pitched (0x14, 0xab,
    /// centre, 35000 + p), vy −0x2904, `+0xce = 0`, and the lane change by r (< 0x21 / < 0x42 / else): lane 2 → vx −0x700
    /// / 0 / +0x700, lane 1 → 0 / +0x700 / +0xe00, lane 3 → −0xe00 / −0x700 / 0, the lane = 1 / 2 / 3 (any other lane:
    /// no change). Else the new `+0x46` > 3 while falling (vy > 0) → `+0xa6 = 0`, `+0x46 = 0`, state 3.
    static func jump(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        let old = s.phase
        var i = Int(old) / 2
        s.phase = old &+ 1
        if 1 < i { i = 2 }
        s.face = face(jumpSet, i)
        if s.phase == 3 {
            let r = w.rng.next(100)
            let p = Int32(w.rng.next(6000))
            w.player.cue(PlayerCue(call: .threeDPitched, snd: jumpSound, priority: 0x14, volume: 0xab, position: s.centre,
                                   rate: p + 35000))
            s.vy = -0x2904                                              // `0xffffd6fc`
            s.groundKind = 0                                            // `+0xce = 0`
            let band = r < 0x21 ? 0 : (r < 0x42 ? 1 : 2)
            let lane = s.classWord15c
            let speeds: [Int32]?
            switch lane {
            case 2: speeds = [-0x700, 0, 0x700]
            case 1: speeds = [0, 0x700, 0xe00]
            case 3: speeds = [-0xe00, -0x700, 0]
            default: speeds = nil
            }
            if let v = speeds {
                s.vx = v[band]
                s.classWord15c = Int32(band + 1)
            }
        } else if 3 < s.phase && 0 < s.vy {
            s.counterA6 = 0
            s.phase = 0
            s.subtype = 3
        }
    }

    /// State 3, the landing (M l. 75363–75405): in the air (`+0xcd == 0`) face 0x779[3] and nothing else. On the ground:
    /// `+0x46 == 0` → R(12000), snd 435 pitched (1, 0xab, centre, 40000 + R), the shake `*_DAT_1009ffa0 = 0x16`, the
    /// player's `+0xce` or `+0xcd` set → the stagger `*_DAT_100a0570 = 0x18`, vx 0, face the player (facing right =
    /// player x > his centre x, the signed-compare idiom); faces `+0x46` 0–1 0x776, 2–4 0x777[0], 5–6 0x776; `+0x46 <
    /// 6` → + 1, else R(2) → `+0x158 = R + 2` throws, state 2, `+0x46 = +0xa6 = 0`.
    static func land(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        guard s.onSprite != 0 else {
            s.face = face(jumpSet, 3)
            return
        }
        if s.phase == 0 {
            let r = Int32(w.rng.next(12000))
            w.player.cue(PlayerCue(call: .threeDPitched, snd: landSound, priority: 1, volume: 0xab, position: s.centre,
                                   rate: r + 40000))
            w.shakeStore = 0x16
            if let pid = w.playerID, let p = w.active.record(id: pid), p.groundKind != 0 || p.onSprite != 0 {
                w.player.bossGrab = stagger
            }
            s.vx = 0
            s.mirrored = Int16(truncatingIfNeeded: s.centre.x) < w.player.centreX
        }
        let n = s.phase
        if n < 5 {
            if n < 2 {
                if -1 < n { s.face = face(standing, 0) }
            } else {
                s.face = face(throwA, 0)
            }
        } else if n < 7 {
            s.face = face(standing, 0)
        }
        if s.phase < 6 {
            s.phase &+= 1
        } else {
            s.classWord158 = Int32(w.rng.next(2)) + 2
            s.subtype = 2
            s.phase = 0
            s.counterA6 = 0
        }
    }

    /// State 2, the throw (M l. 75211–75292): i = `+0x46 >> 1` — face 0x777[i] (i < 4), 0x778[i − 4] (i < 8), else
    /// 0x776. `+0x46 == 7` → R(8000), snd 704 pitched (1, 0x5f, centre, 45000 + R), the boulder
    /// `MTNewSprite(0x77b, +0xc + (facing right ? 0xa1 : −0x11), +0xa + 0x33, +0x80 − 1, −1, .SetupEnemyShotSprite)` (its
    /// Setup draws R(5) and keeps the layer 0xb: in front of him, so not handled on its spawn frame); the boulder's
    /// `+0x17e` = his facing, `+0x46 = 15` (the dead `== 0x10` test after it), vx = R(500) + 4000, vy = −0x4b0 −
    /// R(0x96); |player x − his centre x| < 0xf0 → vx × 0.8, vy 2000 (else < 0x9b → vx × 0.5, vy 0xc80: unreachable
    /// after the first test); facing left → vx negated. No free record (known deviation 6, Ruling 16 widened): no Setup,
    /// so no R(5); the stores and reads through the null result are dropped, R(500) and R(0x96) still drawn. Then
    /// `+0x46 == 0` → face the player, `+0x158` − 1, below 1 → `+0xa6 = +0x46 = 0`, state 6, face 0x776, else `+0x46` +
    /// 1; `+0x46 < 0x12` → + 1; else `+0xa6 = +0x46 = 0`. A cycle is 19 frames; a landing's 2 or 3 give 1 or 2 throws.
    static func throwing(_ w: SpriteWorld, id: Int, _ s: inout SpriteSlot) {
        let i = Int(s.phase >> 1)
        if i < 4 {
            s.face = face(throwA, i)
        } else if i < 8 {
            s.face = face(throwB, i - 4)
        } else {
            s.face = face(standing, 0)
        }
        if s.phase == 7 {
            let dx = s.mirrored ? 0xa1 : -0x11
            let r = Int32(w.rng.next(8000))
            w.player.cue(PlayerCue(call: .threeDPitched, snd: throwSound, priority: 1, volume: 0x5f, position: s.centre,
                                   rate: r + 45000))
            let x = h16(h16(s.x) + dx), y = h16(h16(s.y) + 0x33)
            // No `SpriteSlot` copy across a spawn (`SpriteWorld` rule 2): write back, spawn, re-read.
            w.active.update(id: id) { $0 = s }
            let b = EnemyShot.spawn(w, type: boulder, x: x, y: y, layer: Int16(truncatingIfNeeded: s.layer - 1))
            s = w.active.record(id: id) ?? s
            let right = s.mirrored
            var vx = Int32(w.rng.next(500)) + 4000
            var vy = -0x4b0 - Int32(w.rng.next(0x96))
            var d = Int(w.player.centreX) - h16(s.centre.x)
            if d < 1 { d = -d }
            if d < 0xf0 {
                vx = TileSolver.fctiwz(Double(vx) * nearThrow)
                vy = 2000
            } else if d < 0x9b {
                vx = TileSolver.fctiwz(Double(vx) * nearerThrow)
                vy = 0xc80
            }
            if !right { vx = -vx }
            if let b {
                w.active.update(id: b) { t in
                    t.mirrored = right
                    t.phase = 0xf
                    t.vx = vx
                    t.vy = vy
                }
            }
        }
        let n = s.phase
        if n == 0 {
            s.mirrored = Int16(truncatingIfNeeded: s.centre.x) < w.player.centreX
            s.classWord158 &-= 1
            if s.classWord158 < 1 {
                s.counterA6 = 0
                s.phase = 0
                s.subtype = 6
                s.face = face(standing, 0)
            } else {
                s.subtype = 2
                s.phase &+= 1
            }
        } else if n < 0x12 {
            s.phase = n &+ 1
        } else {
            s.counterA6 = 0
            s.phase = 0
        }
    }

    /// State 4, dying (M l. 75193–75209): vx × 0.9; face 0x77a[min(`+0x46 >> 2`, 3)]; `+0x46` + 1, capped at 0x10;
    /// `+0xa6` + 1; at 0x14 `+0x1a2 = 1` (the burn, two rows a frame by `+0x8d`; its end calls the Kill proc `+0x50`,
    /// `.KillChief` — `kill`, through `EnemyCommon.killProc`).
    static func dying(_ s: inout SpriteSlot) {
        s.vx = TileSolver.fctiwz(Double(s.vx) * friction90)
        var i = Int(s.phase >> 2)
        if 2 < i { i = 3 }
        s.face = face(deathSet, i)
        s.phase &+= 1
        if 0x10 < s.phase { s.phase = 0x10 }
        s.counterA6 &+= 1
        if s.counterA6 == 0x14 { EnemyCommon.startBurn(&s) }
    }

    /// `.GoblinChiefRandomCry(s) @ 1008b724` (M l. 75118–75159): R(100) r (always drawn); then only while none of 465,
    /// 466, 467 plays (`FUN_100916dc`, global over every voice, tested in that order through `SoundVoices`): r < 0x29 →
    /// R(10000), snd 467 vol 0xc9; r < 0x47 → R(10000), 466 vol 0xab; else R(10000), 465 vol 0xab — each
    /// `.STPlay3DSoundPitched(snd, 1, vol, +0xe, 42000 + R)`. Not `EnemyCommon`'s goblin cry (that one draws R(500)).
    public static func randomCry(_ w: SpriteWorld, at centre: SpriteSlot.Point) {
        let r = w.rng.next(100)
        for snd in [EnemyCommon.growl1, EnemyCommon.growl2, EnemyCommon.taunt] where w.isSoundPlaying(snd) { return }
        let snd: Int16, volume: Int16
        if r < 0x47 {
            if r < 0x29 {
                (snd, volume) = (EnemyCommon.taunt, 0xc9)
            } else {
                (snd, volume) = (EnemyCommon.growl2, 0xab)
            }
        } else {
            (snd, volume) = (EnemyCommon.growl1, 0xab)
        }
        let rate = Int32(w.rng.next(10000))
        w.player.cue(PlayerCue(call: .threeDPitched, snd: snd, priority: 1, volume: volume, position: centre,
                               rate: rate + 42000))
    }

    // MARK: - Hit

    /// snd slots: `*_DAT_100a0274` 701 (Crawler Ouch, the hurt above HP 200 and the crush), `*_DAT_100a0270` 702 (the
    /// hurt at HP ≤ 200), `*_DAT_1009fd68` 453 (the boss-kill thunder).
    static let ouchSound: Int16 = 701, uhOhSound: Int16 = 702, thunderSound: Int16 = 453

    /// `.HitChiefSprite(s, other) @ 1008c0e0` (M l. 75444–75499; raw `1008c0e0..1008c318`). Every Handle comparison is
    /// `+0x4c ==` (`BackgroundSprite.runs`):
    /// - a player shot (`PTR_PTR_100a04e8`) with `+0xa6 == 0` while HP `+0xa4` ≥ 1 → `.KillPlayerShot(o, 0, 0)` — silent,
    ///   no effect — **first**; its stale-slot path (`lha r3,0x9a(r29)`, `PlayerShotHits.kill`) reads the Chief's own
    ///   `+0x9a` (`or r29,r3,r3`, raw `1008c0f8`: r29 = s). Then `.HurtSprite(s, o +0xa4, 0, 0, 2, 8)` — the shot's damage
    ///   read after the kill; refused (`+0x116 ≠ 0`) → return: the shot is wasted. On a hurt: `+0x116 = 15`, `+0xb2 = 1`,
    ///   `.BloodSpray(s, o, 0x28, 400, 0x96, 2)` (no HP test), HP < 0xc9 → `.STPlay3DSound(702, 1, 0x100, +0xe)`, else HP
    ///   > 0 → 701; R(100) < 0x3c → `.GoblinChiefRandomCry`. A shot with `+0xa6 ≠ 0`, or the Chief at HP ≤ 0, falls to
    ///   the solid test (which a shot never passes). Fireball 100 → 20 landed hits for 2000 HP;
    /// - else a Statue (`PTR_PTR_100a01f8`) or a Box (`PTR_PTR_100a0484`): the Warrior's crush test —
    ///   `.PlatformBounce(s, o, s's hot-rect centre offset, 0, s +0x34, 0)` == 2 and (o `+0x2c` > 0 or s `+0xce` ≠ 0), both read after the bounce
    ///   → `.HurtSprite(s, 200, (i16)(o.vx >> 1), −1000, 2, 8)` (whether or not it lands), `+0xf0 = 0`, `.KillBox(o)` (its
    ///   own draws), R(10000) → `.STPlay3DSoundPitched(701, 1, 0x100, s +0xe, 42000 + R)`, then `.GoblinChiefRandomCry`
    ///   (R(100) always, [+ R(10000)]).
    /// No environmental-hazard arm.
    public static func hit(_ w: SpriteWorld, id: Int, other oID: Int, lights: inout LightTable, effects: Int16 = 1,
                           faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                           faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard let s = w.active.record(id: id), let o = w.active.record(id: oID) else { return }
        let runs = BackgroundSprite.runs
        if runs(o, .playerShot) && o.counterA6 == 0 && 0 < s.hp {
            PlayerShotHits.kill(w, shot: oID, sound: false, effect: false, effects: effects, lights: &lights,
                                faceWidth: faceWidth, faceBounds: faceBounds, staleSlot: s.light)
            let damage = (w.active.record(id: oID) ?? o).hp               // `lha r4,0xa4(r30)` after the kill
            guard HurtSprite.apply(w, id: id, damage: damage, dvx: 0, dvy: 0, invulnerable: 2, flash: 8) else { return }
            w.active.update(id: id) { c in
                c.invulnerable = 0xf                                        // `+0x116 = 15`
                c.subState = 1                                              // `+0xb2 = 1`
            }
            BloodSpray.spray(w, victim: id, attacker: oID, count: 0x28, speed: 400, spread: 0x96, kind: 2)
            guard let u = w.active.record(id: id) else { return }
            if u.hp < 0xc9 {
                w.player.cue(PlayerCue(call: .threeD, snd: uhOhSound, priority: 1, volume: 0x100, position: u.centre))
            } else if 0 < u.hp {
                w.player.cue(PlayerCue(call: .threeD, snd: ouchSound, priority: 1, volume: 0x100, position: u.centre))
            }
            if w.rng.next(100) < 0x3c { randomCry(w, at: u.centre) }
        } else if runs(o, .statue) || runs(o, .box) {
            let r = s.hotRect
            let centre = SpriteSlot.Point(x: h16(r.left + h16((r.right - r.left) >> 1)),
                                          y: h16(r.top + h16((r.bottom - r.top) >> 1)))
            let b = w.platformBounce(mover: id, solid: oID, centre: centre, factor: 0, rect: r, bounce: false)
            guard b == 2, let m = w.active.record(id: id), let solid = w.active.record(id: oID),
                  0 < solid.vy || m.groundKind != 0 else { return }
            HurtSprite.apply(w, id: id, damage: 200, dvx: Int16(truncatingIfNeeded: solid.vx >> 1), dvy: -1000,
                             invulnerable: 2, flash: 8)
            w.active.update(id: id) { $0.voicePitch = 0 }                  // `+0xf0 = 0`
            BoxSprite.killBox(w, id: oID)
            let at = (w.active.record(id: id) ?? m).centre                 // `+0xe`
            let r1 = Int32(w.rng.next(10000))
            w.player.cue(PlayerCue(call: .threeDPitched, snd: ouchSound, priority: 1, volume: 0x100, position: at,
                                   rate: r1 + 42000))
            randomCry(w, at: at)
        }
    }

    // MARK: - Kill

    /// `.KillChief(s) @ 1008c350` (M l. 75502–75532), the Kill proc `+0x50` — `.KillWarrior` line for line: the counting
    /// head (`+0xe9 == 0 ∧ +0x1b5` → live − 1 and `G+0x306+2L` + 1 — guarding the count only), `+0xe9 = 1`, `+0xea = 1`
    /// (his record cleared by `.UpdateSprites`); then with `+0x170 ≠ 0` the boss-kill tail:
    /// `.STPlay3DSoundPitched(453, 1, 0x100, +0xe, 48000)` (no draw), the shake `*_DAT_1009ffa0 = 0x1e`, the mask flash
    /// `*_DAT_100a00fc = 3`, `*_DAT_1009fed0 = 1` (no boss alive: level 18's gate 2940 p1 −1 opens from its next Handle,
    /// the loop rule fades to track 30). No score. A second call counts nothing and replays the tail.
    static func kill(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        w.enemies.kill(&s, globals: &w.globals, level: w.levelIndex, forGood: true)
        guard s.classWord170 != 0 else { return }
        w.player.cue(PlayerCue(call: .threeDPitched, snd: thunderSound, priority: 1, volume: 0x100, position: s.centre,
                               rate: 48000))
        w.shakeStore = 0x1e
        w.flash.count = 3
        w.arena.noBossAlive = 1
    }
}
