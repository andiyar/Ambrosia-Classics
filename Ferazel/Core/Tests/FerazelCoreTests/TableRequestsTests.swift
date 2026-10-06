import XCTest
@testable import FerazelCore

/// C4 (docs/plans/2026-10-06-ferazel-phase1.md): the requested RGB of every computed colour table, CLUT 202
/// from the committed `Resources/Ferazel` (D26). Contract: lighting-tables §3.1–§3.2, §4, §5, §6.1, §7.2–§7.3.
/// Expected cells are the bank's tables (requested colours [HIGH]), compared as high bytes like the bank prints
/// them unless a 16-bit value is given. A missing data file is a FAILURE naming the path (plan invariant 5).
final class TableRequestsTests: XCTestCase {

    private func clut202() throws -> ColorLUT {
        try ColorLUT.load(id: 202, from: FerazelData.open(try FerazelData.dataDirectory()), chain: .level)
    }

    /// The bank's printed form: each channel's high byte.
    private func hi(_ c: RGB16?) -> UInt32 {
        guard let c else { return 0xdead_beef }
        return UInt32(c.red >> 8) << 16 | UInt32(c.green >> 8) << 8 | UInt32(c.blue >> 8)
    }

    private let noRandom: (Int16) -> UInt16 = { _ in XCTFail("FastRand called outside table 0xa"); return 0 }

    /// §3.2 / §4 / §5 columns (source indices).
    private let cols = [0x00, 0x06, 0x0e, 0x1d, 0x2a, 0x31, 0x61, 0x71, 0x88, 0x9a, 0x9e]
    private let waterCols = [0x00, 0x06, 0x0e, 0x1d, 0x31, 0x61, 0x71, 0x88, 0x9a, 0x9e]
    private let selCols = [0x24, 0x3b, 0x3f, 0x40, 0x4e, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76]

    func testTintRequestsCLUT202() throws {
        let clut = try clut202()
        let rows: [Int: [UInt32]] = [
            1: [0xff0000, 0xd10000, 0xbc0000, 0xd10000, 0x7c0000, 0x510000, 0xa00000, 0x8f0000, 0xff0000, 0xc00000, 0x5a0000],
            2: [0xffff9c, 0xd1d100, 0xbcbc00, 0xd1d100, 0x7c7c00, 0x515100, 0xa0a000, 0x8f8f00, 0xffff2c, 0xc0c000, 0x5a5a00],
            3: [0x007fff, 0x0055ff, 0x004aff, 0x0055ff, 0x002aaa, 0x001554, 0x003cf2, 0x0034d0, 0x0072ff, 0x004cff, 0x001966],
            4: [0x7f7fff, 0x7f3fff, 0x5f7fff, 0x3f3fff, 0x205faa, 0x003f54, 0x674df2, 0x354ed0, 0x7f57ff, 0x4c4cff, 0x191966],
            5: [0xffffff, 0xe8e8e8, 0xd3d3d3, 0xe8e8e8, 0x939393, 0x686868, 0xb7b7b7, 0xa6a6a6, 0xffffff, 0xd8d8d8, 0x717171],
            6: [0x7f7f7f, 0x7f3f3f, 0x5f7f00, 0x3f3f7f, 0x205f00, 0x003f00, 0x674d00, 0x354e18, 0x7f577f, 0x4c4c4c, 0x191919],
            7: [0x3f3f3f, 0x3f1f1f, 0x2f3f00, 0x1f1f3f, 0x102f00, 0x001f00, 0x332600, 0x1a270c, 0x3f2b3f, 0x262626, 0x0c0c0c],
            8: [0xffffff, 0xffbfbf, 0xffff00, 0xbfbfff, 0x60ff00, 0x00bf00, 0xffe900, 0xa1ea48, 0xffffff, 0xe6e6e6, 0x4c4c4c],
            9: [0xffffff, 0xffffff, 0xffff00, 0xffffff, 0xa0ff00, 0x00ff00, 0xffff00, 0xffff78, 0xffffff, 0xffffff, 0x808080],
            0xb: [0xffffff, 0xaaaaaa, 0x959595, 0xaaaaaa, 0x555555, 0x2a2a2a, 0x797979, 0x686868, 0xe4e4e4, 0x999999, 0x333333],
            0xc: [0xffff00, 0xffaa00, 0xff9500, 0xffaa00, 0xff5500, 0xff2a00, 0xff7900, 0xff6800, 0xffe400, 0xff9900, 0xff3300],
            0xd: [0xffffff, 0xffbfbf, 0xbfff7f, 0x7fbfff, 0x40df7f, 0x00bf7f, 0xcfcd7f, 0x6bce98, 0xffd7ff, 0x99cccc, 0x339999],
            0xe: [0xbf5f00, 0x7f3f00, 0x6f3700, 0x7f3f00, 0x3f1f00, 0x1f0f00, 0x5a2d00, 0x4e2700, 0xab5500, 0x733900, 0x261300],
            0x16: [0xbfbfbf, 0xbf5f5f, 0x8fbf00, 0x5f5fbf, 0x308f00, 0x005f00, 0x9b7400, 0x507524, 0xbf82be, 0x737373, 0x262626],
        ]
        for (k, row) in rows {
            let t = TableRequests.tint(k, clut: clut, random: noRandom)
            XCTAssertEqual(t.count, 256)
            XCTAssertEqual(cols.map { hi(t[$0].request) }, row, "tint \(k)")
        }
        // The plan's named cells.
        XCTAssertEqual(hi(TableRequests.tint(1, clut: clut, random: noRandom)[0x00].request), 0xff0000)
        XCTAssertEqual(hi(TableRequests.tint(2, clut: clut, random: noRandom)[0x00].request), 0xffff9c)
        XCTAssertEqual(hi(TableRequests.tint(0xe, clut: clut, random: noRandom)[0x2a].request), 0x3f1f00)
        XCTAssertEqual(hi(TableRequests.tint(0x16, clut: clut, random: noRandom)[0x06].request), 0xbf5f5f)
        // Loops 0..0xfe leave entry 0xff on the identity fill; 0..0xff loops write it.
        for k in [1, 2, 3, 4, 5, 8, 9, 0xb, 0xc] {
            XCTAssertEqual(TableRequests.tint(k, clut: clut, random: noRandom)[0xff], .index(0xff), "tint \(k) @ff")
        }
        for k in [6, 7, 0xd, 0xe, 0x16] {
            XCTAssertNotNil(TableRequests.tint(k, clut: clut, random: noRandom)[0xff].request, "tint \(k) @ff")
        }
        // Table 0 is the identity.
        XCTAssertEqual(TableRequests.tint(0, clut: clut, random: noRandom), (0..<256).map { .index(UInt8($0)) })
        // 0x10 gold / 0x11 cyan on the selected indices; every other index is identity.
        let sel: [Int: [UInt32]] = [
            0x10: [0x6c4c00, 0xd99900, 0x483300, 0xb58000, 0x916600, 0xb07c00, 0x9e6f00, 0x8b6200, 0x785500, 0x654700, 0x533a00],
            0x11: [0x00516c, 0x00f2d9, 0x001c48, 0x00bcb5, 0x008791, 0x00b6b0, 0x009a9e, 0x007e8b, 0x006378, 0x004765, 0x002c53],
        ]
        for (k, row) in sel {
            let t = TableRequests.tint(k, clut: clut, random: noRandom)
            XCTAssertEqual(selCols.map { hi(t[$0].request) }, row, "tint \(k)")
            for i in 0..<256 where !TableRequests.selIndices.contains(i) {
                XCTAssertEqual(t[i], .index(UInt8(i)), "tint \(k) @\(i)")
            }
            XCTAssertEqual(t.compactMap(\.request).count, 14, "tint \(k) requests")
        }
        // 0xa: (FastRand(5000), lum, FastRand(5000)), B drawn first then R, entries 0..0xfe (re-randomised per level).
        var draws: [Int16] = []
        var next: UInt16 = 0
        let t10 = TableRequests.tint(0xa, clut: clut) { bound in draws.append(bound); next += 1; return next }
        XCTAssertEqual(draws.count, 2 * 255)
        XCTAssertEqual(Set(draws), [5000])
        XCTAssertEqual(t10[0x00], .request(RGB16(2, 0xffff, 1)))
        XCTAssertEqual(t10[0x01].request.map { [$0.red, $0.blue] }, [4, 3])
        XCTAssertEqual(cols.map { (t10[$0].request?.green ?? 0) >> 8 },
                       [0xff, 0xaa, 0x95, 0xaa, 0x55, 0x2a, 0x79, 0x68, 0xe4, 0x99, 0x33])
        XCTAssertEqual(t10[0xff], .index(0xff))
        // The census request count of the computed tints: 9 × 255 + 5 × 256 + 2 × 14.
        let total = TableRequests.computedTints.map { TableRequests.tint($0, clut: clut, random: noRandom).compactMap(\.request).count }
        XCTAssertEqual(total.reduce(0, +), 3_603)
    }

    func testFixedIndexTables() throws {
        let clut = try clut202()
        let all: [Int: [UInt8]] = [
            0xf: [0x8d, 0x89, 0x8a, 0x89, 0x8c, 0x8d, 0x8b, 0x8b, 0x8d, 0x8a, 0x8d],
            0x17: [0x2a, 0x71, 0x72, 0x71, 0x76, 0xff, 0x74, 0x75, 0x2a, 0x72, 0xff],
            0x18: [0x7c, 0x7c, 0x7d, 0x7c, 0x81, 0x83, 0x7e, 0x7f, 0x7c, 0x7c, 0x83],
        ]
        for (k, row) in all {
            let t = TableRequests.tint(k, clut: clut, random: noRandom)
            XCTAssertEqual(cols.map { t[$0] }, row.map { .index($0) }, "tint \(k)")
            XCTAssertTrue(t.allSatisfy { $0.request == nil }, "tint \(k) makes no request")
        }
        XCTAssertEqual(TableRequests.tint(0x17, clut: clut, random: noRandom)[0x31], .index(0xff))
        let sel: [Int: [UInt8]] = [
            0x12: [0x82, 0x7e, 0x83, 0x7f, 0x81, 0x7f, 0x80, 0x81, 0x82, 0x82, 0x83],
            0x13: [0x8d, 0x88, 0xa0, 0x8a, 0x8b, 0x8a, 0x8b, 0x8b, 0x8c, 0x8d, 0x8d],
            0x14: [0x7b, 0x67, 0x7b, 0x78, 0x79, 0x78, 0x79, 0x79, 0x7a, 0x7b, 0x7b],
            0x15: [0x9d, 0x98, 0x9f, 0x9a, 0x9b, 0x9a, 0x9b, 0x9c, 0x9d, 0x9d, 0x9e],
        ]
        for (k, row) in sel {
            let t = TableRequests.tint(k, clut: clut, random: noRandom)
            XCTAssertEqual(selCols.map { t[$0] }, row.map { .index($0) }, "tint \(k)")
            for i in 0..<256 where !TableRequests.selIndices.contains(i) {
                XCTAssertEqual(t[i], .index(UInt8(i)), "tint \(k) @\(i)")
            }
        }
    }

    func testWaterRequestsCLUT202() throws {
        let clut = try clut202()
        let rows: [Int: [UInt32]] = [
            0: [0x7f7fff, 0x7f3fff, 0x5f7fff, 0x3f3fff, 0x003f54, 0x674df2, 0x354ed0, 0x7f57ff, 0x4c4cff, 0x191966],
            // @00: Ben's ruling (2026-10-07), follow the binary — L·0x8d00 (`1002054c mullw`) overflows for
            // L ≥ 59,494, so G is no longer the clamped ff but the wrapped 62 (bank ⚑ Corrections).
            1: [0xc76271, 0x91b244, 0x7ab22b, 0x7eb258, 0x1a3a0c, 0x6b8823, 0x517825, 0xb6ef68, 0x77a643, 0x273716],
            2: [0xb33f1f, 0xb31f0f, 0xb33f00, 0xb31f1f, 0x3b1f00, 0xa92600, 0x912706, 0xb32b1f, 0xb32613, 0x470c06],
            3: [0xff3fff, 0xff1fff, 0xff3fff, 0xff1fff, 0x641f64, 0xff26ff, 0xdf27df, 0xff2bff, 0xff26ff, 0x760c76],
            5: [0xb5a068, 0xb58048, 0xa5a028, 0x958068, 0x758028, 0xa98728, 0x908734, 0xb58c68, 0x9b874f, 0x816d35],
        ]
        for (w, row) in rows {
            let t = TableRequests.water(w, clut: clut)
            XCTAssertEqual(waterCols.map { hi(t[$0].request) }, row, "water \(w)")
            XCTAssertEqual(t.compactMap(\.request).count, 256, "water \(w): entries 0..0xff (ble)")
        }
        // Water 1 @00 (white, L = 0xffff), Ben's ruling (2026-10-07): follow the binary. G: 0xffff·0x8d00 =
        // 0x8cff7300 wraps negative in `1002054c mullw`; the signed /0xffff (`10020558 mulhw 0x80008001`) gives
        // −29,441, t = −58,882 (no clamp fires); 0.15·0xffff + 0.85·t = −40,219.45 → `fctiwz` −40,219 → `sth` 0x62e5.
        XCTAssertEqual(TableRequests.water(1, clut: clut)[0x00], .request(RGB16(0xc7e6, 0x62e5, 0x7133)))
        // Table 4 is never written: zero-filled storage → index 0 everywhere.
        XCTAssertEqual(TableRequests.water(4, clut: clut), Array(repeating: .index(0), count: 256))
        // Entry 0xff (black) is written like the others.
        XCTAssertEqual(TableRequests.water(0, clut: clut)[0xff], .request(RGB16(0, 0, 0)))
    }

    func testReddenRequestsWrap() throws {
        let clut = try clut202()
        let a: [Int: [UInt32]] = [
            0: [0xffdfdf, 0xea6f6f, 0xaddf00, 0x7a6fdf, 0x0a6f00, 0xd48800, 0x78892a, 0xf898de, 0x8c8686, 0x392c2c],
            3: [0xff7f7f, 0xaa3f3f, 0x757f00, 0x6a3f7f, 0x2a3f00, 0xe14d00, 0x9d4e18, 0xe3577f, 0x664c4c, 0x4c1919],
            7: [0xff0000, 0x540000, 0x2a0000, 0x540000, 0x540000, 0xf20000, 0xd00000, 0xc80000, 0x330000, 0x660000],
        ]
        let b: [Int: [UInt32]] = [
            0: [0xfffff7, 0xfd847e, 0xc0fc06, 0x8484f6, 0x098004, 0xce9d05, 0x6f9e32, 0xfeb2f5, 0x9c9c96, 0x393934],
            6: [0xffffc7, 0xeda476, 0xc4e82c, 0xa4a4be, 0x418920, 0xc7aa29, 0x8ba642, 0xf9ccc3, 0xb0b083, 0x60603e],
            14: [0xffff87, 0xd7cf6b, 0xc9cd5e, 0xcfcf73, 0x8b9345, 0xbdba58, 0xafb257, 0xf2ed81, 0xc9c969, 0x93934b],
        ]
        for (n, row) in a {
            XCTAssertEqual(waterCols.map { hi(TableRequests.reddenA(n, clut: clut)[$0].request) }, row, "redden A\(n)")
        }
        for (n, row) in b {
            XCTAssertEqual(waterCols.map { hi(TableRequests.reddenB(n, clut: clut)[$0].request) }, row, "redden B\(n)")
        }
        // The & 0xfffe wrap: ffff7f7f7f7f has lum 0xaa54 → 0x154a8 & 0xfffe = 0x54a8 → dark red under A7 (§5's
        // 540000; its note rounds the channels to 7fff).
        XCTAssertEqual(TableRequests.reddenA(7, clut: clut)[0x06], .request(RGB16(0x54a8, 0, 0)))
        XCTAssertEqual(hi(TableRequests.reddenA(0, clut: clut)[0x00].request), 0xffdfdf)
        XCTAssertEqual(hi(TableRequests.reddenB(14, clut: clut)[0x00].request), 0xffff87)
        // Entry 0xff of every A table is forced to index 0xff after its Color2Index; B's is not.
        for n in 0..<8 {
            let t = TableRequests.reddenA(n, clut: clut)
            guard case .overridden(_, let idx) = t[0xff] else { return XCTFail("redden A\(n) @ff: \(t[0xff])") }
            XCTAssertEqual(idx, 0xff)
            XCTAssertEqual(t.compactMap(\.request).count, 256)
        }
        for n in 0..<16 {
            guard case .request = TableRequests.reddenB(n, clut: clut)[0xff] else { return XCTFail("redden B\(n) @ff") }
        }
    }

    func testAmbientDarkenFloat32() throws {
        let white = RGB16(0xffff, 0xffff, 0xffff)
        let exact: [Int: UInt16] = [0: 0xffff, 1: 0xf198, 5: 0xb7ff, 10: 0x6fff, 15: 0x27ff]
        for (d, v) in exact {
            XCTAssertEqual(TableRequests.darken(white, light: 0, darkness: d), RGB16(v, v, v), "white D \(d)")
        }
        XCTAssertEqual(hi(TableRequests.darken(white, light: 0, darkness: 1)), 0xf1f1f1)
        XCTAssertEqual(hi(TableRequests.darken(white, light: 0, darkness: 5)), 0xb7b7b7)
        XCTAssertEqual(hi(TableRequests.darken(white, light: 0, darkness: 10)), 0x6f6f6f)
        XCTAssertEqual(hi(TableRequests.darken(white, light: 0, darkness: 15)), 0x272727)
        // L = 10 gives f = −0.1: a brightening that wraps (§7.2).
        XCTAssertEqual(TableRequests.darken(white, light: 10, darkness: 15), RGB16(0x17fe, 0x17fe, 0x17fe))
        let clut = try clut202()
        let row = TableRequests.ambient(darkness: 5, clut: clut)
        XCTAssertEqual(row.count, 256)
        XCTAssertEqual(row[0x00], RGB16(0xb7ff, 0xb7ff, 0xb7ff))
        XCTAssertEqual(TableRequests.ambient(darkness: 0, clut: clut), clut.entries.map(RGB16.init))
    }

    func testPairTableRequests() throws {
        let w = RGB16(0xffff, 0xffff, 0xffff), z = RGB16(0, 0, 0), h = RGB16(0x8000, 0x8000, 0x8000)
        func grey(_ v: UInt16) -> RGB16 { RGB16(v, v, v) }
        let expect: [(TableRequests.Pair, RGB16, RGB16)] = [
            (.quarterSprite, grey(0x3fff), grey(0x8000)),        // 0154: s>>2 + d>>1 + d>>2
            (.average, grey(0x7fff), grey(0x8000)),              // 015c: (s+d)>>1
            (.threeQuarterSprite, grey(0xbffe), grey(0x8000)),   // 0158: s>>1 + s>>2 + d>>2
            (.additive, grey(0xffff), grey(0xffff)),             // 0160: min(s+d, 0xffff)
            (.spriteGreyAverage, grey(0x7fff), grey(0x8000)),    // 0150: (d + lum(s))>>1
        ]
        for (p, a, b) in expect {
            XCTAssertEqual(TableRequests.pair(p, src: w, dst: z), a, "\(p) (ffff, 0)")
            XCTAssertEqual(TableRequests.pair(p, src: h, dst: h), b, "\(p) (8000, 8000)")
        }
        // 0150 averages the screen pixel with the sprite pixel's grey, per channel.
        XCTAssertEqual(TableRequests.pair(.spriteGreyAverage, src: RGB16(0xffff, 0, 0), dst: RGB16(0, 0x8000, 0xffff)),
                       RGB16(0x2aaa, 0x6aaa, 0xaaaa))   // lum(src) = 0x5555
        // Row = sprite pixel: entry src·0x100 + dst.
        let clut = try clut202()
        let t = TableRequests.pair(.threeQuarterSprite, clut: clut)
        XCTAssertEqual(t.count, 0x10000)
        XCTAssertEqual(t[0x00 * 0x100 + 0x60], grey(0xbffe))   // white sprite over black screen
        XCTAssertEqual(t[0x60 * 0x100 + 0x00], grey(0x3fff))   // black sprite over white screen

        // Glow 014c and grey-pull 0144, Ben's ruling (2026-10-07): follow the binary, 32-bit overflow included.
        // Expected values from an independent Python transcription of 1002103c..1002119c / 10021250..100213d8:
        // every product is a 32-bit `mullw`, every /0xffff the signed `mulhw 0x80008001; add; srawi 15; +sign`.
        // Glow, src white: L = w = 0xffff, (L>>1 + 0x7d00)·w = 0xfcff·0xffff = 0xfcfe0301 (`100210e0`) wraps to
        // −50,462,975 → −770; the dst term is ·0 → each channel −770, `sth` 0xfcfe (unwrapped: 0xfcff).
        XCTAssertEqual(TableRequests.pair(.glow, src: w, dst: z), grey(0xfcfe))
        XCTAssertEqual(TableRequests.pair(.glow, src: w, dst: w), grey(0xfcfe))
        // Glow, src black: L = 0 → w = 1, 0x7d00·1/0xffff = 0; dst 0xffff·0xfffe = 0xfffd0002 (`100210ec`) wraps to
        // −196,606 → −3 → 0xfffd (unwrapped: 0xfffe).
        XCTAssertEqual(TableRequests.pair(.glow, src: z, dst: w), grey(0xfffd))
        // No overflow: (0x4000 + 0x7d00)·0x8000 → 24,192; 0x8000·0x7fff → 16,383; sum 0x9e7f.
        XCTAssertEqual(TableRequests.pair(.glow, src: h, dst: h), grey(0x9e7f))
        // Grey-pull [a·0x1000 + b·0x100 + i]: w = max(a·0x1000, 1); clamp(b·0x1000·w/0xffff + c·(0xffff−w)/0xffff).
        // a = 15, b = 15: 0xf000·0xf000 = 0xe1000000 (`100212bc`) wraps to −520,093,696 → −7,936; white's
        // 0xffff·0x0fff → 4,095; −3,841 clamps to 0 (unwrapped: 0xf0ff).
        XCTAssertEqual(TableRequests.greyPull(weight: 15, level: 15, color: w), grey(0))
        // a = 0 → w = 1: white's 0xffff·0xfffe (`100212cc`) wraps → −3 → clamped 0 (unwrapped: 0xfffe).
        XCTAssertEqual(TableRequests.greyPull(weight: 0, level: 15, color: w), grey(0))
        // a·b = 120 < 128, no overflow: 0x78000000 → 30,720 (+ white's 0xffff·0x7fff → 32,767).
        XCTAssertEqual(TableRequests.greyPull(weight: 8, level: 15, color: z), grey(0x7800))
        XCTAssertEqual(TableRequests.greyPull(weight: 8, level: 15, color: w), grey(0xf7ff))
        XCTAssertEqual(TableRequests.greyPull(weight: 8, level: 8, color: h), grey(0x7fff))
        // Table layout: glow is row = sprite pixel like the others; grey-pull's row byte is a·16 + b.
        let glow = TableRequests.pair(.glow, clut: clut)
        XCTAssertEqual(glow.count, 0x10000)
        XCTAssertEqual(glow[0x00 * 0x100 + 0x60], grey(0xfcfe))
        XCTAssertEqual(glow[0x60 * 0x100 + 0x00], grey(0xfffd))
        let pull = TableRequests.pair(.greyPull, clut: clut)
        XCTAssertEqual(pull.count, 0x10000)
        XCTAssertEqual(pull[0xff * 0x100 + 0x00], grey(0))
        XCTAssertEqual(pull[0x8f * 0x100 + 0x60], grey(0x7800))
        XCTAssertEqual(pull[0x8f * 0x100 + 0x00], grey(0xf7ff))
    }

    func testLightGroupRequests() throws {
        let white = RGB16(0xffff, 0xffff, 0xffff)
        func row(_ d: Int, _ g: Int) -> [UInt32] {
            [0, 5, 10].map { hi(TableRequests.light(group: g, intensity: $0, darkness: d, color: white)) }
        }
        let d0: [[UInt32]] = [
            [0xffffff, 0xffffff, 0xffffff], [0xffffff, 0x8c8c8c, 0x191919], [0xffffff, 0xffffff, 0xffffff],
            [0xffffff, 0xffffff, 0xffffff], [0xffffff, 0xfffafa, 0xfff4f4], [0xffffff, 0xffffff, 0xffffff],
            [0xffffff, 0xff1dfa, 0xff3af4], [0xffffff, 0xffffff, 0xffffff], [0xffffff, 0xffffff, 0xffffff],
            [0xffffff, 0xffffff, 0xffffff],
        ]
        for g in 0..<10 { XCTAssertEqual(row(0, g), d0[g], "D 0 group \(g)") }
        for g in 0..<10 {
            XCTAssertEqual(hi(TableRequests.light(group: g, intensity: 0, darkness: 5, color: white)), 0xb7b7b7, "D 5 group \(g) k 0")
        }
        XCTAssertEqual(hi(TableRequests.light(group: 0, intensity: 5, darkness: 5, color: white)), 0xffffff)
        XCTAssertEqual(hi(TableRequests.light(group: 0, intensity: 10, darkness: 5, color: white)), 0x525252)
        XCTAssertEqual(hi(TableRequests.light(group: 3, intensity: 10, darkness: 5, color: white)), 0x1b2f7d)
        XCTAssertEqual(hi(TableRequests.light(group: 9, intensity: 10, darkness: 5, color: white)), 0x0f0f0f)
        let clut = try clut202()
        XCTAssertEqual(TableRequests.light(group: 8, intensity: 3, darkness: 0, clut: clut), clut.entries.map(RGB16.init))
    }
}
