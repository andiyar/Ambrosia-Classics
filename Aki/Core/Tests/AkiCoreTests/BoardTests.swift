import XCTest
@testable import AkiCore

/// P2.2 — the board model: `_AddTile` @ 0x146bc, `_SetVisibleTiles` @ 0x12328, `_SetOpenTiles` @ 0x1245e,
/// the `_SelectCGTile` @ 0x13eec match predicate and hit box, `_DeleteTile` (docs/aki/rules.md §1–§4, §7, §8).
final class BoardTests: XCTestCase {

    /// A board with no tiles and zero offsets; tests fill `tiles` directly.
    private func syntheticBoard(_ tiles: [Tile]) -> Board {
        var board = Board(layout: Layout(functionName: "_Synthetic", placements: [], offsetX: 0, offsetY: 0, background: 0))
        board.tiles = tiles
        return board
    }

    private func layout1Fresh() -> Board {
        var board = Board(layout: Layouts.forLevel(0))
        board.setVisibleTiles()
        board.setOpenTiles()
        return board
    }

    func testInitFromLayoutDoublesNothingAndInvertsLayer() {
        let board = Board(layout: Layouts.forLevel(0))
        XCTAssertEqual(board.tiles.count, 144)
        let t0 = board.tiles[0]
        XCTAssertEqual([t0.x, t0.y, t0.z], [10, 16, 2])
        XCTAssertTrue(t0.isVisible)
        XCTAssertEqual(t0.face, 0)
        XCTAssertEqual(t0.fadeFrame, 0)
        XCTAssertFalse(t0.isOpen || t0.isHinted || t0.isSelected || t0.isRemoved || t0.isFading)
        let t143 = board.tiles[143]
        XCTAssertEqual([t143.x, t143.y, t143.z], [22, 6, 5])
        XCTAssertEqual(board.offsetX, 0)
        XCTAssertEqual(board.offsetY, -40)
    }

    func testVisibilityLooksOnlyOneLayerUp() {
        let t = Tile(x: 10, y: 10, z: 0)
        var b = syntheticBoard([t, Tile(x: 11, y: 11, z: 1)])
        b.setVisibleTiles()
        XCTAssertFalse(b.tiles[0].isVisible, "U(11,11,z1) overlaps by one half-unit → covered")

        b = syntheticBoard([t, Tile(x: 12, y: 10, z: 1)])
        b.setVisibleTiles()
        XCTAssertTrue(b.tiles[0].isVisible, "U(12,10,z1) is two half-units off → visible")

        b = syntheticBoard([t, Tile(x: 10, y: 10, z: 2)])
        b.setVisibleTiles()
        XCTAssertTrue(b.tiles[0].isVisible, "only W(10,10,z2) above (gap layer) → visible")

        var removed = Tile(x: 10, y: 10, z: 1)
        removed.isRemoved = true
        b = syntheticBoard([t, removed])
        b.setVisibleTiles()
        XCTAssertTrue(b.tiles[0].isVisible, "removed U never covers")
    }

    func testOpenNeedsAFreeSideAtTwoHalfUnits() {
        let t = Tile(x: 10, y: 10, z: 0)
        let left = Tile(x: 8, y: 11, z: 0)
        let right = Tile(x: 12, y: 9, z: 0)

        var b = syntheticBoard([t, left, right])
        b.setVisibleTiles(); b.setOpenTiles()
        XCTAssertFalse(b.tiles[0].isOpen, "both sides blocked → closed")

        var removedRight = right
        removedRight.isRemoved = true
        b = syntheticBoard([t, left, removedRight])
        b.setVisibleTiles(); b.setOpenTiles()
        XCTAssertTrue(b.tiles[0].isOpen, "right neighbour removed → open")

        b = syntheticBoard([t, Tile(x: 11, y: 10, z: 0)])
        b.setVisibleTiles(); b.setOpenTiles()
        XCTAssertTrue(b.tiles[0].isOpen, "a neighbour at x+1 never blocks")

        b = syntheticBoard([t, left, right, Tile(x: 12, y: 9, z: 1)])
        b.setVisibleTiles(); b.setOpenTiles()
        XCTAssertFalse(b.tiles[2].isVisible)
        XCTAssertFalse(b.tiles[0].isOpen, "an invisible (covered) neighbour still blocks")

        b = syntheticBoard([t, Tile(x: 10, y: 10, z: 1)])
        b.setVisibleTiles(); b.setOpenTiles()
        XCTAssertFalse(b.tiles[0].isOpen, "a covered tile is never open")
    }

    func testFreshLayout1VisibleAndOpenCounts() {
        let b = layout1Fresh()
        XCTAssertEqual(b.tiles.filter(\.isVisible).count, 36)
        XCTAssertEqual(b.tiles.filter(\.isOpen).count, 24)
        let top = b.tiles.filter { $0.z == 5 }
        XCTAssertEqual(Set(top.map(\.x)), [10, 12, 14, 18, 20, 22])
        XCTAssertEqual(Set(b.tiles.filter(\.isOpen).map(\.x)), [10, 14, 18, 22])
        XCTAssertTrue(b.tiles.filter(\.isOpen).allSatisfy { $0.z == 5 })
    }

    func testMatchesSameFaceOrAnyTwoSeasons() {
        XCTAssertTrue(Board.matches(213, 213))
        XCTAssertTrue(Board.matches(205, 212))
        XCTAssertFalse(Board.matches(204, 205))
        XCTAssertFalse(Board.matches(212, 213))
        XCTAssertFalse(Board.matches(200, 201))
    }

    func testPixelBoxFormula() {
        XCTAssertEqual(Board.pixelBox(of: Tile(x: 15, y: 1, z: 0), offsetX: 0, offsetY: 0),
                       QDRect(left: 345, top: 27, right: 396, bottom: 87))
        let layout2 = Board(layout: Layouts.forLevel(1))
        XCTAssertEqual([layout2.tiles[0].x, layout2.tiles[0].y, layout2.tiles[0].z], [16, 18, 1])
        XCTAssertEqual([layout2.offsetX, layout2.offsetY], [-4, -45])
        XCTAssertEqual(layout2.pixelBox(of: 0), QDRect(left: 377, top: 440, right: 428, bottom: 500))
        XCTAssertEqual(Board.pixelBox(of: Tile(x: 0, y: 15, z: 0), offsetX: 0, offsetY: 0).top, 412,
                       "27.5 · 15 = 412.5 truncates to 412")
    }

    func testStaticPixelBoxMatchesInstance() {
        let b = Board(layout: Layouts.forLevel(6))
        XCTAssertEqual(b.tiles.count, 144)
        for i in b.tiles.indices {
            XCTAssertEqual(Board.pixelBox(of: b.tiles[i], offsetX: b.offsetX, offsetY: b.offsetY), b.pixelBox(of: i), "tile \(i)")
        }
    }

    func testDeleteRemovedKeepsOrder() {
        var b = Board(layout: Layouts.forLevel(0))
        let former8 = b.tiles[8]
        b.tiles[3].isRemoved = true
        b.tiles[7].isRemoved = true
        b.deleteRemoved()
        XCTAssertEqual(b.tiles.count, 142)
        XCTAssertEqual(b.tiles[6], former8)
        XCTAssertFalse(b.tiles.contains(where: \.isRemoved))
    }

    func testCounts() throws {
        var b = layout1Fresh()
        XCTAssertEqual(b.unremovedCount, 144)
        XCTAssertEqual(b.openUnremovedCount, 24)
        // Remove the two open top-layer (z 5) tiles at x2 10 and x2 14 in the same row (y2 16), then recompute.
        // open-unremoved = 24 − 2 (removed) + 1 (the neighbour at x2 12 now has a free left side)
        //                + 2 (the z 4 tiles directly under the two removed ones are uncovered and have a free side) = 25.
        // plan P2.2 said 22 (no-recompute arithmetic); seat ruled 25 on 2026-10-04 — never edit an expectation to match without a ruling
        let left = try XCTUnwrap(b.tiles.firstIndex { $0.z == 5 && $0.x == 10 && $0.y == 16 })
        let right = try XCTUnwrap(b.tiles.firstIndex { $0.z == 5 && $0.x == 14 && $0.y == 16 })
        XCTAssertTrue(b.tiles[left].isOpen && b.tiles[right].isOpen)
        b.tiles[left].isRemoved = true
        b.tiles[right].isRemoved = true
        b.setVisibleTiles()
        b.setOpenTiles()
        XCTAssertEqual(b.unremovedCount, 142)
        XCTAssertEqual(b.openUnremovedCount, 25)
    }
}
