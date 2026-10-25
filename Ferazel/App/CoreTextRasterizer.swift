import CoreGraphics
import CoreText
import FerazelRender
import Foundation

/// QuickDraw `DrawString` for the status bar (`TextRasterizer`, plan S4/S5; BTX precedent): the pixels one string
/// sets in font family `font` (`TextFont`), `size` points (`TextSize`) and style `face` (`TextFace`), drawn with
/// CoreText at 72 dpi, one pixel per point. TX (Q6 note 1): Mac OS 8.5+ smoothed screen text ("Smooth all fonts on
/// screen", Appearance → Fonts) at and above a size threshold, so at `smoothingThreshold` points and up the mask is
/// CoreText's antialiased coverage as it comes (linear, no threshold — FerazelRender blends it into the palette,
/// `TextCoverage`); below it the mask is two-level, 0 / 255, where the glyph covers at least half of a pixel [MED:
/// QuickDraw's bitmap Times / Geneva are not on this Mac; CoreText's outline fonts stand in].
final class CoreTextRasterizer: TextRasterizer {
    /// The smallest smoothed size ("Smooth all fonts on screen", Appearance → Fonts → Size … and above) [MED]. Read
    /// against the Let's Play (Mac OS 9, `ESuyxMUEzDw`): the conversation's Times 18 is smoothed (03:16), while the
    /// status bar's Times 12 bold stage name (03:16) and a Geneva bold 8 item count (09:50) are crisp, bitmap-like.
    /// The control panel's default as remembered (12 and above) would smooth the stage name, so the Let's Play wins:
    /// 14. The game draws 8, 9, 12 and 18 point text only, so any value 13…18 draws the same.
    static let smoothingThreshold: Int16 = 14

    private var fonts: [String: CTFont] = [:]

    /// The classic font family numbers (Inside Macintosh: Text, "Font family IDs") → today's family names.
    private static let families: [Int16: String] = [
        2: "New York", 3: "Geneva", 4: "Monaco", 20: "Times", 21: "Helvetica", 22: "Courier",
    ]

    /// `font` by its family number with `face`'s bold (bit 0) and italic (bit 1); 0 and 1 (system / application
    /// font) are the system font. CoreText substitutes a fallback when a family is absent.
    private func ctFont(_ font: Int16, size: Int16, face: Int16) -> CTFont {
        let key = "\(font)/\(size)/\(face)"
        if let f = fonts[key] { return f }
        let pt = CGFloat(size)
        let base: CTFont = Self.families[font].map { CTFontCreateWithName($0 as CFString, pt, nil) }
            ?? CTFontCreateUIFontForLanguage(.system, pt, nil)
            ?? CTFontCreateWithName("Lucida Grande" as CFString, pt, nil)
        var traits: CTFontSymbolicTraits = []
        if face & 1 != 0 { traits.insert(.traitBold) }
        if face & 2 != 0 { traits.insert(.traitItalic) }
        let f = traits.isEmpty ? base
            : (CTFontCreateCopyWithSymbolicTraits(base, pt, nil, traits, traits) ?? base)
        fonts[key] = f
        return f
    }

    func rasterize(_ text: String, font: Int16, size: Int16, face: Int16)
        -> (left: Int, top: Int, width: Int, height: Int, coverage: [UInt8]) {
        guard !text.isEmpty else { return (0, 0, 0, 0, []) }
        let f = ctFont(font, size: size, face: face)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): f,
            NSAttributedString.Key(kCTForegroundColorFromContextAttributeName as String): true,
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
        var ascent: CGFloat = 0, descent: CGFloat = 0
        let advance = Int(CTLineGetTypographicBounds(line, &ascent, &descent, nil).rounded(.up))
        // A coverage bitmap: `pad` columns either side, `above` rows over the baseline, `below` under it.
        let pad = 2
        let above = Int(ascent.rounded(.up)) + 1, below = Int(descent.rounded(.up)) + 1
        let w = advance + 2 * pad, h = above + below
        guard w > 0, h > 0 else { return (0, 0, 0, 0, []) }
        var coverage = [UInt8](repeating: 0, count: w * h)
        coverage.withUnsafeMutableBytes { raw in
            guard let ctx = CGContext(data: raw.baseAddress, width: w, height: h, bitsPerComponent: 8,
                                      bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue) else { return }
            ctx.setShouldAntialias(true)
            ctx.setShouldSmoothFonts(false)
            ctx.setFillColor(CGColor(gray: 0, alpha: 1))
            ctx.textPosition = CGPoint(x: CGFloat(pad), y: CGFloat(below))
            CTLineDraw(line, ctx)
        }
        // Row 0 of `coverage` is the top row (CGContext memory is top-down): pen-relative top = −above.
        if size < Self.smoothingThreshold { coverage = coverage.map { $0 >= 0x80 ? 0xff : 0 } }
        return (-pad, -above, w, h, coverage)
    }

    /// QuickDraw `CharWidth(byte)` (C2): the Mac Roman character's CoreText advance, rounded to whole pixels
    /// [MED: the bitmap font's integer widths are not on this Mac].
    func charWidth(_ byte: UInt8, font: Int16, size: Int16, face: Int16) -> Int {
        guard let s = String(bytes: [byte], encoding: .macOSRoman), !s.isEmpty else { return 0 }
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): ctFont(font, size: size, face: face),
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: attributes))
        return Int(CTLineGetTypographicBounds(line, nil, nil, nil).rounded())
    }

    /// QuickDraw `GetFontInfo` (C2): CoreText's ascent, descent and leading, each rounded to whole pixels [MED].
    func fontInfo(font: Int16, size: Int16, face: Int16) -> (ascent: Int, descent: Int, leading: Int) {
        let f = ctFont(font, size: size, face: face)
        return (Int(CTFontGetAscent(f).rounded()), Int(CTFontGetDescent(f).rounded()),
                Int(CTFontGetLeading(f).rounded()))
    }
}
