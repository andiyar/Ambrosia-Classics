import XCTest
@testable import FerazelCore

/// GF (docs/plans/2026-10-30-ferazel-phase5.md): the Gremlin (body, back layer, rider) and the Floater (the Wraith) —
/// `.InitGremlinSprite` (M l. 69080–69150), `.SetupGremlinSprite` (M l. 69153–69234), `.HandleGremlinSprite` (M l.
/// 69237–69637: the body arm 69281–69461, the rider arm 69462–69633), `.HitGremlinSprite` (M l. 69640–69721),
/// `.KillGremlinSprite` (M l. 69724–69758), `.HitGremlinTileSprite` (M l. 69761–69817); `.InitFloaterSprite` (M l.
/// 69820–69831), `.SetupFloaterSprite` (M l. 69834–69907), `.HandleFloaterSprite` (M l. 69910–70031),
/// `.HitFloaterSprite` (M l. 70034–70073), `.HitFloaterTileSprite` (M l. 70076–70108). Both classes are first placed on
/// level 15 (Gremlin) and 62 (Wraith): every placement here is made by hand over level 3's header and a synthetic
/// 60×30 grid (no FG unless a test lays a floor). Every expected draw is re-derived from a copy of the stream.
final class GremlinFloaterTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// The grid: no FG (tile −1) unless `floorRow` (FG kind 3); the BG every cell tile 0 of kind 0 — no BG callback —
    /// or, `emptyBG`, tile −1 (kind −1: `.SeparateFromTiles2` calls the tile callback for every BG cell the hot rect
    /// meets, −1 included).
    private func world(px: Int16 = 1800, py: Int16 = 300, floorRow: Int? = nil, emptyBG: Bool = false) throws
        -> SpriteWorld {
        let w = SpriteWorld(level: try LevelFile.load(from: try resources(), level: 3))
        var fg = [UInt16](repeating: 0, count: 60 * 30)
        let bg = [UInt16](repeating: emptyBG ? 0 : 1, count: 60 * 30)
        if let r = floorRow { for c in 0..<60 { fg[r * 60 + c] = 4 } }
        w.tiles = TileGrid(fg: TileMap(width: 60, height: 30, cells: fg), bg: TileMap(width: 60, height: 30, cells: bg),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        w.player.centreX = px
        w.player.centreY = py
        w.player.scrollH = 400
        w.player.scrollV = 100
        w.levelIndex = 3
        return w
    }

    /// A Gremlin placement (record 0) through `SetupFaces.spawnLevelSprites` — the Setup, its two `.MTNewSprite`
    /// children inserted first, the parent spawned now, the rider's backlink, the radial for path modes 10 / 11 — in a
    /// world with no sprite yet (its list becomes the spawn's). The ids by part `+0xec`.
    private func gremlin(_ w: SpriteWorld, type: Int16 = 0x6ea, x: Int = 600, y: Int = 300, p1: Int16 = 1,
                         p2: Int16 = 100, p3: Int16 = 800, p4: Int16 = 0, window: Bool = true) throws
        -> (body: Int, back: Int, rider: Int) {
        let p = Placement(index: 0, flag: 1, byte1: 0, type: type, p1: p1, p2: p2, p3: p3, p4: p4, y: Int16(y), x: Int16(x))
        w.records = [p]
        let c = SetupFaces.Context(level: w.level, playerX: Int(w.player.centreX), records: w.records)
        var counting = EnemyCounting(window: window, live: w.enemies.live)
        let out = try SetupFaces.spawnLevelSprites(context: c, rng: &w.rng, counting: &counting,
                                                   idleFaceRect: { _ in IdleSprites.Rect.noFace })
        w.enemies.live = counting.live
        w.active = out.active
        func part(_ k: Int16) throws -> Int { try XCTUnwrap(w.active.sprites.first { $0.partIndex == k }?.id) }
        return (try part(0), try part(1), try part(2))
    }

    /// A Floater placement (record 0) set up by `SetupFaces` inside the counting window, inserted.
    private func floater(_ w: SpriteWorld, type: Int16 = 0x6f4, x: Int = 600, y: Int = 300, p1: Int16 = 0,
                         p2: Int16 = 0, p3: Int16 = 0, window: Bool = true) throws -> (id: Int, entry: SetupFaces.Entry) {
        let p = Placement(index: 0, flag: 1, byte1: 0, type: type, p1: p1, p2: p2, p3: p3, p4: 0, y: Int16(y), x: Int16(x))
        w.records = [p]
        let c = SetupFaces.Context(level: w.level, playerX: Int(w.player.centreX), records: w.records)
        var lights = LightTable()
        w.enemies.window = window
        let e = try SetupFaces.setup(p, context: c, lights: &lights, counting: &w.enemies, rng: &w.rng)
        w.enemies.window = false
        var s = e.slot
        GremlinFloater.calcCentre(&s)                                   // as a previous Cleanup leaves it
        return (w.active.insert(s), e)
    }

    /// A player sprite (Handle `.inert`) whose stored centre is `c` — `*_DAT_1009fdd8 + 0xe` for the rider's aim.
    @discardableResult
    private func playerSprite(_ w: SpriteWorld, at c: SpriteSlot.Point) -> Int {
        var p = SpriteSlot(type: 0, x: c.x - 0x30, y: c.y - 0x40)
        p.handler = .inert
        p.centre = c
        let id = w.active.insert(p)
        w.playerID = id
        return id
    }

    private func slot(_ w: SpriteWorld, _ id: Int) throws -> SpriteSlot { try XCTUnwrap(w.active.record(id: id)) }

    private func f(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }

    private func rect(_ l: Int, _ t: Int, _ r: Int, _ b: Int) -> IdleSprites.Rect {
        IdleSprites.Rect(top: t, left: l, bottom: b, right: r)
    }

    /// The first seed ≥ 1 whose stream makes `pick` true.
    private func seed(_ pick: (inout FastRand) -> Bool) -> Int32 {
        var s: Int32 = 1
        while true {
            var r = FastRand(seed: s)
            if pick(&r) { return s }
            s += 1
        }
    }

    /// Whether the next `R(n)` of `r` differs from `R(n − 1)` and `R(n + 1)` at the same point (seed luck: a mutated
    /// range would show).
    private func differs(_ r: FastRand, _ n: Int16) -> Bool {
        var a = r, b = r, c = r
        let x = a.next(n)
        return x != b.next(n - 1) && x != c.next(n + 1)
    }

    /// One Gremlin / Floater Handle call by `+0x4c` (the session's dispatch).
    private func frame(_ w: SpriteWorld, _ id: Int, effects: Int16 = 1) {
        var lights = LightTable()
        let solver = TileSolver(world: w)
        switch w.active.record(id: id)?.handler {
        case .floater?: GremlinFloater.handleFloater(world: w, id: id, solver: solver)
        default: GremlinFloater.handleGremlin(world: w, id: id, solver: solver, lights: &lights, effects: effects)
        }
    }

    /// A sprite of `type` / `handler` with a 20×20 hot rect over the sprite at `id` (a player shot by default).
    private func other(_ w: SpriteWorld, over id: Int, type: Int16 = 2, handler: SpriteHandler = .playerShot,
                       damage: Int16 = 150, vx: Int32 = 1000, vy: Int32 = -200,
                       body: (inout SpriteSlot) -> Void = { _ in }) throws -> Int {
        let t = try slot(w, id)
        return try XCTUnwrap(w.newSprite(type: type, x: t.centre.x - 10, y: t.centre.y - 10, layer: 0xb,
                                         handler: handler) { s in
            s.x = t.centre.x - 10
            s.y = t.centre.y - 10
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 20, right: 20)
            s.centre = t.centre
            s.hp = damage
            s.vx = vx
            s.vy = vy
            body(&s)
        })
    }

    /// The player centre that makes `.FindDesiredDirectionGeneric(rider centre, player centre)` = `k` (0 left, 9 down,
    /// 18 right, 27 up — the vector player → rider), 200 px away.
    private func aim(from r: SpriteSlot.Point, _ k: Int) -> SpriteSlot.Point {
        let a = Double(k) * 10 * Double.pi / 180
        return SpriteSlot.Point(x: r.x + Int((cos(a) * 200).rounded()), y: r.y - Int((sin(a) * 200).rounded()))
    }

    private func dir(_ target: SpriteSlot.Point, from p: SpriteSlot.Point) -> Int {
        BloodSpray.direction(target: (v: Int16(target.y), h: Int16(target.x)), from: (v: Int16(p.y), h: Int16(p.x)))
    }

    // MARK: - the Gremlin

    func testGremlinCompositeSetup() throws {
        // `.SetupGremlinSprite` (M l. 69153–69234) runs for every part: `.InitSprite`; `+0x84`/`+0x86` 0; the Gremlin
        // Handle, hit, Kill `+0x50`; no tile callback (`+0x1f8 = 0`); the three sheets marked; gravity 0; `+0xc0 = 0`;
        // HP 500; `+0xc ← +8`, `+0xa ← +6`; SetRect(0x28, 0x26, 0x59, 0x50); `+0x14c = 0`, `+0x150 = −1`, `+0xa6 = 0`,
        // `+0xb0 = 7`; the 24.8 position; `.CalcCenterPos`. A child (`+0x48 == 0x1ff`): empty rect, no hit, not
        // counted, `+0x188 = 1`. The parent: layer 10, `+0xec = 0`, the back layer `MTNewSprite(type, +0xc, +0xa, 9,
        // 0x1ff)` (`+0xec = 1`, `+0xb8 = 0xb0000`, `+0x88 = 0`, `+0x5c = 0`), the rider `MTNewSprite(type, +0xc + 0x26,
        // +0xa + 0x1b, 12, 0x1ff)` (`+0xec = 2`, backlink, SetRect(6, 3, 0x1a, 0x1b) then bottom − 5, the tile
        // callback), `+0x188 = 1`, `.SetupProgrammedPath(s, −1, 0)`, counted in the window; `+0x188 = 1` last.
        let w = try world()
        let before = w.rng.seed
        let g = try gremlin(w, x: 600, y: 300, p1: 1, p2: 100, p3: 800)
        XCTAssertEqual(w.rng.seed, before, "no draw")
        XCTAssertEqual(w.active.sprites.map(\.id), [g.back, g.body, g.rider], "layers 9, 10, 12")
        let b = try slot(w, g.body)
        XCTAssertEqual([b.type, b.recordIndex], [0x6ea, 0])
        XCTAssertEqual(b.handler, .gremlin)
        XCTAssertEqual([b.hasHit, b.hasTileHit, b.keepRecord, b.countedInTotals, b.lightOverlay, b.mirrored],
                       [true, false, true, true, true, false])
        XCTAssertEqual([b.noWriteBack189, b.noWriteBack18a, b.keepRecordAtKill, b.killedForGood, b.dead],
                       [false, false, false, false, false], "only `+0x188` among the write-back flags")
        XCTAssertEqual([Int(b.layer), Int(b.gravity), Int(b.hp), Int(b.subtype), Int(b.counterA6), Int(b.partIndex),
                        Int(b.classTimer), Int(b.classWord150), Int(b.subState)], [10, 0, 500, 7, 0, 0, 0, -1, 0])
        XCTAssertEqual([Int(b.particleOffsetX), Int(b.particleOffsetY)], [0, 0])
        XCTAssertEqual(b.hotRect, rect(0x28, 0x26, 0x59, 0x50))
        XCTAssertEqual([b.x, b.y, Int(b.x256), Int(b.y256)], [600, 300, 600 << 8, 300 << 8])
        XCTAssertEqual(b.centre, SpriteSlot.Point(x: 600 + 0x28 + 0x18, y: 300 + 0x26 + 0x15), "`.CalcCenterPos`")
        XCTAssertEqual([b.siblings.first, b.siblings.second], [g.back, g.rider])
        XCTAssertEqual(b.face, f(0x6ea, 0), "the Handle's first face (the level start's stand-in)")
        XCTAssertEqual(b.mode, 0)
        // The path (p1 1 → mode 1, p2 travel, p3 speed): `+0x100 = +0x1c + 8·p3`, `+0x104 = +0x1c + 256·p2 − 8·p3`.
        XCTAssertEqual([b.pathMode, b.pathSpeed, b.pathDirection, b.pathLow, b.pathHigh, b.vy, b.vx, Int32(b.sag)],
                       [1, 800, 1, 76800 + 6400, 76800 + 25600 - 6400, 800, 0, 0])
        XCTAssertNil(b.radial)
        // The back layer (record 0x1ff): the same place, layer 9, untouched by the path.
        let k = try slot(w, g.back)
        XCTAssertEqual([k.type, k.recordIndex, Int16(k.layer), k.partIndex, k.hp, k.gravity, k.subtype],
                       [0x6ea, 0x1ff, 9, 1, 500, 0, 7])
        XCTAssertEqual(k.handler, .gremlin)
        XCTAssertEqual([k.hasHit, k.hasTileHit, k.keepRecord, k.countedInTotals, k.lightOverlay, k.killedForGood],
                       [false, false, true, false, false, false])
        XCTAssertEqual(k.mode, 0xb0000)
        XCTAssertEqual(k.hotRect, rect(0, 0, 0, 0))
        XCTAssertEqual([k.x, k.y, Int(k.x256), Int(k.y256), Int(k.classWord150), Int(k.pathMode)],
                       [600, 300, 600 << 8, 300 << 8, -1, 0])
        XCTAssertEqual(k.centre, SpriteSlot.Point(x: 664, y: 359), "the centre before the child's rect is emptied")
        XCTAssertNil(k.face)
        XCTAssertEqual(k.siblings, SpriteSlot.Siblings())
        // The rider: (x + 0x26, y + 0x1b), layer 12, rect (6, 3, 0x1a, 0x16), the tile callback, the backlink.
        let r = try slot(w, g.rider)
        XCTAssertEqual([r.type, r.recordIndex, Int16(r.layer), r.partIndex, r.hp], [0x6ea, 0x1ff, 12, 2, 500])
        XCTAssertEqual([r.hasHit, r.hasTileHit, r.keepRecord, r.countedInTotals, r.lightOverlay],
                       [false, true, true, false, true])
        XCTAssertEqual(r.hotRect, rect(6, 3, 0x1a, 0x16))
        XCTAssertEqual([r.x, r.y, Int(r.x256), Int(r.y256)], [638, 327, 638 << 8, 327 << 8])
        XCTAssertEqual(r.centre, SpriteSlot.Point(x: 638 + 0x40, y: 327 + 0x3b))
        XCTAssertEqual([r.siblings.first, r.siblings.second], [g.body, nil])
        XCTAssertEqual(r.mode, 0)
        XCTAssertNil(r.face)
        XCTAssertEqual(w.enemies.live, 1, "the parent only")
        // Outside the window: not counted.
        let u = try world()
        let ug = try gremlin(u, window: false)
        XCTAssertEqual([u.enemies.live], [0])
        XCTAssertFalse(try slot(u, ug.body).countedInTotals)
        XCTAssertTrue(try slot(u, ug.body).keepRecord)
        // Mode 2 (p1 2): the bounds on x, vx = p3; |p1| and the 1xx form.
        let m2 = try world()
        let g2 = try gremlin(m2, p1: 2, p2: 50, p3: 400)
        let b2 = try slot(m2, g2.body)
        XCTAssertEqual([b2.pathMode, b2.pathSpeed, b2.pathLow, b2.pathHigh, b2.vx, b2.vy],
                       [2, 400, 153600 + 3200, 153600 + 12800 - 3200, 400, 0])
        for p1: Int16 in [-1, 101, -101] {
            let m = try world()
            XCTAssertEqual(try slot(m, try gremlin(m, p1: p1).body).pathMode, 1, "p1 \(p1)")
        }
        // Mode 3 (stores only): the path Setup's rect and fields override the Gremlin's.
        let m3 = try world()
        let b3 = try slot(m3, try gremlin(m3, p1: 3).body)
        XCTAssertEqual(b3.hotRect, rect(7, 0, 0x46, 0x1e))
        XCTAssertEqual([Int(b3.buoyancy), Int(b3.gravity), Int(b3.sag), Int(b3.pushMass), Int(b3.pathDirection)],
                       [0x50, 0x15e, 0x2d, 0x3c, 0])
        // Modes 10 / 11 reach `.MakeRadial` (M l. 39354–39378): hub = the centre, r = p2, speed = p3 (0 in the 1xx
        // form), angle = p4, g 0 / 0x1e; `+0xf8 = 0`.
        for (p1, mode, speed, g) in [(Int16(10), Int32(10), Int32(5), Int16(0)), (11, 11, 5, 0x1e), (110, 10, 0, 0),
                                     (-111, 11, 0, 0x1e)] {
            let m = try world()
            let gb = try slot(m, try gremlin(m, p1: p1, p2: 64, p3: 5, p4: 90).body)
            XCTAssertEqual([gb.pathMode, gb.pathDirection], [mode, 0], "p1 \(p1)")
            let rad = try XCTUnwrap(gb.radial, "p1 \(p1)")
            XCTAssertEqual([rad.hubX, rad.hubY, rad.radius, rad.speed, rad.angle, Int32(rad.gravity)],
                           [664 << 8, 359 << 8, 64 << 8, speed, 90 << 8, Int32(g)], "p1 \(p1)")
        }
        // Every type of the class takes the same Setup; the marks and the Handle rows.
        for t: Int16 in [0x6ea, 0x6ef, 0x6f3] {
            let m = try world()
            let gt = try gremlin(m, type: t)
            XCTAssertEqual(try [gt.body, gt.back, gt.rider].map { try slot(m, $0).type }, [t, t, t])
            XCTAssertEqual(CachedFaces.marks(type: t).sets, [0x6ea, 0x6eb, 0x6ec], "M l. 69181–69183")
            XCTAssertEqual(CachedFaces.marks(type: t).singles, [])
            XCTAssertEqual(SpriteHandler.forClass(type: t), .gremlin)
        }
        // The cache registration (`.InitSprites` M l. 106–145: … Crab, Dillo, Warrior, …, Floater, Frog, Gremlin,
        // Salamander): the Floater's three (M l. 69827–69829) after the Crab's, the Dillo's four (DL, M l. 72283–72286)
        // and the Warrior's three (LV5: `.InitWarriorSprite` M l. 72982–72984 — 0x71c 8, 0x71d 8, 0x71e 6, called
        // right after `.InitDilloSprite`, M l. 133–134), the Gremlin's three (M l. 69118–69120) after the Frog's.
        let picts = CachedFaces.sets.map(\.pict)
        let at = try XCTUnwrap(picts.firstIndex(of: 0x762))
        XCTAssertEqual(Array(picts[at...at + 15]), [0x762, 0x74e, 0x74f, 0x750, 0x751, 0x71c, 0x71d, 0x71e, 0x6f4,
                                                    0x6fe, 0x6ff, 0x708, 0x6ea, 0x6eb, 0x6ec, 0x712])
        XCTAssertEqual(CachedFaces.sets[at...at + 15].map(\.faces), [6, 6, 5, 5, 2, 8, 8, 6, 6, 8, 8, 8, 10, 10, 4, 9])
        XCTAssertEqual(CachedFaces.sets[at...at + 15].map(\.flag), [Int16](repeating: 0, count: 16))
        XCTAssertEqual(SetupFaces.sheet(pict: 0x6ea), SetupFaces.Sheet(pict: 0x6ea, count: 10, cellWidth: 0x84,
                                                                     cellHeight: 0x78, columns: 10, clut: 200))
        XCTAssertEqual(SetupFaces.sheet(pict: 0x6eb), SetupFaces.Sheet(pict: 0x6eb, count: 10, cellWidth: 0x84,
                                                                     cellHeight: 0x78, columns: 10, clut: 200))
        XCTAssertEqual(SetupFaces.sheet(pict: 0x6ec), SetupFaces.Sheet(pict: 0x6ec, count: 4, cellWidth: 0x20,
                                                                     cellHeight: 0x20, columns: 4, clut: 200))
        XCTAssertEqual(CachedFaces.sheets(markedBy: [Int16(0x6ea)]).map(\.pict), [0x6ea, 0x6eb, 0x6ec])
        // The Ring of Smiting seeds every part (all three run the Gremlin Handle): three seeds at the stored centres − 4.
        let sm = try world()
        let gs = try gremlin(sm)
        Smite.smiteEnemies(sm)
        let seeds = sm.active.sprites.filter { $0.handler == .playerShot }
        XCTAssertEqual(seeds.count, 3)
        let centres = try [gs.back, gs.body, gs.rider].map { try slot(sm, $0).centre }
        XCTAssertEqual(seeds.map { [$0.oldPosition.x, $0.oldPosition.y] }.sorted { $0.lexicographicallyPrecedes($1) },
                       centres.map { [$0.x - 4, $0.y - 4] }.sorted { $0.lexicographicallyPrecedes($1) })
        // The Setup's record read: none (`+0x48 == −1`) leaves the path mode 0.
        var bare = SpriteSlot(type: 0x6ea, x: 10, y: 20, recordIndex: -1)
        bare.oldPosition = SpriteSlot.Point(x: 10, y: 20)
        var none = EnemyCounting()
        GremlinFloater.setupGremlin(&bare, record: nil, counting: &none) { _, _, _, _ in nil }
        XCTAssertEqual([bare.pathMode, bare.pathDirection, Int32(bare.layer)], [0, 1, 10])
        XCTAssertEqual([bare.siblings.first, bare.siblings.second], [nil, nil], "no free record: no links")
    }

    func testGremlinBody() throws {
        // The body arm (M l. 69281–69461): `+0x14c` copied to the rider; `.StandardSpriteHandles`; the water block —
        // dead (`.StandardSpriteHandles` has just zeroed `+0x11c`); `.HandleProgrammedPath`; by state (4 dying; path
        // mode 1, 2, other); the wing table wrap and "flap"; the face 1770[table[`+0xa6`]]; HP < 1 → state 4; x += v
        // and `.ApplyGravityAndSeparateFromTiles` (2·v a frame); `.StandardSpriteCleanup`; the back layer and the
        // mounted rider follow; a dislodged rider is made shootable and the saddle bleeds.
        let w = try world(px: 1800)
        let g = try gremlin(w, p1: 1, p2: 100, p3: 800)
        w.active.update(id: g.body) { s in
            s.vx = 1000
            s.previousVY = 801                                          // vy 800 < `+0x30` → the anim advances
            s.flash = 5
            s.mode = 0x10002
        }
        w.active.update(id: g.rider) { $0.clip.top = 7 }
        w.active.update(id: g.back) { $0.clip.top = 9 }
        let before = w.rng.seed
        frame(w, g.body)
        XCTAssertEqual(w.rng.seed, before, "no draw")
        var b = try slot(w, g.body)
        XCTAssertEqual([Int(b.counterA6), b.face?.index ?? -1], [1, 0])
        XCTAssertEqual(b.face, f(0x6ea, 0))
        XCTAssertEqual([b.vx, b.vy], [800, 800], "mode 1: vx · 0.8 (f64 0x100a1bb0); the path keeps vy at p3")
        XCTAssertEqual([Int(b.x256), Int(b.y256), b.x, b.y], [153600 + 1600, 76800 + 1600, 606, 306], "2·v")
        XCTAssertTrue(b.mirrored, "centre x 664 < the player's 1800")
        XCTAssertEqual(Int(b.flash), 4, "`.StandardSpriteHandles` counts the flash down")
        XCTAssertEqual(b.subtype, 7)
        let k = try slot(w, g.back)
        XCTAssertEqual([k.x, k.y, Int(k.x256), Int(k.y256), k.clip.top], [606, 306, 600 << 8, 300 << 8, 0],
                       "the back layer's pixel place, facing, frame and `+0x1bc` (24.8 untouched)")
        XCTAssertEqual(k.face, f(0x6eb, 0))
        XCTAssertTrue(k.mirrored)
        var r = try slot(w, g.rider)
        XCTAssertEqual([r.x, r.y, Int(r.x256), Int(r.y256)], [606 + 0x3e, 306 + 0x1b, (606 + 0x3e) << 8, (306 + 0x1b) << 8],
                       "facing right: body + (0x3e, 0x1b)")
        XCTAssertEqual([r.mirrored, r.hasHit], [true, false])
        XCTAssertEqual([Int(r.flash), Int(r.clip.top), Int(r.classTimer)], [4, 7, 0], "flash copied; `+0x1bc` ≤ 0x1b kept")
        XCTAssertEqual(r.mode, 0x10002)
        XCTAssertEqual(w.particles.counters.count, 0, "a mounted rider: no blood")
        // Facing left (the player's x < the centre): the rider at body + (0x26, 0x1b); equal x keeps the facing.
        w.player.centreX = 0
        frame(w, g.body)
        b = try slot(w, g.body)
        r = try slot(w, g.rider)
        XCTAssertFalse(b.mirrored)
        XCTAssertEqual([r.x, r.y, r.mirrored ? 1 : 0], [b.x + 0x26, b.y + 0x1b, 0])
        w.player.centreX = Int16(b.centre.x)
        w.active.update(id: g.body) { $0.mirrored = true }
        frame(w, g.body)
        XCTAssertTrue(try slot(w, g.body).mirrored, "equal x: kept")
        w.player.centreX = Int16(try slot(w, g.body).centre.x)
        w.active.update(id: g.body) { $0.mirrored = false }
        frame(w, g.body)
        XCTAssertFalse(try slot(w, g.body).mirrored, "equal x: kept (left)")
        XCTAssertEqual([try slot(w, g.back).mode, UInt32(try slot(w, g.back).flash)], [0xb0000, 0],
                       "the back layer keeps its tint; no flash copied to it")
        // The burn row `+0x1bc` (`.HandleBurn`'s top clip, here from a stub face whose opaque top is `top`: the row
        // starts at `top`, + 1 a frame): the back layer takes it as is; the mounted rider takes it − 0x1b only when it
        // is > 0x1b (0x30 → 0x15; 0x1b → its own kept).
        for (top, want) in [(Int16(0x2f), 0x15), (0x1a, 7)] {
            let bw = try world()
            bw.particleFaces = ParticleFaces(sprite: { _ in
                ParticleFace(frame: [0, 0, 0x78, 0x84], bounds: [top, 0, 0x78, 0x84], tokens: [])
            })
            let bg = try gremlin(bw, p1: 0)
            bw.active.update(id: bg.body) { $0.burnRow = 1 }
            bw.active.update(id: bg.rider) { $0.clip.top = 7 }
            frame(bw, bg.body)
            XCTAssertEqual([try slot(bw, bg.body).clip.top, try slot(bw, bg.back).clip.top, try slot(bw, bg.rider).clip.top],
                           [Int(top) + 1, Int(top) + 1, want], "burn row \(top + 1)")
        }
        // Mode 1's anim gate: vy < `+0x30` (strict) or mid-cycle.
        for (a6, prev, want) in [(Int16(0), Int32(800), Int16(0)), (0, 801, 1), (3, 800, 4), (3, 0, 4)] {
            let m = try world()
            let mg = try gremlin(m)
            m.active.update(id: mg.body) { $0.counterA6 = a6; $0.previousVY = prev }
            frame(m, mg.body)
            XCTAssertEqual(try slot(m, mg.body).counterA6, want, "a6 \(a6), +0x30 \(prev)")
        }
        // The wing table (data 0x100a6dd0, count 0x16) and the wrap at ≥ 22 with "flap" (494, Rand, vol 0x55).
        let table = [0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9]
        for a6 in 0..<21 {
            let m = try world()
            let mg = try gremlin(m, p1: 2, p2: 50, p3: 400)
            m.active.update(id: mg.body) { $0.counterA6 = Int16(a6) }
            frame(m, mg.body)
            XCTAssertEqual(try slot(m, mg.body).face, f(0x6ea, table[a6 + 1]), "a6 \(a6 + 1)")
            XCTAssertEqual(try slot(m, mg.back).face, f(0x6eb, table[a6 + 1]))
            XCTAssertEqual(m.player.cues, [], "a6 \(a6 + 1): no flap")
        }
        let wr = try world()
        let wg = try gremlin(wr, p1: 2, p2: 50, p3: 400)
        wr.active.update(id: wg.body) { $0.counterA6 = 21 }
        let centre = try slot(wr, wg.body).centre
        var rr = wr.rng
        let rate = rr.soundRate()
        frame(wr, wg.body)
        XCTAssertEqual([Int(try slot(wr, wg.body).counterA6)], [0])
        XCTAssertEqual(try slot(wr, wg.body).face, f(0x6ea, 0))
        XCTAssertEqual(wr.player.cues, [PlayerCue(call: .threeDRand, snd: 494, priority: 1, volume: 0x55,
                                                  position: centre, rate: rate)])
        XCTAssertEqual(wr.rng.seed, rr.seed)
        // Mode 2: the anim always advances, the facing by vx's sign (vx < 1 → left), vy · 0.7 (f64 0x100a1ba8).
        let m2 = try world(px: 0)
        let g2 = try gremlin(m2, p1: 2, p2: 50, p3: 400)
        m2.active.update(id: g2.body) { $0.vy = 1000 }
        frame(m2, g2.body)
        var s2 = try slot(m2, g2.body)
        XCTAssertEqual([Int(s2.counterA6), Int(s2.vy), Int(s2.vx)], [1, 700, 400])
        XCTAssertTrue(s2.mirrored, "vx 400 ≥ 1: right, whatever the player's side")
        m2.active.update(id: g2.body) { $0.vx = 0; $0.pathSpeed = 0; $0.vy = -10 }
        frame(m2, g2.body)
        s2 = try slot(m2, g2.body)
        XCTAssertEqual([Int(s2.counterA6), Int(s2.vy)], [2, -7])
        XCTAssertFalse(s2.mirrored, "vx 0 < 1: left")
        // Any other mode: the anim advances, the facing by the player, no scaling.
        let m0 = try world(px: 1800)
        let g0 = try gremlin(m0, p1: 0)
        m0.active.update(id: g0.body) { $0.vx = 1000; $0.vy = 1000 }
        frame(m0, g0.body)
        let s0 = try slot(m0, g0.body)
        XCTAssertEqual([Int(s0.pathMode), Int(s0.counterA6), Int(s0.vx), Int(s0.vy)], [0, 1, 1000, 1000])
        XCTAssertTrue(s0.mirrored)
        // The dead water block: in water last frame, `.StandardSpriteHandles` zeroes `+0x11c` before the test reads it.
        let wt = try world()
        let wtg = try gremlin(wt)
        wt.active.update(id: wtg.body) { $0.waterRow = 1; $0.waterKind = 0; $0.vy = 0; $0.pathMode = 0 }
        frame(wt, wtg.body)
        let ws = try slot(wt, wtg.body)
        XCTAssertEqual([Int(ws.hp), Int(ws.invulnerable), Int(ws.vy)], [500, 0, 0], "no damage, no −100 lift")
        XCTAssertEqual(wt.player.cues, [])
        // HP < 1 → state 4 at the end of the frame (no other change this frame).
        let d = try world()
        let dg = try gremlin(d)
        d.active.update(id: dg.body) { $0.hp = 0 }
        frame(d, dg.body)
        XCTAssertEqual(try slot(d, dg.body).subtype, 4)
        XCTAssertEqual(try slot(d, dg.body).pathMode, 1)
        // State 4 (dying): R(3) first; `+0x5c = 0`, path off, vx · 0.8, gravity 0x5a, the tile callback; the first frame
        // `+0x1a2 = 1`, score + 1200, R(3) + 1 coins `MTNewSprite(0x516, c.x − 4, c.y − 4, 2, −1, .SetupBonusSprite)`
        // (vy −0x578 − R(0x640), vx R(1000) − 500), vy = 0, the monster death sound (477/478 by R(2), Rand, 0x100) with
        // the rider mounted.
        for (n, mounted) in [(Int16(0), true), (2, true), (1, false)] {
            let e = try world()
            let eg = try gremlin(e)
            e.active.update(id: eg.body) { s in
                s.subtype = 4
                s.vx = 1000
                s.vy = -300
                s.classTimer = mounted ? 0 : 1
                s.hp = 0                                                // dying: no saddle blood
            }
            e.rng = FastRand(seed: seed { $0.next(3) == n })
            let c0 = try slot(e, eg.body).centre
            var q = e.rng
            _ = q.next(3)
            frame(e, eg.body)
            let s = try slot(e, eg.body)
            XCTAssertEqual([s.hasHit, s.hasTileHit], [false, true], "n \(n)")
            XCTAssertEqual([Int(s.pathMode), Int(s.gravity), Int(s.burnRow), Int(s.vx), Int(s.vy)],
                           [0, 0x5a, 1, 800, 0x5a], "n \(n): vx · 0.8; vy 0 then the gravity")
            XCTAssertEqual(e.globals.score, 1200)
            let coins = e.active.sprites.filter { $0.type == 0x516 }
            XCTAssertEqual(coins.count, Int(n) + 1, "n \(n)")
            XCTAssertEqual(Set(coins.map(\.handler)), [.bonus])
            for c in coins.sorted(by: { $0.id < $1.id }) {
                // `MTNewSprite(0x516, c.x − 4, c.y − 4, 2, −1, .SetupBonusSprite)`: its Setup's draws, then vy, then vx.
                let k = SpriteWorld.newRecord(type: 0x516, x: c0.x - 4, y: c0.y - 4, layer: 2, handler: .bonus,
                                              record: -1) { b in
                    _ = try? BonusSprite.setup(&b, x: c0.x - 4, y: c0.y - 4, level: e.level, records: e.records,
                                               effects: 1, lightCount: 0, counting: false, playerLayer: 0,
                                               rng: &q) { _, _, _, _ in 0 }
                }
                let cvy = -0x578 - Int32(q.next(0x640)), cvx = Int32(q.next(1000)) - 500
                XCTAssertEqual([Int(c.x256 >> 8), Int(c.y256 >> 8), Int(c.layer)], [c0.x - 4, c0.y - 4, Int(k.layer)])
                XCTAssertEqual([c.vy, c.vx], [cvy, cvx], "n \(n): vy drawn before vx")
            }
            let monster = e.player.cues.filter { $0.snd == 477 || $0.snd == 478 }
            if mounted {
                let k = q.next(2)
                XCTAssertEqual(monster, [PlayerCue(call: .threeDRand, snd: 477 + k, priority: 1, volume: 0x100,
                                                   position: c0, rate: q.soundRate())], "n \(n)")
            } else {
                XCTAssertEqual(monster, [], "n \(n)")
            }
            XCTAssertEqual(e.rng.seed, q.seed, "n \(n): R(3), the coins, the monster sound")
            // The next frame: no second burn start, score or coins; vx · 0.8 again.
            e.player.cues = []
            _ = q.next(3)
            frame(e, eg.body)
            XCTAssertEqual(e.rng.seed, q.seed, "n \(n): R(3) drawn again on the next dying frame, nothing else")
            let t = try slot(e, eg.body)
            XCTAssertEqual([Int(t.vx), Int(t.burnRow), Int(e.globals.score)], [640, 1, 1200])
            XCTAssertEqual(e.active.sprites.filter { $0.type == 0x516 }.count, Int(n) + 1)
            XCTAssertEqual(e.player.cues.filter { $0.snd == 477 || $0.snd == 478 }, [])
        }
        // In the open (BG tile −1, kind −1) `.SeparateFromTiles2` calls the dying body's tile callback for each BG cell
        // its hot rect meets — 2 × 2 cells, twice (`.ApplyGravityAndSeparateFromTiles`' entry pass and its one step):
        // eight more vx · 0.8 a frame on top of the state's.
        let eb = try world(emptyBG: true)
        let ebg = try gremlin(eb)
        eb.active.update(id: ebg.body) { s in
            s.subtype = 4
            s.vx = 1000
            s.burnRow = 1
        }
        frame(eb, ebg.body)
        // The path keeps vy 800 (state 4 zeroes it only on its first frame): the Handle's y += vy takes the rect to
        // 341…383 (rows 10–11: 4 cells), the step's y += 890 to 344…386 (rows 10–12: 6 cells) — ten more · 0.8.
        var decayed: Int32 = 1000
        for _ in 0..<11 { decayed = PlayerShot.fctiwz(Double(decayed) * 0.8) }
        XCTAssertEqual([try slot(eb, ebg.body).vx, decayed], [84, 84])
        // A dislodged rider (`+0x14c = 1`): the rider's hit becomes `.HitGremlinSprite`; while the body lives, R(5) + 8
        // blood particles a frame from the saddle (x + 0x3a | 0x4a + R(3), y + 0x2f + R(3)), vx ±400 + body vx + R(0x3c)
        // − 0x1e, vy body vy + R(0x3c) − 0x1e0, delay R(3) or −0x32 − R(0x46) when R(3) is 0, mode 1.
        for facingRight in [true, false] {
            let bl = try world(px: facingRight ? 1800 : 0)
            let bg = try gremlin(bl, p1: 0)
            bl.active.update(id: bg.body) { s in
                s.classTimer = 1
                s.vx = 300
                s.vy = -200
            }
            bl.rng = FastRand(seed: seed { differs($0, 5) })
            var q = bl.rng
            frame(bl, bg.body)
            let s = try slot(bl, bg.body)
            XCTAssertEqual(s.mirrored, facingRight)
            XCTAssertTrue(try slot(bl, bg.rider).hasHit, "the rider is shootable")
            XCTAssertEqual(try slot(bl, bg.rider).classTimer, 1, "`+0x14c` copied")
            XCTAssertEqual([try slot(bl, bg.rider).x], [638], "a dislodged rider is not moved by the body")
            let count = Int(q.next(5)) + 8
            let h = s.x + Int(q.next(3)) + (facingRight ? 0x4a : 0x3a)
            let v = s.y + Int(q.next(3)) + 0x2f
            var want: [ParticlePool.Record] = []
            for _ in 0..<count {
                var dl = Int(q.next(3))
                if dl == 0 { dl = -0x32 - Int(q.next(0x46)) }
                let r16 = Int(q.next(0x3c)), r14 = Int(q.next(0x3c))
                var p = ParticlePool.Record()
                p.alive = true
                p.age = Int16(-dl)
                p.shape = 4
                p.kind = 2
                p.gravity = 100
                p.x = Int32(h) << 8
                p.y = Int32(v) << 8
                p.vx = Int32((facingRight ? 400 : -400) + 300 + r14 - 0x1e)
                p.vy = Int32(-200 + r16 - 0x1e0)
                p.mode = 1
                want.append(p)
            }
            XCTAssertEqual(Array(bl.particles.records.prefix(count)), want, "facing right \(facingRight)")
            XCTAssertFalse(bl.particles.records[count].alive)
            XCTAssertEqual(bl.rng.seed, q.seed)
        }
        // HP ≤ 0: no blood.
        let nb = try world()
        let nbg = try gremlin(nb, p1: 0)
        nb.active.update(id: nbg.body) { $0.classTimer = 1; $0.hp = 0 }
        frame(nb, nbg.body)
        XCTAssertEqual(nb.particles.counters.count, 0)
        // The rider dead (`+0x14c = 2`, `+0x1d8 = 0`): the saddle still bleeds; no rider is touched.
        let rd = try world()
        let rdg = try gremlin(rd, p1: 0)
        rd.active.update(id: rdg.body) { $0.classTimer = 2; $0.siblings.second = nil }
        let rd0 = try slot(rd, rdg.rider)
        frame(rd, rdg.body)
        XCTAssertGreaterThanOrEqual(rd.particles.counters.count, 8)
        XCTAssertEqual(try slot(rd, rdg.rider), rd0)
        // `.KillGremlinSprite` (M l. 69724–69758), the Kill proc `.HandleBurn` calls at the burn's end (headless has no
        // face pixels, so the burn never ends here — called directly): `+0xe9` set → return; counted → live − 1, the
        // stat + 1; score + 2000; `+0xe9 = +0xea = 1`; the back layer `+0xe9`; a mounted rider `+0xe9`; the rider's
        // backlink 0.
        let kw = try world()
        let kg = try gremlin(kw)
        EnemyCommon.killProc(kw, id: kg.body)
        XCTAssertEqual([Int(kw.globals.score), Int(kw.enemies.live), Int(kw.globals.achieved[0][3])], [2000, 0, 1])
        XCTAssertEqual([try slot(kw, kg.body).dead, try slot(kw, kg.body).killedForGood], [true, true])
        XCTAssertEqual([try slot(kw, kg.back).dead, try slot(kw, kg.back).killedForGood], [true, false])
        XCTAssertEqual([try slot(kw, kg.rider).dead, try slot(kw, kg.rider).killedForGood], [true, false])
        XCTAssertNil(try slot(kw, kg.rider).siblings.first)
        EnemyCommon.killProc(kw, id: kg.body)
        XCTAssertEqual([Int(kw.globals.score), Int(kw.enemies.live), Int(kw.globals.achieved[0][3])], [2000, 0, 1],
                       "`+0xe9` set: nothing")
        let kd = try world()
        let kdg = try gremlin(kd, window: false)
        kd.active.update(id: kdg.body) { $0.classTimer = 1 }
        EnemyCommon.killProc(kd, id: kdg.body)
        XCTAssertEqual([Int(kd.globals.score), Int(kd.enemies.live), Int(kd.globals.achieved[0][3])], [2000, 0, 0])
        XCTAssertEqual([try slot(kd, kdg.rider).dead], [false], "a dislodged rider lives on")
        XCTAssertNil(try slot(kd, kdg.rider).siblings.first)
        // The session's Handle dispatch by `+0x4c`: one Gremlin — body, back layer and rider — near the player runs a
        // frame: the body's mode-2 anim and facing, the back layer's follow, the rider's cooldown and mounted place.
        let sess = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 3, seed: 1)
        let sw = sess.world
        let me = try slot(sw, try XCTUnwrap(sw.playerID))
        let p = Placement(index: 0, flag: 1, byte1: 0, type: 0x6ea, p1: 2, p2: 50, p3: 400, p4: 0,
                          y: Int16(me.y - 150), x: Int16(me.x + 150))
        var ns = SpriteSlot(type: 0x6ea, x: Int(p.x), y: Int(p.y), recordIndex: -1)
        ns.oldPosition = SpriteSlot.Point(x: ns.x, y: ns.y)
        var none = EnemyCounting()
        let type = ns.type
        GremlinFloater.setupGremlin(&ns, record: p, counting: &none) { x, y, layer, store in
            var c = SpriteWorld.newRecord(type: type, x: x, y: y, layer: Int16(layer), handler: .gremlin, record: 0x1ff) { c in
                var n2 = EnemyCounting()
                GremlinFloater.setupGremlin(&c, record: nil, counting: &n2) { _, _, _, _ in nil }
            }
            store(&c)
            c.mayIdle = false
            return sw.active.insert(c)
        }
        ns.mayIdle = false
        let nid = sw.active.insert(ns)
        GremlinFloater.linkRider(sw, parent: nid)
        let back = try XCTUnwrap(ns.siblings.first), rider = try XCTUnwrap(ns.siblings.second)
        sw.active.update(id: rider) { $0.classWord15c = 5 }
        _ = sess.step(keys: KeyState())
        let sb = try slot(sw, nid)
        XCTAssertEqual([Int(sb.counterA6), sb.mirrored ? 1 : 0], [1, 1], "the body Handle ran")
        XCTAssertEqual(sb.face, f(0x6ea, 0))
        XCTAssertEqual([try slot(sw, back).x, try slot(sw, back).y], [sb.x, sb.y], "the back layer followed")
        XCTAssertEqual(try slot(sw, back).face, f(0x6eb, 0))
        XCTAssertEqual(try slot(sw, rider).classWord15c, 4, "the rider Handle ran")
        XCTAssertEqual(try slot(sw, rider).x, sb.x + 0x3e)
    }

    func testGremlinRiderSpit() throws {
        // The rider arm (M l. 69462–69633). Fire control: `+0x15c` − 1; at < 1 → 0 and, unless firing (`+0xb2 == 9`),
        // d = `.FindDesiredDirectionGeneric(rider centre, player centre)` into `+0x158`: facing left d ∈ {16, 17, 18}
        // → 18, 19…24 → 22; facing right {0, 1, 2} → 0, 30…35 → 32; else no shot; `+0x14c == 1` forces 18 / 0 and
        // drops the shot with the player behind; no shot with the body dead or its centre outside the view rect; a shot
        // (and `+0x14c ≠ 2`): `+0x158 = (d + 18) mod 36`, `+0x154 = 0`, `+0xb2 = 9`.
        func fire(right: Bool = false, d k: Int, state: Int32 = 0, bodyHP: Int16 = 500, bodyAt: (Int, Int)? = nil,
                  noBody: Bool = false, playerX: Int16? = nil, cooldown: Int32 = 0, firing: Bool = false)
            throws -> (fired: Bool, dir: Int32, t: Int32, face: FaceRef?, cd: Int32) {
            let w = try world()
            let g = try gremlin(w, p1: 0)
            let rc = try slot(w, g.rider).centre
            let pc = aim(from: rc, k)
            XCTAssertEqual(dir(rc, from: pc), k, "the aim helper")
            playerSprite(w, at: pc)
            w.player.centreX = playerX ?? Int16(pc.x)
            w.active.update(id: g.rider) { s in
                s.mirrored = right
                s.classTimer = state
                s.classWord15c = cooldown
                s.classWord154 = 3
                if firing { s.subState = 9 }
                if noBody { s.siblings.first = nil }
            }
            w.active.update(id: g.body) { s in
                s.hp = bodyHP
                if let (x, y) = bodyAt { s.centre = SpriteSlot.Point(x: x, y: y) }
            }
            if firing { w.active.update(id: g.rider) { $0.classWord158 = 77 } }
            frame(w, g.rider)
            let r = try slot(w, g.rider)
            return (r.subState == 9, r.classWord158, r.classWord154, r.face, r.classWord15c)
        }
        // Facing left: 15 | 16 17 18 | 19 … 24 | 25.
        for (k, fired, want) in [(15, false, Int32(15)), (16, true, 0), (17, true, 0), (18, true, 0), (19, true, 4),
                                 (22, true, 4), (24, true, 4), (25, false, 25), (0, false, 0), (32, false, 32)] {
            let r = try fire(d: k)
            XCTAssertEqual([r.fired ? 1 : 0, Int(r.dir)], [fired ? 1 : 0, Int(want)], "left, d \(k)")
            if fired {
                XCTAssertEqual([Int(r.t)], [1], "`+0x154 = 0`, then this frame's + 1")
                XCTAssertEqual(r.face, f(0x6ec, 0), "the firing face t 0")
            } else {
                XCTAssertEqual([Int(r.t)], [3])
                XCTAssertNil(r.face, "the face write to the rider's `+0x1d8` (always 0) never happens")
            }
        }
        // Facing right: 29 | 30 … 35 | 0 1 2 | 3.
        for (k, fired, want) in [(29, false, Int32(29)), (30, true, 14), (33, true, 14), (35, true, 14), (0, true, 18),
                                 (1, true, 18), (2, true, 18), (3, false, 3), (18, false, 18)] {
            let r = try fire(right: true, d: k)
            XCTAssertEqual([r.fired ? 1 : 0, Int(r.dir)], [fired ? 1 : 0, Int(want)], "right, d \(k)")
        }
        // Dislodged (`+0x14c == 1`): forced 18 / 0; no shot with the player behind (the global x); the gate still rules.
        let dl = try fire(d: 18, state: 1)
        XCTAssertEqual([dl.fired ? 1 : 0, Int(dl.dir)], [1, 0])
        let dl2 = try fire(d: 20, state: 1)
        XCTAssertEqual([dl2.fired ? 1 : 0, Int(dl2.dir)], [1, 0], "d 20 passes the gate, then 18")
        let dl3 = try fire(d: 5, state: 1)
        XCTAssertEqual([dl3.fired ? 1 : 0, Int(dl3.dir)], [0, 18], "no gate: no shot, `+0x158` = 18")
        let dl4 = try fire(d: 18, state: 1, playerX: 2000)
        XCTAssertEqual([dl4.fired ? 1 : 0, Int(dl4.dir)], [0, 18], "the player behind (c.x < P.x)")
        let dr = try fire(right: true, d: 0, state: 1, playerX: 0)
        XCTAssertEqual([dr.fired ? 1 : 0, Int(dr.dir)], [0, 0], "facing right, the player behind (P.x < c.x)")
        // The player's x equal to the rider's centre x (702) is not "behind" either way.
        XCTAssertTrue(try fire(d: 18, state: 1, playerX: 702).fired, "left, equal x")
        XCTAssertTrue(try fire(right: true, d: 0, state: 1, playerX: 702).fired, "right, equal x")
        // The cooldown's `= 0` store below 1 (0 − 1 → 0), firing or not.
        XCTAssertEqual([try fire(d: 16, firing: true).cd, try fire(d: 5).cd], [0, 0])
        let dr2 = try fire(right: true, d: 31, state: 1, playerX: 2000)
        XCTAssertEqual([dr2.fired ? 1 : 0, Int(dr2.dir)], [1, 18])
        // `+0x14c == 2`: never a shot; `+0x158` keeps the gated d.
        let s2 = try fire(d: 17, state: 2)
        XCTAssertEqual([s2.fired ? 1 : 0, Int(s2.dir)], [0, 18])
        // The body dead: no shot. No body: no view test, a shot.
        XCTAssertFalse(try fire(d: 18, bodyHP: 0).fired)
        XCTAssertTrue(try fire(d: 18, bodyHP: 1).fired)
        XCTAssertTrue(try fire(d: 18, noBody: true, playerX: nil).fired)
        XCTAssertTrue(try fire(d: 18, bodyHP: 0, noBody: true).fired)
        // The view rect (`PtInRect` of the body's centre in camera h − 32 … h + 640, v − 32 … v + 416; h 400, v 100).
        for (x, y, inside) in [(367, 300, false), (368, 300, true), (1039, 300, true), (1040, 300, false),
                               (600, 67, false), (600, 68, true), (600, 515, true), (600, 516, false)] {
            XCTAssertEqual(try fire(d: 18, bodyAt: (x, y)).fired, inside, "body centre (\(x), \(y))")
        }
        // The cooldown: 2 → 1, no aim; 1 → 0, the aim; firing: no aim.
        XCTAssertEqual(Int(try fire(d: 16, cooldown: 2).dir), 0, "no aim: `+0x158` stays 0")
        XCTAssertFalse(try fire(d: 16, cooldown: 2).fired)
        XCTAssertTrue(try fire(d: 16, cooldown: 1).fired)
        XCTAssertEqual(Int(try fire(d: 16, firing: true).dir), 77, "firing: no aim")
        // Firing (`+0xb2 == 9`), t = `+0x154`: mounted on a mode-1 body → body vx, vy · 0.65 (f64 0x100a1bc0); the face
        // 1772[t >> 1] for t < 8, else [6 − (t >> 1)]; t == 1 firehiss2 (496) when R(100) < 0x33 else firehiss (495),
        // Rand, 0xab; t == 7 the shot; t > 11 → `+0xb2 = 0`, cooldown R(0x1e) + 0x1e; t + 1.
        for hiss2 in [true, false] {
            let w = try world()
            let g = try gremlin(w, p1: 1, p2: 100, p3: 800)
            w.active.update(id: g.body) { $0.vx = 1000; $0.vy = 800 }
            w.active.update(id: g.rider) { s in
                s.subState = 9
                s.classWord154 = 0
                s.classWord158 = 0
                s.classWord15c = 0
            }
            var faces: [Int] = []
            for t in 0...12 {
                let rc = try slot(w, g.rider).centre
                if t == 1 { w.rng = FastRand(seed: seed { (r: inout FastRand) in r.next(100) == (hiss2 ? 0x32 : 0x33) }) }
                if t == 12 { w.rng = FastRand(seed: seed { differs($0, 0x1e) }) }
                var q = w.rng
                let bodyBefore = try slot(w, g.body)
                w.player.cues = []
                frame(w, g.rider)
                let r = try slot(w, g.rider)
                faces.append(r.face?.index ?? -1)
                let bb = try slot(w, g.body)
                XCTAssertEqual([bb.vx, bb.vy], [PlayerShot.fctiwz(Double(bodyBefore.vx) * 0.65),
                                                PlayerShot.fctiwz(Double(bodyBefore.vy) * 0.65)], "t \(t)")
                if t == 1 {
                    let pick = q.next(100)
                    XCTAssertEqual(pick < 0x33, hiss2)
                    let rate = q.soundRate()
                    XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDRand, snd: hiss2 ? 496 : 495, priority: 1,
                                                             volume: 0xab, position: rc, rate: rate)])
                    XCTAssertEqual(w.rng.seed, q.seed)
                } else {
                    XCTAssertEqual(w.player.cues, [], "t \(t)")
                }
                let shots = w.active.sprites.filter { $0.type == 0x712 }
                XCTAssertEqual(shots.count, t < 7 ? 0 : 1, "t \(t)")
                if t < 12 {
                    XCTAssertEqual([Int(r.subState), Int(r.classWord154)], [9, t + 1], "t \(t)")
                } else {
                    let cd = Int32(q.next(0x1e)) + 0x1e
                    XCTAssertEqual([Int(r.subState), Int(r.classWord154), Int(r.classWord15c)], [0, 1, Int(cd)])
                    XCTAssertEqual(w.rng.seed, q.seed)
                }
            }
            XCTAssertEqual(faces, [0, 0, 1, 1, 2, 2, 3, 3, 2, 2, 1, 1, 0])
        }
        // The shot (t == 7): `MTNewSprite(0x712, x + 4, y + 6, layer − 1, −1, .SetupEnemyShotSprite)`,
        // `FUN_1003f218(shot, dir, 0x708)`, vx + the body's vx, rect bottom − 3; dir 4 → `+0x17e = 1`, `+0x1aa = 0xdc`;
        // dir 14 → `+0x1aa = 0x140`.
        for (d, rot, flip) in [(Int32(0), Int16(0), false), (4, 0xdc, true), (14, 0x140, false), (18, 0, false),
                               (22, 0, false)] {
            for noBody in [false, true] {
                let w = try world()
                let g = try gremlin(w, p1: 2, p2: 50, p3: 400)
                w.active.update(id: g.body) { $0.vx = 333; $0.vy = 0 }
                w.active.update(id: g.rider) { s in
                    s.subState = 9
                    s.classWord154 = 7
                    s.classWord158 = d
                    s.classWord15c = 9
                    if noBody { s.siblings.first = nil }
                }
                let r0 = try slot(w, g.rider)
                frame(w, g.rider)
                let shot = try XCTUnwrap(w.active.sprites.first { $0.type == 0x712 }, "dir \(d)")
                var e = SpriteSlot(type: 0x712, x: 0, y: 0)
                PlayerShot.addDirImpulse(&e, dir: Int(d), magnitude: 0x708)
                XCTAssertEqual(shot.handler, .enemyShot)
                XCTAssertEqual([shot.x, shot.y, Int(shot.layer)], [r0.x + 4, r0.y + 6, 11], "dir \(d)")
                XCTAssertEqual([shot.vx, shot.vy], [e.vx + (noBody ? 0 : 333), e.vy], "dir \(d) no body \(noBody)")
                XCTAssertEqual(shot.hotRect, rect(8, 3, 0xf, 0xc - 3))
                XCTAssertEqual([Int(shot.rotation), shot.mirrored ? 1 : 0], [Int(rot), flip ? 1 : 0], "dir \(d)")
            }
        }
        // The rider's integration: x += vx, then `.ApplyGravityAndSeparateFromTiles` (2·v); on ground vx · 0.5.
        let air = try world()
        let ag = try gremlin(air)
        air.active.update(id: ag.rider) { s in
            s.classTimer = 1
            s.vx = 1000
            s.gravity = 0
            s.classWord15c = 9
        }
        frame(air, ag.rider)
        XCTAssertEqual([Int(try slot(air, ag.rider).vx), Int(try slot(air, ag.rider).x256)], [1000, (638 << 8) + 2000])
        // On a flat FG floor (kind 3) the rider's tile callback bounces it — `.WallBounce(…, 0xa0, …, 1)`: vy = −(vy ·
        // 0xa0 >> 8) — and never lands (`+0xce` is set only without the bounce on kind 3), so its vx · 0.5 rule does not
        // fire there; |vy| < 0x100 after a bounce → 0.
        let gr = try world(floorRow: 20)
        let gg = try gremlin(gr, x: 600, y: 560)
        gr.active.update(id: gg.rider) { s in
            s.classTimer = 1
            s.gravity = 0x96
            s.classWord15c = 1000
        }
        var prevVY: Int32 = 0, flips = 0
        for _ in 0..<40 {
            frame(gr, gg.rider)
            let q = try slot(gr, gg.rider)
            XCTAssertEqual(q.groundKind, 0, "bouncing, never grounded")
            if q.vy < 0 && 0 <= prevVY {
                // The bounce lands in the entry separation (after the Handle's own y += vy), before vy += gravity.
                if flips == 0 { XCTAssertEqual(q.vy, 0 &- ((prevVY &* 0xa0) >> 8) &+ 0x96, "the first bounce") }
                flips += 1
            }
            prevVY = q.vy
        }
        XCTAssertGreaterThanOrEqual(flips, 3)
        XCTAssertEqual(try slot(gr, gg.rider).vx, 0)
        // The dislodged rider's death: HP < 1 (or y > the map height · 32 → HP −1): N = 0xaa (prefs Effects 1) or 100;
        // the body `+0x14c = 2`, `+0x1d8 = 0`; "crawler death" 703 (3D, 0x100); `+0xc0 = 0`, `+0xe9 = 1`, score + 500;
        // N particles (R(6) h − 3, R(6) v + 0x10, vx R(0x28a) − 0x145, vy −0x352 − R(700) − R(200)) and N >> 3 with
        // R(900) − 0x1c2, −0x352 − R(900) − R(300). Not counted.
        for (effects, n) in [(Int16(1), 0xaa), (2, 100)] {
            let w = try world()
            let g = try gremlin(w)
            w.active.update(id: g.rider) { s in
                s.classTimer = 1
                s.hp = 0
                s.classWord15c = 9
                s.face = FaceRef(pict: GremlinFloater.riderSet, index: 2, set: .encoded)
            }
            let rc = try slot(w, g.rider).centre
            var q = w.rng
            frame(w, g.rider, effects: effects)
            var want: [ParticlePool.Record] = []
            func blood(_ a: Int16, _ b: Int16, _ c: Int16, _ off: Int) {
                let h = rc.x + Int(q.next(6)) - 3
                let v = rc.y + Int(q.next(6)) + 0x10
                let ra = Int(q.next(a)), rb = Int(q.next(b)), rcc = Int(q.next(c))
                var p = ParticlePool.Record()
                p.alive = true
                p.shape = 4
                p.kind = 2
                p.gravity = 0x78
                p.x = Int32(h) << 8
                p.y = Int32(v) << 8
                p.vx = Int32(rcc - off)
                p.vy = Int32(-0x352 - ra - rb)
                p.mode = 1
                want.append(p)
            }
            for _ in 0..<n { blood(700, 200, 0x28a, 0x145) }
            for _ in 0..<(n >> 3) { blood(900, 300, 900, 0x1c2) }
            XCTAssertEqual(Array(w.particles.records.prefix(want.count)), want, "effects \(effects)")
            XCTAssertFalse(w.particles.records[want.count].alive)
            XCTAssertEqual(w.rng.seed, q.seed)
            let r = try slot(w, g.rider)
            XCTAssertEqual([r.dead, r.face == nil], [true, true])
            XCTAssertEqual([Int(w.globals.score), Int(w.enemies.live), Int(w.globals.achieved[0][3])], [500, 1, 0])
            XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeD, snd: 703, priority: 1, volume: 0x100, position: rc)])
            let b = try slot(w, g.body)
            XCTAssertEqual([Int(b.classTimer)], [2])
            XCTAssertNil(b.siblings.second)
        }
        // Below the map (y > hdr 0xb282 · 32): HP −1 and the death; at the edge, alive.
        let rows = Int(try world().level.header.gridHeight) << 5
        for (y, dies) in [(rows, false), (rows + 1, true)] {
            let w = try world()
            let g = try gremlin(w)
            w.active.update(id: g.rider) { s in
                s.classTimer = 1
                s.y = y
                s.gravity = 0
                s.classWord15c = 9
            }
            frame(w, g.rider)
            XCTAssertEqual(try slot(w, g.rider).dead, dies, "y \(y)")
            XCTAssertEqual(try slot(w, g.rider).hp, dies ? -1 : 500)
        }
        // A mounted rider at HP 0 does not die (the test sits inside `+0x14c ≠ 0`).
        let mt = try world()
        let mtg = try gremlin(mt)
        mt.active.update(id: mtg.rider) { $0.hp = 0; $0.classWord15c = 9 }
        frame(mt, mtg.rider)
        XCTAssertFalse(try slot(mt, mtg.rider).dead)
    }

    func testGremlinHits() throws {
        // `.HitGremlinSprite` (M l. 69640–69721): nothing with `+0xe9` or `+0xea`. A player shot with `+0xa6 == 0`:
        // `.KillPlayerShot(o, 0, 0)`; type 1 → `.TurnIntoStatue`; else `.HurtSprite(s, o.+0xa4, o.vx >> 3, o.vy >> 3, 2,
        // 8)` and on a hurt: `+0xa6 < 2 → 0x15`; HP > 0 → `.BloodSpray(0x28, 400, 0x96, 2)`; HP < 0xc9 and (rider
        // mounted or a child part) → 702 (3D, 0x100); else HP > 0 → 701 (Rand, 0x55) and, R(100) < 0x12 with the rider
        // mounted, 477/478 (R(2)) pitched 84000 + R(5000) (the R(5000) first), 0xab; then a mounted body with a rider
        // and R(100) > 0x50 is dislodged: 703 (Rand, 0x55), `+0x14c = 1`, rider HP R(300) + 300, rider vx ∓(R(200) +
        // 300) by the facing, vy −0x226 − R(200), gravity 0x96. A Statue or Box: the crush.
        func hit(seed s: Int32, hp: Int16 = 500, damage: Int16 = 150, mirrored: Bool = false, state: Int32 = 0,
                 a6: Int16 = 0, part: Bool = false) throws -> (w: SpriteWorld, g: (body: Int, back: Int, rider: Int)) {
            let w = try world()
            let g = try gremlin(w)
            w.active.update(id: g.body) { b in
                b.hp = hp
                b.mirrored = mirrored
                b.classTimer = state
                b.counterA6 = a6
            }
            let target = part ? g.rider : g.body
            if part {
                w.active.update(id: g.rider) { r in
                    r.hp = hp
                    r.classTimer = state
                    r.counterA6 = a6
                    GremlinFloater.calcCentre(&r)                       // as its first frame leaves it
                }
            }
            let o = try other(w, over: target, damage: damage)
            w.rng = FastRand(seed: s)
            w.player.cues = []
            GremlinFloater.hitGremlin(w, id: target, other: o)
            return (w, g)
        }
        /// The draws after the shot's kill, the hurt and the spray (2 × 0x28) for a hit at `seed`.
        func plan(_ s: Int32, spray: Bool = true) -> FastRand {
            var r = FastRand(seed: s)
            if spray { for _ in 0..<0x50 { _ = r.next(1) } }
            return r
        }
        func find(_ pick: (inout FastRand) -> Bool) -> Int32 { seed { r in for _ in 0..<0x50 { _ = r.next(1) }; return pick(&r) } }
        // HP 500 − 150: Ouch, then (mounted) the monster draw, then the dislodge draw — both sides of R(100) < 0x12
        // and of R(100) > 0x50.
        let cases: [(monster: Int16, dislodge: Int16)] = [(0x11, 0x51), (0x12, 0x50), (0x11, 0x50), (0x63, 0x51)]
        for c in cases {
            let s = find { r in
                _ = r.soundRate()
                guard r.next(100) == c.monster else { return false }
                if c.monster < 0x12 { _ = r.next(5000); _ = r.next(2) }
                return r.next(100) == c.dislodge
            }
            for mirrored in [false, true] {
                let (w, g) = try hit(seed: s, mirrored: mirrored)
                let b = try slot(w, g.body)
                var q = plan(s)
                XCTAssertEqual([Int(b.hp), Int(b.invulnerable), Int(b.flash), Int(b.counterA6)], [350, 2, 8, 0x15])
                XCTAssertEqual([b.vx, b.vy], [125, 800 - 25], "the hurt's push: shot v >> 3")
                XCTAssertEqual(w.particles.records.prefix(0x28).filter { $0.alive && $0.kind == 2 }.count, 0x28)
                // `.BloodSpray(s, o, 0x28, 400, 0x96, 2)`: the 10° vector of length 400 from the shot's centre toward the
                // body's, negated and truncated, plus R(0x96) − 0x4b each (vy drawn first).
                let sd = BloodSpray.direction(target: (v: Int16(b.centre.y), h: Int16(b.centre.x)),
                                              from: (v: Int16(b.centre.y), h: Int16(b.centre.x)))
                let vec = BloodSpray.vector(sd, magnitude: 400)
                let nx = Int32((-vec.x).rounded(.towardZero)), ny = Int32((-vec.y).rounded(.towardZero))
                var sq = FastRand(seed: s)
                var spray: [[Int32]] = []
                for _ in 0..<0x28 {
                    let vy = ny + Int32(sq.next(0x96)) - 0x4b
                    spray.append([nx + Int32(sq.next(0x96)) - 0x4b, vy])
                }
                XCTAssertEqual(w.particles.records.prefix(0x28).map { [$0.vx, $0.vy] }, spray)
                XCTAssertEqual(Set(w.particles.records.prefix(0x28).map { [Int($0.gravity), Int($0.kind)] }), [[0xbe, 2]])
                var want = [PlayerCue(call: .threeDRand, snd: 701, priority: 1, volume: 0x55, position: b.centre,
                                      rate: q.soundRate())]
                let m = q.next(100)
                if m < 0x12 {
                    let p = Int32(q.next(5000)), k = q.next(2)
                    want.append(PlayerCue(call: .threeDPitched, snd: 477 + k, priority: 1, volume: 0xab,
                                          position: b.centre, rate: p + 84000))
                }
                let d = q.next(100)
                XCTAssertEqual([m, d], [c.monster, c.dislodge])
                let r = try slot(w, g.rider)
                if 0x50 < d {
                    want.append(PlayerCue(call: .threeDRand, snd: 703, priority: 1, volume: 0x55, position: b.centre,
                                          rate: q.soundRate()))
                    let hp = q.next(300) + 300, vx = Int32(q.next(200)) + 300, vy = -0x226 - Int32(q.next(200))
                    XCTAssertEqual([Int(b.classTimer), Int(r.hp), Int(r.vx), Int(r.vy), Int(r.gravity)],
                                   [1, Int(hp), Int(mirrored ? vx : -vx), Int(vy), 0x96], "dislodged")
                } else {
                    XCTAssertEqual([Int(b.classTimer), Int(r.hp), Int(r.vx), Int(r.vy), Int(r.gravity)],
                                   [0, 500, 0, 0, 0], "kept")
                }
                XCTAssertEqual(w.player.cues, want, "monster \(c.monster) dislodge \(c.dislodge)")
                XCTAssertEqual(w.rng.seed, q.seed)
            }
        }
        // HP exactly 0 left: no blood (HP > 0 fails), 702 (< 0xc9, mounted), then the dislodge draw; HP 1 left: the blood
        // and 702. A dislodged body left at HP 0: no sound, no draw.
        for (hp, blood) in [(Int16(150), false), (151, true)] {
            let (w0, g0) = try hit(seed: 11, hp: hp)
            let b0 = try slot(w0, g0.body)
            XCTAssertEqual([Int(b0.hp), Int(w0.particles.counters.count)], [Int(hp) - 150, blood ? 0x28 : 0])
            XCTAssertEqual(w0.player.cues.first, PlayerCue(call: .threeD, snd: 702, priority: 1, volume: 0x100,
                                                           position: b0.centre))
            var q = blood ? plan(11) : FastRand(seed: 11)
            if 0x50 < q.next(100) {
                _ = q.soundRate(); _ = q.next(300); _ = q.next(200); _ = q.next(200)
            }
            XCTAssertEqual(w0.rng.seed, q.seed, "HP \(hp - 150)")
        }
        let (z0, zg) = try hit(seed: 11, hp: 150, state: 1)
        XCTAssertEqual([Int(try slot(z0, zg.body).hp), z0.player.cues.count], [0, 0])
        XCTAssertEqual(z0.rng.seed, 11, "no draw")
        // The dislodge's R(300), R(200), R(200) at a point where R(n ± 1) differs.
        let lucky = find { r in
            _ = r.soundRate()
            guard 0x12 <= r.next(100), 0x50 < r.next(100) else { return false }
            _ = r.soundRate()
            guard self.differs(r, 300) else { return false }
            _ = r.next(300)
            guard self.differs(r, 200) else { return false }
            _ = r.next(200)
            return self.differs(r, 200)
        }
        let (lw, lg) = try hit(seed: lucky)
        var lq = plan(lucky)
        _ = lq.soundRate(); _ = lq.next(100); _ = lq.next(100); _ = lq.soundRate()
        let lhp = lq.next(300) + 300, lvx = -(Int32(lq.next(200)) + 300), lvy = -0x226 - Int32(lq.next(200))
        let lr = try slot(lw, lg.rider)
        XCTAssertEqual([Int(lr.hp), Int(lr.vx), Int(lr.vy)], [Int(lhp), Int(lvx), Int(lvy)])
        // HP < 0xc9 (200 left: 702; 201 left: 701): mounted body.
        for (hp, uhOh) in [(Int16(350), true), (351, false), (300, true)] {
            let s = find { r in _ = r.soundRate(); _ = r.next(100); return r.next(100) < 0x50 }
            var pr = plan(s)
            let (w, g) = try hit(seed: s, hp: hp)
            let b = try slot(w, g.body)
            XCTAssertEqual(w.player.cues.first, uhOh
                           ? PlayerCue(call: .threeD, snd: 702, priority: 1, volume: 0x100, position: b.centre)
                           : PlayerCue(call: .threeDRand, snd: 701, priority: 1, volume: 0x55, position: b.centre,
                                       rate: pr.soundRate()), "HP \(hp - 150)")
        }
        // Killed by the hit: no blood, 702 (mounted), then the dislodge draw.
        let ks = seed { $0.next(100) > 0x50 }
        let (kw, kg) = try hit(seed: ks, hp: 100)
        var kq = FastRand(seed: ks)
        _ = kq.next(100)
        let kb = try slot(kw, kg.body)
        XCTAssertEqual([Int(kb.hp), Int(kw.particles.counters.count)], [-50, 0])
        XCTAssertEqual(kw.player.cues, [PlayerCue(call: .threeD, snd: 702, priority: 1, volume: 0x100, position: kb.centre),
                                        PlayerCue(call: .threeDRand, snd: 703, priority: 1, volume: 0x55,
                                                  position: kb.centre, rate: kq.soundRate())])
        XCTAssertEqual(kb.classTimer, 1)
        // A dislodged body at HP 150 left: 701 and the R(100) draw, no monster sound even under 0x12, no dislodge draw.
        let ds = find { r in _ = r.soundRate(); return r.next(100) < 0x12 }
        let (dw, dg) = try hit(seed: ds, hp: 300, state: 1)
        var dq = plan(ds)
        XCTAssertEqual(dw.player.cues, [PlayerCue(call: .threeDRand, snd: 701, priority: 1, volume: 0x55,
                                                  position: try slot(dw, dg.body).centre, rate: dq.soundRate())])
        _ = dq.next(100)
        XCTAssertEqual(dw.rng.seed, dq.seed)
        // The rider (a child part) hit after its fall: HP 150 left → 702; HP 350 left → 701; never a dislodge draw.
        let (rw, rg) = try hit(seed: 7, hp: 300, state: 1, part: true)
        XCTAssertEqual(rw.player.cues, [PlayerCue(call: .threeD, snd: 702, priority: 1, volume: 0x100,
                                                  position: try slot(rw, rg.rider).centre)])
        XCTAssertEqual(rw.rng.seed, plan(7).seed)
        let (rw2, rg2) = try hit(seed: 7, hp: 500, state: 1, part: true)
        var rq = plan(7)
        XCTAssertEqual(rw2.player.cues, [PlayerCue(call: .threeDRand, snd: 701, priority: 1, volume: 0x55,
                                                   position: try slot(rw2, rg2.rider).centre, rate: rq.soundRate())])
        _ = rq.next(100)
        XCTAssertEqual(rw2.rng.seed, rq.seed)
        XCTAssertEqual(try slot(rw2, rg2.body).classTimer, 1)
        // The `+0xa6` guard: 1 → 0x15, 2 kept.
        XCTAssertEqual(try slot(try hit(seed: 9, a6: 1).w, try hit(seed: 9, a6: 1).g.body).counterA6, 0x15)
        let a2 = try hit(seed: 9, a6: 2)
        XCTAssertEqual(try slot(a2.w, a2.g.body).counterA6, 2)
        // Skips: `+0xe9`, `+0xea`, a cooling shot (`+0xa6 ≠ 0`), an explosion 0x4b7 (no hazard arm).
        for kind in 0..<4 {
            let w = try world()
            let g = try gremlin(w)
            let o: Int
            switch kind {
            case 0: w.active.update(id: g.body) { $0.dead = true }; o = try other(w, over: g.body)
            case 1: w.active.update(id: g.body) { $0.killedForGood = true }; o = try other(w, over: g.body)
            case 2: o = try other(w, over: g.body) { $0.counterA6 = 1 }
            default: o = try other(w, over: g.body, type: 0x4b7, handler: .effect) { $0.phase = 0 }
            }
            GremlinFloater.hitGremlin(w, id: g.body, other: o)
            XCTAssertEqual([Int(try slot(w, g.body).hp)], [500], "skip \(kind)")
            XCTAssertFalse(try slot(w, o).dead, "skip \(kind)")
        }
        // The Statue spell (a shot of type 1).
        let st = try world()
        let stg = try gremlin(st)
        let sh = try other(st, over: stg.body, type: 1)
        GremlinFloater.hitGremlin(st, id: stg.body, other: sh)
        XCTAssertEqual(try slot(st, stg.body).handler, .statue)
        XCTAssertEqual(try slot(st, stg.body).hp, 500)
        // A falling Box and a falling Statue crush it: HP 0, `+0x150 = 0x16`.
        for h in [SpriteHandler.box, .statue] {
            let w = try world()
            let g = try gremlin(w)
            w.active.update(id: g.body) { $0.vy = -0x400 }
            let s = try slot(w, g.body)
            let bx = s.x + s.hotRect.left, by = s.y + s.hotRect.top - 30
            let solid = try XCTUnwrap(w.newSprite(type: 0xc12, x: bx, y: by, layer: 2, handler: h) { c in
                c.x = bx
                c.y = by
                c.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x20, right: s.hotRect.right - s.hotRect.left)
                c.vy = 1
            })
            GremlinFloater.hitGremlin(w, id: g.body, other: solid)
            XCTAssertEqual([Int(try slot(w, g.body).hp), Int(try slot(w, g.body).classWord150)], [0, 0x16], "\(h)")
        }
        // `.HitGremlinTileSprite` (M l. 69761–69817): a dying body (`+0xb0 == 4`) or the rider (`+0xec == 2`) → vx · 0.8
        // on every call, and the FG bounce takes 0xa0 and its last argument 1; a live body: no scaling.
        for (part, dying, want) in [(Int16(2), false, Int32(800)), (0, true, 800), (0, false, 1000)] {
            let w = try world()
            let g = try gremlin(w)
            let id = part == 2 ? g.rider : g.body
            w.active.update(id: id) { s in
                s.vx = 1000
                if dying { s.subtype = 4 }
            }
            GremlinFloater.hitGremlinTile(TileSolver(world: w), id: id, pos: TilePos(x: 1, y: 1), kind: 0,
                                          layer: .background)
            XCTAssertEqual(try slot(w, id).vx, want, "part \(part) dying \(dying)")
        }
        // After an FG bounce, |vy| < 0x100 → 0: the rider (factor 0xa0) landing on a kind-3 tile with vy 410 bounces to
        // −(410 · 0xa0 >> 8) = −0x100, kept; with vy 408 to −0xff → 0.
        for (vy, want) in [(Int32(410), Int32(-0x100)), (408, 0)] {
            let w = try world(floorRow: 20)
            let g = try gremlin(w)
            w.active.update(id: g.rider) { r in
                r.x = 640
                r.y = 640 + 0x10 - 0x16 + 2                         // kind 3's surface is the tile's Y + 0x10
                r.x256 = Int32(r.x) << 8
                r.y256 = Int32(r.y) << 8
                r.vx = 0
                r.vy = vy
            }
            GremlinFloater.hitGremlinTile(TileSolver(world: w), id: g.rider, pos: TilePos(x: 640, y: 640), kind: 3,
                                          layer: .foreground)
            XCTAssertEqual(try slot(w, g.rider).vy, want, "vy \(vy)")
        }
        // Through the session's hit dispatch.
        let hw = try world()
        let hg = try gremlin(hw)
        let hs = try other(hw, over: hg.body)
        FerazelSession.hitCallback(hw, hg.body, hs)
        XCTAssertEqual(try slot(hw, hg.body).hp, 350)
    }

    // MARK: - the Floater

    func testFloaterCycle() throws {
        // `.SetupFloaterSprite` (M l. 69834–69907): `.InitSprite`; `+0x84`/`+0x86` 0; layer 0xb; the Floater Handle, hit
        // and tile callbacks; gravity 0; `+0xc0 = 0`; HP 500; `+0xc ← +8`, `+0xa ← +6`; 0x6f4…0x6fd: the 1780 set
        // marked, rect (0x23, 1, 0x3e, 0x4b), no tile callback, `+0x14c` = p1 (0 → 0x41), `+0xa6` = p2, `+0x154` = p3
        // (0 → 0x50), home `+0x158` / `+0x15c` = `+0xc` / `+0xa`, `+0x46 = 0`, `+0x88 = 0`; 0x6fe…0x707: the 1790 / 1791
        // sets marked, rect (0x17, 2, 0x38, 0x5c), nothing else; `+0xb0 = 7`; counted; the 24.8 position.
        let w = try world()
        let before = w.rng.seed
        let (id, e) = try floater(w, x: 600, y: 300)
        XCTAssertEqual(w.rng.seed, before, "no draw")
        var s = try slot(w, id)
        XCTAssertEqual(s.handler, .floater)
        XCTAssertEqual([s.hasHit, s.hasTileHit, s.lightOverlay, s.countedInTotals, s.keepRecord, s.killedForGood],
                       [true, false, false, true, false, false])
        XCTAssertEqual([s.noWriteBack189, s.noWriteBack18a, s.keepRecordAtKill], [false, false, false], "no flags")
        XCTAssertEqual([Int(s.layer), Int(s.gravity), Int(s.hp), Int(s.subtype), Int(s.phase), Int(s.counterA6)],
                       [0xb, 0, 500, 7, 0, 0])
        XCTAssertEqual([s.classTimer, s.classWord154, s.classWord158, s.classWord15c], [0x41, 0x50, 600, 300])
        XCTAssertEqual(s.hotRect, rect(0x23, 1, 0x3e, 0x4b))
        XCTAssertEqual([s.x, s.y, Int(s.x256), Int(s.y256)], [600, 300, 600 << 8, 300 << 8])
        XCTAssertEqual([Int(s.particleOffsetX), Int(s.particleOffsetY)], [0, 0])
        XCTAssertEqual(e.spawn, .idle)
        XCTAssertEqual(s.face, f(0x6f4, 0), "the Handle's first face (stand-in)")
        XCTAssertEqual(w.enemies.live, 1)
        let pw = try world()
        let (pid2, _) = try floater(pw, p1: 30, p2: 7, p3: 120)
        XCTAssertEqual([try slot(pw, pid2).classTimer, Int32(try slot(pw, pid2).counterA6), try slot(pw, pid2).classWord154],
                       [30, 7, 120])
        for t: Int16 in [0x6f4, 0x6f9, 0x6fd] {
            XCTAssertEqual(CachedFaces.marks(type: t).sets, [0x6f4], "M l. 69876")
            XCTAssertEqual(SpriteHandler.forClass(type: t), .floater)
        }
        for t: Int16 in [0x6fe, 0x707] {
            XCTAssertEqual(CachedFaces.marks(type: t).sets, [0x6fe, 0x6ff], "M l. 69870–69871")
            XCTAssertEqual(SpriteHandler.forClass(type: t), .floater)
            // The unfinished variant: its sets 1790 / 1791 are absent from the data and its home / box are 0 —
            // `FastRand(0)` reseeds from the clock. `SetupFaces` refuses it; the Setup arm is as written.
            XCTAssertThrowsError(try floater(try world(), type: t))
            var v = SpriteSlot(type: t, x: 0, y: 0)
            v.oldPosition = SpriteSlot.Point(x: 40, y: 50)
            var c = EnemyCounting(window: true)
            GremlinFloater.setupFloater(&v, record: nil, counting: &c)
            XCTAssertEqual(v.hotRect, rect(0x17, 2, 0x38, 0x5c))
            XCTAssertEqual([v.hasTileHit, v.lightOverlay, v.countedInTotals], [true, true, true])
            XCTAssertEqual([v.classTimer, v.classWord154, v.classWord158, Int32(v.counterA6), Int32(v.subtype)],
                           [0, 0, 0, 0, 7])
            XCTAssertEqual([v.x, v.y, Int(v.layer)], [40, 50, 0xb])
            XCTAssertEqual(c.live, 1)
        }
        XCTAssertEqual(SetupFaces.sheet(pict: 0x6f4), SetupFaces.Sheet(pict: 0x6f4, count: 6, cellWidth: 100,
                                                                     cellHeight: 0x50, columns: 6, clut: 200))
        // The hidden countdown: `+0xa6` > 0 → − 1, invisible, the phase kept; at 0 the cycle runs.
        let hw = try world()
        let (hid, _) = try floater(hw, p2: 2)
        frame(hw, hid)
        XCTAssertEqual([Int(try slot(hw, hid).counterA6), Int(try slot(hw, hid).phase)], [1, 0])
        XCTAssertNil(try slot(hw, hid).face)
        frame(hw, hid)
        XCTAssertEqual([Int(try slot(hw, hid).counterA6), Int(try slot(hw, hid).phase)], [0, 0])
        XCTAssertNil(try slot(hw, hid).face)
        // Phase 0: the teleport — x = home x − box/2 + R(box), y likewise (the x draw first), vx = R(600) − 300, vy
        // likewise; the phase + 1; `.ApplyGravityAndSeparateFromTiles` drifts it once by v.
        hw.rng = FastRand(seed: seed { r in
            _ = r.next(0x50); _ = r.next(0x50)
            guard self.differs(r, 600) else { return false }
            _ = r.next(600)
            return self.differs(r, 600)
        })
        var q = hw.rng
        let tx = 600 - 0x28 + Int(q.next(0x50)), ty = 300 - 0x28 + Int(q.next(0x50))
        let vx = Int32(q.next(600)) - 300, vy = Int32(q.next(600)) - 300
        frame(hw, hid)
        s = try slot(hw, hid)
        XCTAssertEqual([Int(s.counterA6), Int(s.phase)], [0, 1])
        XCTAssertEqual([s.vx, s.vy], [vx, vy])
        XCTAssertEqual([s.x256, s.y256], [(Int32(tx) << 8) + vx, (Int32(ty) << 8) + vy])
        XCTAssertEqual(hw.rng.seed, q.seed)
        XCTAssertEqual(s.face, f(0x6f4, 0))
        XCTAssertEqual(s.mode, 0xb0002)
        // An odd box halves toward zero: 0x51 / 2 = 40.
        // A negative odd box (p3 −9, a record the Setup takes as is): box / 2 truncates toward zero (−4, not −5), and
        // `FastRand(−9)` returns ≤ 0.
        let nw = try world()
        let (nid9, _) = try floater(nw, p3: -9)
        var nq = nw.rng
        let nx9 = 600 + 4 + Int(nq.next(-9)), ny9 = 300 + 4 + Int(nq.next(-9))
        frame(nw, nid9)
        let n9 = try slot(nw, nid9)
        XCTAssertEqual([Int((n9.x256 - n9.vx) >> 8), Int((n9.y256 - n9.vy) >> 8)], [nx9, ny9])
        let ow = try world()
        let (oid, _) = try floater(ow, p3: 0x51)
        var oq = ow.rng
        let ox = 600 - 0x28 + Int(oq.next(0x51))
        ow.active.update(id: oid) { _ in }
        frame(ow, oid)
        XCTAssertEqual(Int(try slot(ow, oid).x256 >> 8) - Int(try slot(ow, oid).vx >> 8), ox, "home − 40 + R(0x51)")
        // The phase table: the face (or kept), the tint `+0xb8` (or kept), the facing (phases < 20 only).
        let keepFace = f(0x6f4, 9), keepMode: UInt32 = 0x12345
        let rows: [(phase: Int16, face: FaceRef??, mode: UInt32?)] = [
            (0, .some(f(0x6f4, 0)), 0xb0002), (3, .some(f(0x6f4, 0)), 0xb0002), (4, .some(f(0x6f4, 0)), 0xb0000),
            (7, .some(f(0x6f4, 0)), 0xb0000), (8, .some(f(0x6f4, 0)), 0xb0001), (11, .some(f(0x6f4, 0)), 0xb0001),
            (12, nil, 0), (19, nil, 0), (20, .some(f(0x6f4, 1)), nil), (21, .some(f(0x6f4, 1)), nil),
            (22, .some(f(0x6f4, 2)), nil), (28, .some(f(0x6f4, 5)), nil), (30, nil, nil), (64, nil, nil),
            (65, .some(f(0x6f4, 5)), nil), (66, .some(f(0x6f4, 4)), nil), (73, .some(f(0x6f4, 1)), nil),
            (74, .some(f(0x6f4, 0)), nil), (75, nil, 0xb0001), (78, nil, 0xb0001), (79, nil, 0xb0000),
            (82, nil, 0xb0000), (83, nil, 0xb0002), (86, nil, 0xb0002),
        ]
        for row in rows {
            for right in [false, true] {
                let t = try world(px: right ? 2000 : 0)
                let (tid, _) = try floater(t, p3: 0x50)
                t.active.update(id: tid) { s in
                    s.phase = row.phase
                    s.face = keepFace
                    s.mode = keepMode
                    s.mirrored = !right
                }
                frame(t, tid)
                let u = try slot(t, tid)
                XCTAssertEqual(u.phase, row.phase + 1, "phase \(row.phase)")
                XCTAssertEqual(u.face, row.face ?? keepFace, "phase \(row.phase)")
                XCTAssertEqual(u.mode, row.mode ?? keepMode, "phase \(row.phase)")
                XCTAssertEqual(u.mirrored, row.phase < 20 ? right : !right, "phase \(row.phase) facing")
            }
        }
        // The facing: playerX ≥ the centre x (the carry idiom, raw 10081810–10081824).
        for (dx, right) in [(0, true), (-1, false), (1, true)] {
            let t = try world()
            let (tid, _) = try floater(t)
            let c = try slot(t, tid).centre
            t.player.centreX = Int16(c.x + dx)
            t.active.update(id: tid) { $0.phase = 13 }
            frame(t, tid)
            XCTAssertEqual(try slot(t, tid).mirrored, right, "dx \(dx)")
        }
        // Phase ≥ 87: invisible, the tint 0, phase 0, `+0xa6` = the hidden period.
        let z = try world()
        let (zid, _) = try floater(z, p1: 33)
        z.active.update(id: zid) { $0.phase = 87; $0.mode = keepMode }
        frame(z, zid)
        let zs = try slot(z, zid)
        XCTAssertEqual([Int(zs.phase), Int(zs.counterA6), Int(zs.mode)], [0, 33, 0])
        XCTAssertNil(zs.face)
        // The fade-out while hurt-flashing: phase = 0x4a, opaque — then + 1 (the flash counted down first).
        for (flash, flashes) in [(Int16(2), true), (1, false)] {
            let t = try world()
            let (tid, _) = try floater(t)
            t.active.update(id: tid) { $0.phase = 80; $0.flash = flash }
            frame(t, tid)
            let u = try slot(t, tid)
            XCTAssertEqual([Int(u.phase), Int(u.mode)], flashes ? [0x4b, 0] : [81, 0xb0000], "flash \(flash)")
        }
        // A Wraith never dies of damage: HP is never tested.
        let n = try world()
        let (nid, _) = try floater(n)
        n.active.update(id: nid) { $0.hp = -300; $0.phase = 40 }
        frame(n, nid)
        XCTAssertEqual([try slot(n, nid).dead, try slot(n, nid).handler == .floater], [false, true])
        XCTAssertEqual(try slot(n, nid).phase, 41)
        // The session's Handle dispatch: one Wraith near the player, kept active, runs its phase 0.
        let sess = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 3, seed: 1)
        let sw = sess.world
        let me = try slot(sw, try XCTUnwrap(sw.playerID))
        var nf = SpriteSlot(type: 0x6f4, x: me.x + 150, y: me.y - 150, recordIndex: -1)
        nf.oldPosition = SpriteSlot.Point(x: nf.x, y: nf.y)
        var none = EnemyCounting()
        GremlinFloater.setupFloater(&nf, record: Placement(index: 0, flag: 1, byte1: 0, type: 0x6f4, p1: 0, p2: 0, p3: 0,
                                                           p4: 0, y: Int16(nf.y), x: Int16(nf.x)), counting: &none)
        nf.mayIdle = false
        let nfid = sw.active.insert(nf)
        _ = sess.step(keys: KeyState())
        XCTAssertEqual([Int(try slot(sw, nfid).phase)], [1], "the Floater Handle ran")
        XCTAssertEqual(try slot(sw, nfid).face, f(0x6f4, 0))
        XCTAssertEqual(try slot(sw, nfid).mode, 0xb0002)
    }

    func testFloaterShotAtStep0x1d() throws {
        // Phase 0x1d: `MTNewSprite(own type, x + off − 12, y + 10, layer 0, −1, .SetupEnemyShotSprite)`, off 6 facing
        // left / 0x5e facing right; "elecshot" (504, 3D, 0xab) at (x + off, y + 0x16); the shot's `+0x15c` =
        // `.FindDesiredDirectionGeneric((P.y + 8, P.x), (y + 0x16, x + off))`.
        for (type, right) in [(Int16(0x6f4), false), (0x6f4, true), (0x6f8, false)] {
            let w = try world(px: 900, py: 500)
            let (id, _) = try floater(w, type: type, x: 600, y: 300)
            w.active.update(id: id) { s in
                s.phase = 0x1d
                s.mirrored = right
                s.face = FaceRef(pict: GremlinFloater.wraithSet, index: 5, set: .encoded)
                s.vx = 0
                s.vy = 0
            }
            let s0 = try slot(w, id)
            var q = w.rng
            let p46 = q.next(5)
            let p46b = type == 0x6f4 ? q.next(0xf) : p46
            frame(w, id)
            let off = right ? 0x5e : 6
            let shots = w.active.sprites.filter { $0.handler == .enemyShot }
            XCTAssertEqual(shots.count, 1, "type \(type) right \(right)")
            let shot = try XCTUnwrap(shots.first)
            XCTAssertEqual([shot.type, Int16(shot.x), Int16(shot.y), Int16(shot.layer)],
                           [type, Int16(s0.x + off - 12), Int16(s0.y + 10), 0])
            XCTAssertEqual(shot.phase, p46b, "the shot Setup's draws")
            XCTAssertEqual(w.rng.seed, q.seed, "only the shot Setup's draws")
            let from = SpriteSlot.Point(x: s0.x + off, y: s0.y + 0x16)
            XCTAssertEqual(Int(shot.classWord15c), dir(SpriteSlot.Point(x: 900, y: 508), from: from))
            XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeD, snd: 504, priority: 1, volume: 0xab, position: from)])
            XCTAssertEqual(try slot(w, id).phase, 0x1e)
            XCTAssertEqual(try slot(w, id).face, s0.face, "phase 0x1d leaves the face")
        }
        // The target is the player's centre + 8 down: a player y where the + 8 changes the 10° sector.
        let pyFound = try XCTUnwrap((300...700).first { py in
            let from = SpriteSlot.Point(x: 606, y: 322)
            return dir(SpriteSlot.Point(x: 640, y: py + 8), from: from) != dir(SpriteSlot.Point(x: 640, y: py), from: from)
                && dir(SpriteSlot.Point(x: 640, y: py + 8), from: from)
                != dir(SpriteSlot.Point(x: 640, y: py + 7), from: from)
        })
        let pw = try world(px: 640, py: Int16(pyFound))
        let (pid, _) = try floater(pw, x: 600, y: 300)
        pw.active.update(id: pid) { s in
            s.phase = 0x1d
            s.mirrored = false
            s.vx = 0
            s.vy = 0
        }
        frame(pw, pid)
        let pshot = try XCTUnwrap(pw.active.sprites.first { $0.handler == .enemyShot })
        XCTAssertEqual(Int(pshot.classWord15c), dir(SpriteSlot.Point(x: 640, y: pyFound + 8),
                                                     from: SpriteSlot.Point(x: 606, y: 322)), "P.y + 8")
        // Phases 28 and 30: no shot; hidden at phase 0x1d: the countdown, no shot.
        for (phase, hidden) in [(Int16(28), Int16(0)), (30, 0), (0x1d, 3)] {
            let w = try world()
            let (id, _) = try floater(w, p2: hidden)
            w.active.update(id: id) { $0.phase = phase }
            frame(w, id)
            XCTAssertEqual(w.active.sprites.filter { $0.handler == .enemyShot }.count, 0, "phase \(phase)")
            XCTAssertEqual(w.player.cues, [])
        }
        // Its own shot, reflected (or any of its type) and touching it while visible: −100, flash 10, 701, the shot
        // killed (`.HitFloaterSprite`'s EnemyShot arm).
        let w = try world()
        let (id, _) = try floater(w)
        w.active.update(id: id) { $0.face = FaceRef(pict: GremlinFloater.wraithSet, index: 1, set: .encoded) }
        let own = try other(w, over: id, type: 0x6f4, handler: .enemyShot)
        GremlinFloater.hitFloater(w, id: id, other: own)
        let s = try slot(w, id)
        XCTAssertEqual([Int(s.hp), Int(s.flash)], [400, 10])
        XCTAssertTrue(try slot(w, own).dead, "`.KillEnemyShot`")
        XCTAssertEqual(w.player.cues.first, PlayerCue(call: .threeD, snd: 701, priority: 1, volume: 0x100,
                                                      position: s.centre))
        let alien = try other(w, over: id, type: 0x712, handler: .enemyShot)
        GremlinFloater.hitFloater(w, id: id, other: alien)
        XCTAssertEqual([Int(try slot(w, id).hp)], [400], "another type: nothing")
        XCTAssertFalse(try slot(w, alien).dead)
        w.active.update(id: id) { $0.face = nil }
        let own2 = try other(w, over: id, type: 0x6f4, handler: .enemyShot)
        GremlinFloater.hitFloater(w, id: id, other: own2)
        XCTAssertEqual([Int(try slot(w, id).hp)], [400], "invisible: nothing")
        XCTAssertFalse(try slot(w, own2).dead)
        // Through the session's hit dispatch.
        w.active.update(id: id) { $0.face = FaceRef(pict: GremlinFloater.wraithSet, index: 1, set: .encoded) }
        let own3 = try other(w, over: id, type: 0x6f4, handler: .enemyShot)
        FerazelSession.hitCallback(w, id, own3)
        XCTAssertEqual(try slot(w, id).hp, 300)
    }

    func testFloaterHurtsOnlyAfterFrame12() throws {
        // `.HitPlayerSprite` step 6 (M l. 49514–49573): a Floater hurts only at `+0x46 > 12` — `.HurtPlayer(0x70, no
        // blood, 0x3c, R(100) < 0x51 ? 0 : 3)`; at ≤ 12 nothing (no draw). The phase is the Handle's own count.
        let L = try LevelFile.load(from: try resources(), level: 3)
        let w = SpriteWorld(level: L)
        let p = try XCTUnwrap(Player.spawn(world: w, x: 600, y: 300))
        w.playerID = p
        w.active.update(id: p) { $0.x = 600; $0.y = 300; $0.hp = 0x300 }
        let rec = Placement(index: 0, flag: 1, byte1: 0, type: 0x6f4, p1: 0, p2: 0, p3: 0, p4: 0, y: 280, x: 580)
        var fs = SpriteSlot(type: 0x6f4, x: 580, y: 280, recordIndex: 0)
        fs.oldPosition = SpriteSlot.Point(x: 580, y: 280)
        var none = EnemyCounting()
        GremlinFloater.setupFloater(&fs, record: rec, counting: &none)
        fs.phase = 11
        let id = w.active.insert(fs)
        let solver = TileSolver(world: w)
        GremlinFloater.handleFloater(world: w, id: id, solver: solver)
        XCTAssertEqual(try slot(w, id).phase, 12)
        let seed0 = w.rng.seed
        HitPlayerSprite.hit(w, player: p, other: id)
        XCTAssertEqual([Int(try slot(w, p).hp), Int(try slot(w, p).invulnerable)], [0x300, 0], "phase 12: nothing")
        XCTAssertEqual(w.rng.seed, seed0, "no draw")
        GremlinFloater.handleFloater(world: w, id: id, solver: solver)
        XCTAssertEqual(try slot(w, id).phase, 13)
        HitPlayerSprite.hit(w, player: p, other: id)
        XCTAssertEqual([Int(try slot(w, p).hp), Int(try slot(w, p).invulnerable)], [0x300 - 0x70, 0x3c], "phase 13")
        // `.HitFloaterSprite`, only while visible (`+0xc0 ≠ 0`): a player shot with `+0xa6 == 0` → `.KillPlayerShot`,
        // no HP damage; type 1 → `.TurnIntoStatue`; invisible or a cooling shot → nothing.
        let v = try world()
        let (vid, _) = try floater(v)
        v.active.update(id: vid) { $0.face = FaceRef(pict: GremlinFloater.wraithSet, index: 0, set: .encoded) }
        let shot = try other(v, over: vid, damage: 400)
        GremlinFloater.hitFloater(v, id: vid, other: shot)
        XCTAssertEqual([Int(try slot(v, vid).hp), Int(try slot(v, vid).flash), Int(try slot(v, vid).invulnerable)],
                       [500, 0, 0], "no HP damage")
        XCTAssertTrue(try slot(v, shot).dead, "the shot killed")
        let cool = try other(v, over: vid) { $0.counterA6 = 2 }
        GremlinFloater.hitFloater(v, id: vid, other: cool)
        XCTAssertFalse(try slot(v, cool).dead)
        v.active.update(id: vid) { $0.face = nil }
        let unseen = try other(v, over: vid)
        GremlinFloater.hitFloater(v, id: vid, other: unseen)
        XCTAssertFalse(try slot(v, unseen).dead, "invisible: no hit")
        let unseen1 = try other(v, over: vid, type: 1)
        GremlinFloater.hitFloater(v, id: vid, other: unseen1)
        XCTAssertEqual(try slot(v, vid).handler, .floater, "invisible: no statue")
        v.active.update(id: vid) { $0.face = FaceRef(pict: GremlinFloater.wraithSet, index: 0, set: .encoded) }
        let st = try other(v, over: vid, type: 1)
        GremlinFloater.hitFloater(v, id: vid, other: st)
        XCTAssertEqual(try slot(v, vid).handler, .statue)
        // A falling Box crushes it, visible or not: HP 0, `+0x150 = 0x16` — and it lives on.
        let c = try world()
        let (cid, _) = try floater(c)
        c.active.update(id: cid) { $0.vy = -0x400; $0.face = nil }
        let cs = try slot(c, cid)
        let bx = cs.x + cs.hotRect.left, by = cs.y + cs.hotRect.top - 30
        let crate = try XCTUnwrap(c.newSprite(type: 0xc12, x: bx, y: by, layer: 2, handler: .box) { b in
            b.x = bx
            b.y = by
            b.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x20, right: cs.hotRect.right - cs.hotRect.left)
            b.vy = 1
        })
        GremlinFloater.hitFloater(c, id: cid, other: crate)
        XCTAssertEqual([Int(try slot(c, cid).hp), Int(try slot(c, cid).classWord150)], [0, 0x16])
        XCTAssertFalse(try slot(c, cid).dead)
        // The Ring of Smiting seeds a Wraith (its Handle is one of the 15).
        let sm = try world()
        _ = try floater(sm)
        Smite.smiteEnemies(sm)
        XCTAssertEqual(sm.active.sprites.filter { $0.handler == .playerShot }.count, 1)
    }
}
