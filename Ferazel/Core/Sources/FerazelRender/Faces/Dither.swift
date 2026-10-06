import Foundation
import FerazelCore

/// How a DirectBits picture's transfer mode 64 (`ditherCopy`, all 326 32-bit PICTs — plan bank correction 2)
/// is modelled when `DrawPicture` puts it into the 8-bit conversion port. QuickDraw's dither algorithm is not
/// in the binary (Research note 10): the model is [LOW] and selectable; DECISIONS D26 rules `.errorDiffusion` the
/// default, `.none` selectable (gate card). Indexed pictures and 1-bit BitMaps are never dithered.
public enum DitherModel: Hashable, Sendable {
    /// Each pixel is its own colour search (8-bit components × 257).
    case none
    /// Floyd–Steinberg in 16-bit RGB: rows top-down, each row left-to-right (no serpentine). Per pixel the
    /// source (component × 257) plus the accumulated error is clamped to 0…0xffff per channel, the active
    /// `ColorSearch` model picks the index, and the error = clamped request − the chosen entry's colour is
    /// spread 7/16 right, 3/16 below-left, 5/16 below, 1/16 below-right (each share truncated toward zero;
    /// shares falling outside the picture are dropped).
    case errorDiffusion
}

enum Dither {
    /// `width × height` indices for 8-bit R,G,B triples (`DirectPICT.rgb`) under `model`.
    static func convert(rgb: [UInt8], width: Int, height: Int, clut: ColorLUT, search: ColorSearch.Prepared,
                        model: DitherModel) -> [UInt8] {
        var out = [UInt8](repeating: 0, count: width * height)
        switch model {
        case .none:
            for i in 0..<(width * height) {
                out[i] = search.index(of: RGB16(UInt16(rgb[3 * i]) &* 257, UInt16(rgb[3 * i + 1]) &* 257,
                                                UInt16(rgb[3 * i + 2]) &* 257))
            }
        case .errorDiffusion:
            let entries = clut.entries
            // Error rows padded by one cell each side: index x + 1 is column x.
            var cur = [Int](repeating: 0, count: (width + 2) * 3)
            var next = cur
            for y in 0..<height {
                for k in next.indices { next[k] = 0 }
                for x in 0..<width {
                    let i = y * width + x
                    let e = (x + 1) * 3
                    let r = clamp(Int(rgb[3 * i]) * 257 + cur[e])
                    let g = clamp(Int(rgb[3 * i + 1]) * 257 + cur[e + 1])
                    let b = clamp(Int(rgb[3 * i + 2]) * 257 + cur[e + 2])
                    let index = search.index(of: RGB16(UInt16(r), UInt16(g), UInt16(b)))
                    out[i] = index
                    let chosen = entries[Int(index)]
                    let er = r - Int(chosen.red), eg = g - Int(chosen.green), eb = b - Int(chosen.blue)
                    cur[e + 3] += er * 7 / 16; cur[e + 4] += eg * 7 / 16; cur[e + 5] += eb * 7 / 16
                    next[e - 3] += er * 3 / 16; next[e - 2] += eg * 3 / 16; next[e - 1] += eb * 3 / 16
                    next[e] += er * 5 / 16; next[e + 1] += eg * 5 / 16; next[e + 2] += eb * 5 / 16
                    next[e + 3] += er / 16; next[e + 4] += eg / 16; next[e + 5] += eb / 16
                }
                swap(&cur, &next)
            }
        }
        return out
    }

    @inline(__always) private static func clamp(_ v: Int) -> Int { min(0xffff, max(0, v)) }
}
