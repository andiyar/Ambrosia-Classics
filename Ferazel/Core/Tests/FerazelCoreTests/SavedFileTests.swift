import XCTest
import HectorResources
@testable import FerazelCore

/// SV2 (docs/plans/2026-10-14-ferazel-phase3.md): the prefs record (`'Pref'` 0, 0x942 B — `.InitPrefs @ 1000f180`,
/// M l. 7694–7768), the prefs file, the saved-game file (`'FWSg'` 0 "Ferazel Saved Game" — `.SaveSG @ 10048294`,
/// `.OpenSG @ 10048608`, M l. 41179ff / 41315ff) and `.IncrementLastSGString @ 1004811c` (M l. 41115); engine §8–§9,
/// save-continue §3. Files are written only under the temporary directory (G8).
final class SavedFileTests: XCTestCase {

    private func u16(_ d: Data, _ o: Int) -> UInt16 { UInt16(d[d.startIndex + o]) << 8 | UInt16(d[d.startIndex + o + 1]) }
    private func bytes(_ d: Data, _ r: Range<Int>) -> [UInt8] { [UInt8](d[(d.startIndex + r.lowerBound)..<(d.startIndex + r.upperBound)]) }

    private func tempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ferazel-sv2-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
        return dir
    }

    /// A block with something in every region: header, G, date, a snapshot, the world-name pstr.
    private func sampleBlock() -> SaveBlock {
        var block = SaveBlock()
        block.worldStamp = 0x1234_5678
        block.demo = 1
        block.isCheckpoint = 1
        block.level = 2
        block.playerX = -5
        block.playerY = 0x0102_0304
        block.globals = GameGlobals.initGameGlobals(previous: nil)
        block.date = 0xBADC_0FFE
        block.snapshots[2][7] = Placement(index: 7, flag: 1, byte1: 2, type: 300, p1: 4, p2: 5, p3: 6, p4: 7, y: 80, x: 90)
        block.worldName = Array("World Data".utf8)
        return block
    }

    func testPrefsDefaultsRecord() {
        let prefs = FerazelPrefs()
        let r = prefs.record()
        XCTAssertEqual(r.count, 0x942)
        XCTAssertEqual(bytes(r, 0x12..<0x24), [0x00, 0x56, 0x00, 0x58, 0x00, 0x5B, 0x00, 0x57, 0x00, 0x38, 0x00, 0x3A,
                                               0x00, 0x37, 0x00, 0x59, 0x00, 0x5C])
        XCTAssertEqual(u16(r, 0x0e), 7)
        XCTAssertEqual(u16(r, 0x10), 9)
        XCTAssertEqual(u16(r, 0x3a), 0xffff)
        XCTAssertEqual(bytes(r, 0x42..<0x48), [0x05, 0x40, 0x40, 0x40, 0x40, 0x40])
        // The rest of `.InitPrefs`' stores (M l. 7714–7756), in record order.
        XCTAssertEqual(bytes(r, 0x00..<0x0e), [0, 0, 0, 1, 0, 2, 0, 1, 0, 0, 0, 1, 1, 0])
        XCTAssertEqual([u16(r, 0x2a), u16(r, 0x30), u16(r, 0x32), u16(r, 0x34), u16(r, 0x36), u16(r, 0x38)],
                       [0x30, 0x4c, 0, 1, 0, 0])
        XCTAssertEqual([u16(r, 0x3c), u16(r, 0x3e), u16(r, 0x40)], [0, 0, 0])
        XCTAssertEqual(u16(FerazelPrefs(systemVolume: 0x100).record(), 0x38), 9)
        XCTAssertEqual(u16(FerazelPrefs(processorType: 0x107).record(), 0x06), 2)
        // Never written by `.InitPrefs` → 0 (Invariant 7): +0x0d, +0x24..+0x29, +0x2c..+0x2f, the "@@@@@" tail,
        // and the eight pstr[256] at +0x142 past their (empty) length bytes.
        XCTAssertEqual(r[0x0d], 0)
        XCTAssertEqual(bytes(r, 0x24..<0x2a), [0, 0, 0, 0, 0, 0])
        XCTAssertEqual(bytes(r, 0x2c..<0x30), [0, 0, 0, 0])
        XCTAssertTrue(bytes(r, 0x48..<0x142).allSatisfy { $0 == 0 })
        XCTAssertTrue(bytes(r, 0x142..<0x942).allSatisfy { $0 == 0 })
        XCTAssertEqual(prefs.recentNames, Array(repeating: "", count: 8))
        // Reading the record back gives the same prefs and the same bytes.
        XCTAssertEqual(FerazelPrefs(record: r), prefs)
        XCTAssertEqual(FerazelPrefs(record: r).record(), r)
    }

    func testPrefsShortRecordGrows() {
        // A 0x40-byte record (`GetHandleSize` < 0x942 → `SetHandleSize(h, 0x942)`, M l. 7760–7766): the first 0x40
        // bytes are kept, the grown tail is 0 (the replica's choice; junk in the original).
        let short = Data((0..<0x40).map { UInt8(truncatingIfNeeded: $0 &* 37 &+ 11) })
        let prefs = FerazelPrefs(record: short)
        let r = prefs.record()
        XCTAssertEqual(r.count, 0x942)
        XCTAssertEqual(bytes(r, 0..<0x40), [UInt8](short))
        XCTAssertTrue(bytes(r, 0x40..<0x942).allSatisfy { $0 == 0 })
        XCTAssertEqual(prefs.savedGameName, "")
        XCTAssertEqual(prefs.keys[0], Int16(bitPattern: u16(short, 0x12)))
        // Unknown bytes survive an edit of the modelled fields.
        var edited = prefs
        edited.musicVolume = 3
        edited.savedGameName = "Ferazel Saved Game 2"
        let e = edited.record()
        XCTAssertEqual(e[0x0d], short[0x0d])
        XCTAssertEqual(bytes(e, 0x24..<0x2a), bytes(short, 0x24..<0x2a))
        XCTAssertEqual(u16(e, 0x10), 3)
        XCTAssertEqual(e[0x42], 20)
        XCTAssertEqual(FerazelPrefs(record: e).savedGameName, "Ferazel Saved Game 2")
    }

    func testPrefsFileRoundTrip() throws {
        let dir = try tempDir()
        let url = dir.appendingPathComponent(PrefsFile.fileName)
        XCTAssertEqual(PrefsFile.fileName, "Ferazel's Wand Prefs")
        XCTAssertNil(PrefsFile.read(from: url))                        // absent → `.InitPrefs`' defaults
        var prefs = FerazelPrefs()
        prefs.soundVolume = 3
        prefs.keys[4] = 0x31
        prefs.savedGameName = "My Save"
        prefs.recentNames[2] = "Old"
        try PrefsFile.write(prefs.record(), to: url)
        let back = try XCTUnwrap(PrefsFile.read(from: url))
        XCTAssertEqual(back, prefs.record())
        XCTAssertEqual(FerazelPrefs(record: back), prefs)
        // One `'Pref'` 0 named "Preferences" (`AddResource(h,'Pref',0,"Preferences")`, M l. 7758).
        let map = try ClassicResourceMap.parse(try Data(contentsOf: url))
        XCTAssertEqual(map.count, 1)
        let res = try XCTUnwrap(map.resource(type: "Pref", id: 0))
        XCTAssertEqual(res.name, "Preferences")
        XCTAssertEqual(res.data.count, 0x942)
        // A file holding no `'Pref'` 0 reads as absent (`Get1Resource` nil → defaults).
        try ClassicResourceMap.serialize([Resource(type: "Pref", id: 1, name: nil, data: Data([1]))]).write(to: url)
        XCTAssertNil(PrefsFile.read(from: url))
        // An existing but unreadable file (here a folder) is no record either: the defaults, not an error.
        let folder = dir.appendingPathComponent("Unreadable Prefs")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        XCTAssertNil(PrefsFile.read(from: folder))
    }

    func testSavedGameFileRoundTrip() throws {
        let dir = try tempDir()
        let url = dir.appendingPathComponent("Ferazel Saved Game")
        let block = sampleBlock()
        try SavedGameFile.write(block, to: url)
        let image = block.image()
        // The data fork is the classic map: one `'FWSg'` 0 named "Ferazel Saved Game" (0x100a586c), 966,232 B.
        let map = try ClassicResourceMap.parse(try Data(contentsOf: url))
        XCTAssertEqual(map.count, 1)
        let res = try XCTUnwrap(map.resource(type: "FWSg", id: 0))
        XCTAssertEqual(res.name, "Ferazel Saved Game")
        XCTAssertEqual(res.data, image)
        let back = try SavedGameFile.read(from: url)
        XCTAssertEqual(back.image(), image)
        XCTAssertEqual(back, block)
        #if os(macOS)
        // `FSpCreate(spec, 'Msct', 'FWSg', 0)` (M l. 41253).
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        XCTAssertEqual((attrs[.hfsTypeCode] as? NSNumber)?.uint32Value, 0x4657_5367)      // 'FWSg'
        XCTAssertEqual((attrs[.hfsCreatorCode] as? NSNumber)?.uint32Value, 0x4d73_6374)   // 'Msct'
        #endif
        // Overwrite (`FSpDelete` + create): the second write replaces the first.
        var second = block
        second.level = 1
        try SavedGameFile.write(second, to: url)
        XCTAssertEqual(try SavedGameFile.read(from: url).level, 1)
        // No `'FWSg'` 0 → "Sorry, this does not appear to be a saved game file." (0x100a5a3d).
        let junk = dir.appendingPathComponent("junk")
        try Data("not a resource file".utf8).write(to: junk)
        XCTAssertThrowsError(try SavedGameFile.read(from: junk)) {
            XCTAssertEqual($0 as? SavedGameError, .notASavedGame)
        }
        XCTAssertEqual(SavedGameError.notASavedGame.message, "Sorry, this does not appear to be a saved game file.")
        XCTAssertEqual(SavedGameError.openFailed.message, "Error opening the saved game.")
        // `.SaveSG`'s error mapping (M l. 41275–41296): −34 / −33 / −44 / other; only the last passes the code.
        XCTAssertEqual(SavedGameFile.writeErrorReport(osErr: -34).message,
                       "The game could not be saved, because the disk is full.")
        XCTAssertEqual(SavedGameFile.writeErrorReport(osErr: -33).message,
                       "The game could not be saved, because the directory is full.")
        XCTAssertEqual(SavedGameFile.writeErrorReport(osErr: -44).message,
                       "The game could not be saved, because the volume is locked.")
        let other = SavedGameFile.writeErrorReport(osErr: -36)
        XCTAssertEqual(other.message,
                       "The game could not be saved. Check that there is enough space and the volume is not locked.")
        XCTAssertEqual(other.code, -36)
        XCTAssertNil(SavedGameFile.writeErrorReport(osErr: -34).code)
        XCTAssertEqual(SavedGameFile.writeErrorReport(osErr: -32).code, -32)   // > −33 falls to the last string
        XCTAssertEqual(SavedGameFile.writeErrorReport(osErr: -35).code, -35)   // < −34, not −44
    }

    func testSavedGameFromResourceFork() throws {
        #if os(macOS)
        // A save from a real Mac: the map lives in the resource fork, the data fork is empty.
        let dir = try tempDir()
        let url = dir.appendingPathComponent("Mac Save")
        XCTAssertTrue(FileManager.default.createFile(atPath: url.path, contents: Data()))
        let block = sampleBlock()
        let map = ClassicResourceMap.serialize([Resource(type: "FWSg", id: 0, name: "Ferazel Saved Game",
                                                         data: block.image())])
        try map.write(to: url.appendingPathComponent("..namedfork/rsrc"))
        XCTAssertEqual(try Data(contentsOf: url).count, 0)
        XCTAssertEqual(try SavedGameFile.read(from: url).image(), block.image())
        #endif
    }

    func testSaveNameSequence() {
        // `.IncrementLastSGString` (M l. 41115): "@@@@" in chars 1…4 → "Ferazel Saved Game" (0x100a586c); trailing
        // digits → value + 1; trailing space → "2"; else " 2"; only when the length is < 31.
        XCTAssertEqual(SaveName.increment("@@@@@"), "Ferazel Saved Game")
        XCTAssertEqual(SaveName.increment("Ferazel Saved Game"), "Ferazel Saved Game 2")
        XCTAssertEqual(SaveName.increment("Ferazel Saved Game 2"), "Ferazel Saved Game 3")
        XCTAssertEqual(SaveName.increment("Ferazel Saved Game 9"), "Ferazel Saved Game 10")
        XCTAssertEqual(SaveName.increment("Game "), "Game 2")
        let long = String(repeating: "x", count: 31)
        XCTAssertEqual(SaveName.increment(long), long)
        XCTAssertEqual(SaveName.increment(String(repeating: "y", count: 30)), String(repeating: "y", count: 30) + " 2")
        XCTAssertEqual(SaveName.increment("41"), "42")                 // all digits: the prefix is empty
        XCTAssertEqual(SaveName.increment(""), " 2")                   // the length byte 0 is neither digit nor space
        // The field form reads the stale bytes past the length (chars 1…4 regardless of the length byte).
        var field = [UInt8](repeating: 0, count: 256)
        field[0] = 2
        for k in 1...5 { field[k] = 0x40 }
        XCTAssertEqual(Array(SaveName.increment(field: field).prefix(19)), [18] + Array("Ferazel Saved Game".utf8))
        // The prefs record's field drives it the same way.
        var prefs = FerazelPrefs()
        prefs.incrementSavedGameName()
        XCTAssertEqual(prefs.savedGameName, "Ferazel Saved Game")
        prefs.incrementSavedGameName()
        XCTAssertEqual(prefs.savedGameName, "Ferazel Saved Game 2")
    }
}
