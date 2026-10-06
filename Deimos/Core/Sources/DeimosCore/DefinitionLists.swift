import Foundation
import HectorResources

/// The 0x18-byte sound record every definition embeds (`FUN_1003e1a0`; bank unit-def-struct.md §3):
/// keys `#<stem>_ID`, `_MinVolume_INT`, `_MaxVolume_INT`, `_Priority_INT`, `_MinPitch_FLOAT`,
/// `_MaxPitch_FLOAT`, read in that order. Code default {`none`, 100, 100, 100, 1.0, 1.0} (table
/// `0x100d7250` / `0x100d7014`); the shipped files write Priority 50 (unit-def-struct.md §3 note a).
public struct SoundRecord: Sendable, Equatable {
    public var id: FourCC = .none
    public var minVolume: Int32 = 100
    public var maxVolume: Int32 = 100
    public var priority: Int32 = 100
    public var minPitch: Float = 1
    public var maxPitch: Float = 1

    public init() {}
}

/// The definition parsers' view of `TokenReader`: every reader stores into its destination only on
/// success, so a miss keeps the default already there (STR misses are silent; every other miss or
/// malformation raises the reader's error flag — bank unit-def-struct.md §2.1–§2.2 — except an INT/FLOAT
/// value with no digits, which is silently not stored; see `TokenReader`). The cursor is
/// forward-only, so the call order of these methods IS the parse (§2.3).
struct DefinitionReader {
    var r: TokenReader

    init(_ text: [UInt8]) { r = TokenReader(text) }

    var errors: [String] { r.errors }

    mutating func str(_ dst: inout String, _ key: String, maxLength: Int) {
        if let v = r.string(key, maxLength: maxLength) { dst = v }
    }
    mutating func id(_ dst: inout FourCC, _ key: String) { if let v = r.id(key) { dst = v } }
    mutating func int(_ dst: inout Int32, _ key: String) { if let v = r.int(key) { dst = v } }
    mutating func float(_ dst: inout Float, _ key: String) { if let v = r.float(key) { dst = v } }
    mutating func bool(_ dst: inout Bool, _ key: String) { if let v = r.bool(key) { dst = v } }
    mutating func color(_ dst: inout UInt16, _ key: String) { if let v = r.color(key) { dst = v } }
    mutating func rect(_ dst: inout MacRect, _ key: String) { if let v = r.rect(key) { dst = v } }

    /// A count read into an uninitialised stack local in the original (§2.4): a miss leaves garbage
    /// there — already a load error — and this port loops zero times.
    mutating func count(_ key: String) -> Int32 { r.int(key) ?? 0 }

    mutating func sound(_ dst: inout SoundRecord, _ stem: String) {
        id(&dst.id, "#\(stem)_ID")
        int(&dst.minVolume, "#\(stem)_MinVolume_INT")
        int(&dst.maxVolume, "#\(stem)_MaxVolume_INT")
        int(&dst.priority, "#\(stem)_Priority_INT")
        float(&dst.minPitch, "#\(stem)_MinPitch_FLOAT")
        float(&dst.maxPitch, "#\(stem)_MaxPitch_FLOAT")
    }

    /// The parse-time sprite check (`FUN_10041960`, `FUN_1001fbe0`): an ID that names no sprite group
    /// logs the original's line and becomes `none`. `none` itself is not looked up.
    static func checkSprite(_ id: inout FourCC, _ spriteExists: (FourCC) -> Bool, notes: inout [String]) {
        guard id != .none, !spriteExists(id) else { return }
        notes.append("MISSING SPRITE RESOURCE:  A reference was found to an unknown Sprite Group ('\(id)').")
        id = .none
    }

    /// The conditional de-obfuscation of `unde` (`#name_STR`) and `wede` (`#type_ID`): decode only when
    /// `strstr(raw, marker)` fails (bank pak-format.md §3; plan Research note 11). Either way only the
    /// bytes before the first raw NUL count (`strlen`, then decode — `DeimosText.decodeCString`).
    static func plainText(_ raw: [UInt8], unlessContains marker: String) -> [UInt8] {
        let visible = raw.firstIndex(of: 0).map { Array(raw[..<$0]) } ?? raw
        return TokenReader.find(Array(marker.utf8), in: visible, from: 0) == nil ? DeimosText.decode(visible) : visible
    }
}

/// The four definition master lists, built the original's way: for i = 0, 1, … the i-th tag of the
/// type in tag-index order (`FUN_10002be0`; unit-def-struct.md §1, weapons-projectiles.md §1.1,
/// §9 of unit-def-struct.md, waves-and-enemies.md §1). Sprite checks ask the index for an `im08` tag
/// (a sprite group's colour plate), level objects ask for an `unde` tag (`FUN_10001f20('unde', id)`).
///
/// `errors` aggregates every definition's errors as `"<type> '<id>': <message>"` (token-error keys,
/// the original's fatal load lines, the numStates assert); `notes` likewise for the non-fatal logs.
/// Nothing here throws on bad text — the original reports and (for unde/plde, strict mode) quits; the
/// caller decides. `init` throws only when an entry's bytes cannot be read.
public struct DefinitionLists: Sendable {
    public let units: [UnitDefinition]
    public let players: [PlayerDefinition]
    public let weapons: [WeaponDefinition]
    public let levels: [LevelDefinition]
    public let errors: [String]
    public let notes: [String]

    public init(index: TagIndex) throws {
        let im08 = FourCC("im08")!, unde = FourCC("unde")!
        let spriteExists: (FourCC) -> Bool = { index.record(type: im08, id: $0) != nil }
        let unitExists: (FourCC) -> Bool = { index.record(type: unde, id: $0) != nil }
        var errors: [String] = [], notes: [String] = []
        func raw(_ r: TagIndex.Record) throws -> [UInt8] { [UInt8](try index.data(for: r)) }
        func collect(_ type: String, _ id: FourCC, _ e: [String], _ n: [String]) {
            errors += e.map { "\(type) '\(id)': \($0)" }
            notes += n.map { "\(type) '\(id)': \($0)" }
        }

        var units: [UnitDefinition] = []
        for r in index.records(ofType: unde) {
            let (u, e) = UnitDefinition.parse(id: r.id, text: try raw(r), spriteExists: spriteExists)
            collect("unde", r.id, e, u.notes)
            units.append(u)
        }
        var players: [PlayerDefinition] = []
        for r in index.records(ofType: FourCC("plde")!) {
            let (p, e) = PlayerDefinition.parse(id: r.id, text: try raw(r), spriteExists: spriteExists)
            collect("plde", r.id, e, p.notes)
            players.append(p)
        }
        var weapons: [WeaponDefinition] = []
        for r in index.records(ofType: FourCC("wede")!) {
            let (w, e) = WeaponDefinition.parse(id: r.id, text: try raw(r), spriteExists: spriteExists)
            collect("wede", r.id, e, w.notes)
            weapons.append(w)
        }
        var levels: [LevelDefinition] = []
        for r in index.records(ofType: FourCC("leve")!) {
            let (l, e) = LevelDefinition.parse(id: r.id, text: try raw(r), unitExists: unitExists)
            collect("leve", r.id, e, l.notes)
            levels.append(l)
        }
        self.units = units
        self.players = players
        self.weapons = weapons
        self.levels = levels
        self.errors = errors
        self.notes = notes
    }

    /// The unit with tag ID `id` (linear over the master list, `FUN_1003d2f0`).
    public func unit(_ id: FourCC) -> UnitDefinition? { units.first { $0.id == id } }
}
