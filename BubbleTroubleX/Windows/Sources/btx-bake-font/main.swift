// btx-bake-font <output-directory> — bakes the system-font faces Bubble Trouble X draws into `.btxfont` files
// (plan W2; format in BTXWinKit/BTXFont.swift), by the same CoreText path as BubbleTroubleX/App/CoreTextRasterizer:
// a CTLine with the context's colour, drawn antialiased without font smoothing into an 8-bit alpha-only context.
// Mac-only; on other platforms it only says so.
#if canImport(CoreText)
import BTXWinKit
import CoreGraphics
import CoreText
import Foundation

/// The faces: the compositor's two (`_DrawInterfaceText`: Geneva 9; `_DrawFPS`: System 12, also the dialogs') and the
/// in-window menu bar / About panel's (W5: System 12 bold, Geneva 10 — unused since D21 removed both, still baked).
let faces: [(name: String, size: Int)] = [("Geneva", 9), ("Geneva", 10), ("System", 12), ("System-Bold", 12)]

/// As CoreTextRasterizer resolves names: "System" is the UI system font; "System-Bold" its emphasized form.
func ctFont(_ name: String, size: Int) -> CTFont {
    let s = CGFloat(size)
    switch name {
    case "System":
        return CTFontCreateUIFontForLanguage(.system, s, nil) ?? CTFontCreateWithName("Lucida Grande" as CFString, s, nil)
    case "System-Bold":
        return CTFontCreateUIFontForLanguage(.emphasizedSystem, s, nil)
            ?? CTFontCreateWithName("LucidaGrande-Bold" as CFString, s, nil)
    default:
        return CTFontCreateWithName(name as CFString, s, nil)
    }
}

func line(_ s: String, font: CTFont) -> CTLine {
    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorFromContextAttributeName as String): true,
    ]
    return CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: attributes))
}

func advance(_ l: CTLine) -> (advance: Double, ascent: Double, descent: Double) {
    var a: CGFloat = 0, d: CGFloat = 0
    let w = CTLineGetTypographicBounds(l, &a, &d, nil)
    return (Double(w), Double(a), Double(d))
}

/// The coverage CoreText draws for `l` with its origin at x = `fraction` (of a pixel), cropped to its ink.
func render(_ l: CTLine, fraction: Double, advance: Double, ascent: Double, descent: Double) -> BTXFont.Bitmap? {
    let margin = 8
    let w = Int(advance.rounded(.up)) + 2 * margin
    let above = Int(ascent.rounded(.up)) + margin, below = Int(descent.rounded(.up)) + margin
    let h = above + below
    var coverage = [UInt8](repeating: 0, count: w * h)
    coverage.withUnsafeMutableBytes { raw in
        guard let ctx = CGContext(data: raw.baseAddress, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(),
                                  bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue) else { fatalError("no context") }
        ctx.setShouldAntialias(true)
        ctx.setShouldSmoothFonts(false)
        ctx.setFillColor(CGColor(gray: 0, alpha: 1))
        ctx.textPosition = CGPoint(x: CGFloat(margin) + CGFloat(fraction), y: CGFloat(below))
        CTLineDraw(l, ctx)
    }
    var minR = h, maxR = -1, minC = w, maxC = -1
    for r in 0..<h { for c in 0..<w where coverage[r * w + c] != 0 {
        minR = min(minR, r); maxR = max(maxR, r); minC = min(minC, c); maxC = max(maxC, c)
    } }
    guard maxR >= 0 else { return nil }
    precondition(minR > 0 && minC > 0 && maxR < h - 1 && maxC < w - 1, "ink reaches the bake margin")
    let cw = maxC - minC + 1, ch = maxR - minR + 1
    var cropped = [UInt8](repeating: 0, count: cw * ch)
    for r in 0..<ch { for c in 0..<cw { cropped[r * cw + c] = coverage[(minR + r) * w + minC + c] } }
    // Origin column = `margin` (floor of margin + fraction); baseline row = `above` (h − below).
    return BTXFont.Bitmap(left: Int16(minC - margin), top: Int16(minR - above), width: UInt16(cw), height: UInt16(ch),
                          coverage: cropped)
}

func bake(name: String, size: Int) -> BTXFont {
    let font = ctFont(name, size: size)
    // Every MacRoman printable character: 0x20–0xFF less DEL.
    let characters: [(scalar: UInt32, string: String)] = (0x20...0xFF).filter { $0 != 0x7F }.map { byte in
        let s = String(bytes: [UInt8(byte)], encoding: .macOSRoman)!
        precondition(s.unicodeScalars.count == 1, "MacRoman 0x\(String(byte, radix: 16)) is not one scalar")
        return (s.unicodeScalars.first!.value, s)
    }
    var bitmaps: [BTXFont.Bitmap] = []
    var index: [BTXFont.Bitmap: UInt16] = [:]
    var maxPhases = 0
    /// One drawing unit (a character, or a ligature pair): its line metrics and its phase segments. Sampled at 64
    /// fractions plus 1⁻, then each change between neighbouring samples is bisected to the exact Double where
    /// CoreGraphics switches bitmap.
    func unit(_ l: CTLine) -> BTXFont.Glyph {
        let m = advance(l)
        func draw(_ t: Double) -> BTXFont.Bitmap? {
            render(l, fraction: t, advance: m.advance, ascent: m.ascent, descent: m.descent)
        }
        func id(_ b: BTXFont.Bitmap?) -> UInt16 {
            guard let b else { return BTXFont.blank }
            if let i = index[b] { return i }
            let i = UInt16(bitmaps.count)
            precondition(i != BTXFont.blank, "too many bitmaps")
            bitmaps.append(b); index[b] = i
            return i
        }
        /// The switches in (lo, hi] given draw(lo) == a and draw(hi) == b ≠ a: each switch is the smallest Double
        /// that draws the new bitmap (recursing where a third bitmap appears between the two).
        func switches(_ lo: Double, _ a: BTXFont.Bitmap?, _ hi: Double, _ b: BTXFont.Bitmap?)
            -> [(Double, BTXFont.Bitmap?)] {
            let mid = (lo + hi) / 2
            guard mid > lo, mid < hi else { return [(hi, b)] }
            let c = draw(mid)
            if c == a { return switches(mid, a, hi, b) }
            if c == b { return switches(lo, a, mid, b) }
            return switches(lo, a, mid, c) + switches(mid, c, hi, b)
        }
        // The last sample is the largest Double below 1: CoreGraphics also switches just short of the next pixel
        // (≈ 0.999, to that pixel's phase 0 — the bitmap one column right), which 63/64 would miss.
        let samples = 64
        let at = (0...samples).map { k in k == samples ? (1.0).nextDown : Double(k) / Double(samples) }
        var previous = draw(0)
        var phases = [BTXFont.Phase(start: 0, bitmap: id(previous))]
        for k in 1...samples {
            let t = at[k]
            let next = draw(t)
            guard next != previous else { continue }
            for (start, b) in switches(at[k - 1], previous, t, next) {
                phases.append(BTXFont.Phase(start: start, bitmap: id(b)))
            }
            previous = next
        }
        maxPhases = max(maxPhases, phases.count)
        return BTXFont.Glyph(advance: m.advance, ascent: m.ascent, descent: m.descent, phases: phases)
    }
    func glyphCount(_ l: CTLine) -> Int {
        (CTLineGetGlyphRuns(l) as! [CTRun]).reduce(0) { $0 + CTRunGetGlyphCount($1) }
    }
    var glyphs: [UInt32: BTXFont.Glyph] = [:]
    var counts: [UInt32: Int] = [:]
    for (scalar, s) in characters {
        let l = line(s, font: font)
        glyphs[scalar] = unit(l)
        counts[scalar] = glyphCount(l)
    }
    // Pairs: a ligature where CoreText draws other than the characters' own glyphs (Geneva's "fi"); otherwise
    // kerning = how much the two-character line's advance differs from its characters' own.
    var kerning: [BTXFont.Pair: Double] = [:]
    var ligatures: [BTXFont.Pair: BTXFont.Glyph] = [:]
    for (a, sa) in characters { for (b, sb) in characters {
        let l = line(sa + sb, font: font)
        if glyphCount(l) != counts[a]! + counts[b]! {
            ligatures[BTXFont.Pair(a, b)] = unit(l)
            continue
        }
        let k = advance(l).advance - glyphs[a]!.advance - glyphs[b]!.advance
        if abs(k) > 1e-9 { kerning[BTXFont.Pair(a, b)] = k }
    } }
    let ascent = Double(CTFontGetAscent(font)), descent = Double(CTFontGetDescent(font))
    print("\(name) \(size): \(CTFontCopyPostScriptName(font)) ascent \(ascent) descent \(descent); "
          + "\(glyphs.count) glyphs, \(bitmaps.count) bitmaps (≤ \(maxPhases) phases per glyph), \(kerning.count) kerning pairs"
          + ", ligatures \(ligatures.keys.sorted().map { String(UnicodeScalar($0.left)!) + String(UnicodeScalar($0.right)!) })")
    return BTXFont(name: name, size: size, ascent: ascent, descent: descent, bitmaps: bitmaps, glyphs: glyphs,
                   kerning: kerning, ligatures: ligatures)
}

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: btx-bake-font <output-directory>\n".utf8))
    exit(2)
}
let out = URL(fileURLWithPath: arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
for (name, size) in faces {
    let f = bake(name: name, size: size)
    try f.encoded().write(to: out.appendingPathComponent(BTXFont.fileName(name: name, size: size)))
}
#else
import Foundation
FileHandle.standardError.write(Data("btx-bake-font needs CoreText (run it on the Mac)\n".utf8))
exit(1)
#endif
