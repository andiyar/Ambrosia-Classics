import Foundation
import HectorResources

/// The named fields of the 0xb29c-byte `Mlvl` header (world-data §3.2; plan Research note 7). Offsets are
/// header-relative; labels and use sites are the bank's. The 511 placement records (0x0004) and the two
/// 8192-row factor tables (0x326c / 0x726c) are read by `LevelFile`; the stale runtime pointers 0xb284..0xb298
/// are not read.
public struct LevelHeader: Sendable, Equatable {
    /// 0x0000 — 0x04277dc9 in every level, no reader.
    public let magic: UInt32
    /// 0x25c4 — level display name (pstr, Mac Roman).
    public let name: String
    /// 0x26c4 — map-node level number (= own id in all 24).
    public let mapNodeLevel: Int16
    /// 0x26c6 — draw submerged tiles as tinted faces (1 only in L11).
    public let submergedFaces: UInt8
    /// 0x26c7 — OmniPx mode (0, 1, 2, 5, 6).
    public let omniPxMode: UInt8
    /// 0x26c8 — copied to game-globals +0x16: ≠ 0 → the player starts facing left.
    public let startFacingLeft: UInt8
    /// 0x26c9 — water-surface effect flag.
    public let waterSurfaceEffect: UInt8
    /// 0x26ca — parallax ripple flag.
    public let parallaxRipple: UInt8
    /// 0x26cb — FG pattern tile period: 0 → 8×8, ≠ 0 → 6×6.
    public let patternPeriodSix: UInt8
    /// 0x26cc — px tilesets convert under the level+base CLUT `0x285e` when ≠ 0 (`.LoadPxBackTileset`/`.LoadPxMidTileset`; bosses-3 "level+sprite").
    public let pxUsesLevelBaseClut: UInt8
    /// 0x26cd — level-wide "in liquid" behaviour flag.
    public let inLiquid: UInt8
    /// 0x26d0 — level has its own `snd ` set (0 in all levels).
    public let levelSounds: UInt8
    /// 0x2706 — per-cell darkness enable flag.
    public let darknessEnable: Int16
    /// 0x270a / 0x270c — camera target offsets x / y.
    public let cameraOffsetX: Int16
    public let cameraOffsetY: Int16
    /// 0x270e — landing ("hard-ground") damage (0 → 0x70 at the use site).
    public let landingDamage: Int16
    /// 0x2710 — ice slipperiness.
    public let iceSlipperiness: Int16
    /// 0x2712 — gamma fade-in on level start.
    public let gammaFadeIn: Int16
    /// 0x2714 — water-current push, 1/256 px/frame.
    public let waterCurrent: Int16
    /// 0x2716 / 0x2718 / 0x271a — parallax horizon strip: Backgrounds PICT id, x factor (/256), base y.
    public let stripPict: Int16
    public let stripFactor: Int16
    public let stripBaseY: Int16
    /// 0x271c — alternate CLUT id.
    public let altClut: Int16
    /// 0x271e — parallax mode flag.
    public let parallaxMode: Int16
    /// 0x2722 — fire/flame mode.
    public let flameMode: Int16
    /// 0x2724 — boss-arena camera bound x (> 0 right edge, < 0 left edge).
    public let arenaBound: Int16
    /// 0x2726 / 0x2728 / 0x272a — auto-scroll x speed, y speed (1/256 px/frame), enable.
    public let autoScrollX: Int16
    public let autoScrollY: Int16
    public let autoScrollEnable: Int16
    /// 0x272c — constant side push on the player.
    public let sidePush: Int16
    /// 0x272e — second arena bound.
    public let secondArenaBound: Int16
    /// 0x2730..0x2736 — CLUT animation mode, count, period, amplitude.
    public let clutAnimMode: Int16
    public let clutAnimCount: Int16
    public let clutAnimPeriod: Int16
    public let clutAnimAmplitude: Int16
    /// 0x273c — chapter-screen number shown on entry (0 = none).
    public let chapter: Int16
    /// 0x2846 / 0x2848 — player start y / x (px).
    public let startY: Int16
    public let startX: Int16
    /// 0x284a — music track number.
    public let music: Int16
    /// 0x284c — PxBack tileset PICT (< 1 → 5000 at the use site).
    public let pxBackPict: Int16
    /// 0x284e — PxMid tileset PICT pair id (0 → none).
    public let pxMidPict: Int16
    /// 0x2850 — FG tileset PICT (0 → 181).
    public let fgPict: Int16
    /// 0x2852 — BG tileset PICT (0 → 180).
    public let bgPict: Int16
    /// 0x2856 — FG pattern tileset PICT (< 1 → 206).
    public let patternPict: Int16
    /// 0x285c — level CLUT (0 → 201).
    public let levelClut: Int16
    /// 0x285e — level+sprite CLUT, the screen CLUT (0 → 202).
    public let screenClut: Int16
    /// 0x2860 — physics override flag; 0x2862..0x286a — five physics values (written, never read).
    public let physicsOverride: Int16
    public let physicsValues: [Int16]
    /// 0x28e0 — FG tile → kind table as stored (96 entries; `LevelFile.fgKind(tile:)` applies the
    /// `.LoadTileDefinitions` overwrite).
    public let fgKindTable: [Int16]
    /// 0x29a0 — BG tile → kind table (96 entries).
    public let bgKindTable: [Int16]
    /// 0x3268 — PxMid enable.
    public let pxMidEnable: Int16
    /// 0xb26c / 0xb26e — PxBack / PxMid y-parallax factors (/256).
    public let pxBackYFactor: Int16
    public let pxMidYFactor: Int16
    /// 0xb278..0xb282 — PxBack, PxMid and main-grid dimensions (tiles).
    public let pxBackWidth: Int16
    public let pxBackHeight: Int16
    public let pxMidWidth: Int16
    public let pxMidHeight: Int16
    public let gridWidth: Int16
    public let gridHeight: Int16

    init(_ b: BigEndianBytes) throws {
        magic = try b.u32(0x0000)
        name = try b.pascalString(at: 0x25c4)
        mapNodeLevel = try b.i16(0x26c4)
        submergedFaces = try b.u8(0x26c6)
        omniPxMode = try b.u8(0x26c7)
        startFacingLeft = try b.u8(0x26c8)
        waterSurfaceEffect = try b.u8(0x26c9)
        parallaxRipple = try b.u8(0x26ca)
        patternPeriodSix = try b.u8(0x26cb)
        pxUsesLevelBaseClut = try b.u8(0x26cc)
        inLiquid = try b.u8(0x26cd)
        levelSounds = try b.u8(0x26d0)
        darknessEnable = try b.i16(0x2706)
        cameraOffsetX = try b.i16(0x270a)
        cameraOffsetY = try b.i16(0x270c)
        landingDamage = try b.i16(0x270e)
        iceSlipperiness = try b.i16(0x2710)
        gammaFadeIn = try b.i16(0x2712)
        waterCurrent = try b.i16(0x2714)
        stripPict = try b.i16(0x2716)
        stripFactor = try b.i16(0x2718)
        stripBaseY = try b.i16(0x271a)
        altClut = try b.i16(0x271c)
        parallaxMode = try b.i16(0x271e)
        flameMode = try b.i16(0x2722)
        arenaBound = try b.i16(0x2724)
        autoScrollX = try b.i16(0x2726)
        autoScrollY = try b.i16(0x2728)
        autoScrollEnable = try b.i16(0x272a)
        sidePush = try b.i16(0x272c)
        secondArenaBound = try b.i16(0x272e)
        clutAnimMode = try b.i16(0x2730)
        clutAnimCount = try b.i16(0x2732)
        clutAnimPeriod = try b.i16(0x2734)
        clutAnimAmplitude = try b.i16(0x2736)
        chapter = try b.i16(0x273c)
        startY = try b.i16(0x2846)
        startX = try b.i16(0x2848)
        music = try b.i16(0x284a)
        pxBackPict = try b.i16(0x284c)
        pxMidPict = try b.i16(0x284e)
        fgPict = try b.i16(0x2850)
        bgPict = try b.i16(0x2852)
        patternPict = try b.i16(0x2856)
        levelClut = try b.i16(0x285c)
        screenClut = try b.i16(0x285e)
        physicsOverride = try b.i16(0x2860)
        physicsValues = try b.i16Array(at: 0x2862, count: 5)
        fgKindTable = try b.i16Array(at: 0x28e0, count: 96)
        bgKindTable = try b.i16Array(at: 0x29a0, count: 96)
        pxMidEnable = try b.i16(0x3268)
        pxBackYFactor = try b.i16(0xb26c)
        pxMidYFactor = try b.i16(0xb26e)
        pxBackWidth = try b.i16(0xb278)
        pxBackHeight = try b.i16(0xb27a)
        pxMidWidth = try b.i16(0xb27c)
        pxMidHeight = try b.i16(0xb27e)
        gridWidth = try b.i16(0xb280)
        gridHeight = try b.i16(0xb282)
    }
}
