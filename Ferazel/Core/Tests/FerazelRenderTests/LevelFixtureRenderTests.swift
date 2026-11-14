import XCTest
@testable import FerazelCore
@testable import FerazelRender

/// 6A-FX (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-FX`, "Verification-model additions for 6A"):
/// the level fixture with face pixels — level 21 with its 30 refused records left out (`LevelFixture.level21`), opened
/// through `LevelRun` with `LevelFixtureServices` (the renderer on the same patched resources). The frame golden is a
/// FIXTURE golden ("New goldens are new values, not moves"): it pins the fixture's world, never the real level's. A
/// missing data file is a FAILURE, never a skip.
final class LevelFixtureRenderTests: XCTestCase {

    /// Opens the fixture (`LevelFixtureServices.open`) and runs it to its first presented frame
    /// (`LevelFixtureServices.firstPresentedFrame`, which defines it).
    private func firstFrame(seed: Int32) throws -> (r: FrameRenderer, run: LevelRun, services: LevelFixtureServices,
                                                    fnv: UInt64, tick: UInt32) {
        let (run, services) = try LevelFixtureServices.open(level: 21, leaveOut: LevelFixture.level21, seed: seed)
        let f = try services.firstPresentedFrame(run)
        return (f.renderer, run, services, f.fnv, f.ticks)
    }

    func testLevelFixtureOpensLevel21WithFaces() throws {
        let base = try LevelFixture.base.get()
        let real = try LevelFile.load(from: base, level: 21)
        let out = try LevelFixture.leftOut(real, LevelFixture.level21)
        XCTAssertEqual(out.count, 30, "the 30 refused records")

        let a = try firstFrame(seed: 1)
        // The renderer was made from the same patched level the run opened.
        // (Compared as Bools with the first differing byte offsets: a whole-level XCTAssertEqual prints ~1 MB.)
        let mine = try XCTUnwrap(a.services.resources.world.resource(type: "Mlvl", id: 21)).data
        let runs = try XCTUnwrap(a.run.resources.world.resource(type: "Mlvl", id: 21)).data
        let firstDiffs = LevelFixture.firstDifferences(mine, runs)
        XCTAssertTrue(a.r.level == a.run.levelFile, "the renderer's level is the run's; their Mlvl bytes first differ at \(firstDiffs)")
        XCTAssertTrue(mine == runs, "one patched data set; the Mlvl bytes first differ at \(firstDiffs)")
        XCTAssertEqual(a.r.prefs, a.run.prefs, "the renderer has the run's prefs")
        // ... and passed prefs reach the renderer (the level setup's `prepare` alone, no tick: ~4.5 s).
        var prefs = FerazelPrefs()
        prefs.musicVolume = 3
        let (_, other) = try LevelFixtureServices.open(level: 21, leaveOut: LevelFixture.level21, prefs: prefs)
        _ = try other.prepare(level: 21)
        XCTAssertEqual(other.renderer?.prefs, prefs)
        XCTAssertEqual(a.r.level.activePlacements.count, 325 - 30)
        XCTAssertTrue(out.allSatisfy { a.r.level.placements[$0].flag == 0 })

        // Faces for the active placements only: the store holds exactly the sheets `FrameRenderer` derives from the
        // patched level's active placements ...
        let context = SetupFaces.Context(level: a.r.level, playerX: SetupFaces.Context.levelStartPlayerX(a.r.level.header),
                                         effects: FerazelPrefs().effects)
        let entries = try a.r.level.activePlacements.map { try SetupFaces.setup($0, context: context) }
        let wanted = FrameRenderer.spriteSheets(level: a.r.level, entries: entries, resources: base)
        let held = Set(a.r.sprites.faces.sheets.keys)
        XCTAssertEqual(held, Set(wanted.map(\.pict)))
        XCTAssertEqual(held.count, 231)
        // ... and none for a left-out one: the level-load cache faces the left-out types mark on level 21 (LL §4
        // "Level 21" item 6 — singles #6–#9, #32, #36, #38, #39, #41, #67, #81, #118, each the type's own PICT; 1061 marks
        // none) are not loaded — written out from the ledger, since the port's mark table holds no unbuilt type.
        let leftOutFaces: Set<Int16> = [1490, 1491, 1492, 1493, 2827, 2831, 2833, 2834, 2836, 2850, 2921, 2962]
        XCTAssertEqual(leftOutFaces, Set(out.map { real.placements[$0].type }).subtracting([1061]))
        XCTAssertTrue(held.isDisjoint(with: leftOutFaces), "no face for a left-out record: \(held.intersection(leftOutFaces).sorted())")
        XCTAssertTrue(a.r.sprites.faces.recordSheets.keys.allSatisfy { !leftOutFaces.contains(CachedFaces.record($0).pict) })

        // The first presented frame drew with no refusal (`firstPresentedFrame` throws on one): the first `.GameLoop`
        // iteration, on the 143rd tick (now 142). Two openings with one seed give the same frame — pinned, measured at
        // 6A-FX (a fixture golden: FNV-1a 64 of the 640×480 screen indices after that tick's level draws; seed 1,
        // `FerazelPrefs()`).
        XCTAssertEqual(a.run.iterations, 1)
        XCTAssertEqual(a.tick, 143)
        let b = try firstFrame(seed: 1)
        XCTAssertEqual(b.tick, a.tick)
        XCTAssertEqual(b.fnv, a.fnv)
        XCTAssertEqual(String(a.fnv, radix: 16), "fb80e30a68e4efb7", "the level-21 fixture's first presented frame")
    }
}
