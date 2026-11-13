import XCTest
@testable import DeimosCore

/// `Trig` — the start-up tables of `FUN_10042920` and the heading helpers (units-movement.md §2.2–§2.3,
/// loose-ends-combat.md §1). Float results are pinned by bit pattern (plan invariant 7). The table values
/// were derived on 2026-10-07 by an independent float32/mpmath emulation of the listing (C7 PR notes):
/// every sin/cos entry lies ≥ 150,821 double ulps from a float32 rounding boundary, every atan product
/// ≥ 1,446,053 ulps from an integer, every sqrt ≥ 953 ulps from a float32 boundary — so any libm (Mac
/// MathLib, Darwin, glibc, MSVC) within those errors builds the identical tables.
final class TrigTests: XCTestCase {
    private func bits(_ f: Float) -> UInt32 { f.bitPattern }

    func testTrigTablesAsRead() {
        XCTAssertEqual(Trig.sinTable.count, 360)
        XCTAssertEqual(Trig.cosTable.count, 360)
        XCTAssertEqual(Trig.atanTable.count, 1024)
        XCTAssertEqual(Trig.sqrtTable.count, 16384)
        XCTAssertEqual(bits(Trig.degreesToRadians), 0x3c8e_fa35)               // *(float*)0x100d7318
        // The angle is the single-precision product fl32(0.017453292f · i) (10042a2c fsubs, 10042a30 fmuls).
        XCTAssertEqual(bits(Trig.sin(0)), 0x0000_0000)
        XCTAssertEqual(bits(Trig.cos(0)), 0x3f80_0000)
        XCTAssertEqual(bits(Trig.sin(90)), 0x3f80_0000)                        // 1.0
        XCTAssertEqual(bits(Trig.cos(90)), 0xb33b_bd2e)                        // −4.371139e−8
        XCTAssertEqual(bits(Trig.sin(180)), 0xb3bb_bd2e)                       // −8.742278e−8
        XCTAssertEqual(bits(Trig.cos(180)), 0xbf80_0000)                       // −1.0
        XCTAssertEqual(bits(Trig.sin(30)), 0x3f00_0000)
        XCTAssertEqual(bits(Trig.cos(60)), 0x3eff_ffff)
        XCTAssertEqual(bits(Trig.sin(1)), 0x3c8e_f859)
        // 360 → 0 in both accessors (FUN_10042f00 / FUN_10042ee0 `cmpwi r3,0x168`).
        XCTAssertEqual(bits(Trig.sin(360)), bits(Trig.sin(0)))
        XCTAssertEqual(bits(Trig.cos(360)), bits(Trig.cos(0)))
        // Whole-table witnesses (sum of the 360 bit patterns; emulation 2026-10-07).
        XCTAssertEqual(Trig.sinTable.reduce(UInt64(0)) { $0 + UInt64($1.bitPattern) }, 765_787_171_276)
        XCTAssertEqual(Trig.cosTable.reduce(UInt64(0)) { $0 + UInt64($1.bitPattern) }, 766_622_680_769)
        // atan: trunc(atan(0.01·i)·57.2957795) in double. The shipped constant is the truncated literal
        // 57.2957795 (0x404ca5dc1a47a9e3), so index 100 (ratio 1) gives 44.99999998972517 → 44, not 45.
        XCTAssertEqual(Array(Trig.atanTable[0..<6]), [0, 0, 1, 1, 2, 2])
        XCTAssertEqual(Trig.atanTable[100], 44)
        XCTAssertEqual(Trig.atanTable[1023], 84)
        XCTAssertEqual(Trig.atanTable.reduce(0) { $0 + Int($1) }, 72_543)
        // sqrt: (float)sqrt((double)(float)n).
        XCTAssertEqual(Trig.sqrtTable.reduce(UInt64(0)) { $0 + UInt64($1.bitPattern) }, 18_308_834_383_206)
    }

    func testCompassToInternal() {
        // FUN_10043040: h ≤ 180 → |h − 180|; else 540 − h.
        XCTAssertEqual(Trig.internalHeading(0), 180)
        XCTAssertEqual(Trig.internalHeading(90), 90)
        XCTAssertEqual(Trig.internalHeading(180), 0)
        XCTAssertEqual(Trig.internalHeading(270), 270)
        XCTAssertEqual(Trig.internalHeading(359), 181)
        // FUN_10042b80: (speed·S[h'], speed·C[h']), `fmuls`.
        let down = Trig.vector(heading: Trig.internalHeading(180), speed: 6)
        XCTAssertEqual(bits(down.x), 0x0000_0000)                              // 6·S[0] = 0
        XCTAssertEqual(bits(down.y), 0x40c0_0000)                              // 6·C[0] = 6
        let up = Trig.vector(heading: Trig.internalHeading(0), speed: 10)
        XCTAssertEqual(bits(up.x), 0xb56a_ac7a)                                // 10·S[180] = −8.742278e−7
        XCTAssertEqual(bits(up.y), 0xc120_0000)                                // 10·C[180] = −10 exactly
        let unit = Trig.unitVector(heading: 90)
        XCTAssertEqual(bits(unit.x), 0x3f80_0000)
        XCTAssertEqual(bits(unit.y), 0xb33b_bd2e)
    }

    func testHeadingToPoint() {
        // FUN_10042ad0(x, y, tx, ty) → FUN_10043090(x − tx, y − ty): compass degrees toward (tx, ty).
        XCTAssertEqual(Trig.headingTo(x: 100, y: 100, tx: 100, ty: 50), 0)      // above
        XCTAssertEqual(Trig.headingTo(x: 100, y: 100, tx: 150, ty: 100), 90)    // right
        XCTAssertEqual(Trig.headingTo(x: 100, y: 100, tx: 100, ty: 150), 180)   // below
        XCTAssertEqual(Trig.headingTo(x: 100, y: 100, tx: 50, ty: 100), 270)    // left
        // Up-right diagonal: ratio 1 → atan[100] = 44 → 180 − 44 − 90 = 46 (the truncated constant).
        XCTAssertEqual(Trig.headingTo(x: 100, y: 100, tx: 150, ty: 50), 46)
        XCTAssertEqual(Trig.headingTo(x: 100, y: 100, tx: 50, ty: 150), 226)
        // Same point: 0/0 = NaN → fctiwz 0x80000000 → index clamped to 0 → 90 − 0 … − 90 → 270.
        XCTAssertEqual(Trig.headingTo(x: 5, y: 5, tx: 5, ty: 5), 270)
        // FUN_10042cd0 (internal convention): the cardinal branches, NaN/zero → 0.
        XCTAssertEqual(Trig.headingOf(vx: 0, vy: 1), 0)
        XCTAssertEqual(Trig.headingOf(vx: 1, vy: 0), 90)
        XCTAssertEqual(Trig.headingOf(vx: 0, vy: -1), 180)
        XCTAssertEqual(Trig.headingOf(vx: -1, vy: 0), 270)
        XCTAssertEqual(Trig.headingOf(vx: 0, vy: 0), 0)
        XCTAssertEqual(Trig.headingOf(vx: .nan, vy: 1), 0)
        // The truncation quirk (loose-ends-combat §1.3): the heading of (S[h'], C[h']) comes back as h' − 1
        // for 34 of the 360 headings (emulation 2026-10-07; every atan result ≥ 765,136 double ulps from a
        // float32 boundary, so the set does not depend on the libm).
        XCTAssertEqual(Trig.headingOf(vx: Trig.sin(1), vy: Trig.cos(1)), 0)
        XCTAssertEqual(Trig.headingOf(vx: Trig.sin(2), vy: Trig.cos(2)), 1)
        XCTAssertEqual(Trig.headingOf(vx: Trig.sin(45), vy: Trig.cos(45)), 45)
        XCTAssertEqual(Trig.headingOf(vx: Trig.sin(46), vy: Trig.cos(46)), 45)
        let shifted = (0..<360).filter { h in Trig.headingOf(vx: Trig.sin(Int32(h)), vy: Trig.cos(Int32(h))) != h }
        XCTAssertEqual(shifted.count, 34)
        XCTAssertEqual(Array(shifted.prefix(6)), [1, 2, 4, 13, 27, 31])
    }

    func testDistanceTruncatesSquare() {
        // FUN_10042e90 = root(fctiwz(fmadds(dx, dx, dy·dy))).
        XCTAssertEqual(Trig.distance(x0: 0, y0: 0, x1: 3, y1: 4), 5)
        XCTAssertEqual(Trig.distance(x0: 0, y0: 0, x1: 0.5, y1: 0.9), 1)       // 1.06 → 1 → root(1)
        XCTAssertEqual(Trig.distance(x0: 0, y0: 0, x1: 0.5, y1: 0.5), 0)       // 0.5 → 0
        // FUN_10042f20: the table below 0x4000, the formula above (same expression).
        XCTAssertEqual(Trig.root(25), 5)
        XCTAssertEqual(Trig.root(0x4000), 128)
        XCTAssertEqual(bits(Trig.root(2)), Float(2).squareRoot().bitPattern)
        XCTAssertEqual(bits(Trig.root(20_000)), Float(Foundation.sqrt(20_000.0)).bitPattern)
    }
}
