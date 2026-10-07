/// One 0xF001 tile-animation record, 4 × i16 {tile, base, nframes, divisor} (data-format §3.4, HIGH):
/// `LoadGlobals__Fv @ 10005798` points frame f (0..7) of `tile` at the pixels of
/// `base + ((f / divisor) mod nframes)`. The table ends at the first record whose tile is 0.
public struct AnimationRecord: Equatable, Sendable {
    public let tile: Int16
    public let base: Int16
    public let frameCount: Int16
    public let divisor: Int16

    /// The tile count `LoadGlobals` indexes (`ptr[frame][0..0x9FF]`, pixels 0xA00 × 0x400 B).
    public static let tileLimit: Int16 = 0xA00

    /// nil for a record outside the census shape (Invariant 4): `tile` or `base` not in 0..<0xA00 (`tile` ≥ 1,
    /// 0 is the terminator), `frameCount` or `divisor` ≤ 0, or `base + frameCount − 1` past the last tile.
    /// The original checks none of this — `LoadGlobals` divides by `divisor` and `frameCount` and indexes
    /// `ptr[f][tile]` unguarded — but no shipped record comes near these edges.
    public init?(tile: Int16, base: Int16, frameCount: Int16, divisor: Int16) {
        guard (1..<Self.tileLimit).contains(tile), (0..<Self.tileLimit).contains(base),
              frameCount > 0, divisor > 0, Int(base) + Int(frameCount) - 1 < Int(Self.tileLimit) else { return nil }
        self.tile = tile; self.base = base; self.frameCount = frameCount; self.divisor = divisor
    }

    /// The tile drawn for global animation frame `frame` (0..7), as `LoadGlobals` computes it (C `/` and
    /// `a - (a / n) * n`, truncating). The validating init guarantees non-zero divisors.
    public func tile(forFrame frame: Int) -> Int {
        let q = frame / Int(divisor)
        return Int(base) + (q - (q / Int(frameCount)) * Int(frameCount))
    }
}
