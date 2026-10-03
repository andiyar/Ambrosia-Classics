import AppKit
import AkiCore
import HectorShell

/// `Controller` (method-map §1): the app delegate, window delegate and owner of `_g`, `_p`, the GWorlds
/// and the shell window. P1.5 skeleton: launch shows `map.png` in the 800×600 window; the map loop
/// (P1.7), sound/music (P1.6), splashes and `finishLaunch` (P1.8), menus (P1.9), Preferences (P1.11)
/// and the lifecycle (P1.12) extend this class.
@MainActor final class AkiController: NSObject, NSApplicationDelegate, NSWindowDelegate, ShellInputHandler {
    let g: AkiG
    let store: GameSettingsStore
    var p: GameSettings                                        // `_p`
    var assets: AkiAssets!
    var gworlds: AkiGWorlds!
    var sound: AkiSound!
    var music: AkiMusic!
    var shell: ShellWindowController!
    var launched = false, updateAvailable = false, inactivePause = false   // ivars 0x0e, 0x0d, 0x2d
    var lastTimeCount: UInt32 = 0, lastMouseCount: UInt32 = 0, updateTimeCount: UInt32 = 0, flash: UInt32 = 0, lastTick: UInt32 = 0
    var lastMouse = ShellPoint.zero                            // ivar 0x50 (double-click guard, P2.11)

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
        do {
            sound = try AkiSound(assets: assets, controller: self)   // _Initialize: _InitializeSound
            music = try AkiMusic(assets: assets, controller: self)   // _Initialize: _InitializeMusic
        } catch {
            fatalError("Aki: cannot load the original sounds: \(error)")
        }

        shell = ShellWindowController(title: "Aki - Mahjong Solitaire", logicalWidth: 800, logicalHeight: 600)
        shell.view.inputHandler = self
        shell.windowedWindow.delegate = self

        let full = QDRect(left: 0, top: 0, right: 800, bottom: 600)
        drawToWindow(gworlds.map, srcRect: full, dstRect: full, flush: true)
        p.applyLaunchRegistration()                            // _LoopMusic(1): the replica is registered
        music.playMovie(0x80)                                  // _PlayMovie(0x80): Theme 3 when Music is on
        shell.windowedWindow.center()
        shell.windowedWindow.makeKeyAndOrderFront(nil)
    }

    // MARK: Helpers

    /// `_SavePrefs` @ 0x2882c: the 143-byte `GameSettings` blob under "GameSettings".
    func savePrefs() {
        store.save(p)
    }

    /// `_DrawToWindow` @ 0x4b40: `CopyBits` from `src` into the window port; `flush` presents the port.
    func drawToWindow(_ src: ShellBitmap, srcRect: QDRect, dstRect: QDRect, flush: Bool) {
        gworlds.window.copyBits(from: src, srcRect: ShellRect(srcRect), dstRect: ShellRect(dstRect))
        if flush {
            shell.view.present(gworlds.window)
        }
    }

    // MARK: ShellInputHandler (the screens' dispatch lands with P1.7)

    func shellView(_ view: ShellView, mouseDown event: NSEvent) {}

    func shellView(_ view: ShellView, keyDown event: NSEvent) {}
}
