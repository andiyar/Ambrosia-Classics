import DeimosCore
import Foundation

/// The only file-system entry point (plan S8, design §7.7): the original 1.0.6 `Data` folder (`Paks` + `Local`),
/// shipped unchanged in this app at `Contents/Resources/Deimos/Data` by `tools/stage-deimos.sh` (D10/D24).
extension DeimosAssets {
    /// A file the game cannot start without; its presence marks a usable `Data` folder.
    static let markerFile = "Paks/Game.pak"

    /// The bundle's `Contents/Resources/Deimos/Data` when it holds the data. In DEBUG only, when the bundle lacks
    /// it (an unstaged Xcode build), the `DEIMOS_DATA` environment variable names a `Data` folder instead
    /// (e.g. the repo's `Resources/Deimos/Data`). Nil when neither has it.
    static func dataDirectory(bundle: Bundle = .main) -> URL? {
        if let resources = bundle.resourceURL {
            let dir = resources.appendingPathComponent("Deimos/Data", isDirectory: true)
            if holdsData(dir) { return dir }
        }
        #if DEBUG
        if let path = ProcessInfo.processInfo.environment["DEIMOS_DATA"], !path.isEmpty {
            let dir = URL(fileURLWithPath: path, isDirectory: true)
            if holdsData(dir) { return dir }
        }
        #endif
        return nil
    }

    /// `Data` folder → `TagIndex(dataDirectory:)` → `DeimosAssets.load(index:)`.
    static func load(dataDirectory dir: URL) throws -> DeimosAssets {
        try load(index: TagIndex(dataDirectory: dir))
    }

    private static func holdsData(_ dir: URL) -> Bool {
        FileManager.default.fileExists(atPath: dir.appendingPathComponent(markerFile).path)
    }
}
