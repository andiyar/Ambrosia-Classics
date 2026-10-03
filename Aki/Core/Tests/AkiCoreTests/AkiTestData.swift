import AkiCore
import Foundation
import XCTest

/// An Aki `Contents/Resources` folder for the data-gated census tests: env var `variable` if set,
/// else the repo's git-ignored symlink `Resources/Aki/<app>/Contents/Resources` (docs/DECISIONS.md
/// D1). XCTSkip — naming the variable — when neither exists.
func akiResources(_ variable: String, defaultApp app: String) throws -> URL {
    var repo = URL(fileURLWithPath: #filePath)                 // …/Aki/Core/Tests/AkiCoreTests/<file>
    for _ in 0..<5 { repo.deleteLastPathComponent() }          // → the repo (or worktree) root
    let env = ProcessInfo.processInfo.environment[variable].flatMap { $0.isEmpty ? nil : $0 }
    let path = env ?? repo.appendingPathComponent("Resources/Aki/\(app)/Contents/Resources").path
    let url = URL(fileURLWithPath: path).resolvingSymlinksInPath()
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
        if let env { throw XCTSkip("\(variable)=\(env) is not a directory") }
        throw XCTSkip("\(variable) unset and the default \(path) is absent — set \(variable) to an Aki Contents/Resources folder")
    }
    return url
}

func aki11() throws -> AkiBundle {
    try AkiBundle(resourcesURL: akiResources("AKI_DATA_11", defaultApp: "1.1.0.app"))
}
func aki12() throws -> AkiBundle {
    try AkiBundle(resourcesURL: akiResources("AKI_DATA_12", defaultApp: "1.2.0.app"))
}

/// A file inside the 1.2.0 bundle's `<language>.lproj` (e.g. `akiLproj("English", "Preferences.nib/designable.nib")`).
/// Skips (via `akiResources`) when the 1.2.0 data is absent.
func akiLproj(_ language: String, _ relative: String) throws -> Data {
    try Data(contentsOf: akiResources("AKI_DATA_12", defaultApp: "1.2.0.app")
        .appendingPathComponent("\(language).lproj").appendingPathComponent(relative))
}
