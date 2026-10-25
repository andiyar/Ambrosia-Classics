import XCTest
@testable import FerazelCore

/// PU (docs/plans/2026-10-24-ferazel-phase4.md): the power-up timers — row 14's `.TickTock`s (M l. 44748–44814) and
/// `.TickTock @ 1004c1bc` (M l. 43583–43663), `.DoubleSpeedTrail @ 1004d370` (M l. 44302–44395) — and the effects their
/// flags drive (rows 5, 9, 33, 36; `.HitPlayerTileSprite`'s walk-on-liquid rewrite). The spheres are PK's pickup arm
/// (M l. 49023–49121). spells-items §5, pickups-boxes §1.6, physics §4 / §5.1, held-item-melee §3. Synthetic 16×16
/// grid as GliderTests (a flat FG floor on row 12, surface 400; or BG liquid on rows 12–15) over level 1's data.
final class PowerUpTests: XCTestCase {

    private let standY = 400 - 0x55

    /// `liquid` = the BG kind of rows 12–15 (tile 0) instead of the FG floor.
    private func world(liquid: Int? = nil) throws -> SpriteWorld {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let w = SpriteWorld(level: try LevelFile.load(from: r, level: 1))
        var fg = [UInt16](repeating: 0, count: 16 * 16)
        var bg = [UInt16](repeating: 0, count: 16 * 16)
        var bgKinds = [Int](repeating: 0, count: 0x60)
        if let k = liquid {
            for row in 12..<16 { for c in 0..<16 { bg[row * 16 + c] = 1 } }
            bgKinds[0] = k
        } else {
            for c in 0..<16 { fg[12 * 16 + c] = 3 + 1 }
        }
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: fg), bg: TileMap(width: 16, height: 16, cells: bg),
                           fgKinds: Array(0..<0x60), bgKinds: bgKinds)
        w.globals.health = 0x230
        w.globals.maxHealth = 0x230
        w.globals.breath = 0x230
        return w
    }

    private func frame(_ w: SpriteWorld, _ solver: TileSolver, _ keys: InputActions = []) {
        _ = w.player.drainFrameOutputs()
        Player.handle(world: w, keys: keys, solver: solver)
    }

    private func player(_ w: SpriteWorld) -> SpriteSlot { w.active.sprite(id: w.playerID!)! }

    /// Spawn at x 100, y `y` and settle two frames.
    private func spawn(_ w: SpriteWorld, y: Int? = nil) throws -> TileSolver {
        XCTAssertNotNil(Player.spawn(world: w, x: 100, y: y ?? standY))
        let solver = TileSolver(world: w)
        frame(w, solver)
        frame(w, solver)
        return solver
    }

    /// PK's sphere arm: a Bonus of `type` touched by the player (`.HitPlayerSprite`); returns the sphere and its hide
    /// timer `+0xa6`.
    @discardableResult
    private func sphere(_ w: SpriteWorld, _ type: Int16, record: Int16 = -1) throws -> (id: Int, hide: Int16) {
        var lights = LightTable()
        let p = try XCTUnwrap(w.playerID)
        var s = SpriteSlot(type: type, x: 100, y: standY, recordIndex: record)
        _ = try BonusSprite.setup(&s, x: 100, y: standY, level: w.level, records: w.records, effects: 1,
                                  lightCount: lights.count, counting: false, rng: &w.rng) { f, h, v, c in
            lights.add(face: f, x: Int16(h), y: Int16(v), vx: 0, vy: 0, accelY: 0, colour: c)
        }
        let id = w.active.insert(s)
        w.active.update(id: id) { $0.counterA6 = 0; $0.pickupDelay = 0 }
        HitPlayerSprite.hit(w, player: p, other: id, keys: [], lights: &lights, effects: 1)
        return (id, try XCTUnwrap(w.active.record(id: id)).counterA6)
    }

    private func tickCues(_ w: SpriteWorld) -> [PlayerCue] { w.player.cues.filter { $0.snd == 428 || $0.snd == 429 } }

    func testTickTockWarnings() throws {
        // A 600 timer (High Jump, M l. 44769–44781): `.TickTock` −1 a frame; at 210, 180 … 30 left snd 428
        // (`_DAT_100a03c8`, `.STPlayRegSound(·, 1, 0x100)`) and the shared flag `cRam100a5fd4` toggled; at 195, 165 … 15
        // snd 429 (`_DAT_100a03c4`) and toggled — 14 toggles; reaching 0: `.STPlay3DSoundPitched(428, 0x14, 0x100,
        // *_DAT_100a1998 = (0, 0), 32000)` and the flag set. The paired flags: `0638` = timer ≥ 1, `0634` = the shared
        // flag while it runs (left as it was once the timer is out).
        let w = try world()
        let solver = try spawn(w)
        XCTAssertTrue(w.player.flag5fd4, "`.ClearPlayerVars` stores 1 (raw 1004ad30 stb)")
        w.player.highJumpTimer = 600
        w.player.highJump = true
        w.player.tint0634 = true
        var cues: [Int: [PlayerCue]] = [:]
        var tint: [Bool] = []
        var active: [Bool] = []
        for k in 1...600 {
            frame(w, solver)
            let c = tickCues(w)
            if !c.isEmpty { cues[k] = c }
            tint.append(w.player.tint0634)
            active.append(w.player.highJump)
        }
        func reg(_ snd: Int16) -> [PlayerCue] { [PlayerCue(call: .reg, snd: snd, priority: 1, volume: 0x100)] }
        var expected: [Int: [PlayerCue]] = [:]
        for left in stride(from: 210, through: 30, by: -30) { expected[600 - left] = reg(428) }
        for left in stride(from: 195, through: 15, by: -30) { expected[600 - left] = reg(429) }
        expected[600] = [PlayerCue(call: .threeDPitched, snd: 428, priority: 0x14, volume: 0x100,
                                   position: SpriteSlot.Point(x: 0, y: 0), rate: 32000)]
        XCTAssertEqual(cues, expected)
        XCTAssertEqual(w.player.highJumpTimer, 0)
        // The blink: on to frame 389, then 15 off / 15 on from frame 390 (210 left) to 599; 14 changes.
        for k in 1...599 {
            let left = 600 - k
            let on = left > 210 || ((210 - left) / 15) % 2 == 1
            XCTAssertEqual(tint[k - 1], on, "frame \(k)")
        }
        XCTAssertEqual(zip(tint.dropFirst(), tint).filter { $0 != $1 }.count, 14)
        XCTAssertEqual(active.prefix(599).filter { $0 }.count, 599)
        XCTAssertFalse(active[599], "0638 = 0 once the timer reads 0")
        XCTAssertTrue(w.player.flag5fd4, "set at 0")
        // A finished timer stays at 0 (`0 < t` guard) and makes no more sound.
        frame(w, solver)
        XCTAssertEqual([w.player.highJumpTimer], [0])
        XCTAssertEqual(tickCues(w), [])
    }

    func testSolidLiquid() throws {
        // 1331 (M l. 49038–49046): `0640` = 600, `0648` = 1, `063c` = 0 — `.HitPlayerTileSprite` (M l. 48166–48171)
        // turns a BG cell with `.GetWaterTileKind` (kind − 200) == `063c` into FG kind 3, 16 px up: the player stands
        // on water. 1332 (acid, `063c` 1) does not hold him on water; 1333 holds him on lava (kind 202).
        func stands(_ liquid: Int, _ type: Int16?) throws -> (SpriteWorld, TileSolver, Bool) {
            let w = try world(liquid: liquid)
            XCTAssertNotNil(Player.spawn(world: w, x: 100, y: standY - 0x40))
            let solver = TileSolver(world: w)
            if let t = type { try sphere(w, t) }
            for _ in 0..<40 { frame(w, solver) }
            return (w, solver, player(w).groundKind != 0 && player(w).lastWater == 0)
        }
        let (w, solver, onWater) = try stands(200, 0x533)
        XCTAssertTrue(onWater)
        XCTAssertEqual(w.player.walkOnLiquidKind, 0)
        XCTAssertEqual(player(w).y, standY - 0x10, "the floor is the water cell's top − 16")
        XCTAssertFalse(try stands(200, nil).2, "no sphere: he falls in")
        XCTAssertFalse(try stands(200, 0x534).2, "acid sphere on water: he falls in")
        let (lw, _, onLava) = try stands(202, 0x535)
        XCTAssertTrue(onLava)
        XCTAssertEqual(lw.player.walkOnLiquidKind, 2)
        // 600 frames from the pickup (40 used): row 14 clears `0648` at 0 — the floor goes and he sinks.
        for _ in 0..<559 { frame(w, solver) }
        XCTAssertEqual(w.player.walkOnLiquidTimer, 1)
        XCTAssertTrue(w.player.walkOnLiquid)
        frame(w, solver)
        XCTAssertEqual(w.player.walkOnLiquidTimer, 0)
        XCTAssertFalse(w.player.walkOnLiquid)
        for _ in 0..<10 { frame(w, solver) }
        XCTAssertGreaterThan(player(w).y, standY - 0x10)
        XCTAssertNotEqual(player(w).lastWater, 0, "in the water")
    }

    func testHighJump() throws {
        // 1334 (M l. 49047–49054): `0630` = 600, `0638` = `0634` = 1. Row 9 (M l. 44662–44664): J = −0x898 (−2200)
        // while `0638`; the jump's `.AccelerateSprite(0, J + (−0xc80 − ((|vx| + 0x4e2) >> 3)), 0, 8000)` — 2200 more.
        func jumpVY(_ high: Bool) throws -> (SpriteWorld, Int32) {
            let w = try world()
            let solver = try spawn(w)
            if high {
                let (_, hide) = try sphere(w, 0x536)
                XCTAssertEqual(hide, 600)
            }
            frame(w, solver)
            XCTAssertEqual(w.player.jumpBase, high ? -0x898 : 0)
            frame(w, solver, [.jump])
            return (w, player(w).vy)
        }
        let (w, high) = try jumpVY(true)
        let (_, normal) = try jumpVY(false)
        XCTAssertEqual(high - normal, -2200)
        XCTAssertEqual(w.player.highJumpTimer, 598)
        // Row 9 reads `0638` before row 14 ticks: the frame the timer runs out still jumps high, the next does not.
        w.player.highJumpTimer = 1
        let solver = TileSolver(world: w)
        frame(w, solver)
        XCTAssertFalse(w.player.highJump)
        XCTAssertEqual(w.player.jumpBase, -0x898)
        w.active.update(id: w.playerID!) { $0.groundKind = 3 }
        frame(w, solver)
        XCTAssertNotEqual(w.player.jumpBase, -0x898)
    }

    func testFeatherfall() throws {
        // 1336 (M l. 49063–49070): `0624` = 900, `062c` = `0628` = 1. Row 9 (M l. 44665–44671): falling (vy > 0) →
        // gravity 0x40, and vy > 0x352 → 0x352; row 23 then adds the gravity: the fall moves at 0x352 + 0x40 = 914 a
        // frame (the bank's "fall cap 850" is the pre-gravity clamp). Row 33 caps the air counter at 0xf.
        let w = try world()
        let solver = try spawn(w, y: 0)
        let (_, hide) = try sphere(w, 0x538)
        XCTAssertEqual(hide, 900)
        var vys: [Int32] = []
        for _ in 0..<20 {
            frame(w, solver)
            vys.append(player(w).vy)
            XCTAssertEqual(player(w).gravity, 0x40)
            XCTAssertLessThanOrEqual(w.player.airCounter, 0xf)
        }
        XCTAssertEqual(vys.last, 0x352 + 0x40)
        XCTAssertEqual(w.player.featherFallTimer, 880)
        // Without the sphere the same fall reaches far more (gravity 0x1b8, terminal 12000).
        let n = try world()
        let ns = try spawn(n, y: 0)
        for _ in 0..<5 { frame(n, ns) }
        XCTAssertEqual(player(n).gravity, 0x1b8)
        XCTAssertGreaterThan(player(n).vy, 0x392)
        // 900 frames: the flag clears at 0 and the normal gravity returns.
        w.player.featherFallTimer = 1
        frame(w, solver)
        XCTAssertFalse(w.player.featherFall)
        frame(w, solver)
        XCTAssertEqual(player(w).gravity, 0x1b8)
    }

    func testDoubleSpeedTrail() throws {
        // 1337 (M l. 49071–49077): `0618` = 600, `0620` = `061c` = 1. Row 5 (M l. 44559–44568): max walk / run 0xd82 /
        // 0x15e0 (3458 / 5600). `.DoubleSpeedTrail` (row 42, M l. 46615): the 5-entry ring shifts, entry 4 = this
        // frame's (y, x), face, mirror; trail i shows entry s = (i >> 1) + 2 — odd i at the midpoint of s and s + 1
        // (srawi) — with tints 0xb0002, 0xb0000, 0xb0001, 0, 0 and `+0x88` 0; off: every trail face 0, `+0x88` 0.
        let w = try world()
        let solver = try spawn(w)
        let trail = w.player.trail.compactMap { $0 }
        XCTAssertEqual(trail.count, 5)
        // Off (no sphere): faces 0, `+0x88` 0 (the Setup's 1 cleared on the first tail).
        for id in trail {
            let t = try XCTUnwrap(w.active.record(id: id))
            XCTAssertNil(t.face)
            XCTAssertFalse(t.lightOverlay)
        }
        try sphere(w, 0x539)
        var poses: [(face: FaceRef?, x: Int, y: Int, m: Bool)] = []
        for k in 1...8 {
            frame(w, solver, k < 6 ? [.right, .run] : [.left])
            let p = player(w)
            poses.append((p.face, p.x, p.y, p.mirrored))
        }
        XCTAssertEqual([w.player.maxWalk, w.player.maxRun, w.player.airWalk, w.player.airRun], [3458, 5600, 3458, 5600])
        let n = poses.count
        let e: [Int: (face: FaceRef?, x: Int, y: Int, m: Bool)] = [2: poses[n - 3], 3: poses[n - 2], 4: poses[n - 1]]
        let tints: [UInt32] = [0xb0002, 0xb0000, 0xb0001, 0, 0]
        for (i, id) in trail.enumerated() {
            let t = try XCTUnwrap(w.active.record(id: id))
            let s = (i >> 1) + 2
            let a = e[s]!, b = e[min(s + 1, 4)]!
            XCTAssertEqual(t.face, a.face, "trail \(i)")
            XCTAssertEqual(t.mirrored, a.m, "trail \(i)")
            let x = i & 1 == 0 ? a.x : (a.x + b.x) >> 1
            let y = i & 1 == 0 ? a.y : (a.y + b.y) >> 1
            XCTAssertEqual([t.x, t.y], [x, y], "trail \(i)")
            XCTAssertEqual([t.x256, t.y256], [Int32(x) << 8, Int32(y) << 8])
            XCTAssertEqual(t.mode, tints[i])
            XCTAssertFalse(t.lightOverlay)
        }
        XCTAssertNotEqual(poses[n - 1].x, poses[n - 3].x, "the poses differ, so the trail spreads")
        // Expiry: `0620` = 0 at 0 → the faces go.
        w.player.doubleSpeedTimer = 1
        frame(w, solver)
        XCTAssertFalse(w.player.doubleSpeed)
        for id in trail { XCTAssertNil(try XCTUnwrap(w.active.record(id: id)).face) }
        frame(w, solver)
        XCTAssertEqual([w.player.maxWalk, w.player.maxRun], [0x76c, 0xc80])
    }

    func testInvincibilityAndDeath() throws {
        // 1335 (M l. 49055–49062): the player's `+0x116` = 0x1c2 and `0650` = 0x1c2; the sphere hides 32000 with its
        // record's p2 0, else 0x1c2. `+0x116` counts down in `.StandardSpriteHandles`, `0650` in row 14's first
        // `.TickTock` (its warnings, its pitched 428 at 0; no flag of its own).
        let w = try world()
        let solver = try spawn(w)
        w.records[0] = Placement(index: 0, flag: 1, byte1: 0, type: 0x537, p1: 0, p2: 0, p3: 0, p4: 0, y: 0, x: 0)
        XCTAssertEqual(try sphere(w, 0x537, record: 0).hide, 32000)
        w.records[0] = Placement(index: 0, flag: 1, byte1: 0, type: 0x537, p1: 0, p2: 1, p3: 0, p4: 0, y: 0, x: 0)
        XCTAssertEqual(try sphere(w, 0x537, record: 0).hide, 0x1c2)
        XCTAssertEqual([player(w).invulnerable, w.player.invincibleTimer], [0x1c2, 0x1c2])
        var warned: [Int] = []
        for k in 1...0x1c2 {
            frame(w, solver)
            if !tickCues(w).isEmpty { warned.append(k) }
            XCTAssertEqual(Int(player(w).invulnerable), 0x1c2 - k)
            XCTAssertEqual(Int(w.player.invincibleTimer), 0x1c2 - k)
        }
        XCTAssertEqual(warned, (0..<14).map { 450 - 210 + 15 * $0 } + [450])
        XCTAssertFalse(w.player.highJump || w.player.featherFall || w.player.doubleSpeed || w.player.walkOnLiquid)

        // 1339 (M l. 49110–49117): the sphere killed, snd 450 vol 0xab, HP − 0x380, `+0x116` = `+0xaa` = 30 — the
        // 30 frames count down in `.StandardSpriteHandles`.
        w.active.update(id: w.playerID!) { $0.hp = 0x400 }
        let (death, hide) = try sphere(w, 0x53b)
        XCTAssertEqual(hide, 0)
        XCTAssertEqual(w.active.record(id: death)?.killCount, 1)
        XCTAssertEqual([player(w).hp, player(w).invulnerable, player(w).flash], [0x80, 30, 30])
        for k in 1...30 {
            frame(w, solver)
            XCTAssertEqual(Int(player(w).invulnerable), 30 - k)
        }
    }
}
