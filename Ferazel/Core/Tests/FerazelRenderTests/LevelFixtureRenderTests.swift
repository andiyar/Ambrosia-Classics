import XCTest
@testable import FerazelCore
@testable import FerazelRender

/// 6A-FX (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-FX`, "Verification-model additions for 6A"):
/// the level fixture with face pixels — level 21 with its 30 refused records left out (`LevelFixture.level21`), opened
/// through `LevelRun` with `LevelFixtureServices` (the renderer on the same patched resources). The frame golden is a
/// FIXTURE golden ("New goldens are new values, not moves"): it pins the fixture's world, never the real level's. A
/// missing data file is a FAILURE, never a skip.
final class LevelFixtureRenderTests: XCTestCase {

    private func fnv1a(_ bytes: [UInt8]) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for b in bytes { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        return h
    }

    /// Opens the fixture and ticks it, executing each tick's `.level` segments on the level's renderer (as
    /// `GoblinBurnLevelRunTests` does), until the first presented level frame — the first tick whose level draws copy
    /// the frame port to the screen (`.copyToScreen`, the first drawn `.GameLoop` iteration). Returns the renderer, the
    /// run, and the FNV-1a 64 of the 640×480 screen indices after that tick.
    private func firstFrame(seed: Int32) throws -> (r: FrameRenderer, run: LevelRun, services: LevelFixtureServices,
                                                    fnv: UInt64, tick: UInt32) {
        let res = try LevelFixture.resources(level: 21, leaveOut: LevelFixture.level21)
        let services = LevelFixtureServices(resources: res)
        let run = try LevelFixture.open(level: 21, leaveOut: LevelFixture.level21, services: services, seed: seed)
        var t: UInt32 = 0
        while t < 4000 {
            let out = try run.tick(now: t, input: FrontInput())
            t &+= 1
            var copied = false
            for g in out.segments where g.target == .level {
                let r = try XCTUnwrap(services.renderer, "the level's renderer exists before its first draw")
                do { try r.apply(FrameOps(draws: g.output.draws)) } catch {
                    XCTFail("tick \(t): the renderer refused: \(error)")
                    throw error
                }
                copied = copied || g.output.draws.contains { if case .copyToScreen = $0 { return true }; return false }
            }
            if copied {
                let r = try XCTUnwrap(services.renderer)
                return (r, run, services, fnv1a(r.screen.pixels), t)
            }
        }
        XCTFail("no presented level frame within 4000 ticks")
        throw XCTSkip("unreachable")
    }

    func testLevelFixtureOpensLevel21WithFaces() throws {
        let base = try LevelFixture.base.get()
        let real = try LevelFile.load(from: base, level: 21)
        let out = try LevelFixture.leftOut(real, LevelFixture.level21)
        XCTAssertEqual(out.count, 30, "the 30 refused records")

        let a = try firstFrame(seed: 1)
        // The renderer was made from the same patched level the run opened.
        XCTAssertEqual(a.r.level, a.run.levelFile)
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

        // The first presented frame drew with no refusal (`firstFrame` fails on one): the first `.GameLoop` iteration,
        // at tick 143. Two openings with one seed give the same frame — pinned, measured at 6A-FX (a fixture golden:
        // FNV-1a 64 of the 640×480 screen indices after that tick's level draws; seed 1, `FerazelPrefs()`).
        XCTAssertEqual(a.run.iterations, 1)
        XCTAssertEqual(a.tick, 143)
        let b = try firstFrame(seed: 1)
        XCTAssertEqual(b.tick, a.tick)
        XCTAssertEqual(b.fnv, a.fnv)
        XCTAssertEqual(String(a.fnv, radix: 16), "fb80e30a68e4efb7", "the level-21 fixture's first presented frame")
    }
}
