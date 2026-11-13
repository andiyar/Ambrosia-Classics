import Foundation

/// The pass's audio output as Core records it: effect cues and music commands in call order, and the position
/// of an effects halt. ★ LOCKED (plan S2).
public struct CueBuffer: Equatable, Sendable {
    public var sounds: [SoundCue]
    public var music: [MusicCue]
    /// The index into `sounds` at which `FUN_100476a0` (halt every effect) ran: the sounds before it are cut,
    /// the sounds from it on start after the halt; nil = no halt (leg A I-6).
    public var haltEffectsAt: Int?

    public init(sounds: [SoundCue] = [], music: [MusicCue] = [], haltEffectsAt: Int? = nil) {
        self.sounds = sounds
        self.music = music
        self.haltEffectsAt = haltEffectsAt
    }

    /// `FUN_100476a0` at this point of the pass: everything recorded so far is cut (a later halt supersedes).
    public mutating func haltEffects() { haltEffectsAt = sounds.count }
}
