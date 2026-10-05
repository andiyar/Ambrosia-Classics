@testable import BubbleTroubleCore
import Foundation
import XCTest

/// Task C3 (plan 2026-10-04 btx-playable) — the frame's QuickDraw calls as `DrawOp`s on the OS X path of
/// `_PlayGame @ 00018247` (`Sim/DrawOps.swift`, `Sim/HUD.swift`): restores and playfield sprites into the window,
/// the score bar through comp, the level-start picture into comp. No op adds an RNG draw (G4 guards that).
final class DrawOpTests: XCTestCase {

    private static let idle = FilmSample(up: false, down: false, left: false, right: false, push: false)

    /// Normal bubbles at (0,0) and (15,10) only (so the recount never awards "all bubbles gone"); hero (7,6) state 2
    /// facing left (set 1 frame 3 at (280, 240)); no enemies; air bubbles off; play mode.
    private func world() -> GameState {
        var maze = try! Maze(data: Data(count: Maze.byteCount))
        maze[0, 0] = CellCode.normal
        maze[15, 10] = CellCode.normal
        var config = SessionConfig()
        config.prefs.airBubbles = false
        return GameState.testWorld(maze: maze, totalEnemies: 0, maxActive: 0, pool: [0, 0, 0, 0, 0, 0],
                                   mode: .play, config: config)
    }

    private func step(_ state: inout GameState) -> FrameReport {
        var input = ScriptedInput(samples: [Self.idle, Self.idle])
        return state.stepFrame(input: &input)
    }

    private func screenSprite(_ set: Int, _ frame: Int, _ h: Int, _ v: Int) -> DrawOp {
        .sprite(set: set, frame: frame, h: h, v: v, mode: .normal, target: .screen)
    }

    private func compSprite(_ set: Int, _ frame: Int, _ h: Int, _ v: Int) -> DrawOp {
        .sprite(set: set, frame: frame, h: h, v: v, mode: .normal, target: .comp)
    }

    /// A frozen (state 5, no AI) enemy in slot `i` at cell (col, row).
    private func placeEnemy(_ state: inout GameState, slot i: Int, col: Int, row: Int, drawn: Bool, dead: Bool) {
        state.enemies[i].state = 5
        state.enemies[i].rect = QDRect.cell(col: col, row: row)
        state.enemies[i].prevRect = state.enemies[i].rect
        state.enemies[i].col = Int8(col)
        state.enemies[i].row = Int8(row)
        state.enemies[i].aligned = true
        state.enemies[i].spriteSet = 0x1b
        state.enemies[i].animFrame = 2
        state.enemies[i].drawn = drawn
        state.enemies[i].dead = dead
        state.numEnemiesActive &+= 1
    }

    // MARK: - Level start

    /// `_DrawMaze` for level 1: `.drawMaze(912)`, `.prepareScoreBar`, then one comp sprite (frame 1) per maze cell
    /// 10/15/16/20/30/52, rows outer — mapped to sets 0x11/0x14/0x15/0x16/0x17/0x12.
    func testLevelStartOpsLevel1() throws {
        var state = try GameState.newGame(level: 1, mode: .play, seed: 1, files: BTXTestData.files())
        let ops = state.levelStartOps()
        XCTAssertEqual(Array(ops.prefix(2)), [.drawMaze(pictID: 912), .prepareScoreBar])
        let sets: [UInt8: Int] = [10: 0x11, 0xf: 0x14, 0x10: 0x15, 0x14: 0x16, 0x1e: 0x17, 0x34: 0x12]
        var expected: [DrawOp] = []
        for row in 0..<Maze.rows {
            for col in 0..<Maze.columns {
                if let set = sets[state.maze[col, row]] { expected.append(compSprite(set, 1, col * 40, row * 40)) }
            }
        }
        XCTAssertGreaterThan(expected.count, 20)
        XCTAssertEqual(Array(ops.dropFirst(2)), expected)
        XCTAssertTrue(state.presentation.reserveHeroNeedsDrawing)     // _RequestDrawReserveHero(0)
        XCTAssertTrue(state.presentation.ops.isEmpty)                  // returned, not left behind
    }

    // MARK: - Frame order

    /// `_PlayGame` 00018bcd…00018c2b: restores → hurt blocks → hero → enemies → blocks → splats → points → the score
    /// (through comp) → the notice, every playfield call into the window.
    func testDrawOrderMatchesPlayGame() {
        var state = world()
        state.hurtBlocks[0] = HurtBlock()
        state.hurtBlocks[0].active = true
        state.hurtBlocks[0].spriteSet = 0x11
        state.hurtBlocks[0].frame = 5
        placeEnemy(&state, slot: 0, col: 2, row: 2, drawn: true, dead: false)
        state.blocks[0].state = 3
        state.blocks[0].type = CellCode.normal
        state.blocks[0].rect = QDRect.cell(col: 4, row: 4)
        state.blocks[0].prevRect = state.blocks[0].rect
        state.blocks[0].col = 4
        state.blocks[0].row = 4
        state.blocks[0].spriteSet = 0x11
        state.blocks[0].frame = 1
        state.numActiveBlocks = 1
        state.splats.newSplat(x: 400, y: 80, kind: 0, frame: 0)
        state.points.newPoint(x: 204, y: 300, sprite: 3, delay: 0, level: 1, notRegistered: false)
        state.addToScore(10, multiply: false)
        state.prepareNotice(1)

        let ops = step(&state).drawOps
        let firstSprite = ops.firstIndex { if case .sprite = $0 { return true }; return false }!
        XCTAssertTrue(ops[..<firstSprite].allSatisfy { if case .restoreBgnd(_, .screen) = $0 { return true }; return false })
        let tail = Array(ops[firstSprite...])
        XCTAssertEqual(tail, [
            screenSprite(0x11, 5, 0, 0),                                   // hurt block
            screenSprite(1, 3, 280, 240),                                  // hero
            screenSprite(0x1b, 2, 80, 80),                                 // enemy
            screenSprite(0x11, 1, 160, 160),                               // block
            screenSprite(0x26, 1, 400, 80),                                // splat
            screenSprite(0x34, 3, 200, 307),                               // point (risen 1 px)
            .scoreToComp(QDRect(top: 446, left: 132, bottom: 476, right: 132)),
            compSprite(0x21, 1, 132, 446), compSprite(0x21, 1, 156, 446), compSprite(0x21, 1, 180, 446),
            compSprite(0x21, 2, 204, 446), compSprite(0x21, 1, 228, 446),  // "00010"
            .compToScreen(QDRect(top: 446, left: 132, bottom: 476, right: 252)),
            screenSprite(9, 1, 236, 221), screenSprite(9, 2, 300, 221), screenSprite(9, 3, 364, 221),
        ])
    }

    /// A popping balloon (state 3) in slot 0 at (x, y), box inside the playfield; `counter` = its pop step.
    private func placeBalloon(_ state: inout GameState, x: Int16, y: Int16, counter: Int16) {
        state.balloons[0].state = 3
        state.balloons[0].rect = QDRect(top: y, left: x, bottom: y + 40, right: x + 40)
        state.balloons[0].prevRect = state.balloons[0].rect
        state.balloons[0].box = QDRect(top: y + 8, left: x + 8, bottom: y + 31, right: x + 26)
        state.balloons[0].spriteSet = 0x31
        state.balloons[0].frame = 2
        state.balloons[0].counter = counter
        state.balloons[0].visible = true
        state.numActiveBalloons = 1
    }

    /// The rest of the pass, in `_PlayGame`'s order: hero (state 3) → balloon → bonus icon then shell → star →
    /// "Erk!" → air bubble → `_TimeBonus_Draw(0)` → `_DrawReserveInfo` (both through comp).
    func testDrawOrderBalloonsBonusStarsErkBubblesHUD() {
        var state = world()
        state.hero.state = 3
        state.newOuch()                                               // facing left: (243, 210), face 1
        placeBalloon(&state, x: 40, y: 320, counter: 0)
        state.bonus[0].armed = true
        state.bonus[0].visible = true
        state.bonus[0].launchFrame = 1000                             // not launched: no processing
        state.bonus[0].rect = QDRect.cell(col: 10, row: 2)
        state.bonus[0].iconSet = 0x1a
        state.bonus[0].iconFrame = 4
        state.bonus[0].shellFrame = 2
        state.stars.slots[0].active = true
        state.stars.slots[0].visible = true
        state.stars.slots[0].kind = 1
        state.stars.slots[0].spriteSet = 0x28
        state.stars.slots[0].frame = 1
        state.stars.slots[0].period = 100
        state.stars.slots[0].rect = QDRect(top: 100, left: 500, bottom: 126, right: 526)
        state.stars.slots[0].prevRect = state.stars.slots[0].rect      // a zero prevRect would queue cell (0,0)
        state.stars.activeCount = 1
        state.airBubbles.slots[0].active = true
        state.airBubbles.slots[0].visible = true
        state.airBubbles.slots[0].spriteSet = 0x2d
        state.airBubbles.slots[0].frame = 1
        state.airBubbles.slots[0].animPeriod = 100
        state.airBubbles.slots[0].snakeIndex = 4                      // table value 0: no x move
        state.airBubbles.slots[0].rect = QDRect(top: 300, left: 40, bottom: 316, right: 56)
        state.airBubbles.slots[0].prevRect = state.airBubbles.slots[0].rect
        state.airBubbles.activeCount = 1
        state.presentation.timeBonusHasChanged = true
        state.requestDrawReserveHero(animate: false)

        let ops = step(&state).drawOps
        let firstSprite = ops.firstIndex { if case .sprite = $0 { return true }; return false }!
        let sprites = ops[firstSprite...].compactMap { op -> DrawOp? in
            if case let .sprite(set, frame, h, v, mode, target) = op, target == .screen {
                return .sprite(set: set, frame: frame, h: h, v: v, mode: mode, target: target)
            }
            return nil
        }
        XCTAssertEqual(sprites, [
            screenSprite(1, 3, 280, 240),                                  // hero (state 3)
            screenSprite(0x31, 2, 40, 320),                                // balloon
            screenSprite(0x1a, 4, 400, 80), screenSprite(0x19, 2, 400, 80), // bonus icon, shell
            screenSprite(0x28, 1, 500, 100),                               // star
            screenSprite(0x10, 1, 243, 210),                               // "Erk!"
            screenSprite(0x2d, 1, 40, 300),                                // air bubble
        ])
        let lastScreen = ops.lastIndex(of: screenSprite(0x2d, 1, 40, 300))!
        let hud = Array(ops[(lastScreen + 1)...])
        XCTAssertEqual(hud.first, .scoreToComp(QDRect(top: 446, left: 480, bottom: 476, right: 480)))
        let timeEnd = hud.firstIndex { if case .compToScreen = $0 { return true }; return false }!
        XCTAssertEqual(Array(hud[(timeEnd + 1)...]), [
            .scoreToComp(QDRect(top: 445, left: 55, bottom: 476, right: 77)), compSprite(0x21, 3, 55, 446),
            .compToScreen(QDRect(top: 446, left: 55, bottom: 476, right: 77)),
            .scoreToComp(QDRect(top: 444, left: 16, bottom: 477, right: 48)), compSprite(8, 4, 16, 445),
            .compToScreen(QDRect(top: 445, left: 16, bottom: 477, right: 48)),
        ])
    }

    /// A balloon whose pop finishes and a bonus whose float-up ends die in the processing (visible cleared), so
    /// `_Balloons_DrawToComp` / `_Bonus_Draw` do not plot them on the frame that frees them.
    func testDeadBalloonAndBonusNotDrawnOnFreeingFrame() {
        var state = world()
        state.frame = 100
        placeBalloon(&state, x: 40, y: 320, counter: 3)               // 4th pop step → dead
        state.bonus[0].armed = true
        state.bonus[0].visible = true
        state.bonus[0].popped = true
        state.bonus[0].poppedFrame = 0                                // 0 + 30 < 101 → dead
        state.bonus[0].rect = QDRect.cell(col: 10, row: 2)
        state.bonus[0].prevRect = state.bonus[0].rect
        state.bonus[0].iconSet = 0x1a
        state.bonus[0].iconFrame = 4
        let ops = step(&state).drawOps
        XCTAssertFalse(ops.contains { if case .sprite(0x31, _, _, _, _, _) = $0 { return true }; return false })
        XCTAssertFalse(ops.contains { if case .sprite(0x1a, _, _, _, _, _) = $0 { return true }; return false })
        XCTAssertEqual(state.balloons[0].state, 0)
        XCTAssertEqual(state.numActiveBalloons, 0)
        XCTAssertFalse(state.bonus[0].armed)
        // Their last rects were still queued for restore at their process sites.
        XCTAssertTrue(ops.contains(.restoreBgnd(QDRect(top: 320, left: 40, bottom: 360, right: 80), target: .screen)))
        XCTAssertTrue(ops.contains(.restoreBgnd(QDRect.cell(col: 10, row: 2), target: .screen)))
    }

    /// The report owns the frame's ops: the state's buffer is empty after `stepFrame`.
    func testFrameOpsBufferEmptiedAfterReport() {
        var state = world()
        XCTAssertFalse(step(&state).drawOps.isEmpty)
        XCTAssertTrue(state.presentation.ops.isEmpty)
    }

    /// The bgnd list is filled by the processing at `_AddRectToBgnd`'s sites, in call order — `_ProcessEnemies`
    /// (prevRect), `_ProcessHero` (prevRect, first thing), `_Splats_Process`, `_ProcessBlocks` (before the move),
    /// `_ProcessPoints` (rect, after the rise) — and restored before any sprite.
    func testRestoreBgndPrecedesSprites() {
        var state = world()
        placeEnemy(&state, slot: 0, col: 2, row: 2, drawn: true, dead: false)
        state.blocks[0].state = 3
        state.blocks[0].type = CellCode.normal
        state.blocks[0].rect = QDRect.cell(col: 4, row: 4)
        state.blocks[0].prevRect = state.blocks[0].rect
        state.blocks[0].col = 4
        state.blocks[0].row = 4
        state.blocks[0].spriteSet = 0x11
        state.numActiveBlocks = 1
        state.splats.newSplat(x: 400, y: 80, kind: 0, frame: 0)
        state.points.newPoint(x: 204, y: 300, sprite: 3, delay: 0, level: 1, notRegistered: false)

        let ops = step(&state).drawOps
        let restores = ops.prefix { if case .restoreBgnd = $0 { return true }; return false }
        XCTAssertEqual(Array(restores), [
            .restoreBgnd(QDRect.cell(col: 2, row: 2), target: .screen),
            .restoreBgnd(QDRect.cell(col: 7, row: 6), target: .screen),
            .restoreBgnd(QDRect(top: 80, left: 400, bottom: 120, right: 440), target: .screen),
            .restoreBgnd(QDRect.cell(col: 4, row: 4), target: .screen),
            .restoreBgnd(QDRect(top: 307, left: 200, bottom: 335, right: 248), target: .screen),
        ])
        XCTAssertFalse(ops.dropFirst(restores.count).contains { if case .restoreBgnd = $0 { return true }; return false })
    }

    /// `_DrawEnemiesToComp` tests only the drawn flag (+0x46), then frees a dead slot: a dead-but-drawn enemy is
    /// plotted on its freeing frame, a dead undrawn one is not — both are freed.
    func testDeadEnemyDrawnOnFreeingFrameAsOriginal() {
        var state = world()
        placeEnemy(&state, slot: 0, col: 2, row: 2, drawn: true, dead: true)
        placeEnemy(&state, slot: 1, col: 3, row: 2, drawn: false, dead: true)
        let ops = step(&state).drawOps
        XCTAssertTrue(ops.contains(screenSprite(0x1b, 2, 80, 80)))
        XCTAssertFalse(ops.contains(screenSprite(0x1b, 2, 120, 80)))
        XCTAssertEqual(state.enemies[0].state, 0)
        XCTAssertEqual(state.enemies[1].state, 0)
    }

    // MARK: - HUD

    /// `_DrawScore`'s digit buffer starts 0,0,0,0,0,−1,−1,−1: scores draw at least five digits (leading zeros up to
    /// five — FI §6a's "no leading zeros" is wrong for scores below 10000), none beyond; 24-px pitch from x 132; the
    /// cache erase uses the previous right edge.
    func testScoreDigitsPadToFiveDigits() {
        var state = world()
        state.score = 123
        XCTAssertEqual(state.scoreOps(), [
            .scoreToComp(QDRect(top: 446, left: 132, bottom: 476, right: 132)),
            compSprite(0x21, 1, 132, 446), compSprite(0x21, 1, 156, 446), compSprite(0x21, 2, 180, 446),
            compSprite(0x21, 3, 204, 446), compSprite(0x21, 4, 228, 446),
            .compToScreen(QDRect(top: 446, left: 132, bottom: 476, right: 252)),
        ])
        state.score = 1_234_567
        let ops = state.scoreOps()
        XCTAssertEqual(ops.first, .scoreToComp(QDRect(top: 446, left: 132, bottom: 476, right: 252)))
        XCTAssertEqual(ops.compactMap { if case let .sprite(_, f, _, _, _, _) = $0 { return f - 1 }; return nil },
                       [1, 2, 3, 4, 5, 6, 7])
        XCTAssertEqual(ops.last, .compToScreen(QDRect(top: 446, left: 132, bottom: 476, right: 132 + 7 * 24)))
        XCTAssertEqual(state.scoreOps().count, 9)                     // forced: draws even unchanged
        XCTAssertFalse(state.presentation.scoreHasChanged)
    }

    /// `_DrawReserveHeroNumber` plots frame `lives` of set 0x21 (frame k = digit k − 1): 3 lives show "2"; 0 → frame 1.
    func testLivesDigitShowsSpareLives() {
        var state = world()
        state.lives = 3
        state.requestDrawReserveHero(animate: false)
        let ops = state.reserveInfoOps()
        XCTAssertEqual(Array(ops.prefix(3)), [
            .scoreToComp(QDRect(top: 445, left: 55, bottom: 476, right: 77)),
            compSprite(0x21, 3, 55, 446),
            .compToScreen(QDRect(top: 446, left: 55, bottom: 476, right: 77)),
        ])
        XCTAssertEqual(Array(ops.dropFirst(3)), [
            .scoreToComp(QDRect(top: 444, left: 16, bottom: 477, right: 48)),
            compSprite(8, 4, 16, 445),
            .compToScreen(QDRect(top: 445, left: 16, bottom: 477, right: 48)),
        ])
        XCTAssertFalse(state.presentation.reserveHeroNeedsDrawing)   // not animating: drawn once
        XCTAssertEqual(state.reserveInfoOps(), [])
        state.lives = 0
        state.requestDrawReserveHero(animate: false)
        XCTAssertEqual(state.reserveInfoOps()[1], compSprite(0x21, 1, 55, 446))
    }

    /// `_TimeBonus_Draw`: five digit slots from x 480, 23-px pitch, only a zero ten-thousands slot skipped, the
    /// digits shifted +22 (and the rect widened by 22) below 10000; flashing → set 0x22.
    func testTimeBonusShiftBelow10000() {
        var state = world()
        state.timeBonus = 2500
        XCTAssertEqual(state.timeBonusOps(), [
            .scoreToComp(QDRect(top: 446, left: 480, bottom: 476, right: 480)),
            compSprite(0x21, 3, 502, 446), compSprite(0x21, 6, 525, 446), compSprite(0x21, 1, 548, 446),
            compSprite(0x21, 1, 571, 446),
            .compToScreen(QDRect(top: 446, left: 480, bottom: 476, right: 594)),
        ])
        state.timeBonus = 12345
        XCTAssertEqual(state.timeBonusOps(), [
            .scoreToComp(QDRect(top: 446, left: 480, bottom: 476, right: 594)),
            compSprite(0x21, 2, 480, 446), compSprite(0x21, 3, 503, 446), compSprite(0x21, 4, 526, 446),
            compSprite(0x21, 5, 549, 446), compSprite(0x21, 6, 572, 446),
            .compToScreen(QDRect(top: 446, left: 480, bottom: 476, right: 595)),
        ])
        state.timeBonus = 0
        state.timeBonusIncrease(0)                                      // flash on, timer = frame
        let flashing = state.timeBonusOps()
        XCTAssertEqual(flashing.dropFirst().prefix(4), [compSprite(0x22, 1, 502, 446), compSprite(0x22, 1, 525, 446),
                                                         compSprite(0x22, 1, 548, 446), compSprite(0x22, 1, 571, 446)])
        XCTAssertTrue(state.presentation.timeBonusHasChanged)           // the flash keeps it redrawing
    }

    // MARK: - Notices

    /// `_DrawNotice` notice 6 (LEVEL n) in the frame, into the window: below 10 the word at 254/318 and the digit at
    /// 358; from 10 the word at 241/305, the units at 372 and then the tens at 345 — digits 2 px lower (v 223).
    func testNoticeLevelTwoDigitPlacement() {
        var state = world()
        state.level = 12
        state.prepareNotice(6)
        XCTAssertEqual(Array(step(&state).drawOps.suffix(4)), [
            screenSprite(0xe, 1, 241, 221), screenSprite(0xe, 2, 305, 221),
            screenSprite(0xf, 3, 372, 223), screenSprite(0xf, 2, 345, 223),
        ])
        state = world()
        state.level = 7
        state.prepareNotice(6)
        XCTAssertEqual(Array(step(&state).drawOps.suffix(3)), [
            screenSprite(0xe, 1, 254, 221), screenSprite(0xe, 2, 318, 221), screenSprite(0xf, 8, 358, 223),
        ])
    }

    // MARK: - The dirty list

    /// `_AddRectToBgnd` rounds left down / right up to 4 px, and `_CheckBlock` queues every stationary maze bubble
    /// the rect touches (once) as a hurt block — but not one a live block occupies.
    func testAddRectToBgndQueuesHurtBlockForMazeBubble() {
        var state = world()
        state.maze[3, 3] = CellCode.jewel
        state.addRectToBgnd(QDRect(top: 118, left: 118, bottom: 130, right: 130))
        XCTAssertEqual(state.presentation.bgndRects, [QDRect(top: 118, left: 116, bottom: 130, right: 132)])
        let active = state.hurtBlocks.filter(\.active)
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active.first.map { [Int($0.col), Int($0.row), Int($0.spriteSet), Int($0.frame),
                                           Int($0.left), Int($0.top)] },
                       [3, 3, 0x16, Int(state.levelRecord.words[4]), 120, 120])
        state.addRectToBgnd(QDRect.cell(col: 3, row: 3))
        XCTAssertEqual(state.hurtBlocks.filter(\.active).count, 1)    // already queued
        state.maze[0, 0] = CellCode.normal
        state.blocks[0].state = 1
        state.blocks[0].col = 0
        state.blocks[0].row = 0
        state.addRectToBgnd(QDRect.cell(col: 0, row: 0))
        XCTAssertEqual(state.hurtBlocks.filter(\.active).count, 1)    // a block sits there
    }

    /// `_sNumBgndRects` = 80: 79 entries append; the next one merges into the entry whose union grows least.
    func testBgndListMergesPastSeventyNine() {
        var state = world()
        for k in 0..<79 {
            state.addRectToBgnd(QDRect(top: Int16(k * 5), left: 600, bottom: Int16(k * 5 + 4), right: 604))
        }
        XCTAssertEqual(state.presentation.bgndRects.count, 79)
        state.addRectToBgnd(QDRect(top: 21, left: 600, bottom: 23, right: 604))
        XCTAssertEqual(state.presentation.bgndRects.count, 79)
        XCTAssertEqual(state.presentation.bgndRects[4], QDRect(top: 20, left: 600, bottom: 24, right: 604))
        state.addRectToBgnd(QDRect(top: 22, left: 608, bottom: 26, right: 612))
        XCTAssertEqual(state.presentation.bgndRects[4], QDRect(top: 20, left: 600, bottom: 26, right: 612))
    }
}
