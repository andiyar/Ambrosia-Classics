import Foundation

/// The Box class (W3, BX1; pickups-boxes §2.1–§2.2, §2.4.1, §2.4.11; pickups-boxes-2 §4.2, §7): `.SetupBoxSprite @
/// 1006b43c` (M l. 58892–59727) for every Box type placed on levels 1–4 and the arms they share, `.HandleBoxSprite @
/// 1006d878` (M l. 60030–61180: the arms and the common tail), `.KillCrate @ 1006fa98` (M l. 61181–61327),
/// `.HitBoxSprite @ 10070024` (M l. 61328–61482), `.KillBox @ 100705f0` (M l. 61483–61520) and `.HitBoxTileSprite @
/// 10070718` (M l. 61521–61683). The Box arm of `.HitPlayerSprite` is `HitPlayerSprite.box`. Faces are `SetupFaces`'s
/// (the class caches of `.InitBoxSprite`).
///
/// Not built (named where they stand): the Handle arms of the chest 0x51c and the doors 0xb5e / 0xb5f (BX2), the gate
/// 0xb7c, the switch blocks 0x4e2…0x4ff and the spouts 0x5aa…0x5ad (BT), the tree trunk 0x2c8 / 0x2c9 (SW), the geysers
/// 0x5a0…0x5a9 and the pipes 0x5d2…0x5d5 (Phase 5), the carpet 0x438 / 0x439, the spiked balls 0x5c3 / 0x5c4, the table
/// 0xb71 and the snowball 0xbfe (Phase 6) — those types still return at once from the Handle (`handleBuilt`) and stand
/// still; `.HitBoxSprite`'s Statue partner (SW) and its carpet arm (Phase 6).
public enum BoxSprite {
    /// The trampoline (PICT 1470, the 4-face set `_DAT_100a0a2c`).
    public static let trampoline: Int16 = 0x5be
    /// The save point (PICT 1065, the 3-face set `_DAT_100a0a28`; S1).
    public static let savePoint: Int16 = 0x429
    /// The bridges 1460…1467 (0x5b4…0x5bb).
    public static let bridges: ClosedRange<Int16> = 0x5b4...0x5bb
    /// The stalactite 2932 (W4; its child is made by `SetupFaces.spawnLevelSprites`).
    public static let stalactite: Int16 = 0xb74
    /// The mine cart 2930 (0xb72) and its wheel 2931 (0xb73) — a placed cart makes one child of each (BX1).
    public static let cart: Int16 = 0xb72
    public static let wheel: Int16 = 0xb73
    /// The weakened ice wall 2941 (0xb7d).
    public static let iceWall: Int16 = 0xb7d
    /// The crates 3090…3092 (0xc12…0xc14; their Setup arm and Handle arm) and the range `.HitBoxSprite` and the spin
    /// stomp treat as crates (0xc12…0xc1b, `cmpwi 0xc12` / `0xc1c`).
    public static let crates: ClosedRange<Int16> = 0xc12...0xc14
    public static let crateRange: ClosedRange<Int16> = 0xc12...0xc1b
    /// The boulders 1070…1072 and the falling rocks 1075 / 1076 (`LAB_1006dafc`, M l. 60222–60284).
    public static func isBoulder(_ t: Int16) -> Bool { (0x42e...0x430).contains(t) || t == 0x433 || t == 0x434 }
    /// The switch blocks 1250…1279.
    public static let switchBlocks: ClosedRange<Int16> = 0x4e2...0x4ff
    /// `.KillCrate`'s sounds: `*_DAT_100a02fc` = 492 (the crate breaks), `*_DAT_1009fdec` = 435 (the explosive's bang);
    /// `.KillBox` / the 2941's `*_DAT_100a01e0` = 424; `.HitBoxTileSprite`'s `*_DAT_100a03ac` = 436 (the boulder's thud)
    /// and `*_DAT_100a041c` = 303 (the spiked balls); pickups-boxes-2 §1.2.
    static let crateSound: Int16 = 492, bangSound: Int16 = 435, breakSound: Int16 = 424, thudSound: Int16 = 436,
               spikeSound: Int16 = 303
    /// The Bonus types `.KillCrate` makes with `MTNewSprite(…, .SetupBonusSprite)` (M l. 61273–61276): 1290…1293,
    /// 1055, 1300…1302, 1305, 1306, 1340, 1341.
    static func isBonusDrop(_ t: Int16) -> Bool {
        (0x50a...0x50d).contains(t) || t == 0x41f || (0x514...0x516).contains(t) || (0x519...0x51a).contains(t)
            || (0x53c...0x53d).contains(t)
    }
    /// The faces BX1's run-time spawns read that no placed type loads: the cart's sets 0xb72 (14 × 0x80×0x60, 7 per
    /// row) and 0xb73 (21 × 0x80×0x3a) for its children (`.InitBoxSprite` M l. 58785–58786, cached, flag 0). The debris
    /// 0xc1b, the 3201 pieces and the dust 0x442 (faced from 0x4b0) and the 0x4b7 are the Effect sheets the renderer
    /// already loads; the drops are `dropSheets`.
    public static let spawnSheets: Set<SetupFaces.Sheet> = [
        SetupFaces.Sheet(pict: cart, count: 0xe, cellWidth: 0x80, cellHeight: 0x60, columns: 7, clut: 200),
        SetupFaces.Sheet(pict: wheel, count: 0x15, cellWidth: 0x80, cellHeight: 0x3a, columns: 7, clut: 200),
    ]

    /// The Bonus faces the crates among `records` can drop (`.KillCrate`, p1 0 / 1, p2 > 0): `.InitBonusSprite` loads
    /// every Bonus face at boot, but `BonusSprite.sheets` names PICTs the data lacks (3109, 3200), so a renderer loads
    /// the drops of its level's crates only — a Bonus drop by its face PICT (0x41f → 0x421, 0x519 → 0x51d, 0x51a →
    /// 0x51e), any other p2 by its own PICT (the items).
    public static func dropSheets(_ records: [Placement]) -> Set<SetupFaces.Sheet> {
        var out: Set<SetupFaces.Sheet> = []
        for p in records where crates.contains(p.type) && (0...1).contains(p.p1) && 0 < p.p2 {
            let pict: Int16 = p.p2 == 0x41f ? 0x421 : p.p2 == 0x519 ? 0x51d : p.p2 == 0x51a ? 0x51e : p.p2
            if let sh = BonusSprite.sheets.first(where: { $0.pict == pict }) { out.insert(sh) }
        }
        return out
    }

    @inline(__always) static func h(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }

    @inline(__always) static func rect(_ left: Int, _ top: Int, _ right: Int, _ bottom: Int) -> IdleSprites.Rect {
        IdleSprites.Rect(top: top, left: left, bottom: bottom, right: right)       // `SetRect(r, left, top, right, bottom)`
    }

    /// `.SetupBoxSprite` (M l. 58892–59727) — every field but the face (`SetupFaces` picks it): the head (l. 58934–58950)
    /// `.InitSprite`, `+0x84 = +0x86 = 0`, layer `+0x80 = 2`, the Box Handle, `+0x5c` `.HitBoxSprite`, `+0x1f8`
    /// `.HitBoxTileSprite`, `+0xa6 = 3`, gravity 0x151, HP 600, the position from the spawn copy; the type arm; the tail
    /// `LAB_1006cf1c` (l. 59722–59727): 24.8 from `+8`/`+6`, `+0xa`/`+0xc` = `+6`/`+8`, `+0x13c = 0x80`. The teleporters'
    /// and the chest's `.IsWaterTile` test (`+0xb8 = 0x90000`) is `SetupFaces`'s, with the faces (Phase 1). No arm of a type
    /// placed on levels 1–2 draws `FastRand` (the draws are 0x439's and the geysers', l. 59086 / 59145).
    ///
    /// Transcribed arms: teleporters 0x424…0x426, the save point 0x429, boulders / rocks 0x42e…0x430, 0x433, 0x434, the
    /// chest 0x51c, the bridges 0x5b4…0x5bb, the trampoline 0x5be, signs 0xb56…0xb5d, doors 0xb5e / 0xb5f, crates
    /// 0xc12…0xc14, the stalactite 0xb74 (W4), and the post-chain blocks: switch blocks 0x4e2…0x4ff, furniture 0xb68…0xb70, decorations
    /// 0xaf5…0xb21, outcrops 0xb22…0xb35, mushrooms 0xb36…0xb49, NPCs 0xb87…0xb99; BX1: the mine cart 0xb72 / wheel
    /// 0xb73, the ice wall 0xb7d. The other arms (several make sprites or draw `FastRand` at Setup) leave the head's
    /// fields — // later: SW (tree trunk 0x2c8/0x2c9), BT (the gate 0xb7c), Phase 5
    /// (geysers 0x5a0…0x5a9, pipes 0x5d2…0x5d5), Phase 6 (carpet 0x438/0x439, spiked balls 0x5c3/0x5c4, the table
    /// 0xb71, the snowball 0xbfe). Their write-back flags come with them: the geysers' `+0x189` and their two parts'
    /// `+0x188` (M l. 59127, 59174, 59181), the gate 0xb7c's `+0x188` (M l. 59470; the 2941's is built).
    public static func setup(_ s: inout SpriteSlot, record p: Placement, level: LevelFile) {
        let t = s.type
        s.oldPosition = SpriteSlot.Point(x: s.x, y: s.y)                       // the spawn copy `+8` / `+6`
        s.layer = 2
        s.handler = .box
        s.hasHit = true
        s.hasTileHit = true
        s.counterA6 = 3
        s.gravity = 0x151
        s.hp = 600
        switch t {
        case 0x424...0x426:                                // teleporters (l. 58950–58962, 58983–58995, 59012–59024)
            s.gravity = 0
            s.oneWay = true
            s.hotRect = rect(0, -4, 0x20, 0x1a)
        case 0x429:                                        // save point (l. 59001–59009): face = set cell p1
            s.gravity = 0
            s.oneWay = true
            s.hotRect = rect(0x21, 0x3f, 0x33, 99)
        case 0x42e...0x430, 0x433, 0x434:                  // boulders / falling rocks (`LAB_1006b89c`, l. 59055–59075)
            s.margins = SpriteSlot.Margins(left: 0x80, right: 0x80, top: 0x80, bottom: 0x80)
            s.slip = 0x14
            s.pushMass = 0x8c
            s.friction = 0x46
            s.phase = 0
            s.gravity = 0x100
            s.vx = 0
            s.windScale = 0x100
            s.hotRect = rect(4, 0, 0x1c, 0x1c)
        case 0x51c:                                        // chest (l. 59030–59048)
            s.layer = 0
            s.gravity = 0
            s.counterA6 = 4
            s.oneWay = true
            s.phase = 0
            s.hasHit = false
            s.hotRect = rect(0, 7, 0x1c, 0x1e)
        case bridges:                                      // bridges (l. 59186–59232)
            s.gravity = 0
            s.oneWay = false
            s.layer = 0
            s.mirrored = false
            s.hasHit = false
            switch t {
            case 0x5b4: s.hotRect = rect(0, 0, 0x108, 0x18)
            case 0x5b5: s.hotRect = rect(6, 0, 0x9e, 0x18)
            case 0x5b6: s.mirrored = true; s.hotRect = rect(6, 0, 0x9e, 0x18)
            case 0x5b7: s.hotRect = rect(0, 0, 0x108, 0x28)
            case 0x5b8: s.hotRect = rect(8, 0, 0x8c, 0x28)
            case 0x5b9: s.mirrored = true; s.hotRect = rect(0xe, 0, 0x92, 0x28)
            case 0x5ba:
                // later: Phase 4 — `+0x1e8 = .GetRopeBridgeHeight` (platforms-ropes-radial §3.7) and `.GenerateSprite`'s
                // idle 0x5bb; the rope bridge is placed on no shipped level.
                s.hotRect = rect(-0x10, 0x32, 0x11c, 0x78)
            default:                                       // 0x5bb: the face-only part, layer 0x32, empty rect
                s.layer = 0x32
                s.hotRect = rect(0, 0, 0, 0)
            }
        case trampoline:                                   // trampoline (l. 59256–59268)
            s.hasTileHit = false
            s.hasHit = false
            s.phase = 0
            s.gravity = 0
            s.oneWay = true
            s.layer = 0x3c
            s.hotRect = rect(7, 0x10, 0x2c, 0x37)
        case 0xb56...0xb5d:                                // signs, books, plaques (l. 59280–59316)
            s.hasTileHit = false
            s.hasHit = false
            s.phase = 0
            s.gravity = 0
            s.oneWay = true
            s.layer = 0
            switch t {
            case 0xb56, 0xb5b:
                s.hotRect = rect(4, 7, 0x22, 0x1f)
                s.classWord15c = 1                         // standable (the Box arm's gate, M l. 49304–49307)
            case 0xb57: s.hotRect = rect(0, 0, 0x1a, 0x28)
            case 0xb58: s.hotRect = rect(0, 0, 0x14, 0x1e)
            case 0xb59: s.hotRect = rect(0, 0, 0x48, 0x2d)
            case 0xb5a: s.hotRect = rect(0, 0, 0x34, 0x20)
            default: break                                 // 0xb5c, 0xb5d: no rect
            }
        case 0xb5e:                                        // door right (l. 59317–59322)
            s.phase = 0
            s.gravity = 0
            s.layer = 0
            s.hotRect = rect(0, -0x40, 0x18, 0x98)
        case 0xb5f:                                        // door left (l. 59237–59245)
            s.mirrored = true
            s.phase = 0
            s.gravity = 0
            s.layer = 0
            s.hotRect = rect(0x24, -0x40, 0x3c, 0x98)
        case stalactite:                                   // stalactite (l. 59361–59401; W4)
            if s.recordIndex == -1 {
                // The child the stalactite's own Setup makes (`.MTNewSprite(…, −1, …)`): `+0x110`, `+0x5c`, `+0x1f8` 0,
                // layer 1. The parent gives it its face (`SetupFaces.spawnLevelSprites`).
                s.gravity = 0
                s.hasHit = false
                s.hasTileHit = false
                s.layer = 1
            } else {
                // gravity 0, one-way, SetRect(9, 10, 0x18, 0x2a); HP = p2 (0 → 0x96), `+0x14c` = p3 (0 → 0x40),
                // `+0x150` = p4 (0 → 100), `+0x154` = x (`+0xc`). The child and the face are `SetupFaces`'.
                s.gravity = 0
                s.oneWay = true
                s.hotRect = rect(9, 10, 0x18, 0x2a)
                s.hp = p.p2 == 0 ? 0x96 : p.p2
                s.classTimer = p.p3 == 0 ? 0x40 : Int32(p.p3)
                s.classWord150 = p.p4 == 0 ? 100 : Int32(p.p4)
                s.classWord154 = Int32(Int16(truncatingIfNeeded: s.x))
            }
        case cart, wheel:                                  // the mine cart / wheel (M l. 59428–59466; BX1)
            if s.recordIndex == -1 {
                // A child the cart's own Setup makes (`.MTNewSprite(0xb72 / 0xb73, +8, +6, …, −1, .SetupBoxSprite)`):
                // `SetRect(+0x34, 0, 0, 0, 0)`, gravity 0 (its callbacks stay the head's).
                s.hotRect = rect(0, 0, 0, 0)
                s.gravity = 0
            } else {
                // Face: the cache set 0xb72 cell 0 (`SetupFaces`); the two children are `SetupFaces.spawnLevelSprites`'
                // (made before the cart is inserted, as the stalactite's). `+0x80 = 0` is stored before them.
                s.pushMass = 0xa0
                s.slip = 0
                s.phase = 0
                s.gravity = 0x208
                s.layer = 0
                s.friction = 6
                s.classTimer = 0
                s.hotRect = rect(0x1e, 0x32, 0x5a, 0x50)
            }
        case iceWall:                                      // the 2941's half of the gate arm (M l. 59469–59497; BX1)
            // The arm is shared with the gate 0xb7c (its face and the header-0x26cd tint) // later: BT.
            s.keepRecord = true                            // `+0x188 = 1`
            s.hp = 300
            s.flashTable = 1                               // `+0x1b4 = 1`
            s.pushMass = 0
            s.slip = 0
            s.phase = 0
            s.gravity = 0xb4
            s.layer = 0
            s.friction = 6
            s.classTimer = 0
            s.oneWay = false
            s.clip.top = 4                                 // `+0x1bc = 4`
            s.classWord158 = Int32(Int16(truncatingIfNeeded: s.y))   // `+0x158 = +0xa`
            s.hasTileHit = false
            s.hasHit = false
            s.gravity = 0
            s.hotRect = rect(0, 0, 0x20, 0x74)
        case 0xc12...0xc14:                                // crates (l. 59535–59560)
            s.classTimer = Int32(p.p1)
            s.gravity = 0
            s.oneWay = false
            s.hp = 5
            s.lightOverlay = true
            s.pushMass = 0x78
            s.friction = 0x5a
            s.phase = 0
            s.gravity = 0x100
            s.windScale = 0x100
            s.hotRect = rect(4, 0, 0x23, 0x20)
        default:
            break
        }
        // The blocks after the type chain (l. 59563–59721), reached by the types the chain does not `goto` out of.
        switch t {
        case 0x4e2...0x4ff:                                // switch blocks (l. 59563–59590): snapped to 8 px
            func snap(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v) >> 3) << 3 }
            s.oldPosition = SpriteSlot.Point(x: snap(s.oldPosition.x), y: snap(s.oldPosition.y))
            s.x = snap(s.x)
            s.y = snap(s.y)
            if s.recordIndex != -1 { s.classTimer = Int32(p.p1) }
            s.hotRect = rect(1, 1, 0x23, 0x23)
            s.gravity = 0
            s.oneWay = false
            s.layer = 0 &- (Int32(Int16(truncatingIfNeeded: s.y)) &* 2 &+ Int32(Int16(truncatingIfNeeded: s.x)))
            s.hp = 1
            s.hasHit = false
            s.hasTileHit = false
            if t == 0x4f6 {
                s.mode = 0xb0001
                s.lightOverlay = true
            }
        case 0xb68...0xb70:                                // furniture (l. 59603–59640)
            s.phase = 0
            s.gravity = 0
            s.layer = 0
            switch t {
            case 0xb68: s.hotRect = rect(4, 0, 0x33, 0x3a)
            case 0xb69: s.hotRect = rect(5, 1, 0x32, 0x3a)
            case 0xb6a: s.hotRect = rect(10, 1, 0x2e, 0x38); s.oneWay = true
            case 0xb6b: s.hotRect = rect(0, 0, 0x17, 0x28); s.oneWay = true
            case 0xb6c: s.hotRect = rect(4, 0x16, 0x22, 0x33); s.oneWay = true
            case 0xb6d: s.hotRect = rect(0xe, 0x17, 0x28, 0x28); s.oneWay = true
            case 0xb6e: s.hotRect = rect(6, 0, 0x37, 0x20)
            case 0xb6f: s.hotRect = rect(2, 3, 0x4b, 0x1a)
            default: s.hotRect = rect(3, 5, 0x4d, 0x20)    // 0xb70
            }
        case 0xaf5...0xb21:                                // decorations (l. 59641–59682)
            s.hasHit = false
            s.hasTileHit = false
            s.layer = -1
            s.lightOverlay = true
            s.hotRect = rect(0, 0, 0, 0)
            s.oneWay = true
            switch t {
            case 0xb0b: s.hotRect = rect(0xf, 0xd, 0x32, 0x28); s.oneWay = false
            case 0xb10: s.hotRect = rect(0xe, 4, 0x27, 0x45)
            case 0xb11: s.hotRect = rect(5, 4, 0x3b, 0x46)
            case 0xb12: s.hotRect = rect(2, 6, 0x1c, 0x23)
            case 0xb13: s.hotRect = rect(10, 4, 0x1e, 0x21)
            case 0xb14: s.hotRect = rect(0, 0xe, 0x1f, 0x24)
            default: break
            }
            if p.p1 != 0 {
                s.mirrored = true
                // later: `.FlipHRect(+0x34, face +6)` — Core has no face record; every decoration placed on levels 1–2
                // has the empty rect, which the flip leaves empty (left = right = w): no contact either way.
            }
            if p.p2 != 0 { s.mode = UInt32(truncatingIfNeeded: Int(p.p2) + 0x10000) }
            if p.p3 != 0 { s.layer = 10000 }
            s.gravity = 0
        case 0xb22...0xb35:                                // rock outcrops (l. 59683–59704)
            s.hasHit = false
            s.hasTileHit = false
            s.layer = 0x96
            s.lightOverlay = false
            // `.GetAmbDarkVal(x, y)` twice (`@1001aaf8`): the level light byte when darkness is on.
            let D = level.header.darknessEnable == 0 ? 0 : level.lightByte(col: s.x >> 5, row: s.y >> 5)
            if D > 4 { s.mode = 0x10006 }
            if D > 7 { s.mode = 0x10007 }
            if t == 0xb28 { s.mode = 0xb0005 }
            s.hotRect = rect(0x15, 0x14, 0x47, 0x54)
            s.oneWay = true
            s.gravity = 0
        case 0xb36...0xb49:                                // mushrooms (l. 59705–59714)
            s.hasHit = false
            s.hasTileHit = false
            s.layer = 0x78
            s.oneWay = true
            s.gravity = 0
            s.hotRect = rect(0, 0, 0, 0)
        case 0xb87...0xb99:                                // NPCs (l. 59715–59721): the rect comes from the Handle's face
            s.phase = 0
            s.gravity = 0
            s.layer = 0
            s.oneWay = true
        default:
            break
        }
        // `LAB_1006cf1c` (l. 59722–59727).
        s.x256 = Int32(truncatingIfNeeded: s.oldPosition.x) << 8
        s.y256 = Int32(truncatingIfNeeded: s.oldPosition.y) << 8
        s.x = s.oldPosition.x
        s.y = s.oldPosition.y
        s.pushForce = 0x80
    }

    /// Whether the type's `.HandleBoxSprite` runs (the arm and the common tail). The types whose arm is not built yet
    /// return at once and stand still: the chest 0x51c and the doors 0xb5e / 0xb5f (// later: BX2), the gate 0xb7c, the
    /// switch blocks 0x4e2…0x4ff and the spouts 0x5aa…0x5ad (// later: BT), the tree trunk 0x2c8 / 0x2c9 (// later:
    /// SW), the geysers 0x5a0…0x5a9 and the pipes 0x5d2…0x5d5 (// later: Phase 5), the carpet 0x438 / 0x439, the spiked
    /// balls 0x5c3 / 0x5c4, the table 0xb71 and the snowball 0xbfe (// later: Phase 6). Every other Box runs: the built
    /// arms (W3 trampoline and bridges, S1 save point, C1 NPCs, BX1 boulders and rocks, stalactite, mine cart, crates,
    /// the 2907 timer's countdown, the 2941's death) and the types with no arm (teleporters, signs, decorations,
    /// outcrops, mushrooms, furniture, the wheel, the crate range 0xc15…0xc1b), which go through the block chain's
    /// faces (M l. 61088–61151) to the tail.
    public static func handleBuilt(_ t: Int16) -> Bool {
        switch t {
        case 0x51c, 0xb5e, 0xb5f, 0xb7c, switchBlocks, 0x5aa...0x5ad, 0x2c8, 0x2c9, 0x5a0...0x5a9, 0x5d2...0x5d5, 0x438,
             0x439, 0x5c3, 0x5c4, 0xb71, 0xbfe:
            return false
        default:
            return true
        }
    }

    /// The test form: a solver over `w`, a scratch light table, Effects 1.
    public static func handle(world w: SpriteWorld, id: Int, faceBounds: ((FaceRef) -> IdleSprites.Rect)? = nil) {
        var scratch = LightTable()
        handle(world: w, id: id, solver: TileSolver(world: w), lights: &scratch, effects: 1, faceBounds: faceBounds)
    }

    /// `.HandleBoxSprite` (M l. 60030–61180) for the types that run (`handleBuilt`):
    /// - `+0xe9` or `+0x1b2` → return; `.StandardSpriteHandles`; `+0x182 = 0` (`boxPairLatch`);
    /// - 0x5be (l. 60555–60563): face = the cache set `_DAT_100a0a2c` [`+0x46`]; `+0x46 > 0` → `+0x46 += 1`, past 3 → 0;
    /// - 0x429 (M l. 60191–60195, S1): face = `*_DAT_100a0a28 + p1·0x34` — the set cell of the **live** record's p1
    ///   every frame (0 the empty pedestal, 1 the statue facing right, 2 facing left; save-continue §9.1);
    /// - 0x5b4…0x5bb (l. 60565–60591): face = the class cache (0x5b5 / 0x5b6 → 0x5b5, 0x5b8 / 0x5b9 → 0x5b8, the others
    ///   their own);
    /// - the boulders and rocks (`LAB_1006dafc`, M l. 60222–60284; `boulder`); the stalactite with a record (M l.
    ///   60596–60620; `stalactiteArm`); the cart with a record (M l. 60871–60936; `cartArm`); the crates 0xc12…0xc14
    ///   (M l. 61078–61084): `.MTChangeSpriteLayer(−(2y + x))` (the list re-sort — a crate moved past the walk's place is
    ///   handled again that frame), HP < 1 → `.KillCrate`; the 2907 timer 0xb5b (M l. 60786–60791): `+0xa6 > 0` → −1;
    ///   the 2941 (M l. 61016–61040; `iceWallArm`);
    /// - every other type reaches the block chain (M l. 61088–61151): the switch blocks (not run, BT), then the face
    ///   from the class caches — decorations 0xaf5…0xb21 (`0x1009b500 + type·0x10` = the cache entry), outcrops
    ///   0xb22…0xb35, mushrooms 0xb36…0xb49, furniture 0xb68…0xb70 (each `cache[type − first] + 4`); the NPCs 0xb87…0xb99
    ///   (C1): 0xb8d with the record's p3 ≠ 0 → `+0x17e = 1`; face = the class cache single of the type; `+0x46 = 0`,
    ///   gravity 0, layer 0 (stored, no re-sort); the hot rect = the face's bounds (`faceBounds`, nil → empty); one-way;
    /// - the tail (`tail`).
    /// - Parameters: `solver` the session's tile solver (the fall), `lights` its light table (`.KillCrate`'s effects
    ///   and drops), `effects` prefs+6, `faceBounds` a face's bounds (`face +8`) — the NPC arm's hot rect.
    public static func handle(world w: SpriteWorld, id: Int, solver: TileSolver, lights: inout LightTable,
                              effects: Int16, faceBounds: ((FaceRef) -> IdleSprites.Rect)? = nil) {
        guard let s0 = w.active.record(id: id), handleBuilt(s0.type), !s0.dead, !s0.handleSkip else { return }
        w.standardSpriteHandles(id)
        w.active.update(id: id) { $0.boxPairLatch = false }
        let t = s0.type
        let own = liveRecord(w, s0.recordIndex)
        switch t {
        case trampoline:
            w.active.update(id: id) { s in
                s.face = FaceRef(pict: trampoline, index: Int(s.phase), set: .encoded)
                if 0 < s.phase {
                    s.phase += 1
                    if 3 < s.phase { s.phase = 0 }
                }
            }
        case savePoint:
            w.active.update(id: id) { $0.face = FaceRef(pict: savePoint, index: Int(own?.p1 ?? 0), set: .encoded) }
        case bridges:
            let cache: Int16 = t == 0x5b6 ? 0x5b5 : (t == 0x5b9 ? 0x5b8 : t)
            w.active.update(id: id) { $0.face = FaceRef(pict: cache, index: 0, set: .encoded) }
        case _ where isBoulder(t):
            boulder(w, id: id)
        case stalactite:
            if s0.recordIndex != -1 { stalactiteArm(w, id: id) }
        case cart:
            if s0.recordIndex != -1 { cartArm(w, id: id) }
        case crates:
            if let s = w.active.record(id: id) {
                w.changeLayer(id: id, layer: Int16(truncatingIfNeeded: 0 - (h(s.y) * 2 + h(s.x))))
            }
            if let s = w.active.record(id: id), s.hp < 1 { killCrate(w, id: id, lights: &lights, effects: effects) }
        case 0xb5b:
            w.active.update(id: id) { if 0 < $0.counterA6 { $0.counterA6 -= 1 } }
        case iceWall:
            iceWallArm(w, id: id)
        default:
            // The block chain (M l. 61088–61151): the switch blocks' part does not run here (`handleBuilt`, BT).
            switch t {
            case 0xaf5...0xb21, 0xb22...0xb35, 0xb36...0xb49, 0xb68...0xb70:
                w.active.update(id: id) { $0.face = FaceRef(pict: t, index: 0, set: .encoded) }
            case HitPlayerSprite.npcs:
                let p3 = own?.p3 ?? 0
                w.active.update(id: id) { s in
                    if t == 0xb8d && p3 != 0 { s.mirrored = true }
                    let f = FaceRef(pict: t, index: 0, set: .encoded)
                    s.face = f
                    s.phase = 0
                    s.gravity = 0
                    s.layer = 0
                    s.hotRect = faceBounds?(f) ?? IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0)
                    s.oneWay = true
                }
            default:
                break
            }
        }
        tail(w, id: id, solver: solver, lights: &lights, effects: effects)
    }

    /// The live record `i` (`*_DAT_100a0058 + 16·i`); nil — read as zeros — outside the table (−1, and the 0x200 of
    /// run-time spawns, plan hazard "Record index 0x200").
    static func liveRecord(_ w: SpriteWorld, _ i: Int16) -> Placement? {
        w.records.indices.contains(Int(i)) ? w.records[Int(i)] : nil
    }

    /// The common tail `LAB_1006f948` (M l. 61152–61177): `.ApplyFriction(+0x114)`; type ≠ 0x438 / 0x439 with `+0xcd`
    /// (grounded last frame) → `.FootPressure` (`HandleKeys.footPressure`); `.EnforceMaxSpeed(0x1838)`; `+0x1c += vy`;
    /// `+0xcd = +0xce`; gravity ≠ 0 (or 0x438 / 0x439) → `.ApplyGravityAndSeparateFromTiles` with the tile callback
    /// `.HitBoxTileSprite` (`hitTile`) when `+0x1f8` is set; a placed cart 0xb72: its children `+0x1d4` / `+0x1d8` take
    /// its pixel position (`+0xa`/`+0xc` as one word — the wheel 0x26 lower), `+0x11c` and `+0x128`; type ≠ 0 →
    /// `.BoxCleanUp`: `.BoxUW @ 1006d758` (`+0x120 ≠ 0` ∧ `+0x11c == 0` → `.Splash(s, 4)`) then `.BoxClean` (M l.
    /// 60000–60015): the centre `+0x10 = x + left + (right − left) >> 1`, `+0xe` likewise, `+0xdc = 0`, `+0xd6 = 0`.
    /// `+0x1c += vy` comes before the integration's own `y += vy`, so a falling box moves by the old and the new vy.
    static func tail(_ w: SpriteWorld, id: Int, solver: TileSolver, lights: inout LightTable, effects: Int16) {
        w.active.update(id: id) { s in
            s.applyFriction(s.friction)
            if s.type != 0x438 && s.type != 0x439 && s.onSprite != 0 { HandleKeys.footPressure(&s) }
            s.enforceMaxSpeed(0x1838)
            s.y256 &+= s.vy
            s.onSprite = s.groundKind
        }
        if let s = w.active.record(id: id), s.gravity != 0 || s.type == 0x438 || s.type == 0x439 {
            if s.hasTileHit {
                withoutActuallyEscaping({ (sv: TileSolver, i: Int, c: TilePos, k: Int, l: TileLayer) in
                    hitTile(sv, id: i, pos: c, kind: k, layer: l, lights: &lights, effects: effects)
                }) { pass in solver.applyGravityAndSeparate(id, pass: pass) }
            } else {
                solver.applyGravityAndSeparate(id, pass: nil)
            }
        }
        if let s = w.active.record(id: id), s.type == cart, s.recordIndex != -1 {
            for (sib, dy) in [(s.siblings.first, 0), (s.siblings.second, 0x26)] {
                guard let sib else { continue }                   // no free record at Setup: the binary stores at 0
                w.active.update(id: sib) { c in
                    c.y = h(s.y + dy)
                    c.x = s.x
                    c.waterRow = s.waterRow
                    c.waterKind = s.waterKind
                }
            }
        }
        guard let s = w.active.record(id: id), s.type != 0 else { return }
        if s.lastWater != 0, s.waterRow == 0 { Splash.splash(w, id: id, mode: 4) }
        w.active.update(id: id) { s in
            let r = s.hotRect
            s.centre.x = h(s.x + r.left + ((r.right - r.left) >> 1))
            s.centre.y = h(s.y + r.top + ((r.bottom - r.top) >> 1))
            s.ridden = nil
            s.slope = 0
        }
    }

    /// `LAB_1006dafc` (M l. 60222–60284), the boulders 0x42e…0x430 and the rocks 0x433 / 0x434:
    /// - `+0x160 < 0` (a Wizard's hovering rock, pickups-boxes-2 §5): `+0x5c`, `+0x1f8` 0, `+0x88` 0, gravity 0,
    ///   `+0x160 += 1`; `+0xb8` blinks — below −10 0xb0000 / 0xb0002 by parity (even / odd), else 0xb0002 / 0; at
    ///   `+0x160 ≥ 0` gravity 0x96, `+0xb8 = 0`, both callbacks back, vx = (x − `+0xc6`)·256 (its drawn motion);
    /// - else the roll: d = `.PEDistance(vx, grounded ? 0 : vy)` (grounded = `+0xcd` ∨ `+0xce`), n = d·360 / 0x6900
    ///   (C division; d ≥ 0), `+0x46` += n when vx < 1 else −= n, wrapped into 0…359; `+0x1aa = +0x46` (the drawn
    ///   angle), `+0x88 = 0`, `+0x89 = 1`.
    static func boulder(_ w: SpriteWorld, id: Int) {
        guard let s0 = w.active.record(id: id) else { return }
        if s0.classWord160 < 0 {
            w.active.update(id: id) { s in
                s.hasHit = false
                s.hasTileHit = false
                s.lightOverlay = false
                s.gravity = 0
                s.classWord160 &+= 1
                let u = s.classWord160
                if u < -10 {
                    s.mode = u & 1 == 0 ? 0xb0000 : 0xb0002
                } else {
                    s.mode = u & 1 == 0 ? 0xb0002 : 0
                }
                if -1 < s.classWord160 {
                    s.gravity = 0x96
                    s.mode = 0
                    s.hasHit = true
                    s.hasTileHit = true
                    s.vx = (Int32(h(s.x)) - Int32(h(s.drawnX))) &* 0x100
                }
            }
            return
        }
        let grounded = s0.onSprite != 0 || s0.groundKind != 0
        let d = Int32(truncatingIfNeeded: FerazelSession.peDistance(Int(s0.vx), grounded ? 0 : Int(s0.vy)))
        let n = Int16(truncatingIfNeeded: (d &* 0x168) / 0x6900)
        w.active.update(id: id) { s in
            if s.vx < 1 { s.phase &+= n } else { s.phase &-= n }
            while s.phase < 0 { s.phase &+= 0x168 }
            while 0x167 < s.phase { s.phase &-= 0x168 }
            s.rotation = s.phase
            s.lightOverlay = false
            s.dynamicLight = true
        }
    }

    /// The placed stalactite (M l. 60596–60620; pickups-boxes-2 §4.2): with u = `+0xa6` (the shake frames
    /// `.HitBoxSprite` sets): u < 1 or HP < −0xf9 → (HP < 1 → gravity 0xfa: it falls as an ordinary Box); else
    /// x = home `+0x154` − max(u >> 2, 1) for an even u, + for an odd one (`+0x14` = that ·256, `+0xc` from it), u − 1.
    /// The Setup's `+0xa6 = 3` makes it shake three frames when its Handle first runs.
    static func stalactiteArm(_ w: SpriteWorld, id: Int) {
        w.active.update(id: id) { s in
            let u = s.counterA6
            if u < 1 || s.hp < -0xf9 {
                if s.hp < 1 { s.gravity = 0xfa }
            } else {
                var d = u >> 2                                    // u > 0: the `srawi; addze` rounding adds nothing
                if d < 1 { d = 1 }
                s.x256 = (u & 1 == 0 ? s.classWord154 &- Int32(d) : s.classWord154 &+ Int32(d)) &* 0x100
                s.x = Int(Int16(truncatingIfNeeded: s.x256 >> 8))
                s.counterA6 = u &- 1
            }
        }
    }

    /// The placed mine cart 0xb72 (M l. 60871–60936): `+0x186` (ridden) with `+0x112 < 0xe` → `+0x112 += 1`; the face
    /// row k by the ground kind `+0xce` under it — 3 / 4 / 7 → 0, 0xc / 0x10 / 0x18 → 2, 0xf / 0x17 / 0x1f → 5,
    /// 0x20 / 0x21 → 1, 0x22 / 0x23 → 4, 0x2c / 0x2d → 3, 0x2e / 0x2f → 6, anything else keeps `+0x14c`; face = cache set
    /// 0xb72 [`+0x14c`], the child `+0x1d4`'s [`+0x14c` + 7]; the wheel `+0x1d8`: its `+0x14c` = k (when found), its
    /// `+0x46` += vx >> 9 (i16) wrapped into 0…0x17, face = set 0xb73 [its `+0x14c` + (`+0x46` >> 3)·7].
    static func cartArm(_ w: SpriteWorld, id: Int) {
        guard let s0 = w.active.record(id: id) else { return }
        var k: Int16 = -1
        switch s0.groundKind {
        case 3, 4, 7: k = 0
        case 0xc, 0x10, 0x18: k = 2
        case 0xf, 0x17, 0x1f: k = 5
        case 0x20, 0x21: k = 1
        case 0x22, 0x23: k = 4
        case 0x2c, 0x2d: k = 3
        case 0x2e, 0x2f: k = 6
        default: break
        }
        w.active.update(id: id) { s in
            if s.ridingLatch && s.slip < 0xe { s.slip += 1 }
            if k != -1 { s.classTimer = Int32(k) }
            s.face = FaceRef(pict: cart, index: Int(s.classTimer), set: .encoded)
        }
        guard let s = w.active.record(id: id) else { return }
        if let c = s.siblings.first {
            w.active.update(id: c) { $0.face = FaceRef(pict: cart, index: Int(s.classTimer) + 7, set: .encoded) }
        }
        if let wh = s.siblings.second {
            w.active.update(id: wh) { c in
                if k != -1 { c.classTimer = Int32(k) }
                c.phase &+= Int16(truncatingIfNeeded: s.vx >> 9)
                while 0x17 < c.phase { c.phase &-= 0x18 }
                while c.phase < 0 { c.phase &+= 0x18 }
                c.face = FaceRef(pict: wheel, index: Int(c.classTimer) + Int(c.phase >> 3) * 7, set: .encoded)
            }
        }
    }

    /// The 2941's half of the gate arm (M l. 61016–61040; raw `1006f564..1006f5b0`): `+0x183 = 0` (no reader, not
    /// kept); the open test of the record's p1 is made and then overridden (`unaff_r19 = 0`) — no draws; HP < 1 →
    /// `.ExplodeFaceIntoParticles(+0xc0, (+0xa, +0xc), 2, 2, 2, 0x32, 100)`, `+0xe9 = 1`, `FastRand(5000)` and
    /// `.STPlay3DSoundPitched(424, 1, 0x100, centre, R + 43000)`. // later: BT — the rest of the arm (the closed gate's
    /// descent toward `+0x158` with its idle-only sound, the clip `+0x1bc`); a 2941 is placed first on level 30.
    static func iceWallArm(_ w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id), s.hp < 1 else { return }
        ExplodeFace.explode(w, face: s.face.flatMap(w.particleFaces.sprite), v: Int16(truncatingIfNeeded: s.y),
                            h: Int16(truncatingIfNeeded: s.x), xStep: 2, yStep: 2, shape: 2, gravity: 0x32, style: 100)
        w.active.update(id: id) { $0.dead = true }
        let r = w.rng.next(5000)
        w.player.cue(PlayerCue(call: .threeDPitched, snd: breakSound, priority: 1, volume: 0x100, position: s.centre,
                               rate: Int32(r) + 43000))
    }

    // MARK: - KillCrate / KillBox

    /// `.KillCrate(crate) @ 1006fa98` (M l. 61181–61327; pickups-boxes §2.4.1) — nothing unless HP ≤ 0 (raw
    /// `1006fab8..fac0`); then:
    /// 1. `+0xea = +0xe9 = 1`; `.STPlay3DSoundRand(492, 100, 0x100, centre)`;
    /// 2. a 4 × 4 walk (i outer over x, j inner over y; h = x + 8i + 0xc, v = y + 8j + 0xc): `MTNewSprite(0xc1b, h − 0xc,
    ///    v − 0xc, 9, −1, .SetupEffectSprite)`, `FastRand(0x96)`, `FUN_1003f218(debris, .FindDesiredDirectionGeneric((v,
    ///    h), (y + 0x24, cx)), R + 0x28a)`, `vy −= 0x578 − FastRand(600)`; then for 3092 `MTNewSprite(0xc81, h − 0x18,
    ///    v − 0x18, 0xc, …)`, `FastRand(200)` → the impulse R + 500, `+0x46 = FastRand(5)`; for the others a counter from 0
    ///    (− 1, below 1 → 2) spawns every second piece a 0x442 dust there with R(0x96) + 400 and `+0x46 = FastRand(7)`;
    /// 3. by the live record's p1: 2 → `.STPlay3DSoundRand(435, 1, 0x100, centre)` and `MTNewSprite(0x4b7, cx − 0x30,
    ///    cy − 0x36, 0xc, …)`, no drop; 0 or 1 → p3 0 is written back as 1, then p3 times (the record re-read each time):
    ///    a Bonus drop (`isBonusDrop`) `MTNewSprite(p2, x + 0x16, y + 0x15, 0x14, −1, .SetupBonusSprite)` re-centred
    ///    (x += x − cx, y += y − cy, 24.8 from them), vy = −2000 − `FastRand(1000)`, p3 ≠ 1 → vx = `FastRand(800)` − 400,
    ///    `+0xb0 = 12`; any other p2 > 0 → `.GenerateSprite(x + 0x16, y + 0x15, p2, 0x200, now, layer + 1)` (`generate`)
    ///    re-centred by its rect (x −= (left + right) >> 1, y −= (top + bottom) >> 1), a type > 0xc7f → gravity 0x151 and
    ///    the same velocities, a 0x6cc → `+0xa6 = FastRand(10) + 1`, vx, vy = `FastRand(700)` − 0x15e (transcribed as
    ///    read; no crate drops a bat); any other p1: nothing.
    /// A spawn with no free record (Ruling 16) drops its stores; the draws are still made (the generated type's own
    /// draws need its type: none when nothing was made [LOW]).
    public static func killCrate(_ w: SpriteWorld, id: Int, lights: inout LightTable, effects: Int16) {
        guard let s = w.active.record(id: id), s.hp < 1 else { return }
        w.active.update(id: id) { c in
            c.killedForGood = true
            c.dead = true
        }
        let from = (v: Int16(truncatingIfNeeded: s.y + 0x24), h: Int16(truncatingIfNeeded: s.centre.x))
        w.player.cue(PlayerCue(call: .threeDRand, snd: crateSound, priority: 100, volume: 0x100, position: s.centre,
                               rate: w.rng.soundRate()))
        func spawn(_ type: Int16, _ x: Int, _ y: Int, layer: Int16) -> Int? {
            EffectSprite.spawn(w, type: type, x: x, y: y, layer: layer, effects: effects, lights: &lights)
        }
        func push(_ e: Int?, _ dir: Int, _ m: Int32) {
            if let e { w.active.update(id: e) { PlayerShot.addDirImpulse(&$0, dir: dir, magnitude: m) } }
        }
        var dust: Int16 = 0
        for i in 0..<4 {
            for j in 0..<4 {
                let hx = Int16(truncatingIfNeeded: s.x + 8 * i + 0xc), vy = Int16(truncatingIfNeeded: s.y + 8 * j + 0xc)
                let piece = spawn(EffectSprite.debris, Int(hx) - 0xc, Int(vy) - 0xc, layer: 9)
                let m = Int32(w.rng.next(0x96)) + 0x28a
                push(piece, BloodSpray.direction(target: (v: vy, h: hx), from: from), m)
                let r = Int32(w.rng.next(600))
                if let piece { w.active.update(id: piece) { $0.vy &-= 0x578 - r } }
                if s.type == 0xc14 {
                    let bit = spawn(0xc81, Int(hx) - 0x18, Int(vy) - 0x18, layer: 0xc)
                    let m2 = Int32(w.rng.next(200)) + 500
                    push(bit, BloodSpray.direction(target: (v: vy, h: hx), from: from), m2)
                    let ph = w.rng.next(5)
                    if let bit { w.active.update(id: bit) { $0.phase = ph } }
                } else {
                    dust -= 1
                    if dust < 1 {
                        dust = 2
                        let puff = spawn(EffectSprite.smoke, Int(hx) - 0x18, Int(vy) - 0x18, layer: 0xc)
                        let m2 = Int32(w.rng.next(0x96)) + 400
                        push(puff, BloodSpray.direction(target: (v: vy, h: hx), from: from), m2)
                        let ph = w.rng.next(7)
                        if let puff { w.active.update(id: puff) { $0.phase = ph } }
                    }
                }
            }
        }
        let i = Int(s.recordIndex)
        let p1 = liveRecord(w, s.recordIndex)?.p1 ?? 0
        if p1 == 2 {
            w.player.cue(PlayerCue(call: .threeDRand, snd: bangSound, priority: 1, volume: 0x100, position: s.centre,
                                   rate: w.rng.soundRate()))
            _ = spawn(EffectSprite.bigExplosion, s.centre.x - 0x30, s.centre.y - 0x36, layer: 0xc)
            return
        }
        guard p1 < 2, -1 < p1 else { return }
        if let p = liveRecord(w, s.recordIndex), p.p3 == 0 {
            w.records[i] = Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: p.p1, p2: p.p2,
                                     p3: 1, p4: p.p4, y: p.y, x: p.x)
        }
        var k: Int16 = 0
        while let p = liveRecord(w, s.recordIndex), k < p.p3 {
            let x0 = h(s.x + 0x16), y0 = h(s.y + 0x15)
            if isBonusDrop(p.p2) {
                let drop = w.newSprite(type: p.p2, x: x0, y: y0, layer: 0x14, handler: .bonus) { c in
                    // `try?`: `BonusSprite.setup` throws only for 0xc25 and out-of-table items — no Bonus drop type.
                    _ = try? BonusSprite.setup(&c, x: x0, y: y0, level: w.level, records: w.records, effects: effects,
                                               lightCount: lights.count, counting: false, rng: &w.rng) { f, lh, lv, col in
                        lights.add(face: f, x: Int16(truncatingIfNeeded: lh), y: Int16(truncatingIfNeeded: lv), vx: 0,
                                   vy: 0, accelY: 0, colour: col)
                    }
                }
                if let drop {
                    w.active.update(id: drop) { c in
                        c.x = h(c.x + (c.x - c.centre.x))
                        c.y = h(c.y + (c.y - c.centre.y))
                        c.x256 = Int32(c.x) << 8
                        c.y256 = Int32(c.y) << 8
                    }
                }
                let r = Int32(w.rng.next(1000))
                if let drop { w.active.update(id: drop) { $0.vy = -2000 - r } }
                if liveRecord(w, s.recordIndex)?.p3 != 1 {
                    let r2 = Int32(w.rng.next(800))
                    if let drop { w.active.update(id: drop) { $0.vx = r2 - 400 } }
                }
                if let drop { w.active.update(id: drop) { $0.pickupDelay = 0xc } }
            } else if 0 < p.p2 {
                let layer = w.active.record(id: id).map { $0.layer &+ 1 } ?? 1
                let g = generate(w, type: p.p2, x: x0, y: y0, layer: layer, lights: &lights, effects: effects)
                if let g {
                    w.active.update(id: g) { c in
                        let r = c.hotRect
                        c.x = h(c.x - h((r.left + r.right) >> 1))
                        c.y = h(c.y - h((r.top + r.bottom) >> 1))
                        c.x256 = Int32(c.x) << 8
                        c.y256 = Int32(c.y) << 8
                    }
                }
                if let g, let gs = w.active.record(id: g) {
                    if 0xc7f < gs.type {
                        w.active.update(id: g) { $0.gravity = 0x151 }
                        let r = Int32(w.rng.next(1000))
                        w.active.update(id: g) { $0.vy = -2000 - r }
                        if liveRecord(w, s.recordIndex)?.p3 != 1 {
                            let r2 = Int32(w.rng.next(800))
                            w.active.update(id: g) { $0.vx = r2 - 400 }
                        }
                    }
                    if gs.type == 0x6cc {
                        let a = w.rng.next(10) + 1
                        let vx = Int32(w.rng.next(700)) - 0x15e
                        let vy = Int32(w.rng.next(700)) - 0x15e
                        w.active.update(id: g) { c in
                            c.counterA6 = a
                            c.vx = vx
                            c.vy = vy
                        }
                    }
                }
            }
            k += 1
        }
    }

    /// `.GenerateSprite(x, y, type, 0x200, now, layer) @ 10003478` (M l. 1691–1936) as `.KillCrate` calls it: the
    /// class Setup by `SpriteClassTable`, `MTNewSprite(type, x, y, layer (−1 → 0), 0x200, setup)` and `+0x48 = 0x200`.
    /// Built for the Bonus class (every crate drop on levels 1–4: the item 3219); // later: Phase 5 — the other classes'
    /// run-time Setups (the census's crate drops: the Blob 1731 ×8 on level 31) make nothing here.
    static func generate(_ w: SpriteWorld, type: Int16, x: Int, y: Int, layer: Int32, lights: inout LightTable,
                         effects: Int16) -> Int? {
        guard let (cls, _) = SpriteClassTable.classify(type: type, p1Negative: false) else { return nil }
        let l16 = Int16(truncatingIfNeeded: layer)
        let l = l16 == -1 ? 0 : l16
        switch cls {
        case .bonus:
            return w.newSprite(type: type, x: x, y: y, layer: l, handler: .bonus, record: 0x200) { c in
                // `try?`: `BonusSprite.setup` throws only for 0xc25 and items past 0xc9a (none in a crate's p2).
                _ = try? BonusSprite.setup(&c, x: x, y: y, level: w.level, records: w.records, effects: effects,
                                           lightCount: lights.count, counting: false, rng: &w.rng) { f, lh, lv, col in
                    lights.add(face: f, x: Int16(truncatingIfNeeded: lh), y: Int16(truncatingIfNeeded: lv), vx: 0, vy: 0,
                               accelY: 0, colour: col)
                }
            }
        default:
            return nil
        }
    }

    /// `.KillBox(s) @ 100705f0` (M l. 61483–61520): `+0xe9 = 1`; the switch blocks 0x4e2…0x4ff and the rocks 0x433 /
    /// 0x434 → `.STPlay3DSoundRand(424, 1, 0x100, centre)` and `.ExplodeFaceIntoParticles(+0xc0, (+0xa, +0xc), 2, 2, 2,
    /// 100, 100)`. // later: Phase 5 — the geysers 0x5a0…0x5a8's column buffer `+0x9c` (its 16 pieces and the head
    /// killed); no Box builds one yet.
    static func killBox(_ w: SpriteWorld, id: Int) {
        w.active.update(id: id) { $0.dead = true }
        guard let s = w.active.record(id: id), switchBlocks.contains(s.type) || s.type == 0x433 || s.type == 0x434
        else { return }
        w.player.cue(PlayerCue(call: .threeDRand, snd: breakSound, priority: 1, volume: 0x100, position: s.centre,
                               rate: w.rng.soundRate()))
        ExplodeFace.explode(w, face: s.face.flatMap(w.particleFaces.sprite), v: Int16(truncatingIfNeeded: s.y),
                            h: Int16(truncatingIfNeeded: s.x), xStep: 2, yStep: 2, shape: 2, gravity: 100, style: 100)
    }

    // MARK: - tile and sprite hits

    /// `.HitBoxTileSprite(s, pos, kind, layer) @ 10070718` (M l. 61521–61683). The debug no-clip skip (`_DAT_100a0064`
    /// and key 0x32) is not built. The centre point is the hot rect's (v = top + (bottom − top) >> 1). Factor f and
    /// bounce b start 0; the boulders and rocks 0x42e…0x437 with |vy| > 0x1ff take b 1, f 0x3c. By the layer:
    /// - FG (1): thud = |vy| > 0x300 ∧ `+0xcd == 0`; the crates 0xc12…0xc14 f = b = 0x60; vy > 0x4b0 with the record's
    ///   p1 == 2 → `.KillCrate` (dead behind its HP guard unless the crate is already at HP ≤ 0); 0x5c3 f = b = 0x40;
    ///   unless a 0x5c4 with no bounces left (`+0x14c` ≤ 0; 0x5c4: f = b = 0x40): `.WallBounce(s, kind, &pos, centre, f,
    ///   +0x34, 0, b)`; a hit → the boulders and rocks with b ≠ 0: thud → `.STPlay3DSoundPitched(436, 1, 0x55, centre,
    ///   48000 + FastRand(10000))`, 0x433 / 0x434 → `.KillBox`; 0x5c4, or 0x5c3 with thud, with `+0xa6 < 1` → snd 303
    ///   pitched (vol 0xab, 48000 + R(10000)) and `+0x14c − 1`; then |vy| < 0x100 → vy 0; grounded (`+0xce`) 0x2c9 →
    ///   0x2c8, gravity 0 (the trunk lands);
    /// - any other layer (BG, a crunch nibble) with kind < 100: the same thud, 0x5c3 f = b = 0x40, the 0x5c4 gate,
    ///   `.WallBounce` and the spiked balls' sound — no boulder sound, no `.KillCrate`, no vy clamp;
    /// - kind 100…199: unless 0x434 / 0x5c3 / 0x5c4, `.WallBounceBG(s, kind − 100, …, f, …, b)`; a hit of a boulder or rock
    ///   with b ≠ 0 and thud → the thud;
    /// - kind ≥ 200: water (`.IsWaterTile`) with `+0x140 == 0` → `.HandleUnderWater(s, pos)`.
    public static func hitTile(_ solver: TileSolver, id: Int, pos posIn: TilePos, kind: Int, layer: TileLayer,
                               lights: inout LightTable, effects: Int16) {
        let w = solver.world
        guard let s = w.active.record(id: id) else { return }
        var pos = posIn
        let r = s.hotRect
        let vCentre = h(r.top + h((r.bottom - r.top) >> 1))
        let t = s.type                                                    // `iVar8`, read once
        func mag(_ v: Int32) -> Int32 { v < 1 ? 0 &- v : v }
        var f: Int16 = 0, b: Int16 = 0
        if 0x42d < t && t < 0x438 && 0x1ff < mag(s.vy) {
            b = 1
            f = 0x3c
        }
        let thud = 0x300 < mag(s.vy) && s.onSprite == 0
        func play(_ snd: Int16, _ volume: Int16) {
            let pitch = Int32(w.rng.next(10000)) + 48000
            let c = w.active.record(id: id)?.centre
            w.player.cue(PlayerCue(call: .threeDPitched, snd: snd, priority: 1, volume: volume, position: c, rate: pitch))
        }
        func spikes(_ hit: Bool) {
            guard hit, let c = w.active.record(id: id),
                  c.type == 0x5c4 || (c.type == 0x5c3 && thud), c.counterA6 < 1 else { return }
            play(spikeSound, 0xab)
            w.active.update(id: id) { $0.classTimer &-= 1 }
        }
        let k = Int16(truncatingIfNeeded: kind)
        if layer == .foreground {
            if crates.contains(t) {
                f = 0x60
                b = 0x60
            }
            if 0x4b0 < s.vy && liveRecord(w, s.recordIndex)?.p1 == 2 { killCrate(w, id: id, lights: &lights, effects: effects) }
            guard let s1 = w.active.record(id: id) else { return }
            let t1 = s1.type
            if t1 == 0x5c3 { f = 0x40; b = 0x40 }
            guard t1 != 0x5c4 || 0 < s1.classTimer else { return }
            if t1 == 0x5c4 { f = 0x40; b = 0x40 }
            let hit = solver.wallBounce(id, kind: kind, tile: &pos, vCentre: vCentre, factor: f, rect: s1.hotRect,
                                        bounce: b != 0)
            if hit, let c = w.active.record(id: id), 0x42d < c.type && c.type < 0x438, b != 0 {
                if thud { play(thudSound, 0x55) }
                if c.type == 0x433 || c.type == 0x434 { killBox(w, id: id) }
            }
            spikes(hit)
            w.active.update(id: id) { c in
                if mag(c.vy) < 0x100 { c.vy = 0 }
                if c.groundKind != 0 && c.type == 0x2c9 {
                    c.type = 0x2c8
                    c.gravity = 0
                }
            }
        } else if k < 100 {
            if t == 0x5c3 { f = 0x40; b = 0x40 }
            guard t != 0x5c4 || 0 < s.classTimer else { return }
            if t == 0x5c4 { f = 0x40; b = 0x40 }
            let hit = solver.wallBounce(id, kind: kind, tile: &pos, vCentre: vCentre, factor: f, rect: s.hotRect,
                                        bounce: b != 0)
            spikes(hit)
        } else if k < 200 {
            guard t != 0x434, t != 0x5c3, t != 0x5c4 else { return }
            let hit = solver.wallBounceBG(id, kind: kind - 100, tile: &pos, vCentre: vCentre, factor: f, rect: s.hotRect,
                                          bounce: b != 0)
            if hit, let c = w.active.record(id: id), 0x42d < c.type && c.type < 0x438, b != 0, thud {
                play(thudSound, 0x55)
            }
        } else if UnderWater.isWaterTile(kind), !s.underwaterDone {
            UnderWater.handle(world: w, id: id, pos: pos)
        }
    }

    /// `.HitBoxSprite(self, other) @ 10070024` (M l. 61328–61482; pickups-boxes §2.1, §2.4.1; pickups-boxes-2 §4.2, §7):
    /// skipped for the NPCs 0xb87…0xbb7, the switch blocks 0x4e2…0x4ff and a geyser part (0x5a0 / 0x5a5 / 0x5a9) against
    /// another (M l. 61352–61355); the doors 0xb5e / 0xb5f store a dead `+0xa0 = 0` (pickups-boxes-2 §6; not kept) and
    /// nothing else. Then by the other's Handle (`+0x4c`; an idled record matches none, `BackgroundSprite.runs`):
    /// - a player shot (`PTR_PTR_100a04e8`) with `+0xa6 == 0` (M l. 61366–61382): the crates 0xc12…0xc1b — HP − the
    ///   shot's `+0xa4`, HP < 1 with `+0xea` 0 → `.KillCrate`, then `.KillPlayerShot(shot, 1, 0)` (its stale r29 here is
    ///   the shot itself, `or r29,r4,r4` raw `10070038` — the recolour lands on the shot's own light, `staleSlot`); then
    ///   (both tests made) the stalactite 0xb74: HP − d (d the shot's `+0xa4`), n = d / 20 (C division), `+0xa6 = n +
    ///   FastRand(n / 2)` — the shake frames; the shot is not killed here (its own Hit does that; SH);
    /// - an Effect (`PTR_PTR_100a0460`) of type 0x4b7 (M l. 61384–61391): the crates — HP − 10 on any frame, HP < 1 with
    ///   `+0xea` 0 → `.KillCrate`, `.KillPlayerShot(effect, 1, 0)` (an id ≥ 100: no 419 while its `+0xa6` is the Setup's
    ///   3, then `+0xa6 = −6`; pickups-boxes-2 §7);
    /// - a Box (`PTR_PTR_100a0484`) or a Platform (`_DAT_100a0200`) — the Statue (`PTR_PTR_100a01f8`) // later: SW —
    ///   unless (self 0x433 against a Platform whose `+0xb0 == 0x34`) or self's `+0x182` (M l. 61393–61467): the
    ///   mutual `.PlatformBounce(mover, solid, self's rect centre, 0, self's `+0x34`, 0)` (self's centre and rect for
    ///   both calls, as written): a grounded (`+0xce`) self over an airborne other — or self a geyser part — makes self
    ///   the solid first (`PB(other, self)`, then `PB(self, other)` unless self is a geyser part); the mirror case;
    ///   both airborne → the higher (`+0xa` smaller) one moves first; both grounded → by speed: (|self vx| − |other vx|)
    ///   + (|self vy| − |other vy|) < 0 (i16) → `PB(self, other)` first, else `PB(other, self)` first; then both
    ///   `+0x182 = 1`;
    /// - the player (`PTR_PTR_100a052c`) against the carpet 0x438 — // later: Phase 6 (it wakes into 0x439).
    public static func hit(_ w: SpriteWorld, id: Int, other oID: Int, lights: inout LightTable, effects: Int16 = 1,
                           faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                           faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard let s = w.active.record(id: id), let o = w.active.record(id: oID) else { return }
        let t = s.type
        let geyser = { (v: Int16) in v == 0x5a0 || v == 0x5a5 || v == 0x5a9 }
        guard t < 0xb87 || 2999 < t, t < 0x4e2 || 0x4ff < t, !(geyser(t) && geyser(o.type)) else { return }
        guard t != 0xb5e && t != 0xb5f else { return }
        let runs = BackgroundSprite.runs
        func killShot(_ other: Int) {
            PlayerShotHits.kill(w, shot: other, sound: true, effect: false, effects: effects, lights: &lights,
                                faceWidth: faceWidth, faceBounds: faceBounds,
                                staleSlot: w.active.record(id: other)?.light)
        }
        func damage(_ d: Int16) {
            w.active.update(id: id) { $0.hp &-= d }
            if let c = w.active.record(id: id), c.hp < 1, !c.killedForGood {
                killCrate(w, id: id, lights: &lights, effects: effects)
            }
        }
        if runs(o, .playerShot) && o.counterA6 == 0 {
            if crateRange.contains(t) {
                damage(o.hp)
                killShot(oID)
            }
            if w.active.record(id: id)?.type == stalactite {
                let d = w.active.record(id: oID)?.hp ?? o.hp
                let n = d / 20
                w.active.update(id: id) { $0.hp &-= d }
                let r = w.rng.next(n / 2)
                w.active.update(id: id) { $0.counterA6 = n &+ r }
            }
        } else if runs(o, .effect) && o.type == EffectSprite.bigExplosion {
            if crateRange.contains(t) {
                damage(10)
                killShot(oID)
            }
        } else if runs(o, .box) || runs(o, .platform) {
            guard !(t == 0x433 && runs(o, .platform) && o.subtype == 0x34), !s.boxPairLatch else { return }
            let r = s.hotRect
            let centre = SpriteSlot.Point(x: h(r.left + h((r.right - r.left) >> 1)), y: h(r.top + h((r.bottom - r.top) >> 1)))
            func bounce(_ m: Int, _ solid: Int) {
                w.platformBounce(mover: m, solid: solid, centre: centre, factor: 0, rect: r, bounce: false)
            }
            func mag(_ v: Int32) -> Int16 { Int16(truncatingIfNeeded: v < 1 ? 0 &- v : v) }
            let selfGeyser = t == 0x5a0 || t == 0x5a5 || t == 0x5a9
            let otherGeyser = geyser(o.type)
            if (s.groundKind != 0 && o.groundKind == 0) || selfGeyser {
                bounce(oID, id)
                if !selfGeyser { bounce(id, oID) }
            } else if (o.groundKind != 0 && s.groundKind == 0) || otherGeyser {
                bounce(id, oID)
                if !otherGeyser { bounce(oID, id) }
            } else if o.groundKind == 0 && s.groundKind == 0 {
                if h(s.y) < h(o.y) {
                    bounce(id, oID)
                    bounce(oID, id)
                } else {
                    bounce(oID, id)
                    bounce(id, oID)
                }
            } else if (mag(s.vx) &- mag(o.vx)) &+ (mag(s.vy) &- mag(o.vy)) < 0 {
                bounce(id, oID)
                bounce(oID, id)
            } else {
                bounce(oID, id)
                bounce(id, oID)
            }
            w.active.update(id: oID) { $0.boxPairLatch = true }
            w.active.update(id: id) { $0.boxPairLatch = true }
        }
        // `+0x4c == PTR_PTR_100a052c` with self 0x438: `+0x46 = 2`, type 0x439, `+0x1f8` on, `+0x15c = 30`, `+0x185 = 0`
        // (M l. 61470–61476) // later: Phase 6 (the carpet's Handle does not run).
    }
}
