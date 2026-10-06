import BubbleTroubleCore
import Foundation

/// Start-up checks and wording for the shipped Windows build (plan W7). A GUI-subsystem `.exe` has no console, so a
/// failure to start must be said in a message box (the executable shows `message` through HectorSDL) and written to
/// `BubbleTroubleX.log` (`WinLog`) — the tester can send that file back.
public enum WinStartup {
    /// What the game needs in `Data/` (D10, D16.1): the five original `.rsrc` files, the baked fonts, and — off Apple,
    /// where there is no QuickTime-JPEG decoder — the pre-decoded level backgrounds.
    public static func missingData(in dataDirectory: URL, needsDecoded: Bool = !canDecodeJPEG) -> [String] {
        let fm = FileManager.default
        var missing = BTXGameData.allFileNames.filter {
            !fm.fileExists(atPath: dataDirectory.appendingPathComponent($0).path)
        }
        func hasFiles(_ name: String, suffix: String) -> Bool {
            let dir = dataDirectory.appendingPathComponent(name, isDirectory: true)
            return ((try? fm.contentsOfDirectory(atPath: dir.path)) ?? []).contains { $0.hasSuffix(suffix) }
        }
        if !hasFiles("Fonts", suffix: ".btxfont") { missing.append("Fonts\\*.btxfont") }
        if needsDecoded && !hasFiles("Decoded", suffix: ".rgba") { missing.append("Decoded\\*.rgba") }
        return missing
    }

    public static var canDecodeJPEG: Bool {
        #if canImport(ImageIO)
        true
        #else
        false
        #endif
    }

    /// The message box text when the data folder is missing or incomplete.
    public static func dataMissingMessage(dataDirectory: URL, missing: [String], logURL: URL?) -> String {
        var text = "Bubble Trouble X cannot find its game data.\n\n"
            + "It looks for the folder \"Data\" next to \"Bubble Trouble X.exe\":\n\(displayPath(dataDirectory))\n\n"
            + "Missing: \(missing.joined(separator: ", "))\n\n"
            + "Unzip the whole \"Bubble Trouble X (Windows)\" folder first (do not run the game from inside the zip), "
            + "and keep the Data folder beside the .exe."
        if let logURL { text += "\n\nDetails: \(displayPath(logURL))" }
        return text
    }

    /// The message box text for any other failure to start (`what` says which step failed).
    public static func failureMessage(_ what: String, error: Error, logURL: URL?) -> String {
        var text = "Bubble Trouble X could not start: \(what).\n\n\(error)"
        if let logURL { text += "\n\nDetails: \(displayPath(logURL))" }
        return text
    }

    /// A path as Windows writes it (backslashes) on Windows; unchanged elsewhere.
    public static func displayPath(_ url: URL) -> String {
        #if os(Windows)
        // (pure Swift, not Foundation's replacingOccurrences, which traps on Windows for some patterns — W7)
        String(url.withUnsafeFileSystemRepresentation { $0.map { String(cString: $0) } ?? url.path }
            .map { $0 == "/" ? "\\" : $0 })
        #else
        url.path
        #endif
    }
}

/// `BubbleTroubleX.log`, next to the prefs file (`%APPDATA%\Ambrosia Classics\Bubble Trouble X\` by default): the
/// start-up facts and every reported problem of the last launch (rewritten at each launch). Thread-safe; a log that
/// cannot be written is silently skipped (the game must never fail because of it).
public final class WinLog: @unchecked Sendable {
    public static let fileName = "BubbleTroubleX.log"

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
        let stamp = Self.stamp(Date())
        #if os(Windows)
        let eol = "\r\n"
        #else
        let eol = "\n"
        #endif
        let data = Data("\(stamp) \(line)\(eol)".utf8)
        lock.lock()
        defer { lock.unlock() }
        guard let handle else { return }
        do {
            try handle.write(contentsOf: data)
        } catch {
            self.handle = nil                          // stop trying; never let the log take the game down
        }
    }

    static func stamp(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f.string(from: date)
    }
}
