import Foundation
import DeimosCore
import DeimosRender
import DeimosAudio

/// What one `DeimosDriver.idle` call produced (plan S5).
public struct DriverOutput: Equatable, Sendable {
    /// The window content (`DeimosDriver.screen`) changed since the previous call: a present, a fade step or a
    /// HUD screen blit ran.
    public var screenChanged: Bool
    /// The shell requests of every pass that began in this call, in order.
    public var requests: [ShellRequest]

    public init(screenChanged: Bool = false, requests: [ShellRequest] = []) {
        self.screenChanged = screenChanged
        self.requests = requests
    }
}

/// Runs the front end's passes (`FrontEnd`, Phase 4 plan S1b — its only client; the games are the front end's) on a
/// `DeimosRenderer` against the host's clock (plan H1). The original runs its loops flat out and busy-waits on
/// `TickCount`; the replica turns each wait into a yield, so the driver is a resumable state machine — no threads,
/// no sleeping. The app calls `idle` often (every 1/240 s); each call runs ops until one must wait and returns.
///
/// - **Passes.** A pass (`FrontEnd.pass`: a screen's, or the game's `DeimosSession.pass`) begins only after the
///   previous pass's ops have all run; its keys are the ones handed to the `idle` call in which it begins (the
///   begin-frame input read, `1003052c..10030544`).
/// - **`.limit`** — the FPS limiter (`FUN_10030bc0` `10030ce4..10030d30`, timing-frame §2.3): continue only when
///   `TickCount ≥ lastPresent + FPS_Delay` (PermFloat 33 = 2; `lwz +0x1c; add` at `10030d08..10030d14`, then
///   `cmplw; blt` at `10030d20..10030d24` — unsigned, the sum wrapping), then `lastPresent = TickCount` (a second read,
///   `10030d28..10030d30`). The stamp lives in the frame controller (+0x1c), zeroed at session start
///   (`FUN_10030190`). The session emits the op only when byte pref 10 is set. The wrap is replicated: with the stamp
///   at 0xFFFFFFFE / 0xFFFFFFFF the target wraps to 0 / 1 and the wait never blocks until the tick count wraps too
///   (the original runs flat out for those ≤ 2 ticks).
/// - **Bounded work per `idle`** — at most one limiter release per game, at most one present and at most one game
///   end per call; at any of those bounds the call returns and the next call resumes. In steady play the limiter
///   alone is the yield (one release, one present per call), so the bounds bind only where the original would not
///   have waited: the tick wrap above, and a new game that would quit at once.
/// - **`.fade(kind, present)`** — the blocking fades (`FUN_1000ba70` / `FUN_1000b9a0`): `fadeBegin`; `t0 = TickCount`
///   (`1000bac4`); for each level: `fadeStep` (the step's present), then wait until `TickCount ≥ t0 + 1` (unsigned,
///   `1000bb50..1000bb64`), `t0 = TickCount` (`1000bb68..1000bb78`); then `fadeEnd`.
/// - **No catch-up** (timing-frame §4): the waits are the only pacing and both are "≥ a target", so a stall lets
///   exactly one late pass through; the next target is measured from its stamp.
/// - **Game end** — Esc, game over, a film's end and (plan LT) the campaign end after the last sector end a game
///   (the pass that ends it still runs to its end and carries `sessionEnded`; a level transition to the next sector
///   does not). Once that pass's ops are done, in the same `idle` and at most once per call: the game end's halt and
///   stop (below), the end-of-session `FlushEvents` (`FUN_100302b0`, `10005af0`), and the Esc latch — the Esc that
///   ended the game reads as up until ANY `idle` call sees it released (the original's flush, and a menu with no Esc
///   action, front-end.md §2, mean a new game needs a fresh press); then the front end's next pass begins. What
///   follows a game is the front end's: the direct start (ruling 10, what the app runs until the menu lands) starts
///   the next game at once — at the direct start's own start (never the sector the ended game had reached, plan AP
///   ruling 1), seed and FPS clock = the `TickCount` of that pass (`srand(TickCount())`, `100057c8`; `FUN_100305e0`),
///   from the live prefs the ended game handed back (F6, the FPS monitor, `supermunki`, the volume), reusing the
///   loaded level set — or, with the quit flag set, asks the shell to quit. The renderer's buffers persist across it.
///   **A new game** (`FrontEndState.gamesStarted` moves on the pass that starts it): its frame controller is fresh
///   (`FUN_10030190`), so the limiter stamp is 0 and its first limiter may release in the same `idle`.
/// - **Cursor** — the front end's pass that starts a game carries `.hideCursor`, a return to a menu `.showCursor`;
///   `requests` passes them on, with every other shell request (`.quit` included).
/// - **Stores** — a pass's `ShellRequest.saveLastFilm(bytes)` also goes to the Last Film store; `shutdown()` hands
///   the live prefs to the settings store, and a pass that carries `ShellRequest.quit` runs it as it begins (the
///   shutdown `FUN_10000630` → `FUN_100045f0` writes the prefs before the app ends, question 4: every quit saves), so
///   the app only has to terminate.
/// - **Keys** (H2) — a pass's `typed` characters are every key-down handed to `idle` since the previous pass began
///   (the OS event queue `GetOSEvent` drains), in order; a game end flushes them, and so does the pause screen as
///   its wait begins (`10022f1c`); the front end flushes them again as a game starts (`FUN_10030210`). The pass gets
///   `ticks` = the `TickCount` of the `idle` in which it begins (the FPS monitor's clock).
/// - **Audio** (H2) — each pass's `sounds` / `music` / `haltEffectsAt` go to `audio` (`DeimosAudioSink.apply`) when
///   the pass begins (the original issues them inside the tick — at most one frame early, inaudible); a pass with
///   no cues sends nothing. **A level transition** (plan LT; `PassOutput.fadeToBlackAt`): the cues before the mark
///   (the music stop and `tran`, `10007200..10007224`) go when the pass begins; the rest — the next level's cues, or
///   at the campaign end the resume and the session end's halt and stop — only once the fade to black has presented
///   its last step (`1000722c..10007234` returns before `FUN_100064d0`), so `tran` plays through the fade. At that
///   point the keys typed during the fade are dropped (`FUN_100302e0`'s FlushEvents, `10030328`) and the session's
///   FPS window restarts at that tick (`10030314`, `DeimosSession.transitionFadeEnded`).
/// - **`.pauseWait(present)`** (H2; `FUN_10022ef0`, `10022f18..10023010`) — the pass that paused sent halt, `gaso 8`
///   and the music pause when it began; the wait yields until an `idle` sees `capsLock == false` (`10022f68..
///   10022fa4`), testing it only while the app is not suspended (`10022f84..10022fa0`: r29 = !`FUN_10023030`, the
///   suspended byte r2−0x6179); then the present (`10022fd4..10023004`, within the one-present-per-call bound). The
///   music resume after the wait (`10022fb4`) is the first music cue of the NEXT pass (`PauseScreen
///   .musicAfterWait`, C18a), which begins only after the wait — so it reaches the sink only after Caps Lock goes up,
///   and while Caps Lock stays down no pass begins, so the pause cannot re-fire. **Pause and session end in one
///   pass** (`PassOutput` holds one halt): the session puts `[… .pause, .resume, .stop]` with the pause's halt; the
///   driver sends the cues through `.pause` when the pass begins, the resume when the wait ends (`10022fb4`), and
///   the session end's halt + stop (`10005ad8`, `10005ae4`) — a second apply, halt index 0 — when the pass's ops are
///   done, before the front end's next pass. **Quit inside the wait** (Phase 4 S1b; grounding B §5 `10022f8c`, D S14;
///   X `10023214` / `10023374`, `10023228..10023244`): with the front end's quit flag b8 set, or the system's Quit
///   request (`ShellEvent.quitRequested`) queued or held by the front end (`FrontEnd.quitRequestPending`) — X's pump
///   inside the pause sets b8; ⌘Q / the menu-bar Quit (`.quitChosen`) is ignored in a game, S8a CR — the wait lets go at
///   once, suspended or not and before Caps Lock is tested, WITHOUT the music resume (`10022fb0` skips
///   `10022fb4`), and `FrontEnd.quitDuringPause` sets the flag and the frame controller's +2 (X `10030cb8`): the next
///   pass's begin frame reports quit and the game ends. A queued Quit that finds the app suspended runs the resume
///   handler first (`osx-build.md` D10: X `10023374`, resume if suspended, then the flag) — `resume()`: not
///   suspended any more, and no music resume, since the pause holds the music. The queued request is taken off the
///   queue there (the pause's pump consumed it), so the next pass does not hand it on to be held again. The present
///   and the pause flag's clear run as on a normal exit (`10022fc0..10023010`).
/// - **`.hostWait(wait)`** (Phase 4, plan S1a; `HostWait`) — held like a fade: t0 = `TickCount` of the `idle` that
///   reaches it; the op stream stays there, and no pass begins, until the wait is over — `.ticks(n)`: `TickCount ≥
///   t0 + n` (unsigned, wrapping); `.voiceEnd(id)`: `audio?.isPlaying(id)` false (`FUN_100476e0`; no sink = no mixer =
///   nothing sounds) — asked here, by the host, only to end the wait (standing rule 10); `.clickOrKey`: a mouseDown,
///   keyDown or autoKey event queued; `.answer`: a `ShellEvent.answer` queued; `.musicStopped(n)`:
///   `audio?.isMusicFading()` false (`FUN_100d05a8`; no sink = no music) or `TickCount > t0 + n` (unsigned, wrapping)
///   — asked, like the voice, only to end the wait. The waits present nothing.
/// - **Input queue** (Phase 4) — like `typed`, a pass's `keyEvents`, `mouseDowns` and `events` are everything handed
///   to `idle` since the previous pass began, in order: queued across every wait (limiter, fade, pause, host wait),
///   never dropped, except that the original's `FlushEvents` (a game end, the pause wait's begin, a transition fade's
///   end) empties the OS event queue — `typed`, `keyEvents`, `mouseDowns` — and keeps the shell's own `events`. The
///   held state (`held`, `capsLock`, `mouse`, `mouseButton`) is the `idle`'s in which the pass begins. A
///   `ShellEvent.suspend` / `.resume` only rides to the pass: the app still calls `suspend()` / `resume()`. The one
///   other drop: when a pause's wait lets go on a queued Quit while suspended, the resume it runs first (D10) ends
///   the suspension, so the suspend / resume events queued before it are dropped — a stale `.suspend` would set the
///   front end's flag again with the driver's clear, and the menu would never flash the Quit.
/// - **Suspend / resume** (H2; the app's suspend and resume handlers, `10023db4..10023dcc` and `10023e34..10023e8c`)
///   — `suspend()` pauses the music (`FUN_10048220(1)`) once; `resume()` resumes it (`FUN_10048220(0)`) unless the
///   pause flag r2−0x617b is set (`10023e7c`): set while a pause holds the music — here from the paused pass's
///   begin (where its music pause was sent) to the wait's present (`10022f18` / `10023010`). Across a suspend /
///   resume during the wait the music therefore stays paused.
/// - **Leaving the app pauses the game** (`osx-build.md` D11, the driver's part; Phase 4 S8a AW): while suspended, a
///   running game (a film too) begins no pass — the pass in hand runs out its ops (a pause's wait still lets go on a
///   Quit, D10, whose resume ends the hold), then the driver waits for `resume()`; the input handed meanwhile stays
///   queued for the first pass after it. Not built here: the pause screen D11 opens on the OS event (its effects
///   halt, Paused sound, picture and shown cursor) — the frame controller's paused-frame hook, in Core.
public struct DeimosDriver {
    /// The driver's one client: the screens, the games, the state they share.
    public private(set) var frontEnd: FrontEnd
    /// The game's audio (nil = silent: no engine, like `FUN_10047160`'s "Sound not available" path).
    public let audio: (any DeimosAudioSink)?
    public let rate: TickRate
    let renderer: DeimosRenderer
    /// Where the settings and Last Film go (do-nothing stores by default).
    let settingsStore: any SettingsStore
    let lastFilmStore: any LastFilmStore

    public var assets: DeimosAssets { frontEnd.state.assets }
    /// The live prefs (`FrontEndState.prefs`): `init`'s, then each ended game's.
    public var prefs: DeimosPrefs { frontEnd.state.prefs }
    /// The direct start's game (nil for the boot entry).
    public var start: SessionStart? { frontEnd.directStart }
    /// The current game's session (the last game's once it has ended, until the next replaces it) — forwarded from
    /// the front end (standing rule 7); internal, so settable from tests (`@testable import`) to poke its game state
    /// (plan LT). Valid once a game has been built (the direct start builds one in `init`).
    var session: DeimosSession {
        get {
            guard let session = frontEnd.session else { preconditionFailure("DeimosDriver.session: no game yet") }
            return session
        }
        set { frontEnd.session = newValue }
    }

    /// The frame controller's limiter stamp (+0x1c): `TickCount` at the last limiter release.
    private(set) var lastPresent: UInt32 = 0
    /// Passes begun, `.present` ops run and game ends handled — over the driver's life (inspection).
    private(set) var passCount = 0
    private(set) var presentCount = 0
    /// Every game end, including the last one before a quit (the game that ends with the quit flag set is counted,
    /// though no new game follows it).
    private(set) var restarts = 0
    /// Tests (G12): set to record a row per ticked pass of a game (nil = off).
    var trace: ReplayTrace?

    /// `FPS_Delay` (PermFloat 33, `fctiwz`, `10030cf8..10030d00`).
    private let fpsDelay: UInt32
    /// `FrontEndState.gamesStarted` as last seen (a change = a new game, a fresh frame controller).
    private var gamesSeen = 0

    /// The current pass's ops and the next one to run.
    private var ops: [RenderOp] = []
    private var next = 0
    /// A pass is in progress (its ops may be all done).
    private var passBegun = false
    /// The current pass carried `sessionEnded`.
    private var endAfterPass = false
    /// The Esc that ended the last game is still held (the latch, see the type's comment).
    private var escLatched = false
    /// Per-`idle` bounds (see the type's comment).
    private var releasedThisCall = false
    private var presentedThisCall = false
    private var restartedThisCall = false
    /// The current pass contained a limiter (with byte pref 10 off nothing paces the loop; the driver then yields
    /// after every pass so `idle` returns).
    private var passLimited = false
    /// A fade in progress: its kind, present, the next level index and t0.
    private struct Fade {
        var kind: FadeKind
        var present: PresentKind
        var step: Int
        var t0: UInt32
    }
    private var fade: Fade?
    /// Key-downs handed to `idle` since the last pass began (the OS event queue).
    private(set) var typedQueue: [UInt8] = []
    /// The other events handed to `idle` since the last pass began (Phase 4): keyDown / autoKey events, mouse-downs
    /// (the OS event queue, with `typedQueue`) and the shell's own events.
    private(set) var keyEventQueue: [KeyEvent] = []
    private(set) var mouseDownQueue: [MousePoint] = []
    private(set) var shellEventQueue: [ShellEvent] = []
    /// The host wait in progress and the tick at which it was reached.
    private var hostWaiting: (wait: HostWait, t0: UInt32)?
    /// The keys the last pass began with, as sampled and with the queued events (inspection).
    private(set) var lastPassKeys = HeldKeys()
    /// The app is suspended (r2−0x6179, set by the suspend handler `10023dc4`, cleared by the resume `10023e34`).
    public private(set) var suspended = false
    /// `shutdown()` has run (the settings were handed to the store at quit) — the app's last-chance save checks it.
    public private(set) var settingsSaved = false
    /// The pause flag r2−0x617b: a pause holds the music (from the paused pass's begin to the wait's present).
    private var pauseHoldsMusic = false
    /// The current pass's `.pauseWait` has been reached (its FlushEvents ran) / has seen Caps Lock up.
    private var waitEntered = false
    private var waitReleased = false
    /// A pass that paused and ended the session: the music after the wait (the resume, `10022fb4`) and the session
    /// end's music (the stop, `10005ae4`, sent with a halt, `10005ad8`) once the pass's ops are done.
    private var musicAfterWait: [MusicCue] = []
    private var sessionEndMusic: [MusicCue]?
    /// The current pass's cues after its transition fade to black (`PassOutput.fadeToBlackAt`), sent when the fade
    /// ends; `pauses` = they carry the pass's music pause (the pause flag is set as they are sent).
    private var cuesAfterFade: (sounds: [SoundCue], music: [MusicCue], halt: Int?, pauses: Bool)?

    /// Drives `frontEnd` (its boot entry or its direct start).
    public init(frontEnd: FrontEnd, rate: TickRate = .classic, audio: (any DeimosAudioSink)? = nil,
                settingsStore: any SettingsStore = NoSettingsStore(),
                lastFilmStore: any LastFilmStore = NoLastFilmStore()) {
        self.frontEnd = frontEnd
        self.audio = audio
        self.rate = rate
        self.settingsStore = settingsStore
        self.lastFilmStore = lastFilmStore
        renderer = DeimosRenderer(assets: frontEnd.state.assets)
        fpsDelay = UInt32(frontEnd.state.assets.floats[33].rounded(.towardZero))
    }

    /// The front end's direct start at `start` (ruling 10) — validated here; the first game is built at the first
    /// `idle` with its clock.
    public init(assets: DeimosAssets, prefs: DeimosPrefs, rate: TickRate = .classic, start: SessionStart,
                audio: (any DeimosAudioSink)? = nil, settingsStore: any SettingsStore = NoSettingsStore(),
                lastFilmStore: any LastFilmStore = NoLastFilmStore()) throws {
        self.init(frontEnd: try FrontEnd(direct: start, assets: assets, prefs: prefs, soundAvailable: audio != nil),
                  rate: rate, audio: audio, settingsStore: settingsStore, lastFilmStore: lastFilmStore)
    }

    /// The app is quitting (`FUN_10000630` → `FUN_100045f0`): the live prefs — the running game's, if one runs — go to
    /// the settings store (a failure to write is the store's to report; the prefs are returned regardless).
    @discardableResult
    public mutating func shutdown() -> DeimosPrefs {
        let prefs = frontEnd.livePrefs
        try? settingsStore.save(prefs)
        settingsSaved = true
        return prefs
    }

    /// The app's suspend handler (`10023db4..10023dcc`): once per suspension, suspended = 1 and the music pause
    /// (`FUN_10048220(1)`). [Its window and cursor calls are the app's.] The original has one suspended byte: the
    /// front end's shared state (`FrontEndState.suspended`) is kept in step with the driver's here and in `resume()`,
    /// so the screens can trust it whichever way the suspension arrives (the call, its shell event, or the resume
    /// a Quit runs inside the pause's wait). The original's one byte: a shared flag already set while the driver's is
    /// clear is a suspension the front end ran itself (the menu's erase question, `FUN_10023da0` before the alert) —
    /// the byte is set, so the handler does nothing (`10023db4..10023dbc`), and the music it paused stays paused.
    public mutating func suspend() {
        if frontEnd.state.suspended && !suspended { return }                         // 10023db4..10023dbc: b7 set
        frontEnd.state.suspended = true                                              // the one flag, shared
        guard !suspended else { return }                                             // 10023db4..10023dbc
        suspended = true                                                             // 10023dc0..10023dc4
        audio?.apply(sounds: [], music: [.pause], haltEffectsAt: nil)                // 10023dc8..10023dcc
    }

    /// The app's resume handler (`10023e10`): suspended = 0 (`10023e34`); the music resume (`FUN_10048220(0)`) unless
    /// a pause holds the music (r2−0x617b, `10023e7c..10023e8c`). A resume with the driver's own flag clear does
    /// nothing — not even the shared flag, which a suspension the front end ran itself still holds (`suspend()`).
    public mutating func resume() {
        guard suspended else { return }
        frontEnd.state.suspended = false                                             // the one flag, shared
        suspended = false                                                            // 10023e34
        if !pauseHoldsMusic {                                                        // 10023e7c..10023e84
            audio?.apply(sounds: [], music: [.resume], haltEffectsAt: nil)           // 10023e88..10023e8c
        }
    }

    /// A running game is held between passes while the app is suspended (D11; see the type's comment).
    public var gameHeldWhileSuspended: Bool { suspended && frontEnd.state.gameRunning }

    /// The 640×480 window content.
    public var screen: Pixmap555 { renderer.screen }

    /// A fade is between steps.
    var isFading: Bool { fade != nil }

    /// Run ops until one must wait for the clock (`seconds` = the host's monotonic clock), then return.
    public mutating func idle(seconds: Double, keys: HeldKeys) -> DriverOutput {
        let now = MacTicks.ticks(seconds: seconds, rate: rate.perSecond)
        var out = DriverOutput()
        releasedThisCall = false
        presentedThisCall = false
        restartedThisCall = false
        typedQueue += keys.typed
        keyEventQueue += keys.keyEvents
        mouseDownQueue += keys.mouseDowns
        shellEventQueue += keys.events
        if escLatched && !keys.held.contains(DeimosDriver.escKey) { escLatched = false }   // any idle releases it
        while true {
            // A fade between steps: wait for t0 + 1, then the next step (or the end).
            if var f = fade {
                guard now >= f.t0 &+ 1 else { return out }
                f.t0 = now
                if f.step < levels(f.kind).count {
                    fadeStep(&f, &out)
                    fade = f
                    return out
                }
                renderer.fadeEnd()
                fade = nil
                if f.kind == .toBlack, cuesAfterFade != nil {
                    flushOSEvents()                                                   // 10030328 FlushEvents
                    frontEnd.transitionFadeEnded(ticks: now)                          // 10030314 FUN_100305e0
                    sendCuesAfterFade()
                }
            }

            if next == ops.count {
                // The pass's ops are done.
                assert(cuesAfterFade == nil,
                       "a pass with fadeToBlackAt carries its .fade(.toBlack) op, whose end sent these cues")
                if passBegun {
                    if endAfterPass {
                        guard !restartedThisCall else { return out }
                        restartedThisCall = true
                        restarts += 1
                        if let music = sessionEndMusic {                       // 10005ad8 halt, 10005ae4 stop
                            audio?.apply(sounds: [], music: music, haltEffectsAt: 0)
                        }
                        gameEnded()
                        escLatched = true   // a press in the ended pass's tail too: Esc is read only at begin (10005904)
                    } else if !passLimited {
                        passBegun = false
                        return out
                    }
                    passBegun = false
                }
                if gameHeldWhileSuspended { return out }                      // D11: the game waits for the resume
                beginPass(keys: keys, ticks: now, &out)
                continue
            }

            let op = ops[next]
            switch op {
            case .limit:
                guard !releasedThisCall, now >= lastPresent &+ fpsDelay else { return out }   // 10030d14..10030d24
                releasedThisCall = true
                lastPresent = now                                                            // 10030d28..10030d30
            case let .fade(kind, present):
                next += 1
                renderer.fadeBegin(kind)
                var f = Fade(kind: kind, present: present, step: 0, t0: now)
                fadeStep(&f, &out)
                fade = f
                return out
            case .present:
                guard !presentedThisCall else { return out }
                presentedThisCall = true
                renderer.apply(op)
                presentCount += 1
                out.screenChanged = true
            case .screenBlit:
                renderer.apply(op)
                out.screenChanged = true
            case let .pauseWait(present):
                if !waitEntered {
                    waitEntered = true
                    flushOSEvents()                                           // 10022f1c FlushEvents
                }
                if !waitReleased {
                    let quitQueued = frontEnd.quitRequestPending || shellEventQueue.contains(where: Self.isQuit)
                    if frontEnd.state.quit || quitQueued {                    // 10022f8c b8; X 10023214
                        if quitQueued && suspended {                          // D10: X 10023374 resumes first —
                            resume()                                          // so every suspend / resume queued
                            shellEventQueue.removeAll(where: Self.isSuspension)   // before it is over: dropped
                        }
                        shellEventQueue.removeAll(where: Self.isQuit)         // the pause's pump took it
                        waitReleased = true
                        musicAfterWait = []                                   // 10022fb0: no resume (10022fb4)
                        frontEnd.quitDuringPause()                            // b8; X 10030cb8 the controller's +2
                    } else {
                        guard !suspended, !keys.capsLock else { return out }  // 10022f68..10022fa4
                        waitReleased = true
                        if !musicAfterWait.isEmpty {                          // 10022fb4 (pause + session end)
                            audio?.apply(sounds: [], music: musicAfterWait, haltEffectsAt: nil)
                            musicAfterWait = []
                        }
                    }
                }
                guard !presentedThisCall else { return out }
                presentedThisCall = true
                renderer.apply(.present(present))                             // 10022fd4..10023004
                presentCount += 1
                out.screenChanged = true
                waitEntered = false
                waitReleased = false
                pauseHoldsMusic = false                                       // 10023010
            case let .hostWait(wait):
                let t0: UInt32
                if let held = hostWaiting {
                    t0 = held.t0
                } else {
                    t0 = now                                                  // the tick the wait is reached
                    hostWaiting = (wait, now)
                }
                guard hostWaitOver(wait, t0: t0, now: now) else { return out }
                hostWaiting = nil
            default:
                renderer.apply(op)
            }
            next += 1
        }
    }

    /// Begin a pass: sample `keys` (a latched Esc reads as up) with the queued input, run the front end's pass at
    /// `ticks`, note a new game, route its cues, save a Last Film it hands out, take its ops. An empty `sessionEnded`
    /// output (a game that could not be built) is a finished pass with no ops: the loop ends it again, within the
    /// per-call bound, and the front end tries again on its next pass. Such a pass is not counted in `passCount`,
    /// but its requests and cues are passed on like any pass's (none carries any today; a later screen may).
    private mutating func beginPass(keys: HeldKeys, ticks: UInt32, _ out: inout DriverOutput) {
        var sampled = keys
        if escLatched {
            if sampled.held.contains(DeimosDriver.escKey) {
                sampled.held.remove(DeimosDriver.escKey)
            } else {
                escLatched = false
            }
        }
        sampled.typed = typedQueue
        sampled.keyEvents = keyEventQueue
        sampled.mouseDowns = mouseDownQueue
        sampled.events = shellEventQueue
        typedQueue = []
        keyEventQueue = []
        mouseDownQueue = []
        shellEventQueue = []
        lastPassKeys = sampled
        let pass = frontEnd.pass(keys: sampled, ticks: ticks)
        if suspended && !frontEnd.state.suspended {                   // the front end ran the resume (the menu's Quit
            suspended = false                                         // while suspended, code 8): one byte, so the
        }                                                             // driver's own flag follows it
        if frontEnd.state.gamesStarted != gamesSeen {                 // a new game: a fresh frame controller
            gamesSeen = frontEnd.state.gamesStarted
            lastPresent = 0                                           // FUN_10030190 zeroes +0x1c
            releasedThisCall = false
        }
        for case let .saveLastFilm(film) in pass.requests {
            try? lastFilmStore.save(film)
        }
        if pass.requests.contains(.quit) { shutdown() }               // FUN_10000630 → FUN_100045f0
        passBegun = true
        sessionEndMusic = nil
        out.requests += pass.requests
        if pass.sessionEnded && pass.ops.isEmpty {
            ops = []
            next = 0
            endAfterPass = true
            passLimited = false
            route(pass)                                               // its requests (above) and cues still go on
            return
        }
        passCount += 1
        if pass.ticked, trace != nil, let game = frontEnd.session { trace?.record(game) }
        ops = pass.ops
        next = 0
        endAfterPass = pass.sessionEnded
        passLimited = ops.contains(.limit)
        route(pass)
    }

    /// The pass's cues to `audio` as it begins. A transition pass (`fadeToBlackAt`) sends only the cues before its
    /// fade now and keeps the rest for the fade's end (`cuesAfterFade`); the pause handling below applies to that
    /// rest. A pass that paused (its last op `.pauseWait`) sets the pause flag; if it also ended the session, its
    /// music is split at its last `.pause` (see the type's comment): through the pause now, the resume after the wait,
    /// the stop (with a halt) at the end of the pass.
    private mutating func route(_ pass: PassOutput) {
        var sounds = pass.sounds
        var music = pass.music
        var halt = pass.haltEffectsAt
        if let mark = pass.fadeToBlackAt {                                   // 1000722c..10007234
            let ks = min(max(mark.sounds, 0), sounds.count), km = min(max(mark.music, 0), music.count)
            assert(halt.map { $0 >= ks } ?? true,
                   "halts come only from the pause and the session end, both after the tick's fade mark")
            send(sounds: Array(sounds[..<ks]), music: Array(music[..<km]), halt: nil)
            sounds = Array(sounds[ks...])
            music = Array(music[km...])
            halt = halt.map { $0 - ks }
        }
        let paused = pass.ops.contains { if case .pauseWait = $0 { return true } else { return false } }
        if paused {
            if pass.fadeToBlackAt == nil {
                pauseHoldsMusic = true                                       // 10022f18 (the pause's music pause is sent now)
            }
            if pass.sessionEnded, let k = music.lastIndex(of: .pause) {
                var after = Array(music[(k + 1)...])
                music.removeSubrange((k + 1)...)
                if after.last == .stop {                                     // not a film (10005ad0): halt + stop
                    after.removeLast()
                    sessionEndMusic = [.stop]
                }
                musicAfterWait = after
            }
        }
        if pass.fadeToBlackAt != nil {
            cuesAfterFade = (sounds, music, halt, paused)
        } else {
            send(sounds: sounds, music: music, halt: halt)
        }
    }

    /// One apply, unless there is nothing to send.
    private func send(sounds: [SoundCue], music: [MusicCue], halt: Int?) {
        guard !(sounds.isEmpty && music.isEmpty && halt == nil) else { return }
        audio?.apply(sounds: sounds, music: music, haltEffectsAt: halt)
    }

    /// The transition pass's cues after its fade (see `route`).
    private mutating func sendCuesAfterFade() {
        guard let c = cuesAfterFade else { return }
        cuesAfterFade = nil
        if c.pauses { pauseHoldsMusic = true }                               // 10022f18, after the fade
        send(sounds: c.sounds, music: c.music, halt: c.halt)
    }

    /// One fade step at the current level, then advance the level index.
    private mutating func fadeStep(_ f: inout Fade, _ out: inout DriverOutput) {
        renderer.fadeStep(f.kind, a: levels(f.kind)[f.step], present: f.present)
        f.step += 1
        out.screenChanged = true
    }

    private func levels(_ kind: FadeKind) -> [Int] {
        kind == .fromBlack ? DisplayBuffers.fromBlackLevels : DisplayBuffers.toBlackLevels
    }

    /// A game has ended and its last pass's ops are done: the end-of-session FlushEvents (`FUN_100302b0`,
    /// `10005af0`) and the pass state cleared, before the front end's next pass.
    private mutating func gameEnded() {
        ops = []
        next = 0
        passBegun = false
        endAfterPass = false
        passLimited = false
        fade = nil
        flushOSEvents()                                                       // FUN_100302b0 FlushEvents
        hostWaiting = nil
        pauseHoldsMusic = false
        waitEntered = false
        waitReleased = false
        musicAfterWait = []
        sessionEndMusic = nil
        cuesAfterFade = nil
    }

    /// Tests (`@testable`): splice `inserted` into the current pass at the next op to run — the driver runs them as
    /// the pass's own (no screen emits a host wait before the screens land).
    mutating func insertOps(_ inserted: [RenderOp]) {
        ops.insert(contentsOf: inserted, at: next)
    }

    /// The host wait in progress (inspection).
    var waitingOn: HostWait? { hostWaiting?.wait }

    /// Whether `wait`, reached at `t0`, is over at `now` (`HostWait`): the tick count (unsigned, the sum wrapping, as
    /// the fades); the voice no longer sounding (`FUN_100476e0`; no sink = no mixer = silent); a mouseDown, keyDown or
    /// autoKey event queued; an answer queued; the music's fade over or the bound passed. The input stays queued for
    /// the next pass.
    private func hostWaitOver(_ wait: HostWait, t0: UInt32, now: UInt32) -> Bool {
        switch wait {
        case let .ticks(n):
            return now >= t0 &+ n
        case let .voiceEnd(id):
            return !(audio?.isPlaying(id) ?? false)
        case .clickOrKey:
            return !typedQueue.isEmpty || !keyEventQueue.isEmpty || !mouseDownQueue.isEmpty
        case .answer:
            return shellEventQueue.contains { if case .answer = $0 { return true } else { return false } }
        case let .musicStopped(maxTicks):
            // 100481a0..100481ac FUN_100d05a8, then 10048178..10048184 TickCount > t0 + n (cmplw; ble).
            return !(audio?.isMusicFading() ?? false) || now > t0 &+ maxTicks
        }
    }

    /// `FlushEvents(everyEvent, 0)`: the OS event queue — keyDown, autoKey, mouseDown. The shell's own events
    /// (menu commands, the Quit request, suspend / resume, answers) are not OS-queue events and are kept.
    private mutating func flushOSEvents() {
        typedQueue = []
        keyEventQueue = []
        mouseDownQueue = []
    }

    /// A Quit from the shell (File ▸ Quit, the system's Quit request).
    /// The Quit that lets the pause's wait go: the system's request only — ⌘Q / the menu-bar Quit is ignored in a game
    /// (Phase 4 S8a CR; `FrontEnd.shellEvents`).
    private static func isQuit(_ event: ShellEvent) -> Bool { event == .quitRequested }

    /// The app's suspend / resume events (`ShellEvent.suspend` / `.resume`).
    private static func isSuspension(_ event: ShellEvent) -> Bool { event == .suspend || event == .resume }

    /// Mac virtual key code of Esc (`FUN_100307c0`).
    static let escKey: UInt16 = 0x35
}
