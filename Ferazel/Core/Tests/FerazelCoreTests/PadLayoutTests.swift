import XCTest
import HectorInput
import HectorResources
@testable import FerazelCore

/// GP (docs/plans/2026-10-14-ferazel-phase3.md, D37): a game controller as the original keys — `FerazelPadLayout`'s
/// bindings per `GameFlow.padContext`, the context across a scripted flow, and the 1 s hold before − is Esc.
final class PadLayoutTests: XCTestCase {

    private func binding(_ m: ShellPadMapping, _ b: ShellPadButton) -> ShellPadBinding? { m.bindings[b] }

    func testPlayLayoutFollowsPrefsKeys() {
        // The defaults (keypad 4 6 8 5, Shift, Option, ⌘, keypad 7 9): move, run, jump, use, previous / next item.
        let d = FerazelPadLayout.mapping(keys: FerazelPrefs.defaultKeys, context: .playing, dialogUp: false)
        var play: [ShellPadButton: ShellPadBinding] = [:]
        (play[.left], play[.right], play[.up], play[.down]) = (.key(0x56), .key(0x58), .key(0x5b), .key(0x57))
        (play[.south], play[.east], play[.west], play[.north]) = (.key(0x3a), .key(0x3a), .key(0x38), .key(0x37))
        (play[.leftShoulder], play[.rightShoulder]) = (.key(0x59), .key(0x5c))
        (play[.leftTrigger], play[.rightTrigger]) = (.key(0x38), .key(0x38))
        (play[.start], play[.back]) = (.capsLockToggle, .keyAfterHold(0x35, seconds: 1.0))
        XCTAssertEqual(d.bindings, play)
        // A remapped set (Options): every button follows; a code no `GetKeys` bit can hold binds nothing.
        let keys: [Int16] = [0x00, 0x02, 0x0d, 0x01, 0x31, 0x26, 0x28, 0x0c, 0x0e]
        let m = FerazelPadLayout.mapping(keys: keys, context: .playing, dialogUp: false)
        XCTAssertEqual(binding(m, .left), .key(0x00))
        XCTAssertEqual(binding(m, .right), .key(0x02))
        XCTAssertEqual(binding(m, .up), .key(0x0d))
        XCTAssertEqual(binding(m, .down), .key(0x01))
        XCTAssertEqual(binding(m, .west), .key(0x31))
        XCTAssertEqual(binding(m, .leftTrigger), .key(0x31))
        XCTAssertEqual(binding(m, .south), .key(0x26))
        XCTAssertEqual(binding(m, .east), .key(0x26))
        XCTAssertEqual(binding(m, .north), .key(0x28))
        XCTAssertEqual(binding(m, .leftShoulder), .key(0x0c))
        XCTAssertEqual(binding(m, .rightShoulder), .key(0x0e))
        var odd = keys
        odd[5] = 0x80
        odd[6] = -1
        let o = FerazelPadLayout.mapping(keys: odd, context: .playing, dialogUp: false)
        XCTAssertNil(binding(o, .south))
        XCTAssertNil(binding(o, .east))
        XCTAssertNil(binding(o, .north))
        XCTAssertEqual(binding(o, .west), .key(0x31))
    }

    func testOutOfPlayLayouts() {
        let keys = FerazelPrefs.defaultKeys
        // Paused: only + (the Caps Lock latch), with or without a dialog's arrows / Return / Esc.
        XCTAssertEqual(FerazelPadLayout.mapping(keys: keys, context: .paused, dialogUp: false).bindings,
                       [.start: .capsLockToggle])
        // The main menu: south, east and + are N (New Game); nothing else (the menu acts on letters).
        XCTAssertEqual(FerazelPadLayout.mapping(keys: keys, context: .mainMenu, dialogUp: false).bindings,
                       [.south: .key(0x2d), .east: .key(0x2d), .start: .key(0x2d)])
        // Everything else: the fixed arrows, Return on every face and +, Esc at once.
        let other: [ShellPadButton: ShellPadBinding] = [
            .left: .key(0x7b), .right: .key(0x7c), .down: .key(0x7d), .up: .key(0x7e),
            .south: .key(0x24), .east: .key(0x24), .west: .key(0x24), .north: .key(0x24),
            .start: .key(0x24), .back: .key(0x35),
        ]
        XCTAssertEqual(FerazelPadLayout.mapping(keys: keys, context: .other, dialogUp: false).bindings, other)
        XCTAssertEqual(FerazelPadLayout.mapping(keys: keys, context: .mainMenu, dialogUp: true).bindings, other)
        // A conversation's menu moves on the up / down INPUT keys (C1: inputs 2 / 3), so its d-pad is the move keys.
        var talk = other
        (talk[.left], talk[.right], talk[.up], talk[.down]) = (.key(0x56), .key(0x58), .key(0x5b), .key(0x57))
        XCTAssertEqual(FerazelPadLayout.mapping(keys: keys, context: .conversation, dialogUp: false).bindings, talk)
        // A dialog over a level (a confirm, a report, the pause's Abort Game): arrows / Return / Esc, + stays the latch
        // (the pause survives the dialog).
        var inGame = other
        inGame[.start] = .capsLockToggle
        XCTAssertEqual(FerazelPadLayout.mapping(keys: keys, context: .playing, dialogUp: true).bindings, inGame)
        XCTAssertEqual(FerazelPadLayout.mapping(keys: keys, context: .paused, dialogUp: true).bindings, inGame)
    }

    // MARK: The flow

    private final class Files: FrontFiles {
        func loadPrefs() -> Data? { nil }
        func storePrefs(_ record: Data) throws {}
        func readSavedGame(_ ref: SavedGameRef) throws -> SaveBlock { throw SavedGameError.notASavedGame }
        func writeSavedGame(_ block: SaveBlock, to ref: SavedGameRef) throws(SaveWriteError) {}
    }

    private final class Levels: LevelServices {
        func prepare(level: Int) throws -> LevelFaces { LevelFaces() }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {}
        func deathEffectStep(_ k: Int) throws {}
    }

    func testPadContextAcrossFlow() throws {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let flow = GameFlow(resources: r, prefs: FerazelPrefs(), seed: 1, files: Files(), levels: Levels())
        var t: UInt32 = 1000
        var seen: [GameFlow.PadContext] = []
        func drive(max: Int = 6000, _ input: @escaping (GameFlow) -> FrontInput = { _ in FrontInput() },
                   until: (GameFlow) -> Bool, file: StaticString = #filePath, line: UInt = #line) {
            for _ in 0..<max {
                if case .loading = flow.state { flow.loadFinished() }
                _ = flow.tick(now: t, input: input(flow))
                t &+= 1
                if seen.last != flow.padContext { seen.append(flow.padContext) }
                if until(flow) { return }
            }
            XCTFail("not reached in \(max) ticks (state \(flow.state))", file: file, line: line)
        }
        func playing(_ f: GameFlow, level n: Int) -> Bool {
            guard let run = f.levelRun, run.levelNumber == n else { return false }
            return run.iterations >= 45
        }

        XCTAssertEqual(flow.padContext, .other, "the boot")
        drive { $0.state == .mainMenu }
        XCTAssertEqual(flow.padContext, .mainMenu)
        drive(max: 1, { _ in FrontInput(keys: KeyState(pressed: [MainMenu.newGameKey])) }) { _ in true }   // N
        drive { playing($0, level: 1) }
        XCTAssertEqual(flow.padContext, .playing)
        XCTAssertEqual(seen, [.other, .mainMenu, .other, .playing], "the popup, load bars and chapter card are not play")
        drive({ _ in FrontInput(capsLock: true) }) { $0.levelRun?.pause != nil }
        XCTAssertEqual(flow.padContext, .paused)
        drive { $0.levelRun?.pause == nil }
        XCTAssertEqual(flow.padContext, .playing)
        try touchExit(try XCTUnwrap(flow.levelRun?.session), record: 66)
        drive { f in f.worldMap.map { $0.iterations >= 2 && $0.walkStep == 0 && $0.result == nil } ?? false }
        XCTAssertEqual(flow.padContext, .other, "the map")
        drive({ _ in FrontInput(capsLock: true) }) { $0.worldMap?.pause != nil }
        XCTAssertEqual(flow.padContext, .paused, "the map's pause loop")
        drive { $0.worldMap?.pause == nil }
        flow.savedThisGame = true                       // a save this game (level 2's run takes it): death asks
        drive({ _ in FrontInput(keys: KeyState(pressed: [0x24])) }) { $0.worldMap == nil }
        drive { playing($0, level: 2) }
        XCTAssertEqual(flow.padContext, .playing)
        // Death with a save this game → the death screen (Return / Esc).
        let s = try XCTUnwrap(flow.levelRun?.session)
        s.world.active.update(id: try XCTUnwrap(s.world.playerID)) { $0.hp = 0 }
        s.world.globals.health = 0
        s.world.player.gameOver = true
        drive { $0.deathScreen != nil }
        XCTAssertEqual(flow.padContext, .other, "the death screen")
        XCTAssertNil(flow.levelRun)
    }

    // MARK: − held

    func testHoldToEscape() {
        let m = FerazelPadLayout.mapping(keys: FerazelPrefs.defaultKeys, context: .playing, dialogUp: false)
        var tr = ShellPadTranslator()
        _ = tr.update(.empty, mapping: m, now: 0)
        let back = ShellPadState(buttons: [.back])
        // A tap: down 0.9 s, released — never Esc.
        for now in [0.1, 0.5, 0.99] { XCTAssertFalse(tr.update(back, mapping: m, now: now).held.contains(0x35)) }
        XCTAssertEqual(tr.update(.empty, mapping: m, now: 1.0).released, [])
        // Held: nothing before 1 s, Esc down at 1 s and held on, up on release.
        XCTAssertEqual(tr.update(back, mapping: m, now: 2.0).held, [])
        XCTAssertEqual(tr.update(back, mapping: m, now: 2.5).pressed, [])
        let at = tr.update(back, mapping: m, now: 3.0)
        XCTAssertEqual(at.pressed, [0x35])
        XCTAssertEqual(at.held, [0x35])
        XCTAssertEqual(tr.update(back, mapping: m, now: 4.0).held, [0x35])
        XCTAssertEqual(tr.update(.empty, mapping: m, now: 4.1).released, [0x35])
        // Out of play − is Esc at once.
        let other = FerazelPadLayout.mapping(keys: FerazelPrefs.defaultKeys, context: .other, dialogUp: false)
        XCTAssertEqual(tr.update(back, mapping: other, now: 5.0).pressed, [0x35])
    }
}
