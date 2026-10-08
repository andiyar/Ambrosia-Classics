import XCTest
import FerazelCore
@testable import FerazelRender

/// R3 (docs/plans/2026-10-06-ferazel-phase1.md): the backdrop compositor `.DoubleBlitPPCParallaxOneLayer @ 10017924`
/// as written (rendering-omnipx-titles §1.1–§1.5, §2) behind `.WrapCopyToScreen @ 100174bc` /
/// `.DoubleBlitUniversal @ 10022e34`, and the parallax strip sprites `.MTAddPxSprite @ 1003359c` /
/// `.HandlePxSprite @ 10033378` (triggers-background-2 §4). Pixel tests run on synthetic faces and ports; the row
/// state machine runs on the committed level maps and factor tables. A missing data file is a FAILURE, never a skip.
final class ParallaxTests: XCTestCase {

    /// Levels 1 and 10 (maps, factor tables, header), read once. Immutable after init.
    final class Fixture: @unchecked Sendable {
        let level1: LevelFile
        let level10: LevelFile
        let headers: [Int16: LevelHeader]

        init() throws {
            let resources = try FerazelData.open(try FerazelData.dataDirectory())
            level1 = try LevelFile.load(from: resources, level: 1)
            level10 = try LevelFile.load(from: resources, level: 10)
            var headers: [Int16: LevelHeader] = [:]
            for id: Int16 in [1, 10, 30, 40, 45, 62, 67] { headers[id] = try LevelFile.load(from: resources, level: id).header }
            self.headers = headers
        }
    }

    private static let shared = Result { try Fixture() }

    private func fixture() throws -> Fixture { try Self.shared.get() }

    // MARK: synthetic inputs

    static let w = FramePorts.width, sw = ParallaxBlitter.screenWidth

    /// A 128×128 face whose byte at (row, x) is `f(row, x)`.
    private func face(_ f: (Int, Int) -> UInt8) -> [UInt8] {
        (0..<128).flatMap { row in (0..<128).map { x in f(row, x) } }
    }

    /// The level's blitter with every PxBack slot = `back`, every PxMid image slot = `image`, every mask slot = `mask`.
    private func blitter(_ level: LevelFile, back: [UInt8], image: [UInt8]? = nil, mask: [UInt8]? = nil) -> ParallaxBlitter {
        let slots: [[UInt8]?] = (0..<ParallaxBlitter.slotCount).map { slot in
            slot < ParallaxBlitter.midImageBase ? back : slot < ParallaxBlitter.midMaskBase ? (image ?? back) : (mask ?? back)
        }
        return ParallaxBlitter(level: level, faceSlots: slots)
    }

    /// A 640×416 port whose byte at (x, y) is `f(x, y)`.
    private func port(_ f: (Int, Int) -> UInt8) -> [UInt8] {
        (0..<FramePorts.height).flatMap { y in (0..<Self.w).map { x in f(x, y) } }
    }

    private func be(_ bytes: ArraySlice<UInt8>) -> UInt32 { bytes.reduce(0) { $0 << 8 | UInt32($1) } }

    /// Rows of the composited screen: [(view row, mode, cell row, table row, sub-row)] for one copy-to-screen.
    private func trace(_ b: ParallaxBlitter, h: Int, v: Int, graphicsMode: Int = 1,
                       source: [UInt8]? = nil, mask: [UInt8]? = nil, screen: inout [UInt8]) -> [[ParallaxBlitter.RowTrace]] {
        let zero = [UInt8](repeating: 0, count: FramePorts.width * FramePorts.height)
        var traces: [[ParallaxBlitter.RowTrace]]? = []
        b.copyToScreen(source: source ?? zero, mask: mask ?? zero, h: h, v: v, graphicsMode: graphicsMode,
                       backdrop: true, parallax: 2, screen: &screen, trace: &traces)
        return traces ?? []
    }

    private func blankScreen(_ fill: UInt8 = 0xee) -> [UInt8] {
        [UInt8](repeating: fill, count: ParallaxBlitter.screenWidth * ParallaxBlitter.screenHeight)
    }

    // MARK: tests

    /// §1.2 back row: byte `M == 0xFF ? I : F`; word `M == ~0 → I`, `M == 0 → F`, else `F + (M & I)` as one 32-bit
    /// add (`10018044..1001805c`, `100180e8..10018130`). Then one whole row of level 1 at (h 2, v 10): phase
    /// `(2·128 >> 8) mod 128 = 1` → 3 lead bytes, 151 words, 1 tail byte, every byte/word placed by that split.
    func testBackRowByteAndWordRules() throws {
        typealias B = ParallaxBlitter
        XCTAssertEqual(B.backByte(m: 0xff, f: 0x12, i: 0x34), 0x34)
        XCTAssertEqual(B.backByte(m: 0x00, f: 0x12, i: 0x34), 0x12)
        XCTAssertEqual(B.backByte(m: 0x0f, f: 0x12, i: 0x34), 0x12)        // only 0xFF shows the backdrop
        XCTAssertEqual(B.backWord(m: 0xffff_ffff, f: 0x1122_3344, i: 0x5566_7788), 0x5566_7788)
        XCTAssertEqual(B.backWord(m: 0, f: 0x1122_3344, i: 0x5566_7788), 0x1122_3344)
        // Mixed mask over a frame word with 0xFF bytes: the add carries across bytes (bytewise would give 0x00FF_FF01).
        XCTAssertEqual(B.backWord(m: 0x0000_ffff, f: 0x00ff_ff00, i: 0x0000_0101), 0x0100_0001)
        XCTAssertEqual(B.backWord(m: 0xff00_0000, f: 0x0000_0000, i: 0x7f12_3456), 0x7f00_0000)
        // Carry out of the top byte is dropped (32-bit add).
        XCTAssertEqual(B.backWord(m: 0x0000_00ff, f: 0xffff_ffff, i: 0x0000_0001), 0x0000_0000)

        let f = try fixture()
        let back = face { row, x in UInt8((row * 3 + x) & 0xff) }
        let b = blitter(f.level1, back: back)
        // Frame and mask chosen so that every word kind (0, ~0, mixed with carries) occurs.
        let source = port { x, y in UInt8((x * 7 + y) & 0xff) | 0x80 }
        let mask = port { x, _ in [0x00, 0x00, 0x0f, 0xff, 0x80, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00][x % 12] }
        var screen = blankScreen()
        let traces = trace(b, h: 2, v: 10, source: source, mask: mask, screen: &screen)
        XCTAssertEqual(traces.count, 1, "v' = 10 ≤ 32: one call")
        let first = try XCTUnwrap(traces.first?.first)
        XCTAssertEqual(first.y, 8)
        XCTAssertEqual(first.subRow, 2, "s = (T − 8 + v0b) mod 128, v0b = 10·74 >> 8 = 2")
        XCTAssertFalse(first.mid)
        // Expected row y = 8: src row 10 from h' = 2, I = face row 2 at x phase 1.
        let srcRow = 10, srcLeft = 2, phase = 1, s = 2
        func i(_ j: Int) -> UInt8 { back[s * 128 + (phase + j) % 128] }
        var expected = [UInt8](repeating: 0, count: 608)
        let lead = 3, words = 151
        for j in 0..<lead { expected[j] = B.backByte(m: mask[srcRow * Self.w + srcLeft + j], f: source[srcRow * Self.w + srcLeft + j], i: i(j)) }
        for k in 0..<words {
            let j = lead + 4 * k, o = srcRow * Self.w + srcLeft + j
            let word = B.backWord(m: be(mask[o..<o + 4]), f: be(source[o..<o + 4]),
                                  i: be(ArraySlice((0..<4).map { i(j + $0) })))
            for n in 0..<4 { expected[j + n] = UInt8(word >> (24 - 8 * UInt32(n)) & 0xff) }
        }
        let j = lead + 4 * words
        XCTAssertEqual(j, 607)
        expected[j] = B.backByte(m: mask[srcRow * Self.w + srcLeft + j], f: source[srcRow * Self.w + srcLeft + j], i: i(j))
        XCTAssertEqual(Array(screen[(8 * Self.sw + 16)..<(8 * Self.sw + 624)]), expected)
        XCTAssertEqual(screen[8 * Self.sw + 15], 0xee, "left of the view untouched")
        XCTAssertEqual(screen[8 * Self.sw + 624], 0xee, "right of the view untouched")
    }

    /// §1.2 mid row: byte `K == 0 ? I : F`; word `K == 0 → I`, `K == ~0 → F`, else `(K & F) + I` (32-bit add)
    /// (`10017fa0`, `10018198..100181e4`), I = PxMid sheet id, K = sheet id+1. Then the first mid row of level 10 at
    /// (h 1, v 1400): phase `(1·384 >> 8) mod 128 = 1`.
    func testMidRowRules() throws {
        typealias B = ParallaxBlitter
        XCTAssertEqual(B.midByte(k: 0x00, f: 0x12, i: 0x34), 0x34)
        XCTAssertEqual(B.midByte(k: 0xff, f: 0x12, i: 0x34), 0x12)
        XCTAssertEqual(B.midByte(k: 0x01, f: 0x12, i: 0x34), 0x12)
        XCTAssertEqual(B.midWord(k: 0, f: 0x1122_3344, i: 0x5566_7788), 0x5566_7788)
        XCTAssertEqual(B.midWord(k: 0xffff_ffff, f: 0x1122_3344, i: 0x5566_7788), 0x1122_3344)
        XCTAssertEqual(B.midWord(k: 0xffff_0000, f: 0x12ff_3344, i: 0x0001_0080), 0x1300_0080)   // carry
        XCTAssertEqual(B.midWord(k: 0x00ff_ff00, f: 0xffff_ffff, i: 0xff00_0001), 0xffff_ff01)

        let f = try fixture()
        let back = face { _, _ in 0x55 }
        let image = face { row, x in UInt8((row + 2 * x) & 0x7f) | 0x01 }
        let mask = face { row, x in [0x00, 0xff, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff, 0x00, 0xff, 0xff, 0x00][(row + x) % 12] }
        let b = blitter(f.level10, back: back, image: image, mask: mask)
        let source = port { x, y in UInt8((x + 5 * y) & 0xff) }
        var screen = blankScreen()
        let traces = trace(b, h: 1, v: 1400, source: source, screen: &screen)
        let rows = traces.flatMap { $0 }
        let mid = try XCTUnwrap(rows.first { $0.mid }, "level 10 at v 1400 draws a mid row")
        let s = mid.subRow, phase = 1
        let v1 = 1400 % 416, srcRow = (v1 + (mid.y - 8)) % 416, srcLeft = 1
        func i(_ j: Int) -> UInt8 { image[s * 128 + (phase + j) % 128] }
        func k(_ j: Int) -> UInt8 { mask[s * 128 + (phase + j) % 128] }
        var expected = [UInt8](repeating: 0, count: 608)
        let lead = 3, words = 151
        for j in 0..<lead { expected[j] = B.midByte(k: k(j), f: source[srcRow * Self.w + srcLeft + j], i: i(j)) }
        for n in 0..<words {
            let j = lead + 4 * n, o = srcRow * Self.w + srcLeft + j
            let word = B.midWord(k: be(ArraySlice((0..<4).map { k(j + $0) })), f: be(source[o..<o + 4]),
                                 i: be(ArraySlice((0..<4).map { i(j + $0) })))
            for m in 0..<4 { expected[j + m] = UInt8(word >> (24 - 8 * UInt32(m)) & 0xff) }
        }
        expected[607] = B.midByte(k: k(607), f: source[srcRow * Self.w + srcLeft + 607], i: i(607))
        XCTAssertEqual(Array(screen[(mid.y * Self.sw + 16)..<(mid.y * Self.sw + 624)]), expected)
        XCTAssertTrue([16, 17].contains(mid.cellRow), "drawn from a PxMid cell row (§1.5)")
    }

    /// §1.1 ring split (`1001754c`): v' = 100 → two compositor calls, view rows 0..315 (src 100..415, dst top 8)
    /// and 316..383 (src 0..67, dst top 324); each with its second horizontal piece when h' > 32.
    func testRingSplitTwoCalls() throws {
        typealias R = ParallaxBlitter.Rect
        let calls = ParallaxBlitter.calls(h: 100, v: 100, backdrop: true)
        XCTAssertEqual(calls.count, 2)
        XCTAssertEqual(calls[0].src, R(top: 100, left: 100, bottom: 416, right: 640))
        XCTAssertEqual(calls[0].src2, R(top: 100, left: 0, bottom: 416, right: 68))
        XCTAssertEqual(calls[0].dst, R(top: 8, left: 16, bottom: 324, right: 556))
        XCTAssertEqual(calls[0].dst2, R(top: 8, left: 556, bottom: 324, right: 624))
        XCTAssertEqual(calls[1].src, R(top: 0, left: 100, bottom: 68, right: 640))
        XCTAssertEqual(calls[1].dst, R(top: 324, left: 16, bottom: 392, right: 556))
        XCTAssertEqual(calls[1].dst2, R(top: 324, left: 556, bottom: 392, right: 624))
        XCTAssertTrue(calls.allSatisfy { $0.composited })
        // v' ≤ 32: one call; h' ≤ 32 takes the piecewise path (no second horizontal piece).
        XCTAssertEqual(ParallaxBlitter.calls(h: 100, v: 32, backdrop: true).count, 1)
        XCTAssertEqual(ParallaxBlitter.calls(h: 0, v: 100, backdrop: true).map(\.src2), [nil, nil])
        // Plain copy (prefs+9 ≠ 0): four CopyBits pieces, except the corner piece, which the binary sends through
        // .DoubleBlitUniversal (100178b0..100178e4).
        XCTAssertEqual(ParallaxBlitter.calls(h: 100, v: 100, backdrop: false).map(\.composited), [false, false, false, true])

        let f = try fixture()
        let b = blitter(f.level1, back: face { _, _ in 0 })
        var screen = blankScreen()
        let traces = trace(b, h: 100, v: 100, screen: &screen)
        XCTAssertEqual(traces.count, 2)
        XCTAssertEqual(traces[0].map(\.viewRow), Array(0...315))
        XCTAssertEqual(traces[1].map(\.viewRow), Array(316...383))
        XCTAssertEqual(traces[0].first?.y, 8)
        XCTAssertEqual(traces[1].first?.y, 324)
        XCTAssertEqual(traces[1].first?.tableRow, 0, "each call restarts the row state")
    }

    /// §1.3 step 6 on level 1 at (h 0, v 10): v0b = 10·74 >> 8 = 2; the per-row back factors `back[r + 2]` carry 64
    /// on view rows 274..410 (world-data §3.2 0xb26c table rows 276..412, p19), so the factor changes at 273→274 and
    /// 410→411 — the drawn call (view rows 0..383) re-decides the back row once, at 273→274, and nowhere else.
    func testLevel1FactorChangeRows() throws {
        let f = try fixture()
        let v0b = (10 * Int(f.level1.header.pxBackYFactor)) >> 8
        XCTAssertEqual(v0b, 2)
        let xb = (0..<480).map { f.level1.backFactors[$0 + v0b] }
        XCTAssertEqual((0..<479).filter { xb[$0] != xb[$0 + 1] }.map { $0 + 1 }, [274, 411])
        XCTAssertEqual(Set(xb[274...410]), [64])
        let b = blitter(f.level1, back: face { _, _ in 0 })
        var screen = blankScreen()
        let rows = trace(b, h: 0, v: 10, screen: &screen).flatMap { $0 }
        XCTAssertEqual(rows.map(\.viewRow), Array(0...383))
        XCTAssertEqual(rows.filter(\.redecided).map(\.viewRow), [274])
        XCTAssertFalse(rows.contains { $0.mid }, "level 1: PxMid disabled (0x3268 = 0)")
        // After the re-decision the sub-row is recomputed as (T − 8 + v0b + n) & 0x7f with n = 274.
        XCTAssertEqual(rows[274].subRow, (0 + 2 + 274) & 0x7f)
        XCTAssertEqual(rows[274].cellRow, rows[274].tableRow + rows[0].cellRow, "back refill y = qb + t")
    }

    /// §1.5 table (MED simulation): level 10 shows its PxMid band for V in 1392..1536 and draws, as written, PxMid
    /// cell rows 16 and 17 (geometric 17, 18); V 1391 draws none.
    func testMidBandLevel10() throws {
        let f = try fixture()
        let b = blitter(f.level10, back: face { _, _ in 0 })
        var drawn = Set<Int>()
        for v in 1392...1536 {
            var screen = blankScreen()
            let rows = trace(b, h: 0, v: v, screen: &screen).flatMap { $0 }.filter(\.mid)
            XCTAssertFalse(rows.isEmpty, "v \(v) shows the band")
            drawn.formUnion(rows.map(\.cellRow))
        }
        XCTAssertEqual(drawn, [16, 17])
        var screen = blankScreen()
        XCTAssertFalse(trace(b, h: 0, v: 1391, screen: &screen).flatMap { $0 }.contains { $0.mid })
    }

    /// §1.1 graphics gate (`10022fc0..1002307c`): prefs+2 = 1 every row; 2 → each row written twice (step 2);
    /// 3 → every other row (step 2), the top made even first (`10017a60..10017a78`) — so a call whose top is odd
    /// draws its first source row one screen row lower.
    func testGraphicsModeRowSteps() throws {
        let f = try fixture()
        let b = blitter(f.level1, back: face { _, _ in 0 })
        let source = port { _, y in UInt8(y & 0xff) }
        let mask = port { _, _ in 0 }                                   // F everywhere
        func run(_ mode: Int, v: Int) -> [UInt8] {
            var screen = blankScreen()
            b.copyToScreen(source: source, mask: mask, h: 0, v: v, graphicsMode: mode, backdrop: true, parallax: 2,
                           screen: &screen)
            return screen
        }
        func row(_ s: [UInt8], _ y: Int) -> Set<UInt8> { Set(s[(y * Self.sw + 16)..<(y * Self.sw + 624)]) }

        let m1 = run(1, v: 10)
        for y in 8..<392 { XCTAssertEqual(row(m1, y), [UInt8((10 + y - 8) & 0xff)], "mode 1 row \(y)") }
        let m2 = run(2, v: 10)
        for y in stride(from: 8, to: 392, by: 2) {
            XCTAssertEqual(row(m2, y), [UInt8((10 + y - 8) & 0xff)], "mode 2 row \(y)")
            XCTAssertEqual(row(m2, y + 1), [UInt8((10 + y - 8) & 0xff)], "mode 2 row \(y + 1) doubles \(y)")
        }
        let m3 = run(3, v: 10)
        for y in stride(from: 8, to: 392, by: 2) {
            XCTAssertEqual(row(m3, y), [UInt8((10 + y - 8) & 0xff)], "mode 3 row \(y)")
            XCTAssertEqual(row(m3, y + 1), [0xee], "mode 3 row \(y + 1) skipped")
        }
        // Graphics outside 1..3: DoubleBlitUniversal draws nothing.
        XCTAssertEqual(Set(run(4, v: 10)), [0xee])
        // v 101: second call top 8 + 416 − 101 = 323 (odd) → 324, showing source row 0 there (geometric: row 1).
        let odd = run(3, v: 101)
        XCTAssertEqual(row(odd, 323), [0xee])
        XCTAssertEqual(row(odd, 324), [0])
        XCTAssertEqual(row(odd, 322), [UInt8((101 + 314) & 0xff)])
    }

    /// triggers-background-2 §4: N = ⌊((fx·W·32) >> 8) / 768⌋ + 1 (p02 header + formula: 8 L10, 11 L30, 11 L40, 2 L45,
    /// 8 L62, 1 L67; none on L1). The binary's loop (`1003373c cmpw; 10033740 ble`) runs k = 0..min(N, 31 − count)
    /// with the count growing each pass, so it creates **N + 1** copies (at most 16), x0 = 768·k, layer −500,
    /// mode 0x80000, y0 = 0x271a, fx = 0x2718, fy = 0xb26c.
    func testStripSpriteCopies() throws {
        let f = try fixture()
        XCTAssertNil(PxSprites(header: try XCTUnwrap(f.headers[1])))
        let expected: [(Int16, Int16, Int, Int, Int)] = [   // level, pict, N, y0, fy
            (10, 265, 8, 222, 56), (30, 275, 11, 227, 136), (40, 315, 11, 48, 22), (45, 315, 2, 48, 10),
            (62, 345, 8, 116, 43), (67, 385, 1, 16, 256),
        ]
        for (level, pict, n, y0, fy) in expected {
            let strip = try XCTUnwrap(PxSprites(header: try XCTUnwrap(f.headers[level])), "L\(level)")
            XCTAssertEqual(strip.pict, pict, "L\(level)")
            XCTAssertEqual(strip.n, n, "L\(level) N")
            XCTAssertEqual(strip.sprites.count, n + 1, "L\(level) copies k = 0...N")
            XCTAssertEqual(strip.sprites.map(\.x0), (0...n).map { 0x300 * $0 }, "L\(level)")
            XCTAssertTrue(strip.sprites.allSatisfy { $0.y0 == y0 && $0.fx == 128 && $0.fy == fy }, "L\(level)")
        }
        XCTAssertEqual(PxSprites.layer, -500)
        XCTAssertEqual(PxSprites.drawMode, 0x80000)
        // .HandlePxSprite: x = x0 − (h·fx >> 8) + h, y = y0 − (v·fy >> 8) + v + 232.
        let copy = try XCTUnwrap(PxSprites(header: try XCTUnwrap(f.headers[10]))?.sprites[2])
        let p = copy.position(h: 1000, v: 1400)
        XCTAssertEqual(p.x, 0x600 - ((1000 * 128) >> 8) + 1000)
        XCTAssertEqual(p.y, 222 - ((1400 * 56) >> 8) + 1400 + 232)
    }
}
