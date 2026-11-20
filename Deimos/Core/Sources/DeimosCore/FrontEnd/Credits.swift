import Foundation

/// The credits — `FUN_10025b90('cred')` (grounding A §4; `front-end.md` §6: ten pages and a blank eleventh, 60-tick
/// gaps; a click or a key leaves, `N` starts a one-player game). ◇ Phase 4 S1b stub; S2 builds it.
///
/// **Frozen entry.** `init()` — the original's one argument is the string list `'cred'` (`DeimosAssets.credits()`).
/// **Returns** how it was left: `.newGame` for `N` (its caller `FUN_10025060` then starts a one-player game,
/// `100250a8`), else `.leave`.
///
/// **The stub.** Draws nothing and returns `.leave` at once.
public struct Credits: Sendable {
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
