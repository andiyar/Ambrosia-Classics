import XCTest
import FerazelCore
import HectorGraphics
@testable import FerazelRender

/// C5 (docs/plans/2026-10-06-ferazel-phase1.md): faces — PICT → 8-bit indices under a conversion CLUT through
/// `ColorSearch` (+ the ditherCopy model, the 1-bit bypass), the `.EncodeRect` RLE encoder, and the sheet loaders
/// with the original cell arguments (sprites-backgrounds §1–§3, lighting-tables §8, player-states §7). Planner
/// numbers are probes p10/p11/p16 (plan Research notes 5, 6, 9); the 2922 dither and 185 weight counts are
/// self-derived (see each test). A missing data file is a FAILURE naming the path (plan invariant 5).
final class FaceTests: XCTestCase {

    private func resources() throws -> FerazelResources {
        try FerazelData.open(try FerazelData.dataDirectory())
    }

    private func clut(_ id: Int16, _ r: FerazelResources) throws -> ColorLUT {
        try ColorLUT.load(id: id, from: r, chain: .level)
    }

    /// p10's exposure figures for one sheet under one CLUT: distinct source colours over the pixels, how many of
    /// them sit exactly in the CLUT, on how many `.ruled` and `.exactNearest` disagree, and their pixels.
    private struct Exposure: Equatable {
        var colours: Int, exact: Int, differ: Int, pixelsDiffer: Int
    }

    private func exposure(_ source: PictureSource, _ c: ColorLUT) throws -> Exposure {
        let colours = try XCTUnwrap(ConvertedPicture.sourceColors(source))
        let exactSet = Set(c.entries.map(RGB16.init))
        let ruled = ColorSearch(model: .ruled).prepared(for: c)
        let exact = ColorSearch(model: .exactNearest).prepared(for: c)
        let differing = colours.filter { ruled.index(of: $0.key) != exact.index(of: $0.key) }
        return Exposure(colours: colours.count, exact: colours.keys.filter(exactSet.contains).count,
                        differ: differing.count, pixelsDiffer: differing.values.reduce(0, +))
    }

    private func zeros(_ p: [UInt8]) -> Int { p.reduce(0) { $0 + ($1 == 0 ? 1 : 0) } }

    // MARK: - Conversion

    func testIndexedConversionWalkSheet1020() throws {
        let r = try resources()
        let c = try clut(200, r)
        let walk = try PictureSource.load(id: 1020, from: r, chain: .frontEnd)
        XCTAssertEqual(try exposure(walk, c), Exposure(colours: 51, exact: 6, differ: 5, pixelsDiffer: 1_333))
        let ruled = try ConvertedPicture(source: walk, clut: c, search: ColorSearch(model: .ruled))
        let exact = try ConvertedPicture(source: walk, clut: c, search: ColorSearch(model: .exactNearest))
        XCTAssertEqual(ruled.width, 400)
        XCTAssertEqual(ruled.height, 480)
        XCTAssertEqual(ruled.clutId, 200)
        XCTAssertEqual(zip(ruled.pixels, exact.pixels).filter { $0 != $1 }.count, 1_333)
        XCTAssertEqual(zeros(ruled.pixels), 169_957)
        XCTAssertEqual(zeros(exact.pixels), 169_957)
    }

    func testPxBack207AllExact() throws {
        let r = try resources()
        let c = try clut(201, r)
        let px = try PictureSource.load(id: 207, from: r, chain: .level)
        XCTAssertEqual(try exposure(px, c), Exposure(colours: 52, exact: 52, differ: 0, pixelsDiffer: 0))
        let ruled = try ConvertedPicture(source: px, clut: c, search: ColorSearch(model: .ruled))
        let exact = try ConvertedPicture(source: px, clut: c, search: ColorSearch(model: .exactNearest))
        XCTAssertEqual(ruled.pixels, exact.pixels)
        XCTAssertEqual(ruled.pixels.count, 768 * 768)
    }

    func testTileSheetConversionExposure() throws {
        let r = try resources()
        let c = try clut(202, r)
        let expected: [(Int16, Exposure)] = [
            (200, Exposure(colours: 239, exact: 30, differ: 62, pixelsDiffer: 7_193)),   // FG
            (203, Exposure(colours: 234, exact: 28, differ: 67, pixelsDiffer: 13_898)),  // BG
            (206, Exposure(colours: 200, exact: 30, differ: 73, pixelsDiffer: 8_606)),   // pattern
        ]
        for (id, want) in expected {
            let source = try PictureSource.load(id: id, from: r, chain: .level)
            XCTAssertEqual(try exposure(source, c), want, "PICT \(id)")
            let ruled = try ConvertedPicture(source: source, clut: c, search: ColorSearch(model: .ruled))
            let exact = try ConvertedPicture(source: source, clut: c, search: ColorSearch(model: .exactNearest))
            XCTAssertEqual(zip(ruled.pixels, exact.pixels).filter { $0 != $1 }.count, want.pixelsDiffer, "PICT \(id)")
        }
    }

    /// PICT 2922 (Sprites, 56×60, 32-bit DirectBits, mode 64) under CLUT 200, `.ruled`. Self-derived 2026-10-07
    /// by an independent Python run over the probe libraries (`colorsearch.ITab(…, 4)` + `exact_first`, the
    /// PackBits planes decoded by hand), Floyd–Steinberg exactly as `DitherModel.errorDiffusion` documents it
    /// (16-bit, clamp then search, error = clamped − chosen, 7/3/5/1 sixteenths truncated toward zero, rows
    /// top-down, left-to-right): `.none` 16 distinct indices, `.errorDiffusion` 25; index 0 on 1,232 pixels under
    /// both; the two conversions differ on 704 of 3,360 pixels.
    func testDirectBitsDitherModelsSelectable() throws {
        let r = try resources()
        let c = try clut(200, r)
        let source = try PictureSource.load(id: 2922, from: r, chain: .frontEnd)
        guard case .direct(let d) = source.pixels else { return XCTFail("PICT 2922 is not DirectBits") }
        XCTAssertEqual(d.width, 56)
        XCTAssertEqual(d.height, 60)
        XCTAssertEqual(d.transferMode, 64)
        let search = ColorSearch(model: .ruled)
        let plain = try ConvertedPicture(source: source, clut: c, search: search, dither: .none)
        let dithered = try ConvertedPicture(source: source, clut: c, search: search, dither: .errorDiffusion)
        let byDefault = try ConvertedPicture(source: source, clut: c, search: search)
        XCTAssertEqual(byDefault, dithered, "default dither is .errorDiffusion (D26)")
        XCTAssertNotEqual(plain.pixels, dithered.pixels)
        XCTAssertEqual(zip(plain.pixels, dithered.pixels).filter { $0 != $1 }.count, 704)
        XCTAssertEqual(Set(plain.pixels).count, 16)
        XCTAssertEqual(Set(dithered.pixels).count, 25)
        XCTAssertEqual(zeros(plain.pixels), 1_232)
        XCTAssertEqual(zeros(dithered.pixels), 1_232)
        // `.none` is each pixel's own search, 8-bit components × 257.
        for i in [0, 1_000, 3_359] {
            let rgb = RGB16(UInt16(d.rgb[3 * i]) * 257, UInt16(d.rgb[3 * i + 1]) * 257, UInt16(d.rgb[3 * i + 2]) * 257)
            XCTAssertEqual(plain.pixels[i], search.index(of: rgb, in: c))
        }
    }

    func testOneBitBitMapsBypassColorSearch() throws {
        let r = try resources()
        let c200 = try clut(200, r), c201 = try clut(201, r)
        for (id, chain, setBits) in [(Int16(183), ResourceChain.frontEnd, 29_595), (319, .level, 44_880)] {
            let source = try PictureSource.load(id: id, from: r, chain: chain)
            guard case .indexed(let bm) = source.pixels else { return XCTFail("PICT \(id) not indexed") }
            XCTAssertEqual(bm.version, 1)
            XCTAssertEqual(bm.depth, 1)
            XCTAssertNil(bm.colorTable)
            XCTAssertEqual(bm.pixels.filter { $0 == 1 }.count, setBits, "PICT \(id) set bits")
            var outputs: [[UInt8]] = []
            for model in [ColorSearch.Model.ruled, .exactNearest, .inverseTable(bits: 5)] {
                for c in [c200, c201] {
                    for dither in [DitherModel.none, .errorDiffusion] {
                        let p = try ConvertedPicture(source: source, clut: c, search: ColorSearch(model: model), dither: dither)
                        XCTAssertTrue(p.pixels.allSatisfy { $0 == 0x00 || $0 == 0xff }, "PICT \(id) \(model)")
                        XCTAssertEqual(p.pixels.filter { $0 == 0xff }.count, setBits, "PICT \(id) \(model)")
                        XCTAssertEqual(zip(p.pixels, bm.pixels).filter { ($0 == 0xff) != ($1 == 1) }.count, 0)
                        outputs.append(p.pixels)
                    }
                }
            }
            XCTAssertEqual(Set(outputs).count, 1, "PICT \(id): identical under every model")
        }
    }

    // MARK: - Encoder

    func testEncodeRectTokenGrammar() throws {
        // 9 wide × 4 rows: leading skip, odd literal, inner skip, trailing skip; an all-transparent row; a full
        // literal row (length 9 → pad 3); a literal of 4 (no pad) after a skip.
        let w = 9
        let rows: [[UInt8]] = [
            [0, 0, 5, 6, 7, 0, 8, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0],
            [1, 2, 3, 4, 5, 6, 7, 8, 9],
            [0, 0, 0, 0, 0, 9, 9, 9, 9],
        ]
        let face = FaceEncoder.encode(pixels: rows.flatMap { $0 }, width: w, height: rows.count,
                                      rect: EncodedFace.Rect(top: 0, left: 0, bottom: 4, right: 9), sourceId: 77)
        func t(_ op: UInt32, _ n: UInt32) -> [UInt8] {
            let v = op << 24 | n
            return [UInt8(v >> 24), UInt8(v >> 16 & 0xff), UInt8(v >> 8 & 0xff), UInt8(v & 0xff)]
        }
        let row0 = t(3, 2) + t(2, 3) + [5, 6, 7, 0] + t(3, 1) + t(2, 1) + [8, 0, 0, 0]   // trailing skip not written
        let row2 = t(2, 9) + [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 0, 0]
        let row3 = t(3, 5) + t(2, 4) + [9, 9, 9, 9]
        let expected = t(1, UInt32(row0.count)) + row0 + t(1, 0) + t(1, UInt32(row2.count)) + row2
            + t(1, UInt32(row3.count)) + row3 + t(0, 0)
        XCTAssertEqual(face.data, expected)
        XCTAssertEqual(try face.tokens(), [
            .row(length: row0.count), .skip(2), .copy([5, 6, 7]), .skip(1), .copy([8]),
            .row(length: 0),
            .row(length: row2.count), .copy([1, 2, 3, 4, 5, 6, 7, 8, 9]),
            .row(length: row3.count), .skip(5), .copy([9, 9, 9, 9]),
            .end,
        ])
        XCTAssertEqual(try face.decode(), rows.flatMap { $0 })
        // A token with op ≥ 4 is refused on decode (invariant 6; "Encountered a bad token in sprite RLE data!").
        for op: UInt32 in [4, 5, 0xff] {
            var bad = face
            bad.data = t(1, 8) + t(op, 1) + [1, 0, 0, 0] + t(0, 0)
            XCTAssertThrowsError(try bad.decode()) { error in
                XCTAssertEqual(error as? FaceDecodeError, .badToken(op: Int(op), offset: 4))
            }
            XCTAssertThrowsError(try BlendFaces.process(bad))
        }
    }

    func testFaceRecordBoundsRule() throws {
        // Opaque pixels span rows 2..5, columns 3..6 of a 10×8 cell at (20, 10) in a 40×30 picture.
        var pixels = [UInt8](repeating: 0, count: 40 * 30)
        for (x, y) in [(23, 12), (26, 15), (24, 13)] { pixels[y * 40 + x] = 9 }
        let rect = EncodedFace.Rect(top: 10, left: 20, bottom: 18, right: 30)
        let face = FaceEncoder.encode(pixels: pixels, width: 40, height: 30, rect: rect, sourceId: 1234)
        XCTAssertEqual(face.frame, EncodedFace.Rect(top: 0, left: 0, bottom: 8, right: 10))
        XCTAssertEqual(face.bounds, EncodedFace.Rect(top: 2, left: 2, bottom: 6, right: 8))   // top, left−1, bottom+1, right+2
        XCTAssertTrue(face.hasTransparentPixel)          // +0x18
        XCTAssertEqual(face.scale, 0x100)                // +0x1c
        XCTAssertEqual(face.sourceId, 1234)              // +0x30
        XCTAssertEqual(face.width, 10)
        XCTAssertEqual(face.height, 8)
        // An opaque pixel in column 0 / row 0: left−1 clamps to 0; right+2 may pass the frame (not clamped).
        var full = [UInt8](repeating: 3, count: 4 * 2)
        let solid = FaceEncoder.encode(pixels: full, width: 4, height: 2,
                                       rect: EncodedFace.Rect(top: 0, left: 0, bottom: 2, right: 4), sourceId: 1)
        XCTAssertEqual(solid.bounds, EncodedFace.Rect(top: 0, left: 0, bottom: 2, right: 5))
        XCTAssertFalse(solid.hasTransparentPixel)
        // No opaque pixel: left = 0x7fff − 1, right = 0 + 2; top/bottom come from the record's unwritten memory,
        // modelled as 0 (→ 0, 1).
        full = [UInt8](repeating: 0, count: 4 * 2)
        let empty = FaceEncoder.encode(pixels: full, width: 4, height: 2,
                                       rect: EncodedFace.Rect(top: 0, left: 0, bottom: 2, right: 4), sourceId: 1)
        XCTAssertEqual(empty.bounds, EncodedFace.Rect(top: 0, left: 0x7ffe, bottom: 1, right: 2))
        XCTAssertTrue(empty.hasTransparentPixel)
    }

    func testEncodeRoundTripPhase1Faces() throws {
        let r = try resources()
        let level = try LevelFile.load(from: r, level: 1)
        let search = ColorSearch(model: .ruled)
        let fixed = try TileSets.Fixed(resources: r, search: search)
        let sets = try TileSets(level: level, fixed: fixed, resources: r, search: search)
        var checked = 0
        func roundTrip(_ sheet: FaceSheet, _ source: [[UInt8]], _ label: String) throws {
            XCTAssertEqual(sheet.faces.count, source.count, label)
            for (i, (face, cell)) in zip(sheet.faces, source).enumerated() {
                XCTAssertEqual(try face.decode(), cell, "\(label) face \(i)")
                checked += 1
            }
        }
        func cells(_ p: ConvertedPicture, _ a: FaceSheet.Arguments) -> [[UInt8]] {
            (0..<a.count).map { p.cell(FaceSheet.cellRect($0, a)) }
        }
        try roundTrip(sets.bg, cells(sets.pictures.bg, sets.bg.arguments), "BG 203")
        try roundTrip(sets.fg, cells(sets.pictures.fg, sets.fg.arguments), "FG 200")
        try roundTrip(sets.pattern, cells(sets.pictures.pattern, sets.pattern.arguments), "pattern 206")
        XCTAssertEqual(sets.patternPlain.faces, cells(sets.pictures.pattern, sets.patternPlain.arguments))
        XCTAssertEqual(sets.pxBack.faces.count, 36)
        XCTAssertNil(sets.pxMid)
        // FG water: each cell of 200 with the 183 mask face of its FG kind stamped to 0 (`.BlitEncBoolTile`).
        let mask = fixed.waterMask
        var water = cells(sets.pictures.fg, sets.fgWater.sheet.arguments)
        for i in 0..<96 {
            let kind = level.fgKind(tile: i)
            XCTAssertEqual(sets.fgWater.stampedKinds[i], (0..<96).contains(kind) ? kind : nil)
            guard (0..<96).contains(kind) else { continue }
            let m = try mask.faces[kind].decode()
            for p in 0..<m.count where m[p] != 0 { water[i][p] = 0 }
        }
        try roundTrip(sets.fgWater.sheet, water, "FG water 200")
        try roundTrip(mask, cells(fixed.pictures.waterMask, mask.arguments), "water mask 183")
        try roundTrip(fixed.blendSource, cells(fixed.pictures.blend, fixed.blendSource.arguments), "blend 185")
        // The 29 player sheets under CLUT 200.
        let c200 = try clut(200, r)
        for loader in FaceSheet.playerSheets {
            let source = try PictureSource.load(id: loader.pict, from: r, chain: .frontEnd)
            let picture = try ConvertedPicture(source: source, clut: c200, search: search)
            let sheet = FaceSheet(picture: picture, loader: loader)
            switch loader {
            case .set(let a): try roundTrip(sheet, cells(picture, a), "player \(loader.pict)")
            case .single: try roundTrip(sheet, [picture.pixels], "player \(loader.pict)")
            }
        }
        XCTAssertEqual(checked, 96 * 3 + 64 + 96 * 2 + 195)   // player faces: 194 in sets + 1004
    }

    // MARK: - Sheets

    func testFaceSetCellGeometry() throws {
        let a = FaceSheet.Arguments(pict: 1020, count: 16, cellWidth: 100, cellHeight: 120, columns: 4)
        XCTAssertEqual(FaceSheet.cellRect(5, a), EncodedFace.Rect(top: 120, left: 100, bottom: 240, right: 200))
        XCTAssertEqual(FaceSheet.cellRect(0, a), EncodedFace.Rect(top: 0, left: 0, bottom: 120, right: 100))
        XCTAssertEqual(FaceSheet.cellRect(15, a), EncodedFace.Rect(top: 360, left: 300, bottom: 480, right: 400))
        let r = try resources()
        let picture = try ConvertedPicture(source: try PictureSource.load(id: 1020, from: r, chain: .frontEnd),
                                           clut: try clut(200, r), search: ColorSearch(model: .ruled))
        let sheet = FaceSheet(picture: picture, loader: .set(a))
        XCTAssertEqual(sheet.faces.count, 16)
        XCTAssertFalse(sheet.shortRows)
        for face in sheet.faces {
            XCTAssertEqual(face.frame, EncodedFace.Rect(top: 0, left: 0, bottom: 120, right: 100))
            XCTAssertEqual(face.sourceId, 1020)
            XCTAssertEqual(face.scale, 0x100)
        }
        // Cell 5 is x 100..199, y 120..239 of the sheet.
        let five = try sheet.faces[5].decode()
        for y in 0..<120 {
            for x in 0..<100 { XCTAssertEqual(five[y * 100 + x], picture.pixel(x: 100 + x, y: 120 + y)) }
        }
    }

    func testPlayerFaceSetsTable() throws {
        // player-states §7 / `.InitPlayerSprite` (main l. 42427–42484): (pict, count, cellW, cellH, cols).
        let expected: [(Int16, Int, Int, Int, Int)] = [
            (1003, 4, 100, 120, 4), (1010, 10, 100, 120, 10), (1011, 4, 100, 120, 4), (1012, 6, 100, 120, 6),
            (1013, 4, 100, 120, 6), (1014, 6, 100, 120, 6), (1020, 16, 100, 120, 4), (1021, 5, 100, 120, 5),
            (1022, 10, 150, 120, 10), (1023, 10, 120, 120, 10), (1024, 12, 100, 120, 4), (1025, 8, 100, 120, 8),
            (1027, 6, 100, 120, 6), (1028, 10, 100, 120, 10), (1029, 6, 100, 120, 6), (1030, 3, 100, 120, 3),
            (1031, 6, 100, 120, 6), (1032, 6, 100, 120, 6), (1033, 6, 100, 120, 6), (1015, 8, 100, 120, 4),
            (1016, 7, 100, 120, 7), (1017, 8, 100, 120, 4), (1034, 5, 100, 120, 5), (1035, 5, 100, 120, 5),
            (1036, 6, 100, 120, 6), (1037, 4, 100, 120, 4), (1038, 4, 100, 120, 4), (1039, 9, 100, 120, 9),
        ]
        let sheets = FaceSheet.playerSheets
        XCTAssertEqual(sheets.count, 29)
        XCTAssertEqual(sheets.filter { if case .single = $0 { return true } else { return false } }.map(\.pict), [1004])
        let sets: [FaceSheet.Arguments] = sheets.compactMap { if case .set(let a) = $0 { return a } else { return nil } }
        XCTAssertEqual(sets.map { [Int($0.pict), $0.count, $0.cellWidth, $0.cellHeight, $0.columns] },
                       expected.map { [Int($0.0), $0.1, $0.2, $0.3, $0.4] })
        XCTAssertEqual(Set(sheets.map(\.pict)), Set((1003...1039).filter { ![1005, 1006, 1007, 1008, 1009, 1018, 1019, 1026].contains($0) }.map(Int16.init)))
        // Every cell lies inside its sheet's frame, and 1004 is one 100×120 face.
        let r = try resources()
        for loader in sheets {
            let source = try PictureSource.load(id: loader.pict, from: r, chain: .frontEnd)
            switch loader {
            case .set(let a):
                let last = FaceSheet.cellRect(a.count - 1, a)
                XCTAssertLessThanOrEqual(Int(last.bottom), source.height, "\(a.pict)")
                XCTAssertLessThanOrEqual((0..<a.count).map { Int(FaceSheet.cellRect($0, a).right) }.max()!, source.width, "\(a.pict)")
            case .single:
                XCTAssertEqual([source.width, source.height], [100, 120])
            }
        }
    }

    func testWaterMask183() throws {
        let r = try resources()
        let fixed = try TileSets.Fixed(resources: r, search: ColorSearch(model: .ruled))
        let mask = fixed.waterMask
        XCTAssertEqual(mask.arguments, FaceSheet.Arguments(pict: 183, count: 96, cellWidth: 32, cellHeight: 32, columns: 8))
        XCTAssertEqual(mask.faces.count, 96)
        var set = 0
        for face in mask.faces {
            let p = try face.decode()
            XCTAssertTrue(p.allSatisfy { $0 == 0 || $0 == 0xff })
            set += p.filter { $0 == 0xff }.count
        }
        XCTAssertEqual(set, 29_595)
    }

    /// PICT 185 under CLUT 200 (`.ruled`), copied pixels by weight. Self-derived 2026-10-07 by an independent
    /// Python run (probe `colorsearch.exact_first` + `ITab(…, 4)` over 185's own colour table, then the §8
    /// mapping): weight 0 → 29,184, 1 → 1,698, 2 → 5,601, 3 → 1,528; 60,293 transparent (= p11's ruled figure).
    func testBlendFaceWeights() throws {
        XCTAssertEqual(BlendFaces.weight(0), 3)
        XCTAssertEqual(BlendFaces.weight(0x97), 3)
        XCTAssertEqual(BlendFaces.weight(0x98), 3)
        for v: UInt8 in [0x99, 0x9a, 0x9b] { XCTAssertEqual(BlendFaces.weight(v), 2) }
        for v: UInt8 in [0x9c, 0x9d, 0x9e] { XCTAssertEqual(BlendFaces.weight(v), 1) }
        for v: UInt8 in [1, 0x50, 0x96, 0x9f, 0xa0, 0xfe, 0xff] { XCTAssertEqual(BlendFaces.weight(v), 0) }
        let r = try resources()
        let fixed = try TileSets.Fixed(resources: r, search: ColorSearch(model: .ruled))
        XCTAssertEqual(fixed.blend.faces.count, 96)
        XCTAssertEqual(fixed.blend.arguments, FaceSheet.Arguments(pict: 185, count: 96, cellWidth: 32, cellHeight: 32, columns: 8))
        var weights = [Int](repeating: 0, count: 4), transparent = 0
        for (face, source) in zip(fixed.blend.faces, fixed.blendSource.faces) {
            // Same token structure; only copied bytes change.
            XCTAssertEqual(face.data.count, source.data.count)
            XCTAssertEqual(face.bounds, source.bounds)
            let before = try source.decode(), after = try face.decode()
            for (b, a) in zip(before, after) {
                if b == 0 { transparent += 1; XCTAssertEqual(a, 0) } else { XCTAssertEqual(a, BlendFaces.weight(b)); weights[Int(a)] += 1 }
            }
        }
        XCTAssertEqual(weights, [29_184, 1_698, 5_601, 1_528])
        XCTAssertEqual(transparent, 60_293)
    }

    func testShortSheet257Flagged() throws {
        let r = try resources()
        let source = try PictureSource.load(id: 257, from: r, chain: .level)
        XCTAssertEqual([source.width, source.height], [768, 708])
        let picture = try ConvertedPicture(source: source, clut: try clut(201, r), search: ColorSearch(model: .ruled))
        let a = TileSets.pxBackArguments(pict: 257)
        XCTAssertEqual(a, FaceSheet.Arguments(pict: 257, count: 36, cellWidth: 128, cellHeight: 128, columns: 6))
        let plain = PlainFaceSheet(picture: picture, arguments: a)
        XCTAssertTrue(plain.shortRows)
        XCTAssertEqual(plain.shortCells, Dictionary(uniqueKeysWithValues: (30...35).map { ($0, 60) }))
        for i in 30...35 {
            let face = plain.faces[i]
            XCTAssertTrue(face[(128 - 60) * 128 ..< 128 * 128].allSatisfy { $0 == 0 }, "cell \(i) rows past the frame read 0")
            XCTAssertEqual(Array(face[0 ..< 68 * 128]), Array(picture.cell(FaceSheet.cellRect(i, a)).prefix(68 * 128)))
        }
        let encoded = FaceSheet(picture: picture, loader: .set(a))
        XCTAssertTrue(encoded.shortRows)
        XCTAssertEqual(encoded.shortCells, plain.shortCells)
        XCTAssertEqual(try encoded.faces[30].decode(), plain.faces[30])
        // A sheet inside its frame is not flagged.
        let px207 = PlainFaceSheet(picture: try ConvertedPicture(source: try PictureSource.load(id: 207, from: r, chain: .level),
                                                                  clut: try clut(201, r), search: ColorSearch(model: .ruled)),
                                   arguments: TileSets.pxBackArguments(pict: 207))
        XCTAssertFalse(px207.shortRows)
    }
}
