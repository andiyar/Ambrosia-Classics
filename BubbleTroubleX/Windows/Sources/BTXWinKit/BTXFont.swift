import Foundation

/// One baked system-font face (plan W2): every MacRoman printable character drawn by CoreText on the Mac
/// (`btx-bake-font`), so Windows can draw the same text without CoreText.
///
/// CoreGraphics places glyphs at fractional pen positions and snaps each to a few subpixel phases, so one bitmap
/// per glyph cannot match it. Each glyph therefore carries its phase segments — from fraction `start` (of a pixel,
/// the glyph origin's x minus its floor) up to the next segment's start, CoreText draws bitmap `bitmap` — found
/// exactly by the baker (bisection to the Double), since the snap points are not round binary fractions (the System
/// font snaps to thirds: 341/1024, 682/1024; Geneva to quarters). Bitmaps are de-duplicated across the face.
///
/// File format `.btxfont` (all integers little-endian, `f64` IEEE-754 little-endian):
/// ```
/// "BTXF"  u16 version (1)
/// u16 nameLength, UTF-8 name ("Geneva", "System", "System-Bold")   u16 size (points)
/// f64 ascent  f64 descent                         (the face's own metrics, positive)
/// u32 bitmapCount  u32 glyphCount  u32 kernCount
/// bitmapCount × { i16 left  i16 top  u16 width  u16 height  width·height × u8 coverage (rows top first) }
///     left = first column relative to floor(origin x); top = first row relative to the baseline row (negative
///     = above the baseline; the baseline row is the first row BELOW the baseline)
/// glyphCount × { u32 Unicode scalar  GLYPH }
///     GLYPH = f64 advance  f64 ascent  f64 descent  u16 segmentCount  segmentCount × { f64 start  u16 bitmap }
///     ascent/descent: the line metrics CoreText reports for this character alone (a fallback font raises them);
///     segments ascend from start 0; bitmap 0xFFFF = nothing drawn (space)
/// kernCount × { u32 left scalar  u32 right scalar  f64 adjustment }   (pen-position change, px)
/// u32 ligatureCount
/// ligatureCount × { u32 left scalar  u32 right scalar  GLYPH }
///     a pair CoreText draws as other than its two glyphs (Geneva's "fi", "fl"): drawn as one unit
/// ```
/// Glyphs are written in ascending scalar order, kerning pairs and ligatures in ascending (left, right) order, so baking is
/// deterministic.
public struct BTXFont: Equatable, Sendable {
    public static let magic: [UInt8] = Array("BTXF".utf8)
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

    public var name: String
    public var size: Int
    public var ascent: Double, descent: Double
    public var bitmaps: [Bitmap]
    public var glyphs: [UInt32: Glyph]
    public var kerning: [Pair: Double]
    public var ligatures: [Pair: Glyph]

    public init(name: String, size: Int, ascent: Double, descent: Double, bitmaps: [Bitmap],
                glyphs: [UInt32: Glyph], kerning: [Pair: Double], ligatures: [Pair: Glyph] = [:]) {
        self.name = name; self.size = size; self.ascent = ascent; self.descent = descent
        self.bitmaps = bitmaps; self.glyphs = glyphs; self.kerning = kerning; self.ligatures = ligatures
    }

    /// The file name a face is stored under: `Geneva-9.btxfont`, `System-Bold-12.btxfont`.
    public static func fileName(name: String, size: Int) -> String { "\(name)-\(size).btxfont" }

    public enum FormatError: Error, Equatable {
        case badMagic, unsupportedVersion(UInt16), truncated, badName
        case badBitmapIndex(UInt16), badPhases
    }

    // MARK: Encoding

    public func encoded() -> Data {
        var w = LEWriter()
        w.bytes(Self.magic)
        w.u16(Self.version)
        let nameBytes = Array(name.utf8)
        w.u16(UInt16(nameBytes.count))
        w.bytes(nameBytes)
        w.u16(UInt16(size))
        w.f64(ascent)
        w.f64(descent)
        w.u32(UInt32(bitmaps.count))
        w.u32(UInt32(glyphs.count))
        w.u32(UInt32(kerning.count))
        for b in bitmaps {
            w.u16(UInt16(bitPattern: b.left))
            w.u16(UInt16(bitPattern: b.top))
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
        var r = LEReader(Array(data))
        guard try r.bytes(4) == Self.magic else { throw FormatError.badMagic }
        let version = try r.u16()
        guard version == Self.version else { throw FormatError.unsupportedVersion(version) }
        guard let name = String(bytes: try r.bytes(Int(try r.u16())), encoding: .utf8) else {
            throw FormatError.badName
        }
        self.name = name
        size = Int(try r.u16())
        ascent = try r.f64()
        descent = try r.f64()
        let bitmapCount = Int(try r.u32()), glyphCount = Int(try r.u32()), kernCount = Int(try r.u32())
        var bitmaps: [Bitmap] = []
        bitmaps.reserveCapacity(bitmapCount)
        for _ in 0..<bitmapCount {
            let left = Int16(bitPattern: try r.u16()), top = Int16(bitPattern: try r.u16())
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
    }
}

// MARK: - Little-endian byte helpers (portable: no unaligned loads)

private struct LEWriter {
    var out: [UInt8] = []
    mutating func bytes(_ b: [UInt8]) { out += b }
    mutating func u16(_ v: UInt16) { out += [UInt8(v & 0xFF), UInt8(v >> 8)] }
    mutating func u32(_ v: UInt32) { for i in 0..<4 { out.append(UInt8((v >> (8 * UInt32(i))) & 0xFF)) } }
    mutating func u64(_ v: UInt64) { for i in 0..<8 { out.append(UInt8((v >> (8 * UInt64(i))) & 0xFF)) } }
    mutating func f64(_ v: Double) { u64(v.bitPattern) }
}

private struct LEReader {
    let b: [UInt8]
    var i = 0
    init(_ b: [UInt8]) { self.b = b }
    mutating func bytes(_ n: Int) throws -> [UInt8] {
        guard n >= 0, i + n <= b.count else { throw BTXFont.FormatError.truncated }
        defer { i += n }
        return Array(b[i..<(i + n)])
    }
    mutating func u16() throws -> UInt16 {
        let x = try bytes(2)
        return UInt16(x[0]) | UInt16(x[1]) << 8
    }
    mutating func u32() throws -> UInt32 {
        try bytes(4).enumerated().reduce(0) { $0 | UInt32($1.element) << (8 * UInt32($1.offset)) }
    }
    mutating func u64() throws -> UInt64 {
        try bytes(8).enumerated().reduce(0) { $0 | UInt64($1.element) << (8 * UInt64($1.offset)) }
    }
    mutating func f64() throws -> Double { Double(bitPattern: try u64()) }
}
