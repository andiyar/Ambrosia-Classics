import FerazelCore
import Foundation

/// Start-up checks and wording for the Windows build (plan WF3, D43 Ruling 12; BTX `WinStartup.swift`'s shape). A
/// GUI-subsystem `.exe` has no console, so a failure to start is said in a message box (the executable shows the
/// message through HectorSDL; never in `--frames` mode) and written to `Ferazel's Wand.log` beside the prefs (`WinLog`).
/// The message box shows in Release too, where the Mac shows its alert only in DEBUG builds: the Mac's data sits
/// sealed in the app bundle, while `Data\` lies loose beside the exe and is lost by copying the exe alone.
public enum WinStartup {
    /// The baked faces (`fz-bake-font`'s set, D43 Ruling 2): the game's four and the dialogs' UI font bold 12.
    public static let requiredFonts = ["0-12-1", "20-12-1", "20-18-0", "3-8-1", "3-9-0"].map { "\($0).fzfont" }

    /// The original data (`Resources/Ferazel` unchanged: six `.rsrc` + the music folder, D10).
    public static let requiredData = [FerazelData.appFile, FerazelData.worldFile, FerazelData.backgroundsFile,
                                      FerazelData.spritesFile, FerazelData.soundsFile, FerazelData.titlesFile]

    /// What is missing: every original file, the music folder, every baked face. Names are relative to
    /// `dataDirectory`, Windows-style; with `fonts` given (`--fonts`) a missing face is named by its full path.
    public static func missingData(in dataDirectory: URL, fonts: URL? = nil) -> [String] {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        var missing = requiredData.filter { name in
            !(fm.fileExists(atPath: dataDirectory.appendingPathComponent(name).path, isDirectory: &isDir) && !isDir.boolValue)
        }
        let music = dataDirectory.appendingPathComponent(FerazelData.musicFolder, isDirectory: true)
        if !(fm.fileExists(atPath: music.path, isDirectory: &isDir) && isDir.boolValue) {
            missing.append(FerazelData.musicFolder)
        }
        let fontsDir = fonts ?? dataDirectory.appendingPathComponent("Fonts", isDirectory: true)
        for f in requiredFonts where !fm.fileExists(atPath: fontsDir.appendingPathComponent(f).path) {
            missing.append(fonts == nil ? "Fonts\\\(f)" : displayPath(fontsDir.appendingPathComponent(f)))
        }
        return missing
    }

    /// The message box text when the data folder is missing or incomplete.
    public static func dataMissingMessage(dataDirectory: URL, missing: [String], logURL: URL?) -> String {
        var text = "Ferazel's Wand cannot find its game data.\n\n"
            + "It looks for the folder \"Data\" next to \"Ferazel's Wand.exe\":\n\(displayPath(dataDirectory))\n\n"
            + "Missing: \(missing.joined(separator: ", "))\n\n"
            + "Unzip the whole \"Ferazel's Wand (Windows)\" folder first (do not run the game from inside the zip), "
            + "and keep the Data folder beside the .exe."
        if let logURL { text += "\n\nDetails: \(displayPath(logURL))" }
        return text
    }

    /// The message box text for any other failure to start (`what` says which step failed).
    public static func failureMessage(_ what: String, error: Error, logURL: URL?) -> String {
        var text = "Ferazel's Wand could not start: \(what).\n\n\(error)"
        if let logURL { text += "\n\nDetails: \(displayPath(logURL))" }
        return text
    }

    /// A path as Windows writes it (backslashes) on Windows; unchanged elsewhere. Pure Swift (Ruling 18).
    public static func displayPath(_ url: URL) -> String {
        #if os(Windows)
        String(url.withUnsafeFileSystemRepresentation { $0.map { String(cString: $0) } ?? url.path }
            .map { $0 == "/" ? "\\" : $0 })
        #else
        url.path
        #endif
    }

    /// `message` on one line (" — " between its lines), for stderr and the log. Pure Swift (Ruling 18).
    public static func oneLine(_ message: String) -> String {
        message.split(separator: "\n").joined(separator: " — ")
    }
}

/// `Ferazel's Wand.log`, beside the prefs file: the start-up facts and every reported problem of the last launch
/// (rewritten at each launch; BTX `WinLog`). Thread-safe; a log that cannot be written is silently skipped (the game
/// must never fail because of it). Never `FileHandle.standardError` (Ruling 18): a file handle of its own.
public final class WinLog: @unchecked Sendable {
    public static let fileName = "Ferazel's Wand.log"

    public let url: URL
    private let lock = NSLock()
    private var handle: FileHandle?

    /// Creates the folder and truncates the file; nil when it cannot be opened.
    public init?(url: URL) {
        self.url = url
        let fm = FileManager.default
        do {
            try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            guard fm.createFile(atPath: url.path, contents: nil) else { return nil }
            handle = try FileHandle(forWritingTo: url)
        } catch {
            return nil
        }
    }

    /// The log beside a prefs file.
    public convenience init?(besidePrefs prefsURL: URL) {
        self.init(url: prefsURL.deletingLastPathComponent().appendingPathComponent(Self.fileName))
    }

    deinit { try? handle?.close() }

    /// One line, stamped with the local time (CRLF on Windows, so Notepad shows the lines).
    public func write(_ line: String) {
        #if os(Windows)
        let eol = "\r\n"
        #else
        let eol = "\n"
        #endif
        let now = Date()
        lock.lock()
        defer { lock.unlock() }
        guard let handle else { return }
        do {
            try handle.write(contentsOf: Data("\(Self.stamp(now)) \(line)\(eol)".utf8))
        } catch {
            self.handle = nil                          // stop trying; never let the log take the game down
        }
    }

    /// Made once; used only under `lock` (by `write`).
    nonisolated(unsafe) private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()

    static func stamp(_ date: Date) -> String { formatter.string(from: date) }
}
