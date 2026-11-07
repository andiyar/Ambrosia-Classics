import Foundation

/// The Walker class — the goblins (WK1; enemies-ground §3.1–§3.5, §3.7, §3.8; enemies-ground-2 §1): `.InitWalkerSprite
/// @ 10066c5c` (M l. 56746–56772, the faces), `.SetupWalkerSprite @ 10067318` (M l. 56898–57100, `setup`),
/// `.HandleWalkerSprite @ 100683b8` (M l. 57507–58471, `handle`), `.PopupGoblinCoins @ 10067edc` (M l. 57348–57506,
/// `popupCoins`), `.HitWalkerSprite @ 1006a260` (M l. 58506–58611, `hit`), `.KillWalker @ 1006a6cc` (M l. 58612–58633,
/// `EnemyCommon.killProc`), `.HitWalkerTileSprite @ 1006a740` (M l. 58634–58696, `hitTile`). The Handle dispatches on
/// the **exact** types 1700 (the thrower), 1705 (the spear guard), 1760 (the boulder thrower, `boulderArm`; WK2) and
/// 1750 (the Ax goblin, `AxGoblin`; WK2), each inside the shared prologue and tail; every other Walker type only falls
/// and takes hazards and never dies (no arm, no death entry — transcribed, not fixed).
///
/// Fields (`SpriteSlot`): `+0xb0` the state `subtype` (1 walk, 2 stand / throw / thrust, 4 dying, 5 guard); `+0xb2`
/// the guard / death counter `subState`; `+0xb4` the turn step `classWordB4`; `+0x46` the walk / throw counter
/// `phase`; `+0xa6` the throw cooldown `counterA6`; `+0x14c` the throwing distance `classTimer`; `+0x150` −1
/// `classWord150`; `+0x154` `classWord154` (no reader); `+0x158` the cooldown base `classWord158`; `+0x15c` the
/// dry-corpse frames `classWord15c`; `+0x16c` the wall hits `classWord16c`; `+0x170` the wall-hit lockout
/// `classWord170`; `+0x100` tier 4 `classWord100`; `+0xf0` the goblin voice `voicePitch`; `+0x17c` the first Handle
/// `setupDone`.
public enum Walker {
    /// The types the Handle dispatches on (`+4 ==`).
    public static let thrower: Int16 = 0x6a4, spearGuard: Int16 = 0x6a9, axGoblin: Int16 = 0x6d6,
                      boulderThrower: Int16 = 0x6e0

    /// The sheets (`.InitWalkerSprite`, M l. 56755–56770): the singles 0x6a4 (1700) and 0x6d6 (1750) and the cache
    /// sets 0x6a5 walk (8 × 100×0x50, 4 a row), 0x6a6 throw (6 × 100×0x50), 0x6a9 guard (3 × 0xcc×0x59, one a row),
    /// 0x6aa turn (2), 0x6ab thrust (9), 0x6d7…0x6da (1750, `AxGoblin`), 0x6e0 (1760, 9 × 0x54×0x5c); the boot set 0x6a8 the
    /// death (8 × 0x5e×0x50, `BootFaces`). The renderer loads the cache sets the Setups mark
    /// (`CachedFaces.sheets(markedBy:)`; the Handles' four in `CachedFaces.handleSets`).
    public static let walkSet: Int16 = 0x6a5, throwSet: Int16 = 0x6a6, deathSet: Int16 = 0x6a8, turnSet: Int16 = 0x6aa,
                      thrustSet: Int16 = 0x6ab, axDeathSet: Int16 = 0x6da

    /// The snd slots (`SoundSlots`): `*_DAT_100a0268` 704 'throw', `*_DAT_100a0418` 304 'swoosh big', `*_DAT_100a041c`
    /// 303 'metal hit', `*_DAT_100a026c` 703 'crawler death', `*_DAT_100a0284` 601 'hit ground soft', `*_DAT_100a0340`
    /// 469 'goblindie'.
    static let throwSound: Int16 = 704, thrustSound: Int16 = 304, blockSound: Int16 = 303, deathThud: Int16 = 703,
               landSound: Int16 = 601, dieCry: Int16 = 469

    /// 0.9 (f64 `0x100a1ab8`) and 0.7 (`0x100a1ab0`): the ground friction of the dying 1700 and the guard.
    static let friction9 = Double(bitPattern: 0x3fec_cccc_cccc_cccd)
    static let friction7 = Double(bitPattern: 0x3fe6_6666_6666_6666)
    /// 0.8 (f64 `0x100a1928`): `.SetSpriteSpeed`'s in-water factor.
    static let waterFactor = Double(bitPattern: 0x3fe9_9999_9999_999a)

    @inline(__always) static func h16(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }
    @inline(__always) static func face(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }

    /// The live placement record `+0x48` (`*_DAT_100a0058 + 16·i`; nil for −1 or outside the table — the original
    /// reads whatever precedes the table [LOW: every Walker on levels 1–5 is placed]).
    static func record(_ w: SpriteWorld, _ s: SpriteSlot) -> Placement? {
        let i = Int(s.recordIndex)
        return w.records.indices.contains(i) ? w.records[i] : nil
    }

    // MARK: - Setup

    /// The tier by record p3 (`.SetupWalkerSprite` M l. 57008–57078; enemies-ground §3.1): `+0x158`, HP (the 1750
    /// column for type 0x6d6 exactly), `+0xb8` and `+0x100`. p3 0, ≥ 7 or < 0: nil (the defaults 8 / 500 / 0 / 0).
    public static func tier(p3: Int16, type t: Int16) -> (cooldown: Int32, hp: Int16, mode: UInt32, immune: Int32)? {
        let ax = t == axGoblin
        switch p3 {
        case 1: return (0x10, ax ? 500 : 0xfa, 0x10010, 0)
        case 2: return (6, ax ? 0x4b0 : 0x2a3, 0x10011, 0)
        case 3: return (0xd, ax ? 0x690 : 0x3b6, 0x10012, 0)
        case 4: return (4, ax ? 2000 : 0x5dc, 0x10013, 1)
        case 5: return (10, ax ? 0x5dc : 0x352, 0x10014, 0)
        case 6: return (6, ax ? 0x546 : 0x2ee, 0x10015, 0)
        default: return nil
        }
    }

    /// `.SetupWalkerSprite(s)` (M l. 56898–57100) for the types levels 1–5 place (0x6a4, 0x6a9, 0x6e0…0x6e9) and the
    /// 1750 range 0x6d6…0x6df (WK2; first placed on level 10 — the caller picks the face): `.InitSprite`; `+0x84`/`+0x86`
    /// 0; layer 4; the Walker Handle, hit, tile callback and Kill proc; `+0xa6` 0; `+0x158` 8; state 2 (0x6a4, 0x6d6) or
    /// 5; flip 1 for 0x6e0 only; `+0x17c` 0; gravity 0x151; HP 500; `+0xc ← +8`, `+0xa ← +6`; `+0xf0 = 2·R(0x5fff) +
    /// 0xbfff`; by type the flip rule (0x6e0…0x6e9: `+0xc + 0x32 <` playerX; the others: playerX `< +0xc + 0x32`), the
    /// hot rect (0x6a4 (0x28, 10, 0x3c, 0x46), 0x6a9 (0x4c, 10, 0x7c, 0x47), 0x6d6… (0x5e, 0x23, 0x7f, 0x5c) with state
    /// 1 (M l. 56997–57011), 0x6e0… (0x17, 0x1e, 0x38, 0x55) — `SetRect(l, t, r, b)`); the tier (`tier`); `+0x14c
    /// = 120 + R(0x46)`, `+0x150` −1, `+0x154 = 1000 + R(400)`; p4 ≠ 0 → the idle margins 0x5f4; the counting window
    /// (`EnemyCounting.countIfWindow`); the 24.8 position from `+8`/`+6`. No `+0x188`…`+0x18b` / `+0xea` store.
    /// - Parameter playerX: `*_DAT_1009fd94` at the call.
    public static func setup(_ s: inout SpriteSlot, record p: Placement, playerX: Int, rng: inout FastRand,
                             counting: inout EnemyCounting) {
        let t = s.type
        s.particleOffsetY = 0
        s.particleOffsetX = 0
        s.layer = 4                                                     // `+0x80 = 4` (M l. 56930)
        s.handler = .walker
        s.hasHit = true                                                 // `+0x5c` = `.HitWalkerSprite`
        s.hasTileHit = true                                             // `+0x1f8` = `.HitWalkerTileSprite`
        s.counterA6 = 0
        s.classWord158 = 8
        s.subtype = (t == thrower || t == axGoblin) ? 2 : 5
        s.mirrored = t == boulderThrower
        s.setupDone = false
        s.gravity = 0x151
        s.hp = 500
        s.oldPosition = SpriteSlot.Point(x: s.x, y: s.y)                // `+8` / `+6` = the spawn position
        s.voicePitch = Int32(rng.next(0x5fff)) * 2 + 0xbfff             // `+0xf0` (raw `1006740c`)
        func rect(_ l: Int, _ top: Int, _ r: Int, _ b: Int) {
            s.hotRect = IdleSprites.Rect(top: top, left: l, bottom: b, right: r)
        }
        let px = playerX
        switch t {
        case thrower:
            if px < h16(s.x) + 0x32 { s.mirrored = true }
            rect(0x28, 10, 0x3c, 0x46)
        case spearGuard:
            if px < h16(s.x) + 0x32 { s.mirrored = true }
            rect(0x4c, 10, 0x7c, 0x47)
        case 0x6e0...0x6e9:
            if h16(s.x) + 0x32 < px { s.mirrored = true }
            rect(0x17, 0x1e, 0x38, 0x55)
        case 0x6d6...0x6df:
            s.subtype = 1
            if px < h16(s.x) + 0x32 { s.mirrored = true }
            rect(0x5e, 0x23, 0x7f, 0x5c)
        default:
            break                                                       // 0x6a5…0x6a8, 0x6aa…0x6d5: no arm (none placed)
        }
        if let k = tier(p3: p.p3, type: t) {
            s.classWord158 = k.cooldown
            s.hp = k.hp
            s.mode = k.mode
            if k.immune != 0 { s.classWord100 = k.immune }
        }
        s.classTimer = Int32(rng.next(0x46)) + 0x78                     // `+0x14c` (raw `10067760`)
        s.classWord150 = -1
        s.classWord154 = Int32(rng.next(400)) + 1000                    // `+0x154` (raw `10067780`)
        if p.p4 != 0 { s.margins = SpriteSlot.Margins(left: 0x5f4, right: 0x5f4, top: 0x5f4, bottom: 0x5f4) }
        counting.countIfWindow(&s)                                      // M l. 57090–57094
        s.x256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.y)) << 8
    }

    /// `.SetSpriteSpeed(s, vx, vy) @ 100372b0` (M l. 32815–32830): in water (`+0x11c` only) both become `(i16)(int)(v ·
    /// 0.8)`; vx, vy stored.
    static func setSpriteSpeed(_ s: inout SpriteSlot, _ vx: Int16, _ vy: Int16) {
        var a = vx, b = vy
        if s.waterRow != 0 {
            a = Int16(truncatingIfNeeded: TileSolver.fctiwz(Double(a) * waterFactor))
            b = Int16(truncatingIfNeeded: TileSolver.fctiwz(Double(b) * waterFactor))
        }
        s.vx = Int32(a)
        s.vy = Int32(b)
    }

    /// The guards' and the dying 1700's ground friction: |vx| ≤ 0x80 → 0, else `(int)(vx · f)`.
    static func friction(_ s: inout SpriteSlot, _ f: Double) {
        let m = s.vx < 1 ? 0 &- s.vx : s.vx
        s.vx = m < 0x81 ? 0 : TileSolver.fctiwz(Double(s.vx) * f)
    }

    // MARK: - Handle

    /// The tile callback a Walker's `+0x1f8` names (nil = 0) — also the corpse raft's (`walkerCallbacks`).
    public static func pass(_ s: SpriteSlot) -> TileHit? {
        guard s.hasTileHit else { return nil }
        return { solver, id, cell, kind, layer in hitTile(solver, id: id, pos: cell, kind: kind, layer: layer) }
    }

    /// `.HandleWalkerSprite(s)` (M l. 57507–58471), unless `+0xe9` or `+0x1b2`:
    /// 1. `.StandardSpriteHandles`; the first Handle (`+0x17c == 0`): `+0x17c = 1`, `+0xb4` = flip ? −3 : 3; layer
    ///    `+0x80` = 0xb; `+0x170 > 0` → `+0x16c = 0`, `+0x170` − 1; not dying → `.GoblinRandomCry`;
    /// 2. the exact-type arm: 1700 (`throwerArm`), 1705 (`spearGuardArm`), 1750 (`AxGoblin.arm`), 1760 (`boulderArm`),
    ///    others none;
    /// 3. the tail (`tail`).
    /// Returns the `.ChangeLightFace` ops the coins' Handles made (`popupCoins`; none for coins and bags).
    /// - Parameters: `faceWidth` (the Cleanups' face `+6`) and `faceBounds` (face `+8`: the coins' trigger row and
    ///   origin) — Core has no face records; `lights` / `effects` reach the shots' and the bags' Setups.
    @discardableResult
    public static func handle(world w: SpriteWorld, id: Int, solver: TileSolver, lights: inout LightTable,
                              effects: Int16, faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                              faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) -> [DrawOp] {
        guard let s0 = w.active.record(id: id), !s0.dead, !s0.handleSkip else { return [] }
        w.standardSpriteHandles(id)
        w.active.update(id: id) { s in
            if !s.setupDone {
                s.setupDone = true
                s.classWordB4 = s.mirrored ? -3 : 3
            }
            s.layer = 0xb
            if 0 < s.classWord170 {
                s.classWord16c = 0
                s.classWord170 &-= 1
            }
        }
        if let s = w.active.record(id: id), s.subtype != 4 { EnemyCommon.goblinRandomCry(w, id: id) }
        guard let s1 = w.active.record(id: id) else { return [] }
        switch s1.type {
        case thrower: throwerArm(w, id: id)
        case spearGuard: spearGuardArm(w, id: id)
        case axGoblin: AxGoblin.arm(w, id: id)
        case boulderThrower: boulderArm(w, id: id)
        default: break                                      // other Walker types: no arm (enemies-ground §3.2)
        }
        return tail(w, id: id, solver: solver, lights: &lights, effects: effects, faceWidth: faceWidth,
                    faceBounds: faceBounds)
    }

    /// The 1700 arm (M l. 57584–57814) by state `+0xb0`, then (not dying) the facing: `+0x10 <` P.x → flip 0,
    /// P.x `< +0x10` → flip 1 (P = `*_DAT_1009fd94`, the player's centre x).
    /// - 1 (walk), on ground (`+0xce`): target = P.x ± `+0x14c` (+ while P.x `<` the centre x `+0x10`); the centre
    ///   left of target − 25 → `.SetSpriteSpeed(1000, 0x200)`, right of target + 25 → `(−1000, 0x200)`, the counter
    ///   `+0x46` stepping −1 / +1 (P left) or +1 / −1 (P right — backwards when walking away from the facing); inside:
    ///   `+0x46` 0 or 3 → state 2, `+0x46 = 0`, speed (0, 0); else `+0x46` steps by vx (P left: vx < 0 → +1, else −1;
    ///   P right: vx < 1 → −1, else +1). Wrapped 0…15; face 0x6a5[`+0x46 >> 1`].
    /// - 2: gravity 0x151; on ground: outside target ± 25 and record p1 ≠ 1 → `+0x46 = 0`, state 1; else face 0x6a4,
    ///   vx halved (toward zero); cooldown `+0xa6 == 0` → face 0x6a6[`+0x46 >> 1`], `+0x46` + 1, at 8 snd 704,
    ///   `+0xa6 = +0x158 + R(26)`, `MTNewSprite(flip, +0xc + (flip ? 0 : 0x50) + 10, +0xa + 0x14, 0, −1,
    ///   .SetupEnemyShotSprite)` with vx ±(0x618 + R(0x1c2)), vy −(0x334 + R(0x1c2)), and R(100) > 0x5a → |vx| +=
    ///   R(0x578), vy −= R(0x578); else `+0xa6` − 1 and the throw finishing (`+0x46 < 1` → face 0x6a4, else + 1, face
    ///   0x6a6[`+0x46 >> 1`], past 11 → 0 and face 0x6a4).
    /// - 4 (dying, `dying`).
    static func throwerArm(_ w: SpriteWorld, id: Int) {
        guard let s0 = w.active.record(id: id) else { return }
        let px = w.player.centreX
        let state = s0.subtype
        if state == 1 {
            if s0.groundKind != 0 {
                w.active.update(id: id) { s in
                    let cx = Int16(truncatingIfNeeded: s.centre.x)
                    let d = Int16(truncatingIfNeeded: s.classTimer)
                    if px < cx {
                        let target = px &+ d
                        if cx < target &- 0x19 {
                            s.phase &-= 1
                            setSpriteSpeed(&s, 1000, 0x200)
                        } else if target &+ 0x19 < cx {
                            s.phase &+= 1
                            setSpriteSpeed(&s, -1000, 0x200)
                        } else if s.phase == 0 || s.phase == 3 {
                            s.subtype = 2
                            s.phase = 0
                            setSpriteSpeed(&s, 0, 0)
                        } else if s.vx < 0 {
                            s.phase &+= 1
                        } else {
                            s.phase &-= 1
                        }
                    } else {
                        let target = px &- d
                        if cx < target &- 0x19 {
                            s.phase &+= 1
                            setSpriteSpeed(&s, 1000, 0x200)
                        } else if target &+ 0x19 < cx {
                            s.phase &-= 1
                            setSpriteSpeed(&s, -1000, 0x200)
                        } else if s.phase == 0 || s.phase == 3 {
                            s.subtype = 2
                            s.phase = 0
                            setSpriteSpeed(&s, 0, 0)
                        } else if s.vx < 1 {
                            s.phase &-= 1
                        } else {
                            s.phase &+= 1
                        }
                    }
                    if s.phase < 0 {
                        s.phase = 0xf
                    } else if 0xf < s.phase {
                        s.phase = 0
                    }
                    s.face = face(walkSet, Int(s.phase >> 1))
                }
            }
        } else if state == 2 {
            w.active.update(id: id) { $0.gravity = 0x151 }
            if s0.groundKind != 0 {
                let p1 = record(w, s0)?.p1 ?? 0
                var throwNow = false
                w.active.update(id: id) { s in
                    let cx = Int16(truncatingIfNeeded: s.centre.x)
                    let d = Int16(truncatingIfNeeded: s.classTimer)
                    let target = px &+ (px < cx ? d : 0 &- d)
                    if (cx < target &- 0x19 || target &+ 0x19 < cx) && p1 != 1 {
                        s.phase = 0
                        s.subtype = 1
                        return
                    }
                    s.face = face(thrower, 0)
                    if s.vx != 0 { s.vx = s.vx / 2 }                    // `srawi 1; addze`: toward zero
                    if s.counterA6 == 0 {
                        s.face = face(throwSet, Int(s.phase >> 1))
                        s.phase &+= 1
                        throwNow = s.phase == 8
                    } else {
                        s.counterA6 &-= 1
                        if s.phase < 1 {
                            s.face = face(thrower, 0)
                        } else {
                            s.phase &+= 1
                            s.face = face(throwSet, Int(s.phase >> 1))
                            if 0xb < s.phase {
                                s.phase = 0
                                s.face = face(thrower, 0)
                            }
                        }
                    }
                }
                if throwNow { throwAxe(w, id: id) }
            }
        } else if state == 4 {
            dying(w, id: id)
        }
        w.active.update(id: id) { s in
            guard s.subtype != 4 else { return }
            let cx = Int16(truncatingIfNeeded: s.centre.x)
            if cx < px {
                s.mirrored = false
            } else if px < cx {
                s.mirrored = true
            }
        }
    }

    /// The 1700's throw at `+0x46 == 8` (M l. 57674–57717): snd 704 (`.STPlay3DSound`, no draw), `+0xa6 = +0x158 +
    /// R(26)`, the shot of type flip (0 or 1, `EnemyShot`) with its velocities. No free record (Ruling 16): no Setup,
    /// the stores dropped, the velocity draws still made.
    static func throwAxe(_ w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id) else { return }
        w.player.cue(PlayerCue(call: .threeD, snd: throwSound, priority: 1, volume: 0x100, position: s.centre))
        let r = w.rng.next(0x1a)
        w.active.update(id: id) { $0.counterA6 = Int16(truncatingIfNeeded: $0.classWord158) &+ r }
        let flip = s.mirrored
        let x = h16(h16(s.x) + (flip ? 0 : 0x50) + 10), y = h16(h16(s.y) + 0x14)
        let shot = EnemyShot.spawn(w, type: flip ? 1 : 0, x: x, y: y, layer: 0)
        var vx = Int32(w.rng.next(0x1c2))
        vx = flip ? -0x618 - vx : vx + 0x618
        var vy = -0x334 - Int32(w.rng.next(0x1c2))
        if 0x5a < w.rng.next(100) {
            let a = Int32(w.rng.next(0x578))
            vx = flip ? vx - a : vx + a
            vy -= Int32(w.rng.next(0x578))
        }
        if let shot {
            w.active.update(id: shot) { t in
                t.vx = vx
                t.vy = vy
            }
        }
    }

    /// The 1700 path's dying state 4 (M l. 57750–57801; enemies-ground §3.8, enemies-ground-2 §1.1): `+0xea = 1`; face
    /// 0x6a8[min(`+0xb2` / 3, 7)] (the boot set); `+0xb2 == 22` → vy − 800; `+0xb2 == 0` → snd 703 vol 0x100; layer
    /// `+0x80` 1; the 0.9 friction; `+0xb2` + 1; past 50: dry (`+0x11c == 0 ∧ +0x120 == 0`) → `+0x15c` + 1 (past 2
    /// with `+0x1a2 < 1` → the burn starts, `+0x1a2 = 1`), the record's `+4` cleared, and the player's centre at least
    /// 451 px across or 351 px down / up → `.KillWalker`; wet → the corpse raft: counted (as `.KillWalker` but no
    /// `+0xe9`), the Platform Handle, rect (0x10, 0x35, 0x42, 0x47), `+0x1a0` −6, one-way, `+0xa6` 0, `+0x116` 0,
    /// `+0x17c` 1, `+0x13a` 0x20, `+0x138` 0x3c — the hit, tile and Kill callbacks kept (`walkerCallbacks`).
    static func dying(_ w: SpriteWorld, id: Int) {
        guard var s = w.active.record(id: id) else { return }
        s.killedForGood = true                                          // `+0xea = 1` (M l. 57740)
        let b2 = s.subState
        var f = b2 / 3
        if b2 == 0x16 { s.vy &-= 800 }
        if 7 < f { f = 7 }
        if b2 == 0 { w.player.cue(PlayerCue(call: .threeD, snd: deathThud, priority: 1, volume: 0x100, position: s.centre)) }
        s.face = face(deathSet, Int(f))
        s.layer = 1
        friction(&s, friction9)
        s.subState &+= 1
        guard 0x32 < s.subState else {
            w.active.update(id: id) { $0 = s }
            return
        }
        if s.waterRow == 0 && s.lastWater == 0 {
            s.classWord15c &+= 1
            if 2 < s.classWord15c && s.burnRow < 1 { s.burnRow = 1 }
            w.active.update(id: id) { $0 = s }
            let i = Int(s.recordIndex)                                  // the record's `+4 = 0` (M l. 57773)
            if w.records.indices.contains(i) {
                let q = w.records[i]
                w.records[i] = Placement(index: q.index, flag: 0, byte1: q.byte1, type: q.type, p1: q.p1, p2: q.p2,
                                         p3: q.p3, p4: q.p4, y: q.y, x: q.x)
            }
            let dx = Int(w.player.centreX) - h16(s.centre.x), dy = Int(w.player.centreY) - h16(s.centre.y)
            if abs(dx) < 0x1c3 && abs(dy) < 0x15f { return }
            EnemyCommon.killProc(w, id: id)                             // `.KillWalker` (M l. 57785)
        } else {
            if s.killCount == 0 && s.countedInTotals {
                w.enemies.live &-= 1
                let L = w.levelIndex
                if (0..<GameGlobals.levelSlots).contains(L) { w.globals.achieved[0][L] &+= 1 }
            }
            s.handler = .platform
            s.walkerCallbacks = true
            s.hotRect = IdleSprites.Rect(top: 0x35, left: 0x10, bottom: 0x47, right: 0x42)
            s.floatOffset = -6
            s.oneWay = true
            s.counterA6 = 0
            s.invulnerable = 0
            s.setupDone = true
            s.sag = 0x20
            s.pushMass = 0x3c
            w.active.update(id: id) { $0 = s }
        }
    }

    /// The 1705 arm (M l. 57816–57992): the friction (record p3 < 3 → 0.9, else 0.7); by state —
    /// - 5 (guard): `+0xb2` + 1; below 1 face 0x6a9[1], else by `+0xb2 >> 2` 0 / 1 / 2 / 3 → 0x6a9[0 / 1 / 2 / 1],
    ///   past that `+0xb2 = −(60 + R(60))`, face [1]. The turn: P right of the centre → `+0xb4 < 3`: + 1 (0 → 1), still
    ///   < 3 → flip = (`+0xb2 < 0`), face 0x6aa[|`+0xb4`| − 1]; at 3 flip 0, face 0x6a9[0]; already 3: flip 0. P left
    ///   or level → `+0xb4 < −2`: flip 1; else − 1 (0 → −1), below −2 flip 1, face 0x6a9[0], else as above. Then
    ///   |cx − P.x| < 0x78, |P.y − cy| < 100 and P in front with `+0xb4` at ±3 (flip 1, P left, −3; flip 0, P right, 3)
    ///   → state 2, `+0xb2 = 0`.
    /// - 2 (thrust): i = `+0xb2 >> 1`; i < 13: `+0xb2 == 6` snd 304, `+0xb2 == 16` `MTNewSprite(0x6a9, cx − 0x50·flip,
    ///   cy − 10, 0, −1, .SetupEnemyShotSprite)` vx ±3000; face 0x6ab[i] (i < 9), [17 − i] (i < 12), [0]; i ≥ 13 →
    ///   state 5, `+0xb2 = 0`; then `+0xb2` + 1.
    static func spearGuardArm(_ w: SpriteWorld, id: Int) {
        guard let s0 = w.active.record(id: id) else { return }
        let p3 = record(w, s0)?.p3 ?? 0
        let px = w.player.centreX, py = w.player.centreY
        w.active.update(id: id) { friction(&$0, p3 < 3 ? friction9 : friction7) }
        if s0.subtype == 5 {
            guard var s = w.active.record(id: id) else { return }
            s.subState &+= 1
            if s.subState < 1 {
                s.face = face(spearGuard, 1)
            } else {
                switch s.subState >> 2 {
                case 0: s.face = face(spearGuard, 0)
                case 1: s.face = face(spearGuard, 1)
                case 2: s.face = face(spearGuard, 2)
                case 3: s.face = face(spearGuard, 1)
                default:
                    s.subState = 0 &- (w.rng.next(0x3c) &+ 0x3c)
                    s.face = face(spearGuard, 1)
                }
            }
            let cx = Int16(truncatingIfNeeded: s.centre.x), cy = Int16(truncatingIfNeeded: s.centre.y)
            func turnFace() {
                var m = s.classWordB4
                if m < -2 { m = -2 } else if 2 < m { m = 2 }
                if m < 1 { m = 0 &- m }
                s.mirrored = s.subState < 0
                s.face = face(turnSet, Int(m) - 1)
            }
            if cx < px {
                if s.classWordB4 < 3 {
                    s.classWordB4 &+= 1
                    if s.classWordB4 == 0 { s.classWordB4 = 1 }
                    if s.classWordB4 < 3 {
                        turnFace()
                    } else {
                        s.mirrored = false
                        s.face = face(spearGuard, 0)
                    }
                } else {
                    s.mirrored = false
                }
            } else if s.classWordB4 < -2 {
                s.mirrored = true
            } else {
                s.classWordB4 &-= 1
                if s.classWordB4 == 0 { s.classWordB4 = -1 }
                if s.classWordB4 < -2 {
                    s.mirrored = true
                    s.face = face(spearGuard, 0)
                } else {
                    turnFace()
                }
            }
            let dx = Int(cx) - Int(px), dy = Int(py) - Int(cy)
            if abs(dx) < 0x78 && abs(dy) < 100
                && ((s.mirrored && px < cx && s.classWordB4 == -3) || (!s.mirrored && cx < px && s.classWordB4 == 3)) {
                s.subtype = 2
                s.subState = 0
            }
            w.active.update(id: id) { $0 = s }
        } else if s0.subtype == 2 {
            guard let s = w.active.record(id: id) else { return }
            let i = Int(s.subState >> 1)
            if i < 0xd {
                if s.subState == 6 {
                    w.player.cue(PlayerCue(call: .threeD, snd: thrustSound, priority: 1, volume: 0x100, position: s.centre))
                }
                if s.subState == 0x10 {
                    let x = h16(h16(s.centre.x) + (s.mirrored ? -0x50 : 0)), y = h16(h16(s.centre.y) - 10)
                    if let shot = EnemyShot.spawn(w, type: EnemyShot.swing, x: x, y: y, layer: 0) {
                        w.active.update(id: shot) { $0.vx = s.mirrored ? -3000 : 3000 }
                    }
                }
                w.active.update(id: id) { t in
                    t.face = face(thrustSet, i < 9 ? i : i < 0xc ? 0x11 - i : 0)
                }
            } else {
                w.active.update(id: id) { t in
                    t.subtype = 5
                    t.subState = 0
                }
            }
            w.active.update(id: id) { $0.subState &+= 1 }
        }
    }

    /// The 1760 arm (M l. 57995–58079): the friction (|vx| ≤ 0x80 → 0, else × 0.7, as the 1705's p3 ≥ 3); by state —
    /// - 5: `+0xb2` + 1; the blink: `+0xb4 < −20` → + 1, face 0x6e0[8]; else + 1, R(25) == 1 with the stepped `+0xb4 ≥ 0`
    ///   → `+0xb4 = −28`, face 0x6e0[0]; flip = (cx < P.x); |cx − P.x| < 500 with `+0xb2 ≥ 0` → state 2, `+0xb2 = 0` (no
    ///   vertical test);
    /// - 2: i = `+0xb2 >> 1`; i < 9: `+0xb2 == 6` snd 304, `+0xb2 == 8` the boulder (`throwBoulder`), face 0x6e0[i];
    ///   else state 5, `+0xb2 = −(R(0x50) + 0x28)`; then `+0xb2` + 1.
    static func boulderArm(_ w: SpriteWorld, id: Int) {
        guard let s0 = w.active.record(id: id) else { return }
        let px = w.player.centreX
        w.active.update(id: id) { friction(&$0, friction7) }
        if s0.subtype == 5 {
            guard var s = w.active.record(id: id) else { return }
            s.subState &+= 1
            if s.classWordB4 < -0x14 {
                s.classWordB4 &+= 1
                s.face = face(boulderThrower, 8)
            } else {
                s.classWordB4 &+= 1
                if w.rng.next(0x19) == 1 && -1 < s.classWordB4 { s.classWordB4 = -0x1c }
                s.face = face(boulderThrower, 0)
            }
            let cx = Int16(truncatingIfNeeded: s.centre.x)
            s.mirrored = cx < px
            if abs(Int(cx) - Int(px)) < 500 && -1 < s.subState {
                s.subtype = 2
                s.subState = 0
            }
            w.active.update(id: id) { $0 = s }
        } else if s0.subtype == 2 {
            let i = Int(s0.subState >> 1)
            if i < 9 {
                if s0.subState == 6 {
                    w.player.cue(PlayerCue(call: .threeD, snd: thrustSound, priority: 1, volume: 0x100, position: s0.centre))
                }
                if s0.subState == 8 { throwBoulder(w, id: id) }
                w.active.update(id: id) { $0.face = face(boulderThrower, i) }
            } else {
                let r = w.rng.next(0x50)
                w.active.update(id: id) { t in
                    t.subtype = 5
                    t.subState = 0 &- (r &+ 0x28)
                }
            }
            w.active.update(id: id) { $0.subState &+= 1 }
        }
    }

    /// The 1760's boulder at `+0xb2 == 8` (M l. 58046–58066): `MTNewSprite(0x6e1 + record p1, cx + (flip ? 0x1c : −0x1c)
    /// − 0x10, cy − 0x26, layer + 1, −1, .SetupEnemyShotSprite)` (`EnemyShot`; 0x6e1 'goblin boulders', 0x6e2 'bomb
    /// boulder'); its `+0xa6 = −30`, vy = −0x6a4 − R(0x28a), then vx = −0x514 − R(0x28a), negated when flipped. No free
    /// record (Ruling 16): no Setup, the stores dropped, the two speed draws still made.
    static func throwBoulder(_ w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id) else { return }
        let p1 = Int(record(w, s)?.p1 ?? 0)
        let flip = s.mirrored
        let x = h16(h16(s.centre.x) + (flip ? 0x1c : -0x1c) - 0x10), y = h16(h16(s.centre.y) - 0x26)
        let shot = EnemyShot.spawn(w, type: Int16(truncatingIfNeeded: p1 + 0x6e1), x: x, y: y,
                                   layer: Int16(truncatingIfNeeded: s.layer &+ 1))
        let vy = -0x6a4 - Int32(w.rng.next(0x28a))
        var vx = -0x514 - Int32(w.rng.next(0x28a))
        if flip { vx = 0 &- vx }
        guard let shot else { return }
        w.active.update(id: shot) { t in
            t.counterA6 = -0x1e
            t.vy = vy
            t.vx = vx
        }
    }

    /// The death cry of the death entry (M l. 58312–58325): R(100) < 0x33 → 469 at R(10000) + 55000, else 465 at
    /// R(10000) + 50000 (`.STPlay3DSoundPitchedGob`, prio 1, vol 0xab).
    static func deathCry(_ w: SpriteWorld, id: Int) {
        let r = w.rng.next(100)
        let p = Int32(w.rng.next(10000))
        guard let s = w.active.record(id: id) else { return }
        if r < 0x33 {
            EnemyCommon.playPitchedGob(w, s, snd: dieCry, priority: 1, volume: 0xab, pitch: p + 55000)
        } else {
            EnemyCommon.playPitchedGob(w, s, snd: EnemyCommon.growl1, priority: 1, volume: 0xab, pitch: p + 50000)
        }
    }

    /// The tail `LAB_10069a8c` (M l. 58307–58471):
    /// 1. HP < 1 and not dying → the death entry: `+0xb2 = 0`; by type (others nothing) —
    ///    0x6a4: rect (0x28, 10, 0x3c, 0x46), state 4, the cry, `+0x15c` 0, score + 500, flip 0 → left − 16 and x − 24,
    ///    flip 1 → right + 16 and x + 24 (24.8 only), face 0x6a8[0], top + 0x28 (before the flip edits: top first);
    ///    0x6a9: the rect, type 0x6a4, state 4, the cry, `+0x15c` 0, x + 35 (flip 0) or + 75, face 0x6a8[0], top + 0x28,
    ///    score + 600; 0x6d6: state 4, `+0x15c` 0, face 0x6da[0], the cry, score + 800; 0x6e0: the rect, type 0x6a4,
    ///    state 4, the cry, `+0x15c` 0, flip inverted, y + 20, x − 25 (new flip 0) or + 15, face 0x6a8[0], top + 0x2a,
    ///    score + 400;
    /// 2. `+0x16c = 0`; `.ApplyGravityAndSeparateFromTiles` (`hitTile`);
    /// 3. landed (`+0xce ≠ 0`, `+0xcd == 0`): 0x6d6 in state 6 → `+0xa6 = 2 + R(4)`, `+0x46 = 0`, face 0x6d6; vy at the
    ///    last draw `+0x30` > 2000 → snd 601 at R(4000) + 40000 (`.STPlay3DSoundPitchedGob`, vol 0x55);
    /// 4. the liquids (`EnemyCommon.liquids`, the Walker row); material 2 (`+0xd8`), `+0x116 == 0`, HP > 0 → snd 701
    ///    vol 0x55, `+0x116 = 0x14`, `+0xaa = 0x12`, HP −= hdr+0x270e (raw, no fallback);
    /// 5. a face whose opaque top + 18 is the burn row `+0x1a2` → `.PopupGoblinCoins`;
    /// 6. 0x6a4 airborne (`+0xce` and `+0xcd` 0), not dying → face 0x6a5[6]; `.StandardSpriteCleanup`.
    static func tail(_ w: SpriteWorld, id: Int, solver: TileSolver, lights: inout LightTable, effects: Int16,
                     faceWidth: (FaceRef) -> Int, faceBounds: (FaceRef) -> IdleSprites.Rect) -> [DrawOp] {
        if let s = w.active.record(id: id), s.hp < 1, s.subtype != 4 {
            w.active.update(id: id) { $0.subState = 0 }
            let dyingRect = IdleSprites.Rect(top: 10, left: 0x28, bottom: 0x46, right: 0x3c)
            switch s.type {
            case thrower:
                w.active.update(id: id) { t in
                    t.hotRect = dyingRect
                    t.hotRect.top &+= 0x28
                    t.subtype = 4
                }
                deathCry(w, id: id)
                w.active.update(id: id) { t in
                    t.classWord15c = 0
                    if !t.mirrored {
                        t.hotRect.left &-= 0x10
                        t.x256 &-= 0x1800
                    } else {
                        t.hotRect.right &+= 0x10
                        t.x256 &+= 0x1800
                    }
                    t.face = face(deathSet, 0)
                }
                w.globals.score &+= 500
            case spearGuard:
                w.active.update(id: id) { t in
                    t.hotRect = dyingRect
                    t.type = thrower
                    t.subtype = 4
                }
                deathCry(w, id: id)
                w.active.update(id: id) { t in
                    t.classWord15c = 0
                    t.x256 &+= t.mirrored ? 0x4b00 : 0x2300
                    t.face = face(deathSet, 0)
                    t.hotRect.top &+= 0x28
                }
                w.globals.score &+= 600
            case axGoblin:
                w.active.update(id: id) { t in
                    t.subtype = 4
                    t.classWord15c = 0
                    t.face = face(axDeathSet, 0)
                }
                deathCry(w, id: id)
                w.globals.score &+= 800
            case boulderThrower:
                w.active.update(id: id) { t in
                    t.hotRect = dyingRect
                    t.type = thrower
                    t.subtype = 4
                }
                deathCry(w, id: id)
                w.active.update(id: id) { t in
                    t.classWord15c = 0
                    t.mirrored = !t.mirrored
                    t.y256 &+= 0x1400
                    t.x256 &+= t.mirrored ? 0xf00 : -0x1900
                    t.face = face(deathSet, 0)
                    t.hotRect.top &+= 0x2a
                }
                w.globals.score &+= 400
            default:
                break
            }
        }
        w.active.update(id: id) { $0.classWord16c = 0 }
        if let s = w.active.record(id: id) { solver.applyGravityAndSeparate(id, pass: pass(s)) }
        if let s = w.active.record(id: id), s.groundKind != 0, s.onSprite == 0 {
            if s.type == axGoblin && s.subtype == 6 {
                let r = w.rng.next(4)
                w.active.update(id: id) { t in
                    t.counterA6 = r &+ 2
                    t.phase = 0
                    t.face = face(axGoblin, 0)
                }
            }
            if 2000 < s.previousVY {
                let r = Int32(w.rng.next(4000))
                if let t = w.active.record(id: id) {
                    EnemyCommon.playPitchedGob(w, t, snd: landSound, priority: 1, volume: 0x55, pitch: r + 40000)
                }
            }
        }
        EnemyCommon.liquids(w, id: id, class: .walker)
        if let s = w.active.record(id: id), s.material == 2, s.invulnerable == 0, 0 < s.hp {
            w.player.cue(PlayerCue(call: .threeD, snd: EnemyCommon.ouch, priority: 1, volume: 0x55, position: s.centre))
            let dmg = w.level.header.landingDamage
            w.active.update(id: id) { t in
                t.invulnerable = 0x14
                t.flash = 0x12
                t.hp &-= dmg
            }
        }
        var ops: [DrawOp] = []
        if let s = w.active.record(id: id), let f = s.face, Int(s.burnRow) == faceBounds(f).top + 0x12 {
            ops = popupCoins(w, id: id, solver: solver, lights: &lights, effects: effects, faceWidth: faceWidth,
                             faceBounds: faceBounds)
        }
        w.active.update(id: id) { t in
            if t.groundKind == 0 && t.onSprite == 0 && t.subtype != 4 && t.type == thrower {
                t.face = face(walkSet, 6)
            }
        }
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
        return ops
    }

    // MARK: - coins

    /// `.PopupGoblinCoins(s)` (M l. 57348–57506; enemies-ground §3.8): with a face, the origin is the centre of its
    /// opaque bounds (face `+8`, `.FlipHRect` by the face width `+6` when flipped) at (`+0xc`, `+0xa`). Weights by
    /// record p3 (nothing, 2–4 coins 0x516, one bag 0x50c, 2–4 bags 0x50c, the big bag 0x50d): r = R(total), tested from
    /// the top with strict `<` (big bag, bags, bag, coins, nothing). Each drop `MTNewSprite(type, origin, 0x14, −1,
    /// .SetupBonusSprite)`, re-centred (`+0xc += +0xc − +0x10`, `+0xa` likewise, 24.8 from them), vy = −2000 −
    /// R(1000), the multiples vx = R(2000) − 1000, `+0xb0 = 0xc`, then its own Handle `+0x4c` called at once
    /// (`.HandleBonusSprite`). The 2–4 counts draw R(3) first. p3 outside 0…6 weighs nothing: `FastRand(0)` (the clock
    /// reseed) as written [LOW: no such placement].
    static func popupCoins(_ w: SpriteWorld, id: Int, solver: TileSolver, lights: inout LightTable, effects: Int16,
                           faceWidth: (FaceRef) -> Int, faceBounds: (FaceRef) -> IdleSprites.Rect) -> [DrawOp] {
        guard let s = w.active.record(id: id), let f = s.face else { return [] }
        var b = faceBounds(f)
        if s.mirrored { b = PlatformSprite.flipH(b, faceWidth(f)) }
        let x0 = h16((b.left + b.right) / 2 + h16(s.x)), y0 = h16((b.top + b.bottom) / 2 + h16(s.y))
        var nothing: Int16 = 0, coins: Int16 = 0, bag: Int16 = 0, bags: Int16 = 0, big: Int16 = 0
        switch record(w, s)?.p3 ?? 0 {
        case 0: (nothing, coins, bag) = (0x46, 0x1e, 8)
        case 1: (nothing, coins) = (0x46, 0x1e)
        case 2: (nothing, coins, bag, bags) = (0x23, 0x23, 0x14, 10)
        case 3, 5: (nothing, coins, bag, bags) = (0x14, 0x1e, 0x1e, 0x14)
        case 4: (coins, bag, bags, big) = (10, 0x14, 0x1e, 0x28)
        case 6: (nothing, coins, bag, bags) = (0x14, 0x1e, 0x28, 10)
        default: break
        }
        let total = Int(nothing) + Int(coins) + Int(bag) + Int(bags) + Int(big)
        let r = Int(w.rng.next(Int16(truncatingIfNeeded: total)))
        var edge = Int(Int16(truncatingIfNeeded: total)) - Int(big)
        var ops: [DrawOp] = []
        let pl = w.playerID.flatMap { w.active.record(id: $0) }?.layer ?? 0
        func drop(_ type: Int16, spread: Bool) {
            let c = w.newSprite(type: type, x: x0, y: y0, layer: 0x14, handler: .bonus) { c in
                // Cannot throw: `BonusSprite.setup` throws only for 0xc25 and items past 0xc9a — never 0x50c / 0x50d /
                // 0x516.
                _ = try! BonusSprite.setup(&c, x: x0, y: y0, level: w.level, records: w.records, effects: effects,
                                           lightCount: lights.count, counting: false, playerLayer: pl,
                                           rng: &w.rng) { lf, lh, lv, col in
                    lights.add(face: lf, x: Int16(truncatingIfNeeded: lh), y: Int16(truncatingIfNeeded: lv), vx: 0,
                               vy: 0, accelY: 0, colour: col)
                }
            }
            if let c {
                w.active.update(id: c) { t in
                    t.x = h16(h16(t.x) + (h16(t.x) - h16(t.centre.x)))
                    t.y = h16(h16(t.y) + (h16(t.y) - h16(t.centre.y)))
                    t.x256 = Int32(t.x) << 8
                    t.y256 = Int32(t.y) << 8
                }
            }
            let vy = -2000 - Int32(w.rng.next(1000))
            let vx = spread ? Int32(w.rng.next(2000)) - 1000 : nil
            guard let c else { return }                                 // Ruling 16: no record, the stores dropped
            w.active.update(id: c) { t in
                t.vy = vy
                if let vx { t.vx = vx }
                t.pickupDelay = 0xc
            }
            ops += BonusSprite.handle(world: w, id: c, solver: solver, effects: effects, lights: &lights,
                                      faceWidth: faceWidth)
        }
        if edge < r {
            drop(0x50d, spread: false)
        } else {
            edge -= Int(bags)
            if edge < r {
                let n = w.rng.next(3) &+ 2
                for _ in 0..<Int(n) { drop(0x50c, spread: true) }
            } else {
                edge -= Int(bag)
                if edge < r {
                    drop(0x50c, spread: false)
                } else if edge - Int(coins) < r {
                    let n = w.rng.next(3) &+ 2
                    for _ in 0..<Int(n) { drop(0x516, spread: true) }
                }
            }
        }
        return ops
    }

    // MARK: - hits

    /// `.HitWalkerSprite(s, other)` (M l. 58506–58611; enemies-ground §3.7). Every Handle comparison is `+0x4c ==`
    /// (`BackgroundSprite.runs`: an idled record matches none):
    /// - other a player shot with `+0xa6 == 0`, or an enemy shot with `+0xa6 > 2` and a type ≠ ours: a player shot of
    ///   type 1 → `.KillPlayerShot(o, 1, 1)`, `.TurnIntoStatue(s)`; else not dying: the 1705 in state 5 against a type
    ///   ≠ 0x5a → snd 303 vol 0x100 at the shot, the shot killed (`.KillPlayerShot(o, 1, 1)` / `.KillEnemyShot`), `+0xb2
    ///   = 0`; otherwise kvx = record p2 == 0 ? (i16)(o.vx / 3) : 0 (/ 3 again for 0x6d6), `.HurtSprite(s, o.+0xa4, kvx,
    ///   −1000, 4, 8)` → on a hurt n = max(1, o.+0xa4 / 100): `.GoblinHurtCry`, the shot killed (`.KillPlayerShot(o, 0,
    ///   0)` / `.KillEnemyShot`), `.BloodSpray(s, o, 40n, 50n + 350, 150n, 2)`, HP > 0 → snd 701 vol 0x55;
    /// - other a Statue, Box or Platform: the crush (`EnemyCommon.crushesWalker`) → HP 0;
    /// - other an Effect 0x4b7 at `+0x46 < 8` or a 0x5a0 in mode 1 / 2 (`EnemyCommon.environmentalHazard`) →
    ///   `.HurtGoblin(s, o, 100, 0, −1000, 4, 8)`;
    /// - other a Background of type 0x4b8, 0x5c8…0x5d1 with `+0x170 == 1`, or 0x730…0x735, with our `+0x100 == 0` →
    ///   `.HurtGoblin` 100 (0x113 for 0x730…0x735).
    public static func hit(_ w: SpriteWorld, id: Int, other oID: Int, lights: inout LightTable, effects: Int16 = 1,
                           faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                           faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard let s = w.active.record(id: id), let o = w.active.record(id: oID) else { return }
        let runs = BackgroundSprite.runs
        let playerShot = runs(o, .playerShot)
        func killShot(_ flags: Bool) {
            if playerShot {
                PlayerShotHits.kill(w, shot: oID, sound: flags, effect: flags, effects: effects, lights: &lights,
                                    faceWidth: faceWidth, faceBounds: faceBounds)
            } else {
                EnemyShot.kill(w, shot: oID, lights: &lights, effects: effects)
            }
        }
        if (playerShot && o.counterA6 == 0) || (runs(o, .enemyShot) && 2 < o.counterA6 && o.type != s.type) {
            if o.type == 1 && playerShot {
                killShot(true)
                EnemyCommon.turnIntoStatue(w, id: id)
            } else if s.subtype != 4 {
                if s.type == spearGuard && s.subtype == 5 && o.type != 0x5a {
                    w.player.cue(PlayerCue(call: .threeD, snd: blockSound, priority: 1, volume: 0x100, position: o.centre))
                    killShot(true)
                    w.active.update(id: id) { $0.subState = 0 }
                } else {
                    var kvx = 0
                    if (record(w, s)?.p2 ?? 0) == 0 { kvx = Int(Int16(truncatingIfNeeded: o.vx / 3)) }
                    if s.type == axGoblin { kvx /= 3 }
                    let dmg = o.hp
                    if HurtSprite.apply(w, id: id, damage: dmg, dvx: Int16(truncatingIfNeeded: kvx), dvy: -1000,
                                        invulnerable: 4, flash: 8) {
                        var n = Int(dmg) / 100
                        if n < 2 { n = 1 }
                        let k = Int16(truncatingIfNeeded: n)
                        EnemyCommon.goblinHurtCry(w, id: id)
                        killShot(false)
                        BloodSpray.spray(w, victim: id, attacker: oID, count: k &* 0x28, speed: k &* 0x32 &+ 0x15e,
                                         spread: k &* 0x96, kind: 2)
                        if let t = w.active.record(id: id), 0 < t.hp {
                            w.player.cue(PlayerCue(call: .threeD, snd: EnemyCommon.ouch, priority: 1, volume: 0x55,
                                                   position: t.centre))
                        }
                    }
                }
            }
        } else if runs(o, .statue) || runs(o, .box) || runs(o, .platform) {
            let r = s.hotRect
            let centre = SpriteSlot.Point(x: h16(r.left + h16((r.right - r.left) >> 1)),
                                          y: h16(r.top + h16((r.bottom - r.top) >> 1)))
            let crushed = EnemyCommon.crushesWalker(mover: s, solid: o) {
                w.platformBounce(mover: id, solid: oID, centre: centre, factor: 0, rect: r, bounce: false)
            }
            if crushed { w.active.update(id: id) { $0.hp = 0 } }
        } else if EnemyCommon.environmentalHazard(o) {
            EnemyCommon.hurtGoblin(w, id: id, attacker: oID, damage: 100, dvx: 0, dvy: -1000, invulnerable: 4, flash: 8)
        } else if runs(o, .background), s.classWord100 == 0,
                  o.type == 0x4b8 || ((0x5c8...0x5d1).contains(o.type) && o.classWord170 == 1)
                    || (0x730...0x735).contains(o.type) {
            let dmg: Int16 = (0x730...0x735).contains(o.type) ? 0x113 : 100
            EnemyCommon.hurtGoblin(w, id: id, attacker: oID, damage: dmg, dvx: 0, dvy: -1000, invulnerable: 4, flash: 8)
        }
    }

    /// `.HitWalkerTileSprite(s, pos, kind, layer)` (M l. 58634–58696; the debug no-clip key not built): FG (layer 1)
    /// → `.WallBounce(s, kind, &pos, vCentre, 0, +0x34, 0, 0)`; a hit against a wall in the facing direction (kinds
    /// 0…2; 4 / 9 / 0x1b / 0x14 flip 0; 7 / 10 / 0x1c / 0x13 flip 1; 5 flip 1 with pos.x + 16 < cx; 7 flip 0 with cx <
    /// pos.x + 16; 0x20…0x23 any — the kind as passed) with `+0x170 == 0` → `+0x16c` + 1. BG kinds < 100
    /// `.WallBounce(…, 0, …, 0)`, < 200 `.WallBounceBG(kind − 100, …)`, water → `.HandleUnderWater` unless `+0x140`.
    public static func hitTile(_ solver: TileSolver, id: Int, pos posIn: TilePos, kind: Int, layer: TileLayer) {
        let w = solver.world
        guard let s = w.active.record(id: id) else { return }
        var pos = posIn
        let r = s.hotRect
        let vCentre = h16(r.top + h16((r.bottom - r.top) >> 1))
        let k = Int16(truncatingIfNeeded: kind)
        if layer == .foreground {
            guard solver.wallBounce(id, kind: kind, tile: &pos, vCentre: vCentre, factor: 0, rect: r, bounce: false),
                  let t = w.active.record(id: id) else { return }
            let flip = t.mirrored
            let cx = h16(t.centre.x), tx = h16(pos.x) + 0x10
            let wall = (0...2).contains(k) || (k == 4 && !flip) || (k == 7 && flip) || (flip && (k == 10 || k == 0x1c))
                || (!flip && (k == 9 || k == 0x1b)) || (flip && k == 5 && tx < cx) || (!flip && k == 7 && cx < tx)
                || (k == 0x13 && flip) || (k == 0x14 && !flip) || (0x1f < k && k < 0x24)
            if wall && t.classWord170 == 0 { w.active.update(id: id) { $0.classWord16c &+= 1 } }
        } else if k < 100 {
            solver.wallBounce(id, kind: kind, tile: &pos, vCentre: vCentre, factor: 0, rect: r, bounce: false)
        } else if k < 200 {
            solver.wallBounceBG(id, kind: kind - 100, tile: &pos, vCentre: vCentre, factor: 0, rect: r, bounce: false)
        } else if UnderWater.isWaterTile(kind), !s.underwaterDone {
            UnderWater.handle(world: w, id: id, pos: pos)
        }
    }
}
