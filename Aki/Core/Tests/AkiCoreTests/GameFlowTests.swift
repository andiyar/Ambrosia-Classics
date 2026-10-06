import XCTest
@testable import AkiCore

/// P2.6 — `_ShowNextCGHint` @ 0x12622, `_ReshuffleCustomTiles` @ 0x133ff, `_UndoLastCGMove` @ 0x128cb,
/// `_PauseGame` @ 0xd34b, `_SelectCGButton` @ 0x1356f, `_HandleMenuCommand` @ 0xd465 (cases 3, 6),
/// `_CustomGameScreen` @ 0x12dbc (game tick), `_RedrawCustomTimeBar` @ 0xefa0 and `_RedrawNoMorePairs` @ 0x10854
/// (docs/aki/rules.md §9–§13).
final class GameFlowTests: XCTestCase {

    // MARK: helpers

    private func tile(_ x: Int, _ y: Int, _ z: Int, face: Int) -> Tile {
        var t = Tile(x: x, y: y, z: z)
        t.face = face
        return t
    }

    /// A synthetic board (no offsets) with visibility, openness and g+0x60 computed.
    private func game(_ tiles: [Tile], difficultyRaw: Int16 = 1, levelIndex: Int = 0) -> AkiGame {
        var board = Board(layout: Layout(functionName: "_Synthetic", placements: [], offsetX: 0, offsetY: 0,
                                         background: 0))
        board.tiles = tiles
        board.setVisibleTiles()
        board.setOpenTiles()
        var g = AkiGame(board: board, difficultyRaw: difficultyRaw, levelIndex: levelIndex)
        g.countOpenPairs()
        return g
    }

    /// Four open tiles in a row, faces as given (x 0, 4, 8, 12 half-units: never adjacent, all open).
    private func row(_ faces: [Int], difficultyRaw: Int16 = 1, levelIndex: Int = 0) -> AkiGame {
        game(faces.enumerated().map { tile(4 * $0.offset, 0, 0, face: $0.element) },
             difficultyRaw: difficultyRaw, levelIndex: levelIndex)
    }

    /// Layout 1 (level 0) dealt with SplitMix64(7).
    private func dealt(difficultyRaw: Int16) -> AkiGame {
        var g = AkiGame(layout: Layouts.forLevel(0), difficultyRaw: difficultyRaw, levelIndex: 0)
        var rng = SplitMix64(seed: 7)
        g.dealFresh(using: &rng)
        return g
    }

    /// The "no more pairs" state the reshuffle tests start from: g+0x60 = 0, bc 80, b8 70, c0 1000, a8 100.
    private func frozenNoPairs() -> AkiGame {
        var g = dealt(difficultyRaw: 0)
        g.openPairs = 0
        g.clock.baseTick = 100
        g.clock.frozenRemaining = 80
        g.clock.remaining = 70
        g.clock.freezeTick = 1000
        return g
    }

    private func faces(_ g: AkiGame) -> [Int] { g.board.tiles.map(\.face).sorted() }

    // MARK: hint (rules §9)

    func testHintFlagsFirstPairInListOrderAndCharges() {
        var g = row([201, 202, 201, 202])
        XCTAssertEqual(g.clock.remaining, 150)
        let events = g.showNextHint()
        XCTAssertEqual(events, [.redrawGameScreen(tiles: true)])
        XCTAssertEqual(g.board.tiles.map(\.isHinted), [true, false, true, false])
        XCTAssertEqual(g.clock.penalty, 37)   // Medium: 150 / 4
    }

    func testHintAgainRepeatsFromAfterTheFirstHintedTileWithoutWrap() {
        // F = tile 0, its partner (tile 1) is later: the scan from F.next finds 1 ↔ 0 again.
        var g = row([201, 201, 202, 202])
        XCTAssertEqual(g.showNextHint(), [.redrawGameScreen(tiles: true)])
        XCTAssertEqual(g.board.tiles.map(\.isHinted), [true, true, false, false])
        XCTAssertEqual(g.showNextHint(), [.redrawTile(0), .redrawTile(1), .redrawGameScreen(tiles: true)])
        XCTAssertEqual(g.board.tiles.map(\.isHinted), [true, true, false, false])
        XCTAssertEqual(g.clock.penalty, 74)

        // Hint flags past every open pair: the scan runs off the list end, no wrap back to 0 ↔ 1.
        var h = row([201, 201, 203, 204])
        h.board.tiles[2].isHinted = true
        h.board.tiles[3].isHinted = true
        XCTAssertEqual(h.showNextHint(), [.redrawTile(2), .redrawTile(3)])
        XCTAssertEqual(h.board.tiles.map(\.isHinted), [false, false, false, false])
        XCTAssertEqual(h.clock.penalty, 37)

        // Pins the scan start at F.next, not F: faces 201, 202, 201, 202 — the first hint flags 0 ↔ 2 (F = 0);
        // the second must scan from tile 1 and flag 1 ↔ 3 (a scan from F would re-find 0 ↔ 2).
        var k = row([201, 202, 201, 202])
        XCTAssertEqual(k.showNextHint(), [.redrawGameScreen(tiles: true)])
        XCTAssertEqual(k.board.tiles.map(\.isHinted), [true, false, true, false])
        XCTAssertEqual(k.showNextHint(), [.redrawTile(0), .redrawTile(2), .redrawGameScreen(tiles: true)])
        XCTAssertEqual(k.board.tiles.map(\.isHinted), [false, true, false, true])
        XCTAssertFalse(k.board.tiles[0].isHinted || k.board.tiles[2].isHinted)
    }

    func testHintWithoutAnyPairStillCharges() {
        var g = row([201, 202, 203, 204], difficultyRaw: 0)
        XCTAssertEqual(g.showNextHint(), [])
        XCTAssertFalse(g.board.tiles.contains { $0.isHinted })
        XCTAssertEqual(g.clock.penalty, 75)   // Hard: 150 / 2
    }

    // MARK: reshuffle (rules §11)

    func testReshuffleButtonRestoresFrozenRemaining() {
        var g = frozenNoPairs()
        let before = faces(g)
        var rng = SplitMix64(seed: 11)
        let events = g.buttonClick(h: 70, paused: false, now: 1600, using: &rng)
        // No .pressButton(4): _SelectCGButton draws the pressed button only when g+0x60 ≠ 0 (DC:7753).
        XCTAssertEqual(events, [.setNoPairsFlash(false), .flashButton(3, glow: false), .startMusic,
                                .redrawGameScreen(tiles: true)])
        XCTAssertEqual(g.clock.baseTick, 700)
        XCTAssertEqual(g.clock.freezeTick, 0)
        XCTAssertEqual(g.clock.remaining, 80)
        XCTAssertEqual(g.clock.penalty, 60)   // Hard: 3 · 80 / 4
        XCTAssertGreaterThan(g.openPairs, 0)
        XCTAssertEqual(g.openPairs, g.board.countOpenPairs())
        XCTAssertEqual(faces(g), before)

        // g+0x60 == 0 but c0 == 0: the button's thaw is guarded on c0 ≠ 0 — a8 and the live b8 stay.
        var n = frozenNoPairs()
        n.clock.freezeTick = 0
        var rng2 = SplitMix64(seed: 11)
        _ = n.buttonClick(h: 70, paused: false, now: 1600, using: &rng2)
        XCTAssertEqual(n.clock.baseTick, 100)
        XCTAssertEqual(n.clock.freezeTick, 0)
        XCTAssertEqual(n.clock.remaining, 70)
    }

    func testReshuffleMenuUsesTheLiveRemaining() {
        var g = frozenNoPairs()
        var rng = SplitMix64(seed: 11)
        let events = g.reshuffle(fromButton: false, now: 1600, using: &rng)
        XCTAssertEqual(events, [.setNoPairsFlash(false), .flashButton(3, glow: false), .startMusic,
                                .redrawGameScreen(tiles: true)])
        XCTAssertFalse(events.contains { if case .pressButton = $0 { true } else { false } })
        XCTAssertEqual(g.clock.baseTick, 700)
        XCTAssertEqual(g.clock.freezeTick, 0)
        XCTAssertEqual(g.clock.remaining, 70)
        XCTAssertEqual(g.clock.penalty, 52)   // Hard: 3 · 70 / 4

        // g+0x60 ≠ 0 with c0 ≠ 0: the menu's thaw is guarded on g+0x60 == 0 — a8 and c0 stay.
        var m = frozenNoPairs()
        m.openPairs = 1
        var rng2 = SplitMix64(seed: 11)
        _ = m.reshuffle(fromButton: false, now: 1600, using: &rng2)
        XCTAssertEqual(m.clock.baseTick, 100)
        XCTAssertEqual(m.clock.freezeTick, 1000)
        XCTAssertEqual(m.clock.remaining, 70)
    }

    func testReshuffleClearsSelectionHintsAndRemoved() {
        var g = dealt(difficultyRaw: 1)
        let t = g.board.tiles
        guard let (a, b) = t.indices.lazy.compactMap({ i in
            t.indices.first { $0 != i && t[i].isOpen && t[$0].isOpen && Board.matches(t[i].face, t[$0].face) }
                .map { (i, $0) }
        }).first else { return XCTFail("no open pair") }
        g.board.tiles[a].isRemoved = true
        g.board.tiles[b].isRemoved = true
        let c = t.indices.first { $0 != a && $0 != b }!
        g.board.tiles[c].isSelected = true
        g.selected = c
        let d = t.indices.last { $0 != a && $0 != b && $0 != c }!
        g.board.tiles[d].isHinted = true
        var survivors = t.map(\.face)
        survivors.remove(at: max(a, b))
        survivors.remove(at: min(a, b))
        g.clock.remaining = 12
        XCTAssertGreaterThan(g.openPairs, 0)
        var rng = SplitMix64(seed: 3)
        let events = g.reshuffle(fromButton: true, now: 0, using: &rng)
        XCTAssertEqual(events, [.setNoPairsFlash(false), .flashButton(3, glow: false), .redrawGameScreen(tiles: true),
                                .playSound(.tick, volume: 128)])
        XCTAssertEqual(g.board.tiles.count, 142)
        XCTAssertFalse(g.board.tiles.contains { $0.isRemoved || $0.isSelected || $0.isHinted })
        XCTAssertNil(g.selected)
        XCTAssertEqual(faces(g), survivors.sorted())
        XCTAssertEqual(g.clock.penalty, 6)    // Medium: 12 / 2
        XCTAssertEqual(g.openPairs, g.board.countOpenPairs())
    }

    // MARK: undo (rules §12)

    func testUndoOnlyInEasyAndPractice() {
        for (raw, penalty) in [(Int16(0), -1), (1, -1), (2, 12), (3, 0)] {
            var g = row([200, 200, 201, 201], difficultyRaw: raw)
            _ = g.selectTile(h: 10, v: 10, tileAnimation: false)
            _ = g.selectTile(h: 100, v: 10, tileAnimation: false)
            XCTAssertEqual(g.board.tiles.map(\.isRemoved), [true, true, false, false], "raw \(raw)")
            XCTAssertEqual(g.openPairs, 1)
            let events = g.undo(now: 0)
            if penalty < 0 {
                XCTAssertEqual(events, [], "raw \(raw)")
                XCTAssertEqual(g.board.tiles.map(\.isRemoved), [true, true, false, false])
                XCTAssertEqual(g.clock.penalty, 0)
                continue
            }
            XCTAssertEqual(events, [.undoRedraw(UndoJob(first: 0, second: 1, openPairsAtDraw: 1)),
                                    .redrawOpenPairs(flush: true)], "raw \(raw)")
            XCTAssertEqual(g.board.tiles.map(\.isRemoved), [false, false, false, false])
            XCTAssertFalse(g.board.tiles.contains { $0.isSelected })
            XCTAssertNil(g.selected)
            XCTAssertEqual(g.openPairs, 2)
            XCTAssertTrue(g.undoEnabled)
            XCTAssertEqual(g.clock.penalty, penalty, "raw \(raw)")
            XCTAssertEqual(g.undo(now: 0), [], "second undo, raw \(raw)")
            XCTAssertEqual(g.clock.penalty, penalty)
        }

        // Easy with b8 == 0 and a removed pair present: the b8 ≠ 0 guard (rules §12) — nothing happens.
        var z = row([200, 200, 201, 201], difficultyRaw: 2)
        _ = z.selectTile(h: 10, v: 10, tileAnimation: false)
        _ = z.selectTile(h: 100, v: 10, tileAnimation: false)
        XCTAssertEqual(z.board.tiles.map(\.isRemoved), [true, true, false, false])
        z.clock.remaining = 0
        let before = z
        XCTAssertEqual(z.undo(now: 0), [])
        XCTAssertEqual(z, before)
    }

    func testUndoInNoMorePairsThawsAndDrawsGrey() {
        // A/B match leaves S2 (on S1), T, U open with no pair: "no more pairs", not a stacked loss.
        var g = game([tile(0, 0, 0, face: 200), tile(4, 0, 0, face: 200), tile(20, 0, 0, face: 201),
                      tile(20, 0, 1, face: 201), tile(30, 0, 0, face: 202), tile(40, 0, 0, face: 203)],
                     difficultyRaw: 2)
        _ = g.selectTile(h: 10, v: 10, tileAnimation: false)
        let match = g.selectTile(h: 100, v: 10, tileAnimation: false)
        XCTAssertFalse(match.contains(.setLost))
        XCTAssertEqual(g.openPairs, 0)
        _ = g.enterNoMorePairs(now: 500)
        XCTAssertEqual(g.clock.freezeTick, 500)
        let events = g.undo(now: 800)
        XCTAssertEqual(events, [.undoRedraw(UndoJob(first: 0, second: 1, openPairsAtDraw: 0)),
                                .redrawOpenPairs(flush: true)])
        XCTAssertEqual(g.clock.baseTick, 300)
        XCTAssertEqual(g.clock.freezeTick, 0)
        XCTAssertEqual(g.openPairs, 1)
        XCTAssertEqual(g.clock.penalty, 12)
    }

    // MARK: pause (rules §13)

    func testPauseFreezesAndUnpauseThaws() {
        for remaining in [150, 10] {
            var g = row([200, 200, 201, 201])
            g.clock.remaining = remaining
            let low = remaining < 15
            let paused = g.pauseChange(paused: true, now: 100)
            XCTAssertEqual(g.clock.freezeTick, 100)
            XCTAssertEqual(paused, (low ? [.stopSound(.tick)] : []) + [.playMovie(128), .redrawGameScreen(tiles: false)])
            let resumed = g.pauseChange(paused: false, now: 160)
            XCTAssertEqual(g.clock.baseTick, 60)
            XCTAssertEqual(g.clock.freezeTick, 0)
            XCTAssertEqual(resumed, (low ? [.playSound(.tick, volume: 128)] : []) + [.playMovie(128),
                                                                                  .redrawGameScreen(tiles: true)])
        }
        var none = row([200, 201, 202, 203])
        XCTAssertEqual(none.openPairs, 0)
        XCTAssertEqual(none.pauseChange(paused: true, now: 100), [])
        XCTAssertEqual(none.clock.freezeTick, 0)
        XCTAssertEqual(none.pauseChange(paused: false, now: 160), [])
        XCTAssertEqual(none.clock.baseTick, 0)
    }

    // MARK: button bar (_SelectCGButton)

    func testButtonBarRanges() {
        func click(_ h: Int, paused: Bool = false, faces: [Int] = [200, 200, 201, 201]) -> [GameEvent] {
            var g = row(faces)
            var rng = SplitMix64(seed: 5)
            return g.buttonClick(h: h, paused: paused, now: 0, using: &rng)
        }
        let hint: [GameEvent] = [.pressButton(3), .redrawGameScreen(tiles: true)]
        let reshuffle: [GameEvent] = [.pressButton(4), .setNoPairsFlash(false), .flashButton(3, glow: false),
                                      .redrawGameScreen(tiles: true)]
        let pause: [GameEvent] = [.playSound(.chime, volume: 64), .pauseGame(true)]
        XCTAssertEqual([23, 24, 49, 50].map { click($0) }, [[], hint, hint, []])
        XCTAssertEqual([61, 62, 87, 88].map { click($0) }, [[], reshuffle, reshuffle, []])
        XCTAssertEqual([99, 100, 125, 126].map { click($0) }, [[], pause, pause, []])
        // Paused: the loop starts at k 5 — hint and reshuffle are ignored, pause still works.
        XCTAssertEqual(click(30, paused: true), [])
        XCTAssertEqual(click(70, paused: true), [])
        XCTAssertEqual(click(110, paused: true), [.playSound(.chime, volume: 64), .pauseGame(false)])
        // No open pairs: no pressed button, hint and pause inert.
        XCTAssertEqual(click(30, faces: [200, 201, 202, 203]), [])
        XCTAssertEqual(click(110, faces: [200, 201, 202, 203]), [])
    }

    // MARK: time bar (_RedrawCustomTimeBar)

    func testTimeBarStepLatchAndTimeOut() {
        var g = row([200, 200, 201, 201], levelIndex: 4)
        g.clock.remaining = 20
        let s1 = g.timeBarStep(now: 0, paused: false)
        XCTAssertEqual(s1, TimeBarStep(raw: 9000, length: 225, events: [.stopSound(.tick)]))
        XCTAssertTrue(g.tickLatch)
        g.clock.remaining = 15
        XCTAssertEqual(g.timeBarStep(now: 0, paused: false)?.events, [.playSound(.tick, volume: 128)])
        XCTAssertFalse(g.tickLatch)
        g.clock.remaining = 0
        XCTAssertEqual(g.timeBarStep(now: 0, paused: false)?.events,
                       [.stopMusic, .stopSound(.tick), .setLost, .recordLoss(4), .savePrefs, .setEndLevel])

        var c = row([200, 200, 201, 201], levelIndex: 13)
        c.clock.remaining = 0
        XCTAssertEqual(c.timeBarStep(now: 0, paused: false)?.events,
                       [.stopMusic, .stopSound(.tick), .setLost, .setCustomLost, .savePrefs, .setEndLevel])

        var none = row([200, 201, 202, 203])
        none.openPairs = 3
        none.clock.remaining = 0
        XCTAssertNil(none.timeBarStep(now: 0, paused: false))
        XCTAssertEqual(none.openPairs, 0)

        var p = row([200, 200, 201, 201])
        p.clock.freezeTick = 600
        let step = p.timeBarStep(now: 6000, paused: true)
        XCTAssertEqual(step?.raw, 8400)       // 9000 − (600 − 0)
        XCTAssertEqual(step?.length, 210)     // 8400 · 450 / 18000
        XCTAssertEqual(step?.raw, p.clock.timeBarRaw(at: 600))
    }

    /// U3 (D11, pixels only): `timeBarView` draws what `timeBarStep` draws and writes nothing — not the Practice
    /// a8 reset, not the 300 s cap penalty, not g+0x60, not the tick latch.
    func testTimeBarViewMatchesStepWithoutWrites() {
        for (difficulty, remaining, paused) in [(Int16(1), 20, false), (1, 400, false), (3, 50, false),
                                                (3, 400, true), (2, 10, true)] {
            var g = row([200, 200, 201, 201], difficultyRaw: difficulty)
            g.clock.baseTick = 100
            g.clock.penalty = 7
            g.clock.bonus = 3
            g.clock.remaining = remaining
            g.clock.freezeTick = paused ? 900 : 0
            g.openPairs = 5                                    // stale g+0x60: the view must not store the recount
            let before = g
            let view = g.timeBarView(now: 1500, paused: paused)
            XCTAssertEqual(g, before)
            var stepped = g
            let step = stepped.timeBarStep(now: 1500, paused: paused)
            XCTAssertEqual(view?.raw, step?.raw)
            XCTAssertEqual(view?.length, step?.length)
        }
        XCTAssertNil(row([200, 201, 202, 203]).timeBarView(now: 0, paused: false))
    }

    /// U3: the switch's decode time is discounted from a running clock only; the idle-hint clock moves with it.
    func testDiscountTicks() {
        var running = row([200, 200, 201, 201])
        running.clock.baseTick = 1000
        running.lastClickTick = 1200
        running.discountTicks(90)
        XCTAssertEqual(running.clock.baseTick, 1090)
        XCTAssertEqual(running.lastClickTick, 1290)
        running.clock.update(now: 1090 + 600)
        XCTAssertEqual(running.clock.elapsed, 10)

        var frozen = row([200, 200, 201, 201])
        frozen.clock.baseTick = 1000
        frozen.clock.freezeTick = 1500
        frozen.discountTicks(90)
        XCTAssertEqual(frozen.clock.baseTick, 1000)
        XCTAssertEqual(frozen.clock.freezeTick, 1500)
    }

    // MARK: game tick (_CustomGameScreen)

    func testTickCadenceAndIdleHint() {
        XCTAssertFalse(AkiGame.gameTickDue(now: 101, last: 100))
        XCTAssertTrue(AkiGame.gameTickDue(now: 102, last: 100))
        XCTAssertFalse(AkiGame.flashDue(now: 105, last: 100))
        XCTAssertTrue(AkiGame.flashDue(now: 106, last: 100))
        var g = row([200, 200, 201, 201])
        XCTAssertEqual(g.lastClickTick, 0)
        g.tickClock(now: 1800)
        XCTAssertFalse(g.idleHintFlash)
        XCTAssertEqual(g.clock.elapsed, 30)
        XCTAssertEqual(g.clock.remaining, 120)
        g.tickClock(now: 1801)
        XCTAssertTrue(g.idleHintFlash)
    }

    // MARK: no more pairs (_RedrawNoMorePairs)

    func testEnterNoMorePairs() {
        var g = row([200, 201, 202, 203])
        g.clock.remaining = 12
        XCTAssertEqual(g.enterNoMorePairs(now: 900), [.stopSound(.tick), .setNoPairsFlash(true)])
        XCTAssertEqual(g.clock.frozenRemaining, 12)
        XCTAssertEqual(g.clock.freezeTick, 900)

        var h = row([200, 201, 202, 203])
        h.clock.remaining = 20
        h.clock.freezeTick = 300
        XCTAssertEqual(h.enterNoMorePairs(now: 900), [.setNoPairsFlash(true)])
        XCTAssertEqual(h.clock.frozenRemaining, 20)
        XCTAssertEqual(h.clock.freezeTick, 300)
    }
}
