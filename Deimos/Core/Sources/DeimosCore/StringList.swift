import Foundation
import HectorResources

/// Errors of the positional text lists (flli idli reli coli).
public enum TextDataError: Error, Equatable, Sendable {
    /// The float list did not hold 220 items ("DATA ERROR:  Permanent Float list has incorrect number of
    /// floating point values.").
    case wrongCount(expected: Int, actual: Int)
    /// An ID item whose value is not exactly 4 characters ("Invalid ID Length (must be 4 characters long)").
    case badID(index: Int, value: String)
    case badRect(index: Int, value: String)
    case badColor(index: Int, value: String)
}

/// `stli` — a string list (reader `FUN_10002e50`; bank data-tags.md §2): decoded, split on CR; line i is
/// 0-based. Lines = CR count, +1 when the file does not end in CR (shipped files use CR only, plan known
/// delta 7). A line keeps every byte but the CR (Mac Roman).
public struct StringList: Sendable, Equatable {
    public let lines: [[UInt8]]

    /// `data` = the tag's stored (obfuscated) bytes.
    public init(data: Data) {
        self.init(text: DeimosText.decode(Array(data)))
    }

    public init(text: [UInt8]) {
        var lines = text.split(separator: 0x0d, omittingEmptySubsequences: false).map(Array.init)
        if text.isEmpty || text.last == 0x0d { lines.removeLast() }
        self.lines = lines
    }

    public func string(at index: Int) -> String? {
        lines.indices.contains(index) ? MacRoman.decode(lines[index]) : nil
    }
}
