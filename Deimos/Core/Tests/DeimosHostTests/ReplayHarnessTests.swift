import XCTest
@testable import DeimosHost
@testable import DeimosCore

/// H2 — the machine-side replay tools: `HeadlessRunner` (logic only unless asked to render), `FilmReplay` (seed,
/// sector and players from the film) and `ReplayTrace` (a `TickTrace` row per ticked pass, CSV with a fixed header).
final class ReplayHarnessTests: XCTestCase {

    /// A one-player film of `frames` zero input bytes on `le07` (sector 1), seed 0x469c2.
    private static func film(frames: Int) throws -> Film {
        var b = [UInt8](repeating: 0, count: Film.size)
        func put(_ v: UInt32, _ at: Int) {
            b[at] = UInt8(v >> 24); b[at + 1] = UInt8(v >> 16 & 0xff); b[at + 2] = UInt8(v >> 8 & 0xff)
            b[at + 3] = UInt8(v & 0xff)
        }
        put(Film.version, 0)
        put(0x469c2, 4)
        put(FourCC("le07")!.rawValue, 8)
        b[0x0c] = 1
        put(UInt32(frames), 0x10)
        put(Film.scoreBias, 0x14)
        put(FourCC("le07")!.rawValue, 0x18)
        return try Film(data: Data(b))
    }

    /// de01 from the shipped data: the session takes level, seed and players from the film (`FUN_100069b0`) —
    /// sector 1 (`le07`), seed 0x469c2 (then P1's `R(400, 2000)` at the level start, `10026a9c`), one player. A
    /// bounded logic-only run (100 passes) ends on the bound with P1 reading the film and a trace row per pass.
    func testHeadlessRunnerFromFilm() throws {
        let assets = try ShippedAssets.get()
        let film = try FilmLookup.film("de01", in: assets)
        // The one film lookup (plan CS): an unknown tag and a tag that is not four characters fail naming the tag.
        XCTAssertThrowsError(try FilmLookup.film("de05", in: assets)) {
            XCTAssertEqual($0 as? FilmLookup.NoSuchFilm, FilmLookup.NoSuchFilm(tag: "de05"))
            XCTAssertEqual("\($0)", "no film record \"de05\" in the data")
        }
        XCTAssertThrowsError(try FilmLookup.film("de1", in: assets)) {
            XCTAssertEqual($0 as? FilmLookup.NoSuchFilm, FilmLookup.NoSuchFilm(tag: "de1"))
        }
        var runner = try HeadlessRunner(assets: assets, film: film)
        XCTAssertNil(runner.screen, "logic only unless asked to render")
        XCTAssertEqual(runner.session.sector, 1)
        XCTAssertEqual(runner.session.level, FourCC("le07"))
        XCTAssertEqual(runner.session.game.flags.numPlayers, 1)
        XCTAssertTrue(runner.session.game.flags.filmPlaying)
        var seeded = MSLRandom(seed: 0x469c2)
        _ = seeded.range(Int32(400), Int32(2000))
        XCTAssertEqual(runner.session.rng, seeded)
        XCTAssertEqual(runner.session.rng.draws, 1)

        runner.trace = ReplayTrace()
        let result = runner.run(maxPasses: 100)
        XCTAssertEqual(result.endReason, .bound)
        XCTAssertEqual(result.passes, 100)
        XCTAssertEqual(runner.session.gameTime, 100)
        XCTAssertGreaterThan(result.cursor, 0, "P1 reads the film")
        XCTAssertEqual(result.cursor, runner.session.game.film?.cursors[0])
        XCTAssertNil(result.scoreAtRead4808)
        XCTAssertEqual(result.endScore, runner.session.players[0].score)
        XCTAssertEqual(runner.trace?.rows.count, 100)
        XCTAssertEqual(runner.trace?.rows.last?.gameTime, 100)
        XCTAssertEqual(result.trace, runner.trace)
    }

    /// A synthetic 10-frame film: P1 reads bytes 0…9 and then the read one past the recording (cursor 10 → 11);
    /// `FUN_10009750` (cursor > frames) ends the session on that pass (`10005a38..10005a48`) — 11 input ticks,
    /// `.filmEnd`. Bound: 500 passes. The other ends are told apart from it: a 3,000-frame film outlasts its
    /// input-less pilot and ends on game over (bound 3,000 passes); the level-complete rules, which a zero-input film
    /// cannot reach, are checked on the classifier with their flags set on copies of a session, and the campaign end
    /// on a sector-12 session run to its end.
    func testFilmReplayEndsOnePastLastByte() throws {
        let assets = try ShippedAssets.get()
        let result = try FilmReplay.run(film: Self.film(frames: 10), assets: assets, trace: true, maxPasses: 500)
        XCTAssertEqual(result.endReason, .filmEnd)
        XCTAssertEqual(result.cursor, 11)
        XCTAssertNil(result.scoreAtRead4808)
        XCTAssertLessThan(result.passes, 500)
        let rows = try XCTUnwrap(result.trace).rows
        XCTAssertEqual(rows.count, result.passes, "a row per ticked pass")
        let inputTicks = zip(rows, [Int32(0)] + rows.map(\.cursor)).filter { $0.0.cursor != $0.1 }.count
        XCTAssertEqual(inputTicks, 11)
        XCTAssertEqual(rows.last?.cursor, 11)

        // Game over inside a film (10006d68..10006d98 runs in the tick, before the film branch 10005a24).
        var long = try HeadlessRunner(assets: assets, film: Self.film(frames: 3000))
        let over = long.run(maxPasses: 3000)
        XCTAssertEqual(over.endReason, .gameOver)
        XCTAssertLessThan(over.passes, 3000)
        XCTAssertLessThan(over.cursor, 3000, "the film had not run out")
        XCTAssertTrue(long.session.game.flags.noPlayerAlive)
        XCTAssertFalse(long.session.players.contains(where: \.inGame))

        // FUN_10007170 with G+0x09 set: a film keeps it (100071f0) → level complete; nobody in game (10007264) →
        // game over; not a film, the transition (plan LT) starts the next sector and ends nothing — except after
        // sector 12, where the level start finds level `none` (10006620..100066c8) → the campaign end. Run for real
        // here: a sector-12 session poked one row from the map's end (progress 3599), bound 3,000 passes.
        var s = try HeadlessRunner(assets: assets, film: Self.film(frames: 10)).session
        s.game.flags.levelComplete = true
        s.game.players[0].inGame = true
        XCTAssertEqual(HeadlessRunner.reason(s, levelEndingBefore: true), .levelComplete)
        for i in s.game.players.indices { s.game.players[i].inGame = false }
        XCTAssertEqual(HeadlessRunner.reason(s, levelEndingBefore: true), .gameOver)
        var n = try HeadlessRunner(assets: assets, start: SessionStart(sector: 12, players: 1, film: nil), seed: 0x469c2)
            .session
        n.game.scroll.progress = 3599
        var levelEndingBefore = false
        var nPasses = 0
        while n.running {
            levelEndingBefore = n.game.flags.levelEnding
            _ = n.pass(keys: HeldKeys(), ticks: 0)
            nPasses += 1
            if nPasses > 3000 { return XCTFail("bound: the sector-12 session still runs after 3,000 passes") }
        }
        XCTAssertTrue(levelEndingBefore)
        XCTAssertEqual(n.level, .none)
        XCTAssertEqual(HeadlessRunner.reason(n, levelEndingBefore: levelEndingBefore), .campaignEnd)
    }

    /// The CSV: a fixed header naming the `TickTrace.Row` fields in order, one line per row, `\n`-terminated;
    /// Booleans as 0/1, the shield as Swift's shortest round-trip `Float` text. The last column is the sector
    /// (G+0x14, plan CS — added after the others so the earlier columns keep their places); the run starts at sector 7
    /// so the column cannot pass by matching a default of 1.
    func testReplayTraceCSVHeader() throws {
        XCTAssertEqual(ReplayTrace.csvHeader,
                       "gameTime,cursor,p1State,p1Score,p1Lives,p1Shield,p1Money,p1Multiplier,draws,entities,groups,"
                       + "scrollTop,paused,levelEnding,sector")
        XCTAssertEqual(ReplayTrace().csv(), ReplayTrace.csvHeader + "\n")

        var runner = try HeadlessRunner(assets: ShippedAssets.get(), start: SessionStart(sector: 7, players: 1, film: nil),
                                        seed: 0x469c2)
        runner.trace = ReplayTrace()
        _ = runner.run(maxPasses: 3)
        let trace = try XCTUnwrap(runner.trace)
        let lines = trace.csv().split(separator: "\n", omittingEmptySubsequences: false)
        XCTAssertEqual(lines.count, 5, "header, three rows, the empty tail after the last newline")
        XCTAssertEqual(String(lines[0]), ReplayTrace.csvHeader)
        XCTAssertEqual(lines[4], "")
        let s = runner.session
        let fields = lines[3].split(separator: ",").map(String.init)
        XCTAssertEqual(fields.count, 15)
        XCTAssertEqual(fields, [
            "3", "-1", String(s.players[0].lifeState), String(s.players[0].score), String(s.players[0].lives),
            "\(s.players[0].shield)", String(s.players[0].money), String(s.players[0].multiplier), String(s.rng.draws),
            String(s.game.world.liveCount), String(s.game.world.groups.count), String(s.scroll.window.top),
            s.scroll.speed == 0 ? "1" : "0", s.game.flags.levelEnding ? "1" : "0", "7",
        ])
        XCTAssertEqual(trace.rows[2], ReplayTrace.row(s))
        XCTAssertEqual(trace.rows.map(\.sector), [7, 7, 7])
    }
}
