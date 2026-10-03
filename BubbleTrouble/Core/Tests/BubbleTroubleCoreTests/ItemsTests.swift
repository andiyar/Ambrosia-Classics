@testable import BubbleTroubleCore
import Foundation
import XCTest

/// Task 7b — items II: bonus bubbles, EXTRA, time bonus, regenerate
/// (docs/plans/2026-10-03-btx-core-and-film-harness.md §Task 7b; Invariants 7, 8, 9, 18; Research notes 41–45, 47;
/// B12).
///
/// Sources: `_Bonus_Process @ 0001a92b`, `_Multiplier_Process @ 00019dae`, `_Bonus_DoesHeroTouch @ 00019a13`,
/// `_Bonus_WasHit @ 0001a79a`, `_Bonus_Pop @ 0001a6fd`, `_Bonus_Reward @ 0001a2c5`, `_EXTRA_Change @ 0001a163`,
/// `_TimeBonus_Process @ 00006a15`, `_TimeBonus_Increase @ 000069cd`, `_Jewels_TurnToBlocks @ 0001c705`,
/// `_RegenerateBlocks @ 0001c3db`. All worlds are synthetic (`GameState.testWorld`, an all-empty maze → hero at
/// (7,6), rect (240, 280, 280, 320), state 2; time bonus 2500 at level 1; bonus slots unarmed — set up by hand).
final class ItemsTests: XCTestCase {

    /// Six regenerate candidates (`gMazeCopy` 10, `gMaze` 0) inside cols 1–14 × rows 1–9, none on the hero's row 6 or
    /// column 7; every other cell has `gMazeCopy` 0 (not a candidate).
    private static let candidates: [(col: Int, row: Int)] = [(2, 1), (9, 2), (14, 3), (1, 5), (4, 8), (12, 9)]

    private func world(level: Int = 1, maze: Maze? = nil) -> GameState {
        let maze = maze ?? (try! Maze(data: Data(count: Maze.byteCount)))
        return GameState.testWorld(maze: maze, level: level)
    }

    /// A world whose `gMazeCopy` holds exactly the six candidates.
    private func regenerateWorld(level: Int) -> GameState {
        var state = world(level: level)
        XCTAssertEqual(state.hero.col, 7)
        XCTAssertEqual(state.hero.row, 6)
        for c in Self.candidates { state.mazeCopy[c.col, c.row] = CellCode.normal }
        return state
    }

    /// An enemy of `type` in `enemyState`, aligned on (col, row), with its type's sprite set (0x1a + type).
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

    /// An armed bonus slot as `_Bonus_Init` leaves it (rise 2, snake 0, shell 1, icon set 0x1a).
    private func arm(_ state: inout GameState, slot: Int, type: Int16, left: Int16 = 100, top: Int16 = 0x1b8,
                     launch: UInt16 = 0, timeValue: Int16 = -1) {
        var b = BonusBubble()
        b.armed = true
        b.visible = true
        b.type = type
        b.rect = QDRect(top: top, left: left, bottom: top + 0x28, right: left + 0x28)
        b.prevRect = b.rect
        b.riseSpeed = 2
        b.snakeIndex = 0
        b.iconSet = 0x1a
        b.iconFrame = type
        b.shellFrame = 1
        b.timeValue = timeValue
        b.launchFrame = launch
        state.bonus[slot] = b
    }

    /// The cells of the 14 × 9 regenerate grid in walk order (row-major, cols 1…14, rows 1…9).
    private static func walkIndex(col: Int, row: Int) -> Int { (row - 1) * 14 + (col - 1) }

    /// An independent oracle for one regenerate walk from (col, row) when no candidate lies on the hero's row or column:
    /// the first remaining candidate strictly after the start in walk order, else (after the one wrap) the first one.
    private static func walkTarget(fromCol col: Int, row: Int, remaining: [(col: Int, row: Int)]) -> (col: Int, row: Int)? {
        let start = walkIndex(col: col, row: row)
        let ordered = remaining.sorted { walkIndex(col: $0.col, row: $0.row) < walkIndex(col: $1.col, row: $1.row) }
        return ordered.first { walkIndex(col: $0.col, row: $0.row) > start } ?? ordered.first
    }

    /// Research note 41: a slot launching at 578 (FILM-1-like) does not move through frame 578; at 579 it rises 2
    /// (top 438) and steps x by LUT[0] = +1 and drift entry 0 (4 → +2); at 580 LUT[1] = +1 and drift 1 (2 → −2). The
    /// shell frame advances every 3 frames (1 → 2 at 579, → 3 at 582, → 1 at 585). The top reaches 0 at 798 and goes
    /// negative at 799 — dead on that call (the slot stays armed for the draw pass). No draws.
    func testBonusLaunchRiseAndExit() {
        var state = world()
        arm(&state, slot: 0, type: 9, left: 100, launch: 578)
        state.bonusDrift = [4, 2] + Array(repeating: 0, count: 19)
        let start = state.bonus[0]
        while state.frame < 578 {
            state.frame &+= 1
            state.bonusProcess()
            XCTAssertEqual(state.bonus[0], start, "frame \(state.frame): no movement through the launch frame")
        }
        XCTAssertEqual(state.bonusDriftIndex, 0)

        state.frame = 579
        state.bonusProcess()
        XCTAssertEqual(state.bonus[0].rect, QDRect(top: 438, left: 103, bottom: 478, right: 143))
        XCTAssertEqual(state.bonus[0].snakeIndex, 1)
        XCTAssertEqual(state.bonusDriftIndex, 1)
        XCTAssertEqual(state.bonus[0].shellFrame, 2)
        XCTAssertEqual(state.bonus[0].animTimer, 579)

        let shellAt: [UInt16: Int16] = [580: 2, 581: 2, 582: 3, 583: 3, 584: 3, 585: 1]
        while state.frame < 798 {
            state.frame &+= 1
            state.bonusProcess()
            if state.frame == 580 {
                XCTAssertEqual(state.bonus[0].rect.left, 102)
            }
            if let shell = shellAt[state.frame] {
                XCTAssertEqual(state.bonus[0].shellFrame, shell, "frame \(state.frame)")
            }
            XCTAssertFalse(state.bonus[0].dead, "frame \(state.frame)")
        }
        XCTAssertEqual(state.bonus[0].rect.top, 0)
        XCTAssertEqual(state.bonus[0].rect.bottom, 40)
        // 220 calls: 11 full LUT cycles (net 0) + 11 more steps (+4 +0 −6 = −2); 10 drift cycles (net 0) + 10 entries
        // (+2 −2) → left 98.
        XCTAssertEqual(state.bonus[0].rect.left, 98)
        state.frame = 799
        state.bonusProcess()
        XCTAssertEqual(state.bonus[0].rect.top, -2)
        XCTAssertTrue(state.bonus[0].dead)
        XCTAssertTrue(state.bonus[0].armed, "freed only by the draw pass")
        XCTAssertFalse(state.bonus[0].popped)
        XCTAssertEqual(state.bonus[1].armed, false)
        XCTAssertEqual(state.rng.drawCount, 0)
    }

    /// B12 + Research note 41: `_Bonus_Reward` on a world at frame 500 (time bonus 2500).
    func testBonusRewardTable() {
        func rewarded(type: Int16, timeValue: Int16 = -1, level: Int = 1,
                      setup: (inout GameState) -> Void = { _ in }) -> GameState {
            var state = type == 2 ? regenerateWorld(level: level) : world(level: level)
            state.frame = 500
            XCTAssertEqual(state.timeBonus, 2500)
            arm(&state, slot: 0, type: type, left: 100, top: 200, timeValue: timeValue)
            setup(&state)
            state.bonusReward(0)
            return state
        }

        // 14: time bonus + value, flash, popup (sprite 10, delay 3) at the bubble's (left, top).
        var s = rewarded(type: 14, timeValue: 1000)
        XCTAssertEqual(s.timeBonus, 3500)
        XCTAssertTrue(s.timeBonusFlash)
        XCTAssertEqual(s.timeBonusFlashTimer, 500)
        XCTAssertEqual(s.points.activeCount, 1)
        XCTAssertEqual(s.points.slots[0].frame, 10)
        XCTAssertEqual(s.points.slots[0].delay, 3)
        XCTAssertEqual(s.points.slots[0].rect.left, 96)
        XCTAssertEqual(s.points.slots[0].rect.top, 208)
        XCTAssertEqual(s.rng.drawCount, 0)
        s = rewarded(type: 14, timeValue: 1000) { $0.timeBonus = 99500 }
        XCTAssertEqual(s.timeBonus, 99950, "cap 0x1866e")

        // 4: invisibility from now.
        s = rewarded(type: 4)
        XCTAssertTrue(s.hero.invisible)
        XCTAssertEqual(s.hero.invisibleStart, 500)

        // 9…13: EXTRA letters E, X, T, R, A — one each.
        for type in Int16(9)...13 {
            s = rewarded(type: type)
            var want = [false, false, false, false, false]
            want[Int(type) - 9] = true
            XCTAssertEqual(s.extraLetters, want, "type \(type)")
            XCTAssertFalse(s.extraAnimating, "type \(type)")
        }

        // 5…8 (unreachable after `_Bonus_Init`'s remap): `_Multiplier_Change(2…5)` (jump table 0x337f4).
        for type in Int16(5)...8 {
            s = rewarded(type: type)
            XCTAssertEqual(s.multiplier, type - 3, "type \(type)")
            XCTAssertTrue(s.multiplierAnimating, "type \(type)")
        }

        // 1: capture all — two state-1 enemies → 2 draws, 2 holding balloons.
        s = rewarded(type: 1) { state in
            self.place(&state, slot: 0, col: 2, row: 2)
            self.place(&state, slot: 3, col: 10, row: 4, type: 2)
        }
        XCTAssertEqual(s.rng.drawCount, 2)
        XCTAssertEqual(s.numActiveBalloons, 2)
        XCTAssertEqual(s.balloons[0].state, 2)
        XCTAssertEqual(s.balloons[1].state, 2)
        XCTAssertEqual(s.enemies[0].state, 6)
        XCTAssertEqual(s.enemies[3].state, 6)

        // 2: regenerate at level 1 — 12 draws (2 per attempt), the six candidates become blue, no enemy under.
        s = rewarded(type: 2)
        XCTAssertEqual(s.rng.drawCount, 12)
        for c in Self.candidates { XCTAssertEqual(s.maze[c.col, c.row], CellCode.blue, "\(c)") }
        XCTAssertEqual(s.score, 0)
    }

    /// Research note 42: the fifth letter (A, via type 13) → +1 life, +10000 ×mult, all enemies captured, letters
    /// cleared, the slot's icon becomes the type-14 one (0x1a / 0x15). Then the `_Bonus_Process` blink: one step per
    /// `timer + 5 < frame` (every 6 frames): steps 1/3/5/7/9 letters off, 2/4/6/8 on, step 10 stops the animation.
    func testExtraCompletion() {
        var state = world()
        state.frame = 300
        state.multiplier = 2
        state.nextExtraLifeScore = 40000              // keep the score-based extra life out of the count
        for k in 0..<4 { state.extraLetters[k] = true }
        place(&state, slot: 1, col: 3, row: 3)
        place(&state, slot: 5, col: 11, row: 2, type: 4)
        arm(&state, slot: 0, type: 13, left: 100, top: 200)
        state.bonusReward(0)
        XCTAssertEqual(state.lives, 4)
        XCTAssertEqual(state.score, 20000)
        XCTAssertEqual(state.extraLetters, [false, false, false, false, false])
        XCTAssertTrue(state.extraAnimating)
        XCTAssertEqual(state.extraTimer, 300)
        XCTAssertEqual(state.extraAnimCounter, 0)
        XCTAssertEqual(state.enemies[1].state, 6)
        XCTAssertEqual(state.enemies[5].state, 6)
        XCTAssertEqual(state.numActiveBalloons, 2)
        XCTAssertEqual(state.rng.drawCount, 2)
        XCTAssertEqual(state.bonus[0].type, 14)
        XCTAssertEqual(state.bonus[0].iconSet, 0x1a)
        XCTAssertEqual(state.bonus[0].iconFrame, 0x15)

        // While animating, a further letter does not complete again.
        state.extraChange(letter: 1, bonusSlot: 0)
        XCTAssertEqual(state.extraLetters, [true, false, false, false, false])
        state.extraLetters = [false, false, false, false, false]

        state.bonus[0].armed = false                  // isolate the blink from the slot loop
        var steps = 0
        while state.frame < 380 {
            state.frame &+= 1
            let before = state.extraAnimCounter
            let wasAnimating = state.extraAnimating
            state.bonusProcess()
            let stepped = wasAnimating && Int(state.frame) - 300 == 6 * (steps + 1)
            if stepped {
                steps += 1
                let on = steps % 2 == 0 && steps <= 8
                XCTAssertEqual(state.extraLetters, Array(repeating: on, count: 5), "step \(steps)")
                XCTAssertEqual(state.extraTimer, state.frame, "step \(steps)")
                XCTAssertEqual(state.extraAnimCounter, Int16(min(steps, 9)), "step \(steps)")
                XCTAssertEqual(state.extraAnimating, steps < 10, "step \(steps)")
            } else {
                XCTAssertEqual(state.extraAnimCounter, before, "frame \(state.frame)")
            }
        }
        XCTAssertEqual(steps, 10)
        XCTAssertEqual(state.extraLetters, [false, false, false, false, false])
        XCTAssertEqual(state.lives, 4)
    }

    /// Research note 44: 2500 at level 1; in state 2 from frame 71 with the timer at 70 → −50 at 101 (70 + 30 < 101)
    /// and again at 132; a state-3 frame re-arms the timer (no tick), so the next tick is 31 frames after it.
    func testTimeBonusTicks() {
        var state = world()
        XCTAssertEqual(state.timeBonus, 2500)
        state.timeBonusTimer = 70
        var ticks: [UInt16: Int32] = [:]
        state.frame = 70
        while state.frame < 140 {
            state.frame &+= 1
            let before = state.timeBonus
            state.timeBonusProcess()
            if state.timeBonus != before { ticks[state.frame] = state.timeBonus }
        }
        XCTAssertEqual(ticks, [101: 2450, 132: 2400])
        XCTAssertEqual(state.timeBonusTimer, 132)

        state.hero.state = 3
        state.frame = 140
        state.timeBonusProcess()
        XCTAssertEqual(state.timeBonus, 2400)
        XCTAssertEqual(state.timeBonusTimer, 140, "re-armed")
        state.hero.state = 2
        ticks = [:]
        while state.frame < 175 {
            state.frame &+= 1
            let before = state.timeBonus
            state.timeBonusProcess()
            if state.timeBonus != before { ticks[state.frame] = state.timeBonus }
        }
        XCTAssertEqual(ticks, [171: 2350])
        XCTAssertFalse(state.timeBonusFlash, "flash only below 500")

        // End of level freezes the bonus and the timer.
        state.isEndOfLevel = true
        state.frame = 400
        state.timeBonusProcess()
        XCTAssertEqual(state.timeBonus, 2350)
        XCTAssertEqual(state.timeBonusTimer, 171)
        XCTAssertEqual(state.rng.drawCount, 0)
    }

    /// Research note 44: the tick that reaches exactly 0 turns every jewel (20) and cluster (30) cell into a normal
    /// bubble (10) with a motion-0 star group each (no draws) and sets `gJewelsDone`; a tick that jumps past 0 (30 →
    /// −20) does not, and below 1 nothing ticks any more.
    func testTimeBonusZeroRevertsJewels() {
        var maze = try! Maze(data: Data(count: Maze.byteCount))
        maze[3, 2] = CellCode.jewel
        maze[4, 2] = CellCode.cluster
        maze[10, 8] = CellCode.cluster
        maze[5, 4] = CellCode.normal
        maze[6, 4] = CellCode.blue
        var state = world(maze: maze)
        state.timeBonus = 50
        state.timeBonusTimer = 0
        state.frame = 31
        state.timeBonusProcess()
        XCTAssertEqual(state.timeBonus, 0)
        XCTAssertTrue(state.jewelsDone)
        var want = maze
        want[3, 2] = CellCode.normal
        want[4, 2] = CellCode.normal
        want[10, 8] = CellCode.normal
        XCTAssertEqual(state.maze, want)
        XCTAssertEqual(state.stars.activeCount, 24)
        XCTAssertEqual(state.rng.drawCount, 0)

        var past = world(maze: maze)
        past.timeBonus = 30
        past.frame = 31
        past.timeBonusProcess()
        XCTAssertEqual(past.timeBonus, -20)
        XCTAssertFalse(past.jewelsDone)
        XCTAssertEqual(past.maze, maze)
        past.frame = 200
        past.timeBonusProcess()
        XCTAssertEqual(past.timeBonus, -20)
        XCTAssertEqual(past.timeBonusTimer, 31, "below 1 the timer is not touched")
    }

    /// B12 + Research note 45 on six synthetic candidates: level 10 → all six blue, 12 draws, no stars; level 11 → each
    /// cell blue/purple by its attempt's `(0,1)` (0 → 16, 1 → 15; cell per an independent walk oracle), 18 draws;
    /// level 10 with a state-1 piranha on a candidate → squished n = 1 (+200) with its group-3 stars (4 draws,
    /// interior cell) → 16 draws; the maze outcome of `_SquishEnemy` clearing the **enemy's** cell, aligned and
    /// half a cell off (hand-derived below from the seed-1 draws).
    func testRegenerateBlocks() {
        var state = regenerateWorld(level: 10)
        var want = state.maze
        for c in Self.candidates { want[c.col, c.row] = CellCode.blue }
        state.regenerateBlocks()
        XCTAssertEqual(state.maze, want)
        XCTAssertEqual(state.rng.drawCount, 12)
        XCTAssertEqual(state.stars.activeCount, 0)
        XCTAssertEqual(state.score, 0)

        state = regenerateWorld(level: 11)
        var probe = state.rng
        var remaining = Self.candidates
        want = state.maze
        for _ in 0..<6 {
            let col = probe.fast(1, 0xe), row = probe.fast(1, 9)
            guard let target = Self.walkTarget(fromCol: col, row: row, remaining: remaining) else {
                XCTFail("six attempts, six candidates")
                return
            }
            remaining.removeAll { $0 == target }
            want[target.col, target.row] = probe.fast(0, 1) == 0 ? CellCode.purple : CellCode.blue
        }
        XCTAssertTrue(remaining.isEmpty)
        state.regenerateBlocks()
        XCTAssertEqual(state.maze, want)
        XCTAssertEqual(state.rng.drawCount, 18)
        XCTAssertEqual(probe.drawCount, 18)
        XCTAssertEqual(state.stars.activeCount, 0)

        // Seed-1 attempt pairs (col, row) = (GetRandomFast(1,14), GetRandomFast(1,9)) from raw draws 1–10:
        // (4,3) → (14,3); (10,1) → (9,2); (11,8) → (12,9); (8,1) → (1,5); (3,1) → (4,8) (the piranha's cell).
        // That 5th attempt's squish spends draws 11–14 on stars, so attempt 6 reads draws 15–16 = (12,2).
        state = regenerateWorld(level: 10)
        place(&state, slot: 2, col: 4, row: 8)
        state.regenerateBlocks()
        XCTAssertTrue(state.enemies[2].dead)
        XCTAssertEqual(state.numEnemiesSquished, 1)
        XCTAssertEqual(state.score, 200)
        XCTAssertEqual(state.stars.activeCount, 4)
        XCTAssertEqual(state.rng.drawCount, 16)
        // Aligned: the squish zeroes the piranha's cell (4,8) — the bubble just placed — so (4,8) is a candidate
        // again; attempt 6 from (12,2) walks to (4,8) before wrapping to (2,1), re-places it, and the dead piranha
        // handed out again is ignored (one squish). Six placements, five bubbles: (2,1) stays empty.
        want = regenerateWorld(level: 10).maze
        for c in [(14, 3), (9, 2), (12, 9), (1, 5), (4, 8)] { want[c.0, c.1] = CellCode.blue }
        XCTAssertEqual(state.maze, want)
        XCTAssertEqual(state.maze[2, 1], CellCode.empty, "the clear sent attempt 6 back to (4,8), not on to (2,1)")

        // Half a cell off: piranha rect left 4·40 + 20 = 180 (cols 4–5), its col/row bytes on (5,8). It overlaps
        // (4,8)'s inset-3 rect (163…197), so the 5th attempt still squishes it (+200, 4 star draws), but the clear
        // hits its own cell (5,8) — a sentinel there (gMazeCopy 0: never a candidate) makes the write visible — and
        // the new bubble at (4,8) survives; attempt 6 from (12,2) then wraps to (2,1). Six bubbles, all placed.
        state = regenerateWorld(level: 10)
        place(&state, slot: 2, col: 5, row: 8)
        state.enemies[2].rect = QDRect(top: 320, left: 180, bottom: 360, right: 220)
        state.enemies[2].prevRect = state.enemies[2].rect
        state.enemies[2].aligned = false
        state.maze[5, 8] = CellCode.normal
        state.regenerateBlocks()
        XCTAssertTrue(state.enemies[2].dead)
        XCTAssertEqual(state.numEnemiesSquished, 1)
        XCTAssertEqual(state.score, 200)
        XCTAssertEqual(state.rng.drawCount, 16)
        want = regenerateWorld(level: 10).maze
        for c in Self.candidates { want[c.col, c.row] = CellCode.blue }
        XCTAssertEqual(state.maze, want, "(5,8) cleared to 0; (4,8) keeps its bubble (15)")
        XCTAssertEqual(state.maze[4, 8], CellCode.blue)
        XCTAssertEqual(state.maze[5, 8], CellCode.empty)
    }
}
