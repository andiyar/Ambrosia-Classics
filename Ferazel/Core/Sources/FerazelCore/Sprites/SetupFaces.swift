import Foundation

/// ◇ Phase-1 stub (plan S2; replaced by the class Setup routines in Phases 4–5): what each class Setup leaves for the
/// **42 placed types of level 1** (plan Research note 15) — face (sheet + cell), layer `+0x80`, `+0xb8`, `+0x17e`,
/// `+0x88`/`+0x89`, position, idle margins `+0x1c8..+0x1ce` — and the `.SetupLevelSprites @ 10003cd0` spawn. No
/// Handle runs. Transcribed from the decompile (`ghidra/ferazel/Ferazel_pef.decompiled.c`):
///
/// - `.SetupBackgroundSprite @ 10071710` (l. 61919–62678), `.SetupBonusSprite @ 1005d988` (52338–52804),
///   `.SetupBoxSprite @ 1006b43c` (58892–59730), `.SetupPlatformSprite @ 10061f94` (54497–54536),
///   `.SetupWalkerSprite @ 10067318` (56898–57100), `.SetupCrawlerSprite @ 100659a0` (56153–56246),
///   `.SetupRoachSprite @ 10077914` (64899–64957); each starts with `.InitSprite` (`SpriteSlot` defaults) and copies
///   the position from the spawn copy (`+0xc ← +8`, `+0xa ← +6`), which also undoes `.MTNewSprite`'s store of y into
///   `+0xc` (raw `100331e4..100331f8`: `sth r27,0xc` then `sth r28,0xc`, `+0xa` left 0) — so no level-1 type moves.
/// - Sheets: the `.Init<Class>Sprite` calls (`.InitBonusSprite` l. 52261, `.InitBoxSprite` 58697,
///   `.InitBackgroundSprite` 61846, `.InitPlatformSprite` 54410, `.InitWalkerSprite` 56746, `.InitCrawlerSprite` 56123,
///   `.InitRoachSprite` 64886). Boot loads convert under `*_DAT_1009ff94` = CLUT 200 (`.main` l. 8262–8264); the
///   cached sets (`.CacheEncFaceSetFromPICT` / `.Cache1EncFaceFromPICT`) load in `.LoadCachedSpriteFaces @ 10088fa8`
///   after `.SetupLevelSprites` (`.SetupLevel` l. 2526, 2537) under CLUT 200 (`.SetupLevel` l. 2273 `*ff94 = *0020`)
///   unless the entry's flag (`_DAT_100a0a48` at caching, entry `+0x11c` / `+0xc`) is 1 → the level+base CLUT
///   `*_DAT_1009ff8c` (raw `1008901c..1008903c`, `1008914c..1008916c`; 202 on level 1) or 2 → CLUT 199.
/// - A cached face's pointer (`+4`) is the placeholder PICT 150 face (`*_DAT_100a0080`, `.InitSprites` l. 112–113)
///   until loaded, so on a level's first load a Setup that copies it leaves the placeholder; Phase 1 draws the cached
///   face (`FaceSource.setupCached`).
public enum SetupFaces {

    public enum Error: Swift.Error, Equatable {
        /// `.GenerateSprite` selects no Setup for the type.
        case unmapped(type: Int16)
        /// A Setup arm Phase 1 has not transcribed (only the 42 level-1 types are).
        case notTranscribed(type: Int16)
        /// Header `0x272a` (auto-scroll) ≠ 0: `.SetupLevelSprites` then adds the scroll-marker sprites (l. 2056–2099), not built.
        case autoScrollSprites
    }

    /// Where the face Phase 1 draws comes from.
    public enum FaceSource: Hashable, Sendable {
        /// The Setup stores it (`+0xc0` ← a boot-loaded face).
        case setup
        /// The Setup stores a class-cache face pointer (the placeholder PICT 150 until `.LoadCachedSpriteFaces`).
        case setupCached
        /// The Setup leaves `+0xc0 = 0` and the class Handle sets the face; Phase 1 draws the first face of the
        /// sheet the Handle uses (gate card).
        case handle
        /// Never drawn: no face from Setup or Handle (triggers, the level exit).
        case none
    }

    /// A face set: `.LoadEncFaceSetFromPICT(pict, count, cellW, cellH, cols, −1, −1, 0, 0)`, or with `single`
    /// `.Load1EncFaceFromPICT(pict, 0, 0, 0)` (count 1, the frame).
    public struct Sheet: Hashable, Sendable {
        public let pict: Int16
        public let count: Int
        public let cellWidth: Int
        public let cellHeight: Int
        public let columns: Int
        public let single: Bool
        /// The conversion CLUT.
        public let clut: Int16

        public init(pict: Int16, count: Int, cellWidth: Int, cellHeight: Int, columns: Int, clut: Int16) {
            self.pict = pict; self.count = count; self.cellWidth = cellWidth; self.cellHeight = cellHeight
            self.columns = columns; self.single = false; self.clut = clut
        }

        public static func single(_ pict: Int16, clut: Int16 = 200) -> Sheet { Sheet(single: pict, clut: clut) }

        private init(single pict: Int16, clut: Int16) {
            self.pict = pict; count = 1; cellWidth = 0; cellHeight = 0; columns = 1; single = true; self.clut = clut
        }
    }

    /// A light a Setup adds: `.AddLight @ 1001bc08 (face, (v, h), 0, 0, 0, colour)` takes the first free of the 200
    /// slots at `_DAT_100a0128` and sets `+0` active, `+1` new, `+4` face, `+0xc` the point, `+0x14` radius = face
    /// width (`+0x50`) >> 1, `+0x18` colour (decompile l. 14275–14322). Neither `MTKillSprite` nor
    /// `.ActiveToIdleSprite` removes it, so an idle sprite's light stays from the level start.
    public struct Light: Equatable, Sendable {
        /// The light face: `.Load1LightFaceFromPICT(pict, width, height)`.
        public let pict: Int16
        public let width: Int
        public let height: Int
        /// The point (`+0xe` h, `+0xc` v).
        public let x: Int
        public let y: Int
        /// `+0x18`.
        public let colour: Int

        public var radius: Int { width >> 1 }
    }

    /// One placed sprite after its Setup.
    public struct Entry: Equatable, Sendable {
        public let type: Int16
        public let spriteClass: SpriteClass
        public let spawn: Spawn
        /// The sheet of the face (nil for `.none`).
        public let sheet: Sheet?
        public let faceIndex: Int
        public let source: FaceSource
        /// The sprite as the Setup leaves it; `face` is the drawn face (nil for `.none`).
        public let slot: SpriteSlot
        /// The light the Setup adds (`.AddLight`), nil when none.
        public let light: Light?
        /// The placement record as the Setup leaves it: the Setups that write defaults back (W2a: 1480–1489's p2 0 →
        /// 0x8c, p3 0 → 0x1e; the Roach's p3 0 → 0xaa, M l. 64940–64944) change it; every other Setup leaves the record
        /// it read.
        public let record: Placement
        /// BA: the sprites the Setup made with its own `.MTNewSprite`s, in call order (the swarm's members, the insect's
        /// body) — each already set up, inserted by the spawn before the parent (`spawnLevelSprites`). The parent's
        /// links to them (`swarm.members`, `siblings.first`) hold indices into this list until then.
        public var children: [SpriteSlot] = []
    }

    /// The state a Setup reads besides its record.
    public struct Context: Sendable {
        public let level: LevelFile
        /// `*_DAT_1009fd94` (player x), read by `.SetupWalkerSprite` for `+0x17e`.
        public let playerX: Int
        /// prefs `+6` Effects (`_DAT_1009fe44 + 6`): the Xichron and money-bag lights need it == 1.
        public let effects: Int16

        /// The live placement records `.SetupLevelSprites` walks (`*_DAT_100a0058 + 4 + 16·i`) when they differ from the
        /// file's (L1): `.SetupLevel` copies a level's snapshot over them on a revisit (M l. 2395–2516,
        /// `SaveBlock.restoreSnapshot`) before the Setups run. nil → the file's `level.placements` (every caller before
        /// L1).
        public let records: [Placement]?

        public init(level: LevelFile, playerX: Int, effects: Int16 = FerazelPrefs().effects,
                    records: [Placement]? = nil) {
            self.level = level
            self.playerX = playerX
            self.effects = effects
            self.records = records
        }

        /// The playerX in effect while `.SetupLevel` runs at a level start: `.GameLoop(hdr+0x2848 − 0x20, …)`
        /// (caller l. 5823) stores `param_1 + 0x32` before it calls `.SetupLevel` (l. 5150–5155, 5165) — (x − 32) + 50.
        public static func levelStartPlayerX(_ header: LevelHeader) -> Int { Int(header.startX) - 0x20 + 0x32 }
    }

    /// `*_DAT_100a0080`: the cache placeholder face (`.Load1EncFaceFromPICT(0x96)`, app file).
    public static let placeholderPict: Int16 = 150

    // MARK: - sheets

    private static let sheets: [Int16: Sheet] = {
        func set(_ p: Int16, _ n: Int, _ w: Int, _ h: Int, _ c: Int, clut: Int16 = 200) -> (Int16, Sheet) {
            (p, Sheet(pict: p, count: n, cellWidth: w, cellHeight: h, columns: c, clut: clut))
        }
        func one(_ p: Int16, clut: Int16 = 200) -> (Int16, Sheet) { (p, .single(p, clut: clut)) }
        var all: [(Int16, Sheet)] = [
            // `.InitBackgroundSprite`: cannon set 0x442 (cached, flag 0); maces 0x5c8+i (cached singles, flag 0 —
            // `backgroundSheets`, W2a); plants 0xa8c+i and tunnels 3000+i (cached singles, flag 1 → level+base).
            set(0x442, 5, 0x96, 0x96, 5),
            // `.InitBonusSprite`: Xichron 0x421 set, torch 0x51b set, singles 0x50c, 0x517, 0x532+i, 0xc80+i.
            set(0x421, 10, 0x20, 0x20, 10), set(0x51b, 6, 10, 0x1c, 6), one(0x50c), one(0x517), one(0x537),
            one(0xc84),
            // `.InitBoxSprite`: 0x426, 0x429 set, 0x51c set, bridges 0x5b8 (cached, flag 1), decorations 0xaf5+i
            // (cached, 0), outcrops 0xb22+i (cached, 1), mushrooms 0xb36+i (cached, 0), signs 0xb56+i, door 0xb5e set,
            // furniture 0xb68+i (cached, 0), NPCs 0xb86+i (cached, 0), crates 0xc12..0xc14.
            one(0x426), set(0x429, 3, 0x54, 100, 3), set(0x51c, 4, 0x21, 0x1f, 4), one(0x5b8, clut: 202),
            one(0xb1a), one(0xb25, clut: 202), one(0xb56), set(0xb5e, 6, 0x3c, 0x58, 6), one(0xc12), one(0xc14),
            one(0xb87), one(0xb88), one(0xb6a), one(0xb6c), one(0xb6f),
            // W3 (`.InitBoxSprite` M l. 58743, 58797–58806): the boulder single 0x42e (boot), the bridge cache 0x5b5
            // (flag 1 → the level+base CLUT, 202 on level 2) and the trampoline cache set 0x5be (flag 0; 4 × 0x36×0x38).
            one(0x42e), one(0x5b5, clut: 202), set(0x5be, 4, 0x36, 0x38, 4),
            // `.InitPlatformSprite` (l. 54477–54496): set 0x578, the ice set 0x2c7, the springboard singles 0x58c…0x58e,
            // the mace chains 0x59a / 0x59c, the chain links 0x599 (60 × 16×16), the see-saw segments 0x59b (45 × 24×24),
            // the catapult 0x582 (7 × 216×200) — at boot under clut 200 (W1).
            set(0x578, 10, 0x50, 0x29, 10), set(0x2c7, 3, 0x28, 0x18, 1), one(0x58c), one(0x58d), one(0x58e),
            one(0x59a), one(0x59c), set(0x599, 0x3c, 0x10, 0x10, 10), set(0x59b, 0x2d, 0x18, 0x18, 1),
            set(0x582, 7, 0xd8, 200, 1),
            // `.InitWalkerSprite`: 0x6a4 single, 0x6a9 set, 0x6e0 set, the 1750's single 0x6d6 (WK2; all cached, 0).
            one(0x6a4), set(0x6a9, 3, 0xcc, 0x59, 1), set(0x6e0, 9, 0x54, 0x5c, 9), one(0x6d6),
            // `.InitCrawlerSprite`: 0x6b0 single (0x5dc+i are absent); `.InitRoachSprite`: 0x6b8 set (cached, 0).
            one(0x6b0), set(0x6b8, 6, 100, 0x36, 6),
        ]
        for p: Int16 in [0xa96, 0xa99, 0xa9a, 0xbba] { all.append(one(p, clut: 202)) }
        all += backgroundSheets.map { ($0.pict, $0) }
        all += backgroundW2bSheets.map { ($0.pict, $0) }
        for p: Int16 in [0xb36, 0xb37, 0xb3a, 0xb43] { all.append(one(p)) }
        // W4 — the level-2 types (the same `.Init<Class>Sprite` calls): spheres 0x532+i and items 0xc80+i (boot
        // singles); the 0x53c / 0x53d sets (`.InitBonusSprite` l. 52313–52316, boot, 6 × 0x2c×0x2a); decorations
        // 0xaf5+i, furniture 0xb68+i and NPCs 0xb86+i (cached, flag 0 — `.InitBoxSprite` l. 58777–58786, 58831); the
        // stalactite set 0xb75 (boot, 24 × 0x20×0x36, 12 columns; its child's set 0xb74 is `boxChildSheets`); the bat
        // set 0x6cc (`.InitBatSprite` l. 68099, cached; `_DAT_100a0a48` not set → flag 0) and the frog set 0x708
        // (`.InitFrogSprite` l. 70116, cached, flag 0).
        for p: Int16 in [0x534, 0xc85, 0xb20, 0xb21, 0xb6d, 0xb6e, 0xb70, 0xb8a] { all.append(one(p)) }
        all += [set(0x53c, 6, 0x2c, 0x2a, 6), set(0x53d, 6, 0x2c, 0x2a, 6), set(0xb75, 0x18, 0x20, 0x36, 0xc),
                set(0x6cc, 0xb, 0x38, 0x34, 0xb), set(0x708, 8, 0x78, 100, 8)]
        // FR: the Salamander set 0x712 (`.InitSalamanderSprite` M l. 70649, cached, 9 × 0x50×100, one row, flag 0).
        all += [set(0x712, 9, 0x50, 100, 9)]
        // BX1 (`.InitBoxSprite` M l. 58745, 58747, 58760, 58785–58786, 58811): the boulders 2 / 3 0x42f / 0x430 and the crate 0xc13
        // (boot singles), the mine cart's cache sets 0xb72 (14 × 0x80×0x60, 7 per row) and 0xb73 (21 × 0x80×0x3a; flag
        // 0), the ice wall 0xb7d (boot single).
        all += [one(0x42f), one(0x430), one(0xc13), one(0xb7d)]
        all += [set(BoxSprite.cart, 0xe, 0x80, 0x60, 7), set(BoxSprite.wheel, 0x15, 0x80, 0x3a, 7)]
        // BT (`.InitBoxSprite` M l. 58791–58796, 58809–58810; boot): the switch-block set 0x4e2 (21 × 0x24×0x24, 7 per
        // row) and its outline single 0x4e4, the spout set 0x5aa (4 × 0x20×0x20), the gate single 0xb7c; the Buttons'
        // sets (`.InitButtonSprite`, `ButtonSprite.sheets`).
        all += [set(0x4e2, 0x15, 0x24, 0x24, 7), one(BoxSprite.switchOffFace), set(0x5aa, 4, 0x20, 0x20, 4),
                one(BoxSprite.gate)]
        all += ButtonSprite.sheets.map { ($0.pict, $0) }
        // LV3 — the level-3 types: the decorations 2812, 2813, 2820, 2821, 2832, 2843 (`.InitBoxSprite` M l. 58775–58778:
        // the 0x2d cache singles 0xaf5+i, flag 0), the rock outcrops 2868 / 2869 (M l. 58818–58823: cache 0xb22+i, flag 1
        // → the level+base CLUT, `levelClutCache`) and the mushroom cluster 2884 (M l. 58824–58827: cache 0xb36+i, flag
        // 0); the Blob set 0x6c2 (`.InitBlobSprite` M l. 67666: cache, 16 × 0x40×0x2c, 16 per row, flag 0); the spikes'
        // set 0x730 (12 × 0x18×0x80, 12 per row) and the singles 0x732 / 0x733 (`.InitBackgroundSprite` M l.
        // 61864–61866: cache, flag 0).
        for p: Int16 in [0xafc, 0xafd, 0xb04, 0xb05, 0xb10, 0xb1b, 0xb44, 0x732, 0x733] { all.append(one(p)) }
        all += [one(0xb34, clut: 202), one(0xb35, clut: 202), set(0x6c2, 0x10, 0x40, 0x2c, 0x10),
                set(BackgroundSprite.wallSpikeSheet, 0xc, 0x18, 0x80, 0xc)]
        // ES: the dart traps' cache sets 0x76c, 0x76e, 0x76f (`.InitBackgroundSprite` M l. 61886–61888: 6 × 0x5c×0x5c,
        // 6 per row, flag 0).
        all += [set(0x76c, 6, 0x5c, 0x5c, 6), set(0x76e, 6, 0x5c, 0x5c, 6), set(0x76f, 6, 0x5c, 0x5c, 6)]
        // BL: the Crab's claw set 0x762 (`.InitCrabSprite` M l. 73964: cache, 6 × 100×100, 6 per row, flag 0) and its
        // link single 0x767 (M l. 73965: `.Cache1EncFaceFromPICT`, flag 0) — level-load caches its Setup marks.
        all += [set(BlobCrab.clawSet, 6, 100, 100, 6), one(BlobCrab.linkFace)]
        // BA: `.InitBatSprite`'s other four cache sets (M l. 68100–68103, flag 0, one row each): the insects 0x744 (9 ×
        // 0x30×0x2c), the swarm members 0x74d (8 × 0x18×0x16), the 1850 family 0x73a / 0x73b (12 × 0x40×0x50).
        all += [set(0x744, 9, 0x30, 0x2c, 9), set(0x74d, 8, 0x18, 0x16, 8), set(0x73a, 0xc, 0x40, 0x50, 0xc),
                set(0x73b, 0xc, 0x40, 0x50, 0xc)]
        // GF: `.InitGremlinSprite`'s three cache sets (M l. 69118–69120, flag 0, one row each): the body 0x6ea and its
        // back layer 0x6eb (10 × 0x84×0x78), the rider 0x6ec (4 × 0x20×0x20); `.InitFloaterSprite`'s Wraith 0x6f4 (6 ×
        // 100×0x50, M l. 69827). Its 0x6fe / 0x6ff (M l. 69828–69829) are absent from the data: the variant is refused.
        all += [set(GremlinFloater.bodySet, 10, 0x84, 0x78, 10), set(GremlinFloater.backSet, 10, 0x84, 0x78, 10),
                set(GremlinFloater.riderSet, 4, 0x20, 0x20, 4), set(GremlinFloater.wraithSet, 6, 100, 0x50, 6)]
        // DL: `.InitDilloSprite`'s four cache sets (M l. 72283–72286, flag 0, one row each, 100×0x50): walk 0x74e (6),
        // curl 0x74f (5), death 0x750 (5), jump 0x751 (2).
        all += [set(Dillo.walkType, 6, 100, 0x50, 6), set(Dillo.curlType, 5, 100, 0x50, 5),
                set(Dillo.deathType, 5, 100, 0x50, 5), set(Dillo.jumpType, 2, 100, 0x50, 2)]
        // GY: `.InitBoxSprite`'s three geyser cache sets (M l. 58813–58815, flag 0): the base 1440 (12 × 0x18×0x10, 4 per
        // row, 3 rows), the head 1441 (6 × 0x30×0x20) and the segment 1442 (6 × 0x14×0x20), one row each of those two.
        all += [set(Geyser.baseSet, 0xc, 0x18, 0x10, 4), set(Geyser.headSet, 6, 0x30, 0x20, 6),
                set(Geyser.segmentSet, 6, 0x14, 0x20, 6)]
        all.append(one(placeholderPict))
        // BN: every face `.InitBonusSprite` loads (`BonusSprite.sheets`; the level-1/2 entries above are the same sheets).
        var table = Dictionary(uniqueKeysWithValues: all)
        for sh in BonusSprite.sheets where table[sh.pict] == nil { table[sh.pict] = sh }
        // CS: `.InitPlayerShotSprite`'s sets (`PlayerShot.sheets`) — the shots' cells for the session's face bounds.
        for sh in PlayerShot.sheets where table[sh.pict] == nil { table[sh.pict] = sh }
        return table
    }()

    /// The Background class's radial bars and balls (`.InitBackgroundSprite` l. 61906–61909: ten
    /// `.Cache1EncFaceFromPICT(0x5c8 + i)`, flag 0 → clut 200) — their Handle re-faces them every frame (W2a). PICT
    /// 1489 is absent from every shipped file: its cache entry keeps the placeholder [LOW: placed on no level].
    public static let backgroundSheets: [Sheet] = (Int16(0x5c8)...0x5d0).map { Sheet.single($0) }

    /// The Background class's W2b sets (`.InitBackgroundSprite` l. 61861–61883, cache flag 0 → clut 200): the springs
    /// 0x47e / 0x47f / 0x480 (`.CacheEncFaceSetFromPICT(…, 4, 0x3c, 0x3c, 4, …)`; 0x481 draws 0x480 mirrored) and the
    /// passages 0xb54 / 0xb55 (`.Cache1EncFaceFromPICT`). The cannon set 0x442 is in the level-1 table above.
    public static let backgroundW2bSheets: [Sheet] = [
        Sheet(pict: 0x47e, count: 4, cellWidth: 0x3c, cellHeight: 0x3c, columns: 4, clut: 200),
        Sheet(pict: 0x47f, count: 4, cellWidth: 0x3c, cellHeight: 0x3c, columns: 4, clut: 200),
        Sheet(pict: 0x480, count: 4, cellWidth: 0x3c, cellHeight: 0x3c, columns: 4, clut: 200),
        .single(0xb54), .single(0xb55),
    ]

    /// The faces a Setup gives a sprite it makes itself (W4): the stalactite's child (`.SetupBoxSprite` 0xb74, M l.
    /// 59397–59400: `+0xc0 = *_DAT_100a0a5c + p1·0x34`, the boot set 0xb74, 12 × 0x20×0x14, `.InitBoxSprite` l.
    /// 58789). FerazelRender loads them.
    public static let boxChildSheets: [Sheet] = [Sheet(pict: 0xb74, count: 0xc, cellWidth: 0x20, cellHeight: 0x14,
                                                       columns: 0xc, clut: 200)]

    /// The sheet a Phase-1 face of PICT `pict` comes from (the level-1 table; nil for any other PICT).
    public static func sheet(pict: Int16) -> Sheet? { sheets[pict] }

    /// The class caches loaded with the cache flag `_DAT_100a0a48` = 1 — converted under the level+base CLUT
    /// `*_DAT_1009ff8c` (header 0x285e, 0 → 202; `ColorLUT.screenClutId`) by `.LoadCachedSpriteFaces` (raw
    /// `1008901c..1008903c`): the bridges 0x5b4…0x5bb and the outcrops 0xb22…0xb35 (`.InitBoxSprite` M l. 58798–58805,
    /// 58818–58823), the trees 0xc08…0xc0f, tunnels 3000…3005 and plants 0xa8c…0xaa9 (`.InitBackgroundSprite` M l.
    /// 61891–61916). The table above names them under 202 (levels 1–2); LV3: an entry takes its level's CLUT (210 on
    /// level 3).
    static func levelClutCache(_ pict: Int16) -> Bool {
        (0x5b4...0x5bb).contains(pict) || (0xb22...0xb35).contains(pict) || (0xc08...0xc0f).contains(pict)
            || (3000...3005).contains(pict) || (0xa8c...0xaa9).contains(pict)
    }

    /// The Platform class's sets (`.InitPlatformSprite`, W1): what its Handles face their sprites from — the platform
    /// set, ice, catapult, springboard, chain links, mace chains and see-saw segments. FerazelRender loads them all.
    public static let platformSheets: [Sheet] = [0x578, 0x2c7, 0x582, 0x58c, 0x58d, 0x58e, 0x599, 0x59a, 0x59b, 0x59c]
        .compactMap { sheets[$0] }

    // MARK: - one Setup

    /// The class Setup for record `p` with a throwaway `FastRand(seed: 1)` — for callers that read faces only.
    /// The forms without a `counting` argument run the Setup as `.SetupLevelSprites` does: inside the counting window
    /// (`*_DAT_1009fe8c` set, a throwaway `EnemyCounting`).
    public static func setup(_ p: Placement, context c: SetupFaces.Context, lightsInUse: Int = 0) throws -> Entry {
        var rng = FastRand(seed: 1)
        return try setup(p, context: c, lightsInUse: lightsInUse, rng: &rng)
    }

    /// The class Setup for record `p` (`.GenerateSprite`'s selection, then the Setup arm).
    /// - Parameter lightsInUse: `*_DAT_100a0124`, the lights added so far (the Xichron light needs < 150).
    /// - Parameter rng: the session stream; the Setup draws as the binary does (plan "F1 ⚑ FastRand sites").
    /// The light's slot (`+0x9a`) is `lightsInUse` — the first free slot of a table with no removal (LT: the session's
    /// spawn adds through its `LightTable` instead, `setup(_:context:lights:rng:)`).
    public static func setup(_ p: Placement, context c: SetupFaces.Context, lightsInUse: Int = 0,
                             rng: inout FastRand) throws -> Entry {
        var counting = EnemyCounting(window: true)
        return try setup(p, context: c, lightsInUse: lightsInUse, rng: &rng, counting: &counting) { _ in
            Int16(lightsInUse)
        }
    }

    /// LT: the Setup with its `.AddLight` made on `lights` (`*_DAT_100a0124` = `lights.count` for the Xichron gate);
    /// the slot `.AddLight` returns goes to `+0x9a`.
    public static func setup(_ p: Placement, context c: SetupFaces.Context, lights: inout LightTable,
                             rng: inout FastRand) throws -> Entry {
        var counting = EnemyCounting(window: true)
        return try setup(p, context: c, lights: &lights, counting: &counting, rng: &rng)
    }

    /// EC: the Setup under the counting window `counting.window` (`*_DAT_1009fe8c`): a counted class sets `+0x1b5` and
    /// adds 1 to `counting.live` only while it is set (`EnemyCounting.countIfWindow`).
    public static func setup(_ p: Placement, context c: SetupFaces.Context, lights: inout LightTable,
                             counting: inout EnemyCounting, rng: inout FastRand) throws -> Entry {
        try setup(p, context: c, lightsInUse: Int(lights.count), rng: &rng, counting: &counting) { l in
            lights.add(face: LightFaceRef(pict: l.pict, width: l.width, height: l.height),
                       x: Int16(truncatingIfNeeded: l.x), y: Int16(truncatingIfNeeded: l.y), vx: 0, vy: 0, accelY: 0,
                       colour: Int16(truncatingIfNeeded: l.colour))
        }
    }

    /// The Setup body; `addLight` makes the `.AddLight` call and returns its slot.
    private static func setup(_ p: Placement, context c: SetupFaces.Context, lightsInUse: Int, rng: inout FastRand,
                              counting: inout EnemyCounting, addLight addToTable: (Light) -> Int16) throws -> Entry {
        guard let (cls, spawn) = SpriteClassTable.classify(type: p.type, p1Negative: p.p1 < 0) else {
            throw Error.unmapped(type: p.type)
        }
        var s = SpriteSlot(type: p.type, x: Int(p.x), y: Int(p.y), recordIndex: Int16(p.index))
        let t = Int(p.type)
        var sheet: Sheet?, index = 0, source = FaceSource.none, light: Light?
        var record = p
        var children: [SpriteSlot] = []
        /// `.AddLight(face, (y + dy, x + dx), 0, 0, 0, colour)` with one of `.InitBonusSprite`'s / `.InitPlayerShotSprite`'s
        /// / `.InitEffectSprite`'s light faces.
        /// The slot `.AddLight` returns — the first free one, = the lights added so far — goes to `+0x9a` (every
        /// `.SetupBonusSprite` site, l. 52455–52700).
        func addLight(_ pict: Int16, _ size: Int, dx: Int, dy: Int, colour: Int) {
            let l = Light(pict: pict, width: size, height: size, x: s.x + dx, y: s.y + dy, colour: colour)
            light = l
            s.light = addToTable(l)
        }

        func face(_ pict: Int16, _ i: Int = 0, _ src: FaceSource) {
            sheet = sheets[pict]
            if let sh = sheet, levelClutCache(pict) {
                let clut = ColorLUT.screenClutId(c.level.header)
                sheet = sh.single ? .single(pict, clut: clut)
                    : Sheet(pict: pict, count: sh.count, cellWidth: sh.cellWidth, cellHeight: sh.cellHeight,
                            columns: sh.columns, clut: clut)
            }
            index = i
            source = src
        }
        /// `.GetBGTile(x >> 5, (y + 0xc) >> 5)` → `.LookupBGTileKind` → `.IsWaterTile` (200..209).
        func inWater() -> Bool {
            let k = c.level.bgKind(tile: c.level.bgTile(col: s.x >> 5, row: (s.y + 0xc) >> 5))
            return LiquidTiles.range.contains(k)
        }

        switch cls {
        case .background:
            BackgroundSprite.setupCommon(&s)                   // l. 61966–61977: layer 1, callbacks 0, `+0xa6` 3, HP 6
            switch t {
            case 0x442...1098:                                 // cannons (l. 62058–62184; W2b `setupCannon`)
                // p1 < 0 (programmed path, `.SetupProgrammedPath`) and p1 > 0 (101…106 rotating / shot-steered; the
                // rest a path without a Setup) are not built: none is placed on levels 1–4. // later: Phase 6.
                guard p.p1 == 0 else { throw Error.notTranscribed(type: p.type) }
                BackgroundSprite.setupCannon(&s, record: p, level: c.level)
                face(0x442, 0, .handle)                        // the Handle aims the cannon (set 0x442, 5 faces)
            case 0x47e...0x481:                                // springs (l. 62046–62219; W2b `setupSpring`)
                BackgroundSprite.setupSpring(&s, level: c.level)
                face(t == 0x481 ? 0x480 : Int16(t), 0, .handle) // the Handle faces `+0x46` of 0x47e / 0x47f / 0x480
            case 0xb54, 0xb55:                                 // passages (l. 62433–62437, 62585–62589; W2b)
                BackgroundSprite.setupPassage(&s)
                face(Int16(t), 0, .setupCached)                // `+0xc0 = cache + 4` (`_DAT_100a0b3c` / `0b38`)
            case 0x5c8...0x5d1:                                // maces / balls (l. 62312)
                face(Int16(t), 0, .setupCached)                // `+0xc0 = PTR_DAT_100a09f4[type − 0x5c8] + 4`
                // On a level's first load that pointer is still the placeholder (PICT 150) face: the binary copies it
                // here, so frame 1 can carry PICT 150 until the Handle's per-frame re-face; Core takes the cached face
                // (`.setupCached`). Not visible on L1 (pendulums at x 2656 / 2756, off screen at the start). 1489
                // (0x5d1): no shipped PICT and no level places it.
                // `+0xb0 = p1` (0 → 0xb); modes 1, 2 move the sprite onto a programmed path (not transcribed). The rest
                // (W2a): `BackgroundSprite.setupMace` — rect, the written-back p2 / p3, one-way, `+0x88`, `+0xa6`; the
                // radial block and the mace chains are made after the insert (`spawnLevelSprites`).
                let mode = p.p1 == 0 ? 0xb : Int(p.p1)
                guard !(1...2).contains(mode) else { throw Error.notTranscribed(type: p.type) }
                record = BackgroundSprite.setupMace(&s, record: p)
            case 0xa8c...0xaef:                                // plants (l. 62629–62668)
                s.layer = -100
                s.lightOverlay = true
                face(Int16(t), 0, .setupCached)
                if p.p1 != 0 { s.mirrored = true }             // + `.FlipHRect` of the hot rect
                if p.p2 != 0 { s.mode = UInt32(truncatingIfNeeded: Int(p.p2) + 0x10000) }
                if p.p3 != 0 { s.layer = 10000 }
            case 3000..<0xbc2:                                 // wall tunnels (l. 62620–62627; W2b `setupTunnel`)
                BackgroundSprite.setupTunnel(&s)
                face(Int16(t), 0, .setupCached)
            case 0x730...0x733:                                // the spikes (M l. 61982–62015, 62279–62309, 62459–62490)
                // LV3 (`BackgroundSprite.setupSpike`): `+0xc0` stays 0 — the Handle faces them every frame (0x730 / 0x731
                // cell `+0x46` of the cache set 0x730, 0x731 mirrored; 0x732 / 0x733 their singles). The entry names
                // that face (`.handle`) for the level start's draw.
                BackgroundSprite.setupSpike(&s, record: p, level: c.level)
                if t <= 0x731 {
                    face(BackgroundSprite.wallSpikeSheet, Int(s.phase), .handle)
                } else {
                    face(Int16(t), 0, .handle)
                }
            case 0x76c...0x76f:                                // the dart traps (M l. 62495–62520; ES)
                // `BackgroundSprite.setupDartTrap`: p1 / p2 defaults written back; `+0xc0` stays 0 — the Handle faces
                // cell `+0x46 >> 2` = 4 of its cache set (0x76d: 0x76c's, mirrored by the Handle). None placed on
                // levels 1–5.
                record = BackgroundSprite.setupDartTrap(&s, record: p)
                face(BackgroundSprite.dartTrapSheet(Int16(t)), Int(s.phase >> 2), .handle)
            case 0xcb1:                                        // level exit: `+0xc0 = 0` (l. 62593)
                s.hotRect = IdleSprites.Rect(top: 0xc, left: 0xc, bottom: 0x54, right: 0x54)   // l. 62594 (W4)
            default:
                throw Error.notTranscribed(type: p.type)
            }

        case .bonus:
            // BN: `.SetupBonusSprite` in full (`BonusSprite.setup`) — every type 0x41f…0xcb0 the class owns; its `.AddLight`s
            // through `addLight` (the session's table). A Handle-faced type (`.handle`) leaves `+0xc0 = 0` in the binary;
            // the Phase-1 stand-in (the Handle's first sheet cell, below) is kept for the level start's draw. The shards'
            // `*(*_DAT_1009fdd8 + 0x80) + 1` (M l. 52531): `.GameLoop` makes the new player only after `.SetupLevel` (M l.
            // 5165–5183), so the Setups read the previous player record's layer — `.SetupPlayerSprite`'s 10 (M l. 42828).
            let records = c.records ?? c.level.placements
            if let f = try BonusSprite.setup(&s, x: Int(p.x), y: Int(p.y), level: c.level, records: records,
                                             effects: c.effects, lightCount: Int16(truncatingIfNeeded: lightsInUse),
                                             counting: counting.window, playerLayer: Int32(Player.layer), rng: &rng,
                                             addLight: { lf, h, v, colour in
                let l = Light(pict: lf.pict, width: lf.width, height: lf.height, x: h, y: v, colour: Int(colour))
                light = l
                return addToTable(l)
            }) {
                face(f.pict, f.index, f.source)
            }

        case .box:
            // `.SetupBoxSprite` (W3, `BoxSprite.setup`): layer, rect, one-way, callbacks, gravity, HP, the type's fields.
            // GY: the geyser arm 1440…1448 (`Geyser.setup`) draws `R(4)` and makes the triple's two children
            // (`Entry.children`, inserted before the parent; its links index them).
            if Geyser.placed.contains(p.type) {
                children = Geyser.setup(&s, record: p, level: c.level, rng: &rng)
            } else {
                BoxSprite.setup(&s, record: p, level: c.level)
            }
            switch t {
            case 0x426:                                        // teleporter 3 (l. 59012)
                face(0x426, 0, .setup)
                if inWater() { s.mode = 0x90000 }
            case 0x429:                                        // save point: set 0x429 cell p1 (l. 59000)
                face(0x429, Int(p.p1), .setup)
            case 0x42e, 0x433, 0x434:                          // boulder / rocks (M l. 59056–59058): the boot single 0x42e
                face(0x42e, 0, .setup)
            case 0x42f, 0x430:                                 // boulders 2 / 3 (M l. 59059–59064; BX1)
                face(Int16(t), 0, .setup)
            case 0xb72, 0xb73:                                 // mine cart / wheel (M l. 59436; BX1): cache 0xb72 cell 0
                face(BoxSprite.cart, 0, .setupCached)
            case 0xb7d:                                        // the 2941 (M l. 59475; BX1): the boot single 0xb7d
                face(0xb7d, 0, .setup)
            case 0xb7c:                                        // the gate 2940 (M l. 59472; BT): the boot single 0xb7c
                face(0xb7c, 0, .setup)
            case 0x4e2...0x4ff:                                // switch blocks (M l. 59584; BT): set 0x4e2 cell t − 0x4e2
                face(0x4e2, t - 0x4e2, .setup)
            case 0x5aa...0x5ad:                                // spouts (M l. 59596; BT): set 0x5aa cell t − 0x5aa
                face(0x5aa, t - 0x5aa, .setup)
            case 0x5a0...0x5a8:                                // geysers (GY): `+0xc0` 0; the eruption arm faces cache 1440
                face(Geyser.baseSet, 0, .handle)
            case 0x5a9:                                        // the geyser head (GY; never placed): `+0xc0` 0, no face
                break
            case 0x51c:                                        // chest (l. 59031)
                if inWater() { s.mode = 0x90000 }
                face(0x51c, 0, .setup)
            case 0x5b5, 0x5b6:                                 // bridges 1461 / 1462 (W3): cache 0x5b5, faced by the Handle
                face(0x5b5, 0, .handle)
            case 0x5b8:                                        // bridge 1464 (l. 59212): cache face by the Handle
                face(0x5b8, 0, .handle)
            case 0x5be:                                        // trampoline (W3): `+0xc0 = cache 0x5be + 4` (face 0)
                face(BoxSprite.trampoline, 0, .setupCached)
            case 0xaf5..<0xb22:                                // decorations (l. 59641)
                face(Int16(t), 0, .setupCached)                // `+0xc0 = cache[type − 0xaf5] + 4`
            case 0xb22..<0xb36:                                // rock outcrops (l. 59683)
                face(Int16(t), 0, .handle)                     // re-faced each frame from cache 0xb22+i
            case 0xb36..<0xb4a:                                // mushrooms (l. 59705)
                face(Int16(t), 0, .handle)
            case 0xb56..<0xb5e:                                // signs (l. 59280)
                face(Int16(t), 0, .setup)                      // `+0xc0 = (&0x100a642c)[type − 0xb56]`
            case 0xb5e, 0xb5f:                                 // doors (l. 59280 else; 0xb5f l. 59238 — W4): set 0xb5e cell 0
                face(0xb5e, 0, .setup)
            case 0xb74:                                        // stalactite (l. 59361–59401; W4): set 0xb75 cell p1
                face(0xb75, Int(p.p1), .setup)
            case 0xb68..<0xb71:                                // furniture (l. 59603): cache, Handle re-faces
                face(Int16(t), 0, .handle)
            case 0xb87..<0xb9a:                                // NPCs (l. 59715): cache 0xb86+i, Handle
                face(Int16(t), 0, .handle)
            case 0xc12...0xc14:                                // crates (l. 59535)
                face(Int16(t), 0, .setup)
            default:
                throw Error.notTranscribed(type: p.type)
            }

        case .button:
            // `.SetupButtonSprite` (BT, `ButtonSprite.setup`): `+0xc0` stays 0 — the first Handle faces 1320…1322 from
            // their sets (the entry names the set, `.handle`; the slot's face stays nil, as the Platforms'); 1323…1329
            // have none.
            ButtonSprite.setup(&s)
            if (0x528...0x52a).contains(t) { face(Int16(t), 0, .handle) }

        case .rope:
            // `.SetupRopeSprite` (W3, `RopeSprite.setup`): no face — the segments the first Handle makes carry them.
            // 3023…3039 have no `.SetupRopeSegArray` arm (seg 0: a division by zero; none placed).
            guard RopeSprite.types.contains(p.type) else { throw Error.notTranscribed(type: p.type) }
            RopeSprite.setup(&s, record: p)

        case .platform:
            // `.SetupPlatformSprite @ 10061f94` (W1, `PlatformSprite.setup`): layer −1, `+0xc0 = 0` — the level-start
            // frame draws no platform; `.DoSetupPlatformSprite` (the first Handle frame) sets set 0x578 + (type −
            // 0x578)·0x34 (the catapult its set 0x582, the springboard its single 0x58c). The entry names that sheet
            // (`.handle`) while the slot's face stays nil. The armless types (0x584…0x58b, 0x58d…0x595: a face index
            // past the set; the one placed, 0x591, is a see-saw arm that clears its face every frame) name none.
            s.oldPosition = SpriteSlot.Point(x: s.x, y: s.y)
            PlatformSprite.setup(&s)
            switch t {
            case 0x578...0x581: face(0x578, t - 0x578, .handle)
            case 0x582, 0x583: face(0x582, 0, .handle)
            case 0x58c: face(0x58c, 0, .handle)
            default: break
            }

        case .walker:
            // `.SetupWalkerSprite @ 10067318` (M l. 56898–57100; WK1, `Walker.setup`): the class fields, the flip rule, the
            // hot rect, the tier, the three draws and the counting window. The face: `+0xc0` = the single 0x6a4 for
            // every type (M l. 56951), then 0x6a9's set cell 0 (M l. 56976), 0x6e0…0x6e9's (M l. 56988), the 1750
            // types 0x6d6…0x6df the single 0x6d6 (M l. 57007; WK2, first placed on level 10); the other types are placed
            // nowhere (enemies-ground §1).
            switch t {
            case 0x6a4: face(0x6a4, 0, .setupCached)
            case 0x6a9: face(0x6a9, 0, .setupCached)
            case 0x6d6...0x6df: face(0x6d6, 0, .setupCached)
            case 0x6e0...0x6e9: face(0x6e0, 0, .setupCached)
            default: throw Error.notTranscribed(type: p.type)       // 1701…1704, 1706…1709: placed nowhere
            }
            Walker.setup(&s, record: p, playerX: c.playerX, rng: &rng, counting: &counting)

        case .crawler:
            // `.SetupCrawlerSprite @ 100659a0` (M l. 56153–56246; CR, `CrawlerRoach.setupCrawler`): the class fields, the
            // state by p1, the tier by p2, the rect and the counting window. `+0xc0 = PTR_DAT_100a09b0[p1 == 0 ? 0 : 1]`,
            // loaded from PICT 0x5dc / 0x5dd, which no shipped file holds (enemies-ground §4): 0. p1 0: the Handle's
            // state 0 (ceiling) sets the face 1712 (`*_DAT_100a09ac`, PICT 0x6b0) — the Phase-1 stand-in; p1 ≠ 0 (placed
            // on no level): no face until the Handle's walk set 0x6ae.
            if p.p1 == 0 { face(0x6b0, 0, .handle) }
            CrawlerRoach.setupCrawler(&s, record: p, counting: &counting)

        case .roach:
            // `.SetupRoachSprite @ 10077914` (M l. 64899–64957; CR, `CrawlerRoach.setupRoach`): `+0xc0` = cache 0x6b8
            // face 0 (M l. 64933); the live record's p3 (`*_DAT_100a0058 + 16·(+0x48) + 0xc`) 0 → 0xaa, written back (M
            // l. 64940–64944); `+0x154` = x and vx 0x4b0 (M l. 64945–64946).
            face(0x6b8, 0, .setupCached)
            record = CrawlerRoach.setupRoach(&s, record: p, counting: &counting)

        case .bat:
            // `.SetupBatSprite @ 1007dc30` (M l. 68108–68316; BA, `Bat.setup`) by sub-range: the 0x6cc… arm (HP 500, the
            // path bats 0x6cd / 0x6ce), the 0x73a… arm (HP 100, `+0x188`, the sheet by the record p1 sign), the swarm
            // 0x74d (its members made here, `Entry.children`) and the insects 0x744…0x74c (the body). The Setup leaves
            // `+0xc0 = 0` but for the insects (cache 0x744 cell 3, M l. 68219): the Handle faces the bats from the cache
            // set 0x6cc / 0x73a / 0x73b; the swarm centre has no face. The path modes 10 / 11 (`.MakeRadial`) are placed
            // on no Bat: refused.
            if [0x6cd, 0x6ce, 0x73b, 0x73c].contains(t) {
                var m = Int(p.p1 < 1 ? -p.p1 : p.p1)
                if 99 < m && m < 200 { m -= 100 }
                if 9 < m && m < 0xc { throw Error.notTranscribed(type: p.type) }
            }
            s.oldPosition = SpriteSlot.Point(x: s.x, y: s.y)           // `.MTNewSprite`'s `+8` / `+6`
            var kids: [SpriteSlot] = []
            Bat.setup(&s, record: p, rng: &rng, counting: &counting) { type, x, y, layer, handler, setup in
                kids.append(SpriteWorld.newRecord(type: type, x: x, y: y, layer: Int16(truncatingIfNeeded: layer),
                                                  handler: handler, record: 0x200, setup: setup))
                return kids.count - 1
            }
            children = kids
            switch t {
            case 0x6cc...0x6d5: face(Bat.batSet, 0, .handle)
            case 0x73a...0x743: face(p.p1 < 0 ? Bat.familyBackSet : Bat.familySet, 0, .handle)
            case 0x744...0x74c: face(Bat.insectSet, 3, .setupCached)
            default: break                                             // the swarm centre 0x74d: no face
            }

        case .blob:
            // `.SetupBlobSprite @ 1007cdb0` (M l. 67671–67735; BL, `BlobCrab.setupBlob`): the class fields, HP and
            // `+0xb8` by type (0x6c2…0x6c5; 0x6c6…0x6cb none), the counting window; `+0xc0` = cache 0x6c2 face 0 (M l.
            // 67726–67727) for every type. No draw.
            s.oldPosition = SpriteSlot.Point(x: s.x, y: s.y)           // `.MTNewSprite`'s `+8` / `+6`
            BlobCrab.setupBlob(&s, counting: &counting)
            face(BlobCrab.blobSet, 0, .setupCached)

        case .crab:
            // `.SetupCrabSprite @ 100894e4` (M l. 73970–74093; BL, `BlobCrab.setupCrab`): the claw, its reach (the live
            // record's p1), the in-water flag from the level's own BG (`.GetBGTile(x >> 5, y >> 5)`, enemies-water-cave
            // §7.3), and its links — the Setup's own `.MTNewSprite(0x767, …, 0x1ff, .SetupCrabSprite)`s, made before the
            // claw is inserted or idled (`Entry.children`; the claw's block holds indices into them until the spawn).
            // `+0xc0 = 0`: the Handle faces the claw from the cache set 0x762 (marked, M l. 74007), the links from the
            // single 0x767. 0x768…0x76b (unplaced) keep the claw Handle with no block: refused. First placed on level 62.
            guard (0x762...0x766).contains(t) else { throw Error.notTranscribed(type: p.type) }
            s.oldPosition = SpriteSlot.Point(x: s.x, y: s.y)
            let level = c.level
            let water: (Int, Int) -> Bool = { col, row in
                UnderWater.isWaterTile(level.bgKind(tile: level.bgTile(col: col, row: row)))
            }
            var kids: [SpriteSlot] = []
            BlobCrab.setupCrab(&s, reach: p.p1, water: water) { x, y, layer, wet in
                kids.append(BlobCrab.makeLink(x: x, y: y, layer: layer, clawInWater: wet, water: water))
                return kids.count - 1
            }
            children = kids
            face(BlobCrab.clawSet, 0, .handle)

        case .frog:
            // `.SetupFrogSprite @ 10081f14` (M l. 70137–70220; FR, `FrogSalamander.setupFrog`): the class fields, the p1
            // variant (HP, `+0xb8`), hdr 0x26cd ≠ 0 → `+0x8e = 1`, the counting window; `+0xc0` = cache 0x708 face 0
            // (l. 70211).
            guard (0x708...0x711).contains(t) else { throw Error.notTranscribed(type: p.type) }
            s.oldPosition = SpriteSlot.Point(x: s.x, y: s.y)           // `.MTNewSprite`'s `+8` / `+6`
            FrogSalamander.setupFrog(&s, record: p, inLiquid: c.level.header.inLiquid != 0, rng: &rng,
                                     counting: &counting)
            face(FrogSalamander.frogSet, 0, .setupCached)               // `+0xc0 = cache 0x708 + 4` (l. 70211)

        case .salamander:
            // `.SetupSalamanderSprite @ 10082f20` (M l. 70654–70703; FR, `FrogSalamander.setupSalamander`): the class
            // fields and the counting window; `+0xc0 = 0` — the first Handle faces it from the cache set 0x712 (marked,
            // l. 70680). The entry names that face (`.handle`). First placed on level 50.
            guard (0x712...0x71b).contains(t) else { throw Error.notTranscribed(type: p.type) }
            s.oldPosition = SpriteSlot.Point(x: s.x, y: s.y)
            FrogSalamander.setupSalamander(&s, rng: &rng, counting: &counting)
            face(FrogSalamander.salamanderSet, 0, .handle)

        case .gremlin:
            // `.SetupGremlinSprite @ 1007fc88` (M l. 69153–69234; GF, `GremlinFloater.setupGremlin`): every type 1770…1779
            // alike — the body (the record) and its two `.MTNewSprite(type, …, 0x1ff, .SetupGremlinSprite)` children, the
            // back layer (layer 9) and the rider (layer 12) (`Entry.children`, inserted before the body; the body's
            // `+0x1d4` / `+0x1d8` hold their indices until the spawn, which also makes the rider's backlink), the path
            // (`.SetupProgrammedPath(s, −1, 0)` — the record's p1 any mode: 10 / 11 reach `.MakeRadial`, made by the
            // spawn after the insert), the counting window. `+0xc0 = 0`: the Handle faces the body from the cache set
            // 0x6ea (marked, M l. 69175); the entry names that face (`.handle`). First placed on level 15.
            s.oldPosition = SpriteSlot.Point(x: s.x, y: s.y)           // `.MTNewSprite`'s `+8` / `+6`
            var kids: [SpriteSlot] = []
            let type = s.type
            GremlinFloater.setupGremlin(&s, record: p, counting: &counting) { x, y, layer, store in
                var k = SpriteWorld.newRecord(type: type, x: x, y: y, layer: Int16(truncatingIfNeeded: layer),
                                              handler: .gremlin, record: 0x1ff) { c in
                    var none = EnemyCounting()                          // a child counts nothing (`+0x48 == 0x1ff`)
                    GremlinFloater.setupGremlin(&c, record: nil, counting: &none) { _, _, _, _ in nil }
                }
                store(&k)
                kids.append(k)
                return kids.count - 1
            }
            children = kids
            face(GremlinFloater.bodySet, 0, .handle)

        case .floater:
            // `.SetupFloaterSprite @ 100814b8` (M l. 69834–69907; GF, `GremlinFloater.setupFloater`): 0x6f4…0x6fd — the
            // hidden period, first delay and teleport box from the record's p1…p3, home, unlit, counted. `+0xc0 = 0`: the
            // Handle faces it from the cache set 0x6f4 (marked, M l. 69876); the entry names that face (`.handle`). The
            // unfinished 0x6fe…0x707 (unplaced): their sets 1790 / 1791 are absent from the data and their home and box
            // stay 0 — the Handle's `FastRand(0)` reseeds from the clock (enemies-flyers §5.1): refused before any
            // tally. First placed on level 62.
            guard (0x6f4...0x6fd).contains(t) else { throw Error.notTranscribed(type: p.type) }
            s.oldPosition = SpriteSlot.Point(x: s.x, y: s.y)
            GremlinFloater.setupFloater(&s, record: p, counting: &counting)
            face(GremlinFloater.wraithSet, 0, .handle)

        case .dillo:
            // `.SetupDilloSprite @ 1008622c` (M l. 72291–72378; DL, `Dillo.setup`): the class fields, HP by type, `+0x188`,
            // the live record's p2 0 → 150 (written back), the bounds, the facing draw, the counting window. `+0xc0` = the
            // global `PTR_DAT_100a0d1c` — the walk set's face 0 once any Dillo Handle has run (M l. 72562–72563), 0 before: the
            // first Handle faces it; the entry names that face (`.handle`). 1872…1879 (unplaced) get HP 0 and max 0: the
            // original always dies on its first frame (the HP < 1 test, M l. 72819, follows the state switch); the idle
            // decision before it divides by the max 0 (plain `divw`, raw 10086a48 — undefined, no trap) only when the
            // `FastRand(10)` timer starts at 0 or 1. A named ◇ for an unplaced variant (bank §8, as the Wraith variants
            // above): refused before any tally. Placed on levels 15 and 22.
            guard t == Int(Dillo.walkType) || t == Int(Dillo.curlType) else { throw Error.notTranscribed(type: p.type) }
            s.oldPosition = SpriteSlot.Point(x: s.x, y: s.y)           // `.MTNewSprite`'s `+8` / `+6`
            record = Dillo.setup(&s, record: p, rng: &rng, counting: &counting)
            face(Dillo.walkType, 0, .handle)

        default:
            throw Error.notTranscribed(type: p.type)
        }

        if source != .none, sheet == nil { throw Error.notTranscribed(type: p.type) }   // a face outside the table
        if source != .none, cls != .platform, cls != .button, let sh = sheet {
            s.face = FaceRef(pict: sh.pict, index: index, set: .encoded)
        }
        return Entry(type: p.type, spriteClass: cls, spawn: spawn, sheet: source == .none ? nil : sheet,
                     faceIndex: index, source: source, slot: s, light: light, record: record, children: children)
    }

    // MARK: - the level spawn

    public struct Spawned: Equatable, Sendable {
        /// The sprites `.GenerateSprite` made now (`MTNewSprite`, inserted by the Setup's layer).
        public var active: ActiveList
        /// The sprites it queued (`.AddIdleSprite`).
        public var idle: IdleSprites
        /// Record indices in `.GenerateSprite` call order.
        public var created: [Int]
        /// The lights the Setups added, in `.AddLight` order (= slot order on a level start with no light in use).
        public var lights: [Light]
        /// The level's placement records after the Setups' write-backs (`Entry.record`), by index (W2a).
        public var records: [Placement]
        /// The three tallies the Setups count while `*_DAT_1009fe8c` is set (`.SetupLevel` sets it around
        /// `.SetupLevelSprites`, M l. 2524–2526, after zeroing them, M l. 2520–2523): `.SetupLevel` stores them as the
        /// level's totals on a first visit (M l. 2528–2536; L1).
        public var tallies = Tallies()
        /// LT: the light table after the Setups — fresh (`.RemoveAllLights`, `.SetupLevel` M l. 2269 / `.InitLighting`
        /// M l. 13611, before `.SetupLevelSprites`), then each Setup's `.AddLight` in spawn order.
        public var lightTable = LightTable()
    }

    /// `*_DAT_1009ffac` secrets, `*_DAT_1009ffb0` Xichrons, `*_DAT_1009ffb4` enemies — each Setup site sets the
    /// sprite's `+0x1b5` and adds 1 only while `*_DAT_1009fe8c` ≠ 0 (L1, transcribed for the classes levels 1–2
    /// place): `.SetupBonusSprite` 0x423 → secrets (M l. 52410–52414), 0x41f / 0x420 → Xichrons (M l. 52463–52467);
    /// enemies: `.SetupCrawlerSprite` (M l. 56236–56240), `.SetupWalkerSprite` (M l. 57090–57094), `.SetupRoachSprite`
    /// (M l. 64947–64951) at their ends (no early return), `.SetupBatSprite`'s arms (M l. 68210–68213, 68234–68237,
    /// 68270–68273, 68282–68285; BA),
    /// `.SetupFrogSprite` at its end (M l. 70211–70215), `.SetupSalamanderSprite` at its end (M l. 70692–70698; FR),
    /// `.SetupBlobSprite` at its end for every type (M l. 67728–67731; LV3, BL). The Crab counts nothing (BL).
    /// `.SetupGremlinSprite` in the body arm (M l. 69227–69230), `.SetupFloaterSprite` for every type (M l. 69900–69903;
    /// GF), `.SetupDilloSprite` at its end for 1870 / 1871 (M l. 72371–72374; DL). // later: Phase 5–6 — the other enemy
    /// classes' sites (Warrior 73069, Demon 74493, Chief 75110, Wizard
    /// 75676, Xichra 76435), some branch-gated, are not transcribed (their Setups throw `notTranscribed` before any
    /// tally). EC: the enemies are `EnemyCounting.live` — each counted Setup's `countIfWindow` — copied here after the
    /// spawn; the secrets and Xichrons are counted here by type, while the window is set.
    public struct Tallies: Equatable, Sendable {
        public var secrets: Int16 = 0
        public var xichrons: Int16 = 0
        public var enemies: Int16 = 0

        public init(secrets: Int16 = 0, xichrons: Int16 = 0, enemies: Int16 = 0) {
            self.secrets = secrets
            self.xichrons = xichrons
            self.enemies = enemies
        }

        /// The site a Setup of `type` (class `cls`) reaches during `.SetupLevelSprites`.
        mutating func count(type: Int16, class cls: SpriteClass) {
            switch cls {
            case .bonus where type == 0x423: secrets &+= 1
            case .bonus where type == 0x41f || type == 0x420: xichrons &+= 1
            default: break
            }
        }
    }

    /// The `.SetupLevelSprites @ 10003cd0` order over a set of live records — `LevelFile.spawnOrder`'s three passes
    /// (flag == 1: type 0x51b, then 0x578…0x595, then every other type ≠ 0), over `records` instead of the file's.
    public static func spawnOrder(_ records: [Placement]) -> [Placement] {
        let active = records.filter { $0.flag == 1 }
        let isPlatform: (Placement) -> Bool = { (0x578...0x595).contains($0.type) }
        return active.filter { $0.type == 0x51b }
            + active.filter(isPlatform)
            + active.filter { $0.type != 0 && $0.type != 0x51b && !isPlatform($0) }
    }

    /// `.SetupLevelSprites @ 10003cd0` (l. 1940–2101): every flag-1 record of type 0x51b, then types 0x578..0x595,
    /// then the rest (type ≠ 0), each pass over records 0 … 510, through `.GenerateSprite @ 10003478` (forceNow 0,
    /// layer −1 → 0): spawned now → `MTNewSprite` (Setup, then `.MTInsertSprite`); queued → `.AddIdleSprite`
    /// (Setup with layer argument 1, then `.ActiveToIdleSprite`, whose face rect `idleFaceRect` answers — the opaque
    /// bounds of the face `+0xc0` holds then, `Rect.noFace` without one).
    /// Core has no face pixels: `FerazelRender.SpriteBlitter.Faces.idleFaceRect` answers the face `+8` rect.
    /// With a throwaway `FastRand(seed: 1)` — for callers that read faces and order only.
    public static func spawnLevelSprites(context c: Context,
                                         idleFaceRect: (Entry) -> IdleSprites.Rect) throws -> Spawned {
        var rng = FastRand(seed: 1)
        return try spawnLevelSprites(context: c, rng: &rng, idleFaceRect: idleFaceRect)
    }

    /// The spawn with the session stream, inside a window of its own (a fresh `EnemyCounting`, window set) — for
    /// callers that keep no live count.
    public static func spawnLevelSprites(context c: SetupFaces.Context, rng: inout FastRand,
                                         idleFaceRect: (Entry) -> IdleSprites.Rect) throws -> Spawned {
        var counting = EnemyCounting(window: true)
        return try spawnLevelSprites(context: c, rng: &rng, counting: &counting, idleFaceRect: idleFaceRect)
    }

    /// The spawn with the session stream: each Setup draws in spawn order (plan "F1 ⚑ FastRand sites"). EC: under
    /// `counting` (the caller opens and closes the window around it, as `.SetupLevel` does); `tallies.enemies` is the
    /// live count it ends with (i16, as `.SetupLevel` stores it, M l. 2533).
    public static func spawnLevelSprites(context c: Context, rng: inout FastRand, counting: inout EnemyCounting,
                                         idleFaceRect: (Entry) -> IdleSprites.Rect) throws -> Spawned {
        guard c.level.header.autoScrollEnable == 0 else { throw Error.autoScrollSprites }
        var out = Spawned(active: ActiveList(), idle: IdleSprites(), created: [], lights: [],
                          records: c.records ?? c.level.placements)
        for p in c.records.map(spawnOrder) ?? c.level.spawnOrder {
            var e = try setup(p, context: c, lights: &out.lightTable, counting: &counting, rng: &rng)
            if counting.window { out.tallies.count(type: e.type, class: e.spriteClass) }
            if e.type == BoxSprite.cart || e.type == BoxSprite.wheel, e.slot.recordIndex != -1 {
                // The cart arm of `.SetupBoxSprite` (M l. 59444–59463; BX1) makes two children before the cart is
                // inserted or idled: `MTNewSprite(0xb72, +8, +6, 100, −1, .SetupBoxSprite)` — its Setup's head stores
                // layer 2, the sort key — then `+0x80 = 100` (no re-sort) and face = cache 0xb72 cell 7 (`+0x20`); then
                // `MTNewSprite(0xb73, +8, +6, +0x80 − 1, −1, …)` then `+0x80 = −1` and face = cache 0xb73 cell 0. Both
                // take the record −1 arm (empty rect, gravity 0). The cart's `+0x1d4` / `+0x1d8` = the children.
                func child(_ type: Int16, layer: Int32, face: FaceRef) -> Int {
                    var k = SpriteSlot(type: type, x: e.slot.oldPosition.x, y: e.slot.oldPosition.y, recordIndex: -1)
                    BoxSprite.setup(&k, record: p, level: c.level)
                    let id = out.active.insert(k)
                    out.active.update(id: id) { s in
                        s.layer = layer
                        s.face = face
                    }
                    return id
                }
                var parent = e.slot
                parent.siblings.first = child(BoxSprite.cart, layer: 100,
                                              face: FaceRef(pict: BoxSprite.cart, index: 7, set: .encoded))
                parent.siblings.second = child(BoxSprite.wheel, layer: -1,
                                               face: FaceRef(pict: BoxSprite.wheel, index: 0, set: .encoded))
                e = Entry(type: e.type, spriteClass: e.spriteClass, spawn: e.spawn, sheet: e.sheet,
                          faceIndex: e.faceIndex, source: e.source, slot: parent, light: e.light, record: e.record)
            }
            if e.type == BoxSprite.stalactite, e.slot.recordIndex != -1 {
                // `.SetupBoxSprite`'s stalactite arm (M l. 59383–59400) makes its child before the parent is inserted
                // or idled: `.MTNewSprite(0xb74, +8, +6, +0x80 − 1, −1, .SetupBoxSprite)` — the record −1 arm — then
                // `child +0xc0 = *_DAT_100a0a5c + p1·0x34` and the parent's `+0x1d4` = the child. The child is active
                // from the level start whether the parent spawns or idles (no draw).
                var k = SpriteSlot(type: e.type, x: e.slot.oldPosition.x, y: e.slot.oldPosition.y, recordIndex: -1)
                BoxSprite.setup(&k, record: p, level: c.level)
                k.face = FaceRef(pict: boxChildSheets[0].pict, index: Int(p.p1), set: .encoded)
                var parent = e.slot
                parent.siblings.first = out.active.insert(k)
                e = Entry(type: e.type, spriteClass: e.spriteClass, spawn: e.spawn, sheet: e.sheet,
                          faceIndex: e.faceIndex, source: e.source, slot: parent, light: e.light, record: e.record)
            }
            if !e.children.isEmpty {
                // BA: the Bat Setup's own `.MTNewSprite`s (M l. 68186–68196, 68228–68233) — the swarm's members and the
                // insect's body, record 0x200 — are inserted before the parent is inserted or idled; they stay active
                // whether the parent spawns or idles (enemies-flyers §7.5). The parent's links become their ids. BL: the
                // Crab's links (record 0x1ff) likewise.
                let ids = e.children.map { out.active.insert($0) }
                var parent = e.slot
                if let f = parent.siblings.first { parent.siblings.first = ids[f] }
                if let f = parent.siblings.second { parent.siblings.second = ids[f] }   // GF: the Gremlin's rider
                if var block = parent.swarm {
                    block.members = block.members.map { $0.map { ids[$0] } }
                    parent.swarm = block
                }
                if var block = parent.crabLinks {                      // BL: the Crab's links (M l. 74046–74058)
                    block.links = block.links.map { $0.map { ids[$0] } }
                    parent.crabLinks = block
                }
                e = Entry(type: e.type, spriteClass: e.spriteClass, spawn: e.spawn, sheet: e.sheet,
                          faceIndex: e.faceIndex, source: e.source, slot: parent, light: e.light, record: e.record)
            }
            out.created.append(p.index)
            out.records[p.index] = e.record
            if let l = e.light { out.lights.append(l) }
            switch e.spawn {
            case .now:
                let id = out.active.insert(e.slot)
                if BackgroundSprite.maces.contains(e.type) {
                    // `.MakeRadial` + `.MakeRadiusSprites` inside the 1480–1489 Setup (W2a): the mace chains are
                    // `.MTNewSprite`s of their own (no `FastRand`). 1480–1489 always spawn now (`SpriteClassTable`).
                    // ⚑ The throwaway `SpriteWorld` here has its own seed-1 `rng`, not `rng` above: a `FastRand` draw
                    // added to `makeRadial` would be swallowed silently — thread the stream through first.
                    let w = SpriteWorld(level: c.level, active: out.active)
                    BackgroundSprite.makeRadial(w, id: id, record: e.record)
                    out.active = w.active
                }
                if e.spriteClass == .gremlin {
                    // GF: the rider's backlink `+0x1d4` = the body (M l. 69219), and for path modes 10 / 11 the
                    // `.MakeRadial` of `.SetupProgrammedPath` (M l. 39354–39378; no `FastRand`) — both need the body's id.
                    // The Gremlin class always spawns now (`SpriteClassTable`).
                    let w = SpriteWorld(level: c.level, active: out.active)
                    GremlinFloater.linkRider(w, parent: id)
                    ProgrammedPath.makeRadial(w, id: id, record: e.record)
                    out.active = w.active
                }
            case .idle:
                _ = out.idle.add(e.slot, faceRect: idleFaceRect(e))
            }
        }
        out.tallies.enemies = Int16(truncatingIfNeeded: counting.live)
        return out
    }
}
