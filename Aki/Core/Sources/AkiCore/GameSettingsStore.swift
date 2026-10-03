import Foundation

/// Loads and saves `GameSettings` the way `_LoadPrefs` / `_SavePrefs` do: one `NSData` under the
/// `GameSettings` defaults key; when the key is absent, the 1.1 `Aki Prefs` file is migrated
/// (docs/aki/file-formats.md §2.3) — never written back.
public struct GameSettingsStore {
    public let defaults: UserDefaults
    public let legacyPrefsURL: URL?

    public init(defaults: UserDefaults = .standard,
                legacyPrefsURL: URL? = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?
                    .appendingPathComponent("Preferences/Aki Prefs")) {
        self.defaults = defaults
        self.legacyPrefsURL = legacyPrefsURL
    }

    /// Key present → its blob decoded (defaults if it is not a ≥ 143-byte `Data`); key absent →
    /// the migrated 1.1 file, else the defaults.
    public func load() -> GameSettings {
        if let value = defaults.object(forKey: GameSettings.defaultsKey) {
            guard let data = value as? Data, let settings = try? GameSettings(blob: data) else { return .defaults }
            return settings
        }
        if let legacyPrefsURL, let data = try? Data(contentsOf: legacyPrefsURL),
           let migrated = GameSettings.migrating(akiPrefs11: data) {
            return migrated
        }
        return .defaults
    }

    /// `_SavePrefs`: `setObject:blob forKey:"GameSettings"`.
    public func save(_ settings: GameSettings) {
        defaults.set(settings.blob, forKey: GameSettings.defaultsKey)
    }
}
