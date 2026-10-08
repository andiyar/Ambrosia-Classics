import XCTest
import FerazelCore
@testable import FerazelRender

/// R2 (docs/plans/2026-10-06-ferazel-phase1.md): per-cell darkness and lights on tiles, on the committed level 1
/// (D26). Contract: plan R2 + lighting-tables §4, §7 and its "⚑ Phase-1 note (R2)" (the dump reading: darkness reaches
/// tiles inside `.RedrawScrollGrid` through `.LightAny*Tile` → `.WrapLightTile` → `.DrawLightOverTile`, skipped when
/// prefs Effects == 3; `.DrawLightsOntoTiles` redraws only op-marked cells). Planner numbers: p17 (light bytes of the
/// start window). A missing data file is a FAILURE, never a skip.
final class LightingTests: XCTestCase {

    /// R1's level-1 fixture (`.ruled`, `.errorDiffusion`), built once for the class.
    private static let shared = Result { try TileGridTests.Fixture() }

    private func fixture() throws -> TileGridTests.Fixture { try Self.shared.get() }

    /// R1's recorded hashes of the Effects = 3 tile layer at scroll (0, 10) (`TileGridTests.testTileFrameLevel1Start`).
    private static let r1Frame = "8e7a06f030d78d4a"
    private static let r1Mask = "e5437bb66513def6"

    // MARK: helpers

    private func renderer(_ f: TileGridTests.Fixture, level: LevelFile? = nil, effects: Int16) -> TileGridRenderer {
        let level = level ?? f.level
        return TileGridRenderer(level: level, sets: f.sets, fixed: f.fixed, tables: f.tables, clearFace: f.clearFace,
                                drawnH: 0, drawnV: 10, effects: effects)
    }

    /// The whole window at scroll (0, 10) (`.RedrawEntireScrollGrid`).
    private func startFrame(_ grid: TileGridRenderer) -> FramePorts {
        var ports = FramePorts()
        grid.redrawEntireScrollGrid(h: 0, v: 10, ports: &ports)
        return ports
    }

    private func fnv1a(_ bytes: [UInt8]) -> String {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for b in bytes { h = (h ^ UInt64(b)) &* 0x0000_0100_0000_01b3 }
        return String(h, radix: 16)
    }

    /// The copy-run pixels of a face, row-major `width × height` (a copied 0 counts).
    private func copied(_ face: EncodedFace) throws -> [Bool] {
        var out = [Bool](repeating: false, count: face.width * face.height)
        var row = -1, col = 0
        for token in try face.tokens() {
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

    /// Level 1 with header `0x2706` (darkness enable) rewritten to `value` in the `Mlvl` bytes.
    private func level1(darknessEnable value: Int16, _ f: TileGridTests.Fixture) throws -> LevelFile {
        let r = try XCTUnwrap(f.resources.world.resource(type: "Mlvl", id: 1))
        var data = r.data
        data[data.startIndex + 0x2706] = UInt8(UInt16(bitPattern: value) >> 8)
        data[data.startIndex + 0x2707] = UInt8(UInt16(bitPattern: value) & 0xff)
        return try LevelFile(id: 1, data: data)
    }

    // MARK: tests

    func testAmbientTilesLevel1Start() throws {
        let f = try fixture()
        let L = f.level
        XCTAssertEqual(L.header.darknessEnable, 5)
        // p17: the BG-map light bytes (cell high byte; D = byte − 1, `.GetLightTile @ 1003c2b4`) over the start
        // window cols 0..19 × rows 0..13.
        var histogram: [Int: Int] = [:]
        for row in 0...13 { for col in 0...19 { histogram[L.lightByte(col: col, row: row) + 1, default: 0] += 1 } }
        XCTAssertEqual(histogram, [1: 16, 2: 27, 3: 33, 4: 28, 5: 28, 6: 29, 7: 29, 8: 29, 9: 27, 10: 25, 11: 9])
        XCTAssertEqual(histogram.values.reduce(0, +), 280)

        // `.GetAmbDarkVal @ 1001aaf8`: the cell's D at any pixel of the cell (x >> 5, y >> 5).
        let grid = renderer(f, effects: 1)
        XCTAssertEqual(grid.lights.darkness(x: 5 * 32 + 31, y: 7 * 32), L.lightByte(col: 5, row: 7))

        // No lights at level start: the op grid is empty and `.DrawLightsOntoTiles` draws nothing.
        XCTAssertTrue(grid.lights.slots.allSatisfy { !$0.active })
        XCTAssertEqual(grid.lights.slots.count, 200)
        XCTAssertTrue(grid.lights.calcLightOps(h: 0, v: 10).isEmpty)
        let lit = startFrame(grid)
        var after = lit
        grid.drawLightsOntoTiles(h: 0, v: 10, ports: &after)
        XCTAssertEqual(after, lit)

        // The darkened frame: `.RedrawEntireScrollGrid` at (0, 10), Effects 1 (`.InitPrefs` on a modern Mac), no
        // lights, `.ruled` + `.errorDiffusion`, ambient table under CLUT 202. Self-derived by the R2 implementer,
        // 2026-10-09: FNV-1a 64 of the 640×416 frame port. The mask port is R1's (lights write only `0004`).
        XCTAssertEqual(lit.frame, lit.tiles)
        XCTAssertEqual(fnv1a(lit.frame), "97fa2462814fd12a")
        XCTAssertEqual(fnv1a(lit.mask), Self.r1Mask)

        // Independent per-pixel oracle against the R1 frame R, cell by cell (no overlay or water cell in the window):
        // the FG face's copy pixels are darkened last (`.LightAnyFGTile`, after the FG/blend/pattern draws), the BG
        // face's copy pixels when the BG was drawn (`.LightAnyBGTile`, before the FG draws) unless a later draw
        // replaced them (FG face, pattern tile); a blend pixel outside the FG face read a darkened screen pixel and
        // is not checked here. D = 0 leaves the cell alone.
        let r1 = startFrame(renderer(f, effects: 3))
        XCTAssertEqual(fnv1a(r1.frame), Self.r1Frame)
        var checked = 0, darkened = 0, skipped = 0
        for row in 0...12 {
            for col in 0...19 {
                let t = L.fgTile(col: col, row: row), b = L.bgTile(col: col, row: row)
                let D = L.lightByte(col: col, row: row)
                let R = cell(r1.frame, col: col, row: row), got = cell(lit.frame, col: col, row: row)
                let fgCopy = t >= 0 ? try copied(f.sets.fg.faces[t]) : nil
                let bgDrawn = b >= 0 && (t < 0 || (f.sets.fg.faces[t].hasTransparentPixel))
                let bgCopy = bgDrawn ? try copied(f.sets.bg.faces[b]) : nil
                let k = t >= 0 ? L.fgKind(tile: t) % 100 : -1
                let blendCopy = t >= 0 && t < 95 && k >= 0 && k < 95 ? try copied(f.fixed.blend.faces[k]) : nil
                let patternCopy = t == 95
                    ? try copied(f.sets.pattern.faces[TileGridRenderer.patternTile(col: col, row: row, periodSix: false)])
                    : nil
                for i in 0..<(32 * 32) {
                    let amb = { D == 0 ? R[i] : f.tables.ambient[D][Int(R[i])] }
                    let want: UInt8
                    if fgCopy?[i] == true {
                        want = amb()
                    } else if bgDrawn, blendCopy?[i] == true {
                        skipped += 1
                        continue
                    } else if patternCopy?[i] == true {
                        want = R[i]
                    } else if bgCopy?[i] == true {
                        want = amb()
                    } else {
                        want = R[i]
                    }
                    guard got[i] == want else {
                        return XCTFail("cell (\(col), \(row)) px \(i): \(got[i]) ≠ \(want) (D \(D))")
                    }
                    checked += 1
                    if got[i] != R[i] { darkened += 1 }
                }
            }
        }
        // Self-derived: pixels checked / changed by the darkening / blend pixels left unchecked, rows 0..12.
        XCTAssertEqual([checked, darkened, skipped], [266_240, 199_164, 0])
        XCTAssertEqual(checked + skipped, 260 * 1024)
    }

    func testAmbientEnableGate() throws {
        let f = try fixture()
        let off = try level1(darknessEnable: 0, f)
        XCTAssertEqual(off.header.darknessEnable, 0)
        XCTAssertEqual(off.bg, f.level.bg)
        let grid = renderer(f, level: off, effects: 1)
        // `.GetAmbDarkVal` returns 0 for every cell, so `.DrawLightOverTile` never darkens: the R1 tile layer.
        for row in 0...13 { for col in 0...19 { XCTAssertEqual(grid.lights.darkness(x: col * 32, y: row * 32), 0) } }
        let ports = startFrame(grid)
        XCTAssertEqual(fnv1a(ports.frame), Self.r1Frame)
        XCTAssertEqual(fnv1a(ports.mask), Self.r1Mask)
        // Any non-zero value enables (L1 = 5; 1 and 2 elsewhere): the same darkened frame as 5.
        XCTAssertEqual(startFrame(renderer(f, level: try level1(darknessEnable: 1, f), effects: 1)),
                       startFrame(renderer(f, effects: 1)))
    }

    func testEffectsReducedSkipsLights() throws {
        let f = try fixture()
        // The light faces: `.Load1LightFaceFromPICT @ 1002ff1c` = `.Load1PlainFaceFromPICT` under clut 801, at the
        // twelve call sites' (pict, w, h). Eleven draw their PICT unscaled; pixels are 0 (no light) or 0xf5..0xff.
        // The twelfth, `.InitBonusSprite`'s (806, 84, 84), has DrawPicture shrink the 192×192 picture — QuickDraw's
        // stretch is ROM code, not built: refused by name.
        XCTAssertEqual(LightFace.callSites.count, 12)
        let search = ColorSearch(model: .ruled)
        for site in LightFace.callSites {
            if site.pict == 806 {
                XCTAssertThrowsError(try LightFace.load(pict: 806, width: site.width, height: site.height,
                                                        from: f.resources, search: search)) {
                    XCTAssertEqual($0 as? LightFaceError,
                                   .scaled(pict: 806, frameWidth: 192, frameHeight: 192, width: 84, height: 84))
                }
                continue
            }
            let face = try LightFace.load(pict: site.pict, width: site.width, height: site.height, from: f.resources,
                                          search: search)
            XCTAssertEqual([face.width, face.height], [site.width, site.height])
            XCTAssertTrue(Set(face.pixels).isSubset(of: Set([0] + Array(0xf5...0xff))), "PICT \(site.pict)")
        }
        let face801 = try LightFace.load(pict: 801, width: 0xc0, height: 0xc0, from: f.resources, search: search)
        XCTAssertEqual(face801.rect, EncodedFace.Rect(top: 0, left: 0, bottom: 0xc0, right: 0xc0))
        // lighting-tables §7.4 (Python PICT decode): 12,206 px of 0xff, 9,551 of 0.
        XCTAssertEqual([face801.pixels.filter { $0 == 0xff }.count, face801.pixels.filter { $0 == 0 }.count],
                       [12_206, 9_551])

        // One new light (group 0, PICT 801, radius 96) centred at world (320, 200) in the start view.
        var slot = LightSlot()
        slot.active = true
        slot.isNew = true
        slot.face = face801
        slot.x = 320
        slot.y = 200
        slot.radius = 0x60
        slot.colour = 0

        // Effects 3 (prefs+6, "Reduced"): `.RedrawScrollGrid` skips every `.LightAny*Tile` call and `.PaintFrameWrap`
        // skips `.DrawLightsOntoTiles` (l. 9202) — the R1 tile layer even with a light and darkness present.
        var reduced = renderer(f, effects: 3)
        reduced.lights.slots[0] = slot
        var ports = startFrame(reduced)
        XCTAssertEqual(fnv1a(ports.frame), Self.r1Frame)
        XCTAssertEqual(fnv1a(ports.mask), Self.r1Mask)
        let before = ports
        reduced.drawLightsOntoTiles(h: 0, v: 10, ports: &ports)
        XCTAssertEqual(ports, before)

        // Effects 1: `.CalcLightOps` marks the cells the light's rect (top 104, left 224, bottom 296, right 416)
        // meets, both edges inclusive (cols 7...13, rows 3...9 = 49), and `.DrawLightOps` redraws exactly those.
        var enhanced = renderer(f, effects: 1)
        enhanced.lights.slots[0] = slot
        let ops = enhanced.lights.calcLightOps(h: 0, v: 10)
        XCTAssertEqual(Set(ops.map { [$0.col, $0.row] }),
                       Set((3...9).flatMap { r in (7...13).map { [$0, r] } }))
        XCTAssertTrue(ops.allSatisfy { $0.lights == [0] && $0.changed })
        // The light arrives after a frame drawn without it: `.DrawLightsOntoTiles` changes only op-marked cells.
        var lit = startFrame(renderer(f, effects: 1))
        let unlit = lit
        enhanced.drawLightsOntoTiles(h: 0, v: 10, ports: &lit)
        var changedCells = Set<[Int]>()
        for row in 0...12 {
            for col in 0...19 where cell(lit.frame, col: col, row: row) != cell(unlit.frame, col: col, row: row) {
                changedCells.insert([col, row])
            }
        }
        XCTAssertTrue(changedCells.isSubset(of: Set(ops.map { [$0.col, $0.row] })))
        XCTAssertEqual(changedCells.count, 36)   // self-derived: 13 of the 49 keep their pixels
        XCTAssertEqual(lit.frame, lit.tiles)
        // A grid redrawn with the light present (`.RedrawScrollGrid`'s per-cell `.DrawLightOverTile` sees every active
        // slot) agrees with the op path on this window (self-derived: 0 differing pixels).
        let whole = startFrame(enhanced)
        XCTAssertEqual(zip(whole.frame, lit.frame).filter { $0 != $1 }.count, 0)
        XCTAssertEqual(whole.mask, lit.mask)
    }

    func testWaterTable0Entry0xFFIsBlack() throws {
        let f = try fixture()
        // lighting-tables §4 (⚑ review 2c #1): every water loop is `ble 0xff`, so entry 0xff is written; clut 202
        // entry 0xff is 000000 and water 0 requests (R>>1, G>>1, min(2·lum, 0xffff)) = 000000 → 0x60, the lowest of
        // the duplicate blacks, under both models.
        let c202 = try ColorLUT.load(id: 202, from: f.resources, chain: .level)
        XCTAssertEqual(TableRequests.water(0, clut: c202)[0xff].request, RGB16(0, 0, 0))
        XCTAssertEqual(f.tables.water[0][0xff], 0x60)
        let exact = ColorSearch(model: .exactNearest).indices(of: [RGB16(0, 0, 0)], in: c202)
        XCTAssertEqual(exact, [0x60])
        // A black FG-water pixel stays black under water tint 0.
        XCTAssertEqual(f.tables.water[0][0x60], 0x60)
    }

    func testLightTablesCensusLine() throws {
        let f = try fixture()
        let exact = try LevelTables.forLevel(f.level.header, resources: f.resources,
                                             search: ColorSearch(model: .exactNearest), random: { _ in 0 })
        XCTAssertEqual(f.tables.screenClutId, 202)
        XCTAssertEqual(f.tables.light.count, 16 * 0x6e00)
        func differ(_ a: ArraySlice<UInt8>, _ b: ArraySlice<UInt8>) -> Int { zip(a, b).filter { $0 != $1 }.count }
        // Self-derived by the R2 implementer (planner did not measure the light groups): `.ruled` vs `.exactNearest`
        // disagreements in the light table `_DAT_100a0134` (16 D slabs × 110 (group, intensity) rows × 256), CLUT 202.
        let total = differ(f.tables.light[...], exact.light[...])
        let perGroup = (0..<10).map { g in
            (0..<16).map { D in
                let lo = D * 0x6e00 + g * 11 * 0x100
                return differ(f.tables.light[lo..<(lo + 11 * 0x100)], exact.light[lo..<(lo + 11 * 0x100)])
            }.reduce(0, +)
        }
        XCTAssertEqual(perGroup.reduce(0, +), total)
        XCTAssertEqual(total, 151_568)
        XCTAssertEqual(perGroup, [15_263, 24_496, 14_622, 13_360, 13_636, 12_207, 17_146, 10_988, 15_767, 14_083])
        // The ambient table's line is R1's (C4's CLUT-202 census): 1,887 of 4,096.
        XCTAssertEqual((0..<16).map { differ(f.tables.ambient[$0][...], exact.ambient[$0][...]) }.reduce(0, +), 1_887)
    }
}
