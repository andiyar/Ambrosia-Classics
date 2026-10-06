import Foundation
import HectorResources

/// `idli` — an ID list (`FUN_10003520`; data-tags.md §4): positional `#key <ID>` items; every value must
/// be exactly 4 characters (the original asserts).
public struct IDList: Sendable {
    public let items: [(key: String, id: FourCC)]

    public init(data: Data) throws {
        items = try TokenReader.items(DeimosText.decode(Array(data))).enumerated().map { i, item in
            guard let id = TokenReader.parseID(item.value) else {
                throw TextDataError.badID(index: i, value: MacRoman.decode(item.value))
            }
            return (item.key, id)
        }
    }
}
