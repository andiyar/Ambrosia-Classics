@testable import BubbleTroubleCore
import Foundation
import XCTest

/// Task C2 (plan 2026-10-04 btx-playable) — sound cues from the simulation: `_PlayMySnd @ 00026a7b` at each call
/// site, in order, and the 5-entry delayed queue flushed by `_Sounds_CheckDelayedSounds @ 000268a1` after
/// `_TimeBonus_Process`. Sites and anchors: `Sim/Sounds.swift`. No test here may see an RNG draw the core did not
/// already make (Invariant 3).
final class SoundCueTests: XCTestCase {

    private static let idle = FilmSample(up: false, down: false, left: false, right: false, push: false)

    /// An empty maze but for one normal bubble at (0,0) (so the first frame's recount does not award "all bubbles
    /// gone"), hero (7,6) in state 2 facing left, no enemies, air bubbles off (the launcher's tables are not built by
    /// `testWorld`).
    private func world() -> GameState {
        var maze = try! Maze(data: Data(count: Maze.byteCount))
        maze[0, 0] = CellCode.normal
        var config = SessionConfig()
        config.prefs.airBubbles = false
        return GameState.testWorld(maze: maze, totalEnemies: 0, maxActive: 0, pool: [0, 0, 0, 0, 0, 0],
                                   config: config)
    }

    private func cue(_ slot: Int, _ priority: Int, _ delay: Int = 0) -> SoundCue {
        SoundCue(slot: slot, priority: priority, delayFrames: delay)
    }

    // MARK: - Call sites

    /// `_PushBlock` tail-jumps to `_PlayMySnd(5, 10, 0)` after the maze write (0001be36).
    func testPushSuccessCuesSlot5() {
        var state = world()
        state.maze[6, 6] = CellCode.normal                       // in front of the left-facing hero, empty beyond
        XCTAssertEqual(state.heroPushCrushCheck(), 1)
        XCTAssertEqual(state.numActiveBlocks, 1)
        XCTAssertEqual(state.soundsThisFrame, [cue(5, 10)])
    }

    /// The thud `_PlayMySnd(7, 10, 0)`: a wall / cluster in front (00022285) and a jewel that cannot move (00022367).
    func testPushFailCuesSlot7() {
        var state = world()
        state.maze[6, 6] = CellCode.cluster
        XCTAssertEqual(state.heroPushCrushCheck(), 1)
        XCTAssertEqual(state.soundsThisFrame, [cue(7, 10)])

        state = world()
        state.maze[6, 6] = CellCode.wall
        XCTAssertEqual(state.heroPushCrushCheck(), 1)
        XCTAssertEqual(state.soundsThisFrame, [cue(7, 10)])

        state = world()
        state.maze[6, 6] = CellCode.jewel
        state.maze[5, 6] = CellCode.normal                       // no target yet, blocked → thud, no push
        XCTAssertEqual(state.heroPushCrushCheck(), 1)
        XCTAssertEqual(state.numActiveBlocks, 0)
        XCTAssertEqual(state.soundsThisFrame, [cue(7, 10)])
    }

    /// `_CrushBlock` (0001bcda) "Pop" 6/10 on a blocked bubble; a bonus bubble pop (`_Bonus_Pop`) cues 6/10 then
    /// 26/20 before its reward; the dynamite variant adds "Ignite" 24/10 for the new fuse (0001c286).
    func testBubblePopCuesSlot6() {
        var state = world()
        state.maze[6, 6] = CellCode.normal
        state.maze[5, 6] = CellCode.normal
        XCTAssertEqual(state.heroPushCrushCheck(), 2)
        XCTAssertEqual(state.soundsThisFrame, [cue(6, 10)])

        state = world()
        state.maze[6, 6] = CellCode.dynamite
        state.maze[5, 6] = CellCode.wall
        XCTAssertEqual(state.heroPushCrushCheck(), 2)
        XCTAssertEqual(state.soundsThisFrame, [cue(6, 10), cue(24, 10)])

        state = world()
        state.bonus[0].armed = true
        state.bonus[0].type = 0                                   // no reward
        state.bonusPop(0)
        XCTAssertEqual(state.soundsThisFrame, [cue(6, 10), cue(26, 20)])
    }

    /// `_HeroCaught` picks its sound from the `GetRandomFast(0,1)` the core already made: kind 1 → 37 (draw 0) or
    /// 10, at once; kind 2 → "Squish" 0/20 now, then 45 (draw 0) or 11 queued +5 frames. Exactly one draw for kind 1.
    func testCatchCuesOooerOrAyeeeeWithoutExtraDraw() {
        var seen = Set<Int>()
        for seed: UInt32 in 1...12 {
            var state = GameState.testWorld(maze: try! Maze(data: Data(count: Maze.byteCount)), seed: seed,
                                            totalEnemies: 0, maxActive: 0, pool: [0, 0, 0, 0, 0, 0])
            var probe = state.rng
            let expected = probe.fast(0, 1) == 0 ? 0x25 : 10
            let before = state.rng.drawCount
            state.heroCaught(kind: 1)
            XCTAssertEqual(state.rng.drawCount - before, 1, "seed \(seed): kind 1 makes exactly its one draw")
            XCTAssertEqual(state.soundsThisFrame, [cue(expected, 20)], "seed \(seed)")
            seen.insert(expected)

            var blast = GameState.testWorld(maze: try! Maze(data: Data(count: Maze.byteCount)), seed: seed,
                                            totalEnemies: 0, maxActive: 0, pool: [0, 0, 0, 0, 0, 0])
            var probe2 = blast.rng
            let expected2 = probe2.fast(0, 1) == 0 ? 0x2d : 0xb
            blast.heroCaught(kind: 2)
            XCTAssertEqual(blast.soundsThisFrame, [cue(0, 20)], "seed \(seed)")
            XCTAssertEqual(blast.delayedSounds[0].slot, Int16(expected2), "seed \(seed)")
            XCTAssertEqual(blast.delayedSounds[0].fireAt, 5)
            XCTAssertEqual(blast.delayedSounds[0].priority, 20)
        }
        XCTAssertEqual(seen, [0x25, 10], "both picks occur over the seeds")
    }

    // MARK: - The delayed queue

    /// A `delay` 5 cue made at frame 0 fires in frame 5's `_Sounds_CheckDelayedSounds` (`fireAt <= frame`), not
    /// before, and is listed after that frame's earlier immediate cues; the entry is then free.
    func testDelayedCueFiresAfterDelayFrames() {
        var state = world()
        var input = ScriptedInput(samples: Array(repeating: Self.idle, count: 20))
        state.playMySnd(0x13, priority: 10, delay: 5)
        XCTAssertTrue(state.soundsThisFrame.isEmpty)
        XCTAssertEqual(state.delayedSounds[0].fireAt, 5)
        for f in 1...4 {
            let report = state.stepFrame(input: &input)
            XCTAssertEqual(Int(report.frame), f)
            XCTAssertEqual(report.sounds, [], "frame \(f)")
        }
        let report = state.stepFrame(input: &input)
        XCTAssertEqual(report.frame, 5)
        XCTAssertEqual(report.sounds, [cue(0x13, 10, 5)])
        XCTAssertTrue(state.delayedSounds.allSatisfy(\.isFree))
        XCTAssertEqual(state.stepFrame(input: &input).sounds, [])
    }

    /// Five entries: a sixth delayed call finds none free and plays at once (falls through to `ST_PlaySound`);
    /// the five then fire in entry order. `_NewLevel`'s `_Sounds_InitDelayedSounds` empties the queue.
    func testDelayedQueueHoldsFive() {
        var state = world()
        for slot in 0..<6 {
            state.playMySnd(slot, priority: 10, delay: 3 - slot % 2)     // fire at 3, 2, 3, 2, 3 (+ overflow)
        }
        XCTAssertEqual(GameState.delayedSoundCapacity, 5)
        XCTAssertEqual(state.delayedSounds.map(\.slot), [0, 1, 2, 3, 4])
        XCTAssertEqual(state.soundsThisFrame, [cue(5, 10, 2)], "the sixth overflows and plays now")
        var input = ScriptedInput(samples: Array(repeating: Self.idle, count: 10))
        XCTAssertEqual(state.stepFrame(input: &input).sounds, [])
        XCTAssertEqual(state.stepFrame(input: &input).sounds, [cue(1, 10, 2), cue(3, 10, 2)])
        XCTAssertEqual(state.stepFrame(input: &input).sounds, [cue(0, 10, 3), cue(2, 10, 3), cue(4, 10, 3)])

        state.playMySnd(9, priority: 20, delay: 4)
        XCTAssertFalse(state.delayedSounds[0].isFree)
        state.soundsInitDelayedSounds()
        XCTAssertTrue(state.delayedSounds.allSatisfy(\.isFree))
    }

    /// `_AddHero(1, 1)` cues "Extra Life" 13/20 twice (00022dab, 00022dc7) when the score crosses the next
    /// extra-life mark.
    func testExtraLifeCuesSlot13Twice() {
        var state = world()
        state.addToScore(9990, multiply: true)
        XCTAssertEqual(state.soundsThisFrame, [])
        state.addToScore(10, multiply: true)
        XCTAssertEqual(state.lives, 4)
        XCTAssertEqual(state.soundsThisFrame, [cue(13, 20), cue(13, 20)])
    }

    // MARK: - FILM 1 (self-derived golden)

    /// FILM 1 in full: the cue stream is pinned (count, per-slot histogram and the first cues) so any moved or lost
    /// site shows. SELF-DERIVED from this implementation (not an oracle) — it guards against regressions only.
    func testFilm1CueCountIsStable() throws {
        let files = try BTXTestData.files()
        let film = try files.film(1)
        var state = try GameState.newGame(level: 1, mode: .demo, seed: film.seed, files: files)
        var input = FilmInput(film: film)
        var cues: [(frame: Int, cue: SoundCue)] = []
        while state.playing {
            let report = state.stepFrame(input: &input)
            cues += report.sounds.map { (Int(report.frame), $0) }
        }
        var histogram: [Int: Int] = [:]
        for c in cues { histogram[c.cue.slot, default: 0] += 1 }
        let summary = histogram.keys.sorted().map { "\($0):\(histogram[$0]!)" }.joined(separator: " ")
        let head = cues.prefix(6).map { "\($0.frame)/\($0.cue.slot)/\($0.cue.priority)/\($0.cue.delayFrames)" }
        print("FILM1 cues \(cues.count) [\(summary)] head \(head)")
        XCTAssertEqual(cues.count, Self.film1CueCount)
        XCTAssertEqual(summary, Self.film1Histogram)
        XCTAssertEqual(head, Self.film1Head)
        XCTAssertFalse(cues.contains { $0.cue.slot == 8 || $0.cue.slot == 35 }, "demo: no Hahohaho / End of Level")
    }

    private static let film1CueCount = 42
    private static let film1Histogram = "0:4 5:7 6:10 16:4 19:1 26:1 27:1 28:11 29:2 31:1"
    private static let film1Head = ["71/27/10/0", "148/16/10/0", "149/16/10/0", "271/6/10/0", "283/5/10/0",
                                    "295/28/1/0"]
}
