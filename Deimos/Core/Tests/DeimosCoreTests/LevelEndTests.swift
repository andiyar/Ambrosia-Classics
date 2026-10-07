import XCTest
import HectorResources
@testable import DeimosCore

/// End of level (scoring-bonuses.md §6, level-scroll-objects.md §8, engine-loop.md §3; plan C17): the accuracy tier
/// `FUN_100072c0` and tally `FUN_100075e0`, the coin bonus `FUN_10027670` / `FUN_10027930`, the level-end and
/// game-over branches of `FUN_10006b50` and level complete `FUN_10007170`.
final class LevelEndTests: XCTestCase {
    /// A level-1 `GameState` (both players set up, level start at game time 0, sector `sector`), running, with the
    /// accuracy tally reset as `FUN_100064d0` leaves it (`FUN_10007280`).
    private func world(players n: UInt8 = 1, sector: Int32 = 1) throws -> GameState {
        let a = try TestAssets.loaded.get()
        var s = GameState(assets: a, prefs: DeimosPrefs.fresh, seed: 0x469c2)
        s.flags.numPlayers = n
        s.flags.sector = sector
        s.flags.level = FourCC("le07")!
        s.flags.running = true
        s.scroll.levelStart(rect: MacRect(top: 0, left: 0, bottom: 3600, right: 480))
        try s.setupPlayer(0)
        try s.setupPlayer(1)
        s.playerLevelStart(0)
        s.playerLevelStart(1)
        s.tally.reset()
        return s
    }

    /// The gaso index of every sound cue recorded since `from`.
    private func soundIndices(_ s: GameState, from: Int = 0) -> [Int] {
        s.cues.sounds[from...].map { c in s.assets.sounds.firstIndex(of: c.id) ?? -1 }
    }

    /// The live entities' unit IDs created at or after serial `after`.
    private func spawned(_ s: GameState, after: Int32) -> [FourCC] {
        let units = s.assets.definitions.units
        return s.world.entities.indices
            .filter { s.world.inUse[$0] && s.world.entities[$0].serial >= after }
            .sorted { s.world.entities[$0].serial < s.world.entities[$1].serial }
            .map { units[s.world.entities[$0].unit].id }
    }

    /// Runs the accuracy tally from game time `from` until it reports done; returns the done tick (G11 bound).
    @discardableResult
    private func runTally(_ s: inout GameState, from: Int32, bound: Int32 = 2000,
                          each: (inout GameState, Int32) -> Void = { _, _ in }) -> Int32? {
        var t = from
        while t < from + bound {
            let done = s.accuracyTally(now: t)
            each(&s, t)
            if done { return t }
            t += 1
        }
        XCTFail("accuracy tally not done within \(bound) ticks")
        return nil
    }

    // MARK: - FUN_100072c0

    func testAccuracyTiers() throws {
        // (destroyed, created, sector) → (tier bonus = flli 189…194 × sector, step, percent, 100 % flag).
        let cases: [(Int32, Int32, Int32, Int32, Int32, Int32, Bool)] = [
            (12, 12, 1, 5000, 100, 100, true),     // ≥ 100 → flli 189
            (19, 20, 3, 6000, 120, 95, false),     // 0.95f × 100.0 → 95.0f ≥ 95 → flli 190 × 3; step trunc(6000 × 0.02f)
            (1899, 2000, 1, 1000, 100, 94, false), // 94.95 < 95 → flli 191 (the untruncated float decides)
            (17, 20, 1, 500, 100, 85, false),      // flli 192
            (10, 12, 1, 250, 100, 83, false),      // 83.33 → flli 193 (worked example)
            (15, 20, 1, 0, 0, 75, false),          // < 80 → flli 194 = 0 → step 0
            (0, 0, 2, 0, 0, 0, false),             // nothing created → 0.0 %
        ]
        for (d, c, sector, bonus, step, pct, perfect) in cases {
            var s = try world(sector: sector)
            s.flags.groundDestroyed = d
            s.flags.groundCreated = c
            s.accuracyTier(now: 500)
            XCTAssertEqual(s.tally.bonusRemaining, bonus, "\(d)/\(c) sector \(sector)")
            XCTAssertEqual(s.tally.bonusStep, step, "\(d)/\(c)")
            XCTAssertEqual(s.tally.percent, pct, "\(d)/\(c)")
            XCTAssertEqual(s.flags.perfectThisLevel, perfect, "\(d)/\(c)")
            XCTAssertEqual(s.tally.state, 1)
            XCTAssertEqual(s.tally.stateTimer, 500)
            XCTAssertEqual(s.tally.tickTimer, 500)
            XCTAssertEqual(s.tally.text, s.assets.gameStrings[11])      // "Ground Accuracy:   "
            XCTAssertEqual(s.tally.alpha, 32)                            // untouched (FUN_10007280's 0x20)
        }
    }

    // MARK: - FUN_100075e0

    func testTallyOvershoot() throws {
        // Tier 250 at sector 1: bonus 250, step max(trunc(5.0), 100) = 100 → 3 payments of the full step = 300.
        var s = try world(sector: 1)
        s.players[0].multiplier = 2
        s.flags.groundDestroyed = 16
        s.flags.groundCreated = 20
        s.accuracyTier(now: 0)
        let before = s.players[0].score
        runTally(&s, from: 1)
        XCTAssertEqual(s.players[0].score - before, 300 * 2)             // × multiplier
        XCTAssertEqual(s.tally.bonusRemaining, 0)                         // clamped ≥ 0
        XCTAssertEqual(s.players[1].score, 0)                             // P2 not in game → FUN_10029a10 returns
    }

    func testAccuracyTallyTimeline() throws {
        // As read (FUN_100075e0, every wait `timer + N < now`): tier at T0 = 1000 (state 1, both timers T0); sector 1,
        // 16/20 → bonus 250, step 100.
        var s = try world(sector: 1)
        s.flags.groundDestroyed = 16
        s.flags.groundCreated = 20
        s.accuracyTier(now: 1000)
        var transitions: [Int32: UInt8] = [:]
        var payments: [Int32] = []
        var alphas: [Int32: Int32] = [:]
        var last = s.tally.state
        var remaining = s.tally.bonusRemaining
        let done = runTally(&s, from: 1001) { s, t in
            if s.tally.state != last { transitions[t] = s.tally.state; last = s.tally.state }
            if s.tally.bonusRemaining != remaining { payments.append(t); remaining = s.tally.bonusRemaining }
            alphas[t] = s.tally.alpha
        }
        // 1 → 2 at T0 + 61 (flli 195 = 60); 2 → 3, 3 → 4, 4 → 5, 5 → 6 every 21 ticks (flli 197 = 20).
        // State 6 pays at once (tick timer = T0, flli 198 = 2) and every 3rd tick; remaining 0 → 7 the next tick;
        // 7 → 8 after flli 201 = 20; state 8 reports done after flli 202 = 20 (no mission bonus).
        XCTAssertEqual(transitions, [1061: 2, 1082: 3, 1103: 4, 1124: 5, 1145: 6, 1153: 7, 1174: 8])
        XCTAssertEqual(payments, [1146, 1149, 1152])
        XCTAssertEqual(done, 1195)
        XCTAssertEqual(s.tally.state, 8)                                  // stays 8, keeps reporting done
        XCTAssertTrue(s.accuracyTally(now: 1196))
        // Fade in by flli 203 = 3 per state-2 tick from 32: 29 at 1062 … 2 at 1071, 0 from 1072.
        XCTAssertEqual(alphas[1061], 32)
        XCTAssertEqual(alphas[1062], 29)
        XCTAssertEqual(alphas[1071], 2)
        XCTAssertEqual(alphas[1072], 0)
        XCTAssertEqual(alphas[1174], 0)
        // Fade out by flli 204 = 3 per state-8 tick from 1175, capped at 32.
        XCTAssertEqual(alphas[1175], 3)
        XCTAssertEqual(alphas[1184], 30)
        XCTAssertEqual(alphas[1185], 32)
        // Sounds: moco (gaso 20) at 1061, 1082, 1103, 1124 (bonus > 0, not 100 %), and at each payment.
        XCTAssertEqual(soundIndices(s), [20, 20, 20, 20, 20, 20, 20])
        XCTAssertTrue(s.cues.sounds.allSatisfy { $0.priority == 50 && $0.volume == 100 && !$0.allowMultiple })
        // The text: "%s%i%%%s%i" with the remainder.
        XCTAssertEqual(String(decoding: s.tally.text, as: UTF8.self), "Ground Accuracy:   80%   Bonus:  0")
        // The finale (G+0x0d): state 1 waits flli 196 = 1200 → 2 at T0 + 1201. Bonus 0: state 4 plays nobo (gaso 21),
        // state 5 writes "None!" and state 6 goes to 7 at once.
        var f = try world(sector: 1)
        f.flags.allLevels = true
        f.accuracyTier(now: 0)
        var firstTwo: Int32?
        let fDone = runTally(&f, from: 1, bound: 3000) { s, t in if firstTwo == nil && s.tally.state == 2 { firstTwo = t } }
        XCTAssertEqual(firstTwo, 1201)
        XCTAssertEqual(fDone, 1328)                                       // 1201 + 4 × 21, 7 at once, + 21, + 21
        XCTAssertEqual(soundIndices(f), [20, 20, 20, 21])
        XCTAssertEqual(String(decoding: f.tally.text, as: UTF8.self), "Ground Accuracy:   0%   Bonus:  None!")
    }

    // MARK: - FUN_10027670 / FUN_10027930

    func testCoinBonusSteps() throws {
        // money 30 → value 100 (flli 170 = 0), bonus 3000, step max(trunc(60.0), 100) = 100 → 30 ticks;
        // money 60 → bonus 6000, step trunc(120.0) = 120 → 50 ticks. Both pay exactly the bonus.
        for (money, step, ticks) in [(Int32(30), Int32(100), 30), (60, 120, 50)] {
            var s = try world(sector: 3)
            s.players[0].money = money
            let before = s.players[0].score
            let first = s.world.nextSerial
            XCTAssertFalse(s.coinTallyStarted(0))
            XCTAssertTrue(s.coinTallySetup(0, now: 0, stacked: false))
            XCTAssertTrue(s.coinTallyStarted(0))
            let c = s.tally.coin[0]
            XCTAssertEqual(c.coinValue, 100)                              // not sector-scaled
            XCTAssertEqual(c.moneyAtStart, money)
            XCTAssertEqual(c.bonusRemaining, money * 100)
            XCTAssertEqual(c.bonusStep, step)
            XCTAssertEqual(c.textYOffset, 0)
            XCTAssertEqual(spawned(s, after: first), [FourCC("p1mc")!])   // active_MoneyCounterSpawn_ID
            var paid = 0
            var t: Int32 = 1
            var lastScore = before
            while !s.coinTally(0, now: t) {
                if s.players[0].score != lastScore {
                    XCTAssertEqual(s.players[0].score - lastScore, step)
                    lastScore = s.players[0].score
                    paid += 1
                }
                t += 1
                if t > 3000 { XCTFail("coin tally not done"); break }
            }
            XCTAssertEqual(paid, ticks, "money \(money)")
            XCTAssertEqual(s.players[0].score - before, money * 100)
            XCTAssertEqual(s.players[0].money, money - Int32(ticks))      // money −1 per payment tick
            // States 1 (10) → 2 → 3 → 4 → 5 (20 each) → 6: first payment at 1 + 11 + 4·21 = 96, every 3rd tick; the
            // tick after the last → 7 (30) → 8 (20) → done.
            let lastPay = 96 + 3 * Int32(ticks - 1)
            XCTAssertEqual(t, lastPay + 1 + 31 + 21, "money \(money)")
            XCTAssertEqual(String(decoding: s.tally.coin[0].text, as: UTF8.self),
                           "Coin Bonus:   \(money)  x  100  =  0")
        }
        // The second counter stacks: +0x1f8 = flli 181 and the request 70 lower.
        var s = try world(players: 2)
        s.players[1].money = 5
        let first = s.world.nextSerial
        XCTAssertTrue(s.coinTallySetup(1, now: 0, stacked: true))
        XCTAssertEqual(s.tally.coin[1].textYOffset, 70)
        let e = s.world.entities.indices.first { s.world.inUse[$0] && s.world.entities[$0].serial >= first }
        XCTAssertEqual(e.map { s.assets.definitions.units[s.world.entities[$0].unit].id }, FourCC("p2mc")!)
    }

    func testMissionBonusNeedsAllLevels() throws {
        // A 100 % level when every earlier level of the game was 100 % (G+0x44 reaches FUN_10011de0 = 12) pays
        // 10 × flli 205 = 1,000,000 raw (no multiplier, no extra life) after the tier; at 11 of 12 nothing more.
        for (earlier, mission) in [(Int32(11), true), (10, false)] {
            var s = try world(sector: 12)
            s.players[0].multiplier = 3
            s.flags.perfectLevels = earlier
            s.flags.groundDestroyed = 4
            s.flags.groundCreated = 4
            s.accuracyTier(now: 0)
            let before = s.players[0].score, lives = s.players[0].lives
            runTally(&s, from: 1, bound: 4000)
            let tier: Int32 = 5000 * 12 * 3                                // flli 189 × sector × multiplier
            XCTAssertEqual(s.flags.perfectLevels, earlier + 1)
            if mission {
                XCTAssertEqual(s.players[0].score - before, tier + 1_000_000)
                XCTAssertEqual(s.tally.missionPayments, 10)
                XCTAssertFalse(s.tally.missionBonus)
                XCTAssertEqual(soundIndices(s).filter { $0 == 23 }.count, 1)   // miac once
                XCTAssertTrue(s.cues.sounds.contains { $0.id == s.assets.sounds[23] && $0.priority == 100 })
            } else {
                XCTAssertEqual(s.players[0].score - before, tier)
                XCTAssertEqual(s.tally.missionPayments, 0)
                XCTAssertFalse(soundIndices(s).contains(23))
            }
            XCTAssertTrue(soundIndices(s).contains(22))                    // acbo at 100 %
            // Extra lives come only from the tier's non-raw payments (crossing 10 000, then 40 000, …), never raw.
            XCTAssertGreaterThanOrEqual(s.players[0].lives, lives)
        }
    }

    // MARK: - FUN_10006b50 level end / game over, FUN_10007170

    func testLevelEndSequenceOrder() throws {
        // p15 order inside a tick: game over (`10006c4c…`) → level end (`10006dd4…`) → accuracy tally (`10006f58`)
        // → coin setup (`10006f7c…`) → coin tally (`10006ff4`) → level complete (`10007024`).
        var s = try world(players: 2)
        s.players[0].lifeState = 4
        s.players[1].lifeState = 4
        s.flags.levelsStarted = 1
        var log: [LevelEndEvent] = []
        var perTick: [[LevelEndEvent]] = []
        var t: Int32 = 3918
        while !s.flags.levelComplete {
            s.flags.gameTime = t
            log = []
            s.gameOverStep { log.append($0) }
            s.levelEndStep(atEnd: true) { log.append($0) }
            perTick.append(log)
            t += 1
            if t > 3918 + 1000 { XCTFail("level never completed"); break }
        }
        let nole = FourCC("nole")!
        XCTAssertEqual(perTick[0], [.gameOverChecked, .notice(nole), .invulnerable(0), .invulnerable(1), .accuracyTier])
        XCTAssertEqual(perTick[1], [.gameOverChecked, .accuracyTally(done: false)])
        let firstDone = try XCTUnwrap(perTick.firstIndex { $0.contains(.accuracyTally(done: true)) })
        XCTAssertEqual(perTick[firstDone], [.gameOverChecked, .accuracyTally(done: true), .coinSetup(0), .coinSetup(1),
                                            .coinTally(0, done: false), .coinTally(1, done: false)])
        XCTAssertEqual(perTick.last, [.gameOverChecked, .accuracyTally(done: true), .coinTally(0, done: true),
                                      .coinTally(1, done: true), .levelComplete])
        XCTAssertEqual(firstDone, 188)                                    // bonus 0: state 6 → 7 at once; done at T0 + 188
        XCTAssertTrue(s.flags.levelEnding)
        XCTAssertTrue(s.flags.levelEndHandled)
        XCTAssertEqual(s.flags.levelEndTime, 3918)
        XCTAssertTrue(s.players[0].invulnerable && s.players[1].invulnerable)
        XCTAssertFalse(s.players[0].invulnerableSticky)
        XCTAssertEqual(s.tally.coin[1].textYOffset, 70)                   // P2 stacked under P1
        // Nobody alive at the level end: only +0x29, no notice, no tier.
        var u = try world()
        u.players[0].inGame = false
        log = []
        u.flags.gameTime = 100
        u.gameOverStep { log.append($0) }
        u.flags.gameTime = 101
        u.gameOverStep { log.append($0) }
        u.levelEndStep(atEnd: true) { log.append($0) }
        XCTAssertEqual(log, [.gameOverChecked, .notice(FourCC("nogo")!), .gameOverChecked])
        XCTAssertTrue(u.flags.levelEndHandled)
        XCTAssertEqual(u.tally.state, 0)
        // Not at the end: nothing.
        var v = try world()
        log = []
        v.levelEndStep(atEnd: false) { log.append($0) }
        XCTAssertEqual(log, [])
        XCTAssertFalse(v.flags.levelEnding)
    }

    func testGameOverStopsOnStartPlus111() throws {
        var s = try world()
        s.players[0].inGame = false
        let first = s.world.nextSerial
        s.flags.gameTime = 700
        s.gameOverStep()
        XCTAssertTrue(s.flags.noPlayerAlive)
        XCTAssertTrue(s.flags.gameOverNoticed)
        XCTAssertEqual(s.flags.gameOverStart, 700)
        XCTAssertEqual(spawned(s, after: first), [FourCC("nogo")!])       // PermObjectID 24
        for t in Int32(701)...810 {                                       // `cmpw; ble`: > start + flli 13 (110)
            s.flags.gameTime = t
            s.gameOverStep()
            XCTAssertTrue(s.flags.running, "game time \(t)")
        }
        s.flags.gameTime = 811
        s.gameOverStep()
        XCTAssertFalse(s.flags.running)
        XCTAssertEqual(spawned(s, after: first), [FourCC("nogo")!])       // spawned once
        // A player in game: nothing happens.
        var u = try world()
        u.gameOverStep()
        XCTAssertFalse(u.flags.noPlayerAlive)
        XCTAssertFalse(u.flags.gameOverNoticed)
    }

    func testLevelCompleteClearsRunningInFilm() throws {
        let a = try TestAssets.loaded.get()
        var c = FrameController(fpsMaxRate: 30)
        var console = try Console(assets: a)
        // A film: running cleared, nothing else.
        var s = try world()
        s.flags.filmPlaying = true
        s.flags.levelComplete = true
        s.flags.levelEnding = true
        s.levelCompleteStep(controller: &c, console: &console, ticks: 0)
        XCTAssertFalse(s.flags.running)
        XCTAssertTrue(s.flags.levelComplete)
        XCTAssertTrue(s.flags.levelEnding)
        XCTAssertTrue(s.cues.sounds.isEmpty && s.cues.music.isEmpty)
        // Not complete: nothing.
        var u = try world()
        u.flags.filmPlaying = true
        u.levelCompleteStep(controller: &c, console: &console, ticks: 0)
        XCTAssertTrue(u.flags.running)
        // Nobody in game: running cleared.
        var v = try world()
        v.players[0].inGame = false
        v.flags.levelComplete = true
        v.levelCompleteStep(controller: &c, console: &console, ticks: 0)
        XCTAssertFalse(v.flags.running)
        // Not a film (◇ S9.1): music stop, `tran` (priority 75, volume 100, multiple), +9/+0x39 cleared, then the
        // session ends instead of FUN_100064d0.
        var w = try world()
        w.flags.levelComplete = true
        w.flags.levelEnding = true
        w.levelCompleteStep(controller: &c, console: &console, ticks: 0)
        XCTAssertFalse(w.flags.running)
        XCTAssertFalse(w.flags.levelComplete)
        XCTAssertFalse(w.flags.levelEnding)
        XCTAssertEqual(w.cues.music, [.stop])
        XCTAssertEqual(w.cues.sounds, [SoundPlay.perm(a.sounds[3], priority: 75, volume: 100, allowMultiple: true)])
    }
}
