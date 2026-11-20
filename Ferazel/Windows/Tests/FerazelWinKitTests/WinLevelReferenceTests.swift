@testable import FerazelCore
@testable import FerazelRender
@testable import FerazelWinKit
import Foundation
import XCTest

/// 6A-L10L11 (docs/superpowers/plans/2026-11-04-ferazel-remainder.md, "Verification-model additions for 6A": the level
/// first-frame golden's Windows reference): `WinGame` headless on the scripted host — `--mute --frames`,
/// `-FerazelLevel N`, N held from wake 1,440 (the smoke's `newgame_keys`), the baked fonts, the pinned seed and clock
/// (`WinReferenceFramesTests.framesRun`'s shape) — the flow step and presented-RGBA FNV of the first presented **level**
/// frame (after the chapter card where `-FerazelLevel N` shows one). Neither level's own first frame shows its feature
/// (level 10's horizon strip: none in 6,000 ticks from the header's start, 6A-S8; level 11's ripple: the view never
/// reaches the river band, D53.1), so each test then holds the level to the first frame that does — the player put at
/// the feature golden's start (`FeatureGoldenTests`' (600, 1150) / (16299, 600)), measured — and pins it, so the shell
/// path draws both features.
@MainActor final class WinLevelReferenceTests: XCTestCase {

    /// A headless game started with `-FerazelLevel level`, N held from wake 1,440.
    static func game(level: Int) throws -> (WinGame, WinScriptedHost) {
        let args = try WinArgs.parse(["--mute", "--frames", "100000", "-FerazelLevel", String(level)], environment: [:])
        let host = WinScriptedHost(script: try WinKeyScript(text: WinReferenceFramesTests.newGameKeys))
        let text = try BakedTextTests.baked()
        let (prefsURL, savesFolder) = WinFiles.locations(args, folder: nil)
        let game = WinGame(args: args, host: host, text: text,
                           files: WinFiles(prefsURL: prefsURL, savesFolder: savesFolder),
                           dialogs: DialogSystem(text: text))
        game.step()                                           // the pre-boot poll (system events only)
        try game.boot(dataDirectory: FerazelData.dataDirectory())
        return (game, host)
    }

    /// The pictures a wake's output and level segments drew.
    static func pictures(_ game: WinGame) -> [Int16] {
        let ops = game.lastOutput.draws + game.flow.segments.flatMap { seg -> [DrawOp] in
            switch seg {
            case .screen(let d), .level(let d): return d
            case .map: return []
            }
        }
        return ops.compactMap {
            switch $0 {
            case .drawPicture(let id, _, _, _): return id
            case .copyPicture(let id, _, _, _, _, _): return id
            default: return nil
            }
        }
    }

    /// Wakes until the first presented level frame (`iterations` 1, the tick's output presented): the wakes, the flow
    /// steps, the presented RGBA, and the pictures drawn before it while the level ran (the chapter card's among them).
    static func firstLevelFrame(_ game: WinGame, _ host: WinScriptedHost, level: Int) throws
        -> (wakes: Int, steps: Int, rgba: [UInt8], pictures: Set<Int16>) {
        var seen = Set<Int16>()
        for wake in 1...40_000 {
            game.step()
            host.advance()
            XCTAssertFalse(game.finished)
            if let run = game.flow.levelRun, run.levelNumber == level {
                if run.iterations == 0 { seen.formUnion(pictures(game)) }
                if run.iterations >= 1 {
                    XCTAssertEqual(run.iterations, 1)
                    XCTAssertTrue(game.lastOutput.present, "the first iteration's frame is presented")
                    return (wake, game.flowSteps, try XCTUnwrap(game.lastPresented), seen)
                }
            }
        }
        XCTFail("no level-\(level) frame in 40,000 wakes")
        return (0, 0, [], seen)
    }

    /// The pixels of a presented RGBA frame whose colour is not black.
    static func lit(_ rgba: [UInt8]) -> Int {
        stride(from: 0, to: rgba.count, by: 4).filter { rgba[$0] | rgba[$0 + 1] | rgba[$0 + 2] != 0 }.count
    }

    /// The player put at (x, y), still (`+0xc` / `+0xa`, the 24.8 pair, no speed).
    static func put(_ game: WinGame, x: Int, y: Int) throws {
        let s = try XCTUnwrap(game.flow.levelRun?.session)
        let pid = try XCTUnwrap(s.world.playerID)
        s.world.active.update(id: pid) { p in
            p.x = x; p.y = y; p.x256 = Int32(x) << 8; p.y256 = Int32(y) << 8; p.vx = 0; p.vy = 0
        }
    }

    /// One wake of each game; true when `game` presented a new flow step's frame.
    static func wake(_ game: WinGame, _ host: WinScriptedHost, last: inout Int) -> Bool {
        game.step()
        host.advance()
        guard game.flowSteps != last else { return false }
        last = game.flowSteps
        return game.lastOutput.present
    }

    func testLevel10FirstFrameReference() throws {
        let (game, host) = try Self.game(level: 10)
        let f = try Self.firstLevelFrame(game, host, level: 10)
        // `-FerazelLevel 10` shows chapter card 2 (PICT 4620, `.ChapterScreen` M l. 5038–5089) before the level.
        XCTAssertTrue(f.pictures.contains(4620), "chapter card 2 shown: \(f.pictures.sorted())")
        // Measured at 6A-L10L11: the first presented level frame at flow step 879 (wake 3,513) — the first iteration,
        // under `.GameLoop`'s `GammaFadeInAsync(0x28)` (M l. 5228): the presented RGBA is the fade's start, every pixel
        // black, so this FNV is level 11's too; the held frame below is the one that shows the level.
        XCTAssertEqual(Self.lit(f.rgba), 0)
        XCTAssertEqual([f.wakes, f.steps], [3513, 879])
        XCTAssertEqual(String(WinGame.fnv1a64(f.rgba), radix: 16), "742a0703fa4da325", "level 10's first presented frame")
        // The hold: the same game twice, the twin's strip sprites removed (`.pxSprite`, 6A-S8's nine); both players put
        // at the strip golden's start (600, 1150) after the first frame. The first presented frame where the two differ
        // is the first that shows a strip pixel (the shell path drew mode 8).
        let (twin, twinHost) = try Self.game(level: 10)
        let g = try Self.firstLevelFrame(twin, twinHost, level: 10)
        XCTAssertEqual(g.steps, f.steps)
        XCTAssertEqual(g.rgba, f.rgba)
        let ts = try XCTUnwrap(twin.flow.levelRun?.session)
        let strip = ts.world.active.sprites.filter { $0.handler == .pxSprite }.map(\.id)
        XCTAssertEqual(strip.count, 9)
        for id in strip { _ = ts.world.active.remove(id: id) }
        try Self.put(game, x: 600, y: 1150)
        try Self.put(twin, x: 600, y: 1150)
        var last = game.flowSteps, twinLast = twin.flowSteps
        for _ in 1...24_000 {
            let presented = Self.wake(game, host, last: &last)
            XCTAssertEqual(Self.wake(twin, twinHost, last: &twinLast), presented)
            guard presented else { continue }
            let a = try XCTUnwrap(game.lastPresented), b = try XCTUnwrap(twin.lastPresented)
            guard a != b else { continue }
            let s = try XCTUnwrap(game.flow.levelRun?.session)
            // Measured: flow step 885, the fourth iteration (still fading in), the camera at (0, 756); 254,502 pixels lit,
            // 329 RGBA bytes the strip changed.
            XCTAssertEqual([Self.lit(a), zip(a, b).filter { $0 != $1 }.count], [254_502, 329])
            XCTAssertEqual([game.flowSteps, game.flow.levelRun?.iterations ?? -1], [885, 4])
            XCTAssertEqual([s.camera.scrollH, s.camera.scrollV], [0, 756])
            XCTAssertEqual(String(WinGame.fnv1a64(a), radix: 16), "e8f72bddcaf3b7a1", "level 10's first strip frame")
            return
        }
        XCTFail("no strip pixel in 24,000 wakes")
    }

    func testLevel11FirstFrameReference() throws {
        let (game, host) = try Self.game(level: 11)
        let f = try Self.firstLevelFrame(game, host, level: 11)
        // No chapter card on level 11 (hdr 0x273c = 0).
        XCTAssertFalse(f.pictures.contains { (4610...4699).contains($0) }, "no chapter card: \(f.pictures.sorted())")
        // Measured at 6A-L10L11: flow step 609 (wake 2,433), the first iteration under the fade-in — all black.
        XCTAssertEqual(Self.lit(f.rgba), 0)
        XCTAssertEqual([f.wakes, f.steps], [2433, 609])
        XCTAssertEqual(String(WinGame.fnv1a64(f.rgba), radix: 16), "742a0703fa4da325", "level 11's first presented frame")
        // The hold: the player put at the ripple golden's start (16299, 600); the first presented frame whose view
        // reaches the river band — a backdrop row ≥ 512 (yb 256: rows track the view, v + 383 ≥ 0x200) — with the ripple
        // table filled there (6A-RP's rows 0x200 / 0x280).
        try Self.put(game, x: 16299, y: 600)
        var last = game.flowSteps
        for _ in 1...24_000 {
            guard Self.wake(game, host, last: &last) else { continue }
            let s = try XCTUnwrap(game.flow.levelRun?.session)
            guard s.camera.scrollV + 383 >= 0x200 else { continue }
            let r = try XCTUnwrap(game.driver.levelRenderer)
            let rgba = try XCTUnwrap(game.lastPresented)
            // Measured: flow step 615, the fourth iteration (still fading in), the camera at (15744, 158) — rows 512…541
            // in view; the table −288 / −3302; 254,169 pixels lit.
            XCTAssertEqual(Self.lit(rgba), 254_169)
            XCTAssertEqual([game.flowSteps, game.flow.levelRun?.iterations ?? -1], [615, 4])
            XCTAssertEqual([s.camera.scrollH, s.camera.scrollV], [15744, 158])
            XCTAssertEqual([r.parallax.rippleTable[0x200], r.parallax.rippleTable[0x280]], [-288, -3302])
            XCTAssertEqual(String(WinGame.fnv1a64(rgba), radix: 16), "ba061897f247a79f", "level 11's first ripple frame")
            return
        }
        XCTFail("no ripple row in 24,000 wakes")
    }
}
