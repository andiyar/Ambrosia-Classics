import AkiCore
import Foundation
import HectorShell

/// `Controller` (method-map §1), its platform-neutral core: the owner of `_g`, `_p`, the GWorlds, the sound and
/// music, and the three screens; the idle / mouse / key dispatch by mode; the menu commands and their enable
/// state. The AppKit app delegate, window delegate and menu target is `AkiAppDelegate` (Mac); everything
/// platform-specific is reached through `host` (`AkiHost`, plan C2).
@MainActor final class AkiController {
    let g: AkiG
    let store: GameSettingsStore
    var p: GameSettings                                        // `_p`
    var assets: AkiAssets!
    var gworlds: AkiGWorlds!
    var sound: AkiSound!
    var music: AkiMusic!
    /// The platform shell (the Mac app delegate owns this controller and sets itself here).
    weak var host: (any AkiHost)!
    var mapScreen: MapScreen!; var gameScreen: AkiScreen?; var editorScreen: AkiScreen?   // P2.10 sets gameScreen, P3.4 editorScreen
    private(set) var gameScreenImpl: GameScreen!               // P2.10 — the one GameScreen (`gameScreen` points at it)
    var lastTimeCount: UInt32 = 0, lastMouseCount: UInt32 = 0, updateTimeCount: UInt32 = 0, flash: UInt32 = 0, lastTick: UInt32 = 0
    var lastMouse = ShellPoint.zero                            // ivar 0x50 (double-click guard, P2.11)
    /// Menu tags whose commands land in a later phase: `validateMenuItem` disables them after the 1.2
    /// rules (Known delta 3). Since P2.11 only Phase 3's commands remain (10–14, 16–19: the Level Editor and
    /// its commands, Play Custom Level, Replay); P3.4–P3.6 remove them as they land.
    static var notYetBuilt: Set<Int> = [10, 11, 12, 13, 14, 16, 17, 18, 19]

    init(store: GameSettingsStore = GameSettingsStore()) {
        g = AkiG()
        self.store = store
        p = .defaults
    }

    // MARK: Launch (the shared steps of -[Controller applicationDidFinishLaunching:], in its order)

    /// `_Initialize: _LoadPrefs`, then the assets every later step reads.
    func beginLaunch(assets: AkiAssets) {
        p = store.load()                                       // _Initialize: _LoadPrefs
        self.assets = assets
    }

    /// `_Initialize: _InitializeGWorlds`, the screens, `_InitializeSound`, `_InitializeMusic`.
    func loadLaunchResources() {
        do {
            gworlds = try AkiGWorlds(assets: assets)           // _Initialize: _InitializeGWorlds
        } catch {
            fatalError("Aki: cannot load the original art: \(error)")
        }
        mapScreen = MapScreen(controller: self)
        gameScreenImpl = GameScreen(controller: self)          // P2.10
        gameScreen = gameScreenImpl
        do {
            sound = try AkiSound(assets: assets, controller: self)   // _Initialize: _InitializeSound
            music = try AkiMusic(assets: assets, controller: self)   // _Initialize: _InitializeMusic
        } catch {
            fatalError("Aki: cannot load the original sounds: \(error)")
        }
    }

    /// `_Initialize`'s tail: `_RedrawMapScreen`, `_LoopMusic(1)`, `_PlayMovie(0x80)`. `g.lost` is false at
    /// launch (`AkiG`'s initial value), so `redrawMapScreen` shows no proverb and its continuation runs
    /// before it returns on every host — the steps after it need not move into it.
    func composeLaunchMap() {
        mapScreen.redrawMapScreen {}                           // _Initialize's tail: _RedrawMapScreen
        p.applyLaunchRegistration()                            // _LoopMusic(1): the replica is registered
        music.playMovie(0x80)                                  // _PlayMovie(0x80): Theme 3 when Music is on
    }

    /// The tick ivars 0x34…0x44 = TickCount(), and the map's blink / preview state, before the idle loop starts.
    func startLaunchClocks() {
        let now = ShellClock.ticks()                           // the tick ivars 0x34…0x44 = TickCount()
        lastTimeCount = now; lastMouseCount = now; updateTimeCount = now; flash = now; lastTick = now
        mapScreen.blink = AkiMap.Blink()                       // LastColor 0, ColorDown 1
        mapScreen.lastPreview = nil                            // −9
    }

    /// The tail of `-[Controller finishLaunch:]` @ 0x41d4 (DC:1200): on first launch (p+0x215) the flag is
    /// cleared and saved, then the "welcome" splash runs (no timeout). Nothing follows it.
    func showFirstLaunchWelcome() {
        if p.firstLaunch != 0 {
            p.firstLaunch = 0
            savePrefs()
            host.showSplash(named: "welcome", timeout: 0) {}
        }
    }

    // MARK: Screens

    /// The screen `g.mode` selects (`_g`+0x66 == 0 → map; `_g`+0x80 → editor; else the game).
    var currentScreen: AkiScreen? {
        switch g.mode {
        case .map: mapScreen
        case .game: gameScreen
        case .editor: editorScreen
        }
    }

    /// `-[Controller pause]` @ 0x3c1f: the current mode's pause (the map's is a no-op).
    func pause() {
        currentScreen?.pause()
    }

    /// `-[Controller unpause]`: the current mode's unpause (the map's is a no-op).
    func unpause() {
        currentScreen?.unpause()
    }

    /// `-[Controller idleTimerFired:]`: `_MapScreen`, `_EditorScreen` or `_CustomGameScreen` by mode. The ONE
    /// idle entry point: a host's idle timer calls only this, so it can wrap it to know whether a modal was
    /// requested from inside the idle tick (see `AkiHost`).
    func idleTick() {
        currentScreen?.idle()
    }

    /// `-[Controller _redrawWindow]` @ 0x3bde (DC:932): the current screen's redraw (the map's is a no-op).
    func redrawWindow() {
        currentScreen?.redrawWindow()
    }

    /// `-[Controller mouseDown:]`: the click's point is `_GetMouseLocation`, not the event's location.
    func mouseDown(_ click: ShellClick) {
        currentScreen?.mouseDown(at: click.point, click: click)
    }

    /// `-[Controller keyDown:]` (the map's branch is a no-op).
    func keyDown(_ key: ShellKey) {
        currentScreen?.keyDown(key)
    }

    /// `_LoadLayout` @ 0x132f1 (DC:7593): the chosen built-in level's layout (`_Layout1`…`_Layout12` by
    /// g+0x90, which also set g+0x8e), tilesLeft 144 and Undo off (`AkiGame.init`), the fresh deal
    /// (`_ShuffleCustomTiles(0)`, g+0x60), then the slide-in, `_DrawGameTiles` and `_RedrawEntireWindow`
    /// (`GameScreen.startLevel`).
    func loadLayout() {                                                                    // P2.10
        let level = g.levelIndex!
        let layout = Layouts.forLevel(level)
        var game = AkiGame(layout: layout, difficultyRaw: p.difficultyRaw, levelIndex: level)
        g.background = layout.background
        var rng = SystemRandomNumberGenerator()
        game.dealFresh(using: &rng)
        gameScreenImpl.startLevel(game)
    }

    /// `_TriggerGameToMap` @ 0xe5a2 (DC:5668): stop the current music track, then `_DeleteAllCGTiles` and
    /// `_AnimationCustomGameScreenToMap` — both in `GameScreen.leaveLevel`. Its only caller is P3.6's
    /// Finder-open path; nothing follows the leave (and its proverb), so the continuation is empty.
    func triggerGameToMap() {                                                              // P2.10
        music.stopCurrent()
        gameScreenImpl.leaveLevel {}
    }

    // MARK: Menus

    /// `_HandleMenuCommand` @ 0xd465 (DC:5176–5300). Map (g+0x66 == 0): 9 Level Statistics (DC:5194–5205).
    /// Game: 2 Give Up → `abortGame` (DC:5240–5246); 3 Undo (DC:5248–5261); 4 Tip (DC:5263–5266); 6 Reshuffle
    /// (DC:5268–5278); 7 Pause → Chime at 0x40, then `_PauseGame(!g+0x67)` with no pairs gate (DC:5280–5283);
    /// 9 Level Statistics (DC:5284). The game cases run in `GameScreen`, which alone mutates the level. The
    /// editor's cases and tags 10–19 (Level Editor, files, Play Custom Level, Replay) are Phase 3's (P3.4–P3.6).
    /// Nothing follows a case, so the modal ones (2, 9) need no continuation here.
    func handleMenuCommand(_ tag: Int) {
        switch g.mode {
        case .map:
            switch tag {
            case 9: showStatistics()                                                       // P2.11
            default: break
            }
        case .game:
            switch tag {                                                                   // P2.11
            case 2: gameScreenImpl.abortGame { _ in }
            case 3: gameScreenImpl.menuUndo()
            case 4: gameScreenImpl.menuHint()
            case 6: gameScreenImpl.menuReshuffle()
            case 7:
                sound.play(.chime, volume: 0x40)
                gameScreenImpl.pauseGame(!g.paused)
            case 9: showStatistics()
            default: break
            }
        case .editor:
            break
        }
    }

    /// `_HandleMenuCommand` case 9 (DC:5194–5205), map and game alike: remember g+0x67, `_PauseGame(1)`, the
    /// Stats dialog (`_CreateNewDialog(0x3c)`), and `_PauseGame(0)` unless the game was already paused — in the
    /// dialog's completion. On the map `_PauseGame` only sets its flags (`GameScreen.pauseGame` skips the core
    /// with no level).
    func showStatistics() {                                                                // P2.11
        let wasPaused = g.paused
        gameScreenImpl.pauseGame(true)
        // `_CreateNewDialog(0x3c)` DC:1717–1791: `SetControlData('cfst')` with `"%d"` on each control found by ID;
        // only static texts take the text, so ID 2 — the OK button, first in nib order (Q21) — keeps its title and
        // level 2's Wins stays as the nib left it. The running totals end as the sums written here.
        let table = Stats.table(p)
        let ids = AkiLevels.statsControlIDs
        var fill: [(id: Int, value: Int)] = []
        for (i, row) in table.rows.enumerated() {
            fill += [(ids.minutes + i, row.bestMinutes), (ids.seconds + i, row.bestSeconds), (ids.wins + i, row.wins),
                     (ids.losses + i, row.losses), (ids.giveUps + i, row.giveUps)]
        }
        fill += [(ids.totals[0], table.totalWins), (ids.totals[1], table.totalLosses), (ids.totals[2], table.totalGiveUps)]
        var texts: [Int: String] = [:]
        for (id, value) in fill {
            texts[id] = String(format: "%d", value)                // in fill order: a repeated ID keeps the last write
        }
        host.runDialog("Stats", texts: texts) { [self] _ in
            if !wasPaused {
                gameScreenImpl.pauseGame(false)
            }
        }
    }

    /// The tagged half of `-[Controller validateMenuItem:]` @ 0x3de5 (DC:1048), all three modes: whether the
    /// item is enabled, and the `localizedStringForKey:` title where the original retitles it (`setTitle:`),
    /// else nil. The host applies the title, then disables `notYetBuilt` tags (and, on a host whose modals do
    /// not block the menu bar, every tag while a modal is up — see `AkiHost`).
    func menuState(tag: Int) -> (enabled: Bool, title: String?) {
        switch g.mode {
        case .map:
            switch tag {
            case 2:
                return (false, assets.localized("New Game"))
            case 9, 14, 15:
                return (true, nil)
            case 10:
                return (true, assets.localized("Open Level Editor"))
            case 18:
                // g+0xd0 (the last custom file) set → "Replay %@" with its name, enabled. P3.4 adds the
                // custom-file fields to `AkiG`; until then there is no custom file.
                return (false, assets.localized("Replay Last Level"))
            default:
                return (false, nil)
            }
        case .editor:
            switch tag {
            case 2:
                return (false, assets.localized("New Game"))
            case 9, 11:
                return (true, nil)
            case 10:
                return (true, assets.localized("Exit Level Editor"))
            case 18:
                return (false, assets.localized("Replay Last Level"))
            case 3, 12, 13, 16, 17, 19:
                // 3 → g+0x1f1 (undo), 12/13 → dirty (g+0x1f0) and ≥ 1 tile, 16 → tiles on the current layer,
                // 17 → any tiles, 19 → g+0x1f2 (exactly 144): the editor state P3.4 adds.
                return (false, nil)
            default:
                return (false, nil)
            }
        case .game:
            switch tag {
            case 2:
                return (true, assets.localized("Give Up"))
            case 3:
                return (gameScreenImpl.game?.undoEnabled ?? false, nil)   // g+0x1f1 (DC:1175) — P2.11
            case 4, 6:
                return (!g.paused, nil)
            case 7, 9:
                return (true, nil)
            case 10:
                return (false, assets.localized("Open Level Editor"))
            default:
                return (false, nil)
            }
        }
    }

    // MARK: Helpers

    /// `_SavePrefs` @ 0x2882c: the 143-byte `GameSettings` blob under "GameSettings".
    func savePrefs() {
        store.save(p)
    }

    /// `_GetMouseLocation` @ 0x46ee (DC:1413) — the host's (it knows the window, the activity and the modal).
    func getMouseLocation() -> ShellPoint {
        host.mouseLocation()
    }

    /// `_DrawToWindow` @ 0x4b40: `CopyBits` from `src` into the window port; `flush` presents the port.
    func drawToWindow(_ src: ShellBitmap, srcRect: QDRect, dstRect: QDRect, flush: Bool) {
        gworlds.window.copyBits(from: src, srcRect: ShellRect(srcRect), dstRect: ShellRect(dstRect))
        if flush {
            host.present(gworlds.window)
        }
    }
}
