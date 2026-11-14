import XCTest
import HectorResources
@testable import DeimosCore

/// The carry/reset table (plan CR; appendix A §2, the reference — the bank's §8 omits rows): what a player and the
/// game keep, and what they lose, when `levelCompleteStep` (`FUN_10007170`) starts the next sector inside the same
/// game — the per-level player start `FUN_100269a0` (`100269c4..10026af0`, acting only on an in-game player), the
/// handler reset `FUN_1003af90(h, 1)` (`1003afc0..1003b15c`) and the rest of the level start `FUN_100064d0`.
///
/// Every test crosses a REAL transition: the scroll is poked one row from the map's end (`progress = 3599`), the level
/// end and its tallies run on their own, and the pass whose tally finishes crosses into the next sector. The fields a
/// row is about are poked on the session as it stands just before that pass (a copy kept while running), so the
/// tallies cannot pay into them; then that pass runs.
final class CarryResetTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    private func session(sector: Int, players: Int = 1) throws -> DeimosSession {
        try DeimosSession(assets: assets(), prefs: .fresh, start: SessionStart(sector: sector, players: players, film: nil),
                          seed: 0x469c2)
    }

    private func weapon(_ id: String) throws -> WeaponDefinition {
        try XCTUnwrap(assets().definitions.weapons.first { $0.id == FourCC(id) }, "no weapon \(id)")
    }

    /// Pokes progress 3599 and runs the level end until the pass that crosses into the next sector; returns the
    /// session as it stood just BEFORE that pass (nil, with a failure, at the bound or a session end). Bound: 3,000.
    private func lastPassBeforeTransition(_ start: DeimosSession) -> DeimosSession? {
        var s = start
        s.game.scroll.progress = 3599
        let started = s.game.flags.levelsStarted
        for _ in 0..<3000 {
            let before = s
            let out = s.pass(keys: HeldKeys(), ticks: 0)
            if s.game.flags.levelsStarted != started { return before }
            if out.sessionEnded { XCTFail("the session ended before a transition"); return nil }
        }
        XCTFail("bound: no transition within 3,000 passes")
        return nil
    }

    /// P1's fire-air key in the fresh prefs' key table (⌘, `1000515c..10005194`).
    private static let p1FireAir: UInt16 = 0x37

    /// The crossing pass: one pass that must start the next level and not end the session.
    @discardableResult
    private func cross(_ s: inout DeimosSession, keys: HeldKeys = HeldKeys(),
                       file: StaticString = #filePath, line: UInt = #line) -> PassOutput {
        let started = s.game.flags.levelsStarted
        let sector = s.game.flags.sector
        let out = s.pass(keys: keys, ticks: 0)
        XCTAssertEqual(s.game.flags.levelsStarted, started + 1, "the pass crossed", file: file, line: line)
        XCTAssertEqual(s.game.flags.sector, sector + 1, file: file, line: line)
        XCTAssertFalse(out.sessionEnded, file: file, line: line)
        XCTAssertEqual(s.gameTime, 1, "10006500 then 100059e0", file: file, line: line)
        return out
    }

    /// Runs passes until game time is `t` (the next pass ticks at `t`). Bound: 3,000 passes.
    private func run(_ s: inout DeimosSession, to t: Int32, file: StaticString = #filePath, line: UInt = #line) {
        var n = 0
        while s.gameTime < t {
            _ = s.pass(keys: HeldKeys(), ticks: 0)
            n += 1
            if n > 3000 { return XCTFail("bound: game time \(t) not reached in 3,000 passes", file: file, line: line) }
        }
    }

    /// The live (in a group, in use, not deleted) entity with this serial, if any.
    private static func live(_ g: GameState, serial: Int32) -> Int? {
        for group in g.world.groups {
            for e in group.members where g.world.inUse[e] && !g.world.entities[e].deleted
                && g.world.entities[e].serial == serial {
                return e
            }
        }
        return nil
    }

    /// Every stored field of a player but its shared assets, as text — "byte-equal" for a struct that is not
    /// `Equatable` (floats print exactly; distinct values print distinctly).
    private static func fields(_ p: Player) -> [String] {
        Mirror(reflecting: p).children.filter { $0.label != "assets" }.map { "\($0.label ?? "?")=\(String(reflecting: $0.value))" }
    }

    // MARK: - Rows

    /// Lives +0x98, score +0xb0, extra-life threshold +0x9c / step +0xa0 (setup only: `FUN_10026cc0` from 10026850 /
    /// 10026874, `FUN_100299c0` from 10026354 / 1002688c, 10026d10) and the setup-only bytes (max speed +0xa4,
    /// cheated +0xbd): `FUN_100269a0` touches none of them (`100269c4..10026af0`). The score bar's level start
    /// copies the carried score and lives (`FUN_10031400`).
    func testLivesScoreThresholdCarry() throws {
        var s = try XCTUnwrap(lastPassBeforeTransition(try session(sector: 1)))
        XCTAssertEqual(s.players[0].lives, 3, "the sector-1 start")
        s.game.players[0].lives = 2
        s.game.players[0].score = 12_345
        s.game.players[0].extraLifeThreshold = 40_000
        s.game.players[0].extraLifeStep = 30_000
        s.game.players[0].maxSpeed = 7.25
        s.game.players[0].cheated = true
        cross(&s)
        let p = s.players[0]
        XCTAssertEqual(p.lives, 2)
        XCTAssertEqual(p.score, 12_345)
        XCTAssertEqual(p.extraLifeThreshold, 40_000)
        XCTAssertEqual(p.extraLifeStep, 30_000)
        XCTAssertEqual(p.maxSpeed.bitPattern, Float(7.25).bitPattern)
        XCTAssertTrue(p.cheated)
        XCTAssertEqual(s.scoreBar.records[0].lastScore, 12_345)
        XCTAssertEqual(s.scoreBar.records[0].lastLives, 2)
    }

    /// Money +0xac → 0 (`FUN_10027580`, 10026a3c) and the money counter / coin tally +0xd8…+0x1f8 → reset with alpha
    /// 0x20 (`FUN_10027630`, 10026a48), after the coin bonus was paid: the tally stands in its last state (8) when the
    /// level completes.
    func testMoneyAndCounterReset() throws {
        var s = try XCTUnwrap(lastPassBeforeTransition(try session(sector: 1)))
        XCTAssertEqual(s.game.tally.coin[0].state, 8, "the coin tally's last state, as the level completes")
        XCTAssertFalse(s.game.tally.coin[0].text.isEmpty)
        s.game.players[0].money = 77
        cross(&s)
        XCTAssertEqual(s.players[0].money, 0)
        var reset = TallyState.CoinTally()
        reset.alpha = 0x20
        XCTAssertEqual(s.game.tally.coin[0], reset)
    }

    /// Multiplier +0xb4 carried (`FUN_10029fd0` resets it only at setup 10026898 and death 10028150) and the indicator
    /// serial +0xb8 carried STALE (ruling 6): entity serials restart at 1000 every level (`FUN_10032e60`), so the
    /// first respawn's `FUN_10029fe0` removes whatever new-level entity holds the old serial (1002a094 `FUN_10034de0`)
    /// before it spawns `mux3` (PermObjectID 36) at the ship.
    func testMultiplierCarriesAndIndicatorOnRespawn() throws {
        let pre = try XCTUnwrap(lastPassBeforeTransition(try session(sector: 1)))
        // Find a serial that will be live in sector 2 just before P1's respawn tick (game time 56): cross a copy.
        var probe = pre
        probe.game.players[0].multiplier = 3
        cross(&probe)
        run(&probe, to: 56)
        let serials = probe.game.world.groups.flatMap(\.members)
            .filter { probe.game.world.inUse[$0] && !probe.game.world.entities[$0].deleted }
            .map { probe.game.world.entities[$0].serial }
        let stale = try XCTUnwrap(serials.min(), "something lives in sector 2 at game time 56")

        var s = pre
        s.game.players[0].multiplier = 3
        s.game.players[0].multiplierIndicator = stale                       // level 1's last indicator, as it might be
        cross(&s)
        XCTAssertEqual(s.players[0].multiplier, 3)
        XCTAssertEqual(s.players[0].multiplierIndicator, stale, "+0xb8 is not touched by the level start")
        run(&s, to: 56)
        XCTAssertEqual(s.players[0].lifeState, 2)
        let victim = try XCTUnwrap(Self.live(s.game, serial: stale), "the new level's entity with the stale serial")
        let units = s.game.assets.definitions.units
        XCTAssertNotEqual(units[s.game.world.entities[victim].unit].id, FourCC("mux3"))
        _ = s.pass(keys: HeldKeys(), ticks: 0)                               // the tick at game time 56: respawn
        XCTAssertEqual(s.players[0].lifeState, 4)
        XCTAssertEqual(s.players[0].stateEntered, 56, "now > 0 + entry_InitialDelay 55")
        XCTAssertNil(Self.live(s.game, serial: stale), "removed by the stale serial (1002a094)")
        let indicator = try XCTUnwrap(Self.live(s.game, serial: s.players[0].multiplierIndicator))
        XCTAssertEqual(units[s.game.world.entities[indicator].unit].id, FourCC("mux3"))
        XCTAssertEqual(s.game.assets.objects[36], FourCC("mux3"))
        XCTAssertNotEqual(s.players[0].multiplierIndicator, stale)
    }

    /// Shield → defaultShieldPercentage 100 (`FUN_10027400(p, 1)`, 10026a58: hit timers 0, +0xd1 = 0); +0xd0 = 0
    /// (100269d4), +0xc5 = 0 (100269ec), +0xc0 = the new tag (100269f4); start position, velocity, crosshair adjust,
    /// overload (`FUN_10026b10`, `FUN_10026ea0`); glow off (`FUN_10012c00`); appear fade flli 163–165; the integrity
    /// tick (10026a9c..10026af0); and the handler reset (`FUN_1003af90(h, 1)`): x, y, the previous buttons, icons
    /// dirty, salvo / bomb / air-launch counters, BOTH power-up blocks idle (1003b054..1003b0a8: state 0, start 0,
    /// serial −1, last step 0, level 0, percent 0.0, last release 0, held 0), crosshair unlocked, faded in from 0.
    func testShieldRefilledPowerUpsIdle() throws {
        var s = try XCTUnwrap(lastPassBeforeTransition(try session(sector: 1)))
        XCTAssertEqual(s.players[0].lifeState, 4)
        var charging = WeaponHandler.PowerUpState()
        charging.state = 1; charging.start = 900; charging.serial = 1234; charging.lastStep = 905
        charging.level = 2; charging.percent = 40; charging.lastRelease = 900; charging.held = 5
        s.game.players[0].shield = 37
        s.game.players[0].lastHit = 99
        s.game.players[0].lastHitSpawn = 98
        s.game.players[0].shieldWarningShown = true
        s.game.players[0].hitThisLevel = true
        s.game.players[0].appearing = true
        s.game.players[0].object.x = 111; s.game.players[0].object.y = 222
        s.game.players[0].object.vx = 3; s.game.players[0].object.vy = -2
        s.game.players[0].crosshairAdjust = 40
        s.game.players[0].object.hitGlowOn = true
        s.game.players[0].handler.airPower = charging
        s.game.players[0].handler.groundPower = charging
        s.game.players[0].handler.iconsDirty = false
        s.game.players[0].handler.lastSalvo = 800; s.game.players[0].handler.lastBomb = 801
        s.game.players[0].handler.bombsPending = 3
        s.game.players[0].handler.lastAirLaunch = 802; s.game.players[0].handler.airLaunches = 9
        s.game.players[0].integrityPasses = 4
        cross(&s)
        let p = s.players[0]
        let d = p.definition
        XCTAssertEqual(d.defaultShieldPercentage, 100)
        XCTAssertEqual(p.shield.bitPattern, Float(100).bitPattern)
        XCTAssertEqual(p.lastHit, 0)
        XCTAssertEqual(p.lastHitSpawn, 0)
        XCTAssertFalse(p.shieldWarningShown)
        XCTAssertFalse(p.hitThisLevel)
        XCTAssertFalse(p.appearing)
        XCTAssertEqual(p.levelRef, FourCC("le06"))
        XCTAssertEqual(p.object.x.bitPattern, Float(d.entrySoloStartX).bitPattern)
        XCTAssertEqual(p.object.y.bitPattern, Float(d.entrySoloStartY).bitPattern)
        XCTAssertEqual(p.object.vx, 0)
        XCTAssertEqual(p.object.vy, 0)
        XCTAssertEqual(p.crosshairAdjust, 0)
        XCTAssertFalse(p.overloadActive)
        XCTAssertFalse(p.object.hitGlowOn)
        let f = s.game.assets.floats
        XCTAssertEqual(p.object.visibility.bitPattern, f[163].bitPattern)
        XCTAssertEqual(p.object.visibilityTarget.bitPattern, f[164].bitPattern)
        XCTAssertEqual(p.object.visibilityStep.bitPattern, f[165].bitPattern)
        XCTAssertEqual(p.integrityPasses, 0)
        XCTAssertTrue((400...2000).contains(p.integrityCheckTick), "0 + R(400, 2000) (10026ae4)")
        let h = p.handler
        XCTAssertEqual(h.airPower, WeaponHandler.PowerUpState())
        XCTAssertEqual(h.airPower.serial, -1)
        XCTAssertEqual(h.groundPower, WeaponHandler.PowerUpState())
        XCTAssertEqual(h.x, 0)
        XCTAssertEqual(h.y, 0)
        XCTAssertFalse(h.previousFireGround || h.previousFireAir || h.previousSelect)
        XCTAssertTrue(h.iconsDirty)
        XCTAssertEqual([h.lastSalvo, h.lastBomb, h.bombsPending, h.lastAirLaunch, h.airLaunches], [0, 0, 0, 0, 0])
        XCTAssertFalse(h.crosshairLocked)
        XCTAssertEqual(h.crosshair.visibility, 0)
        XCTAssertEqual(h.crosshair.visibilityTarget, 100)
        XCTAssertEqual(h.crosshair.visibilityStep.bitPattern, h.crosshairFadeInRate.bitPattern)
    }

    /// The level start's forced swap (1003b0dc..1003b108: `FUN_1003cd30` = the PEAA whose minimum level equals G+0x14,
    /// set at 100066e8 before the players): entering sector 2 → `aibg`, 3 → `airg`, 5 → `aipb`, and the pending air
    /// weapon is dropped (1003b104..1003b108). No PEAA has minimum 4 or 6, so 1003b0ec branches past: the current
    /// air weapon stays — at sector 4 even `aiic`, outside sector 4's range (plan correction 3) — and a pending air
    /// weapon is KEPT, not applied. There is one air slot.
    func testAirWeaponForcedAtSectorsTwoThreeFive() throws {
        let aiic = try weapon("aiic"), aibg = try weapon("aibg"), airg = try weapon("airg"), aipb = try weapon("aipb")
        XCTAssertEqual(aiic.maximumLevelAvailable, 3, "the Ion Cannon is outside sector 4's range")
        // A pending air weapon exists only while the air power-up runs (`FUN_1003b180`), so P1 holds fire through
        // the crossing pass to keep it charging (a release would apply the pending weapon in that tick, 1003b44c).
        var charging = WeaponHandler.PowerUpState()
        charging.state = 1; charging.serial = 1234; charging.percent = 40
        let fire = HeldKeys(held: [Self.p1FireAir])

        // 1 → 2: the forced Bacta Gun.
        var s = try XCTUnwrap(lastPassBeforeTransition(try session(sector: 1)))
        XCTAssertEqual(s.players[0].handler.air.id, aiic.id)
        cross(&s)
        XCTAssertEqual(s.players[0].handler.air.id, aibg.id, "entering sector 2")

        // 2 → 3: forced, with a pending weapon dropped.
        s = try XCTUnwrap(lastPassBeforeTransition(try session(sector: 2)))
        s.game.players[0].handler.air = aiic
        s.game.players[0].handler.pendingAir = aibg
        s.game.players[0].handler.airPower = charging
        s.game.players[0].handler.airPower.start = s.gameTime
        s.game.players[0].handler.airPower.lastStep = s.gameTime
        cross(&s, keys: fire)
        XCTAssertEqual(s.players[0].handler.air.id, airg.id, "entering sector 3")
        XCTAssertNil(s.players[0].handler.pendingAir, "dropped on a match (1003b108)")

        // 3 → 4: no match — the Ion Cannon stays, a pending weapon stays pending.
        s = try XCTUnwrap(lastPassBeforeTransition(try session(sector: 3)))
        s.game.players[0].handler.air = aiic
        s.game.players[0].handler.pendingAir = aibg
        s.game.players[0].handler.airPower = charging
        s.game.players[0].handler.airPower.start = s.gameTime
        s.game.players[0].handler.airPower.lastStep = s.gameTime
        cross(&s, keys: fire)
        XCTAssertEqual(s.players[0].handler.air.id, aiic.id, "sector 4 keeps the last selected air weapon")
        XCTAssertEqual(s.players[0].handler.pendingAir?.id, aibg.id, "kept, not applied (1003b0ec beq 1003b138)")
        XCTAssertEqual(s.players[0].handler.airPower, WeaponHandler.PowerUpState())
        XCTAssertEqual(s.players[0].handler.effectiveAir.id, aibg.id)

        // 4 → 5: forced again over a pending weapon.
        s = try XCTUnwrap(lastPassBeforeTransition(try session(sector: 4)))
        s.game.players[0].handler.pendingAir = aibg
        s.game.players[0].handler.airPower = charging
        s.game.players[0].handler.airPower.start = s.gameTime
        s.game.players[0].handler.airPower.lastStep = s.gameTime
        cross(&s, keys: fire)
        XCTAssertEqual(s.players[0].handler.air.id, aipb.id, "entering sector 5")
        XCTAssertNil(s.players[0].handler.pendingAir)

        // 5 → 6: no match — kept.
        s = try XCTUnwrap(lastPassBeforeTransition(try session(sector: 5)))
        s.game.players[0].handler.air = aibg
        cross(&s)
        XCTAssertEqual(s.players[0].handler.air.id, aibg.id, "sector 6 keeps the current air weapon")
        XCTAssertNil(s.players[0].handler.pendingAir)
    }

    /// Invulnerable +0xce set NOT sticky by the level end (10006f28 `FUN_10027de0(p, 1, 0)`); neither `FUN_100269a0`
    /// nor the respawn `FUN_10029cc0` writes it, so the next level's first life starts invulnerable and is cleared on
    /// the first tick with now > enter + entry_InvulnerabilityTime 60 and G+0x39 clear (1002a1e8..1002a238). The life
    /// state: 2 at game time 0 (10026a20), respawn when now > 55. Level 1's first life is not invulnerable.
    func testInvulnerabilityCarriesIntoNextLevel() throws {
        var s = try session(sector: 1)
        run(&s, to: 60)
        XCTAssertEqual(s.players[0].lifeState, 4)
        XCTAssertEqual(s.players[0].stateEntered, 56, "level 1's respawn tick")
        XCTAssertFalse(s.players[0].invulnerable, "level 1's first life is not invulnerable")
        s = try XCTUnwrap(lastPassBeforeTransition(s))
        XCTAssertTrue(s.players[0].invulnerable, "the level end set it (10006f28)")
        XCTAssertFalse(s.players[0].invulnerableSticky)
        cross(&s)
        XCTAssertTrue(s.players[0].invulnerable, "carried into the next level")
        XCTAssertFalse(s.players[0].invulnerableSticky)
        XCTAssertEqual(s.players[0].lifeState, 2)
        XCTAssertEqual(s.players[0].stateEntered, 0)
        run(&s, to: 57)                                                      // the tick at 56 has run
        XCTAssertEqual(s.players[0].lifeState, 4)
        XCTAssertEqual(s.players[0].stateEntered, 56)
        XCTAssertTrue(s.players[0].invulnerable, "the respawn does not touch it")
        run(&s, to: 117)                                                     // ticks through 116 = 56 + 60
        XCTAssertTrue(s.players[0].invulnerable, "now > enter + 60 is strict (1002a214..1002a218)")
        XCTAssertFalse(s.game.flags.levelEnding)
        _ = s.pass(keys: HeldKeys(), ticks: 0)                               // the tick at 117
        XCTAssertFalse(s.players[0].invulnerable)
        XCTAssertFalse(s.players[0].invulnerableSticky)
    }

    /// A player out of the game (+0xc4 = 0) stays out: `FUN_100269a0` returns at once (100269c4..100269cc) — no field
    /// written, no `R(400, 2000)` drawn, its coin tally untouched — and its score-bar record stays dimmed
    /// (`FUN_10031400`: +0x12e = +0x12f = +0xc4). Ruling 6's quirk in the same crossing: P1, caught dying (state 3),
    /// still has +0xc4 = 1, so it is put back to state 2 at game time 0 with no life taken, and plays on.
    func testDeadPlayerStaysOut() throws {
        var s = try session(sector: 1, players: 2)
        // P2 eliminated, as the life-state step leaves it (1002a264): out of lives, state 1, out of the game.
        s.game.players[1].lives = 0
        s.game.players[1].lifeState = 1
        s.game.players[1].inGame = false
        s.game.players[1].shield = 0
        var pre = try XCTUnwrap(lastPassBeforeTransition(s))
        XCTAssertFalse(pre.scoreBar.records[1].drawActive, "retired by the score bar's update")
        // P1 dies on the crossing pass's eve (the death begun before the level end could not happen otherwise).
        let lives = pre.players[0].lives
        pre.game.killPlayer(0, now: pre.gameTime)
        XCTAssertEqual(pre.players[0].lifeState, 3)
        XCTAssertTrue(pre.players[0].inGame)

        // The tick's own draws, measured on a copy whose coin tally is held one more tick (no transition).
        var held = pre
        held.game.tally.coin[0].stateTimer = held.gameTime
        _ = held.pass(keys: HeldKeys(), ticks: 0)
        XCTAssertEqual(held.game.flags.levelsStarted, pre.game.flags.levelsStarted, "the copy did not cross")
        let tickDraws = held.rng.draws - pre.rng.draws

        let p2Before = Self.fields(pre.players[1])
        let coin2Before = pre.game.tally.coin[1]
        var after = pre
        cross(&after)
        XCTAssertEqual(Self.fields(after.players[1]), p2Before, "the out player is not touched")
        XCTAssertEqual(after.game.tally.coin[1], coin2Before)
        XCTAssertFalse(after.scoreBar.records[1].drawActive)
        XCTAssertFalse(after.scoreBar.records[1].pendingRetire)
        XCTAssertTrue(after.scoreBar.records[0].drawActive)
        // One R(400, 2000) (10026a9c, P1's): a sector-2 start draws one per in-game player and nothing else (no
        // load-pass placement; the no02 notice draws none) — and the crossing's level start drew exactly one.
        let one = try session(sector: 2, players: 1), two = try session(sector: 2, players: 2)
        XCTAssertEqual(one.rng.draws, 1)
        XCTAssertEqual(two.rng.draws, 2)
        XCTAssertEqual(after.rng.draws - pre.rng.draws - tickDraws, 1, "P2's draw is not made")
        // The quirk: revived without the life decrement.
        XCTAssertTrue(after.players[0].inGame)
        XCTAssertEqual(after.players[0].lifeState, 2)
        XCTAssertEqual(after.players[0].stateEntered, 0)
        XCTAssertEqual(after.players[0].lives, lives, "no life taken")
        XCTAssertEqual(after.players[0].shield.bitPattern, Float(100).bitPattern)
        run(&after, to: 57)
        XCTAssertEqual(after.players[0].lifeState, 4, "it plays on")
        XCTAssertEqual(after.players[0].lives, lives)
    }

    /// The game's per-level state (`FUN_100064d0` 10006500..10006544, `FUN_10007170` 1000723c..10007248,
    /// `FUN_10032e60`, `FUN_1000fa90`, `FUN_10031400`): reward armed = last level perfect, then the perfect flag
    /// cleared; perfect levels carried; cheat counters, ground counts, the accuracy tally, G+0x29 / +0x2c / +0x38 /
    /// +0x39 / +0x09 reset; G+0x0a, the game-over latch and p1Active not reset; the score bar re-started (all dirty,
    /// followers 0.0, last score / lives current, icons by the new sector); the entity world, the pending list,
    /// messages, notice, debris, particles and blurs as a fresh sector-2 start leaves them; the scroll at its start.
    func testPerLevelCountersReset() throws {
        var s = try XCTUnwrap(lastPassBeforeTransition(try session(sector: 1)))
        XCTAssertTrue(s.game.flags.levelEndHandled)
        XCTAssertNotEqual(s.game.tally.state, 0)
        s.game.flags.perfectThisLevel = true
        s.game.flags.perfectLevels = 5
        s.game.flags.cheatLife = 1; s.game.flags.cheatFunds = 2; s.game.flags.cheatScore = 3
        s.game.flags.cheatShields = 4; s.game.flags.cheatMult = 5
        s.game.flags.groundCreated = 40; s.game.flags.groundDestroyed = 30
        s.game.entityLimitWarned = true
        // Not reset by any level start (a transition needs someone in game; the latches are session state).
        s.game.flags.noPlayerAlive = true
        s.game.flags.gameOverNoticed = true
        let p1Active = s.game.flags.p1Active
        cross(&s)
        let g = s.game.flags
        XCTAssertTrue(g.rewardArmed)
        XCTAssertFalse(g.perfectThisLevel)
        XCTAssertEqual(g.perfectLevels, 5)
        XCTAssertEqual([g.cheatLife, g.cheatFunds, g.cheatScore, g.cheatShields, g.cheatMult], [0, 0, 0, 0, 0])
        XCTAssertEqual(g.groundCreated, 0)
        XCTAssertEqual(g.groundDestroyed, 0)
        XCTAssertFalse(g.levelEndHandled)
        XCTAssertEqual(g.levelEndTime, 0)
        XCTAssertFalse(g.appeared)
        XCTAssertFalse(g.levelEnding)
        XCTAssertFalse(g.levelComplete)
        XCTAssertTrue(g.noPlayerAlive)
        XCTAssertTrue(g.gameOverNoticed)
        XCTAssertEqual(g.p1Active, p1Active)
        XCTAssertFalse(s.game.entityLimitWarned)
        var tally = TallyState()
        tally.reset()
        tally.coin[0].alpha = 0x20
        tally.coin[1] = s.game.tally.coin[1]
        XCTAssertEqual(s.game.tally, tally)
        // The score bar's level start.
        let r = s.scoreBar.records[0]
        XCTAssertEqual(r.dirty, .all)
        XCTAssertEqual(r.shownShield, 0)
        XCTAssertEqual(r.shownPower, 0)
        XCTAssertEqual(r.lastScore, s.players[0].score)
        XCTAssertEqual(r.lastLives, s.players[0].lives)
        XCTAssertTrue(r.drawActive)
        XCTAssertEqual(r.icons, s.players[0].scoreBarIcons(sector: 2))
        // The scroll (FUN_1000fa90): speed 1, offset 0, top 3120, progress 481, not ended.
        XCTAssertEqual(s.scroll.speed, 1)
        XCTAssertEqual(s.scroll.offset, 0)
        XCTAssertEqual(s.scroll.window.top, 3120)
        XCTAssertEqual(s.scroll.progress, 481)
        XCTAssertFalse(s.scroll.levelEnded)
        // The world: PERM and what the load pass and the level notice made — sector 2 places nothing at rows ≥ 3056.
        let w = s.game.world
        XCTAssertEqual(w.groups.count, 1)
        XCTAssertEqual(w.groups[0].id, EntityGroup.permID)
        XCTAssertEqual(w.nextGroupID, EntityGroup.permID + 1)
        XCTAssertTrue(w.noticesShown.isEmpty)
        XCTAssertEqual(w.groundCount, 0)
        let units = s.game.assets.definitions.units
        let made = w.groups[0].members.filter { w.inUse[$0] }.map { units[w.entities[$0].unit].id }
        XCTAssertEqual(made, [FourCC("no02")!])
        XCTAssertEqual(w.liveCount, 1)
        XCTAssertEqual(w.nextSerial, EntityWorld.firstSerial + 1)
        let fresh = try session(sector: 2)
        XCTAssertEqual(w.pendingLevelObjects, fresh.game.world.pendingLevelObjects)
        XCTAssertEqual(s.game.messages, fresh.game.messages)
        XCTAssertEqual(s.game.notice, fresh.game.notice)
        XCTAssertEqual(s.game.debris, fresh.game.debris)
        XCTAssertEqual(s.game.particles, fresh.game.particles)
        // The blur pool's slots keep their stale sprites (`FUN_10046d30` frees, never clears): compare the rest.
        let b = s.game.blurs
        XCTAssertTrue(b.list.isEmpty)
        XCTAssertEqual(b.cachedFree, 0, "the level reset's cache 0 (quirk)")
        XCTAssertEqual(b.count, 0)
        XCTAssertFalse(b.limitWarned)
        XCTAssertFalse(b.inUse.contains(true))
        XCTAssertEqual(s.game.mask, fresh.game.mask)
    }
}
