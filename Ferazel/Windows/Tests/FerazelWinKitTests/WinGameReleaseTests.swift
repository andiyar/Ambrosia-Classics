import FerazelCore
import FerazelRender
@testable import FerazelWinKit
import Foundation
import XCTest

/// A game the shell lets go of is freed (2026-11-10): the Windows-path visit sweep and the random-play bot build a
/// fresh headless `WinGame` per visit and simply drop it; before the fix `LevelRun → services → FerazelDriver → flow →
/// GameFlow → levelRun` (and `FerazelDriver.configuredRun → LevelRun`) kept every finished game alive, ~70 MB each,
/// until four sweep workers filled the Mac's memory (the panics of 2026-11-08 and 2026-11-10).
@MainActor final class WinGameReleaseTests: XCTestCase {

    func testADroppedGameInALevelIsFreed() throws {
        weak var game: WinGame?
        weak var driver: FerazelDriver?
        weak var flow: GameFlow?
        weak var run: LevelRun?
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ferazel-release-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        try autoreleasepool {
            // Built as the sweep builds each visit's game (`WinSweepGame`), then New Game (N held) into level 1.
            let sweep = try WinSweepGame(text: try BakedTextTests.baked(), folder: folder)
            try VisitSweep.toMainMenu(sweep)
            var ticks = 0
            while sweep.flow.levelRun == nil, ticks < 3000 {
                _ = try sweep.tick(keys: [0x2D])
                ticks += 1
            }
            for _ in 0..<30 { _ = try sweep.tick(keys: []) }   // the run configured, its renderer prepared
            let level = try XCTUnwrap(sweep.flow.levelRun, "level 1 is running")
            XCTAssertEqual(level.levelNumber, 1)
            XCTAssertNotNil(sweep.game.driver.levelRenderer, "LevelServices.prepare ran")
            XCTAssertFalse(sweep.game.finished)
            game = sweep.game
            driver = sweep.game.driver
            flow = sweep.flow
            run = level
        }
        XCTAssertNil(game, "the WinGame is freed")
        XCTAssertNil(driver, "its FerazelDriver is freed")
        XCTAssertNil(flow, "its GameFlow is freed")
        XCTAssertNil(run, "its LevelRun is freed")
    }
}
