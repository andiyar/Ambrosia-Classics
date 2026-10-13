import Foundation

/// `.HandlePlayerSprite` row 33 — the state / face selection (decompile l. 45219–46196, `goto LAB_10050e6c`; raw
/// `1004ec4c..10050e6c`; player-states §3) — and row 36's tint (l. 46242–46346): plan P3. **First match wins**, in the binary's order: glider → dying → spirit transition → boss grab →
/// hurt-stun → door walk (`_DAT_100a05f8`) → rope → swim → wall cling / climb / pull-up → melee (`.HandleItemUse`) →
/// grounded (crouch, walk / run with footsteps, stand / turn / uphill / fidget) → airborne. The glider, spirit,
/// boss-grab, door and melee arms are never taken in Phase 2 (their flags have no Phase-2 writer) and are named stubs
/// (plan Invariant 6). A face is `+0xc0 = set + index·0x34` (one 0x34-byte face record per index).
public enum PlayerStates {
    // MARK: the face sets (`.InitPlayerSprite @ 1004a284`, l. 42428–42490; player-states §7)

    /// 1003 stand (`_DAT_100a07ec`), 1004 uphill (`07e8`, a single face), 1010 air (`07e4`), 1011 crouch (`07e0`),
    /// 1012 climb (`07dc`), 1013 hurt (`07d8`), 1014 cast (`07d4`), 1015 tumble (`079c`), 1016 rope stand (`0798`),
    /// 1017 rope walk (`0794`), 1020 walk (`07d0`), 1022 dying (`07c8`, 150×120), 1023 pull-up (`07c4`, 120×120),
    /// 1024 run (`07c0`), 1025 spin (`07bc`), 1027 swim (`07b8`), 1028 fidget 2 (`07b4`), 1029 fidget 1 (`07b0`),
    /// 1030 turn (`07ac`), 1031 cling cast (`07a8`), 1032 V-Blade cast (`07a4`), 1034 crouch cast (`0790`), 1036
    /// potion (`0788`), 1039 shield (`077c`).
    public static let stand: Int16 = 1003, uphill: Int16 = 1004, air: Int16 = 1010, crouch: Int16 = 1011
    public static let climb: Int16 = 1012, hurt: Int16 = 1013, cast: Int16 = 1014, tumble: Int16 = 1015
    public static let ropeStand: Int16 = 1016, ropeWalk: Int16 = 1017, walk: Int16 = 1020, dying: Int16 = 1022
    public static let pullUp: Int16 = 1023, run: Int16 = 1024, spin: Int16 = 1025, swim: Int16 = 1027
    public static let fidget2: Int16 = 1028, fidget1: Int16 = 1029, turn: Int16 = 1030, clingCast: Int16 = 1031
    public static let vBladeCast: Int16 = 1032, crouchCast: Int16 = 1034, potion: Int16 = 1036, shield: Int16 = 1039

    /// A player face's width (face `+6`) for `.StandardSpriteCleanup`: the set's cell width (150 for 1022, 120 for
    /// 1023, else 100 — the single 1004 is 100×120 too). The sets themselves are FerazelRender's
    /// `FaceSheet.playerSheets` (the one table, `.InitPlayerSprite` l. 42427–42484); `FaceTests.testPlayerFaceSetsTable`
    /// checks these widths against it.
    public static func faceWidth(_ f: FaceRef) -> Int {
        switch f.pict {
        case dying: return 0x96
        case pullUp: return 0x78
        default: return 100
        }
    }

    @inline(__always) static func face(_ pict: Int16, _ index: Int) -> FaceRef {
        FaceRef(pict: pict, index: index, set: .encoded)
    }

    // MARK: - row 33

    /// Row 33 for the player `id`. Returns `cStack_6b`: the launched tumble face was drawn (row 34 then leaves the
    /// facing `+0x17e` as it is).
    @discardableResult
    static func select(world w: SpriteWorld, id: Int) -> Bool {
        func s() -> SpriteSlot { w.active.record(id: id)! }
        func set(_ body: (inout SpriteSlot) -> Void) { w.active.update(id: id, body) }
        func setFace(_ f: FaceRef?) { set { $0.face = f } }
        /// `if (0 < idle) idle = fidgets` — most arms' "idle reset".
        func idleReset() { if 0 < w.player.idle { w.player.idle = w.player.fidgets } }
        /// `if (FUN_100916dc(*_DAT_100a03cc)) FUN_10091504(…)`: stop the spin sound 427 if it is playing.
        func stopSpinSound() { w.player.cues.append(PlayerCue(call: .stopIfPlaying, snd: 427)) }

        // Glider (`_DAT_100a05e0`, l. 45219–45518, incl. dying on the glider). // later: Phase 4 (no Phase-2 writer)
        if w.player.glider { return false }

        // Dying (`_DAT_100a069c > 0`, l. 45519–45589).
        if 0 < w.player.dying {
            idleReset()
            set { p in
                p.hasHit = false                                     // `+0x5c = 0`
                p.vx = 0
            }
            // `*PTR_DAT_100a0654 = 0`: the Shadow Double off. // later: Phase 4
            w.player.climb = 0
            let d = w.player.dying
            if d < 0x1e {
                set { p in
                    p.buoyancy = Int16(truncatingIfNeeded: Int(UInt16(bitPattern: d) & 1) + Int(p.buoyancy) + 1)
                    p.floatOffset = -0x16                            // `+0x1a0 = 0xffea`
                    p.face = face(dying, Int(d) / 3)
                    if 8 < d {
                        let dx = p.mirrored ? -2 : 2
                        p.hotRect.left += dx                         // `+0x36`
                        p.hotRect.right += dx                        // `+0x3a`
                    }
                }
            } else {
                setFace(face(dying, 9))                              // `+0x1d4` = 9·0x34
            }
            set { $0.invulnerable = 0 }
            w.player.dying &+= 1
            if 0 < w.player.revive {
                // later: Phase 4 — the necklace revive (`PTR_DAT_100a0594` 1…30, faces 1022[(30 − r)/3], HP/breath
                // from `G+0xa`, `.RemoveItem(0x17)`); no Phase-2 writer of `0594`.
            }
            let ended = w.player.diedInLiquid ? 100 < w.player.dying : 0x50 < w.player.dying
            if ended {
                // `.HasItemWhichSlot(0x17, …)`: no inventory in Phase 2 (// later: Phase 3–4), so never the revive
                // arm — `DAT_100a5106 = 1`, the game over.
                w.player.gameOver = true
            }
            return false
        }
        // Spirit transition (`_DAT_100a0574 > 0`, l. 45590–45624). // later: Phase 4 (Mist potion; no Phase-2 writer)
        if 0 < w.player.spiritTransition { return false }
        // Boss grab (`_DAT_100a0570 > 0`, l. 45625–45672). // later: Phase 5 (Chief, Xichra; no Phase-2 writer)
        if 0 < w.player.bossGrab { return false }

        // Hurt-stun (`_DAT_100a0748 > 0`, l. 45673–45700): 1013 at 0,1,2,3,3,3,3,3,2,1, then the stun ends.
        if 0 < w.player.stun {
            idleReset()
            w.player.standing0670 = false
            w.player.climb = 0
            w.player.spin = false
            stopSpinSound()
            w.player.crouch = 0
            let n = Int(w.player.stun)
            if n < 5 {
                setFace(face(hurt, n - 1))
            } else if n < 8 {
                setFace(face(hurt, 3))                               // `+0x9c`
            } else {
                setFace(face(hurt, 3 - (n - 8)))
            }
            w.player.stun += 1
            if 10 < w.player.stun { w.player.stun = 0 }
            return false
        }
        // Door walk-in / walk-out (`_DAT_100a05f8 ≠ 0`, l. 45701–45722). // later: Phase 3 (doors; no Phase-2 writer)
        if w.player.animation05f8 != 0 { return false }

        // Rope (`_DAT_100a0588`, l. 45723–45748). // W3's `.RopeCollide` sets the flag; no Phase-2 level has a rope.
        if w.player.rope {
            w.player.idle = 0
            let v = s().vx
            let speed = v < 1 ? 0 &- v : v
            if speed < 0x81 {
                w.player.ropeWalk = 0
                setFace(face(ropeStand, 0))
                let wand = w.player.wandPhase
                if 0 < wand {
                    idleReset()
                    if !w.player.vBladeCast { setFace(face(ropeStand, Int(wand))) }
                }
            } else {
                setFace(face(ropeWalk, Int(w.player.ropeWalk >> 1)))
                w.player.ropeWalk += 1
                if 0xf < w.player.ropeWalk { w.player.ropeWalk = 0 }
            }
            return false
        }

        // Swim (`_DAT_100a0714 ≠ 0`, l. 45749–45781): the stroke is 10 ticks, 1027[k >> 1].
        if w.player.swim != 0 {
            var k = w.player.swim - 1
            idleReset()
            set { $0.gravity = 0x50 }
            if 0xb < k {
                w.player.swim = 1
                k = 0
            }
            setFace(face(swim, Int(k >> 1)))
            if w.player.itemUse != 0 {
                // later: Phase 4 — `.HandleItemUse(s)` (melee while swimming).
            }
            if 1 < w.player.swim { w.player.swim += 1 }
            if w.player.strokeCooldown == 0 { w.player.jumpCounter = 6 }
            if !w.player.nearSurface {
                set { p in if p.vy < 0 { p.vy &+= 200 } }
                if 0x12 < s().lastWater && k == 5 {
                    // later: E1a — `.Splash(s, 3)`.
                }
            }
            if s().lastWater == 0 && s().waterRow == 0 && w.player.spiritTimer < 1 { w.player.swim = 0 }
            return false
        }

        // Wall cling / climb / pull-up (`_DAT_100a0758 ≠ 0`, l. 45782–45855).
        if w.player.climb != 0 {
            clingArm(w, id: id)
            return false
        }
        // Melee / throw (`_DAT_100a0698 ≠ 0`, l. 45856–45859). // later: Phase 4 (`.HandleItemUse`; no Phase-2 writer)
        if w.player.itemUse != 0 { return false }

        // Grounded (`_DAT_100a0738 ∨ +0xce`, l. 45860–46053). The jump frame lands here: `0738` was latched by row 20
        // before `.HandleKeys` made the impulse (Bank correction A9).
        if w.player.groundLast != 0 || s().groundKind != 0 {
            grounded(w, id: id)
            return false
        }
        return airborne(w, id: id)
    }

    /// The cling arm (l. 45782–45855): idle reset, standing `0670` 0, air counter 0, spin 0, stop 427, crouch 0. No
    /// pull-up: the climb phase `_DAT_100a5f54` wraps (≥ 13 → 1, < 1 → 12); wand phase < 1 → 1012[(phase − 1) >> 1],
    /// else phase 1, vy 0, 1031[min(wand, 5)] (6 → 5). Pull-up: face 1023[9] at n = 20, else 1023[(n − 1) >> 1],
    /// then n += 1 and past 0x14 the move: x256 ±0x2000 (− when `+0x17e`), y256 −= 0x1600, pull-up 0, climb 0, air
    /// counter 0, spin 0, stop 427, crouch 2, `+0xce` 1, `0738` 1, face 1011[2].
    static func clingArm(_ w: SpriteWorld, id: Int) {
        if 0 < w.player.idle { w.player.idle = w.player.fidgets }
        w.player.standing0670 = false
        w.player.airCounter = 0
        w.player.spin = false
        w.player.cues.append(PlayerCue(call: .stopIfPlaying, snd: 427))   // `_DAT_100a03cc`
        w.player.crouch = 0
        let n = w.player.pullUp
        if n == 0 {
            if w.player.climbPhase < 0xd {
                if w.player.climbPhase < 1 { w.player.climbPhase = 0xc }
            } else {
                w.player.climbPhase = 1
            }
            let wand = w.player.wandPhase
            if wand < 1 {
                let f = face(climb, Int((w.player.climbPhase - 1) >> 1))
                w.active.update(id: id) { $0.face = f }
            } else {
                w.player.climbPhase = 1
                let f = face(clingCast, Int(wand == 6 ? 5 : wand))
                w.active.update(id: id) { p in
                    p.vy = 0
                    p.face = f
                }
            }
            return
        }
        let f = n == 0x14 ? face(pullUp, 9) : face(pullUp, Int((n - 1) >> 1))
        w.active.update(id: id) { $0.face = f }
        w.player.pullUp += 1
        guard 0x14 < w.player.pullUp else { return }
        w.active.update(id: id) { p in
            p.x256 &+= p.mirrored ? -0x2000 : 0x2000
            p.y256 &-= 0x1600
        }
        w.player.pullUp = 0
        w.player.climb = 0
        w.player.airCounter = 0
        w.player.spin = false
        w.player.cues.append(PlayerCue(call: .stopIfPlaying, snd: 427))
        w.player.crouch = 2
        w.player.groundLast = 1                                         // `_DAT_100a0738`
        let landed = face(crouch, 2)                                    // `07e0 + 0x68`
        w.active.update(id: id) { p in
            p.groundKind = 1
            p.face = landed
        }
    }

    /// The grounded arm (l. 45860–46053; player-states §3.11).
    static func grounded(_ w: SpriteWorld, id: Int) {
        func s() -> SpriteSlot { w.active.record(id: id)! }
        func setFace(_ f: FaceRef?) { w.active.update(id: id) { $0.face = f } }
        func idleReset() { if 0 < w.player.idle { w.player.idle = w.player.fidgets } }
        func stopSpinSound() { w.player.cues.append(PlayerCue(call: .stopIfPlaying, snd: 427)) }

        // Crouch (`_DAT_100a071c ≠ 0`).
        if w.player.crouch != 0 {
            idleReset()
            w.player.airCounter = 0
            w.player.spin = false
            stopSpinSound()
            let wand = w.player.wandPhase
            if wand < 2 || w.player.crouch < 4 {
                if w.player.shieldRaise < 1 {
                    setFace(face(crouch, Int(w.player.crouch) - 1))
                } else {
                    if w.player.shieldExtension < 7 { w.player.shieldExtension += 1 }
                    // `.HasItem(0xf)` (the Magical Shield): no inventory in Phase 2 (// later: Phase 3–4) → false, so
                    // 1039[min(raise − 1, 5)] (the other arm: 1039[min(raise + 2, 8)] with raise ≥ 4).
                    var i = Int(w.player.shieldRaise) - 1
                    if 4 < i { i = 5 }
                    setFace(face(shield, i))
                    if 5 < w.player.shieldRaise { w.player.shieldRaise -= 1 }
                }
            } else {
                idleReset()
                setFace(face(crouchCast, Int(wand) - 2))
            }
            return
        }
        w.player.airCounter = 0
        w.player.spin = false
        w.player.shieldExtension = 0                                    // `*_DAT_100a05e4 = 0`
        stopSpinSound()

        // Walk / run (`_DAT_100a0730 ∨ _DAT_100a0734`).
        if w.player.walkLeft || w.player.walkRight {
            idleReset()
            if !w.player.walking { w.active.update(id: id) { $0.phase = 0xc } }
            w.player.walking = true
            w.player.standing0670 = false
            let ds = w.player.doubleSpeed                               // `PTR_DAT_100a0620`
            if w.player.runFlag {
                w.active.update(id: id) { p in p.phase &+= 2 }
                w.player.turnCountdown = 0
                if 0x17 < s().phase { w.active.update(id: id) { $0.phase = 0 } }
                let ph = s().phase
                setFace(face(run, Int(ph >> 1)))
                if (!ds && (ph == 6 || ph == 0x10)) || (ds && (ph == 8 || ph == 0x10)) { footstep(w, id: id, volume: 0x78) }
                return
            }
            w.active.update(id: id) { p in p.phase &+= 2 }
            if 0x1f < s().phase { w.active.update(id: id) { $0.phase = 0 } }
            let v = s().vx
            let speed = v < 1 ? 0 &- v : v
            if (0x5db < speed || w.player.facing == w.player.lastFacing) && w.player.turnCountdown < 1 {
                w.player.turnCountdown = 0
                let ph = s().phase
                setFace(face(walk, Int(ph >> 1)))
                if (!ds && (ph == 6 || ph == 0x16)) || (ds && (ph == 8 || ph == 0x20)) { footstep(w, id: id, volume: 0x55) }
                return
            }
        }

        // Stand (l. 45951ff.).
        w.player.walking = false
        if !w.player.standing0670 { w.player.chestFrame = 3 }
        w.player.standing0670 = true
        if w.player.idle < 0x96 {
            if w.player.turnCountdown < 1 {
                if w.player.lastFacing == w.player.facing {
                    setFace(face(stand, Int(w.player.chestFrame)))
                } else {
                    w.player.turnCountdown = 4
                    setFace(face(turn, 0))
                    w.player.turnMirror = true
                }
            } else {
                w.player.turnCountdown -= 1
                switch w.player.turnCountdown {
                case 3:
                    setFace(face(turn, 1))
                    w.player.turnMirror = true
                case 2:
                    setFace(face(turn, 2))
                    w.player.turnMirror = true
                case 1:
                    setFace(face(turn, 1))
                    w.player.turnMirror = false
                case 0:
                    setFace(face(turn, 0))
                    w.player.turnMirror = false
                default:
                    break
                }
            }
            // The potion overlay (`_DAT_100a05b0 > 0`). The potion counter has no Phase-2 writer (// later: Phase 4);
            // built as read.
            let n = Int(w.player.potion)
            if 0 < n {
                if n < 0x14 {
                    var i = (n - 1) >> 1
                    if 4 < i { i = 5 }
                    setFace(face(potion, i))
                } else {
                    var j = (0x27 - n) >> 1
                    if 4 < max(j, 0) { j = 5 } else if j < 1 { j = 0 }
                    setFace(face(potion, j))
                }
            }
            let wand = w.player.wandPhase
            if wand < 1 {
                let kind = s().groundKind
                let uphill = w.player.facing == 1 ? (kind == 0xc || kind &- 0x2c < 2) : (kind == 0xf || kind &- 0x2e < 2)
                if uphill {
                    setFace(face(PlayerStates.uphill, 0))
                    w.player.turnCountdown = 0
                    w.player.turnMirror = false
                }
            } else {
                w.player.turnCountdown = 0
                w.player.turnMirror = false
                idleReset()
                setFace(face(w.player.vBladeCast ? vBladeCast : cast, Int(wand) - 1))
            }
            return
        }
        // Fidgets (idle ≥ 150): m = idle − 150.
        var m = w.player.idle - 0x96
        let raw = Int(m)
        if w.player.fidgets < 3 {
            if raw < 100 {
                if 7 < raw { m = 8 }
                setFace(face(fidget1, Int(m) / 3))
            }
            if m < 100 || 0x8b < m {
                if m < 0x8c || 0x9b < m {
                    if 0x9b < m {
                        w.player.idle = 0
                        w.player.fidgets += 1
                    }
                } else {
                    var k = m - 0x8c
                    if 0xe < k { k = 0xf }
                    setFace(face(fidget1, Int(0xf - k) / 3))
                }
            } else {
                var k = m - 0x5c
                if 0xe < k { k = 0xf }
                setFace(face(fidget1, Int(k) / 3))
            }
        } else {
            setFace(face(fidget2, (raw % 0x14) >> 1))
            if 0xf0 < raw {
                w.player.idle = 0 &- w.rng.next(0x3c)                  // `-FastRand(60)` (raw `10050e50..10050e54`, l. 46044)
                w.player.fidgets = 0
            }
        }
    }

    /// A footstep (l. 45915–45926 run, 45939–45950 walk; the `FastRand(2)` at raw `1005089c..100508a0` run,
    /// `10050998..1005099c` walk): index `PTR_DAT_100a0710` += `FastRand(2)` + 1, −4 past 3;
    /// dry (`+0x120 == 0`) → `.STPlayRegSound(410 + index, 1, volume)` (0x78 run, 0x55 walk); in liquid →
    /// `.STPlay3DSoundRand(454 `_DAT_100a0378`, 1, 0x2a, +0xe)` with its rate drawn here, after the `FastRand(2)`.
    static func footstep(_ w: SpriteWorld, id: Int, volume: Int16) {
        let r = w.rng.next(2)
        w.player.footstep = w.player.footstep &+ r &+ 1
        if 3 < w.player.footstep { w.player.footstep -= 4 }
        guard let s = w.active.record(id: id) else { return }
        if s.lastWater == 0 {
            w.player.cues.append(PlayerCue(call: .reg, snd: 410 + w.player.footstep, priority: 1, volume: volume))
        } else {
            let rate = w.rng.soundRate()
            w.player.cues.append(PlayerCue(call: .threeDRand, snd: 454, priority: 1, volume: 0x2a, position: s.centre,
                                           rate: rate))
        }
    }

    /// The airborne arm (l. 46054–46196; player-states §3.12): the air counter `_DAT_100a0718` c — c < 10: rising
    /// (vy < 1) and not spinning → c + 1; else c < 3 → 0x12; else c + 2. c ≥ 10: c + 1 only falling, not spinning, not
    /// in wind (`+0x92`). In wind and c > 14 → c − 1; spinning → 0x1a; Feather Fall or launched → ≤ 15 (launched also
    /// steps the tumble frame `_DAT_100a05b4` mod 8). Faces: spinning → launched 0, spin frame +1 mod 8, 1025[frame];
    /// else turn countdown 0, turn mirror 0, and launched → 1015[tumble frame] (returns true: the facing is not
    /// refreshed), else 1010[bucket(c)].
    static func airborne(_ w: SpriteWorld, id: Int) -> Bool {
        guard let s = w.active.record(id: id) else { return false }
        if 0 < w.player.idle { w.player.idle = w.player.fidgets }
        w.player.standing0670 = false
        w.player.crouch = 0
        let spinning = w.player.spin
        let c0 = w.player.airCounter
        if c0 < 10 {
            if s.vy < 1 && !spinning {
                w.player.airCounter = c0 + 1
            } else if c0 < 3 {
                w.player.airCounter = 0x12
            } else {
                w.player.airCounter += 2
            }
        } else if 0 < s.vy && !spinning && !s.inWind {
            w.player.airCounter = c0 + 1
        }
        if s.inWind && 0xe < w.player.airCounter { w.player.airCounter -= 1 }
        if spinning { w.player.airCounter = 0x1a }
        if w.player.featherFall { w.player.airCounter = min(w.player.airCounter, 0xf) }
        let launched = w.player.launched
        if launched {
            w.player.tumbleFrame += 1
            if 7 < w.player.tumbleFrame { w.player.tumbleFrame = 0 }
            w.player.airCounter = min(w.player.airCounter, 0xf)
        }
        let b = bucket(w.player.airCounter)
        var tumbleDrawn = false
        let f: FaceRef
        if !spinning {
            w.player.turnCountdown = 0
            w.player.turnMirror = false
            if !launched {
                f = face(air, b)
            } else {
                tumbleDrawn = true
                f = face(tumble, Int(w.player.tumbleFrame))
            }
        } else {
            w.player.launched = false
            w.player.spinFrame += 1
            if 7 < w.player.spinFrame { w.player.spinFrame = 0 }
            f = face(spin, Int(w.player.spinFrame))
        }
        w.active.update(id: id) { $0.face = f }
        return tumbleDrawn
    }

    /// The air counter's face bucket (l. 46100–46140): < 0 → 9; 0–1 → 0; 2–3 → 1; 4–5 → 2; 6–7 → 3; 8–15 → 4;
    /// 16–23 → 5; 24–29 → 6; 30–35 → 7; 36–41 → 8; ≥ 42 → 9.
    static func bucket(_ c: Int16) -> Int {
        if c < 0x10 {
            if c < 4 {
                if c < 2 { return c < 0 ? 9 : 0 }
                return 1
            }
            if c < 8 { return c < 6 ? 2 : 3 }
            return 4
        }
        if c < 0x24 {
            if c < 0x1e { return c < 0x18 ? 5 : 6 }
            return 7
        }
        return c < 0x2a ? 8 : 9
    }

    // MARK: - row 36

    /// Row 36 (l. 46242–46346): `0708` = 0; the teleporter charge `PTR_DAT_100a0700` +1 while touching (`070c`) or
    /// negative, else −8 to 0; then by the charge n:
    /// - n = 0: the **invulnerability blink** — parity `_DAT_1009fd30` set ∧ `+0x116 ≥ 15` ∧ not stunned →
    ///   `+0xb8 = 0x10006`, `+0x18c = 1`, and over 60 `0x10009`, `+0x1a6 = 0xdc`, `+0x1a8 = 0x10`; otherwise the
    ///   power-up tints (walk-on-liquid / High Jump / Feather Fall / Double Speed with their `0644/0634/0628/061c`
    ///   flags; // later: Phase 4 — all false in Phase 2) or 0, and `+0xb8 == 0` → `+0x1a6 = +0x1a8 = 0`, `+0x88 = 1`,
    ///   else `+0x88 = 0`, `+0x1a8 = 8`;
    /// - |n| < 21 → `+0xb8 = 0`, `+0x18c = 0`; 21…59 → the sparkle `0x50000 + clamp(min(((|n| − 12) >> 2) + 2, 15) +
    ///   FastRand(6) − 3, 0, 15)`, `+0x18c = 1`; 60…79 → 0x4f; 80 → `0708` = 1 (fire). // later: Phase 3 (teleporters)
    /// - `070c` = 0.
    static func tint(_ w: SpriteWorld, id: Int) {
        w.player.teleporterFire = false
        let c = w.player.teleporterCharge
        if !w.player.teleporterTouch && -1 < c {
            if 0 < c {
                w.player.teleporterCharge = c - 8
                if w.player.teleporterCharge < 0 { w.player.teleporterCharge = 0 }
            }
        } else {
            w.player.teleporterCharge &+= 1
        }
        let n = w.player.teleporterCharge
        guard let s = w.active.record(id: id) else { return }
        if n == 0 {
            if !w.parity || s.invulnerable < 0xf || w.player.stun != 0 {
                var mode: UInt32 = 0
                var glow = s.glowKind
                if w.player.tint0644 && w.player.walkOnLiquid {
                    // kinds other than 0, 1, 2 leave `+0xb8` as it was (no store on that path).
                    let k = w.player.walkOnLiquidKind
                    mode = s.mode
                    if k == 1 { mode = 0x1000a } else if k == 0 { mode = 0x10004 } else if k == 2 { mode = 0x10001 }
                    glow = k &+ 0xdc
                } else if w.player.tint0634 && w.player.highJump {
                    mode = 0x1000c
                    glow = 9
                } else if w.player.tint0628 && w.player.featherFall {
                    mode = 0x10003
                    glow = 0xdf
                } else if w.player.tint061c && w.player.doubleSpeed {
                    mode = 0x10008
                    glow = 0xdf
                }
                let m = mode, g = glow
                w.active.update(id: id) { p in
                    p.mode = m
                    p.glowKind = g
                    if m == 0 {
                        p.glowKind = 0
                        p.glowChance = 0
                        p.lightOverlay = true
                    } else {
                        p.lightOverlay = false
                        p.glowChance = 8
                    }
                }
            } else {
                let over = 0x3c < s.invulnerable
                w.active.update(id: id) { p in
                    p.mode = 0x10006
                    p.noWaterSplit = true
                    if over {
                        p.mode = 0x10009
                        p.glowKind = 0xdc
                        p.glowChance = 0x10
                    }
                }
            }
        } else {
            let a = Int(n < 1 ? 0 &- n : n)
            if a < 0x3c {
                if a < 0x15 {
                    w.active.update(id: id) { p in
                        p.mode = 0
                        p.noWaterSplit = false
                    }
                } else {
                    var k = Int16(truncatingIfNeeded: (a - 0xc) >> 2) + 2
                    if 0xf < k { k = 0xf }
                    k = w.rng.next(6) &+ k &- 3
                    if 0xf < k { k = 0xf }
                    if k < 0 { k = 0 }
                    let m = UInt32(truncatingIfNeeded: Int(k) + 0x50000)
                    w.active.update(id: id) { p in
                        p.mode = m
                        p.noWaterSplit = true
                    }
                }
            } else if a < 0x50 {
                w.player.teleporterCharge = 0x4f
            } else if n == 0x50 {
                w.player.teleporterFire = true
            }
        }
        w.player.teleporterTouch = false
    }
}
