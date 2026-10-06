import Foundation
import HectorResources

/// A `STR#` resource: a u16 count, then that many Pascal strings in Mac Roman (decoded through
/// `HectorResources.MacRoman`, never Foundation's Mac Roman string encoding — plan invariant 1). World Data holds
/// `STR# 1000` (level names, read by `.InitMapLevelNames`) and `STR# 500` (sign texts; world-data §2).
public struct StringList: Sendable, Equatable {
    public let strings: [String]

    public init(id: Int16, data: Data) throws {
        let b = BigEndianBytes(data, type: "STR#", id: id)
        let count = Int(try b.u16(0))
        var offset = 2
        var strings: [String] = []
        strings.reserveCapacity(count)
        for _ in 0..<count {
            strings.append(try b.pascalString(at: offset))
            offset += 1 + Int(try b.u8(offset))
        }
        self.strings = strings
    }

    /// `GetIndString` semantics: 1-based; nil outside 1...count.
    public func string(_ index: Int) -> String? {
        guard index >= 1, index <= strings.count else { return nil }
        return strings[index - 1]
    }

    /// `STR# <id>` from World Data.
    public static func load(from resources: FerazelResources, id: Int16) throws -> StringList {
        guard let r = resources.world.resource(type: "STR#", id: id) else {
            throw WorldDataError.missing(type: "STR#", id: id)
        }
        return try StringList(id: r.id, data: r.data)
    }
}
