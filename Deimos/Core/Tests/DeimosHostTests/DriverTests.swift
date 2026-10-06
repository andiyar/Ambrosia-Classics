import XCTest
@testable import DeimosHost
import DeimosCore
import DeimosRender

/// The shipped assets, loaded once per test process (plan Landmine e).
private enum ShippedAssets {
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

    private func makeDriver() throws -> DeimosDriver {
        try DeimosDriver(assets: try ShippedAssets.get(), prefs: .fresh, rate: .classic,
                         start: SessionStart(sector: 1, players: 1, film: nil))
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
    }

    func testEscStartsNewSession() throws {
        let assets = try ShippedAssets.get()
        var driver = try makeDriver()
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

        // A new session at sector 1, seeded with the ticks of the restart (srand(TickCount()), 100057c8).
        let reference = try DeimosSession(assets: assets, prefs: .fresh,
                                          start: SessionStart(sector: 1, players: 1, film: nil),
                                          seed: try XCTUnwrap(restartTicks))
        XCTAssertEqual(driver.session.sector, 1)
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
    }

    /// Hang regression (review of e259561): Esc held for 2 s used to restart forever inside one `idle` (each new
    /// session's first pass quit on the still-held Esc, its limiter released against stamp 0, and the loop never
    /// yielded). Now each `idle` returns after bounded work, and one hold restarts once: the new session ignores Esc
    /// until a pass samples it released (the front end's end-session FlushEvents; front-end.md §2 — a new game
    /// needs a fresh press).
    func testEscHeldRestartsOnceAndIdleReturns() throws {
        var driver = try makeDriver()
        var clock = FakeClock(rate: .classic)
        while driver.presentCount < 20 {
            _ = driver.idle(seconds: clock.seconds, keys: HeldKeys())
            clock.seconds += Self.poll
            if clock.seconds > 60 { return XCTFail("no presents") }
        }
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
}
