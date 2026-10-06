import Foundation
import DeimosCore
import DeimosRender

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
///   `TickCount ≥ lastPresent + FPS_Delay` (PermFloat 33 = 2; `add`, then `cmplw` — unsigned, wrapping), then
///   `lastPresent = TickCount` (a second read, `10030d28..10030d30`). The stamp lives in the frame controller (+0x1c),
///   zeroed at session start (`FUN_10030190`). The session emits the op only when byte pref 10 is set.
/// - **`.fade(kind, present)`** — the blocking fades (`FUN_1000ba70` / `FUN_1000b9a0`): `fadeBegin`; `t0 = TickCount`
///   (`1000bac4`); for each level: `fadeStep` (the step's present), then wait until `TickCount ≥ t0 + 1` (unsigned,
///   `1000bb50..1000bb64`), `t0 = TickCount` (`1000bb68..1000bb78`); then `fadeEnd`.
/// - **No catch-up** (timing-frame §4): the waits are the only pacing and both are "≥ a target", so a stall lets
///   exactly one late pass through; the next target is measured from its stamp.
/// - **Esc** — the pass that sees it still runs to its end and carries `sessionEnded`; then ◇ a new session at
///   sector 1 with seed = the current `TickCount` (the original's `srand(TickCount())`, `100057c8`) — the Phase-1
///   stand-in for the return to the main menu. The renderer's buffers persist across it.
public struct DeimosDriver {
    public let assets: DeimosAssets
    public let prefs: DeimosPrefs
    public let rate: TickRate
    public let start: SessionStart
    let renderer: DeimosRenderer
    private(set) var session: DeimosSession

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
    /// The current pass carried `sessionEnded`.
    private var endAfterPass = false
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

    /// Builds the first session (seed 0 until the first `idle` reseeds it with the clock — the session's set-up
    /// validates `start` here).
    public init(assets: DeimosAssets, prefs: DeimosPrefs, rate: TickRate = .classic, start: SessionStart) throws {
        self.assets = assets
        self.prefs = prefs
        self.rate = rate
        self.start = start
        renderer = DeimosRenderer(assets: assets)
        session = try DeimosSession(assets: assets, prefs: prefs, start: start, seed: 0)
        fpsDelay = UInt32(assets.floats[33].rounded(.towardZero))
    }

    /// The 640×480 window content.
    public var screen: Pixmap555 { renderer.screen }

    /// A fade is between steps.
    var isFading: Bool { fade != nil }

    /// Run ops until one must wait for the clock (`seconds` = the host's monotonic clock), then return.
    public mutating func idle(seconds: Double, keys: HeldKeys) -> DriverOutput {
        let now = MacTicks.ticks(seconds: seconds, rate: rate.perSecond)
        var out = DriverOutput()
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
            }

            if next == ops.count {
                // The pass's ops are done.
                if !ops.isEmpty {
                    ops = []
                    next = 0
                    if endAfterPass {
                        restarts += 1
                        newSession(seed: now, sector: 1)
                    } else if !passLimited {
                        return out
                    }
                }
                beginPass(keys: keys, now: now, &out)
                continue
            }

            let op = ops[next]
            switch op {
            case .limit:
                guard now >= lastPresent &+ fpsDelay else { return out }
                lastPresent = now
            case let .fade(kind, present):
                next += 1
                renderer.fadeBegin(kind)
                var f = Fade(kind: kind, present: present, step: 0, t0: now)
                fadeStep(&f, &out)
                fade = f
                return out
            case .present:
                renderer.apply(op)
                presentCount += 1
                out.screenChanged = true
            case .screenBlit:
                renderer.apply(op)
                out.screenChanged = true
            default:
                renderer.apply(op)
            }
            next += 1
        }
    }

    /// Begin a pass: sample `keys`, take its ops. A session that has already ended (an empty `sessionEnded`
    /// output) restarts at once.
    private mutating func beginPass(keys: HeldKeys, now: UInt32, _ out: inout DriverOutput) {
        var pass = session.pass(keys: keys)
        if pass.sessionEnded && pass.ops.isEmpty {
            restarts += 1
            newSession(seed: now, sector: 1)
            pass = session.pass(keys: keys)
        }
        passCount += 1
        out.requests += pass.requests
        ops = pass.ops
        next = 0
        endAfterPass = pass.sessionEnded
        passLimited = ops.contains(.limit)
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

    /// A fresh session (`srand(seed)`) with a fresh frame controller (limiter stamp 0).
    private mutating func newSession(seed: UInt32, sector: Int) {
        let s = SessionStart(sector: sector, players: start.players, film: start.film)
        do {
            session = try DeimosSession(assets: assets, prefs: prefs, start: s, seed: seed)
        } catch {
            preconditionFailure("DeimosDriver: session at sector \(sector) failed: \(error)")
        }
        lastPresent = 0
        ops = []
        next = 0
        endAfterPass = false
        fade = nil
    }
}
