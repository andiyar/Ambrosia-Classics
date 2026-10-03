import AppKit
import AkiCore
import HectorShell

/// `Controller` (method-map §1): the app delegate, window delegate and owner of `_g`, `_p`, the GWorlds
/// and the shell window. Launch composes the map (P1.7), starts the 0.05 s idle loop that draws it and
/// schedules `finishLaunch` (P1.8: shows the window, first-launch "welcome" splash); sound/music (P1.6),
/// menus (P1.9), Preferences (P1.11) and the lifecycle (P1.12) extend this class.
@MainActor final class AkiController: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuItemValidation, ShellInputHandler {
    let g: AkiG
    let store: GameSettingsStore
    var p: GameSettings                                        // `_p`
    var assets: AkiAssets!
    var gworlds: AkiGWorlds!
    var sound: AkiSound!
    var music: AkiMusic!
    var shell: ShellWindowController!
    var mapScreen: MapScreen!; var gameScreen: AkiScreen?; var editorScreen: AkiScreen?   // P2.10 sets gameScreen, P3.4 editorScreen
    var launched = false, updateAvailable = false, inactivePause = false   // ivars 0x0e, 0x0d, 0x2d
    var lastTimeCount: UInt32 = 0, lastMouseCount: UInt32 = 0, updateTimeCount: UInt32 = 0, flash: UInt32 = 0, lastTick: UInt32 = 0
    var lastMouse = ShellPoint.zero                            // ivar 0x50 (double-click guard, P2.11)
    private var idleTimer: ShellIdleTimer?                     // ivar 0x30
    /// `_fullscreen` (ivar 0x2c), what `-isFullscreen` returns. Kept beside `shell.isFullscreen` because the
    /// original sets it BEFORE the windowed window leaves the screen (`_enterFullscreen` @ 0x36f8) and clears
    /// it only after the windowed window is back (`_finishExitFullscreen:` @ 0x3b52), so the windowed
    /// window's resign-main during the swap never pauses the game.
    private var fullscreen = false
    private var preferences: PreferencesWindowController?      // ivar 0x20, created on first use
    /// Menu tags whose commands land in a later phase: `validateMenuItem` disables them after the 1.2
    /// rules (Known delta 3). P2.11 and P3.4–P3.6 remove tags as their commands are built.
    static var notYetBuilt: Set<Int> = [3, 4, 6, 7, 9, 10, 11, 12, 13, 14, 16, 17, 18, 19]

    init(store: GameSettingsStore = GameSettingsStore()) {
        g = AkiG()
        self.store = store
        p = .defaults
        super.init()
    }

    // MARK: Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        let assets = AkiAssets()
        #if DEBUG
        if !assets.missingFiles().isEmpty {
            let alert = NSAlert()
            alert.messageText = "Aki's original data files are missing from this app. Run tools/stage-aki.sh."
            alert.runModal()
            NSApp.terminate(nil)
            return
        }
        #endif
        p = store.load()                                       // _Initialize: _LoadPrefs
        self.assets = assets
        do {
            NSApp.mainMenu = try AkiMenus.build(controller: self)   // NSMainNibFile = MainMenu.nib
        } catch {
            fatalError("Aki: cannot read MainMenu.nib: \(error)")
        }
        do {
            gworlds = try AkiGWorlds(assets: assets)           // _Initialize: _InitializeGWorlds
        } catch {
            fatalError("Aki: cannot load the original art: \(error)")
        }
        mapScreen = MapScreen(controller: self)
        do {
            sound = try AkiSound(assets: assets, controller: self)   // _Initialize: _InitializeSound
            music = try AkiMusic(assets: assets, controller: self)   // _Initialize: _InitializeMusic
        } catch {
            fatalError("Aki: cannot load the original sounds: \(error)")
        }

        shell = ShellWindowController(title: "Aki - Mahjong Solitaire", logicalWidth: 800, logicalHeight: 600)
        shell.view.inputHandler = self
        shell.windowedWindow.delegate = self

        mapScreen.redrawMapScreen()                            // _Initialize's tail: _RedrawMapScreen
        p.applyLaunchRegistration()                            // _LoopMusic(1): the replica is registered
        music.playMovie(0x80)                                  // _PlayMovie(0x80): Theme 3 when Music is on
        shell.windowedWindow.center()
        let now = ShellClock.ticks()                           // the tick ivars 0x34…0x44 = TickCount()
        lastTimeCount = now; lastMouseCount = now; updateTimeCount = now; flash = now; lastTick = now
        mapScreen.blink = AkiMap.Blink()                       // LastColor 0, ColorDown 1
        mapScreen.lastPreview = nil                            // −9
        let timer = ShellIdleTimer(interval: 0.05) { [weak self] in self?.idleTimerFired() }
        idleTimer = timer
        timer.start()
        perform(#selector(finishLaunch(_:)), with: nil, afterDelay: 0.5)
    }

    /// `-[Controller finishLaunch:]` @ 0x41d4 (DC:1200), 0.5 s after launch: `_launched` = 1; Fullscreen
    /// (p+0x212) set and no update pending (`_updateAvailable`) → `_enterFullscreen`, else the main window
    /// (hidden at launch — MainMenu.nib `visibleAtLaunch` 0) is shown now, over the map the idle loop has
    /// already drawn; on first launch (p+0x215) the flag is cleared and saved, then the "welcome" splash
    /// runs (no timeout).
    @objc func finishLaunch(_ sender: Any?) {
        launched = true
        if p.fullscreen != 0 && !updateAvailable {
            enterFullscreen()
        } else {
            shell.windowedWindow.makeKeyAndOrderFront(nil)
        }
        if p.firstLaunch != 0 {
            p.firstLaunch = 0
            savePrefs()
            AkiSplash.show(named: "welcome", timeout: 0, controller: self)
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

    /// `-[Controller idleTimerFired:]`: `_MapScreen`, `_EditorScreen` or `_CustomGameScreen` by mode.
    private func idleTimerFired() {
        currentScreen?.idle()
    }

    /// `_LoadLayout`. Phase 1: the game is Phase 2, so a chosen level stays on the map (Known delta 3);
    /// P2.10 replaces this body.
    func loadLayout() {}

    /// `-[Controller showPreferences:]` @ 0x3443 (DC:610, otool): the `Preferences` controller is created
    /// once (ivar 0x20). Fullscreen → `runModal`, then the fullscreen window `makeKeyAndOrderFront:` — no
    /// pause; windowed → `pause`, then the sheet on the main window, whose end (`preferencesSheetDidEnd:…`)
    /// sends `unpause`.
    @objc func showPreferences(_ sender: Any?) {
        if preferences == nil {
            do {
                preferences = try PreferencesWindowController(controller: self)
            } catch {
                fatalError("Aki: cannot read Preferences.nib: \(error)")
            }
        }
        guard let preferences else { return }
        if shell.isFullscreen {
            preferences.runModal()
            shell.currentWindow.makeKeyAndOrderFront(nil)
            return
        }
        pause()
        preferences.beginSheet(on: shell.windowedWindow)
    }

    /// `-[Controller toggleFullscreen:]` @ 0x3684 (DC:682): windowed → `_enterFullscreen`, p+0x212 = 1;
    /// fullscreen → `_exitFullscreen`, p+0x212 = 0; then `_SavePrefs`. Each half ends in `_redrawWindow`.
    @objc func toggleFullscreen(_ sender: Any?) {
        if !fullscreen {
            enterFullscreen()
            p.fullscreen = 1
        } else {
            exitFullscreen()
            p.fullscreen = 0
        }
        savePrefs()
    }

    /// `-[Controller _enterFullscreen]` @ 0x36f8 (DC:712): `_fullscreen` = 1, then the faded swap to the
    /// shielding-level window (HectorShell; no 800×600 display-mode switch — Known delta 2), then
    /// `_redrawWindow`. The fullscreen window gets no delegate, as `AkiFullscreenWindow` had none.
    private func enterFullscreen() {
        guard !fullscreen else { return }
        fullscreen = true
        shell.enterFullscreen()
        fullscreen = shell.isFullscreen                       // no main screen → stays windowed
        if !fullscreen { shell.windowedWindow.makeKeyAndOrderFront(nil) }
        currentScreen?.redrawWindow()
    }

    /// `-[Controller _exitFullscreen]` @ 0x3a05 (DC:883) + `_finishExitFullscreen:` @ 0x3b52: the faded
    /// swap back to the main window, then `_redrawWindow` and `_fullscreen` = 0.
    private func exitFullscreen() {
        guard fullscreen else { return }
        shell.exitFullscreen()
        currentScreen?.redrawWindow()
        fullscreen = false
    }

    /// `-[Controller _redrawWindow]` @ 0x3bde (DC:932): the current screen's redraw (the map's is a no-op).
    @objc private func redrawWindow() {
        currentScreen?.redrawWindow()
    }

    // MARK: Window and app lifecycle

    /// `-[Controller windowDidResignMain:]` @ 0x30c0 (DC:423): windowed and not paused → `pause`,
    /// `_inactivePause` = 1.
    func windowDidResignMain(_ notification: Notification) {
        guard !fullscreen, !g.paused else { return }
        pause()
        inactivePause = true
    }

    /// `-[Controller windowDidBecomeMain:]` @ 0x30f6 (DC:436): `_redrawWindow` after delay 0; if
    /// `_inactivePause` → `unpause`, clear it.
    func windowDidBecomeMain(_ notification: Notification) {
        perform(#selector(redrawWindow), with: nil, afterDelay: 0)
        if inactivePause {
            unpause()
            inactivePause = false
        }
    }

    /// `-[Controller windowShouldClose:]` @ 0x3153 (DC:460): YES on the map and in the game; in the editor
    /// with unsaved changes the save alert decides (P3.5).
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        true
    }

    /// `-[Controller applicationWillResignActive:]` @ 0x2ecb (DC:309): stops the music without pausing the
    /// game — `_g`+0x67 is set around `_PlayMovie(0x80)` and then restored.
    func applicationWillResignActive(_ notification: Notification) {
        let wasPaused = g.paused
        g.paused = true
        music?.playMovie(0x80)
        g.paused = wasPaused
    }

    /// `-[Controller applicationDidBecomeActive:]` @ 0x2efe (DC:326): once launched (RT3 refresh out of
    /// scope), on the map or unless the game's "no pairs" flash (`_g`+0x85) is up → `_LoopMusic(1)`
    /// (`applyLaunchRegistration`) and `_PlayMovie` (args lost → 0x80, Q15).
    func applicationDidBecomeActive(_ notification: Notification) {
        guard launched, g.mode == .map || !g.noPairsFlash else { return }
        p.applyLaunchRegistration()
        music.playMovie(0x80)
    }

    /// `-[Controller applicationShouldTerminateAfterLastWindowClosed:]` @ 0x2f7e (DC:357): `_launched` and
    /// not `_fullscreen` — closing the main window quits.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        launched && !fullscreen
    }

    /// `-[Controller applicationShouldTerminate:]` @ 0x2cf7 (DC:226): the map quits at once; the game asks
    /// `abortGame`, the editor its save alert — each screen's `shouldTerminate()`.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        (currentScreen?.shouldTerminate() ?? true) ? .terminateNow : .terminateCancel
    }

    /// `-[Controller applicationWillTerminate:]` @ 0x2d7d (DC:264): invalidates the idle timer, then leaves
    /// fullscreen (the unregistered nag, `ExitMovies`, `RT3_Close`/`FT_Close` are out of scope; the
    /// deferred `_finishExitFullscreen:` never gets a turn, so no redraw).
    func applicationWillTerminate(_ notification: Notification) {
        idleTimer?.invalidate()
        if fullscreen {
            shell.exitFullscreen()
        }
    }

    // MARK: Menus (MainMenu.nib, P1.9)

    /// The delayed pass `AkiMenus.build` schedules once the bar is installed.
    @objc func restoreNibMenu() {
        AkiMenus.restoreNibItems()
    }

    /// `-[Controller gameMenuAction:]` @ 0x31db: every tagged menu item → `_HandleMenuCommand(tag)`.
    @objc func gameMenuAction(_ sender: NSMenuItem) {
        handleMenuCommand(sender.tag)
    }

    /// `_HandleMenuCommand` @ 0xd465 (DC:5176). Phase 1 has no reachable case: every tag `validateMenuItem`
    /// would enable on the map (9 Level Statistics, 10 Open Level Editor, 14 Play Custom Level, 18 Replay)
    /// is in `notYetBuilt`. P2.11 and P3.4–P3.6 add the cases.
    func handleMenuCommand(_ tag: Int) {
        switch tag {
        default: break
        }
    }

    /// `-[Controller validateMenuItem:]` @ 0x3de5 (DC:1048), all three modes, then `false` for any tag in
    /// `notYetBuilt` (retitling still happens). Untagged items: Help is off while a window is modal; Close
    /// is off when the key window is the main window, else follows the key window's close box; the rest on.
    /// Also puts the nib's "Preferences…" back each time AppKit validates it (AppKit retitles it
    /// "Settings…"; see `AkiMenus.restoreNibItems`).
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(showPreferences(_:)), let title = AkiMenus.preferencesTitle,
           menuItem.title != title {
            menuItem.title = title
        }
        let tag = menuItem.tag
        guard tag >= 1 else {
            if menuItem.action == #selector(showHelp(_:)), NSApp.modalWindow != nil { return false }
            guard menuItem.action == #selector(performClose(_:)) else { return true }
            guard let key = NSApp.keyWindow, key !== shell.windowedWindow else { return false }
            return key.styleMask.contains(.closable)
        }
        return validateTaggedItem(menuItem, tag: tag) && !Self.notYetBuilt.contains(tag)
    }

    /// The tagged half of DC:1048: `setTitle:` with `localizedStringForKey:` where the original retitles.
    private func validateTaggedItem(_ menuItem: NSMenuItem, tag: Int) -> Bool {
        switch g.mode {
        case .map:
            switch tag {
            case 2:
                menuItem.title = assets.localized("New Game")
                return false
            case 9, 14, 15:
                return true
            case 10:
                menuItem.title = assets.localized("Open Level Editor")
                return true
            case 18:
                // g+0xd0 (the last custom file) set → "Replay %@" with its name, enabled. P3.4 adds the
                // custom-file fields to `AkiG`; until then there is no custom file.
                menuItem.title = assets.localized("Replay Last Level")
                return false
            default:
                return false
            }
        case .editor:
            switch tag {
            case 2:
                menuItem.title = assets.localized("New Game")
                return false
            case 9, 11:
                return true
            case 10:
                menuItem.title = assets.localized("Exit Level Editor")
                return true
            case 18:
                menuItem.title = assets.localized("Replay Last Level")
                return false
            case 3, 12, 13, 16, 17, 19:
                // 3 → g+0x1f1 (undo), 12/13 → dirty (g+0x1f0) and ≥ 1 tile, 16 → tiles on the current layer,
                // 17 → any tiles, 19 → g+0x1f2 (exactly 144): the editor state P3.4 adds.
                return false
            default:
                return false
            }
        case .game:
            switch tag {
            case 2:
                menuItem.title = assets.localized("Give Up")
                return true
            case 3:
                return false                                   // g+0x1f1 (undo enabled): the game P2 adds
            case 4, 6:
                return !g.paused
            case 7, 9:
                return true
            case 10:
                menuItem.title = assets.localized("Open Level Editor")
                return false
            default:
                return false
            }
        }
    }

    /// `-[Controller showAboutBox:]` @ 0x327a (Q10).
    @objc func showAboutBox(_ sender: Any?) {
        AkiInfoWindows.showAbout(controller: self)
    }

    /// `-[Controller showHelp:]` @ 0x342c: `_SplashScreen("guide", 0)`.
    @objc func showHelp(_ sender: Any?) {
        AkiSplash.show(named: "guide", timeout: 0, controller: self)
    }

    /// `-[Controller showHandbook:]` @ 0x33b2 (DC:587): `openFile:withApplication:@"Preview"` on the
    /// shipped `Aki Handbook.pdf` — opened in Preview (`com.apple.Preview`); only if Preview is missing
    /// does it go to the default PDF handler.
    @objc func showHandbook(_ sender: Any?) {
        guard let url = assets.url("Aki Handbook.pdf") else { return }
        if let preview = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Preview") {
            NSWorkspace.shared.open([url], withApplicationAt: preview, configuration: NSWorkspace.OpenConfiguration())
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    /// `-[Controller showReleaseNotes:]` @ 0x358e (Q10).
    @objc func showReleaseNotes(_ sender: Any?) {
        AkiInfoWindows.showReleaseNotes(controller: self)
    }

    /// `-[Controller performClose:]` @ 0x31fe: the key window's `performClose:` when it responds.
    @objc func performClose(_ sender: Any?) {
        guard let key = NSApp.keyWindow, key.responds(to: #selector(NSWindow.performClose(_:))) else { return }
        key.performClose(sender)
    }

    // MARK: Helpers

    /// `_SavePrefs` @ 0x2882c: the 143-byte `GameSettings` blob under "GameSettings".
    func savePrefs() {
        store.save(p)
    }

    /// `_GetMouseLocation` @ 0x46ee (DC:1413): (0, 0) unless the app is active, no window is modal, and
    /// the game is fullscreen or the main window is key; else the pointer in the 800×600 canvas,
    /// truncating and unclamped.
    func getMouseLocation() -> ShellPoint {
        guard NSApp.isActive, NSApp.modalWindow == nil,
              shell.isFullscreen || shell.windowedWindow.isKeyWindow else { return .zero }
        return shell.view.logicalMouseLocation()
    }

    /// `_DrawToWindow` @ 0x4b40: `CopyBits` from `src` into the window port; `flush` presents the port.
    func drawToWindow(_ src: ShellBitmap, srcRect: QDRect, dstRect: QDRect, flush: Bool) {
        gworlds.window.copyBits(from: src, srcRect: ShellRect(srcRect), dstRect: ShellRect(dstRect))
        if flush {
            shell.view.present(gworlds.window)
        }
    }

    // MARK: ShellInputHandler

    /// `-[Controller mouseDown:]`: the point is `_GetMouseLocation`, not the event's location.
    func shellView(_ view: ShellView, mouseDown event: NSEvent) {
        currentScreen?.mouseDown(at: getMouseLocation(), event: event)
    }

    /// `-[Controller keyDown:]` (the map's branch is a no-op).
    func shellView(_ view: ShellView, keyDown event: NSEvent) {
        currentScreen?.keyDown(event)
    }
}
