import XCTest
@testable import FerazelCore

/// PI (docs/plans/2026-10-30-ferazel-phase5.md; enemies-ground-2 §6, enemies-flyers §7.4): the enemy pipes 1490…1493
/// (0x5d2 up, 0x5d3 down, 0x5d4 right, 0x5d5 left) — `.SetupBoxSprite`'s pipe arm (M l. 59325–59356), `.HandleBoxSprite`'s
/// pipe arm (M l. 60624–60768), `.GenerateSprite`'s Walker / Blob / Bat children (M l. 1691–1936) and `.MTCollideSprites`'
/// `+0x1b2` rule (M l. 30253–30254). Every pipe ships on level 21 only: each placement here is made by hand over level
/// 3's header and an empty synthetic 60×30 grid. Every expected draw is re-derived from a copy of the stream.
final class EnemyPipeTests: XCTestCase {

    nonisolated(unsafe) private static let level3 = Result {
        try LevelFile.load(from: try FerazelData.open(try FerazelData.dataDirectory()), level: 3)
    }

    private func world() throws -> SpriteWorld {
        let w = SpriteWorld(level: try Self.level3.get())
        let empty = [UInt16](repeating: 0, count: 60 * 30)
        w.tiles = TileGrid(fg: TileMap(width: 60, height: 30, cells: empty), bg: TileMap(width: 60, height: 30, cells: empty),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        w.levelIndex = 3
        return w
    }

    /// The pipe's own face `+0` rect (its hot rect is this inset by 3) and the child's face `+8` bounds.
    private let pipeFace = IdleSprites.Rect(top: 0, left: 0, bottom: 32, right: 32)
    private let childBounds = IdleSprites.Rect(top: 4, left: 6, bottom: 76, right: 130)

    /// A pipe placed as record 0 at (400, 600), set up by the pipe arm of `.SetupBoxSprite` on the world's stream.
    private func pipe(_ w: SpriteWorld, _ type: Int16, p1: Int16 = 0x6a9, p2: Int16 = 150) -> (Int, Placement) {
        let p = Placement(index: 0, flag: 1, byte1: 0, type: type, p1: p1, p2: p2, p3: 0, p4: 0, y: 600, x: 400)
        w.records = [p]
        var s = SpriteSlot(type: type, x: 400, y: 600, recordIndex: 0)
        let rec = BoxSprite.setupPipe(&s, record: p, level: w.level, rng: &w.rng, faceRect: pipeFace)
        w.records = [rec]
        return (w.active.insert(s), rec)
    }

    /// One pipe Handle (the Box dispatch row's test form) with the child's face bounds.
    private func frame(_ w: SpriteWorld, _ id: Int) {
        let b = childBounds
        BoxSprite.handle(world: w, id: id) { _ in b }
    }

    private func slot(_ w: SpriteWorld, _ id: Int?) throws -> SpriteSlot { try XCTUnwrap(id.flatMap(w.active.record)) }

    /// `.Deviation(n)` (M l. 39497–39503) on a copy: n + R(n >> 1) − (n >> 2).
    private func deviation(_ n: Int16, _ r: inout FastRand) -> Int16 { n &+ r.next(n >> 1) &- (n >> 2) }

    /// Runs frames until the pipe's next frame spawns (its `+0xa6` at 1).
    private func runToSpawn(_ w: SpriteWorld, _ id: Int) throws {
        var guardFrames = 0
        while try slot(w, id).counterA6 > 1 {
            frame(w, id)
            guardFrames += 1
            guard guardFrames < 400 else { return XCTFail("the pipe's `+0xa6` never counts down") }
        }
        XCTAssertNil(try slot(w, id).siblings.first)
    }

    func testPipeSpawnsChild() throws {
        let w = try world()
        // The Setup (M l. 59325–59356): layer 1, `+0xa6 = .Deviation(p2)`, `+0x15c` = p1, the hot rect = face `+0`
        // inset by 3, gravity 0, no hit, no tile callback.
        var r = w.rng
        let a6 = deviation(150, &r)
        let (id, _) = pipe(w, 0x5d3)
        var s = try slot(w, id)
        XCTAssertEqual(s.layer, 1)
        XCTAssertEqual(s.counterA6, a6)
        XCTAssertEqual(s.classWord15c, 0x6a9)
        XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 3, left: 3, bottom: 29, right: 29))
        XCTAssertEqual(s.gravity, 0)
        XCTAssertFalse(s.hasHit)
        XCTAssertFalse(s.hasTileHit)
        // p2 0 → 100, written back into the record (M l. 59328–59330).
        let w0 = try world()
        XCTAssertEqual(pipe(w0, 0x5d3, p2: 0).1.p2, 100)
        // p1 0: the arm returns before the face store, the countdown and the tail (M l. 60625–60627) — nothing moves.
        let w1 = try world()
        let (id1, _) = pipe(w1, 0x5d3, p1: 0)
        w1.active.update(id: id1) { u in
            u.face = nil
            u.vy = 0x100
            u.counterA6 = 5
        }
        let before1 = try slot(w1, id1)
        frame(w1, id1)
        XCTAssertEqual(try slot(w1, id1), before1)

        try runToSpawn(w, id)
        s = try slot(w, id)
        XCTAssertEqual(s.centre, SpriteSlot.Point(x: 416, y: 616))
        // The spawn frame: `+0xa6 = .Deviation(p2)`, then the Walker's Setup draws (R(0x5fff), R(0x46), R(400)).
        r = w.rng
        let next = deviation(150, &r)
        let pitch = Int32(r.next(0x5fff)) * 2 + 0xbfff
        _ = r.next(0x46)
        let k154 = Int32(r.next(400)) + 1000
        frame(w, id)
        s = try slot(w, id)
        let cID = try XCTUnwrap(s.siblings.first)                      // `+0x1d4` = the child
        let c = try slot(w, cID)
        XCTAssertEqual(s.counterA6, next)
        XCTAssertEqual(s.classWord150, 2)                              // 1 at the spawn, + 1 the same frame (M l. 60696)
        XCTAssertEqual(s.classWord154, (0x47 - 10) / 3 + 4)            // 0x5d3: (bottom − top) / 3 + 4 (M l. 60669–60670)
        XCTAssertEqual(c.type, 0x6a9)
        XCTAssertEqual(c.recordIndex, 0x200)
        XCTAssertTrue(c.emerging)
        XCTAssertEqual(c.handler, .walker)
        XCTAssertEqual(c.layer, 4)                                     // the Walker Setup's own `+0x80` over the argument 2
        XCTAssertEqual(c.voicePitch, pitch)
        XCTAssertEqual(c.classWord154, k154)
        XCTAssertEqual(c.subtype, 5)
        XCTAssertEqual(c.face, FaceRef(pict: 0x6a9, index: 0, set: .encoded))
        // x = centre x − width / 2 − face left; y = pipe y + 0x1c − hot bottom, then + 3 the same frame.
        XCTAssertEqual(c.x, 416 - 62 - 6)
        XCTAssertEqual(c.y, 600 + 0x1c - 0x47 + 3)
        XCTAssertEqual(c.x256, Int32(c.x) << 8)
        XCTAssertEqual(c.y256, Int32(c.y) << 8)
        XCTAssertEqual(c.clip.top, 600 + 0x1d - c.y)
        XCTAssertTrue(w.player.cues.isEmpty)
        // The clip edge at its boundary (0x5d3, M l. 60715–60722: `iVar15 < 1` → 0): 1 px short of the pipe's far edge
        // keeps 1; exactly on it, 0. `+0x150` 2 → 4 here, under `+0x154` 23: still emerging.
        w.active.update(id: cID) { $0.y = 600 + 0x1d - 1 - 3 }
        frame(w, id)
        XCTAssertEqual(try slot(w, cID).clip.top, 1)
        w.active.update(id: cID) { $0.y = 600 + 0x1d - 3 }
        frame(w, id)
        XCTAssertEqual(try slot(w, cID).clip.top, 0)
        XCTAssertTrue(try slot(w, cID).emerging)

        // The other children `.GenerateSprite` makes for the shipped pipes: the Blob 1730 and the insect bat 1860.
        var lights = LightTable()
        let blob = try slot(w, BoxSprite.generate(w, type: 0x6c2, x: 100, y: 200, layer: 2, lights: &lights, effects: 1))
        XCTAssertEqual(blob.handler, .blob)
        XCTAssertEqual(blob.recordIndex, 0x200)
        XCTAssertEqual(blob.hp, 700)
        XCTAssertEqual(blob.layer, 8)
        XCTAssertEqual(SpriteSlot.Point(x: blob.x, y: blob.y), SpriteSlot.Point(x: 100, y: 200))
        XCTAssertEqual(blob.face, FaceRef(pict: BlobCrab.blobSet, index: 0, set: .encoded))
        let bat = try slot(w, BoxSprite.generate(w, type: 0x744, x: 100, y: 200, layer: 2, lights: &lights, effects: 1))
        XCTAssertEqual(bat.handler, .bat)
        XCTAssertEqual(bat.recordIndex, 0x200)
        XCTAssertEqual(bat.face, FaceRef(pict: Bat.insectSet, index: 3, set: .encoded))
        // The Walker children: spawn point `+0xc ← +8`, `+0xa ← +6` (M l. 56957–56958); the flip from playerX
        // (`*_DAT_1009fd94`): 0x6a9 playerX < x + 0x32 (M l. 56982), 0x6d6… the same (M l. 57008), 0x6e0… x + 0x32 <
        // playerX (M l. 56991; 0x6e0 itself starts flipped, M l. 56947, so 0x6e1); the face by family (M l. 56981, 57007,
        // 56990).
        let walkers: [(Int16, Int16, Int16, Bool)] = [
            (0x6a9, 0x6a9, 149, true), (0x6a9, 0x6a9, 150, false),
            (0x6d6, 0x6d6, 149, true), (0x6df, 0x6d6, 150, false),
            (0x6e1, 0x6e0, 151, true), (0x6e9, 0x6e0, 150, false),
        ]
        for (t, face, px, flip) in walkers {
            w.player.centreX = px
            let k = try slot(w, BoxSprite.generate(w, type: t, x: 100, y: 200, layer: 2, lights: &lights, effects: 1))
            XCTAssertEqual(SpriteSlot.Point(x: k.x, y: k.y), SpriteSlot.Point(x: 100, y: 200), "\(t)")
            XCTAssertEqual(k.oldPosition, SpriteSlot.Point(x: 100, y: 200), "\(t)")
            XCTAssertEqual(k.mirrored, flip, "\(t) \(px)")
            XCTAssertEqual(k.face, FaceRef(pict: face, index: 0, set: .encoded), "\(t)")
        }
    }

    func testEmergingClipAndPush() throws {
        // (type, child x at the spawn, y at the spawn, the length `+0x154`, step dx, dy, the clip edge after the spawn
        // frame's push); the child is the 1705 (hot rect (0x4c, 10, 0x7c, 0x47)), faced (4, 6, 76, 130).
        let rows: [(Int16, Int, Int, Int32, Int, Int, WritableKeyPath<SpriteClip, Int>)] = [
            (0x5d2, 416 - 62 - 6, 610, 0x47 / 3 + 4, 0, -3, \.bottom),           // `+0x38` / 3 + 4 (M l. 60662)
            (0x5d4, 400 + 0x1c - 130, 616 - 36 - 4, (0x7c - 0x4c) / 3 + 4, 3, 0, \.left),
            (0x5d5, 410, 616 - 36 - 4, 0x7c / 3 + 4, -3, 0, \.right),          // `+0x3a` / 3 + 4 (M l. 60688)
        ]
        for (t, x0, y0, len, dx, dy, edge) in rows {
            let w = try world()
            let (id, _) = pipe(w, t)
            try runToSpawn(w, id)
            frame(w, id)
            let cID = try XCTUnwrap(try slot(w, id).siblings.first)
            XCTAssertEqual(try slot(w, id).classWord154, len, "\(t)")
            func clip(_ c: SpriteSlot) -> Int {
                // The edge per direction (M l. 60706–60740): (pipe + 7 or + 0x1d) − child, below 1 → 0.
                let v: Int
                switch t {
                case 0x5d2: v = 600 + 7 - c.y
                case 0x5d4: v = 400 + 0x1d - c.x
                default: v = 400 + 7 - c.x
                }
                return v < 1 ? 0 : v
            }
            var n = 2
            var c = try slot(w, cID)
            XCTAssertEqual(SpriteSlot.Point(x: c.x, y: c.y), SpriteSlot.Point(x: x0 + dx, y: y0 + dy), "\(t)")
            XCTAssertEqual(c.clip[keyPath: edge], clip(c), "\(t)")
            // Frame 3: the pipe's random-pitch cue 459 (`*_DAT_100a0364`), priority 1, volume 0x100, at its centre.
            var r = w.rng
            let rate = r.soundRate()
            w.player.cues = []
            frame(w, id)
            n += 1
            let p = try slot(w, id)
            XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDRand, snd: 459, priority: 1, volume: 0x100,
                                                     position: p.centre, rate: rate)], "\(t)")
            // 3 px a frame while `+0x150` ≤ `+0x154`.
            while n < Int(len) {
                frame(w, id)
                n += 1
            }
            w.player.cues = []
            c = try slot(w, cID)
            XCTAssertEqual(try slot(w, id).classWord150, len, "\(t)")
            XCTAssertTrue(c.emerging, "\(t)")
            XCTAssertEqual(SpriteSlot.Point(x: c.x, y: c.y), SpriteSlot.Point(x: x0 + dx * (n - 1), y: y0 + dy * (n - 1)))
            XCTAssertEqual(c.clip[keyPath: edge], clip(c), "\(t)")
            // `+0x150` past `+0x154`: pushed once more, then released — `+0x1b2` 0, the clip back to (0, 32000,
            // 32000, 0), `+0x150` 0; `+0x1d4` stays (M l. 60741–60755).
            frame(w, id)
            c = try slot(w, cID)
            XCTAssertFalse(c.emerging, "\(t)")
            XCTAssertEqual(SpriteSlot.Point(x: c.x, y: c.y), SpriteSlot.Point(x: x0 + dx * n, y: y0 + dy * n))
            XCTAssertEqual(c.clip, SpriteClip(left: 0, right: 32000, bottom: 32000, top: 0), "\(t)")
            XCTAssertEqual(try slot(w, id).classWord150, 0)
            XCTAssertEqual(try slot(w, id).siblings.first, cID)
            XCTAssertTrue(w.player.cues.isEmpty)
            // No push after the release; no new child while the old one lives, whatever `+0xa6`.
            w.active.update(id: id) { $0.counterA6 = 0 }
            frame(w, id)
            XCTAssertEqual(try slot(w, cID).x, c.x)
            XCTAssertEqual(try slot(w, id).siblings.first, cID)
            // The child's kill request: `+0x1d4` and `+0x150` 0, `+0xa6 = .Deviation(p2)` (M l. 60760–60767) — on `+0xe9`
            // (dead), or on `+0xea` alone (killed for good: the 0x5d4 row; M l. 60762).
            w.active.update(id: cID) { k in
                if t == 0x5d4 { k.killedForGood = true } else { k.dead = true }
            }
            r = w.rng
            let a6 = deviation(150, &r)
            frame(w, id)
            XCTAssertNil(try slot(w, id).siblings.first)
            XCTAssertEqual(try slot(w, id).counterA6, a6)
        }
    }

    func testEmergingStillCollidable() throws {
        let w = try world()
        let (id, _) = pipe(w, 0x5d3)
        try runToSpawn(w, id)
        frame(w, id)
        let cID = try XCTUnwrap(try slot(w, id).siblings.first)
        _ = w.active.remove(id: id)                                    // the pipe out of the pass
        let c = try slot(w, cID)
        // B overlaps the child's hot rect (x 424…472, y 570…631 here).
        var b = SpriteSlot(type: 0x51c, x: c.x + 0x4c, y: c.y + 10, recordIndex: -1, layer: 9)
        b.hasHit = true
        b.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 20, right: 20)
        let bID = w.active.insert(b)
        var calls: [[Int]] = []
        w.collideSprites { _, a, o in calls.append([a, o]) }
        // Skipped as the outer sprite (raw `10032744`); as B's inner sprite it is contacted and its hit runs.
        XCTAssertEqual(calls, [[bID, cID], [cID, bID]])
        // Released, it is an outer sprite again: one pair per pass.
        w.active.update(id: cID) { $0.emerging = false }
        calls = []
        w.collideSprites { _, a, o in calls.append([a, o]) }
        XCTAssertEqual(calls.count, 4)
        XCTAssertEqual(calls.filter { $0 == [cID, bID] }.count, 2)

        // The children's class Handles return at once while emerging (each `lbz 0x1b2`): no field, no draw.
        var lights = LightTable()
        let solver = TileSolver(world: w)
        let blobID = try XCTUnwrap(BoxSprite.generate(w, type: 0x6c2, x: 100, y: 200, layer: 2, lights: &lights, effects: 1))
        let batID = try XCTUnwrap(BoxSprite.generate(w, type: 0x744, x: 100, y: 200, layer: 2, lights: &lights, effects: 1))
        for k in [cID, blobID, batID] {
            w.active.update(id: k) { $0.emerging = true }
            let before = try slot(w, k)
            var r = w.rng
            switch before.handler {
            case .walker: Walker.handle(world: w, id: k, solver: solver, lights: &lights, effects: 1)
            case .blob: BlobCrab.handleBlob(world: w, id: k, solver: solver)
            default: Bat.handle(world: w, id: k, solver: solver, lights: &lights, effects: 1)
            }
            XCTAssertEqual(try slot(w, k), before, "\(before.handler)")
            XCTAssertEqual(w.rng.next(30000), r.next(30000))
            EnemyCommon.handle(world: w, id: k)
            XCTAssertEqual(try slot(w, k), before)
        }
    }

    func testPipeChildNotCounted() throws {
        let w = try world()
        w.enemies = EnemyCounting(window: false, live: 0)               // run time: the window is closed
        let (id, rec) = pipe(w, 0x5d4, p1: 0x6a4, p2: 60)
        try runToSpawn(w, id)
        frame(w, id)
        let cID = try XCTUnwrap(try slot(w, id).siblings.first)
        let c = try slot(w, cID)
        XCTAssertEqual(c.recordIndex, 0x200)
        XCTAssertFalse(c.countedInTotals)
        XCTAssertEqual(w.enemies.live, 0)
        // No placement record for the child: `.UpdateSprites` writes back and clears only 0…0x1fe (record 0x200 past
        // the 511 records), through the child's kill and unlink.
        var lights = LightTable()
        w.active.update(id: cID) { $0.dead = true }
        frame(w, id)                                                   // the pipe lets go of it (a new interval)
        XCTAssertNil(try slot(w, id).siblings.first)
        // Dead while still emerging (`+0x150` 2 → 3 this frame): `+0x150 = 0` with the release (M l. 60764).
        XCTAssertEqual(try slot(w, id).classWord150, 0)
        // `+0x150 > 0` with no child: `+0x150 = 0` (M l. 60701–60703), no step and no cue.
        w.active.update(id: id) { $0.classWord150 = 5 }
        w.player.cues = []
        frame(w, id)
        XCTAssertEqual(try slot(w, id).classWord150, 0)
        XCTAssertNil(try slot(w, id).siblings.first)
        XCTAssertTrue(w.player.cues.isEmpty)
        for _ in 0..<5 { w.updateSprites(lights: &lights) }
        XCTAssertNil(w.active.sprite(id: cID))                         // unlinked
        XCTAssertEqual(w.records, [Placement(index: 0, flag: 1, byte1: 0, type: 0x5d4, p1: 0x6a4, p2: 60, p3: 0, p4: 0,
                                             y: 600, x: 400)])
        XCTAssertEqual(w.records, [rec])
        XCTAssertEqual(w.enemies.live, 0)
        // A Blob child counts only while the window is open (`.SetupBlobSprite` M l. 67728–67731: `+0x1b5 = 1`, live
        // + 1): closed, nothing; open, both.
        let shut = try slot(w, BoxSprite.generate(w, type: 0x6c2, x: 100, y: 200, layer: 2, lights: &lights, effects: 1))
        XCTAssertFalse(shut.countedInTotals)
        XCTAssertEqual(w.enemies.live, 0)
        w.enemies.window = true
        let open = try slot(w, BoxSprite.generate(w, type: 0x6c2, x: 100, y: 200, layer: 2, lights: &lights, effects: 1))
        XCTAssertTrue(open.countedInTotals)
        XCTAssertEqual(w.enemies.live, 1)
    }

    // MARK: - 6A-PS: the pipes' level spawn (level 21, on the fixture with nothing left out)

    /// Level 21's six pipes as shipped (World Data): record, type, p1 (the child type), p2.
    private static let level21Pipes: [[Int]] = [
        [35, 1491, 1730, 0], [36, 1491, 1705, 150], [135, 1491, 1705, 60], [136, 1492, 1700, 110],
        [137, 1490, 1860, 60], [169, 1493, 1730, 100],
    ]

    func testLevel21PipeLevelSpawn() throws {
        let data = try LevelFixture.base.get()
        let real = try LevelFile.load(from: data, level: 21)
        let pipes = real.activePlacements.filter { BoxSprite.pipes.contains($0.type) }
        XCTAssertEqual(pipes.map { [$0.index, Int($0.type), Int($0.p1), Int($0.p2)] }, Self.level21Pipes)
        // Every child type is placed on level 21 itself (a child type not placed here would be a STOP for the seat):
        // the Walkers 1700 / 1705, the Blob 1730, the insect 1860.
        var placed: [Int16: Int] = [:]
        for p in real.activePlacements where [1700, 1705, 1730, 1860].contains(p.type) { placed[p.type, default: 0] += 1 }
        XCTAssertEqual(placed, [1700: 5, 1705: 5, 1730: 3, 1860: 5])

        // The Setup arm (M l. 59325–59356): the type's cache single marked (`rec+1 = 1`, M l. 59336 — singles #6–#9,
        // `.InitBoxSprite` M l. 58771) and `+0xc0` = its face (`rec+4`, M l. 59337–59338) — on a level's first load the
        // placeholder PICT 150 (`.Cache1EncFaceFromPICT` M l. 73951–73952), so the hot rect is the placeholder's `+0`
        // frame (0, 0, 64, 64) inset by 3 (M l. 59339–59345); drawn from the cache (`.setupCached`).
        let ctx = SetupFaces.Context(level: real, playerX: SetupFaces.Context.levelStartPlayerX(real.header))
        let placeholder = FaceRef(pict: SetupFaces.placeholderPict, index: 0, set: .encoded)
        XCTAssertEqual(FerazelSession.frameRect(placeholder, resources: data),
                       IdleSprites.Rect(top: 0, left: 0, bottom: 64, right: 64))
        for (k, t) in (Int16(0x5d2)...0x5d5).enumerated() {
            XCTAssertEqual(CachedFaces.markedRecords(type: t), [.single(5 + k)], "\(t)")
            XCTAssertEqual(CachedFaces.singles[5 + k].pict, t)
            XCTAssertEqual(CachedFaces.singles[5 + k].flag, 0)
        }
        for p in pipes {
            var r = FastRand(seed: 3), own = FastRand(seed: 3)
            let e = try SetupFaces.setup(p, context: ctx, rng: &r)
            let s = e.slot, what = "record \(p.index)"
            XCTAssertEqual(e.source, .setupCached, what)
            XCTAssertEqual(e.sheet, .single(p.type), what)
            XCTAssertEqual(s.face, FaceRef(pict: p.type, index: 0, set: .encoded), what)
            XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 3, left: 3, bottom: 61, right: 61), what)
            XCTAssertEqual(s.layer, 1, what)
            XCTAssertEqual(s.classWord15c, Int32(p.p1), what)
            XCTAssertEqual(e.record.p2, p.p2 == 0 ? 100 : p.p2, what)
            XCTAssertEqual(s.counterA6, deviation(e.record.p2, &own), what)
            XCTAssertEqual(r.seed, own.seed, "\(what): the Setup itself draws `.Deviation` only")
            XCTAssertTrue(e.children.isEmpty, "\(what): the throwaway child is the level spawn's")
        }

        // The spawn: after each pipe's Setup, `.GenerateSprite(x, y, p1, 0x200, now 1, layer 2)` (M l. 59349–59352) —
        // the child's class Setup draws here (a Walker R(0x5fff), R(0x46), R(400), M l. 56898–57100; the Blob and the
        // insect none) and counts it (the window is open: Walker M l. 57090–57094, Blob 67728–67731, insect
        // 68234–68237) — then child `+0xe9 = 1` (M l. 59353–59355). Replayed per record on a copy of the stream.
        var rng = FastRand(seed: 1)
        var counting = EnemyCounting(window: true)
        let spawned = try SetupFaces.spawnLevelSprites(context: ctx, rng: &rng, counting: &counting) { _ in .noFace }
        var replay = FastRand(seed: 1)
        var replayCount = EnemyCounting(window: true)
        var lights = LightTable()
        var expected: [[Int]] = []                                     // type, x, y, then a Walker's three draws
        for p in real.spawnOrder {
            _ = try SetupFaces.setup(p, context: ctx, lights: &lights, counting: &replayCount, rng: &replay)
            guard BoxSprite.pipes.contains(p.type) else { continue }
            replayCount.live += 1
            var row = [Int(p.p1), Int(p.x), Int(p.y)]
            if p.p1 == 1700 || p.p1 == 1705 {
                row += [Int(replay.next(0x5fff)) * 2 + 0xbfff, Int(replay.next(0x46)) + 0x78, Int(replay.next(400)) + 1000]
            }
            expected.append(row)
        }
        XCTAssertEqual(rng.seed, replay.seed, "the throwaway children's draws sit after their pipes' Setups")
        XCTAssertEqual(counting.live, replayCount.live)
        let thrown = spawned.active.sprites.filter { $0.recordIndex == 0x200 && $0.dead }
        XCTAssertEqual(thrown.map { Int($0.killCount) }, [1, 1, 1, 1, 1, 1])
        var seen = thrown.map { k -> [Int] in
            var row = [Int(k.type), k.x, k.y]
            if k.handler == .walker { row += [Int(k.voicePitch), Int(k.classTimer), Int(k.classWord154)] }
            return row
        }
        seen.sort { $0.lexicographicallyPrecedes($1) }
        XCTAssertEqual(seen, expected.sorted { $0.lexicographicallyPrecedes($1) })
        XCTAssertEqual(thrown.filter(\.countedInTotals).count, 6)
        for s in spawned.active.sprites where BoxSprite.pipes.contains(s.type) {
            XCTAssertNil(s.siblings.first, "record \(s.recordIndex): the throwaway is not linked (`+0x1d4` 0)")
        }
        XCTAssertEqual(spawned.records[35].p2, 100)
        // Each throwaway is made inside its pipe's Setup, so before the pipe is inserted (`.MTNewSprite` runs the Setup
        // before `.MTInsertSprite`, M l. 30715–30719): the child's id is the lower. Its layer is its class Setup's own
        // store (Walker 4, Blob 8, insect 0xb), which overwrites the `+0x80 + 1` argument. Measured on the session
        // stream: the pipes' `.Deviation(p2)` and the Walkers' flip (playerX 118 < x + 0x32 for all three).
        var pairs: [[Int]] = []
        for s in spawned.active.sprites where BoxSprite.pipes.contains(s.type) {
            let k = try XCTUnwrap(thrown.first { $0.x == s.x && $0.y == s.y }, "record \(s.recordIndex)")
            XCTAssertLessThan(k.id, s.id, "record \(s.recordIndex): the child is made before the pipe is inserted")
            pairs.append([Int(s.recordIndex), Int(s.counterA6), Int(k.type), Int(k.layer), k.mirrored ? 1 : 0])
        }
        XCTAssertEqual(pairs, [[35, 81, 1730, 8, 0], [36, 181, 1705, 4, 1], [135, 53, 1705, 4, 1],
                               [136, 137, 1700, 4, 1], [137, 54, 1860, 0xb, 0], [169, 98, 1730, 8, 0]])
        // The insect throwaway's body (its Setup's `.MTNewSprite(type, +0xc, +0xa, layer − 1, 0x200, …)`, M l.
        // 68228–68233): linked from the throwaway, record 0x200, layer 0xa, alive, uncounted.
        let insect = try XCTUnwrap(thrown.first { $0.type == 1860 })
        let body = try XCTUnwrap(insect.siblings.first.flatMap { spawned.active.record(id: $0) })
        XCTAssertEqual(body.handler, .insectBody)
        XCTAssertEqual([Int(body.recordIndex), Int(body.layer)], [0x200, 0xa])
        XCTAssertFalse(body.dead)
        XCTAssertFalse(body.countedInTotals)
        // A child type whose class `BoxSprite.generate` does not build is a refusal, not "no free record": synthetic,
        // record 35's p1 made the boulder 0x42e (the Box class).
        var swapped = real.placements
        let r35 = swapped[35]
        swapped[35] = Placement(index: 35, flag: r35.flag, byte1: r35.byte1, type: r35.type, p1: 0x42e, p2: r35.p2,
                                p3: r35.p3, p4: r35.p4, y: r35.y, x: r35.x)
        let refusing = SetupFaces.Context(level: real, playerX: ctx.playerX, records: swapped)
        var r2 = FastRand(seed: 1), c2 = EnemyCounting(window: true)
        XCTAssertThrowsError(try SetupFaces.spawnLevelSprites(context: refusing, rng: &r2, counting: &c2) { _ in
            .noFace
        }) { XCTAssertEqual($0 as? SetupFaces.Error, .notTranscribed(type: 0x42e)) }

        // On the fixture (level 21, nothing left out, through the level runner; headless).
        XCTAssertEqual(try LevelFixture.leftOut(real, []).count, 0)
        let run = try LevelFixture.open(level: 21, leaveOut: [])
        var now: UInt32 = 0
        func tick() throws {
            _ = try run.tick(now: now, input: FrontInput())
            now &+= 1
        }
        while run.session == nil && now < 4000 { try tick() }
        let session = try XCTUnwrap(run.session, "level 21 opens with nothing left out")
        let w = session.world
        // The p2 write-back (M l. 59328–59330) in the live records: record 35's 0 → 100, the others as shipped.
        XCTAssertEqual(real.placements[35].p2, 0)
        for row in Self.level21Pipes {
            XCTAssertEqual(w.records[row[0]].p2, row[3] == 0 ? 100 : Int16(row[3]), "record \(row[0])")
        }
        // The six throwaways on the list (`+0xe9` 1), each counted: the live count and the level's enemy total carry
        // the + 6 (M l. 2528–2536).
        XCTAssertEqual(w.active.sprites.filter { $0.recordIndex == 0x200 && $0.dead }.count, 6)
        XCTAssertEqual(w.enemies.live, counting.live)
        XCTAssertEqual(w.globals.totals[0][21], 42, "the 36 counted placements and the six throwaways")
        // The insect throwaway's Setup made its body (record 0x200), which `+0xe9 = 1` does not reach: five placed
        // insects' bodies and that one.
        XCTAssertEqual(w.active.sprites.filter { $0.handler == .insectBody }.count, 6)
        let liveAtStart = w.enemies.live
        XCTAssertEqual(liveAtStart, 36 + 6, "measured: the 36 counted placements and the six throwaways")
        // The pipes on the list with their first-load hot rect, no link, no idle entry: 0x5d2…0x5db spawn at once
        // (`.GenerateSprite` M l. 1734 / 1875–1878, bVar1 false → `.MTNewSprite`), and `.HandleIdleSprites` idles only
        // sprites from the idle table (M l. 4349), so a pipe is never idled.
        for row in Self.level21Pipes {
            let s = try XCTUnwrap(w.active.sprites.first { Int($0.recordIndex) == row[0] }, "record \(row[0])")
            XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 3, left: 3, bottom: 61, right: 61))
            XCTAssertNil(s.siblings.first)
            XCTAssertFalse(w.idle.entries.contains { $0?.saved.recordIndex == Int16(row[0]) })
        }

        // The load bar (`.LoadCachedSpriteFaces`, M l. 73769–73869): the pipes' singles #6–#9 marked; the throwaways'
        // Setups also mark their classes' records, but every child type is placed here, so the marks of the placed
        // types (`needed(by:)`) already hold them — the count is the same with and without.
        let needed = CachedFaces.needed(by: session)
        for k in 5...8 { XCTAssertTrue(needed.records.contains(.single(k)), "single #\(k + 1)") }
        var withChildren = needed
        for p in pipes { withChildren.records.formUnion(CachedFaces.markedRecords(type: p.p1, p1: 0)) }
        XCTAssertEqual(withChildren, needed)
        var a = CachedFaces(), c = CachedFaces()
        let bars = a.load(needed: needed)
        var noPipes = needed
        for k in 5...8 { noPipes.records.remove(.single(k)) }
        XCTAssertEqual(c.load(needed: noPipes).count, bars.count - 4)
        // Measured: 40 bars (36 without the pipes' singles), n = 150 faces → the last bar (300, 300).
        XCTAssertEqual(bars.count, 40)
        XCTAssertEqual(bars.last.map { [$0.0, $0.1] }, [300, 300])

        // Frames: `.UpdateSprites` counts each throwaway's `+0xe9` up and unlinks it at 4 (M l. 4968–5032); the count
        // is never taken back (`EnemyCounting.kill` needs `+0xe9` 0).
        let orphanID = try XCTUnwrap(w.active.sprites.first {
            $0.recordIndex == 0x200 && $0.dead && $0.type == 1860
        }?.siblings.first)
        let start = run.iterations
        while run.iterations < start + 5 && now < 8000 { try tick() }
        XCTAssertTrue(w.active.sprites.filter { $0.recordIndex == 0x200 && $0.dead }.isEmpty)
        XCTAssertEqual(w.enemies.live, liveAtStart)
        // The orphan insect body outlives its head: the Bat Handle copied the head's face and position to it before
        // its `+0xe9` return (M l. 68482–68501), and nothing kills a body when its head is unlinked (`.MTKillSprite`,
        // M l. 30743–30767): drawn, inert, uncounted, at pipe 137's spot with cell 8.
        let orphan = try XCTUnwrap(w.active.record(id: orphanID))
        XCTAssertFalse(orphan.dead)
        XCTAssertFalse(orphan.countedInTotals)
        XCTAssertEqual([orphan.x, orphan.y], [10316, 1820])
        XCTAssertEqual(orphan.face, FaceRef(pict: 1860, index: 8, set: .encoded))

        // The parent / child carry: pipe 135 (1491, p2 60) makes its 1705 at run time (`pipeArm`). Pipes spawn at once
        // and are never idled (M l. 1734 / 1875–1878, l. 4349), so the carry is that the link (`+0x1d4`) holds while
        // the child lives, and no second child is made (M l. 60760–60767).
        let pipeID = try XCTUnwrap(w.active.sprites.first { $0.recordIndex == 135 }?.id)
        var guardFrames = 0
        while try XCTUnwrap(w.active.record(id: pipeID)).siblings.first == nil && guardFrames < 200 {
            let i = run.iterations
            while run.iterations == i && now < 20000 { try tick() }
            guardFrames += 1
        }
        let child = try XCTUnwrap(w.active.record(id: pipeID)?.siblings.first, "pipe 135 spawned")
        let k = try XCTUnwrap(w.active.record(id: child))
        XCTAssertEqual([Int(k.type), Int(k.recordIndex)], [1705, 0x200])
        XCTAssertFalse(k.dead)
        var lived = 0
        for _ in 0..<60 {
            let i = run.iterations
            while run.iterations == i && now < 30000 { try tick() }
            guard let c = w.active.record(id: child), !c.dead, !c.killedForGood else { break }
            lived += 1
            XCTAssertEqual(try XCTUnwrap(w.active.record(id: pipeID)).siblings.first, child)
            XCTAssertFalse(w.idle.entries.contains { $0?.saved.recordIndex == 135 })
        }
        XCTAssertEqual(lived, 60, "measured: the child lives the 60 frames")
    }

    /// 6A-PS review (D69): a restart of level 21 keeps the pipe singles loaded. `FUN_10088ae0` clears only each cache
    /// record's needed byte (M l. 2520, 73582–73642) and `.DisposeUnneededCachedSpriteFaces` (inside
    /// `.LoadCachedSpriteFaces`, M l. 2537, 73714–73731) runs after `.SetupLevelSprites` (M l. 2526), so at a restart's
    /// Setups `rec+4` is the real face and the hot rect its `+0` frame inset by 3 (M l. 59337–59345): 1490 / 1491 are
    /// 96 × 36, 1492 / 1493 36 × 96. A level's first load reads the placeholder's (3, 3, 61, 61). The Box tail takes
    /// the centre from the hot rect, and the pipe Handle places an emerging child from it (M l. 60651–60686).
    func testLevel21PipeHotRectOnRestart() throws {
        let data = try LevelFixture.base.get()
        XCTAssertEqual((Int16(0x5d2)...0x5d5).map {
            let r = FerazelSession.frameRect(FaceRef(pict: $0, index: 0, set: .encoded), resources: data)
            return [r.top, r.left, r.bottom, r.right]
        }, [[0, 0, 36, 96], [0, 0, 36, 96], [0, 0, 96, 36], [0, 0, 96, 36]], "the pipe singles' `+0` frames")
        func open(_ carry: LevelCarry) throws -> (LevelRun, UInt32) {
            let run = try LevelFixture.open(level: 21, leaveOut: [], carry: carry)
            var now: UInt32 = 0
            while run.session == nil && now < 4000 { _ = try run.tick(now: now, input: FrontInput()); now &+= 1 }
            _ = try XCTUnwrap(run.session, "level 21 opens")
            return (run, now)
        }
        func rects(_ run: LevelRun) throws -> [[Int]] {
            let w = try XCTUnwrap(run.session).world
            return w.active.sprites.filter { BoxSprite.pipes.contains($0.type) }.map {
                [Int($0.recordIndex), $0.hotRect.top, $0.hotRect.left, $0.hotRect.bottom, $0.hotRect.right]
            }
        }
        /// Pipe 135 (1491, down) to its first emerging child: [iteration, pipe centre x, y, child type, x, y].
        func emerged(_ run: LevelRun, from start: UInt32) throws -> [Int] {
            let w = try XCTUnwrap(run.session).world
            let pipeID = try XCTUnwrap(w.active.sprites.first { $0.recordIndex == 135 }?.id)
            var now = start
            while try XCTUnwrap(w.active.record(id: pipeID)).siblings.first == nil && now < start &+ 20000 {
                _ = try run.tick(now: now, input: FrontInput())
                now &+= 1
            }
            let pipe = try XCTUnwrap(w.active.record(id: pipeID))
            let k = try XCTUnwrap(pipe.siblings.first.flatMap { w.active.record(id: $0) }, "pipe 135 made its child")
            return [run.iterations, pipe.centre.x, pipe.centre.y, Int(k.type), k.x, k.y]
        }

        // First load: the placeholder's rect on all six.
        let (first, t0) = try open(LevelCarry())
        let carry = first.carry                                            // the cache as the first load left it
        XCTAssertTrue(BoxSprite.pipes.allSatisfy(carry.cachedFaces.loadedSingles.contains))
        XCTAssertEqual(try rects(first), Self.level21Pipes.map { [$0[0], 3, 3, 61, 61] })
        let a = try emerged(first, from: t0)
        // The restart (the same level again, the cache carried): each pipe's rect from its real face.
        let (again, t1) = try open(carry)
        XCTAssertEqual(try rects(again), [[35, 3, 3, 33, 93], [36, 3, 3, 33, 93], [135, 3, 3, 33, 93],
                                          [136, 3, 3, 93, 33], [137, 3, 3, 33, 93], [169, 3, 3, 93, 33]])
        let b = try emerged(again, from: t1)
        // Measured: the child emerges on the same iteration (53); the pipe's centre moves from (x + 32, y + 32) to
        // (x + 48, y + 18), and the child (the 0x5d3 arm: `k.x = centre x − half the child's width − its left`,
        // `k.y = y + 0x1c − its bottom`) moves 16 px right with it; its y does not read the pipe's centre.
        XCTAssertEqual(a, [53, 10674, 1567, 1705, 10572, 1495])
        XCTAssertEqual(b, [53, 10690, 1553, 1705, 10588, 1495])
        XCTAssertEqual(zip(b, a).map { $0 - $1 }, [0, 16, -14, 0, 16, 0])
    }
}
