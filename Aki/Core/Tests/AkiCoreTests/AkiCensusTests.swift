import AVFoundation
import AkiCore
import Foundation
import HectorGraphics
import HectorResources
import XCTest

/// An Aki `Contents/Resources` folder for the data-gated census tests: env var `variable` if set,
/// else the repo's git-ignored symlink `Resources/Aki/<app>/Contents/Resources` (docs/DECISIONS.md
/// D1). XCTSkip — naming the variable — when neither exists.
private func akiResources(_ variable: String, defaultApp app: String) throws -> URL {
    var repo = URL(fileURLWithPath: #filePath)                 // …/Aki/Core/Tests/AkiCoreTests/<file>
    for _ in 0..<5 { repo.deleteLastPathComponent() }          // → the repo (or worktree) root
    let env = ProcessInfo.processInfo.environment[variable].flatMap { $0.isEmpty ? nil : $0 }
    let path = env ?? repo.appendingPathComponent("Resources/Aki/\(app)/Contents/Resources").path
    let url = URL(fileURLWithPath: path).resolvingSymlinksInPath()
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
        if let env { throw XCTSkip("\(variable)=\(env) is not a directory") }
        throw XCTSkip("\(variable) unset and the default \(path) is absent — set \(variable) to an Aki Contents/Resources folder")
    }
    return url
}

private func aki11() throws -> AkiBundle {
    try AkiBundle(resourcesURL: akiResources("AKI_DATA_11", defaultApp: "1.1.0.app"))
}
private func aki12() throws -> AkiBundle {
    try AkiBundle(resourcesURL: akiResources("AKI_DATA_12", defaultApp: "1.2.0.app"))
}

/// Phase 0 census pins (docs/aki/data-census.md is the human-readable twin, from `aki-census`).
final class AkiCensusTests: XCTestCase {

    // MARK: - AkiBundle (synthetic, always on)

    func testBundleListsResourceAudioAndPNGSortedByName() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("aki-bundle-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        for name in ["b.png", "a.png", "z.mp3", "Y.aiff", "game.rsrc", "notes.txt", "icon.icns"] {
            try Data([0]).write(to: dir.appendingPathComponent(name))
        }
        let bundle = try AkiBundle(resourcesURL: dir)
        XCTAssertEqual(bundle.resourceFile?.lastPathComponent, "game.rsrc")
        XCTAssertEqual(bundle.audioFiles.map(\.lastPathComponent), ["Y.aiff", "z.mp3"])
        XCTAssertEqual(bundle.pngFiles.map(\.lastPathComponent), ["a.png", "b.png"])
    }

    // MARK: - 1.1.0: 82 PICTs, all to their frames

    func testAki11EveryPICTDecodesToItsFrame() throws {
        let bundle = try aki11()
        let rsrc = try XCTUnwrap(bundle.resourceFile, "1.1.0 ships a .rsrc")
        XCTAssertEqual(rsrc.lastPathComponent, "Aki - Mahjong Solitaire.rsrc")
        let collection = try XCTUnwrap(try ResourceReader.read(fileAt: rsrc))
        let picts = collection.resources(of: "PICT")
        XCTAssertEqual(picts.count, 82)
        var raw = 0, quickTime = 0
        for res in picts {
            let b = [UInt8](res.data)
            func i16(_ o: Int) -> Int { Int(Int16(bitPattern: UInt16(b[o]) << 8 | UInt16(b[o + 1]))) }
            let frame = [i16(8) - i16(4), i16(6) - i16(2)]          // right−left, bottom−top
            let pict: PICT
            do {
                pict = try PICT(data: res.data); raw += 1
            } catch PICT.DecodeError.unsupportedOpcode(let op) where op == 0x8200 {
                pict = try PICT.decodeQuickTime(data: res.data); quickTime += 1
            }
            XCTAssertEqual([pict.width, pict.height], frame, "PICT \(res.id)")
            XCTAssertEqual(pict.rgba.count, frame[0] * frame[1] * 4, "PICT \(res.id)")
        }
        XCTAssertEqual([raw, quickTime], [11, 71])
    }

    /// The composite is not just the right SIZE: 1.2.0 re-shipped the same art as PNG, and each
    /// decoded 1.1.0 QuickTime composite sits within a mean |ΔRGB| of 6 (0–255) of its 1.2.0 twin —
    /// measured 2026-10-03: 140 1.77 (this ImageIO path; 1.78 with PIL), 130 2.53, 132 4.98, 164 3.02,
    /// 315 0.04; swapping two bands of 140 costs 30.0, of 130 10.5.
    func testAki11QuickTimeCompositesMatchTheirAki12PNGs() throws {
        // Un-nested on purpose: XCTUnwrap records an error thrown inside its autoclosure (an XCTSkip
        // from the locator) as a FAILURE before rethrowing — call the skipping locator outside it.
        let bundle = try aki11()
        let rsrc = try XCTUnwrap(bundle.resourceFile, "1.1.0 ships a .rsrc")
        let collection = try XCTUnwrap(try ResourceReader.read(fileAt: rsrc))
        let pngDir = try akiResources("AKI_DATA_12", defaultApp: "1.2.0.app")
        let twins: [(id: Int16, png: String)] = [(140, "background7.png"), (130, "proverbs.png"),
                                                 (132, "previews.png"), (164, "map.png"), (315, "paper.png")]
        for twin in twins {
            let res = try XCTUnwrap(collection.resource(type: "PICT", id: twin.id), "PICT \(twin.id)")
            let pict = try PICT.decodeQuickTime(data: res.data)
            let png = try CodecImage.decode(Data(contentsOf: pngDir.appendingPathComponent(twin.png)))
            XCTAssertEqual([png.width, png.height], [pict.width, pict.height], twin.png)
            let a = [UInt8](pict.rgba), b = [UInt8](png.rgba)
            var sum = 0
            for i in stride(from: 0, to: a.count, by: 4) {
                sum += abs(Int(a[i]) - Int(b[i])) + abs(Int(a[i + 1]) - Int(b[i + 1])) + abs(Int(a[i + 2]) - Int(b[i + 2]))
            }
            let meanDiff = Double(sum) / Double(a.count / 4 * 3)
            XCTAssertLessThan(meanDiff, 6.0, "PICT \(twin.id) vs \(twin.png)")
        }
    }

    // MARK: - 1.2.0: 50 PNGs, all to their sizes

    func testAki12EveryPNGDecodesToItsSize() throws {
        let bundle = try aki12()
        XCTAssertNil(bundle.resourceFile, "1.2.0 ships no .rsrc")
        var expected: [String: [Int]] = [
            "arrow.png": [132, 144], "buyaki.png": [800, 600], "guide.png": [440, 503],
            "layer_buttons.png": [224, 260], "map.png": [800, 600], "misc.png": [467, 468],
            "nopairs.png": [416, 480], "notavail.png": [240, 150], "paper.png": [420, 338],
            "pause.png": [416, 480], "plate.png": [2358, 68], "previews.png": [237, 2172],
            "proverbs.png": [392, 1727], "tile_pictures.png": [39, 2100], "tiles.png": [53, 1104],
            "welcome.png": [523, 338],
        ]
        for n in 1...17 {
            expected["background\(n).png"] = [800, 600]
            expected["preview\(n).png"] = [237, 181]
        }
        XCTAssertEqual(expected.count, 50)
        var decoded: [String: [Int]] = [:]
        for url in bundle.pngFiles {
            let image = try CodecImage.decode(Data(contentsOf: url))
            XCTAssertEqual(image.rgba.count, image.width * image.height * 4, url.lastPathComponent)
            decoded[url.lastPathComponent] = [image.width, image.height]
        }
        XCTAssertEqual(decoded, expected)
    }

    // MARK: - Audio: every shipped AIFF/MP3 opens (44.1 kHz; channel count per file per afinfo)

    private func assertAudioOpens(_ bundle: AkiBundle, channels expected: [String: Int],
                                  file: StaticString = #filePath, line: UInt = #line) throws {
        var seen: [String: Int] = [:]
        for url in bundle.audioFiles {
            let audio = try AVAudioFile(forReading: url)
            XCTAssertEqual(audio.fileFormat.sampleRate, 44_100, url.lastPathComponent, file: file, line: line)
            XCTAssertGreaterThan(audio.length, 0, url.lastPathComponent, file: file, line: line)
            seen[url.lastPathComponent] = Int(audio.fileFormat.channelCount)
        }
        XCTAssertEqual(seen, expected, file: file, line: line)
    }

    func testAki11AudioFilesOpen() throws {
        try assertAudioOpens(aki11(), channels: [
            "Aki Theme 1.mp3": 2, "Aki Theme 2.mp3": 2, "Aki Theme 3.mp3": 2, "GameOver.aiff": 2,
            "LevelComplete.aiff": 2, "LevelStart.aiff": 2, "Preview.aiff": 1, "Reshuffle.aiff": 2,
            "TileMatch.aiff": 1, "cancel.aiff": 1, "chime.aiff": 1, "tick.mp3": 1,
            "tilehit.aiff": 2, "unclick.aiff": 2,
        ])
    }

    func testAki12AudioFilesOpen() throws {
        try assertAudioOpens(aki12(), channels: [
            "Aki Theme 1.mp3": 2, "Aki Theme 2.mp3": 2, "Aki Theme 3.mp3": 2, "GameOver.aiff": 2,
            "LevelComplete.aiff": 2, "LevelStart.aiff": 2, "Preview.aiff": 1, "Reshuffle.aiff": 2,
            "TileMatch.aiff": 1, "cancel.aiff": 1, "chime.aiff": 1, "tick.aiff": 1, "tick.mp3": 1,
            "tilehit.mp3": 2, "unclick.aiff": 2,
        ])
    }
}
