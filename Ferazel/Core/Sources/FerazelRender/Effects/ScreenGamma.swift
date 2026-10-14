import Foundation
import FerazelCore

/// The screen's gamma as the Monitor Tool leaves it (lighting-tables §10): every game fade goes through
/// `MT_FadeToColor(dev, color, pct, ms, 1) @ 10093304`, which clones the **current** gamma and blends
/// `cur = start + f·(target − start)` toward the saved original (color = nil) or `ColorGamma(color)`, f = pct / 100 —
/// one immediate step when ms = 0, as every async step calls it. Repeated steps therefore compound.
///
/// Modelled per channel as an affine map of the 16-bit CLUT value, `out = gain·v + offset`: the original gamma is
/// the identity (gain 1, offset 0); `ColorGamma(color)` the constant `color` (gain 0, offset = the channel), so every
/// blend stays affine. The result is truncated toward zero and clamped to 0…0xFFFF. [MED: the Monitor Tool's ramp
/// resolution and rounding are library code, lighting-tables NOT RESOLVED 8; `ColorGamma` as a flat ramp is the
/// reading of "fade to colour".] Presentation only: the 8-bit screen and every table are unchanged.
/// Not modelled: the async fades' gates (`DAT_100a53c2` gamma available, `*_DAT_1009fde8` faded-out flag set by the
/// fade-out's end and cleared by the fade-in's, `.HandleAsyncGammaFade` raw `100357b0..100357c8`) — a step is always
/// taken; under compounding a repeated fade toward the state already reached is a no-op [MED].
public struct ScreenGamma: Sendable, Equatable {
    /// Per channel (R, G, B): `out = gain·v + offset`.
    public private(set) var gain: [Double] = [1, 1, 1]
    public private(set) var offset: [Double] = [0, 0, 0]

    /// The original gamma.
    public static let identity = ScreenGamma()

    public init() {}

    /// One `.HandleAsyncGammaFade @ 10035788` step: `MT_FadeToColor(toward, numerator·100 / denominator, 0, 1)` — the
    /// percentage is the C integer quotient (`(j·100) / N`, raw `100357d8..10035800`); `toward` nil = the original
    /// gamma (`.GammaFadeInAsync`), else the fade-out colour (`.GammaFadeOutAsync(N, rgb)`, the RGB at `100a024c`).
    /// A denominator of 0 (a `divw` by zero, undefined on PowerPC) is taken as pct 0 [LOW: no caller passes it].
    public mutating func step(numerator: Int, denominator: Int, toward: RGB16?) {
        let n = Int32(truncatingIfNeeded: numerator) &* 100, d = Int32(truncatingIfNeeded: denominator)
        let pct = d == 0 ? 0 : Int(n.dividedReportingOverflow(by: d).partialValue)
        fade(toward: toward, percent: pct)
    }

    /// `MT_FadeToColor(toward, percent, 0, 1)`: f = percent / 100 of the way from the current gamma to the target.
    public mutating func fade(toward: RGB16?, percent: Int) {
        let f = Double(percent) / 100
        let target: [Double]? = toward.map { [Double($0.red), Double($0.green), Double($0.blue)] }
        for c in 0..<3 {
            if let t = target {
                gain[c] = gain[c] * (1 - f)
                offset[c] = offset[c] * (1 - f) + f * t[c]
            } else {
                gain[c] = gain[c] * (1 - f) + f
                offset[c] = offset[c] * (1 - f)
            }
        }
    }

    /// `.TintFadeProc @ 10034f40`'s per-channel factors (R, G, B) at `percent` (handlers dump l. 178ff, raw
    /// `10034fd8..10035268`): t = percent · 0.01 **rounded to single precision** (`frsp`, raw `10035008`); mode 3
    /// (`.GammaFadeOut`, raw `100351e0..10035268`): B · (1 − t), G · max(1 − 1.35t, 0), R · max(1 − 2.5t, 0) — each
    /// `1 − k·t` one fused `fnmsub` (1.35 @ `100a1960`, 2.5 @ `100a1958`) — so the fade goes red first, blue last.
    /// Modes 0 / 1 / 2 keep R / G / B · (1 − t) and the other two · max(1 − 2t, 0) (2 @ `100a1970`; lighting-tables §10
    /// [MED: no caller passes them]); any other mode leaves the values.
    public static func tintFactors(mode: Int, percent: Int) -> [Double] {
        let t = Double(Float(Double(percent) * 0.01))
        func clamp(_ k: Double) -> Double { max(1.0.addingProduct(-k, t), 0) }
        let keep = 1 - t
        switch mode {
        case 3: return [clamp(2.5), clamp(1.35), keep]
        case 0: return [keep, clamp(2), clamp(2)]
        case 1: return [clamp(2), keep, clamp(2)]
        case 2: return [clamp(2), clamp(2), keep]
        default: return [1, 1, 1]
        }
    }

    /// One tick of `MT_FadeCustom(0, 100, ms, .TintFadeProc, mode)` at `percent`: the **unfaded** gamma scaled by
    /// `tintFactors` (the proc writes the scaled values back into the list in place; whether that compounds tick to tick
    /// is the library's `MT_FadeCustom` [MED] — the replica scales the original table each tick, lighting-tables §10
    /// + BC28). The scaled values truncate toward zero (`FUN_10090a64`, double → u32).
    public static func tintFade(mode: Int, percent: Int) -> ScreenGamma {
        var g = ScreenGamma()
        g.gain = tintFactors(mode: mode, percent: percent)
        return g
    }

    /// Channel `c` (0 R, 1 G, 2 B) of a 16-bit value through this gamma.
    public func apply(_ v: UInt16, channel c: Int) -> UInt16 {
        let x = (gain[c] * Double(v) + offset[c]).rounded(.towardZero)
        return UInt16(max(0, min(65535, x)))
    }

    /// `clut` with every entry through this gamma — same id, seed and stored values (built through `ColorLUT`'s
    /// resource layout, so `entries` keep the `.SetScreenClut` value == index rewrite).
    public func apply(_ clut: ColorLUT) -> ColorLUT {
        guard self != .identity else { return clut }
        var b: [UInt8] = []
        b.reserveCapacity(8 + 8 * ColorLUT.entryCount)
        func put16(_ v: UInt16) { b.append(UInt8(v >> 8)); b.append(UInt8(v & 0xff)) }
        put16(UInt16(clut.seed >> 16)); put16(UInt16(clut.seed & 0xffff))
        put16(clut.flags)
        put16(UInt16(ColorLUT.entryCount - 1))
        for (i, e) in clut.entries.enumerated() {
            put16(clut.storedValues[i])
            put16(apply(e.red, channel: 0)); put16(apply(e.green, channel: 1)); put16(apply(e.blue, channel: 2))
        }
        // The layout is the one `ColorLUT(id:name:data:)` validated for `clut` itself.
        return try! ColorLUT(id: clut.id, name: clut.name, data: Data(b))
    }
}
