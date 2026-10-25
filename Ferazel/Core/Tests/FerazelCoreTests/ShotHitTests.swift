import XCTest
import HectorResources
@testable import FerazelCore

/// SH (docs/plans/2026-10-24-ferazel-phase4.md): the player shots' impacts — `.HitPlayerShotSprite @ 1005a7fc` (M l.
/// 50947–51071), `.HitPlayerShotTileSprite @ 1005b0bc` (M l. 51219–51392), `.KillPlayerShot @ 1005ac34` (M l.
/// 51072–51218), the container arm `LAB_1005fd94` of `.HitBonusSprite` (M l. 53452–53486) and the stalactite's shot
/// case of `.HitBoxSprite` (M l. 61328–61482). Synthetic 16×16 grids over level 1's header (as `CastTests`); every
/// expected draw is re-derived from a copy of the stream at the call site, the geometry from the dump's arithmetic next
/// to each assertion.
final class ShotHitTests: XCTestCase {

    /// A 16×16 grid with the FG `cells` (col, row, raw cell value) and nothing else (BG empty: kind −1).
    private func world(_ cells: [(Int, Int, UInt16)]) throws -> SpriteWorld {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let w = SpriteWorld(level: try LevelFile.load(from: r, level: 1))
        var fg = [UInt16](repeating: 0, count: 16 * 16)
        for (c, row, v) in cells { fg[row * 16 + c] = v }
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: fg),
                           bg: TileMap(width: 16, height: 16, cells: [UInt16](repeating: 0, count: 16 * 16)),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        return w
    }

    /// An FG floor of kind 3 (tile 3, cell 4) on row 12: the surface at y 400.
    private func floor(crunchAt col: Int? = nil) -> [(Int, Int, UInt16)] {
        (0..<16).map { c in (c, 12, c == col ? 0x1000 | 4 : 4) }              // crunch direction 1, crunch kind 0
    }

    private func explosionPackage(_ r: inout FastRand) { for _ in 0..<0x2d { _ = r.next(2000); _ = r.next(2000); _ = r.next(2) } }
    private func effects(_ w: SpriteWorld, _ t: Int16) -> [SpriteSlot] {
        w.active.sprites.filter { $0.handler == .effect && $0.type == t }
    }

    /// One handle pass over the player shots in list order (followers precede their main, spells-detail-2 §4).
    private func handleShots(_ w: SpriteWorld, _ solver: TileSolver, lights: inout LightTable) {
        for id in w.active.sprites.filter({ $0.handler == .playerShot }).map(\.id) {
            PlayerShot.handle(world: w, id: id, solver: solver, lights: &lights, effects: 2)
        }
    }

    /// A shot record of `type` (the id, after the Setup's split) at (x, y) with the Setup's hot rect.
    private func shot(_ w: SpriteWorld, _ type: Int16, power: Int32 = 1, x: Int = 1000, y: Int = 300,
                      hp: Int16 = 100) -> Int {
        var s = SpriteSlot(type: type, x: x, y: y)
        s.handler = .playerShot
        s.hasHit = true
        s.power = power
        s.hp = hp
        s.hotRect = IdleSprites.Rect(top: 3, left: 8, bottom: 0xc, right: 0xf)
        s.centre = SpriteSlot.Point(x: x + 11, y: y + 7)
        return w.active.insert(s)
    }

    // MARK: - tile hits

    func testFireballImpactOnWall() throws {
        // A power-2 Fireball (gravity forced 0) flying right at 8 px a frame into a column of FG kind 2 (the right-half
        // wall, tile rect x 16…32) at col 8: `.HitPlayerShotTileSprite`'s FG arm → `.WallBounce(s, 2, &pos, &vCentre, 0,
        // +0x34, 0, 0)` (M l. 51259–51263) stops it at X + 16 − right = 272 − 15 = 257 and reports the contact → id 0 is
        // no 3 / 4 → `.KillPlayerShot(s, 1, 1)` (M l. 51298–51311): snd 301 Rand at the centre `+0xe`, effect 0 at
        // (x − 8, y − 0xc) = (249, 188) (the stack offset is off the position during the separation), the main and its
        // follower `+0xe9 = 1`. One kill: the later cells see `+0xe9` and return.
        let wall = (0..<16).map { (8, $0, UInt16(2 + 1)) }
        let w = try world(wall)
        let main = try XCTUnwrap(PlayerShot.spawn(w, type: 0x0002, x: 200, y: 200))
        let follower = try XCTUnwrap(w.active.sprite(id: main)?.siblings.first)
        w.active.update(id: main) { s in
            s.gravity = 0
            s.vx = 0x800
        }
        let solver = TileSolver(world: w)
        var lights = LightTable()
        var r = w.rng
        var frames = 0
        while w.active.sprite(id: main)?.dead == false && frames < 20 {
            handleShots(w, solver, lights: &lights)
            frames += 1
        }
        XCTAssertEqual(frames, 8)                                           // x 200 + 8·8 = 264 > 257: the contact
        XCTAssertEqual(w.active.sprite(id: main)?.killCount, 1)
        XCTAssertEqual(w.active.sprite(id: follower)?.killCount, 1)
        let rate = r.soundRate()
        explosionPackage(&r)
        // The sound's centre is the one `.KillPlayerShot`'s opening `.StandardSpriteCleanup` recomputes at the stopped
        // position: (257 + 8 + 3, 200 + 3 + 4).
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDRand, snd: 301, priority: 1, volume: 0x100,
                                                 position: SpriteSlot.Point(x: 268, y: 207), rate: rate)])
        XCTAssertEqual(w.rng.seed, r.seed)
        let e = effects(w, 0)
        XCTAssertEqual(e.map { [$0.x, $0.y] }, [[249, 188]])
        XCTAssertEqual(lights.slots[Int(try XCTUnwrap(e.first).light)].colour, 0x16)         // the package's light, not recoloured
        // BG kinds < 100 take the same arm (M l. 51330–51347): a kind-2 BG cell stops a Fireball the same way.
        let w2 = try world([])
        let bg = (0..<16 * 16).map { $0 % 16 == 8 ? UInt16(2 + 1) : 0 }
        w2.tiles = TileGrid(fg: w2.tiles.fg, bg: TileMap(width: 16, height: 16, cells: bg), fgKinds: Array(0..<0x60),
                            bgKinds: Array(0..<0x60))
        let b = try XCTUnwrap(PlayerShot.spawn(w2, type: 0x0001, x: 200, y: 200))
        w2.active.update(id: b) { s in
            s.gravity = 0
            s.vx = 0x800
        }
        let solver2 = TileSolver(world: w2)
        var lights2 = LightTable()
        for _ in 0..<8 { handleShots(w2, solver2, lights: &lights2) }
        XCTAssertEqual(w2.active.sprite(id: b)?.killCount, 1)
        XCTAssertEqual(effects(w2, 0).map { [$0.x, $0.y] }, [[249, 188]])
    }

    func testSeedsBounceThenExplode() throws {
        // A seed 0x5a (hot rect (2, −6, 10, 6), gravity 0xfa) dropped onto the kind-3 floor (surface 400):
        // `.WallBounce(s, 3, …, 0xa0, +0x34, 0, 1)` (M l. 51248–51251, 51259–51263) reverses vy at 0xa0/256 (0.625)
        // and puts it on y 394; the shot lives while |vy| ≥ 0x200 after the contact (M l. 51298–51311) and dies at the
        // first contact below: snd 435, the flash 3, the shake 0x14, 0x4b7 at (x − 0x2a, y − 0x2a), eight 0x442 with
        // `+0x46` = R(7) (M l. 51145–51180).
        let w = try world(floor())
        let id = try XCTUnwrap(PlayerShot.spawn(w, type: 0x5a01, x: 100, y: 300))
        w.active.update(id: id) { $0.vy = 0x900 }
        let solver = TileSolver(world: w)
        var lights = LightTable()
        var bounces: [[Int32]] = []
        var r = w.rng
        var frames = 0
        while w.active.sprite(id: id)?.dead == false && frames < 400 {
            let before = try XCTUnwrap(w.active.sprite(id: id))
            r = w.rng
            handleShots(w, solver, lights: &lights)
            let after = try XCTUnwrap(w.active.sprite(id: id))
            let entry = before.vy + 0xfa
            if 0 < entry && after.vy < 0 {
                bounces.append([entry, after.vy])
                XCTAssertEqual(after.y, 394)
            }
            frames += 1
        }
        XCTAssertGreaterThanOrEqual(bounces.count, 2)
        for b in bounces { XCTAssertEqual(b[1], 0 &- ((b[0] &* 0xa0) >> 8)) }
        // Every bounce but the last left |vy| ≥ 0x200 (alive); the last one below (the kill).
        XCTAssertTrue(bounces.dropLast().allSatisfy { 0x200 <= -$0[1] })
        XCTAssertLessThan(-(bounces.last?[1] ?? 0x200), 0x200)
        let last = try XCTUnwrap(w.active.sprite(id: id))
        XCTAssertTrue(last.dead)
        XCTAssertLessThan(abs(last.vy), 0x200)
        XCTAssertEqual([last.x, last.y], [100, 394])
        // The draws of the kill frame: the sound, the big explosion's package, then per smoke its package, R(0x96),
        // R(7).
        let rate = r.soundRate()
        explosionPackage(&r)
        var phases: [Int16] = []
        for _ in 0..<8 {
            explosionPackage(&r)
            _ = r.next(0x96)
            phases.append(r.next(7))
        }
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual(w.player.cues.filter { $0.snd == 435 }.map(\.rate), [rate])
        XCTAssertEqual([Int(w.flash.count), Int(w.shakeStore ?? 0)], [3, 0x14])
        let big = effects(w, EffectSprite.bigExplosion)
        XCTAssertEqual(big.map { [$0.x, $0.y, Int($0.mode)] }, [[100 - 0x2a, 394 - 0x2a, 0]])
        // `MTNewSprite(0x4b7, …, 0xc, …)`: `.SetupEffectSprite` stores layer 0xb before the insert (M l. 53722).
        XCTAssertEqual(big.map(\.layer), [0xb])
        XCTAssertEqual(effects(w, BackgroundSprite.smoke).map(\.phase), phases)
    }

    func testZiridiumTint() throws {
        // `+0xf4 ≠ 0` (Ziridium) → the 0x4b7's `+0xb8 = 0x10004` (M l. 51153–51155); `+0xf0 ≠ 0` → no fragments (M l.
        // 51156): the kill draws only the sound and the big explosion's package. Dropped from just above the floor, the
        // first contact (vy 0x1fa → −0x13c) is below 0x200: it explodes there.
        for (f4, f0) in [(Int32(1), Int32(0)), (0, 1)] {
            let w = try world(floor())
            let id = try XCTUnwrap(PlayerShot.spawn(w, type: 0x5a01, x: 100, y: 394))
            w.active.update(id: id) { s in
                s.vy = 0x100
                s.classWordF4 = f4
                s.seedHidden = f0
            }
            let solver = TileSolver(world: w)
            var lights = LightTable()
            var r = w.rng
            handleShots(w, solver, lights: &lights)
            XCTAssertEqual(w.active.sprite(id: id)?.dead, true, "f4 \(f4)")
            _ = r.soundRate()
            explosionPackage(&r)
            if f0 == 0 {
                for _ in 0..<8 {
                    explosionPackage(&r)
                    _ = r.next(0x96)
                    _ = r.next(7)
                }
            }
            XCTAssertEqual(w.rng.seed, r.seed, "f4 \(f4)")
            XCTAssertEqual(effects(w, EffectSprite.bigExplosion).map(\.mode), [f4 == 1 ? 0x10004 : 0], "f4 \(f4)")
            XCTAssertEqual(effects(w, BackgroundSprite.smoke).count, f0 == 0 ? 8 : 0, "f4 \(f4)")
        }
    }

    func testCrunchKills() throws {
        // A Fireball falling onto a crunch cell (col 5, row 12: direction 1, crunch kind 0): `.SeparateFromTiles2`
        // makes the crunch call before the FG call (l. 35330–35352); `.CrunchTile(pos, (short)+0x158)` (strength 1)
        // breaks kind 0 at once and returns 1 → `.KillPlayerShot(s, 1, 1)` (M l. 51380–51386). Called once: the
        // later calls of the pass see `+0xe9`.
        let w = try world(floor(crunchAt: 5))
        let id = try XCTUnwrap(PlayerShot.spawn(w, type: 0x0001, x: 180, y: 360))
        w.active.update(id: id) { $0.vy = 0x400 }
        let solver = TileSolver(world: w)
        var lights = LightTable()
        var frames = 0
        while w.active.sprite(id: id)?.dead == false && frames < 20 {
            handleShots(w, solver, lights: &lights)
            frames += 1
        }
        XCTAssertEqual(w.active.sprite(id: id)?.killCount, 1)
        XCTAssertEqual(w.globals.crunchCount, 1)
        XCTAssertEqual(w.globals.crunchLog.map { [Int($0.col), Int($0.row)] }, [[5, 12]])
        XCTAssertEqual(w.player.cues.filter { $0.snd == 424 }.count, 1)
        XCTAssertEqual(w.player.cues.filter { $0.snd == 301 }.count, 1)
        XCTAssertEqual(effects(w, 0).count, 1)
        // The upper V Blade (id 6) takes the crunch layer only (M l. 51257): it crunches the cell and is not killed
        // (M l. 51383–51384), and passes the floor.
        let w2 = try world(floor(crunchAt: 5))
        let v = try XCTUnwrap(PlayerShot.spawn(w2, type: 0x0601, x: 176, y: 340))
        w2.player.centreY = 400
        w2.active.update(id: v) { $0.vy = 0x400 }
        let solver2 = TileSolver(world: w2)
        var lights2 = LightTable()
        for _ in 0..<30 { handleShots(w2, solver2, lights: &lights2) }
        let blade = try XCTUnwrap(w2.active.sprite(id: v))
        XCTAssertFalse(blade.dead)
        XCTAssertGreaterThan(blade.y, 420)
        XCTAssertEqual(w2.globals.crunchLog.map { [Int($0.col), Int($0.row)] }, [[5, 12]])
        XCTAssertFalse(w2.player.cues.contains { $0.snd == 301 })
    }

    // MARK: - sprite hits

    func testBoomerangCaughtRefund() throws {
        // `.HitPlayerShotSprite` (M l. 50972–50990): the other is the player, id 5, age `+0x14c` > 10 → `+0xe9 = 1`,
        // magic `G+0xe` + 8 with no clamp, power > 1 → the followers flagged. No `.KillPlayerShot`: no sound, no effect.
        for (age, magic, caught) in [(Int32(11), Int16(552), true), (11, 560, true), (10, 552, false)] {
            let w = try world([])
            let pID = try XCTUnwrap(Player.spawn(world: w, x: 1000, y: 300))
            let b = try XCTUnwrap(PlayerShot.spawn(w, type: 0x502, x: 1000, y: 300))
            let follower = try XCTUnwrap(w.active.sprite(id: b)?.siblings.first)
            w.active.update(id: b) { $0.shotAge = age }
            w.globals.magic = magic
            w.globals.maxMagic = 560
            var lights = LightTable()
            FerazelSession.hitCallback(w, b, pID, lights: &lights)
            XCTAssertEqual(w.active.sprite(id: b)?.dead, caught, "age \(age)")
            XCTAssertEqual(w.active.sprite(id: follower)?.dead, caught, "age \(age)")
            XCTAssertEqual(w.globals.magic, caught ? magic + 8 : magic, "age \(age)")
            XCTAssertTrue(w.player.cues.isEmpty)
            XCTAssertTrue(effects(w, 5).isEmpty)
        }
        // Another id touching the player: nothing (M l. 51031: the player's Handle is excluded).
        let w = try world([])
        let pID = try XCTUnwrap(Player.spawn(world: w, x: 1000, y: 300))
        let f = shot(w, 0)
        w.active.update(id: f) { $0.shotAge = 50 }
        var lights = LightTable()
        FerazelSession.hitCallback(w, f, pID, lights: &lights)
        XCTAssertEqual(w.active.sprite(id: f)?.dead, false)
    }

    /// A Bonus container of `type` at (2000, 1000) on record 5 (p4 0), through `.SetupBonusSprite`.
    private func container(_ w: SpriteWorld, _ type: Int16, lights: inout LightTable) throws -> Int {
        let p = w.records[5]
        w.records[5] = Placement(index: 5, flag: 1, byte1: p.byte1, type: type, p1: 0, p2: 0, p3: 0, p4: 0, y: 1000,
                                 x: 2000)
        let id = try XCTUnwrap(w.newSprite(type: type, x: 2000, y: 1000, layer: 1, handler: .bonus, record: 5) { s in
            _ = try! BonusSprite.setup(&s, x: 2000, y: 1000, level: w.level, records: w.records, effects: 2,
                                       lightCount: 0, counting: false, rng: &w.rng) { _, _, _, _ in -1 }
        })
        w.active.update(id: id) { s in
            let r = s.hotRect
            s.centre = SpriteSlot.Point(x: s.x + r.left + ((r.right - r.left) >> 1), y: s.y + r.top + ((r.bottom - r.top) >> 1))
        }
        return id
    }

    func testContainerOpens() throws {
        // The torch 1307 (`+0xb0 = 1`, p4 0) hit by a Fireball (`+0xa6` 0) — `LAB_1005fd94` (M l. 53472–53503): `+0xb0 =
        // 0`, hot rect zeroed, **record p4 = 1**, `.KillPlayerShot(shot, 1, 1)`, score + 150; health 0x230/0x230 is
        // 256/256, magic 0x100/0x230 is 116/256 < 256 and health > 0x25 → a 0x514 at (centre − 9) with vy = −2000 −
        // R(1000), drawn after its Setup's R(4), R(6), R(3) and the tail's R(60).
        let w = try world([])
        var lights = LightTable()
        let torch = try container(w, BonusSprite.torch, lights: &lights)
        XCTAssertEqual(w.active.sprite(id: torch)?.pickupDelay, 1)
        w.globals.health = 0x230
        w.globals.maxHealth = 0x230
        w.globals.magic = 0x100
        w.globals.maxMagic = 0x230
        w.globals.score = 1000
        let c = try XCTUnwrap(w.active.sprite(id: torch)).centre
        let fire = shot(w, 0, x: 2000, y: 1000)
        var r = w.rng
        _ = r.soundRate()
        explosionPackage(&r)
        _ = r.next(4); _ = r.next(6); _ = r.next(3); _ = r.next(0x3c)       // the Setup's tail: the flicker timer
        let vy = -2000 - Int32(r.next(1000))
        FerazelSession.hitCallback(w, torch, fire, lights: &lights)
        XCTAssertEqual(w.rng.seed, r.seed)
        let t = try XCTUnwrap(w.active.sprite(id: torch))
        XCTAssertEqual([Int(t.pickupDelay), Int(w.records[5].p4)], [0, 1])
        XCTAssertEqual(t.hotRect, IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0))
        XCTAssertFalse(t.dead)
        XCTAssertEqual(w.globals.score, 1150)
        XCTAssertEqual(w.active.sprite(id: fire)?.dead, true)
        let crystals = w.active.sprites.filter { $0.handler == .bonus && ($0.type == 0x514 || $0.type == 0x515) }
        XCTAssertEqual(crystals.map { [Int($0.type), $0.x, $0.y, Int($0.vy)] }, [[0x514, c.x - 9, c.y - 9, Int(vy)]])
        XCTAssertEqual(w.player.cues.map(\.snd), [301])
        // The shot's own side afterwards (M l. 51032–51036): the torch's `+0xb0` is 0 now → nothing.
        FerazelSession.hitCallback(w, fire, torch, lights: &lights)
        XCTAssertEqual(w.player.cues.map(\.snd), [301])
        // A second shot: spent (`+0xb0 == 0`) → nothing on either side, the shot is not consumed.
        let second = shot(w, 0, x: 2000, y: 1000)
        let seed0 = w.rng.seed
        FerazelSession.hitCallback(w, torch, second, lights: &lights)
        FerazelSession.hitCallback(w, second, torch, lights: &lights)
        XCTAssertEqual(w.active.sprite(id: second)?.dead, false)
        XCTAssertEqual([w.globals.score, w.rng.seed == seed0 ? 1 : 0], [1150, 1])
        // The orb 0x50 opens nothing (bonus side M l. 53473–53475; shot side M l. 51034).
        let w2 = try world([])
        var lights2 = LightTable()
        let torch2 = try container(w2, BonusSprite.torch, lights: &lights2)
        let orb = shot(w2, PlayerShot.orb, x: 2000, y: 1000, hp: 300)
        FerazelSession.hitCallback(w2, torch2, orb, lights: &lights2)
        FerazelSession.hitCallback(w2, orb, torch2, lights: &lights2)
        XCTAssertEqual(w2.active.sprite(id: torch2)?.pickupDelay, 1)
        XCTAssertEqual(w2.active.sprite(id: orb)?.dead, false)
        // The shot's side first, on a fresh torch (M l. 51032–51036): `.KillPlayerShot(s, 1, 1)`; then the torch's side
        // still sees `+0xa6 == 0` and opens it, killing the shot a second time (two 301s, two effects) — as written.
        let w3 = try world([])
        var lights3 = LightTable()
        let torch3 = try container(w3, BonusSprite.torch, lights: &lights3)
        w3.globals.maxHealth = 0x230
        w3.globals.maxMagic = 0x230
        let fire3 = shot(w3, 0, x: 2000, y: 1000)
        FerazelSession.hitCallback(w3, fire3, torch3, lights: &lights3)
        FerazelSession.hitCallback(w3, torch3, fire3, lights: &lights3)
        XCTAssertEqual(w3.player.cues.map(\.snd), [301, 301])
        XCTAssertEqual(effects(w3, 0).count, 2)
        XCTAssertEqual(w3.records[5].p4, 1)
        // The effect flag cleared by the clip window (an Ice Crystals shot, id 1, wholly hidden in a wall tunnel):
        // `.KillPlayerShot`'s ids 1…4 arm recolours the light named by the caller's r29 + 0x9a — at this call site r29 =
        // G + 4 (`addi r29,r31,0x4`, raw `1005fdc0`), so the slot is the short at G + 0x9e: inventory slot 12's count.
        let w4 = try world([])
        var lights4 = LightTable()
        let torch4 = try container(w4, BonusSprite.torch, lights: &lights4)
        w4.globals.maxHealth = 0x230
        w4.globals.maxMagic = 0x230
        w4.globals.inventory[12].count = 7
        let ice = shot(w4, 1, x: 2000, y: 1000)
        w4.active.update(id: ice) { s in
            s.face = FaceRef(pict: 0x44e, index: 0, set: .encoded)
            s.clip = SpriteClip(left: 0x18, right: 32000, bottom: 32000, top: 0)   // face 0…24 wholly left of the window
        }
        FerazelSession.hitCallback(w4, torch4, ice, lights: &lights4)
        XCTAssertTrue(effects(w4, 5).isEmpty)
        XCTAssertEqual(lights4.slots[7].colour, 0x21)
        XCTAssertEqual(w4.player.cues.map(\.snd), [301])
    }

    func testRockPileDestroyed() throws {
        // The rock pile 1303 (0x517, `+0xb0` 0): the torch's side kills it (`.KillBonus`, M l. 53490), kills the
        // shot, score + 150; health 0x25 is not above 0x25 → the 0x515 (M l. 53494–53509). Its shot's side does nothing
        // (`+0xb0 == 0`, M l. 51034).
        let w = try world([])
        var lights = LightTable()
        let pile = try container(w, 0x517, lights: &lights)
        w.globals.health = 0x25
        w.globals.maxHealth = 0x230
        w.globals.magic = 0
        w.globals.maxMagic = 0x230
        let fire = shot(w, 0, x: 2000, y: 1000)
        FerazelSession.hitCallback(w, fire, pile, lights: &lights)
        XCTAssertEqual(w.active.sprite(id: fire)?.dead, false)
        FerazelSession.hitCallback(w, pile, fire, lights: &lights)
        XCTAssertEqual(w.active.sprite(id: pile)?.dead, true)
        XCTAssertEqual(w.active.sprite(id: fire)?.dead, true)
        XCTAssertEqual(w.globals.score, 150)
        XCTAssertEqual(w.records[5].p4, 0)
        let crystals = w.active.sprites.filter { $0.handler == .bonus && ($0.type == 0x514 || $0.type == 0x515) }
        XCTAssertEqual(crystals.map(\.type), [0x515])
        // Health 0x26 with magic% below health% → the 0x514.
        let w2 = try world([])
        var lights2 = LightTable()
        let pile2 = try container(w2, 0x517, lights: &lights2)
        w2.globals.health = 0x26
        w2.globals.maxHealth = 0x230
        w2.globals.magic = 0
        w2.globals.maxMagic = 0x230
        FerazelSession.hitCallback(w2, pile2, shot(w2, 0, x: 2000, y: 1000), lights: &lights2)
        XCTAssertEqual(w2.active.sprites.filter { $0.type == 0x514 || $0.type == 0x515 }.map(\.type), [0x514])
    }

    func testIceWall2941Needs300() throws {
        // A Box with no one-way top and no surface function (M l. 51037–51049): the 2941 (0xb7d) with `+0x116 < 1` and
        // a shot whose `+0xa4` is exactly 300 (`cmpwi r0,0x12c`, raw `1005ab7c`) → HP − 0x50, `+0xaa = 10`, `+0x116 =
        // 10`, `.STPlay3DSoundPitched(419, 1, 0x100, shot +0xa, 35000)`; then `.KillPlayerShot(s, 1, 1)` whatever.
        let w = try world([])
        var wall = SpriteSlot(type: 0xb7d, x: 2000, y: 1000)
        wall.handler = .box
        wall.hasHit = true
        wall.hp = 300
        let wallID = w.active.insert(wall)
        var lights = LightTable()
        var hps: [Int16] = []
        for k in 0..<4 {
            w.active.update(id: wallID) { $0.invulnerable = 0 }
            w.player.cues = []
            let s = shot(w, 2, x: 2000 + k, y: 1000, hp: 300)
            FerazelSession.hitCallback(w, s, wallID, lights: &lights)
            let o = try XCTUnwrap(w.active.sprite(id: wallID))
            hps.append(o.hp)
            XCTAssertEqual([Int(o.flash), Int(o.invulnerable)], [10, 10])
            XCTAssertEqual(w.player.cues.first, PlayerCue(call: .threeDPitched, snd: 419, priority: 1, volume: 0x100,
                                                          position: SpriteSlot.Point(x: 2000 + k, y: 1000), rate: 35000))
            XCTAssertEqual(w.player.cues.map(\.snd), [419, 301])
            XCTAssertEqual(w.active.sprite(id: s)?.dead, true)
        }
        XCTAssertEqual(hps, [220, 140, 60, -20])
        // Power 2 (`+0xa4` 600): no damage, the shot still dies; and none while `+0x116 > 0`.
        for (hp, invulnerable) in [(Int16(600), Int16(0)), (300, 1)] {
            w.active.update(id: wallID) { s in
                s.hp = 300
                s.invulnerable = invulnerable
                s.flash = 0
            }
            w.player.cues = []
            let s = shot(w, 2, x: 2000, y: 1000, hp: hp)
            FerazelSession.hitCallback(w, s, wallID, lights: &lights)
            XCTAssertEqual(w.active.sprite(id: wallID)?.hp, 300)
            XCTAssertEqual(w.active.sprite(id: wallID)?.flash, 0)
            XCTAssertEqual(w.player.cues.map(\.snd), [301])
            XCTAssertEqual(w.active.sprite(id: s)?.dead, true)
        }
        // A one-way Box: `.PlatformBounce(s, box, centre, 0, +0x34, 0)` (M l. 51050–51060) — no contact, no kill.
        var ledge = SpriteSlot(type: 0xb7d, x: 2000, y: 2000)
        ledge.handler = .box
        ledge.oneWay = true
        ledge.hp = 300
        ledge.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x20, right: 0x20)
        let ledgeID = w.active.insert(ledge)
        let far = shot(w, 2, x: 2000, y: 1000, hp: 300)
        FerazelSession.hitCallback(w, far, ledgeID, lights: &lights)
        XCTAssertEqual(w.active.sprite(id: far)?.dead, false)
        XCTAssertEqual(w.active.sprite(id: ledgeID)?.hp, 300)
        // The stalactite 2932's side (`.HitBoxSprite` M l. 61374–61382): HP − d, shake `+0xa6 = d/20 + R(d/20/2)`.
        var stal = SpriteSlot(type: BoxSprite.stalactite, x: 3000, y: 1000)
        stal.handler = .box
        stal.hasHit = true
        stal.hp = 150
        let stalID = w.active.insert(stal)
        let fire = shot(w, 0, x: 3000, y: 1000, hp: 100)
        var r = w.rng
        let shake = 5 + r.next(2)
        FerazelSession.hitCallback(w, stalID, fire, lights: &lights)
        XCTAssertEqual(w.rng.seed, r.seed)
        let st = try XCTUnwrap(w.active.sprite(id: stalID))
        XCTAssertEqual([Int(st.hp), Int(st.counterA6)], [50, Int(shake)])
        XCTAssertEqual(w.active.sprite(id: fire)?.dead, false)              // its own side kills it, not the box's
    }
}
