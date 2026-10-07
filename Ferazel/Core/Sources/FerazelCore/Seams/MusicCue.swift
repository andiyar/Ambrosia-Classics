import Foundation

/// A music-player request (`.SetAIFFMusic`, fades; engine §4) — plan S3, LOCKED.
public enum MusicCue: Equatable, Sendable {
    case play(track: Int)
    case stop
    case volume(Int)
}
