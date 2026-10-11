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
    /// `+0x11c`: the rows of the face above the water line (0 out of water, 1 fully submerged; draw-effects §1.1
    /// step 5).
    public var waterRow: Int
    /// `+0x1aa`: rotation in degrees (0…359), copied to face `+0x1a` for the draw (`10014688`).
    public var rotation: Int16
    /// `+0x1ae`: scale /256 (0x100 = 1.0), copied to face `+0x1c` (`10014698`).
    public var scale: Int16
    /// `+0xaa`: the hurt-flash frames the draw sees (`100146f0..10014728`). A `+0x89` sprite's flash is 0 here: its
    /// dynamic-light word overwrites the flash word (`1001472c..100147bc`, draw-effects §1.1 step 4).
    public var flash: Int16
    /// `+0x1b4`: the hurt flash uses table bank 4 (`0x40000 + 2n`) instead of 3.
    public var flashTable: UInt8
    /// `+0x1be..+0x1c4`: the occluder (nil = `.InitSprite`'s 32000s). `.WrapDrawSprites` does not read it — the clip
    /// it causes reaches the draw as `clip` (`.StandardSpriteCleanup` l. 32669–32700); kept for the seam (plan S3).
    public var occluder: SpriteSlot.Occluder?
    /// `+0x128`: the water kind of the submerged rows (`0x60000 + kind`, `100147c0..1001491c`).
    public var waterKind: Int16
    /// `+0x18c`: one draw with no water split, and the light pass without the water row (`10014800`, `10014960`).
    public var noWaterSplit: Bool

    public init(face: FaceRef, x: Int, y: Int, mode: UInt32 = 0, mirrored: Bool = false, clip: SpriteClip = SpriteClip(),
                lightOverlay: Bool = false, waterRow: Int = 0, rotation: Int16 = 0, scale: Int16 = 0x100,
                flash: Int16 = 0, flashTable: UInt8 = 0, occluder: SpriteSlot.Occluder? = nil, waterKind: Int16 = 0,
                noWaterSplit: Bool = false) {
        self.face = face
        self.x = x
        self.y = y
        self.mode = mode
        self.mirrored = mirrored
        self.clip = clip
        self.lightOverlay = lightOverlay
        self.waterRow = waterRow
        self.rotation = rotation
        self.scale = scale
        self.flash = flash
        self.flashTable = flashTable
        self.occluder = occluder
        self.waterKind = waterKind
        self.noWaterSplit = noWaterSplit
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
