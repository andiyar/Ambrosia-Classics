/// The two per-process latches `_Get0To6 @ 0000ccc9` (u) and `_Get13To22 @ 0000ccfb` (L).
///
/// Each is `if (val == 99) val = GetRandomFast(0,6)` (resp. `(0xd,0x16)`), static 99 in `__data`. `_Interface`
/// calls `_Get0To6(); _Get13To22();` before any game, so in-game they never draw (Research note 4). Their value
/// depends on the process's QuickDraw seed at that moment — assumed 1 (NR-3, [LOW]); the defaults are recorded
/// assumptions in `SessionConfig` (Invariant 11). u gates enemy AI from level u + 9; L gates sprite swaps from level L.
public struct SessionLatches: Equatable, Sendable {
    public var u: Int        // _Get0To6
    public var L: Int        // _Get13To22

    public init(u: Int, L: Int) {
        self.u = u
        self.L = L
    }

    /// The latches a fresh process (QuickDraw seed 1) computes in `_Interface`.
    public static let fromProcessSeedOne = SessionLatches(u: 1, L: 15)

    /// Replays `_Interface`'s two latch calls, in order, from `processSeed`.
    public static func derive(processSeed: UInt32, step: @escaping GameRandom.Step = QuickDrawRandom.step) -> SessionLatches {
        var rng = GameRandom(seed: processSeed, step: step)
        let u = rng.fast(0, 6)
        let L = rng.fast(0xd, 0x16)
        return SessionLatches(u: u, L: L)
    }
}
