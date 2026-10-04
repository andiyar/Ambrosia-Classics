import Foundation
import XCTest
@testable import AkiCore

/// P2.7 — the `_p` statistics writes (rules §14, R1), the Stats dialog fill (file-formats §2.2, R8)
/// and the 13–17 decoration draw (levels §3). The nib test skips (naming AKI_DATA_12) without the 1.2.0 data.
final class StatsTests: XCTestCase {

    func testWinRecordsBestAndUnlocksNext() {
        var s = GameSettings.defaults
        Stats.recordWin(&s, level: 0, elapsed: 200, difficulty: .medium)
        XCTAssertEqual(s.wins[0], 1)
        XCTAssertEqual(s.bestTimes[0], 200)
        XCTAssertEqual(s.unlocked[1], 1)
        Stats.recordWin(&s, level: 0, elapsed: 250, difficulty: .medium)
        XCTAssertEqual(s.bestTimes[0], 200)
        Stats.recordWin(&s, level: 0, elapsed: 150, difficulty: .medium)
        XCTAssertEqual(s.bestTimes[0], 150)
        XCTAssertEqual(s.wins[0], 3)
    }

    func testPracticeWinCountsOnly() {
        var s = GameSettings.defaults
        Stats.recordWin(&s, level: 0, elapsed: 200, difficulty: .practice)
        XCTAssertEqual(s.wins[0], 1)
        XCTAssertEqual(s.bestTimes[0], 0)
        XCTAssertEqual(s.unlocked[1], 0)
    }

    func testLevel12WinUnlocksNothingBeyond() {
        var s = GameSettings.defaults
        let before = s.unlocked
        Stats.recordWin(&s, level: 11, elapsed: 90, difficulty: .hard)
        XCTAssertEqual(s.wins[11], 1)
        XCTAssertEqual(s.bestTimes[11], 90)
        XCTAssertEqual(s.unlocked, before)
    }

    func testCustomLevelsRecordNothing() {
        var s = GameSettings.defaults
        let before = s
        Stats.recordWin(&s, level: 13, elapsed: 100, difficulty: .easy)
        Stats.recordLoss(&s, level: 13)
        Stats.recordGiveUp(&s, level: 13)
        XCTAssertEqual(s, before)
    }

    func testLossAndGiveUpCounters() {
        var s = GameSettings.defaults
        Stats.recordLoss(&s, level: 4)
        XCTAssertEqual(s.losses[4], 1)
        XCTAssertEqual(s.giveUps[4], 0)
        Stats.recordGiveUp(&s, level: 4)
        XCTAssertEqual(s.giveUps[4], 1)
        XCTAssertEqual(s.losses[4], 1)
    }

    func testTableSplitsBestTimeAndSumsTotals() {
        var s = GameSettings.defaults
        s.bestTimes[0] = 125
        s.wins = [1, 2] + [Int16](repeating: 0, count: 10)
        s.losses[3] = 4
        s.giveUps[5] = 6
        let t = Stats.table(s)
        XCTAssertEqual(t.rows.count, 12)
        XCTAssertEqual(t.rows[0], Stats.Row(wins: 1, losses: 0, giveUps: 0, bestMinutes: 2, bestSeconds: 5))
        XCTAssertEqual([t.rows[1].bestMinutes, t.rows[1].bestSeconds], [0, 0])
        XCTAssertEqual(t.rows[1].wins, 2)
        XCTAssertEqual(t.totalWins, 3)
        XCTAssertEqual(t.totalLosses, 4)
        XCTAssertEqual(t.totalGiveUps, 6)
    }

    func testRandomDecorationIs13To17() {
        var rng = SplitMix64(seed: 3)
        var seen = Set<Int>()
        for _ in 0..<1000 {
            let d = AkiLevels.randomDecoration(using: &rng)
            XCTAssertTrue((13...17).contains(d), "\(d)")
            seen.insert(d)
        }
        XCTAssertEqual(seen, Set(13...17))
        XCTAssertTrue(AkiLevels.isBuiltIn(11))
        XCTAssertFalse(AkiLevels.isBuiltIn(12))
        XCTAssertFalse(AkiLevels.isBuiltIn(13))
    }

    func testStatsNibCarriesEveryFilledControlID() throws {
        let nib = try CarbonNib(data: akiLproj("English", "Aki.nib/objects.xib"))
        let w = try XCTUnwrap(nib.window(named: "Stats"))
        let ids = AkiLevels.statsControlIDs
        let texts = w.controls.filter { $0.kind == "StaticText" }
        func column(_ id: Int) -> [Int] { texts.filter { $0.controlID == id }.map(\.x) }
        let columns = [(ids.minutes, 144), (ids.seconds, 206), (ids.wins, 267), (ids.losses, 312), (ids.giveUps, 374)]
        var found = 0
        for (base, x) in columns {
            for i in 0..<12 {
                XCTAssertEqual(column(base + i), [x], "controlID \(base + i)")
                found += column(base + i).count
            }
        }
        XCTAssertEqual(ids.totals, [40, 41, 42])
        for (id, x) in zip(ids.totals, [267, 312, 374]) {
            XCTAssertEqual(column(id), [x], "controlID \(id)")
            found += column(id).count
        }
        XCTAssertEqual(found, 63)
        let firstTwo = try XCTUnwrap(w.controls.first { $0.controlID == 2 })
        XCTAssertEqual(firstTwo.kind, "Button")
        XCTAssertEqual(firstTwo.title, "OK")
    }
}
