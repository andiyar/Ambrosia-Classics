import Foundation

/// The original's 0x4c-byte draw command (sprite-geometry-draw §3.1), built by the command builders
/// (`FUN_10012fa0`, `FUN_10013460`, the HUD/text builders) and executed by `FUN_10019570` (draw now) or
/// queued on a render layer (`FUN_1001a450`). The frame pointer at +0x00 is resolved by the renderer
/// from `face`/`frame`. ★ LOCKED seam (plan S3).
public struct DrawCommand: Equatable, Sendable {
    /// Sprite group ID (+0x0c) and frame index (+0x10).
    public var face: FourCC
    public var frame: Int
    /// Centre x/y (+0x04/+0x08), integer screen/buffer coordinates.
    public var x: Int32
    public var y: Int32
    /// +0x14: 1 fade blend, 2 shadow, 4 tint, 8 target = terrain buffer.
    public var flags: UInt32
    /// +0x18, single precision.
    public var scale: Float
    /// +0x1c: 0..32, 32 = not drawn.
    public var alpha: UInt32
    /// +0x20..+0x2c {top, left, bottom, right}.
    public var clip: MacRect
    /// +0x30 render layer (0…15).
    public var layer: UInt8
    /// +0x31 draw-now flag.
    public var drawNow: Bool
    /// +0x34 colour (x1R5G5B5).
    public var colour: UInt16
    /// +0x38..+0x44 rect and +0x48 colour: face `COST` (a filled rect) only; nil otherwise.
    public var costRect: MacRect?
    public var costColour: UInt16

    /// Defaults = the runtime template.
    public init(face: FourCC = .none, frame: Int = 0, x: Int32 = 0, y: Int32 = 0, flags: UInt32 = 0,
                scale: Float = 1, alpha: UInt32 = 0,
                clip: MacRect = MacRect(top: 0, left: 0, bottom: 480, right: 416),
                layer: UInt8 = 7, drawNow: Bool = false, colour: UInt16 = 0x7fff,
                costRect: MacRect? = nil, costColour: UInt16 = 0) {
        self.face = face
        self.frame = frame
        self.x = x
        self.y = y
        self.flags = flags
        self.scale = scale
        self.alpha = alpha
        self.clip = clip
        self.layer = layer
        self.drawNow = drawNow
        self.colour = colour
        self.costRect = costRect
        self.costColour = costColour
    }

    /// The RUNTIME template at `0x100e63e4` — after the static initialiser `FUN_10014120` (runs before
    /// `main`, INDEX #56) rewrote the data image: clip {0, 0, 480, 416} (the game area), layer 7, scale 1.0,
    /// colour 0x7fff, everything else 0 / `none` (sprite-geometry-draw §3.1, `10014120..1001418c`).
    public static let template = DrawCommand()
}
