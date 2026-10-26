import FerazelCore
import Foundation

/// MBAR 128's rules, shared by both shells (Phase W, WF3, Ruling 5; moved from the Mac's `FerazelMenus` unchanged in
/// result): which pick each File / Game item is, when an item is enabled (`.UpdateMenus`, M l. 28763–28792), and when a
/// ⌘-key equivalent is taken by the menu rather than falling through to the game's polled keys. The Mac's menu bar
/// asks these; Windows (no menu bar, D21) takes Ctrl + the same letters by them (`WinShortcuts`). Foundation +
/// FerazelCore only; compiled by the Mac app (`Ferazel/Shared`) and by `FerazelWinKit` (a symlink).
enum FerazelMenuRules {
    /// `.MainMenu`'s `GetKeys` letters (M l. 7388–7431): N, O / R, I / P, C, Q, X — Mac virtual key codes.
    static let mainMenuLetters: Set<Int> = Set([MainMenu.newGameKey, MainMenu.creditsKey, MainMenu.quitKey,
                                                MainMenu.jokeKey] + MainMenu.continueKeys + MainMenu.optionsKeys)

    /// The picks of MENU `id`'s items by 1-based item number: File (129) — New Game, Restore Game..., Abort Game,
    /// Quit; any other menu of the bar (Game, 130) — Music, Sound Effects, Preferences…. Separators and the rest pick
    /// nothing. (MENU 128, the Apple menu, is built by the Mac shell itself: About only.)
    static func picks(menu id: Int16) -> [Int: PauseRun.MenuItem] {
        id == 129 ? [1: .newGame, 2: .restoreGame, 4: .abortGame, 6: .quit]
                  : [1: .music, 2: .soundEffects, 4: .preferences]
    }

    /// `.UpdateMenus`' enables: nothing outside the menu loops (`MenuState.menusLive`) or while a dialog or a file
    /// panel is up; not paused — New Game and Restore Game on, Abort Game off; paused — the reverse; the rest always.
    static func enabled(_ item: PauseRun.MenuItem, state: MenuState, modalUp: Bool) -> Bool {
        guard state.menusLive, !modalUp else { return false }
        switch item {
        case .newGame, .restoreGame: return !state.paused
        case .abortGame: return state.paused
        case .quit, .about, .music, .soundEffects, .preferences: return true
        }
    }

    /// Whether the ⌘-key equivalent of `item`, typed on the physical key `keyCode`, is taken by the menu: only when
    /// the item is enabled — and, in the main menu (live, not paused), not when the key is one of its polled letters
    /// (`.MainMenu`'s `GetKeys` block runs before the pass's `.CheckEvent`, so the letter acts as the polled key).
    /// Otherwise the key goes on to the game's polled keys (a level's ⌘Q / ⌘W / ⌘P).
    static func takesKeyEquivalent(_ item: PauseRun.MenuItem, keyCode: Int, state: MenuState, modalUp: Bool) -> Bool {
        guard enabled(item, state: state, modalUp: modalUp) else { return false }
        if state.menusLive && !state.paused, mainMenuLetters.contains(keyCode) { return false }
        return true
    }

    /// One ⌘-key equivalent of the bar: the MENU item's key (lowercased) and its pick.
    struct KeyEquivalent: Equatable {
        let key: String
        let item: PauseRun.MenuItem
    }

    /// The File and Game menus' key equivalents as the MENU resources store them (`MenuTemplate.Item.keyEquivalent`),
    /// in the bar's order (MBAR 128; the first match of a key wins, as AppKit searches the bar). The Apple menu has
    /// none the game uses (About has no key).
    static func keyEquivalents(resources: FerazelResources) -> [KeyEquivalent] {
        let ids = (try? MenuBarTemplate.load(from: resources, id: 128).menuIDs) ?? [128, 129, 130]
        var out: [KeyEquivalent] = []
        for id in ids {
            guard let m = try? MenuTemplate.load(from: resources, id: id), m.title != "\u{14}" else { continue }
            let picks = picks(menu: id)
            for (i, item) in m.items.enumerated() where item.name != "-" {
                guard let pick = picks[i + 1], let key = item.keyEquivalent?.lowercased(), !key.isEmpty else { continue }
                out.append(KeyEquivalent(key: key, item: pick))
            }
        }
        return out
    }
}
