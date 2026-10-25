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
        // The 1056's own 501 at 0x55 (M l. 48647), the hundred's 451 / 445 / 501 at 0x100 (M l. 48668–48669, 48693).
        XCTAssertEqual(w.player.cues.map(\.volume), [0x100, 0x100, 0x55, 0x100, 0x100, 0x100])
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

        // The burst (M l. 48632, 48649–48661) with face pixels: `*PTR_DAT_100a0478` (set 0x421 face 0), `*_DAT_100a0474` (set
        // 0x422 face 0) once `G+0x14 > 99` — here a 1 × 1 face for 0x421, 2 rows × 4 pixels for 0x422. Effects 1 with
        // the count < 1000 → (1, 1, 1): every pixel; 2 with < 0x5dc → (2, 1, 7): every other pixel; else (2, 2, 7):
        // every other pixel of every other row. Style 0x65 draws R(60), R(60), R(16), R(12) per particle.
        func face(rows: Int, pixels: Int) -> ParticleFace {
            var t: [UInt8] = []
            for _ in 0..<rows {
                t += [1, 0, 0, 0, 2, 0, 0, UInt8(pixels)] + [UInt8](repeating: 9, count: pixels)
                t += [UInt8](repeating: 0, count: (4 - pixels % 4) % 4)
            }
            t += [0, 0, 0, 0]
            let b: [Int16] = [0, 0, Int16(rows), Int16(pixels)]
            return ParticleFace(frame: b, bounds: b, tokens: t)
        }
        let one = face(rows: 1, pixels: 1), eight = face(rows: 2, pixels: 4)
        let faces = ParticleFaces(sprite: { ref in
            guard ref.index == 0 else { return nil }
            return ref.pict == 0x421 ? one : ref.pict == 0x422 ? eight : nil
        })
        let cases: [(type: Int16, effects: Int16, count: Int16, made: Int, shape: Int16)] = [
            (0x41f, 1, 0, 1, 1), (0x420, 1, 0, 8, 1), (0x420, 1, 1000, 2, 7), (0x420, 2, 0, 4, 7),
            (0x420, 2, 0x5dc, 2, 7), (0x420, 0, 0, 2, 7), (0x420, 3, 0, 2, 7),
        ]
        for c in cases {
            let (bw, bp) = try world()
            var bl = LightTable()
            bw.particleFaces = faces
            bw.particles.counters.count = c.count
            let b = try bonus(bw, c.type, lights: &bl)
            let before = Set(bw.particles.records.indices.filter { bw.particles.records[$0].alive })
            var rr = bw.rng
            if c.type == 0x420 { _ = rr.next(10000); _ = rr.next(10000) }
            for _ in 0..<c.made { for n: Int16 in [0x3c, 0x3c, 0x10, 0xc] { _ = rr.next(n) } }
            HitPlayerSprite.hit(bw, player: bp, other: b, keys: [], lights: &bl, effects: c.effects)
            let made = bw.particles.records.indices.filter { bw.particles.records[$0].alive && !before.contains($0) }
            XCTAssertEqual(made.count, c.made, "\(c)")
            XCTAssertEqual(Set(made.map { bw.particles.records[$0].shape }), [c.shape], "\(c)")
            XCTAssertEqual(bw.rng.seed, rr.seed, "\(c)")
        }
        // The renderer loads both burst sets with the drops (FrameRenderer): 0x421 / 0x422 / 0x516 as `.InitBonusSprite`.
        for pict: Int16 in [0x421, 0x422, 0x516] {
            let sheet = try XCTUnwrap(BonusSprite.sheets.first { $0.pict == pict })
            XCTAssertTrue(BonusSprite.dropSheets.contains(sheet), "sheet \(pict)")
        }
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
        // 1291 with `+0xa4` 0x200: + 0xe0 → clamped to max health 0x230 (M l. 48735–48738).
        w.active.update(id: p) { $0.hp = 0x200 }
        touch(w, p, try bonus(w, 0x50b, lights: &lights), lights: &lights)
        XCTAssertEqual(w.active.record(id: p)?.hp, 0x230)
        // 1300 (M l. 48763–48772): snd 500 vol 0xab; score + 25; magic + 0xe0, clamped at `G+0xc`.
        w.player.cues = []
        w.globals.magic = 0x100
        var score = w.globals.score
        let c1300 = try bonus(w, 0x514, lights: &lights)
        touch(w, p, c1300, lights: &lights)
        XCTAssertEqual([Int(w.globals.magic), Int(w.globals.score - score)], [0x1e0, 25])
        XCTAssertEqual(dead(w, c1300), 1)
        w.globals.magic = 0x200
        touch(w, p, try bonus(w, 0x514, lights: &lights), lights: &lights)
        XCTAssertEqual(w.globals.magic, 0x230)
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .reg, snd: 500, priority: 1, volume: 0xab),
                                       PlayerCue(call: .reg, snd: 500, priority: 1, volume: 0xab)])
        // 1292 (M l. 48711–48718): snd 501, the 489 at R + 40000; score + 25; coins + 5.
        w.player.cues = []
        score = w.globals.score
        var coins = w.globals.coins
        let c1292 = try bonus(w, 0x50c, lights: &lights)
        var r = w.rng
        let rate = Int32(r.next(10000)) + 40000
        touch(w, p, c1292, lights: &lights)
        XCTAssertEqual([Int(w.globals.score - score), Int(w.globals.coins - coins)], [25, 5])
        XCTAssertEqual(w.player.cues.map(\.snd), [501, 489])
        XCTAssertEqual(w.player.cues.map(\.volume), [0x100, 0x100])
        XCTAssertEqual(w.player.cues.last?.rate, rate)
        XCTAssertEqual(dead(w, c1292), 1)
        // 1305 (M l. 48790–48795): coins + 10, score + 5, snd 501 vol 0xab.
        w.player.cues = []
        score = w.globals.score
        coins = w.globals.coins
        touch(w, p, try bonus(w, 0x519, lights: &lights), lights: &lights)
        XCTAssertEqual([Int(w.globals.score - score), Int(w.globals.coins - coins)], [5, 10])
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .reg, snd: 501, priority: 1, volume: 0xab)])

        // 69, the Mist body (M l. 48597–48615): the spirit timer above 0x167 → nothing; at 0x167 → timer −1,
        // `_DAT_100a0574 = 14`, `PTR_DAT_100a05a8 = 6`, snd 420, `+0xe9`, the player to the stored body (`+0xc` from
        // `04d4`, `+0xa` from `04d0`, 24.8 from them), vx = vy = 0.
        var m = SpriteSlot(type: 0x45, x: 0, y: 0)
        m.handler = .bonus
        let mist = w.active.insert(m)
        w.player.cues = []
        w.player.mistBodyX = 0x123
        w.player.mistBodyY = 0x45
        w.active.update(id: p) { $0.vx = 0x300; $0.vy = -0x200 }
        w.player.spiritTimer = 0x168
        touch(w, p, mist, lights: &lights)
        XCTAssertEqual(dead(w, mist), 0)
        XCTAssertEqual(w.player.spiritTimer, 0x168)
        XCTAssertTrue(w.player.cues.isEmpty)
        w.player.spiritTimer = 0x167
        touch(w, p, mist, lights: &lights)
        XCTAssertEqual(dead(w, mist), 1)
        XCTAssertEqual([Int(w.player.spiritTimer), Int(w.player.spiritTransition), Int(w.player.countdown05a8)],
                       [-1, 14, 6])
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .reg, snd: 420, priority: 1, volume: 0x100)])
        let pm = try XCTUnwrap(w.active.record(id: p))
        XCTAssertEqual([pm.x, pm.y], [0x123, 0x45])
        XCTAssertEqual([pm.x256, pm.y256, pm.vx, pm.vy], [0x12300, 0x4500, 0, 0])

        // 3050, the glider (M l. 48920–48936): `PTR_DAT_100a05c4 ≠ 0` → nothing; else `+0xe9`, `_DAT_100a05e0 = 1`,
        // `_DAT_100a05d4 = 1`, `PTR_DAT_100a05c8 = 0`, the player's 24.8 position the glider's, `+0xc`/`+0xa` from
        // them, face set `_DAT_100a0778` (0x41a) face 0, `SetRect(+0x34, 0x37, 0x3e, 99, 0x6e)`.
        var gl = SpriteSlot(type: 0xbea, x: 0x210, y: 0x88)
        gl.handler = .bonus
        gl.x256 = 0x210_80
        gl.y256 = 0x88_40
        let glider = w.active.insert(gl)
        w.player.countdown05c4 = 1
        w.player.glider05c8 = 7
        touch(w, p, glider, lights: &lights)
        XCTAssertEqual(dead(w, glider), 0)
        XCTAssertFalse(w.player.glider)
        XCTAssertEqual(w.player.glider05c8, 7)
        w.player.countdown05c4 = 0
        touch(w, p, glider, lights: &lights)
        XCTAssertEqual(dead(w, glider), 1)
        XCTAssertTrue(w.player.glider)
        XCTAssertEqual([w.player.gliderExit, w.player.glider05c8], [1, 0])
        let pg = try XCTUnwrap(w.active.record(id: p))
        XCTAssertEqual([pg.x256, pg.y256], [0x210_80, 0x88_40])
        XCTAssertEqual([pg.x, pg.y], [0x210, 0x88])
        XCTAssertEqual(pg.face, FaceRef(pict: 0x41a, index: 0, set: .encoded))
        XCTAssertEqual(pg.hotRect, IdleSprites.Rect(top: 0x3e, left: 0x37, bottom: 0x6e, right: 99))
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

        // One pass, one ordered list: the original draws each call to the screen as it is made, so a scroll's
        // `.UpdateStatusBar(1, 1, 0)` and a passage jump's redraws (M l. 49659–49682) reach the frame in contact
        // order — here the scroll first (list order), then the synthetic passage 2900 (records 509 / 510) at its
        // jump (`06f0` 0x15 → 0x16).
        let r = try resources()
        let ps = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1)
        for _ in 0..<30 { _ = ps.step(keys: KeyState()) }
        let pw = ps.world
        let pid = try XCTUnwrap(pw.playerID)
        let pl = try XCTUnwrap(pw.active.record(id: pid))
        var sc = SpriteSlot(type: 2005, x: pl.x, y: pl.y, recordIndex: -1)
        var sr = pw.rng
        _ = try BonusSprite.setup(&sc, x: pl.x, y: pl.y, level: ps.level, records: pw.records, effects: 2,
                                  lightCount: 0, counting: false, rng: &sr) { _, _, _, _ in -1 }
        sc.x = pl.x
        sc.y = pl.y
        sc.hotRect = pl.hotRect
        sc.layer = 0
        pw.records[509] = Placement(index: 509, flag: 1, byte1: 0, type: 2900, p1: 510, p2: 0, p3: 0, p4: 0,
                                    y: Int16(pl.y), x: Int16(pl.x))
        pw.records[510] = Placement(index: 510, flag: 1, byte1: 0, type: 2900, p1: 509, p2: 0, p3: 0, p4: 0,
                                    y: 500, x: 1600)
        var passage = try SetupFaces.setup(pw.records[509], context: SetupFaces.Context(level: pw.level, playerX: 0)).slot
        passage.recordIndex = 509
        passage.x = pl.x
        passage.y = pl.y
        passage.hotRect = pl.hotRect
        let scrollID = pw.active.insert(sc), passageID = pw.active.insert(passage)
        // The partner idle (record 510): the jump's scan finds it, so `PassageView.snap` runs.
        var partner = try SetupFaces.setup(pw.records[510], context: SetupFaces.Context(level: pw.level, playerX: 0)).slot
        partner.recordIndex = 510
        partner.x = 1600
        partner.y = 500
        XCTAssertNotNil(pw.idle.add(partner, faceRect: .noFace))
        let order = pw.active.sprites.map(\.id)
        XCTAssertLessThan(try XCTUnwrap(order.firstIndex(of: scrollID)), try XCTUnwrap(order.firstIndex(of: passageID)))
        pw.player.doorTransit = 0x15
        let ops = ps.step(keys: KeyState())
        XCTAssertEqual(pw.player.doorTransit, -0x16, "the jump ran")
        XCTAssertTrue(pw.globals.inventory.contains { $0.isSpell == 1 && $0.id == 5 }, "the scroll was taken")
        let bar = try XCTUnwrap(ops.draws.firstIndex { op in
            if case .statusBar(let b) = op { b.call.forceItems } else { false }
        })
        let redraw = try XCTUnwrap(ops.draws.firstIndex { op in
            if case .redrawEntireScrollGrid = op { true } else { false }
        })
        XCTAssertLessThan(bar, redraw, "the scroll's bar call, then the passage's redraws")
        // The one ordered list from the bar on: `PassageView.snap`'s `.RedrawEntireScrollGrid` after its 90 passes,
        // then `PassageView.redraw`'s `.WrapDrawSprites` and `.RedrawEntireScrollGrid` (l. 49672, 49676–49678).
        let grid = DrawOp.redrawEntireScrollGrid(h: ps.camera.scrollH, v: ps.camera.scrollV)
        let tail = ops.draws[bar...].filter { op in
            switch op {
            case .statusBar, .redrawEntireScrollGrid, .wrapDrawSprites: true
            default: false
            }
        }.map { op -> String in
            switch op {
            case .statusBar: "bar"
            case .wrapDrawSprites: "sprites"
            default: op == grid ? "grid" : "\(op)"
            }
        }
        XCTAssertEqual(Array(tail.prefix(4)), ["bar", "grid", "sprites", "grid"], "snap, then redraw")
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
        // 3215 first `.RemoveItem(0xe)` (the wooden shield, M l. 48983–48985), then item 0xf.
        w.globals.inventory[3] = Self.item(0xe)
        w.player.passDraws = []
        touch(w, p, try bonus(w, 0xc8f, lights: &lights), lights: &lights)
        XCTAssertFalse(w.globals.hasItem(0xe))
        XCTAssertTrue(w.globals.hasItem(0xf))
        XCTAssertEqual(w.player.passDraws.count, 2, "the removal's item stat, then the pickup's bar")

        // The spheres (M l. 49023–49121): each one's timer and flags, its sound, the hide timer `sphere+0xa6`
        // (M l. 49120) — 1335's 32000 with its record's p2 = 0, else 0x1c2; 1338's 32000; 1339's 0 (killed).
        let (sw, sp) = try world()
        var sl = LightTable()
        func sphere(_ type: Int16, record: Int16 = -1) throws -> (id: Int, hide: Int16, cues: [PlayerCue]) {
            sw.player.cues = []
            let id = try bonus(sw, type, record: record, lights: &sl)
            sw.active.update(id: id) { $0.counterA6 = 0; $0.pickupDelay = 0 }
            touch(sw, sp, id, lights: &sl)
            return (id, try XCTUnwrap(sw.active.record(id: id)).counterA6, sw.player.cues)
        }
        func reg(_ snd: Int16, _ vol: Int16 = 0x100) -> [PlayerCue] {
            [PlayerCue(call: .reg, snd: snd, priority: 1, volume: vol)]
        }
        var x = try sphere(0x532)
        XCTAssertEqual([x.hide, sw.player.shadowTimer], [600, 600])
        XCTAssertTrue(sw.player.shadowDouble)
        XCTAssertEqual(x.cues, reg(447))
        XCTAssertEqual(dead(sw, x.id), 0, "the sphere stays, hidden")
        for t: Int16 in [0x533, 0x534, 0x535] {
            sw.player.walkOnLiquidTimer = 0
            x = try sphere(t)
            XCTAssertEqual([x.hide, sw.player.walkOnLiquidTimer, sw.player.walkOnLiquidKind], [600, 600, t - 0x533])
            XCTAssertTrue(sw.player.walkOnLiquid && sw.player.tint0644)
            XCTAssertEqual(x.cues, reg(444))
        }
        x = try sphere(0x536)
        XCTAssertEqual([x.hide, sw.player.highJumpTimer], [600, 600])
        XCTAssertTrue(sw.player.highJump && sw.player.tint0634)
        XCTAssertEqual(x.cues, reg(449))
        sw.records[0] = record(0, 0x537, p2: 0)
        x = try sphere(0x537, record: 0)
        XCTAssertEqual([x.hide, sw.player.invincibleTimer, sw.active.record(id: sp)?.invulnerable], [32000, 0x1c2, 0x1c2])
        XCTAssertEqual(x.cues, reg(446))
        sw.records[0] = record(0, 0x537, p2: 1)
        sw.active.update(id: sp) { $0.invulnerable = 0 }
        x = try sphere(0x537, record: 0)
        XCTAssertEqual([x.hide, sw.active.record(id: sp)?.invulnerable], [0x1c2, 0x1c2])
        x = try sphere(0x538)
        XCTAssertEqual([x.hide, sw.player.featherFallTimer], [900, 900])
        XCTAssertTrue(sw.player.featherFall && sw.player.tint0628)
        XCTAssertEqual(x.cues, reg(445))
        x = try sphere(0x539)
        XCTAssertEqual([x.hide, sw.player.doubleSpeedTimer], [600, 600])
        XCTAssertTrue(sw.player.doubleSpeed && sw.player.tint061c)
        XCTAssertEqual(x.cues, reg(447))
        // 1338: + 5 orbs, capped at 8; orbs 0…n−1 at i·(360 / n)·256, radius 0x30, speed 0xa00, in use; the rest out of
        // use; a live orb sprite killed and dropped; `0614 = 1`; hidden 32000; snd 444.
        let old = sw.active.insert(SpriteSlot(type: 1, x: 0, y: 0))
        sw.player.orbs[6].sprite = old
        sw.player.orbs[7].active = true
        x = try sphere(0x53a)
        XCTAssertEqual([x.hide, sw.player.pentashieldCount], [32000, 5])
        XCTAssertEqual(sw.player.orbs.map(\.active), [true, true, true, true, true, false, false, false])
        XCTAssertEqual(sw.player.orbs.prefix(5).map(\.angle), [0, 72, 144, 216, 288].map { Int32($0) * 0x100 })
        XCTAssertEqual(dead(sw, old), 1)
        XCTAssertNil(sw.player.orbs[6].sprite)
        XCTAssertTrue(sw.player.flag0614)
        XCTAssertEqual(x.cues, reg(444))
        sw.player.orbs[1].radius = 0
        sw.player.orbs[1].speed = 0
        x = try sphere(0x53a)
        XCTAssertEqual(sw.player.pentashieldCount, 8, "5 + 5 capped")
        XCTAssertEqual(sw.player.orbs.map(\.active), [Bool](repeating: true, count: 8))
        XCTAssertEqual(sw.player.orbs.map(\.angle), (0..<8).map { Int32($0) * 45 * 0x100 })
        XCTAssertEqual([sw.player.orbs[1].radius, sw.player.orbs[1].speed], [0x30, 0xa00])
        // 1339: `+0xe9`, snd 450 vol 0xab, `+0xa4` − 0x380, `+0x116 = 30`, `+0xaa = 30`; hide 0.
        sw.active.update(id: sp) { $0.hp = 0x400; $0.invulnerable = 0; $0.flash = 0 }
        x = try sphere(0x53b)
        XCTAssertEqual(dead(sw, x.id), 1)
        XCTAssertEqual(x.hide, 0)
        XCTAssertEqual(x.cues, reg(450, 0xab))
        let hurt = try XCTUnwrap(sw.active.record(id: sp))
        XCTAssertEqual([hurt.hp, hurt.invulnerable, hurt.flash], [0x80, 30, 30])
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
        // A 1059 with p1 = 0 (M l. 48590–48593): no sound, still KillBonus'd.
        w.player.cues = []
        w.records[0] = record(0, 0x423, p1: 0)
        let quiet = try bonus(w, 0x423, record: 0, lights: &lights)
        touch(w, p, quiet, lights: &lights)
        XCTAssertTrue(w.player.cues.isEmpty)
        XCTAssertEqual(dead(w, quiet), 1)
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
        s.world.globals.magic = 0x100                                   // below the max: the refill fills it
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

        // The arm itself (M l. 48808–48819): snd 451 vol 0xab, score + 2000, `+0xe9`, `GammaFadeOutAsync(2, …)` toward
        // 1341's `_DAT_100a07f0` (0x5555, 0xffff, 0xffff) / 1340's `_DAT_100a07f4` (0xffff, 0x5555, 0xffff) — whose
        // `HideCursorSafe` (M l. 31905) is a `.hideCursor` request when the fade arms; fading off, neither.
        for (type, rgb) in [(Int16(0x53d), RGB16(red: 0x5555, green: 0xffff, blue: 0xffff)),
                            (Int16(0x53c), RGB16(red: 0xffff, green: 0x5555, blue: 0xffff))] {
            let (w, p) = try world()
            var lights = LightTable()
            let b = try bonus(w, type, lights: &lights)
            w.active.update(id: b) { $0.counterA6 = 0 }
            touch(w, p, b, lights: &lights)
            XCTAssertEqual(w.player.cues, [PlayerCue(call: .reg, snd: 451, priority: 1, volume: 0xab)])
            XCTAssertEqual(w.globals.score, 2000)
            XCTAssertEqual(dead(w, b), 1)
            XCTAssertEqual(w.gammaFade.toward, rgb)
            XCTAssertEqual([w.gammaFade.steps, w.gammaFade.done ? 1 : 0], [2, 0])
            XCTAssertEqual(w.suspension, .upgrade(type: type))
            XCTAssertEqual(w.player.passRequests, [.hideCursor])
            let (w2, p2) = try world()
            w2.gammaFade = AsyncGammaFade(fadedOut: false, done: true, fadingEnabled: false)
            let b2 = try bonus(w2, type, lights: &lights)
            w2.active.update(id: b2) { $0.counterA6 = 0 }
            touch(w2, p2, b2, lights: &lights)
            XCTAssertEqual(w2.suspension, .upgrade(type: type))
            XCTAssertEqual(w2.player.passRequests, [], "fading off: no fade, no cursor hide")
        }

        // A hosted session: the suspended frame hands the cursor hide out; after the loops the rest of the frame
        // reads the keys polled at the resume tick (live in the original) — Caps Lock down there → `.CheckGameLoopKeys`
        // pauses, Esc there asks the abort (`.ConfirmAbortGameDialog`). A 1340 there: the refill (breath = health = max, `G+8 = 8`), max + 0x70, health / breath + 0x70 with
        // the player's `+0xa4` = health; the bar calls are (1, 0, 1).
        for (caps, pressed) in [(true, [Int]()), (false, []), (false, [0x35])] {
            let hs = try FerazelSession(resources: r, prefs: prefs, level: 2, hostedByLevelRun: true)
            for _ in 0..<45 { XCTAssertNil(hs.step(keys: KeyState()).suspension) }
            let hw = hs.world
            let hp = try XCTUnwrap(hw.playerID)
            let hpl = try XCTUnwrap(hw.active.record(id: hp))
            var hu = SpriteSlot(type: 0x53c, x: hpl.x, y: hpl.y, recordIndex: -1)
            var hr = hw.rng
            _ = try BonusSprite.setup(&hu, x: hpl.x, y: hpl.y, level: hs.level, records: hw.records, effects: 2,
                                      lightCount: 0, counting: false, rng: &hr) { _, _, _, _ in -1 }
            hu.hotRect = hpl.hotRect
            hu.x = hpl.x
            hu.y = hpl.y
            _ = hw.active.insert(hu)
            hw.globals.maxHealth = 0x230
            hw.globals.health = 0x100
            hw.active.update(id: hp) { $0.hp = 0x100 }                 // the frame reads G+4 back from `+0xa4`
            hw.globals.breath = 0x80
            hw.globals.suffocation = 0x1e
            hw.globals.magic = 0x100
            hw.globals.maxMagic = 0x230
            var first = FrameOps()
            for _ in 0..<4 {
                first = hs.step(keys: KeyState())
                if first.suspension != nil { break }
            }
            XCTAssertEqual(first.suspension, .upgrade(type: 0x53c))
            XCTAssertEqual(hw.globals.health, 0x100, "below the max at the arm")
            XCTAssertEqual(first.requests, [.hideCursor, .hideCursor], "the iteration's (M l. 5233), the fade's")
            var anim = UpgradeAnimation(type: 0x53c)
            var now: UInt32 = 0
            var barCalls: [StatusBarCall] = []
            while !anim.isDone {
                for op in anim.tick(now: now, session: hs, keys: KeyState()).draws {
                    if case .statusBar(let b) = op { barCalls.append(b.call) }
                }
                now += 1
            }
            XCTAssertEqual(barCalls.count, 50)
            XCTAssertEqual(Set(barCalls.map { [$0.partial, $0.forceItems, $0.forceBars] }), [[true, false, true]])
            XCTAssertEqual([hw.globals.maxHealth, hw.globals.health, hw.globals.breath], [0x2a0, 0x2a0, 0x2a0])
            XCTAssertEqual(hw.globals.suffocation, 8)
            XCTAssertEqual(hw.active.record(id: hp)?.hp, 0x2a0)
            XCTAssertEqual([hw.globals.magic, hw.globals.maxMagic], [0x100, 0x230], "a 1340 leaves magic")
            let rest = hs.resume(.upgrade(keys: KeyState(pressed: pressed), capsLock: caps))
            let expected: FrameSuspension? = caps ? .gameLoopKeys(.pause)
                : pressed.isEmpty ? nil : .gameLoopKeys(.confirmAbort(escape: true))
            XCTAssertEqual(rest.suspension, expected, "Caps Lock \(caps), keys \(pressed) at the resume")
        }
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
