@testable import BTXWinKit
import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import XCTest

/// W4.5: the driver with the real in-window chrome — the menu bar (W5), the dialogs (W6), the About panel, full
/// screen and layout-aware text — headless over the real data (HECTORKIT_DATA_BTX).
final class WinChromeIntegrationTests: XCTestCase {
    private let strip = WinCanvas.menuStripHeight

    // MARK: Helpers

    private func realDriver(backing: any BTXPrefsBacking = WinMemoryPrefs(),
                            output: any WinAudioOutput = SilentWinAudioOutput()) throws -> (WinGameDriver, ScriptedHost) {
        try WinTestData.driver(backing: backing, output: output, dialogs: nil)
    }

    private func toMenu(_ d: WinGameDriver, _ h: ScriptedHost) {
        XCTAssertTrue(WinTestData.run(d, h, limit: 2_000) { d.frontEnd.phase == .menu }, "main menu reached")
    }

    /// One loop iteration with `events` queued first.
    private func step(_ d: WinGameDriver, _ h: ScriptedHost, _ events: [WinEvent] = []) {
        h.injected += events
        d.step()
        h.input.advance()
    }

    /// A click at window-canvas (x, y): down in one iteration, up in the next.
    private func click(_ d: WinGameDriver, _ h: ScriptedHost, _ x: Int, _ y: Int) {
        step(d, h, [.mouseMoved(x: x, y: y), .mouseDown(x: x, y: y)])
        step(d, h, [.mouseUp(x: x, y: y)])
    }

    private func key(_ code: UInt16, _ chars: String = "", _ mods: WinModifiers = []) -> WinEvent {
        .keyDown(keyCode: code, characters: chars, modifiers: mods, isRepeat: false)
    }

    private func geometry(_ d: WinGameDriver) throws -> MenuGeometry {
        MenuBarView(text: try WinTestData.assets().text).geometry(for: d.menuBar, width: 640, height: 500)
    }

    /// Chooses row `row` of menu `menu` by click-release-click (sticky) — the way a mouse user picks an item.
    private func choose(_ d: WinGameDriver, _ h: ScriptedHost, menu: Int, row: Int) throws {
        let g = try geometry(d)
        let t = g.titles[menu]
        click(d, h, t.x + 4, 10)
        XCTAssertEqual(d.tracker.openMenu, menu)
        let r = g.dropdowns[menu].rows[row].frame
        click(d, h, r.x + 20, r.y + r.height / 2)
        XCTAssertFalse(d.tracker.isOpen)
    }

    private func system(_ d: WinGameDriver) throws -> DialogSystem { try XCTUnwrap(d.dialogs as? DialogSystem) }

    private func store(_ backing: any BTXPrefsBacking) throws -> BTXPrefsStore {
        BTXPrefsStore(backing: backing, legacyFileURL: nil,
                      factoryScores: try HighScoreTable.factory(from: WinTestData.assets().data))
    }

    private func scratchPrefsURL() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("btx-w45-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
        return dir.appendingPathComponent("Prefs.bin")
    }

    // MARK: Preferences (Ctrl+,) → DLOG 190 → Music → Save

    func testCtrlCommaOpensPreferencesMusicChangeIsSavedAndMarked() throws {
        let url = try scratchPrefsURL()
        let (d, h) = try realDriver(backing: WinPrefsFile(fileURL: url))
        toMenu(d, h)
        XCTAssertTrue(d.menuBar.musicChecked)
        step(d, h, [key(0x2B, ",", .command)])                         // Ctrl+, = ⌘,
        XCTAssertTrue(WinTestData.run(d, h, limit: 120) { d.dialogs.isShowing }, "DLOG 190 up")
        let s = try system(d)
        let dlg = try XCTUnwrap(s.frontDialog)
        XCTAssertEqual(dlg.template.id, 190)
        XCTAssertTrue(d.dialogs.isModal)
        XCTAssertEqual(d.clock, .none, "the game clocks stop under a modal dialog")
        XCTAssertTrue(d.dialogUp)
        XCTAssertFalse(d.menuBar.isEnabled(.always), "app-modal: the whole bar is disabled")
        let frozen = d.ticksNow()
        WinTestData.run(d, h, limit: 30)
        XCTAssertEqual(d.ticksNow(), frozen, "TickCount frozen while the dialog waits")
        // The dialog is drawn over the canvas, under the strip.
        let frame = try XCTUnwrap(h.lastFrame)
        XCTAssertEqual(frame.height, 500)
        XCTAssertEqual(frame.canvas[dlg.originX + 30, strip + dlg.originY + 30], 0xFFFF_FFFF, "the white dialog body")

        // Music popup (item 27) → "Off" (row 0), through the driver's mouse routing (window coordinates).
        let b = dlg.popupButtonRect(try XCTUnwrap(dlg.item(27)))
        let bx = dlg.originX + b.x + b.width / 2, by = strip + dlg.originY + b.y + b.height / 2
        step(d, h, [.mouseMoved(x: bx, y: by), .mouseDown(x: bx, y: by)])
        guard case .popup(let m) = dlg.tracking else { return XCTFail("the Music menu did not open") }
        let r = m.rows[0]
        let rx = dlg.originX + r.x + r.width / 2, ry = strip + dlg.originY + r.y + r.height / 2
        step(d, h, [.mouseMoved(x: rx, y: ry), .mouseUp(x: rx, y: ry)])
        XCTAssertEqual(dlg.value(27), 1)
        XCTAssertEqual(d.currentPrefs.musicVolume == 1, false, "live prefs reach the sound, not the front end yet")
        // Save (item 1).
        let save = s.centre(of: 1)
        click(d, h, save.x, save.y + strip)
        XCTAssertTrue(WinTestData.run(d, h, limit: 60) { !d.dialogs.isShowing }, "DLOG 190 closed")
        XCTAssertEqual(d.currentPrefs.musicVolume, 1)
        XCTAssertFalse(d.menuBar.musicChecked, "`_ResetOptionsMenu` after the dialog: Music unchecked")
        XCTAssertFalse(d.dialogUp)
        XCTAssertEqual(d.clock, .tick, "the clocks run again")
        XCTAssertEqual(d.cursor, .hand)
        // The prefs file has the change.
        let reread = try store(WinPrefsFile(fileURL: url)).load().prefs
        XCTAssertEqual(reread.musicVolume, 1)
    }

    // MARK: DLOG 1000 typed text

    func testHighScoreNameTypedThroughTheDriverWithLayoutText() throws {
        let (d, h) = try realDriver()
        toMenu(d, h)
        var answer: DialogSystem.Answer?
        // DLOG 1000 as `_CheckHiScore` opens it; the events come through the driver like any other.
        XCTAssertTrue(d.dialogs.present(.highScoreNameDialog(defaultName: "Player"), prefs: d.currentPrefs) {
            answer = $0
        })
        XCTAssertTrue(d.dialogs.isModal)
        step(d, h)
        XCTAssertTrue(h.textInput, "text input on while the name field has the focus")
        let dlg = try XCTUnwrap(try system(d).frontDialog)
        XCTAssertEqual(dlg.text(2), "Player")
        // A key paired with its layout text: the A key typing "é" (a French layout) replaces the selection.
        step(d, h, [key(0x00, "a"), .textInput("é")])
        XCTAssertEqual(dlg.text(2), "é")
        // Shift alone is a flagsChanged: nothing reaches the field.
        step(d, h, [key(0x38, "", .shift)])
        XCTAssertEqual(dlg.text(2), "é")
        // AltGr (Ctrl+Alt) + Q typing "@" (a German layout) types — it is not Ctrl+Q (Quit).
        step(d, h, [key(0x0C, "q", [.command, .option]), .textInput("@")])
        XCTAssertEqual(dlg.text(2), "é@")
        XCTAssertFalse(d.finished)
        XCTAssertFalse(d.quitPending)
        // No text event in the poll: the US layout from the key (B).
        step(d, h, [key(0x0B, "b")])
        XCTAssertEqual(dlg.text(2), "é@b")
        // Text with no key before it (a dead key's composition) types too.
        step(d, h, [.textInput("ü")])
        XCTAssertEqual(dlg.text(2), "é@bü")
        // Ctrl+Q under the dialog: the menu is disabled, the filter ignores it — no quit.
        step(d, h, [key(0x0C, "q", .command)])
        XCTAssertFalse(d.finished)
        XCTAssertEqual(dlg.text(2), "é@bü")
        // Delete, then Return: OK! flashes for 8 ticks (the driver's dialog tick), then the answer.
        step(d, h, [key(0x33, "\u{7F}")])
        step(d, h, [key(0x24, "\r")])
        XCTAssertNil(answer)
        XCTAssertTrue(WinTestData.run(d, h, limit: 30) { answer != nil }, "answered after the flash")
        XCTAssertEqual(answer, .highScoreName("é@b"))
        step(d, h)
        XCTAssertFalse(h.textInput, "text input off once the field is gone")
        XCTAssertEqual(h.textInputChanges, [true, false])
    }

    // MARK: About

    func testAboutFromTheMenuOpensThePanelAndItsCloseButtonCloses() throws {
        let (d, h) = try realDriver()
        toMenu(d, h)
        try choose(d, h, menu: 0, row: 0)                              // Bubble Trouble X ▸ About
        let about = try XCTUnwrap(d.about)
        XCTAssertEqual(d.cursor, .hand, "`_SetMyCCursor(200)`")
        XCTAssertFalse(d.dialogs.isShowing, "not a modal dialog: the game runs on")
        XCTAssertEqual(d.clock, .tick)
        let frame = try XCTUnwrap(h.lastFrame)
        XCTAssertEqual(frame.canvas[about.originX + 40, strip + about.originY + 40], 0xFFEC_ECEC, "the panel")
        // Keys are the panel's: Return does not reach the menu screen.
        let phase = d.frontEnd.phase
        step(d, h, [key(0x24, "\r")])
        XCTAssertEqual(d.frontEnd.phase, phase)
        XCTAssertNil(d.session)
        // The close button.
        click(d, h, about.originX + 14, strip + about.originY + 14)
        XCTAssertNil(d.about)
        // Esc closes it too.
        try choose(d, h, menu: 0, row: 0)
        XCTAssertNotNil(d.about)
        step(d, h, [key(0x35, "\u{1B}")])
        XCTAssertNil(d.about)
    }

    // MARK: Full screen

    func testFullScreenToggleSavedAndRestoredAtLaunch() throws {
        let backing = WinMemoryPrefs()
        let (d, h) = try realDriver(backing: backing)
        toMenu(d, h)
        XCTAssertEqual(h.lastFrame?.height, 500)
        step(d, h, [key(0x03, "f", .command)])                         // Ctrl+F
        XCTAssertTrue(h.fullScreen)
        XCTAssertTrue(d.isFullScreen)
        XCTAssertTrue(d.menuBar.fullScreenChecked)
        XCTAssertTrue(d.currentPrefs.fullScreen)
        XCTAssertEqual(h.lastFrame?.height, 480, "the strip hides in full screen: the game screen alone")
        XCTAssertTrue(try store(backing).load().prefs.fullScreen, "saved")
        // The strip is gone: a click at the top of the screen is the game's, not the bar's.
        click(d, h, 30, strip + 2)
        XCTAssertFalse(d.tracker.isOpen)

        // A new launch over the same prefs starts in full screen.
        let h2 = ScriptedHost()
        let d2 = try WinGameDriver(assets: WinTestData.assets(), host: h2, audioOutput: SilentWinAudioOutput(),
                                   prefsBacking: backing, options: .init(registeredName: "Player", today: { (3, 3) }))
        d2.start()
        XCTAssertTrue(h2.fullScreen)
        XCTAssertTrue(d2.isFullScreen)
        XCTAssertTrue(d2.menuBar.fullScreenChecked)
        XCTAssertEqual(h2.lastFrame?.height, 480)

        // Back to the window.
        step(d, h, [key(0x03, "f", .command)])
        XCTAssertFalse(h.fullScreen)
        XCTAssertFalse(d.currentPrefs.fullScreen)
        XCTAssertEqual(h.lastFrame?.height, 500)
        // A refused switch flips the pref back (the Mac's no-screen case).
        h.refuseFullScreen = true
        step(d, h, [key(0x03, "f", .command)])
        XCTAssertFalse(d.isFullScreen)
        XCTAssertFalse(d.menuBar.fullScreenChecked)
        XCTAssertFalse(d.currentPrefs.fullScreen)
        // `setFullScreen`'s return is the Mac's: true when the window is now as asked.
        h.refuseFullScreen = false
        XCTAssertTrue(d.setFullScreen(true))
        XCTAssertTrue(d.setFullScreen(false))
        h.refuseFullScreen = true
        XCTAssertFalse(d.setFullScreen(true))
    }

    // MARK: Menu clicks

    func testMenuClicksRunTheirCommands() throws {
        let backing = WinMemoryPrefs()
        let (d, h) = try realDriver(backing: backing)
        toMenu(d, h)
        let phase = d.frontEnd.phase
        // Options ▸ Music (row 3): off, unmarked, saved.
        try choose(d, h, menu: 2, row: 3)
        XCTAssertEqual(d.currentPrefs.musicVolume, 1)
        XCTAssertFalse(d.menuBar.musicChecked)
        XCTAssertEqual(try store(backing).load().prefs.musicVolume, 1)
        try choose(d, h, menu: 2, row: 3)
        XCTAssertNotEqual(d.currentPrefs.musicVolume, 1)
        XCTAssertTrue(d.menuBar.musicChecked)
        // Options ▸ Sound Effects (row 2) by its shortcut Ctrl+Shift+A.
        step(d, h, [key(0x00, "A", [.command, .shift])])
        XCTAssertEqual(d.currentPrefs.sfxVolume, 1)
        XCTAssertFalse(d.menuBar.soundChecked)
        // Window ▸ Minimize and Zoom go to the host.
        try choose(d, h, menu: 3, row: 0)
        XCTAssertEqual(h.minimizes, 1)
        try choose(d, h, menu: 3, row: 1)
        XCTAssertEqual(h.zooms, 1)
        // Edit is disabled: choosing Undo does nothing and the menu stays open (sticky).
        let g = try geometry(d)
        click(d, h, g.titles[1].x + 4, 10)
        let undo = g.dropdowns[1].rows[0].frame
        click(d, h, undo.x + 20, undo.y + 5)
        XCTAssertTrue(d.tracker.isOpen)
        // Keys go to the open menu: Esc closes it and never reaches the game.
        step(d, h, [key(0x35, "\u{1B}")])
        XCTAssertFalse(d.tracker.isOpen)
        XCTAssertEqual(d.frontEnd.phase, phase)
        // Alt held swaps the Window menu's alternates in the open menu.
        click(d, h, g.titles[3].x + 4, 10)
        step(d, h, [key(0x3A, "", .option)])
        XCTAssertTrue(d.tracker.optionHeld)
        step(d, h, [.keyUp(keyCode: 0x3A, modifiers: [])])
        XCTAssertFalse(d.tracker.optionHeld)
        step(d, h, [key(0x35, "\u{1B}")])
        // The bar is drawn in the strip.
        let frame = try XCTUnwrap(h.lastFrame)
        XCTAssertEqual(frame.canvas[639, 0], 0xFF00_0000 | MenuBarView.barColor)
        XCTAssertEqual(frame.canvas[639, 19], 0xFF00_0000 | MenuBarView.barLine)
    }

    func testMenusFollowThePlayState() throws {
        let (d, h) = try realDriver()
        toMenu(d, h)
        h.injected = [key(0x24, "\r")]                                 // New Game
        XCTAssertTrue(WinTestData.run(d, h, limit: 1_000) { d.session?.phase == .playing }, "game running")
        XCTAssertFalse(d.menuBar.isEnabled(.preferences), "Preferences off in play")
        XCTAssertFalse(d.menuBar.isEnabled(.playMenus), "Full Screen off in play")
        XCTAssertFalse(d.menuBar.isEnabled(.about), "About off in play")
        step(d, h, [key(0x2B, ",", .command)])                         // Ctrl+, in play: disabled → the game's key
        XCTAssertFalse(d.dialogs.isShowing)
    }

    // MARK: Quit with a dialog up

    func testQuitWhilePreferencesAreUpAtTheMenuSavesAndQuits() throws {
        let backing = WinMemoryPrefs()
        let (d, h) = try realDriver(backing: backing)
        toMenu(d, h)
        step(d, h, [key(0x2B, ",", .command)])
        XCTAssertTrue(WinTestData.run(d, h, limit: 120) { d.dialogs.isShowing })
        let writes = backing.writes.count
        step(d, h, [.quit])                                            // the window's close box
        XCTAssertTrue(d.finished)
        XCTAssertTrue(h.quitCalled)
        XCTAssertFalse(d.quitPending)
        XCTAssertGreaterThan(backing.writes.count, writes, "quit outside a game saves")
    }

    func testQuitWhilePausedWithPreferencesUpSavesAndQuits() throws {
        let backing = WinMemoryPrefs()
        let (d, h) = try realDriver(backing: backing)
        toMenu(d, h)
        h.injected = [key(0x24, "\r")]
        XCTAssertTrue(WinTestData.run(d, h, limit: 1_000) { d.session?.phase == .playing })
        h.input = WinGameDriverTests.inputAt(h.frame, script: "caps on")
        XCTAssertTrue(WinTestData.run(d, h, limit: 300) { d.session?.phase == .paused }, "paused")
        step(d, h, [key(0x2B, ",", .command)])                         // Preferences… while paused
        XCTAssertTrue(WinTestData.run(d, h, limit: 60) { d.dialogs.isShowing }, "DLOG 190 over the pause")
        let writes = backing.writes.count
        step(d, h, [.quit])
        XCTAssertTrue(d.finished, "`_PauseGame` case 0x17: quit now")
        XCTAssertFalse(d.quitPending)
        XCTAssertEqual(backing.writes.count, writes + 1, "with the save")
    }

    /// In play the close box waits on the game's own quit (⌘Q injected); a second close quits at once (the Mac's
    /// `replyPending` → `.terminateNow`), without saving (a running game).
    func testSecondCloseWhileTheGameQuitsTerminatesAtOnce() throws {
        let backing = WinMemoryPrefs()
        let (d, h) = try realDriver(backing: backing)
        toMenu(d, h)
        h.injected = [key(0x24, "\r")]
        XCTAssertTrue(WinTestData.run(d, h, limit: 1_000) { d.session?.phase == .wipe || d.session?.phase == .playing })
        let writes = backing.writes.count
        step(d, h, [.quit])
        XCTAssertTrue(d.quitPending || d.finished)
        if !d.finished {
            step(d, h, [.quit])
            XCTAssertTrue(d.finished)
        }
        XCTAssertFalse(d.quitPending)
        XCTAssertEqual(backing.writes.count, writes, "a running game's quit never saves")
    }
}
