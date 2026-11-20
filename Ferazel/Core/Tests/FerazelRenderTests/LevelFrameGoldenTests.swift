import XCTest
@testable import FerazelCore
@testable import FerazelRender

/// The 6A level first-frame goldens (docs/superpowers/plans/2026-11-04-ferazel-remainder.md, "Verification-model
/// additions for 6A": "New goldens are new values, not moves"): each level task pins its level's first presented frame
/// on the **real** level — the committed data unpatched, opened through the level runner (`LevelFixture.open` on the
/// data set itself, nothing left out) with the fixture's renderer side (`LevelFixtureServices`: the Render tests'
/// colour model, FNV-1a 64 of the 640×480 screen indices). Measured by the build (D46.4), never invented; a later
/// change is a STOP. The Windows references of the same frames are `WinLevelReferenceTests` (presented RGBA through
/// the Windows shell). A missing data file is a FAILURE, never a skip.
final class LevelFrameGoldenTests: XCTestCase {

    /// The real level `level`, seed 1, `FerazelPrefs()`, the header's start: its first presented frame
    /// (`LevelFixtureServices.firstPresentedFrame`), the run, and the camera's scroll after it.
    static func firstFrame(level: Int) throws
        -> (ticks: UInt32, fnv: UInt64, run: LevelRun, renderer: FrameRenderer, scroll: (h: Int, v: Int)) {
        let res = try LevelFixture.base.get()
        let services = LevelFixtureServices(resources: res)
        let run = try LevelFixture.open(resources: res, level: level, services: services)
        let f = try services.firstPresentedFrame(run)
        let s = try XCTUnwrap(run.session)
        return (f.ticks, f.fnv, run, f.renderer, (s.camera.scrollH, s.camera.scrollV))
    }

    /// Checks the frame shows the level: the first `.GameLoop` iteration, the player on screen inside the 640 × 416
    /// view, and the frame not one colour.
    private func checkShowsLevel(_ f: (ticks: UInt32, fnv: UInt64, run: LevelRun, renderer: FrameRenderer,
                                       scroll: (h: Int, v: Int)), _ level: Int) throws {
        XCTAssertEqual(f.run.iterations, 1, "level \(level): the first loop iteration")
        let s = try XCTUnwrap(f.run.session)
        let p = try XCTUnwrap(s.world.playerID.flatMap { s.world.active.record(id: $0) })
        let sx = p.x - f.scroll.h, sy = p.y - f.scroll.v
        XCTAssertTrue((0..<640).contains(sx) && (0..<416).contains(sy), "level \(level): the player in view (\(sx), \(sy))")
        XCTAssertGreaterThan(Set(f.renderer.screen.pixels).count, 16, "level \(level): a level picture, not a card")
    }

    /// 6A-L10L11: level 10 "Unemployed In Greenland" — the first presented frame comes after chapter card 2 (the
    /// card's own golden is `ScreenTests.testChapterCard2FrameGolden`). No horizon strip pixel is in this frame (from
    /// the header's start none appears in 6,000 ticks — 6A-S8); `FeatureGoldenTests.testLevel10StripFeatureGolden`
    /// stays the strip's picture.
    func testLevel10FirstFrameGolden() throws {
        let f = try Self.firstFrame(level: 10)
        try checkShowsLevel(f, 10)
        // Measured at 6A-L10L11 (seed 1): the 1,612th tick (now 1611) — ticks 1…1,611 are the chapter card, as on the
        // strip fixture (6A-S8) — with the camera at (0, 634).
        XCTAssertEqual(f.run.levelFile.header.chapter, 2)
        XCTAssertEqual(f.ticks, 1612)
        XCTAssertEqual([f.scroll.h, f.scroll.v], [0, 634])
        XCTAssertEqual(String(f.fnv, radix: 16), "e76116216b6d605", "the level-10 first-frame golden")
    }

    /// 6A-L10L11: level 11 "River of Fears" — no chapter card; the first presented frame. Its view does not reach the
    /// river band (D53.1: from the header's start the camera never shows a backdrop row ≥ 512), so the ripple is not
    /// in it; `FeatureGoldenTests.testLevel11RippleFeatureGolden` stays the ripple's picture.
    func testLevel11FirstFrameGolden() throws {
        let f = try Self.firstFrame(level: 11)
        try checkShowsLevel(f, 11)
        // Measured at 6A-L10L11 (seed 1): the 143rd tick (now 142), no card, the camera at (15744, 31) — the view's
        // rows 31…414 stay below the river band's 512 (yb 256: backdrop rows track the view 1:1).
        XCTAssertEqual(f.run.levelFile.header.chapter, 0)
        XCTAssertEqual(f.ticks, 143)
        XCTAssertEqual([f.scroll.h, f.scroll.v], [15744, 31])
        XCTAssertLessThan(f.scroll.v + 383, 0x200, "no ripple row in view")
        XCTAssertEqual(String(f.fnv, radix: 16), "5d78b001424a6898", "the level-11 first-frame golden")
    }
}
