import BubbleTroubleCore
import Foundation

/// The in-window menu bar's model (plan W5, D15.3): `BubbleTroubleX/App/BTXMenus.swift` transcribed item by item —
/// titles, order, separators, enable rules, check marks, key equivalents (⌘ → Ctrl), the Key Sets submenu that
/// `_ResetOptionsMenu` rebuilds, the Window menu's ⌥ alternates — minus what only macOS supplies:
///
/// - the Apple menu (the system's, not the app's);
/// - the application menu's Carbon tail — Services (the system's services), Hide Bubble Trouble X ⌘H, Hide Others ⌥⌘H,
///   Show All (other applications' windows) — and with them `setHideKeysCleared` (full screen clears only those keys);
///   the separators they leave doubled collapse into one, so Quit follows Preferences…'s separator;
/// - Edit ▸ Special Characters… (`orderFrontCharacterPalette:`, the macOS character viewer) and its separator;
/// - AppKit's own additions that D4.3 already suppresses on the Mac (Settings…, AutoFill, Dictation, Emoji, Window
///   tiling items) are not built at all.
///
/// The application menu keeps the Mac app menu's title ("Bubble Trouble X") and its nib items: About · — ·
/// Preferences… Ctrl+, · — · Quit Bubble Trouble X Ctrl+Q (Quit stays there, as on the Mac). Edit and Window keep
/// their nib items and rules even where Windows makes them inert (see `MenuCommand`), so the bar looks as the Mac's.

/// Modifier keys as the menu sees them: HectorSDL maps Ctrl → ⌘ (`command`), Alt → ⌥ (`option`), the Windows key →
/// ⌃ (`control`), Shift → ⇧ (D18.5).
public struct MenuModifiers: OptionSet, Hashable, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let command = MenuModifiers(rawValue: 1)
    public static let shift = MenuModifiers(rawValue: 2)
    public static let option = MenuModifiers(rawValue: 4)
    public static let control = MenuModifiers(rawValue: 8)
}

/// One command per actionable item, for the driver to execute as the Mac item's action does.
public enum MenuCommand: Equatable, Hashable, Sendable {
    /// Bubble Trouble X ▸ About — `BTXMenus.about`: hand cursor, the About box.
    case about
    /// Bubble Trouble X ▸ Preferences… — `BTXController.preferencesChosen`.
    case preferences
    /// Bubble Trouble X ▸ Quit — `BTXController.quitChosen` (its four routes).
    case quit
    /// Edit — the first responder's standard commands. No responder in the game window implements them and a dialog
    /// disables the whole bar (`dialogUp`), so on the Mac they always validate disabled; kept for the bar's look.
    case undo, redo, cut, copy, paste, delete, selectAll
    /// Options ▸ Full Screen — `BTXMenus.fullScreen`: see `MenuBar.fullScreenChosen`.
    case fullScreen
    /// Options ▸ Sound Effects — `BTXMenus.soundEffects`: see `MenuBar.apply(_:to:)`.
    case soundEffects
    /// Options ▸ Music — `BTXMenus.music`: see `MenuBar.apply(_:to:)` (+ `_UpdateMusicVolume`).
    case music
    /// Options ▸ Key Sets ▸ set n (1…20) — `BTXMenus.keySet`: see `MenuBar.apply(_:to:)`.
    case keySet(Int)
    /// Window ▸ Minimize / Zoom. On the Mac they validate disabled (the window is titled only, R5); the Windows window
    /// is resizable and minimizable (W4.5), so here they work: Minimize minimizes it, Zoom toggles between 1× and the
    /// largest integer scale that fits the screen.
    case minimize, zoom
    /// Window ▸ Minimize All (⌥ alternate of Minimize) — `miniaturizeAll`: the only window cannot miniaturize, so
    /// nothing happens on the Mac.
    case minimizeAll
    /// Window ▸ Bring All to Front / Arrange in Front (its ⌥ alternate) — `arrangeInFront`: the window comes forward.
    case bringAllToFront, arrangeInFront
}

/// When an item is enabled (`BTXMenus.validateMenuItem`); every rule is off while a dialog is up.
public enum MenuEnableRule: Equatable, Sendable {
    /// Always (Quit, the toggles, Key Sets, the Window menu's NSApp items).
    case always
    /// `!aboutDisabled` — the session's `.disableAbout`.
    case about
    /// `playMenusEnabled` — the session's `.enableMenus` (Full Screen).
    case playMenus
    /// `playMenusEnabled && preferencesHandler != nil` (Preferences…).
    case preferences
    /// Never (Edit's first-responder items).
    case never
}

/// A ⌥ alternate (`isAlternate`): shown in place of its item while Alt is held.
public struct MenuAlternate: Equatable, Sendable {
    public var title: String
    public var key: Character?
    public var modifiers: MenuModifiers
    public var command: MenuCommand
    public var rule: MenuEnableRule

    public var effectiveModifiers: MenuModifiers {
        guard let key else { return [] }
        return key.isUppercase ? modifiers.union(.shift) : modifiers
    }
}

public struct MenuItem: Equatable, Sendable {
    public var title: String
    /// The key equivalent as the nib writes it: an upper-case letter carries Shift (Redo `Z`, Sound Effects `A`).
    public var key: Character?
    public var modifiers: MenuModifiers
    public var command: MenuCommand?
    public var rule: MenuEnableRule
    public var checked: Bool
    public var submenu: BarMenu?
    public var alternate: MenuAlternate?

    public init(_ title: String, key: Character? = nil, modifiers: MenuModifiers = .command,
                command: MenuCommand?, rule: MenuEnableRule = .always, checked: Bool = false,
                submenu: BarMenu? = nil, alternate: MenuAlternate? = nil) {
        self.title = title; self.key = key; self.modifiers = modifiers; self.command = command; self.rule = rule
        self.checked = checked; self.submenu = submenu; self.alternate = alternate
    }

    /// The modifiers the key equivalent needs: the stated ones, plus Shift for an upper-case letter.
    public var effectiveModifiers: MenuModifiers {
        guard let key else { return [] }
        return key.isUppercase ? modifiers.union(.shift) : modifiers
    }
}

public enum MenuEntry: Equatable, Sendable {
    case item(MenuItem)
    case separator

    public var item: MenuItem? { if case let .item(i) = self { return i } else { return nil } }
}

public struct BarMenu: Equatable, Sendable {
    public var title: String
    /// The application menu's title is drawn bold (as the Mac bar draws the app name).
    public var bold: Bool
    public var entries: [MenuEntry]
}

/// The bar's live state — `BTXMenus`' flags, marks and the Key Sets list — and the menus built from it.
public struct MenuBar: Equatable, Sendable {
    /// `.disableAbout(off)`.
    public var aboutDisabled = false
    /// `.enableMenus(on)` — Preferences… and Full Screen.
    public var playMenusEnabled = true
    /// The Mac disables Preferences… until a handler exists (A4); the Windows driver has one (W6), so true.
    public var preferencesAvailable = true
    /// A dialog is up: `ModalDialog` is app-modal — every item disabled until it goes.
    public var dialogUp = false
    /// Options marks (`_ResetOptionsMenu`): Full Screen ✓ = bool 0x37, Sound Effects ✓ = short 0x33 ≠ 1, Music ✓ =
    /// short 0x35 ≠ 1. The nib starts the two sound items checked.
    public var fullScreenChecked = false
    public var soundChecked = true
    public var musicChecked = true
    /// Key sets 1…n by name; set 1's item is always "Default" (`_LoadMenuBar`), whatever its stored name.
    public var keySetNames: [String] = ["Default"]
    /// The marked set (short 0x38); 0 or out of range marks nothing.
    public var currentKeySet = 0

    public init() {}

    /// Mirrors `.enableMenus(on)` / `.disableAbout(off)` for the driver.
    public mutating func setEnabled(menusEnabled on: Bool) { playMenusEnabled = on }
    public mutating func disableAbout(_ off: Bool) { aboutDisabled = off }

    // MARK: The menus

    public static let appMenuTitle = "Bubble Trouble X"

    public var menus: [BarMenu] {
        [
            BarMenu(title: Self.appMenuTitle, bold: true, entries: [
                .item(MenuItem("About Bubble Trouble X", modifiers: [], command: .about, rule: .about)),
                .separator,
                .item(MenuItem("Preferences…", key: ",", command: .preferences, rule: .preferences)),
                .separator,
                .item(MenuItem("Quit Bubble Trouble X", key: "q", command: .quit)),
            ]),
            BarMenu(title: "Edit", bold: false, entries: [
                .item(MenuItem("Undo", key: "z", command: .undo, rule: .never)),
                .item(MenuItem("Redo", key: "Z", command: .redo, rule: .never)),
                .separator,
                .item(MenuItem("Cut", key: "x", command: .cut, rule: .never)),
                .item(MenuItem("Copy", key: "c", command: .copy, rule: .never)),
                .item(MenuItem("Paste", key: "v", command: .paste, rule: .never)),
                .item(MenuItem("Delete", command: .delete, rule: .never)),
                .item(MenuItem("Select All", key: "a", command: .selectAll, rule: .never)),
            ]),
            BarMenu(title: "Options", bold: false, entries: [
                .item(MenuItem("Full Screen", key: "f", command: .fullScreen, rule: .playMenus,
                               checked: fullScreenChecked)),
                .separator,
                .item(MenuItem("Sound Effects", key: "A", command: .soundEffects, checked: soundChecked)),
                .item(MenuItem("Music", key: "m", command: .music, checked: musicChecked)),
                .separator,
                .item(MenuItem("Key Sets", command: nil, submenu: keySetsMenu)),
            ]),
            BarMenu(title: "Window", bold: false, entries: [
                .item(MenuItem("Minimize", key: "m", command: .minimize,
                               alternate: MenuAlternate(title: "Minimize All", key: "m", modifiers: [.command, .option],
                                                        command: .minimizeAll, rule: .always))),
                .item(MenuItem("Zoom", command: .zoom)),
                .separator,
                .item(MenuItem("Bring All to Front", command: .bringAllToFront,
                               alternate: MenuAlternate(title: "Arrange in Front", key: nil,
                                                        modifiers: [.command, .option],
                                                        command: .arrangeInFront, rule: .always))),
            ]),
        ]
    }

    /// `gKeySetsSubMenu` as `_ResetOptionsMenu` leaves it: "Default"; with more than one set, a separator and the
    /// names of sets 2…n (at most 20); the current set marked.
    var keySetsMenu: BarMenu {
        var entries: [MenuEntry] = [.item(MenuItem("Default", command: .keySet(1), checked: currentKeySet == 1))]
        let count = min(keySetNames.count, 20)
        if count > 1 {
            entries.append(.separator)
            for n in 2...count {
                entries.append(.item(MenuItem(keySetNames[n - 1], command: .keySet(n), checked: currentKeySet == n)))
            }
        }
        return BarMenu(title: "Key Sets", bold: false, entries: entries)
    }

    // MARK: Enabling

    public func isEnabled(_ rule: MenuEnableRule) -> Bool {
        if dialogUp { return false }
        switch rule {
        case .always: return true
        case .about: return !aboutDisabled
        case .playMenus: return playMenusEnabled
        case .preferences: return playMenusEnabled && preferencesAvailable
        case .never: return false
        }
    }

    public func isEnabled(_ item: MenuItem) -> Bool { isEnabled(item.rule) }

    // MARK: Key equivalents

    /// Carbon `kVK_ANSI_*` codes of the keys the bar uses (HectorSDL reports physical US positions, D18.5).
    static let keyCodes: [Character: UInt16] = [
        "a": 0x00, "f": 0x03, "z": 0x06, "x": 0x07, "c": 0x08, "v": 0x09, "q": 0x0C, "m": 0x2E, ",": 0x2B,
    ]

    /// The command a key press chooses (Ctrl arrives as `.command`): the first item in bar order whose key
    /// equivalent and exact modifiers match (⌘M is both Music and Minimize — Music comes first, the Mac's Q4), the ⌥
    /// alternates included. Matched by the PHYSICAL key only (D18.5: the key the US/ANSI layout labels so — the typed
    /// character never chooses, so a non-US layout cannot move or double a shortcut). Nil when nothing matches or the
    /// matching item is disabled (the key then belongs to the game, as an unhandled key equivalent does on the Mac).
    public func command(forKeyCode keyCode: UInt16, modifiers: MenuModifiers) -> MenuCommand? {
        guard modifiers.contains(.command), !modifiers.contains(.control) else { return nil }
        func matches(_ key: Character?, _ needed: MenuModifiers) -> Bool {
            guard let key else { return false }
            return Self.keyCodes[Character(key.lowercased())] == keyCode && modifiers == needed
        }
        func search(_ entries: [MenuEntry]) -> (MenuCommand?, Bool)? {
            for case let .item(item) in entries {
                if matches(item.key, item.effectiveModifiers) {
                    return (item.command, isEnabled(item))
                }
                if let alt = item.alternate, matches(alt.key, alt.effectiveModifiers) {
                    return (alt.command, isEnabled(alt.rule))
                }
                if let sub = item.submenu, let found = search(sub.entries) { return found }
            }
            return nil
        }
        for menu in menus {
            if let (command, enabled) = search(menu.entries) { return enabled ? command : nil }
        }
        return nil
    }

    // MARK: `_ResetOptionsMenu` and the Options actions

    /// `_ResetOptionsMenu @ 00008625` (launch, and after the Preferences dialog): the Key Sets list rebuilt from the
    /// prefs and every Options mark set.
    public mutating func resetOptionsMenu(_ prefs: BTXPrefs) {
        let count = min(prefs.keySetCount, 20)
        keySetNames = ["Default"] + (count > 1 ? (2...count).map { prefs.keySet($0).name } : [])
        currentKeySet = prefs.currentKeySetIndex
        fullScreenChecked = prefs.fullScreen
        soundChecked = prefs.sfxVolume != 1
        musicChecked = prefs.musicVolume != 1
    }

    /// The prefs half of Sound Effects, Music and a key set (`BTXMenus.soundEffects` / `music` / `keySet`): the pref
    /// changed and the mark moved. The driver then does `menuChangedPrefs` (Music: with `_UpdateMusicVolume`).
    /// Returns false for any other command.
    @discardableResult
    public mutating func apply(_ command: MenuCommand, to prefs: inout BTXPrefs) -> Bool {
        switch command {
        case .soundEffects:
            if prefs.sfxVolume == 1 { prefs.sfxVolume = prefs.lastSfxVolume; soundChecked = true }
            else { prefs.sfxVolume = 1; soundChecked = false }
        case .music:
            if prefs.musicVolume == 1 { prefs.musicVolume = prefs.lastMusicVolume; musicChecked = true }
            else { prefs.musicVolume = 1; musicChecked = false }
        case let .keySet(n):
            prefs.currentKeySetIndex = n
            currentKeySet = n
        default:
            return false
        }
        return true
    }

    /// Full Screen (`BTXMenus.fullScreen`): bool 0x37 flipped and marked, the switch tried, flipped back if it failed.
    /// The driver then does `menuChangedPrefs`.
    public mutating func fullScreenChosen(_ prefs: inout BTXPrefs, setFullScreen: (Bool) -> Bool) {
        prefs.fullScreen.toggle()
        fullScreenChecked = prefs.fullScreen
        if !setFullScreen(prefs.fullScreen) {
            prefs.fullScreen.toggle()
            fullScreenChecked = prefs.fullScreen
        }
    }
}
