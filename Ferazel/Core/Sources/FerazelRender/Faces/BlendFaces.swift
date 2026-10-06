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

    /// The face with its copied bytes rewritten to weights (token structure, frame and bounds unchanged), walked
    /// as the original walks it (decompile l. 25377–25444): op 0 ends; ops 1 and 3 are passed over (no row-length
    /// check); op 2 rewrites its n bytes in place and steps over the padding to 4. At a token with op ≥ 4 the
    /// original `DebugStr`s "bad token" and **returns** (l. 25409–25411): the face is kept, its copies before the
    /// bad token already rewritten, the bad token and everything after it untouched — so is this.
    /// - Throws: `FaceDecodeError.truncated` when the stream ends before an end token or a literal's padded bytes
    ///   (the original would read past its handle; not modelled).
    public static func process(_ face: EncodedFace) throws -> EncodedFace {
        var out = face
        var p = 0
        while true {
            guard p + 4 <= out.data.count else { throw FaceDecodeError.truncated(offset: p) }
            let t = UInt32(out.data[p]) << 24 | UInt32(out.data[p + 1]) << 16 | UInt32(out.data[p + 2]) << 8
                | UInt32(out.data[p + 3])
            let op = t >> 24, n = Int(t & 0xffffff)
            let at = p
            p += 4
            switch op {
            case 0:
                return out
            case 1, 3:
                continue
            case 2:
                let padded = n + (n & 3 == 0 ? 0 : 4 - (n & 3))
                guard p + padded <= out.data.count else { throw FaceDecodeError.truncated(offset: at) }
                for k in p ..< p + n { out.data[k] = weight(out.data[k]) }
                p += padded
            default:
                return out          // `DebugStr` + return: rewritten up to the bad token
            }
        }
    }

    /// `.ProcessFGBlendTileFaces @ 10001400`: every face of the sheet.
    public static func process(_ sheet: FaceSheet) throws -> FaceSheet {
        FaceSheet(arguments: sheet.arguments, faces: try sheet.faces.map(process), shortCells: sheet.shortCells,
                  clutId: sheet.clutId)
    }
}
