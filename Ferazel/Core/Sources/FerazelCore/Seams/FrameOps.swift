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
