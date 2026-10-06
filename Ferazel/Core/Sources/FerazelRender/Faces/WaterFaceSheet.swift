import Foundation
import FerazelCore

/// `.LoadEncWaterFaceSetFromPICT @ 1002f528` (main dump l. 28319–28512): as `.LoadEncFaceSetFromPICT`, but the
/// picture is drawn into a fresh blit port and, before each cell `i` is encoded, the FG water-mask face of the
/// cell's FG kind (`k = .LookupFGTileKind(i)`, used when 0 ≤ k < 0x60) is stamped into the cell at its top-left
/// by `.BlitEncBoolTile @ 100230bc`: every pixel the mask face copies writes **0** into the port (the blitter
/// stores a literal 0 per copied byte — `li r4,0` / `stw r4`, disasm 10023148..100231cc; skips leave the port
/// alone). The mask faces are PICT 183's 96 cells (`_DAT_1009ff98`), whose set bits are 0xff (the 1-bit bypass).
/// Purpose "the water version of the FG tiles" [MED, sprites-backgrounds §2].
public struct WaterFaceSheet: Sendable, Equatable {
    public let sheet: FaceSheet
    /// Per cell, the mask face stamped (the FG kind), or nil when the kind is outside 0..<96.
    public let stampedKinds: [Int?]

    /// - Parameters:
    ///   - picture: the FG sheet converted under the FG-water conversion CLUT.
    ///   - mask: the FG water-mask set (PICT 183).
    ///   - kind: `.LookupFGTileKind` (`LevelFile.fgKind(tile:)`).
    public init(picture: ConvertedPicture, arguments a: FaceSheet.Arguments, mask: FaceSheet,
                kind: (Int) -> Int) throws {
        var port = picture.pixels
        var faces: [EncodedFace] = []
        var stamped: [Int?] = []
        for i in 0..<a.count {
            let rect = a.rect(ofCell: i)
            let k = kind(i)
            if k >= 0, k < 0x60, k < mask.faces.count {
                try Self.stamp(mask.faces[k], into: &port, width: picture.width, height: picture.height,
                               x: Int(rect.left), y: Int(rect.top))
                stamped.append(k)
            } else {
                stamped.append(nil)
            }
            // +0x30: `.LoadEncWaterFaceSetFromPICT` never writes it (record writes l. 28460–28471 stop at +0x2c; the
            // set loader's `+0x30 = pict` at l. 28277 has no counterpart here). The record is `NewPtr` (l. 28365,
            // not cleared), so the original holds whatever the heap held; built as 0, a fresh record's value.
            faces.append(try FaceEncoder.encode(pixels: port, width: picture.width, height: picture.height, rect: rect,
                                            sourceId: 0))
        }
        sheet = FaceSheet(arguments: a, faces: faces, shortCells: FaceSheet.shortCells(a, in: picture),
                          clutId: picture.clutId)
        stampedKinds = stamped
    }

    /// `.BlitEncBoolTile`: walks `face`'s tokens from (x, y); each copied byte writes 0 at its pixel.
    static func stamp(_ face: EncodedFace, into port: inout [UInt8], width: Int, height: Int, x: Int, y: Int) throws {
        var row = y - 1, col = x
        try face.walk { token in
            switch token {
            case .row: row += 1; col = x
            case .skip(let n): col += n
            case .copy(let bytes):
                for k in 0..<bytes.count where row >= 0 && row < height && col + k >= 0 && col + k < width {
                    port[row * width + col + k] = 0
                }
                col += bytes.count
            case .end: break
            }
        }
    }
}
