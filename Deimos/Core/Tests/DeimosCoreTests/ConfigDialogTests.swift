import XCTest
@testable import DeimosCore
import HectorResources

/// Phase 4 S6 DG — the configuration window, DLOG/DITL 190 "Game - Preferences", as the OS X build runs it (X
/// `FUN_10011240` 10011240..100117a0, refresh X `100117a0`; grounding C §2; `osx-build.md` D2–D5, ruling 5). The window
/// is stepped pass by pass without a host, with the app fork read from the repo. Clicks are one-pass clicks (the
/// mouse-down and the release in the same pass) unless a test holds the button. Every loop names its bound (G11).
final class ConfigDialogTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    /// DLOG 190 (379 × 377) centred on the 640 × 480 picture: the content's top left.
    private static let origin = MousePoint(h: (640 - 379) / 2, v: (480 - 377) / 2)
    /// The window frame (dBoxProc: 6 pixels outside the content) — what the window saves and restores.
    private static let frame = MacRect(top: 45, left: 124, bottom: 434, right: 515)
    private static let screen = MacRect(top: 0, left: 0, bottom: 480, right: 640)
    /// `FUN_100050f0`'s key sets (P1, P2).
    private static let defaultKeys: [UInt16] = [0x7E, 0x7B, 0x7C, 0x7D, 0x37, 0x3A, 0x31,
                                                0x5B, 0x56, 0x58, 0x57, 0x77, 0x75, 0x79]
    private static let returnKey = KeyEvent(charCode: 0x0D, keyCode: 0x24)
    private static let escKey = KeyEvent(charCode: 0x1B, keyCode: 0x35)

    private struct Run {
        var dialog: ConfigDialog
        var state: FrontEndState
        var first: ScreenStep<Bool>
    }

    private func open(firstLaunch: Bool = false, prefs: DeimosPrefs = .fresh) throws -> Run {
        let a = try assets()
        var state = try FrontEndState(assets: a, prefs: prefs, shellResources: try DialogFork.loaded.get())
        var d = ConfigDialog(firstLaunch: firstLaunch)
        let first = d.pass(keys: HeldKeys(), ticks: 100, returned: nil, state: &state)
        XCTAssertNil(first.finished, "the window stays open")
        return Run(dialog: d, state: state, first: first)
    }

    @discardableResult
    private func pass(_ r: inout Run, _ keys: HeldKeys = HeldKeys(), returned: ScreenResult? = nil) -> ScreenStep<Bool> {
        r.dialog.pass(keys: keys, ticks: 200, returned: returned, state: &r.state)
    }

    /// An item's rect in the picture.
    private func global(_ r: Run, _ item: Int) -> MacRect {
        guard let l = r.dialog.items?[item]?.rect else {
            XCTFail("the window has no item \(item)")
            return MacRect(top: 0, left: 0, bottom: 0, right: 0)
        }
        return MacRect(top: l.top + Self.origin.v, left: l.left + Self.origin.h,
                       bottom: l.bottom + Self.origin.v, right: l.right + Self.origin.h)
    }

    private func centre(_ r: Run, _ item: Int) -> MousePoint {
        let g = global(r, item)
        return MousePoint(h: (g.left + g.right) / 2, v: (g.top + g.bottom) / 2)
    }

    /// A press and release at `p` in one pass.
    @discardableResult
    private func click(_ r: inout Run, at p: MousePoint) -> ScreenStep<Bool> {
        pass(&r, HeldKeys(mouse: p, mouseButton: false, mouseDowns: [p]))
    }

    @discardableResult
    private func click(_ r: inout Run, _ item: Int) -> ScreenStep<Bool> { click(&r, at: centre(r, item)) }

    @discardableResult
    private func key(_ r: inout Run, _ k: KeyEvent, command: Bool = false) -> ScreenStep<Bool> {
        pass(&r, HeldKeys(held: command ? [0x37] : [], keyEvents: [k]))
    }

    /// The COST rects drawn by `ops` that lie inside `rect`, with their colours.
    private func fills(_ ops: [RenderOp], inside rect: MacRect) -> [UInt16] {
        ops.compactMap { op -> UInt16? in
            guard case let .draw(c) = op, c.face == FourCC("COST")!, let r = c.costRect else { return nil }
            guard r.left >= rect.left, r.right <= rect.right, r.top >= rect.top, r.bottom <= rect.bottom else { return nil }
            return c.costColour
        }
    }

    // MARK: - The tests

    /// Items 8, 9 and 17 toggle byte prefs 4, 5 and 8 in memory at once (X 10011660, 100116a4, 100116e8: `cntlzw` = not,
    /// `FUN_10004ab0`, `SetControlValue`); a second click toggles back. Item 10 (byte 7) is greyed in X and a click on it
    /// does nothing. The window draws at its first pass (the screen under it saved first, the window's rect blitted
    /// last), redraws only when its picture changes, and Save (Return, the default item) keeps the edits.
    func testConfigItemToggles() throws {
        var r = try open()
        let ops = r.first.output.ops
        XCTAssertEqual(ops.first, .copy(from: .back, to: .terrain, src: Self.frame, dst: Self.frame, interlaced: false),
                       "the screen under the window is saved first")
        XCTAssertEqual(ops.last, .screenBlit(src: Self.frame, dst: Self.frame))
        XCTAssertGreaterThan(ops.count, 200, "the whole window is drawn")
        for op in ops.dropFirst().dropLast() {
            guard case let .draw(c) = op else { XCTFail("only draws between the save and the blit: \(op)"); break }
            XCTAssertEqual(c.face, FourCC("COST")!)
            XCTAssertEqual(c.alpha, 0)
            XCTAssertTrue(c.drawNow)
            XCTAssertEqual(c.clip, Self.screen, "the full-screen clip on every command")
        }
        XCTAssertEqual(pass(&r).output, PassOutput(), "nothing changed: nothing drawn")
        XCTAssertEqual(r.dialog.value(8), 1, "Full Screen shows byte 4 (fresh 1)")
        let onFrame = MousePoint(h: Self.frame.left + 2, v: Self.frame.top + 2)
        XCTAssertEqual(click(&r, at: onFrame).output, PassOutput(), "a click on the window's frame: no item, no beep")
        XCTAssertEqual(click(&r, at: MousePoint(h: 10, v: 10)).output, PassOutput(requests: [.beep]),
                       "a click outside the window beeps (ModalDialog)")

        for (item, byte) in [(8, 4), (9, 5), (17, 8)] {
            let before = r.state.prefs.bytePrefs[byte]
            let s = click(&r, item)
            XCTAssertNil(s.finished)
            XCTAssertEqual(r.state.prefs.bytePrefs[byte], before == 0 ? 1 : 0, "item \(item) toggles byte \(byte)")
            XCTAssertEqual(r.dialog.value(item), Int(r.state.prefs.bytePrefs[byte]), "item \(item) shows it")
            XCTAssertTrue(s.output.ops.contains(.screenBlit(src: Self.frame, dst: Self.frame)), "redrawn")
            click(&r, item)
            XCTAssertEqual(r.state.prefs.bytePrefs[byte], before, "item \(item) toggles back")
        }
        // Two clicks in one pass: a mouse-down queued behind the first means its button came up, so the first is judged
        // at its own place, not at the pass's last mouse position (the second click's).
        let (c8, c9) = (centre(r, 8), centre(r, 9))
        let (b4, b5) = (r.state.prefs.bytePrefs[4], r.state.prefs.bytePrefs[5])
        pass(&r, HeldKeys(mouse: c9, mouseButton: false, mouseDowns: [c8, c9]))
        XCTAssertEqual(r.state.prefs.bytePrefs[4], b4 == 0 ? 1 : 0, "the first of two clicks in one pass is not lost")
        XCTAssertEqual(r.state.prefs.bytePrefs[5], b5 == 0 ? 1 : 0, "and the second lands")
        pass(&r, HeldKeys(mouse: c9, mouseButton: true, mouseDowns: [c8, c9]))
        XCTAssertEqual(r.state.prefs.bytePrefs[4], b4, "the first click lands while the second is still held")
        XCTAssertEqual(r.state.prefs.bytePrefs[5], b5 == 0 ? 1 : 0, "the held one waits for its release")
        pass(&r, HeldKeys(mouse: c9, mouseButton: false))
        XCTAssertEqual(r.state.prefs.bytePrefs[5], b5, "released over it: hit")

        // Set Controls… with a click queued behind it in the same pass: the queue is flushed before the controls window
        // is called (in the original those events went to the nested window, never back to this one).
        let calls = pass(&r, HeldKeys(mouse: c9, mouseButton: false, mouseDowns: [centre(r, 18), c9]))
        XCTAssertEqual(calls.callee, .controlsDialog, "Set Controls… calls the controls window")
        pass(&r, returned: .controlsDialog(false))
        XCTAssertEqual(r.state.prefs.bytePrefs[5], b5, "the click queued behind it was flushed, not replayed here")

        click(&r, 8)
        let byte7 = r.state.prefs.bytePrefs[7]
        XCTAssertEqual(click(&r, 10).output, PassOutput(), "item 10 is greyed in X: no change, nothing drawn")
        XCTAssertEqual(r.state.prefs.bytePrefs[7], byte7)

        let save = key(&r, Self.returnKey)
        XCTAssertEqual(save.finished, true, "Return = Save")
        XCTAssertEqual(r.state.prefs.bytePrefs[4], 0, "the edit is kept")
        XCTAssertEqual(save.output.music, [.level(100)], "closing re-applies the music volume (X 10011758)")
        XCTAssertEqual(pass(&r).finished, true, "a stray pass after Save still answers Save")
        XCTAssertEqual(Array(save.output.ops.suffix(3)), [
            .copy(from: .terrain, to: .back, src: Self.frame, dst: Self.frame, interlaced: false),
            .loadImage(image: FourCC("back")!, into: .terrain, dst: Self.screen),
            .screenBlit(src: Self.frame, dst: Self.frame),
        ], "closing restores the screen under the window and repaints it")
    }

    /// Defaults (item 3) = `FUN_10004f20(0)` → `FUN_100050f0` (X 10004f80 → 10005150): byte 4 = 1; bytes 5, 6, 7, 8 = 0;
    /// ints 0, 1, 2 = 50, 100, 50; both key sets. Bytes 0–3, 9, 10, 11 and int 3 are untouched.
    func testDefaultsResetsKeysNotBytes9to11() throws {
        var prefs = DeimosPrefs.fresh
        for b in 0...11 { prefs.bytePrefs[b] = UInt8(b == 4 ? 0 : 7) }
        prefs.intPrefs = [10, 20, 30, 9]
        prefs.keyTable = (0..<14).map { UInt16(0x20 + $0) }
        var r = try open(prefs: prefs)
        XCTAssertEqual(click(&r, 3).output.music, [], "Defaults does not re-apply the volume (X 100114b4..100114cc)")
        let p = r.state.prefs
        XCTAssertEqual(Array(p.bytePrefs[4...8]), [1, 0, 0, 0, 0], "bytes 4–8")
        XCTAssertEqual(Array(p.intPrefs[0...2]), [50, 100, 50], "ints 0–2")
        XCTAssertEqual(p.keyTable, Self.defaultKeys, "both key sets")
        XCTAssertEqual(Array(p.bytePrefs[0...3]), [7, 7, 7, 7], "bytes 0–3 untouched")
        XCTAssertEqual(Array(p.bytePrefs[9...11]), [7, 7, 7], "bytes 9–11 untouched (FPS counter, limiter, cheats)")
        XCTAssertEqual(p.intPrefs[3], 9, "int 3 (highest sector) untouched")
        XCTAssertEqual(r.dialog.value(8), 1, "the refresh shows the defaults")
        XCTAssertEqual(r.dialog.value(15), 100)
        XCTAssertEqual(MacRoman.decode(r.dialog.label(16)), "100%")
        XCTAssertTrue(r.dialog.isActive(4), "a change: Revert comes alive")
    }

    /// Cancel restores the 0x34f0-byte snapshot taken at open — the key sets too — and returns false (X 1001173c..
    /// 10011750); so does Esc (the cancel item, `SetDialogCancelItem(2)` when not a first launch, X 10011310..10011320).
    func testCancelRestoresSnapshotIncludingKeys() throws {
        var prefs = DeimosPrefs.fresh
        prefs.keyTable[0] = 0x0D
        prefs.keyTable[13] = 0x22
        prefs.bytePrefs[5] = 1
        prefs.intPrefs[1] = 40
        for useEsc in [false, true] {
            var r = try open(prefs: prefs)
            click(&r, 9)
            click(&r, 17)
            click(&r, 3)                                                    // Defaults: the keys change
            XCTAssertNotEqual(r.state.prefs, prefs, "edited in place")
            XCTAssertEqual(r.state.prefs.keyTable, Self.defaultKeys)
            let s = useEsc ? key(&r, Self.escKey) : click(&r, 2)
            XCTAssertEqual(s.finished, false, useEsc ? "Esc = Cancel" : "Cancel")
            XCTAssertEqual(r.state.prefs, prefs, "the snapshot restored, keys included")
            XCTAssertEqual(s.output.ops.last, .screenBlit(src: Self.frame, dst: Self.frame))
            XCTAssertEqual(s.output.music, [.level(40)], "the restored music volume re-applied (X 10011758)")
            XCTAssertEqual(pass(&r).finished, false, "a stray pass after Cancel still answers Cancel")
        }
        var r = try open(prefs: prefs)
        click(&r, 9)
        XCTAssertEqual(key(&r, KeyEvent(charCode: 0x2E, keyCode: 0x2F), command: true).finished, false, "⌘. = Cancel")
        XCTAssertEqual(r.state.prefs, prefs)
    }

    /// Revert (item 4) is greyed at open (X 10011430..10011438) and comes alive once anything changed (X 10011450..
    /// 1001147c, before each ModalDialog); it restores the snapshot, refreshes, greys itself again and clears the flag
    /// (X 100114d0..10011508).
    func testRevertGreysUntilChange() throws {
        var r = try open()
        XCTAssertFalse(r.dialog.isActive(4))
        XCTAssertEqual(click(&r, 4).output, PassOutput(), "greyed: a click does nothing")
        XCTAssertEqual(click(&r, 9).output.music, [], "a toggle does not touch the volume")
        XCTAssertEqual(r.state.prefs.bytePrefs[5], 1)
        XCTAssertTrue(r.dialog.isActive(4), "alive after a change")
        let s = click(&r, 4)
        XCTAssertNil(s.finished)
        XCTAssertEqual(s.output.music, [.level(100)], "Revert re-applies the music volume (X 100114e4)")
        XCTAssertEqual(r.state.prefs, .fresh, "the snapshot restored")
        XCTAssertEqual(r.dialog.value(9), 0, "refreshed")
        XCTAssertFalse(r.dialog.isActive(4), "greyed again")
        XCTAssertFalse(r.dialog.changed)
        click(&r, 4)
        XCTAssertEqual(r.state.prefs, .fresh)
        // A change and a Revert click in the same pass: Revert comes alive as soon as the change is made (X enables it
        // before each ModalDialog, i.e. before the next event), so the queued click reverts it.
        let both = pass(&r, HeldKeys(mouse: centre(r, 4), mouseButton: false, mouseDowns: [centre(r, 9), centre(r, 4)]))
        XCTAssertEqual(both.output.music, [.level(100)], "Revert ran in the same pass as the change")
        XCTAssertEqual(r.state.prefs, .fresh, "the toggle, then Revert in the same pass: reverted")
        XCTAssertFalse(r.dialog.isActive(4), "and greyed again")
        click(&r, 17)
        XCTAssertTrue(r.dialog.isActive(4), "alive again after the next change")
    }

    /// A first launch (the boot's call) has no cancel item and greys Cancel (X 10011310..10011320, 10011418..10011428):
    /// a click on Cancel, Esc and ⌘. do nothing; Save still closes. From the menu Cancel is live.
    func testFirstLaunchHasNoCancel() throws {
        var r = try open(firstLaunch: true)
        XCTAssertFalse(r.dialog.isActive(2), "Cancel greyed")
        XCTAssertNil(r.dialog.cancelItem)
        click(&r, 9)
        XCTAssertNil(click(&r, 2).finished, "a click on the greyed Cancel does nothing")
        XCTAssertNil(key(&r, Self.escKey).finished, "no cancel item: Esc does nothing")
        XCTAssertNil(key(&r, KeyEvent(charCode: 0x2E, keyCode: 0x2F), command: true).finished, "nor ⌘.")
        XCTAssertEqual(r.state.prefs.bytePrefs[5], 1)

        // Keys the window does not use come back from the runner unhandled, in arrival order, as the seam delivered
        // them (S7's key capture takes them); the configuration window ignores them: nothing changes, nothing drawn.
        let tab = KeyEvent(charCode: 0x09, keyCode: 0x30), a = KeyEvent(charCode: 0x61, keyCode: 0x00, autoRepeat: true)
        var runner = r.dialog.runner                                    // a copy: the window is untouched
        let held = HeldKeys(keyEvents: [tab, a, Self.escKey])
        runner.begin(keys: held)
        var out = PassOutput()
        var got: [ModalDialogRunner.Action] = []
        for _ in 0...runner.turnsLeft {
            guard let action = runner.next(keys: held, &out) else { break }
            got.append(action)
        }
        XCTAssertEqual(got, [.key(tab, command: false), .key(a, command: false), .key(Self.escKey, command: false)],
                       "Tab, a typed key and Esc with no cancel item are handed back")
        XCTAssertEqual(out, PassOutput())
        runner.screenFiltersKeys = true                                 // the screen sees keys before Return / Esc
        let ret = HeldKeys(keyEvents: [Self.returnKey])
        runner.begin(keys: ret)
        XCTAssertEqual(runner.next(keys: ret, &out), .key(Self.returnKey, command: false), "Return to the screen first")
        runner.begin(keys: held)
        XCTAssertEqual(runner.next(keys: held, &out), .key(tab, command: false))
        runner.flush()                                                  // FlushEvents: the rest is dropped
        XCTAssertNil(runner.next(keys: held, &out), "flushed: nothing left in the queue")
        XCTAssertEqual(runner.standardKey(Self.returnKey, command: false), 1, "its standard meaning: the default item")
        XCTAssertNil(runner.standardKey(tab, command: false))
        let before = r.state.prefs
        let typed = pass(&r, HeldKeys(keyEvents: [tab, a]))
        XCTAssertNil(typed.finished)
        XCTAssertEqual(typed.output, PassOutput(), "the window ignores them: nothing drawn")
        XCTAssertEqual(r.state.prefs, before, "nothing changed")

        XCTAssertEqual(click(&r, 1).finished, true, "Save closes")
        XCTAssertEqual(r.state.prefs.bytePrefs[5], 1)

        let menu = try open(firstLaunch: false)
        XCTAssertTrue(menu.dialog.isActive(2))
        XCTAssertEqual(menu.dialog.cancelItem, 2)
    }

    /// X greys items 10, 12, 11 and 13 at open (X 10011348..10011380 — not L's item 8), and the refresh makes the sound
    /// slider (12) live only when byte 7 is already 1 (X 10011904..10011934). Item 19 is hidden (plan ruling 17). Greyed
    /// text is drawn in grey, live text in black; nothing is drawn in the hidden item's rect.
    func testGreyingFollowsOSX() throws {
        let r = try open()
        for item in [10, 11, 12, 13, 4] { XCTAssertFalse(r.dialog.isActive(item), "item \(item) greyed") }
        for item in [1, 2, 3, 8, 9, 14, 15, 16, 17, 18, 20] { XCTAssertTrue(r.dialog.isActive(item), "item \(item) live") }
        XCTAssertTrue(r.dialog.isHidden(19), "Set Gamepad Controls… hidden")
        XCTAssertFalse(r.dialog.isHidden(8))

        let ops = r.first.output.ops
        let sound = fills(ops, inside: global(r, 11)), music = fills(ops, inside: global(r, 14))
        XCTAssertFalse(sound.isEmpty)
        XCTAssertEqual(Set(sound), [DialogDraw.Colour.greyText], "Sound Volume: in grey")
        XCTAssertFalse(music.isEmpty)
        XCTAssertEqual(Set(music), [DialogDraw.Colour.text], "Music Volume: in black")
        XCTAssertEqual(fills(ops, inside: global(r, 19)), [], "nothing in the hidden item")

        var prefs = DeimosPrefs.fresh
        prefs.bytePrefs[7] = 1
        let bypass = try open(prefs: prefs)
        XCTAssertTrue(bypass.dialog.isActive(12), "byte 7 already 1: the sound slider is live")
        for item in [10, 11, 13] { XCTAssertFalse(bypass.dialog.isActive(item), "item \(item) still greyed") }
        XCTAssertEqual(bypass.dialog.value(10), 1)
    }

    /// The two volume sliders (items 12 and 15; CNTL 2000/2001 absent, question 6: plain sliders, 0…100): the thumb
    /// follows the mouse with a live "%i%%" label and pins at both ends; the pref (int 1 for item 15, int 0 for item
    /// 12) is set only on release, with `SysBeep(1)` (X 10011588..100115ec). A press on the track pages by 10, pinned.
    /// The greyed sound slider ignores a press.
    func testVolumeSliderPins() throws {
        var r = try open()
        let track = global(r, 15)
        let thumb = DialogDraw.sliderThumb(track, value: 100, min: 0, max: 100)
        let grab = MousePoint(h: (thumb.left + thumb.right) / 2, v: (thumb.top + thumb.bottom) / 2)
        pass(&r, HeldKeys(mouse: grab, mouseButton: true, mouseDowns: [grab]))
        let far = pass(&r, HeldKeys(mouse: MousePoint(h: 0, v: grab.v + 40), mouseButton: true))
        XCTAssertEqual(r.dialog.value(15), 0, "pinned at the minimum")
        XCTAssertEqual(MacRoman.decode(r.dialog.label(16)), "0%", "the live label")
        XCTAssertEqual(r.state.prefs.intPrefs[1], 100, "not set while held")
        XCTAssertFalse(far.output.ops.isEmpty, "redrawn while dragging")
        XCTAssertEqual(far.output.music, [], "the volume is not applied while held")
        let up = pass(&r, HeldKeys(mouse: MousePoint(h: 0, v: grab.v), mouseButton: false))
        XCTAssertEqual(r.state.prefs.intPrefs[1], 0, "set on release")
        XCTAssertEqual(up.output.requests, [.beep])
        XCTAssertEqual(up.output.music, [.level(0)], "and the music volume re-applied (X 100115d8 → 10049580)")

        let low = DialogDraw.sliderThumb(track, value: 0, min: 0, max: 100)
        let grab2 = MousePoint(h: (low.left + low.right) / 2, v: grab.v)
        pass(&r, HeldKeys(mouse: grab2, mouseButton: true, mouseDowns: [grab2]))
        pass(&r, HeldKeys(mouse: MousePoint(h: 639, v: grab.v), mouseButton: true))
        XCTAssertEqual(r.dialog.value(15), 100, "pinned at the maximum")
        XCTAssertEqual(MacRoman.decode(r.dialog.label(16)), "100%")
        pass(&r, HeldKeys(mouse: MousePoint(h: 639, v: grab.v), mouseButton: false))
        XCTAssertEqual(r.state.prefs.intPrefs[1], 100)

        // A press on the track left of the thumb, held: −10 a pass, pinned at 0 (bound: 15 passes).
        let page = MousePoint(h: track.left + 2, v: grab.v)
        pass(&r, HeldKeys(mouse: page, mouseButton: true, mouseDowns: [page]))
        XCTAssertEqual(r.dialog.value(15), 90, "one page")
        for _ in 0..<15 { pass(&r, HeldKeys(mouse: page, mouseButton: true)) }
        XCTAssertEqual(r.dialog.value(15), 0, "pinned at 0")
        let rel = pass(&r, HeldKeys(mouse: page, mouseButton: false))
        XCTAssertEqual(r.state.prefs.intPrefs[1], 0)
        XCTAssertEqual(rel.output.requests, [.beep])
        XCTAssertEqual(rel.output.music, [.level(0)])

        // The sound slider is greyed (byte 7 = 0): a press does nothing.
        let sound = centre(r, 12)
        XCTAssertEqual(pass(&r, HeldKeys(mouse: sound, mouseButton: false, mouseDowns: [sound])).output, PassOutput())
        XCTAssertEqual(r.state.prefs.intPrefs[0], 50)

        // With byte 7 = 1 it drives int 0.
        var prefs = DeimosPrefs.fresh
        prefs.bytePrefs[7] = 1
        var b = try open(prefs: prefs)
        let s = global(b, 12)
        let st = DialogDraw.sliderThumb(s, value: 50, min: 0, max: 100)
        let sg = MousePoint(h: (st.left + st.right) / 2, v: (st.top + st.bottom) / 2)
        pass(&b, HeldKeys(mouse: sg, mouseButton: true, mouseDowns: [sg]))
        let soundUp = pass(&b, HeldKeys(mouse: MousePoint(h: 639, v: sg.v), mouseButton: false))
        XCTAssertEqual(b.state.prefs.intPrefs[0], 100)
        XCTAssertEqual(soundUp.output.music, [.level(100)],
                       "the routine re-applies the music level (int 1); the sound level has no gain stage on OS X (D31)")
        XCTAssertEqual(MacRoman.decode(b.dialog.label(13)), "100%")

        // A press on the thumb released without moving leaves the value exactly as it was, for every value: the
        // thumb follows the mouse's offset from where it was grabbed, and value → thumb → value round-trips
        // (bound: 101 values).
        for v in 0...100 {
            let t = DialogDraw.sliderThumb(track, value: v, min: 0, max: 100)
            let c = MousePoint(h: (t.left + t.right) / 2, v: (t.top + t.bottom) / 2)
            XCTAssertEqual(DialogDraw.sliderValue(track, x: c.h, min: 0, max: 100), v, "value \(v) round-trips")
            var p = DeimosPrefs.fresh
            p.intPrefs[1] = Int32(v)
            var q = try open(prefs: p)
            click(&q, at: c)
            XCTAssertEqual(q.dialog.value(15), v, "a thumb click at \(v) leaves it")
            XCTAssertEqual(q.state.prefs.intPrefs[1], Int32(v))
            pass(&q, HeldKeys(mouse: c, mouseButton: true, mouseDowns: [c]))
            pass(&q, HeldKeys(mouse: c, mouseButton: false))
            XCTAssertEqual(q.dialog.value(15), v, "a held thumb press at \(v) released unmoved leaves it")
            XCTAssertEqual(MacRoman.decode(q.dialog.label(16)), "\(v)%")
        }
    }

    /// The boot opens the window, always as a first launch (X 10000214 `li r3,0x1`), when byte pref 2 is 0 or Option is
    /// held, and not otherwise; when it returns, byte 2 = 1. Without the dialog resources the window finishes at once
    /// with false (the original asserts on a nil `GetNewDialog`, X 100112cc..100112dc; the replica does not trap).
    func testBootDialogRuleByte2AndOption() throws {
        let a = try assets()
        let fork = try DialogFork.loaded.get()
        for (pref2, option, opens) in [(UInt8(0), false, true), (1, true, true), (0, true, true), (1, false, false)] {
            let label = "byte 2 = \(pref2), Option \(option)"
            var prefs = DeimosPrefs.fresh
            prefs.bytePrefs[2] = pref2
            var fe = try FrontEnd(assets: a, prefs: prefs, launch: LaunchModifiers(option: option), shellResources: fork)
            _ = fe.pass(keys: HeldKeys(), ticks: 1_000)
            guard opens else {
                XCTAssertEqual(fe.screens, [.boot], "\(label): no window")
                continue
            }
            XCTAssertEqual(fe.screens, [.boot, .configDialog], "\(label): the window is up")
            _ = fe.pass(keys: HeldKeys(keyEvents: [Self.escKey]), ticks: 1_001)
            XCTAssertEqual(fe.screens, [.boot, .configDialog], "\(label): a first launch — Esc does nothing")
            _ = fe.pass(keys: HeldKeys(keyEvents: [Self.returnKey]), ticks: 1_002)
            XCTAssertEqual(fe.screens, [.boot], "\(label): Save closes it")
            _ = fe.pass(keys: HeldKeys(), ticks: 1_003)
            XCTAssertEqual(fe.state.prefs.bytePrefs[2], 1, "\(label): byte 2 ← 1")
        }

        var prefs = DeimosPrefs.fresh
        prefs.bytePrefs[2] = 0
        var bare = try FrontEnd(assets: a, prefs: prefs)
        _ = bare.pass(keys: HeldKeys(), ticks: 1_000)
        XCTAssertEqual(bare.screens, [.boot], "no dialog resources: the window finishes at once")
        XCTAssertEqual(bare.state.prefs.bytePrefs[2], 1, "and the boot carries on")
        var d = ConfigDialog(firstLaunch: true)
        var st = try FrontEndState(assets: a, prefs: .fresh)
        XCTAssertEqual(d.pass(keys: HeldKeys(), ticks: 0, returned: nil, state: &st).finished, false)
    }
}
