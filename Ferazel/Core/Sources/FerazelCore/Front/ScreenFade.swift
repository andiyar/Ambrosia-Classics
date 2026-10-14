import Foundation

/// The original's blocking gamma fades and their global state (plan S2, FE0; lighting-tables §10,
/// rendering-omnipx-titles §4.3 + BC16/BC28). Each fade is a `FrontTimeline` of `DrawOp.screenGamma` ops, one per tick
/// (Invariant 3: millisecond-timed Monitor-Tool fades take `ticks(milliseconds:)` ticks [MED: library internals]).
/// The flags change when the call is made — the flow is blocked until the timeline ends, so nothing reads them earlier.
public struct ScreenFade: Equatable, Sendable {
    /// `DAT_100a53c2`: fading enabled (data-section initial 1; `.main` clears it, M l. 8313).
    public var fadingEnabled = true
    /// `*_DAT_1009fde8`: the screen is faded out (bss, initial 0).
    public var faded = false
    /// `DAT_100a53d6`: no async fade running (data-section initial 1).
    public var noAsyncFade = true
    /// `_DAT_100a024c`: the colour `.GammaFadeOut` stores for the async fade (r6/r7 halves, raw `100353e4..10035404`).
    public var asyncColour = RGB16(0, 0, 0)

    public init() {}

    /// `ticks = ceil(ms · 60 / 1000)` (Invariant 3).
    public static func ticks(milliseconds ms: Int) -> Int {
        ms <= 0 ? 0 : (ms * 60 + 999) / 1000
    }

    /// `.GammaFadeOut(n)`'s `MT_FadeCustom` duration, in the binary's order (raw `10035338..100353c4`):
    /// m = `fctiwz(2.3 · n)` (2.3 @ `100a1940`), then the integer `extsh(m) · 0x37`, then × 0.7 (@ `100a1938`) truncated
    /// by `FUN_10090a64` (double → u32: negative → 0). n 3 → 230 (not 231), 6 → 500, 10 → 885, 12 → 1039, 30 → 2656.
    public static func fadeOutMilliseconds(_ n: Int) -> Int {
        let x = 2.3 * Double(Int16(truncatingIfNeeded: n))
        let m = Int16(truncatingIfNeeded: Int32(x.rounded(.towardZero)))
        let ms = 0.7 * Double(Int32(m) * 0x37)
        return ms < 0 ? 0 : Int(ms.rounded(.towardZero))
    }

    /// `.GammaFadeOut(n, rgb) @ 10035310` (M l. 31782–31803): when fading is enabled and the screen is not faded,
    /// `MT_FadeCustom(0, 100, ms, .TintFadeProc, 3)` — one `.tint(mode: 3, percent:)` per tick, percent =
    /// min(100, trunc(100 · elapsed / ms)) with elapsed = (k + 1) ticks [MED: `MT_FadeCustom`'s schedule is library
    /// code]; then the colour stored, `53d6 = 1`, faded. Otherwise nothing.
    public mutating func gammaFadeOut(_ n: Int, rgb: RGB16) -> FrontTimeline {
        guard fadingEnabled, !faded else { return .none }
        let ms = Self.fadeOutMilliseconds(n)
        let ticks = Self.ticks(milliseconds: ms)
        var events: [FrontTimeline.Event] = []
        if ticks == 0 {
            // ms 0: one immediate step at 100 % [MED].
            events.append(.init(at: 0, output: FrontOutput(draws: [.screenGamma(.tint(mode: 3, percent: 100))])))
        }
        for k in 0..<ticks {
            let pct = min(100, (k + 1) * 100_000 / (60 * ms))
            events.append(.init(at: k, output: FrontOutput(draws: [.screenGamma(.tint(mode: 3, percent: pct))])))
        }
        asyncColour = rgb
        noAsyncFade = true
        faded = true
        return FrontTimeline(events: events, duration: ticks)
    }

    /// The percents `.GammaFadeIn(n)` passes (M l. 31819–31840, raw `10035444..10035560`): p = 0, s, 2s … ≤ 100 with
    /// s = max(1, 100 / (3n)) (the short `3n`; s = 1 when 3n is 0 [LOW: a `divw` by 0, no caller]), each
    /// min(100, trunc(p · 3n / 100)). n 6 → 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 10 … 18 (BC16).
    public static func fadeInPercents(_ n: Int) -> [Int] {
        let n3 = Int(Int16(truncatingIfNeeded: n &* 3))
        let s = n3 == 0 ? 1 : max(1, 100 / n3)
        return stride(from: 0, through: 100, by: s).map { p in min(100, p * n3 / 100) }
    }

    /// `.GammaFadeIn(n) @ 10035444`: when enabled and faded, one `FadeToColor(nil, percent)` per tick (each waits one
    /// `TickCount`; compounding, `ScreenGamma.fade`), then `FadeToColor(nil, 100)`, `ShowCursorSafe` and faded cleared
    /// on the tick the block ends. Otherwise nothing.
    public mutating func gammaFadeIn(_ n: Int) -> FrontTimeline {
        guard fadingEnabled, faded else { return .none }
        let percents = Self.fadeInPercents(n)
        var events = percents.enumerated().map { k, p in
            FrontTimeline.Event(at: k, output: FrontOutput(draws: [.screenGamma(.fadeToColor(percent: p, rgb: nil))]))
        }
        events.append(.init(at: percents.count, output: FrontOutput(
            draws: [.screenGamma(.fadeToColor(percent: 100, rgb: nil))], requests: [.showCursor])))
        faded = false
        return FrontTimeline(events: events, duration: percents.count)
    }

    /// `.GammaFadeInSlow(n)`'s duration (M l. 31859–31862): ms = 33n (`n · 0x21`), replaced by 100 when below 0x65.
    public static func fadeInSlowMilliseconds(_ n: Int) -> Int {
        let ms = Int(Int16(truncatingIfNeeded: n)) * 0x21
        return ms < 0x65 ? 100 : ms
    }

    /// `.GammaFadeInSlow(n) @ 10035584`: when enabled and faded, `MT_FadeToColor(nil, 100, ms, 1)` — linear toward the
    /// original gamma over ms [MED: library `MT_FadeToColor`], emitted per tick as the compounding step that takes the
    /// fade from fraction f(k) to f(k+1) = min(1, (k + 1) ticks / ms) — then `FadeToColor(nil, 100, 0)` and faded
    /// cleared on the tick the block ends (no `ShowCursorSafe`). n 0x37 → 1815 ms → 109 ticks.
    public mutating func gammaFadeInSlow(_ n: Int) -> FrontTimeline {
        guard fadingEnabled, faded else { return .none }
        let ms = Self.fadeInSlowMilliseconds(n)
        let ticks = Self.ticks(milliseconds: ms)
        var events: [FrontTimeline.Event] = []
        var before = 0.0
        for k in 0..<ticks {
            let f = min(1.0, Double((k + 1) * 1000) / Double(60 * ms))
            let pct = before >= 1 ? 100 : Int((100 * (f - before) / (1 - before)).rounded(.towardZero))
            events.append(.init(at: k, output: FrontOutput(draws: [.screenGamma(.fadeToColor(percent: pct, rgb: nil))])))
            before = f
        }
        events.append(.init(at: ticks, output: FrontOutput(draws: [.screenGamma(.fadeToColor(percent: 100, rgb: nil))])))
        faded = false
        return FrontTimeline(events: events, duration: ticks)
    }
}
