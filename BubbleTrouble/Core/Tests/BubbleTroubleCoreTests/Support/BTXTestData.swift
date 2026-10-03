import BubbleTroubleCore
import Foundation
import XCTest

/// The Bubble Trouble X `Contents/Resources` folder for data-gated tests. Game data never enters git
/// (plan Invariant 3; Aki/Core + HectorKit D3 convention): the env var `variable` names the folder, and
/// a test that needs it throws `XCTSkip` — naming the variable — when it is unset or not a directory.
enum BTXTestData {
    static let variable = "HECTORKIT_DATA_BTX"

    static func resourcesDirectory(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> URL {
        guard let value = environment[variable], !value.isEmpty else {
            throw XCTSkip("\(variable) unset — set it to Bubble Trouble X.app/Contents/Resources")
        }
        let url = URL(fileURLWithPath: value).resolvingSymlinksInPath()
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw XCTSkip("\(variable)=\(value) is not a directory")
        }
        return url
    }

    static func files() throws -> BTXResourceFiles {
        try BTXResourceFiles(resourcesDirectory: resourcesDirectory())
    }
}
