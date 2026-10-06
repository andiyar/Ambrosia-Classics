@testable import BubbleTroubleCore
import Foundation
import XCTest

/// Task 7a — items I: balloons (docs/plans/2026-10-03-btx-core-and-film-harness.md §Task 7a; Invariants 8, 9, 18;
/// Research note 40; INDEX C4, C5, C12 / NR-6).
///
/// Sources: `_Balloons_New @ 000237f9`, `_Balloons_Process @ 00024394`, `_Balloons_MoveBalloon @ 00023b3d`,
/// `_Balloons_CaptureHero @ 00023cbb`, `_Balloons_CheckBalloonEnemyHit @ 00023f90`,
/// `_Balloons_CheckHardObjectHit @ 00023da7`, `_Balloons_CheckSquishes @ 00023ae8`,
/// `_Balloons_CaptureAllEnemies @ 000240dd`. All worlds are synthetic (`GameState.testWorld`, an all-empty maze →
/// hero at (7,6), rect (240, 280, 280, 320), facing left).
final class BalloonTests: XCTestCase {

    private func world(level: Int = 1) -> GameState {
        let maze = try! Maze(data: Data(count: Maze.byteCount))
        return GameState.testWorld(maze: maze, level: level)
    }

    /// An enemy of `type` in `enemyState`, aligned on (col, row), facing `direction`.
    private func place(_ state: inout GameState, slot: Int, col: Int, row: Int, type: Int8 = 1,
                       enemyState: UInt8 = 1, direction: Direction? = nil) {
        var e = Enemy()
        e.state = enemyState
        e.type = type
        e.spriteSet = 0x1a + Int16(type)
        e.col = Int8(col)
        e.row = Int8(row)
        e.rect = QDRect.cell(col: col, row: row)
        e.prevRect = e.rect
        e.aligned = true
        e.direction = direction
        state.enemies[slot] = e
    }

    /// One game frame of balloon logic: the frame counter advances, then `_Balloons_Process`.
    private func step(_ state: inout GameState) {
        state.frame &+= 1
        state.balloonsProcess()
    }

    /// Research note 40: a shark facing down at (5,5) (rect (200, 200, 240, 240)) spawns its balloon in the first
    /// free slot — rect = the shark's rect offset +20 down, box 17×17 in front ((240+20, 200+11) … (240+37, 200+28)),
    /// sprite 0x31 frame 1, start/anim timer = frame, one `GetRandomFast(4,7)` for the anim period.
    func testBalloonNew() {
        var state = world()
        state.frame = 33
        place(&state, slot: 3, col: 5, row: 5, type: 3, direction: .down)
        state.balloons[0].state = 2                      // slot 0 taken → first free is slot 1
        state.numActiveBalloons = 1
        XCTAssertEqual(state.rng.drawCount, 0)
        state.balloonsNew(enemy: 3)
        XCTAssertEqual(state.rng.drawCount, 1)
        XCTAssertEqual(state.numActiveBalloons, 2)
        let b = state.balloons[1]
        XCTAssertEqual(b.state, 1)
        XCTAssertEqual(b.startFrame, 33)
        XCTAssertEqual(b.animTimer, 33)
        XCTAssertTrue((4...7).contains(b.animPeriod))
        XCTAssertEqual(b.rect, QDRect(top: 220, left: 200, bottom: 260, right: 240))
        XCTAssertEqual(b.prevRect, b.rect)
        XCTAssertEqual(b.box, QDRect(top: 260, left: 211, bottom: 277, right: 228))
        XCTAssertEqual(b.box.bottom - b.box.top, 17)
        XCTAssertEqual(b.box.right - b.box.left, 17)
        XCTAssertEqual(b.spriteSet, 0x31)
        XCTAssertEqual(b.frame, 1)
        XCTAssertEqual(b.counter, 0)
        XCTAssertEqual(b.direction, .down)
        XCTAssertTrue(b.visible)
        XCTAssertFalse(b.dead)
        XCTAssertEqual(state.balloons[2].state, 0)

        // An enemy with no direction claims nothing and draws nothing.
        place(&state, slot: 4, col: 9, row: 2, type: 3, direction: nil)
        state.balloonsNew(enemy: 4)
        XCTAssertEqual(state.rng.drawCount, 1)
        XCTAssertEqual(state.numActiveBalloons, 2)
        XCTAssertEqual(state.balloons[2].state, 0)

        // Cap 30: a full pool returns before the draw.
        state.numActiveBalloons = 30
        state.balloonsNew(enemy: 3)
        XCTAssertEqual(state.rng.drawCount, 1)
        XCTAssertEqual(state.balloons[2].state, 0)
    }

    /// C4: the box moves 8 px with the rect each flying call; on the 3rd flying call it becomes
    /// (top+8, left+8, top+31, left+26) of the rect and the frame becomes 2 — the frame ≤ 1 gate then fails for good.
    func testBalloonGrowsOnceOnThirdFrame() {
        var state = world()
        place(&state, slot: 0, col: 1, row: 0, type: 3, direction: .down)   // rect (0, 40, 40, 80)
        state.balloonsNew(enemy: 0)
        XCTAssertEqual(state.balloons[0].rect, QDRect(top: 20, left: 40, bottom: 60, right: 80))
        XCTAssertEqual(state.balloons[0].box, QDRect(top: 60, left: 51, bottom: 77, right: 68))

        step(&state)
        XCTAssertEqual(state.balloons[0].rect, QDRect(top: 28, left: 40, bottom: 68, right: 80))
        XCTAssertEqual(state.balloons[0].box, QDRect(top: 68, left: 51, bottom: 85, right: 68))
        XCTAssertEqual(state.balloons[0].frame, 1)
        XCTAssertEqual(state.balloons[0].counter, 1)
        step(&state)
        XCTAssertEqual(state.balloons[0].box, QDRect(top: 76, left: 51, bottom: 93, right: 68))
        XCTAssertEqual(state.balloons[0].frame, 1)
        XCTAssertEqual(state.balloons[0].counter, 2)
        step(&state)                                      // 3rd flying call: the one growth
        let r3 = state.balloons[0].rect
        XCTAssertEqual(r3, QDRect(top: 44, left: 40, bottom: 84, right: 80))
        XCTAssertEqual(state.balloons[0].box, QDRect(top: 52, left: 48, bottom: 75, right: 66))
        XCTAssertEqual(state.balloons[0].frame, 2)
        XCTAssertEqual(state.balloons[0].counter, 0)

        for call in 4...12 {
            step(&state)
            let b = state.balloons[0]
            XCTAssertEqual(b.state, 1, "call \(call)")
            XCTAssertEqual(b.frame, 2, "call \(call)")
            XCTAssertEqual(b.counter, 0, "call \(call)")
            XCTAssertEqual(b.box, QDRect(top: b.rect.top + 8, left: b.rect.left + 8, bottom: b.rect.top + 31,
                                         right: b.rect.left + 26), "call \(call): the box never changes shape again")
        }
        XCTAssertEqual(state.balloons[0].rect.top, 20 + 12 * 8)
        XCTAssertEqual(state.rng.drawCount, 1)
    }

    /// Research note 40: the flying arm tests the enemies first — a box over an enemy (state 1) and the hero captures
    /// the enemy (balloon state 2, sprite 0x32, rect = box = the enemy's rect, holder = slot, kind 0x50; the enemy
    /// state 6 holding the balloon index) and the hero is not trapped. Without the enemy the same flight traps the
    /// hero (`_Balloons_CaptureHero`: kind 0x46, holder −1, rect = box = the hero's rect, trapStart = frame).
    func testBalloonCaptureOrder() {
        var state = world()
        state.frame = 100
        place(&state, slot: 0, col: 7, row: 4, type: 3, direction: .down)   // shark above the hero
        place(&state, slot: 2, col: 7, row: 6, type: 1)                     // piranha on the hero's cell
        state.balloonsNew(enemy: 0)
        XCTAssertEqual(state.balloons[0].box, QDRect(top: 220, left: 291, bottom: 237, right: 308))
        step(&state)                                       // box (228, 291, 245, 308) overlaps both
        let b = state.balloons[0]
        XCTAssertEqual(b.state, 2)
        XCTAssertEqual(b.startFrame, 101)
        XCTAssertEqual(b.animTimer, 101)
        XCTAssertEqual(b.spriteSet, 0x32)
        XCTAssertEqual(b.frame, 1)
        XCTAssertEqual(b.captureKind, 0x50)
        XCTAssertEqual(b.holder, 2)
        XCTAssertEqual(b.rect, QDRect.cell(col: 7, row: 6))
        XCTAssertEqual(b.box, b.rect)
        XCTAssertEqual(state.enemies[2].state, 6)
        XCTAssertEqual(state.enemies[2].balloonIndex, 0)
        XCTAssertEqual(state.enemies[2].spriteSet, 0x20)
        XCTAssertEqual(state.enemies[0].state, 1, "the shark itself is not under the box")
        XCTAssertFalse(state.hero.trapped)

        // The same flight with no enemy under the box traps the hero.
        var solo = world()
        solo.frame = 100
        place(&solo, slot: 0, col: 7, row: 4, type: 3, direction: .down)
        solo.balloonsNew(enemy: 0)
        step(&solo)
        let h = solo.balloons[0]
        XCTAssertEqual(h.state, 2)
        XCTAssertEqual(h.startFrame, 101)
        XCTAssertEqual(h.spriteSet, 0x32)
        XCTAssertEqual(h.frame, 1)
        XCTAssertEqual(h.captureKind, 0x46)
        XCTAssertEqual(h.holder, -1)
        XCTAssertEqual(h.rect, solo.hero.rect)
        XCTAssertEqual(h.box, solo.hero.rect)
        XCTAssertTrue(solo.hero.trapped)
        XCTAssertEqual(solo.hero.trapStart, 101)
    }

    /// Level 1 (w15/w16 = 140/170): a balloon holding an enemy since h stays visible through h+140, toggles its
    /// visibility on every frame from `h + 140 < frame` (h+141), and at h+171 (`h + 170 < frame`) it is shown,
    /// popped (state 3, sprite 0x33) and the enemy released (state 1); the pop runs 4 frames, then dead (the slot
    /// stays claimed for the draw pass — Invariant 8).
    func testBalloonHoldFlashRelease() {
        var state = world(level: 1)
        XCTAssertEqual(state.levelRecord.balloonFlash, 140)
        XCTAssertEqual(state.levelRecord.balloonRelease, 170)
        let h: UInt16 = 10
        state.frame = h
        place(&state, slot: 5, col: 2, row: 2, type: 2, direction: .right)
        state.balloonsCaptureAllEnemies()
        XCTAssertEqual(state.balloons[0].state, 2)
        XCTAssertEqual(state.balloons[0].startFrame, h)
        XCTAssertEqual(state.enemies[5].state, 6)

        while state.frame < h + 140 {
            step(&state)
            XCTAssertTrue(state.balloons[0].visible, "frame \(state.frame)")
            XCTAssertEqual(state.balloons[0].state, 2, "frame \(state.frame)")
        }
        var expectVisible = true
        while state.frame < h + 170 {
            step(&state)
            expectVisible.toggle()
            XCTAssertEqual(state.balloons[0].visible, expectVisible, "frame \(state.frame)")
            XCTAssertEqual(state.balloons[0].state, 2, "frame \(state.frame)")
            XCTAssertEqual(state.enemies[5].state, 6, "frame \(state.frame)")
        }
        XCTAssertTrue(state.balloons[0].visible, "h+141…h+170 is an even number (30) of toggles")
        step(&state)                                       // h + 171
        XCTAssertEqual(state.frame, h + 171)
        XCTAssertTrue(state.balloons[0].visible)
        XCTAssertEqual(state.balloons[0].state, 3)
        XCTAssertEqual(state.balloons[0].startFrame, h + 171)
        XCTAssertEqual(state.balloons[0].spriteSet, 0x33)
        XCTAssertEqual(state.enemies[5].state, 1)
        XCTAssertEqual(state.enemies[5].stateStart, h + 171)
        XCTAssertEqual(state.enemies[5].spriteSet, 0x1c)
        for n in 1...3 {
            step(&state)
            XCTAssertFalse(state.balloons[0].dead, "pop step \(n)")
        }
        step(&state)
        XCTAssertTrue(state.balloons[0].dead)
        XCTAssertFalse(state.balloons[0].visible)
        XCTAssertEqual(state.balloons[0].state, 3, "freed only by the draw pass")
        XCTAssertEqual(state.numActiveBalloons, 1)
    }

    /// C5: `_Balloons_CheckSquishes` pops flying (state 1) balloons whose rect overlaps; a holding balloon under the
    /// same rect is untouched.
    func testCheckSquishesFlyingOnly() {
        var state = world()
        state.frame = 7
        place(&state, slot: 1, col: 3, row: 3, type: 1)
        state.balloonsCaptureAllEnemies()                  // balloon 0 holds slot 1 at (120, 120, 160, 160)
        place(&state, slot: 0, col: 2, row: 2, type: 3, direction: .right)
        state.balloonsNew(enemy: 0)                        // balloon 1 flies at (80, 100, 120, 140)
        XCTAssertEqual(state.balloons[1].rect, QDRect(top: 80, left: 100, bottom: 120, right: 140))
        let squish = QDRect(top: 100, left: 110, bottom: 140, right: 150)
        XCTAssertTrue(squish.collides(state.balloons[0].rect))
        XCTAssertTrue(squish.collides(state.balloons[1].rect))
        state.balloonsCheckSquishes(squish)
        XCTAssertEqual(state.balloons[1].state, 3)
        XCTAssertEqual(state.balloons[1].spriteSet, 0x33)
        XCTAssertEqual(state.balloons[0].state, 2)
        XCTAssertEqual(state.balloons[0].spriteSet, 0x32)
        XCTAssertEqual(state.enemies[1].state, 6)
    }

    /// Research note 40: `_Balloons_CaptureAllEnemies` gives every enemy in state 1/4/5 (slot order) a holding
    /// balloon in the first free slot with one `GetRandomFast(4,7)` each; an egg (state 2) is skipped.
    func testCaptureAllDraws() {
        var state = world()
        state.frame = 60
        place(&state, slot: 0, col: 1, row: 1, type: 1, enemyState: 1)
        place(&state, slot: 1, col: 2, row: 1, type: 2, enemyState: 2)      // egg
        place(&state, slot: 2, col: 3, row: 1, type: 3, enemyState: 4)
        place(&state, slot: 4, col: 4, row: 1, type: 4, enemyState: 5)
        state.balloonsCaptureAllEnemies()
        XCTAssertEqual(state.rng.drawCount, 3)
        XCTAssertEqual(state.numActiveBalloons, 3)
        for (slot, enemy) in [(0, 0), (1, 2), (2, 4)] {
            let b = state.balloons[slot]
            XCTAssertEqual(b.state, 2, "balloon \(slot)")
            XCTAssertEqual(b.holder, Int8(enemy), "balloon \(slot)")
            XCTAssertEqual(b.spriteSet, 0x32, "balloon \(slot)")
            XCTAssertEqual(b.frame, 1, "balloon \(slot)")
            XCTAssertEqual(b.startFrame, 60, "balloon \(slot)")
            XCTAssertTrue((4...7).contains(b.animPeriod), "balloon \(slot)")
            XCTAssertEqual(b.rect, state.enemies[enemy].rect, "balloon \(slot)")
            XCTAssertEqual(b.box, b.rect, "balloon \(slot)")
            XCTAssertEqual(b.direction, state.hero.facing, "balloon \(slot)")
            XCTAssertEqual(state.enemies[enemy].state, 6, "enemy \(enemy)")
            XCTAssertEqual(state.enemies[enemy].balloonIndex, Int8(slot), "enemy \(enemy)")
        }
        XCTAssertEqual(state.balloons[3].state, 0)
        XCTAssertEqual(state.enemies[1].state, 2, "the egg is not captured")
    }
}
