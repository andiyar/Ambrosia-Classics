import BubbleTroubleCore
import Foundation
import XCTest

/// Task 11 — the FILM replay harness (docs/plans/2026-10-03-btx-core-and-film-harness.md §Task 11; Invariant 14;
/// FILM-oracle paragraph (b); G2, G4).
///
/// Sources: `_PlayGame @ 00018247` driven in demo mode (`gGameMode == 1`) at level = FILM id with
/// `SetQDGlobalsRandomSeed(FILM.seed)` (replay-oracle.md §2–§3), stopped by the loop-top `gPlayGame == 0` exit.
///
/// The bar is behavioural self-consistency, NOT equality with the original: the bank derives no FILM end state
/// (replay-oracle.md §6). Data-gated: every test needs `HECTORKIT_DATA_BTX`.
final class FilmReplayTests: XCTestCase {

    /// `FILM.count` per id (data-formats.md §3; the plan's G2 table).
    private static let expectedCounts: [Int: Int] = [1: 1118, 2: 846, 3: 943, 4: 890]

    // Diagnosis protocol open (plan §Diagnosis protocol): these FILMs currently end by the hero's death. Remove an id only with a decompile-cited sim fix; this test then FAILS until the set is updated.
    static let knownDiverging: Set<Int> = [2, 3, 4]

    /// Per FILM: accepted with every sample consumed (Invariant 14) — or, for a known-diverging FILM, NOT accepted,
    /// so a fix that makes it pass forces `knownDiverging` to be updated.
    func testAllFourFilmsEndByCountExhaustion() throws {
        let files = try BTXTestData.files()
        for filmID in 1...4 {
            let result = try FilmReplay.run(filmID: filmID, files: files)
            let row = "\n\(FilmReplayResult.header)\n\(result.row)"
            let count = try XCTUnwrap(Self.expectedCounts[filmID])
            XCTAssertEqual(result.count, count, "FILM \(filmID) count\(row)")
            if Self.knownDiverging.contains(filmID) {
                XCTAssertFalse(result.accepted,
                               "FILM \(filmID) is now accepted — remove it from knownDiverging (with the fix's citation)\(row)")
            } else {
                XCTAssertTrue(result.accepted, "FILM \(filmID) not accepted\(row)")
                XCTAssertEqual(result.samplesConsumed, count, "FILM \(filmID) samples\(row)")
            }
        }
    }

    /// G4: two traced runs of each FILM produce identical per-frame reports and identical results.
    func testReplayIsDeterministic() throws {
        let files = try BTXTestData.files()
        for filmID in 1...4 {
            let a = try FilmReplay.run(filmID: filmID, files: files, trace: true)
            let b = try FilmReplay.run(filmID: filmID, files: files, trace: true)
            let reports = try XCTUnwrap(a.reports, "FILM \(filmID): trace: true must fill reports")
            XCTAssertEqual(reports.count, a.frames, "FILM \(filmID): one report per frame")
            XCTAssertEqual(a.reports, b.reports, "FILM \(filmID) per-frame reports differ between runs")
            XCTAssertEqual(a, b, "FILM \(filmID) results differ between runs\n\(a.row)\n\(b.row)")
        }
    }
}
