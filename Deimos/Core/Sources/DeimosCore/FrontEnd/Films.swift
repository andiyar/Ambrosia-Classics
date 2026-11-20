import Foundation

/// The films from the menu (grounding B §3, §4): DEMOS and `D` — `FUN_10024de0` → `FUN_100234d0(2, 1)`, the next
/// film whose name holds "Demo" by the counter G+0x24 (`FrontEndState.demoCounter`); `F` — `FUN_10024e10` →
/// `FUN_100234d0(1, 1)`, Last Film (the film held in memory, `FrontEndState.lastFilm`, else the one on disk).
/// ◇ Phase 4 S1b stub; S5 builds it.
///
/// **Frozen entry.** `init(kind:)`. **Returns** nothing (`Done`): it chooses the film and plays it through
/// start/return (`StartReturn(mode: .demo / .lastFilm, players: 1, film:)`), then returns to the menu.
///
/// **The stub.** Draws nothing, plays nothing and returns at once.
public struct Films: Sendable {
    public enum Kind: Equatable, Sendable {
        case demo
        case lastFilm
    }

    public typealias Result = Done

    public let kind: Kind

    public init(kind: Kind) {
        self.kind = kind
    }

    public mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?,
                              state: inout FrontEndState) -> ScreenStep<Result> {
        .finish(Done())
    }
}
