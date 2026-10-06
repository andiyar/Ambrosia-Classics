import BubbleTroubleCore
import Foundation

/// Start-up checks and wording for the shipped Windows build (plan W7). A GUI-subsystem `.exe` has no console, so a
/// failure to start must be said in a message box (the executable shows `message` through HectorSDL) and written to
/// `BubbleTroubleX.log` (`WinLog`) — the tester can send that file back.
public enum WinStartup {
    /// The baked font faces (`btx-bake-font`'s list), all shipped and checked: the game draws with Geneva 9
    /// (`_DrawInterfaceText`) and System 12 (the dialogs, `_DrawFPS`); Geneva 10 and System Bold 12 drew the menu bar
    /// and the About panel, both gone since D21 — still baked and shipped, read by nothing.
    public static let requiredFonts = ["Geneva-9", "Geneva-10", "System-12", "System-Bold-12"].map { "\($0).btxfont" }

    /// What the game needs in `Data/` (D10, D16.1): the five original `.rsrc` files, every baked font face
    /// (`requiredFonts`), and — off Apple, where there is no QuickTime-JPEG decoder — every pre-decoded band
    /// `btx-predecode` wrote, as its `Decoded/manifest.txt` lists them (`BTXPredecode.manifestName`). Names are
    /// relative to `dataDirectory`, Windows-style; more than four missing bands are summed up in one entry.
    public static func missingData(in dataDirectory: URL, needsDecoded: Bool = !canDecodeJPEG) -> [String] {
        let fm = FileManager.default
        func exists(_ parts: String...) -> Bool {
            fm.fileExists(atPath: parts.reduce(dataDirectory) { $0.appendingPathComponent($1) }.path)
        }
        var missing = BTXGameData.allFileNames.filter { !exists($0) }
        missing += requiredFonts.filter { !exists("Fonts", $0) }.map { "Fonts\\\($0)" }
        if needsDecoded {
            let manifest = dataDirectory.appendingPathComponent("Decoded", isDirectory: true)
                .appendingPathComponent(BTXPredecode.manifestName)
            let keys = ((try? String(contentsOf: manifest, encoding: .utf8)) ?? "")
                .split(whereSeparator: \.isNewline).map(String.init).filter { !$0.isEmpty }
            if keys.isEmpty {
                missing.append("Decoded\\\(BTXPredecode.manifestName)")
            } else {
                let absent = keys.filter { !exists("Decoded", "\($0).rgba") }.map { "Decoded\\\($0).rgba" }
                missing += absent.count > 4 ? ["Decoded\\*.rgba (\(absent.count) of \(keys.count))"] : absent
            }
        }
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
        #if os(Windows)
        let eol = "\r\n"
        #else
        let eol = "\n"
        #endif
        let now = Date()
        lock.lock()
        defer { lock.unlock() }
        guard let handle else { return }
        let data = Data("\(Self.stamp(now)) \(line)\(eol)".utf8)
        do {
            try handle.write(contentsOf: data)
        } catch {
            self.handle = nil                          // stop trying; never let the log take the game down
        }
    }

    /// Made once; used only under `lock` (by `write`) or from a test.
    nonisolated(unsafe) private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()

    static func stamp(_ date: Date) -> String { formatter.string(from: date) }
}
