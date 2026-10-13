import XCTest
@testable import FerazelCore

/// S1 (docs/plans/2026-10-10-ferazel-phase2.md): the Sound Tool's cue arithmetic in Core — `.STPlayRegSound @ 10047580`,
/// `.STPlayRegSoundPitched @ 10047c98`, `.STPlay3DSound @ 10047ac0`, `.STPlay3DSoundPitched @ 10047b8c`,
/// `.STPlay3DSoundRand @ 10047d44`, `.CalcStereoVolume @ 10047738`, `.PEDistance @ 10047648` (decompile l. 40605–41010;
/// sprites-backgrounds-sounds §6.3), the global volume prefs+0xe · 0x1c (l. 7248), stops `FUN_10091504` →
/// `FrameOps.soundStops`, only-if-idle `FUN_100916dc` → `SoundCue.onlyIfIdle`. Every number is hand arithmetic next to
/// the assertion (global volume 7 · 0x1c = 196 unless named).
final class SoundCueTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    private func prefs(on: UInt8 = 1, volume: Int16 = 7) -> FerazelPrefs {
        var p = FerazelPrefs()
        p.soundOn = on
        p.soundVolume = volume
        return p
    }

    private func call(_ c: PlayerCue, h: Int = 0, v: Int = 0) -> PlayerState.SoundCall {
        PlayerState.SoundCall(cue: c, scrollH: h, scrollV: v)
    }

    private func cue(_ snd: Int16, _ prio: Int, _ l: Int, _ r: Int, _ rate: UInt32 = 0x10000,
                     idle: Bool = false) -> SoundCue {
        SoundCue(snd: snd, priority: prio, left: l, right: r, rate: rate, onlyIfIdle: idle)
    }

    private func emit(_ calls: [PlayerState.SoundCall], _ p: FerazelPrefs = FerazelPrefs()) -> FrameOps {
        var ops = FrameOps()
        SoundCues.emit(calls, prefs: p, into: &ops)
        return ops
    }

    /// A level-1 world with the player standing on a synthetic floor (row 12), outputs drained (as `PlayerTileTests`).
    private func standingWorld() throws -> SpriteWorld {
        let w = SpriteWorld(level: try LevelFile.load(from: try resources(), level: 1))
        var fg = [UInt16](repeating: 0, count: 16 * 16)
        for c in 0..<16 { fg[12 * 16 + c] = 3 + 1 }
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: fg),
                           bg: TileMap(width: 16, height: 16, cells: [UInt16](repeating: 0, count: 16 * 16)),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        XCTAssertNotNil(Player.spawn(world: w, x: 100, y: 400 - 0x55))
        let solver = TileSolver(world: w)
        for _ in 0..<2 {
            _ = w.player.drainFrameOutputs()
            Player.handle(world: w, keys: [], solver: solver)
        }
        XCTAssertEqual(w.active.sprite(id: w.playerID!)!.groundKind, 3)
        _ = w.player.drainFrameOutputs()
        w.player.soundCalls = []
        return w
    }

    // MARK: - Reg

    func testJumpCue() throws {
        // Through the session: level 1, three idle iterations, then JUMP (action 5 = Option 0x3a). `.HandleKeys`'
        // `.STPlayRegSound(414, 1, 0x9c)`: (0x9c · 196) >> 8 = 30576 >> 8 = 119, each side 119 >> 1 = 59, rate 0x10000.
        func jumpFrame(_ p: FerazelPrefs) throws -> FrameOps {
            let s = try FerazelSession(resources: try resources(), prefs: p, level: 1)
            for _ in 0..<3 { _ = s.step(keys: KeyState()) }
            return s.step(keys: KeyState(pressed: [0x3a]))
        }
        let ops = try jumpFrame(prefs())
        XCTAssertEqual(ops.sounds, [cue(414, 1, 59, 59)])
        // The grounded arm's stop 427 (`FUN_10091504`, a stop, not a play).
        XCTAssertEqual(ops.soundStops, [427])
        // Volume 5 → 140: (156 · 140) >> 8 = 85 → 42; volume 0 → 0/0 (Reg has no drop).
        XCTAssertEqual(try jumpFrame(prefs(volume: 5)).sounds, [cue(414, 1, 42, 42)])
        XCTAssertEqual(try jumpFrame(prefs(volume: 0)).sounds, [cue(414, 1, 0, 0)])
        // Sound off (prefs+0xb 0): no play; the stop is still called (it is not gated).
        let off = try jumpFrame(prefs(on: 0))
        XCTAssertEqual(off.sounds, [])
        XCTAssertEqual(off.soundStops, [427])
        XCTAssertEqual(SoundCues.globalVolume(prefs()), 196)
        XCTAssertEqual(SoundCues.globalVolume(prefs(volume: 3)), 84)
        // The snd-slot table (`.InitSounds @ 10045838`): a snd with no slot has a nil handle → `param_1 == 0` → nothing.
        XCTAssertEqual(SoundSlots.snd(slot: 0x100a03f8), 414)
        XCTAssertEqual(SoundSlots.snd(slot: 0x100a03cc), 427)
        XCTAssertEqual(SoundSlots.snd(slot: 0x100a025c, index: 1), 411)
        XCTAssertEqual(SoundSlots.snd(slot: 0x100a0300, index: 2), 491)
        XCTAssertEqual(SoundSlots.table.count, 144)
        XCTAssertEqual(emit([call(PlayerCue(call: .reg, snd: 412 + 1000, priority: 1, volume: 0x100))]).sounds, [])
        // Call order with stops: a stop cancels the plays of its snd made earlier in the iteration (the original stops
        // them in the same iteration), so the shell applies `soundStops` before `sounds`; a play after the stop stays.
        let mixed = emit([call(PlayerCue(call: .reg, snd: 427, priority: 1, volume: 0xba)),
                          call(PlayerCue(call: .reg, snd: 414, priority: 1, volume: 0x9c)),
                          call(PlayerCue(call: .stopIfPlaying, snd: 427)),
                          call(PlayerCue(call: .stop, snd: 493)),
                          call(PlayerCue(call: .reg, snd: 493, priority: 1, volume: 0x100)),
                          call(PlayerCue(call: .reg, snd: 427, priority: 1, volume: 0xba))])
        // 0xba · 196 >> 8 = 142 → 71; 0x100 → 196 → 98.
        XCTAssertEqual(mixed.sounds, [cue(414, 1, 59, 59), cue(493, 1, 98, 98), cue(427, 1, 71, 71)])
        XCTAssertEqual(mixed.soundStops, [427, 493])
    }

    func testLandingCues() throws {
        // `.CheckGroundCeilingHitEffects`: v = impact >> 7; 0x2000 → 64 → 600 prio 0x14 vol 2·64 + 0x14 = 148:
        // (148 · 196) >> 8 = 113 → 56. 0x1000 → 32 < 0x30 → 0, impact > 700 → 601 prio 0x14 vol 0x3c: 45 → 22.
        // 0x2b0 = 688 ≤ 700 → no play. Each landing stops 414 then 427 first.
        for (impact, sounds): (Int32, [SoundCue]) in [(0x2000, [cue(600, 20, 56, 56)]), (0x1000, [cue(601, 20, 22, 22)]),
                                                      (0x2b0, [])] {
            let w = try standingWorld()
            w.active.update(id: w.playerID!) { $0.groundKind = 3 }
            w.player.groundLast = 0
            w.player.landedLatch = false
            w.player.impact = impact
            GroundCeilingEffects.check(w, id: w.playerID!)
            let ops = emit(w.player.soundCalls)
            XCTAssertEqual(ops.sounds, sounds, "impact \(impact)")
            XCTAssertEqual(ops.soundStops, [414, 427], "impact \(impact)")
        }
    }

    func testFootstepVolumes() throws {
        // Dry footsteps `.STPlayRegSound(410 + index, 1, vol)`: walk 0x55 → (85 · 196) >> 8 = 65 → 32; run 0x78 →
        // (120 · 196) >> 8 = 91 → 45. FastRand(2) = 0, 0 here → index 1 → 411, then 2 → 412.
        let w = try standingWorld()
        let id = w.playerID!
        PlayerStates.footstep(w, id: id, volume: 0x55)
        PlayerStates.footstep(w, id: id, volume: 0x78)
        XCTAssertEqual(emit(w.player.soundCalls).sounds, [cue(411, 1, 32, 32), cue(412, 1, 45, 45)])
        // In liquid (`+0x120` ≠ 0): `.STPlay3DSoundRand(454, 1, 0x2a, +0xe)` — Pitched, not halved. Scroll (0, 0),
        // centre at the view centre (304, 192): vol (42 · 196) >> 8 = 32; d 104 → g 115; 115 · 32 >> 7 = 28 each side
        // (L + R = 56 ≥ 0x14). The rate is the one drawn at the site.
        w.player.soundCalls = []
        w.active.update(id: id) { s in
            s.lastWater = 1
            s.centre = SpriteSlot.Point(x: 304, y: 192)
        }
        PlayerStates.footstep(w, id: id, volume: 0x55)
        let wet = try XCTUnwrap(w.player.soundCalls.last)
        let rate = try XCTUnwrap(wet.cue.rate)
        XCTAssertTrue((60535...70534).contains(rate))
        XCTAssertEqual(emit(w.player.soundCalls).sounds, [cue(454, 1, 28, 28, UInt32(rate))])
        // 1400 px right of the view: both ears beyond 1024 → 0/0 → L + R < 0x14 → dropped.
        w.player.soundCalls = []
        w.active.update(id: id) { $0.centre = SpriteSlot.Point(x: 1704, y: 192) }
        PlayerStates.footstep(w, id: id, volume: 0x55)
        XCTAssertEqual(w.player.soundCalls.map(\.cue.snd), [454])
        XCTAssertEqual(emit(w.player.soundCalls).sounds, [])
    }

    // MARK: - CalcStereoVolume

    func testStereoCentre() throws {
        let h = 1000, v = 500
        let centre = SpriteSlot.Point(x: h + 304, y: v + 192)
        // View centre, vol 0x100 → 196: each ear d = 104 + 0/3 → g = (1024 − 104) >> 3 = 115; 115 · 196 >> 7 = 176.
        XCTAssertEqual(StereoVolume.peDistance(104, 0), 104)
        XCTAssertEqual(StereoVolume.peDistance(-300, 104), 334)
        XCTAssertEqual(StereoVolume.peDistance(104, -300), 334)
        XCTAssertEqual(StereoVolume.peDistance(3, 3), 4)
        XCTAssertEqual(StereoVolume.peDistance(0, -7), 7)
        XCTAssertTrue(StereoVolume.calc(volume: 196, position: centre, scrollH: h, scrollV: v) == (176, 176))
        // `.STPlay3DSound`: halved → 88/88; `…Pitched`: not halved → 176/176; `…Rand` is Pitched with its rate.
        let c3 = PlayerCue(call: .threeD, snd: 423, priority: 1, volume: 0x100, position: centre)
        let cp = PlayerCue(call: .threeDPitched, snd: 461, priority: 1, volume: 0x100, position: centre, rate: 0x1b000)
        let cr = PlayerCue(call: .threeDRand, snd: 440, priority: 1, volume: 0x100, position: centre, rate: 61000)
        let cg = PlayerCue(call: .regPitched, snd: 508, priority: 1, volume: 0x100, rate: 50001)
        XCTAssertEqual(emit([c3, cp, cr, cg].map { call($0, h: h, v: v) }).sounds,
                       [cue(423, 1, 88, 88), cue(461, 1, 176, 176, 0x1b000), cue(440, 1, 176, 176, 61000),
                        cue(508, 1, 196, 196, 50001)])
        // Only-if-idle (`if (!FUN_100916dc(423)) …`, raw `10044a50..10044a74`) rides the cue.
        var idle = c3
        idle.onlyIfIdle = true
        XCTAssertEqual(emit([call(idle, h: h, v: v)]).sounds, [cue(423, 1, 88, 88, idle: true)])
        // 300 px below the centre: d = 300 + 104/3 = 334 → g 86 → 86 · 196 >> 7 = 131 → 3D 65/65. Vol 0x9c → 119:
        // centre 115 · 119 >> 7 = 106 → 53/53.
        let low = SpriteSlot.Point(x: h + 304, y: v + 492)
        XCTAssertEqual(SoundCues.play3D(snd: 423, priority: 1, volume: 0x100, position: low, scrollH: h, scrollV: v,
                                        global: 196), cue(423, 1, 65, 65))
        XCTAssertEqual(SoundCues.play3D(snd: 423, priority: 1, volume: 0x9c, position: centre, scrollH: h, scrollV: v,
                                        global: 196), cue(423, 1, 53, 53))
        // Pitched at (0, 0) plays 0x80/0x80 whatever the volume and scroll; `.STPlay3DSound` has no such case: scroll
        // (0, 0), pos (0, 0): ears d 200 + 64 = 264 → g 95 → 145, d 408 + 64 = 472 → g 69 → 105; spread 2·40 + 40 =
        // 120 → 265 / −15 → clamp 256 / 0 → halved 128/0.
        let zero = SpriteSlot.Point()
        XCTAssertEqual(SoundCues.play3DPitched(snd: 461, priority: 1, volume: 0x10, position: zero, rate: 0x10000,
                                               scrollH: h, scrollV: v, global: 196), cue(461, 1, 0x80, 0x80))
        XCTAssertEqual(SoundCues.play3D(snd: 423, priority: 1, volume: 0x100, position: zero, scrollH: 0, scrollV: 0,
                                        global: 196), cue(423, 1, 128, 0))
        // Only exactly (0, 0) is the centred case: x 0 alone (scroll (0, 0), pos (0, 192)): ears d 200 → g 103 → 157 and
        // d 408 → g 77 → 117; spread 120 → 277 / −3 → 256/0. y 0 alone (pos (304, 0)): d 192 + 104/3 = 226 → g 99 →
        // 151 each side.
        XCTAssertEqual(SoundCues.play3DPitched(snd: 461, priority: 1, volume: 0x100, position: SpriteSlot.Point(x: 0, y: 192),
                                               rate: 0x10000, scrollH: 0, scrollV: 0, global: 196), cue(461, 1, 256, 0))
        XCTAssertEqual(SoundCues.play3DPitched(snd: 461, priority: 1, volume: 0x100, position: SpriteSlot.Point(x: 304, y: 0),
                                               rate: 0x10000, scrollH: 0, scrollV: 0, global: 196), cue(461, 1, 151, 151))
        // The Pitched drop L + R < 0x14 at the centre: vol 16 → (16 · 196) >> 8 = 12 → 115 · 12 >> 7 = 10 each → 20
        // kept; vol 15 → 11 → 9 each → 18 dropped.
        XCTAssertEqual(SoundCues.play3DPitched(snd: 461, priority: 1, volume: 16, position: centre, rate: 0x10000,
                                               scrollH: h, scrollV: v, global: 196), cue(461, 1, 10, 10))
        XCTAssertNil(SoundCues.play3DPitched(snd: 461, priority: 1, volume: 15, position: centre, rate: 0x10000,
                                             scrollH: h, scrollV: v, global: 196))
        // Beyond 1024: the left ear at d 1025 gives 0 (not (1024 − 1025) >> 3 = −1), the right at 1233 too → 0/0.
        let far = SpriteSlot.Point(x: h + 200 - 1025, y: v + 192)
        XCTAssertTrue(StereoVolume.calc(volume: 196, position: far, scrollH: h, scrollV: v) == (0, 0))
        XCTAssertNil(SoundCues.play3DPitched(snd: 461, priority: 1, volume: 0x100, position: far, rate: 0x10000,
                                             scrollH: h, scrollV: v, global: 196))
        // d 1016 → g 1 → 196 >> 7 = 1; the right ear at 1224 → 0; spread 2 + 1 = 3 → 4 / −3 → 4 / 0.
        let edge = SpriteSlot.Point(x: h + 200 - 1016, y: v + 192)
        XCTAssertTrue(StereoVolume.calc(volume: 196, position: edge, scrollH: h, scrollV: v) == (4, 0))
    }

    func testStereoLeftEar() throws {
        let h = 64, v = 32
        // At the left ear (h + 200, v + 192), vol 196: L d 0 → g 128 → 196; R d 208 → g 102 → 156; diff 40, spread
        // 80 + 40 = 120 → 316 / 36 → clamp 256 / 36 → `.STPlay3DSound` halves → 128/18; Pitched 256/36.
        let ear = SpriteSlot.Point(x: h + 200, y: v + 192)
        XCTAssertTrue(StereoVolume.calc(volume: 196, position: ear, scrollH: h, scrollV: v) == (256, 36))
        XCTAssertEqual(SoundCues.play3D(snd: 424, priority: 1, volume: 0x100, position: ear, scrollH: h, scrollV: v,
                                        global: 196), cue(424, 1, 128, 18))
        XCTAssertEqual(SoundCues.play3DPitched(snd: 424, priority: 1, volume: 0x100, position: ear, rate: 0x10000,
                                               scrollH: h, scrollV: v, global: 196), cue(424, 1, 256, 36))
        // Mirrored at the right ear: 18/128.
        let right = SpriteSlot.Point(x: h + 408, y: v + 192)
        XCTAssertEqual(SoundCues.play3D(snd: 424, priority: 1, volume: 0x100, position: right, scrollH: h, scrollV: v,
                                        global: 196), cue(424, 1, 18, 128))
        // 300 px right of the right ear: R d 300 → g 90 → 137; L d 508 → g 64 → 98; diff 39, spread 78 + 39 = 117 →
        // L −19 → 0, R 254 → 3D 0/127, Pitched 0/254.
        let out = SpriteSlot.Point(x: h + 708, y: v + 192)
        XCTAssertTrue(StereoVolume.calc(volume: 196, position: out, scrollH: h, scrollV: v) == (0, 254))
        XCTAssertEqual(SoundCues.play3D(snd: 424, priority: 1, volume: 0x100, position: out, scrollH: h, scrollV: v,
                                        global: 196), cue(424, 1, 0, 127))
        // Mirrored 300 px left of the left ear: 127/0.
        let outL = SpriteSlot.Point(x: h + 200 - 300, y: v + 192)
        XCTAssertTrue(StereoVolume.calc(volume: 196, position: outL, scrollH: h, scrollV: v) == (254, 0))
        // Through a cue: the stamp is the scroll point at the call (`PlayerState.cue`).
        let w = try standingWorld()
        w.player.scrollH = h
        w.player.scrollV = v
        w.player.cue(PlayerCue(call: .threeD, snd: 424, priority: 1, volume: 0x100, position: ear))
        w.player.scrollH = h - 208                                      // its right ear is now at x
        w.player.cue(PlayerCue(call: .threeD, snd: 424, priority: 1, volume: 0x100, position: ear))
        XCTAssertEqual(w.player.cues.count, 2)
        XCTAssertEqual(emit(w.player.soundCalls).sounds, [cue(424, 1, 128, 18), cue(424, 1, 18, 128)])
    }

    func test3DRandConsumesWhenSoundOff() throws {
        // Level 1, 3 idle iterations then RIGHT held 20 (SessionTests.testWalkCycleFaces): walking iteration 10 is the first cling frame,
        // whose `.STPlay3DSoundRand(455, …)` drew its FastRand(10000) at the site. Sound off makes no cue but the
        // stream is the same draw for draw; the stops are made either way.
        let on = try FerazelSession(resources: try resources(), prefs: prefs(), level: 1)
        let off = try FerazelSession(resources: try resources(), prefs: prefs(on: 0), level: 1)
        for _ in 0..<3 {
            _ = on.step(keys: KeyState())
            _ = off.step(keys: KeyState())
        }
        var onSnds: [[Int16]] = []
        for k in 1...20 {
            let a = on.step(keys: KeyState(pressed: [0x58]))
            let b = off.step(keys: KeyState(pressed: [0x58]))
            XCTAssertEqual(on.rngSeed, off.rngSeed, "iteration \(k)")
            XCTAssertEqual(b.sounds, [], "iteration \(k)")
            XCTAssertEqual(a.soundStops, b.soundStops, "iteration \(k)")
            onSnds.append(a.sounds.map(\.snd))
            if k == 10 {
                let rate = try XCTUnwrap(on.frameCues.first { $0.snd == 455 }?.rate)
                XCTAssertTrue((60535...70534).contains(rate))
                XCTAssertEqual(a.sounds.first { $0.snd == 455 }?.rate, UInt32(rate))
            }
        }
        XCTAssertEqual(onSnds[4], [411])
        XCTAssertTrue(onSnds[9].contains(455))
    }

    func testHurtSmallCues() throws {
        // `.HurtPlayer` damage < 0xe0 (l. 48053–48067): `.STPlayRegSoundPitched(508, 1, 0x97, FastRand(10000) + 65000)`
        // — (151 · 196) >> 8 = 115, not halved — then R(3) → 401/402/403 `.STPlayRegSound(…, 1, 0xab)`:
        // (171 · 196) >> 8 = 130 → 65. Seed 1: R(10000) 2564, R(3) 0 → 401.
        let w = SpriteWorld(level: try LevelFile.load(from: try resources(), level: 1))
        let p = try XCTUnwrap(Player.spawn(world: w, x: 2000, y: 1000))
        w.playerID = p
        let a = w.active.insert(SpriteSlot(type: 1485, x: 0, y: 0))
        w.active.update(id: a) { $0.hp = 1 }
        w.active.update(id: p) { $0.hp = 0x230 }
        w.player.soundCalls = []
        XCTAssertTrue(HurtPlayer.hurt(w, player: p, attacker: a, damage: 0x70, blood: false, invulnerable: 0x3c,
                                      coins: 0))
        XCTAssertEqual(emit(w.player.soundCalls).sounds, [cue(508, 1, 115, 115, 65000 + 2564), cue(401, 1, 65, 65)])
        // Damage ≥ 0xe0: 450 Reg 0xab → 65/65; 508 Pitched 0x100 → 196/196 at R + 50000 and R + 65000.
        w.player.soundCalls = []
        w.active.update(id: p) { $0.invulnerable = 0 }
        XCTAssertTrue(HurtPlayer.hurt(w, player: p, attacker: a, damage: 0xe0, blood: false, invulnerable: 0x3c,
                                      coins: 0))
        let big = emit(w.player.soundCalls).sounds
        XCTAssertEqual(big.map(\.snd), [450, 508, 508])
        XCTAssertEqual(big.map(\.left), [65, 196, 196])
        XCTAssertEqual(big.map(\.right), [65, 196, 196])
        XCTAssertTrue((50000..<60000).contains(big[1].rate))
        XCTAssertTrue((65000..<75000).contains(big[2].rate))

        // After the loop (l. 5296–5310): `FUN_10091504` 452 and 511 always; level complete adds 452, 453, 511.
        let r = try resources()
        let dead = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1)
        _ = dead.step(keys: KeyState())
        dead.world.active.update(id: try XCTUnwrap(dead.world.playerID)) { $0.hp = 0 }
        var last = FrameOps()
        var frames = 0
        while !dead.player.gameOver && frames < 200 {
            last = dead.step(keys: KeyState())
            frames += 1
            if !dead.player.gameOver { XCTAssertFalse(last.soundStops.contains(452), "frame \(frames)") }
        }
        XCTAssertEqual(last.requests, [.deathEffect])
        XCTAssertEqual(Array(last.soundStops.suffix(2)), [452, 511])
        XCTAssertFalse(last.soundStops.dropLast(2).contains(452))
        let done = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1)
        _ = done.step(keys: KeyState())
        done.world.player.levelDone = true
        let end = done.step(keys: KeyState())
        // No exit touched (exit index unset): `LevelFlow` restarts the current level.
        XCTAssertEqual(end.requests, [.loadLevel(1)])
        XCTAssertEqual(Array(end.soundStops.suffix(5)), [452, 511, 452, 453, 511])
        XCTAssertFalse(end.soundStops.dropLast(5).contains(452))
        // Death wins over a completed level (G+4 < 1 is tested first, l. 5302): 452, 511 only.
        let both = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1)
        _ = both.step(keys: KeyState())
        both.world.player.levelDone = true
        both.world.active.update(id: try XCTUnwrap(both.world.playerID)) { $0.hp = 0 }
        let bothEnd = both.step(keys: KeyState())
        XCTAssertEqual(bothEnd.requests, [.deathEffect])
        XCTAssertEqual(Array(bothEnd.soundStops.suffix(2)), [452, 511])
        XCTAssertFalse(bothEnd.soundStops.contains(453))
    }
}
