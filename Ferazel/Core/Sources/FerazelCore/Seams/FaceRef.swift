import Foundation

/// One face of one loaded face set: the sheet's PICT id, the face index, and which kind of set holds it (plan S3,
/// LOCKED).
public struct FaceRef: Hashable, Sendable {
    public var pict: Int16
    public var index: Int
    public var set: FaceSetKind

    public init(pict: Int16, index: Int, set: FaceSetKind) {
        self.pict = pict
        self.index = index
        self.set = set
    }
}

/// Which loader made a face set (sprites-backgrounds §2): `.LoadEncFaceSetFromPICT` (encoded), its flip variant,
/// `.LoadEncWaterFaceSetFromPICT` (the FG water set) and `.LoadPlainFaceSetFromPICT` (plain pixmaps).
public enum FaceSetKind: Hashable, Sendable {
    case encoded
    case flipped
    case fgWater
    case plain
}
