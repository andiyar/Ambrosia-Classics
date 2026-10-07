import XCTest
import HectorResources
@testable import DeimosCore

/// The player, complete (player-physics.md §1–§8, scoring-bonuses.md §3–§5, damage-health-death.md §5;
/// plan C14): `GameState.updatePlayer` in the `FUN_10028170` order, hits, death, respawn, scoring.
final class PlayerTests: XCTestCase {
    /// A level-1 `GameState` as `FUN_100051a0` + `FUN_100064d0` leave it: both players set up, level start P1
    /// then P2 at game time 0 (`le07`, sector `sector`), the scroll's level start.
    private func world(players n: UInt8 = 1, sector: Int32 = 1, seed: UInt32 = 0x469c2) throws -> GameState {
        let a = try TestAssets.loaded.get()
        var s = GameState(assets: a, prefs: DeimosPrefs.fresh, seed: seed)
        s.flags.numPlayers = n
        s.flags.sector = sector
        s.flags.level = FourCC("le07")!
        s.scroll.levelStart(rect: MacRect(top: 0, left: 0, bottom: 3600, right: 480))
        try s.setupPlayer(0)
        try s.setupPlayer(1)
        s.playerLevelStart(0)
        s.playerLevelStart(1)
        return s
    }

    /// One tick's player part in `FUN_10006b50` order: the P1-active gate (`10006b9c..10006bc4`), P1, P2;
    /// then game time + 1.
    private func tick(_ s: inout GameState, _ input: PlayerInput = []) {
        if !s.flags.p1Active && s.players[0].lifeState == 4 { s.flags.p1Active = true }
        s.updatePlayer(0, input: input)
        s.updatePlayer(1, input: [])
        s.flags.gameTime += 1
    }

    /// Ticks with no input until P1 is active (the respawn tick included); bounded (G11).
    private func toActive(_ s: inout GameState, bound: Int = 200) {
        var n = 0
        while s.players[0].lifeState != 4 {
            tick(&s)
            n += 1
            if n >= bound { XCTFail("P1 never became active within \(bound) ticks"); return }
        }
    }

    /// The live entities created after serial `after`, in creation (serial) order, as unit IDs.
    private func spawned(_ s: GameState, after: Int32) -> [(id: FourCC, e: Entity)] {
        let units = s.assets.definitions.units
        return s.world.entities.indices
            .filter { s.world.inUse[$0] && s.world.entities[$0].serial >= after }
            .map { s.world.entities[$0] }
            .sorted { $0.serial < $1.serial }
            .map { (units[$0.unit].id, $0) }
    }

    private func bits(_ f: Float) -> UInt32 { f.bitPattern }

    func testHoldUpTenTicks() throws {
        var s = try world()
        toActive(&s)
        XCTAssertEqual(s.players[0].object.x, 208)
        XCTAssertEqual(s.players[0].object.y, 330)
        XCTAssertEqual(s.players[0].object.vy, 0)
        // player-physics.md worked example (float32, plan C14 / leg A m3): step 1.6, cap 7.8.
        let vys: [Float] = [-1.6, -3.2, -4.8, -6.4, -7.8, -7.8, -7.8, -7.8, -7.8, -7.8]
        let ys: [Float] = [328.4, 325.19998, 320.4, 314.0, 306.2, 298.40002, 290.60004, 282.80005, 275.00006,
                           267.20007]
        for k in 0..<10 {
            tick(&s, .up)
            XCTAssertEqual(bits(s.players[0].object.vy), bits(vys[k]), "vy tick \(k + 1)")
            XCTAssertEqual(bits(s.players[0].object.y), bits(ys[k]), "y tick \(k + 1)")
        }
        // Released: decay +1.6 per tick, snapped to 0.0 on tick 15; rest at 252.00006.
        var vy = s.players[0].object.vy, y = s.players[0].object.y
        for k in 11...16 {
            tick(&s)
            if vy < 0 { vy = vy + 1.6; if vy > 0 { vy = 0 } }
            y = y + vy
            XCTAssertEqual(bits(s.players[0].object.vy), bits(vy), "vy tick \(k)")
            XCTAssertEqual(bits(s.players[0].object.y), bits(y), "y tick \(k)")
            if k >= 15 {
                XCTAssertEqual(s.players[0].object.vy, 0, "rest tick \(k)")
                XCTAssertEqual(bits(s.players[0].object.y), bits(252.00006), "rest y tick \(k)")
            }
        }
        XCTAssertEqual(s.players[0].object.x, 208)
        XCTAssertEqual(s.players[0].object.vx, 0)
        XCTAssertEqual(s.players[0].object.frame, 0)                   // no-horizontal table: 0 → 0
    }

    func testClampToArea() throws {
        var s = try world()
        toActive(&s)
        let hw = s.players[0].object.halfWidth, hh = s.players[0].object.halfHeight
        XCTAssertGreaterThan(hw, 0); XCTAssertGreaterThan(hh, 0)
        // Left: x − hw < −32.0 → x = hw − 32, vx = 0 (`10029588..100295b4`).
        s.players[0].object.x = -40; s.players[0].object.vx = 0
        tick(&s, .left)
        XCTAssertEqual(s.players[0].object.x, Float(hw - 32))
        XCTAssertEqual(s.players[0].object.vx, 0)
        // Right: x + hw > W + 32 → x = W − hw + 32 (`100295c0..10029614`), W = 416.
        s.players[0].object.x = 470; s.players[0].object.vx = 0
        tick(&s, .right)
        XCTAssertEqual(s.players[0].object.x, Float(416 - hw + 32))
        XCTAssertEqual(s.players[0].object.vx, 0)
        // Inside both edges: untouched.
        s.players[0].object.x = 200; s.players[0].object.vx = 0
        tick(&s, .right)
        XCTAssertEqual(bits(s.players[0].object.x), bits(Float(200) + 1.6))
        // Top: y − hh < 13 → y = 13 + hh, vy = 0 (`10029664..10029694`).
        s.players[0].object.vx = 0
        s.players[0].object.y = Float(hh) + 13.5; s.players[0].object.vy = 0
        tick(&s, .up)
        XCTAssertEqual(s.players[0].object.y, Float(13 + hh))
        XCTAssertEqual(s.players[0].object.vy, 0)
        // Bottom: y + hh > 480 → y = 480 − hh, vy = 0, pinned (`100296bc..100296f0`) — the crosshair pulls in.
        s.players[0].object.y = 479; s.players[0].object.vy = 0
        let adj0 = s.players[0].crosshairAdjust
        tick(&s, .down)
        XCTAssertEqual(s.players[0].object.y, Float(480 - hh))
        XCTAssertEqual(s.players[0].object.vy, 0)
        XCTAssertEqual(s.players[0].crosshairAdjust, adj0 + 3)
        // The handler copies the clamped position (`FUN_1003bb00`).
        XCTAssertEqual(s.players[0].handler.x, s.players[0].object.x)
        XCTAssertEqual(s.players[0].handler.y, s.players[0].object.y)
    }

    func testCrosshairAdjust() throws {
        var s = try world()
        toActive(&s)
        let hh = s.players[0].object.halfHeight
        let g = s.players[0].handler.ground
        XCTAssertEqual(g.crosshairXOffset, 0); XCTAssertEqual(g.crosshairYOffset, -121)  // Plasma Bomb
        XCTAssertTrue(s.players[0].handler.crosshairShown)
        // Pinned at the bottom, down held: +3 per tick (flli 185), capped at 80 (flli 187).
        s.players[0].object.y = Float(480 - hh)
        var expected: Int32 = 0
        for k in 0..<30 {
            tick(&s, .down)
            expected = min(expected + 3, 80)
            XCTAssertEqual(s.players[0].crosshairAdjust, expected, "down tick \(k)")
            let y = s.players[0].object.y
            XCTAssertEqual(s.players[0].handler.crosshair.y, (y + Float(-121)) + Float(expected))
            XCTAssertEqual(s.players[0].handler.crosshair.x, s.players[0].object.x)
        }
        XCTAssertEqual(s.players[0].crosshairAdjust, 80)
        // Released: −4 per tick (flli 186), floored at 0.
        for k in 0..<25 {
            tick(&s)
            expected = max(expected - 4, 0)
            XCTAssertEqual(s.players[0].crosshairAdjust, expected, "release tick \(k)")
        }
        // Down while not pinned: no adjustment.
        s.players[0].object.y = 300; s.players[0].object.vy = 0
        tick(&s, .down)
        XCTAssertEqual(s.players[0].crosshairAdjust, 0)
        // cy − ch < 0.0 → cy = ch (`10029864..10029894`).
        s.players[0].object.y = Float(13 + hh); s.players[0].object.vy = 0
        tick(&s)
        let ch = s.players[0].handler.crosshair.scaledHeight / 2
        XCTAssertEqual(s.players[0].handler.crosshair.y, Float(ch))
    }

    func testSevenFullHitsDestroy() throws {
        var s = try world()
        toActive(&s)
        let d = s.players[0].definition
        XCTAssertEqual(d.shieldBaseHitPercentage, 15); XCTAssertEqual(d.shieldHitDelay, 1)
        var t = s.flags.gameTime + 100
        let shields: [Float] = [85, 70, 55, 40, 25, 10]
        for k in 0..<6 {
            s.flags.gameTime = t
            s.playerHit(0, damage: 1.0)
            s.playerHit(0, damage: 1.0)                                 // same tick: < lastHit + delay → ignored
            XCTAssertEqual(s.players[0].shield, shields[k], "hit \(k + 1)")
            XCTAssertEqual(s.players[0].lifeState, 4)
            XCTAssertEqual(s.players[0].lastHit, t)
            XCTAssertTrue(s.players[0].hitThisLevel)
            XCTAssertTrue(s.players[0].object.hitGlowOn)
            XCTAssertEqual(s.players[0].object.hitGlowColour, d.hitGlowColor)
            t += 1
        }
        XCTAssertTrue(s.players[0].shieldWarningShown)                  // 10 ≤ 15 → nosw once
        s.flags.gameTime = t
        s.playerHit(0, damage: 1.0)                                     // 10 − 15 = −5 < 0 → destroyed
        XCTAssertEqual(s.players[0].lifeState, 3)
        XCTAssertEqual(s.players[0].stateEntered, t)
        // Not in state 4: ignored.
        s.flags.gameTime = t + 5
        s.playerHit(0, damage: 1.0)
        XCTAssertEqual(s.players[0].lastHit, 0)                         // the death cleared it; no new hit
        // A hit landing exactly on 0 survives; invulnerable → no shield loss but the glow and the timer.
        var u = try world()
        toActive(&u)
        u.players[0].shield = 15
        u.flags.gameTime = 500
        u.playerHit(0, damage: 1.0)
        XCTAssertEqual(u.players[0].shield, 0); XCTAssertEqual(u.players[0].lifeState, 4)
        u.players[0].shield = 50; u.players[0].hitThisLevel = false; u.players[0].invulnerable = true
        u.flags.gameTime = 501
        u.playerHit(0, damage: 1.0)
        XCTAssertEqual(u.players[0].shield, 50); XCTAssertFalse(u.players[0].hitThisLevel)
        XCTAssertEqual(u.players[0].lastHit, 501)
    }

    func testShieldEighthPercent() throws {
        var s = try world()
        s.players[0].shield = 33.3
        XCTAssertEqual(s.players[0].shield, 33.25)                      // stored + 1324366.0: ulp 0.125
        XCTAssertEqual(bits(s.players[0].shield), bits(33.25))
        // `FUN_10027490`: clamp(shield + v, 0, 100); in game only; v == 0 → nothing.
        s.addShield(0, 20)
        XCTAssertEqual(s.players[0].shield, 53.25)
        s.addShield(0, 100)
        XCTAssertEqual(s.players[0].shield, 100)
        s.addShield(0, -250)
        XCTAssertEqual(s.players[0].shield, 0)
        s.players[1].shield = 0
        s.addShield(1, 20)                                              // P2 not in a 1-player game
        XCTAssertEqual(s.players[1].shield, 0)
    }

    func testDeathOrder() throws {
        var s = try world()
        toActive(&s)
        s.flags.gameTime = 300
        s.stepMultiplier(0); s.stepMultiplier(0)                        // ×3, indicator mux3
        let indicator = s.players[0].multiplierIndicator
        XCTAssertNotEqual(indicator, -1)
        s.players[0].money = 67
        s.scoreBar.setShownShield(index: 0, 55); s.scoreBar.setShownPower(index: 0, 40)
        let first = s.world.nextSerial
        s.killPlayer(0)
        let made = spawned(s, after: first)
        let ids = made.map(\.id)
        let death = s.players[0].definition.deathSpawn
        XCTAssertNotEqual(death, .none)
        let coins = ["calg", "cals", "casg", "cass", "cass"].map { FourCC($0)! }
        XCTAssertGreaterThan(ids.count, coins.count)
        XCTAssertEqual(Array(ids.suffix(coins.count)), coins)            // greedy 50/10/5/1, after the death spawn
        XCTAssertTrue(ids.dropLast(coins.count).allSatisfy { $0 == death })
        XCTAssertTrue(made.dropLast(coins.count).allSatisfy { $0.e.ownerPlayer == 0 })
        XCTAssertTrue(made.suffix(coins.count).allSatisfy { $0.e.ownerPlayer == -1 })   // template +0x14 = 0xff
        XCTAssertEqual(s.players[0].money, 0)
        XCTAssertEqual(s.scoreBar.records[0].shownShield, 0)
        XCTAssertEqual(s.scoreBar.records[0].shownPower, 0)
        XCTAssertEqual(s.players[0].lifeState, 3)
        XCTAssertEqual(s.players[0].stateEntered, 300)
        XCTAssertTrue(s.players[0].invulnerable)
        XCTAssertEqual(s.players[0].multiplier, 1)
        let mux = try XCTUnwrap(s.world.entities.indices.first { s.world.entities[$0].serial == indicator })
        XCTAssertTrue(s.world.entities[mux].deleted)
        XCTAssertEqual(s.players[0].lastHit, 0); XCTAssertEqual(s.players[0].lastHitSpawn, 0)
        XCTAssertFalse(s.players[0].shieldWarningShown)
    }

    func testDyingAndRespawn() throws {
        var s = try world()
        // The film read happens only in state 4, after the life-state step of the same tick, and stores the
        // decoded score at the consumed byte (G4.1).
        let index = try RealData.index()
        let film = try Film(data: index.data(for: XCTUnwrap(index.record(type: FourCC("film")!, id: FourCC("de01")!))))
        s.film = FilmCursor(film: film)
        s.flags.filmPlaying = true
        s.players[0].score = 1234
        tick(&s)
        XCTAssertEqual(s.film?.cursors[0], 0)                           // state 2: no read
        toActive(&s)                                                    // the respawn tick reads byte 0
        XCTAssertEqual(s.film?.cursors[0], 1)
        XCTAssertEqual(s.film?.score(player: 0, atRead: 0), 1234)
        XCTAssertFalse(s.flags.p1Active)                               // the gate opens at the top of the next tick
        tick(&s)
        XCTAssertTrue(s.flags.p1Active)
        XCTAssertEqual(s.film?.cursors[0], 2)
        // Death → dying 80 ticks (lives 3 ≠ 1) → lives 2, respawn at T + 81, shield 100.
        let lives = s.players[0].lives
        XCTAssertEqual(lives, 3)
        let t = s.flags.gameTime
        s.killPlayer(0)
        let cursor = s.film?.cursors[0]
        tick(&s)                                                        // at T: still dying
        XCTAssertEqual(s.film?.cursors[0], cursor)                      // no read while dying
        s.flags.gameTime = t + 80
        tick(&s)
        XCTAssertEqual(s.players[0].lifeState, 3)
        XCTAssertEqual(s.scoreBar.records[0].shownShield, 0)
        tick(&s)                                                        // T + 81 > T + 80
        XCTAssertEqual(s.players[0].lifeState, 4)
        XCTAssertEqual(s.players[0].stateEntered, t + 81)
        XCTAssertEqual(s.players[0].lives, lives - 1)
        XCTAssertEqual(s.players[0].shield, 100)
        XCTAssertEqual(s.players[0].object.y, 330)                      // start point; input then moves it
        XCTAssertTrue(s.players[0].appearing)
        XCTAssertTrue(s.players[0].invulnerable)                        // cleared only after 60 ticks
        XCTAssertEqual(s.film?.cursors[0], cursor.map { $0 + 1 })       // reads resume on the respawn tick
        s.flags.gameTime = t + 81 + 60
        tick(&s)
        XCTAssertTrue(s.players[0].invulnerable)                        // not yet: now > enter + 60 is strict
        tick(&s)
        XCTAssertFalse(s.players[0].invulnerable)
        // Last life: finalDyingTime 40 → lives 0 → state 1; gameOverTime 20 later → out of the game.
        s.film = nil; s.flags.filmPlaying = false
        s.players[0].lives = 1
        let u = s.flags.gameTime
        s.killPlayer(0)
        s.flags.gameTime = u + 40
        tick(&s)
        XCTAssertEqual(s.players[0].lifeState, 3)
        tick(&s)
        XCTAssertEqual(s.players[0].lifeState, 1)
        XCTAssertEqual(s.players[0].stateEntered, u + 41)
        XCTAssertEqual(s.players[0].lives, 0)
        s.flags.gameTime = u + 61
        tick(&s)
        XCTAssertTrue(s.players[0].inGame)
        tick(&s)
        XCTAssertFalse(s.players[0].inGame)
        // Gate closed (P1 never active this session): the dying state ends without a lives decrement.
        var g = try world()
        toActive(&g)
        g.flags.p1Active = false
        g.updatePlayer(1, input: [])
        let v = g.flags.gameTime
        g.killPlayer(0)
        g.flags.gameTime = v + 81
        g.updatePlayer(0, input: [])
        XCTAssertEqual(g.players[0].lifeState, 4)
        XCTAssertEqual(g.players[0].lives, 3)
    }

    func testExtraLifeThresholds() throws {
        var s = try world()
        let d = s.players[0].definition
        XCTAssertEqual(d.lifeInitialRequiredScore, 10000); XCTAssertEqual(d.lifeAdditionalRequiredScore, 30000)
        XCTAssertEqual(s.players[0].lives, 3)
        s.addScore(0, 10000)                                            // 10000 is not > 10000
        XCTAssertEqual(s.players[0].lives, 3)
        s.addScore(0, 1)
        XCTAssertEqual(s.players[0].lives, 4)
        XCTAssertEqual(s.players[0].extraLifeThreshold, 40000)
        XCTAssertEqual(s.players[0].extraLifeStep, 10000)
        s.addScore(0, 30000)
        XCTAssertEqual(s.players[0].lives, 5)
        XCTAssertEqual(s.players[0].extraLifeThreshold, 80000)
        XCTAssertEqual(s.players[0].extraLifeStep, 20000)
        s.addScore(0, 100000)                                           // two thresholds crossed: one life per call
        XCTAssertEqual(s.players[0].lives, 6)
        XCTAssertEqual(s.players[0].extraLifeThreshold, 130000)
        s.addScore(0, 1)
        XCTAssertEqual(s.players[0].lives, 7)
        XCTAssertEqual(s.players[0].extraLifeThreshold, 190000)
        XCTAssertEqual(s.players[0].score, 140002)
        // Multiplier applies to positive and negative adds; a negative add never touches lives.
        s.players[0].multiplier = 2
        s.addScore(0, 50)
        XCTAssertEqual(s.players[0].score, 140102)
        s.addScore(0, -10000)
        XCTAssertEqual(s.players[0].score, 120102)
        // Raw (mission bonus): unmultiplied, no life, step = new + flli 182.
        s.addScore(0, 100000, raw: true)
        XCTAssertEqual(s.players[0].score, 220102)
        XCTAssertEqual(s.players[0].lives, 7)
        XCTAssertEqual(s.players[0].extraLifeStep, 230102)
        // At life_MaxNum (10) a crossing advances the threshold but adds nothing.
        s.players[0].lives = 10
        s.players[0].multiplier = 1
        s.addScore(0, 1)
        XCTAssertEqual(s.players[0].lives, 10)
        XCTAssertEqual(s.players[0].extraLifeThreshold, 190000 + 30000 + 230102)
        // Not in game: nothing.
        let p2 = s.players[1].score
        s.addScore(1, 500)
        XCTAssertEqual(s.players[1].score, p2)
    }

    func testMultiplierSteps() throws {
        var s = try world()
        s.stepMultiplier(0)                                             // state 2: no change
        XCTAssertEqual(s.players[0].multiplier, 1)
        toActive(&s)
        XCTAssertEqual(s.players[0].multiplierIndicator, -1)            // ×1 has no indicator
        let names = ["mux2", "mux3", "mux4", "mux5", "muxx"].map { FourCC($0)! }
        var previous: Int32 = -1
        for (k, m) in [UInt8(2), 3, 4, 5, 10].enumerated() {
            s.stepMultiplier(0)
            XCTAssertEqual(s.players[0].multiplier, m)
            let serial = s.players[0].multiplierIndicator
            let i = try XCTUnwrap(s.world.entities.indices.first {
                s.world.inUse[$0] && s.world.entities[$0].serial == serial
            })
            XCTAssertEqual(s.assets.definitions.units[s.world.entities[i].unit].id, names[k])
            XCTAssertEqual(s.world.entities[i].ownerPlayer, 0)
            XCTAssertFalse(s.world.entities[i].deleted)
            if previous != -1 {
                let p = try XCTUnwrap(s.world.entities.indices.first { s.world.entities[$0].serial == previous })
                XCTAssertTrue(s.world.entities[p].deleted)
            }
            previous = serial
        }
        s.stepMultiplier(0)                                             // ×10 is the cap
        XCTAssertEqual(s.players[0].multiplier, 10)
        XCTAssertEqual(s.players[0].multiplierIndicator, previous)
    }

    func testDefenceBonusOnce() throws {
        var s = try world(sector: 3)
        toActive(&s)
        s.players[0].multiplier = 2
        let score = s.players[0].score
        let first = s.world.nextSerial
        s.flags.levelEnding = true
        tick(&s)
        XCTAssertEqual(s.players[0].score, score + 2000 * 3 * 2)        // flli 184 × sector × multiplier
        XCTAssertTrue(s.players[0].hitThisLevel)
        XCTAssertTrue(spawned(s, after: first).contains { $0.id == s.players[0].definition.activeDefenceBonusObject })
        tick(&s)
        XCTAssertEqual(s.players[0].score, score + 12000)               // once per level
        // A player hit this level earns nothing.
        var u = try world(sector: 3)
        toActive(&u)
        u.players[0].hitThisLevel = true
        let before = u.players[0].score
        u.flags.levelEnding = true
        tick(&u)
        XCTAssertEqual(u.players[0].score, before)
    }
}
