import Foundation

/// Mode 5's draw-time randoms (`.BlitEncFaceDiffuse @ 10029988` / `.BlitEncFaceFlipDiffuse @ 10029c6c`, draw-effects
/// §2.3): advance `rng` — the game's one stream — by exactly the `FastRand(30)` / `FastRand(6)` calls the renderer's
/// draw of `draw` at scroll (h, v) makes (one `FastRand(30)` per drawn literal pixel, in token order, and a
/// `FastRand(6)` after each one below n). FerazelRender's `SpriteBlitter.diffuseRandoms` walks the same pixels its
/// draw walks.
public typealias DiffuseRandoms = @Sendable (_ draw: SpriteDraw, _ h: Int, _ v: Int, _ rng: inout FastRand) -> Void

/// SP: the same walk at the renderer's own state for that `.WrapDrawSprites` — the scroll point (h, v) its blits clip
/// and wrap at (`.WrapDrawFace` reads `PTR_DAT_1009fe78`, M l. 10641–10664) and the grid's drawn location (drawnH,
/// drawnV) its cull offsets by (`_DAT_1009fe74/fe70`, `.WrapDrawSprites` M l. 10255–10256, 10259–10264), exactly as
/// the renderer holds them when it draws the op (`FerazelSession` tracks them from the scroll ops it emits). A session
/// given this uses it and ignores `DiffuseRandoms` (plan S3: added, not retyped).
public typealias DiffuseRandomsAt = @Sendable (_ draw: SpriteDraw, _ h: Int, _ v: Int, _ drawnH: Int, _ drawnV: Int,
                                               _ rng: inout FastRand) -> Void

/// What a session takes from the renderer side when a level opens (plan S2, L1): a face's opaque bounds (`face +8`,
/// `.ActiveToIdleSprite`), the face pixels the particle emitters walk, and the mode-5 draw walk (`DiffuseRandoms`;
/// SP: `DiffuseRandomsAt`, preferred when set). Nil bounds / empty faces / no walk = the session's defaults (each
/// face's frame rect; no particles; mode-5 draws take no randoms) — what Core tests use.
public struct LevelFaces {
    public var faceBounds: ((FaceRef) -> IdleSprites.Rect)?
    public var particleFaces: ParticleFaces
    public var diffuseRandoms: DiffuseRandoms?
    /// SP: the walk at the renderer's scroll point and drawn pair (`FrameRenderer.diffuseRandomsAt`).
    public var diffuseRandomsAt: DiffuseRandomsAt?

    public init(faceBounds: ((FaceRef) -> IdleSprites.Rect)? = nil, particleFaces: ParticleFaces = ParticleFaces(),
                diffuseRandoms: DiffuseRandoms? = nil, diffuseRandomsAt: DiffuseRandomsAt? = nil) {
        self.faceBounds = faceBounds
        self.particleFaces = particleFaces
        self.diffuseRandoms = diffuseRandoms
        self.diffuseRandomsAt = diffuseRandomsAt
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
