import FerazelCore
@testable import FerazelWinKit
import Foundation
import XCTest

/// Phase 5 PB: the Windows smoke's three reference frames (`tools/windows/smoke-ferazel-win.sh` `menu_fnv`,
/// `newgame_fnv`, `text_fnv`) pinned in-process, so a task that moves them by night moves them honestly. Each run is
/// the executable's `--frames` path (`Sources/FerazelWin/main.swift`) on the scripted host: the same arguments as the
/// smoke (`--mute --frames N`, `--keys` for runs B and C), the baked fonts, the exe's in-picture dialogs, in-memory
/// prefs (headless), the pinned seed and clock (Phase W Ruling 20); one pre-boot wake without a tick, the boot, then N
/// wakes of one `step` + one 1/240 s each; the last presented frame's RGBA FNV.
@MainActor final class WinReferenceFramesTests: XCTestCase {
    /// The smoke's `newgame_keys` (N held from the first tick after the main menu).
    static let newGameKeys = "# N held from the first tick after the main menu (WinGameTests test 18)\n1440 down n\n"

    /// `main.swift`'s headless loop, in-process: the last presented frame's RGBA FNV (the exe's own `WinGame.fnv1a64`) and the flow steps made.
    static func framesRun(_ frames: Int, keys: String?) throws -> (fnv: UInt64, steps: Int) {
        let args = try WinArgs.parse(["--mute", "--frames", String(frames)], environment: [:])
        let host = WinScriptedHost(script: try WinKeyScript(text: keys ?? ""))
        let text = try BakedTextTests.baked()
        let (prefsURL, savesFolder) = WinFiles.locations(args, folder: nil)
        let game = WinGame(args: args, host: host, text: text,
                           files: WinFiles(prefsURL: prefsURL, savesFolder: savesFolder),
                           dialogs: DialogSystem(text: text))
        game.step()                                           // the pre-boot poll (system events only)
        XCTAssertFalse(game.finished)
        try game.boot(dataDirectory: FerazelData.dataDirectory())
        for _ in 0..<frames where !game.finished {
            game.step()
            host.advance()
        }
        XCTAssertFalse(game.finished, "a --frames run ends by its count")
        XCTAssertEqual(host.wallClockReads, 0, "the host's wall clock is never read headless")
        return (WinGame.fnv1a64(try XCTUnwrap(game.lastPresented)), game.flowSteps)
    }

    func testSmokeReferencesInProcess() throws {
        // Run A: the main menu, presented at flow step 360.
        let menu = try Self.framesRun(1437, keys: nil)
        XCTAssertEqual(menu.steps, 360)
        XCTAssertEqual(hex(menu.fnv), hex(0xae2b_1ee0_8c08_9b2a), "smoke menu_fnv")
        // Run B: N held from wake 1,440 → level 1's first frame at step 467.
        let newGame = try Self.framesRun(1865, keys: Self.newGameKeys)
        XCTAssertEqual(newGame.steps, 467)
        XCTAssertEqual(hex(newGame.fnv), hex(0xc99c_e8e8_5b4b_d8f7), "smoke newgame_fnv")
        // Run C: the same keys → the level's last full-gamma fade-in step, 959, with the status bar text.
        let text = try Self.framesRun(3833, keys: Self.newGameKeys)
        XCTAssertEqual(text.steps, 959)
        XCTAssertEqual(hex(text.fnv), hex(0xfbb2_dd7a_1d28_9726), "smoke text_fnv")
    }
}
