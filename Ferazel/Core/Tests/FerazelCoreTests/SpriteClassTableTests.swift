import XCTest
import HectorResources
@testable import FerazelCore

/// C2 (docs/plans/2026-10-06-ferazel-phase1.md): sprite type → class + spawn (world-data §3.5, `.GenerateSprite`;
/// cross-check `docs/ferazel/tools/gensprite_map.py`) and the `.SetupLevelSprites` spawn order (§3.4), against
/// the committed `Resources/Ferazel` (D26). Numbers are planner probes (p02, p21 = Research note 12).
final class SpriteClassTableTests: XCTestCase {

    private static let levelIds: [Int16] = [1, 2, 3, 4, 5, 10, 11, 15, 18, 20, 21, 22, 25, 30, 31, 40, 45, 50, 51,
                                            52, 55, 62, 67, 70]

    private func resources() throws -> FerazelResources {
        try FerazelData.open(try FerazelData.dataDirectory())
    }

    func testEveryPlacedTypeHasAClass() throws {
        let r = try resources()
        var types = Set<Int16>(), totals: [SpriteClass: Int] = [:], unmapped: [Int16] = []
        for id in Self.levelIds {
            for p in try LevelFile.load(from: r, level: id).activePlacements {
                types.insert(p.type)
                if let (c, _) = SpriteClassTable.classify(type: p.type, p1Negative: p.p1 < 0) {
                    totals[c, default: 0] += 1
                } else {
                    unmapped.append(p.type)
                }
            }
        }
        XCTAssertEqual(types.count, 243)
        XCTAssertEqual(unmapped, [])
        // Research note 12 (p21): the census `classes` line.
        XCTAssertEqual(totals, [.platform: 169, .bonus: 2895, .background: 1274, .box: 759, .demon: 1, .wizard: 1,
                                .gremlin: 50, .walker: 158, .salamander: 22, .blob: 29, .rope: 49, .button: 24,
                                .crawler: 31, .bat: 89, .chief: 1, .xichra: 1, .frog: 41, .dillo: 20, .warrior: 1,
                                .roach: 16, .floater: 7, .crab: 3])
        XCTAssertEqual(totals.values.reduce(0, +), 5_641)
        XCTAssertEqual(SpriteClass.allCases.count, 23)
        // §3.5: 1830 (0x726) is inside the 1700..1839 sub-chain → Wizard; the later `0x726 → Effect` arm is dead.
        XCTAssertEqual(SpriteClassTable.classify(type: 1830, p1Negative: false)?.0, .wizard)
        // Types that spawn nothing (§3.5): 1710/1711, 1713..1719, 1721..1729, 1844..1849, and anything unlisted.
        for t: Int16 in [0, 1, 1000, 1710, 1711, 1713, 1719, 1721, 1729, 1844, 1849, 3250, 5000, -1] {
            XCTAssertNil(SpriteClassTable.classify(type: t, p1Negative: false), "type \(t)")
        }
    }

    func testLevel1ClassesAndSpawn() throws {
        let level = try LevelFile.load(from: try resources(), level: 1)
        var now: [SpriteClass: [Int16]] = [:], idle = 0
        for p in level.activePlacements {
            let (c, spawn) = try XCTUnwrap(SpriteClassTable.classify(type: p.type, p1Negative: p.p1 < 0))
            switch spawn {
            case .now: now[c, default: []].append(p.type)
            case .idle: idle += 1
            }
        }
        XCTAssertEqual(now[.platform]?.count, 7)
        XCTAssertEqual(now[.bonus], [1335])
        XCTAssertEqual(now[.background], [1485, 1485])
        XCTAssertEqual(Set(now.keys), [.platform, .bonus, .background])
        XCTAssertEqual(idle, 162 - 10)
        // 1090..1099 Background: idle, or now when param 1 < 0 (§3.5).
        for t: Int16 in [1090, 1099] {
            XCTAssertEqual(SpriteClassTable.classify(type: t, p1Negative: false)?.0, .background)
            XCTAssertEqual(SpriteClassTable.classify(type: t, p1Negative: false)?.1, .idle)
            XCTAssertEqual(SpriteClassTable.classify(type: t, p1Negative: true)?.1, .now)
        }
        // p1 < 0 changes nothing outside 1090..1099.
        for t: Int16 in [1089, 1100, 1400, 1700, 2902] {
            let a = SpriteClassTable.classify(type: t, p1Negative: false)
            let b = SpriteClassTable.classify(type: t, p1Negative: true)
            XCTAssertEqual(a?.0, b?.0, "type \(t)"); XCTAssertEqual(a?.1, b?.1, "type \(t)")
        }
    }

    func testSpawnOrder() throws {
        let level = try LevelFile.load(from: try resources(), level: 1)
        let order = level.spawnOrder
        XCTAssertEqual(order.count, level.activePlacements.count)
        XCTAssertEqual(Set(order.map(\.index)), Set(level.activePlacements.map(\.index)))
        XCTAssertEqual(order.prefix(22).map(\.type), Array(repeating: 1307, count: 22))
        XCTAssertTrue(order.dropFirst(22).prefix(7).allSatisfy { (1400...1429).contains($0.type) })
        XCTAssertFalse(order.dropFirst(29).contains { $0.type == 1307 || (1400...1429).contains($0.type) })
        // Within each group, record order.
        for group in [Array(order.prefix(22)), Array(order.dropFirst(22).prefix(7)), Array(order.dropFirst(29))] {
            XCTAssertEqual(group.map(\.index), group.map(\.index).sorted())
        }
    }
}
