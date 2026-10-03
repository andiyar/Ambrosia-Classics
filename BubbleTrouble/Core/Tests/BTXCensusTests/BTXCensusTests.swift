@testable import btx_census
import Foundation
import HectorAudio
import HectorGraphics
import HectorResources
import XCTest

/// The Bubble Trouble X 1.1 `Contents/Resources` folder named by `HECTORKIT_DATA_BTX`. Game data never
/// enters git: XCTSkip — naming the variable — when it is unset or not a directory (HectorKit D3 / Aki/Core
/// convention).
private func btxResources() throws -> URL {
    let variable = "HECTORKIT_DATA_BTX"
    guard let value = ProcessInfo.processInfo.environment[variable], !value.isEmpty else {
        throw XCTSkip("\(variable) unset — set it to Bubble Trouble X.app/Contents/Resources")
    }
    let url = URL(fileURLWithPath: value).resolvingSymlinksInPath()
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
        throw XCTSkip("\(variable)=\(value) is not a directory")
    }
    return url
}

private func btxFile(_ name: String) throws -> ResourceCollection {
    let dir = try btxResources()                       // outside XCTUnwrap: an XCTSkip must stay a skip
    let collection = try ResourceReader.read(fileAt: dir.appendingPathComponent(name))
    return try XCTUnwrap(collection, name)
}

/// Census pins for `btx-census` (plan docs/plans/2026-10-03-hectorkit-btx-decoders.md Task 7).
/// Numbers: research notes 6 (cicn), 10 (ppat), 13 (PICT), 20–22 (snd), 24 (per-file counts = bank INDEX.md
/// "Resource census"). Every PICT goes through `PICT.decodeAny` (Task 4c); the masked ones (0x0099 regions,
/// 0x8201 mattes) decode via kit Tasks 4a/4b.
final class BTXCensusTests: XCTestCase {

    /// The seven exact summary lines of plan Task 7, in order (the Totals line is the last stdout line).
    static let summaryLines = [
        "# Bubble Trouble X 1.1 — data census",
        "files 5 · resources 1066 (BT Levels.rsrc 119 · BT Sounds.rsrc 53 · BT Sprites.rsrc 662 · BT Titles.rsrc 9 · Bubble Trouble X.rsrc 223)",
        "cicn 335 (331 + 4) · depth {1: 20, 2: 11, 4: 84, 8: 220} · opaque px 236,687 · RGB sum 64,978,590 · blank 7: 25004 25108 25208 25308 25408 25504 27308",
        "ppat 7 · 256×256 8-bit · device colour table 7 · RGB sum 89,901,763",
        "PICT 28 · raw 11 · quicktime 8 · region 4 (9001 9002 9012 9020) · matte 5 (2910 7000 9030 9031 9077)",
        "snd 52 · pcm8 48 · ima4 4 (stereo) · 22050 Hz 46 · 22254 Hz 5 · 11127 Hz 1",
        "Totals: cicn 335 (331 + 4), ppat 7, PICT 28 (raw 11 · quicktime 8 · region 4 · matte 5), snd 52 (pcm8 48 · ima4 4), failures 0",
    ]

    // MARK: - Per-file decoding through the kit directly

    /// Note 24 / INDEX.md "Resource census": Levels 119, Sounds 53, Sprites 662, Titles 9, app 223.
    func testFiveFilesOpen() throws {
        var counts: [String: Int] = [:]
        for name in BTXCensus.fileNames { counts[name] = try btxFile(name).count }
        XCTAssertEqual(counts, ["BT Levels.rsrc": 119, "BT Sounds.rsrc": 53, "BT Sprites.rsrc": 662,
                                "BT Titles.rsrc": 9, "Bubble Trouble X.rsrc": 223])
    }

    /// Notes 6 and 10: 331 + 4 cicn, 7 ppat — every one decodes.
    func testEveryCIconAndPixelPatternDecodes() throws {
        var cicn = 0, ppat = 0
        for name in BTXCensus.fileNames {
            let collection = try btxFile(name)
            for res in collection.resources(of: "cicn") {
                XCTAssertNoThrow(try CIcon(data: res.data), "\(name) cicn \(res.id)")
                cicn += 1
            }
            for res in collection.resources(of: "ppat") {
                XCTAssertNoThrow(try PixelPattern(data: res.data), "\(name) ppat \(res.id)")
                ppat += 1
            }
        }
        XCTAssertEqual([cicn, ppat], [335, 7])
    }

    /// Note 13: 28 PICTs, every one through `PICT.decodeAny` = raster 11 · quickTime 8 (0x8200) ·
    /// packBitsRegion 4 (0x0099) · quickTimeMatte 5 (0x8201); any throw fails the test.
    func testEveryPICTClassified() throws {
        var raw: [Int] = [], quickTime: [Int] = [], region: [Int] = [], matte: [Int] = []
        for name in BTXCensus.fileNames {
            for res in try btxFile(name).resources(of: "PICT") {
                let id = Int(res.id)
                switch try PICT.decodeAny(data: res.data).path {
                case .raster: raw.append(id)
                case .quickTime: quickTime.append(id)
                case .packBitsRegion: region.append(id)
                case .quickTimeMatte: matte.append(id)
                }
            }
        }
        XCTAssertEqual(raw.sorted(), [200, 900, 912, 913, 998, 999, 8001, 9010, 9011, 9099, 9100])
        XCTAssertEqual(quickTime.sorted(), [13000, 13001, 13002, 13003, 13004, 13005, 29401, 29402])
        XCTAssertEqual(region.sorted(), [9001, 9002, 9012, 9020])
        XCTAssertEqual(matte.sorted(), [2910, 7000, 9030, 9031, 9077])
    }

    /// Notes 20–22: 52 snd parse; 48 pcm8 (encode 0x00), 4 compressed (encode 0xFE, stereo 'ima4').
    func testEverySoundParses() throws {
        var pcm8 = 0, compressed = 0, total = 0
        for name in BTXCensus.fileNames {
            for res in try btxFile(name).resources(of: "snd ") {
                total += 1
                let sound = try XCTUnwrap(SndSound(data: res.data), "\(name) snd \(res.id)")
                switch sound.payload {
                case .pcm8: pcm8 += 1
                case let .compressed(codec, _, _):
                    compressed += 1
                    XCTAssertEqual(codec, "ima4", "snd \(res.id)")
                    XCTAssertEqual(sound.numChannels, 2, "snd \(res.id)")
                }
            }
        }
        XCTAssertEqual([total, pcm8, compressed], [52, 48, 4])
    }

    // MARK: - The tool's stdout

    func testSummaryLinesExact() throws {
        let census = BTXCensus.render(resourcesDirectory: try btxResources())
        XCTAssertEqual(census.failures, 0)
        XCTAssertFalse(census.stdout.contains("deferred"), "no PICT is a deferral after Task 4c")
        let lines = census.stdout.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        XCTAssertEqual(lines.last, "", "stdout ends with a newline")
        XCTAssertEqual(lines.dropLast().last, Self.summaryLines.last, "the Totals line is the last line")
        var searchFrom = 0
        for expected in Self.summaryLines {
            guard let index = lines[searchFrom...].firstIndex(of: expected) else {
                XCTFail("missing or out of order: \(expected)"); return
            }
            searchFrom = index + 1
        }
    }

    /// docs/bubble-trouble/data-census.md = a header, a `---` rule line, a blank line, then this stdout verbatim.
    func testStdoutEqualsCommittedCensus() throws {
        let census = BTXCensus.render(resourcesDirectory: try btxResources())
        var repo = URL(fileURLWithPath: #filePath)        // …/BubbleTrouble/Core/Tests/BTXCensusTests/<file>
        for _ in 0..<5 { repo.deleteLastPathComponent() }  // → the repo (or worktree) root
        let doc = try String(contentsOf: repo.appendingPathComponent("docs/bubble-trouble/data-census.md"),
                             encoding: .utf8)
        let rule = try XCTUnwrap(doc.range(of: "\n---\n\n"), "data-census.md has its rule")
        XCTAssertEqual(String(doc[rule.upperBound...]), census.stdout)
    }
}
