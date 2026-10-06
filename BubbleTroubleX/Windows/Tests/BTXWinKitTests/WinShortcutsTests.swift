@testable import BTXWinKit
import BubbleTroubleCore
import Foundation
import XCTest

/// D21: the Mac menu bar's key equivalents without the bar, against `BubbleTroubleX/App/BTXMenus.swift`.
final class WinShortcutsTests: XCTestCase {
    private let ctrl: WinModifiers = .command

    func testTable() {
        let rows = WinShortcuts.table.map { "\(String($0.keyCode, radix: 16)) \($0.modifiers.rawValue) \($0.command)" }
        XCTAssertEqual(rows, [
            "2b 2 preferences",     // Ctrl+,
            "c 2 quit",             // Ctrl+Q
            "3 2 fullScreen",       // Ctrl+F
            "0 3 soundEffects",     // Ctrl+Shift+A
            "2e 2 music",           // Ctrl+M
            "2e 6 minimizeAll",     // Ctrl+Alt+M
        ])
    }

    func testEachShortcutFires() {
        let s = WinShortcuts()
        XCTAssertEqual(s.command(forKeyCode: 0x2B, modifiers: ctrl), .preferences)
        XCTAssertEqual(s.command(forKeyCode: 0x0C, modifiers: ctrl), .quit)
        XCTAssertEqual(s.command(forKeyCode: 0x03, modifiers: ctrl), .fullScreen)
        XCTAssertEqual(s.command(forKeyCode: 0x00, modifiers: [.command, .shift]), .soundEffects)
        XCTAssertEqual(s.command(forKeyCode: 0x2E, modifiers: ctrl), .music, "Music before Minimize (the Mac's Q4)")
        XCTAssertEqual(s.command(forKeyCode: 0x2E, modifiers: [.command, .option]), .minimizeAll)
        XCTAssertEqual(s.command(forKeyCode: 0x0C, modifiers: [.command, .capsLock]), .quit, "Caps Lock ignored")
    }

    func testNotShortcuts() {
        let s = WinShortcuts()
        XCTAssertNil(s.command(forKeyCode: 0x0C, modifiers: []), "no Ctrl")
        XCTAssertNil(s.command(forKeyCode: 0x0C, modifiers: [.command, .shift]), "exact modifiers")
        XCTAssertNil(s.command(forKeyCode: 0x0C, modifiers: [.command, .control]))
        XCTAssertNil(s.command(forKeyCode: 0x01, modifiers: ctrl))
        // The Mac bar's always-disabled items are no shortcuts: Select All, Undo, Cut, Copy, Paste — the game's keys.
        for code: UInt16 in [0x00, 0x06, 0x07, 0x08, 0x09] { XCTAssertNil(s.command(forKeyCode: code, modifiers: ctrl)) }
        XCTAssertNil(s.command(forKeyCode: 0x06, modifiers: [.command, .shift]), "Redo")
        // By physical key only: the key that types "q" on AZERTY (A's position, 0x00) is not Quit; the old "h"
        // (Hide) code is gone.
        XCTAssertNil(s.command(forKeyCode: 0x04, modifiers: ctrl))
    }

    func testEnableRules() {
        var s = WinShortcuts()
        s.playMenusEnabled = false                                     // `.enableMenus(false)`: a game runs
        XCTAssertNil(s.command(forKeyCode: 0x03, modifiers: ctrl), "Full Screen off in play")
        XCTAssertNil(s.command(forKeyCode: 0x2B, modifiers: ctrl), "Preferences off in play")
        XCTAssertEqual(s.command(forKeyCode: 0x0C, modifiers: ctrl), .quit, "Quit stays on")
        XCTAssertEqual(s.command(forKeyCode: 0x2E, modifiers: ctrl), .music)
        XCTAssertEqual(s.command(forKeyCode: 0x00, modifiers: [.command, .shift]), .soundEffects)
        s.playMenusEnabled = true
        s.dialogUp = true                                              // app-modal: every shortcut off
        for e in WinShortcuts.table {
            XCTAssertNil(s.command(forKeyCode: e.keyCode, modifiers: e.modifiers), "\(e.command) under a dialog")
        }
    }

    // MARK: The Options actions

    func testSoundAndMusicToggles() {
        var p = BTXPrefs.defaults
        p.sfxVolume = 3; p.lastSfxVolume = 3; p.musicVolume = 1; p.lastMusicVolume = 4
        WinShortcuts.apply(.soundEffects, to: &p)
        XCTAssertEqual(p.sfxVolume, 1)
        WinShortcuts.apply(.soundEffects, to: &p)
        XCTAssertEqual(p.sfxVolume, 3)
        WinShortcuts.apply(.music, to: &p)
        XCTAssertEqual(p.musicVolume, 4)
        WinShortcuts.apply(.music, to: &p)
        XCTAssertEqual(p.musicVolume, 1)
        XCTAssertFalse(WinShortcuts.apply(.quit, to: &p))
    }

    func testFullScreenFlipsBackWhenTheSwitchFails() {
        var p = BTXPrefs.defaults
        p.fullScreen = false
        WinShortcuts.fullScreenChosen(&p) { XCTAssertTrue($0); return true }
        XCTAssertTrue(p.fullScreen)
        WinShortcuts.fullScreenChosen(&p) { _ in false }
        XCTAssertTrue(p.fullScreen)
    }
}
