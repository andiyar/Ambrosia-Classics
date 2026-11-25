import XCTest
import HectorResources
@testable import FerazelCore

/// 6A-CP — the magic carpet 0x438 / 0x439 (docs/superpowers/plans/2026-11-04-ferazel-remainder.md, card 6A-CP;
/// docs/ferazel/phase6-engine-contracts.md §2.11). The carpet's own half: `.SetupBoxSprite`'s arm (M l. 59078–59103),
/// `.HandleBoxSprite`'s arm (M l. 60289–60375) and the Box tail (M l. 61152–61174), the wake in `.HitBoxSprite` (M l.
/// 61470–61476); the player's built half proven: `.HandlePlayerSprite` row 3 (M l. 44532–44552), the `.HandleKeys`
/// carpet block (M l. 47249–47308). The level-22 tests run on the level fixture (level 22 with nothing left out, the
/// player's start moved beside placement 486 through the fixture's `start:` — a named test stand-in); the ride-count,
/// flash and burst arms run on made-up carpets (record p2 > 0), named as such: the only shipped carpet has p2 0.
/// Proof-B rules: no `@MainActor`, no Foundation string search. A missing data file is a FAILURE, never a skip.
final class CarpetTests: XCTestCase {

    // MARK: - helpers

    private func resources() throws -> FerazelResources { try LevelFixture.base.get() }
    private func level22() throws -> LevelFile { try LevelFile.load(from: try resources(), level: 22) }

    /// Level 22's leave-out list: none — the carpet is the last level-22 feature (ENG §2.11 "First level / golden").
    static let level22LeaveOut: [LevelFixture.LeaveOut] = []

    /// The only shipped carpet: level 22's placement 486.
    static let carpetRecord = 486

    /// The fixture's player start (`LevelRun`'s `start:`): right above the shipped carpet (7849, 2017), which lies on
    /// the ledge of FG row 63 (columns 245…248); the player's hot rect (x + 0x26 … x + 0x3e = 7890…7914) spans the
    /// rolled carpet's one-pixel-wide rect (x 7901, y 2021…2029), and he drops onto it (his rect's bottom y + 0x55).
    static let start = (x: 7852, y: 1931)

    /// A synthetic 16×16 grid over level 22's header; an FG kind-3 floor (tile 3) on `floorRow` when given — its tile
    /// hot rect (`TileHotRects`, kind 3) is the cell's lower half: row 12's surface is y 400.
    private func world(floorRow: Int? = nil) throws -> SpriteWorld {
        let w = SpriteWorld(level: try level22())
        var fg = [UInt16](repeating: 0, count: 16 * 16)
        if let r = floorRow { for c in 0..<16 { fg[r * 16 + c] = 4 } }
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: fg),
                           bg: TileMap(width: 16, height: 16, cells: [UInt16](repeating: 0, count: 16 * 16)),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        return w
    }

    /// A made-up carpet record (`type` 1080 / 1081, p1, p2) set up through `SetupFaces` on the world's stream and
    /// inserted, with `.BoxClean`'s centre.
    private func carpet(_ w: SpriteWorld, type: Int16, p1: Int16 = 0, p2: Int16 = 0, x: Int = 100,
                        y: Int = 100) throws -> Int {
        let p = Placement(index: -1, flag: 1, byte1: 0, type: type, p1: p1, p2: p2, p3: 0, p4: 0, y: Int16(y),
                          x: Int16(x))
        var s = try SetupFaces.setup(p, context: SetupFaces.Context(level: w.level, playerX: 0), rng: &w.rng).slot
        let r = s.hotRect
        s.centre = SpriteSlot.Point(x: s.x + r.left + ((r.right - r.left) >> 1), y: s.y + r.top + ((r.bottom - r.top) >> 1))
        return w.active.insert(s)
    }

    /// A player slot (the player's Handle, the standard hot rect) at (x, y), made the world's player.
    private func player(_ w: SpriteWorld, x: Int, y: Int) -> Int {
        var s = SpriteSlot(type: 0, x: x, y: y, layer: 10)
        s.handler = .player
        s.hasHit = true
        s.hotRect = HandleKeys.standardHotRect
        let r = s.hotRect
        s.centre = SpriteSlot.Point(x: x + r.left + ((r.right - r.left) >> 1), y: y + r.top + ((r.bottom - r.top) >> 1))
        let id = w.active.insert(s)
        w.playerID = id
        return id
    }

    /// One `.HandleBoxSprite` (the arm and the tail) of sprite `id`.
    private func handle(_ w: SpriteWorld, _ id: Int) {
        var lights = LightTable()
        BoxSprite.handle(world: w, id: id, solver: TileSolver(world: w), lights: &lights, effects: 1)
    }

    /// `.HitBoxSprite(carpet, other)`.
    private func hit(_ w: SpriteWorld, _ id: Int, by other: Int) {
        var lights = LightTable()
        BoxSprite.hit(w, id: id, other: other, lights: &lights)
    }

    /// A made-up carpet woken by the player: a 0x438 at (100, 100) and a player touching it.
    private func wokenCarpet(_ w: SpriteWorld, p1: Int16 = 0, p2: Int16 = 0) throws -> (carpet: Int, player: Int) {
        let c = try carpet(w, type: 1080, p1: p1, p2: p2)
        let pl = player(w, x: 100 + 0x34 - 0x26 - 4, y: 100 - 0x40)
        hit(w, c, by: pl)
        XCTAssertEqual(w.active.record(id: c)?.type, 0x439, "the wake")
        return (c, pl)
    }

    /// The fixture opened (level 22, nothing left out, the player at `start`, seed 1), ticked until its session
    /// exists. `now` is the next tick.
    private func open22(start: (x: Int, y: Int) = CarpetTests.start) throws -> (run: LevelRun, now: UInt32) {
        let run = try LevelFixture.open(level: 22, leaveOut: Self.level22LeaveOut, start: start)
        var now: UInt32 = 0
        while run.session == nil && now < 4000 {
            _ = try run.tick(now: now, input: FrontInput())
            now &+= 1
        }
        _ = try XCTUnwrap(run.session, "level 22 opens with nothing left out")
        return (run, now)
    }

    /// Ticks `run` until one more `.GameLoop` iteration has run.
    private func iterate(_ run: LevelRun, _ now: inout UInt32, input: FrontInput = FrontInput()) throws {
        let before = run.iterations
        let limit = now &+ 4000
        while run.iterations == before && now < limit {
            _ = try run.tick(now: now, input: input)
            now &+= 1
        }
        XCTAssertEqual(run.iterations, before + 1, "an iteration within 4000 ticks")
    }

    /// The carpet's sprite on the fixture (record 486, the Box Handle).
    private func carpetID(_ run: LevelRun) throws -> Int {
        let w = try XCTUnwrap(run.session).world
        return try XCTUnwrap(w.active.sprites.first { Int($0.recordIndex) == Self.carpetRecord && $0.handler == .box }?.id,
                             "the carpet is on the active list")
    }

    /// Iterates the fixture until the carpet is 0x439; returns that iteration (nil when it never wakes).
    private func runToWake(_ run: LevelRun, _ now: inout UInt32, limit: Int = 300) throws -> Int? {
        let w = try XCTUnwrap(run.session).world
        let c = try carpetID(run)
        while run.iterations < limit {
            try iterate(run, &now)
            if w.active.record(id: c)?.type == 0x439 { return run.iterations }
        }
        return nil
    }

    // MARK: - Setup

    /// The rolled carpet's Setup (M l. 59078–59103) on the only shipped carpet: level 22's placement 486.
    func testCarpetSetupRolled() throws {
        // The data: one 1080 in the whole game (level 22, placement 486, p1…p4 0) and no 1081 anywhere — read raw from
        // every `Mlvl` (record i at 4 + 16·i: flag u8, byte1 u8, type i16, …).
        var placed: [[Int]] = []
        for res in try resources().world.resources(of: "Mlvl") {
            let d = [UInt8](res.data)
            for i in 0..<LevelFile.placementCount {
                let o = 4 + 16 * i
                guard o + 16 <= d.count, d[o] == 1 else { continue }
                let t = Int(Int16(bitPattern: UInt16(d[o + 2]) << 8 | UInt16(d[o + 3])))
                if t == 1080 || t == 1081 { placed.append([Int(res.id), i, t]) }
            }
        }
        XCTAssertEqual(placed, [[22, 486, 1080]])
        let L = try level22()
        let p = L.placements[Self.carpetRecord]
        XCTAssertEqual([Int(p.flag), Int(p.type), Int(p.p1), Int(p.p2), Int(p.p3), Int(p.p4), Int(p.x), Int(p.y)],
                       [1, 1080, 0, 0, 0, 0, 7849, 2017])

        var rng = FastRand(seed: 1)
        let e = try SetupFaces.setup(p, context: SetupFaces.Context(level: L, playerX: 0), rng: &rng)
        XCTAssertEqual(rng.seed, FastRand(seed: 1).seed, "the rolled carpet draws no FastRand")
        XCTAssertEqual(e.spriteClass, .box)
        // `+0xc0` is left 0: the Handle faces it from the cache set 0x438 (`_DAT_100a0a10`, 6 × 0x71×0x18, one a row,
        // flag 0 → clut 200; `.InitBoxSprite` M l. 58816), cell `+0x46 >> 1` = 0.
        XCTAssertEqual(e.sheet, SetupFaces.Sheet(pict: 0x438, count: 6, cellWidth: 0x71, cellHeight: 0x18, columns: 1,
                                                 clut: 200))
        XCTAssertEqual(e.source, .handle)
        XCTAssertEqual(e.faceIndex, 0)
        let s = e.slot
        // The head (M l. 58934–58950) and the arm: `+0x46 = 0`, `+0x1f8 = 0`, SetRect(0x34, 4, 0x35, 0xc) (M l.
        // 59080–59083); one-way, gravity 0, `+0x138 = 0`, `+0xa6 = 0` (59090–59093); `+0x14c` = p2·30, 0 → −1
        // (59094–59098); `+0x150` = p1 (59099–59100); `+0xb8 = p1 + 0x10000` (59101); `+0x15c` never set (0).
        XCTAssertEqual(s.phase, 0)
        XCTAssertFalse(s.hasTileHit, "no tile hit on the rolled carpet")
        XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 4, left: 0x34, bottom: 0xc, right: 0x35))
        XCTAssertTrue(s.oneWay)
        XCTAssertEqual([Int(s.gravity), Int(s.pushMass), Int(s.counterA6)], [0, 0, 0])
        XCTAssertEqual(s.classTimer, -1, "p2 0 → −1: never counts down")
        XCTAssertEqual([s.classWord150, s.classWord154, s.classWord158, s.classWord15c], [0, 0, 0, 0])
        XCTAssertEqual(s.mode, 0x10000)
        XCTAssertTrue(s.hasHit)
        XCTAssertEqual(s.handler, .box)
        XCTAssertEqual(s.layer, 2)
        XCTAssertEqual(s.hp, 600)
        XCTAssertEqual(s.pushForce, 0x80, "the tail `LAB_1006cf1c`")
        XCTAssertEqual([s.x, s.y, Int(s.x256), Int(s.y256)], [7849, 2017, 7849 << 8, 2017 << 8])
        // The cache mark `_DAT_100a0a10 + 1 = 1` (M l. 59079): set #27 (0-based 26), for both types.
        XCTAssertEqual(CachedFaces.markedRecords(type: 0x438), [.set(26)])
        XCTAssertEqual(CachedFaces.markedRecords(type: 0x439), [.set(26)])
        XCTAssertEqual(CachedFaces.record(.set(26)).pict, 0x438)
        XCTAssertEqual(CachedFaces.record(.set(26)).faces, 6)
        // Its Handle runs (the arm is built).
        XCTAssertTrue(BoxSprite.handleBuilt(0x438))
        XCTAssertTrue(BoxSprite.handleBuilt(0x439))
    }

    /// The unrolled carpet's Setup (M l. 59084–59089): the tile hit set, `+0x46 = FastRand(4) + 2`, SetRect(0x12, 4,
    /// 0x5b, 0x12). Made-up records (1081 is placed nowhere; it is reached only by the wake).
    func testCarpetSetupUnrolledDrawsR4() throws {
        let L = try level22()
        var seen: Set<Int16> = []
        for seed: Int32 in 1...64 where seen.count < 4 {
            var rng = FastRand(seed: seed)
            var ref = rng
            let r4 = ref.next(4)
            let p = Placement(index: -1, flag: 1, byte1: 0, type: 1081, p1: 7, p2: 3, p3: 0, p4: 0, y: 200, x: 300)
            let e = try SetupFaces.setup(p, context: SetupFaces.Context(level: L, playerX: 0), rng: &rng)
            XCTAssertEqual(rng.seed, ref.seed, "seed \(seed): exactly one draw, FastRand(4)")
            XCTAssertEqual(e.slot.phase, r4 + 2, "seed \(seed)")
            XCTAssertEqual(e.faceIndex, Int((r4 + 2) >> 1), "seed \(seed): cell +0x46 >> 1")
            XCTAssertEqual(e.source, .handle)
            seen.insert(r4)
        }
        XCTAssertEqual(seen, [0, 1, 2, 3], "every R(4)")
        var rng = FastRand(seed: 1)
        let p = Placement(index: -1, flag: 1, byte1: 0, type: 1081, p1: 7, p2: 3, p3: 0, p4: 0, y: 200, x: 300)
        let s = try SetupFaces.setup(p, context: SetupFaces.Context(level: L, playerX: 0), rng: &rng).slot
        XCTAssertTrue(s.hasTileHit, "the tile hit set")
        XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 4, left: 0x12, bottom: 0x12, right: 0x5b))
        XCTAssertTrue(s.oneWay)
        XCTAssertEqual([Int(s.gravity), Int(s.pushMass), Int(s.counterA6)], [0, 0, 0])
        XCTAssertEqual(s.classTimer, 90, "p2 3 · 30")
        XCTAssertEqual(s.classWord150, 7, "p1")
        XCTAssertEqual(s.mode, 0x10007, "p1 + 0x10000")
        XCTAssertEqual(s.classWord15c, 0)
        // p2 0 → −1 on a 1081 too; a negative p1 is sign-extended (`+0x150` an i32 from the record's i16).
        var r2 = FastRand(seed: 1)
        let q = Placement(index: -1, flag: 1, byte1: 0, type: 1081, p1: -2, p2: 0, p3: 0, p4: 0, y: 200, x: 300)
        let t = try SetupFaces.setup(q, context: SetupFaces.Context(level: L, playerX: 0), rng: &r2).slot
        XCTAssertEqual(t.classTimer, -1)
        XCTAssertEqual(t.classWord150, -2)
        XCTAssertEqual(t.mode, 0xfffe)
    }

    // MARK: - the wake

    /// `.HitBoxSprite`'s last arm (M l. 61470–61476): the player (`+0x4c == PTR_PTR_100a052c`) against a 0x438 —
    /// `+0x46 = 2`, type 0x439, the tile hit set, `+0x15c = 0x1e`, `+0x185 = 0`. Then on level 22's fixture: the
    /// player started on the ledge wakes the shipped carpet.
    func testCarpetWakesOnPlayer() throws {
        let w = try world()
        let c = try carpet(w, type: 1080)
        // Not the player: an Effect (no arm of `.HitBoxSprite`) leaves it rolled.
        var e = SpriteSlot(type: 0x442, x: 100, y: 100)
        e.handler = .effect
        let eid = w.active.insert(e)
        hit(w, c, by: eid)
        XCTAssertEqual(w.active.record(id: c)?.type, 0x438)
        let pl = player(w, x: 100, y: 40)
        hit(w, c, by: pl)
        var s = try XCTUnwrap(w.active.record(id: c))
        XCTAssertEqual(s.type, 0x439)
        XCTAssertEqual(s.phase, 2)
        XCTAssertTrue(s.hasTileHit)
        XCTAssertEqual(s.classWord15c, 0x1e)
        XCTAssertFalse(s.oneWay, "the wake's `+0x185 = 0` (M l. 61475)")
        // Nothing else: the rect stays the rolled one until the next Handle re-sets it; the count and mode as set up.
        XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 4, left: 0x34, bottom: 0xc, right: 0x35))
        XCTAssertEqual([s.classTimer, Int32(bitPattern: s.mode)], [-1, 0x10000])
        // A 0x439 is not woken again (`sVar9 == 0x438` only): one Handle (`+0x15c` 29), then the player again.
        handle(w, c)
        XCTAssertEqual(w.active.record(id: c)?.classWord15c, 29)
        hit(w, c, by: pl)
        s = try XCTUnwrap(w.active.record(id: c))
        XCTAssertEqual([Int(s.phase), Int(s.classWord15c)], [3, 29])

        // Level 22's fixture: the player started above the shipped carpet drops onto it and wakes it.
        var (run, now) = try open22()
        let fw = try XCTUnwrap(run.session).world
        let fc = try carpetID(run)
        XCTAssertEqual(fw.active.record(id: fc)?.type, 0x438, "rolled at the level start")
        let k = try XCTUnwrap(try runToWake(run, &now), "the carpet wakes")
        let a = try XCTUnwrap(fw.active.record(id: fc))
        XCTAssertEqual(a.type, 0x439)
        XCTAssertEqual([Int(a.phase), Int(a.classWord15c)], [2, 0x1e])
        XCTAssertTrue(a.hasTileHit)
        XCTAssertFalse(a.oneWay)
        XCTAssertEqual(k, Self.wakeIteration, "measured: the iteration the player wakes it")
    }

    /// The iteration of the fixture in which the player wakes the carpet (measured at 6A-CP: he falls 5 px, from y
    /// 1931 to 1936, his rect's bottom reaching the carpet's top 2021).
    static let wakeIteration = 3

    // MARK: - the Handle

    /// After the wake: `+0x15c` 30 counts down; < 16 → vy + 0x1e, else vy − 0x1e — 14 frames up, then 16 down; vx 0 and
    /// no tile hit while `+0x15c > 0`; at 0 the tile hit and one-way back and the damping starts. The unroll step:
    /// `+0x46 > 0` → + 1, > 11 → 2, the face cell `+0x46 >> 1` (M l. 60290–60297); the 0x439 rect re-set each Handle
    /// (M l. 60313–60315). Measured on level 22's fixture (the player riding it), against the dump's arithmetic.
    func testCarpetRiseAndSink() throws {
        var (run, now) = try open22()
        let w = try XCTUnwrap(run.session).world
        let c = try carpetID(run)
        _ = try XCTUnwrap(try runToWake(run, &now))
        var vy: Int32 = try XCTUnwrap(w.active.record(id: c)).vy
        var phase: Int16 = 2
        let unrolled = IdleSprites.Rect(top: 4, left: 0x12, bottom: 0x12, right: 0x5b)
        for k in 1...30 {
            try iterate(run, &now)
            let s = try XCTUnwrap(w.active.record(id: c))
            phase += 1
            if phase > 11 { phase = 2 }
            let left = Int32(30 - k)
            vy += left < 16 ? 0x1e : -0x1e
            if left == 0 { vy = Int32((Double(vy) * 0.8).rounded(.towardZero)) }
            XCTAssertEqual(s.classWord15c, left, "Handle \(k)")
            XCTAssertEqual(s.vy, vy, "Handle \(k)")
            XCTAssertEqual(s.phase, phase, "Handle \(k)")
            XCTAssertEqual(s.face, FaceRef(pict: 0x438, index: Int(phase >> 1), set: .encoded), "Handle \(k)")
            XCTAssertEqual(s.hotRect, unrolled, "Handle \(k)")
            if left > 0 {
                XCTAssertEqual(s.vx, 0, "Handle \(k): vx 0 while rising and sinking")
                XCTAssertFalse(s.hasTileHit, "Handle \(k)")
                XCTAssertFalse(s.oneWay, "Handle \(k)")
            } else {
                XCTAssertTrue(s.hasTileHit, "Handle \(k): the tile hit back")
                XCTAssertTrue(s.oneWay, "Handle \(k): one-way back")
            }
            XCTAssertEqual(s.mode, 0x10000, "Handle \(k)")
        }
        // 14 frames up (vy −0x1e … −14·0x1e), then up to + 2·0x1e: 60 → 48 on the 30th, damped.
        XCTAssertEqual(w.active.record(id: c)?.vy, 48)
    }

    /// The rolled carpet's Setup clears the tile hit and never sets `+0x15c`; its first Handle (`+0x15c == 0`) gives
    /// the tile hit back and one-way (M l. 60309–60312), keeps cell 0 and the rolled rect (the rect re-set is 0x439's
    /// only), and its tail still runs `.ApplyGravityAndSeparateFromTiles` with gravity 0 (forced for 0x438 / 0x439,
    /// M l. 61161–61164) — through the tile callback now set.
    func testRolledCarpetGetsTileHitOnFirstHandle() throws {
        // On a floor (row 12, the surface at y 400): the rolled rect's bottom 0xc at 404 lies inside it.
        let w = try world(floorRow: 12)
        let c = try carpet(w, type: 1080, x: 100, y: 400 - 8)
        XCTAssertEqual(w.active.record(id: c)?.hasTileHit, false)
        handle(w, c)
        let s = try XCTUnwrap(w.active.record(id: c))
        XCTAssertTrue(s.hasTileHit, "the tile hit back on the first Handle")
        XCTAssertTrue(s.oneWay)
        XCTAssertEqual(s.type, 0x438)
        XCTAssertEqual(s.phase, 0, "`+0x46` 0 stays 0")
        XCTAssertEqual(s.face, FaceRef(pict: 0x438, index: 0, set: .encoded))
        XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 4, left: 0x34, bottom: 0xc, right: 0x35), "no rect re-set")
        XCTAssertEqual([s.classWord15c, s.classWord154, s.classTimer], [0, 0, -1])
        // The separation ran with the tile callback: the rect's bottom (404) out of the floor, on its surface (400).
        XCTAssertEqual(s.y + s.hotRect.bottom, 400, "separated by the forced `.ApplyGravityAndSeparateFromTiles`")
        // The same carpet with the arm's tile hit stubbed off (its Setup's state), through the tail alone: the gravity-0
        // pass runs without the callback and leaves it in the floor.
        let w2 = try world(floorRow: 12)
        let c2 = try carpet(w2, type: 1080, x: 100, y: 400 - 8)
        var lights = LightTable()
        BoxSprite.tail(w2, id: c2, solver: TileSolver(world: w2), lights: &lights, effects: 1)
        let t = try XCTUnwrap(w2.active.record(id: c2))
        XCTAssertFalse(t.hasTileHit)
        XCTAssertEqual(t.y, 400 - 8, "no callback, no separation")
    }

    /// `+0x15c < 1` → vy = fctiwz(vy · 0.8) (f64 `100a1ae8` = 0.8, M l. 60369–60374) every frame once the bob ends; vx
    /// decays: |vx| ≤ 0x80 → 0, else 0x80 toward 0 (M l. 60357–60368). A made-up carpet woken on an empty grid.
    func testCarpetVerticalDampingAfterBob() throws {
        // The port's factor is the binary's f64 at `100a1ae8` (`0x3fe999999999999a`), i.e. the double nearest 0.8.
        XCTAssertEqual(BoxSprite.carpetDamping.bitPattern, 0x3fe9_9999_9999_999a)
        let w = try world()
        let (c, _) = try wokenCarpet(w)
        for _ in 1...30 { handle(w, c) }
        var s = try XCTUnwrap(w.active.record(id: c))
        XCTAssertEqual([s.classWord15c, s.vy], [0, 48], "the bob ends on the 30th Handle, damped once")
        // Each later Handle: vy · 0.8 toward zero — 48, 38, 30, 24, 19, 15, 12, 9, 7, 5, 4, 3, 2, 1, 0.
        var vys: [Int32] = []
        for _ in 0..<15 { handle(w, c); vys.append(try XCTUnwrap(w.active.record(id: c)).vy) }
        XCTAssertEqual(vys, [38, 30, 24, 19, 15, 12, 9, 7, 5, 4, 3, 2, 1, 0, 0])
        // Negative: toward zero too (−50 → −40, −40 → −32, −32 → −25).
        w.active.update(id: c) { $0.vy = -50 }
        vys = []
        for _ in 0..<3 { handle(w, c); vys.append(try XCTUnwrap(w.active.record(id: c)).vy) }
        XCTAssertEqual(vys, [-40, -32, -25])
        // vx: 0x200 → 0x180 → 0x100 → 0x80 → 0 (≤ 0x80 → 0); −0x81 → −1 → 0; the friction is 0 (`+0x114`).
        w.active.update(id: c) { $0.vx = 0x200; $0.vy = 0 }
        var vxs: [Int32] = []
        for _ in 0..<5 { handle(w, c); vxs.append(try XCTUnwrap(w.active.record(id: c)).vx) }
        XCTAssertEqual(vxs, [0x180, 0x100, 0x80, 0, 0])
        w.active.update(id: c) { $0.vx = -0x81 }
        vxs = []
        for _ in 0..<2 { handle(w, c); vxs.append(try XCTUnwrap(w.active.record(id: c)).vx) }
        XCTAssertEqual(vxs, [-1, 0])
        // While `+0x15c > 0` there is no damping: a freshly woken carpet's first Handle is exactly − 0x1e.
        let w2 = try world()
        let (c2, _) = try wokenCarpet(w2)
        w2.active.update(id: c2) { $0.vy = -100; $0.vx = 0x200 }
        handle(w2, c2)
        XCTAssertEqual(w2.active.record(id: c2)?.vy, -130)
        s = try XCTUnwrap(w2.active.record(id: c2))
        XCTAssertEqual(s.vx, 0, "vx 0 while `+0x15c > 0` (M l. 60306), not the decay's 0x180")
        // `.FootPressure` is skipped for 0x438 / 0x439 (M l. 61154–61157): grounded last frame (`+0xcd`), vx 0x200 →
        // y256 moves by vy only (a crate would sink by |vx|). `+0xcd` is set through `+0xce`: the Handle's head
        // (`.StandardSpriteHandles`) copies `+0xce` into `+0xcd` before the tail reads it.
        let w3 = try world()
        let (c3, _) = try wokenCarpet(w3)
        for _ in 1...30 { handle(w3, c3) }
        w3.active.update(id: c3) { $0.vx = 0x200; $0.vy = 0; $0.groundKind = 1 }
        let y0 = try XCTUnwrap(w3.active.record(id: c3)).y256
        handle(w3, c3)
        XCTAssertEqual(w3.active.record(id: c3)?.y256, y0, "no `.FootPressure` sink")
    }

    // MARK: - the ride count (made-up carpets, p2 > 0)

    /// Ridden (`+0x186`) or riding (`+0x154`) and `+0x14c ≥ 0`: `+0x154 = 1`, `+0x14c − 1` (floor 0); on frames with
    /// `+0xa6 < 1` and the paint counter & 3 = 0 (M l. 60323): `+0xa6` = 10 when `+0x14c < 91` else 30, `+0x158 = 6`,
    /// `+0xb8 = 0x10009`; other frames: `+0xa6 − 1`, then `+0x158 < 1` → `p1 + 0x10000`, else < 4 → 0x10008, else
    /// 0x10009, `+0x158 − 1` (M l. 60316–60352). A MADE-UP carpet (1080, p1 3, p2 4 → `+0x14c` 120): the shipped one
    /// has p2 0.
    func testCarpetRideCountAndFlash() throws {
        let w = try world()
        let (c, _) = try wokenCarpet(w, p1: 3, p2: 4)
        XCTAssertEqual(w.active.record(id: c)?.classTimer, 120)
        // Not ridden: nothing counts.
        for _ in 0..<3 { handle(w, c) }
        var s = try XCTUnwrap(w.active.record(id: c))
        XCTAssertEqual([s.classTimer, s.classWord154, Int32(s.counterA6), s.classWord158], [120, 0, 0, 0])
        XCTAssertEqual(s.mode, 0x10003)
        // Ridden once (`+0x186`, `.RectBounce`'s): from then on it counts every Handle (`+0x154 = 1`), ridden or not.
        w.active.update(id: c) { $0.ridingLatch = true }
        w.paintCounter = 1
        // The model, line by line from the dump.
        var t: Int32 = 120, a6: Int16 = 0, f158: Int32 = 0, mode: UInt32 = 0x10003
        var gates: [Int] = []
        for k in 1...140 {
            if k == 2 { w.active.update(id: c) { $0.ridingLatch = false } }
            handle(w, c)
            t = max(t - 1, 0)
            if a6 < 1 && w.paintCounter & 3 == 0 {
                a6 = t < 0x5b ? 10 : 30
                f158 = 6
                mode = 0x10009
                gates.append(k)
            } else {
                a6 -= 1
                if f158 < 1 { mode = 0x10003 } else { mode = f158 < 4 ? 0x10008 : 0x10009; f158 -= 1 }
            }
            s = try XCTUnwrap(w.active.record(id: c))
            XCTAssertEqual(s.classWord154, 1, "Handle \(k)")
            XCTAssertEqual([s.classTimer, Int32(s.counterA6), s.classWord158], [t, Int32(a6), f158], "Handle \(k)")
            XCTAssertEqual(s.mode, mode, "Handle \(k)")
            XCTAssertEqual(s.dead, t == 0 && gates.last == k, "Handle \(k)")
            if s.dead { break }
            w.paintCounter &+= 1                                   // `.PaintFrameWrap`'s count, every iteration
        }
        // The gate needs `+0xa6 < 1` AND the counter's low bits 0: off the 4-beat the cooldown runs on below 0. Counter
        // 1 on Handle 1: −1, −2, −3, then Handle 4 (counter 4, count 116 ≥ 91) → 30; 0 on Handle 34, −1 on 35, Handle 36
        // (count 84 < 91) → 10; 0 on 46, −1 on 47, Handle 48.
        XCTAssertEqual(Array(gates.prefix(3)), [4, 36, 48], "the flash gates (the paint counter & 3 == 0)")
        XCTAssertTrue(s.dead, "the count ran out within 140 Handles")
        // The cooldown's threshold (M l. 60324): a gate frame whose decremented count is 91 sets `+0xa6` 30, one at 90
        // sets 10. Made-up carpets with the count stored right before a gate.
        for (before, cooldown) in [(Int32(92), Int16(30)), (Int32(91), Int16(10))] {
            let g = try world()
            let (gc, _) = try wokenCarpet(g, p1: 3, p2: 4)
            g.active.update(id: gc) { $0.ridingLatch = true; $0.classTimer = before }
            g.paintCounter = 0
            handle(g, gc)
            let t = try XCTUnwrap(g.active.record(id: gc))
            XCTAssertEqual([t.classTimer, Int32(t.counterA6)], [before - 1, Int32(cooldown)], "count \(before - 1)")
        }
    }

    /// At `+0x14c` = 0 on a gate frame: `+0xe9 = 1` and `.ExplodeFaceIntoParticles(+0xc0, (+0xa, +0xc), 1, 2, 4, 100,
    /// 100)` (M l. 60331–60336). A MADE-UP carpet (1081 via the wake, p2 1 → 30 frames), a synthetic face to walk.
    func testCarpetBurstsAtZero() throws {
        func tok(_ op: UInt32, _ n: Int) -> [UInt8] {
            let t = op << 24 | UInt32(n)
            return [UInt8(t >> 24), UInt8(t >> 16 & 0xff), UInt8(t >> 8 & 0xff), UInt8(t & 0xff)]
        }
        // Two rows of four literal pixels: xStep 1 → four particles a used row, yStep 2 → the second row skipped, style
        // 100 (four draws each).
        let face = ParticleFace(frame: [0, 0, 2, 4], bounds: [0, 0, 2, 4],
                                tokens: tok(1, 8) + tok(2, 4) + [10, 11, 12, 13]
                                    + tok(1, 8) + tok(2, 4) + [20, 21, 22, 23] + tok(0, 0))
        // The face walked is `+0xc0` as this Handle set it: `+0x46` 2 at the wake, + 1 a Handle, > 11 → 2 (M l.
        // 60290–60297) — 9 on Handle 37, the cell 9 >> 1 = 4 of the set 0x438. Only that cell has pixels here.
        let w = try world()
        w.particleFaces = ParticleFaces(sprite: { $0.pict == 0x438 && $0.index == 4 ? face : nil })
        let (c, _) = try wokenCarpet(w, p2: 1)
        XCTAssertEqual(w.active.record(id: c)?.classTimer, 30)
        w.active.update(id: c) { $0.ridingLatch = true }
        w.paintCounter = 0
        var burst = 0
        for k in 1...80 {
            let before = w.active.record(id: c)
            let rng = w.rng, n0 = w.particles.counters.count
            handle(w, c)
            let s = try XCTUnwrap(w.active.record(id: c))
            if s.dead {
                burst = k
                // The burst: four particles from the face the Handle set this frame (cell `+0x46 >> 1`), at the
                // position before this Handle's tail moved it, (y + 1, x … x + 3).
                let b = try XCTUnwrap(before)
                XCTAssertEqual(b.classTimer, 0, "the count had reached 0")
                XCTAssertEqual(s.classTimer, 0)
                XCTAssertEqual(w.paintCounter & 3, 0, "on a gate frame")
                XCTAssertEqual(s.mode, 0x10009)
                XCTAssertEqual(w.particles.counters.count - n0, 4)
                var ref = rng
                for _ in 0..<16 { _ = ref.next(1) }
                XCTAssertEqual(w.rng.seed, ref.seed, "four draws a particle")
                let r = w.particles.records.filter { $0.alive }
                XCTAssertEqual(r.count, 4)
                XCTAssertEqual(Set(r.map(\.shape)), [4])
                XCTAssertEqual(Set(r.map { Int($0.x >> 8) }), Set((0..<4).map { b.x + $0 }))
                XCTAssertEqual(Set(r.map { Int($0.y >> 8) }), [b.y + 1], "the first row only (yStep 2)")
                XCTAssertEqual(r.map(\.kind), [10, 11, 12, 13].map { Int16(-($0 + 0x100)) }, "the first row's pixels")
                // Gravity 100 (the burst's sixth argument) + each particle's R(30), its fourth draw.
                var g = rng, gravities: [Int16] = []
                for _ in 0..<4 {
                    _ = g.next(0x14); _ = g.next(0x2ee); _ = g.next(100)
                    gravities.append(100 + Int16(g.next(0x1e)))
                }
                XCTAssertEqual(r.map(\.gravity), gravities, "gravity 100 + R(30)")
                break
            }
            XCTAssertEqual(w.particles.counters.count, n0, "Handle \(k): no burst before 0")
            w.paintCounter &+= 1
        }
        // Counter 0 on Handle 1: gates on Handles 1, 13, 25 (`+0xa6` 10 each, the count < 91), the count 30 → 0 on
        // Handle 30, `+0xa6` 0 on 35, −1 on 36 (counter 35), and Handle 37 (counter 36) is the gate that bursts it.
        XCTAssertEqual(burst, 37)
        // Dead: the Box Handle returns at once (`+0xe9`), nothing more moves.
        let dead = try XCTUnwrap(w.active.record(id: c))
        handle(w, c)
        XCTAssertEqual(w.active.record(id: c), dead)
    }

    /// The shipped carpet (p2 0 → `+0x14c = −1`): the ride block never runs — `+0x154` stays 0, the mode stays
    /// 0x10000, it never flashes or bursts (the test `-1 < +0x14c`, M l. 60316–60317) — though the player rides it.
    /// Level 22's fixture, 300 iterations after the wake.
    func testCarpetLevel22NeverCounts() throws {
        var (run, now) = try open22()
        let w = try XCTUnwrap(run.session).world
        let c = try carpetID(run)
        _ = try XCTUnwrap(try runToWake(run, &now))
        var ridden = 0, carpetFlag = 0
        for k in 1...300 {
            try iterate(run, &now)
            let s = try XCTUnwrap(w.active.record(id: c), "iteration \(k): the carpet lives")
            XCTAssertEqual([s.classTimer, s.classWord154, s.classWord158, Int32(s.counterA6)], [-1, 0, 0, 0],
                           "iteration \(k)")
            XCTAssertEqual(s.mode, 0x10000, "iteration \(k)")
            XCTAssertFalse(s.dead, "iteration \(k)")
            if s.ridingLatch { ridden += 1 }
            if w.player.carpet { carpetFlag += 1 }
        }
        XCTAssertGreaterThan(ridden, 0, "the player rode it (`+0x186`)")
        XCTAssertGreaterThan(carpetFlag, 0, "the player's carpet flag `PTR_DAT_100a05a4`")
    }

    // MARK: - the player's half

    /// The player's built half (proven, not changed): row 3 of `.HandlePlayerSprite` (M l. 44532–44552) — riding a
    /// 0x438 / 0x439 sets the carpet flag, the camera latch `*_DAT_1009fd34 = 1`, idle 0 and vx 0; and the `.HandleKeys`
    /// carpet block (M l. 47249–47308): L/R vx ∓0x140 (cap ±0xc80; LEFT at its cap falls through to RIGHT), UP/DOWN vy
    /// ∓0x100 (cap ∓4000; UP skips DOWN), none while the steering lock `_DAT_100a059c` ≥ 1, then the centre-gap close
    /// (1 px each, while the carpet's |vx| < 0x100). On level 22's fixture the keys move the woken carpet.
    func testCarpetSteeringMovesCarpet() throws {
        let w = try world()
        let (c, pl) = try wokenCarpet(w)
        // Row 3: the ridden sprite's type decides the flag; the latch, idle 0 and vx 0 for any ridden sprite.
        w.player.ridden = c
        w.player.idle = 7
        w.active.update(id: pl) { $0.vx = 0x300 }
        Player.riding(w, id: pl)
        XCTAssertTrue(w.player.carpet)
        XCTAssertTrue(w.player.cameraSnapVeto)
        XCTAssertEqual(w.player.idle, 0)
        XCTAssertEqual(w.active.record(id: pl)?.vx, 0, "carpet → vx 0")
        let crate = w.active.insert(SpriteSlot(type: 0xc12, x: 0, y: 0))
        w.player.ridden = crate
        w.active.update(id: pl) { $0.vx = 0x300 }
        Player.riding(w, id: pl)
        XCTAssertFalse(w.player.carpet)
        XCTAssertEqual(w.active.record(id: pl)?.vx, 0x300)
        w.player.ridden = nil
        Player.riding(w, id: pl)
        XCTAssertFalse(w.player.carpet)
        // A rolled 0x438 ridden sets the flag too (`!= 0x438 && != 0x439` → 0, M l. 44538–44540).
        w.player.ridden = try carpet(w, type: 1080, x: 300)
        Player.riding(w, id: pl)
        XCTAssertTrue(w.player.carpet, "a ridden 0x438")
        w.player.ridden = nil
        Player.riding(w, id: pl)

        // The player's tile arm (raw `100550e8..10055174`): an FG hit while on a carpet → the player's `+0xdc` = the
        // ridden carpet; the carpet's `+0xa` = the player's `+0xa` + his rect bottom − the carpet's rect top (i16), its
        // `+0x1c` = that << 8; its vx 0 when the player's vx < 0x100, a SIGNED compare (`eqv`/`subfc`/`addze`).
        for (pvx, stops) in [(Int32(0xff), true), (Int32(0x100), false), (Int32(-0x200), true)] {
            let g = try world(floorRow: 12)
            let (gc, gp) = try wokenCarpet(g)
            g.active.update(id: gc) { $0.vx = 0x300 }
            // The player 3 px into the floor (surface y 400; his rect's bottom y + 0x55), falling.
            g.active.update(id: gp) { p in
                p.x = 100; p.x256 = 100 << 8
                p.y = 400 - 0x55 + 3; p.y256 = Int32(400 - 0x55 + 3) << 8
                p.vx = pvx; p.vy = 0x200
                p.ridden = nil
            }
            g.player.carpet = true
            g.player.ridden = gc
            TileSolver(world: g).separateFromTiles(gp, pass: PlayerTiles.hit(keys: []))
            let p = try XCTUnwrap(g.active.record(id: gp)), k = try XCTUnwrap(g.active.record(id: gc))
            XCTAssertEqual(g.player.carpetLock, 2, "player vx \(pvx): the hit")
            XCTAssertEqual(p.ridden, gc, "player vx \(pvx)")
            XCTAssertEqual(k.y, p.y + 0x55 - k.hotRect.top, "player vx \(pvx): the carpet under his feet")
            XCTAssertEqual(k.y256, Int32(k.y) << 8, "player vx \(pvx)")
            XCTAssertEqual(k.vx, stops ? 0 : 0x300, "player vx \(pvx)")
        }

        // The keys block, carpet and player centres equal (no gap close).
        func steer(_ keys: InputActions, vx: Int32, vy: Int32, lock: Int16 = 0) -> [Int32] {
            w.player.carpetLock = lock
            w.active.update(id: c) { $0.vx = vx; $0.vy = vy; $0.centre.x = 500 }
            w.active.update(id: pl) { $0.centre.x = 500 }
            HandleKeys.carpetSteering(w, id: pl, carpet: c, keys: keys)
            let s = w.active.record(id: c)!
            return [s.vx, s.vy]
        }
        XCTAssertEqual(steer(.right, vx: 0, vy: 0), [0x140, 0])
        XCTAssertEqual(w.player.facing, 2)
        XCTAssertEqual(steer(.left, vx: 0, vy: 0), [-0x140, 0])
        XCTAssertEqual(w.player.facing, 1)
        XCTAssertEqual(steer(.right, vx: 0xc7f, vy: 0), [0xc7f + 0x140, 0], "below the cap: one more push")
        XCTAssertEqual(steer(.right, vx: 0xc80, vy: 0), [0xc80, 0], "at the cap")
        XCTAssertEqual(steer(.left, vx: -0xc7f, vy: 0), [-0xc7f - 0x140, 0])
        XCTAssertEqual(steer([.left, .right], vx: -0xc80, vy: 0), [-0xc80 + 0x140, 0], "LEFT at its cap → RIGHT")
        XCTAssertEqual(steer([.left, .right], vx: 0, vy: 0), [-0x140, 0], "LEFT taken skips RIGHT")
        XCTAssertEqual(steer(.up, vx: 0, vy: 0), [0, -0x100])
        XCTAssertEqual(steer(.down, vx: 0, vy: 0), [0, 0x100])
        XCTAssertEqual(steer([.up, .down], vx: 0, vy: 0), [0, -0x100], "UP skips DOWN")
        XCTAssertEqual(steer([.up, .down], vx: 0, vy: -4000), [0, -4000 + 0x100], "UP at its cap → DOWN")
        XCTAssertEqual(steer(.down, vx: 0, vy: 4000), [0, 4000])
        XCTAssertEqual(steer(.up, vx: 0, vy: -3999), [0, -3999 - 0x100])
        XCTAssertEqual(steer([.right, .up], vx: 0, vy: 0, lock: 1), [0, 0], "the steering lock")
        XCTAssertEqual(w.player.idle, 0)
        // The centre-gap close: carpet left of the player by > 1 px, |vx| < 0x100 → carpet x256 + 0x100, player − 0x100.
        w.player.carpetLock = 1
        w.active.update(id: c) { $0.vx = 0xff; $0.centre.x = 500; $0.x256 = 0 }
        w.active.update(id: pl) { $0.centre.x = 502; $0.x256 = 0 }
        HandleKeys.carpetSteering(w, id: pl, carpet: c, keys: [])
        XCTAssertEqual([w.active.record(id: c)!.x256, w.active.record(id: pl)!.x256], [0x100, -0x100])
        w.active.update(id: c) { $0.vx = 0x100; $0.x256 = 0 }
        w.active.update(id: pl) { $0.x256 = 0 }
        HandleKeys.carpetSteering(w, id: pl, carpet: c, keys: [])
        XCTAssertEqual([w.active.record(id: c)!.x256, w.active.record(id: pl)!.x256], [0, 0], "|vx| 0x100: no close")
        w.active.update(id: c) { $0.vx = -0x10; $0.centre.x = 505; $0.x256 = 0 }
        w.active.update(id: pl) { $0.centre.x = 502; $0.x256 = 0 }
        HandleKeys.carpetSteering(w, id: pl, carpet: c, keys: [])
        XCTAssertEqual([w.active.record(id: c)!.x256, w.active.record(id: pl)!.x256], [-0x100, 0x100])

        // Level 22's fixture (the default keys: keypad 6 RIGHT 0x58, keypad 8 UP 0x5b). After the bob (40 iterations,
        // no key) the ridden carpet hovers: no key keeps it in place. Each iteration runs the carpet's Handle (layer 2)
        // before the player's (layer 10): vx decays by 0x80, then RIGHT adds 0x140 — 0x140, then + 0xc0 an iteration
        // (before it reaches the wall at x 8000); vy is damped (· 0.8 toward 0), then UP subtracts 0x100.
        func hover() throws -> (run: LevelRun, now: UInt32, carpet: Int) {
            var (run, now) = try open22()
            let fw = try XCTUnwrap(run.session).world
            let fc = try carpetID(run)
            _ = try XCTUnwrap(try runToWake(run, &now))
            for _ in 1...40 { try iterate(run, &now) }
            XCTAssertTrue(fw.player.carpet, "riding the carpet")
            XCTAssertEqual(fw.player.ridden, fc)
            XCTAssertTrue(fw.player.cameraSnapVeto)
            XCTAssertEqual(fw.player.carpetLock, 0)
            return (run, now, fc)
        }
        var (run, now, fc) = try hover()
        var fw = try XCTUnwrap(run.session).world
        let x0 = try XCTUnwrap(fw.active.record(id: fc)).x, p0 = try XCTUnwrap(fw.active.record(id: fw.playerID!)).x
        for _ in 1...5 { try iterate(run, &now) }
        XCTAssertEqual(fw.active.record(id: fc)?.x, x0, "no key: the carpet holds its place")
        var vxs: [Int32] = []
        for _ in 1...12 {
            try iterate(run, &now, input: FrontInput(keys: KeyState(pressed: [0x58])))
            vxs.append(try XCTUnwrap(fw.active.record(id: fc)).vx)
        }
        XCTAssertEqual(vxs, (0..<12).map { 0x140 + 0xc0 * Int32($0) }, "RIGHT: vx by the dump's values")
        let dx = try XCTUnwrap(fw.active.record(id: fc)).x - x0
        XCTAssertEqual(dx, 49, "measured: the carpet's move over 12 iterations of RIGHT")
        XCTAssertEqual(try XCTUnwrap(fw.active.record(id: fw.playerID!)).x - p0, dx, "the rider goes with it")
        (run, now, fc) = try hover()
        fw = try XCTUnwrap(run.session).world
        var vy = try XCTUnwrap(fw.active.record(id: fc)).vy
        let y0 = try XCTUnwrap(fw.active.record(id: fc)).y
        for k in 1...12 {
            try iterate(run, &now, input: FrontInput(keys: KeyState(pressed: [0x5b])))
            vy = Int32((Double(vy) * 0.8).rounded(.towardZero)) - 0x100
            XCTAssertEqual(fw.active.record(id: fc)?.vy, vy, "UP, iteration \(k)")
        }
        XCTAssertLessThan(try XCTUnwrap(fw.active.record(id: fc)).y, y0, "UP: the carpet climbs")
    }

    // MARK: - the tile hits

    /// `.HitBoxTileSprite`'s boulder / rock ranges stop below 0x438 (M l. 61551, 61592, 61668): a carpet hitting the
    /// floor fast gets factor 0 and no bounce — no thud (no `FastRand(10000)`, no cue 436), no `.KillBox` — where a
    /// boulder 0x42e on the same floor at the same speed thuds. Through the carpet's own Handle (its tail's tile pass).
    func testCarpetExcludedFromBoxTileHits() throws {
        func drop(_ type: Int16, vy: Int32 = 0x500) throws
            -> (cues: [PlayerCue], rngMoved: Bool, vy: Int32, dead: Bool) {
            let w = try world(floorRow: 12)
            let id: Int
            if type == 0x42e {
                let p = Placement(index: -1, flag: 1, byte1: 0, type: 0x42e, p1: 0, p2: 0, p3: 0, p4: 0, y: 300, x: 100)
                let s = try SetupFaces.setup(p, context: SetupFaces.Context(level: w.level, playerX: 0), rng: &w.rng).slot
                id = w.active.insert(s)
            } else {
                let (c, _) = try wokenCarpet(w)
                for _ in 1...30 { handle(w, c) }                  // the bob over: the tile hit set
                id = c
            }
            // Falling at 0x500 (0x400 after the carpet's damping: > 0x300, airborne last frame) from 4 px above the
            // floor's surface (y 400).
            let bottom = try XCTUnwrap(w.active.record(id: id)).hotRect.bottom
            w.active.update(id: id) {
                $0.vy = vy; $0.vx = 0; $0.onSprite = 0
                $0.x = 100; $0.x256 = 100 << 8; $0.y = 400 - bottom - 4; $0.y256 = Int32(400 - bottom - 4) << 8
            }
            w.player.cues = []
            let rng = w.rng
            for _ in 0..<3 { handle(w, id) }
            let s = try XCTUnwrap(w.active.record(id: id))
            return (w.player.cues, w.rng.seed != rng.seed, s.vy, s.dead)
        }
        let boulder = try drop(0x42e)
        XCTAssertEqual(boulder.cues.map(\.snd), [436], "the boulder thuds")
        XCTAssertTrue(boulder.rngMoved)
        let carpet = try drop(0x439)
        XCTAssertEqual(carpet.cues, [], "no thud for the carpet")
        XCTAssertFalse(carpet.rngMoved, "no FastRand(10000)")
        XCTAssertFalse(carpet.dead)
        XCTAssertEqual(carpet.vy, 0, "factor 0: landed, no bounce")
        // Faster (0x800, 0x666 after the damping): a boulder's factor 0x3c would bounce it up by about 0x180, past the
        // |vy| < 0x100 clamp — the carpet, outside the first range (M l. 61551, `< 0x438`), still lands dead.
        let fast = try drop(0x439, vy: 0x800)
        XCTAssertEqual(fast.cues, [])
        XCTAssertFalse(fast.rngMoved)
        XCTAssertEqual(fast.vy, 0, "factor 0 at any speed")
    }
}
