import Foundation

/// Every sprite face the original loads at boot: `.InitSprites @ 100002ac` (M l. 103–145) — its two singles, then each
/// `.Init<Class>Sprite` in call order — every `.Load1EncFaceFromPICT(pict, 0, 0, 0)` (a single) and
/// `.LoadEncFaceSetFromPICT(pict, count, cell w, cell h, columns, …)` (a set), unconditional, in the order made. They
/// stay loaded for the whole run, whatever the level; the per-level `.Cache*` faces (`.LoadCachedSpriteFaces`) are not
/// here.
///
/// Conversion CLUT: `*_DAT_1009ff94` = clut 200 "base sprite clut" for all of them except PICT 0x292, which
/// `.InitRopeSprite` converts under clut 199 (`_DAT_100a001c`) and switches back to 200 (`_DAT_100a0020`) after (M l.
/// 71007–71011); no other boot loader touches `ff94` (M l. 42387–71014, read).
///
/// Left out: `.InitMapFaces` (M l. 66615–66637: 8000…8004 under `_DAT_100a0024`), the world map's faces, which
/// `MapRenderer` loads and draws; the light faces (`.Load1LightFaceFromPICT`, `LightFace`).
///
/// A PICT the data does not hold is in the list as the binary asks for it: `.Load1EncFaceFromPICT` returns nil when
/// `GetPicture` finds nothing (M l. 28038–28039), so the renderer loads none for it (e.g. the crawler's 0x5dc…0x5df,
/// most held items 0x2ee…0x308).
public enum BootFaces {
    private static func set(_ p: Int16, _ n: Int, _ w: Int, _ h: Int, _ c: Int, clut: Int16 = 200) -> SetupFaces.Sheet {
        SetupFaces.Sheet(pict: p, count: n, cellWidth: w, cellHeight: h, columns: c, clut: clut)
    }
    private static func one(_ p: Int16) -> SetupFaces.Sheet { .single(p) }
    private static func ones<S: Sequence>(_ r: S) -> [SetupFaces.Sheet] where S.Element == Int16 { r.map(one) }

    /// In load order (duplicates none).
    public static let sheets: [SetupFaces.Sheet] = {
        var s: [SetupFaces.Sheet] = []
        // `.InitSprites` (M l. 112–115): the placeholder 150 and 151.
        s += [one(0x96), one(0x97)]
        // `.InitPlayerSprite` (M l. 42428–42491).
        s += [set(0x3eb, 4, 100, 0x78, 4), one(0x3ec), set(0x3f2, 10, 100, 0x78, 10), set(0x3f3, 4, 100, 0x78, 4),
              set(0x3f4, 6, 100, 0x78, 6), set(0x3f5, 4, 100, 0x78, 6), set(0x3f6, 6, 100, 0x78, 6),
              set(0x3fc, 0x10, 100, 0x78, 4), set(0x3fd, 5, 100, 0x78, 5), set(0x3fe, 10, 0x96, 0x78, 10),
              set(0x3ff, 10, 0x78, 0x78, 10), set(0x400, 0xc, 100, 0x78, 4), set(0x401, 8, 100, 0x78, 8),
              set(0x403, 6, 100, 0x78, 6), set(0x404, 10, 100, 0x78, 10), set(0x405, 6, 100, 0x78, 6),
              set(0x406, 3, 100, 0x78, 3), set(0x407, 6, 100, 0x78, 6), set(0x408, 6, 100, 0x78, 6),
              set(0x409, 6, 100, 0x78, 6), set(0x3f7, 8, 100, 0x78, 4), set(0x3f8, 7, 100, 0x78, 7),
              set(0x3f9, 8, 100, 0x78, 4), set(0x40a, 5, 100, 0x78, 5), set(0x40b, 5, 100, 0x78, 5),
              set(0x40c, 6, 100, 0x78, 6), set(0x40d, 4, 100, 0x78, 4), set(0x40e, 4, 100, 0x78, 4),
              set(0x40f, 9, 100, 0x78, 9)]
        s += ones(Int16(0x2ee)..<0x2ee + 0x1b)
        // `.InitPlayerShotSprite` (M l. 50235–50255).
        s += [set(0x44c, 6, 0x18, 0xf, 1), set(0x44d, 6, 0x18, 0xf, 1), set(0x44e, 6, 0x18, 0xf, 1),
              set(0x44f, 6, 0x18, 0xf, 1), set(0x450, 6, 0x18, 0xf, 1), set(0x451, 6, 0x18, 0xf, 1),
              set(0x459, 6, 0x20, 0x20, 6), set(0x45a, 0x14, 0x20, 0x28, 10), set(0x45b, 6, 0x1c, 0x1c, 6),
              set(0x45c, 8, 0xc, 0xc, 8), one(0x45e)]
        // `.InitEffectSprite` (M l. 53650–53682).
        s += [set(0x4b0, 0xd, 0x30, 0x30, 0xd), set(0x4b7, 0xd, 0x60, 0x60, 0xd), set(0x4b1, 6, 0x38, 8, 6),
              set(0x410, 4, 8, 8, 4), set(0x4b6, 0x22, 0x40, 0x74, 0x22), set(0xc1b, 0x10, 0x18, 0x18, 8),
              one(0x4b2), one(0x4b3), one(0x4b4), set(0x4e3, 6, 0x24, 0x24, 6), set(0x4ba, 3, 0x20, 0x20, 3),
              set(0x4c4, 0xb, 0x18, 0x18, 1)]
        // `.InitBonusSprite` (M l. 52272–52330).
        s += [one(0x517), one(2000), set(0x421, 10, 0x20, 0x20, 10), set(0x422, 10, 0x20, 0x20, 10),
              set(0x4bf, 4, 0x10, 0x11, 4), one(0x50a), one(0x50b), one(0x50c), one(0x50d),
              set(0x514, 6, 0x12, 0x14, 6), set(0x515, 6, 0x12, 0x14, 6), set(0x516, 9, 10, 10, 9),
              set(0x51d, 9, 10, 10, 9), set(0x51e, 9, 10, 10, 9), set(0x51b, 6, 10, 0x1c, 6),
              set(0x53c, 6, 0x2c, 0x2a, 6), set(0x53d, 6, 0x2c, 0x2a, 6), one(0x546), one(0xbea)]
        s += ones(Int16(0xc1c)..<0xc1c + 10) + ones(Int16(0xc80)..<0xc80 + 0x1b) + ones(Int16(0x532)..<0x532 + 10)
        // `.InitPlatformSprite` (M l. 54473–54491).
        s += [set(0x578, 10, 0x50, 0x29, 10), set(0x2c7, 3, 0x28, 0x18, 1), one(0x58c), one(0x58d), one(0x58e),
              one(0x59a), one(0x59c), set(0x599, 0x3c, 0x10, 0x10, 10), set(0x59b, 0x2d, 0x18, 0x18, 1),
              set(0x582, 7, 0xd8, 200, 1)]
        // `.InitCrawlerSprite` (M l. 56136–56140).
        s += ones(Int16(0x5dc)..<0x5dc + 4) + [one(0x6b0)]
        // `.InitWalkerSprite` (M l. 56759).
        s += [set(0x6a8, 8, 0x5e, 0x50, 1)]
        // `.InitBoxSprite` (M l. 58733–58811).
        s += [one(0x2c8), one(0x2c9), one(0x424), one(0x425), one(0x426), one(0x42e), one(0x42f), one(0x430),
              set(0xb5e, 6, 0x3c, 0x58, 6), set(0x51c, 4, 0x21, 0x1f, 4), one(0xcb2), one(0xc12), one(0xc13),
              one(0xc14)]
        s += ones(Int16(0xb56)..<0xb56 + 8)
        s += [set(0xb74, 0xc, 0x20, 0x14, 0xc), set(0xb75, 0x18, 0x20, 0x36, 0xc), set(0x4e2, 0x15, 0x24, 0x24, 7),
              one(0x4e4), set(0x5aa, 4, 0x20, 0x20, 4), set(0x429, 3, 0x54, 100, 3), one(0xb7c), one(0xb7d)]
        // `.InitEnemyShotSprite` (M l. 51402–51432).
        s += [set(0x6a7, 8, 0x18, 0x18, 4), set(0x6e1, 8, 0x20, 0x20, 8), set(0x6e2, 8, 0x20, 0x20, 8),
              set(0x6e6, 8, 0x10, 0x10, 8), set(0x454, 6, 0x18, 0xf, 1), set(0x455, 6, 0x18, 0xf, 1),
              set(0x456, 6, 0x18, 0xf, 1), set(0x457, 6, 0x18, 0xf, 1), set(0x45d, 0xf, 0x18, 0x18, 0xf),
              set(0x754, 8, 0x12, 0x12, 8), one(0x753), set(0x71f, 0x10, 0x30, 0x30, 8), one(0x771), one(0x772),
              one(0x773), one(0x774)]
        // `.InitButtonSprite` (M l. 61693–61697).
        s += [set(0x528, 6, 0xe, 0xc, 6), set(0x529, 6, 0xe, 0xc, 6), set(0x52a, 8, 0x20, 0x15, 8)]
        // `.InitRopeSprite` (M l. 71002–71010): 0x292 under clut 199.
        s += [one(0x289), set(0x28a, 0x1e, 0x14, 0x14, 0xf), set(0x28c, 0x1e, 0x14, 0x14, 0xf),
              set(0x292, 0x1e, 0x18, 0x18, 0xf, clut: 199)]
        return s
    }()
}
