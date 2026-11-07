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
}
