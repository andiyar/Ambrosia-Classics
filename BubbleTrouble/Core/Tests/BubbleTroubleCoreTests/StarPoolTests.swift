import BubbleTroubleCore
import XCTest

/// Task 3a — Cosmetic pools I: stars (docs/plans/2026-10-03-btx-core-and-film-harness.md §Task 3a;
/// Research notes 46–47; Invariants 6 and 8).
///
/// Sources: `_InitStars @ 00004db8` + `_CreateStarRandomLocLookupTable @ 0000323e` (21 × {(0,8),(0,1)} = 42 draws),
/// `_NewStar @ 0000329a` (60-cap → first free → claim → rect → playfield clip x 0..640 / y 0..440 → only then the
/// motion-0xb `(0,1)` draw), `_NewStarGroup @ 000035b5` (squish groups 3/4/5: four 26-px stars at (−8,−8) (+6,+6)
/// (−16,+20) (+6,+20); group 0xe: 13 explicit stars + the shared tail call at (x+10, y−2) = 14), `_ProcessStars
/// @ 00004b05`, `_DrawStarsToComp @ 00004de0` (frees dead slots). The clip draw counts are the plan's Python
/// computation from those offsets, not an oracle trace.
final class StarPoolTests: XCTestCase {

    private let hero = HeroAnchor(state: 2, aligned: true, facing: .left,
                                  rect: QDRect.cell(col: 7, row: 6), lastBubbleFrame: 0)

    /// Draws consumed by one `newGroup` on a fresh pool at the cell's (left, top).
    private func groupDraws(_ group: Int, col: Int, row: Int, prefs: CosmeticPrefs = CosmeticPrefs())
        -> (draws: Int, active: Int)
    {
        var pool = StarPool()
        var rng = GameRandom(seed: 0x0046_42a0)
        pool.newGroup(x: Int16(col * 40), y: Int16(row * 40), group: group, hero: hero, frame: 0,
                      prefs: prefs, rng: &rng)
        return (rng.drawCount, pool.activeCount)
    }

    /// `_InitStars` → `_CreateStarRandomLocLookupTable`: 21 entries × {(0,8), (0,1)} = 42 draws; entries in −8...8.
    func testStarResetDraws42() {
        var pool = StarPool()
        var rng = GameRandom(seed: 0x0046_42a0)
        pool.reset(rng: &rng)
        XCTAssertEqual(rng.drawCount, 42)
        XCTAssertEqual(pool.locationLookup.count, 21)
        XCTAssertTrue(pool.locationLookup.allSatisfy { (-8...8).contains($0) })
        XCTAssertEqual(pool.locationIndex, 0)
        XCTAssertEqual(pool.activeCount, 0)
        XCTAssertEqual(pool.slots.count, StarPool.capacity)
        XCTAssertTrue(pool.slots.allSatisfy { !$0.active })
    }

    /// Research note 47 / Invariant 6: group 3 at cell (0,6) → 2, (5,0) → 3, (5,10) → 2, (0,10) → 1, (15,5) → 4,
    /// (7,6) → 4 draws; a clipped star frees its slot and is not counted active.
    func testSquishGroupClipDrawCounts() {
        let cases: [(col: Int, row: Int, draws: Int)] = [(0, 6, 2), (5, 0, 3), (5, 10, 2), (0, 10, 1), (15, 5, 4), (7, 6, 4)]
        for c in cases {
            let r = groupDraws(3, col: c.col, row: c.row)
            XCTAssertEqual(r.draws, c.draws, "group 3 at cell (\(c.col),\(c.row))")
            XCTAssertEqual(r.active, c.draws, "group 3 at cell (\(c.col),\(c.row)): clipped stars not active")
        }
        // Groups 4 and 5 share group 3's offsets (kinds 5 / 6).
        XCTAssertEqual(groupDraws(4, col: 0, row: 6).draws, 2)
        XCTAssertEqual(groupDraws(5, col: 5, row: 0).draws, 3)
    }

    /// C2: group 0xe is 13 explicit `_NewStar` calls + the shared tail at (x+10, y−2) = 14 motion-0xb stars.
    func testGroup0xEHasFourteenStars() {
        let centre = groupDraws(0xe, col: 7, row: 6)
        XCTAssertEqual(centre.active, 14)
        XCTAssertEqual(centre.draws, 14)
        XCTAssertEqual(groupDraws(0xe, col: 0, row: 0).draws, 8)
        XCTAssertEqual(groupDraws(0xe, col: 0, row: 6).draws, 10)
        XCTAssertEqual(groupDraws(0xe, col: 15, row: 5).draws, 14)
    }

    /// `gNumActiveStars == 0x3c` → `_NewStar` returns before anything, so the group draws nothing.
    func testStarCapSixtyDrawsNothing() {
        var pool = StarPool()
        var rng = GameRandom(seed: 0x0046_42a0)
        for i in 0..<60 {
            pool.newStar(x: Int16(100 + i), y: 200, kind: 2, delay: 0, motion: 0, orbitIndex: -1, frame: 0, rng: &rng)
        }
        XCTAssertEqual(pool.activeCount, 60)
        XCTAssertEqual(rng.drawCount, 0, "motion-0 stars draw nothing")
        pool.newGroup(x: 280, y: 240, group: 3, hero: hero, frame: 0, prefs: CosmeticPrefs(), rng: &rng)
        XCTAssertEqual(rng.drawCount, 0)
        XCTAssertEqual(pool.activeCount, 60)
    }

    /// Pref 0x35 gates every group but 0xf / 0x10. Both blast groups are kind 7, motion 0 (no draws); group 0x10's
    /// ±80 offsets with the 38-px kind-7 star at x+1/y+1 fit when x ∈ 79…521 and y ∈ 79…321 — (300, 200) does.
    func testStarsPrefOffOnlyBlastGroups() {
        let off = CosmeticPrefs(stars: false, airBubbles: true)
        XCTAssertEqual(groupDraws(3, col: 7, row: 6, prefs: off).active, 0)
        XCTAssertEqual(groupDraws(0xe, col: 7, row: 6, prefs: off).active, 0)
        for (group, count) in [(0xf, 9), (0x10, 21)] {
            var pool = StarPool()
            var rng = GameRandom(seed: 0x0046_42a0)
            pool.newGroup(x: 300, y: 200, group: group, hero: hero, frame: 0, prefs: off, rng: &rng)
            XCTAssertEqual(pool.activeCount, count, "group \(group)")
            XCTAssertEqual(rng.drawCount, 0, "group \(group)")
            XCTAssertTrue(pool.slots.filter(\.active).allSatisfy { $0.kind == 7 && $0.width == 38 && $0.height == 38 })
        }
        // Group 0x10's (x, y) centre star is at x+1 / y+1.
        var pool = StarPool()
        var rng = GameRandom(seed: 1)
        pool.newStar(x: 300, y: 200, kind: 7, delay: 0, motion: 0, orbitIndex: -1, frame: 0, rng: &rng)
        XCTAssertEqual(pool.slots[0].rect, QDRect(top: 201, left: 301, bottom: 239, right: 339))
    }

    /// `_ProcessStars`: motion 0xb has period 7 and dies when the frame passes 5 → dead on its 40th call (it stays
    /// on the playfield from a centred start); `_DrawStarsToComp` then frees the slot.
    func testMotion0xBStarDiesOnCall40() {
        var pool = StarPool()
        var rng = GameRandom(seed: 0x0046_42a0)
        pool.newStar(x: 307, y: 200, kind: 4, delay: 0, motion: 0xb, orbitIndex: -1, frame: 0, rng: &rng)
        XCTAssertEqual(rng.drawCount, 1)
        XCTAssertEqual(pool.slots[0].dy, -10)
        XCTAssertEqual(abs(Int(pool.slots[0].dx)), 5)
        XCTAssertEqual(pool.slots[0].period, 7)
        for call in 1...39 {
            pool.process(frame: UInt16(call))
            XCTAssertFalse(pool.slots[0].dead, "alive after \(call) calls")
            pool.drawPassFree()
        }
        pool.process(frame: 40)
        XCTAssertTrue(pool.slots[0].dead)
        XCTAssertTrue(pool.slots[0].active)
        pool.drawPassFree()
        XCTAssertFalse(pool.slots[0].active)
        XCTAssertEqual(pool.activeCount, 0)
    }

    /// `_ProcessStars`: motion 0 has period 2 → dead on its 15th call; freed by the draw pass. A delayed star
    /// waits (no animation) until `start + delay < frame`.
    func testMotion0StarDiesOnCall15() {
        var pool = StarPool()
        var rng = GameRandom(seed: 1)
        pool.newStar(x: 300, y: 200, kind: 2, delay: 0, motion: 0, orbitIndex: -1, frame: 0, rng: &rng)
        for call in 1...14 {
            pool.process(frame: UInt16(call))
            XCTAssertFalse(pool.slots[0].dead, "alive after \(call) calls")
            pool.drawPassFree()
        }
        pool.process(frame: 15)
        XCTAssertTrue(pool.slots[0].dead)
        pool.drawPassFree()
        XCTAssertEqual(pool.activeCount, 0)
        XCTAssertFalse(pool.slots[0].active)

        // Delay 6 from frame 10: hidden through frame 16, revealed at 17 (no anim step that call), then 15 calls.
        pool.newStar(x: 300, y: 200, kind: 2, delay: 6, motion: 0, orbitIndex: -1, frame: 10, rng: &rng)
        XCTAssertTrue(pool.slots[0].delayed)
        XCTAssertFalse(pool.slots[0].visible)
        for f in 11...16 { pool.process(frame: UInt16(f)) }
        XCTAssertTrue(pool.slots[0].delayed)
        pool.process(frame: 17)
        XCTAssertFalse(pool.slots[0].delayed)
        XCTAssertTrue(pool.slots[0].visible)
        XCTAssertEqual(pool.slots[0].animCounter, 0)
        for f in 18...31 { pool.process(frame: UInt16(f)) }
        XCTAssertFalse(pool.slots[0].dead)
        pool.process(frame: 32)
        XCTAssertTrue(pool.slots[0].dead)
    }
}
