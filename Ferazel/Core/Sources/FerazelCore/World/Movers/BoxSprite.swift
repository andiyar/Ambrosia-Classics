import Foundation

/// The Box class standing still as solids (W3; pickups-boxes §2.1–§2.2, §2.4.11): `.SetupBoxSprite @ 1006b43c` (M l.
/// 58892–59727) for every Box type placed on levels 1–2 and the arms they share, and `.HandleBoxSprite @ 1006d878` (M l.
/// 60030–61157) for the types whose arm W3 builds — the trampoline 1470 and the bridges 1460…1467. The Box arm of
/// `.HitPlayerSprite` is `HitPlayerSprite.box`. Faces are `SetupFaces`'s (the class caches of `.InitBoxSprite`).
///
/// Not built (design §8 puts the Box mechanisms in Phase 4): pushing and falling — the common tail's
/// `.ApplyGravityAndSeparateFromTiles` and `.FootPressure` — and every other type arm of the Handle (chests, crates,
/// switch blocks, decorations' re-face, NPCs, doors, teleporters, boulders' roll, spouts, geysers, pipes, carts, gates,
/// stalactites, snowballs); `.HitBoxSprite` (box vs box / platform) and `.HitBoxTileSprite`.
public enum BoxSprite {
    /// The trampoline (PICT 1470, the 4-face set `_DAT_100a0a2c`).
    public static let trampoline: Int16 = 0x5be
    /// The bridges 1460…1467 (0x5b4…0x5bb).
    public static let bridges: ClosedRange<Int16> = 0x5b4...0x5bb

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
    /// 0xc12…0xc14, and the post-chain blocks: switch blocks 0x4e2…0x4ff, furniture 0xb68…0xb70, decorations
    /// 0xaf5…0xb21, outcrops 0xb22…0xb35, mushrooms 0xb36…0xb49, NPCs 0xb87…0xb99. // later: Phase 4 / W4 — the other
    /// arms (tree trunk 0x2c8/0x2c9, carpet 0x438/0x439, geysers 0x5a0…0x5a9, spiked balls 0x5c3/0x5c4, pipes
    /// 0x5d2…0x5d5, the table 0xb71, the cart 0xb72/0xb73, the stalactite 0xb74, gates 0xb7c/0xb7d, the snowball 0xbfe —
    /// several make sprites or draw `FastRand` at Setup) leave the head's fields.
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

    /// The types whose `.HandleBoxSprite` arm W3 builds: the trampoline and the bridges.
    public static func handleBuilt(_ t: Int16) -> Bool { t == trampoline || bridges.contains(t) }

    /// `.HandleBoxSprite` (M l. 60030–61157) for the built types (`handleBuilt`; every other Box returns at once — its
    /// arm and the tail are Phase 4, and they stand still meanwhile):
    /// - `+0xe9` or `+0x1b2` → return; `.StandardSpriteHandles`; `+0x182 = 0` (the `.HitBoxSprite` pair latch — no
    ///   Phase-2 writer, not kept);
    /// - 0x5be (l. 60555–60563): face = the cache set `_DAT_100a0a2c` [`+0x46`]; `+0x46 > 0` → `+0x46 += 1`, past 3 → 0;
    /// - 0x5b4…0x5bb (l. 60565–60591): face = the class cache (0x5b5 / 0x5b6 → 0x5b5, 0x5b8 / 0x5b9 → 0x5b8, the others
    ///   their own);
    /// - the tail `LAB_1006f948` (l. 61152–61156): `.ApplyFriction(+0x114)`; `+0xcd ≠ 0` → `.FootPressure`
    ///   // later: Phase 4 (gravity 0: never grounded); `.EnforceMaxSpeed(0x1838)`; `+0x1c += vy`; `+0xcd = +0xce`;
    ///   gravity ≠ 0 → `.ApplyGravityAndSeparateFromTiles` // later: Phase 4 (the fall — no built type has gravity);
    ///   `.BoxCleanUp`: `.BoxUW` (left the water → `.Splash(s, 4)`, // later: E1a) then `.BoxClean` (M l.
    ///   60000–60015): the centre `+0x10 = x + left + (right − left) >> 1`, `+0xe` likewise, `+0xdc = 0`, `+0xd6 = 0`.
    public static func handle(world w: SpriteWorld, id: Int) {
        guard let s0 = w.active.record(id: id), handleBuilt(s0.type), !s0.dead, !s0.handleSkip else { return }
        w.standardSpriteHandles(id)
        let t = s0.type
        w.active.update(id: id) { s in
            if t == trampoline {
                s.face = FaceRef(pict: trampoline, index: Int(s.phase), set: .encoded)
                if 0 < s.phase {
                    s.phase += 1
                    if 3 < s.phase { s.phase = 0 }
                }
            } else {
                let cache: Int16 = t == 0x5b6 ? 0x5b5 : (t == 0x5b9 ? 0x5b8 : t)
                s.face = FaceRef(pict: cache, index: 0, set: .encoded)
            }
            // `LAB_1006f948`.
            s.applyFriction(s.friction)
            s.enforceMaxSpeed(0x1838)
            s.y256 &+= s.vy
            s.onSprite = s.groundKind
            // `.BoxClean`.
            let r = s.hotRect
            s.centre.x = Int(Int16(truncatingIfNeeded: s.x + r.left + ((r.right - r.left) >> 1)))
            s.centre.y = Int(Int16(truncatingIfNeeded: s.y + r.top + ((r.bottom - r.top) >> 1)))
            s.ridden = nil
            s.slope = 0
        }
    }
}
