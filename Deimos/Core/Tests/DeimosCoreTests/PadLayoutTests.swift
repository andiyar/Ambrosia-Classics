import XCTest
import HectorInput
@testable import DeimosCore

/// Phase 4 S7 GP (grounding C §4, ruling 17, question 5's defaults): a game controller as the original's keys —
/// `DeimosPadLayout`'s bindings per context, P1's live key set in play and at the level select, the + latch, the 1 s
/// hold before − is Esc in play, and a button held across a change of context.
final class PadLayoutTests: XCTestCase {

    private let esc: UInt16 = 0x35
    private let ret: UInt16 = 0x24

    /// Updates `tr` with `buttons` at each of `times`, returning the frames; fails if `times` exceeds `bound`.
    private func run(_ tr: inout ShellPadTranslator, _ buttons: Set<ShellPadButton>, _ m: ShellPadMapping,
                     at times: [Double], bound: Int = 16, file: StaticString = #filePath,
                     line: UInt = #line) -> [ShellPadFrame] {
        var frames: [ShellPadFrame] = []
        for (i, t) in times.enumerated() {
            if i >= bound { XCTFail("more than \(bound) updates", file: file, line: line); break }
            frames.append(tr.update(ShellPadState(buttons: buttons), mapping: m, now: t))
        }
        return frames
    }

    func testPlayLayoutFollowsKeySet() {
        // Fresh prefs, P1 ↑ ← → ↓ ⌘ ⌥ Space: d-pad = slots 0–3; south = fire air (slot 4), west = fire ground (5),
        // north and east = select (6); + = the Caps Lock latch; − = Esc after 1 s. P2's set binds nothing.
        let fresh = KeyTable(prefs: .fresh)
        let play: [ShellPadButton: ShellPadBinding] = [
            .up: .key(0x7E), .left: .key(0x7B), .right: .key(0x7C), .down: .key(0x7D),
            .south: .key(0x37), .west: .key(0x3A), .north: .key(0x31), .east: .key(0x31),
            .start: .capsLockToggle, .back: .keyAfterHold(esc, seconds: 1.0),
        ]
        XCTAssertEqual(DeimosPadLayout.mapping(keySet: fresh, context: .playing).bindings, play)
        // A remapped P1 set (the controls window): every button follows; P2's codes never reach the pad.
        var codes = fresh.codes
        codes.replaceSubrange(0..<7, with: [0x0d, 0x00, 0x02, 0x01, 0x26, 0x28, 0x25])
        codes[7] = 0x22
        let m = DeimosPadLayout.mapping(keySet: KeyTable(codes: codes), context: .playing)
        XCTAssertEqual([m.bindings[.up], m.bindings[.left], m.bindings[.right], m.bindings[.down]],
                       [.key(0x0d), .key(0x00), .key(0x02), .key(0x01)])
        XCTAssertEqual([m.bindings[.south], m.bindings[.west], m.bindings[.north], m.bindings[.east]],
                       [.key(0x26), .key(0x28), .key(0x25), .key(0x25)])
        XCTAssertFalse(m.bindings.values.contains(.key(0x22)), "P2's set")
        // A code no `GetKeys` bit can hold (> 0x7F), or a short table, binds nothing.
        var odd = codes
        odd[4] = 0x80
        let o = DeimosPadLayout.mapping(keySet: KeyTable(codes: odd), context: .playing)
        XCTAssertNil(o.bindings[.south])
        XCTAssertEqual(o.bindings[.west], .key(0x28))
        let short = DeimosPadLayout.mapping(keySet: KeyTable(codes: [0x0d, 0x00]), context: .playing)
        XCTAssertEqual(short.bindings[.left], .key(0x00))
        XCTAssertNil(short.bindings[.right])
        XCTAssertNil(short.bindings[.south])
        // The level select reads P1's set too: left / right = slots 1 / 2, any face = its slot (4–6 all accept),
        // − = Esc at once; nothing else.
        let select: [ShellPadButton: ShellPadBinding] = [
            .left: .key(0x7B), .right: .key(0x7C),
            .south: .key(0x37), .west: .key(0x3A), .north: .key(0x31), .east: .key(0x31),
            .back: .key(esc),
        ]
        XCTAssertEqual(DeimosPadLayout.mapping(keySet: fresh, context: .levelSelect).bindings, select)
        let ls = DeimosPadLayout.mapping(keySet: KeyTable(codes: codes), context: .levelSelect)
        XCTAssertEqual([ls.bindings[.left], ls.bindings[.right], ls.bindings[.south]],
                       [.key(0x00), .key(0x02), .key(0x26)], "the live set")
    }

    func testOutOfPlayArrowsReturnEsc() {
        let fresh = KeyTable(prefs: .fresh)
        // The main menu and name entry / scores / credits / dialogs: the fixed arrows, Return on every face and +,
        // Esc at once — whatever the key set.
        let other: [ShellPadButton: ShellPadBinding] = [
            .up: .key(0x7E), .left: .key(0x7B), .right: .key(0x7C), .down: .key(0x7D),
            .south: .key(ret), .east: .key(ret), .west: .key(ret), .north: .key(ret),
            .start: .key(ret), .back: .key(esc),
        ]
        let remapped = KeyTable(codes: [0x0d, 0x00, 0x02, 0x01, 0x26, 0x28, 0x25] + fresh.codes.suffix(7))
        for context in [DeimosPadLayout.Context.mainMenu, .screens] {
            XCTAssertEqual(DeimosPadLayout.mapping(keySet: fresh, context: context).bindings, other, "\(context)")
            XCTAssertEqual(DeimosPadLayout.mapping(keySet: remapped, context: context).bindings, other, "\(context)")
        }
        // A demo film: no key ends a film (D45 ruling 1) but − is Esc at once (ruling 17); nothing else.
        XCTAssertEqual(DeimosPadLayout.mapping(keySet: fresh, context: .demo).bindings, [.back: .key(esc)])
        // Paused: only + (the latch); shoulders, triggers and thumbs are never bound.
        XCTAssertEqual(DeimosPadLayout.mapping(keySet: fresh, context: .paused).bindings, [.start: .capsLockToggle])
        let unmapped: [ShellPadButton] = [.leftShoulder, .rightShoulder, .leftTrigger, .rightTrigger, .leftThumb,
                                          .rightThumb]
        for context in DeimosPadLayout.Context.allCases {
            let b = DeimosPadLayout.mapping(keySet: fresh, context: context).bindings
            for button in unmapped { XCTAssertNil(b[button], "\(button) in \(context)") }
        }
    }

    func testPlusIsCapsLockLatch() {
        let keys = KeyTable(prefs: .fresh)
        let play = DeimosPadLayout.mapping(keySet: keys, context: .playing)
        let paused = DeimosPadLayout.mapping(keySet: keys, context: .paused)
        var tr = ShellPadTranslator()
        _ = run(&tr, [], play, at: [0])
        // + down: the latch is on (pause is the Caps Lock state); held or released it stays on — no key is held.
        let down = run(&tr, [.start], play, at: [0.1, 0.5])
        XCTAssertEqual(down.map(\.capsLock), [true, true])
        XCTAssertEqual(down.map(\.held), [[], []])
        // Paused (the layout the shell polls with while the lock is on): released, the latch holds; a second press
        // turns it off — back in play.
        XCTAssertEqual(run(&tr, [], paused, at: [0.6, 0.7]).map(\.capsLock), [true, true])
        XCTAssertEqual(run(&tr, [.start], paused, at: [0.8]).map(\.capsLock), [false])
        XCTAssertEqual(run(&tr, [], play, at: [0.9]).map(\.capsLock), [false])
        // On again in play; leaving play for a context with no latch clears it, and + there is Return / nothing.
        XCTAssertEqual(run(&tr, [.start], play, at: [1.0]).map(\.capsLock), [true])
        XCTAssertEqual(run(&tr, [], play, at: [1.1]).map(\.capsLock), [true])
        let menu = DeimosPadLayout.mapping(keySet: keys, context: .mainMenu)
        XCTAssertEqual(run(&tr, [], menu, at: [1.2]).map(\.capsLock), [false])
        let plus = run(&tr, [.start], menu, at: [1.3])[0]
        XCTAssertEqual(plus.capsLock, false)
        XCTAssertEqual(plus.pressed, [ret])
        _ = run(&tr, [], menu, at: [1.4])
        let ls = DeimosPadLayout.mapping(keySet: keys, context: .levelSelect)
        let atSelect = run(&tr, [.start], ls, at: [1.5])[0]
        XCTAssertEqual([atSelect.capsLock, atSelect.held.isEmpty], [false, true])
    }

    func testMinusHoldInPlayAtOnceElsewhere() {
        let keys = KeyTable(prefs: .fresh)
        let play = DeimosPadLayout.mapping(keySet: keys, context: .playing)
        var tr = ShellPadTranslator()
        _ = run(&tr, [], play, at: [0])
        // A tap in play: down 0.99 s, released — never Esc.
        XCTAssertEqual(run(&tr, [.back], play, at: [0.1, 0.5, 1.09]).map(\.held), [[], [], []])
        XCTAssertEqual(run(&tr, [], play, at: [1.1]).map(\.released), [[]])
        // Held: nothing before 1 s, Esc down at 1 s and held on, up on release.
        let held = run(&tr, [.back], play, at: [2.0, 2.5, 2.999, 3.0, 4.0])
        XCTAssertEqual(held.map(\.held), [[], [], [], [esc], [esc]])
        XCTAssertEqual(held.map(\.pressed), [[], [], [], [esc], []])
        XCTAssertEqual(run(&tr, [], play, at: [4.1]).map(\.released), [[esc]])
        // Everywhere else − is Esc on its first update: it ends a demo and leaves the level select (ruling 17).
        for context in [DeimosPadLayout.Context.levelSelect, .demo, .mainMenu, .screens] {
            let m = DeimosPadLayout.mapping(keySet: keys, context: context)
            var t = ShellPadTranslator()
            _ = run(&t, [], m, at: [0])
            let f = run(&t, [.back], m, at: [0.01])[0]
            XCTAssertEqual([f.pressed, f.held.sorted()], [[esc], [esc]], "\(context)")
            XCTAssertEqual(run(&t, [], m, at: [0.02])[0].released, [esc], "\(context)")
        }
        // Paused: − is nothing.
        let paused = DeimosPadLayout.mapping(keySet: keys, context: .paused)
        var p = ShellPadTranslator()
        _ = run(&p, [], paused, at: [0])
        XCTAssertEqual(run(&p, [.back], paused, at: [0.5, 2.0]).map(\.held), [[], []])
    }

    func testHeldButtonAcrossContextChangeDoesNotFire() {
        // The kit's translator (HectorKit D16) ignores a button already down when its binding changes, until it is
        // released; these pin that through the Deimos contexts.
        let keys = KeyTable(prefs: .fresh)
        func layout(_ c: DeimosPadLayout.Context) -> ShellPadMapping { DeimosPadLayout.mapping(keySet: keys, context: c) }
        // The main menu's Return (south) still down as play begins: no fire air until it is released and pressed.
        var tr = ShellPadTranslator()
        _ = run(&tr, [], layout(.mainMenu), at: [0])
        XCTAssertEqual(run(&tr, [.south], layout(.mainMenu), at: [0.1])[0].pressed, [ret])
        let into = run(&tr, [.south], layout(.playing), at: [0.2, 0.3, 2.0])
        XCTAssertEqual(into.map(\.held), [[], [], []])
        XCTAssertEqual(into.map(\.released), [[ret], [], []])
        _ = run(&tr, [], layout(.playing), at: [2.1])
        XCTAssertEqual(run(&tr, [.south], layout(.playing), at: [2.2])[0].pressed, [0x37], "a fresh press fires")
        // A direction held through the pause does not move the ship when the pause ends.
        _ = run(&tr, [], layout(.playing), at: [2.3])
        XCTAssertEqual(run(&tr, [.left], layout(.paused), at: [2.4])[0].held, [])
        XCTAssertEqual(run(&tr, [.left], layout(.playing), at: [2.5, 2.6]).map(\.held), [[], []])
        // − held 1 s ends the game (Esc); still down on the next screens it does not Esc them too.
        _ = run(&tr, [], layout(.playing), at: [2.9])
        XCTAssertEqual(run(&tr, [.back], layout(.playing), at: [3.0, 4.0]).map(\.pressed), [[], [esc]])
        let after = run(&tr, [.back], layout(.screens), at: [4.2, 4.3])
        XCTAssertEqual(after.map(\.held), [[], []])
        XCTAssertEqual(after.map(\.released), [[esc], []])
        // A face held through a demo's end: no Return on the main menu.
        var d = ShellPadTranslator()
        _ = run(&d, [], layout(.demo), at: [0])
        XCTAssertEqual(run(&d, [.south], layout(.demo), at: [0.1])[0].held, [])
        XCTAssertEqual(run(&d, [.south], layout(.mainMenu), at: [0.2, 0.3]).map(\.held), [[], []])
    }
}
