import BubbleTroubleCore
import Foundation

/// The Windows port's prefs store (DECISIONS D16.3): `BTXPrefsStore`'s one blob (the original prefs file's data-fork
/// image, under the key `Prefs`) kept in a plain file, because `UserDefaults` crashes under Wine. Never touches
/// `UserDefaults`, and never the Mac app's domain `com.ambrosiaclassics.bubbletroublex` (Ben's play data).
///
/// The key `Prefs` lives in `fileURL`; any other key (none is used) in a sibling `<key>.bin`. Writes are atomic
/// (temporary file + replace), creating the folder when needed; a failed write is reported through `log`.
public final class WinPrefsFile: BTXPrefsBacking {
    public let fileURL: URL
    private let log: (String) -> Void

    public init(fileURL: URL, log: @escaping (String) -> Void = { _ in }) {
        self.fileURL = fileURL
        self.log = log
    }

    /// Where the blob lives by default:
    /// - Windows: `%APPDATA%\Ambrosia Classics\Bubble Trouble X\Prefs.bin`;
    /// - elsewhere (the Mac SDL development build): `~/Library/Application Support/Ambrosia Classics/Bubble Trouble X
    ///   (SDL)/Prefs.bin` — its own folder, apart from the Mac replica's `UserDefaults` domain.
    /// nil when Windows has no `APPDATA`.
    public static func defaultURL(environment: [String: String] = ProcessInfo.processInfo.environment,
                                  windows: Bool = isWindows,
                                  home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL? {
        if windows {
            guard let appData = environment["APPDATA"], !appData.isEmpty else { return nil }
            return URL(fileURLWithPath: appData, isDirectory: true)
                .appendingPathComponent("Ambrosia Classics", isDirectory: true)
                .appendingPathComponent("Bubble Trouble X", isDirectory: true)
                .appendingPathComponent("Prefs.bin")
        }
        return home.appendingPathComponent("Library/Application Support/Ambrosia Classics", isDirectory: true)
            .appendingPathComponent("Bubble Trouble X (SDL)", isDirectory: true)
            .appendingPathComponent("Prefs.bin")
    }

    public static var isWindows: Bool {
        #if os(Windows)
        true
        #else
        false
        #endif
    }

    private func url(forKey key: String) -> URL {
        key == BTXPrefsStore.key ? fileURL
            : fileURL.deletingLastPathComponent().appendingPathComponent("\(key).bin")
    }

    public func data(forKey key: String) -> Data? {
        try? Data(contentsOf: url(forKey: key))
    }

    public func set(_ value: Data, forKey key: String) {
        let target = url(forKey: key)
        do {
            try FileManager.default.createDirectory(at: target.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try value.write(to: target, options: .atomic)
        } catch {
            log("cannot save the prefs to \(target.path): \(error)")
        }
    }

    public func removeObject(forKey key: String) {
        let target = url(forKey: key)
        guard FileManager.default.fileExists(atPath: target.path) else { return }
        do { try FileManager.default.removeItem(at: target) } catch {
            log("cannot remove \(target.path): \(error)")
        }
    }
}

/// Prefs kept in memory only — the headless smoke mode (`--frames` without `--prefs`), so a scripted run never
/// depends on, or writes, a player's saved prefs.
public final class WinMemoryPrefs: BTXPrefsBacking {
    public private(set) var values: [String: Data] = [:]
    /// Every `set` call, in order (tests read the save count).
    public private(set) var writes: [String] = []

    public init() {}

    public func data(forKey key: String) -> Data? { values[key] }

    public func set(_ value: Data, forKey key: String) {
        values[key] = value
        writes.append(key)
    }

    public func removeObject(forKey key: String) { values[key] = nil }
}
