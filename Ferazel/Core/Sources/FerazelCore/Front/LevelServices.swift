import Foundation

/// What a session takes from the renderer side when a level opens (plan S2, L1): a face's opaque bounds (`face +8`,
/// `.ActiveToIdleSprite`) and the face pixels the particle emitters walk. Nil bounds / empty faces = the session's
/// defaults (each face's frame rect; no particles) — what Core tests use.
public struct LevelFaces {
    public var faceBounds: ((FaceRef) -> IdleSprites.Rect)?
    public var particleFaces: ParticleFaces

    public init(faceBounds: ((FaceRef) -> IdleSprites.Rect)? = nil, particleFaces: ParticleFaces = ParticleFaces()) {
        self.faceBounds = faceBounds
        self.particleFaces = particleFaces
    }
}

/// How `LevelRun` opens a level on the renderer side (plan S2, L1) — the App's order today
/// (`FerazelController.openLevel`): build the per-level renderer (`prepare`, before the session exists: its
/// `faceBounds` / `particleFaces` go into `FerazelSession.init`), then hand it the session's lights and tint-table
/// draws (`attach`, right after the session init). Core tests pass a stub; the App (A1a) builds the per-level
/// `FrameRenderer` on the shared `ScreenSurface`.
public protocol LevelServices: AnyObject {
    /// Called once per level entry, at `.SetupLevel` (after `.PopupStageLoad`), before the session init.
    func prepare(level: Int) throws -> LevelFaces
    /// Called once, right after the session init: the Setup lights (`FrameRenderer.addLights`) and the 510 tint
    /// 0xa draws (`FrameRenderer.buildTintTable`).
    func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws
    /// `.DeathEffect @ 10005270`'s step k (0 … 49, M l. 2700–2735): paint the gray `patOr` and black bands of step k
    /// on the screen (`DeathEffect.frame(step:on:)` in FerazelRender) — the bands **only**: the step's
    /// `.HandleAsyncGammaFade` is `LevelRun`'s (its `gammaStep` op rides the tick's `FrontOutput`, gated as the binary
    /// gates it), so the renderer must not apply the gamma op `frame(step:on:)` returns.
    func deathEffectStep(_ k: Int) throws
}
