import XCTest
@testable import DeimosHost
@testable import DeimosCore
import DeimosRender
import DeimosAudio

/// The shipped assets, loaded once per test process (plan Landmine e) — shared by every DeimosHostTests file.
enum ShippedAssets {
    static let loaded: Result<DeimosAssets, Error> = Result {
        try DeimosAssets.load(index: TagIndex(dataDirectory: DeimosData.dataDirectory()))
    }
    static func get() throws -> DeimosAssets { try loaded.get() }
}

/// A fake clock: the test owns the seconds handed to `idle`, polled at a fixed period.
private struct FakeClock {
    var seconds: Double = 0
    let rate: TickRate
    var ticks: UInt32 { MacTicks.ticks(seconds: seconds, rate: rate.perSecond) }
}

/// H1 — the driver (plan H1; timing-frame §2.3 limiter `10030ce4..10030d30`, fades `1000bac4`,
/// `1000bb50..1000bb78`, §4 no catch-up; engine-loop `100057c8` seed).
final class DriverTests: XCTestCase {

    private static let poll = 0.004
    private static let escKey: UInt16 = 0x35

    private func makeDriver(audio: (any DeimosAudioSink)? = nil, sector: Int = 1) throws -> DeimosDriver {
        try DeimosDriver(assets: try ShippedAssets.get(), prefs: .fresh, rate: .classic,
                         start: SessionStart(sector: sector, players: 1, film: nil), audio: audio)
    }

    func testTicksAtRate() {
        XCTAssertEqual(TickRate.classic.perSecond, 60.15)
        XCTAssertEqual(TickRate.osx.perSecond, 60.0)
        XCTAssertEqual(MacTicks.ticks(seconds: 1, rate: TickRate.classic.perSecond), 60)
        XCTAssertEqual(MacTicks.ticks(seconds: 10, rate: TickRate.classic.perSecond), 601)
        XCTAssertEqual(MacTicks.ticks(seconds: 100, rate: TickRate.classic.perSecond), 6015)
        XCTAssertEqual(MacTicks.ticks(seconds: 10, rate: TickRate.osx.perSecond), 600)
    }

    func testLimiterTwoTicksPolledEvery4ms() throws {
        var driver = try makeDriver()
        var clock = FakeClock(rate: .classic)
        var stamps: [UInt32] = []
        var guardCalls = 0
        while stamps.count < 301 {
            let before = driver.presentCount
            _ = driver.idle(seconds: clock.seconds, keys: HeldKeys())
            let presented = driver.presentCount - before
            XCTAssertLessThanOrEqual(presented, 1, "at most one present per poll")
            if presented == 1 { stamps.append(clock.ticks) }
            clock.seconds += Self.poll
            guardCalls += 1
            if guardCalls > 100_000 { return XCTFail("no presents after \(guardCalls) polls") }
        }
        let gaps = zip(stamps.dropFirst(), stamps).map { $0 &- $1 }
        XCTAssertEqual(gaps.count, 300)
        XCTAssertEqual(Set(gaps), [2], "present stamps exactly 2 ticks apart")
        XCTAssertEqual(driver.lastPresent, stamps.last)
    }

    func testFadeYieldsNineSteps() throws {
        var driver = try makeDriver()
        var clock = FakeClock(rate: .classic)
        var changes: [UInt32] = []       // ticks of each screen change before the first present
        var calls = 0
        while driver.presentCount == 0 {
            let out = driver.idle(seconds: clock.seconds, keys: HeldKeys())
            if out.screenChanged && driver.presentCount == 0 {
                changes.append(clock.ticks)
                // The first from-black step (a = 0) is an all-black window.
                if changes.count == 1 { XCTAssertTrue(driver.screen.pixels.allSatisfy { $0 == 0 }) }
            }
            clock.seconds += Self.poll
            calls += 1
            if calls > 100_000 { return XCTFail("no present") }
        }
        XCTAssertEqual(changes.count, 9, "nine fade steps, each one yield")
        for (b, a) in zip(changes.dropFirst(), changes) { XCTAssertGreaterThanOrEqual(b &- a, 1) }
        // The pass resumed after the ninth step's wait: pass 2's remaining ops ran (its limiter, its present), and
        // pass 3 began in the same poll — its logic ran as it began (game time 4) — and stopped at its limiter.
        XCTAssertEqual(driver.passCount, 4)
        XCTAssertEqual(driver.session.gameTime, 4)
        XCTAssertTrue(driver.session.appeared)
        XCTAssertFalse(driver.isFading)
    }

    func testNoCatchUp() throws {
        var driver = try makeDriver()
        var clock = FakeClock(rate: .classic)
        while driver.presentCount < 100 {
            _ = driver.idle(seconds: clock.seconds, keys: HeldKeys())
            clock.seconds += Self.poll
            if clock.seconds > 60 { return XCTFail("no presents") }
        }
        // Stall one second, then one poll.
        clock.seconds += 1.0
        let passes = driver.passCount, presents = driver.presentCount, time = driver.session.gameTime
        let out = driver.idle(seconds: clock.seconds, keys: HeldKeys())
        XCTAssertTrue(out.screenChanged)
        XCTAssertEqual(driver.presentCount - presents, 1, "one late present")
        XCTAssertEqual(driver.passCount - passes, 1, "one new pass, no catch-up")
        XCTAssertEqual(driver.session.gameTime - time, 1)
        let stallStamp = clock.ticks
        XCTAssertEqual(driver.lastPresent, stallStamp)
        // The rhythm resumes from the stall's stamp.
        while driver.presentCount == presents + 1 {
            clock.seconds += Self.poll
            _ = driver.idle(seconds: clock.seconds, keys: HeldKeys())
            if clock.seconds > 120 { return XCTFail("no present after the stall") }
        }
        XCTAssertEqual(clock.ticks, stallStamp + 2)

        // Caps Lock: the pass that samples it carries `.pauseWait` (the renderer traps on it). H2: the driver holds the
        // loop there — no pass begins while Caps Lock stays down — and runs on once an idle sees it up.
        let caps = HeldKeys(capsLock: true)
        var probe = driver.session
        XCTAssertTrue(probe.pass(keys: caps).ops.contains { if case .pauseWait = $0 { return true } else { return false } })
        let passesBeforeCaps = driver.passCount
        for _ in 0..<500 {
            clock.seconds += Self.poll
            _ = driver.idle(seconds: clock.seconds, keys: caps)
        }
        XCTAssertEqual(driver.passCount, passesBeforeCaps + 1, "one pass sampled Caps Lock, then the wait holds")
        while driver.passCount < passesBeforeCaps + 3 {
            clock.seconds += Self.poll
            _ = driver.idle(seconds: clock.seconds, keys: HeldKeys())
            if clock.seconds > 180 { return XCTFail("no passes after Caps Lock went up") }
        }
        XCTAssertTrue(driver.session.running)
    }

    /// ◇ Stand-in 3 + plan ruling 1 (`-sector N`): Esc restarts at the LAUNCH's sector — a sector-7 launch restarts
    /// at 7, a direct start, so one life (`FUN_10026cc0`: lives = 1 above sector 1). The restart also keeps the
    /// launch's player count (a two-player launch) and film (a `de01` launch). Bounds: fake clock 60 s / 120 s.
    func testEscStartsNewSession() throws {
        let assets = try ShippedAssets.get()
        // Started at sector 7, not 1, so a restart that ignored the launch's sector would show it.
        var driver = try makeDriver(sector: 7)
        XCTAssertEqual(driver.session.sector, 7)
        var clock = FakeClock(rate: .classic)
        while driver.presentCount < 20 {
            _ = driver.idle(seconds: clock.seconds, keys: HeldKeys())
            clock.seconds += Self.poll
            if clock.seconds > 60 { return XCTFail("no presents") }
        }
        XCTAssertEqual(driver.restarts, 0)
        XCTAssertGreaterThan(driver.session.gameTime, 20)

        // Hold Esc until a pass has sampled it, then release.
        let passes = driver.passCount
        while driver.passCount == passes {
            clock.seconds += Self.poll
            _ = driver.idle(seconds: clock.seconds, keys: HeldKeys(held: [Self.escKey]))
            if clock.seconds > 120 { return XCTFail("no pass with Esc") }
        }
        XCTAssertEqual(driver.restarts, 0, "the Esc pass still runs to its end")
        let loaded = driver.session.game.levels
        XCTAssertEqual(loaded.definitions.count, 12, "the first session loaded the twelve levels")
        let presents = driver.presentCount
        var restartTicks: UInt32?
        var passesAtRestart = 0
        while driver.restarts == 0 {
            clock.seconds += Self.poll
            _ = driver.idle(seconds: clock.seconds, keys: HeldKeys())
            if driver.restarts == 1 { restartTicks = clock.ticks; passesAtRestart = driver.passCount }
            if clock.seconds > 120 { return XCTFail("no restart") }
        }
        XCTAssertEqual(driver.presentCount - presents, 1, "the Esc pass presented")
        XCTAssertEqual(driver.restarts, 1)

        // A new session at the launch's sector 7, seeded with the ticks of the restart (srand(TickCount()), 100057c8).
        let reference = try DeimosSession(assets: assets, prefs: .fresh,
                                          start: SessionStart(sector: 7, players: 1, film: nil),
                                          seed: try XCTUnwrap(restartTicks))
        XCTAssertEqual(driver.session.sector, 7, "the restart starts at the launch's sector (ruling 1)")
        XCTAssertEqual(driver.session.game.flags.level, reference.game.flags.level)
        XCTAssertEqual(driver.session.players[0].lives, 1, "a start above sector 1 has one life (FUN_10026cc0)")
        XCTAssertTrue(driver.session.game.levels.isSameLoad(as: loaded),
                      "the restart reuses the ended session's level set — no second decode of the twelve masks")
        XCTAssertEqual(driver.session.rng, reference.rng)
        XCTAssertFalse(driver.session.appeared)
        XCTAssertEqual(driver.lastPresent, try XCTUnwrap(restartTicks), "the new controller's stamp starts at 0, so its first limiter releases at once and stamps the restart's ticks")
        // Game time restarted from 0: it counts the new session's passes.
        XCTAssertEqual(driver.session.gameTime, Int32(driver.passCount - passesAtRestart + 2))

        // The fade from black runs again: nine screen changes before the new session's first present.
        let presentsAtRestart = driver.presentCount
        var changes = 0
        var calls = 0
        while driver.presentCount == presentsAtRestart {
            clock.seconds += Self.poll
            let out = driver.idle(seconds: clock.seconds, keys: HeldKeys())
            if out.screenChanged && driver.presentCount == presentsAtRestart { changes += 1 }
            calls += 1
            if calls > 100_000 { return XCTFail("no present after restart") }
        }
        XCTAssertEqual(changes, 9)
        XCTAssertTrue(driver.session.appeared)

        // The restart keeps the launch's player count and film too: a two-player launch (`-players 2`) restarts with
        // both players in game, and a film launch (`-film de01`) restarts playing the same film from its start.
        func escRestart(_ d: inout DeimosDriver, _ label: String) -> Bool {
            var c = FakeClock(rate: .classic)
            while d.presentCount < 20 {
                _ = d.idle(seconds: c.seconds, keys: HeldKeys())
                c.seconds += Self.poll
                if c.seconds > 60 { XCTFail("\(label): no presents"); return false }
            }
            while d.restarts == 0 {
                _ = d.idle(seconds: c.seconds, keys: HeldKeys(held: [Self.escKey]))
                c.seconds += Self.poll
                if c.seconds > 120 { XCTFail("\(label): no restart"); return false }
            }
            return true
        }
        var two = try DeimosDriver(assets: assets, prefs: .fresh, rate: .classic,
                                   start: SessionStart(sector: 1, players: 2, film: nil))
        XCTAssertEqual(two.session.players.filter(\.inGame).count, 2, "launched with two players")
        guard escRestart(&two, "two players") else { return }
        XCTAssertEqual(two.restarts, 1)
        XCTAssertEqual(two.session.players.filter(\.inGame).count, 2, "the restart is still a two-player game")

        let film = try FilmLookup.film("de01", in: assets)
        var filmDriver = try DeimosDriver(assets: assets, prefs: .fresh, rate: .classic,
                                          start: SessionStart(sector: 1, players: 1, film: film))
        guard escRestart(&filmDriver, "film") else { return }
        XCTAssertEqual(filmDriver.restarts, 1)
        XCTAssertTrue(filmDriver.session.start.film == film, "the restart plays the launch's film")
        XCTAssertTrue(filmDriver.session.game.flags.filmPlaying, "the restarted session is a film (G+0x20)")
        let filmReference = try DeimosSession(assets: assets, prefs: .fresh,
                                              start: SessionStart(sector: 1, players: 1, film: film), seed: 0)
        XCTAssertEqual(filmDriver.session.rng, filmReference.rng, "from the film's own seed, not the restart's ticks")
    }

    /// Hang regression (review of e259561): Esc held for 2 s used to restart forever inside one `idle` (each new
    /// session's first pass quit on the still-held Esc, its limiter released against stamp 0, and the loop never
    /// yielded). Now each `idle` returns after bounded work, and one hold restarts once: the new session ignores Esc
    /// until a pass samples it released (the front end's end-session FlushEvents; front-end.md §2 — a new game
    /// needs a fresh press). Plan ruling 1: the session first crosses a level transition (sector 1 → 2, the level put
    /// one tick from its end as in the LT tests); the restart still starts at the LAUNCH's sector 1, not at the sector
    /// the session had reached.
    func testEscHeldRestartsOnceAndIdleReturns() throws {
        var driver = try makeDriver()
        var clock = FakeClock(rate: .classic)
        while driver.presentCount < 20 {
            _ = driver.idle(seconds: clock.seconds, keys: HeldKeys())
            clock.seconds += Self.poll
            if clock.seconds > 60 { return XCTFail("no presents") }
        }
        driver.session.game.flags.levelComplete = true
        driver.session.game.flags.levelEnding = true
        while driver.session.sector != 2 || driver.isFading {
            _ = driver.idle(seconds: clock.seconds, keys: HeldKeys())
            clock.seconds += Self.poll
            if clock.seconds > 120 { return XCTFail("no transition to sector 2") }
        }
        let presentsInSector2 = driver.presentCount
        while driver.presentCount < presentsInSector2 + 20 {
            _ = driver.idle(seconds: clock.seconds, keys: HeldKeys())
            clock.seconds += Self.poll
            if clock.seconds > 180 { return XCTFail("no presents in sector 2") }
        }
        XCTAssertEqual(driver.session.sector, 2, "the session crossed into sector 2")
        XCTAssertEqual(driver.restarts, 0, "a transition is not a restart")
        let esc = HeldKeys(held: [Self.escKey])
        let holdEnd = clock.seconds + 2.0
        var calls = 0
        var hidesAfterRestart = 0
        while clock.seconds < holdEnd {
            let passes = driver.passCount, presents = driver.presentCount, restarts = driver.restarts
            let out = driver.idle(seconds: clock.seconds, keys: esc)
            XCTAssertLessThanOrEqual(driver.restarts - restarts, 1, "at most one restart per idle")
            XCTAssertLessThanOrEqual(driver.passCount - passes, 2, "bounded passes per idle")
            XCTAssertLessThanOrEqual(driver.presentCount - presents, 1, "at most one present per idle")
            if driver.restarts > restarts { hidesAfterRestart += out.requests.filter { $0 == .hideCursor }.count }
            clock.seconds += Self.poll
            calls += 1
            if calls > 2_000 || driver.restarts > 1 { break }
        }
        XCTAssertEqual(driver.restarts, 1, "one hold, one restart")
        XCTAssertEqual(driver.session.sector, 1, "the launch's sector, not the sector 2 the session had reached")
        XCTAssertEqual(hidesAfterRestart, 1, "the new session hides the cursor")
        XCTAssertTrue(driver.session.running, "the held Esc is latched: the new session keeps running")

        // Release, then a fresh press ends the new session.
        for _ in 0..<10 {
            _ = driver.idle(seconds: clock.seconds, keys: HeldKeys())
            clock.seconds += Self.poll
        }
        XCTAssertEqual(driver.restarts, 1)
        calls = 0
        while driver.restarts == 1 {
            _ = driver.idle(seconds: clock.seconds, keys: esc)
            clock.seconds += Self.poll
            calls += 1
            if calls > 2_000 { return XCTFail("a fresh Esc press did not end the session") }
        }
        XCTAssertEqual(driver.restarts, 2)
        XCTAssertEqual(driver.session.sector, 1)
    }

    /// The limiter's add + `cmplw` wrap (`10030d08..10030d24`, replicated): with the stamp at 0xFFFFFFFE or
    /// 0xFFFFFFFF the target wraps to 0 or 1 and the wait never blocks, as in the original — but each `idle` still
    /// returns after at most one limiter release and one present, and after the wrap the 2-tick rhythm resumes.
    func testTickWrapNeverSpins() throws {
        var driver = try makeDriver()
        let start: UInt32 = 0xFFFF_FFF0
        var clock = FakeClock(seconds: (Double(start) + 0.5) / TickRate.classic.perSecond, rate: .classic)
        XCTAssertEqual(clock.ticks, start)
        var stamps: [UInt32] = []
        var calls = 0
        while stamps.count < 40 {
            let passes = driver.passCount, presents = driver.presentCount
            _ = driver.idle(seconds: clock.seconds, keys: HeldKeys())
            XCTAssertLessThanOrEqual(driver.passCount - passes, 2, "bounded passes per idle at ticks \(clock.ticks)")
            XCTAssertLessThanOrEqual(driver.presentCount - presents, 1, "at most one present per idle")
            if driver.presentCount > presents { stamps.append(clock.ticks) }
            clock.seconds += Self.poll
            calls += 1
            if calls > 10_000 { return XCTFail("no presents") }
        }
        XCTAssertTrue(stamps.contains { $0 >= 0xFFFF_FFFE }, "presents ran at the wrap")
        let after = stamps.filter { $0 < 0x8000_0000 && $0 >= 2 }
        XCTAssertGreaterThan(after.count, 10)
        XCTAssertEqual(Set(zip(after.dropFirst(), after).map { $0 &- $1 }), [2], "the rhythm resumes after the wrap")
    }

    // MARK: - H2: the driver, Phase 2

    private static let capsUp = HeldKeys()
    private static let f6Key: UInt16 = 0x61
    private static let minusKey: UInt16 = 0x1b
    private static let consoleKey: UInt16 = 0x32

    /// The pause (`FUN_10030870` → `FUN_10022ef0`, listing `10022f18..10023010`): the pass that samples Caps Lock
    /// down carries halt, `gaso 8` and the music pause to the sink when it begins; `.pauseWait` then holds the loop
    /// until an idle sees Caps Lock up (`10022f68..10022fa4`) — while it is held no pass begins, so the pause cannot
    /// re-fire; while the app is suspended Caps Lock is not even tested (`10022f84..10022fa0`: r29 = !suspended), and
    /// the resume handler is blocked by the pause flag r2−0x617b (`10023e7c..10023e8c`), so the music stays paused.
    /// Up → the pause's present, and the next pass's cues lead with the resume (`10022fb4`, one frame late). Caps
    /// Lock + Esc in one pass: the begin carries halt + gaso 8 + pause only; after the wait the resume (`10022fb4`),
    /// the present, then the session end's halt and stop (`10005ad8`, `10005ae4`), then the new session.
    /// Fake-clock cap 120 s.
    func testPauseWaitHoldsUntilCapsUp() throws {
        let assets = try ShippedAssets.get()
        let gaso8 = assets.sounds[8]
        let sink = RecordingSink()
        var driver = try makeDriver(audio: sink)
        var clock = FakeClock(rate: .classic)
        let cap = 120.0
        func idle(_ keys: HeldKeys) -> Bool {
            _ = driver.idle(seconds: clock.seconds, keys: keys)
            clock.seconds += Self.poll
            return clock.seconds <= cap
        }
        while driver.presentCount < 20 { guard idle(Self.capsUp) else { return XCTFail("no presents") } }

        // Caps Lock down: the next pass pauses; its cues reach the sink as it begins.
        let caps = HeldKeys(capsLock: true)
        var applies = sink.applies.count
        let passesBefore = driver.passCount
        while driver.passCount == passesBefore { guard idle(caps) else { return XCTFail("no pass with Caps Lock") } }
        let pausePass = driver.passCount
        XCTAssertEqual(sink.applies.count, applies + 1, "the pause pass's cues, once")
        let pause = try XCTUnwrap(sink.applies.last)
        XCTAssertEqual(pause.music.last, .pause)
        XCTAssertFalse(pause.music.contains(.resume), "no resume before the wait")
        XCTAssertEqual(pause.sounds.last?.id, gaso8)
        XCTAssertEqual(pause.halt, pause.sounds.count - 1, "the halt runs just before gaso 8")

        // Held for 3 s: no pass begins, the pause does not re-fire, nothing reaches the sink.
        applies = sink.applies.count
        let holdEnd = clock.seconds + 3
        while clock.seconds < holdEnd { guard idle(caps) else { return XCTFail("cap") } }
        XCTAssertEqual(driver.passCount, pausePass, "no pass while Caps Lock is down")
        XCTAssertEqual(sink.applies.count, applies)

        // Suspend during the wait: the music pause (10023dc8); Caps Lock up is not tested while suspended; resume
        // sends no music resume (blocked by the pause flag).
        driver.suspend()
        XCTAssertEqual(sink.applies.count, applies + 1)
        XCTAssertEqual(sink.applies.last, RecordingSink.Apply(sounds: [], music: [.pause], halt: nil))
        for _ in 0..<20 { guard idle(Self.capsUp) else { return XCTFail("cap") } }
        XCTAssertEqual(driver.passCount, pausePass, "suspended: the wait does not test Caps Lock")
        driver.resume()
        XCTAssertEqual(sink.applies.count, applies + 1, "the resume handler is blocked during the wait")
        for _ in 0..<20 { guard idle(caps) else { return XCTFail("cap") } }
        XCTAssertEqual(driver.passCount, pausePass)
        XCTAssertFalse(sink.applies.flatMap(\.music).contains(.resume), "music stays paused")

        // Caps Lock up: the wait ends in that idle — the pause's present — and the next pass begins, its music led by
        // the resume.
        applies = sink.applies.count
        let presents = driver.presentCount
        _ = idle(Self.capsUp)
        XCTAssertEqual(driver.presentCount, presents + 1, "the pause's present after the wait")
        XCTAssertEqual(driver.passCount, pausePass + 1)
        XCTAssertEqual(sink.applies.count, applies + 1)
        XCTAssertEqual(sink.applies.last?.music.first, .resume, "the resume reaches the sink after Caps Lock up")

        // Caps Lock stays up: no second pause.
        applies = sink.applies.count
        while driver.passCount < pausePass + 30 { guard idle(Self.capsUp) else { return XCTFail("cap") } }
        XCTAssertFalse(sink.applies.dropFirst(applies).flatMap(\.music).contains(.pause))

        // Caps Lock + Esc in one pass.
        let both = HeldKeys(held: [Self.escKey], capsLock: true)
        applies = sink.applies.count
        let p0 = driver.passCount
        while driver.passCount == p0 { guard idle(both) else { return XCTFail("no pass with Caps Lock + Esc") } }
        XCTAssertFalse(driver.session.running)
        XCTAssertEqual(sink.applies.count, applies + 1)
        let end = try XCTUnwrap(sink.applies.last)
        XCTAssertEqual(end.music.last, .pause, "the begin carries the pause, not the resume or the stop")
        XCTAssertFalse(end.music.contains(.resume))
        XCTAssertFalse(end.music.contains(.stop))
        XCTAssertEqual(end.sounds.last?.id, gaso8)
        XCTAssertEqual(end.halt, end.sounds.count - 1, "the pause's halt")
        let holdBoth = clock.seconds + 1
        while clock.seconds < holdBoth { guard idle(both) else { return XCTFail("cap") } }
        XCTAssertEqual(sink.applies.count, applies + 1, "nothing more until Caps Lock goes up")
        XCTAssertEqual(driver.restarts, 0)
        _ = idle(Self.capsUp)
        XCTAssertEqual(driver.restarts, 1)
        let after = Array(sink.applies.dropFirst(applies + 1))
        XCTAssertEqual(after.count, 3)
        guard after.count == 3 else { return }
        XCTAssertEqual(after[0], RecordingSink.Apply(sounds: [], music: [.resume], halt: nil), "10022fb4, after the wait")
        XCTAssertEqual(after[1], RecordingSink.Apply(sounds: [], music: [.stop], halt: 0), "10005ad8 halt, 10005ae4 stop")
        XCTAssertEqual(after[2].music, [.play(FourCC("ammu")!, loop: true), .stop, .level(100)], "the new session")

        // Outside a pause: resume only acts when suspended (10023e10..10023e34); suspend once per suspension
        // (10023db4..10023dbc); a resume with no pause holding the music resumes it (10023e88..10023e8c).
        applies = sink.applies.count
        driver.resume()
        XCTAssertEqual(sink.applies.count, applies, "not suspended: resume sends nothing")
        driver.suspend()
        driver.suspend()
        driver.resume()
        driver.resume()
        XCTAssertEqual(Array(sink.applies.dropFirst(applies)), [RecordingSink.Apply(sounds: [], music: [.pause], halt: nil),
                                                                RecordingSink.Apply(sounds: [], music: [.resume], halt: nil)])
    }

    /// Each pass's `sounds` / `music` / `haltEffectsAt` reach the sink once, in pass order, in the `idle` in which
    /// the pass begins — checked in lockstep against a reference session fed the same keys and TickCount; F6's
    /// `gaso 7` and the Esc pass's halt (at the end of its sounds, `10005ad8`) and stop (`10005ae4`) included.
    func testCuesRoutedAtPassBegin() throws {
        let assets = try ShippedAssets.get()
        let sink = RecordingSink()
        var driver = try makeDriver(audio: sink)
        var clock = FakeClock(rate: .classic)
        var ref = try DeimosSession(assets: assets, prefs: .fresh, start: SessionStart(sector: 1, players: 1, film: nil),
                                    seed: 0, ticks: 0)
        var expected: [RecordingSink.Apply] = []
        var idles = 0
        while driver.session.running {
            let n = driver.passCount
            var keys = HeldKeys()
            if (100..<103).contains(n) { keys.held.insert(Self.f6Key) }
            if n >= 200 { keys.held.insert(Self.escKey) }
            let applies = sink.applies.count
            _ = driver.idle(seconds: clock.seconds, keys: keys)
            var thisIdle: [RecordingSink.Apply] = []
            for _ in 0..<(driver.passCount - n) {
                let out = ref.pass(keys: keys, ticks: clock.ticks)
                if !(out.sounds.isEmpty && out.music.isEmpty && out.haltEffectsAt == nil) {
                    thisIdle.append(RecordingSink.Apply(sounds: out.sounds, music: out.music, halt: out.haltEffectsAt))
                }
            }
            XCTAssertEqual(Array(sink.applies.dropFirst(applies)), thisIdle, "idle \(idles)")
            expected += thisIdle
            clock.seconds += Self.poll
            idles += 1
            if idles > 20_000 { return XCTFail("bound: 20,000 idles") }
        }
        XCTAssertEqual(driver.restarts, 0)
        XCTAssertEqual(driver.session.rng, ref.rng, "the reference ran the same passes")
        XCTAssertEqual(sink.applies, expected)
        XCTAssertEqual(sink.applies.first?.music, [.play(FourCC("ammu")!, loop: true), .stop, .level(100)])
        XCTAssertTrue(sink.applies.contains { $0.music == [.play(FourCC("mu03")!, loop: true)] }, "the appear's music")
        XCTAssertTrue(sink.applies.contains { $0.sounds.contains { $0.id == assets.sounds[7] } }, "F6's gaso 7")
        let last = try XCTUnwrap(sink.applies.last)
        XCTAssertEqual(last.halt, last.sounds.count, "the session end's halt after the pass's sounds")
        XCTAssertEqual(last.music.last, .stop)
    }

    /// Typed characters (`HeldKeys.typed`, key-downs) accumulate across `idle` calls in which no pass begins and all
    /// reach the next pass; the open console takes one per frame (`FUN_1002d230`), so three passes later its line
    /// holds all three.
    func testTypedQueueAcrossIdleCalls() throws {
        var driver = try makeDriver()
        var clock = FakeClock(rate: .classic)
        while driver.presentCount < 20 {
            _ = driver.idle(seconds: clock.seconds, keys: HeldKeys())
            clock.seconds += Self.poll
            if clock.seconds > 60 { return XCTFail("no presents") }
        }
        let opening = driver.passCount
        while driver.passCount == opening {
            _ = driver.idle(seconds: clock.seconds, keys: HeldKeys(held: [Self.consoleKey]))
            clock.seconds += Self.poll
            if clock.seconds > 120 { return XCTFail("no pass with the console key") }
        }
        XCTAssertTrue(driver.session.console.isOpen)
        // The pass waits at its limiter: idles at the same clock begin no pass.
        let passes = driver.passCount
        for c: UInt8 in [0x61, 0x62, 0x63] {
            _ = driver.idle(seconds: clock.seconds, keys: HeldKeys(typed: [c]))
            XCTAssertEqual(driver.passCount, passes, "no pass began while typing")
        }
        while driver.passCount < passes + 3 {
            clock.seconds += Self.poll
            _ = driver.idle(seconds: clock.seconds, keys: HeldKeys())
            if clock.seconds > 180 { return XCTFail("no passes after typing") }
        }
        XCTAssertEqual(driver.session.console.text, [0x61, 0x62, 0x63])
    }

    /// ◇ Stand-in 3: the Esc that ended a session is latched, and the latch clears on a release seen by ANY `idle` —
    /// here one in which no pass begins (the driver waits at the new session's limiter). A fresh press then ends the
    /// new session. (On the Phase-1 driver only a pass's sample cleared the latch, so this press was swallowed.)
    func testEscLatchClearsOnSubPassRelease() throws {
        var driver = try makeDriver()
        var clock = FakeClock(rate: .classic)
        while driver.presentCount < 20 {
            _ = driver.idle(seconds: clock.seconds, keys: HeldKeys())
            clock.seconds += Self.poll
            if clock.seconds > 60 { return XCTFail("no presents") }
        }
        let esc = HeldKeys(held: [Self.escKey])
        while driver.restarts == 0 {
            _ = driver.idle(seconds: clock.seconds, keys: esc)
            clock.seconds += Self.poll
            if clock.seconds > 120 { return XCTFail("no restart") }
        }
        let passes = driver.passCount
        _ = driver.idle(seconds: clock.seconds, keys: HeldKeys())
        XCTAssertEqual(driver.passCount, passes, "the release idle began no pass")
        var calls = 0
        while driver.restarts == 1 {
            clock.seconds += Self.poll
            _ = driver.idle(seconds: clock.seconds, keys: esc)
            calls += 1
            if calls > 2_000 { return XCTFail("the fresh Esc press was swallowed by the latch") }
        }
        XCTAssertEqual(driver.restarts, 2)
    }

    /// ◇ Stand-in 6: a restart keeps the ended session's prefs — F6 (byte pref 5) and `-` (int pref 0, 50 → 40)
    /// then Esc → the carried prefs; the new level start sees pref 5 set (suspended until its appear, `1000693c`).
    /// ◇ Stand-in 2: game over (no input: the pilot dies; running clears at gameOverStart + 111) restarts the same
    /// way, carrying the prefs again. Plan ruling 1: launched at sector 7 (`-sector 7`), both restarts start at 7.
    /// Bound: fake clock 300 s.
    func testPrefsSurviveRestart() throws {
        var driver = try makeDriver(sector: 7)
        var clock = FakeClock(rate: .classic)
        func idle(_ keys: HeldKeys) -> Bool {
            _ = driver.idle(seconds: clock.seconds, keys: keys)
            clock.seconds += Self.poll
            return clock.seconds <= 300
        }
        while driver.presentCount < 20 { guard idle(HeldKeys()) else { return XCTFail("no presents") } }
        XCTAssertEqual(driver.prefs.bytePrefs[5], 0)
        XCTAssertEqual(driver.prefs.intPrefs[0], 50)
        let p = driver.passCount
        while driver.passCount == p {
            guard idle(HeldKeys(held: [Self.f6Key, Self.minusKey])) else { return XCTFail("no F6 pass") }
        }
        XCTAssertEqual(driver.session.prefs.bytePrefs[5], 1)
        XCTAssertEqual(driver.session.prefs.intPrefs[0], 40)

        while driver.restarts == 0 { guard idle(HeldKeys(held: [Self.escKey])) else { return XCTFail("no restart") } }
        XCTAssertEqual(driver.prefs.bytePrefs[5], 1, "carried: F6")
        XCTAssertEqual(driver.prefs.intPrefs[0], 40, "carried: the volume")
        XCTAssertEqual(driver.session.sector, 7, "Esc restarts at the launch's sector")
        XCTAssertTrue(driver.session.restoreInterlace, "the new level start saw pref 5 set")

        var gameOver = false
        while driver.restarts == 1 {
            guard idle(HeldKeys()) else { return XCTFail("no game over") }
            if !driver.session.running && driver.session.game.flags.noPlayerAlive { gameOver = true }
        }
        XCTAssertTrue(gameOver, "the second session ended on game over")
        XCTAssertEqual(driver.restarts, 2)
        XCTAssertEqual(driver.session.sector, 7, "game over restarts at the launch's sector")
        XCTAssertEqual(driver.prefs.bytePrefs[5], 1, "carried again (restored at the appear)")
        XCTAssertEqual(driver.prefs.intPrefs[0], 40)
    }

    // MARK: - LT: the level transition

    /// The cues around the transition's fade to black (`FUN_10007170`, `10007200..1000725c`): the music stop and `tran`
    /// reach the sink when the transition pass begins, before the fade's first step; nothing while the 33 steps run;
    /// the rest only once the fade's last step has been presented (each step ≥ 1 tick, `1000ba34..1000ba44`) — the new
    /// level's cues at sector 1 → 2, the session end's halt and stop at sector 12 → `none` (`tran` is not halted
    /// before the fade finishes). The frame controller's FPS window restarts at the tick the fade ended (`10030314`,
    /// after `10007234`). The level is put one tick from its end by setting G+0x09 (the tallies done) with P1 in game.
    /// Fake-clock cap 120 s per sector.
    func testTransitionCuesSplitAroundFade() throws {
        let assets = try ShippedAssets.get()
        let tran = SoundPlay.perm(assets.sounds[3], priority: 75, volume: 100, allowMultiple: true)
        for sector in [1, 12] {
            let sink = RecordingSink()
            var driver = try makeDriver(audio: sink, sector: sector)
            var clock = FakeClock(rate: .classic)
            let cap = 120.0
            var idleTicks: UInt32 = 0                                   // the TickCount of the last idle
            func idle() -> Bool {
                idleTicks = clock.ticks
                _ = driver.idle(seconds: clock.seconds, keys: HeldKeys())
                clock.seconds += Self.poll
                return clock.seconds <= cap
            }
            while driver.presentCount < 20 { guard idle() else { return XCTFail("no presents (sector \(sector))") } }
            driver.session.game.flags.levelComplete = true
            driver.session.game.flags.levelEnding = true
            XCTAssertTrue(driver.session.players[0].inGame)

            // The transition pass begins and stops at its fade's first step.
            let applies = sink.applies.count, passes = driver.passCount
            while driver.passCount == passes { guard idle() else { return XCTFail("no transition pass") } }
            let fadeBegan = idleTicks
            XCTAssertTrue(driver.isFading, "sector \(sector): the pass waits inside its fade")
            let begin = Array(sink.applies.dropFirst(applies))
            XCTAssertEqual(begin.count, 1, "sector \(sector)")
            XCTAssertEqual(begin.first?.music, [.stop], "sector \(sector): 10007204 only")
            XCTAssertEqual(begin.first?.sounds.last, tran, "sector \(sector): 1000720c..10007224")
            XCTAssertNil(begin.first?.halt, "sector \(sector): tran is not halted before the fade")

            // While the fade runs nothing reaches the sink.
            var fadeEnded: UInt32?
            while driver.isFading {
                let before = sink.applies.count
                guard idle() else { return XCTFail("the fade never ended") }
                if driver.isFading {
                    XCTAssertEqual(sink.applies.count, before, "sector \(sector): nothing during the fade")
                } else {
                    fadeEnded = idleTicks
                }
            }
            let ended = try XCTUnwrap(fadeEnded)
            XCTAssertGreaterThanOrEqual(ended &- fadeBegan, 33, "33 steps, each followed by a wait of ≥ 1 tick")
            let after = Array(sink.applies.dropFirst(applies + 1))
            XCTAssertGreaterThanOrEqual(after.count, 1)
            if sector == 1 {
                XCTAssertEqual(after.first?.music, [.play(FourCC("ammu")!, loop: true), .stop, .level(100)],
                               "the new level's cues after the fade")
                XCTAssertNil(after.first?.halt)
                XCTAssertEqual(driver.session.sector, 2)
                XCTAssertTrue(driver.session.running)
                XCTAssertEqual(driver.restarts, 0, "a transition is not a restart")
                XCTAssertEqual(driver.session.controller.fpsWindowStart, ended,
                               "FUN_100302e0's FPS init runs at the tick the fade ended")
            } else {
                XCTAssertEqual(after.first, RecordingSink.Apply(sounds: [], music: [.resume, .stop], halt: 0),
                               "1000669c resume, then the session end's halt (10005ad8) and stop (10005ae4)")
                XCTAssertEqual(driver.restarts, 1, "the campaign end restarts (◇) after the pass")
                XCTAssertEqual(driver.session.sector, 12, "a sector-12 launch restarts at 12 (ruling 1)")
                XCTAssertEqual(after.dropFirst().first?.music, [.play(FourCC("ammu")!, loop: true), .stop, .level(100)],
                               "then the new session's level start")
            }
        }
    }

    /// Characters typed while the transition's fade runs are dropped: `FUN_100302e0` flushes the event queue after
    /// the fade (`10030328`). Byte pref 10 off (no limiter), so a pass's end returns from `idle` and the queue is
    /// visible between passes. Characters typed after the fade still reach the next passes (the console takes one per
    /// frame). Fake-clock cap 120 s.
    func testTypedKeysDroppedAcrossTransitionFade() throws {
        var prefs = DeimosPrefs.fresh
        prefs.bytePrefs[10] = 0
        var driver = try DeimosDriver(assets: try ShippedAssets.get(), prefs: prefs, rate: .classic,
                                      start: SessionStart(sector: 1, players: 1, film: nil))
        var clock = FakeClock(rate: .classic)
        let cap = 120.0
        func idle(_ keys: HeldKeys = HeldKeys()) -> Bool {
            _ = driver.idle(seconds: clock.seconds, keys: keys)
            clock.seconds += Self.poll
            return clock.seconds <= cap
        }
        while driver.presentCount < 20 { guard idle() else { return XCTFail("no presents") } }
        driver.session.game.flags.levelComplete = true
        driver.session.game.flags.levelEnding = true
        let passes = driver.passCount
        while driver.passCount == passes { guard idle() else { return XCTFail("no transition pass") } }
        XCTAssertTrue(driver.isFading)
        let transitionPass = driver.passCount
        var typedDuringFade = 0
        while driver.isFading {
            guard idle(HeldKeys(typed: [0x61])) else { return XCTFail("the fade never ended") }
            if driver.isFading {
                typedDuringFade += 1
                XCTAssertEqual(driver.typedQueue.count, typedDuringFade, "queued while the fade runs")
            }
        }
        XCTAssertGreaterThan(typedDuringFade, 30)
        XCTAssertEqual(driver.passCount, transitionPass, "no pass began in the idle the fade ended")
        XCTAssertEqual(driver.typedQueue, [], "FlushEvents after the fade (10030328)")
        XCTAssertEqual(driver.session.sector, 2)

        // After the fade: open the console, then type — the characters reach it.
        guard idle(HeldKeys(held: [Self.consoleKey])) else { return XCTFail("cap") }
        XCTAssertTrue(driver.session.console.isOpen)
        guard idle(HeldKeys(typed: [0x62])) else { return XCTFail("cap") }
        for _ in 0..<5 { guard idle() else { return XCTFail("cap") } }
        XCTAssertEqual(driver.session.console.text, [0x62])
    }

    /// Phase 4 SK-a — the front end's host waits (`HostWait`, plan S1a; A §1, §4), run by the driver the way it runs a
    /// fade. No session emits them yet, so the test splices them into the running pass (`insertOps`).
    /// 1. `.ticks(10)`: held until `TickCount ≥ t0 + 10`, t0 = the tick the wait was reached; then `.clickOrKey`, which
    ///    the input that arrived during the tick wait releases at once — and all of it (typed, key events, a mouse-down,
    ///    a shell event) reaches the next pass: queued, not dropped (the console shows the typed `a`).
    /// 2. `.clickOrKey` with nothing but a held key: held; a mouse-down releases it, and so does a lone autoKey event
    ///    (no typed character, no click).
    /// 3. `.answer`: an unrelated shell event does not release it; the answer does, and both events reach the pass.
    /// 4. FlushEvents (here the pause wait's, `10022f1c`) empties the OS queue — typed, key events, mouse-downs — and
    ///    keeps the shell's own events: a Quit request queued before it reaches the next pass.
    /// Bound: 50,000 polls (fake clock).
    func testDriverRunsHostWaits() throws {
        var driver = try makeDriver()
        var clock = FakeClock(rate: .classic)
        var calls = 0
        func idle(_ keys: HeldKeys = HeldKeys()) -> Bool {
            _ = driver.idle(seconds: clock.seconds, keys: keys)
            clock.seconds += Self.poll
            calls += 1
            return calls < 50_000
        }
        while driver.presentCount < 20 { guard idle() else { return XCTFail("no presents") } }
        let opening = driver.passCount
        while driver.passCount == opening { guard idle(HeldKeys(held: [Self.consoleKey])) else { return XCTFail("cap") } }
        for _ in 0..<10 { guard idle() else { return XCTFail("cap") } }
        XCTAssertTrue(driver.session.console.isOpen)
        XCTAssertNil(driver.waitingOn)

        // 1. Ticks, then click-or-key, with input arriving during the tick wait.
        driver.insertOps([.hostWait(.ticks(10)), .hostWait(.clickOrKey)])
        let passes = driver.passCount
        let t0 = clock.ticks
        guard idle() else { return XCTFail("cap") }
        XCTAssertEqual(driver.waitingOn, .ticks(10))
        let click = MousePoint(h: 100, v: 200)
        let keyA = KeyEvent(charCode: 0x61, keyCode: 0x00)
        guard idle(HeldKeys(typed: [0x61], mouseDowns: [click], keyEvents: [keyA], events: [.suspend])) else {
            return XCTFail("cap")
        }
        var released: UInt32?
        while released == nil {
            let before = driver.passCount
            let now = clock.ticks
            guard idle() else { return XCTFail("cap") }
            if driver.passCount != before { released = now }
            if released == nil {
                XCTAssertLessThan(now, t0 &+ 10, "no pass begins before the tick wait ends")
                XCTAssertEqual(driver.waitingOn, .ticks(10))
            }
        }
        XCTAssertEqual(released, t0 &+ 10, "the tick wait ends at t0 + 10, and the queued input ends click-or-key at once")
        XCTAssertEqual(driver.passCount, passes + 1)
        XCTAssertNil(driver.waitingOn)
        XCTAssertEqual(driver.lastPassKeys.typed, [0x61])
        XCTAssertEqual(driver.lastPassKeys.keyEvents, [keyA])
        XCTAssertEqual(driver.lastPassKeys.mouseDowns, [click])
        XCTAssertEqual(driver.lastPassKeys.events, [.suspend])
        for _ in 0..<10 { guard idle() else { return XCTFail("cap") } }
        XCTAssertEqual(driver.session.console.text, [0x61], "the character typed during the wait reached the game")

        // 2. Click-or-key: a held key is not an event; a mouse-down is.
        driver.insertOps([.hostWait(.clickOrKey)])
        let held = driver.passCount
        for _ in 0..<300 {
            guard idle(HeldKeys(held: [0x31], mouse: MousePoint(h: 5, v: 5), mouseButton: true)) else {
                return XCTFail("cap")
            }
        }
        XCTAssertEqual(driver.passCount, held, "nothing but held state: the wait holds")
        XCTAssertEqual(driver.waitingOn, .clickOrKey)
        let down = MousePoint(h: 320, v: 240)
        guard idle(HeldKeys(mouseDowns: [down])) else { return XCTFail("cap") }
        XCTAssertNotEqual(driver.waitingOn, .clickOrKey)
        while driver.passCount == held { guard idle() else { return XCTFail("no pass after the click") } }
        XCTAssertEqual(driver.lastPassKeys.mouseDowns, [down])

        // 2b. A key event alone (an autoKey: no typed character) releases it too.
        driver.insertOps([.hostWait(.clickOrKey)])
        let keyed = driver.passCount
        for _ in 0..<300 { guard idle() else { return XCTFail("cap") } }
        XCTAssertEqual(driver.waitingOn, .clickOrKey)
        let repeatA = KeyEvent(charCode: 0x61, keyCode: 0x00, autoRepeat: true)
        guard idle(HeldKeys(keyEvents: [repeatA])) else { return XCTFail("cap") }
        XCTAssertNotEqual(driver.waitingOn, .clickOrKey, "a key event ends click-or-key")
        while driver.passCount == keyed { guard idle() else { return XCTFail("no pass after the key") } }
        XCTAssertEqual(driver.lastPassKeys.keyEvents, [repeatA])
        XCTAssertEqual(driver.lastPassKeys.typed, [])

        // 3. The answer to a question.
        driver.insertOps([.hostWait(.answer)])
        let asked = driver.passCount
        guard idle(HeldKeys(typed: [0x62], events: [.aboutChosen])) else { return XCTFail("cap") }
        for _ in 0..<300 { guard idle() else { return XCTFail("cap") } }
        XCTAssertEqual(driver.passCount, asked, "no answer yet: the wait holds")
        XCTAssertEqual(driver.waitingOn, .answer)
        guard idle(HeldKeys(events: [.answer(.second)])) else { return XCTFail("cap") }
        while driver.passCount == asked { guard idle() else { return XCTFail("no pass after the answer") } }
        XCTAssertEqual(driver.lastPassKeys.events, [.aboutChosen, .answer(.second)])
        XCTAssertEqual(driver.lastPassKeys.typed, [0x62])

        // 4. FlushEvents keeps the shell's events: input queued during a tick wait, then the pause wait's flush.
        let console = driver.session.console.text
        driver.insertOps([.hostWait(.ticks(3)), .pauseWait(.gameScreen)])
        let flushed = driver.passCount
        guard idle() else { return XCTFail("cap") }
        XCTAssertEqual(driver.waitingOn, .ticks(3))
        guard idle(HeldKeys(typed: [0x63], mouseDowns: [click], keyEvents: [KeyEvent(charCode: 0x63, keyCode: 0x08)],
                            events: [.quitRequested])) else { return XCTFail("cap") }
        while driver.passCount == flushed { guard idle() else { return XCTFail("no pass after the pause wait") } }
        XCTAssertEqual(driver.lastPassKeys.typed, [], "FlushEvents empties the OS queue")
        XCTAssertEqual(driver.lastPassKeys.keyEvents, [])
        XCTAssertEqual(driver.lastPassKeys.mouseDowns, [])
        XCTAssertEqual(driver.lastPassKeys.events, [.quitRequested], "the shell's own events are not OS-queue events")
        for _ in 0..<10 { guard idle() else { return XCTFail("cap") } }
        XCTAssertEqual(driver.session.console.text, console, "the flushed character never reached the game")
    }

    /// Phase 4 SK-a — `.voiceEnd(id)` (boot step 12, `100003b0..10000404`: spin while `FUN_100476e0('publ')`): held
    /// while the sink reports the id sounding — another id ending does not matter — and released by the first poll
    /// after it stops; with no sound system (`audio == nil`, no mixer) nothing sounds and the wait ends at once. Then
    /// the other audio wait, `.musicStopped(maxTicks:)`: its bound, its release on the fade's end, no sink.
    /// Bound: 50,000 polls (fake clock).
    func testVoiceEndWaitReleases() throws {
        let publ = FourCC("publ")!, incl = FourCC("incl")!
        let sink = VoiceSink()
        var driver = try makeDriver(audio: sink)
        var clock = FakeClock(rate: .classic)
        var calls = 0
        func idle(_ d: inout DeimosDriver) -> Bool {
            _ = d.idle(seconds: clock.seconds, keys: HeldKeys())
            clock.seconds += Self.poll
            calls += 1
            return calls < 50_000
        }
        while driver.presentCount < 20 { guard idle(&driver) else { return XCTFail("no presents") } }

        sink.playing = [publ, incl]
        driver.insertOps([.hostWait(.voiceEnd(publ))])
        let passes = driver.passCount
        for _ in 0..<300 { guard idle(&driver) else { return XCTFail("cap") } }
        XCTAssertEqual(driver.waitingOn, .voiceEnd(publ))
        sink.playing = [publ]
        for _ in 0..<300 { guard idle(&driver) else { return XCTFail("cap") } }
        XCTAssertEqual(driver.passCount, passes, "publ still sounds: the wait holds")
        XCTAssertEqual(driver.waitingOn, .voiceEnd(publ))
        sink.playing = []
        guard idle(&driver) else { return XCTFail("cap") }
        XCTAssertNil(driver.waitingOn, "the first poll after the voice ends releases the wait")
        while driver.passCount == passes { guard idle(&driver) else { return XCTFail("no pass after the voice ended") } }

        // No sound system: no mixer, so no voice sounds.
        var silent = try makeDriver()
        while silent.presentCount < 20 { guard idle(&silent) else { return XCTFail("no presents") } }
        silent.insertOps([.hostWait(.voiceEnd(publ))])
        guard idle(&silent) else { return XCTFail("cap") }
        XCTAssertNil(silent.waitingOn)

        // The music fade's wait (`FUN_10048120(1)`, `10048164..100481ac`): t0 = TickCount, then while the fade runs
        // (`FUN_100d05a8`) idle and leave once TickCount > t0 + 600 (`cmplw; ble`). A fade that never ends — no audio
        // rendering — releases on the first poll at t0 + 601; a fade that ends releases on the next poll.
        sink.fading = true
        driver.insertOps([.hostWait(.musicStopped(maxTicks: 600))])
        var t0: UInt32?
        while t0 == nil {
            let now = clock.ticks
            guard idle(&driver) else { return XCTFail("cap") }
            if driver.waitingOn == .musicStopped(maxTicks: 600) { t0 = now }
        }
        let reached = try XCTUnwrap(t0)
        var releasedAt: UInt32?
        while releasedAt == nil {
            let now = clock.ticks
            guard idle(&driver) else { return XCTFail("bound: the music wait never released") }
            if driver.waitingOn == nil { releasedAt = now } else { XCTAssertLessThanOrEqual(now, reached &+ 600) }
        }
        XCTAssertEqual(releasedAt, reached &+ 601, "the bound: the first TickCount past t0 + 600")

        driver.insertOps([.hostWait(.musicStopped(maxTicks: 600))])
        for _ in 0..<300 { guard idle(&driver) else { return XCTFail("cap") } }
        XCTAssertEqual(driver.waitingOn, .musicStopped(maxTicks: 600), "the fade runs: the wait holds")
        sink.fading = false
        guard idle(&driver) else { return XCTFail("cap") }
        XCTAssertNil(driver.waitingOn, "the fade is over: released on the next poll")

        silent.insertOps([.hostWait(.musicStopped(maxTicks: 600))])
        guard idle(&silent) else { return XCTFail("cap") }
        XCTAssertNil(silent.waitingOn, "no sound system: no music fades")
    }
}

/// A sink whose effects "sound" while their ids are in `playing` (single-threaded tests).
final class VoiceSink: DeimosAudioSink, @unchecked Sendable {
    var playing: Set<FourCC> = []
    /// The music's fade-out "runs" while true.
    var fading = false

    func apply(sounds: [SoundCue], music: [MusicCue], haltEffectsAt: Int?) {}

    func isPlaying(_ id: FourCC) -> Bool { playing.contains(id) }

    func isMusicFading() -> Bool { fading }
}

/// A sink that records every `apply`, in order (single-threaded tests).
final class RecordingSink: DeimosAudioSink, @unchecked Sendable {
    struct Apply: Equatable {
        var sounds: [SoundCue]
        var music: [MusicCue]
        var halt: Int?
    }
    private(set) var applies: [Apply] = []

    func apply(sounds: [SoundCue], music: [MusicCue], haltEffectsAt: Int?) {
        applies.append(Apply(sounds: sounds, music: music, halt: haltEffectsAt))
    }

    /// No mixer behind it: nothing sounds, no music fades.
    func isPlaying(_ id: FourCC) -> Bool { false }

    func isMusicFading() -> Bool { false }
}
