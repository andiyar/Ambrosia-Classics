import Foundation

/// The world map's face sets (plan S3, FE0; LOCKED) — `DrawOp.drawFace` draws face `index` of one of them (M2).
public enum FrontFaceSet: Equatable, Hashable, Sendable {
    /// PICT 8000: the player marker.
    case mapMarker
    /// PICT 8001: the level nodes.
    case mapNode
    /// PICT 8002: the boss nodes.
    case mapBoss
    /// PICT 8004: the ambient sprite.
    case mapAmbient

    /// The PICT the set is loaded from.
    public var pict: Int16 {
        switch self {
        case .mapMarker: return 8000
        case .mapNode: return 8001
        case .mapBoss: return 8002
        case .mapAmbient: return 8004
        }
    }
}
