import AppKit
import AkiCore
import HectorShell

/// `Controller` (method-map §1): the app delegate, window delegate and owner of `_g`, `_p`, the GWorlds
/// and the shell window. Launch composes the map (P1.7) and starts the 0.05 s idle loop that draws it;
/// sound/music (P1.6), splashes and `finishLaunch` (P1.8), menus (P1.9), Preferences (P1.11) and the
/// lifecycle (P1.12) extend this class.
@MainActor final class AkiController: NSObject, NSApplicationDelegate, NSWindowDelegate, ShellInputHandler {
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
        shell.windowedWindow.makeKeyAndOrderFront(nil)
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

    /// `-[Controller idleTimerFired:]`: `_MapScreen`, `_EditorScreen` or `_CustomGameScreen` by mode.
    private func idleTimerFired() {
        currentScreen?.idle()
    }

    /// `_LoadLayout`. Phase 1: the game is Phase 2, so a chosen level stays on the map (Known delta 3);
    /// P2.10 replaces this body.
    func loadLayout() {}

    /// `-[Controller showPreferences:]` — P1.11 builds the Preferences window; until then the map bar's
    /// Preferences does nothing.
    @objc func showPreferences(_ sender: Any?) {}

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
