import XCTest
import DeimosCore
import DeimosHost
@testable import deimos_replay

/// The replay gate G4 (plan H3, "G4 — the replay gate, and the miss path"): the shipped demo film de01 replayed
/// through the simulation must reach player 1's recorded score at the instant the recorder stored it. A separate
/// bundle, excluded from G2 by `--skip DeimosReplayTests`.
final class ReplayGateTests: XCTestCase {

    /// G4.1: P1's decoded score at the read that consumes film byte 4808 (cursor 4808 → 4809) is 25,050 — what
    /// `FUN_10009830` stored at `1002a42c` while recording (the film's +0x14 − 0xb3ac2). Bound: 20,000 passes.
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
    /// then PASS / FAIL for the gate film de01 (the replica's score at the read of the last recorded byte against the
    /// film's stored score), INFO for the others. Exit 0 iff de01 ran and passed.
    func testCLISummaryLine() throws {
        let de01 = try ReplayTestData.film("de01")
        XCTAssertEqual(DeimosReplay.summaryLine(tag: "de01", film: de01, scoreAtLastRead: 25_050, end: .filmEnd),
                       "de01 le07 seed 0x469c2: score 25050 at read 4809 (end: filmEnd) PASS")
        XCTAssertEqual(DeimosReplay.summaryLine(tag: "de01", film: de01, scoreAtLastRead: 24_950, end: .gameOver),
                       "de01 le07 seed 0x469c2: score 24950 at read 4809 (end: gameOver) FAIL")
        XCTAssertEqual(DeimosReplay.summaryLine(tag: "de01", film: de01, scoreAtLastRead: nil, end: .bound),
                       "de01 le07 seed 0x469c2: score none at read 4809 (end: bound) FAIL")
        XCTAssertTrue(DeimosReplay.passes(tag: "de01", film: de01, scoreAtLastRead: 25_050))
        XCTAssertFalse(DeimosReplay.passes(tag: "de01", film: de01, scoreAtLastRead: 25_051))

        let de02 = try ReplayTestData.film("de02")
        let info = DeimosReplay.summaryLine(tag: "de02", film: de02, scoreAtLastRead: de02.players[0].score,
                                            end: .filmEnd)
        let seed = String(de02.seed, radix: 16)
        XCTAssertEqual(info, "de02 \(de02.level) seed 0x\(seed): score \(de02.players[0].score) at read "
                       + "\(de02.players[0].frames) (end: filmEnd) INFO (recorded \(de02.players[0].score))")
        XCTAssertFalse(DeimosReplay.passes(tag: "de02", film: de02, scoreAtLastRead: de02.players[0].score),
                       "only de01 is the gate")

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

        XCTAssertEqual(DeimosReplay.exitCode(gatePassed: true), 0)
        XCTAssertEqual(DeimosReplay.exitCode(gatePassed: false), 1)
        XCTAssertEqual(DeimosReplay.exitCode(gatePassed: nil), 1, "de01 not run → not a pass")

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
