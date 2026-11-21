import XCTest
@testable import FerazelCore

/// 6A-RN (docs/superpowers/plans/2026-11-04-ferazel-remainder.md; ENG §2.7): OmniPx mode 1's weather on level 15
/// ("Storm Valley") — `.GenerateRain @ 100109c0` (M l. 8429–8531): the first call's thunder timer and looped rain
/// sound, the thunder (flash, snd 453, the async gamma fade), the drops (three particles each), on every
/// `.PaintFrameWrap` pass — and the level's constant side push (M l. 46347–46365, built as `Player.sidePush`).
///
/// Every test opens level 15's fixture (6A-FX) headless with nothing left out: since 6A-BG1c every one of its 183
/// records sets up (level 15 joined `BuiltLevels` at 6A-L15; the fixture never consults it). The expected values are
/// re-derived here from the dump's arithmetic over the game's random stream (`FastRand`, seeded where the call found
/// it), never from the port's generator. A missing data file is a FAILURE, never a skip.
final class RainTests: XCTestCase {
    /// Level 15's leave-out list: empty (count asserted 0).
    static let level15: [LevelFixture.LeaveOut] = []

    // MARK: - The fixture

    /// Level 15's fixture through the level runner, ticked until its session exists (before its first iteration).
    private func open(prefs: FerazelPrefs = FerazelPrefs()) throws -> (run: LevelRun, session: FerazelSession) {
        let real = try LevelFile.load(from: try LevelFixture.base.get(), level: 15)
        XCTAssertEqual(try LevelFixture.leftOut(real, Self.level15).count, 0, "nothing left out")
        let run = try LevelFixture.open(level: 15, leaveOut: Self.level15, prefs: prefs)
        var t: UInt32 = 0
        while run.session == nil && t < 4000 {
            _ = try run.tick(now: t, input: FrontInput())
            t &+= 1
        }
        now = t
        let s = try XCTUnwrap(run.session, "level 15 opened within 4000 ticks")
        return (run, s)
    }

    /// The next tick's `now` for the run `open` made.
    private var now: UInt32 = 0
    /// `drive` saw a `.CheckGameLoopKeys` confirm (DLOG 202) asked for.
    private var asked = false

    /// Ticks until the run's iteration count has grown by one (the whole iteration, its modals answered by `input`).
    /// Returns every tick's merged output and every `FrameOps` the session handed out on the way.
    @discardableResult
    private func iterate(_ run: LevelRun, input: FrontInput = FrontInput(), max: Int = 400) throws
        -> (outs: [FrontOutput], steps: [FrameOps]) {
        let before = run.iterations
        var outs: [FrontOutput] = [], steps: [FrameOps] = []
        for _ in 0..<max {
            let o = try run.tick(now: now, input: input)
            now &+= 1
            outs.append(o.merged)
            steps += run.lastSteps
            if run.iterations > before { return (outs, steps) }
        }
        XCTFail("no iteration within \(max) ticks")
        return (outs, steps)
    }

    /// Ticks until `until` holds (checked after each tick).
    private func drive(_ run: LevelRun, input: FrontInput = FrontInput(), max: Int = 6000,
                       until: () -> Bool) throws -> [FrontOutput] {
        var outs: [FrontOutput] = []
        asked = false
        for _ in 0..<max {
            let o = try run.tick(now: now, input: input).merged
            now &+= 1
            outs.append(o)
            if o.requests.contains(where: { if case .dialog(.confirm) = $0 { true } else { false } }) { asked = true }
            if until() { return outs }
        }
        XCTFail("the run did not reach the condition in \(max) ticks")
        return outs
    }

    /// Into the loop, past the entry's async fade-in (`.CheckGameLoopKeys` answers again), at least `iterations` in.
    private func settle(_ run: LevelRun, _ s: FerazelSession, iterations: Int = 45) throws {
        _ = try drive(run) { run.iterations >= iterations && s.world.gammaFade.done }
    }

    // MARK: - The dump's arithmetic, re-derived

    /// One particle `.NewParticle(kind, 0, (v, h), shape, vx, vy, 0, 1)` (M l. 8501, 8516, 8527).
    struct Drop: Equatable {
        var kind: Int, v: Int, h: Int, shape: Int, vx: Int, vy: Int
    }

    /// M l. 8481–8530 on `rng` at scroll point (H, V): `sVar4 = H + R(50)`; while `H + 0x294 > sVar4`: `sVar5 = R(2)`;
    /// `local_38 = (V, sVar4)`; shape 4 / vx −700 / vy 0x834, or (sVar5 == 0) 5 / −0x4b0 / 0xe10; particle kind 7;
    /// kind 7 or (heavy) 6; light: `R(100) > 0x32` → h = sVar4 − 1; v + 2, heavy: (v_old + 4, h − 1); particle; light:
    /// `R(100) > 0x32` → h − 1; v + 2 / heavy as before; particle kind − 1; `sVar4 += R(200) + 0x32`. Shorts throughout.
    static func dumpDrops(_ rng: inout FastRand, H: Int, V: Int) -> [Drop] {
        func s16(_ x: Int) -> Int { Int(Int16(truncatingIfNeeded: x)) }
        var out: [Drop] = []
        var x = s16(H + Int(rng.next(0x32)))
        while !(s16(H) + 0x294 <= x) {
            let light = rng.next(2) != 0
            let (shape, vx, vy) = light ? (4, -700, 0x834) : (5, -0x4b0, 0xe10)
            var v = V, h = x
            out.append(Drop(kind: 7, v: s16(v), h: s16(h), shape: shape, vx: vx, vy: vy))
            if light {
                if rng.next(100) > 0x32 { h = x - 1 }
                v += 2
            } else {
                v += 4; h -= 1
            }
            out.append(Drop(kind: light ? 7 : 6, v: s16(v), h: s16(h), shape: shape, vx: vx, vy: vy))
            if light {
                if rng.next(100) > 0x32 { h -= 1 }
                v += 2
            } else {
                v += 4; h -= 1
            }
            out.append(Drop(kind: light ? 6 : 5, v: s16(v), h: s16(h), shape: shape, vx: vx, vy: vy))
            x = s16(x + Int(rng.next(200)) + 0x32)
        }
        return out
    }

    /// The particles alive in `pool` slots 0 ..< n as `Drop`s (a fresh pool fills from slot 0), each checked for the
    /// fields `.NewParticle` stores beside them: gravity 0, delay 0 (age 0), blend 0, collision mode 1.
    private func drops(_ pool: ParticlePool, file: StaticString = #filePath, line: UInt = #line) -> [Drop] {
        var out: [Drop] = []
        for r in pool.records where r.alive {
            XCTAssertEqual([Int(r.gravity), Int(r.age), Int(r.blend), Int(r.mode)], [0, 0, 0, 1], file: file, line: line)
            out.append(Drop(kind: Int(r.kind), v: Int(r.y >> 8), h: Int(r.x >> 8), shape: Int(r.shape), vx: Int(r.vx),
                            vy: Int(r.vy)))
        }
        return out
    }

    /// One `.GenerateRain` call made directly on the session's world at (h, v), the pool emptied first.
    @discardableResult
    private func call(_ s: FerazelSession, h: Int, v: Int) -> (draws: [DrawOp], requests: [ShellRequest]) {
        s.world.particles = ParticlePool()
        return s.rain.generate(world: s.world, h: h, v: v)
    }

    // MARK: - The tests

    /// The first call (M l. 8448–8454): the flag set, T = R(90) + 90 (then the thunder block's T − 1 in the same call),
    /// `.STPlayLoopedSound(snd 452, 1, 0x55)` — the loop's volume (vol · global) >> 8 on both sides, not halved, rate
    /// 0x10000; it plays only with sound on and draws no number either way. The second call draws no timer and starts
    /// no loop. Level 15's header as the data has it.
    func testRainFirstCallTimerAndLoop() throws {
        // The header (the Mlvl bytes): OmniPx mode 1, 0x26c9 = 1, 0x270e = 56, the side push −320; level 15 is the
        // only OmniPx mode-1 level.
        let base = try LevelFixture.base.get()
        let mlvl = try XCTUnwrap(base.world.resource(type: "Mlvl", id: 15)).data
        func byte(_ o: Int) -> Int { Int(mlvl[mlvl.startIndex + o]) }
        func i16(_ o: Int) -> Int { Int(Int16(bitPattern: UInt16(byte(o)) << 8 | UInt16(byte(o + 1)))) }
        XCTAssertEqual([byte(0x26c7), byte(0x26c9), i16(0x270e), i16(0x272c)], [1, 1, 56, -320])
        for res in base.world.resources(of: "Mlvl") where res.id != 15 {
            XCTAssertNotEqual(res.data[res.data.startIndex + 0x26c7], 1, "level \(res.id)")
        }

        let (run, s) = try open()
        XCTAssertEqual(s.iterations, 0)
        XCTAssertEqual(s.level.header.omniPxMode, 1)
        // Every one of the 183 records set up (a refused one would have thrown from the session init).
        let active = Set(run.levelFile.activePlacements.map(\.index))
        XCTAssertEqual(active.count, 183)
        let fromRecords = Set(s.world.active.sprites.map { Int($0.recordIndex) }
                              + s.world.idle.entries.compactMap { $0.map { Int($0.saved.recordIndex) } })
        XCTAssertEqual(fromRecords.intersection(active), active, "every active record set up")
        // `.SetupLevel`'s clear after `.SetupOmniPx` (M l. 2541) meets a fresh flag, so it cannot be seen here; its
        // effect — iteration 1's call is a first call (R(90), the loop) — is asserted just below.

        // Iteration 1: the first call.
        let first = try iterate(run)
        XCTAssertTrue(s.rain.started)
        let firstEntry = s.rain.entrySeed
        var r = FastRand(seed: firstEntry)
        let T = Int(r.next(0x5a)) + 0x5a
        XCTAssertEqual(Int(s.rain.timer), T - 1, "T = R(90) + 90, then T − 1 in the same call")
        XCTAssertTrue((89...178).contains(Int(s.rain.timer)))
        _ = Self.dumpDrops(&r, H: s.camera.scrollH, V: s.camera.scrollV)
        let afterFirst = r.seed
        // The loop cue: one `.STPlayLoopedSound` in the frame's calls, and the cue the Sound Tool takes — both sides
        // (0x55 · 7·0x1c) >> 8 = 65 (default sound volume 7), rate 0x10000, looping.
        XCTAssertEqual(s.frameCues.filter { $0.snd == 452 }, [PlayerCue(call: .looped, snd: 452, priority: 1, volume: 0x55)])
        let loops = first.steps.flatMap(\.sounds).filter { $0.snd == 452 }
        XCTAssertEqual(loops, [SoundCue(snd: 452, priority: 1, left: 65, right: 65, rate: 0x10000, loops: true)])

        // The second call: no R(90), no loop — T − 1, the drops drawn from the entry seed on.
        try iterate(run)
        XCTAssertEqual(Int(s.rain.timer), T - 2)
        XCTAssertFalse(s.frameCues.contains { $0.snd == 452 })
        var r2 = FastRand(seed: s.rain.entrySeed)
        let seen = Self.dumpDrops(&r2, H: s.camera.scrollH, V: s.camera.scrollV)
        XCTAssertFalse(seen.isEmpty)

        // Sound off: the same call draws the same numbers (the loop draws none) and no cue reaches the Sound Tool;
        // the call itself is still made (`PlayerCue`), as the original calls `.STPlayLoopedSound` and it returns.
        var quiet = FerazelPrefs()
        quiet.soundOn = 0
        let (qrun, qs) = try open(prefs: quiet)
        let q = try iterate(qrun)
        XCTAssertEqual(qs.rain.timer, Int16(T - 1))
        XCTAssertEqual(qs.rain.entrySeed, firstEntry, "the stream reached the call alike")
        XCTAssertEqual(qs.frameCues.filter { $0.snd == 452 }.count, 1)
        XCTAssertTrue(q.steps.flatMap(\.sounds).isEmpty, "sound off: no cue plays")
        var rq = FastRand(seed: qs.rain.entrySeed)
        XCTAssertEqual(Int(rq.next(0x5a)) + 0x5a, T, "the same draw with sound off")
        _ = Self.dumpDrops(&rq, H: qs.camera.scrollH, V: qs.camera.scrollV)
        XCTAssertEqual(rq.seed, afterFirst, "the loop drew nothing: the same stream after the call")
    }

    /// `.Pause` (M l. 3171–3204): its own `.PaintFrameWrap(1, 0)` runs the rain once more with the flag still set
    /// (M l. 3190), then the voices 452 / 511 stop and the flag is cleared (M l. 3203) — so the next call draws a fresh
    /// R(90) and plays the loop again. And `.GameLoop`'s exit clears the flag (M l. 5300).
    func testRainRestartsAfterPause() throws {
        let (run, s) = try open()
        try settle(run, s)
        let t0 = Int(s.rain.timer)
        XCTAssertGreaterThan(t0, 3, "no thunder in the window")
        let i0 = run.iterations
        // Caps Lock down: the next iteration's main pass (T − 1), `.CheckGameLoopKeys` → `.Pause`, its paint (T − 1).
        let entry = try drive(run, input: FrontInput(capsLock: true)) { run.pause != nil && run.pause?.paused == true }
        XCTAssertEqual(run.iterations, i0 + 1, "the pause sits inside one iteration")
        XCTAssertEqual(Int(s.rain.timer), t0 - 2, "the main pass and the pause's own paint each ran the rain")
        XCTAssertFalse(s.rain.started, "`.Pause` cleared the flag (M l. 3203)")
        let o = try XCTUnwrap(entry.last)
        XCTAssertEqual(o.soundStops.suffix(2), [452, 511], "the rain loop and the ambience stopped, last")
        XCTAssertFalse(o.sounds.contains { $0.snd == 452 }, "the pause's paint started no loop (flag still set)")

        // Unpause (Caps Lock up: the counter from 10), then the next iteration's call is a first call again.
        _ = try drive(run) { run.pause == nil }
        XCTAssertEqual(run.iterations, i0 + 1)
        let next = try iterate(run)
        XCTAssertTrue(s.rain.started)
        var r = FastRand(seed: s.rain.entrySeed)
        XCTAssertEqual(Int(s.rain.timer), Int(r.next(0x5a)) + 0x5a - 1, "a fresh R(90) + 90")
        XCTAssertEqual(next.steps.flatMap(\.sounds).filter { $0.snd == 452 },
                       [SoundCue(snd: 452, priority: 1, left: 65, right: 65, rate: 0x10000, loops: true)],
                       "the loop replayed")

        // `.GameLoop`'s exit: Esc, OK — the loop ends after the iteration; the voices stop and the flag is cleared.
        try iterate(run)
        XCTAssertTrue(s.rain.started)
        _ = try drive(run, input: FrontInput(keys: KeyState(pressed: [0x35]))) { asked }
        run.dialogDone(.ok)
        let end = try drive(run) { s.loopEnded }
        XCTAssertFalse(s.rain.started, "`.GameLoop`'s exit cleared the flag (M l. 5300)")
        XCTAssertTrue(end.flatMap(\.soundStops).contains(452))
    }

    /// The thunder (M l. 8456–8480) call by call: T 1 → 0 (no thunder yet); 0 → flash count 3 + snd 453 (1, 0xab), T −1;
    /// −1 → −2; −2 → the fade, −3; T < −2 → T = R(150) + 210 drawn before the drops; then T − 1 a call.
    func testRainThunderSequence() throws {
        let (_, s) = try open()
        let h = s.camera.scrollH, v = s.camera.scrollV
        s.rain.started = true
        s.rain.timer = 1
        s.world.flash = ScreenFlash()
        let global = SoundCues.globalVolume(s.prefs)

        func callAndCheckStream(timerDraw: Bool) -> Int? {
            s.world.player.cues = []
            let seed = s.world.rng.seed
            call(s, h: h, v: v)
            var r = FastRand(seed: seed)
            let t = timerDraw ? Int(r.next(0x96)) + 0xd2 : nil
            XCTAssertEqual(drops(s.world.particles), Self.dumpDrops(&r, H: h, V: v))
            XCTAssertEqual(s.world.rng.seed, r.seed)
            return t
        }
        // 1 → 0.
        _ = callAndCheckStream(timerDraw: false)
        XCTAssertEqual(s.rain.timer, 0)
        XCTAssertEqual(s.world.flash, ScreenFlash())
        XCTAssertTrue(s.world.player.cues.isEmpty)
        // 0 → the thunder: the flash count 3 (the toggle is the drawn pass's), snd 453, T = −1.
        _ = callAndCheckStream(timerDraw: false)
        XCTAssertEqual(s.rain.timer, -1)
        XCTAssertEqual(s.world.flash, ScreenFlash(count: 3, on: false))
        XCTAssertEqual(s.world.player.cues, [PlayerCue(call: .reg, snd: 453, priority: 1, volume: 0xab)])
        let thunderCue = try XCTUnwrap(s.world.player.cues.first)
        // `.STPlayRegSound(453, 1, 0xab)` by the dump's arithmetic: global 7 · 0x1c = 0xc4; (0xab · 0xc4) >> 8 = 130,
        // halved = 65 on both sides, rate 0x10000, not looping.
        XCTAssertEqual(global, 0xc4)
        XCTAssertEqual(SoundCues.convert(PlayerState.SoundCall(cue: thunderCue, scrollH: h, scrollV: v), prefs: s.prefs),
                       .play(SoundCue(snd: 453, priority: 1, left: 65, right: 65, rate: 0x10000, loops: false)))
        if case .play(let c)? = SoundCues.convert(PlayerState.SoundCall(cue: thunderCue, scrollH: h, scrollV: v),
                                                  prefs: s.prefs) {
            XCTAssertFalse(c.loops, "the thunder plays once: `SoundCue.loops` is off by default")
        } else {
            XCTFail("the thunder's cue plays")
        }
        // −1 → −2.
        _ = callAndCheckStream(timerDraw: false)
        XCTAssertEqual(s.rain.timer, -2)
        XCTAssertTrue(s.world.player.cues.isEmpty)
        // −2 → the fade (`testRainThunderGammaOps`), −3.
        _ = callAndCheckStream(timerDraw: false)
        XCTAssertEqual(s.rain.timer, -3)
        // −3 → R(150) + 210, drawn first.
        let reset = try XCTUnwrap(callAndCheckStream(timerDraw: true))
        XCTAssertEqual(Int(s.rain.timer), reset)
        XCTAssertTrue((210...359).contains(reset))
        // Then T − 1 a call, no draw for it.
        _ = callAndCheckStream(timerDraw: false)
        XCTAssertEqual(Int(s.rain.timer), reset - 1)
        XCTAssertEqual(s.world.flash, ScreenFlash(count: 3, on: false), "nothing but the thunder stores the flash")
    }

    /// T = −2 (M l. 8466–8473): `.GammaFadeOutAsync(2, white)` + three `.HandleAsyncGammaFade` (0 %, 50 %, 100 %: then
    /// done and faded) + `.GammaFadeInAsync(0x6e)`, in the same call — gated on fading enabled (`DAT_100a53c2`, M l.
    /// 31879, 31899) and the faded flag (`*_DAT_1009fde8`, M l. 31882, 31899): with fading off nothing of it happens;
    /// with the screen already faded the fade-out and its steps do not arm but the fade-in does. In a real iteration
    /// the three steps sit in that iteration's ops, where the rain runs, and the iteration's own `.HandleAsyncGammaFade`
    /// (M l. 5282) takes the fade-in's first step.
    func testRainThunderGammaOps() throws {
        let (run, s) = try open()
        let h = s.camera.scrollH, v = s.camera.scrollV
        let white = RGB16(red: 0xffff, green: 0xffff, blue: 0xffff)
        func atMinus2(_ g: AsyncGammaFade) -> (draws: [DrawOp], requests: [ShellRequest]) {
            s.rain.started = true
            s.rain.timer = -2
            s.world.gammaFade = g
            return call(s, h: h, v: v)
        }
        // Fading on, not faded.
        let on = atMinus2(AsyncGammaFade(fadedOut: false, done: true, fadingEnabled: true))
        XCTAssertEqual(on.draws, [.gammaStep(numerator: 0, denominator: 2, toward: white),
                                  .gammaStep(numerator: 1, denominator: 2, toward: white),
                                  .gammaStep(numerator: 2, denominator: 2, toward: white)])
        XCTAssertEqual(on.requests, [.hideCursor], "`HideCursorSafe` at the arm (M l. 31905)")
        XCTAssertEqual(s.rain.timer, -3)
        var g = s.world.gammaFade
        XCTAssertEqual([g.fadedOut, g.done, g.fadingIn], [true, false, true], "faded, the fade-in armed")
        XCTAssertEqual([g.step, g.steps], [0, 0x6e])
        XCTAssertEqual(g.handle(), .gammaStep(numerator: 0, denominator: 0x6e, toward: nil))
        // Fading off: no op, no request, the state untouched.
        let offState = AsyncGammaFade(fadedOut: false, done: true, fadingEnabled: false)
        let off = atMinus2(offState)
        XCTAssertEqual(off.draws, [])
        XCTAssertEqual(off.requests, [])
        XCTAssertEqual(s.world.gammaFade, offState)
        XCTAssertEqual(s.rain.timer, -3)
        // Already faded: the fade-out does not arm (no hide, no step); the fade-in does.
        let faded = atMinus2(AsyncGammaFade(fadedOut: true, done: true, fadingEnabled: true))
        XCTAssertEqual(faded.draws, [])
        XCTAssertEqual(faded.requests, [])
        g = s.world.gammaFade
        XCTAssertEqual([g.fadedOut, g.done, g.fadingIn], [true, false, true])
        XCTAssertEqual(g.steps, 0x6e)
        // With fading off the thunder's flash and sound still happen (T = 0).
        s.world.gammaFade = offState
        s.world.flash = ScreenFlash()
        s.world.player.cues = []
        s.rain.timer = 0
        let thunder = call(s, h: h, v: v)
        XCTAssertEqual(thunder.draws, [])
        XCTAssertEqual(s.world.flash.count, 3)
        XCTAssertEqual(s.world.player.cues.map(\.snd), [453])

        // In a real iteration: settle, then T = −2 at the next pass.
        let (run2, s2) = try open()
        _ = run
        try settle(run2, s2)
        XCTAssertTrue(s2.world.gammaFade.done)
        XCTAssertFalse(s2.world.gammaFade.fadedOut)
        s2.rain.timer = -2
        let it = try iterate(run2)
        let draws = it.steps.flatMap(\.draws)
        let steps = draws.indices.filter { if case .gammaStep(_, 2, white) = draws[$0] { true } else { false } }
        XCTAssertEqual(steps.count, 3)
        guard steps.count == 3 else { return }
        XCTAssertEqual(steps[2] - steps[0], 2, "the three steps in a row, inside the pass")
        let sprites = try XCTUnwrap(draws.firstIndex { if case .wrapDrawSprites = $0 { true } else { false } })
        let particles = try XCTUnwrap(draws.firstIndex { if case .drawParticles = $0 { true } else { false } })
        XCTAssertLessThan(sprites, steps[0])
        XCTAssertLessThan(steps[2], particles)
        XCTAssertEqual(draws.last { if case .gammaStep = $0 { true } else { false } },
                       .gammaStep(numerator: 0, denominator: 0x6e, toward: nil), "the loop's step 0 of the fade-in")
        XCTAssertTrue(it.steps.flatMap(\.requests).contains(.hideCursor))
        XCTAssertEqual(s2.rain.timer, -3)
    }

    /// The drops' columns and the stream's order (M l. 8481–8530): x = H + R(50), then per drop R(2), [light: R(100),
    /// R(100)], R(200), x += R(200) + 50 while x < H + 660 — every particle where the dump puts it, the stream left where
    /// the dump leaves it; at three scroll points and two seeds. No other draw.
    func testRainDropColumnsAndDraws() throws {
        let (_, s) = try open()
        s.rain.started = true
        for seed: Int32 in [1, 0x2c1b1519] {
            for (h, v) in [(0, 0), (1234, 567), (s.camera.scrollH, s.camera.scrollV)] {
                s.rain.timer = 50
                s.world.rng = FastRand(seed: seed)
                call(s, h: h, v: v)
                var r = FastRand(seed: seed)
                let want = Self.dumpDrops(&r, H: h, V: v)
                XCTAssertEqual(drops(s.world.particles), want, "seed \(seed) at (\(h), \(v))")
                XCTAssertEqual(s.world.rng.seed, r.seed, "the stream after the call")
                XCTAssertEqual(want.count % 3, 0)
                // Columns: the first at H + 0…49, each next 50…249 to the right, the last < H + 660.
                let columns = stride(from: 0, to: want.count, by: 3).map { want[$0].h }
                let firstColumn = try XCTUnwrap(columns.first), lastColumn = try XCTUnwrap(columns.last)
                XCTAssertTrue((h..<(h + 50)).contains(firstColumn))
                for (a, b) in zip(columns, columns.dropFirst()) { XCTAssertTrue((50...249).contains(b - a)) }
                XCTAssertLessThan(lastColumn, h + 660)
                XCTAssertTrue(want.allSatisfy { $0.v >= v && $0.v <= v + 8 })
            }
        }
        // Pinned for seed 1 at (0, 0) (measured once from the stream): the first drop's column and weight, and the count.
        s.world.rng = FastRand(seed: 1)
        s.rain.timer = 50
        call(s, h: 0, v: 0)
        let pinned = drops(s.world.particles)
        var r = FastRand(seed: 1)
        let x0 = Int(r.next(50))
        let heavy0 = r.next(2) == 0
        XCTAssertEqual(try XCTUnwrap(pinned.first), Drop(kind: 7, v: 0, h: x0, shape: heavy0 ? 5 : 4, vx: heavy0 ? -1200 : -700,
                                       vy: heavy0 ? 3600 : 2100))
        XCTAssertEqual(x0, 12, "FastRand(seed 1).next(50): (16807 · 16807 mod 2³¹ − 1) & 0xffff · 50 >> 16")
        XCTAssertEqual(pinned.count, 15, "five drops")
        // A call makes no draw beyond these: a timer of 50 → 49, no flash, no cue.
        XCTAssertEqual(s.rain.timer, 49)

        // The bound is the dump's int compare `H + 0x294 <= x` (M l. 8482): a column at exactly H + 659 makes a drop,
        // one at exactly H + 660 ends the loop — a seed for each, found by the stream (H = 0; the draw order above).
        func columns(_ seed: Int32) -> (made: [Int], end: Int) {
            var r = FastRand(seed: seed)
            var x = Int(r.next(0x32)), made: [Int] = []
            while x < 0x294 {
                made.append(x)
                if r.next(2) != 0 { _ = r.next(100); _ = r.next(100) }
                x += Int(r.next(200)) + 0x32
            }
            return (made, x)
        }
        for edge in [0x293, 0x294] {
            var seed: Int32 = 1
            while seed < 100_000 && (edge == 0x293 ? columns(seed).made.last != edge : columns(seed).end != edge) {
                seed += 1
            }
            XCTAssertLessThan(seed, 100_000, "a seed meeting H + \(edge)")
            s.rain.timer = 50
            s.world.rng = FastRand(seed: seed)
            call(s, h: 0, v: 0)
            let got = drops(s.world.particles)
            var r = FastRand(seed: seed)
            XCTAssertEqual(got, Self.dumpDrops(&r, H: 0, V: 0), "seed \(seed): the edge H + \(edge)")
            XCTAssertEqual(stride(from: 0, to: got.count, by: 3).map { got[$0].h }, columns(seed).made, "edge \(edge)")
            XCTAssertEqual(s.world.rng.seed, r.seed)
        }
    }

    /// A heavy drop (`R(2)` = 0, M l. 8490–8495): shape 5, vx −1200 (−0x4b0), vy 3600 (0xe10); kinds 7, 6, 5 at (V, x),
    /// (V + 4, x − 1), (V + 8, x − 2) — no R(100).
    func testRainHeavyDropParticles() throws {
        let (_, s) = try open()
        s.rain.started = true
        // A seed whose first drop is heavy, found by the stream: R(50) then R(2) = 0.
        var seed: Int32 = 1
        while true {
            var r = FastRand(seed: seed)
            _ = r.next(50)
            if r.next(2) == 0 { break }
            seed += 1
        }
        let H = 300, V = 200
        s.rain.timer = 50
        s.world.rng = FastRand(seed: seed)
        call(s, h: H, v: V)
        var r = FastRand(seed: seed)
        let x = H + Int(r.next(50))
        XCTAssertEqual(r.next(2), 0)
        let after = r.next(200)                                     // no R(100) on a heavy drop
        let got = Array(drops(s.world.particles).prefix(3))
        XCTAssertEqual(got, [Drop(kind: 7, v: V, h: x, shape: 5, vx: -1200, vy: 3600),
                             Drop(kind: 6, v: V + 4, h: x - 1, shape: 5, vx: -1200, vy: 3600),
                             Drop(kind: 5, v: V + 8, h: x - 2, shape: 5, vx: -1200, vy: 3600)])
        // The next drop's column is x + R(200) + 50 — the R(200) drawn right after the R(2).
        let fourth = try XCTUnwrap(drops(s.world.particles).dropFirst(3).first)
        XCTAssertEqual(fourth.h, x + Int(after) + 50)
        XCTAssertEqual(fourth.kind, 7)
    }

    /// A light drop (`R(2)` = 1, M l. 8496–8524): shape 4, vx −700, vy 2100 (0x834); kinds 7, 7, 6, each next one v + 2
    /// and, when its `R(100)` > 50, h − 1. Both outcomes of each R(100) are met.
    func testRainLightDropParticles() throws {
        let (_, s) = try open()
        s.rain.started = true
        let H = 300, V = 200
        var met: Set<[Bool]> = []
        var seed: Int32 = 1
        while met.count < 4 && seed < 5000 {
            defer { seed += 1 }
            var r = FastRand(seed: seed)
            let x = H + Int(r.next(50))
            guard r.next(2) == 1 else { continue }
            let a = r.next(100), b = r.next(100)
            let key = [a > 50, b > 50]
            guard !met.contains(key) else { continue }
            met.insert(key)
            s.rain.timer = 50
            s.world.rng = FastRand(seed: seed)
            call(s, h: H, v: V)
            let h1 = a > 50 ? x - 1 : x
            let h2 = b > 50 ? h1 - 1 : h1
            XCTAssertEqual(Array(drops(s.world.particles).prefix(3)),
                           [Drop(kind: 7, v: V, h: x, shape: 4, vx: -700, vy: 2100),
                            Drop(kind: 7, v: V + 2, h: h1, shape: 4, vx: -700, vy: 2100),
                            Drop(kind: 6, v: V + 4, h: h2, shape: 4, vx: -700, vy: 2100)], "seed \(seed) \(key)")
            let fourth = try XCTUnwrap(drops(s.world.particles).dropFirst(3).first)
            XCTAssertEqual(fourth.h, x + Int(r.next(200)) + 50, "R(200) after the two R(100)")
        }
        XCTAssertEqual(met.count, 4, "all four R(100) outcomes met")
        // The test is `0x32 < R(100)` (M l. 8507): a first R(100) of exactly 50 keeps h, exactly 51 moves it.
        for (draw, moved) in [(Int16(50), false), (51, true)] {
            func hit(_ seed: Int32) -> Bool {
                var r = FastRand(seed: seed)
                _ = r.next(50)
                return r.next(2) == 1 && r.next(100) == draw
            }
            var seed: Int32 = 1
            while seed < 100_000 && !hit(seed) { seed += 1 }
            XCTAssertLessThan(seed, 100_000, "a seed with R(100) = \(draw)")
            s.rain.timer = 50
            s.world.rng = FastRand(seed: seed)
            call(s, h: H, v: V)
            var r = FastRand(seed: seed)
            let x = H + Int(r.next(50))
            let got = Array(drops(s.world.particles).prefix(2))
            XCTAssertEqual(got.map(\.h), [x, moved ? x - 1 : x], "R(100) = \(draw)")
            XCTAssertEqual(got.map(\.v), [V, V + 2])
        }
    }

    /// The rain runs on every `.PaintFrameWrap` pass (M l. 9228–9229, before the drawn-frame test): on the skipped draw
    /// of "Reduce frame rate" (prefs[0]) it still draws its numbers and makes its drops; and on the extra passes of
    /// `.CheckGameLoopKeys`' dialogs — Esc Cancel (M l. 3918), Esc OK (3922), ⌘Q OK (3980), ⌘W OK (4005) — each once
    /// more (T − 1 more in that iteration). (`.Pause`'s, M l. 3190: `testRainRestartsAfterPause`.)
    func testRainRunsOnUndrawnFrames() throws {
        var reduce = FerazelPrefs()
        reduce.reduceFrameRate = 1
        let (run, s) = try open(prefs: reduce)
        try iterate(run)                                            // the first call (and its R(90))
        var undrawn = 0, drawn = 0
        for _ in 0..<12 {
            let t0 = Int(s.rain.timer), i0 = run.iterations
            let it = try iterate(run)
            let n = run.iterations - i0
            XCTAssertEqual(it.steps.count, n)
            XCTAssertEqual(Int(s.rain.timer), t0 - n, "one call an iteration, drawn or not")
            // The last call's drops, re-derived from where it found the stream, are the youngest particles alive
            // (age 1 after this iteration's `.HandleParticles`), in slot order.
            var r = FastRand(seed: s.rain.entrySeed)
            let want = Self.dumpDrops(&r, H: s.camera.scrollH, V: s.camera.scrollV)
            let young = s.world.particles.records.filter { $0.alive && $0.age == 1 && ($0.vx == -700 || $0.vx == -1200) }
            XCTAssertEqual(young.map { [Int($0.kind), Int($0.shape), Int($0.vx), Int($0.vy)] },
                           want.prefix(young.count).map { [$0.kind, $0.shape, $0.vx, $0.vy] })
            XCTAssertGreaterThan(young.count, 0)
            // The whole list where the dump puts it, at the scroll point the pass used, after the one
            // `.HandleParticles` step since (x += vx, y += vy; gravity 0) — none died in this window.
            XCTAssertEqual(young.map { [Int($0.kind), Int($0.shape), Int($0.vx), Int($0.vy), Int($0.x), Int($0.y)] },
                           want.map { [$0.kind, $0.shape, $0.vx, $0.vy, ($0.h << 8) + $0.vx, ($0.v << 8) + $0.vy] })
            for ops in it.steps {
                if ops.drawn { drawn += 1; continue }
                undrawn += 1
                XCTAssertFalse(ops.draws.contains { if case .drawParticles = $0 { true } else { false } },
                               "a skipped draw draws no particle")
            }
        }
        XCTAssertGreaterThanOrEqual(undrawn, 5, "the skipped draws ran the rain")
        XCTAssertGreaterThanOrEqual(drawn, 5)

        // The dialogs' extra passes. Each from a fresh fixture, settled; the key on the next iteration's poll.
        let escape = 0x35, command = 0x37, keyQ = 0x0c, keyW = 0x0d
        let cases: [(keys: [Int], ok: Bool, line: Int)] = [([escape], false, 3918), ([escape], true, 3922),
                                                           ([command, keyQ], true, 3980), ([command, keyW], true, 4005)]
        for c in cases {
            let (run, s) = try open()
            try settle(run, s)
            let t0 = Int(s.rain.timer)
            XCTAssertGreaterThan(t0, 3, "M l. \(c.line): no thunder in the window")
            let i0 = run.iterations
            _ = try drive(run, input: FrontInput(keys: KeyState(pressed: c.keys))) { asked }
            XCTAssertEqual(Int(s.rain.timer), t0 - 1, "M l. \(c.line): the main pass")
            XCTAssertEqual(run.iterations, i0 + 1)
            run.dialogDone(c.ok ? .ok : .cancel)
            _ = try run.tick(now: now, input: FrontInput())
            now &+= 1
            XCTAssertEqual(Int(s.rain.timer), t0 - 2, "M l. \(c.line): the dialog's pass ran the rain once more")
            if c.keys.contains(keyQ) {
                XCTAssertEqual(s.world.suspension, .gameLoopKeys(.quit), "⌘Q OK: `.Quit` follows")
            } else {
                XCTAssertNil(s.world.suspension, "M l. \(c.line): the frame went on")
            }
        }
    }

    /// The side push (M l. 46347–46365, `Player.sidePush`, built at P-phase; ENG E4, LL §10.7) with level 15's −320:
    /// airborne and not riding → vx −= 320 while vx > 5·(−320) = −1600; grounded (or riding) → x256 += −320 >> 2 = −80
    /// and the camera latch `*_DAT_1009fd34 = 1`.
    func testSidePushOnLevel15() throws {
        let (_, s) = try open()
        let w = s.world
        XCTAssertEqual(w.level.header.sidePush, -320)
        let pid = s.playerID
        func set(ground: UInt8, vx: Int32, riding: Int? = nil) {
            w.active.update(id: pid) { $0.groundKind = ground; $0.vx = vx }
            w.player.ridden = riding
            w.player.cameraSnapVeto = false
        }
        func p() throws -> SpriteSlot { try XCTUnwrap(w.active.record(id: pid)) }
        // Airborne: −320 per frame down to the cap.
        for (vx, want) in [(Int32(0), Int32(-320)), (-1279, -1599), (-1599, -1919), (-1600, -1600), (-2000, -2000),
                           (500, 180)] {
            set(ground: 0, vx: vx)
            let x256 = try p().x256
            Player.sidePush(w, id: pid)
            XCTAssertEqual(try p().vx, want, "airborne vx \(vx)")
            XCTAssertEqual(try p().x256, x256, "airborne: x untouched")
            XCTAssertFalse(w.player.cameraSnapVeto)
        }
        // Grounded, and airborne but riding: x256 − 80, vx untouched, the latch set.
        for (ground, riding) in [(UInt8(1), nil as Int?), (0, pid)] {
            set(ground: ground, vx: -1000, riding: riding)
            let x256 = try p().x256
            Player.sidePush(w, id: pid)
            XCTAssertEqual(try p().x256, x256 - 80, "ground \(ground) riding \(riding != nil)")
            XCTAssertEqual(try p().vx, -1000)
            XCTAssertTrue(w.player.cameraSnapVeto)
        }
    }
}
