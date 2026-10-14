import XCTest
@testable import FerazelCore

/// O1 (docs/plans/2026-10-14-ferazel-phase3.md): the Options dialog's logic (`.PreferencesDialog`,
/// `.UpdatePrefsPanel`, `.PrefDialogFilter`, `.AlreadyUsingKey`, `.ConvertKeyName`; M l. 63963–64830), `.MakeCurrPrefs`
/// and ⌘M / ⌘F (M l. 7105–7251). Bank: save-continue §8.2, engine §8. A missing data file is a FAILURE, never a skip.
final class PrefsDialogTests: XCTestCase {

    private static let layout: @Sendable (Int16) -> String? = { code in
        switch code {
        case 0x52: return "0"
        case 0x0c: return "q"
        case 0x00: return "a"
        default: return nil
        }
    }

    private func dialog(_ record: FerazelPrefs = FerazelPrefs(), live: PrefsToggles? = nil, paused: Bool = false,
                        processorType: Int = FerazelPrefs.modernProcessorType) -> PrefsDialogModel {
        PrefsDialogModel(record: record, live: live ?? PrefsToggles(live: record), paused: paused,
                         processorType: processorType, keyCharacter: Self.layout)
    }

    /// A live side with track 24 loaded and the music flag applied (the main menu with music playing).
    private func playing(_ prefs: FerazelPrefs = FerazelPrefs()) -> PrefsToggles {
        var music = MusicFade()
        _ = music.setAIFFMusic(24)
        return PrefsToggles(live: prefs, music: music, appliedMusicOn: prefs.musicOn)
    }

    func testPanelItemMapping() throws {
        // The panels as appended after DITL 6900's six items (dialog numbering).
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let game = try DialogItemList.load(from: r, id: 6901)
        XCTAssertEqual(game.items.count + 6, 14, "no item 16 on Game Options")
        XCTAssertEqual(game.items[12 - 7].kind, .staticText, "item 12 is the 'Graphics:' label (dead +0x04 branch)")
        XCTAssertEqual(game.items[14 - 7].text, "Resolution switching")
        let keys = try DialogItemList.load(from: r, id: 6902)
        XCTAssertEqual(keys.items.count + 6, 27, "no item 30 on Controls")
        XCTAssertEqual(keys.items[27 - 7].text, "Configure…")
        let sound = try DialogItemList.load(from: r, id: 6903)
        XCTAssertEqual(sound.items[8 - 7].text, "Music")
        XCTAssertEqual(sound.items[16 - 7].text, "Set system volume on startup")

        var d = dialog()
        XCTAssertEqual(d.panel, .gameOptions)
        XCTAssertEqual(d.controlValues, [3: 1, 7: 0, 8: 0, 9: 0, 14: 0, 10: 1, 11: 1])
        d.hit(7); d.hit(8); d.hit(9)
        XCTAssertEqual([d.working.reduceFrameRate, d.working.reuseSavedGames, d.working.backgroundTasks], [1, 1, 1])
        XCTAssertEqual([d.controlValues[7], d.controlValues[8], d.controlValues[9]], [1, 1, 1])
        d.hit(10, value: 3)
        d.hit(11, value: 2)
        XCTAssertEqual(d.working.graphics, 3)
        XCTAssertEqual(d.working.effects, 2)
        d.hit(12)
        XCTAssertEqual(d.working.parallax, 2, "item 12 → +0x04 is dead")
        d.hit(14)
        XCTAssertEqual(d.working.resolutionSwitch, 1)
        XCTAssertEqual(d.controlValues[14], 0, "the click updates item 16, which does not exist")
        XCTAssertNil(d.controlValues[16])

        d.hit(3, value: 3)
        XCTAssertEqual(d.panel, .soundAndMusic)
        XCTAssertEqual(d.hiddenItems, [13], "QuickTime present → the 'requires QuickTime' text is hidden")
        XCTAssertEqual(d.controlValues, [3: 3, 7: 1, 8: 1, 9: 3, 10: 1, 15: 10, 16: 0])
        d.hit(7)
        XCTAssertEqual(d.working.soundOn, 0)
        d.hit(16)
        XCTAssertEqual(d.working.useSystemVolume, 1)
        d.hit(15, value: 4)
        XCTAssertEqual(d.working.systemVolumeBy28, 6)

        d.hit(3, value: 2)
        XCTAssertEqual(d.panel, .controls)
        XCTAssertEqual(d.focus, 7)
        XCTAssertEqual((7...15).map { d.itemTexts[$0] ?? "?" },
                       ["Keypad 4", "Keypad 6", "Keypad 8", "Keypad 5", "Shift", "Option", "Command", "Keypad 7",
                        "Keypad 9"])
        XCTAssertEqual(d.disabledItems, [26, 27], "no InputSprocket: +0x0a forced 0, Configure… off")
        d.hit(26)
        XCTAssertEqual(d.working.useInputSprocket, 0)

        d.hit(3, value: 1)
        XCTAssertNil(d.focus)
        XCTAssertEqual(d.controlValues[14], 1, "the rebuilt panel shows +0x32")
        XCTAssertNil(d.result)
    }

    func testKeyCaptureRules() {
        var d = dialog()
        d.hit(3, value: 2)
        XCTAssertEqual(d.focus, 7)

        // Walk Left (slot 0) ← keypad 8 (Climb Up's key): refused with the report, nothing moves.
        XCTAssertEqual(d.keyDown(char: 0x38, keyCode: 0x5b), .refused(PrefsDialogModel.keyInUseMessage))
        XCTAssertEqual(d.working.keys[0], 0x56)
        XCTAssertEqual(d.focus, 7)

        // Up (2) and Jump (5) may share: Jump (item 12) ← keypad 8.
        d.focus(item: 12)
        XCTAssertEqual(d.keyDown(char: 0x38, keyCode: 0x5b), .captured(item: 12))
        XCTAssertEqual(d.working.keys[5], 0x5b)
        XCTAssertEqual(d.itemTexts[12], "Keypad 8")
        XCTAssertEqual(d.focus, 13)

        // Use (item 13) ← Space, freeing Command; then ⌘ held on Walk Left → 0x37.
        XCTAssertEqual(d.keyDown(char: 0x20, keyCode: 0x31), .captured(item: 13))
        XCTAssertEqual(d.itemTexts[13], "Space Bar")
        d.focus(item: 7)
        XCTAssertEqual(d.idle(modifiers: 0x100), .captured(item: 7))
        XCTAssertEqual(d.working.keys[0], 0x37)
        XCTAssertEqual(d.itemTexts[7], "Command")
        XCTAssertEqual(d.focus, 8)
        XCTAssertEqual(d.idle(modifiers: 0x100), .passed, "a held modifier is taken once")
        XCTAssertEqual(d.focus, 8)
        XCTAssertEqual(d.idle(modifiers: 0), .passed)
        XCTAssertEqual(d.lastModifier, 0)

        // A modifier already in use (Shift = Run) is ignored silently.
        XCTAssertEqual(d.idle(modifiers: 0x200), .passed)
        XCTAssertEqual(d.working.keys[1], 0x58)
        XCTAssertEqual(d.focus, 8)

        // Focus wraps 15 → 7; the layout's character, uppercased.
        d.focus(item: 15)
        XCTAssertEqual(d.keyDown(char: 0x71, keyCode: 0x0c), .captured(item: 15))
        XCTAssertEqual(d.itemTexts[15], "Q")
        XCTAssertEqual(d.focus, 7)

        // 'A' (0x00) reads as used: slot 9 (+0x24) is 0 in the record (D35 ruling 9) [LOW, recorded].
        XCTAssertTrue(PrefsDialogModel.alreadyUsingKey(0x00, slot: 0, in: d.working))
        XCTAssertEqual(d.keyDown(char: 0x61, keyCode: 0x00), .refused(PrefsDialogModel.keyInUseMessage))
        // The last matching slot's verdict: Up's key on Jump with Up matched first, then no later match → free.
        XCTAssertFalse(PrefsDialogModel.alreadyUsingKey(0x5b, slot: 5, in: d.working))

        // On Controls, Return / Esc are keys; elsewhere they are OK / Cancel.
        d.focus(item: 9)
        XCTAssertEqual(d.keyDown(char: 0x0d, keyCode: 0x24), .captured(item: 9))
        XCTAssertEqual(d.itemTexts[9], "Return")
        XCTAssertNil(d.result)
        XCTAssertEqual(d.keyDown(char: 0x1b, keyCode: 0x35), .captured(item: 10))
        XCTAssertNil(d.result)
        XCTAssertEqual(d.keyDown(char: 0x1b, keyCode: 0x35, isRepeat: true), .swallowed)

        var g = dialog()
        XCTAssertEqual(g.keyDown(char: 0x41, keyCode: 0x00), .passed)
        XCTAssertEqual(g.keyDown(char: 0x2e, keyCode: 0x2f, modifiers: 0x100), .cancel)
        XCTAssertEqual(g.result, .cancel)
        var s = dialog()
        s.hit(3, value: 3)
        XCTAssertEqual(s.keyDown(char: 0x03, keyCode: 0x4c), .ok)
        XCTAssertEqual(s.result, .ok)
    }

    func testConvertKeyNameTable() {
        let name = { (c: Int16) in PrefsDialogModel.keyName(c, keyCharacter: Self.layout) }
        XCTAssertEqual(name(0x24), "Return")
        XCTAssertEqual(name(0x31), "Space Bar")
        XCTAssertEqual(name(0x37), "Command")
        XCTAssertEqual(name(0x56), "Keypad 4")
        XCTAssertEqual(name(0x5b), "Keypad 8")
        XCTAssertEqual(name(0x7e), "Up Arrow")
        XCTAssertEqual(name(0x52), "0", "not in the table: the layout's character")
        XCTAssertEqual(name(0x0c), "Q", "uppercased")
        XCTAssertEqual(name(0x32), "`")
        XCTAssertEqual(name(0x75), "Del")
        XCTAssertEqual(name(0x63), "F3")
        XCTAssertEqual(name(0x45), "", "no character from the layout")
    }

    func testVolumeControlMapping() {
        var d = dialog(live: playing())
        d.hit(3, value: 3)
        XCTAssertEqual(d.controlValues[10], 1, "pref 9 → v 1")
        XCTAssertEqual(d.controlValues[9], 3, "pref 7 → v 3")
        d.hit(9, value: 3)
        XCTAssertEqual(d.working.soundVolume, 7, "v 3 → pref 7")
        XCTAssertEqual(d.live.live.soundOn, 1)
        XCTAssertEqual(d.live.soundScale, 196)
        XCTAssertEqual(d.hit(10, value: 4), [.volume(170)], "applied at once: 6·256/9")
        XCTAssertEqual(d.working.musicVolume, 6)
        XCTAssertEqual(d.live.live.musicVolume, 9, "the live +0x10 is not touched by the popup")

        // The Music checkbox: off stops the movie; on writes the live flag but never restarts the music.
        XCTAssertEqual(d.hit(8), [.volume(0), .stop])
        XCTAssertEqual(d.live.live.musicOn, 0)
        XCTAssertEqual(d.hit(8), [], "SetMusicAIFFVolume after the shutdown is a no-op: no .play")
        XCTAssertEqual(d.live.live.musicOn, 1)
        XCTAssertEqual(d.live.live.musicVolume, 6)
        XCTAssertFalse(d.live.music.loaded)

        // Paused (⌘P Options): no volume calls, the shutdown still runs.
        var p = dialog(live: playing(), paused: true)
        p.hit(3, value: 3)
        XCTAssertEqual(p.hit(10, value: 2), [])
        XCTAssertEqual(p.hit(8), [.stop])
    }

    func testGameOptionsDefaultSettingsBug() {
        var old = FerazelPrefs()
        old.graphics = 3
        old.reduceFrameRate = 1
        old.resolutionSwitch = 1
        old.plainCopy = 1
        old.parallax = 3
        old.unread3c = 5

        var d = dialog(old, processorType: 0x104)
        d.hit(4)
        XCTAssertEqual(d.record.graphics, 1, "the defaults land in the record")
        XCTAssertEqual(d.record.reduceFrameRate, 0)
        XCTAssertEqual(d.record.resolutionSwitch, 0)
        XCTAssertEqual(d.record.plainCopy, 0)
        XCTAssertEqual(d.record.parallax, 2)
        XCTAssertEqual(d.record.effects, 2, "pre-G3: Effects 2")
        XCTAssertEqual(d.record.unread3c, 0)
        XCTAssertEqual(d.working, old, "the working copy is untouched")
        XCTAssertEqual(d.controlValues[10], 3, "nothing visibly changes")
        d.hit(1)
        XCTAssertEqual(d.result, .ok)
        XCTAssertEqual(d.record, old, "OK overwrites them with the working copy")

        var c = dialog(old)
        c.hit(4)
        c.hit(2)
        XCTAssertEqual(c.result, .cancel)
        XCTAssertEqual(c.record.graphics, 1, "Cancel keeps them")
        XCTAssertEqual(c.record.effects, 1)

        // Controls and Sound & Music reset the working copy (the record is untouched).
        var k = dialog(old)
        k.hit(3, value: 2)
        k.focus(item: 7)
        _ = k.keyDown(char: 0x71, keyCode: 0x0c)
        k.hit(3, value: 3)
        k.hit(10, value: 5)
        k.hit(4)
        XCTAssertEqual(k.working.musicVolume, 9)
        k.hit(3, value: 2)
        XCTAssertEqual(k.working.keys[0], 0x0c)
        k.hit(4)
        XCTAssertEqual(k.working.keys, FerazelPrefs.defaultKeys)
        XCTAssertEqual(k.focus, 7)
        XCTAssertEqual(k.record, old)
    }

    func testToggleMusicAndSound() {
        var t = playing()
        var record = FerazelPrefs()

        let off = t.toggleMusic(&record, paused: false)
        XCTAssertEqual(off.music, [.stop])
        XCTAssertEqual(record.musicOn, 0, "the prefs record to write")
        XCTAssertEqual(off.prefs?.musicOn, 0)
        XCTAssertEqual(t.live.musicOn, 0)

        let on = t.toggleMusic(&record, paused: false)
        // M l. 7238–7249: SetMusicAIFFVolume(0) is gated on a loaded movie (none after the stop). SetAIFFMusic's
        // ShutDownAIFFMusic (M l. 41877ff, 41943) and SetMusicAIFFVolume (M l. 41959–41971) are both gated on a loaded
        // movie: the stop already happened at ⌘M off, so no second `.stop` before the play.
        XCTAssertEqual(on.music, [.play(track: 24), .volume(256)])
        XCTAssertEqual(record.musicOn, 1)
        XCTAssertEqual(record.musicVolume, 9)
        XCTAssertEqual(on.prefs, record)

        var paused = playing()
        var r2 = FerazelPrefs()
        XCTAssertEqual(paused.toggleMusic(&r2, paused: true).music, [.stop])
        let silent = paused.toggleMusic(&r2, paused: true)
        XCTAssertEqual(silent.music, [], "paused: on stays silent")
        XCTAssertEqual(silent.prefs?.musicOn, 1)
        XCTAssertEqual(paused.appliedMusicOn, 1)

        let fx = t.toggleSound(&record, paused: false)
        XCTAssertEqual(record.soundOn, 0)
        XCTAssertEqual(fx.music, [])
        XCTAssertEqual(fx.prefs?.soundOn, 0)
        XCTAssertEqual(t.soundScale, 196)
        _ = t.toggleSound(&record, paused: false)
        XCTAssertEqual(record.soundOn, 1)

        // .MakeCurrPrefs: 5107 = (+9 == 0); sound scale +0x0e·28.
        var m = PrefsToggles(live: FerazelPrefs())
        var rec = FerazelPrefs()
        rec.plainCopy = 1
        rec.soundVolume = 3
        _ = m.makeCurrPrefs(rec, paused: false)
        XCTAssertFalse(m.wrapCopyFlag)
        XCTAssertEqual(m.soundScale, 84)
        XCTAssertEqual(m.live, rec)
    }
}
