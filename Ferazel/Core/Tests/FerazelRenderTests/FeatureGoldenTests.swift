import XCTest
@testable import FerazelCore
@testable import FerazelRender

/// The 6A feature goldens (docs/superpowers/plans/2026-11-04-ferazel-remainder.md, "Verification-model additions for
/// 6A": "New goldens are new values, not moves"): each engine-feature task pins its feature on a level fixture (6A-FX)
/// — the fixture's world, never the real level's. Measured by the build (D46.4), never invented; a later change is a
/// STOP unless a task marked ◈ names this golden. A missing data file is a FAILURE, never a skip.
final class FeatureGoldenTests: XCTestCase {

    /// 6A-S8: level 10's fixture (`HorizonStripTests.level10`, 31 records left out), the player started at
    /// `HorizonStripTests.stripStart` (600, 1150) (the header's start never shows the strip), seed 1, `FerazelPrefs()` — the
    /// first presented frame in which the horizon strip changed a frame byte inside the view (`HorizonStripTests
    /// .firstStripFrame`). Kept at 6A-L10L11; 6A-WD may move it (◈: wind cells in the frame).
    func testLevel10StripFeatureGolden() throws {
        let (run, services) = try LevelFixtureServices.open(level: 10, leaveOut: HorizonStripTests.level10,
                                                            start: HorizonStripTests.stripStart)
        let f = try HorizonStripTests.firstStripFrame(run, services)
        // The same tick run plainly (no split sprite pass) gives the same screen.
        let (plain, plainServices) = try LevelFixtureServices.open(level: 10, leaveOut: HorizonStripTests.level10,
                                                            start: HorizonStripTests.stripStart)
        var now: UInt32 = 0
        while now < f.ticks { _ = try plainServices.step(plain, now: now); now += 1 }
        let r = try XCTUnwrap(plainServices.renderer)
        XCTAssertEqual(LevelFixtureServices.fnv1a(r.screen.pixels), f.fnv)
        XCTAssertGreaterThan(f.changed, 0)
        // Measured at 6A-S8 (FNV-1a 64 of the 640×480 screen indices after that tick's level draws, the test colour
        // model): the first presented frame — the first `.GameLoop` iteration, after level 10's chapter card — on the
        // 1,612th tick (now 1611).
        XCTAssertEqual(run.iterations, 1)
        XCTAssertEqual(f.changed, 9526, "the frame bytes the strip changed in view")
        XCTAssertEqual(f.ticks, 1612)
        XCTAssertEqual(String(f.fnv, radix: 16), "e471fa3eeca627d3", "the level-10 strip feature golden")
    }
}
