import BubbleTroubleCore
import BubbleTroubleRender
import Foundation

/// The compositor's `TextRasterizer` without CoreText (plan W2): draws from the faces `btx-bake-font` baked on the
/// Mac. It mirrors `BubbleTroubleX/App/CoreTextRasterizer.swift` step for step — the same pen layout (Float64
/// advances plus pair kerning, as CoreText lays out a line), the same clip box (`pad` columns either side,
/// ⌈ascent⌉ + 1 rows above the baseline, ⌈descent⌉ + 1 below), glyph coverage composited into one alpha mask
/// (source-over with CoreGraphics' truncating A8 arithmetic), then blended toward `rgb` with every touched pixel written opaque.
///
/// Measured against CoreText (BTXWinKitTests.CoreTextOracleTests): every MacRoman character and every game string
/// pixel-identical. Known residue: contextual forms are not modelled — the System faces' raised colon between digits
/// ("12:30") and their other contextual alternates (none of which a game string reaches) — nor kerning across a
/// ligature's inner edge; characters the faces lack draw as `?`. Control characters follow CoreText: C0 controls and
/// DEL draw nothing, take no width and are transparent to kerning; a tab moves the pen to the next 28 px stop
/// (CoreText's default tab interval).
public final class BitmapFontRasterizer: TextRasterizer {
    private var faces: [String: BTXFont] = [:]

    public enum LoadError: Error, Equatable {
        /// The fonts directory holds no `*.btxfont` — every string would draw invisibly, so it is refused.
        case noFonts(String)
    }

    /// Loads every `*.btxfont` in `fontsDirectory`; throws if the directory is missing or holds none.
    public convenience init(fontsDirectory: URL) throws {
        let names = try FileManager.default.contentsOfDirectory(atPath: fontsDirectory.path)
            .filter { $0.hasSuffix(".btxfont") }.sorted()
        guard !names.isEmpty else { throw LoadError.noFonts(fontsDirectory.path) }
        self.init(fonts: try names.map { try BTXFont(data: Data(contentsOf: fontsDirectory.appendingPathComponent($0))) })
    }

    /// `fonts` must not be empty.
    public init(fonts: [BTXFont]) {
        precondition(!fonts.isEmpty, "BitmapFontRasterizer needs at least one face")
        for f in fonts { faces[Self.key(f.name, f.size)] = f }
    }

    private static func key(_ name: String, _ size: Int) -> String { "\(name)/\(size)" }

    /// The face for `name`/`size`. A face that was not baked falls back to the same name at the nearest size, then
    /// to System 12 (the port font), then to any face — CoreText likewise substitutes rather than failing.
    func face(_ name: String, size: Int) -> BTXFont? {
        if let f = faces[Self.key(name, size)] { return f }
        if let f = faces.values.filter({ $0.name == name })
            .min(by: { (abs($0.size - size), $0.size) < (abs($1.size - size), $1.size) }) { return f }
        return faces[Self.key("System", 12)] ?? faces.values.sorted(by: { ($0.name, $0.size) < ($1.name, $1.size) }).first
    }

    /// Glyphs and their pen x positions (from the line's origin), the line's advance, and its ascent/descent.
    struct Layout {
        var glyphs: [(glyph: BTXFont.Glyph, x: Double)] = []
        var advance: Double = 0
        var ascent: Double, descent: Double
    }

    private static let question: UInt32 = 0x3F, tab: UInt32 = 0x09
    /// CoreText's default tab interval (no paragraph style): a tab advances the pen to the next multiple.
    static let tabInterval = 28.0

    func layout(_ s: String, in f: BTXFont) -> Layout {
        var out = Layout(ascent: 0, descent: 0)
        var pen = 0.0
        let scalars = s.precomposedStringWithCanonicalMapping.unicodeScalars.compactMap { u -> UInt32? in
            if u.value == Self.tab { return Self.tab }
            if u.value < 0x20 || u.value == 0x7F { return nil }        // drawn as nothing, transparent to kerning
            return f.glyphs[u.value] != nil ? u.value : (f.glyphs[Self.question] != nil ? Self.question : nil)
        }
        var previous: UInt32?
        var i = 0
        while i < scalars.count {
            let scalar = scalars[i]
            if scalar == Self.tab {
                pen = ((pen / Self.tabInterval).rounded(.down) + 1) * Self.tabInterval
                previous = nil
                i += 1
                continue
            }
            var g = f.glyphs[scalar]!, last = scalar, step = 1
            if i + 1 < scalars.count, let lig = f.ligatures[BTXFont.Pair(scalar, scalars[i + 1])] {
                g = lig; last = scalars[i + 1]; step = 2                  // drawn as one unit, as CoreText does
            }
            if let p = previous, let k = f.kerning[BTXFont.Pair(p, scalar)] { pen += k }
            out.glyphs.append((g, pen))
            pen += g.advance
            out.ascent = max(out.ascent, g.ascent)
            out.descent = max(out.descent, g.descent)
            previous = last
            i += step
        }
        out.advance = pen
        return out
    }

    public func width(_ s: String, font: String, size: Int) -> Int {
        guard let f = face(font, size: size) else { return 0 }
        return Int(layout(s, in: f).advance.rounded())
    }

    public func rasterize(_ s: String, font: String, size: Int, rgb: UInt32, into image: inout RGBAImage,
                          at: (h: Int, v: Int), centredIn: QDRect?) {
        guard !s.isEmpty, let f = face(font, size: size) else { return }
        let l = layout(s, in: f)
        let advance = Int(l.advance.rounded())
        var h = at.h
        if let r = centredIn {
            let rw = Int(r.right) - Int(r.left)
            h = Int(r.left) + (rw - advance) / 2                      // C truncating division
        }
        let pad = 2
        let above = Int(l.ascent.rounded(.up)) + 1, below = Int(l.descent.rounded(.up)) + 1
        let w = advance + 2 * pad, ht = above + below
        guard w > 0, ht > 0 else { return }
        // The line's alpha mask, glyph by glyph (source-over), clipped to the box; the baseline is row `above`.
        var coverage = [UInt8](repeating: 0, count: w * ht)
        for (g, x) in l.glyphs {
            let origin = Double(pad) + x
            let column = origin.rounded(.down)
            let index = g.bitmap(at: origin - column)
            guard index != BTXFont.blank else { continue }
            let b = f.bitmaps[Int(index)]
            let left = Int(column) + Int(b.left), top = above + Int(b.top)
            for r in 0..<Int(b.height) {
                let y = top + r
                guard y >= 0, y < ht else { continue }
                for c in 0..<Int(b.width) {
                    let s = UInt32(b.coverage[r * Int(b.width) + c])
                    guard s != 0 else { continue }
                    let x = left + c
                    guard x >= 0, x < w else { continue }
                    let d = UInt32(coverage[y * w + x])
                    coverage[y * w + x] = UInt8(s + d * (255 - s) / 255)    // CoreGraphics' A8 source-over
                }
            }
        }
        // Row r of the mask lands on image row v − above + r; column c on h − pad + c (as CoreTextRasterizer).
        let red = (rgb >> 16) & 0xFF, green = (rgb >> 8) & 0xFF, blue = rgb & 0xFF
        for r in 0..<ht {
            let y = at.v - above + r
            guard y >= 0, y < image.height else { continue }
            for c in 0..<w {
                let a = UInt32(coverage[r * w + c])
                guard a != 0 else { continue }
                let x = h - pad + c
                guard x >= 0, x < image.width else { continue }
                let dst = image[x, y]
                func mix(_ src: UInt32, _ shift: UInt32) -> UInt32 {
                    let d = (dst >> shift) & 0xFF
                    return ((src * a + d * (255 - a) + 127) / 255) << shift
                }
                image[x, y] = 0xFF00_0000 | mix(red, 16) | mix(green, 8) | mix(blue, 0)
            }
        }
    }
}
