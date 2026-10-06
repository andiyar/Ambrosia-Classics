import Foundation

public enum DeimosDataError: Error, Equatable {
    case notFound(String)
}

/// Where the original Deimos Rising 1.0.6 `Data` folder lives (DECISIONS D24): the repo's committed
/// copy `Resources/Deimos/Data` (`Paks/` + `Local/`), or `DEIMOS_DATA` when set.
public enum DeimosData {
    public static let environmentVariable = "DEIMOS_DATA"

    /// `DEIMOS_DATA` if set (must be a directory), else the repo's `Resources/Deimos/Data`, found by
    /// walking up from this source file with symlinks resolved (worktrees reach HectorKit through a
    /// symlink; Windows-safe: no symlink enumeration, just path resolution).
    public static func dataDirectory() throws -> URL {
        let fm = FileManager.default
        if let env = ProcessInfo.processInfo.environment[environmentVariable], !env.isEmpty {
            let url = URL(fileURLWithPath: env, isDirectory: true).resolvingSymlinksInPath()
            guard isDirectory(url, fm) else { throw DeimosDataError.notFound("\(environmentVariable)=\(env) is not a directory") }
            return url
        }
        var dir = URL(fileURLWithPath: #filePath).resolvingSymlinksInPath().deletingLastPathComponent()
        while dir.pathComponents.count > 1 {
            let candidate = dir.appendingPathComponent("Resources/Deimos/Data", isDirectory: true)
            if isDirectory(candidate, fm) { return candidate }
            dir = dir.deletingLastPathComponent()
        }
        throw DeimosDataError.notFound("no Resources/Deimos/Data above \(#filePath); set \(environmentVariable)")
    }

    private static func isDirectory(_ url: URL, _ fm: FileManager) -> Bool {
        var isDir: ObjCBool = false
        return fm.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }
}
