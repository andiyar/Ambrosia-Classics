import Foundation

/// Everything one `DeimosSession.pass` produced, in order. ★ LOCKED seam (plan S3).
public struct PassOutput: Equatable, Sendable {
    public var ops: [RenderOp]
    public var sounds: [SoundCue]
    public var music: [MusicCue]
    public var requests: [ShellRequest]
    /// The pass ran a logic tick (always, in 1.0.6: the speed divider is never set — timing-frame §3).
    public var ticked: Bool
    public var sessionEnded: Bool

    public init(ops: [RenderOp] = [], sounds: [SoundCue] = [], music: [MusicCue] = [],
                requests: [ShellRequest] = [], ticked: Bool = false, sessionEnded: Bool = false) {
        self.ops = ops
        self.sounds = sounds
        self.music = music
        self.requests = requests
        self.ticked = ticked
        self.sessionEnded = sessionEnded
    }
}
