import XCTest
@testable import DeimosCore

/// MSL `rand`/`srand` and the two RandomRange variants: engine-loop.md §9 (HIGH); listing
/// `FUN_100553e0`, `FUN_10046580` (`10046580…100465dc`), `FUN_100465e0` (`100465fc…1004665c`).
final class RandomTests: XCTestCase {
    func testRandSeedOne() {
        var r = MSLRandom(seed: 1)
        XCTAssertEqual([r.rand(), r.rand(), r.rand()], [16838, 5758, 10113])
    }

    func testRandSeedDemo01() {
        // Demo 01's film seed (engine-loop.md §7 worked decode).
        var r = MSLRandom(seed: 0)
        r.srand(0x469c2)
        XCTAssertEqual([r.rand(), r.rand(), r.rand()], [26662, 28174, 2951])
    }

    func testIntRange() {
        var r = MSLRandom(seed: 0x469c2)
        XCTAssertEqual(r.range(Int32(400), Int32(2000)), 1446)
        let before = r.state
        XCTAssertEqual(r.range(Int32(5), Int32(5)), 5)
        XCTAssertEqual(r.state, before, "min == max must not draw")
    }

    func testFloatRange() {
        func fresh() -> MSLRandom { MSLRandom(seed: 1) }
        // Each after its own srand(1) (review I3); float32 bits exact.
        var a = fresh(); XCTAssertEqual(a.range(Float(1.0), Float(2.0)).bitPattern, Float(1.5138707).bitPattern)
        var b = fresh(); XCTAssertEqual(b.range(Float(2.0), Float(1.0)).bitPattern, Float(0.48612934).bitPattern)
        var c = fresh(); XCTAssertEqual(c.range(Float(0.8), Float(1.2)).bitPattern, Float(1.0055482).bitPattern)
        var d = fresh()
        XCTAssertEqual(d.range(Float(1.5), Float(1.5)), 1.5)
        XCTAssertEqual(d.state, 1, "lo == hi must not draw")
        // Sequential after one srand(1).
        var s = fresh()
        let triple = [s.range(Float(1.0), Float(2.0)), s.range(Float(2.0), Float(1.0)), s.range(Float(0.8), Float(1.2))]
        XCTAssertEqual(triple.map(\.bitPattern),
                       [Float(1.5138707), Float(0.8242744), Float(0.9234535)].map(\.bitPattern))
    }
}
