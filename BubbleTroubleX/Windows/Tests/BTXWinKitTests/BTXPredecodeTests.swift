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
        XCTAssertEqual(first.filter { $0.hasSuffix(".rgba") }.count, 20)
    }
}
