import Foundation
import HectorResources

public enum FerazelDataError: Error, Equatable {
    /// The named data file or folder (or the data directory itself) is not there.
    case missing(String)
}

/// Where the original Ferazel's Wand 1.0.3 data lives (DECISIONS D26): the repo's committed copy
/// `Resources/Ferazel` (six data-fork `.rsrc` resource maps + `Ferazel's Wand Music`), or
/// `FERAZEL_DATA` when set.
public enum FerazelData {
    public static let environmentVariable = "FERAZEL_DATA"

    public static let appFile = "Ferazel's Wand.rsrc"
    public static let worldFile = "Ferazel's Wand World Data.rsrc"
    public static let backgroundsFile = "Ferazel's Wand Backgrounds.rsrc"
    public static let spritesFile = "Ferazel's Wand Sprites.rsrc"
    public static let soundsFile = "Ferazel's Wand Sounds.rsrc"
    public static let titlesFile = "Ferazel's Wand Titles.rsrc"
    public static let musicFolder = "Ferazel's Wand Music"

    /// `FERAZEL_DATA` if set (must be a directory), else the repo's `Resources/Ferazel`, found by walking
    /// up from this source file with symlinks resolved (worktrees reach HectorKit through a symlink;
    /// Windows-safe: no symlink enumeration, just path resolution).
    public static func dataDirectory() throws -> URL {
        let fm = FileManager.default
        if let env = ProcessInfo.processInfo.environment[environmentVariable], !env.isEmpty {
            let url = URL(fileURLWithPath: env, isDirectory: true).resolvingSymlinksInPath()
            guard isDirectory(url, fm) else { throw FerazelDataError.missing("\(environmentVariable)=\(env)") }
            return url
        }
        var dir = URL(fileURLWithPath: #filePath).resolvingSymlinksInPath().deletingLastPathComponent()
        while dir.pathComponents.count > 1 {
            let candidate = dir.appendingPathComponent("Resources/Ferazel", isDirectory: true)
            if isDirectory(candidate, fm) { return candidate }
            dir = dir.deletingLastPathComponent()
        }
        throw FerazelDataError.missing("Resources/Ferazel above \(#filePath); set \(environmentVariable)")
    }

    /// Opens the six resource maps (data forks, classic resource-map layout) and locates the music
    /// folder. Every file is checked before any is parsed, so a missing one is named, not masked.
    public static func open(_ directory: URL) throws -> FerazelResources {
        let fm = FileManager.default
        let dir = directory.resolvingSymlinksInPath()
        let files = [appFile, worldFile, backgroundsFile, spritesFile, soundsFile, titlesFile]
        for name in files where !isFile(dir.appendingPathComponent(name), fm) {
            throw FerazelDataError.missing(name)
        }
        let music = dir.appendingPathComponent(musicFolder, isDirectory: true).resolvingSymlinksInPath()
        guard isDirectory(music, fm) else { throw FerazelDataError.missing(musicFolder) }

        func load(_ name: String) throws -> ResourceCollection {
            let url = dir.appendingPathComponent(name).resolvingSymlinksInPath()
            let bytes = try Data(contentsOf: url)
            guard ClassicResourceMap.sniff(bytes) else { throw FerazelDataError.missing("\(name) (not a resource map)") }
            return try ClassicResourceMap.parse(bytes)
        }
        return FerazelResources(app: try load(appFile), world: try load(worldFile),
                                backgrounds: try load(backgroundsFile), sprites: try load(spritesFile),
                                sounds: try load(soundsFile), titles: try load(titlesFile),
                                musicDirectory: music)
    }

    private static func isDirectory(_ url: URL, _ fm: FileManager) -> Bool {
        var isDir: ObjCBool = false
        return fm.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }

    private static func isFile(_ url: URL, _ fm: FileManager) -> Bool {
        var isDir: ObjCBool = false
        return fm.fileExists(atPath: url.path, isDirectory: &isDir) && !isDir.boolValue
    }
}
