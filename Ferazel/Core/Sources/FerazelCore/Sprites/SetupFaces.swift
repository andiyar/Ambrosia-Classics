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
    }

    /// The state a Setup reads besides its record.
    public struct Context: Sendable {
        public let level: LevelFile
        /// `*_DAT_1009fd94` (player x), read by `.SetupWalkerSprite` for `+0x17e`.
        public let playerX: Int

        public init(level: LevelFile, playerX: Int) {
            self.level = level
            self.playerX = playerX
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
            // `.InitBackgroundSprite`: cannon set 0x442 (cached, flag 0); maces 0x5c8+i (cached singles, flag 0);
            // plants 0xa8c+i and tunnels 3000+i (cached singles, flag 1 → level+base).
            set(0x442, 5, 0x96, 0x96, 5), one(0x5cd),
            // `.InitBonusSprite`: Xichron 0x421 set, torch 0x51b set, singles 0x50c, 0x517, 0x532+i, 0xc80+i.
            set(0x421, 10, 0x20, 0x20, 10), set(0x51b, 6, 10, 0x1c, 6), one(0x50c), one(0x517), one(0x537),
            one(0xc84),
            // `.InitBoxSprite`: 0x426, 0x429 set, 0x51c set, bridges 0x5b8 (cached, flag 1), decorations 0xaf5+i
            // (cached, 0), outcrops 0xb22+i (cached, 1), mushrooms 0xb36+i (cached, 0), signs 0xb56+i, door 0xb5e set,
            // furniture 0xb68+i (cached, 0), NPCs 0xb86+i (cached, 0), crates 0xc12..0xc14.
            one(0x426), set(0x429, 3, 0x54, 100, 3), set(0x51c, 4, 0x21, 0x1f, 4), one(0x5b8, clut: 202),
            one(0xb1a), one(0xb25, clut: 202), one(0xb56), set(0xb5e, 6, 0x3c, 0x58, 6), one(0xc12), one(0xc14),
            one(0xb87), one(0xb88), one(0xb6a), one(0xb6c), one(0xb6f),
            // `.InitPlatformSprite`: set 0x578.
            set(0x578, 10, 0x50, 0x29, 10),
            // `.InitWalkerSprite`: 0x6a4 single, 0x6a9 set, 0x6e0 set (all cached, 0).
            one(0x6a4), set(0x6a9, 3, 0xcc, 0x59, 1), set(0x6e0, 9, 0x54, 0x5c, 9),
            // `.InitCrawlerSprite`: 0x6b0 single (0x5dc+i are absent); `.InitRoachSprite`: 0x6b8 set (cached, 0).
            one(0x6b0), set(0x6b8, 6, 100, 0x36, 6),
        ]
        for p: Int16 in [0xa96, 0xa99, 0xa9a, 0xbba] { all.append(one(p, clut: 202)) }
        for p: Int16 in [0xb36, 0xb37, 0xb3a, 0xb43] { all.append(one(p)) }
        all.append(one(placeholderPict))
        return Dictionary(uniqueKeysWithValues: all)
    }()

    /// The sheet a Phase-1 face of PICT `pict` comes from (the level-1 table; nil for any other PICT).
    public static func sheet(pict: Int16) -> Sheet? { sheets[pict] }

    // MARK: - one Setup

    /// The class Setup for record `p` (`.GenerateSprite`'s selection, then the Setup arm).
    public static func setup(_ p: Placement, context c: SetupFaces.Context) throws -> Entry {
        guard let (cls, spawn) = SpriteClassTable.classify(type: p.type, p1Negative: p.p1 < 0) else {
            throw Error.unmapped(type: p.type)
        }
        var s = SpriteSlot(type: p.type, x: Int(p.x), y: Int(p.y), recordIndex: Int16(p.index))
        let t = Int(p.type)
        var sheet: Sheet?, index = 0, source = FaceSource.none

        func face(_ pict: Int16, _ i: Int = 0, _ src: FaceSource) {
            sheet = sheets[pict]
            index = i
            source = src
        }
        /// `.GetBGTile(x >> 5, (y + 0xc) >> 5)` → `.LookupBGTileKind` → `.IsWaterTile` (200..209).
        func inWater() -> Bool {
            let k = c.level.bgKind(tile: c.level.bgTile(col: s.x >> 5, row: (s.y + 0xc) >> 5))
            return (200..<210).contains(k)
        }

        switch cls {
        case .background:
            s.layer = 1                                        // `+0x80 = 1` (l. 61970)
            switch t {
            case 0x442...1098:                                 // cannons (l. 62058)
                s.layer = 1000
                face(0x442, 0, .handle)                        // the Handle aims the cannon (set 0x442, 5 faces)
            case 0x5c8...0x5d1:                                // maces / balls (l. 62312)
                face(Int16(t), 0, .setupCached)                // `+0xc0 = PTR_DAT_100a09f4[type − 0x5c8] + 4`
                // `+0xb0 = p1` (0 → 0xb); modes 12, 13, 14 with a record clear `+0x88`; modes 1, 2 move the sprite onto
                // a programmed path (not transcribed).
                let mode = p.p1 == 0 ? 0xb : Int(p.p1)
                guard !(1...2).contains(mode) else { throw Error.notTranscribed(type: p.type) }
                if (12...14).contains(mode) { s.lightOverlay = false }
            case 0xa8c...0xaef:                                // plants (l. 62629–62668)
                s.layer = -100
                s.lightOverlay = true
                face(Int16(t), 0, .setupCached)
                if p.p1 != 0 { s.mirrored = true }             // + `.FlipHRect` of the hot rect
                if p.p2 != 0 { s.mode = UInt32(truncatingIfNeeded: Int(p.p2) + 0x10000) }
                if p.p3 != 0 { s.layer = 10000 }
            case 3000..<0xbc2:                                 // wall tunnels (l. 62620–62627)
                s.layer = 0
                face(Int16(t), 0, .setupCached)
            case 0xcb1:                                        // level exit: `+0xc0 = 0` (l. 62593)
                break
            default:
                throw Error.notTranscribed(type: p.type)
            }

        case .bonus:
            s.layer = 1                                        // l. 52383
            switch t {
            case 0x41f:                                        // gold Xichron: Handle face set 0x421, `+0x46 >> 1`
                s.lightOverlay = false
                face(0x421, 0, .handle)
            case 0x423:                                        // secret-area trigger: no face (l. 52403)
                s.lightOverlay = false
            case 0x50c:                                        // money bag: Handle face `*_DAT_100a08e0` (PICT 0x50c)
                s.lightOverlay = false
                face(0x50c, 0, .handle)
            case 0x517:                                        // rock pile (l. 52567): Handle face PICT 0x517; `+0x88` kept
                face(0x517, 0, .handle)
            case 0x51b:                                        // torch (l. 52541): Handle face set 0x51b, `+0x46 >> 1`
                s.lightOverlay = false
                face(0x51b, 0, .handle)
            case 0x532...0x53b:                                // spheres: Handle face `_DAT_100a089c[type − 0x532]`
                s.lightOverlay = false                         // the shared tail before the range arms (l. 52642)
                face(Int16(t), 0, .handle)
            case 0xc80...0xcb0:                                // items: `+0xc0 = _DAT_100a08a0[type − 0xc80]` (l. 52667)
                s.lightOverlay = false
                face(Int16(t), 0, .setup)
            default:
                throw Error.notTranscribed(type: p.type)
            }

        case .box:
            s.layer = 2                                        // l. 58939
            switch t {
            case 0x426:                                        // teleporter 3 (l. 59012)
                face(0x426, 0, .setup)
                if inWater() { s.mode = 0x90000 }
            case 0x429:                                        // save point: set 0x429 cell p1 (l. 59000)
                face(0x429, Int(p.p1), .setup)
            case 0x51c:                                        // chest (l. 59031)
                if inWater() { s.mode = 0x90000 }
                s.layer = 0
                face(0x51c, 0, .setup)
            case 0x5b4...0x5bb:                                // bridges (l. 59212): layer 0, cache face by the Handle
                s.layer = 0
                s.mirrored = t == 0x5b6 || t == 0x5b9
                guard t == 0x5b8 else { throw Error.notTranscribed(type: p.type) }
                face(0x5b8, 0, .handle)
            case 0xaf5..<0xb22:                                // decorations (l. 59641)
                s.layer = -1
                s.lightOverlay = true
                face(Int16(t), 0, .setupCached)                // `+0xc0 = cache[type − 0xaf5] + 4`
                if p.p1 != 0 { s.mirrored = true }
                if p.p2 != 0 { s.mode = UInt32(truncatingIfNeeded: Int(p.p2) + 0x10000) }
                if p.p3 != 0 { s.layer = 10000 }
            case 0xb22..<0xb36:                                // rock outcrops (l. 59683)
                s.layer = 0x96
                s.lightOverlay = false
                let D = c.level.header.darknessEnable == 0 ? 0 : c.level.lightByte(col: s.x >> 5, row: s.y >> 5)
                if D > 4 { s.mode = 0x10006 }                  // `.GetAmbDarkVal(x, y)` (`@1001aaf8`)
                if D > 7 { s.mode = 0x10007 }
                if t == 0xb28 { s.mode = 0xb0005 }
                face(Int16(t), 0, .handle)                     // re-faced each frame from cache 0xb22+i
            case 0xb36..<0xb4a:                                // mushrooms (l. 59705)
                s.layer = 0x78
                face(Int16(t), 0, .handle)
            case 0xb56..<0xb5e:                                // signs (l. 59280)
                s.layer = 0
                face(Int16(t), 0, .setup)                      // `+0xc0 = (&0x100a642c)[type − 0xb56]`
            case 0xb5e:                                        // door right (l. 59280 else): set 0xb5e cell 0
                s.layer = 0
                face(0xb5e, 0, .setup)
            case 0xb68..<0xb71:                                // furniture (l. 59603): cache, Handle re-faces
                s.layer = 0
                face(Int16(t), 0, .handle)
            case 0xb87..<0xb9a:                                // NPCs (l. 59715): cache 0xb86+i, Handle
                s.layer = 0
                face(Int16(t), 0, .handle)
            case 0xc12...0xc14:                                // crates (l. 59535)
                s.lightOverlay = true
                face(Int16(t), 0, .setup)
            default:
                throw Error.notTranscribed(type: p.type)
            }

        case .platform:
            s.layer = -1                                       // l. 54514
            // `+0xc0 = 0`; `.DoSetupPlatformSprite` (first Handle frame) sets set 0x578 + (type − 0x578)·0x34.
            guard (0x578...0x581).contains(t) else { throw Error.notTranscribed(type: p.type) }
            face(0x578, t - 0x578, .handle)

        case .walker:
            s.layer = 4                                        // l. 56933
            s.mirrored = t == 0x6e0
            switch t {
            case 0x6a4: face(0x6a4, 0, .setupCached)
            case 0x6a9: face(0x6a9, 0, .setupCached)
            case 0x6e0...0x6e9: face(0x6e0, 0, .setupCached)
            default: throw Error.notTranscribed(type: p.type)
            }
            // `+0x17e` (l. 56965–57003): 0x6e0..0x6e9 when x + 0x32 < playerX, the others when playerX < x + 0x32.
            if (0x6e0...0x6e9).contains(t) {
                if s.x + 0x32 < c.playerX { s.mirrored = true }
            } else if c.playerX < s.x + 0x32 {
                s.mirrored = true
            }
            switch p.p3 {                                      // tiers (l. 57013–57078)
            case 1: s.mode = 0x10010
            case 2: s.mode = 0x10011
            case 3: s.mode = 0x10012
            case 4: s.mode = 0x10013
            case 5: s.mode = 0x10014
            case 6: s.mode = 0x10015
            default: break
            }
            if p.p4 != 0 { s.margins = SpriteSlot.Margins(left: 0x5f4, right: 0x5f4, top: 0x5f4, bottom: 0x5f4) }

        case .crawler:
            s.layer = 0xb                                      // l. 56180
            guard p.p1 == 0 else { throw Error.notTranscribed(type: p.type) }   // p1 ≠ 0: floor crawler, face 0x5dd
            // `+0xc0 = PTR_DAT_100a09b0[0]`, loaded from PICT 0x5dc, which no shipped file holds (enemies-ground §4):
            // 0. The Handle's state 0 (ceiling) sets the face 1712 (`*_DAT_100a09ac`, PICT 0x6b0).
            face(0x6b0, 0, .handle)
            switch p.p2 {                                      // tiers (enemies-ground §4)
            case 2: s.mode = 0x10003
            case 3: s.mode = 0x1000f
            case 1: s.mode = 0x10002
            default: break
            }

        case .roach:
            s.layer = 0xb                                      // l. 64923
            face(0x6b8, 0, .setupCached)

        default:
            throw Error.notTranscribed(type: p.type)
        }

        if source != .none, sheet == nil { throw Error.notTranscribed(type: p.type) }   // a face outside the table
        if source != .none, let sh = sheet {
            s.face = FaceRef(pict: sh.pict, index: index, set: .encoded)
        }
        return Entry(type: p.type, spriteClass: cls, spawn: spawn, sheet: source == .none ? nil : sheet,
                     faceIndex: index, source: source, slot: s)
    }

    // MARK: - the level spawn

    public struct Spawned: Equatable, Sendable {
        /// The sprites `.GenerateSprite` made now (`MTNewSprite`, inserted by the Setup's layer).
        public var active: ActiveList
        /// The sprites it queued (`.AddIdleSprite`).
        public var idle: IdleSprites
        /// Record indices in `.GenerateSprite` call order.
        public var created: [Int]
    }

    /// `.SetupLevelSprites @ 10003cd0` (l. 1940–2101): every flag-1 record of type 0x51b, then types 0x578..0x595,
    /// then the rest (type ≠ 0), each pass over records 0 … 510, through `.GenerateSprite @ 10003478` (forceNow 0,
    /// layer −1 → 0): spawned now → `MTNewSprite` (Setup, then `.MTInsertSprite`); queued → `.AddIdleSprite`
    /// (Setup with layer argument 1, then `.ActiveToIdleSprite`, whose face rect `idleFaceRect` answers — the opaque
    /// bounds of the face `+0xc0` holds then, `Rect.noFace` without one).
    public static func spawnLevelSprites(context c: Context,
                                         idleFaceRect: (Entry) -> IdleSprites.Rect = { _ in .noFace }) throws -> Spawned {
        guard c.level.header.autoScrollEnable == 0 else { throw Error.autoScrollSprites }
        var out = Spawned(active: ActiveList(), idle: IdleSprites(), created: [])
        for p in c.level.spawnOrder {
            let e = try setup(p, context: c)
            out.created.append(p.index)
            switch e.spawn {
            case .now:
                out.active.insert(e.slot)
            case .idle:
                _ = out.idle.add(e.slot, faceRect: idleFaceRect(e))
            }
        }
        return out
    }
}
