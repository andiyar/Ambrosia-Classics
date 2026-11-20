import Foundation

/// The controls window — DLOG/DITL 191 "Game - Controls", X `FUN_100435d0(prefs + 0x14b8, prefs + 0x14d4)`
/// (grounding C §3, §3a; `osx-build.md` D4). Called by the configuration window's "Set Controls…". ◇ Phase 4 S1b
/// stub; S7 builds it.
///
/// **Frozen entry.** `init()` — the original's arguments are the live prefs' two key sets
/// (`FrontEndState.prefs.keyTable`); it edits working copies and writes both sets back on Save. **Returns** true for
/// Save (X returns 1), false for Cancel.
///
/// **The stub.** Draws nothing, changes nothing and returns false at once.
public struct ControlsDialog: Sendable {
    public typealias Result = Bool

    public init() {}

    public mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?,
                              state: inout FrontEndState) -> ScreenStep<Result> {
        .finish(false)
    }
}
