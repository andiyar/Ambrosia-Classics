import Foundation
import FerazelCore
import HectorResources

/// QuickDraw `DrawString` for the status bar (plan S4: the App implements it with CoreText; BTX precedent). FerazelRender
/// has no font engine: it asks for the pixels one string covers and paints them itself (`TextCoverage.paint`) — the
/// transfer mode `.UpdateTextStats` leaves untouched is srcOr, so only the glyph pixels change
/// (spells-items §6 "⚑ Phase-1 note (R6)"). TX (Q6 note 1): Mac OS 8.5+ smoothed text at and above the Appearance
/// size threshold, so the mask is per-pixel coverage; a two-level font answers 0 / 255 only.
public protocol TextRasterizer {
    /// The pixels `DrawString(text)` covers with the pen at (0, 0) on the baseline, in font family `font` (`TextFont`),
    /// `size` points (`TextSize`) and style `face` (`TextFace`: bit 0 bold, bit 1 italic, …) at 72 dpi, one pixel per
    /// point: a `width × height` row-major coverage mask (0 = untouched … 255 = fully the text colour) whose top-left is
    /// (`left`, `top`) relative to the pen (`top` is negative above the baseline). The text is Mac Roman as the
    /// original stores it.
    func rasterize(_ text: String, font: Int16, size: Int16, face: Int16)
        -> (left: Int, top: Int, width: Int, height: Int, coverage: [UInt8])

    /// QuickDraw `CharWidth(byte)` (Mac Roman) in `font`/`size`/`face`: the pen advance in whole pixels — what
    /// `.DrawConvTextString`'s wrap sums and `.DrawStringCharByChar` advances by (C2).
    func charWidth(_ byte: UInt8, font: Int16, size: Int16, face: Int16) -> Int

    /// QuickDraw `GetFontInfo` in `font`/`size`/`face`: TextEdit's line height is `ascent + descent + leading`
    /// (`.CalcWrappedStringInBoxHeight`'s `teLineHite`, C2).
    func fontInfo(font: Int16, size: Int16, face: Int16) -> (ascent: Int, descent: Int, leading: Int)
}

extension TextRasterizer {
    /// QuickDraw `DrawChar(byte)`: the one character's coverage with the pen at (0, 0) on the baseline (C2's
    /// per-character drawing; `rasterize` of the byte's Mac Roman character).
    public func rasterize(byte: UInt8, font: Int16, size: Int16, face: Int16)
        -> (left: Int, top: Int, width: Int, height: Int, coverage: [UInt8]) {
        rasterize(MacRoman.decode([byte]), font: font, size: size, face: face)
    }
}

/// TX (Q6 note 1): one rasterized string painted srcOr into an indexed port, smoothed as Mac OS 9 drew it — coverage 255
/// takes the text index exactly as before, 0 leaves the pixel, and a partly covered pixel takes the colour between the
/// text colour and the pixel's own colour (its index looked up in the port's CLUT) by c / 255, mapped back to an index
/// with the site's own colour search (`Color2Index`). The mix is linear in coverage on the 16-bit channels [MED: the
/// ROM's blend and any gamma are not in the binary].
enum TextCoverage {
    /// Paints `glyph` with its pen at (`x`, `y`) into `pixels` (`width × height`, row-major), clipped.
    /// - Parameters:
    ///   - index: the text index (`Color2Index(rgb)` against `clut`), written where coverage is 255.
    ///   - rgb: the text colour (`RGBForeColor`).
    ///   - clut: the colour table the port's indices are seen through.
    ///   - search: the site's colour search on `clut`.
    static func paint(_ glyph: (left: Int, top: Int, width: Int, height: Int, coverage: [UInt8]), x: Int, y: Int,
                      into pixels: inout [UInt8], width: Int, height: Int,
                      index: UInt8, rgb: RGB16, clut: ColorLUT, search: ColorSearch.Prepared) {
        precondition(glyph.coverage.count == glyph.width * glyph.height,
                     "TextRasterizer: \(glyph.width)×\(glyph.height) mask")
        for r in 0..<glyph.height {
            let py = y + glyph.top + r
            guard (0..<height).contains(py) else { continue }
            for c in 0..<glyph.width {
                let cover = glyph.coverage[r * glyph.width + c]
                guard cover != 0 else { continue }
                let px = x + glyph.left + c
                guard (0..<width).contains(px) else { continue }
                let at = py * width + px
                if cover == 255 { pixels[at] = index; continue }
                let p = Int(pixels[at])
                // An index past a short CLUT reads black [LOW: every shipped screen CLUT holds 256 entries].
                let under = p < clut.entries.count ? RGB16(clut.entries[p]) : RGB16(0, 0, 0)
                pixels[at] = search.index(of: mix(rgb, under, cover))
            }
        }
    }

    /// `text` over `under` at `cover` / 255, per 16-bit channel, rounded to nearest.
    static func mix(_ text: RGB16, _ under: RGB16, _ cover: UInt8) -> RGB16 {
        let c = Int(cover)
        func m(_ a: UInt16, _ b: UInt16) -> UInt16 { UInt16((Int(a) * c + Int(b) * (255 - c) + 127) / 255) }
        return RGB16(m(text.red, under.red), m(text.green, under.green), m(text.blue, under.blue))
    }
}
