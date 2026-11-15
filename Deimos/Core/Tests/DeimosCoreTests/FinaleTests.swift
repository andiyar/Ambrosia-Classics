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
/// so the scroll's spawn row passes le09's four mission irises (map rows 179, 120, 103, 85). The poke SKIPS sector
/// 12's end fight: `12e1` (map row 377, "pauses scrolling until Beamer destroyed") and the Beamer `be02` (335), the
/// ground units at rows 335–501 and the `fl02` at rows 204 / 208 / 436 never spawn. So a real run reaches the finale
/// with different survivors and a different random stream; this run proves the finale's chain from the level end on,
/// and the campaign sweep (task CS) covers the real approach. Bound: 3,000 passes.
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
        var scale: Float
    }

    /// An entity first seen live after a pass: its unit, serial, its owner's unit and its position.
    private struct Born {
        var id: FourCC
        var serial: Int32
        var owner: FourCC?
        var x: Float
        var y: Float
    }

    /// One ticked pass: its game time, its effect cues' ids, the tracked units' live entities after it, the
    /// entities born on it, the RNG before and after it, the tally states, P1's score and money, and the G+0x0d /
    /// G+0x29 flags after it.
    private struct Pass {
        var t: Int32
        var sounds: [FourCC]
        var live: [FourCC: [Seen]]
        var born: [Born]
        var rngBefore: MSLRandom
        var rngAfter: MSLRandom
        var tally: UInt8
        var coin: UInt8
        var percent: Int32
        var score: Int32
        var money: Int32
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
        /// The session after the pass at T0 + 1200 (the last tick of the tally's wait) — the start of the
        /// mission-bonus variants.
        var beforeTally: DeimosSession
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
                                           x: e.object.x, y: e.object.y, countdown: e.spawnCountdown,
                                           scale: e.object.scale))
        }
        for k in r.keys { r[k]!.sort { $0.serial < $1.serial } }
        return r
    }

    /// One pass with no keys, recorded; `seen` holds the serials already reported as born.
    private static func step(_ s: inout DeimosSession, seen: inout Set<Int32>) throws -> (Pass, PassOutput) {
        let t = s.gameTime, rngBefore = s.game.rng
        let out = s.pass(keys: HeldKeys(), ticks: 0)
        guard out.ticked else { throw RunError(description: "the pass at game time \(t) did not tick") }
        let g = s.game, units = g.assets.definitions.units
        var born: [Born] = []
        for i in g.world.entities.indices where g.world.inUse[i] && !g.world.entities[i].deleted {
            let e = g.world.entities[i]
            guard seen.insert(e.serial).inserted else { continue }
            let owner = e.owner.flatMap { o -> FourCC? in
                let u = g.world.entities[o].unit
                return u >= 0 ? units[u].id : nil
            }
            born.append(Born(id: units[e.unit].id, serial: e.serial, owner: owner, x: e.object.x, y: e.object.y))
        }
        born.sort { $0.serial < $1.serial }
        let f = g.flags
        let p = Pass(t: t, sounds: out.sounds.map(\.id), live: live(g), born: born, rngBefore: rngBefore,
                     rngAfter: g.rng, tally: g.tally.state, coin: g.tally.coin[0].state, percent: g.tally.percent,
                     score: g.players[0].score, money: g.players[0].money, allLevels: f.allLevels,
                     levelEndHandled: f.levelEndHandled, levelsStarted: f.levelsStarted,
                     levelComplete: f.levelComplete, running: f.running)
        return (p, out)
    }

    private static let finale: Result<FinaleRun, Error> = Result { try runFinale() }

    /// The tally and session end from the shared run's T0 + 1200 snapshot, perfect levels poked; bound 1,000 passes.
    private static func runTally(from s0: DeimosSession, perfectLevels: Int32) throws -> [Pass] {
        var s = s0
        s.game.flags.perfectLevels = perfectLevels
        var seen = Set(s.game.world.entities.map(\.serial))
        var passes: [Pass] = []
        for _ in 0..<1000 {
            let (p, out) = try step(&s, seen: &seen)
            passes.append(p)
            if out.sessionEnded { return passes }
        }
        throw RunError(description: "bound: the variant (perfect levels \(perfectLevels)) still runs after 1,000 passes")
    }

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
        var passes: [Pass] = [], seen = Set<Int32>()
        var t0: Int32?, beforeTally: DeimosSession?
        for _ in 0..<3000 {
            let before = s
            let (p, out) = try step(&s, seen: &seen)
            passes.append(p)
            if t0 == nil, p.levelEndHandled { t0 = p.t }
            if let t0, p.t == t0 + 1200 { beforeTally = s }
            if out.sessionEnded {
                guard let beforeTally else { throw RunError(description: "the session ended before T0 + 1200") }
                return FinaleRun(passes: passes, last: out, beforeLast: before, end: s, beforeTally: beforeTally)
            }
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
        // no delay, so it is issued at entry), every member present from that pass, and nothing else makes an aieg.
        var aiegSerials: [Int32: Int32] = [:]
        for k in passes.indices {
            for e in passes[k].live[Self.aieg] ?? [] where aiegSerials[e.serial] == nil { aiegSerials[e.serial] = rel(k) }
        }
        XCTAssertEqual(aiegSerials.count, 50)
        XCTAssertEqual(Set(aiegSerials.values), [95], "every aieg member first seen on the pass at T0 + 95")
        let made = passes[k0 + 95].live[Self.aieg] ?? []
        XCTAssertEqual(made.count, 50)
        // The pass at T0 + 95 replayed draw for draw from the RNG at its start. Its only draws are the group's, four
        // per member in creation (= serial) order (`Air Explosion Group[aieg].unde.txt`): `10037988` R(0, 359) the
        // placement heading and `100379b8` F(0, |xOffsetMax| = 200) the radius (both offset ranges open, lines 88–91;
        // randomiseInitialLoc, line 18), `10014b14` R(−15, 15) the scale tolerance (30 / 2, line 61; in the state
        // entry called at `10035f74`), `10035fc8` R(5, 6) the group delay (lines 6–7). Every other range is closed, so
        // `10046580` / `100465e0` skip the draw: no heading draw at `10035ee4` (tolerance 0, line 93), none for the
        // speed (0..0), the state timer (5..5), the frame (0..0) or the two spawn records (rate 0..0, volley 1..1,
        // delay 0..0). Each member sits at fmadds(S[h], r, 208), fmadds(C[h], r, 150) (`100379cc` / `100379d8`; the
        // group at 12gc), scale (80 + tol) / 100 (line 60, `FUN_1001a260`), countdown = the running sum of the delays
        // through it (`10035fe0`) less its creation pass's one decrement — member 0 included.
        let p95 = passes[k0 + 95]
        var replay = p95.rngBefore
        var delaySum: Int32 = 0
        for (n, m) in made.enumerated() {
            let h = replay.range(Int32(0), 359)                                  // 10037988
            let radius = replay.range(Float(0), 200)                             // 100379b8
            let tol = replay.range(Int32(-15), 15)                               // 10014b14
            delaySum += replay.range(Int32(5), 6)                                // 10035fc8
            let (sx, cy) = Trig.unitVector(heading: h)
            let x = Float(208).addingProduct(sx, radius), y = Float(150).addingProduct(cy, radius)
            XCTAssertEqual(m.x.bitPattern, x.bitPattern, "member \(n) x")
            XCTAssertEqual(m.y.bitPattern, y.bitPattern, "member \(n) y")
            XCTAssertEqual(m.scale.bitPattern, (Float(80 + tol) / Float(100)).bitPattern, "member \(n) scale")
            XCTAssertEqual(m.countdown, delaySum - 1, "member \(n) countdown")
        }
        XCTAssertEqual(p95.rngAfter.draws - p95.rngBefore.draws, 200, "the pass at T0 + 95 draws 50 × 4")
        XCTAssertEqual(replay.draws, p95.rngAfter.draws)
        XCTAssertEqual(replay.state, p95.rngAfter.state, "the RNG after the pass = the replay's after 200 draws")

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
        // (The rule's range itself — 60 — is not pinned by this run: every flag lands well inside 50 of its iris, so a
        // smaller range would pass too.)

        // What each iris releases (`Mission Iris - …[migc|mimu|mipo|miac].unde.txt`, no RNG: every timer and set range
        // is closed): the pass after its flag, state 1 "RULE Response - Wait To Open" (timer 10) → 2 "Open" (8) → 3
        // "Continue Open, Spawn …", whose one set (offset 0, 0; rate 0/0, volley 1/1, delay 0/0, no repeat) releases on
        // entry at the iris — flag + 1 + 10 + 8 = flag + 19; then 4 "Close" (40) → 0 (30) at flag + 89, waiting again
        // before the flag's second round (flag + 280), which releases a second time. migc → `migs`, mimu → `pimu`,
        // mipo → `mips`, miac → `mias`.
        let releaseOf: [FourCC: FourCC] = [FourCC("migc")!: FourCC("migs")!, FourCC("mimu")!: FourCC("pimu")!,
                                           FourCC("mipo")!: FourCC("mips")!, FourCC("miac")!: FourCC("mias")!]
        var released: [FourCC: [Int32]] = [:]
        var stormOf: [FourCC: [String]] = [:]
        for k in passes.indices {
            for b in passes[k].born {
                guard let o = b.owner else { continue }
                if let want = releaseOf[o] {
                    XCTAssertGreaterThanOrEqual(k, k0, "\(o) released \(b.id) before the level end")
                    XCTAssertEqual(b.id, want, "\(o) releases \(want)")
                    let iris = try XCTUnwrap(passes[k].live[o]?.first, "\(o) live when it releases")
                    if b.id == FourCC("pimu") {
                        // Placed at the iris (offsets 0), then it moves on its creation pass ("Grow and Dance
                        // Around", max speed 4): within 4 of the iris on each axis.
                        XCTAssertLessThanOrEqual(max(abs(b.x - iris.x), abs(b.y - iris.y)), 4, "pimu by mimu")
                    } else {
                        XCTAssertEqual([b.x, b.y], [iris.x, iris.y], "\(b.id) released at \(o)")
                    }
                    released[o, default: []].append(rel(k))
                }
                if releaseOf.values.contains(o) { stormOf[o, default: []].append("\(b.id)@\(rel(k))") }
            }
        }
        for (iris, f) in flagOf {
            XCTAssertEqual(released[iris], [f + 19, f + 280 + 19], "\(iris) releases at its flag + 19, both rounds")
        }
        // And what the released storms let go, by their data (all closed ranges but one): `migs` — `casg` on entry,
        // then state 1 at + 6 releases `cals` on each entry, re-entered every 6 (timer 1, then Wait 5) until its 8th
        // entry hits the counter (Delete): seven `cals` at + 6 … + 42. `mips` — `pi5k` and `pi2k` on entry, state 1
        // at + 9, seven `p500` at + 9 … + 45. `mias` — state 1 at + 6, counter 12: eleven `casg` at + 6 … + 66; its
        // entry set `calg` has rate R(2, 3) and delay R(2, 3) (drawn at `10017d64` / `10017dbc`), so its tick is
        // only bounded here: one `calg`, after the entry and before the first `casg`. `pimu` releases nothing.
        func storm(_ r: Int32, _ entry: [String], _ unit: String, first: Int32, count: Int32) -> [String] {
            entry.map { "\($0)@\(r)" } + (0..<count).map { "\(unit)@\(r + first + 6 * $0)" }
        }
        let rounds = { (iris: String) -> [Int32] in released[FourCC(iris)!] ?? [] }
        XCTAssertEqual(stormOf[FourCC("migs")!]?.sorted(),
                       rounds("migc").flatMap { storm($0, ["casg"], "cals", first: 6, count: 7) }.sorted())
        XCTAssertEqual(stormOf[FourCC("mips")!]?.sorted(),
                       rounds("mipo").flatMap { storm($0, ["pi5k", "pi2k"], "p500", first: 9, count: 7) }.sorted())
        let mias = stormOf[FourCC("mias")!] ?? []
        XCTAssertEqual(mias.filter { !$0.hasPrefix("calg") }.sorted(),
                       rounds("miac").flatMap { storm($0, [], "casg", first: 6, count: 11) }.sorted())
        let calg = mias.filter { $0.hasPrefix("calg") }.compactMap { Int32($0.dropFirst(5)) }
        XCTAssertEqual(calg.count, 2, "one calg per mias")
        for (c, r) in zip(calg.sorted(), rounds("miac")) { XCTAssertTrue((r + 1)...(r + 5) ~= c, "calg at \(c - r) after mias") }
        XCTAssertNil(stormOf[FourCC("pimu")!])

        // The accuracy tally: state 1 from the tier at T0, the finale's wait flli 196 = 1200 (strict) → 2 at T0 + 1201.
        XCTAssertEqual(passes[k0].tally, 1)
        XCTAssertEqual(passes[k0 + 1200].tally, 1)
        XCTAssertEqual(passes[k0 + 1201].tally, 2)
        XCTAssertTrue(passes[k0..<(k0 + 1201)].allSatisfy { $0.tally == 1 })
    }

    func testFinaleEndsSessionAfterTally() throws {
        let a = try assets()
        let r = try finaleRun()
        let (t0, k0) = try levelEndTick(r)
        let last = r.last, s = r.end, before = r.beforeLast
        let passes = r.passes
        func rel(_ p: Pass) -> Int32 { p.t - t0 }

        // The preconditions of the tally timing below: accuracy 0 % (no ground target destroyed) and no money, so
        // neither tally has a bonus to count down; 0 perfect levels.
        XCTAssertEqual(passes[k0].percent, 0)
        XCTAssertTrue(passes[k0...].allSatisfy { $0.money == 0 && $0.percent == 0 })
        XCTAssertEqual(r.beforeTally.game.flags.perfectLevels, 0)
        XCTAssertEqual(r.beforeTally.game.tally.bonusRemaining, 0)
        // The waits (flli): 196 = 1200 (the finale's), 197 = 20, 201 = 20, 202 = 20; coins 172 = 10, 173 = 20,
        // 174 = 30, 175 = 20; the mission bonus 206 = 4, 207 = 3, 205 = 100,000, 208 = 10 payments. Sounds gaso 20
        // moco, 21 nobo, 23 miac (the mission bonus).
        XCTAssertEqual([196, 197, 201, 202, 172, 173, 174, 175, 206, 207, 205, 208].map { a.floats[$0] },
                       [1200, 20, 20, 20, 10, 20, 30, 20, 4, 3, 100_000, 10])
        let moco = a.sounds[20], nobo = a.sounds[21], mission = a.sounds[23]
        XCTAssertEqual([moco, nobo, mission], [FourCC("moco")!, FourCC("nobo")!, FourCC("miac")!])
        // A wait of N passes when now > timer + N (strict), N + 1 ticks after the timer. Accuracy (timer T0 from the
        // tier): 1 → 2 at 1200 + 1 = 1201 (moco), → 3 at 1222 (moco), → 4 at 1243 (moco), → 5 at 1264 (nobo: bonus 0),
        // → 6 at 1285, → 7 at 1286 (bonus ≤ 0: no wait), → 8 at 1307, done at 1328 (perfect levels ≠ 12: state stays 8,
        // no mission bonus). The coin tally is set up on that pass (state 1, timer 1328): → 2 at 1339 (moco), → 3 at
        // 1360 (moco), → 4 at 1381 (moco), → 5 at 1402 (nobo: bonus 0), → 6 at 1423, → 7 at 1424, → 8 at 1455 (wait
        // 30), done at 1476 — level complete, and FUN_10007170 plays tran and ends the session on that same pass.
        func changes(_ ps: ArraySlice<Pass>, _ v: (Pass) -> UInt8) -> [[Int32]] {
            var out: [[Int32]] = [], prev: UInt8? = nil
            for p in ps where v(p) != prev { out.append([rel(p), Int32(v(p))]); prev = v(p) }
            return out
        }
        let tallyPasses = passes[(k0 + 1200)..<(passes.count - 1)]
        XCTAssertEqual(changes(tallyPasses, \.tally),
                       [[1200, 1], [1201, 2], [1222, 3], [1243, 4], [1264, 5], [1285, 6], [1286, 7], [1307, 8]])
        XCTAssertEqual(changes(tallyPasses, \.coin),
                       [[1200, 0], [1328, 1], [1339, 2], [1360, 3], [1381, 4], [1402, 5], [1423, 6], [1424, 7],
                        [1455, 8]])
        XCTAssertEqual(rel(passes[passes.count - 1]), 1476, "the session ends on the pass at T0 + 1476")
        let heard = passes[(k0 + 1200)...].filter { !$0.sounds.isEmpty }.map { "\(rel($0)) \($0.sounds)" }
        XCTAssertEqual(heard, ["1201 \([moco])", "1222 \([moco])", "1243 \([moco])", "1264 \([nobo])",
                               "1339 \([moco])", "1360 \([moco])", "1381 \([moco])", "1402 \([nobo])",
                               "1476 \([a.sounds[3]])"])
        // With 0 perfect levels the mission bonus (state 9) never starts, its sound never plays, and the score stays.
        XCTAssertFalse(passes.contains { $0.tally >= 9 || $0.sounds.contains(mission) })
        let score = passes[k0 + 1200].score
        XCTAssertTrue(passes[(k0 + 1200)...].allSatisfy { $0.score == score })
        XCTAssertEqual(s.players[0].score, score)

        // The variants, from the T0 + 1200 snapshot: perfect levels 12 (= the level order's count, 10007b68..10007b78)
        // pays — state 9 at 1328 with miac, → 10 at 1333 (wait 4), a payment of 100,000 (raw, no multiplier) at 1337,
        // then → 9 → 10 → pay every 9 passes, ten payments (1337 … 1418); done at 1419, the coin tally from there
        // (1419 + 148 = 1567). Perfect levels 11 does not: the base run's passes exactly.
        XCTAssertEqual(a.levelOrder.levels.count, 12)
        let v12 = try Self.runTally(from: r.beforeTally, perfectLevels: 12)
        XCTAssertEqual(v12.first.map(rel), 1201)
        XCTAssertEqual(v12.last.map(rel), 1567, "the session ends 91 passes later")
        XCTAssertEqual(v12.filter { $0.sounds.contains(mission) }.map(rel), [1328])
        XCTAssertEqual(Array(changes(v12[...].dropLast(), \.tally).filter { $0[1] >= 8 }.prefix(4)),
                       [[1307, 8], [1328, 9], [1333, 10], [1337, 9]])
        var paid: [Int32] = [], prevScore = score
        for p in v12 where p.score != prevScore {
            XCTAssertEqual(p.score - prevScore, 100_000, "one payment at \(rel(p))")
            paid.append(rel(p))
            prevScore = p.score
        }
        XCTAssertEqual(paid, (Int32(0)..<10).map { 1337 + 9 * $0 })
        XCTAssertEqual(changes(v12[...].dropLast(), \.coin).filter { $0[1] == 1 }, [[1419, 1]])
        let v11 = try Self.runTally(from: r.beforeTally, perfectLevels: 11)
        let base = passes[(k0 + 1201)...]
        XCTAssertEqual(v11.map(rel), base.map(rel))
        XCTAssertEqual(v11.map(\.sounds), base.map(\.sounds))
        XCTAssertEqual(v11.map(\.tally), base.map(\.tally))
        XCTAssertEqual(v11.map(\.coin), base.map(\.coin))
        XCTAssertEqual(v11.map(\.score), base.map(\.score))

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
        func world(players: UInt8 = 1) throws -> GameState {
            var s = GameState(assets: a, prefs: DeimosPrefs.fresh, seed: 0x469c2)
            s.flags.numPlayers = players
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
        /// Kills a fresh Hospital with one hit credited to `killer` (`FUN_10014f10` step 9 →
        /// `FUN_10006190(killer, score_INT)`).
        func killHospital(_ s: inout GameState, killer: Int8 = 0) throws {
            let r = try XCTUnwrap(s.spawn(SpawnRequest(unit: FourCC("hosp")!, x: 200, y: 200)), "hosp")
            let i = r.entity
            s.world.entities[i].spawnCountdown = 0
            XCTAssertGreaterThan(s.world.entities[i].shields, 0)
            s.damageEntity(i, damage: 100, killer: killer, now: s.flags.gameTime)
            XCTAssertTrue(s.world.entities[i].deleted, "the hospital died")
        }

        // Multiplier 1 from score 0: exactly −10,000 — score + pts × multiplier (`10029a50..10029a58`), no clamp at
        // zero, and pts ≤ 0 skips the life branch (`10029a5c..10029a60`).
        var one = try world()
        one.players[0].score = 0
        one.players[0].multiplier = 1
        try killHospital(&one)
        XCTAssertEqual(one.players[0].score, -10_000)

        // A kill by player 2: `FUN_10006190` takes killer index 1 to G[1] (`10006198..100061b8`) — P2 pays with its
        // own multiplier, P1 is untouched.
        var two = try world(players: 2)
        XCTAssertTrue(two.players[1].inGame)
        two.players[0].score = 50_000
        two.players[0].multiplier = 3
        two.players[1].score = 40_000
        two.players[1].multiplier = 2
        try killHospital(&two, killer: 1)
        XCTAssertEqual(two.players[1].score, 20_000, "40,000 − 10,000 × 2")
        XCTAssertEqual(two.players[0].score, 50_000)

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
