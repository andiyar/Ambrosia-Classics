import XCTest
import HectorResources
@testable import DeimosCore

/// Phase 4 S4 HS — name entry `FUN_10021bd0(player, slot, prefs, fromGame)` (grounding B §2c; dump
/// `ghidra/deimos/Deimos_pef.decompiled.c` FUN_10021bd0; front-end.md §4.3). Ticks are the screen's clock (it counts
/// `TickCount`, not frames). Expectations are read from the dump and the data (the MSL ctype table at `0x100f0f94`,
/// PermFloats 79 / 82 / 83, pgsl 7, gaso 0 / 2 / 4 / 9 / 15), never from the screen's own output.
final class NameEntryTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    private static let returnKey = KeyEvent(charCode: 0x0d, keyCode: 0x24)
    private static let enterKey = KeyEvent(charCode: 0x03, keyCode: 0x4c)
    private static let backspace = KeyEvent(charCode: 0x08, keyCode: 0x33)
    private static let esc = KeyEvent(charCode: 0x1b, keyCode: 0x35)

    private func keys(_ s: String, autoRepeat: Bool = false) -> [KeyEvent] {
        s.utf8.map { KeyEvent(charCode: $0, keyCode: 0, autoRepeat: autoRepeat) }
    }

    /// The name element of table row `slot` (list item 4 + 4·slot, `FUN_10000cf0` 0-based).
    private func nameText(_ e: NameEntry, slot: Int) -> String {
        MacRoman.decode(e.list.elements[4 + 4 * slot].record.text)
    }

    /// One pass; returns the step.
    private func step(_ e: inout NameEntry, _ s: inout FrontEndState, ticks: UInt32,
                      keys: HeldKeys = HeldKeys()) -> ScreenStep<DeimosPrefs> {
        e.pass(keys: keys, ticks: ticks, returned: nil, state: &s)
    }

    private func finished(_ st: ScreenStep<DeimosPrefs>) -> DeimosPrefs? {
        if case let .finish(p) = st.next { return p }
        return nil
    }

    /// Types `typed` (after first deleting the pre-filled name when `clear`), confirms with Return, then waits out
    /// the 25 ticks (bound 100 passes, G11). Returns the prefs name entry hands back, and the live prefs after.
    private func enter(_ typed: [KeyEvent], player: Int = 0, slot: Int = 3, clear: Bool = true,
                       prefs: DeimosPrefs = .fresh) throws -> (DeimosPrefs, FrontEndState, [SoundCue]) {
        var s = try FrontEndState(assets: assets(), prefs: prefs)
        var e = NameEntry(player: player, slot: slot, prefs: prefs)
        var t: UInt32 = 1_000
        var sounds: [SoundCue] = []
        sounds += step(&e, &s, ticks: t).output.sounds
        t += 1
        var events = clear ? Array(repeating: Self.backspace, count: 20) : []
        events += typed + [Self.returnKey]
        sounds += step(&e, &s, ticks: t, keys: HeldKeys(keyEvents: events)).output.sounds
        for _ in 0..<100 {
            t += 1
            let st = step(&e, &s, ticks: t)
            sounds += st.output.sounds
            if let p = finished(st) { return (p, s, sounds) }
        }
        XCTFail("bound: name entry did not finish within 100 passes")
        throw XCTSkip("unfinished")
    }

    /// The eggs are tested on an uppercase copy (substring, `strstr`), in the order BIKI, DILVISH, SUPERCOBRA,
    /// PYTHOS, FISJ, the last match winning; an empty name becomes "Jar Jar Must Die"; any other name is kept as
    /// typed, case and all. The result goes into the row and the player's remembered name, and on exit into the live
    /// prefs (`FUN_100047f0`). "Leonard Cohen Rules J00" is 23 characters: the original's `strcpy` runs past the
    /// 21-byte row field into the next row's ("00") and, for player 1, past the remembered name into player 2's.
    func testNameEntryEggs() throws {
        let cases: [(String, String)] = [
            ("biki", "Filthy Communist"), ("xDilvishx", "Just Ship It, Baby"), ("SuperCobra", "Munkis Rool J00"),
            ("fisj", "Daikajinn!!"), ("BIKIFISJ", "Daikajinn!!"), ("DILVISHBIKI", "Just Ship It, Baby"),
            ("AcE", "AcE"), ("b i k i", "b i k i"), ("", "Jar Jar Must Die"),
        ]
        for (typed, want) in cases {
            let (p, s, sounds) = try enter(keys(typed), player: 1, slot: 3)
            XCTAssertEqual(p.highScoreNames[3], want, "typed \"\(typed)\"")
            XCTAssertEqual(p.playerNames[1], want, "the remembered name, typed \"\(typed)\"")
            XCTAssertEqual(p.playerNames[0], "Player 1", "the other player's name is untouched")
            XCTAssertEqual(s.prefs, p, "on exit the edited prefs are the live prefs (FUN_100047f0)")
            XCTAssertEqual(p.highScoreNames[4], DeimosPrefs.fresh.highScoreNames[4])
            let confirm = SoundPlay.perm(s.assets.sounds[4], priority: 0x32, volume: 100, allowMultiple: true)
            XCTAssertEqual(sounds.last, confirm, "gaso 4 on Return, and nothing after it")
        }
        // PYTHOS, player 1 in row 3: 23 characters spill "00" into row 4 and into player 2's remembered name.
        let (p, s, _) = try enter(keys("pythos"), player: 0, slot: 3)
        XCTAssertEqual(p.highScoreNames[3], "Leonard Cohen Rules J00")
        XCTAssertEqual(p.highScoreNames[4], "00", "the row below gets the overflow")
        XCTAssertEqual(p.playerNames[0], "Leonard Cohen Rules J00")
        XCTAssertEqual(p.playerNames[1], "00", "player 2's remembered name gets the overflow")
        XCTAssertEqual(s.prefs, p)
        // Player 2's overflow lands in the three pad bytes before the scores: only the row below changes.
        let (q, _, _) = try enter(keys("Pythos"), player: 1, slot: 0)
        XCTAssertEqual(q.highScoreNames[0], "Leonard Cohen Rules J00")
        XCTAssertEqual(q.highScoreNames[1], "00")
        XCTAssertEqual(q.playerNames, ["Player 1", "Leonard Cohen Rules J00"])
        XCTAssertEqual(q.highScores, DeimosPrefs.fresh.highScores)
        // Return 0x0d and 0x0a confirm; Enter (0x03) does not.
        var st = try FrontEndState(assets: assets(), prefs: .fresh)
        var e = NameEntry(player: 0, slot: 2, prefs: .fresh)
        _ = step(&e, &st, ticks: 10)
        let ignored = step(&e, &st, ticks: 11, keys: HeldKeys(keyEvents: [Self.enterKey, Self.esc]))
        XCTAssertTrue(e.editing, "Enter and Esc do nothing")
        XCTAssertEqual(e.buffer, Array("Player 1".utf8), "nothing appended")
        XCTAssertEqual(ignored.output.sounds, [], "silently")
        XCTAssertEqual(ignored.output.ops, [], "no redraw")
        _ = step(&e, &st, ticks: 12, keys: HeldKeys(keyEvents: [KeyEvent(charCode: 0x0a, keyCode: 0)]))
        XCTAssertFalse(e.editing, "0x0a confirms")
        XCTAssertEqual(e.edited.highScoreNames[2], "Player 1", "the pre-filled remembered name, kept as it was")

        // Both players (player2Slot): player 2's entry follows inside the screen, and the events queued behind the
        // key that ends player 1's entry (the "x" after Return) are player 2's.
        var st2 = try FrontEndState(assets: assets(), prefs: .fresh)
        var both = NameEntry(player: 0, slot: 1, prefs: .fresh)
        both.player2Slot = 4
        _ = step(&both, &st2, ticks: 10)
        let queue = keys("A") + [Self.returnKey] + keys("x") + Array(repeating: Self.backspace, count: 8) + keys("Zed")
            + [Self.returnKey]
        let mid = step(&both, &st2, ticks: 11, keys: HeldKeys(keyEvents: queue))
        XCTAssertNil(finished(mid), "player 2 is still on screen")
        XCTAssertEqual(st2.prefs.highScoreNames[1], "Player 1A", "player 1's entry left: live prefs ← A")
        XCTAssertFalse(both.editing, "player 2 pressed Return too")
        XCTAssertEqual(both.buffer, Array("Zed".utf8))
        let exitAt = try XCTUnwrap(mid.output.ops.firstIndex(of: .copy(from: .terrain, to: .back, src: nil, dst: nil,
                                                                         interlaced: false)))
        XCTAssertEqual(mid.output.ops[exitAt + 2], .fill(.back, colour: 0), "player 1 leaves, player 2's screen opens")
        let final = try XCTUnwrap(finished(step(&both, &st2, ticks: 37)))
        XCTAssertEqual(final.highScoreNames[1], "Player 1A")
        XCTAssertEqual(final.highScoreNames[4], "Zed")
        XCTAssertEqual(final.playerNames, ["Player 1A", "Zed"])
        XCTAssertEqual(st2.prefs, final)
    }

    /// The edit buffer is pre-filled with the remembered name ("Player 1": 8 characters). A character whose MSL
    /// ctype has a bit of 0xdc (table `0x100f0f94`: every byte 0x20–0x7E and 0x80–0xFE; not 0x00–0x1F, 0x7F, 0xFF) is
    /// appended while the name is under 20 (gaso 0 `clic`), else refused with gaso 15 `shwa`; Backspace deletes with
    /// gaso 2 (none when empty). keyDown and autoKey both count (`0 < code < 4`), so a held key repeats into the name.
    func testNameEntryTwentyCharsAndRepeat() throws {
        let a = try assets()
        func cue(_ i: Int) -> SoundCue { SoundPlay.perm(a.sounds[i], priority: 0x32, volume: 100, allowMultiple: true) }
        var s = try FrontEndState(assets: a, prefs: .fresh)
        var e = NameEntry(player: 0, slot: 5, prefs: .fresh)
        let first = step(&e, &s, ticks: 100)
        XCTAssertEqual(first.output.sounds, [cue(9)], "gaso 9 HighScoreAchieved (none) at the start")
        XCTAssertEqual(nameText(e, slot: 5), "Player 1", "the row shows the remembered name")
        XCTAssertEqual(e.buffer, Array("Player 1".utf8))
        // A remembered name longer than 20 is cut to 20 in the buffer (FUN_10046510(buf, row, 0x14)).
        var long = DeimosPrefs.fresh
        long.playerNames[0] = "ABCDEFGHIJKLMNOPQRSTUVWXY"
        var cut = NameEntry(player: 0, slot: 2, prefs: long)
        _ = step(&cut, &s, ticks: 100)
        XCTAssertEqual(cut.buffer, Array("ABCDEFGHIJKLMNOPQRST".utf8))
        // Twelve more (four of them auto-repeat) reach 20; the 21st is refused.
        var st = step(&e, &s, ticks: 101, keys: HeldKeys(keyEvents: keys("abcdefgh") + keys("xxxx", autoRepeat: true)))
        XCTAssertEqual(e.buffer, Array("Player 1abcdefghxxxx".utf8))
        XCTAssertEqual(st.output.sounds, Array(repeating: cue(0), count: 12))
        st = step(&e, &s, ticks: 102, keys: HeldKeys(keyEvents: keys("z") + keys("y", autoRepeat: true)))
        XCTAssertEqual(e.buffer.count, 20, "20 is the cap (10022110 cmplwi r3,0x14)")
        XCTAssertEqual(st.output.sounds, [cue(15), cue(15)], "gaso 15 shwa for each refused character")
        XCTAssertEqual(nameText(e, slot: 5), "Player 1abcdefghxxxx", "the row shows the buffer, no cursor at 20")
        // Backspace, then the ctype edges.
        st = step(&e, &s, ticks: 103, keys: HeldKeys(keyEvents: [Self.backspace, Self.backspace]))
        XCTAssertEqual(e.buffer, Array("Player 1abcdefghxx".utf8))
        XCTAssertEqual(st.output.sounds, [cue(2), cue(2)])
        let edges: [UInt8] = [0x1f, 0x7f, 0xff, 0x09, 0x20, 0x7e]
        st = step(&e, &s, ticks: 104, keys: HeldKeys(keyEvents: edges.map { KeyEvent(charCode: $0, keyCode: 0) }))
        XCTAssertEqual(e.buffer, Array("Player 1abcdefghxx".utf8) + [0x20, 0x7e], "0x1f 0x7f 0xff Tab refused silently")
        XCTAssertEqual(st.output.sounds, [cue(0), cue(0)])
        st = step(&e, &s, ticks: 105, keys: HeldKeys(keyEvents: [Self.backspace, KeyEvent(charCode: 0x80, keyCode: 0)]))
        XCTAssertEqual(e.buffer.last, 0x80, "Mac Roman 0x80 (Ä, ctype 0x80) is a letter")
        // Clicks are ignored while editing.
        _ = step(&e, &s, ticks: 106, keys: HeldKeys(mouseDowns: [MousePoint(h: 5, v: 5)]))
        XCTAssertTrue(e.editing)
        // Emptying the buffer: Backspace on empty plays nothing.
        st = step(&e, &s, ticks: 107, keys: HeldKeys(keyEvents: Array(repeating: Self.backspace, count: 21)))
        XCTAssertEqual(e.buffer, [])
        XCTAssertEqual(st.output.sounds, Array(repeating: cue(2), count: 20))
        // Confirm; the screen leaves 25 ticks later (F79, fromGame), not before; nothing leaves before Return.
        XCTAssertEqual(EntityDraw.fctiwz(a.floats[79]), 25)
        st = step(&e, &s, ticks: 200, keys: HeldKeys(keyEvents: keys("Q") + [Self.returnKey]))
        XCTAssertNil(finished(st))
        XCTAssertNil(finished(step(&e, &s, ticks: 225)), "200 + 25 is not past")
        let done = step(&e, &s, ticks: 226)
        XCTAssertEqual(finished(done)?.highScoreNames[5], "Q")
        XCTAssertEqual(done.output.ops, [.copy(from: .terrain, to: .back, src: nil, dst: nil, interlaced: false),
                                         .present(.fullScreen)], "restore +0x6c → +0x68, present")
        // After Return any key or click leaves at once; not from the menu (fromGame false) the wait is F78 = 600.
        var e2 = NameEntry(player: 1, slot: 0, prefs: .fresh, fromGame: false)
        _ = step(&e2, &s, ticks: 10)
        _ = step(&e2, &s, ticks: 11, keys: HeldKeys(keyEvents: [Self.returnKey]))
        XCTAssertNil(finished(step(&e2, &s, ticks: 611)))
        XCTAssertNotNil(finished(step(&e2, &s, ticks: 612)))
        var e3 = NameEntry(player: 1, slot: 0, prefs: .fresh)
        _ = step(&e3, &s, ticks: 10)
        _ = step(&e3, &s, ticks: 11, keys: HeldKeys(keyEvents: [Self.returnKey]))
        XCTAssertNotNil(finished(step(&e3, &s, ticks: 12, keys: HeldKeys(mouseDowns: [MousePoint(h: 1, v: 1)]))))
    }

    /// The cursor `_` (pgsl 7) shows only when more than F82 = 30 ticks have passed since the last accepted key AND
    /// more than F83 = 10 since the last flip; each flip redraws. A key that edits the name hides it (and redraws).
    /// While shown and the name is under 20, the row reads name + "_". Passes come every tick here.
    func testNameEntryCursorBlink() throws {
        let a = try assets()
        XCTAssertEqual(EntityDraw.fctiwz(a.floats[82]), 30)
        XCTAssertEqual(EntityDraw.fctiwz(a.floats[83]), 10)
        XCTAssertEqual(a.gameString(7), "_")
        var s = try FrontEndState(assets: a, prefs: .fresh)
        var e = NameEntry(player: 0, slot: 0, prefs: .fresh)
        let t0: UInt32 = 5_000
        _ = step(&e, &s, ticks: t0)
        var flips: [UInt32] = []
        var shownAt: [UInt32: Bool] = [:]
        for t in (t0 + 1)...(t0 + 64) {
            let st = step(&e, &s, ticks: t)
            if !st.output.ops.isEmpty { flips.append(t) }
            shownAt[t] = nameText(e, slot: 0).hasSuffix("_")
            if t == t0 + 31 { XCTAssertEqual(nameText(e, slot: 0), "Player 1_") }
        }
        XCTAssertEqual(flips, [t0 + 31, t0 + 42, t0 + 53, t0 + 64], "strictly past 30, then strictly past 10 apart")
        XCTAssertEqual(shownAt[t0 + 30], false)
        XCTAssertEqual(shownAt[t0 + 31], true)
        XCTAssertEqual(shownAt[t0 + 41], true)
        XCTAssertEqual(shownAt[t0 + 42], false)
        XCTAssertEqual(shownAt[t0 + 53], true)
        XCTAssertEqual(shownAt[t0 + 64], false)
        // A redraw: the `back` image into the back buffer, the list drawn restoring and presenting each element,
        // then a full present.
        let redraw = step(&e, &s, ticks: t0 + 75)
        XCTAssertEqual(redraw.output.ops.first, .loadImage(image: FourCC("back")!, into: .back,
                                                           dst: MacRect(top: 0, left: 0, bottom: 480, right: 640)))
        XCTAssertEqual(redraw.output.ops.last, .present(.fullScreen))
        XCTAssertTrue(nameText(e, slot: 0).hasSuffix("_"))
        // A typed key hides the cursor at once; it comes back only once 30 ticks have passed since that key.
        let tk = t0 + 80
        _ = step(&e, &s, ticks: tk, keys: HeldKeys(keyEvents: keys("!")))
        XCTAssertEqual(nameText(e, slot: 0), "Player 1!")
        var back: UInt32?
        for t in (tk + 1)...(tk + 40) {
            // An Esc on the way does not restart the 30 ticks (dump: only an edit sets the key clock).
            _ = step(&e, &s, ticks: t, keys: t == tk + 15 ? HeldKeys(keyEvents: [Self.esc]) : HeldKeys())
            if back == nil, nameText(e, slot: 0).hasSuffix("_") { back = t }
        }
        XCTAssertEqual(back, tk + 31)
        // A refused key (Esc) neither hides it nor restarts the 30 ticks (dump: only edits set the key clock).
        // (The loop above stepped every tick to tk + 40; the cursor shows from tk + 31 until the flip at tk + 42.)
        let te = tk + 40
        let before = nameText(e, slot: 0)
        _ = step(&e, &s, ticks: te, keys: HeldKeys(keyEvents: [Self.esc]))
        XCTAssertEqual(nameText(e, slot: 0), before)
        XCTAssertTrue(before.hasSuffix("_"))
        // Backspace, arriving while the cursor shows (tk + 41: no flip is due), hides it at once and restarts the key
        // clock: back only 31 ticks after it.
        let tb = te + 1
        XCTAssertTrue(nameText(e, slot: 0).hasSuffix("_"), "showing when Backspace arrives")
        _ = step(&e, &s, ticks: tb, keys: HeldKeys(keyEvents: [Self.backspace]))
        XCTAssertEqual(nameText(e, slot: 0), "Player 1")
        var again: UInt32?
        for t in (tb + 1)...(tb + 40) {
            _ = step(&e, &s, ticks: t)
            if again == nil, nameText(e, slot: 0).hasSuffix("_") { again = t }
        }
        XCTAssertEqual(again, tb + 31)
        // At 20 characters the cursor is never appended.
        var full = NameEntry(player: 0, slot: 0, prefs: .fresh)
        _ = step(&full, &s, ticks: 0)
        _ = step(&full, &s, ticks: 1, keys: HeldKeys(keyEvents: keys("123456789012")))
        for t in UInt32(2)...UInt32(60) { _ = step(&full, &s, ticks: t) }
        XCTAssertEqual(nameText(full, slot: 0), "Player 1123456789012")
    }
}
