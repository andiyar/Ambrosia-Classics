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
