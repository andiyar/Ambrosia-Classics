import XCTest
@testable import AkiCore

/// P2.5 — `_SelectCGTile` @ 0x13eec, `_RedrawMatchedTiles` @ 0x13af5, `_CalculateSurroundingTiles` @ 0x138a7 and
/// the click gating of `-[Controller mouseDown:]` @ 0x4489 (docs/aki/rules.md §7, §8).
final class SelectTests: XCTestCase {

    // MARK: helpers

    private func tile(_ x: Int, _ y: Int, _ z: Int, face: Int) -> Tile {
        var t = Tile(x: x, y: y, z: z)
        t.face = face
        return t
    }

    /// A synthetic board (offsets as given, 0 by default) with visibility and openness computed.
    private func game(_ tiles: [Tile], difficultyRaw: Int16 = 1, levelIndex: Int = 0,
                      offsetX: Int = 0, offsetY: Int = 0) -> AkiGame {
        var board = Board(layout: Layout(functionName: "_Synthetic", placements: [], offsetX: offsetX,
                                         offsetY: offsetY, background: 0))
        board.tiles = tiles
        board.setVisibleTiles()
        board.setOpenTiles()
        return AkiGame(board: board, difficultyRaw: difficultyRaw, levelIndex: levelIndex)
    }

    /// A point inside tile `i`'s box that `_SelectCGTile`'s z 6→0, list-order scan resolves to `i`.
    private func clickPoint(_ game: AkiGame, _ i: Int) -> (h: Int, v: Int)? {
        let box = game.board.pixelBox(of: i)
        for v in box.top..<box.bottom {
            for h in box.left..<box.right {
                let first = (0...6).reversed().lazy.compactMap { layer in
                    game.board.tiles.indices.first { j in
                        let t = game.board.tiles[j]
                        let b = game.board.pixelBox(of: j)
                        return t.z == layer && t.isOpen && !t.isRemoved
                            && b.left <= h && h < b.right && b.top <= v && v < b.bottom
                    }
                }.first
                if first == i { return (h, v) }
            }
        }
        return nil
    }

    @discardableResult
    private func click(_ game: inout AkiGame, _ i: Int, animation: Bool = true) -> [GameEvent] {
        guard let p = clickPoint(game, i) else { XCTFail("no click point resolves to tile \(i)"); return [] }
        return game.selectTile(h: p.h, v: p.v, tileAnimation: animation)
    }

    /// The first pair of open, not-removed, matching tiles in list order that each have a resolving click point.
    private func openPair(_ game: AkiGame, where accept: (Int, Int) -> Bool = { _, _ in true }) -> (Int, Int)? {
        let t = game.board.tiles
        for i in t.indices where t[i].isOpen && !t[i].isRemoved && clickPoint(game, i) != nil {
            for j in t.indices where j != i && t[j].isOpen && !t[j].isRemoved && Board.matches(t[i].face, t[j].face)
                && accept(i, j) && clickPoint(game, j) != nil {
                return (i, j)
            }
        }
        return nil
    }

    private func fadeJob(_ events: [GameEvent]) -> FadeJob? {
        for e in events { if case .fade(let job) = e { return job } }
        return nil
    }

    // MARK: select / deselect

    func testClickOpenTileSelects() {
        var g = game([tile(0, 0, 0, face: 200), tile(10, 0, 0, face: 201)])
        let events = g.selectTile(h: 10, v: 10, tileAnimation: true)
        XCTAssertEqual(events, [.playSound(.tilehit, volume: 128), .redrawTile(0)])
        XCTAssertEqual(g.selected, 0)
        XCTAssertTrue(g.board.tiles[0].isSelected)
    }

    func testClickSelectedTileDeselects() {
        var g = game([tile(0, 0, 0, face: 200), tile(10, 0, 0, face: 201)])
        _ = g.selectTile(h: 10, v: 10, tileAnimation: true)
        let events = g.selectTile(h: 10, v: 10, tileAnimation: true)
        XCTAssertEqual(events, [.playSound(.unclick, volume: 128), .redrawTile(0)])
        XCTAssertNil(g.selected)
        XCTAssertFalse(g.board.tiles[0].isSelected)
    }

    func testCoveredTileIsSkippedForALowerOpenTileUnderThePoint() {
        // W(9,9,z2) box h 217…267 (misses h 280); U(10,10,z1) is covered by W; C(12,10,z0) is open.
        var g = game([tile(9, 9, 2, face: 220), tile(10, 10, 1, face: 221), tile(12, 10, 0, face: 222)])
        XCTAssertFalse(g.board.tiles[1].isOpen)
        XCTAssertTrue(g.board.tiles[2].isOpen)
        let events = g.selectTile(h: 280, v: 300, tileAnimation: true)
        XCTAssertEqual(events, [.playSound(.tilehit, volume: 128), .redrawTile(2)])
        XCTAssertEqual(g.selected, 2)
    }

    func testUpperMismatchWithoutLowerHitClearsSelection() {
        var g = game([tile(30, 30, 0, face: 213), tile(10, 10, 1, face: 214)])
        click(&g, 0)
        XCTAssertEqual(g.selected, 0)
        let events = g.selectTile(h: 240, v: 280, tileAnimation: true)
        XCTAssertEqual(events, [.playSound(.cancel, volume: 128), .playSound(.unclick, volume: 128), .redrawTile(0)])
        XCTAssertNil(g.selected)
        XCTAssertFalse(g.board.tiles[0].isSelected)
    }

    func testLayerZeroMismatchKeepsSelection() {
        var g = game([tile(30, 30, 0, face: 213), tile(10, 10, 0, face: 214)])
        click(&g, 0)
        let events = g.selectTile(h: 240, v: 280, tileAnimation: true)
        XCTAssertEqual(events, [.playSound(.cancel, volume: 128)])
        XCTAssertEqual(g.selected, 0)
        XCTAssertTrue(g.board.tiles[0].isSelected)
    }

    func testMismatchThenLowerOverlappingTileMatches() {
        var g = game([tile(30, 30, 0, face: 213), tile(10, 10, 1, face: 214), tile(12, 10, 0, face: 213)])
        click(&g, 0)
        let events = g.selectTile(h: 280, v: 300, tileAnimation: true)
        XCTAssertGreaterThanOrEqual(events.count, 4)
        XCTAssertEqual(Array(events.prefix(3)),
                       [.playSound(.cancel, volume: 128), .stopSound(.cancel), .playSound(.tileMatch, volume: 128)])
        XCTAssertNotNil(events.count > 3 ? fadeJob([events[3]]) : nil)
        XCTAssertEqual(g.board.tiles.map(\.isRemoved), [true, false, true])
        XCTAssertNil(g.selected)
    }

    // MARK: match path

    func testMatchEventOrderAndCounts() {
        for (raw, undo) in [(Int16(1), false), (2, true), (3, true)] {
            var g = AkiGame(layout: Layouts.forLevel(0), difficultyRaw: raw, levelIndex: 0)
            var rng = SplitMix64(seed: 7)
            g.dealFresh(using: &rng)
            XCTAssertEqual(g.tilesLeft, 144)
            XCTAssertGreaterThan(g.openPairs, 0)
            guard let (a, b) = openPair(g) else { return XCTFail("no open pair") }
            click(&g, a)
            let events = click(&g, b)
            guard let job = fadeJob(events) else { return XCTFail("no fade") }
            var expected: [GameEvent] = [.stopSound(.cancel), .playSound(.tileMatch, volume: 128), .fade(job),
                                         .redrawOpenPairs(flush: false)]
            if g.openPairs == 0 { expected += [.stopMusic, .playSound(.reshuffle, volume: 256)] }
            expected += [.redrawGameScreen(tiles: true), .applyMatchBonus]
            XCTAssertEqual(events, expected, "raw \(raw)")
            XCTAssertEqual(g.tilesLeft, 142)
            XCTAssertEqual(g.openPairs, g.board.countOpenPairs())
            XCTAssertEqual(g.undoEnabled, undo, "raw \(raw)")
            XCTAssertNil(g.selected)
        }
    }

    func testSecondMatchDeletesThePreviousPair() {
        var g = AkiGame(layout: Layouts.forLevel(0), difficultyRaw: 1, levelIndex: 0)
        var rng = SplitMix64(seed: 7)
        g.dealFresh(using: &rng)
        guard let (a, b) = openPair(g) else { return XCTFail("no first pair") }
        click(&g, a)
        click(&g, b)
        XCTAssertEqual(g.board.tiles.count, 144)
        let lowFirst = min(a, b)
        // A second pair whose selected index lies past a removed tile, so deleteRemoved shifts it.
        guard let (s, c) = openPair(g, where: { s, _ in s > lowFirst }) else { return XCTFail("no second pair") }
        click(&g, s)
        XCTAssertEqual(g.selected, s)
        let pairCells = Set([s, c].map { [g.board.tiles[$0].x, g.board.tiles[$0].y, g.board.tiles[$0].z] })
        click(&g, c)
        XCTAssertEqual(g.board.tiles.count, 142)
        let removed = g.board.tiles.filter(\.isRemoved)
        XCTAssertEqual(removed.count, 2)
        XCTAssertEqual(Set(removed.map { [$0.x, $0.y, $0.z] }), pairCells)
        XCTAssertFalse(g.board.tiles.contains { $0.isSelected || $0.isFading })
        XCTAssertNil(g.selected)
        XCTAssertEqual(g.tilesLeft, 140)
    }

    func testStackedLossEndsTheLevel() {
        for level in [0, 13] {
            var g = game([tile(0, 0, 0, face: 200), tile(4, 0, 0, face: 200),
                          tile(20, 0, 0, face: 201), tile(20, 0, 1, face: 201)], levelIndex: level)
            _ = g.selectTile(h: 10, v: 10, tileAnimation: true)
            let events = g.selectTile(h: 100, v: 10, tileAnimation: true)
            guard let job = fadeJob(events) else { return XCTFail("no fade") }
            var expected: [GameEvent] = [.stopSound(.cancel), .playSound(.tileMatch, volume: 128), .fade(job),
                                         .redrawOpenPairs(flush: false), .stopMusic,
                                         .playSound(.reshuffle, volume: 256), .redrawGameScreen(tiles: true),
                                         .dialog(0x47), .setLost, .setEndLevel]
            if level == 13 { expected.append(.setCustomLost) }
            expected.append(.applyMatchBonus)
            XCTAssertEqual(events, expected, "level \(level)")
            XCTAssertEqual(g.isCustom, level == 13)
            XCTAssertEqual(g.tilesLeft, 2)
            XCTAssertEqual(g.openPairs, 0)
        }
    }

    func testLastPairSetsEndLevelOnly() {
        var g = game([tile(0, 0, 0, face: 200), tile(4, 0, 0, face: 200)])
        _ = g.selectTile(h: 10, v: 10, tileAnimation: true)
        let events = g.selectTile(h: 100, v: 10, tileAnimation: true)
        guard let job = fadeJob(events) else { return XCTFail("no fade") }
        XCTAssertEqual(events, [.stopSound(.cancel), .playSound(.tileMatch, volume: 128), .fade(job),
                                .redrawOpenPairs(flush: false), .stopMusic, .playSound(.reshuffle, volume: 256),
                                .setEndLevel, .applyMatchBonus])
        XCTAssertEqual(g.tilesLeft, 0)
    }

    func testFadeJobSnapshot() {
        // List: R (already removed — deleted by step 2), S selected, N1, K clicked, N2, F far, N3, E just outside.
        var r = tile(16, 6, 0, face: 230); r.isRemoved = true
        var n1 = tile(14, 10, 0, face: 231); n1.isHinted = true
        let tiles = [r, tile(10, 10, 0, face: 200), n1, tile(20, 10, 0, face: 200), tile(24, 14, 1, face: 232),
                     tile(30, 10, 0, face: 233), tile(6, 6, 0, face: 234), tile(25, 10, 0, face: 235)]
        for animation in [true, false] {
            var g = game(tiles, offsetX: 7, offsetY: 3)
            click(&g, 1, animation: animation)
            XCTAssertEqual(g.selected, 1)
            let events = click(&g, 3, animation: animation)
            guard let job = fadeJob(events) else { return XCTFail("no fade") }
            // Sweep z 0→6, d 0→49, k 0→32, (x, y) = (32−k, d−k): z0 K(d 22), N1(d 28), S(d 32, x 10), N3(d 32, x 6); z1 N2.
            func snap(_ x: Int, _ y: Int, _ z: Int, _ face: Int, fading: Bool) -> Tile {
                var t = Tile(x: x, y: y, z: z)
                t.face = face
                t.isFading = fading
                t.fadeFrame = animation ? 0 : 10
                return t
            }
            XCTAssertEqual(job.surrounding, [snap(20, 10, 0, 200, fading: true), snap(14, 10, 0, 231, fading: false),
                                             snap(10, 10, 0, 200, fading: true), snap(6, 6, 0, 234, fading: false),
                                             snap(24, 14, 1, 232, fading: false)])
            XCTAssertEqual([job.clicked.x, job.clicked.y, job.clicked.z], [20, 10, 0])
            XCTAssertEqual([job.selected.x, job.selected.y, job.selected.z], [10, 10, 0])
            XCTAssertTrue(job.clicked.isFading)
            XCTAssertTrue(job.selected.isFading)
            XCTAssertFalse(job.clicked.isSelected || job.selected.isSelected)
            XCTAssertEqual(job.animate, animation)
            XCTAssertEqual(job.offsetX, 7)
            XCTAssertEqual(job.offsetY, 3)
            XCTAssertEqual(g.board.tiles.count, 7)
            XCTAssertFalse(g.board.tiles.contains { $0.isHinted || $0.isFading })
        }
    }

    // MARK: click gating

    func testClickGuardAndIdleFlash() {
        XCTAssertTrue(AkiGame.isRepeatClick(now: 100, lastTick: 95, doubleClickTicks: 30))
        XCTAssertFalse(AkiGame.isRepeatClick(now: 111, lastTick: 95, doubleClickTicks: 30))
        XCTAssertTrue(AkiGame.isRepeatClick(now: 3, lastTick: UInt32.max - 5, doubleClickTicks: 30))   // 0xFFFFFFFA + 15 wraps to 9
        XCTAssertFalse(AkiGame.isRepeatClick(now: UInt32.max, lastTick: UInt32.max, doubleClickTicks: 30))
        XCTAssertTrue(AkiGame.movedEnough(h: 2, v: 2, lastH: 0, lastV: 0))
        XCTAssertFalse(AkiGame.movedEnough(h: 2, v: 0, lastH: 0, lastV: 0))
        XCTAssertFalse(AkiGame.movedEnough(h: 0, v: 2, lastH: 0, lastV: 0))
        var g = game([tile(0, 0, 0, face: 200)])
        g.idleHintFlash = true
        XCTAssertTrue(g.noteClick(now: 500))
        XCTAssertEqual(g.lastClickTick, 500)
        XCTAssertFalse(g.idleHintFlash)
        XCTAssertFalse(g.noteClick(now: 501))
        XCTAssertEqual(g.lastClickTick, 501)
    }
}
