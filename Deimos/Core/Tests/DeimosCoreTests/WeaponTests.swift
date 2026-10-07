import XCTest
import HectorResources
@testable import DeimosCore

/// The weapon handler (weapons-projectiles.md §2–§4, loose-ends-combat §6, hud-scorebar §3/§6; plan C15):
/// `tickWeapons` through `GameState.updatePlayer`, the launchers, the power-up/overload machine, bombs, the score bar.
final class WeaponTests: XCTestCase {
    /// A `GameState` as `FUN_100051a0` + `FUN_100064d0` leave it at `sector` (`le07`), P1 solo.
    private func world(sector: Int32 = 1, seed: UInt32 = 0x469c2) throws -> GameState {
        let a = try TestAssets.loaded.get()
        var s = GameState(assets: a, prefs: DeimosPrefs.fresh, seed: seed)
        s.flags.numPlayers = 1
        s.flags.sector = sector
        s.flags.level = FourCC("le07")!
        s.scroll.levelStart(rect: MacRect(top: 0, left: 0, bottom: 3600, right: 480))
        try s.setupPlayer(0)
        try s.setupPlayer(1)
        s.playerLevelStart(0)
        s.playerLevelStart(1)
        s.scoreBar.levelStart(players: s.players)
        return s
    }

    /// What one tick did: the entities it created (creation order, unit IDs) and its sound cues.
    private struct TickResult {
        var spawned: [(id: FourCC, e: Entity)]
        var sounds: [SoundCue]
        func ids(_ id: String) -> [Entity] { spawned.filter { $0.id == FourCC(id)! }.map(\.e) }
    }

    /// One tick's player + score-bar part in `FUN_10006b50` order (P1-active gate, P1, P2, score bar); time + 1.
    @discardableResult
    private func tick(_ s: inout GameState, _ input: PlayerInput = []) -> TickResult {
        let first = s.world.nextSerial
        s.cues = CueBuffer()
        if !s.flags.p1Active && s.players[0].lifeState == 4 { s.flags.p1Active = true }
        s.updatePlayer(0, input: input)
        s.updatePlayer(1, input: [])
        s.scoreBar.update(players: s.players)
        s.flags.gameTime += 1
        let units = s.assets.definitions.units
        let made = s.world.entities.indices
            .filter { s.world.inUse[$0] && s.world.entities[$0].serial >= first }
            .map { s.world.entities[$0] }
            .sorted { $0.serial < $1.serial }
            .map { (units[$0.unit].id, $0) }
        return TickResult(spawned: made, sounds: s.cues.sounds)
    }

    /// Ticks with no input until P1 is active; bounded (G11).
    private func toActive(_ s: inout GameState, bound: Int = 200) {
        var n = 0
        while s.players[0].lifeState != 4 {
            tick(&s)
            n += 1
            if n >= bound { XCTFail("P1 never became active within \(bound) ticks"); return }
        }
    }

    /// The request position: the entity's group x, y (`FUN_10033220` `1003351c..1003357c`; placement may offset the
    /// member by its unit's offsets).
    private func groupXY(_ s: GameState, _ e: Entity) -> [Float] {
        guard let g = s.world.groups.first(where: { $0.id == e.groupID }) else { return [] }
        return [g.x, g.y]
    }

    private var ion: WeaponDefinition.PowerUp { get throws { try TestAssets.loaded.get().definitions.weapons[1].powerupAir } }

    func testIonShotSpawns() throws {
        var s = try world()
        toActive(&s)
        XCTAssertEqual(s.players[0].handler.air.id, FourCC("aiic"))
        XCTAssertEqual(s.players[0].object.x, 208); XCTAssertEqual(s.players[0].object.y, 330)
        let r = tick(&s, .fireAir)
        // weapons-projectiles worked example 2: icb (203, 330), icbf (208, 322), icb (212, 330), owner 0.
        XCTAssertEqual(r.spawned.map(\.id.description), ["icb ", "icbf", "icb "])
        XCTAssertEqual(r.spawned.map(\.e.object.x), [203, 208, 212])
        XCTAssertEqual(r.spawned.map(\.e.object.y), [330, 322, 330])
        XCTAssertEqual(r.spawned.map(\.e.ownerPlayer), [0, 0, 0])
        XCTAssertEqual(r.ids("icb ").first?.object.vy, Trig.vector(heading: Trig.internalHeading(0), speed: 10).y)
        XCTAssertEqual(s.players[0].handler.airLaunches, 1)
        XCTAssertEqual(s.players[0].handler.lastAirLaunch, s.flags.gameTime - 1)
        XCTAssertTrue(s.players[0].handler.previousFireAir)
        // The crosshair part of the tick: shown, Plasma Bomb face pbta frame 0, unlocked, no shadow.
        XCTAssertTrue(s.players[0].handler.crosshairShown)
        XCTAssertEqual(s.players[0].handler.crosshair.face, FourCC("pbta"))
        XCTAssertEqual(s.players[0].handler.crosshair.frame, 0)
        XCTAssertFalse(s.players[0].handler.crosshairLocked)
        // FUN_1003bab0: locked → frame 1; unlocked → 0; only while shown.
        s.players[0].handler.setCrosshairLock(true)
        XCTAssertEqual(s.players[0].handler.crosshair.frame, 1); XCTAssertTrue(s.players[0].handler.crosshairLocked)
        tick(&s)
        XCTAssertEqual(s.players[0].handler.crosshair.frame, 0); XCTAssertFalse(s.players[0].handler.crosshairLocked)
        var h = WeaponHandler(); h.ground = s.players[0].handler.ground
        h.setCrosshairLock(true)
        XCTAssertFalse(h.crosshairLocked)
        // Crosshair fade-in after the (re)spawn reset: visibility 0 → 100 by flli 149 (6) per handler tick
        // (`FUN_10012750` at `1003ba2c`), counted from the respawn tick's own handler tick.
        var f = try world()
        toActive(&f)
        let rate = f.assets.floats[149]
        XCTAssertEqual(rate, 6)
        var seen: [Float] = [f.players[0].handler.crosshair.visibility]
        for _ in 0..<17 { tick(&f); seen.append(f.players[0].handler.crosshair.visibility) }
        XCTAssertEqual(seen, (1...18).map { min(Float($0) * 6, 100) })
        // Bacta Gun (sector 2): SetHeading TRUE records carry their angle into +0x138; the flash `bagl` does not.
        var b = try world(sector: 2)
        toActive(&b)
        XCTAssertEqual(b.players[0].handler.air.id, FourCC("aibg"))
        let r2 = tick(&b, .fireAir)
        XCTAssertEqual(r2.spawned.map(\.id.description), ["bagb", "bagl", "bagb", "bagb", "bagb", "bagb", "bagb", "bagb"])
        XCTAssertEqual(r2.ids("bagb").map(\.heading), [3, 6, 9, 357, 354, 351, 0])
        XCTAssertEqual(r2.ids("bagb").map { [$0.object.x, $0.object.y] }, [[211, 320], [214, 322], [217, 327], [205, 320],
                                                               [202, 322], [199, 327], [208, 319]])
    }

    func testAirEdgeAndCooldown() throws {
        var s = try world()
        toActive(&s)
        let t = s.flags.gameTime
        // delay 4: a shot needs now > last + 4 and fire air up on the previous tick → spacing 5 (no buffering).
        let pattern: [(PlayerInput, Int)] = [(.fireAir, 3), ([], 0), (.fireAir, 0), ([], 0), ([], 0), (.fireAir, 3)]
        for (k, (input, n)) in pattern.enumerated() {
            XCTAssertEqual(tick(&s, input).spawned.count, n, "tick t+\(k)")
        }
        XCTAssertEqual(s.players[0].handler.lastAirLaunch, t + 5)
        // Holding never refires (autoRepeat FALSE).
        for k in 6..<14 { XCTAssertEqual(tick(&s, .fireAir).ids("icb ").count, 0, "held t+\(k)") }
        XCTAssertEqual(s.players[0].handler.airLaunches, 2)
        // A fresh press exactly at last + 4 is dropped, at last + 5 it fires.
        s.players[0].handler.lastAirLaunch = s.flags.gameTime - 4
        tick(&s)
        s.players[0].handler.lastAirLaunch = s.flags.gameTime - 4
        XCTAssertEqual(tick(&s, .fireAir).spawned.count, 0)
        tick(&s)
        s.players[0].handler.lastAirLaunch = s.flags.gameTime - 5
        XCTAssertEqual(tick(&s, .fireAir).spawned.count, 3)
    }

    func testPowerUpActivationAndLevels() throws {
        var s = try world()
        toActive(&s)
        let pu = try ion
        XCTAssertEqual([pu.timeUntilActivation, pu.timeBetweenPowerLevelChanges, pu.maxPowerLevel], [15, 2, 20])
        let t = s.flags.gameTime
        for k in 0..<14 {
            let r = tick(&s, .fireAir)
            XCTAssertEqual(r.ids("icpo").count, 0, "t+\(k)")
            XCTAssertEqual(s.players[0].handler.airPower.state, 0)
            XCTAssertEqual(s.players[0].handler.airPower.held, Int32(k + 1))
        }
        // The 15th held tick (t + 14) activates: icpo at the ship, owned, its serial kept; state 1 from T0.
        let r = tick(&s, .fireAir)
        let t0 = t + 14
        let icpo = try XCTUnwrap(r.ids("icpo").first)
        XCTAssertEqual(groupXY(s, icpo), [208, 330])
        XCTAssertEqual(icpo.ownerPlayer, 0)
        var a = s.players[0].handler.airPower
        XCTAssertEqual(a.state, 1); XCTAssertEqual(a.start, t0); XCTAssertEqual(a.serial, icpo.serial)
        XCTAssertEqual(a.held, 0); XCTAssertEqual(a.level, 0); XCTAssertEqual(a.percent, 0)
        XCTAssertEqual(a.lastStep, t0); XCTAssertEqual(a.lastRelease, t0)
        // Level k at T0 + 3k, percent = frsp(100.0 · (k / 20)) = 5k %.
        for tt in (t0 + 1)...(t0 + 60) {
            tick(&s, .fireAir)
            a = s.players[0].handler.airPower
            let k = (tt - t0) / 3
            XCTAssertEqual(a.level, k, "level at T0+\(tt - t0)")
            let q: Float = Float(k) / 20
            XCTAssertEqual(a.percent.bitPattern, Float(100.0 * Double(q)).bitPattern, "percent at T0+\(tt - t0)")
            XCTAssertEqual(a.percent, Float(5 * k), accuracy: 1e-4)
            XCTAssertEqual(s.players[0].handler.powerPercent, a.percent)
        }
        XCTAssertEqual(a.percent, 100); XCTAssertEqual(a.lastStep, t0 + 60)
        // T0 + 63: level 21 clamped to 20 (DoRelease FALSE → keeps charging); +0x1c not updated, so it re-clamps.
        for _ in 0..<6 { tick(&s, .fireAir) }
        a = s.players[0].handler.airPower
        XCTAssertEqual(a.level, 20); XCTAssertEqual(a.percent, 100); XCTAssertEqual(a.lastStep, t0 + 60)
        XCTAssertEqual(a.state, 1)
        // The percent's clamps: < 1.0 → 0.0, > 100.0 → 100.0.
        XCTAssertEqual(GameState.powerPercent(level: 1, max: 200), 0)        // 0.5 %
        XCTAssertEqual(GameState.powerPercent(level: 2, max: 200), 1)
        XCTAssertEqual(GameState.powerPercent(level: 30, max: 20), 100)
        // max 0: 0 / 0 = NaN fails `fcmpo; bge` (unordered) → 0.0; 1 / 0 = +inf → 100.0.
        XCTAssertEqual(GameState.powerPercent(level: 0, max: 0).bitPattern, Float(0).bitPattern)
        XCTAssertEqual(GameState.powerPercent(level: 1, max: 0), 100)
    }

    func testOverloadTimeline() throws {
        var s = try world()
        toActive(&s)
        let t = s.flags.gameTime
        let t0 = t + 14
        let sOver = t0 + 181                                                 // OverloadTime 180: now > T0 + 180
        var warnings: [Int32] = []
        var death: Int32?
        var n = 0
        while death == nil {
            let now = s.flags.gameTime
            let r = tick(&s, .fireAir)
            if now == sOver - 1 {
                XCTAssertEqual(s.players[0].handler.airPower.state, 1)
                XCTAssertFalse(s.players[0].overloadActive)
            }
            if now == sOver {
                XCTAssertEqual(s.players[0].handler.airPower.state, 2)     // code 1 → the player's warning
                XCTAssertEqual(s.players[0].handler.airPower.start, sOver)
                XCTAssertTrue(s.players[0].overloadActive)
                XCTAssertEqual(s.players[0].handler.airPower.level, 20)    // frozen in state 2
            }
            if r.sounds.contains(where: { $0.id == FourCC("wewa") }) { warnings.append(now - sOver) }
            if s.players[0].lifeState == 3 { death = now - sOver }
            n += 1
            if n > 400 { XCTFail("no overload death within 400 ticks"); return }
        }
        // weapons-projectiles §2.6 / worked example 4b: flashes S+9 … S+48 with wewa, death at S+54.
        XCTAssertEqual(warnings, [9, 17, 24, 30, 36, 42, 48])
        XCTAssertEqual(death, 54)
        XCTAssertEqual(sOver - t, 195)
        // Photon Beam (sector 5): OverloadTime 0 → the `cmpwi r3,0; ble` gate (`1003c230..1003c238`) never overloads.
        var p = try world(sector: 5)
        toActive(&p)
        XCTAssertEqual(p.players[0].handler.air.powerupAir.overloadTime, 0)
        for _ in 0..<(14 + 300) { tick(&p, .fireAir) }
        XCTAssertEqual(p.players[0].handler.airPower.state, 1)
        XCTAssertEqual(p.players[0].handler.airPower.level, 22)
        XCTAssertFalse(p.players[0].overloadActive)
        XCTAssertEqual(p.players[0].lifeState, 4)
    }

    func testReleaseStream() throws {
        var s = try world()
        toActive(&s)
        let t = s.flags.gameTime
        for _ in 0..<(14 + 66) { tick(&s, .fireAir) }                        // to T0 + 65: level 20
        XCTAssertEqual(s.players[0].handler.airPower.level, 20)
        let serial = s.players[0].handler.airPower.serial
        let slot = try XCTUnwrap(s.world.entities.indices.first { s.world.inUse[$0] && s.world.entities[$0].serial == serial })
        // An overload warning running is cancelled by the release (code 2).
        s.players[0].overloadActive = true
        let r0 = s.flags.gameTime
        XCTAssertEqual(r0, t + 80)
        var stream: [Int32] = []
        var bound = 0
        while s.flags.gameTime <= r0 + 40 {
            let now = s.flags.gameTime
            let r = tick(&s)
            if !r.ids("icps").isEmpty {
                XCTAssertEqual(r.ids("icps").count, 1)
                XCTAssertEqual(groupXY(s, r.ids("icps")[0]), [208, 330])
                stream.append(now - r0)
            }
            if now == r0 {
                XCTAssertEqual(s.players[0].handler.airPower.state, 3)
                XCTAssertEqual(s.players[0].handler.airPower.start, r0)
                XCTAssertFalse(s.players[0].overloadActive)
                let e = s.world.entities[slot]
                let u = s.assets.definitions.units[e.unit]
                XCTAssertEqual(u.states[Int(e.state)].stateName, "_Powerup Release, Dwindle & Del")
            }
            if now <= r0 + 38 { XCTAssertEqual(s.players[0].handler.airPower.state, 3, "r+\(now - r0)") }
            if now == r0 + 39 {                                              // level 0 → idle (`1003c35c` before the timing)
                XCTAssertEqual(s.players[0].handler.airPower.state, 0)
                XCTAssertEqual(s.players[0].handler.airPower.start, r0 + 39)
            }
            bound += 1
            if bound > 60 { XCTFail("release loop unbounded"); return }
        }
        // icps at r, r+2, …, r+38 (20, TBRS 1); idle at r+39 — the level ≤ 0 test (`1003c35c..1003c364`) precedes
        // the release timing (review ruling: the bank's worked example 4a "r+40" is wrong; B1 corrects it).
        XCTAssertEqual(stream, (0..<20).map { Int32(2 * $0) })
        XCTAssertEqual(s.players[0].handler.airPower.state, 0)
        XCTAssertEqual(s.players[0].handler.airPower.level, 0)
        XCTAssertEqual(s.players[0].handler.airPower.percent, 0)
        // Releasing at level 0 gives no release spawn: state 3 (step 2) then, in the same tick, the machine's
        // level ≤ 0 test (`1003c35c..1003c364`, before the release timing) returns it to idle.
        for _ in 0..<15 { tick(&s, .fireAir) }                               // activation
        XCTAssertEqual(s.players[0].handler.airPower.state, 1)
        let rel = s.flags.gameTime
        XCTAssertEqual(tick(&s).ids("icps").count, 0)
        XCTAssertEqual(s.players[0].handler.airPower.state, 0)
        XCTAssertEqual(s.players[0].handler.airPower.start, rel)
    }

    func testSelectCycleBySector() throws {
        // weapons-projectiles §2.4 table: the start weapon and the select cycle per sector (list order aibg, aiic,
        // aipb, airg).
        let cases: [(Int32, [String])] = [
            (1, ["aiic", "aiic"]), (2, ["aibg", "aiic", "aibg"]), (3, ["airg", "aibg", "aiic", "airg"]),
            (4, ["airg", "aibg", "airg"]), (5, ["aipb", "airg", "aibg", "aipb"]),
        ]
        for (sector, cycle) in cases {
            var s = try world(sector: sector)
            toActive(&s)
            XCTAssertEqual(s.players[0].handler.air.id.description, cycle[0], "sector \(sector) start")
            for k in 1..<cycle.count {
                let r = tick(&s, [.select, .fireAir])
                XCTAssertEqual(s.players[0].handler.air.id.description, cycle[k], "sector \(sector) select \(k)")
                XCTAssertEqual(r.spawned.count, 0, "a select press suppresses the air shot")
                XCTAssertEqual(r.sounds, [SoundCue(id: FourCC("wesw")!, priority: 75, volume: 100, pitch: 1,
                                                   allowMultiple: true)])
                XCTAssertTrue(s.players[0].handler.iconsDirty)
                XCTAssertEqual(s.players[0].object.face, s.players[0].handler.air.player1AppearanceFace)
                XCTAssertEqual(tick(&s, .select).sounds.count, 0, "held select is no edge")
                tick(&s)
            }
        }
        // One sector source, game +0x14: a player set up at sector 1 with the game now at sector 2 cycles,
        // equips and previews by 2 (select `1003b8c0`, reset `1003b0dc`, icons `FUN_1003bb40`).
        var d = try world(sector: 1)
        toActive(&d)
        d.flags.sector = 2
        XCTAssertEqual(d.players[0].sector, 1)
        tick(&d, .select)
        XCTAssertEqual(d.players[0].handler.air.id, FourCC("aibg"))          // at 1 it would stay aiic
        d.players[0].handler.air = d.assets.definitions.weapons[1]
        d.players[0].resetHandler(levelStart: true, sector: d.flags.sector)
        XCTAssertEqual(d.players[0].handler.air.id, FourCC("aibg"))          // FUN_1003cd30(2)
        XCTAssertEqual(d.players[0].scoreBarIcons(sector: d.flags.sector).map(\.frame), [1, 0, 0])
        XCTAssertEqual(d.players[0].scoreBarIcons(sector: d.flags.sector)[2], .none)

        // While a power-up runs the switch is pending: the face follows the pending weapon; it is applied when
        // the machine returns to idle.
        var s = try world(sector: 2)
        toActive(&s)
        for _ in 0..<15 { tick(&s, .fireAir) }
        XCTAssertEqual(s.players[0].handler.airPower.state, 1)
        tick(&s, [.fireAir, .select])
        XCTAssertEqual(s.players[0].handler.air.id, FourCC("aibg"))
        XCTAssertEqual(s.players[0].handler.pendingAir?.id, FourCC("aiic"))
        XCTAssertEqual(s.players[0].object.face, FourCC("pl1o"))
        var n = 0
        repeat {
            tick(&s)
            n += 1
            if n > 100 { XCTFail("power-up never idle"); return }
        } while s.players[0].handler.airPower.state != 0
        XCTAssertEqual(s.players[0].handler.air.id, FourCC("aiic"))
        XCTAssertNil(s.players[0].handler.pendingAir)
    }

    func testBombSalvo() throws {
        var s = try world()
        toActive(&s)
        // Sector 1 → min(1, 8) = 1: plbo at the ship + pblf at (x, y − 6), owned.
        var r = tick(&s, .fireGround)
        XCTAssertEqual(r.spawned.map(\.id.description), ["plbo", "pblf"])
        XCTAssertEqual(r.spawned.map(\.e.object.y), [330, 324])
        XCTAssertEqual(r.spawned.map(\.e.ownerPlayer), [0, 0])
        XCTAssertEqual(s.players[0].handler.bombsPending, 0)
        for _ in 0..<6 { XCTAssertEqual(tick(&s, .fireGround).spawned.count, 0) }   // held: no edge

        // Sector 5 → 5 bombs at t, t+2, t+4, t+6, t+8 (delayBetweenLoadLaunches 1), with or without the button.
        s = try world(sector: 5)
        toActive(&s)
        let t = s.flags.gameTime
        var ticks: [Int32] = []
        for k in 0..<12 {
            let now = s.flags.gameTime
            r = tick(&s, k == 0 || k == 3 ? .fireGround : [])
            XCTAssertEqual(r.ids("pblf").count, r.ids("plbo").count)
            if !r.ids("plbo").isEmpty { ticks.append(now - t) }
        }
        XCTAssertEqual(ticks, [0, 2, 4, 6, 8])
        // Next salvo: a fresh press with now > last bomb (t+8) + delay 4 — t+12 is refused, t+15 (after a release) fires.
        XCTAssertEqual(s.flags.gameTime, t + 12)
        XCTAssertEqual(tick(&s, .fireGround).spawned.count, 0)              // t+12 (a press during the salvo, t+3, was ignored)
        XCTAssertEqual(tick(&s, .fireGround).spawned.count, 0)              // t+13 held: no edge
        tick(&s)
        XCTAssertEqual(tick(&s, .fireGround).ids("plbo").count, 1)           // t+15
        XCTAssertEqual(s.players[0].handler.bombsPending, 4)

        // Sectors 9–12: capped at trunc(flli 152) = 8 → t, t+2, …, t+14.
        for sector: Int32 in [9, 12] {
            var c = try world(sector: sector)
            toActive(&c)
            let t9 = c.flags.gameTime
            var bombs: [Int32] = []
            for k in 0..<20 {
                let now = c.flags.gameTime
                if !tick(&c, k == 0 ? .fireGround : []).ids("plbo").isEmpty { bombs.append(now - t9) }
            }
            XCTAssertEqual(bombs, (0..<8).map { Int32(2 * $0) }, "sector \(sector)")
        }

        // Ground and air in one tick: the ground launcher runs first (`1003ba34` before `1003ba4c`).
        var g = try world()
        toActive(&g)
        XCTAssertEqual(tick(&g, [.fireGround, .fireAir]).spawned.map(\.id.description), ["plbo", "pblf", "icb ", "icbf", "icb "])

        // The respawn reset (`FUN_1003af90(h, 0)`): previous-button bytes cleared, the pending ground applied.
        g.players[0].handler.previousFireGround = true
        g.players[0].handler.previousFireAir = true
        g.players[0].handler.previousSelect = true
        g.players[0].handler.bombsPending = 3
        let other = g.assets.definitions.weapons[1]
        g.players[0].handler.pendingGround = other
        g.players[0].resetHandler(levelStart: false)
        XCTAssertFalse(g.players[0].handler.previousFireGround)
        XCTAssertFalse(g.players[0].handler.previousFireAir)
        XCTAssertFalse(g.players[0].handler.previousSelect)
        XCTAssertEqual(g.players[0].handler.ground.id, other.id)
        XCTAssertNil(g.players[0].handler.pendingGround)
        XCTAssertEqual(g.players[0].handler.bombsPending, 0)
    }

    func testBombSpeedRatio() throws {
        var s = try world()
        toActive(&s)
        let v6 = Trig.vector(heading: Trig.internalHeading(0), speed: 6)
        // Default crosshair (adj 0): ratio 121/121 = 1.0 → plbo speed 6.
        tick(&s)
        XCTAssertEqual(s.players[0].handler.crosshair.y, 330 - 121)
        var bomb = try XCTUnwrap(tick(&s, .fireGround).ids("plbo").first)
        XCTAssertEqual(bomb.object.vy, v6.y)
        XCTAssertEqual(bomb.object.vx, v6.x)
        // adj 44 decays to 40 on the next tick: crosshair y = 330 − 121 + 40; the bomb then flies at 81/121 of 6
        // = 4.02 px/tick (worked example).
        for _ in 0..<6 { tick(&s) }
        s.players[0].crosshairAdjust = 44
        tick(&s)
        XCTAssertEqual(s.players[0].crosshairAdjust, 40)
        XCTAssertEqual(s.players[0].handler.crosshair.y, 249)
        bomb = try XCTUnwrap(tick(&s, .fireGround).ids("plbo").first)
        let ratio: Float = Float(81) / Float(121)
        XCTAssertEqual(bomb.object.vy.bitPattern, (v6.y * ratio).bitPattern)
        XCTAssertEqual(-bomb.object.vy, 4.02, accuracy: 0.005)
        // The ratio uses the handler's y (+0x04, last tick's copy), the request the player's y: make them differ.
        for _ in 0..<12 { tick(&s) }                                         // adj 40 → 0 at −4 per tick
        XCTAssertEqual(s.players[0].handler.crosshair.y, 209)
        s.players[0].handler.y = 350
        bomb = try XCTUnwrap(tick(&s, .fireGround).ids("plbo").first)
        XCTAssertEqual(bomb.object.vy.bitPattern, (v6.y * (Float(141) / Float(121))).bitPattern)
        XCTAssertEqual([bomb.object.x, bomb.object.y], [208, 330])
        // A crosshair below the ship gives 0 (max(0, trunc(h.y − crosshair.y))): the bomb does not move.
        for _ in 0..<6 { tick(&s) }
        s.players[0].handler.crosshair.y = 400
        bomb = try XCTUnwrap(tick(&s, .fireGround).ids("plbo").first)
        XCTAssertEqual(bomb.object.vy, 0)
    }

    func testScoreBarPowerAndIcons() throws {
        var s = try world()
        XCTAssertEqual(s.scoreBar.records[0].icons, [ScoreBarState.Icon(face: FourCC("wesy")!, frame: 0), .none, .none])
        toActive(&s)
        for _ in 0..<15 { tick(&s, .fireAir) }                               // T0 = this last tick
        // Power follower: +2 per tick while active, capped at the handler's percent (5 % at T0+3, 10 % at T0+6).
        var shown: [Float] = []
        for _ in 0..<6 { tick(&s, .fireAir); shown.append(s.scoreBar.records[0].shownPower) }
        XCTAssertEqual(shown, [0, 0, 2, 4, 5, 7])
        XCTAssertTrue(s.scoreBar.records[0].dirty.contains(.weapons))
        // Released: the percent drops 5 per release spawn; the follower falls 4 per tick, floored at the target.
        while s.scoreBar.records[0].shownPower < s.players[0].handler.powerPercent { tick(&s, .fireAir) }
        let before = s.scoreBar.records[0].shownPower
        tick(&s)
        XCTAssertEqual(s.players[0].handler.powerPercent, before - 5)
        XCTAssertEqual(s.scoreBar.records[0].shownPower, before - 4)
        tick(&s)
        XCTAssertEqual(s.scoreBar.records[0].shownPower, before - 5)
        // Slot 2 repeating slot 1 (not slot 0) is blanked: Bacta held at sector 1 → n1 = Ion, n2 = Ion again.
        s.players[0].handler.air = s.assets.definitions.weapons[0]
        s.players[0].handler.pendingAir = nil
        let icons = s.players[0].scoreBarIcons(sector: 1)
        XCTAssertEqual(icons.map(\.frame), [1, 0, 0])
        XCTAssertEqual(icons[2], .none)
        XCTAssertEqual(icons[1].face, FourCC("wesy"))
        // Sector 5 icons: Photon, then the next two selects (Rear, Bacta); after a select they rebuild.
        var s5 = try world(sector: 5)
        let wesy = FourCC("wesy")!
        XCTAssertEqual(s5.scoreBar.records[0].icons.map(\.frame), [2, 3, 1])
        XCTAssertEqual(s5.scoreBar.records[0].icons.map(\.face), [wesy, wesy, wesy])
        toActive(&s5)
        tick(&s5, .select)
        XCTAssertEqual(s5.scoreBar.records[0].icons.map(\.frame), [3, 1, 2])
        XCTAssertTrue(s5.scoreBar.records[0].dirty.contains(.weapons))
    }
}
