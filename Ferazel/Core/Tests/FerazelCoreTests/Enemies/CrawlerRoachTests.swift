import XCTest
@testable import FerazelCore

/// CR (docs/plans/2026-10-30-ferazel-phase5.md): the Crawler 1712 and the Roach 1720 — `.SetupCrawlerSprite` (M l.
/// 56153–56246), `.HandleCrawlerSprite` (M l. 56247–56519), `.HitCrawlerSprite` (M l. 56556–56682), `.KillCrawler` (M l.
/// 56683–56704), `.HitCrawlerTileSprite` (M l. 56706–56745); `.SetupRoachSprite` (M l. 64899–64957),
/// `.HandleRoachSprite` (M l. 64959–65116), `.HitRoachSprite` (M l. 65118–65199), `.KillRoach` (M l. 65201–65222);
/// the player shot's Crawler arm (M l. 51062–51064). A synthetic 40×16 grid over level 1's header: a floor of FG kind 3
/// along row 12 (its surface at y 400); every expected draw is re-derived from a copy of the stream at the call site.
final class CrawlerRoachTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// The grid (floor row 12, kind 3; BG liquid of kind 200 + `liquid` from row `waterRow` down when given) and the
    /// player's centre globals `*_DAT_1009fd94` / `fd90` at (`px`, `py`).
    private func world(px: Int16 = 900, py: Int16 = 340, waterRow: Int? = nil, liquid: Int = 0,
                       floor: Bool = true) throws -> SpriteWorld {
        let w = SpriteWorld(level: try LevelFile.load(from: try resources(), level: 1))
        var fg = [UInt16](repeating: 0, count: 40 * 16), bg = fg
        if floor { for c in 0..<40 { fg[12 * 40 + c] = 4 } }            // tile 3 → kind 3
        if let r = waterRow { for row in r..<16 { for c in 0..<40 { bg[row * 40 + c] = 1 } } }
        var bgKinds = [Int](repeating: 0, count: 0x60)
        bgKinds[0] = 200 + liquid
        w.tiles = TileGrid(fg: TileMap(width: 40, height: 16, cells: fg), bg: TileMap(width: 40, height: 16, cells: bg),
                           fgKinds: Array(0..<0x60), bgKinds: bgKinds)
        w.player.centreX = px
        w.player.centreY = py
        return w
    }

    /// A sprite of `type` placed (record 0) at (`x`, `y`) and set up by its class Setup inside the counting window
    /// (outside it when `counted` is false). y 367 stands a Crawler (hot-rect bottom 0x21) on the floor, y 355 a Roach
    /// (0x2d).
    private func enemy(_ w: SpriteWorld, type: Int16, x: Int = 200, y: Int, p1: Int16 = 0, p2: Int16 = 0,
                       p3: Int16 = 0, counted: Bool = true) throws -> (id: Int, entry: SetupFaces.Entry) {
        let p = Placement(index: 0, flag: 1, byte1: 0, type: type, p1: p1, p2: p2, p3: p3, p4: 0, y: Int16(y),
                          x: Int16(x))
        w.records = [p]
        let c = SetupFaces.Context(level: w.level, playerX: Int(w.player.centreX), records: w.records)
        var lights = LightTable()
        w.enemies.window = counted
        let e = try SetupFaces.setup(p, context: c, lights: &lights, counting: &w.enemies, rng: &w.rng)
        w.enemies.window = false
        w.records = [e.record]
        return (w.active.insert(e.slot), e)
    }

    private func crawler(_ w: SpriteWorld, x: Int = 200, y: Int = 367, p1: Int16 = 1, p2: Int16 = 0,
                         counted: Bool = true) throws -> Int {
        try enemy(w, type: CrawlerRoach.crawler, x: x, y: y, p1: p1, p2: p2, counted: counted).id
    }

    private func roach(_ w: SpriteWorld, x: Int = 200, y: Int = 355, p3: Int16 = 0, counted: Bool = true) throws -> Int {
        try enemy(w, type: CrawlerRoach.roach, x: x, y: y, p3: p3, counted: counted).id
    }

    private func slot(_ w: SpriteWorld, _ id: Int) throws -> SpriteSlot { try XCTUnwrap(w.active.record(id: id)) }

    /// One class Handle call (the session's dispatch by `+0x4c`).
    private func frame(_ w: SpriteWorld, _ id: Int, _ solver: TileSolver) {
        var lights = LightTable()
        if w.active.record(id: id)?.handler == .roach {
            CrawlerRoach.handleRoach(world: w, id: id, solver: solver, lights: &lights, effects: 1)
        } else {
            CrawlerRoach.handleCrawler(world: w, id: id, solver: solver, lights: &lights, effects: 1)
        }
    }

    private func f(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }

    /// A player shot of `type` at (230, 382), its 20×20 hot rect overlapping a Crawler's or a Roach's at (200, 367) /
    /// (200, 355) (the blood spray starts in the overlap).
    private func shot(_ w: SpriteWorld, type: Int16 = 2, damage: Int16 = 150, vx: Int32 = 1000,
                      a6: Int16 = 0) throws -> Int {
        try XCTUnwrap(w.newSprite(type: type, x: 230, y: 382, layer: 0xb, handler: .playerShot) { s in
            s.x = 230
            s.y = 382
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 20, right: 20)
            s.hp = damage
            s.vx = vx
            s.counterA6 = a6
        })
    }

    // MARK: - the Crawler

    func testCrawlerJumpCycle() throws {
        // The floor crawler (p1 1, state 2): one frame lands it; the player 30 px right of its centre, level.
        let w = try world()
        let solver = TileSolver(world: w)
        let id = try crawler(w)
        frame(w, id, solver)
        var s = try slot(w, id)
        XCTAssertNotEqual(s.groundKind, 0, "landed")
        XCTAssertEqual([s.x, s.y, s.centre.x, s.centre.y], [200, 367, 232, 389])
        XCTAssertEqual(s.face, f(CrawlerRoach.walkSet, 0), "0x6ae[`+0x46 >> 1`] at `+0x46` 1")
        w.player.centreX = Int16(s.centre.x + 30)
        w.player.centreY = Int16(s.centre.y)
        w.active.update(id: id) { $0.counterA6 = 0 }
        // `+0xa6 == 0`, `+0xb2 == −1`, |dx| 30 < 70, |dy| 0 < 100 → `+0xb2 = 5`; facing: c.x < P.x → flip 1. No draw.
        var r = w.rng
        frame(w, id, solver)
        s = try slot(w, id)
        XCTAssertEqual([Int(s.subState), Int(s.counterA6), Int(s.subtype)], [5, 0, 2])
        XCTAssertTrue(s.mirrored)
        XCTAssertEqual(w.rng.seed, r.seed)
        // The wind-up: faces 0x6af[1, 2, 3, 4, 4] while `+0xb2` counts 5 → 1; vx is held at 0 around the integration
        // and restored as an i16 (0x12345 → 0x2345); the position does not move.
        for (b2, cell) in [(5, 1), (4, 2), (3, 3), (2, 4)] {
            w.active.update(id: id) { $0.vx = 0x12345 }
            let x0 = try slot(w, id).x256
            frame(w, id, solver)
            s = try slot(w, id)
            XCTAssertEqual(s.face, f(CrawlerRoach.jumpSet, cell), "b2 \(b2)")
            XCTAssertEqual([Int(s.subState), Int(s.vx), Int(s.x256 - x0)], [b2 - 1, 0x2345, 0], "b2 \(b2)")
        }
        // `+0xb2` 1 → 0: the leap — snd 700, `.SetSpriteSpeed(0, −2000 − R(1000))`, `.AccelerateBasedOnSlope(−R(500) −
        // 0x4b0, 0x960)`, `+0xa6 = 10 + R(10)`, `+0x14c` = vx, both negated (c.x < P.x), `+0xb2 = −1`; then gravity.
        w.active.update(id: id) { $0.vx = 0 }
        w.player.cues = []
        r = w.rng
        let r1 = Int32(r.next(1000)), r2 = Int32(r.next(500)), r3 = r.next(10)
        let x0 = try slot(w, id).x256
        frame(w, id, solver)
        s = try slot(w, id)
        XCTAssertEqual(w.rng.seed, r.seed, "three draws")
        XCTAssertEqual(s.face, f(CrawlerRoach.jumpSet, 4))
        XCTAssertEqual([Int(s.subState), Int(s.counterA6)], [-1, 9 + Int(r3)], "re-armed, then counted (still on ground)")
        XCTAssertEqual([s.classTimer, s.vx, s.x256 - x0], [r2 + 0x4b0, r2 + 0x4b0, r2 + 0x4b0])
        XCTAssertEqual(s.vy, -2000 - r1 + 0x151)
        XCTAssertEqual(w.player.cues.map(\.snd), [700])
        XCTAssertEqual(w.player.cues.first?.volume, 0x100)
        // Airborne: no ground block (`+0xa6` holds), the walk face holds; landing resumes the count-down.
        let a6 = try slot(w, id).counterA6
        frame(w, id, solver)
        XCTAssertEqual(try slot(w, id).counterA6, a6)
        XCTAssertEqual(try slot(w, id).groundKind, 0)
        // The player on the left: the leap goes left (vx and `+0x14c` stay negative); the cap is 2·`+0x158` (tier 3:
        // 2000 → 4000 holds −R(500) − 2000).
        let wl = try world()
        let sl = TileSolver(world: wl)
        let il = try crawler(wl, p2: 3)
        frame(wl, il, sl)
        wl.player.centreX = Int16(try slot(wl, il).centre.x - 30)
        wl.player.centreY = Int16(try slot(wl, il).centre.y)
        wl.active.update(id: il) { $0.subState = 1; $0.vx = 0 }
        var rl = wl.rng
        _ = rl.next(1000)
        let l2 = Int32(rl.next(500))
        frame(wl, il, sl)
        let tl = try slot(wl, il)
        XCTAssertEqual([tl.classTimer, tl.vx], [-l2 - 2000, -l2 - 2000])
        XCTAssertFalse(tl.mirrored)
        // The player level with the centre (c.x == P.x): the leap is not negated (vx stays −R(500) − cap) and the
        // facing holds either way.
        for flip in [false, true] {
            let we = try world()
            let se = TileSolver(world: we)
            let ie = try crawler(we)
            frame(we, ie, se)
            we.player.centreX = Int16(try slot(we, ie).centre.x)
            we.player.centreY = Int16(try slot(we, ie).centre.y)
            we.active.update(id: ie) { $0.subState = 1; $0.vx = 0; $0.mirrored = flip }
            var re = we.rng
            _ = re.next(1000)
            let e2 = Int32(re.next(500))
            frame(we, ie, se)
            let te = try slot(we, ie)
            XCTAssertEqual([te.classTimer, te.vx], [-e2 - 0x4b0, -e2 - 0x4b0], "flip \(flip)")
            XCTAssertEqual(te.mirrored, flip)
        }
        // On ground with the player beyond ±60 of the centre: `.AccelerateBasedOnSlope(±250, cap)`; within: none; the
        // cooldown counts down only on ground; out of range (|dx| ≥ 70 or |dy| ≥ 100) no wind-up.
        for (dx, dy, dvx, armed) in [(61, 0, 250, true), (-61, 0, -250, true), (60, 0, 0, true), (-60, 0, 0, true),
                                     (69, 0, 250, true), (70, 0, 250, false), (0, 99, 0, true), (0, -99, 0, true),
                                     (0, 100, 0, false), (0, -100, 0, false)] {
            let wg = try world()
            let sg = TileSolver(world: wg)
            let ig = try crawler(wg)
            frame(wg, ig, sg)
            let g = try slot(wg, ig)
            wg.player.centreX = Int16(g.centre.x + dx)
            wg.player.centreY = Int16(g.centre.y + dy)
            wg.active.update(id: ig) { $0.counterA6 = 1; $0.vx = 0 }
            frame(wg, ig, sg)
            let h = try slot(wg, ig)
            XCTAssertEqual([Int(h.vx), Int(h.counterA6), Int(h.subState)], [dvx, 0, armed ? 5 : -1], "dx \(dx) dy \(dy)")
        }
        // The cap: vx 1100 + 250 → 1200 (tier 0's 0x4b0).
        let wc = try world()
        let sc = TileSolver(world: wc)
        let ic = try crawler(wc)
        frame(wc, ic, sc)
        wc.player.centreX = Int16(try slot(wc, ic).centre.x + 200)
        wc.active.update(id: ic) { $0.vx = 1100 }
        frame(wc, ic, sc)
        XCTAssertEqual(try slot(wc, ic).vx, 0x4b0)
        // HP ≤ `+0x15c` (300) with `+0xb2 == −1` → state 3 (the flee); winding up it waits; above it stays.
        for (hp, b2, state) in [(Int16(300), Int16(-1), Int16(3)), (301, -1, 2), (300, 3, 2)] {
            let wf = try world()
            let sf = TileSolver(world: wf)
            let i = try crawler(wf)
            frame(wf, i, sf)
            wf.active.update(id: i) { $0.hp = hp; $0.subState = b2; $0.counterA6 = 9 }
            frame(wf, i, sf)
            XCTAssertEqual(try slot(wf, i).subtype, state, "hp \(hp) b2 \(b2)")
        }
        // The flee (state 3) on ground with `+0xa6 == 0`: the hop — `.SetSpriteSpeed(0, −900 − R(400))`,
        // `.AccelerateBasedOnSlope(−0x6a4 − R(800), 2000)`, `+0x14c` = vx, negated with vx away from a player on the
        // left, `+0xa6 = 20 + R(30)`; then (still on ground this frame) vx halved while moving away from P (vx < 0 with
        // P right, vx > 300 with P left), else `+0xa6` − 1; airborne vx = `+0x14c`.
        for left in [false, true] {
            let wh = try world()
            let sh = TileSolver(world: wh)
            let ih = try crawler(wh)
            frame(wh, ih, sh)
            let c = try slot(wh, ih).centre
            wh.player.centreX = Int16(c.x + (left ? -100 : 100))
            wh.active.update(id: ih) { $0.subtype = 3; $0.counterA6 = 0; $0.hp = 200; $0.vx = 0 }
            var rh = wh.rng
            let h1 = Int32(rh.next(400)), h2 = Int32(rh.next(800)), h3 = rh.next(0x1e)
            frame(wh, ih, sh)
            let t = try slot(wh, ih)
            let v = -0x6a4 - h2
            XCTAssertEqual(wh.rng.seed, rh.seed)
            XCTAssertEqual([t.classTimer, t.vx, t.vy], [left ? -v : v, (left ? -v : v) / 2, -900 - h1 + 0x151],
                           "left \(left)")
            XCTAssertEqual([Int(t.counterA6), Int(t.subtype)], [Int(h3) + 0x14, 3])
            wh.active.update(id: ih) { $0.vx = 5 }
            frame(wh, ih, sh)
            XCTAssertEqual(try slot(wh, ih).vx, t.classTimer, "airborne: vx = `+0x14c`")
        }
        // The hop's cap 2000: a stream whose R(800) passes 300 (|−0x6a4 − R| > 2000 → −2000); the player level with
        // the centre: not negated.
        do {
            var sd: Int32 = 1
            while true {
                var q = FastRand(seed: sd)
                _ = q.next(400)
                if 300 < q.next(800) { break }
                sd += 1
            }
            let wh = try world()
            let sh = TileSolver(world: wh)
            let ih = try crawler(wh)
            frame(wh, ih, sh)
            wh.player.centreX = Int16(try slot(wh, ih).centre.x)
            wh.active.update(id: ih) { $0.subtype = 3; $0.counterA6 = 0; $0.hp = 200; $0.vx = 0 }
            wh.rng = FastRand(seed: sd)
            frame(wh, ih, sh)
            XCTAssertEqual([try slot(wh, ih).classTimer], [-2000], "seed \(sd)")
        }
        for (left, vx, out, a6) in [(false, Int32(-301), Int32(-150), Int16(4)), (false, 400, 400, 3),
                                    (true, 301, 150, 4), (true, 300, 300, 3), (true, -400, -400, 3)] {
            let wh = try world()
            let sh = TileSolver(world: wh)
            let ih = try crawler(wh)
            frame(wh, ih, sh)
            let c = try slot(wh, ih).centre
            wh.player.centreX = Int16(c.x + (left ? -100 : 100))
            wh.active.update(id: ih) { $0.subtype = 3; $0.counterA6 = 4; $0.hp = 200; $0.vx = vx }
            let x0 = try slot(wh, ih).x256
            frame(wh, ih, sh)
            let t = try slot(wh, ih)
            XCTAssertEqual([t.vx, t.x256 - x0, Int32(t.counterA6)], [out, out, Int32(a6)], "left \(left) vx \(vx)")
        }
        // The flee's `+0xa6` count-down has no floor; HP ≥ 300 on ground leaves state 3 alone (no way back).
        let wn = try world()
        let sn = TileSolver(world: wn)
        let iN = try crawler(wn)
        frame(wn, iN, sn)
        wn.player.centreX = Int16(try slot(wn, iN).centre.x + 100)
        wn.active.update(id: iN) { $0.subtype = 3; $0.counterA6 = -1; $0.hp = 500; $0.vx = 0 }
        frame(wn, iN, sn)
        XCTAssertEqual([Int(try slot(wn, iN).counterA6), Int(try slot(wn, iN).subtype)], [-2, 3])
        // The ceiling crawler (p1 0, state 0): gravity −0x151, face 0x6b0, `+0x46` back to 0; vx halved (toward zero);
        // it drops (state 1) when the player is within 140 across and below by at most 219, or HP ≤ max − 100.
        for (dx, dy, hp, drops) in [(0, 219, Int16(500), true), (139, 1, 500, true), (-139, 1, 500, true),
                                    (140, 1, 500, false), (0, 220, 500, false), (0, 0, 500, false), (0, -1, 500, false),
                                    (500, 0, 400, true), (500, 0, 401, false)] {
            let wz = try world(floor: false)
            let sz = TileSolver(world: wz)
            let iz = try crawler(wz, y: 100, p1: 0)
            XCTAssertEqual([Int(try slot(wz, iz).subtype), Int(try slot(wz, iz).gravity)], [0, -0x151])
            wz.standardSpriteCleanup(iz, faceWidth: { _ in 0x40 })     // the centre from the hot rect
            let c = try slot(wz, iz).centre
            wz.player.centreX = Int16(c.x + dx)
            wz.player.centreY = Int16(c.y + dy)
            wz.active.update(id: iz) { $0.hp = hp; $0.vx = -7 }
            frame(wz, iz, sz)
            let z = try slot(wz, iz)
            XCTAssertEqual([Int(z.subtype), Int(z.vx), Int(z.phase)], [drops ? 1 : 0, -3, drops ? 1 : 0],
                           "dx \(dx) dy \(dy) hp \(hp)")
            XCTAssertEqual(z.face, drops ? f(CrawlerRoach.walkSet, 0) : f(CrawlerRoach.ceilingFace, 0))
            XCTAssertEqual(z.gravity, -0x151)
            XCTAssertEqual(z.vy, -0x151, "held against the ceiling")
            XCTAssertEqual(wz.records[0].p1, 0)
        }
        // Falling (state 1): record p1 := 1 in the live record (a reload makes a floor crawler), gravity 0x151, the face
        // left as it was; on ground → state 2.
        let wd = try world()
        let sd = TileSolver(world: wd)
        let iD = try crawler(wd, y: 300, p1: 0)
        wd.player.centreX = 100
        wd.player.centreY = 1000
        wd.active.update(id: iD) { $0.subtype = 1; $0.face = self.f(CrawlerRoach.jumpSet, 5) }
        frame(wd, iD, sd)
        XCTAssertEqual(wd.records[0].p1, 1)
        XCTAssertEqual([Int(try slot(wd, iD).gravity), Int(try slot(wd, iD).subtype)], [0x151, 1])
        XCTAssertEqual(try slot(wd, iD).face, f(CrawlerRoach.jumpSet, 5))
        var n = 0
        while try slot(wd, iD).subtype == 1 && n < 60 { frame(wd, iD, sd); n += 1 }
        XCTAssertEqual(try slot(wd, iD).subtype, 2)
        XCTAssertEqual(try slot(wd, iD).y, 367)
        // A face of 0x6af[5] while airborne is kept (the walk counter waits); on ground it walks on.
        wd.active.update(id: iD) { $0.face = self.f(CrawlerRoach.jumpSet, 5); $0.groundKind = 0; $0.phase = 4 }
        frame(wd, iD, sd)
        XCTAssertEqual([try slot(wd, iD).face, nil], [f(CrawlerRoach.jumpSet, 5), nil])
        XCTAssertEqual(try slot(wd, iD).phase, 4)
        frame(wd, iD, sd)
        XCTAssertEqual(try slot(wd, iD).face, f(CrawlerRoach.walkSet, 2))
        // The walk counter wraps past 11 (face 0x6ae[0…5]); `+0xe9` or `+0x1b2` → no Handle at all.
        wd.active.update(id: iD) { $0.phase = 0xa }
        frame(wd, iD, sd)
        XCTAssertEqual(try slot(wd, iD).face, f(CrawlerRoach.walkSet, 5))
        XCTAssertEqual([Int(try slot(wd, iD).phase)], [0xb])
        frame(wd, iD, sd)
        XCTAssertEqual([Int(try slot(wd, iD).phase)], [0])
        for skip in [true, false] {
            wd.active.update(id: iD) { $0.phase = 3; if skip { $0.handleSkip = true } else { $0.dead = true } }
            frame(wd, iD, sd)
            XCTAssertEqual(try slot(wd, iD).phase, 3)
            wd.active.update(id: iD) { $0.handleSkip = false; $0.dead = false }
        }
        // States past 4 (none written): no gravity store; state 4's is 0x151.
        wd.active.update(id: iD) { $0.subtype = 5; $0.gravity = 7 }
        frame(wd, iD, sd)
        XCTAssertEqual(try slot(wd, iD).gravity, 7)
    }

    func testCrawlerCooldownStartsAt3() throws {
        // `.SetupCrawlerSprite` (M l. 56153–56246): layer 0xb, the Handle / hit / tile callbacks, `+0xa6 = 3`, `+0xb2 =
        // −1`, `+0x15c = 300`, rect (0x14, 0xc, 0x2c, 0x21), `+0x150 = −1`; p1 0 → state 0, gravity −0x151, ≠ 0 → state 2,
        // 0x151; the tier by p2; no draw; counted in the window; no save write-back flag and no idle margins.
        let w = try world()
        var r = w.rng
        let (id, e) = try enemy(w, type: CrawlerRoach.crawler, y: 367, p1: 1, p2: 1)
        let a = try slot(w, id)
        XCTAssertEqual(w.rng.seed, r.seed, "no draw")
        XCTAssertEqual(a.handler, .crawler)
        XCTAssertEqual([Int(a.layer), Int(a.counterA6), Int(a.subState), Int(a.subtype), Int(a.gravity)],
                       [0xb, 3, -1, 2, 0x151])
        XCTAssertEqual([a.hasHit, a.hasTileHit, a.countedInTotals, a.mirrored], [true, true, true, false])
        XCTAssertEqual([a.keepRecord, a.noWriteBack189, a.noWriteBack18a, a.keepRecordAtKill, a.killedForGood, a.dead],
                       [false, false, false, false, false, false])
        XCTAssertEqual(a.margins, SpriteSlot(type: 0x6b0, x: 0, y: 0).margins)
        XCTAssertEqual(a.hotRect, IdleSprites.Rect(top: 0xc, left: 0x14, bottom: 0x21, right: 0x2c))
        XCTAssertEqual([a.classWord150, a.classWord154, a.classWord158, a.classWord15c], [-1, 300, 0x352, 100])
        XCTAssertEqual([Int(a.hp), Int(a.mode)], [300, 0x10002])
        XCTAssertEqual([a.x, a.y, a.oldPosition.x, a.oldPosition.y, Int(a.x256), Int(a.y256)],
                       [200, 367, 200, 367, 200 << 8, 367 << 8])
        XCTAssertEqual([Int(a.particleOffsetX), Int(a.particleOffsetY)], [0, 0])
        XCTAssertEqual(w.enemies.live, 1)
        XCTAssertNil(a.face, "p1 ≠ 0: the absent 0x5dd")
        XCTAssertEqual(e.source, .none)
        XCTAssertEqual(e.record, w.records[0])
        // p1 0: the ceiling; the Phase-1 stand-in face 0x6b0 (the Handle's).
        let (cid, ce) = try enemy(w, type: CrawlerRoach.crawler, y: 100, p1: 0)
        XCTAssertEqual([Int(try slot(w, cid).subtype), Int(try slot(w, cid).gravity)], [0, -0x151])
        XCTAssertEqual([ce.source == .handle, ce.sheet?.pict == 0x6b0], [true, true])
        // The tiers (enemies-ground §4): p2 → (HP = `+0x154`, `+0x158`, `+0x15c`, `+0xb8`); outside 0…3 nothing stored.
        for (p2, hp, cap, flee, mode) in [(Int16(0), 500, 0x4b0, 300, 0), (1, 300, 0x352, 100, 0x10002),
                                          (2, 1000, 0x60e, 300, 0x10003), (3, 0x640, 2000, 200, 0x1000f),
                                          (4, 0, 0, 300, 0), (-1, 0, 0, 300, 0)] as [(Int16, Int, Int, Int, Int)] {
            let t = try slot(w, try crawler(w, p2: p2))
            XCTAssertEqual([Int(t.hp), Int(t.classWord154), Int(t.classWord158), Int(t.classWord15c), Int(t.mode)],
                           [hp, hp, cap, flee, mode], "p2 \(p2)")
        }
        // Outside the window: not counted.
        let live = w.enemies.live
        XCTAssertFalse(try slot(w, try crawler(w, counted: false)).countedInTotals)
        XCTAssertEqual(w.enemies.live, live)
        // The cooldown (enemies-ground-2 §2): the initial 3 is consumed by state-2 grounded frames — with the player in
        // range from the start, the wind-up arms only on the third grounded frame (the first frame lands it).
        let wc = try world()
        let solver = TileSolver(world: wc)
        let ic = try crawler(wc)
        wc.player.centreX = 262
        wc.player.centreY = 389
        var seen: [[Int]] = []
        for _ in 0..<4 {
            frame(wc, ic, solver)
            let t = try slot(wc, ic)
            seen.append([Int(t.counterA6), Int(t.subState)])
        }
        XCTAssertEqual(seen, [[3, -1], [2, -1], [1, -1], [0, 5]])
        // The wind-up's five frames draw nothing; the leap re-arms `+0xa6 = 10 + R(10)` (counted once that frame) — the
        // next gate: no wind-up until it is back at 0.
        r = wc.rng
        _ = r.next(1000)
        _ = r.next(500)
        let r3 = r.next(10)
        XCTAssertEqual(try slot(wc, ic).centre.x, 232)
        for _ in 0..<5 { frame(wc, ic, solver) }
        XCTAssertEqual([Int(try slot(wc, ic).counterA6), Int(try slot(wc, ic).subState)], [Int(r3) + 9, -1])
        XCTAssertEqual(wc.rng.seed, r.seed)
    }

    func testCrawlerKilledByShotArm() throws {
        // `.HitPlayerShotSprite`'s Crawler arm (M l. 51062–51064): any player shot against a Crawler Handle →
        // `.KillPlayerShot(s, 0, 0)` — no sound, no effect, whatever the shot's `+0xa6`; an idled crawler (`+0x4c` 0) or a
        // Roach: nothing.
        for (handler, cleared, a6, dies) in [(SpriteHandler.crawler, false, Int16(0), true), (.crawler, false, 5, true),
                                             (.crawler, true, 0, false), (.roach, false, 0, false)] {
            let w = try world()
            let cid = try crawler(w)
            w.active.update(id: cid) { $0.handler = handler; $0.handleCleared = cleared }
            let sid = try shot(w, a6: a6)
            w.player.cues = []
            var lights = LightTable()
            PlayerShotHits.hit(w, shot: sid, other: cid, effects: 1, lights: &lights)
            XCTAssertEqual(try slot(w, sid).dead, dies, "\(handler) cleared \(cleared) a6 \(a6)")
            XCTAssertEqual(w.player.cues.count, 0)
            XCTAssertEqual(w.active.sprites.count, 2, "no effect sprite")
            XCTAssertEqual(try slot(w, cid).hp, 500)
        }
        // `.HitCrawlerSprite`: a player shot with `+0xa6 == 0` → `.KillPlayerShot(o, 0, 0)` first (no sound, no effect;
        // its stale r29 is the shot: id 2 recolours the shot's own light to 0x21), then `.HurtSprite(s, 150, (int)(0.65 ·
        // 1000), −1000, 4, 10)`, 40 blood particles, HP ≥ 0xc9 → snd 701 vol 0x100.
        let w = try world()
        let cid = try crawler(w)
        let sid = try shot(w, damage: 150, vx: 1000)
        var lights = LightTable()
        let light = lights.add(face: nil, x: 0, y: 0, vx: 0, vy: 0, accelY: 0, colour: 5)
        w.active.update(id: sid) { $0.light = light }
        w.player.cues = []
        CrawlerRoach.hitCrawler(w, id: cid, other: sid, lights: &lights)
        var c = try slot(w, cid)
        XCTAssertEqual([Int(c.hp), Int(c.vx), Int(c.vy), Int(c.invulnerable), Int(c.flash)], [350, 650, -1000, 4, 10])
        XCTAssertTrue(try slot(w, sid).dead)
        XCTAssertEqual(lights.slots[Int(light)].colour, 0x21)
        XCTAssertEqual(w.particles.records.filter(\.alive).count, 40)
        XCTAssertEqual(w.player.cues.map { [Int($0.snd), Int($0.volume)] }, [[701, 0x100]])
        // The knockback is `fctiwz(0.65 · vx)` as an i16: −999 → −649; 0x10000 → 0xa666 → −0x599a.
        for (vx, kvx) in [(Int32(-999), -649), (0x10000, Int(Int16(truncatingIfNeeded: 0xa666)))] {
            let wk = try world()
            let k = try crawler(wk)
            var lk = LightTable()
            CrawlerRoach.hitCrawler(wk, id: k, other: try shot(wk, vx: vx), lights: &lk)
            XCTAssertEqual(Int(try slot(wk, k).vx), kvx, "vx \(vx)")
        }
        // Invulnerable (`+0x116 ≠ 0`): no hurt, no blood, no sound — the shot is still killed.
        w.player.cues = []
        let s2 = try shot(w)
        CrawlerRoach.hitCrawler(w, id: cid, other: s2, lights: &lights)
        XCTAssertEqual(try slot(w, cid).hp, 350)
        XCTAssertTrue(try slot(w, s2).dead)
        XCTAssertEqual(w.player.cues.count, 0)
        XCTAssertEqual(w.particles.records.filter(\.alive).count, 40)
        // HP below 0xc9 after the hit → snd 702 'uh oh', also on the killing hit; 201 left → 701.
        for (hp, dmg, snd) in [(Int16(350), Int16(149), Int16(701)), (350, 150, 702), (100, 150, 702)] {
            let wu = try world()
            let u = try crawler(wu)
            wu.active.update(id: u) { $0.hp = hp }
            wu.player.cues = []
            var lu = LightTable()
            CrawlerRoach.hitCrawler(wu, id: u, other: try shot(wu, damage: dmg), lights: &lu)
            XCTAssertEqual(wu.player.cues.map(\.snd), [snd], "hp \(hp) dmg \(dmg)")
        }
        // A player shot with `+0xa6 ≠ 0` (a stab's second visit, −6; or 2): nothing here.
        let s6 = try shot(w, a6: -6)
        w.active.update(id: cid) { $0.invulnerable = 0 }
        CrawlerRoach.hitCrawler(w, id: cid, other: s6, lights: &lights)
        XCTAssertEqual(try slot(w, cid).hp, 350)
        XCTAssertFalse(try slot(w, s6).dead)
        let s3 = try shot(w, a6: 2)
        w.active.update(id: cid) { $0.invulnerable = 0 }
        CrawlerRoach.hitCrawler(w, id: cid, other: s3, lights: &lights)
        XCTAssertEqual(try slot(w, cid).hp, 350)
        XCTAssertFalse(try slot(w, s3).dead)
        // An enemy shot: nothing (no reaction to enemy shots, enemies-ground §4).
        let es = try XCTUnwrap(w.newSprite(type: 0, x: 250, y: 330, layer: 0xb, handler: .enemyShot) { $0.hp = 100 })
        CrawlerRoach.hitCrawler(w, id: cid, other: es, lights: &lights)
        XCTAssertEqual(try slot(w, cid).hp, 350)
        // The Statue arm: a shot of type 1 → killed, then `.TurnIntoStatue(s)` (snd 302 vol 0x32, the Statue Handle,
        // the Crawler's saved) — no damage.
        w.player.cues = []
        let st = try shot(w, type: 1)
        CrawlerRoach.hitCrawler(w, id: cid, other: st, lights: &lights)
        c = try slot(w, cid)
        XCTAssertEqual(c.handler, .statue)
        XCTAssertEqual(c.savedHandler, .crawler)
        XCTAssertEqual(c.hp, 350)
        XCTAssertTrue(try slot(w, st).dead)
        XCTAssertEqual(w.player.cues.map { [Int($0.snd), Int($0.volume)] }, [[302, 0x32]])
        // The session's hit dispatch reaches `.HitCrawlerSprite` / `.HitRoachSprite` by `+0x4c`.
        let wd = try world()
        let d = try crawler(wd)
        FerazelSession.hitCallback(wd, d, try shot(wd))
        XCTAssertEqual(try slot(wd, d).hp, 350)
        let rd = try roach(wd)
        FerazelSession.hitCallback(wd, rd, try shot(wd, damage: 50))
        XCTAssertEqual(try slot(wd, rd).hp, 150)
        // The Handle row (`forClass`) and the session's Handle dispatch: a level-1 session runs Crawlers and Roaches.
        XCTAssertEqual([SpriteHandler.forClass(type: 0x6b0), SpriteHandler.forClass(type: 0x6b8)], [.crawler, .roach])
    }

    // MARK: - the Roach

    func testRoachSetupFields() throws {
        // `.SetupRoachSprite` (M l. 64899–64957): layer 0xb, the Roach Handle / hit / tile callbacks, `+0xa6 = 3`, state
        // 2, gravity 0x151, face 0x6b8[0] (the cache), HP 200, rect (0x23, 0x1b, 0x44, 0x2d), `+0x150 = −1`, p3 0 → 0xaa
        // written back, `+0x154` = x (the spawn's left edge), vx 0x4b0 (M l. 64945–64946); no draw, no flag, no margins.
        let w = try world()
        let r = w.rng
        let (id, e) = try enemy(w, type: CrawlerRoach.roach, x: 321, y: 355, p3: 0)
        let a = try slot(w, id)
        XCTAssertEqual(w.rng.seed, r.seed, "no draw")
        XCTAssertEqual(a.handler, .roach)
        XCTAssertEqual([Int(a.layer), Int(a.counterA6), Int(a.subtype), Int(a.gravity), Int(a.hp)], [0xb, 3, 2, 0x151, 200])
        XCTAssertEqual([a.classWord154, a.vx, a.classWord150], [321, 0x4b0, -1])
        XCTAssertEqual(a.hotRect, IdleSprites.Rect(top: 0x1b, left: 0x23, bottom: 0x2d, right: 0x44))
        XCTAssertEqual(a.face, f(0x6b8, 0))
        XCTAssertEqual(e.source, .setupCached)
        XCTAssertEqual([a.hasHit, a.hasTileHit, a.countedInTotals, a.mirrored], [true, true, true, false])
        XCTAssertEqual([a.keepRecord, a.noWriteBack189, a.noWriteBack18a, a.keepRecordAtKill, a.killedForGood, a.dead],
                       [false, false, false, false, false, false])
        XCTAssertEqual(a.margins, SpriteSlot(type: 0x6b8, x: 0, y: 0).margins)
        XCTAssertEqual([Int(a.mode), Int(a.subState), Int(a.classWord158), Int(a.classWord15c)], [0, 0, 0, 0])
        XCTAssertEqual([a.x, a.y, a.oldPosition.x, a.oldPosition.y, Int(a.x256), Int(a.y256)],
                       [321, 355, 321, 355, 321 << 8, 355 << 8])
        XCTAssertEqual(e.record.p3, 0xaa)
        XCTAssertEqual([e.record.p1, e.record.p2, e.record.p4, e.record.x, e.record.y, e.record.type], [0, 0, 0, 321, 355, 0x6b8])
        XCTAssertEqual(w.enemies.live, 1)
        // p3 ≠ 0 is kept; a negative x keeps its sign in `+0x154`.
        XCTAssertEqual(try enemy(w, type: CrawlerRoach.roach, x: 100, y: 355, p3: 7).entry.record.p3, 7)
        XCTAssertEqual(try slot(w, try roach(w, x: -40)).classWord154, -40)
        XCTAssertFalse(try slot(w, try roach(w, counted: false)).countedInTotals)
        // A level-1 session: the five Roaches set up so (records 15, 19, 27, 30, 163: p3 0 → 170 in the live records).
        let s = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 1, seed: 1)
        let roaches = s.world.active.sprites.filter { $0.type == 0x6b8 } + s.world.idle.entries.compactMap { e in
            e.flatMap { $0.saved.type == 0x6b8 && $0.activeID == nil ? $0.saved : nil }
        }
        XCTAssertEqual(roaches.count, 5)
        for q in roaches {
            XCTAssertEqual([q.classWord154, q.vx], [Int32(s.world.records[Int(q.recordIndex)].x), 0x4b0])
            XCTAssertEqual(s.world.records[Int(q.recordIndex)].p3, 170)
        }
    }

    func testRoachPatrol() throws {
        // The patrol (state 2, on ground; M l. 65026–65053): w = p3 / 2 (0xaa → 85) about home `+0x154` (the spawn x):
        // c.x < home − w → +100 (cap 0x4b0), flip 1; c.x > home + w → −100, flip 0; inside: flip 0 with vx > −0x4b0 →
        // −100, flip 1 with vx > 0x4b0 → +100 — rightward travel coasts. Each frame checked against that rule on the
        // frame's own c.x and vx; the face 0x6b8[`+0x46 >> 1`]; `+0xa6` counts 3 → 0 and is read by nothing.
        let w = try world()
        let solver = TileSolver(world: w)
        let id = try roach(w, x: 400)
        frame(w, id, solver)                                            // lands
        XCTAssertNotEqual(try slot(w, id).groundKind, 0)
        XCTAssertEqual(try slot(w, id).y, 355)
        var flips = 0, minX = Int.max, maxX = Int.min
        var lastFlip = try slot(w, id).mirrored
        for n in 0..<400 {
            let s = try slot(w, id)
            let cx = s.centre.x
            var vx = Int(s.vx), flip = s.mirrored
            func acc(_ a: Int) { vx += a; if vx > 0x4b0 { vx = 0x4b0 } else if vx < -0x4b0 { vx = -0x4b0 } }
            if cx < 400 - 85 { acc(100); flip = true } else if 400 + 85 < cx { acc(-100); flip = false }
            else if !flip && -0x4b0 < vx { acc(-100) } else if flip && 0x4b0 < vx { acc(100) }
            let x0 = s.x256
            let r = w.rng
            frame(w, id, solver)
            let t = try slot(w, id)
            XCTAssertEqual([Int(t.vx), Int(t.x256 - x0)], [vx, vx], "frame \(n)")
            XCTAssertEqual(t.mirrored, flip, "frame \(n)")
            XCTAssertEqual(t.face, f(0x6b8, Int(t.phase >> 1)), "frame \(n)")
            XCTAssertEqual(Int(t.counterA6), max(0, 2 - n), "frame \(n)")
            XCTAssertEqual(w.rng.seed, r.seed, "no draw, frame \(n)")
            if t.mirrored != lastFlip { flips += 1; lastFlip = t.mirrored }
            minX = min(minX, t.centre.x)
            maxX = max(maxX, t.centre.x)
        }
        XCTAssertGreaterThanOrEqual(flips, 4)
        XCTAssertLessThan(minX, 400 - 85)
        XCTAssertGreaterThan(maxX, 400 + 85)
        // An odd p3 halves toward zero (−7 → −3: the band inverts, as written); airborne: no patrol, no count-down.
        let wo = try world()
        let so = TileSolver(world: wo)
        let io = try roach(wo, x: 400, p3: -7)
        frame(wo, io, so)
        wo.active.update(id: io) { $0.vx = 0; $0.mirrored = false }
        frame(wo, io, so)
        // c.x 451: 451 < 400 + 3 false; 400 − 3 < 451 → −100, flip 0.
        XCTAssertEqual([Int(try slot(wo, io).vx)], [-100])
        // The band's edges (c.x 451, home 400): p3 −103 → w −51 (toward zero; `>> 1` would be −52): 451 < 451 is false,
        // 349 < 451 → −100, flip 0; p3 102 → w 51: c.x == home + w is inside — flip 1 at vx 0x4b0 coasts; flip 0 at
        // vx −1199 still accelerates (−1200).
        for (p3, flip, vx, outVX, outFlip) in [(Int16(-103), true, Int32(0), Int32(-100), false),
                                               (102, true, 0x4b0, 0x4b0, true), (102, false, -1199, -0x4b0, false),
                                               (102, false, -0x4b0, -0x4b0, false)] {
            let wb = try world()
            let sb = TileSolver(world: wb)
            let ib = try roach(wb, x: 400, p3: p3)
            frame(wb, ib, sb)
            wb.active.update(id: ib) { $0.vx = 0; $0.mirrored = flip; $0.x256 = 400 << 8; $0.x = 400 }
            wb.standardSpriteCleanup(ib, faceWidth: { _ in 100 })
            XCTAssertEqual(try slot(wb, ib).centre.x, 451)
            wb.active.update(id: ib) { $0.vx = vx }
            frame(wb, ib, sb)
            XCTAssertEqual([Int(try slot(wb, ib).vx), try slot(wb, ib).mirrored ? 1 : 0], [Int(outVX), outFlip ? 1 : 0],
                           "p3 \(p3) flip \(flip) vx \(vx)")
        }
        // The walk counter wraps past 11 (face 0x6b8[0…5]); a state past 4 (none written) stores no gravity.
        wo.active.update(id: io) { $0.phase = 0xa }
        frame(wo, io, so)
        XCTAssertEqual([Int(try slot(wo, io).phase)], [0xb])
        XCTAssertEqual(try slot(wo, io).face, f(0x6b8, 5))
        frame(wo, io, so)
        XCTAssertEqual([Int(try slot(wo, io).phase)], [0])
        wo.active.update(id: io) { $0.subtype = 5; $0.gravity = 7 }
        frame(wo, io, so)
        XCTAssertEqual(try slot(wo, io).gravity, 7)
        wo.active.update(id: io) { $0.subtype = 4; $0.gravity = 7; $0.hp = 1 }
        frame(wo, io, so)
        XCTAssertEqual(try slot(wo, io).gravity, 0x151)
        let wa = try world(floor: false)
        let ia = try roach(wa, x: 400)
        frame(wa, ia, TileSolver(world: wa))
        XCTAssertEqual([Int(try slot(wa, ia).vx), Int(try slot(wa, ia).counterA6)], [0x4b0, 3])
        XCTAssertEqual(try slot(wa, ia).gravity, 0x151)
        // State 2 with HP 1…2 stays state 2 (the hop-flee is entered only from itself); state 3 runs the hop as the
        // Crawler's (`flee`): a player on the right keeps vx negative.
        let wh = try world()
        let sh = TileSolver(world: wh)
        let ih = try roach(wh, x: 400)
        frame(wh, ih, sh)
        wh.active.update(id: ih) { $0.hp = 2 }
        frame(wh, ih, sh)
        XCTAssertEqual(try slot(wh, ih).subtype, 2)
        wh.player.centreX = Int16(try slot(wh, ih).centre.x + 100)
        wh.active.update(id: ih) { $0.subtype = 3; $0.counterA6 = 0; $0.vx = 0 }
        var rh = wh.rng
        let h1 = Int32(rh.next(400)), h2 = Int32(rh.next(800)), h3 = rh.next(0x1e)
        frame(wh, ih, sh)
        let t = try slot(wh, ih)
        XCTAssertEqual([t.classTimer, t.vx, t.vy], [-0x6a4 - h2, (-0x6a4 - h2) / 2, -900 - h1 + 0x151])
        XCTAssertEqual([Int(t.counterA6), Int(t.subtype)], [Int(h3) + 0x14, 3])
        XCTAssertEqual(t.face, f(0x6b8, Int(t.phase >> 1)))
        // `.HitRoachSprite`: a player shot (`+0xa6 == 0`) → killed, `.HurtSprite(s, o.+0xa4, (i16)(o.vx >> 1), −1000, 4,
        // 8)`, blood 40, snd 702 below HP 3, else 701; the Statue arm; `+0xa6 ≠ 0` nothing.
        for (hp, dmg, vx, snd, kvx) in [(Int16(200), Int16(50), Int32(-1001), Int16(701), -501),
                                        (200, 198, 0x20000, 702, 0), (200, 200, 3, 702, 1), (200, 197, 3, 701, 1)] {
            let wr = try world()
            let ir = try roach(wr)
            wr.active.update(id: ir) { $0.hp = hp; $0.vx = 0 }
            wr.player.cues = []
            var lr = LightTable()
            let sr = try shot(wr, damage: dmg, vx: vx)
            CrawlerRoach.hitRoach(wr, id: ir, other: sr, lights: &lr)
            let q = try slot(wr, ir)
            XCTAssertEqual([Int(q.hp), Int(q.vx), Int(q.vy), Int(q.invulnerable), Int(q.flash)],
                           [Int(hp - dmg), kvx, -1000, 4, 8], "dmg \(dmg)")
            XCTAssertEqual(wr.player.cues.map { [Int($0.snd), Int($0.volume)] }, [[Int(snd), 0x100]], "dmg \(dmg)")
            XCTAssertTrue(try slot(wr, sr).dead)
            XCTAssertEqual(wr.particles.records.filter(\.alive).count, 40)
        }
        let wr = try world()
        let ir = try roach(wr)
        var lr = LightTable()
        let light = lr.add(face: nil, x: 0, y: 0, vx: 0, vy: 0, accelY: 0, colour: 5)
        let s3 = try shot(wr, type: 3)
        wr.active.update(id: s3) { $0.light = light }
        CrawlerRoach.hitRoach(wr, id: ir, other: s3, lights: &lr)
        XCTAssertEqual(lr.slots[Int(light)].colour, 0x4d, "the stale r29 is the shot")
        let a6n = try shot(wr, a6: -6)
        wr.active.update(id: ir) { $0.invulnerable = 0 }
        CrawlerRoach.hitRoach(wr, id: ir, other: a6n, lights: &lr)
        XCTAssertFalse(try slot(wr, a6n).dead)
        let a6 = try shot(wr, a6: 1)
        wr.active.update(id: ir) { $0.invulnerable = 0 }
        CrawlerRoach.hitRoach(wr, id: ir, other: a6, lights: &lr)
        XCTAssertFalse(try slot(wr, a6).dead)
        XCTAssertEqual(try slot(wr, ir).hp, 50)
        wr.player.cues = []
        CrawlerRoach.hitRoach(wr, id: ir, other: try shot(wr, type: 1), lights: &lr)
        XCTAssertEqual([try slot(wr, ir).handler, try slot(wr, ir).savedHandler], [.statue, .roach])
        XCTAssertEqual(wr.player.cues.map(\.snd), [302])
        XCTAssertEqual(try slot(wr, ir).hp, 50)
    }

    // MARK: - both

    func testCrushByBox() throws {
        // The crush (Crawler M l. 56620–56634, Roach 65136–65151): a Statue or Box whose `.PlatformBounce` against the
        // enemy is 2 (contact from below — measured on a twin world), with the solid falling (vy > 0) or the enemy on
        // ground → HP 0, `+0x150 = 0x16`; one-way solids too; a Platform: nothing.
        func crush(_ type: Int16, _ handler: SpriteHandler, solidVY: Int32, grounded: Bool,
                   oneWay: Bool = false) throws -> (bounce: Int16, hp: Int16, w150: Int32) {
            func make() throws -> (SpriteWorld, Int, Int) {
                let wc = try world(floor: false)
                let c = type == CrawlerRoach.roach ? try roach(wc) : try crawler(wc)
                wc.active.update(id: c) { $0.vy = -0x400; $0.groundKind = grounded ? 3 : 0 }
                let top = try self.slot(wc, c).hotRect.top + 367 - (type == CrawlerRoach.roach ? 12 : 0) - 30
                let box = try XCTUnwrap(wc.newSprite(type: 0xc12, x: 220, y: top, layer: 2, handler: handler) { b in
                    b.x = 220
                    b.y = top
                    b.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x20, right: 0x40)
                    b.vy = solidVY
                    b.oneWay = oneWay
                })
                return (wc, c, box)
            }
            let (wa, ca, ba) = try make()
            let r = try slot(wa, ca).hotRect
            let centre = SpriteSlot.Point(x: r.left + ((r.right - r.left) >> 1), y: r.top + ((r.bottom - r.top) >> 1))
            let b = wa.platformBounce(mover: ca, solid: ba, centre: centre, factor: 0, rect: r, bounce: false)
            let (wb, cb, bb) = try make()
            var l = LightTable()
            if type == CrawlerRoach.roach {
                CrawlerRoach.hitRoach(wb, id: cb, other: bb, lights: &l)
            } else {
                CrawlerRoach.hitCrawler(wb, id: cb, other: bb, lights: &l)
            }
            let s = try slot(wb, cb)
            return (b, s.hp, s.classWord150)
        }
        for type in [CrawlerRoach.crawler, CrawlerRoach.roach] {
            let hp: Int16 = type == CrawlerRoach.roach ? 200 : 500
            for h in [SpriteHandler.box, .statue] {
                for (vy, grounded, crushed) in [(Int32(1), false, true), (0, true, true), (-5, true, true),
                                                (0, false, false), (-5, false, false)] {
                    let c = try crush(type, h, solidVY: vy, grounded: grounded)
                    XCTAssertEqual(c.bounce, 2, "\(type) \(h)")
                    XCTAssertEqual([Int(c.hp), Int(c.w150)], crushed ? [0, 0x16] : [Int(hp), -1],
                                   "\(type) \(h) vy \(vy) grounded \(grounded)")
                }
            }
            let ow = try crush(type, .box, solidVY: 1, grounded: false, oneWay: true)
            XCTAssertEqual([Int(ow.bounce == 2 ? 1 : 0), Int(ow.hp)], [0, Int(hp)], "one-way: no contact from below")
            XCTAssertEqual(try crush(type, .platform, solidVY: 1, grounded: true).hp, hp, "a Platform: nothing")
            XCTAssertEqual(try crush(type, .inert, solidVY: 1, grounded: true).hp, hp)
        }
        // Crushed, the next Handle dies at once: state 4, `+0x150` 0x16 → 0x17 past 21 — snd 703, face 0, the Kill,
        // the score, the coins; hit callback off.
        for type in [CrawlerRoach.crawler, CrawlerRoach.roach] {
            let w = try world()
            w.levelIndex = 1
            let id = type == CrawlerRoach.roach ? try roach(w) : try crawler(w)
            w.active.update(id: id) { $0.hp = 0; $0.classWord150 = 0x16 }
            w.player.cues = []
            frame(w, id, TileSolver(world: w))
            let s = try slot(w, id)
            XCTAssertEqual([Int(s.subtype), Int(s.classWord150)], [4, 0x17])
            XCTAssertEqual([s.dead, s.killedForGood, s.hasHit], [true, true, false])
            XCTAssertNil(s.face)
            XCTAssertEqual(w.globals.score, type == CrawlerRoach.roach ? 600 : 500)
            XCTAssertEqual(w.player.cues.map(\.snd), [703])
        }
    }

    func testCrawlerRoachLiquids() throws {
        // §2.4 after `.ApplyGravityAndSeparateFromTiles` (Crawler M l. 56497–56512, Roach 65103–65110), submerged from
        // row 8 (y 256) down in a liquid of kind k: the Crawler — kind 0 nothing, 1 / 2 `+0x116 = 0x13`, HP − 100,
        // `+0xaa = 0x11`, snd 701 vol 0x55, 3 heals 4 below 500, ≥ 4 nothing; the Roach — every kind hurts.
        for type in [CrawlerRoach.crawler, CrawlerRoach.roach] {
            for k in 0...4 {
                for hp in [Int16(100), 500] {
                    let w = try world(waterRow: 8, liquid: k)
                    let id = type == CrawlerRoach.roach ? try roach(w, y: 300) : try crawler(w, y: 300)
                    w.active.update(id: id) { $0.hp = hp; $0.subtype = 1 }
                    w.player.cues = []
                    frame(w, id, TileSolver(world: w))
                    let s = try slot(w, id)
                    XCTAssertEqual([Int(s.waterRow), Int(s.waterKind)], [1, k], "\(type) kind \(k)")
                    let hurts = type == CrawlerRoach.roach || k == 1 || k == 2
                    let heal = type == CrawlerRoach.crawler && k == 3 && hp < 500
                    XCTAssertEqual([Int(s.hp), Int(s.invulnerable), Int(s.flash)],
                                   hurts ? [Int(hp) - 100, 0x13, 0x11] : [Int(hp) + (heal ? 4 : 0), 0, 0],
                                   "\(type) kind \(k) hp \(hp)")
                    XCTAssertEqual(w.player.cues.map { [Int($0.snd), Int($0.volume)] }, hurts ? [[701, 0x55]] : [],
                                   "\(type) kind \(k)")
                    // Re-hit only once `+0x116` is back to 0.
                    w.active.update(id: id) { $0.hp = hp }
                    frame(w, id, TileSolver(world: w))
                    XCTAssertEqual(Int(try slot(w, id).hp), Int(hp) + (heal ? 4 : 0), "\(type) kind \(k) second frame")
                }
            }
        }
        // The tile callback: BG water (kind 200…209) → `.HandleUnderWater` unless `+0x140`; FG / BG kinds below 100 →
        // `.WallBounce`, 100…199 → `.WallBounceBG` (measured on twin worlds).
        for done in [false, true] {
            let wu = try world(waterRow: 8, floor: false)
            let iu = try crawler(wu, y: 300)
            wu.active.update(id: iu) { $0.underwaterDone = done }
            CrawlerRoach.hitTile(TileSolver(world: wu), id: iu, pos: TilePos(x: 224, y: 320), kind: 200, layer: .background)
            XCTAssertEqual(Int(try slot(wu, iu).waterRow), done ? 0 : 1, "+0x140 \(done)")
        }
        // FG 150 and BG 100 are where the two routines' answers differ (the others act alike here).
        for (kind, layer, bg) in [(1, TileLayer.foreground, false), (150, .foreground, false), (1, .background, false),
                                  (99, .background, false), (100, .background, true), (101, .background, true),
                                  (199, .background, true)] {
            func make() throws -> (SpriteWorld, Int) {
                let wt = try world(floor: false)
                let it = try roach(wt, x: 200, y: 330)
                wt.standardSpriteCleanup(it, faceWidth: { _ in 100 })
                wt.active.update(id: it) { $0.vx = 900; $0.vy = 700 }
                return (wt, it)
            }
            func by(_ useBG: Bool) throws -> SpriteSlot {
                let (wa, ia) = try make()
                let r = try slot(wa, ia).hotRect
                var pos = TilePos(x: 256, y: 352)
                let solver = TileSolver(world: wa)
                let vc = r.top + ((r.bottom - r.top) >> 1)
                if useBG {
                    solver.wallBounceBG(ia, kind: kind - 100, tile: &pos, vCentre: vc, factor: 0, rect: r, bounce: false)
                } else {
                    solver.wallBounce(ia, kind: kind, tile: &pos, vCentre: vc, factor: 0, rect: r, bounce: false)
                }
                return try slot(wa, ia)
            }
            let (wb, ib) = try make()
            let untouched = try slot(wb, ib)
            CrawlerRoach.hitTile(TileSolver(world: wb), id: ib, pos: TilePos(x: 256, y: 352), kind: kind, layer: layer)
            XCTAssertEqual(try slot(wb, ib), try by(bg), "kind \(kind) \(layer)")
            if kind == 150 || kind == 100 { XCTAssertNotEqual(try by(!bg), try by(bg), "kind \(kind): the routines differ") }
            if kind == 150 { XCTAssertNotEqual(try slot(wb, ib), untouched) }
        }
        let wp = try world()
        XCTAssertNotNil(CrawlerRoach.pass(try slot(wp, try crawler(wp))))
        var noTile = SpriteSlot(type: 0x6b0, x: 0, y: 0)
        noTile.hasTileHit = false
        XCTAssertNil(CrawlerRoach.pass(noTile))
        // The hazards (the Ring of Smiting's explosion is the Effect 0x4b7): an Effect 0x4b7 at `+0x46 < 8`, or a 0x5a0
        // — the Crawler's test `+0x14c == 1 || +0x150 == 2` (as read), the Roach's `+0x14c` 1 or 2 — → `.HurtSprite(s,
        // 100, knock(o.vx), −1000, 4, flash)` (Crawler (int)(0.65 · vx) / 10, Roach vx >> 1 / 8), blood, the cry.
        for type in [CrawlerRoach.crawler, CrawlerRoach.roach] {
            let roachy = type == CrawlerRoach.roach
            func hurt(_ t: Int16, _ handler: SpriteHandler, phase: Int16 = 0, timer: Int32 = 0, w150: Int32 = 0,
                      cleared: Bool = false) throws -> [Int] {
                let w = try world()
                let id = roachy ? try roach(w) : try crawler(w)
                w.active.update(id: id) { $0.hp = 300; $0.vx = 0 }
                let o = try XCTUnwrap(w.newSprite(type: t, x: 230, y: 382, layer: 1, handler: handler) { o in
                    o.x = 230
                    o.y = 382
                    o.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 20, right: 20)
                    o.phase = phase
                    o.classTimer = timer
                    o.classWord150 = w150
                    o.vx = 1001
                    o.handleCleared = cleared
                })
                w.player.cues = []
                var l = LightTable()
                if roachy { CrawlerRoach.hitRoach(w, id: id, other: o, lights: &l) } else {
                    CrawlerRoach.hitCrawler(w, id: id, other: o, lights: &l)
                }
                let s = try slot(w, id)
                return [Int(s.hp), Int(s.vx), Int(s.vy), Int(s.flash), w.player.cues.count,
                        w.particles.records.filter(\.alive).count]
            }
            let hit = [200, roachy ? 500 : 650, -1000, roachy ? 8 : 10, 1, 40]
            let none = [300, 0, 0, 0, 0, 0]
            XCTAssertEqual(try hurt(0x4b7, .effect, phase: 7), hit, "\(type) Smite")
            XCTAssertEqual(try hurt(0x4b7, .effect, phase: 8), none, "\(type)")
            XCTAssertEqual(try hurt(0x4b7, .effect, phase: 7, cleared: true), none, "\(type) idled")
            XCTAssertEqual(try hurt(0x4b7, .bonus, phase: 7), none, "\(type) not an Effect")
            XCTAssertEqual(try hurt(0x5a0, .background, timer: 1), hit, "\(type) geyser 1")
            XCTAssertEqual(try hurt(0x5a0, .inert, timer: 1), hit, "\(type) geyser: type only")
            XCTAssertEqual(try hurt(0x5a0, .background, timer: 2), roachy ? hit : none, "\(type) geyser 2")
            XCTAssertEqual(try hurt(0x5a0, .background, w150: 2), roachy ? none : hit, "\(type) `+0x150` 2")
            XCTAssertEqual(try hurt(0x5a0, .background, timer: 3), none, "\(type)")
            XCTAssertEqual(try hurt(0x5a1, .background, timer: 1), none, "\(type)")
        }
    }

    func testKillScores() throws {
        // The natural death (HP < 1 → state 4; Crawler M l. 56443–56482, Roach 65060–65100): `FastRand(3)` every frame,
        // `+0x5c = 0`, `+0x150` −1 → 1, then + 1 a frame with the face death[min((`+0x150` − 2) >> 1, 5)] — the
        // Crawler's vx × 0.97 —, past 21 (the 21st frame): snd 703, face 0, `.KillCrawler` / `.KillRoach` (counted:
        // live − 1, the stat `G+0x306+2L` + 1, `+0xe9`, `+0xea`), score + 500 (+ 100 in `.KillRoach`), 2 + R(3) coins
        // 0x516 at (c.x − 4, c.y − 4) layer 2 (vy −1400 − R(1600), vx R(1000) − 500) and 100 blood particles.
        for type in [CrawlerRoach.crawler, CrawlerRoach.roach] {
            let roachy = type == CrawlerRoach.roach
            let w = try world()
            let solver = TileSolver(world: w)
            w.levelIndex = 1
            let id = roachy ? try roach(w) : try crawler(w)
            frame(w, id, solver)                                        // lands
            let live = w.enemies.live
            w.active.update(id: id) { $0.hp = 0; $0.vx = 1000; $0.mirrored = false }
            w.player.centreX = Int16(try slot(w, id).centre.x)          // no facing change
            var vx: Int32 = 1000
            for k in 1...20 {
                var r = w.rng
                _ = r.next(3)
                // The first frame is still state 2's: the Roach's patrol (inside the band, flip 0) takes 100 off; then
                // the Crawler's 0.97 friction each dying frame, the Roach's none.
                if roachy && k == 1 { vx -= 100 }
                vx = roachy ? vx : TileSolver.fctiwz(Double(vx) * Double(bitPattern: 0x3fef_0a3d_70a3_d70a))
                frame(w, id, solver)
                let s = try slot(w, id)
                XCTAssertEqual(w.rng.seed, r.seed, "\(type) frame \(k)")
                XCTAssertEqual([Int(s.subtype), Int(s.classWord150)], [4, k + 1], "\(type) frame \(k)")
                XCTAssertEqual(s.face, f(roachy ? CrawlerRoach.roachDeath : CrawlerRoach.deathSet, min((k - 1) >> 1, 5)),
                               "\(type) frame \(k)")
                XCTAssertFalse(s.hasHit)
                XCTAssertFalse(s.dead)
                XCTAssertEqual(s.vx, vx, "\(type) frame \(k)")
            }
            XCTAssertEqual(w.globals.score, 0)
            var r = w.rng
            let n = Int(r.next(3)) + 2
            vx = roachy ? vx : TileSolver.fctiwz(Double(vx) * Double(bitPattern: 0x3fef_0a3d_70a3_d70a))
            let c = try slot(w, id).centre
            w.player.cues = []
            let before = Set(w.active.sprites.map(\.id))
            frame(w, id, solver)
            let s = try slot(w, id)
            XCTAssertEqual([s.dead, s.killedForGood, s.countedInTotals], [true, true, true])
            XCTAssertNil(s.face)
            XCTAssertEqual(w.globals.score, roachy ? 600 : 500, "\(type)")
            XCTAssertEqual(w.enemies.live, live - 1)
            XCTAssertEqual(w.globals.achieved[0][1], 1)
            XCTAssertEqual(w.player.cues.map { [Int($0.snd), Int($0.volume)] }, [[703, 0x100]])
            let coins = w.active.sprites.filter { !before.contains($0.id) }
            XCTAssertEqual(coins.count, n, "\(type)")
            // Each coin: its Setup's draws (replayed on a scratch slot), then vy −1400 − R(1600), vx R(1000) − 500.
            var rc = r
            for coin in coins.sorted(by: { $0.id < $1.id }) {
                var scratch = SpriteSlot(type: 0x516, x: c.x - 4, y: c.y - 4)
                _ = try BonusSprite.setup(&scratch, x: c.x - 4, y: c.y - 4, level: w.level, records: w.records,
                                          effects: 1, lightCount: 0, counting: false, playerLayer: 0,
                                          rng: &rc) { _, _, _, _ in 0 }
                XCTAssertEqual(coin.type, 0x516)                        // its layer is the Bonus Setup's
                XCTAssertEqual(coin.handler, .bonus)
                XCTAssertEqual([Int(coin.x256 >> 8), Int(coin.y256 >> 8)], [c.x - 4, c.y - 4])
                let cvy = -0x578 - Int32(rc.next(0x640)), cvx = Int32(rc.next(1000)) - 500
                XCTAssertEqual([coin.vy, coin.vx], [cvy, cvx])
            }
            // The draws: R(3), each coin's Setup and R(1600), R(1000), then the particles R(700), R(600) a hundred times.
            let parts = w.particles.records.filter(\.alive)
            XCTAssertEqual(parts.count, 100)
            XCTAssertEqual(Set(parts.map { [Int($0.kind), Int($0.gravity), Int($0.shape), Int($0.mode)] }), [[2, 0x50, 4, 1]])
            XCTAssertEqual(Set(parts.map { [Int($0.x >> 8), Int($0.y >> 8)] }), [[c.x - 1, c.y + 6]])
            // The particles in order: R(700) then R(600) — vy −350 − a, vx b − 300.
            var want: [[Int]] = []
            for _ in 0..<100 {
                let a = Int(rc.next(700)), b = Int(rc.next(600))
                want.append([b - 300, -0x15e - a])
            }
            XCTAssertEqual(parts.map { [Int($0.vx), Int($0.vy)] }, want)
            XCTAssertEqual(w.rng.seed, rc.seed, "R(3), the coins, the particles")
            // `+0xe9` set: the next Handle does nothing (no draw, nothing moves).
            let after = w.rng.seed
            let pos = try slot(w, id).y256
            frame(w, id, solver)
            XCTAssertEqual([w.rng.seed, Int32(try slot(w, id).y256)], [after, Int32(pos)])
            XCTAssertEqual(w.globals.score, roachy ? 600 : 500)
        }
        // The Kills directly: counted once; an uncounted one (outside the window) changes no tally; `.KillRoach`'s + 100
        // only while `+0xe9` was 0; both store `+0xea`.
        let w = try world()
        w.levelIndex = 2
        let c = try crawler(w), q = try roach(w), u = try roach(w, counted: false)
        let live = w.enemies.live
        for (id, roachy) in [(c, false), (q, true), (u, true)] {
            var s = try slot(w, id)
            if roachy { CrawlerRoach.killRoach(w, &s) } else { CrawlerRoach.killCrawler(w, &s) }
            if roachy { CrawlerRoach.killRoach(w, &s) } else { CrawlerRoach.killCrawler(w, &s) }
            XCTAssertEqual([s.dead, s.killedForGood], [true, true])
        }
        XCTAssertEqual(w.enemies.live, live - 2)
        XCTAssertEqual(w.globals.achieved[0][2], 2)
        XCTAssertEqual(w.globals.score, 200)
        // A dying sprite with `+0x150 ≤ 0` (as written, never reached): the face and the counter hold.
        let wz = try world()
        let z = try crawler(wz)
        wz.active.update(id: z) { $0.hp = 0; $0.classWord150 = -2; $0.face = nil }
        frame(wz, z, TileSolver(world: wz))
        XCTAssertEqual(try slot(wz, z).classWord150, -2)
        XCTAssertEqual(try slot(wz, z).face, f(CrawlerRoach.walkSet, 0))
        XCTAssertFalse(try slot(wz, z).hasHit)
    }
}
