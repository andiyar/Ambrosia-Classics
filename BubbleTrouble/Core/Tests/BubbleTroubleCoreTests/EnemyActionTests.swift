@testable import BubbleTroubleCore
import Foundation
import XCTest

/// Task 9c — enemy actions (docs/plans/2026-10-03-btx-core-and-film-harness.md §Task 9c; Research note 33;
/// Invariants 8, 9, 18; enemies-ai.md §4e).
///
/// Sources: `_TryRemoveGo @ 0001305e`, `_TryEnemyPushBlock @ 000131fd`, `_TryEnemyCreateBalloon @ 00013441`,
/// `_ToastBubble @ 00012ef2`. All worlds are synthetic (`GameState.testWorld`, zero draws on return); the actions
/// are called directly, one call per aligned frame, as the AI's pending-action dispatch would.
final class EnemyActionTests: XCTestCase {

    private static func emptyMaze() -> Maze {
        try! Maze(data: Data(count: Maze.byteCount))
    }

    /// A hatched, aligned enemy in slot 0 at (col,row), sprite set by type (1 piranha … 4 starfish).
    private static func place(_ state: inout GameState, type: Int8, col: Int, row: Int, dir: Direction?) {
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
        e.drawn = true
        e.marker = 0x17
        e.balloonIndex = -1
        state.enemies[0] = e
        state.numEnemiesActive = 1
    }

    /// The hero parked far from every scan (bottom-right corner) unless a test moves it.
    private static func world(level: Int = 1) -> GameState {
        var s = GameState.testWorld(maze: emptyMaze(), level: level)
        s.hero.col = 15
        s.hero.row = 10
        s.frame = 500
        return s
    }

    /// Calls `act` once per frame until it fires; returns the number of waiting calls before the firing call (each
    /// waiting call must leave `pending` set and the count equal to the calls so far). Fails after `limit` calls.
    private static func waitingFrames(_ s: inout GameState, pending: Int16, limit: Int = 200,
                                      fired: (GameState) -> Bool,
                                      _ act: (inout GameState) -> Bool) -> Int {
        for n in 0..<limit {
            s.frame &+= 1
            XCTAssertTrue(act(&s), "call \(n + 1) returns 1")
            XCTAssertTrue(s.enemies[0].paused, "call \(n + 1) pauses")
            if fired(s) {
                XCTAssertEqual(s.enemies[0].actionWait, 0, "count cleared on the firing call")
                XCTAssertEqual(s.enemies[0].pendingAction, 0, "pending cleared on the firing call")
                XCTAssertEqual(s.enemies[0].lastPop, s.frame, "+0x5a = frame on the firing call")
                return n
            }
            XCTAssertEqual(s.enemies[0].pendingAction, pending, "waiting call \(n + 1) stores the action")
            XCTAssertEqual(Int(s.enemies[0].actionWait), n + 1, "waiting call \(n + 1) counts")
        }
        XCTFail("never fired within \(limit) calls")
        return -1
    }

    /// `_ToastBubble` tests up, down, left — the loop counter goes 3 → "none", so right is never tested
    /// (Invariant 18). Bubbles only to the right → nothing popped, dir 1 (up), paused, stuck untouched.
    func testToastBubbleNeverRight() {
        var s = Self.world()
        Self.place(&s, type: 1, col: 7, row: 5, dir: .left)
        s.enemies[0].stuck = 1
        s.maze[8, 5] = CellCode.normal
        s.maze[9, 5] = CellCode.normal
        let before = s.maze
        s.toastBubble(0)
        XCTAssertEqual(s.maze, before, "nothing popped")
        XCTAssertEqual(s.numActiveBlocks, 0, "no pop block")
        XCTAssertEqual(s.enemies[0].direction, .up, "none found → dir 1")
        XCTAssertTrue(s.enemies[0].paused)
        XCTAssertEqual(s.enemies[0].stuck, 1, "the none-found exit does not clear +0x48")
        XCTAssertEqual(s.rng.drawCount, 0)

        // Control: a bubble to the left (and the right) → the left one is popped (no score), stuck cleared, dir 3.
        s.maze[6, 5] = CellCode.purple
        s.enemies[0].paused = false
        s.toastBubble(0)
        XCTAssertEqual(s.maze[6, 5], CellCode.popping, "left bubble → pop block")
        XCTAssertEqual(s.maze[8, 5], CellCode.normal, "right bubble untouched")
        XCTAssertEqual(s.blocks[0].type, CellCode.popping)
        XCTAssertEqual(s.enemies[0].direction, .left)
        XCTAssertTrue(s.enemies[0].paused)
        XCTAssertEqual(s.enemies[0].stuck, 0)
        XCTAssertEqual(s.score, 0, "_CrushBlock(…, 0) — no score")
    }

    /// Note 33 at level 1: pop waits 40 − 1 = 39 frames, push 70 − 2 = 68, shark balloon 70 − 3 = 67; the starfish
    /// (sprite set 0x1e) waits 10 for pop and push. The action fires on the call after the last waiting frame.
    /// `+0x5a` (lastPop) is written on every waiting frame only by the balloon; pop and push write it only on fire.
    /// The starfish wait keys on the sprite set (`+0x3a == 0x1e`), not the type byte.
    func testActionWaits() {
        // Pop (piranha): normal bubble to the right; lastPop untouched while waiting.
        var s = Self.world()
        Self.place(&s, type: 1, col: 7, row: 5, dir: .right)
        s.maze[8, 5] = CellCode.normal
        s.enemies[0].lastPop = 123
        XCTAssertEqual(Self.waitingFrames(&s, pending: 2, fired: { $0.maze[8, 5] == CellCode.popping }) {
            let r = $0.tryRemoveGo(0, .right)
            if $0.maze[8, 5] != CellCode.popping {
                XCTAssertEqual($0.enemies[0].lastPop, 123, "pop waiting frames leave +0x5a alone")
            }
            return r
        }, 39)
        XCTAssertEqual(s.blocks[0].type, CellCode.popping, "pop block at the bubble")
        XCTAssertEqual(s.enemies[0].direction, .right)
        XCTAssertEqual(s.score, 0, "enemy pops never score")

        // Push (eel): normal bubble then empty; lastPop untouched while waiting.
        s = Self.world()
        Self.place(&s, type: 2, col: 7, row: 5, dir: .right)
        s.maze[8, 5] = CellCode.normal
        s.enemies[0].lastPop = 123
        XCTAssertEqual(Self.waitingFrames(&s, pending: 1, fired: { $0.maze[8, 5] == CellCode.empty }) {
            let r = $0.tryEnemyPushBlock(0, .right)
            if $0.maze[8, 5] != CellCode.empty {
                XCTAssertEqual($0.enemies[0].lastPop, 123, "push waiting frames leave +0x5a alone")
            }
            return r
        }, 68)
        XCTAssertEqual(s.blocks[0].type, CellCode.normal, "moving normal bubble")
        XCTAssertEqual(s.blocks[0].direction, .right)

        // Balloon (shark): hero two cells down the open column; lastPop follows every waiting frame.
        s = Self.world()
        Self.place(&s, type: 3, col: 7, row: 5, dir: .down)
        s.hero.col = 7
        s.hero.row = 7
        var calls = 0
        XCTAssertEqual(Self.waitingFrames(&s, pending: 3, fired: { $0.numActiveBalloons == 1 }) {
            calls += 1
            let r = $0.tryEnemyCreateBalloon(0, .down)
            if $0.numActiveBalloons == 0 {
                XCTAssertEqual($0.enemies[0].lastPop, $0.frame, "waiting call \(calls) stamps +0x5a")
            }
            return r
        }, 67)
        XCTAssertEqual(s.balloons[0].state, 1, "balloon slot 0 flying")
        XCTAssertEqual(s.balloons[0].direction, .down)
        XCTAssertEqual(s.rng.drawCount, 1, "only _Balloons_New's GetRandomFast(4,7)")

        // Hero trapped → 0 before anything else.
        s = Self.world()
        Self.place(&s, type: 3, col: 7, row: 5, dir: .down)
        s.hero.col = 7
        s.hero.row = 7
        s.hero.trapped = true
        XCTAssertFalse(s.tryEnemyCreateBalloon(0, .down))
        XCTAssertEqual(s.enemies[0].actionWait, 0)

        // Starfish: 10 for pop and push.
        s = Self.world()
        Self.place(&s, type: 4, col: 7, row: 5, dir: .left)
        s.maze[6, 5] = CellCode.blue
        XCTAssertEqual(Self.waitingFrames(&s, pending: 2, fired: { $0.maze[6, 5] == CellCode.popping }) {
            $0.tryRemoveGo(0, .left)
        }, 10)
        s = Self.world()
        Self.place(&s, type: 4, col: 7, row: 5, dir: .up)
        s.maze[7, 4] = CellCode.normal
        XCTAssertEqual(Self.waitingFrames(&s, pending: 1, fired: { $0.maze[7, 4] == CellCode.empty }) {
            $0.tryEnemyPushBlock(0, .up)
        }, 10)

        // The wait keys on the sprite set, not the type byte: a piranha-typed enemy wearing sprite set 0x1e waits 10.
        s = Self.world()
        Self.place(&s, type: 1, col: 7, row: 5, dir: .right)
        s.enemies[0].spriteSet = 0x1e
        s.maze[8, 5] = CellCode.normal
        XCTAssertEqual(Self.waitingFrames(&s, pending: 2, fired: { $0.maze[8, 5] == CellCode.popping }) {
            $0.tryRemoveGo(0, .right)
        }, 10, "type 1 with sprite set 0x1e → starfish wait")
        s = Self.world()
        Self.place(&s, type: 2, col: 7, row: 5, dir: .right)
        s.enemies[0].spriteSet = 0x1e
        s.maze[8, 5] = CellCode.normal
        XCTAssertEqual(Self.waitingFrames(&s, pending: 1, fired: { $0.maze[8, 5] == CellCode.empty }) {
            $0.tryEnemyPushBlock(0, .right)
        }, 10, "type 2 with sprite set 0x1e → starfish wait")
    }

    /// B8, `_TryEnemyPushBlock @ 000131fd`: the adjacent cell must be a normal bubble (10) and the cell beyond empty
    /// or 'F' (70); every refusal returns 0 without touching the enemy (no wait counted). The edge limits (down row ≤ 8,
    /// up row ≥ 2, left col ≥ 2, right col ≤ 13) are tested first.
    func testEnemyPushNeedsNormalThenEmptyOrF() {
        func refused(_ s: GameState, _ msg: String) {
            XCTAssertEqual(s.enemies[0].actionWait, 0, msg)
            XCTAssertEqual(s.enemies[0].pendingAction, 0, msg)
            XCTAssertFalse(s.enemies[0].paused, msg)
            XCTAssertEqual(s.enemies[0].direction, .up, msg + " (direction untouched)")
            XCTAssertEqual(s.numActiveBlocks, 0, msg)
        }

        // Normal then empty, normal then 'F' → push after the wait (shark: 68 at level 1).
        for beyond in [CellCode.empty, CellCode.passableF] {
            var s = Self.world()
            Self.place(&s, type: 3, col: 7, row: 5, dir: .up)
            s.maze[8, 5] = CellCode.normal
            s.maze[9, 5] = beyond
            XCTAssertEqual(Self.waitingFrames(&s, pending: 1, fired: { $0.maze[8, 5] == CellCode.empty }) {
                $0.tryEnemyPushBlock(0, .right)
            }, 68, "beyond = \(beyond)")
            XCTAssertEqual(s.blocks[0].type, CellCode.normal)
        }

        // Normal then 'P', blue then empty, dynamite then empty → 0, never waits.
        for (next, beyond) in [(CellCode.normal, CellCode.passableP), (CellCode.blue, CellCode.empty),
                               (CellCode.dynamite, CellCode.empty)] {
            var s = Self.world()
            Self.place(&s, type: 3, col: 7, row: 5, dir: .up)
            s.maze[8, 5] = next
            s.maze[9, 5] = beyond
            let before = s.maze
            XCTAssertFalse(s.tryEnemyPushBlock(0, .right), "\(next) then \(beyond)")
            refused(s, "\(next) then \(beyond)")
            XCTAssertEqual(s.maze, before)
        }

        // Edge limits: a normal bubble next to the enemy in `d` with empty cells beyond where the grid has them.
        // The plan's B8 bar ("returns 0 before any maze read") is behaviourally unobservable here: at these four
        // positions `getDistantObject` already returns 50 (off-grid) and `getNextObject` returns 50 one cell further
        // out, so the maze query alone would refuse too. Observing the ordering would need a maze-read spy, and
        // production code carries none (ruling). The edge switch in `EnemyActions.swift` (`tryEnemyPushBlock`) is
        // transcribed from `_TryEnemyPushBlock @ 000131fd` and is behaviourally redundant with the maze-query edge
        // returns; these assertions pin only the refusal and that nothing is touched.
        for (col, row, d) in [(7, 1, Direction.up), (7, 9, .down), (1, 5, .left), (14, 5, .right)] {
            var s = Self.world()
            Self.place(&s, type: 3, col: col, row: row, dir: .up)
            let next = GameState.adjacentCell(col: col, row: row, d)
            s.maze[next.col, next.row] = CellCode.normal
            let before = s.maze
            XCTAssertFalse(s.tryEnemyPushBlock(0, d), "(\(col),\(row)) facing \(d)")
            refused(s, "(\(col),\(row)) facing \(d)")
            XCTAssertEqual(s.maze, before)
        }

        // Direction 0 → _LocationErrorInt(0x7d8,5): the original quits. Unreachable in play (`_ToastBubble` always
        // leaves +0x23 non-zero — 00013040 on pop, 0001304f otherwise — and every other writer sets it non-zero); the
        // nil arm is defensive transcription of the original's 0 exit, pinned here directly.
        var s = Self.world()
        Self.place(&s, type: 3, col: 7, row: 5, dir: .up)
        XCTAssertFalse(s.tryEnemyPushBlock(0, nil))
        XCTAssertTrue(s.pendingStops.contains(.originalWouldAbort("LocationErrorInt 0x7d8/5")))
    }
}
