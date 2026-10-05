import AppKit
import AkiCore
import HectorShell

/// `Controller` (method-map §1), its AppKit half: the app delegate, window delegate, menu target and validator,
/// the shell window's input handler, and the Mac `AkiHost` (`AkiMacHost.swift`). It owns the shared
/// `AkiController` (`_g`, `_p`, the GWorlds, the screens). Launch composes the map (P1.7), starts the 0.05 s
/// idle loop that draws it and schedules `finishLaunch` (P1.8: shows the window, first-launch "welcome"
/// splash); sound/music (P1.6), menus (P1.9), Preferences (P1.11) and the lifecycle (P1.12) extend it.
@MainActor final class AkiAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuItemValidation, ShellInputHandler {
    let controller: AkiController
    var shell: ShellWindowController!
    var launched = false, updateAvailable = false   // ivars 0x0e, 0x0d (`_inactivePause` 0x2d: AkiController)
    private var idleTimer: ShellIdleTimer?                     // ivar 0x30
    /// `_fullscreen` (ivar 0x2c), what `-isFullscreen` returns. Kept beside `shell.isFullscreen` because the
    /// original sets it BEFORE the windowed window leaves the screen (`_enterFullscreen` @ 0x36f8) and clears
    /// it only after the windowed window is back (`_finishExitFullscreen:` @ 0x3b52), so the windowed
    /// window's resign-main during the swap never pauses the game.
    private var fullscreen = false
    private var preferences: PreferencesWindowController?      // ivar 0x20, created on first use

    init(store: GameSettingsStore = GameSettingsStore()) {
        controller = AkiController(store: store)
        super.init()
        controller.host = self
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
        controller.beginLaunch(assets: assets)                 // _Initialize: _LoadPrefs
        do {
            NSApp.mainMenu = try AkiMenus.build(app: self)     // NSMainNibFile = MainMenu.nib
        } catch {
            fatalError("Aki: cannot read MainMenu.nib: \(error)")
        }
        controller.loadLaunchResources()                       // _InitializeGWorlds, screens, sound, music

        shell = ShellWindowController(title: "Aki - Mahjong Solitaire", logicalWidth: 800, logicalHeight: 600)
        shell.view.inputHandler = self
        shell.windowedWindow.delegate = self

        controller.composeLaunchMap()                          // _RedrawMapScreen, _LoopMusic(1), _PlayMovie(0x80)
        shell.windowedWindow.center()
        controller.startLaunchClocks()                         // the tick ivars, blink, preview
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
        if controller.p.fullscreen != 0 && !updateAvailable {
            enterFullscreen()
        } else {
            shell.windowedWindow.makeKeyAndOrderFront(nil)
        }
        controller.showFirstLaunchWelcome()
    }

    /// `-[Controller idleTimerFired:]` → the shared idle entry point.
    private func idleTimerFired() {
        controller.idleTick()
    }

    /// `-[Controller showPreferences:]` @ 0x3443 (DC:610, otool): the `Preferences` controller is created
    /// once (ivar 0x20). Fullscreen → `runModal`, then the fullscreen window `makeKeyAndOrderFront:` — no
    /// pause; windowed → `pause`, then the sheet on the main window, whose end (`preferencesSheetDidEnd:…`)
    /// sends `unpause`.
    @objc func showPreferences(_ sender: Any?) {
        if preferences == nil {
            do {
                preferences = try PreferencesWindowController(app: self)
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
        controller.pause()
        preferences.beginSheet(on: shell.windowedWindow)
    }

    /// `-[Controller toggleFullscreen:]` @ 0x3684 (DC:682): windowed → `_enterFullscreen`, p+0x212 = 1;
    /// fullscreen → `_exitFullscreen`, p+0x212 = 0; then `_SavePrefs`. Each half ends in `_redrawWindow`.
    @objc func toggleFullscreen(_ sender: Any?) {
        if !fullscreen {
            enterFullscreen()
            controller.p.fullscreen = 1
        } else {
            exitFullscreen()
            controller.p.fullscreen = 0
        }
        controller.savePrefs()
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
        controller.redrawWindow()
    }

    /// `-[Controller _exitFullscreen]` @ 0x3a05 (DC:883) + `_finishExitFullscreen:` @ 0x3b52: the faded
    /// swap back to the main window, then `_redrawWindow` and `_fullscreen` = 0.
    private func exitFullscreen() {
        guard fullscreen else { return }
        shell.exitFullscreen()
        controller.redrawWindow()
        fullscreen = false
    }

    /// `-[Controller _redrawWindow]` @ 0x3bde (DC:932): the current screen's redraw (the map's is a no-op).
    @objc private func redrawWindow() {
        controller.redrawWindow()
    }

    // MARK: Window and app lifecycle

    /// `-[Controller windowDidResignMain:]` @ 0x30c0 (DC:423): windowed and not paused → `pause`,
    /// `_inactivePause` = 1 (the shared body: `AkiController.focusLost`).
    func windowDidResignMain(_ notification: Notification) {
        guard !fullscreen else { return }
        controller.focusLost()
    }

    /// `-[Controller windowDidBecomeMain:]` @ 0x30f6 (DC:436): `_redrawWindow` after delay 0; if
    /// `_inactivePause` → `unpause`, clear it (`AkiController.focusRegained`).
    func windowDidBecomeMain(_ notification: Notification) {
        perform(#selector(redrawWindow), with: nil, afterDelay: 0)
        controller.focusRegained()
    }

    /// `-[Controller windowShouldClose:]` @ 0x3153 (DC:460): YES on the map and in the game; in the editor
    /// with unsaved changes the save alert decides (P3.5).
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        true
    }

    /// `-[Controller applicationWillResignActive:]` @ 0x2ecb (DC:309): `AkiController.resignActiveMusic`.
    func applicationWillResignActive(_ notification: Notification) {
        controller.resignActiveMusic()
    }

    /// `-[Controller applicationDidBecomeActive:]` @ 0x2efe (DC:326): `AkiController.becomeActiveMusic`.
    func applicationDidBecomeActive(_ notification: Notification) {
        controller.becomeActiveMusic(launched: launched)
    }

    /// `-[Controller applicationShouldTerminateAfterLastWindowClosed:]` @ 0x2f7e (DC:357): `_launched` and
    /// not `_fullscreen` — closing the main window quits.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        launched && !fullscreen
    }

    /// `-[Controller applicationShouldTerminate:]` @ 0x2cf7 (DC:226): the map quits at once; the game asks
    /// `abortGame`, the editor its save alert — each screen's `shouldTerminate`. Termination is Mac-only, and the
    /// Mac host runs every modal synchronously, so the screen's completion has run when `shouldTerminate`
    /// returns (asserted).
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let screen = controller.currentScreen else { return .terminateNow }
        var reply: Bool?
        screen.shouldTerminate { reply = $0 }
        guard let reply else { preconditionFailure("Aki: shouldTerminate's completion did not run synchronously") }
        return reply ? .terminateNow : .terminateCancel
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
        controller.handleMenuCommand(sender.tag)
    }

    /// `-[Controller validateMenuItem:]` @ 0x3de5 (DC:1048), all three modes, then `false` for any tag in
    /// `notYetBuilt` (retitling still happens). Untagged items: Help is off while a window is modal; Close
    /// is off when the key window is the main window, else follows the key window's close box; the rest on.
    /// Also puts the nib's "Preferences…" back each time AppKit validates it (AppKit retitles it
    /// "Settings…"; see `AkiMenus.restoreNibItems`).
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(toggleRemasteredArt(_:)) {
            // D11: checked while the Remaster art runs; off without the art set, under a modal window and under
            // the Preferences sheet (whose OK applies its own checkbox).
            menuItem.state = controller.remasterActive ? .on : .off
            return controller.remasterAvailable && NSApp.modalWindow == nil && shell?.windowedWindow.attachedSheet == nil
        }
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
        // The tagged half (shared): `setTitle:` with `localizedStringForKey:` where the original retitles.
        let state = controller.menuState(tag: tag)
        if let title = state.title {
            menuItem.title = title
        }
        return state.enabled && !AkiController.notYetBuilt.contains(tag)
    }

    /// "Remastered Art" (D11, not in the nib): flips the Remaster art live (`AkiController.setRemastered`); the
    /// Preferences checkbox shows the new state the next time Preferences opens (`updateUI`).
    @objc func toggleRemasteredArt(_ sender: Any?) {
        controller.setRemastered(!controller.remasterActive)
    }

    /// `-[Controller showAboutBox:]` @ 0x327a (Q10).
    @objc func showAboutBox(_ sender: Any?) {
        showAbout()
    }

    /// `-[Controller showHelp:]` @ 0x342c: `_SplashScreen("guide", 0)`.
    @objc func showHelp(_ sender: Any?) {
        showSplash(named: "guide", timeout: 0) {}
    }

    /// `-[Controller showHandbook:]` @ 0x33b2 (DC:587).
    @objc func showHandbook(_ sender: Any?) {
        showHandbook()
    }

    /// `-[Controller showReleaseNotes:]` @ 0x358e (Q10).
    @objc func showReleaseNotes(_ sender: Any?) {
        showReleaseNotes()
    }

    /// `-[Controller performClose:]` @ 0x31fe: the key window's `performClose:` when it responds.
    @objc func performClose(_ sender: Any?) {
        guard let key = NSApp.keyWindow, key.responds(to: #selector(NSWindow.performClose(_:))) else { return }
        key.performClose(sender)
    }

    // MARK: ShellInputHandler

    /// `-[Controller mouseDown:]`: the point is `_GetMouseLocation`, not the event's location; the modifiers
    /// are the POLLED `NSEvent.modifierFlags` (what `_SelectMapArea` read for Option), taken here, in the same
    /// event dispatch and before any screen code runs.
    func shellView(_ view: ShellView, mouseDown event: NSEvent) {
        let click = ShellClick(point: controller.getMouseLocation(), timestamp: event.timestamp,
                               modifiers: ShellModifiers(NSEvent.modifierFlags))
        controller.mouseDown(click)
    }

    /// `-[Controller keyDown:]` (the map's branch is a no-op).
    func shellView(_ view: ShellView, keyDown event: NSEvent) {
        controller.keyDown(ShellKey(characters: event.characters ?? "", modifiers: ShellModifiers(event.modifierFlags)))
    }
}

extension ShellModifiers {
    /// The AppKit modifier flags as the classic modifier keys.
    init(_ flags: NSEvent.ModifierFlags) {
        var m: ShellModifiers = []
        if flags.contains(.shift) { m.insert(.shift) }
        if flags.contains(.control) { m.insert(.control) }
        if flags.contains(.option) { m.insert(.option) }
        if flags.contains(.command) { m.insert(.command) }
        self = m
    }
}
