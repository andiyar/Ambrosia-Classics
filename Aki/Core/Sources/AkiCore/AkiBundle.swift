import Foundation

/// One shipped Aki - Mahjong Solitaire `Contents/Resources` folder (1.1.0 Carbon or 1.2.0 Cocoa),
/// as the files lie on disk — the shipped bundle layout IS the data format (design §4).
public struct AkiBundle: Sendable {
    /// The data-fork classic resource file (`*.rsrc`): 1.1.0 ships `Aki - Mahjong Solitaire.rsrc`
    /// (124 resources, 82 PICT); 1.2.0 ships none (its art is loose PNGs) → nil.
    public let resourceFile: URL?
    /// Every `.aiff` and `.mp3` directly in the folder, sorted by file name.
    public let audioFiles: [URL]
    /// Every `.png` directly in the folder, sorted by file name.
    public let pngFiles: [URL]

    /// Lists `resourcesURL` (not recursive). Throws if the folder cannot be read.
    public init(resourcesURL: URL) throws {
        let names = try FileManager.default.contentsOfDirectory(atPath: resourcesURL.path).sorted()
        func files(_ extensions: Set<String>) -> [URL] {
            names.filter { extensions.contains(($0 as NSString).pathExtension.lowercased()) }
                .map { resourcesURL.appendingPathComponent($0) }
        }
        resourceFile = files(["rsrc"]).first
        audioFiles = files(["aiff", "mp3"])
        pngFiles = files(["png"])
    }
}
