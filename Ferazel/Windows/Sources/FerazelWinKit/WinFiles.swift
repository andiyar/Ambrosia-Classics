import FerazelCore
import Foundation

/// The Windows shell's side of Core's file seam (plan WF3, D43 Ruling 10; the Mac's `FerazelFiles` shape): the prefs
/// file (`PrefsFile.fileName`, the same 0x942-byte record the Mac writes) and the saved games' start folder live in
/// `%APPDATA%\Ambrosia Classics\Ferazel's Wand\` — on the Mac SDL development build in `~/Library/Application
/// Support/Ambrosia Classics/Ferazel's Wand (SDL)/`, never the Mac app's folder. `--prefs` / `--saves` override; with
/// no prefs file (the `--frames` mode) the record lives in memory. Never `UserDefaults` (D16.3). Nothing here deletes a
/// user file; the only removal is `.SaveSG`'s own delete-then-write of the file the player chose (`SavedGameFile`).
public final class WinFiles: FrontFiles {
    public static let companyFolder = "Ambrosia Classics"
    public static let gameFolder = "Ferazel's Wand"
    /// The Mac SDL development build's folder (apart from the Mac app's).
    public static let developmentFolder = "Ferazel's Wand (SDL)"

    /// The prefs file; nil = kept in memory.
    public let prefsURL: URL?
    /// The save / open dialogs' start folder; nil = none (the dialog's own).
    public let savesFolder: URL?
    private var memoryPrefs: Data?

    public init(prefsURL: URL?, savesFolder: URL?) {
        self.prefsURL = prefsURL
        self.savesFolder = savesFolder
    }

    public enum FolderError: Error, Equatable {
        case noAppData

        public var message: String {
            switch self {
            case .noAppData: "APPDATA is not set: the prefs and saved games cannot be kept"
            }
        }
    }

    /// The default folder: Windows — `%APPDATA%\Ambrosia Classics\Ferazel's Wand` (throws without `APPDATA`);
    /// elsewhere — `~/Library/Application Support/Ambrosia Classics/Ferazel's Wand (SDL)`.
    public static func defaultFolder(environment: [String: String] = ProcessInfo.processInfo.environment,
                                     windows: Bool = isWindows,
                                     home: URL = FileManager.default.homeDirectoryForCurrentUser) throws(FolderError)
        -> URL {
        if windows {
            guard let appData = environment["APPDATA"], !appData.isEmpty else { throw .noAppData }
            return URL(fileURLWithPath: appData, isDirectory: true)
                .appendingPathComponent(companyFolder, isDirectory: true)
                .appendingPathComponent(gameFolder, isDirectory: true)
        }
        return home.appendingPathComponent("Library/Application Support", isDirectory: true)
            .appendingPathComponent(companyFolder, isDirectory: true)
            .appendingPathComponent(developmentFolder, isDirectory: true)
    }

    public static var isWindows: Bool {
        #if os(Windows)
        true
        #else
        false
        #endif
    }

    /// Creates the saves folder (and its parents) when it is missing; returns it (nil when there is none).
    @discardableResult
    public func ensureSavesFolder() throws -> URL? {
        guard let savesFolder else { return nil }
        try FileManager.default.createDirectory(at: savesFolder, withIntermediateDirectories: true)
        return savesFolder
    }

    /// A default save name made Windows-legal (Ruling 10): each of `\ / : * ? " < > |` and every control character
    /// → "-", trailing dots and spaces dropped, a reserved device name (CON, PRN, AUX, NUL, COM1–9, LPT1–9, any case,
    /// with or without an extension) gets "_" after it; no extension is added. Pure Swift (no `replacingOccurrences`,
    /// Ruling 18).
    public static func legalSaveName(_ name: String) -> String {
        let illegal: Set<Unicode.Scalar> = ["\\", "/", ":", "*", "?", "\"", "<", ">", "|"]
        var scalars = String.UnicodeScalarView()
        for s in name.unicodeScalars {
            scalars.append(illegal.contains(s) || s.value < 0x20 || s.value == 0x7F ? "-" : s)
        }
        var out = String(scalars)
        while let last = out.last, last == "." || last == " " { out.removeLast() }
        let stem = out.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? out
        let reserved = ["CON", "PRN", "AUX", "NUL"] + (1...9).flatMap { ["COM\($0)", "LPT\($0)"] }
        if reserved.contains(stem.uppercased()) {
            out = stem + "_" + out.dropFirst(stem.count)
        }
        return out
    }

    // MARK: FrontFiles

    public func loadPrefs() -> Data? {
        guard let prefsURL else { return memoryPrefs }
        return PrefsFile.read(from: prefsURL)
    }

    public func storePrefs(_ record: Data) throws {
        guard let prefsURL else {
            memoryPrefs = record
            return
        }
        try FileManager.default.createDirectory(at: prefsURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try PrefsFile.write(record, to: prefsURL)
    }

    public func readSavedGame(_ ref: SavedGameRef) throws -> SaveBlock {
        try SavedGameFile.read(from: ref.url)
    }

    public func writeSavedGame(_ block: SaveBlock, to ref: SavedGameRef) throws(SaveWriteError) {
        do {
            try SavedGameFile.write(block, to: ref.url)
        } catch {
            throw SaveWriteError(error)
        }
    }
}
