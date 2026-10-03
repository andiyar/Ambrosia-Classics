/// The session-wide assumptions the replica cannot read from the FILMs (plan Invariant 11). Every default is an
/// ASSUMPTION recorded in the plan, not a decision of the executor; changing one is Ben's call.
///
/// NOT `Equatable`: it holds an `@Sendable` closure, so a synthesized `==` cannot compile (plan review A2). If equality
/// is ever needed, hand-write `==` over the four non-closure fields.
public struct SessionConfig: Sendable {
    /// `_Get0To6` / `_Get13To22` latches, drawn once per process from `_Interface` before any game — from process
    /// seed 1: u = 1, L = 15 (Research note 4; NR-3 [LOW]).
    public var latches = SessionLatches.fromProcessSeedOne
    /// "Registered, valid licence" (INDEX Decision 2 — assumption). Feeds `RT3_IsRegistered` (hero `+0x3a`, the
    /// per-enemy `gREGCHECK1registered` flags) and `RT3_GetLicenseCode() != 0` (`gAIRegistered`, set by `_DrawMaze`).
    public var registeredValidLicence = true
    /// Bool prefs 0x35 (stars) and 0x36 (air bubbles), both ON — the shipped default (`_DoFXSuitabilityCheck @
    /// 0000f760`); whether they are exposed is Ben's call.
    public var prefs = CosmeticPrefs()
    /// `gPointsNotReg` (NR-4 — assumption: false).
    public var pointsNotRegistered = false
    /// The QuickDraw `Random()` step (Invariant 10: the single swappable place the LCG lives; suspect #1 on any
    /// FILM divergence).
    public var rngStep: GameRandom.Step = QuickDrawRandom.step

    public init() {}

    public init(latches: SessionLatches = .fromProcessSeedOne, registeredValidLicence: Bool = true,
                prefs: CosmeticPrefs = CosmeticPrefs(), pointsNotRegistered: Bool = false,
                rngStep: @escaping GameRandom.Step = QuickDrawRandom.step) {
        self.latches = latches
        self.registeredValidLicence = registeredValidLicence
        self.prefs = prefs
        self.pointsNotRegistered = pointsNotRegistered
        self.rngStep = rngStep
    }
}

/// `gGameMode`: 1 = demo (FILM playback) in the original; play covers live input. (Mode 2, recording, is not
/// modelled — the FILMs are only played back.)
public enum GameMode: Sendable {
    case play, demo
}
