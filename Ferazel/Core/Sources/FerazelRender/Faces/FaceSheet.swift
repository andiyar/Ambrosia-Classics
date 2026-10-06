import Foundation
import FerazelCore

public enum FaceSheetError: Error, Equatable {
    /// `.Load1EncFaceFromPICT` keeps the picture's unshifted picFrame as the face frame and the encoded rect
    /// (decompile l. 28041–28042, 28075, 28078); every shipped frame starts at (0, 0), and any other origin is
    /// refused rather than modelled.
    case singleFrameNotAtOrigin(pict: Int16, top: Int16, left: Int16)
}

/// An encoded face set: `.LoadEncFaceSetFromPICT @ 1002ef2c` (pict, count, cellW, cellH, cols, maskFirst,
/// maskLast, cacheId, flip) with flip 0 and no cache id (no `McSp` ships), or `.Load1EncFaceFromPICT @ 1002eafc`
/// (one face = the whole picture frame). Cell `i` = rect (`(i % cols)·w`, `(i / cols)·h`, +w, +h) of the
/// converted picture, each run through `.EncodeRect` (sprites-backgrounds §2, main dump l. 28245–28290).
///
/// A cell reaching past the frame reads 0 there and is listed in `shortCells` (PICT 257: 768×708, PxBack cells
/// 30..35 lose 60 of 128 rows — design §11; sprites §3 [MED: the original reads past its GWorld there]).
public struct FaceSheet: Sendable, Equatable {
    /// The loader's cell arguments.
    public struct Arguments: Hashable, Sendable {
        public var pict: Int16
        public var count: Int
        public var cellWidth: Int
        public var cellHeight: Int
        public var columns: Int

        public init(pict: Int16, count: Int, cellWidth: Int, cellHeight: Int, columns: Int) {
            self.pict = pict; self.count = count; self.cellWidth = cellWidth; self.cellHeight = cellHeight
            self.columns = columns
        }
    }

    /// Which loader call made the sheet.
    public enum Loader: Hashable, Sendable {
        /// `.LoadEncFaceSetFromPICT` with these arguments.
        case set(Arguments)
        /// `.Load1EncFaceFromPICT(pict, 0, 0, 0)`: one face, the picture frame.
        case single(pict: Int16)

        public var pict: Int16 {
            switch self {
            case .set(let a): return a.pict
            case .single(let p): return p
            }
        }
    }

    /// The arguments in effect (`.single` → count 1, the frame's size, 1 column).
    public let arguments: Arguments
    public let faces: [EncodedFace]
    /// Cell → rows below the picture frame (read as 0).
    public let shortCells: [Int: Int]
    /// The conversion CLUT the picture was converted under.
    public let clutId: Int16

    /// True when any cell reaches past the frame.
    public var shortRows: Bool { !shortCells.isEmpty }

    public init(arguments: Arguments, faces: [EncodedFace], shortCells: [Int: Int], clutId: Int16) {
        self.arguments = arguments; self.faces = faces; self.shortCells = shortCells; self.clutId = clutId
    }

    /// Cell `i`'s rect in the sheet.
    public static func cellRect(_ i: Int, _ a: Arguments) -> EncodedFace.Rect {
        let col = i % a.columns, row = i / a.columns
        return EncodedFace.Rect(top: Int16(truncatingIfNeeded: row * a.cellHeight),
                                left: Int16(truncatingIfNeeded: col * a.cellWidth),
                                bottom: Int16(truncatingIfNeeded: (row + 1) * a.cellHeight),
                                right: Int16(truncatingIfNeeded: (col + 1) * a.cellWidth))
    }

    /// Cells → rows past the frame, for any grid over `picture`.
    static func shortCells(_ a: Arguments, in picture: ConvertedPicture) -> [Int: Int] {
        var out: [Int: Int] = [:]
        for i in 0..<a.count {
            let rows = picture.rowsPastFrame(cellRect(i, a))
            if rows > 0 { out[i] = rows }
        }
        return out
    }

    /// The loader run over an already converted picture.
    /// - Throws: `FaceSheetError.singleFrameNotAtOrigin` for a `.single` picture whose frame is not at (0, 0).
    public init(picture: ConvertedPicture, loader: Loader) throws {
        switch loader {
        case .set(let a):
            let faces = (0..<a.count).map { i in
                FaceEncoder.encode(pixels: picture.pixels, width: picture.width, height: picture.height,
                                   rect: Self.cellRect(i, a), sourceId: a.pict)
            }
            self.init(arguments: a, faces: faces, shortCells: Self.shortCells(a, in: picture), clutId: picture.clutId)
        case .single(let pict):
            // `.Load1EncFaceFromPICT` stores the unshifted picFrame as the frame; at (0, 0) that is the cell.
            guard picture.frameTop == 0, picture.frameLeft == 0 else {
                throw FaceSheetError.singleFrameNotAtOrigin(pict: pict, top: picture.frameTop, left: picture.frameLeft)
            }
            let a = Arguments(pict: pict, count: 1, cellWidth: picture.width, cellHeight: picture.height, columns: 1)
            let face = FaceEncoder.encode(pixels: picture.pixels, width: picture.width, height: picture.height,
                                          rect: Self.cellRect(0, a), sourceId: pict)
            self.init(arguments: a, faces: [face], shortCells: [:], clutId: picture.clutId)
        }
    }

    /// `GetPicture`, conversion under `clut`, then the loader.
    public static func load(_ loader: Loader, from resources: FerazelResources, chain: ResourceChain, clut: ColorLUT,
                            search: ColorSearch, dither: DitherModel = .errorDiffusion) throws -> FaceSheet {
        let source = try PictureSource.load(id: loader.pict, from: resources, chain: chain)
        let picture = try ConvertedPicture(source: source, clut: clut, search: search, dither: dither)
        return try FaceSheet(picture: picture, loader: loader)
    }

    /// The player's face sets in `.InitPlayerSprite` call order (player-states §7; main dump l. 42427–42484):
    /// 29 sheets, 1003..1039 except 1026 (unused) — all with cell 100×120 except 1022 (150×120) and 1023
    /// (120×120); 1004 through `.Load1EncFaceFromPICT`. Converted under the sprite CLUT 200. The glider sets
    /// 1050..1053 (cached 160×160) are not Phase 1.
    public static let playerSheets: [Loader] = {
        func s(_ pict: Int16, _ count: Int, _ w: Int, _ cols: Int, h: Int = 120) -> Loader {
            .set(Arguments(pict: pict, count: count, cellWidth: w, cellHeight: h, columns: cols))
        }
        return [
            s(1003, 4, 100, 4), .single(pict: 1004), s(1010, 10, 100, 10), s(1011, 4, 100, 4), s(1012, 6, 100, 6),
            s(1013, 4, 100, 6), s(1014, 6, 100, 6), s(1020, 16, 100, 4), s(1021, 5, 100, 5), s(1022, 10, 150, 10),
            s(1023, 10, 120, 10), s(1024, 12, 100, 4), s(1025, 8, 100, 8), s(1027, 6, 100, 6), s(1028, 10, 100, 10),
            s(1029, 6, 100, 6), s(1030, 3, 100, 3), s(1031, 6, 100, 6), s(1032, 6, 100, 6), s(1033, 6, 100, 6),
            s(1015, 8, 100, 4), s(1016, 7, 100, 7), s(1017, 8, 100, 4), s(1034, 5, 100, 5), s(1035, 5, 100, 5),
            s(1036, 6, 100, 6), s(1037, 4, 100, 4), s(1038, 4, 100, 4), s(1039, 9, 100, 9),
        ]
    }()
}
