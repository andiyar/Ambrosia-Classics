import Foundation
import HectorResources

/// All five shipped Bubble Trouble X resource files, opened once from a `Contents/Resources` folder
/// (data-fork maps, `ResourceReader.read(fileAt:)`), with lookups by type + id and by name across them.
///
/// The original opens them into one Resource Manager chain (STR# 129 "Required Files"), so a
/// `GetResource`/`GetNamedResource` finds a resource whichever file holds it — e.g. `cicn 1000–1002`,
/// `cicn 128`, `PICT 912` and `snd 9047` live in `Bubble Trouble X.rsrc`, not the sprite/level/sound files
/// (amendment R9). The five files share no (type, id) except `vers 1/2`; lookups search `fileNames` in order.
///
/// `ResourceCollection` is not `Sendable`, so this is a final class used from one isolation domain (the
/// App's main actor). The simulation's own value types (`levels`, `sprites`, `rects`, `presentation`)
/// are `Sendable` and can be handed out freely.
public final class BTXGameData {
    public static let appFileName = "Bubble Trouble X.rsrc"
    public static let levelsFileName = BTXResourceFiles.levelsFileName
    public static let spritesFileName = "BT Sprites.rsrc"
    public static let soundsFileName = "BT Sounds.rsrc"
    public static let titlesFileName = "BT Titles.rsrc"
    public static let allFileNames = [appFileName, levelsFileName, spritesFileName, soundsFileName, titlesFileName]

    /// `_LoadMusic(0)` loads "Title music", which it maps to "Level set 3 music" (`_LoadMusic @ 0001b23c`).
    public static let titleMusicSet = 3

    /// The file names in lookup order (`allFileNames`).
    public let fileNames: [String]
    /// The existing MAZE/LEVL/FILM loaders over `BT Levels.rsrc`, unchanged.
    public let levels: BTXResourceFiles
    /// `SpIL 128` → `SpIc` sprite addressing.
    public let sprites: SpriteIndex
    /// `Rect 1…7`, decoded L,T,R,B.
    public let rects: RectResources
    /// Per-level background PICT and music set (LEVL w1/w2).
    public let presentation: LevelPresentation

    private let collections: [ResourceCollection]

    public init(resourcesDirectory: URL) throws {
        var collections: [ResourceCollection] = []
        for name in Self.allFileNames {
            let url = resourcesDirectory.appendingPathComponent(name)
            guard FileManager.default.fileExists(atPath: url.path) else { throw BTXDataError.missingFile(name) }
            let collection: ResourceCollection?
            do { collection = try ResourceReader.read(fileAt: url) } catch {
                throw BTXDataError.notAResourceFile(name)
            }
            guard let collection else { throw BTXDataError.notAResourceFile(name) }
            collections.append(collection)
        }
        self.collections = collections
        fileNames = Self.allFileNames
        let levels = try BTXResourceFiles(levelsCollection: collections[1])
        self.levels = levels
        presentation = try LevelPresentation(levels: levels)

        func find(_ type: String, _ id: Int) -> Resource? {
            for c in collections { if let r = c.resource(type: type, id: Int16(truncatingIfNeeded: id)) { return r } }
            return nil
        }
        guard let spil = find("SpIL", 128) else { throw BTXDataError.missingResource(type: "SpIL", id: 128) }
        sprites = try SpriteIndex(spilData: spil.data, spicData: { find("SpIc", $0)?.data })

        var rects: [Int: QDRect] = [:], rectNames: [Int: String] = [:]
        for c in collections {
            for r in c.resources(of: "Rect") where rects[Int(r.id)] == nil {
                rects[Int(r.id)] = try RectResources.decode(r.data, id: Int(r.id))
                rectNames[Int(r.id)] = r.name
            }
        }
        self.rects = RectResources(rects: rects, names: rectNames)
    }

    // MARK: - Lookups across the five files

    /// The first resource of `type` (4-char OSType, e.g. `"snd "`) and `id` in `fileNames` order.
    public func resource(type: String, id: Int) -> Resource? {
        guard let i = fileIndex(type: type, id: id) else { return nil }
        return collections[i].resource(type: type, id: Int16(truncatingIfNeeded: id))
    }

    /// The raw bytes of a resource by type + id, from whichever file holds it.
    public func data(type: String, id: Int) -> Data? { resource(type: type, id: id)?.data }

    /// The name of the file that holds `type`/`id`.
    public func fileName(containingType type: String, id: Int) -> String? {
        fileIndex(type: type, id: id).map { fileNames[$0] }
    }

    /// Every id of `type` across the five files, sorted, without duplicates.
    public func ids(of type: String) -> [Int] {
        Set(collections.flatMap { $0.resources(of: type).map { Int($0.id) } }).sorted()
    }

    /// `GetNamedResource(type, name)`: the first resource of `type` whose name is exactly `name`.
    public func resource(type: String, named name: String) -> Resource? {
        for c in collections { if let r = c.resources(of: type).first(where: { $0.name == name }) { return r } }
        return nil
    }

    /// The id of the resource `GetNamedResource(type, name)` finds.
    public func resourceID(type: String, named name: String) -> Int? {
        resource(type: type, named: name).map { Int($0.id) }
    }

    /// A `STR#` list (u16 count, then Pascal strings, MacRoman).
    public func strings(_ id: Int) throws -> [String] {
        guard let data = data(type: "STR#", id: id) else {
            throw BTXDataError.missingResource(type: "STR#", id: Int16(truncatingIfNeeded: id))
        }
        let bad = BTXDataError.badSize(type: "STR#", id: Int16(truncatingIfNeeded: id), size: data.count)
        guard data.count >= 2 else { throw bad }
        var out: [String] = []
        var offset = 2
        for _ in 0..<Int(BigEndian.uint16(data, at: 0)) {
            guard offset < data.count else { throw bad }
            let length = Int(data[data.startIndex + offset])
            guard offset + 1 + length <= data.count else { throw bad }
            let bytes = BigEndian.bytes(data, at: offset + 1, count: length)
            out.append(MacRoman.decode(bytes))
            offset += 1 + length
        }
        return out
    }

    // MARK: - Music names (`_LoadMusic @ 0001b23c`, `_GetMusicString` = STR# 131)

    /// `_LoadMusic(1)`: STR# 131 item 3 ("Level set ") + the set number + item 4 (" music") + ".1".
    public func musicName(set: Int) throws -> String {
        let s = try strings(131)
        guard s.count >= 4 else { throw BTXDataError.missingResource(type: "STR#", id: 131) }
        return s[2] + String(set) + s[3] + ".1"
    }

    /// `_LoadMusic(0)`: STR# 131 item 2 ("Title music"), replaced by the literal "Level set 3 music", + ".1".
    public func titleMusicName() throws -> String {
        let s = try strings(131)
        guard s.count >= 2 else { throw BTXDataError.missingResource(type: "STR#", id: 131) }
        let base = s[1] == "Title music" ? "Level set \(Self.titleMusicSet) music" : s[1]
        return base + ".1"
    }

    /// The `snd ` id `_LoadMusic(1)` loads for music `set` (1…4 → 11001…11004).
    public func musicResourceID(set: Int) throws -> Int {
        try namedSoundID(musicName(set: set))
    }

    /// The `snd ` id `_LoadMusic(0)` loads for the title screen (11003).
    public func titleMusicResourceID() throws -> Int {
        try namedSoundID(titleMusicName())
    }

    private func namedSoundID(_ name: String) throws -> Int {
        guard let id = resourceID(type: "snd ", named: name) else {
            throw BTXDataError.missingNamedResource(type: "snd ", name: name)
        }
        return id
    }

    private func fileIndex(type: String, id: Int) -> Int? {
        collections.firstIndex { $0.resource(type: type, id: Int16(truncatingIfNeeded: id)) != nil }
    }
}

/// Per-level presentation read from `LEVL` (FI §6a): w1 = background PICT (912 in the app file,
/// 13000–13005 in `BT Levels.rsrc`, drawn centred by `_DrawMaze`), w2 = music set 1…4 (`_LoadMusic(1)`).
/// Levels are the LEVL ids 1…50; the ≥ 51 random pick is the session's (`_LoadLevel @ 00002ef7`).
public struct LevelPresentation: Equatable, Sendable {
    private struct Entry: Equatable, Sendable { let pict: Int, music: Int }
    private let entries: [Int: Entry]

    public init(levels: BTXResourceFiles) throws {
        var entries: [Int: Entry] = [:]
        for id in levels.levelIDs {
            let record = try levels.level(id)
            entries[id] = Entry(pict: record.pictID, music: record.musicSet)
        }
        self.entries = entries
    }

    public func background(level: Int) throws -> Int { try entry(level).pict }
    public func musicSet(level: Int) throws -> Int { try entry(level).music }

    private func entry(_ level: Int) throws -> Entry {
        guard let e = entries[level] else {
            throw BTXDataError.missingResource(type: "LEVL", id: Int16(truncatingIfNeeded: level))
        }
        return e
    }
}
