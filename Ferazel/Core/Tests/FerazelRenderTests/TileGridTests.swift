import XCTest
import FerazelCore
@testable import FerazelRender

/// R1 (docs/plans/2026-10-06-ferazel-phase1.md): the level's resolved tables, the frame/mask/tile ports and
/// `.RedrawScrollGrid` on the committed level 1 (D26). Contract: plan R1 + "Bank corrections" 9 (the dump reading:
/// strip-incremental grid drawn into the third port `0004`, mask cells erased to 0xFF, boolean stamps write 0x00);
/// sprites-backgrounds §3.1–§3.3, lighting-tables §8. Planner numbers: p17 (start view), p18 (water extent), p02
/// (overlay cells), C4's CLUT-202 census (p09/p14). A missing data file is a FAILURE, never a skip.
final class TileGridTests: XCTestCase {

    /// Level 1 under the ruled model, built once for the class.
    /// Immutable after init (`FerazelResources` is not `Sendable`).
    final class Fixture: @unchecked Sendable {
        let resources: FerazelResources
        let level: LevelFile
        let sets: TileSets
        let fixed: TileSets.Fixed
        let tables: LevelTables
        let clearFace: EncodedFace

        init() throws {
            resources = try FerazelData.open(try FerazelData.dataDirectory())
            level = try LevelFile.load(from: resources, level: 1)
            let search = ColorSearch(model: .ruled)
            fixed = try TileSets.Fixed(resources: resources, search: search)
            sets = try TileSets(level: level, fixed: fixed, resources: resources, search: search)
            tables = try LevelTables.forLevel(level.header, resources: resources, search: search, random: { _ in 0 })
            clearFace = try TileGridRenderer.loadClearFace(resources: resources, search: search)
        }

        func renderer(drawnH: Int, drawnV: Int) -> TileGridRenderer {
            TileGridRenderer(level: level, sets: sets, fixed: fixed, tables: tables, clearFace: clearFace,
                             drawnH: drawnH, drawnV: drawnV)
        }
    }

    private static let shared = Result { try Fixture() }

    private func fixture() throws -> Fixture { try Self.shared.get() }

    // MARK: helpers

    /// The copy-run (opaque) pixels of a face, row-major `width × height` (blend faces copy weight 0 too).
    private func copied(_ face: EncodedFace) throws -> [Bool] {
        var out = [Bool](repeating: false, count: face.width * face.height)
        var row = -1, col = 0
        try face.walk { token in
            switch token {
            case .row: row += 1; col = 0
            case .skip(let n): col += n
            case .copy(let bytes):
                for k in 0..<bytes.count { out[row * face.width + col + k] = true }
                col += bytes.count
            case .end: break
            }
        }
        return out
    }

    /// The 32×32 pixels of world cell (col, row) in a port.
    private func cell(_ port: [UInt8], col: Int, row: Int) -> [UInt8] {
        (0..<32).flatMap { j in (0..<32).map { i in port[FramePorts.ringOffset(x: col * 32 + i, y: row * 32 + j)] } }
    }

    /// A scroll that shows cell (col, row), clamped to the level-1 map (200×50).
    private func scroll(showing col: Int, _ row: Int) -> (h: Int, v: Int) {
        (min(max(col * 32 - 288, 0), 32 * 200 - 640), min(max(row * 32 - 176, 0), 32 * 50 - 384))
    }

    /// Render one cell alone into fresh ports.
    private func renderCell(_ f: Fixture, col: Int, row: Int, fill: UInt8 = 0) -> FramePorts {
        let s = scroll(showing: col, row)
        var ports = FramePorts(fill: fill)
        f.renderer(drawnH: s.h, drawnV: s.v)
            .redrawScrollGrid(top: row, left: col, right: col, bottom: row, h: s.h, v: s.v, ports: &ports)
        return ports
    }

    /// The tiles-port cell before the blend step (cleared, BG when the FG face is transparent, FG): the `d` the
    /// blend reads — for a dry cell, or a water cell with header 0x26c6 = 0.
    private func preBlend(_ f: Fixture, t: Int, b: Int) throws -> [UInt8] {
        var out = [UInt8](repeating: 0, count: 32 * 32)
        let fg = f.sets.fg.faces[t]
        if fg.hasTransparentPixel, b >= 0 {
            let bg = f.sets.bg.faces[b]
            for (i, (c, v)) in zip(try copied(bg), try bg.decode()).enumerated() where c { out[i] = v }
        }
        for (i, (c, v)) in zip(try copied(fg), try fg.decode()).enumerated() where c { out[i] = v }
        return out
    }

    private func fnv1a(_ bytes: [UInt8]) -> UInt64 {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for b in bytes { h = (h ^ UInt64(b)) &* 0x0000_0100_0000_01b3 }
        return h
    }

    // MARK: tests

    func testLevelTablesLevel1() throws {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let header = try LevelFile.load(from: r, level: 1).header
        let ruled = try LevelTables.forLevel(header, resources: r, search: ColorSearch(model: .ruled), random: { _ in 0 })
        let exact = try LevelTables.forLevel(header, resources: r, search: ColorSearch(model: .exactNearest),
                                             random: { _ in 0 })
        XCTAssertEqual(ruled.screenClutId, 202)
        XCTAssertEqual(ruled.model, .ruled)
        let c202 = try ColorLUT.load(id: 202, from: r, chain: .level)

        func differ(_ a: [UInt8], _ b: [UInt8]) -> Int { zip(a, b).filter { $0 != $1 }.count }
        // C4's groups (ColorSearchTests.censusGroups): the computed tints, the written waters, redden A + B, ambient,
        // pairs 0154 + 015c + 0158; denominators = the requests the builders hand Color2Index.
        let tint = (TableRequests.computedTints.map { differ(ruled.tint[$0], exact.tint[$0]) }.reduce(0, +),
                    TableRequests.computedTints.map { TableRequests.tint($0, clut: c202, random: { _ in 0 })
                        .compactMap(\.request).count }.reduce(0, +))
        let water = (TableRequests.computedWaters.map { differ(ruled.water[$0], exact.water[$0]) }.reduce(0, +),
                     TableRequests.computedWaters.map { TableRequests.water($0, clut: c202).compactMap(\.request).count }
                        .reduce(0, +))
        let redden = ((0..<8).map { differ(ruled.reddenA[$0], exact.reddenA[$0]) }.reduce(0, +)
                        + (0..<16).map { differ(ruled.reddenB[$0], exact.reddenB[$0]) }.reduce(0, +),
                      (0..<8).map { TableRequests.reddenA($0, clut: c202).compactMap(\.request).count }.reduce(0, +)
                        + (0..<16).map { TableRequests.reddenB($0, clut: c202).compactMap(\.request).count }.reduce(0, +))
        let ambient = ((0..<16).map { differ(ruled.ambient[$0], exact.ambient[$0]) }.reduce(0, +),
                       ruled.ambient.map(\.count).reduce(0, +))
        let pairKinds: [TableRequests.Pair] = [.quarterSprite, .average, .threeQuarterSprite]
        let pairs = (pairKinds.map { differ(ruled.pair($0), exact.pair($0)) }.reduce(0, +),
                     pairKinds.map { ruled.pair($0).count }.reduce(0, +))
        XCTAssertEqual([tint.0, tint.1], [1_168, 3_603])
        XCTAssertEqual([water.0, water.1], [397, 1_280])
        XCTAssertEqual([redden.0, redden.1], [1_885, 6_144])
        XCTAssertEqual([ambient.0, ambient.1], [1_887, 4_096])
        XCTAssertEqual([pairs.0, pairs.1], [70_124, 196_608])
        XCTAssertEqual(tint.0 + water.0 + redden.0 + ambient.0 + pairs.0, 75_461)
        XCTAssertEqual(tint.1 + water.1 + redden.1 + ambient.1 + pairs.1, 211_731)

        // Shapes, and the entries no search touches.
        XCTAssertEqual(ruled.tint.count, 25)
        XCTAssertEqual(ruled.tint[0], (0..<256).map(UInt8.init))
        XCTAssertEqual(ruled.water.count, 6)
        XCTAssertEqual(ruled.water[4], [UInt8](repeating: 0, count: 256))
        XCTAssertEqual(ruled.reddenA.map { $0[0xff] }, [UInt8](repeating: 0xff, count: 8))
        XCTAssertEqual(Set(TableRequests.Pair.allCases.map { ruled.pair($0).count }), [0x10000])
        XCTAssertEqual(ruled.greyPull.count, 0x10000)
        XCTAssertEqual(ruled.light.count, 16 * 0x6e00)
    }

    func testFramePortsRingAddressing() throws {
        XCTAssertEqual([FramePorts.width, FramePorts.height], [640, 416])
        XCTAssertEqual(FramePorts.ringX(630), 630)
        XCTAssertEqual(FramePorts.ringX(640), 0)
        XCTAssertEqual(FramePorts.ringX(645), 5)
        XCTAssertEqual(FramePorts.ringX(630 + 1280), 630)
        XCTAssertEqual(FramePorts.ringY(410), 410)
        XCTAssertEqual(FramePorts.ringY(416), 0)
        XCTAssertEqual(FramePorts.ringY(420), 4)
        XCTAssertEqual(FramePorts.ringOffset(x: 645, y: 420), 4 * 640 + 5)

        // A 32×32 opaque face at world (630, 410) with the view there: one blit at the ring position and three
        // wrapped copies (`.WrapDrawTile` shape) — x 630..639 and 0..21, y 410..415 and 0..25.
        let f = try fixture()
        let s = TileBlitters.Scroll(h: 630, v: 410)
        var port = [UInt8](repeating: 0, count: FramePorts.width * FramePorts.height)
        TileBlitters.wrapDraw(f.clearFace, .erase, into: &port, x: 630, y: 410, scroll: s)
        XCTAssertEqual(port.filter { $0 == 0xff }.count, 32 * 32)
        for (x, y) in [(630, 410), (639, 415), (0, 0), (21, 25), (639, 0), (0, 415), (21, 410), (630, 25)] {
            XCTAssertEqual(port[y * 640 + x], 0xff, "(\(x), \(y))")
        }
        for (x, y) in [(22, 0), (629, 410), (0, 26), (22, 26), (629, 25)] {
            XCTAssertEqual(port[y * 640 + x], 0, "(\(x), \(y))")
        }
        // Culled outside [h − 32, h + 608] × [v − 32, v + 384].
        XCTAssertTrue(TileBlitters.visible(x: 630 + 608, y: 410 + 384, width: 32, height: 32, scroll: s))
        XCTAssertFalse(TileBlitters.visible(x: 630 + 609, y: 410, width: 32, height: 32, scroll: s))
        XCTAssertFalse(TileBlitters.visible(x: 630 - 33, y: 410, width: 32, height: 32, scroll: s))
        XCTAssertFalse(TileBlitters.visible(x: 640, y: 410 - 33, width: 32, height: 32, scroll: s))

        // The whole grid at (630, 410): world cell (20, 13) = (640, 416) lands at ring (0, 0), and the frame port
        // holds the tiles port's copy (`.WrapRectBlitX`) everywhere the view reads.
        var ports = FramePorts()
        f.renderer(drawnH: 630, drawnV: 410).redrawEntireScrollGrid(h: 630, v: 410, ports: &ports)
        let alone = renderCell(f, col: 20, row: 13)
        XCTAssertEqual(cell(ports.tiles, col: 20, row: 13), cell(alone.tiles, col: 20, row: 13))
        XCTAssertEqual((0..<32).flatMap { j in (0..<32).map { ports.tiles[j * 640 + $0] } }, cell(alone.tiles, col: 20, row: 13))
        for y in stride(from: 410, to: 410 + 384, by: 7) {
            for x in stride(from: 630, to: 630 + 608, by: 5) {
                let o = FramePorts.ringOffset(x: x, y: y)
                XCTAssertEqual(ports.frame[o], ports.tiles[o])
            }
        }
    }

    func testPatternTileIndexRule() throws {
        let f = try fixture()
        XCTAssertEqual(f.level.header.patternPeriodSix, 0)
        XCTAssertEqual(TileGridRenderer.patternTile(col: 0, row: 0, periodSix: false), 0)
        XCTAssertEqual(TileGridRenderer.patternTile(col: 9, row: 10, periodSix: false), 1 + 8 * 2)
        XCTAssertEqual(TileGridRenderer.patternTile(col: 7, row: 7, periodSix: false), 63)
        XCTAssertEqual(TileGridRenderer.patternTile(col: 8, row: 8, periodSix: false), 0)
        let l2 = try LevelFile.load(from: f.resources, level: 2)
        XCTAssertEqual(l2.header.patternPeriodSix, 1)
        XCTAssertEqual(TileGridRenderer.patternTile(col: 7, row: 13, periodSix: true), 1 + 8 * 1)
        XCTAssertEqual(TileGridRenderer.patternTile(col: 5, row: 5, periodSix: true), 45)
        XCTAssertEqual(TileGridRenderer.patternTile(col: 6, row: 6, periodSix: true), 0)
        // Every 8×8 index 0..63 once per period; the 6×6 rule never reaches columns 6, 7 of the sheet.
        XCTAssertEqual(Set((0..<8).flatMap { r in (0..<8).map { TileGridRenderer.patternTile(col: $0, row: r, periodSix: false) } }).count, 64)
        let six = Set((0..<6).flatMap { r in (0..<6).map { TileGridRenderer.patternTile(col: $0, row: r, periodSix: true) } })
        XCTAssertEqual(six.count, 36)
        XCTAssertTrue(six.allSatisfy { $0 % 8 < 6 && $0 < 48 })

        // A level-1 pattern cell (FG tile 95) draws pattern face (col mod 8) + 8·(row mod 8).
        let (col, row) = try XCTUnwrap((0..<50).lazy.flatMap { r in (0..<200).lazy.map { ($0, r) } }
            .first { f.level.fgTile(col: $0.0, row: $0.1) == 95 && f.level.overlay1(col: $0.0, row: $0.1) < 100 })
        let ports = renderCell(f, col: col, row: row)
        let face = f.sets.pattern.faces[(col % 8) + 8 * (row % 8)]
        let got = cell(ports.tiles, col: col, row: row)
        for (i, (c, v)) in zip(try copied(face), try face.decode()).enumerated() where c {
            XCTAssertEqual(got[i], v)
        }
    }

    func testTileFrameLevel1Start() throws {
        let f = try fixture()
        let L = f.level
        // The cells the 640×416 ring covers from scroll (0, 10) (p17).
        let cols = (0 >> 5)...((0 + 640 - 1) >> 5), rows = (10 >> 5)...((10 + 416 - 1) >> 5)
        XCTAssertEqual([cols.lowerBound, cols.upperBound, rows.lowerBound, rows.upperBound], [0, 19, 0, 13])
        let cells = rows.flatMap { r in cols.map { ($0, r) } }
        XCTAssertEqual(cells.count, 280)
        XCTAssertEqual(cells.filter { L.fgTile(col: $0.0, row: $0.1) >= 0 }.count, 189)
        XCTAssertEqual(cells.filter { L.fgTile(col: $0.0, row: $0.1) == 95 }.count, 116)
        XCTAssertEqual(cells.filter { L.bgTile(col: $0.0, row: $0.1) >= 0 }.count, 162)
        XCTAssertEqual(cells.filter { (200..<210).contains(L.bgKind(tile: L.bgTile(col: $0.0, row: $0.1))) }.count, 0)
        XCTAssertEqual(cells.filter { L.overlay.cell(col: $0.0, row: $0.1) != 0 }.count, 0)

        // `.RedrawEntireScrollGrid` iterates cols 0...20 × rows 0...13 (294 cells); the per-blit cull draws 20×13
        // of them (x ≤ h + 608, y ≤ v + 384) — self-derived from the dump reading ("Bank corrections" 9).
        let s = TileBlitters.Scroll(h: 0, v: 10)
        let iterated = (0...13).flatMap { r in (0...20).map { ($0, r) } }
        XCTAssertEqual(iterated.count, 294)
        XCTAssertEqual(iterated.filter { TileBlitters.visible(x: $0.0 * 32, y: $0.1 * 32, width: 32, height: 32, scroll: s) }
            .count, 260)

        var ports = FramePorts()
        f.renderer(drawnH: 0, drawnV: 10).redrawEntireScrollGrid(h: 0, v: 10, ports: &ports)
        XCTAssertEqual(ports.frame, ports.tiles)
        // Self-derived by the R1 implementer, 2026-10-07 (`.ruled`, `.errorDiffusion`, no lights — the Effects = 3
        // tile layer): FNV-1a 64 of the 640×416 frame and mask ports.
        XCTAssertEqual(String(fnv1a(ports.frame), radix: 16), "8e7a06f030d78d4a")
        XCTAssertEqual(String(fnv1a(ports.mask), radix: 16), "e5437bb66513def6")

        // Strip-incremental: `.SetScrollLocation(40, 45)` after that frame redraws only row 13 (old h's 21 columns)
        // and columns 20...21 (old v's 14 rows); the view then reads what a whole redraw at (40, 45) draws.
        var renderer = f.renderer(drawnH: 0, drawnV: 10)
        renderer.setScrollLocation(h: 40, v: 45, ports: &ports)
        XCTAssertEqual([renderer.drawnH, renderer.drawnV], [40, 45])
        var whole = FramePorts()
        f.renderer(drawnH: 40, drawnV: 45).redrawEntireScrollGrid(h: 40, v: 45, ports: &whole)
        for y in 45..<(45 + 384) {
            for x in 40..<(40 + 608) {
                let o = FramePorts.ringOffset(x: x, y: y)
                guard ports.frame[o] == whole.frame[o], ports.mask[o] == whole.mask[o] else {
                    return XCTFail("view pixel (\(x), \(y)) differs after the strip redraw")
                }
            }
        }
    }

    func testFGWaterCellRule() throws {
        let f = try fixture()
        let L = f.level
        XCTAssertEqual(L.header.submergedFaces, 0)
        // p18: the 268 L1 kind-0 water cells (BG kind 200) lie inside cols 4..193 × rows 19..49.
        let water = (0..<50).flatMap { r in (0..<200).map { ($0, r) } }
            .filter { L.bgKind(tile: L.bgTile(col: $0.0, row: $0.1)) == 200 }
        XCTAssertEqual(water.count, 268)
        XCTAssertTrue(water.allSatisfy { (4...193).contains($0.0) && (19...49).contains($0.1) })
        // A kind-0 water cell whose FG tile draws the FG-water face (0 ≤ t < 95 and 0 ≤ k < 95, the dump's gate)
        // and whose FG-water face has an opaque pixel.
        let pick = try water.first { c in
            let t = L.fgTile(col: c.0, row: c.1), k = L.fgKind(tile: t) % 100
            guard t >= 0, t < 95, k >= 0, k < 95 else { return false }
            return try copied(f.sets.fgWater.sheet.faces[t]).contains(true)
        }
        let (col, row) = try XCTUnwrap(pick)
        let t = L.fgTile(col: col, row: row), b = L.bgTile(col: col, row: row), k = L.fgKind(tile: t) % 100
        let ports = renderCell(f, col: col, row: row)

        // Oracle: BG/FG, the blend (dry blitter: 0x26c6 = 0), then the FG-water face through water table 0.
        var want = try preBlend(f, t: t, b: b)
        let pattern = f.sets.patternPlain.faces[TileGridRenderer.patternTile(col: col, row: row, periodSix: false)]
        let blend = f.blend(k)
        for (i, (c, w)) in zip(try copied(blend), try blend.decode()).enumerated() where c {
            let di = Int(want[i]) << 8 | Int(pattern[i])
            switch w {
            case 0: want[i] = pattern[i]
            case 1: want[i] = f.tables.pair(.quarterSprite)[di]
            case 2: want[i] = f.tables.pair(.average)[di]
            default: want[i] = f.tables.pair(.threeQuarterSprite)[di]
            }
        }
        let beforeWater = want
        let wf = f.sets.fgWater.sheet.faces[t]
        for (i, (c, v)) in zip(try copied(wf), try wf.decode()).enumerated() where c { want[i] = f.tables.water[0][Int(v)] }
        XCTAssertEqual(cell(ports.tiles, col: col, row: row), want)
        XCTAssertEqual(cell(ports.frame, col: col, row: row), want)
        XCTAssertNotEqual(want, beforeWater, "the water face must change the cell for this test to mean anything")
    }

    func testBlendCellMix() throws {
        let f = try fixture()
        let L = f.level
        // Blend cells: 0 ≤ t < 95 and 0 ≤ k < 95 with k = `.LookupFGTileKind(t)` mod 100. The original's lookup reads
        // the table `.LoadTileDefinitions @ 10041dcc` overwrote with 80..95 for tiles 0x50..0x5f (`LevelFile.fgKind`):
        // 1,560 cells. Research note 8's 1,335 counted the raw header table (tiles 80..92 → −1: 225 cells fewer).
        let all = (0..<50).flatMap { r in (0..<200).map { ($0, r) } }
        func blends(_ kind: (Int) -> Int) -> Int {
            all.filter { c in
                let t = L.fgTile(col: c.0, row: c.1)
                guard t >= 0, t < 95 else { return false }
                let k = kind(t) % 100
                return k >= 0 && k < 95
            }.count
        }
        XCTAssertEqual(blends(L.fgKind(tile:)), 1_560)
        XCTAssertEqual(blends { Int(L.header.fgKindTable[$0]) }, 1_335)

        // One dry blend cell whose blend face holds all four weights.
        let pick = try all.first { c in
            let t = L.fgTile(col: c.0, row: c.1), k = L.fgKind(tile: t) % 100
            guard t >= 0, t < 95, k >= 0, k < 95, L.bgKind(tile: L.bgTile(col: c.0, row: c.1)) < 200 else { return false }
            let face = f.blend(k)
            let weights = Set(zip(try copied(face), try face.decode()).filter(\.0).map(\.1))
            return weights == [0, 1, 2, 3]
        }
        let (col, row) = try XCTUnwrap(pick)
        let t = L.fgTile(col: col, row: row), b = L.bgTile(col: col, row: row), k = L.fgKind(tile: t) % 100
        let ports = renderCell(f, col: col, row: row)
        let got = cell(ports.tiles, col: col, row: row)
        let d = try preBlend(f, t: t, b: b)
        let p = f.sets.patternPlain.faces[TileGridRenderer.patternTile(col: col, row: row, periodSix: false)]
        let face = f.blend(k)
        var seen = Set<UInt8>()
        for (i, (c, w)) in zip(try copied(face), try face.decode()).enumerated() {
            let di = Int(d[i]) << 8 | Int(p[i])
            guard c else { XCTAssertEqual(got[i], d[i]); continue }   // skip → the screen pixel stays
            seen.insert(w)
            switch w {
            case 0: XCTAssertEqual(got[i], p[i])                                         // pattern
            case 1: XCTAssertEqual(got[i], f.tables.pair(.quarterSprite)[di])            // ¼ d + ¾ p
            case 2: XCTAssertEqual(got[i], f.tables.pair(.average)[di])                  // ½ / ½
            default: XCTAssertEqual(got[i], f.tables.pair(.threeQuarterSprite)[di])      // ¾ d + ¼ p
            }
        }
        XCTAssertEqual(seen, [0, 1, 2, 3])
        // The tables mean what §8 says: 0154 with the screen pixel as row is ¼ d + ¾ p.
        let (dw, pw) = (RGB16(0xffff, 0xffff, 0xffff), RGB16(0, 0, 0))
        XCTAssertEqual(TableRequests.pair(.quarterSprite, src: dw, dst: pw), RGB16(0x3fff, 0x3fff, 0x3fff))
        XCTAssertEqual(TableRequests.pair(.threeQuarterSprite, src: dw, dst: pw), RGB16(0xbffe, 0xbffe, 0xbffe))
    }

    func testOverlayCellsLevel1() throws {
        let f = try fixture()
        let L = f.level
        let overlay = (0..<50).flatMap { r in (0..<200).map { ($0, r) } }.filter { L.overlay1(col: $0.0, row: $0.1) > 99 }
        XCTAssertEqual(overlay.count, 20)
        XCTAssertTrue(overlay.allSatisfy { L.overlay1(col: $0.0, row: $0.1) == 100 })
        XCTAssertEqual(overlay.filter { L.overlay2(col: $0.0, row: $0.1) == 95 }.count, 12)
        for (col, row) in overlay {
            let o2 = L.overlay2(col: col, row: row)
            let ports = renderCell(f, col: col, row: row)
            let drawn = o2 == 95 ? f.sets.pattern.faces[TileGridRenderer.patternTile(col: col, row: row, periodSix: false)]
                                 : f.sets.fg.faces[o2]
            let tiles = cell(ports.tiles, col: col, row: row), mask = cell(ports.mask, col: col, row: row)
            for (i, (c, v)) in zip(try copied(drawn), try drawn.decode()).enumerated() where c {
                XCTAssertEqual(tiles[i], v, "(\(col), \(row)) o2 \(o2) px \(i)")
            }
            // The overlay's mask stamp is FG face o2 — face 95 of the FG sheet when o2 = 95.
            for (i, c) in try copied(f.sets.fg.faces[o2]).enumerated() where c {
                XCTAssertEqual(mask[i], 0, "(\(col), \(row)) mask px \(i)")
            }
        }
    }

    func testMaskPortTransparencyRule() throws {
        let f = try fixture()
        let L = f.level
        // "Bank corrections" 9: each redrawn cell's mask starts at 0xFF (erase-bool, PICT 1002) and its tiles cell at
        // 0x00; every boolean stamp writes 0x00 over the face's opaque pixels. Ports start at a sentinel to show both
        // values are written, not inherited.
        var ports = FramePorts(fill: 0x5a)
        f.renderer(drawnH: 0, drawnV: 10).redrawEntireScrollGrid(h: 0, v: 10, ports: &ports)
        XCTAssertFalse(ports.mask.contains(0x5a))
        XCTAssertEqual(Set(ports.mask), [0x00, 0xff])

        func stampMask(_ faces: [EncodedFace]) throws -> [UInt8] {
            var m = [UInt8](repeating: 0xff, count: 32 * 32)
            for face in faces { for (i, c) in try copied(face).enumerated() where c { m[i] = 0 } }
            return m
        }
        var emptyCells = 0, opaqueCells = 0
        for row in 0...12 {
            for col in 0...19 {
                let t = L.fgTile(col: col, row: row), b = L.bgTile(col: col, row: row)
                let fg = f.sets.fg.faces, bg = f.sets.bg.faces
                var stamps: [EncodedFace] = []
                if t < 0 {
                    if b >= 0 { stamps = [bg[b]] }
                } else if !fg[t].hasTransparentPixel || b < 0 {
                    stamps = [fg[t]]
                } else {
                    stamps = bg[b].hasTransparentPixel ? [bg[b], fg[t]] : [bg[b]]
                }
                let want = try stampMask(stamps)
                XCTAssertEqual(cell(ports.mask, col: col, row: row), want, "cell (\(col), \(row))")
                if stamps.isEmpty {
                    emptyCells += 1
                    XCTAssertEqual(Set(cell(ports.mask, col: col, row: row)), [0xff])
                    XCTAssertEqual(Set(cell(ports.tiles, col: col, row: row)), [0x00])
                }
                if !want.contains(0xff) { opaqueCells += 1 }
            }
        }
        // Self-derived from the start window: cells with nothing stamped (fill 0xFF throughout, tiles 0x00) and
        // cells stamped opaque throughout.
        XCTAssertEqual([emptyCells, opaqueCells], [29, 217])
    }
}

private extension TileGridTests.Fixture {
    /// Blend face k (PICT 185 after `.ProcessFGBlendTileFaces`).
    func blend(_ k: Int) -> EncodedFace { fixed.blend.faces[k] }
}
