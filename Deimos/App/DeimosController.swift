import AppKit
import DeimosCore
import DeimosHost
import DeimosRender
import HectorShell

/// The app delegate and shell owner (plan S6, A1): loads the original data, opens the 640×480 game window at the
/// largest whole scale that fits (D27.3), and drives `DeimosDriver` from a 1/240 s idle timer — keys polled once per
/// fire (`GetKeys`), the window's RGB555 screen converted and presented whenever the driver says it changed, the
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

    // MARK: Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = Self.makeMenuBar()
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
            driver = try DeimosDriver(assets: assets, prefs: .fresh, rate: .classic,
                                      start: SessionStart(sector: 1, players: 1, film: nil))
        } catch {
            fail("cannot load the original data: \(error)")
            return
        }

        shell = ShellWindowController(title: Self.title, logicalWidth: Self.width, logicalHeight: Self.height,
                                      styleMask: [.titled, .miniaturizable], scalingPolicy: .integerFit)
        shell.view.inputHandler = self
        sizeToWholeScale(shell.windowedWindow)
        present()                                                       // black until the first pass presents
        shell.windowedWindow.makeKeyAndOrderFront(nil)
        NSApp.activate()

        timer = ShellIdleTimer(interval: 1.0 / 240.0) { [weak self] in self?.idleFired() }
        timer.start()
        idleFired()
    }

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

    /// The app menu only (the original had no menus in play): About hidden, Quit ⌘Q.
    private static func makeMenuBar() -> NSMenu {
        let bar = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: title)
        appMenu.addItem(NSMenuItem(title: "Quit \(title)", action: #selector(NSApplication.terminate(_:)),
                                   keyEquivalent: "q"))
        appItem.submenu = appMenu
        bar.addItem(appItem)
        return bar
    }

    // MARK: Clock

    /// One 1/240 s fire: the driver runs as far as its clock allows; a changed screen is presented.
    private func idleFired() {
        guard driver != nil else { return }
        let state = shell.view.pollKeyState()
        let out = driver.idle(seconds: ProcessInfo.processInfo.systemUptime,
                              keys: HeldKeys(held: state.held, capsLock: state.capsLock))
        for request in out.requests {
            switch request {
            case .hideCursor: wantsCursorHidden = true
            case .showCursor: wantsCursorHidden = false
            }
        }
        if out.screenChanged { present() }
        updateCursor()
    }

    /// Copies the driver's screen into the window bitmap (x1R5G5B5 → 0xAARRGGBB) and shows it.
    private func present() {
        if let driver { ScreenRGBA.convert(driver.screen, into: bitmap.pixels) }
        shell.view.present(bitmap)
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

    /// Play reads the keyboard by polling (`pollKeyState`); key-downs only matter for ⌃⌘F, which toggles full
    /// screen (the largest whole multiple, black border — `.integerFit`).
    func shellView(_ view: ShellView, keyDown event: NSEvent) {
        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if event.keyCode == 0x03, !event.isARepeat, mods.contains([.control, .command]),
           mods.isDisjoint(with: [.option, .shift]) {
            if shell.isFullscreen { shell.exitFullscreen() } else { shell.enterFullscreen() }
            present()
        }
    }

    func shellView(_ view: ShellView, mouseDown event: NSEvent) {}
}
