import XCTest
import HectorResources
@testable import DeimosCore

/// Score-bar state (hud-scorebar.md §2–§3, §6–§7): init `FUN_10030f40`, level start `FUN_10031400` (state
/// part), per-tick update `FUN_100317e0`, icons `FUN_1003bb40`.
final class ScoreBarStateTests: XCTestCase {
    func testScoreBarFollowersAndIcons() throws {
        let a = try PlayerPhase1Tests.loaded.get()
        var w = try PlayerPhase1Tests.World(assets: a, players: 1)

        // Level start: P1 drawn active, P2 (not in game) drawn dimmed once — all six dirty for both.
        let p1 = w.bar.records[0], p2 = w.bar.records[1]
        XCTAssertTrue(p1.drawActive)
        XCTAssertTrue(p1.pendingRetire)
        XCTAssertFalse(p2.drawActive)
        XCTAssertFalse(p2.pendingRetire)
        for r in [p1, p2] { XCTAssertEqual(r.dirty, ScoreBarState.Dirty.all) }
        XCTAssertEqual(p1.lastLives, 3)
        XCTAssertEqual(p1.lastScore, 0)
        XCTAssertEqual(p1.shownShield, 0)
        XCTAssertEqual(p1.shownPower, 0)
        XCTAssertEqual(p1.livesSymbol, ScoreBarState.Icon(face: FourCC("play")!, frame: 0))
        XCTAssertEqual(p2.livesSymbol, ScoreBarState.Icon(face: FourCC("play")!, frame: 1))
        XCTAssertEqual(p1.shieldMeter.face, FourCC("shme"))
        // Icons: slot 0 = Ion Cannon's preview (wesy 0); the sector-1 cycle wraps to aiic → slots 1–2 none.
        XCTAssertEqual(p1.icons, [ScoreBarState.Icon(face: FourCC("wesy")!, frame: 0), .none, .none])
        // Rects: R0 local and back-buffer (+416 x).
        XCTAssertEqual(p1.localRects.count, 8)
        XCTAssertEqual(p1.bufferRects[0].left, p1.localRects[0].left + 416)
        XCTAssertEqual(p1.bufferRects[0].top, p1.localRects[0].top)
        XCTAssertEqual(p2.localRects[0], a.rects[8])

        for t: Int32 in 0...110 {
            w.tick()
            let r = w.bar.records[0]
            let expected: Float = t <= 55 ? 0 : min(100, Float(2 * (t - 55)))
            XCTAssertEqual(r.shownShield, expected, "shield t \(t)")
            XCTAssertEqual(r.shownPower, 0, "power t \(t)")
            XCTAssertTrue(r.dirty.contains(.weapons), "weapons dirty t \(t)")
            XCTAssertEqual(r.dirty.contains(.shield), t <= 105, "shield dirty t \(t)")
            XCTAssertFalse(r.dirty.contains(.power))
            XCTAssertFalse(r.dirty.contains(.score))
            XCTAssertFalse(r.dirty.contains(.livesCount))
            XCTAssertEqual(r.icons, [ScoreBarState.Icon(face: FourCC("wesy")!, frame: 0), .none, .none])
            XCTAssertEqual(w.bar.records[1].dirty, [], "P2 never redrawn after level start, t \(t)")
            XCTAssertFalse(w.bar.records[1].drawActive)
        }
        XCTAssertEqual(w.bar.records[0].shownShield, 100)

        // Direct setters (FUN_10031710 no clamp; FUN_10031760 the < 1 → 0, > 100 → 100 clamp).
        w.bar.setShownShield(index: 0, 150)
        XCTAssertEqual(w.bar.records[0].shownShield, 150)
        w.bar.setShownPower(index: 0, 0.5)
        XCTAssertEqual(w.bar.records[0].shownPower, 0)
        w.bar.setShownPower(index: 0, 120)
        XCTAssertEqual(w.bar.records[0].shownPower, 100)
        // Followers: shield falls 3/tick (floored at target); power falls 4/tick then the < 1 → 0 clamp.
        w.bar.setShownPower(index: 0, 5)
        w.tick()
        XCTAssertEqual(w.bar.records[0].shownShield, 147)
        XCTAssertEqual(w.bar.records[0].shownPower, 1)
        w.tick()
        XCTAssertEqual(w.bar.records[0].shownShield, 144)
        XCTAssertEqual(w.bar.records[0].shownPower, 0)
    }
}
