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

/// Runs `DeimosSession` passes on a `DeimosRenderer` against the host's clock (plan H1). The original runs its game
/// loop flat out and busy-waits on `TickCount` in two places; the replica turns each wait into a yield, so the driver
/// is a resumable state machine — no threads, no sleeping. The app calls `idle` often (every 1/240 s); each call runs
/// ops until one must wait and returns.
///
/// - **Passes.** A pass (`DeimosSession.pass`) begins only after the previous pass's ops have all run; its keys are
///   the ones handed to the `idle` call in which it begins (the begin-frame input read, `1003052c..10030544`).
/// - **`.limit`** — the FPS limiter (`FUN_10030bc0` `10030ce4..10030d30`, timing-frame §2.3): continue only when
///   `TickCount ≥ lastPresent + FPS_Delay` (PermFloat 33 = 2; `lwz +0x1c; add` at `10030d08..10030d14`, then
///   `cmplw; blt` at `10030d20..10030d24` — unsigned, the sum wrapping), then `lastPresent = TickCount` (a second read,
///   `10030d28..10030d30`). The stamp lives in the frame controller (+0x1c), zeroed at session start
///   (`FUN_10030190`). The session emits the op only when byte pref 10 is set. The wrap is replicated: with the stamp
///   at 0xFFFFFFFE / 0xFFFFFFFF the target wraps to 0 / 1 and the wait never blocks until the tick count wraps too
///   (the original runs flat out for those ≤ 2 ticks).
/// - **Bounded work per `idle`** — at most one limiter release per session, at most one present and at most one
///   restart per call; at any of those bounds the call returns and the next call resumes. In steady play the
///   limiter alone is the yield (one release, one present per call), so the bounds bind only where the original
///   would not have waited: the tick wrap above, and a restart whose new session would quit at once.
/// - **`.fade(kind, present)`** — the blocking fades (`FUN_1000ba70` / `FUN_1000b9a0`): `fadeBegin`; `t0 = TickCount`
///   (`1000bac4`); for each level: `fadeStep` (the step's present), then wait until `TickCount ≥ t0 + 1` (unsigned,
///   `1000bb50..1000bb64`), `t0 = TickCount` (`1000bb68..1000bb78`); then `fadeEnd`.
/// - **No catch-up** (timing-frame §4): the waits are the only pacing and both are "≥ a target", so a stall lets
///   exactly one late pass through; the next target is measured from its stamp.
/// - **Session end** — ◇ stand-ins 2–3: Esc, game over, a film's level complete and (plan LT) the campaign end after
///   the last sector end the session (the pass that ends it still runs to its end and carries `sessionEnded`; a
///   level transition to the next sector does not); then a new session at sector 1 with seed = the current
///   `TickCount` (the original's `srand(TickCount())`, `100057c8`) — the stand-in for the return to the main menu
///   (Phase 4). ◇ Stand-in 6: the new session starts from the ENDED session's prefs (F6, the FPS monitor,
///   `supermunki`, the volume — in memory only), which `prefs` then holds. The renderer's buffers persist across
///   it. ◇ The Esc that ended the session is latched: the new session's passes see Esc as up until ANY `idle` call
///   sees it released (the original's end-of-session `FlushEvents` and the main menu, which has no Esc action —
///   front-end.md §2 — mean a new game needs a fresh press). A restart that cannot build sector 1 falls back to
///   `start` (validated by `init`).
/// - **Cursor** — the session's first pass carries `.hideCursor` (see `DeimosSession.pass`); `requests` passes it on.
/// - **Keys** (H2) — a pass's `typed` characters are every key-down handed to `idle` since the previous pass began
///   (the OS event queue `GetOSEvent` drains), in order; a restart flushes them (`FUN_10030210` FlushEvents), and so
///   does the pause screen as its wait begins (`10022f1c`). The pass gets `ticks` = the `TickCount` of the `idle`
///   in which it begins (the FPS monitor's clock), and so does a new session's controller (`FUN_100305e0`).
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
///   done, before the restart.
/// - **Suspend / resume** (H2; the app's suspend and resume handlers, `10023db4..10023dcc` and `10023e34..10023e8c`)
///   — `suspend()` pauses the music (`FUN_10048220(1)`) once; `resume()` resumes it (`FUN_10048220(0)`) unless the
///   pause flag r2−0x617b is set (`10023e7c`): set while a pause holds the music — here from the paused pass's
///   begin (where its music pause was sent) to the wait's present (`10022f18` / `10023010`). Across a suspend /
///   resume during the wait the music therefore stays paused.
public struct DeimosDriver {
    public let assets: DeimosAssets
    /// The prefs the current session started from: `init`'s, then — after a ◇ restart — the ended session's
    /// (stand-in 6).
    public private(set) var prefs: DeimosPrefs
    /// The game's audio (nil = silent: no engine, like `FUN_10047160`'s "Sound not available" path).
    public let audio: (any DeimosAudioSink)?
    public let rate: TickRate
    public let start: SessionStart
    let renderer: DeimosRenderer
    /// The current session — internal, so settable from tests (`@testable import`) to poke its game state (plan LT;
    /// `internal(set)` on an internal property is redundant and warns).
    var session: DeimosSession

    /// The frame controller's limiter stamp (+0x1c): `TickCount` at the last limiter release.
    private(set) var lastPresent: UInt32 = 0
    /// Passes begun, `.present` ops run and Esc restarts — over the driver's life (inspection).
    private(set) var passCount = 0
    private(set) var presentCount = 0
    private(set) var restarts = 0

    /// `FPS_Delay` (PermFloat 33, `fctiwz`, `10030cf8..10030d00`).
    private let fpsDelay: UInt32
    /// The first session is seeded at the first `idle` (the clock is unknown before it).
    private var seeded = false

    /// The current pass's ops and the next one to run.
    private var ops: [RenderOp] = []
    private var next = 0
    /// A pass is in progress (its ops may be all done).
    private var passBegun = false
    /// The current pass carried `sessionEnded`.
    private var endAfterPass = false
    /// The Esc that ended the last session is still held (◇ latch, see the type's comment).
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
    /// The app is suspended (r2−0x6179, set by the suspend handler `10023dc4`, cleared by the resume `10023e34`).
    public private(set) var suspended = false
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

    /// Builds the first session (seed 0 until the first `idle` reseeds it with the clock — the session's set-up
    /// validates `start` here).
    public init(assets: DeimosAssets, prefs: DeimosPrefs, rate: TickRate = .classic, start: SessionStart,
                audio: (any DeimosAudioSink)? = nil) throws {
        self.audio = audio
        self.assets = assets
        self.prefs = prefs
        self.rate = rate
        self.start = start
        renderer = DeimosRenderer(assets: assets)
        session = try DeimosSession(assets: assets, prefs: prefs, start: start, seed: 0)
        fpsDelay = UInt32(assets.floats[33].rounded(.towardZero))
    }

    /// The app's suspend handler (`10023db4..10023dcc`): once per suspension, suspended = 1 and the music pause
    /// (`FUN_10048220(1)`). [Its window and cursor calls are the app's.]
    public mutating func suspend() {
        guard !suspended else { return }                                             // 10023db4..10023dbc
        suspended = true                                                             // 10023dc0..10023dc4
        audio?.apply(sounds: [], music: [.pause], haltEffectsAt: nil)                // 10023dc8..10023dcc
    }

    /// The app's resume handler (`10023e10`): suspended = 0 (`10023e34`); the music resume (`FUN_10048220(0)`) unless
    /// a pause holds the music (r2−0x617b, `10023e7c..10023e8c`).
    public mutating func resume() {
        guard suspended else { return }
        suspended = false                                                            // 10023e34
        if !pauseHoldsMusic {                                                        // 10023e7c..10023e84
            audio?.apply(sounds: [], music: [.resume], haltEffectsAt: nil)           // 10023e88..10023e8c
        }
    }

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
        if escLatched && !keys.held.contains(DeimosDriver.escKey) { escLatched = false }   // ◇ any idle releases it
        if !seeded {
            seeded = true
            newSession(seed: now, sector: start.sector)
        }
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
                    typedQueue = []                                                   // 10030328 FlushEvents
                    session.transitionFadeEnded(ticks: now)                           // 10030314 FUN_100305e0
                    sendCuesAfterFade()
                }
            }

            if next == ops.count {
                // The pass's ops are done.
                if cuesAfterFade != nil { sendCuesAfterFade() }                      // (a mark without its fade)
                if passBegun {
                    if endAfterPass {
                        guard !restartedThisCall else { return out }
                        restartedThisCall = true
                        restarts += 1
                        if let music = sessionEndMusic {                       // 10005ad8 halt, 10005ae4 stop
                            audio?.apply(sounds: [], music: music, haltEffectsAt: 0)
                        }
                        prefs = session.prefs                                  // ◇ stand-in 6
                        newSession(seed: now, sector: 1)
                        escLatched = true   // a press in the ended pass's tail too: Esc is read only at begin (10005904)
                    } else if !passLimited {
                        passBegun = false
                        return out
                    }
                    passBegun = false
                }
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
                    typedQueue = []                                           // 10022f1c FlushEvents
                }
                if !waitReleased {
                    guard !suspended, !keys.capsLock else { return out }      // 10022f68..10022fa4
                    waitReleased = true
                    if !musicAfterWait.isEmpty {                              // 10022fb4 (pause + session end)
                        audio?.apply(sounds: [], music: musicAfterWait, haltEffectsAt: nil)
                        musicAfterWait = []
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
            default:
                renderer.apply(op)
            }
            next += 1
        }
    }

    /// Begin a pass: sample `keys` (a latched Esc reads as up) with the queued typed characters, run it at
    /// `ticks`, route its cues, take its ops. A session that has already ended (an empty `sessionEnded` output) is a
    /// finished pass with no ops: the loop restarts it, within the per-call bound.
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
        typedQueue = []
        let pass = session.pass(keys: sampled, ticks: ticks)
        passBegun = true
        sessionEndMusic = nil
        if pass.sessionEnded && pass.ops.isEmpty {
            ops = []
            next = 0
            endAfterPass = true
            passLimited = false
            return
        }
        passCount += 1
        out.requests += pass.requests
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
            send(sounds: Array(sounds[..<ks]), music: Array(music[..<km]), halt: halt.flatMap { $0 < ks ? $0 : nil })
            sounds = Array(sounds[ks...])
            music = Array(music[km...])
            halt = halt.flatMap { $0 >= ks ? $0 - ks : nil }
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

    /// A fresh session (`srand(seed)`) with a fresh frame controller (limiter stamp 0). When `sector` cannot be
    /// built (data without that level), the session falls back to `start`, which `init` validated.
    private mutating func newSession(seed: UInt32, sector: Int) {
        let s = SessionStart(sector: sector, players: start.players, film: start.film)
        if let made = try? DeimosSession(assets: assets, prefs: prefs, start: s, seed: seed, ticks: seed) {
            session = made
        } else if let made = try? DeimosSession(assets: assets, prefs: prefs, start: start, seed: seed, ticks: seed) {
            session = made
        }
        lastPresent = 0
        ops = []
        next = 0
        passBegun = false
        endAfterPass = false
        passLimited = false
        fade = nil
        releasedThisCall = false
        typedQueue = []                                                       // FUN_10030210 FlushEvents
        pauseHoldsMusic = false
        waitEntered = false
        waitReleased = false
        musicAfterWait = []
        sessionEndMusic = nil
        cuesAfterFade = nil
    }

    /// Mac virtual key code of Esc (`FUN_100307c0`).
    static let escKey: UInt16 = 0x35
}
