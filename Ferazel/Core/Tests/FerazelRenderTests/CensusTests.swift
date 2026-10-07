import XCTest
import FerazelCore
import HectorResources
@testable import FerazelRender

/// The census run once over the committed data, shared by the suite.
private enum Census {
    static let shipped: Result<(stdout: String, failures: Int), Error> = Result {
        FerazelCensus.render(dataDirectory: try FerazelData.dataDirectory())
    }
    static func lines() throws -> [String] {
        try shipped.get().stdout.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    }
}

/// The built `ferazel-census` binary next to this test bundle (SwiftPM puts both in the products dir; the test
/// target depends on the executable so it is built first).
private func censusBinary() throws -> URL {
    let bundle = try XCTUnwrap(Bundle.allBundles.first { $0.bundlePath.hasSuffix(".xctest") })
    let url = bundle.bundleURL.deletingLastPathComponent().appendingPathComponent("ferazel-census")
    XCTAssertTrue(FileManager.default.isExecutableFile(atPath: url.path), "no ferazel-census at \(url.path)")
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

/// C6 (docs/plans/2026-10-06-ferazel-phase1.md): `ferazel-census` — stdout is `docs/ferazel/data-census.md` below
/// its rule; every resource the game reads decodes; the Color2Index measurement (DECISIONS D26). Every number is a
/// planner probe (p01–p21) except the two Ben ruled on 2026-10-07 (follow the binary; D26 C4 and C5 as built):
/// the 16-CLUT total 1,178,146 (the water-1 overflow) and FG 200 under the level CLUT 201 (44/239, 5,400 px).
final class CensusTests: XCTestCase {

    static let summaryLines = [
        "# Ferazel's Wand 1.0.3 — data census",
        "files 34 · resource files 6 · music 28 of 30 (21, 27 absent) · bytes 85,281,911",
        "resources app 164/28 · World Data 60/7 · Backgrounds 194/7 · Sprites 587/3 · Sounds 175/3 · Titles 86/4",
        "PICT 770 · v2 765 (indexed 8-bit 427 · 4-bit 11 · 2-bit 1 · direct 32-bit 326 mode 64) · v1 1-bit 5 · failures 0",
        "clut 79 · app 6 · Backgrounds 57 · Titles 16 · 256 entries each · duplicate ids identical 6 · + base 24 "
            + "(0x00..0x9f = clut 200)",
        "snd 172 · format 1 · 22050 Hz 138 · 11025 Hz 33 · 22254.545 Hz 1 · samples 2,432,217",
        "music 28 · AIFC ima4 stereo 22050 Hz · packets 694,051 · frames 44,419,264",
        "Mlvl 24 · active records 5,641 · placed types 243 · flag-0 typed 48 · flag 99 1 · unmapped types 0",
        "classes Bonus 2895 · Background 1274 · Box 759 · Platform 169 · Walker 158 · Bat 89 · Gremlin 50 · Rope 49 · "
            + "Frog 41 · Crawler 31 · Blob 29 · Button 24 · Salamander 22 · Dillo 20 · Roach 16 · Floater 7 · Crab 3 · "
            + "Chief 1 · Demon 1 · Warrior 1 · Wizard 1 · Xichra 1",
        "world Mwld Teraknorn 0x152be0ed · Mmap nodes 24 · Mcnv 29 (lines 580, text 198, portrait 183) · "
            + "STR# 1000 99 · STR# 500 19",
        "color2index CLUT 202 ruled vs exact: tint 1168/3603 · water 397/1280 · redden 1885/6144 · ambient 1887/4096 · "
            + "pairs 70124/196608 · total 75461/211731",
        // Ben 2026-10-07, follow the binary (water 1's 32-bit overflow; D26 C4 as built): the plan's 1,178,143 → 1,178,146.
        "color2index 16 level CLUTs: 1,178,146 of 3,387,696 requests differ",
        // FG 200 converts under the level CLUT 201, not 202 (D26 C5 as built): the plan's 62/239 7,193 px → 44/239 5,400 px.
        "faces level 1 ruled vs exact: FG 200 44/239 colours 5,400 px · BG 203 67/234 13,898 px · "
            + "pattern 206 73/200 8,606 px · PxBack 207 0/52 · walk 1020 5/51 1,333 px",
        "short sheet PICT 257 768×708 (cells 30..35, 60 rows)",
        "Totals: items 1,108 decoded, failures 0",
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
        XCTAssertEqual(lines.first, Self.summaryLines.first)
        XCTAssertEqual(lines.last { !$0.isEmpty }, Self.summaryLines.last)
    }

    func testStdoutEqualsCommittedCensus() throws {
        var root = URL(fileURLWithPath: #filePath).resolvingSymlinksInPath()
        for _ in 0..<5 { root.deleteLastPathComponent() }   // …/Ferazel/Core/Tests/FerazelRenderTests/<file>
        let doc = try String(contentsOf: root.appendingPathComponent("docs/ferazel/data-census.md"), encoding: .utf8)
        let rule = "\n---\n\n"
        let range = try XCTUnwrap(doc.range(of: rule), "data-census.md has no rule")
        let body = String(doc[range.upperBound...])
        let stdout = try Census.shipped.get().stdout
        XCTAssertTrue(body == stdout, "docs/ferazel/data-census.md is stale: regenerate it from ferazel-census")
    }

    func testExitCodes() throws {
        // The argument parser the executable uses.
        XCTAssertNil(FerazelCensus.Arguments(parsing: []))
        XCTAssertNil(FerazelCensus.Arguments(parsing: ["a", "b"]))
        XCTAssertNil(FerazelCensus.Arguments(parsing: ["a", "--render"]))
        XCTAssertNil(FerazelCensus.Arguments(parsing: ["a", "--rendr", "b"]))
        XCTAssertEqual(FerazelCensus.Arguments(parsing: ["a"]), FerazelCensus.Arguments(dataDirectory: "a", renderDirectory: nil))
        XCTAssertEqual(FerazelCensus.Arguments(parsing: ["a", "--render", "b"]),
                       FerazelCensus.Arguments(dataDirectory: "a", renderDirectory: "b"))

        // The binary: bad arguments → 2.
        let binary = try censusBinary()
        XCTAssertEqual(try runCensus(binary, []).status, 2)
        XCTAssertEqual(try runCensus(binary, ["a", "b"]).status, 2)
        XCTAssertEqual(try runCensus(binary, ["/nonexistent", "--render"]).status, 2)
        XCTAssertEqual(try runCensus(binary, ["/nonexistent"]).status, 2)

        // A data folder whose Titles file holds one truncated PICT (the other five files empty resource maps, the
        // music folder empty) → exit 1, and the failing item line names that PICT; never a machine path.
        let fm = FileManager.default
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ferazel-census-\(UUID().uuidString)")
        defer { try? fm.removeItem(at: dir) }
        try fm.createDirectory(at: dir.appendingPathComponent(FerazelData.musicFolder), withIntermediateDirectories: true)
        let shipped = try FerazelData.open(try FerazelData.dataDirectory())
        let whole = try XCTUnwrap(shipped.titles.resource(type: "PICT", id: 129), "Titles PICT 129")
        let truncated = Resource(type: "PICT", id: 129, name: whole.name, data: whole.data.prefix(200))
        for name in [FerazelData.appFile, FerazelData.worldFile, FerazelData.backgroundsFile, FerazelData.spritesFile,
                     FerazelData.soundsFile] {
            try ClassicResourceMap.serialize([]).write(to: dir.appendingPathComponent(name))
        }
        try ClassicResourceMap.serialize([truncated]).write(to: dir.appendingPathComponent(FerazelData.titlesFile))
        let result = try runCensus(binary, [dir.path])
        XCTAssertEqual(result.status, 1)
        let failLines = result.stdout.split(separator: "\n").filter { $0.contains("FAIL") }
        XCTAssertTrue(failLines.contains { $0.hasPrefix("| PICT | Titles | 129 |") }, "\(failLines)")
        XCTAssertFalse(result.stdout.contains(dir.path))
        let direct = FerazelCensus.render(dataDirectory: dir)
        XCTAssertGreaterThan(direct.failures, 0)
        XCTAssertEqual(direct.stdout, result.stdout)
        XCTAssertTrue(result.stdout.hasSuffix("failures \(direct.failures)\n"))
    }

    func testOneLinePerItem() throws {
        let lines = try Census.lines()
        let start = try XCTUnwrap(lines.firstIndex { $0.hasPrefix("## 3. ") })
        let end = try XCTUnwrap(lines.indices.first { $0 > start && lines[$0].hasPrefix("## ") })
        let rows = lines[start..<end].filter { $0.hasPrefix("| ") && !$0.hasPrefix("| type |") && !$0.hasPrefix("| ---") }
        XCTAssertEqual(rows.count, 1_108)
        XCTAssertEqual(rows.filter { !$0.hasSuffix("| ok |") }, [])
        var kinds: [String: Int] = [:]
        for row in rows { kinds[String(row.dropFirst(2).prefix { $0 != " " }), default: 0] += 1 }
        XCTAssertEqual(kinds, ["PICT": 770, "clut": 79, "snd": 172, "Mlvl": 24, "Mcnv": 29, "music": 28, "Mwld": 1,
                               "Mmap": 1, "STR#": 4])
        // Names only — never a machine path.
        XCTAssertFalse(try Census.shipped.get().stdout.contains("/Users/"))
        XCTAssertFalse(try Census.shipped.get().stdout.contains(try FerazelData.dataDirectory().path))
    }
}
