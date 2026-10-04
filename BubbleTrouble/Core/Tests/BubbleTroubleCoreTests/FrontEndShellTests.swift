@testable import BubbleTroubleCore
import Foundation
import XCTest

/// A2 — the front end's shell seams the App drives (plan 2026-10-04 btx-playable §A2 + C8 carry): frames carry
/// TickCount (the FPS readout counts against it), `_gShowFPS` outlives a `_PlayGame`, the cheat buffer sees key-downs
/// only (`_PauseGame` event kind 3, not autoKey 5) and never ⌘ keys, menu-bar prefs reach the front end, and the
/// menu-bar Quit at the main menu (`_HandleMenuChoice` 0x81/1: `_StopMusic` then quit). Data-gated (G1 sets it).
final class FrontEndShellTests: XCTestCase {
    private static let away = MousePoint(h: 600, v: 20, button: false)

    private func frontEnd(prefs: BTXPrefs = .defaults) throws -> FrontEnd {
        let data = try BTXGameData(resourcesDirectory: BTXTestData.resourcesDirectory())
        return FrontEnd(data: data, prefs: prefs, highScores: .empty, registeredName: "Ben", today: { (3, 3) })
    }

    @discardableResult
    private func ticks(_ fe: FrontEnd, now: inout UInt32, limit: Int = 3000,
                       while condition: (FrontEnd) -> Bool) -> SessionOutput {
        var all = SessionOutput()
        var n = 0
        while condition(fe) && n < limit {
            all.append(fe.tick(now: now, keys: HeldKeys(), mouse: Self.away))
            now += 1
            n += 1
        }
        XCTAssertLessThan(n, limit, "tick loop did not finish")
        return all
    }

    /// Splash → menu → a demo (D) running its frames.
    private func startDemo(_ fe: FrontEnd, now: inout UInt32) throws -> GameSession {
        ticks(fe, now: &now) { $0.phase != .menu }
        _ = fe.key(0x02, chars: "d", modifiers: KeyModifiers())
        ticks(fe, now: &now) { $0.session == nil }
        let s = try XCTUnwrap(fe.session)
        ticks(fe, now: &now) { $0.session?.phase == .wipe }
        XCTAssertTrue(fe.wantsFrameTimer)
        return s
    }

    func testFrameWithTicksDrawsFPS() throws {
        let fe = try frontEnd()
        var now: UInt32 = 1000
        let s = try startDemo(fe, now: &now)
        s.showFPS = true
        var fps = 0
        for _ in 0..<70 {
            now += 2
            for op in fe.frame(keys: HeldKeys(), now: now).drawOps { if case .fps = op { fps += 1 } }
        }
        XCTAssertGreaterThanOrEqual(fps, 1, "140 ticks of frames → at least one `_DrawFPS`")
    }

    func testShowFPSCarriesIntoNextSession() throws {
        let fe = try frontEnd()
        var now: UInt32 = 1000
        let first = try startDemo(fe, now: &now)
        first.showFPS = true
        _ = fe.frame(keys: HeldKeys(), now: now)
        _ = fe.key(0x31, chars: " ", modifiers: KeyModifiers())
        XCTAssertEqual(fe.frame(keys: HeldKeys(), now: now).ended, .demoInterrupted)
        ticks(fe, now: &now) { $0.phase != .menu }
        _ = fe.key(0x02, chars: "d", modifiers: KeyModifiers())
        ticks(fe, now: &now) { $0.session == nil }
        let second = try XCTUnwrap(fe.session)
        XCTAssertFalse(second === first)
        XCTAssertTrue(second.showFPS, "_gShowFPS is never reset by _PlayGame")
    }

    func testPausedCheatBufferTakesKeyDownsOnly() throws {
        let fe = try frontEnd()
        var now: UInt32 = 1000
        ticks(fe, now: &now) { $0.phase != .menu }
        _ = fe.key(0x2d, chars: "n", modifiers: KeyModifiers())
        ticks(fe, now: &now) { $0.session == nil }
        let s = try XCTUnwrap(fe.session)
        ticks(fe, now: &now) { $0.session?.phase == .wipe }
        _ = fe.frame(keys: HeldKeys(), now: now)
        _ = fe.frame(keys: HeldKeys(capsLock: true), now: now)
        XCTAssertEqual(s.phase, .paused)
        let seeded = try XCTUnwrap(s.cheatBuffer)
        _ = fe.key(0x06, chars: "Z", modifiers: KeyModifiers(capsLock: true), isRepeat: true)
        XCTAssertEqual(s.cheatBuffer, seeded, "autoKey (kind 5) is not handled by _PauseGame")
        _ = fe.key(0x06, chars: "Z", modifiers: KeyModifiers(command: true, capsLock: true))
        XCTAssertEqual(s.cheatBuffer, seeded, "⌘ held → ignored (000178e8)")
        _ = fe.key(0x06, chars: "Z", modifiers: KeyModifiers(capsLock: true))
        XCTAssertEqual(s.cheatBuffer, Array(seeded.dropFirst()) + [0x5a])
        // A Mac Roman character arrives as its Mac Roman byte (é = 0x8E).
        _ = fe.key(0x0e, chars: "é", modifiers: KeyModifiers(capsLock: true))
        XCTAssertEqual(s.cheatBuffer?.last, 0x8e)
    }

    func testMenuBarPrefsReachFrontEndAndGame() throws {
        let fe = try frontEnd()
        var now: UInt32 = 1000
        ticks(fe, now: &now) { $0.phase != .menu }
        var p = fe.prefs
        p.musicVolume = 1
        fe.prefsChanged(p)
        XCTAssertEqual(fe.prefs.musicVolume, 1)
        let s = try startDemo(fe, now: &now)
        XCTAssertEqual(s.prefs.musicVolume, 1, "the game starts from the changed prefs")
        p.sfxVolume = 2
        fe.prefsChanged(p)
        XCTAssertEqual(s.prefs.sfxVolume, 2, "a running game sees the change at once (_HandleMenuChoice)")
        XCTAssertEqual(fe.prefs.sfxVolume, 2)
    }

    func testMenuBarQuitFadesTitleMusicThenQuits() throws {
        let fe = try frontEnd()
        var now: UInt32 = 1000
        ticks(fe, now: &now) { $0.phase != .menu }
        var out = try XCTUnwrap(fe.quitFromMenuBar())
        XCTAssertEqual(out.music.first, .volume(0x100), "_StopMusic: the blocking fade from 0x100 (music 4)")
        out.append(ticks(fe, now: &now) { $0.phase != .quit })
        XCTAssertTrue(out.music.contains(.stopNow))
        XCTAssertEqual(out.requests.last, .quit)
        XCTAssertEqual(fe.phase, .quit)
        // Not at the idle menu (a blocking step pending): no fade — the App quits at once.
        let busy = try frontEnd()
        XCTAssertNil(busy.quitFromMenuBar(), "splash: not the idle menu")
        XCTAssertEqual(busy.phase, .splash)
    }

    /// A screen that records the keys it is given.
    private final class KeyRecorder: FrontEndScreen {
        var keys: [String] = []
        var result: FrontEndScreenResult?
        func tick(now: UInt32, keys: HeldKeys, mouse: MousePoint) -> SessionOutput { SessionOutput() }
        func key(_ code: UInt16, chars: String, modifiers: KeyModifiers) -> SessionOutput {
            keys.append(chars)
            return SessionOutput()
        }
        func mouseDown(h: Int, v: Int, modifiers: KeyModifiers) -> SessionOutput { SessionOutput() }
        func mouseUp(h: Int, v: Int, modifiers: KeyModifiers) -> SessionOutput { SessionOutput() }
        func appActivated() -> SessionOutput { SessionOutput() }
        func appDeactivated() -> SessionOutput { SessionOutput() }
        func dialogAnswered(_ answer: FrontEndDialogAnswer) -> SessionOutput { SessionOutput() }
    }

    func testScreensTakeKeyDownsNotAutoKey() throws {
        let fe = try frontEnd()
        var now: UInt32 = 1000
        ticks(fe, now: &now) { $0.phase != .menu }
        let screen = KeyRecorder()
        fe.push([.screen(make: { screen }, then: { _ in [] })])
        _ = fe.tick(now: now, keys: HeldKeys(), mouse: Self.away)
        XCTAssertTrue(fe.activeScreen === screen)
        _ = fe.key(0x00, chars: "a", modifiers: KeyModifiers(), isRepeat: true)
        XCTAssertEqual(screen.keys, [], "event mask 0x800a: no autoKey")
        _ = fe.key(0x00, chars: "a", modifiers: KeyModifiers())
        XCTAssertEqual(screen.keys, ["a"])
    }
}
