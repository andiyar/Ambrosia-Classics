@testable import BTXWinKit
import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import XCTest

/// DLOG 190 (+ 200, ALRT 201 / 202) as `BTXPrefsWindow.swift` behaves: real data, input through `DialogSystem`.
final class WinPrefsDialogTests: XCTestCase {
    private var system: DialogSystem!
    private var recorder: DialogRecorder!
    private var answers: [DialogSystem.Answer] = []

    private func open(_ prefs: BTXPrefs = .defaults) throws -> DialogWindow {
        (system, recorder) = try DialogFixture.system()
        answers = []
        XCTAssertTrue(system.present(.prefsDialog, prefs: prefs) { [unowned self] in answers.append($0) })
        return try XCTUnwrap(system.frontDialog)
    }

    private var saved: BTXPrefs? {
        if case .prefs(let p)? = answers.last { return p }
        return nil
    }

    /// Opens popup `item`'s menu by pressing on it, drags to row `row` (0-based), releases.
    private func choose(_ item: Int, row: Int, in d: DialogWindow) throws {
        let b = d.popupButtonRect(try XCTUnwrap(d.item(item)))
        system.mouseDown(x: d.originX + b.x + b.width / 2, y: d.originY + b.y + b.height / 2)
        guard case .popup(let m) = d.tracking else { return XCTFail("menu not open") }
        let r = m.rows[row]
        system.mouseMoved(x: d.originX + r.x + r.width / 2, y: d.originY + r.y + r.height / 2)
        system.mouseUp(x: d.originX + r.x + r.width / 2, y: d.originY + r.y + r.height / 2)
    }

    func testOpenSoundAreaAndHelpLine() throws {
        let d = try open()
        XCTAssertEqual(recorder.sounds.first?.cue, SoundCue(slot: 0x16, priority: 10, delayFrames: 0))
        XCTAssertEqual(d.defaultItem, 1)
        XCTAssertEqual(d.cancelItem, 2)
        XCTAssertEqual(d.items.count, 28)                                // 25 + DITL 191
        XCTAssertEqual(d.value(26), BTXPrefs.defaults.sfxVolume)
        XCTAssertEqual(d.value(27), BTXPrefs.defaults.musicVolume)
        XCTAssertEqual(d.value(28), BTXPrefs.defaults.titleMusic ? 1 : 0)
        XCTAssertEqual(d.frames.count, 9)                                // `_TouchUpPrefsDialog` items 14…22
        XCTAssertEqual(d.overlays.map(\.darkened), [true, false, false])
        let help = try system.data.strings(135)
        system.ticks(1)
        XCTAssertEqual(d.text(23), help[23])                             // first check: item 24, "Welcome…"
        let save = system.centre(of: 1)
        system.mouseMoved(x: save.x, y: save.y)
        system.ticks(1)
        XCTAssertEqual(d.text(23), help[0])
        let music = system.centre(of: 27)
        system.mouseMoved(x: music.x, y: music.y)
        system.ticks(1)
        XCTAssertEqual(d.text(23), try system.data.strings(132)[1])      // STR# 131 + area, item 27 − 25
    }

    func testMiscAreaSaveAndCancelRoundTrip() throws {
        let p = BTXPrefs.defaults
        var d = try open(p)
        system.click(7)
        XCTAssertEqual(system.prefsDialog?.area, 3)
        XCTAssertEqual(recorder.slots.last, 0x11)                        // `_ChangeArea`: snd 17
        XCTAssertEqual(d.items.count, 29)
        XCTAssertEqual(d.overlays.map(\.darkened), [false, false, true])
        XCTAssertEqual(d.value(26), p.fullScreen ? 1 : 0)
        system.click(26)
        system.click(27)
        system.click(28)
        system.click(29)
        XCTAssertEqual(d.value(27), p.showAirBubbles ? 0 : 1)
        system.click(1)                                                  // Save
        var q = p
        q.fullScreen.toggle(); q.showAirBubbles.toggle(); q.showStars.toggle(); q.holdEscapeToExit.toggle()
        XCTAssertEqual(saved, q)
        XCTAssertFalse(system.isShowing)

        d = try open(p)
        system.click(7)
        system.click(27)
        system.press(DialogSystem.kEscape)                               // Cancel (flashed)
        XCTAssertEqual(d.flashItem, 2)
        system.ticks(8)
        XCTAssertEqual(saved, p)
        XCTAssertFalse(system.isShowing)
    }

    func testSoundPopupsAndTitleMusic() throws {
        var p = BTXPrefs.defaults
        p.sfxVolume = 3
        p.musicVolume = 3
        let d = try open(p)
        try choose(26, row: 0, in: d)                                    // Sound FX → Off
        XCTAssertEqual(d.value(26), 1)
        XCTAssertEqual(system.prefsDialog?.prefs.sfxVolume, 1)
        XCTAssertEqual(system.prefsDialog?.prefs.lastSfxVolume, p.lastSfxVolume)   // "Off" keeps the last level
        XCTAssertEqual(recorder.sounds.last?.cue.slot, 0x12)
        XCTAssertNil(recorder.sounds.last?.volume)
        XCTAssertEqual(recorder.live.last?.music, false)
        try choose(27, row: 3, in: d)                                    // Music → Full
        XCTAssertEqual(system.prefsDialog?.prefs.musicVolume, 4)
        XCTAssertEqual(system.prefsDialog?.prefs.lastMusicVolume, 4)
        XCTAssertEqual(recorder.sounds.last?.cue.slot, 0x0d)
        XCTAssertEqual(recorder.sounds.last?.volume, 4)                  // snd 13 at the music level
        XCTAssertEqual(recorder.live.last?.music, true)
        // Click-release on the button keeps the menu open; a click on a row then chooses it.
        let b = d.popupButtonRect(d.item(26)!)
        system.mouseDown(x: d.originX + b.x + 10, y: d.originY + b.y + 10)
        system.mouseUp(x: d.originX + b.x + 10, y: d.originY + b.y + 10)
        guard case .popup(let m) = d.tracking else { return XCTFail("menu closed") }
        XCTAssertTrue(m.sticky)
        let r = m.rows[2]
        system.mouseDown(x: d.originX + r.x + 20, y: d.originY + r.y + 5)
        system.mouseUp(x: d.originX + r.x + 20, y: d.originY + r.y + 5)
        XCTAssertEqual(d.tracking, .none)
        XCTAssertEqual(system.prefsDialog?.prefs.sfxVolume, 3)
        // A click outside an open menu closes it without choosing.
        system.mouseDown(x: d.originX + b.x + 10, y: d.originY + b.y + 10)
        system.mouseUp(x: d.originX + b.x + 10, y: d.originY + b.y + 10)
        system.mouseDown(x: 2, y: 2)
        XCTAssertEqual(d.tracking, .none)
        XCTAssertEqual(d.value(26), 3)
        system.click(28)                                                 // Title screen music
        XCTAssertEqual(system.prefsDialog?.prefs.titleMusic, !p.titleMusic)
        XCTAssertEqual(d.value(28), p.titleMusic ? 0 : 1)
        system.press(DialogSystem.kReturn)                               // Save
        system.ticks(8)
        XCTAssertEqual(saved?.sfxVolume, 3)
        XCTAssertEqual(saved?.musicVolume, 4)
        XCTAssertEqual(saved?.titleMusic, !p.titleMusic)
    }

    func testKeysAreaSetsAndKeyCapture() throws {
        let p = BTXPrefs.defaults
        XCTAssertEqual(p.currentKeySetIndex, 1)
        let d = try open(p)
        system.click(6)
        XCTAssertEqual(system.prefsDialog?.area, 2)
        XCTAssertEqual(d.items.count, 25 + 18)
        // Set 1 ("Defaults") cannot be edited: the names show as static text.
        XCTAssertTrue((26...30).allSatisfy { d.isHidden($0) })
        XCTAssertTrue((34...38).allSatisfy { !d.isHidden($0) })
        XCTAssertEqual(d.text(34), try system.data.strings(130)[Int(p.keySet(1).left)])
        let titles = try XCTUnwrap(d.popups[33]?.titles)
        XCTAssertEqual(titles.first, "Defaults")
        XCTAssertEqual(titles[1], "(-")
        XCTAssertEqual(titles.count, 2 + p.keySetCount - 1)
        XCTAssertEqual(d.value(33), 1)
        system.press(0x00, "a")                                          // set 1: keys go nowhere
        XCTAssertEqual(system.prefsDialog?.prefs.currentKeySet, p.currentKeySet)

        try choose(33, row: 2, in: d)                                    // set 2
        XCTAssertEqual(system.prefsDialog?.prefs.currentKeySetIndex, 2)
        XCTAssertEqual(d.value(33), 3)
        XCTAssertTrue((26...30).allSatisfy { !d.isHidden($0) })
        XCTAssertEqual(d.focusedEditItem, 26)
        let names = try system.data.strings(130)
        let set2 = p.keySet(2)
        XCTAssertEqual(d.text(26), names[Int(set2.left)])

        system.press(0x00, "a")                                          // left ← A
        XCTAssertEqual(d.text(26), "A")
        XCTAssertEqual(system.prefsDialog?.keyTarget, 27)
        XCTAssertEqual(d.focusedEditItem, 27)
        XCTAssertEqual(d.selection, 0..<d.text(27).count)
        system.press(0x00, "a")                                          // already Left → beep, target stays
        XCTAssertEqual(recorder.beeps, 1)
        XCTAssertEqual(system.prefsDialog?.keyTarget, 27)
        system.ticks(1, held: [0x38])                                    // left Shift held → right ← Shift
        XCTAssertEqual(d.text(27), "Shift")
        system.ticks(1, held: [0x38])                                    // latched: once per press
        XCTAssertEqual(system.prefsDialog?.keyTarget, 28)
        system.click(30)                                                 // target the Push field
        XCTAssertEqual(system.prefsDialog?.keyTarget, 30)
        system.press(DialogSystem.kTab)                                  // Tab moves the TextEdit focus only
        XCTAssertEqual(system.prefsDialog?.keyTarget, 30)
        system.press(DialogSystem.kReturn)
        system.ticks(8)
        let q = try XCTUnwrap(saved)
        XCTAssertEqual(q.currentKeySetIndex, 2)
        XCTAssertEqual(q.keySet(2).left, 0x00)
        XCTAssertEqual(q.keySet(2).right, 0x38)
        XCTAssertEqual(q.keySet(2).up, set2.up)
    }

    func testNewSetDeleteSetAndAlerts201And202() throws {
        let p = BTXPrefs.defaults
        let d = try open(p)
        system.click(6)
        system.click(31)                                                 // New Set...
        let n = try XCTUnwrap(system.frontDialog)
        XCTAssertEqual(n.template.id, 200)
        XCTAssertEqual(n.outlines, [1])
        XCTAssertNil(n.defaultItem)
        XCTAssertEqual(n.text(3), "Sheryn")
        XCTAssertEqual(n.selection, 0..<6)
        system.type("Abcdefghijkl")
        system.press(DialogSystem.kReturn)
        system.ticks(8)
        let alert = try XCTUnwrap(system.frontDialog)
        XCTAssertEqual(alert.template.id, 201)
        XCTAssertEqual(recorder.beeps, 1)
        system.press(DialogSystem.kReturn)
        system.ticks(8)
        XCTAssertTrue(system.frontDialog === n)
        XCTAssertEqual(n.text(3), "Abcdefghij")                          // cut to 10 bytes, all selected
        XCTAssertEqual(n.selection, 0..<10)
        system.type("Ben")
        system.press(DialogSystem.kEnter)
        system.ticks(8)
        XCTAssertTrue(system.frontDialog === d)
        let edited = try XCTUnwrap(system.prefsDialog?.prefs)
        XCTAssertEqual(edited.keySetCount, p.keySetCount + 1)
        XCTAssertEqual(edited.currentKeySetIndex, edited.keySetCount)
        XCTAssertEqual(edited.currentKeySet, KeySet(name: "Ben", left: 0x7b, right: 0x7c, up: 0x7e, down: 0x7d,
                                                   push: 0x31))
        XCTAssertEqual(d.popups[33]?.titles.last, "Ben")
        // Cancel in DLOG 200 changes nothing.
        system.click(31)
        system.press(DialogSystem.kEscape)
        system.ticks(8)
        XCTAssertTrue(system.frontDialog === d)
        XCTAssertEqual(system.prefsDialog?.prefs.keySetCount, p.keySetCount + 1)
        // Delete Set removes the current one.
        system.click(32)
        XCTAssertEqual(system.prefsDialog?.prefs.keySetCount, p.keySetCount)
        XCTAssertEqual(system.prefsDialog?.prefs.currentKeySetIndex, p.keySetCount)

        var full = BTXPrefs.defaults
        full.keySetCount = 20
        _ = try open(full)
        system.click(6)
        system.click(31)
        XCTAssertEqual(system.frontDialog?.template.id, 202)
        XCTAssertEqual(recorder.beeps, 1)
        system.click(1)
        XCTAssertEqual(system.frontDialog?.template.id, 190)
    }

    func testDefaultsAndRevert() throws {
        var p = BTXPrefs.defaults
        p.sfxVolume = 1
        p.showStars = false
        let d = try open(p)
        system.click(3)                                                  // Defaults
        var alex = p
        alex.applyAlexPrefsSoundInit(); alex.applyAlexPrefsKeysInit(); alex.applyAlexPrefsGameInit()
        XCTAssertEqual(system.prefsDialog?.prefs, alex)
        XCTAssertEqual(d.value(26), alex.sfxVolume)
        XCTAssertEqual(recorder.live.last?.music, true)
        system.click(4)                                                  // Revert
        XCTAssertEqual(system.prefsDialog?.prefs, p)
        XCTAssertEqual(d.value(26), 1)
        system.click(2)                                                  // Cancel
        XCTAssertEqual(saved, p)
    }

    func testAlexEggPlaysOnce() throws {
        var p = BTXPrefs.defaults
        p.currentKeySetIndex = 2
        let d = try open(p)
        system.click(6)
        XCTAssertEqual(d.focusedEditItem, 26)
        for (code, ch) in [(UInt16(0x00), "a"), (0x25, "l"), (0x0e, "e"), (0x07, "x"), (0x2f, ".")] {
            system.press(code, ch)
        }
        XCTAssertEqual(system.prefsDialog?.prefs.currentKeySet.codes, [0x00, 0x25, 0x0e, 0x07, 0x2f])
        XCTAssertEqual(recorder.slots.last, 0x0d)
        XCTAssertTrue(system.prefsStatics.playedEggOne)
    }
}
