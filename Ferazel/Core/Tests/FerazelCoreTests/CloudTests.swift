import XCTest
import HectorResources
@testable import FerazelCore

/// 6A-CL (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-CL`; docs/ferazel/phase6-engine-contracts.md
/// §2.8): the clouds 0xb4a…0xb4d (2890–2893), placed on level 20 only — the Setup arm of `.SetupBackgroundSprite` (M l.
/// 62526–62567: two draws, R(60) then R(50)) and the Handle arm (M l. 63304–63341: the face again and the parallax).
/// The Setup is read per record from level 20's file (`SetupFaces.setup`, no level opened), on the level fixture
/// (`CloudTests.level20`, headless) for the draws' place in the stream, or made synthetically on level 20's world. A
/// missing data file is a FAILURE, never a skip.
final class CloudTests: XCTestCase {

    /// Level 20's leave-out list (6A-CL; ENG §7.2): the 44 records the port refused there when the clouds were built
    /// — the blades 3060 (28, built since by 6A-BD) and the maces 1485 (16, every one a mode-1 path, 6A-MP), by
    /// type. A literal list, never computed from what the port refuses today; `FeatureGoldenTests.level20Clouds` is
    /// the same list (the Render target cannot see a Core test's list).
    static let level20: [LevelFixture.LeaveOut] = [.type(3060), .type(1485)]

    /// The four cloud types, written here (not read from the port).
    private static let types: [Int16] = [0xb4a, 0xb4b, 0xb4c, 0xb4d]

    private typealias Rect = IdleSprites.Rect

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// Level 20's world, nothing in it.
    private func world() throws -> SpriteWorld {
        SpriteWorld(level: try LevelFile.load(from: try resources(), level: 20))
    }

    private func rec(_ type: Int16, p1: Int16 = 0, p2: Int16 = 0, index: Int = 7, x: Int16 = 3000,
                     y: Int16 = 900) -> Placement {
        Placement(index: index, flag: 1, byte1: 0, type: type, p1: p1, p2: p2, p3: 0, p4: 0, y: y, x: x)
    }

    /// The Park–Miller steps from seed `a` to seed `b` (every `FastRand(n ≠ 0)` is one step); nil past `limit`.
    private func steps(from a: Int32, to b: Int32, limit: Int = 200_000) -> Int? {
        var r = FastRand(seed: a)
        var n = 0
        while r.seed != b {
            guard n < limit else { return nil }
            _ = r.next(1)
            n += 1
        }
        return n
    }

    /// A synthetic cloud of type `t` set up on `w` with `rng` (`SetupFaces.setup`) and inserted.
    private func cloud(_ w: SpriteWorld, _ p: Placement, seed: Int32 = 1) throws -> Int {
        var rng = FastRand(seed: seed)
        let e = try SetupFaces.setup(p, context: SetupFaces.Context(level: w.level, playerX: 0), rng: &rng)
        return w.active.insert(e.slot)
    }

    /// One Handle of sprite `id` with the scroll point at (h, v).
    @discardableResult
    private func handle(_ w: SpriteWorld, _ id: Int, h: Int, v: Int) throws -> SpriteSlot {
        let r = try resources()
        w.player.scrollH = h
        w.player.scrollV = v
        BackgroundSprite.handle(world: w, id: id) { FerazelSession.frameRect($0, resources: r).right }
        return try XCTUnwrap(w.active.sprite(id: id))
    }

    /// M l. 63326 / 63336: `S·256 + (base − (S·256·f >> 8))` (32-bit, the shift arithmetic), for f > 0.
    private func parallax(scroll: Int, base: Int32, factor: Int32) -> Int32 {
        let s = Int32(truncatingIfNeeded: scroll) &* 0x100
        return s &+ (base &- ((s &* factor) >> 8))
    }

    // MARK: - the Setup arm (M l. 62526–62567)

    func testCloudSetupDrawsTwo() throws {
        let base = try LevelFixture.base.get()
        let real = try LevelFile.load(from: base, level: 20)
        // The fixture's 44 records, by type, re-derived from the level file: every 1485 on level 20 is a mode-1 path.
        let out = try LevelFixture.leftOut(real, Self.level20)
        XCTAssertEqual(out.count, 44, "the 44 refused records")
        var perType: [Int16: Int] = [:]
        for i in out { perType[real.placements[i].type, default: 0] += 1 }
        XCTAssertEqual(perType, [3060: 28, 1485: 16])
        XCTAssertEqual(Set(real.activePlacements.filter { $0.type == 1485 }.map(\.p1)), [1])

        // The fixture's records, spawned as `.SetupLevelSprites` does from seed 1 (`spawnLevelSprites`), and the twin
        // with the 164 clouds left out as well: the clouds' Setups are 328 steps of the stream.
        let res = try LevelFixture.resources(level: 20, leaveOut: Self.level20)
        let L = try LevelFile.load(from: res, level: 20)
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header))
        var rng = FastRand(seed: 1)
        let sp = try SetupFaces.spawnLevelSprites(context: c, rng: &rng) { _ in .noFace }
        let twinRes = try LevelFixture.resources(level: 20, leaveOut: Self.level20 + Self.types.map { .type($0) })
        let T = try LevelFile.load(from: twinRes, level: 20)
        var twinRng = FastRand(seed: 1)
        _ = try SetupFaces.spawnLevelSprites(context: SetupFaces.Context(level: T, playerX: c.playerX),
                                             rng: &twinRng) { _ in .noFace }
        let all = try XCTUnwrap(steps(from: 1, to: rng.seed)), twin = try XCTUnwrap(steps(from: 1, to: twinRng.seed))
        XCTAssertEqual(all - twin, 328, "two draws per cloud, 164 clouds")

        // Record by record in spawn order (the three passes): each cloud's Setup takes exactly two steps where it
        // stands in the stream — R(60) first (`+0x14c` = R(60) + 270), then R(50) (`+0x15c`).
        var spawned: [Int: SpriteSlot] = [:]
        for s in sp.active.sprites where Self.types.contains(s.type) { spawned[Int(s.recordIndex)] = s }
        XCTAssertEqual(spawned.count, 164, "every cloud spawned now (`.GenerateSprite`, 0xb4a…0xb53)")
        var replay = FastRand(seed: 1)
        var lights = 0, cloudsSeen = 0
        var firstCloudStep: Int?
        var ahead: [Int: Int] = [:]                        // the records set up before the first cloud: their steps
        for p in SetupFaces.spawnOrder(L.placements) {
            let before = replay.seed
            let e = try SetupFaces.setup(p, context: c, lightsInUse: lights, rng: &replay)
            if e.light != nil { lights += 1 }
            guard Self.types.contains(p.type) else {
                if cloudsSeen == 0 { ahead[p.index] = steps(from: before, to: replay.seed) }
                continue
            }
            cloudsSeen += 1
            if firstCloudStep == nil { firstCloudStep = steps(from: 1, to: before) }
            var own = FastRand(seed: before)
            let r60 = Int32(own.next(60)), r50 = Int32(own.next(50))
            XCTAssertEqual(steps(from: before, to: replay.seed), 2, "record \(p.index)")
            XCTAssertEqual([e.slot.classTimer, e.slot.classWord15c], [r60 + 270, r50], "record \(p.index)")
            let s = try XCTUnwrap(spawned[p.index], "record \(p.index)")
            XCTAssertEqual([s.classTimer, s.classWord150, s.classWord15c], [r60 + 270, r60 + 270, r50],
                           "record \(p.index): the spawn drew the same pair")
        }
        XCTAssertEqual(cloudsSeen, 164)
        XCTAssertEqual(replay.seed, rng.seed, "the replay is the whole spawn's stream")
        // Measured: the clouds are records 2…190 of pass 3 (no torch 0x51b, no platform on level 20); ahead of them only
        // records 0 (the hang glider 3050) and 1 (the Gremlin 1770) set up, one draw between them — so the clouds'
        // draws are the stream's 2nd to 329th.
        XCTAssertEqual(ahead.keys.sorted(), [0, 1])
        XCTAssertEqual(ahead.values.reduce(0, +), 1)
        XCTAssertEqual(firstCloudStep, 1)

        // On the fixture opened through the level runner (headless): `.SetupLevel` ran `.SetupLevelSprites` from the
        // run's seed, so every cloud carries the same pair — the 328 draws are inside it.
        let run = try LevelFixture.open(level: 20, leaveOut: Self.level20)
        var now: UInt32 = 0
        while run.session == nil && now < 2000 {
            _ = try run.tick(now: now, input: FrontInput())
            now += 1
        }
        let session = try XCTUnwrap(run.session, "level 20's fixture opens")
        var live: [Int: SpriteSlot] = [:]
        for s in session.world.active.sprites where Self.types.contains(s.type) { live[Int(s.recordIndex)] = s }
        for e in session.world.idle.entries.compactMap({ $0 }) where Self.types.contains(e.saved.type) {
            live[Int(e.saved.recordIndex)] = e.saved
        }
        XCTAssertEqual(live.count, 164)
        for (i, s) in spawned {
            let l = try XCTUnwrap(live[i], "record \(i)")
            XCTAssertEqual([l.classTimer, l.classWord150, l.classWord15c], [s.classTimer, s.classWord150, s.classWord15c],
                           "record \(i)")
        }
    }

    func testCloudSetupFields() throws {
        let r = try resources()
        let L = try LevelFile.load(from: r, level: 20)
        let c = SetupFaces.Context(level: L, playerX: 0)
        var seen: [Int16: Int] = [:]
        for p in L.activePlacements where Self.types.contains(p.type) {
            seen[p.type, default: 0] += 1
            let what = "record \(p.index)"
            XCTAssertEqual([p.p1, p.p2, p.p3, p.p4], [0, 0, 0, 0], what)
            var rng = FastRand(seed: Int32(p.index) + 1)
            var own = FastRand(seed: Int32(p.index) + 1)
            let e = try SetupFaces.setup(p, context: c, rng: &rng)
            let s = e.slot
            let fx = Int32(own.next(60)) + 270, r50 = Int32(own.next(50))
            // The common head (`setupCommon`, M l. 61966–61977), then the arm: `+0x5c = +0x1f8 = 0`, the empty rect
            // (M l. 62527–62529); the face from the cache and its mark (M l. 62530–62548); `+0x88 = 0`, `+0xb8 =
            // 0xb0004` (translucency, table 4), layer 0x7ef4 (M l. 62549–62551); `+0x14c` = p1, 0 → R(60) + 270;
            // `+0x150` = p2, 0 → `+0x14c`; `+0x154 = x << 8`, `+0x158 = y << 8`; `+0x15c = R(50)` (M l. 62552–62565).
            XCTAssertEqual(s.handler, .background, what)
            XCTAssertEqual([s.hasHit, s.hasTileHit], [false, false], what)
            XCTAssertEqual(s.hotRect, Rect(top: 0, left: 0, bottom: 0, right: 0), what)
            XCTAssertFalse(s.lightOverlay, what)
            XCTAssertEqual(s.mode, 0xb0004, what)
            XCTAssertEqual(s.layer, 0x7ef4, what)
            XCTAssertEqual([s.classTimer, s.classWord150, s.classWord15c], [fx, fx, r50], what)
            XCTAssertEqual([s.classWord154, s.classWord158], [Int32(p.x) << 8, Int32(p.y) << 8], what)
            XCTAssertEqual([s.x256, s.y256], [Int32(p.x) << 8, Int32(p.y) << 8], what)
            XCTAssertEqual([Int(s.counterA6), Int(s.hp)], [3, 6], what)
            XCTAssertEqual(rng.seed, own.seed, "\(what): two draws")
            // Spawned now; the face the cache single of the type (`+0xc0 = cache + 4`), converted under CLUT 200 (the
            // flag 0, `.InitBackgroundSprite` M l. 61869–61872); nothing written back, nothing made.
            XCTAssertEqual(e.spawn, .now, what)
            XCTAssertEqual(e.source, .setupCached, what)
            XCTAssertEqual(e.sheet, SetupFaces.Sheet.single(p.type, clut: 200), what)
            XCTAssertEqual(s.face, FaceRef(pict: p.type, index: 0, set: .encoded), what)
            XCTAssertEqual(e.record, p, "\(what): nothing written back")
            XCTAssertTrue(e.children.isEmpty, what)
        }
        XCTAssertEqual(seen, [0xb4a: 44, 0xb4b: 44, 0xb4c: 32, 0xb4d: 44])
        // Level 20 only: no other level places a cloud.
        for res in r.world.resources(of: "Mlvl") where res.id != 20 {
            let other = try LevelFile(resource: res)
            XCTAssertFalse(other.activePlacements.contains { Self.types.contains($0.type) }, "level \(res.id)")
        }
        // Each cloud marks its own cache single (`rec+1 = 1`, M l. 62533–62545): singles #132–#135 (0-based 131…134),
        // registered flag 0 (M l. 61869–61872).
        for (k, t) in Self.types.enumerated() {
            XCTAssertEqual(CachedFaces.markedRecords(type: t), [.single(131 + k)], "\(t)")
            XCTAssertEqual(CachedFaces.record(.single(131 + k)).pict, t)
            XCTAssertEqual(CachedFaces.record(.single(131 + k)).flag, 0)
        }
        // The cloud pictures are 174 / 197 / 220 / 193 px wide — below the translucency buffer's 301 bytes, so the
        // renderer's `Refusal.translucency` width case cannot be reached by a cloud (ENG §2.8 item 3).
        let widths = Self.types.map { FerazelSession.frameRect(FaceRef(pict: $0, index: 0, set: .encoded), resources: r).right }
        XCTAssertEqual(widths, [174, 197, 220, 193])
        XCTAssertTrue(widths.allSatisfy { $0 < 301 })

        // Synthetic records (none shipped): p1 ≠ 0 is taken as it is with no R(60) — the one draw is R(50); p2 ≠ 0
        // is taken as it is; a negative position shifts as a 32-bit int.
        let w = try world()
        let wc = SetupFaces.Context(level: w.level, playerX: 0)
        for (p1, p2): (Int16, Int16) in [(300, 0), (300, -7), (-3, 0), (0, 12)] {
            var rng = FastRand(seed: 5), own = FastRand(seed: 5)
            let e = try SetupFaces.setup(rec(0xb4c, p1: p1, p2: p2, x: -40, y: -2), context: wc, rng: &rng)
            let fx: Int32 = p1 == 0 ? Int32(own.next(60)) + 270 : Int32(p1)
            let fy: Int32 = p2 == 0 ? fx : Int32(p2)
            let r50 = Int32(own.next(50))
            XCTAssertEqual([e.slot.classTimer, e.slot.classWord150, e.slot.classWord15c], [fx, fy, r50],
                           "p1 \(p1) p2 \(p2)")
            XCTAssertEqual(rng.seed, own.seed, "p1 \(p1): \(p1 == 0 ? 2 : 1) draws")
            XCTAssertEqual([e.slot.classWord154, e.slot.classWord158], [-40 * 256, -2 * 256])
        }
        // The base is the spawn copy's 16-bit position (`(int)*(short *)(+0xc) << 8`, M l. 62563–62564): a pixel
        // position past 16 bits keeps its low half.
        var wide = SpriteSlot(type: 0xb4a, x: 0x10000 + 40, y: -0x10000 - 2)
        var wideRng = FastRand(seed: 5)
        BackgroundSprite.setupCloud(&wide, record: rec(0xb4a), rng: &wideRng)
        XCTAssertEqual([wide.classWord154, wide.classWord158], [40 * 256, -2 * 256], "the 16-bit position")
    }

    // MARK: - the Handle arm (M l. 63304–63341)

    func testCloudParallaxX() throws {
        let w = try world()
        // A cloud of each type at (3000, 900), fx 300 and fy 0 (y held at `+0x158`): x256 = H·256 + (`+0x154` −
        // (H·256·fx >> 8)) for every scroll H (M l. 63321–63327), then the pixel copies (M l. 63340–63341).
        for (k, t) in Self.types.enumerated() {
            let id = try cloud(w, rec(t, index: 10 + k))
            w.active.update(id: id) { $0.classTimer = 300; $0.classWord150 = 0 }
            for h in [0, 100, 640, 3000, 9999, -40, -1, 32000] {
                // The face re-read from the cache on every Handle (M l. 63307–63320).
                w.active.update(id: id) { $0.face = nil }
                let s = try handle(w, id, h: h, v: 77)
                let x256 = parallax(scroll: h, base: 3000 << 8, factor: 300)
                XCTAssertEqual(s.face, FaceRef(pict: t, index: 0, set: .encoded), "\(t) H \(h)")
                XCTAssertEqual(s.x256, x256, "\(t) H \(h)")
                XCTAssertEqual(s.x, Int(Int16(truncatingIfNeeded: x256 >> 8)), "\(t) H \(h)")
                XCTAssertEqual([s.y256, Int32(s.y)], [900 << 8, 900], "\(t) H \(h): fy 0 → `+0x158`")
            }
        }
        // As shipped (fx = 270…329 > 256): on screen (x − H) the cloud moves fx/256 of every pixel the view moves — more
        // than the world does (fx 300: H 0 → x 3000, on screen 3000; H 256 → x 2956, on screen 2700).
        let id = try cloud(w, rec(0xb4a, index: 20))
        w.active.update(id: id) { $0.classTimer = 300 }
        XCTAssertEqual(try handle(w, id, h: 0, v: 0).x, 3000)
        XCTAssertEqual(try handle(w, id, h: 256, v: 0).x, 2956)
        // fx = 0 → x256 = `+0x154` whatever the scroll (M l. 63322–63323); fx < 0 → x256 unchanged (M l.
        // 63321–63325) — and the pixel copy still made from it.
        w.active.update(id: id) { $0.classTimer = 0; $0.x256 = 0x12345; $0.x = 1 }
        var s = try handle(w, id, h: 5000, v: 0)
        XCTAssertEqual([s.x256, Int32(s.x)], [3000 << 8, 3000])
        w.active.update(id: id) { $0.classTimer = -5; $0.x256 = 0x12345; $0.x = 1 }
        s = try handle(w, id, h: 5000, v: 0)
        XCTAssertEqual([s.x256, Int32(s.x)], [0x12345, 0x123])
        w.active.update(id: id) { $0.classTimer = Int32.min; $0.x256 = -0x1234; $0.x = 1 }
        s = try handle(w, id, h: 5000, v: 0)
        XCTAssertEqual([s.x256, Int32(s.x)], [-0x1234, -0x13], "the copy is the 24.8 value's middle 16 bits")
        // H is the scroll point's 16-bit h (`*(short *)(PTR_DAT_1009fe78 + 2)`, M l. 63327): a wider scroll keeps its
        // low half.
        w.active.update(id: id) { $0.classTimer = 300 }
        s = try handle(w, id, h: 0x10000 + 100, v: 0)
        XCTAssertEqual(s.x256, parallax(scroll: 100, base: 3000 << 8, factor: 300), "H is 16-bit")
    }

    func testCloudParallaxY() throws {
        let w = try world()
        // fy 280, fx 0 (x held at `+0x154`): y256 = V·256 + (`+0x158` − (V·256·fy >> 8)) (M l. 63330–63337).
        for (k, t) in Self.types.enumerated() {
            let id = try cloud(w, rec(t, index: 10 + k, x: 500, y: 1200))
            w.active.update(id: id) { $0.classTimer = 0; $0.classWord150 = 280 }
            for v in [0, 1, 416, 1200, 7000, -64, 32000] {
                let s = try handle(w, id, h: 999, v: v)
                let y256 = parallax(scroll: v, base: 1200 << 8, factor: 280)
                XCTAssertEqual(s.y256, y256, "\(t) V \(v)")
                XCTAssertEqual(s.y, Int(Int16(truncatingIfNeeded: y256 >> 8)), "\(t) V \(v)")
                XCTAssertEqual([s.x256, Int32(s.x)], [500 << 8, 500], "\(t) V \(v): fx 0 → `+0x154`")
            }
        }
        // The two axes are independent: fy reads `+0x150`, never `+0x14c` (fx 1 here would move x alone).
        let id = try cloud(w, rec(0xb4d, index: 20, x: 500, y: 1200))
        w.active.update(id: id) { $0.classTimer = 512; $0.classWord150 = 256 }
        var s = try handle(w, id, h: 100, v: 100)
        XCTAssertEqual([Int32(s.x), Int32(s.y)], [500 - 100, 1200], "fx 512 moves x; fy 256 keeps y on the world")
        // fy = 0 → y256 = `+0x158` (M l. 63331–63332); fy < 0 → y256 unchanged (M l. 63330–63334), copied after both.
        w.active.update(id: id) { $0.classWord150 = 0; $0.y256 = 0x7777; $0.y = 3 }
        s = try handle(w, id, h: 100, v: 4000)
        XCTAssertEqual([s.y256, Int32(s.y)], [1200 << 8, 1200])
        w.active.update(id: id) { $0.classWord150 = -1; $0.y256 = 0x7777; $0.y = 3 }
        s = try handle(w, id, h: 100, v: 4000)
        XCTAssertEqual([s.y256, Int32(s.y)], [0x7777, 0x77])
        XCTAssertEqual([Int32(s.x)], [500 - 100], "x moved in the same Handle")
        // V is the scroll point's 16-bit v (`*(short *)PTR_DAT_1009fe78`, M l. 63336): a wider scroll keeps its low half.
        w.active.update(id: id) { $0.classWord150 = 280 }
        s = try handle(w, id, h: 100, v: 0x10000 + 416)
        XCTAssertEqual(s.y256, parallax(scroll: 416, base: 1200 << 8, factor: 280), "V is 16-bit")
    }

    func testCloudNeverCollides() throws {
        let w = try world()
        // A probe with a hit callback and a large hot rect over each cloud, through every arm of the Handle (fx / fy
        // > 0, = 0, < 0): the clouds have no hit callback, no tile callback and an empty rect (M l. 62527–62529), and
        // `.MTCollideSprites` never pairs them with anything.
        var ids: [Int] = []
        for (k, (fx, fy)) in [(Int32(300), Int32(300)), (0, 0), (-1, -1), (300, 0), (0, -1)].enumerated() {
            let id = try cloud(w, rec(Self.types[k % 4], index: 10 + k, x: 1000, y: 600))
            w.active.update(id: id) { $0.classTimer = fx; $0.classWord150 = fy }
            ids.append(id)
        }
        var probe = SpriteSlot(type: 0x51b, x: 900, y: 500)
        probe.hasHit = true
        probe.hotRect = Rect(top: 0, left: 0, bottom: 400, right: 400)
        let pID = w.active.insert(probe)
        for f in 0..<3 {
            for id in ids { try handle(w, id, h: 900 + 10 * f, v: 500) }
            var pairs: [[Int]] = []
            w.collideSprites { _, a, b in pairs.append([a, b]) }
            XCTAssertTrue(pairs.isEmpty, "frame \(f): \(pairs)")
            for id in ids {
                let s = try XCTUnwrap(w.active.sprite(id: id))
                XCTAssertEqual([s.hasHit, s.hasTileHit], [false, false])
                XCTAssertEqual(s.hotRect, Rect(top: 0, left: 0, bottom: 0, right: 0))
            }
        }
        // The control: a second probe over the first is paired (the pass runs).
        var other = SpriteSlot(type: 0x51b, x: 950, y: 550)
        other.hotRect = Rect(top: 0, left: 0, bottom: 40, right: 40)
        let oID = w.active.insert(other)
        var pairs: [[Int]] = []
        w.collideSprites { _, a, b in pairs.append([a, b]) }
        XCTAssertEqual(pairs, [[pID, oID]])
    }

    func testCloudFxAlwaysAbove256OnLevel20() throws {
        // Per record from level 20's file, on the stream the level start gives them (the fixture's spawn from seed 1)
        // and on every stream: p1 = p2 = 0, so fx = fy = R(60) + 270 ∈ 270…329 > 256 — the fx / fy ≤ 0 arms are not
        // reachable as shipped.
        let L = try LevelFile.load(from: try resources(), level: 20)
        let c = SetupFaces.Context(level: L, playerX: 0)
        let clouds = L.activePlacements.filter { Self.types.contains($0.type) }
        XCTAssertEqual(clouds.count, 164)
        for p in clouds {
            XCTAssertEqual([p.p1, p.p2], [0, 0], "record \(p.index)")
            for seed: Int32 in [1, 2, 0x7fff_fffe, 12345] {
                var rng = FastRand(seed: seed)
                let s = try SetupFaces.setup(p, context: c, rng: &rng).slot
                XCTAssertTrue((270...329).contains(s.classTimer), "record \(p.index) seed \(seed): \(s.classTimer)")
                XCTAssertEqual(s.classWord150, s.classTimer, "record \(p.index)")
                XCTAssertGreaterThan(s.classTimer, 256)
            }
        }
        let res = try LevelFixture.resources(level: 20, leaveOut: Self.level20)
        let F = try LevelFile.load(from: res, level: 20)
        var rng = FastRand(seed: 1)
        let sp = try SetupFaces.spawnLevelSprites(context: SetupFaces.Context(level: F, playerX: 0), rng: &rng) { _ in .noFace }
        let fxs = sp.active.sprites.filter { Self.types.contains($0.type) }.map(\.classTimer)
        XCTAssertEqual(fxs.count, 164)
        XCTAssertTrue(fxs.allSatisfy { $0 > 256 && $0 < 330 })
        // A spread, not one value: measured 58 of R(60)'s 60 values among the 164, from 270 to 329.
        XCTAssertEqual(Set(fxs).count, 58)
        XCTAssertEqual([fxs.min(), fxs.max()], [270, 329])
    }
}
