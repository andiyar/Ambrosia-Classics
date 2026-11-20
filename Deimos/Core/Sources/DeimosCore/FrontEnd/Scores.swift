import Foundation

/// The high-score screen — `FUN_10021950` (grounding B §2d; `front-end.md` §4.1: 600 ticks, a click or a key leaves,
/// `N` starts a one-player game). ◇ Phase 4 S1b stub; S4 builds it.
///
/// **Frozen entry.** `init()` — the table is `FrontEndState.prefs`. The Option-click erase question belongs to the
/// menu's SCORES action, before this screen (`front-end.md` §2.7). **Returns** how it was left: `.newGame` for `N`
/// (its caller `FUN_10024e70` then starts a one-player game, `10024eb0`), else `.leave`.
///
/// **The stub.** Draws nothing and returns `.leave` at once.
public struct Scores: Sendable {
    public enum Exit: Equatable, Sendable {
        case leave
        case newGame
    }

    public typealias Result = Exit

    public init() {}

    public mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?,
                              state: inout FrontEndState) -> ScreenStep<Result> {
        .finish(.leave)
    }
}
