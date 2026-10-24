import AppKit
import FerazelCore

/// The menu bar (plan A1b): MBAR 128 = MENU 128 (Apple), 129 "File", 130 "Game" — `.InitMenus` (M l. 28745–28758:
/// `GetNewMBar`, `AppendResMenu(Apple, 'DRVR')`, `DrawMenuBar`) — built from the MENU resources (titles and ⌘ keys as
/// stored), every pick handed to `GameFlow.menuChosen` as `.HandleMenuSelection @ 10030398` dispatches it:
///
/// | menu | item | key | `.Handle…MenuSelection` | `PauseRun.MenuItem` |
/// |---|---|---|---|---|
/// | Apple (128) | 1 About Ferazel's Wand… | — | `.Credits` | `.about` |
/// | File (129) | 1 New Game | ⌘N | `*fd5c = 1`, `.NewGame` | `.newGame` |
/// | | 2 Restore Game... | ⌘O | `.ContinueGame(0)` | `.restoreGame` |
/// | | 4 Abort Game | ⌘W | `.AbortGame` | `.abortGame` |
/// | | 6 Quit | ⌘Q | `.Quit` | `.quit` |
/// | Game (130) | 1 Music | ⌘M | `.ToggleMusic` | `.music` |
/// | | 2 Sound Effects | ⌘F | `.ToggleSound` | `.soundEffects` |
/// | | 4 Preferences… | ⌘P | `.Options` | `.preferences` |
///
/// The Apple menu's items go into the macOS app menu, which keeps only About and the hidden Full Screen item (⌃⌘F;
/// the desk accessories `AppendResMenu` added are not built; the system Quit is File ▸ Quit — a Dock / logout quit
/// still goes through the flow's queued quit event). Enable rules, `.UpdateMenus` (M l. 28763–28792): not paused —
/// New Game and Restore Game enabled, Abort Game disabled; paused — the reverse; check marks Music = prefs+0x0c,
/// Sound Effects = prefs+0x0b (the flow's `MenuState`). **Menus act only where the original handled menu events**
/// (the flow's `MenuState.menusLive`: the main-menu loop and the pause loop) and never while a dialog is up; elsewhere every
/// item is disabled and its ⌘ key falls through to the game's polled keys (`GetKeys`: a level's ⌘Q / ⌘W / ⌘P).
/// In the main menu the ⌘ keys of its own letters (N, O, Q, P — `.MainMenu`'s `GetKeys` block runs before the pass's
/// `.CheckEvent`) fall through too, so they act as the polled letter (the button track, then the action).
@MainActor final class FerazelMenus: NSObject, NSMenuDelegate, NSMenuItemValidation {
    let bar = NSMenu(title: "main")
    /// What the flow last sent (`.UpdateMenus` and the menu loop's entry / exit): live, paused, the check marks — the
    /// one source for what the menu bar takes.
    private(set) var state = MenuState(menusLive: false, paused: false, musicOn: true, soundOn: true)
    private var musicItem: NSMenuItem?
    private var soundItem: NSMenuItem?

    /// A dialog or a file panel is up (no pick is taken).
    var modalUp: () -> Bool = { true }
    /// The game's polled main-menu letters are being read: the menu loop is live and not paused.
    private var inMainMenu: Bool { state.menusLive && !state.paused }
    /// A pick → `GameFlow.menuChosen`.
    var chosen: (PauseRun.MenuItem) -> Void = { _ in }

    /// `.MainMenu`'s `GetKeys` letters (M l. 7388–7431): N, O / R, I / P, C, Q, X.
    static let mainMenuLetters: Set<Int> = Set([MainMenu.newGameKey, MainMenu.creditsKey, MainMenu.quitKey,
                                                MainMenu.jokeKey] + MainMenu.continueKeys + MainMenu.optionsKeys)

    /// - Parameters:
    ///   - fullScreen: the hidden ⌃⌘F item (target and action), kept in the app menu.
    init(resources: FerazelResources, title: String, fullScreen: NSMenuItem) {
        super.init()
        let ids = (try? MenuBarTemplate.load(from: resources, id: 128).menuIDs) ?? [128, 129, 130]
        for id in ids {
            guard let m = try? MenuTemplate.load(from: resources, id: id) else { continue }
            let top = NSMenuItem()
            let menu: NSMenu
            // MENU 128's title is the single byte 0x14 (the Apple logo, R1): its items go into the app menu.
            if m.title == "\u{14}" {
                menu = NSMenu(title: title)
                for (i, item) in m.items.enumerated() where i == 0 {
                    add(item, to: menu, pick: .about)
                }
                menu.addItem(fullScreen)
            } else {
                menu = NSMenu(title: m.title)
                menu.delegate = self
                let picks: [Int: PauseRun.MenuItem] = id == 129
                    ? [1: .newGame, 2: .restoreGame, 4: .abortGame, 6: .quit]
                    : [1: .music, 2: .soundEffects, 4: .preferences]
                for (i, item) in m.items.enumerated() {
                    if item.name == "-" {
                        menu.addItem(.separator())
                        continue
                    }
                    guard let pick = picks[i + 1] else { continue }
                    let added = add(item, to: menu, pick: pick)
                    if pick == .music { musicItem = added }
                    if pick == .soundEffects { soundItem = added }
                }
            }
            top.submenu = menu
            bar.addItem(top)
        }
        update(state)
    }

    @discardableResult
    private func add(_ item: MenuTemplate.Item, to menu: NSMenu, pick: PauseRun.MenuItem) -> NSMenuItem {
        let i = NSMenuItem(title: item.name, action: #selector(picked(_:)), keyEquivalent: item.keyEquivalent?.lowercased() ?? "")
        i.keyEquivalentModifierMask = [.command]
        i.target = self
        i.representedObject = Pick(pick)
        menu.addItem(i)
        return i
    }

    /// `PauseRun.MenuItem` boxed for `representedObject`.
    private final class Pick: NSObject {
        let item: PauseRun.MenuItem
        init(_ item: PauseRun.MenuItem) { self.item = item }
    }

    /// `.UpdateMenus`' state: the check marks now; the enables at validation.
    func update(_ s: MenuState) {
        state = s
        musicItem?.state = s.musicOn ? .on : .off
        soundItem?.state = s.soundOn ? .on : .off
    }

    @objc private func picked(_ sender: Any?) {
        guard let p = (sender as? NSMenuItem)?.representedObject as? Pick, enabled(p.item) else { return }
        chosen(p.item)
    }

    private func enabled(_ item: PauseRun.MenuItem) -> Bool {
        guard state.menusLive, !modalUp() else { return false }
        switch item {
        case .newGame, .restoreGame: return !state.paused
        case .abortGame: return state.paused
        case .quit, .about, .music, .soundEffects, .preferences: return true
        }
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let p = menuItem.representedObject as? Pick else { return true }
        return enabled(p.item)
    }

    /// The File and Game menus' ⌘ keys: taken only when the item is enabled — and, in the main menu, not one of its
    /// polled letters; otherwise the key event goes on to the game window (the polled keys).
    func menuHasKeyEquivalent(_ menu: NSMenu, for event: NSEvent, target: AutoreleasingUnsafeMutablePointer<AnyObject?>,
                              action: UnsafeMutablePointer<Selector?>) -> Bool {
        let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
        guard flags == [.command], let key = event.charactersIgnoringModifiers?.lowercased(), !key.isEmpty else {
            return false
        }
        guard let item = menu.items.first(where: { $0.keyEquivalent == key }),
              let p = item.representedObject as? Pick, enabled(p.item) else { return false }
        if inMainMenu, Self.mainMenuLetters.contains(Int(event.keyCode)) { return false }
        keyPick = p.item
        target.pointee = self
        action.pointee = #selector(keyPicked(_:))
        return true
    }

    /// The item `menuHasKeyEquivalent` matched last (AppKit sends `keyPicked` right after it answers true).
    private var keyPick: PauseRun.MenuItem?

    @objc private func keyPicked(_ sender: Any?) {
        guard let item = keyPick else { return }
        keyPick = nil
        if enabled(item) { chosen(item) }
    }
}
