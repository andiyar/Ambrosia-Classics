import AppKit
import BubbleTroubleCore
import BubbleTroubleRender
import HectorShell

/// The app delegate and shell owner (plan S3, tasks A1 + A2): loads the original data, opens the 640×480 game window,
/// owns the clocks (Invariant 4) and drives `FrontEnd` — splash, main menu, attract demos, games, the C7 screens —
/// → `Compositor` → `ShellView.present`, plays the cues through `BTXAudio` and carries out the `ShellRequest`s.
///
/// Clocks: the 1/60 s TickCount timer drives `FrontEnd.tick` (splash, menu, wipes, fades, every blocking phase);
/// while a game or demo runs frames (`FrontEnd.wantsFrameTimer`) the 0.033 s Carbon frame timer drives
/// `FrontEnd.frame` instead — or, with the frame-limit cheat (`GameSession.limitFrames` false), a 0.001 s timer, the
/// original's `ReceiveNextEvent` spin (00019122). Exactly one runs at a time.
@MainActor final class BTXController: NSObject, NSApplicationDelegate, ShellInputHandler {
    private var data: BTXGameData!
    private var art: ArtBank!
    private var sounds: SoundBankPCM!
    private var compositor: Compositor!
    private var audio: BTXAudio!
    private var store: BTXPrefsStore!
    /// The prefs / scores loaded at launch, until `frontEnd` holds them.
    private var prefs = BTXPrefs.defaults
    private var scores = HighScoreTable.empty
    private var shell: ShellWindowController!
    /// The window's image, refilled from `compositor.screen` on every present.
    private let bitmap = ShellBitmap(width: Compositor.width, height: Compositor.height)

    /// Everything from launch to quit (C6/C7); it owns the running `GameSession`.
    private var frontEnd: FrontEnd!
    /// The running game or demo.
    private var session: GameSession? { frontEnd?.session }

    /// Invariant 4: the 0.033 s Carbon frame timer (`_PlayGame` 00018326…00018355) while frames run (0.001 s with
    /// the frame-limit cheat), else the TickCount (1/60 s) timer. Exactly one runs at a time; a `Timer` drops the
    /// fires it missed, as the original's `gTimerFired` flag did.
    private enum Clock { case none, frame, fastFrame, tick }
    private var clock = Clock.none
    private var frameTimer: ShellIdleTimer!
    private var fastFrameTimer: ShellIdleTimer!
    private var tickTimer: ShellIdleTimer!

    /// The `_WipeScreen` / `_WipeScreenOut` being paced (`.wipe` / `.wipeOut` op seen): which, its step, the band
    /// advance done, the tick it was done on.
    private var wipe: (out: Bool, step: Int, row: Int, lastTick: UInt32)?

    /// The menu bar (A3).
    private(set) var menus: BTXMenus!
    /// `_CleanUp` from inside a game (`.quitNow`, a data failure): terminate without saving.
    private var quitWithoutSaving = false
    /// Quit while paused: `_PauseGame` case 0x17 (the quit Apple event — Carbon's Quit menu item and ⌘Q arrive as
    /// it) runs `_SaveGamePrefs` → `_StopMusic` → `_CleanUp`, so this quit saves although a game is running.
    private var saveOnQuit = false
    /// The front end's `gFinished` path ended (`.quit`): terminate now, prefs saved.
    private var frontEndQuit = false
    /// Quit was chosen while a game runs outside its pause: ⌘ + key 0x0C is injected into every frame's keys until
    /// the game's own ⌘Q check (`_PlayGame` 00018ea4) fades the music and quits. A menu key equivalent eats the
    /// keyDown, so the view never sees it.
    private var quitPending = false
    /// `_HideMyCursor` / `_ShowMyCursor` (`gCursorVisible`: idempotent; NSCursor.hide counts).
    private var cursorHidden = false
    /// The play-mode mouse capture (warped to centre, `CGAssociateMouseAndMouseCursorPosition(0)`).
    private var mouseCaptured = false
    /// `gSavedMousePosition` (global, top-left origin): `_GetMouse` right before each centre warp.
    private var savedMouse: CGPoint?
    /// The cursor `_SetMyCCursor` / `_InitCursor` / `_WatchCursor` last set (see `setCursor`).
    private var cursor = NSCursor.arrow
    /// `crsr 200`, decoded from the original (`_LoadHandCursor @ 00025af8`); `NSCursor.pointingHand` if it fails.
    private var handCursor = NSCursor.pointingHand
    /// `CGDisplayFade` stand-in for the full-screen splash (`.displayFade`).
    private let displayFade = BTXDisplayFade()
    /// Dialog answers waiting to be delivered once the output that asked is fully applied (A4 hook stubs).
    private var pendingAnswers: [(FrontEnd) -> SessionOutput] = []

    // MARK: Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        let assets = BTXAssets()
        #if DEBUG
        if !assets.missingFiles().isEmpty {
            let alert = NSAlert()
            alert.messageText = "Bubble Trouble X's original data files are missing from this app. "
                + "Run tools/stage-btx.sh."
            alert.runModal()
            NSApp.terminate(nil)
            return
        }
        #endif
        do {
            guard let dir = assets.resourcesDirectory else { throw BTXDataError.missingFile("Contents/Resources") }
            let data = try BTXGameData(resourcesDirectory: dir)
            let art = ArtBank(data: data)
            try art.prewarm()
            let sounds = SoundBankPCM(data: data)
            try sounds.prewarm()
            let store = BTXPrefsStore(defaults: .standard, legacyFileURL: BTXPrefsStore.legacyFileURL,
                                      factoryScores: try HighScoreTable.factory(from: data))
            (prefs, scores) = store.load()
            self.data = data
            self.art = art
            self.sounds = sounds
            self.store = store
        } catch {
            fail("cannot load the original data: \(error)")
            return
        }
        compositor = Compositor(art: art, text: CoreTextRasterizer())
        // K3's `ShellMixer` is not on HectorKit main yet: a silent output stands in (one-file swap later).
        audio = BTXAudio(output: SilentAudioOutput(), sounds: sounds, data: data)
        applyPrefsToAudio()
        handCursor = Self.makeHandCursor(data) ?? .pointingHand

        menus = BTXMenus(controller: self, assets: assets)
        NSApp.mainMenu = menus.bar                                      // `_LoadMenuBar`
        menus.installed()
        menus.resetOptionsMenu(prefs)                                   // `_InitMac` → `_ResetOptionsMenu`

        // `_CreateGameWindow @ 00010144`: `CreateNewWindow(6, 0x2800000)` 640×480 → titled only (R5), titled
        // "Bubble Trouble X", `RepositionWindow(…, kWindowCenterOnMainScreen)`.
        shell = ShellWindowController(title: "Bubble Trouble X", logicalWidth: Compositor.width,
                                      logicalHeight: Compositor.height, styleMask: [.titled])
        shell.view.inputHandler = self
        centreOnMainScreen(shell.windowedWindow)
        present()
        shell.windowedWindow.makeKeyAndOrderFront(nil)
        NSApp.activate()
        if prefs.fullScreen { _ = setFullScreen(true) }                 // `_InitMac` → `_PrepareMonitor`

        // `_InitMac` → `_Interface`: the splash, the loading screen, then the main menu (C6). Info message 2 is
        // "Registered To: <name>" — the macOS account's full name (Q15).
        frontEnd = FrontEnd(data: data, prefs: prefs, highScores: scores, registeredName: NSFullUserName())
        frameTimer = ShellIdleTimer(interval: 0.033) { [weak self] in self?.frameFired() }
        fastFrameTimer = ShellIdleTimer(interval: 0.001) { [weak self] in self?.frameFired() }
        tickTimer = ShellIdleTimer(interval: 1.0 / 60.0) { [weak self] in self?.tickFired() }
        tickFired()                                                     // the splash's first output
    }

    /// `kWindowCenterOnMainScreen`: centred in the main screen's area below the menu bar.
    private func centreOnMainScreen(_ window: NSWindow) {
        guard let screen = NSScreen.screens.first else { window.center(); return }
        let area = screen.visibleFrame, size = window.frame.size
        window.setFrameOrigin(NSPoint(x: (area.midX - size.width / 2).rounded(),
                                      y: (area.midY - size.height / 2).rounded()))
    }

    /// Quit (menu ⌘Q, or the quit Apple event via `applicationShouldTerminate`):
    /// - no game, the main menu idle: `_HandleMenuChoice` 0x81/1 — `_SaveGamePrefs`, then `_StopMusic`'s blocking
    ///   fade of the title music, then the front end's `.quit` terminates (saving again, as `_main` does);
    /// - no game, anything else (splash, a wipe, a screen): terminate now, prefs saved;
    /// - paused: `_PauseGame` case 0x17 (DC ~15381): `_AEProcessAppleEvent` → `_SaveGamePrefs` → `_StopMusic` →
    ///   `_CleanUp` — terminate now WITH the save (the music voice is paused; ⌘-keys never reach the cheat buffer,
    ///   `_PauseGame` case 3 tests cmdKey);
    /// - any other game phase: ⌘ + 0x0C is injected into the frames' keys, so `_PlayGame`'s check (00018ea4) runs
    ///   its `_StopMusic` fade and `.quitNow` follows; blocking phases (wipe, fade, count-down) poll no keys, so the
    ///   injection waits for frames to run again.
    @objc func quitChosen(_ sender: Any?) {
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

    /// The menu-screen quit with the title music's fade; false when the front end is not idle at the menu.
    private func quitThroughFrontEnd() -> Bool {
        guard let frontEnd, !frontEndQuit else { return false }
        if frontEnd.phase == .quit { return false }
        savePrefs()
        guard let out = frontEnd.quitFromMenuBar() else { return false }
        handle(out, now: ShellClock.ticks())
        return true
    }

    /// Quit now. When a terminate request (the quit Apple event) is waiting on the game's own quit path, it is
    /// answered yes instead.
    private func terminate() {
        frontEndQuit = true
        if insideShouldTerminate { return }                             // its own return value says "now"
        if replyPending {
            replyPending = false
            NSApp.reply(toApplicationShouldTerminate: true)
        } else {
            NSApp.terminate(nil)
        }
    }

    /// `applicationShouldTerminate` answered `.terminateLater`: the reply comes when the music fade has run.
    private var replyPending = false
    private var insideShouldTerminate = false

    /// A terminate that did not come from the game or the front end (the quit Apple event — `_QuitAppleEventHandler`
    /// sets `gFinished` and returns at once) goes through `quitChosen`'s routes and is answered once the original's
    /// quit path (the music fade) has run; the game's own `.quitNow`, the front end's `.quit` and the rest proceed.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if quitWithoutSaving || saveOnQuit || frontEndQuit || frontEnd == nil || replyPending { return .terminateNow }
        guard let session, session.isInGame else {
            insideShouldTerminate = true
            let fading = quitThroughFrontEnd()
            insideShouldTerminate = false
            guard fading, !frontEndQuit else { return .terminateNow }
            replyPending = true
            return .terminateLater
        }
        if session.phase == .paused {
            saveOnQuit = true
            return .terminateNow
        }
        quitPending = true
        replyPending = true
        return .terminateLater
    }

    /// A launch/start failure: logged; DEBUG also shows an alert (Invariant 6); then a clean quit without saving.
    private func fail(_ message: String) {
        NSLog("Bubble Trouble X: %@", message)
        #if DEBUG
        let alert = NSAlert()
        alert.messageText = "Bubble Trouble X: \(message)"
        alert.runModal()
        #endif
        quitWithoutSaving = true
        NSApp.terminate(nil)
    }

    // MARK: Clocks

    private func applyPrefsToAudio() {
        audio.sfxVolumePref = prefs.sfxVolume
        audio.musicVolumePref = prefs.musicVolume
        audio.titleMusicPref = prefs.titleMusic
    }

    /// The keyboard as `GetKeys` reads it: K1's key state, Caps Lock and modifiers re-polled once per fire.
    private func heldKeys() -> HeldKeys {
        let state = shell.view.pollKeyState()
        return HeldKeys(codes: state.held, capsLock: state.capsLock, command: state.modifiers.contains(.command))
    }

    /// `_GetMouse` in the 640×480 screen, plus `Button()`.
    private func mousePoint() -> MousePoint {
        let p = shell.view.logicalMouseLocation()
        return MousePoint(h: p.h, v: p.v, button: NSEvent.pressedMouseButtons & 1 != 0)
    }

    /// One frame fire: one simulation step, one present.
    private func frameFired() {
        guard let frontEnd else { return }
        var keys = heldKeys()
        if quitPending {                                                // ⌘Q chosen from the menu (see `quitChosen`)
            keys.codes.insert(0x0c)
            keys.command = true
        }
        let now = ShellClock.ticks()
        handle(frontEnd.frame(keys: keys, now: now), now: now)
    }

    /// One 1/60 s fire: the wipe advances when TickCount has moved on, then the front end ticks.
    private func tickFired() {
        guard let frontEnd else { return }
        let now = ShellClock.ticks()
        var dirty = false
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
        keepCursor()
        handle(frontEnd.tick(now: now, keys: heldKeys(), mouse: mousePoint()), now: now, alreadyDirty: dirty)
    }

    private static func wipeRows(_ w: (out: Bool, step: Int, row: Int, lastTick: UInt32)) -> Int {
        w.out ? Compositor.wipeOutSteps(w.step) : Compositor.wipeSteps(w.step)
    }

    private func applyWipeRow(_ w: (out: Bool, step: Int, row: Int, lastTick: UInt32)) {
        if w.out { compositor.applyWipeOut(row: w.row) } else { compositor.applyWipe(row: w.row) }
    }

    private func selectClock() {
        let want: Clock
        if frontEnd == nil || frontEnd.phase == .quit {
            want = .none
        } else if frontEnd.wantsFrameTimer {
            want = session?.limitFrames == false ? .fastFrame : .frame
        } else {
            want = .tick
        }
        guard want != clock else { return }
        frameTimer.invalidate()
        fastFrameTimer.invalidate()
        tickTimer.invalidate()
        switch want {
        case .frame: frameTimer.start()
        case .fastFrame: fastFrameTimer.start()
        case .tick: tickTimer.start()
        case .none: break
        }
        clock = want
    }

    // MARK: Output

    /// Carries out one `SessionOutput` produced at TickCount `now`: requests first (`ST_HaltSound` before the cues
    /// that follow it), music, effects; a wipe still in flight is finished before any new drawing (the original's
    /// wipes block), then the draw ops, present; then quit and the clock for the new phase.
    private func handle(_ out: SessionOutput, now: UInt32, alreadyDirty: Bool = false) {
        var quitNow = false, quit = false
        audio.gameRunning = session != nil                              // `gPlayGame` (`_StartMusic`'s volume rule)
        for request in out.requests {
            switch request {
            case .hideCursor: hideCursor()
            case .showCursor: showCursor()
            case let .enableMenus(on): menus.playMenusEnabled = on
            case .haltAllSound: audio.haltEffects()
            case .quitNow: quitNow = true
            case .savePrefs: savePrefs()
            case let .setCursor(id): setCursor(id == 200 ? handCursor : .arrow)
            case .restoreMousePosition:
                if let savedMouse { CGWarpMouseCursorPosition(savedMouse) }
            case let .disableAbout(off): menus.aboutDisabled = off
            case .beep: NSSound.beep()
            // `_WatchCursor`: the system watch (`GetCursor(4)`). AppKit has no public busy cursor: the arrow stays.
            case .watchCursor: setCursor(.arrow)
            case let .displayFade(toBlack, seconds): displayFade.fade(toBlack: toBlack, seconds: seconds)
            case .quit: quit = true
            case .highScoreNameDialog, .levelSelectDialog, .prefsDialog, .hiScoreEraseDialog, .modalDialog, .closeDialog:
                dialogRequested(request)
            }
        }
        for cue in out.music { audio.apply(cue) }
        for cue in out.sounds { audio.play(cue) }
        var dirty = alreadyDirty
        if !out.drawOps.isEmpty {
            if let w = wipe {                                           // the blocking wipe ends before drawing on
                for row in (w.row + 1)..<(Self.wipeRows(w) + 1) {
                    applyWipeRow((w.out, w.step, row, w.lastTick))
                }
                wipe = nil
            }
            compositor.apply(out.drawOps)
            dirty = true
            if let started = out.drawOps.lastWipe {                    // the op itself copied the first band pair
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
        while !pendingAnswers.isEmpty, let frontEnd {
            let answer = pendingAnswers.removeFirst()
            handle(answer(frontEnd), now: ShellClock.ticks())
        }
    }

    /// Copies the compositor's screen into the window bitmap (never holding the buffer across frames) and shows it.
    private func present() {
        let pixels = bitmap.pixels
        compositor.screen.pixels.withUnsafeBufferPointer { src in
            guard let base = src.baseAddress else { return }
            pixels.update(from: base, count: min(src.count, Compositor.width * Compositor.height))
        }
        shell.view.present(bitmap)
    }

    /// `_SaveGamePrefs` (`_LoadLevel`, menu toggles, quit): the prefs as the front end / running game hold them (short
    /// 0x3a raised) plus the high scores. The first-ever save swaps in the factory scores (C5) — written back.
    private func savePrefs() {
        guard let store else { return }
        if let frontEnd {
            prefs = frontEnd.prefs
            scores = frontEnd.highScores
        }
        store.save(prefs: prefs, scores: &scores)
        frontEnd?.highScores = scores
    }

    // MARK: - A4 dialog hooks (BTXDialogs / BTXPrefsWindow)

    /// A4 HOOK — every modal dialog the front end asks for lands here; the front end waits on the answer (its
    /// `.dialog` step) until one of `FrontEnd`'s answer methods is called through `dialogAnswered(_:)`:
    /// - `.levelSelectDialog(max:)` — DLOG 160 → `levelSelectDone(typed:)` (nil = Cancel); `.closeDialog` follows
    ///   the 30-tick hold after OK (and comes at once after Cancel): dispose the dialog then.
    /// - `.prefsDialog` — DLOG 190 → `prefsDialogDone(prefs:)`, then `audio.updateMusicVolume()` (`_PrefsButton`).
    /// - `.hiScoreEraseDialog` — DLOG 1001 → `hiScoreEraseDone(reset:)`.
    /// - `.modalDialog(id:)` — DLOG 290 / 291 (any key or click) and 3000 / 3001 (OK) → `dialogDone()`.
    /// - `.highScoreNameDialog(defaultName:)` — DLOG 1000 name entry (C7) → `highScoreNameEntered(_:)`; apply that
    ///   answer's output (snd 15 + any joke-name sound) before disposing the dialog, as the original did.
    /// Until A4 replaces the body, each is answered at once as its Cancel / dismiss would be (after this output
    /// is applied), so the front end never waits on a dialog nobody shows.
    private func dialogRequested(_ request: ShellRequest) {
        switch request {
        case .levelSelectDialog: pendingAnswers.append { $0.levelSelectDone(typed: nil) }
        case .prefsDialog: pendingAnswers.append { $0.prefsDialogDone(prefs: $0.prefs) }
        case .hiScoreEraseDialog: pendingAnswers.append { $0.hiScoreEraseDone(reset: false) }
        case .modalDialog: pendingAnswers.append { $0.dialogDone() }
        case let .highScoreNameDialog(name): pendingAnswers.append { $0.highScoreNameEntered(name) }   // OK at once
        case .closeDialog: break
        default: break
        }
    }

    /// A4 HOOK — a dialog's answer: `dialogAnswered { $0.levelSelectDone(typed: 5) }`. The output is applied now.
    func dialogAnswered(_ answer: (FrontEnd) -> SessionOutput) {
        guard let frontEnd else { return }
        handle(answer(frontEnd), now: ShellClock.ticks())
    }

    /// A4 HOOK — Preferences… (⌘,) at the menu screen: `_PrefsAppleEventHandler` sets `gDoPrefsNow`, which the
    /// menu loop turns into `.prefsDialog`. A4 wires it: `menus.preferencesHandler = { [unowned self] in
    /// preferencesChosen() }` (the item validates disabled while the handler is nil).
    func preferencesChosen() {
        frontEnd?.requestPreferences()
    }

    // MARK: Menu hooks (A3, `BTXMenus`)

    /// The prefs every reader sees now: the running game's (it raises short 0x3a) or the front end's.
    var currentPrefs: BTXPrefs { frontEnd?.prefs ?? prefs }

    /// A menu command changed the prefs (`_HandleMenuChoice`): the front end, the game and the sound take them at
    /// once, then `_SaveGamePrefs`. `updateMusicVolume`: the Music toggle's `_UpdateMusicVolume`.
    func menuChangedPrefs(_ newPrefs: BTXPrefs, updateMusicVolume: Bool = false) {
        prefs = newPrefs
        frontEnd?.prefsChanged(newPrefs)
        applyPrefsToAudio()
        if updateMusicVolume { audio.updateMusicVolume() }
        savePrefs()
    }

    /// `_GoFullScreenMode` / `_GoWindowMode` (D3: the main screen filled, integer-crisp, no display-mode switch),
    /// then the window redrawn and `gDidToggleFullscreen` (the menu redraws 10 ticks later). False when the switch
    /// did not happen (no main screen).
    func setFullScreen(_ on: Bool) -> Bool {
        if on { shell.enterFullscreen() } else { shell.exitFullscreen() }
        guard shell.isFullscreen == on else { return false }
        menus.setHideKeysCleared(on)
        present()
        frontEnd?.didToggleFullscreen()
        return true
    }

    // MARK: Cursor (`_SetMyCCursor`, `_RequestGame` / `_PlayGame` / `_PauseGame`)

    /// `crsr 200` as an `NSCursor` (Q16: decoded by `ColorCursor`; 16 × 16 points, the hot spot from the resource).
    private static func makeHandCursor(_ data: BTXGameData) -> NSCursor? {
        guard let bytes = data.data(type: "crsr", id: 200), let c = try? ColorCursor(data: bytes) else { return nil }
        let w = c.image.width, h = c.image.height
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8,
                                         samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                         colorSpaceName: .deviceRGB, bytesPerRow: w * 4, bitsPerPixel: 32),
              let out = rep.bitmapData else { return nil }
        for (i, p) in c.image.pixels.enumerated() {         // straight alpha 0 or 0xFF: RGB is already premultiplied
            out[i * 4] = UInt8(truncatingIfNeeded: p >> 16)
            out[i * 4 + 1] = UInt8(truncatingIfNeeded: p >> 8)
            out[i * 4 + 2] = UInt8(truncatingIfNeeded: p)
            out[i * 4 + 3] = UInt8(truncatingIfNeeded: p >> 24)
        }
        let image = NSImage(size: NSSize(width: w, height: h))
        image.addRepresentation(rep)
        return NSCursor(image: image, hotSpot: NSPoint(x: c.hotSpot.h, y: c.hotSpot.v))
    }

    /// `_SetMyCCursor(200)` / `_InitCursor`: QuickDraw's cursor is global and stays until changed.
    private func setCursor(_ c: NSCursor) {
        cursor = c
        c.set()
    }

    /// AppKit resets the cursor to the arrow on its own (window entry, activation); while active and shown, the
    /// cursor the game last set is put back each tick — the QuickDraw cursor never changed by itself.
    private func keepCursor() {
        guard NSApp.isActive, !cursorHidden, NSCursor.current != cursor else { return }
        cursor.set()
    }

    /// `.hideCursor`. During the level-start wipe it is `_RequestGame`'s plain `_HideMyCursor` (and the full-screen
    /// splash's); once a game's frames run (`_PlayGame` after the first wipe, DC 15652…; `_PauseGame` exit, DC
    /// 15416…) it is the capture: `_GetMouse(gSavedMousePosition)`, warp to the main display's centre unless the
    /// button is down, `CGAssociateMouseAndMouseCursorPosition(0)`, `_HideMyCursor`. Idempotent (`gCursorVisible`).
    private func hideCursor() {
        if let session, session.phase != .wipe, !mouseCaptured {
            savedMouse = CGEvent(source: nil)?.location
            if NSEvent.pressedMouseButtons == 0 {
                let b = CGDisplayBounds(CGMainDisplayID())
                CGWarpMouseCursorPosition(CGPoint(x: b.origin.x + b.width * 0.5, y: b.origin.y + b.height * 0.5))
            }
            CGAssociateMouseAndMouseCursorPosition(0)
            mouseCaptured = true
        }
        if !cursorHidden {
            NSCursor.hide()
            cursorHidden = true
        }
    }

    /// `_ShowMyCursor` + `CGAssociateMouseAndMouseCursorPosition(1)`; idempotent. (`.restoreMousePosition`, sent
    /// just before it, puts the pointer back.)
    private func showCursor() {
        if mouseCaptured {
            CGAssociateMouseAndMouseCursorPosition(1)
            mouseCaptured = false
        }
        if cursorHidden {
            NSCursor.unhide()
            cursorHidden = false
        }
    }

    // MARK: Lifecycle

    /// `kEventAppDeactivated` (suspend): queued by the menu loop (`_SuspendGame`), a demo ends, a game pauses at its
    /// next frame.
    func applicationDidResignActive(_ notification: Notification) {
        guard let frontEnd else { return }
        handle(frontEnd.appDeactivated(), now: ShellClock.ticks())
    }

    /// `kEventAppActivated` (resume): the menu loop's `_ResumeGame`; a pause taken by deactivation may end (Caps
    /// Lock off); a demo ends.
    func applicationDidBecomeActive(_ notification: Notification) {
        guard let frontEnd else { return }
        handle(frontEnd.appActivated(keys: heldKeys()), now: ShellClock.ticks())
    }

    /// Quit saves the prefs from outside a game (the front end's `.quit`, the menu screens) and from the pause
    /// (`saveOnQuit`); the game's own ⌘Q path (`_PlayGame` → `_CleanUp`) never saves (R7; `GameSession.isInGame`).
    func applicationWillTerminate(_ notification: Notification) {
        if !quitWithoutSaving && (saveOnQuit || !(session?.isInGame ?? false)) && store != nil {
            savePrefs()
        }
        showCursor()
    }

    // MARK: ShellInputHandler

    /// keyDown and autoKey events (`_Interface` handles both; `_PauseGame` key-downs only — `FrontEnd.key`). The
    /// character is the event's with the modifiers applied, as Carbon's `charCode` (Ctrl-C = 0x03); play itself
    /// reads the keyboard by polling (`GetKeys`, K1 key state).
    func shellView(_ view: ShellView, keyDown event: NSEvent) {
        guard let frontEnd else { return }
        handle(frontEnd.key(event.keyCode, chars: event.characters ?? "", modifiers: Self.modifiers(event),
                            isRepeat: event.isARepeat), now: ShellClock.ticks())
    }

    func shellView(_ view: ShellView, mouseDown event: NSEvent) {
        guard let frontEnd else { return }
        let p = logicalPoint(event)
        handle(frontEnd.mouseDown(h: p.h, v: p.v, modifiers: Self.modifiers(event)), now: ShellClock.ticks())
    }

    /// K1's mouseUp forwarding: ends `_HandleMSMouse`'s `StillDown` tracking.
    func shellView(_ view: ShellView, mouseUp event: NSEvent) {
        guard let frontEnd else { return }
        let p = logicalPoint(event)
        handle(frontEnd.mouseUp(h: p.h, v: p.v, modifiers: Self.modifiers(event)), now: ShellClock.ticks())
    }

    /// The event's point in the 640×480 logical screen (truncating, unclamped).
    private func logicalPoint(_ event: NSEvent) -> ShellPoint {
        let view = shell.view
        return ShellScaling.logicalPoint(viewPoint: view.convert(event.locationInWindow, from: nil),
                                         imageRect: view.imageRectInPoints, logicalWidth: view.logicalWidth,
                                         logicalHeight: view.logicalHeight)
    }

    /// `EventRecord.modifiers` as the front end reads them.
    private static func modifiers(_ event: NSEvent) -> KeyModifiers {
        let f = event.modifierFlags
        return KeyModifiers(command: f.contains(.command), shift: f.contains(.shift), option: f.contains(.option),
                            control: f.contains(.control), capsLock: f.contains(.capsLock))
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

/// `CGDisplayFade` for the full-screen splash (`_InitMac`: 0.1 s to black, 0.6 s back, 0.6 s out). HectorShell has no
/// display-fade API, so the fade is a black shield over every screen whose opacity animates — the original's gamma
/// fade as it looks, without touching the displays' gamma (a crash can never leave a screen black). The front end
/// holds the duration in ticks, as the synchronous original blocked.
@MainActor final class BTXDisplayFade {
    private var windows: [NSWindow] = []

    func fade(toBlack: Bool, seconds: Double) {
        if windows.isEmpty {
            guard toBlack else { return }
            windows = NSScreen.screens.map { screen in
                let w = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
                w.isReleasedWhenClosed = false
                w.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()) + 1)
                w.backgroundColor = .black
                w.isOpaque = false
                w.hasShadow = false
                w.ignoresMouseEvents = true
                w.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
                w.alphaValue = 0
                w.setFrame(screen.frame, display: false)
                w.orderFrontRegardless()
                return w
            }
        }
        let shields = windows
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = seconds
            for w in shields { w.animator().alphaValue = toBlack ? 1 : 0 }
        }, completionHandler: { @Sendable [weak self] in
            Task { @MainActor in self?.removeIfClear() }
        })
    }

    /// Back from black: the shields go once fully clear (a fade to black started meanwhile keeps them).
    private func removeIfClear() {
        guard let first = windows.first, first.alphaValue == 0 else { return }
        for w in windows { w.orderOut(nil) }
        windows = []
    }
}
