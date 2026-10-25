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
            // IU: with the dagger left selected (no Next) the item gate of the same call stabs (M l. 47353–47357,
            // 47543–47561): both latches set (`0760`, `075c`, M l. 47549–47550), snd 418 vol 0x55, counter 1; with
            // Next the selection is the Fireball — no stab, `075c` cleared (M l. 47358).
            let stab = !keys.contains(.nextItem)
            XCTAssertEqual(w.player.useDebounce, stab)
            XCTAssertEqual(w.player.useItemHeld, stab)
            XCTAssertEqual(w.player.cues, stab ? [PlayerCue(call: .reg, snd: 418, priority: 1, volume: 0x55)] : [])
            XCTAssertEqual(w.player.itemUse, stab ? 1 : 0)
            XCTAssertEqual(w.player.wandPhase, 0)
            XCTAssertTrue(shots(w).isEmpty)
            XCTAssertEqual(w.globals.magic, 0)
        }
    }

    func testCastPressMovesSpellToFront() throws {
        // The shield raised (`0 < *puVar8`, M l. 47313–47315): the gate's first arm — the latch `0760` cleared, no
        // flag, no wand, no move to the front.
        do {
            let w = try world()
            XCTAssertNotNil(Player.spawn(world: w, x: 100, y: standY))
            stock(w, [Self.spell(5), Self.item(0), Self.item(1), Self.spell(0)], selected: 3)
            w.player.shieldRaise = 1
            w.player.useDebounce = true
            HandleKeys.run(world: w, keys: .use, ridden: nil)
            XCTAssertFalse(w.player.useDebounce)
            XCTAssertFalse(w.player.castFlag)
            XCTAssertEqual(w.player.wandPhase, 0)
            XCTAssertEqual(w.globals.selectedSlot, 3)
            XCTAssertEqual(w.globals.inventory.prefix(4).map(\.id), [5, 0, 1, 0])
        }
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
        // The loss timer (M l. 46704–46706): `1 < *_DAT_100a073c` → power = the count alone; at 1 still count + 1.
        for (timer, power) in [(Int16(1), Int32(3)), (2, 2)] {
            let w = try world()
            let pID = try XCTUnwrap(Player.spawn(world: w, x: 100, y: standY))
            stock(w, [Self.spell(0), Self.item(0x13, 2)])
            w.player.countdown073c = timer
            CastSpell.cast(world: w, player: pID, keys: [])
            XCTAssertEqual(shots(w).last?.power, power, "timer \(timer)")
            XCTAssertEqual(shots(w).count, Int(power), "timer \(timer)")
        }
        // No free record (all 700 in use, `.MTNewSprite` M l. 30650–30690 → 0; Ruling 16): no Setup (no R(5)), no shot;
        // the caller's draws are still made — R(10000) for the sound, R(100) (raw `10051f14..10051f18`, unconditional
        // after the `bl .MTNewSprite`), R(0x4b) (M l. 46908) — and the cost is paid.
        do {
            let w = try world()
            let pID = try XCTUnwrap(Player.spawn(world: w, x: 100, y: standY))
            stock(w, [Self.spell(0)])
            while w.active.sprites.count < SpriteWorld.recordCount { _ = w.active.insert(SpriteSlot(type: 0, x: 0, y: 0)) }
            var r = w.rng
            let a = r.next(10000)
            _ = r.next(100)
            _ = r.next(0x4b)
            CastSpell.cast(world: w, player: pID, keys: [])
            XCTAssertEqual(w.rng.seed, r.seed)
            XCTAssertEqual(w.player.cues.last?.rate, Int32(a) + 0xec77)
            XCTAssertTrue(shots(w).isEmpty)
            XCTAssertEqual(w.globals.magic, 552)
            XCTAssertTrue(w.player.useDebounce)
        }
        // The same for case 5 (R(100), M l. 46842) and case 6 — both V Blade spawns fail, both R(0x100) are still drawn
        // (M l. 46864, 46867) — each before R(0x4b).
        for (spell, middle) in [(Int16(5), [100]), (6, [0x100, 0x100])] {
            let w = try world()
            let pID = try XCTUnwrap(Player.spawn(world: w, x: 100, y: standY))
            stock(w, [Self.spell(spell)])
            while w.active.sprites.count < SpriteWorld.recordCount { _ = w.active.insert(SpriteSlot(type: 0, x: 0, y: 0)) }
            var r = w.rng
            _ = r.next(10000)
            for n in middle { _ = r.next(Int16(n)) }
            _ = r.next(0x4b)
            CastSpell.cast(world: w, player: pID, keys: [])
            XCTAssertEqual(w.rng.seed, r.seed, "case \(spell)")
            XCTAssertTrue(shots(w).isEmpty, "case \(spell)")
        }
        // Power clamped to 5 after the stack offset (raw `1005956c`): type 0x0006 → power 5, offset (0, (6 − 1)·3 = 15),
        // four followers; type 0x0005 → power 5, offset (0, 12).
        for (raw, offset) in [(Int16(6), Int32(15)), (5, 12)] {
            let w = try world()
            let id = try XCTUnwrap(PlayerShot.spawn(w, type: raw, x: 100, y: 100))
            let s = try XCTUnwrap(w.active.sprite(id: id))
            XCTAssertEqual([s.power, s.stackY], [5, offset], "type \(raw)")
            XCTAssertEqual(PlayerShot.followers(s).compactMap { $0 }.count, 4, "type \(raw)")
        }
        // Ice Wall (id 3) and Tree Trunk (id 4) on their first armed frame (age 1): each particle draws a first R(400)
        // that is never read (M l. 50502, 50593; raw `10059a88..10059a90`, `10059b6c..10059b74`), then R(6)/R(8) twice,
        // the vy draw, the vx draw and R(2) — 5 × 6 and 7 × 6 draws; the particle fields come from draws 2…6.
        for (id, n, span, ice) in [(Int16(3), 5, Int16(6), true), (4, 7, 8, false)] {
            let w = try world(floor: false)
            let shot = try XCTUnwrap(PlayerShot.spawn(w, type: id << 8 | 1, x: 100, y: 100))
            let solver = TileSolver(world: w)
            var lights = LightTable()
            handleShots(w, solver, lights: &lights)
            let s0 = try XCTUnwrap(w.active.sprite(id: shot))
            var r = w.rng
            var expected: [ParticlePool.Record] = []
            for _ in 0..<n {
                _ = r.next(400)
                let rx = Int(r.next(span)), ry = Int(r.next(span))
                let vy = ice ? Int(r.next(800)) + Int(s0.vy) - 400 : Int(r.next(400)) - 200
                let vx = Int(r.next(400)) - 200
                let shape = Int(r.next(2)) + 1
                var p = ParticlePool.Record()
                p.alive = true
                p.shape = Int16(shape)
                p.kind = ice ? 3 : 9
                p.gravity = ice ? 0x15e : 0
                p.x = Int32(s0.x + rx + (ice ? 10 : 9)) << 8
                p.y = Int32(s0.y + ry + (ice ? 5 : 4)) << 8
                p.vx = Int32(vx)
                p.vy = Int32(vy)
                p.mode = 1
                expected.append(p)
            }
            handleShots(w, solver, lights: &lights)
            XCTAssertEqual(w.rng.seed, r.seed, "id \(id)")
            XCTAssertEqual(Array(w.particles.records.filter(\.alive).prefix(n + 1)), expected, "id \(id)")
        }
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
        // Per id at rest (pvx = pvy = 0, M l. 46726–46892, 46900–46906): the arc vy −= 0x5dc for ids 0, 1, 3, 4 only;
        // id 5 vy −0x80 and 0xed8; 2 and 7 the plain 0xd2f. Then the carried speed: |ridden vx| on a magic carpet
        // (M l. 46711–46714), and the facing inverted while clinging to wall side 1 or 2 (M l. 46910–46912).
        func cast(_ id: Int16, carpet: Int32? = nil, climb side: Int16? = nil) throws -> (vx: Int32, vy: Int32, c: Int32,
                                                                                          d: Int32) {
            let w = try world()
            let pID = try XCTUnwrap(Player.spawn(world: w, x: 100, y: standY))
            stock(w, [Self.spell(id)])
            w.active.update(id: pID) { p in
                p.vx = 0
                p.vy = 0
                p.mirrored = false
            }
            if let carpet {
                let rideID = w.active.insert(SpriteSlot(type: 0x438, x: 0, y: 0))
                w.active.update(id: rideID) { $0.vx = carpet }
                w.player.ridden = rideID
                w.player.carpet = true
            }
            if let side {
                w.player.climb = 1
                w.player.wallSide = side
            }
            var r = w.rng
            _ = r.next(10000)
            _ = r.next(5)
            let c = Int32(r.next(100)), d = Int32(r.next(0x4b))
            CastSpell.cast(world: w, player: pID, keys: [])
            XCTAssertEqual(w.rng.seed, r.seed, "id \(id)")
            let s = try XCTUnwrap(shots(w).first)
            return (s.vx, s.vy, c, d)
        }
        for id: Int16 in [0, 1, 2, 3, 4, 5, 7] {
            let k = try cast(id)
            let arc: Int32 = [0, 1, 3, 4].contains(id) ? -0x5dc : 0
            XCTAssertEqual(k.vy, (id == 5 ? -0x80 : 0) + arc + k.d - 0x28, "id \(id)")
            XCTAssertEqual(k.vx, k.c + (id == 5 ? 0xed8 : 0xd2f), "id \(id)")
        }
        for v: Int32 in [-0x300, 0x280] {
            let k = try cast(0, carpet: v)
            XCTAssertEqual(k.vx, k.c + abs(v) + 0xd2f, "carpet \(v)")
        }
        for side: Int16 in [0, 1, 2, 3] {
            let k = try cast(0, climb: side)
            XCTAssertEqual(k.vx, (side == 1 || side == 2 ? -1 : 1) * (k.c + 0xd2f), "side \(side)")
        }
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
        // A: at rest, the shot's centre (500, 298); the target, the player's centre less 4 in v, is (v 296, h 500): 2 px
        // straight above. `.FindDesiredDirectionGeneric`'s sectors put that offset in dir 30 (30° past straight up, 27,
        // toward the left), not 27; without the − 4 (2 px below) it would be dir 6. Dir 30: vx −= 0.5·800,
        // vy −= 0.866·800 (raw jump table `0x100a5694` entry 30).
        let a = try XCTUnwrap(PlayerShot.spawn(w, type: 0x501, x: 484, y: 282))
        XCTAssertEqual(w.active.sprite(id: a)?.hotRect, IdleSprites.Rect(top: 10, left: 10, bottom: 0x16, right: 0x16))
        // `.InitPlayerShotSprite`'s sets are the ones the faces table serves (`SetupFaces.sheet`, M l. 50235–50256).
        XCTAssertEqual(PlayerShot.sheets.map { SetupFaces.sheet(pict: $0.pict) }, PlayerShot.sheets)
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
        // The age stops at 200 (`+0x14c` + 1 while < 200, M l. 50482–50484).
        w.active.update(id: b) { $0.shotAge = 199 }
        var ages: [Int32] = []
        for _ in 0..<2 {
            handleShots(w, solver, lights: &lights)
            ages.append(try XCTUnwrap(w.active.sprite(id: b)).shotAge)
        }
        XCTAssertEqual(ages, [200, 200])
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
        // The lower half 0x3c passes too: the tile callback returns for 6 and 0x3c off the crunch layer (M l. 51257),
        // so `+0x11c` never comes from the water arm.
        let lowerID = try XCTUnwrap(PlayerShot.spawn(w2, type: 0x3c01, x: 100, y: 250))
        w2.active.update(id: lowerID) { $0.vy = 0x800 }
        for _ in 0..<30 { PlayerShot.handle(world: w2, id: lowerID, solver: solver2, lights: &lights2, effects: 2) }
        let low = try XCTUnwrap(w2.active.sprite(id: lowerID))
        XCTAssertEqual([low.dead ? 1 : 0, Int(low.waterRow)], [0, 0])
        XCTAssertGreaterThan(low.y, 320)
        XCTAssertFalse(w2.active.sprites.contains { $0.handler == .effect })
        // V Blade's ±500 rule (M l. 50612–50616, 0x3c 50671–50675): `+0xe9 = 1` when the centre y is more than 500 px
        // from the player's (`*_DAT_1009fd90`) — 500 exactly is kept, on both sides; the lower half the same.
        for (type, dy, dies) in [(Int16(0x601), 500, false), (0x601, 501, true), (0x601, -500, false),
                                 (0x601, -501, true), (0x3c01, 501, true), (0x3c01, -500, false)] {
            let w = try world(floor: false)
            let id = try XCTUnwrap(PlayerShot.spawn(w, type: type, x: 100, y: 100))
            let solver = TileSolver(world: w)
            var lights = LightTable()
            PlayerShot.handle(world: w, id: id, solver: solver, lights: &lights, effects: 2)
            let cy = Int(try XCTUnwrap(w.active.sprite(id: id)).centre.y)
            w.player.centreY = Int16(cy - dy)
            PlayerShot.handle(world: w, id: id, solver: solver, lights: &lights, effects: 2)
            XCTAssertEqual(w.active.sprite(id: id)?.dead, dies, "type \(type) dy \(dy)")
        }
        // The level-bottom rule (M l. 50820–50822): `hdr+0xb282 << 5 < +0xa` after the move → `+0xe9 = 1`; y on the
        // bottom edge itself is kept.
        for (dy, dies) in [(0, false), (1, true)] {
            let w = try world(floor: false)
            let bottom = Int(w.level.header.gridHeight) << 5
            let id = try XCTUnwrap(PlayerShot.spawn(w, type: 0x601, x: 100, y: bottom - 0x100))
            w.player.centreY = Int16(truncatingIfNeeded: bottom)
            w.active.update(id: id) { $0.vy = Int32(0x100 + dy) << 8 }
            let solver = TileSolver(world: w)
            var lights = LightTable()
            PlayerShot.handle(world: w, id: id, solver: solver, lights: &lights, effects: 2)
            let s = try XCTUnwrap(w.active.sprite(id: id))
            XCTAssertEqual(s.y, bottom + dy, "dy \(dy)")
            XCTAssertEqual(s.dead, dies, "dy \(dy)")
        }
    }
}
