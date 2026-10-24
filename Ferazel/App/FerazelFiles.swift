import FerazelCore
import Foundation

/// The App's side of Core's file seam (plan S2 `FrontFiles`, A1a; design §7.5, D35 Known deviation 3): the prefs file
/// "Ferazel's Wand Prefs" and the default home of saved games live in `~/Library/Application Support/Ambrosia
/// Classics/Ferazel's Wand/` (the original kept the prefs in the System Folder's Preferences), created on demand. The
/// codecs are Core's (`PrefsFile`, `SavedGameFile`, SV2); a saved game is wherever the player's panel put it. Nothing
/// here deletes or resets a user file or the `com.ambrosiaclassics.*` defaults (Invariant 8); the only removal is
/// `.SaveSG`'s own delete-then-write of the file the player chose to save over (`SavedGameFile.write`).
final class FerazelFiles: FrontFiles {
    /// `~/Library/Application Support/Ambrosia Classics/Ferazel's Wand/`.
    let folder: URL

    init(fileManager: FileManager = .default) {
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        folder = support.appendingPathComponent("Ambrosia Classics", isDirectory: true)
            .appendingPathComponent("Ferazel's Wand", isDirectory: true)
    }

    /// The prefs file's place in `folder`.
    var prefsURL: URL { folder.appendingPathComponent(PrefsFile.fileName) }

    /// Creates `folder` (and its parents) when it is missing; returns it.
    @discardableResult
    func ensureFolder() throws -> URL {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    // MARK: FrontFiles

    func loadPrefs() -> Data? {
        PrefsFile.read(from: prefsURL)
    }

    func storePrefs(_ record: Data) throws {
        try ensureFolder()
        try PrefsFile.write(record, to: prefsURL)
    }

    func readSavedGame(_ ref: SavedGameRef) throws -> SaveBlock {
        try SavedGameFile.read(from: ref.url)
    }

    func writeSavedGame(_ block: SaveBlock, to ref: SavedGameRef) throws(SaveWriteError) {
        do {
            try SavedGameFile.write(block, to: ref.url)
        } catch {
            throw SaveWriteError(error)
        }
    }
}
