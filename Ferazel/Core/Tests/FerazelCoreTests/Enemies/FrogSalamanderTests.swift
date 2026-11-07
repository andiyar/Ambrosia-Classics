import XCTest
@testable import FerazelCore

/// FR (docs/plans/2026-10-30-ferazel-phase5.md): the Frog and the Salamander — `.InitFrogSprite` /
/// `.STPlay3DSoundRandFrog` (M l. 70111–70136), `.SetupFrogSprite` (M l. 70137–70220), `.HandleFrogSprite` (M l.
/// 70223–70459), `.HitFrogSprite` (M l. 70462–70553), `.KillFrog` (M l. 70556–70602), `.HitFrogTileSprite` (M l.
/// 70604–70640); `.InitSalamanderSprite` (M l. 70642–70652), `.SetupSalamanderSprite` (M l. 70654–70703),
/// `.HandleSalamanderSprite` (M l. 70705–70857), `.HitSalamanderSprite` (M l. 70859–70911), `.KillSalamander` (M l.
/// 70913–70937), `.HitSalamanderTileSprite` (M l. 70939–70980). The Salamander is placed first on level 50: its
/// placements here are made by hand. A synthetic 60×30 grid over a level header (FG floor along row 20 unless a test
/// says otherwise); every expected draw is re-derived from a copy of the stream at the call site.
final class FrogSalamanderTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// The grid: FG kind 3 along `floorRow`; BG liquid 200 + `liquid` from `waterRow` down; BG kind 3 (solid BG) along
    /// `bgSolidRow`; the player's centre globals at (`px`, `py`).
    private func world(px: Int16 = 1800, py: Int16 = 600, floorRow: Int? = 20, waterRow: Int? = nil, liquid: Int = 0,
                       bgSolidRow: Int? = nil, level: Int16 = 2) throws -> SpriteWorld {
        let w = SpriteWorld(level: try LevelFile.load(from: try resources(), level: level))
        var fg = [UInt16](repeating: 0, count: 60 * 30), bg = fg
        if let r = floorRow { for c in 0..<60 { fg[r * 60 + c] = 4 } }
        if let r = waterRow { for row in r..<30 { for c in 0..<60 { bg[row * 60 + c] = 1 } } }
        if let r = bgSolidRow { for c in 0..<60 { bg[r * 60 + c] = 2 } }
        var bgKinds = [Int](repeating: 0, count: 0x60)
        bgKinds[0] = 200 + liquid
        bgKinds[1] = 3
        w.tiles = TileGrid(fg: TileMap(width: 60, height: 30, cells: fg), bg: TileMap(width: 60, height: 30, cells: bg),
                           fgKinds: Array(0..<0x60), bgKinds: bgKinds)
        w.player.centreX = px
        w.player.centreY = py
        w.levelIndex = 2
        return w
    }

    /// A placement of `type` (record 0) set up by `SetupFaces` inside the counting window, its centre set as a previous
    /// Cleanup leaves it.
    private func enemy(_ w: SpriteWorld, type: Int16 = 0x708, x: Int = 600, y: Int = 500, p1: Int16 = 0)
        throws -> (id: Int, entry: SetupFaces.Entry) {
        let p = Placement(index: 0, flag: 1, byte1: 0, type: type, p1: p1, p2: 0, p3: 0, p4: 0, y: Int16(y), x: Int16(x))
        w.records = [p]
        let c = SetupFaces.Context(level: w.level, playerX: Int(w.player.centreX), records: w.records)
        var lights = LightTable()
        w.enemies.window = true
        let e = try SetupFaces.setup(p, context: c, lights: &lights, counting: &w.enemies, rng: &w.rng)
        w.enemies.window = false
        var s = e.slot
        let r = s.hotRect
        s.centre = SpriteSlot.Point(x: s.x + r.left + ((r.right - r.left) >> 1), y: s.y + r.top + ((r.bottom - r.top) >> 1))
        return (w.active.insert(s), e)
    }

    private func slot(_ w: SpriteWorld, _ id: Int) throws -> SpriteSlot { try XCTUnwrap(w.active.record(id: id)) }

    /// One Handle call by `+0x4c` (the session's dispatch).
    private func frame(_ w: SpriteWorld, _ id: Int, _ solver: TileSolver) {
        switch w.active.record(id: id)?.handler {
        case .salamander?: FrogSalamander.handleSalamander(world: w, id: id, solver: solver)
        default: FrogSalamander.handleFrog(world: w, id: id, solver: solver)
        }
    }

    /// Lets the sprite fall onto the floor with its decision held off (`+0x14c` far below 0), then gives `timer` back.
    private func settle(_ w: SpriteWorld, _ id: Int, _ solver: TileSolver, timer: Int32 = -1) throws {
        w.active.update(id: id) { $0.classTimer = -10000 }
        for _ in 0..<60 { frame(w, id, solver) }
        XCTAssertNotEqual(try slot(w, id).groundKind, 0, "settled on the floor")
        w.active.update(id: id) { $0.classTimer = timer }
        w.player.cues = []
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

    private func enemyShots(_ w: SpriteWorld) -> [SpriteSlot] { w.active.sprites.filter { $0.handler == .enemyShot } }

    private func blood(_ w: SpriteWorld) -> Int { w.particles.records.filter { $0.alive && $0.kind == 2 }.count }

    /// A 4-wide, 6-row face: rows 2…4 opaque, so face `+8` (top) 2 and `+0xc` (bottom) 5 (EnemyCommonTests' shape).
    private static let burnFace: ParticleFace = {
        var t: [UInt8] = []
        func token(_ op: UInt32, _ n: UInt32) {
            let v = op << 24 | n
            t += [UInt8(v >> 24), UInt8((v >> 16) & 0xff), UInt8((v >> 8) & 0xff), UInt8(v & 0xff)]
        }
        for row in 0..<6 {
            token(1, 0)
            if (2...4).contains(row) {
                token(2, 4)
                t += [9, 9, 9, 9]
            }
        }
        token(0, 0)
        return ParticleFace(frame: [0, 0, 6, 4], bounds: [2, 0, 5, 4], tokens: t)
    }()

    // MARK: - the Frog

    func testFrogVariantsByP1() throws {
        // `.SetupFrogSprite` (M l. 70137–70219): HP 500 then the p1 tier (l. 70185–70206), `+0xb0 = 0xb`, `+0x14c = −0x14
        // − R(0x1e)`, `+0x15c` = the live record's p1 (l. 70180–70181), `+0xf0 = R(0x5fff)·2 + 0xbfff`, gravity 0x8c, `+0x150 =
        // −1`, `+0xa6 = 0`, rect SetRect(0xb, 0x14, 0x48, 0x49), the cache set 0x708 marked and face 0, counted (l.
        // 70211–70215). `.KillFrog` (M l. 70556–70602): the count, `+0xe9 = +0xea = 1`, score by p1 — unconditional.
        for (p1, hp, mode, score) in [(Int16(0), Int16(0x15e), UInt32(0), Int32(500)), (1, 500, 0x1000c, 600),
                                      (2, 0x15e, 0x10017, 600), (3, 0x5dc, 0x1000f, 2000), (4, 1000, 0x1000b, 1000),
                                      (5, 500, 0, 0), (-1, 500, 0, 0)] {
            let w = try world()
            var x = w.rng
            let (id, e) = try enemy(w, x: 600, y: 500, p1: p1)
            let s = e.slot
            XCTAssertEqual(s.classTimer, -0x14 - Int32(x.next(0x1e)), "p1 \(p1)")
            XCTAssertEqual(s.voicePitch, Int32(x.next(0x5fff)) * 2 + 0xbfff, "p1 \(p1)")
            XCTAssertEqual(w.rng.seed, x.seed, "p1 \(p1): two draws")
            XCTAssertEqual([s.hp, Int16(s.classWord15c)], [hp, p1], "p1 \(p1)")
            XCTAssertEqual(s.mode, mode, "p1 \(p1)")
            XCTAssertEqual([Int(s.layer), Int(s.subtype), Int(s.gravity), Int(s.counterA6)], [0xb, 0xb, 0x8c, 0])
            XCTAssertEqual([s.classWord150, s.classWord154, s.classWord158], [-1, 0, 0])
            XCTAssertEqual(s.hotRect, rect(0xb, 0x14, 0x48, 0x49))
            XCTAssertEqual(s.handler, .frog)
            XCTAssertEqual([s.hasHit, s.hasTileHit, s.countedInTotals, s.burnStyle], [true, true, true, false])
            // The write-back flags: the Setup stores none of `+0x188`…`+0x18b` (nor `+0xea`).
            XCTAssertEqual([s.keepRecord, s.noWriteBack189, s.noWriteBack18a, s.keepRecordAtKill, s.killedForGood],
                           [false, false, false, false, false], "p1 \(p1)")
            XCTAssertEqual([s.particleOffsetX, s.particleOffsetY], [0, 0])
            XCTAssertEqual([s.x, s.y, Int(s.x256 >> 8), Int(s.y256 >> 8)], [600, 500, 600, 500])
            XCTAssertEqual(s.face, f(0x708, 0))
            XCTAssertEqual(e.source, .setupCached)
            XCTAssertEqual(e.sheet, SetupFaces.Sheet(pict: 0x708, count: 8, cellWidth: 0x78, cellHeight: 100, columns: 8,
                                                     clut: 200))
            XCTAssertEqual(w.enemies.live, 1)
            // The Kill proc `+0x50` (`.HandleBurn` calls it at the opaque bottom): counted once, `+0xea` set, score.
            w.globals.score = 0
            EnemyCommon.killProc(w, id: id)
            let k = try slot(w, id)
            XCTAssertEqual([k.dead, k.killedForGood], [true, true], "p1 \(p1): `+0xe9`, `+0xea` (M l. 70574–70575)")
            XCTAssertEqual([w.globals.score, w.enemies.live, Int32(w.globals.achieved[0][2])], [score, 0, 1], "p1 \(p1)")
            EnemyCommon.killProc(w, id: id)
            XCTAssertEqual([w.globals.score, w.enemies.live, Int32(w.globals.achieved[0][2])], [2 * score, 0, 1],
                           "p1 \(p1): a second Kill counts nothing, scores again")
        }
        XCTAssertEqual(CachedFaces.marks(type: 0x708).sets, [0x708], "the Setup marks set 0x708 (M l. 70211)")
        // A freezing-water level (hdr+0x26cd ≠ 0, level 30): `+0x8e = 1` — the burn's particle kind 0xd.
        let cold = try world(level: 30)
        XCTAssertNotEqual(cold.level.header.inLiquid, 0)
        XCTAssertTrue(try enemy(cold).entry.slot.burnStyle)
        // A level-2 session sets its two Frogs up with the Frog class (active or idled at the start).
        let session = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 2)
        let frogs = session.world.active.sprites.filter { $0.type == 0x708 }
            + session.world.idle.entries.compactMap { $0?.saved }.filter { $0.type == 0x708 }
        XCTAssertEqual(frogs.map(\.handler), [.frog, .frog])
        XCTAssertEqual(frogs.map(\.countedInTotals), [true, true])
    }

    func testFrogLeapCycle() throws {
        // State 0xb (M l. 70406–70446) → 9 (l. 70328–70391: crouch faces min(+0x46/3, 2), the launch at `+0x46 ≥ 8`) →
        // 10 (l. 70392–70405: vx = `+0x158`, gravity 0x5a, face 3 / 4 by vy) → landing: face 5, state 0xb.
        // Near (|dx| < 250): the decision draws R(100); ≥ 0x47 → state 9.
        let near = seed { r in 0x47 <= r.next(100) }
        let w = try world(px: 450)
        let (id, _) = try enemy(w)
        let solver = TileSolver(world: w)
        try settle(w, id, solver)
        w.player.centreY = Int16(try slot(w, id).centre.y)
        w.rng = FastRand(seed: near)
        var x = w.rng
        frame(w, id, solver)
        _ = x.next(100)
        var s = try slot(w, id)
        XCTAssertEqual([Int(s.subtype), Int(s.phase), Int(s.classTimer)], [9, 0, 0])
        XCTAssertEqual(w.rng.seed, x.seed, "one draw")
        XCTAssertFalse(s.mirrored, "the player left: facing left")
        // The crouch: phases 0…7, faces by `+0x46 / 3`; the launch at `+0x46` 8.
        var faces: [Int] = []
        while try slot(w, id).subtype == 9 && faces.count < 20 {
            let before = try slot(w, id)
            x = w.rng
            frame(w, id, solver)
            s = try slot(w, id)
            if s.subtype == 9 {
                faces.append(s.face?.index ?? -1)
                XCTAssertEqual(s.vx, 0)
                XCTAssertEqual(w.rng.seed, x.seed, "no draw while crouching")
                continue
            }
            // The launch (l. 70333–70389): R(100) > 0x37 → frogjump 613 (vol 0x80, the frog's pitch); `+0xce = 0`;
            // vx = −0x28a − R(200), vy = −0x514 − R(400); `+0x154 ≥ 0` → `+0x14c = −10 − R(10)`; the aim; gravity 0x5a;
            // facing left: vx kept; `+0x158 = vx`.
            XCTAssertEqual(before.phase, 8)
            let jump = x.next(100)
            var cues: [PlayerCue] = []
            if 0x37 < jump {
                let rate = before.voicePitch + Int32(x.next(10000)) - 5000
                cues.append(PlayerCue(call: .threeDPitched, snd: 613, priority: 1, volume: 0x80, position: before.centre,
                                      rate: rate))
            }
            let vx = -0x28a - Int32(x.next(200))
            var vy = -0x514 - Int32(x.next(400))
            let timer = -10 - Int32(x.next(10))
            // ⚑ The aim's "player above" test reads the player's centre X (M l. 70358, `_DAT_1009fd94`): x 450 < the
            // frog's cy − 0x28 (≈ 573), so the "above" branch is taken though the player stands level with the frog:
            // vy −= R(0x96) + 200, and no near-range R(100).
            vy -= Int32(x.next(0x96)) + 200
            XCTAssertEqual(w.rng.seed, x.seed)
            XCTAssertEqual(w.player.cues, cues)
            XCTAssertEqual([Int(s.subtype), s.face?.index ?? -1, Int(s.gravity)], [10, 3, 0x5a])
            XCTAssertEqual([s.classWord158, s.classTimer, s.vx], [vx, timer, vx])
            XCTAssertEqual(s.vy, vy + 0x5a, "one gravity call (the frog stood on the floor at the switch)")
        }
        XCTAssertEqual(faces, [0, 0, 0, 1, 1, 1, 2, 2], "phases 0…7")
        // Airborne: three integrations of vx a frame (gravity call, `x += vx`, gravity call), face 3 rising, 4 falling,
        // gravity 0x5a; on ground: face 5, state 0xb, gravity 0x5a — this "above" arc (the playerX aim, M l. 70358) lands
        // in the frame before (the second gravity call: `.HitFrogTileSprite` stores 400), then the switch frame stores
        // 0x5a and its second gravity call makes no FG tile hit (`+0xce` back to 0), so no 400 is stored after it.
        var airFaces: [Int] = []
        var n = 0
        while try slot(w, id).subtype == 10 && n < 120 {
            let before = try slot(w, id)
            frame(w, id, solver)
            s = try slot(w, id)
            n += 1
            if s.subtype == 10 {
                airFaces.append(s.face?.index ?? -1)
                XCTAssertEqual(s.vx, before.classWord158)
                if before.groundKind == 0 && s.groundKind == 0 && n > 1 {
                    XCTAssertEqual(s.x256 - before.x256, 3 * before.classWord158, "frame \(n): three integrations")
                }
            }
        }
        XCTAssertEqual([Int(s.subtype), s.face?.index ?? -1, Int(s.gravity), Int(s.groundKind)], [0xb, 5, 0x5a, 0])
        XCTAssertEqual(Set(airFaces), [3, 4])
        XCTAssertEqual(airFaces.first, 3)
        XCTAssertEqual(airFaces.last, 4)
        XCTAssertLessThan(s.x, 600, "it hopped toward the player")

        // Far (|dx| ≥ 250), the player on the right: state 9 with no draw, facing right (`+0x17e`); the launch scales vx /
        // vy by 0.7 (f64 `0x100a1bd8`), sets `+0x14c = −4 − R(4)`, and the facing negates vx (l. 70384–70386). The
        // player stands at x ≥ the frog's cy − 0x28: at x 100 (the player on the left) the aim's playerX test (M l.
        // 70358) takes the "above" branch instead, so a far left launch from this frog is never far.
        let v = try world(px: 1200)
        let (fid, _) = try enemy(v)
        let vs = TileSolver(world: v)
        try settle(v, fid, vs)
        v.player.centreY = Int16(try slot(v, fid).centre.y)
        let seed0 = v.rng.seed
        frame(v, fid, vs)
        XCTAssertEqual([Int(try slot(v, fid).subtype), Int(v.rng.seed == seed0 ? 1 : 0)], [9, 1])
        XCTAssertTrue(try slot(v, fid).mirrored, "the player right: facing right")
        for _ in 0..<8 { frame(v, fid, vs) }
        var y = v.rng
        frame(v, fid, vs)
        if 0x37 < y.next(100) { _ = y.next(10000) }
        let vx0 = -0x28a - Int32(y.next(200)), vy0 = -0x514 - Int32(y.next(400))
        _ = y.next(10)
        let far = Double(bitPattern: 0x3fe6_6666_6666_6666)
        let fx = Int32(Double(vx0) * far), fy = Int32(Double(vy0) * far)
        let ft = -4 - Int32(y.next(4))
        let t = try slot(v, fid)
        XCTAssertEqual([t.classWord158, t.vx, t.classTimer, t.vy], [-fx, -fx, ft, fy + 0x5a], "facing right: vx negated")
        XCTAssertEqual(v.rng.seed, y.seed)
        n = 0
        while try slot(v, fid).subtype == 10 && n < 120 {
            frame(v, fid, vs)
            n += 1
        }
        XCTAssertEqual(try slot(v, fid).subtype, 0xb)
        XCTAssertGreaterThan(try slot(v, fid).x, 600, "it hopped right, toward the player")

        // A hop chain: R(100) < 8 → state 9 with `+0x154 = −3 − R(3)`; each launch counts it up and sets `+0x14c = 0`
        // (no draw), so the landing re-decides at once — and `+0x154 < 0` sends it straight back to state 9.
        let chain = seed { r in r.next(100) < 8 }
        let u = try world(px: 450)
        let (cid, _) = try enemy(u)
        let us = TileSolver(world: u)
        try settle(u, cid, us)
        u.player.centreY = Int16(try slot(u, cid).centre.y)
        u.rng = FastRand(seed: chain)
        var z = u.rng
        frame(u, cid, us)
        _ = z.next(100)
        let hops = -3 - Int32(z.next(3))
        XCTAssertEqual([Int(try slot(u, cid).subtype), Int(try slot(u, cid).classWord154)], [9, Int(hops)])
        for _ in 0..<9 { frame(u, cid, us) }
        XCTAssertEqual([Int(try slot(u, cid).subtype), Int(try slot(u, cid).classWord154),
                        Int(try slot(u, cid).classTimer)], [10, Int(hops) + 1, 0])
        n = 0
        while try slot(u, cid).subtype == 10 && n < 120 {
            frame(u, cid, us)
            n += 1
        }
        XCTAssertEqual(try slot(u, cid).subtype, 0xb)
        z = u.rng
        frame(u, cid, us)
        _ = z.next(100)
        XCTAssertEqual([Int(try slot(u, cid).subtype), Int(try slot(u, cid).phase)], [9, 0])
        XCTAssertEqual(u.rng.seed, z.seed, "one R(100), and `+0x154 < 0` → state 9")

        // The launch's aim (M l. 70356–70386), one launch frame at a time from one settled Frog (x 600) restored before
        // each: state 9 at `+0x46` 8, `+0x154` 0, facing by `c.x < P.x`. ⚑ The "player above" test compares the
        // player's centre X with the frog's centre y − 0x28 (M l. 70358 `(short)*puVar1 < *(short *)(s + 0xe) − 0x28`,
        // `puVar1 = _DAT_1009fd94` = playerX, l. 70242; raw `100824bc lha r4,0x0(r30)` with r30 = `-0x7aac(r2)` at
        // `1008215c`) — the bank's "playerY" was wrong; the port copies the binary.
        let a = try world(px: 600)
        let (aid, _) = try enemy(a)
        let asolver = TileSolver(world: a)
        try settle(a, aid, asolver, timer: -500)
        let rest = try slot(a, aid)
        let acx = rest.centre.x, acy = rest.centre.y, above = rest.centre.y - 0x28
        func common(_ x: inout FastRand) -> (vx: Int32, vy: Int32, timer: Int32, cue: Bool) {
            let cue = 0x37 < x.next(100)
            if cue { _ = x.next(10000) }
            let vx = -0x28a - Int32(x.next(200)), vy = -0x514 - Int32(x.next(400))
            return (vx, vy, -10 - Int32(x.next(10)), cue)
        }
        func launch(px: Int, py: Int, seed sd: Int32 = 1, _ aim: String, _ msg: String) throws {
            a.active.update(id: aid) { $0 = rest; $0.subtype = 9; $0.phase = 8; $0.mirrored = acx < px }
            a.player.centreX = Int16(px)
            a.player.centreY = Int16(py)
            a.player.cues = []
            a.rng = FastRand(seed: sd)
            var x = a.rng
            frame(a, aid, asolver)
            let s = try slot(a, aid)
            let c = common(&x)
            var vx = c.vx, vy = c.vy, timer = c.timer
            switch aim {
            case "above":
                vy -= Int32(x.next(0x96)) + 200
            case "near":
                if 0x50 < x.next(100) {
                    vy -= 0x15e
                    vx -= 200
                }
            default:                                                    // far
                vx = Int32(Double(vx) * Double(bitPattern: 0x3fe6_6666_6666_6666))
                vy = Int32(Double(vy) * Double(bitPattern: 0x3fe6_6666_6666_6666))
                timer = -4 - Int32(x.next(4))
            }
            if acx < px { vx = -vx }
            XCTAssertEqual([s.classWord158, s.vx, s.vy, s.classTimer], [vx, vx, vy + 0x5a, timer], "\(aim): \(msg)")
            XCTAssertEqual(a.rng.seed, x.seed, "\(aim): \(msg)")
            XCTAssertEqual(a.player.cues.map(\.snd), c.cue ? [613] : [], "\(aim): \(msg)")
        }
        // The quirk both ways: player x above the threshold with player y level → "above"; player y far above with
        // player x past the threshold → the near-range arm (a playerY read would take "above" for this one).
        try launch(px: above - 1, py: acy, "above", "x one below cy − 0x28")
        try launch(px: above, py: acy, "near", "x at cy − 0x28: the test is strict")
        try launch(px: acx, py: acy - 200, "near", "the player 200 px above the frog: y is never read here")
        // The near range |c.x − P.x| < 0xfb (l. 70366), the player on the right (facing right negates vx).
        try launch(px: acx + 0xfa, py: acy, "near", "|dx| 0xfa")
        try launch(px: acx + 0xfb, py: acy, "far", "|dx| 0xfb")
        // The near-range boost R(100) > 0x50 (l. 70367–70371) and the jump sound R(100) > 0x37 (l. 70334), at their edges.
        for v in [Int16(0x50), 0x51] {
            try launch(px: acx, py: acy, seed: seed { r in _ = common(&r); return r.next(100) == v }, "near",
                       "boost draw \(v)")
        }
        for v in [Int16(0x37), 0x38] {
            try launch(px: acx, py: acy, seed: seed { r in r.next(100) == v }, "near", "jump-sound draw \(v)")
        }

        // The idle decision (M l. 70406–70446) from the same Frog: `+0x14c` −1 → 0 decides. `+0x17e = c.x < P.x`
        // (l. 70409–70411: equal x faces left). |dx| < 0xfa → R(100): 10 < R < 0x47 with P.y < c.y − 0x32 → 100 (the
        // player-above override, which does read playerY, `_DAT_1009fd90`); R < 0x47 with `+0x154 ≥ 0` → R < 8: state 9,
        // `+0x154 = −3 − R(3)`; else state 2; otherwise state 9. Every branch sets `+0x46 = 0`.
        func decide(px: Int, py: Int, r v: Int16?, hops: Int32 = 0) throws -> (s: SpriteSlot, draws: FastRand) {
            a.active.update(id: aid) { $0 = rest; $0.subtype = 0xb; $0.classTimer = -1; $0.classWord154 = hops; $0.phase = 5 }
            a.player.centreX = Int16(px)
            a.player.centreY = Int16(py)
            if let v { a.rng = FastRand(seed: seed { r in r.next(100) == v }) }
            let x = a.rng
            frame(a, aid, asolver)
            return (try slot(a, aid), x)
        }
        for (px, py, v, hops, state, msg) in [
            (acx - 0xfa, acy, Int16?.none, Int32(0), Int16(9), "|dx| 0xfa: far, no draw"),
            (acx - 0xf9, acy, 0x47, 0, 9, "|dx| 0xf9: near, R 0x47"),
            (acx, acy - 0x33, 10, 0, 2, "above, R 10: not overridden"),
            (acx, acy - 0x33, 11, 0, 9, "above, R 11: overridden to 100"),
            (acx, acy - 0x33, 0x46, 0, 9, "above, R 0x46: overridden"),
            (acx, acy - 0x32, 0x46, 0, 2, "P.y at c.y − 0x32: not above"),
            (acx, acy, 8, 0, 2, "R 8: spit"),
            (acx, acy, 0x46, -1, 9, "`+0x154` −1: state 9"),
        ] {
            let (s, x0) = try decide(px: px, py: py, r: v, hops: hops)
            var x = x0
            if v != nil { _ = x.next(100) }
            XCTAssertEqual([Int(s.subtype), Int(s.phase), Int(s.classWord154)], [Int(state), 0, Int(hops)], msg)
            XCTAssertEqual(a.rng.seed, x.seed, msg)
        }
        let (r7, x7) = try decide(px: acx, py: acy, r: 7)
        var y7 = x7
        _ = y7.next(100)
        XCTAssertEqual([Int(r7.subtype), Int(r7.phase), Int(r7.classWord154)], [9, 0, -3 - Int(y7.next(3))], "R 7: hops")
        XCTAssertEqual(a.rng.seed, y7.seed)
        XCTAssertFalse(try decide(px: acx, py: acy, r: 0x47).s.mirrored, "c.x == P.x: facing left")
        XCTAssertTrue(try decide(px: acx + 1, py: acy, r: 0x47).s.mirrored, "c.x < P.x: facing right")
    }

    func testFrogSpitAtStep6() throws {
        // State 2 (M l. 70270–70319): vx 0; k = `+0x46 / 3`: k < 5 → face 5 + (k ≤ 2 ? k : 4 − k); at `+0x46 == 6`
        // `MTNewSprite(0x709, cx + flip·0x5a − 0x2d, cy − 0x14, layer + 1, −1, .SetupEnemyShotSprite)`, vx ±2000 by
        // facing, the p1 tint (×2/×4/×3 on the shot's `+0xa4`, which is 0); k ≥ 5 → state 0xb, `+0x14c = −10 − R(10)`,
        // face 0. The decision (l. 70419–70433): 8 ≤ R(100) ≤ 0x46 with `+0x154 ≥ 0` → state 2.
        let spit = seed { r in (8..<0x47).contains(r.next(100)) }
        for (p1, px, mode) in [(Int16(0), Int16(450), UInt32(0)), (1, 450, 0x1000c), (2, 750, 0x10017),
                               (3, 750, 0x1000f), (4, 450, 0x1000b)] {
            let w = try world(px: px)
            let (id, _) = try enemy(w, p1: p1)
            let solver = TileSolver(world: w)
            try settle(w, id, solver)
            w.player.centreY = Int16(try slot(w, id).centre.y)
            w.rng = FastRand(seed: spit)
            frame(w, id, solver)
            XCTAssertEqual([Int(try slot(w, id).subtype), Int(try slot(w, id).phase)], [2, 0], "p1 \(p1)")
            var faces: [Int] = []
            var shot: SpriteSlot?
            for _ in 0..<16 {
                let before = try slot(w, id)
                var x = w.rng
                frame(w, id, solver)
                let s = try slot(w, id)
                XCTAssertEqual(s.vx, 0)
                if s.subtype != 2 {
                    XCTAssertEqual(before.phase, 15)
                    XCTAssertEqual([Int(s.subtype), s.face?.index ?? -1, Int(s.classTimer)],
                                   [0xb, 0, -10 - Int(x.next(10))], "p1 \(p1): back to idle")
                    XCTAssertEqual(w.rng.seed, x.seed)
                    break
                }
                faces.append(s.face?.index ?? -1)
                if before.phase == 6 {
                    let shots = enemyShots(w)
                    XCTAssertEqual(shots.count, 1, "p1 \(p1): the spit at `+0x46 == 6`")
                    shot = shots.first
                    let c = before.centre
                    let sx = Int(Int16(truncatingIfNeeded: c.x + (before.mirrored ? 0x5a : 0) - 0x2d))
                    let sy = Int(Int16(truncatingIfNeeded: c.y - 0x14))
                    XCTAssertEqual(shot?.oldPosition, SpriteSlot.Point(x: sx, y: sy), "p1 \(p1)")
                    XCTAssertEqual(shot?.phase, x.next(5), "the shot Setup's R(5)")
                    XCTAssertEqual(w.rng.seed, x.seed)
                } else {
                    XCTAssertEqual(w.rng.seed, x.seed, "no draw at `+0x46` \(before.phase)")
                }
            }
            XCTAssertEqual(faces, [5, 5, 5, 6, 6, 6, 7, 7, 7, 6, 6, 6, 5, 5, 5], "p1 \(p1): phases 0…14")
            let sp = try XCTUnwrap(shot)
            XCTAssertEqual(sp.type, 0x709)
            XCTAssertEqual(sp.handler, .enemyShot)
            XCTAssertEqual(sp.vx, px < 600 ? -2000 : 2000, "p1 \(p1): vx by facing")
            XCTAssertEqual(sp.mode, mode, "p1 \(p1): the tint")
            XCTAssertEqual([Int(sp.hp), Int(sp.layer), Int(sp.gravity)], [0, 0xc, 0], "p1 \(p1)")
            XCTAssertEqual(sp.hotRect, rect(8, 3, 0xf, 0xc))
        }
    }

    func testFrogHitByShot() throws {
        // `.HitFrogSprite` (M l. 70462–70553): ignored in state 4; a player shot with `+0xa6 == 0`: `.KillPlayerShot(o,
        // 0, 0)`; type 1 → `.TurnIntoStatue`; else `.HurtSprite(s, o.+0xa4, o.vx >> 3, o.vy >> 3, 8, 8)` and on a hurt:
        // R(100) < 0x2e → 701 else froghit 614 (vol 0x100, the frog's pitch); state 9 unless 10; `+0x46 = 3`; HP > 0 →
        // `.BloodSpray(s, o, 0x28, 400, 0x96, 2)`.
        let w = try world()
        let (id, _) = try enemy(w)
        let solver = TileSolver(world: w)
        try settle(w, id, solver, timer: -500)
        let sid = try other(w, over: id, damage: 150, vx: 1000, vy: -200)
        var x = w.rng
        let before = try slot(w, id)
        FrogSalamander.hitFrog(w, id: id, other: sid)
        var s = try slot(w, id)
        XCTAssertTrue(try slot(w, sid).dead, "the shot killed")
        XCTAssertEqual([Int(s.hp), Int(s.invulnerable), Int(s.flash)], [0x15e - 150, 8, 8])
        XCTAssertEqual([s.vx - before.vx, s.vy - before.vy], [Int32(1000 >> 3), Int32(-200 >> 3)])
        XCTAssertEqual([Int(s.subtype), Int(s.phase)], [9, 3])
        let r = x.next(100)
        let rate = before.voicePitch + Int32(x.next(10000)) - 5000
        XCTAssertEqual(w.player.cues.last, PlayerCue(call: .threeDPitched, snd: r < 0x2e ? 701 : 614, priority: 1,
                                                     volume: 0x100, position: s.centre, rate: rate))
        XCTAssertEqual(blood(w), 0x28, "alive: blood")
        // HP exactly 1 lives on through a frame (M l. 70448 `+0xa4 < 1`): no state 4, no frogdie.
        w.active.update(id: id) { $0.hp = 1 }
        w.player.cues = []
        frame(w, id, solver)
        XCTAssertNotEqual(try slot(w, id).subtype, 4, "HP 1: alive")
        XCTAssertFalse(w.player.cues.contains { $0.snd == 615 })
        // The hurt sound's draw at its edge (l. 70494 `R(100) < 0x2e`): 0x2d → 701, 0x2e → froghit 614.
        for v in [Int16(0x2d), 0x2e] {
            let h = try world()
            let (hid, _) = try enemy(h)
            let hs = try other(h, over: hid)
            h.rng = FastRand(seed: seed { r in r.next(100) == v })
            FrogSalamander.hitFrog(h, id: hid, other: hs)
            XCTAssertEqual(h.player.cues.last?.snd, v < 0x2e ? 701 : 614, "draw \(v)")
        }
        // Airborne (state 10) stays 10; `+0x46 = 3` all the same. A killing shot: no blood.
        w.active.update(id: id) { $0.subtype = 10; $0.invulnerable = 0; $0.hp = 100 }
        let kill = try other(w, over: id, damage: 150)
        let spray = blood(w)
        FrogSalamander.hitFrog(w, id: id, other: kill)
        s = try slot(w, id)
        XCTAssertEqual([Int(s.subtype), Int(s.phase), Int(s.hp)], [10, 3, -50])
        XCTAssertEqual(blood(w), spray, "dead: no blood")
        // State 4 (dying): the hit is ignored — the shot lives on.
        w.active.update(id: id) { $0.subtype = 4 }
        let late = try other(w, over: id)
        FrogSalamander.hitFrog(w, id: id, other: late)
        XCTAssertFalse(try slot(w, late).dead)
        // The Statue spell (shot type 1): `.TurnIntoStatue`.
        let v = try world()
        let (vid, _) = try enemy(v)
        let statue = try other(v, over: vid, type: 1)
        FrogSalamander.hitFrog(v, id: vid, other: statue)
        XCTAssertEqual(try slot(v, vid).handler, .statue)
        // The Smiting explosion (Effect 0x4b7 at `+0x46 < 8`) and an active geyser 0x5a0 (`+0x14c == 1 || +0x150 == 2`):
        // `.HurtSprite(100, o.vx >> 3, o.vy >> 3, 8, 8)`; snd 702 below HP 201, else 701 (unpitched, no draw).
        for (type, handler, phase, timer, w150, hurts) in [
            (Int16(0x4b7), SpriteHandler.effect, Int16(7), Int32(0), Int32(0), true), (0x4b7, .effect, 8, 0, 0, false),
            (0x5a0, .background, 0, 1, 0, true), (0x5a0, .background, 0, 0, 2, true), (0x5a0, .background, 0, 2, 0, false),
        ] {
            let u = try world()
            let (uid, _) = try enemy(u)
            u.player.cues = []
            let o = try other(u, over: uid, type: type, handler: handler, vx: 800, vy: 400) { s in
                s.phase = phase
                s.classTimer = timer
                s.classWord150 = w150
            }
            FrogSalamander.hitFrog(u, id: uid, other: o)
            let t = try slot(u, uid)
            XCTAssertEqual(t.hp, hurts ? 0x15e - 100 : 0x15e, "\(type) \(phase) \(timer) \(w150)")
            if hurts {
                XCTAssertEqual([Int(t.subtype), Int(t.phase), Int(t.vx), Int(t.vy)], [9, 3, 100, 50])
                XCTAssertEqual(u.player.cues, [PlayerCue(call: .threeD, snd: 701, priority: 1, volume: 0x100,
                                                         position: t.centre)])
            }
        }
        let low = try world()
        let (lid, _) = try enemy(low)
        low.active.update(id: lid) { $0.hp = 250 }
        low.player.cues = []
        let blast = try other(low, over: lid, type: 0x4b7, handler: .effect) { $0.phase = 0 }
        FrogSalamander.hitFrog(low, id: lid, other: blast)
        XCTAssertEqual(low.player.cues.map(\.snd), [702], "HP 150 < 201: 702")
        // At the edge (l. 70530 `+0xa4 < 0xc9`): HP 200 after the blast → 702, 201 → 701.
        for (hp, snd) in [(Int16(300), Int16(702)), (301, 701)] {
            let e = try world()
            let (eid, _) = try enemy(e)
            e.active.update(id: eid) { $0.hp = hp }
            e.player.cues = []
            let b = try other(e, over: eid, type: 0x4b7, handler: .effect) { $0.phase = 0 }
            FrogSalamander.hitFrog(e, id: eid, other: b)
            XCTAssertEqual(e.player.cues.map(\.snd), [snd], "HP \(hp - 100)")
        }
        // A Box falling on it from above (`.PlatformBounce` 2, the solid's vy > 0): crushed — HP 0, `+0x150 = 0x16`.
        let c = try world()
        let (cid, _) = try enemy(c)
        let cs = TileSolver(world: c)
        try settle(c, cid, cs, timer: -500)
        c.active.update(id: cid) { $0.vy = -0x400 }
        let fr = try slot(c, cid)
        let bx = fr.x + fr.hotRect.left, by = fr.y + fr.hotRect.top - 30
        let box = try XCTUnwrap(c.newSprite(type: 0xc12, x: bx, y: by, layer: 2, handler: .box) { s in
            s.x = bx
            s.y = by
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x20, right: fr.hotRect.right - fr.hotRect.left)
            s.vy = 1
        })
        FrogSalamander.hitFrog(c, id: cid, other: box)
        XCTAssertEqual([Int(try slot(c, cid).hp), Int(try slot(c, cid).classWord150)], [0, 0x16])
    }

    func testFrogDeathBurns() throws {
        // HP < 1 with state ≠ 4 (M l. 70448–70452): `+0x46 = 0`, state 4, frogdie 615 (vol 0x100, the frog's pitch).
        // State 4 (l. 70320–70327): vx × 0.9 (f64 `0x100a1bd0`), face 4, `+0x1a2 = max(+0x1a2, 1)` → the burn from the
        // Cleanup (`.HandleBurn`), whose end calls the Kill proc `.KillFrog`: score + 500 (p1 0), `+0xe9`, `+0xea`.
        let w = try world()
        w.particleFaces = ParticleFaces(sprite: { _ in Self.burnFace })
        var prefs = FerazelPrefs()
        prefs.effects = 2
        w.voices = SoundVoices(prefs: prefs)
        let (id, _) = try enemy(w)
        let solver = TileSolver(world: w)
        try settle(w, id, solver, timer: -500)
        XCTAssertEqual(w.enemies.live, 1)
        // It dies mid-leap (state 10, `+0x158` 1000): the death frame's state-10 arm stores vx = `+0x158` (l. 70399) before
        // the HP test, so the dying frames slide from 1000 (the idle arm would zero vx, l. 70407).
        w.active.update(id: id) { $0.hp = 0; $0.subtype = 10; $0.classWord158 = 1000 }
        var x = w.rng
        let before = try slot(w, id)
        frame(w, id, solver)
        var s = try slot(w, id)
        XCTAssertEqual([Int(s.subtype), Int(s.phase), Int(s.burnRow)], [4, 0, 0])
        XCTAssertEqual(s.vx, 1000)
        let rate = before.voicePitch + Int32(x.next(10000)) - 5000
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDPitched, snd: 615, priority: 1, volume: 0x100,
                                                 position: before.centre, rate: rate)])
        // The dying frames: vx × 0.9 a frame, face 4, the burn; the frog's own sound never again.
        w.player.cues = []
        w.globals.score = 0
        var vx: Int32 = s.vx
        var frames = 0
        while !(try slot(w, id).dead) && frames < 20 {
            frame(w, id, solver)
            frames += 1
            s = try slot(w, id)
            vx = Int32(Double(vx) * Double(bitPattern: 0x3fec_cccc_cccc_cccd))
            XCTAssertEqual([Int(s.subtype), s.face?.index ?? -1], [4, 4])
            XCTAssertEqual(s.vx, vx, "frame \(frames): vx × 0.9")
        }
        XCTAssertEqual(frames, 4, "the burn: rows 2 → 3, 4, 5, then past the opaque bottom")
        XCTAssertEqual(w.player.cues.filter { $0.snd == 615 }.count, 0)
        XCTAssertEqual(w.player.cues.filter { $0.snd == Burn.sound }.count, 1, "the burn's sound once")
        XCTAssertEqual([s.dead, s.killedForGood], [true, true])
        XCTAssertEqual([w.globals.score, w.enemies.live, Int32(w.globals.achieved[0][2])], [500, 0, 1])
        // A hit is ignored while dying.
        let shot = try other(w, over: id)
        FrogSalamander.hitFrog(w, id: id, other: shot)
        XCTAssertFalse(try slot(w, shot).dead)

        // The dead water block (§0.1, §7.4): `.StandardSpriteHandles` zeroes `+0x11c` before the Handle tests it, so a
        // frog in lava (kind 2) is neither hurt nor buoyed; the frame's first gravity call uses the dry gravity.
        let lava = try world(waterRow: 15, liquid: 2)
        let (lid, _) = try enemy(lava, y: 520)
        let ls = TileSolver(world: lava)
        lava.active.update(id: lid) { $0.classTimer = -10000 }
        var inLava = false
        for _ in 0..<80 {
            frame(lava, lid, ls)
            if try slot(lava, lid).waterRow != 0 { inLava = true }
        }
        let l = try slot(lava, lid)
        XCTAssertTrue(inLava, "the frog stood in the lava")
        XCTAssertEqual([Int(l.hp), Int(l.invulnerable), Int(l.subtype)], [0x15e, 0, 0xb])
        // `.HitFrogTileSprite`'s liquid branch runs only while `+0x140 == 0` (l. 70634; `.HandleUnderWater` sets it, the
        // next `.StandardSpriteHandles` clears it): with it set, a lava cell leaves `+0x11c` alone.
        for done in [true, false] {
            lava.active.update(id: lid) { $0.waterRow = 0; $0.underwaterDone = done }
            FrogSalamander.hitFrogTile(ls, id: lid, pos: TilePos(x: 640, y: 16 * 32), kind: 202, layer: .background)
            XCTAssertEqual(try slot(lava, lid).waterRow != 0, !done, "`+0x140` \(done)")
        }
    }

    // MARK: - the Salamander

    func testSalamanderFireball() throws {
        // `.SetupSalamanderSprite` (M l. 70654–70703): HP 500, state 0xc, `+0x14c = −0x14 − R(0x1e)`, rect SetRect(0xe,
        // 0x14, 0x42, 0x49), gravity 0x8c, `+0x150 = −1`, `+0xa6 = 0`, the cache set 0x712 marked, no face, counted; no
        // other draw, no write-back flag.
        let w = try world(px: 450)
        var x = w.rng
        let (id, e) = try enemy(w, type: 0x712, x: 600, y: 500)
        let s0 = e.slot
        XCTAssertEqual(s0.classTimer, -0x14 - Int32(x.next(0x1e)))
        XCTAssertEqual(w.rng.seed, x.seed)
        XCTAssertEqual([Int(s0.hp), Int(s0.subtype), Int(s0.gravity), Int(s0.layer), Int(s0.counterA6)],
                       [500, 0xc, 0x8c, 0xb, 0])
        XCTAssertEqual(s0.classWord150, -1)
        XCTAssertEqual(s0.hotRect, rect(0xe, 0x14, 0x42, 0x49))
        XCTAssertEqual(s0.handler, .salamander)
        XCTAssertEqual([s0.hasHit, s0.hasTileHit, s0.countedInTotals], [true, true, true])
        XCTAssertEqual([s0.keepRecord, s0.noWriteBack189, s0.noWriteBack18a, s0.keepRecordAtKill, s0.killedForGood],
                       [false, false, false, false, false])
        XCTAssertEqual(s0.mode, 0)
        XCTAssertEqual(e.source, .handle)
        XCTAssertEqual(e.sheet, SetupFaces.Sheet(pict: 0x712, count: 9, cellWidth: 0x50, cellHeight: 100, columns: 9,
                                                 clut: 200))
        XCTAssertEqual(CachedFaces.marks(type: 0x712).sets, [0x712], "the Setup marks set 0x712 (M l. 70680)")
        XCTAssertEqual(w.enemies.live, 1)
        let solver = TileSolver(world: w)
        try settle(w, id, solver)
        let x0 = try slot(w, id).x
        // State 0xc (l. 70826–70846): `+0x14c + 1 ≥ 0` and |dx| < 250 → `+0x46 = 0`, face 1, state 10, vy = −0xc80 −
        // R(700). At the edges (l. 70833, l. 70838), from the settled Salamander restored each time:
        let rest = try slot(w, id)
        for (timer, dx, leaps) in [(Int32(-2), -100, false), (-1, -0xf9, true), (-1, -0xfa, false), (-1, 0xf9, true),
                                   (-1, 0xfa, false)] {
            w.active.update(id: id) { $0 = rest; $0.classTimer = timer }
            w.player.centreX = Int16(rest.centre.x + dx)
            frame(w, id, solver)
            XCTAssertEqual(try slot(w, id).subtype, leaps ? 10 : 0xc, "`+0x14c` \(timer) + 1, dx \(dx)")
        }
        w.active.update(id: id) { $0 = rest }
        w.player.centreX = 450
        x = w.rng
        let pre = try slot(w, id)
        frame(w, id, solver)
        var s = try slot(w, id)
        XCTAssertEqual([Int(s.subtype), Int(s.phase), s.face?.index ?? -1], [10, 0, 1])
        XCTAssertEqual(s.vy, -0xc80 - Int32(x.next(700)), "the leap, set after the frame's one gravity call")
        XCTAssertFalse(pre.mirrored)
        XCTAssertEqual(w.rng.seed, x.seed)
        // State 2 (l. 70738–70786): faces 3…8 by `+0x46 / 3`, the fireball at `+0x46 == 12`: `MTNewSprite(0x712, cx +
        // flip·0x3c − 0x2d, cy − 0x19, layer + 1, −1, .SetupEnemyShotSprite)`, vx ±2000. Set directly, standing.
        try settle(w, id, solver, timer: 0)
        w.active.update(id: id) { $0.subtype = 2; $0.phase = 0 }
        var faces: [Int] = []
        for _ in 0..<18 {
            let before = try slot(w, id)
            x = w.rng
            frame(w, id, solver)
            s = try slot(w, id)
            faces.append(s.face?.index ?? -1)
            if before.phase == 12 {
                let shots = enemyShots(w)
                XCTAssertEqual(shots.count, 1)
                let b = try XCTUnwrap(shots.first)
                let c = before.centre
                XCTAssertEqual(b.type, 0x712)
                XCTAssertEqual(b.oldPosition, SpriteSlot.Point(x: c.x - 0x2d, y: c.y - 0x19))
                XCTAssertEqual([b.vx, Int32(b.layer), Int32(b.hp), Int32(b.gravity)], [-2000, 0xc, 0, 0])
                XCTAssertEqual(b.phase, x.next(5))
            }
            XCTAssertEqual(w.rng.seed, x.seed)
        }
        XCTAssertEqual(faces, [3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 8])
        XCTAssertEqual(try slot(w, id).x, x0, "the Salamander never moves sideways")
        // k ≥ 6 (`+0x46` 18): R(10) < 7 → `+0x46 = 0` (then + 1), `+0x14c = −10 − R(10)` — the pause (face 0, `+0x46`
        // 0, `+0x14c + 1` a frame) then another fireball; else `+0x14c = −10 − R(10)`, state 0xb, face 1, vy = −0x708 −
        // R(600). The draw at its edge (l. 70770 `R(10) < 7`): 6 spits again, 7 hops.
        let again = seed { r in r.next(10) == 6 }
        let hop = seed { r in r.next(10) == 7 }
        for (sd, spits) in [(again, true), (hop, false)] {
            w.active.update(id: id) { $0.subtype = 2; $0.phase = 18; $0.classTimer = 0 }
            w.rng = FastRand(seed: sd)
            x = w.rng
            frame(w, id, solver)
            s = try slot(w, id)
            _ = x.next(10)
            let timer = -10 - Int32(x.next(10))
            if spits {
                XCTAssertEqual([Int(s.subtype), Int(s.phase), Int(s.classTimer)], [2, 1, Int(timer)])
                frame(w, id, solver)
                XCTAssertEqual([Int(try slot(w, id).phase), Int(try slot(w, id).classTimer),
                                try slot(w, id).face?.index ?? -1], [0, Int(timer) + 1, 0], "the pause")
            } else {
                let vy = -0x708 - Int32(x.next(600))
                XCTAssertEqual([Int(s.subtype), Int(s.classTimer), s.face?.index ?? -1], [0xb, Int(timer), 1])
                XCTAssertEqual(s.vy, vy)
                XCTAssertEqual(s.gravity, 0x15e, "grounded at the hop's tile hit: 350")
                frame(w, id, solver)
                XCTAssertEqual(try slot(w, id).gravity, 0xd2, "state 0xb: gravity 210 (then airborne, no tile hit)")
            }
            XCTAssertEqual(w.rng.seed, x.seed)
        }
        // Facing right (the player on the right: state 2 sets `+0x17e = c.x < P.x`, l. 70741): the fireball at c.x + 0x3c
        // − 0x2d (l. 70757), vx 2000.
        let r = try world(px: 1200)
        let (rid, _) = try enemy(r, type: 0x712, x: 600, y: 500)
        let rs = TileSolver(world: r)
        try settle(r, rid, rs, timer: 0)
        r.active.update(id: rid) { $0.subtype = 2; $0.phase = 12 }
        let rb = try slot(r, rid)
        frame(r, rid, rs)
        XCTAssertTrue(try slot(r, rid).mirrored)
        let fb = try XCTUnwrap(enemyShots(r).first)
        XCTAssertEqual(fb.oldPosition, SpriteSlot.Point(x: rb.centre.x + 0x3c - 0x2d, y: rb.centre.y - 0x19))
        XCTAssertEqual(fb.vx, 2000)
    }

    func testSalamanderWater() throws {
        // State 10's landing (M l. 70793–70812): `+0x11c` 0 or > 1 (dry or partly in liquid) → state 2; == 1 (fully
        // submerged) → state 0xc, `+0x14c = −0x14 − R(0x1e)`. The one gravity call a frame comes before the switch, so
        // the landing frame's `.HandleUnderWater` has set `+0x11c`.
        for (waterRow, deep) in [(Int?.none, false), (19, false), (10, true)] {
            let w = try world(px: 450, waterRow: waterRow)
            let (id, _) = try enemy(w, type: 0x712, x: 600, y: 500)
            let solver = TileSolver(world: w)
            try settle(w, id, solver)
            frame(w, id, solver)
            XCTAssertEqual(try slot(w, id).subtype, 10)
            var n = 0
            while try slot(w, id).subtype == 10 && n < 200 {
                var x = w.rng
                frame(w, id, solver)
                n += 1
                let s = try slot(w, id)
                guard s.subtype != 10 else {
                    XCTAssertEqual(s.gravity, 0xaa, "the leap's gravity (l. 70800)")
                    continue
                }
                XCTAssertEqual(s.face?.index, 0)
                if deep {
                    XCTAssertEqual(s.waterRow, 1)
                    XCTAssertEqual([Int(s.subtype), Int(s.classTimer)], [0xc, -0x14 - Int(x.next(0x1e))])
                } else {
                    XCTAssertNotEqual(s.waterRow, 1, "water row \(String(describing: waterRow))")
                    XCTAssertEqual(s.subtype, 2)
                }
                if waterRow == nil || deep { XCTAssertEqual(w.rng.seed, x.seed) }
            }
            XCTAssertNotEqual(try slot(w, id).subtype, 10)
        }
        // The landing's depth test reads `+0x11c` as stored (l. 70803 `== 0 || 1 < +0x11c`): depth 2 (the surface 2 px
        // below the sprite's top) lands like a dry one. The FG floor here only gives the landing depths 1, 9, 41 and 73,
        // so the state arm is called directly on a grounded state-10 record.
        for (depth, state) in [(Int32(0), Int16(2)), (1, 0xc), (2, 2)] {
            let w = try world(px: 450)
            let (id, _) = try enemy(w, type: 0x712)
            var s = try slot(w, id)
            s.subtype = 10
            s.groundKind = 1
            s.waterRow = depth
            FrogSalamander.salamanderState(w, id: id, &s)
            XCTAssertEqual([Int(s.subtype), s.face?.index ?? -1], [Int(state), 0], "depth \(depth)")
        }
        // The dead water block (§2.2, §7.4): lava (kind 2) costs nothing, standing in it fully submerged.
        let lava = try world(px: 1800, waterRow: 10, liquid: 2)
        let (lid, _) = try enemy(lava, type: 0x712, x: 600, y: 500)
        let ls = TileSolver(world: lava)
        lava.active.update(id: lid) { $0.classTimer = -10000 }
        for _ in 0..<80 { frame(lava, lid, ls) }
        let l = try slot(lava, lid)
        XCTAssertEqual(l.waterRow, 1, "fully submerged")
        XCTAssertEqual([Int(l.hp), Int(l.invulnerable)], [500, 0])
        // `.HitSalamanderTileSprite` (M l. 70939–70980): in state 0xb the solid BG (kind < 100) is passed through; in
        // any other state it is a floor. Grounded after a tile hit: gravity 350.
        for (state, stops) in [(Int16(0xb), false), (0xc, true)] {
            let w = try world(floorRow: nil, bgSolidRow: 20)
            let (id, _) = try enemy(w, type: 0x712, x: 600, y: 500)
            let solver = TileSolver(world: w)
            w.active.update(id: id) { $0.classTimer = -10000; $0.subtype = state }
            for _ in 0..<20 { frame(w, id, solver) }
            let s = try slot(w, id)
            if stops {
                XCTAssertTrue((20 * 32..<21 * 32).contains(s.y + s.hotRect.bottom), "standing on the solid BG row")
                XCTAssertEqual([Int(s.groundKind == 0 ? 0 : 1), Int(s.gravity), Int(s.subtype)], [1, 0x15e, 0xc])
            } else {
                XCTAssertGreaterThan(s.y + s.hotRect.top, 21 * 32, "fell through the solid BG row")
                XCTAssertEqual([Int(s.groundKind), Int(s.gravity), Int(s.subtype)], [0, 0xd2, 0xb])
            }
        }
    }

    func testSalamanderContactHazardArm() throws {
        // `.HitPlayerSprite` step 6 (`HitPlayerSprite.enemyHazard`, M l. 49514–49523): the Salamander's Handle → `.HurtPlayer
        // (0x70, no blood, 0x3c, R(100) < 0x51 ? 0 : 3)` — reached with the class's own Handle from its Setup.
        for coins in [false, true] {
            let w = try world()
            let pid = try XCTUnwrap(Player.spawn(world: w, x: 600, y: 500))
            w.active.update(id: pid) { $0.hp = 1000; $0.invulnerable = 0 }
            let p = try slot(w, pid)
            let (sid, _) = try enemy(w, type: 0x712, x: p.x, y: p.y)
            w.active.update(id: sid) { $0.x = p.x; $0.y = p.y; $0.hotRect = p.hotRect }
            w.globals.coins = 10
            let r = seed { r in (r.next(100) < 0x51) != coins }
            w.rng = FastRand(seed: r)
            HitPlayerSprite.hit(w, player: pid, other: sid)
            let q = try slot(w, pid)
            XCTAssertEqual([Int(q.hp), Int(q.invulnerable)], [1000 - 0x70, 0x3c])
            XCTAssertEqual(w.player.coinsLost, coins ? 3 : 0)
            XCTAssertEqual(blood(w), 0, "no blood")
        }
        // A dead Salamander (HP < 1) hurts not at all (`.HurtPlayer`'s attacker gate, M l. 47983–47985).
        let d = try world()
        let dp = try XCTUnwrap(Player.spawn(world: d, x: 600, y: 500))
        d.active.update(id: dp) { $0.hp = 1000; $0.invulnerable = 0 }
        let dps = try slot(d, dp)
        let (did, _) = try enemy(d, type: 0x712, x: dps.x, y: dps.y)
        d.active.update(id: did) { $0.x = dps.x; $0.y = dps.y; $0.hotRect = dps.hotRect; $0.hp = 0 }
        HitPlayerSprite.hit(d, player: dp, other: did)
        XCTAssertEqual(try slot(d, dp).hp, 1000)
        // The Frog's body: step 7's generic row (0x70, blood).
        let fw = try world()
        let fp = try XCTUnwrap(Player.spawn(world: fw, x: 600, y: 500))
        fw.active.update(id: fp) { $0.hp = 1000; $0.invulnerable = 0 }
        let fps = try slot(fw, fp)
        let (fid, _) = try enemy(fw, x: fps.x, y: fps.y)
        fw.active.update(id: fid) { $0.x = fps.x; $0.y = fps.y; $0.hotRect = fps.hotRect }
        HitPlayerSprite.hit(fw, player: fp, other: fid)
        XCTAssertEqual(try slot(fw, fp).hp, 1000 - 0x70)

        // The other way — `.HitSalamanderSprite` (M l. 70859–70911), through the session's hit dispatch (`+0x5c`): a
        // player shot → `.KillPlayerShot`; `.HurtSprite(o.+0xa4, o.vx >> 5, o.vy >> 3, 2, 8)`; on a hurt `+0xa6 < 2`
        // → 0x15 (write-only, §7.1), blood while alive, 702 below HP 201 else 701 (unpitched); no state-4 guard.
        let w = try world()
        let (id, _) = try enemy(w, type: 0x712)
        w.player.cues = []
        let shot = try other(w, over: id, damage: 150, vx: 1000, vy: -200)
        FerazelSession.hitCallback(w, id, shot)
        var s = try slot(w, id)
        XCTAssertTrue(try slot(w, shot).dead)
        XCTAssertEqual([Int(s.hp), Int(s.invulnerable), Int(s.flash), Int(s.counterA6)], [350, 2, 8, 0x15])
        XCTAssertEqual([s.vx, s.vy], [Int32(1000 >> 5), Int32(-200 >> 3)])
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeD, snd: 701, priority: 1, volume: 0x100, position: s.centre)])
        XCTAssertEqual(blood(w), 0x28)
        // HP exactly 1 lives on through a frame (l. 70847 `+0xa4 < 1`); HP 0 → state 4, `+0x46 = 0`, no sound.
        let ss = TileSolver(world: w)
        for (hp, dies) in [(Int16(1), false), (0, true)] {
            w.active.update(id: id) { $0.hp = hp; $0.phase = 7; $0.subtype = 0xc; $0.classTimer = -500 }
            w.player.cues = []
            FrogSalamander.handleSalamander(world: w, id: id, solver: ss)
            let t = try slot(w, id)
            XCTAssertEqual([Int(t.subtype), Int(t.phase)], dies ? [4, 0] : [0xc, 7], "HP \(hp)")
            XCTAssertEqual(w.player.cues, [])
        }
        w.active.update(id: id) { $0.hp = 350 }
        // Dying (state 4) and hit again: hurt all the same; HP 150 → 702; `+0xa6` already ≥ 2 stays.
        w.active.update(id: id) { $0.subtype = 4; $0.invulnerable = 0; $0.counterA6 = 5 }
        w.player.cues = []
        let second = try other(w, over: id, damage: 200)
        FerazelSession.hitCallback(w, id, second)
        s = try slot(w, id)
        XCTAssertEqual([Int(s.hp), Int(s.counterA6)], [150, 5])
        XCTAssertEqual(w.player.cues.map(\.snd), [702])
        // No Smiting-explosion arm: an Effect 0x4b7 at `+0x46 < 8` does nothing.
        w.active.update(id: id) { $0.invulnerable = 0 }
        let blast = try other(w, over: id, type: 0x4b7, handler: .effect) { $0.phase = 0 }
        FerazelSession.hitCallback(w, id, blast)
        XCTAssertEqual(try slot(w, id).hp, 150)
        // At the edge (l. 70889 `+0xa4 < 0xc9`): HP 200 after the hit → 702, 201 → 701.
        for (hp, snd) in [(Int16(350), Int16(702)), (351, 701)] {
            let e = try world()
            let (eid, _) = try enemy(e, type: 0x712)
            e.active.update(id: eid) { $0.hp = hp }
            e.player.cues = []
            FerazelSession.hitCallback(e, eid, try other(e, over: eid, damage: 150))
            XCTAssertEqual(e.player.cues.map(\.snd), [snd], "HP \(hp - 150)")
        }
        // The Statue spell: `.TurnIntoStatue`. The Kill proc `.KillSalamander` (M l. 70913–70937): the count; score
        // + 400 only while `+0xe9 == 0`; `+0xe9 = +0xea = 1`.
        let u = try world()
        let (uid, _) = try enemy(u, type: 0x712)
        u.globals.score = 0
        EnemyCommon.killProc(u, id: uid)
        XCTAssertEqual([u.globals.score, u.enemies.live, Int32(u.globals.achieved[0][2])], [400, 0, 1])
        XCTAssertEqual([try slot(u, uid).dead, try slot(u, uid).killedForGood], [true, true])
        EnemyCommon.killProc(u, id: uid)
        XCTAssertEqual(u.globals.score, 400, "a second Kill scores nothing")
        let (tid, _) = try enemy(u, type: 0x712)
        let ice = try other(u, over: tid, type: 1)
        FerazelSession.hitCallback(u, tid, ice)
        XCTAssertEqual(try slot(u, tid).handler, .statue)
    }
}
