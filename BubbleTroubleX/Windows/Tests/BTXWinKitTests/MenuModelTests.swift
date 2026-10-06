@testable import BTXWinKit
import BubbleTroubleCore
import Foundation
import XCTest

/// W5: the model against `BubbleTroubleX/App/BTXMenus.swift`, item by item.
final class MenuModelTests: XCTestCase {
    /// One row per entry: menu, title ("—" = separator), key, modifiers, command, rule, checked (default model).
    struct Row: Equatable {
        var menu: String, title: String, key: Character?, mods: MenuModifiers, command: MenuCommand?
        var rule: MenuEnableRule, checked: Bool
    }

    static func r(_ menu: String, _ title: String, _ key: Character? = nil, _ mods: MenuModifiers = [],
                  _ command: MenuCommand? = nil, _ rule: MenuEnableRule = .always, checked: Bool = false) -> Row {
        Row(menu: menu, title: title, key: key, mods: mods, command: command, rule: rule, checked: checked)
    }
    static func sep(_ menu: String) -> Row { r(menu, "—") }

    /// The transcription table: BTXMenus.swift `appMenu` (minus Carbon's tail), `makeEditMenu` (minus Special
    /// Characters… and its separator), `makeOptionsMenu`, `windowMenu`; `validateMenuItem` for the rules.
    static let table: [Row] = [
        r("Bubble Trouble X", "About Bubble Trouble X", nil, [], .about, .about),
        sep("Bubble Trouble X"),
        r("Bubble Trouble X", "Preferences…", ",", .command, .preferences, .preferences),
        sep("Bubble Trouble X"),
        r("Bubble Trouble X", "Quit Bubble Trouble X", "q", .command, .quit),
        r("Edit", "Undo", "z", .command, .undo, .never),
        r("Edit", "Redo", "Z", .command, .redo, .never),
        sep("Edit"),
        r("Edit", "Cut", "x", .command, .cut, .never),
        r("Edit", "Copy", "c", .command, .copy, .never),
        r("Edit", "Paste", "v", .command, .paste, .never),
        r("Edit", "Delete", nil, .command, .delete, .never),
        r("Edit", "Select All", "a", .command, .selectAll, .never),
        r("Options", "Full Screen", "f", .command, .fullScreen, .playMenus),
        sep("Options"),
        r("Options", "Sound Effects", "A", .command, .soundEffects, checked: true),
        r("Options", "Music", "m", .command, .music, checked: true),
        sep("Options"),
        r("Options", "Key Sets", nil, .command, nil),
        r("Window", "Minimize", "m", .command, .minimize, .always),
        r("Window", "Zoom", nil, .command, .zoom, .always),
        sep("Window"),
        r("Window", "Bring All to Front", nil, .command, .bringAllToFront),
    ]

    func flatten(_ bar: MenuBar) -> [Row] {
        bar.menus.flatMap { m in
            m.entries.map { e -> Row in
                guard let i = e.item else { return Self.sep(m.title) }
                return Row(menu: m.title, title: i.title, key: i.key, mods: i.modifiers, command: i.command,
                           rule: i.rule, checked: i.checked)
            }
        }
    }

    func testTranscriptionTable() {
        let bar = MenuBar()
        XCTAssertEqual(bar.menus.map(\.title), ["Bubble Trouble X", "Edit", "Options", "Window"])
        XCTAssertEqual(bar.menus.map(\.bold), [true, false, false, false])
        let got = flatten(bar)
        XCTAssertEqual(got.count, Self.table.count)
        for (g, w) in zip(got, Self.table) { XCTAssertEqual(g, w) }
    }

    func testWindowAlternates() throws {
        let window = MenuBar().menus[3]
        let minimize = try XCTUnwrap(window.entries[0].item?.alternate)
        XCTAssertEqual(minimize, MenuAlternate(title: "Minimize All", key: "m", modifiers: [.command, .option],
                                               command: .minimizeAll, rule: .always))
        let front = try XCTUnwrap(window.entries[3].item?.alternate)
        XCTAssertEqual(front.title, "Arrange in Front")
        XCTAssertNil(front.key)
        XCTAssertEqual(front.command, .arrangeInFront)
    }

    func testOmittedMacOSOnlyItems() {
        let titles = MenuBar().menus.flatMap { $0.entries.compactMap { $0.item?.title } }
        for gone in ["Services", "Hide Bubble Trouble X", "Hide Others", "Show All", "Special Characters…",
                     "Settings…", "Register Bubble Trouble X…", "Check for Updates…"] {
            XCTAssertFalse(titles.contains(gone), gone)
        }
    }

    // MARK: Key Sets (`_ResetOptionsMenu`)

    func prefs(sets: [String], current: Int) -> BTXPrefs {
        var p = BTXPrefs.defaults
        p.keySetCount = sets.count
        for (i, name) in sets.enumerated() {
            var k = p.keySet(i + 1)
            k.name = name
            p.setKeySet(i + 1, k)
        }
        p.currentKeySetIndex = current
        return p
    }

    func keySetRows(_ bar: MenuBar) -> [String] {
        bar.menus[2].entries[5].item!.submenu!.entries.map { e in
            guard let i = e.item else { return "—" }
            return (i.checked ? "✓" : "") + i.title + "=" + "\(i.command.map { "\($0)" } ?? "")"
        }
    }

    func testKeySetsOneSet() {
        var bar = MenuBar()
        bar.resetOptionsMenu(prefs(sets: ["Mine"], current: 1))
        XCTAssertEqual(keySetRows(bar), ["✓Default=keySet(1)"], "set 1 is always \"Default\"")
    }

    func testKeySetsSeveral() {
        var bar = MenuBar()
        bar.resetOptionsMenu(prefs(sets: ["Default", "Ben", "Arrows"], current: 3))
        XCTAssertEqual(keySetRows(bar), ["Default=keySet(1)", "—", "Ben=keySet(2)", "✓Arrows=keySet(3)"])
        var p = prefs(sets: ["Default", "Ben", "Arrows"], current: 3)
        XCTAssertTrue(bar.apply(.keySet(2), to: &p))
        XCTAssertEqual(p.currentKeySetIndex, 2)
        XCTAssertEqual(keySetRows(bar), ["Default=keySet(1)", "—", "✓Ben=keySet(2)", "Arrows=keySet(3)"])
    }

    func testKeySetsCappedAtTwenty() {
        var bar = MenuBar()
        bar.resetOptionsMenu(prefs(sets: (1...20).map { "S\($0)" }, current: 20))
        var p = BTXPrefs.defaults
        p.keySetCount = 25
        bar.resetOptionsMenu(p)
        XCTAssertEqual(keySetRows(bar).count, 1 + 1 + 19)
    }

    func testResetMarks() {
        var bar = MenuBar()
        var p = prefs(sets: ["Default"], current: 1)
        p.fullScreen = true; p.sfxVolume = 1; p.musicVolume = 3
        bar.resetOptionsMenu(p)
        let o = bar.menus[2].entries
        XCTAssertEqual(o[0].item?.checked, true)
        XCTAssertEqual(o[2].item?.checked, false)
        XCTAssertEqual(o[3].item?.checked, true)
    }

    // MARK: The Options actions

    func testSoundAndMusicToggles() {
        var bar = MenuBar()
        var p = BTXPrefs.defaults
        p.sfxVolume = 3; p.lastSfxVolume = 3; p.musicVolume = 1; p.lastMusicVolume = 4
        bar.resetOptionsMenu(p)
        bar.apply(.soundEffects, to: &p)
        XCTAssertEqual(p.sfxVolume, 1); XCTAssertFalse(bar.soundChecked)
        bar.apply(.soundEffects, to: &p)
        XCTAssertEqual(p.sfxVolume, 3); XCTAssertTrue(bar.soundChecked)
        bar.apply(.music, to: &p)
        XCTAssertEqual(p.musicVolume, 4); XCTAssertTrue(bar.musicChecked)
        bar.apply(.music, to: &p)
        XCTAssertEqual(p.musicVolume, 1); XCTAssertFalse(bar.musicChecked)
        XCTAssertFalse(bar.apply(.quit, to: &p))
    }

    func testFullScreenFlipsBackWhenTheSwitchFails() {
        var bar = MenuBar()
        var p = BTXPrefs.defaults
        p.fullScreen = false
        bar.fullScreenChosen(&p) { XCTAssertTrue($0); return true }
        XCTAssertTrue(p.fullScreen); XCTAssertTrue(bar.fullScreenChecked)
        bar.fullScreenChosen(&p) { _ in false }
        XCTAssertTrue(p.fullScreen); XCTAssertTrue(bar.fullScreenChecked)
    }

    // MARK: Enabling

    func testEnableRules() {
        var bar = MenuBar()
        XCTAssertTrue(bar.isEnabled(.about))
        XCTAssertTrue(bar.isEnabled(.preferences))
        XCTAssertTrue(bar.isEnabled(.playMenus))
        XCTAssertFalse(bar.isEnabled(.never))
        bar.disableAbout(true)
        XCTAssertFalse(bar.isEnabled(.about))
        bar.setEnabled(menusEnabled: false)
        XCTAssertFalse(bar.isEnabled(.preferences))
        XCTAssertFalse(bar.isEnabled(.playMenus))
        XCTAssertTrue(bar.isEnabled(.always))
        bar.setEnabled(menusEnabled: true)
        bar.preferencesAvailable = false
        XCTAssertFalse(bar.isEnabled(.preferences))
        XCTAssertTrue(bar.isEnabled(.playMenus))
        bar.dialogUp = true
        XCTAssertFalse(bar.isEnabled(.always), "a dialog disables every item")
    }

    // MARK: Ctrl shortcuts

    func testShortcuts() {
        var bar = MenuBar()
        let ctrl: MenuModifiers = .command
        XCTAssertEqual(bar.command(forKeyCode: 0x0C, modifiers: ctrl), .quit)
        XCTAssertEqual(bar.command(forKeyCode: 0x2B, modifiers: ctrl), .preferences)
        XCTAssertEqual(bar.command(forKeyCode: 0x03, modifiers: ctrl), .fullScreen)
        XCTAssertEqual(bar.command(forKeyCode: 0x00, modifiers: [.command, .shift]), .soundEffects)
        XCTAssertNil(bar.command(forKeyCode: 0x00, modifiers: ctrl), "Select All: disabled")
        XCTAssertEqual(bar.command(forKeyCode: 0x2E, modifiers: ctrl), .music, "Music before Minimize")
        XCTAssertEqual(bar.command(forKeyCode: 0x2E, modifiers: [.command, .option]), .minimizeAll)
        XCTAssertNil(bar.command(forKeyCode: 0x0C, modifiers: []), "no Ctrl")
        XCTAssertNil(bar.command(forKeyCode: 0x0C, modifiers: [.command, .shift]), "exact modifiers")
        XCTAssertNil(bar.command(forKeyCode: 0x0C, modifiers: [.command, .control]))
        XCTAssertNil(bar.command(forKeyCode: 0x01, modifiers: ctrl))
        // By physical key only: the key that types "q" on AZERTY (A's position, 0x00) is Select All, not Quit;
        // the Q key is Quit whatever it types. The old "h" (Hide) code is gone.
        XCTAssertNil(bar.command(forKeyCode: 0x00, modifiers: ctrl))
        XCTAssertNil(bar.command(forKeyCode: 0x04, modifiers: ctrl))
        bar.setEnabled(menusEnabled: false)
        XCTAssertNil(bar.command(forKeyCode: 0x03, modifiers: ctrl), "Full Screen off in play")
        XCTAssertNil(bar.command(forKeyCode: 0x2B, modifiers: ctrl))
        XCTAssertEqual(bar.command(forKeyCode: 0x0C, modifiers: ctrl), .quit, "Quit stays on")
        bar.dialogUp = true
        XCTAssertNil(bar.command(forKeyCode: 0x0C, modifiers: ctrl))
    }

    func testShortcutLabels() {
        XCTAssertEqual(MenuBarView.shortcut("f", .command), "Ctrl+F")
        XCTAssertEqual(MenuBarView.shortcut("A", .command), "Ctrl+Shift+A")
        XCTAssertEqual(MenuBarView.shortcut("m", [.command, .option]), "Ctrl+Alt+M")
        XCTAssertEqual(MenuBarView.shortcut(",", .command), "Ctrl+,")
        XCTAssertNil(MenuBarView.shortcut(nil, .command))
        XCTAssertNil(MenuBarView.shortcut("x", []))
    }
}
