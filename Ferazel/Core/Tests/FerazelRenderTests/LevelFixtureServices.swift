import Foundation
@testable import FerazelCore
@testable import FerazelRender

/// 6A-FX: the level fixture's renderer side (the plan's "Verification-model additions for 6A"). The `LevelServices`
/// built as `FerazelDriver.prepare` / `attach` build them (`Ferazel/Shared/FerazelDriver.swift`; the
/// `GoblinBurnLevelRunTests.Services` shape), the renderer made from the **same** patched resources the fixture opens
/// (`LevelFixture.resources`) — `FrameRenderer.init` runs `SetupFaces` on that level's active placements, so a left-out
/// record loads no face — so the Render tests (goldens, burns) open the fixture with face pixels.
final class LevelFixtureServices: LevelServices {
    let resources: FerazelResources
    let prefs: FerazelPrefs
    /// The level's renderer, made at `prepare` (`.SetupLevel`).
    private(set) var renderer: FrameRenderer?

    /// - Parameters:
    ///   - resources: the fixture's patched resources (`LevelFixture.resources(level:leaveOut:header:)`).
    ///   - prefs: the prefs the run is opened with (the renderer's parallax and Effects).
    init(resources: FerazelResources, prefs: FerazelPrefs = FerazelPrefs()) {
        self.resources = resources
        self.prefs = prefs
    }

    func prepare(level: Int) throws -> LevelFaces {
        let r = try FrameRenderer(resources: resources, level: level, search: ColorSearch(model: .ruled, tieBreak: .lowest),
                                  dither: .errorDiffusion, text: StatusBarTests.BoxRasterizer(), prefs: prefs)
        renderer = r
        return LevelFaces(faceBounds: r.faceBounds, particleFaces: r.particleFaces, diffuseRandoms: r.diffuseRandoms,
                          diffuseRandomsAt: r.diffuseRandomsAt)
    }

    func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {
        guard let r = renderer else { throw FrameRenderer.Refusal.tintTableNotBuilt }
        try r.addLights(lights)
        try r.buildTintTable(tintTableDraws)
    }

    func deathEffectStep(_ k: Int) throws {}
}
