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
///
/// The Mac's chrome is drawn in-window (W4.5, D15.3): the menu bar (`MenuBar` / `MenuTracker` / `MenuBarView`, W5) in
/// the 20 px strip above the game screen, the dialogs (`DialogSystem`, W6) over it, and the About panel. Input goes
/// to the open menu first, then the menu bar's Ctrl shortcuts, then a dialog (app-modal) or the About panel, then the
/// game. In full screen the strip is not shown (as the Mac's menu bar hides) and the canvas is the game screen.
public final class WinGameDriver: DialogSystemDelegate {
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
    private let text: BitmapFontRasterizer
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

    // The in-window menu bar (W5): `BTXMenus`' state and the press-drag-release tracking.
    public private(set) var menuBar = MenuBar()
    public private(set) var tracker = MenuTracker()
    private let menuView: MenuBarView
    /// The closed bar's strip (rows 0 ..< 20), drawn once per bar state.
    private var stripCache: (bar: MenuBar, pixels: ArraySlice<UInt32>)?
    /// 'pref' and 'Full' enabled — the session's `.enableMenus`.
    public var playMenusEnabled: Bool { menuBar.playMenusEnabled }
    /// `DisableMenuCommand(0, 'abou')` in effect — the session's `.disableAbout`.
    public var aboutDisabled: Bool { menuBar.aboutDisabled }
    /// A dialog is up: every menu item is disabled (Carbon `ModalDialog` is app-modal).
    public var dialogUp: Bool { menuBar.dialogUp }
    /// Bubble Trouble X ▸ About's panel while it is open.
    public private(set) var about: WinAboutPanel?

    /// The dialogs' 1/60 s tick (flash, caret, the prefs' null events) — runs while one is on screen, whatever the
    /// game clocks do.
    private var dialogTimer = WinTimer(intervalNanoseconds: WinClock.nanosPerSecond, per: 60)
    /// Layout-aware text input is on at the host.
    public private(set) var textInputOn = false
    /// What the chrome looked like at the last present (a change re-presents).
    private var lastChrome: Chrome?

    private var quitWithoutSaving = false
    private var saveOnQuit = false
    private var frontEndQuit = false
    /// The window's close box (the quit Apple event) is waiting on the game's own quit path: a second close
    /// terminates at once (the Mac's `replyPending` → `.terminateNow`).
    private var closeRequestPending = false
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
    /// Where the last mouse-down went (its mouse-up goes there too).
    private enum MouseTarget { case none, game, dialog, about }
    private var mouseTarget = MouseTarget.none

    /// Called after every frame fire with the running session (tests trace the demo).
    public var frameObserver: ((GameSession) -> Void)?
    /// Called after every present.
    public var presentObserver: ((WinFrame) -> Void)?

    /// Loads the prefs and builds the sound and the compositor (the first half of the Mac's
    /// `applicationDidFinishLaunching`); `start()` opens the front end.
    /// `dialogs` defaults to the real in-window `DialogSystem`; pass `WinAutoDialogs` for runs that must not stop at a
    /// dialog.
    public init(assets: WinGameAssets, host: any WinHost, audioOutput: any WinAudioOutput,
                prefsBacking: any BTXPrefsBacking, dialogs: (any WinDialogs)? = nil, options: Options) throws {
        self.host = host
        self.data = assets.data
        self.art = assets.art
        self.dialogs = dialogs ?? DialogSystem(data: assets.data, art: assets.art,
                                               renderer: DialogRenderer(rasterizer: assets.text))
        self.options = options
        text = assets.text
        menuView = MenuBarView(text: assets.text)
        store = BTXPrefsStore(backing: prefsBacking, legacyFileURL: nil,
                              factoryScores: try HighScoreTable.factory(from: assets.data))
        (prefs, scores) = store.load()
        compositor = Compositor(art: assets.art, text: assets.text)
        audio = WinAudio(output: audioOutput, sounds: assets.sounds, data: assets.data, log: options.log)
        applyPrefsToAudio()
    }

    /// The Mac's `applicationDidFinishLaunching` tail: `_LoadMenuBar` + `_ResetOptionsMenu`, the window shown, full
    /// screen when the prefs say so (`_InitMac` → `_PrepareMonitor`), then `_Interface`: the front end and the
    /// splash's first output.
    public func start() {
        dialogs.delegate = self
        menuBar.resetOptionsMenu(prefs)
        present()
        if prefs.fullScreen { _ = setFullScreen(true) }
        frontEnd = FrontEnd(data: data, prefs: prefs, highScores: scores, registeredName: options.registeredName,
                            today: options.today)
        present()
        tickFired()                                                     // the splash's first output
    }

    // MARK: The main loop

    /// One pass of the host's loop: the queued events (each typing key paired with its text), the dialogs' tick if
    /// one is due, then the running clock's fire if one is due (at most one); then the chrome is re-presented if it
    /// changed and the host's text input follows the dialogs.
    public func step() {
        guard !finished else { return }
        for (event, typed) in Self.pairTypedText(host.pollEvents()) {
            handleEvent(event, typed: typed)
            if finished { return }
        }
        let now = host.nanoseconds
        if dialogTimer.poll(now: now) {
            dialogs.tick(heldKeys: keys.held)
            if finished { return }
        }
        switch clock {
        case .frame: if frameTimer.poll(now: now) { frameFired() }
        case .fastFrame: if fastFrameTimer.poll(now: now) { frameFired() }
        case .tick: if tickTimer.poll(now: now) { tickFired() }
        case .none: break
        }
        guard !finished else { return }
        syncChrome()
    }

    /// When the running clock (or the dialogs' tick) fires next (nil: none runs) — the host may sleep until then.
    public var nextDeadline: UInt64? {
        let game: UInt64? = switch clock {
        case .frame: frameTimer.nextFire
        case .fastFrame: fastFrameTimer.nextFire
        case .tick: tickTimer.nextFire
        case .none: nil
        }
        guard let d = dialogTimer.nextFire else { return game }
        return game.map { min($0, d) } ?? d
    }

    /// Pairs each key-down with the layout-aware text that follows it in the same poll (before the next key-down):
    /// SDL reports the key, then what it typed. A `.textInput` with no key-down before it (an IME commit, a dead key's
    /// composition) stays an event of its own.
    public static func pairTypedText(_ events: [WinEvent]) -> [(WinEvent, String?)] {
        var out: [(WinEvent, String?)] = []
        var used = Set<Int>()
        for (i, e) in events.enumerated() where !used.contains(i) {
            guard case .keyDown = e else { out.append((e, nil)); continue }
            var typed: String?
            var j = i + 1
            while j < events.count {
                if case .keyDown = events[j] { break }
                if case let .textInput(t) = events[j], !used.contains(j) {
                    typed = t
                    used.insert(j)
                    break
                }
                j += 1
            }
            out.append((e, typed))
        }
        return out
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
        tracker.close()
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
        quitPending = false
        closeRequestPending = false
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
            case let .enableMenus(on): menuBar.playMenusEnabled = on
            case .haltAllSound: audio.haltEffects()
            case .quitNow: quitNow = true
            case .savePrefs: savePrefs()
            case let .setCursor(id): setCursor(id == 200 ? .hand : .arrow)
            case .restoreMousePosition: host.restoreMousePosition()
            case let .disableAbout(off): menuBar.aboutDisabled = off
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

    /// The composed canvas (and the fade) to the host.
    private func present() {
        let frame = currentFrame
        lastChrome = chrome
        host.present(frame)
        presentObserver?(frame)
    }

    /// The frame as it would be presented now (dumps).
    public var currentFrame: WinFrame { WinFrame(canvas: composeCanvas(), fade: fadeLevel()) }

    /// Windowed: the menu bar's strip, the game screen under it, the dialogs and the About panel over the screen,
    /// the open menu over everything. Full screen: the game screen, the dialogs and the About panel.
    private func composeCanvas() -> RGBAImage {
        let screen = compositor.screen
        if isFullScreen {
            var img = screen
            dialogs.draw(into: &img, canvasX: 0, canvasY: 0)
            about?.draw(into: &img, canvasX: 0, canvasY: 0)
            return img
        }
        let strip = WinCanvas.menuStripHeight * WinCanvas.width
        var img = RGBAImage(width: WinCanvas.width, height: WinCanvas.height)
        img.pixels.replaceSubrange(strip..<img.pixels.count, with: screen.pixels.prefix(img.pixels.count - strip))
        dialogs.draw(into: &img, canvasX: 0, canvasY: WinCanvas.menuStripHeight)
        about?.draw(into: &img, canvasX: 0, canvasY: WinCanvas.menuStripHeight)
        if tracker.isOpen {
            menuView.draw(menuBar, tracker: tracker, into: &img)
        } else {
            if stripCache?.bar != menuBar {
                var bar = RGBAImage(width: WinCanvas.width, height: WinCanvas.menuStripHeight)
                menuView.draw(menuBar, tracker: MenuTracker(), into: &bar)
                stripCache = (menuBar, bar.pixels[...])
            }
            img.pixels.replaceSubrange(0..<strip, with: stripCache!.pixels)
        }
        return img
    }

    /// Everything besides the game screen that changes what is presented.
    private struct Chrome: Equatable {
        var bar: MenuBar
        var tracker: MenuTracker
        var dialogs: Int
        var about: Bool
        var fullScreen: Bool
    }

    private var chrome: Chrome {
        Chrome(bar: menuBar, tracker: tracker, dialogs: dialogs.drawKey, about: about != nil, fullScreen: isFullScreen)
    }

    /// After every step: the menu bar's dialog state, the host's text input, and a present when the chrome changed.
    private func syncChrome() {
        menuBar.dialogUp = dialogs.isShowing
        let wantText = dialogs.isShowing && dialogs.wantsTextInput
        if wantText != textInputOn {
            textInputOn = wantText
            host.setTextInput(wantText)
        }
        if chrome != lastChrome { present() }
    }

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

    private func answerArrived(_ answer: DialogSystem.Answer, fromPause: Bool) {
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
            pendingAnswers.append { DialogSystem.deliver(answer, to: $0) }
        }
        if handleDepth == 0 { drainAnswers() }
    }

    /// The tail of `_PrefsDialog` after Save (the edited prefs) or Cancel (the prefs at open): `_GoFullScreenMode` /
    /// `_GoWindowMode` when bool 0x37 no longer matches, `_SaveGamePrefs`, `_InitControls`, `_UpdateSoundVol`,
    /// `_UpdateMusicStatus`, then `_ResetOptionsMenu` and `_SetMyCCursor(200)`.
    private func prefsDialogClosed(_ p: BTXPrefs) {
        if p.fullScreen != isFullScreen { _ = setFullScreen(p.fullScreen) }
        prefs = p
        frontEnd?.prefsChanged(p)
        applyPrefsToAudio()
        savePrefs()
        menuBar.resetOptionsMenu(p)
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

    // MARK: DialogSystemDelegate

    public func dialogPlaySound(_ cue: SoundCue, volumeOverride: Int?) {
        audio.play(cue, sfxLevel: volumeOverride)
    }

    public func dialogLivePrefs(_ p: BTXPrefs, updateMusic: Bool) {
        prefs = p
        applyPrefsToAudio()
        if updateMusic { audio.updateMusicVolume() }
    }

    public func dialogBeep() {
        beeps += 1
        host.beep()
    }

    public func dialogModalStateChanged() { modalStateChanged() }

    /// A dialog went up or away: the menu bar follows (app-modal), the dialogs' tick runs while one is shown, and the
    /// clocks stop while one waits for the user and resume where they stopped when none does (BTXController's
    /// `modalStateChanged`: "the App's clocks stop").
    private func modalStateChanged() {
        menuBar.dialogUp = dialogs.isShowing
        if dialogs.isShowing {
            if !dialogTimer.isRunning { dialogTimer.start(now: host.nanoseconds) }
        } else {
            dialogTimer.invalidate()
        }
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

    /// The window is in full screen (the menu strip hidden, the game screen integer-fit on black).
    public private(set) var isFullScreen = false

    /// `_GoFullScreenMode` / `_GoWindowMode` (BTXController.setFullScreen: the main screen filled, integer-crisp, no
    /// display-mode switch), then the window redrawn and `gDidToggleFullscreen` (the menu redraws 10 ticks later).
    /// False when the switch did not happen (the host refused).
    public func setFullScreen(_ on: Bool) -> Bool {
        isFullScreen = host.setFullScreen(on)
        guard isFullScreen == on else { return false }
        if on { tracker.close() }
        present()
        frontEnd?.didToggleFullscreen()
        return true
    }

    // MARK: Menu commands (`BTXMenus` actions, `_HandleMenuChoice`)

    /// Carries out a menu command exactly as the Mac item's action does.
    public func perform(_ command: MenuCommand) {
        switch command {
        case .about:
            // `_SetMyCCursor(200)`, then the About panel (`orderFrontStandardAboutPanel`).
            setCursor(.hand)
            if about == nil { about = WinAboutPanel(text: text, icon: try? art.cicn(128)) }
        case .preferences:
            preferencesChosen()
        case .quit:
            quitChosen()
        case .fullScreen:
            var p = currentPrefs
            var bar = menuBar                                           // the switch re-presents (reads the bar)
            bar.fullScreenChosen(&p) { setFullScreen($0) }
            menuBar = bar
            menuChangedPrefs(p)
        case .soundEffects, .music, .keySet:
            var p = currentPrefs
            menuBar.apply(command, to: &p)
            menuChangedPrefs(p, updateMusicVolume: command == .music)
        case .minimize:
            host.minimize()
        case .zoom:
            host.zoom()
        case .undo, .redo, .cut, .copy, .paste, .delete, .selectAll:
            break                                                       // no responder takes them (always disabled)
        case .minimizeAll, .bringAllToFront, .arrangeInFront:
            break                                                       // the only window: nothing happens
        }
    }

    /// The About panel's close button (or Esc, or a click elsewhere).
    public func closeAbout() { about = nil }

    private static func menuModifiers(_ m: WinModifiers) -> MenuModifiers {
        var out: MenuModifiers = []
        if m.contains(.command) { out.insert(.command) }
        if m.contains(.shift) { out.insert(.shift) }
        if m.contains(.option) { out.insert(.option) }
        if m.contains(.control) { out.insert(.control) }
        return out
    }

    private var menuGeometry: MenuGeometry {
        menuView.geometry(for: menuBar, width: WinCanvas.width, height: WinCanvas.height)
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

    /// One host event (the Mac's ShellInputHandler, NSApplication delegate and menu key equivalents); `typed` is the
    /// layout-aware text a key-down typed (`pairTypedText`), nil when none came.
    public func handleEvent(_ event: WinEvent, typed: String? = nil) {
        switch event {
        case let .keyDown(code, chars, mods, isRepeat):
            keyDown(code, chars: chars, modifiers: mods, isRepeat: isRepeat, typed: typed)
        case let .keyUp(code, mods):
            keys.keyUp(code)
            if code == 0x3A || code == 0x3D {
                tracker.modifiersChanged(Self.menuModifiers(mods.subtracting(.option)), bar: menuBar,
                                         geometry: menuGeometry)
            }
        case let .textInput(text):
            // Text with no key-down before it (an IME commit, a dead key's composition): typed into the dialog.
            guard dialogs.isShowing, !tracker.isOpen else { return }
            for ch in text {
                dialogs.keyDown(DialogKeyEvent(keyCode: Self.noKeyCode, characters: String(ch)))
            }
        case let .mouseMoved(x, y):
            mouse = (x, y)
            if !isFullScreen {
                tracker.mouseMoved(x: x, y: y, modifiers: Self.menuModifiers(host.modifiers), bar: menuBar,
                                   geometry: menuGeometry)
            }
            if dialogs.isShowing { dialogs.mouseMoved(x: x, y: y - WinCanvas.menuStripHeight) }
        case let .mouseDown(x, y):
            mouseDown(x, y)
        case let .mouseUp(x, y):
            mouseUp(x, y)
        case .quit:
            // The quit Apple event (`applicationShouldTerminate`): a second one while the first waits on the game's
            // own quit path terminates at once; otherwise `quitChosen`'s routes.
            if closeRequestPending { terminate(); return }
            quitChosen()
            if quitPending && !finished { closeRequestPending = true }
        case .focusLost:
            keys.releaseAll()
            guard let frontEnd else { return }
            handle(frontEnd.appDeactivated(), now: ticksNow())
        case .focusGained:
            guard let frontEnd else { return }
            handle(frontEnd.appActivated(keys: heldKeys()), now: ticksNow())
        }
    }

    /// The key code `DialogKeyEvent` gets for text that came without a key (none of Carbon's: the text decides).
    static let noKeyCode: UInt16 = 0xFFFF

    private func keyDown(_ code: UInt16, chars: String, modifiers mods: WinModifiers, isRepeat: Bool, typed: String?) {
        // Modifier keys arrive on the Mac as flagsChanged, never as keyDown: GetKeys sees them; Alt swaps the Window
        // menu's alternates; nothing else does.
        if WinKeyState.modifierKeyCodes.contains(code) {
            keys.keyDown(code)
            if code == 0x3A || code == 0x3D {
                tracker.modifiersChanged(Self.menuModifiers(mods.union(.option)), bar: menuBar, geometry: menuGeometry)
            }
            return
        }
        // AltGr is Ctrl+Alt on Windows: a key that typed text with both held is typing, not a Ctrl shortcut.
        let altGr = typed != nil && mods.contains(.command) && mods.contains(.option)
        // An open menu takes every key (Esc closes it).
        if tracker.isOpen {
            _ = tracker.keyDown(keyCode: code)
            return
        }
        // The menu bar's key equivalents, by physical key (D18.5): the menu eats the key (the view never sees it).
        if mods.contains(.command), !altGr,
           let command = menuBar.command(forKeyCode: code, modifiers: Self.menuModifiers(mods)) {
            if !isRepeat { perform(command) }
            return
        }
        keys.keyDown(code)
        if dialogs.isShowing {
            let text = typed ?? (DialogKeyEvent.typesText(keyCode: code) ? chars : "")
            dialogs.keyDown(DialogKeyEvent(keyCode: code, characters: text,
                                           command: mods.contains(.command) && !altGr, shift: mods.contains(.shift),
                                           option: mods.contains(.option) && !altGr,
                                           control: mods.contains(.control)))
            return
        }
        if about != nil {                                               // the About panel is the key window
            if code == 0x35 { closeAbout() }
            return
        }
        guard let frontEnd else { return }
        var m = mods
        if altGr { m.subtract([.command, .option]) }
        handle(frontEnd.key(code, chars: chars, modifiers: Self.keyModifiers(m), isRepeat: isRepeat),
               now: ticksNow())
    }

    private func mouseDown(_ x: Int, _ y: Int) {
        mouse = (x, y)
        mouseButton = true
        mouseTarget = .none
        // The menu bar first: a press on the strip, or anywhere while a menu is open, is the bar's.
        if !isFullScreen, tracker.mouseDown(x: x, y: y, modifiers: Self.menuModifiers(host.modifiers), bar: menuBar,
                                            geometry: menuGeometry) {
            return
        }
        let cy = y - WinCanvas.menuStripHeight
        if dialogs.isShowing {                                          // app-modal: the dialog takes it (or beeps)
            mouseTarget = .dialog
            dialogs.mouseDown(x: x, y: cy)
            return
        }
        if let a = about {
            if a.contains(x: x, y: cy) {
                mouseTarget = .about
                if a.isOnCloseButton(x: x, y: cy) { closeAbout() }
                return
            }
            closeAbout()                                                // the game window comes forward
        }
        guard y >= WinCanvas.menuStripHeight, let frontEnd else { return }
        mouseTarget = .game
        handle(frontEnd.mouseDown(h: x, v: cy, modifiers: Self.keyModifiers(host.modifiers)), now: ticksNow())
    }

    private func mouseUp(_ x: Int, _ y: Int) {
        mouse = (x, y)
        mouseButton = false
        if !isFullScreen {
            let r = tracker.release(x: x, y: y, modifiers: Self.menuModifiers(host.modifiers), bar: menuBar,
                                    geometry: menuGeometry)
            if r.consumed {
                mouseTarget = .none
                if let c = r.command { perform(c) }
                return
            }
        }
        let target = mouseTarget
        mouseTarget = .none
        let cy = y - WinCanvas.menuStripHeight
        if dialogs.isShowing {
            dialogs.mouseUp(x: x, y: cy)
            return
        }
        guard target == .game, let frontEnd else { return }
        handle(frontEnd.mouseUp(h: x, v: cy, modifiers: Self.keyModifiers(host.modifiers)), now: ticksNow())
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
