import Foundation

/// `.HandleKeys(s, ridden) @ 10052ac0` (decompile l. 47047–47882; player-states §4–§5, physics §4), called by
/// `.HandlePlayerSprite` row 21 unless a door transit locks input. P1a builds everything but the L/R block (P1b):
/// the early returns, the standard hot rect, the carpet steering, the USE gates (false in Phase 2), the DOWN block
/// (crouch, shield, spin), the climb block and the JUMP arm with its else-refill.
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
        // the item switch (l. 47543–47609) instead of the L/R block. // later: Phase 4 — false in Phase 2.
        w.player.useItemHeld = false                                      // `_DAT_100a075c = 0`
        if !w.player.glider {
            if w.player.climb == 0 && w.player.crouch == 0 && !w.player.carpet && charge < 0x15 {
                // later: P1b — the L/R block (l. 47360–47493): walk/run/turn, air control, rope, swim, exertion
                // +1 (< 0xb9) walking / +3 running, the facing from vx.
            }
        } else if s().hp > 0 {
            // later: Phase 4 — glider steering (l. 47494–47541).
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
