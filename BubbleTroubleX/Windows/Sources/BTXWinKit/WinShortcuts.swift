import BubbleTroubleCore
import Foundation

/// The Mac menu bar's key equivalents, kept without the bar (D21: the Windows build draws no menu bar — Ben,
/// 2026-10-06). `BubbleTroubleX/App/BTXMenus.swift`'s shortcuts with their enable rules, ⌘ → Ctrl:
///
/// | Keys | Mac item | Enabled (`BTXMenus.validateMenuItem`) |
/// |---|---|---|
/// | Ctrl+, | Bubble Trouble X ▸ Preferences… | `.enableMenus` on |
/// | Ctrl+Q | Bubble Trouble X ▸ Quit | always |
/// | Ctrl+F | Options ▸ Full Screen | `.enableMenus` on |
/// | Ctrl+Shift+A | Options ▸ Sound Effects | always |
/// | Ctrl+M | Options ▸ Music (it comes before Window ▸ Minimize in the bar, so it wins ⌘M — the Mac's Q4) | always |
/// | Ctrl+Alt+M | Window ▸ Minimize All (the ⌥ alternate) — nothing happens, the key is only eaten, as on the Mac | always |
///
/// Every one is off while a dialog is up (Carbon `ModalDialog` is app-modal). A disabled shortcut — or one the Mac
/// bar had but always disabled (Edit's Undo/Redo/Cut/Copy/Paste/Select All, Window ▸ Minimize) — is no shortcut:
/// the key belongs to the game, as an unhandled key equivalent does on the Mac.
public enum ShortcutCommand: Equatable, Hashable, Sendable {
    /// `BTXController.preferencesChosen`.
    case preferences
    /// `BTXController.quitChosen` (its four routes).
    case quit
    /// `BTXMenus.fullScreen`: see `WinShortcuts.fullScreenChosen`.
    case fullScreen
    /// `BTXMenus.soundEffects`: see `WinShortcuts.apply(_:to:)`.
    case soundEffects
    /// `BTXMenus.music`: see `WinShortcuts.apply(_:to:)` (+ `_UpdateMusicVolume`).
    case music
    /// `miniaturizeAll` on a window that cannot miniaturize: nothing happens.
    case minimizeAll
}

/// The shortcuts' live enable state and the key → command table.
public struct WinShortcuts: Equatable, Sendable {
    /// `.enableMenus(on)` — Preferences… and Full Screen.
    public var playMenusEnabled = true
    /// A dialog is up: every shortcut is off until it goes.
    public var dialogUp = false

    public init() {}

    /// When a shortcut is enabled.
    public enum Rule: Equatable, Sendable {
        case always
        /// `.enableMenus` (Preferences…, Full Screen).
        case playMenus
    }

    public struct Entry: Equatable, Sendable {
        /// Carbon `kVK_ANSI_*` code of the PHYSICAL key (HectorSDL reports US/ANSI positions, D18.5).
        public var keyCode: UInt16
        /// The exact modifiers (Ctrl arrives as `.command`, Alt as `.option`); Caps Lock is ignored.
        public var modifiers: WinModifiers
        public var command: ShortcutCommand
        public var rule: Rule
    }

    /// In the Mac bar's order (the first match wins).
    public static let table: [Entry] = [
        Entry(keyCode: 0x2B, modifiers: .command, command: .preferences, rule: .playMenus),         // ,
        Entry(keyCode: 0x0C, modifiers: .command, command: .quit, rule: .always),                   // q
        Entry(keyCode: 0x03, modifiers: .command, command: .fullScreen, rule: .playMenus),          // f
        Entry(keyCode: 0x00, modifiers: [.command, .shift], command: .soundEffects, rule: .always), // A
        Entry(keyCode: 0x2E, modifiers: .command, command: .music, rule: .always),                  // m
        Entry(keyCode: 0x2E, modifiers: [.command, .option], command: .minimizeAll, rule: .always), // ⌥m
    ]

    public func isEnabled(_ rule: Rule) -> Bool {
        if dialogUp { return false }
        switch rule {
        case .always: return true
        case .playMenus: return playMenusEnabled
        }
    }

    /// The command a key press chooses: the entry whose physical key and exact modifiers match (the typed character
    /// never chooses, so a non-US layout cannot move or double a shortcut — D18.5). Nil when nothing matches or the
    /// match is disabled (the key then belongs to the game).
    public func command(forKeyCode keyCode: UInt16, modifiers: WinModifiers) -> ShortcutCommand? {
        let mods = modifiers.subtracting(.capsLock)
        guard let e = Self.table.first(where: { $0.keyCode == keyCode && $0.modifiers == mods }) else { return nil }
        return isEnabled(e.rule) ? e.command : nil
    }

    // MARK: The Options actions

    /// The prefs half of Sound Effects and Music (`BTXMenus.soundEffects` / `music`): the pref toggled between off (1)
    /// and its last on level. The driver then does `shortcutChangedPrefs` (Music: with `_UpdateMusicVolume`). Returns
    /// false for any other command.
    @discardableResult
    public static func apply(_ command: ShortcutCommand, to prefs: inout BTXPrefs) -> Bool {
        switch command {
        case .soundEffects:
            prefs.sfxVolume = prefs.sfxVolume == 1 ? prefs.lastSfxVolume : 1
        case .music:
            prefs.musicVolume = prefs.musicVolume == 1 ? prefs.lastMusicVolume : 1
        default:
            return false
        }
        return true
    }

    /// Full Screen (`BTXMenus.fullScreen`): bool 0x37 flipped, the switch tried, flipped back if it failed. The driver
    /// then does `shortcutChangedPrefs`.
    public static func fullScreenChosen(_ prefs: inout BTXPrefs, setFullScreen: (Bool) -> Bool) {
        prefs.fullScreen.toggle()
        if !setFullScreen(prefs.fullScreen) { prefs.fullScreen.toggle() }
    }
}
