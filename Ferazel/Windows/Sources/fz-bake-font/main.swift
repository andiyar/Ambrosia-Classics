// fz-bake-font <output-directory> — bakes the faces Ferazel's Wand draws into `.fzfont` files (WF2, D43 Ruling 2; format
// in FerazelWinKit/FZFont.swift; BTX `btx-bake-font` shape). Fonts are resolved only through the Mac app's own
// `CoreTextRasterizer` (`ctFont`, `fontInfo`); each unit is a CTLine with the same attributes as its `rasterize`, drawn
// antialiased without font smoothing into an 8-bit alpha-only context, at sampled and bisected subpixel origins.
// Mac-only; on other platforms it only says so. Re-run after any text-path change (Ruling 16(d)): the staleness test
// fails otherwise.
#if canImport(CoreText)
import CoreGraphics
import CoreText
import FerazelWinKit
import Foundation
import HectorResources

enum FZBaker {
    /// The faces the game draws (font, size, face): `.UpdateTextStats`' Times 12 bold (`StatusBar.swift:152`),
    /// `.UpdateItemStat`'s Geneva 9 plain and Geneva 8 bold (`:196–197`, `:217–218`), the conversation's Times 18
    /// plain (`ConversationRun.swift:474,488,505`), and the in-window dialogs' UI font bold 12 (font 0 face 1, WF4a).
    static let faces: [(font: Int16, size: Int16, face: Int16)] = [
        (0, 12, 1), (3, 8, 1), (3, 9, 0), (20, 12, 1), (20, 18, 0),
    ]

    /// `CoreTextRasterizer.rasterize`'s attributes exactly.
    static func line(_ s: String, font: CTFont) -> CTLine {
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorFromContextAttributeName as String): true,
        ]
        return CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: attributes))
    }

    static func metrics(_ l: CTLine) -> (advance: Double, ascent: Double, descent: Double) {
        var a: CGFloat = 0, d: CGFloat = 0
        let w = CTLineGetTypographicBounds(l, &a, &d, nil)
        return (Double(w), Double(a), Double(d))
    }

    /// The coverage CoreText draws for `l` with its origin at x = `fraction` (of a pixel), cropped to its ink.
    static func render(_ l: CTLine, fraction: Double, advance: Double, ascent: Double, descent: Double) -> FZFont.Bitmap? {
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
        return FZFont.Bitmap(left: Int16(minC - margin), top: Int16(minR - above), width: UInt16(cw),
                             height: UInt16(ch), coverage: cropped)
    }

    /// One face, every MacRoman byte's character (0x00–0xFF; `MacRoman.decode`, the table `rasterize(byte:)` uses),
    /// the kerning pairs and ligatures among the printable ones (0x20–0xFF less DEL). Returns the face and a summary.
    static func bake(font: Int16, size: Int16, face: Int16,
                     using rasterizer: CoreTextRasterizer = CoreTextRasterizer()) -> (font: FZFont, summary: String) {
        let ct = rasterizer.ctFont(font, size: size, face: face)
        let characters: [(scalar: UInt32, string: String)] = (0...255).map { byte in
            let s = MacRoman.decode([UInt8(byte)])
            precondition(s.unicodeScalars.count == 1, "MacRoman 0x\(String(byte, radix: 16)) is not one scalar")
            return (s.unicodeScalars.first!.value, s)
        }
        let printable = characters.enumerated().filter { $0.offset >= 0x20 && $0.offset != 0x7F }.map(\.element)
        var bitmaps: [FZFont.Bitmap] = []
        var index: [FZFont.Bitmap: UInt16] = [:]
        var maxPhases = 0
        /// One drawing unit (a character, or a ligature pair): its line metrics and its phase segments. Sampled at 64
        /// fractions plus 1⁻, then each change between neighbouring samples is bisected to the exact Double where
        /// CoreGraphics switches bitmap.
        func unit(_ l: CTLine) -> FZFont.Glyph {
            let m = metrics(l)
            func draw(_ t: Double) -> FZFont.Bitmap? {
                render(l, fraction: t, advance: m.advance, ascent: m.ascent, descent: m.descent)
            }
            func id(_ b: FZFont.Bitmap?) -> UInt16 {
                guard let b else { return FZFont.blank }
                if let i = index[b] { return i }
                let i = UInt16(bitmaps.count)
                precondition(i != FZFont.blank, "too many bitmaps")
                bitmaps.append(b); index[b] = i
                return i
            }
            /// The switches in (lo, hi] given draw(lo) == a and draw(hi) == b ≠ a: each switch is the smallest Double
            /// that draws the new bitmap (recursing where a third bitmap appears between the two).
            func switches(_ lo: Double, _ a: FZFont.Bitmap?, _ hi: Double, _ b: FZFont.Bitmap?)
                -> [(Double, FZFont.Bitmap?)] {
                let mid = (lo + hi) / 2
                guard mid > lo, mid < hi else { return [(hi, b)] }
                let c = draw(mid)
                if c == a { return switches(mid, a, hi, b) }
                if c == b { return switches(lo, a, mid, b) }
                return switches(lo, a, mid, c) + switches(mid, c, hi, b)
            }
            // The last sample is the largest Double below 1: CoreGraphics also switches just short of the next pixel.
            let samples = 64
            let at = (0...samples).map { k in k == samples ? (1.0).nextDown : Double(k) / Double(samples) }
            var previous = draw(0)
            var phases = [FZFont.Phase(start: 0, bitmap: id(previous))]
            for k in 1...samples {
                let t = at[k]
                let next = draw(t)
                guard next != previous else { continue }
                for (start, b) in switches(at[k - 1], previous, t, next) {
                    phases.append(FZFont.Phase(start: start, bitmap: id(b)))
                }
                previous = next
            }
            maxPhases = max(maxPhases, phases.count)
            return FZFont.Glyph(advance: m.advance, ascent: m.ascent, descent: m.descent, phases: phases)
        }
        /// The glyph ids CoreText draws for `l`, run by run.
        func glyphIDs(_ l: CTLine) -> [CGGlyph] {
            (CTLineGetGlyphRuns(l) as! [CTRun]).flatMap { run -> [CGGlyph] in
                var ids = [CGGlyph](repeating: 0, count: CTRunGetGlyphCount(run))
                CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &ids)
                return ids
            }
        }
        var glyphs: [UInt32: FZFont.Glyph] = [:]
        var ids: [UInt32: [CGGlyph]] = [:]
        for (scalar, s) in characters {
            let l = line(s, font: ct)
            glyphs[scalar] = unit(l)
            ids[scalar] = glyphIDs(l)
        }
        /// The two glyphs as `BakedTextRasterizer` composes them (phase bitmaps, source-over) with the first at origin
        /// 0 and the second at its advance plus `k`, cropped to the ink — in `render`'s frame.
        func composed(_ a: UInt32, _ b: UInt32, k: Double) -> FZFont.Bitmap? {
            var ink: [Int: UInt32] = [:]                    // row << 16 | column (both offset) → coverage
            let bias = 1 << 15
            for (scalar, x) in [(a, 0.0), (b, glyphs[a]!.advance + k)] {
                let column = x.rounded(.down)
                let i = glyphs[scalar]!.bitmap(at: x - column)
                guard i != FZFont.blank else { continue }
                let bm = bitmaps[Int(i)]
                for r in 0..<Int(bm.height) { for c in 0..<Int(bm.width) {
                    let s = UInt32(bm.coverage[r * Int(bm.width) + c])
                    guard s != 0 else { continue }
                    let key = (Int(bm.top) + r + bias) << 16 | (Int(column) + Int(bm.left) + c + bias)
                    let d = ink[key] ?? 0
                    ink[key] = s + d * (255 - s) / 255
                } }
            }
            guard !ink.isEmpty else { return nil }
            let rows = ink.keys.map { $0 >> 16 }, cols = ink.keys.map { $0 & 0xFFFF }
            let top = rows.min()!, left = cols.min()!
            let h = rows.max()! - top + 1, w = cols.max()! - left + 1
            var coverage = [UInt8](repeating: 0, count: w * h)
            for (key, v) in ink { coverage[((key >> 16) - top) * w + (key & 0xFFFF) - left] = UInt8(v) }
            return FZFont.Bitmap(left: Int16(left - bias), top: Int16(top - bias), width: UInt16(w), height: UInt16(h),
                                 coverage: coverage)
        }
        // Pairs: a ligature (a unit drawn whole) where CoreText draws other than the characters' own glyphs ("fi",
        // the UI font's contextual forms beside "ƒ") or other than their composition (overlapping ink CoreText does
        // not composite source-over: the UI font's "__"); otherwise kerning = how much the two-character line's
        // advance differs from its characters' own.
        var kerning: [FZFont.Pair: Double] = [:]
        var ligatures: [FZFont.Pair: FZFont.Glyph] = [:]
        for (a, sa) in printable { for (b, sb) in printable {
            let l = line(sa + sb, font: ct)
            let m = metrics(l)
            let k = m.advance - glyphs[a]!.advance - glyphs[b]!.advance
            if glyphIDs(l) != ids[a]! + ids[b]!
                || render(l, fraction: 0, advance: m.advance, ascent: m.ascent, descent: m.descent)
                    != composed(a, b, k: k) {
                ligatures[FZFont.Pair(a, b)] = unit(l)
                continue
            }
            if k != 0 { kerning[FZFont.Pair(a, b)] = k }
        } }
        let info = rasterizer.fontInfo(font: font, size: size, face: face)
        let name = CTFontCopyPostScriptName(ct) as String
        let f = FZFont(font: font, size: size, face: face, name: name,
                       info: FZFont.Info(ascent: Int16(info.ascent), descent: Int16(info.descent),
                                         leading: Int16(info.leading)),
                       ascent: Double(CTFontGetAscent(ct)), descent: Double(CTFontGetDescent(ct)),
                       bitmaps: bitmaps, glyphs: glyphs, kerning: kerning, ligatures: ligatures)
        let summary = "font \(font) size \(size) face \(face): \(name), fontInfo \(info); \(glyphs.count) glyphs, "
            + "\(bitmaps.count) bitmaps (≤ \(maxPhases) phases per glyph), \(kerning.count) kerning pairs, ligatures "
            + "\(ligatures.keys.sorted().map { String(UnicodeScalar($0.left)!) + String(UnicodeScalar($0.right)!) })"
        return (f, summary)
    }

    static func main(_ arguments: [String]) -> Int32 {
        guard arguments.count == 2 else {
            FileHandle.standardError.write(Data("usage: fz-bake-font <output-directory>\n".utf8))
            return 2
        }
        let out = URL(fileURLWithPath: arguments[1], isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
            let rasterizer = CoreTextRasterizer()
            for (font, size, face) in faces {
                let (f, summary) = bake(font: font, size: size, face: face, using: rasterizer)
                print(summary)
                try f.encoded().write(to: out.appendingPathComponent(FZFont.fileName(font: font, size: size, face: face)))
            }
        } catch {
            FileHandle.standardError.write(Data("fz-bake-font: \(error)\n".utf8))
            return 1
        }
        return 0
    }
}

exit(FZBaker.main(CommandLine.arguments))
#else
import Foundation
fputs("fz-bake-font needs CoreText (run it on the Mac)\n", stderr)
exit(1)
#endif
