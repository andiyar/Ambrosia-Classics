import BubbleTroubleCore
import XCTest

/// Task 0 — package skeleton, data locator, geometry
/// (docs/plans/2026-10-03-btx-core-and-film-harness.md §Task 0).
final class SkeletonTests: XCTestCase {

    /// The locator must skip — not fail — without data, and the skip must name the variable.
    func testLocatorSkipsNamingTheVariable() {
        do {
            _ = try BTXTestData.resourcesDirectory(environment: [:])
            XCTFail("expected XCTSkip with no \(BTXTestData.variable) in the environment")
        } catch let skip as XCTSkip {
            let text = "\(skip.message ?? "") \(String(describing: skip))"
            XCTAssertTrue(text.contains("HECTORKIT_DATA_BTX"), text)
        } catch {
            XCTFail("expected XCTSkip, got \(error)")
        }
    }

    /// `_RectsCollide @ 0000c398` is strict on all four sides:
    /// `a.left < b.right && b.left < a.right && a.top < b.bottom && b.top < a.bottom`.
    func testRectCollisionIsStrict() {
        let a = QDRect.cell(col: 3, row: 2)
        XCTAssertEqual(a, QDRect(top: 80, left: 120, bottom: 120, right: 160))
        // Edge-sharing neighbours (right, below, left, above) do not collide.
        XCTAssertFalse(a.collides(.cell(col: 4, row: 2)))
        XCTAssertFalse(a.collides(.cell(col: 3, row: 3)))
        XCTAssertFalse(a.collides(.cell(col: 2, row: 2)))
        XCTAssertFalse(a.collides(.cell(col: 3, row: 1)))
        // One pixel of overlap does.
        var b = QDRect.cell(col: 4, row: 2); b.offset(dx: -1, dy: 0)
        XCTAssertTrue(a.collides(b)); XCTAssertTrue(b.collides(a))
        var c = QDRect.cell(col: 3, row: 3); c.offset(dx: 0, dy: -1)
        XCTAssertTrue(a.collides(c)); XCTAssertTrue(c.collides(a))
        XCTAssertTrue(a.collides(a))
    }

    /// `_MyInsetRect @ 0000c3f1`: left += dx, right -= dx, top += dy, bottom -= dy.
    /// `_MyOffsetRect @ 0000c3d2`: left/right += dx, top/bottom += dy.
    func testInsetAndOffset() {
        var r = QDRect.cell(col: 7, row: 6)
        XCTAssertEqual(r, QDRect(top: 240, left: 280, bottom: 280, right: 320))
        r.inset(dx: 8, dy: 8)
        XCTAssertEqual(r, QDRect(top: 248, left: 288, bottom: 272, right: 312))
        r.offset(dx: -5, dy: 0)
        XCTAssertEqual(r, QDRect(top: 248, left: 283, bottom: 272, right: 307))
        XCTAssertEqual(Direction.up.opposite, .down)
        XCTAssertEqual(Direction.down.opposite, .up)
        XCTAssertEqual(Direction.left.opposite, .right)
        XCTAssertEqual(Direction.right.opposite, .left)
    }

    /// Data-gated. `BT Levels.rsrc` is a data-fork resource file; census (Research note 7,
    /// rsrc_census.py): LEVL 50, MAZE 50, FILM 4.
    func testLevelsFileOpens() throws {
        let files = try BTXTestData.files()
        XCTAssertEqual(files.typeCounts["LEVL"], 50)
        XCTAssertEqual(files.typeCounts["MAZE"], 50)
        XCTAssertEqual(files.typeCounts["FILM"], 4)
    }
}
