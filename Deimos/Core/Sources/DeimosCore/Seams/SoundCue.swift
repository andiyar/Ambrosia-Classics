import Foundation

/// One effect to play (Phase 2; empty in Phase 1). ★ LOCKED seam (plan S3).
public struct SoundCue: Equatable, Sendable {
    public var id: FourCC
    public var priority: Int32
    public var volume: Int32
    public var pitch: Float
    public var allowMultiple: Bool

    public init(id: FourCC, priority: Int32, volume: Int32, pitch: Float, allowMultiple: Bool) {
        self.id = id
        self.priority = priority
        self.volume = volume
        self.pitch = pitch
        self.allowMultiple = allowMultiple
    }
}
