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
@MainActor final class BTXController: NSObject, NSApplicationDelegate, NSMenuItemValidation, ShellInputHandler {
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

    /// `.enableMenus` (the game disables the menu bar while frames run).
    private var menusEnabled = true
    /// `.disableAbout` (kept for A3's About item).
    private var aboutDisabled = false
    /// `.quitNow` (⌘Q in play, R7): the terminate path skips the prefs save.
    private var quitWithoutSaving = false
    /// `_HideMyCursor` / `_ShowMyCursor` balance (NSCursor.hide counts).
    private var cursorHidden = false
    /// `gSavedMousePosition` (global, top-left origin), taken when the game begins (`_RequestGame`).
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
            fatalError("Bubble Trouble X: cannot load the original data: \(error)")
        }
        compositor = Compositor(art: art, text: CoreTextRasterizer())
        // K3's `ShellMixer` is not on HectorKit main yet: a silent output stands in (one-file swap later).
        audio = BTXAudio(output: SilentAudioOutput(), sounds: sounds, data: data)
        applyPrefsToAudio()

        NSApp.mainMenu = Self.buildMenuBar()

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

    /// The menu bar until A3 transcribes `main.nib`: the application menu with Quit (⌘Q), disabled while the game
    /// disables the menus — ⌘Q then reaches the game as keys (`_PlayGame`'s `GameKeyDown(0xc)` + ⌘, R7).
    private static func buildMenuBar() -> NSMenu {
        let bar = NSMenu()
        let appItem = NSMenuItem()
        bar.addItem(appItem)
        let appMenu = NSMenu(title: "Bubble Trouble X")
        appMenu.addItem(withTitle: "Quit Bubble Trouble X", action: #selector(NSApplication.terminate(_:)),
                        keyEquivalent: "q")
        appItem.submenu = appMenu
        return bar
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        menusEnabled
    }

    // MARK: Game

    /// `_RequestGame(1, play)` (temporary A1 entry): a new game at level 1, seeded from TickCount.
    private func startNewGame() {
        savedMouse = CGEvent(source: nil)?.location                     // `_GetMouse(gSavedMousePosition)`
        do {
            session = try GameSession(data: data, prefs: prefs, mode: .play, startLevel: 1,
                                      seed: ShellClock.ticks(), film: nil)
        } catch {
            fatalError("Bubble Trouble X: cannot start a game: \(error)")
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
        handle(session.frame(keys: heldKeys()))
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
        handle(session.tick(now: now, keys: heldKeys()), alreadyDirty: dirty)
    }

    /// Carries out one `SessionOutput`: requests (`ST_HaltSound` before the cues that follow it), music, effects,
    /// draw ops, present; then the end of the game and the clock for the new phase.
    private func handle(_ out: SessionOutput, alreadyDirty: Bool = false) {
        var quit = false
        for request in out.requests {
            switch request {
            case .hideCursor: hideCursor()
            case .showCursor: showCursor()
            case let .enableMenus(on): menusEnabled = on
            case .haltAllSound: audio.haltEffects()
            case .highScoreEntry: break                                 // A4's dialog (C7); no high scores at A1
            case .quitNow: quit = true
            case .savePrefs: savePrefs()
            case let .setCursor(id): (id == 200 ? NSCursor.pointingHand : NSCursor.arrow).set()   // crsr 200: Q16
            case .restoreMousePosition:
                if let savedMouse { CGWarpMouseCursorPosition(savedMouse) }
            case let .disableAbout(off): aboutDisabled = off
            case .beep: NSSound.beep()
            }
        }
        for cue in out.music { audio.apply(cue) }
        for cue in out.sounds { audio.play(cue) }
        if !out.drawOps.isEmpty {
            compositor.apply(out.drawOps)
            if let step = out.drawOps.lastWipeStep {                    // the op itself copied the first band pair
                wipe = (step, 0, ShellClock.ticks())
            }
        }
        // A wipe still unfinished when its blocking phase ended completes at once (the original's loop ran out).
        if let w = wipe, session?.phase != .wipe {
            let rows = Compositor.wipeSteps(w.step)
            if w.row < rows {
                for row in (w.row + 1)...rows { compositor.applyWipe(row: row) }
            }
            wipe = nil
            present()
        } else if alreadyDirty || !out.drawOps.isEmpty {
            present()
        }

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
        if case .originalWouldQuit = reason {
            quitWithoutSaving = true
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

    /// `_HideMyCursor` with the play-mode mouse capture: warp to the main display's centre (unless the button is
    /// down), `CGAssociateMouseAndMouseCursorPosition(0)`, hide.
    /// Idempotent (the original guards with `gCursorVisible`): the session may ask twice.
    private func hideCursor() {
        guard !cursorHidden else { return }
        if NSEvent.pressedMouseButtons == 0 {
            let b = CGDisplayBounds(CGMainDisplayID())
            CGWarpMouseCursorPosition(CGPoint(x: b.origin.x + b.width * 0.5, y: b.origin.y + b.height * 0.5))
        }
        CGAssociateMouseAndMouseCursorPosition(0)
        NSCursor.hide()
        cursorHidden = true
    }

    /// `_ShowMyCursor` + `CGAssociateMouseAndMouseCursorPosition(1)`; idempotent.
    private func showCursor() {
        guard cursorHidden else { return }
        NSCursor.unhide()
        CGAssociateMouseAndMouseCursorPosition(1)
        cursorHidden = false
    }

    // MARK: Lifecycle

    /// Event kind 2 (suspend): the game pauses at its next frame.
    func applicationDidResignActive(_ notification: Notification) {
        session?.appDeactivated()
    }

    /// Event kind 1 (resume): a pause taken by deactivation may end (Caps Lock off).
    func applicationDidBecomeActive(_ notification: Notification) {
        guard let session else { return }
        handle(session.appActivated(keys: heldKeys()))
    }

    /// Quit saves the prefs only from outside a game (the menu screens, A2): `_CleanUp` from inside a game never
    /// saves — ⌘Q in play (`.quitNow`, R7) or any quit while a session is in any phase (orchestrator ruling on C4's
    /// review; C4 adds `GameSession.isInGame`, which replaces the phase test here after the rebase).
    func applicationWillTerminate(_ notification: Notification) {
        let inGame = session.map { $0.phase != .ended } ?? false
        if !quitWithoutSaving && !inGame && store != nil {
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
