import Foundation

/// Start a game and return to the menu — `FUN_100234d0(mode, players)` (grounding B §1a–§1e; `front-end.md` §3;
/// X `100238c0`, `osx-build.md` D7, D9, D13, D18). ◇ Phase 4 S1b stub; S3a builds the start and return sequences.
///
/// **Frozen entry.** `init(mode:players:film:)` — the original's mode (0 play, 1 Last Film, 2 demo) and player count;
/// a film mode carries the film its caller chose (the films screen, S5) or nil when none loads (the result is then
/// `SessionResult.filmLoadFailed`). `init(direct:)` — the direct start (ruling 10): no level select, no fades, no
/// cursor shown on the way back; it is G12's path and stays as it is. **Returns** the game's `SessionResult`, or nil
/// when no game ran (the level select was cancelled). The level select hands back only the sector, so the game's
/// "music already playing" (`SessionStart.musicAlreadyPlaying`) is start/return's to set as it builds the start
/// after a level select. The menu's element list and its lit button are in `FrontEndState` (`menuElements`,
/// `menuLit`): the menu fills them, start/return fades them out and back in. As every screen: a pass's queued input
/// (shell events included) reaches it only when it is that pass's first step (`FrontEndScreen`).
///
/// **The stub.** Play mode calls the level select (its stub returns sector 1) and plays that sector; a film mode
/// plays the film; the direct start plays its start. The game is the front end's (`FrontEndState.startGame` /
/// `gamePass`): its pass is this screen's pass, and the pass that starts it carries `.hideCursor` first
/// (`10023550`; not for a film, X `1002393c..10023948`, D13 — the direct start hides it as the app always has). On
/// the pass after the game ended: return its result, with `.showCursor` (`InitCursor`, `100238b4` / `10023ad0`)
/// unless this is the direct start. A game that cannot be built: the direct start reports an ended game with no ops
/// and tries again on its next pass; otherwise it returns nil.
public struct StartReturn: Sendable {
    /// `FUN_100234d0`'s mode.
    public enum Mode: Equatable, Sendable {
        case play
        case lastFilm
        case demo
    }

    public typealias Result = SessionResult?

    public let mode: Mode
    public let players: Int
    public let film: Film?
    /// The direct start's game (nil from a menu).
    public let direct: SessionStart?

    private enum Step: Sendable {
        case begin
        case levelSelect
        case game
    }
    private var step = Step.begin

    public init(mode: Mode, players: Int, film: Film? = nil) {
        self.mode = mode
        self.players = players
        self.film = film
        direct = nil
    }

    /// The direct start (ruling 10).
    public init(direct start: SessionStart) {
        mode = .play
        players = start.players
        film = start.film
        direct = start
    }

    public mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?,
                              state: inout FrontEndState) -> ScreenStep<Result> {
        switch step {
        case .begin:
            if let direct { return startGame(direct, hideCursor: true, keys: keys, ticks: ticks, state: &state) }
            switch mode {
            case .play:
                step = .levelSelect
                return .call(.levelSelect(LevelSelect()))
            case .lastFilm, .demo:
                guard let film else { return .finish(.filmLoadFailed(startSector: 0), Self.backToMenu) }
                return startGame(SessionStart(sector: 1, players: film.playerCount, film: film), hideCursor: false,
                                 keys: keys, ticks: ticks, state: &state)
            }
        case .levelSelect:
            guard case let .levelSelect(sector)? = returned, let sector else { return .finish(nil, Self.backToMenu) }
            return startGame(SessionStart(sector: sector, players: players, film: nil), hideCursor: true,
                             keys: keys, ticks: ticks, state: &state)
        case .game:
            guard state.gameRunning else {
                return .finish(state.game?.session.result, direct == nil ? Self.backToMenu : PassOutput())
            }
            return .stay(state.gamePass(keys: keys, ticks: ticks))
        }
    }

    /// The way back to a menu: the cursor shown (`InitCursor`).
    private static let backToMenu = PassOutput(requests: [.showCursor])

    /// Build the game (the direct start's first game is already built, provisionally) and run its first pass.
    private mutating func startGame(_ start: SessionStart, hideCursor: Bool, keys: HeldKeys, ticks: UInt32,
                                    state: inout FrontEndState) -> ScreenStep<Result> {
        let prebuilt = direct != nil && (state.game.map { $0.provisional && !$0.begun } ?? false)
        if !prebuilt {
            do {
                try state.startGame(start, ticks: ticks)
            } catch {
                if direct != nil { return .stay(PassOutput(sessionEnded: true)) }
                return .finish(nil, Self.backToMenu)
            }
        }
        step = .game
        var out = state.gamePass(keys: keys, ticks: ticks)
        if hideCursor { out.requests.insert(.hideCursor, at: 0) }    // 10023550 FUN_1000b6e0
        return .stay(out)
    }
}
