import Foundation

/// What `.WrapDrawSprites @ 100144c8` reads per sprite (plan S3, LOCKED).
public struct SpriteDraw: Equatable, Sendable {
    public var face: FaceRef
    public var x: Int
    public var y: Int
    /// The effective draw-mode word `+0xb8` (`mode << 16 | arg`, lighting-tables §2).
    public var mode: UInt32
    public var mirrored: Bool
    public var clip: SpriteClip
    /// The `+0x88` gate result.
    public var lightOverlay: Bool
    /// `+0x11c` (0 in Phase 1).
    public var waterRow: Int

    public init(face: FaceRef, x: Int, y: Int, mode: UInt32 = 0, mirrored: Bool = false, clip: SpriteClip = SpriteClip(),
                lightOverlay: Bool = false, waterRow: Int = 0) {
        self.face = face
        self.x = x
        self.y = y
        self.mode = mode
        self.mirrored = mirrored
        self.clip = clip
        self.lightOverlay = lightOverlay
        self.waterRow = waterRow
    }
}

/// A sprite's per-frame clip edges: `+0x1b6` left, `+0x1b8` right, `+0x1ba` bottom, `+0x1bc` top (zeroed every frame
/// by `.StandardSpriteHandles`; plan "Hazards for every R implementer").
public struct SpriteClip: Equatable, Sendable {
    public var left: Int
    public var right: Int
    public var bottom: Int
    public var top: Int

    public init(left: Int = 0, right: Int = 0, bottom: Int = 0, top: Int = 0) {
        self.left = left
        self.right = right
        self.bottom = bottom
        self.top = top
    }
}
