import Foundation
import HectorResources

public enum BTXDataError: Error, Equatable {
    case missingFile(String), notAResourceFile(String)
    case missingResource(type: String, id: Int16), badSize(type: String, id: Int16, size: Int)
}

/// The shipped Bubble Trouble X resource files, opened eagerly from a `Contents/Resources` folder.
/// HectorResources' `ResourceCollection` is not `Sendable`, so nothing of it is kept: what the core
/// needs is converted to its own value types at load time (plan Invariant 13).
public struct BTXResourceFiles: Sendable {
    /// A data-fork resource file (1,345,319 B); `ResourceReader.read(fileAt:)` falls back to the data fork.
    public static let levelsFileName = "BT Levels.rsrc"

    /// Resource counts per type in `BT Levels.rsrc`, e.g. `["LEVL": 50, "MAZE": 50, "FILM": 4, …]`.
    public let typeCounts: [String: Int]

    public init(resourcesDirectory: URL) throws {
        let url = resourcesDirectory.appendingPathComponent(Self.levelsFileName)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw BTXDataError.missingFile(Self.levelsFileName)
        }
        let collection: ResourceCollection?
        do {
            collection = try ResourceReader.read(fileAt: url)
        } catch {
            throw BTXDataError.notAResourceFile(Self.levelsFileName)
        }
        guard let collection else { throw BTXDataError.notAResourceFile(Self.levelsFileName) }
        var counts: [String: Int] = [:]
        for entry in collection.counts() { counts[entry.type] = entry.count }
        typeCounts = counts
    }
}
