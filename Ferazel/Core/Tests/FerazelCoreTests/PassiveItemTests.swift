import XCTest
import HectorResources
@testable import FerazelCore

/// MS (docs/plans/2026-10-24-ferazel-phase4.md): the Mist potion's spirit form (row 33's transition arm M l.
/// 45555–45589, row 16 M l. 44827–44855, `.TickTockLong` M l. 43664–43746, row 42's tint M l. 46633–46641, the tile
/// callback's return raw `10054d3c`), the Mist body's arm (M l. 48597–48615), the Resurrection Necklace (row 33's dying
/// arm M l. 45495–45553), the Fire Charm (the Background arm M l. 49576–49580) and the Multi Crystal (`.HurtPlayer` M l.
/// 47989–48032, row 13 M l. 44743–44747); spells-items §4, player-states §3.2–§3.3, physics §5.2,
/// enemy-shots-and-damage §3.7. Synthetic 16×16 grids over level 1's header (as `ItemUseTests`).
final class PassiveItemTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// The player stands with his hot-rect bottom (`y + 0x55`) on the floor surface 400.
    private let standY = 400 - 0x55

    private func world() throws -> SpriteWorld {
        let w = SpriteWorld(level: try LevelFile.load(from: try resources(), level: 1))
        var fg = [UInt16](repeating: 0, count: 16 * 16)
        for c in 0..<16 { fg[12 * 16 + c] = 3 + 1 }
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: fg),
                           bg: TileMap(width: 16, height: 16, cells: [UInt16](repeating: 0, count: 16 * 16)),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        return w
    }

    private static func spell(_ id: Int16) -> InventorySlot {
        InventorySlot(id: id, count: 1, field4: -1, field6: 0, isSpell: 1)
    }
    private static func item(_ id: Int16, _ n: Int16 = 1) -> InventorySlot {
        InventorySlot(id: id, count: n, field4: -1, field6: 0, isSpell: 0)
    }

    private func stock(_ w: SpriteWorld, _ slots: [InventorySlot], selected: Int16 = 0) {
        var inv = [InventorySlot](repeating: .empty, count: GameGlobals.inventorySlots)
        for (k, s) in slots.enumerated() { inv[k] = s }
        w.globals.inventory = inv
        w.globals.selectedSlot = selected
        w.globals.maxHealth = 0x230
        w.globals.health = 0x230
        w.globals.breath = 0x230
    }

    private func player(_ w: SpriteWorld) -> SpriteSlot { w.active.record(id: w.playerID!)! }
    private func f(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }
    private func reg(_ snd: Int16, _ vol: Int16 = 0x100) -> PlayerCue {
        PlayerCue(call: .reg, snd: snd, priority: 1, volume: vol)
    }

    /// Spawned at (100, standY) and settled two frames.
    private func standing(_ w: SpriteWorld) -> TileSolver {
        XCTAssertNotNil(Player.spawn(world: w, x: 100, y: standY))
        let solver = TileSolver(world: w)
        Player.handle(world: w, keys: [], solver: solver)
        Player.handle(world: w, keys: [], solver: solver)
        XCTAssertEqual(player(w).groundKind, 3)
        return solver
    }

    /// One player Handle (the body is left where it was spawned).
    private func frame(_ w: SpriteWorld, _ solver: TileSolver, _ keys: InputActions = []) {
        Player.handle(world: w, keys: keys, solver: solver)
    }

    /// USE on the Mist potion, then frames up to the drink's 40th: returns the faces of the transition frames after
    /// it, up to the frame that starts the spirit form.
    private func drinkMist(_ w: SpriteWorld, _ solver: TileSolver) -> [FaceRef?] {
        stock(w, [Self.item(0x19)])
        frame(w, solver, .use)
        for _ in 0..<0x40 where w.player.potion != 0x28 { frame(w, solver) }
        XCTAssertEqual(w.player.potion, 0x28, "the drink never reached 40")
        var faces: [FaceRef?] = []
        for _ in 0..<20 where w.player.spiritTimer == 0 {
            frame(w, solver)
            faces.append(player(w).face)
        }
        return faces
    }

    private func touch(_ w: SpriteWorld, _ other: Int) { HitPlayerSprite.hit(w, player: w.playerID!, other: other) }

    // MARK: -

    func testMistSpiritForm() throws {
        let w = try world()
        let solver = standing(w)
        let pid = w.playerID!
        let x0 = player(w).x, y0 = player(w).y
        let before = Set(w.active.sprites.map(\.id))
        stock(w, [Self.item(0x19)])
        frame(w, solver, .use)
        for _ in 0..<0x40 where w.player.potion != 0x28 { frame(w, solver) }
        // The drink's frame 40 (M l. 45210–45213): `_DAT_100a0574 = 1`, and row 33's transition arm runs in the same
        // Handle: face 1038[1 >> 2], n 2.
        XCTAssertEqual(w.player.potion, 0x28)
        XCTAssertEqual(w.player.spiritTransition, 2)
        XCTAssertEqual(player(w).face, f(1038, 0))
        XCTAssertEqual(w.player.spiritTimer, 0)
        // n 2…12: face 1038[n >> 2], v = 0; at 13 the spirit form starts (M l. 45555–45579).
        var faces: [FaceRef?] = []
        for _ in 0..<20 where w.player.spiritTimer == 0 {
            frame(w, solver)
            faces.append(player(w).face)
        }
        XCTAssertEqual(faces, [0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3].map { f(1038, $0) })
        XCTAssertEqual([w.player.spiritTimer, Int32(w.player.spiritTransition)], [600, 0])
        XCTAssertEqual([player(w).vx, player(w).vy], [0, -0x35c])
        XCTAssertEqual([Int(w.player.mistBodyX), Int(w.player.mistBodyY)], [x0, y0])
        // The body: `.MTNewSprite(0x45, x, y, …, .SetupBonusSprite)` at the player, face 1038[3], his facing.
        let bodyID = try XCTUnwrap(w.player.mistBody)
        XCTAssertFalse(before.contains(bodyID))
        let body = try XCTUnwrap(w.active.record(id: bodyID))
        XCTAssertEqual([Int(body.type), body.x, body.y], [0x45, x0, y0])
        XCTAssertEqual(body.handler, .bonus)
        XCTAssertEqual(body.face, f(1038, 3))
        XCTAssertEqual(body.mirrored, player(w).mirrored)
        XCTAssertEqual(body.hotRect, IdleSprites.Rect(top: 0x23, left: 0x23, bottom: 0x50, right: 0x41))
        // Row 42's tint (M l. 46633–46641): 0xb0001 while `_DAT_100a056c` is 0, `+0x88 = 0`.
        XCTAssertFalse(w.player.spiritBlink)
        XCTAssertEqual(player(w).mode, 0xb0001)
        XCTAssertFalse(player(w).lightOverlay)

        // No tile stops the spirit (the tile callback returns at once, raw `10054d3c`): it sinks through the floor.
        for _ in 0..<80 { frame(w, solver) }
        XCTAssertEqual(w.player.spiritTimer, 520)
        XCTAssertGreaterThan(player(w).y, 400)
        XCTAssertEqual(player(w).groundKind, 0)

        // Row 16 (M l. 44827–44855) directly: `+0xce` 0, swim 0 → 1 (3 stays), near-surface 1, gravity 0x50, vy ≥ 0x400
        // → 0x400 (0x3ff stays).
        w.player.swim = 0
        w.player.nearSurface = false
        w.active.update(id: pid) { $0.groundKind = 3; $0.gravity = 0x1b8; $0.vy = 0x500 }
        Player.spiritForm(w, id: pid)
        XCTAssertEqual([Int(w.player.swim), Int(player(w).groundKind), Int(player(w).gravity), Int(player(w).vy)],
                       [1, 0, 0x50, 0x400])
        XCTAssertTrue(w.player.nearSurface)
        w.player.swim = 3
        w.active.update(id: pid) { $0.vy = 0x3ff }
        Player.spiritForm(w, id: pid)
        XCTAssertEqual([Int(w.player.swim), Int(player(w).vy)], [3, 0x3ff])
        // `.TickTockLong`'s marks (M l. 43664–43746): 240 → snd 428, 225 → 429, each toggling the shared byte, which
        // row 42 reads (0xb0005 while set); nothing at 239.
        w.player.flag5fd4 = true
        w.player.cues = []
        w.player.spiritTimer = 241
        Player.spiritForm(w, id: pid)
        XCTAssertEqual(w.player.cues, [reg(428)])
        XCTAssertFalse(w.player.spiritBlink)
        Player.spiritForm(w, id: pid)
        XCTAssertEqual(w.player.cues, [reg(428)])
        w.player.spiritTimer = 226
        Player.spiritForm(w, id: pid)
        XCTAssertEqual(w.player.cues, [reg(428), reg(429)])
        XCTAssertTrue(w.player.spiritBlink)
        Player.tail(w, id: pid, faceWidth: PlayerStates.faceWidth)
        XCTAssertEqual(player(w).mode, 0xb0005)
        w.player.spiritTimer = 16
        w.player.cues = []
        Player.spiritForm(w, id: pid)
        XCTAssertEqual(w.player.cues, [reg(429)])

        // Only a Bonus reaches `.HitPlayerSprite` in spirit form (M l. 48568): a fire hurts not, a coin is taken.
        var fire = SpriteSlot(type: 0x4b8, x: player(w).x, y: player(w).y)
        fire.handler = .background
        fire.hp = 1
        let fid = w.active.insert(fire)
        let hp = player(w).hp
        w.player.cues = []
        touch(w, fid)
        XCTAssertEqual(player(w).hp, hp)
        XCTAssertEqual(player(w).invulnerable, 0)
        XCTAssertTrue(w.player.cues.isEmpty)
        var coin = SpriteSlot(type: 0x516, x: player(w).x, y: player(w).y)
        coin.handler = .bonus
        let cid = w.active.insert(coin)
        touch(w, cid)
        XCTAssertEqual(w.globals.coins, 1)
        XCTAssertEqual(w.active.record(id: cid)?.killCount, 1)

        // Exit B: the timer runs out (M l. 44828–44840) — snd 428 at (0, 0) pitched 32000 (prio 0x14), the shared byte
        // set; G+4 = HP = 0, the player at the body (24.8 too), the body's `+0xe9 = 1`; row 41 starts the death in the
        // same Handle (snd 417).
        w.player.flag5fd4 = false
        w.player.spiritTimer = 1
        w.player.cues = []
        w.active.update(id: pid) { $0.vx = 0x123 }
        frame(w, solver)
        XCTAssertEqual(w.player.spiritTimer, 0)
        XCTAssertEqual(w.player.cues.first, PlayerCue(call: .threeDPitched, snd: 428, priority: 0x14, volume: 0x100,
                                                      position: SpriteSlot.Point(x: 0, y: 0), rate: 32000))
        XCTAssertTrue(w.player.cues.contains(reg(417)))
        XCTAssertTrue(w.player.spiritBlink)
        XCTAssertEqual([Int(w.globals.health), Int(player(w).hp)], [0, 0])
        XCTAssertEqual(w.player.dying, 1)
        XCTAssertEqual(w.active.record(id: bodyID)?.killCount, 1)
        XCTAssertEqual(w.player.mistBodyX, Int32(x0))
        XCTAssertNotEqual(player(w).mode, 0xb0001)                       // timer 0: no spirit tint
        // Row 16 alone writes G+4 = 0 (row 42 would copy the HP into it later in the Handle).
        w.globals.health = 0x100
        w.player.spiritTimer = 1
        Player.spiritForm(w, id: pid)
        XCTAssertEqual(w.globals.health, 0)
    }

    func testMistBodyReturn() throws {
        let w = try world()
        let solver = standing(w)
        let pid = w.playerID!
        let x0 = player(w).x, y0 = player(w).y
        _ = drinkMist(w, solver)
        let bodyID = try XCTUnwrap(w.player.mistBody)
        // Away from the body, timer 0x169 → 0x168 after a frame: the body's arm refuses (> 0x167).
        w.player.spiritTimer = 0x169
        for _ in 0..<10 { frame(w, solver) }
        w.player.spiritTimer = 0x169
        frame(w, solver)
        XCTAssertEqual(w.player.spiritTimer, 0x168)
        w.player.cues = []
        touch(w, bodyID)
        XCTAssertEqual(w.active.record(id: bodyID)?.killCount, 0)
        XCTAssertTrue(w.player.cues.isEmpty)
        XCTAssertNotEqual(player(w).y, y0)
        // 0x167: back in the body (M l. 48597–48615) — timer −1, `_DAT_100a0574 = 0xe`, `05a8` 6, snd 420, the body
        // killed, the player at the stored x / y (24.8 too), v 0.
        frame(w, solver)
        XCTAssertEqual(w.player.spiritTimer, 0x167)
        w.active.update(id: pid) { $0.vx = 0x200; $0.vy = 0x300 }
        w.player.cues = []
        touch(w, bodyID)
        XCTAssertEqual(w.active.record(id: bodyID)?.killCount, 1)
        XCTAssertEqual(w.player.cues, [reg(420)])
        XCTAssertEqual([Int(w.player.spiritTimer), Int(w.player.spiritTransition), Int(w.player.countdown05a8)],
                       [-1, 0xe, 6])
        let p = player(w)
        XCTAssertEqual([p.x, p.y], [x0, y0])
        XCTAssertEqual([p.x256, p.y256, p.vx, p.vy], [Int32(x0) << 8, Int32(y0) << 8, 0, 0])
        // The way back (M l. 45581–45588): n 14…26 → face 1038[(27 − n) >> 2], v 0; past 26 → n 0, timer 0. Row 16 and
        // the spirit tint are off (timer −1); the 05a8 flash tint shows.
        var faces: [FaceRef?] = []
        var modes: [UInt32] = []
        for _ in 0..<13 {
            frame(w, solver)
            faces.append(player(w).face)
            modes.append(player(w).mode)
            XCTAssertEqual(player(w).vx, 0)
        }
        XCTAssertEqual(faces, [3, 3, 2, 2, 2, 2, 1, 1, 1, 1, 0, 0, 0].map { f(1038, $0) })
        XCTAssertEqual(Array(modes.prefix(3)), [0x10009, 0x10009, 0x10009])
        XCTAssertEqual([Int(w.player.spiritTimer), Int(w.player.spiritTransition)], [0, 0])
        frame(w, solver)
        XCTAssertNotEqual(player(w).face?.pict, 1038)                    // the next frame's state arm takes over
        XCTAssertEqual(player(w).y, y0)                                  // the floor holds him again
    }

    func testNecklaceRevives() throws {
        let w = try world()
        _ = standing(w)
        let pid = w.playerID!
        stock(w, [Self.spell(0), Self.item(0x17)])
        w.globals.health = 0
        w.globals.breath = 0
        w.active.update(id: pid) { $0.hp = 0; $0.buoyancy = 5 }
        w.player.cues = []
        w.player.passDraws = []
        // The end of the dying counter (> 80, M l. 45531–45553) with the necklace in slot 1, inside the map: the item
        // flash (mode 0, 0x1e, slot 1), dying back to 30, `0594 = 1`, snd 420 pitched 40000 at the centre, `05a8` 0x14.
        w.player.dying = 0x50
        PlayerStates.select(world: w, id: pid)
        XCTAssertFalse(w.player.gameOver)
        XCTAssertEqual([w.player.dying, w.player.revive, w.player.countdown05a8], [0x1e, 1, 0x14])
        XCTAssertEqual(w.statusBar.flashes.item, 0x1e)
        XCTAssertEqual(w.statusBar.flashes.itemSlot, 1)
        XCTAssertEqual(w.statusBar.flashes.itemMode, 0)
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDPitched, snd: 420, priority: 1, volume: 0x100,
                                                 position: player(w).centre, rate: 40000)])
        XCTAssertTrue(w.globals.hasItem(0x17))
        // The revive (M l. 45495–45512): 30 frames of 1022[(30 − r)/3] with `+0x19e` 0, dying still counting; at the
        // 30th HP = health = breath = the maximum, dying 0, `+0x116 = 0x3c`, `055c`, the necklace removed (one
        // `.UpdateItemStat`), the standard rect.
        var faces: [Int] = []
        for k in 1...30 {
            PlayerStates.select(world: w, id: pid)
            faces.append(player(w).face?.index ?? -1)
            XCTAssertEqual(player(w).face?.pict, 1022)
            XCTAssertEqual(player(w).buoyancy, 0)
            if k < 30 {
                XCTAssertEqual([w.player.dying, w.player.revive], [0x1e + Int16(k), Int16(k) + 1], "frame \(k)")
                XCTAssertEqual(player(w).hp, 0)
                XCTAssertTrue(w.globals.hasItem(0x17))
            }
        }
        XCTAssertEqual(faces, (1...30).map { (30 - $0) / 3 })
        XCTAssertEqual([w.player.dying, w.player.revive], [0, 0])
        XCTAssertEqual([w.globals.health, w.globals.breath, player(w).hp], [0x230, 0x230, 0x230])
        XCTAssertEqual(player(w).invulnerable, 0x3c)
        XCTAssertTrue(w.player.flag055c)
        XCTAssertEqual(player(w).hotRect, HandleKeys.standardHotRect)
        XCTAssertFalse(w.globals.hasItem(0x17))
        XCTAssertEqual(w.player.passDraws.filter { if case .statusBar(let s) = $0 { s.call.itemsOnly } else { false } }
                        .count, 1)
        XCTAssertFalse(w.player.gameOver)

        // No revive → the game over (`DAT_100a5106 = 1`): no necklace; on the glider (GL: `5106 = 1`); the centre
        // outside the map (x < 0, or y > 32·height); a death in liquid ends at 100, not 80.
        func end(_ setUp: (SpriteWorld) -> Void, dying: Int16 = 0x50) throws -> (over: Bool, revive: Int16) {
            let v = try world()
            _ = standing(v)
            stock(v, [Self.spell(0), Self.item(0x17)])
            setUp(v)
            v.player.dying = dying
            PlayerStates.select(world: v, id: v.playerID!)
            return (v.player.gameOver, v.player.revive)
        }
        var r = try end { $0.globals.inventory[1] = .empty }
        XCTAssertEqual([r.over ? 1 : 0, Int(r.revive)], [1, 0])
        r = try end { $0.player.glider = true }
        XCTAssertEqual([r.over ? 1 : 0, Int(r.revive)], [1, 0])
        r = try end { $0.player.centreX = -1 }
        XCTAssertEqual([r.over ? 1 : 0, Int(r.revive)], [1, 0])
        r = try end { $0.player.centreY = Int16($0.level.header.gridHeight) * 32 + 1 }
        XCTAssertEqual([r.over ? 1 : 0, Int(r.revive)], [1, 0])
        r = try end { $0.player.centreX = Int16($0.level.header.gridWidth) * 32 }
        XCTAssertEqual([r.over ? 1 : 0, Int(r.revive)], [0, 1])
        r = try end({ $0.player.diedInLiquid = true })
        XCTAssertEqual([r.over ? 1 : 0, Int(r.revive)], [0, 0])
        r = try end({ $0.player.diedInLiquid = true }, dying: 100)
        XCTAssertEqual([r.over ? 1 : 0, Int(r.revive)], [0, 1])
        r = try end({ _ in }, dying: 0x4f)
        XCTAssertEqual([r.over ? 1 : 0, Int(r.revive)], [0, 0])
    }

    func testFireCharmImmunity() throws {
        // A fire Background (M l. 49576–49580): no Fire Charm (0x18) → `.HurtPlayer(player, fire, 0xe0, 1, 0x3c, 0)`
        // — HP − 0xe0, `+0x116` 0x3c, stun, snd 450 then 508 twice (damage ≥ 0xe0), no coins; with it → nothing,
        // unless the fire's `+0x14c` > 0. The other types are not fire.
        func hurt(_ type: Int16, charm: Bool, timer: Int32 = 0) throws -> (hp: Int16, w: SpriteWorld) {
            let w = try world()
            _ = standing(w)
            stock(w, charm ? [Self.spell(0), Self.item(0x18)] : [Self.spell(0)])
            w.globals.coins = 10
            var fire = SpriteSlot(type: type, x: player(w).x, y: player(w).y)
            fire.handler = .background
            fire.hp = 1
            fire.classTimer = timer
            let fid = w.active.insert(fire)
            w.player.cues = []
            touch(w, fid)
            return (0x230 - player(w).hp, w)
        }
        let (dmg, w) = try hurt(0x4b8, charm: false)
        XCTAssertEqual(dmg, 0xe0)
        XCTAssertEqual(player(w).invulnerable, 0x3c)
        XCTAssertEqual(player(w).flash, 0xc)
        XCTAssertEqual(w.player.stun, 1)
        XCTAssertEqual(w.player.cues.map(\.snd), [450, 508, 508])
        XCTAssertEqual(w.player.cues.first, reg(450, 0xab))
        XCTAssertEqual(w.globals.coins, 10)
        for t: Int16 in [0x4bb, 0x4bc, 0x4bd] { XCTAssertEqual(try hurt(t, charm: false).hp, 0xe0, "type \(t)") }
        for t: Int16 in [0x4b8, 0x4bb, 0x4bc, 0x4bd] {
            let (d, v) = try hurt(t, charm: true)
            XCTAssertEqual(d, 0, "type \(t)")
            XCTAssertTrue(v.player.cues.isEmpty)
            XCTAssertEqual(v.player.stun, 0)
            XCTAssertEqual(try hurt(t, charm: true, timer: 1).hp, 0xe0, "type \(t), +0x14c 1")
        }
        XCTAssertEqual(try hurt(0x4b8, charm: true, timer: -1).hp, 0)
        for t: Int16 in [0x4b7, 0x4b9, 0x4ba, 0x4be] { XCTAssertEqual(try hurt(t, charm: false).hp, 0, "type \(t)") }
    }

    func testCrystalLostAfterHurt() throws {
        let w = try world()
        _ = standing(w)
        let pid = w.playerID!
        stock(w, [Self.spell(0), Self.item(0x13, 2)])
        var a = SpriteSlot(type: 0x4b8, x: 0, y: 0)
        a.handler = .background
        a.hp = 1
        let aid = w.active.insert(a)
        w.active.update(id: pid) { $0.vx = 0x2000; $0.mirrored = false }
        let c = player(w).centre
        var r = w.rng
        let before = Set(w.active.sprites.map(\.id))
        w.player.cues = []
        XCTAssertTrue(HurtPlayer.hurt(w, player: pid, attacker: aid, damage: 0x70, blood: false, invulnerable: 0x3c,
                                      coins: 0))
        // The arm (M l. 47989–48032): `073c` 0xf, snd 507 first, the item flash 0xf on slot 1 in red.
        XCTAssertEqual(w.player.countdown073c, 0xf)
        XCTAssertEqual(w.player.cues.first, reg(507))
        XCTAssertEqual([w.statusBar.flashes.item, w.statusBar.flashes.itemSlot, w.statusBar.flashes.itemMode], [0xf, 1, 1])
        // Four shards 0x4bf…0x4c2 at the centre's quadrants; per shard the Setup's R(60), vy = −0x4b0 − R(0x708),
        // vx = 0x2000 / 4 − R(300) (≥ 500: kept), negated (facing right, `+0x17e` 0).
        let shards = w.active.sprites.filter { !before.contains($0.id) }
        XCTAssertEqual(shards.map(\.type), [0x4bf, 0x4c0, 0x4c1, 0x4c2])
        XCTAssertEqual(shards.map { [$0.x, $0.y] },
                       [[c.x - 16, c.y - 16], [c.x, c.y - 16], [c.x - 16, c.y], [c.x, c.y]])
        for s in shards {
            _ = r.next(0x3c)
            XCTAssertEqual(s.vy, -0x4b0 - Int32(r.next(0x708)))
            XCTAssertEqual(s.vx, -(0x800 - Int32(r.next(300))))
            XCTAssertEqual(s.handler, .bonus)
            XCTAssertEqual(s.counterA6, -40)
        }
        // The hurt's own draws follow (snd 508's rate, then R(3)).
        XCTAssertEqual(w.player.cues[1].rate, Int32(r.next(10000)) + 65000)
        // A slow player facing left: |0 / 4 − R(300)| < 500 → 600 − R(200), not negated.
        do {
            let v = try world()
            _ = standing(v)
            stock(v, [Self.spell(0), Self.item(0x13)])
            let vid = v.playerID!
            let att = v.active.insert(a)
            v.active.update(id: vid) { $0.vx = 0; $0.mirrored = true }
            var q = v.rng
            let pre = Set(v.active.sprites.map(\.id))
            HurtPlayer.hurt(v, player: vid, attacker: att, damage: 0x70, blood: false, invulnerable: 0x3c, coins: 0)
            for s in v.active.sprites.filter({ !pre.contains($0.id) }) {
                _ = q.next(0x3c)
                _ = q.next(0x708)
                _ = q.next(300)
                XCTAssertEqual(s.vx, 600 - Int32(q.next(200)))
            }
        }
        // The |vx| < 500 test at its edge: |player vx| / 4 − R(300) = 500 is kept (negated), 499 is replaced.
        for (edge, replaced) in [(Int32(500), false), (499, true)] {
            let v = try world()
            _ = standing(v)
            stock(v, [Self.spell(0), Self.item(0x13)])
            let vid = v.playerID!
            let att = v.active.insert(a)
            var q = v.rng
            _ = q.next(0x3c)
            _ = q.next(0x708)
            let r300 = Int32(q.next(300))
            v.active.update(id: vid) { $0.vx = -4 * (edge + r300); $0.mirrored = false }
            let pre = Set(v.active.sprites.map(\.id))
            HurtPlayer.hurt(v, player: vid, attacker: att, damage: 0x70, blood: false, invulnerable: 0x3c, coins: 0)
            let first = try XCTUnwrap(v.active.sprites.first { !pre.contains($0.id) })
            XCTAssertEqual(first.vx, replaced ? -(600 - Int32(q.next(200))) : -edge, "edge \(edge)")
        }
        // Not for a Background 0x730…0x733 (the hurt lands; no arm), nor without a crystal.
        for (t, slots) in [(Int16(0x730), [Self.item(0x13)]), (0x733, [Self.item(0x13)]), (0x4b8, [Self.spell(0)])] {
            let v = try world()
            _ = standing(v)
            stock(v, slots)
            var b = SpriteSlot(type: t, x: 0, y: 0)
            b.handler = .background
            b.hp = 1
            let bid = v.active.insert(b)
            let pre = v.active.sprites.count
            v.player.cues = []
            XCTAssertTrue(HurtPlayer.hurt(v, player: v.playerID!, attacker: bid, damage: 0x70, blood: false,
                                          invulnerable: 0x3c, coins: 0), "type \(t)")
            XCTAssertEqual(v.player.countdown073c, 0, "type \(t)")
            XCTAssertEqual(v.active.sprites.count, pre, "type \(t)")
            XCTAssertFalse(v.player.cues.contains(reg(507)), "type \(t)")
        }
        // Row 13 (M l. 44743–44747): `073c` − 1 a frame; at 0 with the crystal → `.RemoveItem(0x13)` (its
        // `.UpdateItemStat`) then `.UpdateStatusBar(1, 1, 0)`; the count 2 → 1.
        w.player.passDraws = []
        for _ in 0..<14 { Player.countdowns(w, id: pid) }
        XCTAssertEqual(w.player.countdown073c, 1)
        XCTAssertEqual(w.globals.inventory[1].count, 2)
        XCTAssertTrue(w.player.passDraws.isEmpty)
        Player.countdowns(w, id: pid)
        XCTAssertEqual(w.player.countdown073c, 0)
        XCTAssertEqual(w.globals.inventory[1].id, 0x13)
        XCTAssertEqual(w.globals.inventory[1].count, 1)
        let calls = w.player.passDraws.compactMap { op -> StatusBarCall? in
            if case .statusBar(let s) = op { return s.call } else { return nil }
        }
        XCTAssertEqual(calls.map(\.itemsOnly), [true, false])
        XCTAssertEqual([calls[1].partial, calls[1].forceItems, calls[1].forceBars], [true, true, false])
        Player.countdowns(w, id: pid)
        XCTAssertEqual(w.player.passDraws.count, 2)
        XCTAssertEqual(w.globals.inventory[1].count, 1)
        // At 0 with no crystal left → nothing.
        w.globals.inventory[1] = .empty
        w.player.countdown073c = 1
        Player.countdowns(w, id: pid)
        XCTAssertEqual([Int(w.player.countdown073c), w.player.passDraws.count], [0, 2])
    }
}
