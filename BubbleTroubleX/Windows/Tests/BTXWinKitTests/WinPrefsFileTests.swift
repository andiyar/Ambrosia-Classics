import BTXWinKit
import BubbleTroubleCore
import Foundation
import XCTest

/// `WinPrefsFile` (D16.3): the prefs blob in a plain file, never `UserDefaults`.
final class WinPrefsFileTests: XCTestCase {
    private func scratch() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("win-prefs-\(UUID().uuidString)", isDirectory: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    func testDefaultPaths() throws {
        let win = WinPrefsFile.defaultURL(environment: ["APPDATA": "/C/Users/ben/AppData/Roaming"], windows: true,
                                          home: URL(fileURLWithPath: "/unused"))
        XCTAssertEqual(win?.path, "/C/Users/ben/AppData/Roaming/Ambrosia Classics/Bubble Trouble X/Prefs.bin")
        XCTAssertNil(WinPrefsFile.defaultURL(environment: [:], windows: true, home: URL(fileURLWithPath: "/h")))
        let mac = WinPrefsFile.defaultURL(environment: [:], windows: false, home: URL(fileURLWithPath: "/Users/ben"))
        XCTAssertEqual(mac?.path,
                       "/Users/ben/Library/Application Support/Ambrosia Classics/Bubble Trouble X (SDL)/Prefs.bin")
        // Never the Mac replica's prefs domain (Ben's play data).
        XCTAssertFalse(mac!.path.contains(BTXPrefsStore.domain))
        XCTAssertFalse(mac!.path.contains("Preferences"))
    }

    func testRoundTripCreatesFolderAndReplacesAtomically() throws {
        let file = try scratch().appendingPathComponent("a/b/Prefs.bin")
        let store = WinPrefsFile(fileURL: file)
        XCTAssertNil(store.data(forKey: BTXPrefsStore.key))
        store.set(Data([1, 2, 3]), forKey: BTXPrefsStore.key)
        XCTAssertEqual(try Data(contentsOf: file), Data([1, 2, 3]))
        store.set(Data([9]), forKey: BTXPrefsStore.key)
        XCTAssertEqual(store.data(forKey: BTXPrefsStore.key), Data([9]))
        // No temporary files left beside it.
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: file.deletingLastPathComponent().path),
                       ["Prefs.bin"])
        store.set(Data([7]), forKey: "Other")
        XCTAssertEqual(try Data(contentsOf: file.deletingLastPathComponent().appendingPathComponent("Other.bin")),
                       Data([7]))
        store.removeObject(forKey: BTXPrefsStore.key)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        store.removeObject(forKey: BTXPrefsStore.key)                // absent: no error
    }

    /// `BTXPrefsStore` over the file: a save then a fresh load gives the same prefs and scores.
    func testPrefsStoreRoundTripsThroughTheFile() throws {
        let file = try scratch().appendingPathComponent("Prefs.bin")
        let factory = HighScoreTable.empty
        let first = BTXPrefsStore(backing: WinPrefsFile(fileURL: file), legacyFileURL: nil, factoryScores: factory)
        var (prefs, scores) = first.load()
        XCTAssertEqual(prefs, BTXPrefs.defaults)
        prefs.sfxVolume = 2
        prefs.musicVolume = 1
        first.save(prefs: prefs, scores: &scores)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
        let second = BTXPrefsStore(backing: WinPrefsFile(fileURL: file), legacyFileURL: nil, factoryScores: factory)
        let (loaded, loadedScores) = second.load()
        XCTAssertEqual(loaded.sfxVolume, 2)
        XCTAssertEqual(loaded.musicVolume, 1)
        XCTAssertEqual(loadedScores, scores)
    }

    func testMemoryPrefsRecordWrites() {
        let m = WinMemoryPrefs()
        m.set(Data([1]), forKey: "Prefs")
        XCTAssertEqual(m.data(forKey: "Prefs"), Data([1]))
        m.removeObject(forKey: "Prefs")
        XCTAssertNil(m.data(forKey: "Prefs"))
        XCTAssertEqual(m.writes, ["Prefs"])
    }
}
