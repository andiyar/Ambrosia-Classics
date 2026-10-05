import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import XCTest

/// The Bubble Trouble X `Contents/Resources` folder for the data-gated render tests (game data never enters
/// git). Unset `HECTORKIT_DATA_BTX` → `XCTSkip` naming the variable (G1 counts a skip as a failure, and the gate
/// always sets it); set but not a directory, or the files will not open → a thrown error (a loud failure).
enum RenderTestData {
    static let variable = "HECTORKIT_DATA_BTX"

    struct BadData: Error, CustomStringConvertible { let description: String }

    static func gameData() throws -> BTXGameData {
        guard let value = ProcessInfo.processInfo.environment[variable], !value.isEmpty else {
            throw XCTSkip("\(variable) unset — set it to Bubble Trouble X.app/Contents/Resources")
        }
        let url = URL(fileURLWithPath: value).resolvingSymlinksInPath()
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw BadData(description: "\(variable)=\(value) is not a directory")
        }
        return try BTXGameData(resourcesDirectory: url)
    }
}
