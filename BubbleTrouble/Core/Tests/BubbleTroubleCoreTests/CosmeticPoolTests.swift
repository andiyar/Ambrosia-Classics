@testable import BubbleTroubleCore
import XCTest

/// Task 3b — Cosmetic pools II: air bubbles, score points, splats (docs/plans/2026-10-03-btx-core-and-film-harness.md
/// §Task 3b; Research notes 15, 16, 22, 48–50; Invariant 8; bank correction C7).
///
/// Sources: `_Bubbles_Init @ 00016cda` + `_Bubbles_CreateRandomLUT @ 000161f6` (33 + 21 + 21 + 13 + 21 = 109 draws;
/// table lengths from `nm -n`), `_Bubbles @ 000169e2` (launch while `frame > last + delay`, initial delay 0x1e; hero
/// mouth when state 2, aligned, `hero+0x0c + 0x8c < frame`, facing 3/4 → group 9/10), `_Bubbles_NewGroup @ 0001657e`
/// (calls per group 1,1,1,1,2,2,2,3,4,3,3,5), `_Bubbles_New @ 00016349` (8-cap returns before `(5,9)`),
/// `_Bubbles_Process @ 00016b1a` (delayed: no move, no drift advance; dead when bottom < 0 — C7),
/// `_InitPoints @ 0000241b` (8 × `(2,6) + 0x12`), `_NewPoint @ 00002468`, `_ProcessPoints @ 00002585` (dead on the
/// 31st visible call), `_DrawPointsToComp @ 00002641` (trap `(0,0x14)` per live armed point), `_Splats_* @
/// 00002af9…00002c79` (dead when `start + 7 < frame`). FILM 1 table values are the plan's Python computation
/// (Research notes 18/22, QuickDraw LCG assumed) — self-derived, not bank-derived.
final class CosmeticPoolTests: XCTestCase {

    /// A step whose "seed" is the number of draws so far and whose value is `value(drawIndex)`.
    private func countingStep(_ value: @escaping @Sendable (UInt32) -> Int16) -> GameRandom.Step {
        { seed in (seed &+ 1, value(seed)) }
    }

    /// The raw `Random()` value r with `((n) * r) >> 16 == k` for `_GetRandomFast(0, n − 1)`.
    private static func raw(for k: Int, range n: Int) -> Int16 {
        Int16(bitPattern: UInt16((k * 65536 + n - 1) / n))
    }

    /// A step returning 0 forever: every `fast(lo, hi)` is `lo` (vertical table all 2 → size-2 speed 3).
    private let zeroStep: GameRandom.Step = { seed in (seed, 0) }

    private func hero(facing: Direction, last: UInt16 = 0) -> HeroAnchor {
        HeroAnchor(state: 2, aligned: true, facing: facing, rect: QDRect.cell(col: 7, row: 6), lastBubbleFrame: last)
    }

    // MARK: - Air bubbles

    /// Research note 15: `_Bubbles_CreateRandomLUT` draws 109; `(0,0xe)` results 0…14 map to groups
    /// 0,0,1,1,2,2,3,4,4,5,5,6,7,7,8. FILM 1 cross-check (Research note 18, self-derived): after the 6 jewel draws the
    /// LUT ends at draw 115 with x-table `159, 228, 277, 133, 262…`, the full delay and group tables, vertical
    /// `5,4,2,3,4…` and drift `2,0,3,2,3…`.
    func testBubbleResetDraws109AndGroupMap() {
        var pool = AirBubblePool()
        var rng = GameRandom(seed: 0x0046_42a0)
        for _ in 0..<6 { _ = rng.random() }            // PositionJewels: 3 × {(1,14), (1,9)}
        pool.reset(rng: &rng)
        XCTAssertEqual(rng.drawCount, 115)
        XCTAssertEqual(Array(pool.xLoc.prefix(5)), [159, 228, 277, 133, 262])
        XCTAssertEqual(pool.delayTable, [85, 69, 53, 53, 56, 54, 78, 51, 49, 90, 51, 49, 74])
        XCTAssertEqual(pool.groups, [2, 0, 0, 3, 5, 4, 0, 4, 7, 5, 5, 4, 6, 3, 7, 0, 0, 2, 6, 1, 0])
        XCTAssertEqual(Array(pool.vertical.prefix(5)), [5, 4, 2, 3, 4])
        XCTAssertEqual(Array(pool.drift.prefix(5)), [2, 0, 3, 2, 3])
        XCTAssertEqual(pool.xLoc.count, 33)
        XCTAssertEqual(pool.drift.count, 21)
        XCTAssertEqual(pool.vertical.count, 21)
        XCTAssertEqual(pool.delayTable.count, 13)
        XCTAssertEqual(pool.groups.count, 21)
        XCTAssertTrue(pool.xLoc.allSatisfy { (40...480).contains($0) })
        XCTAssertEqual([pool.xIndex, pool.driftIndex, pool.verticalIndex, pool.delayIndex, pool.groupIndex], [0, 0, 0, 0, 0])
        XCTAssertEqual(pool.activeCount, 0)
        XCTAssertEqual(pool.timeLastGroupLaunched, 0)
        XCTAssertEqual(pool.delayTilNextGroup, 0x1e)

        // Group map: draws 88…102 (the first 15 group draws) yield (0,0xe) results 0…14.
        let step = countingStep { i in i >= 88 ? Self.raw(for: Int(i - 88) % 15, range: 15) : 0 }
        var mapped = AirBubblePool()
        var stub = GameRandom(seed: 0, step: step)
        mapped.reset(rng: &stub)
        XCTAssertEqual(stub.drawCount, 109)
        XCTAssertEqual(Array(mapped.groups.prefix(15)), [0, 0, 1, 1, 2, 2, 3, 4, 4, 5, 5, 6, 7, 7, 8])
        XCTAssertEqual(Array(mapped.groups.suffix(6)), [0, 0, 1, 1, 2, 2])
    }

    /// Research note 48: `_Bubbles_NewGroup` makes 1,1,1,1,2,2,2,3,4,3,3,5 `_Bubbles_New` calls for groups 0…0xb,
    /// one `(5,9)` draw each on an empty pool; pref 0x36 off → nothing.
    func testBubbleGroupSizes() {
        let expected = [1, 1, 1, 1, 2, 2, 2, 3, 4, 3, 3, 5]
        for (group, calls) in expected.enumerated() {
            var pool = AirBubblePool()
            var rng = GameRandom(seed: 0x0046_42a0)
            pool.reset(rng: &rng)
            let before = rng.drawCount
            pool.newGroup(x: 300, y: 200, group: group, frame: 40, prefs: CosmeticPrefs(), rng: &rng)
            XCTAssertEqual(rng.drawCount - before, calls, "group \(group)")
            XCTAssertEqual(pool.activeCount, calls, "group \(group)")
        }
        var pool = AirBubblePool()
        var rng = GameRandom(seed: 0x0046_42a0)
        pool.newGroup(x: 300, y: 200, group: 0xc, frame: 40, prefs: CosmeticPrefs(), rng: &rng)
        pool.newGroup(x: 300, y: 200, group: 0xb, frame: 40, prefs: CosmeticPrefs(stars: true, airBubbles: false), rng: &rng)
        XCTAssertEqual(rng.drawCount, 0)
        XCTAssertEqual(pool.activeCount, 0)
    }

    /// `_Bubbles_NewGroup @ 0001657e` last call per group at (x, y) = (300, 200), rect (y', x', y' + side, x' + side)
    /// with side 0x12 / 0x17 / 0x1d / 0x2b by size (`_Bubbles_New @ 00016349`):
    /// 4 → `New(x+0x14, y+8, 0, 0)`; 5 → `New(x+0x14, y+8, 2, 0)`; 6 → `New(x+0x14, y+0x10, 2, 0)`;
    /// 7 → `New(x+0x14, y+0x29, 0, 0)`; 8 → `New(x+1, y+4, 0, 0)`; 10 → `New(x, y+8, 2, 4)`;
    /// 0xb → `New(x+0xc, y+0xc, 0, 6)`.
    func testBubbleGroupLastOffsets() {
        let cases: [(group: Int, rect: QDRect, size: Int8, delay: Int16)] = [
            (4, QDRect(top: 208, left: 320, bottom: 226, right: 338), 0, 0),
            (5, QDRect(top: 208, left: 320, bottom: 237, right: 349), 2, 0),
            (6, QDRect(top: 216, left: 320, bottom: 245, right: 349), 2, 0),
            (7, QDRect(top: 241, left: 320, bottom: 259, right: 338), 0, 0),
            (8, QDRect(top: 204, left: 301, bottom: 222, right: 319), 0, 0),
            (10, QDRect(top: 208, left: 300, bottom: 237, right: 329), 2, 4),
            (0xb, QDRect(top: 212, left: 312, bottom: 230, right: 330), 0, 6),
        ]
        for c in cases {
            var pool = AirBubblePool()
            var rng = GameRandom(seed: 0x0046_42a0)
            pool.reset(rng: &rng)
            pool.newGroup(x: 300, y: 200, group: c.group, frame: 40, prefs: CosmeticPrefs(), rng: &rng)
            let last = pool.slots[pool.activeCount - 1]
            XCTAssertEqual(last.rect, c.rect, "group \(c.group)")
            XCTAssertEqual(last.size, c.size, "group \(c.group)")
            XCTAssertEqual(last.delay, c.delay, "group \(c.group)")
        }
    }

    /// `_Bubbles_New`: `if (_gBubbles_NumActive == 8) return;` precedes `_GetRandomFast(5,9)`.
    func testBubbleCapEight() {
        var pool = AirBubblePool()
        var rng = GameRandom(seed: 0x0046_42a0)
        for i in 0..<8 {
            pool.newBubble(x: Int16(100 + 40 * i), y: 300, size: 0, delay: 0, frame: 1, rng: &rng)
        }
        XCTAssertEqual(pool.activeCount, 8)
        XCTAssertEqual(rng.drawCount, 8)
        pool.newBubble(x: 300, y: 300, size: 1, delay: 0, frame: 1, rng: &rng)
        pool.newGroup(x: 300, y: 300, group: 0xb, frame: 1, prefs: CosmeticPrefs(), rng: &rng)
        XCTAssertEqual(rng.drawCount, 8)
        XCTAssertEqual(pool.activeCount, 8)
    }

    /// C7: dead when the rect **bottom** < 0. Size 2 (side 29) at y 385 → bottom 414; speed 3 (vertical 2 → 3):
    /// bottom 0 after 138 calls (alive), −3 after 139 (dead); freed by the draw pass.
    func testBubbleDiesWhenBottomBelowZero() {
        var pool = AirBubblePool()
        var rng = GameRandom(seed: 1, step: zeroStep)
        pool.reset(rng: &rng)
        pool.newBubble(x: 300, y: 385, size: 2, delay: 0, frame: 0, rng: &rng)
        XCTAssertEqual(pool.slots[0].riseSpeed, 3)
        XCTAssertEqual(pool.slots[0].rect.bottom, 414)
        for f in 1...138 {
            pool.process(frame: UInt16(f))
            pool.drawPassFree()
        }
        XCTAssertEqual(pool.slots[0].rect.bottom, 0)
        XCTAssertFalse(pool.slots[0].dead)
        XCTAssertTrue(pool.slots[0].active)
        pool.process(frame: 139)
        XCTAssertEqual(pool.slots[0].rect.bottom, -3)
        XCTAssertTrue(pool.slots[0].dead)
        XCTAssertTrue(pool.slots[0].active, "freed only in the draw pass (Invariant 8)")
        XCTAssertEqual(pool.activeCount, 1)
        pool.drawPassFree()
        XCTAssertFalse(pool.slots[0].active)
        XCTAssertEqual(pool.activeCount, 0)
    }

    /// C7 / Research note 48: group 9 (delays 0, 2, 4) — a delayed bubble keeps its rect and does not advance the
    /// global drift index until `delay + start < frame` makes it visible (that call still does not move it).
    func testDelayedBubbleNeitherMovesNorDrifts() {
        var pool = AirBubblePool()
        var rng = GameRandom(seed: 0x0046_42a0)
        pool.reset(rng: &rng)
        let start: UInt16 = 100
        pool.newGroup(x: 280, y: 240, group: 9, frame: start, prefs: CosmeticPrefs(), rng: &rng)
        XCTAssertEqual(pool.activeCount, 3)
        XCTAssertEqual(pool.slots.prefix(3).map(\.delayed), [false, true, true])
        let rect1 = pool.slots[1].rect, rect2 = pool.slots[2].rect
        // Moving bubbles per call at frames start+1 … start+7: slot 1 becomes visible at start+3 (2 + start <
        // frame) and moves from start+4; slot 2 visible at start+5, moves from start+6.
        let movers = [1, 1, 1, 2, 2, 3, 3]
        var drift = 0
        for (k, n) in movers.enumerated() {
            let frame = start + UInt16(k + 1)
            pool.process(frame: frame)
            drift = (drift + n) % 21
            XCTAssertEqual(pool.driftIndex, drift, "frame start+\(k + 1)")
            if frame <= start + 3 { XCTAssertEqual(pool.slots[1].rect, rect1, "slot 1 frame start+\(k + 1)") }
            if frame <= start + 5 { XCTAssertEqual(pool.slots[2].rect, rect2, "slot 2 frame start+\(k + 1)") }
            XCTAssertEqual(pool.slots[1].delayed, frame <= start + 2)
            XCTAssertEqual(pool.slots[2].delayed, frame <= start + 4)
            XCTAssertEqual(pool.slots[1].visible, frame > start + 2)
        }
        XCTAssertNotEqual(pool.slots[1].rect, rect1)
        XCTAssertNotEqual(pool.slots[2].rect, rect2)
    }

    /// `_Bubbles`: after `reset` (last 0, delay 0x1e) no launch at frame 30, launch at 31 (FILM 1: group 2 → one
    /// `(5,9)`, Research note 22). Hero aligned facing left with `lastBubbleFrame + 140 < frame` → group 9 at the
    /// hero's (left, top), `lastBubbleFrame = frame`, random indices untouched. (The frame-31 facing-up launch only
    /// shows the timing gate — `lastBubbleFrame 0 + 140` already fails; the facing fallback and facing right are
    /// `testLauncherFacingUpFallsBackToRandomTable` / `testLauncherFacingRightLaunchesGroup10`.)
    func testLauncherTimingAndHeroMouth() {
        var pool = AirBubblePool()
        var rng = GameRandom(seed: 0x0046_42a0)
        for _ in 0..<6 { _ = rng.random() }
        pool.reset(rng: &rng)
        var up = hero(facing: .up)
        pool.launch(frame: 30, hero: &up, prefs: CosmeticPrefs(), rng: &rng)
        XCTAssertEqual(rng.drawCount, 115)
        XCTAssertEqual(pool.activeCount, 0)
        XCTAssertEqual(pool.timeLastGroupLaunched, 0)
        // Frame 31: lastBubbleFrame 0 + 140 ≮ 31 fails the hero gate before facing is read → random group
        // groups[0] = 2 at (159, 0x181).
        pool.launch(frame: 31, hero: &up, prefs: CosmeticPrefs(), rng: &rng)
        XCTAssertEqual(rng.drawCount, 116)
        XCTAssertEqual(pool.activeCount, 1)
        XCTAssertEqual(pool.slots[0].size, 2)
        XCTAssertEqual(pool.slots[0].rect, QDRect(top: 0x181, left: 159, bottom: 0x181 + 29, right: 159 + 29))
        XCTAssertEqual([pool.xIndex, pool.groupIndex, pool.delayIndex], [1, 1, 1])
        XCTAssertEqual(pool.timeLastGroupLaunched, 31)
        XCTAssertEqual(pool.delayTilNextGroup, 85)
        XCTAssertEqual(up.lastBubbleFrame, 0)
        // Next launch needs frame > 31 + 85.
        pool.launch(frame: 116, hero: &up, prefs: CosmeticPrefs(), rng: &rng)
        XCTAssertEqual(rng.drawCount, 116)

        // Hero mouth: frame 200, lastBubbleFrame 59 (59 + 140 < 200), facing left → group 9 at (left, top).
        var left = hero(facing: .left, last: 59)
        pool.launch(frame: 200, hero: &left, prefs: CosmeticPrefs(), rng: &rng)
        XCTAssertEqual(rng.drawCount, 119)
        XCTAssertEqual(left.lastBubbleFrame, 200)
        XCTAssertEqual([pool.xIndex, pool.groupIndex, pool.delayIndex], [1, 1, 2])
        XCTAssertEqual(pool.delayTilNextGroup, 69)
        let h = left.rect
        XCTAssertEqual(pool.slots[1].rect.left, h.left - 8)
        XCTAssertEqual(pool.slots[1].rect.top, h.top + 12)
        XCTAssertEqual(pool.slots[3].rect.left, h.left - 16)
        XCTAssertEqual(pool.slots[3].rect.top, h.top + 8)
        // lastBubbleFrame + 140 == frame is not enough: falls through to the random table.
        var edge = hero(facing: .right, last: 130)
        pool.launch(frame: 270, hero: &edge, prefs: CosmeticPrefs(), rng: &rng)
        XCTAssertEqual(edge.lastBubbleFrame, 130)
        XCTAssertEqual([pool.xIndex, pool.groupIndex, pool.delayIndex], [2, 2, 3])
        // Prefs off → nothing at all.
        var off = AirBubblePool()
        var rng2 = GameRandom(seed: 0x0046_42a0)
        off.reset(rng: &rng2)
        off.launch(frame: 31, hero: &up, prefs: CosmeticPrefs(stars: true, airBubbles: false), rng: &rng2)
        XCTAssertEqual(rng2.drawCount, 109)
        XCTAssertEqual(off.timeLastGroupLaunched, 0)
    }

    /// `_Bubbles @ 000169e2`: state 2, aligned and `hero+0x0c + 0x8c < frame` all hold (59 + 140 = 199 < 200), but
    /// facing (hero+0x26) is neither 3 nor 4 → `goto LAB_00016a88`, the random launch: groups[0] = 2 at
    /// (xLoc[0] = 159, 0x181), and `hero+0x0c` is **not** rewritten (only the mouth branch stores the frame).
    func testLauncherFacingUpFallsBackToRandomTable() {
        var pool = AirBubblePool()
        var rng = GameRandom(seed: 0x0046_42a0)
        for _ in 0..<6 { _ = rng.random() }
        pool.reset(rng: &rng)
        var up = hero(facing: .up, last: 59)
        pool.launch(frame: 200, hero: &up, prefs: CosmeticPrefs(), rng: &rng)
        XCTAssertEqual(rng.drawCount, 116)
        XCTAssertEqual(pool.activeCount, 1)
        XCTAssertEqual(pool.slots[0].size, 2)
        XCTAssertEqual(pool.slots[0].rect, QDRect(top: 0x181, left: 159, bottom: 0x181 + 29, right: 159 + 29))
        XCTAssertEqual([pool.xIndex, pool.groupIndex, pool.delayIndex], [1, 1, 1])
        XCTAssertEqual(up.lastBubbleFrame, 59)
        XCTAssertEqual(pool.timeLastGroupLaunched, 200)
        XCTAssertEqual(pool.delayTilNextGroup, 85)
    }

    /// `_Bubbles @ 000169e2`: facing 4 (right) → `_Bubbles_NewGroup(hero+0x1a = right, hero+0x14 = top, 10)`;
    /// `_Bubbles_NewGroup` case 10 → `New(x, y+0xc, 0, 0)`, `New(x, y+10, 1, 2)`, `New(x, y+8, 2, 4)`. Hero cell (7,6):
    /// right 320, top 240. Sides 0x12 / 0x17 / 0x1d (`_Bubbles_New`). Random x/group indices untouched.
    func testLauncherFacingRightLaunchesGroup10() {
        var pool = AirBubblePool()
        var rng = GameRandom(seed: 0x0046_42a0)
        for _ in 0..<6 { _ = rng.random() }
        pool.reset(rng: &rng)
        var right = hero(facing: .right, last: 59)
        pool.launch(frame: 200, hero: &right, prefs: CosmeticPrefs(), rng: &rng)
        XCTAssertEqual(rng.drawCount, 118)
        XCTAssertEqual(pool.activeCount, 3)
        XCTAssertEqual(right.lastBubbleFrame, 200)
        XCTAssertEqual([pool.xIndex, pool.groupIndex, pool.delayIndex], [0, 0, 1])
        XCTAssertEqual(pool.slots[0].rect, QDRect(top: 252, left: 320, bottom: 270, right: 338))
        XCTAssertEqual(pool.slots[1].rect, QDRect(top: 250, left: 320, bottom: 273, right: 343))
        XCTAssertEqual(pool.slots[2].rect, QDRect(top: 248, left: 320, bottom: 277, right: 349))
        XCTAssertEqual(pool.slots.prefix(3).map(\.size), [0, 1, 2])
        XCTAssertEqual(pool.slots.prefix(3).map(\.delay), [0, 2, 4])
    }

    // MARK: - Score points

    /// Research note 16: `_InitPoints` draws 8 thresholds `(2,6) + 0x12` ∈ 20…24. FILM 1 cross-check (Research
    /// note 18, self-derived): after jewels (6), bubble LUT (109) and stars (42) → `23,24,21,22,20,24,23,23`, 165.
    func testPointResetThresholds() {
        var points = PointPool()
        var rng = GameRandom(seed: 0x0046_42a0)
        points.reset(rng: &rng)
        XCTAssertEqual(rng.drawCount, 8)
        XCTAssertEqual(points.thresholds.count, 8)
        XCTAssertTrue(points.thresholds.allSatisfy { (20...24).contains($0) })
        XCTAssertEqual(points.activeCount, 0)
        XCTAssertTrue(points.slots.allSatisfy { !$0.active })

        var film = GameRandom(seed: 0x0046_42a0)
        for _ in 0..<6 { _ = film.random() }
        var bubbles = AirBubblePool(), stars = StarPool(), p = PointPool()
        bubbles.reset(rng: &film)
        stars.reset(rng: &film)
        p.reset(rng: &film)
        XCTAssertEqual(film.drawCount, 165)
        XCTAssertEqual(p.thresholds, [23, 24, 21, 22, 20, 24, 23, 23])
    }

    /// `_ProcessPoints`: a visible point dies on its 31st call (`counter > 0x1e`), rising 1 px per call while
    /// top > 0; a delayed point becomes visible once `delay < counter`. `_DrawPointsToComp` draws `(0,0x14)` per live
    /// trap-armed point (`threshold <= level && gPointsNotReg`), none otherwise; a draw of 1 is the original's quit.
    func testPointLifetimeAndTrap() {
        var points = PointPool()
        var rng = GameRandom(seed: 0x0046_42a0)
        points.reset(rng: &rng)
        let base = rng.drawCount
        points.newPoint(x: 302, y: 200, sprite: 12, delay: 0, level: 30, notRegistered: false)
        XCTAssertEqual(points.slots[0].rect, QDRect(top: 208, left: 298, bottom: 236, right: 346))
        XCTAssertEqual(points.slots[0].spriteSet, 0x34)
        XCTAssertEqual(points.slots[0].frame, 12)
        for _ in 0..<30 {
            points.process()
            XCTAssertEqual(points.drawPass(rng: &rng), false)
        }
        XCTAssertFalse(points.slots[0].dead)
        XCTAssertEqual(points.slots[0].rect.top, 178)
        points.process()
        XCTAssertTrue(points.slots[0].dead)
        XCTAssertEqual(points.activeCount, 1)
        XCTAssertFalse(points.drawPass(rng: &rng))
        XCTAssertFalse(points.slots[0].active)
        XCTAssertEqual(points.activeCount, 0)
        XCTAssertEqual(rng.drawCount, base, "no trap draws when gPointsNotReg is false")

        // x clamps: x − 4 < 0 → 0; x − 4 + 48 > 640 → 592.
        points.newPoint(x: 2, y: 0, sprite: 1, delay: 0, level: 1, notRegistered: false)
        points.newPoint(x: 600, y: 0, sprite: 1, delay: 0, level: 1, notRegistered: false)
        XCTAssertEqual(points.slots[0].rect.left, 0)
        XCTAssertEqual(points.slots[1].rect.left, 0x250)

        // Delayed point (delay 12): visible on the 13th call, then its 31-call life starts.
        var delayed = PointPool()
        var r2 = GameRandom(seed: 0x0046_42a0)
        delayed.reset(rng: &r2)
        delayed.newPoint(x: 300, y: 200, sprite: 12, delay: 12, level: 1, notRegistered: false)
        for _ in 0..<12 { delayed.process() }
        XCTAssertTrue(delayed.slots[0].delayed)
        XCTAssertEqual(delayed.slots[0].rect.top, 208)
        delayed.process()
        XCTAssertFalse(delayed.slots[0].delayed)
        XCTAssertTrue(delayed.slots[0].visible)
        XCTAssertEqual(delayed.slots[0].counter, 0)
        for _ in 0..<30 { delayed.process() }
        XCTAssertFalse(delayed.slots[0].dead)
        delayed.process()
        XCTAssertTrue(delayed.slots[0].dead)

        // Trap: level below every threshold → not armed; level 24 (≥ every threshold) → 1 draw per live point per pass.
        var trap = PointPool()
        var r3 = GameRandom(seed: 0x0046_42a0)
        trap.reset(rng: &r3)
        trap.newPoint(x: 100, y: 100, sprite: 1, delay: 0, level: 19, notRegistered: true)
        trap.newPoint(x: 200, y: 100, sprite: 1, delay: 0, level: 24, notRegistered: true)
        trap.newPoint(x: 300, y: 100, sprite: 1, delay: 0, level: 24, notRegistered: true)
        XCTAssertEqual(trap.slots.prefix(3).map(\.trap), [false, true, true])
        let t0 = r3.drawCount
        XCTAssertFalse(trap.drawPass(rng: &r3))
        XCTAssertEqual(r3.drawCount - t0, 2)
        trap.process()
        XCTAssertFalse(trap.drawPass(rng: &r3))
        XCTAssertEqual(r3.drawCount - t0, 4)

        // A trap draw of 1 → the original quits; the replica reports it.
        var quit = PointPool()
        var r4 = GameRandom(seed: 0, step: countingStep { i in i < 8 ? 0 : Self.raw(for: 1, range: 21) })
        quit.reset(rng: &r4)
        quit.newPoint(x: 100, y: 100, sprite: 1, delay: 0, level: 20, notRegistered: true)
        XCTAssertEqual(quit.thresholds[0], 20)
        XCTAssertTrue(quit.drawPass(rng: &r4))
        XCTAssertEqual(r4.drawCount, 9)
    }

    // MARK: - Splats

    /// `_Splats_Process`: dead when `start + 7 < frame` (alive at start + 7, dead at start + 8), freed by the draw
    /// pass; kind 0 → sprite set 0x26, kind 1 → 0x27; rect 40 × 40; first free of 12 slots.
    func testSplatLifetime() {
        var splats = SplatPool()
        splats.reset()
        splats.newSplat(x: 120, y: 80, kind: 0, frame: 10)
        splats.newSplat(x: 200, y: 160, kind: 1, frame: 12)
        XCTAssertEqual(splats.slots[0].spriteSet, 0x26)
        XCTAssertEqual(splats.slots[1].spriteSet, 0x27)
        XCTAssertEqual(splats.slots[0].rect, QDRect(top: 80, left: 120, bottom: 120, right: 160))
        for f in UInt16(11)...17 {
            splats.process(frame: f)
            splats.drawPassFree()
        }
        XCTAssertTrue(splats.slots[0].active)
        XCTAssertFalse(splats.slots[0].dead)
        splats.process(frame: 18)
        XCTAssertTrue(splats.slots[0].dead)
        XCTAssertFalse(splats.slots[0].visible)
        XCTAssertFalse(splats.slots[1].dead)
        XCTAssertTrue(splats.slots[0].active, "freed only in the draw pass (Invariant 8)")
        splats.drawPassFree()
        XCTAssertFalse(splats.slots[0].active)
        XCTAssertTrue(splats.slots[1].active)
        // The freed slot 0 is reused first.
        splats.newSplat(x: 0, y: 0, kind: 1, frame: 18)
        XCTAssertEqual(splats.slots[0].startFrame, 18)
        splats.process(frame: 20)
        XCTAssertTrue(splats.slots[1].dead)
        XCTAssertFalse(splats.slots[0].dead)
        // Twelve slots: a 13th splat is dropped.
        var full = SplatPool()
        for i in 0..<13 { full.newSplat(x: Int16(i * 40), y: 0, kind: 0, frame: 1) }
        XCTAssertTrue(full.slots.allSatisfy(\.active))
        XCTAssertEqual(full.slots.count, 12)
    }
}
