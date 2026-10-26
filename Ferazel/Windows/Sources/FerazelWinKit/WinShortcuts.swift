import FerazelCore
import Foundation

/// MBAR 128's commands without a menu bar (D21, Ruling 5): **Ctrl alone** (no Shift, Alt or Windows key — the Mac takes
/// a shortcut only with ⌘ and no other modifier, `FerazelMenus.menuHasKeyEquivalent`) + a letter the MENU resources give
/// as a key equivalent (today N / O / W / Q / M / F / P), taken by the shared `FerazelMenuRules` exactly where the Mac's
/// menus would take it. A key nothing takes is the game's (⌘ + the letter in the polled keys, as on the Mac). The
/// letter is matched by its physical key on a US layout (the key code SDL reports, D18.5), so a non-US layout cannot
/// move or double a shortcut.
struct WinShortcuts: Equatable {
    struct Entry: Equatable {
        /// The MENU item's key equivalent, lowercased.
        let letter: String
        /// Its key on a US layout (Carbon `kVK_ANSI_*`).
        let keyCode: UInt16
        let item: PauseRun.MenuItem
    }

    /// In the bar's order (the first entry of a key wins, as AppKit searches the bar).
    let entries: [Entry]

    init(entries: [Entry]) {
        self.entries = entries
    }

    /// From MBAR 128 / MENU 129–130 (`FerazelMenuRules.keyEquivalents`); a letter with no US key is dropped.
    init(resources: FerazelResources) {
        entries = FerazelMenuRules.keyEquivalents(resources: resources).compactMap { k in
            guard let code = WinKeyNames.table[k.key]?.code else { return nil }
            return Entry(letter: k.key, keyCode: code, item: k.item)
        }
    }

    /// The command a key-down picks: Ctrl alone (Caps Lock ignored) + an entry's key, when the shared rules say the
    /// menu takes it (`menus` = the flow's last `MenuState`, `modalUp` = a dialog or a file dialog is up). Nil = the
    /// key is the game's.
    func take(keyCode: UInt16, modifiers: WinModifiers, menus: MenuState, modalUp: Bool) -> PauseRun.MenuItem? {
        guard modifiers.subtracting(.capsLock) == .command,
              let e = entries.first(where: { $0.keyCode == keyCode }),
              FerazelMenuRules.takesKeyEquivalent(e.item, keyCode: Int(keyCode), state: menus, modalUp: modalUp)
        else { return nil }
        return e.item
    }

    /// Alt+Enter (Return or the keypad's Enter, Alt alone): full screen on / off — the Mac's ⌃⌘F would be
    /// Windows+Ctrl+F, a system key, and Ctrl+F is ⌘F = Sound Effects (Ruling 14).
    static func isFullScreenToggle(keyCode: UInt16, modifiers: WinModifiers) -> Bool {
        (keyCode == 0x24 || keyCode == 0x4C) && modifiers.subtracting(.capsLock) == .option
    }
}
