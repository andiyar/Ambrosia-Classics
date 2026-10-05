import Foundation
import HectorResources

public enum BTXDataError: Error, Equatable {
    case missingFile(String), notAResourceFile(String)
    case missingResource(type: String, id: Int16), badSize(type: String, id: Int16, size: Int)
    case missingNamedResource(type: String, name: String)
}

/// The shipped Bubble Trouble X resource files, opened eagerly from a `Contents/Resources` folder.
/// HectorResources' `ResourceCollection` is not `Sendable`, so nothing of it is kept: what the core
/// needs is converted to its own value types at load time (plan Invariant 13).
public struct BTXResourceFiles: Sendable {
    /// A data-fork resource file (1,345,319 B); `ResourceReader.read(fileAt:)` falls back to the data fork.
    public static let levelsFileName = "BT Levels.rsrc"

    /// Resource counts per type in `BT Levels.rsrc`, e.g. `["LEVL": 50, "MAZE": 50, "FILM": 4, …]`.
    public let typeCounts: [String: Int]

    // Converted eagerly at init (Invariant 13); a Swift extension cannot add stored properties, so the
    // Task 2 values live here and the Task 2 accessors in the extension below.
    private let mazes: [Int: Maze]
    private let levels: [Int: LevelRecord]
    private let films: [Int: Film]

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
        try self.init(levelsCollection: collection)
    }

    /// Converts an already-opened `BT Levels.rsrc` (used by `BTXGameData`, which opens all five files once).
    init(levelsCollection collection: ResourceCollection) throws {
        var counts: [String: Int] = [:]
        for entry in collection.counts() { counts[entry.type] = entry.count }
        typeCounts = counts
        var mazes: [Int: Maze] = [:]
        for r in collection.resources(of: "MAZE") { mazes[Int(r.id)] = try Maze(data: r.data, id: r.id) }
        var levels: [Int: LevelRecord] = [:]
        for r in collection.resources(of: "LEVL") { levels[Int(r.id)] = try LevelRecord(data: r.data, id: r.id) }
        var films: [Int: Film] = [:]
        for r in collection.resources(of: "FILM") { films[Int(r.id)] = try Film(id: Int(r.id), data: r.data) }
        self.mazes = mazes
        self.levels = levels
        self.films = films
    }
}

// MARK: - Task 2: MAZE, LEVL, FILM

extension BTXResourceFiles {
    public var levelIDs: [Int] { levels.keys.sorted() }
    public var mazeIDs: [Int] { mazes.keys.sorted() }
    public var filmIDs: [Int] { films.keys.sorted() }

    public func maze(_ id: Int) throws -> Maze {
        guard let maze = mazes[id] else { throw Self.missing("MAZE", id) }
        return maze
    }

    public func level(_ id: Int) throws -> LevelRecord {
        guard let level = levels[id] else { throw Self.missing("LEVL", id) }
        return level
    }

    public func film(_ id: Int) throws -> Film {
        guard let film = films[id] else { throw Self.missing("FILM", id) }
        return film
    }

    private static func missing(_ type: String, _ id: Int) -> BTXDataError {
        .missingResource(type: type, id: Int16(truncatingIfNeeded: id))
    }
}
