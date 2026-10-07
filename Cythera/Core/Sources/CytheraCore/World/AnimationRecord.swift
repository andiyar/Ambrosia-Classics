/// One 0xF001 tile-animation record, 4 × i16 {tile, base, nframes, divisor} (data-format §3.4, HIGH):
/// `LoadGlobals__Fv @ 10005798` points frame f (0..7) of `tile` at the pixels of
/// `base + ((f / divisor) mod nframes)`. The table ends at the first record whose tile is 0.
public struct AnimationRecord: Equatable, Sendable {
    public let tile: Int16
    public let base: Int16
    public let frameCount: Int16
    public let divisor: Int16

    public init(tile: Int16, base: Int16, frameCount: Int16, divisor: Int16) {
        self.tile = tile; self.base = base; self.frameCount = frameCount; self.divisor = divisor
    }

    /// The tile drawn for global animation frame `frame` (0..7), as `LoadGlobals` computes it (C `/` and
    /// `a - (a / n) * n`, truncating). `WorldGlobals` refuses records with a zero divisor or frame count.
    public func tile(forFrame frame: Int) -> Int {
        let q = frame / Int(divisor)
        return Int(base) + (q - (q / Int(frameCount)) * Int(frameCount))
    }
}
