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
    /// 6A-S8 (added, Invariant 9): one face `.Load1EncFaceFromPICT` loads with the **Backgrounds** file on top of the
    /// chain — the horizon strip's (`.MTAddPxSprite`, M l. 30888, with the Backgrounds file opened on top by
    /// `.SetupLevel`, M l. 2256 / 2276; a PICT it lacks is found further down, `PxSprites.facePicture`). The Sprites
    /// file holds PICTs of the same ids (265 among them), so the strip's face is named by this case, never by
    /// `.encoded`. Index 0 always.
    case backgroundsSingle
}
