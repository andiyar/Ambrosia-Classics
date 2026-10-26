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

    /// The debris' velocities by spawn position, from the same walk on a copy of the stream (after the 492 draw):
    /// `FUN_1003f218(debris, .FindDesiredDirectionGeneric((v, h), (y + 0x24, cx)), R(0x96) + 0x28a)` on the fresh
    /// piece (vx = vy = 0), then `vy −= 0x578 − R(600)` (M l. 61230–61235).
    private func debris(_ r: inout FastRand, crate c: SpriteSlot, explosive: Bool) -> [[Int]: [Int32]] {
        var out: [[Int]: [Int32]] = [:]
        var dust: Int16 = 0
        let from = (v: Int16(c.y + 0x24), h: Int16(c.centre.x))
        for i in 0..<4 {
            for j in 0..<4 {
                let hx = Int16(c.x + 8 * i + 0xc), vy = Int16(c.y + 8 * j + 0xc)
                _ = r.next(100); _ = r.next(8)
                let m = Int32(r.next(0x96)) + 0x28a
                var p = SpriteSlot(type: EffectSprite.debris, x: 0, y: 0)
                PlayerShot.addDirImpulse(&p, dir: BloodSpray.direction(target: (v: vy, h: hx), from: from), magnitude: m)
                let r600 = Int32(r.next(600))
                out[[Int(hx) - 0xc, Int(vy) - 0xc]] = [p.vx, p.vy - (0x578 - r600)]
                if explosive {
                    _ = r.next(200); _ = r.next(5)
                } else {
                    dust -= 1
                    if dust < 1 { dust = 2; explosionPackage(&r); _ = r.next(0x96); _ = r.next(7) }
                }
            }
        }
        return out
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
        var rd = w.rng
        _ = rd.soundRate()
        let wantDebris = debris(&rd, crate: c, explosive: false)
        FerazelSession.hitCallback(w, crate, fire, lights: &lights)
        XCTAssertEqual(w.rng.seed, r.seed)
        let gotDebris = Dictionary(uniqueKeysWithValues: effects(w, EffectSprite.debris).map { ([$0.x, $0.y], [$0.vx, $0.vy]) })
        XCTAssertEqual(gotDebris, wantDebris)
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
        var rd = r
        let wantDebris = debris(&rd, crate: c, explosive: true)
        let phases = pieces(&r, explosive: true)
        let rate435 = r.soundRate()
        explosionPackage(&r)                                              // the 0x4b7 Setup's package
        BoxSprite.killCrate(w, id: crate, lights: &lights, effects: 2)
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual(Dictionary(uniqueKeysWithValues: effects(w, EffectSprite.debris).map { ([$0.x, $0.y], [$0.vx, $0.vy]) }),
                       wantDebris)
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
        // `.HitBoxTileSprite`'s FG arm (M l. 61572–61575): vy > 0x4b0 (signed) with the record's p1 == 2 →
        // `.KillCrate`, which then dies behind its own HP guard; a landing crate 4 px into the kind-3 floor.
        func land(record: Int, vy: Int32, hp: Int16) throws -> (dead: Bool, cues: [Int16]) {
            let id = try add(w, record: record, x: 64, y: 400 - 0x20 + 4)
            w.active.update(id: id) { $0.vy = vy; $0.hp = hp }
            w.player.cues = []
            BoxSprite.hitTile(TileSolver(world: w), id: id, pos: TilePos(x: 64, y: 384), kind: 3, layer: .foreground,
                              lights: &lights, effects: 2)
            return (try XCTUnwrap(w.active.sprite(id: id)).dead, w.player.cues.map(\.snd))
        }
        var l = try land(record: 130, vy: 0x4b1, hp: 0)
        XCTAssertTrue(l.dead)
        XCTAssertEqual(l.cues, [492, 435])
        l = try land(record: 130, vy: 0x4b0, hp: 0)
        XCTAssertEqual([l.dead ? 1 : 0, l.cues.count], [0, 0])
        l = try land(record: 130, vy: 0x4b1, hp: 1)                       // alive: `.KillCrate` returns at once
        XCTAssertEqual([l.dead ? 1 : 0, l.cues.count], [0, 0])
        l = try land(record: 32, vy: 0x4b1, hp: 0)                        // p1 0: no call
        XCTAssertEqual([l.dead ? 1 : 0, l.cues.count], [0, 0])
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
        func stomp(vy: Int32, keys: InputActions, cooldown: Int16 = 0, hp: Int16? = nil) throws -> (SpriteWorld, Int, Int) {
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
            if let hp { w.active.update(id: crate) { $0.hp = hp } }
            w.player.spin = true
            w.player.crunchCooldown = cooldown
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
        XCTAssertEqual(w.active.sprite(id: crate)?.hp, -95)                       // the same stomp as without DOWN
        XCTAssertEqual([Int(ps.groundKind), Int(w.player.groundLast)], [0, 0])
        XCTAssertNil(ps.ridden)
        // The cooldown `PTR_DAT_100a060c` ≠ 0 (M l. 49367): an ordinary landing — HP 5, vy 0, on the crate, spin on,
        // no sound; the cooldown is left as it was.
        (w, pid, crate) = try stomp(vy: 0xa00, keys: [], cooldown: 1)
        ps = try XCTUnwrap(w.active.sprite(id: pid))
        XCTAssertEqual(w.active.sprite(id: crate)?.hp, 5)
        XCTAssertEqual([ps.vy, Int32(ps.groundKind)], [0, 3])
        XCTAssertEqual(ps.ridden, crate)
        XCTAssertTrue(w.player.spin)
        XCTAssertEqual([w.player.crunchCooldown, w.player.airCounter], [1, 0])
        XCTAssertEqual(w.player.cues, [])
        // HP ≤ 0 (`0 < +0xa4`, M l. 49365): no stomp either.
        (w, pid, crate) = try stomp(vy: 0xa00, keys: [], hp: 0)
        XCTAssertEqual(w.active.sprite(id: crate)?.hp, 0)
        XCTAssertEqual(w.active.sprite(id: pid)?.vy, 0)
        XCTAssertEqual(w.player.crunchCooldown, 0)
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

        // The tail itself (M l. 61152–61161), gravity 0 so nothing but the tail moves the crate. `.FootPressure` reads
        // `+0xcd` (grounded last frame), after `.ApplyFriction`: vx 0x200 → 0x1a6, then y256 += |vx| (kind 0 is
        // downhill both ways, no rider); `+0xce` alone does not trigger it. Then `+0xcd = +0xce`.
        func tailOnly(vx: Int32, vy: Int32, last: UInt8, now: UInt8, gravity: Int16 = 0) throws -> SpriteSlot {
            w.active.update(id: crate) { c in
                c.x = 200; c.y = 100; c.x256 = 200 << 8; c.y256 = 100 << 8
                c.vx = vx; c.vy = vy; c.onSprite = last; c.groundKind = now; c.gravity = gravity
                c.ridden = nil; c.oneWayLanded = false; c.slope = 0
            }
            BoxSprite.tail(w, id: crate, solver: solver, lights: &lights, effects: 1)
            return try XCTUnwrap(w.active.sprite(id: crate))
        }
        s = try tailOnly(vx: 0x200, vy: 0, last: 3, now: 0)
        XCTAssertEqual([s.vx, s.y256 - (100 << 8)], [0x1a6, 0x1a6])
        XCTAssertEqual(s.onSprite, 0)
        s = try tailOnly(vx: 0x200, vy: 0, last: 0, now: 3)
        XCTAssertEqual([s.vx, s.y256 - (100 << 8)], [0x1a6, 0])
        XCTAssertEqual(s.onSprite, 3)
        // `.EnforceMaxSpeed(0x1838)` comes before `+0x1c += vy`: vy 0x2000 moves the crate by 0x1838.
        s = try tailOnly(vx: 0, vy: 0x2000, last: 0, now: 0)
        XCTAssertEqual([s.vy, s.y256 - (100 << 8)], [0x1838, 0x1838])
        // `+0xcd = +0xce` is taken before `.ApplyGravityAndSeparateFromTiles` clears `+0xce` in the air.
        s = try tailOnly(vx: 0, vy: 0, last: 0, now: 3, gravity: 0x100)
        XCTAssertEqual([Int(s.onSprite), Int(s.groundKind)], [3, 0])

        // `.HitBoxSprite`, Box against Box (M l. 61393–61467): the mutual `.PlatformBounce` (factor 0, self's rect
        // centre and rect for both calls). Two crates, the upper's bottom 8 px into the lower's top, vy 0 — whichever
        // moves first is pushed out (the upper from above onto y 92, the lower from below onto y 132) and the second
        // call finds no overlap. The order: self grounded (`+0xce`) over an airborne other → `PB(other, self)` first;
        // the mirror; both airborne → the higher (`+0xa` smaller) first; both grounded → (|vx| − |vx'|) + (|vy| −
        // |vy'|) < 0 → `PB(self, other)` first, else `PB(other, self)`; then both `+0x182 = 1`.
        let up = try add(w, record: 31, x: 400, y: 100)
        let lo = try add(w, record: 31, x: 400, y: 100 + 0x18)
        func pair(selfUpper: Bool, ground: (up: Bool, lo: Bool), up uv: (Int32, Int32) = (0, 0),
                  lo lv: (Int32, Int32) = (0, 0), latch: (up: Bool, lo: Bool) = (false, false)) throws -> [Int] {
            for (id, y, g, v, l) in [(up, 100, ground.up, uv, latch.up), (lo, 100 + 0x18, ground.lo, lv, latch.lo)] {
                w.active.update(id: id) { c in
                    c.x = 400; c.y = y; c.x256 = 400 << 8; c.y256 = Int32(y) << 8
                    c.vx = v.0; c.vy = v.1; c.groundKind = g ? 3 : 0; c.onSprite = 0
                    c.boxPairLatch = l; c.ceilingHit = 0; c.ridden = nil; c.rider = nil
                }
            }
            BoxSprite.hit(w, id: selfUpper ? up : lo, other: selfUpper ? lo : up, lights: &lights)
            return [try XCTUnwrap(w.active.sprite(id: up)).y, try XCTUnwrap(w.active.sprite(id: lo)).y]
        }
        let upperMoved = [92, 100 + 0x18], lowerMoved = [100, 132]
        XCTAssertEqual(try pair(selfUpper: true, ground: (false, false)), upperMoved)    // both airborne: the higher
        XCTAssertEqual(try pair(selfUpper: false, ground: (false, false)), upperMoved)
        XCTAssertEqual(try pair(selfUpper: true, ground: (true, false)), lowerMoved)     // grounded self: other first
        XCTAssertEqual(try pair(selfUpper: false, ground: (false, true)), upperMoved)
        XCTAssertEqual(try pair(selfUpper: true, ground: (false, true)), upperMoved)     // grounded other: self first
        XCTAssertEqual(try pair(selfUpper: false, ground: (true, false)), lowerMoved)
        XCTAssertEqual(w.active.sprite(id: lo)?.ceilingHit, 1)                           // `PB` return 2 → `+0xcf`
        // The grounded flags win over a speed order that says the opposite.
        XCTAssertEqual(try pair(selfUpper: true, ground: (true, false), lo: (0x80, 0)), lowerMoved)
        XCTAssertEqual(try pair(selfUpper: false, ground: (true, false), lo: (0x80, 0)), lowerMoved)
        // Both grounded: by speed (vx 0x80 / vy 0x80 move no pixel of the previous position, `>> 8`).
        XCTAssertEqual(try pair(selfUpper: true, ground: (true, true), up: (0x80, 0)), lowerMoved)
        XCTAssertEqual(try pair(selfUpper: true, ground: (true, true), lo: (0x80, 0)), upperMoved)
        XCTAssertEqual(try pair(selfUpper: true, ground: (true, true), lo: (0, 0x80)), upperMoved)
        XCTAssertEqual(try pair(selfUpper: true, ground: (true, true), lo: (-0x80, 0)), upperMoved)   // magnitudes
        XCTAssertEqual(try pair(selfUpper: true, ground: (true, true)), lowerMoved)      // 0 is not < 0
        XCTAssertEqual(try pair(selfUpper: false, ground: (true, true)), upperMoved)
        XCTAssertEqual([w.active.sprite(id: up)?.boxPairLatch, w.active.sprite(id: lo)?.boxPairLatch], [true, true])
        // Self's `+0x182` set → nothing (the other's latch is not read).
        XCTAssertEqual(try pair(selfUpper: true, ground: (false, false), latch: (true, false)), [100, 100 + 0x18])
        XCTAssertEqual(try pair(selfUpper: false, ground: (false, false), latch: (true, false)), upperMoved)
        // The Handle clears `+0x182` after `.StandardSpriteHandles` (M l. 60090–60091) — also for a type whose arm
        // returns at once (`handleBuilt`, here the chest 0x51c); a dying Box returns before it (M l. 60084–60089).
        BoxSprite.handle(world: w, id: up, solver: solver, lights: &lights, effects: 1)
        XCTAssertEqual(w.active.sprite(id: up)?.boxPairLatch, false)
        w.active.update(id: lo) { $0.type = 0x51c; $0.boxPairLatch = true }
        BoxSprite.handle(world: w, id: lo, solver: solver, lights: &lights, effects: 1)
        XCTAssertEqual(w.active.sprite(id: lo)?.boxPairLatch, false)
        w.active.update(id: lo) { $0.boxPairLatch = true; $0.dead = true }
        BoxSprite.handle(world: w, id: lo, solver: solver, lights: &lights, effects: 1)
        XCTAssertEqual(w.active.sprite(id: lo)?.boxPairLatch, true)
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

        // A falling rock 0x433 (the boulders' Setup arm) breaks on that bounce (M l. 61596–61600): the thud first, then
        // `.KillBox` (M l. 61495–61500): `+0xe9`, `.STPlay3DSoundRand(424, 1, 0x100, centre)`, then
        // `.ExplodeFaceIntoParticles(face, (y, x), 2, 2, 2, 100, 100)` — a one-pixel face: gravity 100 + R(0x1e).
        func tok(_ op: UInt32, _ n: Int) -> [UInt8] {
            let t = op << 24 | UInt32(n)
            return [UInt8(t >> 24), UInt8(t >> 16 & 0xff), UInt8(t >> 8 & 0xff), UInt8(t & 0xff)]
        }
        let dot = ParticleFace(frame: [0, 0, 1, 1], bounds: [0, 0, 1, 1], tokens: tok(1, 4) + tok(2, 1) + [7, 0, 0, 0] + tok(0, 0))
        w.particleFaces = ParticleFaces(sprite: { _ in dot })
        w.active.update(id: b) { $0.type = 0x433; $0.face = FaceRef(pict: 1070, index: 0, set: .encoded) }
        var rr = w.rng
        let thudPitch = Int32(rr.next(10000))
        let rate424 = rr.soundRate()
        _ = rr.next(0x14); _ = rr.next(0x2ee); _ = rr.next(100)
        let r30 = Int16(rr.next(0x1e))
        let n0 = w.particles.counters.count
        (l, cues, _) = try land(0x320)
        XCTAssertEqual(w.rng.seed, rr.seed)
        XCTAssertTrue(l.dead)
        XCTAssertEqual(cues.map(\.snd), [436, 424])
        XCTAssertEqual(cues.map(\.rate), [48000 + thudPitch, rate424])
        XCTAssertEqual(cues.last, PlayerCue(call: .threeDRand, snd: 424, priority: 1, volume: 0x100, position: l.centre,
                                          rate: rate424))
        XCTAssertEqual(w.particles.counters.count, n0 + 1)
        XCTAssertEqual(w.particles.records[Int(w.particles.counters.hint)].gravity, 100 + r30)
        // No bounce (|vy| ≤ 0x1ff, b 0): it survives.
        w.active.update(id: b) { $0.dead = false }
        (l, cues, _) = try land(0x1ff)
        XCTAssertFalse(l.dead)
        w.particleFaces = ParticleFaces()

        // The mine cart 2930 (level 3's carts cannot load yet — enemy 1730): a cart placed alone on level 2's records.
        // Its Setup (M l. 59433–59464) makes its two children before it idles: the rider 0xb72 at layer 100 with the
        // set's cell 7 (`+0x20`), the wheel 0xb73 at layer −1 with cell 0; both the record −1 arm (empty rect, gravity 0).
        var recs = w.records.map {
            Placement(index: $0.index, flag: 0, byte1: $0.byte1, type: $0.type, p1: $0.p1, p2: $0.p2, p3: $0.p3,
                      p4: $0.p4, y: $0.y, x: $0.x)
        }
        let q = recs[21]
        recs[21] = Placement(index: q.index, flag: 1, byte1: q.byte1, type: 2930, p1: 0, p2: 0, p3: 0, p4: 0, y: q.y, x: q.x)
        let sp = try SetupFaces.spawnLevelSprites(context: SetupFaces.Context(level: w.level, playerX: 0, records: recs)) { _ in .noFace }
        let parent = try XCTUnwrap(sp.idle.entries.compactMap { $0 }.first { $0.saved.type == BoxSprite.cart }).saved
        let rider = try XCTUnwrap(parent.siblings.first), wheel = try XCTUnwrap(parent.siblings.second)
        let r0 = try XCTUnwrap(sp.active.sprite(id: rider)), w0 = try XCTUnwrap(sp.active.sprite(id: wheel))
        XCTAssertEqual([Int(r0.type), Int(r0.layer), Int(r0.recordIndex), Int(r0.gravity)], [0xb72, 100, -1, 0])
        XCTAssertEqual([Int(w0.type), Int(w0.layer), Int(w0.recordIndex), Int(w0.gravity)], [0xb73, -1, -1, 0])
        XCTAssertEqual([r0.face, w0.face], [FaceRef(pict: 0xb72, index: 7, set: .encoded),
                                            FaceRef(pict: 0xb73, index: 0, set: .encoded)])
        XCTAssertEqual([Int(parent.gravity), Int(parent.friction), Int(parent.pushMass), Int(parent.layer)], [0x208, 6, 0xa0, 0])
        // Its arm (M l. 60871–60936) then the tail's children (M l. 61163–61171): the face row k by `+0xce` (3 → 0,
        // 0x22 → 4, 0x2e → 6, 0 keeps it); the rider's face = cell k + 7; the wheel's `+0x46 += vx >> 9` (arithmetic)
        // wrapped into 0…0x17, face = cell k + (`+0x46` >> 3)·7; the rider at the cart's (x, y), the wheel 0x26 lower.
        let cw = SpriteWorld(level: w.level, active: sp.active, records: sp.records)
        cw.tiles = w.tiles
        let cart = cw.active.insert(parent)
        cw.active.update(id: cart) { c in
            c.x = 100; c.y = 400 - 0x50; c.x256 = 100 << 8; c.y256 = Int32(400 - 0x50) << 8
            c.oldPosition = SpriteSlot.Point(x: 100, y: 400 - 0x50)
            c.ridingLatch = true
        }
        let cs = TileSolver(world: cw)
        func cartFrame(vx: Int32, ground: UInt8) throws -> [Int] {
            cw.active.update(id: cart) { $0.vx = vx; $0.vy = 0; $0.groundKind = ground }
            BoxSprite.handle(world: cw, id: cart, solver: cs, lights: &lights, effects: 1)
            let c = try XCTUnwrap(cw.active.sprite(id: cart))
            let rs = try XCTUnwrap(cw.active.sprite(id: rider)), ws = try XCTUnwrap(cw.active.sprite(id: wheel))
            XCTAssertEqual([rs.x, rs.y, ws.x, ws.y], [c.x, c.y, c.x, c.y + 0x26])
            return [c.face?.index ?? -1, rs.face?.index ?? -1, Int(ws.phase), ws.face?.index ?? -1, Int(ws.classTimer)]
        }
        XCTAssertEqual(try cartFrame(vx: 0x1200, ground: 3), [0, 7, 9, 0 + 7, 0])          // 0x1200 >> 9 = 9
        XCTAssertEqual(cw.active.sprite(id: cart)?.slip, 1)                                // ridden: `+0x112 + 1`
        XCTAssertEqual(try cartFrame(vx: 0x1200, ground: 0x22), [4, 11, 18, 4 + 14, 4])
        XCTAssertEqual(try cartFrame(vx: 0x1200, ground: 0), [4, 11, 3, 4, 4])            // 27 − 0x18; k kept
        XCTAssertEqual(try cartFrame(vx: -0x800, ground: 0x2e), [6, 13, 23, 6 + 14, 6])    // −1 + 0x18
        XCTAssertEqual(try cartFrame(vx: -0x100, ground: 3), [0, 7, 22, 0 + 14, 0])        // −0x100 >> 9 = −1
        XCTAssertEqual(try cartFrame(vx: 0x1ff, ground: 3), [0, 7, 22, 14, 0])             // 0x1ff >> 9 = 0
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
        // The shake for other damages d (M l. 61374–61381): n = d / 20, `+0xa6 = n + FastRand(n / 2)` — one draw.
        for d: Int16 in [2000, 990, 300, 61] {
            let id = try add(w, record: 160, x: 400, y: 100)
            let hp0 = try XCTUnwrap(w.active.sprite(id: id)).hp
            let f = shot(w, 0, x: 405, y: 120, hp: d)
            var r = w.rng
            let n = d / 20
            let want = n + r.next(n / 2)
            FerazelSession.hitCallback(w, id, f, lights: &lights)
            XCTAssertEqual(w.rng.seed, r.seed, "d \(d)")
            let s = try XCTUnwrap(w.active.sprite(id: id))
            XCTAssertEqual([s.hp, s.counterA6], [hp0 &- d, want], "d \(d)")
        }

        // The ice wall 2941's Setup (M l. 59469–59493): gravity 0xb4 then 0 (`+0x110` stored twice — it never falls),
        // HP 300, `+0x1b4 = 1`, friction 6, `+0x1bc = 4`, `+0x158 = y`, both callbacks 0, rect (0, 0, 0x20, 0x74).
        let q = w.records[158]
        let iceRecord = Placement(index: q.index, flag: q.flag, byte1: q.byte1, type: 2941, p1: 0, p2: 0, p3: 0, p4: 0,
                                  y: q.y, x: q.x)
        var ice = SpriteSlot(type: BoxSprite.iceWall, x: 300, y: 200, recordIndex: Int16(q.index))
        BoxSprite.setup(&ice, record: iceRecord, level: w.level)
        XCTAssertEqual([Int(ice.gravity), Int(ice.hp), Int(ice.friction), Int(ice.flashTable), Int(ice.clip.top),
                        Int(ice.classWord158)], [0, 300, 6, 1, 4, 200])
        XCTAssertEqual([ice.keepRecord, ice.hasHit, ice.hasTileHit], [true, false, false])
        XCTAssertEqual(ice.hotRect, IdleSprites.Rect(top: 0, left: 0, bottom: 0x74, right: 0x20))
        ice.face = FaceRef(pict: BoxSprite.iceWall, index: 0, set: .encoded)
        ice.centre = SpriteSlot.Point(x: 300 + 0x10, y: 200 + 0x3a)
        let iw = w.active.insert(ice)
        BoxSprite.handle(world: w, id: iw, solver: solver, lights: &lights, effects: 1)
        var iceNow = try XCTUnwrap(w.active.sprite(id: iw))
        XCTAssertEqual([iceNow.y, iceNow.dead ? 1 : 0], [200, 0])                  // HP 300: it stands
        // Its death (M l. 61032–61040): HP < 1 → `.ExplodeFaceIntoParticles(face, (y, x), 2, 2, 2, 0x32, 100)`, `+0xe9`,
        // then `FastRand(5000)` → `.STPlay3DSoundPitched(424, 1, 0x100, centre, R + 43000)`. A one-pixel face gives one
        // particle: R(0x14), R(0x2ee), R(100), R(0x1e) → gravity 0x32 + R30, vx R100 − 0x32, vy 0x28 − R750.
        func tok(_ op: UInt32, _ n: Int) -> [UInt8] {
            let t = op << 24 | UInt32(n)
            return [UInt8(t >> 24), UInt8(t >> 16 & 0xff), UInt8(t >> 8 & 0xff), UInt8(t & 0xff)]
        }
        let dot = ParticleFace(frame: [0, 0, 1, 1], bounds: [0, 0, 1, 1], tokens: tok(1, 4) + tok(2, 1) + [7, 0, 0, 0] + tok(0, 0))
        w.particleFaces = ParticleFaces(sprite: { _ in dot })
        w.active.update(id: iw) { $0.hp = 0 }
        w.player.cues = []
        var ri = w.rng
        _ = ri.next(0x14)
        let r750 = Int32(ri.next(0x2ee)), r100 = Int32(ri.next(100)), r30 = Int32(ri.next(0x1e))
        let pitch = Int32(ri.next(5000))
        let n0 = w.particles.counters.count
        BoxSprite.handle(world: w, id: iw, solver: solver, lights: &lights, effects: 1)
        w.particleFaces = ParticleFaces()
        XCTAssertEqual(w.rng.seed, ri.seed)
        iceNow = try XCTUnwrap(w.active.sprite(id: iw))
        XCTAssertTrue(iceNow.dead)
        XCTAssertEqual(w.particles.counters.count, n0 + 1)
        let pt = w.particles.records[Int(w.particles.counters.hint)]
        let ptGot: [Int32] = [Int32(pt.gravity), pt.vx, pt.vy, Int32(pt.kind), pt.x >> 8, pt.y >> 8]
        let ptWant: [Int32] = [0x32 + r30, r100 - 0x32, 0x28 - r750, -(7 + 0x100), 300, 201]
        XCTAssertEqual(ptGot, ptWant)
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDPitched, snd: 424, priority: 1, volume: 0x100,
                                                 position: SpriteSlot.Point(x: 300 + 0x10, y: 200 + 0x3a),
                                                 rate: pitch + 43000)])
    }
}
