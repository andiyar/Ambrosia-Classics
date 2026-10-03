@testable import BubbleTroubleCore
import Foundation
import XCTest

/// Task 8 — blocks in motion and jewel joining
/// (docs/plans/2026-10-03-btx-core-and-film-harness.md §Task 8; Invariants 7, 8, 9, 18; Research notes 34–39; B11;
/// INDEX C5).
///
/// Sources: `_MoveBlock @ 0001cccb`, `_ProcessBlocks @ 0001d2b8`, `_CheckJewelMovement @ 0001ca05`,
/// `_Jewels_GiveBonus @ 0001c7c5`, `_Blocks_DeactivateRubberBlocks @ 0001c2c7`. All worlds are synthetic
/// (`GameState.testWorld`, an all-empty maze → hero at (7,6), rect (240, 280, 280, 320), state 2; time bonus 2500;
/// LEVL w8 (egg time) 50, w7 (max active) 2).
///
/// The frame loop and the draw pass belong to Task 10, so `step` stands in for them: frame + 1, `_ProcessBlocks`,
/// then the two draw-pass frees the tests depend on (Invariant 8) — `_DrawBlocksToComp @ 0001c315` (a non-free
/// block: prev rect = rect; retired → state 0, `_gNumActiveBlocks--`) and `_DrawEnemiesToComp @ 00011170` (a
/// non-free dead enemy → state 0, `gNumEnemiesActive--`).
final class BlocksTests: XCTestCase {

    private func world(level: Int = 1) -> GameState {
        let maze = try! Maze(data: Data(count: Maze.byteCount))
        return GameState.testWorld(maze: maze, level: level)
    }

    /// An active (state 1) enemy of `type` aligned on (col, row) with its type's sprite set (0x1a + type).
    private func place(_ state: inout GameState, slot: Int, col: Int, row: Int, type: Int8 = 1) {
        var e = Enemy()
        e.state = 1
        e.type = type
        e.spriteSet = 0x1a + Int16(type)
        e.col = Int8(col)
        e.row = Int8(row)
        e.rect = QDRect.cell(col: col, row: row)
        e.prevRect = e.rect
        e.aligned = true
        state.enemies[slot] = e
    }

    /// One frame: frame + 1, `_ProcessBlocks`, then the block and enemy draw-pass frees (see the class comment).
    private func step(_ state: inout GameState) {
        state.frame &+= 1
        state.processBlocks()
        for i in state.blocks.indices where state.blocks[i].state != 0 {
            state.blocks[i].prevRect = state.blocks[i].rect
            if state.blocks[i].retired {
                state.blocks[i].state = 0
                state.numActiveBlocks -= 1
            }
        }
        for i in state.enemies.indices where state.enemies[i].state != 0 && state.enemies[i].dead {
            state.enemies[i].state = 0
            state.numEnemiesActive &-= 1
        }
    }

    /// Note 36: a pushed bubble moves 10 px per call (4 calls per cell), steps col at ±40, is aligned only on a cell;
    /// at an aligned cell it keeps going while the next cell is empty and stops at the first obstacle: retired and
    /// the maze cell rewritten with its type, then freed by the draw pass. The cells it crossed stay empty. No draws.
    func testPushedBubbleSlides10px() {
        var state = world()
        state.maze[3, 2] = CellCode.normal
        state.maze[6, 2] = CellCode.normal                           // the obstacle
        state.pushBlock(col: 2, row: 2, direction: .right, type: CellCode.normal)
        XCTAssertEqual(state.maze[3, 2], 0)
        XCTAssertEqual(state.numActiveBlocks, 1)
        for call in 1...8 {
            step(&state)
            let b = state.blocks[0]
            XCTAssertEqual(b.rect, QDRect(top: 80, left: Int16(120 + 10 * call), bottom: 120,
                                          right: Int16(160 + 10 * call)), "call \(call)")
            XCTAssertEqual(b.col, Int8(3 + call / 4), "call \(call)")
            XCTAssertEqual(b.xOffset, Int8(10 * (call % 4)), "call \(call)")
            XCTAssertEqual(b.aligned, call % 4 == 0, "call \(call)")
            if call < 8 {
                XCTAssertEqual(b.state, 1, "call \(call): still sliding")
                XCTAssertEqual(state.maze[4, 2], 0, "call \(call)")
                XCTAssertEqual(state.maze[5, 2], 0, "call \(call)")
            }
        }
        // Call 8: aligned on (5,2), next (6,2) is a bubble → stop.
        XCTAssertEqual(state.maze[5, 2], CellCode.normal)
        XCTAssertEqual(state.maze[4, 2], 0)
        XCTAssertEqual(state.maze[3, 2], 0)
        XCTAssertEqual(state.maze[6, 2], CellCode.normal)
        XCTAssertEqual(state.blocks[0].state, 0, "retired, freed by the draw pass")
        XCTAssertEqual(state.numActiveBlocks, 0)
        XCTAssertEqual(state.rng.drawCount, 0)
    }

    /// B11 + note 36 (`_MoveBlock @ 0001cccb` disasm 0001cfa2..0001d287): a blue block squashes in place for 4 calls at
    /// its first obstacle (frames right 8,9,8,1), reverses and `bounces` = 1; it slides back and at the second obstacle
    /// squashes again (left 6,7,6,1), `bounces` = 2 → retired, maze = 15. A purple block bounces at that second
    /// obstacle too (`bounces` = 2, not retired) and retires at its third (`bounces` = 3). Vertical squash frames:
    /// down 4,5,4,1 · up 2,3,2,1. The rect does not move while squashing.
    func testBounceCounts() {
        // Horizontal: obstacles at (1,2) and (6,2); the block starts at (3,2) moving right.
        func horizontal(_ type: UInt8) -> (state: GameState, frames: [Int: Int16], bounces: [Int: Int16]) {
            var state = world()
            state.maze[1, 2] = CellCode.normal
            state.maze[6, 2] = CellCode.normal
            state.maze[3, 2] = type
            state.pushBlock(col: 2, row: 2, direction: .right, type: type)
            var frames: [Int: Int16] = [:], bounces: [Int: Int16] = [:]
            for call in 1...60 where state.blocks[0].state != 0 {
                step(&state)
                frames[call] = state.blocks[0].frame
                bounces[call] = state.blocks[0].bounces
                if call == 8 || call == 9 || call == 10 {
                    XCTAssertTrue(state.blocks[0].bouncing, "call \(call)")
                    XCTAssertEqual(state.blocks[0].rect.left, 200, "call \(call): no movement while squashing")
                }
            }
            return (state, frames, bounces)
        }

        let blue = horizontal(CellCode.blue)
        XCTAssertEqual((8...11).map { blue.frames[$0]! }, [8, 9, 8, 1], "right squash")
        XCTAssertEqual(blue.bounces[10], 0)
        XCTAssertEqual(blue.bounces[11], 1, "first obstacle: reversed, bounces 1")
        XCTAssertEqual(blue.frames[12], 1)
        // Back from (5,2) to (2,2): 12 calls (12…23); aligned on (2,2) at call 23, next (1,2) is a bubble.
        XCTAssertEqual((23...26).map { blue.frames[$0]! }, [6, 7, 6, 1], "left squash")
        XCTAssertEqual(blue.bounces[26], 2)
        XCTAssertNil(blue.frames[27], "retired at bounces 2 (freed after call 26)")
        XCTAssertEqual(blue.state.maze[2, 2], CellCode.blue)
        XCTAssertEqual(blue.state.maze[5, 2], 0)
        XCTAssertEqual(blue.state.numActiveBlocks, 0)

        let purple = horizontal(CellCode.purple)
        XCTAssertEqual((8...11).map { purple.frames[$0]! }, [8, 9, 8, 1])
        XCTAssertEqual((23...26).map { purple.frames[$0]! }, [6, 7, 6, 1])
        XCTAssertEqual(purple.bounces[26], 2, "purple bounces again at its second obstacle")
        XCTAssertEqual(purple.frames[27], 1, "still alive")
        // Right again from (2,2) to (5,2): calls 27…38; squash 38…41, bounces 3 → retired on (5,2).
        XCTAssertEqual((38...41).map { purple.frames[$0]! }, [8, 9, 8, 1])
        XCTAssertEqual(purple.bounces[41], 3)
        XCTAssertNil(purple.frames[42])
        XCTAssertEqual(purple.state.maze[5, 2], CellCode.purple)
        XCTAssertEqual(purple.state.maze[2, 2], 0)

        // Vertical: column 10, obstacles at (10,1) and (10,4); the block starts at (10,2) moving down.
        var state = world()
        state.maze[10, 1] = CellCode.normal
        state.maze[10, 4] = CellCode.normal
        state.newBlock(col: 10, row: 2, direction: .down, type: CellCode.blue, enemy: -1, moving: true)
        var frames: [Int16] = []
        for _ in 1...14 {
            step(&state)
            frames.append(state.blocks[0].frame)
        }
        XCTAssertEqual(Array(frames[3...6]), [4, 5, 4, 1], "down squash on (10,3), calls 4…7")
        XCTAssertEqual(Array(frames[10...13]), [2, 3, 2, 1], "up squash on (10,2), calls 11…14")
        XCTAssertEqual(state.blocks[0].state, 0)
        XCTAssertEqual(state.maze[10, 2], CellCode.blue)
    }

    /// §1.5 (`_ProcessBlocks @ 0001d2b8` second loop): after every block moved, each moving non-retired block i takes
    /// the first later moving non-retired block j whose rect strictly overlaps; both reverse unless bouncing or
    /// already reversed this frame (one flag per slot), so a block met twice in a frame reverses once.
    func testBlockBlockReversal() {
        // Two blocks on row 2 closing at 20 px per frame: touching after 4 frames, overlapping on the 5th.
        var state = world()
        state.newBlock(col: 2, row: 2, direction: .right, type: CellCode.normal, enemy: -1, moving: true)
        state.newBlock(col: 5, row: 2, direction: .left, type: CellCode.normal, enemy: -1, moving: true)
        for _ in 1...4 { step(&state) }
        XCTAssertEqual(state.blocks[0].rect.right, 160)
        XCTAssertEqual(state.blocks[1].rect.left, 160)
        XCTAssertEqual(state.blocks[0].direction, .right, "edge-sharing rects do not collide")
        XCTAssertEqual(state.blocks[1].direction, .left)
        step(&state)
        XCTAssertEqual(state.blocks[0].direction, .left)
        XCTAssertEqual(state.blocks[1].direction, .right)
        step(&state)
        XCTAssertEqual(state.blocks[0].rect.left, 120, "moved back")
        XCTAssertEqual(state.blocks[1].rect.left, 160)
        XCTAssertEqual(state.blocks[0].direction, .left, "apart: no second reversal")
        XCTAssertEqual(state.blocks[1].direction, .right)
        XCTAssertEqual(state.rng.drawCount, 0)

        // Three blocks overlapping after their move: 0 meets 1 (both reverse), then 1 meets 2 — 1 is already
        // reversed this frame (unchanged), 2 reverses.
        var three = world()
        three.newBlock(col: 2, row: 2, direction: .right, type: CellCode.normal, enemy: -1, moving: true)
        three.blocks[0].xOffset = 10
        three.blocks[0].rect.offset(dx: 10, dy: 0)                       // → left 100 after the move
        three.newBlock(col: 3, row: 2, direction: .left, type: CellCode.normal, enemy: -1, moving: true)
        three.blocks[1].xOffset = -10
        three.blocks[1].rect.offset(dx: -10, dy: 0)                      // → left 100 after the move
        three.newBlock(col: 3, row: 2, direction: .left, type: CellCode.normal, enemy: -1, moving: true)
        step(&three)                                                     // block 2 → left 110
        XCTAssertEqual(three.blocks.prefix(3).map(\.rect.left), [100, 100, 110])
        XCTAssertEqual(three.blocks[0].direction, .left)
        XCTAssertEqual(three.blocks[1].direction, .right, "reversed once, not twice")
        XCTAssertEqual(three.blocks[2].direction, .right)

        // A later block met twice: 0 and 1 do not overlap each other but both overlap 2 — 0 meets 2 (both reverse),
        // then 1 meets 2 — 1 reverses, 2 (already flagged) does not.
        var twice = world()
        twice.newBlock(col: 1, row: 2, direction: .right, type: CellCode.normal, enemy: -1, moving: true)
        twice.blocks[0].xOffset = 10
        twice.blocks[0].rect.offset(dx: 10, dy: 0)                       // → left 60 after the move
        twice.newBlock(col: 3, row: 2, direction: .left, type: CellCode.normal, enemy: -1, moving: true)   // → 110
        twice.newBlock(col: 2, row: 2, direction: .right, type: CellCode.normal, enemy: -1, moving: true)  // → 90
        step(&twice)
        XCTAssertEqual(twice.blocks.prefix(3).map(\.rect.left), [60, 110, 90])
        XCTAssertEqual(twice.blocks[0].direction, .left)
        XCTAssertEqual(twice.blocks[1].direction, .right)
        XCTAssertEqual(twice.blocks[2].direction, .left, "reversed once, not twice")

        // A bouncing block is not reversed, but still flags and reverses its partner.
        var bouncing = world()
        bouncing.newBlock(col: 2, row: 2, direction: .right, type: CellCode.blue, enemy: -1, moving: true)
        bouncing.blocks[0].bouncing = true                                // squashing in place on (2,2)
        bouncing.blocks[0].bounceStep = 1
        bouncing.maze[3, 2] = CellCode.normal
        bouncing.newBlock(col: 2, row: 3, direction: .up, type: CellCode.normal, enemy: -1, moving: true)
        step(&bouncing)                                                  // block 1 → top 110, overlapping
        XCTAssertEqual(bouncing.blocks[0].direction, .right)
        XCTAssertEqual(bouncing.blocks[0].frame, 9, "squash step 2 (right)")
        XCTAssertEqual(bouncing.blocks[1].direction, .down)
    }

    /// Note 36 + Invariant 7 (`_MoveBlock`: `n = ++block.count; _SquishEnemy(e, n)` on the rect inset 3;
    /// `_WasEnemySquished @ 00010eca` does not test the dead flag). One block through three enemies scores 200, 400,
    /// 800 and steps the multiplier 1 → 2 on the third. Then the quirk: two blocks overlap enemy E in the same frame;
    /// slot 0 squishes it (200), slot 1 is handed the same dead, unfreed slot — its count advances to 1 with no score
    /// — so its next real squish (enemy F, next frame) scores 400, not 200.
    func testSquishCountChains() {
        var state = world()
        place(&state, slot: 0, col: 3, row: 2)
        place(&state, slot: 1, col: 4, row: 2)
        place(&state, slot: 2, col: 5, row: 2)
        state.numEnemiesActive = 3
        state.maze[9, 2] = CellCode.normal
        state.newBlock(col: 2, row: 2, direction: .right, type: CellCode.normal, enemy: -1, moving: true)
        let expected: [Int: (score: Int32, count: Int8)] = [1: (200, 1), 5: (600, 2), 9: (1400, 3)]
        for call in 1...12 {
            step(&state)
            if let want = expected[call] {
                XCTAssertEqual(state.score, want.score, "call \(call)")
                XCTAssertEqual(state.blocks[0].squishCount, want.count, "call \(call)")
            }
        }
        XCTAssertEqual(state.multiplier, 2, "the third squish steps the multiplier")
        XCTAssertEqual(state.score, 1400)
        XCTAssertEqual(state.numEnemiesSquished, 3)
        XCTAssertEqual(state.numEnemiesActive, 0)

        var quirk = world()
        place(&quirk, slot: 0, col: 3, row: 4)                                 // E
        place(&quirk, slot: 1, col: 3, row: 4)                                 // F: (160, 140, 200, 180), mid-cell
        quirk.enemies[1].rect = QDRect(top: 160, left: 140, bottom: 200, right: 180)
        quirk.enemies[1].xOffset = 20
        quirk.enemies[1].aligned = false
        quirk.numEnemiesActive = 2
        quirk.newBlock(col: 2, row: 4, direction: .right, type: CellCode.normal, enemy: -1, moving: true)   // A
        quirk.newBlock(col: 4, row: 4, direction: .left, type: CellCode.normal, enemy: -1, moving: true)    // B
        step(&quirk)
        // A at left 90 (inset 93…127) and B at left 150 (inset 153…187) both overlap E (120…160); E is slot 0.
        XCTAssertEqual(quirk.score, 200, "B's hand-back scores nothing")
        XCTAssertEqual(quirk.blocks[0].squishCount, 1)
        XCTAssertEqual(quirk.blocks[1].squishCount, 1, "the chain count advanced on the dead enemy")
        XCTAssertEqual(quirk.numEnemiesSquished, 1)
        XCTAssertEqual(quirk.enemies[0].state, 0, "E freed by the draw pass")
        XCTAssertEqual(quirk.enemies[1].state, 1, "F untouched so far (A's inset ends at 127 < 140)")
        step(&quirk)
        // B at left 140 (inset 143…177) overlaps F; A (inset 103…137) does not.
        XCTAssertEqual(quirk.blocks[1].squishCount, 2)
        XCTAssertEqual(quirk.score, 600, "F scores 400 (n = 2), not 200")
        XCTAssertEqual(quirk.blocks[0].squishCount, 1)
    }

    /// Note 36: `_IsHeroCaught(blockRect, 1, 0)` insets the block rect by 4 and tests the plain hero rect (strict).
    /// A block sliding right on the hero's row: with the hero's left edge at 276 the inset rect (right edge
    /// block.right − 4) first overlaps on call 5 (right 290 − 4 = 286); at 275 it overlaps on call 4 (276 > 275).
    /// The catch is `_HeroCaught(2)`: state 3, invisible-drawn flag cleared.
    func testMovingBlockCatchesHero() {
        for (heroLeft, catchCall) in [(Int16(276), 5), (Int16(275), 4)] {
            var state = world()
            state.hero.rect = QDRect(top: 240, left: heroLeft, bottom: 280, right: heroLeft + 40)
            state.newBlock(col: 5, row: 6, direction: .right, type: CellCode.normal, enemy: -1, moving: true)
            for call in 1...catchCall {
                step(&state)
                XCTAssertEqual(state.hero.state, call < catchCall ? 2 : 3, "hero left \(heroLeft), call \(call)")
            }
            XCTAssertTrue(state.heroCaughtThisFrame)
            XCTAssertFalse(state.hero.visible)
            XCTAssertEqual(state.hero.stateStart, UInt16(catchCall))
            XCTAssertGreaterThan(state.rng.drawCount, 0, "the (0,1) sound draw and the 0xe stars")
        }
    }

    /// Note 37: an egg laid at L (state 3, w8 = 50) toggles egg ↔ bubble sprite every 9 calls (bubble first: the
    /// toggle starts at 0), turns state 4 at L + 50 (start = L + 50), pops at L + 66 (`start + 15 < frame`: type 40,
    /// state 2, sprite 0x18, frame 1, maze 40), and the pop retires and empties the cell 8 calls later at L + 74.
    func testEggBlockTimeline() {
        var state = world()
        XCTAssertEqual(state.levelRecord.eggTime, 50)
        place(&state, slot: 3, col: 4, row: 3, type: 2)
        state.enemies[3].state = 2
        let laid: UInt16 = 100
        state.frame = laid
        state.maze[4, 3] = CellCode.egg
        state.newBlock(col: 4, row: 3, direction: nil, type: CellCode.egg, enemy: 3, moving: false)
        XCTAssertEqual(state.blocks[0].state, 3)
        XCTAssertEqual(state.blocks[0].frame, 2, "egg frame = the enemy's type")
        while state.frame < laid + 74 {
            step(&state)
            let f = state.frame, b = state.blocks[0]
            switch f {
            case laid + 1:
                XCTAssertEqual(b.spriteSet, 0x11)
                XCTAssertEqual(b.frame, 1)
            case laid + 9:
                XCTAssertEqual(b.spriteSet, 0x1f, "toggled on the 9th call")
                XCTAssertEqual(b.frame, 2)
            case laid + 18:
                XCTAssertEqual(b.spriteSet, 0x11)
            case laid + 49:
                XCTAssertEqual(b.state, 3)
            case laid + 50:
                XCTAssertEqual(b.state, 4)
                XCTAssertEqual(b.startFrame, laid + 50)
            case laid + 65:
                XCTAssertEqual(b.state, 4)
                XCTAssertEqual(state.maze[4, 3], CellCode.egg)
            case laid + 66:
                XCTAssertEqual(b.type, CellCode.popping)
                XCTAssertEqual(b.state, 2)
                XCTAssertEqual(b.spriteSet, 0x18)
                XCTAssertEqual(b.frame, 1)
                XCTAssertEqual(b.startFrame, laid + 66)
                XCTAssertEqual(state.maze[4, 3], CellCode.popping)
            case laid + 73:
                XCTAssertEqual(b.frame, 8)
                XCTAssertEqual(state.maze[4, 3], CellCode.popping)
            default:
                break
            }
        }
        XCTAssertEqual(state.maze[4, 3], 0, "empty at L + 74")
        XCTAssertEqual(state.blocks[0].state, 0)
        XCTAssertEqual(state.numActiveBlocks, 0)
    }

    /// Note 37: a pop block (type 40) advances its frame each call; the call that takes it past 8 retires it and
    /// empties the cell.
    func testPopClearsCellAfter8() {
        var state = world()
        state.maze[8, 6] = CellCode.normal
        state.crushBlock(col: 7, row: 6, direction: .right, score: true)
        XCTAssertEqual(state.maze[8, 6], CellCode.popping)
        for call in 1...7 {
            step(&state)
            XCTAssertEqual(state.blocks[0].frame, Int16(1 + call))
            XCTAssertEqual(state.maze[8, 6], CellCode.popping, "call \(call)")
        }
        step(&state)
        XCTAssertEqual(state.maze[8, 6], 0)
        XCTAssertEqual(state.blocks[0].state, 0)
        XCTAssertEqual(state.score, 1)
    }

    /// Note 36: pushed dynamite slides like a bubble; on the stop call it is retired, the maze takes 52, then
    /// `_ExplodeBombBlock` zeroes the cell (that order) and the blast (level < 12: the cell grown 40) squishes the
    /// diagonal enemy at (4,1). Not before the stop call.
    func testDynamiteSlidesThenExplodes() {
        var state = world()
        state.maze[3, 2] = CellCode.dynamite
        state.maze[6, 2] = CellCode.normal
        place(&state, slot: 0, col: 4, row: 1)
        state.numEnemiesActive = 1
        state.pushBlock(col: 2, row: 2, direction: .right, type: CellCode.dynamite)
        for call in 1...7 {
            step(&state)
            XCTAssertEqual(state.blocks[0].state, 1, "call \(call)")
            XCTAssertNotEqual(state.blocks[0].spriteSet, -1, "call \(call)")
            XCTAssertEqual(state.score, 0, "call \(call)")
        }
        state.frame &+= 1
        state.processBlocks()
        XCTAssertTrue(state.blocks[0].retired)
        XCTAssertEqual(state.blocks[0].spriteSet, -1, "exploded")
        XCTAssertEqual(state.blocks[0].col, 5)
        XCTAssertEqual(state.maze[5, 2], 0, "the explosion zeroes the cell after the stop wrote 52")
        XCTAssertEqual(state.maze[6, 2], CellCode.normal)
        XCTAssertTrue(state.enemies[0].dead)
        XCTAssertEqual(state.score, 200)
        XCTAssertEqual(state.hero.state, 2)
    }

    /// Note 37: a static fuse (state 3) lit at f rewrites its maze cell to 52 every call, animates (frame 2 → 3 on
    /// the 4th call, wrapping to 2 on the 8th), and explodes on the call where `start + 60 < frame`: f + 61.
    func testFuseExplodesAt61() {
        var state = world()
        let lit: UInt16 = 200
        state.frame = lit
        state.maze[3, 2] = CellCode.dynamite
        state.newBlock(col: 3, row: 2, direction: .right, type: CellCode.dynamite, enemy: -1, moving: false)
        XCTAssertEqual(state.blocks[0].state, 3)
        for call in 1...60 {
            if call == 30 { state.maze[3, 2] = 0 }
            step(&state)
            XCTAssertEqual(state.maze[3, 2], CellCode.dynamite, "call \(call): rewritten every call")
            XCTAssertFalse(state.blocks[0].retired, "call \(call)")
            if call == 4 { XCTAssertEqual(state.blocks[0].frame, 3) }
            if call == 8 { XCTAssertEqual(state.blocks[0].frame, 2) }
        }
        XCTAssertEqual(state.frame, lit + 60)
        state.frame &+= 1
        state.processBlocks()
        XCTAssertTrue(state.blocks[0].retired, "explodes at f + 61")
        XCTAssertEqual(state.blocks[0].spriteSet, -1)
        XCTAssertEqual(state.maze[3, 2], 0)
    }

    /// Note 39 / §3 (`_CheckJewelMovement @ 0001ca05`): three jewels. Jewel (3,2) pushed right slides past (4,2),
    /// keeps going at (5,2) though (6,2) holds a jewel (no target yet), and on arriving at (6,2) joins it: target =
    /// (6,2), the moving block becomes the cell's cluster (retired, maze 30) and a new static cluster block is made;
    /// count 1 < 3 − 1 → partial: total enemies (w6) and the starfish pool (w21) +1 only while active < max (w7 = 2).
    /// The third jewel then slides into the target from below and gives the bonus.
    func testJewelJoinPartial() {
        func joined(active: Int8) -> GameState {
            var state = world()
            state.numJewels = 3
            state.numEnemiesActive = active
            state.maze[3, 2] = CellCode.jewel
            state.maze[6, 2] = CellCode.jewel
            state.maze[6, 5] = CellCode.jewel
            state.pushBlock(col: 2, row: 2, direction: .right, type: CellCode.jewel)
            for call in 1...12 {
                step(&state)
                if call < 12 {
                    XCTAssertFalse(state.jewelFound, "call \(call)")
                    XCTAssertEqual(state.blocks[0].state, 1, "call \(call)")
                }
            }
            XCTAssertTrue(state.jewelFound)
            XCTAssertEqual(state.targetJewel, CellRef(col: 6, row: 2))
            XCTAssertEqual(state.jewelCount, 1)
            XCTAssertEqual(state.maze[6, 2], CellCode.cluster)
            XCTAssertEqual(state.maze[5, 2], 0)
            XCTAssertEqual(state.blocks[0].state, 0, "the moving jewel retired")
            XCTAssertEqual(state.blocks[1].state, 1)
            XCTAssertEqual(state.blocks[1].type, CellCode.cluster)
            XCTAssertFalse(state.blocks[1].moving)
            XCTAssertEqual(state.blocks[1].col, 6)
            XCTAssertEqual(state.blocks[1].row, 2)
            XCTAssertFalse(state.jewelsDone)
            XCTAssertEqual(state.score, 0)
            return state
        }

        let room = joined(active: 1)
        XCTAssertEqual(room.levelRecord.words[6], 5, "total enemies +1")
        XCTAssertEqual(room.levelRecord.words[21], 1, "starfish pool +1")

        var full = joined(active: 2)
        XCTAssertEqual(full.levelRecord.words[6], 4, "active == max: no starfish")
        XCTAssertEqual(full.levelRecord.words[21], 0)

        // The third jewel, pushed up from (6,5): keeps going at (6,3) because its next cell is the target; merges.
        full.pushBlock(col: 6, row: 6, direction: .up, type: CellCode.jewel)
        let slot = full.blocks.firstIndex { $0.type == CellCode.jewel && $0.state == 1 }!
        for _ in 1...12 { step(&full) }
        XCTAssertEqual(full.blocks[slot].state, 0)
        XCTAssertEqual(full.jewelCount, 2)
        XCTAssertTrue(full.jewelsDone)
        XCTAssertEqual(full.score, 5000)
        XCTAssertEqual(full.maze[6, 2], CellCode.cluster)
        XCTAssertEqual(full.maze[6, 3], 0)
        XCTAssertEqual(full.levelRecord.words[6], 4)
    }

    /// Note 39 (`_Jewels_GiveBonus @ 0001c7c5`): a target on the border (col 0/15, row 0/10) → 1000; otherwise by level
    /// 1…5 → 5000…9000, ≥ 6 → 10000; ×mult; `gJewelsDone`; then `_Balloons_CaptureAllEnemies` (an active enemy ends
    /// in a balloon).
    func testJewelBonusValues() {
        for (level, value) in [(1, 5000), (2, 6000), (3, 7000), (4, 8000), (5, 9000), (6, 10000), (7, 10000)] {
            var state = world(level: level)
            state.targetJewel = CellRef(col: 5, row: 5)
            state.jewelsGiveBonus()
            XCTAssertEqual(state.score, Int32(value), "level \(level)")
            XCTAssertTrue(state.jewelsDone)
        }
        for target in [CellRef(col: 0, row: 5), CellRef(col: 15, row: 5), CellRef(col: 5, row: 0),
                       CellRef(col: 5, row: 10)] {
            var state = world(level: 4)
            state.targetJewel = target
            state.jewelsGiveBonus()
            XCTAssertEqual(state.score, 1000, "border \(target)")
        }
        var state = world(level: 2)
        state.multiplier = 3
        state.targetJewel = CellRef(col: 5, row: 5)
        place(&state, slot: 0, col: 2, row: 2)
        state.jewelsGiveBonus()
        XCTAssertEqual(state.score, 18000, "×mult")
        XCTAssertEqual(state.enemies[0].state, 6, "capture-all follows")
        XCTAssertEqual(state.numActiveBalloons, 1)
        XCTAssertEqual(state.balloons[0].holder, 0)
    }

    /// Note 36: a moving jewel with TimeBonus < 1 becomes a normal bubble (type 10, state 1, moving, sprite 0x11,
    /// frame 1) and stops as a bubble (maze 10). TimeBonus 1 keeps it a jewel.
    func testMovingJewelBecomesBubble() {
        var state = world()
        state.numJewels = 3
        state.maze[3, 2] = CellCode.jewel
        state.maze[5, 2] = CellCode.normal
        state.pushBlock(col: 2, row: 2, direction: .right, type: CellCode.jewel)
        state.timeBonus = 1
        step(&state)
        XCTAssertEqual(state.blocks[0].type, CellCode.jewel)
        XCTAssertEqual(state.blocks[0].spriteSet, 0x16)
        state.timeBonus = 0
        step(&state)
        XCTAssertEqual(state.blocks[0].type, CellCode.normal)
        XCTAssertEqual(state.blocks[0].state, 1)
        XCTAssertTrue(state.blocks[0].moving)
        XCTAssertEqual(state.blocks[0].spriteSet, 0x11)
        XCTAssertEqual(state.blocks[0].frame, 1)
        for _ in 1...2 { step(&state) }                    // aligned on (4,2); next (5,2) is a bubble
        XCTAssertEqual(state.blocks[0].state, 0)
        XCTAssertEqual(state.maze[4, 2], CellCode.normal)
    }

    /// `_Blocks_DeactivateRubberBlocks @ 0001c2c7`: every non-free blue/purple block is retired and written into the
    /// maze at its col/row (mid-cell too); other blocks are untouched.
    func testRubberBlocksDeactivate() {
        var state = world()
        state.newBlock(col: 3, row: 2, direction: .right, type: CellCode.blue, enemy: -1, moving: true)
        state.newBlock(col: 10, row: 8, direction: .up, type: CellCode.normal, enemy: -1, moving: true)
        state.newBlock(col: 12, row: 4, direction: .down, type: CellCode.purple, enemy: -1, moving: true)
        for _ in 1...2 { step(&state) }
        XCTAssertEqual(state.blocks[0].xOffset, 20, "mid-cell")
        XCTAssertEqual(state.blocks[2].yOffset, 20)
        state.blocksDeactivateRubberBlocks()
        XCTAssertTrue(state.blocks[0].retired)
        XCTAssertTrue(state.blocks[2].retired)
        XCTAssertFalse(state.blocks[1].retired)
        XCTAssertEqual(state.maze[3, 2], CellCode.blue)
        XCTAssertEqual(state.maze[12, 4], CellCode.purple)
        XCTAssertEqual(state.maze[10, 8], 0)
        XCTAssertEqual(state.maze[10, 7], 0)
    }
}
