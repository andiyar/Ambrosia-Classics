import XCTest
@testable import FerazelCore

/// W3 (docs/plans/2026-10-10-ferazel-phase2.md): the Box class standing still as solids (`.SetupBoxSprite @ 1006b43c`,
/// the Box arm of `.HitPlayerSprite` M l. 49149–49362), the trampoline 1470 (`.HandleBoxSprite` M l. 60555–60563), and
/// the ropes 3020–3022 (`.SetupRopeSprite` M l. 71078, `.SetupRopeSegArray` 71245, `.GetRopeHeight` 71197,
/// `.HandleRopeSprite` 71506, `.RopeCollide` 43863), against the committed `Resources/Ferazel` (D26). Pickups-boxes
/// §2.1–§2.2, §2.4.11; physics-sprites §8.2; platforms-ropes-radial §3. A missing data file is a FAILURE, never a skip.
final class BoxRopeTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// A world on `level` holding a player at (x, y) with the pixel copy the first separation leaves.
    private func world(level: Int16 = 1, playerX: Int = 2000, playerY: Int = 1000) throws -> (SpriteWorld, Int) {
        let L = try LevelFile.load(from: try resources(), level: level)
        let w = SpriteWorld(level: L)
        let p = try XCTUnwrap(Player.spawn(world: w, x: playerX, y: playerY))
        w.playerID = p
        w.active.update(id: p) { $0.x = playerX; $0.y = playerY }
        return (w, p)
    }

    private func placement(_ index: Int, _ type: Int16, p1: Int16 = 0, p2: Int16 = 0, p3: Int16 = 0, p4: Int16 = 0,
                           x: Int16, y: Int16) -> Placement {
        Placement(index: index, flag: 1, byte1: 0, type: type, p1: p1, p2: p2, p3: p3, p4: p4, y: y, x: x)
    }

    /// The sprite `SetupFaces` (→ `BoxSprite.setup` / `RopeSprite.setup`) leaves for `p`, inserted into `w`; the record
    /// is put into the world's table (synthetic records index past the level's).
    @discardableResult
    private func add(_ w: SpriteWorld, _ p: Placement) throws -> Int {
        let e = try SetupFaces.setup(p, context: SetupFaces.Context(level: w.level, playerX: 0))
        if p.index < w.records.count { w.records[p.index] = p }
        return w.active.insert(e.slot)
    }

    /// A Box made by `BoxSprite.setup` alone (types whose face `SetupFaces` does not transcribe).
    private func addBox(_ w: SpriteWorld, _ p: Placement) -> Int {
        var s = SpriteSlot(type: p.type, x: Int(p.x), y: Int(p.y), recordIndex: Int16(p.index))
        BoxSprite.setup(&s, record: p, level: w.level)
        return w.active.insert(s)
    }

    /// Puts the player so that his feet (`y + 0x55`) are `overlap` px below `top`, his rect's x span over `x`, moving
    /// down at `vy` (previous feet `overlap − vy >> 8` px from the top).
    private func dropPlayer(_ w: SpriteWorld, _ p: Int, ontoTop top: Int, x: Int, vy: Int32, overlap: Int = 4) {
        let r = HandleKeys.standardHotRect
        w.active.update(id: p) { s in
            s.x = x - r.left - 4
            s.y = top + overlap - r.bottom
            s.x256 = Int32(s.x) << 8
            s.y256 = Int32(s.y) << 8
            s.vx = 0
            s.vy = vy
            s.groundKind = 0
            s.ridden = nil
            s.centre = SpriteSlot.Point(x: s.x + 0x32, y: s.y + 0x3b)    // as `.StandardSpriteCleanup` leaves it
        }
    }

    // MARK: - Box solids

    func testBridgeIsTwoWaySolid() throws {
        // `.SetupBoxSprite` bridge arm (M l. 59157–59208): gravity 0, `+0x185 = 0`, layer 0, `+0x17e = 0`, `+0x5c = 0`;
        // 0x5b5 / 0x5b6 SetRect(6, 0, 0x9e, 0x18) (0x5b6 flipped), 0x5b8 SetRect(8, 0, 0x8c, 0x28).
        let (w2, p2) = try world(level: 2)
        let L2 = w2.level
        XCTAssertEqual([L2.placements[60].type, L2.placements[61].type], [1461, 1462])
        let e60 = try SetupFaces.setup(L2.placements[60], context: SetupFaces.Context(level: L2, playerX: 0))
        let e61 = try SetupFaces.setup(L2.placements[61], context: SetupFaces.Context(level: L2, playerX: 0))
        for e in [e60, e61] {
            XCTAssertEqual(e.slot.hotRect, IdleSprites.Rect(top: 0, left: 6, bottom: 0x18, right: 0x9e))
            XCTAssertFalse(e.slot.oneWay)
            XCTAssertEqual([Int(e.slot.layer), Int(e.slot.gravity), Int(e.slot.hp), Int(e.slot.counterA6),
                            Int(e.slot.pushForce)], [0, 0, 600, 3, 0x80])
            XCTAssertEqual([e.slot.hasHit, e.slot.hasTileHit], [false, true])
            XCTAssertEqual(e.slot.handler, .box)
            XCTAssertEqual(e.slot.face, FaceRef(pict: 0x5b5, index: 0, set: .encoded))   // cache 0x5b5 (`_DAT_100a0a40`)
        }
        XCTAssertEqual([e60.slot.mirrored, e61.slot.mirrored], [false, true])
        let (w1, _) = try world(level: 1)
        XCTAssertEqual(w1.level.placements[87].type, 1464)
        let e87 = try SetupFaces.setup(w1.level.placements[87], context: SetupFaces.Context(level: w1.level, playerX: 0))
        XCTAssertEqual(e87.slot.hotRect, IdleSprites.Rect(top: 0, left: 8, bottom: 0x28, right: 0x8c))
        XCTAssertFalse(e87.slot.oneWay)
        XCTAssertEqual(e87.slot.face, FaceRef(pict: 0x5b8, index: 0, set: .encoded))
        // The other bridges of the arm (unplaced): 0x5b4 / 0x5b7 (0, 0, 0x108, 0x18 / 0x28), 0x5b9 (0xe, 0, 0x92, 0x28)
        // flipped, 0x5ba (−0x10, 0x32, 0x11c, 0x78), 0x5bb layer 0x32 and an empty rect.
        let rects: [(Int16, IdleSprites.Rect, Bool, Int32)] = [
            (0x5b4, IdleSprites.Rect(top: 0, left: 0, bottom: 0x18, right: 0x108), false, 0),
            (0x5b7, IdleSprites.Rect(top: 0, left: 0, bottom: 0x28, right: 0x108), false, 0),
            (0x5b9, IdleSprites.Rect(top: 0, left: 0xe, bottom: 0x28, right: 0x92), true, 0),
            (0x5ba, IdleSprites.Rect(top: 0x32, left: -0x10, bottom: 0x78, right: 0x11c), false, 0),
            (0x5bb, IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0), false, 0x32),
        ]
        for (t, r, flip, layer) in rects {
            var s = SpriteSlot(type: t, x: 100, y: 100)
            BoxSprite.setup(&s, record: placement(0, t, x: 100, y: 100), level: w1.level)
            XCTAssertEqual(s.hotRect, r, "type \(t)")
            XCTAssertEqual([s.mirrored, s.oneWay, s.hasHit], [flip, false, false], "type \(t)")
            XCTAssertEqual(s.layer, layer, "type \(t)")
        }

        // Two-way: the player rising into the bridge from below is stopped (`.RectBounce` return 2: vy 0, his top
        // under the bridge, `+0xcf = 1`); a one-way top (the teleporter 1062) lets him through.
        let b = try add(w2, L2.placements[60])
        let bs = try XCTUnwrap(w2.active.sprite(id: b))
        let r = HandleKeys.standardHotRect
        w2.active.update(id: p2) { s in
            s.x = bs.x + 0x30
            s.y = bs.y + 0x18 - r.top - 4                               // top 4 px into the bridge's bottom
            s.x256 = Int32(s.x) << 8
            s.y256 = Int32(s.y) << 8
            s.vy = -0x800
            s.ceilingHit = 0
            s.centre = SpriteSlot.Point(x: s.x + 0x32, y: s.y + 0x3b)
        }
        HitPlayerSprite.hit(w2, player: p2, other: b)
        var ps = try XCTUnwrap(w2.active.sprite(id: p2))
        XCTAssertEqual(ps.vy, 0)
        XCTAssertEqual(ps.y, bs.y + 0x18 - r.top)
        XCTAssertEqual(ps.ceilingHit, 1)
        XCTAssertNil(ps.ridden)
        // From above it lands: ridden = the bridge, ground kind 3, the bridge's rider and latch.
        dropPlayer(w2, p2, ontoTop: bs.y, x: bs.x + 0x30, vy: 0x300)
        HitPlayerSprite.hit(w2, player: p2, other: b)
        ps = try XCTUnwrap(w2.active.sprite(id: p2))
        XCTAssertEqual([ps.vy, Int32(ps.groundKind)], [0, 3])
        XCTAssertEqual(ps.ridden, b)
        XCTAssertEqual(ps.y, bs.y - r.bottom)
        XCTAssertFalse(ps.oneWayLanded)                                  // a two-way top
        XCTAssertEqual(w2.active.sprite(id: b)?.rider, p2)
        XCTAssertEqual(w2.active.sprite(id: b)?.ridingLatch, true)

        let t = try add(w2, L2.placements[13])                           // 1062, one-way
        let ts = try XCTUnwrap(w2.active.sprite(id: t))
        XCTAssertTrue(ts.oneWay)
        w2.active.update(id: p2) { s in
            s.x = ts.x - 0x20
            s.y = ts.y + 0x1a - r.top - 4
            s.x256 = Int32(s.x) << 8
            s.y256 = Int32(s.y) << 8
            s.vy = -0x800
            s.ceilingHit = 0
            s.ridden = nil
            s.centre = SpriteSlot.Point(x: s.x + 0x32, y: s.y + 0x3b)
        }
        let y0 = try XCTUnwrap(w2.active.sprite(id: p2)).y
        HitPlayerSprite.hit(w2, player: p2, other: t)
        ps = try XCTUnwrap(w2.active.sprite(id: p2))
        XCTAssertEqual([ps.vy, Int32(ps.y), Int32(ps.ceilingHit)], [-0x800, Int32(y0), 0])

        // The bridge Handle (`.HandleBoxSprite` M l. 60565–60591): the face from the class cache every frame, then the
        // common tail's `.BoxClean` (M l. 60000–60015): the centre from the hot rect, `+0xdc = 0`, `+0xd6 = 0`.
        w2.active.update(id: b) { $0.face = nil; $0.slope = 7 }
        BoxSprite.handle(world: w2, id: b)
        var bh = try XCTUnwrap(w2.active.sprite(id: b))
        XCTAssertEqual(bh.face, FaceRef(pict: 0x5b5, index: 0, set: .encoded))
        XCTAssertEqual([bh.centre.x, bh.centre.y], [bs.x + 6 + ((0x9e - 6) >> 1), bs.y + (0x18 >> 1)])
        XCTAssertEqual(bh.slope, 0)
        XCTAssertEqual([bh.x, bh.y, Int(bh.y256 >> 8)], [bs.x, bs.y, bs.y])   // gravity 0: stands still
        // `.StandardSpriteHandles` runs first: riding a vanished record (ids past the list read 0s) carries y by
        // + 0x100 and sets `+0xce = 3` (copied to `+0xcd` by the tail); `.BoxClean` then clears `+0xdc`.
        w2.active.update(id: b) { $0.ridden = 99 }
        BoxSprite.handle(world: w2, id: b)
        bh = try XCTUnwrap(w2.active.sprite(id: b))
        XCTAssertNil(bh.ridden)
        XCTAssertEqual([bh.y, bh.centre.y, Int(bh.groundKind), Int(bh.onSprite)], [bs.y + 1, bs.y + 1 + 12, 3, 3])
        // The flipped 1462 (0x5b6) takes the same class cache as 0x5b5 (M l. 60571–60576: both read `iVar14`).
        let b61 = try add(w2, L2.placements[61])
        w2.active.update(id: b61) { $0.face = nil }
        BoxSprite.handle(world: w2, id: b61)
        XCTAssertEqual(w2.active.sprite(id: b61)?.face, FaceRef(pict: 0x5b5, index: 0, set: .encoded))
    }

    func testTrampolineBounce() throws {
        // The Box arm (M l. 49308–49362, raw `10057278..10057324`): `.PlatformBounce` return 1 → `+0x46 = 1` (before the
        // threshold test); entry vy ≤ 0xa5a (`cmpwi r25,0xa5a; ble`) → return; else vy = max(−6500, −(0.6·g + vy))
        // (`lfd` 0.6 @ `0x100a1a10`, −6500 @ `0x100a1a08`, `fnmsub`, `fctiwz`), `.STPlayRegSound(604, 1, 0x100)`
        // (`_DAT_100a027c`), the air counter `_DAT_100a0718 = 1`, `+0xce = 0`.
        let (w, p) = try world(level: 2)
        let L2 = w.level
        XCTAssertEqual(L2.placements[62].type, 1470)
        let e = try SetupFaces.setup(L2.placements[62], context: SetupFaces.Context(level: L2, playerX: 0))
        XCTAssertEqual(e.slot.hotRect, IdleSprites.Rect(top: 0x10, left: 7, bottom: 0x37, right: 0x2c))
        XCTAssertTrue(e.slot.oneWay)
        XCTAssertEqual([Int(e.slot.layer), Int(e.slot.gravity), Int(e.slot.phase)], [0x3c, 0, 0])
        XCTAssertEqual([e.slot.hasHit, e.slot.hasTileHit], [false, false])
        XCTAssertEqual(e.slot.face, FaceRef(pict: 0x5be, index: 0, set: .encoded))
        XCTAssertEqual(e.sheet, SetupFaces.Sheet(pict: 0x5be, count: 4, cellWidth: 0x36, cellHeight: 0x38, columns: 4,
                                                 clut: 200))
        XCTAssertEqual(e.source, .setupCached)
        let t = try add(w, L2.placements[62])
        let ts = try XCTUnwrap(w.active.sprite(id: t))

        func bounce(_ vy: Int32, gravity: Int16 = 440) throws -> SpriteSlot {
            w.player.cues = []
            w.player.airCounter = 7
            w.active.update(id: t) { $0.phase = 0 }
            w.active.update(id: p) { $0.gravity = gravity }
            dropPlayer(w, p, ontoTop: ts.y + 0x10, x: ts.x + 7, vy: vy)
            HitPlayerSprite.hit(w, player: p, other: t)
            XCTAssertEqual(w.active.sprite(id: t)?.phase, 1, "vy \(vy)")
            return try XCTUnwrap(w.active.sprite(id: p))
        }
        XCTAssertEqual(Player.gravity, 440)
        var s = try bounce(4096)
        XCTAssertEqual(s.vy, -4360)
        XCTAssertEqual(s.groundKind, 0)
        XCTAssertEqual(s.ridden, t)                                       // `.PlatformBounce` left it
        XCTAssertEqual(s.y, ts.y + 0x10 - 0x55)
        XCTAssertEqual(w.player.airCounter, 1)
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .reg, snd: 604, priority: 1, volume: 0x100)])
        // The threshold: 0xa5a stands (vy 0 from the landing, ground kind 3, no cue, counter kept); 0xa5b bounces.
        s = try bounce(2650)
        XCTAssertEqual([s.vy, Int32(s.groundKind)], [0, 3])
        XCTAssertEqual(w.player.airCounter, 7)
        XCTAssertEqual(w.player.cues, [])
        s = try bounce(0xa5b)
        XCTAssertEqual(s.vy, -(0xa5b + 264))
        // The cap and the truncation toward zero: −(7000 + 264) → −6500; −(4096 + 264.6) → −4360; g 0 → −vy.
        s = try bounce(7000)
        XCTAssertEqual(s.vy, -6500)
        s = try bounce(6236)
        XCTAssertEqual(s.vy, -6500)                                       // −6500.0 exactly
        s = try bounce(6237)
        XCTAssertEqual(s.vy, -6500)
        s = try bounce(6235)
        XCTAssertEqual(s.vy, -6499)
        s = try bounce(4096, gravity: 441)
        XCTAssertEqual(s.vy, -4360)
        s = try bounce(4096, gravity: 0)
        XCTAssertEqual(s.vy, -4096)
        // A one-way miss (feet already 9 px past the top before the move): no landing, `+0x46` untouched.
        w.active.update(id: t) { $0.phase = 0 }
        dropPlayer(w, p, ontoTop: ts.y + 0x10, x: ts.x + 7, vy: 0x100, overlap: 10)
        HitPlayerSprite.hit(w, player: p, other: t)
        XCTAssertEqual(w.active.sprite(id: t)?.phase, 0)
        XCTAssertEqual(w.active.sprite(id: p)?.vy, 0x100)
    }

    func testTrampolineFaceSquash() throws {
        // `.HandleBoxSprite` 0x5be (M l. 60555–60563): face = cache set `_DAT_100a0a2c` [+0x46]; then, when `+0x46 > 0`,
        // `+0x46 += 1` and past 3 → 0. A landing sets 1 (the arm above) — so the faces after one bounce are 1, 2, 3, 0,
        // and a player standing on it re-sets 1 every contact: held at 1.
        let (w, p) = try world(level: 2)
        let t = try add(w, w.level.placements[62])
        let ts = try XCTUnwrap(w.active.sprite(id: t))
        func face() -> Int? { w.active.sprite(id: t)?.face?.index }
        BoxSprite.handle(world: w, id: t)
        XCTAssertEqual(face(), 0)
        XCTAssertEqual(w.active.sprite(id: t)?.phase, 0)                  // 0 never counts
        dropPlayer(w, p, ontoTop: ts.y + 0x10, x: ts.x + 7, vy: 4096)
        HitPlayerSprite.hit(w, player: p, other: t)
        var faces: [Int] = [], phases: [Int16] = []
        for _ in 0..<5 {
            BoxSprite.handle(world: w, id: t)
            faces.append(face() ?? -1)
            phases.append(w.active.sprite(id: t)?.phase ?? -1)
        }
        XCTAssertEqual(faces, [1, 2, 3, 0, 0])
        XCTAssertEqual(phases, [2, 3, 0, 0, 0])
        XCTAssertEqual(w.active.sprite(id: t)?.face?.pict, 0x5be)
        // Stood on (a landing below the bounce threshold every contact): face 1 frame after frame.
        faces = []
        for _ in 0..<4 {
            dropPlayer(w, p, ontoTop: ts.y + 0x10, x: ts.x + 7, vy: 0x1b8)
            HitPlayerSprite.hit(w, player: p, other: t)
            BoxSprite.handle(world: w, id: t)
            faces.append(face() ?? -1)
        }
        XCTAssertEqual(faces, [1, 1, 1, 1])
        // Stepping off: the squash runs out.
        faces = []
        for _ in 0..<3 {
            BoxSprite.handle(world: w, id: t)
            faces.append(face() ?? -1)
        }
        XCTAssertEqual(faces, [2, 3, 0])
        // `+0x1b2` / `+0xe9` → the Handle returns at once.
        w.active.update(id: t) { $0.phase = 2; $0.handleSkip = true }
        BoxSprite.handle(world: w, id: t)
        XCTAssertEqual([face(), Int(w.active.sprite(id: t)?.phase ?? -1)], [0, 2])
        w.active.update(id: t) { $0.handleSkip = false; $0.dead = true }
        BoxSprite.handle(world: w, id: t)
        XCTAssertEqual([face(), Int(w.active.sprite(id: t)?.phase ?? -1)], [0, 2])
    }

    func testSignStandableOnlyWith15c() throws {
        // `.SetupBoxSprite` signs 0xb56…0xb5d (M l. 59280–59316): `+0x5c = 0`, `+0x1f8 = 0`, gravity 0, one-way, layer 0;
        // 0xb56 / 0xb5b SetRect(4, 7, 0x22, 0x1f) and `+0x15c = 1`. The Box arm (M l. 49304–49307): 0xb55 < type < 0xb5e
        // with `+0x15c == 0` → return before `.PlatformBounce`.
        let (w, p) = try world()
        XCTAssertEqual(w.level.placements[1].type, 2902)
        let sign = try add(w, w.level.placements[1])
        let ss = try XCTUnwrap(w.active.sprite(id: sign))
        XCTAssertEqual(ss.hotRect, IdleSprites.Rect(top: 7, left: 4, bottom: 0x1f, right: 0x22))
        XCTAssertEqual([ss.classWord15c, Int32(ss.layer), Int32(ss.gravity)], [1, 0, 0])
        XCTAssertEqual([ss.oneWay, ss.hasHit, ss.hasTileHit], [true, false, false])
        dropPlayer(w, p, ontoTop: ss.y + 7, x: ss.x + 4, vy: 0x300)
        HitPlayerSprite.hit(w, player: p, other: sign)
        var ps = try XCTUnwrap(w.active.sprite(id: p))
        XCTAssertEqual([ps.vy, Int32(ps.groundKind)], [0, 3])
        XCTAssertEqual(ps.ridden, sign)
        XCTAssertTrue(ps.oneWayLanded)

        // The other sign rects and `+0x15c` (M l. 59293–59316).
        let table: [(Int16, IdleSprites.Rect, Int32)] = [
            (0xb57, IdleSprites.Rect(top: 0, left: 0, bottom: 0x28, right: 0x1a), 0),
            (0xb58, IdleSprites.Rect(top: 0, left: 0, bottom: 0x1e, right: 0x14), 0),
            (0xb59, IdleSprites.Rect(top: 0, left: 0, bottom: 0x2d, right: 0x48), 0),
            (0xb5a, IdleSprites.Rect(top: 0, left: 0, bottom: 0x20, right: 0x34), 0),
            (0xb5b, IdleSprites.Rect(top: 7, left: 4, bottom: 0x1f, right: 0x22), 1),
            (0xb5c, IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0), 0),
        ]
        for (t, r, f) in table {
            var s = SpriteSlot(type: t, x: 100, y: 100)
            BoxSprite.setup(&s, record: placement(0, t, x: 100, y: 100), level: w.level)
            XCTAssertEqual([s.hotRect.top, s.hotRect.left, s.hotRect.bottom, s.hotRect.right, Int(s.classWord15c)],
                           [r.top, r.left, r.bottom, r.right, Int(f)], "type \(t)")
            XCTAssertTrue(s.oneWay)
        }

        // The gate reads `+0x15c`, not the type: 2903 (`+0x15c` 0) is walked through; the same sprite with 1 holds.
        let book = addBox(w, placement(600, 0xb57, x: 3000, y: 900))
        let bs = try XCTUnwrap(w.active.sprite(id: book))
        dropPlayer(w, p, ontoTop: bs.y, x: bs.x, vy: 0x300)
        HitPlayerSprite.hit(w, player: p, other: book)
        ps = try XCTUnwrap(w.active.sprite(id: p))
        XCTAssertEqual([ps.vy, Int32(ps.groundKind)], [0x300, 0])
        w.active.update(id: book) { $0.classWord15c = 1 }
        HitPlayerSprite.hit(w, player: p, other: book)
        XCTAssertEqual(w.active.sprite(id: p)?.vy, 0)
        // A 2902 with `+0x15c` 0 is walked through too (the low edge 0xb56); the door 0xb5e (past the range) is a solid
        // without it.
        w.active.update(id: sign) { $0.classWord15c = 0 }
        dropPlayer(w, p, ontoTop: ss.y + 7, x: ss.x + 4, vy: 0x300)
        HitPlayerSprite.hit(w, player: p, other: sign)
        XCTAssertEqual(w.active.sprite(id: p)?.vy, 0x300)
        let door = try add(w, w.level.placements[55])
        let ds = try XCTUnwrap(w.active.sprite(id: door))
        XCTAssertEqual(ds.type, 2910)
        XCTAssertEqual(ds.hotRect, IdleSprites.Rect(top: -0x40, left: 0, bottom: 0x98, right: 0x18))
        XCTAssertEqual([ds.classWord15c, Int32(ds.layer)], [0, 0])
        XCTAssertEqual([ds.oneWay, ds.hasHit], [false, true])
        dropPlayer(w, p, ontoTop: ds.y - 0x40, x: ds.x, vy: 0x300)
        HitPlayerSprite.hit(w, player: p, other: door)
        XCTAssertEqual(w.active.sprite(id: p)?.vy, 0)
        // An idled Box (`+0x4c` 0) is no Box: no arm.
        w.active.update(id: door) { $0.handleCleared = true }
        dropPlayer(w, p, ontoTop: ds.y - 0x40, x: ds.x, vy: 0x300)
        HitPlayerSprite.hit(w, player: p, other: door)
        XCTAssertEqual(w.active.sprite(id: p)?.vy, 0x300)
    }

    func testBoxSolidRectsLevels1And2() throws {
        // `.SetupBoxSprite` (M l. 58892–59730; digest B §2.5): the head — layer 2, `+0x4c` Box, `+0x5c` HitBox, `+0x1f8`
        // HitBoxTile, `+0xa6 = 3`, gravity 0x151, HP 600 — then the type arm, then the tail `+0x13c = 0x80`.
        let (w1, p) = try world()
        let L1 = w1.level
        let ctx1 = SetupFaces.Context(level: L1, playerX: 0)
        // 1062 teleporter (L1 rec 126): gravity 0, one-way, (0, −4, 0x20, 0x1a).
        XCTAssertEqual(L1.placements[126].type, 1062)
        let tele = try SetupFaces.setup(L1.placements[126], context: ctx1).slot
        XCTAssertEqual(tele.hotRect, IdleSprites.Rect(top: -4, left: 0, bottom: 0x1a, right: 0x20))
        XCTAssertEqual([tele.oneWay, tele.hasHit, tele.hasTileHit], [true, true, true])
        XCTAssertEqual([Int(tele.layer), Int(tele.gravity), Int(tele.hp), Int(tele.counterA6), Int(tele.pushForce)],
                       [2, 0, 600, 3, 0x80])
        // 1308 chest (L1 rec 23): layer 0, gravity 0, `+0xa6 = 4`, one-way, `+0x46 = 0`, `+0x5c = 0`, (0, 7, 0x1c, 0x1e).
        XCTAssertEqual(L1.placements[23].type, 1308)
        let chest = try SetupFaces.setup(L1.placements[23], context: ctx1).slot
        XCTAssertEqual(chest.hotRect, IdleSprites.Rect(top: 7, left: 0, bottom: 0x1e, right: 0x1c))
        XCTAssertEqual([chest.oneWay, chest.hasHit, chest.hasTileHit], [true, false, true])
        XCTAssertEqual([Int(chest.layer), Int(chest.gravity), Int(chest.counterA6)], [0, 0, 4])
        // 3090 crate (L1 rec 31): two-way, HP 5, `+0x88 = 1`, mass 0x78, friction 0x5a, gravity 0x100, `+0x90 = 0x100`,
        // `+0x14c = p1`, (4, 0, 0x23, 0x20).
        XCTAssertEqual(L1.placements[31].type, 3090)
        let crate = try SetupFaces.setup(L1.placements[31], context: ctx1).slot
        XCTAssertEqual(crate.hotRect, IdleSprites.Rect(top: 0, left: 4, bottom: 0x20, right: 0x23))
        XCTAssertEqual([crate.oneWay, crate.hasHit, crate.lightOverlay], [false, true, true])
        XCTAssertEqual([Int(crate.hp), Int(crate.pushMass), Int(crate.friction), Int(crate.gravity),
                        Int(crate.windScale), Int(crate.layer)], [5, 0x78, 0x5a, 0x100, 0x100, 2])
        XCTAssertEqual(crate.classTimer, Int32(L1.placements[31].p1))
        // 1065 save point (L1 rec 24): gravity 0, one-way, (0x21, 0x3f, 0x33, 99).
        let save = try SetupFaces.setup(L1.placements[24], context: ctx1).slot
        XCTAssertEqual(save.hotRect, IdleSprites.Rect(top: 0x3f, left: 0x21, bottom: 99, right: 0x33))
        XCTAssertEqual([save.oneWay, save.hasHit], [true, true])
        // 2922 / 2924 / 2927 furniture (L1 recs 0, 52, 22; M l. 59599–59636): layer 0, gravity 0; 0xb6a and 0xb6c
        // one-way, 0xb6f two-way.
        let furniture: [(Int, Int16, IdleSprites.Rect, Bool)] = [
            (0, 0xb6a, IdleSprites.Rect(top: 1, left: 10, bottom: 0x38, right: 0x2e), true),
            (52, 0xb6c, IdleSprites.Rect(top: 0x16, left: 4, bottom: 0x33, right: 0x22), true),
            (22, 0xb6f, IdleSprites.Rect(top: 3, left: 2, bottom: 0x1a, right: 0x4b), false),
        ]
        for (i, t, r, oneWay) in furniture {
            let s = try SetupFaces.setup(L1.placements[i], context: ctx1).slot
            XCTAssertEqual(s.type, t)
            XCTAssertEqual(s.hotRect, r, "rec \(i)")
            XCTAssertEqual([s.oneWay, s.hasHit], [oneWay, true], "rec \(i)")
            XCTAssertEqual([Int(s.layer), Int(s.gravity)], [0, 0])
        }
        // Outcrop 2853 (rec 74): (0x15, 0x14, 0x47, 0x54) one-way, layer 0x96; mushrooms 2870 (rec 75) and the
        // decoration 2842 (rec 158): an empty rect, no hit; NPC 2951 (rec 157): one-way, layer 0, its rect from the
        // Handle's face (none at Setup).
        let outcrop = try SetupFaces.setup(L1.placements[74], context: ctx1).slot
        XCTAssertEqual(outcrop.hotRect, IdleSprites.Rect(top: 0x14, left: 0x15, bottom: 0x54, right: 0x47))
        XCTAssertEqual([outcrop.oneWay, outcrop.hasHit, outcrop.lightOverlay], [true, false, false])
        XCTAssertEqual(outcrop.layer, 0x96)
        for i in [75, 158] {
            let s = try SetupFaces.setup(L1.placements[i], context: ctx1).slot
            XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0), "rec \(i)")
            XCTAssertEqual([s.oneWay, s.hasHit, s.hasTileHit], [true, false, false], "rec \(i)")
        }
        let npc = try SetupFaces.setup(L1.placements[157], context: ctx1).slot
        XCTAssertEqual([npc.oneWay, npc.hasHit], [true, true])
        XCTAssertEqual([Int(npc.layer), Int(npc.gravity)], [0, 0])
        XCTAssertEqual(npc.hotRect, IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0))

        // 1070 boulder (L2 rec 21; M l. 59078–59098): margins 0x80, `+0x112 = 0x14`, mass 0x8c, friction 0x46, gravity
        // 0x100, vx 0, `+0x90 = 0x100`, (4, 0, 0x1c, 0x1c), two-way, HitBox; face the boot single 0x42e.
        let L2 = try LevelFile.load(from: try resources(), level: 2)
        XCTAssertEqual(L2.placements[21].type, 1070)
        let eb = try SetupFaces.setup(L2.placements[21], context: SetupFaces.Context(level: L2, playerX: 0))
        let boulder = eb.slot
        XCTAssertEqual(boulder.hotRect, IdleSprites.Rect(top: 0, left: 4, bottom: 0x1c, right: 0x1c))
        XCTAssertEqual([boulder.oneWay, boulder.hasHit, boulder.hasTileHit], [false, true, true])
        XCTAssertEqual([Int(boulder.slip), Int(boulder.pushMass), Int(boulder.friction), Int(boulder.gravity),
                        Int(boulder.windScale), Int(boulder.layer), Int(boulder.hp)], [0x14, 0x8c, 0x46, 0x100, 0x100,
                                                                                         2, 600])
        XCTAssertEqual(boulder.margins, SpriteSlot.Margins(left: 0x80, right: 0x80, top: 0x80, bottom: 0x80))
        XCTAssertEqual(boulder.face, FaceRef(pict: 0x42e, index: 0, set: .encoded))
        XCTAssertEqual(eb.source, .setup)

        // Solids: the player lands on the crate's top and is stopped by its side; one-way 1308 holds him from above.
        let c = try add(w1, L1.placements[31])
        let cs = try XCTUnwrap(w1.active.sprite(id: c))
        dropPlayer(w1, p, ontoTop: cs.y, x: cs.x + 4, vy: 0x400)
        HitPlayerSprite.hit(w1, player: p, other: c)
        var ps = try XCTUnwrap(w1.active.sprite(id: p))
        XCTAssertEqual([ps.vy, Int32(ps.groundKind)], [0, 3])
        XCTAssertEqual(ps.ridden, c)
        XCTAssertFalse(ps.oneWayLanded)
        // From the left at walking speed: vx 0, x snapped to the crate's left; the crate is not moved (pushing is the
        // Phase-4 tail).
        let r = HandleKeys.standardHotRect
        w1.active.update(id: p) { s in
            s.y = cs.y + 0x20 - r.bottom
            s.y256 = Int32(s.y) << 8
            s.x = cs.x + 4 - r.right + 3
            s.x256 = Int32(s.x) << 8
            s.vx = 0x300
            s.vy = 0
            s.ridden = nil
        }
        HitPlayerSprite.hit(w1, player: p, other: c)
        ps = try XCTUnwrap(w1.active.sprite(id: p))
        XCTAssertEqual(ps.vx, 0)
        XCTAssertEqual(ps.x, cs.x + 4 - r.right)
        BoxSprite.handle(world: w1, id: c)
        XCTAssertEqual([w1.active.sprite(id: c)?.x, w1.active.sprite(id: c)?.y], [cs.x, cs.y])
        let ch = try add(w1, L1.placements[23])
        let chs = try XCTUnwrap(w1.active.sprite(id: ch))
        dropPlayer(w1, p, ontoTop: chs.y + 7, x: chs.x, vy: 0x400)
        HitPlayerSprite.hit(w1, player: p, other: ch)
        ps = try XCTUnwrap(w1.active.sprite(id: p))
        XCTAssertEqual([ps.vy, Int32(ps.groundKind)], [0, 3])
        XCTAssertTrue(ps.oneWayLanded)
    }

    // MARK: - Ropes

    /// A synthetic rope record: end points (x1, y1) – (x2, y2), the record at their midpoint − 6 (the editor's
    /// convention, platforms-ropes-radial §3.3).
    private func rope(_ index: Int, _ type: Int16, x1: Int16, y1: Int16, x2: Int16, y2: Int16) -> Placement {
        placement(index, type, p1: x1, p2: y1, p3: x2, p4: y2, x: (x1 + x2) / 2 - 6, y: (y1 + y2) / 2 - 6)
    }

    func testRopeSagCentre3022() throws {
        // `.SetupRopeSprite` (M l. 71078–71125): layer 1, the rope Handle, `+0x5c = 0`, `+0x1f8 = 0`, HP 6, `+0x8a = 0`,
        // `+0x46 = 0`, `+0xa6 = 4`, margins `+0x1c8 = +0x1ca = (p3 − p1)/2`, `+0x1ce = 0x40`, `+0x17c = 0`; no face.
        let (w, _) = try world(level: 1)
        let rec = rope(600, 3022, x1: 1000, y1: 500, x2: 1240, y2: 500)
        let e = try SetupFaces.setup(rec, context: SetupFaces.Context(level: w.level, playerX: 0))
        XCTAssertEqual(e.spriteClass, .rope)
        XCTAssertEqual(e.spawn, .idle)
        XCTAssertNil(e.slot.face)
        XCTAssertEqual(e.slot.handler, .rope)
        XCTAssertEqual([Int(e.slot.layer), Int(e.slot.hp), Int(e.slot.counterA6), Int(e.slot.phase)], [1, 6, 4, 0])
        XCTAssertEqual([e.slot.hasHit, e.slot.hasTileHit, e.slot.currentApplies, e.slot.setupDone],
                       [false, false, false, false])
        XCTAssertEqual(e.slot.margins, SpriteSlot.Margins(left: 120, right: 120, top: 0, bottom: 0x40))
        XCTAssertNil(e.slot.rope)

        // The first Handle runs `.SetupRopeSegArray` (M l. 71245–71455): span 240, seg 24 → nSeg (240 + 12)/24 = 10,
        // span 240; x = recX + (240 − 240)/2 − 120, y = recY − 0/2; rect (top −16, left 0, bottom 40, right 240).
        let id = try ropeInWorld(w, rec)
        RopeSprite.handle(world: w, id: id)
        let s = try XCTUnwrap(w.active.sprite(id: id))
        let b = try XCTUnwrap(s.rope)
        XCTAssertTrue(s.setupDone)
        XCTAssertEqual([s.classTimer, s.classWord150, s.classWord170], [240, 10, 1])
        XCTAssertEqual([s.x, s.y], [Int(rec.x) - 120, Int(rec.y)])
        XCTAssertEqual([s.x256, s.y256], [Int32(Int(rec.x) - 120) << 8, Int32(rec.y) << 8])
        XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: -16, left: 0, bottom: 40, right: 240))
        XCTAssertEqual([Int(b.seg), Int(b.dy), Int(b.restSag), Int(b.riddenMax)], [24, 0, 0xc00, 0x1800])
        XCTAssertEqual([b.exponent, b.decay, b.ease], [Float(1.4), Float(0.4), Float(0.4)])
        XCTAssertEqual(b.faces, 0x292)
        // Rest sag at the centre 0xc00 (12 px), the static curve `R·(1 − (d/m)^2)`, the ends at dy·256 = 0.
        XCTAssertEqual(b.base[120], 0xc00)
        XCTAssertEqual([b.base[0], b.base[24], b.base[60], b.base[96], b.base[144], b.base[239], b.base[240]],
                       [0, 1105, 2304, 2949, 2949, 50, 0])
        XCTAssertEqual(RopeSprite.height(s, 120), 12)
        XCTAssertEqual([RopeSprite.height(s, -5), RopeSprite.height(s, 0), RopeSprite.height(s, 12),
                        RopeSprite.height(s, 300)], [0, 0, 2, 0])
        // `+0x154` is the rest sag; the after-Handle decay already ran once (not ridden: × 0.4).
        XCTAssertEqual(s.classWord154, 1228)
        // 10 segments (type 600, layer −1, HP 400, the rope in `+0x1d4`) + 2 faceless end sprites.
        let segs = b.segments.compactMap { $0 }
        XCTAssertEqual(segs.count, 10)
        XCTAssertEqual(b.ends.compactMap { $0 }.count, 2)
        for (k, sid) in segs.enumerated() {
            let g = try XCTUnwrap(w.active.sprite(id: sid))
            XCTAssertEqual([Int(g.type), Int(g.layer), Int(g.hp)], [600, -1, 400])
            XCTAssertEqual(g.handler, .ropeSegment)
            XCTAssertEqual(g.siblings.first, id)
            XCTAssertEqual(g.x, s.x + k * 24)
            XCTAssertEqual(g.face?.pict, 0x292)
        }
        // Faces / y offsets on the static curve (`s = (Δbase) >> 8` clamped ±14; index s ≥ 0 → s, else 14 + |s|; y =
        // rope.y·256 + base + (−15 + s >> 1)·256 or (−15 − |s| >> 1)·256).
        let gs = segs.map { w.active.sprite(id: $0)! }
        XCTAssertEqual(gs.map { $0.face!.index }, [4, 3, 2, 1, 0, 15, 16, 17, 18, 19])
        let ropeY256 = Int32(s.y) << 8
        let offsets: [Int32] = [-0xd00, 1105 - 0xe00, 1966 - 0xe00, 2580 - 0xf00, 2949 - 0xf00, 3072 - 0xf00,
                                2949 - 0x1000, 2580 - 0x1000, 1966 - 0x1100, 1105 - 0x1100]
        XCTAssertEqual(gs.map { $0.y256 - ropeY256 }, offsets)
        XCTAssertEqual(gs.map { $0.y }, gs.map { Int(Int16(truncatingIfNeeded: $0.y256 >> 8)) })
        // The ends at (x − seg, y − seg/2) and (x + span, y + dy − seg/2), no face.
        let ends = b.ends.compactMap { $0 }.map { w.active.sprite(id: $0)! }
        XCTAssertEqual(ends.map { [$0.x256 >> 8, $0.y256 >> 8] }, [[Int32(s.x - 24), Int32(s.y - 12)],
                                                                    [Int32(s.x + 240), Int32(s.y - 12)]])
        XCTAssertEqual(ends.map { $0.face }, [nil, nil])

        // Ridden at i = 120 (`+0x186` set by `.RopeCollide`): T = 0x1800·(h² − 0)/h²; `+0x154` eases 0.4 of the way,
        // snapping within 0x100; dyn[i] = sag; the side samples `sag·(1 − (d/side)^1.4)` at multiples of seg.
        w.active.update(id: id) { $0.ridingLatch = true; $0.phase = 120; $0.classWord154 = 0xc00 }
        RopeSprite.handle(world: w, id: id)
        let r1 = try XCTUnwrap(w.active.sprite(id: id))
        XCTAssertEqual(r1.classWord154, 4300)
        XCTAssertEqual(r1.rope!.dyn[120], 4300)
        XCTAssertEqual([r1.rope!.dyn[0], r1.rope!.dyn[24], r1.rope!.dyn[96], r1.rope!.dyn[144], r1.rope!.dyn[240]],
                       [0, 1153, 3848, 3848, 0])
        XCTAssertFalse(r1.ridingLatch)                                    // cleared at the Handle's end
        XCTAssertEqual(RopeSprite.height(r1, 120), Int16((0xc00 + 4300) >> 8))
        // Close to the target the sag snaps: within 0x100 → T.
        w.active.update(id: id) { $0.ridingLatch = true; $0.classWord154 = 0x1800 - 0x1a0 }
        RopeSprite.handle(world: w, id: id)
        XCTAssertEqual(w.active.sprite(id: id)?.classWord154, 0x1800)
        // Easing down snaps too (M l. 71605–71621): 0x1980 → (int)−(0x180·0.4 − 0x1980) = 6374, within 0x100 of T → T.
        w.active.update(id: id) { $0.ridingLatch = true; $0.phase = 120; $0.classWord154 = 0x1800 + 0x180 }
        RopeSprite.handle(world: w, id: id)
        XCTAssertEqual(w.active.sprite(id: id)?.classWord154, 0x1800)
        // Above the target it eases down: rider at 24 → T = 0x1800·(14400 − 9216)/14400 = 2211.
        w.active.update(id: id) { $0.ridingLatch = true; $0.phase = 24 }
        RopeSprite.handle(world: w, id: id)
        XCTAssertEqual(w.active.sprite(id: id)?.classWord154, Int32(Float(0x1800) - Float(0x1800 - 2211) * 0.4))
        // Let go: the dynamic samples and the sag decay × 0.4, an unchanged sample → 0.
        let before = try XCTUnwrap(w.active.sprite(id: id))
        RopeSprite.handle(world: w, id: id)
        let after = try XCTUnwrap(w.active.sprite(id: id))
        XCTAssertEqual(after.classWord154, Int32(Float(before.classWord154) * 0.4))
        XCTAssertEqual(after.rope!.dyn[48], Int32(Float(before.rope!.dyn[48]) * 0.4))
        var probe = after
        probe.rope!.dyn[48] = 1
        probe.ridingLatch = false
        w.active.update(id: id) { $0 = probe }
        RopeSprite.handle(world: w, id: id)
        XCTAssertEqual(w.active.sprite(id: id)?.rope!.dyn[48], 0)
        w.active.update(id: id) { $0.rope!.dyn[48] = 3 }
        RopeSprite.handle(world: w, id: id)
        XCTAssertEqual(w.active.sprite(id: id)?.rope!.dyn[48], 1)

        // The idle callbacks through `.HandleIdleSprites`: back in the window, `.IdleToActiveSprite` restores the record
        // and calls `+0x58` `.RopeDeIdleize` (M l. 71492–71503) — 10 + 2 new sprites, `+0x186 = 1`, `+0x170 = 1`; out of
        // it, `.ActiveToIdleSprite` first calls `+0x54` `.RopeIdleize` (M l. 71458–71489) — `+0xe9` on all 12, `+0x170 =
        // 0` — then saves the record (the saved copy keeps `+0x170` 0).
        var saved = try XCTUnwrap(w.active.sprite(id: id))
        saved.ridingLatch = false
        var list = ActiveList()
        var idle = IdleSprites()
        _ = idle.add(saved, faceRect: .noFace)
        let on = idle.handle(h: saved.x - 100, v: saved.y - 100, playerHotRect: nil, active: &list) { _ in .noFace }
        XCTAssertEqual(on.activated, [0])
        let live = try XCTUnwrap(idle.entries[0]?.activeID)
        let lr = try XCTUnwrap(list.sprite(id: live))
        XCTAssertEqual([lr.classWord170, lr.ridingLatch ? 1 : 0], [1, 1])
        let made = (lr.rope!.segments + lr.rope!.ends).compactMap { $0 }
        XCTAssertEqual(made.count, 12)
        XCTAssertEqual(list.sprites.count, 13)
        XCTAssertEqual(made.compactMap { list.sprite(id: $0) }.filter { !$0.dead && $0.type == 600 }.count, 12)
        // `.MTNewSprite`'s 24.8 position (its pixel `+0xc` holds y until the rope's Handle places the segment).
        XCTAssertEqual(list.sprite(id: made[1]).map { Int($0.x256 >> 8) }, lr.x + 24)
        XCTAssertEqual(list.sprite(id: made[11]).map { [Int($0.x256 >> 8), Int($0.y256 >> 8)] }, [lr.x + 240, lr.y - 12])
        let off = idle.handle(h: saved.x + 5000, v: saved.y, playerHotRect: nil, active: &list) { _ in .noFace }
        XCTAssertEqual(off.deactivated, [0])
        XCTAssertEqual(made.compactMap { list.record(id: $0) }.filter(\.dead).count, 12)
        XCTAssertEqual(idle.entries[0]?.saved.classWord170, 0)
        XCTAssertEqual(list.record(id: live)?.handleCleared, true)
        // A rope never handled (`+0x17c` 0) makes and kills nothing.
        var fresh = IdleSprites()
        var none = ActiveList()
        _ = fresh.add(e.slot, faceRect: .noFace)
        _ = fresh.handle(h: Int(rec.x) - 100, v: Int(rec.y) - 100, playerHotRect: nil, active: &none) { _ in .noFace }
        XCTAssertEqual(none.sprites.count, 1)
        XCTAssertNil(none.sprites.first?.rope)
        _ = fresh.handle(h: Int(rec.x) + 5000, v: Int(rec.y), playerHotRect: nil, active: &none) { _ in .noFace }
        XCTAssertEqual(none.sprites.filter(\.dead).count, 0)

        // 3020 / 3021 (M l. 71282–71325): seg 20; rest 0xe00 / 0xa00, ridden 0x1a00 / 0x2c00, exponent 1.0 / 1.4,
        // faces 0x28a / 0x28c.
        for (t, rest, max, ex, faces) in [(Int16(3020), 0xe00, 0x1a00, Float(1.0), Int16(0x28a)),
                                          (3021, 0xa00, 0x2c00, Float(1.4), 0x28c)] {
            let (wt, _) = try world(level: 1)
            let rt = rope(601, t, x1: 1000, y1: 500, x2: 1200, y2: 530)
            let it = try ropeInWorld(wt, rt)
            RopeSprite.handle(world: wt, id: it)
            let st = try XCTUnwrap(wt.active.sprite(id: it))
            let bt = try XCTUnwrap(st.rope)
            XCTAssertEqual([Int(bt.seg), Int(bt.restSag), Int(bt.riddenMax), Int(bt.faces), Int(bt.dy)],
                           [20, rest, max, Int(faces), 30])
            XCTAssertEqual(bt.exponent, ex)
            XCTAssertEqual(st.classWord150, 10)                            // (200 + 10)/20
            XCTAssertEqual([bt.base[200], bt.base[201]], [30 << 8, 30 << 8])
            XCTAssertEqual(bt.base[100], Int32(rest) + (30 << 8) / 2)
            XCTAssertEqual(st.hotRect, IdleSprites.Rect(top: -16, left: 0, bottom: 30 + 40, right: 200))
            XCTAssertEqual(st.y, Int(rt.y) - 15)
        }

        // A steep 3022 (dy 400 over span 240): the segment step s = Δ >> 8 passes 14 — the face index clamps to 14 and
        // the y offset gains (s − 14)·256 (M l. 71688–71716).
        let (ws, _) = try world(level: 1)
        let steep = try ropeInWorld(ws, rope(602, 3022, x1: 1000, y1: 500, x2: 1240, y2: 900))
        RopeSprite.handle(world: ws, id: steep)
        let ss = try XCTUnwrap(ws.active.sprite(id: steep))
        let sb = try XCTUnwrap(ss.rope)
        let sg = sb.segments.compactMap { $0 }.map { ws.active.sprite(id: $0)! }
        XCTAssertEqual(sg.map { $0.face!.index }, Array(repeating: 14, count: 10))
        // Segment 0: s = 11345 >> 8 = 44 → `segmentOffset(14)` −0x800 + (44 − 14)·256 = 5632 over the sample at 0 (0);
        // segment 9: s = (102400 − 93265) >> 8 = 35 → 93265 − 0x800 + 21·256 = 96593.
        XCTAssertEqual([sb.base[24] &+ sb.dyn[24], sb.base[216] &+ sb.dyn[216], sb.base[240] &+ sb.dyn[240]],
                       [11345, 93265, 102400])
        XCTAssertEqual(sg.map { $0.y256 - (Int32(ss.y) << 8) },
                       [5632, 16721, 27566, 38164, 48517, 58624, 68485, 78100, 87470, 96593])
    }

    /// The rope record placed into the world (appended to the records so `+0x48` finds it) and its sprite inserted.
    private func ropeInWorld(_ w: SpriteWorld, _ p: Placement) throws -> Int {
        let index = w.records.count
        let q = Placement(index: index, flag: p.flag, byte1: p.byte1, type: p.type, p1: p.p1, p2: p.p2, p3: p.p3,
                          p4: p.p4, y: p.y, x: p.x)
        w.records.append(q)
        let e = try SetupFaces.setup(q, context: SetupFaces.Context(level: w.level, playerX: 0))
        return w.active.insert(e.slot)
    }

    func testRopeGrabWindow() throws {
        // `.RopeCollide` (M l. 43863–43986): for a rope (Handle `PTR_PTR_100a04f0`, type 0xbcc…0xbdf) whose rect strictly
        // holds the player's centre x: i = cx − rope.x ± 7 (+7 facing right), surf = rope.y + height(i). Not on a rope
        // last frame: grab iff surf ≤ y + 16 < surf + 0x40 and the previous `y − vy >> 8 + 16` < surf — jump counter
        // 0, landing sound (R(3), 3D rand); on this rope last frame: jump counter 6. DOWN → no attach. Attach: air
        // counter 0, current rope, on-rope, y = surf − 16, vy 0, rope `+0x46 = i`, `+0x186 = 1`; the step sound when
        // the rope-walk counter is 1 or 8 (not on the grab frame).
        let (w, p) = try world(level: 1)
        let id = try ropeInWorld(w, rope(600, 3022, x1: 1000, y1: 500, x2: 1240, y2: 500))
        RopeSprite.handle(world: w, id: id)
        let rs = try XCTUnwrap(w.active.sprite(id: id))
        let r = HandleKeys.standardHotRect
        let cxOff = r.left + ((r.right - r.left) >> 1)
        let i = 100
        let surf = rs.y + Int(RopeSprite.height(rs, i))
        XCTAssertEqual(surf, rs.y + 11)

        func place(feet: Int, vy: Int32, facingLeft: Bool = false, at: Int = i) {
            w.active.update(id: p) { s in
                s.mirrored = facingLeft
                s.x = rs.x + at - (facingLeft ? -7 : 7) - cxOff
                s.centre.x = s.x + cxOff
                s.y = feet - 16
                s.centre.y = s.y + 0x3b
                s.x256 = Int32(s.x) << 8
                s.y256 = Int32(s.y) << 8
                s.vy = vy
            }
            w.player.rope = false
            w.player.lastRope = false
            w.player.currentRope = nil
            w.player.jumpCounter = 3
            w.player.airCounter = 5
            w.player.cues = []
            w.active.update(id: id) { $0.ridingLatch = false; $0.phase = 0 }
        }
        func grabbed() -> Bool { w.player.rope }

        // The window's two edges, the previous-frame test, and the strict centre test.
        for (feet, vy, expect) in [(surf, Int32(0x100), true), (surf - 1, 0x100, false), (surf + 0x3f, 0x4000, true),
                                   (surf + 0x40, 0x4100, false), (surf + 1, 0x100, false), (surf + 1, 0x200, true),
                                   (surf, 0, false), (surf, -0x100, false)] {
            place(feet: feet, vy: vy)
            RopeSprite.collide(w, player: p, keys: [])
            XCTAssertEqual(grabbed(), expect, "feet \(feet - surf) vy \(vy)")
        }
        // A grab: the state, the snap, the rope's `+0x46`/`+0x186`, and the landing cue (3022: chaincreak 489 + R(3),
        // vol 0x69, 3D rand at the player's centre) with its two draws in order.
        place(feet: surf + 5, vy: 0x800)
        var rng = w.rng
        let pick = rng.next(3)
        let rate = rng.soundRate()
        RopeSprite.collide(w, player: p, keys: [])
        var ps = try XCTUnwrap(w.active.sprite(id: p))
        XCTAssertTrue(w.player.rope)
        XCTAssertEqual(w.player.currentRope, id)
        XCTAssertEqual([w.player.jumpCounter, w.player.airCounter], [0, 0])
        XCTAssertEqual([ps.y, Int(ps.vy)], [surf - 16, 0])
        XCTAssertEqual(ps.y256, Int32(surf - 16) << 8)
        XCTAssertEqual(w.active.sprite(id: id)?.phase, Int16(i))
        XCTAssertEqual(w.active.sprite(id: id)?.ridingLatch, true)
        XCTAssertEqual(w.rng.seed, rng.seed)
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDRand, snd: 489 + pick, priority: 1, volume: 0x69,
                                                 position: ps.centre, rate: rate)])

        // The grab frame plays no step sound even with the walk counter at 1 (`!grab`): only the landing cue.
        let walk0 = w.player.ropeWalk
        place(feet: surf + 5, vy: 0x800)
        w.player.ropeWalk = 1
        RopeSprite.collide(w, player: p, keys: [])
        XCTAssertTrue(grabbed())
        XCTAssertEqual(w.player.cues.map { Int($0.volume) }, [0x69])
        w.player.ropeWalk = walk0

        // Facing left: i = cx − x − 7.
        place(feet: surf, vy: 0x100, facingLeft: true)
        RopeSprite.collide(w, player: p, keys: [])
        XCTAssertTrue(grabbed())
        XCTAssertEqual(w.active.sprite(id: id)?.phase, Int16(i))
        // The centre on the rope's left edge (strict test) or right edge: no contact; DOWN: the landing sound plays and
        // the jump counter is cleared, but no attach.
        for edge in [0, 240] {
            place(feet: surf, vy: 0x100, at: edge + 7)
            w.active.update(id: p) { s in s.x = rs.x + edge - cxOff; s.centre.x = rs.x + edge }
            RopeSprite.collide(w, player: p, keys: [])
            XCTAssertFalse(grabbed(), "edge \(edge)")
            XCTAssertEqual(w.player.cues, [])
        }
        place(feet: surf, vy: 0x100)
        RopeSprite.collide(w, player: p, keys: [.down])
        XCTAssertFalse(grabbed())
        XCTAssertEqual(w.player.jumpCounter, 0)
        XCTAssertEqual(w.player.cues.count, 1)
        XCTAssertEqual(w.player.airCounter, 5)

        // On this rope last frame: no window test — the jump counter 6 and the snap; the step sound with the walk
        // counter at 1 or 8 (vol 0x4b for 3022), none at 2.
        for (walk, cue) in [(Int16(1), true), (8, true), (2, false), (0, false)] {
            place(feet: surf + 0x50, vy: 0)
            w.player.lastRope = true
            w.player.currentRope = id
            w.player.ropeWalk = walk
            var g = w.rng
            let k = g.next(3)
            let rt = g.soundRate()
            RopeSprite.collide(w, player: p, keys: [])
            ps = try XCTUnwrap(w.active.sprite(id: p))
            XCTAssertTrue(grabbed())
            XCTAssertEqual([w.player.jumpCounter, Int16(ps.y)], [6, Int16(surf - 16)])
            XCTAssertEqual(w.player.cues, cue ? [PlayerCue(call: .threeDRand, snd: 489 + k, priority: 1, volume: 0x4b,
                                                           position: ps.centre, rate: rt)] : [], "walk \(walk)")
        }
        // On a rope last frame but another one: neither branch — no attach.
        place(feet: surf, vy: 0x100)
        w.player.lastRope = true
        w.player.currentRope = 12345
        RopeSprite.collide(w, player: p, keys: [])
        XCTAssertFalse(grabbed())

        // 3020: ropecreak 486 + R(3) at vol 0x5f (grab) / 0x41 (step).
        let (w2, p2) = try world(level: 1)
        let id2 = try ropeInWorld(w2, rope(600, 3020, x1: 1000, y1: 500, x2: 1200, y2: 500))
        RopeSprite.handle(world: w2, id: id2)
        let r2 = try XCTUnwrap(w2.active.sprite(id: id2))
        let surf2 = r2.y + Int(RopeSprite.height(r2, 100))
        w2.active.update(id: p2) { s in
            s.x = r2.x + 100 - 7 - cxOff
            s.centre.x = s.x + cxOff
            s.y = surf2 - 16
            s.vy = 0x100
        }
        var g2 = w2.rng
        let k2 = g2.next(3)
        let rt2 = g2.soundRate()
        RopeSprite.collide(w2, player: p2, keys: [])
        XCTAssertEqual(w2.player.cues.map { [Int($0.snd), Int($0.volume)] }, [[486 + Int(k2), 0x5f]])
        XCTAssertEqual(w2.player.cues.first?.rate, rt2)
        w2.player.cues = []
        w2.player.lastRope = true
        w2.player.ropeWalk = 8
        RopeSprite.collide(w2, player: p2, keys: [])
        XCTAssertEqual(w2.player.cues.map { Int($0.volume) }, [0x41])

        // A rope with no block yet (`+0x1e8 == 0`) under the player stops the whole scan (M l. 43863–43986: return, not
        // continue): a built rope later in the list at the same place is never reached.
        let (w3, p3) = try world(level: 1)
        let unbuilt = try ropeInWorld(w3, rope(600, 3022, x1: 1000, y1: 500, x2: 1240, y2: 500))
        let built = try ropeInWorld(w3, rope(601, 3022, x1: 1000, y1: 500, x2: 1240, y2: 500))
        RopeSprite.handle(world: w3, id: unbuilt)
        RopeSprite.handle(world: w3, id: built)
        w3.active.update(id: unbuilt) { $0.rope = nil }
        let r3 = try XCTUnwrap(w3.active.sprite(id: built))
        let surf3 = r3.y + Int(RopeSprite.height(r3, 100))
        w3.active.update(id: p3) { s in
            s.mirrored = false
            s.x = r3.x + 100 - 7 - cxOff
            s.centre.x = s.x + cxOff
            s.y = surf3 - 16
            s.vy = 0x100
        }
        RopeSprite.collide(w3, player: p3, keys: [])
        XCTAssertFalse(w3.player.rope)
        XCTAssertEqual(w3.player.cues, [])

        // Wired as row 7 of `.HandlePlayerSprite` (`dying < 1`, after `0584 = 0588; 0588 = 0`): a player falling onto
        // the rope ends the Handle on it.
        place(feet: surf, vy: 0x300)
        w.player.dying = 0
        Player.handle(world: w, keys: [])
        XCTAssertTrue(w.player.rope)
        XCTAssertEqual(w.player.currentRope, id)
        place(feet: surf, vy: 0x300)
        w.player.dying = 1
        Player.handle(world: w, keys: [])
        XCTAssertFalse(w.player.rope)
    }

    func testReversedRopeIsDead() throws {
        // Level 3 record 145 is authored right to left (p1 2622 > p3 2449, span −173; platforms-ropes-radial §3.6):
        // nSeg = (−173 + 12)/24 = −6 (truncating), span −144 — no segments, only the two faceless end sprites; the rect
        // has right < left, so `.RopeCollide`'s strict test never passes.
        let (w, p) = try world(level: 3)
        let rec = w.level.placements[145]
        XCTAssertEqual([rec.type, rec.p1, rec.p3], [3022, 2622, 2449])
        let e = try SetupFaces.setup(rec, context: SetupFaces.Context(level: w.level, playerX: 0))
        XCTAssertEqual(e.slot.margins, SpriteSlot.Margins(left: -86, right: -86, top: 0, bottom: 0x40))
        let id = w.active.insert(e.slot)
        RopeSprite.handle(world: w, id: id)
        let s = try XCTUnwrap(w.active.sprite(id: id))
        let b = try XCTUnwrap(s.rope)
        XCTAssertEqual([s.classTimer, s.classWord150], [-144, -6])
        XCTAssertEqual(b.segments.compactMap { $0 }, [])
        XCTAssertEqual(b.ends.compactMap { $0 }.count, 2)
        XCTAssertEqual(w.active.sprites.filter { $0.type == 600 && $0.face != nil }.count, 0)
        XCTAssertEqual(w.active.sprites.filter { $0.type == 600 }.count, 2)
        // x = recX + (−173 + 144)/2 − (−144)/2 = recX − 14 + 72; y = recY − (1112 − 1153)/2 = recY + 20.
        XCTAssertEqual([s.x, s.y], [Int(rec.x) - 14 + 72, Int(rec.y) + 20])
        XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: -41 - 16, left: 0, bottom: 40, right: -144))
        XCTAssertEqual(s.classWord154, Int32(Float(0xc00) * 0.4))
        // No position of the player grabs it.
        let r = HandleKeys.standardHotRect
        for dx in stride(from: -200, through: 200, by: 8) {
            for dy in stride(from: -60, through: 60, by: 6) {
                w.active.update(id: p) { q in
                    q.x = s.x + dx - (r.left + ((r.right - r.left) >> 1))
                    q.centre.x = s.x + dx
                    q.y = s.y + dy - 16
                    q.vy = 0x200
                }
                w.player.lastRope = false
                RopeSprite.collide(w, player: p, keys: [])
                XCTAssertFalse(w.player.rope)
            }
        }
        XCTAssertEqual(w.player.cues, [])
    }
}
