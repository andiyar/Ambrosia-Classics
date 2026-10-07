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
    /// The index into `sounds` at which `FUN_100476a0` (halt every effect) ran: the sounds before it are cut,
    /// the sounds from it on start after the halt; nil = no halt this pass (Phase 2, plan S3).
    public var haltEffectsAt: Int?

    public init(ops: [RenderOp] = [], sounds: [SoundCue] = [], music: [MusicCue] = [],
                requests: [ShellRequest] = [], ticked: Bool = false, sessionEnded: Bool = false,
                haltEffectsAt: Int? = nil) {
        self.ops = ops
        self.sounds = sounds
        self.music = music
        self.requests = requests
        self.ticked = ticked
        self.sessionEnded = sessionEnded
        self.haltEffectsAt = haltEffectsAt
    }
}
