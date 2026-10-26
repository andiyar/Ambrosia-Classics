import Foundation

/// One baked face (WF2, D43 Ruling 2; copy-adapted from BTX `BTXFont.swift`): every MacRoman character as the Mac's
/// `CoreTextRasterizer` draws it (`fz-bake-font`), so Windows draws the same text without CoreText.
///
/// CoreGraphics places glyphs at fractional pen positions and snaps each to a few subpixel phases, so one bitmap per
/// glyph cannot match it. Each glyph therefore carries its phase segments — from fraction `start` (of a pixel, the
/// glyph origin's x minus its floor) up to the next segment's start, CoreText draws bitmap `bitmap` — found exactly by
/// the baker (bisection to the Double). Bitmaps are de-duplicated across the face. No string is baked whole.
///
/// File format `.fzfont` = BTX's `.btxfont` layout under its own magic, with the QuickDraw face and `GetFontInfo` added
/// (all integers little-endian, `f64` IEEE-754 little-endian):
/// ```
/// "FZF1"  u16 version (1)
/// i16 font (TextFont family number)  i16 size (points)  i16 face (TextFace bits)
/// u16 nameLength, UTF-8 name (the PostScript name CoreText resolved; informational)
/// i16 infoAscent  i16 infoDescent  i16 infoLeading      (`CoreTextRasterizer.fontInfo`, whole pixels)
/// f64 ascent  f64 descent                               (the resolved font's own metrics, positive)
/// u32 bitmapCount  u32 glyphCount  u32 kernCount
/// bitmapCount × { i16 left  i16 top  u16 width  u16 height  width·height × u8 coverage (rows top first) }
///     left = first column relative to floor(origin x); top = first row relative to the baseline row (negative
///     = above the baseline; the baseline row is the first row BELOW the baseline)
/// glyphCount × { u32 Unicode scalar  GLYPH }
///     GLYPH = f64 advance  f64 ascent  f64 descent  u16 segmentCount  segmentCount × { f64 start  u16 bitmap }
///     advance/ascent/descent: CTLineGetTypographicBounds of this character alone (a fallback font raises them);
///     segments ascend from start 0; bitmap 0xFFFF = nothing drawn
/// kernCount × { u32 left scalar  u32 right scalar  f64 adjustment }   (pen-position change, px)
/// u32 ligatureCount
/// ligatureCount × { u32 left scalar  u32 right scalar  GLYPH }
///     a pair CoreText draws as other than its two glyphs ("fi", "fl"): drawn as one unit
/// ```
/// Glyphs are written in ascending scalar order, kerning pairs and ligatures in ascending (left, right) order, so
/// baking is deterministic. The coverage is CoreText's antialiased coverage before the Mac's 0/255 cut (the rasterizer
/// cuts the composed line, never a glyph).
public struct FZFont: Equatable, Sendable {
    public static let magic: [UInt8] = Array("FZF1".utf8)
    public static let version: UInt16 = 1
    public static let blank: UInt16 = 0xFFFF

    public struct Bitmap: Equatable, Hashable, Sendable {
        public var left: Int16, top: Int16
        public var width: UInt16, height: UInt16
        public var coverage: [UInt8]
        public init(left: Int16, top: Int16, width: UInt16, height: UInt16, coverage: [UInt8]) {
            precondition(coverage.count == Int(width) * Int(height), "coverage size ≠ width·height")
            self.left = left; self.top = top; self.width = width; self.height = height; self.coverage = coverage
        }
    }

    public struct Glyph: Equatable, Sendable {
        public var advance: Double, ascent: Double, descent: Double
        /// Ascending by `start`, the first at 0.
        public var phases: [Phase]
        public init(advance: Double, ascent: Double, descent: Double, phases: [Phase]) {
            precondition(phases.first?.start == 0, "a glyph's phases start at 0")
            self.advance = advance; self.ascent = ascent; self.descent = descent; self.phases = phases
        }
        /// The bitmap drawn with the origin at `fraction` (0 ≤ fraction < 1) of a pixel.
        public func bitmap(at fraction: Double) -> UInt16 {
            var i = phases.count - 1
            while i > 0 && phases[i].start > fraction { i -= 1 }
            return phases[i].bitmap
        }
    }

    public struct Phase: Equatable, Sendable {
        public var start: Double
        public var bitmap: UInt16
        public init(start: Double, bitmap: UInt16) { self.start = start; self.bitmap = bitmap }
    }

    public struct Pair: Hashable, Comparable, Sendable {
        public var left: UInt32, right: UInt32
        public init(_ left: UInt32, _ right: UInt32) { self.left = left; self.right = right }
        public static func < (a: Pair, b: Pair) -> Bool { (a.left, a.right) < (b.left, b.right) }
    }

    /// `GetFontInfo` as the Mac answers it (`CoreTextRasterizer.fontInfo`).
    public struct Info: Equatable, Sendable {
        public var ascent: Int16, descent: Int16, leading: Int16
        public init(ascent: Int16, descent: Int16, leading: Int16) {
            self.ascent = ascent; self.descent = descent; self.leading = leading
        }
    }

    public var font: Int16, size: Int16, face: Int16
    public var name: String
    public var info: Info
    public var ascent: Double, descent: Double
    public var bitmaps: [Bitmap]
    public var glyphs: [UInt32: Glyph]
    public var kerning: [Pair: Double]
    public var ligatures: [Pair: Glyph]

    public init(font: Int16, size: Int16, face: Int16, name: String, info: Info, ascent: Double, descent: Double,
                bitmaps: [Bitmap], glyphs: [UInt32: Glyph], kerning: [Pair: Double], ligatures: [Pair: Glyph] = [:]) {
        self.font = font; self.size = size; self.face = face; self.name = name; self.info = info
        self.ascent = ascent; self.descent = descent
        self.bitmaps = bitmaps; self.glyphs = glyphs; self.kerning = kerning; self.ligatures = ligatures
    }

    /// The file a face is stored under: `<font>-<size>-<face>.fzfont` (`20-12-1.fzfont` = Times 12 bold).
    public static func fileName(font: Int16, size: Int16, face: Int16) -> String { "\(font)-\(size)-\(face).fzfont" }

    public enum FormatError: Error, Equatable {
        case badMagic, unsupportedVersion(UInt16), truncated, badName
        case badBitmapIndex(UInt16), badPhases, trailingBytes
    }

    // MARK: Encoding

    public func encoded() -> Data {
        var w = FZWriter()
        w.bytes(Self.magic)
        w.u16(Self.version)
        w.i16(font); w.i16(size); w.i16(face)
        let nameBytes = Array(name.utf8)
        w.u16(UInt16(nameBytes.count))
        w.bytes(nameBytes)
        w.i16(info.ascent); w.i16(info.descent); w.i16(info.leading)
        w.f64(ascent)
        w.f64(descent)
        w.u32(UInt32(bitmaps.count))
        w.u32(UInt32(glyphs.count))
        w.u32(UInt32(kerning.count))
        for b in bitmaps {
            w.i16(b.left)
            w.i16(b.top)
            w.u16(b.width)
            w.u16(b.height)
            w.bytes(b.coverage)
        }
        func glyph(_ g: Glyph) {
            w.f64(g.advance)
            w.f64(g.ascent)
            w.f64(g.descent)
            w.u16(UInt16(g.phases.count))
            for p in g.phases { w.f64(p.start); w.u16(p.bitmap) }
        }
        for scalar in glyphs.keys.sorted() {
            w.u32(scalar)
            glyph(glyphs[scalar]!)
        }
        for pair in kerning.keys.sorted() {
            w.u32(pair.left)
            w.u32(pair.right)
            w.f64(kerning[pair]!)
        }
        w.u32(UInt32(ligatures.count))
        for pair in ligatures.keys.sorted() {
            w.u32(pair.left)
            w.u32(pair.right)
            glyph(ligatures[pair]!)
        }
        return Data(w.out)
    }

    public init(data: Data) throws {
        var r = FZReader(Array(data))
        guard try r.bytes(4) == Self.magic else { throw FormatError.badMagic }
        let version = try r.u16()
        guard version == Self.version else { throw FormatError.unsupportedVersion(version) }
        font = try r.i16(); size = try r.i16(); face = try r.i16()
        guard let name = String(bytes: try r.bytes(Int(try r.u16())), encoding: .utf8) else {
            throw FormatError.badName
        }
        self.name = name
        info = Info(ascent: try r.i16(), descent: try r.i16(), leading: try r.i16())
        ascent = try r.f64()
        descent = try r.f64()
        let bitmapCount = Int(try r.u32()), glyphCount = Int(try r.u32()), kernCount = Int(try r.u32())
        var bitmaps: [Bitmap] = []
        for _ in 0..<bitmapCount {
            let left = try r.i16(), top = try r.i16()
            let width = try r.u16(), height = try r.u16()
            bitmaps.append(Bitmap(left: left, top: top, width: width, height: height,
                                  coverage: try r.bytes(Int(width) * Int(height))))
        }
        self.bitmaps = bitmaps
        func glyph() throws -> Glyph {
            let advance = try r.f64(), a = try r.f64(), d = try r.f64()
            var phases: [Phase] = []
            for _ in 0..<Int(try r.u16()) {
                let start = try r.f64(), i = try r.u16()
                guard i == Self.blank || Int(i) < bitmapCount else { throw FormatError.badBitmapIndex(i) }
                guard start >= 0, start < 1, start == 0 ? phases.isEmpty : start > (phases.last?.start ?? 1) else {
                    throw FormatError.badPhases
                }
                phases.append(Phase(start: start, bitmap: i))
            }
            guard !phases.isEmpty else { throw FormatError.badPhases }
            return Glyph(advance: advance, ascent: a, descent: d, phases: phases)
        }
        var glyphs: [UInt32: Glyph] = [:]
        for _ in 0..<glyphCount {
            let scalar = try r.u32()
            glyphs[scalar] = try glyph()
        }
        self.glyphs = glyphs
        var kerning: [Pair: Double] = [:]
        for _ in 0..<kernCount {
            let pair = Pair(try r.u32(), try r.u32())
            kerning[pair] = try r.f64()
        }
        self.kerning = kerning
        var ligatures: [Pair: Glyph] = [:]
        for _ in 0..<Int(try r.u32()) {
            let pair = Pair(try r.u32(), try r.u32())
            ligatures[pair] = try glyph()
        }
        self.ligatures = ligatures
        guard r.atEnd else { throw FormatError.trailingBytes }
    }
}

// MARK: - Little-endian byte helpers (portable: no unaligned loads)

private struct FZWriter {
    var out: [UInt8] = []
    mutating func bytes(_ b: [UInt8]) { out += b }
    mutating func u16(_ v: UInt16) { out += [UInt8(v & 0xFF), UInt8(v >> 8)] }
    mutating func i16(_ v: Int16) { u16(UInt16(bitPattern: v)) }
    mutating func u32(_ v: UInt32) { for i in 0..<4 { out.append(UInt8((v >> (8 * UInt32(i))) & 0xFF)) } }
    mutating func u64(_ v: UInt64) { for i in 0..<8 { out.append(UInt8((v >> (8 * UInt64(i))) & 0xFF)) } }
    mutating func f64(_ v: Double) { u64(v.bitPattern) }
}

private struct FZReader {
    let b: [UInt8]
    var i = 0
    init(_ b: [UInt8]) { self.b = b }
    var atEnd: Bool { i == b.count }
    mutating func bytes(_ n: Int) throws -> [UInt8] {
        guard n >= 0, i + n <= b.count else { throw FZFont.FormatError.truncated }
        defer { i += n }
        return Array(b[i..<(i + n)])
    }
    mutating func u16() throws -> UInt16 {
        let x = try bytes(2)
        return UInt16(x[0]) | UInt16(x[1]) << 8
    }
    mutating func i16() throws -> Int16 { Int16(bitPattern: try u16()) }
    mutating func u32() throws -> UInt32 {
        try bytes(4).enumerated().reduce(0) { $0 | UInt32($1.element) << (8 * UInt32($1.offset)) }
    }
    mutating func u64() throws -> UInt64 {
        try bytes(8).enumerated().reduce(0) { $0 | UInt64($1.element) << (8 * UInt64($1.offset)) }
    }
    mutating func f64() throws -> Double { Double(bitPattern: try u64()) }
}
