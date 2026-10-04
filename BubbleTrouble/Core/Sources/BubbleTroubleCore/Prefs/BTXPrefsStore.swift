import Foundation

/// Persists the prefs blob + high-score block as one `Data` (0x800 + 0x8a bytes, the original file's data-fork
/// image) under the UserDefaults key `Prefs` (plan Known delta 6). The App passes `UserDefaults.standard`, whose
/// domain is the replica's bundle id; tests pass a scratch suite.
///
/// "The stored entry exists" plays the part of "the prefs file exists", so the original's load/save quirks are
/// kept:
/// - `load()` transcribes `_LoadGamePrefs @ 00027306` (after `_main`'s `_InitPrefs`, `_AlexPrefsInit`,
///   `_LoadDefaultHiScores`): nothing stored → defaults; version ≠ 0x17 → the entry is removed and defaults are
///   used (the original deletes the file and re-inits); version 0x17 with bool 0x3e "default scores loaded" clear
///   → the flag is set, the factory scores replace the stored table, and it is saved at once.
/// - `save(prefs:scores:)` transcribes `_SaveGamePrefs @ 00026b36`: when the entry does not exist yet (the
///   original's `HCreate` path) the factory scores are loaded first and written.
/// - First run only: if nothing is stored and the original's prefs file is present, its bytes are copied in
///   (read-only — the file itself is never modified or deleted), then gated as above.
public final class BTXPrefsStore {
    public static let key = "Prefs"
    public static let domain = "com.ambrosiaclassics.bubbletroublex"
    /// The original's file: Preferences folder, name `STR# 129` item 5.
    public static var legacyFileURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Preferences/Bubble Trouble X Prefs")
    }

    private let defaults: UserDefaults
    private let legacyFileURL: URL?
    private let factoryScores: HighScoreTable

    /// - Parameters:
    ///   - legacyFileURL: the original prefs file to import on first run (`BTXPrefsStore.legacyFileURL`), or nil.
    ///   - factoryScores: `SCOR 128` (`HighScoreTable.factory(from:)`).
    public init(defaults: UserDefaults, legacyFileURL: URL?, factoryScores: HighScoreTable) {
        self.defaults = defaults
        self.legacyFileURL = legacyFileURL
        self.factoryScores = factoryScores
    }

    public func load() -> (prefs: BTXPrefs, scores: HighScoreTable) {
        if defaults.data(forKey: Self.key) == nil, let url = legacyFileURL,
           let legacy = try? Data(contentsOf: url) {
            defaults.set(legacy, forKey: Self.key)
        }
        guard let blob = defaults.data(forKey: Self.key) else { return (.defaults, factoryScores) }
        guard blob.count >= BTXPrefs.size,
              var prefs = BTXPrefs(data: blob.prefix(BTXPrefs.size)),
              prefs.version == BTXPrefs.currentVersion else {
            defaults.removeObject(forKey: Self.key)
            return (.defaults, factoryScores)
        }
        let tail = blob.dropFirst(BTXPrefs.size).prefix(HighScoreTable.size)
        var scores = HighScoreTable(data: tail) ?? factoryScores
        if !prefs.defaultScoresLoaded {
            prefs.defaultScoresLoaded = true
            scores = factoryScores
            write(prefs, scores)
        }
        return (prefs, scores)
    }

    /// Saves both; `scores` becomes the factory table when nothing was stored before (see type doc).
    public func save(prefs: BTXPrefs, scores: inout HighScoreTable) {
        if defaults.data(forKey: Self.key) == nil { scores = factoryScores }
        write(prefs, scores)
    }

    private func write(_ prefs: BTXPrefs, _ scores: HighScoreTable) {
        defaults.set(prefs.data + scores.data, forKey: Self.key)
    }
}
