import Foundation

/// The game's RNG: the MSL C library `rand`/`srand` (engine-loop.md §9, HIGH) and the two RandomRange
/// wrappers. The state is the global `_DAT_100e032c`.
public struct MSLRandom: Equatable, Sendable {
    /// `_DAT_100e032c`.
    public var state: UInt32

    public init(seed: UInt32) { state = seed }

    /// `FUN_10055400` — `srand(s)`: stores the state.
    public mutating func srand(_ seed: UInt32) { state = seed }

    /// `FUN_100553e0` — `state = state·0x41c64e6d + 0x3039; return state >> 16 & 0x7fff`.
    public mutating func rand() -> Int32 {
        state = state &* 0x41c6_4e6d &+ 0x3039
        return Int32(state >> 16 & 0x7fff)
    }

    /// `FUN_10046580 @ 10046580` — `min == max ? min : min + rand() % (max − min + 1)`; no draw when
    /// `min == max` (`100465a0 bne` skips the `bl rand`). `subf/addi` (span) and `add` wrap (`&-`, `&+`);
    /// `divw/mullw/subf` = a truncating signed remainder `r − (r / span)·span`. Swift's `/` is NOT wrapping:
    /// it traps when span == 0 (e.g. `range(Int32.min, Int32.max)`), where the original's `divw` by zero is
    /// undefined — a precondition, not a modelled case (`r` ≥ 0, so `Int32.min / −1` cannot arise).
    public mutating func range(_ min: Int32, _ max: Int32) -> Int32 {
        if min == max { return min }
        let r = rand()
        let span = max &- min &+ 1
        return min &+ (r - (r / span) &* span)
    }

    /// `FUN_100465e0 @ 100465e0` — float RandomRange, every operation single precision
    /// (`100465fc…1004665c`): `lo == hi ? lo` (no draw, `fcmpu`/`bne`) `: m + (hi − lo)·rand() / 32767.0f`
    /// with `m = lo > hi ? hi : lo` (`fcmpo`/`ble`: not greater → `lo`, and `ble` is taken on unordered too,
    /// so the original picks `lo` when either is NaN; this port's `lo <= hi` picks `hi` then — a divergence
    /// for NaN inputs only, which no shipped PermFloat holds).
    /// `fsubs f1,f30,f29` = hi − lo; the int→double conversion of `rand()` is exact and narrowed by
    /// `fsubs`; `fmuls`; `fdivs` by K = 32767.0 (`*(float*)0x100d73f4`, via r2−0x6dd8); `fadds` m.
    /// Quirk kept: with lo > hi the result is `hi + (hi − lo)·r`, i.e. ≤ hi.
    public mutating func range(_ lo: Float, _ hi: Float) -> Float {
        if lo == hi { return lo }
        let m: Float = lo <= hi ? lo : hi
        let r = Float(rand())
        let span: Float = hi - lo
        let scaled: Float = span * r
        let q: Float = scaled / Float(32767.0)
        return q + m
    }
}
