import Foundation

/// The play order (engine-loop §6, HIGH): `FUN_10011c00` decodes 12 identifiers from the 12 × 64-byte
/// table at `0x100d6470` (code image) and matches each, with `strcmp` (`10011ce0 bl 0x10057820`), against
/// the levels' `#indentifier_STR`. The tag number in a level's file name is NOT its sector.
public struct LevelOrder: Sendable, Equatable {
    /// The 12 decoded identifiers, sector 1 first.
    public static let identifiers = ["Lucena", "Yippe", "Vista", "Swoop", "Conrad", "Delos", "Sparta", "Saratoga",
                                     "Hannibal", "Leonidas", "Thebes", "Yamato"]

    /// Level tag IDs, sector 1 first; `none` where no level carries the identifier.
    public let levels: [FourCC]

    /// Each identifier against the levels in master-list order; the first exact match wins. An identifier no
    /// level carries becomes `.none` here; the original treats it as fatal (`10011da4`: `FUN_10000f30` with
    /// error 0x110) — `DeimosSession` throws `SessionError.noLevel` when such a sector is started.
    public init(levels definitions: [LevelDefinition]) {
        levels = Self.identifiers.map { ident in definitions.first { $0.indentifier == ident }?.id ?? .none }
    }

    /// The level of `sector` (1…12); `none` outside that range.
    public func level(sector: Int) -> FourCC {
        (1...levels.count).contains(sector) ? levels[sector - 1] : .none
    }

    /// The sector (1…12) of level `id`, nil when it is not in the order.
    public func sector(of id: FourCC) -> Int? {
        guard id != .none, let i = levels.firstIndex(of: id) else { return nil }
        return i + 1
    }
}
