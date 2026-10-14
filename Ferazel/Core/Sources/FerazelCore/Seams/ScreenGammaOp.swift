import Foundation

/// A Monitor-Tool change of the screen gamma (plan S3, FE0; LOCKED; lighting-tables §10). Presentation only: the 8-bit
/// screen and every table are unchanged.
public enum ScreenGammaOp: Equatable, Sendable {
    /// One tick of `MT_FadeCustom(0, 100, ms, .TintFadeProc, mode)` at `percent` (`.GammaFadeOut`): the **unfaded**
    /// gamma scaled per channel by `.TintFadeProc @ 10034f40` (mode 3: red first, then green, blue last).
    case tint(mode: Int, percent: Int)
    /// `MT_FadeToColor(rgb, percent, 0, 1)`: the current gamma moved `percent` toward `rgb` (nil = the original gamma),
    /// compounding (`.GammaFadeIn`, `.GammaFadeInSlow`).
    case fadeToColor(percent: Int, rgb: RGB16?)
    /// The original gamma (`MT_FadeToColor(nil, 100, 0, 1)` from any state).
    case identity
    /// `SetEntries` of the whole screen CLUT (`.TurnGray`, D1).
    case clut(entries: [RGB16])
}
