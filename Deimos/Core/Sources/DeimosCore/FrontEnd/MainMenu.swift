import Foundation

/// The main menu — `FUN_100229a0` (grounding A §2; `front-end.md` §2; X rows in `osx-build.md`). ◇ Phase 4 S1b
/// stub; S2 builds it.
///
/// **Frozen entry.** `init(film:)` — `film` is played as soon as the menu is up, as the DEMOS button plays a demo
/// (the hidden `-film` switch, ruling 10); nil for a normal launch. **Returns** nothing (`Done`): the menu has been
/// left (b9), and the front end then shuts down (`FUN_10000630`) and asks the shell to quit. Its buttons and keys
/// call the other screens: start/return (1 PLAYER, 2 PLAYER), the configuration window, scores, films (DEMOS, `D`,
/// `F`), credits; the shared state (b6, b8, b9, the copyright clock, the demo counter) is `FrontEndState`'s.
///
/// **The stub.** Draws nothing. With the quit flag set it returns at once; otherwise it plays `film` once, if any,
/// then starts a one-player game at sector 1 through start/return each time it is resumed.
public struct MainMenu: Sendable {
    public typealias Result = Done

    public let film: Film?
    private var filmPlayed = false

    public init(film: Film? = nil) {
        self.film = film
    }

    public mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?,
                              state: inout FrontEndState) -> ScreenStep<Result> {
        if state.quit { return .finish(Done()) }
        if let film, !filmPlayed {
            filmPlayed = true
            return .call(.startReturn(StartReturn(mode: .demo, players: 1, film: film)))
        }
        return .call(.startReturn(StartReturn(mode: .play, players: 1)))
    }
}
