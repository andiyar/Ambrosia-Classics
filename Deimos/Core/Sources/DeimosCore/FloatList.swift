import Foundation

/// `flli` — the permanent float list (`FUN_100204a0`; data-tags.md §3): float i = the i-th `#…<…>` item
/// in file order (`sscanf "%f"`); keys are documentation only. The loader reads at most 220 items
/// (`do … while i < 220`) and raises the DATA ERROR when it got fewer — so a 221st item is ignored.
public struct FloatList: Sendable, Equatable {
    public static let count = 220
    public let values: [Float]
    public let keys: [String]

    public init(data: Data) throws {
        var values: [Float] = [], keys: [String] = []
        for item in TokenReader.items(DeimosText.decode(Array(data))).prefix(Self.count) {
            // A value sscanf cannot read leaves the slot at 0 (the table is zero-filled); still counted.
            values.append(TokenReader.parseFloat(item.value) ?? 0)
            keys.append(item.key)
        }
        guard values.count == Self.count else { throw TextDataError.wrongCount(expected: Self.count, actual: values.count) }
        self.values = values
        self.keys = keys
    }
}
