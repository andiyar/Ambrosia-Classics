import BTXWinKit
import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import HectorInput
import XCTest

/// The gamepad on Windows (Classics D36, HectorKit D16, gamepad plan W1): the driver reads an injected pad source,
/// maps it with the shared `BTXPadLayout` and merges it with the keyboard as the original keys — over the real data
/// (HECTORKIT_DATA_BTX) and a fake pad.
final class WinGamepadTests: XCTestCase {
    /// The buttons held now; the driver reads them through `state`.
    final class FakePad {
        var buttons: Set<ShellPadButton> = []
        /// Runs (once) at the next read, before the state is returned — a pad edge's consequence mid-step.
        var onRead: (() -> Void)?
        var state: ShellPadState {
            if let f = onRead {
                onRead = nil
                f()
            }
            return ShellPadState(buttons: buttons)
        }
    }

    /// Dialogs that stay up once asked for (modal) and count their ticks — nothing drawn, no answers.
    final class StuckDialogs: WinDialogs {
        weak var delegate: DialogSystemDelegate?
        private(set) var isShowing = false
        var isModal: Bool { isShowing }
        var wantsTextInput: Bool { false }
        var drawKey: Int { isShowing ? 1 : 0 }
        private(set) var ticks = 0
        @discardableResult
        func present(_ request: ShellRequest, prefs: BTXPrefs,
                     completion: @escaping (DialogSystem.Answer) -> Void) -> Bool {
            isShowing = true
            delegate?.dialogModalStateChanged()
            return true
        }
        func close() {}
        func mouseDown(x: Int, y: Int) {}
        func mouseMoved(x: Int, y: Int) {}
        func mouseUp(x: Int, y: Int) {}
        func keyDown(_ event: DialogKeyEvent) {}
        func tick(heldKeys: Set<UInt16>) { ticks += 1 }
        func draw(into image: inout RGBAImage, canvasX: Int, canvasY: Int) {}
    }

    private static let returnKey: UInt16 = 0x24, escapeKey: UInt16 = 0x35
    private static let leftArrow: UInt16 = 0x7B, rightArrow: UInt16 = 0x7C

    private func driver(dialogs: (any WinDialogs)? = WinAutoDialogs())
        throws -> (WinGameDriver, ScriptedHost, FakePad) {
        let pad = FakePad()
        let (d, h) = try WinTestData.driver(dialogs: dialogs, padSource: { pad.state })
        return (d, h, pad)
    }

    private func toMenu(_ d: WinGameDriver, _ h: ScriptedHost) {
        XCTAssertTrue(WinTestData.run(d, h, limit: 2_000) { d.frontEnd.phase == .menu }, "main menu reached")
    }

    /// A letter key set (J L I K, push Space) made current: on the menu L is level select, so a d-pad that sent the
    /// set's keys there would open a dialog.
    private func useLetterKeySet(_ d: WinGameDriver) -> KeySet {
        var p = d.currentPrefs
        let set = KeySet(name: "Letters", left: 0x26, right: 0x25, up: 0x22, down: 0x28, push: 0x31)
        p.setKeySet(p.currentKeySetIndex, set)
        d.shortcutChangedPrefs(p)
        return set
    }

    private func steps(_ d: WinGameDriver, _ h: ScriptedHost, _ n: Int) {
        WinTestData.run(d, h, limit: n)
    }

    /// From the menu, a face button (Return → New Game) starts a game; runs until its frames run, then releases it.
    private func startGameWithPad(_ d: WinGameDriver, _ h: ScriptedHost, _ pad: FakePad) {
        toMenu(d, h)
        pad.buttons = [.south]
        XCTAssertTrue(WinTestData.run(d, h, limit: 1_000) {
            d.session?.mode == .play && d.session?.phase == .playing
        }, "game running")
        pad.buttons = []
        steps(d, h, 4)
    }

    // MARK: Outside play

    func testDPadOnTheMenuIsTheArrowsNotTheKeySet() throws {
        let (d, h, pad) = try driver(dialogs: nil)                     // the real in-window dialogs
        toMenu(d, h)
        _ = useLetterKeySet(d)
        pad.buttons = [.right]
        steps(d, h, 10)
        XCTAssertEqual(d.padFrame.held, [Self.rightArrow])
        XCTAssertFalse(d.dialogs.isShowing, "L (the set's right) would have opened level select")
        XCTAssertEqual(d.frontEnd.phase, .menu)
        pad.buttons = [.left]
        steps(d, h, 4)
        XCTAssertEqual(d.padFrame.held, [Self.leftArrow])
        pad.buttons = []
        steps(d, h, 2)
        XCTAssertEqual(d.padFrame.held, [])
        XCTAssertFalse(d.dialogs.isShowing)
        XCTAssertNil(d.session)
    }

    func testPadReturnAndEscapeReachADialog() throws {
        let (d, h, pad) = try driver(dialogs: nil)
        toMenu(d, h)
        func openLevelSelect() {
            h.injected = [.keyDown(keyCode: 0x25, characters: "l", modifiers: [], isRepeat: false),
                          .keyUp(keyCode: 0x25, modifiers: [])]
            XCTAssertTrue(WinTestData.run(d, h, limit: 300) { d.dialogs.isModal }, "level select up")
            XCTAssertEqual(d.clock, .none, "the game clocks stop under the dialog")
        }
        openLevelSelect()
        // The d-pad does nothing in a dialog (only Return and Esc reach it).
        pad.buttons = [.down]
        steps(d, h, 6)
        pad.buttons = []
        steps(d, h, 2)
        XCTAssertTrue(d.dialogs.isModal)
        // − is Esc there: Cancel.
        pad.buttons = [.back]
        XCTAssertTrue(WinTestData.run(d, h, limit: 60) { !d.dialogs.isShowing }, "Esc cancelled the dialog")
        pad.buttons = []
        steps(d, h, 4)
        XCTAssertEqual(d.frontEnd.phase, .menu)

        openLevelSelect()
        pad.buttons = [.north]                                          // any face button is Return: OK
        XCTAssertTrue(WinTestData.run(d, h, limit: 60) { !d.dialogs.isModal }, "Return answered the dialog")
        pad.buttons = []
    }

    // MARK: Play

    func testFaceButtonHeldIntoPlayIsIgnoredUntilReleasedThenPushes() throws {
        let (d, h, pad) = try driver()
        toMenu(d, h)
        let set = d.currentPrefs.currentKeySet
        pad.buttons = [.south]
        XCTAssertTrue(WinTestData.run(d, h, limit: 1_000) { d.session?.phase == .playing }, "Return started a game")
        XCTAssertEqual(d.padFrame.held, [], "held across Return → push: ignored until released")
        pad.buttons = []
        steps(d, h, 4)
        pad.buttons = [.east]
        steps(d, h, 4)
        XCTAssertEqual(d.padFrame.held, [set.push])
    }

    func testDPadAndStickAreTheKeySetInPlay() throws {
        let (d, h, pad) = try driver()
        startGameWithPad(d, h, pad)
        let set = d.currentPrefs.currentKeySet
        let x0 = try XCTUnwrap(d.session).state.hero.rect.left
        pad.buttons = [.right]
        steps(d, h, 4)
        XCTAssertEqual(d.padFrame.held, [set.right])
        XCTAssertTrue(WinTestData.run(d, h, limit: 600) { (d.session?.state.hero.rect.left ?? x0) > x0 },
                      "the hero walked right (once the level's intro lets him)")
        XCTAssertEqual(d.padFrame.held, [set.right])
        pad.buttons = [.up]
        steps(d, h, 4)
        XCTAssertEqual(d.padFrame.held, [set.up])
        pad.buttons = []
        steps(d, h, 4)
        XCTAssertEqual(d.padFrame.held, [])
    }

    func testStartLatchesThePauseAsCapsLock() throws {
        let (d, h, pad) = try driver()
        startGameWithPad(d, h, pad)
        pad.buttons = [.start]
        steps(d, h, 4)
        pad.buttons = []
        XCTAssertTrue(d.padFrame.capsLock)
        XCTAssertTrue(WinTestData.run(d, h, limit: 300) { d.session?.phase == .paused }, "paused")
        steps(d, h, 30)
        XCTAssertEqual(d.session?.phase, .paused, "a latch, not a held key: the pause stays")
        pad.buttons = [.start]
        steps(d, h, 4)
        pad.buttons = []
        XCTAssertFalse(d.padFrame.capsLock)
        XCTAssertTrue(WinTestData.run(d, h, limit: 300) { d.session?.phase == .playing }, "unpaused")
    }

    func testBackIsEscapeOnlyAfterAOneSecondHold() throws {
        let (d, h, pad) = try driver()
        startGameWithPad(d, h, pad)
        pad.buttons = [.back]
        steps(d, h, 30)                                                 // ½ s
        XCTAssertEqual(d.padFrame.held, [])
        XCTAssertEqual(d.session?.phase, .playing)
        steps(d, h, 32)                                                 // past 1 s
        XCTAssertEqual(d.padFrame.held, [Self.escapeKey])
        XCTAssertTrue(WinTestData.run(d, h, limit: 600) { d.session.map { !$0.isInGame } ?? true },
                      "Esc ended the game")
        pad.buttons = []
    }

    func testFocusLostReleasesThePadAndAButtonHeldOnReturnWaitsForRelease() throws {
        let (d, h, pad) = try driver()
        startGameWithPad(d, h, pad)
        let set = d.currentPrefs.currentKeySet
        pad.buttons = [.right]
        steps(d, h, 4)
        XCTAssertEqual(d.padFrame.held, [set.right])
        h.injected = [.focusLost]
        steps(d, h, 6)
        XCTAssertEqual(d.padFrame.held, [], "inactive: the pad reads as nothing")
        h.injected = [.focusGained]
        steps(d, h, 6)
        XCTAssertEqual(d.padFrame.held, [], "held across the inactive stretch: ignored until released")
        pad.buttons = []
        steps(d, h, 4)
        pad.buttons = [.right]
        steps(d, h, 4)
        XCTAssertEqual(d.padFrame.held, [set.right])
    }

    func testThePauseLatchSurvivesADialogAndOnlyPlusUnpauses() throws {
        let (d, h, pad) = try driver(dialogs: nil)                     // the real in-window dialogs
        startGameWithPad(d, h, pad)
        pad.buttons = [.start]
        XCTAssertTrue(WinTestData.run(d, h, limit: 300) { d.session?.phase == .paused }, "paused")
        pad.buttons = []
        steps(d, h, 4)
        d.preferencesChosen()                                           // the pause loop opens DLOG 190
        XCTAssertTrue(d.dialogs.isModal, "prefs up over the pause")
        // The mapping changed under the dialog (face buttons are Return), but + stays the latch: the pause holds.
        steps(d, h, 30)
        XCTAssertTrue(d.padFrame.capsLock, "the latch survives the dialog")
        XCTAssertTrue(d.dialogs.isModal)
        pad.buttons = [.back]                                           // Esc: Cancel
        XCTAssertTrue(WinTestData.run(d, h, limit: 120) { !d.dialogs.isShowing }, "Esc closed the prefs")
        pad.buttons = []
        steps(d, h, 30)
        XCTAssertEqual(d.session?.phase, .paused, "still paused after the dialog")
        XCTAssertTrue(d.padFrame.capsLock)
        pad.buttons = [.start]
        steps(d, h, 4)
        pad.buttons = []
        XCTAssertTrue(WinTestData.run(d, h, limit: 300) { d.session?.phase == .playing }, "+ unpaused")
    }

    func testKeyboardAndPadHoldingTheSameKeyReleaseIndependently() throws {
        let (d, h, pad) = try driver()
        startGameWithPad(d, h, pad)
        let right = d.currentPrefs.currentKeySet.right
        func held() -> Bool { d.lastHeldKeys.codes.contains(right) }
        h.injected = [.keyDown(keyCode: right, characters: "", modifiers: [], isRepeat: false)]
        pad.buttons = [.right]
        steps(d, h, 6)
        XCTAssertTrue(held())
        h.injected = [.keyUp(keyCode: right, modifiers: [])]            // the keyboard lets go: the pad still holds
        steps(d, h, 6)
        XCTAssertTrue(held())
        h.injected = [.keyDown(keyCode: right, characters: "", modifiers: [], isRepeat: false)]
        pad.buttons = []                                                // the pad lets go: the keyboard still holds
        steps(d, h, 6)
        XCTAssertTrue(held())
        XCTAssertEqual(d.padFrame.held, [])
        h.injected = [.keyUp(keyCode: right, modifiers: [])]
        steps(d, h, 6)
        XCTAssertFalse(held(), "both released: up")
    }

    // MARK: A pad read that ends the driver mid-step: the rest of the step does not run

    func testAFrameFireStopsWhenThePadReadFinishesTheDriver() throws {
        let (d, h, pad) = try driver()
        startGameWithPad(d, h, pad)
        XCTAssertEqual(d.clock, .frame)
        let session = try XCTUnwrap(d.session)
        let frame = session.state.frame
        var frames = 0
        d.frameObserver = { _ in frames += 1 }
        pad.onRead = { [unowned d] in
            d.handleEvent(.quit)                                        // in play: waits on the game's own quit
            d.handleEvent(.quit)                                        // a second close: terminate now
        }
        XCTAssertTrue(WinTestData.run(d, h, limit: 10) { d.finished })
        XCTAssertEqual(frames, 0, "no frame ran after the driver finished")
        XCTAssertEqual(session.state.frame, frame)
    }

    func testATickFireStopsWhenThePadReadFinishesTheDriver() throws {
        let (d, h, pad) = try driver()
        WinTestData.run(d, h, limit: 30)
        XCTAssertEqual(d.frontEnd.phase, .splash)
        XCTAssertEqual(d.clock, .tick)
        let presents = h.presents
        pad.onRead = { [unowned d] in d.handleEvent(.quit) }            // the splash: terminate at once
        XCTAssertTrue(WinTestData.run(d, h, limit: 10) { d.finished })
        XCTAssertEqual(h.presents, presents, "the tick's output was never handled")
    }

    func testADialogTickStopsWhenThePadReadFinishesTheDriver() throws {
        let dialogs = StuckDialogs()
        let (d, h, pad) = try driver(dialogs: dialogs)
        toMenu(d, h)
        h.injected = [.keyDown(keyCode: 0x25, characters: "l", modifiers: [], isRepeat: false)]   // level select
        XCTAssertTrue(WinTestData.run(d, h, limit: 300) { dialogs.isModal })
        steps(d, h, 4)
        XCTAssertGreaterThan(dialogs.ticks, 0)
        XCTAssertEqual(d.clock, .none)
        let ticks = dialogs.ticks
        pad.onRead = { [unowned d] in d.handleEvent(.quit) }            // a dialog up: terminate at once
        XCTAssertTrue(WinTestData.run(d, h, limit: 10) { d.finished })
        XCTAssertEqual(dialogs.ticks, ticks, "the dialog tick after the pad poll did not run")
    }

    /// No pad source (headless runs, the existing tests): the pad is never read.
    func testNoPadSourceMeansNoPad() throws {
        let (d, h) = try WinTestData.driver()
        toMenu(d, h)
        XCTAssertEqual(d.padFrame, ShellPadFrame())
    }
}
