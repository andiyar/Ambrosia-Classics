import FerazelCore
import Foundation

/// The only file-system entry point (plan S5, S7): the original Ferazel's Wand 1.0.3 data — the six `.rsrc` files and
/// `Ferazel's Wand Music` — shipped unchanged in this app at `Contents/Resources/Ferazel/` by `tools/stage-ferazel.sh`
/// (D10, D26).
enum FerazelAssets {
    /// The bundle's `Contents/Resources/Ferazel` when it holds the data. In DEBUG only, when the bundle lacks it (an
    /// unstaged Xcode build), `FERAZEL_DATA` names the folder instead (e.g. the repo's `Resources/Ferazel`). Nil when
    /// neither has it.
    static func dataDirectory(bundle: Bundle = .main) -> URL? {
        if let resources = bundle.resourceURL {
            let dir = resources.appendingPathComponent("Ferazel", isDirectory: true)
            if holdsData(dir) { return dir }
        }
        #if DEBUG
        if let path = ProcessInfo.processInfo.environment[FerazelData.environmentVariable], !path.isEmpty {
            let dir = URL(fileURLWithPath: path, isDirectory: true)
            if holdsData(dir) { return dir }
        }
        #endif
        return nil
    }

    /// The app's resource fork marks a usable data folder; `FerazelData.open` then names any other missing file.
    private static func holdsData(_ dir: URL) -> Bool {
        FileManager.default.fileExists(atPath: dir.appendingPathComponent(FerazelData.appFile).path)
    }
}
