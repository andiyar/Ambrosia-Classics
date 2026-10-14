import Foundation

/// A Monitor-Tool change of the screen gamma (plan S3, FE0; LOCKED; lighting-tables §10). Presentation only: the 8-bit
/// screen and every table are unchanged.
public enum ScreenGammaOp: Equatable, Sendable {
    /// One tick of `MT_FadeCustom(0, 100, ms, .TintFadeProc, mode)` at `percent` (`.GammaFadeOut`): the **unfaded**
    /// gamma scaled per channel by `.TintFadeProc @ 10034f40` (mode 3: red first, then green, blue last).
    case tint(mode: Int, percent: Int)
    /// `MT_FadeToColor(rgb, percent, 0, 1)`: the current gamma moved `percent` toward `rgb` (nil = the original gamma),
    /// compounding (`.GammaFadeIn`, the slow fade's closing snap).
    case fadeToColor(percent: Int, rgb: RGB16?)
    /// Tick `tick` (0-based) of one timed `MT_FadeToColor(rgb, 100, milliseconds, 1)` (`.GammaFadeInSlow`): the gamma
    /// the call started from (captured at tick 0 — the library clones the current gamma, lighting-tables §10) moved the
    /// **absolute** fraction min(1, (tick + 1) ticks / ms) toward `rgb` — linear, non-compounding [MED: library
    /// `MT_FadeToColor`]. Added in the Phase 3 run-2 review fixes: neither `.tint` (per-channel `.TintFadeProc` factors
    /// of the unfaded gamma, so only a black start) nor the integer-percent compounding `.fadeToColor` (floored steps:
    /// 0 % for ticks 0–8 at n 0x37) can express it; the faded start may be a colour (`.GammaFadeOutAsync`).
    case timedFadeToColor(tick: Int, milliseconds: Int, rgb: RGB16?)
    /// The original gamma (`MT_FadeToColor(nil, 100, 0, 1)` from any state).
    case identity
    /// `SetEntries` of the whole screen CLUT (`.TurnGray`, D1).
    case clut(entries: [RGB16])
}
