import BTXWinKit
import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import XCTest

/// `WinGameDriver` headless over the real data (HECTORKIT_DATA_BTX): splash → main menu → attract demo 1, the demo
/// against `btx-replay`'s FILM 1, reproducible frames, the quit rules, the clocks, the sound and the cursor.
final class WinGameDriverTests: XCTestCase {
    /// The game-state trace line both sides print: the `btx-replay --trace` fields read from `GameState`.
    static func traceLine(_ s: GameState) -> String {
        "frame=\(s.frame) total=\(s.rng.drawCount) hero=\(s.hero.state)@\(s.hero.col),\(s.hero.row) "
            + "rect=\(s.hero.rect.left),\(s.hero.rect.top) score=\(s.score) lives=\(s.lives) "
            + "enemies=\(s.numEnemiesActive) balloons=\(s.numActiveBalloons) blocks=\(s.numActiveBlocks)"
    }

    private func toMenu(_ d: WinGameDriver, _ h: ScriptedHost) {
        XCTAssertTrue(WinTestData.run(d, h, limit: 2_000) { d.frontEnd.phase == .menu }, "main menu reached")
    }

    // MARK: Splash → menu → demo 1 = FILM 1

    func testSplashMenuAndAttractDemoOneMatchesFilmReplay() throws {
        let (d, h) = try WinTestData.driver()
        XCTAssertEqual(d.frontEnd.phase, .splash)
        XCTAssertEqual(d.clock, .tick)
        toMenu(d, h)
        XCTAssertEqual(d.clock, .tick, "the menu runs on TickCount")
        let menuAt = h.frame
        var lines: [String] = []
        var lastFrame: UInt16?
        d.frameObserver = { s in
            guard s.mode == .demo, s.state.frame != lastFrame else { return }
            lastFrame = s.state.frame
            lines.append(Self.traceLine(s.state))
        }
        // Idle 0x4b0 ticks → the first attract is the demo (FILM 1).
        XCTAssertTrue(WinTestData.run(d, h, limit: 3_000) { d.session?.mode == .demo && d.clock == .frame },
                      "attract demo started")
        XCTAssertGreaterThan(h.frame - menuAt, 0x4b0 - 60, "≈ 20 s idle (counted from the loop's own start)")
        XCTAssertTrue(WinTestData.run(d, h, limit: 20_000) { d.session == nil && !lines.isEmpty }, "demo ended")
        XCTAssertEqual(d.clock, .tick)

        let data = try WinTestData.assets().data
        var expected: [String] = []
        let replay = try FilmReplay.run(filmID: 1, files: data.levels) { _, s in expected.append(Self.traceLine(s)) }
        XCTAssertGreaterThan(expected.count, 100)
        XCTAssertEqual(lines.count, expected.count)
        if let i = (0..<min(lines.count, expected.count)).first(where: { lines[$0] != expected[$0] }) {
            XCTFail("first difference at demo frame \(i + 1):\n  driver \(lines[i])\n  replay \(expected[i])")
        }
        XCTAssertEqual(lines.last, expected.last)
        XCTAssertEqual(replay.frames, expected.count)
    }

    // MARK: Reproducible frames

    func testFrameDumpsAreReproducible() throws {
        func run() throws -> [Int: [UInt8]] {
            let (d, h) = try WinTestData.driver()
            var dumps: [Int: [UInt8]] = [:]
            for i in 1...600 {
                d.step()
                h.input.advance()
                if [120, 300, 600].contains(i) { dumps[i] = d.currentFrame.rgba }
            }
            return dumps
        }
        let a = try run(), b = try run()
        XCTAssertEqual(a.keys.sorted(), [120, 300, 600])
        for k in a.keys.sorted() { XCTAssertTrue(a[k] == b[k], "frame \(k) differs between runs") }
        XCTAssertFalse(a[120] == a[600], "the screen moved on")
    }

    // MARK: Quit rules

    /// Idle main menu: `_SaveGamePrefs`, the title music's blocking fade, then the front end's `.quit` (saving again).
    func testQuitAtIdleMenuSavesFadesThenQuits() throws {
        let out = RecordingAudioOutput()
        let (d, h) = try WinTestData.driver(output: out)
        toMenu(d, h)
        let saves = d.saveCount
        out.calls = []
        h.injected = [.keyDown(keyCode: 0x0C, characters: "q", modifiers: .command, isRepeat: false)]   // Ctrl+Q
        d.step()
        XCTAssertFalse(d.finished, "the fade runs first")
        XCTAssertEqual(d.saveCount, saves + 1)
        XCTAssertTrue(WinTestData.run(d, h, limit: 600) { d.finished })
        XCTAssertTrue(h.quitCalled)
        XCTAssertEqual(d.saveCount, saves + 2, "`_main` saves again")
        let volumes = out.calls.compactMap { if case let .setVolume(4, v) = $0 { v } else { nil } }
        XCTAssertGreaterThan(volumes.count, 10, "faded on the music voice")
        XCTAssertEqual(out.calls.last, .stop(4))
        XCTAssertEqual(d.clock, .none)
    }

    /// Anything but the idle menu outside a game (the splash): terminate now, prefs saved.
    func testWindowCloseDuringSplashQuitsAtOnceWithSave() throws {
        let (d, h) = try WinTestData.driver()
        WinTestData.run(d, h, limit: 30)
        XCTAssertEqual(d.frontEnd.phase, .splash)
        let saves = d.saveCount
        h.injected = [.quit]
        d.step()
        XCTAssertTrue(d.finished)
        XCTAssertTrue(h.quitCalled)
        // As on the Mac: `quitThroughFrontEnd` saves before finding the front end busy, then terminate saves.
        XCTAssertEqual(d.saveCount, saves + 2)
    }

    /// Starts a game from the menu (Return → New Game) and runs until its frames run.
    private func startGame(_ d: WinGameDriver, _ h: ScriptedHost) {
        toMenu(d, h)
        h.injected = [.keyDown(keyCode: 0x24, characters: "\r", modifiers: [], isRepeat: false)]
        XCTAssertTrue(WinTestData.run(d, h, limit: 1_000) {
            d.session?.mode == .play && d.session?.phase == .playing
        }, "game running")
        XCTAssertEqual(d.clock, .frame)
    }

    /// In play: ⌘ + 0x0C injected into the frames → the game's own quit (`.quitNow`) — no save.
    func testCtrlQInPlayInjectsCommandQAndQuitsWithoutSaving() throws {
        let backing = WinMemoryPrefs()
        let (d, h) = try WinTestData.driver(backing: backing)
        startGame(d, h)
        let writes = backing.writes.count
        h.injected = [.keyDown(keyCode: 0x0C, characters: "q", modifiers: .command, isRepeat: false)]
        d.step()
        XCTAssertTrue(d.quitPending)
        XCTAssertFalse(d.finished)
        XCTAssertTrue(WinTestData.run(d, h, limit: 600) { d.finished })
        XCTAssertTrue(h.quitCalled)
        XCTAssertEqual(backing.writes.count, writes, "`_CleanUp` never saves")
        XCTAssertTrue(h.cursorVisible, "the cursor comes back on quit")
    }

    /// Paused (Caps Lock): `_PauseGame` case 0x17 — quit now WITH the save.
    func testQuitWhilePausedSaves() throws {
        let backing = WinMemoryPrefs()
        let (d, h) = try WinTestData.driver(backing: backing)
        startGame(d, h)
        h.input = Self.inputAt(h.frame, script: "caps on")             // Caps Lock is the pause key (polled)
        XCTAssertTrue(WinTestData.run(d, h, limit: 300) { d.session?.phase == .paused }, "paused")
        let writes = backing.writes.count
        d.quitChosen()
        XCTAssertTrue(d.finished)
        XCTAssertEqual(backing.writes.count, writes + 1)
    }

    /// A scripted input positioned at `frame` whose script runs `command` there.
    static func inputAt(_ frame: Int, script command: String) -> WinScriptedInput {
        var input = WinScriptedInput(script: try! WinKeyScript(text: "\(frame) \(command)"))
        for _ in 0..<frame { input.advance() }
        return input
    }

    // MARK: Sound, cursor, menus

    func testTitleMusicAndGameCues() throws {
        let out = RecordingAudioOutput()
        out.playsLast = false
        let (d, h) = try WinTestData.driver(output: out)
        toMenu(d, h)
        let title = try XCTUnwrap(d.audio.musicID, "title music loaded")
        XCTAssertEqual(title, try WinTestData.assets().data.titleMusicResourceID())
        XCTAssertTrue(out.calls.contains { if case .play(title, 4, _, 50) = $0 { true } else { false } },
                      "title music started on the music voice, 50 loops")
        out.calls = []
        startGame(d, h)
        XCTAssertTrue(out.calls.contains(.play(id: 9002, voice: 0, volume: 0x80, loops: 1)), "Get Ready! (snd 9002)")
        XCTAssertFalse(d.playMenusEnabled, "Preferences / Full Screen off in play")
        XCTAssertFalse(h.cursorVisible, "cursor hidden in play")
        XCTAssertTrue(h.captured, "mouse captured once frames run")
    }
}
