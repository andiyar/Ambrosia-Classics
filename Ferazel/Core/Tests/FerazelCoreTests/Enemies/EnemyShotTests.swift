import XCTest
@testable import FerazelCore

/// ES (docs/plans/2026-10-30-ferazel-phase5.md): the EnemyShot class — `.SetupEnemyShotSprite` (M l. 51442–51611),
/// `.HandleEnemyShotSprite` (M l. 51614–51908), `.HitEnemyShotSprite` (M l. 51911–51964), `.KillEnemyShot` (M l.
/// 51967–52091), `.HitEnemyShotTileSprite` (M l. 52094–52258) — `.ShieldBlock` (M l. 48359–48444) with step 7's shot
/// rows of `.HitPlayerSprite` (M l. 49802–49929), the Magical Shield crouch face (M l. 45835–45860) and the boulder
/// spouts (M l. 60488–60547). Synthetic 16×16 grids over a level's header; every expected draw is re-derived from a
/// copy of the stream at the call site.
final class EnemyShotTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// An empty 16×16 grid over `level`'s header and the player at (`px`, `py`) with HP 1000, not invulnerable.
    private func world(level: Int16 = 1, px: Int = 100, py: Int = 200) throws -> (SpriteWorld, Int) {
        let w = SpriteWorld(level: try LevelFile.load(from: try resources(), level: level))
        let empty = [UInt16](repeating: 0, count: 16 * 16)
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: empty), bg: TileMap(width: 16, height: 16, cells: empty),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        let pid = try XCTUnwrap(Player.spawn(world: w, x: px, y: py))
        w.playerID = pid
        w.active.update(id: pid) { $0.hp = 1000; $0.invulnerable = 0 }
        w.player.cues = []
        return (w, pid)
    }

    private func slot(_ w: SpriteWorld, _ id: Int) throws -> SpriteSlot { try XCTUnwrap(w.active.record(id: id)) }

    private func shots(_ w: SpriteWorld, _ type: Int16) -> [SpriteSlot] {
        w.active.sprites.filter { $0.handler == .enemyShot && $0.type == type }
    }

    /// One `.HandleEnemyShotSprite` call.
    private func frame(_ w: SpriteWorld, _ id: Int, _ solver: TileSolver) {
        var lights = LightTable()
        EnemyShot.handle(world: w, id: id, solver: solver, lights: &lights, effects: 1)
    }

    /// `.HitEnemyShotTileSprite(s, pos, kind, layer)`.
    private func tile(_ w: SpriteWorld, _ id: Int, _ solver: TileSolver, kind: Int = 3,
                      layer: TileLayer = .foreground) {
        var lights = LightTable()
        EnemyShot.hitTile(solver, id, TilePos(x: 96, y: 192), kind, layer, lights: &lights, effects: 1)
    }

    /// The shot moved so its hot rect's bottom sits in the lower half of the floor cell (96, 192) of kind 3, falling.
    private func intoFloor(_ w: SpriteWorld, _ id: Int, vy: Int32 = 0x400, vx: Int32 = 0) {
        w.active.update(id: id) { s in
            let y = 192 + 23 - s.hotRect.bottom
            s.x = 96
            s.x256 = 96 << 8
            s.y = y
            s.y256 = Int32(y) << 8
            s.oldPosition = SpriteSlot.Point(x: 96, y: y)
            s.vx = vx
            s.vy = vy
            s.centre = SpriteSlot.Point(x: 1234, y: 567)                       // a sentinel `+0x10` / `+0xe`
        }
    }

    /// The Magical Shield (item 0xf) in slot 0.
    private func giveShield(_ w: SpriteWorld) {
        w.globals.inventory[0] = InventorySlot(id: 0xf, count: 1, field4: -1, field6: 0, isSpell: 0)
    }

    /// A shot of `type` whose centre stands `dx` px right of the player's hot rect right edge (left of the left edge
    /// for `dx` < 0), at the player's height, with `vx`.
    private func shotBeside(_ w: SpriteWorld, _ pid: Int, _ type: Int16, dx: Int, vx: Int32, vy: Int32 = 0,
                            handler: SpriteHandler = .enemyShot) throws -> Int {
        let p = try slot(w, pid)
        let cx = dx >= 0 ? p.x + p.hotRect.right + dx : p.x + p.hotRect.left + dx
        let id: Int
        if handler == .enemyShot {
            id = try XCTUnwrap(EnemyShot.spawn(w, type: type, x: cx - 12, y: p.y + 40, layer: 0))
        } else {
            id = try XCTUnwrap(w.newSprite(type: type, x: cx - 12, y: p.y + 40, layer: 0xb, handler: handler) { $0.hp = 100 })
        }
        w.active.update(id: id) { s in
            s.x = cx - 12
            s.y = p.y + 40
            s.vx = vx
            s.vy = vy
            s.centre = SpriteSlot.Point(x: cx, y: p.y + 50)
        }
        return id
    }

    // MARK: - flight

    func testWalkerAxeShot() throws {
        // The Walker's axe, type 0 / 1 (its facing byte): the default arm of the Setup — R(5) the phase, `+0x90` 0x100,
        // gravity 0xaf, `+0xa6` 0, `+0x8c` 1, the hot rect `SetRect(8, 8, 16, 16)`, no face, `+0xc ← +8`, `+0xa ← +6`
        // (M l. 51455–51611). Its Handle: `+0xa6` + 1, type 0 phase + 1 (type 1 − 1), the default arm's wrap 0…7 and face
        // 0x6a7[phase] (M l. 51869–51879), `.ApplyGravityAndSeparateFromTiles` (vy + 0xaf, x + vx, y + vy).
        let (w, pid) = try world()
        var r = w.rng
        let phase0 = r.next(5)
        let id = try XCTUnwrap(EnemyShot.spawn(w, type: 0, x: 300, y: 100, layer: 12))
        XCTAssertEqual(w.rng.seed, r.seed, "the default arm draws R(5) only")
        var s = try slot(w, id)
        XCTAssertEqual(s.handler, .enemyShot)
        XCTAssertEqual([s.hasHit, s.hasTileHit, s.burnPitched, s.lightOverlay], [true, true, true, true])
        XCTAssertEqual([Int(s.gravity), Int(s.windScale), Int(s.counterA6), Int(s.hp), Int(s.layer), Int(s.phase)],
                       [0xaf, 0x100, 0, 0, 12, Int(phase0)])
        XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 8, left: 8, bottom: 0x10, right: 0x10))
        XCTAssertEqual([s.x, s.y, Int(s.x256), Int(s.y256)], [300, 100, 300 << 8, 100 << 8])
        XCTAssertNil(s.face)
        XCTAssertEqual([s.bounceCount, s.classWord154, s.classTimer], [0, 0, 0])
        w.active.update(id: id) { $0.vx = 0x618; $0.vy = -0x334 }
        let solver = TileSolver(world: w)
        var x256: Int32 = 300 << 8, y256: Int32 = 100 << 8, vy: Int32 = -0x334
        var p = phase0
        let seed = w.rng.seed
        for n in 1...10 {
            frame(w, id, solver)
            vy += 0xaf
            x256 += 0x618
            y256 += vy
            p += 1
            if 7 < p { p = 0 }
            s = try slot(w, id)
            XCTAssertEqual(s.phase, p, "frame \(n)")
            XCTAssertEqual(s.face, FaceRef(pict: 0x6a7, index: Int(p), set: .encoded), "frame \(n)")
            XCTAssertEqual([s.vy, s.x256, s.y256], [vy, x256, y256], "frame \(n)")
            XCTAssertEqual(Int(s.counterA6), n)
            XCTAssertFalse(s.dead)
        }
        XCTAssertEqual(w.rng.seed, seed, "no draw in flight")
        // Type 1 counts down: 0 → −1 → 7.
        let one = try XCTUnwrap(EnemyShot.spawn(w, type: 1, x: 300, y: 100, layer: 12))
        w.active.update(id: one) { $0.phase = 0 }
        frame(w, one, solver)
        XCTAssertEqual(try slot(w, one).phase, 7)
        XCTAssertEqual(try slot(w, one).face, FaceRef(pict: 0x6a7, index: 7, set: .encoded))
        // Its own Hit never kills types 0 / 1 against the player (M l. 51921–51926)…
        var lights = LightTable()
        EnemyShot.hit(w, shot: one, other: pid, lights: &lights, effects: 1)
        XCTAssertFalse(try slot(w, one).dead)
        // …the player's step 7 does: 0x38 (the "all others" row, M l. 49853–49891), invulnerability 0x3c, no coin draw,
        // then `.KillEnemyShot` (M l. 49920).
        HitPlayerSprite.hit(w, player: pid, other: one)
        XCTAssertEqual([Int(try slot(w, pid).hp), Int(try slot(w, pid).invulnerable)], [1000 - 0x38, 0x3c])
        XCTAssertTrue(try slot(w, one).dead)
        // Dies on the first wall: `+0x150` 0 → 1 ≥ 0 (M l. 52126–52135); no sound (not a boulder), nothing spawned.
        let axe = try XCTUnwrap(EnemyShot.spawn(w, type: 0, x: 300, y: 100, layer: 12))
        intoFloor(w, axe)
        let count = w.active.sprites.count
        w.player.cues = []
        tile(w, axe, solver)
        s = try slot(w, axe)
        XCTAssertTrue(s.dead)
        XCTAssertEqual([s.bounceCount, s.classWord154], [1, 1])
        XCTAssertEqual(s.vy, -((0x400 * 0xa0) >> 8), "restitution 0xa0 before the kill")
        XCTAssertEqual(w.player.cues, [])
        XCTAssertEqual(w.active.sprites.count, count)
        // Killed below the map (`hdr+0xb282 << 5 < +0xa`, M l. 51885–51887) and 1000 px beyond the view (M l.
        // 51901–51907: camX − x ≥ 1001, or x − (camX + 640) > 1000); at exactly 1000 it flies on.
        let rows = Int(w.level.header.gridHeight) << 5
        for (x, y, gone) in [(300, rows + 1, true), (300, rows, false), (0x280 + 1000 + 1, 100, true),
                             (0x280 + 1000, 100, false), (-1001, 100, true), (-1000, 100, false)] {
            let a = try XCTUnwrap(EnemyShot.spawn(w, type: 0, x: x, y: y, layer: 12))
            w.active.update(id: a) { $0.vy = 0; $0.gravity = 0 }
            w.player.scrollH = 0
            frame(w, a, solver)
            XCTAssertEqual(try slot(w, a).dead, gone, "(\(x), \(y))")
        }
        // The other thrown types' arms: 0x6a9 lives two Handles (`+0x14c` 2, M l. 51472; − 1 at each, dead at 0), layer
        // 0x14, no face; 0x6d6 never times out (`+0xa6` 3: + 1 then − 1, M l. 51656 / 51671–51675); 0x71f faces 0x71f,
        // `+0x17e = vx > 0` (raw `1005c408..1005c428`); 0x754 faces 0x754[`+0x46`], layer 0xc, gravity 0.
        let swing = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6a9, x: 300, y: 100, layer: 11))
        XCTAssertEqual([Int(try slot(w, swing).layer), Int(try slot(w, swing).gravity)], [0x14, 0])
        XCTAssertEqual(try slot(w, swing).hotRect, IdleSprites.Rect(top: 0, left: 0, bottom: 0xe, right: 0x5a))
        frame(w, swing, solver)
        XCTAssertFalse(try slot(w, swing).dead)
        XCTAssertNil(try slot(w, swing).face)
        frame(w, swing, solver)
        XCTAssertTrue(try slot(w, swing).dead)
        let ax = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6d6, x: 300, y: 100, layer: 11))
        XCTAssertEqual([Int(try slot(w, ax).counterA6), Int(try slot(w, ax).hp)], [3, 0x70])
        w.active.update(id: ax) { $0.gravity = 0 }
        for _ in 0..<5 { frame(w, ax, solver) }
        XCTAssertEqual(try slot(w, ax).counterA6, 3)
        XCTAssertFalse(try slot(w, ax).dead)
        for vx in [Int32(0xb00), 0, -0xb00] {
            let wr = try XCTUnwrap(EnemyShot.spawn(w, type: 0x71f, x: 300, y: 100, layer: 0))
            w.active.update(id: wr) { $0.vx = vx }
            frame(w, wr, solver)
            XCTAssertEqual(try slot(w, wr).mirrored, vx > 0, "vx \(vx)")
            XCTAssertEqual(try slot(w, wr).face, FaceRef(pict: 0x71f, index: 1, set: .encoded))
        }
        let spine = try XCTUnwrap(EnemyShot.spawn(w, type: 0x754, x: 300, y: 100, layer: 0))
        XCTAssertEqual([Int(try slot(w, spine).layer), Int(try slot(w, spine).gravity)], [0xc, 0])
        w.active.update(id: spine) { $0.phase = 3 }
        frame(w, spine, solver)
        XCTAssertEqual(try slot(w, spine).face, FaceRef(pict: 0x754, index: 3, set: .encoded))
        // The boss types, built as read. The Chief's boulder 0x77b: no tile callback, gravity 0x140; the cache face by
        // `+0x46` (+ 1, − 1 while `+0x15c`, wrapped 0…0xf); its hot rect the face's bounds (face `+8`) with top + 4,
        // left + 4, bottom − 3, right − 4 (M l. 51793–51815).
        let rock = try XCTUnwrap(EnemyShot.spawn(w, type: 0x77b, x: 300, y: 100, layer: 5))
        XCTAssertEqual([try slot(w, rock).hasTileHit ? 1 : 0, Int(try slot(w, rock).gravity)], [0, 0x140])
        XCTAssertEqual(try slot(w, rock).hotRect, IdleSprites.Rect(top: 0x20, left: 0x20, bottom: 0x38, right: 0x50))
        w.active.update(id: rock) { $0.phase = 0xf; $0.gravity = 0 }
        var lt = LightTable()
        let bounds = IdleSprites.Rect(top: 10, left: 12, bottom: 100, right: 104)
        EnemyShot.handle(world: w, id: rock, solver: solver, lights: &lt, effects: 1, faceBounds: { _ in bounds })
        XCTAssertEqual(try slot(w, rock).face, FaceRef(pict: 0x77b, index: 0, set: .encoded))
        XCTAssertEqual(try slot(w, rock).hotRect, IdleSprites.Rect(top: 14, left: 16, bottom: 97, right: 100))
        w.active.update(id: rock) { $0.classWord15c = 1 }
        EnemyShot.handle(world: w, id: rock, solver: solver, lights: &lt, effects: 1, faceBounds: { _ in bounds })
        XCTAssertEqual(try slot(w, rock).phase, 0xf)
        // The arm's own bottom test, before the move (M l. 51818: `hdr+0xb282·0x20 + 0x20 < +0xa`): at rows + 0x21,
        // rising 0x22 px, it dies though the common test after the move (M l. 51879) would pass it; at rows + 0x20 not.
        for (dy, gone) in [(0x21, true), (0x20, false)] {
            let c = try XCTUnwrap(EnemyShot.spawn(w, type: 0x77b, x: 300, y: rows + dy, layer: 5))
            w.active.update(id: c) { $0.gravity = 0; $0.vy = -(0x22 << 8) }
            EnemyShot.handle(world: w, id: c, solver: solver, lights: &lt, effects: 1, faceBounds: { _ in bounds })
            XCTAssertEqual(try slot(w, c).y, rows + dy - 0x22)
            XCTAssertEqual(try slot(w, c).dead, gone, "rows + \(dy)")
        }
        // The fireball 0x46a: layer 8, rect (6, 6, 0x2a, 0x1a), `+0x88` 0, R(5) twice at Setup; each Handle on a level
        // with no flame (`hdr+0x2722 == 0`) R(3) + 5 sparks: R(0x24), R(0x24), R(2) each (M l. 51822–51848).
        XCTAssertEqual(w.level.header.flameMode, 0)
        var r2 = w.rng
        _ = (r2.next(5), r2.next(5))
        let fb = try XCTUnwrap(EnemyShot.spawn(w, type: 0x46a, x: 300, y: 100, layer: 0))
        XCTAssertEqual(w.rng.seed, r2.seed)
        XCTAssertEqual([Int(try slot(w, fb).layer), try slot(w, fb).lightOverlay ? 1 : 0], [8, 0])
        XCTAssertEqual(try slot(w, fb).hotRect, IdleSprites.Rect(top: 6, left: 6, bottom: 0x1a, right: 0x2a))
        // Each spark `NewParticle(1, 0xbe, (y + (vy >> 8) + 6 + dv, x + (vx >> 8) + 6 + dh), R(2) + 1, 0, 0, 0, 1)`,
        // from the position before the move (M l. 51829–51846).
        w.active.update(id: fb) { $0.vx = 0x3ff; $0.vy = -0x280 }
        let n = Int(r2.next(3)) + 5
        var sparks: [[Int]] = []
        for _ in 0..<n {
            let dh = Int(r2.next(0x24)), dv = Int(r2.next(0x24)), sh = Int(r2.next(2)) + 1
            sparks.append([1, 0xbe, (300 + 3 + 6 + dh) << 8, (100 - 3 + 6 + dv) << 8, sh, 0, 0, 0, 1])
        }
        let p0 = w.particles.counters.count
        let alive0 = w.particles.records.map(\.alive)
        frame(w, fb, solver)
        XCTAssertEqual(w.rng.seed, r2.seed)
        XCTAssertEqual(Int(w.particles.counters.count - p0), n)
        XCTAssertEqual(w.particles.records.indices.filter { w.particles.records[$0].alive && !alive0[$0] }.map {
            let q = w.particles.records[$0]
            return [Int(q.kind), Int(q.gravity), Int(q.x), Int(q.y), Int(q.shape), Int(q.vx), Int(q.vy), Int(q.age),
                    Int(q.mode)]
        }, sparks)
        // Its Kill (M l. 52074–52079): R(13000), `.STPlay3DSoundPitched(301, 1, 0x100, +0xe, R + 44000)`, the particles
        // (2, 2, 2, 0x96, 0x66) — none with no face — and `+0xe9 = 1`.
        var r3 = w.rng
        let pitch = Int32(r3.next(13000)) + 44000
        w.player.cues = []
        var lk = LightTable()
        EnemyShot.kill(w, shot: fb, lights: &lk, effects: 1)
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDPitched, snd: 301, priority: 1, volume: 0x100,
                                                 position: try slot(w, fb).centre, rate: pitch)])
        XCTAssertEqual(w.rng.seed, r3.seed)
        XCTAssertTrue(try slot(w, fb).dead)
    }

    func testBoulderBounceBudget() throws {
        // `.SetupEnemyShotSprite` 0x6e1 / 0x6e2 (M l. 51475–51487): rect (8, 8, 0x18, 0x18), gravity 300, HP 200,
        // `+0xeb` 1, `+0x150 = −2 − R(2)`, then `R(100) > 0x56` → `+0x150 −= 3 − R(5)`: every start in −6…−1.
        let (w, _) = try world()
        var seen = Set<Int32>()
        var adjusted = 0
        for seed in Int32(1)...1500 {
            w.rng = FastRand(seed: seed)
            var r = w.rng
            _ = r.next(5)
            var b = -2 - Int32(r.next(2))
            if 0x56 < r.next(100) {
                b -= 3 - Int32(r.next(5))
                adjusted += 1
            }
            let id = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6e1, x: 0, y: 0, layer: 9))
            XCTAssertEqual(try slot(w, id).bounceCount, b, "seed \(seed)")
            XCTAssertEqual(w.rng.seed, r.seed, "seed \(seed)")
            seen.insert(b)
            w.active.remove(id: id)
        }
        XCTAssertEqual(seen, Set(Int32(-6) ... -1))
        XCTAssertGreaterThan(adjusted, 0)
        w.rng = FastRand(seed: 1)
        let b0 = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6e1, x: 0, y: 0, layer: 9))
        let s0 = try slot(w, b0)
        XCTAssertEqual([Int(s0.hp), Int(s0.gravity), Int(s0.crunches)], [200, 300, 1])
        XCTAssertEqual(s0.hotRect, IdleSprites.Rect(top: 8, left: 8, bottom: 0x18, right: 0x18))
        // The budget on FG contacts (M l. 52113–52138): each counted contact plays snd 436 (`*_DAT_100a03ac`, vol 0x55,
        // `.STPlay3DSoundRand` at `+0xe`), `+0x150` + 1 and `+0x154 = 1`; killed when `+0x150 ≥ 0`. The Handle re-arms
        // `+0x154` (− 1 a frame, M l. 51882–51884, never below 0); while it is 1 the FG arm does nothing. Each contact
        // below follows one real Handle call in the open (no tile) — the gate's only re-arm.
        let solver = TileSolver(world: w)
        let start = s0.bounceCount
        var contacts = 0
        while try !slot(w, b0).dead && contacts < 10 {
            let gate = try slot(w, b0).classWord154
            frame(w, b0, solver)
            XCTAssertEqual(try slot(w, b0).classWord154, max(gate - 1, 0), "contact \(contacts + 1)")
            intoFloor(w, b0)
            var r = w.rng
            let rate = r.soundRate()
            w.player.cues = []
            tile(w, b0, solver)
            contacts += 1
            XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDRand, snd: 436, priority: 1, volume: 0x55,
                                                     position: SpriteSlot.Point(x: 1234, y: 567), rate: rate)])
            XCTAssertEqual(try slot(w, b0).bounceCount, start + Int32(contacts))
            XCTAssertEqual(try slot(w, b0).classWord154, 1)
            if try !slot(w, b0).dead {
                XCTAssertEqual(try slot(w, b0).vy, -((0x400 * 0xa0) >> 8))
                // Gated: a second FG call in the same frame does nothing.
                intoFloor(w, b0)
                let before = try slot(w, b0)
                w.player.cues = []
                tile(w, b0, solver)
                XCTAssertEqual([try slot(w, b0).vy, try slot(w, b0).bounceCount], [before.vy, before.bounceCount])
                XCTAssertEqual(w.player.cues, [])
            }
        }
        XCTAssertEqual(contacts, Int(-start), "dies on the contact that takes `+0x150` to 0")
        // BG kinds < 100 take the rule without the `+0x154` gate (M l. 52143–52178): with `+0x154` already 1 the bounce
        // and the sound happen, `+0x150` stays. A bomb 0x6e2 plays 436 as well.
        let bg = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6e2, x: 0, y: 0, layer: 9))
        w.active.update(id: bg) { $0.bounceCount = -3 }
        intoFloor(w, bg)
        w.active.update(id: bg) { $0.classWord154 = 1 }
        w.player.cues = []
        tile(w, bg, solver, layer: .background)
        XCTAssertEqual(try slot(w, bg).bounceCount, -3)
        XCTAssertEqual(try slot(w, bg).vy, -((0x400 * 0xa0) >> 8))
        XCTAssertEqual(w.player.cues.map(\.snd), [436])
        intoFloor(w, bg)
        w.active.update(id: bg) { $0.classWord154 = 0 }
        tile(w, bg, solver, layer: .background)
        XCTAssertEqual(try slot(w, bg).bounceCount, -2)
        // `fast` (|vx| ≥ 0x1195 or |vy| ≥ 0x1965 before the bounce) kills on any contact.
        let f = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6e1, x: 0, y: 0, layer: 9))
        XCTAssertLessThan(try slot(w, f).bounceCount, -1)
        intoFloor(w, f, vx: 0x1195)
        tile(w, f, solver)
        XCTAssertTrue(try slot(w, f).dead)
        // The edges (M l. 52119–52132: |vx| < 0x1195 and |vy| < 0x1965 is slow), with a budget the contact leaves < 0.
        for (vx, vy, dead) in [(Int32(0x1194), Int32(0x400), false), (0, 0x1965, true), (0, 0x1964, false)] {
            let g = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6e1, x: 0, y: 0, layer: 9))
            w.active.update(id: g) { $0.bounceCount = -5 }
            intoFloor(w, g, vy: vy, vx: vx)
            tile(w, g, solver)
            XCTAssertEqual(try slot(w, g).bounceCount, -4)
            XCTAssertEqual(try slot(w, g).dead, dead, "vx \(vx) vy \(vy)")
        }
        // BG (and crunch) contacts skip the types 0x46a…0x46f (M l. 52163): no bounce, no budget.
        for (type, bounces) in [(Int16(0x469), true), (0x46a, false), (0x46f, false), (0x470, true)] {
            let g = try XCTUnwrap(EnemyShot.spawn(w, type: type, x: 0, y: 0, layer: 9))
            intoFloor(w, g)
            tile(w, g, solver, layer: .background)
            XCTAssertEqual([try slot(w, g).vy, try slot(w, g).bounceCount], bounces ? [-((0x400 * 0xa0) >> 8), 1] : [0x400, 0],
                           "type \(type)")
        }
        // The split (`.KillEnemyShot` M l. 51995–52022): n = R(3) + 3 shards 0x6e6; shard i (1…n): R(16) (dy), R(16) (dx),
        // `MTNewSprite(0x6e6, x + dx, y + dy, the parent's layer, −1, .SetupEnemyShotSprite)` — its Setup's R(5) —
        // `+0x154 = +0x150 = 1`, vx = parent vx + R(200i) − 100i, vy = parent vy + R(200i) − 100i. 0x6e1 then just dies.
        let k = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6e1, x: 400, y: 120, layer: 9))
        w.active.update(id: k) { $0.vx = 0x300; $0.vy = -0x200; $0.x = 400; $0.y = 120 }
        var r = w.rng
        let n = Int(r.next(3)) + 3
        var want: [[Int]] = []
        for i in 1...n {
            let dy = Int(r.next(16)), dx = Int(r.next(16))
            _ = r.next(5)
            let vx = 0x300 + Int(r.next(Int16(200 * i))) - 100 * i
            let vy = -0x200 + Int(r.next(Int16(200 * i))) - 100 * i
            want.append([400 + dx, 120 + dy, vx, vy, 1, 1, 9])
        }
        w.player.cues = []
        var lights = LightTable()
        let earlier = Set(shots(w, 0x6e6).map(\.id))                    // the two kills above split too
        EnemyShot.kill(w, shot: k, lights: &lights, effects: 1)
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertTrue(try slot(w, k).dead)
        XCTAssertEqual(w.player.cues, [])
        XCTAssertEqual(shots(w, 0x6e6).filter { !earlier.contains($0.id) }.map { [$0.x, $0.y, Int($0.vx), Int($0.vy), Int($0.bounceCount),
                                             Int($0.classWord154), Int($0.layer)] }, want)
    }

    func testBombBoulderExplodes() throws {
        // 0x6e2's Kill (M l. 52028–52033): the shards, then `.STPlay3DSoundRand(435, 1, 0x100, +0xe)` and the Effect 0x4b7
        // at (x − 0x20, y − 0x20), layer 0xc (its Setup stores 0xb); `+0xe9 = 1`.
        let (w, pid) = try world()
        let k = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6e2, x: 400, y: 120, layer: 9))
        w.active.update(id: k) { $0.centre = SpriteSlot.Point(x: 416, y: 136) }
        var r = w.rng
        let n = Int(r.next(3)) + 3
        for i in 1...n {
            _ = (r.next(16), r.next(16), r.next(5))
            _ = (r.next(Int16(200 * i)), r.next(Int16(200 * i)))
        }
        let rate = r.soundRate()
        var lights = LightTable()
        EnemyShot.kill(w, shot: k, lights: &lights, effects: 1)
        XCTAssertTrue(try slot(w, k).dead)
        XCTAssertEqual(shots(w, 0x6e6).count, n)
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDRand, snd: 435, priority: 1, volume: 0x100,
                                                 position: SpriteSlot.Point(x: 416, y: 136), rate: rate)])
        let big = w.active.sprites.filter { $0.handler == .effect && $0.type == EffectSprite.bigExplosion }
        XCTAssertEqual(big.map { [$0.x, $0.y] }, [[400 - 0x20, 120 - 0x20]])
        // A bomb never reaches `.HitPlayerSprite` (enemy-shots-and-damage-2 §4.3): its own Hit kills it against the
        // player (0x6e2 is not in the exclusion list, M l. 51921–51926) — it splits and explodes there.
        let b = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6e2, x: 300, y: 120, layer: 9))
        EnemyShot.hit(w, shot: b, other: pid, lights: &lights, effects: 1)
        XCTAssertTrue(try slot(w, b).dead)
        XCTAssertEqual(w.active.sprites.filter { $0.handler == .effect && $0.type == EffectSprite.bigExplosion }.count, 2)
        // The whole list against the player (M l. 51925–51931): spared 0x6e6, 0x709, 0x712, 0x76c…0x775, 0x6f4, 0x753,
        // 0x754, 0x71f, 0, 1, 0x77b, 0x46a…0x46c; killed one outside each range and any other type — except 1, 0x6a9
        // and 0x6d6, which this Kill never takes (M l. 51934–51936).
        for (type, killed) in [(Int16(0x6e6), false), (0x709, false), (0x712, false), (0x76b, true), (0x76c, false),
                               (0x775, false), (0x776, true), (0x6f4, false), (0x753, false), (0x754, false),
                               (0x71f, false), (0, false), (1, false), (0x77b, false), (0x469, true), (0x46a, false),
                               (0x46c, false), (0x46d, true), (0x6a9, false), (0x6d6, false), (0x6a5, true)] {
            let k = try XCTUnwrap(EnemyShot.spawn(w, type: type, x: 300, y: 120, layer: 9))
            EnemyShot.hit(w, shot: k, other: pid, lights: &lights, effects: 1)
            XCTAssertEqual(try slot(w, k).dead, killed, "type \(type)")
        }
        // A player shot kills 0x6e1 / 0x6e2 / 0x753 (M l. 51927–51928); a Box spout does not eat its own bomb
        // (Boxes 0x5aa…0x5b3 are left out, M l. 51942–51944).
        let ps = try XCTUnwrap(PlayerShot.spawn(w, type: 0x0001, x: 0, y: 0))
        let b2 = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6e2, x: 300, y: 120, layer: 9))
        EnemyShot.hit(w, shot: b2, other: ps, lights: &lights, effects: 1)
        XCTAssertTrue(try slot(w, b2).dead)
        for (type, killed) in [(Int16(0x6e1), true), (0x753, true), (0x712, false), (0x6e6, false)] {
            let k = try XCTUnwrap(EnemyShot.spawn(w, type: type, x: 300, y: 120, layer: 9))
            EnemyShot.hit(w, shot: k, other: ps, lights: &lights, effects: 1)
            XCTAssertEqual(try slot(w, k).dead, killed, "type \(type) vs a player shot")
        }
        let spout = try XCTUnwrap(w.newSprite(type: 0x5aa, x: 300, y: 120, layer: 10, handler: .box))
        let b3 = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6e2, x: 300, y: 120, layer: 9))
        EnemyShot.hit(w, shot: b3, other: spout, lights: &lights, effects: 1)
        XCTAssertFalse(try slot(w, b3).dead)
        let box = try XCTUnwrap(w.newSprite(type: 0x424, x: 300, y: 120, layer: 10, handler: .box))
        EnemyShot.hit(w, shot: b3, other: box, lights: &lights, effects: 1)
        XCTAssertTrue(try slot(w, b3).dead, "a solid Box outside 0x5aa…0x5b3 with no one-way top kills it")
        // The range's ends (M l. 51942–51944), a Statue, a wall-passing shot (`+0x16c`), a shard (never by this arm).
        // A Box with a one-way top or a surface function (`+0x185`, `+0x1e8`) kills only on a `.PlatformBounce`
        // contact — none for a shot far from it (M l. 51946–51960).
        func versus(_ type: Int16, _ handler: SpriteHandler, shot: Int16 = 0x6e2, oneWay: Bool = false,
                    rope: Bool = false, passes: Int32 = 0, x: Int = 300) throws -> Bool {
            let o = try XCTUnwrap(w.newSprite(type: type, x: x, y: 120, layer: 10, handler: handler))
            w.active.update(id: o) { $0.oneWay = oneWay; $0.rope = rope ? RopeBlock() : nil }
            let k = try XCTUnwrap(EnemyShot.spawn(w, type: shot, x: 300, y: 120, layer: 9))
            w.active.update(id: k) { $0.classWord16c = passes }
            EnemyShot.hit(w, shot: k, other: o, lights: &lights, effects: 1)
            return try slot(w, k).dead
        }
        XCTAssertEqual(try [versus(0x5a9, .box), versus(0x5b3, .box), versus(0x5b4, .box), versus(0x424, .statue),
                            versus(0x424, .box, passes: 1), versus(0x424, .box, shot: 0x6e6),
                            versus(0x424, .box, oneWay: true, x: 3000), versus(0x424, .box, rope: true, x: 3000)],
                       [true, false, true, true, false, false, false, false])
        // A Pentashield orb (a player shot 0x50) against an enemy shot (`.HitPlayerShotSprite` M l. 50997–51001):
        // `.STPlay3DSound(303, 1, 0x55, other +0xe)`, `.KillPlayerShot(orb, 1, 1)`, `.KillEnemyShot(other)`. A spout
        // bomb (layer 10) before an orb (11): its own Hit splits it, then the orb's splits it again
        // (enemy-shots-and-damage-2 §4.3) — the one double split.
        let orb = try XCTUnwrap(PlayerShot.spawn(w, type: Pentashield.spawnType, x: 300, y: 120))
        let b4 = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6e2, x: 300, y: 120, layer: 10))
        w.active.update(id: b4) { $0.centre = SpriteSlot.Point(x: 316, y: 136) }
        let shards0 = shots(w, 0x6e6).count
        var r2 = w.rng
        let n1 = Int(r2.next(3)) + 3
        for i in 1...n1 { _ = (r2.next(16), r2.next(16), r2.next(5), r2.next(Int16(200 * i)), r2.next(Int16(200 * i))) }
        EnemyShot.hit(w, shot: b4, other: orb, lights: &lights, effects: 1)
        XCTAssertEqual(shots(w, 0x6e6).count - shards0, n1)
        w.player.cues = []
        var r4 = w.rng
        let orbRate = r4.soundRate()
        let o0 = try slot(w, orb)                                            // the Cleanup's centre (`+0xe`) first
        let orbCentre = SpriteSlot.Point(x: o0.x + o0.hotRect.left + ((o0.hotRect.right - o0.hotRect.left) >> 1),
                                         y: o0.y + o0.hotRect.top + ((o0.hotRect.bottom - o0.hotRect.top) >> 1))
        PlayerShotHits.hit(w, shot: orb, other: b4, effects: 1, lights: &lights)
        XCTAssertGreaterThan(shots(w, 0x6e6).count - shards0, n1, "split twice")
        // `.KillPlayerShot(orb, 1, 1)`: with hits left the orb's snd 423 (`STPlay3DSoundRand`, the sound flag 1).
        XCTAssertEqual(Array(w.player.cues.prefix(2)), [
            PlayerCue(call: .threeD, snd: 303, priority: 1, volume: 0x55, position: SpriteSlot.Point(x: 316, y: 136)),
            PlayerCue(call: .threeDRand, snd: 423, priority: 1, volume: 0x100, position: orbCentre, rate: orbRate),
        ])
        XCTAssertEqual(try slot(w, orb).stackX, 2, "one of the orb's three hits")
        // The Chief's boulder against a player shot: snd 303 vol 0xab, `.KillPlayerShot(s, 0, 1)` (M l. 50991–50994).
        let ps2 = try XCTUnwrap(PlayerShot.spawn(w, type: 0x0001, x: 0, y: 0))
        let rock = try XCTUnwrap(EnemyShot.spawn(w, type: 0x77b, x: 300, y: 120, layer: 5))
        w.player.cues = []
        PlayerShotHits.hit(w, shot: ps2, other: rock, effects: 1, lights: &lights)
        // The sound flag 0: snd 303 only — no 301 from `.KillPlayerShot`.
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeD, snd: 303, priority: 1, volume: 0xab,
                                                 position: try slot(w, rock).centre)])
        XCTAssertTrue(try slot(w, ps2).dead)
        XCTAssertFalse(try slot(w, rock).dead)
        // A spring kills an enemy shot (`.HitBackgroundSprite` l. 63721–63723) — the bomb explodes, no launch; a cannon
        // never captures one (its Handle is excluded, l. 63684).
        let spring = try XCTUnwrap(w.newSprite(type: 0x47e, x: 300, y: 120, layer: 1, handler: .background))
        let b5 = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6e2, x: 300, y: 120, layer: 9))
        BackgroundSprite.hit(w, id: spring, other: b5, lights: &lights)
        XCTAssertTrue(try slot(w, b5).dead)
        XCTAssertEqual(try slot(w, spring).phase, 0)
        let cannon = try XCTUnwrap(w.newSprite(type: 0x442, x: 300, y: 120, layer: 1, handler: .background))
        let b6 = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6e1, x: 300, y: 120, layer: 9))
        BackgroundSprite.hit(w, id: cannon, other: b6, lights: &lights)
        XCTAssertEqual(try slot(w, b6).handler, .enemyShot)
        XCTAssertNil(try slot(w, b6).cannon)
        // The egg-bomb 0x753 (M l. 51512–51520, 51765–51785, 52040–52070): rect (4, 0, 0x14, 0xe), HP 0x1c0, `+0x46` 6,
        // `+0x17e = R(100) > 0x32`, fuse `+0x15c` 0xf0. Each Handle: gravity 0x100, the single face, `+0x46` − 1 (at 0
        // the flash `+0xaa = 5` and 0x2d), the fuse − 1, vx = (int)(vx · 0.9) (f64 `0x100a1a58`), grounded → vx 0.
        func eggSeed(_ want: Int16) -> Int32 {
            var seed: Int32 = 1
            while true {
                var q = FastRand(seed: seed)
                _ = q.next(5)
                if q.next(100) == want { return seed }
                seed += 1
            }
        }
        for (roll, mirrored) in [(Int16(0x32), false), (0x33, true)] {
            w.rng = FastRand(seed: eggSeed(roll))
            let e = try XCTUnwrap(EnemyShot.spawn(w, type: 0x753, x: 300, y: 100, layer: 0))
            XCTAssertEqual(try slot(w, e).mirrored, mirrored, "R(100) = \(roll)")
        }
        let egg = try XCTUnwrap(EnemyShot.spawn(w, type: 0x753, x: 300, y: 100, layer: 0))
        var e0 = try slot(w, egg)
        XCTAssertEqual([Int(e0.hp), Int(e0.phase), Int(e0.classWord15c)], [0x1c0, 6, 0xf0])
        XCTAssertEqual(e0.hotRect, IdleSprites.Rect(top: 0, left: 4, bottom: 0xe, right: 0x14))
        let solver = TileSolver(world: w)
        var lt = LightTable()
        w.active.update(id: egg) { $0.vx = 0x200 }
        EnemyShot.handle(world: w, id: egg, solver: solver, lights: &lt, effects: 1)
        e0 = try slot(w, egg)
        XCTAssertEqual([Int(e0.gravity), Int(e0.vx), Int(e0.phase), Int(e0.classWord15c)], [0x100, 460, 5, 0xef])
        XCTAssertEqual(e0.face, FaceRef(pict: 0x753, index: 0, set: .encoded))
        for _ in 0..<5 { EnemyShot.handle(world: w, id: egg, solver: solver, lights: &lt, effects: 1) }
        XCTAssertEqual([Int(try slot(w, egg).phase), Int(try slot(w, egg).flash)], [0x2d, 5])
        // The arm runs before `.ApplyGravityAndSeparateFromTiles` clears `+0xce`: last frame's ground stops the roll.
        w.active.update(id: egg) { $0.vx = 0x200; $0.groundKind = 1 }
        EnemyShot.handle(world: w, id: egg, solver: solver, lights: &lt, effects: 1)
        XCTAssertEqual(try slot(w, egg).vx, 0)
        // Its contact (M l. 52136–52146): the bounce (restitution 0xa0), then |vy| < 300 → vx = vy = 0, gravity 0x200;
        // no budget, no kill. A fall at 479 rebounds to −299 and stops; at 480 to −300 and goes on.
        for (vy, stops) in [(Int32(479), true), (480, false)] {
            let e = try XCTUnwrap(EnemyShot.spawn(w, type: 0x753, x: 0, y: 0, layer: 0))
            intoFloor(w, e, vy: vy, vx: 0x80)
            tile(w, e, solver)
            let q = try slot(w, e)
            XCTAssertEqual([q.vx, q.vy, Int32(q.gravity), q.bounceCount], stops ? [0, 0, 0x200, 0] : [0x80, -300, 0xaf, 0],
                           "vy \(vy)")
            XCTAssertFalse(q.dead)
        }
        // The fuse: `.KillEnemyShot` inside the Handle — snd 435, the Effect 0x4b7 at (x − 0x2a, y − 0x2a), eight smoke
        // puffs 0x442, each after its Setup's 45 sparks: R(0x96) (the push) and `+0x46 = R(7)` (M l. 52049–52059).
        w.active.update(id: egg) { $0.classWord15c = 1; $0.vx = 0; $0.vy = 0; $0.gravity = 0 }
        let big0 = w.active.sprites.filter { $0.handler == .effect && $0.type == EffectSprite.bigExplosion }.count
        let smoke0 = w.active.sprites.filter { $0.handler == .effect && $0.type == EffectSprite.smoke }.count
        let smokeIDs = Set(w.active.sprites.filter { $0.handler == .effect && $0.type == EffectSprite.smoke }.map(\.id))
        w.player.cues = []
        let ex = try slot(w, egg)
        var r5 = w.rng
        _ = r5.soundRate()
        for _ in 0..<0x2d { _ = (r5.next(2000), r5.next(2000), r5.next(2)) }      // the 0x4b7's sparks
        var puffs: [Int16] = []
        for _ in 0..<8 {
            for _ in 0..<0x2d { _ = (r5.next(2000), r5.next(2000), r5.next(2)) }  // the 0x442's (no plume, no light)
            _ = r5.next(0x96)
            puffs.append(r5.next(7))
        }
        EnemyShot.handle(world: w, id: egg, solver: solver, lights: &lt, effects: 1)
        XCTAssertTrue(try slot(w, egg).dead)
        XCTAssertEqual(w.rng.seed, r5.seed)
        XCTAssertEqual(w.active.sprites.filter { $0.handler == .effect && $0.type == EffectSprite.smoke
                                                 && !smokeIDs.contains($0.id) }.map(\.phase), puffs)
        XCTAssertEqual(w.player.cues.first?.snd, 435)
        let bigs = w.active.sprites.filter { $0.handler == .effect && $0.type == EffectSprite.bigExplosion }
        XCTAssertEqual(bigs.count, big0 + 1)
        XCTAssertEqual(bigs.last.map { [$0.x, $0.y] }, [ex.x - 0x2a, ex.y - 0x2a])
        XCTAssertEqual(w.active.sprites.filter { $0.handler == .effect && $0.type == EffectSprite.smoke }.count,
                       smoke0 + 8)
    }

    func testShardHurtsOnlyYoung() throws {
        // 0x6e6: rect (6, 6, 10, 10), gravity 0xaf (M l. 51488–51490); the Handle adds 1 to `+0x164` a frame (M l.
        // 51706–51708). Step 7 returns for `+0x164 ≥ 2` (M l. 49816–49818) — no hurt, no draw, the shard not killed;
        // younger it hurts 0x38 (no coin draw) and is killed (M l. 49920).
        let (w, pid) = try world()
        let p = try slot(w, pid)
        let solver = TileSolver(world: w)
        let s = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6e6, x: p.x, y: p.y, layer: 10))
        XCTAssertEqual(try slot(w, s).hotRect, IdleSprites.Rect(top: 6, left: 6, bottom: 10, right: 10))
        XCTAssertEqual(try slot(w, s).gravity, 0xaf)
        frame(w, s, solver)
        XCTAssertEqual(try slot(w, s).shardAge, 1)
        XCTAssertEqual(try slot(w, s).face?.pict, 0x6e6)
        frame(w, s, solver)
        XCTAssertEqual(try slot(w, s).shardAge, 2)
        let seed = w.rng.seed
        HitPlayerSprite.hit(w, player: pid, other: s)
        XCTAssertEqual(try slot(w, pid).hp, 1000)
        XCTAssertEqual(w.rng.seed, seed)
        XCTAssertFalse(try slot(w, s).dead)
        // Its own Hit never kills it against the player (0x6e6 is excluded, M l. 51922).
        var lights = LightTable()
        EnemyShot.hit(w, shot: s, other: pid, lights: &lights, effects: 1)
        XCTAssertFalse(try slot(w, s).dead)
        let young = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6e6, x: p.x, y: p.y, layer: 10))
        frame(w, young, solver)
        XCTAssertEqual(try slot(w, young).shardAge, 1)
        HitPlayerSprite.hit(w, player: pid, other: young)
        XCTAssertEqual([Int(try slot(w, pid).hp), Int(try slot(w, pid).invulnerable)], [1000 - 0x38, 0x3c])
        XCTAssertTrue(try slot(w, young).dead)
    }

    func testFrogSpitTintDead() throws {
        // 0x709's first Setup arm (M l. 51491–51494): gravity 0, rect (8, 3, 0xf, 0xc) — the later `+0xa4 = 0x38` arm
        // (M l. 51522–51525) is unreachable, so HP stays 0 and the Frog's tint multipliers (×2 / ×4 / ×3 on `+0xa4`)
        // multiply 0. Step 7 never reads `+0xa4` for 0x709: 0x38 whatever it holds; an EnemyShot with HP < 1 still hurts
        // (`.HurtPlayer` M l. 47983). The Handle faces 0x455 for vx ≤ 0, 0x454 for vx > 0 and leaves the tint.
        let (w, pid) = try world()
        let solver = TileSolver(world: w)
        for (hp, vx, pict) in [(Int16(0), Int32(-2000), Int16(0x455)), (0x1c0, 2000, 0x454)] {
            let id = try XCTUnwrap(EnemyShot.spawn(w, type: 0x709, x: 300, y: 100, layer: 5))
            var s = try slot(w, id)
            XCTAssertEqual([Int(s.gravity), Int(s.hp)], [0, 0])
            XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 3, left: 8, bottom: 0xc, right: 0xf))
            w.active.update(id: id) { t in
                t.vx = vx
                t.mode = 0x1000c
                t.hp = hp
            }
            frame(w, id, solver)
            s = try slot(w, id)
            XCTAssertEqual(s.face?.pict, pict)
            XCTAssertEqual(s.mode, 0x1000c)
            w.active.update(id: pid) { $0.hp = 1000; $0.invulnerable = 0 }
            let seed = w.rng.seed
            HitPlayerSprite.hit(w, player: pid, other: id)
            XCTAssertEqual(try slot(w, pid).hp, 1000 - 0x38, "HP \(hp)")
            XCTAssertNotEqual(w.rng.seed, seed, "the hurt's own draws")
            XCTAssertTrue(try slot(w, id).dead)
        }
        // The face test is vx < 1 (M l. 51742–51760): vx 0 takes 0x455 / 0x457, vx 1 0x454 / 0x456.
        for (type, vx, pict) in [(Int16(0x709), Int32(0), Int16(0x455)), (0x709, 1, 0x454), (0x712, 0, 0x457),
                                 (0x712, 1, 0x456)] {
            let id = try XCTUnwrap(EnemyShot.spawn(w, type: type, x: 300, y: 100, layer: 5))
            w.active.update(id: id) { $0.vx = vx }
            frame(w, id, solver)
            XCTAssertEqual(try slot(w, id).face?.pict, pict, "type \(type) vx \(vx)")
        }
        // An EnemyShot 0x77b with `+0x14c ≠ 0` is passed over (M l. 49810–49812; no code writes it — enemy-shots-and-
        // damage-2 §4.1); the test is the EnemyShot Handle's: another Handle's 0x77b with it set still hurts 0x70.
        w.active.update(id: pid) { $0.hp = 1000; $0.invulnerable = 0 }
        let held = try XCTUnwrap(EnemyShot.spawn(w, type: 0x77b, x: 300, y: 100, layer: 5))
        w.active.update(id: held) { $0.classTimer = 1; $0.vx = -2000 }
        HitPlayerSprite.hit(w, player: pid, other: held)
        XCTAssertEqual([Int(try slot(w, pid).hp), Int(try slot(w, held).vx), try slot(w, held).dead ? 1 : 0], [1000, -2000, 0])
        let other = try XCTUnwrap(w.newSprite(type: 0x77b, x: 300, y: 100, layer: 5, handler: .walker) { $0.hp = 100 })
        w.active.update(id: other) { $0.classTimer = 1 }
        HitPlayerSprite.hit(w, player: pid, other: other)
        XCTAssertEqual(try slot(w, pid).hp, 1000 - 0x70)
        // The rest of step 7's type table (M l. 49852–49891): 0x46a 0x70, 0x46c 0xa8 (5 coins, no draw), 0x6f4 0x70,
        // 0x71f 0x70, 0x753 / 0x754 / 0x771…0x774 their `+0xa4`, 0x775 0x38, 0x77b 0x70. A landed hurt zeroes the stagger
        // `_DAT_100a0570` (M l. 49910–49912); every shot but 0x77b is killed, landed or not; 0x77b: `+0x15c = 1`, vx ×
        // −0.15 (f64 `0x100a1a00`), gravity < 1 → 0x15e (M l. 49913–49926).
        for (type, hp, damage) in [(Int16(0x46a), Int16(0), 0x70), (0x46c, 0, 0xa8), (0x6f4, 0, 0x70), (0x71f, 0, 0x70),
                                   (0x753, 0x1c0, 0x1c0), (0x754, 0xe0, 0xe0), (0x771, 0x50, 0x50), (0x774, 0x60, 0x60),
                                   (0x775, 0x90, 0x38), (0x6a5, 0x90, 0x38), (0x77b, 0, 0x70)] {
            let id = try XCTUnwrap(EnemyShot.spawn(w, type: type, x: 300, y: 100, layer: 5))
            w.active.update(id: id) { t in
                t.hp = hp
                t.gravity = 0
                t.vx = 1000
            }
            w.active.update(id: pid) { $0.hp = 1000; $0.invulnerable = 0 }
            w.player.bossGrab = 5
            HitPlayerSprite.hit(w, player: pid, other: id)
            XCTAssertEqual(Int(try slot(w, pid).hp), 1000 - damage, "type \(type)")
            XCTAssertEqual(w.player.bossGrab, 0, "type \(type)")
            let s = try slot(w, id)
            if type == 0x77b {
                XCTAssertFalse(s.dead)
                XCTAssertEqual([s.classWord15c, s.vx, Int32(s.gravity)], [1, -150, 0x15e])   // 1000 · −0.15
            } else {
                XCTAssertTrue(s.dead, "type \(type)")
            }
        }
        // Not landed (Ferazel invulnerable): the stagger is kept, the shot still killed; a 0x77b already falling keeps
        // its gravity.
        w.active.update(id: pid) { $0.invulnerable = 10 }
        w.player.bossGrab = 5
        let late = try XCTUnwrap(EnemyShot.spawn(w, type: 0x712, x: 300, y: 100, layer: 5))
        HitPlayerSprite.hit(w, player: pid, other: late)
        XCTAssertEqual(w.player.bossGrab, 5)
        XCTAssertTrue(try slot(w, late).dead)
        let rock = try XCTUnwrap(EnemyShot.spawn(w, type: 0x77b, x: 300, y: 100, layer: 5))
        w.active.update(id: rock) { $0.vx = -2000 }
        HitPlayerSprite.hit(w, player: pid, other: rock)
        XCTAssertEqual([try slot(w, rock).vx, Int32(try slot(w, rock).gravity)], [300, 0x140])
    }

    func testWraithHoming() throws {
        // 0x6f4 (M l. 51502–51511): R(5), then R(0xf) the phase, rect (5, 5, 0x12, 0xc), gravity 0, HP 0x70, `+0x88` 0.
        // The Handle (M l. 51711–51734): `+0xa6` + 1 first, then the tint by `+0xa6` (< 3 0xb0002, < 5 0xb0000, < 7
        // 0xb0001, else 0) and, while `+0xa6 < 0x14`, `FUN_1003f218(s, .FindDesiredDirectionGeneric((pcy + 8, pcx),
        // (y + 0xc, x + 0xc)), 0x8c)` — 19 impulses (ages 1…19), then it coasts. The player straight left (same v):
        // direction 0 → vx − 0x8c each.
        let (w, _) = try world()
        w.player.centreX = 100
        w.player.centreY = 200
        var r = w.rng
        _ = r.next(5)
        let ph = r.next(0xf)
        let id = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6f4, x: 500, y: 196, layer: 0))
        XCTAssertEqual(w.rng.seed, r.seed)
        var s = try slot(w, id)
        XCTAssertEqual(s.phase, ph)
        XCTAssertEqual([Int(s.gravity), Int(s.hp), s.lightOverlay ? 1 : 0], [0, 0x70, 0])
        XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 5, left: 5, bottom: 0xc, right: 0x12))
        let solver = TileSolver(world: w)
        var p = ph
        for n in 1...30 {
            s = try slot(w, id)
            XCTAssertEqual(BloodSpray.direction(target: (v: 208, h: 100),
                                                from: (v: Int16(s.y + 0xc), h: Int16(s.x + 0xc))), 0, "frame \(n)")
            frame(w, id, solver)
            s = try slot(w, id)
            XCTAssertEqual(s.vx, -0x8c * Int32(min(n, 19)), "frame \(n)")
            XCTAssertEqual(s.vy, 0)
            XCTAssertEqual(s.mode, n < 3 ? 0xb0002 : n < 5 ? 0xb0000 : n < 7 ? 0xb0001 : 0, "frame \(n)")
            p += 1
            if 0xe < p { p = 0 }
            XCTAssertEqual(s.face, FaceRef(pict: 0x45d, index: Int(p), set: .encoded))
        }
    }

    // MARK: - the shield

    func testShieldBlockReflectsDart() throws {
        // `.ShieldBlock` (M l. 48376–48441): ax = shot `+0x10` − (vx >> 8); side 2 when ax > player x + rect right − 10,
        // side 1 when ax < player x + rect left + 10; blocks when the side is the facing `_DAT_100a5f5a`, the counter
        // `PTR_DAT_100a05e8` > 2 and the shot runs the EnemyShot Handle: the counter = 7. A dart 0x76c…0x775 / spine
        // 0x754: `.STPlay3DSound(303, 1, 0x100, player +0xe)`; the Magical Shield → `+0x1a2 = 1`; vx, vy × −0.38 (f64
        // `0x100a1a18` = 0xbfd851eb851eb852, `fctiwz`), vy − 0x5dc, gravity 0x100.
        let (w, pid) = try world()
        var lights = LightTable()
        let pc = try slot(w, pid).centre
        w.player.facing = 2
        w.player.shieldRaise = 3
        let d = try shotBeside(w, pid, 0x772, dx: 20, vx: -0x1000, vy: 0x80)
        XCTAssertTrue(EnemyShot.shieldBlock(w, player: pid, shot: d, lights: &lights, effects: 1))
        XCTAssertEqual(w.player.shieldRaise, 7)
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeD, snd: 303, priority: 1, volume: 0x100, position: pc)])
        var s = try slot(w, d)
        XCTAssertEqual([s.vx, s.vy], [1556, -48 - 1500])               // −4096·−0.38 = 1556.48; 128·−0.38 = −48.64
        XCTAssertEqual([Int(s.gravity), Int(s.burnRow)], [0x100, 0])
        XCTAssertFalse(s.dead)
        // Reflected (gravity > 0) it is harmless: step 7 returns before the shield (M l. 49806–49809).
        w.player.shieldRaise = 3
        let seed = w.rng.seed
        HitPlayerSprite.hit(w, player: pid, other: d)
        XCTAssertEqual([Int(try slot(w, pid).hp), Int(w.player.shieldRaise)], [1000, 3])
        XCTAssertEqual(w.rng.seed, seed)
        XCTAssertFalse(try slot(w, d).dead)
        // Not blocked: the wrong facing, the counter ≤ 2, the shot on the other side.
        for (facing, raise, dx) in [(Int16(1), Int16(3), 20), (2, 2, 20), (2, 3, -20)] {
            w.player.facing = facing
            w.player.shieldRaise = raise
            w.player.cues = []
            let e = try shotBeside(w, pid, 0x772, dx: dx, vx: -0x1000)
            XCTAssertFalse(EnemyShot.shieldBlock(w, player: pid, shot: e, lights: &lights, effects: 1))
            XCTAssertEqual(w.player.shieldRaise, raise)
            XCTAssertEqual(w.player.cues, [])
            XCTAssertEqual(try slot(w, e).vx, -0x1000)
        }
        // The side test is strict: ax = player x + rect right − 10 is no side; one more is side 2.
        // (The rect is 0x26…0x3e wide, so right − 10 is right of left + 10.)
        w.player.facing = 2
        let pr = try slot(w, pid)
        for (dx, blocked) in [(-10, false), (-9, true)] {
            w.player.shieldRaise = 3
            let e = try shotBeside(w, pid, 0x772, dx: 0, vx: 0)
            w.active.update(id: e) { $0.centre.x = pr.x + pr.hotRect.right + dx }
            XCTAssertEqual(EnemyShot.shieldBlock(w, player: pid, shot: e, lights: &lights, effects: 1), blocked, "dx \(dx)")
        }
        // ax takes the shot's speed off (M l. 48380: `+0x10 − (+0x24 >> 8)`, arithmetic): at right − 10, vx −0x100 and
        // −0xff (>> 8 = −1) put ax one past the edge; at right − 9 vx 0x100 and at right − 11 vx −0x100 put it on it.
        for (dx, vx, blocked) in [(-10, Int32(-0x100), true), (-10, -0xff, true), (-9, 0x100, false), (-11, -0x100, false)] {
            w.player.shieldRaise = 3
            let e = try shotBeside(w, pid, 0x772, dx: 0, vx: vx)
            w.active.update(id: e) { $0.centre.x = pr.x + pr.hotRect.right + dx }
            XCTAssertEqual(EnemyShot.shieldBlock(w, player: pid, shot: e, lights: &lights, effects: 1), blocked,
                           "dx \(dx) vx \(vx)")
        }
        // The left side, facing left, is strict too (M l. 48385: ax < player x + rect left + 10).
        w.player.facing = 1
        for (dx, blocked) in [(10, false), (9, true)] {
            w.player.shieldRaise = 3
            let e = try shotBeside(w, pid, 0x772, dx: 0, vx: 0)
            w.active.update(id: e) { $0.centre.x = pr.x + pr.hotRect.left + dx }
            XCTAssertEqual(EnemyShot.shieldBlock(w, player: pid, shot: e, lights: &lights, effects: 1), blocked, "dx \(dx)")
        }
        w.player.facing = 2
        // Facing left with the shot on the left: blocked (a spine 0x754 too).
        w.player.facing = 1
        w.player.shieldRaise = 6
        let sp = try shotBeside(w, pid, 0x754, dx: -20, vx: 0x900, vy: -0x900)
        XCTAssertTrue(EnemyShot.shieldBlock(w, player: pid, shot: sp, lights: &lights, effects: 1))
        s = try slot(w, sp)
        XCTAssertEqual([s.vx, s.vy, Int32(s.gravity)], [-875, 875 - 1500, 0x100])   // 2304·0.38 = 875.52
        // Not blocked, the dart hurts its `+0xa4` 0x38 and is killed (M l. 49862–49866, 49920).
        w.player.shieldRaise = 0
        let hurt = try shotBeside(w, pid, 0x771, dx: 20, vx: 0x1000)
        HitPlayerSprite.hit(w, player: pid, other: hurt)
        XCTAssertEqual(try slot(w, pid).hp, 1000 - 0x38)
        XCTAssertTrue(try slot(w, hurt).dead)
        // The Magical Shield: `+0x1a2 = 1` — it burns away from the next `.StandardSpriteCleanup`, and with no Kill
        // proc (`.SetupEnemyShotSprite` stores no `+0x50`) the burn's end is `+0xe9 = 1` only (M l. 38834–38838).
        giveShield(w)
        w.player.facing = 2
        w.player.shieldRaise = 3
        let m = try shotBeside(w, pid, 0x773, dx: 20, vx: -0x1000)
        XCTAssertTrue(EnemyShot.shieldBlock(w, player: pid, shot: m, lights: &lights, effects: 1))
        XCTAssertEqual(try slot(w, m).burnRow, 1)
        XCTAssertEqual(try slot(w, m).gravity, 0x100)
        let count = w.active.sprites.count
        EnemyCommon.killProc(w, id: m)
        XCTAssertTrue(try slot(w, m).dead)
        XCTAssertEqual(w.active.sprites.count, count)
        // The darts' maker, the trap 1901 (0x76d, fires left; `.HandleBackgroundSprite` M l. 63345–63507), armed (state
        // 0x11, `+0xa6` 0, half-width `+0x150` 50): the player inside the band and left of it → state 0x12, `+0xa6 = 8`,
        // the cell 5 mirrored; next frame snd 499 vol 0xab and the dart 0x772 at (x − 0x20, y + 0x2a), vx −0x1000.
        w.player.centreX = 100
        w.player.centreY = 300
        let trap = try XCTUnwrap(w.newSprite(type: 0x76d, x: 400, y: 260, layer: 1, handler: .background) { t in
            t.phase = 0x11
            t.classTimer = 45
            t.classWord150 = 50
            t.hotRect = IdleSprites.Rect(top: 32, left: 32, bottom: 60, right: 60)
        })
        w.active.update(id: trap) { t in
            t.x = 400
            t.y = 260
            t.centre = SpriteSlot.Point(x: 446, y: 306)
        }
        BackgroundSprite.handle(world: w, id: trap) { _ in 92 }
        var t = try slot(w, trap)
        XCTAssertEqual([Int(t.phase), Int(t.counterA6), t.face?.index ?? -1], [0x12, 8, 5])
        XCTAssertTrue(t.mirrored)
        w.player.cues = []
        let darts = shots(w, 0x772).count
        BackgroundSprite.handle(world: w, id: trap) { _ in 92 }
        t = try slot(w, trap)
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeD, snd: 499, priority: 1, volume: 0xab, position: t.centre)])
        let dart = try XCTUnwrap(shots(w, 0x772).last)
        XCTAssertEqual(shots(w, 0x772).count, darts + 1)
        XCTAssertEqual([dart.x, dart.y, Int(dart.vx), Int(dart.vy)], [400 - 0x20, 260 + 0x2a, -0x1000, 0])
        XCTAssertEqual([Int(t.phase), t.face?.index ?? -1], [0x13, 0])
        // 8 frames on, the reload `+0x14c` and state 0.
        for _ in 0..<8 { BackgroundSprite.handle(world: w, id: trap) { _ in 92 } }
        t = try slot(w, trap)
        XCTAssertEqual([Int(t.phase), Int(t.counterA6)], [0, 45])
        // In the band but right of a left-firing trap: no shot.
        w.active.update(id: trap) { $0.phase = 0x11; $0.counterA6 = 0 }
        w.player.centreX = 500
        BackgroundSprite.handle(world: w, id: trap) { _ in 92 }
        XCTAssertEqual(try slot(w, trap).phase, 0x11)
        w.player.centreX = 100
        // Out of the band: armed, no shot.
        w.active.update(id: trap) { $0.phase = 0x11; $0.counterA6 = 0 }
        w.player.centreY = 360
        BackgroundSprite.handle(world: w, id: trap) { _ in 92 }
        XCTAssertEqual(try slot(w, trap).phase, 0x11)
        // The band is strict both sides (M l. 63398–63403: cy − d < pcy < cy + d; cy 306, d 50) and the side strict
        // (pcx < cx 446): 256 / 356 and pcx 446 do not fire, 257 / 355 do.
        func fires(_ type: Int16, px: Int16, py: Int16) throws -> Bool {
            w.active.update(id: trap) { $0.type = type; $0.phase = 0x11; $0.counterA6 = 0 }
            w.player.centreX = px
            w.player.centreY = py
            BackgroundSprite.handle(world: w, id: trap) { _ in 92 }
            return try slot(w, trap).phase == 0x12
        }
        XCTAssertEqual(try [(Int16(100), Int16(256)), (100, 257), (100, 355), (100, 356), (446, 300), (445, 300)]
                        .map { try fires(0x76d, px: $0.0, py: $0.1) }, [false, true, true, false, false, true])
        // 0x76e (M l. 63376–63380): cx − d < pcx < cx + d and pcy ≤ cy + 0x23 (341); 0x76f (M l. 63411–63416): the
        // same band and pcy > cy.
        XCTAssertEqual(try [(Int16(396), Int16(300)), (397, 300), (495, 300), (496, 300), (446, 341), (446, 342)]
                        .map { try fires(0x76e, px: $0.0, py: $0.1) }, [false, true, true, false, true, false])
        XCTAssertEqual(try [(Int16(446), Int16(306)), (446, 307)].map { try fires(0x76f, px: $0.0, py: $0.1) },
                       [false, true])
        // The traps' Setup arm (`.SetupBackgroundSprite` M l. 62496–62520): after the common part, the cache marked,
        // `+0x46 = 0x10`; the live record's p1 0 → 0x2d and p2 0 → 0x32 written back; `+0x14c` = `+0xa6` = p1,
        // `+0x150` = p2; `SetRect(0x20, 0x20, 0x3c, 0x3c)`; both callbacks 0. The Handle's first call faces the cell
        // 0x10 >> 2 = 4 (`.handle`) and arms it.
        let ctx = SetupFaces.Context(level: w.level, playerX: 0)
        for (type, p1, p2, sheet) in [(Int16(0x76d), Int16(0), Int16(0), Int16(0x76c)), (0x76f, 30, 40, 0x76f)] {
            let rec = Placement(index: 5, flag: 0, byte1: 0, type: type, p1: p1, p2: p2, p3: 7, p4: 9, y: 300, x: 200)
            let e = try SetupFaces.setup(rec, context: ctx)
            let (q1, q2): (Int16, Int16) = p1 == 0 ? (0x2d, 0x32) : (p1, p2)
            XCTAssertEqual([e.record.p1, e.record.p2, e.record.p3, e.record.p4], [q1, q2, 7, 9])
            XCTAssertEqual([Int(e.slot.phase), Int(e.slot.classTimer), Int(e.slot.counterA6), Int(e.slot.classWord150),
                            Int(e.slot.layer), Int(e.slot.hp)], [0x10, Int(q1), Int(q1), Int(q2), 1, 6])
            XCTAssertEqual(e.slot.hotRect, IdleSprites.Rect(top: 0x20, left: 0x20, bottom: 0x3c, right: 0x3c))
            XCTAssertEqual([e.slot.hasHit, e.slot.hasTileHit, e.slot.handler == .background], [false, false, true])
            XCTAssertEqual([e.source == .handle ? 1 : 0, e.faceIndex, Int(e.sheet?.pict ?? 0), e.sheet?.count ?? 0,
                            e.sheet?.cellWidth ?? 0, e.sheet?.cellHeight ?? 0], [1, 4, Int(sheet), 6, 0x5c, 0x5c])
        }
        XCTAssertEqual([CachedFaces.marks(type: 0x76c).sets, CachedFaces.marks(type: 0x76d).sets,
                        CachedFaces.marks(type: 0x76e).sets, CachedFaces.marks(type: 0x76f).sets],
                       [[0x76c], [0x76c], [0x76e], [0x76f]])
    }

    func testShieldBlockKillsOthers() throws {
        // Every other shot: snd 303 then `.KillEnemyShot` (M l. 48401–48404) — 0x712 adds `.STPlay3DSoundRand(301, 1,
        // 0x100, +0xe)` and the Effect 0 at (x − 8, y − 0xc) (M l. 52034–52039). Blocked → step 7 returns: no hurt.
        let (w, pid) = try world()
        let pc = try slot(w, pid).centre
        w.player.facing = 2
        w.player.shieldRaise = 3
        let spit = try shotBeside(w, pid, 0x712, dx: 20, vx: -0x708)
        let sc = try slot(w, spit)
        var r = w.rng
        let rate = r.soundRate()
        HitPlayerSprite.hit(w, player: pid, other: spit)
        XCTAssertEqual(try slot(w, pid).hp, 1000)
        XCTAssertEqual(w.player.shieldRaise, 7)
        XCTAssertTrue(try slot(w, spit).dead)
        XCTAssertEqual(w.player.cues, [
            PlayerCue(call: .threeD, snd: 303, priority: 1, volume: 0x100, position: pc),
            PlayerCue(call: .threeDRand, snd: 301, priority: 1, volume: 0x100, position: sc.centre, rate: rate),
        ])
        XCTAssertEqual(w.active.sprites.filter { $0.handler == .effect && $0.type == 0 }.map { [$0.x, $0.y] },
                       [[sc.x - 8, sc.y - 0xc]])
        // The Wraith shot without the Magical Shield: killed (its particles need a face; none here).
        w.player.shieldRaise = 3
        w.player.cues = []
        let wr = try shotBeside(w, pid, 0x6f4, dx: 20, vx: -0x300)
        var lights = LightTable()
        XCTAssertTrue(EnemyShot.shieldBlock(w, player: pid, shot: wr, lights: &lights, effects: 1))
        XCTAssertTrue(try slot(w, wr).dead)
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeD, snd: 303, priority: 1, volume: 0x100, position: pc)])
        // A non-shot attacker is never blocked (the whole body is gated on the EnemyShot Handle, M l. 48389): the
        // counter is left, the Walker's 0x70 lands.
        w.player.shieldRaise = 3
        w.player.cues = []
        let walker = try shotBeside(w, pid, 0x6a4, dx: 20, vx: -0x300, handler: .walker)
        XCTAssertFalse(EnemyShot.shieldBlock(w, player: pid, shot: walker, lights: &lights, effects: 1))
        XCTAssertEqual(w.player.shieldRaise, 3)
        XCTAssertEqual(w.player.cues, [])
        HitPlayerSprite.hit(w, player: pid, other: walker)
        XCTAssertEqual(try slot(w, pid).hp, 1000 - 0x70)
        XCTAssertEqual(w.player.shieldRaise, 3)
        XCTAssertFalse(try slot(w, walker).dead)
    }

    func testShieldReflectsWraithShot() throws {
        // 0x6f4 with `.HasItem(0xf)` (M l. 48384–48393): once (`+0x160 == 0`) snd 303, vx and vy negated, vy + 0x140,
        // `+0x160 = 1`, `.ExplodeFaceIntoParticles(+0xc0, +0xa, 1, 1, 1, 100, 0x65)` — not killed; again: only the
        // counter write.
        let (w, pid) = try world()
        giveShield(w)
        let pc = try slot(w, pid).centre
        func tok(_ op: UInt32, _ n: Int) -> [UInt8] {
            let t = op << 24 | UInt32(n)
            return [UInt8(t >> 24), UInt8(t >> 16 & 0xff), UInt8(t >> 8 & 0xff), UInt8(t & 0xff)]
        }
        let face = ParticleFace(frame: [0, 0, 1, 3], bounds: [0, 0, 1, 3],
                                tokens: tok(1, 8) + tok(2, 3) + [10, 11, 12, 0] + tok(0, 0))
        w.particleFaces = ParticleFaces(sprite: { _ in face })
        w.player.facing = 2
        w.player.shieldRaise = 3
        var lights = LightTable()
        let wr = try shotBeside(w, pid, 0x6f4, dx: 20, vx: -0x300, vy: 0x100)
        w.active.update(id: wr) { $0.face = FaceRef(pict: 0x45d, index: 0, set: .encoded) }
        /// The particles made since `alive0`: [kind, gravity, shape, age].
        func made(since alive0: [Bool]) -> [[Int]] {
            w.particles.records.indices.filter { w.particles.records[$0].alive && !alive0[$0] }.map {
                let q = w.particles.records[$0]
                return [Int(q.kind), Int(q.gravity), Int(q.shape), Int(q.age)]
            }
        }
        /// Style 0x65 (`.ExplodeFaceIntoParticles` per pixel px: R(0x3c), R(0x3c), R(0x10), R(0xc) → kind −(px + 0x100),
        /// gravity g + R(0xc), age 0x68 − R(0x10)) for `pixels`, shape 1.
        func style65(_ r: inout FastRand, _ pixels: [Int], gravity g: Int) -> [[Int]] {
            pixels.map { px in
                _ = (r.next(0x3c), r.next(0x3c))
                let r16 = Int(r.next(0x10)), r12 = Int(r.next(0xc))
                return [-(px + 0x100), g + r12, 1, 0x68 - r16]
            }
        }
        var r = w.rng
        let want = style65(&r, [10, 11, 12], gravity: 100)                          // (…, 1, 1, 1, 100, 0x65)
        let p0 = w.particles.counters.count
        let alive0 = w.particles.records.map(\.alive)
        XCTAssertTrue(EnemyShot.shieldBlock(w, player: pid, shot: wr, lights: &lights, effects: 1))
        XCTAssertEqual(made(since: alive0), want)
        var s = try slot(w, wr)
        XCTAssertEqual([s.vx, s.vy, s.classWord160], [0x300, -0x100 + 0x140, 1])
        XCTAssertFalse(s.dead)
        XCTAssertEqual(w.player.shieldRaise, 7)
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeD, snd: 303, priority: 1, volume: 0x100, position: pc)])
        XCTAssertEqual(w.particles.counters.count - p0, 3)
        XCTAssertEqual(w.rng.seed, r.seed)
        // A second block: the counter only.
        w.player.shieldRaise = 3
        w.player.cues = []
        w.active.update(id: wr) { $0.vx = -0x300 }
        let seed = w.rng.seed
        XCTAssertTrue(EnemyShot.shieldBlock(w, player: pid, shot: wr, lights: &lights, effects: 1))
        s = try slot(w, wr)
        XCTAssertEqual([s.vx, s.vy, s.classWord160], [-0x300, 0x40, 1])
        XCTAssertEqual(w.player.shieldRaise, 7)
        XCTAssertEqual(w.player.cues, [])
        XCTAssertEqual(w.rng.seed, seed)
        XCTAssertFalse(s.dead)
        // Without the item: killed (`.KillEnemyShot` 0x6f4: particles (…, 1, 1, 1, 0, 0x65), `+0xe9 = 1`).
        w.globals.inventory[0] = InventorySlot(id: 0, count: 0, field4: 0, field6: 0, isSpell: 0)
        w.player.shieldRaise = 3
        let wr2 = try shotBeside(w, pid, 0x6f4, dx: 20, vx: -0x300)
        // Two rows of three: every row and pixel taken (steps 1, 1). 0x6f4: gravity 0, style 0x65 (M l. 52069–52072).
        let face2 = ParticleFace(frame: [0, 0, 2, 3], bounds: [0, 0, 2, 3],
                                 tokens: tok(1, 8) + tok(2, 3) + [10, 11, 12, 0] + tok(1, 8) + tok(2, 3) + [20, 21, 22, 0]
                                    + tok(0, 0))
        w.particleFaces = ParticleFaces(sprite: { _ in face2 })
        w.active.update(id: wr2) { $0.face = FaceRef(pict: 0x45d, index: 0, set: .encoded) }
        var r2 = w.rng
        let want2 = style65(&r2, [10, 11, 12, 20, 21, 22], gravity: 0)
        let alive2 = w.particles.records.map(\.alive)
        XCTAssertTrue(EnemyShot.shieldBlock(w, player: pid, shot: wr2, lights: &lights, effects: 1))
        XCTAssertTrue(try slot(w, wr2).dead)
        XCTAssertEqual(try slot(w, wr2).vx, -0x300)
        XCTAssertEqual(made(since: alive2), want2)
        XCTAssertEqual(w.rng.seed, r2.seed)
        // The darts and the spine (M l. 52086–52089): `+0xe9 = 1`, then (…, 1, 1, 1, 100, 100) — style 100 per pixel:
        // R(0x14), R(0x2ee), R(100), R(0x1e) → kind −(px + 0x100), gravity 100 + R(0x1e), age 0x62 − R(0x14).
        for type: Int16 in [0x754, 0x771] {
            let k = try XCTUnwrap(EnemyShot.spawn(w, type: type, x: 300, y: 100, layer: 0))
            w.active.update(id: k) { $0.face = FaceRef(pict: type, index: 0, set: .encoded) }
            var r3 = w.rng
            let want3: [[Int]] = [10, 11, 12, 20, 21, 22].map { px in
                let r20 = Int(r3.next(0x14))
                _ = (r3.next(0x2ee), r3.next(100))
                let r30 = Int(r3.next(0x1e))
                return [-(px + 0x100), 100 + r30, 1, 0x62 - r20]
            }
            let alive3 = w.particles.records.map(\.alive)
            EnemyShot.kill(w, shot: k, lights: &lights, effects: 1)
            XCTAssertTrue(try slot(w, k).dead)
            XCTAssertEqual(made(since: alive3), want3, "type \(type)")
            XCTAssertEqual(w.rng.seed, r3.seed)
        }
    }

    // MARK: - the spouts

    func testSpoutFiresWhenLinkedButtonPressed() throws {
        // Level 4 spout 28 (1450, p1 30, p2 31, p4 1). At `+0xa6` 0 with record[p1] or record[p2] p4 == 1 (M l.
        // 60488–60547; raw `1006e8f4..1006eb1c`): `MTNewSprite(0x6e1 + own p4, +0xc, +0xa, +0x80 − 1, −1,
        // .SetupEnemyShotSprite)` — its Setup's draws — then, only with a record (`or. r19,r3,r3; beq`), 1450: vx =
        // R(300) − 0x96, vy = R(400); then `+0xa6 = R(30) + 50`.
        let (w, _) = try world(level: 4)
        XCTAssertEqual([w.records[28].type, w.records[28].p1, w.records[28].p2, w.records[28].p4], [1450, 30, 31, 1])
        let spout = try SetupFaces.setup(w.records[28], context: SetupFaces.Context(level: w.level, playerX: 0)).slot
        let k = w.active.insert(spout)
        var lights = LightTable()
        let solver = TileSolver(world: w)
        func fire() { BoxSprite.handle(world: w, id: k, solver: solver, lights: &lights, effects: 1) }
        func setP4(_ i: Int, _ v: Int16) {
            let q = w.records[i]
            w.records[i] = Placement(index: q.index, flag: q.flag, byte1: q.byte1, type: q.type, p1: q.p1, p2: q.p2,
                                     p3: q.p3, p4: v, y: q.y, x: q.x)
        }
        let s0 = try slot(w, k)
        setP4(31, 1)
        var r = w.rng
        _ = r.next(5)
        var b = -2 - Int32(r.next(2))
        if 0x56 < r.next(100) { b -= 3 - Int32(r.next(5)) }
        let vx = Int32(r.next(300)) - 0x96, vy = Int32(r.next(400))
        let t = r.next(30) + 50
        fire()
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual(try slot(w, k).counterA6, t)
        let bomb = try XCTUnwrap(shots(w, 0x6e2).first)
        XCTAssertEqual(shots(w, 0x6e2).count, 1)
        XCTAssertEqual([bomb.x, bomb.y, Int(bomb.layer), Int(bomb.vx), Int(bomb.vy), Int(bomb.bounceCount)],
                       [s0.x, s0.y, Int(s0.layer) - 1, Int(vx), Int(vy), Int(b)])
        XCTAssertEqual(bomb.x256, Int32(s0.x) << 8)
        // Own p4 0 → the plain boulder 0x6e1; record[p1] (30) pressed alone fires too.
        setP4(28, 0)
        setP4(31, 0)
        setP4(30, 1)
        w.active.update(id: k) { $0.counterA6 = 0 }
        fire()
        XCTAssertEqual(shots(w, 0x6e1).count, 1)
        XCTAssertEqual(shots(w, 0x6e2).count, 1)
        // The other speeds (M l. 60496–60540): level 4's 1453 (rec 68: p1 57, p4 0) and, as fixtures, rec 28's spout
        // retyped 1451 / 1452 (no level 1–5 places them): 1451 vx = R(300) − 0x96, vy = −3000 − R(300); 1452 vx =
        // R(600) + 0xaf0, vy = −(R(700) + 500); 1453 vx = −(R(600) + 0xaf0), vy = −(R(700) + 500).
        XCTAssertEqual([w.records[68].type, w.records[68].p1, w.records[68].p4], [1453, 57, 0])
        setP4(57, 1)
        for (rec, type) in [(68, Int16(0x5ad)), (28, 0x5ab), (28, 0x5ac)] {
            var sp = try SetupFaces.setup(w.records[rec], context: SetupFaces.Context(level: w.level, playerX: 0)).slot
            sp.type = type
            let id = w.active.insert(sp)
            var r = w.rng
            _ = r.next(5)
            _ = r.next(2)
            if 0x56 < r.next(100) { _ = r.next(5) }
            let vx: Int32, vy: Int32
            switch type {
            case 0x5ab:
                vx = Int32(r.next(300)) - 0x96
                vy = -3000 - Int32(r.next(300))
            case 0x5ac:
                vx = Int32(r.next(600)) + 0xaf0
                vy = -(Int32(r.next(700)) + 500)
            default:
                vx = -(Int32(r.next(600)) + 0xaf0)
                vy = -(Int32(r.next(700)) + 500)
            }
            let t = r.next(30) + 50
            let before = Set(shots(w, 0x6e1).map(\.id))
            BoxSprite.handle(world: w, id: id, solver: solver, lights: &lights, effects: 1)
            XCTAssertEqual(w.rng.seed, r.seed, "type \(type)")
            XCTAssertEqual(try slot(w, id).counterA6, t, "type \(type)")
            XCTAssertEqual(shots(w, 0x6e1).filter { !before.contains($0.id) }.map { [Int($0.vx), Int($0.vy)] },
                           [[Int(vx), Int(vy)]], "type \(type)")
        }
        // With all 700 records in use: no Setup, no speed draws — only the re-arm's R(30) (Ruling 16).
        while w.active.sprites.count < SpriteWorld.recordCount { _ = w.active.insert(SpriteSlot(type: 1, x: 0, y: 0)) }
        w.active.update(id: k) { $0.counterA6 = 0 }
        r = w.rng
        let t2 = r.next(30) + 50
        let n = w.active.sprites.count
        fire()
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual(try slot(w, k).counterA6, t2)
        XCTAssertEqual(w.active.sprites.count, n)
        // An enemy shot presses a Button like a player shot (`.HitButtonSprite` M l. 61837–61840): 4704, level 0xb.
        let (v, _) = try world(level: 4)
        let button = try XCTUnwrap(v.newSprite(type: 0x528, x: 0, y: 0, layer: 1, handler: .button))
        let shot = try XCTUnwrap(EnemyShot.spawn(v, type: 0x6e1, x: 0, y: 0, layer: 9))
        ButtonSprite.hit(v, id: button, other: shot)
        XCTAssertEqual(try slot(v, button).phase, 0xb)
        XCTAssertEqual(v.player.cues.map(\.snd), [4704])
    }

    // MARK: - the crouch

    func testMagicalShieldCrouchFace() throws {
        // The grounded crouch with the shield raised (M l. 45835–45860): extension + 1 below 7; `.HasItem(0xf)` false or
        // the counter < 4 → 1039[min(raise − 1, 5)]; else 1039[min(raise + 2, 8)]; then the counter − 1 above 5.
        let (w, pid) = try world()
        func crouchFace(_ raise: Int16) throws -> (Int, Int16) {
            w.player.crouch = 2
            w.player.wandPhase = 0
            w.player.shieldRaise = raise
            PlayerStates.grounded(w, id: pid)
            return (try XCTUnwrap(try slot(w, pid).face?.index), w.player.shieldRaise)
        }
        func faces() throws -> [[Int]] { try (1...7).map { let f = try crouchFace(Int16($0)); return [f.0, Int(f.1)] } }
        let plain = try faces()
        XCTAssertEqual(plain, [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 5], [5, 6]])
        giveShield(w)
        let magic = try faces()
        XCTAssertEqual(magic, [[0, 1], [1, 2], [2, 3], [6, 4], [7, 5], [8, 5], [8, 6]])
        XCTAssertEqual(try slot(w, pid).face?.pict, PlayerStates.shield)
    }
}
