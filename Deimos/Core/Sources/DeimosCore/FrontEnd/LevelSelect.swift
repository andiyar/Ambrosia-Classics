import Foundation

/// The level select — `FUN_1002e310(&sector)` (grounding A §3; X rows in `osx-build.md`; ruling 14: its own bare
/// `GameState` for the frame controller, the console and the pause). ◇ Phase 4 S1b stub; S3b builds it.
///
/// **Frozen entry.** `init()` — the original's only argument is the result pointer; what it reads (pref 3, the
/// highest sector reached; pref 8, the Esc hold) is in `FrontEndState.prefs`. **Returns** the chosen sector (1…12),
/// or nil when it was left with Esc (the original's `'none'`) — the sector only: the session's "music already
/// playing" flag (`SessionStart.musicAlreadyPlaying`, which the plan has the level select pass, its `ammu` still
/// playing) is set by start/return (S3a) when it builds the game's `SessionStart` from this result.
///
/// **The stub.** Draws nothing and returns sector 1 at once.
public struct LevelSelect: Sendable {
    public typealias Result = Int?

    public init() {}

    public mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?,
                              state: inout FrontEndState) -> ScreenStep<Result> {
        .finish(1)
    }
}
