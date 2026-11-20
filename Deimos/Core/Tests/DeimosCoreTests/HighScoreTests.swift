import XCTest
@testable import DeimosCore

/// Phase 4 S4 HS — the score-table insertion `FUN_100214c0(result)` (grounding B §2b; loose-ends-session.md §3.1,
/// listing `100214c0..10021940`, simulated there). Expectations are the four simulated rows of loose-ends §3.1, worked
/// by hand from the default table (15000 … 1000, names Mars … Electrofryer, front-end / engine-loop §10).
final class HighScoreTests: XCTestCase {
    private static let fresh = DeimosPrefs.fresh
    private static let names = DeimosPrefs.fresh.highScoreNames
    private static let levelNames: [FourCC: String] = [FourCC("le02")!: "Darius", FourCC("le06")!: "Sixth"]

    private func result(_ p1: Int32, _ p2: Int32, present: [Bool] = [true, true]) -> SessionResult {
        SessionResult(end: .gameOver, isFilm: false, startSector: 1, present: present, scores: [p1, p2],
                      levels: [FourCC("le02")!, FourCC("le06")!], allLevels: false, cheated: false)
    }

    private func insert(_ r: SessionResult, into prefs: DeimosPrefs = fresh) -> HighScoreTable.Insertion {
        HighScoreTable.insert(r, into: prefs) { Self.levelNames[$0] ?? "?" }
    }

    /// The default table's row i: score 15000 − 1000·i, name `names[i]`, sector "New Atlantis".
    private func row(_ i: Int) -> (Int32, String, String) {
        (Int32(15_000 - 1_000 * i), Self.names[i], "New Atlantis")
    }

    private func assertTable(_ p: DeimosPrefs, _ rows: [(Int32, String, String)], _ what: String,
                             file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(rows.count, 15, file: file, line: line)
        XCTAssertEqual(p.highScores, rows.map(\.0), "\(what): scores", file: file, line: line)
        XCTAssertEqual(p.highScoreNames, rows.map(\.1), "\(what): names", file: file, line: line)
        XCTAssertEqual(p.highScoreSectorNames, rows.map(\.2), "\(what): sector names", file: file, line: line)
    }

    /// The four simulated rows of loose-ends §3.1, plus one-player games. idx = the first row strictly below the
    /// score; both qualify: idx1 > idx2 → idx1 + 1; then idx2 ≥ idx1 → idx2 + 1; P1's shift reads the pristine copy
    /// B, then B = A, then P2's shift. The rows written carry A's player names (+0x1233 / +0x1248) and the level's
    /// name (`FUN_100120f0`).
    func testInsertTwoPlayerQuirks() throws {
        let p1 = (Int32(12_500), "Player 1", "Darius")
        // 12500, 9500 → 3, 7: correct.
        var r = insert(result(12_500, 9_500))
        XCTAssertEqual(r.slots, [3, 7])
        let p2a = (Int32(9_500), "Player 2", "Sixth")
        assertTable(r.prefs, [row(0), row(1), row(2), p1, row(3), row(4), row(5), p2a, row(6), row(7), row(8),
                              row(9), row(10), row(11), row(12)], "12500 / 9500")

        // 9500, 9500 → 6, 7: P1 wins the tie.
        r = insert(result(9_500, 9_500))
        XCTAssertEqual(r.slots, [6, 7])
        assertTable(r.prefs, [row(0), row(1), row(2), row(3), row(4), row(5), (9_500, "Player 1", "Darius"), p2a,
                              row(6), row(7), row(8), row(9), row(10), row(11), row(12)], "9500 / 9500")

        // Quirk (a): 9500, 12500 → 7, 3 — Vodi's 9000 is lost and Fisj's 8000 is listed twice.
        r = insert(result(9_500, 12_500))
        XCTAssertEqual(r.slots, [7, 3])
        assertTable(r.prefs, [row(0), row(1), row(2), (12_500, "Player 2", "Sixth"), row(3), row(4), row(5),
                              (9_500, "Player 1", "Darius"), row(7), row(7), row(8), row(9), row(10), row(11),
                              row(12)], "9500 / 12500 (quirk a)")
        XCTAssertFalse(r.prefs.highScoreNames.contains("Vodi"), "the row just below P1's first slot is lost")

        // Quirk (b): 14500, 14600 → 1, 2 — P1 listed above a higher P2.
        r = insert(result(14_500, 14_600))
        XCTAssertEqual(r.slots, [1, 2])
        assertTable(r.prefs, [row(0), (14_500, "Player 1", "Darius"), (14_600, "Player 2", "Sixth"), row(1),
                              row(2), row(3), row(4), row(5), row(6), row(7), row(8), row(9), row(10), row(11),
                              row(12)], "14500 / 14600 (quirk b)")

        // A one-player game reports P2's slot present with score 0: it is tested and never qualifies.
        r = insert(result(12_500, 0))
        XCTAssertEqual(r.slots, [3, nil])
        // A slot that is not present is not tested at all.
        r = insert(result(12_500, 20_000, present: [true, false]))
        XCTAssertEqual(r.slots, [3, nil])
        // The names come from the prefs' remembered player names, and the level name from the level data.
        var named = Self.fresh
        named.playerNames = ["ACE", "BOB"]
        r = insert(result(12_500, 9_500), into: named)
        XCTAssertEqual(r.prefs.highScoreNames[3], "ACE")
        XCTAssertEqual(r.prefs.highScoreNames[7], "BOB")
        XCTAssertEqual(r.prefs.playerNames, ["ACE", "BOB"])
        let a = try TestAssets.loaded.get()
        let real = HighScoreTable.insert(result(12_500, 0), into: Self.fresh, assets: a)
        XCTAssertEqual(real.prefs.highScoreSectorNames[3], "Darius",
                       "le02's level name (loose-ends worked example step 8)")
        // Everything but the table is the prefs as handed in.
        XCTAssertEqual(real.prefs.keyTable, Self.fresh.keyTable)
        XCTAssertEqual(real.prefs.intPrefs, Self.fresh.intPrefs)
    }

    /// A tie ranks below (`10021520 cmpw; ble next`: strict): a score equal to row i goes below it; equal to the
    /// last row it does not qualify; one point more takes the last row.
    func testInsertTieRanksBelow() {
        var r = insert(result(12_000, 0))
        XCTAssertEqual(r.slots, [4, nil], "12000 ties El B's 12000 at row 3 and goes below it")
        XCTAssertEqual(r.prefs.highScores[3], 12_000)
        XCTAssertEqual(r.prefs.highScoreNames[3], "El B")
        XCTAssertEqual(r.prefs.highScoreNames[4], "Player 1")
        XCTAssertEqual(r.prefs.highScores[4], 12_000)
        r = insert(result(15_000, 0))
        XCTAssertEqual(r.slots, [1, nil], "a tie with the top score is second")
        r = insert(result(1_000, 0))
        XCTAssertEqual(r.slots, [nil, nil], "a tie with the last row does not qualify")
        XCTAssertEqual(r.prefs, Self.fresh, "nothing changes")
        r = insert(result(1_001, 0))
        XCTAssertEqual(r.slots, [14, nil])
        XCTAssertEqual(r.prefs.highScoreNames[14], "Player 1")
        XCTAssertEqual(Array(r.prefs.highScoreNames.prefix(14)), Array(Self.names.prefix(14)))
        // Two players tied with each other between the same rows: P1 first (both 12000 → 4, 5).
        r = insert(result(12_000, 12_000))
        XCTAssertEqual(r.slots, [4, 5])
        // Pushed off the table. P1: idx1 14 (1500 > 1000) below P2's 0 → 15 → off; only P2's row is written.
        r = insert(result(1_500, 20_000))
        XCTAssertEqual(r.slots, [nil, 0])
        XCTAssertEqual(r.prefs.highScores, [20_000] + Array(Self.fresh.highScores.prefix(14)))
        XCTAssertEqual(r.prefs.highScoreNames[0], "Player 2")
        // P2: both 14 → idx2 15 → off; P1 takes the last row.
        r = insert(result(1_500, 1_200))
        XCTAssertEqual(r.slots, [14, nil])
        XCTAssertEqual(r.prefs.highScores, Array(Self.fresh.highScores.prefix(14)) + [1_500])
        XCTAssertEqual(r.prefs.highScoreNames[14], "Player 1")
    }
}
