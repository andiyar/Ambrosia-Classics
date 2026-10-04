import Foundation

/// Every rect the game screen draws with, transcribed from the original's `_SetRect(r, left, top, right,
/// bottom)` calls (R2 `_DrawGameTiles` DC:6244, `_DrawBufferTiles` DC:6661, R3 `_RedrawCustomGameScreen`
/// DC:6470, `_RedrawCustomTimeBar` DC:5860, `_RedrawCustomTimeAccumulated` DC:5746, `_RedrawCustomOpenPairs`
/// DC:6355, `_RedrawNoMorePairs` DC:6420, `_FlashCGButton` DC:5412, `_SelectCGButton` DC:7729, R4 the slides).
/// Sheet layouts: docs/aki/assets-census.md §1 (misc.png 467×468, tiles.png 53×1104, tile_pictures.png
/// 39×2100, plate.png 2358×68, pause.png / nopairs.png 416×480). Including the code's 1-px size mismatches
/// that make QuickDraw stretch (Invariant 13).
public enum AkiGameArt {

    // MARK: - Tiles (`_DrawGameTiles` DC:6244, `_DrawBufferTiles` DC:6661)

    /// tiles.png row 0 — the blank tile body (DC:6301).
    public static let tileBlank = QDRect(left: 0, top: 0, right: 53, bottom: 69)
    /// tiles.png row 1 — the selected overlay (DC:6323).
    public static let tileSelected = QDRect(left: 0, top: 69, right: 53, bottom: 138)
    /// tiles.png row 2 — the hint overlay (DC:6330, 0x8a…0xcf).
    public static let tileHint = QDRect(left: 0, top: 138, right: 53, bottom: 207)
    /// tiles.png row 3 — the greyed (no open pairs) overlay (DC:6312, 0xcf…0x114).
    public static let tileGrey = QDRect(left: 0, top: 207, right: 53, bottom: 276)

    /// tiles.png fade-mask row f (f 0 = the solid body mask, DC:6307; 1…10 the fade frames, DC:6847).
    public static func fadeMask(_ f: Int) -> QDRect {
        QDRect(left: 0, top: 276 + 69 * f, right: 53, bottom: 345 + 69 * f)
    }

    /// tiles.png last row — the mask for every overlay (0x40b…0x450, DC:6316).
    public static let overlayMask = QDRect(left: 0, top: 1035, right: 53, bottom: 1104)

    /// tile_pictures.png face picture for PICT id `face` (200…241): (0, 50·face − 10000, 38, 50·face − 9950) (DC:6296).
    public static func facePicture(_ face: Int) -> QDRect {
        QDRect(left: 0, top: 50 * face - 10000, right: 38, bottom: 50 * face - 9950)
    }

    /// Where the face is painted into the tiles buffer — 38×49, so the 38×50 picture stretches (DC:6298).
    public static let faceDestination = QDRect(left: 8, top: 5, right: 46, bottom: 54)

    /// The 53×69 tile at the box's (left, top) (DC:6306).
    public static func tileRect(_ box: QDRect) -> QDRect {
        QDRect(left: box.left, top: box.top, right: box.left + 53, bottom: box.top + 69)
    }

    /// The board-buffer → screen copy of one tile: (left, top+1, left+51, top+67) (DC:6334).
    public static func tileWindowRect(_ box: QDRect) -> QDRect {
        QDRect(left: box.left, top: box.top + 1, right: box.left + 51, bottom: box.top + 67)
    }

    /// The background restore around one tile: (left−53, top−69, left+53, top+69) (`_DrawBufferTiles` DC:6693).
    public static func bufferRestore(_ box: QDRect) -> QDRect {
        QDRect(left: box.left - 53, top: box.top - 69, right: box.left + 53, bottom: box.top + 69)
    }

    // MARK: - Plate (`_RedrawCustomGameScreen` DC:6495)

    public static let plateSource = QDRect(left: 0, top: 0, right: 786, bottom: 68)
    /// The right half of plate.png: (w, 0, 2w, 68) with w = 786.
    public static let plateMask = QDRect(left: 786, top: 0, right: 1572, bottom: 68)
    public static let plateDestination = QDRect(left: 7, top: 532, right: 793, bottom: 600)

    // MARK: - Buttons (misc.png; `_RedrawCustomGameScreen` DC:6501, `_SelectCGButton` DC:7729)

    /// Button k (3 hint, 4 reshuffle, 5 pause): (25(k−3)+205, 411, 25(k−3)+230, 436).
    public static func buttonSprite(_ k: Int) -> QDRect {
        QDRect(left: 25 * (k - 3) + 205, top: 411, right: 25 * (k - 3) + 230, bottom: 436)
    }

    /// The pause button while paused (0x14a…0x163).
    public static let pausedSprite = QDRect(left: 330, top: 411, right: 355, bottom: 436)
    /// Every button sprite's mask (0x163, 0x19b, 0x17c, 0x1b4).
    public static let buttonMask = QDRect(left: 355, top: 411, right: 380, bottom: 436)

    /// Button k's 25×25 slot on the plate: (38k−90, 559, 38k−65, 584) — 24, 62, 100 for k 3/4/5.
    public static func buttonDestination(_ k: Int) -> QDRect {
        QDRect(left: 38 * k - 90, top: 559, right: 38 * k - 65, bottom: 584)
    }

    /// The pressed sprite of button k: (25k+205, 411, 25k+230, 436) (DC:7765).
    public static func pressedSprite(_ k: Int) -> QDRect {
        QDRect(left: 25 * k + 205, top: 411, right: 25 * k + 230, bottom: 436)
    }

    /// The plate restore before the pressed sprite: (38k−106, 10, 38k−52, 64) (DC:7758). The original's mask
    /// rect for this copy lies outside plate.png (Q26), so the replica restores with CopyBits.
    public static func pressedRestoreSource(_ k: Int) -> QDRect {
        QDRect(left: 38 * k - 106, top: 10, right: 38 * k - 52, bottom: 64)
    }

    /// (38k−99, 542, 38k−45, 596) (DC:7759).
    public static func pressedRestoreDestination(_ k: Int) -> QDRect {
        QDRect(left: 38 * k - 99, top: 542, right: 38 * k - 45, bottom: 596)
    }

    // MARK: - Button flash (`_FlashCGButton` DC:5412)

    /// The rects of one `_FlashCGButton(n, glow)` call. The glow is masked by the phase row `glowMask(p)`.
    /// Order in `_FlashCGButton` (DC:5450–5466): the plate restore and the sprite copy happen on EVERY call;
    /// only when the glow flag is set is the phase STEPPED FIRST (`FlashPhase.step()`) and the glow then drawn
    /// with the NEW p. The App executor (P2.9) must step, then draw.
    public struct FlashRects: Equatable, Sendable {
        public var restoreSource: QDRect, restoreDestination: QDRect
        public var spriteSource: QDRect, spriteDestination: QDRect, spriteMask: QDRect
        public var glowSource: QDRect, glowDestination: QDRect
        public var window: QDRect

        /// misc.png glow mask for phase p: (233, 149+25p, 258, 174+25p) (DC:5465). p is the phase AFTER this
        /// call's `FlashPhase.step()` — the original steps first, then draws, both only under the glow flag
        /// (DC:5450–5466).
        public func glowMask(_ p: Int) -> QDRect {
            QDRect(left: glowSource.left, top: glowSource.top + 25 * p,
                   right: glowSource.right, bottom: glowSource.bottom + 25 * p)
        }
    }

    /// s = 38·((n−1)/2): restore plate (s+7, 17, s+52, 62) → (s+14, 549, s+59, 594); sprite n == 5 ? paused :
    /// (25j+205, 411, 25j+230, 436), j = (n−1)/2, → (s+24, 559, s+49, 584) masked by `buttonMask`; glow
    /// (233, 149, 258, 174) → the sprite slot; window (s+14, 549, s+59, 594).
    public static func flash(_ n: Int) -> FlashRects {
        let j = (n - 1) / 2
        let s = 38 * j
        let slot = QDRect(left: s + 24, top: 559, right: s + 49, bottom: 584)
        let window = QDRect(left: s + 14, top: 549, right: s + 59, bottom: 594)
        return FlashRects(
            restoreSource: QDRect(left: s + 7, top: 17, right: s + 52, bottom: 62),
            restoreDestination: window,
            spriteSource: n == 5 ? pausedSprite
                : QDRect(left: 25 * j + 205, top: 411, right: 25 * j + 230, bottom: 436),
            spriteDestination: slot,
            spriteMask: buttonMask,
            glowSource: QDRect(left: 233, top: 149, right: 258, bottom: 174),
            glowDestination: slot,
            window: window)
    }

    /// The glow ping-pong (g+0x87 falling flag, g+0x88 phase): rising → p += 1, at 6 → falling;
    /// falling → p −= 1, at 1 → rising. Level start = rising, p = 2 (R4). In `_FlashCGButton` (DC:5450–5466)
    /// the step runs only when the glow flag is set, and BEFORE the glow draw, which uses the new p (step, then
    /// draw); the restore + sprite copies happen every call regardless.
    public struct FlashPhase: Equatable, Sendable {
        public var rising: Bool
        public var p: Int

        public init() { self.init(rising: true, p: 2) }
        public init(rising: Bool, p: Int) { self.rising = rising; self.p = p }

        public mutating func step() {
            if rising {
                p += 1
                if p == 6 { rising = false }
            } else {
                p -= 1
                if p == 1 { rising = true }
            }
        }
    }

    // MARK: - Digits (misc.png; `_RedrawCustomTimeAccumulated` DC:5746, `_RedrawCustomOpenPairs` DC:6355)

    /// Digit d: e = d == 0 ? 10 : d; src (155, 30e+87, 179, 30e+117), mask (180, same rows, 204).
    public static func digit(_ d: Int) -> (src: QDRect, mask: QDRect) {
        let e = d == 0 ? 10 : d
        return (QDRect(left: 155, top: 30 * e + 87, right: 179, bottom: 30 * e + 117),
                QDRect(left: 180, top: 30 * e + 87, right: 204, bottom: 30 * e + 117))
    }

    public static let colon = QDRect(left: 155, top: 417, right: 179, bottom: 447)
    public static let colonMask = QDRect(left: 180, top: 417, right: 204, bottom: 447)

    /// Elapsed HH:MM:SS: plate (620, 38, 749, 60) → (627, 570, 756, 592) (DC:5771).
    public static let elapsedRestore: (src: QDRect, dst: QDRect) = (
        QDRect(left: 620, top: 38, right: 749, bottom: 60),
        QDRect(left: 627, top: 570, right: 756, bottom: 592))

    /// Left to right: H-tens, H-ones, colon, M-tens, M-ones, colon, S-tens, S-ones — each 16×22 at y 570…592.
    public static let elapsedDestinations: [QDRect] = [637, 653, 663, 673, 689, 699, 709, 725].map {
        QDRect(left: $0, top: 570, right: $0 + 16, bottom: 592)
    }

    public static let elapsedWindow = QDRect(left: 627, top: 570, right: 756, bottom: 592)

    /// Open pairs: plate (625, 10, 673, 33) → (632, 542, 680, 565) (DC:6374).
    public static let pairsRestore: (src: QDRect, dst: QDRect) = (
        QDRect(left: 625, top: 10, right: 673, bottom: 33),
        QDRect(left: 632, top: 542, right: 680, bottom: 565))

    /// Place 0 ones (657), 1 tens (641, n ≥ 10), 2 hundreds (625, n ≥ 100) — 16×22 at y 544…566.
    public static func pairsDigitDestination(_ place: Int) -> QDRect {
        let left = 657 - 16 * place
        return QDRect(left: left, top: 544, right: left + 16, bottom: 566)
    }

    /// The hundreds digit of the open-pairs count: row 30d+87 WITHOUT the 0 → 10 map (DC:6404).
    public static func pairsHundredsDigit(_ d: Int) -> (src: QDRect, mask: QDRect) {
        (QDRect(left: 155, top: 30 * d + 87, right: 179, bottom: 30 * d + 117),
         QDRect(left: 180, top: 30 * d + 87, right: 204, bottom: 30 * d + 117))
    }

    public static let pairsWindow = QDRect(left: 632, top: 542, right: 680, bottom: 565)

    // MARK: - Time bar (`_RedrawCustomTimeBar` DC:5860)

    /// Plate (134, 25, 590, 56) → (141, 557, 597, 588) (DC:5890).
    public static let timeBarRestore: (src: QDRect, dst: QDRect) = (
        QDRect(left: 134, top: 25, right: 590, bottom: 56),
        QDRect(left: 141, top: 557, right: 597, bottom: 588))

    public static let timeBarWindow = QDRect(left: 141, top: 557, right: 597, bottom: 588)

    /// One time-bar draw: k full stones (k > 0) in one masked copy, then the cap stone masked by its cell.
    public struct StoneDraw: Equatable, Sendable {
        public var k: Int
        public var fullSource: QDRect?, fullDestination: QDRect?, fullMask: QDRect?
        public var capSource: QDRect, capDestination: QDRect, capMask: QDRect
    }

    /// raw ≤ 0 → nil (nothing drawn); k = length < 24 ? 0 : min(17, length/24); full stones src
    /// (3, 39, 25k+3, 78) → (144, 552, 25k+144, 591) mask (3, 78, 25k+3, 117); cap src (25k+3, 39, 25k+28, 78)
    /// → (25k+144, 552, 25k+169, 591) masked by `capCell(length − 24k)`.
    public static func timeBarStones(raw: Int, length: Int) -> StoneDraw? {
        guard raw > 0 else { return nil }
        let k = length < 24 ? 0 : min(17, length / 24)
        let full = k > 0
        return StoneDraw(
            k: k,
            fullSource: full ? QDRect(left: 3, top: 39, right: 25 * k + 3, bottom: 78) : nil,
            fullDestination: full ? QDRect(left: 144, top: 552, right: 25 * k + 144, bottom: 591) : nil,
            fullMask: full ? QDRect(left: 3, top: 78, right: 25 * k + 3, bottom: 117) : nil,
            capSource: QDRect(left: 25 * k + 3, top: 39, right: 25 * k + 28, bottom: 78),
            capDestination: QDRect(left: 25 * k + 144, top: 552, right: 25 * k + 169, bottom: 591),
            capMask: capCell(length - 24 * k))
    }

    /// The cap's mask cell for remainder r (the DC:5917 switch): c = r ≤ 11 ? 11 − r : (r ≤ 23 ? 35 − r : 12);
    /// misc.png grid of 25×39 cells at x 3 + 25(c%6), y 117 + 39(c/6).
    public static func capCell(_ r: Int) -> QDRect {
        let c = r <= 11 ? 11 - r : (r <= 23 ? 35 - r : 12)
        let x = 3 + 25 * (c % 6), y = 117 + 39 * (c / 6)
        return QDRect(left: x, top: y, right: x + 25, bottom: y + 39)
    }

    // MARK: - Overlays (pause.png / nopairs.png; DC:6439, DC:6537)

    public static let overlaySource = QDRect(left: 0, top: 0, right: 208, bottom: 480)
    /// The overlay sheet's right half. (`overlayMask` is the tiles.png overlay mask above.)
    public static let overlaySourceMask = QDRect(left: 208, top: 0, right: 416, bottom: 480)
    public static let overlayDestination = QDRect(left: 296, top: 26, right: 504, bottom: 506)

    // MARK: - Slides (R4; shared by the game and the editor slides)

    /// Opening slide offset after t ticks: `Int(Float(t)/60·400)`, 0 → 400. The tick delta is an UNSIGNED
    /// 32-bit compare (`(uint)delta < 0x3d`, DC:6600): ≥ 61 clamps to 60, and so does a negative (wrapped) delta.
    public static func slideIn(ticks: Int) -> Int {
        let t = (ticks < 0 || ticks > 60) ? 60 : ticks
        return Int(Float(t) / 60 * 400)
    }

    /// Closing slide offset after t ticks: `Int(Float(t)/60·(−400) + 400)`, 400 → 0. Same unsigned clamp as
    /// `slideIn` (DC:6600): a delta ≥ 61 or negative becomes 60.
    public static func slideOut(ticks: Int) -> Int {
        let t = (ticks < 0 || ticks > 60) ? 60 : ticks
        return Int(Float(t) / 60 * -400 + 400)
    }

    /// [left, middle, right]: left (s, 0, 400, 600) → (0, 0, 400−s, 600); middle (400−s, 0, 400+s, 600) from the
    /// other buffer; right (400, 0, 800−s, 600) → (400+s, 0, 800, 600).
    public static func slideRects(_ s: Int) -> [(src: QDRect, dst: QDRect)] {
        let middle = QDRect(left: 400 - s, top: 0, right: 400 + s, bottom: 600)
        return [
            (QDRect(left: s, top: 0, right: 400, bottom: 600), QDRect(left: 0, top: 0, right: 400 - s, bottom: 600)),
            (middle, middle),
            (QDRect(left: 400, top: 0, right: 800 - s, bottom: 600), QDRect(left: 400 + s, top: 0, right: 800, bottom: 600)),
        ]
    }
}
