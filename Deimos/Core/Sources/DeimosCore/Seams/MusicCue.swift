import Foundation

/// A music-streamer command (Phase 2; empty in Phase 1). ★ LOCKED seam (plan S3).
public enum MusicCue: Equatable, Sendable {
    case play(FourCC, loop: Bool)
    case stop
    case pause
    case resume
    case level(Int32)
    /// `FUN_10048120(1)` (Phase 4, plan S1a): a stream that is playing fades out over 1000 ms (`FUN_100d04d8(1000)`,
    /// the double-buffer callback stepping the fade 0x100 → 0, `100d0750..100d0848`), is paused, then disposed; a
    /// paused stream is disposed at once. The original busy-waits for the fade (≤ 600 ticks) — that wait is the
    /// caller's, not the cue's.
    case stopWithFade
}
