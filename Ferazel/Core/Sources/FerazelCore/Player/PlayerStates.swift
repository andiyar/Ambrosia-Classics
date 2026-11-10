import Foundation

/// `.HandlePlayerSprite` row 33 — the state / face selection (decompile l. 45219–46196, `goto LAB_10050e6c`; raw
/// `1004ec4c..10050e6c`; player-states §3) — and row 36's tint (l. 46242–46346): plan P3. **First match wins**, in the binary's order: glider → dying → spirit transition → boss grab →
/// hurt-stun → door walk (`_DAT_100a05f8`) → rope → swim → wall cling / climb / pull-up → melee (`.HandleItemUse`) →
/// grounded (crouch, walk / run with footsteps, stand / turn / uphill / fidget) → airborne. The glider arm is GL's,
/// the spirit transition and the dying arm's necklace revive MS's; the boss-grab arm is a named stub (no writer until
/// Phase 6: 6A-CH, 6C-XI); the melee arm is IU's `.HandleItemUse`, `HeldItem`; the door
/// arm is W2b's (passages) (plan Invariant 6). A face is `+0xc0 = set + index·0x34` (one 0x34-byte face record per index).
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
    /// 1038 (`_DAT_100a0780`, 4 × 100×120): the spirit transition, both ways, and the Mist body's face 3 (MS).
    public static let mist: Int16 = 1038
    /// 1033 (`_DAT_100a07a0`): the door walk-in (W2b).
    public static let walkIn: Int16 = 1033
    /// The glider's cached sets (`_CacheEncFaceSetFromPICT`, l. 42486–42489; 160×160 cells): 1050 deploy / stow / turn
    /// (`_DAT_100a0778`, 6), 1051 the glide loop (`_DAT_100a0774`, 4), 1052 pitch (`_DAT_100a0770`, 6: nose up 0…2,
    /// down 3…5), 1053 casting (`_DAT_100a076c`, 4).
    /// `gliderDeploy` is the same set as `HitPlayerSprite.gliderFaceSet` (0x41a).
    public static let gliderDeploy: Int16 = 1050, gliderLoop: Int16 = 1051, gliderPitch: Int16 = 1052
    public static let gliderCast: Int16 = 1053

    /// A player face's width (face `+6`) for `.StandardSpriteCleanup`: the set's cell width (150 for 1022, 120 for
    /// 1023, 160 for the glider's 1050…1053, else 100 — the single 1004 is 100×120 too). The sets themselves are FerazelRender's
    /// `FaceSheet.playerSheets` (the one table, `.InitPlayerSprite` l. 42427–42484); `FaceTests.testPlayerFaceSetsTable`
    /// checks these widths against it.
    public static func faceWidth(_ f: FaceRef) -> Int {
        switch f.pict {
        case dying: return 0x96
        case pullUp: return 0x78
        case gliderDeploy...gliderCast: return 0xa0
        default: return 100
        }
    }

    @inline(__always) static func face(_ pict: Int16, _ index: Int) -> FaceRef {
        FaceRef(pict: pict, index: index, set: .encoded)
    }

    // MARK: - row 33

    /// Row 33's glider arm (l. 45219–45471; raw `1004ec4c…`; spells-detail §5.2–§5.4). Idle and stun 0, the glider rect
    /// `SetRect(+0x34, 0x37, 0x3e, 99, 0x61)`. Ground contact (`+0xce` or `+0xcd`) not riding (`+0xdc` 0) → the count
    /// `PTR_DAT_100a05c8` + 1, vx = (int)(vx · 0.5) (`dRam100a1a28`, fctiwz), vy 0x100; else count 0. Count > 12 at
    /// phase 0 → phase −23 (the stow then runs this same frame). Alive (`_DAT_100a069c` 0): vy ≤ 2000. Then by phase:
    /// - 0, gliding: the loop counter `_DAT_100a05dc` + 1 (0…0x1f), face 1051[c >> 3]. No turn running: wand step
    ///   (`_DAT_100a06d4`) < 3 — pitch 0 → dive counter `PTR_DAT_100a05cc` 0; pitch p ≠ 0, k = |p| >> 1: p < 0 → face
    ///   1052[k]; p > 0 → 1052[k + 3], and k 2 (pitch 4…5) → dive counter + 1 (≤ 30), vx ±0x50 toward the facing
    ///   (`+0x17e` 0 → +, while vx < 0xc80; else −, while vx > −0xc80); k < 2 with a counter c > 0 → vy +=
    ///   trunc(−0x640·c / 30). Wand step ≥ 3 → face 1053[step − 3]. A turn t ≠ 0: t → 1 toward 0, k = min(|t| >> 1, 5);
    ///   k < 3 → face 1050[5 − k] and the facing toward the turn (old t < 1 → `+0x17e` 0, F 2; else 1, F 1); k ≥ 3 →
    ///   face 1050[k] and the facing still away from it; t reaching 0 → face 1051[0].
    /// - < 0, stowing: face 1050[|phase| >> 2], vx 0, gravity 0, vy 0x100; phase < −16 → `+0x1c` −= 0x200 (`+0xa` from
    ///   it); phase + 1; at 0: `.MTNewSprite(0xbea, +0xc, +0xa, 2, −1, .SetupBonusSprite)` (`_DAT_1009ff38`), the
    ///   cooldown `PTR_DAT_100a05c4` = 180, glider off, gravity 0x1b8, `+0x14` += 0x1e00, `+0x1c` += 0x2000 (0xa00 while
    ///   `PTR_DAT_100a04cc`), the stand face `*_DAT_100a07ec` and the standard rect.
    /// - > 0, deploying: phase 1 → vy 0, gravity 0; phase < 24 → face 1050[phase >> 2], phase + 1, past 16 → gravity
    ///   −0x78, vx 0; else gravity < 100 → loop counter + 1, face 1051[c >> 3], gravity + 0x1e; else the loop step and
    ///   phase 0.
    /// Dying on the glider (`_DAT_100a069c > 0`): the dying arm's counters without its faces — idle reset, `+0x5c` 0,
    /// vx 0, climb 0, phase 0, gravity 0x17c, pitch + 1 (≤ 5), d < 30 → buoyancy / float line / rect drift, `+0x116`
    /// 0, d + 1; at the end `DAT_100a5106 = 1` — never the Resurrection Necklace (`_DAT_100a05e0 ≠ 0`, l. 45449).
    static func glider(_ w: SpriteWorld, id: Int) {
        guard var s = w.active.record(id: id) else { return }
        var p = w.player
        p.idle = 0
        p.stun = 0
        s.hotRect = IdleSprites.Rect(top: 0x3e, left: 0x37, bottom: 0x61, right: 99)
        if (s.groundKind == 0 && s.onSprite == 0) || s.ridden != nil {
            p.glider05c8 = 0
        } else {
            p.glider05c8 &+= 1
            s.vx = TileSolver.fctiwz(Double(s.vx) * 0.5)
            s.vy = 0x100
        }
        if 0xc < p.glider05c8 && p.gliderExit == 0 { p.gliderExit = -0x17 }
        if 2000 < s.vy && p.dying == 0 { s.vy = 2000 }
        func loopStep() {
            p.gliderLoop &+= 1
            if 0x1f < p.gliderLoop { p.gliderLoop = 0 }
            s.face = face(gliderLoop, Int(p.gliderLoop >> 3))
        }
        let phase = p.gliderExit
        if phase == 0 {
            loopStep()
            let t = p.gliderTurn
            if t == 0 {
                let step = p.wandPhase
                if step < 3 {
                    let pitch = p.gliderPitch
                    if pitch == 0 {
                        p.gliderDive = 0
                    } else {
                        let k = Int(abs(Int32(pitch)) >> 1)
                        if pitch < 0 {
                            s.face = face(gliderPitch, k)
                        } else {
                            s.face = face(gliderPitch, k + 3)
                            if k == 2 {
                                if p.gliderDive < 0x1e { p.gliderDive += 1 }
                                if !s.mirrored {
                                    if s.vx < 0xc80 { s.vx &+= 0x50 }
                                } else if -0xc80 < s.vx {
                                    s.vx &-= 0x50
                                }
                            } else if 0 < p.gliderDive {
                                s.vy &+= Int32(p.gliderDive) &* -0x640 / 0x1e
                            }
                        }
                    }
                } else if 0 < step {
                    s.face = face(gliderCast, Int(step) - 3)
                }
            } else {
                if t < 0 { p.gliderTurn = t + 1 } else if 0 < t { p.gliderTurn = t - 1 }
                let k = min(Int(abs(Int32(p.gliderTurn)) >> 1), 5)
                let towardTurn = k < 3
                s.face = face(gliderDeploy, towardTurn ? 5 - k : k)
                let left = (t < 1) != towardTurn                     // `+0x17e`
                s.mirrored = left
                p.facing = left ? 1 : 2                              // `_DAT_100a5f5a`
                if p.gliderTurn == 0 { s.face = face(gliderLoop, 0) }
            }
        } else if phase < 1 {
            s.face = face(gliderDeploy, Int(abs(Int32(phase))) >> 2)
            s.vy = 0
            s.gravity = 0
            s.vx = 0
            s.vy = 0x100
            if p.gliderExit < -0x10 {
                s.y256 &-= 0x200
                s.y = Int(Int16(truncatingIfNeeded: s.y256 >> 8))
            }
            p.gliderExit += 1
            if p.gliderExit == 0 {
                dropGlider(w, x: s.x, y: s.y)
                p.countdown05c4 = 0xb4
                p.glider = false
                s.gravity = 0x1b8
                s.x256 &+= 0x1e00
                s.y256 &+= p.oneWayTimer == 0 ? 0x2000 : 0xa00
                s.face = face(stand, 0)
                s.hotRect = HandleKeys.standardHotRect
            }
        } else {
            if phase == 1 {
                s.vy = 0
                s.gravity = 0
            }
            if p.gliderExit < 0x18 {
                s.face = face(gliderDeploy, Int(p.gliderExit >> 2))
                p.gliderExit += 1
                if 0x10 < p.gliderExit { s.gravity = -0x78 }
                s.vx = 0
            } else if s.gravity < 100 {
                loopStep()
                s.gravity += 0x1e
            } else {
                loopStep()
                p.gliderExit = 0
            }
        }
        if 0 < p.dying {
            if 0 < p.idle { p.idle = p.fidgets }
            s.hasHit = false                                         // `+0x5c = 0`
            p.shadowDouble = false                                   // `*PTR_DAT_100a0654 = 0` (M l. 45410)
            s.vx = 0
            p.climb = 0
            p.gliderExit = 0
            s.gravity = 0x17c
            if p.gliderPitch < 5 { p.gliderPitch += 1 }
            let d = p.dying
            if d < 0x1e {
                s.buoyancy = Int16(truncatingIfNeeded: Int(UInt16(bitPattern: d) & 1) + Int(s.buoyancy) + 1)
                s.floatOffset = -0x16                                // `+0x1a0 = 0xffea`
                if 8 < d {
                    let dx = s.mirrored ? -2 : 2
                    s.hotRect.left += dx                             // `+0x36`
                    s.hotRect.right += dx                            // `+0x3a`
                }
            }
            s.invulnerable = 0
            p.dying &+= 1
            let ended = p.diedInLiquid ? 100 < p.dying : 0x50 < p.dying
            // `.HasItemWhichSlot(0x17, …)` is called but the glider sends every end to `DAT_100a5106 = 1`.
            if ended { p.gameOver = true }
        }
        w.player = p
        let out = s
        w.active.update(id: id) { $0 = out }
    }

    /// The Resurrection Necklace's revive frame (MS; M l. 45504–45522; physics §5.2, player-states §3.2), while
    /// `PTR_DAT_100a0594` r > 0 (after the dying counter's + 1): `+0x19e = 0`, face 1022[(30 − r) / 3] (the death
    /// backwards), r + 1; past 30 → `G+6 = G+4 = +0xa4 = G+10` (breath, health, HP = the maximum), dying 0, r 0,
    /// `+0x116 = 0x3c`, `PTR_DAT_100a055c = 1`, `.RemoveItem(0x17)` (its `.UpdateItemStat`), `SetRect(+0x34, 0x26, 0x22,
    /// 0x3e, 0x55)`.
    static func reviveStep(_ w: SpriteWorld, id: Int) {
        let r = w.player.revive
        w.active.update(id: id) { p in
            p.buoyancy = 0
            p.face = face(dying, Int(0x1e - r) / 3)
        }
        w.player.revive = r &+ 1
        guard 0x1e < w.player.revive else { return }
        let m = w.globals.maxHealth
        w.globals.breath = m
        w.globals.health = m
        w.player.dying = 0
        w.player.revive = 0
        w.active.update(id: id) { p in
            p.hp = m
            p.invulnerable = 0x3c
        }
        w.player.flag055c = true
        Player.removeItem(w, 0x17)
        w.active.update(id: id) { $0.hotRect = HandleKeys.standardHotRect }
    }

    /// The dying arm's end (dying > 80, or > 100 after a death in liquid; M l. 45531–45553): `.HasItemWhichSlot(0x17)`;
    /// none, the forced death `*_DAT_100a0568` (the debug key / the auto-scroll death — no Core writer, so 0) or the
    /// glider (`_DAT_100a05e0`; the glider's dying runs inside its own arm, so never here) → `DAT_100a5106 = 1`, the game
    /// over; the centre `fd94`/`fd90` outside the map (x < 0 or > 32·hdr`+0xb280`, y < 0 or > 32·hdr`+0xb282`) → the
    /// game over too; else the revive starts: the item flash mode `_DAT_1009fda0` 0, count `PTR_DAT_1009fda8` 0x1e, slot
    /// `_DAT_1009fda4` = the necklace's, dying back to 0x1e, `PTR_DAT_100a0594 = 1`, `.STPlay3DSoundPitched(420, 1,
    /// 0x100, +0xe, 40000)` (`_DAT_100a03e0`; no draw), `PTR_DAT_100a05a8 = 0x14`. The game-over call is not repeated
    /// on later frames by anything here: the flag ends `.GameLoop` after this iteration.
    static func necklaceOrGameOver(_ w: SpriteWorld, id: Int) {
        guard let slot = w.globals.hasItemWhichSlot(0x17), !w.player.glider else {
            w.player.gameOver = true
            return
        }
        let cx = Int32(w.player.centreX), cy = Int32(w.player.centreY)
        let mapW = Int32(w.level.header.gridWidth) << 5, mapH = Int32(w.level.header.gridHeight) << 5
        if cx < 0 || mapW < cx || cy < 0 || mapH < cy {
            w.player.gameOver = true
            return
        }
        w.statusBar.flashes.itemMode = 0
        w.statusBar.flashes.item = 0x1e
        w.statusBar.flashes.itemSlot = Int16(slot)
        w.player.dying = 0x1e
        w.player.revive = 1
        let pos = w.active.record(id: id)?.centre
        w.player.cue(PlayerCue(call: .threeDPitched, snd: 420, priority: 1, volume: 0x100, position: pos,
                               rate: 40000))
        w.player.countdown05a8 = 0x14
    }

    /// Row 33's spirit transition arm (MS; M l. 45555–45589, the timer stores raw `1004fb04`, `1004fb88`;
    /// player-states §3.3), while `_DAT_100a0574` n > 0: v = 0; n < 13 → face 1038[n >> 2] (`_DAT_100a0780`), n + 1, and at 13: vy = −0x35c, the
    /// body position `PTR_DAT_100a04d4` / `04d0` = `+0xc` / `+0xa`, the timer `_DAT_100a0578 = 600`, n = 0,
    /// `_DAT_100a056c = 0`, the body `.MTNewSprite(0x45, +0xc, +0xa, (i16) +0x80, −1, .SetupBonusSprite)` into
    /// `PTR_DAT_100a0550` with the player's `+0x17e`. n > 13 (the way back, from the body's arm's 14) → face
    /// 1038[(27 − n) >> 2], n + 1, past 26 → n = 0 and the timer 0.
    static func spiritTransition(_ w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id) else { return }
        w.active.update(id: id) { p in
            p.vy = 0
            p.vx = 0
        }
        let n = w.player.spiritTransition
        if n < 0xd {
            w.active.update(id: id) { $0.face = face(mist, Int(n >> 2)) }
            w.player.spiritTransition = n + 1
            guard w.player.spiritTransition == 0xd else { return }
            w.active.update(id: id) { $0.vy = -0x35c }
            let x = Int(Int16(truncatingIfNeeded: s.x)), y = Int(Int16(truncatingIfNeeded: s.y))
            w.player.mistBodyX = Int32(x)
            w.player.mistBodyY = Int32(y)
            w.player.spiritTimer = 600
            w.player.spiritTransition = 0
            w.player.spiritBlink = false
            let body = w.newSprite(type: Player.spriteType, x: x, y: y, layer: Int16(truncatingIfNeeded: s.layer),
                                   handler: .bonus) { b in
                // Cannot throw: `BonusSprite.setup` throws `notTranscribed` only from its default arm (0xc25, or any
                // type there outside the items 0xc80…0xc9a, e.g. 0x4c3); 0x45 has its own arm.
                _ = try! BonusSprite.setup(&b, x: x, y: y, level: w.level, records: w.records, effects: 0, lightCount: 0,
                                           counting: false, rng: &w.rng) { _, _, _, _ in -1 }
            }
            w.player.mistBody = body
            if let body { w.active.update(id: body) { $0.mirrored = s.mirrored } }   // no free record: dropped
        } else if 0xd < n {
            w.active.update(id: id) { $0.face = face(mist, Int(0x1b - n) >> 2) }
            w.player.spiritTransition = n + 1
            if 0x1a < w.player.spiritTransition {
                w.player.spiritTransition = 0
                w.player.spiritTimer = 0
            }
        }
    }

    /// The stow's `.MTNewSprite(0xbea, x, y, 2, −1, .SetupBonusSprite)` (M l. 45354–45356): the Bonus Setup's 0xbea arm
    /// (M l. 52611–52627) — no light — and its tail's `FastRand(60)`; the Setup puts it on layer 1 (M l. 52383).
    static func dropGlider(_ w: SpriteWorld, x: Int, y: Int) {
        _ = w.newSprite(type: 0xbea, x: x, y: y, layer: 2, handler: .bonus) { b in
            // Cannot throw: `BonusSprite.setup` throws `notTranscribed` only from its default arm (0xc25, or any type
            // there outside the items 0xc80…0xc9a, e.g. 0x4c3); 0xbea has its own arm.
            _ = try! BonusSprite.setup(&b, x: x, y: y, level: w.level, records: w.records, effects: 0, lightCount: 0,
                                       counting: false, rng: &w.rng) { _, _, _, _ in -1 }
        }
    }

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
        func stopSpinSound() { w.player.cue(PlayerCue(call: .stopIfPlaying, snd: 427)) }

        // Glider (`_DAT_100a05e0`, l. 45219–45471, incl. dying on the glider; GL).
        if w.player.glider {
            glider(w, id: id)
            return false
        }

        // Dying (`_DAT_100a069c > 0`, M l. 45473–45554).
        if 0 < w.player.dying {
            idleReset()
            set { p in
                p.hasHit = false                                     // `+0x5c = 0`
                p.vx = 0
            }
            w.player.shadowDouble = false                            // `*PTR_DAT_100a0654 = 0` (M l. 45478)
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
            if 0 < w.player.revive { reviveStep(w, id: id) }
            let ended = w.player.diedInLiquid ? 100 < w.player.dying : 0x50 < w.player.dying
            if ended { necklaceOrGameOver(w, id: id) }
            return false
        }
        // Spirit transition (`_DAT_100a0574 > 0`, M l. 45555–45589; MS).
        if 0 < w.player.spiritTransition {
            spiritTransition(w, id: id)
            return false
        }
        // Boss grab (`_DAT_100a0570 > 0`, l. 45625–45672). // later: Phase 6 (Chief, Xichra; no Phase-2 writer)
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
        // Door walk-in / walk-out (`_DAT_100a05f8 ≠ 0`, l. 45661–45682; raw `1004fddc..1004fe80`; W2b — the passage arm
        // of `.HitPlayerSprite` writes it): n = |05f8|, idle `_DAT_100a068c` = 0, k = n >> 1; n < 0 (walk-out) → k >>= 1,
        // at most 2, face 1030[k] (`_DAT_100a07ac`); else at most 5, face 1033[k] (`_DAT_100a07a0`); then 05f8 += 1 —
        // so the walk-in counts up until the jump sets −15 and the walk-out stops at 0.
        let door = w.player.animation05f8
        if door != 0 {
            let n = door < 1 ? 0 &- Int32(door) : Int32(door)
            w.player.idle = 0
            var k = Int16(truncatingIfNeeded: n >> 1)
            if door < 1 {
                k = k >> 1
                if 2 < k { k = 2 }
                setFace(face(turn, Int(k)))
            } else {
                if 5 < k { k = 5 }
                setFace(face(walkIn, Int(k)))
            }
            w.player.animation05f8 = door &+ 1
            return false
        }

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
                HeldItem.handleItemUse(w, player: id)                   // M l. 45727–45729: the stab while swimming (IU)
            }
            if 1 < w.player.swim { w.player.swim += 1 }
            if w.player.strokeCooldown == 0 { w.player.jumpCounter = 6 }
            if !w.player.nearSurface {
                set { p in if p.vy < 0 { p.vy &+= 200 } }
                if 0x12 < s().lastWater && k == 5 {
                    Splash.splash(w, id: id, mode: 3)                   // `.Splash(s, 3)` (l. 45741; E1a)
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
        // Melee / throw (`_DAT_100a0698 ≠ 0`, M l. 45817–45820): `.HandleItemUse` (IU), then `goto LAB_10050e6c`.
        if w.player.itemUse != 0 {
            HeldItem.handleItemUse(w, player: id)
            return false
        }

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
        w.player.cue(PlayerCue(call: .stopIfPlaying, snd: 427))   // `_DAT_100a03cc`
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
        w.player.cue(PlayerCue(call: .stopIfPlaying, snd: 427))
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
        func stopSpinSound() { w.player.cue(PlayerCue(call: .stopIfPlaying, snd: 427)) }

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
                    // Without `.HasItem(0xf)` (the Magical Shield) or below 4: 1039[min(raise − 1, 5)]; with it
                    // from 4: 1039[min(raise + 2, 8)] (M l. 45843–45856; ES).
                    var i: Int
                    if !w.globals.hasItem(0xf) || w.player.shieldRaise < 4 {
                        i = Int(w.player.shieldRaise) - 1
                        if 4 < i { i = 5 }
                    } else {
                        i = Int(w.player.shieldRaise) + 2
                        if 7 < i { i = 8 }
                    }
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
            // The potion overlay (`_DAT_100a05b0 > 0`; the item switch starts the drink, row 32 counts it — IU).
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
            w.player.cue(PlayerCue(call: .reg, snd: 410 + w.player.footstep, priority: 1, volume: volume))
        } else {
            let rate = w.rng.soundRate()
            w.player.cue(PlayerCue(call: .threeDRand, snd: 454, priority: 1, volume: 0x2a, position: s.centre,
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
    ///   flags, set by the spheres' timers, `PowerUps`) or 0, and `+0xb8 == 0` → `+0x1a6 = +0x1a8 = 0`, `+0x88 = 1`,
    ///   else `+0x88 = 0`, `+0x1a8 = 8`;
    /// - |n| < 21 → `+0xb8 = 0`, `+0x18c = 0`; 21…59 → the sparkle `0x50000 + clamp(min(((|n| − 12) >> 2) + 2, 15) +
    ///   FastRand(6) − 3, 0, 15)`, `+0x18c = 1`; 60…79 → 0x4f; 80 → `0708` = 1 (fire; the teleporters' arm, TP)
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
