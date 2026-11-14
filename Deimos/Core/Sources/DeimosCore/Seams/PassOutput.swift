import Foundation

/// A point in a pass's cue lists: the count of `sounds` and of `music` issued before it (plan LT).
public struct CueMark: Equatable, Sendable {
    public var sounds: Int
    public var music: Int

    public init(sounds: Int, music: Int) {
        self.sounds = sounds
        self.music = music
    }
}

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
    /// Where the level transition's fade to black (`FUN_10007170` → `FUN_1000b9a0(display, 1)`, `1000722c..10007234`)
    /// falls in `sounds` and `music`: the cues before the mark were issued before the fade began (the music stop and
    /// `tran`), the rest only after its last step (the next level's cues, or the session end's). The halt belongs to
    /// the side its index falls on. nil = no transition this pass (plan LT; additive, as H2's pause).
    public var fadeToBlackAt: CueMark?

    public init(ops: [RenderOp] = [], sounds: [SoundCue] = [], music: [MusicCue] = [],
                requests: [ShellRequest] = [], ticked: Bool = false, sessionEnded: Bool = false,
                haltEffectsAt: Int? = nil, fadeToBlackAt: CueMark? = nil) {
        self.ops = ops
        self.sounds = sounds
        self.music = music
        self.requests = requests
        self.ticked = ticked
        self.sessionEnded = sessionEnded
        self.haltEffectsAt = haltEffectsAt
        self.fadeToBlackAt = fadeToBlackAt
    }
}
