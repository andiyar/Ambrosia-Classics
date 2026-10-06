import XCTest
import CryptoKit
import HectorResources
@testable import CytheraCore

/// C1 (docs/plans/2026-10-06-cythera-phase0.md): the data locator, the three resource files and the
/// data-then-app lookup, against the committed `Resources/Cythera` (D28). Every number is a planner probe
/// (p06 = INDEX "Resource census", p07; Research notes 10, 12). A missing data file is a FAILURE naming the
/// path, never a skip (plan S4).
final class CytheraDataTests: XCTestCase {

    private func resources() throws -> CytheraResources {
        try CytheraResources(directory: try CytheraData.dataDirectory())
    }

    private func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    func testDataDirectoryResolvesCommittedFolder() throws {
        let dir = try CytheraData.dataDirectory()
        XCTAssertEqual(dir.lastPathComponent, "Cythera")
        XCTAssertEqual(dir.deletingLastPathComponent().lastPathComponent, "Resources")
        for name in [CytheraData.appFile, CytheraData.dataResourceFile, CytheraData.documentationFile,
                     CytheraData.segmentFile] {
            let path = dir.appendingPathComponent(name).path
            XCTAssertTrue(FileManager.default.fileExists(atPath: path), "missing data: \(path)")
        }
        let r = try resources()
        XCTAssertEqual(r.segmentFileURL.lastPathComponent, "Cythera Data")
    }

    func testOverrideAndMissingFileNamed() throws {
        let real = try CytheraData.dataDirectory()
        let fm = FileManager.default
        let temp = fm.temporaryDirectory.appendingPathComponent("cythera-c1-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: temp) }
        // Everything except `Cythera Data.rsrc`, linked from the committed folder.
        for name in [CytheraData.appFile, CytheraData.documentationFile, CytheraData.segmentFile] {
            try fm.createSymbolicLink(at: temp.appendingPathComponent(name),
                                      withDestinationURL: real.appendingPathComponent(name))
        }

        let previous = ProcessInfo.processInfo.environment[CytheraData.environmentVariable]
        setenv(CytheraData.environmentVariable, temp.path, 1)
        defer {   // restore an outside override for the tests that run after this one
            if let previous { setenv(CytheraData.environmentVariable, previous, 1) }
            else { unsetenv(CytheraData.environmentVariable) }
        }
        let overridden = try CytheraData.dataDirectory()
        XCTAssertEqual(overridden.path, temp.resolvingSymlinksInPath().path)

        XCTAssertThrowsError(try CytheraResources(directory: overridden)) { error in
            XCTAssertEqual(error as? CytheraDataError, .notFound("Cythera Data.rsrc"))
        }
    }

    func testThreeResourceFilesCounts() throws {
        let r = try resources()
        let expected: [(String, ResourceCollection, Int, Int)] = [
            ("app", r.app, 339, 52),
            ("data", r.data, 113, 18),
            ("documentation", r.documentation, 268, 40),
        ]
        for (name, coll, resourceCount, typeCount) in expected {
            XCTAssertEqual(coll.count, resourceCount, "\(name) resources")
            XCTAssertEqual(coll.types().count, typeCount, "\(name) types")
        }
    }

    func testKeyResourceCounts() throws {
        let r = try resources()
        let app: [(String, Int)] = [
            ("PICT", 2), ("clut", 1), ("pltt", 1), ("Lite", 25), ("snd ", 13), ("DLOG", 17), ("DITL", 20),
            ("WIND", 10), ("CNTL", 8), ("ALRT", 5), ("MENU", 14), ("MBAR", 2), ("CMNU", 1), ("STR#", 16),
            ("STR ", 3), ("TxSt", 8), ("FOND", 1), ("Pref", 2), ("crsr", 57),
        ]
        for (type, n) in app { XCTAssertEqual(r.app.resources(of: type).count, n, "app \(type)") }
        let data: [(String, Int)] = [
            ("PICT", 19), ("clut", 1), ("FILT", 7), ("FOND", 2), ("NFNT", 2), ("sfnt", 1), ("STR#", 5),
            ("TxSt", 12), ("nrct", 1), ("PORT", 2), ("LINF", 3), ("MSta", 3), ("eBRS", 25), ("eSTM", 16),
            ("RMAP", 1), ("DATA", 10),
        ]
        for (type, n) in data { XCTAssertEqual(r.data.resources(of: type).count, n, "data \(type)") }
    }

    func testLookupOrderDataThenApp() throws {
        let r = try resources()
        // Two different `clut 256` (Research note 12): the data file's wins (app-shell.md §1.3).
        let dataClut = try XCTUnwrap(r.data.resource(type: "clut", id: 256), "data clut 256")
        let appClut = try XCTUnwrap(r.app.resource(type: "clut", id: 256), "app clut 256")
        XCTAssertTrue(sha256(dataClut.data).hasPrefix("e7fe2eef"), sha256(dataClut.data))
        XCTAssertTrue(sha256(appClut.data).hasPrefix("f3373625"), sha256(appClut.data))
        let found = try XCTUnwrap(r.resource(type: "clut", id: 256))
        XCTAssertEqual(found, dataClut)
        XCTAssertTrue(sha256(found.data).hasPrefix("e7fe2eef"))
        // `Lite 140` is only in the app: the lookup falls through (65 B).
        XCTAssertNil(r.data.resource(type: "Lite", id: 140))
        let lite = try XCTUnwrap(r.resource(type: "Lite", id: 140), "Lite 140")
        XCTAssertEqual(lite.data.count, 65)
        XCTAssertEqual(lite, r.app.resource(type: "Lite", id: 140))
    }
}
