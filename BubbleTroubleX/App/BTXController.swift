import AppKit
import BubbleTroubleCore
import BubbleTroubleRender
import HectorShell

/// The app delegate and shell owner (plan S3, task A1): loads the original data, opens the 640×480 game window,
/// owns the two clocks (Invariant 4), drives `GameSession` → `Compositor` → `ShellView.present`, plays the cues
/// through `BTXAudio` and carries out the session's `ShellRequest`s.
///
/// At A1 the app launches straight into a new game at level 1 and starts a new one when a game ends (temporary:
/// A2 puts `FrontEnd` — splash, menu, demos — before and after it).
@MainActor final class BTXController: NSObject, NSApplicationDelegate, ShellInputHandler {
    private var data: BTXGameData!
    private var art: ArtBank!
    private var sounds: SoundBankPCM!
    private var compositor: Compositor!
    private var audio: BTXAudio!
    private var store: BTXPrefsStore!
    private var prefs = BTXPrefs.defaults
    private var scores = HighScoreTable.empty
    private var shell: ShellWindowController!
    /// The window's image, refilled from `compositor.screen` on every present.
    private let bitmap = ShellBitmap(width: Compositor.width, height: Compositor.height)

    private var session: GameSession?

    /// Invariant 4: the 0.033 s Carbon frame timer (`_PlayGame` 00018326…00018355) while frames run, else the
    /// TickCount (1/60 s) timer for the blocking sequences. Exactly one runs at a time; a `Timer` drops the fires
    /// it missed, as the original's `gTimerFired` flag did.
    private enum Clock { case none, frame, tick }
    private var clock = Clock.none
    private var frameTimer: ShellIdleTimer!
    private var tickTimer: ShellIdleTimer!

    /// The `_WipeScreen` being paced (`.wipe` op seen): its step, the band advance done, the tick it was done on.
    private var wipe: (step: Int, row: Int, lastTick: UInt32)?

    /// `.disableAbout` — UNUSED until A3 adds the About item (it enables/disables that item from this flag).
    private var aboutDisabled = false
    /// `_CleanUp` from inside a game (`.quitNow`, a data failure): terminate without saving.
    private var quitWithoutSaving = false
    /// Quit while paused: `_PauseGame` case 0x17 (the quit Apple event — Carbon's Quit menu item and ⌘Q arrive as
    /// it) runs `_SaveGamePrefs` → `_StopMusic` → `_CleanUp`, so this quit saves although a game is running.
    private var saveOnQuit = false
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

        NSApp.mainMenu = buildMenuBar()

        // `_CreateGameWindow @ 00010144`: `CreateNewWindow(6, 0x2800000)` 640×480 → titled only (R5), titled
        // "Bubble Trouble X", `RepositionWindow(…, kWindowCenterOnMainScreen)`.
        shell = ShellWindowController(title: "Bubble Trouble X", logicalWidth: Compositor.width,
                                      logicalHeight: Compositor.height, styleMask: [.titled])
        shell.view.inputHandler = self
        centreOnMainScreen(shell.windowedWindow)
        present()
        shell.windowedWindow.makeKeyAndOrderFront(nil)
        NSApp.activate()

        frameTimer = ShellIdleTimer(interval: 0.033) { [weak self] in self?.frameFired() }
        tickTimer = ShellIdleTimer(interval: 1.0 / 60.0) { [weak self] in self?.tickFired() }
        startNewGame()
    }

    /// `kWindowCenterOnMainScreen`: centred in the main screen's area below the menu bar.
    private func centreOnMainScreen(_ window: NSWindow) {
        guard let screen = NSScreen.screens.first else { window.center(); return }
        let area = screen.visibleFrame, size = window.frame.size
        window.setFrameOrigin(NSPoint(x: (area.midX - size.width / 2).rounded(),
                                      y: (area.midY - size.height / 2).rounded()))
    }

    /// The menu bar until A3 transcribes `main.nib`: the application menu with Quit (⌘Q). The original keeps Quit
    /// enabled in play (only 'pref' and 'Full' are disabled, `_PlayGame`); the item goes to `quitChosen`, which
    /// lets a running game quit its own way.
    private func buildMenuBar() -> NSMenu {
        let bar = NSMenu()
        let appItem = NSMenuItem()
        bar.addItem(appItem)
        let appMenu = NSMenu(title: "Bubble Trouble X")
        let quit = appMenu.addItem(withTitle: "Quit Bubble Trouble X", action: #selector(quitChosen(_:)),
                                   keyEquivalent: "q")
        quit.target = self
        appItem.submenu = appMenu
        return bar
    }

    /// Quit (menu ⌘Q, or the quit Apple event via `applicationShouldTerminate`):
    /// - no game: terminate, prefs saved (`_HandleMenuChoice` 0x81/1 → `_SaveGamePrefs`);
    /// - paused: `_PauseGame` case 0x17 (DC ~15381): `_AEProcessAppleEvent` → `_SaveGamePrefs` → `_StopMusic` →
    ///   `_CleanUp` — terminate now WITH the save (the music voice is paused; ⌘-keys never reach the cheat buffer,
    ///   `_PauseGame` case 3 tests cmdKey);
    /// - any other phase: ⌘ + 0x0C is injected into the frames' keys, so `_PlayGame`'s check (00018ea4) runs its
    ///   `_StopMusic` fade and `.quitNow` follows; blocking phases (wipe, fade, count-down) poll no keys, so the
    ///   injection waits for frames to run again.
    @objc func quitChosen(_ sender: Any?) {
        guard let session, session.isInGame else {
            NSApp.terminate(nil)
            return
        }
        if session.phase == .paused {
            saveOnQuit = true
            NSApp.terminate(nil)
        } else {
            quitPending = true
        }
    }

    /// A terminate that did not come from the game (e.g. the quit Apple event) goes through `quitChosen` while a game
    /// runs; the game's own `.quitNow` and every quit outside a game proceed.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if quitWithoutSaving || saveOnQuit || !(session?.isInGame ?? false) { return .terminateNow }
        if session?.phase == .paused {
            saveOnQuit = true
            return .terminateNow
        }
        quitPending = true
        return .terminateCancel
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

    // MARK: Game

    /// `_RequestGame(1, play)` (temporary A1 entry): a new game at level 1, seeded from TickCount.
    private func startNewGame() {
        do {
            session = try GameSession(data: data, prefs: prefs, mode: .play, startLevel: 1,
                                      seed: ShellClock.ticks(), film: nil)
        } catch {
            fail("cannot start a game: \(error)")
            return
        }
        audio.gameRunning = true
        applyPrefsToAudio()
        selectClock()
        tickFired()                                                     // the opening output
    }

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

    /// One 0.033 s fire: one simulation step, one present.
    private func frameFired() {
        guard let session else { return }
        var keys = heldKeys()
        if quitPending {                                                // ⌘Q chosen from the menu (see `quitChosen`)
            keys.codes.insert(0x0c)
            keys.command = true
        }
        handle(session.frame(keys: keys), now: ShellClock.ticks())
    }

    /// One 1/60 s fire: the wipe advances when TickCount has moved on, then the session's blocking phase ticks.
    private func tickFired() {
        guard let session else { return }
        let now = ShellClock.ticks()
        var dirty = false
        if var w = wipe, w.lastTick < now {
            w.row += 1
            w.lastTick = now
            if w.row <= Compositor.wipeSteps(w.step) {
                compositor.applyWipe(row: w.row)
                dirty = true
            }
            wipe = w.row < Compositor.wipeSteps(w.step) ? w : nil
        }
        handle(session.tick(now: now, keys: heldKeys()), now: now, alreadyDirty: dirty)
    }

    /// Carries out one `SessionOutput` produced at TickCount `now`: requests (`ST_HaltSound` before the cues that
    /// follow it), music, effects; a wipe whose blocking phase just ended is finished, then the draw ops, present;
    /// then the end of the game and the clock for the new phase.
    private func handle(_ out: SessionOutput, now: UInt32, alreadyDirty: Bool = false) {
        var quit = false
        for request in out.requests {
            switch request {
            case .hideCursor: hideCursor()
            case .showCursor: showCursor()
            case .enableMenus: break                                    // A3: Prefs / Full Screen items
            case .haltAllSound: audio.haltEffects()
            case .highScoreEntry: break                                 // A4's dialog (C7); no high scores at A1
            case .quitNow: quit = true
            case .savePrefs: savePrefs()
            case let .setCursor(id): (id == 200 ? NSCursor.pointingHand : NSCursor.arrow).set()   // crsr 200: Q16
            case .restoreMousePosition:
                if let savedMouse { CGWarpMouseCursorPosition(savedMouse) }
            case let .disableAbout(off): aboutDisabled = off
            case .beep: NSSound.beep()
            // C6 front-end requests — A2 wires the front end; until then these are not emitted.
            case .watchCursor: break                                    // A2: busy cursor (no public NSCursor)
            case .closeDialog: break                                    // A2/A4: dispose the level-select dialog
            case .levelSelectDialog: break                              // A4: DLOG 160
            case .prefsDialog: break                                    // A4: DLOG 190
            case .hiScoreEraseDialog: break                             // A4: DLOG 1001
            case .modalDialog: break                                    // A4: DLOG 290/291/3000/3001
            case .quit: break                                           // A2: quit through the prefs-saving path
            case .displayFade: break                                    // A2: CGDisplayFade (full-screen splash)
            }
        }
        for cue in out.music { audio.apply(cue) }
        for cue in out.sounds { audio.play(cue) }
        // A wipe still unfinished when its blocking phase ended completes first (`_WipeScreen` returns before
        // `_NewLevel` draws on), then this output's post-wipe ops.
        var dirty = alreadyDirty
        if let w = wipe, session?.phase != .wipe {
            let rows = Compositor.wipeSteps(w.step)
            if w.row < rows {
                for row in (w.row + 1)...rows { compositor.applyWipe(row: row) }
                dirty = true
            }
            wipe = nil
        }
        if !out.drawOps.isEmpty {
            compositor.apply(out.drawOps)
            dirty = true
            if let step = out.drawOps.lastWipeStep {                    // the op itself copied the first band pair
                wipe = (step, 0, now)
            }
        }
        if dirty { present() }

        if quit {
            quitWithoutSaving = true
            NSApp.terminate(nil)
            return
        }
        if let ended = out.ended {
            gameEnded(ended)
            return
        }
        selectClock()
    }

    /// The game is over. At A1 a new one starts at once; `originalWouldQuit` quits as the original's `_CleanUp`.
    private func gameEnded(_ reason: SessionEnd) {
        session = nil
        audio.gameRunning = false
        switch reason {
        case .originalWouldQuit, .quit:
            quitWithoutSaving = true
            NSApp.terminate(nil)
            return
        default:
            break
        }
        if quitPending {                        // the game ended before its ⌘Q check ran: an ordinary quit (saves)
            NSApp.terminate(nil)
            return
        }
        startNewGame()
    }

    private func selectClock() {
        let want: Clock = session == nil ? .none : (session!.wantsFrameTimer ? .frame : .tick)
        guard want != clock else { return }
        frameTimer.invalidate()
        tickTimer.invalidate()
        switch want {
        case .frame: frameTimer.start()
        case .tick: tickTimer.start()
        case .none: break
        }
        clock = want
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

    /// `_LoadLevel` / quit: the prefs as the game left them (short 0x3a) plus the high scores.
    private func savePrefs() {
        if let session { prefs = session.prefs }
        store.save(prefs: prefs, scores: &scores)
    }

    // MARK: Cursor (`_RequestGame` / `_PlayGame` / `_PauseGame`)

    /// `.hideCursor`. During the level-start wipe it is `_RequestGame`'s plain `_HideMyCursor`; once frames run
    /// (`_PlayGame` after the first wipe, DC 15652…; `_PauseGame` exit, DC 15416…) it is the capture:
    /// `_GetMouse(gSavedMousePosition)`, warp to the main display's centre unless the button is down,
    /// `CGAssociateMouseAndMouseCursorPosition(0)`, `_HideMyCursor`. Idempotent (`gCursorVisible`).
    private func hideCursor() {
        if session?.phase != .wipe && !mouseCaptured {
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

    /// Event kind 2 (suspend): the game pauses at its next frame.
    func applicationDidResignActive(_ notification: Notification) {
        session?.appDeactivated()
    }

    /// Event kind 1 (resume): a pause taken by deactivation may end (Caps Lock off).
    func applicationDidBecomeActive(_ notification: Notification) {
        guard let session else { return }
        handle(session.appActivated(keys: heldKeys()), now: ShellClock.ticks())
    }

    /// Quit saves the prefs from outside a game (the menu screens, A2) and from the pause (`saveOnQuit`); the
    /// game's own ⌘Q path (`_PlayGame` → `_CleanUp`) never saves (R7; `GameSession.isInGame`).
    func applicationWillTerminate(_ notification: Notification) {
        if !quitWithoutSaving && (saveOnQuit || !(session?.isInGame ?? false)) && store != nil {
            savePrefs()
        }
        showCursor()
    }

    // MARK: ShellInputHandler

    /// Play reads the keyboard by polling (`GetKeys`, K1 key state); key events themselves do nothing at A1.
    func shellView(_ view: ShellView, keyDown event: NSEvent) {}

    /// The mouse is unused in play.
    func shellView(_ view: ShellView, mouseDown event: NSEvent) {}
}

private extension [DrawOp] {
    /// The step of the last `.wipe` op, if any.
    var lastWipeStep: Int? {
        for op in reversed() { if case let .wipe(step) = op { return step } }
        return nil
    }
}
