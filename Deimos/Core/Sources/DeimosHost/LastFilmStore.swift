import Foundation
import DeimosCore

/// The Last Film store on disk (Phase 4 S5; plan ruling 7; grounding B §4b): the front end's `LastFilmStore`, saving
/// the recorded film image as `<root>/Local/film/Last Film[last].film` — the original's
/// `FUN_100095b0(film, 'last')` → `FUN_100025b0('film', 'last', data, "Last Film", 1, 1)` → `Data:Local:film:Last
/// Film[last].film`. A launch's tag index finds it through its second Local root (`localRoot`,
/// `TagIndex(dataDirectory:secondLocalRoot:)`), ahead of the shipped copy.
///
/// Listing reads (`FUN_10002640`, `10002640..10002840`): the path is `Data:Local:` + the type's folder + the tag file
/// name (`FUN_10004230`); the file is created with type/creator `Data`/`Deim` (permission 0x17 for the first 1 —
/// not carried: no resource fork or Finder info here), opened, written whole; on success, with the second 1, the tag
/// index is rebuilt (`FUN_100016c0(0, 0)`: the boot scan again, no log lines). Each failure — create, open, write — is
/// only a debug log line (`FUN_10049550`, written when the log flag is set) and nothing else: no alert, the game goes
/// on. Here a failure throws, and the driver drops it (S1b), which is the same to the player. Within one run the
/// front end replays the film from memory (`FrontEndState.lastFilm`); the rebuild is the next launch's index.
public struct LastFilmFileStore: LastFilmStore {
    /// The original's file name for tag `last` of type `film`, display name "Last Film" (`FUN_10004230`).
    public static let fileName = "Last Film[last].film"

    /// The default root: `~/Library/Application Support/Ambrosia Classics/Deimos Rising` (plan ruling 7, beside the
    /// settings file of ruling 6).
    public static var defaultRoot: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("Ambrosia Classics", isDirectory: true)
            .appendingPathComponent("Deimos Rising", isDirectory: true)
    }

    public let root: URL
    /// `<root>/Local`: the second Local root for the tag index.
    public var localRoot: URL { root.appendingPathComponent("Local", isDirectory: true) }
    /// `<root>/Local/film/Last Film[last].film`.
    public var fileURL: URL {
        localRoot.appendingPathComponent("film", isDirectory: true).appendingPathComponent(Self.fileName)
    }

    public init(root: URL = LastFilmFileStore.defaultRoot) {
        self.root = root
    }

    /// Writes the image whole, making the folders first; a second save replaces the first.
    public func save(_ film: [UInt8]) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(film).write(to: fileURL, options: .atomic)
    }

    /// The saved image, or nil when none has been saved; a file that is not exactly `Film.size` bytes throws
    /// (`FilmError.wrongSize`).
    public func load() throws -> [UInt8]? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let bytes = [UInt8](try Data(contentsOf: fileURL))
        guard bytes.count == Film.size else { throw FilmError.wrongSize(bytes.count) }
        return bytes
    }
}
