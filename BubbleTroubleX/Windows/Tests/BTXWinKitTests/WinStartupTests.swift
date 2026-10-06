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
        let fonts = ["Geneva-9", "Geneva-10", "System-12", "System-Bold-12"].map { "Fonts\\\($0).btxfont" }
        XCTAssertEqual(WinStartup.missingData(in: dir, needsDecoded: true),
                       BTXGameData.allFileNames + fonts + ["Decoded\\manifest.txt"])
        XCTAssertEqual(WinStartup.missingData(in: dir, needsDecoded: false).count, 9)
    }

    func testCompleteDataFolderHasNothingMissing() throws {
        let dir = try scratch()
        let fm = FileManager.default
        for name in BTXGameData.allFileNames { fm.createFile(atPath: dir.appendingPathComponent(name).path, contents: nil) }
        let keys = (1...20).map { "\($0)-\(String(repeating: "a", count: 16))" }
        let fonts = dir.appendingPathComponent("Fonts", isDirectory: true)
        let decoded = dir.appendingPathComponent("Decoded", isDirectory: true)
        for d in [fonts, decoded] { try fm.createDirectory(at: d, withIntermediateDirectories: true) }
        for f in WinStartup.requiredFonts { fm.createFile(atPath: fonts.appendingPathComponent(f).path, contents: nil) }
        for k in keys { fm.createFile(atPath: decoded.appendingPathComponent("\(k).rgba").path, contents: nil) }
        try Data(keys.map { "\($0)\n" }.joined().utf8).write(to: decoded.appendingPathComponent("manifest.txt"))
        XCTAssertEqual(WinStartup.missingData(in: dir, needsDecoded: true), [])
        try fm.removeItem(at: dir.appendingPathComponent("BT Sounds.rsrc"))
        try fm.removeItem(at: fonts.appendingPathComponent("Geneva-10.btxfont"))
        try fm.removeItem(at: decoded.appendingPathComponent("\(keys[3]).rgba"))
        XCTAssertEqual(WinStartup.missingData(in: dir, needsDecoded: true),
                       ["BT Sounds.rsrc", "Fonts\\Geneva-10.btxfont", "Decoded\\\(keys[3]).rgba"])
        XCTAssertEqual(WinStartup.missingData(in: dir, needsDecoded: false), ["BT Sounds.rsrc", "Fonts\\Geneva-10.btxfont"])
        for k in keys.prefix(6) { try? fm.removeItem(at: decoded.appendingPathComponent("\(k).rgba")) }
        XCTAssertEqual(WinStartup.missingData(in: dir, needsDecoded: true).last, "Decoded\\*.rgba (6 of 20)")
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
