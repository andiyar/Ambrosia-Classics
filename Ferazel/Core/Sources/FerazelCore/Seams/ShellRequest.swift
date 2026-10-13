import Foundation

/// What the original asked of the Mac outside the game screen (`HideCursorSafe`, the menu bar) — plan S3, LOCKED.
public enum ShellRequest: Equatable, Sendable {
    case hideCursor
    case showCursor
    case hideMenuBar
    case showMenuBar
    /// W4 (◇ `LevelFlow`, D33): load level n — the shell rebuilds the session with the old one's `rngSeed` and
    /// `carry`, and the renderer. A level exit asks for the level it unlocks (Phase 2: 1…2, else the current level);
    /// `FerazelSession.deathEffectDone()` asks for the current level.
    case loadLevel(Int)
    /// W4: the game loop ended with G+4 < 1 (M l. 5302–5306) — run `.DeathEffect` (E2's `DeathEffect.frame(step:on:)`),
    /// then call `FerazelSession.deathEffectDone()`.
    case deathEffect
}
