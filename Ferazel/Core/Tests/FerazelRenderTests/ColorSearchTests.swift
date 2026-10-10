import XCTest
import FerazelCore
@testable import FerazelRender

/// C4 (docs/plans/2026-10-06-ferazel-phase1.md): the `Color2Index` models and the measurement of how much they
/// disagree, on the committed `Resources/Ferazel` (D26). Contract: design §6, lighting-tables §1.2, §1.4, §4.
/// Every number is a planner probe (p06 CLUTs, p09 parts A/B/C, p14 per-CLUT census; plan Research note 9).
/// A missing data file is a FAILURE naming the path, never a skip (plan invariant 5).
final class ColorSearchTests: XCTestCase {

    private static let levelCLUTs: [Int16] = [202, 210, 212, 214, 216, 218, 220, 222, 224, 228, 236, 238, 240, 242, 246, 248]

    private func resources() throws -> FerazelResources {
        try FerazelData.open(try FerazelData.dataDirectory())
    }

    private func clut(_ id: Int16, _ r: FerazelResources) throws -> ColorLUT {
        try ColorLUT.load(id: id, from: r, chain: .level)
    }

    private let noRandom: (Int16) -> UInt16 = { _ in 0 }

    /// (index, request) of the computed entries of tint table k at sprite indices 0..0x9f.
    private func spriteRequests(_ k: Int, _ c: ColorLUT) -> [(Int, RGB16)] {
        TableRequests.tint(k, clut: c, random: noRandom).enumerated().compactMap { i, e in
            i <= 0x9f ? e.request.map { (i, $0) } : nil
        }
    }

    /// The measured request groups (p14): 16 computed tints, 5 water, 24 redden, 16 ambient, pairs 0154/015c/0158.
    private func censusGroups(_ c: ColorLUT) -> [(String, [[RGB16]])] {
        [
            ("tint", TableRequests.computedTints.map { TableRequests.tint($0, clut: c, random: noRandom).compactMap(\.request) }),
            ("water", TableRequests.computedWaters.map { TableRequests.water($0, clut: c).compactMap(\.request) }),
            ("redden", (0..<8).map { TableRequests.reddenA($0, clut: c).compactMap(\.request) }
                + (0..<16).map { TableRequests.reddenB($0, clut: c).compactMap(\.request) }),
            ("ambient", (0..<16).map { TableRequests.ambient(darkness: $0, clut: c) }),
            ("pairs", [TableRequests.Pair.quarterSprite, .average, .threeQuarterSprite].map { TableRequests.pair($0, clut: c) }),
        ]
    }

    private func disagreements(_ requests: [RGB16], _ c: ColorLUT, _ a: ColorSearch, _ b: ColorSearch) -> Int {
        zip(a.indices(of: requests, in: c), b.indices(of: requests, in: c)).filter { $0 != $1 }.count
    }

    func testExactNearestTiesLowest() throws {
        let c = try clut(202, try resources())
        let black = RGB16(0, 0, 0)
        let blacks = (0..<256).filter { RGB16(c.entries[$0]) == black }
        XCTAssertEqual(blacks, [0x60, 0xa0, 0xfe, 0xff])
        XCTAssertEqual(ColorSearch(model: .exactNearest).index(of: black, in: c), 0x60)
        XCTAssertEqual(ColorSearch(model: .ruled).index(of: black, in: c), 0x60)
        // A near-black request is equidistant from all four blacks: still the lowest.
        XCTAssertEqual(ColorSearch(model: .exactNearest).index(of: RGB16(1, 0, 0), in: c), 0x60)
    }

    func testDuplicateBlackTieBreakCLUT201() throws {
        // Ben, 2026-10-07 (D26): clut 201 holds 162 pure blacks; which duplicate QuickDraw picks is LOW, so the
        // tie-break is selectable — `.lowest` (the default) and `.highest`.
        let c = try clut(201, try resources())
        let black = RGB16(0, 0, 0)
        let blacks = (0..<256).filter { RGB16(c.entries[$0]) == black }
        XCTAssertEqual(blacks, Array(1...160) + [254, 255])
        XCTAssertEqual(ColorSearch(model: .ruled).index(of: black, in: c), 1)
        XCTAssertEqual(ColorSearch(model: .ruled, tieBreak: .lowest).index(of: black, in: c), 1)
        XCTAssertEqual(ColorSearch(model: .ruled, tieBreak: .highest).index(of: black, in: c), 255)
        XCTAssertEqual(ColorSearch(model: .exactNearest, tieBreak: .lowest).index(of: black, in: c), 1)
        XCTAssertEqual(ColorSearch(model: .exactNearest, tieBreak: .highest).index(of: black, in: c), 255)
        XCTAssertEqual(ColorSearch(model: .exactNearest, tieBreak: .highest).indices(of: [black], in: c), [255])
        // A near-black request is not an exact match: `.ruled` falls to the inverse table, whose cell (0, 0, 0) ties
        // over the same 162 blacks — the tie-break governs that cell too.
        let nearBlack = RGB16(1, 0, 0)
        XCTAssertEqual(ColorSearch(model: .ruled, tieBreak: .lowest).index(of: nearBlack, in: c), 1)
        XCTAssertEqual(ColorSearch(model: .ruled, tieBreak: .highest).index(of: nearBlack, in: c), 255)
        XCTAssertEqual(ColorSearch(model: .inverseTable(bits: 4), tieBreak: .highest).index(of: nearBlack, in: c), 255)
        XCTAssertEqual(InverseTable(clut: c, bits: 5, tieBreak: .highest).index(of: nearBlack), 255)
    }

    func testInverseTableBitReplicatedCells() throws {
        XCTAssertEqual(InverseTable.cellColor(0, bits: 4), 0x0000)
        XCTAssertEqual(InverseTable.cellColor(1, bits: 4), 0x1111)
        XCTAssertEqual(InverseTable.cellColor(15, bits: 4), 0xffff)
        XCTAssertEqual(InverseTable.cellColor(1, bits: 5), 0x0842)
        XCTAssertEqual(InverseTable.cellColor(31, bits: 5), 0xffff)
        let c = try clut(202, try resources())
        let exact = ColorSearch(model: .exactNearest)
        for bits in [4, 5] {
            let t = InverseTable(clut: c, bits: bits)
            XCTAssertEqual(t.cells.count, 1 << (3 * bits))
            // Each cell holds the exact-nearest index of its bit-replicated colour; requests look up by top bits.
            for (r, g, b) in [(0, 0, 0), (1, 2, 3), (7, 0, 15), (15, 15, 15), (3, 9, 12)] {
                let cell = RGB16(InverseTable.cellColor(r, bits: bits), InverseTable.cellColor(g, bits: bits),
                                 InverseTable.cellColor(b, bits: bits))
                XCTAssertEqual(t.index(of: cell), exact.index(of: cell, in: c), "\(bits)-bit cell \(r),\(g),\(b)")
                let inside = RGB16(cell.red & ~UInt16(0xffff >> bits) | 0x0123 >> bits,
                                   cell.green & ~UInt16(0xffff >> bits), cell.blue | UInt16(0xffff >> bits))
                XCTAssertEqual(t.index(of: inside), t.index(of: cell), "\(bits)-bit cell \(r),\(g),\(b) by top bits")
            }
            XCTAssertEqual(ColorSearch(model: .inverseTable(bits: bits)).indices(of: [RGB16(0x1234, 0x5678, 0x9abc)], in: c),
                           [t.index(of: RGB16(0x1234, 0x5678, 0x9abc))])
        }
    }

    func testRuledModelExactFirst() throws {
        let c = try clut(202, try resources())
        let ruled = ColorSearch(model: .ruled), four = ColorSearch(model: .inverseTable(bits: 4))
        // Every palette colour → its lowest exact index.
        for i in 0..<256 {
            let rgb = RGB16(c.entries[i])
            let lowest = (0..<256).first { RGB16(c.entries[$0]) == rgb }!
            XCTAssertEqual(ruled.index(of: rgb, in: c), UInt8(lowest), "entry \(i)")
        }
        // Tint 6 (p09 part C: exact≠4-bit 124, exact≠ruled 123): an exact-matching request the 4-bit table
        // sends elsewhere, which the ruled model keeps exact.
        let t6 = TableRequests.tint(6, clut: c, random: noRandom).compactMap(\.request)
        let exactHits = t6.filter { rq in c.entries.contains { RGB16($0) == rq } }
        XCTAssertTrue(exactHits.contains { ruled.index(of: $0, in: c) != four.index(of: $0, in: c) })
        // Without an exact match the ruled model is the 4-bit table (water 0 @9e requests 191966).
        let rq = try XCTUnwrap(TableRequests.water(0, clut: c)[0x9e].request)
        XCTAssertNil(c.entries.first { RGB16($0) == rq })
        XCTAssertEqual(ruled.index(of: rq, in: c), four.index(of: rq, in: c))
        XCTAssertEqual(ruled.index(of: rq, in: c), 0x49)
        // The per-pixel fast path answers exactly like `index(of:in:)` for every model: every palette colour, the
        // tint 6 / water 0 requests, and a 4,096-colour lattice off the cell corners.
        var sample = c.entries.map(RGB16.init) + t6 + [rq]
        for r in stride(from: 0x0101, to: 0x10000, by: 0x1003) {
            for g in stride(from: 0x0207, to: 0x10000, by: 0x1003) {
                for b in stride(from: 0x0011, to: 0x10000, by: 0x1003) { sample.append(RGB16(UInt16(r), UInt16(g), UInt16(b))) }
            }
        }
        // Independent references: brute-force nearest (strict <), the InverseTable, lowest exact match else 4-bit.
        let entries = c.entries.map(RGB16.init)
        func brute(_ q: RGB16) -> UInt8 {
            func d(_ e: RGB16) -> Int {
                let dr = Int(e.red) - Int(q.red), dg = Int(e.green) - Int(q.green), db = Int(e.blue) - Int(q.blue)
                return dr * dr + dg * dg + db * db
            }
            var bi = 0
            for i in 1..<256 where d(entries[i]) < d(entries[bi]) { bi = i }
            return UInt8(bi)
        }
        let t4 = InverseTable(clut: c, bits: 4), t5 = InverseTable(clut: c, bits: 5)
        let reference: [ColorSearch.Model: (RGB16) -> UInt8] = [
            .exactNearest: brute, .inverseTable(bits: 4): t4.index(of:), .inverseTable(bits: 5): t5.index(of:),
            .ruled: { q in entries.firstIndex(of: q).map(UInt8.init) ?? t4.index(of: q) },
        ]
        for model in [ColorSearch.Model.exactNearest, .ruled, .inverseTable(bits: 4), .inverseTable(bits: 5)] {
            let search = ColorSearch(model: model)
            let prepared = search.prepared(for: c)
            XCTAssertEqual(prepared.model, model)
            XCTAssertEqual(sample.map { prepared.index(of: $0) }, sample.map { search.index(of: $0, in: c) }, "\(model)")
            XCTAssertEqual(sample.map { prepared.index(of: $0) }, sample.map(reference[model]!), "\(model) reference")
            let uncached = ColorSearch.Prepared(clut: c, model: model)
            XCTAssertEqual(sample.map { uncached.index(of: $0) },
                           sample.map { prepared.index(of: $0) }, "\(model) uncached")
        }
    }

    func testBankAgreementFiguresCLUT202() throws {
        let c = try clut(202, try resources())
        let exact = ColorSearch(model: .exactNearest)
        let four = ColorSearch(model: .inverseTable(bits: 4)), five = ColorSearch(model: .inverseTable(bits: 5))
        var n: [Int] = [], a4: [Int] = [], a5: [Int] = []
        for k in TableRequests.computedTints {
            let rq = spriteRequests(k, c).map(\.1)
            let e = exact.indices(of: rq, in: c)
            n.append(rq.count)
            a4.append(zip(e, four.indices(of: rq, in: c)).filter { $0 == $1 }.count)
            a5.append(zip(e, five.indices(of: rq, in: c)).filter { $0 == $1 }.count)
        }
        // k: 1 2 3 4 5 6 7 8 9 0xb 0xc 0xd 0xe 0x10 0x11 0x16
        XCTAssertEqual(n, [160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 160, 14, 14, 160])
        XCTAssertEqual(a4, [143, 116, 107, 134, 130, 107, 65, 143, 151, 103, 153, 138, 39, 10, 10, 118])
        XCTAssertEqual(a5, [145, 149, 147, 145, 150, 124, 104, 152, 156, 127, 157, 147, 66, 12, 12, 138])
        // lighting-tables §1.2: 39..153 at 4 bits, 66..157 at 5 bits (of the 160-entry tables).
        let full4 = zip(n, a4).filter { $0.0 == 160 }.map(\.1), full5 = zip(n, a5).filter { $0.0 == 160 }.map(\.1)
        XCTAssertEqual([full4.min(), full4.max()], [39, 153])
        XCTAssertEqual([full5.min(), full5.max()], [66, 157])
    }

    func testBankLevelSpreadFigures() throws {
        let r = try resources()
        let luts = try Self.levelCLUTs.map { try clut($0, r) }
        let four = ColorSearch(model: .inverseTable(bits: 4))
        var spread: [Int] = []
        for k in TableRequests.computedTints {
            var seen: [Int: Set<RGB16>] = [:]
            for c in luts {
                let rq = spriteRequests(k, c)
                for ((i, _), idx) in zip(rq, four.indices(of: rq.map(\.1), in: c)) {
                    seen[i, default: []].insert(RGB16(c.entries[Int(idx)]))
                }
            }
            spread.append(seen.values.filter { $0.count > 1 }.count)
        }
        // k: 1 2 3 4 5 6 7 8 9 0xb 0xc 0xd 0xe 0x10 0x11 0x16 — lighting-tables §1.4
        XCTAssertEqual(spread, [138, 32, 76, 77, 87, 97, 111, 62, 55, 106, 157, 66, 76, 3, 12, 71])
    }

    func testWaterTable0Index9E() throws {
        let c = try clut(202, try resources())
        let rq = try XCTUnwrap(TableRequests.water(0, clut: c)[0x9e].request)
        XCTAssertEqual(rq.red >> 8, 0x19)
        XCTAssertEqual(rq.green >> 8, 0x19)
        XCTAssertEqual(rq.blue >> 8, 0x66)
        XCTAssertEqual(ColorSearch(model: .exactNearest).index(of: rq, in: c), 0x84)
        XCTAssertEqual(ColorSearch(model: .inverseTable(bits: 4)).index(of: rq, in: c), 0x49)
    }

    func testDisagreementCensusCLUT202() throws {
        let c = try clut(202, try resources())
        let exact = ColorSearch(model: .exactNearest), ruled = ColorSearch(model: .ruled)
        var groups: [String: (Int, Int)] = [:]
        var perTable: [String: [Int]] = [:]
        for (name, tables) in censusGroups(c) {
            let d = tables.map { disagreements($0, c, exact, ruled) }
            perTable[name] = d
            groups[name] = (d.reduce(0, +), tables.map(\.count).reduce(0, +))
        }
        XCTAssertEqual(perTable["tint"], [36, 69, 82, 56, 67, 123, 160, 59, 32, 114, 22, 43, 186, 4, 4, 111])
        XCTAssertEqual(perTable["water"], [56, 96, 130, 48, 67])
        XCTAssertEqual(perTable["redden"].map { [$0[..<8].reduce(0, +), $0[8...].reduce(0, +)] }, [843, 1_042])
        XCTAssertEqual(perTable["pairs"], [23_561, 23_002, 23_561])
        XCTAssertEqual(groups["tint"].map { [$0.0, $0.1] }, [1_168, 3_603])
        // Measured unchanged under Ben's ruling (2026-10-07; water 1 overflow `1002054c`): 397 of 1,280.
        XCTAssertEqual(groups["water"].map { [$0.0, $0.1] }, [397, 1_280])
        XCTAssertEqual(groups["redden"].map { [$0.0, $0.1] }, [1_885, 6_144])
        XCTAssertEqual(groups["ambient"].map { [$0.0, $0.1] }, [1_887, 4_096])
        XCTAssertEqual(groups["pairs"].map { [$0.0, $0.1] }, [70_124, 196_608])
        XCTAssertEqual(groups.values.map(\.0).reduce(0, +), 75_461)
        XCTAssertEqual(groups.values.map(\.1).reduce(0, +), 211_731)
    }

    func testDisagreementCensusAllSixteen() throws {
        let r = try resources()
        let exact = ColorSearch(model: .exactNearest), ruled = ColorSearch(model: .ruled)
        var totals: [Int16: Int] = [:]
        var requests = 0
        for id in Self.levelCLUTs {
            let c = try clut(id, r)
            let all = censusGroups(c).flatMap(\.1).flatMap { $0 }
            requests += all.count
            totals[id] = disagreements(all, c, exact, ruled)
        }
        // Ben's ruling (2026-10-07), follow the binary: water 1's L·0x8d00 overflow (`1002054c mullw`) moves
        // 218 +3, 222 −3, 224 +1, 228 +1, 242 +1 (CLUT 202 unchanged) — grand total 1,178,143 → 1,178,146.
        XCTAssertEqual(totals, [202: 75_461, 210: 77_037, 212: 73_640, 214: 72_846, 216: 78_302, 218: 74_684,
                                220: 71_105, 222: 63_104, 224: 68_552, 228: 67_849, 236: 79_478, 238: 73_737,
                                240: 78_219, 242: 73_026, 246: 77_463, 248: 73_643])
        XCTAssertEqual(totals.values.reduce(0, +), 1_178_146)
        XCTAssertEqual(requests, 3_387_696)
    }
}
