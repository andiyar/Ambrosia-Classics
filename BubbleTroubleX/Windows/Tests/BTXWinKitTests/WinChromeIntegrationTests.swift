@testable import BTXWinKit
import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import XCTest

/// W4.5 + D21: the driver with the real in-window chrome — the dialogs (W6), the Ctrl shortcuts (no menu bar), full
/// screen and layout-aware text — headless over the real data (HECTORKIT_DATA_BTX). The canvas is the 640×480 game
/// screen, windowed and in full screen.
final class WinChromeIntegrationTests: XCTestCase {
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

    /// A click at canvas (x, y): down in one iteration, up in the next.
    private func click(_ d: WinGameDriver, _ h: ScriptedHost, _ x: Int, _ y: Int) {
        step(d, h, [.mouseMoved(x: x, y: y), .mouseDown(x: x, y: y)])
        step(d, h, [.mouseUp(x: x, y: y)])
    }

    private func key(_ code: UInt16, _ chars: String = "", _ mods: WinModifiers = []) -> WinEvent {
        .keyDown(keyCode: code, characters: chars, modifiers: mods, isRepeat: false)
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
        XCTAssertNotEqual(d.currentPrefs.musicVolume, 1)
        step(d, h, [key(0x2B, ",", .command)])                         // Ctrl+, = ⌘,
        XCTAssertTrue(WinTestData.run(d, h, limit: 120) { d.dialogs.isShowing }, "DLOG 190 up")
        let s = try system(d)
        let dlg = try XCTUnwrap(s.frontDialog)
        XCTAssertEqual(dlg.template.id, 190)
        XCTAssertTrue(d.dialogs.isModal)
        XCTAssertEqual(d.clock, .none, "the game clocks stop under a modal dialog")
        XCTAssertTrue(d.dialogUp)
        XCTAssertFalse(d.shortcuts.isEnabled(.always), "app-modal: every shortcut is off")
        let frozen = d.ticksNow()
        WinTestData.run(d, h, limit: 30)
        XCTAssertEqual(d.ticksNow(), frozen, "TickCount frozen while the dialog waits")
        // The dialog is drawn over the 640×480 canvas, centred (`alertPositionParentWindowScreen`).
        let frame = try XCTUnwrap(h.lastFrame)
        XCTAssertEqual(frame.width, 640)
        XCTAssertEqual(frame.height, 480)
        XCTAssertEqual(dlg.originX, (640 - dlg.template.width + 1) / 2, "horizontally centred")
        XCTAssertEqual(dlg.originY, Int((Double(480 - dlg.template.height) / 3).rounded()), "a third of the free height above")
        XCTAssertEqual(frame.canvas[dlg.originX + 30, dlg.originY + 30], 0xFFFF_FFFF, "the white dialog body")
        // The Ctrl shortcuts are off under it: Full Screen, Music and Quit do nothing.
        let before = d.currentPrefs
        step(d, h, [key(0x03, "f", .command)])
        step(d, h, [key(0x2E, "m", .command)])
        XCTAssertFalse(d.isFullScreen)
        XCTAssertEqual(d.currentPrefs, before)
        XCTAssertTrue(d.dialogs.isShowing)

        // Music popup (item 27) → "Off" (row 0), through the driver's mouse routing (window coordinates).
        let b = dlg.popupButtonRect(try XCTUnwrap(dlg.item(27)))
        let bx = dlg.originX + b.x + b.width / 2, by = dlg.originY + b.y + b.height / 2
        step(d, h, [.mouseMoved(x: bx, y: by), .mouseDown(x: bx, y: by)])
        guard case .popup(let m) = dlg.tracking else { return XCTFail("the Music menu did not open") }
        let r = m.rows[0]
        let rx = dlg.originX + r.x + r.width / 2, ry = dlg.originY + r.y + r.height / 2
        step(d, h, [.mouseMoved(x: rx, y: ry), .mouseUp(x: rx, y: ry)])
        XCTAssertEqual(dlg.value(27), 1)
        XCTAssertEqual(d.currentPrefs.musicVolume == 1, false, "live prefs reach the sound, not the front end yet")
        // Save (item 1).
        let save = s.centre(of: 1)
        click(d, h, save.x, save.y)
        XCTAssertTrue(WinTestData.run(d, h, limit: 60) { !d.dialogs.isShowing }, "DLOG 190 closed")
        XCTAssertEqual(d.currentPrefs.musicVolume, 1)
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
        // While text input is on, a key without its text in the poll types nothing itself — no US-layout fallback;
        // its text arriving in the next poll is typed once (B).
        step(d, h, [key(0x0B, "b")])
        XCTAssertEqual(dlg.text(2), "é@")
        step(d, h, [.textInput("b")])
        XCTAssertEqual(dlg.text(2), "é@b")
        // A dead key (´ on the ' key) types nothing; the composed "é" that follows the next key is typed once.
        step(d, h, [key(0x27, "'")])
        XCTAssertEqual(dlg.text(2), "é@b")
        step(d, h, [key(0x0E, "e"), .textInput("é")])
        XCTAssertEqual(dlg.text(2), "é@bé")
        // AltGr whose text comes a poll later: the key alone does nothing, the text types.
        step(d, h, [key(0x0C, "q", [.command, .option])])
        XCTAssertEqual(dlg.text(2), "é@bé")
        XCTAssertFalse(d.finished)
        step(d, h, [.textInput("ü")])
        XCTAssertEqual(dlg.text(2), "é@béü")
        // Ctrl+Q under the dialog: the shortcut is off, the filter ignores it — no quit.
        step(d, h, [key(0x0C, "q", .command)])
        XCTAssertFalse(d.finished)
        XCTAssertEqual(dlg.text(2), "é@béü")
        // Delete, then Return: OK! flashes for 8 ticks (the driver's dialog tick), then the answer.
        step(d, h, [key(0x33, "\u{7F}")])
        step(d, h, [key(0x24, "\r")])
        XCTAssertNil(answer)
        XCTAssertTrue(WinTestData.run(d, h, limit: 30) { answer != nil }, "answered after the flash")
        XCTAssertEqual(answer, .highScoreName("é@bé"))
        step(d, h)
        XCTAssertFalse(h.textInput, "text input off once the field is gone")
        XCTAssertEqual(h.textInputChanges, [true, false])
    }

    // MARK: Live move / resize (Windows' modal loop)

    func testLiveStepKeepsTheGameRunningWhileThePollIsBlocked() throws {
        let (d, h) = try realDriver()
        toMenu(d, h)
        step(d, h, [key(0x24, "\r")])                                  // Return: a game
        XCTAssertTrue(WinTestData.run(d, h, limit: 600) { d.clock == .frame }, "frames run")
        var frames = 0
        d.frameObserver = { _ in frames += 1 }
        // Outside a poll, liveStep does nothing (the driver could be mid-event).
        for _ in 0..<4 { h.input.advance() }
        d.liveStep()
        XCTAssertEqual(frames, 0)
        // A poll blocked for 60 TickCounts (one second of dragging): the live exposes keep the 0.033 s clock firing.
        let presents = h.presents
        h.duringPoll = { [unowned h] in
            h.duringPoll = nil
            for _ in 0..<60 {
                h.input.advance()
                d.liveStep()
            }
        }
        step(d, h)
        XCTAssertGreaterThanOrEqual(frames, 29, "≈ 30 frames in the second")
        XCTAssertLessThanOrEqual(frames, 31)
        XCTAssertGreaterThan(h.presents, presents)
    }

    // MARK: Full screen

    func testFullScreenToggleSavedAndRestoredAtLaunch() throws {
        let backing = WinMemoryPrefs()
        let (d, h) = try realDriver(backing: backing)
        toMenu(d, h)
        XCTAssertEqual(h.lastFrame?.height, 480)
        let presents = h.presents
        step(d, h, [key(0x03, "f", .command)])                         // Ctrl+F
        XCTAssertTrue(h.fullScreen)
        XCTAssertTrue(d.isFullScreen)
        XCTAssertTrue(d.currentPrefs.fullScreen)
        XCTAssertGreaterThan(h.presents, presents, "the window redrawn at its new size")
        XCTAssertEqual(h.lastFrame?.width, 640)
        XCTAssertEqual(h.lastFrame?.height, 480, "the same canvas in full screen")
        XCTAssertTrue(try store(backing).load().prefs.fullScreen, "saved")

        // A new launch over the same prefs starts in full screen.
        let h2 = ScriptedHost()
        let d2 = try WinGameDriver(assets: WinTestData.assets(), host: h2, audioOutput: SilentWinAudioOutput(),
                                   prefsBacking: backing, options: .init(registeredName: "Player", today: { (3, 3) }))
        d2.start()
        XCTAssertTrue(h2.fullScreen)
        XCTAssertTrue(d2.isFullScreen)
        XCTAssertEqual(h2.lastFrame?.height, 480)

        // Back to the window.
        step(d, h, [key(0x03, "f", .command)])
        XCTAssertFalse(h.fullScreen)
        XCTAssertFalse(d.currentPrefs.fullScreen)
        XCTAssertEqual(h.lastFrame?.height, 480)
        // A refused switch flips the pref back (the Mac's no-screen case).
        h.refuseFullScreen = true
        step(d, h, [key(0x03, "f", .command)])
        XCTAssertFalse(d.isFullScreen)
        XCTAssertFalse(d.currentPrefs.fullScreen)
        // `setFullScreen`'s return is the Mac's: true when the window is now as asked.
        h.refuseFullScreen = false
        XCTAssertTrue(d.setFullScreen(true))
        XCTAssertTrue(d.setFullScreen(false))
        h.refuseFullScreen = true
        XCTAssertFalse(d.setFullScreen(true))
    }

    // MARK: Ctrl shortcuts (no menu bar)

    func testShortcutsRunTheirCommands() throws {
        let backing = WinMemoryPrefs()
        let (d, h) = try realDriver(backing: backing)
        toMenu(d, h)
        let phase = d.frontEnd.phase
        // Ctrl+M: Music off, saved; again: back on.
        step(d, h, [key(0x2E, "m", .command)])
        XCTAssertEqual(d.currentPrefs.musicVolume, 1)
        XCTAssertEqual(try store(backing).load().prefs.musicVolume, 1)
        step(d, h, [key(0x2E, "m", .command)])
        XCTAssertNotEqual(d.currentPrefs.musicVolume, 1)
        // Ctrl+Shift+A: Sound Effects off, saved.
        step(d, h, [key(0x00, "A", [.command, .shift])])
        XCTAssertEqual(d.currentPrefs.sfxVolume, 1)
        XCTAssertEqual(try store(backing).load().prefs.sfxVolume, 1)
        // A repeat of a held shortcut does nothing (the Mac's menu key equivalents ignore auto-repeat).
        step(d, h, [.keyDown(keyCode: 0x00, characters: "A", modifiers: [.command, .shift], isRepeat: true)])
        XCTAssertEqual(d.currentPrefs.sfxVolume, 1)
        // Ctrl+Alt+M (the Mac's ⌥⌘M Minimize All) is eaten: nothing happens.
        let prefs = d.currentPrefs
        step(d, h, [key(0x2E, "m", [.command, .option])])
        XCTAssertEqual(d.currentPrefs, prefs)
        XCTAssertEqual(d.frontEnd.phase, phase)
        XCTAssertFalse(d.finished)
        // Ctrl+Q at the main menu: the quit routes (saves, fades, quits).
        step(d, h, [key(0x0C, "q", .command)])
        XCTAssertTrue(WinTestData.run(d, h, limit: 600) { d.finished }, "Ctrl+Q quits")
        XCTAssertTrue(h.quitCalled)
    }

    func testNoMenuStrip() throws {
        let (d, h) = try realDriver()
        toMenu(d, h)
        let frame = try XCTUnwrap(h.lastFrame)
        XCTAssertEqual(frame.width, 640)
        XCTAssertEqual(frame.height, 480)
        XCTAssertEqual(frame.canvas.pixels, d.compositor.screen.pixels, "the canvas is the game screen alone")
        // The top rows are the game's: a click there reaches the game (no bar takes it), and the pointer the game
        // reads is the canvas position.
        step(d, h, [.mouseMoved(x: 30, y: 2)])
        click(d, h, 30, 2)
        XCTAssertFalse(d.dialogs.isShowing)
        XCTAssertFalse(d.finished)
    }

    func testShortcutsFollowThePlayState() throws {
        let (d, h) = try realDriver()
        toMenu(d, h)
        h.injected = [key(0x24, "\r")]                                 // New Game
        XCTAssertTrue(WinTestData.run(d, h, limit: 1_000) { d.session?.phase == .playing }, "game running")
        XCTAssertFalse(d.shortcuts.isEnabled(.playMenus), "Preferences / Full Screen off in play")
        step(d, h, [key(0x2B, ",", .command)])                         // Ctrl+, in play: disabled → the game's key
        XCTAssertFalse(d.dialogs.isShowing)
        step(d, h, [key(0x03, "f", .command)])                         // Ctrl+F in play: disabled
        XCTAssertFalse(d.isFullScreen)
        XCTAssertFalse(d.currentPrefs.fullScreen)
        let music = d.currentPrefs.musicVolume
        step(d, h, [key(0x2E, "m", .command)])                         // Ctrl+M stays on in play
        XCTAssertNotEqual(d.currentPrefs.musicVolume, music)
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
