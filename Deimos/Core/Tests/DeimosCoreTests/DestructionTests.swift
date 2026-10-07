import XCTest
import HectorResources
@testable import DeimosCore

/// Combat II (plan C11b): destruction `FUN_10016300` with the random-bonus ladder, the media gate `FUN_10016880` /
/// `FUN_1000fee0`, the deletion sweep `FUN_10036610` with `FUN_10036120` (coins, group kill) and the wreck stamp
/// into `GameState.tickOps` (damage-health-death.md §4, scoring-bonuses.md §7, spawn-and-waves.md §5,
/// sprite-geometry-draw.md §3.2). Shipped units only.
final class DestructionTests: XCTestCase {
    /// A level-1 world (`le07`, sector 1, map 480 × 3600) with P1 set up, level-started and respawned at time 100.
    private func world(seed: UInt32 = 0x469c2) throws -> GameState {
        let a = try TestAssets.loaded.get()
        var s = GameState(assets: a, prefs: DeimosPrefs.fresh, seed: seed)
        s.flags.numPlayers = 1
        s.flags.sector = 1
        s.flags.level = FourCC("le07")!
        s.scroll.levelStart(rect: MacRect(top: 0, left: 0, bottom: 3600, right: 480))
        try s.setupPlayer(0)
        try s.setupPlayer(1)
        s.playerLevelStart(0)
        s.playerLevelStart(1)
        s.flags.gameTime = 100
        s.respawnPlayer(0, now: 100)
        return s
    }

    /// One shipped unit spawned through `FUN_10033220` at (x, y) — all members it created, the first first.
    @discardableResult
    private func put(_ s: inout GameState, _ id: String, x: Float, y: Float, player: Int8 = -1) throws -> [Int] {
        var req = SpawnRequest(unit: FourCC(id)!, x: x, y: y)
        req.player = player
        let before = Set(s.world.groups.flatMap(\.members))
        let r = try XCTUnwrap(s.spawn(req), id)
        let made = s.world.groups.flatMap(\.members).filter { !before.contains($0) }
        XCTAssertEqual(made.first, r.entity)
        for m in made {
            s.world.entities[m].object.x = x
            s.world.entities[m].object.y = y
            s.world.entities[m].spawnCountdown = 0
        }
        return made
    }

    /// Live (in the pool, not flagged) entities of unit `id`.
    private func count(_ s: GameState, _ id: String) -> Int {
        let units = s.assets.definitions.units
        return s.world.entities.indices.filter {
            s.world.inUse[$0] && !s.world.entities[$0].deleted && units[s.world.entities[$0].unit].id == FourCC(id)!
        }.count
    }

    /// The §4.1 order. `bsgr` (Bonus Station, ground): glow off → particles → media gate (land) → spawn `bsdt` →
    /// sound → flags → accuracy count → the bonus draw last. `plla` (Platform, ground): the obstacle after the glow
    /// and before the particles, no bonus. No shipped unit has a destruct notice (so the notice step is never taken).
    func testDestroyOrder() throws {
        var s = try world()
        XCTAssertTrue(s.assets.definitions.units.allSatisfy { $0.destructNotice.isEmpty || $0.destructNotice == "none" })
        let b = try put(&s, "bsgr", x: 200, y: 300)[0]
        s.world.entities[b].object.hitGlowOn = true
        let created = s.flags.groundDestroyed
        var steps: [DestroyStep] = []
        s.destroyEntity(b, killer: 0, now: 100) { steps.append($0) }
        XCTAssertEqual(steps.count, 8)
        guard steps.count == 8 else { return }
        XCTAssertEqual(Array(steps.prefix(7)), [.glowOff, .particles(FourCC("med ")!), .mediaGate(allowed: true),
                                                .spawn(FourCC("bsdt")!), .sound(FourCC("shat")!), .flags,
                                                .accuracyCount])
        guard case let .randomBonus(r, object) = steps[7] else { return XCTFail("bonus last: \(steps[7])") }
        XCTAssertTrue((0...100).contains(r))
        var t = try world()
        XCTAssertEqual(object, t.randomBonusObject(r))
        XCTAssertFalse(s.world.entities[b].object.hitGlowOn)
        XCTAssertTrue(s.world.entities[b].deleted)
        XCTAssertTrue(s.world.entities[b].destroyed)
        XCTAssertEqual(s.world.entities[b].killer, 0)
        XCTAssertEqual(s.flags.groundDestroyed, created + 1)
        XCTAssertEqual(s.debris.rects, [])                                    // bsgr: no obstacle
        XCTAssertEqual(count(s, "bsdt"), 1)

        // A second destroy of a flagged entity does nothing (10016320).
        steps = []
        let draws = s.rng.draws
        s.destroyEntity(b, killer: 1, now: 101) { steps.append($0) }
        XCTAssertEqual(steps, [])
        XCTAssertEqual(s.rng.draws, draws)
        XCTAssertEqual(s.world.entities[b].killer, 0)

        let p = try put(&s, "plla", x: 100, y: 200)[0]
        steps = []
        s.destroyEntity(p, killer: -1, now: 100) { steps.append($0) }
        XCTAssertEqual(steps, [.glowOff, .obstacle(s.boundingBox(p)), .particles(FourCC("med ")!),
                               .mediaGate(allowed: true), .spawn(FourCC("plld")!), .sound(FourCC("ex2s")!), .flags,
                               .accuracyCount])
        XCTAssertEqual(s.debris.rects, [s.boundingBox(p)])
        XCTAssertEqual(s.world.entities[p].killer, -1)
    }

    /// The ladder `1001653c..100167b8` with flli 209–219 = 70, 78, 82, 84, 87, 91, 95, 98, 100, 10, 3 and gaob 25…34
    /// = `rb01`…`rb10`; the reward rule (G+0x0c) turns one r < 10 into `rb06` and disarms.
    func testRandomBonusLadder() throws {
        var s = try world()
        func rb(_ n: Int) -> FourCC { FourCC(String(format: "rb%02d", n))! }
        XCTAssertEqual(s.randomBonusObject(0), rb(1))
        XCTAssertEqual(s.randomBonusObject(69), rb(1))
        XCTAssertEqual(s.randomBonusObject(70), rb(2))
        XCTAssertEqual(s.randomBonusObject(77), rb(2))
        XCTAssertEqual(s.randomBonusObject(78), rb(3))
        XCTAssertEqual(s.randomBonusObject(82), rb(4))
        XCTAssertEqual(s.randomBonusObject(84), rb(5))
        XCTAssertEqual(s.randomBonusObject(87), rb(6))
        XCTAssertEqual(s.randomBonusObject(91), rb(7))
        XCTAssertEqual(s.randomBonusObject(95), rb(8))
        XCTAssertEqual(s.randomBonusObject(97), rb(8))
        XCTAssertEqual(s.randomBonusObject(98), rb(8))                        // sector 1 < 3
        XCTAssertEqual(s.randomBonusObject(100), rb(8))
        s.flags.sector = 2
        XCTAssertEqual(s.randomBonusObject(98), rb(8))
        s.flags.sector = 3
        XCTAssertEqual(s.randomBonusObject(98), rb(9))
        XCTAssertEqual(s.randomBonusObject(99), rb(9))
        XCTAssertEqual(s.randomBonusObject(100), rb(10))
        XCTAssertEqual(s.randomBonusObject(97), rb(8))

        s.flags.rewardArmed = true
        XCTAssertEqual(s.randomBonusObject(50), rb(1))                        // r ≥ 10: still armed
        XCTAssertTrue(s.flags.rewardArmed)
        XCTAssertEqual(s.randomBonusObject(10), rb(1))                        // r < F(218) = 10 is strict
        XCTAssertTrue(s.flags.rewardArmed)
        XCTAssertEqual(s.randomBonusObject(75), rb(2))
        XCTAssertTrue(s.flags.rewardArmed)
        XCTAssertEqual(s.randomBonusObject(9), rb(6))
        XCTAssertFalse(s.flags.rewardArmed)                                   // once
        XCTAssertEqual(s.randomBonusObject(9), rb(1))
    }

    /// `plla` (shields 2.6f, score 0, `destructNumCoinsToRelease 2 × cass`) under the Plasma Bomb's 0.4: six hits leave
    /// 2.1999998 … 0.1999999 (single `fsubs`), the 7th stores 0.0 (clamped) and destroys; no points; the sweep's
    /// `FUN_10036120` releases the 2 coins (killer P1, not collected).
    func testPlatformSevenBombHits() throws {
        var s = try world()
        let p = try put(&s, "plla", x: 200, y: 300)[0]
        XCTAssertEqual(s.world.entities[p].shields.bitPattern, Float(2.6).bitPattern)
        let expected: [Float] = [2.1999998, 1.7999998, 1.3999999, 0.9999999, 0.5999999, 0.1999999, 0]
        let score = s.players[0].score
        for (k, v) in expected.enumerated() {
            XCTAssertFalse(s.world.entities[p].deleted, "hit \(k + 1)")
            s.damageEntity(p, damage: 0.4, killer: 0, now: 200 + 2 * Int32(k))
            XCTAssertEqual(s.world.entities[p].shields.bitPattern, v.bitPattern, "hit \(k + 1)")
        }
        XCTAssertTrue(s.world.entities[p].deleted)
        XCTAssertTrue(s.world.entities[p].destroyed)
        XCTAssertEqual(s.world.entities[p].killer, 0)
        XCTAssertEqual(s.players[0].score, score)
        let cass = count(s, "cass")
        s.sweepDeleted()
        XCTAssertEqual(count(s, "cass"), cass + 2)
        XCTAssertFalse(s.world.inUse[p])

        // A timer/rule kill (killer −1) releases no coin; nor does a collected pickup.
        let q = try put(&s, "plla", x: 100, y: 300)[0]
        s.destroyEntity(q, killer: -1, now: 300)
        let r = try put(&s, "plla", x: 300, y: 300)[0]
        s.world.entities[r].collected = true
        s.destroyEntity(r, killer: 0, now: 300)
        let before = count(s, "cass")
        s.sweepDeleted()
        XCTAssertEqual(count(s, "cass"), before)
    }

    /// `fl02` (Flipper Mk 2, a group of 8–9, `destructCoinOnGroupKill cass`, no single coin): the group coin needs the
    /// group's last removed member (`+0xac == +0xa4`) to be a player kill; earlier members count even when they died to a
    /// timer. Exactly one `cass` per group.
    func testGroupKillCoin() throws {
        var s = try world()
        let a = try put(&s, "fl02", x: 200, y: 100)
        XCTAssertGreaterThanOrEqual(a.count, 8)
        let g = try XCTUnwrap(s.world.groups.firstIndex { $0.members.contains(a[0]) })
        XCTAssertEqual(Int(s.world.groups[g].requested), a.count)
        for (k, m) in a.enumerated() { s.destroyEntity(m, killer: k == 0 ? -1 : 0, now: 100) }   // first by a timer
        let cass = count(s, "cass")
        s.sweepDeleted()
        XCTAssertEqual(count(s, "cass"), cass + 1)
        XCTAssertFalse(s.world.groups.contains { $0.members.contains(a[0]) })   // the emptied group is freed

        // The last one by a timer: no group coin.
        let b = try put(&s, "fl02", x: 200, y: 100)
        for (k, m) in b.enumerated() { s.destroyEntity(m, killer: k == b.count - 1 ? -1 : 0, now: 100) }
        let before = count(s, "cass")
        s.sweepDeleted()
        XCTAssertEqual(count(s, "cass"), before)
    }

    /// `plbo` (Plasma Bomb, ground, `mediaImpactSize smra`, destruct spawn `pbhf`) dying over a 0x001f mask cell (map point
    /// (trunc x + 32, trunc y + window top), cell = point / 5): one `R(0, 1)` picks gaob 6 `spti` (≠ 0) or 7 `spsm`, which
    /// is spawned, and the destruct spawn is suppressed. Over land: no draw, the spawn appears.
    func testMediaGateWater() throws {
        var s = try world()
        let top = s.scroll.window.top
        XCTAssertEqual(top, 3120)
        var cells = [UInt16](repeating: 0x7fff, count: 96 * 720)
        let (col, row) = (Int(210 + 32) / 5, Int(300 + top) / 5)               // x 210.7, y 300.9
        cells[row * 96 + col] = 0x001f
        s.mask = MediaMask(width: 96, height: 720, cells: cells, scale: 5)
        XCTAssertTrue(s.mask.isWater(x: 210 + 32, y: 300 + top))
        XCTAssertFalse(s.mask.isWater(x: 215 + 32, y: 300 + top))             // next cell
        XCTAssertTrue(s.mask.isWater(x: -4, y: -4) == (cells[0] == 0x001f))    // −4 / 5 = 0: tested, not rejected
        XCTAssertFalse(MediaMask().isWater(x: 0, y: 0))

        let w = try put(&s, "plbo", x: 210.7, y: 300.9, player: 0)[0]
        var copy = s.rng
        let impact = copy.range(Int32(0), 1) != 0 ? "spti" : "spsm"
        let (spti, spsm, pbhf) = (count(s, "spti"), count(s, "spsm"), count(s, "pbhf"))
        var steps: [DestroyStep] = []
        s.destroyEntity(w, killer: 0, now: 100) { steps.append($0) }
        XCTAssertEqual(steps, [.glowOff, .mediaGate(allowed: false), .flags])
        XCTAssertEqual(count(s, "pbhf"), pbhf)
        XCTAssertEqual(count(s, "spti") - spti + count(s, "spsm") - spsm, 1)
        XCTAssertEqual(count(s, impact), (impact == "spti" ? spti : spsm) + 1)
        let made = try XCTUnwrap(s.world.entities.indices.last { s.world.inUse[$0] && s.world.entities[$0].owner == w })
        XCTAssertEqual(s.world.entities[made].ownerPlayer, 0)                  // +0x14 = +0xd8

        let l = try put(&s, "plbo", x: 230, y: 300, player: 0)[0]
        let draws = s.rng.draws
        XCTAssertTrue(s.mediaGate(l))
        XCTAssertEqual(s.rng.draws, draws)
    }

    /// `plla` (`destructDrawToTerrain`, `castsShadows`) reaped by the sweep: +0x36 set, its shadow (layer 0) and sprite
    /// (layer 1) commands with flags |8, the terrain-buffer clip and map coordinates go to `tickOps`; the slot is freed.
    func testDrawToTerrainStampsIntoTickOps() throws {
        var s = try world()
        s.scroll.offset = 7                                                   // ignored by the stamp
        let p = try put(&s, "plla", x: 200.6, y: 300.4)[0]
        s.destroyEntity(p, killer: 0, now: 100)
        XCTAssertTrue(s.tickOps.isEmpty)
        let o = s.world.entities[p].object
        XCTAssertGreaterThan(o.visibility, 0)
        s.sweepDeleted()
        XCTAssertTrue(s.world.entities[p].object.drawToTerrain)
        XCTAssertFalse(s.world.inUse[p])
        let cmds: [DrawCommand] = s.tickOps.compactMap { if case let .draw(c) = $0 { return c } else { return nil } }
        XCTAssertEqual(cmds.count, s.tickOps.count)
        XCTAssertGreaterThanOrEqual(cmds.count, 2)
        let terrain = MacRect(top: 0, left: 0, bottom: 3600, right: 480)
        XCTAssertTrue(cmds.allSatisfy { $0.flags & 8 != 0 && $0.clip == terrain && !$0.drawNow && $0.face == o.face })
        XCTAssertEqual(cmds.first?.layer, 0)                                  // the shadow first
        XCTAssertEqual(cmds.first.map { $0.flags & 2 }, 2)
        let sprite = try XCTUnwrap(cmds.first { $0.layer == 1 })
        XCTAssertEqual(sprite.x, 200 + 32)
        XCTAssertEqual(sprite.y, 300 + s.scroll.window.top)
        XCTAssertEqual(sprite.flags & 7, 0)
    }
}
