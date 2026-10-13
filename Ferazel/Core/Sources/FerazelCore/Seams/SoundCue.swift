import Foundation

/// One sound the original started this iteration (`STPlay*`; sprites-backgrounds §6.2–§6.3) — plan S3, LOCKED.
public struct SoundCue: Equatable, Sendable {
    public var snd: Int16
    public var priority: Int
    public var left: Int
    public var right: Int
    public var rate: UInt32
    /// S1: `if (!FUN_100916dc(snd)) play(…)` — the call is made only while no voice plays `snd` (`FUN_100916dc` =
    /// the number of voices playing it); the shell asks its mixer at the cue's place in `sounds`.
    public var onlyIfIdle: Bool

    public init(snd: Int16, priority: Int, left: Int, right: Int, rate: UInt32, onlyIfIdle: Bool = false) {
        self.snd = snd
        self.priority = priority
        self.left = left
        self.right = right
        self.rate = rate
        self.onlyIfIdle = onlyIfIdle
    }
}
