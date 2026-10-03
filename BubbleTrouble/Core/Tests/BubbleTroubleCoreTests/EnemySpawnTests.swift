@testable import BubbleTroubleCore
import Foundation
import XCTest

/// Task 9a — enemy spawn, eggs, `_ProcessEnemies`, animation
/// (docs/plans/2026-10-03-btx-core-and-film-harness.md §Task 9a; Research notes 29, 30; Invariants 8, 9, 18; INDEX C10).
///
/// Sources: `_CheckNewEnemies @ 000124fa` (+ folded `_NewEnemy @ 00012172`), `_ProcessEnemies @ 00011ad3`,
/// `_CorrectEnemyAligned @ 00012596`. All worlds are synthetic (`GameState.testWorld`, zero draws on return). No
/// test reaches the `enemyAI` seam (Task 9b): every state-1 enemy carries the post-hatch delay flag.
final class EnemySpawnTests: XCTestCase {

    private static func emptyMaze() -> Maze {
        try! Maze(data: Data(count: Maze.byteCount))
    }

    /// B12: the only normal bubbles are (3,2), (12,7), (0,10); seed 42; pool `[4,0,0,0,0,0]`. Draws: `(0,15)` = 12,
    /// `(0,10)` = 7, `(1,4)` = 2, `(0,5)` = 5 (rejected, pool[5] = 0), `(0,5)` = 0 (accepted) → 5 draws (4 + k, k = 1).
    /// The scan starts at (13,7) and tests the start cell (12,7) last, so the egg lands at (0,10).
    func testNewEnemyScanAndDraws() {
        var maze = Self.emptyMaze()
        maze[3, 2] = CellCode.normal
        maze[12, 7] = CellCode.normal
        maze[0, 10] = CellCode.normal
        var state = GameState.testWorld(maze: maze, seed: 42, pool: [4, 0, 0, 0, 0, 0])
        XCTAssertEqual(state.rng.drawCount, 0)
        XCTAssertEqual(state.numNormalBlocks, 100)
        state.frame = 20

        state.checkNewEnemies()

        XCTAssertEqual(state.rng.drawCount, 5, "(0,15) (0,10) (1,4) + (0,5)×2 (k = 1 rejected)")
        let e = state.enemies[0]
        XCTAssertEqual(e.state, 2)
        XCTAssertEqual(e.stateStart, 20)
        XCTAssertEqual(e.lastPop, 20)
        XCTAssertEqual(e.col, 0)
        XCTAssertEqual(e.row, 10)
        XCTAssertEqual(e.rect, QDRect.cell(col: 0, row: 10))
        XCTAssertEqual(e.prevRect, e.rect)
        XCTAssertEqual(e.direction, .down)
        XCTAssertTrue(e.aligned)
        XCTAssertEqual(e.type, 1)
        XCTAssertEqual(e.spriteSet, 0x1b)
        XCTAssertEqual(e.animFrame, 4, "piranha, dir 2 → frame 4")
        XCTAssertEqual(e.tier, 4)
        XCTAssertEqual(e.marker, 0x14)
        XCTAssertEqual(e.balloonIndex, -1)
        XCTAssertFalse(e.dead)
        XCTAssertEqual(state.levelRecord.words[18], 3)
        XCTAssertEqual(Array(state.levelRecord.words[19...23]), [0, 0, 0, 0, 0])
        XCTAssertEqual(state.maze[0, 10], CellCode.egg)
        XCTAssertEqual(state.maze[12, 7], CellCode.normal)
        XCTAssertEqual(state.maze[3, 2], CellCode.normal)
        let b = state.blocks[0]
        XCTAssertEqual(b.state, 3)
        XCTAssertEqual(b.type, CellCode.egg)
        XCTAssertEqual(b.spriteSet, 0x1f)
        XCTAssertEqual(b.frame, 1, "egg frame = enemy type")
        XCTAssertEqual(b.enemy, 0)
        XCTAssertEqual(b.eggPopDelay, 15)
        XCTAssertEqual(b.col, 0)
        XCTAssertEqual(b.row, 10)
        XCTAssertFalse(b.moving)
        XCTAssertEqual(b.startFrame, 20)
        XCTAssertEqual(state.numActiveBlocks, 1)
        XCTAssertEqual(state.numNormalBlocks, 99)
        XCTAssertEqual(state.numEnemiesActive, 1)
        XCTAssertTrue(state.enemies[1...].allSatisfy { $0.state == 0 })
        XCTAssertTrue(state.blocks[1...].allSatisfy { $0.state == 0 })
    }

    /// Research note 29: pool words 18…23 all zero → word 18 := 1, then the `(0,5)` rejection loop can only accept
    /// i = 0 → a piranha, and the pool is all zero again.
    func testPoolFallbackWord18() {
        var maze = Self.emptyMaze()
        maze[2, 3] = CellCode.normal
        var state = GameState.testWorld(maze: maze, seed: 7, pool: [0, 0, 0, 0, 0, 0])

        state.checkNewEnemies()

        let e = state.enemies[0]
        XCTAssertEqual(e.state, 2)
        XCTAssertEqual(e.type, 1)
        XCTAssertEqual(e.spriteSet, 0x1b)
        XCTAssertEqual(e.col, 2)
        XCTAssertEqual(e.row, 3)
        XCTAssertEqual(Array(state.levelRecord.words[18...23]), [0, 0, 0, 0, 0, 0])
        XCTAssertEqual(state.numEnemiesActive, 1)
        XCTAssertEqual(state.blocks[0].frame, 1)
        XCTAssertGreaterThanOrEqual(state.rng.drawCount, 4, "(0,15) (0,10) (1,4) + at least one (0,5)")
    }

    /// Research note 30 / enemies-ai.md §2, with LEVL w10 (pre-egg delay) = 10 and w8 (egg time) = 50 set
    /// explicitly (the `testWorld` defaults, the level-1 values): laid at L → state 3 at L+11
    /// (`L + 10 < L+11`), hatch at L+72 (`L+11 + 10 + 50 < L+72`). The post-hatch counter reaches 16 on the L+88
    /// call and clears the flag, so `enemyAI` would first run at L+89 — the test stops at L+88. No draws.
    func testEggToHatchTimeline() {
        var maze = Self.emptyMaze()
        maze[1, 1] = CellCode.normal
        var state = GameState.testWorld(maze: maze, seed: 3)
        state.levelRecord.words[8] = 50
        state.levelRecord.words[10] = 10
        let laid: UInt16 = 30
        state.frame = laid
        state.checkNewEnemies()
        XCTAssertEqual(state.enemies[0].state, 2)
        XCTAssertEqual(state.enemies[0].col, 1)
        XCTAssertEqual(state.enemies[0].row, 1)
        let drawsAfterSpawn = state.rng.drawCount

        for t in 1...88 {
            state.frame = laid + UInt16(t)
            state.processEnemies()
            let e = state.enemies[0]
            switch t {
            case 1...10:
                XCTAssertEqual(e.state, 2, "L+\(t)")
                XCTAssertEqual(e.stateStart, laid, "L+\(t)")
            case 11...71:
                XCTAssertEqual(e.state, 3, "L+\(t)")
                XCTAssertEqual(e.stateStart, laid + 11, "L+\(t)")
            case 72:
                XCTAssertEqual(e.state, 1, "hatch at L+72")
                XCTAssertEqual(e.stateStart, laid + 72)
                XCTAssertTrue(e.drawn)
                XCTAssertTrue(e.postHatchDelay)
                XCTAssertEqual(e.postHatchCounter, 0)
                XCTAssertEqual(e.marker, 0x17, "valid licence → marker 0x17")
            case 73...87:
                XCTAssertEqual(e.state, 1, "L+\(t)")
                XCTAssertTrue(e.postHatchDelay, "L+\(t)")
                XCTAssertEqual(e.postHatchCounter, Int16(t - 72), "L+\(t)")
            default:   // 88
                XCTAssertEqual(e.state, 1)
                XCTAssertFalse(e.postHatchDelay, "flag clears on the L+88 call (+0x44 reached 16)")
                XCTAssertEqual(e.postHatchCounter, 0)
            }
            XCTAssertTrue(e.aligned, "L+\(t)")
            XCTAssertFalse(e.dead, "L+\(t)")
        }
        XCTAssertEqual(state.rng.drawCount, drawsAfterSpawn, "eggs, hatch and animation draw nothing")
        XCTAssertEqual(state.hero.state, 2)

        // Animation (piranha, 3-frame cycle per direction every 3 ticks): 16 state-1 calls (L+73…L+88), tick reaches
        // 3 on every third call → 5 frame advances inside the direction's 3-frame range.
        let e = state.enemies[0]
        let base: Int16
        switch e.direction {
        case .up: base = 1
        case .down: base = 4
        case .left: base = 7
        case .right: base = 10
        case nil: base = 0
        }
        XCTAssertTrue((base...(base + 2)).contains(e.animFrame), "frame \(e.animFrame) in \(base)…\(base + 2)")
        XCTAssertEqual(e.animTick, 1, "16 ticks: 5 wraps (15) + 1")
    }

    /// Research note 30 / INDEX C10: a state-1 enemy (post-hatch flag set, so no AI) not aligned, moving right into
    /// a resting normal bubble, while overlapping the hero → `_SquishEnemy(i,1)` (200) and then `_HeroCaught(1)` in
    /// the same call (the dead flag is not tested); the squish's star-group draws precede the catch's `(0,1)`.
    func testSquishOnEntryAndSameFrameCatch() {
        var state = Self.squishScenario()
        XCTAssertEqual(state.rng.drawCount, 0)

        // Reference: squish first, then the catch (the order note 30 fixes).
        var reference = Self.squishScenario()
        reference.squishEnemy(0, count: 1)
        let squishDraws = reference.rng.drawCount
        reference.heroCaught(kind: 1)
        // The order is observable: catch first, then squish, leaves different stars.
        var swapped = Self.squishScenario()
        swapped.heroCaught(kind: 1)
        swapped.squishEnemy(0, count: 1)

        state.processEnemies()

        XCTAssertGreaterThan(squishDraws, 0, "the squish star group draws")
        XCTAssertFalse(state.enemies[0].aligned)
        XCTAssertEqual(state.enemies[0].postHatchCounter, 1, "post-hatch flag set → counted, no AI")
        XCTAssertTrue(state.enemies[0].dead, "squished on entry")
        XCTAssertEqual(state.enemies[0].state, 5, "the catch's _StopAllEnemies → state 5")
        XCTAssertEqual(state.maze[5, 6], CellCode.empty)
        XCTAssertEqual(state.maze[6, 6], CellCode.normal)
        XCTAssertEqual(state.score, 200)
        XCTAssertEqual(state.numEnemiesSquished, 1)
        XCTAssertEqual(state.hero.state, 3, "caught in the same call")
        XCTAssertEqual(state.hero.stateStart, 200)
        XCTAssertTrue(state.heroCaughtThisFrame)
        XCTAssertEqual(state.rng.drawCount, squishDraws + 1, "squish draws + the catch's (0,1)")
        XCTAssertEqual(state.rng.seed, reference.rng.seed)
        XCTAssertEqual(state.stars.slots, reference.stars.slots, "squish draws first, then the catch")
        XCTAssertEqual(swapped.rng.drawCount, state.rng.drawCount)
        XCTAssertNotEqual(swapped.stars.slots, state.stars.slots, "the test discriminates the order")
    }

    /// Hero at (5,6); enemy 0 a hatched piranha (post-hatch flag set, counter 0) between (5,6) and (6,6), heading
    /// right, rect left 215 (not aligned); a resting normal bubble at (6,6). Overlap: enemy inset 11 → x 226…244,
    /// hero inset 8 → x 208…232; same row.
    private static func squishScenario() -> GameState {
        var maze = emptyMaze()
        maze[6, 6] = CellCode.normal
        var state = GameState.testWorld(maze: maze, seed: 11)
        state.frame = 200
        state.hero.col = 5
        state.hero.row = 6
        state.hero.rect = QDRect.cell(col: 5, row: 6)
        var e = Enemy()
        e.state = 1
        e.stateStart = 100
        e.type = 1
        e.spriteSet = 0x1b
        e.tier = 4
        e.marker = 0x17
        e.direction = .right
        e.col = 5
        e.row = 6
        e.rect = QDRect(top: 240, left: 215, bottom: 280, right: 255)
        e.prevRect = e.rect
        e.xOffset = 15
        e.aligned = true                          // stale: `_CorrectEnemyAligned` recomputes it
        e.animFrame = 10
        e.postHatchDelay = true
        e.postHatchCounter = 0
        e.drawn = true
        state.enemies[0] = e
        state.numEnemiesActive = 1
        return state
    }
}
