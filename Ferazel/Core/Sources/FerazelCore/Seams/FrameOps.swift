import Foundation

/// What one `.GameLoop` iteration asked the screen, the mixer, the music player and the shell to do (plan S3,
/// LOCKED once Phase 1 lands — cases and fields may be added, never renamed). Core records the original's draw calls
/// at their call sites (`DrawOp`, in `.PaintFrameWrap` order); FerazelRender executes them; the shell plays the cues
/// and honours the requests (design §3, §3.2).
public struct FrameOps: Equatable, Sendable {
    public var draws: [DrawOp]
    public var sounds: [SoundCue]
    public var music: [MusicCue]
    public var requests: [ShellRequest]
    /// False on a skipped draw (prefs[0] "Reduce frame rate": the odd iteration of the pair, engine §4).
    public var drawn: Bool
    /// S1: the `FUN_10091504(snd)` stops of the iteration (every voice playing `snd`), in call order; where each fell
    /// among the plays is `soundStopAt`.
    public var soundStops: [Int16] = []
    /// S1 (review fix): parallel to `soundStops` — entry k is the index in `sounds` before which stop k was made
    /// (`sounds.count` at the stop). The mixer (`FUN_10091208` / `FUN_10091504`, l. 78217–78310) takes the calls in
    /// order: a play before a stop still takes a voice (evicting the lowest-priority one when all 16 are busy), and a
    /// stop frees nothing for the plays before it. The consumer interleaves: for i in 0...sounds.count, apply every
    /// stop whose `soundStopAt` == i (in order), then play `sounds[i]` (when i < sounds.count).
    public var soundStopAt: [Int] = []

    /// A stop at its place in call order (after the plays already in `sounds`).
    public mutating func stopSound(_ snd: Int16) {
        soundStops.append(snd)
        soundStopAt.append(sounds.count)
    }

    /// The empty iteration: nothing drawn, played or requested, and not a skipped draw.
    public init(draws: [DrawOp] = [], sounds: [SoundCue] = [], music: [MusicCue] = [], requests: [ShellRequest] = [],
                drawn: Bool = true) {
        self.draws = draws
        self.sounds = sounds
        self.music = music
        self.requests = requests
        self.drawn = drawn
    }
}
