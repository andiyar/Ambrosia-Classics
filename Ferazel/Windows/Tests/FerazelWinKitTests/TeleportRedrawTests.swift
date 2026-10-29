import FerazelCore
@testable import FerazelRender
@testable import FerazelWinKit
import Foundation
import XCTest

/// Q15 follow-up (Windows beta, 2026-10-29): after the level-1 teleporter (record 148 → 149) a rectangle of the view
/// stayed stale. The re-seat copies the scroll point into the grid's drawn location (`*_DAT_1009fe74/fe70`, M l.
/// 49453–49456) before `.RedrawEntireScrollGrid`, which redraws the window AT that location; the port's renderer kept
/// the location of the last strip redraw, so the whole-window redraws landed on the old view. Driven through the real
/// path: a saved game continued on the teleporter (`WinGame`'s SAVED-GAME argument → `GameFlow` → `LevelRun` → the
/// shared driver's `FrameRenderer`).
@MainActor final class TeleportRedrawTests: XCTestCase {

    /// A level-1 save-point save with the player at (x, y) and the level's records `records`.
    static func savedGame(x: Int, y: Int, records: [Placement], to url: URL) throws {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        var g = GameGlobals.initGameGlobals(previous: nil)
        var save = SaveBlock()
        save.savePointSave(level: 1, x: Int16(x), y: Int16(y), stamp: try WorldFile.load(from: r).stamp, date: 0,
                           globals: &g, records: records)
        try SavedGameFile.write(save, to: url)
    }

    /// The renderer's tile port against the window drawn fresh at the scroll point (h, v), over the pixels the view
    /// reads (608×384 from (h, v)): the number that differ. A copy of the live grid (same level, faces, lights) is
    /// moved to (h, v) on scratch ports, then `.RedrawEntireScrollGrid` draws the whole window there.
    static func staleTilePixels(_ r: FrameRenderer, h: Int, v: Int) -> Int {
        var grid = r.grid
        var scratch = FramePorts()
        grid.setScrollLocation(h: h, v: v, ports: &scratch)
        var fresh = FramePorts()
        grid.redrawEntireScrollGrid(h: h, v: v, ports: &fresh)
        var stale = 0
        for y in v..<(v + 384) {
            for x in h..<(h + 608) {
                let o = FramePorts.ringOffset(x: x, y: y)
                if fresh.tiles[o] != r.ports.tiles[o] { stale += 1 }
            }
        }
        return stale
    }

    func testTeleportArrivalRedrawsTheWholeView() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let L = try LevelFile.load(from: r, level: 1)
        let t = L.placements[148]
        XCTAssertEqual(t.type, 1062)
        // On the teleporter (TeleporterTests' start, 20 px left): it fires after ~1.5 s of standing.
        let url = dir.appendingPathComponent("teleporter.fzs")
        try Self.savedGame(x: Int(t.x) + 0x10 - 50 - 20, y: Int(t.y) - 4 - 85 + 1, records: L.placements, to: url)
        let (game, host) = try WinGameTests.game(arguments: [url.path])
        WinGameTests.run(game, host, max: 100_000) { $0.flow.levelRun?.session != nil }
        let s = try XCTUnwrap(game.flow.levelRun?.session)
        WinGameTests.run(game, host, max: 100_000) { _ in s.player.teleporterCharge >= 20 }
        let from = (s.camera.scrollH, s.camera.scrollV)
        // The arrival frame: the tail after the in-mosaic sets the charge −59.
        WinGameTests.run(game, host, max: 100_000) { _ in s.player.teleporterCharge < 0 }
        XCTAssertGreaterThan(abs(s.camera.scrollH - from.0) + abs(s.camera.scrollV - from.1), 640,
                             "a jump across the level")
        let renderer = try XCTUnwrap(game.driver.levelRenderer)
        // Measured without the fix: 220,460 of the view's 233,472 pixels differ (220,579 fifty frames on).
        XCTAssertEqual(Self.staleTilePixels(renderer, h: s.camera.scrollH, v: s.camera.scrollV), 0, "the arrival frame")
        let start = game.flowSteps
        for k in [1, 30, 50] {
            WinGameTests.run(game, host, max: 100_000) { $0.flowSteps >= start + k && $0.lastOutput.present }
            XCTAssertEqual(Self.staleTilePixels(renderer, h: s.camera.scrollH, v: s.camera.scrollV), 0, "arrival + \(k)")
        }
    }
}
