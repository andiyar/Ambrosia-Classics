@testable import BubbleTroubleCore
import Foundation
import XCTest

/// Task 6 — hero: input, movement, push/pop, death animation
/// (docs/plans/2026-10-03-btx-core-and-film-harness.md §Task 6; Invariant 5; Research notes 5, 23–26).
///
/// Sources: `_ProcessHero @ 00022de0`, `_CheckHeroMovement @ 00021f49`, `_MoveHeroAligned @ 00022847`,
/// `_MoveHeroNotAligned @ 000224c8`, `_HeroPushCrushCheck @ 000220d8`, `_SetHeroInvisibility @ 00021bee`.
/// All worlds are synthetic (`GameState.testWorld`, an all-empty maze → hero at (7,6), facing left, hero state 2
/// unless stated; `ScriptedInput` supplies the samples).
final class HeroTests: XCTestCase {

    private static let none = FilmSample(up: false, down: false, left: false, right: false, push: false)

    private static func held(up: Bool = false, down: Bool = false, left: Bool = false, right: Bool = false,
                             push: Bool = false) -> FilmSample {
        FilmSample(up: up, down: down, left: left, right: right, push: push)
    }

    private func world(level: Int = 1, heroState: Int16 = 2) -> GameState {
        let maze = try! Maze(data: Data(count: Maze.byteCount))
        return GameState.testWorld(maze: maze, level: level, heroState: heroState)
    }

    private func input(_ sample: FilmSample, count: Int = 400) -> ScriptedInput {
        ScriptedInput(samples: Array(repeating: sample, count: count))
    }

    private func moveHero(_ state: inout GameState, col: Int, row: Int) {
        state.hero.col = Int8(col)
        state.hero.row = Int8(row)
        state.hero.rect = QDRect.cell(col: col, row: row)
    }

    /// Invariant 5: `_ProcessHero` returns before `_CheckHeroMovement` in states 1, 3 and 4 (no sample); in state 2
    /// (not frozen, not trapped) each call consumes exactly one.
    func testSampleConsumptionByState() {
        for heroState: Int16 in [1, 3, 4] {
            var state = world(heroState: heroState)
            var source = input(Self.none)
            for _ in 0..<10 { state.processHero(input: &source) }
            XCTAssertEqual(source.samplesConsumed, 0, "state \(heroState)")
            XCTAssertEqual(state.hero.state, heroState, "state \(heroState)")
        }
        var state = world()
        var source = input(Self.none)
        for call in 1...10 {
            state.processHero(input: &source)
            XCTAssertEqual(source.samplesConsumed, call)
        }
        XCTAssertEqual(state.rng.drawCount, 0)
    }

    /// Research note 23: a push (result 1, duration 2) freezes the push call + 3 calls (counter 1, 2 ≤ 2; 3 ends it
    /// without moving); a pop (result 2, duration 5) the pop call + 6 calls.
    func testPushFreezeDurations() {
        // Push: a bubble at (6,6), empty beyond.
        var state = world()
        state.maze[6, 6] = CellCode.normal
        var source = input(Self.held(push: true))
        state.processHero(input: &source)
        XCTAssertEqual(source.samplesConsumed, 1)
        XCTAssertTrue(state.hero.frozen)
        XCTAssertEqual(state.hero.freezeDuration, 2)
        XCTAssertEqual(state.hero.spriteSet, 6)
        XCTAssertEqual(state.hero.spriteFrame, Int16(Direction.left.rawValue))
        for call in 2...4 {
            state.processHero(input: &source)
            XCTAssertEqual(source.samplesConsumed, 1, "push call \(call)")
        }
        XCTAssertFalse(state.hero.frozen)
        XCTAssertEqual(state.hero.spriteSet, 4)      // walking-left sprite restored
        XCTAssertEqual(state.hero.spriteFrame, 1)
        state.processHero(input: &source)
        XCTAssertEqual(source.samplesConsumed, 2, "push call 5")

        // Pop: a bubble at (6,6) with a bubble beyond.
        state = world()
        state.maze[6, 6] = CellCode.normal
        state.maze[5, 6] = CellCode.normal
        source = input(Self.held(push: true))
        state.processHero(input: &source)
        XCTAssertEqual(source.samplesConsumed, 1)
        XCTAssertEqual(state.hero.freezeDuration, 5)
        for call in 2...7 {
            state.processHero(input: &source)
            XCTAssertEqual(source.samplesConsumed, 1, "pop call \(call)")
        }
        XCTAssertFalse(state.hero.frozen)
        state.processHero(input: &source)
        XCTAssertEqual(source.samplesConsumed, 2, "pop call 8")
    }

    /// Invariant 5 / `replay-oracle.md` §2: trapped at f0, calls at f0+1…f0+90 return early; f0+91 clears the trap and
    /// returns (no sample); f0+92 samples again.
    func testTrapReleaseFrameConsumesNone() {
        var state = world()
        let f0: UInt16 = 100
        state.hero.trapped = true
        state.hero.trapStart = f0
        var source = input(Self.none)
        for f in (f0 + 1)...(f0 + 90) {
            state.frame = f
            state.processHero(input: &source)
            XCTAssertEqual(source.samplesConsumed, 0, "frame \(f)")
            XCTAssertTrue(state.hero.trapped, "frame \(f)")
        }
        state.frame = f0 + 91
        state.processHero(input: &source)
        XCTAssertFalse(state.hero.trapped)
        XCTAssertEqual(source.samplesConsumed, 0, "release frame")
        state.frame = f0 + 92
        state.processHero(input: &source)
        XCTAssertEqual(source.samplesConsumed, 1)
    }

    /// Research note 25: aligned, the if/else chain gives Up > Down > Left > Right; facing, sprite set and frame 1
    /// follow, and the hero steps 5 px that way.
    func testDirectionPriorityAligned() {
        let cases: [(FilmSample, Direction, Int16, Int16, Int16)] = [
            (Self.held(up: true, left: true), .up, 2, 0, -5),
            (Self.held(down: true, right: true), .down, 3, 0, 5),
            (Self.held(left: true, right: true), .left, 4, -5, 0),
        ]
        for (sample, dir, sprite, dx, dy) in cases {
            var state = world()
            var source = input(sample)
            state.processHero(input: &source)
            XCTAssertEqual(state.hero.facing, dir)
            XCTAssertEqual(state.hero.spriteSet, sprite, "\(dir)")
            XCTAssertEqual(state.hero.spriteFrame, 1, "\(dir)")
            XCTAssertEqual(state.hero.xOffset, dx, "\(dir)")
            XCTAssertEqual(state.hero.yOffset, dy, "\(dir)")
            XCTAssertFalse(state.hero.aligned, "\(dir)")
            XCTAssertEqual(state.hero.rect, QDRect(top: 240 + dy, left: 280 + dx, bottom: 280 + dy, right: 320 + dx))
        }
    }

    /// Research note 25: between cells the hero keeps his direction; only the exact opposite key reverses, at once
    /// (walk frame −1 on that call, +1 otherwise).
    func testReversalBetweenCells() {
        var state = world()
        var source = ScriptedInput(samples: Array(repeating: Self.held(left: true), count: 3)
                                   + [Self.held(up: true), Self.held(right: true)])
        for _ in 0..<3 { state.processHero(input: &source) }
        XCTAssertEqual(state.hero.xOffset, -15)
        XCTAssertEqual(state.hero.spriteFrame, 3)
        state.processHero(input: &source)            // Up: ignored mid-cell
        XCTAssertEqual(state.hero.facing, .left)
        XCTAssertEqual(state.hero.xOffset, -20)
        XCTAssertEqual(state.hero.yOffset, 0)
        XCTAssertEqual(state.hero.spriteFrame, 4)
        state.processHero(input: &source)            // Right: reverses this call
        XCTAssertEqual(state.hero.facing, .right)
        XCTAssertEqual(state.hero.spriteSet, 5)
        XCTAssertEqual(state.hero.xOffset, -15)
        XCTAssertEqual(state.hero.spriteFrame, 3)
        XCTAssertEqual(source.samplesConsumed, 5)
    }

    /// Research note 25: speed 5 → 8 calls per 40-px cell; the 8th call steps the column and re-aligns.
    func testEightFramesPerCell() {
        var state = world()
        var source = input(Self.held(left: true))
        for call in 1...7 {
            state.processHero(input: &source)
            XCTAssertFalse(state.hero.aligned, "call \(call)")
            XCTAssertEqual(state.hero.col, 7, "call \(call)")
        }
        state.processHero(input: &source)
        XCTAssertTrue(state.hero.aligned)
        XCTAssertEqual(state.hero.col, 6)
        XCTAssertEqual(state.hero.row, 6)
        XCTAssertEqual(state.hero.xOffset, 0)
        XCTAssertEqual(state.hero.rect, QDRect.cell(col: 6, row: 6))
        XCTAssertEqual(state.hero.spriteFrame, 8)
    }

    /// `hero-and-input.md` §4 bubble rows: empty (or 'P') beyond → `_PushBlock` (moving block in the adjacent cell,
    /// maze cell 0), return 1; anything 10…60 or the off-grid wall beyond → `_CrushBlock` (+1 point), return 2.
    func testPushTableBubble() {
        for type in [CellCode.normal, CellCode.blue, CellCode.purple] {
            for beyond in [CellCode.empty, CellCode.passableP] {
                var state = world()
                state.maze[6, 6] = type
                state.maze[5, 6] = beyond
                XCTAssertEqual(state.heroPushCrushCheck(), 1, "type \(type) beyond \(beyond)")
                XCTAssertEqual(state.maze[6, 6], 0)
                XCTAssertEqual(state.blocks[0].state, 1)
                XCTAssertTrue(state.blocks[0].moving)
                XCTAssertEqual(state.blocks[0].type, type)
                XCTAssertEqual(state.blocks[0].direction, .left)
                XCTAssertEqual(state.blocks[0].col, 6)
                XCTAssertEqual(state.score, 0)
            }
            // A bubble beyond → pop.
            var state = world()
            state.maze[6, 6] = type
            state.maze[5, 6] = CellCode.normal
            XCTAssertEqual(state.heroPushCrushCheck(), 2, "type \(type) blocked")
            XCTAssertEqual(state.maze[6, 6], CellCode.popping)
            XCTAssertEqual(state.blocks[0].type, CellCode.popping)
            XCTAssertEqual(state.blocks[0].state, 2)
            XCTAssertEqual(state.score, 1)
            // The grid edge beyond (hero at (1,6) facing left → distant = wall 50) → pop.
            state = world()
            moveHero(&state, col: 1, row: 6)
            state.maze[0, 6] = type
            XCTAssertEqual(state.heroPushCrushCheck(), 2, "type \(type) edge")
            XCTAssertEqual(state.maze[0, 6], CellCode.popping)
            XCTAssertEqual(state.blocks[0].col, 0)
        }
    }

    /// `hero-and-input.md` §4 jewel rows: no jewel joined yet → push into empty or into a jewel, thud otherwise;
    /// a target exists → the target itself thuds, another jewel pushes into empty or onto the target; a cluster
    /// or the wall thuds. Every thud returns 1 with no block.
    func testPushTableJewels() {
        func check(_ beyond: UInt8, found: CellRef? = nil, pushes: Bool, _ msg: String) {
            var state = world()
            if let found {
                state.jewelFound = true
                state.targetJewel = found
            }
            state.maze[6, 6] = CellCode.jewel
            state.maze[5, 6] = beyond
            XCTAssertEqual(state.heroPushCrushCheck(), 1, msg)
            if pushes {
                XCTAssertEqual(state.blocks[0].state, 1, msg)
                XCTAssertEqual(state.blocks[0].type, CellCode.jewel, msg)
                XCTAssertEqual(state.maze[6, 6], 0, msg)
                XCTAssertEqual(state.numActiveBlocks, 1, msg)
            } else {
                XCTAssertEqual(state.numActiveBlocks, 0, msg)
                XCTAssertEqual(state.maze[6, 6], CellCode.jewel, msg)
            }
        }
        check(CellCode.empty, pushes: true, "no join, empty")
        check(CellCode.jewel, pushes: true, "no join, jewel")
        check(CellCode.normal, pushes: false, "no join, bubble")
        check(CellCode.cluster, pushes: false, "no join, cluster")
        let near = CellRef(col: 6, row: 6), far = CellRef(col: 5, row: 6), elsewhere = CellRef(col: 1, row: 1)
        check(CellCode.empty, found: near, pushes: false, "the target itself")
        check(CellCode.empty, found: elsewhere, pushes: true, "target elsewhere, empty")
        check(CellCode.cluster, found: far, pushes: true, "onto the target cluster")
        check(CellCode.jewel, found: elsewhere, pushes: false, "jewel not the target")

        var state = world()
        state.maze[6, 6] = CellCode.cluster
        XCTAssertEqual(state.heroPushCrushCheck(), 1, "cluster")
        XCTAssertEqual(state.numActiveBlocks, 0)
        state = world()
        moveHero(&state, col: 0, row: 6)
        XCTAssertEqual(state.heroPushCrushCheck(), 1, "wall")
        XCTAssertEqual(state.numActiveBlocks, 0)
        state = world()
        XCTAssertEqual(state.heroPushCrushCheck(), 0, "empty")
        XCTAssertEqual(state.rng.drawCount, 0)
    }

    /// `hero-and-input.md` §4: an egg → `_KillEggBlock`, return 2; free dynamite slides (return 1); blocked dynamite
    /// → `_CrushBlock` + `_ActivateBombBlock` (a static lit fuse), return 2; already-lit dynamite free to slide → 0.
    func testPushTableEggAndDynamite() {
        var state = world()
        state.enemies[0].type = 1
        state.enemies[0].spriteSet = 0x1b
        state.enemies[0].state = 2
        state.newBlock(col: 6, row: 6, direction: nil, type: CellCode.egg, enemy: 0, moving: false)
        state.maze[6, 6] = CellCode.egg
        XCTAssertEqual(state.heroPushCrushCheck(), 2, "egg")
        XCTAssertEqual(state.blocks[0].type, CellCode.popping)
        XCTAssertEqual(state.blocks[0].state, 2)
        XCTAssertEqual(state.maze[6, 6], CellCode.popping)
        XCTAssertEqual(state.score, 50)
        XCTAssertTrue(state.enemies[0].dead)

        state = world()
        state.maze[6, 6] = CellCode.dynamite
        XCTAssertEqual(state.heroPushCrushCheck(), 1, "free dynamite")
        XCTAssertEqual(state.blocks[0].type, CellCode.dynamite)
        XCTAssertEqual(state.blocks[0].state, 1)
        XCTAssertTrue(state.blocks[0].moving)
        XCTAssertEqual(state.maze[6, 6], 0)

        state = world()
        state.maze[6, 6] = CellCode.dynamite
        state.maze[5, 6] = CellCode.normal
        XCTAssertEqual(state.heroPushCrushCheck(), 2, "blocked dynamite")
        XCTAssertEqual(state.maze[6, 6], CellCode.dynamite)          // crush leaves a dynamite cell
        XCTAssertEqual(state.blocks[0].type, CellCode.popping)
        XCTAssertEqual(state.blocks[1].type, CellCode.dynamite)
        XCTAssertEqual(state.blocks[1].state, 3)                       // static lit fuse
        XCTAssertFalse(state.blocks[1].moving)
        XCTAssertEqual(state.score, 1)

        state = world()
        state.maze[6, 6] = CellCode.dynamite
        state.newBlock(col: 6, row: 6, direction: nil, type: CellCode.dynamite, enemy: -1, moving: false)
        XCTAssertEqual(state.heroPushCrushCheck(), 0, "lit dynamite, free to slide")
        XCTAssertEqual(state.numActiveBlocks, 1)
        XCTAssertEqual(state.maze[6, 6], CellCode.dynamite)
        XCTAssertEqual(state.rng.drawCount, 0)
    }

    /// Research note 23: in state 4 the frame steps every 2nd call from 1; the 32nd call takes it past 16 and, for a
    /// visible hero (`+0x4a`) that has not emitted them, launches air-bubble group 0xb at (left, top) — 5
    /// `_Bubbles_New` anim-period draws on an empty pool — once. A hero with `visible == false` (as `heroCaught(kind:
    /// 2)` leaves it) emits nothing; the invisibility bonus `+0x50` does not gate it.
    func testDeathAnimationBubblesOnce() {
        func dying(visible: Bool, invisible: Bool) -> GameState {
            var state = world(heroState: 4)
            state.hero.spriteFrame = 1          // `_PlayGame` state 3 → 4: +0x3e = 1, +0x42 = 0, +0x48 = 0
            state.hero.freezeCounter = 0
            state.hero.deathCounter = 0
            state.hero.visible = visible
            state.hero.invisible = invisible
            return state
        }
        for invisible in [false, true] {
            var state = dying(visible: true, invisible: invisible)
            var source = input(Self.none)
            for call in 1...31 {
                state.processHero(input: &source)
                XCTAssertEqual(state.rng.drawCount, 0, "call \(call)")
            }
            XCTAssertEqual(state.hero.spriteSet, 7)
            XCTAssertEqual(state.hero.spriteFrame, 16)
            state.processHero(input: &source)
            XCTAssertEqual(state.rng.drawCount, 5, "call 32")
            XCTAssertEqual(state.airBubbles.activeCount, 5)
            XCTAssertEqual(state.airBubbles.slots[0].rect.left, 280 + 8)
            XCTAssertEqual(state.airBubbles.slots[0].rect.top, 240 + 8)
            XCTAssertTrue(state.hero.deathBubblesEmitted)
            XCTAssertEqual(state.hero.spriteFrame, 16)
            XCTAssertEqual(state.hero.deathCounter, 1)
            for _ in 0..<100 { state.processHero(input: &source) }
            XCTAssertEqual(state.rng.drawCount, 5)
            XCTAssertEqual(state.hero.deathCounter, 51)
            XCTAssertEqual(source.samplesConsumed, 0)
        }
        var state = dying(visible: false, invisible: false)
        var source = input(Self.none)
        for _ in 0..<64 { state.processHero(input: &source) }
        XCTAssertEqual(state.rng.drawCount, 0)
        XCTAssertEqual(state.airBubbles.activeCount, 0)
        XCTAssertFalse(state.hero.deathBubblesEmitted)
        XCTAssertEqual(state.hero.deathCounter, 17)
    }

    /// Research notes 23, 25: the first state-2 call latches `gLevelForEffect` = L (15); a direction choice draws
    /// `GetRandomFast(0,1)` when `L <= level`. On a successful push frame the push check runs first and returns, so
    /// there is no turn draw; the push-freeze end restores the walking sprite with one draw.
    func testLevelForEffectDraws() {
        var state = world(level: 15)
        XCTAssertEqual(state.levelForEffect, 50)
        var source = input(Self.held(left: true))
        state.processHero(input: &source)
        XCTAssertEqual(state.levelForEffect, 15)
        XCTAssertEqual(state.rng.drawCount, 1, "level 15 aligned choice")
        state.processHero(input: &source)            // mid-cell, no reversal: no choice, no draw
        XCTAssertEqual(state.rng.drawCount, 1)

        state = world(level: 14)
        source = input(Self.held(left: true))
        state.processHero(input: &source)
        XCTAssertEqual(state.levelForEffect, 15)
        XCTAssertEqual(state.rng.drawCount, 0, "level 14")

        state = world(level: 15)
        state.maze[6, 6] = CellCode.normal
        source = input(Self.held(left: true, push: true))
        state.processHero(input: &source)
        XCTAssertTrue(state.hero.frozen)
        XCTAssertEqual(state.rng.drawCount, 0, "push frame: no turn draw")
        state.processHero(input: &source)
        state.processHero(input: &source)
        XCTAssertEqual(state.rng.drawCount, 0)
        state.processHero(input: &source)            // freeze end
        XCTAssertFalse(state.hero.frozen)
        XCTAssertEqual(state.rng.drawCount, 1, "push-freeze end")
    }

    /// Research note 23 / `hero-and-input.md` §7: the bonus ends once `start + 300 < frame`; from `start + 210 <
    /// frame` the draw-transparent flag follows a toggle that flips every 3rd call.
    func testInvisibilityTimeline() {
        var state = world()
        let start: UInt16 = 1000
        state.frame = start
        state.setHeroInvisibility(true)
        var source = input(Self.none)
        for f in (start + 1)...(start + 300) {
            state.frame = f
            state.processHero(input: &source)
            XCTAssertTrue(state.hero.invisible, "frame \(f)")
            let k = Int(f) - Int(start) - 210
            let expected = k <= 0 ? true : (k / 3) % 2 == 1
            XCTAssertEqual(state.hero.drawTransparent, expected, "frame \(f)")
        }
        state.frame = start + 301
        state.processHero(input: &source)
        XCTAssertFalse(state.hero.invisible)
        XCTAssertFalse(state.hero.drawTransparent)
        XCTAssertEqual(state.rng.drawCount, 0)
    }
}
