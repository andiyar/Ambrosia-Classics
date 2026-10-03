import Foundation
import XCTest
@testable import AkiCore

/// P1.2 — the 143-byte `GameSettings` blob (docs/aki/file-formats.md §2.2), the 1.1 `Aki Prefs`
/// migration (§2.3, §3), the Preferences checkbox arithmetic and the launch registration.
final class GameSettingsTests: XCTestCase {

    func testDefaultsBlobIsTheExact143Bytes() {
        let blob = [UInt8](GameSettings.defaults.blob)
        XCTAssertEqual(GameSettings.blobLength, 143)
        XCTAssertEqual(GameSettings.defaultsKey, "GameSettings")
        XCTAssertEqual(blob.count, 143)
        XCTAssertEqual(Array(blob[0..<23]), [1] + [UInt8](repeating: 0, count: 11) + [0, 1, 0, 2, 0, 2, 0, 1, 1, 1, 1])
        XCTAssertEqual(Array(blob[23...]), [UInt8](repeating: 0, count: 120))
    }

    func testFieldOffsetsAreBigEndianAndPacked() throws {
        var s = GameSettings.defaults
        s.difficultyRaw = 3
        s.wins[0] = 0x0102
        s.losses[11] = 7
        s.giveUps[5] = -1
        s.bestTimes[0] = 0x0A0B_0C0D
        s.bestTimes[11] = 59
        let blob = [UInt8](s.blob)
        XCTAssertEqual(blob.count, 143)
        XCTAssertEqual(Array(blob[12..<14]), [0, 3])
        XCTAssertEqual(Array(blob[23..<25]), [1, 2])
        XCTAssertEqual(Array(blob[69..<71]), [0, 7])
        XCTAssertEqual(Array(blob[81..<83]), [0xFF, 0xFF])
        XCTAssertEqual(Array(blob[95..<99]), [0x0A, 0x0B, 0x0C, 0x0D])
        XCTAssertEqual(Array(blob[139..<143]), [0, 0, 0, 59])
        XCTAssertEqual(try GameSettings(blob: Data(blob)), s)
    }

    func testEveryByteRoundTrips() throws {
        let bytes = (0..<143).map { UInt8(($0 * 37 + 11) % 256) }
        let decoded = try GameSettings(blob: Data(bytes))
        XCTAssertEqual([UInt8](decoded.blob), bytes)
    }

    func testShortBlobIsRefused() {
        XCTAssertThrowsError(try GameSettings(blob: Data(count: 142))) { error in
            XCTAssertEqual(error as? GameSettings.DecodeError, .tooShort(142))
        }
    }

    /// A 1.1 `Aki Prefs` image: the 0x290-byte `PrefsType` with `_p`'s offsets, big-endian.
    private func akiPrefs11(length: Int = 0x290, unlocked: [UInt8], difficulty: Int16, music: Int16, sound: Int16,
                            flags: [UInt8], wins0: Int16, best0: Int32, losses0: Int16 = 0, giveUps0: Int16 = 0) -> Data {
        var b = [UInt8](repeating: 0, count: length)
        for i in 0..<min(0x200, length) { b[i] = 0xEE }
        func put16(_ v: Int16, _ o: Int) { b[o] = UInt8(UInt16(bitPattern: v) >> 8); b[o + 1] = UInt8(UInt16(bitPattern: v) & 0xFF) }
        for (i, u) in unlocked.enumerated() { b[0x200 + i] = u }
        put16(difficulty, 0x20c); put16(music, 0x20e); put16(sound, 0x210)
        for (i, f) in flags.enumerated() { b[0x212 + i] = f }
        put16(wins0, 0x218)
        put16(losses0, 0x230); put16(giveUps0, 0x248)
        let u = UInt32(bitPattern: best0)
        if length >= 0x264 { for k in 0..<4 { b[0x260 + k] = UInt8((u >> (24 - 8 * UInt32(k))) & 0xFF) } }
        return Data(b)
    }

    func testMigrationReadsThe11StructAtItsOffsets() throws {
        let data = akiPrefs11(unlocked: [1, 1], difficulty: 2, music: 0, sound: 2, flags: [0, 1, 0, 0, 1], wins0: 4, best0: 95,
                              losses0: 6, giveUps0: 0x0203)
        let s = try XCTUnwrap(GameSettings.migrating(akiPrefs11: data))
        XCTAssertEqual(s.unlocked, [1, 1] + [UInt8](repeating: 0, count: 10))
        XCTAssertEqual(s.difficulty, .easy)
        XCTAssertFalse(s.musicOn)
        XCTAssertTrue(s.soundAudible)
        XCTAssertTrue(s.soundCheckbox)
        XCTAssertEqual([s.fullscreen, s.tileAnimation, s.showDescription, s.firstLaunch, s.unused216], [0, 1, 0, 0, 1])
        let zeros11 = [Int16](repeating: 0, count: 11)
        XCTAssertEqual(s.wins, [4] + zeros11)
        XCTAssertEqual(s.losses, [6] + zeros11)
        XCTAssertEqual(s.giveUps, [0x0203] + zeros11)
        XCTAssertEqual(s.bestTimes, [95] + [Int32](repeating: 0, count: 11))
        XCTAssertNil(GameSettings.migrating(akiPrefs11: Data(data.prefix(0x28f))))
    }

    func testCheckboxArithmeticMatchesPreferencesSave() {
        var s = GameSettings.defaults
        s.soundFlags = 3
        s.setSoundCheckbox(false)
        XCTAssertEqual(s.soundFlags, 1)
        XCTAssertFalse(s.soundCheckbox)
        XCTAssertTrue(s.soundAudible)
        s.setSoundCheckbox(true)
        XCTAssertEqual(s.soundFlags, 3)
        XCTAssertTrue(s.soundCheckbox)
        s.musicFlags = 3
        s.setMusicCheckbox(false)
        XCTAssertEqual(s.musicFlags, 1)
        XCTAssertFalse(s.musicOn)
        XCTAssertFalse(s.musicCheckbox)
        XCTAssertTrue(s.registered)
    }

    func testLaunchRegistrationSetsBitZeroKeepsBitOne() {
        for (before, after) in [(Int16(0), Int16(1)), (1, 1), (2, 3), (3, 3)] {
            var s = GameSettings.defaults
            s.musicFlags = before
            s.applyLaunchRegistration()
            XCTAssertEqual(s.musicFlags, after, "musicFlags \(before)")
            XCTAssertTrue(s.registered)
        }
    }

    func testDifficultyCyclesLikeTheMapArrows() {
        let all: [Difficulty] = [.hard, .medium, .easy, .practice]
        XCTAssertEqual(Difficulty.allCases, all)
        XCTAssertEqual(all.map(\.rawValue), [0, 1, 2, 3])
        XCTAssertEqual(all.map(\.next), [.medium, .easy, .practice, .hard])
        XCTAssertEqual(all.map(\.previous), [.practice, .hard, .medium, .easy])
    }

    func testStoreSavesLoadsAndMigrates() throws {
        let suite = "aki-settings-test-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("aki-prefs-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let legacy = dir.appendingPathComponent("Aki Prefs")
        let store = GameSettingsStore(defaults: defaults, legacyPrefsURL: legacy)

        // No key, no file → defaults.
        XCTAssertEqual(store.load(), GameSettings.defaults)

        // Legacy file (levels 1…5 unlocked, Practice) → migrated.
        let legacyData = akiPrefs11(unlocked: [1, 1, 1, 1, 1], difficulty: 3, music: 2, sound: 2,
                                    flags: [0, 1, 1, 1, 1], wins0: 0, best0: 0)
        try legacyData.write(to: legacy)
        let migrated = store.load()
        XCTAssertEqual(migrated.unlocked, [1, 1, 1, 1, 1] + [UInt8](repeating: 0, count: 7))
        XCTAssertEqual(migrated.difficulty, .practice)
        XCTAssertEqual(migrated, GameSettings.migrating(akiPrefs11: legacyData))

        // Save → the 143-byte key wins over the file; the legacy file is not written back.
        var saved = GameSettings.defaults
        saved.unlocked[2] = 1
        saved.difficultyRaw = 0
        store.save(saved)
        XCTAssertEqual((defaults.object(forKey: "GameSettings") as? Data)?.count, 143)
        XCTAssertEqual(store.load(), saved)
        XCTAssertEqual(try Data(contentsOf: legacy), legacyData)

        // A malformed key → defaults (not the legacy file).
        defaults.set(Data([1, 2, 3]), forKey: "GameSettings")
        XCTAssertEqual(store.load(), GameSettings.defaults)
    }
}
