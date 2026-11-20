import Foundation

/// The boot — `FUN_100000e0` (grounding A §1: the loading screen, the logos, `publ` and `inmu`, the loading lines;
/// the configuration window first when byte pref 2 is 0 or Option is held). ◇ Phase 4 S1b stub; S6 builds it.
///
/// **Frozen entry.** `init()` — the boot reads everything it needs from `FrontEndState`: the launch modifiers
/// (Command = the quiet launch, Option = the configuration window), sound available, the prefs. **Returns** nothing
/// (`Done`); the front end then enters the main menu (`FUN_100000a0`).
///
/// **The stub.** Draws nothing and returns at once.
public struct Boot: Sendable {
    public typealias Result = Done

    public init() {}

    public mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?,
                              state: inout FrontEndState) -> ScreenStep<Result> {
        .finish(Done())
    }
}
