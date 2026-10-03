@testable import BubbleTroubleCore
import Foundation
import XCTest

/// Task 5b — shared primitives II: enemy mutations, block creation, dynamite
/// (docs/plans/2026-10-03-btx-core-and-film-harness.md §Task 5b; Invariants 7, 8; Research notes 26, 34, 35, 38, 40;
/// INDEX C1, C12; B4, B7, B12).
///
/// Sources: `_SquishEnemy @ 0001131b`, `_PopEnemy @ 00011254`, `_KillEnemy @ 00010f57`, `_CaptureEnemy @ 00010fa6`,
/// `_ReleaseEnemyFromBalloon @ 00010ff3`, `_MakeAllEnemiesDisappear @ 000117d7`, `_WasEnemySquished @ 00010eca`,
/// `_Balloons_PopBalloon @ 00023a84`, `_Balloons_PopAll @ 00023f54`, `_NewBlock @ 0001b94b`, `_PushBlock @ 0001bd62`,
/// `_CrushBlock @ 0001bc14`, `_KillEggBlock @ 0001be3b`, `_IsActiveBombBlock @ 0001c9c6`,
/// `_ActivateBombBlock @ 0001c1c4`, `_ExplodeBombBlock @ 0001c032`, `_CheckForBombKills @ 000116eb`.
/// All worlds are synthetic (`GameState.testWorld`, an all-empty maze → hero at (7,6), rect (240, 280, 280, 320)).
final class PrimitivesMutationTests: XCTestCase {

    private func world(level: Int = 1) -> GameState {
        let maze = try! Maze(data: Data(count: Maze.byteCount))
        return GameState.testWorld(maze: maze, level: level)
    }

    /// An active (state 1) enemy of `type` aligned on (col, row) with its type's sprite set (0x1a + type).
    private func place(_ state: inout GameState, slot: Int, col: Int, row: Int, type: Int8 = 1,
                       enemyState: UInt8 = 1) {
        var e = Enemy()
        e.state = enemyState
        e.type = type
        e.spriteSet = 0x1a + Int16(type)
        e.col = Int8(col)
        e.row = Int8(row)
        e.rect = QDRect.cell(col: col, row: row)
        e.prevRect = e.rect
        e.aligned = true
        state.enemies[slot] = e
    }

    private func moveHero(_ state: inout GameState, col: Int, row: Int) {
        state.hero.col = Int8(col)
        state.hero.row = Int8(row)
        state.hero.rect = QDRect.cell(col: col, row: row)
    }

    /// B4 + Research note 34: n = 1…6 → +200, 400, 800, 1600, 3200, 3200 (×1) and point sprites 2, 4, 8, 0xb, 0x18,
    /// 0x18; n ≥ 3 then calls `_Bonus_SetNumEnemySquishes(n)` → multiplier 1, 1, 2, 3, 4, 5. Each case on a fresh
    /// world. The squish: dead, drawn 0, squished++, maze cell 0, enemy splat at the rect, star group 3 (piranha).
    func testSquishScoreTable() {
        let expected: [(score: Int32, sprite: Int16, multiplier: Int16)] =
            [(200, 2, 1), (400, 4, 1), (800, 8, 2), (1600, 0xb, 3), (3200, 0x18, 4), (3200, 0x18, 5)]
        for (i, want) in expected.enumerated() {
            let n = i + 1
            var state = world()
            XCTAssertEqual(state.multiplier, 1)
            XCTAssertEqual(state.bonusSquishedAtOnce, 0)
            state.frame = 50
            state.maze[3, 2] = 77        // a marker byte: the squish clears the enemy's cell whatever it holds
            place(&state, slot: 4, col: 3, row: 2)
            state.enemies[4].drawn = true
            state.squishEnemy(4, count: n)
            XCTAssertEqual(state.score, want.score, "n \(n)")
            XCTAssertEqual(state.multiplier, want.multiplier, "n \(n)")
            XCTAssertEqual(state.points.activeCount, 1, "n \(n)")
            XCTAssertEqual(state.points.slots[0].frame, want.sprite, "n \(n)")
            XCTAssertEqual(state.points.slots[0].delay, 0xc, "n \(n)")
            // _NewPoint(left 120, top 80): x − 4, rect (y + 8, x, y + 36, x + 48).
            XCTAssertEqual(state.points.slots[0].rect, QDRect(top: 88, left: 116, bottom: 116, right: 164), "n \(n)")
            XCTAssertTrue(state.enemies[4].dead, "n \(n)")
            XCTAssertFalse(state.enemies[4].drawn, "n \(n)")
            XCTAssertEqual(state.enemies[4].state, 1, "n \(n): the slot is freed only by the draw pass")
            XCTAssertEqual(state.numEnemiesSquished, 1, "n \(n)")
            XCTAssertEqual(state.maze[3, 2], 0, "n \(n)")
            XCTAssertEqual(state.splats.slots[0].active, true, "n \(n)")
            XCTAssertEqual(state.splats.slots[0].spriteSet, 0x26, "n \(n)")
            XCTAssertEqual(state.splats.slots[0].rect, QDRect.cell(col: 3, row: 2), "n \(n)")
            // Star group 3 at (120, 80): 4 hop stars of kind 4, none clipped → 4 draws.
            XCTAssertEqual(state.stars.activeCount, 4, "n \(n)")
            XCTAssertEqual(state.stars.slots[0].kind, 4, "n \(n)")
            XCTAssertEqual(state.rng.drawCount, 4, "n \(n)")
            // A second squish of the now-dead enemy is ignored entirely.
            state.squishEnemy(4, count: n)
            XCTAssertEqual(state.score, want.score, "n \(n)")
            XCTAssertEqual(state.numEnemiesSquished, 1, "n \(n)")
            XCTAssertEqual(state.rng.drawCount, 4, "n \(n)")
        }
    }

    /// C1: `_CheckForBombKills` tests the hero once per rect (`_IsHeroCaught(rect, 1, 1)`), but `_HeroCaught` sets
    /// state 3 first, so three blast rects on the hero catch it once: one `(0,1)` + group 0xe's 14 hop stars at
    /// (280, 240) (none clipped) = 15 draws, one hero splat.
    func testHeroCaughtOncePerFrame() {
        var state = world()
        state.frame = 200
        var blast = QDRect.cell(col: 7, row: 6)
        blast.inset(dx: -40, dy: -40)
        for _ in 0..<3 {
            XCTAssertEqual(state.checkForBombKills(blast, base: 0), 0)
        }
        XCTAssertEqual(state.hero.state, 3)
        XCTAssertEqual(state.hero.stateStart, 200)
        XCTAssertFalse(state.hero.visible)
        XCTAssertTrue(state.heroCaughtThisFrame)
        XCTAssertEqual(state.stars.activeCount, 14)
        XCTAssertEqual(state.rng.drawCount, 1 + state.stars.activeCount)
        XCTAssertEqual(state.rng.drawCount, 15)
        XCTAssertEqual(state.splats.slots.filter(\.active).count, 1)
    }

    /// Research note 35: first free of 35; types 10/15/16 moving (state 1, sprite 0x11/0x14/0x15, frame 1); 20 jewel
    /// moving (0x16, frame 1, jewel cell); 30 cluster static (0x17, frame 1); 40 pop (state 2, 0x18, frame 1);
    /// 52 dynamite (moving → state 1, frame 1; fuse → state 3, frame 2; 0x12 below level 12, 0x13 from 12); 60 egg
    /// (state 3, 0x1f, frame = enemy type, `+0x2a` = 15). start = frame; `_gNumActiveBlocks++`. A freed slot is reused.
    func testNewBlockFirstFreeSlotAndTypes() {
        var state = world()
        state.frame = 33
        place(&state, slot: 7, col: 9, row: 9, type: 2, enemyState: 2)
        let rows: [(type: UInt8, moving: Bool, blockState: UInt8, sprite: Int16, frame: Int16, moves: Bool)] = [
            (10, true, 1, 0x11, 1, true), (15, true, 1, 0x14, 1, true), (16, true, 1, 0x15, 1, true),
            (20, true, 1, 0x16, 1, true), (30, false, 1, 0x17, 1, false), (40, false, 2, 0x18, 1, false),
            (52, true, 1, 0x12, 1, true), (52, false, 3, 0x12, 2, false), (60, false, 3, 0x1f, 2, false),
        ]
        for (slot, row) in rows.enumerated() {
            let enemy: Int8 = row.type == 60 ? 7 : -1
            let got = state.newBlock(col: slot, row: 3, direction: .right, type: row.type, enemy: enemy,
                                     moving: row.moving)
            XCTAssertEqual(got, slot, "type \(row.type)")
            let b = state.blocks[slot]
            XCTAssertEqual(b.state, row.blockState, "type \(row.type)")
            XCTAssertEqual(b.type, row.type)
            XCTAssertEqual(b.spriteSet, row.sprite, "type \(row.type)")
            XCTAssertEqual(b.frame, row.frame, "type \(row.type)")
            XCTAssertEqual(b.moving, row.moves, "type \(row.type)")
            XCTAssertEqual(b.rect, QDRect.cell(col: slot, row: 3))
            XCTAssertEqual(b.prevRect, b.rect)
            XCTAssertEqual(b.col, Int8(slot))
            XCTAssertEqual(b.row, 3)
            XCTAssertEqual(b.direction, .right)
            XCTAssertTrue(b.aligned)
            XCTAssertEqual(b.squishCount, 0)
            XCTAssertFalse(b.retired)
            XCTAssertEqual(b.enemy, enemy)
            XCTAssertEqual(b.startFrame, 33)
            if row.type == 20 || row.type == 30 {
                XCTAssertEqual(b.jewelCol, Int8(slot))
                XCTAssertEqual(b.jewelRow, 3)
            }
            if row.type == 60 {
                XCTAssertEqual(b.eggPopDelay, 15)
            }
        }
        XCTAssertEqual(state.numActiveBlocks, rows.count)
        // From level 12 dynamite uses sprite set 0x13.
        var late = world(level: 12)
        XCTAssertEqual(late.newBlock(col: 1, row: 1, direction: nil, type: 52, enemy: -1, moving: false), 0)
        XCTAssertEqual(late.blocks[0].spriteSet, 0x13)
        XCTAssertNil(late.blocks[0].direction)
        // A slot freed by the draw pass (state byte 0) is the next one allocated.
        state.blocks[2].state = 0
        XCTAssertEqual(state.newBlock(col: 14, row: 9, direction: .up, type: 10, enemy: -1, moving: true), 2)
        XCTAssertEqual(state.newBlock(col: 14, row: 8, direction: .up, type: 10, enemy: -1, moving: true), rows.count)
        XCTAssertEqual(state.rng.drawCount, 0)
    }

    /// Research note 26: `_PushBlock` makes a moving block of the pushed type in the adjacent cell
    /// (`_NewBlock(next, dir, type, −1, 1)`) and clears that maze cell.
    func testPushBlockClearsCell() {
        var state = world()
        state.frame = 90
        state.maze[5, 6] = CellCode.blue
        state.pushBlock(col: 4, row: 6, direction: .right, type: CellCode.blue)
        XCTAssertEqual(state.maze[5, 6], 0)
        let b = state.blocks[0]
        XCTAssertEqual(b.state, 1)
        XCTAssertEqual(b.type, CellCode.blue)
        XCTAssertTrue(b.moving)
        XCTAssertEqual(b.direction, .right)
        XCTAssertEqual(b.enemy, -1)
        XCTAssertEqual(b.rect, QDRect.cell(col: 5, row: 6))
        XCTAssertEqual(b.startFrame, 90)
        XCTAssertEqual(state.numActiveBlocks, 1)
        // Each direction picks its neighbour: up → row − 1, down → row + 1, left → col − 1.
        state.maze[4, 2] = CellCode.normal
        state.pushBlock(col: 4, row: 3, direction: .up, type: CellCode.normal)
        XCTAssertEqual(state.maze[4, 2], 0)
        XCTAssertEqual(state.blocks[1].rect, QDRect.cell(col: 4, row: 2))
        state.maze[4, 4] = CellCode.purple
        state.pushBlock(col: 4, row: 3, direction: .down, type: CellCode.purple)
        XCTAssertEqual(state.maze[4, 4], 0)
        XCTAssertEqual(state.blocks[2].rect, QDRect.cell(col: 4, row: 4))
        state.maze[3, 3] = CellCode.normal
        state.pushBlock(col: 4, row: 3, direction: .left, type: CellCode.normal)
        XCTAssertEqual(state.maze[3, 3], 0)
        XCTAssertEqual(state.blocks[3].rect, QDRect.cell(col: 3, row: 3))
        XCTAssertEqual(state.score, 0)
    }

    /// Research note 26: `_CrushBlock` pops the adjacent cell (`_NewBlock(next, dir, 0x28, −1, 0)` → state 2, sprite
    /// 0x18), maze 0x28 unless the cell is dynamite (52 stays), and `_AddToScore(1, 1)` (×mult) when the score flag is
    /// set.
    func testCrushBlockScoresAndMarksCell() {
        var state = world()
        state.multiplier = 3
        state.maze[5, 6] = CellCode.normal
        state.crushBlock(col: 4, row: 6, direction: .right, score: true)
        XCTAssertEqual(state.maze[5, 6], CellCode.popping)
        XCTAssertEqual(state.score, 3)
        let b = state.blocks[0]
        XCTAssertEqual(b.type, CellCode.popping)
        XCTAssertEqual(b.state, 2)
        XCTAssertEqual(b.spriteSet, 0x18)
        XCTAssertEqual(b.frame, 1)
        XCTAssertFalse(b.moving)
        XCTAssertEqual(b.rect, QDRect.cell(col: 5, row: 6))
        // Dynamite: the pop block is made but the cell stays 52.
        state.maze[4, 7] = CellCode.dynamite
        state.crushBlock(col: 4, row: 6, direction: .down, score: true)
        XCTAssertEqual(state.maze[4, 7], CellCode.dynamite)
        XCTAssertEqual(state.blocks[1].type, CellCode.popping)
        XCTAssertEqual(state.score, 6)
        // Score flag clear → no score.
        state.maze[3, 6] = CellCode.normal
        state.crushBlock(col: 4, row: 6, direction: .left, score: false)
        XCTAssertEqual(state.maze[3, 6], CellCode.popping)
        XCTAssertEqual(state.score, 6)
        XCTAssertEqual(state.numActiveBlocks, 3)
        XCTAssertEqual(state.rng.drawCount, 0)
    }

    /// Research note 26: `_KillEggBlock` finds the egg block (type 60) in the adjacent cell → type 0x28, state 2,
    /// sprite 0x18, frame 1, static; maze 0x28; `_AddToScore(50, 1)`; `_NewPoint(block.left, block.top, 0x15, 0xc)`;
    /// `_KillEnemy(block.enemy, 0)` (dead, squished++, cell untouched); star group 3 (enemy sprite 0x1b) / 4 (0x1c,
    /// 0x1e) / 5 (other) at the egg cell ×40.
    func testKillEggBlock() {
        for (spriteSet, group) in [(Int16(0x1b), 3), (0x1c, 4), (0x1e, 4), (0x1d, 5)] {
            var state = world()
            state.multiplier = 2
            state.frame = 120
            place(&state, slot: 3, col: 5, row: 6, type: 1, enemyState: 2)
            state.enemies[3].spriteSet = spriteSet
            state.maze[5, 6] = CellCode.egg
            state.newBlock(col: 5, row: 6, direction: nil, type: CellCode.egg, enemy: 3, moving: false)
            state.killEggBlock(col: 4, row: 6, direction: .right)
            XCTAssertEqual(state.score, 100, "sprite \(spriteSet)")
            XCTAssertEqual(state.maze[5, 6], CellCode.popping)
            let b = state.blocks[0]
            XCTAssertEqual(b.type, CellCode.popping)
            XCTAssertEqual(b.state, 2)
            XCTAssertEqual(b.spriteSet, 0x18)
            XCTAssertEqual(b.frame, 1)
            XCTAssertEqual(b.startFrame, 120)
            XCTAssertFalse(b.moving)
            XCTAssertTrue(state.enemies[3].dead)
            XCTAssertEqual(state.numEnemiesSquished, 1)
            XCTAssertEqual(state.points.activeCount, 1)
            XCTAssertEqual(state.points.slots[0].frame, 0x15)
            XCTAssertEqual(state.points.slots[0].delay, 0xc)
            // _NewPoint(left 200, top 240): rect (248, 196, 276, 244).
            XCTAssertEqual(state.points.slots[0].rect, QDRect(top: 248, left: 196, bottom: 276, right: 244))
            // Group 3/4/5 → 4 hop stars of kind group + 1 at (200, 240), none clipped.
            XCTAssertEqual(state.stars.activeCount, 4, "sprite \(spriteSet)")
            XCTAssertEqual(state.stars.slots[0].kind, Int16(group + 1), "sprite \(spriteSet)")
            XCTAssertEqual(state.stars.slots[0].rect.left, 192, "sprite \(spriteSet)")
            XCTAssertEqual(state.rng.drawCount, 4, "sprite \(spriteSet)")
        }
        // No egg block in the adjacent cell → nothing.
        var state = world()
        state.killEggBlock(col: 4, row: 6, direction: .right)
        XCTAssertEqual(state.score, 0)
        XCTAssertEqual(state.numActiveBlocks, 0)
    }

    /// Research note 26: `_ActivateBombBlock` with no lit fuse in the cell makes one (`_NewBlock(cell, dir, 0x34, −1,
    /// 0)`: static, state 3, frame 2); a lit fuse explodes now only when `start + 30 < frame` (lit at f: f + 30 →
    /// nothing, f + 31 → explode).
    func testFuseAndRelight() {
        var state = world()
        state.maze[5, 6] = CellCode.dynamite
        state.frame = 100
        XCTAssertFalse(state.isActiveBombBlock(col: 5, row: 6))
        state.activateBombBlock(col: 4, row: 6, direction: .right)
        XCTAssertTrue(state.isActiveBombBlock(col: 5, row: 6))
        XCTAssertFalse(state.isActiveBombBlock(col: 6, row: 6))
        var b = state.blocks[0]
        XCTAssertEqual(b.type, CellCode.dynamite)
        XCTAssertEqual(b.state, 3)
        XCTAssertEqual(b.frame, 2)
        XCTAssertEqual(b.spriteSet, 0x12)
        XCTAssertFalse(b.moving)
        XCTAssertEqual(b.startFrame, 100)
        state.frame = 130
        state.activateBombBlock(col: 4, row: 6, direction: .right)
        XCTAssertEqual(state.numActiveBlocks, 1)
        XCTAssertFalse(state.blocks[0].retired)
        XCTAssertEqual(state.maze[5, 6], CellCode.dynamite)
        XCTAssertEqual(state.stars.activeCount, 0)
        state.frame = 131
        state.activateBombBlock(col: 4, row: 6, direction: .right)
        b = state.blocks[0]
        XCTAssertTrue(b.retired)
        XCTAssertEqual(b.spriteSet, -1)
        XCTAssertEqual(b.frame, 1)
        XCTAssertEqual(state.maze[5, 6], 0)
        XCTAssertEqual(state.numActiveBlocks, 1)
        XCTAssertEqual(state.stars.activeCount, 9, "small blast: group 0xf")
        XCTAssertEqual(state.rng.drawCount, 0)
    }

    /// B12 + Research note 38: level 1, bomb (5,5) → blast rect (160, 160, 280, 280), one `_CheckForBombKills(rect, 0)`.
    /// Slot 0 at (4,4) and slot 1 at (6,6) overlap → squished with n = 1, 2 (+200, +400 = 600); slot 2 at (3,5)
    /// (right edge 160) only touches → untouched. Group 0xf (9 kind-7 stars, motion 0) makes 0 draws; the two squish
    /// groups (3, piranha) make 4 each.
    func testSmallBlastRect() {
        var state = world()
        state.frame = 300
        place(&state, slot: 0, col: 4, row: 4)
        place(&state, slot: 1, col: 6, row: 6)
        place(&state, slot: 2, col: 3, row: 5)
        state.maze[5, 5] = CellCode.dynamite
        let slot = state.newBlock(col: 5, row: 5, direction: nil, type: CellCode.dynamite, enemy: -1, moving: false)
        state.explodeBombBlock(slot)
        XCTAssertEqual(state.maze[5, 5], 0)
        XCTAssertTrue(state.blocks[slot].retired)
        XCTAssertTrue(state.enemies[0].dead)
        XCTAssertTrue(state.enemies[1].dead)
        XCTAssertFalse(state.enemies[2].dead)
        XCTAssertEqual(state.numEnemiesSquished, 2)
        XCTAssertEqual(state.score, 600)
        XCTAssertEqual(state.points.slots[0].frame, 2)
        XCTAssertEqual(state.points.slots[1].frame, 4)
        XCTAssertEqual(state.multiplier, 1)
        XCTAssertEqual(state.hero.state, 2)
        // 9 kind-7 stars (group 0xf at (200, 200), first in the pool) + 2 × 4 hop stars.
        XCTAssertEqual(state.stars.activeCount, 17)
        XCTAssertEqual(state.stars.slots[0..<9].filter { $0.kind == 7 && $0.motion == 0 }.count, 9)
        XCTAssertEqual(state.rng.drawCount, 8, "group 0xf draws nothing; each squish group draws 4")
        // The blast rect itself: what `_CheckForBombKills` would see.
        var blast = QDRect.cell(col: 5, row: 5)
        blast.inset(dx: -40, dy: -40)
        XCTAssertEqual(blast, QDRect(top: 160, left: 160, bottom: 280, right: 280))
    }

    /// Invariant 7 + B12: level 12, bomb (5,5) → rects A (top−80, left−40, bottom−40, right+40) base 0, B (top+80,
    /// left−40, bottom+80, right+40) base n_A, C (top−40, left−80, bottom+40, right+80) base n_A + n_B. Slot 0 at
    /// (5,4) is in A (n = 1 → 200) and again in C, where the count advances over the dead enemy (ignored squish) so
    /// slot 1 at (3,5) is squished with n = 1 + 2 = 3 → 800 and the multiplier steps 1 → 2. Score 1000 (the fixed
    /// count would give 600 and 1).
    func testBigBlastDoubleCount() {
        var state = world(level: 12)
        moveHero(&state, col: 14, row: 1)
        place(&state, slot: 0, col: 5, row: 4)
        place(&state, slot: 1, col: 3, row: 5)
        state.maze[5, 5] = CellCode.dynamite
        let slot = state.newBlock(col: 5, row: 5, direction: nil, type: CellCode.dynamite, enemy: -1, moving: false)
        XCTAssertEqual(state.blocks[slot].spriteSet, 0x13)
        state.explodeBombBlock(slot)
        XCTAssertEqual(state.score, 1000)
        XCTAssertEqual(state.multiplier, 2)
        XCTAssertEqual(state.points.slots[0].frame, 2)
        XCTAssertEqual(state.points.slots[1].frame, 8)
        XCTAssertEqual(state.numEnemiesSquished, 2)
        XCTAssertEqual(state.hero.state, 2)
        XCTAssertEqual(state.maze[5, 5], 0)
        // Group 0x10 (21 kind-7 stars around (200, 200), none clipped, no draws) + 2 × 4 hop stars.
        XCTAssertEqual(state.stars.activeCount, 29)
        XCTAssertEqual(state.rng.drawCount, 8)
    }

    /// `_StopAllEnemies` then `_MakeAllEnemiesDisappear`: held balloons popped (`_Balloons_PopAll`: state 2 → 3, sprite
    /// 0x33, frame 1, counter 0, start = frame); every non-free enemy dead, drawn 0, state 5, `level.pool[type]++`;
    /// `gNumEnemiesSquished` unchanged; free slots untouched.
    func testStopAllAndDisappear() {
        var state = world()
        state.frame = 400
        place(&state, slot: 0, col: 1, row: 1, type: 1)
        place(&state, slot: 2, col: 2, row: 2, type: 1, enemyState: 2)
        place(&state, slot: 5, col: 3, row: 3, type: 3)
        state.captureEnemy(5, balloon: 4)
        state.balloons[4].state = 2
        state.balloons[4].holder = 5
        state.balloons[4].spriteSet = 0x32
        state.balloons[7].state = 1      // a flying balloon is not popped by PopAll
        state.balloons[7].spriteSet = 0x31
        state.enemies[0].drawn = true
        // The pool after spawning these three (LEVL w18 = 4 piranhas, w20 = 0 sharks): 2 piranhas, −1 shark left.
        state.levelRecord.words[18] = 2
        state.levelRecord.words[20] = -1
        state.numEnemiesSquished = 1
        state.stopAllEnemies()
        XCTAssertEqual(state.enemies[0].state, 5)
        XCTAssertEqual(state.enemies[5].state, 5)
        state.makeAllEnemiesDisappear()
        XCTAssertEqual(state.levelRecord.words[18], 4)
        XCTAssertEqual(state.levelRecord.words[20], 0)
        XCTAssertEqual(state.numEnemiesSquished, 1)
        for slot in [0, 2, 5] {
            XCTAssertTrue(state.enemies[slot].dead, "slot \(slot)")
            XCTAssertFalse(state.enemies[slot].drawn, "slot \(slot)")
            XCTAssertEqual(state.enemies[slot].state, 5, "slot \(slot)")
        }
        XCTAssertFalse(state.enemies[1].dead)
        XCTAssertEqual(state.enemies[1].state, 0)
        XCTAssertEqual(state.balloons[4].state, 3)
        XCTAssertEqual(state.balloons[4].spriteSet, 0x33)
        XCTAssertEqual(state.balloons[4].frame, 1)
        XCTAssertEqual(state.balloons[4].counter, 0)
        XCTAssertEqual(state.balloons[4].startFrame, 400)
        XCTAssertEqual(state.balloons[7].state, 1)
        XCTAssertEqual(state.rng.drawCount, 0)
    }

    /// Research note 34 + Invariant 7 + B7: `_WasEnemySquished(rect)` returns the first enemy in states 1/4/5/6/3
    /// whose rect strictly overlaps; a state-6 enemy's balloon is popped (state 3). The dead flag is NOT tested — a
    /// squished-but-unfreed state-1 enemy is still returned. −1 when none.
    func testWasEnemySquishedPopsHeldBalloon() {
        var state = world()
        state.frame = 77
        place(&state, slot: 1, col: 5, row: 5, type: 3)
        state.captureEnemy(1, balloon: 2)
        XCTAssertEqual(state.enemies[1].state, 6)
        XCTAssertEqual(state.enemies[1].spriteSet, 0x20)
        XCTAssertEqual(state.enemies[1].animFrame, 3)
        XCTAssertEqual(state.enemies[1].balloonIndex, 2)
        state.balloons[2].state = 2
        state.balloons[2].holder = 1
        var probe = QDRect.cell(col: 5, row: 5)
        probe.inset(dx: 3, dy: 3)
        XCTAssertEqual(state.wasEnemySquished(probe), 1)
        XCTAssertEqual(state.balloons[2].state, 3)
        XCTAssertEqual(state.balloons[2].spriteSet, 0x33)
        XCTAssertEqual(state.balloons[2].frame, 1)
        XCTAssertEqual(state.balloons[2].startFrame, 77)
        // B7: dead but not yet freed (state 1) → still returned.
        place(&state, slot: 0, col: 8, row: 8)
        state.enemies[0].dead = true
        XCTAssertEqual(state.wasEnemySquished(QDRect.cell(col: 8, row: 8)), 0)
        // Edge contact only (strict collide) and states 0/2 are not candidates.
        XCTAssertEqual(state.wasEnemySquished(QDRect.cell(col: 9, row: 8)), -1)
        place(&state, slot: 3, col: 10, row: 2, type: 1, enemyState: 2)
        XCTAssertEqual(state.wasEnemySquished(QDRect.cell(col: 10, row: 2)), -1)
        // C12 / NR-6: slot −1 (the hero's balloon) is a no-op for pop and release.
        let before = state.enemies
        state.popEnemy(-1)
        state.releaseEnemyFromBalloon(-1)
        XCTAssertEqual(state.enemies, before)
        XCTAssertEqual(state.score, 0)
        XCTAssertEqual(state.rng.drawCount, 0)
    }
}
