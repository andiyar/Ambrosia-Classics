import Foundation

/// `.ProcessFGBlendTileFace @ 1002a6b0` (lighting-tables §8, sprites-backgrounds §3.2; main dump l. 25377–25432),
/// run by `.ProcessFGBlendTileFaces` on each of PICT 185's 96 faces: walks the encoded tokens and rewrites every
/// copied pixel value `v` (an index in the CLUT current at load time) to a 2-bit weight; skips stay transparent.
public enum BlendFaces {
    /// `v == 0 || 0x97 ≤ v ≤ 0x98 → 3`; `1 ≤ v ≤ 0x96 → 0`; `0x99..0x9b → 2`; `0x9c..0x9e → 1`; `v ≥ 0x9f → 0`.
    public static func weight(_ v: UInt8) -> UInt8 {
        if v < 0x99 { return v == 0 || v > 0x96 ? 3 : 0 }
        if v > 0x9e { return 0 }
        return v < 0x9c ? 2 : 1
    }

    /// The face with its copied bytes rewritten to weights (token structure, frame and bounds unchanged).
    /// - Throws: `FaceDecodeError.badToken` for an op ≥ 4 (the original `DebugStr`s and returns).
    public static func process(_ face: EncodedFace) throws -> EncodedFace {
        var out = face
        var offset = 0
        try face.walk(position: { offset = $0 }) { token in
            if case .copy(let bytes) = token {
                for k in 0..<bytes.count { out.data[offset + 4 + k] = weight(bytes[k]) }
            }
        }
        return out
    }

    /// `.ProcessFGBlendTileFaces @ 10001400`: every face of the sheet.
    public static func process(_ sheet: FaceSheet) throws -> FaceSheet {
        FaceSheet(arguments: sheet.arguments, faces: try sheet.faces.map(process), shortCells: sheet.shortCells,
                  clutId: sheet.clutId)
    }
}
