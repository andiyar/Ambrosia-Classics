import Foundation
import HectorResources

/// The prefs file: a classic resource file holding `'Pref'` id 0 named "Preferences" (`AddResource(h,'Pref',0,
/// 0x100a3199)`, `.InitPrefs` M l. 7694ff), the body `FerazelPrefs.record()`. The original keeps it in the System
/// Folder's Preferences (`.SetPrefFile(0x100a2c80, '????', 'pref', …)`); the replica reads and writes it at a URL the
/// App passes (Application Support, D35 Known deviation 3). The map is in the data fork (`ClassicResourceMap`).
public enum PrefsFile {
    /// "Ferazel's Wand Prefs" (pstr `0x100a2c80`).
    public static let fileName = "Ferazel's Wand Prefs"
    public static let resourceType = "Pref"
    public static let resourceID: Int16 = 0
    /// "Preferences" (pstr `0x100a3199`).
    public static let resourceName = "Preferences"

    /// The `'Pref'` 0 record as stored, or nil when there is none — no file, a file that is not a resource map, or a
    /// map without `'Pref'` 0 — the cases where `.InitPrefs`' `Get1Resource` returns nil and the defaults are made
    /// (`FerazelPrefs()`). The record is returned at its stored length (`FerazelPrefs(record:)` grows it).
    public static func read(from url: URL) throws -> Data? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        guard ClassicResourceMap.sniff(data),
              let map = try? ClassicResourceMap.parse(data),
              let res = map.resource(type: resourceType, id: resourceID) else { return nil }
        return res.data
    }

    /// Writes `record` as the file's only resource (`AddResource` / `ChangedResource` + `WriteResource`).
    public static func write(_ record: Data, to url: URL) throws {
        let map = ClassicResourceMap.serialize([Resource(type: resourceType, id: resourceID, name: resourceName,
                                                         data: record)])
        try map.write(to: url, options: .atomic)
    }
}
