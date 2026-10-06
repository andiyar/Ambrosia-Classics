import Foundation
import FerazelCore

/// `.LoadPlainFaceSetFromPICT @ 1002fab8` (pict, count, w, h, cols, out[]): the picture converted as for an
/// encoded set, then each cell `CopyBits`'d (srcCopy) into its own `w × h` 8-bit blit port carrying the same
/// conversion CLUT — an index-for-index copy (sprites-backgrounds §2–§3, main dump l. 28514–28640). Used for the
/// parallax sets (PxBack 36 of 128×128, PxMid 12 + 12) and the plain pattern faces.
public struct PlainFaceSheet: Sendable, Equatable {
    public let arguments: FaceSheet.Arguments
    /// One `cellWidth × cellHeight` index buffer per cell, row-major.
    public let faces: [[UInt8]]
    /// Cell → rows below the picture frame (read as 0; design §11).
    public let shortCells: [Int: Int]
    public let clutId: Int16

    public var shortRows: Bool { !shortCells.isEmpty }

    public init(picture: ConvertedPicture, arguments a: FaceSheet.Arguments) {
        arguments = a
        faces = (0..<a.count).map { picture.cell(FaceSheet.cellRect($0, a)) }
        shortCells = FaceSheet.shortCells(a, in: picture)
        clutId = picture.clutId
    }

    /// `GetPicture`, conversion under `clut`, then the loader.
    public static func load(_ a: FaceSheet.Arguments, from resources: FerazelResources, chain: ResourceChain,
                            clut: ColorLUT, search: ColorSearch, dither: DitherModel = .errorDiffusion) throws -> PlainFaceSheet {
        let source = try PictureSource.load(id: a.pict, from: resources, chain: chain)
        return PlainFaceSheet(picture: try ConvertedPicture(source: source, clut: clut, search: search, dither: dither),
                              arguments: a)
    }
}
