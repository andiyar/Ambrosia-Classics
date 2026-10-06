import BTXWinKit
import BubbleTroubleCore
import Foundation
import XCTest

/// W7: the shipped build's start-up checks, message wording and log file.
final class WinStartupTests: XCTestCase {
    private func scratch() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("win-startup-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    func testMissingDataFolderNamesEverything() throws {
        let dir = try scratch().appendingPathComponent("Data", isDirectory: true)
        XCTAssertEqual(WinStartup.missingData(in: dir, needsDecoded: true),
                       BTXGameData.allFileNames + ["Fonts\\*.btxfont", "Decoded\\*.rgba"])
        XCTAssertEqual(WinStartup.missingData(in: dir, needsDecoded: false).count, 6)
    }

    func testCompleteDataFolderHasNothingMissing() throws {
        let dir = try scratch()
        let fm = FileManager.default
        for name in BTXGameData.allFileNames { fm.createFile(atPath: dir.appendingPathComponent(name).path, contents: nil) }
        for (sub, file) in [("Fonts", "Geneva-9.btxfont"), ("Decoded", "abc.rgba")] {
            let d = dir.appendingPathComponent(sub, isDirectory: true)
            try fm.createDirectory(at: d, withIntermediateDirectories: true)
            fm.createFile(atPath: d.appendingPathComponent(file).path, contents: nil)
        }
        XCTAssertEqual(WinStartup.missingData(in: dir, needsDecoded: true), [])
        try fm.removeItem(at: dir.appendingPathComponent("BT Sounds.rsrc"))
        XCTAssertEqual(WinStartup.missingData(in: dir, needsDecoded: true), ["BT Sounds.rsrc"])
    }

    func testMessagesSayWhatToDoAndWhereTheLogIs() {
        let data = URL(fileURLWithPath: "/x/Bubble Trouble X (Windows)/Data", isDirectory: true)
        let log = URL(fileURLWithPath: "/x/BubbleTroubleX.log")
        let m = WinStartup.dataMissingMessage(dataDirectory: data, missing: ["BT Sounds.rsrc"], logURL: log)
        XCTAssertTrue(m.contains("cannot find its game data"))
        XCTAssertTrue(m.contains(WinStartup.displayPath(data)))
        XCTAssertTrue(m.contains("Missing: BT Sounds.rsrc"))
        XCTAssertTrue(m.contains("Unzip"))
        XCTAssertTrue(m.contains(WinStartup.displayPath(log)))
        struct Boom: Error, CustomStringConvertible { var description: String { "SDL_CreateWindow failed: nope" } }
        let f = WinStartup.failureMessage("cannot open the window", error: Boom(), logURL: nil)
        XCTAssertEqual(f, "Bubble Trouble X could not start: cannot open the window.\n\nSDL_CreateWindow failed: nope")
    }

    func testLogTruncatesAtLaunchAndStampsLines() throws {
        let prefs = try scratch().appendingPathComponent("sub/Prefs.bin")
        let logURL = prefs.deletingLastPathComponent().appendingPathComponent("BubbleTroubleX.log")
        try FileManager.default.createDirectory(at: logURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("old session\n".utf8).write(to: logURL)
        let log = try XCTUnwrap(WinLog(besidePrefs: prefs))
        XCTAssertEqual(log.url, logURL)
        log.write("started")
        log.write("problem: é")
        let lines = try String(contentsOf: logURL, encoding: .utf8).split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines[0].hasSuffix(" started"))
        XCTAssertTrue(lines[1].hasSuffix(" problem: é"))
        XCTAssertNotNil(lines[0].range(of: #"^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d{3} "#, options: .regularExpression))
    }
}
