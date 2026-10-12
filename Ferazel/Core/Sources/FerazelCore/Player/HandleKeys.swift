import Foundation

/// `.HandleKeys(s, ridden) @ 10052ac0` (decompile l. 47047–47882; player-states §4–§5, physics §4), called by
/// `.HandlePlayerSprite` row 21 unless a door transit locks input: the early returns, the standard hot rect, the
/// carpet steering, the USE gates (false in Phase 2), the L/R block with `.FootPressure` (P1b), the DOWN block
/// (crouch, shield, spin), the climb block and the JUMP arm with its else-refill (P1a).
///
/// Keys: one `InputActions` snapshot per frame stands in for each live `.IsInputKeyPressed(i)` (plan Hazards: keys
/// cannot change inside a frame) [MED, gate card 20]. Every sound here is `.STPlayRegSound` — no `FastRand` draw.
public enum HandleKeys {
    /// The standard hot rect `SetRect(+0x34, 0x26, 0x22, 0x3e, 0x55)` (l. 47231–47239; both arms identical).
    public static let standardHotRect = IdleSprites.Rect(top: 0x22, left: 0x26, bottom: 0x55, right: 0x3e)

    /// - Parameter ridden: `param_2` = `*PTR_DAT_100a0558` (the sprite ridden this frame; nil = 0).
    public static func run(world w: SpriteWorld, keys: InputActions, ridden: Int?) {
        guard let id = w.playerID, w.active.record(id: id) != nil else { return }
        func s() -> SpriteSlot { w.active.record(id: id)! }
        func set(_ body: (inout SpriteSlot) -> Void) { w.active.update(id: id, body) }
        func cue(_ snd: Int16, _ vol: Int16) { w.player.cues.append(PlayerCue(call: .reg, snd: snd, priority: 1, volume: vol)) }

        // Early returns (l. 47108–47122): |teleporter charge| > 0x1e; drinking a potion (wand phase and crouch 0);
        // boss grab.
        let charge = abs(Int(w.player.teleporterCharge))
        if charge > 0x1e { return }
        if w.player.potion > 0 {
            w.player.wandPhase = 0
            w.player.crouch = 0
            return
        }
        if w.player.bossGrab > 0 { return }
        // `GetKeys`, then the debug keys while `*_DAT_100a0064` (engine §7.3) — not built: debug mode is off.
        if w.player.dying == 0 { set { $0.hotRect = standardHotRect } }   // l. 47231–47239
        w.player.walkRight = false                                        // `_DAT_100a0734`
        w.player.walkLeft = false                                         // `_DAT_100a0730`
        if w.player.pullUp > 0 { return }
        if w.player.dying > 0 { return }

        if w.player.carpet, let carpetID = w.player.ridden {
            carpetSteering(w, id: id, carpet: carpetID, keys: keys)
        }
        // LAB_100530cc.
        w.player.noCastBegan = true                                       // `PTR_DAT_100a06e0 = 1`
        // USE, first gate (l. 47311–47352): USE ∧ the selected slot is a spell (G + 0x2c + 10·slot) ∧ shield raise < 1
        // → cast / select. // later: Phase 4 (spells, inventory) — false in Phase 2 (plan P1a).
        w.player.useDebounce = false                                      // `_DAT_100a0760 = 0`
        // USE, second gate (l. 47353–47357): USE ∧ an item (not a spell) selected ∧ shield < 1 ∧ climb 0 ∧ rope 0 →
        // the item switch (l. 47543–47609) instead of the L/R and glider blocks. // later: Phase 4 — false in
        // Phase 2 (no inventory; plan P1a/P1b).
        let itemSwitch = false
        if !itemSwitch {
            w.player.useItemHeld = false                                  // `_DAT_100a075c = 0`
            // The L/R gate (l. 47359–47365; raw `100534f0..10053548`, Bank correction A7): not gliding
            // (`_DAT_100a05e0`), climb 0 (`_DAT_100a0758`), crouch depth 0 (`_DAT_100a071c`), no carpet
            // (`PTR_DAT_100a05a4`), |teleporter charge| < 0x15 — the charge re-read here as the binary re-reads
            // `PTR_DAT_100a0700` (raw `1005352c lwz r3,-0x7140(r2); lha`), not the early-return copy.
            if !w.player.glider {
                if w.player.climb == 0 && w.player.crouch == 0 && !w.player.carpet
                    && abs(Int(w.player.teleporterCharge)) < 0x15 {
                    leftRight(w, id: id, keys: keys)
                }
            } else if s().hp > 0 {
                // later: Phase 4 — glider steering (l. 47494–47541).
            }
        } else {
            // later: Phase 4 — the item switch (l. 47543–47609).
        }

        if w.player.climb == 0 {
            downBlock(w, id: id, keys: keys)
        } else if w.player.wandPhase < 4 {
            climbBlock(w, id: id, keys: keys)
        }

        // The JUMP arm (l. 47725–47869), gated by the shield raise `PTR_DAT_100a05e8 < 1` (raw `10052ae8`,
        // `10053ec8..10053ed0`; Bank correction A1).
        guard !w.player.glider, keys.contains(.jump), w.player.shieldRaise < 1 else {
            // The else-refill (l. 47870–47880): airborne 0 (climbing 3), grounded 6. No coyote time, no buffer.
            if s().groundKind == 0 {
                w.player.jumpCounter = w.player.climb == 0 ? 0 : 3
            } else {
                w.player.jumpCounter = 6
            }
            return
        }
        // Wall jump (l. 47727–47743).
        if w.player.climb != 0 && w.player.jumpCounter > 0 {
            cue(414, 0x9c)                                                // `_DAT_100a03f8`
            w.player.postJumpGuard = 2
            w.player.climb = 0
            w.player.lastRope = false
            w.player.rope = false
            let counter = w.player.jumpCounter, side = w.player.wallSide
            set { p in
                p.vy = 0
                if counter == 3 { p.vy = -0x8cb }
                p.vx = side == 1 ? 0x8ca : -0x8ca
            }
        }
        guard w.player.jumpCounter > 0 else { return }
        // The spin / leap refill (l. 47744–47772): DOWN, or UP below the surface band in liquid; spin 0; counter 1…6.
        let inLiquid = s().waterRow != 0 || s().lastWater != 0
        if (keys.contains(.down) || (keys.contains(.up) && !w.player.nearSurface && inLiquid)) && !w.player.spin
            && w.player.jumpCounter < 7 && w.player.jumpCounter > 0 {
            if !w.player.nearSurface && w.player.spinCooldown == 0 {
                w.player.spinCooldown = 0x14
                w.player.jumpCounter = 6
            }
            if !keys.contains(.up) {
                w.player.spin = true
            } else {
                w.player.spin = false
                w.player.airCounter = 1
            }
            w.player.lastRope = false
            w.player.rope = false
            w.player.swim = 0
            if w.player.spin { cue(427, 0xba) }                            // `_DAT_100a03cc`
            w.player.crouch = 0
            w.player.spinFrame = 0
        }
        let near = w.player.nearSurface
        if (!near && w.player.swim == 0) || w.player.spin {
            if s().groundKind == 0 || w.player.swim != 0 || w.player.jumpCounter != 6 {
                // Sustain (l. 47776–47790).
                if w.player.jumpCounter > 0 && w.player.swim == 0 {
                    w.player.exertion &+= 8
                    set { $0.vy = 0 }
                    accelerateJump(w, id: id)
                    w.player.lastRope = false
                    w.player.rope = false
                    w.player.jumpCounter -= 1
                }
            } else {
                // The initial jump (l. 47791–47821).
                if s().invulnerable > 0x3c {
                    w.player.launched = true
                    w.player.tumbleFrame = 7
                }
                w.player.lastRope = false
                w.player.rope = false
                w.player.exertion &+= 8
                cue(414, 0x9c)                                            // `_DAT_100a03f8`
                w.player.postJumpGuard = 2
                set { $0.vy = 0 }
                if w.player.airCounter == 0 {
                    set { p in
                        p.face = FaceRef(pict: 1010, index: 0, set: .encoded)   // `*_DAT_100a07e4` = set 1010 [0]
                        p.groundKind = 0
                    }
                }
                if ridden != nil {
                    // later: W1 — J = the ridden platform's `+0x194`, and the springboard sound 604 (`_DAT_100a027c`)
                    // when J ≠ 0 and its `+0xb0` mode is 0x58c. No Phase-2 sprite is ridden before W1.
                }
                accelerateJump(w, id: id)
                w.player.jumpCounter -= 1
            }
        } else if near || w.player.swim != 0 {
            swimStroke(w, id: id, near: near, ridden: ridden)
        }
    }

    /// The L/R block (l. 47366–47490; raw `1005354c..100539c0`; player-states §4, §5.7, §6). Each key zeroes
    /// fidgets and idle. **LEFT** (action 0): airborne (`+0xce == 0`) — swimming: −0xd2 while vx > −0x76c; on a
    /// rope: −1000, floor −0x960; else −0x14a while vx > −air max (`600e`, `6010` with the run flag; raw
    /// `10053780`). Grounded — walk flag `0730`; walking: exertion +1 while < 0xb9, run flag 0,
    /// `.AccelerateBasedOnSlope(−0x104 if vx < 0 ∨ ice else −0x14f, walk max)`; running: exertion +3, run flag 1,
    /// −0x12c / −0x1f4 with the run max; then with the air counter `0718` 0: `.FootPressure` (no Double Speed, no
    /// post-jump guard) and the slip y += |2vx| + 0x200 when `+0x112 > 0` (raw `100536a4..100536d0`, Bank correction
    /// A14). Then vx < 0 ∧ stun 0 → F 1. **RIGHT** (action 1): airborne — swimming: +0xd2 while vx < 0x76c; on a
    /// rope: +1000, cap 0x960; grounded — walk flag `0734`, exertion and run flag as LEFT,
    /// `.AccelerateBasedOnSlope(0x14f if vx < 1 ∧ no ice else 0x104 / 500 else 300)`, `.FootPressure` under the same
    /// three gates (no slip); then in **every** state +0x14a while vx < air max (raw `100539a4`), and vx > 0 → F 2
    /// with no stun test (raw `100539ac..100539bc`).
    static func leftRight(_ w: SpriteWorld, id: Int, keys: InputActions) {
        // ⚠️ Works on a copy of the record and writes it back on exit: any call added here that writes the player's
        // record through `w.active` (none in Phase 2 — `.AccelerateBasedOnSlope` and `.FootPressure` take the copy)
        // would be overwritten by the write-back. Move such a call outside, or re-read the copy after it.
        guard var s = w.active.record(id: id) else { return }
        defer { let out = s; w.active.update(id: id) { $0 = out } }
        func airMax() -> Int32 { Int32(w.player.runFlag ? w.player.airRun : w.player.airWalk) }
        /// −air max as the LEFT test computes it: `lha; neg; …; extsh` (raw `1005375c..10053774`).
        func negAirMax() -> Int32 {
            Int32(Int16(truncatingIfNeeded: 0 &- Int32(w.player.runFlag ? w.player.airRun : w.player.airWalk)))
        }
        func walkOrRun(_ walk: Int16, _ walkFresh: Int16, _ run: Int16, _ runFresh: Int16, fresh: Bool) {
            if !keys.contains(.run) {
                if w.player.exertion < 0xb9 { w.player.exertion += 1 }    // raw `10053600..1005360c` / `10053860..6c`
                w.player.runFlag = false
                s.accelerateBasedOnSlope(fresh ? walkFresh : walk, cap: Int32(w.player.maxWalk))
            } else {
                w.player.exertion &+= 3                                   // raw `10053598..100535a0` / `100537f8..800`
                w.player.runFlag = true
                s.accelerateBasedOnSlope(fresh ? runFresh : run, cap: Int32(w.player.maxRun))
            }
        }
        if keys.contains(.left) {
            w.player.fidgets = 0                                          // `_DAT_100a0688`
            w.player.idle = 0                                             // `_DAT_100a068c`
            if s.groundKind == 0 {
                if w.player.swim != 0 {
                    if -0x76c < s.vx { s.vx &-= 0xd2 }                    // raw `100536d8..10053710`
                } else if w.player.rope {
                    s.vx &-= 1000                                         // raw `10053724..10053740`
                    if s.vx < -0x960 { s.vx = -0x960 }
                } else if negAirMax() < s.vx {
                    s.vx &-= 0x14a                                        // raw `10053780`
                }
            } else {
                w.player.walkLeft = true
                walkOrRun(-0x104, -0x14f, -0x12c, -0x1f4, fresh: !(s.vx < 0 || w.player.ice != 0))
                if w.player.airCounter == 0 {
                    if !w.player.doubleSpeed && w.player.postJumpGuard == 0 { footPressure(&s) }
                    if 0 < s.slip {
                        let twice = s.vx &* 2                             // `rlwinm. r3,r0,1,0,30; ble → neg`
                        s.y256 = (twice < 1 ? 0 &- twice : twice) &+ s.y256 &+ 0x200
                    }
                }
            }
            if s.vx < 0 && w.player.stun == 0 { w.player.facing = 1 }    // raw `10053788..100537a8`
        }
        if keys.contains(.right) {
            w.player.fidgets = 0
            w.player.idle = 0
            if s.groundKind == 0 {
                if w.player.swim != 0 {
                    if s.vx < 0x76c { s.vx &+= 0xd2 }                     // raw `10053908..10053940`
                } else if w.player.rope {
                    s.vx &+= 1000                                         // raw `10053954..10053970`
                    if 0x960 < s.vx { s.vx = 0x960 }
                }
            } else {
                w.player.walkRight = true
                walkOrRun(0x104, 0x14f, 300, 500, fresh: s.vx < 1 && w.player.ice == 0)
                if w.player.airCounter == 0 && !w.player.doubleSpeed && w.player.postJumpGuard == 0 {
                    footPressure(&s)
                }
            }
            if s.vx < airMax() { s.vx &+= 0x14a }                         // raw `10053974..100539a8`
            if 0 < s.vx { w.player.facing = 2 }                           // raw `100539ac..100539bc`
        }
    }

    /// `.FootPressure @ 100431ec` (raw `100431ec..100433bc`; physics-sprites §8.4): not riding (`+0xdc` 0), not on a
    /// one-way top (`+0xd0`), `+0xce` not 4/7/0x13/0x14 and not moving uphill (vx ≤ 0 excludes 0xc, 0x20, 0x21,
    /// 0x2c, 0x2d, 0x32…0x35; vx > 0 excludes 0xf, 0x22, 0x23, 0x2e, 0x2f, 0x36…0x39) → y += |vx|. Riding with a
    /// slope `+0xd6 ≠ 0`: d = |vx·slope| >> 8 (`mullw`, `srawi`); vx and slope of one sign (vx 0 counts as +) →
    /// y += min(d, 0x800), else y −= d. Returns the delta. Also called by `.HandleBoxSprite` (Phase 4).
    @discardableResult
    static func footPressure(_ s: inout SpriteSlot) -> Int16 {
        if s.ridden == nil {
            let k = s.groundKind
            guard !s.oneWayLanded, k != 4, k != 7, k != 0x13, k != 0x14 else { return 0 }
            let downhill: Bool
            if 0 < s.vx {
                downhill = ![0xf, 0x22, 0x23, 0x2e, 0x2f].contains(k) && !(0x36...0x39).contains(k)
            } else {
                downhill = ![0xc, 0x20, 0x21, 0x2c, 0x2d].contains(k) && !(0x32...0x35).contains(k)
            }
            guard downhill else { return 0 }
            let d = 0 < s.vx ? s.vx : 0 &- s.vx
            s.y256 &+= d
            return Int16(truncatingIfNeeded: d)
        }
        let slope = Int32(s.slope)
        guard slope != 0 else { return 0 }
        let product = s.vx &* slope
        let d = (product < 1 ? 0 &- product : product) >> 8
        var delta: Int32
        if (s.vx < 0) == (slope < 0) {
            delta = d
            if 0x800 <= delta { delta = 0x800 }                           // `cmpwi 0x800; bge → li 0x800`
        } else {
            delta = 0 &- d
            if 0x800 <= delta { delta = 0x800 }                           // dead (delta ≤ 0), as written
        }
        s.y256 &+= delta
        return Int16(truncatingIfNeeded: delta)
    }

    /// `.AccelerateSprite(s, 0, J + (−0xc80 − ((|vx| + 0x4e2) >> 3)), 0, 8000)` (raw `100541c4`, `10054240`).
    static func accelerateJump(_ w: SpriteWorld, id: Int) {
        guard let p = w.active.record(id: id) else { return }
        let ax = p.vx < 1 ? 0 &- p.vx : p.vx
        let ay = w.player.jumpBase &+ (-0xc80 &- ((ax &+ 0x4e2) >> 3))
        w.active.update(id: id) { $0.accelerateSprite(ax: 0, ay: ay, maxX: 0, maxY: 8000) }
    }

    /// The swim stroke (l. 47822–47867): counter 6 → impulse `(i16)(J + (−0x640 − (i16)((|vx| + 200) >> 3)))`,
    /// halved (srawi) when already swimming below the surface band, swim 3, gravity 0x50, stroke cooldown 12,
    /// exertion +8, snd 497 vol 0x9c unless in spirit form, face 1027[0], cap 2000; a later counter repeats it
    /// quartered below the band.
    static func swimStroke(_ w: SpriteWorld, id: Int, near: Bool, ridden: Int?) {
        guard let p = w.active.record(id: id) else { return }
        let ax = p.vx < 1 ? 0 &- p.vx : p.vx
        var a = Int16(truncatingIfNeeded: w.player.jumpBase) &+ (-0x640 &- Int16(truncatingIfNeeded: (ax &+ 200) >> 3))
        if w.player.jumpCounter == 6 {
            if w.player.swim != 0 && !near { a = a >> 1 }
            w.player.swim = 3
            w.player.strokeCooldown = 0xc
            w.player.exertion &+= 8
            if w.player.spiritTimer == 0 {
                w.player.cues.append(PlayerCue(call: .reg, snd: 497, priority: 1, volume: 0x9c))   // `_DAT_100a02e8`
            }
            w.active.update(id: id) { s in
                s.gravity = 0x50
                s.vy = 0
                s.face = FaceRef(pict: 1027, index: 0, set: .encoded)    // `*_DAT_100a07b8`
                s.groundKind = 0
            }
            if ridden != nil {
                // later: W1 — J from the ridden platform's `+0x194` (and the 0x58c springboard sound).
            }
            let ay = Int32(a)
            w.active.update(id: id) { $0.accelerateSprite(ax: 0, ay: ay, maxX: 0, maxY: 2000) }
            w.player.jumpCounter -= 1
        } else if w.player.jumpCounter > 0 {
            if w.player.swim != 0 && !near { a = a >> 2 }
            w.player.exertion &+= 8
            let ay = Int32(a)
            w.active.update(id: id) { s in
                s.vy = 0
                s.accelerateSprite(ax: 0, ay: ay, maxX: 0, maxY: 2000)
            }
            w.player.jumpCounter -= 1
        }
    }

    /// The magic-carpet block (l. 47249–47285, LAB_1005303c l. 47286–47308): idle 0; unless the steering lock runs,
    /// L/R push the carpet's vx ±0x140 (cap ±0xc80, F 1/2; L at its cap falls through to R), UP/DOWN its vy ∓0x100
    /// (cap ∓4000; UP skips DOWN); then the carpet and the player close a centre gap > 1 px by 1 px each while the
    /// carpet's |vx| < 0x100.
    static func carpetSteering(_ w: SpriteWorld, id: Int, carpet: Int, keys: InputActions) {
        w.player.idle = 0
        if w.player.carpetLock < 1 {
            var leftTaken = false
            if keys.contains(.left), let c = w.active.record(id: carpet), !(c.vx < -0xc7f) {
                w.active.update(id: carpet) { $0.vx &-= 0x140 }
                w.player.facing = 1
                leftTaken = true
            }
            if !leftTaken, keys.contains(.right), let c = w.active.record(id: carpet), c.vx < 0xc80 {
                w.active.update(id: carpet) { $0.vx &+= 0x140 }
                w.player.facing = 2
            }
            var upTaken = false
            if keys.contains(.up), let c = w.active.record(id: carpet), -4000 < c.vy {
                w.active.update(id: carpet) { $0.vy &-= 0x100 }
                upTaken = true
            }
            if !upTaken, keys.contains(.down), let c = w.active.record(id: carpet), c.vy < 4000 {
                w.active.update(id: carpet) { $0.vy &+= 0x100 }
            }
        }
        guard let c = w.active.record(id: carpet), let p = w.active.record(id: id) else { return }
        let cvx = c.vx < 1 ? 0 &- c.vx : c.vx
        if c.centre.x < p.centre.x - 1, cvx < 0x100 {
            w.active.update(id: carpet) { $0.x256 &+= 0x100 }
            w.active.update(id: id) { $0.x256 &-= 0x100 }
            return
        }
        if p.centre.x + 1 < c.centre.x, cvx < 0x100 {
            w.active.update(id: carpet) { $0.x256 &-= 0x100 }
            w.active.update(id: id) { $0.x256 &+= 0x100 }
        }
    }

    /// The DOWN block while not climbing (l. 47610–47680): no DOWN (or on a carpet) → the shield raise, else the
    /// crouch depth, decays by 1; DOWN → idle/fidgets 0 and, airborne, crouch/shield 0; grounded, crouch +1 (≤ 4),
    /// facing from L/R without a shield (with one: the raise grows when pressing away from F, else decays), and the
    /// crouch hot rect `(0x26, 0x37, 0x3e + e, 0x55)` facing right / `(0x26 − e, 0x37, 0x3e, 0x55)` left. Then
    /// DOWN with spin 0 and 0 < counter < 6 → spin, rope flags 0, swim 0, snd 427 vol 0xba, crouch 0, spin frame 0
    /// (raw `10053cec..10053d60`) — **before** the JUMP arm, so DOWN + JUMP in the air never refills (Bank
    /// correction A2).
    static func downBlock(_ w: SpriteWorld, id: Int, keys: InputActions) {
        let down = keys.contains(.down)
        if !down || w.player.carpet {
            if w.player.shieldRaise < 1 {
                if w.player.crouch > 0 { w.player.crouch -= 1 }
            } else {
                w.player.shieldRaise -= 1
            }
        } else {
            w.player.fidgets = 0
            w.player.idle = 0
            if w.active.record(id: id)?.groundKind == 0 {
                w.player.crouch = 0
                w.player.shieldRaise = 0
                w.player.shieldExtension = 0
            } else {
                if w.player.crouch < 4 { w.player.crouch += 1 }
                if !hasShield(w) {
                    if keys.contains(.left) {
                        w.player.facing = 1
                    } else if keys.contains(.right) {
                        w.player.facing = 2
                    }
                } else if (keys.contains(.left) && w.player.facing == 2)
                            || (keys.contains(.right) && w.player.facing == 1) {
                    if w.player.shieldRaise < 5 { w.player.shieldRaise += 1 }
                } else if w.player.shieldRaise > 0 {
                    w.player.shieldRaise -= 1
                }
                let e = Int(w.player.shieldExtension), right = w.player.facing == 2
                w.active.update(id: id) { s in
                    s.hotRect = right ? IdleSprites.Rect(top: 0x37, left: 0x26, bottom: 0x55, right: 0x3e + e)
                                      : IdleSprites.Rect(top: 0x37, left: 0x26 - e, bottom: 0x55, right: 0x3e)
                }
            }
        }
        if down && !w.player.spin && w.player.jumpCounter < 6 && w.player.jumpCounter > 0 {
            w.player.spin = true
            w.player.lastRope = false
            w.player.rope = false
            w.player.swim = 0
            w.player.cues.append(PlayerCue(call: .reg, snd: 427, priority: 1, volume: 0xba))   // `_DAT_100a03cc`
            w.player.crouch = 0
            w.player.spinFrame = 0
        }
    }

    /// `.HasItem(0xe) ∨ .HasItem(0xf)` (a shield). // later: Phase 4 (inventory) — no Phase-2 inventory: false.
    static func hasShield(_ w: SpriteWorld) -> Bool { false }

    /// The climb block while clinging and the wand phase < 4 (l. 47681–47724): UP → vy −1000 (−0x578 Double
    /// Speed), DOWN → +1000 (+0x578), each with idle/fidgets 0 and wand phase 0 — or vy 0 when a cast began this
    /// call (`PTR_DAT_100a06e0 == 0`) or (wand phase > 0 ∧ wand-held < 5); the climb phase ±1 (UP skips DOWN).
    static func climbBlock(_ w: SpriteWorld, id: Int, keys: InputActions) {
        let up = keys.contains(.up)
        guard up || keys.contains(.down) else { return }
        w.player.fidgets = 0
        w.player.idle = 0
        let p = w.player
        if !p.noCastBegan || (p.wandPhase > 0 && p.wandHeld < 5) {
            w.active.update(id: id) { $0.vy = 0 }
        } else {
            w.player.wandPhase = 0
            let v: Int32 = p.doubleSpeed ? 0x578 : 1000
            w.active.update(id: id) { $0.vy = up ? 0 &- v : v }
        }
        w.player.climbPhase = up ? p.climbPhase &+ 1 : p.climbPhase &- 1
    }
}
