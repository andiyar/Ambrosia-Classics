import Foundation
import FerazelCore

/// A level's tile sets as `.LoadLevelTilesets @ 10003098` loads them (sprites-backgrounds §3; main dump
/// l. 1548–1628), each with the original cell arguments, converted under its conversion CLUT
/// (`*_DAT_1009ff94` at that call) through `ColorSearch` + `DitherModel`:
///
/// | set | loader | args | default id | conversion CLUT |
/// |---|---|---|---|---|
/// | PxBack | plain | 36 of 128×128, 6 cols | `0x284c` < 1 → 5000 | level CLUT `0x285c` (0 → 201); level+base if `0x26cc` |
/// | PxMid | plain ×2 | 12 + 12 of 128×128, 6 cols, ids id / id+1 | `0x284e` > 0 only | as PxBack |
/// | BG | encoded | 96 of 32×32, 8 cols | `0x2852` 0 → 180 | level+base `0x285e` (0 → 202) |
/// | FG | encoded | 96 of 32×32, 8 cols | `0x2850` 0 → 181 | level CLUT |
/// | FG water | `WaterFaceSheet` | as FG, same id | — | level CLUT |
/// | pattern | encoded **and** plain | 64 of 32×32, 8 cols | `0x2856` < 1 → 206 | level+base |
///
/// Decompile (`ghidra/Ferazel_pef.decompiled.c`): `.SetupLevel` l. 2287–2297 (`PTR_DAT_1009ff4c` ←
/// `GetCTable(0x285c)`, 0 → 201) and l. 2301–2318 (`_DAT_1009ff8c` ← `GetCTable(0x285e)`, 0 → 202);
/// `.LoadLevelTilesets` l. 1576–1577 sets the conversion CLUT `*_DAT_1009ff94` to the level CLUT on entry;
/// `.LoadBGTileset` switches to `ff8c` and restores (l. 950–955); `.LoadFGTileset`/`.LoadFGWaterTileset` leave
/// `ff94` alone (l. 970–1031); `.LoadFGPatternTileset` switches to `ff8c` (l. 1049); `.LoadPxBackTileset`/
/// `.LoadPxMidTileset` use `ff8c` when header `0x26cc` is set (l. 1094–1096, 1128–1130).
///
/// The fixed sets (`.InitGameGlobals`, loaded once) are `Fixed`.
public struct TileSets: Sendable {

    /// The conversion CLUT id of each set for one level.
    public struct ConversionCLUTs: Hashable, Sendable {
        public var pxBack: Int16
        public var pxMid: Int16
        /// Level+base `0x285e` (`.LoadBGTileset` l. 950–955).
        public var bg: Int16
        /// The level CLUT `0x285c` (201 for level 1): `.LoadLevelTilesets` sets it on entry (l. 1576–1577),
        /// `.LoadBGTileset` restores it (l. 955), and `.LoadFGTileset`/`.LoadFGWaterTileset` do not touch it
        /// (l. 970–1031). Seat ruling under Ben's 2026-10-07 follow-the-binary precedent (the plan's "level+base
        /// like BG [MED]" was wrong).
        public var fg: Int16
        /// As `fg` (`.LoadFGWaterTileset` l. 1001–1031).
        public var fgWater: Int16
        /// Level+base `0x285e` (`.LoadFGPatternTileset` l. 1049).
        public var pattern: Int16

        public init(pxBack: Int16, pxMid: Int16, bg: Int16, fg: Int16, fgWater: Int16, pattern: Int16) {
            self.pxBack = pxBack; self.pxMid = pxMid; self.bg = bg; self.fg = fg; self.fgWater = fgWater
            self.pattern = pattern
        }

        public static func forLevel(_ header: LevelHeader) -> ConversionCLUTs {
            let level = TileSets.levelClutId(header), base = ColorLUT.screenClutId(header)
            let px = header.pxUsesLevelBaseClut != 0 ? base : level   // `.LoadPxBackTileset`/`.LoadPxMidTileset`
            return ConversionCLUTs(pxBack: px, pxMid: px, bg: base, fg: level, fgWater: level, pattern: base)
        }
    }

    /// The PICT ids `.LoadLevelTilesets` passes (header fields with their defaults).
    public struct Ids: Hashable, Sendable {
        public var pxBack: Int16
        /// 0 = no PxMid set.
        public var pxMid: Int16
        public var bg: Int16
        public var fg: Int16
        public var pattern: Int16

        public static func forLevel(_ h: LevelHeader) -> Ids {
            Ids(pxBack: h.pxBackPict < 1 ? 5000 : h.pxBackPict, pxMid: h.pxMidPict > 0 ? h.pxMidPict : 0,
                bg: h.bgPict == 0 ? 180 : h.bgPict, fg: h.fgPict == 0 ? 181 : h.fgPict,
                pattern: h.patternPict < 1 ? 206 : h.patternPict)
        }
    }

    /// The converted pictures the sets were cut from (the census and the round-trip test read them).
    public struct Pictures: Sendable {
        public let pxBack: ConvertedPicture
        public let bg: ConvertedPicture
        public let fg: ConvertedPicture
        public let pattern: ConvertedPicture
    }

    /// `.InitGameGlobals @ 10001498` (main dump l. 826–852): the FG water mask `PICT 183` and the FG blend
    /// `PICT 185`, both `.LoadEncFaceSetFromPICT(id, 0x60, 0x20, 0x20, 8, 0, 0, 0, 0)` from the Sprites file;
    /// 185 then `.ProcessFGBlendTileFaces`. Conversion CLUT: clut **199** — `_DAT_100a001c` ← `GetCTable(199)`
    /// (`.InitAppGlobals` l. 412–413), and `.InitGameGlobals` sets `*_DAT_1009ff94 = *_DAT_100a001c` before both
    /// loads (l. 827, 840); the lighting-tables §8 weight mapping is therefore in CLUT-199 indices. Seat ruling
    /// under Ben's 2026-10-07 follow-the-binary precedent (the plan said 200). 183 is a 1-bit BitMap (the
    /// bypass), so only 185 depends on it.
    public struct Fixed: Sendable {
        public static let conversionClut: Int16 = 199
        public static let waterMaskArguments = FaceSheet.Arguments(pict: 183, count: 0x60, cellWidth: 0x20,
                                                                   cellHeight: 0x20, columns: 8)
        public static let blendArguments = FaceSheet.Arguments(pict: 185, count: 0x60, cellWidth: 0x20,
                                                               cellHeight: 0x20, columns: 8)

        public struct Pictures: Sendable {
            public let waterMask: ConvertedPicture
            public let blend: ConvertedPicture
        }

        /// `_DAT_1009ff98`.
        public let waterMask: FaceSheet
        /// `_DAT_1009ffc8` after `.ProcessFGBlendTileFaces` (copied bytes are weights 0..3).
        public let blend: FaceSheet
        /// 185 as encoded, before the weight rewrite.
        public let blendSource: FaceSheet
        public let pictures: Pictures

        public init(resources: FerazelResources, search: ColorSearch, dither: DitherModel = .errorDiffusion,
                    conversionClut: Int16 = Fixed.conversionClut) throws {
            let clut = try ColorLUT.load(id: conversionClut, from: resources, chain: .frontEnd)
            func convert(_ id: Int16) throws -> ConvertedPicture {
                try ConvertedPicture(source: try PictureSource.load(id: id, from: resources, chain: .frontEnd),
                                     clut: clut, search: search, dither: dither)
            }
            let mask = try convert(183), blend = try convert(185)
            pictures = Pictures(waterMask: mask, blend: blend)
            waterMask = try FaceSheet(picture: mask, loader: .set(Self.waterMaskArguments))
            blendSource = try FaceSheet(picture: blend, loader: .set(Self.blendArguments))
            self.blend = try BlendFaces.process(blendSource)
        }
    }

    public let ids: Ids
    public let cluts: ConversionCLUTs
    public let pxBack: PlainFaceSheet
    /// (image `id`, mask `id + 1`), or nil when the level has no PxMid set.
    public let pxMid: (image: PlainFaceSheet, mask: PlainFaceSheet)?
    public let bg: FaceSheet
    public let fg: FaceSheet
    public let fgWater: WaterFaceSheet
    /// `_DAT_1009ff84`.
    public let pattern: FaceSheet
    /// `DAT_100a5004[64]`.
    public let patternPlain: PlainFaceSheet
    public let pictures: Pictures

    public static func pxBackArguments(pict: Int16) -> FaceSheet.Arguments {
        FaceSheet.Arguments(pict: pict, count: 0x24, cellWidth: 0x80, cellHeight: 0x80, columns: 6)
    }

    public static func pxMidArguments(pict: Int16) -> FaceSheet.Arguments {
        FaceSheet.Arguments(pict: pict, count: 0xc, cellWidth: 0x80, cellHeight: 0x80, columns: 6)
    }

    /// BG, FG and FG water.
    public static func tileArguments(pict: Int16) -> FaceSheet.Arguments {
        FaceSheet.Arguments(pict: pict, count: 0x60, cellWidth: 0x20, cellHeight: 0x20, columns: 8)
    }

    public static func patternArguments(pict: Int16) -> FaceSheet.Arguments {
        FaceSheet.Arguments(pict: pict, count: 0x40, cellWidth: 0x20, cellHeight: 0x20, columns: 8)
    }

    /// The level CLUT: header `0x285c`, 0 → 201 (`.SetupLevel`).
    public static func levelClutId(_ header: LevelHeader) -> Int16 {
        header.levelClut == 0 ? 201 : header.levelClut
    }

    public init(level: LevelFile, fixed: Fixed, resources: FerazelResources, search: ColorSearch,
                dither: DitherModel = .errorDiffusion, cluts: ConversionCLUTs? = nil) throws {
        let ids = Ids.forLevel(level.header)
        let cluts = cluts ?? ConversionCLUTs.forLevel(level.header)
        var clutCache: [Int16: ColorLUT] = [:]
        func convert(_ id: Int16, _ clutId: Int16) throws -> ConvertedPicture {
            if clutCache[clutId] == nil { clutCache[clutId] = try ColorLUT.load(id: clutId, from: resources, chain: .level) }
            return try ConvertedPicture(source: try PictureSource.load(id: id, from: resources, chain: .level),
                                        clut: clutCache[clutId]!, search: search, dither: dither)
        }
        self.ids = ids
        self.cluts = cluts
        let pxBackPicture = try convert(ids.pxBack, cluts.pxBack)
        pxBack = PlainFaceSheet(picture: pxBackPicture, arguments: Self.pxBackArguments(pict: ids.pxBack))
        if ids.pxMid != 0 {
            pxMid = (PlainFaceSheet(picture: try convert(ids.pxMid, cluts.pxMid), arguments: Self.pxMidArguments(pict: ids.pxMid)),
                     PlainFaceSheet(picture: try convert(ids.pxMid + 1, cluts.pxMid),
                                    arguments: Self.pxMidArguments(pict: ids.pxMid + 1)))
        } else {
            pxMid = nil
        }
        let bgPicture = try convert(ids.bg, cluts.bg)
        bg = try FaceSheet(picture: bgPicture, loader: .set(Self.tileArguments(pict: ids.bg)))
        let fgPicture = try convert(ids.fg, cluts.fg)
        fg = try FaceSheet(picture: fgPicture, loader: .set(Self.tileArguments(pict: ids.fg)))
        let fgWaterPicture = cluts.fgWater == cluts.fg ? fgPicture : try convert(ids.fg, cluts.fgWater)
        fgWater = try WaterFaceSheet(picture: fgWaterPicture, arguments: Self.tileArguments(pict: ids.fg),
                                     mask: fixed.waterMask, kind: level.fgKind(tile:))
        let patternPicture = try convert(ids.pattern, cluts.pattern)
        pattern = try FaceSheet(picture: patternPicture, loader: .set(Self.patternArguments(pict: ids.pattern)))
        patternPlain = PlainFaceSheet(picture: patternPicture, arguments: Self.patternArguments(pict: ids.pattern))
        pictures = Pictures(pxBack: pxBackPicture, bg: bgPicture, fg: fgPicture, pattern: patternPicture)
    }
}
