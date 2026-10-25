import XCTest
import HectorResources
@testable import FerazelCore

/// IU (docs/plans/2026-10-24-ferazel-phase4.md): USE with an item — `.HandleKeys @ 10052ac0`'s item gate and switch
/// (M l. 47353–47358, 47541–47609), `.HandleItemUse @ 1004d054` (M l. 44197–44301), `.SetHeldItemPos @ 1004bf2c`
/// (M l. 43460–43533), `.SetupHeldItemSprite` / `.HandleHeldItemSprite` (M l. 43406–43459), `.SmiteEnemies @ 10052964`
/// (M l. 46981–47046), the potion drink (row 32, M l. 45177–45218), the hint conversations inside the player's Handle
/// (the resumable player Handle) and the shield's `.HasItem(0xe) ∨ .HasItem(0xf)` (M l. 47635–47636). Synthetic 16×16
/// grids over level 1's header (as `CastTests`); every expected value is the dump's arithmetic next to the assertion.
final class ItemUseTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// The player stands with his hot-rect bottom (`y + 0x55`) on the floor surface 400 (as `PlayerMotionTests`).
    private let standY = 400 - 0x55

    /// A 16×16 grid with an FG kind-3 floor on row 12 when `floor`.
    private func world(floor: Bool = true) throws -> SpriteWorld {
        let w = SpriteWorld(level: try LevelFile.load(from: try resources(), level: 1))
        var fg = [UInt16](repeating: 0, count: 16 * 16)
        if floor { for c in 0..<16 { fg[12 * 16 + c] = 3 + 1 } }
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: fg),
                           bg: TileMap(width: 16, height: 16, cells: [UInt16](repeating: 0, count: 16 * 16)),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        return w
    }

    private static let empty = InventorySlot(id: -1, count: 0, field4: -1, field6: 0, isSpell: 0)
    private static func spell(_ id: Int16) -> InventorySlot {
        InventorySlot(id: id, count: 1, field4: -1, field6: 0, isSpell: 1)
    }
    private static func item(_ id: Int16, _ n: Int16 = 1) -> InventorySlot {
        InventorySlot(id: id, count: n, field4: -1, field6: 0, isSpell: 0)
    }

    private static func stock(_ g: inout GameGlobals, _ slots: [InventorySlot], selected: Int16) {
        var inv = [InventorySlot](repeating: Self.empty, count: GameGlobals.inventorySlots)
        for (k, s) in slots.enumerated() { inv[k] = s }
        g.inventory = inv
        g.selectedSlot = selected
    }

    private func stock(_ w: SpriteWorld, _ slots: [InventorySlot], selected: Int16, magic: Int16 = 560) {
        Self.stock(&w.globals, slots, selected: selected)
        w.globals.magic = magic
        w.globals.maxMagic = 1000
    }

    private func player(_ w: SpriteWorld) -> SpriteSlot { w.active.sprite(id: w.playerID!)! }
    private func held(_ w: SpriteWorld) -> SpriteSlot { w.active.record(id: w.player.heldItem!)! }
    /// The player shots on the list — not the held item, which runs the player-shot Handle at c 3…5.
    private func shots(_ w: SpriteWorld) -> [SpriteSlot] {
        w.active.sprites.filter { $0.handler == .playerShot && $0.id != w.player.heldItem }
    }

    /// Spawned at (x, standY) and settled two frames (landed, jump counter refilled).
    private func standing(_ w: SpriteWorld, x: Int = 100) -> TileSolver {
        XCTAssertNotNil(Player.spawn(world: w, x: x, y: standY))
        let solver = TileSolver(world: w)
        Player.handle(world: w, keys: [], solver: solver)
        Player.handle(world: w, keys: [], solver: solver)
        XCTAssertEqual(player(w).groundKind, 3)
        return solver
    }

    /// A face's opaque bounds for the tests (the dagger's, held-item-melee §1.5: face +8 = (8, 0, 16, 22)).
    private static func bounds(_ f: FaceRef) -> IdleSprites.Rect {
        IdleSprites.Rect(top: 8, left: 0, bottom: 16, right: 22)
    }

    /// One `.MTHandleSprites` pass as the session dispatches it: the player, the held item (its own Handle or, at
    /// c 3…5, the player-shot Handle), the shots.
    private func frame(_ w: SpriteWorld, _ solver: TileSolver, _ keys: InputActions) {
        var lights = LightTable()
        w.handleSprites { w, id in
            switch w.active.record(id: id)?.handler {
            case .player?: Player.handle(world: w, keys: keys, solver: solver)
            case .heldItem?: HeldItem.handle(world: w, id: id, faceBounds: Self.bounds)
            case .playerShot?: PlayerShot.handle(world: w, id: id, solver: solver, lights: &lights, effects: 2,
                                                 faceBounds: Self.bounds)
            default: break
            }
        }
    }

    private func reg(_ snd: Int16, _ vol: Int16) -> PlayerCue { PlayerCue(call: .reg, snd: snd, priority: 1, volume: vol) }

    private func itemStats(_ w: SpriteWorld) -> Int {
        w.player.passDraws.filter { if case .statusBar(let s) = $0 { s.call.itemsOnly } else { false } }.count
    }

    private func useKeys() -> KeyState { KeyState(pressed: [Int(FerazelPrefs.defaultKeys[6])]) }

    // MARK: -

    func testDaggerStab() throws {
        let w = try world()
        let solver = standing(w)
        stock(w, [Self.spell(0), Self.item(0)], selected: 1)
        w.player.cues = []
        // The press (M l. 47543–47561): idle / fidgets 0, `0760` = `075c` = 1, item 0 with no swing and no mist →
        // snd 418 (`_DAT_100a03e8`) vol 0x55, counter 1, side flag = facing left (F 2 → 0), in-use 0,
        // `.MoveSelectedItemToFront` (slot 1 to the front, its (1,1,0) call).
        frame(w, solver, .use)
        XCTAssertEqual(w.player.cues.filter { $0.snd == 418 }, [reg(418, 0x55)])
        XCTAssertTrue(w.player.useDebounce)
        XCTAssertTrue(w.player.useItemHeld)
        XCTAssertFalse(w.player.heldLeft)
        XCTAssertEqual(w.player.meleeItem, 0)
        XCTAssertEqual(w.globals.inventory.prefix(2).map(\.id), [0, 0])
        XCTAssertEqual(w.globals.inventory.prefix(2).map(\.isSpell), [0, 1])
        XCTAssertEqual(w.globals.selectedSlot, 0)
        // Ten calls of `.HandleItemUse` (row 33's melee arm, M l. 45817–45820): c = 1…5, −5…−1 at entry (+1, 6 → −5),
        // the player face 1021[|c| − 1], the held face 750 (`0x100a5f68 + 4·0`), damage 100, `+0x158` −1, `+0xeb` 0;
        // the player-shot Handle and hit callback only at c 3, 4, 5 (M l. 44238–44251).
        var after: [Int16] = [w.player.itemUse]
        var faces: [Int] = [player(w).face?.index ?? -1]
        var striking: [Bool] = [held(w).handler == .playerShot && held(w).hasHit]
        // Each half on its own: off outside c 3…5 is the Handle back to `.HandleHeldItemSprite` and the hit callback 0.
        var hits: [Bool] = [held(w).hasHit]
        var handlers: [SpriteHandler?] = [held(w).handler]
        for k in 2...10 {
            if k == 3 { w.player.fidgets = 7 }
            frame(w, solver, k == 3 ? [] : .use)                  // a release on frame 3 clears the latch only
            // `.HandleItemUse`'s step 1 (M l. 44213–44215): idle (row 6 made it 1) = the fidget count.
            if k == 3 { XCTAssertEqual(w.player.idle, 7) }
            after.append(w.player.itemUse)
            XCTAssertEqual(player(w).face?.pict, 1021)
            faces.append(player(w).face?.index ?? -1)
            striking.append(held(w).handler == .playerShot && held(w).hasHit)
            hits.append(held(w).hasHit)
            handlers.append(held(w).handler)
            XCTAssertEqual(held(w).face, FaceRef(pict: 750, index: 0, set: .encoded))
            XCTAssertEqual([held(w).hp, Int16(held(w).crunchStrength), Int16(held(w).crunches)], [100, -1, 0])
        }
        XCTAssertEqual(after, [2, 3, 4, 5, -5, -4, -3, -2, -1, 0])
        XCTAssertEqual(faces, [0, 1, 2, 3, 4, 4, 3, 2, 1, 0])
        XCTAssertEqual(striking, [false, false, true, true, true, false, false, false, false, false])
        XCTAssertEqual(hits, [false, false, true, true, true, false, false, false, false, false])
        XCTAssertEqual(handlers, [.heldItem, .heldItem, .playerShot, .playerShot, .playerShot,
                                  .heldItem, .heldItem, .heldItem, .heldItem, .heldItem])
        XCTAssertEqual(held(w).handler, .heldItem)
        // The press on frame 4 found the swing running (`0698 ≠ 0`): no second 418; frame 11, USE still held: latched.
        frame(w, solver, .use)
        XCTAssertEqual(w.player.cues.filter { $0.snd == 418 }.count, 1)
        XCTAssertEqual(w.player.itemUse, 0)
        XCTAssertNil(held(w).face)                                   // row 31's `*(065c + 0xc0) = 0` (M l. 45141)
        XCTAssertNotEqual(player(w).face?.pict, 1021)
        // Released, pressed again: a new swing.
        frame(w, solver, [])
        XCTAssertFalse(w.player.useItemHeld)
        frame(w, solver, .use)
        XCTAssertEqual(w.player.cues.filter { $0.snd == 418 }.count, 2)
        XCTAssertEqual(w.player.itemUse, 2)

        // The Ice Pick (0x12): 300, `+0x158` 4, `+0xeb` 1, face 768; the Vorpal Dirk (0x15): 200, 1, 1, face 771
        // (M l. 44285–44294).
        for (id, hp, crunch, pict) in [(Int16(0x12), Int16(300), Int32(4), Int16(768)), (0x15, 200, 1, 771)] {
            let v = try world()
            let sv = standing(v)
            stock(v, [Self.spell(0), Self.item(id)], selected: 1)
            frame(v, sv, .use)
            XCTAssertEqual(v.player.meleeItem, id)
            XCTAssertEqual([held(v).hp], [hp])
            XCTAssertEqual(held(v).crunchStrength, crunch)
            XCTAssertEqual(held(v).crunches, 1)
            XCTAssertEqual(held(v).face?.pict, pict)
        }

        // Magic 0 with the Fireball selected (CS, M l. 47321–47336): the dagger to the front, then the item gate of the
        // same call stabs — snd 418, counter 1 (no `.HandleItemUse` here: `HandleKeys` alone).
        do {
            let v = try world()
            XCTAssertNotNil(Player.spawn(world: v, x: 100, y: standY))
            stock(v, [Self.spell(0), Self.spell(5), Self.item(0), Self.item(1)], selected: 0, magic: 0)
            HandleKeys.run(world: v, keys: .use, ridden: nil)
            XCTAssertEqual(v.globals.inventory.prefix(4).map(\.id), [0, 0, 5, 1])
            XCTAssertEqual(v.player.cues, [reg(418, 0x55)])
            XCTAssertEqual(v.player.itemUse, 1)
            XCTAssertEqual(v.player.meleeItem, 0)
            XCTAssertTrue(v.player.useItemHeld)
        }
        // USE held with an item selected, latched (`075c` set: no switch): fidgets and idle zeroed every frame (M l.
        // 47544–47545), each on its own.
        do {
            let v = try world()
            XCTAssertNotNil(Player.spawn(world: v, x: 100, y: standY))
            stock(v, [Self.spell(0), Self.item(0)], selected: 1)
            v.player.useItemHeld = true
            v.player.fidgets = 7
            v.player.idle = 9
            HandleKeys.run(world: v, keys: .use, ridden: nil)
            XCTAssertEqual(v.player.fidgets, 0)
            XCTAssertEqual(v.player.idle, 0)
            XCTAssertEqual(v.player.itemUse, 0)
            // USE up: neither touched (the L/R block runs instead).
            v.player.fidgets = 7
            v.player.idle = 9
            HandleKeys.run(world: v, keys: [], ridden: nil)
            XCTAssertEqual([v.player.fidgets, v.player.idle], [7, 9])
        }
        // Slot −1 (the empty inventory, `repairSelection`): the gate and switch read `G+0x22` (flag 0, an item) and
        // `G+0x1a` (id 0, the zero gap): the dagger's arm — snd 418, counter 1 (M l. 47541–47561).
        do {
            let v = try world()
            XCTAssertNotNil(Player.spawn(world: v, x: 100, y: standY))
            stock(v, [], selected: -1)
            HandleKeys.run(world: v, keys: .use, ridden: nil)
            XCTAssertEqual(v.player.cues, [reg(418, 0x55)])
            XCTAssertEqual(v.player.itemUse, 1)
            XCTAssertEqual(v.player.meleeItem, 0)
            XCTAssertTrue(v.player.useItemHeld)
        }
        // A cast press: the item block later in the same call clears `075c` (the selection is a spell, M l. 47355).
        do {
            let v = try world()
            XCTAssertNotNil(Player.spawn(world: v, x: 100, y: standY))
            stock(v, [Self.spell(0), Self.item(0)], selected: 0)
            HandleKeys.run(world: v, keys: .use, ridden: nil)
            XCTAssertTrue(v.player.castFlag)
            XCTAssertFalse(v.player.useItemHeld)
            XCTAssertEqual(v.player.itemUse, 0)
        }
        // The gate's other terms (M l. 47353–47356): shield raised, clinging, on a rope → no switch, `075c` 0 (and the
        // L/R block runs); in spirit form (`0578`, `0574`) the switch runs but item 0 does nothing — latches set.
        for f: (inout PlayerState) -> Void in [{ $0.shieldRaise = 1 }, { $0.climb = 1 }, { $0.rope = true },
                                                { $0.spiritTimer = 5 }, { $0.spiritTransition = 2 }] {
            let v = try world()
            XCTAssertNotNil(Player.spawn(world: v, x: 100, y: standY))
            stock(v, [Self.item(0)], selected: 0)
            f(&v.player)
            let spirit = v.player.spiritTimer != 0 || v.player.spiritTransition != 0
            HandleKeys.run(world: v, keys: [.use, .right], ridden: nil)
            XCTAssertEqual(v.player.itemUse, 0)
            XCTAssertTrue(v.player.cues.filter { $0.snd == 418 }.isEmpty)
            XCTAssertEqual(v.player.useItemHeld, spirit)
            // The L/R block (airborne: vx + 0x14a) ran unless the switch took its place or the player clings.
            XCTAssertEqual(player(v).vx != 0, !spirit && v.player.climb == 0)
        }
    }

    func testHeldItemPositions() throws {
        let w = try world()
        XCTAssertNotNil(Player.spawn(world: w, x: 100, y: standY))
        let pid = w.playerID!, hid = w.player.heldItem!
        XCTAssertEqual(held(w).handler, .heldItem)                  // `.SetupHeldItemSprite`'s Handle (M l. 43420)
        w.active.update(id: pid) { p in
            p.x256 = 1000 << 8
            p.y256 = 300 << 8
            p.y = 300
            p.waterRow = 0
            p.lastWater = 0
        }
        func place(_ c: Int16, crouch: Int16 = 0, left: Bool = false, mirrored: Bool = false) -> (Int, Int) {
            w.player.itemUse = c
            w.player.crouch = crouch
            w.player.heldLeft = left
            w.active.update(id: pid) { $0.mirrored = mirrored }
            HeldItem.setPos(w, player: pid, held: hid)
            let h = held(w)
            XCTAssertEqual(h.x256, Int32(h.x) << 8)
            XCTAssertEqual(h.y256, Int32(h.y) << 8)
            XCTAssertEqual(h.mirrored, mirrored)
            return (h.x, h.y)
        }
        // (dx, dy) by |c| (M l. 43474–43501): 1 (0x2d, 0x1e), 2 (0x35, 0x1c), 3 (0x42, 0x18), 4 (0x47, 0x16), 5 and 0
        // (0x54, 0x11); y + dy + 0x16, + 0xc crouching.
        XCTAssertEqual(place(1).0, 1000 + 0x2d)
        XCTAssertEqual(place(1).1, 300 + 0x1e + 0x16)
        XCTAssertEqual(place(-2).0, 1000 + 0x35)
        XCTAssertEqual(place(-2).1, 300 + 0x1c + 0x16)
        XCTAssertEqual(place(3).1, 300 + 0x18 + 0x16)
        XCTAssertEqual(place(-4).0, 1000 + 0x47)
        XCTAssertEqual(place(4).1, 300 + 0x16 + 0x16)
        XCTAssertEqual(place(0).0, 1000 + 0x54)
        XCTAssertEqual(place(5, crouch: 2).0, 1000 + 0x54)
        XCTAssertEqual(place(5, crouch: 2).1, 300 + 0x11 + 0xc + 0x16)
        // Pressed facing left (`PTR_DAT_100a04f4`), still mirrored: x + (100 − 0x42) − 0x20 (M l. 43509, 43525–43527).
        XCTAssertEqual(place(3, left: true, mirrored: true).0, 1000 + (100 - 0x42) - 0x20)
        // Pressed left, turned right mid-swing: the side stays, the −0x20 follows the current `+0x17e`.
        XCTAssertEqual(place(3, left: true, mirrored: false).0, 1000 + (100 - 0x42))
        // Pressed right, now mirrored: x + off − 0x20.
        XCTAssertEqual(place(1, mirrored: true).0, 1000 + 0x2d - 0x20)
        // The water contact (M l. 43514–43523): max(+0x120, +0x11c) − (player y − held y), at least 1; no contact →
        // left alone; the (short) of the max.
        w.active.update(id: hid) { $0.waterRow = 77 }
        _ = place(3)
        XCTAssertEqual(held(w).waterRow, 77)
        w.active.update(id: pid) { p in
            p.waterRow = 0x10
            p.lastWater = 0x30
        }
        _ = place(3)
        XCTAssertEqual(held(w).waterRow, 0x30 + (0x18 + 0x16))
        w.active.update(id: pid) { p in
            p.waterRow = 0x30
            p.lastWater = 0x10
        }
        _ = place(1)
        XCTAssertEqual(held(w).waterRow, 0x30 + (0x1e + 0x16))
        w.active.update(id: pid) { p in
            p.waterRow = 0x18000
            p.lastWater = 0
        }
        _ = place(1)
        XCTAssertEqual(held(w).waterRow, 1)

        // The held faces (`.InitPlayerSprite` M l. 42478–42482: `Load1EncFaceFromPICT(0x2ee + i)` for the 27 ids):
        // only the PICTs the data holds give a face.
        let r = try resources()
        for i: Int16 in 0..<27 {
            let present = r.resource(type: "PICT", id: 750 + i, chain: .frontEnd) != nil
            XCTAssertEqual(HeldItem.face(item: i) != nil, present, "item \(i)")
            if present { XCTAssertEqual(HeldItem.face(item: i), FaceRef(pict: 750 + i, index: 0, set: .encoded)) }
        }
        XCTAssertEqual([Int16(0), 6, 0x12, 0x15].map { HeldItem.face(item: $0)?.pict }, [750, 756, 768, 771])
        XCTAssertNil(HeldItem.face(item: -1))
        XCTAssertNil(HeldItem.face(item: 0x1a))

        // `.HandleHeldItemSprite` (M l. 43431–43458): v 0, 24.8 from the pixel position, old position = position,
        // layer 0x14, type 100; with a face, the hot rect = its bounds with left + 1, right − 1; `+0xa6` < 0 → + 1.
        w.active.update(id: hid) { h in
            h.x = 321
            h.y = 123
            h.x256 = 5
            h.vx = 70
            h.vy = -70
            h.layer = 3
            h.type = 7
            h.face = FaceRef(pict: 750, index: 0, set: .encoded)
            h.counterA6 = -3
        }
        HeldItem.handle(world: w, id: hid, faceBounds: Self.bounds)
        var h = held(w)
        XCTAssertEqual([h.vx, h.vy, h.x256, h.y256, h.layer], [0, 0, 321 << 8, 123 << 8, 0x14])
        XCTAssertEqual(h.oldPosition, SpriteSlot.Point(x: 321, y: 123))
        XCTAssertEqual(h.type, 100)
        XCTAssertEqual(h.hotRect, IdleSprites.Rect(top: 8, left: 1, bottom: 16, right: 21))
        XCTAssertEqual(h.counterA6, -2)
        w.active.update(id: hid) { h in
            h.face = nil
            h.hotRect = IdleSprites.Rect(top: 1, left: 2, bottom: 3, right: 4)
            h.counterA6 = 5
        }
        HeldItem.handle(world: w, id: hid, faceBounds: Self.bounds)
        h = held(w)
        XCTAssertEqual(h.hotRect, IdleSprites.Rect(top: 1, left: 2, bottom: 3, right: 4))
        XCTAssertEqual(h.counterA6, 5)
    }

    func testSeedsThrown() throws {
        // Fire seeds (6) facing right, then Ziridium seeds (0x1a) facing left in the air.
        for (id, left) in [(Int16(6), false), (0x1a, true)] {
            let w = try world(floor: !left)
            let solver: TileSolver
            if left {
                w.globals.startFacing = 1
                XCTAssertNotNil(Player.spawn(world: w, x: 100, y: 100))
                solver = TileSolver(world: w)
            } else {
                solver = standing(w)
            }
            stock(w, [Self.spell(0), Self.item(id, 2)], selected: 1)
            w.player.cues = []
            w.player.passDraws = []
            // The press (M l. 47576–47585): snd 704 (`_DAT_100a0268`) vol 0x55, counter 1, the side flag, in-use,
            // `.MoveSelectedItemToFront`, `.RemoveItem(id)` at the press (count 2 → 1, its `.UpdateItemStat`).
            frame(w, solver, .use)
            XCTAssertEqual(w.player.cues.filter { $0.snd == 704 }, [reg(704, 0x55)])
            XCTAssertEqual(w.globals.inventory[0].id, id)
            XCTAssertEqual(w.globals.inventory[0].count, 1)
            XCTAssertEqual(itemStats(w), 1)
            XCTAssertEqual(w.player.meleeItem, id)
            XCTAssertEqual(w.player.heldLeft, left)
            XCTAssertEqual(held(w).face, HeldItem.face(item: id))
            // Walking during the swing (USE up): the seed takes the player's vx.
            for _ in 0..<3 { frame(w, solver, left ? [.left] : [.right]) }
            XCTAssertEqual(w.player.itemUse, 5)
            XCTAssertTrue(shots(w).isEmpty)
            let centre = held(w).centre
            var rng = w.rng
            // c == 5 (M l. 44262–44283): `MTNewSprite(0x5a01, held +0x10, held +0xe − 4, 0xb, −1, Setup)`, `+0xf4` 1 for
            // 0x1a, vx 0x60e (left: −, x256 + 0xc00) + the player's vx, vy −0x60e + the player's vy when > 0; in-use −1.
            Player.handle(world: w, keys: left ? [.left] : [.right], solver: solver)
            let seeds = shots(w)
            XCTAssertEqual(seeds.count, 1)
            let s = try XCTUnwrap(seeds.first)
            let p = player(w)
            XCTAssertEqual(s.type, 0x5a)
            XCTAssertEqual(s.power, 1)
            XCTAssertEqual(s.phase, rng.next(5))                        // the Setup's `FastRand(5)`
            XCTAssertEqual(s.oldPosition, SpriteSlot.Point(x: centre.x, y: centre.y - 4))
            XCTAssertEqual(s.x256, (Int32(centre.x) << 8) + (left ? 0xc00 : 0))
            XCTAssertEqual(s.y256, Int32(centre.y - 4) << 8)
            XCTAssertNotEqual(p.vx, 0)
            XCTAssertEqual(s.vx, (left ? -0x60e : 0x60e) + p.vx)
            if left { XCTAssertGreaterThan(p.vy, 0) }
            XCTAssertEqual(s.vy, -0x60e + (0 < p.vy ? p.vy : 0))
            XCTAssertEqual(s.classWordF4, id == 0x1a ? 1 : 0)
            XCTAssertEqual(w.player.meleeItem, -1)
            XCTAssertEqual(w.player.itemUse, -5)
            // The rest of the swing: no face for item −1, no second seed.
            for _ in 0..<5 { frame(w, solver, []) }
            XCTAssertNil(held(w).face)
            XCTAssertEqual(shots(w).count, 1)
            XCTAssertEqual(w.player.itemUse, 0)
        }
        // The player's vy is added only when > 0 (M l. 44278–44280): rising (vy < 0) → −0x60e alone; falling → + vy.
        do {
            let w = try world()
            _ = standing(w)
            let pid = w.playerID!, hid = w.player.heldItem!
            for (vy, added) in [(Int32(-0x300), false), (0x200, true)] {
                w.active.update(id: pid) { $0.vy = vy }
                let before = Set(shots(w).map(\.id))
                HeldItem.throwSeed(w, player: pid, held: hid, ziridium: false)
                let s = try XCTUnwrap(shots(w).first { !before.contains($0.id) })
                XCTAssertEqual(s.vy, -0x60e + (added ? vy : 0), "vy \(vy)")
            }
        }
    }

    func testPotionsDrink() throws {
        // The health potion (5) at HP 0x100 (M l. 45177–45193): the counter +1 per frame; at 20 HP = breath = player
        // `+0xa4` = max, snds 502 (`_DAT_100a02d0`) then 415 (`_DAT_100a03f4`), `.RemoveItem(5)`, `05a8` 6, the health
        // flash 0xb; > 40 → 0.
        let w = try world()
        let solver = standing(w)
        stock(w, [Self.spell(0), Self.item(5, 2)], selected: 1)
        w.globals.maxHealth = 0x230
        w.globals.health = 0x100
        w.globals.breath = 0x100
        w.active.update(id: w.playerID!) { $0.hp = 0x100 }
        w.player.cues = []
        w.player.passDraws = []
        frame(w, solver, .use)
        XCTAssertEqual(w.player.potionItem, 5)
        XCTAssertEqual(w.globals.selectedSlot, 1)                     // no move to the front for a potion
        var counters: [Int16] = [w.player.potion]
        while counters.last != 0x14 {
            XCTAssertEqual(player(w).hp, 0x100)
            frame(w, solver, .use)
            counters.append(w.player.potion)
            XCTAssertEqual(w.player.wandPhase, 0)                      // `.HandleKeys`' drink return (M l. 47114–47117)
        }
        XCTAssertEqual(counters, Array(2...0x14))
        XCTAssertEqual([w.globals.health, w.globals.breath, player(w).hp], [0x230, 0x230, 0x230])
        XCTAssertEqual(w.player.cues.filter { $0.call == .reg && $0.snd != 442 }, [reg(502, 0x100), reg(415, 0x100)])
        XCTAssertEqual(w.globals.inventory[1].count, 1)
        XCTAssertEqual(itemStats(w), 1)
        XCTAssertEqual(w.statusBar.flashes.health, 0xb)
        XCTAssertEqual(w.statusBar.flashes.magic, 0)
        XCTAssertEqual(w.player.countdown05a8, 6)
        while counters.last != 0 {
            frame(w, solver, [])
            counters.append(w.player.potion)
        }
        XCTAssertEqual(counters.suffix(22), Array(0x14...0x28) + [0])
        XCTAssertEqual(w.globals.inventory[1].count, 1)

        // The magic potion (4) (M l. 45194–45203): magic = max, snds 500 (`_DAT_100a02d8`), 415, the magic flash.
        let m = try world()
        let ms = standing(m)
        stock(m, [Self.item(4)], selected: 0, magic: 7)
        m.player.cues = []
        frame(m, ms, .use)
        for _ in 0..<0x40 where m.player.potion != 0x14 { frame(m, ms, []) }
        XCTAssertEqual(m.player.potion, 0x14, "the drink never reached 20")
        XCTAssertEqual(m.globals.magic, 1000)
        XCTAssertEqual(m.player.cues.filter { $0.call == .reg && $0.snd != 442 }, [reg(500, 0x100), reg(415, 0x100)])
        XCTAssertEqual(m.statusBar.flashes.magic, 0xb)
        XCTAssertEqual(m.statusBar.flashes.health, 0)
        XCTAssertFalse(m.globals.hasItem(4))
        XCTAssertEqual(m.player.countdown05a8, 6)

        // The Mist potion (0x19) (M l. 45204–45208): snd 415 only, removed, `05a8` 6. In spirit form no drink starts.
        let x = try world()
        let xs = standing(x)
        stock(x, [Self.item(0x19)], selected: 0)
        x.player.cues = []
        frame(x, xs, .use)
        for _ in 0..<0x40 where x.player.potion != 0x14 { frame(x, xs, []) }
        XCTAssertEqual(x.player.potion, 0x14, "the drink never reached 20")
        XCTAssertEqual(x.player.cues.filter { $0.call == .reg && $0.snd != 442 }, [reg(415, 0x100)])
        XCTAssertFalse(x.globals.hasItem(0x19))
        XCTAssertEqual(x.player.countdown05a8, 6)
        let y = try world()
        XCTAssertNotNil(Player.spawn(world: y, x: 100, y: standY))
        stock(y, [Self.item(5)], selected: 0)
        y.player.spiritTransition = 1
        HandleKeys.run(world: y, keys: .use, ridden: nil)
        XCTAssertEqual(y.player.potion, 0)
        XCTAssertEqual(y.player.potionItem, -1)
    }

    func testEscapeRing() throws {
        // USE on the Escape Ring (0x11, M l. 47597–47603): `.RemoveItem`, snd 421 (`_DAT_100a03dc`), exit −1, the level
        // complete, `*_DAT_1009fd64 = 1` — `LevelRun` skips `.StageCompleteEffect` and clears the flag (M l. 5311–5313);
        // exit −1 unlocks nothing.
        let r = try resources()
        let stub = StubServices()
        let run = try LevelRun(resources: r, prefs: FerazelPrefs(), level: 1, seed: 1, carry: LevelCarry(),
                               save: SaveBlock(), fade: ScreenFade(), music: MusicFade(), services: stub,
                               sounds: StageSounds(prefs: FerazelPrefs(), lengths: Self.lengths))
        var t: UInt32 = 0
        func tick(_ input: FrontInput = FrontInput()) throws -> FrontOutput {
            stub.now = t
            let out = try run.tick(now: t, input: input).merged
            t &+= 1
            return out
        }
        while run.iterations < 45 { _ = try tick() }
        let s = try XCTUnwrap(run.session)
        Self.stock(&s.world.globals, [Self.spell(0), Self.item(0x11)], selected: 1)
        var outs: [FrontOutput] = []
        var levelSounds: [Int16] = []
        while run.end == nil && outs.count < 2000 {
            outs.append(try tick(FrontInput(keys: useKeys())))
            levelSounds += run.lastSteps.flatMap { $0.sounds.map(\.snd) }
        }
        XCTAssertEqual(run.end, .completed(exit1: -1, exit2: -1))
        XCTAssertEqual(levelSounds.filter { $0 == 421 }.count, 1)
        XCTAssertFalse(s.globals.hasItem(0x11))
        XCTAssertEqual(s.world.player.exitIndex, -1)
        XCTAssertTrue(s.world.player.levelDone)
        XCTAssertTrue(s.world.stageCompleteSkip)
        XCTAssertFalse(run.skipStageComplete)
        XCTAssertFalse(outs.flatMap { $0.draws }.contains { if case .copyPicture(140, _, _, _, _, _) = $0 { true } else { false } })
        XCTAssertNil(LevelFlow.next(level: s.level.header.mapNodeLevel, exit: -1, map: s.map))
    }

    func testSmitingRing() throws {
        // `.SmiteEnemies` (M l. 46981–47046): every listed sprite whose Handle is one of the 15 enemy Handles (TOC
        // 0x100a048c…0x100a04c4; the Phase-1 enemies are inert, matched by class — Ruling 3), the first 16 only:
        // `MTNewSprite(0x5a01, centre x − 4, centre y − 4, 0xb, −1, .SetupPlayerShotSprite)`, `+0xf0` 0, `+0xa6` 0.
        let w = try world()
        let solver = standing(w)
        let enemies: [(Int16, IdleSprites.Rect, (Int, Int))] = [
            (0x6cc, IdleSprites.Rect(top: 0xf, left: 0xc, bottom: 0x2f, right: 0x2b), (300, 200)),   // bat
            (0x708, IdleSprites.Rect(top: 0x14, left: 0xb, bottom: 0x49, right: 0x48), (420, 150)),  // frog
            (0x6a4, IdleSprites.Rect(top: 0x10, left: 0x10, bottom: 0x50, right: 0x40), (40, 260)),  // walker
        ]
        var centres: [SpriteSlot.Point] = []
        for (type, rect, at) in enemies {
            let id = try XCTUnwrap(w.newSprite(type: type, x: at.0, y: at.1, layer: 4, handler: .inert) { s in
                s.x = at.0
                s.y = at.1
                s.hotRect = rect
            })
            let e = w.active.sprite(id: id)!
            centres.append(SpriteSlot.Point(x: e.x + rect.left + ((rect.right - rect.left) >> 1),
                                            y: e.y + rect.top + ((rect.bottom - rect.top) >> 1)))
        }
        // Not enemies: a Button (0x528, inert), a Bonus, an idled enemy record (Handle 0).
        w.newSprite(type: 0x528, x: 10, y: 10, layer: 4, handler: .inert)
        w.newSprite(type: 0x532, x: 10, y: 10, layer: 4, handler: .bonus)
        let idled = try XCTUnwrap(w.newSprite(type: 0x6cc, x: 10, y: 10, layer: 4, handler: .inert))
        w.active.update(id: idled) { $0.handleCleared = true }
        stock(w, [Self.spell(0), Self.item(0x10)], selected: 1)
        w.player.cues = []
        w.player.passDraws = []
        var rng = w.rng
        // The press (M l. 47591–47595): `.RemoveItem(0x10)`, flash 3, snd 421 (`_DAT_100a03dc`) vol 0x100, smite.
        HandleKeys.run(world: w, keys: .use, ridden: nil)
        let seeds = shots(w)
        XCTAssertEqual(seeds.count, 3)
        XCTAssertEqual(seeds.map(\.oldPosition), centres.map { SpriteSlot.Point(x: $0.x - 4, y: $0.y - 4) })
        XCTAssertEqual(seeds.map(\.type), [0x5a, 0x5a, 0x5a])
        XCTAssertEqual(seeds.map(\.power), [1, 1, 1])
        XCTAssertEqual(seeds.map(\.phase), [rng.next(5), rng.next(5), rng.next(5)])
        XCTAssertEqual(seeds.map(\.seedHidden), [0, 0, 0])
        XCTAssertEqual(seeds.map(\.counterA6), [0, 0, 0])
        XCTAssertEqual(w.flash.count, 3)
        XCTAssertEqual(w.player.cues, [reg(421, 0x100)])
        XCTAssertFalse(w.globals.hasItem(0x10))
        XCTAssertEqual(itemStats(w), 1)
        XCTAssertEqual(w.player.itemUse, 0)
        _ = solver

        // The first 16 only (`sVar19` from 0x10).
        let v = try world()
        XCTAssertNotNil(Player.spawn(world: v, x: 100, y: standY))
        for k in 0..<18 { v.newSprite(type: 0x6b8, x: 20 * k, y: 50, layer: 0xb, handler: .inert) }
        stock(v, [Self.item(0x10)], selected: 0)
        HandleKeys.run(world: v, keys: .use, ridden: nil)
        XCTAssertEqual(shots(v).count, 16)
        // The 15 Handles resolved (`pef.py tocfunc`): no Crab, no Button.
        XCTAssertEqual(Set(Smite.enemyClasses), [.xichra, .wizard, .warrior, .walker, .salamander, .roach, .gremlin,
                                                 .frog, .floater, .demon, .dillo, .crawler, .chief, .blob, .bat])
        XCTAssertEqual(Smite.enemyClasses.count, 15)
    }

    func testHintSuspendsInsidePlayerHandle() throws {
        let r = try resources()
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1)
        for _ in 0..<40 { _ = s.step(keys: KeyState()) }
        let pid = s.playerID
        XCTAssertNotEqual(s.active.sprite(id: pid)?.groundKind, 0)
        XCTAssertEqual(s.player.jumpCounter, 6)
        Self.stock(&s.world.globals, [Self.spell(0), Self.item(1)], selected: 1)
        let hid = try XCTUnwrap(s.player.heldItem)
        s.world.active.update(id: hid) { $0.counterA6 = -5 }
        let tail = s.player.counter05ec
        // The Steel Key (1) selected + USE (M l. 47563–47566): `.SimpleConv(4001, "Ferazel", 0x100a616f)` inside the
        // player's Handle — the frame suspends there.
        let first = s.step(keys: useKeys())
        XCTAssertEqual(first.suspension, .hint(text: HandleKeys.keyHint))
        XCTAssertEqual(HandleKeys.keyHint.count, 112)
        XCTAssertEqual(HandleKeys.keyHint, MacRoman.bytes("You don't need to select keys from the inventory. Just walk "
                                                          + "into the door that requires it and I'll use the key."))
        XCTAssertFalse(s.suspendedInNestedPass)
        XCTAssertEqual(s.player.counter05ec, tail)                      // row 42 not reached
        XCTAssertEqual(s.world.active.record(id: hid)?.counterA6, -5)  // the held item (after the player) not handled
        XCTAssertFalse(first.draws.contains { if case .wrapEraseSprites = $0 { true } else { false } })
        // Resumed with JUMP down too: the rest of `.HandleKeys` and of the frame reads the input polled at the return.
        let resumed = KeyState(pressed: [Int(FerazelPrefs.defaultKeys[6]), Int(FerazelPrefs.defaultKeys[5])])
        let rest = s.resume(.hint(keys: resumed, capsLock: false))
        XCTAssertNil(rest.suspension)
        XCTAssertEqual(s.player.jumpCounter, 5)                          // the initial jump (not the else-refill 6)
        XCTAssertTrue(rest.sounds.contains { $0.snd == 414 })
        XCTAssertEqual(s.player.counter05ec, (tail + 1) % 0x20)
        XCTAssertEqual(s.world.active.record(id: hid)?.counterA6, -4)  // handled once this frame
        XCTAssertTrue(rest.draws.contains { if case .wrapEraseSprites = $0 { true } else { false } })
        // Held: one action per press (`075c`).
        XCTAssertNil(s.step(keys: useKeys()).suspension)

        // The shield (0xe, 0xf) and Red Xichron (0x16) texts (M l. 47589, 47606).
        for (id, text) in [(Int16(0xe), HandleKeys.shieldHint), (0xf, HandleKeys.shieldHint),
                           (0x16, HandleKeys.xichronHint)] {
            let w = try world()
            XCTAssertNotNil(Player.spawn(world: w, x: 100, y: standY))
            stock(w, [Self.item(id)], selected: 0)
            HandleKeys.run(world: w, keys: .use, ridden: nil)
            XCTAssertEqual(w.suspension, .hint(text: text))
        }
        XCTAssertEqual(HandleKeys.shieldHint.count, 135)
        XCTAssertEqual(HandleKeys.xichronHint, MacRoman.bytes("You don't need to select the Red Xichrons from the "
                                                              + "inventory. "))
        XCTAssertEqual(HandleKeys.shieldHint.prefix(29), ArraySlice(MacRoman.bytes("You don't need to select the ")))
        // `Player.handle` stops at the switch; `resumeAfterHint` runs the rest of the Handle once.
        do {
            let w = try world()
            let solver = standing(w)
            stock(w, [Self.item(0x16)], selected: 0)
            let c = w.player.counter05ec
            Player.handle(world: w, keys: .use, solver: solver)
            XCTAssertEqual(w.player.counter05ec, c)
            w.suspension = nil
            Player.resumeAfterHint(world: w, keys: [.use, .jump], solver: solver)
            XCTAssertEqual(w.player.counter05ec, c + 1)
            XCTAssertEqual(w.player.jumpCounter, 5)
        }

        // Nested: the pause's `.PaintFrameWrap(1, 0)` (hosted) runs the Handles with USE held on the Steel Key — the
        // nested pass suspends at the switch; its resume finishes that pass and hands back to the pause.
        let h = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1, hostedByLevelRun: true)
        for _ in 0..<40 { _ = h.step(keys: KeyState()) }
        Self.stock(&h.world.globals, [Self.spell(0), Self.item(1)], selected: 1)
        // JUMP held on the pausing frame: its top-level pass cues the initial jump (snd 414) — kept when the nested pass
        // adds its own cues (appended, not replaced).
        let jumpKeys = KeyState(pressed: [Int(FerazelPrefs.defaultKeys[5])])
        XCTAssertEqual(h.step(keys: jumpKeys, capsLock: true).suspension, .gameLoopKeys(.pause))
        let topCues = h.frameCues
        XCTAssertTrue(topCues.contains { $0.snd == 414 })
        let paint = h.resume(.gameLoopKeys(GameLoopKeyAnswer(reply: .pausePaint, keys: useKeys(), capsLock: false)))
        XCTAssertEqual(paint.suspension, .hint(text: HandleKeys.keyHint))
        XCTAssertTrue(h.suspendedInNestedPass)
        let back = h.resume(.hint(keys: useKeys(), capsLock: false))
        XCTAssertEqual(back.suspension, .gameLoopKeys(.paused))
        XCTAssertFalse(h.suspendedInNestedPass)
        XCTAssertTrue(back.draws.contains { if case .wrapEraseSprites = $0 { true } else { false } })
        XCTAssertEqual(Array(h.frameCues.prefix(topCues.count)), topCues)

        // Through `LevelRun`, top-level: the Steel Key + USE → the run shows `.SimpleConv(4001, "Ferazel", text)`; its
        // end resumes the player's Handle and the frame finishes in the same iteration.
        let run = try LevelRun(resources: r, prefs: FerazelPrefs(), level: 1, seed: 1, carry: LevelCarry(),
                               save: SaveBlock(), fade: ScreenFade(), music: MusicFade(), services: StubServices(),
                               sounds: StageSounds(prefs: FerazelPrefs(), lengths: Self.lengths))
        var t: UInt32 = 1000
        func tick(_ input: FrontInput = FrontInput()) throws {
            _ = try run.tick(now: t, input: input)
            t &+= 1
        }
        let anyKey = FrontInput(keys: KeyState(pressed: [0x01]))     // 'S': no game action
        func finishRead() throws {
            for _ in 0..<5000 {
                guard let c = run.conversation else { return }
                try tick(c.wait == .anyKey ? anyKey : FrontInput())
            }
            XCTFail("the hint never ended")
        }
        for _ in 0..<6000 {
            if let ls = run.session, ls.world.gammaFade.done, run.iterations >= 60, !run.lastSteps.isEmpty { break }
            try tick()
        }
        let ls = try XCTUnwrap(run.session)
        XCTAssertTrue(ls.world.gammaFade.done)
        Self.stock(&ls.world.globals, [Self.spell(0), Self.item(1)], selected: 1)
        let iterationsBefore = run.iterations
        for _ in 0..<10 where run.conversation == nil { try tick(FrontInput(keys: useKeys())) }
        guard case .simple(4001, let name, let text)? = run.conversation?.kind else { return XCTFail("not the hint") }
        XCTAssertEqual(name, MacRoman.bytes("Ferazel"))
        XCTAssertEqual(text, HandleKeys.keyHint)
        XCTAssertEqual(text.count, 112)
        XCTAssertEqual(ls.suspension, .hint(text: HandleKeys.keyHint))
        XCTAssertEqual(run.iterations, iterationsBefore + 1)
        let runTail = ls.player.counter05ec
        try finishRead()
        XCTAssertNil(ls.suspension)
        XCTAssertNil(run.lastSteps.last?.suspension)
        XCTAssertEqual(ls.player.counter05ec, (runTail + 1) % 0x20)     // the rest of the Handle ran
        XCTAssertTrue(run.lastSteps.last?.draws.contains { if case .wrapEraseSprites = $0 { true } else { false } }
                      ?? false)
        XCTAssertEqual(run.iterations, iterationsBefore + 1)
        XCTAssertNil(run.end)

        // Nested, through `LevelRun`: Caps Lock + USE on the Steel Key. The shield is up at the gate of the top-level
        // pass (raise 1 ≥ 1: no switch; no DOWN, so the DOWN block lowers it to 0), so the pause's `.PaintFrameWrap(1,
        // 0)` is the first pass to reach the switch: the hint runs inside the pause, then control returns to it.
        for _ in 0..<20 { try tick() }                                 // USE up: the latch cleared
        XCTAssertFalse(ls.player.useItemHeld)
        let nestedBefore = run.iterations
        for _ in 0..<10 where run.conversation == nil && run.pause == nil {
            ls.world.player.shieldRaise = 1
            try tick(FrontInput(keys: useKeys(), capsLock: true))
        }
        XCTAssertNotNil(run.pause)
        guard case .simple(4001, _, let nestedText)? = run.conversation?.kind else { return XCTFail("no nested hint") }
        XCTAssertEqual(nestedText, HandleKeys.keyHint)
        XCTAssertTrue(ls.suspendedInNestedPass)
        XCTAssertEqual(ls.suspension, .hint(text: HandleKeys.keyHint))
        XCTAssertEqual(run.iterations, nestedBefore + 1)
        try finishRead()
        XCTAssertFalse(ls.suspendedInNestedPass)
        XCTAssertEqual(ls.suspension, .gameLoopKeys(.paused))
        XCTAssertNotNil(run.pause)
        XCTAssertNil(run.end)
        // Caps Lock up: the pause ends and the same iteration finishes; the run steps on.
        for _ in 0..<200 where run.pause != nil { try tick() }
        XCTAssertNil(run.pause)
        XCTAssertNil(ls.suspension)
        XCTAssertEqual(run.iterations, nestedBefore + 1)
        for _ in 0..<4 { try tick() }
        XCTAssertGreaterThan(run.iterations, nestedBefore + 1)
    }

    func testShieldRaiseNeedsShield() throws {
        // `.HandleKeys`' DOWN block (M l. 47610–47680): grounded, DOWN + the direction away from F raises the shield
        // only with `.HasItem(0xe) ∨ .HasItem(0xf)`; without one the keys turn the player.
        let w = try world()
        _ = standing(w)
        stock(w, [Self.spell(0), Self.item(7)], selected: 0)
        XCTAssertEqual(w.player.facing, 2)
        // Crouched first (DOWN alone: crouch 1 — from standing, DOWN + LEFT would walk and turn in the L/R block, whose
        // gate wants crouch 0, M l. 47359–47365).
        HandleKeys.run(world: w, keys: [.down], ridden: nil)
        HandleKeys.run(world: w, keys: [.down, .left], ridden: nil)
        XCTAssertEqual(w.player.shieldRaise, 0)
        XCTAssertEqual(w.player.facing, 1)
        XCTAssertEqual(w.player.crouch, 2)
        for shield: Int16 in [0xe, 0xf] {
            let v = try world()
            _ = standing(v)
            stock(v, [Self.spell(0), Self.item(7), Self.item(shield)], selected: 0)
            HandleKeys.run(world: v, keys: [.down], ridden: nil)
            var raises: [Int16] = []
            for _ in 0..<6 {
                HandleKeys.run(world: v, keys: [.down, .left], ridden: nil)
                raises.append(v.player.shieldRaise)
            }
            XCTAssertEqual(raises, [1, 2, 3, 4, 5, 5])
            XCTAssertEqual(v.player.facing, 2)
            // Pressing toward the facing lowers it (and does not turn).
            HandleKeys.run(world: v, keys: [.down, .right], ridden: nil)
            XCTAssertEqual(v.player.shieldRaise, 4)
            XCTAssertEqual(v.player.facing, 2)
            // Raised: the JUMP arm is gated (M l. 47725) — the else-refill.
            HandleKeys.run(world: v, keys: [.down, .left, .jump], ridden: nil)
            XCTAssertEqual(v.player.jumpCounter, 6)
        }
    }

    // MARK: - LevelRun rig (as `LevelRunTests`)

    private static let lengths: [Int16: Int] = [800: 30, 801: 40, 802: 50, 803: 5, 804: 7, 805: 20]

    private final class StubServices: LevelServices {
        var faces = LevelFaces()
        var now: UInt32 = 0
        func prepare(level: Int) throws -> LevelFaces { faces }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {}
        func deathEffectStep(_ k: Int) throws {}
    }
}
