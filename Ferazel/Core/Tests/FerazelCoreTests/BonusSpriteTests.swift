import XCTest
@testable import FerazelCore

/// BN (docs/plans/2026-10-24-ferazel-phase4.md): the Bonus class — `.SetupBonusSprite` (M l. 52338–52804),
/// `.HandleBonusSprite` (M l. 52805–53443), `.HitBonusSprite` (M l. 53444–53536), `.KillBonus` (M l. 53537–53570),
/// `.HitBonusTileSprite` (M l. 53571–53638); pickups-boxes §1.1–§1.4, §1.9–§1.11.
final class BonusSpriteTests: XCTestCase {

    private func world(records: [Placement]? = nil) throws -> SpriteWorld {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let L = try LevelFile.load(from: r, level: 1)
        return SpriteWorld(level: L, records: records)
    }

    /// A record at `index` (flag 1) with the given type and params.
    private func record(_ index: Int, _ type: Int16, p1: Int16 = 0, p3: Int16 = 0, p4: Int16 = 0) -> Placement {
        Placement(index: index, flag: 1, byte1: 0, type: type, p1: p1, p2: 0, p3: p3, p4: p4, y: 0, x: 0)
    }

    /// `.MTNewSprite(type, x, y, …, .SetupBonusSprite)` with the world's stream; the lights go to `lights`.
    @discardableResult
    private func make(_ w: SpriteWorld, _ type: Int16, x: Int = 400, y: Int = 100, record: Int16 = -1,
                      effects: Int16 = 1, lights: inout LightTable, counting: Bool = false) throws -> Int {
        var s = SpriteSlot(type: type, x: x, y: y, recordIndex: record)
        _ = try BonusSprite.setup(&s, x: x, y: y, level: w.level, records: w.records, effects: effects,
                                  lightCount: lights.count, counting: counting, rng: &w.rng) { f, h, v, c in
            lights.add(face: f, x: Int16(h), y: Int16(v), vx: 0, vy: 0, accelY: 0, colour: c)
        }
        return w.active.insert(s)
    }

    private func handle(_ w: SpriteWorld, _ id: Int, effects: Int16 = 1, lights: inout LightTable) -> [DrawOp] {
        BonusSprite.handle(world: w, id: id, solver: TileSolver(world: w), effects: effects, lights: &lights) { _ in 0x80 }
    }

    func testSetupDrawOrder() throws {
        let w = try world()
        var lights = LightTable()
        // 0x516 (`LAB_1005e02c`): R(9) → +0x46, R(6) + 0x1c → +0x112, R(3) + 2 → +0x114, then the tail R(60) → +0x14c.
        var x = w.rng
        let coinID = try make(w, 0x516, lights: &lights)
        let coin = try XCTUnwrap(w.active.sprite(id: coinID))
        XCTAssertEqual([coin.phase, coin.slip, coin.friction], [x.next(9), x.next(6) + 0x1c, x.next(3) + 2])
        XCTAssertEqual(coin.lightTimer, Int32(x.next(0x3c)))
        XCTAssertEqual(w.rng.seed, x.seed, "four draws")
        XCTAssertEqual([coin.gravity, Int16(coin.layer)], [0x151, 1])
        XCTAssertEqual(coin.handler, .bonus)
        XCTAssertEqual(coin.hotRect, IdleSprites.Rect(top: -4, left: 2, bottom: 7, right: 8))
        XCTAssertEqual(coin.light, -1, "a coin adds no light")
        // 0x50c (money bag): its light (no draw), then −R(10) − 5 → +0x46, +0x112 = 0, +0x114 = 0x32, the tail.
        let bagID = try make(w, 0x50c, lights: &lights)
        let bag = try XCTUnwrap(w.active.sprite(id: bagID))
        XCTAssertEqual(bag.phase, -x.next(10) - 5)
        XCTAssertEqual(bag.lightTimer, Int32(x.next(0x3c)))
        XCTAssertEqual(w.rng.seed, x.seed)
        XCTAssertEqual([bag.slip, bag.friction, bag.gravity], [0, 0x32, 0x151])
        XCTAssertEqual(bag.light, 0)
        XCTAssertEqual(lights.slots[0].face, LightFaceRef(pict: 0x336, width: 0x34, height: 0x34))
        XCTAssertEqual([lights.slots[0].x, lights.slots[0].y, lights.slots[0].colour], [416, 116, 99])
        // 1290 (0x50a): p1 ≠ 0 on a valid record → gravity 0; p1 0 → 0x151. Records 0…1 rewritten for the probe.
        let w2 = try world()
        w2.records[0] = record(0, 0x50a, p1: 1)
        w2.records[1] = record(1, 0x50a)
        var l2 = LightTable()
        let hungID = try make(w2, 0x50a, record: 0, lights: &l2)
        let hung = try XCTUnwrap(w2.active.sprite(id: hungID))
        let fellID = try make(w2, 0x50a, record: 1, lights: &l2)
        let fell = try XCTUnwrap(w2.active.sprite(id: fellID))
        XCTAssertEqual([hung.gravity, fell.gravity], [0, 0x151])
        XCTAssertEqual(hung.friction, 10)
        XCTAssertGreaterThanOrEqual(hung.slip, 0x1c)
    }

    func testXichronCycle() throws {
        let w = try world()
        var lights = LightTable()
        let id = try make(w, 0x41f, lights: &lights)
        w.active.update(id: id) { s in
            s.phase = 18
            s.gravity = 0x151                              // never applied to a Xichron, whatever the field holds
        }
        XCTAssertEqual(w.active.sprite(id: id)?.phase, 18)
        var cells: [Int] = [18 >> 1]
        for _ in 0..<3 {
            handle(w, id, lights: &lights)
            cells.append(try XCTUnwrap(w.active.sprite(id: id)?.face?.index))
        }
        XCTAssertEqual(cells, [9, 9, 0, 0], "+0x46 19 → cell 9, 20 → 0, 1 → 0")
        let x = try XCTUnwrap(w.active.sprite(id: id))
        XCTAssertEqual(x.face?.pict, 0x421)
        XCTAssertEqual([x.vy, x.y256], [0, Int32(100) << 8], "no gravity step")
        XCTAssertEqual(x.hotRect, IdleSprites.Rect(top: 2, left: 2, bottom: 0x1e, right: 0x1e), "the Handle's rect")
        XCTAssertEqual(x.mode, 0)
        // 1056: `+0xb8 = 0x10001` every frame (even after another writer).
        let big = try make(w, 0x420, lights: &lights)
        for _ in 0..<3 {
            w.active.update(id: big) { $0.mode = 0 }
            handle(w, big, lights: &lights)
            XCTAssertEqual(w.active.sprite(id: big)?.mode, 0x10001)
        }
    }

    func testTorchDrawsWhileUnspent() throws {
        let w = try world()
        var lights = LightTable()
        let id = try make(w, 0x51b, lights: &lights)
        // Unspent (`+0xb0 = 1`), Effects 1, the flicker timer far from its reset: R(100) first, then two sparks of
        // R(1000) vy, R(1000) vx, R(2) shape each, then R(0x1e) (+ R(600) × 2 on a 1).
        w.active.update(id: id) { s in
            s.pickupDelay = 1
            s.lightTimer = 100
        }
        for frame in 0..<40 {
            var x = w.rng
            let before = w.particles.counters.count
            // `.NewParticle` takes the first free record from the hint.
            let first = try XCTUnwrap(w.particles.records.indices.first {
                $0 >= Int(w.particles.counters.hint) && !w.particles.records[$0].alive })
            handle(w, id, lights: &lights)
            _ = x.next(100)
            let vy = x.next(1000), vx = x.next(1000), shape = x.next(2)
            for _ in 0..<3 { _ = x.next(1) }
            let spark = x.next(0x1e) == 1
            if spark { for _ in 0..<2 { _ = x.next(1) } }
            XCTAssertEqual(w.rng.seed, x.seed, "frame \(frame): 1 + 6 + 1 (+ 2) draws")
            XCTAssertEqual(Int(w.particles.counters.count - before), spark ? 3 : 2)
            let p = w.particles.records[first]
            XCTAssertEqual([p.vx, p.vy], [Int32(vx) - 500, Int32(vy) - 500], "the first spark after the R(100)")
            XCTAssertEqual([Int(p.shape), Int(p.kind), Int(p.mode)], [Int(shape) + 1, 1, 1])
        }
        // Spent (`+0xb0 = 0`): R(100) and R(0x1e) only — 2 draws a frame (4 on a 1-in-30 spark frame), no spark.
        w.active.update(id: id) { $0.pickupDelay = 0 }
        for frame in 0..<40 {
            var x = w.rng
            let before = w.particles.counters.count
            handle(w, id, lights: &lights)
            _ = x.next(100)
            let spark = x.next(0x1e) == 1
            if spark { for _ in 0..<2 { _ = x.next(1) } }
            XCTAssertEqual(w.rng.seed, x.seed, "spent frame \(frame)")
            XCTAssertEqual(Int(w.particles.counters.count - before), spark ? 1 : 0)
        }
        // The flicker (Effects 1): 0x321 every call; at `+0x14c` 3 / 7 also 0x322; below 1 → R(15) + 5.
        w.active.update(id: id) { $0.lightTimer = 4 }
        let ops = handle(w, id, lights: &lights)
        let s = try XCTUnwrap(w.active.sprite(id: id))
        XCTAssertEqual(ops.map { op -> Int16 in if case .changeLightFace(_, let p, _, _) = op { return p } else { return 0 } },
                       [0x321, 0x322])
        XCTAssertEqual(s.lightTimer, 3)
        XCTAssertEqual(lights.slots[Int(s.light)].face?.pict, 0x322)
    }

    func testDroppedCoinLife() throws {
        let w = try world()
        var lights = LightTable()
        let id = try make(w, 0x516, lights: &lights)
        w.active.update(id: id) { s in
            s.coinLife = -240
            s.gravity = 0                                  // held in place: the life count is the probe
        }
        var frame = 0
        while w.active.sprite(id: id)?.dead == false {
            frame += 1
            w.parity = frame % 2 == 0
            w.active.update(id: id) { $0.mode = 0x1234 }
            handle(w, id, lights: &lights)
            let s = try XCTUnwrap(w.active.sprite(id: id))
            XCTAssertEqual(s.coinLife, Int32(-240 + frame))
            if s.coinLife <= -45 {
                XCTAssertEqual(s.mode, 0x1234, "frame \(frame): no blink through −45")
            } else if !s.dead {
                XCTAssertEqual(s.mode, w.parity ? 0xb0000 : 0, "frame \(frame): blink on parity frames")
                XCTAssertFalse(s.lightOverlay)
            }
            XCTAssertLessThanOrEqual(frame, 240)
        }
        XCTAssertEqual(frame, 240, "+0x16c reaches 0 → KillBonus")
        XCTAssertEqual(w.active.sprite(id: id)?.killCount, 1)
        // A coin below the level (`hdr+0xb282 · 32`) is killed at once.
        let below = Int(w.level.header.gridHeight) << 5 + 1
        let low = try make(w, 0x516, y: below, lights: &lights)
        w.active.update(id: low) { $0.gravity = 0 }
        handle(w, low, lights: &lights)
        XCTAssertEqual(w.active.sprite(id: low)?.killCount, 1)
        let edge = try make(w, 0x516, y: below - 1, lights: &lights)
        w.active.update(id: edge) { $0.gravity = 0 }
        handle(w, edge, lights: &lights)
        XCTAssertEqual(w.active.sprite(id: edge)?.killCount, 0, "y == height · 32 stays")
    }

    func testSphereHidesAndReturns() throws {
        let w = try world()
        var lights = LightTable()
        let id = try make(w, 1335, lights: &lights)
        let slot = try XCTUnwrap(w.active.sprite(id: id)?.light)
        XCTAssertNotEqual(slot, -1)
        w.active.update(id: id) { s in
            s.counterA6 = 450
            s.gravity = 0
        }
        for frame in 1...450 {
            handle(w, id, lights: &lights)
            let s = try XCTUnwrap(w.active.sprite(id: id))
            XCTAssertNil(s.face, "frame \(frame)")
            XCTAssertNil(lights.slots[Int(slot)].face, "frame \(frame): light off")
            XCTAssertEqual(s.counterA6, Int16(450 - frame))
        }
        let ops = handle(w, id, lights: &lights)
        let s = try XCTUnwrap(w.active.sprite(id: id))
        XCTAssertEqual(s.face, FaceRef(pict: 1335, index: 0, set: .encoded), "visible on the 451st")
        XCTAssertNotNil(lights.slots[Int(slot)].face)
        XCTAssertEqual(ops.count, 1)
        XCTAssertFalse(s.lightOverlay)
    }

    func testRestsOnBoxes() throws {
        let w = try world()
        var lights = LightTable()
        var crate = SpriteSlot(type: 0xc12, x: 100, y: 200)
        crate.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x20, right: 0x20)
        XCTAssertEqual(crate.handler, .box)
        let crateID = w.active.insert(crate)
        var chest = crate
        chest.type = 0x51c
        let chestID = w.active.insert(chest)
        /// A coin-sized bonus 2 px into the top at `vy`; returns it after `.HitBonusSprite(bonus, solid)`.
        func drop(_ type: Int16, vy: Int32, onto solid: Int) throws -> SpriteSlot {
            let id = try make(w, type, x: 110, y: 195, lights: &lights)
            w.active.update(id: id) { s in
                s.hotRect = IdleSprites.Rect(top: -4, left: 2, bottom: 7, right: 8)
                s.vy = vy
            }
            BonusSprite.hit(w, id: id, other: solid)
            return try XCTUnwrap(w.active.sprite(id: id))
        }
        // vy 0x200 ≥ 0x180: `.PlatformBounce(…, 0x80, rect, 1)` — bounced up at half speed, not landed.
        let fast = try drop(0x516, vy: 0x200, onto: crateID)
        XCTAssertEqual(fast.vy, -0x100)
        XCTAssertNil(fast.ridden)
        // vy 0x100 < 0x180: factor 0, last 0 — landed: vy 0, riding the crate, on its top.
        let slow = try drop(0x516, vy: 0x100, onto: crateID)
        XCTAssertEqual(slow.vy, 0)
        XCTAssertEqual(slow.ridden, crateID)
        XCTAssertEqual(slow.y, 200 - 7)
        // A chest 0x51c → no bounce; a scroll 2000 → no bounce.
        XCTAssertEqual(try drop(0x516, vy: 0x200, onto: chestID).vy, 0x200)
        XCTAssertEqual(try drop(2000, vy: 0x200, onto: crateID).vy, 0x200)
        // Not a Platform or Box Handle (the player's) → nothing; a shard 0x4bf returns at once.
        var player = crate
        player.handler = .player
        let playerID = w.active.insert(player)
        XCTAssertEqual(try drop(0x516, vy: 0x200, onto: playerID).vy, 0x200)
        XCTAssertEqual(try drop(0x4bf, vy: 0x200, onto: crateID).vy, 0x200)
    }

    func testTileBounceFactors() throws {
        let w = try world()
        var lights = LightTable()
        let solver = TileSolver(world: w)
        let cell = TilePos(x: 96, y: 192)
        /// A bonus of `type` falling at `vy` into the lower half of `cell`, after `.HitBonusTileSprite(…, kind, FG)`.
        func fall(_ type: Int16, vy: Int32, kind: Int) throws -> (before: SpriteSlot, after: SpriteSlot) {
            let id = try make(w, type, x: 100, y: 100, lights: &lights)
            w.active.update(id: id) { s in
                let y = 192 + 23 - s.hotRect.bottom
                s.y = y
                s.y256 = Int32(y) << 8
                s.vy = vy
            }
            let before = try XCTUnwrap(w.active.sprite(id: id))
            BonusSprite.hitTile(solver, id: id, pos: cell, kind: kind, layer: .foreground)
            return (before, try XCTUnwrap(w.active.sprite(id: id)))
        }
        // Kind 3 (a floor) with bounce 1: vy = −(vy · f) >> 8.
        XCTAssertEqual(try fall(0x50c, vy: 0x400, kind: 3).after.vy, -(0x400 * 0x40) >> 8, "money bag 0x40")
        XCTAssertEqual(try fall(0x4bf, vy: 0x400, kind: 3).after.vy, -(0x400 * 0xe0) >> 8, "shard 0xe0")
        XCTAssertEqual(try fall(0x516, vy: 0x400, kind: 3).after.vy, -(0x400 * 0x80) >> 8, "coin 0x80")
        XCTAssertEqual(try fall(0x4c2, vy: 0x400, kind: 3).after.vy, -(0x400 * 0x80) >> 8, "0x4c2 is not < 0x4c2")
        // FG kind 0x67 (one-way, base 3) is passed while rising: no `.WallBounce` (y not snapped); kind 3 snaps.
        let up = try fall(0x516, vy: -0x400, kind: 0x67)
        XCTAssertEqual([up.after.y, Int(up.after.vy)], [up.before.y, -0x400])
        let down = try fall(0x516, vy: 0x400, kind: 0x67)
        XCTAssertEqual(down.after.vy, -0x200, "falling, 0x67 bounces as its base kind 3")
        let solid = try fall(0x516, vy: -0x400, kind: 3)
        XCTAssertEqual(solid.after.y, 0xd0 - 7, "kind 3 snaps y to the cell's middle line even while rising")
        // The money bag's landing sound: |vy| > 0x100 after the bounce → `.STPlay3DSoundRand(489, 1, 0x55, centre)`.
        _ = w.player.drainFrameOutputs()
        _ = try fall(0x50c, vy: 0x800, kind: 3)
        XCTAssertEqual(w.player.drainFrameOutputs().cues.map { [Int($0.snd), Int($0.volume)] }, [[489, 0x55]])
        _ = try fall(0x50c, vy: 0x400, kind: 3)
        XCTAssertEqual(w.player.drainFrameOutputs().cues.count, 0, "|−0x100| is not > 0x100")
        // Layer 2 (a crunch nibble) clears `+0x118`.
        let id = try make(w, 0x516, lights: &lights)
        w.active.update(id: id) { $0.waterGate = 7 }
        BonusSprite.hitTile(solver, id: id, pos: cell, kind: 1, layer: .crunch)
        XCTAssertEqual(w.active.sprite(id: id)?.waterGate, 0)
    }

    func testKillBonusCounts() throws {
        let w = try world()
        w.levelIndex = 2
        w.pendingTallies = SetupFaces.Tallies(secrets: 4, xichrons: 9, enemies: 0)
        var lights = LightTable()
        let x = try make(w, 1055, lights: &lights, counting: true)
        let slot = try XCTUnwrap(w.active.sprite(id: x)?.light)
        XCTAssertNotEqual(slot, -1)
        XCTAssertTrue(try XCTUnwrap(w.active.sprite(id: x)).countedInTotals)
        BonusSprite.kill(w, id: x, lights: &lights)
        XCTAssertEqual(w.globals.achieved[1][2], 1, "G+0x3ce+4 + 1")
        XCTAssertEqual(w.pendingTallies.xichrons, 8)
        XCTAssertEqual(w.active.sprite(id: x)?.killCount, 1)
        XCTAssertEqual(w.active.sprite(id: x)?.light, -1)
        XCTAssertTrue(lights.slots[Int(slot)].removing, "the light slot freed")
        BonusSprite.kill(w, id: x, lights: &lights)
        XCTAssertEqual([w.globals.achieved[1][2], w.pendingTallies.xichrons], [1, 8], "dying: nothing counted")
        // 1059 (0x423): secrets.
        let secret = try make(w, 0x423, lights: &lights, counting: true)
        BonusSprite.kill(w, id: secret, lights: &lights)
        XCTAssertEqual([w.globals.achieved[2][2], w.pendingTallies.secrets], [1, 3], "G+0x496+4 + 1")
        // Not counted (spawned outside `.SetupLevelSprites`): nothing moves.
        let dropped = try make(w, 1055, lights: &lights, counting: false)
        BonusSprite.kill(w, id: dropped, lights: &lights)
        XCTAssertEqual([w.globals.achieved[1][2], w.pendingTallies.xichrons], [1, 8])
        XCTAssertEqual(w.globals.achieved[1][1], 0)
    }
}
