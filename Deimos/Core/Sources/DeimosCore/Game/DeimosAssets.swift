import Foundation
import HectorResources

/// The game's permanent data, loaded the way boot loads it: `FUN_1001fcf0` (the permanent ID / rect / colour
/// lists), `FUN_100204a0` (floats), `FUN_1001fe60` (sprites, sounds, game strings), `FUN_1000ed60` (the 54
/// text formats in `idli gate` order), plus the four definition master lists and the level order
/// (data-tags §2–§5, hud-scorebar §9, engine-loop §2, §6). Sprite groups decode on first use and are cached
/// for the life of the value (decoding all 2,554 frames up front is slow — plan landmine 10e).
/// ★ LOCKED (plan S2).
public struct DeimosAssets: Sendable {
    public let index: TagIndex
    /// `flli gafl`: PermFloat i (`FUN_10020250(i)`), 220.
    public let floats: [Float]
    /// `stli pgsl`: the 37 × 128-byte game-string table (`FUN_10020260(i)`), Mac Roman bytes per line
    /// (at most 127, the table's NUL-terminated row).
    public let gameStrings: [[UInt8]]
    /// Format i = item i of `idli gate` (`FUN_1000ed60`, 54).
    public let formats: [TextFormat]
    /// The tag IDs of `formats`, same order.
    public let formatIDs: [FourCC]
    /// `idli gaob` (40, `FUN_100201f0(i)`), `gaso` (24, `FUN_10020210(i)`), `gasp` (8, `FUN_10020200(i)`).
    public let objects: [FourCC]
    public let sounds: [FourCC]
    public let sprites: [FourCC]
    /// `idli tesp`: the font sprite groups (3).
    public let fonts: [FourCC]
    /// `reli inre` (22, `FUN_10020220(i, &r)`).
    public let rects: [MacRect]
    /// `coli gaco` (1: the score-bar digit colour).
    public let colors: [UInt16]
    public let definitions: DefinitionLists
    public let levelOrder: LevelOrder
    private let cache: SpriteGroupCache

    /// Rows of the game-string table (`iVar6 < 0x25`) and its row size (0x80, NUL included).
    public static let gameStringCount = 37
    public static let gameStringRowSize = 0x80

    public static func load(index: TagIndex) throws -> DeimosAssets {
        try DeimosAssets(index: index)
    }

    private init(index: TagIndex) throws {
        func tag(_ type: String, _ id: String) throws -> Data {
            guard let r = index.record(type: FourCC(type)!, id: FourCC(id)!) else {
                throw DeimosAssetsError.missingTag(type: type, id: id)
            }
            return try index.data(for: r)
        }
        func ids(_ id: String, _ count: Int) throws -> [FourCC] {
            let list = try IDList(data: tag("idli", id)).items.map(\.id)
            guard list.count >= count else { throw DeimosAssetsError.shortList(id: id, expected: count, actual: list.count) }
            return Array(list.prefix(count))
        }
        self.index = index
        floats = try FloatList(data: tag("flli", "gafl")).values
        objects = try ids("gaob", 0x28)
        sounds = try ids("gaso", 0x18)
        sprites = try ids("gasp", 8)
        fonts = try IDList(data: tag("idli", "tesp")).items.map(\.id)
        let rectItems = try RectList(data: tag("reli", "inre")).items
        guard rectItems.count >= 0x16 else {
            throw DeimosAssetsError.shortList(id: "inre", expected: 0x16, actual: rectItems.count)
        }
        rects = rectItems.prefix(0x16).map(\.rect)
        colors = try ColorList(data: tag("coli", "gaco")).items.map(\.color)
        let lines = StringList(data: try tag("stli", "pgsl")).lines
        gameStrings = (0..<Self.gameStringCount).map { i in
            i < lines.count ? Array(lines[i].prefix(Self.gameStringRowSize - 1)) : []
        }
        formatIDs = try ids("gate", 0x36)
        formats = try formatIDs.map { id in
            guard let r = index.record(type: FourCC("tefo")!, id: id) else {
                throw DeimosAssetsError.missingTag(type: "tefo", id: id.description)
            }
            return TextFormat(data: try index.data(for: r), tagName: r.tagName)
        }
        definitions = try DefinitionLists(index: index)
        levelOrder = LevelOrder(levels: definitions.levels)
        cache = SpriteGroupCache()
    }

    /// Game string i as text (Mac Roman); nil outside 0..<37.
    public func gameString(_ i: Int) -> String? {
        gameStrings.indices.contains(i) ? MacRoman.decode(gameStrings[i]) : nil
    }

    /// Sprite group `id` (`SpriteGroup.load`), decoded once and cached.
    public func spriteGroup(_ id: FourCC) throws -> SpriteGroup {
        try cache.group(id) { try SpriteGroup.load(id: id, index: index) }
    }
}

public enum DeimosAssetsError: Error, Equatable, Sendable {
    case missingTag(type: String, id: String)
    case shortList(id: String, expected: Int, actual: Int)
}

/// A lock-guarded memo of decoded sprite groups, shared by every copy of a `DeimosAssets`.
final class SpriteGroupCache: @unchecked Sendable {
    private let lock = NSLock()
    private var groups: [FourCC: SpriteGroup] = [:]

    func group(_ id: FourCC, load: () throws -> SpriteGroup) throws -> SpriteGroup {
        lock.lock()
        defer { lock.unlock() }
        if let g = groups[id] { return g }
        let g = try load()
        groups[id] = g
        return g
    }
}
