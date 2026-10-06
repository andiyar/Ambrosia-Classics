import XCTest
import HectorResources
@testable import FerazelCore

/// C2 (docs/plans/2026-10-06-ferazel-phase1.md): `Mwld 0`, `Mmap 200`, `STR#` 500/1000 and the 29 `Mcnv`
/// resources against the committed `Resources/Ferazel` (D26). Contract: world-data §2.1, §4.2;
/// conversations-mcnv §2.2. Numbers are planner probes (p02, p12 = Research note 11).
/// A missing data file is a FAILURE naming the path, never a skip (plan invariant 5).
final class WorldDataTests: XCTestCase {

    private func resources() throws -> FerazelResources {
        try FerazelData.open(try FerazelData.dataDirectory())
    }

    func testMwld() throws {
        let world = try WorldFile.load(from: try resources())
        XCTAssertEqual(world.name, "Teraknorn")
        XCTAssertEqual(world.stamp, 0x152b_e0ed)
        XCTAssertEqual(world.field144, 2)
        XCTAssertEqual(world.startLevel, 1)
        XCTAssertEqual(world.field1c6, 100)
    }

    func testMmapTwentyFourNodes() throws {
        let map = try WorldMap.load(from: try resources())
        // Research note 11: node → level, (v, h), links, face.
        let expected: [(Int, Int16, Int16, Int16, [Int16], Int16)] = [
            (1, 1, 307, 237, [2], 0), (2, 2, 330, 269, [1, 3, 4], 0), (3, 3, 355, 228, [2], 0),
            (4, 4, 329, 297, [2, 5], 0), (5, 5, 294, 319, [4, 10], 1), (10, 10, 230, 300, [5, 11, 15], 0),
            (11, 11, 227, 272, [10, 18], 0), (15, 15, 235, 358, [10, 20, 30], 0), (18, 18, 222, 225, [11, 40], 1),
            (20, 20, 229, 393, [15, 21], 0), (21, 21, 220, 431, [20, 22, 70], 0), (22, 22, 191, 453, [21, 25], 0),
            (25, 25, 136, 460, [22], 1), (30, 30, 266, 476, [15, 31], 0), (31, 31, 344, 492, [30], 0),
            (40, 40, 214, 143, [18, 45, 60], 0), (45, 45, 241, 91, [40, 50], 0), (50, 50, 265, 51, [45, 51], 0),
            (51, 51, 300, 52, [50, 52], 0), (52, 52, 328, 62, [51, 55], 0), (55, 55, 358, 71, [52], 1),
            (60, 62, 159, 34, [40, 62], 0), (62, 67, 77, 90, [60], 1), (70, 70, 235, 469, [21], 0),
        ]
        XCTAssertEqual(map.nodes.count, 24)
        XCTAssertEqual(map.nodes.map(\.index), expected.map(\.0))
        for (node, e) in zip(map.nodes, expected) {
            XCTAssertEqual(node.level, e.1, "node \(e.0) level")
            XCTAssertEqual(node.v, e.2, "node \(e.0) v"); XCTAssertEqual(node.h, e.3, "node \(e.0) h")
            XCTAssertEqual(node.links.filter { $0 != 0 }, e.4, "node \(e.0) links")
            XCTAssertEqual(node.links.count, 7)
            XCTAssertEqual(node.face, e.5, "node \(e.0) face")
            XCTAssertEqual(node.name, "", "node \(e.0) name")
        }
        XCTAssertEqual(map.tail.count, 256)
        XCTAssertTrue(map.tail.allSatisfy { $0 == 0 })
    }

    func testStringLists() throws {
        let r = try resources()
        let levelNames = try StringList.load(from: r, id: 1000)
        XCTAssertEqual(levelNames.strings.count, 99)
        XCTAssertEqual(levelNames.string(1), "A Scent of Peril")          // GetIndString is 1-based
        XCTAssertEqual(levelNames.string(51), "If You Can't Stand The Heat\u{2026}")
        XCTAssertNil(levelNames.string(0)); XCTAssertNil(levelNames.string(100))
        let signs = try StringList.load(from: r, id: 500)
        XCTAssertEqual(signs.strings.count, 19)
    }

    func testMcnvRecords() throws {
        let r = try resources()
        let ids = r.world.resources(of: "Mcnv").map(\.id).sorted()
        XCTAssertEqual(ids, [200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 220, 221,
                             250, 251, 252, 260, 261, 280, 281, 282, 283, 300, 400, 401])
        var slots = 0, withText = 0, withPortrait = 0
        for id in ids {
            let conv = try Conversation.load(from: r, id: id)
            XCTAssertEqual(conv.lines.count, 20)
            for line in conv.lines {
                slots += 1
                if !line.text.isEmpty { withText += 1 }
                if line.portrait != 0 { withPortrait += 1 }
                XCTAssertEqual(line.responses.count, 5); XCTAssertEqual(line.responseTargets.count, 5)
            }
        }
        XCTAssertEqual(slots, 580)
        XCTAssertEqual(withText, 198)
        XCTAssertEqual(withPortrait, 183)
        let rojinko = try Conversation.load(from: r, id: 200)
        XCTAssertEqual(rojinko.name, "Rojinko Conv")
        // world-data §5 / conversations-mcnv §2.2: line 0 is spoken by "Suspicious Character".
        XCTAssertEqual(rojinko.lines[0].speaker, "Suspicious Character")
        // A resource of the wrong length is refused.
        let raw = try XCTUnwrap(r.world.resource(type: "Mcnv", id: 200)).data
        XCTAssertThrowsError(try Conversation(id: 200, data: raw.dropLast()))
    }
}
