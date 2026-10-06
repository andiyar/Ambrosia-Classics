import Foundation
import FerazelCore
import HectorResources

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
/// Which file a set's picture comes from (`.LoadLevelTilesets` l. 1567–1628): the routine opens
/// `Ferazel's Wand Backgrounds` (l. 1569, `OpenResFile` makes it the current file) and loads a header-given id
/// between `_SetResWorldFile()` / `_RestoreResWorldFile()` (l. 1583–1585, 1590–1592, 1601–1603, 1613–1616,
/// 1624–1626; World Data on top: `.level`), but a **default** id
/// (header field 0 / < 1 — l. 1579–1580, 1597–1598, 1608–1610, 1620–1621) with no `_SetResWorldFile`, so its
/// search starts at Backgrounds: Backgrounds → Sprites → Sounds → Titles → app (World is not searched).
///
/// The fixed sets (`.InitGameGlobals`, loaded once) are `Fixed`.
public struct TileSets: Sendable, Equatable {

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

        public init(pxBack: Int16, pxMid: Int16, bg: Int16, fg: Int16, pattern: Int16) {
            self.pxBack = pxBack; self.pxMid = pxMid; self.bg = bg; self.fg = fg; self.pattern = pattern
        }

        public static func forLevel(_ h: LevelHeader) -> Ids {
            Ids(pxBack: h.pxBackPict < 1 ? 5000 : h.pxBackPict, pxMid: h.pxMidPict > 0 ? h.pxMidPict : 0,
                bg: h.bgPict == 0 ? 180 : h.bgPict, fg: h.fgPict == 0 ? 181 : h.fgPict,
                pattern: h.patternPict < 1 ? 206 : h.patternPict)
        }
    }

    /// The PxMid pair: image `id`, mask `id + 1`.
    public struct PxMid<Element: Sendable & Equatable>: Sendable, Equatable {
        public let image: Element
        public let mask: Element

        public init(image: Element, mask: Element) {
            self.image = image; self.mask = mask
        }
    }

    /// The converted pictures the sets were cut from (the census and the round-trip test read them).
    public struct Pictures: Sendable, Equatable {
        public let pxBack: ConvertedPicture
        /// Nil when the level has no PxMid set.
        public let pxMid: PxMid<ConvertedPicture>?
        public let bg: ConvertedPicture
        public let fg: ConvertedPicture
        /// The FG sheet under `cluts.fgWater` (the FG picture itself when the CLUTs agree), before the stamps.
        public let fgWater: ConvertedPicture
        public let pattern: ConvertedPicture
    }

    /// `.InitGameGlobals @ 10001498` (main dump l. 826–852): the FG water mask `PICT 183` and the FG blend
    /// `PICT 185`, both `.LoadEncFaceSetFromPICT(id, 0x60, 0x20, 0x20, 8, 0, 0, 0, 0)` from the Sprites file;
    /// 185 then `.ProcessFGBlendTileFaces`. Conversion CLUT: clut **199** — `_DAT_100a001c` ← `GetCTable(199)`
    /// (`.InitAppGlobals` l. 412–413), and `.InitGameGlobals` sets `*_DAT_1009ff94 = *_DAT_100a001c` before both
    /// loads (l. 827, 840); the lighting-tables §8 weight mapping is therefore in CLUT-199 indices. Seat ruling
    /// under Ben's 2026-10-07 follow-the-binary precedent (the plan said 200). 183 is a 1-bit BitMap (the
    /// bypass), so only 185 depends on it.
    public struct Fixed: Sendable, Equatable {
        public static let conversionClut: Int16 = 199
        public static let waterMaskArguments = FaceSheet.Arguments(unchecked: 183, count: 0x60, cellWidth: 0x20,
                                                                   cellHeight: 0x20, columns: 8)
        public static let blendArguments = FaceSheet.Arguments(unchecked: 185, count: 0x60, cellWidth: 0x20,
                                                               cellHeight: 0x20, columns: 8)

        public struct Pictures: Sendable, Equatable {
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
    /// Image `id`, mask `id + 1`; nil when the level has no PxMid set.
    public let pxMid: PxMid<PlainFaceSheet>?
    public let bg: FaceSheet
    public let fg: FaceSheet
    public let fgWater: WaterFaceSheet
    /// `_DAT_1009ff84`.
    public let pattern: FaceSheet
    /// `DAT_100a5004[64]`.
    public let patternPlain: PlainFaceSheet
    public let pictures: Pictures

    public static func pxBackArguments(pict: Int16) -> FaceSheet.Arguments {
        FaceSheet.Arguments(unchecked: pict, count: 0x24, cellWidth: 0x80, cellHeight: 0x80, columns: 6)
    }

    public static func pxMidArguments(pict: Int16) -> FaceSheet.Arguments {
        FaceSheet.Arguments(unchecked: pict, count: 0xc, cellWidth: 0x80, cellHeight: 0x80, columns: 6)
    }

    /// BG, FG and FG water.
    public static func tileArguments(pict: Int16) -> FaceSheet.Arguments {
        FaceSheet.Arguments(unchecked: pict, count: 0x60, cellWidth: 0x20, cellHeight: 0x20, columns: 8)
    }

    public static func patternArguments(pict: Int16) -> FaceSheet.Arguments {
        FaceSheet.Arguments(unchecked: pict, count: 0x40, cellWidth: 0x20, cellHeight: 0x20, columns: 8)
    }

    /// The level CLUT: header `0x285c`, 0 → 201 (`.SetupLevel`).
    public static func levelClutId(_ header: LevelHeader) -> Int16 {
        header.levelClut == 0 ? 201 : header.levelClut
    }

    public init(level: LevelFile, fixed: Fixed, resources: FerazelResources, search: ColorSearch,
                dither: DitherModel = .errorDiffusion, cluts: ConversionCLUTs? = nil) throws {
        let header = level.header
        let ids = Ids.forLevel(header)
        let cluts = cluts ?? ConversionCLUTs.forLevel(header)
        var clutCache: [Int16: ColorLUT] = [:]
        /// `fromWorld`: the header gave the id (`_SetResWorldFile`, chain `.level`); else the default id is
        /// searched from the current file, Backgrounds, onward (see the type doc).
        func convert(_ id: Int16, _ clutId: Int16, fromWorld: Bool) throws -> ConvertedPicture {
            if clutCache[clutId] == nil { clutCache[clutId] = try ColorLUT.load(id: clutId, from: resources, chain: .level) }
            let source: PictureSource
            if fromWorld {
                source = try PictureSource.load(id: id, from: resources, chain: .level)
            } else {
                let files = [resources.backgrounds, resources.sprites, resources.sounds, resources.titles, resources.app]
                guard let r = files.lazy.compactMap({ $0.resource(type: "PICT", id: id) }).first else {
                    throw PictureSourceError.missing(id: id)
                }
                source = try PictureSource(resource: r)
            }
            return try ConvertedPicture(source: source, clut: clutCache[clutId]!, search: search, dither: dither)
        }
        self.ids = ids
        self.cluts = cluts
        let pxBackPicture = try convert(ids.pxBack, cluts.pxBack, fromWorld: header.pxBackPict >= 1)
        pxBack = PlainFaceSheet(picture: pxBackPicture, arguments: Self.pxBackArguments(pict: ids.pxBack))
        let pxMidPictures: PxMid<ConvertedPicture>?
        if ids.pxMid != 0 {
            // Only a header-given id loads PxMid (l. 1589–1592), always from World on top.
            let image = try convert(ids.pxMid, cluts.pxMid, fromWorld: true)
            let mask = try convert(ids.pxMid + 1, cluts.pxMid, fromWorld: true)
            pxMidPictures = PxMid(image: image, mask: mask)
            pxMid = PxMid(image: PlainFaceSheet(picture: image, arguments: Self.pxMidArguments(pict: ids.pxMid)),
                          mask: PlainFaceSheet(picture: mask, arguments: Self.pxMidArguments(pict: ids.pxMid + 1)))
        } else {
            pxMidPictures = nil
            pxMid = nil
        }
        let bgPicture = try convert(ids.bg, cluts.bg, fromWorld: header.bgPict != 0)
        bg = try FaceSheet(picture: bgPicture, loader: .set(Self.tileArguments(pict: ids.bg)))
        let fgFromWorld = header.fgPict != 0
        let fgPicture = try convert(ids.fg, cluts.fg, fromWorld: fgFromWorld)
        fg = try FaceSheet(picture: fgPicture, loader: .set(Self.tileArguments(pict: ids.fg)))
        let fgWaterPicture = cluts.fgWater == cluts.fg ? fgPicture
            : try convert(ids.fg, cluts.fgWater, fromWorld: fgFromWorld)
        fgWater = try WaterFaceSheet(picture: fgWaterPicture, arguments: Self.tileArguments(pict: ids.fg),
                                     mask: fixed.waterMask, kind: level.fgKind(tile:))
        let patternPicture = try convert(ids.pattern, cluts.pattern, fromWorld: header.patternPict >= 1)
        pattern = try FaceSheet(picture: patternPicture, loader: .set(Self.patternArguments(pict: ids.pattern)))
        patternPlain = PlainFaceSheet(picture: patternPicture, arguments: Self.patternArguments(pict: ids.pattern))
        pictures = Pictures(pxBack: pxBackPicture, pxMid: pxMidPictures, bg: bgPicture, fg: fgPicture,
                            fgWater: fgWaterPicture, pattern: patternPicture)
    }
}
