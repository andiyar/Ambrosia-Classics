import XCTest
import FerazelCore
@testable import FerazelRender

/// TB (loop run 21): sprite draw mode 0xb — `.BlitEncFaceTransClip @ 10027d04` and `.BlitEncFaceTransFlipClip @
/// 100287cc` (draw-effects §2.7, lighting-tables §6.1; main dump l. 23226–23456, 23737–23960), on a synthetic face
/// over the committed level 1's tables. A missing data file is a FAILURE, never a skip.
final class TranslucencyTests: XCTestCase {

    private static let shared = Result { try TileGridTests.Fixture() }
    private func fixture() throws -> TileGridTests.Fixture { try Self.shared.get() }

    /// An 8×6 face: pixel (r, c) = 0x20 + 8r + c, except (0, 0), (2, 3), (5, 7) transparent (0).
    private static let w = 8, h = 6
    private static func pixel(_ r: Int, _ c: Int) -> UInt8 {
        [(0, 0), (2, 3), (5, 7)].contains { $0 == (r, c) } ? 0 : UInt8(0x20 + 8 * r + c)
    }
    private static let ref = FaceRef(pict: 9001, index: 0, set: .encoded)
    /// A 40×40 face opaque only in rows 20..29, columns 20..29 (bounds away from every edge strip).
    private static let inner = FaceRef(pict: 9002, index: 0, set: .encoded)
    private static let open = SpriteClip(left: 0, right: 32000, bottom: 32000, top: 0)

    private func blitter(_ f: TileGridTests.Fixture) throws -> SpriteBlitter {
        func sheet(_ pict: Int16, _ w: Int, _ h: Int, _ px: [UInt8]) throws -> FaceSheet {
            let face = try FaceEncoder.encode(pixels: px, width: w, height: h,
                                              rect: EncodedFace.Rect(top: 0, left: 0, bottom: Int16(h), right: Int16(w)),
                                              sourceId: pict)
            let a = try FaceSheet.Arguments(pict: pict, count: 1, cellWidth: w, cellHeight: h, columns: 1)
            return FaceSheet(arguments: a, faces: [face], shortCells: [:], clutId: 202)
        }
        let px = (0..<Self.h).flatMap { r in (0..<Self.w).map { c in Self.pixel(r, c) } }
        let inner = (0..<40).flatMap { r in (0..<40).map { c in (20..<30).contains(r) && (20..<30).contains(c) ? UInt8(9) : 0 } }
        let faces = SpriteBlitter.Faces(sheets: [9001: try sheet(9001, Self.w, Self.h, px),
                                                 9002: try sheet(9002, 40, 40, inner)])
        return SpriteBlitter(level: f.level, tables: f.tables, faces: faces, effects: 3)
    }

    /// Every PxBack slot the same 128×128 face, byte (row, x) = `pattern(row, x)`.
    private static func pattern(_ row: Int, _ x: Int) -> UInt8 { UInt8((row * 7 + x * 3 + 1) & 0xff) }
    private func parallax(_ f: TileGridTests.Fixture) throws -> ParallaxBlitter {
        let face = (0..<128).flatMap { r in (0..<128).map { x in Self.pattern(r, x) } }
        return try ParallaxBlitter(level: f.level, faceSlots: [[UInt8]?](repeating: face, count: ParallaxBlitter.slotCount))
    }

    /// `.CalcPxRowContents @ 10027aac` (header 0x2722 = 0 branch) for world (x, y) at scroll (h, v), y being the
    /// blitter's row counter (sprite y + face row + 1): row = y − v + (v·yb >> 8) − 1, col = x − h + (h·xb[row] >> 8).
    private func px(_ f: TileGridTests.Fixture, x: Int, y: Int, h: Int, v: Int) -> UInt8 {
        let row = y - v + ((v * Int(f.level.header.pxBackYFactor)) >> 8) - 1
        let col = x - h + ((h * Int(f.level.backFactors[row])) >> 8)
        return Self.pattern(row & 0x7f, col & 0x7f)
    }

    private func at(_ port: [UInt8], _ x: Int, _ y: Int) -> UInt8 { port[FramePorts.ringOffset(x: x, y: y)] }

    /// Arg → table (`10027d28..10027dfc`): 0 avg `015c`, 1 ¾ sprite `0158`, 2 ¼ sprite `0154`, 3 `0150`, 4 glow `014c`,
    /// 5 additive `0160`; ≥ 0x80 grey-pull `0144 + (arg − 0x80)·0x1000` with the sprite pixel first through `0148`.
    /// Over a mask byte ≠ 0xff the background is the screen pixel: out = T[s·0x100 + d].
    func testTableByArgOverTheScreenPixel() throws {
        let f = try fixture()
        let b = try blitter(f)
        let d: UInt8 = 0x37, m: UInt8 = 0x11
        func draw(_ word: UInt32) throws -> FramePorts {
            var ports = FramePorts(fill: d)
            for k in ports.mask.indices { ports.mask[k] = m }
            try b.wrapDrawSprites([SpriteDraw(face: Self.ref, x: 100, y: 50, mode: word, clip: Self.open)], h: 0, v: 0,
                                  ports: &ports)
            return ports
        }
        // `_DAT_100a0148` (`100211a8..10021248`): 255 bytes, clamp(lum/3072 − 2, 0, 15) of the working CLUT (202),
        // pinned by hand from clut 202's entries: 0 (FFFF FFFF FFFF) → 15, 0x20 (7F7F 4040 FFFF) → 38207/3072 − 2 = 10,
        // 0x37 (4040 7F7F BFBF) → 8, 0x40 (4040 0000 FFFF) → 6, 0x80 (4E3B 7F52 79DD) → 7, 0xd7 (2121 ×3) → 0,
        // 0xf0 (0000 9494 0808) → 2, 0xfe (black) → 0; the whole table sums to 1,178.
        XCTAssertEqual(f.tables.brightness.count, 255)
        for (i, level) in [(0, 15), (1, 15), (0x20, 10), (0x37, 8), (0x40, 6), (0x80, 7), (0xa0, 0), (0xd7, 0),
                           (0xf0, 2), (0xfe, 0)] {
            XCTAssertEqual(Int(f.tables.brightness[i]), level, "0148[\(i)]")
        }
        XCTAssertEqual(f.tables.brightness.reduce(0) { $0 + Int($1) }, 1178)
        let cases: [(UInt32, [UInt8], (UInt8) -> Int)] = [
            (0, f.tables.pair(.average), { Int($0) }), (1, f.tables.pair(.threeQuarterSprite), { Int($0) }),
            (2, f.tables.pair(.quarterSprite), { Int($0) }), (3, f.tables.pair(.spriteGreyAverage), { Int($0) }),
            (4, f.tables.pair(.glow), { Int($0) }), (5, f.tables.pair(.additive), { Int($0) }),
            (0x8a, f.tables.greyPull, { 0xa0 + Int(f.tables.brightness[Int($0)]) }),   // row byte a·16 + level
        ]
        for (arg, table, row) in cases {
            let ports = try draw(0xb0000 + arg)
            for r in 0..<Self.h {
                for c in 0..<Self.w {
                    let s = Self.pixel(r, c)
                    let want = s == 0 ? d : table[row(s) * 0x100 + Int(d)]
                    XCTAssertEqual(at(ports.frame, 100 + c, 50 + r), want, "arg \(arg) frame (\(r), \(c))")
                    XCTAssertEqual(at(ports.mask, 100 + c, 50 + r), s == 0 ? m : 0, "arg \(arg) mask (\(r), \(c))")
                }
            }
        }
        // The three shipped fade args differ (a = 1 the most opaque, a = 2 the most transparent of the three).
        let s = Int(Self.pixel(1, 1))
        XCTAssertNotEqual(f.tables.pair(.threeQuarterSprite)[s * 0x100 + Int(d)], f.tables.pair(.quarterSprite)[s * 0x100 + Int(d)])
        // Refused by name: an arg whose grey-pull read leaves the 64 KB table (6 → base (6 − 0x80)·0x1000 < 0;
        // 0x90 → base 0x10000; `+0x89` L = −1 → 0xbff02), and 0xb under scale (the Scale switch has no 0xb arm, §2.9).
        for word: UInt32 in [0xb0006, 0xb0090, 0xbff02] {
            XCTAssertThrowsError(try draw(word)) { XCTAssertEqual($0 as? SpriteBlitter.Refusal, .mode(word)) }
        }
        var ports = FramePorts(fill: d)
        XCTAssertThrowsError(try b.wrapDrawSprites([SpriteDraw(face: Self.ref, x: 100, y: 50, mode: 0xb0000,
                                                               clip: Self.open, scale: 0x80)], h: 0, v: 0, ports: &ports)) {
            XCTAssertEqual($0 as? SpriteBlitter.Refusal, .mode(0xb0000))
        }
    }

    /// Where the mask byte is 0xff the background operand is the parallax row (`.CalcPxRowContents`, row counter =
    /// sprite y + face row + 1, column = the pixel's world x), not the frame pixel; the mask pass then writes 0 under
    /// the silhouette. With no parallax the read is refused by name.
    func testParallaxBackgroundUnderAnEmptyMask() throws {
        let f = try fixture()
        var b = try blitter(f)
        let d: UInt8 = 0x37, m: UInt8 = 0x11
        let avg = f.tables.pair(.average)
        for (h, v) in [(0, 0), (40, 20)] {
            let x0 = h + 100, y0 = v + 50
            var ports = FramePorts(fill: d)
            for y in (y0 - 2)..<(y0 + Self.h + 2) {
                for x in (x0 - 2)..<(x0 + Self.w + 2) { ports.mask[FramePorts.ringOffset(x: x, y: y)] = x < x0 + 4 ? 0xff : m }
            }
            var refused = ports
            XCTAssertThrowsError(try b.wrapDrawSprites([SpriteDraw(face: Self.ref, x: x0, y: y0, mode: 0xb0000,
                                                                   clip: Self.open)], h: h, v: v, ports: &refused)) {
                XCTAssertEqual($0 as? SpriteBlitter.Refusal, .translucency(x: x0 + 1, y: y0 + 1))
            }
            b.parallax = try parallax(f)
            try b.wrapDrawSprites([SpriteDraw(face: Self.ref, x: x0, y: y0, mode: 0xb0000, clip: Self.open)], h: h, v: v,
                                  ports: &ports)
            b.parallax = nil
            for y in (y0 - 2)..<(y0 + Self.h + 2) {
                for x in (x0 - 2)..<(x0 + Self.w + 2) {
                    let r = y - y0, c = x - x0
                    let s = (0..<Self.h).contains(r) && (0..<Self.w).contains(c) ? Self.pixel(r, c) : 0
                    let empty = x < x0 + 4
                    let bg = empty ? px(f, x: x, y: y0 + r + 1, h: h, v: v) : d
                    XCTAssertEqual(at(ports.frame, x, y), s == 0 ? d : avg[Int(s) * 0x100 + Int(bg)], "(\(h), \(v)) frame (\(x), \(y))")
                    XCTAssertEqual(at(ports.mask, x, y), s != 0 ? 0 : (empty ? 0xff : m), "(\(h), \(v)) mask (\(x), \(y))")
                }
            }
        }
        // The fetch mid-run: with the empty mask only from x0 + 4 on, the first 0xff pixel is face column 4 of a run
        // that started at column 0 or 1, and the buffer is fetched at that pixel's own x (sprite x + 4), not at the
        // run's start — each pixel still reads its own column.
        let (h, v) = (40, 20), x0 = h + 100, y0 = v + 50
        var ports = FramePorts(fill: d)
        for y in y0..<(y0 + Self.h) {
            for x in x0..<(x0 + Self.w) { ports.mask[FramePorts.ringOffset(x: x, y: y)] = x >= x0 + 4 ? 0xff : m }
        }
        b.parallax = try parallax(f)
        try b.wrapDrawSprites([SpriteDraw(face: Self.ref, x: x0, y: y0, mode: 0xb0000, clip: Self.open)], h: h, v: v,
                              ports: &ports)
        for r in 0..<Self.h {
            for c in 0..<Self.w where Self.pixel(r, c) != 0 {
                let bg = c >= 4 ? px(f, x: x0 + c, y: y0 + r + 1, h: h, v: v) : d
                XCTAssertEqual(at(ports.frame, x0 + c, y0 + r), avg[Int(Self.pixel(r, c)) * 0x100 + Int(bg)],
                               "mid-run fetch (\(r), \(c))")
            }
        }
    }

    /// `.BlitEncFaceTransFlipClip`: the face mirrored in its frame (face column c at x0 + 7 − c), the blend as the
    /// unflipped one over the screen pixel; over an 0xff mask the parallax is read as written — fetched at
    /// x0 + a − k (a the run's first face column, k the pixels already drawn since the last row/skip token) for the
    /// rest of the run and walked **backwards** from index n — so pixel c of run [a, b) reads x0 + a + b − c, not its
    /// own mirrored column. Then `.WrapEraseSprites`' second rule: a last-frame mode 0xb forces the erase
    /// (`10014d08..10014d1c`) of a sprite that otherwise would not be erased.
    func testFlipVariantAndTheForcedErase() throws {
        let f = try fixture()
        var b = try blitter(f)
        let d: UInt8 = 0x37, m: UInt8 = 0x11
        let q = f.tables.pair(.quarterSprite)
        let x0 = 100, y0 = 50
        for empty in [false, true] {
            var ports = FramePorts(fill: d)
            for k in ports.mask.indices { ports.mask[k] = empty ? 0xff : m }
            b.parallax = empty ? try parallax(f) : nil
            try b.wrapDrawSprites([SpriteDraw(face: Self.ref, x: x0, y: y0, mode: 0xb0002, mirrored: true,
                                              clip: Self.open)], h: 0, v: 0, ports: &ports)
            for r in 0..<Self.h {
                // The row's copy runs [a, b) in face columns.
                var runs: [(Int, Int)] = [], start: Int?
                for c in 0...Self.w {
                    let opaque = c < Self.w && Self.pixel(r, c) != 0
                    if opaque, start == nil { start = c }
                    if !opaque, let a = start { runs.append((a, c)); start = nil }
                }
                for c in 0..<Self.w {
                    let s = Self.pixel(r, c), x = x0 + Self.w - 1 - c
                    guard s != 0, let (a, e) = runs.first(where: { $0.0 <= c && c < $0.1 }) else {
                        XCTAssertEqual(at(ports.frame, x, y0 + r), d)
                        XCTAssertEqual(at(ports.mask, x, y0 + r), empty ? 0xff : m)
                        continue
                    }
                    let bg = empty ? Self.pattern(y0 + r, (x0 + a + e - c) & 0x7f) : d
                    XCTAssertEqual(at(ports.frame, x, y0 + r), q[Int(s) * 0x100 + Int(bg)], "empty \(empty) (\(r), \(c))")
                    XCTAssertEqual(at(ports.mask, x, y0 + r), 0)
                }
            }
        }
        // (Row 0's run is [1, 8): the pixel drawn at x0 + 6, face column 1, read the parallax at x0 + 8.)

        // The fetch mid-run, flipped: the empty mask only left of x0 + 4, so face columns ≥ 4 of each run [a, b) take
        // the parallax; the first, column cf = max(a, 4), fetches at x0 + a − k with k = cf − a pixels already drawn
        // since the row/skip token, n = b − cf, and pixel c reads byte n − (c − cf): x0 + a − k + b − c.
        var mid = FramePorts(fill: d)
        for y in y0..<(y0 + Self.h) {
            for x in x0..<(x0 + Self.w) { mid.mask[FramePorts.ringOffset(x: x, y: y)] = x < x0 + 4 ? 0xff : m }
        }
        b.parallax = try parallax(f)
        try b.wrapDrawSprites([SpriteDraw(face: Self.ref, x: x0, y: y0, mode: 0xb0002, mirrored: true,
                                          clip: Self.open)], h: 0, v: 0, ports: &mid)
        var kSeen = false
        for r in 0..<Self.h {
            var runs: [(Int, Int)] = [], start: Int?
            for c in 0...Self.w {
                let opaque = c < Self.w && Self.pixel(r, c) != 0
                if opaque, start == nil { start = c }
                if !opaque, let a = start { runs.append((a, c)); start = nil }
            }
            for (a, e) in runs {
                let cf = max(a, 4), k = cf - a
                kSeen = kSeen || k > 0
                for c in a..<e {
                    let bg = c >= 4 ? Self.pattern(y0 + r, (x0 + a - k + e - c) & 0x7f) : d
                    XCTAssertEqual(at(mid.frame, x0 + Self.w - 1 - c, y0 + r), q[Int(Self.pixel(r, c)) * 0x100 + Int(bg)],
                                   "flipped mid-run fetch (\(r), \(c))")
                }
            }
        }
        XCTAssertTrue(kSeen)

        // Straddling the view's left edge (h = 0, sprite x −3, face columns 0..4 drawn at x 4..0): the flipped reads
        // run down to sprite x + 1 + … = x −2, left of the view — parallax columns −1 and −2. `.CalcPxRowContents`
        // divides by 128 truncating (`10027b30..10027b5c`, `srawi; addze`, remainder by `subfc`): cell column 0,
        // remainder −1/−2, so the copy starts at row pointer (`+0x60` table) − 1/−2 — the tail of the face's previous
        // row (rows are 128 bytes, one 128×128 GWorld per cell, `.NewBlitPort`) — and on a cell's row 0 the bytes before
        // its pixel base, modelled as 0 (`ParallaxBlitter.beforePixelBase`). y0 = 125: face row 3 reads PxBack row 128.
        for y0 in [50, 125] {
            let x0 = -3
            var edge = FramePorts(fill: d)
            for k in edge.mask.indices { edge.mask[k] = 0xff }
            try b.wrapDrawSprites([SpriteDraw(face: Self.ref, x: x0, y: y0, mode: 0xb0002, mirrored: true,
                                              clip: Self.open)], h: 0, v: 0, ports: &edge)
            var negative = 0
            for r in 0..<Self.h {
                var runs: [(Int, Int)] = [], start: Int?
                for c in 0...Self.w {
                    let opaque = c < Self.w && Self.pixel(r, c) != 0
                    if opaque, start == nil { start = c }
                    if !opaque, let a = start { runs.append((a, c)); start = nil }
                }
                for (a0, e0) in runs {
                    let a = max(a0, 0), e = min(e0, 5)
                    guard a < e else { continue }
                    for c in a..<e {
                        let col = x0 + a + e - c, row = y0 + r
                        let bg: UInt8 = col >= 0 ? Self.pattern(row & 0x7f, col)
                            : row & 0x7f == 0 ? 0 : Self.pattern((row & 0x7f) - 1, 128 + col)
                        if col < 0 { negative += 1 }
                        XCTAssertEqual(at(edge.frame, x0 + Self.w - 1 - c, row), q[Int(Self.pixel(r, c)) * 0x100 + Int(bg)],
                                       "left edge y0 \(y0) (\(r), \(c))")
                    }
                }
            }
            XCTAssertGreaterThan(negative, 0)
        }
        b.parallax = nil

        // The forced erase: the 40×40 face unchanged and away from the edge strips is not erased after a mode-0 frame,
        // and is after a mode-0xb frame (and a mode-0xb0004 one: any sub).
        for (mode, count) in [(UInt32(0), 0), (0xb0000, 1), (0xb0004, 1)] {
            var slot = SpriteSlot(type: 1, x: 100, y: 50, face: Self.inner)
            slot.mode = mode
            slot.recordDrawn()
            var ports = FramePorts(fill: d)
            XCTAssertEqual(try b.wrapEraseSprites([slot], h: 0, v: 0, ports: &ports).count, count, "last mode \(mode)")
        }
    }
}
