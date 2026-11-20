import XCTest
@testable import DeimosHost
@testable import DeimosCore

/// The settings store on disk (Phase 4 S4 PF; grounding C §1b): given a folder, the file "Deimos Rising Preferences"
/// in it; a missing or wrong-version file gives the fresh record, written at once (`FUN_10004540`).
final class PrefsStoreTests: XCTestCase {
    private var folder: URL!

    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("PrefsStoreTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: folder)
    }

    private var fileURL: URL { folder.appendingPathComponent("Deimos Rising Preferences") }
    private func onDisk() throws -> [UInt8] { [UInt8](try Data(contentsOf: fileURL)) }
    private func putOnDisk(_ bytes: [UInt8]) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data(bytes).write(to: fileURL)
    }

    func testStoreWritesFreshAtOnce() throws {
        // Missing file (and a folder not yet made): the fresh record, on disk before load returns.
        let nested = folder.appendingPathComponent("Ambrosia Classics/Deimos Rising", isDirectory: true)
        let store = PrefsStore(folder: nested)
        XCTAssertEqual(try store.load(), DeimosPrefs.fresh)
        let written = [UInt8](try Data(contentsOf: nested.appendingPathComponent("Deimos Rising Preferences")))
        XCTAssertEqual(written.count, 0x34f0)
        XCTAssertEqual(Array(written[0..<4]), [0x00, 0x00, 0x27, 0x14])
        XCTAssertEqual(Array(written[0x10f8..<0x10fd]), [0x2B, 0xE9, 0xD8, 0xC8, 0x00])   // "Mars" scrambled
        XCTAssertEqual(written, PrefsFile.fresh.fileBytes)

        // Wrong version: overwritten with the fresh record at once (a corrupt file is replaced at boot).
        var wrong = [UInt8](repeating: 0x55, count: 0x34f0)
        wrong[0] = 0; wrong[1] = 0; wrong[2] = 0x27; wrong[3] = 0x13
        try putOnDisk(wrong)
        XCTAssertEqual(try PrefsStore(folder: folder).load(), DeimosPrefs.fresh)
        XCTAssertEqual(try onDisk(), PrefsFile.fresh.fileBytes)

        // A short file with the right version is accepted and NOT rewritten (only quit writes).
        let short = Array(PrefsFile.fresh.fileBytes[0..<0x1260])
        try putOnDisk(short)
        let loaded = try PrefsStore(folder: folder).load()
        XCTAssertEqual(loaded.highScoreNames, DeimosPrefs.fresh.highScoreNames)
        XCTAssertEqual(try onDisk(), short)
    }

    func testStoreRoundTripOnDisk() throws {
        // A file with bytes no typed field reads: a reserved byte, the pad, an int pref past 3.
        var file = PrefsFile.fresh.fileBytes
        file[0x2000] = 0x9C                     // reserved block 2
        file[0x125e] = 0x7A                     // pad
        file[0x7b] = 0x42                       // int 4's low byte
        try putOnDisk(file)

        // Loading and saving the same prefs writes the same bytes.
        let store = PrefsStore(folder: folder)
        let prefs = try store.load()
        XCTAssertEqual(try onDisk(), file)      // load did not write
        try store.save(prefs)
        XCTAssertEqual(try onDisk(), file)

        // Changed prefs reach disk; the unread bytes stay; a new store reads the changes back.
        var changed = prefs
        changed.highScores[0] = 123_456
        changed.highScoreNames[0] = "Ben"
        changed.playerNames[1] = "Ann"
        changed.intPrefs[3] = 9
        changed.bytePrefs[11] = 1
        try store.save(changed)
        let after = try onDisk()
        XCTAssertEqual(after.count, 0x34f0)
        XCTAssertEqual(after[0x2000], 0x9C)
        XCTAssertEqual(after[0x125e], 0x7A)
        XCTAssertEqual(after[0x7b], 0x42)
        XCTAssertEqual(Array(after[0x1260..<0x1264]), [0x02, 0x4C, 0x6B, 0x43])   // 123456 + 0x24A8903 = 0x024C6B43
        XCTAssertEqual(Array(after[0x1248..<0x124c]), Array("Ann".utf8) + [0])  // player names plain
        XCTAssertEqual(try PrefsStore(folder: folder).load(), changed)
    }
}
