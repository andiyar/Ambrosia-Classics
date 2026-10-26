import FerazelCore
import FerazelRender
@testable import FerazelWinKit
import Foundation
import XCTest

/// WF3 (D43 Rulings 8, 9, 20): the Windows game loop `WinGame` driven headless through the scripted host — no SDL, no
/// window, no audio device (the driver's silent mixer). Frames are the baked text's (WF2's reference FNVs); the loop
/// wakes 240 times a second and the flow runs once per new 60 Hz tick, so these pin that the loop adds nothing.
@MainActor final class WinGameTests: XCTestCase {
    /// A headless (`--frames`) game on the real data, in-memory prefs, the baked fonts, stub dialogs and panels.
    static func game(script: String = "", arguments: [String] = [], wallClock: (UInt32, UInt32) = (0x1111_1111, 77),
                     dialogs: any WinDialogs = WinStubDialogs(), boot: Bool = true) throws
        -> (WinGame, WinScriptedHost) {
        let args = try WinArgs.parse(["--frames", "100000"] + arguments, environment: [:])
        let host = WinScriptedHost(script: try WinKeyScript(text: script), wallClock: wallClock)
        let game = WinGame(args: args, host: host, text: try BakedTextTests.baked(),
                           files: WinFiles(prefsURL: nil, savesFolder: nil), dialogs: dialogs)
        if boot { try game.boot(dataDirectory: FerazelData.dataDirectory()) }
        return (game, host)
    }

    /// Loop iterations (one `step` + one 1/240 s of the scripted clock) until `until` holds after one; fails after `max`.
    @discardableResult
    static func run(_ game: WinGame, _ host: WinScriptedHost, max: Int = 40_000,
                    until: (WinGame) -> Bool) -> Int {
        for i in 1...max {
            game.step()
            host.advance()
            if until(game) { return i }
        }
        XCTFail("not reached in \(max) iterations (state \(game.flow.state))")
        return max
    }

    static func fnv(_ game: WinGame) throws -> String { hex(fnv1a64(try XCTUnwrap(game.lastPresented))) }

    // MARK: 1 · the main menu through the loop

    func testMainMenuThroughTheLoopIsWF2sFrame() throws {
        let (game, host) = try Self.game()
        let n = Self.run(game, host) { $0.flow.state == .mainMenu }
        XCTAssertEqual(game.flowSteps, FerazelDriverTests.bootTicks, "flow steps to the main menu")
        XCTAssertEqual(n, 4 * (FerazelDriverTests.bootTicks - 1) + 1, "240 Hz iterations to the main menu")
        XCTAssertEqual(try Self.fnv(game), hex(BakedTextTests.bakedMainMenuFNV), "main menu RGBA FNV")
        XCTAssertEqual(host.presented.last.map(fnv1a64), BakedTextTests.bakedMainMenuFNV, "the host got that frame")
        XCTAssertFalse(game.finished)
    }

    // MARK: 2 · 240 Hz wakes, one flow step per new tick, none while a dialog is up

    func testOneFlowStepPerNewTickAndNoneWhileModal() throws {
        let dialogs = HeldDialogs()
        let (game, host) = try Self.game(dialogs: dialogs)
        for _ in 0..<40 {
            game.step()
            host.advance()
        }
        XCTAssertEqual(game.flowSteps, 10, "40 wakes at 240 Hz = 10 ticks")
        XCTAssertEqual(game.lastTick, WinScriptedInput.baseTick + 9)
        dialogs.showing = true
        for _ in 0..<16 {
            game.step()
            host.advance()
        }
        XCTAssertEqual(game.flowSteps, 10, "the flow is held while a dialog is up")
        dialogs.showing = false
        for _ in 0..<8 {
            game.step()
            host.advance()
        }
        XCTAssertEqual(game.flowSteps, 12, "then once per new tick again, never catching up")
        // Two wakes inside one tick never step twice; a skipped tick steps once with the latest `now`.
        host.skip(iterations: 9)
        game.step()
        XCTAssertEqual(game.flowSteps, 13)
        game.step()
        XCTAssertEqual(game.flowSteps, 13)
    }

    // MARK: 9 · the window's close box / Alt+F4 = the Dock's Quit (D40)

    func testQuitEventIsSystemQuitAndALevelAsksFirst() throws {
        let dialogs = WinStubDialogs()
        let (game, host) = try Self.game(script: "1440 down n", dialogs: dialogs)
        Self.run(game, host) { $0.flow.padContext == .playing }
        let free = game.flowSteps
        Self.run(game, host) { $0.flowSteps == free + Self.settleSteps }   // past the level's opening
        XCTAssertEqual(game.flow.padContext, .playing)
        XCTAssertTrue(dialogs.shown.isEmpty)
        host.inject(.quit)
        let before = game.flowSteps
        Self.run(game, host) { $0.flowSteps == before + 1 }
        // Taken at the next tick: the level's ⌘Q confirm is pending for its next `.CheckGameLoopKeys`.
        let session = try XCTUnwrap(game.flow.levelRun?.session)
        XCTAssertTrue(session.systemQuitPending || session.suspension != nil, "the level took the quit")
        XCTAssertFalse(game.finished)
        Self.run(game, host) { _ in !dialogs.shown.isEmpty }
        XCTAssertEqual(game.flowSteps - before, Self.quitConfirmSteps, "the confirm at the level's next key check")
        XCTAssertEqual(dialogs.shown, [.confirm(text: "Are you sure you want to quit?")])
        // The stub answers Cancel: the level plays on, nothing quits. Ctrl+Q there (⌘Q in the polled keys) raises the
        // same confirm as soon — the close box is the level's own ⌘Q.
        Self.run(game, host) { $0.flow.padContext == .playing }
        XCTAssertFalse(game.finished)
        host.inject(.keyDown(keyCode: 0x37, modifiers: .command, isRepeat: false))
        host.inject(.keyDown(keyCode: 0x0C, modifiers: .command, isRepeat: false))
        let keyed = game.flowSteps
        Self.run(game, host) { _ in dialogs.shown.count == 2 }
        XCTAssertEqual(dialogs.shown.last, .confirm(text: "Are you sure you want to quit?"))
        XCTAssertEqual(game.flowSteps - keyed, Self.quitConfirmSteps, "as ⌘Q's")
    }

    /// Flow steps from the quit event to the confirm request (self-measured, WF3): the level takes the quit at the
    /// next tick and asks for the dialog at its next `.CheckGameLoopKeys`, as ⌘Q does. (Asked during the level's
    /// opening — `padContext` already reads `.playing` there — it waits for the first key check: 82 steps measured.)
    static let quitConfirmSteps = 2
    /// Steps run after the level first reads as playing, so its opening is over (WF3).
    static let settleSteps = 120

    // MARK: 10 · a quit before the flow exists ends at once

    func testQuitBeforeTheFlowExistsExitsZeroAtOnce() throws {
        let dialogs = WinStubDialogs()
        let (game, host) = try Self.game(dialogs: dialogs, boot: false)
        host.inject(.quit)
        game.step()
        XCTAssertTrue(game.finished)
        XCTAssertEqual(game.exitCode, 0)
        XCTAssertTrue(dialogs.shown.isEmpty, "no confirm")
        XCTAssertEqual(game.flowSteps, 0)
    }

    // MARK: 18 · New Game through a key script

    func testNewGameViaScriptReachesLevelOneWithWF2sFrames() throws {
        let (game, host) = try Self.game(script: "# N held from the first tick in the main menu\n1440 down n\n")
        Self.run(game, host) { $0.flow.state == .mainMenu }
        let menuSteps = game.flowSteps
        Self.run(game, host) { $0.flow.levelRun != nil && $0.lastOutput.present }
        XCTAssertEqual(game.flow.levelRun?.levelNumber, 1)
        XCTAssertEqual(game.flowSteps - menuSteps, FerazelDriverTests.newGameTicks, "N → level 1's first frame")
        XCTAssertEqual(try Self.fnv(game), hex(BakedTextTests.bakedLevelOneFNV), "level 1's first frame")
        let levelSteps = game.flowSteps
        Self.run(game, host) { $0.flowSteps == levelSteps + BakedTextTests.firstTextPresentTick }
        XCTAssertTrue(game.lastOutput.present)
        XCTAssertEqual(try Self.fnv(game), hex(BakedTextTests.bakedFirstTextPresentFNV), "the first frame with text")
    }

    // MARK: 19 · `--frames` determinism: both clocks pinned (Ruling 20)

    func testFramesRunsAreDeterministicAndSeedIsPinned() throws {
        var dumps: [String] = []
        var dates: [UInt32] = []
        for clock in [(UInt32(0x1111_1111), UInt32(77)), (0xDEAD_BEEF, 123_456)] {
            let (game, host) = try Self.game(script: "1440 down n", wallClock: clock)
            XCTAssertEqual(game.seedUsed, WinGame.headlessSeed)
            XCTAssertEqual(game.dateTimeNow(), WinGame.headlessDateTime)
            Self.run(game, host) { $0.flowSteps == 480 }
            XCTAssertEqual(game.flow.levelRun?.levelNumber, 1)
            dumps.append(hex(fnv1a64(WinGame.ppm(rgba: try XCTUnwrap(game.lastPresented)))))
            dates.append(game.dateTimeNow())
            XCTAssertEqual(host.wallClockReads, 0, "the host's wall clock is never read headless")
        }
        XCTAssertEqual(dumps[0], dumps[1], "same dump")
        XCTAssertEqual(dates, [WinGame.headlessDateTime + 479 / 60, WinGame.headlessDateTime + 479 / 60])
        // `--seed N` is the seed the flow gets.
        let (seeded, _) = try Self.game(arguments: ["--seed", "7"])
        XCTAssertEqual(seeded.seedUsed, 7)
        XCTAssertEqual(seeded.flow.rng.seed, 7)
        let (pinned, _) = try Self.game()
        XCTAssertEqual(pinned.flow.rng.seed, Rig.seed, "default = WF1's test seed")
    }
}

/// A dialog that stays up until the test takes it down (`showing`).
@MainActor final class HeldDialogs: WinDialogs {
    var showing = false
    var isShowing: Bool { showing }
    func show(_ dialog: FerazelDialog, done: @escaping (DialogResult) -> Void) { done(.cancel) }
    func keyDown(_ keyCode: UInt16, modifiers: WinModifiers) {}
    func padKeyDown(_ keyCode: UInt16) {}
}
