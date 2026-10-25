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
        // BG kinds 100…199 (M l. 51348–51372): `.WallBounceBG(s, kind − 100, …)` — a BG cell of kind 103 is the one-way
        // floor 3 (as 103 itself is no kind, > 0x3c); the contact kills the shot. A Fireball falls onto it on row 12.
        let w3 = try world([])
        var bgKinds = [Int](repeating: 0, count: 0x60)
        bgKinds[3] = 103
        w3.tiles = TileGrid(fg: w3.tiles.fg, bg: TileMap(width: 16, height: 16,
                                                          cells: (0..<16 * 16).map { $0 / 16 == 12 ? 4 : 0 }),
                            fgKinds: Array(0..<0x60), bgKinds: bgKinds)
        let d = try XCTUnwrap(PlayerShot.spawn(w3, type: 0x0001, x: 180, y: 360))
        w3.active.update(id: d) { $0.vy = 0x400 }
        let solver3 = TileSolver(world: w3)
        var lights3 = LightTable()
        var frames3 = 0
        while w3.active.sprite(id: d)?.dead == false && frames3 < 20 {
            handleShots(w3, solver3, lights: &lights3)
            frames3 += 1
        }
        XCTAssertEqual(w3.active.sprite(id: d)?.killCount, 1)
        XCTAssertLessThan(frames3, 20)
        XCTAssertLessThanOrEqual(try XCTUnwrap(w3.active.sprite(id: d)).y, 400)       // stopped on the floor, not through it
        XCTAssertEqual(w3.player.cues.filter { $0.snd == 301 }.count, 1)
        // The Tree Trunk (id 4) landing on an FG floor: `.WallBounce` grounds it (`+0xce`) and the contact takes the
        // trunk arm (M l. 51312–51327): the trunk bottom 0x2c8 (// later: SW, its Setup draws nothing), an effect 2
        // at (trunk +0xc − 6, trunk +0xa − 9) = (centre.x − 8 − 6, centre.y − 6 − 9) with `+0x46 = 8` and light colour
        // 0x42, the shot `+0xe9 = 1`, `.STPlay3DSound(302, 1, 0x100, shot +0xe)` — no `.KillPlayerShot` (no 301).
        let w4 = try world(floor())
        let trunk = try XCTUnwrap(PlayerShot.spawn(w4, type: 0x0401, x: 180, y: 360))
        w4.active.update(id: trunk) { $0.vy = 0x400 }
        let solver4 = TileSolver(world: w4)
        var lights4 = LightTable()
        var frames4 = 0
        while w4.active.sprite(id: trunk)?.dead == false && frames4 < 20 {
            handleShots(w4, solver4, lights: &lights4)
            frames4 += 1
        }
        let landed = try XCTUnwrap(w4.active.sprite(id: trunk))
        XCTAssertTrue(landed.dead)
        XCTAssertNotEqual(landed.groundKind, 0)
        // The centre at the landing (the frame's later steps refresh it): the sound's position.
        let at = try XCTUnwrap(w4.player.cues.first { $0.snd == 302 }?.position)
        XCTAssertEqual(w4.player.cues, [PlayerCue(call: .threeD, snd: 302, priority: 1, volume: 0x100, position: at)])
        XCTAssertEqual(at.x, landed.centre.x)
        let grown = effects(w4, 2)
        XCTAssertEqual(grown.map { [$0.x, $0.y, Int($0.phase)] }, [[at.x - 14, at.y - 15, 8]])
        XCTAssertEqual(lights4.slots[Int(try XCTUnwrap(grown.first).light)].colour, 0x42)
        // Any other id grounded by the floor takes the contact rule (`+4 != 4`, M l. 51298): a Fireball falling onto
        // it dies with 301, no 302.
        let w6 = try world(floor())
        let fb = try XCTUnwrap(PlayerShot.spawn(w6, type: 0x0001, x: 180, y: 360))
        w6.active.update(id: fb) { $0.vy = 0x400 }
        let solver6 = TileSolver(world: w6)
        var lights6 = LightTable()
        for _ in 0..<20 where w6.active.sprite(id: fb)?.dead == false { handleShots(w6, solver6, lights: &lights6) }
        XCTAssertNotEqual(w6.active.sprite(id: fb)?.groundKind, 0)
        XCTAssertEqual(w6.player.cues.map(\.snd), [301])
        // A Tree Trunk flying into the kind-2 wall is not grounded: the contact rule kills it (snd 301, effect 2,
        // M l. 51298–51311), no 302.
        let w5 = try world(wall)
        let side = try XCTUnwrap(PlayerShot.spawn(w5, type: 0x0401, x: 200, y: 200))
        w5.active.update(id: side) { s in
            s.gravity = 0
            s.vx = 0x800
        }
        let solver5 = TileSolver(world: w5)
        var lights5 = LightTable()
        for _ in 0..<8 { handleShots(w5, solver5, lights: &lights5) }
        XCTAssertEqual(w5.active.sprite(id: side)?.groundKind, 0)
        XCTAssertEqual(w5.active.sprite(id: side)?.killCount, 1)
        XCTAssertEqual(w5.player.cues.map(\.snd), [301])
        XCTAssertEqual(effects(w5, 2).count, 1)
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
        // The exact threshold (`iVar8 < 0x200`, M l. 51302): an entry vy of 820 bounces to −((820·0xa0) >> 8) = −0x200
        // and lives; 819 bounces to −0x1ff and dies.
        for (entry, dies) in [(Int32(820), false), (819, true)] {
            let w2 = try world(floor())
            let s2 = try XCTUnwrap(PlayerShot.spawn(w2, type: 0x5a01, x: 100, y: 394))
            w2.active.update(id: s2) { $0.vy = entry - 0xfa }
            let solver2 = TileSolver(world: w2)
            var lights2 = LightTable()
            handleShots(w2, solver2, lights: &lights2)
            let after = try XCTUnwrap(w2.active.sprite(id: s2))
            XCTAssertEqual(after.vy, entry == 820 ? -0x200 : -0x1ff, "entry \(entry)")
            XCTAssertEqual(after.dead, dies, "entry \(entry)")
        }
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
        // Strength 1 (`+0x158` from the Setup, `(short)` M l. 51381) against crunch kind 2 (breaks only at strength 2):
        // `.CrunchTile` plays 423 (only if idle), breaks nothing and returns 1 → the Fireball is killed. Strength 2
        // would break it (424); 0 would return the kind without the 423.
        let w3 = try world((0..<16).map { c in (c, 12, c == 5 ? 0x1000 | 0x200 | 4 : 4) })
        let k2 = try XCTUnwrap(PlayerShot.spawn(w3, type: 0x0001, x: 180, y: 360))
        XCTAssertEqual(w3.active.sprite(id: k2)?.crunchStrength, 1)
        w3.active.update(id: k2) { $0.vy = 0x400 }
        let solver3 = TileSolver(world: w3)
        var lights3 = LightTable()
        var frames3 = 0
        while w3.active.sprite(id: k2)?.dead == false && frames3 < 20 {
            handleShots(w3, solver3, lights: &lights3)
            frames3 += 1
        }
        XCTAssertEqual(w3.active.sprite(id: k2)?.killCount, 1)
        XCTAssertEqual(w3.globals.crunchCount, 0)
        XCTAssertEqual(w3.player.cues.filter { $0.snd == 423 || $0.snd == 424 }.map { [Int($0.snd), $0.onlyIfIdle ? 1 : 0] },
                       [[423, 1]])
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
        // An idled player record (`+0x4c` 0) is not the player's Handle (M l. 50972): the Boomerang is not caught.
        let w2 = try world([])
        let p2 = try XCTUnwrap(Player.spawn(world: w2, x: 1000, y: 300))
        let b2 = try XCTUnwrap(PlayerShot.spawn(w2, type: 0x501, x: 1000, y: 300))
        w2.active.update(id: b2) { $0.shotAge = 11 }
        w2.active.update(id: p2) { $0.handleCleared = true }
        w2.globals.magic = 552
        FerazelSession.hitCallback(w2, b2, p2, lights: &lights)
        XCTAssertEqual(w2.active.sprite(id: b2)?.dead, false)
        XCTAssertEqual(w2.globals.magic, 552)
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
        // A shot with `+0xa6 ≠ 0` (M l. 53475) and an idled shot (`+0x4c` 0 ≠ the player-shot Handle, M l. 53473–53474)
        // open nothing; an idled torch is no Bonus to the shot's side (M l. 51032): the shot lives.
        w2.globals.maxHealth = 0x230
        w2.globals.maxMagic = 0x230
        let busy = shot(w2, 0, x: 2000, y: 1000)
        w2.active.update(id: busy) { $0.counterA6 = 1 }
        let idled = shot(w2, 0, x: 2000, y: 1000)
        w2.active.update(id: idled) { $0.handleCleared = true }
        let seed2 = w2.rng.seed
        FerazelSession.hitCallback(w2, torch2, busy, lights: &lights2)
        FerazelSession.hitCallback(w2, torch2, idled, lights: &lights2)
        XCTAssertEqual(w2.active.sprite(id: torch2)?.pickupDelay, 1)
        XCTAssertEqual([w2.active.sprite(id: busy)?.dead, w2.active.sprite(id: idled)?.dead], [false, false])
        XCTAssertEqual([Int(w2.records[5].p4), Int(w2.globals.score), w2.rng.seed == seed2 ? 1 : 0], [0, 0, 1])
        w2.active.update(id: torch2) { $0.handleCleared = true }
        let probe = shot(w2, 0, x: 2000, y: 1000)
        FerazelSession.hitCallback(w2, probe, torch2, lights: &lights2)
        XCTAssertEqual(w2.active.sprite(id: probe)?.dead, false)
        XCTAssertTrue(w2.player.cues.isEmpty)
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
        // Equal percentages (magic 0x118/0x230 and health 0x118/0x230, both 128/256): `(m << 8)/M < (h << 8)/H` is
        // false (`cmpw r28,r25; ble`, raw `1005fe74`) → the 0x515.
        let w3 = try world([])
        var lights3 = LightTable()
        let pile3 = try container(w3, 0x517, lights: &lights3)
        w3.globals.health = 0x118
        w3.globals.maxHealth = 0x230
        w3.globals.magic = 0x118
        w3.globals.maxMagic = 0x230
        FerazelSession.hitCallback(w3, pile3, shot(w3, 0, x: 2000, y: 1000), lights: &lights3)
        XCTAssertEqual(w3.active.sprites.filter { $0.type == 0x514 || $0.type == 0x515 }.map(\.type), [0x515])
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
        // An idled 2941 (`+0x4c` 0) is no Box (M l. 51038): no damage, the shot lives.
        w.active.update(id: wallID) { s in
            s.invulnerable = 0
            s.handleCleared = true
        }
        w.player.cues = []
        let ghost = shot(w, 2, x: 2000, y: 1000, hp: 300)
        FerazelSession.hitCallback(w, ghost, wallID, lights: &lights)
        XCTAssertEqual([Int(w.active.sprite(id: wallID)?.hp ?? 0), w.active.sprite(id: ghost)?.dead == true ? 1 : 0], [300, 0])
        XCTAssertTrue(w.player.cues.isEmpty)
        // The orb vs the gate 0xb7c (a Box, no one-way top): nothing (M l. 51004) — not the Box arm's kill.
        var gate = SpriteSlot(type: 0xb7c, x: 2000, y: 1000)
        gate.handler = .box
        gate.hasHit = true
        let gateID = w.active.insert(gate)
        let orb = shot(w, PlayerShot.orb, x: 2000, y: 1000, hp: 300)
        w.active.update(id: orb) { $0.stackX = 3 }
        FerazelSession.hitCallback(w, orb, gateID, lights: &lights)
        XCTAssertEqual(w.active.sprite(id: orb)?.dead, false)
        XCTAssertEqual(w.active.sprite(id: orb)?.stackX, 3)
        XCTAssertTrue(w.player.cues.isEmpty)
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
        // A thin one-way ledge (top 2000, rect height 2: solid centre line 2001) and a shot falling 1 px a frame at
        // x 2000: `.RectBounce` lands it from above only when the previous centre `y + 7 − 1` (7 = the hot rect's
        // vertical centre, 3 + (0xc − 3) >> 1) is above 2001 — then the contact (1) kills the shot (M l. 51057–51060).
        // y 1994 → 2000 < 2001: landed, killed; y 1995 → 2001: no side for a one-way solid, no contact.
        for (y, killed) in [(1994, true), (1995, false)] {
            var thin = SpriteSlot(type: 0xb7d, x: 2000, y: 2000)
            thin.handler = .box
            thin.oneWay = true
            thin.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 2, right: 0x20)
            let thinID = w.active.insert(thin)
            w.player.cues = []
            let faller = shot(w, 2, x: 2000, y: y, hp: 300)
            w.active.update(id: faller) { s in
                s.x256 = Int32(s.x) << 8
                s.y256 = Int32(s.y) << 8
                s.vy = 0x100
            }
            FerazelSession.hitCallback(w, faller, thinID, lights: &lights)
            XCTAssertEqual(w.active.sprite(id: faller)?.dead, killed, "y \(y)")
            XCTAssertEqual(w.player.cues.map(\.snd), killed ? [301] : [], "y \(y)")
            w.active.update(id: thinID) { $0.dead = true }
        }
        // The tree trunk 0x2c8 → its top segment 0x2c9 (`+0x1d4`), hit by a Tree Trunk shot (M l. 51005–51030): the
        // new segment (// later: SW) would sit at (top +0xc, top +0xa − 0x10); the old top's `+0xa6` is raised to 0x23
        // (kept when above), an effect 2 at (top.x − 6, top.y − 0x10 − 9) with `+0x46 = 8` and colour 0x42, the shot
        // `+0xe9 = 1`, `.STPlay3DSound(302, 1, 0x100, effect +0xe)` (the new effect's centre word). Any other id: nothing.
        for (a6, kept) in [(Int16(0x10), Int16(0x23)), (0x30, 0x30)] {
            let wt = try world([])
            var lt = LightTable()
            var top = SpriteSlot(type: 0x2c9, x: 4000, y: 968)
            top.handler = .box
            top.counterA6 = a6
            let topID = wt.active.insert(top)
            var base = SpriteSlot(type: 0x2c8, x: 4000, y: 1000)
            base.handler = .box
            base.counterA6 = 5
            base.siblings = SpriteSlot.Siblings(first: topID)
            let baseID = wt.active.insert(base)
            let plain = shot(wt, 0, x: 4000, y: 1000)
            FerazelSession.hitCallback(wt, plain, baseID, lights: &lt)
            XCTAssertEqual(wt.active.sprite(id: plain)?.dead, false)
            XCTAssertEqual(wt.active.sprite(id: topID)?.counterA6, a6)
            XCTAssertTrue(wt.player.cues.isEmpty)
            let tree = shot(wt, 4, x: 4000, y: 1000)
            FerazelSession.hitCallback(wt, tree, baseID, lights: &lt)
            XCTAssertEqual(wt.active.sprite(id: tree)?.dead, true)
            XCTAssertEqual([wt.active.sprite(id: topID)?.counterA6, wt.active.sprite(id: baseID)?.counterA6], [kept, 5])
            let e = effects(wt, 2)
            XCTAssertEqual(e.map { [$0.x, $0.y, Int($0.phase)] }, [[4000 - 6, 968 - 0x10 - 9, 8]])
            let e0 = try XCTUnwrap(e.first)
            XCTAssertEqual(lt.slots[Int(e0.light)].colour, 0x42)
            XCTAssertEqual(wt.player.cues, [PlayerCue(call: .threeD, snd: 302, priority: 1, volume: 0x100,
                                                      position: e0.centre)])
            // An idled trunk (`+0x4c` 0 ≠ the Box Handle, M l. 51005): a second Tree Trunk shot grows nothing.
            wt.active.update(id: baseID) { $0.handleCleared = true }
            let tree2 = shot(wt, 4, x: 4000, y: 1000)
            FerazelSession.hitCallback(wt, tree2, baseID, lights: &lt)
            XCTAssertEqual(wt.active.sprite(id: tree2)?.dead, false)
            XCTAssertEqual(effects(wt, 2).count, 1)
        }
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
        // A shot with `+0xa6 ≠ 0`, and an idled shot (`+0x4c` 0, M l. 61366): no damage, no draw.
        let busy = shot(w, 0, x: 3000, y: 1000, hp: 100)
        w.active.update(id: busy) { $0.counterA6 = 2 }
        let idled = shot(w, 0, x: 3000, y: 1000, hp: 100)
        w.active.update(id: idled) { $0.handleCleared = true }
        let seed1 = w.rng.seed
        FerazelSession.hitCallback(w, stalID, busy, lights: &lights)
        FerazelSession.hitCallback(w, stalID, idled, lights: &lights)
        XCTAssertEqual(w.active.sprite(id: stalID)?.hp, 50)
        XCTAssertEqual(w.rng.seed, seed1)
    }
}
