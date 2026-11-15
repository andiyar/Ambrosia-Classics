import XCTest
import HectorResources
@testable import DeimosCore

/// The finale (plan FN; appendix B §2, §7 "FIN-a" / "FIN-b", with the plan's corrections 1 and 2, which win): the
/// twelfth level of a game reaches its end, the level end spawns `noal` instead of `nole` and sets G+0x0d
/// (`10006dd4..10006e04`), `noal` flashes fifteen times and spawns `12gc`, `12gc` runs the explosions and the four
/// flags that open the mission irises, the accuracy tally waits flli 196 = 1,200 ticks (`1000763c..10007664`), and the
/// level start after it finds level `none` and ends the session (`100064d0..100066c8`).
///
/// Sound timing (correction 1, re-read in the listing): inside an entity's update the state sound step
/// (`10033b64..10033c54`) runs BEFORE the timer step (`10033c58..10033d6c`), and the state entry `FUN_100146f0`
/// plays nothing (it zeroes the visit's play count +0xe8, `1001488c`; no call to `FUN_100475e0`). So a state entered
/// by its timer plays its entry sound on the NEXT tick, while a state entered at spawn plays on the spawn tick (the
/// level end at `10006da4` runs before the entity loop at `1000702c`). The spawn executor runs after the timer in the
/// same update, so spawns land on the entry tick.
///
/// One run serves the three session tests: sector 12 (`le09`), levels started poked to 12 (as a game begun at
/// sector 1 reaches sector 12), P1 invulnerable and sticky (god mode, `FUN_10027de0(p, 1, 1)`), and the scroll moved
/// to 250 rows from the map's end (window top 250, progress 3351 — top + progress = 3601 as the scroll keeps them),
/// so the scroll's spawn row passes le09's four mission irises (map rows 179, 120, 103, 85) but not the two `fl02`
/// at rows 204 / 208. Bound: 3,000 passes.
final class FinaleTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    // MARK: - The shared finale run

    private struct Seen: Equatable {
        var serial: Int32
        var state: Int32
        var stateStart: Int32
        var x: Float
        var y: Float
        var countdown: Int32
    }

    /// One ticked pass: its game time, its effect cues' ids, the tracked units' live entities after it, the tally
    /// state and the G+0x0d / G+0x29 flags after it.
    private struct Pass {
        var t: Int32
        var sounds: [FourCC]
        var live: [FourCC: [Seen]]
        var tally: UInt8
        var allLevels: Bool
        var levelEndHandled: Bool
        var levelsStarted: Int32
        var levelComplete: Bool
        var running: Bool
    }

    private struct FinaleRun {
        var passes: [Pass]
        var last: PassOutput
        var beforeLast: DeimosSession
        var end: DeimosSession
    }

    private struct RunError: Error, CustomStringConvertible { let description: String }

    private static let noal = FourCC("noal")!, gc12 = FourCC("12gc")!, aieg = FourCC("aieg")!, miof = FourCC("miof")!
    private static let irises = [FourCC("miac")!, FourCC("mipo")!, FourCC("mimu")!, FourCC("migc")!]
    private static let tracked: Set<FourCC> = Set([noal, gc12, aieg, miof] + irises)

    private static func live(_ g: GameState) -> [FourCC: [Seen]] {
        let units = g.assets.definitions.units
        var r: [FourCC: [Seen]] = [:]
        for i in g.world.entities.indices where g.world.inUse[i] && !g.world.entities[i].deleted {
            let e = g.world.entities[i]
            let id = units[e.unit].id
            guard tracked.contains(id) else { continue }
            r[id, default: []].append(Seen(serial: e.serial, state: e.state, stateStart: e.stateStart,
                                           x: e.object.x, y: e.object.y, countdown: e.spawnCountdown))
        }
        for k in r.keys { r[k]!.sort { $0.serial < $1.serial } }
        return r
    }

    private static let finale: Result<FinaleRun, Error> = Result { try runFinale() }

    private static func runFinale() throws -> FinaleRun {
        let a = try TestAssets.loaded.get()
        var s = try DeimosSession(assets: a, prefs: .fresh, start: SessionStart(sector: 12, players: 1, film: nil),
                                  seed: 0x469c2)
        guard s.level == FourCC("le09"), s.game.flags.levelsStarted == 1 else {
            throw RunError(description: "sector 12 did not start le09 as the first level (\(s.level))")
        }
        s.game.flags.levelsStarted = 12
        s.game.setInvulnerable(0, true, sticky: true)
        s.game.scroll.window.top = 250
        s.game.scroll.window.bottom = 730
        s.game.scroll.progress = 3351
        var passes: [Pass] = []
        for _ in 0..<3000 {
            let before = s
            let t = s.gameTime
            let out = s.pass(keys: HeldKeys(), ticks: 0)
            guard out.ticked else { throw RunError(description: "the pass at game time \(t) did not tick") }
            let f = s.game.flags
            passes.append(Pass(t: t, sounds: out.sounds.map(\.id), live: live(s.game), tally: s.game.tally.state,
                               allLevels: f.allLevels, levelEndHandled: f.levelEndHandled,
                               levelsStarted: f.levelsStarted, levelComplete: f.levelComplete, running: f.running))
            if out.sessionEnded { return FinaleRun(passes: passes, last: out, beforeLast: before, end: s) }
        }
        throw RunError(description: "bound: the session still runs after 3,000 passes")
    }

    private func finaleRun(file: StaticString = #filePath, line: UInt = #line) throws -> FinaleRun {
        do { return try Self.finale.get() } catch {
            XCTFail("the finale run failed: \(error)", file: file, line: line)
            throw error
        }
    }

    /// T0: the level end's first tick — the first pass after which G+0x29 is set (`10006eec..10006ef0`).
    private func levelEndTick(_ r: FinaleRun, file: StaticString = #filePath, line: UInt = #line) throws -> (Int32, Int) {
        let k = try XCTUnwrap(r.passes.firstIndex(where: \.levelEndHandled), "the level end never ran",
                              file: file, line: line)
        return (r.passes[k].t, k)
    }

    // MARK: - Tests

    func testFinaleTimelineFromNoal() throws {
        let r = try finaleRun()
        let (t0, k0) = try levelEndTick(r)
        let passes = r.passes
        guard k0 > 200, passes.count > k0 + 1201 else {
            return XCTFail("the level end at pass \(k0) of \(passes.count): expected ~249 rows of scroll before it and "
                           + "the session to outlast the tally wait (T0 + 1201)")
        }
        // Every pass ticked once at consecutive game times (the run threw otherwise): index ↔ T0-relative tick.
        for (k, p) in passes.enumerated() where k >= k0 {
            guard p.t == t0 + Int32(k - k0) else { return XCTFail("pass \(k) ran at \(p.t), not T0 + \(k - k0)") }
        }
        func rel(_ k: Int) -> Int32 { passes[k].t - t0 }

        // T0: the level end at sector 12 with 12 levels started — G+0x0d set, `noal` (not `nole`) spawned, one.
        XCTAssertTrue(passes[k0].allLevels)
        XCTAssertFalse(passes[k0 - 1].allLevels)
        let firstNoal = try XCTUnwrap(passes.firstIndex { !($0.live[Self.noal] ?? []).isEmpty })
        XCTAssertEqual(firstNoal, k0, "noal appears on the level end's first tick")
        for p in passes[k0...] {
            guard p.live[Self.noal]?.count == 1 else { return XCTFail("one noal from T0 to the end (t \(p.t - t0))") }
        }
        let noalSerial = passes[k0].live[Self.noal]![0].serial
        // It is placed at (208, 240 − 90) and never moves (no motion in its states).
        XCTAssertEqual(passes[k0].live[Self.noal]![0].x, 208)
        XCTAssertEqual(passes[k0].live[Self.noal]![0].y, 150)

        // noal's states (0 Flash On t3 → 1 Flash Off t3 → 0 …; the 16th entry of state 0 is redirected by its
        // counter to 6 Spawn Game Completion t2 → 5 Scale Out t10 ↔ 4 Scale In t10), as (entry tick, state).
        var expectedNoal: [(Int32, Int32)] = []
        for k in Int32(0)...14 { expectedNoal += [(6 * k, 0), (6 * k + 3, 1)] }
        expectedNoal.append((90, 6))
        var t: Int32 = 92, st: Int32 = 5
        while t <= rel(passes.count - 1) { expectedNoal.append((t, st)); t += 10; st = st == 5 ? 4 : 5 }
        var gotNoal: [(Int32, Int32)] = []
        var lastStart: Int32 = .min
        for k in k0..<passes.count {
            let n = passes[k].live[Self.noal]![0]
            XCTAssertEqual(n.serial, noalSerial)
            if n.stateStart != lastStart { gotNoal.append((n.stateStart - t0, n.state)); lastStart = n.stateStart }
        }
        XCTAssertEqual(gotNoal.map(\.0), expectedNoal.map(\.0), "noal's state entries (T0-relative)")
        XCTAssertEqual(gotNoal.map(\.1), expectedNoal.map(\.1), "noal's states at those entries")

        // Sounds (correction 1): acbo on noal state 0's spawn entry at T0, and the next fourteen entries (by the
        // timer, T0 + 6k) one tick later; leen once, the tick after state 4's first entry (T0 + 102) — its
        // RepeatOnStateChange is FALSE, so the later entries are silent. Nothing else plays either sound.
        var acbo: [Int32] = [], leen: [Int32] = []
        for k in passes.indices {
            for id in passes[k].sounds {
                if id == FourCC("acbo")! { acbo.append(rel(k)) }
                if id == FourCC("leen")! { leen.append(rel(k)) }
            }
        }
        XCTAssertEqual(acbo, [0] + (Int32(1)...14).map { 6 * $0 + 1 }, "fifteen acbo: T0, T0+7 … T0+85")
        XCTAssertEqual(acbo.count, 15)
        XCTAssertEqual(leen, [103])

        // 12gc: spawned on noal's state 6 entry at T0 + 90 at noal's position (offset 0, 0); 0 Wait t5 → 2 Explosions
        // at 95 → (t300) 1 Spawn Flags at 395 → (t280) itself at 675 → its third run's timer at 955 hits the counter
        // (3) → Delete.
        let gcSeen = passes.indices.filter { !(passes[$0].live[Self.gc12] ?? []).isEmpty }
        XCTAssertEqual(gcSeen.first.map(rel), 90)
        XCTAssertEqual(gcSeen.last.map(rel), 954, "deleted on the pass at T0 + 955")
        XCTAssertEqual(gcSeen.count, 955 - 90, "12gc is live on every pass in between")
        var gcEntries: [[Int32]] = []
        lastStart = .min
        for k in gcSeen {
            guard let g = passes[k].live[Self.gc12], g.count == 1 else { return XCTFail("one 12gc at \(rel(k))") }
            XCTAssertEqual([g[0].x, g[0].y], [208, 150])
            if g[0].stateStart != lastStart { gcEntries.append([g[0].stateStart - t0, g[0].state]); lastStart = g[0].stateStart }
        }
        XCTAssertEqual(gcEntries, [[90, 0], [95, 2], [395, 1], [675, 1]])

        // The explosions: one `aieg` group of 50 requested on 12gc's state 2 entry (T0 + 95; INDEX #64: the set has
        // no delay, so it is issued at entry), every member present from that pass; the members' spawn countdowns
        // step by R(5, 6) each (group delay 5..6, cumulative, member order), and nothing else makes an aieg.
        var aiegSerials: [Int32: Int32] = [:]
        for k in passes.indices {
            for e in passes[k].live[Self.aieg] ?? [] where aiegSerials[e.serial] == nil { aiegSerials[e.serial] = rel(k) }
        }
        XCTAssertEqual(aiegSerials.count, 50)
        XCTAssertEqual(Set(aiegSerials.values), [95], "every aieg member first seen on the pass at T0 + 95")
        let made = passes[k0 + 95].live[Self.aieg] ?? []
        XCTAssertEqual(made.count, 50)
        // Member order = serial order. Every member's countdown has had the same number of decrements on its creation
        // pass, so consecutive differences are the draws themselves; 49 of them, all 5 or 6, and both values occur.
        let steps = zip(made.dropFirst(), made).map { $0.countdown - $1.countdown }
        XCTAssertEqual(steps.count, 49)
        XCTAssertTrue(steps.allSatisfy { $0 == 5 || $0 == 6 }, "group delay R(5, 6) per member: \(steps)")
        XCTAssertTrue(steps.contains(5) && steps.contains(6), "both ends of R(5, 6) drawn: \(steps)")
        XCTAssertTrue(made.allSatisfy { $0.countdown > 0 }, "no member out yet on its creation pass")

        // The flags: `miof` at 12gc + each set's offset on entry + max(delay − 1, 0): 395, 464, 534, 604, then again
        // at 675, 744, 814, 884; each lives one pass (Wait Briefly t1 → Delete).
        let flagPos: [[Float]] = [[208 - 126, 150 - 25], [208 + 2, 150 - 43], [208 + 104, 150 - 11], [208 + 188, 150 + 42]]
        var miofFirst: [Int32: Int] = [:], miofCount: [Int32: Int] = [:]
        for k in passes.indices {
            for e in passes[k].live[Self.miof] ?? [] {
                if miofFirst[e.serial] == nil { miofFirst[e.serial] = k }
                miofCount[e.serial, default: 0] += 1
            }
        }
        let flags = miofFirst.sorted { $0.key < $1.key }
        XCTAssertEqual(flags.map { rel($0.value) }, [395, 464, 534, 604, 675, 744, 814, 884])
        XCTAssertTrue(miofCount.values.allSatisfy { $0 == 1 }, "each flag lives one pass: \(miofCount)")
        for (n, f) in flags.enumerated() {
            let e = try XCTUnwrap(passes[f.value].live[Self.miof]?.first { $0.serial == f.key })
            XCTAssertEqual([e.x, e.y], flagPos[n % 4], "flag \(n)")
        }

        // The irises (le09, spawned by the scroll before T0, one each): each waits in state 0 ("Is Active miof
        // within 60", rule #3) until its flag — migc ← the flag at 395, mimu ← 464, mipo ← 534, miac ← 604 — and
        // leaves state 0 on the next pass (the irises' groups come before 12gc's in the entity loop, so they see
        // the flag spawned after them on the pass after its spawn).
        let flagOf: [FourCC: Int32] = [FourCC("migc")!: 395, FourCC("mimu")!: 464, FourCC("mipo")!: 534,
                                       FourCC("miac")!: 604]
        for id in Self.irises {
            let first = try XCTUnwrap(passes.firstIndex { !($0.live[id] ?? []).isEmpty }, "\(id) never spawned")
            XCTAssertLessThan(first, k0, "\(id) spawned before the level end")
            let f = try XCTUnwrap(flagOf[id])
            for k in first...(k0 + Int(f)) {
                guard passes[k].live[id]?.count == 1, passes[k].live[id]![0].state == 0 else {
                    return XCTFail("\(id) in state 0 alone through its flag's pass (failed at \(rel(k)))")
                }
            }
            let after = try XCTUnwrap(passes[k0 + Int(f) + 1].live[id]?.first, "\(id) after its flag")
            XCTAssertNotEqual(after.state, 0, "\(id) leaves state 0 on the pass after its flag (T0 + \(f + 1))")
        }

        // The accuracy tally: state 1 from the tier at T0, the finale's wait flli 196 = 1200 (strict) → 2 at T0 + 1201.
        XCTAssertEqual(passes[k0].tally, 1)
        XCTAssertEqual(passes[k0 + 1200].tally, 1)
        XCTAssertEqual(passes[k0 + 1201].tally, 2)
        XCTAssertTrue(passes[k0..<(k0 + 1201)].allSatisfy { $0.tally == 1 })
    }

    func testFinaleEndsSessionAfterTally() throws {
        let a = try assets()
        let r = try finaleRun()
        let (t0, _) = try levelEndTick(r)
        let last = r.last, s = r.end, before = r.beforeLast
        XCTAssertEqual(a.sounds[3], FourCC("tran"))
        let tran = SoundPlay.perm(a.sounds[3], priority: 75, volume: 100, allowMultiple: true)
        // The pass before: the twelfth level still running, the tallies not yet done, 12 levels started.
        XCTAssertTrue(before.running)
        XCTAssertFalse(before.game.flags.levelComplete)
        XCTAssertEqual(before.game.flags.levelsStarted, 12)
        XCTAssertEqual(before.level, FourCC("le09"))
        XCTAssertGreaterThan(before.gameTime, t0 + 1201, "the session ends after the finale's tally wait")
        // The last pass: G+9 → FUN_10007170 (music stop, tran, the fade to black), then FUN_100064d0 → level none.
        XCTAssertTrue(last.sessionEnded)
        XCTAssertFalse(s.running)
        XCTAssertEqual(s.game.flags.levelsStarted, 13, "+= 1 before the none test (1000667c..10006684)")
        XCTAssertEqual(s.level, .none)                                       // 10006620..10006628
        XCTAssertEqual(s.sector, 12, "G+0x14 is set only after the none exit (100066e8)")
        XCTAssertEqual(s.gameTime, 1, "correction 2: 10006500 sets 0, the loop's 100059e0 adds 1")
        XCTAssertFalse(s.appeared)                                           // 10006510
        XCTAssertFalse(s.game.flags.levelComplete)                           // 1000723c..10007240
        XCTAssertFalse(s.game.flags.levelEnding)                             // 10007248
        // 10007204 stop, 1000669c resume (FUN_10048220(0)), 10005ae4 the session end's stop.
        XCTAssertEqual(last.music, [.stop, .resume, .stop])
        XCTAssertEqual(last.sounds.last, tran)
        XCTAssertEqual(last.sounds.filter { $0 == tran }.count, 1)
        XCTAssertEqual(last.fadeToBlackAt, CueMark(sounds: last.sounds.count, music: 1))
        XCTAssertEqual(last.haltEffectsAt, last.sounds.count, "the session end's halt (10005ad8) after the fade")
        let fade = try XCTUnwrap(last.ops.firstIndex(of: .fade(.toBlack, .gameLayout)))
        XCTAssertEqual(last.ops.filter { $0 == .fade(.toBlack, .gameLayout) }.count, 1)
        XCTAssertFalse(last.ops[fade...].contains { if case .present = $0 { return true } else { return false } },
                       "no present after the fade: appeared is 0, the screen stays black")
        XCTAssertFalse(last.ops.contains { if case .loadTerrain = $0 { return true } else { return false } })
        // No earlier pass of the run ended or crossed a level.
        XCTAssertTrue(r.passes.dropLast().allSatisfy { $0.running && $0.levelsStarted == 12 })
        // A pass after the end: an empty output.
        var after = s
        XCTAssertEqual(after.pass(keys: HeldKeys(), ticks: 0), PassOutput(sessionEnded: true))
    }

    func testAllLevelsFlagSurvivesToSessionEnd() throws {
        let r = try finaleRun()
        let (_, k0) = try levelEndTick(r)
        // G+0x0d: clear for the whole level before its end, set on the level end's first tick (10006e00..10006e04),
        // and never cleared after — not by the tallies, FUN_10007170 or the level start (G is zeroed only at session
        // start), so the session end's result (10005c08) reads 1.
        XCTAssertTrue(r.passes[..<k0].allSatisfy { !$0.allLevels })
        XCTAssertTrue(r.passes[k0...].allSatisfy(\.allLevels))
        XCTAssertTrue(r.beforeLast.game.flags.allLevels)
        XCTAssertTrue(r.end.game.flags.allLevels)
        XCTAssertFalse(r.end.running)
        XCTAssertEqual(r.end.level, .none)
    }

    func testTwelveGcExplosionSetHasNoDelay() throws {
        // The data pin closing RE-bank INDEX #64 (`Level 12 - Game Comp[12gc].unde.txt` lines 483–495): 12gc state 2
        // "Explosions" has one spawn set, `aieg` at (0, 0), Rate 0/0, NumInVolley 1/1, DelayBetweenEntities 0/0,
        // RepeatSpawns FALSE — so it is issued on the state's entry.
        let a = try assets()
        let gc = try XCTUnwrap(a.definitions.units.first { $0.id == FourCC("12gc") })
        XCTAssertEqual(gc.numStates, 4)
        XCTAssertEqual(gc.states.map(\.stateName),
                       ["Wait", "Spawn Flags, Delete on Counter", "Explosions", "Wait Before Spawning Again"])
        XCTAssertEqual([gc.states[0].stateOnTimerMin, gc.states[0].stateOnTimerMax], [5, 5])
        XCTAssertEqual(gc.states[0].stateOnTimerChangeTo, "Explosions")
        XCTAssertEqual([gc.states[2].stateOnTimerMin, gc.states[2].stateOnTimerMax], [300, 300])
        XCTAssertEqual(gc.states[2].stateOnTimerChangeTo, "Spawn Flags, Delete on Counter")
        XCTAssertEqual([gc.states[1].stateOnTimerMin, gc.states[1].stateOnTimerMax], [280, 280])
        XCTAssertEqual(gc.states[1].stateOnTimerChangeTo, "Spawn Flags, Delete on Counter")
        XCTAssertEqual(gc.states[1].stateOnCounter, 3)
        XCTAssertEqual(gc.states[1].stateOnCounterChangeTo, "Delete")
        let explosions = gc.states[2].spawnSets
        XCTAssertEqual(explosions.count, 1)
        let x = try XCTUnwrap(explosions.first)
        XCTAssertEqual(x.stateSpawnSetSpawn, FourCC("aieg"))
        XCTAssertEqual([x.stateSpawnSetXOffset, x.stateSpawnSetYOffset], [0, 0])
        XCTAssertEqual([x.stateSpawnSetRateMin, x.stateSpawnSetRateMax], [0, 0])
        XCTAssertEqual([x.stateSpawnSetNumInVolleyMin, x.stateSpawnSetNumInVolleyMax], [1, 1])
        XCTAssertEqual([x.stateSpawnSetDelayBetweenEntitiesMin, x.stateSpawnSetDelayBetweenEntitiesMax], [0, 0])
        XCTAssertFalse(x.stateSpawnSetRepeatSpawns)
        // The same keys read non-zero in the sibling states (so the zeros above are read, not defaults): state 1's
        // four `miof` sets at delays 0 / 70 / 140 / 210 (lines 292–356) and the unreachable state 3's 0 / 90 / 180 / 270.
        let s1 = gc.states[1].spawnSets, s3 = gc.states[3].spawnSets
        XCTAssertEqual(s1.map(\.stateSpawnSetSpawn), Array(repeating: FourCC("miof")!, count: 4))
        XCTAssertEqual(s1.map(\.stateSpawnSetDelayBetweenEntitiesMin), [0, 70, 140, 210])
        XCTAssertEqual(s1.map(\.stateSpawnSetDelayBetweenEntitiesMax), [0, 70, 140, 210])
        XCTAssertEqual(s1.map { [$0.stateSpawnSetXOffset, $0.stateSpawnSetYOffset] },
                       [[-126, -25], [2, -43], [104, -11], [188, 42]])
        XCTAssertEqual(s3.map(\.stateSpawnSetDelayBetweenEntitiesMin), [0, 90, 180, 270])
        // The explosion group itself: 50 members, group delay 5..6 (`Air Explosion Group[aieg].unde.txt` lines 4–7).
        let g = try XCTUnwrap(a.definitions.units.first { $0.id == FourCC("aieg") })
        XCTAssertEqual([g.numInGroupMin, g.numInGroupMax], [50, 50])
        XCTAssertEqual([g.groupDelayMin, g.groupDelayMax], [5, 6])
    }

    func testHospitalKillSubtractsMultipliedScore() throws {
        let a = try assets()
        let hosp = try XCTUnwrap(a.definitions.units.first { $0.id == FourCC("hosp") })
        XCTAssertEqual(hosp.score, -10_000, "Hospital[hosp].unde.txt line 72")
        func world() throws -> GameState {
            var s = GameState(assets: a, prefs: DeimosPrefs.fresh, seed: 0x469c2)
            s.flags.numPlayers = 1
            s.flags.sector = 12
            s.flags.level = FourCC("le09")!
            s.scroll.levelStart(rect: MacRect(top: 0, left: 0, bottom: 3600, right: 480))
            try s.setupPlayer(0)
            try s.setupPlayer(1)
            s.playerLevelStart(0)
            s.playerLevelStart(1)
            s.scoreBar.levelStart(players: s.players, sector: 12)
            s.flags.gameTime = 100
            s.respawnPlayer(0, now: 100)
            return s
        }
        /// Kills a fresh Hospital with one hit credited to P1 (`FUN_10014f10` step 9 → `FUN_10006190(0, score_INT)`).
        func killHospital(_ s: inout GameState) throws {
            let r = try XCTUnwrap(s.spawn(SpawnRequest(unit: FourCC("hosp")!, x: 200, y: 200)), "hosp")
            let i = r.entity
            s.world.entities[i].spawnCountdown = 0
            XCTAssertGreaterThan(s.world.entities[i].shields, 0)
            s.damageEntity(i, damage: 100, killer: 0, now: s.flags.gameTime)
            XCTAssertTrue(s.world.entities[i].deleted, "the hospital died")
        }

        // −10,000 × the multiplier (3), and no life: the score passes a poked threshold, but pts ≤ 0 skips the life
        // branch entirely (10029a5c..10029a60), so lives, threshold and step stay.
        var s = try world()
        s.players[0].score = 100_000
        s.players[0].multiplier = 3
        s.players[0].lives = 3
        s.players[0].extraLifeThreshold = 20_000
        s.players[0].extraLifeStep = 7_000
        try killHospital(&s)
        XCTAssertEqual(s.players[0].score, 70_000, "100,000 − 10,000 × 3")
        XCTAssertEqual(s.players[0].lives, 3)
        XCTAssertEqual(s.players[0].extraLifeThreshold, 20_000)
        XCTAssertEqual(s.players[0].extraLifeStep, 7_000)

        // Below zero (no clamp), × 10, and the score bar's "%0.7i" negative form: a leading '-' then seven digits.
        var n = try world()
        n.players[0].score = 5_000
        n.players[0].multiplier = 10
        let lives = n.players[0].lives, threshold = n.players[0].extraLifeThreshold, step = n.players[0].extraLifeStep
        try killHospital(&n)
        XCTAssertEqual(n.players[0].score, -95_000, "5,000 − 10,000 × 10")
        XCTAssertEqual(n.players[0].lives, lives)
        XCTAssertEqual(n.players[0].extraLifeThreshold, threshold)
        XCTAssertEqual(n.players[0].extraLifeStep, step)
        n.scoreBar.update(players: n.players, sector: 12)
        let rec = n.scoreBar.records[0]
        XCTAssertEqual(rec.lastScore, -95_000)
        XCTAssertTrue(rec.dirty.contains(.score))
        XCTAssertTrue(rec.drawActive)
        let text = try TextLayout(assets: a)
        func words(_ str: String) -> [RenderOp] {
            var t = TextRequest(format: a.formats[43], text: str)                // tefo 43, P1's score, undimmed
            t.drawNow = true
            return text.draw(t).map { .draw($0) }
        }
        let minus = words("-0095000"), plain = words("0095000")
        XCTAssertEqual(minus.count, 8)
        XCTAssertNotEqual(Array(minus.dropFirst()), plain, "the '-' moves the digits")
        let ops = try ScoreBarDraw(assets: a).drawOps(state: n.scoreBar, blitToScreen: false)
        func contains(_ run: [RenderOp]) -> Bool {
            guard ops.count >= run.count else { return false }
            return (0...(ops.count - run.count)).contains { Array(ops[$0..<($0 + run.count)]) == run }
        }
        XCTAssertTrue(contains(minus), "P1's score drawn as \"-0095000\"")
        XCTAssertFalse(contains(plain), "not as \"0095000\"")
    }
}
