import XCTest
import HectorResources
@testable import FerazelCore

/// C2 (docs/plans/2026-10-06-ferazel-phase1.md): `Mlvl` layout, header fields, tile-map decodes, factor tables
/// and placement records against the committed `Resources/Ferazel` (D26). Contract: world-data §3.1–§3.4.
/// Every number is a planner probe (p02 = Research note 7/8, p18 water, p19 factors, p21 all-level placements).
/// A missing data file is a FAILURE naming the path, never a skip (plan invariant 5).
final class LevelFileTests: XCTestCase {

    private static let levelIds: [Int16] = [1, 2, 3, 4, 5, 10, 11, 15, 18, 20, 21, 22, 25, 30, 31, 40, 45, 50, 51,
                                            52, 55, 62, 67, 70]

    private func resources() throws -> FerazelResources {
        try FerazelData.open(try FerazelData.dataDirectory())
    }

    private func allLevels(_ r: FerazelResources) throws -> [Int16: LevelFile] {
        var out: [Int16: LevelFile] = [:]
        for id in Self.levelIds { out[id] = try LevelFile.load(from: r, level: id) }
        return out
    }

    func testTwentyFourLevelIdsAndExactLayout() throws {
        let r = try resources()
        XCTAssertEqual(r.world.resources(of: "Mlvl").map(\.id).sorted(), Self.levelIds)
        // Research note 7: resource sizes; every one layout-exact (§3.1).
        let sizes: [Int16: Int] = [1: 126_748, 2: 126_748, 3: 197_724, 4: 197_724, 5: 53_916, 10: 231_004,
                                   11: 183_292, 15: 257_724, 18: 66_140, 20: 201_452, 21: 234_524, 22: 328_348,
                                   25: 66_140, 30: 183_772, 31: 231_004, 40: 305_884, 45: 145_052, 50: 231_004,
                                   51: 198_972, 52: 128_284, 55: 53_916, 62: 231_004, 67: 52_140, 70: 113_308]
        for id in Self.levelIds {
            let res = try XCTUnwrap(r.world.resource(type: "Mlvl", id: id), "Mlvl \(id)")
            XCTAssertEqual(res.data.count, sizes[id], "Mlvl \(id) size")
            let level = try LevelFile(id: id, data: res.data)
            let h = level.header
            let expected = LevelFile.headerSize
                + 2 * (Int(h.pxBackWidth) * Int(h.pxBackHeight) + Int(h.pxMidWidth) * Int(h.pxMidHeight))
                + 8 * Int(h.gridWidth) * Int(h.gridHeight)
            XCTAssertEqual(expected, res.data.count, "Mlvl \(id) layout")
            XCTAssertEqual(level.pxBack.cells.count, Int(h.pxBackWidth) * Int(h.pxBackHeight))
            XCTAssertEqual(level.pxMid.cells.count, Int(h.pxMidWidth) * Int(h.pxMidHeight))
            for map in [level.bg, level.fg, level.map5, level.overlay] {
                XCTAssertEqual(map.width, Int(h.gridWidth)); XCTAssertEqual(map.height, Int(h.gridHeight))
            }
        }
        // A resource of the wrong length is refused (one byte short, one byte long).
        let one = try XCTUnwrap(r.world.resource(type: "Mlvl", id: 1)).data
        XCTAssertThrowsError(try LevelFile(id: 1, data: one.dropLast())) { error in
            XCTAssertEqual(error as? WorldDataError,
                           .wrongLength(type: "Mlvl", id: 1, expected: 126_748, actual: 126_747))
        }
        XCTAssertThrowsError(try LevelFile(id: 1, data: one + Data([0])))
        XCTAssertThrowsError(try LevelFile(id: 1, data: Data(count: 100)))
        // A forged negative dimension is refused by name (no layout length is derivable).
        let h1 = try LevelFile(id: 1, data: one).header
        var forged = one
        forged[forged.startIndex + 0xb278] = 0xff; forged[forged.startIndex + 0xb279] = 0xff   // pxBackWidth = −1
        XCTAssertThrowsError(try LevelFile(id: 1, data: forged)) { error in
            XCTAssertEqual(error as? WorldDataError,
                           .badDimensions(type: "Mlvl", id: 1,
                                          widths: [-1, Int(h1.pxMidWidth), Int(h1.gridWidth)],
                                          heights: [Int(h1.pxBackHeight), Int(h1.pxMidHeight), Int(h1.gridHeight)]))
        }
    }

    func testLevel1Header() throws {
        let h = try LevelFile.load(from: try resources(), level: 1).header
        // Research note 7, level-1 row (p02).
        XCTAssertEqual(h.magic, 0x0427_7dc9)
        XCTAssertEqual(h.name, "A Scent Of Peril")
        XCTAssertEqual(h.mapNodeLevel, 1)
        XCTAssertEqual(h.omniPxMode, 0)
        XCTAssertEqual(h.submergedFaces, 0)
        XCTAssertEqual(h.startFacingLeft, 0)
        XCTAssertEqual(h.waterSurfaceEffect, 0)
        XCTAssertEqual(h.parallaxRipple, 0)
        XCTAssertEqual(h.patternPeriodSix, 0)
        XCTAssertEqual(h.pxUsesSpriteClut, 0)
        XCTAssertEqual(h.darknessEnable, 5)
        XCTAssertEqual(h.cameraOffsetX, 0); XCTAssertEqual(h.cameraOffsetY, 0)
        XCTAssertEqual(h.stripPict, 0); XCTAssertEqual(h.stripFactor, 0); XCTAssertEqual(h.stripBaseY, 0)
        XCTAssertEqual(h.altClut, 0)
        XCTAssertEqual(h.flameMode, 0)
        XCTAssertEqual(h.arenaBound, 0)
        XCTAssertEqual(h.autoScrollEnable, 0)
        XCTAssertEqual(h.clutAnimMode, 0)
        XCTAssertEqual(h.chapter, 1)
        XCTAssertEqual(h.startY, 175); XCTAssertEqual(h.startX, 115)
        XCTAssertEqual(h.music, 1)
        XCTAssertEqual(h.pxBackPict, 207); XCTAssertEqual(h.pxMidPict, 0)
        XCTAssertEqual(h.fgPict, 200); XCTAssertEqual(h.bgPict, 203); XCTAssertEqual(h.patternPict, 206)
        XCTAssertEqual(h.levelClut, 201); XCTAssertEqual(h.screenClut, 202)
        XCTAssertEqual(h.pxMidEnable, 0)
        XCTAssertEqual(h.pxBackYFactor, 74); XCTAssertEqual(h.pxMidYFactor, 128)
        XCTAssertEqual([h.pxBackWidth, h.pxBackHeight, h.pxMidWidth, h.pxMidHeight, h.gridWidth, h.gridHeight],
                       [32, 8, 32, 8, 200, 50])
        XCTAssertEqual(Int(h.gridWidth) * 32, 6_400); XCTAssertEqual(Int(h.gridHeight) * 32, 1_600)
    }

    func testAllLevelsHeaderCensus() throws {
        let levels = try allLevels(try resources())
        func ids(where predicate: (LevelHeader) -> Bool) -> [Int16] {
            Self.levelIds.filter { predicate(levels[$0]!.header) }
        }
        // OmniPx modes {0: 20 levels, 1: L15, 2: L5, 5: L25, 6: L70}.
        XCTAssertEqual(ids { $0.omniPxMode == 0 }.count, 20)
        XCTAssertEqual(ids { $0.omniPxMode == 1 }, [15])
        XCTAssertEqual(ids { $0.omniPxMode == 2 }, [5])
        XCTAssertEqual(ids { $0.omniPxMode == 5 }, [25])
        XCTAssertEqual(ids { $0.omniPxMode == 6 }, [70])
        XCTAssertEqual(ids { $0.pxMidEnable == 1 }, [10, 15, 21, 22, 30, 31, 40, 45, 50, 51, 52, 55, 62, 70])
        XCTAssertEqual(ids { $0.pxMidEnable != 0 }, ids { $0.pxMidPict != 0 })
        let strips = Dictionary(uniqueKeysWithValues: ids { $0.stripPict != 0 }.map { ($0, levels[$0]!.header.stripPict) })
        XCTAssertEqual(strips, [10: 265, 30: 275, 40: 315, 45: 315, 62: 345, 67: 385])
        XCTAssertEqual(ids { $0.startFacingLeft == 1 }, [3, 5, 11, 18, 40, 45])
        XCTAssertEqual(ids { $0.startFacingLeft > 1 }, [])
        XCTAssertEqual(ids { $0.flameMode == 1 }, [52]); XCTAssertEqual(ids { $0.flameMode == 2 }, [55])
        XCTAssertEqual(ids { $0.flameMode != 0 }, [52, 55])
        XCTAssertEqual(ids { $0.clutAnimMode == 1 }, [50, 51]); XCTAssertEqual(ids { $0.clutAnimMode == 3 }, [67])
        XCTAssertEqual(ids { $0.clutAnimMode != 0 }, [50, 51, 67])
        let chapters = Dictionary(uniqueKeysWithValues: ids { $0.chapter != 0 }.map { ($0, levels[$0]!.header.chapter) })
        XCTAssertEqual(chapters, [1: 1, 10: 2, 40: 3, 50: 4, 22: 5, 30: 6, 62: 7])
        XCTAssertEqual(ids { $0.pxUsesSpriteClut == 1 }, [62, 70])
        XCTAssertEqual(ids { $0.pxUsesSpriteClut != 0 }, [62, 70])
        // The map-node level number equals the own id in all 24 (§3.2).
        XCTAssertEqual(Self.levelIds.filter { levels[$0]!.header.mapNodeLevel != $0 }, [])
    }

    func testLevel1Maps() throws {
        let level = try LevelFile.load(from: try resources(), level: 1)
        let w = level.header.gridWidth, h = level.header.gridHeight
        var bgTiles = Set<Int>(), noTile = 0, lightRaw: [Int: Int] = [:]
        var fgNonZero = 0, fgWithTile = 0, fgPattern = 0, crunchKind = 0, crunchDir = 0
        var overlayNonZero = 0, o1Values = Set<Int>(), o2Counts: [Int: Int] = [:]
        for row in 0..<Int(h) {
            for col in 0..<Int(w) {
                let bgCell = level.bg.cell(col: col, row: row)
                let t = level.bgTile(col: col, row: row)
                if t == -1 { noTile += 1 } else { bgTiles.insert(t) }
                lightRaw[Int(bgCell >> 8), default: 0] += 1
                XCTAssertEqual(level.lightByte(col: col, row: row), Int(bgCell >> 8) - 1)

                if level.fg.cell(col: col, row: row) != 0 { fgNonZero += 1 }
                let ft = level.fgTile(col: col, row: row)
                if ft != -1 { fgWithTile += 1 }
                if ft == 95 { fgPattern += 1 }
                if level.crunchKind(col: col, row: row) != 0 { crunchKind += 1 }
                if level.crunchDir(col: col, row: row) != 0 { crunchDir += 1 }

                if level.overlay.cell(col: col, row: row) != 0 {
                    overlayNonZero += 1
                    o1Values.insert(level.overlay1(col: col, row: row))
                    o2Counts[level.overlay2(col: col, row: row), default: 0] += 1
                }
            }
        }
        XCTAssertEqual(noTile, 8_353)
        XCTAssertEqual(bgTiles.count, 73)
        XCTAssertEqual(lightRaw, [1: 1931, 2: 472, 3: 491, 4: 449, 5: 511, 6: 656, 7: 880, 8: 1166, 9: 1048,
                                  10: 1060, 11: 1293, 12: 43])
        XCTAssertEqual(fgNonZero, 7_274)
        XCTAssertEqual(fgWithTile, 7_270)
        XCTAssertEqual(fgPattern, 5_710)
        XCTAssertEqual(crunchKind, 3)
        XCTAssertEqual(crunchDir, 225)
        XCTAssertTrue(level.map5.cells.allSatisfy { $0 == 0 }, "map #5 all zero")
        XCTAssertEqual(overlayNonZero, 20)
        XCTAssertEqual(o1Values, [100])
        XCTAssertEqual(o2Counts, [95: 12, 0: 3, 2: 2, 8: 1, 9: 1, 10: 1])
        // PxMid: 256 cells, all 0xFFFF, read as −1.
        XCTAssertEqual(level.pxMid.cells.count, 256)
        XCTAssertTrue(level.pxMid.cells.allSatisfy { $0 == 0xFFFF })
        XCTAssertEqual(level.pxMidTile(col: 3, row: 2), -1)
        // PxBack: 256 cells, tile 16 in 69 of them.
        XCTAssertEqual(level.pxBack.cells.count, 256)
        XCTAssertEqual(level.pxBack.cells.filter { $0 == 16 }.count, 69)
        // (column, row) order and `.ConstrainXY` clamping (§3.3): row-major cell = row·w + col.
        XCTAssertEqual(level.fg.cell(col: 7, row: 3), level.fg.cells[3 * Int(w) + 7])
        XCTAssertEqual(level.fg.cell(col: -5, row: -9), level.fg.cells[0])
        XCTAssertEqual(level.fg.cell(col: 10_000, row: 10_000), level.fg.cells[level.fg.cells.count - 1])
        XCTAssertEqual(level.fg.cell(col: Int(w) + 4, row: 2), level.fg.cells[2 * Int(w) + Int(w) - 1])
    }

    func testLevel1KindTablesAndWater() throws {
        let level = try LevelFile.load(from: try resources(), level: 1)
        // Research note 8 — the header tables as stored.
        var fg = [Int16](repeating: -1, count: 96)
        for t in 0...47 { fg[t] = Int16(t) }
        for t in 48...51 { fg[t] = 3 }
        for t in 52...55 { fg[t] = 1 }
        for t in 56...59 { fg[t] = 0 }
        for t in 60...63 { fg[t] = 2 }
        fg[64] = 203; fg[65] = 34; fg[66] = 35; fg[67] = 32; fg[68] = 33
        XCTAssertEqual(level.header.fgKindTable, fg)
        var bg = [Int16](repeating: -1, count: 96)
        bg[0] = 200; bg[1] = 200; bg[2] = 201; bg[3] = 201; bg[4] = 202; bg[5] = 202; bg[6] = 103; bg[7] = 103
        bg[11] = 104; bg[12] = 107; bg[13] = 104; bg[22] = 103; bg[23] = 103
        XCTAssertEqual(level.header.bgKindTable, bg)
        // Lookups: FG kinds 0x50..0x5f overwritten with the identity 80..95 (`.LoadTileDefinitions`); out of
        // range → −1.
        for t in 0..<80 { XCTAssertEqual(level.fgKind(tile: t), Int(fg[t]), "fg tile \(t)") }
        for t in 80..<96 { XCTAssertEqual(level.fgKind(tile: t), t, "fg tile \(t)") }
        for t in 0..<96 { XCTAssertEqual(level.bgKind(tile: t), Int(bg[t]), "bg tile \(t)") }
        for t in [-1, 96, 200] {
            XCTAssertEqual(level.fgKind(tile: t), -1); XCTAssertEqual(level.bgKind(tile: t), -1)
        }
        // Water (p18): BG kind 200 (water kind 0) 268 cells, 201 (kind 1) 24 cells.
        var water: [Int: Int] = [:]
        for row in 0..<level.bg.height {
            for col in 0..<level.bg.width {
                let k = level.bgKind(tile: level.bgTile(col: col, row: row))
                if (200...209).contains(k) { water[k - 200, default: 0] += 1 }
            }
        }
        XCTAssertEqual(water, [0: 268, 1: 24])
    }

    func testFactorTablesLevel1() throws {
        let level = try LevelFile.load(from: try resources(), level: 1)
        XCTAssertEqual(level.backFactors.count, 8192)
        XCTAssertEqual(level.midFactors.count, 8192)
        for (row, f) in level.backFactors.enumerated() {
            XCTAssertEqual(f, (276...412).contains(row) ? 64 : 128, "back factor row \(row)")
        }
        XCTAssertTrue(level.midFactors.allSatisfy { $0 == 128 })
    }

    func testPlacementsLevel1() throws {
        let level = try LevelFile.load(from: try resources(), level: 1)
        XCTAssertEqual(level.placements.count, 511)
        XCTAssertEqual(level.placements.map(\.index), Array(0..<511))
        XCTAssertEqual(level.activePlacements.count, 162)
        var classes: [SpriteClass: Int] = [:]
        for p in level.activePlacements {
            let (c, _) = try XCTUnwrap(SpriteClassTable.classify(type: p.type, p1Negative: p.p1 < 0), "type \(p.type)")
            classes[c, default: 0] += 1
        }
        XCTAssertEqual(classes, [.bonus: 81, .box: 43, .background: 16, .platform: 7, .walker: 7, .roach: 5,
                                 .crawler: 3])
        XCTAssertEqual(level.placements.filter { $0.flag == 0 && $0.type != 0 }.count, 2)
        XCTAssertEqual(level.placements.filter { $0.flag > 1 }.count, 0)
        // world-data §3.4 worked decode.
        let r0 = level.placements[0], r1 = level.placements[1]
        XCTAssertEqual([Int(r0.flag), Int(r0.byte1), Int(r0.type), Int(r0.p1), Int(r0.p2), Int(r0.p3), Int(r0.p4),
                        Int(r0.y), Int(r0.x)], [1, 0, 2922, 0, 0, 0, 0, 666, 5455])
        XCTAssertEqual([Int(r1.flag), Int(r1.byte1), Int(r1.type), Int(r1.p1), Int(r1.p2), Int(r1.p3), Int(r1.p4),
                        Int(r1.y), Int(r1.x)], [1, 0, 2902, 12, 0, 0, 0, 439, 406])
    }

    func testAllLevelsPlacementCensus() throws {
        let levels = try allLevels(try resources())
        var active = 0, types = Set<Int16>(), flag0Typed = 0, others: [(Int16, Int, UInt8, Int16)] = []
        for id in Self.levelIds {
            let level = levels[id]!
            active += level.activePlacements.count
            for p in level.placements {
                switch p.flag {
                case 1: types.insert(p.type)
                case 0: if p.type != 0 { flag0Typed += 1 }
                default: others.append((id, p.index, p.flag, p.type))
                }
            }
        }
        XCTAssertEqual(active, 5_641)
        XCTAssertEqual(types.count, 243)
        XCTAssertEqual(flag0Typed, 48)
        XCTAssertEqual(others.count, 1)
        XCTAssertEqual(others.first?.0, 11); XCTAssertEqual(others.first?.1, 283)
        XCTAssertEqual(others.first?.2, 99); XCTAssertEqual(others.first?.3, 2956)
        // A record with p2, p3, p4 all non-zero and distinct, so a field swap cannot pass (Mlvl 55 record 5;
        // bytes 01 00 057b 0034 001e 005a 003c 010c 032a, checked with xxd).
        let r5 = levels[55]!.placements[5]
        XCTAssertEqual([Int(r5.flag), Int(r5.byte1), Int(r5.type), Int(r5.p1), Int(r5.p2), Int(r5.p3), Int(r5.p4),
                        Int(r5.y), Int(r5.x)], [1, 0, 1403, 52, 30, 90, 60, 268, 810])
    }
}
