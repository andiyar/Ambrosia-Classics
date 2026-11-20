import XCTest
@testable import DeimosCore
import HectorResources

/// Phase 4 S7 CW — the controls window, DLOG/DITL 191 "Game - Controls", as the OS X build runs it (X `FUN_100435d0`
/// 100435d0..10043924; fill X `10043930`, name `10043b40`, assign `10043c00`, filter `10043f90`; grounding C §3, §3a,
/// §3b; `osx-build.md` D4, Item 2). The window is stepped pass by pass without a host, with the app fork read from the
/// repo. Clicks are one-pass clicks (the mouse-down and the release in the same pass). Every loop names its bound (G11).
final class ControlsDialogTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    /// STR# 130 "Game Keys": entry code + 1 names key `code`.
    private func keyNames() throws -> [[UInt8]] { try ResourceStringList.load(130, from: try DialogFork.loaded.get()) }

    private func name(_ code: Int, _ strings: [[UInt8]]) -> String {
        guard (0...0x7F).contains(code), code < strings.count, !strings[code].isEmpty else { return "??" }
        return MacRoman.decode(strings[code])
    }

    /// The fields, in focus order, and the slot each one stores into.
    private static let fields = [5, 7, 9, 11, 13, 15, 17]

    private struct Run {
        var dialog: ControlsDialog
        var state: FrontEndState
        var first: ScreenStep<Bool>
    }

    private func open(prefs: DeimosPrefs = .fresh) throws -> Run {
        var state = try FrontEndState(assets: try assets(), prefs: prefs, shellResources: try DialogFork.loaded.get())
        var d = ControlsDialog()
        let first = d.pass(keys: HeldKeys(), ticks: 100, returned: nil, state: &state)
        XCTAssertNil(first.finished, "the window stays open")
        return Run(dialog: d, state: state, first: first)
    }

    @discardableResult
    private func pass(_ r: inout Run, _ keys: HeldKeys = HeldKeys()) -> ScreenStep<Bool> {
        r.dialog.pass(keys: keys, ticks: 200, returned: nil, state: &r.state)
    }

    /// A key event (keyDown) with virtual key code `code`.
    @discardableResult
    private func key(_ r: inout Run, _ code: UInt16, char: UInt8 = 0x61) -> ScreenStep<Bool> {
        pass(&r, HeldKeys(keyEvents: [KeyEvent(charCode: char, keyCode: code)]))
    }

    private func centre(_ rect: MacRect) -> MousePoint {
        MousePoint(h: (rect.left + rect.right) / 2, v: (rect.top + rect.bottom) / 2)
    }

    @discardableResult
    private func click(_ r: inout Run, at p: MousePoint) -> ScreenStep<Bool> {
        pass(&r, HeldKeys(mouse: p, mouseButton: false, mouseDowns: [p]))
    }

    @discardableResult
    private func click(_ r: inout Run, item n: Int) -> ScreenStep<Bool> {
        guard let rect = r.dialog.runner.rect(n) else {
            XCTFail("the window has no item \(n)")
            return pass(&r)
        }
        return click(&r, at: centre(rect))
    }

    @discardableResult
    private func clickTab(_ r: inout Run, _ tab: Int) -> ScreenStep<Bool> {
        guard let rect = r.dialog.tabRect(tab) else {
            XCTFail("the tab control has no tab \(tab)")
            return pass(&r)
        }
        return click(&r, at: centre(rect))
    }

    /// The seven field texts.
    private func texts(_ r: Run) -> [String] { Self.fields.map { MacRoman.decode(r.dialog.runner.label($0)) } }

    // MARK: - Tests

    /// DLOG 191: t40 l16 b364 r319 (303 × 324), dBoxProc, items 191; DITL 191's seventeen items with the rects of
    /// grounding C §3; CNTL 191 (proc 128, value 6000) → tab# 6000 "Player 1", "Player 2". The window opens nested: no
    /// save-under, the pictures through the shell's route (ruling 9). No resources → false at once. KeyTable's slot
    /// meanings pinned to X 1004ce18..1004cf08 (grounding C §3b).
    func testDITL191Parse() throws {
        let fork = try DialogFork.loaded.get()
        let dlog = try DialogTemplate.load(191, from: fork)
        XCTAssertEqual(dlog.bounds, MacRect(top: 40, left: 16, bottom: 364, right: 319))
        XCTAssertEqual(dlog.procID, 1)
        XCTAssertEqual(dlog.itemsID, 191)
        let ditl = try DialogItemList.load(191, from: fork)
        XCTAssertEqual(ditl.items.count, 17)
        let expected: [(DialogItem.Kind, MacRect, Int16?)] = [
            (.button, MacRect(top: 291, left: 215, bottom: 311, right: 285), nil),
            (.button, MacRect(top: 291, left: 128, bottom: 311, right: 198), nil),
            (.control, MacRect(top: 20, left: 18, bottom: 276, right: 285), 191),
            (.picture, MacRect(top: 56, left: 151, bottom: 69, right: 164), 190),
            (.editText, MacRect(top: 75, left: 128, bottom: 89, right: 186), nil),
            (.picture, MacRect(top: 103, left: 46, bottom: 116, right: 59), 191),
            (.editText, MacRect(top: 102, left: 65, bottom: 116, right: 123), nil),
            (.picture, MacRect(top: 103, left: 255, bottom: 116, right: 268), 192),
            (.editText, MacRect(top: 102, left: 191, bottom: 116, right: 249), nil),
            (.picture, MacRect(top: 148, left: 151, bottom: 161, right: 164), 193),
            (.editText, MacRect(top: 128, left: 128, bottom: 142, right: 186), nil),
            (.picture, MacRect(top: 185, left: 69, bottom: 201, right: 184), 195),
            (.editText, MacRect(top: 186, left: 191, bottom: 200, right: 249), nil),
            (.picture, MacRect(top: 211, left: 69, bottom: 227, right: 184), 196),
            (.editText, MacRect(top: 212, left: 191, bottom: 226, right: 249), nil),
            (.picture, MacRect(top: 236, left: 69, bottom: 252, right: 184), 197),
            (.editText, MacRect(top: 237, left: 191, bottom: 251, right: 249), nil),
        ]
        for (i, e) in expected.enumerated() where i < ditl.items.count {
            XCTAssertEqual(ditl.items[i].kind, e.0, "item \(i + 1) kind")
            XCTAssertEqual(ditl.items[i].rect, e.1, "item \(i + 1) rect")
            if let id = e.2 { XCTAssertEqual(ditl.items[i].resourceID, id, "item \(i + 1) resource") }
        }
        XCTAssertEqual(MacRoman.decode(ditl.items[0].text), "Save")
        XCTAssertEqual(MacRoman.decode(ditl.items[1].text), "Cancel")
        let cntl = try ControlTemplate.load(191, from: fork)
        XCTAssertEqual(cntl.procID, 128)
        XCTAssertEqual(cntl.value, 6000)

        let r = try open()
        XCTAssertEqual(r.dialog.tabNames.map { MacRoman.decode($0) }, ["Player 1", "Player 2"])
        XCTAssertEqual(r.dialog.player, 0, "opens on Player 1")
        XCTAssertEqual(r.dialog.focus, 5)
        XCTAssertTrue(r.dialog.runner.screenFiltersKeys, "the filter takes every key")
        let window = r.dialog.runner.windowRect
        XCTAssertFalse(r.first.output.ops.contains(DialogDraw.saveUnder(window)), "nested: no save-under")
        XCTAssertFalse(r.first.output.ops.contains { if case .copy = $0 { true } else { false } }, "nothing saved")
        XCTAssertEqual(r.first.output.ops.last, .screenBlit(src: window, dst: window), "the window drawn")
        let pictures = r.first.output.ops.compactMap { op -> Int16? in
            if case let .drawPicture(id, into, _, _) = op, into == .back { return id }
            return nil
        }
        XCTAssertEqual(pictures, [190, 191, 192, 193, 195, 196, 197],
                       "the seven arrow / button pictures (no item names PICT 194), ruling 9")
        if let r4 = r.dialog.runner.rect(4) {
            XCTAssertTrue(r.first.output.ops.contains(.drawPicture(id: 190, into: .back, top: r4.top, left: r4.left)))
        }

        var bare = try FrontEndState(assets: try assets(), prefs: .fresh)
        var d = ControlsDialog()
        let s = d.pass(keys: HeldKeys(), ticks: 0, returned: nil, state: &bare)
        XCTAssertEqual(s.finished, false, "no resources: false at once")
        XCTAssertEqual(s.output.ops, [], "and nothing drawn")
        XCTAssertEqual(bare.prefs, .fresh)

        // KeyTable's slots (X FUN_1004cdf0, 1004ce18..1004cf08): up, left, right, down, fire air, fire ground, select.
        XCTAssertEqual(KeyTable.slotBits, [.up, .left, .right, .down, .fireAir, .fireGround, .select])
    }

    /// The name of a code is STR# 130 entry code + 1 (`10043b40`); outside 0…0x7F or an empty entry → "??". The open
    /// fills the fields with the P1 set's names; a captured key shows its name in the focused field.
    func testCaptureNamesFromSTR130() throws {
        let strings = try keyNames()
        XCTAssertEqual(MacRoman.decode(ControlsDialog.keyName(0x31, strings: strings)), "Space")
        XCTAssertEqual(MacRoman.decode(ControlsDialog.keyName(0x7E, strings: strings)), "Arrow Up")
        XCTAssertEqual(MacRoman.decode(ControlsDialog.keyName(0x80, strings: strings)), "??")
        XCTAssertEqual(MacRoman.decode(ControlsDialog.keyName(-1, strings: strings)), "??")
        XCTAssertEqual(MacRoman.decode(ControlsDialog.keyName(5, strings: [[0x41], [], [0x42]])), "??", "past the list")
        XCTAssertEqual(MacRoman.decode(ControlsDialog.keyName(1, strings: [[0x41], [], [0x42]])), "??", "an empty entry")

        var r = try open()
        XCTAssertEqual(texts(r), DeimosPrefs.fresh.keyTable.prefix(7).map { name(Int($0), strings) })
        XCTAssertEqual(texts(r)[0], "Arrow Up")
        key(&r, 0x00)                                                        // 'a' into field 5
        XCTAssertEqual(MacRoman.decode(r.dialog.runner.label(5)), name(0x00, strings))
        XCTAssertEqual(r.dialog.sets[0][0], 0x00)
        var prefs = DeimosPrefs.fresh
        prefs.keyTable[6] = 0x0C                                             // Space free
        r = try open(prefs: prefs)
        click(&r, item: 17)
        XCTAssertEqual(r.dialog.focus, 17)
        key(&r, 0x31)
        XCTAssertEqual(MacRoman.decode(r.dialog.runner.label(17)), "Space")
        XCTAssertEqual(r.dialog.sets[0][6], 0x31)
    }

    /// Each accepted key advances the focus 5→7→9→11→13→15→17→5 and stores into the current player's slot; a click on
    /// a field focuses it. Return, Esc and Tab are bindable and never press Save or Cancel.
    func testFocusAdvancesAndWraps() throws {
        var r = try open()
        let codes: [UInt16] = [0x00, 0x24, 0x35, 0x30, 0x04, 0x05, 0x06]      // a, Return, Esc, Tab, h, g, z
        let chars: [UInt8] = [0x61, 0x0D, 0x1B, 0x09, 0x68, 0x67, 0x7A]
        for (i, c) in codes.enumerated() {
            XCTAssertEqual(r.dialog.focus, Self.fields[i])
            let s = key(&r, c, char: chars[i])
            XCTAssertNil(s.finished, "key \(c) is bound, not Save or Cancel")
            XCTAssertEqual(s.output.requests, [], "no beep")
            XCTAssertEqual(r.dialog.focus, Self.fields[(i + 1) % 7], "after key \(i + 1)")
            XCTAssertEqual(r.dialog.shown, r.dialog.focus, "the selection follows")
        }
        XCTAssertEqual(r.dialog.sets[0], codes.map(Int32.init))
        XCTAssertEqual(r.dialog.sets[1], DeimosPrefs.fresh.keyTable[7...].map(Int32.init), "P2 untouched")

        click(&r, item: 11)
        XCTAssertEqual(r.dialog.focus, 11)
        XCTAssertEqual(r.dialog.shown, 11)
        key(&r, 0x07)
        XCTAssertEqual(r.dialog.sets[0][3], 0x07)
        XCTAssertEqual(r.dialog.focus, 13)
        click(&r, item: 4)                                                  // a picture: nothing (X 10043850)
        XCTAssertEqual(r.dialog.focus, 13)
    }

    /// A code held by any of the 14 working slots (either player) is refused: FlushEvents (the rest of the pass's input
    /// goes) and SysBeep, nothing changes.
    func testDuplicateAcrossPlayersRefused() throws {
        var r = try open()
        let before = texts(r)
        let s = pass(&r, HeldKeys(keyEvents: [KeyEvent(charCode: 0x38, keyCode: 0x5B),     // P2's kp8
                                              KeyEvent(charCode: 0x61, keyCode: 0x00)]))   // flushed
        XCTAssertEqual(s.output.requests, [.beep])
        XCTAssertEqual(texts(r), before)
        XCTAssertEqual(r.dialog.focus, 5)
        XCTAssertEqual(r.dialog.sets[0] + r.dialog.sets[1], DeimosPrefs.fresh.keyTable.map(Int32.init))
        key(&r, 0x7B)                                                       // P1's own Arrow Left, in field 5
        XCTAssertEqual(r.dialog.focus, 5, "refused: P1's slot 1 holds it")
        XCTAssertEqual(texts(r), before)

        clickTab(&r, 2)
        XCTAssertEqual(r.dialog.player, 1)
        let p2 = texts(r)
        let t = key(&r, 0x7E)                                               // P1's Arrow Up, on P2's tab
        XCTAssertEqual(t.output.requests, [.beep])
        XCTAssertEqual(texts(r), p2)
        XCTAssertEqual(r.dialog.focus, 5)
        XCTAssertEqual(click(&r, item: 1).finished, true)
        XCTAssertEqual(r.state.prefs, .fresh, "nothing changed")
    }

    /// The self-match is by name: the focused field's own key is accepted again (and the focus moves on); the same key
    /// in another field is refused.
    func testSameKeyInSameFieldAccepted() throws {
        var r = try open()
        let s = key(&r, 0x7E)                                               // field 5 already reads "Arrow Up"
        XCTAssertEqual(s.output.requests, [])
        XCTAssertEqual(r.dialog.focus, 7)
        XCTAssertEqual(r.dialog.sets[0][0], 0x7E)
        XCTAssertEqual(MacRoman.decode(r.dialog.runner.label(5)), "Arrow Up")
        let t = key(&r, 0x7E)                                               // field 7 reads "Arrow Left"
        XCTAssertEqual(t.output.requests, [.beep])
        XCTAssertEqual(r.dialog.focus, 7)
        XCTAssertEqual(r.dialog.sets[0][1], 0x7B)
    }

    /// Modifier keys bind only as GetKeys edges on null events, and only left Control 0x3B, Shift 0x38, Option 0x3A
    /// and Command 0x37, one per null event, each latched until released (10044014..100441ac). Caps Lock, the
    /// right-hand modifiers and Fn never bind.
    func testModifiersOnlyLeftFour() throws {
        var prefs = DeimosPrefs.fresh
        prefs.keyTable[4] = 0x0C                                            // ⌘ and ⌥ free
        prefs.keyTable[5] = 0x0D
        var r = try open(prefs: prefs)
        let strings = try keyNames()
        let before = texts(r)
        for code: UInt16 in [0x39, 0x36, 0x3C, 0x3D, 0x3E, 0x3F] {
            let s = pass(&r, HeldKeys(held: [code], capsLock: code == 0x39,
                                      keyEvents: [KeyEvent(charCode: 0, keyCode: code)]))
            XCTAssertEqual(s.output.requests, [], "code \(code)")
            XCTAssertEqual(texts(r), before, "code \(code) never binds")
            XCTAssertEqual(r.dialog.focus, 5)
        }
        pass(&r, HeldKeys(held: [0x3B]))
        XCTAssertEqual(r.dialog.sets[0][0], 0x3B)
        XCTAssertEqual(MacRoman.decode(r.dialog.runner.label(5)), name(0x3B, strings))
        XCTAssertEqual(r.dialog.focus, 7)
        pass(&r, HeldKeys(held: [0x3B]))
        XCTAssertEqual(r.dialog.focus, 7, "latched while held")
        pass(&r, HeldKeys(held: [0x3B, 0x38, 0x3A, 0x37]))
        XCTAssertEqual(r.dialog.focus, 9, "one modifier a null event: Shift")
        XCTAssertEqual(r.dialog.sets[0][1], 0x38)
        pass(&r, HeldKeys(held: [0x3B, 0x38, 0x3A, 0x37]))
        XCTAssertEqual(r.dialog.sets[0][2], 0x3A)
        pass(&r, HeldKeys(held: [0x3B, 0x38, 0x3A, 0x37]))
        XCTAssertEqual(r.dialog.sets[0][3], 0x37)
        XCTAssertEqual(r.dialog.focus, 13)
        pass(&r)                                                            // all up: the latches clear
        let s = pass(&r, HeldKeys(held: [0x3B]))
        XCTAssertEqual(s.output.requests, [.beep], "Control again, held by slot 0: refused")
        XCTAssertEqual(r.dialog.focus, 13)
    }

    /// A tab change refills the fields from that player's set and puts the focus on field 5 (X 10043798..10043848);
    /// the keys then go to that player. A click on the tab already up sets the focus variable to 5 only.
    func testTabSwitchRefillsFocus5() throws {
        let strings = try keyNames()
        var r = try open()
        key(&r, 0x00)
        XCTAssertEqual(r.dialog.focus, 7)
        clickTab(&r, 2)
        XCTAssertEqual(r.dialog.player, 1)
        XCTAssertEqual(r.dialog.focus, 5)
        XCTAssertEqual(r.dialog.shown, 5)
        XCTAssertEqual(texts(r), DeimosPrefs.fresh.keyTable[7...].map { name(Int($0), strings) })
        key(&r, 0x01)
        XCTAssertEqual(r.dialog.sets[1][0], 0x01, "P2's slot 0")
        XCTAssertEqual(r.dialog.sets[0][0], 0x00, "P1's untouched")
        XCTAssertEqual(r.dialog.focus, 7)
        clickTab(&r, 2)                                                     // the tab already up
        XCTAssertEqual(r.dialog.focus, 5, "X 10043798: the focus variable only")
        XCTAssertEqual(r.dialog.shown, 7, "no refill, no new selection")
        clickTab(&r, 1)
        XCTAssertEqual(r.dialog.player, 0)
        XCTAssertEqual(r.dialog.focus, 5)
        XCTAssertEqual(r.dialog.shown, 5)
        XCTAssertEqual(texts(r)[0], name(0x00, strings))
        XCTAssertEqual(texts(r)[1], name(0x7B, strings))
    }

    /// Save copies both working sets into the live prefs and answers true (X 1004386c..100438ec); Cancel changes
    /// nothing and answers false. Neither restores what is under the window (the parent redraws).
    func testSaveWritesBothSetsCancelNone() throws {
        for save in [true, false] {
            var r = try open()
            key(&r, 0x00)                                                   // P1 slot 0 = a
            clickTab(&r, 2)
            key(&r, 0x01)                                                   // P2 slot 0 = s
            key(&r, 0x02)                                                   // P2 slot 1 = d
            XCTAssertEqual(r.state.prefs, .fresh, "the live prefs wait for Save")
            let s = click(&r, item: save ? 1 : 2)
            XCTAssertEqual(s.finished, save)
            XCTAssertFalse(s.output.ops.contains { if case .copy = $0 { true } else { false } }, "no restore")
            var expected = DeimosPrefs.fresh
            if save {
                expected.keyTable[0] = 0x00
                expected.keyTable[7] = 0x01
                expected.keyTable[8] = 0x02
            }
            XCTAssertEqual(r.state.prefs, expected)
            XCTAssertEqual(pass(&r).finished, save, "a stray pass repeats the answer")
        }
    }
}
