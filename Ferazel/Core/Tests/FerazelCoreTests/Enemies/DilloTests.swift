import XCTest
@testable import FerazelCore

/// DL (docs/plans/2026-10-30-ferazel-phase5.md): the Dillo — `.InitDilloSprite` (M l. 72276–72288),
/// `.SetupDilloSprite` (M l. 72291–72378), `.ShootSpines` (M l. 72381–72470), `.DilloLayEgg` (M l. 72473–72485),
/// `.RandomDilloAttack` (M l. 72488–72537), `.HandleDilloSprite` (M l. 72540–72847), `.HitDilloSprite` (M l.
/// 72850–72913), `.KillDillo` (M l. 72916–72937). The Dillo is placed only on levels 15 and 22: every placement here is
/// made by hand over level 3's header and a synthetic 60×30 grid (FG floor along row 20 unless a test says otherwise).
/// Every expected draw is re-derived from a copy of the stream.
final class DilloTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    nonisolated(unsafe) private static let level3 = Result {
        try LevelFile.load(from: try FerazelData.open(try FerazelData.dataDirectory()), level: 3)
    }

    /// The grid: FG kind 3 along `floorRow`; BG liquid 200 + `liquid` from `waterRow` down; the player's centre globals at
    /// (`px`, `py`).
    private func world(px: Int16 = 1800, py: Int16 = 300, floorRow: Int? = 20, waterRow: Int? = nil,
                       liquid: Int = 0) throws -> SpriteWorld {
        let w = SpriteWorld(level: try Self.level3.get())
        var fg = [UInt16](repeating: 0, count: 60 * 30), bg = fg
        if let r = floorRow { for c in 0..<60 { fg[r * 60 + c] = 4 } }
        if let r = waterRow { for row in r..<30 { for c in 0..<60 { bg[row * 60 + c] = 1 } } }
        var bgKinds = [Int](repeating: 0, count: 0x60)
        bgKinds[0] = 200 + liquid                       // BG cell 1 = tile 0 (cell 0 = no tile)
        w.tiles = TileGrid(fg: TileMap(width: 60, height: 30, cells: fg), bg: TileMap(width: 60, height: 30, cells: bg),
                           fgKinds: Array(0..<0x60), bgKinds: bgKinds)
        w.player.centreX = px
        w.player.centreY = py
        w.levelIndex = 3
        return w
    }

    /// A Dillo placement (record 0) set up by `SetupFaces` inside the counting window, its centre set as a previous
    /// Cleanup leaves it. Standing on the row-20 floor at y 582 (hot-rect bottom 0x3a).
    private func dillo(_ w: SpriteWorld, type: Int16 = Dillo.walkType, x: Int = 600, y: Int = 582, p1: Int16 = 0,
                       p2: Int16 = 0, window: Bool = true) throws -> (id: Int, entry: SetupFaces.Entry) {
        let p = Placement(index: 0, flag: 1, byte1: 0, type: type, p1: p1, p2: p2, p3: 0, p4: 0, y: Int16(y), x: Int16(x))
        w.records = [p]
        let c = SetupFaces.Context(level: w.level, playerX: Int(w.player.centreX), records: w.records)
        var lights = LightTable()
        w.enemies.window = window
        let e = try SetupFaces.setup(p, context: c, lights: &lights, counting: &w.enemies, rng: &w.rng)
        w.enemies.window = false
        w.records = [e.record]
        var s = e.slot
        let r = s.hotRect
        s.centre = SpriteSlot.Point(x: s.x + r.left + ((r.right - r.left) >> 1), y: s.y + r.top + ((r.bottom - r.top) >> 1))
        return (w.active.insert(s), e)
    }

    private func slot(_ w: SpriteWorld, _ id: Int) throws -> SpriteSlot { try XCTUnwrap(w.active.record(id: id)) }

    /// One Dillo Handle call by `+0x4c` (the session's form of the dispatch row).
    private func frame(_ w: SpriteWorld, _ id: Int) {
        Dillo.handle(world: w, id: id, solver: TileSolver(world: w))
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

    /// A sprite of `type` / `handler` with a 20×20 hot rect whose centre is the Dillo's moved by `dx` (a player shot by
    /// default).
    private func other(_ w: SpriteWorld, over id: Int, dx: Int = 0, type: Int16 = 2, handler: SpriteHandler = .playerShot,
                       damage: Int16 = 150, vx: Int32 = 1000, vy: Int32 = -200,
                       body: (inout SpriteSlot) -> Void = { _ in }) throws -> Int {
        let t = try slot(w, id)
        let c = SpriteSlot.Point(x: t.centre.x + dx, y: t.centre.y)
        return try XCTUnwrap(w.newSprite(type: type, x: c.x - 10, y: c.y - 10, layer: 0xb, handler: handler) { s in
            s.x = c.x - 10
            s.y = c.y - 10
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 20, right: 20)
            s.centre = c
            s.hp = damage
            s.vx = vx
            s.vy = vy
            body(&s)
        })
    }

    private func shots(_ w: SpriteWorld, _ type: Int16) -> [SpriteSlot] {
        w.active.sprites.filter { $0.handler == .enemyShot && $0.type == type }
    }

    private func blood(_ w: SpriteWorld) -> Int { w.particles.records.filter { $0.alive && $0.kind == 2 }.count }

    // MARK: -

    func testDilloSetup() throws {
        // `.SetupDilloSprite` (M l. 72291–72378): layer 8, gravity 0x122, HP 1870 → 500, 1871 → 1100 with `+0xb8 =
        // 0x1000b`; `+0x168` = HP; `+0x188 = 1`; rect SetRect(0x1a, 0x17, 0x4a, 0x3a); `+0x150 = −1`; state 6, `+0xb2 = 0`,
        // `+0x46 = 2`, `+0x14c = 0`; `+0xa6 = R(10)`; the live record's p2 0 → 150 written back; bounds `x ∓ p2 >> 1`;
        // `+0x164 = 0`; flip = R(100) ≥ 51 (the signed-compare idiom); the counting window; the 24.8 position.
        for (type, hp, mode, p2, half) in [(Dillo.walkType, Int16(500), UInt32(0), Int16(0), 75),
                                           (Dillo.curlType, 1100, 0x1000b, 201, 100)] {
            for want in [Int16(50), 51] {
                let w = try world()
                w.rng = FastRand(seed: seed { r in _ = r.next(10); return r.next(100) == want })
                var x = w.rng
                let a6 = x.next(10)
                _ = x.next(100)
                let (id, e) = try dillo(w, type: type, p2: p2)
                XCTAssertEqual(w.rng.seed, x.seed, "two draws: R(10), then R(100)")
                let s = try slot(w, id)
                let tag = "type \(type) R \(want)"
                XCTAssertEqual([Int(s.layer), Int(s.gravity), Int(s.hp), Int(s.bonusP4)], [8, 0x122, Int(hp), Int(hp)], tag)
                XCTAssertEqual(s.mode, mode, tag)
                XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 0x17, left: 0x1a, bottom: 0x3a, right: 0x4a))
                XCTAssertEqual([Int(s.classWord150), Int(s.subtype), Int(s.subState), Int(s.phase), Int(s.classTimer)],
                               [-1, 6, 0, 2, 0], tag)
                XCTAssertEqual([Int(s.counterA6), Int(s.launchSpeed)], [Int(a6), 0], tag)
                XCTAssertEqual([Int(s.classWord15c), Int(s.classWord160)], [600 - half, 600 + half], tag)
                XCTAssertEqual(s.mirrored, want == 51, "\(tag): R(100) > 50 → facing right")
                XCTAssertEqual(e.record.p2, p2 == 0 ? 150 : p2, "\(tag): p2 0 → 150 written back")
                XCTAssertEqual([s.handler == .dillo, s.hasHit, s.hasTileHit, s.countedInTotals],
                               [true, true, true, true], tag)
                // The write-back flags: `+0x188 = 1` (M l. 72343); none of `+0x189`…`+0x18b`, no `+0xea`.
                XCTAssertEqual([s.keepRecord, s.noWriteBack189, s.noWriteBack18a, s.keepRecordAtKill, s.killedForGood],
                               [true, false, false, false, false], tag)
                XCTAssertEqual([s.x, s.y, Int(s.x256 >> 8), Int(s.y256 >> 8)], [600, 582, 600, 582])
                XCTAssertEqual([Int(s.particleOffsetX), Int(s.particleOffsetY)], [0, 0])
                XCTAssertEqual(s.face, f(Dillo.walkType, 0))
                XCTAssertEqual(e.source, .handle)
                XCTAssertEqual(e.sheet, SetupFaces.Sheet(pict: 0x74e, count: 6, cellWidth: 100, cellHeight: 0x50,
                                                         columns: 6, clut: 200))
                XCTAssertEqual(w.enemies.live, 1)
            }
        }
        // Outside the window: not counted.
        let n = try world()
        let (nid, _) = try dillo(n, window: false)
        XCTAssertEqual([try slot(n, nid).countedInTotals ? 1 : 0, Int(n.enemies.live)], [0, 0])
        // 1872…1879: HP 0, max 0 — the original always dies on frame 1 (the HP < 1 test, M l. 72819, follows the state
        // switch); the idle decision divides by the max 0 (plain `divw`, raw 10086a48: undefined, no trap) only when the
        // R(10) timer starts at 0 or 1. Refused: a named ◇ for an unplaced variant (bank §8, the Wraith-variant precedent).
        for t: Int16 in [0x750, 0x757] {
            XCTAssertThrowsError(try dillo(try world(), type: t), "type \(t)")
        }
        // The faces (`.InitDilloSprite`, M l. 72283–72286): four cache sets, 100×80 cells, one row each; the Setup marks
        // all four (M l. 72330–72333).
        XCTAssertEqual(CachedFaces.marks(type: 0x74e).sets, [0x74e, 0x74f, 0x750, 0x751])
        XCTAssertEqual(CachedFaces.marks(type: 0x74f).sets, [0x74e, 0x74f, 0x750, 0x751])
        for (p, cells) in [(Int16(0x74e), 6), (0x74f, 5), (0x750, 5), (0x751, 2)] {
            XCTAssertEqual(SetupFaces.sheet(pict: p),
                           SetupFaces.Sheet(pict: p, count: cells, cellWidth: 100, cellHeight: 0x50, columns: cells,
                                            clut: 200))
        }
        XCTAssertEqual([SpriteHandler.forClass(type: 0x74e), SpriteHandler.forClass(type: 0x74f)], [.dillo, .dillo])
        // The session's Handle dispatch by `+0x4c`: a Dillo near the player, kept active, runs its idle state.
        let sess = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 3, seed: 1)
        let sw = sess.world
        let me = try slot(sw, try XCTUnwrap(sw.playerID))
        let p = Placement(index: 0, flag: 1, byte1: 0, type: 0x74e, p1: 0, p2: 100, p3: 0, p4: 0,
                          y: Int16(me.y - 150), x: Int16(me.x + 150))
        var ns = SpriteSlot(type: 0x74e, x: Int(p.x), y: Int(p.y), recordIndex: -1)
        ns.oldPosition = SpriteSlot.Point(x: ns.x, y: ns.y)
        var none = EnemyCounting()
        _ = Dillo.setup(&ns, record: p, rng: &sw.rng, counting: &none)
        ns.mayIdle = false
        ns.counterA6 = 5
        ns.vx = 1000
        let nd = sw.active.insert(ns)
        _ = sess.step(keys: KeyState())
        let sd = try slot(sw, nd)
        XCTAssertEqual([Int(sd.counterA6), Int(sd.subtype)], [4, 6], "the Dillo Handle ran")
        XCTAssertEqual(sd.face, f(0x74e, 0))
        XCTAssertEqual(sd.vx, 500, "state 6: vx 1000 × 0.5 (M l. 72607–72608)")
        // The idle halving is `(int)(vx · 0.5)` (f64, `fctiwz`): toward zero either side, no decision draw at `+0xa6` 5.
        for (vx0, vx1) in [(Int32(1001), Int32(500)), (-1001, -500), (1, 0), (-1, 0)] {
            let h = try world()
            let (hid, _) = try dillo(h)
            h.active.update(id: hid) { s in s.counterA6 = 5; s.vx = vx0 }
            let seed0 = h.rng.seed
            frame(h, hid)
            XCTAssertEqual([try slot(h, hid).vx, Int32(h.rng.seed == seed0 ? 1 : 0)], [vx1, 1], "idle vx \(vx0)")
        }
    }

    func testDilloSpines5And7() throws {
        // State 8 (M l. 72626–72768): vx × 0.5 each frame. `+0xb2` 0, the curl: face 0x74f[`+0x46 >> 1`], `+0x46` + 1; past
        // 8 → `+0x46 = 9`, `+0xb2 = 1`, `+0x14c` + 1.
        let c = try world()
        let (cid, _) = try dillo(c)
        c.active.update(id: cid) { s in
            s.subtype = 8
            s.subState = 0
            s.phase = 0
            s.classTimer = 1
            s.counterA6 = 16
            s.vx = 1001
        }
        var curl: [Int] = []
        for k in 0..<9 {
            frame(c, cid)
            let s = try slot(c, cid)
            curl.append(s.face?.index ?? -1)
            XCTAssertEqual(s.face?.pict, Dillo.curlType)
            if k == 0 { XCTAssertEqual(s.vx, 500, "1001 × 0.5, truncated") }
            XCTAssertEqual([Int(s.subState), Int(s.classTimer)], k < 8 ? [0, 1] : [1, 2], "curl frame \(k)")
        }
        XCTAssertEqual(curl, [0, 0, 1, 1, 2, 2, 3, 3, 4], "phases 0…8; the 9th frame (phase 8 → 9) sets `+0xb2 = 1`")
        XCTAssertEqual(try slot(c, cid).phase, 9)
        // `+0xb2` 1: face 0x74f[4] only while `+0xa6 < 16` (16 keeps the curl face).
        frame(c, cid)
        var s = try slot(c, cid)
        XCTAssertEqual([Int(s.counterA6), s.face?.index ?? -1], [15, 4], "a6 16: face kept (index 4 from the curl)")
        c.active.update(id: cid) { $0.face = FaceRef(pict: Dillo.curlType, index: 0, set: .encoded) }
        frame(c, cid)
        XCTAssertEqual([Int(try slot(c, cid).counterA6), try slot(c, cid).face?.index ?? -1], [14, 4], "a6 15 < 16")
        c.active.update(id: cid) { $0.face = FaceRef(pict: Dillo.curlType, index: 0, set: .encoded); $0.counterA6 = 16 }
        frame(c, cid)
        XCTAssertEqual(try slot(c, cid).face?.index, 0, "a6 16: not < 16")

        // The 5-spine volley: mode 0 (`+0x154`), `+0xa6` 1 → 0 with `+0x14c > 1`: face 0x74f[3], `+0xa6 = 16`,
        // `.ShootSpines(S, 0)`; then `+0x14c` − 1. The table (M l. 72400–72469): snd 463 (3D, 1, 0x100, S centre);
        // MTNewSprite(0x754, c + offset, layer 0, −1, .SetupEnemyShotSprite) ×5 — each Setup draws R(5) for `+0x46`, then
        // overwritten; v 0x900 / 0xbb3, d = (int)(0.7·v) = 1612 / 2096, `+0xa4` 0x38 / 0xe0, `+0xb8` 0 / 0x1000b.
        for (type, v, d, dmg, mode) in [(Dillo.walkType, Int32(0x900), Int32(1612), Int16(0x38), UInt32(0)),
                                        (Dillo.curlType, 0xbb3, 2096, 0xe0, 0x1000b)] {
            for timer in [Int32(2), 3] {
                let w = try world()
                let (id, _) = try dillo(w, type: type)
                w.active.update(id: id) { s in
                    s.subtype = 8
                    s.subState = 1
                    s.counterA6 = 1
                    s.classTimer = timer
                    s.classWord154 = 0
                    s.vx = 0
                }
                let before = try slot(w, id)
                w.player.cues = []
                var x = w.rng
                frame(w, id)
                for _ in 0..<5 { _ = x.next(5) }
                XCTAssertEqual(w.rng.seed, x.seed, "five spawn draws, nothing else")
                s = try slot(w, id)
                XCTAssertEqual([s.face?.index ?? -1, Int(s.counterA6), Int(s.classTimer), Int(s.subState)],
                               [3, 16, Int(timer) - 1, 1], "type \(type) timer \(timer)")
                XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeD, snd: 463, priority: 1, volume: 0x100,
                                                         position: before.centre)])
                let cx = before.centre.x, cy = before.centre.y
                let sp = shots(w, 0x754)
                XCTAssertEqual(sp.map { [$0.x, $0.y] }, [[cx - 10, cy - 8], [cx + 10, cy - 8], [cx - 7, cy - 15],
                                                          [cx + 7, cy - 15], [cx, cy - 18]], "spawn order")
                XCTAssertEqual(sp.map { [$0.vx, $0.vy] }, [[-v, 0], [v, 0], [-d, -d], [d, -d], [0, -v]])
                XCTAssertEqual(sp.map { Int($0.phase) }, [0, 4, 1, 3, 2])
                XCTAssertEqual(Set(sp.map(\.hp)), [dmg])
                XCTAssertEqual(Set(sp.map(\.mode)), [mode])
                XCTAssertEqual(Set(sp.map { Int($0.layer) }), [0xc], "the spine Setup's layer")
                // 16 frames on, the second volley only while `+0x14c` was 3 (`+0x14c > 1` at the time); then `+0xb2 = 2`.
                w.player.cues = []
                for _ in 0..<16 { frame(w, id) }
                s = try slot(w, id)
                XCTAssertEqual(shots(w, 0x754).count, timer == 3 ? 10 : 5, "timer \(timer)")
                XCTAssertEqual(Int(s.subState), timer == 3 ? 1 : 2)
                XCTAssertEqual(Int(s.classTimer), timer == 3 ? 1 : 0)
            }
        }
        // `+0xa6` 2 → 1: no volley yet (`< 1`); `+0x14c` 1 at 0: no volley, `+0x14c` 0 → uncurl.
        let q = try world()
        let (qid, _) = try dillo(q)
        q.active.update(id: qid) { s in s.subtype = 8; s.subState = 1; s.counterA6 = 2; s.classTimer = 2; s.classWord154 = 0 }
        frame(q, qid)
        XCTAssertEqual([shots(q, 0x754).count, Int(try slot(q, qid).classTimer)], [0, 2])
        q.active.update(id: qid) { s in s.counterA6 = 1; s.classTimer = 1 }
        frame(q, qid)
        XCTAssertEqual([shots(q, 0x754).count, Int(try slot(q, qid).classTimer), Int(try slot(q, qid).subState)],
                       [0, 0, 2])

        // The jump, mode 1 (M l. 72705–72714): `+0xa6 = 16`, face 0x751[1], `+0xb2 = 3`, vy −0xed8, `+0xce = 0`, R(4000),
        // snd 414 pitched (prio 0x14, vol 0xab, 75000 + R).
        let j = try world(floorRow: nil)
        let (jid, _) = try dillo(j)
        j.active.update(id: jid) { s in
            s.subtype = 8; s.subState = 1; s.counterA6 = 1; s.classTimer = 2; s.classWord154 = 1; s.vy = 0
        }
        let jb = try slot(j, jid)
        j.player.cues = []
        var jx = j.rng
        frame(j, jid)
        let pitch = Int32(jx.next(4000)) + 75000
        XCTAssertEqual(j.rng.seed, jx.seed)
        s = try slot(j, jid)
        XCTAssertEqual(j.player.cues, [PlayerCue(call: .threeDPitched, snd: 414, priority: 0x14, volume: 0xab,
                                                 position: jb.centre, rate: pitch)])
        XCTAssertEqual([s.face?.pict ?? 0, Int16(s.face?.index ?? -1), s.subState, s.counterA6],
                       [Dillo.jumpType, 1, 3, 16])
        XCTAssertEqual([s.vy, Int32(s.classTimer)], [-0xed8 + 0x122, 1], "vy −3800 + one gravity; `+0x14c` 1")

        // The 7-spine apex volley (`+0xb2` 3, M l. 72751–72767): face 0x751[1] rising / [0] falling; vy < 0 ≤ vy + 0x122 →
        // face 0x751[1] and `.ShootSpines(S, 1)`: the five, then (−7, −15) (−d, +d) `+0x46` 7 and (+7, −15) (+d, +d) 5.
        for (vy0, fires) in [(Int32(-0x122), true), (-0x123, false), (0, false), (-1, true)] {
            let a = try world(floorRow: nil)
            let (aid, _) = try dillo(a, type: Dillo.curlType)
            a.active.update(id: aid) { s in s.subtype = 8; s.subState = 3; s.vy = vy0; s.vx = 0 }
            let ab = try slot(a, aid)
            a.player.cues = []
            frame(a, aid)
            let t = try slot(a, aid)
            let sp = shots(a, 0x754)
            XCTAssertEqual(sp.count, fires ? 7 : 0, "vy \(vy0)")
            XCTAssertEqual(t.face, f(Dillo.jumpType, vy0 < 0 ? 1 : 0), "vy \(vy0)")
            XCTAssertEqual(t.subState, 3, "airborne")
            guard fires else { continue }
            let cx = ab.centre.x, cy = ab.centre.y
            XCTAssertEqual(sp.suffix(2).map { [$0.x, $0.y, Int($0.vx), Int($0.vy), Int($0.phase)] },
                           [[cx - 7, cy - 15, -2096, 2096, 7], [cx + 7, cy - 15, 2096, 2096, 5]])
            XCTAssertEqual(Set(sp.map(\.hp)), [0xe0])
            XCTAssertEqual(Set(sp.map(\.mode)), [0x1000b])
            XCTAssertEqual(a.player.cues.first, PlayerCue(call: .threeD, snd: 463, priority: 1, volume: 0x100,
                                                          position: ab.centre))
        }
        // Landing (`+0xce ≠ 0`) → `+0xb2 = 1`.
        let l = try world()
        let (lid, _) = try dillo(l)
        for _ in 0..<5 { frame(l, lid) }
        l.active.update(id: lid) { s in s.subtype = 8; s.subState = 3; s.vy = 300 }
        frame(l, lid)
        XCTAssertNotEqual(try slot(l, lid).groundKind, 0)
        frame(l, lid)
        XCTAssertEqual(try slot(l, lid).subState, 1, "landed")

        // The uncurl (`+0xb2` 2, M l. 72627–72646): face 0x74f[`+0x46 >> 1`], `+0x46` − 1, `+0x164` and `+0x1aa` 0; below 0 →
        // state 6, `+0xa6 = 12 + R(30)`, or with `+0x14c == 2` `6 + R(12)`.
        for timer in [Int32(0), 2] {
            let u = try world()
            let (uid, _) = try dillo(u)
            u.active.update(id: uid) { s in
                s.subtype = 8; s.subState = 2; s.phase = 1; s.classTimer = timer; s.launchSpeed = 15; s.rotation = 90
            }
            frame(u, uid)
            var t = try slot(u, uid)
            XCTAssertEqual([t.face?.index ?? -1, Int(t.phase), Int(t.launchSpeed), Int(t.rotation), Int(t.subtype)],
                           [0, 0, 0, 0, 8])
            var ux = u.rng
            frame(u, uid)
            let a6 = timer == 2 ? 6 + ux.next(12) : 12 + ux.next(30)
            XCTAssertEqual(u.rng.seed, ux.seed)
            t = try slot(u, uid)
            XCTAssertEqual([Int(t.subtype), Int(t.phase), Int(t.counterA6)], [6, -1, Int(a6)], "timer \(timer)")
        }
    }

    func testDilloEggBomb() throws {
        // Mode 2 (M l. 72663–72698): R(4000), snd 498 pitched (prio 0x14, vol 0x100, 63000 + R); face 0x74f[3], `+0xa6 =
        // 16`, `+0x14c = 0`; MTNewSprite(0x753, x, cy − 8, layer 0, −1, .SetupEnemyShotSprite) — x = S.x + face.right −
        // 0x17 facing left, S.x + face.left + 5 facing right, the face the one shown (0x74f[4], `+0xa6` < 16) —; layer S − 1;
        // vx +0x200 facing left / −0x200 right; vy −800; `+0xa4` 0xe0 (1870) / 0x1c0 + `+0xb8 0x1000b` (1871). Then
        // `+0x14c` − 1 → −1 → `+0xb2 = 2`.
        for (type, right) in [(Dillo.walkType, false), (Dillo.walkType, true), (Dillo.curlType, false)] {
            let w = try world()
            let (id, _) = try dillo(w, type: type)
            w.active.update(id: id) { s in
                s.subtype = 8; s.subState = 1; s.counterA6 = 1; s.classTimer = 2; s.classWord154 = 2; s.mirrored = right
                s.vx = 0
            }
            let before = try slot(w, id)
            w.player.cues = []
            var x = w.rng
            frame(w, id)
            let pitch = Int32(x.next(4000)) + 63000
            _ = x.next(5)                                   // the egg Setup's `+0x46` draw
            let flip = x.next(100)                          // its `+0x17e` draw
            XCTAssertEqual(w.rng.seed, x.seed, "R(4000), then the egg Setup's two")
            let s = try slot(w, id)
            let tag = "type \(type) right \(right)"
            XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDPitched, snd: 498, priority: 0x14, volume: 0x100,
                                                     position: before.centre, rate: pitch)], tag)
            XCTAssertEqual([s.face?.index ?? -1, Int(s.counterA6), Int(s.classTimer), Int(s.subState)], [3, 16, -1, 2],
                           tag)
            let egg = try XCTUnwrap(shots(w, 0x753).first, tag)
            XCTAssertEqual([egg.x, egg.y, Int(egg.layer)],
                           [before.x + (right ? 0 + 5 : 100 - 0x17), before.centre.y - 8, 7], tag)
            XCTAssertEqual([egg.vx, egg.vy], [right ? -0x200 : 0x200, -800], tag)
            XCTAssertEqual([Int(egg.hp), Int(egg.mode)], type == Dillo.walkType ? [0xe0, 0] : [0x1c0, 0x1000b], tag)
            XCTAssertEqual(egg.mirrored, 0x32 < flip, "the egg Setup's own flip")
        }

        // `.RandomDilloAttack` (M l. 72488–72537): R(100) first; state 8, `+0x46 = +0xb2 = 0`; r ≥ 76 with the live record's
        // p1 ≠ 0 → roll (mode 3): flip = P.x > c.x (signed), `+0x14c` 1 (bounds width < 150) or 2, + 1 facing right;
        // else r < 36 → spines (mode 0, `+0xa6 = 16`), 36…50 → `.DilloLayEgg` (mode 2, `+0xa6 = 5`), ≥ 51 → jump
        // (mode 1, `+0xa6 = 16`); modes 0–2 `+0x14c = 1 + R(2)`.
        for (r, p1, wantMode) in [(Int16(35), Int16(0), Int32(0)), (36, 0, 2), (50, 0, 2), (51, 0, 1), (75, 1, 1),
                                  (76, 0, 1), (99, 0, 1), (76, 1, 3), (99, -1, 3)] {
            let w = try world(px: 700)
            let (id, _) = try dillo(w, p1: p1, p2: 200)
            w.active.update(id: id) { s in s.phase = 7; s.subState = 3; s.subtype = 6 }
            w.rng = FastRand(seed: seed { g in g.next(100) == r })
            var x = w.rng
            var s = try slot(w, id)
            Dillo.randomAttack(w, &s)
            _ = x.next(100)
            let tag = "r \(r) p1 \(p1)"
            XCTAssertEqual([Int(s.subtype), Int(s.phase), Int(s.subState), Int(s.classWord154)],
                           [8, 0, 0, Int(wantMode)], tag)
            if wantMode == 3 {
                XCTAssertTrue(s.mirrored, "\(tag): player right of the centre")
                XCTAssertEqual(s.classTimer, 3, "\(tag): width 200 → 2, + 1 facing right")
            } else {
                let timer = Int32(x.next(2)) + 1
                XCTAssertEqual([s.classTimer, Int32(s.counterA6)], [timer, wantMode == 2 ? 5 : 16], tag)
            }
            XCTAssertEqual(w.rng.seed, x.seed, tag)
        }
        // The roll's `+0x14c` by width (149 → 1, 150 → 2) and facing (P.x == c.x → left, no + 1).
        for (width, px, timer, right) in [(149, 9000, Int32(2), true), (150, 9000, 3, true), (150, -1, 2, false),
                                          (149, nil, 1, false)] as [(Int, Int?, Int32, Bool)] {
            let w = try world()
            let (id, _) = try dillo(w, p1: 1)
            var s = try slot(w, id)
            w.player.centreX = Int16(px ?? s.centre.x)
            s.classWord15c = 500
            s.classWord160 = Int32(500 + width)
            w.rng = FastRand(seed: seed { g in g.next(100) == 80 })
            Dillo.randomAttack(w, &s)
            XCTAssertEqual([Int(s.classTimer), s.mirrored ? 1 : 0, Int(s.classWord154)], [Int(timer), right ? 1 : 0, 3],
                           "width \(width) px \(String(describing: px))")
        }
        // A roll frame (mode 3, M l. 72714–72745): `+0x164 = 15`, vx = ±(int)(150.796447·15) = ±2261; the spin
        // `+0x1aa` ± 15 a frame — a frame that does not complete a turn adds 1 back to `+0x14c` (net 0), a turn
        // (wrapping 360 / below 0) lets the − 1 through.
        for (right, angle, wantAngle, net) in [(false, Int16(0), Int16(15), Int32(0)), (false, 345, 0, -1),
                                               (false, 344, 359, 0), (true, 0, 345, -1), (true, 15, 0, 0),
                                               (true, 14, 359, -1)] {
            let w = try world()
            let (id, _) = try dillo(w, p1: 1)
            w.active.update(id: id) { s in
                s.subtype = 8; s.subState = 1; s.counterA6 = 0; s.classTimer = 3; s.classWord154 = 3; s.mirrored = right
                s.rotation = angle; s.vx = 0
            }
            frame(w, id)
            let s = try slot(w, id)
            let tag = "right \(right) angle \(angle)"
            XCTAssertEqual([Int(s.launchSpeed), Int(s.rotation), Int(s.classTimer)], [15, Int(wantAngle), 3 + Int(net)],
                           tag)
            XCTAssertEqual(abs(Int(s.vx)) <= 2261, true, tag)
        }
        let rv = try world(floorRow: nil)
        let (rid, _) = try dillo(rv, p1: 1)
        rv.active.update(id: rid) { s in
            s.subtype = 8; s.subState = 1; s.counterA6 = 0; s.classTimer = 3; s.classWord154 = 3; s.mirrored = false
            s.vx = 0
        }
        let r0 = try slot(rv, rid)
        frame(rv, rid)
        XCTAssertEqual(try slot(rv, rid).x256 - r0.x256, -2261, "in the air: one move by vx = −2261")

        // `.DilloLayEgg` from the idle decision (M l. 72585–72594): a slow walk (R(100) ≤ 100 − t) with R(100) > 80 →
        // `+0x154 = 2`, `+0xa6 = 5`, `+0x14c = 1 + R(2)` — the walk runs fast for 5 cycles. R(100) 80 → no egg.
        for (r3, egg) in [(Int16(81), true), (80, false)] {
            let w = try world()
            let (id, _) = try dillo(w)
            w.active.update(id: id) { s in s.counterA6 = 1 }
            w.rng = FastRand(seed: seed { g in
                let r = g.next(100), t = g.next(16) - 8
                guard t < r else { return false }
                _ = g.next(3)
                guard g.next(100) <= 100 - t else { return false }
                return g.next(100) == r3
            })
            var x = w.rng
            frame(w, id)
            _ = x.next(100); _ = x.next(16)
            let a6 = x.next(3) + 2
            _ = x.next(100); _ = x.next(100)
            let timer = egg ? Int32(x.next(2)) + 1 : 0
            XCTAssertEqual(w.rng.seed, x.seed, "r3 \(r3)")
            let s = try slot(w, id)
            XCTAssertEqual([Int(s.subtype), Int(s.phase)], [7, 1])
            XCTAssertEqual([Int32(s.counterA6), s.classTimer, s.classWord154], egg ? [5, timer, 2] : [Int32(a6), 0, 0],
                           "r3 \(r3)")
        }
        // The idle decision's t = (i16)(R(16) − (i16)(HP·100 / max) + 0x5c) at half HP (250 / 500 → t = R(16) + 42): r ==
        // t → `.RandomDilloAttack` (state 8), r == t + 1 → the walk; the fast walk at R(100) > 100 − t (100 − t + 1 fast,
        // 100 − t slow, then R(100) 0 → no egg). The turn: S.x past `+0x160` → facing left, short of `+0x15c` → right;
        // on a bound (675 / 525, strict) the facing is kept.
        for (dr, fastAt, x0, start, right) in [(0, 0, 600, false, true), (1, 1, 2000, true, false),
                                               (1, 0, 100, false, true), (1, 1, 675, true, true),
                                               (1, 1, 525, false, false)] {
            let w = try world()
            let (id, _) = try dillo(w)
            w.active.update(id: id) { s in s.counterA6 = 1; s.hp = 250; s.x = x0; s.mirrored = start }
            w.rng = FastRand(seed: seed { g in
                let r = Int(g.next(100)), t = Int(g.next(16)) + 42
                guard r == t + dr else { return false }
                guard dr == 1 else { return true }
                _ = g.next(3)
                let r2 = Int(g.next(100))
                guard r2 == 100 - t + fastAt else { return false }
                return fastAt == 1 || g.next(100) == 0
            })
            frame(w, id)
            let s = try slot(w, id)
            let tag = "dr \(dr) fast \(fastAt) x \(x0)"
            if dr == 0 {
                XCTAssertEqual(s.subtype, 8, "\(tag): r == t → attack")
                continue
            }
            XCTAssertEqual([Int(s.subtype), Int(s.classTimer)], [7, fastAt], tag)
            XCTAssertEqual(s.mirrored, right, "\(tag): the turn")
        }
        // The walk (M l. 72769–72818): slow (`+0x14c` 0) face 0x74e[`+0x46 >> 1`], the cycle's end past 10, vx ±0x400;
        // fast face 0x74e[`+0x46`], past 4, vx ±0x800. The end: `+0x46 = 0`, `+0xa6` − 1, outside the bounds → 0; at 0 →
        // state 6, `+0xa6 = 8 + R(20)`. Then `+0x46` + 1.
        for (fast, last, right) in [(Int32(0), Int16(10), false), (1, 4, true)] {
            let w = try world()
            let (id, _) = try dillo(w)
            w.active.update(id: id) { s in
                s.subtype = 7; s.classTimer = fast; s.phase = last; s.counterA6 = 2; s.mirrored = right
            }
            frame(w, id)
            var s = try slot(w, id)
            let tag = "fast \(fast)"
            XCTAssertEqual([s.face?.index ?? -1, Int(s.phase), Int(s.counterA6)],
                           [fast == 1 ? 4 : 5, Int(last) + 1, 2], "\(tag): at the cycle's last step, no end")
            let v: Int32 = fast == 1 ? 0x800 : 0x400
            XCTAssertEqual(s.vx, right ? v : -v, tag)
            frame(w, id)
            s = try slot(w, id)
            XCTAssertEqual([s.face?.index ?? -1, Int(s.phase), Int(s.counterA6), Int(s.subtype)],
                           [fast == 1 ? 5 : 5, 1, 1, 7], "\(tag): the end, a6 2 → 1")
            w.active.update(id: id) { $0.phase = last + 1 }
            var x = w.rng
            frame(w, id)
            let a6 = x.next(0x14) + 8
            XCTAssertEqual(w.rng.seed, x.seed, tag)
            s = try slot(w, id)
            XCTAssertEqual([Int(s.subtype), Int(s.counterA6), Int(s.phase)], [6, Int(a6), 1], "\(tag): a6 1 → 0: idle")
        }
        // Outside the bounds at the cycle's end: `+0xa6 = 0` at once.
        let o = try world()
        let (oid, _) = try dillo(o)
        o.active.update(id: oid) { s in s.subtype = 7; s.classTimer = 0; s.phase = 11; s.counterA6 = 9; s.classWord160 = 599 }
        frame(o, oid)
        XCTAssertEqual(try slot(o, oid).subtype, 6, "x 600 > 599: out of bounds")
    }

    func testDilloArmourBlock() throws {
        // `.HitDilloSprite` (M l. 72850–72913): a player shot with `+0xa6 == 0` while HP > 0. Vulnerable only in states
        // 6 / 7 and only from the front — the shot's centre left of the Dillo's facing left, right of it facing right
        // (strict, i16). Front: `.KillPlayerShot(o, 0, 0)`; shot type 1 → `.TurnIntoStatue`; else `.HurtSprite(s, o.+0xa4,
        // (i16)(o.vx >> 1), −1000, 2, 8)` and on a hurt `.BloodSpray(s, o, 0x28, 400, 0x96, 2)`, HP < 201 → snd 702 else
        // HP > 0 → 701 (3D, 1, 0x100), then `.RandomDilloAttack`. Otherwise `.KillPlayerShot(o, 0, 1)` and snd 303 at the
        // shot's centre.
        struct Case { let state: Int16; let right: Bool; let dx: Int; let type: Int16; let front: Bool }
        let cases = [
            Case(state: 6, right: false, dx: -1, type: 2, front: true), Case(state: 6, right: false, dx: 1, type: 2, front: false),
            Case(state: 6, right: false, dx: 0, type: 2, front: false), Case(state: 6, right: true, dx: 1, type: 2, front: true),
            Case(state: 6, right: true, dx: -1, type: 2, front: false), Case(state: 6, right: true, dx: 0, type: 2, front: false),
            Case(state: 7, right: false, dx: -5, type: 2, front: true), Case(state: 8, right: false, dx: -5, type: 2, front: false),
            Case(state: 4, right: false, dx: -5, type: 2, front: false), Case(state: 5, right: false, dx: -5, type: 2, front: false),
            Case(state: 6, right: false, dx: 5, type: 1, front: false), Case(state: 8, right: false, dx: -5, type: 1, front: false),
        ]
        for k in cases {
            let tag = "state \(k.state) right \(k.right) dx \(k.dx) type \(k.type)"
            let w = try world()
            let (id, _) = try dillo(w)
            w.active.update(id: id) { s in s.subtype = k.state; s.mirrored = k.right; s.vx = 0; s.vy = 0 }
            let sid = try other(w, over: id, dx: k.dx, type: k.type, damage: 150, vx: 1001)
            let shot0 = try slot(w, sid)
            w.player.cues = []
            FerazelSession.hitCallback(w, id, sid)              // the session's hit dispatch (`+0x5c`)
            let s = try slot(w, id)
            XCTAssertTrue(try slot(w, sid).dead, "\(tag): the shot is killed either way")
            if k.front {
                XCTAssertEqual([Int(s.hp), Int(s.invulnerable), Int(s.flash), Int(s.vx), Int(s.vy)],
                               [350, 2, 8, 1001 >> 1, -1000], tag)
                XCTAssertEqual([Int(s.subtype), Int(s.phase), Int(s.subState)], [8, 0, 0], "\(tag): retaliation")
                XCTAssertEqual(w.player.cues.last, PlayerCue(call: .threeD, snd: 701, priority: 1, volume: 0x100,
                                                             position: s.centre), tag)
                XCTAssertEqual(blood(w), 0x28, tag)
            } else {
                XCTAssertEqual([Int(s.hp), Int(s.invulnerable), Int(s.subtype)], [500, 0, Int(k.state)], tag)
                XCTAssertEqual(s.handler, .dillo, "\(tag): the Statue spell is blocked too")
                XCTAssertEqual(w.player.cues.last, PlayerCue(call: .threeD, snd: 303, priority: 1, volume: 0x100,
                                                             position: shot0.centre), tag)
                XCTAssertEqual(blood(w), 0, tag)
            }
        }
        // The retaliation's draws follow the hurt's: a twin world runs the same calls by hand (`.KillPlayerShot`,
        // `.HurtSprite`, `.BloodSpray`), then `.RandomDilloAttack`'s R(100) and R(2) — one start seed per attack band.
        func make() throws -> (SpriteWorld, Int, Int) {
            let w = try world()
            let (id, _) = try dillo(w)
            w.active.update(id: id) { s in s.subtype = 7; s.mirrored = false }
            return (w, id, try other(w, over: id, dx: -3))
        }
        func hurt(_ t: SpriteWorld, _ tid: Int, _ tsid: Int) {
            var lights = LightTable()
            PlayerShotHits.kill(t, shot: tsid, sound: false, effect: false, effects: 1, lights: &lights)
            HurtSprite.apply(t, id: tid, damage: 150, dvx: 500, dvy: -1000, invulnerable: 2, flash: 8)
            BloodSpray.spray(t, victim: tid, attacker: tsid, count: 0x28, speed: 400, spread: 0x96, kind: 2)
        }
        for band in [0...35, 36...50, 51...99] as [ClosedRange<Int16>] {
            var start: Int32 = 0
            var x = FastRand(seed: 1)
            for candidate in Int32(1)...200 {
                let (t, tid, tsid) = try make()
                t.rng = FastRand(seed: candidate)
                hurt(t, tid, tsid)
                var probe = t.rng
                if band.contains(probe.next(100)) {
                    start = candidate
                    x = t.rng
                    break
                }
            }
            XCTAssertNotEqual(start, 0, "a seed for \(band)")
            let r = x.next(100)
            let timer = Int32(x.next(2)) + 1
            let (w, id, sid) = try make()
            w.rng = FastRand(seed: start)
            FerazelSession.hitCallback(w, id, sid)
            let s = try slot(w, id)
            XCTAssertEqual(w.rng.seed, x.seed, "r \(r): the hurt's draws, then R(100), R(2)")
            XCTAssertEqual([Int(s.classWord154), Int(s.classTimer), Int(s.counterA6)],
                           [r < 36 ? 0 : r < 51 ? 2 : 1, Int(timer), r < 36 || 50 < r ? 16 : 5], "r \(r)")
        }
        // The sound by the HP left: 201 → 701, 200 → 702; 0 → 702 (`< 0xc9` first).
        for (hp, snd) in [(Int16(351), Int16(701)), (350, 702), (150, 702)] {
            let w = try world()
            let (id, _) = try dillo(w)
            w.active.update(id: id) { s in s.hp = hp; s.subtype = 6 }
            let sid = try other(w, over: id, dx: -3, damage: 150)
            w.player.cues = []
            FerazelSession.hitCallback(w, id, sid)
            XCTAssertEqual(w.player.cues.last?.snd, snd, "HP \(hp) − 150")
        }
        // A shot with `+0xa6 ≠ 0`, or a Dillo at HP 0: nothing — the shot lives on, no sound.
        for (a6, hp) in [(Int16(1), Int16(500)), (0, 0)] {
            let w = try world()
            let (id, _) = try dillo(w)
            w.active.update(id: id) { $0.hp = hp }
            let sid = try other(w, over: id, dx: -3) { $0.counterA6 = a6 }
            w.player.cues = []
            FerazelSession.hitCallback(w, id, sid)
            XCTAssertFalse(try slot(w, sid).dead, "a6 \(a6) HP \(hp)")
            XCTAssertEqual(w.player.cues, [])
        }
        // From the front while still invulnerable from a previous hit: `.HurtSprite` refuses, so no blood, no ouch and no
        // `.RandomDilloAttack` (it sits inside the hurt's success, M l. 72884–72893) — the state, mode and attack phase
        // stay and the stream does not move. The shot is still killed (`.KillPlayerShot` comes first).
        for state in [Int16(6), 7] {
            let w = try world()
            let (id, _) = try dillo(w)
            w.active.update(id: id) { s in
                s.subtype = state; s.mirrored = false; s.invulnerable = 2; s.phase = 3; s.subState = 2
                s.classWord154 = 9; s.classTimer = 7; s.counterA6 = 11
            }
            let sid = try other(w, over: id, dx: -3, damage: 150)
            let seed0 = w.rng.seed
            w.player.cues = []
            FerazelSession.hitCallback(w, id, sid)
            let s = try slot(w, id)
            let tag = "invulnerable, state \(state)"
            XCTAssertTrue(try slot(w, sid).dead, tag)
            XCTAssertEqual([Int(s.hp), Int(s.invulnerable), Int(s.subtype), Int(s.phase), Int(s.subState)],
                           [500, 2, Int(state), 3, 2], tag)
            XCTAssertEqual([Int(s.classWord154), Int(s.classTimer), Int(s.counterA6)], [9, 7, 11], "\(tag): no attack")
            XCTAssertEqual(w.rng.seed, seed0, "\(tag): no R(100) / R(2)")
            XCTAssertEqual(w.player.cues.filter { $0.snd == 701 || $0.snd == 702 }, [], tag)
            XCTAssertEqual(blood(w), 0, tag)
        }
        // The Statue spell from the front in state 6: `.TurnIntoStatue`; no hurt, no retaliation.
        let v = try world()
        let (vid, _) = try dillo(v)
        let statue = try other(v, over: vid, dx: -3, type: 1)
        FerazelSession.hitCallback(v, vid, statue)
        XCTAssertEqual(try slot(v, vid).handler, .statue)
        XCTAssertEqual(try slot(v, vid).hp, 500)
        // An Effect 0x4b7 (the Smiting explosion) or an active geyser 0x5a0: no Dillo arm — nothing.
        for (type, handler) in [(Int16(0x4b7), SpriteHandler.effect), (0x5a0, .background)] {
            let u = try world()
            let (uid, _) = try dillo(u)
            let o = try other(u, over: uid, dx: -3, type: type, handler: handler) { s in s.phase = 0; s.classTimer = 1 }
            FerazelSession.hitCallback(u, uid, o)
            XCTAssertEqual([Int(try slot(u, uid).hp), Int(try slot(u, uid).subtype)], [500, 6], "type \(type)")
        }
        // The crush (M l. 72900–72911): a Box or Statue whose `.PlatformBounce` is 2 with the solid falling (or the Dillo
        // on ground) → HP 0, `+0x150 = 0x16`.
        for (handler, vy, crushed) in [(SpriteHandler.box, Int32(1), true), (.statue, 1, true), (.platform, 1, false)] {
            func make() throws -> (SpriteWorld, Int, Int) {
                let w = try world(floorRow: nil)
                let (id, _) = try dillo(w, x: 200, y: 300)
                w.active.update(id: id) { m in m.vy = 0; m.vx = 0; m.groundKind = 0 }
                let box = try XCTUnwrap(w.newSprite(type: 0xc12, x: 200, y: 300 + 0x17 - 0x1d, layer: 2,
                                                    handler: handler) { b in
                    b.x = 200 + 0x1a
                    b.y = 300 + 0x17 - 0x1d
                    b.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x20, right: 0x30)
                    b.vy = vy
                })
                return (w, id, box)
            }
            let (ta, tia, tba) = try make()
            let r = try slot(ta, tia).hotRect
            let b = ta.platformBounce(mover: tia, solid: tba, centre: SpriteSlot.Point(x: 0x32, y: 0x28), factor: 0,
                                      rect: r, bounce: false)
            if handler != .platform { XCTAssertEqual(b, 2, "contact from below") }
            let (w, id, box) = try make()
            FerazelSession.hitCallback(w, id, box)
            let s = try slot(w, id)
            XCTAssertEqual([Int(s.hp), Int(s.classWord150)], crushed ? [0, 0x16] : [500, -1], "\(handler)")
        }
    }

    func testDilloKillScore1500() throws {
        // HP < 1 with state ≠ 4, after the state switch (M l. 72819–72824): state 4, `+0x46 = +0xa6 = 0`, snd 703 (3D, 1,
        // 0x100). State 4 (M l. 72611–72625): vx × 0.9; face 0x750[`+0x46 / 3`]; `+0x46` + 1, capped at 14; `+0xa6` + 1; at
        // 45 → `+0x1a2 = 1` (the burn, `.KillDillo` at its end).
        let w = try world()
        let (id, _) = try dillo(w)
        w.active.update(id: id) { s in s.hp = 0; s.counterA6 = 3; s.vx = 0 }
        w.player.cues = []
        let before = try slot(w, id)
        frame(w, id)
        var s = try slot(w, id)
        XCTAssertEqual([Int(s.subtype), Int(s.phase), Int(s.counterA6)], [4, 0, 0])
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeD, snd: 703, priority: 1, volume: 0x100,
                                                 position: before.centre)])
        XCTAssertEqual(s.face, f(Dillo.walkType, 0), "the entry frame ran state 6's face; no death face yet")
        // HP 1 lives on.
        let a = try world()
        let (aid, _) = try dillo(a)
        a.active.update(id: aid) { s in s.hp = 1; s.counterA6 = 3 }
        frame(a, aid)
        XCTAssertEqual(try slot(a, aid).subtype, 6)
        // The death frames.
        w.active.update(id: id) { $0.vx = 1000 }
        var faces: [Int] = []
        for k in 0..<17 {
            let b = try slot(w, id)
            frame(w, id)
            s = try slot(w, id)
            faces.append(s.face?.index ?? -1)
            XCTAssertEqual(s.face?.pict, Dillo.deathType)
            if k == 0 { XCTAssertEqual(s.vx, 900, "1000 × 0.9") }
            XCTAssertEqual(Int(s.phase), min(Int(b.phase) + 1, 14))
        }
        XCTAssertEqual(faces, [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4, 4], "phase / 3, the phase capped at 14")
        XCTAssertEqual([Int(s.counterA6), Int(s.burnRow)], [17, 0])
        w.active.update(id: id) { $0.counterA6 = 43 }
        frame(w, id)
        XCTAssertEqual([Int(try slot(w, id).counterA6), Int(try slot(w, id).burnRow)], [44, 0])
        frame(w, id)
        XCTAssertEqual(try slot(w, id).counterA6, 45)
        XCTAssertNotEqual(try slot(w, id).burnRow, 0, "45: the burn starts")
        // `.KillDillo` (the Kill proc `+0x50`, M l. 72916–72937): counted (`+0x1b5`, `+0xe9 == 0`) → live − 1, the
        // enemies stat + 1; score + 1500 unconditionally; `+0xe9 = 1`, `+0xea = 1`.
        let k = try world()
        let (kid, _) = try dillo(k)
        XCTAssertEqual(k.enemies.live, 1)
        k.globals.score = 0
        EnemyCommon.killProc(k, id: kid)
        let ks = try slot(k, kid)
        XCTAssertEqual([ks.dead, ks.killedForGood], [true, true])
        XCTAssertEqual([Int(k.globals.score), Int(k.enemies.live), Int(k.globals.achieved[0][3])], [1500, 0, 1])
        EnemyCommon.killProc(k, id: kid)
        XCTAssertEqual([Int(k.globals.score), Int(k.enemies.live), Int(k.globals.achieved[0][3])], [3000, 0, 1],
                       "a second Kill counts nothing and scores again")
        // The liquids (M l. 72828–72843, `EnemyCommon.liquids` — the Dillo row): kind 2 hurts (`+0x116` 0x13, HP − 100,
        // `+0xaa` 0x11, snd 701 vol 0x55); kind 3 heals 4 below 500; kind 1 nothing.
        for (liquid, hp, want) in [(2, Int16(500), Int16(400)), (3, 300, 304), (3, 500, 500), (1, 500, 500)] {
            let u = try world(floorRow: 20, waterRow: 15, liquid: liquid)
            let (uid, _) = try dillo(u)
            u.active.update(id: uid) { s in s.hp = hp; s.counterA6 = 100 }
            frame(u, uid)
            let t = try slot(u, uid)
            XCTAssertNotEqual(t.waterRow, 0, "liquid \(liquid): in it")
            XCTAssertEqual(t.hp, want, "liquid \(liquid) HP \(hp)")
            if liquid == 2 { XCTAssertEqual([Int(t.invulnerable), Int(t.flash)], [0x13, 0x11]) }
        }
        // The session's Handle dispatch: a dying Dillo near the player, kept active, counts on to the burn.
        let sess = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 3, seed: 1)
        let sw = sess.world
        let me = try slot(sw, try XCTUnwrap(sw.playerID))
        let p = Placement(index: 0, flag: 1, byte1: 0, type: 0x74f, p1: 0, p2: 100, p3: 0, p4: 0,
                          y: Int16(me.y - 150), x: Int16(me.x + 150))
        var ns = SpriteSlot(type: 0x74f, x: Int(p.x), y: Int(p.y), recordIndex: -1)
        ns.oldPosition = SpriteSlot.Point(x: ns.x, y: ns.y)
        var none = EnemyCounting()
        _ = Dillo.setup(&ns, record: p, rng: &sw.rng, counting: &none)
        ns.mayIdle = false
        ns.subtype = 4
        ns.hp = 0
        ns.counterA6 = 44
        let nd = sw.active.insert(ns)
        _ = sess.step(keys: KeyState())
        XCTAssertEqual(try slot(sw, nd).counterA6, 45, "the Dillo Handle ran")
        XCTAssertNotEqual(try slot(sw, nd).burnRow, 0)
    }
}
