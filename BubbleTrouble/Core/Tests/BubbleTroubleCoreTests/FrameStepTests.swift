@testable import BubbleTroubleCore
import Foundation
import XCTest

/// Task 10 — the `_PlayGame` frame step and its end conditions
/// (docs/plans/2026-10-03-btx-core-and-film-harness.md §Task 10; Invariants 5, 8, 9, 14; Research notes 19–22).
///
/// Sources: `_PlayGame @ 00018247` (the loop body: hero state machine with `_CheckNewEnemies` in its state-2 branch,
/// the `gNumNormalBlocks` recount, the process calls, the draw pass, the end-of-level and FILM-count checks),
/// `_FinishLevel @ 00010eb7`, `_AreAllEnemiesSquished @ 00010e9b`, `_SubtractLife @ 0001058a`.
///
/// The FILM 1 numbers are the plan's Research note 22 checkpoints [Python; QuickDraw LCG assumed] — SELF-DERIVED, not
/// bank-derived. Synthetic worlds use `GameState.testWorld` with the air-bubble pref off (the launcher's tables are
/// not built by `testWorld`) and `ScriptedInput` idle samples.
final class FrameStepTests: XCTestCase {

    private static let idle = FilmSample(up: false, down: false, left: false, right: false, push: false)

    // MARK: - Helpers

    /// FILM 1 from the demo prologue; one report per frame, frames 1…`frames`.
    private func runFilm1(frames: Int, each: (Int, GameState) -> Void = { _, _ in }) throws -> [FrameReport] {
        let files = try BTXTestData.files()
        let film = try files.film(1)
        var state = try GameState.newGame(level: 1, mode: .demo, seed: film.seed, files: files)
        var input = FilmInput(film: film)
        var reports: [FrameReport] = []
        for f in 1...frames {
            XCTAssertTrue(state.playing, "FILM 1 stopped before frame \(f): \(state.pendingStops)")
            reports.append(state.stepFrame(input: &input))
            each(f, state)
        }
        return reports
    }

    /// An all-empty maze with normal bubbles at the given cells (hero starts at (7,6)).
    private func world(normals: [(Int, Int)], totalEnemies: Int = 4, maxActive: Int = 0) -> GameState {
        var maze = try! Maze(data: Data(count: Maze.byteCount))
        for (c, r) in normals { maze[c, r] = CellCode.normal }
        var config = SessionConfig()
        config.prefs.airBubbles = false
        return GameState.testWorld(maze: maze, totalEnemies: totalEnemies, maxActive: maxActive,
                                   pool: [Int16(totalEnemies), 0, 0, 0, 0, 0], config: config)
    }

    private func idle(_ count: Int) -> ScriptedInput {
        ScriptedInput(samples: Array(repeating: Self.idle, count: count))
    }

    /// Steps until the end of frame `f`, asserting no stop fired on the way.
    private func step<I: InputSource>(_ state: inout GameState, _ input: inout I, through f: Int,
                                      file: StaticString = #filePath, line: UInt = #line) {
        while Int(state.frame) < f {
            let report = state.stepFrame(input: &input)
            XCTAssertTrue(report.stops.isEmpty, "frame \(report.frame) stops \(report.stops)", file: file, line: line)
        }
    }

    /// A hatched piranha in slot 0 at (col,row) moved `dy` px down from the cell, heading `dir`, post-hatch
    /// delay set (no AI this frame), counted active.
    private func placeEnemy(_ state: inout GameState, col: Int, row: Int, dy: Int16, dir: Direction) {
        var e = Enemy()
        e.state = 1
        e.type = 1
        e.spriteSet = 0x1b
        e.animFrame = 1
        e.tier = 4
        e.col = Int8(col)
        e.row = Int8(row)
        e.direction = dir
        e.rect = QDRect.cell(col: col, row: row)
        e.rect.offset(dx: 0, dy: dy)
        e.prevRect = e.rect
        e.postHatchDelay = true
        state.enemies[0] = e
        state.numEnemiesActive = 1
    }

    // MARK: - Data-gated (FILM 1)

    /// Research note 22: total draws 191 / 192 / 192 / 192 / 192 / 198 / 208 / 208 / 209 at the end of frames
    /// 30 / 31 / 70 / 71 / 81 / 82 / 83 / 116 / 117; hero state 2 first at frame 71; samples consumed 0 at frame 70,
    /// 1 at 71, 12 at 82; time bonus 2500 at frame 100, 2450 at 101.
    func testFilm1Checkpoints() throws {
        var timeBonus: [Int: Int32] = [:]
        let reports = try runFilm1(frames: 117) { f, state in timeBonus[f] = state.timeBonus }
        let expected: [(frame: Int, total: Int)] = [(30, 191), (31, 192), (70, 192), (71, 192), (81, 192),
                                                    (82, 198), (83, 208), (116, 208), (117, 209)]
        for (f, total) in expected {
            XCTAssertEqual(reports[f - 1].frame, UInt16(f))
            XCTAssertEqual(reports[f - 1].totalDraws, total, "total draws at the end of frame \(f)")
        }
        XCTAssertEqual(reports.first { $0.heroState == 2 }?.frame, 71, "first state-2 frame")
        XCTAssertEqual(reports[69].heroState, 1)
        XCTAssertEqual(reports[69].samplesConsumed, 0, "samples at frame 70")
        XCTAssertEqual(reports[70].samplesConsumed, 1, "samples at frame 71")
        XCTAssertEqual(reports[81].samplesConsumed, 12, "samples at frame 82")
        XCTAssertEqual(timeBonus[100], 2500)
        XCTAssertEqual(timeBonus[101], 2450)
        XCTAssertTrue(reports.allSatisfy { $0.stops.isEmpty && !$0.heroCaughtThisFrame })
    }

    /// Research note 22: egg slot 0 laid frame 82 in (0,6), dir 2, piranha; slot 1 laid frame 83 in (11,6), dir 1;
    /// enemy 0 state 3 at frame 93, hatched (state 1) at 154; its egg cell (0,6) popping (40) at 148, empty at 156.
    func testFilm1EggTimeline() throws {
        var firstState3: Int?, firstHatched: Int?, firstPopping: Int?, firstEmptyAfterPop: Int?
        _ = try runFilm1(frames: 156) { f, state in
            let e0 = state.enemies[0], e1 = state.enemies[1]
            switch f {
            case 81:
                XCTAssertEqual(e0.state, 0, "no egg before frame 82")
            case 82:
                XCTAssertEqual(e0.state, 2)
                XCTAssertEqual(CellRef(col: e0.col, row: e0.row), CellRef(col: 0, row: 6))
                XCTAssertEqual(e0.direction, .down)
                XCTAssertEqual(e0.type, 1)
                XCTAssertEqual(e0.spriteSet, 0x1b)
                XCTAssertEqual(state.maze[0, 6], CellCode.egg)
                XCTAssertEqual(e1.state, 0, "slot 1 still free at frame 82")
            case 83:
                XCTAssertEqual(e1.state, 2)
                XCTAssertEqual(CellRef(col: e1.col, row: e1.row), CellRef(col: 11, row: 6))
                XCTAssertEqual(e1.direction, .up)
                XCTAssertEqual(e1.type, 1)
            default:
                break
            }
            if firstState3 == nil && e0.state == 3 { firstState3 = f }
            if firstHatched == nil && f > 82 && e0.state == 1 { firstHatched = f }
            if firstPopping == nil && state.maze[0, 6] == CellCode.popping { firstPopping = f }
            if firstPopping != nil && firstEmptyAfterPop == nil && state.maze[0, 6] == CellCode.empty {
                firstEmptyAfterPop = f
            }
        }
        XCTAssertEqual(firstState3, 93)
        XCTAssertEqual(firstHatched, 154)
        XCTAssertEqual(firstPopping, 148)
        XCTAssertEqual(firstEmptyAfterPop, 156)
    }

    // MARK: - Synthetic

    /// Invariant 14: the FILM count runs out on the very frame the level-complete +70 stop fires → both reasons are
    /// reported on that frame.
    func testStopReasonsSameFrame() {
        var state = world(normals: [(2, 2), (3, 3), (12, 9)], totalEnemies: 1)
        let e = 20, stopFrame = e + 71
        var input = idle(stopFrame)                    // one sample per state-2 frame from frame 1
        step(&state, &input, through: e - 1)
        placeEnemy(&state, col: 3, row: 3, dy: 5, dir: .up)
        step(&state, &input, through: stopFrame - 1)
        XCTAssertTrue(state.playing)
        let report = state.stepFrame(input: &input)
        XCTAssertEqual(report.frame, UInt16(stopFrame))
        XCTAssertEqual(report.samplesConsumed, stopFrame)
        XCTAssertEqual(report.stops, [.levelCompleted, .countExhausted])
        XCTAssertFalse(state.playing)
    }

    /// C6 / Research note 19: `gNumNormalBlocks` holds the 100 sentinel until frame 1's recount, then the real count;
    /// the recount reaching 0 awards 2000 ×multiplier and `_FinishLevel` sets squished = total.
    func testNormalBlockSentinel() {
        var state = world(normals: [(2, 2), (12, 9)], totalEnemies: 4)
        var input = idle(50)
        XCTAssertEqual(state.numNormalBlocks, 100)
        _ = state.stepFrame(input: &input)
        XCTAssertEqual(state.numNormalBlocks, 2)
        state.maze[2, 2] = CellCode.empty
        state.maze[12, 9] = CellCode.empty
        state.multiplier = 3
        let score = state.score
        let report = state.stepFrame(input: &input)
        XCTAssertEqual(state.numNormalBlocks, 0)
        XCTAssertEqual(report.score, score + 2000 * 3)
        XCTAssertEqual(state.numEnemiesSquished, 4, "squished = total (LEVL w6)")
        XCTAssertTrue(state.isEndOfLevel)
        XCTAssertEqual(state.endOfLevelTime, 2)
        // No further recount once it reached 0.
        state.maze[5, 5] = CellCode.normal
        _ = state.stepFrame(input: &input)
        XCTAssertEqual(state.numNormalBlocks, 0)
        XCTAssertEqual(state.score, score + 6000)
    }

    /// Research note 21: the last enemy squished at frame E → `gIsEndOfLevel` at E, the stop reported on frame
    /// E + 71 (`gEndOfLevelTime + 0x46 < frame`), not earlier.
    func testLevelCompleteStopsAtPlus71() {
        var state = world(normals: [(2, 2), (3, 3), (12, 9)], totalEnemies: 1)
        var input = idle(400)
        let e = 20
        step(&state, &input, through: e - 1)
        placeEnemy(&state, col: 3, row: 3, dy: 5, dir: .up)          // entering (3,3), a normal bubble
        let squish = state.stepFrame(input: &input)
        XCTAssertEqual(squish.frame, UInt16(e))
        XCTAssertEqual(state.numEnemiesSquished, 1)
        XCTAssertEqual(state.enemies[0].state, 0, "dead enemy freed by the draw pass")
        XCTAssertEqual(state.numEnemiesActive, 0)
        XCTAssertTrue(state.isEndOfLevel)
        XCTAssertEqual(state.endOfLevelTime, UInt16(e))
        XCTAssertTrue(squish.stops.isEmpty)
        step(&state, &input, through: e + 70)
        XCTAssertTrue(state.playing)
        let report = state.stepFrame(input: &input)
        XCTAssertEqual(report.frame, UInt16(e + 71))
        XCTAssertEqual(report.stops, [.levelCompleted])
        XCTAssertFalse(state.playing)
    }

    /// Research notes 20–21: caught at frame C (by `_ProcessEnemies`, before `_ProcessHero`) → state 3 at C, state 4
    /// at C + 31 (`stateStart + 0x1e < frame`), the demo stop on frame C + 97 (`stateStart + 0x41 < frame`); no
    /// sample is consumed from frame C on.
    func testDemoDeathStopsAtPlus97() {
        var state = world(normals: [(2, 2), (12, 9)], totalEnemies: 4)
        var input = idle(400)
        let c = 20
        step(&state, &input, through: c - 1)
        XCTAssertEqual(input.samplesConsumed, c - 1)
        placeEnemy(&state, col: 7, row: 6, dy: 0, dir: .left)       // on the hero's cell
        let caught = state.stepFrame(input: &input)
        XCTAssertEqual(caught.frame, UInt16(c))
        XCTAssertTrue(caught.heroCaughtThisFrame)
        XCTAssertEqual(caught.heroState, 3)
        XCTAssertEqual(caught.samplesConsumed, c - 1)
        var stateFourFrame: Int?
        while state.playing {
            let r = state.stepFrame(input: &input)
            XCTAssertFalse(r.heroCaughtThisFrame, "frame \(r.frame)")
            XCTAssertEqual(r.samplesConsumed, c - 1, "frame \(r.frame)")
            if stateFourFrame == nil && r.heroState == 4 { stateFourFrame = Int(r.frame) }
            if r.frame < UInt16(c + 97) {
                XCTAssertTrue(r.stops.isEmpty, "frame \(r.frame) stops \(r.stops)")
            } else {
                XCTAssertEqual(r.frame, UInt16(c + 97))
                XCTAssertEqual(r.stops, [.heroDeathAnimationDone])
            }
            if r.frame > UInt16(c + 97) { break }
        }
        XCTAssertEqual(stateFourFrame, c + 31)
        XCTAssertEqual(state.frame, UInt16(c + 97))
        XCTAssertEqual(state.lives, 2, "_SubtractLife on 3 → 4")
    }
}
