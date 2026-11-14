import Foundation
@testable import FerazelCore
@testable import FerazelRender

/// 6A-FX: the level fixture's renderer side (the plan's "Verification-model additions for 6A"). `LevelServices` in the
/// shape of `FerazelDriver.prepare` / `attach` (`Ferazel/Shared/FerazelDriver.swift`; the
/// `GoblinBurnLevelRunTests.Services` shape): the level's renderer made at `prepare` from the **same** patched
/// resources the run opens (`open` builds them once) — `FrameRenderer.init` runs `SetupFaces` on that level's active
/// placements, so a left-out record loads no face — then its lights and tint table at `attach`. So the Render tests
/// (goldens, burns) open the fixture with face pixels.
///
/// Where it differs from the driver's, on purpose: the colour search is the Render tests' `.ruled` / `.lowest` (the
/// driver's is `.exactNearest` with the settings' tie-break, `.highest` by default), so fixture goldens sit under the
/// test colour model with the other Render goldens; text goes through `StatusBarTests.BoxRasterizer`; the renderer
/// keeps its own screen (no `surface:`); there is no `ConversationRenderer`; the prefs are fixed when it is made (the
/// driver passes the live toggles); and `deathEffectStep` does nothing (the driver paints the death wipe's bands), so
/// a fixture test through a player death sees no wipe.
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

    /// The fixture opened with face pixels: the patched resources built ONCE and handed to both the run and its
    /// renderer, and the run's `prefs` given to the renderer — so the two can never read different levels or prefs.
    static func open(level: Int, leaveOut: [LevelFixture.LeaveOut], header: [LevelFixture.HeaderPatch] = [],
                     start: (x: Int, y: Int)? = nil, prefs: FerazelPrefs = FerazelPrefs(),
                     carry: LevelCarry = LevelCarry(),
                     seed: Int32 = 1) throws -> (run: LevelRun, services: LevelFixtureServices) {
        let res = try LevelFixture.resources(level: level, leaveOut: leaveOut, header: header)
        let services = LevelFixtureServices(resources: res, prefs: prefs)
        let run = try LevelFixture.open(resources: res, level: level, start: start, prefs: prefs, carry: carry,
                                        services: services, seed: seed)
        return (run, services)
    }

    /// Why `step` or `firstPresentedFrame` stopped: a fixture test fails on it, never skips.
    struct FrameFailure: Error, CustomStringConvertible {
        /// The `now` of the tick that failed.
        let now: UInt32
        let description: String
        /// The run's or the renderer's own error, when one was thrown.
        var underlying: Error? = nil
    }

    /// Ticks `run` once at `now` and executes that tick's `.level` segments, in order, on the level's renderer (the
    /// `GoblinBurnLevelRunTests` loop). Returns true when the tick presented a frame: its `.level` draws hold a
    /// `.copyToScreen` (the frame port copied to the screen). Throws `FrameFailure` when the run refuses (named by
    /// record through `LevelFixture.describe`), when a level draw comes before the renderer exists, or when the renderer
    /// refuses a draw.
    func step(_ run: LevelRun, now: UInt32, input: FrontInput = FrontInput()) throws -> Bool {
        let out: LevelRunOutput
        do { out = try run.tick(now: now, input: input) } catch {
            throw FrameFailure(now: now, description: "tick now \(now): the run refused: "
                               + LevelFixture.describe(error, level: run.levelFile), underlying: error)
        }
        var presented = false
        for g in out.segments where g.target == .level {
            guard let r = renderer else {
                throw FrameFailure(now: now, description: "tick now \(now): a level draw before the renderer exists")
            }
            do { try r.apply(FrameOps(draws: g.output.draws)) } catch {
                throw FrameFailure(now: now, description: "tick now \(now): the renderer refused: \(error)",
                                   underlying: error)
            }
            presented = presented || g.output.draws.contains { if case .copyToScreen = $0 { return true }; return false }
        }
        return presented
    }

    /// The **first presented frame** of a run just opened (nothing ticked yet): `step` from `now` 0, one `FrontInput()`
    /// a tick, `now` + 1 each tick, until the first tick that presents (its `.level` draws hold a `.copyToScreen`) — on
    /// a freshly opened level, the first drawn `.GameLoop` iteration (`run.iterations == 1`). Returns `ticks`, the ticks
    /// run including that one (its `now` is `ticks − 1`); the renderer; and `fnv`, the FNV-1a 64 of the renderer's
    /// 640×480 screen **indices** after that tick's draws — palette- and gamma-blind, not the presented RGBA the Windows
    /// level references hash. Throws `FrameFailure` on a refusal, or when no frame is presented within `limit` ticks.
    func firstPresentedFrame(_ run: LevelRun, limit: UInt32 = 4000) throws
        -> (ticks: UInt32, renderer: FrameRenderer, fnv: UInt64) {
        var now: UInt32 = 0
        while now < limit {
            let presented = try step(run, now: now)
            now &+= 1
            if presented, let r = renderer { return (now, r, Self.fnv1a(r.screen.pixels)) }
        }
        throw FrameFailure(now: now, description: "no presented level frame within \(limit) ticks")
    }

    /// FNV-1a 64 (the frame goldens' hash).
    static func fnv1a(_ bytes: [UInt8]) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for b in bytes { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        return h
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
