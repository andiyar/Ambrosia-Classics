import XCTest
@testable import AkiCore

/// P2.3 — `_ShuffleCustomTiles(char reuse)` @ 0x12763 and `_CountOpenPairs` @ 0xe5e4
/// (docs/aki/rules.md §4.2, §5, §6).
final class DealTests: XCTestCase {

    /// A board with no tiles and zero offsets; tests fill `tiles` directly.
    private func syntheticBoard(_ tiles: [Tile]) -> Board {
        var board = Board(layout: Layout(functionName: "_Synthetic", placements: [], offsetX: 0, offsetY: 0, background: 0))
        board.tiles = tiles
        return board
    }

    /// One tile per face, flags set directly (only open / removed are read by `countOpenPairs`).
    private func flagged(_ faces: [Int], open: [Bool]? = nil, removed: [Bool]? = nil) -> Board {
        syntheticBoard(faces.enumerated().map { i, face in
            var t = Tile(x: 4 * i, y: 0, z: 0)
            t.face = face
            t.isOpen = open?[i] ?? true
            t.isRemoved = removed?[i] ?? false
            return t
        })
    }

    func testFreshDealUsesTheWholeMultiset() {
        var board = Board(layout: Layouts.forLevel(0))
        var rng = SplitMix64(seed: 1)
        let pairs = board.deal(reuse: false, using: &rng)
        XCTAssertEqual(board.tiles.map(\.face).sorted(), Layouts.faceMultiset.sorted())
        XCTAssertEqual(pairs, board.countOpenPairs())
        XCTAssertGreaterThanOrEqual(pairs, 1)
        XCTAssertFalse(board.tiles.contains { $0.isHinted || $0.isSelected })
    }

    func testFreshDealIsSeedDeterministic() {
        var a = Board(layout: Layouts.forLevel(0)), b = Board(layout: Layouts.forLevel(0))
        var rngA = SplitMix64(seed: 42), rngB = SplitMix64(seed: 42)
        let pairsA = a.deal(reuse: false, using: &rngA)
        let pairsB = b.deal(reuse: false, using: &rngB)
        XCTAssertEqual(a.tiles.map(\.face), b.tiles.map(\.face))
        XCTAssertEqual(pairsA, pairsB)
        // regression pin (implementer-computed), not an oracle: Layout 1, SplitMix64(seed: 42).
        XCTAssertEqual(pairsA, 1)
    }

    func testReshuffleReusesTheRemainingFaces() {
        var board = Board(layout: Layouts.forLevel(0))
        var rng = SplitMix64(seed: 7)
        _ = board.deal(reuse: false, using: &rng)
        for i in [0, 37, 90, 143] { board.tiles[i].isRemoved = true }
        let remaining = board.tiles.filter { !$0.isRemoved }.map(\.face).sorted()
        board.deleteRemoved()
        let pairs = board.deal(reuse: true, using: &rng)
        XCTAssertEqual(board.tiles.count, 140)
        XCTAssertEqual(board.tiles.map(\.face).sorted(), remaining)
        XCTAssertGreaterThanOrEqual(pairs, 1)
    }

    func testDealRetriesUntilAPairIsOpen() {
        let faces = [200, 201, 200, 201]
        var board = syntheticBoard(zip([(0, 1), (8, 1), (0, 0), (8, 0)], faces).map { pos, face in
            var t = Tile(x: pos.0, y: 0, z: pos.1)
            t.face = face
            return t
        })
        var rng = ScriptedRNG([1, 0, 2, 3, 1, 2, 0, 3])
        let pairs = board.deal(reuse: true, using: &rng)
        XCTAssertEqual(pairs, 1)
        XCTAssertEqual(rng.consumed, 8)
        XCTAssertEqual(board.tiles.map(\.face), [200, 200, 201, 201])
        XCTAssertEqual(board.tiles.map(\.isOpen), [true, true, false, false])
    }

    func testCountOpenPairsFormula() {
        XCTAssertEqual(flagged([200, 200]).countOpenPairs(), 1)
        XCTAssertEqual(flagged([200, 200, 200]).countOpenPairs(), 1)
        XCTAssertEqual(flagged([200, 200, 200, 200]).countOpenPairs(), 2)
        XCTAssertEqual(flagged([205, 206, 207]).countOpenPairs(), 1)
        XCTAssertEqual(flagged([200, 200, 200, 201, 201, 201]).countOpenPairs(), 2)        // B = 6
        XCTAssertEqual(flagged([200, 200, 200, 201, 201, 201, 202, 202, 202]).countOpenPairs(), 4)  // over-count
        XCTAssertEqual(flagged([200, 201]).countOpenPairs(), 0)
    }

    func testCountIgnoresClosedAndRemoved() {
        XCTAssertEqual(flagged([200, 200], open: [true, false]).countOpenPairs(), 0)
        XCTAssertEqual(flagged([200, 200], removed: [false, true]).countOpenPairs(), 0)
    }
}
