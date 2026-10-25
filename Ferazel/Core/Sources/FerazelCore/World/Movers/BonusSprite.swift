import Foundation

/// The Bonus class (BN; pickups-boxes §1.1–§1.4, §1.9–§1.11, pickups-boxes-2 §1–§2, §4): `.SetupBonusSprite @
/// 1005d988` (M l. 52338–52804), `.HandleBonusSprite @ 1005e934` (M l. 52805–53443), `.HitBonusSprite @ 1005fd38`
/// (M l. 53444–53536), `.KillBonus @ 10060024` (M l. 53537–53570) and `.HitBonusTileSprite @ 1006010c` (M l.
/// 53571–53638), with the faces `.InitBonusSprite @ 1005d4f0` loads (M l. 52261–52337). The pickup arms of
/// `.HitPlayerSprite` are PK's; the player-shot container arm of `.HitBonusSprite` is SH's.
public enum BonusSprite {
    @inline(__always) static func h(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }

    @inline(__always) static func rect(_ left: Int, _ top: Int, _ right: Int, _ bottom: Int) -> IdleSprites.Rect {
        IdleSprites.Rect(top: top, left: left, bottom: bottom, right: right)       // `SetRect(r, left, top, right, bottom)`
    }

    // MARK: - faces (`.InitBonusSprite`, M l. 52261–52337; boot loads, clut 200)

    /// Every face `.InitBonusSprite` loads: the singles 0x517 (`PTR_DAT_100a08f4`), 2000 (`_DAT_100a08f0`, every
    /// scroll), 0x50a…0x50d, 0x546, 0xbea, 0xc1c…0xc25 (`_DAT_100a08a4`), 0xc80…0xc9a (`_DAT_100a08a0`, 27) and
    /// 0x532…0x53b (`_DAT_100a089c`); the sets 0x421 / 0x422 (10 × 0x20×0x20), 0x4bf (4 × 0x10×0x11), 0x514 / 0x515
    /// (6 × 0x12×0x14), 0x516 / 0x51d / 0x51e (9 × 10×10), 0x51b (6 × 10×0x1c), 0x53c / 0x53d (6 × 0x2c×0x2a).
    public static let sheets: [SetupFaces.Sheet] = {
        func set(_ p: Int16, _ n: Int, _ w: Int, _ h: Int) -> SetupFaces.Sheet {
            SetupFaces.Sheet(pict: p, count: n, cellWidth: w, cellHeight: h, columns: n, clut: 200)
        }
        var all: [SetupFaces.Sheet] = [
            .single(0x517), .single(2000), set(0x421, 10, 0x20, 0x20), set(0x422, 10, 0x20, 0x20),
            set(0x4bf, 4, 0x10, 0x11), .single(0x50a), .single(0x50b), .single(0x50c), .single(0x50d),
            set(0x514, 6, 0x12, 0x14), set(0x515, 6, 0x12, 0x14), set(0x516, 9, 10, 10), set(0x51d, 9, 10, 10),
            set(0x51e, 9, 10, 10), set(0x51b, 6, 10, 0x1c), set(0x53c, 6, 0x2c, 0x2a), set(0x53d, 6, 0x2c, 0x2a),
            .single(0x546), .single(0xbea),
        ]
        all += (Int16(0xc1c)...0xc25).map { SetupFaces.Sheet.single($0) }
        all += (Int16(0xc80)..<(0xc80 + 0x1b)).map { SetupFaces.Sheet.single($0) }
        all += (Int16(0x532)...0x53b).map { SetupFaces.Sheet.single($0) }
        return all
    }()

    /// PK: the sheets Bonus faces are read from at run time without a placed type to load them — `.HurtPlayer`'s lost
    /// coin 0x516 (`_DAT_100a08d0`, M l. 52294, 9 × 10×10) and the Xichron burst's sets (`.ExplodeFaceIntoParticles`,
    /// M l. 48632, 48649–48661: 0x421 face 0 `*PTR_DAT_100a0478`, 0x422 face 0 `*_DAT_100a0474` from the hundredth on;
    /// 10 × 0x20×0x20) — for a renderer that loads only the placed types' sheets (`.InitBonusSprite` loads them all
    /// at boot). The burst's particles and their `FastRand` draws follow the face's pixels, which Core has only from
    /// the renderer (`SpriteWorld.particleFaces`): a face not loaded would emit nothing.
    public static let dropSheets: Set<SetupFaces.Sheet> = Set(sheets.filter { [0x421, 0x422, 0x516].contains($0.pict) })

    /// The light faces: `_DAT_100a07fc` 0x336 (52×52), `PTR_DAT_100a088c[0…3]` 0x32a…0x32d (72×72, `BonusHandle`),
    /// `_DAT_100a08c0` 0x321 / `_DAT_100a08bc` 0x322 (192×192), `_DAT_100a08b8` 0x326 (84×84).
    static let crystalLight = LightFaceRef(pict: 0x336, width: 0x34, height: 0x34)
    static let torchLight = LightFaceRef(pict: 0x321, width: 0xc0, height: 0xc0)
    static let torchLight2 = LightFaceRef(pict: 0x322, width: 0xc0, height: 0xc0)
    static let upgradeLight0 = LightFaceRef(pict: 0x326, width: 0x54, height: 0x54)
    static func twinkleLight(_ i: Int) -> LightFaceRef {
        let f = BonusHandle.twinkleFaces[i]
        return LightFaceRef(pict: f.pict, width: f.width, height: f.height)
    }

    public static let torch: Int16 = 0x51b
    public static let candelabras: ClosedRange<Int16> = 0xc1c...0xc25
    public static let shards: ClosedRange<Int16> = 0x4bf...0x4c2

    // MARK: - Setup

    /// What the Setup leaves for the face (`SetupFaces` turns it into the drawn face / sheet).
    public struct Face: Equatable, Sendable {
        public let pict: Int16
        public let index: Int
        public let source: SetupFaces.FaceSource
    }

    /// `.SetupBonusSprite` (M l. 52338–52804) on `s` — every field, in the arm order, with the arm's `FastRand` draws in
    /// the order of the planner-probe note (pickups-boxes §1.1; raw `1005db3c…1005e8c0`) and the shared tail
    /// `LAB_1005e8bc` (`+0x14c = FastRand(60)`, 24.8 from `+8`/`+6`, `.CalcCenterPos`, `+0xe4 = 1` — the last has no
    /// reader beyond `.SeparateFromTiles2`'s dead loop and is not kept).
    ///
    /// The head: `.InitSprite`, `+0x84 = +0x86 = 0` (no reader kept), layer 1, the Bonus Handle, hit and tile callbacks,
    /// `+0xa6 = 0`, gravity 0x151, face 0, the position from the spawn copy, `+0x9a = −1`, `+0x168 = p4` for a record
    /// 0 ≤ i < 0x1ff. A record read elsewhere uses the index unchecked (the binary reads `hdr + 16·i + …`): an index
    /// outside the live records reads 0 (plan hazard "Record index 0x200"; [LOW] for −1, which no spawned type that
    /// reads it passes). `+0x183` and `+0x12c` have no reader (raw search) and are not kept.
    ///
    /// - Parameter x: `+8`, `y`: `+6` — the spawn copy (`.MTNewSprite` / the level spawn).
    /// - Parameter counting: `*_DAT_1009fe8c` (set only around `.SetupLevelSprites`) — 0x41f/0x420/0x423 then set
    ///   `+0x1b5` (the tallies are `SetupFaces.Tallies`).
    /// - Parameter playerLayer: the player's `+0x80` (`*_DAT_1009fdd8`), the shards' layer − 1.
    /// - Parameter addLight: `.AddLight(face, (v, h), 0, 0, 0, colour)`; returns the slot for `+0x9a`.
    /// - Returns: the face the Setup stores (`.setup`), or the sheet its Handle faces it from (`.handle`; the Setup
    ///   leaves `+0xc0 = 0`), nil for a faceless type. Throws `notTranscribed` for a type no Bonus arm handles faithfully:
    ///   the default arm's out-of-table faces (0x421, 0x50e…0x513, 0x518, 0x53e…0x545, items past 0xc9a — the face is
    ///   read past `_DAT_100a08a0`'s 27 entries) and 0xc25 (its light point is an uninitialised stack word).
    public static func setup(_ s: inout SpriteSlot, x: Int, y: Int, level: LevelFile, records: [Placement],
                             effects: Int16, lightCount: Int16, counting: Bool, playerLayer: Int32 = 0,
                             rng: inout FastRand,
                             addLight: (_ face: LightFaceRef, _ h: Int, _ v: Int, _ colour: Int16) -> Int16)
        throws -> Face? {
        let t = s.type
        let ti = Int(t)
        func rec(_ i: Int16) -> Placement? { (0..<records.count).contains(Int(i)) ? records[Int(i)] : nil }
        let own = rec(s.recordIndex)
        var face: Face?
        func light(_ f: LightFaceRef, _ dx: Int, _ dy: Int, _ colour: Int16) {
            s.light = addLight(f, h(s.x + dx), h(s.y + dy), colour)
        }
        // The head (M l. 52372–52396).
        s.oldPosition = SpriteSlot.Point(x: x, y: y)
        s.x = x                                                    // `+0xc = +8`
        s.y = y                                                    // `+0xa = +6`
        s.layer = 1
        s.handler = .bonus
        s.hasHit = true
        s.hasTileHit = true
        s.counterA6 = 0
        s.gravity = 0x151
        s.face = nil
        s.light = -1
        if 0 <= s.recordIndex && s.recordIndex < 0x1ff { s.bonusP4 = Int32(own?.p4 ?? 0) }

        switch ti {
        case 0x423, 0x422:                                 // triggers (M l. 52403–52415, 52469–52477)
            s.lightOverlay = false
            s.hotRect = rect(0, 0, 0x60, 0x60)
            s.gravity = 0
            s.hasHit = false
            s.hasTileHit = false
            if t == 0x423 && counting { s.countedInTotals = true }
        case 0x45:                                         // the Mist body (M l. 52419–52427)
            s.hotRect = rect(0x23, 0x23, 0x41, 0x50)
            s.mode = 0
            s.pickupDelay = 0
            s.counterA6 = 0
            // `+0xc0 = player face + 0x9c` // later: MS — the Mist body's spawner hands its face over.
        case 0x41f, 0x420:                                 // Xichrons (M l. 52430–52467)
            s.lightOverlay = false
            s.hotRect = rect(2, -4, 0x12, 0x10)
            s.phase = rng.next(0x13)                       // raw `1005db3c` → `+0x46`
            s.slip = rng.next(6) + 0x1c                    // `1005db4c` → `+0x112`
            s.friction = rng.next(3) + 2                   // `1005db60` → `+0x114`
            s.gravity = 0
            // `.GetBGTile((x + 0x10) >> 5, (y + 0x10) >> 5)` → `.LookupBGTileKind` → `.IsWaterTile` (M l. 52442–52450).
            let k = level.bgKind(tile: level.bgTile(col: h(s.x + 0x10) >> 5, row: h(s.y + 0x10) >> 5))
            s.inWaterAtSpawn = UnderWater.isWaterTile(k) ? 1 : 0
            if effects == 1 && lightCount < 0x96 { light(crystalLight, 0x10, 0x10, t == 0x41f ? 0x16 : 0x2c) }
            if counting { s.countedInTotals = true }
            face = Face(pict: 0x421, index: 0, source: .handle)
        case 0x50a, 0x50b:                                 // big crystals (M l. 52482–52505)
            if effects == 1 { light(crystalLight, 10, 0x10, t == 0x50a ? 0x37 : 0x21) }
            if s.recordIndex != -1 && s.recordIndex != 0x1ff && (own?.p1 ?? 0) != 0 { s.gravity = 0 }
            s.lightOverlay = false
            s.hotRect = rect(2, 0xe, 0x12, 0x1e)
            s.phase = rng.next(10)                         // raw `1005de54`
            s.slip = rng.next(6) + 0x1c                    // `1005de64`
            s.friction = 10
            face = Face(pict: t, index: 0, source: .handle)
        case 0x50c, 0x50d:                                 // money bags (M l. 52508–52527)
            if effects == 1 { light(crystalLight, 0x10, 0x10, 99) }
            s.lightOverlay = false
            s.hotRect = t == 0x50c ? rect(6, 0xc, 0x1a, 0x12) : rect(2, 0xc, 0x1e, 0x18)
            s.phase = -5 - rng.next(10)                    // raw `1005df24` (`neg; subi 5`)
            s.slip = 0
            s.friction = 0x32
            face = Face(pict: t, index: 0, source: .handle)
        case 0x4bf...0x4c2:                                // Multi Crystal shards (M l. 52530–52536)
            s.layer = playerLayer &+ 1
            s.gravity = 0x151
            s.counterA6 = -40                              // 0xffd8
            s.hotRect = rect(0, -4, 0x10, 10)
            s.face = FaceRef(pict: 0x4bf, index: ti - 0x4bf, set: .encoded)
            face = Face(pict: 0x4bf, index: ti - 0x4bf, source: .setup)
        case 0x51b:                                        // the torch (M l. 52541–52563)
            s.lightOverlay = false
            if (own?.p4 ?? 0) == 0 {
                s.pickupDelay = 1
            } else {
                s.pickupDelay = 0
                s.hasHit = false
            }
            s.hotRect = rect(-4, -2, 0xe, 0x1e)
            s.gravity = 0
            s.phase = rng.next(10)                         // raw `1005e110`
            light(torchLight, 5, 8, (own?.p3 ?? 0) == 0 ? 0x16 : 0x58)
            face = Face(pict: 0x51b, index: 0, source: .handle)
        case 0x517:                                        // the rock pile (M l. 52565–52568): `+0x88` kept
            s.hotRect = rect(2, -8, 0x1c, 0xb)
            face = Face(pict: 0x517, index: 0, source: .handle)
        case 0x516, 0x519, 0x51a:                          // coins (`LAB_1005e02c`, M l. 52571–52581)
            s.hotRect = rect(2, -4, 8, 7)
            s.phase = rng.next(9)                          // raw `1005e050`
            s.slip = rng.next(6) + 0x1c
            s.friction = rng.next(3) + 2
            face = Face(pict: t == 0x516 ? 0x516 : t == 0x519 ? 0x51d : 0x51e, index: 0, source: .handle)
        case 0x514, 0x515:                                 // crystals (M l. 52583–52603)
            if effects == 1 { light(crystalLight, 10, 0x10, t == 0x514 ? 0x37 : 0x21) }
            s.lightOverlay = false
            s.hotRect = rect(2, -4, 0x12, 0x10)
            s.phase = rng.next(4)                          // raw `1005dff4`
            s.slip = rng.next(6) + 0x1c
            s.friction = rng.next(3) + 2
            face = Face(pict: t, index: 0, source: .handle)
        case 0xbea:                                        // the hang glider (M l. 52611–52627)
            s.gravity = 0
            s.hotRect = rect(0x47, 0x44, 0x5a, 0x6d)
            s.keepRecordAtKill = true                      // `+0x18b = 1` (M l. 52615)
            s.keepRecord = true                            // `+0x188 = 1` (M l. 52617)
            s.face = FaceRef(pict: 0xbea, index: 0, set: .encoded)
            face = Face(pict: 0xbea, index: 0, source: .setup)
            // `_DAT_100a076c…0778 + 1 = 1` (four cache entries' "needed" bytes) // later: GL — the glider's faces.
        case 0x546:                                        // the air bubble (M l. 52628–52638)
            s.lightOverlay = false
            s.hotRect = rect(8, 8, 0x18, 0x18)
            s.gravity = 0
            s.phase = rng.next(10)                         // raw `1005e1bc`
            s.keepRecord = true                            // `+0x188 = 1` (M l. 52636)
            s.face = FaceRef(pict: 0x546, index: 0, set: .encoded)
            face = Face(pict: 0x546, index: 0, source: .setup)
        default:
            // The shared default (M l. 52642–52645): `+0x183 = 1`, `+0x88 = 0`, gravity 200.
            s.lightOverlay = false
            s.gravity = 200
            if candelabras.contains(t) {                   // 3100…3109 (M l. 52740–52794)
                guard t != 0xc25 else { throw SetupFaces.Error.notTranscribed(type: t) }
                s.pickupDelay = 1
                s.gravity = 0
                s.hasHit = true
                s.hasTileHit = false
                s.face = FaceRef(pict: t, index: 0, set: .encoded)
                if (own?.p4 ?? 0) == 0 {
                    s.pickupDelay = 1
                } else {
                    s.pickupDelay = 0
                    s.hasHit = false
                }
                var colour: Int16 = 99
                let (dx, dy): (Int, Int)
                switch ti {
                case 0xc1c: (dx, dy) = (0xf, 0x10)
                case 0xc1d: (dx, dy) = (0x12, 0xf)
                case 0xc1e: (dx, dy) = (0x11, 8)
                case 0xc1f: (dx, dy) = (0xf, 8); colour = 0x4d
                case 0xc20, 0xc21: (dx, dy) = (0x14, 9)
                case 0xc22: (dx, dy) = (0x13, 7)
                case 0xc23: (dx, dy) = (0x13, 0x1a); colour = 0x37
                default: (dx, dy) = (0x13, 0x18); colour = 0x42      // 0xc24
                }
                let ph = h(s.x + dx), pv = h(s.y + dy)
                s.hotRect = rect(ph - 8 - s.x, pv - 8 - s.y, ph + 8 - s.x, pv + 8 - s.y)
                s.light = addLight(torchLight, ph, pv, colour)
                s.phase = rng.next(0x10)                   // raw `1005e4a4`
                face = Face(pict: t, index: 0, source: .setup)
            } else if (2000...0x833).contains(ti) {        // scrolls (M l. 52726–52737)
                s.gravity = 0
                s.face = FaceRef(pict: 2000, index: 0, set: .encoded)
                s.hotRect = rect(4, 4, 0x1c, 0x1c)
                light(twinkleLight(0), 0x10, 0xc, 99)
                s.phase = rng.next(0x10)                   // raw `1005e534`
                if (own?.p1 ?? 0) != 0 { s.gravity = 0 }
                face = Face(pict: 2000, index: 0, source: .setup)
            } else if (0x532...0x53b).contains(ti) {       // spheres (M l. 52713–52723)
                s.face = nil
                s.hotRect = rect(0, 0, 0x20, 0x1b)
                light(twinkleLight(0), 0x10, 0x10, 99)
                s.phase = rng.next(0x10)                   // raw `1005e5dc`
                if (own?.p1 ?? 0) != 0 { s.gravity = 0 }
                face = Face(pict: t, index: 0, source: .handle)
            } else if t == 0x53c || t == 0x53d {           // upgrades (M l. 52650–52663)
                s.gravity = 0
                s.hotRect = rect(4, 8, 0x28, 0x1e)
                light(twinkleLight(0), 0x16, 0x14, t == 0x53d ? 0x21 : 0x4d)
                s.inWaterAtSpawn = Int32(rng.next(0x10))   // raw `1005e6c0` → `+0x15c` (`stw`)
                face = Face(pict: t, index: 0, source: .handle)
            } else {                                       // items (M l. 52665–52710)
                guard (0xc80..<(0xc80 + 0x1b)).contains(ti) else { throw SetupFaces.Error.notTranscribed(type: t) }
                s.face = FaceRef(pict: t, index: 0, set: .encoded)
                var r = rect(4, 4, 0x1c, 0x18)
                s.phase = rng.next(0x10)                   // raw `1005e724`
                if t == 0xc86 || t == 0xc9a { r.top += 6 }
                if t < 0xc84 { r.bottom -= 6 }
                if t == 0xc87 || t == 0xc88 || (0xc8b...0xc8f).contains(ti) || t == 0xc99 || t == 0xc93 || t == 0xc94 {
                    r.bottom = 0x1f
                    r.top += 7
                }
                if t == 0xc92 || t == 0xc95 || t == 0xc97 || t == 0xc98 {
                    r.top += 0xd
                    r.bottom = 0x26
                }
                s.hotRect = r
                var colour: Int16 = 99
                if t == 0xc97 || t == 0xc99 || t == 0xc9a { colour = 0x21 }
                if t == 0xc86 || t == 0xc98 { colour = 0x2c }
                if t == 0xc93 { colour = 0x4d }
                light(twinkleLight(0), 0x10, 0xc, colour)
                s.friction = 6
                // The signed-range idiom (M l. 52704–52706): 0xc80 ≤ t ≤ 0xcb1, with p1 ≠ 0 → gravity 0.
                if (0xc80...0xcb1).contains(ti) && (own?.p1 ?? 0) != 0 { s.gravity = 0 }
                face = Face(pict: t, index: 0, source: .setup)
            }
        }
        // `LAB_1005e8bc` (raw `1005e8c0`): `+0x14c = FastRand(60)`; 24.8 from `+8`/`+6`; `.CalcCenterPos`.
        s.lightTimer = Int32(rng.next(0x3c))
        s.x256 = Int32(Int16(truncatingIfNeeded: x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: y)) << 8
        let r = s.hotRect
        s.centre = SpriteSlot.Point(x: h(s.x + r.left + h((r.right - r.left) >> 1)),
                                    y: h(s.y + r.top + h((r.bottom - r.top) >> 1)))
        return face
    }

    // MARK: - KillBonus

    /// `.KillBonus @ 10060024` (M l. 53537–53570): not dying (`+0xe9 == 0`) and counted (`+0x1b5`): 0x41f / 0x420 →
    /// the pending Xichrons `*_DAT_1009ffb0` − 1 and `G+0x3ce+2L` + 1; 0x423 → the pending secrets `*_DAT_1009ffac` − 1
    /// and `G+0x496+2L` + 1 (L = `*_DAT_1009feac`); then `+0xe9 = 1` if 0; `.RemoveLight(+0x9a)`.
    public static func kill(_ w: SpriteWorld, _ s: inout SpriteSlot, lights: inout LightTable) {
        if s.killCount == 0 && s.countedInTotals {
            let L = w.levelIndex
            if s.type == 0x41f || s.type == 0x420 {
                w.pendingTallies.xichrons &-= 1
                if (0..<GameGlobals.levelSlots).contains(L) { w.globals.achieved[1][L] &+= 1 }
            } else if s.type == 0x423 {
                w.pendingTallies.secrets &-= 1
                if (0..<GameGlobals.levelSlots).contains(L) { w.globals.achieved[2][L] &+= 1 }
            }
        }
        if s.killCount == 0 { s.killCount = 1 }
        lights.remove(&s.light)
    }

    /// `.KillBonus` on the listed sprite `id`.
    public static func kill(_ w: SpriteWorld, id: Int, lights: inout LightTable) {
        guard var s = w.active.record(id: id) else { return }
        kill(w, &s, lights: &lights)
        w.active.update(id: id) { $0 = s }
    }

    // MARK: - Handle

    /// The tile callback a Bonus's `+0x1f8` names (nil = 0).
    static func pass(_ s: SpriteSlot) -> TileHit? {
        guard s.hasTileHit else { return nil }
        return { solver, id, cell, kind, layer in hitTile(solver, id: id, pos: cell, kind: kind, layer: layer) }
    }

    /// `.HandleBonusSprite @ 1005e934` (M l. 52805–53443). Returns the `.ChangeLightFace` calls it made (also made on
    /// `lights`) as ops, in call order.
    /// - `+0xe9` or `+0x1b2` → return; `.StandardSpriteHandles`; a negative `+0xa6` counts up;
    /// - the type arm (each documented at its case);
    /// - the tail `LAB_1005fc30` (M l. 53412–53440): friction `+0x114` toward 0; `.ApplyGravityAndSeparateFromTiles`
    ///   when gravity > 0 and the type is not 0x517 / 0x41f / 0x420; `.StandardSpriteCleanup`; `.SetLightPos(+0x9a,
    ///   centre)` unless no light, the torch 0x51b or a candelabra 0xc1c…0xc25.
    /// - Parameter effects: prefs `+6` (`_DAT_1009fe44 + 6`).
    /// - Parameter faceWidth: the Cleanup's face `+6`.
    @discardableResult
    public static func handle(world w: SpriteWorld, id: Int, solver: TileSolver, effects: Int16,
                              lights: inout LightTable, faceWidth: (FaceRef) -> Int) -> [DrawOp] {
        guard let s0 = w.active.record(id: id), s0.killCount == 0, !s0.handleSkip else { return [] }
        w.standardSpriteHandles(id)
        guard var s = w.active.record(id: id) else { return [] }
        var ops: [DrawOp] = []
        let slot = s.light                                 // `+0x9a` — no arm that calls `.ChangeLightFace` changes it
        /// `.ChangeLightFace(+0x9a, f)` on `lights`, and the op for the renderer's copy (a slot outside 0…199 is ignored).
        func change(_ f: LightFaceRef?) {
            if let f {
                lights.changeFace(slot, f)
                if (0..<LightTable.slotCount).contains(Int(slot)) {
                    ops.append(.changeLightFace(slot: Int(slot), pict: f.pict, width: f.width, height: f.height))
                }
            } else {
                lights.clearFace(slot)
            }
        }
        if s.counterA6 < 0 { s.counterA6 &+= 1 }
        let t = s.type
        let ti = Int(t)
        /// The 11-step / 41-step glint (M l. 52866–52996): `+0xb0` counts down to 0, `+0x46` 0…`wrap`, `+0xb8` 0 on
        /// steps < 2 (and negative), 0x10008 on 2…3 and 6…7, 0x10009 on 4…5, 0 from 8.
        func glint(_ wrap: Int16) {
            if s.pickupDelay > 0 { s.pickupDelay -= 1 }
            s.phase &+= 1
            if wrap < s.phase { s.phase = 0 }
            switch s.phase {
            case 2...3, 6...7: s.mode = 0x10008
            case 4...5: s.mode = 0x10009
            default: s.mode = 0
            }
            s.face = FaceRef(pict: t, index: 0, set: .encoded)
        }
        switch ti {
        case 0x45:
            w.active.update(id: id) { $0 = s }
            return ops                                     // the Mist body: no tail (M l. 52845)
        case 0x41f, 0x420:                                 // Xichrons (M l. 52847–52862)
            s.hotRect = rect(2, 2, 0x1e, 0x1e)
            s.phase &+= 1
            if 0x13 < s.phase { s.phase = 0 }
            s.face = FaceRef(pict: 0x421, index: Int(s.phase >> 1), set: .encoded)
            if s.inWaterAtSpawn != 0 {
                s.lastWater = 1
                s.waterRow = 1
            }
            if t == 0x420 { s.mode = 0x10001 }
        case 0x423:
            break
        case 0x50a, 0x50b:
            glint(10)
        case 0x50c, 0x50d:
            glint(0x28)
        case 0x4bf...0x4c2:                                // shards (M l. 52914–52932)
            s.lightOverlay = false
            if -0xd < s.counterA6 { s.mode = 0xb0001 }
            if -9 < s.counterA6 { s.mode = 0xb0000 }
            if -5 < s.counterA6 { s.mode = 0xb0002 }
            if -1 < s.counterA6 {
                s.mode = 0
                s.face = nil
                if s.killCount == 0 { s.killCount = 1 }
            }
        case 0x546:                                        // the air bubble (M l. 53002–53006)
            s.face = FaceRef(pict: 0x546, index: 0, set: .encoded)
            s.waterRow = 1
        case 0x514, 0x515:                                 // crystals (M l. 53012–53023)
            s.counterA6 = 0
            s.pickupDelay = 0
            s.phase &+= 1
            if 5 < s.phase { s.phase = 0 }
            s.face = FaceRef(pict: t, index: Int(s.phase), set: .encoded)
        case 0x517:
            s.face = FaceRef(pict: 0x517, index: 0, set: .encoded)
        case 0x516, 0x518, 0x519, 0x51a:                   // coins (M l. 53034–53069)
            if s.pickupDelay > 0 { s.pickupDelay -= 1 }
            s.phase &+= 1
            if 0x11 < s.phase { s.phase = 0 }
            let cell = Int(s.phase >> 1)
            if t == 0x516 { s.face = FaceRef(pict: 0x516, index: cell, set: .encoded) }
            if t == 0x519 { s.face = FaceRef(pict: 0x51d, index: cell, set: .encoded) }
            if t == 0x51a { s.face = FaceRef(pict: 0x51e, index: cell, set: .encoded) }
            if Int(w.level.header.gridHeight) << 5 < s.y { kill(w, &s, lights: &lights) }
            if s.coinLife < 0 {
                s.coinLife &+= 1
                if -0x2d < s.coinLife {
                    s.lightOverlay = false
                    s.mode = w.parity ? 0xb0000 : 0
                }
                if -1 < s.coinLife { kill(w, &s, lights: &lights) }
            }
        case 0xbea:
            s.face = FaceRef(pict: 0xbea, index: 0, set: .encoded)
        case 0x51b, 0xc1c...0xc25:                         // `LAB_1005f00c` (M l. 53108–53294)
            torchArm(w, &s, effects: effects, change: change)
        default:
            // `LAB_1005f808`: every type no arm above takes (the spheres, upgrades, scrolls, items, 0x422, …).
            loot(&s, effects: effects, change: change)
        }
        w.active.update(id: id) { $0 = s }

        // `LAB_1005fc30`: the tail.
        w.active.update(id: id) { $0.applyFriction($0.friction) }
        if let c = w.active.record(id: id), 0 < c.gravity, c.type != 0x517, c.type != 0x41f, c.type != 0x420 {
            solver.applyGravityAndSeparate(id, pass: pass(c))
        }
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
        if let c = w.active.record(id: id), c.light != -1, c.type != torch, !candelabras.contains(c.type) {
            lights.setPos(c.light, x: Int16(truncatingIfNeeded: c.centre.x), y: Int16(truncatingIfNeeded: c.centre.y))
        }
        return ops
    }

    /// `LAB_1005f00c` (M l. 53108–53294): the torch 0x51b and the candelabras. One `FastRand(100)` (the spark point of
    /// the candelabras' per-type alternatives); the spark point defaults to the centre (`+0xe`/`+0x10`). While
    /// `+0xb0 == 1` (unspent): at Effects 3 every other call (`+0xb2` toggled) one spark, else one spark and a second
    /// at Effects 1 — each `FastRand(1000)` (vy), `FastRand(1000)` (vx), `FastRand(2)` (shape) then
    /// `.NewParticle(kind, 0, point, shape + 1, vx − 500, vy − 500, 0, 1)`, kind 1 (0xb for 0xc1f, 0xc for 0xc23).
    /// Kind 1 and not the torch: each non-zero flame point (up to four) → `FastRand(3)` (h += r − 1), `FastRand(100)`
    /// → `.NewParticle(1, 0, point, 1, 0, −0x32 − r, 0, 0)`. Effects 1: `.ChangeLightFace(0x321)`, `+0x14c` − 1; below
    /// 0xb: at 3 or 7 `.ChangeLightFace(0x322)`; below 1 `+0x14c = FastRand(15) + 5`. The torch: `+0x46` 0…11, face set
    /// 0x51b cell `+0x46 >> 1`; `FastRand(0x1e) == 1` → `FastRand(600)` (vy), `FastRand(600)` (vx) →
    /// `.NewParticle(1, 0xb4, (y + 8, x + 4), 4, vx − 300, vy, 0, 1)`.
    static func torchArm(_ w: SpriteWorld, _ s: inout SpriteSlot, effects: Int16, change: (LightFaceRef?) -> Void) {
        typealias P = (v: Int, h: Int)
        let x = s.x, y = s.y
        var kind = 1
        var f: [P] = [(0, 0), (0, 0), (0, 0), (0, 0)]          // uStack_2a, _2e, _32, _36 (`uRam100a1a60…6c` = 0)
        let r = Int(w.rng.next(100))
        var point: P = (s.centre.y, s.centre.x)               // `uStack_26 = *(+0xe)`
        func p(_ dx: Int, _ dy: Int) -> P { (h(y + dy), h(x + dx)) }
        switch Int(s.type) {
        case 0xc1c:
            f = [p(6, 0x17), p(0xd, 0x10), p(0x13, 0x10), p(0x19, 0x16)]
            point = r < 0x1a ? f[3] : r < 0x33 ? f[2] : r < 0x4c ? f[1] : f[0]
        case 0xc1d:
            f = [p(8, 0x13), p(0x12, 0xf), p(0x1b, 0xb), (0, 0)]
            point = r < 0x22 ? f[2] : r < 0x43 ? f[1] : f[0]
        case 0xc1e:
            f = [p(0xb, 10), p(0x17, 6), (0, 0), (0, 0)]
            point = r < 0x33 ? f[1] : f[0]
        case 0xc1f:
            kind = 0xb
            point = p(0xf, 8)
        case 0xc20, 0xc21:
            f = [p(0xd, 0xe), p(0x14, 9), p(0x1b, 0xe), (0, 0)]
            point = p(0x14, 9)
        case 0xc22:
            f = [p(10, 3), p(0x13, 7), p(0x1c, 0xb), (0, 0)]
            point = p(0x13, 7)
        case 0xc23:
            kind = 0xc
            point = p(0x13, 0x1a)
        case 0xc24:
            f = [p(0xc, 0x18), p(0x1c, 0x18), (0, 0), (0, 0)]
            point = r < 0x33 ? f[1] : f[0]
        default:
            break                                              // the torch (and 0xc25): the centre
        }
        func spark() {
            let vy = Int(w.rng.next(1000)), vx = Int(w.rng.next(1000)), shape = Int(w.rng.next(2))
            w.particles.newParticle(kind: kind, gravity: 0, v: point.v, h: point.h, shape: shape + 1, vx: vx - 500,
                                    vy: vy - 500, delay: 0, mode: 1)
        }
        if s.pickupDelay == 1 {
            if effects == 3 {
                s.subState = s.subState == 0 ? 1 : 0
                if s.subState == 1 { spark() }
            } else {
                spark()
                if effects == 1 { spark() }
            }
        }
        if kind == 1 && s.type != torch {
            for q in f where q.v != 0 || q.h != 0 {
                let dh = Int(w.rng.next(3))
                let vy = Int(w.rng.next(100))
                w.particles.newParticle(kind: 1, gravity: 0, v: q.v, h: h(q.h - 1 + dh), shape: 1, vx: 0,
                                        vy: -0x32 - vy, delay: 0, mode: 0)
            }
        }
        if effects == 1 {
            change(torchLight)
            s.lightTimer &-= 1
            if s.lightTimer < 0xb {
                if s.lightTimer == 3 || s.lightTimer == 7 { change(torchLight2) }
                if s.lightTimer < 1 { s.lightTimer = Int32(w.rng.next(0xf)) + 5 }
            }
        }
        if s.type == torch {
            s.phase &+= 1
            if 0xb < s.phase { s.phase = 0 }
            s.face = FaceRef(pict: 0x51b, index: Int(s.phase >> 1), set: .encoded)
            if w.rng.next(0x1e) == 1 {
                let vy = Int(w.rng.next(600)), vx = Int(w.rng.next(600))
                w.particles.newParticle(kind: 1, gravity: 0xb4, v: h(y + 8), h: h(x + 4), shape: 4, vx: vx - 300,
                                        vy: vy, delay: 0, mode: 1)
            }
        }
    }

    /// `LAB_1005f808` (M l. 53297–53409): `+0xb0` counts down to 0; then a type < 2000 or Effects 3 — the spheres and
    /// the upgrades (no arm for the rest); else the item twinkle (`BonusHandle`, k = (`+0x46` >> 2) mod 6).
    /// - Upgrades 0x53c / 0x53d: `+0x46` 0…19, cell `+0x46 >> 1` folded at 5 (10 − c), `+0x88 = 0`, `+0x15c` + 1,
    ///   k = (`+0x15c` / 3) mod 6: 0 → `+0xb8 = 0` and light 0x326; 1, 5 → 0x32a; 2, 4 → 0x32b; 3 → 0x32c.
    /// - Spheres 0x532…0x53b while `+0xa6 < 1`: face `_DAT_100a089c[t − 0x532]`, `+0x88 = 0`, `+0x46` + 1,
    ///   k = (`+0x46` / 3) mod 6: 0 → `+0xb8` 0 / 0x32a; 1, 5 → 0xb0001 / 0x32b; 2, 4 → 0xb0000 / 0x32c; 3 → 0xb0002 /
    ///   0x32d (k < 0 after the Int16 wrap: nothing). Hidden (`+0xa6 ≥ 1`): `+0xa6` − 1, face 0,
    ///   `.ChangeLightFace(+0x9a, 0)`.
    static func loot(_ s: inout SpriteSlot, effects: Int16, change: (LightFaceRef?) -> Void) {
        if s.pickupDelay > 0 { s.pickupDelay -= 1 }
        let t = s.type
        if t < 2000 || effects == 3 {
            if (0x532...0x53b).contains(t) {
                if s.counterA6 < 1 {
                    s.face = FaceRef(pict: t, index: 0, set: .encoded)
                    s.lightOverlay = false
                    s.phase &+= 1
                    let k = (s.phase / 3) % 6
                    switch k {
                    case 0: s.mode = 0; change(twinkleLight(0))
                    case 1, 5: s.mode = 0xb0001; change(twinkleLight(1))
                    case 2, 4: s.mode = 0xb0000; change(twinkleLight(2))
                    case 3: s.mode = 0xb0002; change(twinkleLight(3))
                    default: break
                    }
                } else {
                    s.counterA6 -= 1
                    s.face = nil
                    change(nil)
                }
            } else if t == 0x53c || t == 0x53d {
                s.phase &+= 1
                if 0x13 < s.phase { s.phase = 0 }
                var c = s.phase >> 1
                if 5 < c { c = 10 - c }
                s.face = FaceRef(pict: t, index: Int(c), set: .encoded)
                s.lightOverlay = false
                s.inWaterAtSpawn &+= 1                    // `+0x15c` (the upgrades' light counter)
                let k = Int16(truncatingIfNeeded: s.inWaterAtSpawn / 3) % 6
                switch k {
                case 0: s.mode = 0; change(upgradeLight0)
                case 1, 5: change(twinkleLight(0))
                case 2, 4: change(twinkleLight(1))
                case 3: change(twinkleLight(2))
                default: break
                }
            }
        } else {
            s.phase &+= 1
            let k = (s.phase >> 2) % 6
            guard k >= 0 else { return }
            change(twinkleLight(BonusHandle.twinkleOrder[Int(k)]))
        }
    }

    // MARK: - hit callbacks

    /// `.HitBonusSprite(self, other) @ 1005fd38` (M l. 53444–53536): 0x4bf returns at once (M l. 53468). The
    /// containers 0x51b, 0x517 and 0xc1c…0xc25 take the player-shot arm `LAB_1005fd94` (`container`, SH) — and nothing
    /// else. Any other Bonus rests on a Platform or Box (by the other's Handle; not the player) unless it is a scroll or
    /// low item (2000 ≤ t ≤ 0xc80) or the other is a chest 0x51c: `.PlatformBounce(self, other, own rect centre, f,
    /// own rect, f == 0x80)` with f = 0x80, or 0 when `vy < 0x180` (BC49: raw `1005ffb8..1005ffd0`).
    /// - Parameters: `lights` the session's table, `effects` prefs+6, `faceWidth` / `faceBounds` the face reads — the
    ///   container arm's `.KillPlayerShot`, `.KillBonus` and the crystal's Setup.
    public static func hit(_ w: SpriteWorld, id: Int, other: Int, lights: inout LightTable, effects: Int16 = 1,
                           faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                           faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard let s = w.active.record(id: id), let o = w.active.record(id: other) else { return }
        let t = s.type
        if t == 0x4bf { return }
        if t == torch || t == 0x517 || candelabras.contains(t) {
            container(w, id: id, shot: other, lights: &lights, effects: effects, faceWidth: faceWidth,
                      faceBounds: faceBounds)
            return
        }
        guard !o.handleCleared, o.handler == .platform || o.handler == .box, t < 2000 || 0xc80 < t,
              o.type != 0x51c else { return }
        let r = s.hotRect
        let centre = SpriteSlot.Point(x: h(r.left + h((r.right - r.left) >> 1)), y: h(r.top + h((r.bottom - r.top) >> 1)))
        let f: Int32 = s.vy < 0x180 ? 0 : 0x80
        w.platformBounce(mover: id, solid: other, centre: centre, factor: f, rect: r, bounce: f != 0)
    }

    /// The test-only form (no light table): its light calls go to a scratch table.
    static func hit(_ w: SpriteWorld, id: Int, other: Int) {
        var scratch = LightTable()
        hit(w, id: id, other: other, lights: &scratch)
    }

    /// The container arm `LAB_1005fd94` of `.HitBonusSprite` (M l. 53472–53503; raw `1005fd94..1005ff24`;
    /// pickups-boxes §1.5): only a player shot (`PTR_PTR_100a04e8`) that is not the orb 0x50 with `+0xa6 == 0`. G's
    /// magic, health, max health and max magic are read first (`G+0xe`, `+4`, `+0xa`, `+0xc`). The torch 0x51b and the
    /// candelabras: spent (`+0xb0 == 0`) → nothing (the shot is not consumed); else `+0xb0 = 0`, `SetRect(+0x34, 0, 0, 0,
    /// 0)` and the record's p4 = 1 (`*(*_DAT_100a0058) + +0x48·0x10 + 0xe`, raw `1005fe48`); the rock pile 0x517:
    /// `.KillBonus`. Then `.KillPlayerShot(shot, 1, 1)` (its stale r29 here is G + 4: the short at G + 0x9e, inventory
    /// slot 12's count, `PlayerShotHits.kill`), score `G+0` + 0x96 and the crystal — 0x514 when `(magic << 8) / max
    /// magic < (health << 8) / max health` (`cmpw r28,r25; ble`, raw `1005fe74`) and the live health `G+4` > 0x25
    /// (`bgt`), else 0x515 — `MTNewSprite(type, +0x10 − 9, +0xe − 9, 2, −1, .SetupBonusSprite)` (its Setup's draws),
    /// then `FastRand(1000)` and `vy = −2000 − R` (drawn even with no free record, Ruling 16). A maximum of 0 (`divw`
    /// by 0, undefined on the PPC) is taken as a quotient of 0 [LOW: no maximum is ever 0].
    static func container(_ w: SpriteWorld, id: Int, shot: Int, lights: inout LightTable, effects: Int16,
                          faceWidth: (FaceRef) -> Int, faceBounds: (FaceRef) -> IdleSprites.Rect) {
        guard let s = w.active.record(id: id), let o = w.active.record(id: shot), o.handler == .playerShot,
              o.type != PlayerShot.orb, o.counterA6 == 0 else { return }
        let g = w.globals
        func q(_ n: Int16, _ d: Int16) -> Int32 { d == 0 ? 0 : (Int32(n) << 8) / Int32(d) }
        let magicPct = q(g.magic, g.maxMagic), healthPct = q(g.health, g.maxHealth)
        if s.type == torch || candelabras.contains(s.type) {
            guard s.pickupDelay != 0 else { return }
            w.active.update(id: id) { b in
                b.pickupDelay = 0
                b.hotRect = rect(0, 0, 0, 0)
            }
            let i = Int(s.recordIndex)
            if w.records.indices.contains(i) {                         // `+0x48` −1: no record (none on the levels)
                let p = w.records[i]
                w.records[i] = Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: p.p1, p2: p.p2,
                                         p3: p.p3, p4: 1, y: p.y, x: p.x)
            }
        } else {
            kill(w, id: id, lights: &lights)
        }
        PlayerShotHits.kill(w, shot: shot, sound: true, effect: true, effects: effects, lights: &lights,
                            faceWidth: faceWidth, faceBounds: faceBounds, staleSlot: w.globals.inventory[12].count)
        w.globals.score &+= 0x96
        let type: Int16 = magicPct < healthPct && 0x25 < w.globals.health ? 0x514 : 0x515
        let x = h(s.centre.x - 9), y = h(s.centre.y - 9)
        let crystal = w.newSprite(type: type, x: x, y: y, layer: 2, handler: .bonus) { c in
            // Cannot throw: `setup` throws only for 0xc25 and out-of-table item faces — never for 0x514 / 0x515.
            _ = try! setup(&c, x: x, y: y, level: w.level, records: w.records, effects: effects,
                           lightCount: lights.count, counting: false, rng: &w.rng) { f, lh, lv, colour in
                lights.add(face: f, x: Int16(truncatingIfNeeded: lh), y: Int16(truncatingIfNeeded: lv), vx: 0, vy: 0,
                           accelY: 0, colour: colour)
            }
        }
        let r = w.rng.next(1000)
        if let crystal { w.active.update(id: crystal) { $0.vy = -2000 - Int32(r) } }
    }

    /// `.HitBonusTileSprite(s, pos, kind, layer) @ 1006010c` (M l. 53571–53638). The debug no-clip skip (`_DAT_100a0064`
    /// and key 0x32) is not built. Factor 0x80; 0x40 for the money bags 0x50c / 0x50d; 0xe0 for the shards 0x4bf…0x4c1.
    /// FG: unless kind 0x67 while rising (`vy < 0`), `.WallBounce(…, f, rect, bounce 1)`; a hit of a money bag with
    /// |vy| > 0x100 → `.STPlay3DSoundRand(489, 1, 0x55, centre)` (`*_DAT_100a0300`; raw `10060278`). BG < 100
    /// `.WallBounce`, 100…199 `.WallBounceBG(kind − 100)` (both f, bounce 1), water → `.HandleUnderWater` unless
    /// `+0x140`. Layer 2 (a crunch nibble) → `+0x118 = 0`.
    public static func hitTile(_ solver: TileSolver, id: Int, pos posIn: TilePos, kind: Int, layer: TileLayer) {
        let w = solver.world
        guard let s = w.active.record(id: id) else { return }
        var pos = posIn
        let t = s.type
        var f: Int16 = 0x80
        if t == 0x50c || t == 0x50d { f = 0x40 }
        if 0x4be < t && t < 0x4c2 { f = 0xe0 }
        let r = s.hotRect
        let vCentre = h(r.top + h((r.bottom - r.top) >> 1))
        let k = Int16(truncatingIfNeeded: kind)
        switch layer {
        case .foreground:
            if k != 0x67 || -1 < s.vy,
               solver.wallBounce(id, kind: kind, tile: &pos, vCentre: vCentre, factor: f, rect: r, bounce: true) {
                guard let c = w.active.record(id: id) else { return }
                let m = c.vy < 1 ? 0 &- c.vy : c.vy
                if 0x100 < m && (c.type == 0x50c || c.type == 0x50d) {
                    w.player.cue(PlayerCue(call: .threeDRand, snd: 489, priority: 1, volume: 0x55, position: c.centre,
                                           rate: w.rng.soundRate()))
                }
            }
        case .background:
            if k < 100 {
                solver.wallBounce(id, kind: kind, tile: &pos, vCentre: vCentre, factor: f, rect: r, bounce: true)
            } else if k < 200 {
                solver.wallBounceBG(id, kind: kind - 100, tile: &pos, vCentre: vCentre, factor: f, rect: r, bounce: true)
            } else if UnderWater.isWaterTile(kind), w.active.record(id: id)?.underwaterDone == false {
                UnderWater.handle(world: w, id: id, pos: pos)
            }
        case .crunch:
            w.active.update(id: id) { $0.waterGate = 0 }
        }
    }
}
