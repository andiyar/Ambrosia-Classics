import FerazelRender
import Foundation
import HectorResources

/// The game's `TextRasterizer` without CoreText (WF2, D43 Ruling 2; copy-adapted from BTX `BitmapFontRasterizer`):
/// draws from the faces `fz-bake-font` baked on the Mac through `CoreTextRasterizer`. It mirrors that rasterizer step
/// for step — the line laid out as CoreText lays it out (Float64 advances plus pair kerning, ligatures as one unit), the
/// same box (`pad` columns either side, ⌈ascent⌉ + 1 rows above the baseline, ⌈descent⌉ + 1 below, ⌈advance⌉ wide),
/// each glyph's phase bitmap composited into one coverage mask (CoreGraphics' truncating A8 source-over) — and only
/// then, below `smoothingThreshold`, the Mac's two-level cut (≥ 0x80 → 255, else 0) on the composed mask, never per
/// glyph. `charWidth` is the Mac's rounding of the baked advance; `fontInfo` the Mac's, baked.
///
/// Measured against `CoreTextRasterizer` byte for byte (FerazelWinKitTests.BakedTextTests). Not modelled (no game
/// string reaches them): contextual alternates and kerning across a ligature's inner edge. C0 controls and DEL draw
/// their baked unit but are transparent to kerning; a tab moves the pen to the next 28 px stop (CoreText's default
/// interval). A face that was not baked draws nothing, measures 0, and is logged once.
public final class BakedTextRasterizer: TextRasterizer {
    /// `CoreTextRasterizer.smoothingThreshold` (the oracle tests hold the two equal).
    public static let smoothingThreshold: Int16 = 14
    public static let fileExtension = "fzfont"
    /// CoreText's default tab interval (no paragraph style): a tab advances the pen to the next multiple.
    static let tabInterval = 28.0
    private static let question: UInt32 = 0x3F, tab: UInt32 = 0x09

    struct Key: Hashable { var font: Int16, size: Int16, face: Int16 }

    private var faces: [Key: FZFont] = [:]
    private var reported: Set<Key> = []
    private let log: (String) -> Void

    public enum LoadError: Error, Equatable {
        /// The fonts directory holds no `*.fzfont` — every string would draw invisibly, so it is refused.
        case noFonts(String)
    }

    /// `log` receives one line per face asked for and not baked (C stdio or the log file in the executable — never
    /// `NSLog` / `FileHandle.standardError`, Ruling 18).
    public init(fonts: [FZFont], log: @escaping (String) -> Void = { _ in }) {
        self.log = log
        for f in fonts { faces[Key(font: f.font, size: f.size, face: f.face)] = f }
    }

    /// Loads every `*.fzfont` in `fontsDirectory`; throws if the directory is missing or holds none.
    public convenience init(fontsDirectory: URL, log: @escaping (String) -> Void = { _ in }) throws {
        let names = try FileManager.default.contentsOfDirectory(atPath: fontsDirectory.path)
            .filter { $0.hasSuffix("." + Self.fileExtension) }.sorted()
        guard !names.isEmpty else { throw LoadError.noFonts(fontsDirectory.path) }
        self.init(fonts: try names.map { try FZFont(data: Data(contentsOf: fontsDirectory.appendingPathComponent($0))) },
                  log: log)
    }

    /// The baked faces (font, size, face), sorted.
    public var bakedFaces: [[Int16]] {
        faces.keys.map { [$0.font, $0.size, $0.face] }.sorted { $0.lexicographicallyPrecedes($1) }
    }

    func face(_ font: Int16, _ size: Int16, _ face: Int16) -> FZFont? {
        let key = Key(font: font, size: size, face: face)
        if let f = faces[key] { return f }
        if reported.insert(key).inserted {
            log("BakedTextRasterizer: no baked face for font \(font) size \(size) face \(face); its text draws nothing")
        }
        return nil
    }

    /// Glyphs and their pen x positions (from the line's origin), the line's advance, and its ascent/descent.
    struct Layout {
        var glyphs: [(glyph: FZFont.Glyph, x: Double)] = []
        var advance: Double = 0
        var ascent: Double = 0, descent: Double = 0
    }

    func layout(_ s: String, in f: FZFont) -> Layout {
        var out = Layout()
        var pen = 0.0
        let scalars = s.unicodeScalars.compactMap { u -> UInt32? in
            f.glyphs[u.value] != nil ? u.value : (f.glyphs[Self.question] != nil ? Self.question : nil)
        }
        var previous: UInt32?
        var i = 0
        while i < scalars.count {
            let scalar = scalars[i]
            var g = f.glyphs[scalar]!, last = scalar, step = 1
            if scalar == Self.tab {
                pen = ((pen / Self.tabInterval).rounded(.down) + 1) * Self.tabInterval
                out.ascent = max(out.ascent, g.ascent)
                out.descent = max(out.descent, g.descent)
                previous = nil
                i += 1
                continue
            }
            if i + 1 < scalars.count, let lig = f.ligatures[FZFont.Pair(scalar, scalars[i + 1])] {
                g = lig; last = scalars[i + 1]; step = 2                  // drawn as one unit, as CoreText does
            }
            if let p = previous, let k = f.kerning[FZFont.Pair(p, scalar)] { pen += k }
            out.glyphs.append((g, pen))
            pen += g.advance
            out.ascent = max(out.ascent, g.ascent)
            out.descent = max(out.descent, g.descent)
            // C0 controls and DEL are transparent to kerning.
            if !(scalar < 0x20 || scalar == 0x7F) { previous = last }
            i += step
        }
        out.advance = pen
        return out
    }

    public func rasterize(_ text: String, font: Int16, size: Int16, face: Int16)
        -> (left: Int, top: Int, width: Int, height: Int, coverage: [UInt8]) {
        guard !text.isEmpty, let f = self.face(font, size, face) else { return (0, 0, 0, 0, []) }
        let l = layout(text, in: f)
        let advance = Int(l.advance.rounded(.up))
        let pad = 2
        let above = Int(l.ascent.rounded(.up)) + 1, below = Int(l.descent.rounded(.up)) + 1
        let w = advance + 2 * pad, h = above + below
        guard w > 0, h > 0 else { return (0, 0, 0, 0, []) }
        // The line's coverage, glyph by glyph (source-over), clipped to the box; the baseline is row `above`.
        var coverage = [UInt8](repeating: 0, count: w * h)
        for (g, x) in l.glyphs {
            let origin = Double(pad) + x
            let column = origin.rounded(.down)
            let index = g.bitmap(at: origin - column)
            guard index != FZFont.blank else { continue }
            let b = f.bitmaps[Int(index)]
            let left = Int(column) + Int(b.left), top = above + Int(b.top)
            for r in 0..<Int(b.height) {
                let y = top + r
                guard y >= 0, y < h else { continue }
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
        // The Mac's cut, on the composed line (`CoreTextRasterizer.rasterize`).
        if size < Self.smoothingThreshold { coverage = coverage.map { $0 >= 0x80 ? 0xff : 0 } }
        return (-pad, -above, w, h, coverage)
    }

    public func charWidth(_ byte: UInt8, font: Int16, size: Int16, face: Int16) -> Int {
        guard let f = self.face(font, size, face),
              let scalar = MacRoman.decode([byte]).unicodeScalars.first,
              let g = f.glyphs[scalar.value] else { return 0 }
        return Int(g.advance.rounded())
    }

    public func fontInfo(font: Int16, size: Int16, face: Int16) -> (ascent: Int, descent: Int, leading: Int) {
        guard let f = self.face(font, size, face) else { return (0, 0, 0) }
        return (Int(f.info.ascent), Int(f.info.descent), Int(f.info.leading))
    }
}
