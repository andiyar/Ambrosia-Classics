import XCTest
import HectorResources
@testable import FerazelCore

/// C3 (docs/plans/2026-10-06-ferazel-phase1.md): every `clut` in the app fork, Backgrounds and Titles, against the
/// committed `Resources/Ferazel` (D26). Contract: sprites-backgrounds §4, lighting-tables §1–§1.1, §1.4.
/// Every number is a planner probe (p06 = CLUT census, p02 = Mlvl headers). A missing data file is a FAILURE
/// naming the path, never a skip (plan invariant 5).
final class ColorLUTTests: XCTestCase {

    private func resources() throws -> FerazelResources {
        try FerazelData.open(try FerazelData.dataDirectory())
    }

    private func luts(_ coll: ResourceCollection) throws -> [ColorLUT] {
        try coll.resources(of: "clut").map { try ColorLUT(resource: $0) }.sorted { $0.id < $1.id }
    }

    func testSeventyNineCLUTsAll256Entries() throws {
        let r = try resources()
        let app = try luts(r.app), bg = try luts(r.backgrounds), titles = try luts(r.titles)
        XCTAssertEqual(app.map(\.id), [198, 199, 200, 700, 801, 4000], "app clut ids")
        XCTAssertEqual(bg.count, 57, "Backgrounds cluts")
        XCTAssertEqual(titles.map(\.id), [128, 130, 131, 132, 260, 281, 282, 283, 284, 285, 286, 287, 288, 289, 290, 729],
                       "Titles clut ids")
        XCTAssertEqual(app.count + bg.count + titles.count, 79)
        XCTAssertEqual(app.first?.name, "cooling map clut")
        XCTAssertEqual(bg.first { $0.id == 202 }?.name, "base + earthcav")
        for lut in app + bg + titles {
            XCTAssertEqual(lut.flags, 0, "clut \(lut.id) ctFlags")
            XCTAssertEqual(lut.entries.count, 256, "clut \(lut.id) entries")
            // .SetScreenClut rewrites every value field to its index; on shipped data that rewrite is a no-op.
            XCTAssertEqual(lut.entries.map(\.value), (0...255).map(UInt16.init), "clut \(lut.id) values")
            XCTAssertEqual(lut.storedValues, lut.entries.map(\.value), "clut \(lut.id) stored values")
        }
        // A non-zero ctFlags is outside the census and refused (plan invariant 6).
        var blob = Data(count: 8 + 256 * 8)
        blob[6] = 0x00; blob[7] = 0xff                                  // ctSize 255 → 256 entries
        XCTAssertNoThrow(try ColorLUT(id: 9, name: nil, data: blob))
        blob[4] = 0x80                                                  // ctFlags 0x8000 (device clut bit)
        XCTAssertThrowsError(try ColorLUT(id: 9, name: nil, data: blob)) { error in
            XCTAssertEqual(error as? ColorLUTError, .unexpectedFlags(id: 9, flags: 0x8000))
        }
    }

    func testDuplicateCLUTIdsIdentical() throws {
        let r = try resources()
        let appIds = Set(r.app.resources(of: "clut").map(\.id))
        let bgIds = Set(r.backgrounds.resources(of: "clut").map(\.id))
        XCTAssertEqual(appIds.intersection(bgIds).sorted(), [198, 199, 200, 700, 801, 4000])
        for id: Int16 in [198, 199, 200, 700, 801, 4000] {
            let a = try XCTUnwrap(r.app.resource(type: "clut", id: id), "app clut \(id)")
            let b = try XCTUnwrap(r.backgrounds.resource(type: "clut", id: id), "Backgrounds clut \(id)")
            XCTAssertEqual(a.data, b.data, "clut \(id) bytes")
            XCTAssertEqual(try ColorLUT(resource: a), try ColorLUT(resource: b), "clut \(id) parsed")
        }
    }

    func testPlusBaseCLUTsShareSpriteRange() throws {
        let r = try resources()
        let plusBase: [Int16] = [202, 204, 206, 208, 210, 212, 214, 216, 218, 220, 222, 224, 226, 228, 230, 232,
                                 236, 238, 240, 242, 244, 246, 248, 322]
        let bg = try luts(r.backgrounds)
        XCTAssertEqual(bg.filter { ($0.name ?? "").contains("+") }.map(\.id), plusBase, "'+' named Backgrounds cluts")
        let base = try ColorLUT.load(id: 200, from: r, chain: .level)
        for id in plusBase {
            let lut = try XCTUnwrap(bg.first { $0.id == id }, "Backgrounds clut \(id)")
            for i in 0..<0xa0 {
                XCTAssertEqual(lut.entries[i].rgb, base.entries[i].rgb, "clut \(id) entry \(i)")
            }
            XCTAssertEqual(lut.entries[0xff].rgb, base.entries[0xff].rgb, "clut \(id) entry 0xff")
            XCTAssertEqual(lut.entries[0xa0].rgb == base.entries[0xa0].rgb, id == 202, "clut \(id) entry 0xa0")
        }
    }

    func testSixteenLevelCLUTs() throws {
        let r = try resources()
        let levels = r.world.resources(of: "Mlvl")
        XCTAssertEqual(levels.count, 24)
        var ids = Set<Int16>()
        for res in levels {
            let level = try LevelFile(resource: res)
            ids.insert(ColorLUT.screenClutId(level.header))
        }
        XCTAssertEqual(ids.sorted(), [202, 210, 212, 214, 216, 218, 220, 222, 224, 228, 236, 238, 240, 242, 246, 248])
        for id in ids {
            let lut = try ColorLUT.load(id: id, from: r, chain: .level)
            XCTAssertNotNil(r.backgrounds.resource(type: "clut", id: id), "level clut \(id) in Backgrounds")
            XCTAssertEqual(lut.entries.count, 256, "level clut \(id)")
        }
    }
}
