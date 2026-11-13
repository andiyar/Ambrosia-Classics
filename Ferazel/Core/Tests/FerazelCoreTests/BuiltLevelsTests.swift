@testable import FerazelCore
import Foundation
import XCTest

/// The built-level list (6A-BL): one explicit sorted list of the level ids the replica can run, asked through
/// `contains(_:)`, and the one source line `tools/ferazel-built-levels.sh` prints for the visit sweep and the bot.
/// Plain Swift only (Proof B: no Foundation string search or trim, no regular expressions).
final class BuiltLevelsTests: XCTestCase {
    func testBuiltLevelsListAndContains() {
        XCTAssertEqual(BuiltLevels.list, [1, 2, 3, 4, 5])
        // Sorted, no duplicates: strictly increasing.
        for (a, b) in zip(BuiltLevels.list, BuiltLevels.list.dropFirst()) {
            XCTAssertLessThan(a, b, "BuiltLevels.list must be strictly increasing")
        }
        XCTAssertEqual(Set(BuiltLevels.list).count, BuiltLevels.list.count)
        for n in BuiltLevels.list { XCTAssertTrue(BuiltLevels.contains(n), "level \(n)") }
        // 6–9 have no level data; 10 is not built yet; 0 is no level.
        for n in [0, 6, 7, 8, 9, 10] { XCTAssertFalse(BuiltLevels.contains(n), "level \(n)") }
        XCTAssertEqual(BuiltLevels.notBuiltReport(10), "Level 10 is not built yet (Phase 6).")
    }

    /// The shape `tools/ferazel-built-levels.sh` reads: after leading blanks, this prefix, then digits, commas and
    /// spaces, then `]` and only trailing blanks.
    static let shapePrefix = "public static let list: [Int] = ["

    /// The helper's parse of one line, in plain Swift: the ids, or nil when the line is not of the shape.
    static func parse(_ line: Substring) -> [Int]? {
        let blank: (Character) -> Bool = { $0 == " " || $0 == "\t" || $0 == "\r" }
        var s = Substring(line.drop(while: blank))
        while let last = s.last, blank(last) { s = s.dropLast() }
        guard s.hasPrefix(shapePrefix), s.last == "]" else { return nil }
        let inner = s.dropFirst(shapePrefix.count).dropLast()
        guard inner.allSatisfy({ $0 == "," || $0 == " " || ("0"..."9").contains($0) }) else { return nil }
        var ids: [Int] = []
        for piece in inner.split(separator: ",", omittingEmptySubsequences: false) {
            guard let n = Int(String(piece.filter { $0 != " " })) else { return nil }
            ids.append(n)
        }
        return ids
    }

    func testBuiltLevelsSourceLineParses() throws {
        let url = URL(fileURLWithPath: #filePath).resolvingSymlinksInPath().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/FerazelCore/Front/BuiltLevels.swift")
        let text = try String(contentsOf: url, encoding: .utf8)
        let parsed = text.split(separator: "\n", omittingEmptySubsequences: false).compactMap(Self.parse)
        XCTAssertEqual(parsed.count, 1, "BuiltLevels.swift holds exactly one line of the helper's shape")
        XCTAssertEqual(parsed.first, BuiltLevels.list, "the helper's parse equals BuiltLevels.list")
    }
}
