import Foundation
import HectorResources

/// `coli` — a colour list (`FUN_10003340`; data-tags.md §4): positional `#key <RRGGBB>` items → x1R5G5B5.
public struct ColorList: Sendable {
    public let items: [(key: String, color: UInt16)]

    public init(data: Data) throws {
        items = try TokenReader.items(DeimosText.decode(Array(data))).enumerated().map { i, item in
            guard let c = TokenReader.parseColor(item.value) else {
                throw TextDataError.badColor(index: i, value: MacRoman.decode(item.value))
            }
            return (item.key, c)
        }
    }
}
