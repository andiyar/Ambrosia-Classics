import XCTest
import HectorResources
@testable import FerazelCore

/// C1 (docs/plans/2026-10-06-ferazel-phase1.md): the data locator, the six resource files, the music
/// folder and the two resource-search chains, against the committed `Resources/Ferazel` (D26).
/// Every number is a planner probe (p01 = INDEX resource census, p06, p08 = Research note 1).
/// A missing data file is a FAILURE naming the path, never a skip (plan invariant 5).
final class FerazelDataTests: XCTestCase {

    private func resources() throws -> FerazelResources {
        try FerazelData.open(try FerazelData.dataDirectory())
    }

    func testDataDirectoryResolvesCommittedFolder() throws {
        let dir = try FerazelData.dataDirectory()
        XCTAssertEqual(dir.lastPathComponent, "Ferazel")
        XCTAssertEqual(dir.deletingLastPathComponent().lastPathComponent, "Resources")
        for name in ["Ferazel's Wand.rsrc", "Ferazel's Wand World Data.rsrc", "Ferazel's Wand Backgrounds.rsrc",
                     "Ferazel's Wand Sprites.rsrc", "Ferazel's Wand Sounds.rsrc", "Ferazel's Wand Titles.rsrc",
                     "Ferazel's Wand Music"] {
            let path = dir.appendingPathComponent(name).path
            XCTAssertTrue(FileManager.default.fileExists(atPath: path), "missing data: \(path)")
        }
    }

    func testOverrideAndMissingFileNamed() throws {
        let real = try FerazelData.dataDirectory()
        let fm = FileManager.default
        let temp = fm.temporaryDirectory.appendingPathComponent("ferazel-c1-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: temp) }
        // Everything except Sounds, linked from the committed folder.
        for name in ["Ferazel's Wand.rsrc", "Ferazel's Wand World Data.rsrc", "Ferazel's Wand Backgrounds.rsrc",
                     "Ferazel's Wand Sprites.rsrc", "Ferazel's Wand Titles.rsrc", "Ferazel's Wand Music"] {
            try fm.createSymbolicLink(at: temp.appendingPathComponent(name),
                                      withDestinationURL: real.appendingPathComponent(name))
        }

        let previous = ProcessInfo.processInfo.environment[FerazelData.environmentVariable]
        setenv(FerazelData.environmentVariable, temp.path, 1)
        defer {   // restore an outside override for the tests that run after this one
            if let previous { setenv(FerazelData.environmentVariable, previous, 1) }
            else { unsetenv(FerazelData.environmentVariable) }
        }
        let overridden = try FerazelData.dataDirectory()
        XCTAssertEqual(overridden.path, temp.resolvingSymlinksInPath().path)

        XCTAssertThrowsError(try FerazelData.open(overridden)) { error in
            XCTAssertEqual(error as? FerazelDataError, .missing("Ferazel's Wand Sounds.rsrc"))
        }
    }

    func testSixResourceFilesCounts() throws {
        let r = try resources()
        let expected: [(String, ResourceCollection, Int, Int)] = [
            ("app", r.app, 164, 28),
            ("World Data", r.world, 60, 7),
            ("Backgrounds", r.backgrounds, 194, 7),
            ("Sprites", r.sprites, 587, 3),
            ("Sounds", r.sounds, 175, 3),
            ("Titles", r.titles, 86, 4),
        ]
        for (name, coll, resourceCount, typeCount) in expected {
            XCTAssertEqual(coll.count, resourceCount, "\(name) resources")
            XCTAssertEqual(coll.types().count, typeCount, "\(name) types")
        }
    }

    func testKeyTypeCounts() throws {
        let r = try resources()
        let files = [r.app, r.world, r.backgrounds, r.sprites, r.sounds, r.titles]
        XCTAssertEqual(files.map { $0.resources(of: "PICT").count }, [5, 1, 113, 584, 0, 67], "PICT app/world/bg/sprites/sounds/titles")
        XCTAssertEqual(files.map { $0.resources(of: "clut").count }, [6, 0, 57, 0, 0, 16], "clut app/world/bg/sprites/sounds/titles")
        // Pinned by probe: `snd ` lives only in Sounds; Mlvl/Mcnv/Mmap/Mwld only in World Data.
        XCTAssertEqual(files.map { $0.resources(of: "snd ").count }, [0, 0, 0, 0, 172, 0], "snd ")
        XCTAssertEqual(files.map { $0.resources(of: "Mlvl").count }, [0, 24, 0, 0, 0, 0], "Mlvl")
        XCTAssertEqual(files.map { $0.resources(of: "Mcnv").count }, [0, 29, 0, 0, 0, 0], "Mcnv")
        XCTAssertEqual(files.map { $0.resources(of: "Mmap").count }, [0, 1, 0, 0, 0, 0], "Mmap")
        XCTAssertEqual(files.map { $0.resources(of: "Mwld").count }, [0, 1, 0, 0, 0, 0], "Mwld")
        XCTAssertEqual(files.map { $0.resources(of: "STR#").count }, [2, 2, 0, 0, 0, 0], "STR# app + World")
    }

    func testMusicFolderTwentyEightTracks() throws {
        let r = try resources()
        // Research note 1 (p08): 01..30 minus 21 and 27, bytes.
        let expected: [(String, Int)] = [
            ("01", 1_935_726), ("02", 1_831_606), ("03", 1_650_862), ("04", 1_401_574), ("05", 2_059_814),
            ("06", 1_685_474), ("07", 1_684_318), ("08", 1_544_918), ("09", 3_299_070), ("10", 1_607_206),
            ("11", 1_503_166), ("12", 1_431_358), ("13", 2_089_326), ("14", 1_499_902), ("15", 1_206_142),
            ("16", 1_556_886), ("17", 1_469_438), ("18", 2_152_702), ("19", 1_535_410), ("20", 1_687_242),
            ("22", 1_800_882), ("23", 1_526_694), ("24", 2_202_342), ("25", 1_306_238), ("26", 1_575_654),
            ("28", 1_426_054), ("29", 1_310_726), ("30", 1_221_238),
        ]
        let fm = FileManager.default
        let dir = r.musicDirectory.resolvingSymlinksInPath()
        let names = try fm.contentsOfDirectory(atPath: dir.path).filter { !$0.hasPrefix(".") }.sorted()
        XCTAssertEqual(names, expected.map(\.0))
        for (name, bytes) in expected {
            let path = dir.appendingPathComponent(name).path
            let size = (try fm.attributesOfItem(atPath: path)[.size] as? NSNumber)?.intValue
            XCTAssertEqual(size, bytes, "music \(path)")
        }
        XCTAssertEqual(expected.map(\.1).reduce(0, +), 47_201_968)
    }

    func testResourceChainOrder() throws {
        let r = try resources()
        // PICT 7000: the app fork's copy in .frontEnd (save-continue §8.4, rendering §6.2); World Data holds
        // a different PICT 7000, which .level (World first) finds instead.
        let app7000 = try XCTUnwrap(r.app.resource(type: "PICT", id: 7000), "app PICT 7000")
        let world7000 = try XCTUnwrap(r.world.resource(type: "PICT", id: 7000), "World Data PICT 7000")
        XCTAssertNotEqual(app7000.data, world7000.data)
        XCTAssertEqual(r.resource(type: "PICT", id: 7000, chain: .frontEnd), app7000)
        XCTAssertEqual(r.resource(type: "PICT", id: 7000, chain: .level), world7000)
        // PICT 183 in .level resolves to Sprites.
        let sprites183 = try XCTUnwrap(r.sprites.resource(type: "PICT", id: 183), "Sprites PICT 183")
        XCTAssertEqual(r.resource(type: "PICT", id: 183, chain: .level), sprites183)
        // clut 200 is byte-identical in app and Backgrounds (p06).
        let appClut = try XCTUnwrap(r.app.resource(type: "clut", id: 200), "app clut 200")
        let bgClut = try XCTUnwrap(r.backgrounds.resource(type: "clut", id: 200), "Backgrounds clut 200")
        XCTAssertEqual(appClut.data, bgClut.data)
        XCTAssertEqual(r.resource(type: "clut", id: 200, chain: .level), bgClut)
        XCTAssertEqual(r.resource(type: "clut", id: 200, chain: .frontEnd), appClut)
    }
}
