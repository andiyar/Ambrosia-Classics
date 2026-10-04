import BubbleTroubleCore
import Foundation

/// The only file-system entry point (plan S5): the original's `Contents/Resources` files, shipped unchanged in this
/// app's own `Contents/Resources` (D10) and resolved by their original names (Aki `AkiAssets` pattern).
@MainActor final class BTXAssets {
    let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    /// The directory holding the five `.rsrc` files (`BTXGameData(resourcesDirectory:)`).
    var resourcesDirectory: URL? { bundle.resourceURL }

    /// The exact shipped file name, e.g. `url("BT Sounds.rsrc")`; nil when the bundle lacks it.
    func url(_ fileName: String) -> URL? {
        guard let resources = bundle.resourceURL else { return nil }
        let url = resources.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    #if DEBUG
    /// Dev-build launch check only (Invariant 6, Aki Known delta 7 precedent): the original files the game cannot
    /// start without that this bundle lacks. Compiled out of Release.
    func missingFiles() -> [String] {
        BTXGameData.allFileNames.filter { url($0) == nil }
    }
    #endif
}
