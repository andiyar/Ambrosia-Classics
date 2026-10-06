import Foundation
import HectorResources

/// `reli` — a RECT list (`FUN_10020220`; data-tags.md §4): positional `#key <l, t, r, b>` items → Mac Rects.
public struct RectList: Sendable {
    public let items: [(key: String, rect: MacRect)]

    public init(data: Data) throws {
        items = try TokenReader.items(DeimosText.decode(Array(data))).enumerated().map { i, item in
            guard let r = TokenReader.parseRect(item.value) else {
                throw TextDataError.badRect(index: i, value: MacRoman.decode(item.value))
            }
            return (item.key, r)
        }
    }
}
