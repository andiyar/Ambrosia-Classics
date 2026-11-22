import AppKit
import DeimosAudio
import DeimosCore
import DeimosHost
import DeimosRender
import HectorGraphics
import HectorInput
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
/// the driver as Mac charCodes in `HeldKeys.typed` (the console); Caps Lock is `HeldKeys.capsLock` (the pause key).
///
/// Phase 4 (plan S8a AW): the app starts as the original does — the front end's boot entry: the loading screen, the
/// two logos, the main menu — and everything is reached from the menu. Into `HeldKeys` go the mouse (position,
/// button, mouse-downs, in the game's 640×480 picture under any scale or full screen), every key event with its
/// auto-repeat mark, the pad's keys, and the shell's events (About, Quit, the system's Quit request, suspend /
/// resume, the answer to a question). The shell requests are honoured (the cursor, About on / off, quit, a question
/// as a normal macOS alert, the system beep); the settings and the Last Film live in `~/Library/Application
/// Support/Ambrosia Classics/Deimos Rising` (rulings 6, 7); the app's resource fork is read and its pictures decoded
/// here (ruling 9); the settings' Full Screen byte chooses full screen or a window at launch (ruling 13). Hidden
/// switches: `-film deNN` (ruling 10), the mute switch (D42) and the key log (`-keylog` or the `keylog` default:
/// `KeyLog`, the bomb-freeze diagnosis); DEBUG only, `-debugCapsLock`.
@MainActor final class DeimosController: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuItemValidation,
                                         ShellInputHandler {
    static let width = 640
    static let height = 480
    static let title = "Deimos Rising"

    private let options: LaunchOptions
    private var driver: DeimosDriver!
    private var shell: ShellWindowController!
    private var timer: ShellIdleTimer!
    /// The Mac's audio output and the game's stream voice on it; nil when sound is not available (the game then
    /// runs silent — `FUN_10047160`'s non-fatal "Sound not available" path) or the app was launched muted.
    private var mixer: ShellMixer?
    private var streamID: Int?
    /// Key-down charCodes since the last `driver.idle` (the OS event queue the original's `GetOSEvent` reads):
    /// handed to the driver once, in the next `heldKeys(seconds:)`, then cleared. The other queues the same way:
    /// every keyDown / autoKey event, the mouse-downs, the shell's own events.
    private var pendingTyped: [UInt8] = []
    private var pendingKeyEvents: [KeyEvent] = []
    private var pendingMouseDowns: [MousePoint] = []
    private var pendingEvents: [ShellEvent] = []
    /// "About Deimos Rising…" is enabled (`ShellRequest.aboutEnabled`; the OS X build never greys it, D9).
    private var aboutEnabled = true
    /// The front end asked to quit (the settings are already written): the next terminate goes through.
    private var quitting = false
    /// A question waits to be put as an alert (one at a time: the front end waits for its answer).
    private var pendingQuestion: ShellQuestion?
    /// The system asked the app to quit while it was in the background: the driver runs, unseen and with no live
    /// input (`heldKeys`), until `BackgroundQuitPump` says stop — the shell's quit, the request held for the menu, the
    /// flag taken where nothing reads it (the level select), or its hard bound — and the app sleeps again. The
    /// original's pump reads the Quit event while suspended and resumes first (D10).
    private var backgroundPump: BackgroundQuitPump?
    /// Caps Lock as last polled while the app was active: what a background pump hands the driver (no live input).
    private var lastActiveCapsLock = false
    /// ◇ The hidden key log (`LaunchOptions.keyLog`); nil when the switch is off.
    private var keyLog: KeyLog?
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
        // Command and Option are read once, first (`1000015c` / `1000016c`): Command = the quiet launch (no `publ`,
        // no `inmu`), Option = the configuration window before the logos.
        let flags = NSEvent.modifierFlags
        let launch = LaunchModifiers(command: flags.contains(.command), option: flags.contains(.option))
        NSApp.mainMenu = makeMenuBar()
        guard let dataDirectory = DeimosAssets.dataDirectory() else {
            #if DEBUG
            let detail = "Run tools/stage-deimos.sh (or set DEIMOS_DATA to Resources/Deimos/Data)."
            #else
            let detail = "The app's Contents/Resources/Deimos/Data folder is missing. Download the app again."
            #endif
            refuseLaunch("Deimos Rising's original data folder is missing from this app.", detail: detail,
                         log: "no Data folder at Contents/Resources/Deimos/Data")
            return
        }
        // Rulings 6 and 7: the settings file and the Last Film share one folder; the Last Film's `Local` is the tag
        // index's second root, so a film saved last time is found ahead of the shipped copy.
        let lastFilm = LastFilmFileStore()
        let settings = PrefsStore(folder: lastFilm.root)
        let prefs: DeimosPrefs
        do {
            var assets = try DeimosAssets.load(dataDirectory: dataDirectory, secondLocalRoot: lastFilm.localRoot)
            let fork = Self.appResourceFork()
            assets.shellPictures = fork.pictures
            // ◇ `-film deNN` (ruling 10): played as soon as the menu is up, as a demo, then the menu again.
            var film: Film?
            if let tag = options.film {
                do {
                    film = try FilmLookup.film(tag, in: assets)
                } catch {
                    refuseLaunch("Deimos Rising has no demo film “\(tag)” it can play.",
                                 detail: "-film takes a shipped film tag: de01, de02, de03 or de04.\n\n\(error)",
                                 log: "cannot play -film \(tag): \(error)")
                    return
                }
            }
            // The prefs load (`FUN_10004540`) writes a fresh file at once when there is none; whether one was there
            // decides the first launch (the unit names on the loading screen, Ben 2026-11-20).
            prefs = (try? settings.load()) ?? .fresh
            let audio = options.mute ? nil : startAudio(assets: assets)
            let frontEnd = try FrontEnd(assets: assets, prefs: prefs, launch: launch, soundAvailable: audio != nil,
                                        film: film, shellResources: fork.resources,
                                        firstLaunch: !settings.fileExisted)
            // Mac OS X's 60 Hz TickCount: Ben played Deimos on OS X (gate 1, DECISIONS D30; Q1).
            driver = DeimosDriver(frontEnd: frontEnd, rate: .osx, audio: audio, settingsStore: settings,
                                  lastFilmStore: lastFilm)
        } catch {
            // The folder is there but its contents do not load (design §7.7): say so, log and quit.
            refuseLaunch("Deimos Rising's original data could not be loaded.",
                         detail: "\(dataDirectory.path)\n\n\(error)",
                         log: "cannot load the original data: \(error)")
            return
        }

        shell = ShellWindowController(title: Self.title, logicalWidth: Self.width, logicalHeight: Self.height,
                                      styleMask: Self.windowStyle, scalingPolicy: .integerFit)
        shell.view.inputHandler = self
        shell.windowedWindow.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(windowMiniaturizeChanged(_:)),
                                               name: NSWindow.didMiniaturizeNotification,
                                               object: shell.windowedWindow)
        NotificationCenter.default.addObserver(self, selector: #selector(windowMiniaturizeChanged(_:)),
                                               name: NSWindow.didDeminiaturizeNotification,
                                               object: shell.windowedWindow)
        sizeToWholeScale(shell.windowedWindow)
        present()                                                       // black until the first pass presents
        // Ruling 13 (`osx-build.md` D6, X `10000230`): byte pref 4 (Full Screen, 1 in a fresh file) read at launch —
        // set: full screen; clear: the 640×480 window. A change in the settings window takes effect at the next launch.
        // Entering full screen does nothing with no main screen: the window is shown then.
        if prefs.bytePrefs.indices.contains(4), prefs.bytePrefs[4] != 0 {
            shell.enterFullscreen()
        }
        if !shell.isFullscreen {
            shell.windowedWindow.makeKeyAndOrderFront(nil)
        }
        NSApp.activate()
        if options.keyLog { keyLog = KeyLog(shell: shell) }

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
    /// titled + miniaturisable (collapse), not resizable (whole-number scale, D27.3). Phase 4 S8a adds the close button
    /// (the original's window had none), which does what ⌘Q does (`windowShouldClose`).
    static let windowStyle: NSWindow.StyleMask = [.titled, .closable, .miniaturizable]

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

    /// The shared refusal (Phase 4 S8a; ruling 10): a launch the app cannot go on with — a bad `-film` tag, a missing
    /// data folder, data that does not load — says so in an alert (in Release too), then logs and quits.
    private func refuseLaunch(_ message: String, detail: String, log: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = detail
        alert.runModal()
        fail(log)
    }

    /// The app's own resource fork as committed (`Contents/Resources/Deimos/Deimos Rising.rsrc`, copied in by the
    /// build): every resource by type and id for the front end's dialogs (`FrontEndState.shellResources`, read with
    /// `DialogResources.readFork`), and the pictures Core draws — PICT 1000 (the developer logo) and PICT 190–197 (the
    /// controls window's) — decoded with HectorKit (ruling 9: Core never decodes a PICT). A missing or unreadable file
    /// or picture is logged and left out: the logo is then not drawn and the settings windows close at once, as Core
    /// does without its resources.
    private static func appResourceFork(bundle: Bundle = .main) -> (resources: [ShellResourceKey: [UInt8]],
                                                                    pictures: [Int16: ShellPicture]) {
        guard let url = bundle.resourceURL?.appendingPathComponent("Deimos/Deimos Rising.rsrc"),
              let data = try? Data(contentsOf: url) else {
            NSLog("Deimos Rising: no app resource fork at Contents/Resources/Deimos/Deimos Rising.rsrc")
            return ([:], [:])
        }
        let resources: [ShellResourceKey: [UInt8]]
        do {
            resources = try DialogResources.readFork([UInt8](data))
        } catch {
            NSLog("Deimos Rising: the app resource fork does not read: %@", "\(error)")
            return ([:], [:])
        }
        var pictures: [Int16: ShellPicture] = [:]
        let pict = FourCC("PICT")!
        for id in [Int16(1000)] + Array(Int16(190)...Int16(197)) {
            guard let bytes = resources[ShellResourceKey(pict, id)] else { continue }   // DITL 191 uses no 194
            do {
                let decoded = try PICT.decodeAny(data: Data(bytes)).pict
                if let picture = ShellPictures.picture(width: decoded.width, height: decoded.height,
                                                       rgba: [UInt8](decoded.rgba)) {
                    pictures[id] = picture
                }
            } catch {
                NSLog("Deimos Rising: PICT %d does not decode: %@", Int(id), "\(error)")
            }
        }
        return (resources, pictures)
    }

    /// Sound init (`FUN_10047160`): decodes the game's sounds into its mixer first, then opens the Mac's output and
    /// attaches the mixer as the output's stream voice. Any failure is logged and the game runs silent (the original's
    /// "Sound not available" path is non-fatal) — the driver then has no sink.
    private func startAudio(assets: DeimosAssets) -> (any DeimosAudioSink)? {
        do {
            let engine = try DeimosAudioEngine(assets: assets)
            let output = try ShellMixer(voices: 0)          // the stream voice is the only voice
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

    /// The app menu (ruling 12, grounding C §5; the OS X build's bar, `osx-build.md` D7): "About Deimos Rising…"
    /// (MENU 128 item 1: the credits screen, `ShellEvent.aboutChosen`; on or off as the front end asks — the OS X
    /// build never greys it, D9) and Quit ⌘Q (`ShellEvent.quitChosen`: the front end acts on it at the menu and the
    /// level select, the driver in the Caps Lock pause, and it is dropped elsewhere). Plus a hidden Full Screen ⌃⌘F
    /// item — the shortcut goes through the menu's key-equivalent matching (layout-independent, as Aki's and BTX's
    /// Full Screen items do), but the original had no such menu entry, so it is not shown. Not built: X's
    /// Preferences… item (D8; no shell event for it) and its greyed Edit menu.
    private func makeMenuBar() -> NSMenu {
        let bar = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: Self.title)
        let about = NSMenuItem(title: "About \(Self.title)…", action: #selector(aboutChosen(_:)), keyEquivalent: "")
        about.target = self
        appMenu.addItem(about)
        appMenu.addItem(.separator())
        let fullScreen = NSMenuItem(title: "Full Screen", action: #selector(toggleFullScreenChosen(_:)),
                                    keyEquivalent: "f")
        fullScreen.keyEquivalentModifierMask = [.control, .command]
        fullScreen.target = self
        fullScreen.isHidden = true
        fullScreen.allowsKeyEquivalentWhenHidden = true
        appMenu.addItem(fullScreen)
        let quit = NSMenuItem(title: "Quit \(Self.title)", action: #selector(quitChosen(_:)), keyEquivalent: "q")
        quit.target = self
        appMenu.addItem(quit)
        appItem.submenu = appMenu
        bar.addItem(appItem)
        return bar
    }

    @objc private func aboutChosen(_ sender: Any?) { pendingEvents.append(.aboutChosen) }

    @objc private func quitChosen(_ sender: Any?) { pendingEvents.append(.quitChosen) }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(aboutChosen(_:)) { return aboutEnabled && driver != nil }
        return true
    }

    /// The window's close button is ⌘Q: the front end decides, and the window stays.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        pendingEvents.append(.quitChosen)
        return false
    }

    // MARK: Quit

    /// Every quit goes through the front end (question 4). A terminate the front end asked for (`ShellRequest.quit`:
    /// the driver has already written the settings) goes through, as does one before the game is up (a refused
    /// launch). Any other — the Dock's Quit, log-out, an AppleScript quit — is the system's Quit request: queued as
    /// `ShellEvent.quitRequested` and the terminate cancelled; the front end acts on it at the menu and the level
    /// select, and holds it elsewhere until the menu is back (X's pump, D10).
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if quitting || driver == nil { return .terminateNow }
        pendingEvents.append(.quitRequested)
        if suspended && backgroundPump == nil {                         // in the background: run the driver, unseen
            backgroundPump = BackgroundQuitPump()
            timer?.start()
        }
        return .terminateCancel
    }

    // MARK: Clock

    /// One 1/240 s fire: the driver runs as far as its clock allows; a changed screen is presented.
    private func idleFired() {
        guard driver != nil, !quitting, !suspended || backgroundPump != nil else { return }
        let seconds = ProcessInfo.processInfo.systemUptime
        #if DEBUG
        let before = audioCounter?.snapshot
        #endif
        let out = driver.idle(seconds: seconds, keys: heldKeys(seconds: seconds))
        #if DEBUG
        debugAfterIdle(seconds: seconds, before: before)
        #endif
        var quit = false
        for request in out.requests {
            switch request {
            case .hideCursor: wantsCursorHidden = true
            case .showCursor: wantsCursorHidden = false
            case let .aboutEnabled(on): aboutEnabled = on
            case .quit: quit = true                                     // the driver wrote the settings as it began
            case .saveLastFilm: break                                   // the driver hands it to the Last Film store
            case let .ask(question): ask(question)
            case .beep: if !options.mute { NSSound.beep() }             // SysBeep(1); none when launched muted
            }
        }
        if out.screenChanged { present() }
        updateCursor()
        if quit {
            quitting = true
            timer?.invalidate()
            NSApp.terminate(nil)
            return
        }
        // A Quit request pumped in the background: sleep again when the pump says so.
        if suspended, var pump = backgroundPump {
            if pump.shouldStop(after: driver) {
                backgroundPump = nil
                timer?.invalidate()
            } else {
                backgroundPump = pump
            }
        }
    }

    /// `ShellRequest.ask` (question 8: a normal macOS alert): put once the current fire is over, app-modal, above the
    /// full-screen window when there is one; its answer is queued as `ShellEvent.answer` (the front end holds a host
    /// wait until it is). The idle timer keeps firing under the alert (the driver just waits).
    private func ask(_ question: ShellQuestion) {
        guard pendingQuestion == nil else { return }
        pendingQuestion = question
        DispatchQueue.main.async { [weak self] in self?.putQuestion() }
    }

    private func putQuestion() {
        guard let question = pendingQuestion else { return }
        let alert = NSAlert()
        alert.messageText = question.message
        alert.addButton(withTitle: question.firstButton)
        alert.addButton(withTitle: question.secondButton)
        if shell.isFullscreen {
            alert.window.perform(#selector(NSWindow.deimosRaiseAboveShield), with: nil, afterDelay: 0,
                                 inModes: [.modalPanel])
        }
        let reply = alert.runModal()
        pendingQuestion = nil
        pendingEvents.append(.answer(reply == .alertFirstButtonReturn ? .first : .second))
        shell.currentWindow.makeKeyAndOrderFront(nil)
    }

    /// The Mac tick of the last full key poll.
    private var lastKeyPollTick: UInt32?
    /// The Mac tick of the last attempt to take the keyboard back (`KeyboardFocus`); nil before the first. Also
    /// starts the recovery window in which held keys are read from the hardware.
    private var lastFocusReclaimTick: UInt32?
    /// Attempts to take the keyboard back since the window was last key with the view first responder
    /// (`KeyboardFocus.maxAttempts`).
    private var focusReclaimAttempts = 0
    /// Keys held across a keyboard steal that the view no longer holds, read from the hardware once per Mac tick
    /// (`KeyboardFocus.stepRecovered`); each stays until the hardware reads it up or the view holds it again.
    private var recoveredKeys: Set<UInt16> = []

    /// The keys for this fire. A pass can begin only when the Mac tick moves (the limiter and fades wait on it), so
    /// the full poll (`pollKeyState`: modifiers, Caps Lock, and HectorKit's `CGPreflightListenEventAccess` ⌘-release
    /// probe; the pad) runs once per tick — the first fire after a boundary, i.e. before any pass that tick can start —
    /// and the other three-odd fires reuse `keyState`, which key-down/up/flags events keep current anyway. The pad's
    /// layout is assigned before each full poll for the screen on top (`DeimosDriver.padContext`; off — an empty
    /// layout — in the controls window). The mouse: where it is over the 640×480 picture (unclamped, as `GetMouse`),
    /// whether its button is down (`Button()`), the clicks since the last fire.
    /// Before each full poll, a full-screen game window that another app's hidden panel has left without the keyboard
    /// takes it back (`KeyboardFocus.shouldReclaim`; Ben's bomb freeze, 2026-11-22), retried at most every quarter
    /// second and at most eight times (about two seconds) after the window was last key with the view first responder;
    /// then the game stops trying until that is true again (so a panel another app opens on a second display is not
    /// fought for longer than that). Losing key drops every held key in the view, so for two seconds after each attempt
    /// the game's bound keys that the hardware reports down are picked up as recovered keys, and a recovered key stays
    /// until the hardware reads it up or the view holds it again (`KeyboardFocus.stepRecovered`, once per tick after
    /// the poll). The held set handed to the game is the view's plus the recovered keys: a key held across the steal,
    /// Command held to fire included, keeps working without a re-press for as long as it is held.
    /// In the background (a Quit request pumped while suspended) the driver gets NO live input: nothing held, the
    /// mouse button up, no mouse position, no poll (no pad keys), Caps Lock as last seen while active — only what
    /// was queued (the shell's events; any key or click queued before the switch) — so nothing the player does in
    /// another app reaches the game.
    private func heldKeys(seconds: Double) -> HeldKeys {
        if suspended {
            let keys = HeldKeys(capsLock: lastActiveCapsLock, typed: pendingTyped, mouseDowns: pendingMouseDowns,
                                keyEvents: pendingKeyEvents, events: pendingEvents)
            pendingTyped = []
            pendingKeyEvents = []
            pendingMouseDowns = []
            pendingEvents = []
            return keys
        }
        let tick = MacTicks.ticks(seconds: seconds, rate: driver.rate.perSecond)
        let state: ShellKeyState
        if tick != lastKeyPollTick {
            lastKeyPollTick = tick
            let window = shell.currentWindow
            let viewIsFirst = window.firstResponder === shell.view
            if window.isKeyWindow && viewIsFirst { focusReclaimAttempts = 0 }
            let reclaim = { (attempts: Int) in
                KeyboardFocus.shouldReclaim(appActive: NSApp.isActive, fullScreen: self.shell.isFullscreen,
                                            suspended: self.suspended,
                                            questionUp: self.pendingQuestion != nil || NSApp.modalWindow != nil,
                                            windowIsKey: window.isKeyWindow, firstResponderIsView: viewIsFirst,
                                            ticksSinceLastAttempt: self.lastFocusReclaimTick.map { tick &- $0 },
                                            attemptsSinceKey: attempts)
            }
            if reclaim(focusReclaimAttempts) {
                lastFocusReclaimTick = tick
                focusReclaimAttempts += 1
                window.makeKeyAndOrderFront(nil)
                if !viewIsFirst { window.makeFirstResponder(shell.view) }
                keyLog?.note("reclaim keyboard")
            } else if focusReclaimAttempts == KeyboardFocus.maxAttempts && reclaim(0) {
                // Only the limit stopped a ninth try: counted past it so the give-up is noted once.
                focusReclaimAttempts += 1
                keyLog?.note("reclaim gave up")
            }
            shell.view.padMapping = driver.padContext.map {
                DeimosPadLayout.mapping(keySet: driver.padKeySet, context: $0)
            } ?? ShellPadMapping(bindings: [:])
            state = shell.view.pollKeyState()                           // the pad's key events arrive from here
            // Wrapping subtraction: a Mac tick counter roll-over still gives the small true difference.
            let inRecovery = KeyboardFocus.inRecovery(ticksSinceLastAttempt: lastFocusReclaimTick.map { tick &- $0 })
            if inRecovery || !recoveredKeys.isEmpty {
                recoveredKeys = KeyboardFocus.stepRecovered(recovered: recoveredKeys, viewHeld: state.held,
                                                            bound: driver.padKeySet.codes, inRecovery: inRecovery,
                                                            isDown: {
                    CGEventSource.keyState(.combinedSessionState, key: CGKeyCode($0))
                })
            }
            var given = state
            given.held = state.held.union(recoveredKeys)
            keyLog?.pollState(given)                                    // the held set the game is given
        } else {
            state = shell.view.keyState
        }
        let held = state.held.union(recoveredKeys)
        var capsLock = state.capsLock
        lastActiveCapsLock = capsLock
        #if DEBUG
        if debugCapsLockHeld(seconds: seconds) { capsLock = true }
        #endif
        // The queued input goes to exactly one `idle` (the driver queues it into its next pass).
        let keys = HeldKeys(held: held, capsLock: capsLock, typed: pendingTyped,
                            mouse: Self.mousePoint(shell.view.logicalMouseLocation()),
                            mouseButton: NSEvent.pressedMouseButtons & 1 != 0, mouseDowns: pendingMouseDowns,
                            keyEvents: pendingKeyEvents, events: pendingEvents)
        pendingTyped = []
        pendingKeyEvents = []
        pendingMouseDowns = []
        pendingEvents = []
        return keys
    }

    /// A canvas point (`ShellScaling.logicalPoint`: truncating, unclamped) as the game's `MousePoint`.
    private static func mousePoint(_ p: ShellPoint) -> MousePoint {
        MousePoint(h: Int32(clamping: p.h), v: Int32(clamping: p.v))
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
    /// Audio (A3): as in 1.0.6, only the MUSIC pauses. The driver's suspend handler sends the music pause
    /// (`10023dc8`, `FUN_10048220(1)`) and its resume handler (`10023e10`) the music resume (`10023e88`) unless the
    /// pause flag r2−0x617b holds it (`10023e7c..10023e84`: the game was already in the Caps Lock pause). The original
    /// touched no sound channel on suspend, so effects already sounding ring out: the game's stream voice keeps
    /// running in the background (it is detached only on quit).
    /// Phase 4: each change also reaches the front end as its shell event (`.suspend` / `.resume`, the OS events the
    /// menu's pump reads) with the next pass's input.
    private func updateSuspension() {
        guard driver != nil, shell != nil, !quitting else { return }
        let suspend = !NSApp.isActive || shell.windowedWindow.isMiniaturized
        guard suspend != suspended else { return }
        suspended = suspend
        keyLog?.suspendedChanged(suspend)
        if suspend {
            recoveredKeys = []                                          // nothing carries over an app switch
            timer?.invalidate()
            driver.suspend()
            pendingEvents.append(.suspend)
            if cursorHidden {
                NSCursor.unhide()
                cursorHidden = false
            }
        } else {
            backgroundPump = nil
            driver.resume()
            pendingEvents.append(.resume)
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
        // Every quit path writes the settings: the front end's quit already did (`DeimosDriver.settingsSaved`); any
        // terminate that bypassed it still saves here.
        if driver != nil && !driver.settingsSaved { driver.shutdown() }
        // The audio stops with the game (as Ferazel's quit stops its audio): the stream voice is detached.
        if let mixer, let streamID { mixer.detachStream(streamID) }
        streamID = nil
        if cursorHidden {
            NSCursor.unhide()
            cursorHidden = false
        }
    }

    // MARK: ShellInputHandler

    /// Play reads the held keys by polling (`pollKeyState`); a key-down (no auto-repeats — `GetOSEvent` keyDown) also
    /// queues its Mac charCodes for the console (⌃⌘F and ⌘Q are menu key equivalents and never get here). Every
    /// key-down, auto-repeats included, is also a key event (`HeldKeys.keyEvents`: keyDown and autoKey, the menu, name
    /// entry and the controls window read them) with its virtual key code; a key whose characters give no charCode
    /// is still a key event, with charCode 0.
    func shellView(_ view: ShellView, keyDown event: NSEvent) {
        keyLog?.viewEvent("keyDown", event)
        let codes = Self.macCharCodes(event.characters ?? "")
        for code in codes.isEmpty ? [0] : codes {
            pendingKeyEvents.append(KeyEvent(charCode: code, keyCode: event.keyCode, autoRepeat: event.isARepeat))
        }
        guard !event.isARepeat else { return }
        pendingTyped += codes
    }

    /// A key-up or modifier change in the view: nothing for the game (play polls `keyState`, which the view keeps
    /// itself); logged only, when the key log is on.
    func shellView(_ view: ShellView, keyUp event: NSEvent) { keyLog?.viewEvent("keyUp", event) }
    func shellView(_ view: ShellView, flagsChanged event: NSEvent) { keyLog?.viewEvent("flagsChanged", event) }

    /// A pad key pressed (HectorKit D16, from `pollKeyState`): a key-down as the keyboard's would be — a key event
    /// and its typed character, for the keys a pad layout binds outside play (`PadKeys`). A held pad key never
    /// repeats (the S7 handoff's item 3).
    func shellView(_ view: ShellView, padKeyDown keyCode: UInt16) {
        guard let event = PadKeys.keyEvent(forPadKey: keyCode) else { return }
        pendingKeyEvents.append(event)
        pendingTyped.append(event.charCode)
    }

    /// NSEvent characters → classic Mac keyDown charCodes (the codes `Console` switches on, `1002d2e0..1002d350`;
    /// its default case stores any byte, so every key the classic Mac gave a charCode is passed on):
    /// the arrow function keys 0xF700–0xF703 → 0x1E ↑ / 0x1F ↓ / 0x1C ← / 0x1D →; the delete key (NSEvent 0x7F) →
    /// 0x08; forward delete → 0x7F; Home 0x01, End 0x04, Page Up 0x0B, Page Down 0x0C, Help 0x05; every function key
    /// F1–F35 → 0x10; keypad Clear → 0x1B; Shift-Tab (NSEvent 0x19) → Tab 0x09; return 0x0D stays 0x0D; other ASCII
    /// (0x01–0x7E: letters as typed, Esc 0x1B, keypad Enter 0x03, Tab) is the Mac's own code; a character above 0x7F is
    /// its Mac Roman byte. Anything else (a character with no Mac Roman byte, other AppKit function keys) is dropped.
    static func macCharCodes(_ characters: String) -> [UInt8] {
        var codes: [UInt8] = []
        for scalar in characters.unicodeScalars {
            switch scalar.value {
            case 0xF700: codes.append(Console.upArrow)          // NSUpArrowFunctionKey → 0x1E
            case 0xF701: codes.append(0x1F)                     // NSDownArrowFunctionKey
            case 0xF702: codes.append(0x1C)                     // NSLeftArrowFunctionKey
            case 0xF703: codes.append(0x1D)                     // NSRightArrowFunctionKey
            case 0xF704...0xF726: codes.append(0x10)            // NSF1FunctionKey…NSF35FunctionKey (kFunctionKeyCharCode)
            case 0xF728: codes.append(0x7F)                     // NSDeleteFunctionKey (forward delete)
            case 0xF729: codes.append(0x01)                     // NSHomeFunctionKey
            case 0xF72B: codes.append(0x04)                     // NSEndFunctionKey
            case 0xF72C: codes.append(0x0B)                     // NSPageUpFunctionKey
            case 0xF72D: codes.append(0x0C)                     // NSPageDownFunctionKey
            case 0xF739: codes.append(0x1B)                     // NSClearLineFunctionKey (keypad Clear)
            case 0xF746: codes.append(0x05)                     // NSHelpFunctionKey
            case 0x19: codes.append(0x09)                       // NSBackTabCharacter (Shift-Tab) → Tab
            case 0x7F: codes.append(Console.backspace)          // NSDeleteCharacter (the delete key) → 0x08
            case 0x0D: codes.append(Console.returnKey)
            case 0x01...0x7E: codes.append(UInt8(scalar.value))
            default:
                // Above 0x7F: the Mac Roman byte (U+F8FF, the Apple logo, is 0xF0); no byte → dropped.
                if let byte = String(Character(scalar)).data(using: .macOSRoman), byte.count == 1 {
                    codes.append(byte[byte.startIndex])
                }
            }
        }
        return codes
    }

    /// ⌃⌘F: full screen (the largest whole multiple, black border — `.integerFit`) or back to the window.
    @objc private func toggleFullScreenChosen(_ sender: Any?) {
        if shell.isFullscreen { shell.exitFullscreen() } else { shell.enterFullscreen() }
        present()
    }

    /// A click in the view (the picture or, in full screen, the black around it): queued at its point in the game's
    /// 640×480 picture under the current scale (`ShellScaling.logicalPoint`, unclamped, as the original's
    /// `GlobalToLocal`).
    func shellView(_ view: ShellView, mouseDown event: NSEvent) {
        keyLog?.viewEvent("mouseDown", event)
        let inView = view.convert(event.locationInWindow, from: nil)
        pendingMouseDowns.append(Self.mousePoint(ShellScaling.logicalPoint(
            viewPoint: inView, imageRect: view.imageRectInPoints, logicalWidth: Self.width, logicalHeight: Self.height)))
    }

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

extension NSWindow {
    /// An alert put while the game is full screen goes above the shielding-level window (Aki's `scheduleShieldingLevel`
    /// pattern: run inside the alert's modal session, after `runModal` has set its own level).
    @objc func deimosRaiseAboveShield() {
        level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
        orderFrontRegardless()
    }
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

    func isPlaying(_ id: FourCC) -> Bool { engine.isPlaying(id) }

    func isMusicFading() -> Bool { engine.isMusicFading() }

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
