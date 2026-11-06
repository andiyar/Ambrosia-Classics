import XCTest
@testable import FerazelCore

/// BA (docs/plans/2026-10-30-ferazel-phase5.md): the Bat class — `.InitBatSprite` (M l. 68092–68104),
/// `.SetupBatSprite` (M l. 68108–68316), `.SetupSwarmMemberSprite` / `.HandleSwarmMemberSprite` (M l. 68319–68443),
/// `.HandleBatSprite` (M l. 68446–68905), the insect body (M l. 68908–68925), `.HitBatSprite` (M l. 68928–68986),
/// `.HitSwarmMemberSprite` (M l. 68989–69020), `.KillBat` (M l. 69023–69044), `.HitBatTileSprite` (M l. 69047–69079),
/// `.SetupProgrammedPath` / `.HandleProgrammedPath` (M l. 39288–39468) and `.KillCrate`'s Bat arm (M l. 61312–61320).
/// A synthetic 60×30 grid over level 1's header (empty unless a test lays a floor); every expected draw is re-derived
/// from a copy of the stream at the call site, over seeds that tell R(n) from R(n ± 1) (seed 3: R(3) 2, R(0x50) 61,
/// R(0x4b) 57).
final class BatTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// The grid (FG kind 3 along row `floorRow` when given; BG liquid 200 + `liquid` from row `waterRow` down) and the
    /// player's centre globals `*_DAT_1009fd94` / `fd90` at (`px`, `py`) — far away by default (no bat wakes).
    private func world(px: Int16 = 1800, py: Int16 = 30, floorRow: Int? = nil, waterRow: Int? = nil,
                       liquid: Int = 0, level: Int16 = 1) throws -> SpriteWorld {
        let w = SpriteWorld(level: try LevelFile.load(from: try resources(), level: level))
        var fg = [UInt16](repeating: 0, count: 60 * 30), bg = fg
        if let r = floorRow { for c in 0..<60 { fg[r * 60 + c] = 4 } }
        if let r = waterRow { for row in r..<30 { for c in 0..<60 { bg[row * 60 + c] = 1 } } }
        var bgKinds = [Int](repeating: 0, count: 0x60)
        bgKinds[0] = 200 + liquid
        w.tiles = TileGrid(fg: TileMap(width: 60, height: 30, cells: fg), bg: TileMap(width: 60, height: 30, cells: bg),
                           fgKinds: Array(0..<0x60), bgKinds: bgKinds)
        w.player.centreX = px
        w.player.centreY = py
        return w
    }

    /// A placement of `type` (record 0) set up by `SetupFaces` inside the counting window (outside with `counted` false),
    /// its children inserted first as the level spawn does, and its centre set as a previous Cleanup leaves it.
    private func bat(_ w: SpriteWorld, type: Int16 = 0x6d1, x: Int = 300, y: Int = 100, p1: Int16 = 0, p2: Int16 = 0,
                     p3: Int16 = 0, counted: Bool = true) throws -> (id: Int, entry: SetupFaces.Entry) {
        let p = Placement(index: 0, flag: 1, byte1: 0, type: type, p1: p1, p2: p2, p3: p3, p4: 0, y: Int16(y),
                          x: Int16(x))
        w.records = [p]
        let c = SetupFaces.Context(level: w.level, playerX: Int(w.player.centreX), records: w.records)
        var lights = LightTable()
        w.enemies.window = counted
        let e = try SetupFaces.setup(p, context: c, lights: &lights, counting: &w.enemies, rng: &w.rng)
        w.enemies.window = false
        let ids = e.children.map { w.active.insert($0) }
        var s = e.slot
        if let f = s.siblings.first { s.siblings.first = ids[f] }
        if var b = s.swarm {
            b.members = b.members.map { $0.map { ids[$0] } }
            s.swarm = b
        }
        let r = s.hotRect
        s.centre = SpriteSlot.Point(x: s.x + r.left + ((r.right - r.left) >> 1), y: s.y + r.top + ((r.bottom - r.top) >> 1))
        return (w.active.insert(s), e)
    }

    private func slot(_ w: SpriteWorld, _ id: Int) throws -> SpriteSlot { try XCTUnwrap(w.active.record(id: id)) }

    /// One Handle call by `+0x4c` (the session's dispatch).
    private func frame(_ w: SpriteWorld, _ id: Int, _ solver: TileSolver, effects: Int16 = 1) {
        var lights = LightTable()
        switch w.active.record(id: id)?.handler {
        case .swarmMember?: Bat.handleSwarmMember(world: w, id: id)
        case .insectBody?: Bat.handleInsectBody(world: w, id: id)
        default: Bat.handle(world: w, id: id, solver: solver, lights: &lights, effects: effects)
        }
    }

    private func f(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }

    private func rect(_ l: Int, _ t: Int, _ r: Int, _ b: Int) -> IdleSprites.Rect {
        IdleSprites.Rect(top: t, left: l, bottom: b, right: r)
    }

    /// A player shot of `type` with a 20×20 hot rect at (`x`, `y`).
    private func shot(_ w: SpriteWorld, type: Int16 = 2, x: Int = 330, y: Int = 120, damage: Int16 = 150,
                      vx: Int32 = 1000, vy: Int32 = -200, a6: Int16 = 0) throws -> Int {
        try XCTUnwrap(w.newSprite(type: type, x: x, y: y, layer: 0xb, handler: .playerShot) { s in
            s.x = x
            s.y = y
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 20, right: 20)
            s.hp = damage
            s.vx = vx
            s.vy = vy
            s.counterA6 = a6
        })
    }

    /// The particles `.BloodSpray(victim, shot, 0x28, 400, 0x96, 2)` makes from the stream `r` on a twin world holding
    /// copies of the two records as they stand after the hit (the spray is the hit's last change to either), and the
    /// stream after it — compared with what a hit left in `w`.
    private func sprayTwin(_ w: SpriteWorld, victim: Int, shot: Int, rng r: FastRand) throws
        -> (parts: [ParticlePool.Record], rng: FastRand) {
        let tw = try world()
        let v = tw.active.insert(try slot(w, victim))
        let a = tw.active.insert(try XCTUnwrap(w.active.record(id: shot)))
        tw.rng = r
        BloodSpray.spray(tw, victim: v, attacker: a, count: 0x28, speed: 400, spread: 0x96, kind: 2)
        return (tw.particles.records.filter(\.alive), tw.rng)
    }

    // MARK: - Setup

    func testBatSetupBySubRange() throws {
        // 0x6cc…0x6d5 (M l. 68279–68310): HP 500, rect SetRect(0xc, 0xf, 0x2b, 0x2f), counted, layer 0xb, the Bat
        // callbacks, gravity 0, face 0 (the Handle's: Phase-1 picture 0x6cc[0]), `+0x150 = −1`, `+0x158 = 0x1e`,
        // `+0x15c = 0`, `+0xb0 = 7`; 0x6cc asleep (`+0xa6 = 0`), 0x6d1 awake (1), the others 0; no draw.
        for (type, a6) in [(Int16(0x6cc), Int16(0)), (0x6d1, 1), (0x6cf, 0), (0x6d5, 0)] {
            let w = try world()
            let seed = w.rng.seed
            let (_, e) = try bat(w, type: type, x: 300, y: 100)
            let s = e.slot
            XCTAssertEqual(w.rng.seed, seed, "\(type): no draw")
            XCTAssertEqual([Int(s.hp), Int(s.counterA6), Int(s.subtype), Int(s.layer), Int(s.gravity)],
                           [500, Int(a6), 7, 0xb, 0], "\(type)")
            XCTAssertEqual([s.classWord150, s.classWord158, s.classWord15c, s.classWord154, s.classTimer],
                           [-1, 0x1e, 0, 0, 0], "\(type)")
            XCTAssertEqual(s.hotRect, rect(0xc, 0xf, 0x2b, 0x2f))
            XCTAssertEqual([s.hasHit, s.hasTileHit, s.countedInTotals, s.keepRecord], [true, true, true, false])
            XCTAssertEqual([s.noWriteBack189, s.noWriteBack18a, s.keepRecordAtKill, s.killedForGood],
                           [false, false, false, false], "\(type): no other save flag")
            XCTAssertEqual([s.particleOffsetX, s.particleOffsetY], [0, 0])
            XCTAssertEqual(s.handler, .bat)
            XCTAssertEqual(s.mode, 0)
            XCTAssertEqual([s.x, s.y, Int(s.x256 >> 8), Int(s.y256 >> 8)], [300, 100, 300, 100])
            XCTAssertEqual(s.margins, SpriteSlot.Margins(), "no idle margins")
            XCTAssertEqual(e.source, .handle)
            XCTAssertEqual(s.face, f(Bat.batSet, 0))
            XCTAssertEqual(e.sheet, SetupFaces.Sheet(pict: 0x6cc, count: 0xb, cellWidth: 0x38, cellHeight: 0x34,
                                                     columns: 0xb, clut: 200))
            XCTAssertEqual(w.enemies.live, 1)
            XCTAssertTrue(e.children.isEmpty)
            XCTAssertEqual(CachedFaces.marks(type: type).sets, [0x6cc], "every 0x6cc… type marks the set (M l. 68286)")
        }
        // Outside the counting window: not counted.
        let wn = try world()
        let (_, en) = try bat(wn, type: 0x6cc, counted: false)
        XCTAssertEqual([en.slot.countedInTotals ? 1 : 0, Int(wn.enemies.live)], [0, 0])

        // 1741 (level 3 rec 189: p1 2, p2 340, p3 800; x 8371): `+0x188`, `+0xa6 = 1`, gravity 0, the path — mode
        // `+0xf0` = 2, `+0xfc` = 800, `+0xf8` = 1, `+0x100` = x·256 + 8·800, `+0x104` = x·256 + 256·340 − 8·800, vx 800,
        // vy 0 (M l. 39301–39343). The Walker's voice slot is untouched.
        let w3 = try world(level: 3)
        let rec = w3.level.placements[189]
        XCTAssertEqual([rec.type, rec.p1, rec.p2, rec.p3, rec.x, rec.y], [0x6cd, 2, 340, 800, 8371, 910])
        let e3 = try SetupFaces.setup(rec, context: SetupFaces.Context(level: w3.level, playerX: 0))
        var s = e3.slot
        XCTAssertEqual([s.keepRecord, s.hasHit], [true, true])
        XCTAssertEqual([s.pathMode, s.pathSpeed, s.pathDirection, s.pathLow, s.pathHigh, s.vx, s.vy, s.voicePitch],
                       [Int32(2), 800, 1, 2_149_376, 2_223_616, 800, 0, 0])      // 8371·256 + 6400; + 87040 − 6400
        XCTAssertEqual([Int32(s.counterA6), Int32(s.gravity), Int32(s.hp), Int32(s.subtype)], [1, 0, 500, 7])

        // 1742 (0x6ce; p1 1, p2 60, p3 512 — level 21's): retyped 0x6cd, `+0x188`, `+0x14c = 1`, `+0xb8 = 0x1000c`,
        // `+0x154 = R(0x50) + 0x32` (the only draw), then the path mode 1 on y: `+0x100` = y·256 + 8·512, `+0x104` =
        // y·256 + 256·60 − 8·512, vy 512, vx 0, `+0x13a = 0`.
        for seed in Int32(1)...40 {
            let w = try world()
            w.rng = FastRand(seed: seed)
            var r = w.rng
            let want = Int32(r.next(0x50)) + 0x32
            let (_, e) = try bat(w, type: 0x6ce, x: 200, y: 150, p1: 1, p2: 60, p3: 512)
            s = e.slot
            XCTAssertEqual(w.rng.seed, r.seed, "seed \(seed)")
            XCTAssertEqual(s.classWord154, want, "seed \(seed)")
            if seed == 3 { XCTAssertEqual(want, 61 + 0x32) }
        }
        XCTAssertEqual([Int(s.type), Int(s.classTimer), Int(s.mode), s.keepRecord ? 1 : 0], [0x6cd, 1, 0x1000c, 1])
        XCTAssertEqual([s.pathMode, s.pathSpeed, s.pathDirection, s.pathLow, s.pathHigh, s.vx, s.vy, Int32(s.sag)],
                       [Int32(1), 512, 1, 42_496, 49_664, 0, 512, 0])            // 150·256 + 4096; + 60·256 − 4096
        XCTAssertEqual(CachedFaces.marks(type: 0x6ce).sets, [0x6cc])
        // Path modes: 101 / 102 → 1 / 2 (M l. 39308–39310), p1 −2 → |p1| 2, 0 → none (dir 1, no velocity), 3 → the
        // stores only (rect (7, 0, 0x46, 0x1e), `+0x19e = 0x50`, gravity 0x15e, `+0x13a = 0x2d`, `+0x138 = 0x3c`, dir 0).
        for (p1, mode, vx, vy) in [(Int16(102), Int32(2), Int32(300), Int32(0)), (101, 1, 0, 300), (-2, 2, 300, 0),
                                   (0, 0, 0, 0), (100, 0, 0, 0), (199, 99, 0, 0), (200, 200, 0, 0), (-102, 2, 300, 0)] {
            let (_, e) = try bat(try world(), type: 0x6cd, p1: p1, p2: 10, p3: 300)
            XCTAssertEqual([e.slot.pathMode, e.slot.vx, e.slot.vy, e.slot.pathDirection], [mode, vx, vy, 1], "p1 \(p1)")
        }
        let (_, e3m) = try bat(try world(), type: 0x6cd, p1: 3, p2: 10, p3: 300)
        XCTAssertEqual([Int(e3m.slot.buoyancy), Int(e3m.slot.gravity), Int(e3m.slot.sag), Int(e3m.slot.pushMass),
                        Int(e3m.slot.pathDirection), Int(e3m.slot.vx)], [0x50, 0x15e, 0x2d, 0x3c, 0, 0])
        XCTAssertEqual(e3m.slot.hotRect, rect(7, 0, 0x46, 0x1e))
        // Modes 10 / 11 (`.MakeRadial`) are placed on no Bat: refused.
        XCTAssertThrowsError(try bat(try world(), type: 0x6cd, p1: 10))
        XCTAssertThrowsError(try bat(try world(), type: 0x73b, p1: -111))

        // The 1850 family (M l. 68240–68277): `+0x188`, HP 100, rect SetRect(0x10, 0x1e, 0x30, 0x32); 0x73a asleep;
        // p1 ≥ 0: `+0x160 = 0`, counted, the 0x73a set; p1 < 0: layer 8, `+0x160 = 1`, not counted, the 0x73b set too.
        do {
            let w = try world()
            let (_, e) = try bat(w, type: 0x73a, p1: 0)
            s = e.slot
            XCTAssertEqual([Int(s.hp), Int(s.counterA6), Int(s.layer), Int(s.classWord160), Int(s.subtype)],
                           [100, 0, 0xb, 0, 7])
            XCTAssertEqual([s.classWord158, s.classWord15c], [0x1e, 0], "the 1850 family's thrust (M l. 68261)")
            XCTAssertEqual([s.keepRecord, s.countedInTotals], [true, true])
            XCTAssertEqual(s.hotRect, rect(0x10, 0x1e, 0x30, 0x32))
            XCTAssertEqual(e.sheet?.pict, Bat.familySet)
            XCTAssertEqual(CachedFaces.marks(type: 0x73a, p1: 0).sets, [0x73a])
            XCTAssertEqual(CachedFaces.marks(type: 0x73a, p1: -1).sets, [0x73a, 0x73b])
            XCTAssertEqual(CachedFaces.marks(type: 0x73e, p1: 0).sets, [0x73a])
            XCTAssertEqual(CachedFaces.marks(type: 0x73f, p1: 0).sets, [], "0x73f is the Background class's")
        }
        do {
            let (_, e1) = try bat(try world(), type: 0x73a, p1: -1)
            XCTAssertEqual([Int(e1.slot.layer), Int(e1.slot.classWord160), e1.slot.countedInTotals ? 1 : 0], [8, 1, 0])
            let w = try world()
            let (_, e) = try bat(w, type: 0x73b, p1: -2, p2: 100, p3: 200)
            s = e.slot
            XCTAssertEqual([Int(s.layer), Int(s.classWord160), Int(s.counterA6), Int(s.pathMode), Int(s.vx)],
                           [8, 1, 1, 2, 200])
            XCTAssertEqual([s.classWord158, s.classWord15c], [0x1e, 0])
            XCTAssertEqual([s.countedInTotals ? 1 : 0, Int(w.enemies.live)], [0, 0])
            XCTAssertEqual(e.sheet?.pict, Bat.familyBackSet)
        }
        do {
            let w = try world()
            w.rng = FastRand(seed: 3)
            let (_, e) = try bat(w, type: 0x73c, p1: 0)
            XCTAssertEqual([Int(e.slot.type), Int(e.slot.classTimer), Int(e.slot.mode), Int(e.slot.classWord154)],
                           [0x73b, 1, 0x1000c, 61 + 0x32])
        }

        // The swarm 0x74d (M l. 68153–68211): x, y + 0x40 (the 24.8 position stays the spawn point); p1 0 → members
        // 0x74c, p2 count, p3 radius (0 → 0x4b); HP 100, no hit callback, rect ±r/2; counted; each member drawn R(2r) for
        // y then x, then its Setup's R(7) — `MTNewSprite(type, x + 0x40 + R − r, y + 0x40 + R − r, 0xa, 0x200, …)`, its
        // pixel copies `.MTNewSprite`'s (`+0xc` = y, `+0xa` = 0), `+0x14c` / `+0x150` = the centre.
        for seed in Int32(1)...12 {
            let w = try world()
            w.rng = FastRand(seed: seed)
            var r = w.rng
            let (_, e) = try bat(w, type: Bat.swarm, x: 200, y: 300, p1: 0, p2: 3, p3: 11)
            s = e.slot
            XCTAssertEqual([s.x, s.y, Int(s.x256 >> 8), Int(s.y256 >> 8)], [0x108, 0x16c, 200, 300], "seed \(seed)")
            XCTAssertEqual(s.swarm?.alive, 3)
            XCTAssertEqual(s.swarm?.total, 3)
            XCTAssertEqual(s.swarm?.members, [0, 1, 2])
            XCTAssertEqual([Int(s.hp), Int(s.classWord154), s.hasHit ? 1 : 0, s.countedInTotals ? 1 : 0], [100, 11, 0, 1])
            XCTAssertEqual(s.hotRect, rect(-5, -5, 5, 5), "r 11 → 11 / 2 = 5")
            XCTAssertNil(s.face)
            XCTAssertEqual(e.source, .none)
            XCTAssertEqual(e.children.count, 3)
            for c in e.children {
                let a = Int(r.next(22)), b = Int(r.next(22)), ph = r.next(7)
                let cx = 0x108 + b - 11, cy = 0x16c + a - 11
                XCTAssertEqual([Int(c.type), Int(c.recordIndex), Int(c.layer), Int(c.phase)], [0x74c, 0x200, 0xa, Int(ph)],
                               "seed \(seed)")
                XCTAssertEqual([Int(c.x256 >> 8), Int(c.y256 >> 8), c.oldPosition.x, c.oldPosition.y, c.x, c.y],
                               [cx, cy, cx, cy, cy, 0], "seed \(seed)")
                XCTAssertEqual([c.classTimer, c.classWord150], [0x108, 0x16c])
                XCTAssertEqual(c.handler, .swarmMember)
                XCTAssertEqual([c.hasHit, c.hasTileHit, c.sameHandlerExempt, c.countedInTotals], [true, false, true, false])
                XCTAssertEqual([Int(c.hp)], [100])
                XCTAssertEqual(c.hotRect, rect(0, 0, 0x18, 0x16))
            }
            XCTAssertEqual(w.rng.seed, r.seed, "seed \(seed)")
        }
        do {
            // p1 8, p2 0, p3 0 (level 11's): members of type 8, 8 of them, radius 0x4b; p2 −1: no member, `+0xe9 = 1`.
            let (_, e) = try bat(try world(), type: Bat.swarm, p1: 8)
            XCTAssertEqual([e.children.count, Int(e.slot.classWord154), Int(e.children[0].type)], [8, 0x4b, 8])
            XCTAssertEqual(e.slot.hotRect, rect(-37, -37, 37, 37))
            let (_, none) = try bat(try world(), type: Bat.swarm, p2: -1)
            XCTAssertEqual([none.children.count, none.slot.dead ? 1 : 0], [0, 1])
            XCTAssertEqual(CachedFaces.marks(type: Bat.swarm).sets, [0x74d])
        }

        // The insects 0x744…0x74c (M l. 68212–68238): rect SetRect(6, 6, 0x2a, 0x26), face = the 0x744 set's cell 3,
        // HP 200, `+0xb0 = 7`, `+0xa6 = 3`, `+0x46 = 3`, `+0xb8 = 0xb0004`, `+0x158 = 0x28`, `+0x15c = 0`, `+0x88 = 0`;
        // the body `MTNewSprite(type, x, y, 0xa, 0x200, .SetupInsectBodySprite)` with the body Handle; counted.
        for type in [Int16(0x744), 0x748, 0x74c] {
            let w = try world()
            let seed = w.rng.seed
            let (id, e) = try bat(w, type: type, x: 400, y: 200)
            s = e.slot
            XCTAssertEqual(w.rng.seed, seed)
            XCTAssertEqual([Int(s.hp), Int(s.subtype), Int(s.counterA6), Int(s.phase), Int(s.classWord158)],
                           [200, 7, 3, 3, 0x28])
            XCTAssertEqual([s.mode, UInt32(s.classWord15c)], [0xb0004, 0])
            XCTAssertEqual([s.lightOverlay, s.countedInTotals, s.keepRecord], [false, true, false])
            XCTAssertEqual(s.hotRect, rect(6, 6, 0x2a, 0x26))
            XCTAssertEqual([s.face, e.sheet.map { f($0.pict, 3) }], [f(Bat.insectSet, 3), f(Bat.insectSet, 3)])
            XCTAssertEqual(e.source, .setupCached)
            XCTAssertEqual(e.children.count, 1)
            let b = e.children[0]
            XCTAssertEqual([Int(b.type), Int(b.recordIndex), Int(b.layer)], [Int(type), 0x200, 0xa])
            XCTAssertEqual(b.handler, .insectBody)
            XCTAssertEqual([b.hasHit, b.hasTileHit, b.countedInTotals], [false, false, false])
            XCTAssertEqual([Int(b.x256 >> 8), Int(b.y256 >> 8), b.x, b.y], [400, 200, 200, 0])
            XCTAssertNotNil(try slot(w, id).siblings.first)
            XCTAssertEqual(CachedFaces.marks(type: type).sets, [0x744])
        }
        // The level-load cache: `.InitBatSprite`'s five sets in its order, after the dart traps' and before the Blob's.
        let picts = CachedFaces.sets.map(\.pict)
        let at = try XCTUnwrap(picts.firstIndex(of: 0x6cc))
        XCTAssertEqual(Array(picts[at...at + 5]), [0x6cc, 0x744, 0x74d, 0x73a, 0x73b, 0x6c2])
        XCTAssertEqual(CachedFaces.sets[at...at + 4].map(\.faces), [11, 9, 8, 12, 12])
        XCTAssertEqual(CachedFaces.sheets(markedBy: [Int16(0x744), Bat.swarm, 0x73a]).map(\.pict), [0x744, 0x74d, 0x73a])
        XCTAssertEqual(SetupFaces.sheet(pict: 0x744), SetupFaces.Sheet(pict: 0x744, count: 9, cellWidth: 0x30,
                                                                     cellHeight: 0x2c, columns: 9, clut: 200))
        XCTAssertEqual(SetupFaces.sheet(pict: 0x74d), SetupFaces.Sheet(pict: 0x74d, count: 8, cellWidth: 0x18,
                                                                     cellHeight: 0x16, columns: 8, clut: 200))
        XCTAssertEqual(SetupFaces.sheet(pict: 0x73b), SetupFaces.Sheet(pict: 0x73b, count: 12, cellWidth: 0x40,
                                                                     cellHeight: 0x50, columns: 12, clut: 200))
        XCTAssertEqual(SpriteHandler.forClass(type: 0x6cc), .bat)
        XCTAssertEqual(SpriteHandler.forClass(type: 0x74d), .bat)
    }

    // MARK: - waking

    func testSleeperWakesOnHit() throws {
        // A player shot (`+0xa6 == 0`) on a sleeping 1740 (M l. 68934–68960): `.KillPlayerShot`, `.HurtSprite(s, 150,
        // vx >> 3, vy >> 3, 2, 8)`, then `.STPlay3DSoundRand(609, 1, 0xab)`, `+0xa6 < 2 → 0x15`, the blood spray (HP >
        // 0), HP 350 ≥ 0xc9 → snd 701 (vol 0x100).
        let w = try world()
        let solver = TileSolver(world: w)
        let (id, _) = try bat(w, type: 0x6cc)
        let sh = try shot(w, damage: 150, vx: 1000, vy: -200)
        var r = w.rng
        let rate = r.soundRate()
        var l = LightTable()
        Bat.hit(w, id: id, other: sh, lights: &l)
        var s = try slot(w, id)
        XCTAssertEqual([Int(s.hp), Int(s.counterA6), Int(s.invulnerable), Int(s.flash)], [350, 0x15, 2, 8])
        XCTAssertEqual([s.vx, s.vy], [1000 >> 3, -200 >> 3], "the knockback (vx >> 3, vy >> 3)")
        XCTAssertEqual(w.player.cues.map { [Int($0.snd), Int($0.volume), Int($0.priority)] },
                       [[609, 0xab, 1], [701, 0x100, 1]])
        XCTAssertEqual(w.player.cues.first?.call, .threeDRand)
        XCTAssertEqual(w.player.cues.first?.rate, rate)
        XCTAssertEqual(w.player.cues.first?.position, s.centre)
        XCTAssertGreaterThan(w.particles.live, 0, "the blood spray")
        XCTAssertTrue(w.active.record(id: sh)?.dead ?? true, "the shot is killed")
        // The next Handle: awake → retyped 0x6d1; `+0xa6` 0x15 → 0x16 > 0x15 → 2, face 0x6cc[1].
        frame(w, id, solver)
        s = try slot(w, id)
        XCTAssertEqual([Int(s.type), Int(s.counterA6)], [0x6d1, 2])
        XCTAssertEqual(s.face, f(Bat.batSet, 1))
        // `+0xa6` 1 → 0x15 as well; 2 and above stay.
        for (a6, want) in [(Int16(1), Int16(0x15)), (2, 2), (9, 9)] {
            let w2 = try world()
            let (b, _) = try bat(w2, type: 0x6d1)
            w2.active.update(id: b) { $0.counterA6 = a6 }
            let s2 = try shot(w2, damage: 10)
            Bat.hit(w2, id: b, other: s2, lights: &l)
            XCTAssertEqual(try slot(w2, b).counterA6, want, "a6 \(a6)")
        }
        // HP 201 left → 701; 200 → 702; 0 → no blood, 702 (HP < 0xc9); a shot with `+0xa6 ≠ 0` → nothing.
        for (damage, snd, blood) in [(Int16(299), Int16(701), true), (300, 702, true), (499, 702, true),
                                     (500, 702, false)] {
            let w2 = try world()
            let (b, _) = try bat(w2, type: 0x6cc)
            let s2 = try shot(w2, damage: damage)
            Bat.hit(w2, id: b, other: s2, lights: &l)
            XCTAssertEqual(w2.player.cues.map(\.snd), [609, snd], "damage \(damage)")
            XCTAssertEqual(w2.particles.live > 0, blood, "damage \(damage)")
        }
        do {
            let w2 = try world()
            let (b, _) = try bat(w2, type: 0x6cc)
            let s2 = try shot(w2, a6: 1)
            let seed = w2.rng.seed
            Bat.hit(w2, id: b, other: s2, lights: &l)
            XCTAssertEqual([Int(try slot(w2, b).hp), Int(w2.rng.seed == seed ? 1 : 0)], [500, 1])
            XCTAssertEqual(w2.active.record(id: s2)?.dead, false)
            // A shot of type 1 (the Statue spell): `.TurnIntoStatue` (the Statue Handle, 120 frames).
            let st = try shot(w2, type: 1)
            Bat.hit(w2, id: b, other: st, lights: &l)
            XCTAssertEqual(try slot(w2, b).handler, .statue)
            XCTAssertEqual(try slot(w2, b).reentry, 0x78)
        }
        // Waking by proximity (M l. 68566–68577): |c.x − P.x| < 0x9c and c.y + 0x20 < P.y, P.y − c.y < 200 →
        // `.STPlay3DSoundRand(608, 1, 0xab)` (its rate drawn), `+0xa6 = 0x14`; the animation then makes it 0x15, face
        // 0x6cc[10]. Both sides of each edge. The centre (327, 131).
        for (dx, dy, wakes) in [(155, 33, true), (156, 33, false), (-155, 33, true), (-156, 33, false), (0, 32, false),
                                (0, 199, true), (0, 200, false)] {
            let w2 = try world(px: Int16(327 + dx), py: Int16(131 + dy))
            let (b, _) = try bat(w2, type: 0x6cc)
            var r2 = w2.rng
            let rate2 = r2.soundRate()
            frame(w2, b, TileSolver(world: w2))
            let s2 = try slot(w2, b)
            XCTAssertEqual(Int(s2.counterA6), wakes ? 0x15 : 0, "dx \(dx) dy \(dy)")
            XCTAssertEqual(s2.face, f(Bat.batSet, wakes ? 10 : 0), "dx \(dx) dy \(dy)")
            XCTAssertEqual(Int(s2.type), 0x6cc, "retyped only by an awake Handle")
            XCTAssertEqual(w2.player.cues.map(\.snd), wakes ? [608] : [], "dx \(dx) dy \(dy)")
            if wakes, let cue = w2.player.cues.first {
                XCTAssertEqual([Int(cue.volume), Int(cue.priority)], [0xab, 1])
                XCTAssertEqual(cue.rate, rate2)
                XCTAssertEqual(cue.call, .threeDRand)
                XCTAssertEqual(w2.rng.seed, r2.seed)
            }
        }
    }

    // MARK: - the chasers

    func testChaserAI() throws {
        // The steering states (M l. 68622–68730) on `steer` with a given d: 7 turns toward d by 1 (the short way when d >
        // h by less than 18, else − 1), wrapping 0…35, and goes to 8 when aligned; 8 thrusts `FUN_1003f218(heading,
        // +0x158)` while d is within ±2 (also ±36), else 6; 6 drops to 7 (the pair 0); 5 aims.
        func steer(_ type: Int16 = 0x6d1, state: Int16, heading: Int16, d: Int, vx: Int32 = 0, vy: Int32 = 0,
                   pair: Int16 = 0) -> SpriteSlot {
            var s = SpriteSlot(type: type, x: 0, y: 0)
            s.subtype = state
            s.phase = heading
            s.vx = vx
            s.vy = vy
            s.classWord158 = type == 0x744 ? 0x28 : 0x1e
            s.particleOffsetX = pair
            s.particleOffsetY = pair
            Bat.steer(&s, dir: d)
            return s
        }
        // The wrap (M l. 68571–68578): 34 → 35 holds, 1 → 0 holds, 0 → −1 → 35; 35 → 36 → 0 only with a d past 35 (none
        // from `FindDesiredDirectionGeneric`: the arm as written).
        for (h, d, want, state) in [(Int16(10), 18, Int16(11), Int16(7)), (17, 34, 18, 7), (17, 35, 16, 7),
                                    (0, 27, 35, 7), (35, 0, 34, 7), (5, 3, 4, 7), (18, 18, 18, 8), (34, 35, 35, 7),
                                    (1, 0, 0, 7), (35, 40, 0, 7)] {
            let s = steer(state: 7, heading: h, d: d)
            XCTAssertEqual([s.phase, s.subtype], [want, state], "h \(h) d \(d)")
            XCTAssertEqual([s.vx, s.vy], [0, 0])
        }
        // State 8: aligned within ±2 → the impulse along the heading (dir 18 → vx + 0x1e, dir 9 → vy + 0x1e); 3 off → 6.
        XCTAssertEqual([steer(state: 8, heading: 18, d: 18).vx, steer(state: 8, heading: 18, d: 16).vx,
                        steer(state: 8, heading: 18, d: 20).vx], [0x1e, 0x1e, 0x1e])
        XCTAssertEqual(steer(state: 8, heading: 9, d: 9).vy, 0x1e)
        XCTAssertEqual(steer(state: 8, heading: 0, d: 0).vx, -0x1e)
        for (h, d) in [(Int16(18), 15), (18, 21)] {
            let s = steer(state: 8, heading: h, d: d)
            XCTAssertEqual([Int(s.subtype), Int(s.vx)], [6, 0], "h \(h) d \(d)")
        }
        // The wrap tests: d + 36 − h and d − 36 − h.
        XCTAssertEqual([Int(steer(state: 8, heading: 34, d: 0).subtype), Int(steer(state: 8, heading: 33, d: 0).subtype)],
                       [8, 6])
        XCTAssertEqual([Int(steer(state: 8, heading: 1, d: 35).subtype), Int(steer(state: 8, heading: 2, d: 35).subtype)],
                       [8, 6])
        // The gates: the 1740 family |pair| > 0xb3 both, the 1850 family > 0x4f, insects |vx|, |vy| > 0x1c1.
        XCTAssertEqual([steer(state: 8, heading: 18, d: 18, pair: 0xb4).vx,
                        steer(state: 8, heading: 18, d: 18, pair: 0xb3).vx], [0, 0x1e])
        // Both halves must pass the gate: one at 0xb3 (0x4f) lets the thrust through.
        for (x, y, gated) in [(Int16(0xb3), Int16(0xb4), false), (0xb4, 0xb3, false), (-0xb4, 0xb4, true)] {
            var g = SpriteSlot(type: 0x6d1, x: 0, y: 0)
            g.subtype = 8
            g.phase = 18
            g.classWord158 = 0x1e
            g.particleOffsetX = x
            g.particleOffsetY = y
            Bat.steer(&g, dir: 18)
            XCTAssertEqual(g.vx, gated ? 0 : 0x1e, "pair (\(x), \(y))")
            var b = SpriteSlot(type: 0x73a, x: 0, y: 0)
            b.subtype = 8
            b.phase = 18
            b.classWord158 = 0x1e
            b.particleOffsetX = x == 0xb3 ? 0x4f : (x == 0xb4 ? 0x50 : -0x50)
            b.particleOffsetY = y == 0xb3 ? 0x4f : 0x50
            Bat.steer(&b, dir: 18)
            XCTAssertEqual(b.vx, gated ? 0 : 0x1e, "1850 pair (\(x), \(y))")
        }
        XCTAssertEqual([steer(0x73a, state: 8, heading: 18, d: 18, pair: 0x50).vx,
                        steer(0x73a, state: 8, heading: 18, d: 18, pair: 0x4f).vx], [0, 0x1e])
        XCTAssertEqual([steer(0x744, state: 8, heading: 18, d: 18, vx: 0x1c2, vy: 0x1c2).vx,
                        steer(0x744, state: 8, heading: 18, d: 18, vx: 0x1c1, vy: 0x1c2).vx,
                        steer(0x744, state: 8, heading: 18, d: 18, vx: -0x1c2, vy: 0x1c1).vx],
                       [0x1c2, 0x1c1 + 0x28, -0x1c2 + 0x28])
        // State 6: the pair under 0x9c → state 7, both 0; at 0x9c each × `+0x15c` (0) and `+0xa6` + 1. State 5: heading = d.
        var s6 = steer(state: 6, heading: 4, d: 20)
        XCTAssertEqual([Int(s6.subtype), Int(s6.phase), Int(s6.counterA6)], [7, 4, 0])
        s6 = steer(state: 6, heading: 4, d: 20, pair: 0x9c)
        XCTAssertEqual([Int(s6.subtype), Int(s6.particleOffsetX), Int(s6.particleOffsetY), Int(s6.counterA6)], [6, 0, 0, 1])
        XCTAssertEqual(Int(steer(state: 5, heading: 4, d: 20).phase), 20)
        XCTAssertEqual(Int(steer(state: 4, heading: 4, d: 20).phase), 4, "state 4: none")
        XCTAssertEqual(Int(steer(state: 9, heading: 4, d: 20).phase), 4, "state 9: none")

        // Through the Handle: an awake 1745 at (300, 100), centre (327, 131); P at (500, 146) — T = (131, 500) lies due
        // right: d 18. Heading 17 → 18 this frame (state 7), then state 8 and the thrust; each frame moves 2·v.
        let w = try world(px: 500, py: 146)
        let solver = TileSolver(world: w)
        let (id, _) = try bat(w, type: 0x6d1)
        XCTAssertEqual(BloodSpray.direction(target: (v: 131, h: 500), from: (v: 131, h: 327)), 18)
        w.active.update(id: id) { $0.phase = 17 }
        let seed = w.rng.seed
        frame(w, id, solver)
        var s = try slot(w, id)
        XCTAssertEqual([Int(s.phase), Int(s.subtype), Int(s.vx), Int(s.x256 >> 8)], [18, 7, 0, 300])
        XCTAssertTrue(s.mirrored, "c.x < P.x → flip 1")
        XCTAssertEqual(w.rng.seed, seed, "no draw")
        frame(w, id, solver)
        s = try slot(w, id)
        XCTAssertEqual([Int(s.subtype), Int(s.vx)], [8, 0], "aligned: state 8, no thrust yet")
        let x0 = s.x256
        frame(w, id, solver)
        s = try slot(w, id)
        XCTAssertEqual([Int(s.subtype), Int(s.vx), Int(s.x256 - x0)], [8, 0x1e, 0x3c], "the thrust, moved 2·vx")
        // T is the player's centre less 15 px up (M l. 68557): state 5 aims at it — P at (327, 146) puts T on the
        // bat's own centre (131, 327), both coordinates nudged (`FindDesiredDirectionGeneric`).
        do {
            let wt = try world(px: 327, py: 146)
            let (b, _) = try bat(wt, type: 0x6d1)
            wt.active.update(id: b) { $0.subtype = 5 }
            frame(wt, b, TileSolver(world: wt))
            let d = BloodSpray.direction(target: (v: 131, h: 327), from: (v: 131, h: 327))
            XCTAssertNotEqual(d, BloodSpray.direction(target: (v: 132, h: 327), from: (v: 131, h: 327)))
            XCTAssertEqual(Int(try slot(wt, b).phase), d)
        }
        // The brake (state 9 — no steering): awake, c.x < P.x − 40 with vx < −0x100 → + 0x48; mirrored on the right.
        for (vx, cxOff, want, flip) in [(Int32(-0x101), 41, Int32(-0x101 + 0x48), true), (-0x100, 41, -0x100, true),
                                        (-0x101, 40, -0x101, true), (0x101, -41, 0x101 - 0x48, false),
                                        (0x100, -41, 0x100, false), (0x101, -40, 0x101, false)] {
            let wb = try world(px: Int16(327 + cxOff), py: 1000)
            let (b, _) = try bat(wb, type: 0x6d1)
            wb.active.update(id: b) { t in
                t.subtype = 9
                t.vx = vx
                t.mirrored = !flip
            }
            let bx0 = try slot(wb, b).x256
            frame(wb, b, TileSolver(world: wb))
            let t = try slot(wb, b)
            XCTAssertEqual([t.vx, t.x256 - bx0], [want, 2 * want], "vx \(vx) offset \(cxOff)")
            XCTAssertEqual(t.mirrored, flip, "vx \(vx) offset \(cxOff)")
        }
        // Level with the player: no facing change, no brake. An asleep bat: no brake.
        do {
            let wb = try world(px: 327, py: 1000)
            let (b, _) = try bat(wb, type: 0x6d1)
            wb.active.update(id: b) { $0.subtype = 9; $0.vx = 0x200; $0.mirrored = true }
            frame(wb, b, TileSolver(world: wb))
            XCTAssertEqual([try slot(wb, b).vx, try slot(wb, b).mirrored ? 1 : 0], [0x200, 1])
            // Level (M l. 68512–68525: `<` both ways): the facing held from either side.
            do {
                let wl = try world(px: 327, py: 1000)
                let (lb, _) = try bat(wl, type: 0x6d1)
                wl.active.update(id: lb) { $0.subtype = 9; $0.vx = -0x200; $0.mirrored = false }
                frame(wl, lb, TileSolver(world: wl))
                XCTAssertEqual([try slot(wl, lb).vx, try slot(wl, lb).mirrored ? 1 : 0], [-0x200, 0])
            }
            // The path arm's facing (M l. 68748–68753) level too: held either way.
            for held in [true, false] {
                let (pb, _) = try bat(wb, type: 0x6cf, x: 300, y: 500)
                wb.active.update(id: pb) { $0.mirrored = held }
                frame(wb, pb, TileSolver(world: wb))
                XCTAssertEqual(try slot(wb, pb).mirrored, held, "path arm level, held \(held)")
            }
            let (q, _) = try bat(wb, type: 0x6cc, x: 300, y: 800)
            wb.player.centreX = 500
            wb.active.update(id: q) { $0.vx = -0x200 }
            frame(wb, q, TileSolver(world: wb))
            XCTAssertEqual([try slot(wb, q).vx, try slot(wb, q).mirrored ? 1 : 0], [-0x200, 0])
        }
        // Water (M l. 68548–68564): last frame in liquid → vy − 100 while > −800; fully under plain water (`+0x120 == 1`,
        // kind 0) or kind > 0 other than 3, with `+0x116 == 0` (after the Handles' decrement) → `+0x116 = 0x13`, HP −
        // 100, `+0xaa = 0x11`, snd 701 vol 0x55. Asleep bats too.
        for (water, kind, invul, vy, hurt, wantVY) in [
            (Int32(1), Int16(0), Int16(0), Int32(0), true, Int32(-100)), (1, 0, 1, -799, true, -899),
            (1, 0, 2, -800, false, -800), (2, 0, 0, 0, false, -100), (2, 1, 0, 0, true, -100), (2, 2, 0, 0, true, -100),
            (2, 3, 0, 0, false, -100), (1, 3, 0, 0, false, -100), (2, 4, 0, 0, true, -100),
        ] {
            let ww = try world()
            let (b, _) = try bat(ww, type: 0x6cc)
            ww.active.update(id: b) { t in
                t.waterRow = water
                t.waterKind = kind
                t.invulnerable = invul
                t.vy = vy
                t.currentApplies = false
            }
            frame(ww, b, TileSolver(world: ww))
            let t = try slot(ww, b)
            XCTAssertEqual(t.vy, wantVY, "water \(water) kind \(kind) invul \(invul)")
            XCTAssertEqual([Int(t.hp), Int(t.invulnerable), Int(t.flash)],
                           hurt ? [400, 0x13, 0x11] : [500, max(0, Int(invul) - 1), 0], "water \(water) kind \(kind)")
            XCTAssertEqual(ww.player.cues.map { [Int($0.snd), Int($0.volume)] }, hurt ? [[701, 0x55]] : [])
        }
        // The 1850 family's animation (M l. 68848–68862): `+0xa6` + 1 every frame, past 0x12 → 0, face 0x73a / 0x73b
        // (`+0x160`)[`+0xa6 >> 1`]; the surface line `+0x164` = y while `+0x11c ≠ 1`.
        for (a6, back, want, cell) in [(Int16(0x12), Int32(0), Int16(0), 0), (0x11, 0, 0x12, 9), (5, 1, 6, 3)] {
            let wf = try world()
            let (b, _) = try bat(wf, type: 0x73a, y: 100)
            wf.active.update(id: b) { $0.counterA6 = a6; $0.classWord160 = back }
            frame(wf, b, TileSolver(world: wf))
            let t = try slot(wf, b)
            XCTAssertEqual(t.counterA6, want)
            XCTAssertEqual(t.face, f(back == 0 ? Bat.familySet : Bat.familyBackSet, cell))
            XCTAssertEqual(t.surfaceLine, 100)
        }
        // Fully under (`+0x11c == 1` after the tiles, M l. 68873–68880): `+0x164` holds, and a bat that rose above it
        // is put back on it (the integer y only) with vy 0; partly under (`+0x11c` the depth below the surface): the
        // line follows y.
        do {
            let wu = try world(waterRow: 1)                       // the surface at y 32 (not row 0: endless walk)
            let (u, _) = try bat(wu, type: 0x73a, y: 100)
            wu.active.update(id: u) { $0.surfaceLine = 110; $0.vy = -0x200 }
            frame(wu, u, TileSolver(world: wu))
            let t = try slot(wu, u)
            XCTAssertEqual(t.waterRow, 1)
            XCTAssertEqual([t.y, Int(t.vy), Int(t.surfaceLine), Int(t.y256 >> 8)], [110, 0, 110, 96])
            let wp = try world(waterRow: 4)
            let (q, _) = try bat(wp, type: 0x73a, y: 100)
            wp.active.update(id: q) { $0.surfaceLine = 0 }
            frame(wp, q, TileSolver(world: wp))
            let tq = try slot(wp, q)
            XCTAssertEqual([Int(tq.waterRow), tq.y, Int(tq.surfaceLine)], [28, 100, 100])
        }
        // The insect's animation (M l. 68836–68846): `+0xa6` + 1, past 8 → − 8, the face 0x744[`+0xa6` − 1].
        for (a6, want) in [(Int16(3), Int16(4)), (8, 1), (7, 8)] {
            let wi = try world()
            let (b, _) = try bat(wi, type: 0x744)
            wi.active.update(id: b) { $0.counterA6 = a6; $0.subtype = 9 }
            frame(wi, b, TileSolver(world: wi))
            XCTAssertEqual(try slot(wi, b).counterA6, want, "a6 \(a6)")
            XCTAssertEqual(try slot(wi, b).face, f(Bat.insectSet, Int(want) - 1))
        }
        // The chaser arm runs for 0x73a and 0x744 too (M l. 68507): awake, the brake and the facing; in liquid the vy
        // lift and the damage; asleep, the waking. 0x73a centre (332, 140), 0x744 centre (324, 122).
        for (type, cx, cy, hp) in [(Int16(0x73a), 332, 140, Int16(0)), (0x744, 324, 122, 100)] {
            let wc = try world(px: Int16(cx - 41), py: 1000)
            let (b, _) = try bat(wc, type: type)
            wc.active.update(id: b) { t in
                t.counterA6 = 2
                t.subtype = 9
                t.vx = 0x101
                t.mirrored = true
                t.waterRow = 1
                t.waterKind = 0
            }
            frame(wc, b, TileSolver(world: wc))
            let t = try slot(wc, b)
            XCTAssertEqual([t.vx, t.vy], [0x101 - 0x48, -100], "\(type): the brake, the lift")
            XCTAssertFalse(t.mirrored, "\(type): P.x < c.x → flip 0")
            XCTAssertEqual([t.hp, t.invulnerable, t.flash], [hp, 0x13, 0x11], "\(type): the water damage")
            XCTAssertEqual(wc.player.cues.map { [Int($0.snd), Int($0.volume)] }, [[701, 0x55]], "\(type)")
            let ww = try world(px: Int16(cx), py: Int16(cy + 33))
            let (k, _) = try bat(ww, type: type)
            ww.active.update(id: k) { $0.counterA6 = 0 }
            frame(ww, k, TileSolver(world: ww))
            XCTAssertEqual(ww.player.cues.map(\.snd), [608], "\(type): wakes")
            // 0x73a: 0x14 + 1 past 0x12 → 0; 0x744: 0x14 + 1 = 0x15, − 8 = 13, clamped to 8 (M l. 68839–68846).
            XCTAssertEqual(try slot(ww, k).counterA6, type == 0x744 ? 8 : 0, "\(type)")
        }
        // The 0x6cc… animation bound (M l. 68826: `< 0x6d6`): 0x6d5 steps, 0x6d6 does not.
        do {
            let wa = try world()
            let (b, _) = try bat(wa, type: 0x6d5)
            wa.active.update(id: b) { $0.counterA6 = 4 }
            frame(wa, b, TileSolver(world: wa))
            XCTAssertEqual(try slot(wa, b).counterA6, 5)
            XCTAssertEqual(try slot(wa, b).face, f(Bat.batSet, 2))
            wa.active.update(id: b) { $0.type = 0x6d6; $0.counterA6 = 4; $0.face = nil }
            frame(wa, b, TileSolver(world: wa))
            XCTAssertEqual(try slot(wa, b).counterA6, 4, "0x6d6: no animation")
            XCTAssertNil(try slot(wa, b).face)
        }
        // Fully under on exactly the surface line (M l. 68877: `y < +0x164`): vy kept.
        do {
            let wu = try world(waterRow: 1)
            let (u, _) = try bat(wu, type: 0x73a, y: 100)
            wu.active.update(id: u) { $0.surfaceLine = 96; $0.vy = -0x200 }
            frame(wu, u, TileSolver(world: wu))
            let t = try slot(wu, u)
            XCTAssertEqual([Int(t.waterRow), t.y, Int(t.surfaceLine), Int(t.vy)], [1, 96, 96, -0x200])
        }
        // An unplaced 1740-family type (0x6cf): the path arm with no path — faces the player, `+0x8a = 0`, motionless.
        do {
            let wp = try world(px: 100)
            let (b, _) = try bat(wp, type: 0x6cf)
            wp.active.update(id: b) { $0.mirrored = true }
            frame(wp, b, TileSolver(world: wp))
            let t = try slot(wp, b)
            XCTAssertEqual([t.mirrored, t.currentApplies], [false, false])
            XCTAssertEqual([t.x, t.y, Int(t.counterA6)], [300, 100, 0])
            XCTAssertEqual(t.face, f(Bat.batSet, 0))
        }
    }

    // MARK: - the path bats

    func testPathBat1741() throws {
        // Level 3's 1741 (rec 189: mode 2, 340 px, speed 800) on an empty grid: the path arm (M l. 68731–68763) — `+0x8a =
        // 0`; mode 2: vy → 0 by 0x100 a frame (0 inside ±0x100), flip = vx > 0; `.HandleProgrammedPath` (M l.
        // 39384–39468); then x moves 2·vx (`+0x14 += vx` and `.ApplyGravityAndSeparateFromTiles`).
        let w3 = try world(level: 3)
        let rec = w3.level.placements[189]
        let w = try world(px: 0, py: 0)
        let solver = TileSolver(world: w)
        var e = try SetupFaces.setup(rec, context: SetupFaces.Context(level: w3.level, playerX: 0)).slot
        e.x256 = 300 << 8                                                 // moved onto the synthetic grid
        e.x = 300
        e.y = 100
        e.y256 = 100 << 8
        let lo: Int32 = (300 << 8) + 8 * 800, hi: Int32 = (300 << 8) + 340 * 256 - 8 * 800
        e.pathLow = lo
        e.pathHigh = hi
        e.vy = 0x250
        let id = w.active.insert(e)
        let x0 = e.x256
        frame(w, id, solver)
        var s = try slot(w, id)
        XCTAssertEqual([s.vx, s.vy, s.x256 - x0, s.pathDirection], [800, 0x150, 1600, 1])
        XCTAssertEqual([s.mirrored, s.currentApplies], [true, false])
        XCTAssertEqual(Int(s.counterA6), 2, "the 0x6cc… animation: + 1")
        XCTAssertEqual(s.face, f(Bat.batSet, 1))
        XCTAssertEqual(s.jumpBonus, 0)
        frame(w, id, solver)
        XCTAssertEqual(try slot(w, id).vy, 0x50)
        frame(w, id, solver)
        XCTAssertEqual(try slot(w, id).vy, 0, "inside ±0x100 → 0")
        w.active.update(id: id) { $0.vy = -0x101 }
        frame(w, id, solver)
        XCTAssertEqual(try slot(w, id).vy, -1)
        w.active.update(id: id) { $0.vy = -0x100 }
        frame(w, id, solver)
        XCTAssertEqual(try slot(w, id).vy, 0)
        // vx 0: flip 0 (`+0x24 < 1`, M l. 68741).
        w.active.update(id: id) { $0.vx = 0; $0.mirrored = true; $0.pathSpeed = 0 }
        frame(w, id, solver)
        XCTAssertFalse(try slot(w, id).mirrored)
        w.active.update(id: id) { $0.vx = 800; $0.pathSpeed = 800 }
        // Past `+0x104` (`+0x104 < +0x14`): direction −1, vx kept this frame; then − 800 >> 4 = 50 a frame to −800.
        w.active.update(id: id) { $0.x256 = hi + 1 }
        frame(w, id, solver)
        s = try slot(w, id)
        XCTAssertEqual([s.pathDirection, s.vx], [-1, 800])
        frame(w, id, solver)
        XCTAssertEqual(try slot(w, id).vx, 750)
        XCTAssertTrue(try slot(w, id).mirrored, "vx still > 0")
        w.active.update(id: id) { $0.vx = -790 }
        frame(w, id, solver)
        XCTAssertEqual(try slot(w, id).vx, -800, "floored at −800")
        XCTAssertFalse(try slot(w, id).mirrored, "vx < 1 → flip 0")
        // At exactly `+0x104` the direction holds (strict compare); below `+0x100` it turns back to 1.
        w.active.update(id: id) { $0.x256 = lo; $0.vx = -800 }
        frame(w, id, solver)
        XCTAssertEqual(try slot(w, id).pathDirection, -1, "at +0x100: not before it")
        w.active.update(id: id) { $0.x256 = lo - 1; $0.vx = -800 }
        frame(w, id, solver)
        XCTAssertEqual([try slot(w, id).pathDirection, try slot(w, id).vx], [1, -800])
        frame(w, id, solver)
        XCTAssertEqual(try slot(w, id).vx, -750)
        w.active.update(id: id) { $0.pathDirection = 1; $0.x256 = hi; $0.vx = 790 }
        frame(w, id, solver)
        XCTAssertEqual([try slot(w, id).pathDirection, try slot(w, id).vx], [1, 800], "at +0x104: capped, not turned")
        // The animation runs 2 … 0x15 → 2.
        w.active.update(id: id) { $0.counterA6 = 0x15 }
        frame(w, id, solver)
        XCTAssertEqual([Int(try slot(w, id).counterA6)], [2])

        // A mode-1 path bat (vertical): faces the player, vy accelerates by p3 >> 4 toward ±p3 between its bounds.
        let wv = try world(px: 100, py: 0)
        let (v, _) = try bat(wv, type: 0x6cd, x: 300, y: 100, p1: 1, p2: 100, p3: 0x100)
        wv.active.update(id: v) { $0.vy = 0x80; $0.vx = 0x40 }
        let y0 = try slot(wv, v).y256
        frame(wv, v, TileSolver(world: wv))
        var t = try slot(wv, v)
        XCTAssertEqual([t.vy, t.y256 - y0, t.vx], [0x90, 0x120, 0x40], "vy + 0x10; the vy decay is mode 2's only")
        XCTAssertFalse(t.mirrored, "P.x < c.x → flip 0")
        wv.player.centreX = 1000
        wv.active.update(id: v) { $0.vy = 0x100 }
        frame(wv, v, TileSolver(world: wv))
        t = try slot(wv, v)
        XCTAssertEqual(t.vy, 0x100, "capped at p3")
        XCTAssertTrue(t.mirrored)
        wv.active.update(id: v) { $0.y256 = $0.pathHigh + 1 }
        frame(wv, v, TileSolver(world: wv))
        XCTAssertEqual(try slot(wv, v).pathDirection, -1)

        // Path modes 10 / 11 (M l. 39354–39378, 39448–39459) — on no placed Bat (SetupFaces refuses them); the maces,
        // cannons and the Gremlin share the pair. The Setup: `+0xf8 = 0`, then with a record `.MakeRadial(s, +0x10,
        // +0xe, r = p2, speed = p3 — 0 in the 1xx form (`bVar1` cleared, M l. 39310–39313) —, angle = p4, g 0 (10) /
        // 0x1e (11), 0, 0, 0)`; no `.MakeRadiusSprites` (every caller passes −1). No record: no block.
        func radialBat(_ wr: SpriteWorld, p1: Int16) -> (Int, Placement) {
            var r = SpriteSlot(type: 0x6cd, x: 300, y: 100)
            r.x256 = 300 << 8
            r.y256 = 100 << 8
            r.centre = SpriteSlot.Point(x: 327, y: 131)
            r.handler = .bat
            let rec = Placement(index: 0, flag: 1, byte1: 0, type: 0x6cd, p1: p1, p2: 40, p3: 0x200, p4: 90, y: 100,
                                x: 300)
            ProgrammedPath.setup(&r, record: rec)
            return (wr.active.insert(r), rec)
        }
        for (p1, mode, speed, g) in [(Int16(10), Int32(10), Int32(0x200), Int16(0)), (11, 11, 0x200, 0x1e),
                                     (110, 10, 0, 0), (111, 11, 0, 0x1e), (-10, 10, 0x200, 0), (-111, 11, 0, 0x1e)] {
            let wr = try world()
            let (rid, rec) = radialBat(wr, p1: p1)
            let r = try slot(wr, rid)
            XCTAssertEqual([r.pathMode, r.pathSpeed, r.pathDirection, r.vx, r.vy], [mode, 0x200, 0, 0, 0], "p1 \(p1)")
            ProgrammedPath.makeRadial(wr, id: rid, record: rec)
            let b = try XCTUnwrap(try slot(wr, rid).radial, "p1 \(p1)")
            XCTAssertEqual([b.hubX, b.hubY, b.radius, b.radiusCopy, b.speed, b.angle],
                           [327 << 8, 131 << 8, 40 << 8, 40 << 8, speed, 90 << 8], "p1 \(p1)")
            XCTAssertEqual([b.gravity, b.damp, b.persp, b.spokeCount], [g, 0, 0, 0], "p1 \(p1)")
            XCTAssertEqual(b.hubDamp, 0)
            let wn = try world()
            let (nid, _) = radialBat(wn, p1: p1)
            ProgrammedPath.makeRadial(wn, id: nid, record: nil)
            XCTAssertNil(try slot(wn, nid).radial, "no record: no block")
        }
        do {
            let wr = try world()
            let (rid, rec) = radialBat(wr, p1: 2)
            ProgrammedPath.makeRadial(wr, id: rid, record: rec)
            XCTAssertNil(try slot(wr, rid).radial, "mode 2: no block")
        }
        // The Handle: `+0xf8` < 0 → + 1, else 0; vx = vy = 0; `.UpdateRadialPos`, `.UpdateRadiusSprites(s, 0, 0)`;
        // `+0x194 = 0`. The position against `RadialMotion.updatePosition` on a twin.
        for (dir, want) in [(Int32(-3), Int32(-2)), (-1, 0), (0, 0), (1, 0), (5, 0)] {
            let wr = try world(), wq = try world()
            let (rid, rec) = radialBat(wr, p1: 10)
            let (qid, _) = radialBat(wq, p1: 10)
            ProgrammedPath.makeRadial(wr, id: rid, record: rec)
            ProgrammedPath.makeRadial(wq, id: qid, record: rec)
            for (ww, i) in [(wr, rid), (wq, qid)] {
                ww.active.update(id: i) { c in
                    c.pathDirection = dir
                    c.vx = 123
                    c.vy = -45
                    c.jumpBonus = 7
                }
            }
            RadialMotion.updatePosition(wq, id: qid)
            let q = try slot(wq, qid)
            var t = try slot(wr, rid)
            ProgrammedPath.handle(wr, id: rid, slot: &t)
            XCTAssertEqual([t.pathDirection, t.vx, t.vy, t.jumpBonus], [want, 0, 0, 0], "dir \(dir)")
            XCTAssertEqual(t.radial?.angle, (90 << 8) + 0x200, "dir \(dir): `.UpdateRadialPos` ran")
            XCTAssertEqual([t.x, t.y, Int(t.x256), Int(t.y256)], [q.x, q.y, Int(q.x256), Int(q.y256)], "dir \(dir)")
            XCTAssertEqual(t.radial, q.radial)
            // The slot-only Handle makes the same stores (no radial update).
            var u = SpriteSlot(type: 0x6cd, x: 0, y: 0)
            u.pathMode = 11
            u.pathDirection = dir
            u.vx = 123
            u.vy = -45
            u.jumpBonus = 7
            ProgrammedPath.handle(&u)
            XCTAssertEqual([u.pathDirection, u.vx, u.vy, u.jumpBonus], [want, 0, 0, 0], "dir \(dir)")
        }
        // Through the Bat Handle's path arm: the radial step runs (vx, vy 0; the angle advanced).
        do {
            let wr = try world(px: 0, py: 0)
            let (rid, rec) = radialBat(wr, p1: 10)
            ProgrammedPath.makeRadial(wr, id: rid, record: rec)
            wr.active.update(id: rid) { $0.vx = 300 }
            frame(wr, rid, TileSolver(world: wr))
            let t = try slot(wr, rid)
            XCTAssertEqual([t.vx, t.vy, t.radial?.angle ?? 0], [0, 0, (90 << 8) + 0x200])
        }
        // `+0x194 = 0` is the path's (modes 1 / 2), not the arm's: a mode-0 path bat keeps it.
        do {
            let wz = try world(px: 0, py: 0)
            let (z, _) = try bat(wz, type: 0x6cd, x: 300, y: 100, p1: 0)
            wz.active.update(id: z) { $0.jumpBonus = 7 }
            frame(wz, z, TileSolver(world: wz))
            XCTAssertEqual(try slot(wz, z).jumpBonus, 7, "mode 0: no store")
            let (y2, _) = try bat(wz, type: 0x6cd, x: 300, y: 100, p1: 2, p2: 100, p3: 0x100)
            wz.active.update(id: y2) { $0.jumpBonus = 7 }
            frame(wz, y2, TileSolver(world: wz))
            XCTAssertEqual(try slot(wz, y2).jumpBonus, 0, "mode 2: `+0x194 = 0`")
            let (y1, _) = try bat(wz, type: 0x6cd, x: 300, y: 100, p1: 1, p2: 100, p3: 0x100)
            wz.active.update(id: y1) { $0.jumpBonus = 7 }
            frame(wz, y1, TileSolver(world: wz))
            XCTAssertEqual(try slot(wz, y1).jumpBonus, 0, "mode 1: `+0x194 = 0`")
        }
    }

    func testPathBatSpit() throws {
        // A spitter (1742 → 0x6cd with `+0x14c = 1`; path mode 0 — no motion) (M l. 68765–68785): `+0x154 > 0` → − 1;
        // at 0 with |P.y − c.y| < 0x1e: `MTNewSprite(0x712, c.x − 12, c.y − 7, layer + 1, −1, .SetupEnemyShotSprite)`
        // (its Setup's R(5)), vx ±0x708 by `+0x17e`, its integer x + vx and y + (i16) the bat's vy, vy = the bat's vy >> 2;
        // `+0x154 = R(0x4b) + 0x3c`.
        for seed in Int32(1)...24 {
            for right in [true, false] {
                let w = try world(px: right ? 900 : 10, py: 131 + 0x1d)
                let (id, _) = try bat(w, type: 0x6ce, x: 300, y: 100, p1: 0)
                w.active.update(id: id) { t in
                    t.classWord154 = 1
                    t.vy = -0x12345
                }
                w.rng = FastRand(seed: seed)
                var r = w.rng
                let phase = r.next(5)
                let cool = Int32(r.next(0x4b)) + 0x3c
                let before = Set(w.active.sprites.map(\.id))
                frame(w, id, TileSolver(world: w))
                let s = try slot(w, id)
                XCTAssertEqual(w.rng.seed, r.seed, "seed \(seed)")
                XCTAssertEqual(s.classWord154, cool, "seed \(seed)")
                let spits = w.active.sprites.filter { !before.contains($0.id) }
                XCTAssertEqual(spits.count, 1)
                let p = try XCTUnwrap(spits.first)
                let vx: Int32 = right ? 0x708 : -0x708
                XCTAssertEqual([Int(p.type), Int(p.layer), Int(p.phase)], [0x712, 0xc, Int(phase)])
                XCTAssertEqual(p.handler, .enemyShot)
                XCTAssertEqual([p.vx, p.vy], [vx, -0x12345 >> 2])
                XCTAssertEqual([p.x, p.y], [327 - 12 + Int(vx), 124 - 0x2345], "integer copies + vx, + (i16) the bat's vy")
                XCTAssertEqual([Int(p.x256 >> 8), Int(p.y256 >> 8)], [327 - 12, 124], "the 24.8 position untouched")
                XCTAssertEqual(s.mirrored, right)
            }
        }
        // Edges: |P.y − c.y| 0x1e → no spit (the count stays 0); the count 2 → 1 → no spit; not a spitter → none.
        for (dy, count, spitter, spits, left) in [(0x1e, Int32(1), true, 0, Int32(0)), (-0x1d, 1, true, 1, -1),
                                                  (-0x1e, 1, true, 0, 0), (0, 2, true, 0, 1), (0, 0, true, 1, -1),
                                                  (0, 1, false, 0, 0)] {
            let w = try world(px: 900, py: Int16(131 + dy))
            let (id, _) = try bat(w, type: spitter ? 0x6ce : 0x6cd, x: 300, y: 100, p1: 0)
            w.active.update(id: id) { $0.classWord154 = count }
            let n = w.active.sprites.count
            frame(w, id, TileSolver(world: w))
            XCTAssertEqual(w.active.sprites.count - n, spits, "dy \(dy) count \(count)")
            let c154 = try slot(w, id).classWord154
            if left < 0 { XCTAssertGreaterThanOrEqual(c154, 0x3c) } else { XCTAssertEqual(c154, left, "dy \(dy)") }
        }
        // The 1850 spitter (0x73c → 0x73b) spits the same.
        let w = try world(px: 900, py: 100 + 0x1e + 0x14)
        let (id, _) = try bat(w, type: 0x73c, x: 300, y: 100, p1: 0)
        w.active.update(id: id) { $0.classWord154 = 1 }
        let n = w.active.sprites.count
        frame(w, id, TileSolver(world: w))
        XCTAssertEqual(w.active.sprites.count - n, 1)
        XCTAssertEqual(w.active.sprites.last?.type, 0x712)
    }

    // MARK: - swarms

    func testSwarmMembersHome() throws {
        // A member's Handle (M l. 68336–68443), relative to its centre C = (`+0x14c`, `+0x150`): the face 0x74d[`+0x46`
        // + 1]; alive: the pull toward C — `FUN_1003f218(d, R(0x96) + 0x172)` with d = Dir((0, 0), (y + 12, x + 12)) —,
        // `.EnforceMaxSpeed(0xa8c)`, the re-scatter inside 8 px of C at low speed, the jitter ±200; one integration.
        let w = try world(px: 0, py: 0)
        let solver = TileSolver(world: w)
        let m = try XCTUnwrap(w.newSprite(type: Bat.defaultMember, x: 0, y: 0, layer: 4, handler: .swarmMember,
                                          record: 0x200) { c in Bat.setupSwarmMember(&c, phase: 7) })
        // Rel (−112, −12): (y + 12, x + 12) = (0, −100) → C lies due right: d 18.
        func place(_ rx: Int, _ ry: Int, vx: Int32 = 0, vy: Int32 = 0) {
            w.active.update(id: m) { c in
                c.classTimer = 500
                c.classWord150 = 400
                c.x = 500 + rx
                c.y = 400 + ry
                c.x256 = Int32(500 + rx) << 8
                c.y256 = Int32(400 + ry) << 8
                c.vx = vx
                c.vy = vy
            }
        }
        XCTAssertEqual(BloodSpray.direction(target: (v: 0, h: 0), from: (v: 0, h: -100)), 18)
        place(-112, -12)
        for seed in Int32(1)...16 {
            place(-112, -12)
            w.rng = FastRand(seed: seed)
            var r = w.rng
            let pull = Int32(r.next(0x96)) + 0x172
            let jx = Int32(r.next(400)) - 200, jy = Int32(r.next(400)) - 200
            frame(w, m, solver)
            let s = try slot(w, m)
            XCTAssertEqual(w.rng.seed, r.seed, "seed \(seed)")
            XCTAssertEqual([s.vx, s.vy], [pull + jx, jy], "seed \(seed)")
            XCTAssertEqual(s.x256, Int32(388) << 8 + pull + jx, "one integration, C added back")
            XCTAssertEqual(s.x, 388 + Int((pull + jx) >> 8))
        }
        XCTAssertEqual(try slot(w, m).phase, 7, "7 → 8 → 0, then + 1 each of 16 frames")
        XCTAssertEqual(try slot(w, m).face, f(Bat.memberSet, 7))
        // `.EnforceMaxSpeed(0xa8c)` after the pull: vx 0xa00 + pull capped at 0xa8c, then the jitter.
        do {
            place(-112, -12, vx: 0xa00)
            var r = w.rng
            _ = r.next(0x96)
            let jx = Int32(r.next(400)) - 200
            frame(w, m, solver)
            XCTAssertEqual(try slot(w, m).vx, 0xa8c + jx)
        }
        // The re-scatter (M l. 68386–68417): |x|, |y| < 8 and — after the pull and the cap — |vx|, |vy| < 0x578 → vx,
        // vy = R(0x12fc) − 2430 each. The speed edge: the pull's x part measured from rest on a copy of the stream, then
        // vx set so that it lands on 0x577 / 0x578 (and −0x577 / −0x578).
        func landing(_ edge: Int32) -> Int32 {
            // The vx before the pull that the fused `fmadd`/`fnmsub` + `fctiwz` of `FUN_1003f218` turns into `edge`.
            let d = BloodSpray.direction(target: (v: 0, h: 0), from: (v: 12, h: 12))
            var r = w.rng
            let m = Int32(r.next(0x96)) + 0x172
            for v in (edge - 600)...(edge + 600) {
                var probe = SpriteSlot(type: 0x74c, x: 0, y: 0)
                probe.vx = v
                PlayerShot.addDirImpulse(&probe, dir: d, magnitude: m)
                if probe.vx == edge { return v }
            }
            XCTFail("no vx lands on \(edge)")
            return 0
        }
        // (rel x, rel y, the vx after the pull — nil: from rest —, scatter expected).
        var rows: [(Int, Int, Int32?, Bool)] = [(7, -7, nil, true), (8, 0, nil, false), (0, 8, nil, false),
                                                (-7, -7, nil, true), (-8, 0, nil, false), (0, -8, nil, false),
                                                (0, 0, 0x577, true), (0, 0, 0x578, false), (0, 0, -0x577, true),
                                                (0, 0, -0x578, false)]
        // The pull aims from (y + 12, x + 12) (M l. 68363): two places where x + 11 or x + 13 would aim elsewhere.
        func aim(_ rx: Int, _ k: Int) -> Int {
            BloodSpray.direction(target: (v: 0, h: 0), from: (v: Int16(30 + 12), h: Int16(rx + k)))
        }
        let below = try XCTUnwrap((-60...60).first { abs($0) >= 8 && aim($0, 12) != aim($0, 11) })
        let above = try XCTUnwrap((-60...60).first { abs($0) >= 8 && aim($0, 12) != aim($0, 13) })
        rows += [(below, 30, nil, false), (above, 30, nil, false)]
        for (rx, ry, edge, scatter) in rows {
            place(rx, ry, vx: edge.map(landing) ?? 0)
            let pre = try slot(w, m)
            var r = w.rng
            let d = BloodSpray.direction(target: (v: 0, h: 0), from: (v: Int16(ry + 12), h: Int16(rx + 12)))
            let pull = Int32(r.next(0x96)) + 0x172
            var probe = pre
            PlayerShot.addDirImpulse(&probe, dir: d, magnitude: pull)
            probe.enforceMaxSpeed(0xa8c)
            let small = abs(probe.vx) < 0x578 && abs(probe.vy) < 0x578
            if rx == 0 && ry == 0 { XCTAssertEqual(small, scatter, "the speed edge lands where meant") }
            var wantVX = probe.vx, wantVY = probe.vy
            if scatter && small {
                wantVX = Int32(r.next(0x12fc)) - 2430
                wantVY = Int32(r.next(0x12fc)) - 2430
            }
            wantVX += Int32(r.next(400)) - 200
            wantVY += Int32(r.next(400)) - 200
            frame(w, m, solver)
            XCTAssertEqual(w.rng.seed, r.seed, "rel (\(rx), \(ry)) edge \(String(describing: edge))")
            XCTAssertEqual([try slot(w, m).vx, try slot(w, m).vy], [wantVX, wantVY],
                           "rel (\(rx), \(ry)) edge \(String(describing: edge))")
        }
        // The same speed edge on vy (M l. 68404): ±0x577 scatters, ±0x578 does not.
        func landingY(_ edge: Int32) -> Int32 {
            let d = BloodSpray.direction(target: (v: 0, h: 0), from: (v: 12, h: 12))
            var r = w.rng
            let m = Int32(r.next(0x96)) + 0x172
            for v in (edge - 600)...(edge + 600) {
                var probe = SpriteSlot(type: 0x74c, x: 0, y: 0)
                probe.vy = v
                PlayerShot.addDirImpulse(&probe, dir: d, magnitude: m)
                if probe.vy == edge { return v }
            }
            XCTFail("no vy lands on \(edge)")
            return 0
        }
        for (edge, scatter) in [(Int32(0x577), true), (0x578, false), (-0x577, true), (-0x578, false)] {
            place(0, 0, vy: landingY(edge))
            let pre = try slot(w, m)
            var r = w.rng
            let d = BloodSpray.direction(target: (v: 0, h: 0), from: (v: 12, h: 12))
            var probe = pre
            PlayerShot.addDirImpulse(&probe, dir: d, magnitude: Int32(r.next(0x96)) + 0x172)
            probe.enforceMaxSpeed(0xa8c)
            XCTAssertEqual(probe.vy, edge)
            XCTAssertLessThan(abs(probe.vx), 0x578)
            var wantVX = probe.vx, wantVY = probe.vy
            if scatter {
                wantVX = Int32(r.next(0x12fc)) - 2430
                wantVY = Int32(r.next(0x12fc)) - 2430
            }
            wantVX += Int32(r.next(400)) - 200
            wantVY += Int32(r.next(400)) - 200
            frame(w, m, solver)
            XCTAssertEqual([try slot(w, m).vx, try slot(w, m).vy], [wantVX, wantVY], "vy edge \(edge)")
        }
        // The flip: x + 12 < P.x (x after the integration), both sides.
        w.player.centreX = 0
        w.rng = FastRand(seed: 5)
        place(-112, -12)
        frame(w, m, solver)
        let mx = try slot(w, m).x
        for (px, flip) in [(mx + 13, true), (mx + 12, false)] {
            w.player.centreX = Int16(px)
            w.rng = FastRand(seed: 5)
            place(-112, -12)
            frame(w, m, solver)
            XCTAssertEqual([try slot(w, m).x, try slot(w, m).mirrored ? 1 : 0], [mx, flip ? 1 : 0], "P.x \(px)")
        }

        // Dead (HP < 1): vx · 0.85, vy = max(vy, 0) + 0x32, the tile callback set; the first dead frame starts the burn
        // (`+0x1a2 = 1`) and zeroes vy; no draw.
        place(-112, -12, vx: 1000, vy: -300)
        w.active.update(id: m) { $0.hp = 0 }
        var seed = w.rng.seed
        frame(w, m, solver)
        var s = try slot(w, m)
        XCTAssertEqual(w.rng.seed, seed)
        XCTAssertEqual([s.vx, s.vy, Int32(s.burnRow)], [850, 0, 1])
        XCTAssertTrue(s.hasTileHit)
        XCTAssertEqual([s.x256, s.y256], [(Int32(388) << 8) + 850, (Int32(388) << 8) + 0x32])
        w.active.update(id: m) { $0.vy = -1 }
        seed = w.rng.seed
        frame(w, m, solver)
        s = try slot(w, m)
        XCTAssertEqual([s.vx, s.vy], [722, 0x32], "(int)(850 · 0.85) = 722; vy −1 → 0, + 0x32, the burn already running")
        w.active.update(id: m) { $0.vy = 1 }
        frame(w, m, solver)
        XCTAssertEqual(try slot(w, m).vy, 0x33, "vy ≥ 0 kept")

        // The centre's Handle (M l. 68706–68730): `.StandardSpriteHandles` twice, `FUN_1003f218(Dir((P.y, P.x), (y,
        // x)), R(6) + 0x14)`, `.EnforceMaxSpeed(400)`, `+0xb8 = 0x10009`, each live member's `+0x14c` / `+0x150` = (x, y);
        // a member with `+0xe9` dropped; the spit tail counts the radius `+0x154` down; 2·v a frame.
        // The centre's pixel copies keep the + 0x40 only until its first integration re-derives them from the 24.8
        // spawn point (300 → y 300); P level with it then: due right, d 18 (the nudge, `FindDesiredDirectionGeneric`).
        let ws = try world(px: 900, py: 0x16c)
        let (c, _) = try bat(ws, type: Bat.swarm, x: 200, y: 300, p1: 0, p2: 3, p3: 11)
        XCTAssertEqual(BloodSpray.direction(target: (v: 0x16c, h: 900), from: (v: 0x16c, h: 0x108)), 18)
        let members = try XCTUnwrap(try slot(ws, c).swarm?.members.compactMap { $0 })
        XCTAssertEqual(members.count, 3)
        ws.active.update(id: c) { $0.invulnerable = 5 }
        for seed in Int32(1)...30 {
            ws.rng = FastRand(seed: seed)
            var r = ws.rng
            let pre = try slot(ws, c)
            let d = BloodSpray.direction(target: (v: 0x16c, h: 900),
                                         from: (v: Int16(truncatingIfNeeded: pre.y), h: Int16(truncatingIfNeeded: pre.x)))
            if seed == 1 { XCTAssertEqual(d, 18) }
            var probe = pre
            PlayerShot.addDirImpulse(&probe, dir: d, magnitude: Int32(r.next(6)) + 0x14)
            probe.enforceMaxSpeed(400)
            frame(ws, c, TileSolver(world: ws))
            let t = try slot(ws, c)
            XCTAssertEqual(ws.rng.seed, r.seed, "seed \(seed)")
            XCTAssertEqual([t.vx, t.vy], [probe.vx, probe.vy], "seed \(seed)")
            if seed == 1 {
                var q = FastRand(seed: 1)
                XCTAssertEqual([t.vx, t.vy], [Int32(q.next(6)) + 0x14, 0], "due right from rest: vx + R(6) + 0x14")
                XCTAssertEqual(t.invulnerable, 3, "5 − 2: two `.StandardSpriteHandles`")
                XCTAssertEqual(t.y, 300, "re-derived from the 24.8 spawn point")
            }
            XCTAssertEqual([t.x256 - pre.x256, t.y256 - pre.y256], [2 * t.vx, 2 * t.vy])
            XCTAssertEqual(t.mode, 0x10009)
            XCTAssertEqual(t.classWord154, max(pre.classWord154 - 1, 0), "the radius counted down by the spit tail")
            if seed == 30 { XCTAssertEqual(abs(t.vx) == 400 || abs(t.vy) == 400, true, "at the 400 cap") }
            for k in members {
                XCTAssertEqual([try slot(ws, k).classTimer, try slot(ws, k).classWord150], [Int32(pre.x), Int32(pre.y)])
            }
        }
        ws.active.update(id: members[1]) { $0.dead = true }
        frame(ws, c, TileSolver(world: ws))
        var block = try XCTUnwrap(try slot(ws, c).swarm)
        XCTAssertEqual(block.members.compactMap { $0 }, [members[0], members[2]])
        XCTAssertEqual([block.alive, block.total], [2, 3])
        XCTAssertFalse(try slot(ws, c).dead)
        ws.active.update(id: members[0]) { $0.dead = true }
        ws.active.update(id: members[2]) { $0.dead = true }
        frame(ws, c, TileSolver(world: ws))
        block = try XCTUnwrap(try slot(ws, c).swarm)
        XCTAssertEqual([block.alive, Int16(block.members.compactMap { $0 }.count)], [0, 0])
        XCTAssertTrue(try slot(ws, c).dead, "alive ≤ 0 → `+0xe9 = 1`, no `.KillBat` (no score)")
        XCTAssertEqual(ws.globals.score, 0)

        // A member's hit (M l. 68989–69020): any player shot (its `+0xa6` not tested) but a type 0x74d →
        // `.KillPlayerShot`, `.HurtSprite(…, 2, 8)`, the blood spray while alive, then `.STPlay3DSoundPitched(480, 1,
        // 0xab, +0xe, R(20000) + 58000)`.
        let wh = try world()
        let mh = try XCTUnwrap(wh.newSprite(type: Bat.defaultMember, x: 320, y: 110, layer: 4, handler: .swarmMember,
                                            record: 0x200) { c in Bat.setupSwarmMember(&c, phase: 0) })
        wh.active.update(id: mh) { $0.x = 320; $0.y = 110 }             // over the shot (the blood spray's overlap)
        var l = LightTable()
        for (dmg, a6, alive) in [(Int16(40), Int16(3), true), (Int16(100), Int16(0), false)] {
            let sh = try shot(wh, damage: dmg, a6: a6)
            wh.player.cues = []
            let live = wh.particles.live
            var r = wh.rng
            let pre = try slot(wh, mh)
            Bat.hitSwarmMember(wh, id: mh, other: sh, lights: &l)
            let t = try slot(wh, mh)
            XCTAssertEqual(t.hp, alive ? 60 : -40)
            XCTAssertEqual([t.vx - pre.vx, t.vy - pre.vy], [1000 >> 3, -200 >> 3], "the push (vx >> 3, vy >> 3)")
            XCTAssertEqual([t.invulnerable, t.flash], [2, 8])
            XCTAssertEqual(wh.particles.live > live, alive, "the blood spray only while alive")
            XCTAssertEqual(wh.player.cues.map { [Int($0.snd), Int($0.volume)] }, [[480, 0xab]])
            XCTAssertEqual(wh.player.cues.first?.call, .threeDPitched)
            if !alive {
                let rate = Int32(r.next(20000)) + 58000
                XCTAssertEqual(wh.player.cues.first?.rate, rate)
            }
            wh.active.update(id: mh) { $0.invulnerable = 0 }
        }
        do {
            let w2 = try world()
            let m2 = try XCTUnwrap(w2.newSprite(type: Bat.defaultMember, x: 320, y: 110, layer: 4, handler: .swarmMember,
                                                record: 0x200) { c in Bat.setupSwarmMember(&c, phase: 0) })
            let sw = try shot(w2, type: Bat.swarm)
            Bat.hitSwarmMember(w2, id: m2, other: sw, lights: &l)
            XCTAssertEqual(try slot(w2, m2).hp, 100, "a 0x74d other: nothing")
            let st = try shot(w2, type: 1)
            Bat.hitSwarmMember(w2, id: m2, other: st, lights: &l)
            XCTAssertEqual(try slot(w2, m2).handler, .statue, "the Statue spell")
        }
        // The spray in full (a twin from the stream before the hit; the 480 rate drawn after it), 0x28 particles; HP
        // exactly 1 left still sprays, exactly 0 does not; any other sprite but a player shot: nothing (M l. 68995).
        for (dmg, sprays) in [(Int16(99), true), (100, false)] {
            let w3 = try world()
            let m3 = try XCTUnwrap(w3.newSprite(type: Bat.defaultMember, x: 320, y: 110, layer: 4, handler: .swarmMember,
                                                record: 0x200) { c in Bat.setupSwarmMember(&c, phase: 0) })
            w3.active.update(id: m3) { $0.x = 320; $0.y = 110 }
            let sh = try shot(w3, damage: dmg)
            let r = w3.rng
            Bat.hitSwarmMember(w3, id: m3, other: sh, lights: &l)
            XCTAssertEqual(try slot(w3, m3).hp, 100 - dmg)
            let parts = w3.particles.records.filter(\.alive)
            if sprays {
                var twin = try sprayTwin(w3, victim: m3, shot: sh, rng: r)
                _ = twin.rng.next(20000)
                XCTAssertEqual(parts.count, 0x28)
                XCTAssertEqual(parts, twin.parts)
                XCTAssertEqual(w3.rng.seed, twin.rng.seed)
            } else {
                XCTAssertTrue(parts.isEmpty, "HP 0: no spray")
            }
        }
        do {
            let w4 = try world()
            let m4 = try XCTUnwrap(w4.newSprite(type: Bat.defaultMember, x: 320, y: 110, layer: 4, handler: .swarmMember,
                                                record: 0x200) { c in Bat.setupSwarmMember(&c, phase: 0) })
            let other = try XCTUnwrap(w4.newSprite(type: 2, x: 330, y: 120, layer: 0xb, handler: .enemyShot) { c in
                c.x = 330
                c.y = 120
                c.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 20, right: 20)
                c.hp = 150
                c.vx = 1000
            })
            let seed = w4.rng.seed
            Bat.hitSwarmMember(w4, id: m4, other: other, lights: &l)
            XCTAssertEqual([Int(try slot(w4, m4).hp), Int(try slot(w4, m4).vx), w4.player.cues.count], [100, 0, 0])
            XCTAssertEqual(w4.rng.seed, seed)
            XCTAssertEqual(w4.active.record(id: other)?.dead, false, "not killed")
        }
        // A negative radius (no shipped swarm): the rect half rounds toward zero, r / 2 (`srawi 1; addze`), not r >> 1.
        do {
            let (_, e) = try bat(try world(), type: Bat.swarm, p2: -1, p3: -11)
            XCTAssertEqual(e.slot.hotRect, rect(5, 5, -5, -5), "−11 / 2 = −5")
        }

        // The level spawn (`SetupFaces.spawnLevelSprites`): the members are inserted active before the centre, which
        // idles (the class's `.idle`); its block names their ids; they stay active (enemies-flyers §7.5).
        let L = try LevelFile.load(from: try resources(), level: 1)
        let p = Placement(index: 0, flag: 1, byte1: 0, type: Bat.swarm, p1: 0, p2: 2, p3: 0, p4: 0, y: 300, x: 200)
        var rr = FastRand(seed: 1)
        var counting = EnemyCounting(window: true)
        let out = try SetupFaces.spawnLevelSprites(context: SetupFaces.Context(level: L, playerX: 0, records: [p]),
                                                   rng: &rr, counting: &counting) { _ in IdleSprites.Rect.noFace }
        XCTAssertEqual(out.active.sprites.map(\.handler), [.swarmMember, .swarmMember])
        XCTAssertEqual(out.active.sprites.map(\.recordIndex), [0x200, 0x200])
        XCTAssertEqual(counting.live, 1)
        XCTAssertEqual(out.tallies.enemies, 1)
    }

    // MARK: - insects

    func testInsectBodyFollows() throws {
        // The insect head copies to its body before and after its own frame (M l. 68476–68494, 68880–68898): for
        // 0x744…0x746 the body's face = 0x744[8]; the body's `+0xa` / `+0xc`, `+0x11c`, `+0x17e`, `+0x1ba`.
        let w = try world(px: 900, py: 140)
        let solver = TileSolver(world: w)
        let (id, _) = try bat(w, type: 0x744, x: 400, y: 100)
        let body = try XCTUnwrap(try slot(w, id).siblings.first)
        XCTAssertNil(try slot(w, body).face)
        w.active.update(id: id) { $0.subtype = 9; $0.vx = 0x100; $0.vy = -0x80 }
        frame(w, id, solver)
        var s = try slot(w, id), b = try slot(w, body)
        XCTAssertEqual(b.face, f(Bat.insectSet, 8))
        XCTAssertEqual([b.x, b.y], [s.x, s.y])
        XCTAssertEqual([s.x, s.y], [402, 99], "2·v")
        XCTAssertEqual(b.mirrored, s.mirrored)
        XCTAssertTrue(s.mirrored)
        XCTAssertEqual(s.face, f(Bat.insectSet, 3), "the head: `+0xa6` 3 → 4, cell a6 − 1")
        // The first copy carries the previous frame: a dead head (`+0xe9`) still copies, then returns.
        w.active.update(id: id) { t in
            t.dead = true
            t.x = 10
            t.y = 20
            t.waterRow = 1
            t.mirrored = false
            t.clip.bottom = 7
        }
        let seed = w.rng.seed
        frame(w, id, solver)
        b = try slot(w, body)
        XCTAssertEqual([b.x, b.y, Int(b.waterRow), Int(b.clip.bottom), b.mirrored ? 1 : 0], [10, 20, 1, 7, 0])
        XCTAssertEqual([try slot(w, id).x, Int(w.rng.seed == seed ? 1 : 0)], [10, 1], "no frame run")
        // 0x746 (the last of the three): the body's face too.
        let w6 = try world()
        let (id6, _) = try bat(w6, type: 0x746, x: 400, y: 100)
        frame(w6, id6, TileSolver(world: w6))
        XCTAssertEqual(try slot(w6, try XCTUnwrap(try slot(w6, id6).siblings.first)).face, f(Bat.insectSet, 8))
        // Emerging from a pipe (`+0x1b2`, M l. 68502): the first copy, then nothing — no move, no draw, no face.
        let we = try world()
        let (ide, _) = try bat(we, type: 0x744, x: 400, y: 100)
        we.active.update(id: ide) { $0.emerging = true; $0.vx = 0x300; $0.counterA6 = 5 }
        let bodyE = try XCTUnwrap(try slot(we, ide).siblings.first)
        frame(we, ide, TileSolver(world: we))
        XCTAssertEqual([try slot(we, ide).x, Int(try slot(we, ide).counterA6)], [400, 5])
        XCTAssertEqual(try slot(we, ide).face, f(Bat.insectSet, 3))
        XCTAssertEqual([try slot(we, bodyE).x, try slot(we, bodyE).y], [400, 100], "the before-copy ran")
        XCTAssertEqual(try slot(we, bodyE).face, f(Bat.insectSet, 8), "the before-copy's face")
        // 0x745 animates as 0x744 does (M l. 68838: `type − 0x744 < 2`); past 8 after the − 8 → 8 (a hit's 0x15 →
        // 0x16 − 8 = 14 → 8; M l. 68843–68846).
        for (type, a6, want) in [(Int16(0x745), Int16(3), Int16(4)), (0x744, 0x15, 8), (0x745, 0x10, 8),
                                 (0x744, 8, 1)] {
            let wa = try world()
            let (a, _) = try bat(wa, type: type, x: 400, y: 100)
            wa.active.update(id: a) { $0.subtype = 9; $0.counterA6 = a6 }
            frame(wa, a, TileSolver(world: wa))
            XCTAssertEqual(try slot(wa, a).counterA6, want, "\(type) a6 \(a6)")
            XCTAssertEqual(try slot(wa, a).face, f(Bat.insectSet, Int(want) - 1), "\(type) a6 \(a6)")
        }
        // Types 0x747…0x74c: no body face copy (the position still copies); their path arm (no path) holds them still.
        let w2 = try world()
        let (id2, _) = try bat(w2, type: 0x747, x: 400, y: 100)
        let body2 = try XCTUnwrap(try slot(w2, id2).siblings.first)
        frame(w2, id2, TileSolver(world: w2))
        XCTAssertNil(try slot(w2, body2).face)
        XCTAssertEqual([try slot(w2, body2).x, try slot(w2, body2).y], [400, 100])
        XCTAssertEqual(try slot(w2, id2).face, f(Bat.insectSet, 3), "the Setup face held: no animation arm")
        // The body's own Handle: the Standard pair — its centre from its empty rect.
        frame(w, body, solver)
        XCTAssertEqual(try slot(w, body).centre, SpriteSlot.Point(x: 10, y: 20))
        // `.KillBat` recurses into `+0x1d4` (M l. 69039–69041): the head's death kills the body (+100 more): 700.
        let wk = try world()
        wk.levelIndex = 3
        let (k, _) = try bat(wk, type: 0x744, x: 400, y: 100)
        let kb = try XCTUnwrap(try slot(wk, k).siblings.first)
        wk.active.update(id: k) { $0.hp = 0 }
        frame(wk, k, TileSolver(world: wk))
        XCTAssertEqual(try slot(wk, k).subtype, 4)
        frame(wk, k, TileSolver(world: wk))
        s = try slot(wk, k)
        b = try slot(wk, kb)
        XCTAssertEqual([s.dead, s.killedForGood, b.dead, b.killedForGood], [true, true, true, true])
        XCTAssertEqual(wk.globals.score, 700)
        XCTAssertEqual(wk.enemies.live, 0, "the head counted down once; the body was never counted")
        XCTAssertEqual(wk.globals.achieved[0][3], 1)
        XCTAssertEqual(b.face, f(Bat.insectSet, 8), "the after-copy still runs on the death frame")
    }

    // MARK: - death

    func testBatDeathCoinsBlood() throws {
        // HP < 1 → state 4 at the end of the Handle (M l. 68863–68865); the next Handle dies (M l. 68786–68825): R(3);
        // N = 0xaa at Effects 1, else 100; `+0x5c = 0`; snd 703 (vol 0x100); `.KillBat` (+100, the stat, `+0xe9`,
        // `+0xea`); +500; R(3) + 1 coins 0x516 at (c.x − 4, c.y − 4), layer 2 (vy −0x578 − R(0x640), vx R(1000) − 500);
        // N blood particles `NewParticle(2, 0x78, (c.y + R(6) − 3, c.x + R(6) − 3), 4, R(0x28a) − 0x145, −0x352 − R(700)
        // − R(200), 0, 1)` (the h offset drawn first) and N >> 3 with R(900), R(300), R(900) − 0x1c2.
        for effects in [Int16(1), 2] {
            let w = try world()
            let solver = TileSolver(world: w)
            w.levelIndex = 2
            let (id, _) = try bat(w, type: 0x6d1)
            w.active.update(id: id) { t in
                t.hp = 0
                t.subtype = 9
                t.counterA6 = 2
            }
            let live = w.enemies.live
            frame(w, id, solver, effects: effects)
            var s = try slot(w, id)
            XCTAssertEqual([Int(s.subtype), Int(w.globals.score)], [4, 0])
            XCTAssertFalse(s.dead)
            w.rng = FastRand(seed: 3)
            var r = w.rng
            let n = Int(r.next(3)) + 1
            XCTAssertEqual(n, 3, "seed 3: R(3) 2 (R(2) 1, R(4) 3)")
            let c = s.centre
            XCTAssertEqual([c.x, c.y], [327, 131])
            w.player.cues = []
            let before = Set(w.active.sprites.map(\.id))
            frame(w, id, solver, effects: effects)
            s = try slot(w, id)
            XCTAssertEqual([s.dead, s.killedForGood, s.hasHit], [true, true, false])
            XCTAssertEqual(s.face, f(Bat.batSet, 2), "re-faced by the animation that follows (`+0xa6` 3 → 4, 4 >> 1)")
            XCTAssertNil(s.draw, "`+0xe9`: not drawn")
            XCTAssertEqual(w.globals.score, 600)
            XCTAssertEqual(w.enemies.live, live - 1)
            XCTAssertEqual(w.globals.achieved[0][2], 1)
            XCTAssertEqual(w.player.cues.map { [Int($0.snd), Int($0.volume), Int($0.priority)] }, [[703, 0x100, 1]])
            XCTAssertEqual(w.player.cues.first?.position, c)
            let coins = w.active.sprites.filter { !before.contains($0.id) }.sorted { $0.id < $1.id }
            XCTAssertEqual(coins.count, n)
            var rc = r
            for coin in coins {
                var scratch = SpriteSlot(type: 0x516, x: c.x - 4, y: c.y - 4)
                _ = try BonusSprite.setup(&scratch, x: c.x - 4, y: c.y - 4, level: w.level, records: w.records,
                                          effects: effects, lightCount: 0, counting: false, playerLayer: 0,
                                          rng: &rc) { _, _, _, _ in 0 }
                XCTAssertEqual([Int(coin.type), Int(coin.x256 >> 8), Int(coin.y256 >> 8)], [0x516, c.x - 4, c.y - 4])
                XCTAssertEqual(coin.handler, .bonus)
                let cvy = -0x578 - Int32(rc.next(0x640)), cvx = Int32(rc.next(1000)) - 500
                XCTAssertEqual([coin.vy, coin.vx], [cvy, cvx])
            }
            let count = effects == 1 ? 0xaa : 100
            var want: [[Int]] = []
            for k in 0..<(count + (count >> 3)) {
                let big = k >= count
                let ho = Int(rc.next(6)), vo = Int(rc.next(6))
                let a = Int(rc.next(big ? 900 : 700)), b = Int(rc.next(big ? 300 : 200)), cc = Int(rc.next(big ? 900 : 0x28a))
                want.append([c.x + ho - 3, c.y + vo - 3, cc - (big ? 0x1c2 : 0x145), -0x352 - a - b])
            }
            let parts = w.particles.records.filter(\.alive)
            XCTAssertEqual(parts.count, count + (count >> 3), "effects \(effects)")
            XCTAssertEqual(Set(parts.map { [Int($0.kind), Int($0.gravity), Int($0.shape), Int($0.mode)] }),
                           [[2, 0x78, 4, 1]])
            XCTAssertEqual(parts.map { [Int($0.x >> 8), Int($0.y >> 8), Int($0.vx), Int($0.vy)] }, want)
            XCTAssertEqual(Set(parts.map(\.age)), [0], "delay 0 (M l. 68813, 68823)")
            XCTAssertEqual(w.rng.seed, rc.seed, "R(3), the coins, the blood")
            // `+0xe9`: the next Handle does nothing.
            let after = w.rng.seed
            frame(w, id, solver, effects: effects)
            XCTAssertEqual([w.rng.seed, Int32(w.globals.score)], [after, 600])
        }
        // Uncounted (outside the window): no tally; still 600.
        let wu = try world()
        let (u, _) = try bat(wu, type: 0x6d1, counted: false)
        wu.active.update(id: u) { $0.subtype = 4 }
        frame(wu, u, TileSolver(world: wu))
        XCTAssertEqual([Int(wu.globals.score), Int(wu.enemies.live)], [600, 0])
        XCTAssertEqual(wu.globals.achieved[0][0], 0)

        // The dying state's face 0 (M l. 68793) stands for the types no animation re-faces (0x746…0x74c).
        do {
            let wd = try world()
            let (d, _) = try bat(wd, type: 0x747)
            wd.active.update(id: d) { $0.subtype = 4 }
            XCTAssertNotNil(try slot(wd, d).face)
            frame(wd, d, TileSolver(world: wd))
            XCTAssertEqual(try slot(wd, d).dead, true)
            XCTAssertNil(try slot(wd, d).face, "0x747: face 0 held")
        }
        // The bat hit's spray and sounds (M l. 68950–68963): `.BloodSpray(s, o, 0x28, 400, 0x96, 2)` (measured on a
        // twin from the stream after the 609 rate), then HP 200 < 0xc9 → snd 702 at vol 0x100.
        do {
            let wh = try world()
            let (b, _) = try bat(wh, type: 0x6cc)
            let sh = try shot(wh, damage: 300)
            var r = wh.rng
            _ = r.soundRate()
            var l = LightTable()
            Bat.hit(wh, id: b, other: sh, lights: &l)
            XCTAssertEqual(try slot(wh, b).hp, 200)
            XCTAssertEqual(wh.player.cues.map { [Int($0.snd), Int($0.volume), Int($0.priority)] },
                           [[609, 0xab, 1], [702, 0x100, 1]])
            XCTAssertEqual(wh.player.cues.last?.call, .threeD)
            let twin = try sprayTwin(wh, victim: b, shot: sh, rng: r)
            let parts = wh.particles.records.filter(\.alive)
            XCTAssertEqual(parts.count, 0x28)
            XCTAssertEqual(parts, twin.parts)
            XCTAssertEqual(Set(parts.map(\.kind)), [2])
            XCTAssertEqual(wh.rng.seed, twin.rng.seed, "the spray is the hit's last draw")
        }

        // The crush (M l. 68962–68984): a Statue or Box whose `.PlatformBounce` is 2 (measured on a twin world) with the
        // solid falling or the bat on ground → HP 0, `+0x150 = 0x16`; else nothing; a Platform: nothing.
        func crush(_ handler: SpriteHandler, solidVY: Int32, grounded: Bool) throws -> (Int16, Int16, Int32) {
            func make() throws -> (SpriteWorld, Int, Int) {
                let wc = try world()
                let (b, _) = try bat(wc, type: 0x6d1)
                wc.active.update(id: b) { $0.vy = -0x400; $0.groundKind = grounded ? 3 : 0 }
                let box = try XCTUnwrap(wc.newSprite(type: 0xc12, x: 310, y: 100 + 0xf - 30, layer: 2,
                                                     handler: handler) { s in
                    s.x = 310
                    s.y = 100 + 0xf - 30
                    s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x20, right: 0x40)
                    s.vy = solidVY
                })
                return (wc, b, box)
            }
            let (wa, ba, xa) = try make()
            let r = try slot(wa, ba).hotRect
            let bounce = wa.platformBounce(mover: ba, solid: xa, centre: SpriteSlot.Point(x: 27, y: 31), factor: 0,
                                           rect: r, bounce: false)
            let (wb, bb, xb) = try make()
            var l = LightTable()
            Bat.hit(wb, id: bb, other: xb, lights: &l)
            return (bounce, try slot(wb, bb).hp, try slot(wb, bb).classWord150)
        }
        for (handler, vy, grounded, crushed) in [(SpriteHandler.box, Int32(100), false, true),
                                                 (.statue, 100, false, true), (.box, 0, false, false),
                                                 (.box, 0, true, true), (.platform, 100, false, false)] {
            let (bounce, hp, w150) = try crush(handler, solidVY: vy, grounded: grounded)
            if handler != .platform { XCTAssertEqual(bounce, 2, "\(handler)") }
            XCTAssertEqual([Int(hp), Int(w150)], crushed ? [0, 0x16] : [500, -1], "\(handler) vy \(vy) \(grounded)")
        }
    }

    // MARK: - the crate

    func testKillCrateBatDropArm() throws {
        // `.KillCrate` with p1 0 and p2 1740 (M l. 61292–61320): p3 × `.GenerateSprite(x + 0x16, y + 0x15, 0x6cc, 0x200,
        // 1, layer + 1)` — `.SetupBatSprite` (no draw; record 0x200 reads zeros; not counted at run time), moved by the
        // hot-rect centre (−0x1b, −0x1f), the 24.8 position re-derived; then `+0xa6 = R(10) + 1`, vx, vy = R(700) − 0x15e.
        // The debris draws before it are measured on a twin world whose crate drops a type `.GenerateSprite` makes
        // nothing of (the Blob 0x6c2 — its run-time Setup is BL's): the stream there ends where the Bat's draws begin.
        func crateWorld(_ p2: Int16, seed: Int32) throws -> (SpriteWorld, Int, SpriteSlot) {
            let w = try world()
            let p = Placement(index: 0, flag: 1, byte1: 0, type: 0xc12, p1: 0, p2: p2, p3: 2, p4: 0, y: 200, x: 600)
            w.records = [p]
            var s = try SetupFaces.setup(p, context: SetupFaces.Context(level: w.level, playerX: 0, records: [p])).slot
            let r = s.hotRect
            s.centre = SpriteSlot.Point(x: s.x + r.left + ((r.right - r.left) >> 1),
                                        y: s.y + r.top + ((r.bottom - r.top) >> 1))
            s.hp = 0
            let id = w.active.insert(s)
            w.rng = FastRand(seed: seed)
            return (w, id, s)
        }
        for seed in Int32(1)...12 {
            let (twin, tid, _) = try crateWorld(0x6c2, seed: seed)
            var l = LightTable()
            BoxSprite.killCrate(twin, id: tid, lights: &l, effects: 1)
            XCTAssertEqual(twin.active.sprites.filter { $0.type == 0x6c2 }.count, 0, "no Blob made at run time")
            var r = twin.rng
            let (w, id, crate) = try crateWorld(0x6cc, seed: seed)
            let enemies = w.enemies
            BoxSprite.killCrate(w, id: id, lights: &l, effects: 1)
            let bats = w.active.sprites.filter { $0.type == 0x6cc }.sorted { $0.id < $1.id }
            XCTAssertEqual(bats.count, 2, "p3 2")
            for b in bats {
                let a6 = r.next(10) + 1
                let vx = Int32(r.next(700)) - 0x15e, vy = Int32(r.next(700)) - 0x15e
                XCTAssertEqual([Int(b.counterA6), Int(b.vx), Int(b.vy)], [Int(a6), Int(vx), Int(vy)], "seed \(seed)")
                XCTAssertEqual(b.handler, .bat)
                XCTAssertEqual([Int(b.recordIndex), Int(b.layer), Int(b.hp), Int(b.subtype)],
                               [0x200, 0xb, 500, 7])
                XCTAssertEqual([b.x, b.y], [crate.x + 0x16 - 0x1b, crate.y + 0x15 - 0x1f])
                XCTAssertEqual([Int(b.x256 >> 8), Int(b.y256 >> 8)], [b.x, b.y])
                XCTAssertEqual([b.countedInTotals, b.hasHit, b.keepRecord], [false, true, false])
                XCTAssertEqual(Int(b.gravity), 0, "below 0xc80: no gravity arm")
            }
            XCTAssertEqual(w.rng.seed, r.seed, "seed \(seed): the Bat Setup draws nothing")
            XCTAssertEqual(w.enemies, enemies, "the window is shut at run time")
            if seed == 1 {
                // The dropped bat flies: awake (a6 ≥ 1) it steers from state 7 at once.
                let b = try XCTUnwrap(bats.first)
                frame(w, b.id, TileSolver(world: w))
                XCTAssertEqual(try slot(w, b.id).type, 0x6d1)
            }
        }
        // A 1741 from a crate: the path from record 0x200 (zeros — mode 0, speed 0), direction 1; `+0x188`. Every live
        // record below 0x200 holds a mode-2 path here, so reading any of them would show.
        let w = try world()
        w.records = (0..<0x200).map { Placement(index: $0, flag: 1, byte1: 0, type: 0x6cd, p1: 2, p2: 340, p3: 800,
                                                 p4: 0, y: 100, x: 100) }
        var l = LightTable()
        let g = try XCTUnwrap(BoxSprite.generate(w, type: 0x6cd, x: 100, y: 100, layer: 3, lights: &l, effects: 1))
        let s = try slot(w, g)
        XCTAssertEqual([s.pathMode, s.pathSpeed, s.pathDirection, s.vx, s.vy], [0, 0, 1, 0, 0])
        XCTAssertEqual([s.keepRecord, s.hasHit], [true, true])
        XCTAssertEqual([s.x, s.y, Int(s.recordIndex), Int(s.layer)], [100, 100, 0x200, 0xb])
        // An insect from a crate: face = the 0x744 set's cell 3 (M l. 68219), as at level load.
        let gi = try XCTUnwrap(BoxSprite.generate(w, type: 0x744, x: 100, y: 100, layer: 3, lights: &l, effects: 1))
        XCTAssertEqual(try slot(w, gi).face, f(Bat.insectSet, 3))
        XCTAssertNotNil(try slot(w, gi).siblings.first)
        // A swarm from `.GenerateSprite`: its members made at once (8 of 0x74c, record 0x200), linked.
        let gs = try XCTUnwrap(BoxSprite.generate(w, type: Bat.swarm, x: 100, y: 100, layer: 3, lights: &l, effects: 1))
        let block = try XCTUnwrap(try slot(w, gs).swarm)
        XCTAssertEqual(block.members.compactMap { $0 }.count, 8)
        for m in block.members.compactMap({ $0 }) {
            XCTAssertEqual(try slot(w, m).handler, .swarmMember)
            XCTAssertEqual([Int(try slot(w, m).classTimer), Int(try slot(w, m).classWord150)], [100 + 0x40, 100 + 0x40])
        }
    }
}
