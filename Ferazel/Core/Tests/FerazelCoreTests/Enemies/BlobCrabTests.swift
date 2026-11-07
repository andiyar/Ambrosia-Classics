import XCTest
@testable import FerazelCore

/// BL (docs/plans/2026-10-30-ferazel-phase5.md): the Blob and the Crab — `.InitBlobSprite` (M l. 67661–67668),
/// `.SetupBlobSprite` (M l. 67671–67735), `.HandleDeadBlobSprite` (M l. 67738–67763), `.HandleBlobSprite` (M l.
/// 67766–67978), `.HitBlobSprite` (M l. 67981–68028), `.KillBlob` (M l. 68031–68054), `.HitBlobTileSprite` (M l.
/// 68057–68089); `.InitCrabSprite` (M l. 73957–73967), `.SetupCrabSprite` (M l. 73970–74093), `.HandleCrabSprite` (M l.
/// 74096–74293), `.HandleCrabSegSprite` (M l. 74296–74305), `.HitCrabSprite` (M l. 74308–74321); the Multi Crystal's
/// Blob exception in `.HurtPlayer` (M l. 47989–47995). The Crab is first placed on level 62: its placements here are
/// made by hand. A synthetic 60×30 grid over level 3's header (FG floor along row 20 unless a test says otherwise);
/// every expected draw is re-derived from a copy of the stream at the call site.
final class BlobCrabTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// The grid: FG kind 3 along `floorRow`; BG liquid 200 + `liquid` from `waterRow` down; the player's centre globals
    /// at (`px`, `py`). The Crab tests use level 62's header (its Setup reads the level's own BG for the water flag:
    /// no water cell there outside rows 20…49, enemies-water-cave §7.3).
    private func crabWorld(px: Int16 = 1800, py: Int16 = 600) throws -> SpriteWorld {
        try world(px: px, py: py, level: 62)
    }

    private func world(px: Int16 = 1800, py: Int16 = 600, floorRow: Int? = 20, waterRow: Int? = nil, liquid: Int = 0,
                       level: Int16 = 3) throws -> SpriteWorld {
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
        w.levelIndex = 3
        return w
    }

    /// A placement of `type` (record 0) set up by `SetupFaces` inside the counting window, its centre set as a previous
    /// Cleanup leaves it. A Crab's links (`Entry.children`) are inserted first and the claw's block re-pointed at their
    /// ids, as `SetupFaces.spawnLevelSprites` does.
    private func enemy(_ w: SpriteWorld, type: Int16 = 0x6c2, x: Int = 600, y: Int = 500, p1: Int16 = 0,
                       window: Bool = true) throws -> (id: Int, entry: SetupFaces.Entry, links: [Int]) {
        let p = Placement(index: 0, flag: 1, byte1: 0, type: type, p1: p1, p2: 0, p3: 0, p4: 0, y: Int16(y), x: Int16(x))
        w.records = [p]
        let c = SetupFaces.Context(level: w.level, playerX: Int(w.player.centreX), records: w.records)
        var lights = LightTable()
        w.enemies.window = window
        let e = try SetupFaces.setup(p, context: c, lights: &lights, counting: &w.enemies, rng: &w.rng)
        w.enemies.window = false
        let ids = e.children.map { w.active.insert($0) }
        var s = e.slot
        if var b = s.crabLinks {
            b.links = b.links.map { $0.map { ids[$0] } }
            s.crabLinks = b
        }
        let r = s.hotRect
        s.centre = SpriteSlot.Point(x: s.x + r.left + ((r.right - r.left) >> 1), y: s.y + r.top + ((r.bottom - r.top) >> 1))
        return (w.active.insert(s), e, ids)
    }

    private func slot(_ w: SpriteWorld, _ id: Int) throws -> SpriteSlot { try XCTUnwrap(w.active.record(id: id)) }

    /// The first seed ≥ 1 whose stream makes `pick` true.
    private func seed(_ pick: (inout FastRand) -> Bool) -> Int32 {
        var s: Int32 = 1
        while true {
            var r = FastRand(seed: s)
            if pick(&r) { return s }
            s += 1
        }
    }

    private func f(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }

    private func rect(_ l: Int, _ t: Int, _ r: Int, _ b: Int) -> IdleSprites.Rect {
        IdleSprites.Rect(top: t, left: l, bottom: b, right: r)
    }

    /// A sprite of `type` / `handler` with a 20×20 hot rect over the sprite at `id` (a player shot by default).
    private func other(_ w: SpriteWorld, over id: Int, type: Int16 = 2, handler: SpriteHandler = .playerShot,
                       damage: Int16 = 150, vx: Int32 = 1000, vy: Int32 = -200, body: (inout SpriteSlot) -> Void = { _ in })
        throws -> Int {
        let t = try slot(w, id)
        return try XCTUnwrap(w.newSprite(type: type, x: t.centre.x - 10, y: t.centre.y - 10, layer: 0xb,
                                         handler: handler) { s in
            s.x = t.centre.x - 10
            s.y = t.centre.y - 10
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 20, right: 20)
            s.hp = damage
            s.vx = vx
            s.vy = vy
            body(&s)
        })
    }

    /// A Blob record for the state arm, centre (600, 500), with `body` applied.
    private func blob(_ body: (inout SpriteSlot) -> Void) -> SpriteSlot {
        var s = SpriteSlot(type: 0x6c2, x: 576, y: 478)
        s.handler = .blob
        s.hasHit = true
        s.hp = 700
        s.centre = SpriteSlot.Point(x: 600, y: 500)
        body(&s)
        return s
    }

    private func slime(_ w: SpriteWorld) -> Int { w.particles.records.filter { $0.alive && $0.kind == 0xc9 }.count }

    /// One Blob Handle call by `+0x4c` (the session's dispatch).
    private func frame(_ w: SpriteWorld, _ id: Int, _ solver: TileSolver) {
        switch w.active.record(id: id)?.handler {
        case .deadBlob?: BlobCrab.handleDeadBlob(world: w, id: id)
        case .crab?: BlobCrab.handleCrab(world: w, id: id)
        case .crabSegment?: BlobCrab.handleCrabSegment(world: w, id: id)
        default: BlobCrab.handleBlob(world: w, id: id, solver: solver)
        }
    }

    // MARK: - the Blob

    func testBlobVariantsByType() throws {
        // `.SetupBlobSprite` (M l. 67671–67735) after `.InitSprite`: `+0x84`/`+0x86` 0, layer 8, the Blob Handle, hit
        // and tile callbacks, gravity 0xfa, `+0xc0 = 0`; by TYPE (M l. 67699–67718): 0x6c4 (0x5dc, 0x1000c), 0x6c2 (700,
        // 0), 0x6c3 (0x44c, 0x10004), 0x6c5 (2000, 0x1000f), any other type none — HP 0 (`.InitSprite`), `+0xb8` 0;
        // `+0xc ← +8`, `+0xa ← +6`; SetRect(0xe, 0xc, 0x2f, 0x21); `+0x150 = −1`, `+0xb0 = 6`, `+0xb2 = 0`, `+0x46 = 2`,
        // `+0x14c = 0`; the set 0x6c2 marked and `+0xc0` = its face 0; counted inside the window; the 24.8 position.
        let table: [(Int16, Int16, UInt32)] = [(0x6c2, 700, 0), (0x6c3, 0x44c, 0x10004), (0x6c4, 0x5dc, 0x1000c),
                                               (0x6c5, 2000, 0x1000f), (0x6c6, 0, 0), (0x6c7, 0, 0), (0x6c8, 0, 0),
                                               (0x6c9, 0, 0), (0x6ca, 0, 0), (0x6cb, 0, 0)]
        for (type, hp, mode) in table {
            let w = try world()
            let x = w.rng
            let (_, e, links) = try enemy(w, type: type, x: 600, y: 500)
            let s = e.slot
            XCTAssertEqual(w.rng.seed, x.seed, "\(type): no draw")
            XCTAssertEqual([s.hp], [hp], "\(type)")
            XCTAssertEqual(s.mode, mode, "\(type)")
            XCTAssertEqual([Int(s.layer), Int(s.gravity), Int(s.subtype), Int(s.subState), Int(s.phase)],
                           [8, 0xfa, 6, 0, 2], "\(type)")
            XCTAssertEqual([s.classTimer, s.classWord150, Int32(s.counterA6), s.classWord15c], [0, -1, 0, 0], "\(type)")
            XCTAssertEqual(s.hotRect, rect(0xe, 0xc, 0x2f, 0x21))
            XCTAssertEqual(s.handler, .blob)
            XCTAssertEqual(SpriteHandler.forClass(type: type), .blob, "\(type): the class row")
            XCTAssertEqual([s.hasHit, s.hasTileHit, s.countedInTotals, s.lightOverlay, s.mirrored],
                           [true, true, true, true, false], "\(type)")
            // The write-back flags: the Setup stores none of `+0x188`…`+0x18b`, nor `+0xea`.
            XCTAssertEqual([s.keepRecord, s.noWriteBack189, s.noWriteBack18a, s.keepRecordAtKill, s.killedForGood,
                            s.dead], [false, false, false, false, false, false], "\(type)")
            XCTAssertEqual([Int(s.particleOffsetX), Int(s.particleOffsetY)], [0, 0])
            XCTAssertEqual([s.x, s.y, Int(s.x256 >> 8), Int(s.y256 >> 8)], [600, 500, 600, 500])
            XCTAssertNil(s.crabLinks)
            XCTAssertEqual(links, [])
            XCTAssertEqual(s.face, f(0x6c2, 0))
            XCTAssertEqual(e.source, .setupCached)
            XCTAssertEqual(e.sheet, SetupFaces.Sheet(pict: 0x6c2, count: 16, cellWidth: 0x40, cellHeight: 0x2c,
                                                     columns: 16, clut: 200))
            XCTAssertEqual(w.enemies.live, 1, "\(type): counted (M l. 67728–67731)")
            XCTAssertEqual(CachedFaces.marks(type: type).sets, [0x6c2], "\(type): every type marks the set (M l. 67726)")
        }
        // Outside the counting window: not counted.
        let shut = try world()
        let (_, se, _) = try enemy(shut, window: false)
        XCTAssertFalse(se.slot.countedInTotals)
        XCTAssertEqual(shut.enemies.live, 0)
        // 0x6c6…0x6cb: HP 0 → state 4 on its first frame (M l. 67946 `+0xa4 < 1`); 0x6c2's 700 lives on.
        for (type, dies) in [(Int16(0x6c6), true), (0x6cb, true), (0x6c2, false)] {
            let w = try world()
            let (id, _, _) = try enemy(w, type: type)
            frame(w, id, TileSolver(world: w))
            XCTAssertEqual(try slot(w, id).subtype == 4, dies, "\(type)")
        }
        // HP 1 lives; 0 dies (the `< 1` edge).
        for (hp, dies) in [(Int16(1), false), (0, true), (-5, true)] {
            let w = try world()
            let (id, _, _) = try enemy(w)
            w.active.update(id: id) { $0.hp = hp }
            frame(w, id, TileSolver(world: w))
            XCTAssertEqual(try slot(w, id).subtype == 4, dies, "HP \(hp)")
        }
        // Level 3 sets its four Blobs up with the Blob class, level 4 its one (active or idled at the start).
        for (level, count) in [(3, 4), (4, 1)] {
            let session = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: level)
            let blobs = (session.world.active.sprites + session.world.idle.entries.compactMap { $0?.saved })
                .filter { (0x6c2...0x6cb).contains($0.type) }
            XCTAssertEqual(blobs.map(\.handler), [SpriteHandler](repeating: .blob, count: count), "level \(level)")
            XCTAssertEqual(blobs.map(\.countedInTotals), [Bool](repeating: true, count: count))
        }
    }

    func testBlobStates() throws {
        let w = try world(px: 1800, py: 500)
        func run(_ s0: SpriteSlot) -> SpriteSlot {
            var s = s0
            BlobCrab.blobState(w, id: 0, &s)
            return s
        }
        // State 6 (M l. 67885–67929): `+0x17e = 0`; `+0xa6` counts down while > 0; phase 0 (`+0xb2 == 0`) grows `+0x46`
        // to 9 then `+0xb2 = 1`; phase 1: `+0xa6 == 1` → `+0xb2 = 0`; `+0xa6 == 0` → `+0x46 − 1`, below 3 → 2 and `+0xa6 =
        // 2 + R(14)`.
        var s = blob { $0.subtype = 6; $0.phase = 2; $0.mirrored = true }
        var phases: [Int16] = [], sub: [Int16] = []
        // A stream whose first R(14) differs from R(15) and R(13) (the bound itself is pinned).
        w.rng = FastRand(seed: seed { r in
            var q = r, u = r
            let v = r.next(0xe)
            return v != q.next(0xf) && v != u.next(0xd)
        })
        var x = w.rng
        for _ in 0..<14 {
            s = run(s)
            phases.append(s.phase)
            sub.append(s.subState)
            XCTAssertFalse(s.mirrored, "state 6 faces left (M l. 67886)")
        }
        XCTAssertEqual(phases, [3, 4, 5, 6, 7, 8, 9, 8, 7, 6, 5, 4, 3, 2])
        XCTAssertEqual(sub, [0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1])
        XCTAssertEqual(s.counterA6, 2 + Int16(x.next(0xe)), "the pause 2 + R(14) (M l. 67898)")
        XCTAssertEqual(w.rng.seed, x.seed, "one draw in 14 frames")
        // The pause counts down; at `+0xa6 == 1` the grow phase returns (no phase step that frame); the next frame
        // `+0xa6` 0 and `+0x46` 3.
        s.counterA6 = 3
        s = run(s)
        XCTAssertEqual([Int(s.counterA6), Int(s.subState), Int(s.phase)], [2, 1, 2])
        s = run(s)
        XCTAssertEqual([Int(s.counterA6), Int(s.subState), Int(s.phase)], [1, 0, 2])
        s = run(s)
        XCTAssertEqual([Int(s.counterA6), Int(s.subState), Int(s.phase)], [0, 0, 3])
        // `+0xa6` at 0 in phase 0 stays 0 (the `0 < +0xa6` guard).
        XCTAssertEqual(run(s).counterA6, 0)
        // The trigger (M l. 67908–67922): |P.x − c.x| < 200, |P.y − c.y| < 220, P.y > c.y − 128 and `+0xa6 == 1` (after
        // the count-down) → `+0xa6 = 0`, state 2. Centre (600, 500).
        for (dx, dy, a6, fires) in [(0, 0, Int16(2), true), (199, 0, 2, true), (200, 0, 2, false), (-199, 0, 2, true),
                                    (-200, 0, 2, false), (0, 219, 2, true), (0, 220, 2, false), (0, -127, 2, true),
                                    (0, -128, 2, false), (0, -219, 2, false), (0, 0, 3, false), (0, 0, 1, false),
                                    (199, 219, 2, true)] {
            w.player.centreX = Int16(600 + dx)
            w.player.centreY = Int16(500 + dy)
            let t = run(blob { $0.subtype = 6; $0.subState = 1; $0.counterA6 = a6; $0.phase = 5 })
            XCTAssertEqual(t.subtype, fires ? 2 : 6, "(\(dx), \(dy)) a6 \(a6)")
            XCTAssertEqual(t.counterA6, fires ? 0 : (a6 > 0 ? a6 - 1 : 0), "(\(dx), \(dy)) a6 \(a6)")
        }
        // The brake at the end of state 6 (M l. 67924–67928): vx = (int)(vx · 0.8), then vx < 100 (signed) → 0.
        w.player.centreX = 1800
        w.player.centreY = 500
        for (vx, out) in [(Int32(125), Int32(100)), (124, 0), (1000, 800), (-1000, 0), (-1, 0), (0, 0)] {
            XCTAssertEqual(run(blob { $0.subtype = 6; $0.vx = vx }).vx, out, "vx \(vx)")
        }
        // State 2, the lunge (M l. 67835–67883), player to the right (a = +400): `+0x46` steps 0 → 20; at `+0x46 == 4`
        // (before the step) slimemove 607 vol 0x55 at 50000 + R(30000); 8…13 → vx + 400; 14…19 → vx − 400; at 20 →
        // `+0x46 = 0`, `+0xa6 = R(20)`, R(100) > 0x5c → state 6.
        w.player.centreX = 900
        let stay = seed { r in _ = r.next(30000); _ = r.next(20); return r.next(100) == 0x5c }
        w.rng = FastRand(seed: stay)
        x = w.rng
        w.player.cues = []
        s = blob { $0.subtype = 2; $0.classTimer = 1; $0.phase = 0 }
        var vxs: [Int32] = [], cueFrames: [Int] = []
        for k in 1...20 {
            let n = w.player.cues.count
            s = run(s)
            if w.player.cues.count != n { cueFrames.append(k) }
            vxs.append(s.vx)
            XCTAssertEqual(s.classTimer, 1, "side: the player is right")
        }
        XCTAssertEqual(vxs, [0, 0, 0, 0, 0, 0, 0, 400, 800, 1200, 1600, 2000, 2400, 2000, 1600, 1200, 800, 400, 0, 0])
        XCTAssertEqual(cueFrames, [5], "slimemove on the frame entered at `+0x46 == 4` only")
        let rate = Int32(x.next(30000)) + 50000
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDPitched, snd: 607, priority: 1, volume: 0x55,
                                                 position: s.centre, rate: rate)])
        XCTAssertEqual([Int(s.phase), Int(s.counterA6), Int(s.subtype)], [0, Int(x.next(20)), 2])
        _ = x.next(100)
        XCTAssertEqual(w.rng.seed, x.seed, "three draws in the lunge")
        // R(100) = 0x5d → state 6.
        let back = seed { r in _ = r.next(20); return r.next(100) == 0x5d }
        w.rng = FastRand(seed: back)
        s = run(blob { $0.subtype = 2; $0.classTimer = 1; $0.phase = 19 })
        XCTAssertEqual([Int(s.phase), Int(s.subtype)], [0, 6])
        // A rest `+0xa6 > 0`: `+0xa6 − 1`, no step, no vx change.
        s = run(blob { $0.subtype = 2; $0.classTimer = 1; $0.phase = 9; $0.counterA6 = 3; $0.vx = 77 })
        XCTAssertEqual([Int(s.counterA6), Int(s.phase), Int(s.vx), Int(s.subtype)], [2, 9, 77, 2])
        // A lunge entered past `+0x46 == 4` plays no sound; to the left a = −400.
        w.player.cues = []
        w.player.centreX = 300
        s = blob { $0.subtype = 2; $0.classTimer = 0; $0.phase = 7 }
        s = run(s)
        XCTAssertEqual([Int(s.phase), Int(s.vx)], [8, -400])
        XCTAssertEqual(w.player.cues, [])
        // The side test (M l. 67836–67845): side = P.x > c.x; side ≠ `+0x14c`, or vx against it → state 5 (the
        // frame's lunge still runs), `+0x14c = side`. P.x == c.x is side 0 with a = −400.
        for (px, side0, vx, brakes) in [(Int16(601), Int32(1), Int32(0), false), (601, 0, 0, true), (601, 1, -1, true),
                                        (599, 0, 1, true), (599, 0, -1, false), (599, 1, 0, true), (600, 0, 0, false),
                                        (600, 1, 0, true)] {
            w.player.centreX = px
            let t = run(blob { $0.subtype = 2; $0.classTimer = side0; $0.phase = 9; $0.vx = vx })
            XCTAssertEqual(t.subtype, brakes ? 5 : 2, "P.x \(px) side \(side0) vx \(vx)")
            XCTAssertEqual(t.classTimer, px > 600 ? 1 : 0)
            XCTAssertEqual(t.vx, vx + (px > 600 ? 400 : -400), "P.x \(px): the lunge step at `+0x46` 10")
        }
        // State 5, the brake (M l. 67930–67944): vx × 0.8, `+0x46` cycles 0…19; |vx| < 200 → 0 and state 2.
        for (vx, out, state) in [(Int32(1000), Int32(800), Int16(5)), (250, 200, 5), (249, 0, 2), (-249, 0, 2),
                                 (-250, -200, 5), (1001, 800, 5), (-1001, -800, 5)] {
            let t = run(blob { $0.subtype = 5; $0.vx = vx; $0.phase = 3 })
            XCTAssertEqual([t.vx, Int32(t.subtype), Int32(t.phase)], [out, Int32(state), 4], "vx \(vx)")
        }
        XCTAssertEqual(run(blob { $0.subtype = 5; $0.vx = 5000; $0.phase = 19 }).phase, 0)
        XCTAssertEqual(run(blob { $0.subtype = 5; $0.vx = 5000; $0.phase = 18 }).phase, 19)
        // The Handle (M l. 67792–67797, 67967–67974): facing `+0x17e` = c.x < P.x, kept when equal (state 5 keeps it);
        // the face `+0x46 >> 1`, in state 4 `10 + (+0x46 >> 2)`.
        for (px, before, after) in [(Int16(2000), false, true), (100, true, false), (-1, true, false)] {
            let v = try world(px: px)
            let (id, _, _) = try enemy(v)
            let solver = TileSolver(world: v)
            v.active.update(id: id) { $0.subtype = 5; $0.vx = 5000; $0.mirrored = before; $0.phase = 6 }
            frame(v, id, solver)
            let t = try slot(v, id)
            XCTAssertEqual(t.mirrored, after, "P.x \(px)")
            XCTAssertEqual(t.face, f(0x6c2, 7 >> 1))
            if px == -1 {
                let c = t.centre.x
                v.player.centreX = Int16(c)
                v.active.update(id: id) { $0.mirrored = true; $0.subtype = 5; $0.vx = 5000 }
                frame(v, id, solver)
                XCTAssertTrue(try slot(v, id).mirrored, "equal centres: kept")
                v.active.update(id: id) { $0.mirrored = false; $0.subtype = 5; $0.vx = 5000 }
                v.player.centreX = Int16(try slot(v, id).centre.x)
                frame(v, id, solver)
                XCTAssertFalse(try slot(v, id).mirrored, "equal centres: kept (false)")
            }
        }
        let d = try world()
        let (did, _, _) = try enemy(d)
        d.active.update(id: did) { $0.subtype = 4; $0.phase = 12 }
        frame(d, did, TileSolver(world: d))
        XCTAssertEqual(try slot(d, did).face, f(0x6c2, 10 + (13 >> 2)))
        // Water (M l. 67950–67966) after the gravity call: fully under kind 0, or any kind > 0 — kind 3 heals 4 below 500;
        // kind 2 with `+0x116 == 0` → `+0x116 = 0x13`, HP − 100, `+0xaa = 0x11`, snd 701 vol 0x55; kinds 0 / 1 nothing.
        // No self-buoyancy: the Blob sinks.
        for (liquid, hp0, hp1, hurt) in [(3, Int16(496), Int16(500), false), (3, 497, 501, false), (3, 500, 500, false),
                                         (2, 700, 600, true), (0, 700, 700, false), (1, 700, 700, false)] {
            let v = try world(floorRow: nil, waterRow: 10, liquid: liquid)
            let (id, _, _) = try enemy(v, x: 600, y: 500)
            let solver = TileSolver(world: v)
            v.active.update(id: id) { $0.hp = 10000; $0.subtype = 6 }
            for _ in 0..<12 { frame(v, id, solver) }
            XCTAssertEqual(try slot(v, id).waterRow, 1, "kind \(liquid): fully submerged")
            let y0 = try slot(v, id).y
            v.active.update(id: id) { $0.hp = hp0; $0.invulnerable = 0 }
            v.player.cues = []
            frame(v, id, solver)
            let t = try slot(v, id)
            XCTAssertEqual(t.hp, hp1, "kind \(liquid) HP \(hp0)")
            XCTAssertGreaterThan(t.y, y0, "kind \(liquid): sinking")
            if hurt {
                XCTAssertEqual([Int(t.invulnerable), Int(t.flash)], [0x13, 0x11])
                XCTAssertEqual(v.player.cues, [PlayerCue(call: .threeD, snd: 701, priority: 1, volume: 0x55,
                                                         position: t.centre)])
                v.player.cues = []
                frame(v, id, solver)
                XCTAssertEqual(try slot(v, id).hp, 600, "`+0x116` > 0: no second hurt")
            } else {
                XCTAssertEqual(v.player.cues, [])
            }
        }
    }

    func testBlobDeadSprite() throws {
        let w = try world()
        func run(_ s0: SpriteSlot) -> SpriteSlot {
            var s = s0
            BlobCrab.blobState(w, id: 0, &s)
            return s
        }
        // State 4 (M l. 67800–67833): `+0x14c` + 1; vx × 0.8, |vx| < 200 → 0; `+0x46` + 1; above 19 → 20 and, with vy 0
        // or `+0xcd` set, the Handle becomes `.HandleDeadBlobSprite`; `+0x5c = 0` either way.
        var s = run(blob { $0.subtype = 4; $0.phase = 18; $0.vx = 1000 })
        XCTAssertEqual([Int(s.phase), Int(s.vx), Int(s.classTimer)], [19, 800, 1])
        XCTAssertEqual([s.handler == .blob, s.hasHit], [true, true])
        s = run(s)
        XCTAssertEqual([Int(s.phase), Int(s.vx), Int(s.classTimer)], [20, 640, 2])
        XCTAssertEqual([s.handler == .deadBlob, s.hasHit], [true, false])
        for (vy, on, dead) in [(Int32(50), UInt8(0), false), (50, 1, true), (0, 0, true), (-1, 0, false)] {
            let t = run(blob { $0.subtype = 4; $0.phase = 25; $0.vy = vy; $0.onSprite = on })
            XCTAssertEqual([Int(t.phase), t.hasHit ? 1 : 0], [20, 0])
            XCTAssertEqual(t.handler, dead ? .deadBlob : .blob, "vy \(vy) +0xcd \(on)")
        }
        for (vx, out) in [(Int32(250), Int32(200)), (249, 0), (-249, 0), (-250, -200)] {
            XCTAssertEqual(run(blob { $0.subtype = 4; $0.vx = vx }).vx, out, "vx \(vx)")
        }
        // The entry block guarded by `+0x14c == −1` (M l. 67801–67814): no Blob routine stores −1 there (Setup 0, the
        // lunge 0 / 1, this arm + 1) — dead in play, transcribed as written: `+0x46 = 0`, score + 200, crawler death 703
        // (vol 0x100), the record's flag cleared; then the arm's own steps.
        w.records = [Placement(index: 0, flag: 1, byte1: 0, type: 0x6c2, p1: 0, p2: 0, p3: 0, p4: 0, y: 0, x: 0)]
        w.globals.score = 0
        w.player.cues = []
        s = run(blob { $0.subtype = 4; $0.phase = 9; $0.classTimer = -1; $0.recordIndex = 0 })
        XCTAssertEqual([Int(s.phase), Int(s.classTimer), Int(w.globals.score), Int(w.records[0].flag)], [1, 0, 200, 0])
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeD, snd: 703, priority: 1, volume: 0x100, position: s.centre)])
        // `+0x14c` −2 or 0: no entry block.
        for t0 in [Int32(-2), 0] {
            w.globals.score = 0
            let t = run(blob { $0.subtype = 4; $0.phase = 9; $0.classTimer = t0 })
            XCTAssertEqual([Int(t.phase), Int(w.globals.score)], [10, 0], "+0x14c \(t0)")
        }
        // The whole death through the Handle: HP 0 → state 4 at the frame's end; the next frames `+0x46` from where it
        // was (not reset), faces 10 + (`+0x46` >> 2); on the floor at `+0x46` 20 → the dead Handle.
        let v = try world()
        let (id, _, _) = try enemy(v)
        let solver = TileSolver(world: v)
        for _ in 0..<40 { frame(v, id, solver) }
        XCTAssertNotEqual(try slot(v, id).groundKind, 0, "settled")
        v.active.update(id: id) { $0.hp = 0; $0.subtype = 6; $0.phase = 4; $0.subState = 0; $0.counterA6 = 0 }
        frame(v, id, solver)
        XCTAssertEqual([Int(try slot(v, id).subtype), Int(try slot(v, id).phase)], [4, 5])
        var n = 0
        while try slot(v, id).handler == .blob && n < 30 {
            frame(v, id, solver)
            n += 1
            let t = try slot(v, id)
            XCTAssertEqual(t.face, f(0x6c2, 10 + Int(t.phase >> 2)))
        }
        // 5 → 20 in 15 frames; the resting Blob's vy reads 0 and 250 on alternate frames (gravity, then the floor's
        // separation), and `+0xcd` follows `+0xce` a frame late, so the dead Handle comes on the frame `+0x46` reaches 20
        // or the next (held at 20).
        XCTAssertTrue((15...16).contains(n), "\(n) frames")
        var t = try slot(v, id)
        XCTAssertEqual([t.handler == .deadBlob, t.hasHit, t.dead], [true, false, false])
        // `.HandleDeadBlobSprite` (M l. 67738–67763): `+0x15c` + 1, `+0xaa = 0`, `+0xea = 1`; > 0x3c → `+0x88 = 0`; >
        // 0x42 → `+0xb8 = 0xb0001`; > 0x48 → 0xb0000; > 0x4e → 0xb0002; > 0x54 → `.KillBlob`, `+0xc0 = 0`. No motion.
        v.active.update(id: id) { $0.mode = 0x1000c; $0.flash = 5; $0.vx = 300; $0.vy = 300 }
        v.globals.score = 0
        v.enemies.live = 4
        let pos = (t.x, t.y, t.x256, t.y256)
        var trace: [(n: Int32, lit: Bool, mode: UInt32, dead: Bool)] = []
        for _ in 0..<85 {
            frame(v, id, solver)
            t = try slot(v, id)
            trace.append((t.classWord15c, t.lightOverlay, t.mode, t.dead))
            XCTAssertEqual([Int(t.flash)], [0])
            XCTAssertTrue(t.killedForGood, "`+0xea = 1` every frame (M l. 67745)")
        }
        XCTAssertEqual(trace.map { $0.n }, (1...85).map { Int32($0) })
        XCTAssertEqual(trace.map { $0.lit }, (1...85).map { $0 <= 60 })
        XCTAssertEqual(trace.map { $0.mode }, (1...85).map { (k: Int) -> UInt32 in
            k > 78 ? 0xb0002 : k > 72 ? 0xb0000 : k > 66 ? 0xb0001 : 0x1000c
        })
        XCTAssertEqual(trace.map { $0.dead }, (1...85).map { $0 > 84 })
        XCTAssertEqual([t.x, t.y], [pos.0, pos.1])
        XCTAssertEqual([t.x256, t.y256, t.vx, t.vy], [pos.2, pos.3, 300, 300])
        XCTAssertNil(t.face)
        XCTAssertEqual(trace[83].dead, false, "84: alive")
        // `.KillBlob` (M l. 68031–68054): score + 250 while `+0xe9 == 0`; counted → live − 1, stat + 1; `+0xe9 = +0xea = 1`.
        XCTAssertEqual([Int(v.globals.score), Int(v.enemies.live), Int(v.globals.achieved[0][3])], [250, 3, 1])
        frame(v, id, solver)
        XCTAssertEqual([Int(v.globals.score), Int(v.enemies.live), Int(v.globals.achieved[0][3])], [250, 3, 1],
                       "a second Kill scores and counts nothing")
        // An uncounted Blob: the score, no count.
        let u = try world()
        let (uid, _, _) = try enemy(u, window: false)
        u.active.update(id: uid) { $0.handler = .deadBlob; $0.classWord15c = 0x54 }
        u.enemies.live = 2
        frame(u, uid, TileSolver(world: u))
        XCTAssertEqual([Int(u.globals.score), Int(u.enemies.live), Int(u.globals.achieved[0][3])], [250, 2, 0])
        XCTAssertEqual([try slot(u, uid).dead, try slot(u, uid).killedForGood], [true, true])
        // The session's Handle dispatch by `+0x4c` (`FerazelSession`'s handle pass): a live Blob and a dead puddle, kept
        // active (`+0x1c6` 0), each advance one step a frame.
        let sess = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 3, seed: 1)
        let sw = sess.world
        let pl = try slot(sw, try XCTUnwrap(sw.playerID))
        var nb = SpriteSlot(type: 0x6c2, x: pl.x + 200, y: pl.y - 50)
        nb.oldPosition = SpriteSlot.Point(x: nb.x, y: nb.y)
        var none = EnemyCounting()
        BlobCrab.setupBlob(&nb, counting: &none)
        nb.mayIdle = false
        var nd = nb
        nd.handler = .deadBlob
        nd.hasHit = false
        let nbid = sw.active.insert(nb), ndid = sw.active.insert(nd)
        _ = sess.step(keys: KeyState())
        XCTAssertEqual([Int(try slot(sw, nbid).phase), try slot(sw, nbid).face?.index ?? -1], [3, 1], "the Blob Handle ran")
        XCTAssertEqual([Int(try slot(sw, ndid).classWord15c), try slot(sw, ndid).killedForGood ? 1 : 0], [1, 1],
                       "the dead Blob Handle ran")
    }

    func testBlobAttackerKeepsMultiCrystal() throws {
        // `.HurtPlayer` step 3 (M l. 47989–47995): the crystal arm runs only when the attacker's `+0x4c` is not
        // `PTR_PTR_100a04c0` — `.HandleBlobSprite` (TOC 0x100a04c0, `Smite`'s list) — so a Blob's hurt costs no Multi
        // Crystal; the dead Blob's Handle (`PTR_PTR_100a0c58`) is another pointer.
        func hurt(_ handler: SpriteHandler, hp: Int16 = 1, idled: Bool = false) throws
            -> (landed: Bool, w: SpriteWorld, before: Set<Int>) {
            let w = try world()
            var fg = [UInt16](repeating: 0, count: 60 * 30)
            for c in 0..<60 { fg[12 * 60 + c] = 4 }
            w.tiles = TileGrid(fg: TileMap(width: 60, height: 30, cells: fg),
                               bg: TileMap(width: 60, height: 30, cells: [UInt16](repeating: 0, count: 60 * 30)),
                               fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
            let pid = try XCTUnwrap(Player.spawn(world: w, x: 100, y: 400 - 0x55))
            var inv = [InventorySlot](repeating: .empty, count: GameGlobals.inventorySlots)
            inv[0] = InventorySlot(id: 0x13, count: 2, field4: -1, field6: 0, isSpell: 0)
            w.globals.inventory = inv
            w.globals.maxHealth = 0x230
            w.globals.health = 0x230
            w.active.update(id: pid) { $0.hp = 0x230; $0.invulnerable = 0 }
            var a = SpriteSlot(type: 0x6c2, x: 0, y: 0)
            a.handler = handler
            a.hp = hp
            a.handleCleared = idled
            let aid = w.active.insert(a)
            let before = Set(w.active.sprites.map(\.id))
            w.player.cues = []
            let landed = HurtPlayer.hurt(w, player: pid, attacker: aid, damage: 0x38, blood: false, invulnerable: 0x3c,
                                         coins: 0)
            return (landed, w, before)
        }
        let (landed, w, before) = try hurt(.blob)
        XCTAssertTrue(landed, "the hurt lands")
        XCTAssertEqual(w.active.record(id: w.playerID!)?.hp, 0x230 - 0x38)
        XCTAssertEqual(w.player.countdown073c, 0, "no crystal loss timer")
        XCTAssertFalse(w.player.cues.contains { $0.snd == 507 }, "no snd 507")
        XCTAssertEqual(w.statusBar.flashes.item, 0)
        XCTAssertEqual(w.active.sprites.filter { !before.contains($0.id) }.map(\.type), [], "no shards")
        XCTAssertEqual(w.globals.inventory[0].count, 2)
        // Every other attacker with the crystal: the arm (a Frog, a Crawler, a Walker).
        for h in [SpriteHandler.frog, .crawler, .walker] {
            let (l, v, b) = try hurt(h)
            XCTAssertTrue(l)
            XCTAssertEqual(v.player.countdown073c, 0xf, "\(h)")
            XCTAssertEqual(v.active.sprites.filter { !b.contains($0.id) }.map(\.type), [0x4bf, 0x4c0, 0x4c1, 0x4c2])
        }
        // The dead Blob: HP < 1 stops the hurt at step 1; with HP (hypothetical) its Handle is not the Blob's.
        let (dl, _, _) = try hurt(.deadBlob, hp: 0)
        XCTAssertFalse(dl)
        let (dh, dv, db) = try hurt(.deadBlob, hp: 1)
        XCTAssertTrue(dh)
        XCTAssertEqual(dv.player.countdown073c, 0xf)
        XCTAssertEqual(dv.active.sprites.filter { !db.contains($0.id) }.count, 4)
        // An idled Blob record (Handle 0): not the Blob's pointer either.
        let (il, iv, _) = try hurt(.blob, idled: true)
        XCTAssertTrue(il)
        XCTAssertEqual(iv.player.countdown073c, 0xf)
    }

    // MARK: - the Crab

    func testCrabAims() throws {
        // `.SetupCrabSprite` (M l. 73970–74093): `+0x84`/`+0x86` 0, layer 8, the Crab Handle and hit, no tile callback,
        // HP 1000, gravity 0, `+0xc ← +8`, `+0xa ← +6`, SetRect(0x18, 0x18, 0x4c, 0x4c), `+0x150 = −1`, `+0xb0 = 0`,
        // `+0xb2 = 0`, `+0x46 = 2`, both caches marked, `+0xc0 = 0`, `+0x16c` = `.IsWaterTile(.GetBGTile(x >> 5, y >> 5))`;
        // types < 0x767: reach `+0x14c` = the live record's p1 (0 → 100), anchor `+0x150`/`+0x154` = (x, y), the link
        // block (n = min((reach + 23) / 24, 12) links 0x767 at (x + 30, y + 30), layer − 1, record 0x1ff), the angle by
        // type, `+0xa6 = 0`, `+0xb0 = 0`, `+0x15c = 0`. Not counted, no write-back flag.
        for (type, angle) in [(Int16(0x762), Int16(0)), (0x763, 180), (0x764, 90), (0x765, 270), (0x766, 90)] {
            let w = try crabWorld()
            let x = w.rng
            let (id, e, links) = try enemy(w, type: type, x: 7620, y: 1655, p1: 0)
            let s = try slot(w, id)
            XCTAssertEqual(w.rng.seed, x.seed, "no draw")
            XCTAssertEqual(s.phase, angle, "\(type)")
            XCTAssertEqual(SpriteHandler.forClass(type: type), .crab)
            XCTAssertEqual([Int(s.layer), Int(s.hp), Int(s.gravity), Int(s.subtype), Int(s.subState),
                            Int(s.counterA6)], [8, 1000, 0, 0, 0, 0])
            XCTAssertEqual([s.classTimer, s.classWord150, s.classWord154, s.classWord15c, s.classWord16c],
                           [100, 7620, 1655, 0, 0])
            XCTAssertEqual(s.hotRect, rect(0x18, 0x18, 0x4c, 0x4c))
            XCTAssertEqual(s.handler, .crab)
            XCTAssertEqual([s.hasHit, s.hasTileHit, s.countedInTotals, s.mirrored], [true, false, false, false])
            XCTAssertEqual([s.keepRecord, s.noWriteBack189, s.noWriteBack18a, s.keepRecordAtKill, s.killedForGood],
                           [false, false, false, false, false])
            XCTAssertEqual([s.x, s.y, Int(s.x256 >> 8), Int(s.y256 >> 8)], [7620, 1655, 7620, 1655])
            XCTAssertEqual(s.mode, 0)
            XCTAssertEqual(w.enemies.live, 0, "the Crab sets no `+0x1b5`")
            XCTAssertEqual(e.source, .handle)
            XCTAssertEqual(e.sheet, SetupFaces.Sheet(pict: 0x762, count: 6, cellWidth: 100, cellHeight: 100, columns: 6,
                                                     clut: 200))
            XCTAssertEqual(CachedFaces.marks(type: type).sets, [0x762])
            XCTAssertEqual(CachedFaces.marks(type: type).singles, [0x767])
            // Reach 100 → (123) / 24 = 5 links; the block holds 12 pointers, the rest 0.
            let b = try XCTUnwrap(s.crabLinks)
            XCTAssertEqual(b.count, 5)
            XCTAssertEqual(b.links, links.map { Optional($0) } + [Int?](repeating: nil, count: 7))
            for l in links {
                let k = try slot(w, l)
                XCTAssertEqual(k.type, 0x767)
                XCTAssertEqual([k.x, k.y, Int(k.x256 >> 8), Int(k.y256 >> 8)], [7650, 1685, 7650, 1685])
                XCTAssertEqual([Int(k.layer), Int(k.hp), Int(k.gravity), Int(k.phase), Int(k.recordIndex)],
                               [8, 1000, 0, 2, 0x1ff], "the Setup's layer 8 replaces the 7 passed")
                XCTAssertEqual(k.handler, .crabSegment)
                XCTAssertEqual([k.hasHit, k.hasTileHit, k.countedInTotals], [false, false, false])
                XCTAssertEqual(k.hotRect, rect(0, 0, 0, 0))
                XCTAssertEqual([k.classWord150, k.classTimer, k.classWord16c], [-1, 0, 0])
                XCTAssertEqual(k.mode, 0)
                XCTAssertNil(k.crabLinks)
                XCTAssertNil(k.face)
            }
            XCTAssertEqual(e.children.count, 5)
        }
        XCTAssertEqual(SpriteHandler.forClass(type: 0x767), .crab, "the class row; the Setup installs the link Handle")
        // The link count n = min((reach + 23) / 24, 12): reach 1 → 1; 24 → 1; 25 → 2; 264 → 11; 265 → 12; 300 → 12; p1
        // 0 → reach 100 → 5; p1 50 → 3.
        for (p1, reach, n) in [(Int16(1), Int32(1), Int16(1)), (24, 24, 1), (25, 25, 2), (264, 264, 11),
                               (265, 265, 12), (300, 300, 12), (0, 100, 5), (50, 50, 3)] {
            let w = try crabWorld()
            let (id, _, links) = try enemy(w, type: 0x764, p1: p1)
            let s = try slot(w, id)
            XCTAssertEqual([s.classTimer, Int32(s.crabLinks?.count ?? -1), Int32(links.count)],
                           [reach, Int32(n), Int32(n)], "p1 \(p1)")
        }
        // Types 0x768…0x76b take the 0x767 test's other side with no block and a claw Handle: refused (unplaced).
        for t: Int16 in [0x768, 0x76b] {
            XCTAssertThrowsError(try enemy(try crabWorld(), type: t)) { e in
                XCTAssertEqual(e as? SetupFaces.Error, .notTranscribed(type: t))
            }
        }
        // In water (`+0x16c = 1`): the claw and every link `+0xb8 = 0x90000`; each link's own `+0x16c` reads its own
        // cell (x + 30, y + 30).
        var lake = SpriteSlot(type: 0x764, x: 100, y: 100)
        lake.oldPosition = SpriteSlot.Point(x: 100, y: 100)
        var made: [SpriteSlot] = []
        let wet: (Int, Int) -> Bool = { col, row in col == 3 && row == 3 }
        BlobCrab.setupCrab(&lake, reach: 48, water: wet) { x, y, layer, inWater in
            made.append(BlobCrab.makeLink(x: x, y: y, layer: layer, clawInWater: inWater, water: wet))
            return made.count - 1
        }
        XCTAssertEqual([lake.classWord16c, Int32(lake.mode)], [1, 0x90000])
        XCTAssertEqual(made.map(\.mode), [0x90000, 0x90000])
        XCTAssertEqual(made.map(\.classWord16c), [0, 0], "links at (130, 130): cell (4, 4)")
        var dry = SpriteSlot(type: 0x764, x: 100, y: 100)
        dry.oldPosition = SpriteSlot.Point(x: 100, y: 100)
        var dryMade: [SpriteSlot] = []
        let wetLinks: (Int, Int) -> Bool = { col, row in col == 4 && row == 4 }
        BlobCrab.setupCrab(&dry, reach: 48, water: wetLinks) { x, y, layer, inWater in
            dryMade.append(BlobCrab.makeLink(x: x, y: y, layer: layer, clawInWater: inWater, water: wetLinks))
            return dryMade.count - 1
        }
        XCTAssertEqual([dry.classWord16c, Int32(dry.mode)], [0, 0])
        XCTAssertEqual(dryMade.map(\.mode), [0, 0])
        XCTAssertEqual(dryMade.map(\.classWord16c), [1, 1])

        // Aiming (state 0, M l. 74185–74272). Allowed directions by type: 0x762 d ≤ 8 or d ≥ 28; 0x763 9 < d < 27; 0x764
        // 0 < d < 18; 0x765 18 < d < 36; 0x766 any; every other type none.
        func allowed(_ t: Int16) -> [Int] { (0..<40).filter { BlobCrab.crabAllowed(type: t, direction: $0) } }
        XCTAssertEqual(allowed(0x762), Array(0...8) + Array(28...39))
        XCTAssertEqual(allowed(0x763), Array(10...26))
        XCTAssertEqual(allowed(0x764), Array(1...17))
        XCTAssertEqual(allowed(0x765), Array(19...35))
        XCTAssertEqual(allowed(0x766), Array(0..<40))
        XCTAssertEqual(allowed(0x767), [])
        let w = try crabWorld(px: 5000, py: 5000)
        func aim(_ type: Int16, angle: Int16, d: Int, a6: Int16 = 5) -> SpriteSlot {
            var s = SpriteSlot(type: type, x: 576, y: 476)
            s.handler = .crab
            s.phase = angle
            s.counterA6 = a6
            s.classTimer = 100
            s.centre = SpriteSlot.Point(x: 626, y: 526)
            BlobCrab.aim(w, &s, direction: d)
            return s
        }
        // 5° a frame toward T = 10·d the short way; the exact half turn (|a − T| = 180) goes the other way; wrap 0…359.
        for (angle, d, out) in [(Int16(90), 9, Int16(90)), (85, 9, 90), (90, 0, 85), (0, 35, 355), (355, 0, 0),
                                (10, 19, 5), (190, 1, 195), (100, 27, 105), (270, 9, 275), (5, 0, 0), (2, 35, 357)] {
            let s = aim(0x766, angle: angle, d: d)
            XCTAssertEqual([s.phase, s.rotation], [out, out], "angle \(angle) → d \(d)")
            XCTAssertEqual(s.face, f(0x762, 0))
            XCTAssertFalse(s.mirrored)
        }
        // A forbidden direction leaves the angle: 0x764 at d 0 and 18; d 1 and 17 step.
        XCTAssertEqual([aim(0x764, angle: 90, d: 0).phase, aim(0x764, angle: 90, d: 18).phase,
                        aim(0x764, angle: 90, d: 1).phase, aim(0x764, angle: 90, d: 17).phase], [90, 90, 85, 95])
        // 0x763: `+0x17e = 1`, rotation = (angle + 180) mod 360.
        let t3 = aim(0x763, angle: 200, d: 20)
        XCTAssertEqual([Int(t3.phase), Int(t3.rotation), t3.mirrored ? 1 : 0], [200, 20, 1])
        XCTAssertEqual(aim(0x763, angle: 175, d: 18).rotation, 0, "180 + 180 → 0")
        // The strike test: `+0xa6 < 1`, angle == 10·d (even a forbidden d), `.PEDistance(P.x − c.x, P.y − c.y) ≤ reach
        // + 54` → state 1, `+0xa6 = 0`; else `+0xa6 − 1` while ≥ 1. Centre (626, 526), reach 100: 154.
        for (dx, dy, fires) in [(154, 0, true), (155, 0, false), (-154, 0, true), (150, 12, true), (150, 15, false),
                                (0, -154, true), (12, 150, true), (13, 151, false)] {
            w.player.centreX = Int16(626 + dx)
            w.player.centreY = Int16(526 + dy)
            let s = aim(0x766, angle: 90, d: 9, a6: 0)
            XCTAssertEqual([Int(s.subtype), Int(s.counterA6)], [fires ? 1 : 0, 0], "(\(dx), \(dy))")
        }
        w.player.centreX = 626
        w.player.centreY = 526
        XCTAssertEqual([Int(aim(0x766, angle: 90, d: 9, a6: 1).subtype), Int(aim(0x766, angle: 90, d: 9, a6: 1).counterA6)],
                       [0, 0], "cooling down: `+0xa6` 1 → 0, no strike")
        XCTAssertEqual(aim(0x766, angle: 90, d: 9, a6: -3).subtype, 1, "`+0xa6 < 1`")
        XCTAssertEqual(aim(0x766, angle: 85, d: 9, a6: 0).subtype, 1, "stepped onto T this frame")
        XCTAssertEqual([Int(aim(0x766, angle: 80, d: 9, a6: 0).subtype), Int(aim(0x766, angle: 80, d: 9, a6: 0).counterA6)],
                       [0, 0], "off T: no strike, `+0xa6` stays 0")
        XCTAssertEqual(aim(0x764, angle: 0, d: 0, a6: 0).subtype, 1, "forbidden d 0, angle already 0: strikes")
        // Through the Handle: d from the claw's centre to the player sprite's (`.FindDesiredDirectionGeneric`, 0 right,
        // 9 up, 18 left, 27 down). A player straight above a 0x764 at angle 90: no step, strike in range.
        let v = try crabWorld()
        let (cid, _, _) = try enemy(v, type: 0x764, x: 600, y: 500)
        let c = try slot(v, cid).centre
        var pl = SpriteSlot(type: 0x80, x: c.x, y: c.y - 100)
        pl.centre = SpriteSlot.Point(x: c.x, y: c.y - 100)
        v.playerID = v.active.insert(pl)
        v.player.centreX = Int16(c.x)
        v.player.centreY = Int16(c.y - 100)
        BlobCrab.handleCrab(world: v, id: cid)
        XCTAssertEqual([Int(try slot(v, cid).phase), Int(try slot(v, cid).subtype)], [90, 1])
        // Straight right (d 0, forbidden for 0x764), out of reach: the angle holds.
        let r = try crabWorld()
        let (rid, _, _) = try enemy(r, type: 0x764, x: 600, y: 500)
        let rc = try slot(r, rid).centre
        var rp = SpriteSlot(type: 0x80, x: rc.x + 400, y: rc.y)
        rp.centre = SpriteSlot.Point(x: rc.x + 400, y: rc.y)
        r.playerID = r.active.insert(rp)
        r.player.centreX = Int16(rc.x + 400)
        r.player.centreY = Int16(rc.y)
        BlobCrab.handleCrab(world: r, id: rid)
        XCTAssertEqual([Int(try slot(r, rid).phase), Int(try slot(r, rid).subtype)], [90, 0])
        XCTAssertEqual(try slot(r, rid).face, f(0x762, 0))
        // Up-left (d 13, T 130) for 0x766 at 90: + 5.
        let q = try crabWorld()
        let (qid, _, _) = try enemy(q, type: 0x766, x: 600, y: 500)
        let qc = try slot(q, qid).centre
        var qp = SpriteSlot(type: 0x80, x: qc.x - 200, y: qc.y - 238)
        qp.centre = SpriteSlot.Point(x: qc.x - 200, y: qc.y - 238)
        q.playerID = q.active.insert(qp)
        XCTAssertEqual(BloodSpray.direction(target: (v: Int16(qc.y), h: Int16(qc.x)), from: (v: Int16(qc.y - 238),
                                                                                            h: Int16(qc.x - 200))), 13)
        BlobCrab.handleCrab(world: q, id: qid)
        XCTAssertEqual(try slot(q, qid).phase, 95)
        // The water lookup's order through SetupFaces: `.GetBGTile(x >> 5, y >> 5)` — column first. Level 62's cell
        // (231, 28) is water (enemies-water-cave §7.3); (28, 231) — the swapped order — is not.
        let lv = try crabWorld()
        let L = lv.level
        XCTAssertTrue(UnderWater.isWaterTile(L.bgKind(tile: L.bgTile(col: 231, row: 28))))
        XCTAssertFalse(UnderWater.isWaterTile(L.bgKind(tile: L.bgTile(col: 28, row: 231))))
        let (wid, _, wl) = try enemy(lv, type: 0x764, x: 231 * 32, y: 28 * 32)
        XCTAssertEqual([try slot(lv, wid).classWord16c, Int32(try slot(lv, wid).mode)], [1, 0x90000])
        XCTAssertEqual(try wl.map { try slot(lv, $0).mode }, [UInt32](repeating: 0x90000, count: 5))
    }

    func testCrabStrike30Frames() throws {
        // State 1 (M l. 74124–74184): t = ++`+0xa6`; t ≤ 5 → face t; u = t − 5: u == 1 → `(+0x16c, +0x170)` =
        // `FUN_100417bc((angle / 10 + 18) mod 36, reach)` truncated; u ≤ 12 → claw = anchor + v·u² / 144; 13 ≤ u ≤ 24 →
        // face max(17 − u, 0), claw = anchor + v·(144 − (u − 12)²) / 144; u ≥ 25 → state 0, `+0xa6 = 10`. Every frame
        // link i at anchor + (claw − anchor)·i / (n + 1) + 30 (M l. 74274–74286).
        let w = try crabWorld(px: 5000, py: 5000)
        let (id, _, links) = try enemy(w, type: 0x766, x: 600, y: 500, p1: 0)
        XCTAssertEqual(links.count, 5)
        w.active.update(id: id) { $0.subtype = 1; $0.counterA6 = 0; $0.phase = 90 }
        var faces: [Int] = [], ys: [Int] = [], xs: [Int] = []
        for k in 1...30 {
            BlobCrab.handleCrab(world: w, id: id)
            let s = try slot(w, id)
            faces.append(s.face?.index ?? -1)
            ys.append(s.y)
            xs.append(s.x)
            XCTAssertEqual([Int(s.x256 >> 8), Int(s.y256 >> 8)], [s.x, s.y], "frame \(k)")
            XCTAssertEqual(s.rotation, 0, "no aim in state 1")
            for (i, l) in links.enumerated() {
                let ls = try slot(w, l)
                XCTAssertEqual(ls.x, 600 + ((s.x - 600) * i) / 6 + 30, "frame \(k) link \(i)")
                XCTAssertEqual(ls.y, 500 + ((s.y - 500) * i) / 6 + 30, "frame \(k) link \(i)")
            }
            if k == 6 { XCTAssertEqual([s.classWord16c, s.classWord170], [0, -100], "angle 90 → index 27 → (0, −r)") }
            if k < 30 { XCTAssertEqual(s.subtype, 1, "frame \(k)") }
        }
        // The setup's own face (nil) until t = 1; then 1…5, held at 5 while the claw goes out, 4…0 on the way back.
        XCTAssertEqual(faces, [1, 2, 3, 4, 5] + [Int](repeating: 5, count: 12) + [4, 3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0] + [0])
        let out = (1...12).map { 500 + (-100 * $0 * $0) / 144 }
        let back = (13...24).map { 500 + (-100 * (144 - ($0 - 12) * ($0 - 12))) / 144 }
        XCTAssertEqual(ys, [Int](repeating: 500, count: 5) + out + back + [500])
        XCTAssertEqual(out.last, 400, "full reach at u = 12")
        XCTAssertEqual(back.first, 401, "u = 13: −14300 / 144 → −99 (C truncation)")
        XCTAssertEqual(out.first, 500, "u = 1: −100 / 144 → 0")
        XCTAssertEqual(xs, [Int](repeating: 600, count: 30))
        var s = try slot(w, id)
        XCTAssertEqual([Int(s.subtype), Int(s.counterA6)], [0, 10], "t 30: back to aiming, 10-frame cooldown")
        // Cooldown: the aim decrements `+0xa6` and never strikes while ≥ 1.
        w.player.centreX = Int16(s.centre.x)
        w.player.centreY = Int16(s.centre.y - 50)
        var pl = SpriteSlot(type: 0x80, x: 0, y: 0)
        pl.centre = SpriteSlot.Point(x: s.centre.x, y: s.centre.y - 50)
        w.playerID = w.active.insert(pl)
        for k in 0..<10 {
            BlobCrab.handleCrab(world: w, id: id)
            s = try slot(w, id)
            XCTAssertEqual([Int(s.subtype), Int(s.counterA6)], [0, 9 - k])
        }
        BlobCrab.handleCrab(world: w, id: id)
        XCTAssertEqual(try slot(w, id).subtype, 1, "cooled down, in reach, on target: strikes")
        // A diagonal (angle 40 → index 22: (sin 50°·r, −sin 40°·r) truncated) and straight right (angle 0 → 18: (r, 0)).
        for (angle, idx) in [(Int16(40), 22), (0, 18), (350, 17), (270, 9), (170, 35), (70, 25), (180, 0), (50, 23)] {
            let v = try crabWorld()
            let (vid, _, _) = try enemy(v, type: 0x766, x: 600, y: 500)
            v.active.update(id: vid) { $0.subtype = 1; $0.counterA6 = 5; $0.phase = angle }
            BlobCrab.handleCrab(world: v, id: vid)
            let t = try slot(v, vid)
            let vec = BloodSpray.vector(idx, magnitude: 100)
            XCTAssertEqual([t.classWord16c, t.classWord170], [Int32(vec.x), Int32(vec.y)], "angle \(angle)")
            XCTAssertEqual([t.x, t.y], [600 + Int(Int32(vec.x)) / 144, 500 + Int(Int32(vec.y)) / 144])
        }
        // Angle 70 → index 25: y = −0.94·100 — the table's stored sin 70° is 0.94 (`100a18b8` = 0x3fee147ae147ae14), so
        // −94 exactly; the y truncation is pinned by angle 50 → index 23 (−76.6 → −76 truncated, −77 rounded; index 22’s −64.27 tells truncation only from a floor). Angle 180 → index
        // (18 + 18) mod 36 = 0: (−100, 0), x = 600 + (−100) / 144 = 600 (C division; a floor would give 599); angle 170 →
        // index 35.
        XCTAssertEqual(Int32(BloodSpray.vector(25, magnitude: 100).y), -94)
        XCTAssertEqual([Int32(BloodSpray.vector(0, magnitude: 100).x), Int32(600 + -100 / 144)], [-100, 600])
        XCTAssertEqual([Int32(BloodSpray.vector(22, magnitude: 100).x), Int32(BloodSpray.vector(22, magnitude: 100).y)],
                       [76, -64])
        // The cap: reach 300 → 12 links, divisor 13; at full reach (angle 0, u 12) link 12's place is never written.
        let cap = try crabWorld()
        let (kid, _, kl) = try enemy(cap, type: 0x766, x: 600, y: 500, p1: 300)
        XCTAssertEqual(kl.count, 12)
        cap.active.update(id: kid) { $0.subtype = 1; $0.counterA6 = 16; $0.phase = 0; $0.classWord16c = 300; $0.classWord170 = 0 }
        BlobCrab.handleCrab(world: cap, id: kid)
        let ks = try slot(cap, kid)
        XCTAssertEqual([ks.x, ks.y], [900, 500])
        XCTAssertEqual(try kl.map { try slot(cap, $0).x }, (0..<12).map { 600 + (300 * $0) / 13 + 30 })
        XCTAssertEqual(try kl.map { try slot(cap, $0).y }, [Int](repeating: 530, count: 12))
        // HP < 1 → state 3 (M l. 74287–74289; nothing hurts it) — then nothing moves but the links' rule.
        cap.active.update(id: kid) { $0.hp = 0 }
        BlobCrab.handleCrab(world: cap, id: kid)
        XCTAssertEqual(try slot(cap, kid).subtype, 3)
        let frozen = try slot(cap, kid)
        BlobCrab.handleCrab(world: cap, id: kid)
        XCTAssertEqual([try slot(cap, kid).x, Int(try slot(cap, kid).counterA6)], [frozen.x, Int(frozen.counterA6)])
        // `.HandleCrabSegSprite` (M l. 74296–74305): face = the single 0x767; nothing else.
        let seg = kl[3]
        let before = try slot(cap, seg)
        BlobCrab.handleCrabSegment(world: cap, id: seg)
        var after = try slot(cap, seg)
        XCTAssertEqual(after.face, f(0x767, 0))
        after.face = before.face
        XCTAssertEqual(after, before)
        // The session's Handle dispatch: a Crab claw and its links, kept active, each run their Handle in a frame — the
        // claw's aim faces it 0x762[0] and sets `+0x1aa`, each link takes the single 0x767.
        let sess = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 3, seed: 1)
        let sw = sess.world
        let me = try slot(sw, try XCTUnwrap(sw.playerID))
        var nc = SpriteSlot(type: 0x766, x: me.x + 200, y: me.y - 150)
        nc.oldPosition = SpriteSlot.Point(x: nc.x, y: nc.y)
        BlobCrab.setupCrab(&nc, reach: 0, water: { _, _ in false }) { x, y, layer, wet in
            var k = BlobCrab.makeLink(x: x, y: y, layer: layer, clawInWater: wet, water: { _, _ in false })
            k.mayIdle = false
            return sw.active.insert(k)
        }
        nc.mayIdle = false
        let ncid = sw.active.insert(nc)
        let nl = (try slot(sw, ncid).crabLinks?.links ?? []).compactMap { $0 }
        XCTAssertEqual(nl.count, 5)
        _ = sess.step(keys: KeyState())
        XCTAssertEqual(try slot(sw, ncid).face, f(0x762, 0), "the Crab Handle ran")
        XCTAssertEqual(try slot(sw, ncid).rotation, try slot(sw, ncid).phase)
        XCTAssertEqual(try nl.map { try slot(sw, $0).face }, [FaceRef?](repeating: f(0x767, 0), count: 5),
                       "the segment Handle ran")
    }

    func testCrabInvulnerable() throws {
        // `.HitCrabSprite` (M l. 74308–74321): a player shot with `+0xa6 == 0` while the claw's HP > 0 → `.KillPlayerShot(
        // shot, 1, 1)` and metal hit 303 vol 0xab at the claw's centre — no damage, no Statue test, no blood.
        let w = try crabWorld()
        let (id, _, _) = try enemy(w, type: 0x764)
        let sid = try other(w, over: id, damage: 500)
        w.player.cues = []
        var lights = LightTable()
        BlobCrab.hitCrab(w, id: id, other: sid, lights: &lights)
        var s = try slot(w, id)
        XCTAssertTrue(try slot(w, sid).dead, "the shot killed")
        XCTAssertEqual([Int(s.hp), Int(s.invulnerable), Int(s.flash), Int(s.subtype)], [1000, 0, 0, 0])
        XCTAssertEqual(w.player.cues.last, PlayerCue(call: .threeD, snd: 303, priority: 1, volume: 0xab, position: s.centre))
        XCTAssertEqual(w.player.cues.filter { $0.snd == 301 }.count, 1, "the shot's own impact sound (`sound` 1)")
        XCTAssertEqual(w.active.sprites.filter { $0.handler == .effect && $0.type == 5 }.count, 1,
                       "the impact effect 5 (`effect` 1)")
        XCTAssertEqual(w.particles.records.filter { $0.alive && ($0.kind == 2 || $0.kind == 0xc9) }.count, 0, "no blood")
        // The Statue spell: no test — the shot dies, the claw stays a Crab.
        let st = try other(w, over: id, type: 1)
        BlobCrab.hitCrab(w, id: id, other: st, lights: &lights)
        XCTAssertTrue(try slot(w, st).dead)
        XCTAssertEqual(try slot(w, id).handler, .crab)
        // A shot with `+0xa6 ≠ 0`, a claw at HP 0, a non-shot: nothing.
        w.player.cues = []
        let late = try other(w, over: id) { $0.counterA6 = -6 }
        BlobCrab.hitCrab(w, id: id, other: late, lights: &lights)
        XCTAssertFalse(try slot(w, late).dead)
        let box = try other(w, over: id, type: 0xc12, handler: .box)
        BlobCrab.hitCrab(w, id: id, other: box, lights: &lights)
        w.active.update(id: id) { $0.hp = 0 }
        let fresh = try other(w, over: id)
        BlobCrab.hitCrab(w, id: id, other: fresh, lights: &lights)
        XCTAssertFalse(try slot(w, fresh).dead, "HP 0: the `0 < +0xa4` guard")
        XCTAssertEqual(w.player.cues, [])
        // Through the session's hit dispatch (`+0x5c` = `.HitCrabSprite`); the links have none.
        let v = try crabWorld()
        let (vid, _, vl) = try enemy(v, type: 0x764)
        let vs = try other(v, over: vid)
        FerazelSession.hitCallback(v, vid, vs)
        XCTAssertTrue(try slot(v, vs).dead)
        XCTAssertEqual(try slot(v, vid).hp, 1000)
        XCTAssertFalse(try slot(v, vl[0]).hasHit)
        // Not in the Ring of Smiting's list (`.SmiteEnemies`, TOC 0x100a048c…04c4); the Blob is.
        XCTAssertEqual([Smite.enemyHandlers.contains(.crab), Smite.enemyHandlers.contains(.blob)], [false, true])
        // Contact (`.HitPlayerSprite` step 6, M l. 49514–49573): 0x70, no blood, 3 coins when R(100) ≥ 0x3d.
        for (r, coins) in [(Int16(0x3c), Int16(0)), (0x3d, 3)] {
            let c = try crabWorld()
            let pid = try XCTUnwrap(Player.spawn(world: c, x: 200, y: 300))
            c.active.update(id: pid) { $0.hp = 1000; $0.invulnerable = 0 }
            let p = try slot(c, pid)
            let (cid, _, _) = try enemy(c, type: 0x764, x: p.x, y: p.y)
            c.active.update(id: cid) { $0.hotRect = p.hotRect }
            c.globals.coins = 10
            c.rng = FastRand(seed: seed { $0.next(100) == r })
            HitPlayerSprite.hit(c, player: pid, other: cid)
            XCTAssertEqual(try slot(c, pid).hp, 1000 - 0x70, "R \(r)")
            XCTAssertEqual(c.particles.records.filter { $0.alive && $0.kind == 2 }.count, 0)
            XCTAssertTrue(coins == 0 ? c.player.coinsLost == 0 : (2...4).contains(c.player.coinsLost), "R \(r)")
        }
        // The Blob is hurt by a shot (`.HitBlobSprite`, M l. 67993–68026): `.KillPlayerShot(shot, 0, 0)`; type 1 →
        // `.TurnIntoStatue`; else `.HurtSprite(s, shot +0xa4, (i16)(shot vx >> 1), −1000, 2, 8)`, on a hurt state 5,
        // `.BloodSpray(s, shot, 0x28, 400, 0x96, 0xc9)` and snd 702 below HP 201, else 701 (vol 0x100). Statue / Box
        // crush as the Frog. No Effect 0x4b7 arm. (The Crab's contrast, kept in this test.)
        let b = try world()
        let (bid, _, _) = try enemy(b)
        let bs = try other(b, over: bid, damage: 150, vx: 1001, vy: -200)
        let pre = try slot(b, bid)
        b.player.cues = []
        var draws = b.rng
        BlobCrab.hitBlob(b, id: bid, other: bs)
        s = try slot(b, bid)
        // The slime's velocities (`BloodSpray` rule: the 10° vector of length 400 from the shot's centre toward the
        // Blob's, negated and truncated, plus R(0x96) − 0x4b each — vy drawn first).
        let dir = BloodSpray.direction(target: (v: Int16(s.centre.y), h: Int16(s.centre.x)),
                                       from: (v: Int16(try slot(b, bs).centre.y), h: Int16(try slot(b, bs).centre.x)))
        let vec = BloodSpray.vector(dir, magnitude: 400)
        let nx = Int32((-vec.x).rounded(.towardZero)), ny = Int32((-vec.y).rounded(.towardZero))
        var want: [[Int32]] = []
        for _ in 0..<0x28 {
            let vy = ny + Int32(draws.next(0x96)) - 0x4b
            want.append([nx + Int32(draws.next(0x96)) - 0x4b, vy])
        }
        XCTAssertEqual(b.particles.records.filter { $0.alive && $0.kind == 0xc9 }.map { [$0.vx, $0.vy] }, want)
        XCTAssertTrue(try slot(b, bs).dead)
        XCTAssertEqual([Int(s.hp), Int(s.invulnerable), Int(s.flash), Int(s.subtype)], [550, 2, 8, 5])
        XCTAssertEqual([s.vx - pre.vx, s.vy - pre.vy], [500, -1000])
        XCTAssertEqual(slime(b), 0x28)
        XCTAssertEqual(b.player.cues.filter { $0.snd != 301 }, [PlayerCue(call: .threeD, snd: 701, priority: 1,
                                                                          volume: 0x100, position: s.centre)])
        XCTAssertEqual(b.player.cues.filter { $0.snd == 301 }, [], "`.KillPlayerShot(shot, 0, 0)`: no impact sound")
        XCTAssertEqual(b.active.sprites.filter { $0.handler == .effect }.count, 0, "no impact effect")
        for (hp, snd) in [(Int16(351), Int16(701)), (350, 702), (100, 702)] {
            let e = try world()
            let (eid, _, _) = try enemy(e)
            e.active.update(id: eid) { $0.hp = hp }
            e.player.cues = []
            let o = try other(e, over: eid, damage: 150)
            BlobCrab.hitBlob(e, id: eid, other: o)
            XCTAssertEqual(e.player.cues, [PlayerCue(call: .threeD, snd: snd, priority: 1, volume: 0x100,
                                                     position: try slot(e, eid).centre)], "HP \(hp - 150)")
            XCTAssertEqual(slime(e), 0x28, "blood even when killed")
        }
        // Statue spell; a dead Blob (HP 0) or a cooling shot is not hit; a Smiting explosion 0x4b7 does nothing.
        let st2 = try other(b, over: bid, type: 1)
        b.active.update(id: bid) { $0.invulnerable = 0 }
        BlobCrab.hitBlob(b, id: bid, other: st2)
        XCTAssertEqual(try slot(b, bid).handler, .statue)
        let z = try world()
        let (zid, _, _) = try enemy(z)
        z.active.update(id: zid) { $0.hp = 0 }
        let zs = try other(z, over: zid)
        BlobCrab.hitBlob(z, id: zid, other: zs)
        XCTAssertFalse(try slot(z, zs).dead)
        let cool = try other(z, over: zid) { $0.counterA6 = 1 }
        z.active.update(id: zid) { $0.hp = 700 }
        BlobCrab.hitBlob(z, id: zid, other: cool)
        XCTAssertFalse(try slot(z, cool).dead)
        let spent = try other(z, over: zid) { $0.counterA6 = -6 }
        BlobCrab.hitBlob(z, id: zid, other: spent)
        XCTAssertEqual([try slot(z, spent).dead, try slot(z, zid).hp == 700], [false, true], "`+0xa6` −6: no hit")
        let blast = try other(z, over: zid, type: 0x4b7, handler: .effect) { $0.phase = 0 }
        BlobCrab.hitBlob(z, id: zid, other: blast)
        XCTAssertEqual(try slot(z, zid).hp, 700, "no explosion arm")
        // A Box falling on it from above: crushed — HP 0, `+0x150 = 0x16`.
        let cr = try world()
        let (crid, _, _) = try enemy(cr)
        let solver = TileSolver(world: cr)
        for _ in 0..<40 { frame(cr, crid, solver) }
        cr.active.update(id: crid) { $0.vy = -0x400 }
        let fr = try slot(cr, crid)
        let bx = fr.x + fr.hotRect.left, by = fr.y + fr.hotRect.top - 30
        let crate = try XCTUnwrap(cr.newSprite(type: 0xc12, x: bx, y: by, layer: 2, handler: .box) { s in
            s.x = bx
            s.y = by
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x20, right: fr.hotRect.right - fr.hotRect.left)
            s.vy = 1
        })
        BlobCrab.hitBlob(cr, id: crid, other: crate)
        XCTAssertEqual([Int(try slot(cr, crid).hp), Int(try slot(cr, crid).classWord150)], [0, 0x16])
        // A falling Statue (`PTR_PTR_100a01f8`) crushes it the same way.
        let sc = try world()
        let (scid, _, _) = try enemy(sc)
        let ss = TileSolver(world: sc)
        for _ in 0..<40 { frame(sc, scid, ss) }
        sc.active.update(id: scid) { $0.vy = -0x400 }
        let sf = try slot(sc, scid)
        let sx = sf.x + sf.hotRect.left, sy = sf.y + sf.hotRect.top - 30
        let statue = try XCTUnwrap(sc.newSprite(type: 0x708, x: sx, y: sy, layer: 2, handler: .statue) { s in
            s.x = sx
            s.y = sy
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x20, right: sf.hotRect.right - sf.hotRect.left)
            s.vy = 1
        })
        BlobCrab.hitBlob(sc, id: scid, other: statue)
        XCTAssertEqual([Int(try slot(sc, scid).hp), Int(try slot(sc, scid).classWord150)], [0, 0x16], "Statue crush")
        // Through the session's hit dispatch.
        let h = try world()
        let (hid, _, _) = try enemy(h)
        let hs = try other(h, over: hid)
        FerazelSession.hitCallback(h, hid, hs)
        XCTAssertEqual(try slot(h, hid).hp, 550)
    }
}
