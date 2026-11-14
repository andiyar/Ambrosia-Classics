import XCTest
import DeimosCore
import DeimosHost
@testable import deimos_replay

/// The replay gate G4 (plan H3, "G4 — the replay gate, and the miss path"): the shipped demo film de01 replayed
/// through the simulation must reach player 1's recorded score at the instant the recorder stored it. A separate
/// bundle, excluded from G2 by `--skip DeimosReplayTests`.
final class ReplayGateTests: XCTestCase {

    /// G4.1: P1's decoded score at the read that consumes film byte 4808 (cursor 4808 → 4809) is 25,050 — what
    /// `FUN_10009830` stored at `1002a42c` while recording (the film's +0x14 − 0xb3ac2). The film then runs out:
    /// the session ends on the film branch (`FUN_10009750`) with P1's cursor one past the recording, 4810.
    /// Bound: 20,000 passes.
    func testDemo01ReachesScore25050AtRead4809() throws {
        let film = try ReplayTestData.film("de01")
        XCTAssertEqual(film.players[0].frames, 4809, "de01's recording length")
        XCTAssertEqual(film.players[0].score, 25_050, "de01's recorded score")
        var runner = try HeadlessRunner(assets: ReplayTestData.getAssets(), film: film)
        let result = runner.run(maxPasses: 20_000)
        if result.endReason == .bound || result.passes >= 20_000 {
            XCTFail("de01 replay reached the 20,000-pass bound (cursor \(result.cursor))")
        }
        XCTAssertEqual(result.scoreAtRead4808, 25_050,
                       "score at read 4809: \(result.scoreAtRead4808.map(String.init) ?? "none"); end "
                       + "\(result.endReason), cursor \(result.cursor), passes \(result.passes), end score "
                       + "\(result.endScore)")
        XCTAssertEqual(result.endReason, .filmEnd, "de01 ends when its film runs out")
        XCTAssertEqual(result.cursor, 4810, "P1's cursor at the end: one past the 4,809-byte recording")
    }

    /// The other three shipped films (orchestrator ruling, H3 fix round: asserted, not information). Each replays to
    /// the score its recorder stored, at the read of its last recorded byte, and ends when the film runs out. de01
    /// alone cannot see a wrong x3 multiplier (de02 does) or a lost extra life (de04 does). Literals, not values read
    /// back from the films. Bound: 20,000 passes each (the longest, de03, has 10,058 reads).
    func testDemos02To04ReachTheirStoredScores() throws {
        let assets = try ReplayTestData.getAssets()
        let expected: [(tag: String, level: String, seed: UInt32, score: Int32, read: Int)] = [
            ("de02", "le06", 0x4f655, 116_180, 8_357),
            ("de03", "le02", 0x54c83, 57_520, 10_058),
            ("de04", "le08", 0x5afed, 24_670, 5_649),
        ]
        let bound = 20_000
        for e in expected {
            let film = try ReplayTestData.film(e.tag)
            XCTAssertEqual("\(film.level)", e.level, "\(e.tag)'s level")
            XCTAssertEqual(film.seed, e.seed, "\(e.tag)'s seed")
            XCTAssertEqual(film.players[0].frames, e.read, "\(e.tag)'s recording length")
            XCTAssertEqual(film.players[0].score, e.score, "\(e.tag)'s recorded score")
            var runner = try HeadlessRunner(assets: assets, film: film)
            let result = runner.run(maxPasses: bound)
            if result.endReason == .bound || result.passes >= bound {
                XCTFail("\(e.tag) replay reached the \(bound)-pass bound (cursor \(result.cursor))")
            }
            let score = runner.session.game.film?.score(player: 0, atRead: e.read - 1)
            XCTAssertEqual(score, e.score,
                           "\(e.tag) score at read \(e.read): \(score.map(String.init) ?? "none"); end "
                           + "\(result.endReason), cursor \(result.cursor), passes \(result.passes), end score "
                           + "\(result.endScore)")
            XCTAssertEqual(result.endReason, .filmEnd, "\(e.tag) ends when its film runs out")
        }
    }

    /// Two runs of de01 to game time 1,000 give the same trace, row for row, and the same trace hash (FNV-1a 64 of
    /// the CSV). Bound: 1,200 passes each.
    func testReplayIsDeterministic() throws {
        let assets = try ReplayTestData.getAssets()
        let film = try ReplayTestData.film("de01")
        func run() throws -> ReplayTrace {
            var runner = try HeadlessRunner(assets: assets, film: film)
            runner.trace = ReplayTrace()
            while runner.session.gameTime < 1000 && runner.ended == nil && runner.passes < 1200 {
                _ = runner.run(maxPasses: runner.passes + 1)
            }
            if runner.session.gameTime < 1000 {
                XCTFail("de01 did not reach game time 1,000 within 1,200 passes (ended \(String(describing: runner.ended)))")
            }
            return try XCTUnwrap(runner.trace)
        }
        let a = try run()
        let b = try run()
        XCTAssertEqual(a.rows.count, 1000, "a row per ticked pass")
        XCTAssertEqual(a.rows.last?.gameTime, 1000)
        XCTAssertEqual(a, b)
        XCTAssertEqual(DeimosReplay.traceHash(a), DeimosReplay.traceHash(b))
        XCTAssertNotEqual(DeimosReplay.traceHash(a), DeimosReplay.traceHash(ReplayTrace()), "the hash reads the rows")
    }

    /// The CLI's G4 line (plan G4 table): `<tag> <level> seed 0x<seed>: score <n> at read <frames> (end: <reason>)`
    /// then PASS / FAIL for every film (the replica's score at the read of the last recorded byte against the
    /// film's stored score, and a real end — never the pass bound). Exit 0 iff every film run passed and every
    /// requested file was written.
    func testCLISummaryLine() throws {
        let de01 = try ReplayTestData.film("de01")
        XCTAssertEqual(DeimosReplay.summaryLine(tag: "de01", film: de01, scoreAtLastRead: 25_050, end: .filmEnd),
                       "de01 le07 seed 0x469c2: score 25050 at read 4809 (end: filmEnd) PASS")
        XCTAssertEqual(DeimosReplay.summaryLine(tag: "de01", film: de01, scoreAtLastRead: 24_950, end: .gameOver),
                       "de01 le07 seed 0x469c2: score 24950 at read 4809 (end: gameOver) FAIL")
        XCTAssertEqual(DeimosReplay.summaryLine(tag: "de01", film: de01, scoreAtLastRead: nil, end: .bound),
                       "de01 le07 seed 0x469c2: score none at read 4809 (end: bound) FAIL")
        XCTAssertEqual(DeimosReplay.summaryLine(tag: "de01", film: de01, scoreAtLastRead: 25_050, end: .bound),
                       "de01 le07 seed 0x469c2: score 25050 at read 4809 (end: bound) FAIL",
                       "the right score with no real end is not a pass")
        XCTAssertTrue(DeimosReplay.passes(film: de01, scoreAtLastRead: 25_050, end: .filmEnd))
        XCTAssertFalse(DeimosReplay.passes(film: de01, scoreAtLastRead: 25_051, end: .filmEnd))
        XCTAssertFalse(DeimosReplay.passes(film: de01, scoreAtLastRead: 25_050, end: .bound))

        let de02 = try ReplayTestData.film("de02")
        XCTAssertEqual(DeimosReplay.summaryLine(tag: "de02", film: de02, scoreAtLastRead: 116_180, end: .filmEnd),
                       "de02 le06 seed 0x4f655: score 116180 at read 8357 (end: filmEnd) PASS")
        XCTAssertEqual(DeimosReplay.summaryLine(tag: "de02", film: de02, scoreAtLastRead: 87_960, end: .filmEnd),
                       "de02 le06 seed 0x4f655: score 87960 at read 8357 (end: filmEnd) FAIL")

        // Arguments: films, --trace, --frames with --every, --all = de01…de04.
        XCTAssertEqual(try DeimosReplay.Options(arguments: ["de01"]).films, ["de01"])
        let o = try DeimosReplay.Options(arguments: ["--all", "--trace", "t.csv", "--frames", "f", "--every", "30"])
        XCTAssertEqual(o.films, ["de01", "de02", "de03", "de04"])
        XCTAssertEqual(o.trace, "t.csv")
        XCTAssertEqual(o.frames, "f")
        XCTAssertEqual(o.every, 30)
        XCTAssertThrowsError(try DeimosReplay.Options(arguments: []))
        XCTAssertThrowsError(try DeimosReplay.Options(arguments: ["de01", "--every", "0"]))
        XCTAssertThrowsError(try DeimosReplay.Options(arguments: ["de01", "--bogus"]))

        XCTAssertEqual(DeimosReplay.exitCode(filmsPassed: [true], writeFailed: false), 0)
        XCTAssertEqual(DeimosReplay.exitCode(filmsPassed: [true, true, true, true], writeFailed: false), 0)
        XCTAssertEqual(DeimosReplay.exitCode(filmsPassed: [true, false, true, true], writeFailed: false), 1,
                       "one failing film fails the run")
        XCTAssertEqual(DeimosReplay.exitCode(filmsPassed: [false], writeFailed: false), 1)
        XCTAssertEqual(DeimosReplay.exitCode(filmsPassed: [], writeFailed: false), 1, "no film run → not a pass")
        XCTAssertNotEqual(DeimosReplay.exitCode(filmsPassed: [true], writeFailed: true), 0,
                          "a trace that could not be written is a failure of its own")

        // The tool's own de01 run (its pass-by-pass loop, bound 20,000): it agrees with a plain HeadlessRunner run,
        // reads the score at byte 4808, and its last line is the G4 line built from those numbers.
        let report = try DeimosReplay.replay(tag: "de01", film: de01, assets: ReplayTestData.getAssets())
        if report.result.endReason == .bound { XCTFail("de01 replay reached the 20,000-pass bound") }
        var plain = try HeadlessRunner(assets: ReplayTestData.getAssets(), film: de01)
        let reference = plain.run(maxPasses: DeimosReplay.maxPasses)
        XCTAssertEqual(report.result.endReason, reference.endReason)
        XCTAssertEqual(report.result.cursor, reference.cursor)
        XCTAssertEqual(report.result.passes, reference.passes)
        XCTAssertEqual(report.result.endScore, reference.endScore)
        XCTAssertEqual(report.scoreAtLastRead, reference.scoreAtRead4808, "read 4809 = byte 4808")
        XCTAssertEqual(report.result.trace?.rows.count, reference.passes, "a trace row per pass")
        let lines = DeimosReplay.lines(report)
        XCTAssertEqual(lines.last, DeimosReplay.summaryLine(tag: "de01", film: de01,
                                                           scoreAtLastRead: reference.scoreAtRead4808,
                                                           end: reference.endReason))
        XCTAssertTrue(lines.dropLast().allSatisfy { $0.hasPrefix("de01 ") }, "every line names its film")
        XCTAssertTrue(lines.contains { $0.hasPrefix("de01 P1 score at reads: 1000 = ") && $0.contains(", 4809 = ") },
                      "score at reads 1,000 … 4,809")
    }
}
