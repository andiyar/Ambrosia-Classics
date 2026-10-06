import Foundation

/// A music-streamer command (Phase 2; empty in Phase 1). ★ LOCKED seam (plan S3).
public enum MusicCue: Equatable, Sendable {
    case play(FourCC, loop: Bool)
    case stop
    case pause
    case resume
    case level(Int32)
}
