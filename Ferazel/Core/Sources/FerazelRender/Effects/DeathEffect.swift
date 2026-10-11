import Foundation
import FerazelCore

/// `.DeathEffect @ 10005270` (decompile l. 2676–2738), the border wipe after the player dies, drawn straight onto the
/// screen port (`.MTSetPortScreen`, `ForeColor(blackColor)`) one step per tick: before the loop
/// `.GammaFadeOutAsync(0x30, black)` (the RGB at `100a2c1e` = (0, 0, 0); raw `10005278..100052c4`), then 50 steps,
/// i = 4k for k = 0 … 49 (`iVar7 < 200`):
/// - four 4-px bands closing in over the 608×384 view (16..624 × 8..392): top (16, 8 + i, 624, 12 + i), bottom
///   (16, 388 − i, 624, 392 − i), left (16 + i, 8, 20 + i, 392), right (620 − i, 8, 624 − i, 392) (`SetRect` order
///   left, top, right, bottom);
/// - from k = 2 on (`1 < sVar5`), first the same bands 8 px further in (top/left +8, bottom/right −8) in the gray
///   pattern `qd+0xb2` with `patOr` (`PenMode(1)`), then the bands in the black pattern `qd+0xba` with `patCopy`;
/// - one `.HandleAsyncGammaFade` (`DrawOp.gammaStep(k, 0x30, toward: black)` while k ≤ 0x30; the fade is over after
///   k = 0x30, so step 49 has none), then the wait for the next tick.
/// Not modelled: `.GammaFadeOutAsync`'s gates (`DAT_100a53c2` gamma available, `*_DAT_1009fde8` not already faded
/// out, raw `100356c0..`) — taken as open; with the screen already faded the compounding steps toward black change
/// nothing visible either [MED]. `FrameRenderer.deathEffectStep` runs a step on the renderer's screen.
/// QuickDraw colour patterns: a 1 bit is the foreground colour (`patCopy` and `patOr`); a 0 bit is the background
/// under `patCopy` and leaves the pixel under `patOr` (Inside Macintosh: Imaging With QuickDraw, colour transfer
/// modes) — the black pattern is all 1s, gray is `AA 55 AA 55 …`, aligned to the screen's (0, 0): pixel (x, y) is set
/// when x + y is even [MED: QuickDraw, not the binary; the pattern origin of the screen port].
public struct DeathEffect: Sendable {
    /// The steps (`.DeathEffect`'s loop count).
    public static let steps = 50
    /// `.GammaFadeOutAsync`'s N.
    public static let gammaSteps = 0x30
    /// The fade-out colour, `100a2c1e`.
    public static let fadeColour = RGB16(0, 0, 0)

    /// The foreground index `ForeColor(blackColor)` gives on the screen (`Color2Index` of black in the screen CLUT).
    public let foreColor: UInt8

    public init(foreColor: UInt8) { self.foreColor = foreColor }

    /// A band (left, top, right, bottom), half-open.
    public struct Band: Equatable, Sendable {
        public var left: Int, top: Int, right: Int, bottom: Int
        public init(left: Int, top: Int, right: Int, bottom: Int) {
            self.left = left; self.top = top; self.right = right; self.bottom = bottom
        }
    }

    /// Step k's black bands (top, bottom, left, right).
    public static func blackBands(step k: Int) -> [Band] {
        let i = 4 * k
        return [Band(left: 0x10, top: i + 8, right: 0x270, bottom: i + 0xc),
                Band(left: 0x10, top: 0x184 - i, right: 0x270, bottom: Int(Int16(truncatingIfNeeded: 0x188 - i))),
                Band(left: i + 0x10, top: 8, right: i + 0x14, bottom: 0x188),
                Band(left: 0x26c - i, top: 8, right: Int(Int16(truncatingIfNeeded: 0x270 - i)), bottom: 0x188)]
    }

    /// Step k's gray `patOr` bands (none before k = 2): the black ones moved 8 px inward.
    public static func grayBands(step k: Int) -> [Band] {
        guard k > 1 else { return [] }
        let b = blackBands(step: k)
        func off(_ r: Band, _ dh: Int, _ dv: Int) -> Band {
            Band(left: r.left + dh, top: r.top + dv, right: r.right + dh, bottom: r.bottom + dv)
        }
        return [off(b[0], 0, 8), off(b[1], 0, -8), off(b[2], 8, 0), off(b[3], -8, 0)]
    }

    /// Paints step `k` onto `screen` (gray bands, then black) and returns its gamma step, nil when the fade is over.
    /// - Precondition: k in 0 … 49 (`iVar7` from 0 by 4 while < 200).
    @discardableResult
    public func frame(step k: Int, on screen: inout IndexedFrame) -> DrawOp? {
        precondition((0..<Self.steps).contains(k), "DeathEffect step \(k)")
        for r in Self.grayBands(step: k) { paint(r, on: &screen) { x, y in (x + y) & 1 == 0 } }
        for r in Self.blackBands(step: k) { paint(r, on: &screen) { _, _ in true } }
        guard k <= Self.gammaSteps else { return nil }
        return .gammaStep(numerator: k, denominator: Self.gammaSteps, toward: Self.fadeColour)
    }

    /// `PaintRect` clipped to the screen: pattern 1 bits → the foreground index (0 bits left alone: the gray `patOr`;
    /// the black pattern has none).
    private func paint(_ r: Band, on screen: inout IndexedFrame, _ bit: (Int, Int) -> Bool) {
        for y in max(r.top, 0)..<max(min(r.bottom, IndexedFrame.height), max(r.top, 0)) {
            for x in max(r.left, 0)..<max(min(r.right, IndexedFrame.width), max(r.left, 0)) where bit(x, y) {
                screen[x, y] = foreColor
            }
        }
    }
}
