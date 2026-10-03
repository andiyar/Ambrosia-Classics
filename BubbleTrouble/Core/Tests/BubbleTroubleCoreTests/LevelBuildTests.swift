@testable import BubbleTroubleCore
import Foundation
import XCTest

/// Task 4 — `GameState` and level construction in the original's draw order
/// (docs/plans/2026-10-03-btx-core-and-film-harness.md §Task 4; Research notes 11–18).
///
/// Sources: `_PlayGame @ 00018247` demo prologue (seed → `SetLevel(id − 1)` → `ResetHeroLives` → `ResetScore(0)` →
/// `Multiplier_Reset` → `EXTRA_Reset` → `_NewLevel`), `_NewLevel @ 0001735f` (order: LoadLevel, ResetBlocks,
/// ResetHurtBlockList, TimeBonus_Reset, LoadMaze, InitHero, PositionJewels (2 draws per jewel), Splats_Init,
/// Bubbles_Init (109), Balloons_Init, InitStars (42), InitPoints (8), InitEnemies, InitEnemyAI (no-op), Bonus_Init,
/// DrawMaze), `_PositionSingleJewel @ 0001c544`, `_Bonus_Init @ 00019734`, `_InitHero @ 000217b3`,
/// `_ResetHeroPosition @ 0002165f`, `_TimeBonus_Reset @ 00006930`, `_ResetBlocks @ 0001b90e`.
///
/// Every number below is the plan's Research note 18 table [Python over the extracted resources, QuickDraw LCG
/// assumed] — SELF-DERIVED, not bank-derived — and was recomputed independently for this task on 2026-10-03 by a
/// fresh Python transcription of the decompiled functions (all values agree, incl. seed 446091883 after FILM 1).
final class LevelBuildTests: XCTestCase {

    /// FILM n plays level n (Research note 10).
    private func build(film id: Int, checkpoints: inout [LevelBuildCheckpoint: Int]) throws -> GameState {
        let files = try BTXTestData.files()
        let film = try files.film(id)
        return try GameState.newGame(level: id, mode: .demo, seed: film.seed, files: files, checkpoints: &checkpoints)
    }

    private func build(film id: Int) throws -> GameState {
        var unused: [LevelBuildCheckpoint: Int] = [:]
        return try build(film: id, checkpoints: &unused)
    }

    // MARK: - Data-gated

    /// Research note 18: cumulative draws 6 after `_PositionJewels`, 115 after `_Bubbles_CreateRandomLUT`, 157 after
    /// `_InitStars`, 165 after `_InitPoints`, and after `_Bonus_Init` 191 / 194 / 194 / 193 for FILMs 1–4.
    func testNewLevelDrawCheckpoints() throws {
        let finals = [1: 191, 2: 194, 3: 194, 4: 193]
        for id in 1...4 {
            var cp: [LevelBuildCheckpoint: Int] = [:]
            let state = try build(film: id, checkpoints: &cp)
            XCTAssertEqual(cp[.jewels], 6, "FILM \(id) after jewels")
            XCTAssertEqual(cp[.bubbleLUT], 115, "FILM \(id) after the bubble LUT")
            XCTAssertEqual(cp[.stars], 157, "FILM \(id) after stars")
            XCTAssertEqual(cp[.points], 165, "FILM \(id) after points")
            XCTAssertEqual(cp[.bonus], finals[id], "FILM \(id) after Bonus_Init")
            XCTAssertEqual(state.rng.drawCount, finals[id], "FILM \(id) final")
            XCTAssertTrue(state.pendingStops.isEmpty, "FILM \(id) stops \(state.pendingStops)")
        }
    }

    /// Research note 18: the 12 jewel cells (col,row) in placement order; normal bubbles left after the jewels
    /// replace three of them: 80 / 70 / 78 / 57.
    func testJewelPlacement() throws {
        let expected: [Int: [CellRef]] = [
            1: [CellRef(col: 2, row: 2), CellRef(col: 1, row: 6), CellRef(col: 9, row: 7)],
            2: [CellRef(col: 14, row: 2), CellRef(col: 10, row: 4), CellRef(col: 6, row: 5)],
            3: [CellRef(col: 6, row: 1), CellRef(col: 8, row: 6), CellRef(col: 10, row: 8)],
            4: [CellRef(col: 1, row: 4), CellRef(col: 5, row: 9), CellRef(col: 8, row: 5)],
        ]
        let normals = [1: 80, 2: 70, 3: 78, 4: 57]
        for id in 1...4 {
            let state = try build(film: id)
            XCTAssertEqual(state.numJewels, 3, "FILM \(id)")
            XCTAssertEqual(Array(state.jewelCells.prefix(3)), expected[id], "FILM \(id)")
            for cell in expected[id]! {
                XCTAssertEqual(state.maze[Int(cell.col), Int(cell.row)], CellCode.jewel, "FILM \(id) \(cell)")
                // gMazeCopy keeps the MAZE as loaded (jewels are written into gMaze only).
                XCTAssertEqual(state.mazeCopy[Int(cell.col), Int(cell.row)], CellCode.normal, "FILM \(id) \(cell)")
            }
            XCTAssertEqual(state.maze.cells.filter { $0 == CellCode.normal }.count, normals[id], "FILM \(id)")
            XCTAssertFalse(state.jewelFound)
            XCTAssertNil(state.targetJewel)
            XCTAssertEqual(state.jewelCount, 0)
        }
    }

    /// Research note 17: launch frame, left, type (and time value) per armed slot; FILM 1's slot 1 is unarmed.
    func testBonusInit() throws {
        struct Slot { let launch: UInt16; let left: Int16; let type: Int16; let timeValue: Int16 }
        let expected: [Int: [Slot?]] = [
            1: [Slot(launch: 578, left: 492, type: 11, timeValue: -1), nil],
            2: [Slot(launch: 434, left: 430, type: 10, timeValue: -1), Slot(launch: 577, left: 343, type: 10, timeValue: -1)],
            3: [Slot(launch: 256, left: 303, type: 13, timeValue: -1), Slot(launch: 716, left: 492, type: 14, timeValue: 1000)],
            4: [Slot(launch: 481, left: 237, type: 9, timeValue: -1), Slot(launch: 612, left: 263, type: 9, timeValue: -1)],
        ]
        for id in 1...4 {
            let state = try build(film: id)
            XCTAssertEqual(state.bonus.count, 2)
            XCTAssertEqual(state.bonusSquishedAtOnce, 0, "level 1 zeroes it; levels 2–4 keep the fresh game's 0")
            for (i, slot) in expected[id]!.enumerated() {
                let b = state.bonus[i]
                guard let slot else {
                    XCTAssertFalse(b.armed, "FILM \(id) slot \(i) should be unarmed")
                    continue
                }
                XCTAssertTrue(b.armed, "FILM \(id) slot \(i)")
                XCTAssertEqual(b.launchFrame, slot.launch, "FILM \(id) slot \(i) launch")
                XCTAssertEqual(b.rect, QDRect(top: 440, left: slot.left, bottom: 480, right: slot.left + 40),
                               "FILM \(id) slot \(i) rect")
                XCTAssertEqual(b.prevRect, b.rect)
                XCTAssertEqual(b.type, slot.type, "FILM \(id) slot \(i) type")
                XCTAssertEqual(b.timeValue, slot.timeValue, "FILM \(id) slot \(i) time value")
                XCTAssertEqual(b.riseSpeed, 2)
                XCTAssertEqual(b.iconSet, 0x1a)
                // Type 14's icon frame is 0xe + value index (1000 → index 2 → 0x10); otherwise the type itself.
                XCTAssertEqual(b.iconFrame, slot.type == 14 ? 0x10 : slot.type)
                XCTAssertTrue(b.visible)
                XCTAssertFalse(b.dead)
                XCTAssertFalse(b.popped)
            }
        }
    }

    /// Research note 18, FILM 1: the bubble LUT, star lookup, point thresholds and bonus drift heads, and the seed
    /// after `_Bonus_Init`.
    func testFilm1Tables() throws {
        let s = try build(film: 1)
        XCTAssertEqual(Array(s.airBubbles.xLoc.prefix(5)), [159, 228, 277, 133, 262])
        XCTAssertEqual(s.airBubbles.delayTable, [85, 69, 53, 53, 56, 54, 78, 51, 49, 90, 51, 49, 74])
        XCTAssertEqual(s.airBubbles.groups, [2, 0, 0, 3, 5, 4, 0, 4, 7, 5, 5, 4, 6, 3, 7, 0, 0, 2, 6, 1, 0])
        XCTAssertEqual(Array(s.airBubbles.vertical.prefix(5)), [5, 4, 2, 3, 4])
        XCTAssertEqual(Array(s.airBubbles.drift.prefix(5)), [2, 0, 3, 2, 3])
        XCTAssertEqual(Array(s.stars.locationLookup.prefix(6)), [-6, 4, 8, 8, 4, -3])
        XCTAssertEqual(s.points.thresholds, [23, 24, 21, 22, 20, 24, 23, 23])
        XCTAssertEqual(s.bonusDrift.count, 21)
        XCTAssertEqual(Array(s.bonusDrift.prefix(5)), [3, 4, 2, 2, 2])
        XCTAssertEqual(s.bonusDriftIndex, 0)
        XCTAssertEqual(s.airBubbles.delayTilNextGroup, 0x1e)
        XCTAssertEqual(s.rng.seed, 446_091_883)
    }

    /// Research notes 11–13: the state `_PlayGame`'s prologue + `_NewLevel` leave for FILM 1.
    func testStateAfterNewLevel() throws {
        let s = try build(film: 1)
        XCTAssertEqual(s.level, 1)
        XCTAssertEqual(s.mode, .demo)
        XCTAssertEqual(s.frame, 0)
        XCTAssertEqual(s.hero.col, 7)
        XCTAssertEqual(s.hero.row, 6)
        XCTAssertEqual(s.hero.rect, QDRect.cell(col: 7, row: 6))
        XCTAssertEqual(s.hero.prevRect, s.hero.rect)
        XCTAssertEqual(s.hero.state, 1)
        XCTAssertEqual(s.hero.stateStart, 0)
        XCTAssertEqual(s.hero.facing, .left)
        XCTAssertEqual(s.hero.speed, 5)
        XCTAssertTrue(s.hero.aligned)
        XCTAssertEqual(s.hero.spriteSet, 1)
        XCTAssertEqual(s.hero.spriteFrame, 3)
        XCTAssertTrue(s.hero.licenceValid)
        XCTAssertTrue(s.hero.registered)
        XCTAssertEqual(s.lives, 3)
        XCTAssertEqual(s.score, 0)
        XCTAssertEqual(s.nextExtraLifeScore, 10000)
        XCTAssertEqual(s.multiplier, 1)
        XCTAssertEqual(s.extraLetters, [false, false, false, false, false])
        XCTAssertEqual(s.timeBonus, 2500)
        XCTAssertEqual(s.timeBonusTimer, 0)
        XCTAssertEqual(s.numNormalBlocks, 100)
        XCTAssertEqual(s.maze.cells.filter { $0 == CellCode.normal }.count, 80)
        XCTAssertEqual(s.enemies.count, 30)
        XCTAssertEqual(s.blocks.count, 35)
        XCTAssertEqual(s.balloons.count, 30)
        XCTAssertTrue(s.enemies.allSatisfy { $0.state == 0 })
        XCTAssertTrue(s.blocks.allSatisfy { $0.state == 0 })
        XCTAssertTrue(s.balloons.allSatisfy { $0.state == 0 })
        XCTAssertEqual(s.numActiveBlocks, 0)
        XCTAssertEqual(s.numActiveBalloons, 0)
        XCTAssertEqual(s.numEnemiesActive, 0)
        XCTAssertEqual(s.numEnemiesSquished, 0)
        XCTAssertEqual(s.levelRecord.totalEnemies, 4)
        XCTAssertEqual(s.levelRecord.pool, [4, 0, 0, 0, 0, 0])
        XCTAssertEqual(s.levelForEffect, 50)
        XCTAssertFalse(s.isEndOfLevel)
        XCTAssertTrue(s.firstAppearance)
        XCTAssertTrue(s.playing)
        XCTAssertTrue(s.aiRegistered)
        XCTAssertTrue(s.jewelAnimDir)
        XCTAssertFalse(s.jewelsDone)
        XCTAssertTrue(s.pendingStops.isEmpty)
        XCTAssertEqual(s.stars.activeCount, 0)
        XCTAssertEqual(s.airBubbles.activeCount, 0)
    }

    // MARK: - Synthetic

    /// `_PositionSingleJewel @ 0001c544`: the walk covers cols 1–14 × rows 1–9 while `tries < 501`, then widens to the
    /// whole grid. With the only normal bubbles at (0,0), (5,0), (10,0) and 3 jewels (4 would loop forever — only
    /// three candidates), all three land on row 0, in the order (0,0), (5,0), (10,0) from seed 1 [Python, QuickDraw
    /// LCG]; the row/column rejections are off by then (`tries ≥ 151`). 2 draws per jewel → 6.
    func testJewelWalkWidensAfter500() throws {
        var maze = try Maze(data: Data(count: Maze.byteCount))
        maze[0, 0] = CellCode.normal
        maze[5, 0] = CellCode.normal
        maze[10, 0] = CellCode.normal
        var s = GameState.testWorld(maze: maze, jewelCount: 3)
        XCTAssertEqual(s.rng.drawCount, 0, "testWorld makes no draws")
        s.positionJewels()
        XCTAssertEqual(s.rng.drawCount, 6)
        XCTAssertEqual(s.numJewels, 3)
        XCTAssertEqual(Array(s.jewelCells.prefix(3)),
                       [CellRef(col: 0, row: 0), CellRef(col: 5, row: 0), CellRef(col: 10, row: 0)])
        XCTAssertEqual(s.maze[0, 0], CellCode.jewel)
        XCTAssertEqual(s.maze[5, 0], CellCode.jewel)
        XCTAssertEqual(s.maze[10, 0], CellCode.jewel)
        XCTAssertEqual(s.mazeCopy[5, 0], CellCode.normal)
    }
}
