import XCTest
import HectorResources
@testable import FerazelCore

/// BX1 (docs/plans/2026-10-24-ferazel-phase4.md): the Box class's mechanisms — `.HandleBoxSprite @ 1006d878`'s arms
/// and common tail (M l. 60030–61180), `.KillCrate @ 1006fa98` (M l. 61181–61327), `.HitBoxSprite @ 10070024` (M l.
/// 61328–61482), `.HitBoxTileSprite @ 10070718` (M l. 61521–61683) and the spin stomp of `.HitPlayerSprite`'s Box arm
/// (M l. 49364–49406). Synthetic 16×16 grids over the level's header (as `ShotHitTests`); every expected draw is
/// re-derived from a copy of the stream at its call site, the geometry from the dump's arithmetic next to each assertion.
final class BoxMechanismTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// A 16×16 grid over `level`'s header with an FG kind-3 floor (tile 3, cell 4) on row 12 — the surface at y 400.
    private func world(level: Int16 = 1) throws -> SpriteWorld {
        let w = SpriteWorld(level: try LevelFile.load(from: try resources(), level: level))
        var fg = [UInt16](repeating: 0, count: 16 * 16)
        for c in 0..<16 { fg[12 * 16 + c] = 4 }
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: fg),
                           bg: TileMap(width: 16, height: 16, cells: [UInt16](repeating: 0, count: 16 * 16)),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        return w
    }

    /// The record's Setup (`SetupFaces` → `BoxSprite.setup`) inserted, with `.BoxClean`'s centre (the previous frame's).
    private func add(_ w: SpriteWorld, record i: Int, x: Int? = nil, y: Int? = nil) throws -> Int {
        let p = w.records[i]
        var s = try SetupFaces.setup(p, context: SetupFaces.Context(level: w.level, playerX: 0)).slot
        if let x { s.x = x; s.oldPosition.x = x; s.x256 = Int32(x) << 8 }
        if let y { s.y = y; s.oldPosition.y = y; s.y256 = Int32(y) << 8 }
        let r = s.hotRect
        s.centre = SpriteSlot.Point(x: s.x + r.left + ((r.right - r.left) >> 1), y: s.y + r.top + ((r.bottom - r.top) >> 1))
        return w.active.insert(s)
    }

    /// A player shot of id `type` (after the Setup's split) at (x, y) with the Setup's hot rect.
    private func shot(_ w: SpriteWorld, _ type: Int16 = 0, x: Int, y: Int, hp: Int16 = 100) -> Int {
        var s = SpriteSlot(type: type, x: x, y: y)
        s.handler = .playerShot
        s.hasHit = true
        s.power = 1
        s.hp = hp
        s.hotRect = IdleSprites.Rect(top: 3, left: 8, bottom: 0xc, right: 0xf)
        s.centre = SpriteSlot.Point(x: x + 11, y: y + 7)
        return w.active.insert(s)
    }

    private func effects(_ w: SpriteWorld, _ t: Int16) -> [SpriteSlot] {
        w.active.sprites.filter { $0.handler == .effect && $0.type == t }
    }

    private func explosionPackage(_ r: inout FastRand) { for _ in 0..<0x2d { _ = r.next(2000); _ = r.next(2000); _ = r.next(2) } }

    /// `.KillCrate`'s 16-piece walk (M l. 61219–61258) on a copy of the stream: the debris Setup's `FastRand(100)`,
    /// `FastRand(8)` (M l. 53812–53825), its `FastRand(0x96)` and `FastRand(600)`; for 3092 the 0xc81 piece's
    /// `FastRand(200)`, `FastRand(5)` (its Setup draws nothing: ids ≥ 0xc80 skip the package), else every second
    /// piece's 0x442 smoke (its Setup's 45 × 3 package draws, kind 4) and `FastRand(0x96)`, `FastRand(7)`.
    private func pieces(_ r: inout FastRand, explosive: Bool) -> [Int16] {
        var phases: [Int16] = []
        var dust: Int16 = 0
        for _ in 0..<16 {
            _ = r.next(100); _ = r.next(8)
            _ = r.next(0x96); _ = r.next(600)
            if explosive {
                _ = r.next(200)
                phases.append(r.next(5))
            } else {
                dust -= 1
                if dust < 1 {
                    dust = 2
                    explosionPackage(&r)
                    _ = r.next(0x96)
                    phases.append(r.next(7))
                }
            }
        }
        return phases
    }

    // MARK: - KillCrate

    func testCrateDropsBonus() throws {
        let w = try world()
        var lights = LightTable()
        // Level 1 rec 32: 3090 (0xc12), p1 0, p2 1291 (0x50b), p3 3 — HP 5 (M l. 59552).
        let p = w.records[32]
        XCTAssertEqual([p.type, p.p1, p.p2, p.p3], [3090, 0, 1291, 3])
        let crate = try add(w, record: 32)
        let c = try XCTUnwrap(w.active.sprite(id: crate))
        XCTAssertEqual(c.hp, 5)
        let fire = shot(w, 0, x: c.x + 8, y: c.y + 8, hp: 100)
        // `.HitBoxSprite(crate, shot)` (M l. 61366–61373): HP 5 − 100 < 1, `+0xea` 0 → `.KillCrate`, then
        // `.KillPlayerShot(shot, 1, 0)`.
        var r = w.rng
        let rate492 = r.soundRate()                                       // `STPlay3DSoundRand(492, 100, 0x100, centre)`
        _ = pieces(&r, explosive: false)
        var drops: [(vx: Int32, vy: Int32)] = []
        for _ in 0..<3 {
            _ = r.next(10); _ = r.next(6); _ = r.next(0x3c)               // the 0x50b Setup (M l. 52482–52505, tail)
            let vy = -2000 - Int32(r.next(1000))
            let vx = Int32(r.next(800)) - 400                             // p3 ≠ 1 (M l. 61286–61289)
            drops.append((vx, vy))
        }
        let rate301 = r.soundRate()                                       // `.KillPlayerShot` id 0: snd 301
        FerazelSession.hitCallback(w, crate, fire, lights: &lights)
        XCTAssertEqual(w.rng.seed, r.seed)
        let k = try XCTUnwrap(w.active.sprite(id: crate))
        XCTAssertEqual(k.hp, -95)
        XCTAssertTrue(k.dead)
        XCTAssertTrue(k.killedForGood)                                    // `+0xea = 1` (M l. 61213)
        XCTAssertEqual(w.active.sprite(id: fire)?.dead, true)
        XCTAssertEqual(effects(w, EffectSprite.debris).count, 16)
        XCTAssertEqual(effects(w, EffectSprite.smoke).count, 8)
        // The drops: `MTNewSprite(0x50b, x + 0x16, y + 0x15, 0x14, −1, .SetupBonusSprite)`, re-centred `x += x − cx`
        // (the 0x50b rect (2, 0xe, 0x12, 0x1e): cx = x + 10, cy = y + 0x16), `+0xb0 = 12`.
        let x0 = c.x + 0x16, y0 = c.y + 0x15
        let got = w.active.sprites.filter { $0.type == 0x50b }
        XCTAssertEqual(got.count, 3)
        for (g, d) in zip(got, drops) {
            XCTAssertEqual([g.x, g.y, Int(g.x256 >> 8), Int(g.y256 >> 8)], [x0 - 10, y0 - 0x16, x0 - 10, y0 - 0x16])
            XCTAssertEqual([g.vx, g.vy], [d.vx, d.vy])
            XCTAssertEqual(g.pickupDelay, 12)
            XCTAssertEqual(g.recordIndex, -1)
        }
        XCTAssertEqual(w.player.cues.map(\.snd), [492, 301])
        XCTAssertEqual(w.player.cues[0], PlayerCue(call: .threeDRand, snd: 492, priority: 100, volume: 0x100,
                                                   position: c.centre, rate: rate492))
        XCTAssertEqual(w.player.cues[1].rate, rate301)
        // The record is cleared for good at the next `.UpdateSprites` (`+0xea`, M l. 4968–4983).
        XCTAssertEqual(w.records[32].flag, 1)
        w.updateSprites(lights: &lights)
        XCTAssertEqual(w.records[32].flag, 0)
        // An effect 0x4b7 against a crate (M l. 61384–61391): −10 on any frame, `.KillPlayerShot(effect, 1, 0)` — an
        // Effect's `+0xa6` is 3 (M l. 53726), so no 419 is played and it becomes −6.
        let crate2 = try add(w, record: 65)
        var bigID: Int?
        var scratch = LightTable()
        bigID = EffectSprite.spawn(w, type: EffectSprite.bigExplosion, x: 3000, y: 1500, layer: 0xc, effects: 2,
                                   lights: &scratch)
        let big = try XCTUnwrap(bigID)
        w.active.update(id: crate2) { $0.hp = 20 }
        let seed = w.rng.seed
        w.player.cues = []
        FerazelSession.hitCallback(w, crate2, big, lights: &lights)
        XCTAssertEqual(w.active.sprite(id: crate2)?.hp, 10)
        XCTAssertEqual(w.active.sprite(id: big)?.counterA6, -6)
        XCTAssertEqual(w.rng.seed, seed)
        XCTAssertEqual(w.player.cues, [])
    }

    func testCrateP3One() throws {
        let w = try world()
        var lights = LightTable()
        // Rec 32 with p3 = 1: one drop and no `FastRand(800)` (vx stays 0, M l. 61286–61289).
        let p = w.records[32]
        w.records[32] = Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: p.p1, p2: p.p2, p3: 1,
                                  p4: p.p4, y: p.y, x: p.x)
        let crate = try add(w, record: 32)
        w.active.update(id: crate) { $0.hp = 0 }
        var r = w.rng
        _ = r.soundRate()
        _ = pieces(&r, explosive: false)
        _ = r.next(10); _ = r.next(6); _ = r.next(0x3c)
        let vy = -2000 - Int32(r.next(1000))
        BoxSprite.killCrate(w, id: crate, lights: &lights, effects: 1)
        XCTAssertEqual(w.rng.seed, r.seed)
        let got = w.active.sprites.filter { $0.type == 0x50b }
        XCTAssertEqual(got.map(\.vx), [0])
        XCTAssertEqual(got.map(\.vy), [vy])
        // Rec 65 (1293 × 0): p3 0 is written back as 1 (M l. 61264–61268) → one 0x50d.
        XCTAssertEqual([w.records[65].p2, w.records[65].p3], [1293, 0])
        let crate65 = try add(w, record: 65)
        w.active.update(id: crate65) { $0.hp = -1 }
        BoxSprite.killCrate(w, id: crate65, lights: &lights, effects: 1)
        XCTAssertEqual(w.records[65].p3, 1)
        XCTAssertEqual(w.active.sprites.filter { $0.type == 0x50d }.map(\.vx), [0])
        // HP > 0: nothing at all (the guard `lha 0xa4; cmpwi 0; bgt`, raw `1006fab8..fac0`).
        let crate31 = try add(w, record: 31)
        let seed = w.rng.seed, n = w.active.sprites.count
        BoxSprite.killCrate(w, id: crate31, lights: &lights, effects: 1)
        XCTAssertEqual([w.rng.seed, Int32(w.active.sprites.count)], [seed, Int32(n)])
        XCTAssertEqual(w.active.sprite(id: crate31)?.dead, false)
    }

    func testExplosiveCrate() throws {
        let w = try world()
        var lights = LightTable()
        // Level 1 rec 130: 3092 (0xc14), p1 2 — 16 debris, 16 × 0xc81, snd 435 and a 0x4b7, no drop (M l. 61259–61263).
        let p = w.records[130]
        XCTAssertEqual([p.type, p.p1, p.p2, p.p3], [3092, 2, 0, 0])
        let crate = try add(w, record: 130)
        let c = try XCTUnwrap(w.active.sprite(id: crate))
        w.active.update(id: crate) { $0.hp = -95 }
        var r = w.rng
        let rate492 = r.soundRate()
        let phases = pieces(&r, explosive: true)
        let rate435 = r.soundRate()
        explosionPackage(&r)                                              // the 0x4b7 Setup's package
        BoxSprite.killCrate(w, id: crate, lights: &lights, effects: 2)
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual(w.player.cues.map(\.snd), [492, 435])
        XCTAssertEqual(w.player.cues.map(\.priority), [100, 1])
        XCTAssertEqual(w.player.cues.map(\.rate), [rate492, rate435])
        XCTAssertEqual(effects(w, EffectSprite.debris).count, 16)
        // The 3201 (0xc81) pieces at (x + 8i + 0xc − 0x18, y + 8j + 0xc − 0x18), `+0x46 = FastRand(5)`.
        let bits = effects(w, 0xc81)
        XCTAssertEqual(bits.count, 16)
        XCTAssertEqual(bits.map(\.phase), phases)
        XCTAssertEqual(Set(bits.map { [$0.x, $0.y] }),
                       Set((0..<4).flatMap { i in (0..<4).map { j in [c.x + 8 * i - 0xc, c.y + 8 * j - 0xc] } }))
        let big = effects(w, EffectSprite.bigExplosion)
        XCTAssertEqual(big.map { [$0.x, $0.y] }, [[c.centre.x - 0x30, c.centre.y - 0x36]])
        XCTAssertTrue(w.active.sprites.allSatisfy { $0.handler != .bonus })
        XCTAssertEqual(effects(w, EffectSprite.smoke).count, 0)
    }

    func testCrateDropsItemViaGenerate() throws {
        let w = try world()
        var lights = LightTable()
        // Level 1 rec 31: 3090, p2 3219 (0xc93, an item ≥ 3200), p3 1 → `.GenerateSprite(x + 0x16, y + 0x15, 3219,
        // 0x200, now, layer + 1)` (M l. 61292–61320).
        let p = w.records[31]
        XCTAssertEqual([p.type, p.p1, p.p2, p.p3], [3090, 0, 3219, 1])
        let crate = try add(w, record: 31)
        let c = try XCTUnwrap(w.active.sprite(id: crate))
        w.active.update(id: crate) { $0.hp = 0 }
        var r = w.rng
        _ = r.soundRate()
        _ = pieces(&r, explosive: false)
        _ = r.next(0x10); _ = r.next(0x3c)                                // the item Setup (M l. 52665–52710, tail)
        let vy = -2000 - Int32(r.next(1000))                              // type > 0xc7f: gravity 0x151 and vy
        BoxSprite.killCrate(w, id: crate, lights: &lights, effects: 1)
        XCTAssertEqual(w.rng.seed, r.seed)
        let item = try XCTUnwrap(w.active.sprites.first { $0.type == 0xc93 })
        // Record 0x200 reads zeros (plan hazard): p1 0, so the item keeps its gravity — it falls.
        XCTAssertEqual(item.recordIndex, 0x200)
        XCTAssertEqual(item.gravity, 0x151)
        XCTAssertEqual([item.vx, item.vy], [0, vy])
        // Re-centred by the rect (left 4, top 0xb, right 0x1c, bottom 0x1f): x −= (4 + 0x1c) >> 1, y −= (0xb + 0x1f) >> 1.
        XCTAssertEqual(item.hotRect, IdleSprites.Rect(top: 0xb, left: 4, bottom: 0x1f, right: 0x1c))
        XCTAssertEqual([item.x, item.y, Int(item.x256 >> 8), Int(item.y256 >> 8)],
                       [c.x + 0x16 - 0x10, c.y + 0x15 - 0x15, c.x + 0x16 - 0x10, c.y + 0x15 - 0x15])
        XCTAssertEqual(item.handler, .bonus)
        XCTAssertNotEqual(item.light, -1)
    }

    // MARK: - the spin stomp

    func testSpinStompCrate() throws {
        func stomp(vy: Int32, keys: InputActions) throws -> (SpriteWorld, Int, Int) {
            let w = try world()
            let pid = try XCTUnwrap(Player.spawn(world: w, x: 100, y: 200))
            w.playerID = pid
            let crate = try add(w, record: 32, x: 200, y: 368)
            let r = HandleKeys.standardHotRect
            w.active.update(id: pid) { s in
                s.x = 200 + 4 - r.left
                s.y = 368 + 4 - r.bottom                                  // feet 4 px into the crate's top
                s.x256 = Int32(s.x) << 8
                s.y256 = Int32(s.y) << 8
                s.vx = 0
                s.vy = vy
                s.groundKind = 0
                s.centre = SpriteSlot.Point(x: s.x + 0x32, y: s.y + 0x3b)
            }
            w.player.spin = true
            w.player.crunchCooldown = 0
            w.player.airCounter = 0
            HitPlayerSprite.hit(w, player: pid, other: crate, keys: keys)
            return (w, pid, crate)
        }
        // Spin landing at vy 0xa00 > 0x9c4 on a crate (M l. 49364–49406): HP 5 − 100; vy = (int)(−0.9 · 0xa00) =
        // −2304, kept negative; DOWN not held → the spin ends and its sound 427 is stopped if playing, air counter 1;
        // cooldown 5; `+0xce = 0`, `_DAT_100a0738 = 0`, `+0xdc = 0`.
        var (w, pid, crate) = try stomp(vy: 0xa00, keys: [])
        var ps = try XCTUnwrap(w.active.sprite(id: pid))
        XCTAssertEqual(w.active.sprite(id: crate)?.hp, -95)
        XCTAssertEqual(ps.vy, -2304)
        XCTAssertEqual([Int(ps.groundKind), Int(w.player.groundLast)], [0, 0])
        XCTAssertNil(ps.ridden)
        XCTAssertFalse(w.player.spin)
        XCTAssertEqual([w.player.crunchCooldown, w.player.airCounter], [5, 1])
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .stopIfPlaying, snd: 427)])
        // The crate's Handle kills it at HP < 1 (M l. 61081–61083).
        var lights = LightTable()
        BoxSprite.handle(world: w, id: crate, solver: TileSolver(world: w), lights: &lights, effects: 1)
        XCTAssertEqual(w.active.sprite(id: crate)?.dead, true)
        XCTAssertEqual(effects(w, EffectSprite.debris).count, 16)
        // DOWN held: the spin goes on with `.STPlayRegSound(427, 1, 0xba)`; the air counter is not set.
        (w, pid, crate) = try stomp(vy: 0xa00, keys: .down)
        ps = try XCTUnwrap(w.active.sprite(id: pid))
        XCTAssertEqual(ps.vy, -2304)
        XCTAssertTrue(w.player.spin)
        XCTAssertEqual([w.player.crunchCooldown, w.player.airCounter], [5, 0])
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .reg, snd: 427, priority: 1, volume: 0xba)])
        // At vy 0x9c4 (not > 0x9c4): an ordinary landing — HP 5, vy 0, standing on the crate.
        (w, pid, crate) = try stomp(vy: 0x9c4, keys: [])
        ps = try XCTUnwrap(w.active.sprite(id: pid))
        XCTAssertEqual(w.active.sprite(id: crate)?.hp, 5)
        XCTAssertEqual([ps.vy, Int32(ps.groundKind)], [0, 3])
        XCTAssertEqual(ps.ridden, crate)
        XCTAssertTrue(w.player.spin)
        XCTAssertEqual(w.player.crunchCooldown, 0)
        // The cooldown `PTR_DAT_100a060c` ≠ 0 or record p4 == 1: no stomp either.
        let w2 = try world()
        let pid2 = try XCTUnwrap(Player.spawn(world: w2, x: 100, y: 200))
        w2.playerID = pid2
        let q = w2.records[32]
        w2.records[32] = Placement(index: q.index, flag: q.flag, byte1: q.byte1, type: q.type, p1: q.p1, p2: q.p2,
                                   p3: q.p3, p4: 1, y: q.y, x: q.x)
        let c2 = try add(w2, record: 32, x: 200, y: 368)
        let hr = HandleKeys.standardHotRect
        w2.active.update(id: pid2) { s in
            s.x = 204 - hr.left; s.y = 372 - hr.bottom
            s.x256 = Int32(s.x) << 8; s.y256 = Int32(s.y) << 8
            s.vy = 0xa00
            s.centre = SpriteSlot.Point(x: s.x + 0x32, y: s.y + 0x3b)
        }
        w2.player.spin = true
        HitPlayerSprite.hit(w2, player: pid2, other: c2)
        XCTAssertEqual(w2.active.sprite(id: c2)?.hp, 5)
    }

    // MARK: - the common tail

    func testBoxFallsAndSettles() throws {
        let w = try world()
        var lights = LightTable()
        let solver = TileSolver(world: w)
        // A crate (rect bottom 0x20) 40 px above its resting y 400 − 0x20 = 368 (the kind-3 floor's surface).
        let crate = try add(w, record: 32, x: 200, y: 368 - 40)
        func frame() { BoxSprite.handle(world: w, id: crate, solver: solver, lights: &lights, effects: 1) }
        // The tail (M l. 61152–61175): `y += vy` (the previous frame's vy), then `.ApplyGravityAndSeparateFromTiles`:
        // vy += 0x100, y += vy — so after frame k: vy = 0x100·k, y = 328 + Σ (i − 1 + i) = 328 + k².
        for k in 1...6 {
            frame()
            let s = try XCTUnwrap(w.active.sprite(id: crate))
            XCTAssertEqual([s.vy, Int32(s.y)], [Int32(0x100 * k), Int32(328 + k * k)], "frame \(k)")
            // The crate arm re-sorts by `−(2y + x)` every frame (`.MTChangeSpriteLayer`, M l. 61079–61080).
            XCTAssertEqual(s.layer, -Int32(2 * (328 + (k - 1) * (k - 1)) + 200), "frame \(k)")
        }
        // Frame 7: the tail's `y += 0x600` reaches 370; the separation's FG hit from above bounces with the crate
        // factor 0x60 (`.HitBoxTileSprite` M l. 61571–61574): vy = −(0x600·0x60 >> 8) = −0x240 on the surface 368,
        // then +0x100 gravity and the step −0x140 lifts it to 368 − 2 (24.8: 368·256 − 0x140).
        frame()
        var s = try XCTUnwrap(w.active.sprite(id: crate))
        XCTAssertEqual(s.vy, -0x240 + 0x100)
        XCTAssertEqual(s.y256, (368 << 8) - 0x140)
        // It settles on the surface: vy 0, y 368.
        for _ in 0..<30 { frame() }
        s = try XCTUnwrap(w.active.sprite(id: crate))
        XCTAssertEqual([s.vy, Int32(s.y)], [0, 368])
        XCTAssertEqual(s.centre, SpriteSlot.Point(x: 200 + 4 + ((0x23 - 4) >> 1), y: 368 + (0x20 >> 1)))
        // A push of vx 0x200: friction 0x5a a frame (`.ApplyFriction(+0x114)`) — 0x1a6, 0x14c, 0xf2, 0x98, 0x3e, 0 —
        // and x moves by each (the integration's `x += vx`): 1210 / 256 → 4 px.
        w.active.update(id: crate) { $0.vx = 0x200 }
        var vxs: [Int32] = []
        for _ in 0..<7 {
            frame()
            vxs.append(try XCTUnwrap(w.active.sprite(id: crate)).vx)
        }
        XCTAssertEqual(vxs, [0x1a6, 0x14c, 0xf2, 0x98, 0x3e, 0, 0])
        s = try XCTUnwrap(w.active.sprite(id: crate))
        XCTAssertEqual([s.x, s.y], [204, 368])
        XCTAssertEqual(s.x256, (200 << 8) + 1210)
    }

    func testBoulderRolls() throws {
        let w = try world(level: 2)
        var lights = LightTable()
        let solver = TileSolver(world: w)
        // Level 2 rec 21: the boulder 1070 (rect 4, 0, 0x1c, 0x1c) resting on the floor: y = 400 − 0x1c.
        XCTAssertEqual(w.records[21].type, 1070)
        let b = try add(w, record: 21, x: 200, y: 400 - 0x1c)
        // The roll (M l. 60258–60283): grounded (`+0xcd` or `+0xce`) → d = `.PEDistance(vx, 0)` = |vx|; `+0x46` ±=
        // d·360 / 0x6900 (+ when vx < 1); wrapped into 0…359; `+0x1aa = +0x46`; `+0x88 = 0`, `+0x89 = 1`.
        func roll(_ vx: Int32) throws -> SpriteSlot {
            w.active.update(id: b) { $0.vx = vx; $0.groundKind = 3 }
            BoxSprite.handle(world: w, id: b, solver: solver, lights: &lights, effects: 1)
            return try XCTUnwrap(w.active.sprite(id: b))
        }
        var s = try roll(-75)                                             // 75·360 / 0x6900 = 1
        XCTAssertEqual([s.phase, s.rotation], [1, 1])
        XCTAssertEqual([s.lightOverlay, s.dynamicLight], [false, true])
        s = try roll(-74)                                                 // 74·360 / 0x6900 = 0
        XCTAssertEqual(s.phase, 1)
        s = try roll(0x6900 / 360 * 4)                                    // 296 → 3, vx > 0: subtracted, wrapped
        XCTAssertEqual([s.phase, s.rotation], [358, 358])
        // In the air the distance takes vy too: `.PEDistance(vx, vy)` = max + min / 3.
        w.active.update(id: b) { $0.vx = 0; $0.vy = -300; $0.groundKind = 0; $0.onSprite = 0; $0.phase = 0 }
        BoxSprite.handle(world: w, id: b, solver: solver, lights: &lights, effects: 1)
        XCTAssertEqual(w.active.sprite(id: b)?.phase, Int16(300 * 360 / 0x6900))

        // `.HitBoxTileSprite` (M l. 61553–61611): a boulder landing at |vy| > 0x1ff bounces with factor 0x3c; a thud
        // (`.STPlay3DSoundPitched(436, 1, 0x55, centre, 48000 + FastRand(10000))`) when |vy| > 0x300 and `+0xcd == 0`;
        // then |vy| < 0x100 → 0.
        func land(_ vy: Int32) throws -> (SpriteSlot, [PlayerCue], Int16) {
            w.player.cues = []
            w.active.update(id: b) { s in
                s.x = 64; s.y = 400 - 0x1c + 4
                s.x256 = Int32(s.x) << 8; s.y256 = Int32(s.y) << 8
                s.oldPosition = SpriteSlot.Point(x: s.x, y: s.y)
                s.vx = 0; s.vy = vy; s.onSprite = 0
                s.centre = SpriteSlot.Point(x: 64 + 0x10, y: s.y + 0xe)
            }
            var r = w.rng
            let pitch = r.next(10000)
            BoxSprite.hitTile(solver, id: b, pos: TilePos(x: 64, y: 384), kind: 3, layer: .foreground, lights: &lights,
                              effects: 1)
            return (try XCTUnwrap(w.active.sprite(id: b)), w.player.cues, pitch)
        }
        var (l, cues, pitch) = try land(0x320)
        // −(0x320·0x3c >> 8) = −187, then |vy| < 0x100 → 0; on the surface.
        XCTAssertEqual([l.vy, Int32(l.y)], [0, 400 - 0x1c])
        XCTAssertEqual(cues, [PlayerCue(call: .threeDPitched, snd: 436, priority: 1, volume: 0x55,
                                        position: SpriteSlot.Point(x: 64 + 0x10, y: 400 - 0x1c + 4 + 0xe),
                                        rate: 48000 + Int32(pitch))])
        (l, cues, _) = try land(0x600)                                    // −(0x600·0x3c >> 8) = −360: kept
        XCTAssertEqual(l.vy, -360)
        XCTAssertEqual(cues.map(\.snd), [436])
        let seed = w.rng.seed
        (l, cues, _) = try land(0x1ff)                                    // no bounce, no thud, no draw
        XCTAssertEqual([l.vy, Int32(l.y)], [0, 400 - 0x1c])
        XCTAssertEqual(cues, [])
        XCTAssertEqual(w.rng.seed, seed)
    }

    // MARK: - the stalactite

    func testStalactiteFalls() throws {
        let w = try world(level: 2)
        var lights = LightTable()
        let solver = TileSolver(world: w)
        // Level 2 rec 158: 2932, p2 0 → HP 150 (M l. 59376–59379); home x `+0x154` = x.
        XCTAssertEqual(w.records[158].type, 2932)
        let st = try add(w, record: 158, x: 200, y: 100)
        w.active.update(id: st) { $0.classWord154 = 200; $0.counterA6 = 0 }
        XCTAssertEqual(w.active.sprite(id: st)?.hp, 150)
        func fire() {
            let f = shot(w, 0, x: 205, y: 120, hp: 100)
            FerazelSession.hitCallback(w, st, f, lights: &lights)
        }
        func frame() { BoxSprite.handle(world: w, id: st, solver: solver, lights: &lights, effects: 1) }
        // A Fireball (100): HP 50, shake n + FastRand(n / 2) with n = 100 / 20 = 5 (M l. 61374–61382).
        var r = w.rng
        let shake = 5 + r.next(2)
        fire()
        var s = try XCTUnwrap(w.active.sprite(id: st))
        XCTAssertEqual([s.hp, s.counterA6], [50, shake])
        // While shaking (M l. 60597–60616): x = home ∓ max(frames >> 2, 1) by the frames' parity, frames − 1.
        var xs: [Int] = []
        for _ in 0..<Int(shake) { frame(); xs.append(try XCTUnwrap(w.active.sprite(id: st)).x) }
        var expected: [Int] = []
        var u = shake
        while 0 < u {
            let d = max(Int(u >> 2), 1)
            expected.append(u & 1 == 0 ? 200 - d : 200 + d)
            u -= 1
        }
        XCTAssertEqual(xs, expected)
        frame()
        s = try XCTUnwrap(w.active.sprite(id: st))
        XCTAssertEqual([s.counterA6, s.gravity], [0, 0])                  // HP 50 ≥ 1: it stays
        // A second Fireball: HP −50; the gravity 0xfa comes when the shake is over (`+0xa6 < 1`, M l. 60599–60602).
        r = w.rng
        let s2 = 5 + r.next(2)
        fire()
        s = try XCTUnwrap(w.active.sprite(id: st))
        XCTAssertEqual([s.hp, s.counterA6], [-50, s2])
        for _ in 0..<Int(s2) {
            frame()
            XCTAssertEqual(w.active.sprite(id: st)?.gravity, 0)
        }
        frame()
        s = try XCTUnwrap(w.active.sprite(id: st))
        XCTAssertEqual(s.gravity, 0xfa)
        XCTAssertEqual(s.vy, 0xfa)                                        // the same frame's tail falls
        // HP below −0xf9 skips the shake: gravity at once.
        let st2 = try add(w, record: 159, x: 300, y: 100)
        w.active.update(id: st2) { $0.hp = -0xfa; $0.counterA6 = 9; $0.classWord154 = 300 }
        BoxSprite.handle(world: w, id: st2, solver: solver, lights: &lights, effects: 1)
        XCTAssertEqual(w.active.sprite(id: st2)?.gravity, 0xfa)
        XCTAssertEqual(w.active.sprite(id: st2)?.counterA6, 9)
    }
}
