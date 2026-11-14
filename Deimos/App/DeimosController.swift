import AppKit
import DeimosAudio
import DeimosCore
import DeimosHost
import DeimosRender
import HectorShell
#if DEBUG
import HectorAudio
import Synchronization
#endif

/// The app delegate and shell owner (plan S6, A1): loads the original data, opens the 640×480 game window at the
/// largest whole scale that fits (D27.3), and drives `DeimosDriver` from a 1/240 s idle timer — keys polled once per
/// Mac tick (`GetKeys`; `heldKeys(seconds:)`), suspended while the app is hidden (`updateSuspension`), the window's RGB555 screen converted and presented whenever the driver says it changed, the
/// cursor requests honoured. All timing (Mac ticks, the FPS limiter, fade steps) is the driver's; the App only asks
/// often enough (every ~4 ms) that a tick boundary is never missed by more than a fraction of a tick.
///
/// Phase 2 (plan A3): the game's audio (`DeimosAudioEngine`, effects + music behind one pull source) rides the kit's
/// output as one stream voice (`ShellMixer.attachStream`) and is the driver's `audio` sink; key-down characters reach
/// the driver as Mac charCodes in `HeldKeys.typed` (the console); Caps Lock is `HeldKeys.capsLock` (the pause key);
/// ◇ `-film deNN` plays a shipped demo film (stand-in 5).
@MainActor final class DeimosController: NSObject, NSApplicationDelegate, ShellInputHandler {
    static let width = 640
    static let height = 480
    static let title = "Deimos Rising"

    private let options: LaunchOptions
    private var driver: DeimosDriver!
    private var shell: ShellWindowController!
    private var timer: ShellIdleTimer!
    /// The Mac's audio output and the game's stream voice on it; nil when sound is not available (the game then
    /// runs silent — `FUN_10047160`'s non-fatal "Sound not available" path).
    private var mixer: ShellMixer?
    private var streamID: Int?
    /// Key-down charCodes since the last `driver.idle` (the OS event queue the original's `GetOSEvent` reads):
    /// handed to the driver once, in the next `heldKeys(seconds:)`, then cleared.
    private var pendingTyped: [UInt8] = []
    #if DEBUG
    private var audioCounter: DebugAudioCounter?
    private var launchSeconds = 0.0
    private var lastDebugLog = 0.0
    private var debugCapsLockDown = false
    #endif

    init(options: LaunchOptions) {
        self.options = options
        super.init()
    }
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
            // ◇ `-film deNN` (stand-in 5): the session takes seed, level and player count from the film (`FUN_100069b0`).
            var film: Film?
            if let tag = options.film {
                do {
                    film = try Self.film(tag, in: assets)
                } catch {
                    // Like a missing data folder: DEBUG says so, then log and quit.
                    #if DEBUG
                    let alert = NSAlert()
                    alert.messageText = "Deimos Rising has no demo film “\(tag)” it can play."
                    alert.informativeText = "-film takes a shipped film tag: de01, de02, de03 or de04.\n\n\(error)"
                    alert.runModal()
                    #endif
                    fail("cannot play -film \(tag): \(error)")
                    return
                }
            }
            let audio = startAudio(assets: assets)
            // Mac OS X's 60 Hz TickCount: Ben played Deimos on OS X (gate 1, DECISIONS D30; Q1).
            driver = try DeimosDriver(assets: assets, prefs: .fresh, rate: .osx,
                                      start: SessionStart(sector: 1, players: film?.playerCount ?? 1, film: film),
                                      audio: audio)
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

        #if DEBUG
        launchSeconds = ProcessInfo.processInfo.systemUptime
        lastDebugLog = launchSeconds
        #endif
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

    /// No `film` record with this tag in the data (`-film` with an unknown or missing tag).
    private struct NoSuchFilm: Error, CustomStringConvertible {
        let tag: String
        var description: String { "no film record \"\(tag)\" in the data" }
    }

    /// The shipped `film` record `tag` (de01–de04), decoded.
    private static func film(_ tag: String, in assets: DeimosAssets) throws -> Film {
        guard let type = FourCC("film"), let id = FourCC(tag),
              let record = assets.index.record(type: type, id: id) else { throw NoSuchFilm(tag: tag) }
        return try Film(data: assets.index.data(for: record))
    }

    /// Sound init (`FUN_10047160`): opens the Mac's output and the game's mixer and attaches the mixer as the
    /// output's stream voice. Any failure is logged and the game runs silent (the original's "Sound not available"
    /// path is non-fatal) — the driver then has no sink.
    private func startAudio(assets: DeimosAssets) -> (any DeimosAudioSink)? {
        do {
            let output = try ShellMixer(voices: 0)          // the stream voice is the only voice
            let engine = try DeimosAudioEngine(assets: assets)
            #if DEBUG
            let counter = DebugAudioCounter(engine: engine)
            audioCounter = counter
            streamID = output.attachStream(counter)
            mixer = output
            return counter
            #else
            streamID = output.attachStream(engine)
            mixer = output
            return engine
            #endif
        } catch {
            NSLog("Deimos Rising: sound not available, running silent: %@", "\(error)")
            return nil
        }
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
        #if DEBUG
        let before = audioCounter?.snapshot
        #endif
        let out = driver.idle(seconds: seconds, keys: heldKeys(seconds: seconds))
        #if DEBUG
        debugAfterIdle(seconds: seconds, before: before)
        #endif
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
        var capsLock = state.capsLock
        #if DEBUG
        if debugCapsLockHeld(seconds: seconds) { capsLock = true }
        #endif
        // The typed characters go to exactly one `idle` (the driver queues them into its next pass).
        let typed = pendingTyped
        pendingTyped = []
        return HeldKeys(held: state.held, capsLock: capsLock, typed: typed)
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
    /// Audio (A3): the driver's suspend / resume handlers send the music pause / resume (`10023dc8`, `10023e88`; a
    /// pause in progress keeps the music paused across them), and the game's stream voice is paused meanwhile.
    private func updateSuspension() {
        guard driver != nil, shell != nil else { return }
        let suspend = !NSApp.isActive || shell.windowedWindow.isMiniaturized
        guard suspend != suspended else { return }
        suspended = suspend
        if suspend {
            timer?.invalidate()
            driver.suspend()
            if let mixer, let streamID { mixer.setStreamPaused(streamID, true) }
            if cursorHidden {
                NSCursor.unhide()
                cursorHidden = false
            }
        } else {
            driver.resume()
            if let mixer, let streamID { mixer.setStreamPaused(streamID, false) }
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

    /// Play reads the held keys by polling (`pollKeyState`); a key-down (no auto-repeats — `GetOSEvent` keyDown) also
    /// queues its Mac charCodes for the console (⌃⌘F and ⌘Q are menu key equivalents and never get here).
    func shellView(_ view: ShellView, keyDown event: NSEvent) {
        guard !event.isARepeat else { return }
        pendingTyped += Self.macCharCodes(event.characters ?? "")
    }

    /// NSEvent characters → classic Mac keyDown charCodes (the codes `Console` switches on, `1002d2e0..1002d350`):
    /// the arrow function keys 0xF700–0xF703 → 0x1E ↑ / 0x1F ↓ / 0x1C ← / 0x1D →; the delete key (NSEvent 0x7F) →
    /// 0x08; return 0x0D stays 0x0D; other ASCII (0x01–0x7E: letters as typed, Esc 0x1B, keypad Enter 0x03, Tab)
    /// is the Mac's own code. Anything else (other function keys, non-ASCII) has no charCode here and is dropped.
    static func macCharCodes(_ characters: String) -> [UInt8] {
        var codes: [UInt8] = []
        for scalar in characters.unicodeScalars {
            switch scalar.value {
            case 0xF700: codes.append(Console.upArrow)          // NSUpArrowFunctionKey → 0x1E
            case 0xF701: codes.append(0x1F)                     // NSDownArrowFunctionKey
            case 0xF702: codes.append(0x1C)                     // NSLeftArrowFunctionKey
            case 0xF703: codes.append(0x1D)                     // NSRightArrowFunctionKey
            case 0x7F: codes.append(Console.backspace)          // NSDeleteCharacter (the delete key) → 0x08
            case 0x0D: codes.append(Console.returnKey)
            case 0x01...0x7E: codes.append(UInt8(scalar.value))
            default: break
            }
        }
        return codes
    }

    /// ⌃⌘F: full screen (the largest whole multiple, black border — `.integerFit`) or back to the window.
    @objc private func toggleFullScreenChosen(_ sender: Any?) {
        if shell.isFullscreen { shell.exitFullscreen() } else { shell.enterFullscreen() }
        present()
    }

    func shellView(_ view: ShellView, mouseDown event: NSEvent) {}

    // MARK: DEBUG checks (A3; compiled out of Release)

    #if DEBUG
    /// `-debugCapsLock <s>`: Caps Lock reads as down from `s` seconds after launch for `LaunchOptions.debugCapsLockHold`
    /// seconds (through `HeldKeys`, as the real key would); each edge is logged.
    private func debugCapsLockHeld(seconds: Double) -> Bool {
        guard let at = options.debugCapsLockAt else { return false }
        let t = seconds - launchSeconds
        let down = t >= at && t < at + LaunchOptions.debugCapsLockHold
        if down != debugCapsLockDown {
            debugCapsLockDown = down
            NSLog("Deimos Rising [DEBUG caps]: Caps Lock simulated %@ at %.1f s", down ? "DOWN" : "UP", t)
        }
        return down
    }

    /// After each `idle`: a music pause / resume routed by that pass is logged (the pause cue at a pass's begin means
    /// the pass ends in `.pauseWait`; the resume means the wait saw Caps Lock up), and every 5 s the counters.
    private func debugAfterIdle(seconds: Double, before: DebugAudioCounter.Snapshot?) {
        let t = seconds - launchSeconds
        if let before, let now = audioCounter?.snapshot {
            if now.pauses > before.pauses {
                NSLog("Deimos Rising [DEBUG pause]: music pause routed by a pass at %.1f s - the .pauseWait path is reached", t)
            }
            if now.resumes > before.resumes {
                NSLog("Deimos Rising [DEBUG pause]: music resume routed at %.1f s - the pause wait ended", t)
            }
        }
        guard seconds - lastDebugLog >= 5 else { return }
        lastDebugLog = seconds
        if let s = audioCounter?.snapshot {
            NSLog("Deimos Rising [DEBUG audio]: %.0f s: cues routed %ld (sound %ld, music %ld; pause %ld, resume %ld), frames rendered %ld",
                  t, s.sounds + s.music, s.sounds, s.music, s.pauses, s.resumes, s.frames)
        } else {
            NSLog("Deimos Rising [DEBUG audio]: %.0f s: no audio engine (running silent)", t)
        }
    }
    #endif
}

#if DEBUG
/// DEBUG only (A3's machine check, the SDL audio-out `framesRendered` pattern): the engine behind a counting wrapper —
/// cues routed to the sink (game thread) and frames the engine rendered (audio thread). Counting here keeps
/// `DeimosAudio` untouched; the wrapper forwards every call unchanged.
final class DebugAudioCounter: DeimosAudioSink, PCMPullSource {
    struct Snapshot {
        var sounds: Int
        var music: Int
        var pauses: Int
        var resumes: Int
        var frames: Int
    }

    private let engine: DeimosAudioEngine
    private let sounds = Atomic<Int>(0)
    private let music = Atomic<Int>(0)
    private let pauses = Atomic<Int>(0)
    private let resumes = Atomic<Int>(0)
    private let frames = Atomic<Int>(0)

    init(engine: DeimosAudioEngine) { self.engine = engine }

    var outputRate: Double { engine.outputRate }

    func apply(sounds: [SoundCue], music: [MusicCue], haltEffectsAt: Int?) {
        self.sounds.add(sounds.count, ordering: .relaxed)
        self.music.add(music.count, ordering: .relaxed)
        for cue in music {
            if cue == .pause { pauses.add(1, ordering: .relaxed) }
            if cue == .resume { resumes.add(1, ordering: .relaxed) }
        }
        engine.apply(sounds: sounds, music: music, haltEffectsAt: haltEffectsAt)
    }

    func render(into buffer: UnsafeMutableBufferPointer<Float>, frames: Int) {
        engine.render(into: buffer, frames: frames)
        self.frames.add(frames, ordering: .relaxed)
    }

    var snapshot: Snapshot {
        Snapshot(sounds: sounds.load(ordering: .relaxed), music: music.load(ordering: .relaxed),
                 pauses: pauses.load(ordering: .relaxed), resumes: resumes.load(ordering: .relaxed),
                 frames: frames.load(ordering: .relaxed))
    }
}
#endif
