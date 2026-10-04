// The front end (plan 2026-10-04 btx-playable C6, S2; FI §1–§2): everything from launch to quit that is not a game
// frame — `_InitMac @ 0000563c`'s splash, `_Interface @ 0000b500`'s main-menu loop, the attract mode, demo and play
// sessions (`_RequestGame @ 0000a9a1`, owning a `GameSession`), level select and the hand-over to the scores /
// credits / high-score screens (C7).
//
// Time base (Invariant 4): `tick(now:keys:mouse:)` is TickCount (1/60 s); while a game runs the App also calls
// `frame(keys:)` on the 0.033 s timer (`wantsFrameTimer`). The original's blocking sequences (`_WaitFor`, the wipes,
// the `_StopMusic` fade, splash holds, modal dialogs) become steps the front end holds on ticks, input ignored as
// the original ignores it. `_Interface`'s loop body runs once per tick; one queued event is handled per iteration
// (`ReceiveNextEvent`); events arriving while a step blocks stay queued unless a `FlushEvents` drops them.
//
// Randomness: `_GetRandomFast` is QuickDraw `Random()` on the one process seed `qd.randSeed`. Every game reseeds it
// (`SetQDGlobalsRandomSeed` — TickCount in play, FILM.seed in a demo), so front-end draws never reach a game (G4);
// the front end keeps its own `GameRandom` (process seed 1, NR-3 — the core's `SessionLatches` assumption) and
// takes over the game's stream when a game returns, as the shared seed would.

import Foundation

/// Where the front end stands.
public enum FrontEndPhase: Equatable, Sendable {
    /// `_InitMac`'s splash and loading screen.
    case splash
    /// `_Interface`'s loop, idle (no blocking step pending).
    case menu
    /// A blocking front-end sequence (button flash, wipe, music fade, dialog, scores / credits screen).
    case busy
    /// A game or demo is running (`session`).
    case game
    /// `gFinished` / `.quitNow`: the App quits.
    case quit
}

/// A full-screen sequence the front end hands control to and waits on — C7's `_DisplayHiScores @ 00025733`,
/// `_DisplayCredits @ 0002145a` and `_CheckHiScore @ 00024b34` (C6 ships placeholders that finish at once).
///
/// Screens are built lazily, when their step is reached (so they see the state as it then stands — e.g. the table
/// just reset by the erase dialog), from factories that get the `FrontEnd`: a screen reads and writes back
/// `frontEnd.highScores`, `frontEnd.storedPrefs` and draws from `frontEnd.random` (the process stream — C5's
/// "Maniac"/"Swoop" `GetRandomFast(0, 1)`). Every input the front end receives while a screen runs is forwarded.
protocol FrontEndScreen: AnyObject {
    func tick(now: UInt32, keys: HeldKeys, mouse: MousePoint) -> SessionOutput
    func key(_ code: UInt16, chars: String, modifiers: KeyModifiers) -> SessionOutput
    func mouseDown(h: Int, v: Int, modifiers: KeyModifiers) -> SessionOutput
    func mouseUp(h: Int, v: Int, modifiers: KeyModifiers) -> SessionOutput
    func appActivated() -> SessionOutput
    func appDeactivated() -> SessionOutput
    /// A dialog the screen requested was answered (DLOG 1000 name entry → `FrontEnd.highScoreNameEntered`).
    func dialogAnswered(_ answer: FrontEndDialogAnswer) -> SessionOutput
    /// nil while running.
    var result: FrontEndScreenResult? { get }
}

/// An answer the App gives to a dialog a C7 screen requested.
public enum FrontEndDialogAnswer: Equatable, Sendable {
    /// DLOG 1000 "High Score Name": the text in the field when OK was hit.
    case name(String)
    case dismissed
}

/// How a `FrontEndScreen` ended: `_DisplayHiScores` / `_DisplayCredits` return true when N was pressed (→
/// `_NewGameButton`); `_CheckHiScore` returns whether a name was entered, with the table row it went into (the
/// row `_DisplayHiScores` then flashes; nil = none → the plain menu path of `_RequestGame`).
enum FrontEndScreenResult: Equatable, Sendable {
    case finished
    case newGame
    case highScoreEntered(rank: Int?)
}

/// C6's stand-in for a C7 screen: no output, finishes on its first tick with `result`.
final class PlaceholderScreen: FrontEndScreen {
    private let outcome: FrontEndScreenResult
    private(set) var result: FrontEndScreenResult?
    init(_ outcome: FrontEndScreenResult) { self.outcome = outcome }
    func tick(now: UInt32, keys: HeldKeys, mouse: MousePoint) -> SessionOutput {
        result = outcome
        return SessionOutput()
    }
    func key(_ code: UInt16, chars: String, modifiers: KeyModifiers) -> SessionOutput { SessionOutput() }
    func mouseDown(h: Int, v: Int, modifiers: KeyModifiers) -> SessionOutput { SessionOutput() }
    func mouseUp(h: Int, v: Int, modifiers: KeyModifiers) -> SessionOutput { SessionOutput() }
    func appActivated() -> SessionOutput { SessionOutput() }
    func appDeactivated() -> SessionOutput { SessionOutput() }
    func dialogAnswered(_ answer: FrontEndDialogAnswer) -> SessionOutput { SessionOutput() }
}

/// The front end (S2). Main-actor use by the App; not Sendable.
public final class FrontEnd {
    // MARK: Public state

    public internal(set) var phase: FrontEndPhase = .splash
    /// The running game / demo, if any.
    public internal(set) var session: GameSession?
    /// The prefs as they stand (a running game's copy while it runs — `_LoadLevel` raises short 0x3a).
    public var prefs: BTXPrefs { session?.prefs ?? storedPrefs }
    public internal(set) var highScores: HighScoreTable
    /// True while a game frame is due on the 0.033 s timer.
    public var wantsFrameTimer: Bool { phase == .game && session?.wantsFrameTimer == true }
    /// `gFilmCounter` (bss → 0: the first demo is FILM 1 — closes U10 / Q11) and `gNumFilmsAvailable`.
    var filmCounter = 0
    var numFilms = 0
    /// `gMsgCounter`, `gInfoTimer`, `gSuspended`.
    var msgCounter = 0
    var infoTimer: UInt32 = 0
    var suspended = false
    /// The title music as the front end has driven it (`gMusicLoaded`, "the channel is busy", `gMusicPaused`).
    var musicLoaded = false
    var musicPlaying = false
    var musicPaused = false
    /// The process `qd.randSeed` stream (`_GetRandomFast`).
    var random: GameRandom
    /// `_Get0To6` / `_Get13To22` as `_Interface` latched them.
    var latches: SessionLatches?
    var stars = MenuStars()

    // MARK: Internals

    let data: BTXGameData
    let menu: MainMenu
    var storedPrefs: BTXPrefs
    var info: InfoBox
    let today: () -> (month: Int, day: Int)
    /// `local_3c` — the idle timer; `bVar2` — the Demo / Scores alternation.
    var idleStart: UInt32 = 0
    var idleShowsScores = false
    /// `local_30` — the full-screen-toggle redraw deadline (0 = none).
    var redrawAt: UInt32 = 0
    var doPrefsNow = false
    var foreground = true
    var hitButtons = Set<MainMenu.Button>()
    var mouse = MousePoint(h: 320, v: 240, button: false)
    var now: UInt32 = 0
    var ticked = false

    enum Event: Equatable {
        case key(chars: String, modifiers: KeyModifiers)
        case mouseDown(h: Int, v: Int, modifiers: KeyModifiers)
        /// Class 'appl' kind 1 / 2 — not dropped by `FlushEvents(0x3e)`.
        case activated
        case deactivated
    }
    var events: [Event] = []

    /// A blocking step of a sequence; `.run` steps execute at once and may push further steps in front.
    enum Step {
        case run(() -> SessionOutput)
        /// `_WaitFor(n)`: done when TickCount ≥ start + n.
        case waitTicks(Int)
        /// Done when TickCount ≥ the deadline the closure gives at the step's start.
        case waitUntil(() -> UInt32)
        /// A `.wipe` / `.wipeOut` op in flight: `n` advances, one per tick that TickCount has moved on.
        case advances(Int)
        /// `_StopMusic`'s blocking fade (from `fadeVolume`).
        case musicFade
        /// The game / demo in `session`.
        case game(then: (GameSession) -> [Step])
        /// A C7 screen, built when the step is reached (`activeScreen`).
        case screen(make: () -> FrontEndScreen, then: (FrontEndScreenResult) -> [Step])
        /// A modal dialog the App shows; resumes with its answer.
        case dialog(then: (DialogAnswer) -> [Step])
        /// Button tracking (`_HandleMSMouse`'s `StillDown` loop).
        case track(MainMenu.Button, modifiers: KeyModifiers)
    }

    enum DialogAnswer: Equatable {
        case dismissed
        case levelSelect(Int?)
        case erase(Bool)
        case prefs
    }

    var steps: [Step] = []
    /// The running step's clock (start / last tick / count / fade volume).
    var stepStart: UInt32?
    var stepLast: UInt32 = 0
    var stepCount = 0
    var stepDeadline: UInt32 = 0
    var fadeVolume = 0
    /// Button tracking state (`bVar1` lit, `bVar2` first pass) and the release seen by `mouseUp`.
    var trackLit = false
    var trackFirst = true
    var released: (h: Int, v: Int, modifiers: KeyModifiers)?
    var lastSessionTick: UInt32?
    /// The screen of the `.screen` step at the front, once built.
    var activeScreen: FrontEndScreen?

    /// - Parameters:
    ///   - registeredName: info message 2's `RT3_GetDisplayName` (Q15: the macOS account's full name).
    ///   - today: (month, day) for `_Interface_GetOccasions` / `_DoBirthdaysCheck`.
    public init(data: BTXGameData, prefs: BTXPrefs, highScores: HighScoreTable, registeredName: String,
                licenceCopies: Int = 1, today: @escaping () -> (month: Int, day: Int) = FrontEnd.systemToday,
                processSeed: UInt32 = 1) {
        self.data = data
        self.storedPrefs = prefs
        self.highScores = highScores
        self.today = today
        menu = MainMenu(data: data)
        info = InfoBox(registeredName: registeredName, licenceCopies: licenceCopies)
        random = GameRandom(seed: processSeed)
        steps = splashSteps()
    }

    /// Today's (month, day) from the system calendar.
    public static func systemToday() -> (month: Int, day: Int) {
        let c = Calendar.current.dateComponents([.month, .day], from: Date())
        return (c.month ?? 1, c.day ?? 1)
    }

    // MARK: - Driving

    /// One TickCount tick.
    public func tick(now: UInt32, keys: HeldKeys, mouse: MousePoint) -> SessionOutput {
        self.now = now
        ticked = true
        if !suspended { self.mouse = mouse }
        var out = SessionOutput()
        if phase == .quit { return out }
        // A running game / screen gets its tick first.
        if case .game = steps.first, let s = session, lastSessionTick != now {
            lastSessionTick = now
            out.append(s.tick(now: now, keys: keys))
            out.append(checkGameEnd(out))
        } else if case .screen? = steps.first, let screen = activeScreen {
            out.append(screen.tick(now: now, keys: keys, mouse: mouse))
        }
        out.append(runSteps(keys: keys))
        if steps.isEmpty && phase != .quit && phase != .splash {
            phase = .menu
            out.append(menuIteration(keys: keys))
        }
        return out
    }

    /// One 0.033 s frame of the running game / demo.
    public func frame(keys: HeldKeys) -> SessionOutput {
        guard case .game = steps.first, let s = session else { return SessionOutput() }
        var out = SessionOutput()
        // `_StopMusicWithoutFade` at the hero's death runs in a demo too: it stops the title music (demo only —
        // in play the title music is unloaded and the session drives the level music).
        let deathDue = s.mode == .demo && s.phase == .playing && s.state.upcomingHeroTransition == .death
        out.append(s.frame(keys: keys))
        if deathDue && musicLoaded {
            out.music.append(.stopNow)
            musicPlaying = false
        }
        out.append(checkGameEnd(out))
        out.append(runSteps(keys: keys))
        return out
    }

    /// A keyDown / autoKey event. A2: `chars` must be the character WITH the modifiers applied, as the Carbon
    /// event's `charCode` was (`NSEvent.characters`, not `charactersIgnoringModifiers`): `_Interface` switches on
    /// that byte, so Ctrl-C (0x03 = Enter) starts a New Game and Ctrl-M (0x0d) too; ⌘ is in `modifiers.command`.
    public func key(_ code: UInt16, chars: String, modifiers: KeyModifiers) -> SessionOutput {
        switch steps.first {
        case .game?:
            guard let s = session else { return SessionOutput() }
            if s.mode == .demo { s.interrupt(); return SessionOutput() }
            if s.phase == .paused, let c = chars.unicodeScalars.first, c.value < 0x100 {
                return s.pauseKeyTyped(UInt8(c.value))
            }
            return SessionOutput()
        case .screen?:
            return activeScreen?.key(code, chars: chars, modifiers: modifiers) ?? SessionOutput()
        case .dialog?:
            return SessionOutput()
        default:
            if phase == .splash || phase == .quit { return SessionOutput() }   // FlushEvents(0xffff) in the holds
            events.append(.key(chars: chars, modifiers: modifiers))
            return SessionOutput()
        }
    }

    public func mouseDown(h: Int, v: Int, modifiers: KeyModifiers) -> SessionOutput {
        switch steps.first {
        case .game?:
            if let s = session, s.mode == .demo { s.interrupt() }
            return SessionOutput()
        case .screen?:
            return activeScreen?.mouseDown(h: h, v: v, modifiers: modifiers) ?? SessionOutput()
        case .dialog?:
            return SessionOutput()
        default:
            if phase == .splash || phase == .quit { return SessionOutput() }
            events.append(.mouseDown(h: h, v: v, modifiers: modifiers))
            return SessionOutput()
        }
    }

    /// The button went up: ends `_HandleMSMouse`'s `StillDown` loop at the next tick.
    public func mouseUp(h: Int, v: Int, modifiers: KeyModifiers) -> SessionOutput {
        switch steps.first {
        case .track?:
            released = (h, v, modifiers)
        case .screen?:
            return activeScreen?.mouseUp(h: h, v: v, modifiers: modifiers) ?? SessionOutput()
        default:
            break
        }
        return SessionOutput()
    }

    /// The app was deactivated (`kEventAppDeactivated`). In a game / demo the session acts; in a screen it is
    /// forwarded; otherwise it waits in the event queue like the original's, acted on by the loop
    /// (`_SuspendGame`) once no blocking step holds it.
    public func appDeactivated() -> SessionOutput {
        foreground = false
        switch steps.first {
        case .game?:
            guard let s = session else { return SessionOutput() }
            s.appDeactivated()
            // A demo: `_PlayGame` calls `_SuspendGame` before ending it.
            return s.mode == .demo ? suspendGame() : SessionOutput()
        case .screen?:
            return activeScreen?.appDeactivated() ?? SessionOutput()
        default:
            if phase != .splash && phase != .quit { events.append(.deactivated) }
            return SessionOutput()
        }
    }

    /// The app was reactivated (`kEventAppActivated`); queued like `appDeactivated` — the loop then does
    /// `local_3c = TickCount; _ResumeGame`.
    public func appActivated(keys: HeldKeys) -> SessionOutput {
        foreground = true
        switch steps.first {
        case .game?:
            guard let s = session else { return SessionOutput() }
            if s.mode == .demo { s.interrupt(); return SessionOutput() }
            return s.appActivated(keys: keys)
        case .screen?:
            return activeScreen?.appActivated() ?? SessionOutput()
        default:
            if phase != .splash && phase != .quit { events.append(.activated) }
            return SessionOutput()
        }
    }

    /// `gDidToggleFullscreen`: the menu is redrawn 10 ticks later.
    public func didToggleFullscreen() {
        redrawAt = now &+ 10
    }

    /// Preferences… chosen from the menu bar (`_PrefsAppleEventHandler` → `gDoPrefsNow`).
    public func requestPreferences() {
        doPrefsNow = true
    }

    // MARK: Dialog answers

    /// DLOG 160 answered: `typed` = the number in the field when OK was hit, nil for Cancel. On OK the front end
    /// beeps at once when out of range, holds 30 ticks with the dialog up, then emits `closeDialog`.
    public func levelSelectDone(typed: Int?) -> SessionOutput {
        answer(.levelSelect(typed))
    }

    /// DLOG 1000 (a C7 screen's high-score name entry) answered with the text in the field.
    public func highScoreNameEntered(_ name: String) -> SessionOutput {
        guard case .screen? = steps.first, let screen = activeScreen else { return SessionOutput() }
        var out = screen.dialogAnswered(.name(name))
        out.append(runSteps(keys: HeldKeys()))
        return out
    }

    public func prefsDialogDone(prefs: BTXPrefs) -> SessionOutput {
        storedPrefs = prefs
        return answer(.prefs)
    }

    public func hiScoreEraseDone(reset: Bool) -> SessionOutput {
        answer(.erase(reset))
    }

    public func dialogDone() -> SessionOutput {
        if case .screen? = steps.first, let screen = activeScreen {
            var out = screen.dialogAnswered(.dismissed)
            out.append(runSteps(keys: HeldKeys()))
            return out
        }
        return answer(.dismissed)
    }

    private func answer(_ a: DialogAnswer) -> SessionOutput {
        guard case .dialog(let then)? = steps.first else { return SessionOutput() }
        steps.removeFirst()
        steps.insert(contentsOf: then(a), at: 0)
        return runSteps(keys: HeldKeys())
    }

    // MARK: - Step runner

    func runSteps(keys: HeldKeys) -> SessionOutput {
        var out = SessionOutput()
        while let step = steps.first {
            switch step {
            case .run(let f):
                steps.removeFirst()
                out.append(f())
                continue
            case .waitTicks(let n):
                let start = beginStep()
                if now >= start &+ UInt32(n) { endStep(); continue }
            case .waitUntil(let deadline):
                if stepStart == nil { _ = beginStep(); stepDeadline = deadline() }
                if now >= stepDeadline { endStep(); continue }
            case .advances(let n):
                if stepStart == nil { _ = beginStep() } else if stepLast < now { stepCount += 1; stepLast = now }
                if stepCount >= n { endStep(); continue }
            case .musicFade:
                if stepStart == nil {
                    // Started by `stopMusic`, which emitted the first volume.
                    _ = beginStep()
                } else if stepLast < now {
                    stepLast = now
                    fadeVolume -= 5
                    if fadeVolume >= 0 {
                        out.music.append(.volume(fadeVolume))
                    } else {
                        endStep()
                        out.append(stopMusicWithoutFade())
                        continue
                    }
                }
            case .game(let then):
                guard let s = session, s.phase == .ended else { break }
                steps.removeFirst()
                steps.insert(contentsOf: then(s), at: 0)
                continue
            case .screen(let make, let then):
                if activeScreen == nil { activeScreen = make() }
                guard let r = activeScreen?.result else { break }
                activeScreen = nil
                steps.removeFirst()
                steps.insert(contentsOf: then(r), at: 0)
                continue
            case .dialog:
                break
            case .track(let button, let modifiers):
                guard ticked else { break }
                ticked = false
                if let more = trackIteration(button, modifiers: modifiers, out: &out) {
                    steps.removeFirst()
                    steps.insert(contentsOf: more, at: 0)
                    continue
                }
            }
            break
        }
        ticked = false
        if !steps.isEmpty, phase != .splash, phase != .quit {
            if case .game? = steps.first { phase = .game } else { phase = .busy }
        }
        return out
    }

    private func beginStep() -> UInt32 {
        if let s = stepStart { return s }
        stepStart = now
        stepLast = now
        stepCount = 0
        return now
    }

    private func endStep() {
        steps.removeFirst()
        stepStart = nil
    }

    func push(_ more: [Step]) {
        steps.insert(contentsOf: more, at: 0)
    }

    /// QuickDraw `PtInRect`: left ≤ h < right, top ≤ v < bottom.
    static func ptInRect(_ h: Int, _ v: Int, _ r: QDRect) -> Bool {
        h >= Int(r.left) && h < Int(r.right) && v >= Int(r.top) && v < Int(r.bottom)
    }

    // MARK: - Music (`_LoadMusic(0)`, `_StartMusic`, `_StopMusic`, `_UnloadMusic`, `_PauseMusic`, `_ResumeMusic`)

    /// `_LoadMusic(0)`: the title music, "Level set 3 music" (no-op while loaded).
    func loadTitleMusic() -> SessionOutput {
        guard !musicLoaded else { return SessionOutput() }
        musicLoaded = true
        return SessionOutput(music: [.load(set: BTXGameData.titleMusicSet)])
    }

    /// `_StartMusic @ 0001ad8c` on the menu (no game running): the volume first — 0 unless bool 0x40 (title-screen
    /// music), else by short 0x35 (1 → 0, 2 → 0x40, 3 → 0x80, 4 → 0x100) — then the play. The App applies the
    /// `volume` cue to the music voice and must not override it at `start`.
    func startMusic() -> SessionOutput {
        guard musicLoaded else { return SessionOutput() }
        musicPlaying = true
        let byPref: Int = switch prefs.musicVolume {
        case 2: 0x40
        case 3: 0x80
        case 4: 0x100
        default: 0
        }
        let volume = prefs.titleMusic ? byPref : 0
        return SessionOutput(music: [.volume(volume), .start])
    }

    /// `_StopMusic @ 0001afac`: when loaded, music volume not off (short 0x35 ≠ 1), the title music pref on (no
    /// game is running here) and playing → the blocking fade (−5 per tick from 0x40 / 0x80 / 0x100); then
    /// `_StopMusicWithoutFade`.
    func stopMusicSteps() -> [Step] {
        [.run { [unowned self] in
            guard musicLoaded else { return SessionOutput() }
            let start: Int? = switch prefs.musicVolume {
            case 2: 0x40
            case 3: 0x80
            case 4: 0x100
            default: nil
            }
            if prefs.musicVolume != 1, prefs.titleMusic, musicPlaying, let start {
                fadeVolume = start
                push([.musicFade])
                return SessionOutput(music: [.volume(start)])
            }
            return stopMusicWithoutFade()
        }]
    }

    func stopMusicWithoutFade() -> SessionOutput {
        guard musicLoaded else { return SessionOutput() }
        musicPlaying = false
        return SessionOutput(music: [.stopNow])
    }

    /// `_UnloadMusic`.
    func unloadMusic() -> SessionOutput {
        guard musicLoaded else { return SessionOutput() }
        musicLoaded = false
        musicPlaying = false
        return SessionOutput(music: [.unload])
    }

    /// `_SuspendGame @ 00008888`: `gSuspended`, `_PauseMusic`.
    func suspendGame() -> SessionOutput {
        suspended = true
        guard musicLoaded else { return SessionOutput() }
        musicPaused = true
        return SessionOutput(music: [.pause])
    }

    /// `_ResumeGame @ 0000a28e` (registered): `gSuspended = 0`, `gInfoTimer = TickCount`, `crsr 200`, cursor shown,
    /// `_UpdateScreen`.
    func resumeGame() -> SessionOutput {
        suspended = false
        infoTimer = now
        return SessionOutput(drawOps: [.compToScreen(MainMenu.screenRect)],
                             requests: [.setCursor(id: 200), .showCursor])
    }

    /// `_ResumeMusic`: resume, and `_StartMusic` when the channel is idle.
    func resumeMusic() -> SessionOutput {
        guard musicLoaded else { return SessionOutput() }
        var out = SessionOutput(music: [.resume])
        if !musicPlaying { out.append(startMusic()) }
        musicPaused = false
        return out
    }
}
