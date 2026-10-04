import AppKit
import BubbleTroubleCore

/// The menu bar (plan task A3): `English.lproj/main.nib` "MenuBar" (`IBCarbonFramework`, `objects.xib`), which
/// `_LoadMenuBar @ 000084d7` installs with `SetMenuBarFromNib` before the event loop, transcribed item by item — titles,
/// key equivalents (an upper-case letter carries Shift, as the nib's own Redo `Z` does; modifier masks are the nib's
/// Cocoa-valued `keyEquivalentModifier`), separators, check marks, the Window menu's dynamic (⌥) pairs. Nib object ids
/// are cited per item.
///
/// Not built (Known delta 1, Invariant 5): "Register Bubble Trouble X…" (`Regi`, id 269) and "Check for Updates…"
/// (`Upda`, id 270); the separators they leave doubled collapse into one. The application menu's tail — Services,
/// Hide, Hide Others, Show All, Quit — is not in the nib: Carbon appended it to `_NSAppleMenu` (the decompile reaches
/// its Hide items by command, `'hide'` / `'hido'`, in `_GoFullScreenMode @ 0000fb21`), so it is built here as Carbon
/// supplied it. About shows the standard panel with `AboutCredits1.rtf` (Known delta 1: the ASW About-box bundle).
///
/// AppKit's own additions are suppressed as D4.3 rules (Aki precedent): "Settings…" is renamed back to the nib's
/// "Preferences…" a run-loop turn after install and in validation; the Edit items the nib did not build (AutoFill) are
/// removed; Start Dictation… / Emoji & Symbols are switched off by the defaults `BTXMain` registers; the Window
/// menu's tiling items are left (no switch exists).
@MainActor final class BTXMenus: NSObject, NSMenuItemValidation {
    let bar = NSMenu(title: "main")                                         // id 29, `_NSMainMenu`
    /// Menu 131 (`gOptionsMenu = GetMenuHandle(0x83)`, id 258) and its items.
    private let optionsMenu = NSMenu(title: "Options")
    private var fullScreenItem: NSMenuItem!                                 // item 1, id 259
    private var soundItem: NSMenuItem!                                      // item 3, id 260
    private var musicItem: NSMenuItem!                                      // item 4, id 261
    /// `gKeySetsSubMenu`: `CreateNewMenu(0x8c)` + "Default", hung on Options item 6 (`_LoadMenuBar`).
    private let keySetsMenu = NSMenu(title: "Key Sets")
    private var preferencesItem: NSMenuItem!
    private var hideItem: NSMenuItem!
    private var hideOthersItem: NSMenuItem!
    private var editMenu: NSMenu!
    private var nibEditItems: [NSMenuItem] = []
    /// The nib's title for item 273, which AppKit renames "Settings…".
    static let preferencesTitle = "Preferences…"

    /// `DisableMenuCommand(0, 'abou')` in effect (`_RequestGame`; `_PauseGame` → `_DisableAboutMenu`; `_EnableAboutMenu`
    /// on resume and at the `_RequestGame` exit) — the session's `.disableAbout`.
    var aboutDisabled = false
    /// 'pref' and 'Full' enabled: off in play (`_PlayGame` 00018702 / 00018716), on while paused (`_PauseGame`) and
    /// after the game (`_PlayGame` 0001919b / 000191af) — the session's `.enableMenus`.
    var playMenusEnabled = true
    /// Preferences… → `_PrefsButton @ 000084c6` (`_PrefsDialog` + `_UpdateMusicVolume`): task A4's Preferences window
    /// sets this. Until then the item validates disabled (there is nothing to show).
    var preferencesHandler: (() -> Void)?

    private unowned let controller: BTXController
    private let assets: BTXAssets

    private enum Target { case menus, firstResponder, object(AnyObject) }

    init(controller: BTXController, assets: BTXAssets) {
        self.controller = controller
        self.assets = assets
        super.init()
        bar.addItem(submenuItem(appMenu()))                                 // 185
        bar.addItem(submenuItem(makeEditMenu()))                            // 152
        bar.addItem(submenuItem(makeOptionsMenu()))                         // 257
        bar.addItem(submenuItem(windowMenu()))                              // 192
    }

    /// Call right after `NSApp.mainMenu = bar`: the Window menu becomes AppKit's (Carbon's `_NSWindowsMenu`), and the
    /// D4.3 restore runs a turn later (an immediate re-set does not stick, measured on Aki).
    func installed() {
        NSApp.windowsMenu = bar.items.last?.submenu
        perform(#selector(restoreNibItems), with: nil, afterDelay: 0)
    }

    // MARK: The nib's menus

    /// Menu 128 "Bubble Trouble X" (id 184, `_NSAppleMenu`): About (227, modifier 0) · [Register, 269] · — (228) ·
    /// [Check for Updates, 270] · — (271) · Preferences… ⌘, (273) · — (272); then Carbon's tail.
    private func appMenu() -> NSMenu {
        let menu = NSMenu(title: "Bubble Trouble X")
        add(menu, "About Bubble Trouble X", modifiers: [], action: #selector(about(_:)))
        menu.addItem(.separator())                                          // 228 (271 collapses into it)
        preferencesItem = add(menu, Self.preferencesTitle, ",", action: #selector(preferences(_:)))
        menu.addItem(.separator())                                          // 272
        // Carbon's application-menu tail.
        let services = NSMenu(title: "Services")
        add(menu, "Services").submenu = services
        NSApp.servicesMenu = services
        menu.addItem(.separator())
        hideItem = add(menu, "Hide Bubble Trouble X", "h", action: #selector(NSApplication.hide(_:)),
                       target: .object(NSApp))
        hideOthersItem = add(menu, "Hide Others", "h", modifiers: [.command, .option],
                             action: #selector(NSApplication.hideOtherApplications(_:)), target: .object(NSApp))
        add(menu, "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), target: .object(NSApp))
        menu.addItem(.separator())
        // Quit stays enabled in play (only 'pref' and 'Full' are disabled); A1's routing lets a game quit its own way.
        add(menu, "Quit Bubble Trouble X", "q", action: #selector(BTXController.quitChosen(_:)),
            target: .object(controller))
        return menu
    }

    /// Menu 130 "Edit" (id 147) — the standard commands, to the first responder (the dialogs' text fields).
    private func makeEditMenu() -> NSMenu {
        let menu = NSMenu(title: "Edit")
        add(menu, "Undo", "z", action: Selector(("undo:")), target: .firstResponder)                // 141 'undo'
        add(menu, "Redo", "Z", action: Selector(("redo:")), target: .firstResponder)                // 146 'redo'
        menu.addItem(.separator())                                                                   // 142
        add(menu, "Cut", "x", action: #selector(NSText.cut(_:)), target: .firstResponder)           // 143 'cut '
        add(menu, "Copy", "c", action: #selector(NSText.copy(_:)), target: .firstResponder)         // 149 'copy'
        add(menu, "Paste", "v", action: #selector(NSText.paste(_:)), target: .firstResponder)       // 144 'past'
        add(menu, "Delete", action: #selector(NSText.delete(_:)), target: .firstResponder)          // 151 'clea'
        add(menu, "Select All", "a", action: #selector(NSText.selectAll(_:)), target: .firstResponder) // 148 'sall'
        menu.addItem(.separator())                                                                   // 199
        add(menu, "Special Characters…", action: #selector(NSApplication.orderFrontCharacterPalette(_:)),
            target: .firstResponder)                                                                 // 198 'chrp'
        editMenu = menu
        nibEditItems = menu.items
        return menu
    }

    /// Menu 131 "Options" (id 258): Full Screen ⌘F (259 'Full') · — (262) · Sound Effects ⇧⌘A ✓ (260 'Soun') · Music ⌘M ✓
    /// (261 'Musi') · — (263) · Key Sets ▸ (265 'KeyS'; submenu 140 built at run time).
    private func makeOptionsMenu() -> NSMenu {
        let menu = optionsMenu
        fullScreenItem = add(menu, "Full Screen", "f", action: #selector(fullScreen(_:)))
        menu.addItem(.separator())
        soundItem = add(menu, "Sound Effects", "A", action: #selector(soundEffects(_:)))
        soundItem.state = .on
        musicItem = add(menu, "Music", "m", action: #selector(music(_:)))
        musicItem.state = .on
        menu.addItem(.separator())
        add(menu, "Key Sets").submenu = keySetsMenu
        add(keySetsMenu, "Default", action: #selector(keySet(_:)))           // `_LoadMenuBar`: cf "Default"
        return menu
    }

    /// "Window" (id 195, `_NSWindowsMenu`): Minimize ⌘M (190 'mini', dynamic) / Minimize All ⌥⌘M (191 'mina', its ⌥
    /// alternate) · Zoom (197 'zoom') · — (194) · Bring All to Front (196 'bfrt', dynamic) / Arrange in Front (193
    /// 'frnt', ⌥ alternate; AppKit has no arranging variant, so both bring the windows forward). ⌘M is also Options ▸
    /// Music: the first match in the bar wins (Q4 default — Music). The window is titled only (R5), so Minimize and
    /// Zoom validate disabled.
    private func windowMenu() -> NSMenu {
        let menu = NSMenu(title: "Window")
        add(menu, "Minimize", "m", action: #selector(NSWindow.performMiniaturize(_:)), target: .firstResponder)
        add(menu, "Minimize All", "m", modifiers: [.command, .option],
            action: #selector(NSApplication.miniaturizeAll(_:)), target: .object(NSApp)).isAlternate = true
        add(menu, "Zoom", action: #selector(NSWindow.performZoom(_:)), target: .firstResponder)
        menu.addItem(.separator())
        add(menu, "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), target: .object(NSApp))
        add(menu, "Arrange in Front", modifiers: [.command, .option],
            action: #selector(NSApplication.arrangeInFront(_:)), target: .object(NSApp)).isAlternate = true
        return menu
    }

    // MARK: `_ResetOptionsMenu @ 00008625`

    /// Rebuilds the Key Sets submenu and sets the Options marks from `prefs` (`_InitMac` at launch; A4 calls it after
    /// the Preferences window, as `_PrefsDialog` does): items after "Default" deleted; "Default" unmarked; with more than
    /// one set (short 0x37) a separator and the names of sets 2…n; the mark on short 0x38's item (+1 past the
    /// separator); Full Screen ✓ = bool 0x37; Sound Effects ✓ = short 0x33 ≠ 1; Music ✓ = short 0x35 ≠ 1. (Item 6 is
    /// disabled only for InputSprockets — not built, Known delta 5.)
    func resetOptionsMenu(_ prefs: BTXPrefs) {
        while keySetsMenu.items.count > 1 { keySetsMenu.removeItem(at: keySetsMenu.items.count - 1) }
        keySetsMenu.items[0].state = .off
        let count = min(prefs.keySetCount, 20)
        if count > 1 {
            keySetsMenu.addItem(.separator())
            for n in 2...count { add(keySetsMenu, prefs.keySet(n).name, action: #selector(keySet(_:))) }
        }
        markKeySet(prefs.currentKeySetIndex, on: true)
        fullScreenItem.state = prefs.fullScreen ? .on : .off
        soundItem.state = prefs.sfxVolume == 1 ? .off : .on
        musicItem.state = prefs.musicVolume == 1 ? .off : .on
    }

    /// `SetItemMark(gKeySetsSubMenu, set > 1 ? set + 1 : set, …)`.
    private func markKeySet(_ set: Int, on: Bool) {
        let index = (set > 1 ? set + 1 : set) - 1
        guard keySetsMenu.items.indices.contains(index) else { return }
        keySetsMenu.items[index].state = on ? .on : .off
    }

    // MARK: `_HandleMenuChoice @ 0000a482`

    /// Menu 128 item 1: `_SetMyCCursor(200)`, then the About box (the standard panel with `AboutCredits1.rtf`).
    @objc func about(_ sender: Any?) {
        NSCursor.pointingHand.set()
        var options: [NSApplication.AboutPanelOptionKey: Any] = [:]
        if let url = assets.url("English.lproj/AboutCredits1.rtf"),
           let credits = try? NSAttributedString(url: url, options: [:], documentAttributes: nil) {
            options[.credits] = credits
        }
        NSApp.orderFrontStandardAboutPanel(options: options)
    }

    /// Menu 128 item 6 → `_PrefsButton`.
    @objc func preferences(_ sender: Any?) {
        preferencesHandler?()
    }

    /// Menu 131 item 1: bool 0x37 flipped and marked, then `_GoFullScreenMode` / `_GoWindowMode`; a failed switch flips
    /// it back; the window is redrawn; `_SaveGamePrefs`.
    @objc func fullScreen(_ sender: Any?) {
        var prefs = controller.currentPrefs
        prefs.fullScreen.toggle()
        fullScreenItem.state = prefs.fullScreen ? .on : .off
        if !controller.setFullScreen(prefs.fullScreen) {
            prefs.fullScreen.toggle()
            fullScreenItem.state = prefs.fullScreen ? .on : .off
        }
        controller.menuChangedPrefs(prefs)
    }

    /// Menu 131 item 3: short 0x33 = 1 → restore short 0x34 (✓); else store 1 (no ✓). `_UpdateSoundVol` is empty — the
    /// next `_PlayMySnd` reads the pref. `_SaveGamePrefs`.
    @objc func soundEffects(_ sender: Any?) {
        var prefs = controller.currentPrefs
        if prefs.sfxVolume == 1 {
            prefs.sfxVolume = prefs.lastSfxVolume
            soundItem.state = .on
        } else {
            prefs.sfxVolume = 1
            soundItem.state = .off
        }
        controller.menuChangedPrefs(prefs)
    }

    /// Menu 131 item 4: short 0x35 = 1 → restore short 0x36 (✓); else store 1 (no ✓). `_UpdateMusicStatus` (empty),
    /// `_UpdateMusicVolume`, `_SaveGamePrefs`.
    @objc func music(_ sender: Any?) {
        var prefs = controller.currentPrefs
        if prefs.musicVolume == 1 {
            prefs.musicVolume = prefs.lastMusicVolume
            musicItem.state = .on
        } else {
            prefs.musicVolume = 1
            musicItem.state = .off
        }
        controller.menuChangedPrefs(prefs, updateMusicVolume: true)
    }

    /// Menu 140 item n: the old mark cleared; short 0x38 = n > 2 ? n − 1 : n; `_InitControls`; marked; `_SaveGamePrefs`.
    @objc func keySet(_ sender: NSMenuItem) {
        var prefs = controller.currentPrefs
        markKeySet(prefs.currentKeySetIndex, on: false)
        let item = keySetsMenu.index(of: sender) + 1
        prefs.currentKeySetIndex = item > 2 ? item - 1 : item
        markKeySet(prefs.currentKeySetIndex, on: true)
        controller.menuChangedPrefs(prefs)
    }

    /// `_GoFullScreenMode` clears the Hide and Hide Others command keys (saving them) once the display is captured;
    /// `_GoWindowMode` puts them back.
    func setHideKeysCleared(_ cleared: Bool) {
        hideItem.keyEquivalent = cleared ? "" : "h"
        hideOthersItem.keyEquivalent = cleared ? "" : "h"
    }

    // MARK: Enabling

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(about(_:)):
            return !aboutDisabled
        case #selector(preferences(_:)):
            if menuItem.title != Self.preferencesTitle { menuItem.title = Self.preferencesTitle }
            return playMenusEnabled && preferencesHandler != nil
        case #selector(fullScreen(_:)):
            return playMenusEnabled
        default:
            return true
        }
    }

    /// D4.3: the nib's "Preferences…" back over AppKit's "Settings…"; every Edit item the nib did not build removed.
    @objc private func restoreNibItems() {
        if preferencesItem.title != Self.preferencesTitle { preferencesItem.title = Self.preferencesTitle }
        for item in editMenu.items where !nibEditItems.contains(where: { $0 === item }) {
            editMenu.removeItem(item)
        }
    }

    // MARK: Building

    private func submenuItem(_ menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: menu.title, action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }

    /// One item (⌘ unless `modifiers` says otherwise); `target` defaults to this object, which carries the commands
    /// `_HandleMenuChoice` handles.
    @discardableResult
    private func add(_ menu: NSMenu, _ title: String, _ key: String = "", modifiers: NSEvent.ModifierFlags = .command,
                     action: Selector? = nil, target: Target = .menus) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.keyEquivalentModifierMask = modifiers
        if action != nil {
            switch target {
            case .menus: item.target = self
            case .firstResponder: item.target = nil
            case let .object(object): item.target = object
            }
        }
        menu.addItem(item)
        return item
    }
}
