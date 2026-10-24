import XCTest
@testable import FerazelCore

/// PK (docs/plans/2026-10-24-ferazel-phase4.md): the Bonus arm of `.HitPlayerSprite` (M l. 48571–49123), the upgrade
/// animation (M l. 48808–48918, BC35) and `.HurtPlayer`'s lost coins (M l. 48088–48104, BC46); pickups-boxes §1.2,
/// §1.3, §1.6–§1.9, spells-items §3, pickups-boxes-2 §1.3. Against the committed `Resources/Ferazel` (D26).
final class PickupTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    private static func spell(_ id: Int16) -> InventorySlot {
        InventorySlot(id: id, count: 1, field4: -1, field6: 0, isSpell: 1)
    }

    private static func item(_ id: Int16, _ count: Int16 = 1) -> InventorySlot {
        InventorySlot(id: id, count: count, field4: -1, field6: 0, isSpell: 0)
    }

    /// A level's world with the player at (400, 100), the new game's inventory [spell 0, item 0] and maxima 0x230.
    private func world(level: Int = 1) throws -> (w: SpriteWorld, player: Int) {
        let L = try LevelFile.load(from: try resources(), level: Int16(level))
        let w = SpriteWorld(level: L)
        w.globals.inventory = [InventorySlot](repeating: .empty, count: GameGlobals.inventorySlots)
        w.globals.inventory[0] = Self.spell(0)
        w.globals.inventory[1] = Self.item(0)
        w.globals.maxHealth = 0x230
        w.globals.maxMagic = 0x230
        w.globals.health = 0x230
        w.globals.magic = 0x230
        w.globals.breath = 0x230
        let p = try XCTUnwrap(Player.spawn(world: w, x: 400, y: 100))
        return (w, p)
    }

    /// `.MTNewSprite(type, x, y, …, .SetupBonusSprite)` on the world's stream (lights into `lights`).
    @discardableResult
    private func bonus(_ w: SpriteWorld, _ type: Int16, record: Int16 = -1, lights: inout LightTable) throws -> Int {
        var s = SpriteSlot(type: type, x: 400, y: 100, recordIndex: record)
        _ = try BonusSprite.setup(&s, x: 400, y: 100, level: w.level, records: w.records, effects: 1,
                                  lightCount: lights.count, counting: false, rng: &w.rng) { f, h, v, c in
            lights.add(face: f, x: Int16(h), y: Int16(v), vx: 0, vy: 0, accelY: 0, colour: c)
        }
        return w.active.insert(s)
    }

    private func touch(_ w: SpriteWorld, _ p: Int, _ b: Int, lights: inout LightTable) {
        HitPlayerSprite.hit(w, player: p, other: b, keys: [], lights: &lights, effects: 1)
    }

    private func dead(_ w: SpriteWorld, _ id: Int) -> UInt8 { w.active.record(id: id)?.killCount ?? 0xff }

    private func record(_ i: Int, _ type: Int16, p1: Int16 = 0, p2: Int16 = 0) -> Placement {
        Placement(index: i, flag: 1, byte1: 0, type: type, p1: p1, p2: p2, p3: 0, p4: 0, y: 0, x: 0)
    }

    func testPickupGate() throws {
        let (w, p) = try world()
        var lights = LightTable()
        // `+0xb0 = 12` (a dropped coin's delay) → no pickup.
        let c = try bonus(w, 0x516, lights: &lights)
        w.active.update(id: c) { $0.pickupDelay = 12 }
        touch(w, p, c, lights: &lights)
        XCTAssertEqual([w.globals.coins, Int16(dead(w, c))], [0, 0])
        // `+0xa6 = 3` (a hidden sphere / a counting Bonus) → none.
        w.active.update(id: c) { $0.pickupDelay = 0; $0.counterA6 = 3 }
        touch(w, p, c, lights: &lights)
        XCTAssertEqual([w.globals.coins, Int16(dead(w, c))], [0, 0])
        // Dying (`_DAT_100a069c > 0`) → none.
        w.active.update(id: c) { $0.counterA6 = 0 }
        w.player.dying = 1
        touch(w, p, c, lights: &lights)
        XCTAssertEqual([w.globals.coins, Int16(dead(w, c))], [0, 0])
        XCTAssertTrue(w.player.cues.isEmpty)
        // In spirit form a Bonus still reaches its arm (M l. 48568): coins + 1, score + 5, snd 501 vol 0xab, `+0xe9`.
        w.player.dying = 0
        w.player.spiritTimer = 100
        touch(w, p, c, lights: &lights)
        XCTAssertEqual([w.globals.coins, Int16(dead(w, c))], [1, 1])
        XCTAssertEqual(w.globals.score, 5)
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .reg, snd: 501, priority: 1, volume: 0xab)])
        // A Bonus that takes no arm (the shard 0x4bf, M l. 48740) does nothing.
        let shard = try bonus(w, 0x4bf, lights: &lights)
        w.active.update(id: shard) { $0.counterA6 = 0 }
        touch(w, p, shard, lights: &lights)
        XCTAssertEqual(dead(w, shard), 0)
    }

    func testXichronHundred() throws {
        let (w, p) = try world()
        var lights = LightTable()
        w.globals.xichrons = 99
        let x = try bonus(w, 0x41f, lights: &lights)
        touch(w, p, x, lights: &lights)
        // 99 + 1 → the hundred: `G+0x14 = 0` (raw `10055ac4..acc`), the Red Xichron 0x16 in the first empty slot.
        XCTAssertEqual(w.globals.xichrons, 0)
        XCTAssertEqual(w.globals.score, 10)
        XCTAssertEqual(w.globals.inventory[2], InventorySlot(id: 0x16, count: 1, field4: -1, field6: 0, isSpell: 0))
        XCTAssertEqual(w.player.cues.map { [$0.snd, $0.volume] }, [[501, 0x55], [451, 0x100], [445, 0x100], [501, 0x100]])
        XCTAssertEqual(dead(w, x), 1)
        XCTAssertEqual(w.statusBar.flashes.item, 0, "the Red Xichron sets no item flash")
        // One `.UpdateStatusBar(1, 1, 0)`, made in the pass.
        guard case .statusBar(let bar)? = w.player.passDraws.first else { return XCTFail("no status bar op") }
        XCTAssertEqual(w.player.passDraws.count, 1)
        XCTAssertEqual([bar.call.partial, bar.call.forceItems, bar.call.forceBars], [true, true, false])
        // A 1056 at 99 → 0 (the excess is lost); score + 1000; the two pitched 489s draw their rates first.
        w.player.cues = []
        w.globals.xichrons = 99
        let big = try bonus(w, 0x420, lights: &lights)
        var r = w.rng
        let r1 = Int32(r.next(10000)) + 40000, r2 = Int32(r.next(10000)) + 30000
        touch(w, p, big, lights: &lights)
        XCTAssertEqual(w.rng.seed, r.seed, "two draws (no particle faces in this world)")
        XCTAssertEqual(w.globals.xichrons, 0)
        XCTAssertEqual(w.globals.score, 1010)
        XCTAssertEqual(w.globals.inventory[2].count, 2, "the slot already holding 0x16")
        XCTAssertEqual(w.player.cues.map(\.snd), [489, 489, 501, 451, 445, 501])
        XCTAssertEqual(w.player.cues.prefix(2).map(\.rate), [r1, r2])
        XCTAssertEqual(w.player.cues[0].call, .threeDPitched)
        // Below the hundred: no item, no second sound pair; the light slot freed (KillBonus).
        w.player.cues = []
        let small = try bonus(w, 0x41f, lights: &lights)
        let slot = try XCTUnwrap(w.active.record(id: small)).light
        XCTAssertTrue(lights.slots[Int(slot)].active)
        touch(w, p, small, lights: &lights)
        XCTAssertEqual(w.globals.xichrons, 1)
        XCTAssertEqual(w.player.cues.map(\.snd), [501])
        XCTAssertTrue(lights.slots[Int(slot)].removing)
    }

    func testCrystalsMoneyCoins() throws {
        let (w, p) = try world()
        var lights = LightTable()
        // 1290: magic 0x200 of 0x230 + 0x2a0 → clamped 0x230; score + 100; snd 500.
        w.globals.magic = 0x200
        touch(w, p, try bonus(w, 0x50a, lights: &lights), lights: &lights)
        XCTAssertEqual(w.globals.magic, 0x230)
        XCTAssertEqual(w.globals.score, 100)
        // 1291: health and breath + 0x2a0 clamped to max health; the sprite's `+0xa4` + 0xe0 (0x100 → 0x1e0).
        w.globals.health = 0x100
        w.globals.breath = 0x80
        w.active.update(id: p) { $0.hp = 0x100 }
        touch(w, p, try bonus(w, 0x50b, lights: &lights), lights: &lights)
        XCTAssertEqual([w.globals.health, w.globals.breath], [0x230, 0x230])
        XCTAssertEqual(w.active.record(id: p)?.hp, 0x1e0)
        XCTAssertEqual(w.globals.score, 200)
        // 1293: coins + 25, score + 100 (snd 501, two pitched 489s).
        touch(w, p, try bonus(w, 0x50d, lights: &lights), lights: &lights)
        XCTAssertEqual([Int(w.globals.coins), Int(w.globals.score)], [25, 300])
        // 1306: coins + 100, score + 5.
        touch(w, p, try bonus(w, 0x51a, lights: &lights), lights: &lights)
        XCTAssertEqual([Int(w.globals.coins), Int(w.globals.score)], [125, 305])
        XCTAssertEqual(w.player.cues.map(\.snd), [500, 502, 501, 489, 489, 501])
        // 1301: `+0xa4` + 0xe0 (clamped), breath + 0xe0, `G+8 = 30`, then health = `+0xa4`.
        w.globals.breath = 0x10
        w.active.update(id: p) { $0.hp = 0x200 }
        touch(w, p, try bonus(w, 0x515, lights: &lights), lights: &lights)
        XCTAssertEqual([w.globals.breath, w.globals.suffocation, w.globals.health], [0xf0, 0x1e, 0x230])
        XCTAssertEqual(w.active.record(id: p)?.hp, 0x230)
        // 1350: breath + 0x230, ≤ health.
        w.globals.health = 0x180
        touch(w, p, try bonus(w, 0x546, lights: &lights), lights: &lights)
        XCTAssertEqual(w.globals.breath, 0x180)
        XCTAssertEqual(w.player.cues.suffix(2).map(\.snd), [502, 456])
    }

    func testScrollLearns() throws {
        let (w, p) = try world()
        var lights = LightTable()
        w.records[0] = record(0, 2000, p1: 2)
        let s1 = try bonus(w, 2000, record: 0, lights: &lights)
        touch(w, p, s1, lights: &lights)
        // Spell 2 → slot 2 (the first empty), remapped to 3, flag 1, count left at the empty slot's 0.
        XCTAssertEqual(w.globals.inventory[2], InventorySlot(id: 3, count: 0, field4: -1, field6: 0, isSpell: 1))
        XCTAssertEqual([w.statusBar.flashes.item, w.statusBar.flashes.itemSlot, w.statusBar.flashes.itemMode],
                       [0x20, 2, 0])
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .reg, snd: 503, priority: 1, volume: 0x100)])
        XCTAssertEqual(dead(w, s1), 1)
        XCTAssertEqual(w.player.passDraws.count, 1)
        // A second 2-scroll: the search compares the unmapped 2 with the slot's 3 (BC48) → the next empty slot.
        let s2 = try bonus(w, 2000, record: 0, lights: &lights)
        touch(w, p, s2, lights: &lights)
        XCTAssertEqual(w.globals.inventory[3].id, 3)
        XCTAssertEqual(w.statusBar.flashes.itemSlot, 3)
        // 2005 (type − 2000) into the next.
        touch(w, p, try bonus(w, 2005, lights: &lights), lights: &lights)
        XCTAssertEqual(w.globals.inventory[4], InventorySlot(id: 5, count: 0, field4: -1, field6: 0, isSpell: 1))
        // No empty or matching slot: the arm returns at once — no sound, the scroll not killed (M l. 48956–48962).
        for k in 5..<GameGlobals.inventorySlots { w.globals.inventory[k] = Self.item(Int16(k)) }
        w.player.cues = []
        let s3 = try bonus(w, 2006, lights: &lights)
        touch(w, p, s3, lights: &lights)
        XCTAssertTrue(w.player.cues.isEmpty)
        XCTAssertEqual(dead(w, s3), 0)
    }

    func testItemsStack() throws {
        let (w, p) = try world()
        var lights = LightTable()
        // 3206 (fire seeds) → item 6 count 3 in slot 2; snd 506; the item flash on slot 2.
        touch(w, p, try bonus(w, 0xc86, lights: &lights), lights: &lights)
        XCTAssertEqual(w.globals.inventory[2], Self.item(6, 3))
        XCTAssertEqual(w.player.cues.map(\.snd), [506])
        XCTAssertEqual([w.statusBar.flashes.item, w.statusBar.flashes.itemSlot], [0x20, 2])
        // 33 more → 3 + 99 → capped 99.
        for _ in 0..<33 { touch(w, p, try bonus(w, 0xc86, lights: &lights), lights: &lights) }
        XCTAssertEqual(w.globals.inventory[2].count, 99)
        // 3221 with one dagger: `.RemoveItem(0)` (slot 1 emptied, the seeds move down; its `.UpdateItemStat`), then
        // item 0x15 into the first empty slot (2), the flash there.
        w.player.passDraws = []
        touch(w, p, try bonus(w, 0xc95, lights: &lights), lights: &lights)
        XCTAssertEqual(Array(w.globals.inventory[0...2]), [Self.spell(0), Self.item(6, 99), Self.item(0x15)])
        XCTAssertFalse(w.globals.hasItem(0))
        XCTAssertEqual(w.statusBar.flashes.itemSlot, 2)
        let calls = w.player.passDraws.compactMap { op -> StatusBarCall? in
            if case .statusBar(let s) = op { s.call } else { nil }
        }
        XCTAssertEqual(calls.map(\.itemsOnly), [true, false], "the removal's item stat, then the pickup's (1, 1, 0)")
    }

    func testWorldFlagTrigger() throws {
        let (w, p) = try world(level: 2)
        var lights = LightTable()
        // Level 2 record 228: the 1058 trigger, p1 1, p2 0.
        let r = w.records[228]
        XCTAssertEqual([r.type, r.p1, r.p2], [0x422, 1, 0])
        let t = try bonus(w, 0x422, record: 228, lights: &lights)
        touch(w, p, t, lights: &lights)
        XCTAssertEqual(w.globals.worldFlags[1], 1, "`G+0xad8 + 2·p1` = 1 (p2 0)")
        XCTAssertEqual(dead(w, t), 1)
        XCTAssertTrue(w.player.cues.isEmpty)
        // Saved in G (the G image's `+0xad8 + 2`).
        let image = w.globals.image()
        XCTAssertEqual([image[0xad8 + 2], image[0xad8 + 3]], [0, 1])
        // p2 ≠ 0 stores p2; the 1059 secret trigger with p1 ≠ 0 plays snd 505.
        w.records[228] = record(228, 0x422, p1: 3, p2: 7)
        touch(w, p, try bonus(w, 0x422, record: 228, lights: &lights), lights: &lights)
        XCTAssertEqual(w.globals.worldFlags[3], 7)
        w.records[0] = record(0, 0x423, p1: 1)
        touch(w, p, try bonus(w, 0x423, record: 0, lights: &lights), lights: &lights)
        XCTAssertEqual(w.player.cues.map(\.snd), [505])
    }

    /// The renderer side of a `LevelRun` (Core: the session's default face bounds).
    private final class Stub: LevelServices {
        func prepare(level: Int) throws -> LevelFaces { LevelFaces() }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {}
        func deathEffectStep(_ k: Int) throws {}
    }

    func testUpgradeRuns120Ticks() throws {
        let r = try resources()
        let prefs = FerazelPrefs()
        let run = try LevelRun(resources: r, prefs: prefs, level: 2, seed: 1, carry: LevelCarry(), save: SaveBlock(),
                               fade: ScreenFade(), music: MusicFade(), services: Stub(),
                               sounds: StageSounds(prefs: prefs, lengths: [800: 30, 801: 40, 802: 50, 803: 5, 804: 7, 805: 20]))
        var t: UInt32 = 0
        while run.iterations < 45 && t < 4000 {
            _ = try run.tick(now: t, input: FrontInput())
            t += 1
        }
        let s = try XCTUnwrap(run.session)
        let pid = try XCTUnwrap(s.world.playerID)
        let pl = try XCTUnwrap(s.world.active.record(id: pid))
        s.world.globals.magic = 0x230
        s.world.globals.maxMagic = 0x230
        let score = s.world.globals.score
        // A 1341 under the player (its Setup as `.SetupLevelSprites` makes it).
        var u = SpriteSlot(type: 0x53d, x: pl.x, y: pl.y + 0x30, recordIndex: -1)
        var rng = s.world.rng
        _ = try BonusSprite.setup(&u, x: pl.x, y: pl.y + 0x30, level: s.level, records: s.world.records, effects: 2,
                                  lightCount: 0, counting: false, rng: &rng) { _, _, _, _ in -1 }
        u.hotRect = pl.hotRect
        u.x = pl.x
        u.y = pl.y
        _ = s.world.active.insert(u)
        // Tick until the arm suspends the frame.
        var armed: UInt32?
        var firstBar: UInt32?
        var firstGamma: UInt32?
        var end: UInt32?
        var bars = 0
        while t < 4000, end == nil {
            let out = try run.tick(now: t, input: FrontInput())
            if armed == nil, run.lastSteps.contains(where: { $0.suspension == .upgrade(type: 0x53d) }) { armed = t }
            if let a = armed, t > a || run.upgrade == nil {
                let n = out.merged.draws.filter { op in
                    if case .statusBar(let b) = op { b.call.forceBars } else { false }
                }.count
                if n > 0, firstBar == nil { firstBar = t }
                bars += n
                if firstGamma == nil, out.merged.draws.contains(where: { if case .gammaStep = $0 { true } else { false } }),
                   t > a { firstGamma = t }
                if run.upgrade == nil, run.lastSteps.contains(where: { $0.suspension == nil }) { end = t }
            }
            t += 1
        }
        let a = try XCTUnwrap(armed)
        XCTAssertEqual(firstGamma, a + 2, "the first wait (2 ticks) precedes the first fade step")
        XCTAssertEqual(firstBar, a + 20, "after 10 + 10 ticks")
        XCTAssertEqual(end, a + 120, "120 ticks (BC35), then the frame's rest")
        XCTAssertEqual(bars, 50, "11 + 14 + 14 + 11 bar calls (1, 0, 1)")
        XCTAssertEqual([s.world.globals.maxMagic, s.world.globals.magic], [0x2a0, 0x2a0])
        XCTAssertEqual(s.world.globals.score, score + 2000)
        XCTAssertEqual(s.world.statusBar.flashes.magic, 0)
        XCTAssertNil(run.upgrade)
        XCTAssertNil(s.suspension)
    }

    func testHurtCoinsSpawned() throws {
        let (w, p) = try world()
        var lights = LightTable()
        let attacker = try bonus(w, 0x516, lights: &lights)
        w.active.update(id: attacker) { $0.hp = 1 }
        w.globals.coins = 3
        w.active.update(id: p) { $0.hp = 0x230 }
        let before = Set(w.active.sprites.map(\.id))
        // The draws: the 508 rate, the sound pick R(3), n = R(3) + 5 − 1 (capped at the 3 held), the 489 rate, then
        // per coin R(8) dy, R(8) dx, the Setup's R(9) R(6) R(3) R(60), R(0x640), R(100), R(0xdac).
        var r = w.rng
        _ = r.next(10000)
        _ = r.next(3)
        _ = r.next(3)
        _ = r.soundRate()
        let centre = try XCTUnwrap(w.active.record(id: p)).centre
        var expected: [(x: Int, y: Int, vx: Int32, vy: Int32)] = []
        for _ in 0..<3 {
            let dy = Int(r.next(8)), dx = Int(r.next(8))
            for n: Int16 in [9, 6, 3, 0x3c] { _ = r.next(n) }
            let vx = Int32(r.next(0x640)) + 600, sign = r.next(100), vy = -2000 - Int32(r.next(0xdac))
            expected.append((centre.x + dx - 8, centre.y + dy - 2, 0x31 < sign ? -vx : vx, vy))
        }
        XCTAssertTrue(HurtPlayer.hurt(w, player: p, attacker: attacker, damage: 0x70, blood: false, invulnerable: 0x3c,
                                      coins: 5))
        XCTAssertEqual(w.rng.seed, r.seed, "nine draws per coin")
        XCTAssertEqual(w.globals.coins, 0)
        let coins = w.active.sprites.filter { !before.contains($0.id) }
        XCTAssertEqual(coins.count, 3)
        for (c, e) in zip(coins, expected) {
            XCTAssertEqual(c.type, 0x516)
            // `.MTNewSprite`'s 0x14 is overwritten by the Setup's `+0x80 = 1` (M l. 52383) before the insert.
            XCTAssertEqual(c.layer, 1)
            XCTAssertEqual(c.handler, .bonus)
            XCTAssertEqual([Int(c.pickupDelay), Int(c.coinLife)], [12, -240])
            XCTAssertEqual([c.x, c.y], [e.x, e.y])
            XCTAssertEqual([c.vx, c.vy], [e.vx, e.vy])
        }
        // With 700 records in use `.MTNewSprite` makes nothing and runs no Setup: five draws per coin.
        let (w2, p2) = try world()
        var l2 = LightTable()
        let a2 = try bonus(w2, 0x516, lights: &l2)
        w2.active.update(id: a2) { $0.hp = 1 }
        while w2.active.sprites.count < SpriteWorld.recordCount {
            _ = w2.active.insert(SpriteSlot(type: 1, x: 0, y: 0, recordIndex: -1))
        }
        w2.globals.coins = 3
        w2.active.update(id: p2) { $0.hp = 0x230 }
        var r2 = w2.rng
        _ = r2.next(10000)
        _ = r2.next(3)
        _ = r2.next(3)
        _ = r2.soundRate()
        for _ in 0..<3 { for n: Int16 in [8, 8, 0x640, 100, 0xdac] { _ = r2.next(n) } }
        HurtPlayer.hurt(w2, player: p2, attacker: a2, damage: 0x70, blood: false, invulnerable: 0x3c, coins: 5)
        XCTAssertEqual(w2.rng.seed, r2.seed, "five draws per coin (BC46)")
        XCTAssertEqual(w2.active.sprites.count, SpriteWorld.recordCount)
        XCTAssertFalse(w2.active.sprites.contains { $0.type == 0x516 && $0.pickupDelay == 12 })
    }
}
