@testable import BubbleTroubleCore
import Foundation
import XCTest

/// Task 5a — shared primitives I: maze and jewel queries, scoring, catches
/// (docs/plans/2026-10-03-btx-core-and-film-harness.md §Task 5a; Research notes 27, 28, 43; INDEX C1, C8; B1, B6).
///
/// Sources: `_Bonus_SetNumEnemySquishes @ 0001a818`, `_Multiplier_Change @ 00019ceb`, `_AddToScore @ 000280dd`,
/// `_AddHero @ 00022d62`, `_IsHeroCaught @ 00021c79`, `_HeroCaught @ 00021dfa`, `_StopAllEnemies @ 000110c8`,
/// `_IsTargetJewelFound @ 0001c9b9`, `_IsJewelTheTarget @ 0001c8fb`, `_IsJewelTheDistantTarget @ 0001c95a`.
/// All worlds are synthetic (`GameState.testWorld`, an all-empty maze → hero at (7,6), rect (240, 280, 280, 320)).
final class PrimitivesTests: XCTestCase {

    private func world(level: Int = 1) -> GameState {
        let maze = try! Maze(data: Data(count: Maze.byteCount))
        return GameState.testWorld(maze: maze, level: level)
    }

    /// Research note 43 + C8: n = 3: 1→2, 2→3, 3→4, 4→5; n = 4: 1,2→3, 3→4, 4→5; n = 5: 1…3→4, 4→5; n ≥ 6: 1…4→5;
    /// at 5 the award is `_AddToScore(2000 / 4000, 1)` (×5) plus `_NewPoint(hero.left, hero.top, 0xc / 0xe, 0)` and
    /// the multiplier stays 5; n < 3 → no change.
    func testMultiplierStepTable() {
        let table: [Int: [Int16: Int16]] = [
            3: [1: 2, 2: 3, 3: 4, 4: 5],
            4: [1: 3, 2: 3, 3: 4, 4: 5],
            5: [1: 4, 2: 4, 3: 4, 4: 5],
            6: [1: 5, 2: 5, 3: 5, 4: 5],
            7: [1: 5, 2: 5, 3: 5, 4: 5],
        ]
        for (n, steps) in table {
            for (from, to) in steps {
                var state = world()
                state.frame = 77
                state.multiplier = from
                state.bonusSetNumEnemySquishes(n)
                XCTAssertEqual(state.multiplier, to, "n \(n) from \(from)")
                XCTAssertTrue(state.multiplierAnimating, "n \(n) from \(from)")
                XCTAssertEqual(state.multiplierTimer, 77, "n \(n) from \(from)")
                XCTAssertEqual(state.multiplierAnimCounter, 0, "n \(n) from \(from)")
                XCTAssertEqual(state.score, 0, "n \(n) from \(from)")
                XCTAssertEqual(state.points.activeCount, 0, "n \(n) from \(from)")
                XCTAssertEqual(state.bonusSquishedAtOnce, 0, "n \(n) from \(from)")
            }
            // At 5: the award, ×5, no multiplier change.
            for (level, award, sprite) in [(8, Int32(10000), Int16(0xc)), (9, Int32(20000), Int16(0xe))] {
                var state = world(level: level)
                state.multiplier = 5
                state.bonusSetNumEnemySquishes(n)
                XCTAssertEqual(state.multiplier, 5, "n \(n) level \(level)")
                XCTAssertFalse(state.multiplierAnimating, "n \(n) level \(level)")
                XCTAssertEqual(state.score, award, "n \(n) level \(level)")
                XCTAssertEqual(state.points.activeCount, 1, "n \(n) level \(level)")
                XCTAssertEqual(state.points.slots[0].frame, sprite, "n \(n) level \(level)")
                // _NewPoint(hero.left = 280, hero.top = 240): x − 4, rect (y + 8, x, y + 36, x + 48).
                XCTAssertEqual(state.points.slots[0].rect, QDRect(top: 248, left: 276, bottom: 276, right: 324))
                XCTAssertEqual(state.bonusSquishedAtOnce, 0)
            }
        }
        // C8: n = 0, 1, 2 → no change at any multiplier (and no award at 5).
        for n in 0...2 {
            for from in Int16(1)...5 {
                var state = world()
                state.multiplier = from
                state.bonusSquishedAtOnce = 9
                state.bonusSetNumEnemySquishes(n)
                XCTAssertEqual(state.multiplier, from, "n \(n) from \(from)")
                XCTAssertFalse(state.multiplierAnimating)
                XCTAssertEqual(state.score, 0)
                XCTAssertEqual(state.points.activeCount, 0)
                XCTAssertEqual(state.bonusSquishedAtOnce, 0)
            }
        }
        XCTAssertEqual(world().rng.drawCount, 0)
    }

    /// Research note 28: one life when `score >= next`; next = 40000 if below it, else +40000 — one life per call.
    func testAddToScoreExtraLives() {
        var state = world()
        XCTAssertEqual(state.lives, 3)
        state.addToScore(9999, multiply: false)
        XCTAssertEqual(state.lives, 3)
        XCTAssertEqual(state.nextExtraLifeScore, 10000)
        state.addToScore(1, multiply: false)
        XCTAssertEqual(state.score, 10000)
        XCTAssertEqual(state.lives, 4)
        XCTAssertEqual(state.nextExtraLifeScore, 40000)
        state.addToScore(29999, multiply: false)
        XCTAssertEqual(state.lives, 4)
        state.addToScore(1, multiply: false)
        XCTAssertEqual(state.lives, 5)
        XCTAssertEqual(state.nextExtraLifeScore, 80000)
        state.multiplier = 4
        state.addToScore(10000, multiply: true)          // 4 × 10000 → 80000
        XCTAssertEqual(state.score, 80000)
        XCTAssertEqual(state.lives, 6)
        XCTAssertEqual(state.nextExtraLifeScore, 120000)

        // A single +100000 from 0 gives exactly one life.
        var big = world()
        big.addToScore(100000, multiply: false)
        XCTAssertEqual(big.score, 100000)
        XCTAssertEqual(big.lives, 4)
        XCTAssertEqual(big.nextExtraLifeScore, 40000)

        // `_AddHero` caps at 9.
        var capped = world()
        capped.lives = 9
        capped.addToScore(10000, multiply: false)
        XCTAssertEqual(capped.lives, 9)
        XCTAssertEqual(capped.nextExtraLifeScore, 40000)
        XCTAssertEqual(capped.rng.drawCount, 0)
    }

    /// Research note 27: the enemy-body test `_IsHeroCaught(rect, 1, 1)` insets the enemy rect by 11 and the hero rect
    /// by 8; `_RectsCollide` is strict ⇒ same row, |dx| ≤ 20 caught, 21 not. Invisible + protect → never caught.
    func testHeroCatchInsetBoundary() {
        var state = world()
        XCTAssertEqual(state.hero.rect, QDRect(top: 240, left: 280, bottom: 280, right: 320))
        let base = state.hero.rect
        func enemy(_ dx: Int16) -> QDRect {
            var r = base
            r.offset(dx: dx, dy: 0)
            return r
        }
        for dx: Int16 in [0, 20, -20] {
            XCTAssertTrue(state.isHeroCaught(enemy(dx), protectInvisible: true, bigInset: true), "dx \(dx)")
        }
        for dx: Int16 in [21, -21] {
            XCTAssertFalse(state.isHeroCaught(enemy(dx), protectInvisible: true, bigInset: true), "dx \(dx)")
        }
        // Small inset (4, hero not inset): 40 − 4 = 36 → caught at 35, not at 36.
        XCTAssertTrue(state.isHeroCaught(enemy(35), protectInvisible: true, bigInset: false))
        XCTAssertFalse(state.isHeroCaught(enemy(36), protectInvisible: true, bigInset: false))

        // Invisible hero, protect = 1: never caught; protect = 0: caught.
        state.setHeroInvisibility(true)
        XCTAssertTrue(state.hero.invisible)
        for dx: Int16 in [0, 20, -20] {
            XCTAssertFalse(state.isHeroCaught(enemy(dx), protectInvisible: true, bigInset: true), "dx \(dx)")
            XCTAssertFalse(state.isHeroCaught(enemy(dx), protectInvisible: true, bigInset: false), "dx \(dx)")
        }
        XCTAssertTrue(state.isHeroCaught(enemy(0), protectInvisible: false, bigInset: true))

        // Only in hero state 2.
        state.setHeroInvisibility(false)
        state.hero.state = 3
        XCTAssertFalse(state.isHeroCaught(enemy(0), protectInvisible: false, bigInset: false))
        XCTAssertEqual(state.rng.drawCount, 0)
    }

    /// Research note 27 + B6 + C2: `_HeroCaught(2)` sets state 3 first, stateStart = frame, `_StopAllEnemies`
    /// (states 1,2,3,4,6 → 5), one `(0,1)` draw, a hero splat (kind 1) at hero left/top, star group 0xe at
    /// (col·40, row·40) = (280, 240) — 14 hop stars, none clipped → 14 draws — and `+0x4a` visible = 0 only.
    func testHeroCaughtKind2() {
        var state = world()
        XCTAssertEqual(state.hero.col, 7)
        XCTAssertEqual(state.hero.row, 6)
        state.frame = 321
        state.hero.invisible = true
        state.hero.invisibleStart = 300
        for s in UInt8(0)...6 {
            state.enemies[Int(s)].state = s
            state.enemies[Int(s)].stateStart = 11
        }
        XCTAssertEqual(state.rng.drawCount, 0)

        state.heroCaught(kind: 2)

        XCTAssertEqual(state.hero.state, 3)
        XCTAssertEqual(state.hero.stateStart, 321)
        XCTAssertTrue(state.heroCaughtThisFrame)
        for s in UInt8(0)...6 {
            let e = state.enemies[Int(s)]
            if [1, 2, 3, 4, 6].contains(s) {
                XCTAssertEqual(e.state, 5, "state \(s)")
                XCTAssertEqual(e.stateStart, 321, "state \(s)")
            } else {
                XCTAssertEqual(e.state, s, "state \(s)")
                XCTAssertEqual(e.stateStart, 11, "state \(s)")
            }
        }
        for i in 7..<GameState.enemyCapacity { XCTAssertEqual(state.enemies[i].state, 0) }
        let splats = state.splats.slots.filter(\.active)
        XCTAssertEqual(splats.count, 1)
        XCTAssertEqual(splats[0].kind, 1)
        XCTAssertEqual(splats[0].rect, QDRect(top: 240, left: 280, bottom: 280, right: 320))
        XCTAssertFalse(state.hero.visible)
        XCTAssertTrue(state.hero.invisible)
        XCTAssertEqual(state.hero.invisibleStart, 300)
        XCTAssertEqual(state.stars.activeCount, 14)
        XCTAssertTrue(state.stars.slots[0..<14].allSatisfy { $0.active && $0.motion == 0xb })
        XCTAssertEqual(state.stars.slots[0].rect.left, 280 - 8)
        XCTAssertEqual(state.stars.slots[0].rect.top, 240 - 8)
        XCTAssertEqual(state.rng.drawCount, 1 + 14)
    }

    /// B1: both target queries are false unless `gJewelFound`; they step one (resp. two) cells in `dir` (`char`
    /// arithmetic) and compare to the target jewel.
    func testJewelTargetHelpers() {
        var state = world()
        state.targetJewel = CellRef(col: 5, row: 5)
        state.jewelFound = false
        XCTAssertFalse(state.isTargetJewelFound())
        XCTAssertFalse(state.isJewelTheTarget(.right, col: 4, row: 5))
        XCTAssertFalse(state.isJewelTheDistantTarget(.right, col: 3, row: 5))

        state.jewelFound = true
        XCTAssertTrue(state.isTargetJewelFound())
        XCTAssertTrue(state.isJewelTheTarget(.right, col: 4, row: 5))
        XCTAssertFalse(state.isJewelTheDistantTarget(.right, col: 4, row: 5))
        XCTAssertTrue(state.isJewelTheDistantTarget(.right, col: 3, row: 5))
        XCTAssertFalse(state.isJewelTheTarget(.right, col: 3, row: 5))
        XCTAssertTrue(state.isJewelTheDistantTarget(.up, col: 5, row: 7))
        XCTAssertFalse(state.isJewelTheTarget(.up, col: 5, row: 4))
        XCTAssertFalse(state.isJewelTheDistantTarget(.up, col: 5, row: 4))
        // The other two directions, for completeness.
        XCTAssertTrue(state.isJewelTheTarget(.left, col: 6, row: 5))
        XCTAssertTrue(state.isJewelTheTarget(.down, col: 5, row: 4))
        XCTAssertTrue(state.isJewelTheDistantTarget(.left, col: 7, row: 5))
        XCTAssertTrue(state.isJewelTheDistantTarget(.down, col: 5, row: 3))
        XCTAssertEqual(state.rng.drawCount, 0)
    }
}
