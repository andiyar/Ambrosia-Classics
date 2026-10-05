import BubbleTroubleCore
import Foundation
import XCTest

/// Plan 2026-10-04-btx-playable §C5 (+ amendment R2) — the 0x800 prefs blob, key sets 1–8, the 0x8a high-score
/// block and its persistence. Oracles: data-formats §8–§9, FI §4 / §8, `_AlexPrefsInit @ 0000fa93` and its three
/// helpers, `_ZeroPrefs @ 0002722d`, `_CheckHiScore @ 00024b34`, `_LoadGamePrefs @ 00027306`,
/// `_SaveGamePrefs @ 00026b36`, `SCOR 128`.
final class PrefsTests: XCTestCase {

    // MARK: helpers

    /// A throw-away UserDefaults suite — never the replica's real domain.
    private func scratchDefaults() -> UserDefaults {
        let name = "btx-prefs-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        addTeardownBlock { UserDefaults(suiteName: name)?.removePersistentDomain(forName: name) }
        return defaults
    }

    private func scratchFile(_ data: Data?) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("btx-prefs-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("Bubble Trouble X Prefs")
        if let data { try data.write(to: url) }
        return url
    }

    /// A table distinguishable from any other (stands in for SCOR 128 where the data is not needed).
    private func table(_ base: Int32) -> HighScoreTable {
        var t = HighScoreTable.empty
        for i in 0..<7 { t.setEntry(i, name: "N\(base)-\(i)", score: base - Int32(i) * 10, level: 7 - i) }
        t.defaultName = "D\(base)"
        return t
    }

    private func be16(_ d: Data, _ o: Int) -> Int { Int(Int16(bitPattern: UInt16(d[o]) << 8 | UInt16(d[o + 1]))) }

    // MARK: tests

    func testDefaultsMatchAlexPrefsInit() {
        let p = BTXPrefs.defaults
        XCTAssertEqual(p.data.count, 0x800)
        XCTAssertEqual(p.version, 0x17)
        // _AlexPrefsSoundInit @ 0000f6b8
        XCTAssertEqual(p.sfxVolume, 3); XCTAssertEqual(p.lastSfxVolume, 3)
        XCTAssertEqual(p.musicVolume, 4); XCTAssertEqual(p.lastMusicVolume, 4)
        XCTAssertTrue(p.titleMusic)
        // _AlexPrefsKeysInit @ 0000f790
        XCTAssertFalse(p.inputSprockets)
        XCTAssertEqual(p.keySetCount, 8); XCTAssertEqual(p.currentKeySetIndex, 1)
        XCTAssertEqual(p.currentKeySet, KeySet.builtIn[0])
        // _AlexPrefsGameInit @ 0000fa24 (OS X: bool 0x3f = !IsOSX = 0)
        XCTAssertEqual(p.spritePlotting, 2)
        XCTAssertFalse(p.fullScreen); XCTAssertFalse(p.quickerDraw); XCTAssertFalse(p.holdEscapeToExit)
        XCTAssertTrue(p.showStars); XCTAssertTrue(p.showAirBubbles)
        XCTAssertEqual(p.cosmetic, CosmeticPrefs(stars: true, airBubbles: true))
        // _AlexPrefsInit @ 0000fa93
        XCTAssertEqual(p.levelSelectMax, 10)
        XCTAssertFalse(p.defaultScoresLoaded)
        for n in [0x33, 0x34, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3e] { XCTAssertFalse(p.bool(n), "bool \(n)") }
        // Every other bool/short/long is zero (_ZeroPrefs @ 0002722d).
        let setBools: Set = [0x35, 0x36, 0x40], setShorts: Set = [0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a]
        for n in 1...100 {
            if !setBools.contains(n) { XCTAssertFalse(p.bool(n), "bool \(n)") }
            if !setShorts.contains(n) { XCTAssertEqual(p.short(n), 0, "short \(n)") }
            XCTAssertEqual(p.long(n), 0, "long \(n)")
        }
        // Byte layout (data-formats §9): bool n at byte n+1, short n at 0x66 + 2(n−1), BE.
        XCTAssertEqual(p.data[0], 0x00); XCTAssertEqual(p.data[1], 0x17)
        XCTAssertEqual(p.data[0x35 + 1], 1); XCTAssertEqual(p.data[0x40 + 1], 1); XCTAssertEqual(p.data[0x37 + 1], 0)
        XCTAssertEqual(be16(p.data, 0x66 + 2 * (0x3a - 1)), 10)
        XCTAssertEqual(be16(p.data, 0x66 + 2 * (0x35 - 1)), 4)
        // Legacy score list filled by _ZeroPrefs: "Bubble Trouble X" 10000, 9000 … 1000.
        XCTAssertEqual(p.legacyScore(1).name, "Bubble Trouble X"); XCTAssertEqual(p.legacyScore(1).score, "10000")
        XCTAssertEqual(p.legacyScore(10).name, "Bubble Trouble X"); XCTAssertEqual(p.legacyScore(10).score, "1000")
        // Typed setters write the same slots the generic accessors read.
        var q = p
        q.holdEscapeToExit = true; q.levelSelectMax = 30; q.musicVolume = 1
        XCTAssertTrue(q.bool(0x3d)); XCTAssertEqual(q.short(0x3a), 30); XCTAssertEqual(q.short(0x35), 1)
        q.setLong(100, -2)
        XCTAssertEqual(q.long(100), -2)
        XCTAssertEqual([UInt8](q.data[(0x12e + 4 * 99)..<(0x12e + 4 * 100)]), [0xff, 0xff, 0xff, 0xfe])
    }

    func testKeySets1to8() {
        let expected: [(String, [UInt16])] = [
            ("Default", [0x7b, 0x7c, 0x7e, 0x7d, 0x31]),
            ("Keypad 1", [0x56, 0x58, 0x5b, 0x54, 0x31]),
            ("Keypad 2", [0x56, 0x58, 0x5b, 0x57, 0x31]),
            ("Keypad 3", [0x56, 0x58, 0x5b, 0x54, 0x52]),
            ("Keypad 4", [0x56, 0x58, 0x5b, 0x57, 0x52]),
            ("Keyboard", [0x26, 0x25, 0x22, 0x28, 0x31]),
            ("Classic", [0x06, 0x07, 0x27, 0x2c, 0x31]),
            ("Spectrum", [0x0c, 0x0d, 0x0e, 0x0f, 0x11]),
        ]
        XCTAssertEqual(KeySet.builtIn.count, 8)
        let p = BTXPrefs.defaults
        for (i, (name, codes)) in expected.enumerated() {
            XCTAssertEqual(KeySet.builtIn[i].name, name)
            XCTAssertEqual(KeySet.builtIn[i].codes, codes)
            XCTAssertEqual(p.keySet(i + 1), KeySet.builtIn[i], "set \(i + 1)")
        }
        let first = KeySet.builtIn[0]
        XCTAssertEqual([first.left, first.right, first.up, first.down, first.push], [0x7b, 0x7c, 0x7e, 0x7d, 0x31])
        // Sets 9–20 are empty after init.
        XCTAssertEqual(p.keySet(9), KeySet(name: "", left: 0, right: 0, up: 0, down: 0, push: 0))
        // Layout: 0x2be + 22(n−1): 12-byte C name, then i16 BE ×5.
        let o = 0x2be + 22 * 6
        XCTAssertEqual([UInt8](p.data[o..<(o + 8)]), Array("Classic\0".utf8))
        XCTAssertEqual([UInt8](p.data[(o + 12)..<(o + 22)]), [0, 6, 0, 7, 0, 0x27, 0, 0x2c, 0, 0x31])
        var q = p
        let mine = KeySet(name: "Mine", left: 1, right: 2, up: 3, down: 4, push: 5)
        q.setKeySet(20, mine)
        q.currentKeySetIndex = 20
        XCTAssertEqual(q.keySet(20), mine)
        XCTAssertEqual(q.currentKeySet, mine)
        XCTAssertEqual(q.data[0x2be + 22 * 19 + 21], 5)
    }

    func testBlobRoundTrip() throws {
        var p = BTXPrefs.defaults
        p.fullScreen = true; p.sfxVolume = 1; p.setKeySet(9, KeySet(name: "Nine", left: 9, right: 8, up: 7, down: 6, push: 5))
        XCTAssertEqual(BTXPrefs(data: p.data), p)
        XCTAssertNil(BTXPrefs(data: Data(count: 0x7ff)))
        let t = table(9000)
        XCTAssertEqual(t.data.count, 0x8a)
        XCTAssertEqual(HighScoreTable(data: t.data), t)
        XCTAssertEqual(t.entries.map(\.score), [9000, 8990, 8980, 8970, 8960, 8950, 8940])
        XCTAssertEqual(t.entry(0).name, "N9000-0"); XCTAssertEqual(t.entry(0).level, 7); XCTAssertEqual(t.defaultName, "D9000")
        XCTAssertNil(HighScoreTable(data: Data(count: 0x89)))
        // Through the store: one Data under key "Prefs" = 0x800 prefs then the 0x8a block.
        let defaults = scratchDefaults()
        let store = BTXPrefsStore(defaults: defaults, legacyFileURL: nil, factoryScores: table(1))
        var scores = t
        store.save(prefs: p, scores: &scores)              // first save = file creation → factory scores
        XCTAssertEqual(scores, table(1))
        scores = t
        store.save(prefs: p, scores: &scores)              // the "file" exists now → kept
        XCTAssertEqual(scores, t)
        let stored = try XCTUnwrap(defaults.data(forKey: BTXPrefsStore.key))
        XCTAssertEqual(stored, p.data + t.data)
        XCTAssertEqual(BTXPrefsStore.key, "Prefs")
        XCTAssertEqual(BTXPrefsStore.domain, "com.ambrosiaclassics.bubbletroublex")
        var loadedPrefs = p
        loadedPrefs.defaultScoresLoaded = true                       // _LoadGamePrefs sets bool 0x3e on first load
        let loaded = store.load()
        XCTAssertEqual(loaded.prefs, loadedPrefs)
        XCTAssertEqual(loaded.scores, table(1))                     // …and reloads the factory scores
        var again = loaded.scores
        again.setEntry(0, name: "Kept", score: 99999, level: 9)
        store.save(prefs: loaded.prefs, scores: &again)
        XCTAssertEqual(store.load().scores, again)                  // flag set → table survives from now on
        XCTAssertEqual(store.load().prefs, loadedPrefs)
    }

    func testScor128Defaults() throws {
        let game = try BTXGameData(resourcesDirectory: BTXTestData.resourcesDirectory())
        let raw = try XCTUnwrap(game.data(type: "SCOR", id: 128))
        XCTAssertEqual(raw.count, 0x8a)
        let t = try HighScoreTable.factory(from: game)
        XCTAssertEqual(t.data, raw)
        XCTAssertEqual(t.defaultName, "The Fonz")
        let expected: [(String, Int32, Int)] = [
            ("Potsie", 4500, 4), ("Ralph", 1000, 3), ("Ritchie", 500, 2), ("Mr Kotter", 500, 1),
            ("Horshack", 500, 1), ("Mr Peabody", 500, 1), ("Sherman", 500, 1),
        ]
        XCTAssertEqual(t.entries.count, 7)
        for (i, e) in expected.enumerated() {
            XCTAssertEqual(t.entry(i).name, e.0); XCTAssertEqual(t.entry(i).score, e.1); XCTAssertEqual(t.entry(i).level, e.2)
        }
    }

    func testQualifiesAboveSeventh() {
        let t = table(1000)                                 // entry 7 (index 6) = 940
        XCTAssertFalse(t.qualifies(score: 939))
        XCTAssertFalse(t.qualifies(score: 940))             // strictly greater than entry #7
        XCTAssertTrue(t.qualifies(score: 941))
        XCTAssertTrue(t.qualifies(score: 1_000_000))
    }

    func testInsertShiftsDown() {
        var t = table(1000)                                 // 1000 990 980 970 960 950 940
        XCTAssertNil(t.insert(name: "Low", score: 940, level: 1))
        XCTAssertEqual(t, table(1000))
        // Ties go below the existing equal score (strict > in the shift loop).
        XCTAssertEqual(t.insert(name: "Tie", score: 980, level: 12), 3)
        XCTAssertEqual(t.entries.map(\.score), [1000, 990, 980, 980, 970, 960, 950])
        XCTAssertEqual(t.entries.map(\.name), ["N1000-0", "N1000-1", "N1000-2", "Tie", "N1000-3", "N1000-4", "N1000-5"])
        XCTAssertEqual(t.entries.map(\.level), [7, 6, 5, 12, 4, 3, 2])
        XCTAssertEqual(t.defaultName, "Tie")                // slot 0 = last name entered
        XCTAssertEqual(t.insert(name: "Top", score: 5000, level: 30), 0)
        XCTAssertEqual(t.entries.map(\.name), ["Top", "N1000-0", "N1000-1", "N1000-2", "Tie", "N1000-3", "N1000-4"])
        // Two-step form (score first, name after the dialog), as _CheckHiScore does it.
        var u = table(1000)
        let index = u.insertScore(score: 945, level: 2)
        XCTAssertEqual(index, 6)
        XCTAssertEqual(u.entry(6).score, 945); XCTAssertEqual(u.entry(6).level, 2)
        u.setName("Late", at: 6)
        XCTAssertEqual(u.entry(6).name, "Late"); XCTAssertEqual(u.defaultName, "Late")
        // Names are stored as a 12-byte Pascal string (≤ 11 characters).
        u.setName("ABCDEFGHIJKLMNOP", at: 0)
        XCTAssertEqual(u.entry(0).name, "ABCDEFGHIJK")
    }

    func testJokeNameSubstitution() {
        // Every pair of the _CheckHiScore compare chain (exact, case-sensitive C-string compares).
        let pairs: [(String, String, Int)] = [
            ("Wareing", "Swoop!", 13), ("Metcalf", "Maniac!", 13), ("Luke", "Skywalker", 13),
            ("Dog", "Nonny", 46), ("Woof", "Nonny", 46), ("Han", "Solo", 13), ("Darth", "Vader", 13),
            ("Ben", "Obi Wan", 13), ("Apple", "Moof", 13), ("Bart", "Simpson", 13), ("Homer", "Doh", 13),
            ("Steve", "Woz", 13), ("Oogle", "Boogle", 13),
        ]
        XCTAssertEqual(HighScoreTable.jokeNames.map(\.typed), pairs.map(\.0))
        XCTAssertEqual(HighScoreTable.jokeNames.map(\.replacement), pairs.map(\.1))
        XCTAssertEqual(HighScoreTable.jokeNames.map(\.sound), pairs.map(\.2))
        let noRandom: (Int, Int) -> Int = { _, _ in XCTFail("random drawn for a typed name"); return 0 }
        for (typed, replacement, sound) in pairs {
            let r = HighScoreTable.resolveName(typed: typed, randomFast: noRandom)
            XCTAssertEqual(r.name, replacement, typed); XCTAssertEqual(r.sound, sound, typed)
        }
        for typed in ["luke", "Lukas", "Ben ", "Andrew", "Swoop!"] {
            let r = HighScoreTable.resolveName(typed: typed, randomFast: noRandom)
            XCTAssertEqual(r.name, typed); XCTAssertNil(r.sound)
        }
        // Empty → GetRandomFast(0,1): 0 "Maniac", else "Swoop" (no extra sound).
        var calls: [[Int]] = []
        let zero = HighScoreTable.resolveName(typed: "") { lo, hi in calls.append([lo, hi]); return 0 }
        let one = HighScoreTable.resolveName(typed: "") { lo, hi in calls.append([lo, hi]); return 1 }
        XCTAssertEqual(zero.name, "Maniac"); XCTAssertNil(zero.sound)
        XCTAssertEqual(one.name, "Swoop"); XCTAssertNil(one.sound)
        XCTAssertEqual(calls, [[0, 1], [0, 1]])
        // The resolved name is what lands in the table and the default slot.
        var t = table(1000)
        let r = HighScoreTable.resolveName(typed: "Homer", randomFast: noRandom)
        _ = t.insert(name: r.name, score: 2000, level: 3)
        XCTAssertEqual(t.entry(0).name, "Doh"); XCTAssertEqual(t.defaultName, "Doh")
    }

    func testLegacyFileImportVersionGate() throws {
        var legacyPrefs = BTXPrefs.defaults
        legacyPrefs.currentKeySetIndex = 7; legacyPrefs.holdEscapeToExit = true; legacyPrefs.defaultScoresLoaded = true
        let legacyScores = table(5000)
        let factory = table(1)

        // 1. Version 0x17, scores already flagged → imported as is, copied into UserDefaults; file untouched.
        let good = try scratchFile(legacyPrefs.data + legacyScores.data)
        let d1 = scratchDefaults()
        let s1 = BTXPrefsStore(defaults: d1, legacyFileURL: good, factoryScores: factory)
        let l1 = s1.load()
        XCTAssertEqual(l1.prefs, legacyPrefs); XCTAssertEqual(l1.scores, legacyScores)
        XCTAssertEqual(d1.data(forKey: BTXPrefsStore.key), legacyPrefs.data + legacyScores.data)
        XCTAssertEqual(try Data(contentsOf: good), legacyPrefs.data + legacyScores.data)
        var keep = l1.scores
        s1.save(prefs: l1.prefs, scores: &keep)              // imported = "file exists": no factory reset
        XCTAssertEqual(keep, legacyScores)

        // 2. Version 0x17, bool 0x3e clear → flag set, factory scores loaded, saved.
        var unflagged = legacyPrefs; unflagged.defaultScoresLoaded = false
        let d2 = scratchDefaults()
        let l2 = BTXPrefsStore(defaults: d2, legacyFileURL: try scratchFile(unflagged.data + legacyScores.data),
                               factoryScores: factory).load()
        XCTAssertEqual(l2.prefs, legacyPrefs); XCTAssertEqual(l2.scores, factory)
        XCTAssertEqual(d2.data(forKey: BTXPrefsStore.key), legacyPrefs.data + factory.data)

        // 3. Wrong version → defaults (the original deletes and re-inits); nothing stored, file untouched.
        var old = legacyPrefs; old.version = 0x16
        let bad = try scratchFile(old.data + legacyScores.data)
        let d3 = scratchDefaults()
        let l3 = BTXPrefsStore(defaults: d3, legacyFileURL: bad, factoryScores: factory).load()
        XCTAssertEqual(l3.prefs, .defaults); XCTAssertEqual(l3.scores, factory)
        XCTAssertNil(d3.data(forKey: BTXPrefsStore.key))
        XCTAssertEqual(try Data(contentsOf: bad), old.data + legacyScores.data)

        // 4. No file, nothing stored → defaults, nothing stored.
        let d4 = scratchDefaults()
        let l4 = BTXPrefsStore(defaults: d4, legacyFileURL: try scratchFile(nil), factoryScores: factory).load()
        XCTAssertEqual(l4.prefs, .defaults); XCTAssertEqual(l4.scores, factory)
        XCTAssertNil(d4.data(forKey: BTXPrefsStore.key))

        // 5. A stored blob wins over the legacy file (import happens on first run only).
        let d5 = scratchDefaults()
        var mine = BTXPrefs.defaults; mine.defaultScoresLoaded = true; mine.sfxVolume = 2
        d5.set(mine.data + table(77).data, forKey: BTXPrefsStore.key)
        let l5 = BTXPrefsStore(defaults: d5, legacyFileURL: good, factoryScores: factory).load()
        XCTAssertEqual(l5.prefs, mine); XCTAssertEqual(l5.scores, table(77))

        // 6. Default legacy location is ~/Library/Preferences/Bubble Trouble X Prefs.
        XCTAssertEqual(BTXPrefsStore.legacyFileURL.lastPathComponent, "Bubble Trouble X Prefs")
        XCTAssertEqual(BTXPrefsStore.legacyFileURL.deletingLastPathComponent().lastPathComponent, "Preferences")
    }
}
