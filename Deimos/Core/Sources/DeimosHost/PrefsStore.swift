import Foundation
import Synchronization
import DeimosCore

/// The settings store on disk (Phase 4 S4; grounding C §1b): the file "Deimos Rising Preferences" in a folder the
/// caller names (the app picks the real one, plan ruling 6). It keeps the record it read, so a save writes back every
/// byte the typed prefs do not carry.
///
/// - `load` (`FUN_10004540` → `FUN_10004f80`): a file that reads with version 0x2714 — even a short one — is the
///   record; a missing, unreadable or wrong-version file gives the fresh record, **written at once**. As the original,
///   a failed write of the fresh record does not stop the launch (it logged "ERROR: Couldn't save preferences").
/// - `save` (`FUN_10004640`): the typed prefs over the kept record, 0x34f0 bytes out. Called at quit only (the
///   driver's shutdown), as the original.
public final class PrefsStore: SettingsStore {
    /// The original's file name (`_DAT_100df59c + 0x5d`).
    public static let fileName = "Deimos Rising Preferences"

    public let folder: URL
    public var fileURL: URL { folder.appendingPathComponent(Self.fileName, isDirectory: false) }

    /// The record last read or written (nil before the first load or save).
    private let record = Mutex<PrefsFile?>(nil)

    public init(folder: URL) {
        self.folder = folder
    }

    public func load() throws -> DeimosPrefs {
        record.withLock { kept -> DeimosPrefs in
            let exists = FileManager.default.fileExists(atPath: fileURL.path)
            let data = try? Data(contentsOf: fileURL)
            if let data, let file = PrefsFile(fileBytes: [UInt8](data)) {
                kept = file
                return file.prefs
            }
            let fresh = PrefsFile.fresh
            kept = fresh
            // A file that is there but cannot be read is left alone: the original's open fails (L 10048a00) and its
            // fresh write's open fails the same way. Only a missing or wrong-version file is replaced.
            if !exists || data != nil { try? write(fresh) }
            return fresh.prefs
        }
    }

    public func save(_ prefs: DeimosPrefs) throws {
        // The write happens under the lock, so concurrent saves reach the disk in the order they took it.
        try record.withLock { kept in
            var file = kept ?? .fresh
            file.apply(prefs)
            kept = file
            try write(file)
        }
    }

    private func write(_ file: PrefsFile) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data(file.fileBytes).write(to: fileURL, options: .atomic)
    }
}
