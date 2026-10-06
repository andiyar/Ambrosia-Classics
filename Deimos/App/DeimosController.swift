import AppKit
import DeimosCore
import DeimosHost
import DeimosRender
import HectorShell

/// The app delegate and shell owner (plan S6, A1): loads the original data, opens the 640×480 game window at the
/// largest whole scale that fits (D27.3), and drives `DeimosDriver` from a 1/240 s idle timer — keys polled once per
/// Mac tick (`GetKeys`; `heldKeys(seconds:)`), suspended while the app is hidden (`updateSuspension`), the window's RGB555 screen converted and presented whenever the driver says it changed, the
/// cursor requests honoured. All timing (Mac ticks, the FPS limiter, fade steps) is the driver's; the App only asks
/// often enough (every ~4 ms) that a tick boundary is never missed by more than a fraction of a tick.
@MainActor final class DeimosController: NSObject, NSApplicationDelegate, ShellInputHandler {
    static let width = 640
    static let height = 480
    static let title = "Deimos Rising"

    private var driver: DeimosDriver!
    private var shell: ShellWindowController!
    private var timer: ShellIdleTimer!
    /// The window's image, refilled from `driver.screen` on every present (k = 1: the original's 640×480 pixels).
    private let bitmap = ShellBitmap(width: DeimosController.width, height: DeimosController.height)

    /// The game asked for the cursor hidden (`.hideCursor` / `.showCursor`, the original's `HideCursor`).
    private var wantsCursorHidden = false
    /// `NSCursor.hide` is counted: this records whether this controller's one hide is in effect.
    private var cursorHidden = false
    /// The display is suspended (`FUN_1000b7d0`'s +0x65): the app is in the background or the window is miniaturised.
    private var suspended = false

    // MARK: Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = makeMenuBar()
        guard let dataDirectory = DeimosAssets.dataDirectory() else {
            #if DEBUG
            let alert = NSAlert()
            alert.messageText = "Deimos Rising's original data folder is missing from this app."
            alert.informativeText = "Run tools/stage-deimos.sh (or set DEIMOS_DATA to Resources/Deimos/Data)."
            alert.runModal()
            #endif
            fail("no Data folder at Contents/Resources/Deimos/Data")
            return
        }
        do {
            let assets = try DeimosAssets.load(dataDirectory: dataDirectory)
            // Mac OS X's 60 Hz TickCount: Ben played Deimos on OS X (gate 1, DECISIONS D30; Q1).
            driver = try DeimosDriver(assets: assets, prefs: .fresh, rate: .osx,
                                      start: SessionStart(sector: 1, players: 1, film: nil))
        } catch {
            // The folder is there but its contents do not load (design §7.7): DEBUG says so, Release logs and quits.
            #if DEBUG
            let alert = NSAlert()
            alert.messageText = "Deimos Rising's original data could not be loaded."
            alert.informativeText = "\(dataDirectory.path)\n\n\(error)"
            alert.runModal()
            #endif
            fail("cannot load the original data: \(error)")
            return
        }

        shell = ShellWindowController(title: Self.title, logicalWidth: Self.width, logicalHeight: Self.height,
                                      styleMask: Self.windowStyle, scalingPolicy: .integerFit)
        shell.view.inputHandler = self
        NotificationCenter.default.addObserver(self, selector: #selector(windowMiniaturizeChanged(_:)),
                                               name: NSWindow.didMiniaturizeNotification,
                                               object: shell.windowedWindow)
        NotificationCenter.default.addObserver(self, selector: #selector(windowMiniaturizeChanged(_:)),
                                               name: NSWindow.didDeminiaturizeNotification,
                                               object: shell.windowedWindow)
        sizeToWholeScale(shell.windowedWindow)
        present()                                                       // black until the first pass presents
        shell.windowedWindow.makeKeyAndOrderFront(nil)
        NSApp.activate()

        timer = ShellIdleTimer(interval: 1.0 / 240.0) { [weak self] in self?.idleFired() }
        timer.start()
        idleFired()
        updateSuspension()                                              // launched behind another app: suspend now
    }

    /// The window. The original's play screen is a borderless DrawSprocket context (`NewCWindow` procID 2
    /// `plainDBox`); its windowed variant — unreachable in 1.0.6 (+0x4d is only ever 0) but the shape it was built
    /// for — is procID 4 `noGrowDocProc` with goAway 0: a title bar, no close box, no grow box, and collapsible (it
    /// un-collapses in `FUN_1000a840` and suspends on collapse via `FUN_1000c380`) — display-window-present.md §3
    /// (`FUN_1000a640`) and §8.1. D27.3 rules a window plus ⌃⌘F full screen, so the window is that variant:
    /// titled + miniaturisable (collapse), no close (quit is ⌘Q), not resizable (whole-number scale, D27.3).
    static let windowStyle: NSWindow.StyleMask = [.titled, .miniaturizable]

    /// Content 640k × 480k points, k the largest whole number whose window frame (title bar included) fits the main
    /// screen's visible frame, min 1; centred in that area.
    private func sizeToWholeScale(_ window: NSWindow) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { window.center(); return }
        let area = screen.visibleFrame
        var k = 1
        while true {
            let next = k + 1
            let content = NSRect(x: 0, y: 0, width: Self.width * next, height: Self.height * next)
            let frame = window.frameRect(forContentRect: content)
            guard frame.width <= area.width, frame.height <= area.height else { break }
            k = next
        }
        window.setContentSize(NSSize(width: Self.width * k, height: Self.height * k))
        let size = window.frame.size
        window.setFrameOrigin(NSPoint(x: (area.midX - size.width / 2).rounded(),
                                      y: (area.midY - size.height / 2).rounded()))
    }

    /// A launch failure: logged (DEBUG has already shown its alert where one applies), then quit.
    private func fail(_ message: String) {
        NSLog("Deimos Rising: %@", message)
        NSApp.terminate(nil)
    }

    // MARK: Menu

    /// The app menu only (the original had no menus in play): Quit ⌘Q, plus a hidden Full Screen ⌃⌘F item — the
    /// shortcut goes through the menu's key-equivalent matching (layout-independent, as Aki's and BTX's Full
    /// Screen items do), but the original had no such menu entry, so it is not shown.
    private func makeMenuBar() -> NSMenu {
        let bar = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: Self.title)
        let fullScreen = NSMenuItem(title: "Full Screen", action: #selector(toggleFullScreenChosen(_:)),
                                    keyEquivalent: "f")
        fullScreen.keyEquivalentModifierMask = [.control, .command]
        fullScreen.target = self
        fullScreen.isHidden = true
        fullScreen.allowsKeyEquivalentWhenHidden = true
        appMenu.addItem(fullScreen)
        appMenu.addItem(NSMenuItem(title: "Quit \(Self.title)", action: #selector(NSApplication.terminate(_:)),
                                   keyEquivalent: "q"))
        appItem.submenu = appMenu
        bar.addItem(appItem)
        return bar
    }

    // MARK: Clock

    /// One 1/240 s fire: the driver runs as far as its clock allows; a changed screen is presented.
    private func idleFired() {
        guard driver != nil, !suspended else { return }
        let seconds = ProcessInfo.processInfo.systemUptime
        let out = driver.idle(seconds: seconds, keys: heldKeys(seconds: seconds))
        for request in out.requests {
            switch request {
            case .hideCursor: wantsCursorHidden = true
            case .showCursor: wantsCursorHidden = false
            }
        }
        if out.screenChanged { present() }
        updateCursor()
    }

    /// The Mac tick of the last full key poll.
    private var lastKeyPollTick: UInt32?

    /// The keys for this fire. A pass can begin only when the Mac tick moves (the limiter and fades wait on it), so
    /// the full poll (`pollKeyState`: modifiers, Caps Lock, and HectorKit's `CGPreflightListenEventAccess` ⌘-release
    /// probe) runs once per tick — the first fire after a boundary, i.e. before any pass that tick can start — and
    /// the other three-odd fires reuse `keyState`, which key-down/up/flags events keep current anyway.
    private func heldKeys(seconds: Double) -> HeldKeys {
        let tick = MacTicks.ticks(seconds: seconds, rate: driver.rate.perSecond)
        let state: ShellKeyState
        if tick != lastKeyPollTick {
            lastKeyPollTick = tick
            state = shell.view.pollKeyState()
        } else {
            state = shell.view.keyState
        }
        return HeldKeys(held: state.held, capsLock: state.capsLock)
    }

    /// Copies the driver's screen into the window bitmap (x1R5G5B5 → 0xAARRGGBB) and shows it.
    private func present() {
        if let driver { ScreenRGBA.convert(driver.screen, into: bitmap.pixels) }
        shell.view.present(bitmap)
    }

    // MARK: Suspend / resume

    func applicationDidResignActive(_ notification: Notification) { updateSuspension() }
    func applicationDidBecomeActive(_ notification: Notification) { updateSuspension() }
    @objc private func windowMiniaturizeChanged(_ notification: Notification) { updateSuspension() }

    /// The original suspends its display when the app goes to the background (the OS suspend event, front-end.md
    /// §2.5–2.6: `FUN_10023da0`) or its window is collapsed (`FUN_1000c380` polled by the menu loop):
    /// `FUN_1000b7d0` sets +0x65 (DSp context inactive, `HideWindow`), and while it is set nothing presents and the
    /// menu's idle loop does not run (display-window-present.md §7; front-end.md §2.4 "while not suspended").
    /// Here: background or miniaturised → the idle timer stops and `driver.idle` is not called. The driver has no
    /// catch-up, so on resume (`FUN_1000b8b0`: +0x65 = 0, show, bring to front) its next pass simply runs late, as
    /// the original's did. The original painted the window black on resume and let the next present restore the
    /// image; here the held screen is shown at once (the menu would otherwise stay black until a button redraws).
    private func updateSuspension() {
        guard driver != nil, shell != nil else { return }
        let suspend = !NSApp.isActive || shell.windowedWindow.isMiniaturized
        guard suspend != suspended else { return }
        suspended = suspend
        if suspend {
            timer?.invalidate()
            if cursorHidden {
                NSCursor.unhide()
                cursorHidden = false
            }
        } else {
            present()
            timer?.start()
            idleFired()
        }
    }

    // MARK: Cursor

    /// The hide is honoured only over the game area while the window is key (the original hid it in play); the
    /// pointer comes back anywhere else (menu bar, other apps, outside the window).
    private func updateCursor() {
        let window = shell.currentWindow
        var hide = wantsCursorHidden && NSApp.isActive && window.isKeyWindow
        if hide {
            let inWindow = window.mouseLocationOutsideOfEventStream
            let inView = shell.view.convert(inWindow, from: nil)
            hide = shell.view.imageRectInPoints.contains(inView)
        }
        guard hide != cursorHidden else { return }
        if hide { NSCursor.hide() } else { NSCursor.unhide() }
        cursorHidden = hide
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        if cursorHidden {
            NSCursor.unhide()
            cursorHidden = false
        }
    }

    // MARK: ShellInputHandler

    /// Play reads the keyboard by polling (`pollKeyState`); key-downs are not used (⌃⌘F is the hidden menu item).
    func shellView(_ view: ShellView, keyDown event: NSEvent) {}

    /// ⌃⌘F: full screen (the largest whole multiple, black border — `.integerFit`) or back to the window.
    @objc private func toggleFullScreenChosen(_ sender: Any?) {
        if shell.isFullscreen { shell.exitFullscreen() } else { shell.enterFullscreen() }
        present()
    }

    func shellView(_ view: ShellView, mouseDown event: NSEvent) {}
}
