import Foundation
import HectorResources

/// QuickDraw `DrawString` for the status bar (plan S4: the App implements it with CoreText; BTX precedent). FerazelRender
/// has no font engine: it asks for the pixels one string sets and paints them in the port's foreground index itself —
/// the transfer mode `.UpdateTextStats` leaves untouched is srcOr, so only the glyph pixels change
/// (spells-items §6 "⚑ Phase-1 note (R6)").
public protocol TextRasterizer {
    /// The pixels `DrawString(text)` sets with the pen at (0, 0) on the baseline, in font family `font` (`TextFont`),
    /// `size` points (`TextSize`) and style `face` (`TextFace`: bit 0 bold, bit 1 italic, …) at 72 dpi, one pixel per
    /// point: a `width × height` row-major mask whose top-left is (`left`, `top`) relative to the pen (`top` is
    /// negative above the baseline). The text is Mac Roman as the original stores it.
    func rasterize(_ text: String, font: Int16, size: Int16, face: Int16)
        -> (left: Int, top: Int, width: Int, height: Int, bits: [Bool])

    /// QuickDraw `CharWidth(byte)` (Mac Roman) in `font`/`size`/`face`: the pen advance in whole pixels — what
    /// `.DrawConvTextString`'s wrap sums and `.DrawStringCharByChar` advances by (C2).
    func charWidth(_ byte: UInt8, font: Int16, size: Int16, face: Int16) -> Int

    /// QuickDraw `GetFontInfo` in `font`/`size`/`face`: TextEdit's line height is `ascent + descent + leading`
    /// (`.CalcWrappedStringInBoxHeight`'s `teLineHite`, C2).
    func fontInfo(font: Int16, size: Int16, face: Int16) -> (ascent: Int, descent: Int, leading: Int)
}

extension TextRasterizer {
    /// QuickDraw `DrawChar(byte)`: the one character's pixels with the pen at (0, 0) on the baseline (C2's
    /// per-character drawing; `rasterize` of the byte's Mac Roman character).
    public func rasterize(byte: UInt8, font: Int16, size: Int16, face: Int16)
        -> (left: Int, top: Int, width: Int, height: Int, bits: [Bool]) {
        rasterize(MacRoman.decode([byte]), font: font, size: size, face: face)
    }
}
