/// The game's random stream: QuickDraw `Random()` (through a swappable step) plus `_GetRandomFast`.
///
/// Every draw in the simulation goes through one `GameRandom`; `drawCount` counts each `Random()` call and is
/// part of the replay trace (G4, `--trace`). Seeded once per demo by `SetQDGlobalsRandomSeed(FILM.seed)`
/// (Research note 3); levels inherit the running state.
public struct GameRandom: Sendable {
    public typealias Step = @Sendable (UInt32) -> (seed: UInt32, value: Int16)

    public private(set) var seed: UInt32
    public private(set) var drawCount: Int
    private let step: Step

    public init(seed: UInt32, step: @escaping Step = QuickDrawRandom.step) {
        self.seed = seed
        self.drawCount = 0
        self.step = step
    }

    /// One QuickDraw `Random()`: advance the seed, count the draw, return the signed 16-bit value.
    public mutating func random() -> Int16 {
        let next = step(seed)
        seed = next.seed
        drawCount += 1
        return next.value
    }

    /// `_GetRandomFast(lo, hi) @ 0000c4cc`, exact arithmetic (Research note 1):
    /// `p = ((hi - lo) + 1) * (Random() & 0xffff); if (0x7fffffff < p) p += 0xffff; return lo + ((int)p >> 16) & 0xffff;`
    /// Unsigned 32-bit product, the `+0xffff` correction (never reached by game ranges — kept), signed
    /// arithmetic shift, then the 16-bit mask over the sum. Result is in `[lo, hi]` for the game's ranges.
    public mutating func fast(_ lo: Int, _ hi: Int) -> Int {
        let r = UInt32(UInt16(bitPattern: random()))
        let n = UInt32(truncatingIfNeeded: hi - lo + 1)
        var p = n &* r
        if p > 0x7fff_ffff {
            p &+= 0xffff
        }
        return (lo + Int(Int32(bitPattern: p) >> 16)) & 0xffff
    }
}
