import BTXWinKit
import BubbleTroubleCore
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
        var state: ShellPadState { ShellPadState(buttons: buttons) }
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

    /// No pad source (headless runs, the existing tests): the pad is never read.
    func testNoPadSourceMeansNoPad() throws {
        let (d, h) = try WinTestData.driver()
        toMenu(d, h)
        XCTAssertEqual(d.padFrame, ShellPadFrame())
    }
}
