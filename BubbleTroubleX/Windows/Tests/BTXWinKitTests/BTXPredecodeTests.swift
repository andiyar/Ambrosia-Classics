import BTXWinKit
import Foundation
import HectorGraphics
import XCTest

/// `BTXPredecode` (plan W0.5, D16.1) against the real data: the BTX `Contents/Resources` folder named by
/// `HECTORKIT_DATA_BTX` (game data never enters git). Unset → XCTSkip naming the variable; set → every check runs.
final class BTXPredecodeTests: XCTestCase {
    static let variable = "HECTORKIT_DATA_BTX"

    private func resources() throws -> URL {
        guard let value = ProcessInfo.processInfo.environment[Self.variable], !value.isEmpty else {
            throw XCTSkip("\(Self.variable) unset — set it to Bubble Trouble X.app/Contents/Resources")
        }
        return URL(fileURLWithPath: value).resolvingSymlinksInPath()
    }

    private func scratch() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("btx-predecode-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    /// The census's eight QuickTime-JPEG PICTs (docs/bubble-trouble/data-census.md §4): the six level backgrounds
    /// 13000–13005 (3 bands each) and the David/Alex portraits 29401/29402 (1 band each) — 20 bands.
    func testFindsTheEightQuickTimePictures() throws {
        let pictures = try BTXPredecode.quickTimePictures(resourcesDirectory: resources())
        XCTAssertEqual(pictures.map(\.id), [13000, 13001, 13002, 13003, 13004, 13005, 29401, 29402])
        XCTAssertEqual(pictures.map(\.file), Array(repeating: "BT Levels.rsrc", count: 6)
                       + Array(repeating: "Bubble Trouble X.rsrc", count: 2))
        XCTAssertEqual(pictures.map(\.payloads.count), [3, 3, 3, 3, 3, 3, 1, 1])
    }

    /// The classifier, on synthetic streams (no data needed): a raster PICT is skipped; a picture that reaches a
    /// 0x8200 band the walk refuses (here truncated) fails loudly, naming the file and id.
    func testClassifierSkipsRasterAndFailsLoudlyOnABrokenQuickTimePicture() throws {
        // picSize, picFrame (0, 0, 10, 10), VersionOp v2, HeaderOp (24 bytes)
        let head: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 10, 0, 10, 0x00, 0x11, 0x02, 0xFF, 0x0C, 0x00]
            + [UInt8](repeating: 0, count: 24)
        let raster = Data(head + [0x00, 0x98] + [UInt8](repeating: 0, count: 8))   // PackBitsRect: a raster picture
        XCTAssertNil(try BTXPredecode.picture(file: "f", id: 128, data: raster))
        let noBands = Data(head + [0x00, 0xFF])                                    // ends with no band
        XCTAssertNil(try BTXPredecode.picture(file: "f", id: 129, data: noBands))
        let brokenBand = Data(head + [0x82, 0x00, 0x00, 0x00])                    // 0x8200, truncated record
        XCTAssertThrowsError(try BTXPredecode.picture(file: "BT Levels.rsrc", id: 13000, data: brokenBand)) { error in
            let text = String(describing: error)
            XCTAssertTrue(text.contains("BT Levels.rsrc") && text.contains("13000"), text)
        }
    }

    /// Every written file registers, and its bytes are exactly `CodecImage.decode` of the payload it is keyed by.
    func testWrittenFilesRegisterAndEqualTheDecode() throws {
        let data = try resources()
        let out = try scratch()
        let report = try BTXPredecode.run(resourcesDirectory: data, outputDirectory: out)
        XCTAssertEqual(report.map(\.id), [13000, 13001, 13002, 13003, 13004, 13005, 29401, 29402])
        XCTAssertEqual(report.reduce(0) { $0 + $1.keys.count }, 20)

        let payloads = try BTXPredecode.quickTimePictures(resourcesDirectory: data).flatMap(\.payloads)
        let keys = Set(payloads.map(CodecImage.precomputedKey))
        let files = try FileManager.default.contentsOfDirectory(atPath: out.path).filter { $0.hasSuffix(".rgba") }
        XCTAssertEqual(Set(files), Set(keys.map { "\($0).rgba" }))
        XCTAssertEqual(try CodecImage.registerPrecomputed(directory: out), keys.count)
        // The manifest lists every key in stream order — what the shipped build's start-up check reads.
        let manifest = try String(contentsOf: out.appendingPathComponent(BTXPredecode.manifestName), encoding: .utf8)
        XCTAssertEqual(manifest, report.flatMap(\.keys).map { "\($0)\n" }.joined())
        XCTAssertEqual(Set(manifest.split(separator: "\n").map(String.init)), keys)

        for payload in payloads {
            let decoded = try CodecImage.decode(payload)
            let file = try Data(contentsOf: out.appendingPathComponent("\(CodecImage.precomputedKey(payload)).rgba"))
            var expected = Data()
            for value in [UInt32(decoded.width), UInt32(decoded.height)] {
                withUnsafeBytes(of: value.littleEndian) { expected.append(contentsOf: $0) }
            }
            expected.append(decoded.rgba)
            XCTAssertEqual(file, expected, CodecImage.precomputedKey(payload))
        }
    }

    /// A second run over the same directory leaves exactly the same files (stale `.rgba` files are cleared; other
    /// files are left alone).
    func testRunIsIdempotent() throws {
        let data = try resources()
        let out = try scratch()
        try Data([1, 2, 3]).write(to: out.appendingPathComponent("stale.rgba"))
        try Data([4]).write(to: out.appendingPathComponent("keep.txt"))
        _ = try BTXPredecode.run(resourcesDirectory: data, outputDirectory: out)
        let first = try FileManager.default.contentsOfDirectory(atPath: out.path).sorted()
        _ = try BTXPredecode.run(resourcesDirectory: data, outputDirectory: out)
        let second = try FileManager.default.contentsOfDirectory(atPath: out.path).sorted()
        XCTAssertEqual(first, second)
        XCTAssertFalse(first.contains("stale.rgba"))
        XCTAssertTrue(first.contains("keep.txt"))
        XCTAssertTrue(first.contains(BTXPredecode.manifestName))
        XCTAssertEqual(first.filter { $0.hasSuffix(".rgba") }.count, 20)
    }
}
