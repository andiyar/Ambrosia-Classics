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

    private func weapon(_ id: String, file: StaticString = #filePath, line: UInt = #line) throws -> WeaponDefinition {
        try XCTUnwrap(assets().definitions.weapons.first { $0.id == FourCC(id) }, "no weapon \(id)", file: file, line: line)
    }

    /// Pokes progress 3599 and runs the level end until the pass that crosses into the next sector; returns the
    /// session as it stood just BEFORE that pass (nil, with a failure, at the bound or a session end). Bound: 3,000.
    private func lastPassBeforeTransition(_ start: DeimosSession,
                                          file: StaticString = #filePath, line: UInt = #line) -> DeimosSession? {
        var s = start
        s.game.scroll.progress = 3599
        let started = s.game.flags.levelsStarted
        for _ in 0..<3000 {
            let before = s
            let out = s.pass(keys: HeldKeys(), ticks: 0)
            if s.game.flags.levelsStarted != started { return before }
            if out.sessionEnded { XCTFail("the session ended before a transition", file: file, line: line); return nil }
        }
        XCTFail("bound: no transition within 3,000 passes", file: file, line: line)
        return nil
    }

    /// What the crossing pass's tick alone does: one pass on a copy whose P1 coin tally is held one more tick (its
    /// state timer re-armed), so the level does not complete and no level start runs. Fails if the copy crosses.
    private func tickWithoutCrossing(_ s: DeimosSession, keys: HeldKeys = HeldKeys(),
                                     file: StaticString = #filePath, line: UInt = #line) -> DeimosSession {
        var c = s
        c.game.tally.coin[0].stateTimer = c.gameTime
        _ = c.pass(keys: keys, ticks: 0)
        XCTAssertEqual(c.game.flags.levelsStarted, s.game.flags.levelsStarted, "the copy did not cross",
                       file: file, line: line)
        return c
    }

    /// Replays the crossing pass's generator from the snapshot taken before it: every draw is one `rand()`, and the
    /// level start's `R(400, 2000)` per in-game player (10026a9c) are the pass's last `inGame` draws. Returns the
    /// first of those draws (P1's), after checking the replayed generator lands exactly on the session's.
    private func replayedIntegrityDraw(from before: MSLRandom, to after: MSLRandom, inGame: Int,
                                       file: StaticString = #filePath, line: UInt = #line) -> Int32? {
        let n = after.draws &- before.draws
        guard n >= UInt64(inGame), n < 100_000 else {
            XCTFail("bound: \(n) draws in the crossing pass (expected \(inGame) to 100,000)", file: file, line: line)
            return nil
        }
        var r = before
        for _ in 0..<(n - UInt64(inGame)) { _ = r.rand() }
        let first = r.range(Int32(400), Int32(2000))
        for _ in 1..<max(inGame, 1) { _ = r.range(Int32(400), Int32(2000)) }
        XCTAssertEqual(r, after, "the level start's draws are the pass's last", file: file, line: line)
        return first
    }

    /// P1's keys in the fresh prefs' key table (`1000515c..10005194`): ↑ ←, fire air ⌘, fire ground ⌥, select Space.
    private static let p1Up: UInt16 = 0x7E
    private static let p1Left: UInt16 = 0x7B
    private static let p1Right: UInt16 = 0x7C
    private static let p1Down: UInt16 = 0x7D
    private static let p1FireAir: UInt16 = 0x37
    private static let p1FireGround: UInt16 = 0x3A
    private static let p1Select: UInt16 = 0x31

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
    /// cheated +0xbd), and the input bytes +0x1fc (cleared by the setup 10026934 and by `FUN_1002a3a0`'s read in
    /// state 4, never by the level start): `FUN_100269a0` touches none of them (`100269c4..10026af0`).
    func testLivesScoreThresholdCarry() throws {
        var s = try XCTUnwrap(lastPassBeforeTransition(try session(sector: 1)))
        XCTAssertEqual(s.players[0].lives, 3, "the sector-1 start")
        XCTAssertEqual(s.players[0].lifeState, 4)
        let fresh = s.players[0]
        s.game.players[0].lives = 2
        s.game.players[0].score = 12_345
        s.game.players[0].extraLifeThreshold = 40_000
        s.game.players[0].extraLifeStep = 30_000
        s.game.players[0].maxSpeed = 7.25
        s.game.players[0].cheated = true
        XCTAssertNotEqual(fresh.maxSpeed.bitPattern, Float(7.25).bitPattern, "7.25 is not the setup's")
        XCTAssertFalse(fresh.cheated, "the setup's byte is 0 (100268ec)")
        // The input bytes: the crossing tick's read (state 4) leaves the held keys in them, ahead of the level start.
        let keys = HeldKeys(held: [Self.p1Up, Self.p1Left])
        cross(&s, keys: keys)
        let p = s.players[0]
        XCTAssertEqual(p.lives, 2)
        XCTAssertEqual(p.score, 12_345)
        XCTAssertEqual(p.extraLifeThreshold, 40_000)
        XCTAssertEqual(p.extraLifeStep, 30_000)
        XCTAssertEqual(p.maxSpeed.bitPattern, Float(7.25).bitPattern)
        XCTAssertTrue(p.cheated)
        XCTAssertEqual(p.input, [.up, .left], "the input bytes carried (only the setup clears them, 10026934)")
        // The score bar shows the carried values (the crossing tick's update `FUN_100317e0` copies them too for an
        // in-game player; the level start's own copy, 1003160c..1003167c, is seen on an out player in
        // `testDeadPlayerStaysOut`).
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
        // Find a serial that will be live in sector 2 just before P1's respawn tick (game time 56): cross a copy whose
        // indicator serial is 0, which no entity holds (serials start at 1000 every level).
        var probe = pre
        probe.game.players[0].multiplier = 3
        probe.game.players[0].multiplierIndicator = 0
        cross(&probe)
        run(&probe, to: 56)
        let serials = probe.game.world.groups.flatMap(\.members)
            .filter { probe.game.world.inUse[$0] && !probe.game.world.entities[$0].deleted }
            .map { probe.game.world.entities[$0].serial }
        let stale = try XCTUnwrap(serials.min(), "something lives in sector 2 at game time 56")
        XCTAssertGreaterThanOrEqual(stale, EntityWorld.firstSerial)
        // Without the stale serial the same entity survives the respawn tick: the removal below is the serial's doing.
        _ = probe.pass(keys: HeldKeys(), ticks: 0)                           // the tick at game time 56: respawn
        XCTAssertEqual(probe.players[0].lifeState, 4)
        XCTAssertNotNil(Self.live(probe.game, serial: stale), "survives tick 56 when no indicator holds its serial")

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
    /// serial −1, last step 0, level 0, percent 0.0, last release 0, held 0), crosshair unlocked, faded in from 0;
    /// the ship sprite (`FUN_10029f10`: face from the effective air weapon, frame 0, banking tick 0, layer `play`)
    /// and its size (`FUN_10012940`).
    ///
    /// The crossing tick runs before the level start (`100059cc`, then `100059dc`), so each poke is checked on a copy
    /// that runs that tick alone (`tickWithoutCrossing`) to show the tick leaves it — the reset is then the level
    /// start's. Three pokes need help to survive that tick: P1 holds all three buttons (the handler tick writes them
    /// into the previous-button bytes, 1003b9d4..1003b9e8, with no rising edge since two were already set); the
    /// overload, which the tick's overload step clears while the level ends (10026f6c..10026fb0), needs G+0x38 clear
    /// for that tick (a poke: the level-end step sets it again later in the same tick, 10006db0, before the level
    /// completes) — so only the level start's two clears (`FUN_10026b10`, 10026a64) can clear it; and the crosshair
    /// lock, which every handler tick clears (1003ba08), is poked on P2 of a two-player crossing, waiting to respawn
    /// (state 2: no handler tick, 100290c4..100290cc).
    func testShieldRefilledPowerUpsIdle() throws {
        var s = try XCTUnwrap(lastPassBeforeTransition(try session(sector: 1)))
        XCTAssertEqual(s.players[0].lifeState, 4)
        XCTAssertTrue(s.game.flags.levelEnding)
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
        s.game.players[0].handler.previousFireGround = true          // held through the pass: no new salvo edge
        s.game.players[0].handler.previousSelect = true              // held through the pass: no select edge
        s.game.players[0].integrityPasses = 4
        s.game.players[0].integrityCheckTick = 3                     // outside 0 + R(400, 2000)
        // The overload, mid-warning with nothing due this tick (phase 1, the next step 1,000 ticks away).
        s.game.flags.levelEnding = false
        s.game.players[0].overloadActive = true
        s.game.players[0].overloadPhase = 1
        s.game.players[0].overloadGlow = 50
        s.game.players[0].overloadLast = s.gameTime
        s.game.players[0].overloadInterval = 1000
        s.game.players[0].overloadCount = 2
        s.game.players[0].object.glow = 30
        // The ship sprite and size, as no ship has them.
        let bogus = try XCTUnwrap(FourCC("zzzz"))
        s.game.players[0].object.face = bogus
        s.game.players[0].object.frame = 5
        s.game.players[0].object.layer = try XCTUnwrap(FourCC("defa"))
        s.game.players[0].lastBankingTick = 77
        s.game.players[0].object.scaledWidth = 1; s.game.players[0].object.scaledHeight = 1
        // Small half sizes: the tick's clamp (1002952c..100296f0) reads them, and a large one would pin the ship and
        // zero its velocity there.
        s.game.players[0].object.halfWidth = 9; s.game.players[0].object.halfHeight = 8
        s.game.players[0].object.sizeDirty = false
        // ↓ → held too, so the tick's velocity step leaves a velocity for the reset to zero.
        let buttons = HeldKeys(held: [Self.p1Down, Self.p1Right, Self.p1FireAir, Self.p1FireGround, Self.p1Select])

        let tickOnly = tickWithoutCrossing(s, keys: buttons).players[0]
        XCTAssertEqual(tickOnly.lifeState, 4)
        XCTAssertTrue(tickOnly.handler.previousFireGround && tickOnly.handler.previousFireAir
                      && tickOnly.handler.previousSelect, "the tick leaves all three set")
        XCTAssertFalse(tickOnly.handler.iconsDirty, "no select edge")
        XCTAssertTrue(tickOnly.overloadActive, "the tick keeps the overload with G+0x38 clear")
        XCTAssertNotEqual(tickOnly.overloadPhase, 0)
        XCTAssertNotEqual(tickOnly.object.glow.bitPattern, Float(0).bitPattern)
        XCTAssertNotEqual(tickOnly.object.vx, 0)
        XCTAssertNotEqual(tickOnly.object.vy, 0)
        XCTAssertEqual(tickOnly.object.face, bogus)
        XCTAssertEqual(tickOnly.object.halfWidth, 9)
        XCTAssertEqual(tickOnly.integrityCheckTick, 3)
        XCTAssertNotEqual(tickOnly.handler.crosshair.visibility.bitPattern, Float(0).bitPattern)

        let rngBefore = s.rng
        cross(&s, keys: buttons)
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
        XCTAssertEqual(p.object.vx.bitPattern, Float(0).bitPattern)
        XCTAssertEqual(p.object.vy.bitPattern, Float(0).bitPattern)
        XCTAssertEqual(p.crosshairAdjust, 0)
        // The overload (`FUN_10026ea0`): every field of it, and the glow triple / tint it drives.
        XCTAssertFalse(p.overloadActive)
        XCTAssertEqual(p.overloadPhase, 0)
        XCTAssertEqual(p.overloadGlow.bitPattern, Float(0).bitPattern)
        XCTAssertEqual([p.overloadLast, p.overloadInterval, p.overloadCount], [0, 0, 0])
        XCTAssertFalse(p.object.hideSprite)
        XCTAssertEqual(p.object.glow.bitPattern, Float(0).bitPattern)
        XCTAssertEqual(p.object.glowTarget.bitPattern, Float(0).bitPattern)
        XCTAssertEqual(p.object.glowStep.bitPattern, Float(0).bitPattern)
        XCTAssertEqual(p.object.glowTintColour, 0x7fff)
        XCTAssertFalse(p.object.hitGlowOn)
        // The ship sprite (sector 2's forced Bacta Gun is the effective air weapon) and its size.
        let air = p.handler.effectiveAir
        XCTAssertEqual(air.id, try weapon("aibg").id)
        XCTAssertEqual(p.object.face, air.player1AppearanceFace)
        XCTAssertEqual(p.object.frame, 0)
        XCTAssertEqual(p.lastBankingTick, 0)
        XCTAssertEqual(p.object.layer, FourCC("play"))
        XCTAssertFalse(p.object.sizeDirty)
        let size = Player.frameSize(s.game.assets, air.player1AppearanceFace, 0, p.object.scale)
        XCTAssertGreaterThan(size.0, 0)
        XCTAssertEqual([p.object.scaledWidth, p.object.scaledHeight], [size.0, size.1])
        XCTAssertEqual([p.object.halfWidth, p.object.halfHeight], [size.0 / 2, size.1 / 2])
        let f = s.game.assets.floats
        XCTAssertEqual(p.object.visibility.bitPattern, f[163].bitPattern)
        XCTAssertEqual(p.object.visibilityTarget.bitPattern, f[164].bitPattern)
        XCTAssertEqual(p.object.visibilityStep.bitPattern, f[165].bitPattern)
        // The integrity tick: 0 + the level start's draw (10026a9c..10026aec), replayed from the generator snapshot.
        XCTAssertEqual(p.integrityPasses, 0)
        let draw = try XCTUnwrap(replayedIntegrityDraw(from: rngBefore, to: s.rng, inGame: 1))
        XCTAssertEqual(p.integrityCheckTick, 0 + draw, "0 + R(400, 2000) (10026ae4)")
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
        XCTAssertEqual(h.crosshair.visibility.bitPattern, Float(0).bitPattern)
        XCTAssertEqual(h.crosshair.visibilityTarget.bitPattern, Float(100).bitPattern)
        XCTAssertEqual(h.crosshair.visibilityStep.bitPattern, h.crosshairFadeInRate.bitPattern)

        // Two players: P2 draws its R(400, 2000) but does not keep it (10026aac..10026ab8 — only P1 writes +0x234 /
        // +0x238), and P2, waiting to respawn, brings its poked buttons and crosshair lock to the reset.
        var duo = try XCTUnwrap(lastPassBeforeTransition(try session(sector: 1, players: 2)))
        XCTAssertTrue(duo.players[0].inGame && duo.players[1].inGame)
        XCTAssertTrue(duo.players[1].handler.crosshairShown, "else FUN_1003bab0 does nothing (1003bab0..1003bab8)")
        duo.game.players[1].lifeState = 2
        duo.game.players[1].stateEntered = duo.gameTime                     // no respawn in the crossing tick
        duo.game.players[1].integrityCheckTick = 4321
        duo.game.players[1].integrityPasses = 3
        duo.game.players[1].handler.previousFireGround = true
        duo.game.players[1].handler.previousFireAir = true
        duo.game.players[1].handler.previousSelect = true
        duo.game.players[1].handler.setCrosshairLock(true)
        XCTAssertTrue(duo.players[1].handler.crosshairLocked)
        let duoTick = tickWithoutCrossing(duo).players[1]
        XCTAssertEqual(duoTick.lifeState, 2)
        XCTAssertTrue(duoTick.handler.crosshairLocked, "no handler tick for P2 in state 2")
        XCTAssertTrue(duoTick.handler.previousFireGround && duoTick.handler.previousFireAir
                      && duoTick.handler.previousSelect)
        let duoRng = duo.rng
        cross(&duo)
        let p1 = duo.players[0], p2 = duo.players[1]
        let p1Draw = try XCTUnwrap(replayedIntegrityDraw(from: duoRng, to: duo.rng, inGame: 2))
        XCTAssertEqual(p1.integrityCheckTick, 0 + p1Draw)
        XCTAssertEqual(p1.integrityPasses, 0)
        XCTAssertEqual(p2.integrityCheckTick, 4321, "P2's draw is not kept (10026ab4)")
        XCTAssertEqual(p2.integrityPasses, 3)
        XCTAssertEqual(p2.lifeState, 2)
        XCTAssertEqual(p2.stateEntered, 0)
        XCTAssertFalse(p2.handler.crosshairLocked, "1003b138..1003b140")
        XCTAssertFalse(p2.handler.previousFireGround || p2.handler.previousFireAir || p2.handler.previousSelect)
        XCTAssertEqual(p2.object.x.bitPattern, Float(p2.definition.entryMultiStartX).bitPattern)
        XCTAssertEqual(p2.object.y.bitPattern, Float(p2.definition.entryMultiStartY).bitPattern)
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

        // 1 → 2: the forced Bacta Gun; the ground weapon carried (the reset swaps it only for a pending one,
        // 1003b0ac..1003b0d0); the shipped data has one ground weapon, `plbo`. A pending ground weapon is not reachable
        // in release: `FUN_1003b180(h, 'PEAG', …)` is called only by the reset and the ground power-up's end (both
        // apply an existing pending one) and by `FUN_10029c00`, whose only callers are the unregistered debug command
        // PLAYER GROUNDWEP (10008490) — and with one ground weapon there is nothing to switch to anyway.
        let grounds = try assets().definitions.weapons.filter { $0.type == FourCC("PEAG") }.map(\.id)
        XCTAssertEqual(grounds, [FourCC("plbo")])
        var s = try XCTUnwrap(lastPassBeforeTransition(try session(sector: 1)))
        XCTAssertEqual(s.players[0].handler.air.id, aiic.id)
        XCTAssertEqual(s.players[0].handler.ground.id, FourCC("plbo"))
        XCTAssertNil(s.players[0].handler.pendingGround)
        cross(&s)
        XCTAssertEqual(s.players[0].handler.air.id, aibg.id, "entering sector 2")
        XCTAssertEqual(s.players[0].handler.ground.id, FourCC("plbo"), "the ground weapon carried")
        XCTAssertNil(s.players[0].handler.pendingGround)

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

        // 5 → 6: no match — the current weapon kept, and a pending one kept, not applied.
        s = try XCTUnwrap(lastPassBeforeTransition(try session(sector: 5)))
        s.game.players[0].handler.air = aibg
        s.game.players[0].handler.pendingAir = aiic
        s.game.players[0].handler.airPower = charging
        s.game.players[0].handler.airPower.start = s.gameTime
        s.game.players[0].handler.airPower.lastStep = s.gameTime
        cross(&s, keys: fire)
        XCTAssertEqual(s.players[0].handler.air.id, aibg.id, "sector 6 keeps the current air weapon")
        XCTAssertEqual(s.players[0].handler.pendingAir?.id, aiic.id, "kept, not applied (1003b0ec beq 1003b138)")
        XCTAssertEqual(s.players[0].handler.airPower, WeaponHandler.PowerUpState())
        XCTAssertEqual(s.players[0].handler.effectiveAir.id, aiic.id)
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
    /// (`FUN_10031400`: +0x12e = +0x12f = +0xc4), yet the score bar's level start copies its score and lives into
    /// that record like any player's (1003160c..1003167c: `FUN_100299f0` / `FUN_10026d50` for both, unconditional) —
    /// a copy the per-tick update never makes for an out player (`FUN_100317e0` skips it), so it is seen only here.
    /// Ruling 6's quirk in the same crossing: P1, caught dying (state 3), still has +0xc4 = 1, so it is put back to
    /// state 2 at game time 0 with no life taken, and plays on; and (appendix A §5 item 6) a P1 in state 1 with
    /// 0 lives, not yet out of the game, is revived the same way and plays on with 0 lives.
    func testDeadPlayerStaysOut() throws {
        var s = try session(sector: 1, players: 2)
        // P2 eliminated, as the life-state step leaves it (1002a264): out of lives, state 1, out of the game.
        s.game.players[1].lives = 0
        s.game.players[1].lifeState = 1
        s.game.players[1].inGame = false
        s.game.players[1].shield = 0
        var pre = try XCTUnwrap(lastPassBeforeTransition(s))
        XCTAssertFalse(pre.scoreBar.records[1].drawActive, "retired by the score bar's update")
        // P2's score, poked: its record still holds the set-up's copy (score 0, 3 lives).
        pre.game.players[1].score = 4_321
        XCTAssertEqual(pre.scoreBar.records[1].lastScore, 0)
        XCTAssertEqual(pre.scoreBar.records[1].lastLives, 3)
        let atTransition = pre                                               // P1 alive, for the state-1 variant
        // P1 put into its dying state (3) just before the crossing pass. A poke: in play the level end makes in-game
        // players invulnerable (10006f28), so a death at the transition must have begun before the level end
        // (appendix A §5 item 6); the poke stands in for that.
        let lives = pre.players[0].lives
        pre.game.killPlayer(0, now: pre.gameTime)
        XCTAssertEqual(pre.players[0].lifeState, 3)
        XCTAssertTrue(pre.players[0].inGame)

        // The tick's own draws, measured on a copy whose coin tally is held one more tick (no transition); the same
        // copy shows the tick's score-bar update leaves the out player's record alone.
        let held = tickWithoutCrossing(pre)
        let tickDraws = held.rng.draws - pre.rng.draws
        XCTAssertEqual(held.scoreBar.records[1].lastScore, 0, "the update skips an out player")
        XCTAssertEqual(held.scoreBar.records[1].lastLives, 3)

        let p2Before = Self.fields(pre.players[1])
        let coin2Before = pre.game.tally.coin[1]
        var after = pre
        cross(&after)
        XCTAssertEqual(Self.fields(after.players[1]), p2Before, "the out player is not touched")
        XCTAssertEqual(after.game.tally.coin[1], coin2Before)
        XCTAssertFalse(after.scoreBar.records[1].drawActive)
        XCTAssertFalse(after.scoreBar.records[1].pendingRetire)
        XCTAssertEqual(after.scoreBar.records[1].lastScore, 4_321, "copied for every player (10031660..1003166c)")
        XCTAssertEqual(after.scoreBar.records[1].lastLives, 0, "10031670..1003167c")
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

        // The state-1 variant: P1 out of lives in its game-over wait (entered this tick, so the wait cannot end in the
        // crossing tick) still has +0xc4 = 1: revived to state 2 at 0 with 0 lives, and it plays on.
        var last = atTransition
        last.game.players[0].lives = 0
        last.game.players[0].lifeState = 1
        last.game.players[0].stateEntered = last.gameTime
        cross(&last)
        XCTAssertTrue(last.players[0].inGame)
        XCTAssertEqual(last.players[0].lifeState, 2)
        XCTAssertEqual(last.players[0].stateEntered, 0)
        XCTAssertEqual(last.players[0].lives, 0)
        XCTAssertEqual(last.players[0].shield.bitPattern, Float(100).bitPattern)
        XCTAssertTrue(last.scoreBar.records[0].drawActive, "+0x12e = +0x12f = in game")
        XCTAssertEqual(last.scoreBar.records[0].lastLives, 0)
        run(&last, to: 57)
        XCTAssertEqual(last.players[0].lifeState, 4, "it plays on with 0 lives")
        XCTAssertEqual(last.players[0].lives, 0)
        XCTAssertTrue(last.players[0].inGame)
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
        s.game.world.groundCount = 7
        s.game.world.noticesShown = [[1, 2, 3]]
        // Debris, a particle group and a motion blur that outlive the crossing tick's own updates (a rect is never
        // removed before the reset; a group with a start delay > 1 is kept; a blur fading by 1 from 100 is kept).
        s.game.debris.add(MacRect(top: 10, left: 20, bottom: 30, right: 40))
        s.game.particles.groups.append(ParticleGroup(delay: 100, particles: [Particle()]))
        _ = s.game.blurs.emit(MotionBlurRequest(object: s.game.players[0].object, initialVisibility: 100,
                                                visibilityDelta: 1))
        s.game.blurs.limitWarned = true
        // The score bar's followers, away from 0.0.
        s.game.scoreBar.records[0].shownShield = 37
        s.game.scoreBar.records[0].shownPower = 100
        // P2 (not in this game) keeps its coin tally: neither the level start's tally reset nor `FUN_100269a0` reaches it.
        s.game.tally.coin[1].coinValue = 9
        let coin1 = s.game.tally.coin[1]
        // Not reset by any level start (a transition needs someone in game; the latches are session state).
        s.game.flags.noPlayerAlive = true
        s.game.flags.gameOverNoticed = true
        let p1Active = s.game.flags.p1Active
        let tickOnly = tickWithoutCrossing(s)
        XCTAssertEqual(tickOnly.game.debris.count, 1)
        XCTAssertEqual(tickOnly.game.particles.groups.count, 1)
        XCTAssertEqual(tickOnly.game.blurs.list.count, 1)
        XCTAssertEqual(tickOnly.game.blurs.count, 1)
        XCTAssertNotEqual(tickOnly.game.blurs.cachedFree, 0)
        XCTAssertTrue(tickOnly.game.blurs.limitWarned)
        XCTAssertTrue(tickOnly.game.blurs.inUse.contains(true))
        XCTAssertEqual(tickOnly.game.world.groundCount, 7)
        XCTAssertFalse(tickOnly.game.world.noticesShown.isEmpty)
        XCTAssertNotEqual(tickOnly.scoreBar.records[0].shownPower.bitPattern, Float(0).bitPattern)
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
        tally.coin[1] = coin1
        XCTAssertEqual(s.game.tally, tally)
        // The score bar's level start.
        let r = s.scoreBar.records[0]
        XCTAssertEqual(r.dirty, .all)
        XCTAssertEqual(r.shownShield.bitPattern, Float(0).bitPattern)
        XCTAssertEqual(r.shownPower.bitPattern, Float(0).bitPattern)
        XCTAssertEqual(r.lastScore, s.players[0].score)
        XCTAssertEqual(r.lastLives, s.players[0].lives)
        XCTAssertTrue(r.drawActive)
        XCTAssertEqual(r.icons, s.players[0].scoreBarIcons(sector: 2), "icons by the new sector (1003151c, G+0x14 = 2)")
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
        XCTAssertEqual(s.game.debris.count, 0, "100067d8")
        XCTAssertEqual(s.game.particles, fresh.game.particles)
        XCTAssertTrue(s.game.particles.groups.isEmpty, "100067e0")
        // The blur pool's slots keep their stale sprites (`FUN_10046d30` frees, never clears): compare the rest.
        let b = s.game.blurs
        XCTAssertTrue(b.list.isEmpty)
        XCTAssertEqual(b.cachedFree, 0, "the level reset's cache 0 (quirk)")
        XCTAssertEqual(b.count, 0)
        XCTAssertFalse(b.limitWarned)
        XCTAssertFalse(b.inUse.contains(true))
        XCTAssertEqual(s.game.mask, fresh.game.mask)

        // Sector 3 → 4: the reward flag CLEARED when the last level was not perfect (10006524..10006528); and the
        // icons by the new sector where the sector changes them (`aiic` leaves the list after sector 3, so with
        // `airg` held sector 3 lists three air weapons and sector 4 two — at 1 → 2 the lists are the same).
        var next = try XCTUnwrap(lastPassBeforeTransition(try session(sector: 3)))
        next.game.flags.rewardArmed = true
        next.game.flags.perfectThisLevel = false
        cross(&next)
        XCTAssertFalse(next.game.flags.rewardArmed)
        XCTAssertFalse(next.game.flags.perfectThisLevel)
        let q = next.players[0]
        XCTAssertEqual(q.handler.effectiveAir.id, FourCC("airg"))
        XCTAssertEqual(next.scoreBar.records[0].icons, q.scoreBarIcons(sector: 4))
        XCTAssertNotEqual(q.scoreBarIcons(sector: 3), q.scoreBarIcons(sector: 4), "so the sector read is pinned")
    }
}
