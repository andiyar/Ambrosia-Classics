import Foundation

/// The Ax goblin — the Walker type 1750 (WK2; enemies-ground §3.6, the ⚑ WK2 corrections): the 0x6d6 arm of
/// `.HandleWalkerSprite @ 100683b8` (M l. 58082–58306, `arm`, inside `Walker.handle`'s shared prologue and tail) and
/// `.AxGoblinCoreLogic @ 10067840` (M l. 57101–57347, `coreLogic`). Its Setup is `.SetupWalkerSprite`'s 0x6d6…0x6df arm
/// (`Walker.setup`); its hits, death entry, landing and Kill are the Walker's (`Walker.hit`, `Walker.tail`,
/// `.KillWalker`). First placed on level 10 (Ruling 1: built, tested synthetically).
///
/// Fields (`SpriteSlot`): `+0xb0` the state `subtype` (1 walk, 2 swing, 4 dying, 6 airborne, 7 → the core logic; 0 / 3
/// / 5 report an error); `+0xb2` `subState` (1 advance, 2 retreat; the death counter); `+0xb6` the flee flag
/// `classWordB6`; `+0x46` the walk / swing / jump counter `phase`; `+0xa6` the swing and landing cooldown `counterA6`;
/// `+0x160` the jump budget `classWord160`; `+0x164` the walk timer `launchSpeed`; `+0x168` the airborne target vx
/// `bonusP4`; `+0x16c` the wall hits `classWord16c`; `+0x170` the wall-hit lockout `classWord170`; `+0x174` the flee
/// lockout `classWord174`; `+0x100` tier 4 `classWord100` (never flees).
public enum AxGoblin {
    /// The sheets (`.InitWalkerSprite` M l. 56756, 56764–56767): the single 0x6d6 (standing) and the cache sets 0x6d7
    /// walk (8), 0x6d8 swing (6), 0x6d9 jump (3), 0x6da death (6), each 0xd8×0x6e, one a row.
    public static let standFace: Int16 = 0x6d6, walkSet: Int16 = 0x6d7, swingSet: Int16 = 0x6d8, jumpSet: Int16 = 0x6d9,
                      deathSet: Int16 = 0x6da

    /// The snd slots (`SoundSlots`): `*_DAT_100a03f8` 414 (the jump), `*_DAT_100a02a0` 610 'axgoblin' (the jump cry),
    /// `*_DAT_100a0268` 704 'throw' (the swing), `*_DAT_100a026c` 703 (the death thud).
    static let jumpSound: Int16 = 414, jumpCry: Int16 = 610, swingSound: Int16 = 704, deathThud: Int16 = 703

    @inline(__always) static func h16(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }
    @inline(__always) static func face(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }

    // MARK: - the Handle arm

    /// The 0x6d6 arm of `.HandleWalkerSprite` (M l. 58082–58306) by state `+0xb0`, then the facing:
    /// - 1 (walk, M l. 58086–58114), on ground: right iff P.x < cx (the signed-compare idiom, raw `100694dc`), inverted at
    ///   `+0xb2 == 1` and again while fleeing (`+0xb6 == 3 ∧ +0x174 == 0`); `+0x46` + 1; `.SetSpriteSpeed(±0x578, 0x200)`;
    ///   `+0x46` wrapped 0…15; face 0x6d7[`+0x46 >> 1`]; `coreLogic`;
    /// - 2 (swing, M l. 58115–58192): gravity 0x151; face 0x6d6; vx halved toward zero; the face by `+0x46` (0 → 0x6d6;
    ///   1–2, 3–4, 5–6, 7–8, 9–11, 12–17 → 0x6d8[0…5]); `+0xa6 > 0` → − 1; then `+0xa6 == 0` → `+0x46` + 1, at 5 snd 704
    ///   (`.STPlay3DSoundPitched`, prio 1, vol 0x100, pitch 45000, no draw), at 8 `+0xa6 = R(12) + 10` and
    ///   `MTNewSprite(type, x + (flip ? 3 : 0x99), y + 0x2c, 0, −1, .SetupEnemyShotSprite)` (the axe hitbox 0x6d6,
    ///   `EnemyShot`); else `+0x46 < 1` → face 0x6d6; else `+0x46` + 1, past 14 → 0 and `coreLogic`;
    /// - 4 (dying, `dying`);
    /// - 6 (airborne, M l. 58239–58291): `+0x46 < 0` → + 1, at 0 vy = −5000 and `+0xce = 0` (no writer of a negative
    ///   `+0x46` — dead, as written); else vy < 0 and `+0x46 < 8` → + 1; else vy > 2000 and `+0x46 > 1` → − 1; face
    ///   0x6d9[0] while `+0x46 < 0`, else 0x6d9[(`+0x46` − 1) / 3] (toward zero); airborne (`+0xce == 0 ∧ +0xcd == 0`):
    ///   vx moves toward `+0x168` by |`+0x168`| / 6; on ground: face 0x6d6, vx 0, `+0xa6 < 1` → (`+0x46 ≥ 0` →
    ///   `coreLogic`), else `+0x170 = 50`, `+0xa6` − 1, `+0x16c = 0`;
    /// - 7: `coreLogic` (no writer of state 7 — dead, as written);
    /// - 0, 3, 5 and any other: `.ReportError("Ax goblin error!")` (M l. 58083–58085; the alert is not modelled — no
    ///   writer of these states for a 1750).
    /// The facing (M l. 58295–58306), not dying and not mid-swing (state ≠ 2 or `+0x46 == 0`): cx < P.x → flip =
    /// (`+0xb2 == 2`); P.x < cx → flip = (`+0xb2 ≠ 2`); then inverted while fleeing.
    static func arm(_ w: SpriteWorld, id: Int) {
        guard let s0 = w.active.record(id: id) else { return }
        let px = w.player.centreX
        switch s0.subtype {
        case 1:
            guard s0.groundKind != 0 else { break }
            w.active.update(id: id) { s in
                var right = px < Int16(truncatingIfNeeded: s.centre.x)
                if s.subState == 1 { right = !right }
                if s.classWordB6 == 3 && s.classWord174 == 0 { right = !right }
                s.phase &+= 1
                Walker.setSpriteSpeed(&s, right ? 0x578 : -0x578, 0x200)
                if s.phase < 0 {
                    s.phase = 0xf
                } else if 0xf < s.phase {
                    s.phase = 0
                }
                s.face = face(walkSet, Int(s.phase >> 1))
            }
            coreLogic(w, id: id)
        case 2:
            var swingNow = false, logic = false, swish = false
            w.active.update(id: id) { s in
                s.gravity = 0x151
                s.face = face(standFace, 0)
                if 0 < (s.vx < 1 ? 0 &- s.vx : s.vx) { s.vx = s.vx / 2 }   // `srawi 1; addze`: toward zero
                switch s.phase {
                case 0: s.face = face(standFace, 0)
                case 1, 2: s.face = face(swingSet, 0)
                case 3, 4: s.face = face(swingSet, 1)
                case 5, 6: s.face = face(swingSet, 2)
                case 7, 8: s.face = face(swingSet, 3)
                case 9...0xb: s.face = face(swingSet, 4)
                case 0xc...0x11: s.face = face(swingSet, 5)
                default: break
                }
                if 0 < s.counterA6 { s.counterA6 &-= 1 }
                if s.counterA6 == 0 {
                    s.phase &+= 1
                    swish = s.phase == 5
                    swingNow = s.phase == 8
                } else if s.phase < 1 {
                    s.face = face(standFace, 0)
                } else {
                    s.phase &+= 1
                    if 0xe < s.phase {
                        s.phase = 0
                        logic = true
                    }
                }
            }
            if swish, let s = w.active.record(id: id) {
                w.player.cue(PlayerCue(call: .threeDPitched, snd: swingSound, priority: 1, volume: 0x100,
                                       position: s.centre, rate: 45000))
            }
            if swingNow { swing(w, id: id) }
            if logic { coreLogic(w, id: id) }
        case 4:
            dying(w, id: id)
        case 6:
            var logic = false
            w.active.update(id: id) { s in
                let p = s.phase
                if p < 0 {
                    s.phase = p &+ 1
                    if s.phase == 0 {
                        s.vy = -5000
                        s.groundKind = 0
                    }
                } else if s.vy < 0 && p < 8 {
                    s.phase = p &+ 1
                } else if 2000 < s.vy && 1 < p {
                    s.phase &-= 1
                }
                s.face = s.phase < 0 ? face(jumpSet, 0) : face(jumpSet, Int((s.phase &- 1) / 3))
                if s.groundKind == 0 && s.onSprite == 0 {
                    let t = s.bonusP4
                    let step = (t < 1 ? 0 &- t : t) / 6
                    if s.vx < t {
                        s.vx &+= step
                    } else if t < s.vx {
                        s.vx &-= step
                    }
                }
                if s.groundKind != 0 {
                    s.face = face(standFace, 0)
                    s.vx = 0
                    if s.counterA6 < 1 {
                        logic = -1 < s.phase
                    } else {
                        s.classWord170 = 0x32
                        s.face = face(standFace, 0)
                        s.counterA6 &-= 1
                        s.classWord16c = 0
                    }
                }
            }
            if logic { coreLogic(w, id: id) }
        case 7:
            coreLogic(w, id: id)
        default:
            break                                                       // `.ReportError("Ax goblin error!")`
        }
        w.active.update(id: id) { s in
            guard s.subtype != 4, s.subtype != 2 || s.phase == 0 else { return }
            let cx = Int16(truncatingIfNeeded: s.centre.x)
            if cx < px {
                s.mirrored = s.subState == 2
            } else if px < cx {
                s.mirrored = s.subState != 2
            }
            if s.classWordB6 == 3 && s.classWord174 == 0 { s.mirrored = !s.mirrored }
        }
    }

    /// The swing's axe at `+0x46 == 8` (M l. 58172–58184): `+0xa6 = R(12) + 10`, then `MTNewSprite(type, x + (flip ? 3 :
    /// 0x99), y + 0x2c, 0, −1, .SetupEnemyShotSprite)` — the type is the goblin's own, 0x6d6 (the exact-type dispatch).
    /// No free record (Ruling 16): no Setup.
    static func swing(_ w: SpriteWorld, id: Int) {
        let r = w.rng.next(0xc)
        w.active.update(id: id) { $0.counterA6 = r &+ 10 }
        guard let s = w.active.record(id: id) else { return }
        EnemyShot.spawn(w, type: s.type, x: h16(h16(s.x) + (s.mirrored ? 3 : 0x99)), y: h16(h16(s.y) + 0x2c), layer: 0)
    }

    /// The 1750 path's dying state 4 (M l. 58193–58238; enemies-ground §3.8): face 0x6da[min(`+0xb2` / 4, 5)] (toward
    /// zero); `+0xb2 == 20` → vy − 800; `+0xb2 == 0` → snd 703 vol 0x100; layer 1; the ×0.9 friction; `+0xb2` + 1; past
    /// 60: `+0x15c` + 1 (past 2 with `+0x1a2 < 1` → the burn starts), the record's `+4` cleared, and the player's centre
    /// at least 451 px across or 351 px down / up → `.KillWalker`. No `+0xea` (the 1700 path's) and no corpse raft.
    static func dying(_ w: SpriteWorld, id: Int) {
        guard var s = w.active.record(id: id) else { return }
        let b2 = s.subState
        var f = b2 / 4
        if b2 == 0x14 { s.vy &-= 800 }
        if 5 < f { f = 5 }
        if s.subState == 0 {
            w.player.cue(PlayerCue(call: .threeD, snd: deathThud, priority: 1, volume: 0x100, position: s.centre))
        }
        s.face = face(deathSet, Int(f))
        s.layer = 1
        Walker.friction(&s, Walker.friction9)
        s.subState &+= 1
        guard 0x3c < s.subState else {
            w.active.update(id: id) { $0 = s }
            return
        }
        s.classWord15c &+= 1
        if 2 < s.classWord15c && s.burnRow < 1 { s.burnRow = 1 }
        w.active.update(id: id) { $0 = s }
        let i = Int(s.recordIndex)                                      // the record's `+4 = 0` (M l. 58224)
        if w.records.indices.contains(i) {
            let q = w.records[i]
            w.records[i] = Placement(index: q.index, flag: 0, byte1: q.byte1, type: q.type, p1: q.p1, p2: q.p2,
                                     p3: q.p3, p4: q.p4, y: q.y, x: q.x)
        }
        let dx = Int(w.player.centreX) - h16(s.centre.x), dy = Int(w.player.centreY) - h16(s.centre.y)
        if abs(dx) < 0x1c3 && abs(dy) < 0x15f { return }
        EnemyCommon.killProc(w, id: id)                                 // `.KillWalker` (M l. 58236)
    }

    // MARK: - the core logic

    /// `.AxGoblinCoreLogic(s)` (M l. 57101–57347; enemies-ground §3.6 with the ⚑ WK2 corrections):
    /// 1. `+0x160 < 0` → + 1; `+0x164 > 0` → − 1; `+0x174 < 0` → + 1;
    /// 2. the target T: flee — T = (P.x < cx ? 32000 : −32000, P.y < cy ? 32000 : −32000), `+0xb6 = 3` — when HP
    ///    `+0xa4 < 0xc9`, `+0x174 == 0`, `+0x100 == 0` and |cx − P.x| < 600, or when the player's health `G+4 ≤ 0`;
    ///    otherwise chase — T = P, `+0x174 = 0`, `+0xb6 = 0` (M l. 57126–57162);
    /// 3. dx = |T.x − cx|, wall = dx ≥ 110 ∧ `+0x16c > 0`; dx < 110 or `+0x16c > 0`:
    ///    a. |T.y − cy| < 40, dx < 110, `+0xb6 == 0`, not wall → the swing: `+0xb6` 0, `+0xb2` 1, `+0x160` 0, `+0x46` 0,
    ///       state 2, `+0x164` 0;
    ///    b. else T.y < cy + 25 or wall: `+0x160` in 0…2 → the jump: `+0xb2` 1; d = (short)(cy − T.y); flip = T.x ≥ cx;
    ///       snd 414 (`.STPlay3DSoundPitchedGob`, prio 0x14, vol 0x55, R(4000) + 40000); R(100) > 0x50 → snd 610 (prio
    ///       0x14, vol 0xab, R(4000) + 40000); state 6, `+0x46` 0; vy = wall ? −2000 − R(3000) : −50·d − R(600), then
    ///       above −4800 → −4800, below −6250 → −6250; vx = `+0x168` = wall ? ((R(30) + 30) / 10)·325, negated for T.x <
    ///       cx : (d / 10)·(T.x − cx) + R(400) − 200 (divisions toward zero); vx and `+0x168` each clamped to ±4200;
    ///       `+0xce` 0; `+0x160` + 1. `+0x160 ≥ 3` → the retreat: state 1, `+0xb2` 2, chasing `+0x164` 30 and `+0x160`
    ///       −30 − R(20); fleeing `+0x164` 70, `+0x160` −70 − R(20), `+0x174` −120 − R(60). `+0x160 < 0`: nothing;
    ///    c. else (T below): r = R(100); `+0x164` 30; `+0x160` −30 − R(20); r < 0x15 → the hop (`+0xb2` 2 below 0xb,
    ///       else 1; state 6, `+0x46` 0, vy −2500 − R(3000), above −4000 → −4000, below −6000 → −6000; vx and `+0xce`
    ///       kept); r < 0x3d → state 1, `+0xb2` 1, `+0x164` 30, `+0x160` −30 − R(20); else state 1, `+0xb2` 2, the
    ///       same second `+0x160` draw;
    ///    otherwise `+0x164 == 0` → state 1, `+0xb2` 1 (advance).
    /// - Parameter w: P = `*_DAT_1009fd94` / `fd90` (the player's centre), `G+4` = `globals.health`.
    public static func coreLogic(_ w: SpriteWorld, id: Int) {
        guard var s = w.active.record(id: id) else { return }
        let px = Int(w.player.centreX), py = Int(w.player.centreY)
        if s.classWord160 < 0 { s.classWord160 &+= 1 }
        if 0 < s.launchSpeed { s.launchSpeed &-= 1 }
        if s.classWord174 < 0 { s.classWord174 &+= 1 }
        let cx = h16(s.centre.x), cy = h16(s.centre.y)
        var tx = 0, ty = 0, flee = true
        if !(s.hp < 0xc9 && s.classWord174 == 0 && s.classWord100 == 0) || 599 < abs(cx - px) {
            if 0 < w.globals.health {                                   // LAB_100678e8 (M l. 57141–57147)
                s.classWord174 = 0
                tx = px
                ty = py
                s.classWordB6 = 0
                flee = false
            }
        }
        if flee {
            tx = px < cx ? 32000 : -32000
            ty = py < cy ? 32000 : -32000
            s.classWordB6 = 3
        }
        let dx = abs(tx - cx)
        guard dx < 0x6e || 0 < s.classWord16c else {
            if s.launchSpeed == 0 {
                s.subtype = 1
                s.subState = 1
            }
            w.active.update(id: id) { $0 = s }
            return
        }
        let wall = 0x6d < dx && 0 < s.classWord16c
        if abs(ty - cy) < 0x28 && dx < 0x6e && s.classWordB6 == 0 && !wall {
            s.classWordB6 = 0
            s.subState = 1
            s.classWord160 = 0
            s.phase = 0
            s.subtype = 2
            s.launchSpeed = 0
            w.active.update(id: id) { $0 = s }
            return
        }
        if ty < cy + 0x19 || wall {
            let j = s.classWord160
            if j < 3 && -1 < j {
                s.subState = 1
                let d = Int32(Int16(truncatingIfNeeded: cy - ty))
                s.mirrored = !(tx < cx)
                let r1 = Int32(w.rng.next(4000))
                EnemyCommon.playPitchedGob(w, s, snd: jumpSound, priority: 0x14, volume: 0x55, pitch: r1 + 40000)
                if 0x50 < w.rng.next(100) {
                    let r2 = Int32(w.rng.next(4000))
                    EnemyCommon.playPitchedGob(w, s, snd: jumpCry, priority: 0x14, volume: 0xab, pitch: r2 + 40000)
                }
                s.subtype = 6
                s.phase = 0
                if wall {
                    s.vy = -2000 - Int32(w.rng.next(3000))
                } else {
                    s.vy = d &* -0x32 &- Int32(w.rng.next(600))
                }
                if -0x12c0 < s.vy { s.vy = -0x12c0 }
                if s.vy < -0x186a { s.vy = -0x186a }
                if wall {
                    let v = (Int32(w.rng.next(0x1e)) + 0x1e) / 10 * 0x145
                    s.vx = v
                    s.bonusP4 = v
                    if tx < cx {
                        s.vx = 0 &- v
                        s.bonusP4 = 0 &- v
                    }
                } else {
                    let r = Int32(w.rng.next(400))
                    let v = (d / 10) &* Int32(truncatingIfNeeded: tx - cx) &+ r &- 200
                    s.vx = v
                    s.bonusP4 = v
                }
                if 0x1068 < s.vx { s.vx = 0x1068 } else if s.vx < -0x1068 { s.vx = -0x1068 }
                if 0x1068 < s.bonusP4 { s.bonusP4 = 0x1068 } else if s.bonusP4 < -0x1068 { s.bonusP4 = -0x1068 }
                s.groundKind = 0
                s.classWord160 &+= 1
            } else if -1 < j {
                s.subtype = 1
                s.subState = 2
                if s.classWordB6 == 0 {
                    s.launchSpeed = 0x1e
                    s.classWord160 = 0 &- Int32(w.rng.next(0x14)) &- s.launchSpeed
                } else {
                    s.launchSpeed = 0x46
                    s.classWord160 = 0 &- Int32(w.rng.next(0x14)) &- s.launchSpeed
                    s.classWord174 = -0x78 - Int32(w.rng.next(0x3c))
                }
            }
        } else {
            let r = w.rng.next(100)
            s.launchSpeed = 0x1e
            s.classWord160 = 0 &- Int32(w.rng.next(0x14)) &- s.launchSpeed
            if r < 0x3d {
                if r < 0x15 {
                    s.subState = r < 0xb ? 2 : 1
                    s.subtype = 6
                    s.phase = 0
                    s.vy = -0x9c4 - Int32(w.rng.next(3000))
                    if -4000 < s.vy { s.vy = -4000 }
                    if s.vy < -6000 { s.vy = -6000 }
                } else {
                    s.subtype = 1
                    s.subState = 1
                    s.launchSpeed = 0x1e
                    s.classWord160 = 0 &- Int32(w.rng.next(0x14)) &- s.launchSpeed
                }
            } else {
                s.subtype = 1
                s.subState = 2
                s.launchSpeed = 0x1e
                s.classWord160 = 0 &- Int32(w.rng.next(0x14)) &- s.launchSpeed
            }
        }
        w.active.update(id: id) { $0 = s }
    }
}
