import Foundation

/// The configuration window — DLOG/DITL 190 "Game - Preferences", `FUN_100047c0(firstLaunch)` (grounding C §2;
/// `osx-build.md` D2–D5). Opened by the boot (`FUN_100047c0(1)` when byte pref 2 is 0 or Option is held) and by the
/// menu's PREFERENCES (`FUN_10024e40` → `FUN_100047c0(0)`, then b6). ◇ Phase 4 S1b stub; S6 builds it.
///
/// **Frozen entry.** `init(firstLaunch:)` — the original's argument (a first launch has no Cancel). It edits the live
/// prefs (`FrontEndState.prefs`) in place and keeps its own snapshot for Cancel; "Set Controls…" calls the controls
/// window. **Returns** true when it was closed with Save, false otherwise.
///
/// **The stub.** Draws nothing, changes nothing and returns false at once.
public struct ConfigDialog: Sendable {
    public typealias Result = Bool

    public let firstLaunch: Bool

    public init(firstLaunch: Bool) {
        self.firstLaunch = firstLaunch
    }

    public mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?,
                              state: inout FrontEndState) -> ScreenStep<Result> {
        .finish(false)
    }
}
