import FerazelCore
import FerazelRender
import Foundation
import XCTest

/// The random-play bot's input generator (RandomPlayPlan.swift): its own seeded stream, never the game's — the same
/// seed and the same contexts give the same keys, step for step; another seed gives other keys; the direction runs
/// last 5–60 steps; every action is one of the nine prefs actions. Always runs.
final class RandomPlayPlanTests: XCTestCase {

    func testGeneratorIsDeterministic() {
        func sequence(_ seed: UInt64) -> [RandomPlayGenerator.Input] {
            var g = RandomPlayGenerator(seed: seed)
            // Mostly playing, with a stretch of conversation and of pause (the generator holds its programs there).
            return (0..<6000).map { i in
                g.step(context: (2000..<2100).contains(i) ? .conversation : (4000..<4050).contains(i) ? .paused : .playing)
            }
        }
        let a = sequence(0x5eed), b = sequence(0x5eed), c = sequence(0x5eee)
        XCTAssertEqual(a, b, "one seed, one sequence")
        XCTAssertNotEqual(a, c, "another seed, another sequence")
        // The first steps of seed 0x5eed, pinned: a change to the generator changes every bot run's input.
        XCTAssertEqual(a.prefix(4).map(\.description), RandomPlayPlanTests.pinned)
        for input in a {
            XCTAssertTrue(input.actions.allSatisfy { (0..<FerazelPrefs.actionCount).contains($0) }, "\(input)")
            XCTAssertTrue(input.keys.allSatisfy { [0x35, 0x23].contains($0) }, "\(input)")
        }
        // Outside play nothing is pressed but the Caps Lock latch.
        for i in 2000..<2100 { XCTAssertTrue(a[i].actions.isEmpty && a[i].keys.isEmpty) }
        // The direction runs: 5–60 steps each (the last one may be cut by the sequence's end).
        let dirs = a[0..<2000].map { $0.actions.filter { $0 < 4 } }
        var runs: [Int] = [], n = 1
        for i in 1..<dirs.count {
            if dirs[i] == dirs[i - 1] { n += 1 } else { runs.append(n); n = 1 }
        }
        // Two runs in a row may pick the same direction (one longer run): every run is ≥ 5 steps.
        XCTAssertTrue(runs.allSatisfy { $0 >= 5 }, "\(runs)")
        XCTAssertGreaterThan(runs.count, 2000 / 60)
        // Every kind of input shows up in 6,000 steps of play.
        XCTAssertTrue(a.contains { $0.capsLock }, "Caps Lock")
        XCTAssertTrue(a.contains { $0.keys.contains(0x35) }, "Esc")
        XCTAssertTrue(a.contains { $0.keys.contains(0x23) && $0.actions.contains(6) }, "⌘P")
        for action in 4...8 { XCTAssertTrue(a.contains { $0.actions.contains(action) }, "action \(action)") }
    }

    static let pinned = ["a 1,4 k -", "a 1,4 k -", "a 1,4,7 k -", "a 1,4,7 k -"]
}

/// The random-play bot, Core path (RandomPlayPlan.swift has the generator and the play loop): for every level in scope
/// and every seed, a fresh `SweepShell` (VisitSweepTests.swift — the shared driver's game half mirrored: the real
/// renderers on one surface, the shells' modal answers, saved games in memory) boots, New Game is started at the level
/// by the hidden `FerazelLevel` switch (`GameFlow.startLevel`), and the bot plays it for `FERAZEL_BOT_MINUTES`.
/// Headless: no window, no audio.
///
/// Runs only with `FERAZEL_BOT=1` (skipped otherwise): `FERAZEL_BOT=1 swift test --filter RandomPlayTests/testRandomPlay`
/// — or tools/ferazel-random-play.sh, which shards it across processes and survives a trap.
///
/// Not main-actor isolated (Windows XCTest traps on a `@MainActor` test class — see VisitSweepTests); the run enters
/// the main actor with `assumeIsolated`.
final class RandomPlayTests: XCTestCase {

    func testRandomPlay() throws {
        guard RandomPlay.enabled else { throw XCTSkip("set FERAZEL_BOT=1 (tools/ferazel-random-play.sh)") }
        try MainActor.assumeIsolated { try Self.play() }
    }

    @MainActor private static func play() throws {
        let resources = try FerazelData.open(try FerazelData.dataDirectory())
        let lengths = try SweepShell.soundLengths(resources)
        var rows: [RandomPlay.Failure] = []
        var total = RandomPlay.Stats()
        var levels: Set<Int> = [], seeds: Set<Int> = []
        for (i, run) in RandomPlay.runs().enumerated() where RandomPlay.mine(index: i) {
            RandomPlay.progress(run, index: i, step: 0)
            let shell = try SweepShell(resources: resources, files: SweepFiles(), soundLengths: lengths)
            shell.flow.startLevel = run.level
            let (failures, stats) = RandomPlay.play(run, index: i, game: shell)
            rows += failures
            total.add(stats)
            levels.insert(run.level)
            seeds.insert(run.seed)
            for f in failures { RandomPlay.append(f.tsv, to: "failures.tsv") }
            RandomPlay.append(stats.tsv(run), to: "runs.tsv")
        }
        let summary = total.summary(levels: levels.count, seeds: seeds.count)
        print("RANDOM PLAY (Core): " + summary)
        XCTAssertTrue(rows.isEmpty, "\(rows.count) random-play failures — \(summary)\n" + RandomPlay.table(rows))
    }
}

extension SweepShell: BotGame {}
