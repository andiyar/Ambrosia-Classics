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

    /// 6A-L15: level 15 "Storm Valley" — no chapter card; the first presented frame, the backdrop replaced by the two
    /// rain sheets (OmniPx mode 1, 6000 / 6001). It is 6A-RN's frame 1 on the same world (that fixture left nothing out,
    /// and this open is the fixture's: `LevelFixture.open` on the data set itself), and it supersedes 6A-RN's rain
    /// feature golden (ENG §2.7), whose pins it carries with their twins (D54.2): frame 1 shows the sheets — the twin
    /// without the `.UpdateOmniPx` ops differs — and no drop (a drop is made at age 0 and `.DrawParticles` draws only
    /// ages > 0, M l. 29787: the twin without the rain particles is the same picture); frame 2 is the first with drops.
    func testLevel15FirstFrameGolden() throws {
        let f = try Self.firstFrame(level: 15)
        try checkShowsLevel(f, 15)
        XCTAssertEqual(f.run.levelFile.header.chapter, 0)
        XCTAssertEqual(f.run.levelFile.header.omniPxMode, 1)
        // Measured at 6A-L15 (seed 1): the 143rd tick (now 142), no card, the camera at (0, 1018) — the same value
        // as 6A-RN's frame 1: the opening paths agree (the level runner, no chapter or stage screen before it).
        XCTAssertEqual(f.ticks, 143)
        XCTAssertEqual([f.scroll.h, f.scroll.v], [0, 1018])
        XCTAssertEqual(String(f.fnv, radix: 16), "49eddc24d9989d95", "the level-15 first-frame golden (6A-RN's frame 1)")
        let plain = try FeatureGoldenTests.level15Frames(count: 2, dropRain: false)
        let noDrops = try FeatureGoldenTests.level15Frames(count: 2, dropRain: true)
        let noSheets = try FeatureGoldenTests.level15Frames(count: 1, dropRain: false, dropOmniPx: true)
        XCTAssertEqual(plain.map(\.ticks), [143, 145])
        XCTAssertEqual(noDrops.map(\.ticks), [143, 145])
        XCTAssertEqual(plain[0].fnv, f.fnv, "the fixture helper's frame 1 is this frame")
        XCTAssertNotEqual(noSheets[0].fnv, f.fnv, "frame 1 shows the rain sheets")
        XCTAssertEqual(String(noSheets[0].fnv, radix: 16), "75d168572f6f029c", "measured: frame 1 without the sheets")
        XCTAssertEqual([plain[0].rain, plain[1].rain], [0, 15], "frame 1 no drop drawn; frame 2 the first call's five")
        XCTAssertEqual(plain[0].fnv, noDrops[0].fnv, "frame 1 shows no drop")
        XCTAssertNotEqual(plain[1].fnv, noDrops[1].fnv, "frame 2 shows the drops")
        XCTAssertEqual(String(noDrops[1].fnv, radix: 16), "b8b5b520071e980e", "frame 2 with the drops taken out (6A-RN)")
        XCTAssertEqual(String(plain[1].fnv, radix: 16), "343813c4727ef0e0", "the rain picture, frame 2 (6A-RN)")
    }
}
