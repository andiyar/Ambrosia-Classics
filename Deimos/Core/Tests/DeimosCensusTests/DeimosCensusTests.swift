import XCTest
import DeimosCore
@testable import deimos_census

/// The census run once over the committed data, shared by the suite.
private enum Census {
    static let shipped: Result<(stdout: String, failures: Int), Error> = Result {
        DeimosCensus.render(dataDirectory: try DeimosData.dataDirectory())
    }
    static func lines() throws -> [String] {
        try shipped.get().stdout.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    }
}

/// The built `deimos-census` binary next to this test bundle (SwiftPM puts both in the products dir).
private func censusBinary() throws -> URL {
    let bundle = try XCTUnwrap(Bundle.allBundles.first { $0.bundlePath.hasSuffix(".xctest") })
    let url = bundle.bundleURL.deletingLastPathComponent().appendingPathComponent("deimos-census")
    XCTAssertTrue(FileManager.default.isExecutableFile(atPath: url.path), "no deimos-census at \(url.path)")
    return url
}

private func runCensus(_ binary: URL, _ arguments: [String]) throws -> (status: Int32, stdout: String) {
    let p = Process()
    p.executableURL = binary
    p.arguments = arguments
    let out = Pipe()
    p.standardOutput = out
    p.standardError = Pipe()
    try p.run()
    let data = out.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return (p.terminationStatus, String(decoding: data, as: UTF8.self))
}

/// `deimos-census` (plan Task C7): the tool's stdout is `docs/deimos/data-census.md` below its rule.
final class DeimosCensusTests: XCTestCase {

    /// The nine summary lines (plan Task C7 "Exact summary lines") plus Task C8's `rsrc` line, each a whole
    /// stdout line, in this order, Totals last.
    static let summaryLines = [
        "# Deimos Rising 1.0.6 — data census",
        "files 5 · paks 4 (Audio.pak 96 · Game.pak 763 · Interface.pak 9 · Music.pak 3) · local 1 · CRC ok 871",
        "tags 872 · coli 1 · film 5 · flli 1 · idli 6 · im08 250 · im16 45 · leve 12 · plde 2 · reli 1 · soun 99 · "
            + "stli 5 · tefo 54 · unde 386 · wede 5 · overridden 0 · alerts 0",
        "im08 250 · sprite groups 125 · frames 2554 (alpha maps 2553) · pixels 3,129,511 · encoded bytes 12,579,236 · "
            + "max frame 218×110",
        "im16 45 · 480×3600 12 · 96×720 12 · 146×306 12 · 640×480 5 · other 4 · water px 117,194",
        "soun 99 · effects 96 mono ima4 44100 Hz (frames 3,133,376) · music 3 stereo ima4 "
            + "(packets 134,892 · 23,966 · 41,153)",
        "text 473 · stli 173 lines · flli 220 · idli 130 · reli 22 · coli 1 · tefo 54 · plde 2 · wede 5 (spawns 15) · "
            + "leve 12 (objects 565) · unde 386 (states 1,167) · token errors 0",
        "film 5 · version 10005 · de01 le07 4809 · de02 le06 8357 · de03 le02 10058 · de04 le08 5649 · last le07 4809",
        "rsrc 39 types · 140 resources · PICT 12 (decoded 12) · DITL 6 (decoded 6, items 76)",
        "Totals: entries 872 (pak 871 + local 1), decoded 872, failures 0",
    ]

    func testSummaryLinesExact() throws {
        let census = try Census.shipped.get()
        XCTAssertEqual(census.failures, 0)
        let lines = try Census.lines()
        var at = -1
        for expected in Self.summaryLines {
            guard let i = lines.indices.first(where: { $0 > at && lines[$0] == expected }) else {
                XCTFail("missing (or out of order): \(expected)"); return
            }
            at = i
        }
        XCTAssertEqual(lines.last { !$0.isEmpty }, Self.summaryLines.last)
        XCTAssertEqual(lines.first, Self.summaryLines.first)
    }

    func testEveryEntryHasOneLine() throws {
        let lines = try Census.lines()
        let start = try XCTUnwrap(lines.firstIndex { $0.hasPrefix("## 4. ") })
        let end = try XCTUnwrap(lines.indices.first { $0 > start && lines[$0].hasPrefix("## ") })
        let rows = lines[start..<end].filter { $0.hasPrefix("| ") }.dropFirst()     // header row
            .filter { !$0.hasPrefix("| ---") }
        XCTAssertEqual(rows.count, 872)
        XCTAssertEqual(rows.filter { $0.contains("FAIL") }, [])
        XCTAssertEqual(rows.filter { $0.hasPrefix("| Local ") }.count, 1)
        // Names only — never a machine path.
        XCTAssertFalse(try Census.shipped.get().stdout.contains("/Users/"))
    }

    func testStdoutEqualsCommittedCensus() throws {
        var root = URL(fileURLWithPath: #filePath).resolvingSymlinksInPath()
        for _ in 0..<5 { root.deleteLastPathComponent() }   // …/Deimos/Core/Tests/DeimosCensusTests/<file>
        let doc = try String(contentsOf: root.appendingPathComponent("docs/deimos/data-census.md"), encoding: .utf8)
        let rule = "\n---\n\n"
        let range = try XCTUnwrap(doc.range(of: rule), "data-census.md has no rule")
        let body = String(doc[range.upperBound...])
        let stdout = try Census.shipped.get().stdout
        XCTAssertTrue(body == stdout, "docs/deimos/data-census.md is stale: regenerate it from deimos-census")
    }

    func testExitCodes() throws {
        let binary = try censusBinary()
        XCTAssertEqual(try runCensus(binary, []).status, 2)
        XCTAssertEqual(try runCensus(binary, ["a", "b"]).status, 2)
        XCTAssertEqual(try runCensus(binary, ["/nonexistent", "--render"]).status, 2)
        XCTAssertEqual(try runCensus(binary, ["/nonexistent"]).status, 2)

        // An empty Data folder: no tags is a failed census, not an empty success.
        let empty = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("deimos-census-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: empty) }
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        XCTAssertEqual(try runCensus(binary, [empty.path]).status, 1)

        // A Data folder holding one corrupt GIF → exit 1, and the failure line names the entry.
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("deimos-census-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let im08 = dir.appendingPathComponent("Local/im08", isDirectory: true)
        try FileManager.default.createDirectory(at: im08, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dir.appendingPathComponent("Paks"), withIntermediateDirectories: true)
        try Data("GIF89a not really".utf8).write(to: im08.appendingPathComponent("Broken IC[brok].gif"))
        let result = try runCensus(binary, [dir.path])
        XCTAssertEqual(result.status, 1)
        let failLines = result.stdout.split(separator: "\n").filter { $0.contains("FAIL") }
        XCTAssertTrue(failLines.contains { $0.contains("Broken IC[brok].gif") }, "\(failLines)")
        XCTAssertFalse(result.stdout.contains(dir.path))
        XCTAssertTrue(result.stdout.hasSuffix("failures \(DeimosCensus.render(dataDirectory: dir).failures)\n"))
    }

    func testRenderWritesFivePNGs() throws {
        #if canImport(ImageIO)
        let out = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("deimos-render-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: out) }
        let written = try DeimosCensus.renderImages(dataDirectory: DeimosData.dataDirectory(), to: out)
        XCTAssertEqual(written, ["menu.png", "background.png", "canyon1-map.png", "bocr-frames.png", "tesm-plate.png"])
        func pngSize(_ name: String) throws -> [Int] {
            let b = [UInt8](try Data(contentsOf: out.appendingPathComponent(name)))
            XCTAssertEqual(Array(b.prefix(8)), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A], name)
            func u32(_ o: Int) -> Int { Int(b[o]) << 24 | Int(b[o + 1]) << 16 | Int(b[o + 2]) << 8 | Int(b[o + 3]) }
            return [u32(16), u32(20)]
        }
        XCTAssertEqual(try pngSize("menu.png"), [640, 480])
        XCTAssertEqual(try pngSize("background.png"), [640, 480])
        XCTAssertEqual(try pngSize("canyon1-map.png"), [480, 3600])
        XCTAssertEqual(try pngSize("tesm-plate.png").count, 2)
        XCTAssertEqual(try pngSize("bocr-frames.png").count, 2)
        #else
        throw XCTSkip("ImageIO unavailable (render is macOS-only)")
        #endif
    }
}
