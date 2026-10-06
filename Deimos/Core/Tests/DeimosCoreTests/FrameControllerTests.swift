import XCTest
@testable import DeimosCore

/// The 0x38-byte frame controller's arithmetic: timing-frame.md §1–§2.5 (HIGH).
final class FrameControllerTests: XCTestCase {
    /// One loop pass as `FUN_100051a0` drives it: begin frame, (world), end-frame wrapper.
    private func pass(_ c: inout FrameController, esc: Bool = false, escHoldPref: Bool = false) -> FrameController.Begin {
        let b = c.beginFrame(escDown: esc, escHoldPref: escHoldPref)
        c.endFrameWrapper(escDown: esc, escHoldPref: escHoldPref)
        return b
    }

    func testTickEveryPass() {
        var c = FrameController(fpsMaxRate: 30)
        XCTAssertFalse(c.tickNextFrame, "the constructor zeroes +0x34")
        c.startSession(filmPlayback: false, gameScreenLayout: true, autoInterlaceAllowed: true)
        XCTAssertEqual(c.speedDivider, 0)
        for n in 1...200 {
            let b = pass(&c)
            XCTAssertTrue(b.tick, "divider 0 ticks every pass (pass \(n))")
            XCTAssertEqual(b.framesPresented, Int32(n - 1), "begin returns +8 before this pass's end frame")
            XCTAssertEqual(c.framesPresented, Int32(n))
            XCTAssertEqual(c.windowFrames, Int32(n))
        }
        // The divider arithmetic itself (never non-zero in 1.0.6): D = 2 → 1, 0, 0, 1, 0, 0 …
        var d = FrameController(fpsMaxRate: 30)
        d.startSession(filmPlayback: false, gameScreenLayout: true, autoInterlaceAllowed: true)
        d.speedDivider = 2
        XCTAssertEqual((0..<7).map { _ in pass(&d).tick }, [true, true, false, false, true, false, false])
    }

    func testEscRule() {
        // Byte pref 8 = 0: quit on the first pass Esc is down.
        var a = FrameController(fpsMaxRate: 30)
        a.startSession(filmPlayback: false, gameScreenLayout: true, autoInterlaceAllowed: true)
        XCTAssertFalse(pass(&a).quit)
        let q = a.beginFrame(escDown: true, escHoldPref: false)
        XCTAssertTrue(q.quit)
        XCTAssertTrue(q.tick, "the quit pass still ticks; the pass completes (review M1)")
        a.endFrameWrapper(escDown: true, escHoldPref: false)
        XCTAssertEqual(a.framesPresented, 2)

        // Byte pref 8 = 1: counter bumped at begin and at the wrapper; quit when > 30 at a begin call
        // → the 16th held pass (1,2 | 3,4 | … | 29,30 | 31).
        var b = FrameController(fpsMaxRate: 30)
        b.startSession(filmPlayback: false, gameScreenLayout: true, autoInterlaceAllowed: true)
        for n in 1...15 {
            XCTAssertFalse(pass(&b, esc: true, escHoldPref: true).quit, "held pass \(n)")
            XCTAssertEqual(b.escHold, Int32(2 * n))
        }
        XCTAssertTrue(b.beginFrame(escDown: true, escHoldPref: true).quit)
        XCTAssertEqual(b.escHold, 31)

        // Release resets the counter.
        var c = FrameController(fpsMaxRate: 30)
        c.startSession(filmPlayback: false, gameScreenLayout: true, autoInterlaceAllowed: true)
        for _ in 1...10 { _ = pass(&c, esc: true, escHoldPref: true) }
        XCTAssertEqual(c.escHold, 20)
        XCTAssertFalse(c.beginFrame(escDown: false, escHoldPref: true).quit)
        XCTAssertEqual(c.escHold, 0)
        c.endFrameWrapper(escDown: false, escHoldPref: true)
        for n in 1...15 { XCTAssertFalse(pass(&c, esc: true, escHoldPref: true).quit, "re-held pass \(n)") }
        XCTAssertTrue(pass(&c, esc: true, escHoldPref: true).quit)
    }
}
