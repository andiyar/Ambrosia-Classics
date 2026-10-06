import XCTest
import HectorResources
@testable import DeimosCore

/// The 250 shipped plates decoded once, and the 125 groups built from them, for the whole suite.
private enum ShippedPlates {
    struct Plate: Sendable { let id: FourCC; let name: String; let image: GIFImage }
    static let plates: Result<[Plate], Error> = Result {
        let index = try RealData.index()
        return try index.records(ofType: FourCC("im08")!).map {
            Plate(id: $0.id, name: $0.displayName, image: try GIFImage(data: index.data(for: $0)))
        }
    }
    static let groups: Result<[SpriteGroup], Error> = Result {
        let all = try plates.get()
        let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0.image) })
        return try all.filter { $0.id.description != $0.id.description.uppercased() }.map { p in
            let alphaID = SpriteGroup.alphaPlateID(for: p.id)
            return try SpriteGroup(colour: p.image, alpha: XCTUnwrap(byID[alphaID]), id: p.id)
        }
    }
    static func group(_ id: String) throws -> SpriteGroup {
        try XCTUnwrap(try groups.get().first { $0.id.description == id }, id)
    }
}

/// Builds a GIF from rows of palette indices (one character per pixel, '0'…'9').
private func plateGIF(_ rows: [String], palette: [(UInt8, UInt8, UInt8)]) -> GIFImage {
    let idx = rows.flatMap { $0.map { UInt8(String($0))! } }
    return try! GIFImage(data: GIFFixture.gif(width: rows[0].count, height: rows.count, palette: palette, indices: idx))
}

final class SpriteGroupTests: XCTestCase {

    func testRGB555IsHighFiveBits() throws {
        XCTAssertEqual(QuickDrawColor.rgb555(222, 0, 0) >> 10, 27)        // round(222·31/255) would be 27 too
        XCTAssertEqual(QuickDrawColor.rgb555(0, 140, 0) >> 5, 17)         // round → 17
        XCTAssertEqual(QuickDrawColor.rgb555(0, 222, 0), 0x0360)
        XCTAssertEqual(QuickDrawColor.rgb555(16, 16, 16), 0x0842)
        XCTAssertEqual(QuickDrawColor.rgb555(255, 255, 255), 0x7FFF)
        XCTAssertEqual(QuickDrawColor.rgb555(7, 7, 7), 0)                 // truncation: round would give 1
        for c in 0...255 { XCTAssertEqual(QuickDrawColor.rgb555(UInt8(c), 0, 0) >> 10, UInt16((c * 257) >> 11)) }
        // Used palette components (per plate, per used entry, per channel) where round-to-nearest differs.
        var differ = 0
        for p in try ShippedPlates.plates.get() {
            for i in Set(p.image.indices) {
                let e = p.image.palette[Int(i)]
                for c in [e.r, e.g, e.b] where Int(c >> 3) != Int((Double(c) * 31 / 255).rounded()) { differ += 1 }
            }
        }
        XCTAssertEqual(differ, 253)
    }

    func testSystemCLUT8Table() {
        let t = QuickDrawColor.systemCLUT8
        XCTAssertEqual(t.count, 256)
        let levels: [UInt8] = [0xFF, 0xCC, 0x99, 0x66, 0x33, 0x00]
        for r in 0..<6 { for g in 0..<6 { for b in 0..<6 where 36 * r + 6 * g + b < 215 {
            let e = t[36 * r + 6 * g + b]
            XCTAssertTrue(e == (levels[r], levels[g], levels[b]))
        } } }
        func hex(_ i: Int) -> String { String(format: "%02X%02X%02X", t[i].0, t[i].1, t[i].2) }
        XCTAssertEqual([0, 5, 210, 214, 215, 225, 235, 245, 254, 255].map(hex),
                       ["FFFFFF", "FFFF00", "0000FF", "000033", "EE0000", "00EE00", "0000EE", "EEEEEE", "111111", "000000"])
    }

    func testSystemIndexCells() {
        XCTAssertEqual(QuickDrawColor.systemIndex(8, 0, 255), 210)        // GLOW fill
        XCTAssertEqual(QuickDrawColor.systemIndex(0, 0, 255), 210)        // GLOW frame body
        XCTAssertEqual(QuickDrawColor.systemIndex(255, 255, 255), 0)
        XCTAssertEqual(QuickDrawColor.systemIndex(0, 0, 0), 255)
        XCTAssertEqual(QuickDrawColor.systemIndex(0xEE, 0, 0), 215)
        // Every CLUT colour whose cell colour is itself maps to itself (the cube and ramps are q·17).
        for (i, e) in QuickDrawColor.systemCLUT8.enumerated() {
            XCTAssertEqual(QuickDrawColor.systemIndex(e.0, e.1, e.2), UInt8(i), "entry \(i)")
        }
    }

    func testPlateScanAsserts() {
        // fill == grid
        XCTAssertThrowsError(try SpritePlate.frameRects(alphaIndices: [1, 1, 2, 0, 0, 0], width: 3, height: 2)) {
            XCTAssertEqual($0 as? SpritePlateError, .fillEqualsGrid)
            XCTAssertEqual(($0 as? SpritePlateError)?.assertText, "FALSE")
        }
        // grid == key
        XCTAssertThrowsError(try SpritePlate.frameRects(alphaIndices: [0, 1, 1, 0, 0, 0], width: 3, height: 2)) {
            XCTAssertEqual($0 as? SpritePlateError, .gridEqualsKey)
        }
        // w < 3, h < 2
        XCTAssertThrowsError(try SpritePlate.frameRects(alphaIndices: [0, 1, 0, 0], width: 2, height: 2)) {
            XCTAssertEqual($0 as? SpritePlateError, .plateTooSmall(width: 2, height: 2))
        }
        XCTAssertThrowsError(try SpritePlate.frameRects(alphaIndices: [0, 1, 2], width: 3, height: 1)) {
            XCTAssertEqual($0 as? SpritePlateError, .plateTooSmall(width: 3, height: 1))
        }
        // An all-fill plate has no frames.
        XCTAssertThrowsError(try SpritePlate.frameRects(alphaIndices: [0, 1, 2, 0, 0, 0], width: 3, height: 2)) {
            XCTAssertEqual($0 as? SpritePlateError, .noFrames)
            XCTAssertEqual(($0 as? SpritePlateError)?.assertText, "outRectListPtr->GetNumLinks() > 0")
        }
        XCTAssertThrowsError(try SpritePlate.frameRects(alphaIndices: [0, 1], width: 3, height: 2)) {
            XCTAssertEqual($0 as? SpritePlateError, .indexCountMismatch(count: 2, width: 3, height: 2))
        }
    }

    func testBocrWorkedExample() throws {
        let g = try ShippedPlates.group("bocr")
        XCTAssertEqual(g.frames.map(\.rect), [MacRect(top: 3, left: 3, bottom: 19, right: 19),
                                              MacRect(top: 3, left: 22, bottom: 19, right: 37),
                                              MacRect(top: 7, left: 40, bottom: 19, right: 53)])
        XCTAssertEqual(g.frames.map(\.key), [0x0360, 0x0360, 0x0360])
        XCTAssertEqual(g.frames.map(\.blockSize), [1048, 984, 648])
        XCTAssertEqual(g.frames.map { $0.alphaMap != nil }, [true, true, true])
        let f0 = g.frames[0]
        XCTAssertEqual(Array(f0.pixels[0..<16]),
                       [UInt16](repeating: 0x0360, count: 8) + [UInt16](repeating: 0x0842, count: 4)
                       + [UInt16](repeating: 0x0360, count: 4))
        XCTAssertEqual(Array(try XCTUnwrap(f0.alphaMap)[0..<16]),
                       [UInt16](repeating: 32, count: 8) + [28, 30, 28, 30] + [UInt16](repeating: 32, count: 4))
        func emptyRows(_ f: SpriteFrame) -> [Int] {
            (0..<f.height).filter { f.alphaMap![$0 * f.width] == 1000 }
        }
        XCTAssertEqual(emptyRows(g.frames[0]), [])
        XCTAssertEqual(emptyRows(g.frames[1]), [15])
        XCTAssertEqual(emptyRows(g.frames[2]), [0, 6, 7])
    }

    func testGlowUsesEightBitScan() throws {
        let g = try ShippedPlates.group("glow")
        XCTAssertEqual(g.frames.count, 12)
        XCTAssertEqual(g.frames[3].rect, MacRect(top: 51, left: 279, bottom: 100, right: 328))
        // The RGB compare (bank plate_frames.py) would give (8,279,100,328): fill (8,0,255) and the body's
        // (0,0,255) are one system-CLUT index under the original's 8-bit scan, distinct in RGB.
        let alpha = try XCTUnwrap(try ShippedPlates.plates.get().first { $0.id.description == "GLOW" }).image
        XCTAssertEqual([alpha.width, alpha.height], [850, 102])
        let rgbKeyed = alpha.palette.map { UInt32($0.r) << 16 | UInt32($0.g) << 8 | UInt32($0.b) }
        var distinct: [UInt32: UInt8] = [:]
        for c in rgbKeyed where distinct[c] == nil { distinct[c] = UInt8(distinct.count) }
        let rgbRects = try SpritePlate.frameRects(alphaIndices: alpha.indices.map { distinct[rgbKeyed[Int($0)]]! },
                                                  width: alpha.width, height: alpha.height)
        XCTAssertEqual(rgbRects.count, 12)
        XCTAssertEqual(rgbRects[3], MacRect(top: 8, left: 279, bottom: 100, right: 328))
        XCTAssertEqual(zip(rgbRects, g.frames.map(\.rect)).filter { $0 != $1 }.count, 5)
    }

    func testAll125GroupsCensus() throws {
        let groups = try ShippedPlates.groups.get()
        XCTAssertEqual(groups.count, 125)
        let frames = groups.flatMap(\.frames)
        XCTAssertEqual(frames.count, 2554)
        XCTAssertEqual(frames.filter { $0.alphaMap != nil }.count, 2553)
        XCTAssertEqual(frames.reduce(0) { $0 + $1.width * $1.height }, 3_129_511)
        XCTAssertEqual(frames.reduce(0) { $0 + $1.blockSize }, 12_579_236)
        XCTAssertEqual(frames.map(\.width).max(), 218)
        XCTAssertEqual(frames.map(\.height).max(), 110)
        XCTAssertEqual(groups.filter { $0.id.description == "tesm" }.first?.frames.count, 91)
    }

    func testTesmFrame90IsInvisibleSpace() throws {
        let tesm = try ShippedPlates.group("tesm")
        XCTAssertEqual(tesm.frames.count, 91)
        let f = tesm.frames[90]
        XCTAssertEqual(f.rect, MacRect(top: 3, left: 846, bottom: 16, right: 850))
        XCTAssertEqual(f.width, 4)
        XCTAssertNil(f.alphaMap)
        XCTAssertEqual(f.blockSize, 0x18 + 2 * 4 * 13)
    }

    func testUpperCaseIdsAreAlphaPlates() throws {
        let plates = try ShippedPlates.plates.get()
        let colour = plates.filter { $0.name.hasSuffix(" IC") }, alpha = plates.filter { $0.name.hasSuffix(" IA") }
        XCTAssertEqual(colour.count, 125)
        XCTAssertEqual(alpha.count, 125)
        XCTAssertTrue(colour.allSatisfy { $0.id.description == $0.id.description.lowercased() })
        XCTAssertEqual(Set(colour.map { SpriteGroup.alphaPlateID(for: $0.id) }), Set(alpha.map(\.id)))
        let byID = Dictionary(uniqueKeysWithValues: plates.map { ($0.id, $0.image) })
        for c in colour {
            let a = try XCTUnwrap(byID[SpriteGroup.alphaPlateID(for: c.id)])
            XCTAssertEqual([c.image.width, c.image.height], [a.width, a.height], c.name)
        }
        // load(id:index:) pairs `bocr` with `BOCR`.
        let loaded = try SpriteGroup.load(id: FourCC("bocr")!, index: RealData.index())
        XCTAssertEqual(loaded.frames, try ShippedPlates.group("bocr").frames)
        XCTAssertThrowsError(try SpriteGroup.load(id: FourCC("zzzz")!, index: RealData.index())) {
            XCTAssertEqual($0 as? SpriteGroupError, .missingPlate(FourCC("zzzz")!))
        }
    }

    func testEncoderSyntheticRules() throws {
        // 0 fill blue · 1 grid magenta · 2 key green (0,222,0) · 3 white · 4 black · 5 grey 128 (r5 16) ·
        // 6 (255,100,0) (r5 31) · 7 (10,20,30).
        let pal: [(UInt8, UInt8, UInt8)] = [(0, 0, 255), (255, 0, 255), (0, 222, 0), (255, 255, 255),
                                            (0, 0, 0), (128, 128, 128), (255, 100, 0), (10, 20, 30)]
        // One strip (rows 2–5, row 5 the fill inset), cell A cols 0–3, grid col 4, cell B cols 5–7.
        let alphaRows = ["01222222", "11111111", "02401033", "06501033", "03301022", "00001000", "11111111"]
        let colourRows = ["01222222", "11111111", "07401077", "04701077", "07701077", "00001000", "11111111"]
        let g = try SpriteGroup(colour: plateGIF(colourRows, palette: pal), alpha: plateGIF(alphaRows, palette: pal),
                                id: FourCC("test")!)
        XCTAssertEqual(g.frames.map(\.rect), [MacRect(top: 2, left: 1, bottom: 5, right: 3),
                                              MacRect(top: 2, left: 6, bottom: 5, right: 8)])
        let c7 = QuickDrawColor.rgb555(10, 20, 30)
        let a = g.frames[0], b = g.frames[1]
        XCTAssertEqual([a.width, a.height, b.width, b.height], [2, 3, 2, 3])
        XCTAssertEqual(a.key, 0x0360)
        XCTAssertEqual(a.pixels, [c7, 0, 0, c7, c7, c7])
        // key → 0x20 · black → 0 · red 31 → 0x20 · grey → 16 · an all-invisible row → 1000 first.
        XCTAssertEqual(a.alphaMap, [0x20, 0, 0x20, 16, 1000, 0x20])
        XCTAssertEqual(a.blockSize, 0x18 + 12 + 12)
        // Cell B: white and key only → no visible pixel → no map.
        XCTAssertNil(b.alphaMap)
        XCTAssertEqual(b.pixels, [c7, c7, c7, c7, c7, c7])
        XCTAssertEqual(b.blockSize, 0x18 + 12)
    }

    func testFrameLimits() throws {
        // A 301-wide frame: plate 303 wide, one strip, one cell of 301 content columns.
        let w = 303
        let row0 = "01" + String(repeating: "2", count: w - 2)
        let grid = String(repeating: "1", count: w)
        let body = "0" + String(repeating: "4", count: w - 2) + "1"
        let pal: [(UInt8, UInt8, UInt8)] = [(0, 0, 255), (255, 0, 255), (0, 222, 0), (255, 255, 255), (0, 0, 0)]
        let p = plateGIF([row0, grid, body, grid], palette: pal)
        XCTAssertThrowsError(try SpriteGroup(colour: p, alpha: p, id: FourCC("wide")!)) {
            XCTAssertEqual($0 as? SpriteGroupError, .frameSize(frame: 0, width: 301, height: 1))
        }
        // 300 wide is the inclusive limit.
        let ok = plateGIF(["01" + String(repeating: "2", count: 300), String(repeating: "1", count: 302),
                           "0" + String(repeating: "4", count: 300) + "1"], palette: pal)
        XCTAssertEqual(try SpriteGroup(colour: ok, alpha: ok, id: FourCC("wide")!).frames.map(\.width), [300])
        // Unequal plates.
        let small = plateGIF(["012", "111", "041"], palette: pal)
        XCTAssertThrowsError(try SpriteGroup(colour: small, alpha: ok, id: FourCC("wide")!)) {
            XCTAssertEqual($0 as? SpriteGroupError,
                           .platesNotEqualSize(colourWidth: 3, colourHeight: 3, alphaWidth: 302, alphaHeight: 3))
        }
    }

    func testColourKeyHistogram() throws {
        var hist: [String: Int] = [:]
        for p in try ShippedPlates.plates.get() where p.name.hasSuffix(" IC") {
            let e = p.image.palette[Int(p.image.indices[2])]
            hist["\(e.r),\(e.g),\(e.b)", default: 0] += 1
        }
        XCTAssertEqual(hist, ["0,239,0": 85, "239,0,0": 24, "0,173,0": 4, "0,140,0": 2,
                              "0,255,156": 1, "0,222,0": 1, "49,156,206": 1, "255,8,8": 1, "255,255,0": 1,
                              "0,0,255": 1, "173,0,0": 1, "255,206,0": 1, "49,49,99": 1, "0,189,0": 1])
    }
}
