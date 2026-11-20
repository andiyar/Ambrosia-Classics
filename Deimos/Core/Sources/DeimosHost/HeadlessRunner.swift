import Foundation
import DeimosCore
import DeimosRender

/// What a headless run ended with (plan H2; the replay gate G4 reads it).
public struct ReplayResult: Equatable, Sendable {
    public enum EndReason: Equatable, Sendable {
        /// `FUN_10009750`: P1's film cursor passed the recording (`10005a38..10005a48`).
        case filmEnd
        /// `FUN_10007170` in a film: the level was completed (`100071e8..100071f8` — a film holds one level).
        case levelComplete
        /// No player in game: running cleared at `gameOverStart + 111` (`10006d68..10006d98`), or the level end's
        /// completion with nobody in game (`10007264`).
        case gameOver
        /// `FUN_10007170` → `FUN_100064d0` after the last sector: the next level is `none` and the session ends
        /// (`10006620..100066c8`; plan LT). A transition to the next sector is not an end.
        case campaignEnd
        /// The begin frame's quit (`1000591c`, `FUN_100064c0`: Esc, or the frame controller's +0x02 — set only by a
        /// Quit that lets the pause's Caps Lock wait go, `FrontEnd.quitDuringPause`, X `10030cb8`), read from the
        /// session's result (`SessionResult.End.escape`). The runner hands every pass empty keys, so its runs do not
        /// reach it today; it names the end instead of trapping. Phase 4 (plan S1a).
        case quit
        /// `maxPasses` passes ran and the session was still running.
        case bound
    }

    public var endReason: EndReason
    /// P1's film cursor (film object +0x04) at the end; −1 without a film.
    public var cursor: Int32
    /// P1's decoded score at the read that consumed film byte 4808 (`FilmCursor.score(player: 0, atRead: 4808)`,
    /// plan G4.1); nil when that read has not happened (or no film).
    public var scoreAtRead4808: Int32?
    /// P1's decoded score at the end of the last pass.
    public var endScore: Int32
    /// Passes run (the runner's total).
    public var passes: Int
    /// The trace, when the run recorded one.
    public var trace: ReplayTrace?

    public init(endReason: EndReason, cursor: Int32, scoreAtRead4808: Int32?, endScore: Int32, passes: Int,
                trace: ReplayTrace? = nil) {
        self.endReason = endReason
        self.cursor = cursor
        self.scoreAtRead4808 = scoreAtRead4808
        self.endScore = endScore
        self.passes = passes
        self.trace = trace
    }
}

/// A `DeimosSession` run with no clock and no keyboard (plan H2): pass after pass, as fast as the machine goes —
/// logic only unless asked to render. Rendering executes each pass's ops on a `DeimosRenderer` with the fades stepped
/// through all their levels and the host waits (`.limit`, `.pauseWait`) skipped (no clock; with no keys no pass ever
/// pauses). Every pass gets empty keys and `ticks` 0 (the FPS monitor's window never closes). Not `Sendable`: the
/// renderer is a shared reference.
public struct HeadlessRunner {
    public private(set) var session: DeimosSession
    /// The renderer when rendering (nil = logic only).
    public let renderer: DeimosRenderer?
    /// Set to a `ReplayTrace` to record a row per ticked pass (nil = off).
    public var trace: ReplayTrace?
    /// Passes run so far.
    public private(set) var passes = 0
    /// Why the session ended, once it has.
    public private(set) var ended: ReplayResult.EndReason?

    /// A non-film session (`srand(seed)`, the start's sector and players).
    public init(assets: DeimosAssets, start: SessionStart, seed: UInt32, prefs: DeimosPrefs = .fresh,
                render: Bool = false) throws {
        session = try DeimosSession(assets: assets, prefs: prefs, start: start, seed: seed)
        renderer = render ? DeimosRenderer(assets: assets) : nil
    }

    /// A film session: seed, level (so the sector) and players from the film (`FUN_100069b0`); fresh prefs.
    /// `DeimosSession` reads all three from the film itself, so the start's sector / players and `seed` passed here
    /// are not read (they are filled in only to name the film's values).
    public init(assets: DeimosAssets, film: Film, render: Bool = false) throws {
        try self.init(assets: assets, start: SessionStart(sector: 1, players: film.playerCount, film: film),
                      seed: film.seed, render: render)
    }

    /// The 640×480 window content when rendering.
    public var screen: Pixmap555? { renderer?.screen }

    /// Run passes until the session ends or `passes` reaches `maxPasses` (the total, across calls).
    public mutating func run(maxPasses: Int) -> ReplayResult {
        while ended == nil && passes < maxPasses {
            let levelEndingBefore = session.game.flags.levelEnding
            let out = session.pass(keys: HeldKeys(), ticks: 0)
            passes += 1
            if let renderer { Self.apply(out.ops, renderer) }
            if out.ticked { trace?.record(session) }
            if out.sessionEnded { ended = Self.reason(session, levelEndingBefore: levelEndingBefore) }
        }
        return result
    }

    /// The result as things stand.
    public var result: ReplayResult {
        ReplayResult(endReason: ended ?? .bound, cursor: session.game.film?.cursors[0] ?? -1,
                     scoreAtRead4808: session.game.film?.score(player: 0, atRead: 4808),
                     endScore: session.players[0].score, passes: passes, trace: trace)
    }

    /// Which rule cleared the running flag on the pass that ended a keyless session, in the pass's own order:
    /// 1. the tick's game over (`FUN_10006b50` `10006d68..10006d98`: no player in game and the tick's game time —
    ///    `gameTime − 1`, the tick adds 1 after it at `100059e0` — > start + int(flli 13));
    /// 2. the tick's `FUN_10007170` with G+0x09 set: nobody in game (`100071a0..100071e4`, `10007264`) → game over;
    ///    a film keeps G+0x09 (`100071f0`) → level complete; not a film, G+0x09 and G+0x39 fall (`1000723c..10007248`)
    ///    and the level start finds level `none` (`10006620..100066c8`) → the campaign end — a transition to the next
    ///    sector keeps the session running, so it never reaches here (plan LT);
    /// 3. the film branch after the tick (`10005a24..10005a48`): a film whose P1 cursor passed the recording.
    /// The only other clear is the begin frame's quit (`1000591c`: Esc, or +0x02, set only by a Quit inside the
    /// pause's Caps Lock wait, `FrontEnd.quitDuringPause`), first in the pass's order: `.quit` when the session's
    /// result says so (Phase 4). The runner's keys are empty, so its own
    /// runs never reach it — an end none of these explains is unreachable, and traps.
    static func reason(_ s: DeimosSession, levelEndingBefore: Bool) -> ReplayResult.EndReason {
        if s.result?.end == .escape { return .quit }
        let f = s.game.flags
        let delay = Int32(s.assets.floats[13].rounded(.towardZero))
        if f.noPlayerAlive && f.gameOverNoticed && s.gameTime &- 1 > f.gameOverStart &+ delay { return .gameOver }
        if f.levelComplete { return s.players.contains(where: \.inGame) ? .levelComplete : .gameOver }
        if levelEndingBefore && !f.levelEnding && f.level == .none { return .campaignEnd }
        if f.filmPlaying && (s.game.film?.finished ?? true) { return .filmEnd }
        preconditionFailure("HeadlessRunner: a keyless session ended by no known rule")
    }

    /// One pass's ops on the renderer: fades through all their levels, host waits skipped.
    static func apply(_ ops: [RenderOp], _ renderer: DeimosRenderer) {
        for op in ops {
            switch op {
            case let .fade(kind, present):
                renderer.fadeBegin(kind)
                let levels = kind == .fromBlack ? DisplayBuffers.fromBlackLevels : DisplayBuffers.toBlackLevels
                for a in levels { renderer.fadeStep(kind, a: a, present: present) }
                renderer.fadeEnd()
            case .limit, .pauseWait, .hostWait:
                break
            default:
                renderer.apply(op)
            }
        }
    }
}
