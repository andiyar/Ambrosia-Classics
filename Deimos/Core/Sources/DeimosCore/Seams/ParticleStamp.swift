import Foundation

/// One particle's 7×7 stamp (particles-debris-blur §2.9): top-left corner, the core and fringe x1R5G5B5
/// colours, and the fade value. Carried by `RenderOp.particles`; R4 writes it. ★ LOCKED seam (plan S3).
public struct ParticleStamp: Equatable, Sendable {
    public var x: Int32
    public var y: Int32
    public var core: UInt16
    public var fringe: UInt16
    public var fade: Int32

    public init(x: Int32, y: Int32, core: UInt16, fringe: UInt16, fade: Int32) {
        self.x = x
        self.y = y
        self.core = core
        self.fringe = fringe
        self.fade = fade
    }
}
