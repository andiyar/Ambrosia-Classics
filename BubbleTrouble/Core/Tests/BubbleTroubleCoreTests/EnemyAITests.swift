@testable import BubbleTroubleCore
import Foundation
import XCTest

/// Task 9b — `_EnemyAI`, movement, random walk, homing
/// (docs/plans/2026-10-03-btx-core-and-film-harness.md §Task 9b; Research notes 31, 32; Invariants 8, 9, 18;
/// INDEX C11; enemies-ai.md §4a–§4d).
///
/// Sources: `_EnemyAI @ 00014296` (+ folded `_MoveEnemy @ 00012786`, `_CorrectEnemyMazeX/Y`), `_FigureEnemyMove @
/// 00013bd4` (+ folded `_MoveEnemyRandomly @ 0001396f`), `_FigureEnemyRandomness @ 00012d65`, `_CanDoNormalPop @
/// 00012cf4`, `_CanDoNormalOtherPop @ 00012c83`, `_TryAndTurnEnemy @ 000138fe`. All worlds are synthetic
/// (`GameState.testWorld`, zero draws on return). No test reaches a Task 9c seam: no pending action is set, piranhas
/// never try a balloon or a push, and every homing case either turns or has the pop window closed.
final class EnemyAITests: XCTestCase {

    private static func emptyMaze() -> Maze {
        try! Maze(data: Data(count: Maze.byteCount))
    }

    /// A hatched, thinking enemy in slot 0: state 1, aligned at (col,row), tier 4, sprite set by type, post-hatch
    /// delay over, `stateStart = start`, `lastPop = lastPop ?? start`.
    private static func place(_ state: inout GameState, type: Int8, col: Int, row: Int, dir: Direction?,
                              start: UInt16, lastPop: UInt16? = nil) {
        var e = Enemy()
        e.state = 1
        e.type = type
        e.spriteSet = [0x1b, 0x1c, 0x1d, 0x1e][Int(type) - 1]
        e.tier = 4
        e.rect = QDRect.cell(col: col, row: row)
        e.prevRect = e.rect
        e.col = Int8(col)
        e.row = Int8(row)
        e.aligned = true
        e.direction = dir
        e.stateStart = start
        e.lastPop = lastPop ?? start
        e.drawn = true
        e.marker = 0x17
        e.balloonIndex = -1
        state.enemies[0] = e
        state.numEnemiesActive = 1
    }

    private static func world(seed: UInt32 = 1, level: Int = 1) -> GameState {
        GameState.testWorld(maze: emptyMaze(), level: level, seed: seed)
    }

    /// enemies-ai.md §4a (`_MoveEnemy`, tier 4): speeds are recomputed only on aligned calls. Direction 0 keeps the
    /// enemy in place, so each call is one aligned speed step with no movement.
    func testSpeedTables() {
        // Piranha (speed kept in +0x4e): 2 while the bonus runs; bonus ≤ 0 → 4 when |dcol| > 1 or |drow| > 1, else 2.
        var s = Self.world()
        Self.place(&s, type: 1, col: 7, row: 5, dir: nil, start: 0)
        s.hero.col = 0
        s.hero.row = 0
        s.timeBonus = 100
        s.moveEnemy(0)
        XCTAssertEqual(s.enemies[0].speedCounter, 2, "piranha, bonus > 0")
        s.timeBonus = 0
        s.moveEnemy(0)
        XCTAssertEqual(s.enemies[0].speedCounter, 4, "piranha, bonus 0, far")
        s.hero.col = 6
        s.hero.row = 6
        s.moveEnemy(0)
        XCTAssertEqual(s.enemies[0].speedCounter, 2, "piranha, bonus 0, adjacent")
        XCTAssertEqual(s.enemies[0].speed, 0, "the piranha never writes +0x50")

        // Eel: bonus > 0 → 2 within 2 cells (both axes), else 4; bonus ≤ 0 → 2 within 1 cell, else 8.
        s = Self.world()
        Self.place(&s, type: 2, col: 7, row: 5, dir: nil, start: 0)
        s.timeBonus = 100
        s.hero.col = 9
        s.hero.row = 3
        s.moveEnemy(0)
        XCTAssertEqual(s.enemies[0].speed, 2, "eel, bonus > 0, |d| ≤ 2")
        s.hero.col = 10
        s.moveEnemy(0)
        XCTAssertEqual(s.enemies[0].speed, 4, "eel, bonus > 0, far")
        s.timeBonus = 0
        s.moveEnemy(0)
        XCTAssertEqual(s.enemies[0].speed, 8, "eel, bonus 0, far")
        s.hero.col = 6
        s.hero.row = 4
        s.moveEnemy(0)
        XCTAssertEqual(s.enemies[0].speed, 2, "eel, bonus 0, |d| ≤ 1")

        // Shark: the step counter over 13 aligned steps (bonus > 0), then the counter is back at 0.
        s = Self.world()
        Self.place(&s, type: 3, col: 7, row: 5, dir: nil, start: 0)
        s.timeBonus = 100
        var shark: [Int16] = []
        for _ in 0..<13 {
            s.moveEnemy(0)
            shark.append(s.enemies[0].speed)
        }
        XCTAssertEqual(shark, [2, 4, 4, 2, 2, 4, 4, 2, 2, 4, 8, 4, 2])
        XCTAssertEqual(s.enemies[0].speedCounter, 0, "c ≥ 13 → c = 0")
        // A non-aligned call keeps both the speed and the counter.
        s.enemies[0].aligned = false
        s.moveEnemy(0)
        XCTAssertEqual(s.enemies[0].speed, 2)
        XCTAssertEqual(s.enemies[0].speedCounter, 0)

        // Starfish (bonus > 0): 1–3 → 4, 4–6 → 8, 7 → 4, 8 → 2 and c = 0.
        s = Self.world()
        Self.place(&s, type: 4, col: 7, row: 5, dir: nil, start: 0)
        s.timeBonus = 100
        var starfish: [Int16] = []
        for _ in 0..<8 {
            s.moveEnemy(0)
            starfish.append(s.enemies[0].speed)
        }
        XCTAssertEqual(starfish, [4, 4, 4, 8, 8, 8, 4, 2])
        XCTAssertEqual(s.enemies[0].speedCounter, 0)

        // The move itself: by the speed, then col/row and the remainders (folded `_CorrectEnemyMazeX/Y`).
        s = Self.world()
        Self.place(&s, type: 1, col: 7, row: 5, dir: .right, start: 0)
        s.timeBonus = 100
        s.moveEnemy(0)
        XCTAssertEqual(s.enemies[0].rect, QDRect(top: 200, left: 282, bottom: 240, right: 322))
        XCTAssertEqual(s.enemies[0].col, 7)
        XCTAssertEqual(s.enemies[0].xOffset, 2)
        s.enemies[0].direction = .up
        s.moveEnemy(0)
        XCTAssertEqual(s.enemies[0].rect, QDRect(top: 198, left: 282, bottom: 238, right: 322))
        XCTAssertEqual(s.enemies[0].row, 4)
        XCTAssertEqual(s.enemies[0].yOffset, 38)
        XCTAssertEqual(s.rng.drawCount, 0, "_MoveEnemy draws nothing")
    }

    /// `_FigureEnemyRandomness`: r = base / (frame − stateStart) + 1, min 1; base piranha 600, eel 120, shark 180,
    /// starfish 750 − 15·level.
    func testRandomnessR() {
        func r(type: Int8, level: Int = 1, age: UInt16) -> Int {
            var s = Self.world(level: level)
            Self.place(&s, type: type, col: 7, row: 5, dir: .left, start: 100)
            s.frame = 100 + age
            return s.figureEnemyRandomness(0)
        }
        XCTAssertEqual(r(type: 1, age: 16), 38, "piranha 600/16 + 1")
        XCTAssertEqual(r(type: 2, age: 16), 8, "eel 120/16 + 1")
        XCTAssertEqual(r(type: 3, age: 16), 12, "shark 180/16 + 1")
        XCTAssertEqual(r(type: 4, level: 12, age: 16), 36, "starfish (750 − 180)/16 + 1")
        XCTAssertEqual(r(type: 1, age: 600), 2, "piranha 600/600 + 1")
        XCTAssertEqual(r(type: 1, age: 601), 1, "piranha 600/601 + 1 — homing every time")
    }

    /// enemies-ai.md §4d: r forced to 1 (piranha, 601 frames after hatch → roll `(1,1)` = 1 → homing). Signed
    /// dx = e.col − hero.col, dy = e.row − hero.row. Run A: everything open → the enemy turns to p. Run B: p blocked by
    /// a blue bubble with the pop window closed (lastPop = frame) → it turns to s. Old dir is chosen so that its
    /// reverse is neither p nor s. Tie cases draw one extra `(1,2)`, replayed here from the same seed.
    func testHomingTable() {
        // (dx, dy) → (p, s); s == nil marks a tie case whose s is (1,2): p up/down → 1→left, 2→right;
        // p left/right → 1→up, 2→down.
        let cases: [(dx: Int, dy: Int, p: Direction, s: Direction?)] = [
            (-3, -1, .down, .right),      // both negative, dx < dy (signed!) → down first though |dx| > |dy|
            (-1, -3, .right, .down),      // both negative, dx ≥ dy
            (0, -2, .down, nil),          // hero below, same column
            (2, -1, .left, .down),        // dy < 0 < dx: "dy ≤ dx" always true
            (-2, 0, .right, nil),         // same row, hero right
            (2, 0, .left, nil),           // same row, hero left
            (0, 0, .right, .up),          // same cell
            (0, 2, .up, nil),             // hero above, same column
            (-1, 3, .up, .right),         // dx < 0 < dy: "dx < dy" always true
            (1, 3, .up, .left),           // both positive, dx < dy
            (3, 1, .left, .up),           // both positive, dx ≥ dy
        ]
        let (ec, er) = (7, 5)
        let frame: UInt16 = 700
        for c in cases {
            let tie = c.s == nil
            var ref = GameRandom(seed: 1)
            XCTAssertEqual(ref.fast(1, 1), 1)
            let s: Direction
            if let fixed = c.s {
                s = fixed
            } else {
                let t = ref.fast(1, 2)
                switch c.p {
                case .up, .down: s = t == 1 ? .left : .right
                case .left, .right: s = t == 1 ? .up : .down
                }
            }
            let old = [Direction.up, .down, .left, .right].first { $0.opposite != c.p && $0.opposite != s
                && !(tie && ($0.opposite == s.opposite)) }!
            let label = "dx \(c.dx) dy \(c.dy)"

            for blocked in [false, true] {
                var w = Self.world(seed: 1)
                Self.place(&w, type: 1, col: ec, row: er, dir: old, start: frame - 601,
                           lastPop: blocked ? frame : nil)
                w.frame = frame
                w.timeBonus = 100
                w.hero.col = Int8(ec - c.dx)
                w.hero.row = Int8(er - c.dy)
                if blocked {
                    switch c.p {
                    case .up: w.maze[ec, er - 1] = CellCode.blue
                    case .down: w.maze[ec, er + 1] = CellCode.blue
                    case .left: w.maze[ec - 1, er] = CellCode.blue
                    case .right: w.maze[ec + 1, er] = CellCode.blue
                    }
                }
                XCTAssertEqual(w.figureEnemyRandomness(0), 1, label)

                w.figureEnemyMove(0)

                XCTAssertEqual(w.enemies[0].direction, blocked ? s : c.p, "\(label) blocked \(blocked)")
                XCTAssertFalse(w.enemies[0].paused, label)
                XCTAssertEqual(w.rng.drawCount, tie ? 2 : 1, "\(label): roll + \(tie ? "one (1,2)" : "no tie draw")")
                XCTAssertEqual(w.rng.seed, ref.seed, label)
                XCTAssertTrue(w.pendingStops.isEmpty, label)
            }
        }
    }

    /// B12: seed 1, piranha 16 frames after hatch (r = 38), aligned at an open junction, old dir 3, no pending action.
    /// Roll `(1,38)` = 10 ≠ 1 with bonus > 0 → `_MoveEnemyRandomly`: pairs (a,b) = (0,2),(0,2),(3,2),(0,0),(0,2),
    /// (0,0),(3,3),(0,0) on [3,4,1,2] → [2,4,3,1]; 2 ≠ opposite(3) and open → new dir 2; 17 draws. Then `_MoveEnemy`
    /// moves it down by 2.
    func testMoveEnemyRandomlyDraws16() {
        var ref = GameRandom(seed: 1)
        XCTAssertEqual(ref.fast(1, 38), 10, "the roll")
        var order = [3, 4, 1, 2]
        var pairs: [[Int]] = []
        for _ in 0..<8 {
            let a = ref.fast(0, 3), b = ref.fast(0, 3)
            pairs.append([a, b])
            order.swapAt(a, b)
        }
        XCTAssertEqual(pairs, [[0, 2], [0, 2], [3, 2], [0, 0], [0, 2], [0, 0], [3, 3], [0, 0]])
        XCTAssertEqual(order, [2, 4, 3, 1])

        var w = Self.world(seed: 1)
        Self.place(&w, type: 1, col: 7, row: 5, dir: .left, start: 200)
        w.frame = 216
        w.timeBonus = 100
        w.hero.col = 0
        w.hero.row = 0
        XCTAssertEqual(w.figureEnemyRandomness(0), 38)

        w.enemyAI(0)

        XCTAssertEqual(w.rng.drawCount, 17, "roll + 16 shuffle draws")
        XCTAssertEqual(w.rng.seed, ref.seed)
        let e = w.enemies[0]
        XCTAssertEqual(e.direction, .down)
        XCTAssertFalse(e.paused)
        XCTAssertEqual(e.stuck, 0)
        XCTAssertEqual(e.speedCounter, 2, "piranha speed 2 (bonus > 0)")
        XCTAssertEqual(e.rect, QDRect(top: 202, left: 280, bottom: 242, right: 320))
        XCTAssertEqual(e.row, 5)
        XCTAssertEqual(e.yOffset, 2)
        XCTAssertTrue(w.pendingStops.isEmpty)
    }

    /// `_CanDoNormalPop`: `lastPop + 120 < frame && (short)(10 − frame) < (short)((frame − stateStart)/30)`;
    /// `_CanDoNormalOtherPop` the same with 4. The `short` truncation closes the window again from frame 32778.
    func testCanDoNormalPopCooldown() {
        var w = Self.world()
        Self.place(&w, type: 2, col: 7, row: 5, dir: .left, start: 100, lastPop: 1000)
        w.frame = 1000 + 120
        XCTAssertFalse(w.canDoNormalPop(0), "lastPop + 120")
        XCTAssertFalse(w.canDoNormalOtherPop(0))
        w.frame = 1000 + 121
        XCTAssertTrue(w.canDoNormalPop(0), "lastPop + 121")
        XCTAssertTrue(w.canDoNormalOtherPop(0))

        // (short)(10 − 40000) = 25546 > (40000 − 30000)/30 = 333 → false (replicated, Invariant 18).
        w.enemies[0].stateStart = 30000
        w.enemies[0].lastPop = 30000
        w.frame = 40000
        XCTAssertFalse(w.canDoNormalPop(0), "short truncation of 10 − frame")
        XCTAssertFalse(w.canDoNormalOtherPop(0))
        XCTAssertEqual(w.rng.drawCount, 0)
    }

    /// INDEX C11: homing with old dir 0 → `_LocationErrorInt(0x7d8, 1)` → the original quits. The replica records
    /// `.originalWouldAbort` and the enemy does not move. One draw (the roll).
    func testHomingWithOldDirZeroStops() {
        var w = Self.world(seed: 1)
        Self.place(&w, type: 1, col: 7, row: 5, dir: nil, start: 0)
        w.frame = 700
        w.timeBonus = 100
        w.hero.col = 2
        w.hero.row = 2
        let rect = w.enemies[0].rect

        w.enemyAI(0)

        XCTAssertEqual(w.pendingStops, [.originalWouldAbort("LocationErrorInt 0x7d8/1")])
        XCTAssertEqual(w.enemies[0].rect, rect, "unmoved")
        XCTAssertNil(w.enemies[0].direction)
        XCTAssertEqual(w.rng.drawCount, 1, "the roll only")
    }
}
