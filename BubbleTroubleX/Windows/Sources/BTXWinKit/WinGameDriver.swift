import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import HectorGraphics

/// The original data as the Windows build ships it (D10, D15.4): a `Data/` folder beside the `.exe` holding the five
/// `.rsrc` files, `Fonts/` (the baked faces, W2) and `Decoded/` (the pre-decoded QuickTime-JPEG bands, D16.1).
public struct WinGameAssets {
    public let data: BTXGameData
    public let art: ArtBank
    public let sounds: SoundBankPCM
    public let text: BitmapFontRasterizer

    /// Loads and prewarms everything (the Mac's `applicationDidFinishLaunching` load). Off Apple the pre-decoded
    /// bands in `Decoded/` are registered first (on the Mac the real decoder runs and the folder is ignored).
    /// `fontsDirectory` defaults to `<dataDirectory>/Fonts`.
    public init(dataDirectory: URL, fontsDirectory: URL? = nil) throws {
        #if !canImport(ImageIO)
        let decoded = dataDirectory.appendingPathComponent("Decoded", isDirectory: true)
        if FileManager.default.fileExists(atPath: decoded.path) {
            try CodecImage.registerPrecomputed(directory: decoded)
        }
        #endif
        data = try BTXGameData(resourcesDirectory: dataDirectory)
        art = ArtBank(data: data)
        try art.prewarm()
        sounds = SoundBankPCM(data: data)
        try sounds.prewarm()
        text = try BitmapFontRasterizer(fontsDirectory: fontsDirectory
                                        ?? dataDirectory.appendingPathComponent("Fonts", isDirectory: true))
    }
}

/// The Windows port of the Mac replica's `BubbleTroubleX/App/BTXController.swift` (plan W4; D15.5 — ported, not
/// shared, so the Mac app stays untouched): owns the clocks (Invariant 4) and drives `FrontEnd` — splash, main menu,
/// attract demos, games, the C7 screens — → `Compositor` → `WinHost.present`, plays the cues through `WinAudio` and
/// carries out the `ShellRequest`s. Every rule is the Mac controller's; the deviations are platform-only (see the
/// notes on `setFullScreen`, the cursor and `displayFade`).
///
/// Clocks: the 1/60 s TickCount timer drives `FrontEnd.tick`; while a game or demo runs frames the 0.033 s Carbon
/// frame timer drives `FrontEnd.frame` instead — or, with the frame-limit cheat, a 0.001 s timer. Exactly one runs
/// at a time; missed fires are dropped (`WinTimer`). The host's main loop calls `step()` repeatedly.
public final class WinGameDriver {
    public struct Options {
        /// Info message 2's "Registered To:" name (the Mac passes `NSFullUserName()`).
        public var registeredName: String
        /// (month, day) for the occasions / birthday dialogs.
        public var today: () -> (month: Int, day: Int)
        /// Log sink (stderr in the executable).
        public var log: (String) -> Void

        public init(registeredName: String, today: @escaping () -> (month: Int, day: Int) = FrontEnd.systemToday,
                    log: @escaping (String) -> Void = { _ in }) {
            self.registeredName = registeredName
            self.today = today
            self.log = log
        }
    }

    /// Which timer runs (Invariant 4).
    public enum Clock: Equatable, Sendable { case none, frame, fastFrame, tick }

    public static let frameInterval: UInt64 = 33_000_000            // 0.033 s
    public static let fastFrameInterval: UInt64 = 1_000_000         // 0.001 s

    private let host: any WinHost
    private let data: BTXGameData
    private let art: ArtBank
    public let compositor: Compositor
    public let audio: WinAudio
    private let store: BTXPrefsStore
    public let dialogs: any WinDialogs
    private let options: Options
    private var prefs: BTXPrefs
    private var scores: HighScoreTable

    /// Everything from launch to quit; it owns the running `GameSession`.
    public private(set) var frontEnd: FrontEnd!
    public var session: GameSession? { frontEnd?.session }

    public private(set) var clock = Clock.none
    private var frameTimer = WinTimer(intervalNanoseconds: frameInterval)
    private var fastFrameTimer = WinTimer(intervalNanoseconds: fastFrameInterval)
    private var tickTimer = WinTimer(intervalNanoseconds: WinClock.nanosPerSecond, per: 60)   // 1/60 s

    /// The `_WipeScreen` / `_WipeScreenOut` being paced.
    private var wipe: (out: Bool, step: Int, row: Int, lastTick: UInt32)?

    // Menu state for W5's in-window menu bar (the Mac's `BTXMenus` properties).
    /// 'pref' and 'Full' enabled — the session's `.enableMenus`.
    public private(set) var playMenusEnabled = true
    /// `DisableMenuCommand(0, 'abou')` in effect — the session's `.disableAbout`.
    public private(set) var aboutDisabled = false
    /// A dialog is up: every menu item is disabled (Carbon `ModalDialog` is app-modal).
    public private(set) var dialogUp = false

    private var quitWithoutSaving = false
    private var saveOnQuit = false
    private var frontEndQuit = false
    /// Quit was chosen while a game runs outside its pause: ⌘ + key 0x0C goes into every frame's keys until the
    /// game's own ⌘Q check fades the music and quits.
    public private(set) var quitPending = false
    /// The driver has terminated (the host's loop ends).
    public private(set) var finished = false
    /// Saves that reached the store (tests).
    public private(set) var saveCount = 0

    public private(set) var cursorHidden = false
    public private(set) var mouseCaptured = false
    public private(set) var cursor = WinCursor.arrow
    /// `.beep` requests seen (the host also gets `beep()`).
    public private(set) var beeps = 0

    /// `CGDisplayFade` in-window: from → to darkness (0…255) over [start, start + duration] nanoseconds.
    private var fade: (from: Int, to: Int, start: UInt64, duration: UInt64)?
    public private(set) var displayFades: [(toBlack: Bool, seconds: Double)] = []

    private var pendingDialogs: [ShellRequest] = []
    private var pendingAnswers: [(FrontEnd) -> SessionOutput] = []
    private var handleDepth = 0
    private var suspendedAt: UInt32?
    private var clockOffset: UInt32 = 0

    private var keys = WinKeyState()
    private var mouse = (x: 0, y: 0)
    private var mouseButton = false
    /// The last mouse-down landed in the game screen (its mouse-up goes there too).
    private var mouseDownInGame = false

    /// Called after every frame fire with the running session (tests trace the demo).
    public var frameObserver: ((GameSession) -> Void)?
    /// Called after every present.
    public var presentObserver: ((WinFrame) -> Void)?

    /// Loads the prefs and builds the sound and the compositor (the first half of the Mac's
    /// `applicationDidFinishLaunching`); `start()` opens the front end.
    public init(assets: WinGameAssets, host: any WinHost, audioOutput: any WinAudioOutput,
                prefsBacking: any BTXPrefsBacking, dialogs: any WinDialogs, options: Options) throws {
        self.host = host
        self.data = assets.data
        self.art = assets.art
        self.dialogs = dialogs
        self.options = options
        store = BTXPrefsStore(backing: prefsBacking, legacyFileURL: nil,
                              factoryScores: try HighScoreTable.factory(from: assets.data))
        (prefs, scores) = store.load()
        compositor = Compositor(art: assets.art, text: assets.text)
        audio = WinAudio(output: audioOutput, sounds: assets.sounds, data: assets.data, log: options.log)
        applyPrefsToAudio()
    }

    /// `_InitMac` → `_Interface`: the front end and the splash's first output. (Full screen at launch is W5's —
    /// see `setFullScreen`.)
    public func start() {
        frontEnd = FrontEnd(data: data, prefs: prefs, highScores: scores, registeredName: options.registeredName,
                            today: options.today)
        var hooks = WinDialogHooks()
        hooks.playSound = { [unowned self] cue, level in audio.play(cue, sfxLevel: level) }
        hooks.livePrefs = { [unowned self] p, updateMusic in
            prefs = p
            applyPrefsToAudio()
            if updateMusic { audio.updateMusicVolume() }
        }
        hooks.modalStateChanged = { [unowned self] in modalStateChanged() }
        dialogs.hooks = hooks
        present()
        tickFired()                                                     // the splash's first output
    }

    // MARK: The main loop

    /// One pass of the host's loop: the queued events, then the running clock's fire if one is due (at most one).
    public func step() {
        guard !finished else { return }
        for event in host.pollEvents() {
            handleEvent(event)
            if finished { return }
        }
        let now = host.nanoseconds
        switch clock {
        case .frame: if frameTimer.poll(now: now) { frameFired() }
        case .fastFrame: if fastFrameTimer.poll(now: now) { frameFired() }
        case .tick: if tickTimer.poll(now: now) { tickFired() }
        case .none: break
        }
    }

    /// When the running clock fires next (nil: none runs) — the host may sleep until then.
    public var nextDeadline: UInt64? {
        switch clock {
        case .frame: frameTimer.nextFire
        case .fastFrame: fastFrameTimer.nextFire
        case .tick: tickTimer.nextFire
        case .none: nil
        }
    }

    // MARK: Quit

    /// Quit (Ctrl+Q — the Mac's ⌘Q — or the window's close box, the quit Apple event):
    /// - no game, the main menu idle: `_SaveGamePrefs`, then `_StopMusic`'s blocking fade, then the front end's
    ///   `.quit` terminates (saving again, as `_main` does);
    /// - no game, anything else: terminate now, prefs saved;
    /// - paused: `_PauseGame` case 0x17 — terminate now WITH the save;
    /// - any other game phase: ⌘ + 0x0C is injected into the frames' keys, so `_PlayGame`'s check runs its
    ///   `_StopMusic` fade and `.quitNow` follows.
    public func quitChosen() {
        guard !finished, frontEnd != nil else { terminate(); return }
        guard let session, session.isInGame else {
            if !quitThroughFrontEnd() { terminate() }
            return
        }
        if session.phase == .paused {
            saveOnQuit = true
            terminate()
        } else {
            quitPending = true
        }
    }

    private func quitThroughFrontEnd() -> Bool {
        guard let frontEnd, !frontEndQuit else { return false }
        if frontEnd.phase == .quit { return false }
        savePrefs()
        guard let out = frontEnd.quitFromMenuBar() else { return false }
        handle(out, now: ticksNow())
        return true
    }

    /// The Mac's `terminate` + `applicationWillTerminate`: quit saves the prefs from outside a game and from the
    /// pause (`saveOnQuit`); the game's own ⌘Q path (`.quitNow`) never saves (R7).
    private func terminate() {
        guard !finished else { return }
        frontEndQuit = true
        if !quitWithoutSaving && (saveOnQuit || !(session?.isInGame ?? false)) {
            savePrefs()
        }
        showCursor()
        finished = true
        selectClock()
        host.quit()
    }

    // MARK: Clocks

    private func applyPrefsToAudio() {
        audio.sfxVolumePref = prefs.sfxVolume
        audio.musicVolumePref = prefs.musicVolume
        audio.titleMusicPref = prefs.titleMusic
    }

    /// The keyboard as `GetKeys` reads it, re-polled once per fire.
    private func heldKeys() -> HeldKeys {
        let m = host.modifiers
        return HeldKeys(codes: keys.held, capsLock: m.contains(.capsLock), command: m.contains(.command))
    }

    /// `_GetMouse` in the 640×480 screen, plus `Button()`.
    private func mousePoint() -> MousePoint {
        MousePoint(h: mouse.x, v: mouse.y - WinCanvas.menuStripHeight, button: mouseButton)
    }

    private func frameFired() {
        guard let frontEnd else { return }
        var keys = heldKeys()
        if quitPending {
            keys.codes.insert(0x0c)
            keys.command = true
        }
        let now = ticksNow()
        handle(frontEnd.frame(keys: keys, now: now), now: now)
        if let session { frameObserver?(session) }
    }

    private func tickFired() {
        guard let frontEnd else { return }
        let now = ticksNow()
        var dirty = fade != nil                                        // the fade animates on the tick clock
        if var w = wipe, w.lastTick < now {
            w.row += 1
            w.lastTick = now
            let rows = Self.wipeRows(w)
            if w.row <= rows {
                applyWipeRow(w)
                dirty = true
            }
            wipe = w.row < rows ? w : nil
        }
        handle(frontEnd.tick(now: now, keys: heldKeys(), mouse: mousePoint()), now: now, alreadyDirty: dirty)
    }

    private static func wipeRows(_ w: (out: Bool, step: Int, row: Int, lastTick: UInt32)) -> Int {
        w.out ? Compositor.wipeOutSteps(w.step) : Compositor.wipeSteps(w.step)
    }

    private func applyWipeRow(_ w: (out: Bool, step: Int, row: Int, lastTick: UInt32)) {
        if w.out { compositor.applyWipeOut(row: w.row) } else { compositor.applyWipe(row: w.row) }
    }

    /// The clock the state calls for (the Mac's `selectClock` decision).
    public static func wantedClock(started: Bool, quitting: Bool, dialogModal: Bool, wantsFrameTimer: Bool,
                                   limitFrames: Bool?) -> Clock {
        if !started || quitting || dialogModal { return .none }
        if wantsFrameTimer { return limitFrames == false ? .fastFrame : .frame }
        return .tick
    }

    private func selectClock() {
        let want = Self.wantedClock(started: frontEnd != nil, quitting: finished || frontEnd?.phase == .quit,
                                    dialogModal: dialogs.isModal, wantsFrameTimer: frontEnd?.wantsFrameTimer ?? false,
                                    limitFrames: session?.limitFrames)
        guard want != clock else { return }
        frameTimer.invalidate()
        fastFrameTimer.invalidate()
        tickTimer.invalidate()
        let now = host.nanoseconds
        switch want {
        case .frame: frameTimer.start(now: now)
        case .fastFrame: fastFrameTimer.start(now: now)
        case .tick: tickTimer.start(now: now)
        case .none: break
        }
        clock = want
    }

    // MARK: Output

    /// Carries out one `SessionOutput` produced at TickCount `now` — the Mac's `handle`, step for step.
    private func handle(_ out: SessionOutput, now: UInt32, alreadyDirty: Bool = false) {
        handleDepth += 1
        defer { handleDepth -= 1 }
        var quitNow = false, quit = false
        audio.gameRunning = session != nil
        for request in out.requests {
            switch request {
            case .hideCursor: hideCursor()
            case .showCursor: showCursor()
            case let .enableMenus(on): playMenusEnabled = on
            case .haltAllSound: audio.haltEffects()
            case .quitNow: quitNow = true
            case .savePrefs: savePrefs()
            case let .setCursor(id): setCursor(id == 200 ? .hand : .arrow)
            case .restoreMousePosition: host.restoreMousePosition()
            case let .disableAbout(off): aboutDisabled = off
            case .beep:
                beeps += 1
                host.beep()
            case .watchCursor: setCursor(.arrow)
            case let .displayFade(toBlack, seconds): displayFade(toBlack: toBlack, seconds: seconds)
            case .quit: quit = true
            case .highScoreNameDialog, .levelSelectDialog, .prefsDialog, .hiScoreEraseDialog, .modalDialog, .closeDialog:
                pendingDialogs.append(request)
            }
        }
        for cue in out.music { audio.apply(cue) }
        for cue in out.sounds { audio.play(cue) }
        var dirty = alreadyDirty
        if !out.drawOps.isEmpty {
            if let w = wipe {
                for row in (w.row + 1)..<(Self.wipeRows(w) + 1) {
                    applyWipeRow((w.out, w.step, row, w.lastTick))
                }
                wipe = nil
            }
            compositor.apply(out.drawOps)
            dirty = true
            if let started = out.drawOps.lastWipe {
                wipe = (started.out, started.step, 0, now)
            }
        }
        if dirty { present() }

        if quitNow {                                                    // ⌘Q in play / a load failure: `_CleanUp`
            quitWithoutSaving = true
            terminate()
            return
        }
        if quit {                                                       // `gFinished`: `_main` saves, then quits
            terminate()
            return
        }
        if out.ended != nil && quitPending {    // the game ended before its ⌘Q check ran: an ordinary quit (saves)
            quitPending = false
            terminate()
            return
        }
        selectClock()
        showPendingDialogs()
        if handleDepth == 1 { drainAnswers() }
    }

    private func drainAnswers() {
        while !pendingAnswers.isEmpty, let frontEnd, !finished {
            let answer = pendingAnswers.removeFirst()
            handle(answer(frontEnd), now: ticksNow())
        }
    }

    /// TickCount as the driver hands it out: frozen while a dialog blocks, with the blocked spans taken out.
    public func ticksNow() -> UInt32 {
        (suspendedAt ?? hostTicks()) &- clockOffset
    }

    private func hostTicks() -> UInt32 { WinClock.ticks(nanoseconds: host.nanoseconds) }

    /// The compositor's screen (and the fade) to the host.
    private func present() {
        let frame = WinFrame(screen: compositor.screen, fade: fadeLevel())
        host.present(frame)
        presentObserver?(frame)
    }

    /// The frame as it would be presented now (dumps).
    public var currentFrame: WinFrame { WinFrame(screen: compositor.screen, fade: fadeLevel()) }

    /// `_SaveGamePrefs`: the prefs as the front end / running game hold them plus the high scores.
    private func savePrefs() {
        if let frontEnd {
            prefs = frontEnd.prefs
            scores = frontEnd.highScores
        }
        store.save(prefs: prefs, scores: &scores)
        saveCount += 1
        frontEnd?.highScores = scores
    }

    // MARK: Display fade (`CGDisplayFade`, full-screen launch only)

    /// The Mac shields every screen with black and animates it; here the window's canvas is darkened over the same
    /// duration on the driver's clock (the front end holds the duration in ticks, as the synchronous original did).
    private func displayFade(toBlack: Bool, seconds: Double) {
        displayFades.append((toBlack, seconds))
        let now = host.nanoseconds
        let current = fadeLevel()
        fade = (current, toBlack ? 255 : 0, now, UInt64(max(0, seconds) * 1e9))
        present()
    }

    private func fadeLevel() -> Int {
        guard let f = fade else { return 0 }
        let now = host.nanoseconds
        let elapsed = now >= f.start ? now - f.start : 0
        if f.duration == 0 || elapsed >= f.duration {
            if f.to == 0 { fade = nil }                                 // back from black: the shield goes
            else { fade = (f.to, f.to, f.start, 0) }
            return f.to
        }
        return f.from + (f.to - f.from) * Int(elapsed) / Int(f.duration)
    }

    // MARK: Dialogs

    private func showPendingDialogs() {
        while !pendingDialogs.isEmpty {
            let request = pendingDialogs.removeFirst()
            if request == .closeDialog {
                dialogs.close()
            } else {
                showDialog(request, fromPause: false)
            }
        }
    }

    private func showDialog(_ request: ShellRequest, fromPause: Bool) {
        switch request {
        case .highScoreNameDialog, .modalDialog(id: 3000), .modalDialog(id: 3001):
            showCursor()
            setCursor(.arrow)
        default:
            break
        }
        dialogs.present(request, prefs: currentPrefs) { [unowned self] answer in
            answerArrived(answer, fromPause: fromPause)
        }
    }

    private func answerArrived(_ answer: WinDialogAnswer, fromPause: Bool) {
        if case let .prefs(p) = answer {
            prefsDialogClosed(p)
            if !fromPause {
                pendingAnswers.append { [unowned self] in
                    let out = $0.prefsDialogDone(prefs: p)
                    audio.updateMusicVolume()                           // `_PrefsButton`: `_UpdateMusicVolume`
                    return out
                }
            }
        } else {
            pendingAnswers.append { answer.deliver(to: $0) }
        }
        if handleDepth == 0 { drainAnswers() }
    }

    /// The tail of `_PrefsDialog` after Save / Cancel.
    private func prefsDialogClosed(_ p: BTXPrefs) {
        if p.fullScreen != isFullScreen { _ = setFullScreen(p.fullScreen) }
        prefs = p
        frontEnd?.prefsChanged(p)
        applyPrefsToAudio()
        savePrefs()
        setCursor(.hand)
    }

    /// Preferences… (Ctrl+,): at the menu screen the front end opens DLOG 190; while paused the pause loop does.
    public func preferencesChosen() {
        guard let frontEnd, !dialogs.isShowing else { return }
        if let session, session.phase == .paused {
            showDialog(.prefsDialog, fromPause: true)
        } else {
            frontEnd.requestPreferences()
        }
    }

    private func modalStateChanged() {
        dialogUp = dialogs.isShowing
        if dialogs.isModal {
            guard suspendedAt == nil else { return }
            suspendedAt = hostTicks()
        } else {
            guard let t = suspendedAt else { return }
            clockOffset &+= hostTicks() &- t
            suspendedAt = nil
        }
        selectClock()
    }

    // MARK: Menu hooks (W5)

    /// The prefs every reader sees now: the running game's or the front end's.
    public var currentPrefs: BTXPrefs { frontEnd?.prefs ?? prefs }

    /// A menu command changed the prefs: the front end, the game and the sound take them at once, then
    /// `_SaveGamePrefs`.
    public func menuChangedPrefs(_ newPrefs: BTXPrefs, updateMusicVolume: Bool = false) {
        prefs = newPrefs
        frontEnd?.prefsChanged(newPrefs)
        applyPrefsToAudio()
        if updateMusicVolume { audio.updateMusicVolume() }
        savePrefs()
    }

    /// Full screen is not built in W4 (HectorSDL has no full-screen call yet): the window stays windowed and the
    /// switch reports failure, so a menu toggle flips the pref back exactly as the Mac does when no screen exists.
    public private(set) var isFullScreen = false

    public func setFullScreen(_ on: Bool) -> Bool {
        guard isFullScreen == on else { return true }
        return false
    }

    // MARK: Cursor

    private func setCursor(_ c: WinCursor) {
        cursor = c
        host.setCursor(c)
    }

    /// `.hideCursor`: during the level-start wipe the plain hide; once frames run, the capture too. Idempotent.
    private func hideCursor() {
        if let session, session.phase != .wipe, !mouseCaptured {
            host.setMouseCaptured(true)
            mouseCaptured = true
        }
        if !cursorHidden {
            host.setCursorVisible(false)
            cursorHidden = true
        }
    }

    private func showCursor() {
        if mouseCaptured {
            host.setMouseCaptured(false)
            mouseCaptured = false
        }
        if cursorHidden {
            host.setCursorVisible(true)
            cursorHidden = false
        }
    }

    // MARK: Input

    /// One host event (the Mac's ShellInputHandler, NSApplication delegate and menu key equivalents).
    public func handleEvent(_ event: WinEvent) {
        switch event {
        case let .keyDown(code, chars, mods, isRepeat):
            // Ctrl+Q = the Quit menu item's ⌘Q: the menu eats it (the view never sees it); inert under a dialog.
            if code == 0x0C && mods.contains(.command) {
                if !dialogs.isShowing && !isRepeat { quitChosen() }
                return
            }
            keys.keyDown(code)
            // Modifier keys arrive on the Mac as flagsChanged, never as keyDown.
            guard !WinKeyState.modifierKeyCodes.contains(code), let frontEnd else { return }
            handle(frontEnd.key(code, chars: chars, modifiers: Self.keyModifiers(mods), isRepeat: isRepeat),
                   now: ticksNow())
        case let .keyUp(code, _):
            keys.keyUp(code)
        case let .mouseMoved(x, y):
            mouse = (x, y)
        case let .mouseDown(x, y):
            mouse = (x, y)
            mouseButton = true
            // The menu strip is W5's; the game view sees only clicks on the game screen.
            mouseDownInGame = y >= WinCanvas.menuStripHeight
            guard mouseDownInGame, let frontEnd else { return }
            handle(frontEnd.mouseDown(h: x, v: y - WinCanvas.menuStripHeight,
                                      modifiers: Self.keyModifiers(host.modifiers)), now: ticksNow())
        case let .mouseUp(x, y):
            mouse = (x, y)
            mouseButton = false
            guard mouseDownInGame, let frontEnd else { return }
            mouseDownInGame = false
            handle(frontEnd.mouseUp(h: x, v: y - WinCanvas.menuStripHeight,
                                    modifiers: Self.keyModifiers(host.modifiers)), now: ticksNow())
        case .quit:
            quitChosen()
        case .focusLost:
            keys.releaseAll()
            guard let frontEnd else { return }
            handle(frontEnd.appDeactivated(), now: ticksNow())
        case .focusGained:
            guard let frontEnd else { return }
            handle(frontEnd.appActivated(keys: heldKeys()), now: ticksNow())
        }
    }

    /// `EventRecord.modifiers` as the front end reads them.
    public static func keyModifiers(_ m: WinModifiers) -> KeyModifiers {
        KeyModifiers(command: m.contains(.command), shift: m.contains(.shift), option: m.contains(.option),
                     control: m.contains(.control), capsLock: m.contains(.capsLock))
    }
}

private extension [DrawOp] {
    /// The last `.wipe` / `.wipeOut` op, if any.
    var lastWipe: (out: Bool, step: Int)? {
        for op in reversed() {
            if case let .wipe(step) = op { return (false, step) }
            if case let .wipeOut(step) = op { return (true, step) }
        }
        return nil
    }
}
