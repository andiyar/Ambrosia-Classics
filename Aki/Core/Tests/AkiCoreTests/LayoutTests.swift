import XCTest
@testable import AkiCore

/// P2.1 — the 12 built-in layouts (`_LoadLayout` @ 0x132f1 dispatch, docs/aki/levels.md §1; tables in
/// docs/aki/levels-layouts.md) and the 144-face multiset `_C.97.126381` (docs/aki/rules.md §4.1).
final class LayoutTests: XCTestCase {

    /// `Layouts.forLevel(level − 1)` against the bank's section for `level`, placement by placement.
    private func check(level: Int, file: StaticString = #filePath, line: UInt = #line) throws {
        let sections = try LayoutMarkdown.load()
        XCTAssertEqual(sections.count, 12, "sections in levels-layouts.md", file: file, line: line)
        let section = try XCTUnwrap(sections.first { $0.level == level }, "no section for level \(level)", file: file, line: line)
        let layout = Layouts.forLevel(level - 1)
        XCTAssertEqual(layout.placements.count, 144, file: file, line: line)
        XCTAssertEqual(section.tuples.count, 144, "bank tuples", file: file, line: line)
        let bank = section.tuples.map { LayoutPlacement(x2: $0.x2, y2: $0.y2, layerArg: $0.layer) }
        if let i = bank.indices.first(where: { $0 >= layout.placements.count || layout.placements[$0] != bank[$0] }),
           i < layout.placements.count {
            XCTFail("level \(level): first mismatch at placement \(i): \(layout.placements[i]) vs bank \(bank[i])",
                    file: file, line: line)
        }
        XCTAssertEqual(layout.placements, bank, file: file, line: line)
        XCTAssertEqual(layout.functionName, section.functionName, file: file, line: line)
        XCTAssertEqual(layout.offsetX, section.offsetX, file: file, line: line)
        XCTAssertEqual(layout.offsetY, section.offsetY, file: file, line: line)
        XCTAssertEqual(layout.background, section.background, file: file, line: line)
        XCTAssertEqual(layout.background, level, file: file, line: line)
    }

    func testLayoutLevel01MatchesBank() throws {
        try check(level: 1)
        let l = Layouts.forLevel(0)
        XCTAssertEqual(l.functionName, "_Layout1")
        XCTAssertEqual([l.offsetX, l.offsetY, l.background], [0, -40, 1])
        XCTAssertEqual(l.placements.first, LayoutPlacement(x2: 10, y2: 16, layerArg: 5))
        XCTAssertEqual(l.placements.last, LayoutPlacement(x2: 22, y2: 6, layerArg: 2))
    }
    func testLayoutLevel02MatchesBank() throws { try check(level: 2) }
    func testLayoutLevel03MatchesBank() throws { try check(level: 3) }
    func testLayoutLevel04MatchesBank() throws { try check(level: 4) }
    func testLayoutLevel05MatchesBank() throws { try check(level: 5) }
    func testLayoutLevel06MatchesBank() throws {
        try check(level: 6)
        let l = Layouts.forLevel(5)
        XCTAssertEqual(l.functionName, "_Layout10")
        XCTAssertEqual([l.offsetX, l.offsetY, l.background], [8, -14, 6])
    }
    func testLayoutLevel07MatchesBank() throws { try check(level: 7) }
    func testLayoutLevel08MatchesBank() throws { try check(level: 8) }
    func testLayoutLevel09MatchesBank() throws { try check(level: 9) }
    func testLayoutLevel10MatchesBank() throws { try check(level: 10) }
    func testLayoutLevel11MatchesBank() throws { try check(level: 11) }
    func testLayoutLevel12MatchesBank() throws {
        try check(level: 12)
        let l = Layouts.forLevel(11)
        XCTAssertEqual(l.functionName, "_Layout12")
        XCTAssertEqual([l.offsetX, l.offsetY, l.background], [25, 25, 12])
        // The whole `_LoadLayout` dispatch (levels.md §1): the function names are shuffled, backgrounds are not.
        XCTAssertEqual((0..<12).map { Layouts.forLevel($0).functionName },
                       ["_Layout1", "_Layout2", "_Layout3", "_Layout4", "_Layout5", "_Layout10",
                        "_Layout7", "_Layout11", "_Layout9", "_Layout6", "_Layout8", "_Layout12"])
    }

    func testFaceMultisetIsTheShippedTable() {
        let faces = Layouts.faceMultiset
        XCTAssertEqual(faces.count, 144)
        XCTAssertEqual(faces.first, 202)
        XCTAssertEqual(faces.last, 216)
        var histogram: [Int: Int] = [:]
        for f in faces { histogram[f, default: 0] += 1 }
        var expected: [Int: Int] = [:]
        for f in 200...204 { expected[f] = 4 }
        for f in 205...212 { expected[f] = 1 }
        for f in 213...241 { expected[f] = 4 }
        XCTAssertEqual(histogram, expected)
    }
}
