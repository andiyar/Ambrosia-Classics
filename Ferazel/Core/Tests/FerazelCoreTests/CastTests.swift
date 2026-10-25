import XCTest
import HectorResources
@testable import FerazelCore

/// CS (docs/plans/2026-10-24-ferazel-phase4.md): casting — the USE gate of `.HandleKeys @ 10052ac0` (M l.
/// 47310–47352), the wand steps of `.HandlePlayerSprite` row 31 (M l. 45142–45176), `.CastSpell @ 10051d1c` (M l.
/// 46653–46980) — and the player shots in flight: `.SetupPlayerShotSprite @ 1005925c` (M l. 50265–50430) and
/// `.HandlePlayerShotSprite @ 10059704` (M l. 50431–50946). Synthetic 16×16 grids over level 1's header; every
/// expected draw is re-derived from a copy of the stream at the call site, the geometry from the dump's arithmetic
/// next to each assertion.
final class CastTests: XCTestCase {

    /// The player stands with his hot-rect bottom (`y + 0x55`) on the floor surface 400 (as `PlayerMotionTests`).
    private let standY = 400 - 0x55

    /// A 16×16 grid: an FG kind-3 floor on row 12 when `floor`; BG tile 5 = kind 200 (water) on rows ≥ `waterRow`.
    private func world(floor: Bool = true, waterRow: Int? = nil) throws -> SpriteWorld {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let w = SpriteWorld(level: try LevelFile.load(from: r, level: 1))
        var fg = [UInt16](repeating: 0, count: 16 * 16)
        if floor { for c in 0..<16 { fg[12 * 16 + c] = 3 + 1 } }
        var bg = [UInt16](repeating: 0, count: 16 * 16)
        var bgKinds = [Int](repeating: 0, count: 0x60)
        if let wr = waterRow {
            for row in wr..<16 { for c in 0..<16 { bg[row * 16 + c] = 5 + 1 } }
            bgKinds[5] = 200
        }
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: fg), bg: TileMap(width: 16, height: 16, cells: bg),
                           fgKinds: Array(0..<0x60), bgKinds: bgKinds)
        return w
    }

    private static let empty = InventorySlot(id: -1, count: 0, field4: -1, field6: 0, isSpell: 0)
    private static func spell(_ id: Int16) -> InventorySlot {
        InventorySlot(id: id, count: 1, field4: -1, field6: 0, isSpell: 1)
    }
    private static func item(_ id: Int16, _ n: Int16 = 1) -> InventorySlot {
        InventorySlot(id: id, count: n, field4: -1, field6: 0, isSpell: 0)
    }

    /// The inventory `slots` (the rest empty), the selection and the magic.
    private func stock(_ w: SpriteWorld, _ slots: [InventorySlot], selected: Int16 = 0, magic: Int16 = 560) {
        var inv = [InventorySlot](repeating: Self.empty, count: GameGlobals.inventorySlots)
        for (k, s) in slots.enumerated() { inv[k] = s }
        w.globals.inventory = inv
        w.globals.selectedSlot = selected
        w.globals.magic = magic
        w.globals.maxMagic = 1000
    }

    private func shots(_ w: SpriteWorld) -> [SpriteSlot] { w.active.sprites.filter { $0.handler == .playerShot } }
    private func player(_ w: SpriteWorld) -> SpriteSlot { w.active.sprite(id: w.playerID!)! }

    /// Spawned at (100, standY) and settled two frames (landed, jump counter refilled).
    private func standing(_ w: SpriteWorld) -> TileSolver {
        XCTAssertNotNil(Player.spawn(world: w, x: 100, y: standY))
        let solver = TileSolver(world: w)
        Player.handle(world: w, keys: [], solver: solver)
        Player.handle(world: w, keys: [], solver: solver)
        XCTAssertEqual(player(w).groundKind, 3)
        return solver
    }

    /// One handle pass over the player shots in list order (followers precede their main, spells-detail-2 §4).
    private func handleShots(_ w: SpriteWorld, _ solver: TileSolver, lights: inout LightTable, effects: Int16 = 2) {
        for id in w.active.sprites.filter({ $0.handler == .playerShot }).map(\.id) {
            PlayerShot.handle(world: w, id: id, solver: solver, lights: &lights, effects: effects)
        }
    }

    // MARK: - the USE gate and the wand

    func testCastOnPressFrame() throws {
        let w = try world()
        let solver = standing(w)
        stock(w, [Self.spell(0), Self.item(0)])
        // The press frame: the gate's step 0 → flag, step 3 (M l. 47341–47344); row 31 later in the same Handle steps
        // to 4 and casts (M l. 45150–45155) — the shot leaves on the frame of the press, magic 560 − 8 (M l. 46729).
        Player.handle(world: w, keys: .use, solver: solver)
        XCTAssertEqual(shots(w).count, 1)
        XCTAssertEqual(w.globals.magic, 552)
        XCTAssertEqual(w.player.wandPhase, 4)
        XCTAssertTrue(w.player.castFlag)
        XCTAssertTrue(w.player.useDebounce)
        XCTAssertEqual(w.player.exertion, 0x19)                         // M l. 46723 (standing: no walk exertion)
        // Held: the latch swallows the press (M l. 47320); the wand runs 5, 6, then past 6 → flag 0, step 3 with the
        // hold counting (M l. 45155–45166); no second shot, no cost.
        var phases: [Int16] = []
        for _ in 0..<4 {
            Player.handle(world: w, keys: .use, solver: solver)
            phases.append(w.player.wandPhase)
        }
        XCTAssertEqual(phases, [5, 6, 3, 3])
        XCTAssertFalse(w.player.castFlag)
        XCTAssertEqual(w.player.wandHeld, 2)
        XCTAssertEqual(shots(w).count, 1)
        XCTAssertEqual(w.globals.magic, 552)
        // Released one frame: the latch clears (M l. 47315); the wand stays raised (hold 3).
        Player.handle(world: w, keys: [], solver: solver)
        XCTAssertFalse(w.player.useDebounce)
        XCTAssertEqual(w.player.wandPhase, 3)
        XCTAssertEqual(w.player.wandHeld, 3)
        // A fresh press at step 3: flag only (M l. 47346–47347), row 31 → 4 → cast on that same frame.
        Player.handle(world: w, keys: .use, solver: solver)
        XCTAssertEqual(shots(w).count, 2)
        XCTAssertEqual(w.globals.magic, 544)
        XCTAssertEqual(w.player.wandPhase, 4)
        XCTAssertEqual(w.player.wandHeld, 0)
        // Left alone the wand lowers: 18 frames of hold at step 3, then 2 → 1 → 0 (M l. 45161–45176).
        var steps: [Int16] = []
        for _ in 0..<26 {
            Player.handle(world: w, keys: [], solver: solver)
            steps.append(w.player.wandPhase)
        }
        XCTAssertEqual(steps, [5, 6] + [Int16](repeating: 3, count: 17) + [2, 1, 0, 0, 0, 0, 0])
        XCTAssertEqual(w.player.wandHeld, 0)
    }

    func testMagicBelowOneSelectsDagger() throws {
        // Magic 0 (`G+0xe < 1`, M l. 47321): the first slot holding item 0 or 0x15 with `+8 == 0` (M l. 47322–47334),
        // `.MoveSelectedItemToFront` (its own `.UpdateStatusBar(1,1,0)`, M l. 39704) and `.UpdateStatusBar(1,1,0)`
        // (M l. 47336): two calls. No cast, no latch, no wand.
        for keys: InputActions in [.use, [.use, .nextItem]] {
            let w = try world()
            XCTAssertNotNil(Player.spawn(world: w, x: 100, y: standY))
            stock(w, [Self.spell(0), Self.spell(5), Self.item(0), Self.item(1)], magic: 0)
            HandleKeys.run(world: w, keys: keys, ridden: nil)
            XCTAssertEqual(w.globals.inventory.prefix(4).map(\.id), [0, 0, 5, 1])
            XCTAssertEqual(w.globals.inventory.prefix(4).map(\.isSpell), [0, 1, 1, 0])
            let bars = w.player.passDraws.compactMap { op -> StatusBarCall? in
                if case .statusBar(let s) = op { return s.call } else { return nil }
            }
            XCTAssertEqual(bars.count, 2)
            XCTAssertTrue(bars.allSatisfy { $0.partial && $0.forceItems && !$0.forceBars })
            if keys.contains(.nextItem) {
                // Each call runs the key block (M l. 4885–4912): the first steps (counter 12, selection 0 → 1), the
                // second counts the repeat down.
                XCTAssertEqual(bars.map(\.stepped), [true, false])
                XCTAssertEqual(w.statusBar.repeatCounter, 11)
                XCTAssertEqual(w.globals.selectedSlot, 1)
            } else {
                XCTAssertEqual(bars.map(\.stepped), [false, false])
                XCTAssertEqual(w.globals.selectedSlot, 0)
            }
            XCTAssertFalse(w.player.castFlag)
            XCTAssertFalse(w.player.useDebounce)
            XCTAssertEqual(w.player.wandPhase, 0)
            XCTAssertTrue(shots(w).isEmpty)
            XCTAssertEqual(w.globals.magic, 0)
        }
    }

    func testCastPressMovesSpellToFront() throws {
        let w = try world()
        XCTAssertNotNil(Player.spawn(world: w, x: 100, y: standY))
        stock(w, [Self.spell(5), Self.item(0), Self.item(1), Self.spell(0)], selected: 3)
        // The press (M l. 47339–47349): `075c` = 1, `0760` = 1, step 0 → flag, step 3, `06e0` = 0, then
        // `.MoveSelectedItemToFront` — slot 3 to the front, selection 0, its one (1,1,0) call. The item block later in
        // the same call clears `075c` (the selected slot is a spell, M l. 47356–47358): the store is dead as observed.
        HandleKeys.run(world: w, keys: .use, ridden: nil)
        XCTAssertEqual(w.globals.inventory.prefix(4).map(\.id), [0, 5, 0, 1])
        XCTAssertEqual(w.globals.inventory.prefix(4).map(\.isSpell), [1, 1, 0, 0])
        XCTAssertEqual(w.globals.selectedSlot, 0)
        let bars = w.player.passDraws.filter { if case .statusBar = $0 { true } else { false } }
        XCTAssertEqual(bars.count, 1)
        XCTAssertTrue(w.player.castFlag)
        XCTAssertEqual(w.player.wandPhase, 3)
        XCTAssertFalse(w.player.noCastBegan)
        XCTAssertTrue(w.player.useDebounce)
        XCTAssertFalse(w.player.useItemHeld)
        // Row 31 casts the front slot's spell: a Fireball.
        Player.wand(w, id: w.playerID!, keys: .use)
        XCTAssertEqual(shots(w).map(\.type), [0])
        XCTAssertEqual(w.globals.magic, 552)
    }

    func testCostWithoutFloor() throws {
        // Statue (case 1, M l. 46746–46765): cost 0x20 with no floor — magic 1 → −31; the shot `+0xa4` 200, gravity
        // 0xfa (M l. 50312–50364), hot rect (8, 3, 15, 12).
        let w = try world()
        XCTAssertNotNil(Player.spawn(world: w, x: 100, y: standY))
        stock(w, [Self.spell(1)], magic: 1)
        HandleKeys.run(world: w, keys: .use, ridden: nil)
        Player.wand(w, id: w.playerID!, keys: .use)
        XCTAssertEqual(w.globals.magic, -31)
        let s = try XCTUnwrap(shots(w).first)
        XCTAssertEqual([s.type, s.hp, s.gravity], [1, 200, 0xfa])
        XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 3, left: 8, bottom: 12, right: 15))
        // Step 4 casts only while magic > 0 (M l. 45153): a raised wand at −31 steps on without a shot.
        w.player.castFlag = true
        w.player.wandPhase = 3
        Player.wand(w, id: w.playerID!, keys: [])
        XCTAssertEqual(w.player.wandPhase, 4)
        XCTAssertEqual(shots(w).count, 1)
    }

    // MARK: - .CastSpell

    func testCastDrawOrder() throws {
        // Power 1: `STPlay3DSoundRand(snd 300)` — FastRand(10000) — first (M l. 46727), then `MTNewSprite` whose Setup
        // draws `+0x46 = FastRand(5)` (M l. 50291), then FastRand(100) (M l. 46742), then FastRand(0x4b) (M l. 46908).
        do {
            let w = try world()
            let pID = try XCTUnwrap(Player.spawn(world: w, x: 100, y: standY))
            stock(w, [Self.spell(0)])
            var r = w.rng
            let a = r.next(10000), b = r.next(5), c = r.next(100), d = r.next(0x4b)
            CastSpell.cast(world: w, player: pID, keys: [])
            XCTAssertEqual(w.rng.seed, r.seed)
            XCTAssertEqual(w.player.cues.last, PlayerCue(call: .threeDRand, snd: 300, priority: 1, volume: 0x100,
                                                         position: player(w).centre, rate: Int32(a) + 0xec77))
            let s = try XCTUnwrap(shots(w).first)
            XCTAssertEqual(s.phase, b)
            XCTAssertEqual(s.vx, Int32(c) + 0xd2f)
            XCTAssertEqual(s.vy, -0x5dc + Int32(d) - 0x28)
        }
        // Power 3 (two Multi Crystals 0x13, M l. 46699–46708): the two followers' Setups draw their FastRand(5) inside
        // the main's Setup (M l. 50399–50408), after its own and before FastRand(100).
        let w = try world()
        let pID = try XCTUnwrap(Player.spawn(world: w, x: 100, y: standY))
        stock(w, [Self.spell(0), Self.item(0x13, 2)])
        var r = w.rng
        let a = r.next(10000), b = r.next(5), f1 = r.next(5), f2 = r.next(5), c = r.next(100), d = r.next(0x4b)
        CastSpell.cast(world: w, player: pID, keys: [])
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual(w.player.cues.last?.rate, Int32(a) + 0xec77)
        // Followers are inserted first (made inside the main's Setup, before its insert; spells-detail-2 §4).
        let list = shots(w)
        XCTAssertEqual(list.map(\.power), [0, 0, 3])
        XCTAssertEqual(list.map(\.phase), [f1, f2, b])
        XCTAssertEqual(list[2].vx, Int32(c) + 0xd2f)
        XCTAssertEqual(list[2].vy, -0x5dc + Int32(d) - 0x28)
        XCTAssertEqual(list[2].siblings, SpriteSlot.Siblings(first: list[0].id, second: list[1].id))
    }

    func testCastSpeeds() throws {
        // vx = |pvx >> 1| + R(100) + carried + 0xd2f, vy = pvy >> 1 (M l. 46738–46744); ids 0/1/3/4 vy −= 0x5dc
        // (−1000 crouching, M l. 46900–46906); vy += R(0x4b) − 0x28; UP: vy −= 0x5dc, vx −= 0x2ee (M l. 46895–46899);
        // facing left (`+0x17e`) negates vx last (M l. 46974–46976). Spawn (x + 0x26, y + 0x33), crouching y + 0x42.
        for (up, left, crouch) in [(false, false, Int16(0)), (true, false, 0), (false, true, 0), (true, true, 4)] {
            let w = try world()
            let pID = try XCTUnwrap(Player.spawn(world: w, x: 100, y: standY))
            stock(w, [Self.spell(0)])
            w.active.update(id: pID) { p in
                p.x = 100                                               // the pixel copy (`.MTNewSprite` leaves y in
                p.y = self.standY                                       // `+0xc` until the first integration)
                p.vx = 0x400
                p.vy = 0x300
                p.mirrored = left
            }
            w.player.crouch = crouch
            var r = w.rng
            _ = r.next(10000)
            _ = r.next(5)
            let c = Int32(r.next(100)), d = Int32(r.next(0x4b))
            CastSpell.cast(world: w, player: pID, keys: up ? .up : [])
            var vx = 0x200 + c + 0xd2f, vy: Int32 = 0x180
            if up {
                vy -= 0x5dc
                vx -= 0x2ee
            }
            vy -= crouch == 0 ? 0x5dc : 1000
            vy += d - 0x28
            if left { vx = -vx }
            let s = try XCTUnwrap(shots(w).first)
            XCTAssertEqual(s.vx, vx, "up \(up) left \(left)")
            XCTAssertEqual(s.vy, vy, "up \(up) left \(left)")
            XCTAssertEqual([s.x, s.y], [100 + 0x26, standY + (crouch == 0 ? 0x33 : 0x42)])
            XCTAssertEqual(w.rng.seed, r.seed)
        }
        // V Blade (case 6, M l. 46846–46872): two shots from the centre x − 20; R(256) − 0x80 each, −4000 / +4000; the
        // lower 0x3c00 + power gets 150 by its own store and no UP / jitter / facing (the upper takes all three).
        let w = try world()
        let pID = try XCTUnwrap(Player.spawn(world: w, x: 100, y: standY))
        stock(w, [Self.spell(6)])
        w.active.update(id: pID) { p in
            p.x = 100
            p.y = self.standY
            p.centre = SpriteSlot.Point(x: 150, y: 300)
            p.mirrored = true
        }
        var r = w.rng
        _ = r.next(10000)
        _ = r.next(5)
        _ = r.next(5)
        let u = Int32(r.next(0x100)), l = Int32(r.next(0x100)), d = Int32(r.next(0x4b))
        CastSpell.cast(world: w, player: pID, keys: .up)
        let list = shots(w)
        XCTAssertEqual(list.map(\.type), [6, 0x3c])
        XCTAssertEqual(list.map(\.hp), [150, 150])
        XCTAssertEqual(list[0].vx, -(u - 0x80 - 0x2ee))
        XCTAssertEqual(list[0].vy, -4000 - 0x5dc + d - 0x28)
        XCTAssertEqual([list[1].vx, list[1].vy], [l - 0x80, 4000])
        XCTAssertEqual([list[0].x, list[0].y, list[1].x, list[1].y], [130, standY + 0x2a, 130, standY + 0x34])
        XCTAssertTrue(w.player.vBladeCast)
        XCTAssertEqual(w.rng.seed, r.seed)
    }

    // MARK: - the shots in flight

    func testPowerMultipliesOnAgeOne() throws {
        // Power 3: stack offset (0, (3 − 1)·3) = (0, 6), step (0, 6) (M l. 50380–50396); followers 1, 2 at `+0x1d4`,
        // `+0x1d8` (raw `1005960c..10059628`). Age −1 → 0 → 1: `+0xa4 ×= power` on age 1 (M l. 50707), with the light
        // `.AddLight(810, (y + 8, x + 0xc + vx >> 8), vx, vy, gravity, 0x16)` (M l. 50709–50776).
        let w = try world(floor: false)
        let pID = try XCTUnwrap(Player.spawn(world: w, x: 100, y: 100))
        stock(w, [Self.spell(0), Self.item(0x13, 2)])
        CastSpell.cast(world: w, player: pID, keys: [])
        let solver = TileSolver(world: w)
        var lights = LightTable()
        let mainID = try XCTUnwrap(shots(w).last?.id)
        let main0 = try XCTUnwrap(w.active.sprite(id: mainID))
        XCTAssertEqual([main0.stackX, main0.stackY, main0.stepX, main0.stepY], [0, 6, 0, 6])
        XCTAssertEqual(main0.hp, 100)
        for age in [Int32(0), 1, 2] {
            handleShots(w, solver, lights: &lights)
            let list = shots(w)
            let main = list[2]
            XCTAssertEqual(main.shotAge, age)
            XCTAssertEqual(main.hp, age == 0 ? 100 : 300, "age \(age)")
            XCTAssertEqual(list[0].hp, 0)
            XCTAssertEqual(list[1].hp, 0)
            // The followers are placed at the main's drawn position − k·step (M l. 50858–50935).
            for (k, f) in list.prefix(2).enumerated() {
                XCTAssertEqual(f.x, main.x, "age \(age) follower \(k + 1)")
                XCTAssertEqual(main.y - f.y, 6 * (k + 1), "age \(age) follower \(k + 1)")
                XCTAssertEqual(f.vx, main.vx)
            }
        }
        let main = try XCTUnwrap(w.active.sprite(id: mainID))
        XCTAssertEqual(main.light, 0)
        XCTAssertEqual(lights.slots[0].face, LightFaceRef(pict: 0x32a, width: 0x48, height: 0x48))
        XCTAssertEqual(lights.slots[0].colour, 0x16)
        XCTAssertEqual(lights.count, 1)
        XCTAssertTrue(shots(w).prefix(2).allSatisfy { $0.light == -1 })
    }

    func testBoomerangHomes() throws {
        // Id 5 (gravity 0, rect (10, 10, 22, 22): centre = origin + 16): straight while age ≤ 12; from age 13
        // `FUN_1003f218(shot, dir, 800)` toward the player's centre with v − 4 (M l. 50579–50585), then
        // `.EnforceMaxSpeed(0x1450)`.
        let w = try world(floor: false)
        let pID = try XCTUnwrap(Player.spawn(world: w, x: 0, y: 0))
        w.active.update(id: pID) { $0.centre = SpriteSlot.Point(x: 500, y: 300) }
        stock(w, [])
        let solver = TileSolver(world: w)
        var lights = LightTable()
        // A: at rest, centre (500, 298) — the target (296, 500) lies 2 px above, so dir 30 (up, 10° short of 27's
        // left side… as `.FindDesiredDirectionGeneric` sectors it: t = −2 → the tan 55° row); the centre itself would
        // give dir 6 (below). Dir 30: vx −= 0.5·800, vy −= 0.866·800 (raw jump table `0x100a5694` entry 30).
        let a = try XCTUnwrap(PlayerShot.spawn(w, type: 0x501, x: 484, y: 282))
        for frame in 1...13 {
            handleShots(w, solver, lights: &lights)
            let s = try XCTUnwrap(w.active.sprite(id: a))
            XCTAssertEqual([s.vx, s.vy], [0, 0], "frame \(frame)")
            XCTAssertEqual([s.x, s.y], [484, 282])
        }
        handleShots(w, solver, lights: &lights)
        let s14 = try XCTUnwrap(w.active.sprite(id: a))
        XCTAssertEqual(s14.shotAge, 13)
        XCTAssertEqual([s14.vx, s14.vy], [-400, -692])
        XCTAssertEqual([s14.x256, s14.y256], [484 * 256 - 400, 282 * 256 - 692])
        // B: flying right at 0x1400 toward a far target at its own height (dir 18: vx += 800) → 5920, capped to 0x1450.
        w.active.update(id: pID) { $0.centre = SpriteSlot.Point(x: 3000, y: 300) }
        w.active.update(id: a) { $0.killCount = 1 }
        let b = try XCTUnwrap(PlayerShot.spawn(w, type: 0x501, x: 100, y: 280))
        w.active.update(id: b) { $0.vx = 0x1400 }
        for frame in 1...13 {
            handleShots(w, solver, lights: &lights)
            let s = try XCTUnwrap(w.active.sprite(id: b))
            XCTAssertEqual([s.vx, s.vy], [0x1400, 0], "frame \(frame)")
            XCTAssertEqual(s.x, 100 + 20 * frame)
        }
        for _ in 0..<2 {
            handleShots(w, solver, lights: &lights)
            let s = try XCTUnwrap(w.active.sprite(id: b))
            XCTAssertEqual([s.vx, s.vy], [0x1450, 0])
        }
    }

    func testShotFizzlesInLiquid() throws {
        // A power-2 Fireball falling into water (BG kind 200 from row 10, y 320): the tile callback's water arm
        // (`.HandleUnderWater`, M l. 51375–51378) sets `+0x11c`; the rule (M l. 50789–50818) spawns effect 5 at
        // (x − 8, y − 12), switches its light off, flags the shot and its follower.
        let w = try world(floor: false, waterRow: 10)
        let pID = try XCTUnwrap(Player.spawn(world: w, x: 100, y: 100))
        stock(w, [Self.spell(0), Self.item(0x13, 1)])
        CastSpell.cast(world: w, player: pID, keys: [])
        let list = shots(w)
        XCTAssertEqual(list.map(\.power), [0, 2])
        let mainID = list[1].id, followerID = list[0].id
        w.active.update(id: mainID) { s in
            s.vx = 0
            s.vy = 0x800
        }
        let solver = TileSolver(world: w)
        var lights = LightTable()
        var frames = 0
        while w.active.sprite(id: mainID)?.dead == false && frames < 40 {
            handleShots(w, solver, lights: &lights)
            frames += 1
        }
        let main = try XCTUnwrap(w.active.sprite(id: mainID))
        XCTAssertTrue(main.dead)
        XCTAssertGreaterThan(main.waterRow, 0)
        XCTAssertEqual(w.active.sprite(id: followerID)?.killCount, 1)
        // The rule reads `+0xc`/`+0xa` before the end-of-call re-shift by the stack offset (0, 3).
        let x = SpriteWorld.pixel(main.x256), y = SpriteWorld.pixel(main.y256 - (main.stackY << 8))
        let effect = try XCTUnwrap(w.active.sprites.first { $0.handler == .effect && $0.type == 5 })
        XCTAssertEqual([effect.x, effect.y], [x - 8, y - 12])
        XCTAssertEqual(lights.slots[Int(effect.light)].colour, 0)
        // The upper V Blade (id 6) takes neither the water arm nor the rule: it passes through.
        let w2 = try world(floor: false, waterRow: 10)
        XCTAssertNotNil(Player.spawn(world: w2, x: 100, y: 100))
        let v = try XCTUnwrap(PlayerShot.spawn(w2, type: 0x601, x: 100, y: 250))
        w2.active.update(id: v) { $0.vy = 0x800 }
        let solver2 = TileSolver(world: w2)
        var lights2 = LightTable()
        for _ in 0..<30 { handleShots(w2, solver2, lights: &lights2) }
        let blade = try XCTUnwrap(w2.active.sprite(id: v))
        XCTAssertFalse(blade.dead)
        XCTAssertGreaterThan(blade.y, 320)
        XCTAssertFalse(w2.active.sprites.contains { $0.handler == .effect })
    }
}
