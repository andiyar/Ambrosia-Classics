import Foundation

public enum CytheraDataError: Error, Equatable {
    /// The named data file (or the data directory itself) is not there.
    case notFound(String)
    /// The file at this path is there but is not a readable resource map: (path, what went wrong).
    case unreadable(String, String)
}

/// Where the original Cythera 1.0.4 data lives (DECISIONS D28, D24.3 shape): the repo's committed copy
/// `Resources/Cythera` (the segment file `Cythera Data` + three data-fork `.rsrc` resource maps + the AI
/// texts and screenshots), or `CYTHERA_DATA` when set.
public enum CytheraData {
    public static let environmentVariable = "CYTHERA_DATA"

    /// The application's resource fork, stored as a data-fork resource map.
    public static let appFile = "Cythera.rsrc"
    /// The scenario file's resource fork.
    public static let dataResourceFile = "Cythera Data.rsrc"
    /// The documentation viewer's resource fork.
    public static let documentationFile = "Cythera Documentation.rsrc"
    /// The scenario file's data fork (the segment file, data-format §1).
    public static let segmentFile = "Cythera Data"

    /// `CYTHERA_DATA` if set (must be a directory), else the repo's `Resources/Cythera`, found by walking
    /// up from this source file with symlinks resolved (worktrees reach HectorKit through a symlink;
    /// Windows-safe: no symlink enumeration, just path resolution).
    public static func dataDirectory() throws -> URL {
        let fm = FileManager.default
        if let env = ProcessInfo.processInfo.environment[environmentVariable], !env.isEmpty {
            let url = URL(fileURLWithPath: env, isDirectory: true).resolvingSymlinksInPath()
            guard isDirectory(url, fm) else { throw CytheraDataError.notFound("\(environmentVariable)=\(env)") }
            return url
        }
        var dir = URL(fileURLWithPath: #filePath).resolvingSymlinksInPath().deletingLastPathComponent()
        while dir.pathComponents.count > 1 {
            let candidate = dir.appendingPathComponent("Resources/Cythera", isDirectory: true)
            if isDirectory(candidate, fm) { return candidate }
            dir = dir.deletingLastPathComponent()
        }
        throw CytheraDataError.notFound("Resources/Cythera above \(#filePath); set \(environmentVariable)")
    }

    static func isDirectory(_ url: URL, _ fm: FileManager) -> Bool {
        var isDir: ObjCBool = false
        return fm.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }

    static func isFile(_ url: URL, _ fm: FileManager) -> Bool {
        var isDir: ObjCBool = false
        return fm.fileExists(atPath: url.path, isDirectory: &isDir) && !isDir.boolValue
    }
}
