import XCTest
@testable import DeimosCore

/// Phase 4 S2 MM — the main menu `FUN_100229a0` as the OS X build runs it (X `10022bb0`; grounding A §2, §6, §10;
/// `front-end.md` §2; `osx-build.md` D1, D7, D15): the registered layout (ruling 4), the idle pass, the copyright
/// flip, hover, click tracking, the keys, suspend and resume, the menu-music rule and the way out. The menu is
/// stepped pass by pass without a host, either alone (to hand it what a called screen returned) or inside a
/// `FrontEnd` (where the frame reads the shell's events first). Every loop names its bound and fails on it (G11).
final class MainMenuTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    private static let full = MacRect(top: 0, left: 0, bottom: 480, right: 640)
    private static let copyright = Array("COPYRIGHT 2001-2003 SWOOP SOFTWARE & AMBROSIA SOFTWARE, INC.".utf8)
    private static let banner = Array("THIS COPY IS REGISTERED TO AMBROSIA CLASSICS".utf8)
    /// The `mebu` frames of buttons 1–6 (1 PLAYER, 2 PLAYER, PREFERENCES, SCORES, DEMOS, QUIT; A §2.1).
    private static let frames = [0, 1, 2, 4, 5, 6]

    /// The centre of button `i` (1…6): (320, 168 + 30·i).
    private static func button(_ i: Int) -> MousePoint { MousePoint(h: 320, v: Int32(168 + 30 * i)) }
    private static let logoPoint = MousePoint(h: 320, v: 101)
    private static let webPoint = MousePoint(h: 320, v: 430)
    private static let copyrightPoint = MousePoint(h: 320, v: 450)
    private static let nowhere = MousePoint(h: 100, v: 100)

    private static func incl(_ a: DeimosAssets) -> SoundCue {
        SoundPlay.perm(a.sounds[2], priority: 0x4b, volume: 100, allowMultiple: false)
    }
    private static func mbro(_ a: DeimosAssets) -> SoundCue {
        SoundPlay.perm(a.sounds[11], priority: 0x4b, volume: 100, allowMultiple: false)
    }
    private static func key(_ c: UInt8, repeating: Bool = false) -> HeldKeys {
        HeldKeys(keyEvents: [KeyEvent(charCode: c, keyCode: 0, autoRepeat: repeating)])
    }

    /// A fresh state and a menu whose entry pass ran at `t0`.
    private func entered(_ a: DeimosAssets, t0: UInt32 = 1_000, soundAvailable: Bool = true)
        throws -> (menu: MainMenu, state: FrontEndState, entry: ScreenStep<ScreenDone>) {
        var state = try FrontEndState(assets: a, prefs: .fresh, soundAvailable: soundAvailable)
        var menu = MainMenu()
        let entry = menu.pass(keys: HeldKeys(), ticks: t0, returned: nil, state: &state)
        return (menu, state, entry)
    }

    /// A front end whose boot (Phase 4 S6 BT, `BootTests`) ran at `t0` until the main menu was the top screen — six
    /// passes with fresh prefs, the configuration window's stub inside the first — so the menu's entry ran at `t0`, as
    /// the boot stub's single pass did. Bound: 10 passes (G11).
    private func frontEnd(_ a: DeimosAssets, t0: UInt32 = 1_000) throws -> FrontEnd {
        var fe = try FrontEnd(assets: a, prefs: .fresh)
        for _ in 0..<10 where fe.screens.last != .mainMenu { _ = fe.pass(keys: HeldKeys(), ticks: t0) }
        if fe.screens.last != .mainMenu { XCTFail("bound: the menu is not up within 10 boot passes") }
        XCTAssertEqual(fe.screens, [.mainMenu])
        return fe
    }

    private func draws(_ ops: [RenderOp]) -> [DrawCommand] {
        ops.compactMap { if case let .draw(c) = $0 { return c } else { return nil } }
    }

    private func tickWaits(_ ops: [RenderOp], _ n: UInt32) -> Int {
        ops.filter { $0 == .hostWait(.ticks(n)) }.count
    }

    /// The forced or dirty redraw `FUN_10024810`: the whole back buffer restored from the save buffer, the list
    /// rebuilt and drawn once (`FUN_100258e0` → `FUN_1000d7f0(list, 0, 0)`), the full screen presented.
    private func redraw(_ s: FrontEndState) -> [RenderOp] {
        [.copy(from: .terrain, to: .back, src: nil, dst: nil, interlaced: false)]
            + s.menuElements.drawOnce(restoreText: false, present: false, text: s.text, assets: s.assets)
            + [.present(.fullScreen)]
    }

    private func copyrightText(_ s: FrontEndState) -> [UInt8] { s.menuElements.elements[8].record.text }

    // MARK: - Layout

    /// The registered build's layout (ruling 4; A §2.1, `FUN_10023fd0` / `FUN_10025420`): nine elements — the logo
    /// (`gasp 5` `galo` frame 0, format 7 `ingl`, centre (320, 101)), six buttons (`gasp 3` `mebu` frames 0, 1, 2, 4,
    /// 5, 6, format 5 `inbn`, centre (320, 168 + 30·i)), no REGISTER, the web line (`inte 0`, format 1 `inwe`, y 426)
    /// and the copyright line (the binary's 2001-2003 string, format 3 `inco`, y 447). Lit: buttons `gasp 4` `mebh`
    /// with format 6, the web line format 2, the copyright format 4, the logo unchanged. A §9a item 4: every lit
    /// frame is wider than its normal frame and as tall, so a lit button's hit rect holds its normal one. The entry
    /// (X `10023800`, no menu bar, D7): `back` into the back and save buffers, the 16-pass fade-in (D1), the redraw,
    /// a full present, the cursor shown, b6 cleared, the clock started.
    func testMenuLayout() throws {
        let a = try assets()
        var (menu, s, entry) = try entered(a, t0: 1_000)
        let list = s.menuElements
        XCTAssertEqual(list.count, 9, "no REGISTER button in the registered build")
        guard list.count == 9 else { return }
        XCTAssertEqual(s.copyrightClock, 1_000)
        XCTAssertFalse(s.menuMusic)
        XCTAssertNil(s.menuLit)

        var logo = a.formats[7]
        logo.locX = 320
        XCTAssertEqual(list.elements[0], .sprite(a.sprites[5], frame: 0, record: TextRequest(format: logo, text: [])))
        XCTAssertEqual(logo.locY, 101)
        for i in 1...6 {
            var f = a.formats[5]
            f.locX = 320
            f.locY = Int32(168 + 30 * i)
            XCTAssertEqual(list.elements[i], .sprite(a.sprites[3], frame: Self.frames[i - 1],
                                                     record: TextRequest(format: f, text: [])), "button \(i)")
        }
        XCTAssertEqual(list.elements[7], .text(TextRequest(format: a.formats[1], text: "WWW.DEIMOSRISING.COM")))
        XCTAssertEqual(list.elements[8], .text(TextRequest(format: a.formats[3], text: Self.copyright)))
        XCTAssertEqual(a.formats[1].locY, 426)
        XCTAssertEqual(a.formats[3].locY, 447)

        func bounds(_ i: Int) -> MacRect { s.menuElements.bounds(of: i, text: s.text, assets: a) }
        XCTAssertEqual(bounds(0), MacRect(top: 47, left: 241, bottom: 156, right: 399))
        XCTAssertEqual(bounds(1), MacRect(top: 186, left: 272, bottom: 211, right: 368))
        XCTAssertEqual(bounds(6), MacRect(top: 336, left: 296, bottom: 361, right: 345))
        XCTAssertEqual(bounds(7), MacRect(top: 426, left: 249, bottom: 439, right: 392))
        XCTAssertEqual(bounds(8), MacRect(top: 447, left: 127, bottom: 460, right: 513))

        // The entry pass's ops, in order.
        let rate = ElementList.fadeRate(floats: a.floats)
        var expected: [RenderOp] = [.loadImage(image: FourCC("back")!, into: .back, dst: Self.full),
                                    .loadImage(image: FourCC("back")!, into: .terrain, dst: Self.full)]
        expected += list.fadeIn(rate: rate, text: s.text, assets: a)
        expected += redraw(s)
        expected.append(.present(.fullScreen))
        XCTAssertEqual(entry.output.ops, expected)
        XCTAssertEqual(tickWaits(entry.output.ops, 1), 15, "16 fade passes (X, D1)")
        XCTAssertEqual(entry.output.requests, [.showCursor])
        XCTAssertEqual(entry.output.sounds, [])
        XCTAssertEqual(entry.output.music, [], "b6 = 0: the boot's music plays on")
        XCTAssertNil(entry.finished)
        XCTAssertNil(entry.callee)

        // Each element lit by the hover, one at a time.
        var t: UInt32 = 1_001
        for i in 0...8 {
            let p: MousePoint = i == 0 ? Self.logoPoint : i == 7 ? Self.webPoint : i == 8 ? Self.copyrightPoint
                                                                                         : Self.button(i)
            _ = menu.pass(keys: HeldKeys(mouse: p), ticks: t, returned: nil, state: &s)
            t += 1
            XCTAssertEqual(s.menuLit, i, "element \(i) lit")
            let e = s.menuElements.elements[i]
            switch i {
            case 0:
                XCTAssertEqual(e, list.elements[0], "the logo is drawn the same lit")
            case 1...6:
                var f = a.formats[6]
                f.locX = 320
                f.locY = Int32(168 + 30 * i)
                XCTAssertEqual(e, .sprite(a.sprites[4], frame: Self.frames[i - 1], record: TextRequest(format: f, text: [])))
                let normal = list.bounds(of: i, text: s.text, assets: a), lit = bounds(i)
                XCTAssertEqual(lit.bottom - lit.top, normal.bottom - normal.top, "A §9a item 4: as tall")
                XCTAssertTrue(lit.left < normal.left && lit.right > normal.right, "A §9a item 4: wider, button \(i)")
            case 7:
                XCTAssertEqual(e, .text(TextRequest(format: a.formats[2], text: "WWW.DEIMOSRISING.COM")))
            default:
                XCTAssertEqual(e, .text(TextRequest(format: a.formats[4], text: Self.copyright)))
            }
        }
    }

    // MARK: - The copyright line

    /// The flip (A §2.2, `10022ad8..10022b50`): strictly after t0 + flli 68 (240) the copyright line becomes "THIS
    /// COPY IS REGISTERED TO <name>" (pgsl 35; the name `FrontEndState.registeredName`, question 2) with a forced
    /// redraw, t0 = now; 240 ticks later it flips back. The clock restarts on a click (before its action), a key
    /// (after it), a suspend and a resume (the resume's b6 restarts it again on the next pass). Bound: 1,000 ticks
    /// per wait.
    func testCopyrightFlip() throws {
        let a = try assets()
        var fe = try frontEnd(a, t0: 1_000)

        /// Passes at t, t+1, … until the copyright text changes; returns the tick of that pass.
        func nextFlip(from start: UInt32, keys: HeldKeys = HeldKeys()) -> UInt32? {
            let before = copyrightText(fe.state)
            var t = start
            for _ in 0..<1_000 {
                let out = fe.pass(keys: keys, ticks: t)
                if copyrightText(fe.state) != before {
                    XCTAssertEqual(out.ops, redraw(fe.state), "a forced redraw")
                    XCTAssertEqual(fe.state.copyrightClock, t, "t0 = now")
                    return t
                }
                t += 1
            }
            XCTFail("bound: no flip in 1,000 ticks")
            return nil
        }

        XCTAssertEqual(copyrightText(fe.state), Self.copyright)
        guard let first = nextFlip(from: 1_001) else { return }
        XCTAssertEqual(first, 1_241, "strictly after t0 + 240")
        XCTAssertEqual(copyrightText(fe.state), Self.banner)
        guard let second = nextFlip(from: first + 1) else { return }
        XCTAssertEqual(second, first + 241)
        XCTAssertEqual(copyrightText(fe.state), Self.copyright, "even flips: the copyright again")

        // A key with no action ('o') restarts the clock after it.
        _ = fe.pass(keys: Self.key(0x6f), ticks: second + 100)
        XCTAssertEqual(fe.state.copyrightClock, second + 100)
        guard let afterKey = nextFlip(from: second + 101) else { return }
        XCTAssertEqual(afterKey, second + 341)

        // A click released inside the web line (whose action does nothing) restarts it.
        let click = afterKey + 50
        _ = fe.pass(keys: HeldKeys(mouse: Self.webPoint, mouseDowns: [Self.webPoint]), ticks: click)
        XCTAssertEqual(fe.state.copyrightClock, click)
        guard let afterClick = nextFlip(from: click + 1, keys: HeldKeys(mouse: Self.nowhere)) else { return }
        XCTAssertEqual(afterClick, click + 241)

        // A suspend restarts it and stops the flips; the resume sets b6, whose pass restarts it once more.
        let suspend = afterClick + 30
        let shown = copyrightText(fe.state)
        _ = fe.pass(keys: HeldKeys(events: [.suspend]), ticks: suspend)
        XCTAssertTrue(fe.state.suspended)
        XCTAssertEqual(fe.state.copyrightClock, suspend)
        for t in (suspend + 1)...(suspend + 600) { _ = fe.pass(keys: HeldKeys(), ticks: t) }
        XCTAssertEqual(copyrightText(fe.state), shown, "no flip while suspended")
        let resume = suspend + 601
        _ = fe.pass(keys: HeldKeys(events: [.resume]), ticks: resume)
        XCTAssertEqual(fe.state.copyrightClock, resume)
        XCTAssertTrue(fe.state.menuMusic, "the resume sets b6")
        guard let afterResume = nextFlip(from: resume + 1) else { return }
        XCTAssertEqual(afterResume, resume + 1 + 241, "the b6 pass restarted the clock")
    }

    // MARK: - Hover

    /// Hover `FUN_10024530` (A §2.2 step 3, `front-end.md` §2.4): the element under the mouse is lit, `mbro` (gaso
    /// 11, 0x4b, 100, 0) only on entering it and never for the logo; leaving unlights; nothing while the mouse is in
    /// the menu-bar strip (the top 22 rows, inclusive — the OS X menu-bar height), so a lit element stays lit there.
    /// The hit rect is the one drawn last (A §9a item 4): a lit 1 PLAYER (`mebh`, 101 wide) holds the mouse 2 px
    /// beyond its normal rect (`mebu`, 96 wide). Bound: the scripted path.
    func testMenuHover() throws {
        let a = try assets()
        var (menu, s, _) = try entered(a)
        let mbro = Self.mbro(a)
        let path: [(MousePoint?, [SoundCue], Int?, String)] = [
            (Self.nowhere, [], nil, "over nothing"),
            (MousePoint(h: 270, v: 198), [], nil, "left of 1 PLAYER's normal rect (272)"),
            (Self.button(1), [mbro], 1, "into 1 PLAYER"),
            (MousePoint(h: 330, v: 200), [], 1, "still inside: no second sound"),
            (MousePoint(h: 270, v: 198), [], 1, "inside the lit rect (270): still lit"),
            (MousePoint(h: 269, v: 198), [], nil, "out of the lit rect"),
            (Self.button(1), [mbro], 1, "back in: the sound again"),
            (Self.button(2), [mbro], 2, "into 2 PLAYER; 1 PLAYER unlit"),
            (Self.logoPoint, [], 0, "the logo lights without a sound"),
            (Self.webPoint, [mbro], 7, "the web line"),
            (MousePoint(h: 320, v: 10), [], 7, "into the menu-bar strip: no hover, the web line stays lit"),
            (MousePoint(h: 320, v: 22), [], 7, "the strip's last row (inclusive)"),
            (MousePoint(h: 320, v: 23), [], nil, "below the strip: the hover runs, nothing under the mouse"),
            (Self.copyrightPoint, [mbro], 8, "the copyright line"),
            (nil, [], nil, "outside the picture: nothing under the mouse"),
        ]
        var t: UInt32 = 1_001
        for (point, sounds, lit, label) in path {
            let step = menu.pass(keys: HeldKeys(mouse: point), ticks: t, returned: nil, state: &s)
            t += 1
            XCTAssertEqual(step.output.sounds, sounds, label)
            XCTAssertEqual(s.menuLit, lit, label)
            XCTAssertNil(step.callee, label)
        }
    }

    // MARK: - Keys

    /// The keys `FUN_10023b00` (`front-end.md` §2.8, L `10023b10..10023d7c`, X `10023ef0..10024170`): each
    /// recognised key plays `incl` (gaso 2, 0x4b, 100, 0), flashes its button for flli 61 = 10 ticks (unlight all,
    /// light it, redraw, wait, unlight, redraw), then calls its screen; `F` plays the click without a flash; `Q` only
    /// sets b8; `R` does nothing (no REGISTER); the volume keys 0x9D / 0x8A change int pref 0 by 10 with no click and
    /// no flash (A §9a item 8: both builds branch past the click), and only with sound; anything else does nothing.
    /// A key that calls a screen restarts the clock when that screen returns; P sets b6 then. A key typed with
    /// Command held is the menu bar's, not the menu's. Bound: the table.
    func testMenuKeys() throws {
        let a = try assets()
        let incl = Self.incl(a)
        enum Want { case play(Int), prefs, scores, demos, lastFilm }
        let table: [(UInt8, Want, Int?)] = [
            (0x31, .play(1), 1), (0x4e, .play(1), 1), (0x6e, .play(1), 1), (0x0d, .play(1), 1), (0x0a, .play(1), 1),
            (0x32, .play(2), 2), (0x50, .prefs, 3), (0x70, .prefs, 3),
            (0x48, .scores, 4), (0x68, .scores, 4), (0x53, .scores, 4), (0x73, .scores, 4),
            (0x44, .demos, 5), (0x64, .demos, 5), (0x46, .lastFilm, nil), (0x66, .lastFilm, nil),
        ]
        for (c, want, flash) in table {
            var (menu, s, _) = try entered(a)
            let label = String(format: "key 0x%02x", c)
            let step = menu.pass(keys: Self.key(c, repeating: c == 0x32), ticks: 1_100, returned: nil, state: &s)
            XCTAssertEqual(step.output.sounds, [incl], label)
            let ops = step.output.ops
            if let flash {
                XCTAssertEqual(tickWaits(ops, 10), 1, "\(label): a 10-tick flash")
                let k = try XCTUnwrap(ops.firstIndex(of: .hostWait(.ticks(10))))
                let frame = Self.frames[flash - 1]
                XCTAssertTrue(draws(Array(ops[..<k])).contains { $0.face == a.sprites[4] && $0.frame == frame },
                              "\(label): lit before the wait")
                XCTAssertFalse(draws(Array(ops[k...])).contains { $0.face == a.sprites[4] },
                               "\(label): nothing lit after it")
            } else {
                XCTAssertEqual(ops, [], "\(label): no flash")
            }
            XCTAssertEqual(s.menuLit, nil, label)
            switch (want, step.next) {
            case let (.play(n), .call(.startReturn(sr))):
                XCTAssertEqual(sr.mode, .play, label)
                XCTAssertEqual(sr.players, n, label)
                XCTAssertNil(sr.film, label)
            case (.prefs, .call(.configDialog(let d))):
                XCTAssertFalse(d.firstLaunch, label)
            case (.scores, .call(.scores)):
                // FUN_10024e70: a full present and the element fade-out after the flash.
                let k = try XCTUnwrap(ops.lastIndex(of: .present(.fullScreen)))
                let rate = ElementList.fadeRate(floats: a.floats)
                XCTAssertEqual(Array(ops[(k + 1)...]), s.menuElements.fadeOut(rate: rate, text: s.text, assets: a), label)
            case (.demos, .call(.films(let f))):
                XCTAssertEqual(f.kind, .demo, label)
            case (.lastFilm, .call(.films(let f))):
                XCTAssertEqual(f.kind, .lastFilm, label)
            default:
                XCTFail("\(label): \(String(describing: step.callee))")
            }
            XCTAssertEqual(s.copyrightClock, 1_000, "\(label): the clock waits for the screen to return")
            // The called screen returns: the clock restarts (and P sets b6).
            let returned: ScreenResult
            switch want {
            case .play: returned = .startReturn(nil)
            case .prefs: returned = .configDialog(false)
            case .scores: returned = .scores(.leave)
            case .demos, .lastFilm: returned = .films(ScreenDone())
            }
            // A `2` typed on the pass the screen returns on reaches the menu's queue (the frame hands that pass's input
            // to its first step, the menu's return).
            let back = menu.pass(keys: Self.key(0x32), ticks: 1_200, returned: returned, state: &s)
            XCTAssertNil(back.callee, label)
            if case .scores = want {
                // The tail of FUN_10024e70: `back` reloaded into both buffers, the fade-in, the redraw, a present.
                XCTAssertEqual(back.output.ops.prefix(2), [.loadImage(image: FourCC("back")!, into: .back, dst: Self.full),
                                                           .loadImage(image: FourCC("back")!, into: .terrain, dst: Self.full)])
                XCTAssertEqual(tickWaits(back.output.ops, 1), 15, label)
                XCTAssertEqual(back.output.ops.last, .present(.fullScreen), label)
                let after = menu.pass(keys: HeldKeys(), ticks: 1_210, returned: nil, state: &s)
                XCTAssertEqual(s.copyrightClock, 1_210, "\(label): restarted after the tail's fade-in")
                XCTAssertNil(after.callee, "\(label): the tail's FlushEvents dropped the 2")
                XCTAssertEqual(after.output.sounds, [], "\(label): the tail's FlushEvents dropped the 2")
            } else {
                XCTAssertEqual(s.copyrightClock, 1_200, label)
            }
            XCTAssertEqual(s.menuMusic, { if case .prefs = want { return true } else { return false } }(), label)
            if case .scores = want { continue }
            // No FlushEvents after these screens (FUN_10024d80 / db0 / de0 / e10 / e40): the 2 is read next.
            let next = menu.pass(keys: HeldKeys(), ticks: 1_201, returned: nil, state: &s)
            guard case let .call(.startReturn(two)) = next.next else {
                XCTFail("\(label): the 2 typed on the return was lost: \(String(describing: next.callee))")
                continue
            }
            XCTAssertEqual(two.players, 2, label)
        }

        // Keys with no flash and no screen.
        var (menu, s, _) = try entered(a)
        XCTAssertEqual(s.prefs.intPrefs[0], 50)
        let quiet: [(UInt8, Int32, Bool, String)] = [
            (0x9d, 40, false, "volume down"), (0x8a, 50, false, "volume up"), (0x8a, 60, false, "up again"),
            (0x52, 60, false, "R: no REGISTER button"), (0x72, 60, false, "r"), (0x4f, 60, false, "O"),
            (0x1b, 60, false, "Esc"), (0x54, 60, false, "T"), (0x51, 60, true, "Q sets b8, silently"),
        ]
        var t: UInt32 = 1_100
        for (c, volume, quit, label) in quiet {
            let step = menu.pass(keys: Self.key(c), ticks: t, returned: nil, state: &s)
            XCTAssertEqual(step.output.sounds, [], label)
            XCTAssertEqual(step.output.ops, [], label)
            XCTAssertNil(step.callee, label)
            XCTAssertEqual(s.prefs.intPrefs[0], volume, label)
            XCTAssertEqual(s.quit, quit, label)
            XCTAssertEqual(s.copyrightClock, t, "\(label): the clock restarts after any key")
            t += 1
        }

        // No sound system: the volume keys change nothing (`FUN_10047990` tests r2−0x60a0).
        var (silent, ss, _) = try entered(a, soundAvailable: false)
        _ = silent.pass(keys: Self.key(0x9d), ticks: 1_100, returned: nil, state: &ss)
        XCTAssertEqual(ss.prefs.intPrefs[0], 50)

        // Command held: the key goes to the menu bar.
        var (cmd, cs, _) = try entered(a)
        var keys = Self.key(0x31)
        keys.held = [0x37]
        let step = cmd.pass(keys: keys, ticks: 1_100, returned: nil, state: &cs)
        XCTAssertNil(step.callee)
        XCTAssertEqual(step.output.sounds, [])
        // … either Command key: the right one (0x36) too.
        var (rcmd, rs, _) = try entered(a)
        keys.held = [0x36]
        let right = rcmd.pass(keys: keys, ticks: 1_100, returned: nil, state: &rs)
        XCTAssertNil(right.callee, "right Command + 1 is the menu bar's")
        XCTAssertEqual(right.output.sounds, [])

        // The entry's FlushEvents (FUN_10048e30, mask 0xffff): a key and a click that reached the pump before the
        // menu came up are dropped, so the first pass after it acts on neither; a menu-bar About is a mouse-down in X
        // (osx-build D23) and goes with them, opening no credits; a suspend stays queued (FlushEvents leaves the OS
        // events), and is dispatched on that pass (t0 = now).
        var early = try FrontEndState(assets: a, prefs: .fresh, soundAvailable: true)
        early.suspended = true                                          // (as the frame applied the event)
        var flushed = MainMenu()
        _ = flushed.pass(keys: HeldKeys(mouse: Self.nowhere, mouseDowns: [Self.button(2)],
                                        keyEvents: [KeyEvent(charCode: 0x31, keyCode: 0)],
                                        events: [.aboutChosen, .suspend]),
                         ticks: 1_000, returned: nil, state: &early)
        for t in UInt32(1_001)...1_002 {
            let after = flushed.pass(keys: HeldKeys(mouse: Self.nowhere), ticks: t, returned: nil, state: &early)
            XCTAssertNil(after.callee, "flushed at the entry (pass \(t))")
            XCTAssertEqual(after.output.sounds, [], "flushed at the entry (pass \(t))")
            if t == 1_001 { XCTAssertEqual(early.copyrightClock, 1_001, "the suspend survived the entry's flush") }
        }

        // Keys queued behind the one that calls a screen are dropped at the call (that screen's FlushEvents or event
        // loop takes them): `1` then `2` in one pass starts one game, and nothing follows its return.
        var (twice, ts, _) = try entered(a)
        let both = HeldKeys(keyEvents: [KeyEvent(charCode: 0x31, keyCode: 0), KeyEvent(charCode: 0x32, keyCode: 0)])
        guard case let .call(.startReturn(first)) = twice.pass(keys: both, ticks: 1_100, returned: nil, state: &ts).next
        else { return XCTFail("1 calls start/return") }
        XCTAssertEqual(first.players, 1)
        _ = twice.pass(keys: HeldKeys(), ticks: 1_200, returned: .startReturn(nil), state: &ts)
        for t in UInt32(1_201)...1_203 {
            let after = twice.pass(keys: HeldKeys(), ticks: t, returned: nil, state: &ts)
            XCTAssertNil(after.callee, "the 2 queued behind the call was dropped (pass \(t))")
            XCTAssertEqual(after.output.sounds, [], "pass \(t)")
        }
    }

    // MARK: - Click tracking

    /// A click `FUN_10024a50` (A §2.2 step 5): the element under the click (the hover runs on its point), `incl`
    /// unless it is the logo, then while the button stays down the element is lit when the mouse is inside the rect
    /// taken at the press and every element unlit otherwise, with a redraw each pass — no hover meanwhile; on the
    /// release every element is unlit and, released inside, the clock restarts and the action runs. QUIT sets b9 at
    /// once. A click on nothing, or with b8 set, does nothing. Bound: the scripted passes.
    func testMenuClickTracking() throws {
        let a = try assets()
        let incl = Self.incl(a), mbro = Self.mbro(a)
        var (menu, s, _) = try entered(a)
        let two = Self.button(2)
        var t: UInt32 = 1_001

        func pass(_ keys: HeldKeys) -> ScreenStep<ScreenDone> {
            let step = menu.pass(keys: keys, ticks: t, returned: nil, state: &s)
            t += 1
            return step
        }

        XCTAssertEqual(pass(HeldKeys(mouse: two)).output.sounds, [mbro])
        var step = pass(HeldKeys(mouse: two, mouseButton: true, mouseDowns: [two]))
        XCTAssertEqual(step.output.sounds, [incl], "the click; no second rollover")
        XCTAssertEqual(s.menuLit, 2)
        XCTAssertEqual(step.output.ops, redraw(s), "redrawn while tracking")
        step = pass(HeldKeys(mouse: Self.nowhere, mouseButton: true))
        XCTAssertNil(s.menuLit, "dragged out: all unlit")
        XCTAssertEqual(step.output.ops, redraw(s))
        XCTAssertEqual(step.output.sounds, [])
        step = pass(HeldKeys(mouse: Self.button(1), mouseButton: true))
        XCTAssertNil(s.menuLit, "over 1 PLAYER while tracking 2 PLAYER: no hover")
        XCTAssertEqual(step.output.sounds, [])
        step = pass(HeldKeys(mouse: two, mouseButton: true))
        XCTAssertEqual(s.menuLit, 2, "back inside: lit, silently")
        XCTAssertEqual(step.output.sounds, [])
        XCTAssertEqual(s.copyrightClock, 1_000)
        let release = t
        step = pass(HeldKeys(mouse: two))
        XCTAssertNil(s.menuLit, "released: all unlit")
        XCTAssertEqual(s.copyrightClock, release, "released inside: the clock restarts before the action")
        guard case let .call(.startReturn(sr)) = step.next else { return XCTFail("2 PLAYER: \(String(describing: step.callee))") }
        XCTAssertEqual(sr.players, 2)
        XCTAssertEqual(sr.mode, .play)
        _ = menu.pass(keys: HeldKeys(), ticks: t, returned: .startReturn(nil), state: &s)
        t += 1
        XCTAssertEqual(s.copyrightClock, release, "a click's clock does not restart on the return")

        // Released outside: no action; the next pass's hover lights what is under the mouse again.
        _ = pass(HeldKeys(mouse: two, mouseButton: true, mouseDowns: [two]))
        step = pass(HeldKeys(mouse: Self.button(1)))
        XCTAssertNil(step.callee)
        XCTAssertNil(s.menuLit)
        step = pass(HeldKeys(mouse: Self.button(1)))
        XCTAssertEqual(step.output.sounds, [mbro])
        XCTAssertEqual(s.menuLit, 1)

        // The logo: tracked without a click sound; its action is nothing, but the clock restarts.
        step = pass(HeldKeys(mouse: Self.logoPoint, mouseDowns: [Self.logoPoint]))
        XCTAssertEqual(step.output.sounds, [], "no rollover and no click for the logo")
        XCTAssertNil(step.callee)
        XCTAssertEqual(s.copyrightClock, t - 1)

        // Nothing under the click.
        step = pass(HeldKeys(mouse: Self.nowhere, mouseDowns: [Self.nowhere]))
        XCTAssertEqual(step.output.sounds, [])
        XCTAssertNil(step.callee)

        // A quick click (released before the pass): 1 PLAYER at once.
        let one = Self.button(1)
        step = pass(HeldKeys(mouse: one, mouseDowns: [one]))
        guard case let .call(.startReturn(sr1)) = step.next else { return XCTFail("1 PLAYER") }
        XCTAssertEqual(sr1.players, 1)
        _ = menu.pass(keys: HeldKeys(), ticks: t, returned: .startReturn(nil), state: &s)
        t += 1

        // The release is tested against the rect taken at the press, not the button's rect now: pressed while lit
        // (its rect the lit one, left 270), dragged out (redrawn unlit: left 272), released at h 270 — inside the
        // rect of the press only. 1 PLAYER runs.
        _ = pass(HeldKeys(mouse: one))
        XCTAssertEqual(s.menuLit, 1)
        _ = pass(HeldKeys(mouse: one, mouseButton: true, mouseDowns: [one]))
        _ = pass(HeldKeys(mouse: Self.nowhere, mouseButton: true))
        XCTAssertNil(s.menuLit)
        step = pass(HeldKeys(mouse: MousePoint(h: 270, v: 198)))
        guard case let .call(.startReturn(srEdge)) = step.next else {
            return XCTFail("released inside the press's rect: \(String(describing: step.callee))")
        }
        XCTAssertEqual(srEdge.players, 1)
        _ = menu.pass(keys: HeldKeys(), ticks: t, returned: .startReturn(nil), state: &s)
        t += 1

        // The web line: the click sound (only the logo has none), the hover's rollover first; its action is nothing.
        step = pass(HeldKeys(mouse: Self.webPoint, mouseDowns: [Self.webPoint]))
        XCTAssertEqual(step.output.sounds, [mbro, incl], "the web line clicks")
        XCTAssertNil(step.callee)
        _ = pass(HeldKeys())

        // PREFERENCES, SCORES, DEMOS and the copyright line call their screens; the copyright line is About, and it
        // clicks. A volume key typed on the pass the screen returns on is read next after PREFERENCES and DEMOS (no
        // FlushEvents there) and dropped by the SCORES / About tail's FlushEvents.
        let calls: [(MousePoint, FrontEndScreen.Kind)] = [(Self.button(3), .configDialog), (Self.button(4), .scores),
                                                          (Self.button(5), .films), (Self.copyrightPoint, .credits)]
        for (p, kind) in calls {
            step = pass(HeldKeys(mouse: p, mouseDowns: [p]))
            XCTAssertEqual(step.callee, kind)
            XCTAssertEqual(step.output.sounds, [mbro, incl], "\(kind): the rollover, then the click")
            let returned: ScreenResult = kind == .configDialog ? .configDialog(false) : kind == .scores ? .scores(.leave)
                : kind == .films ? .films(ScreenDone()) : .credits(.leave)
            let volume = s.prefs.intPrefs[0]
            _ = menu.pass(keys: Self.key(0x9d), ticks: t, returned: returned, state: &s)
            t += 1
            _ = pass(HeldKeys())
            let kept = kind == .configDialog || kind == .films
            XCTAssertEqual(s.prefs.intPrefs[0], kept ? volume - 10 : volume, "\(kind): the key typed on the return")
        }

        // About from the menu bar (FUN_10023330(1) → FUN_10025060) opens the credits as the copyright line does; the
        // credits' N (`.newGame`) starts a one-player game, and its return runs the wrapper's tail (the fade-in).
        step = pass(HeldKeys(events: [.aboutChosen]))
        XCTAssertEqual(step.callee, .credits, "the menu bar's About")
        step = menu.pass(keys: HeldKeys(), ticks: t, returned: .credits(.newGame), state: &s)
        t += 1
        guard case let .call(.startReturn(srNew)) = step.next else {
            return XCTFail("credits N: \(String(describing: step.callee))")
        }
        XCTAssertEqual(srNew.mode, .play)
        XCTAssertEqual(srNew.players, 1)
        XCTAssertNil(srNew.film)
        step = menu.pass(keys: HeldKeys(), ticks: t, returned: .startReturn(nil), state: &s)
        t += 1
        XCTAssertNil(step.callee)
        XCTAssertEqual(tickWaits(step.output.ops, 1), 15, "the tail's fade-in")
        _ = pass(HeldKeys())

        // b8 set: a click is ignored.
        s.quit = true
        s.suspended = true                                            // (keeps the QUIT flash from running first)
        step = pass(HeldKeys(mouse: one, mouseDowns: [one]))
        XCTAssertEqual(step.output.sounds, [])
        XCTAssertNil(step.callee)
        s.quit = false
        s.suspended = false

        // QUIT: b9 at once, no flash.
        let quit = Self.button(6)
        step = pass(HeldKeys(mouse: quit, mouseDowns: [quit]))
        XCTAssertTrue(s.leave)
        XCTAssertEqual(tickWaits(step.output.ops, 10), 0)
        XCTAssertNil(step.callee)
    }

    // MARK: - Suspend and resume

    /// Suspend and resume (A §2.2 steps 2–3; `FUN_10023da0` / `FUN_10023e10`, X `10024190` / `10024200`): while
    /// suspended there is no flip, no hover and no b6 music; the resume shows the cursor, does not present (X, D15)
    /// and sets b6, whose next pass resumes a living stream or starts `inmu` looped. Two cycles: the shell's events,
    /// then the driver's `suspend()` / `resume()` alone (the shared flag; the edge the menu tracks, as the
    /// original's window-collapse check). Bound: 600 ticks suspended per cycle.
    func testMenuSuspendResume() throws {
        let a = try assets()
        var fe = try frontEnd(a, t0: 1_000)
        var t: UInt32 = 1_001
        fe.state.musicAlive = true
        for cycle in 1...2 {
            if cycle == 1 {
                // The queued suspend has not changed b7 yet on its own pass: the hover and b6 still run there.
                fe.state.menuMusic = true
                let own = fe.pass(keys: HeldKeys(mouse: Self.button(2), events: [.suspend]), ticks: t)
                XCTAssertEqual(own.sounds, [Self.mbro(a)], "the suspend's own pass hovers")
                XCTAssertEqual(own.music, [.resume], "the suspend's own pass serves b6")
                XCTAssertEqual(fe.state.menuLit, 2)
            } else {
                fe.state.suspended = true
                _ = fe.pass(keys: HeldKeys(), ticks: t)
            }
            t += 1
            XCTAssertTrue(fe.state.suspended)
            let text = copyrightText(fe.state)
            for _ in 0..<600 {
                let out = fe.pass(keys: HeldKeys(mouse: Self.button(1)), ticks: t)
                t += 1
                XCTAssertEqual(out.sounds, [], "cycle \(cycle): no hover while suspended")
                XCTAssertEqual(out.music, [], "cycle \(cycle): no music while suspended")
            }
            XCTAssertEqual(copyrightText(fe.state), text, "cycle \(cycle): no flip while suspended")
            XCTAssertEqual(fe.state.menuLit, cycle == 1 ? 2 : nil, "cycle \(cycle): no hover while suspended")

            // The resume event is dispatched in step 5, after the pass's step 3, so its b6 is served on the next
            // pass; the edge is seen in step 2, before step 3, so its b6 is served in the same pass.
            let resumed: PassOutput, music: PassOutput
            if cycle == 1 {
                resumed = fe.pass(keys: HeldKeys(events: [.resume]), ticks: t)
                t += 1
                XCTAssertTrue(fe.state.menuMusic, "cycle \(cycle): b6")
                XCTAssertEqual(resumed.music, [])
                music = fe.pass(keys: HeldKeys(), ticks: t)
            } else {
                fe.state.suspended = false
                resumed = fe.pass(keys: HeldKeys(), ticks: t)
                music = resumed
            }
            XCTAssertEqual(fe.state.copyrightClock, t, "cycle \(cycle): b6 restarts the clock")
            t += 1
            XCTAssertFalse(fe.state.suspended)
            XCTAssertEqual(resumed.requests, [.showCursor], "cycle \(cycle)")
            if cycle == 1 {
                XCTAssertEqual(resumed.ops, [], "cycle \(cycle): no present on resume (D15)")
            } else {
                // The edge's turn runs the flip check (the clock is 600 ticks old) before b6 restarts the clock:
                // its only drawing is the flip's forced redraw.
                XCTAssertEqual(resumed.ops, redraw(fe.state), "cycle \(cycle): the flip, nothing else (D15)")
            }
            XCTAssertFalse(fe.state.menuMusic)
            XCTAssertEqual(music.music, cycle == 1 ? [.resume] : [.play(FourCC("inmu")!, loop: true)], "cycle \(cycle)")
            if cycle == 1 { fe.state.musicAlive = false }             // cycle 2: the stream is gone
        }
        XCTAssertTrue(fe.state.musicAlive, "the front end tracked the play")

        // The menu comes up while the app is suspended, and the driver's resume() clears the flag before the menu's
        // first turn: that turn sees the edge and does the resume work (the cursor, b6 served at once).
        var held = try FrontEndState(assets: a, prefs: .fresh, soundAvailable: true)
        held.suspended = true
        var menu = MainMenu()
        _ = menu.pass(keys: HeldKeys(), ticks: 1_000, returned: nil, state: &held)
        held.suspended = false
        let first = menu.pass(keys: HeldKeys(), ticks: 1_001, returned: nil, state: &held)
        XCTAssertEqual(first.output.requests, [.showCursor], "the resume work after a suspended entry")
        XCTAssertEqual(first.output.music, [.play(FourCC("inmu")!, loop: true)])
    }

    // MARK: - Menu music

    /// The menu-music rule (A §2.2 step 3, `10022b9c..10022bd8`): with b6 set the next active pass clears it,
    /// restarts the clock and resumes the stream if one still exists (`FUN_100481e0` → `FUN_10048220(0)`), else plays
    /// `inmu` from the start, looped (`FUN_10047f90('inmu', 1, 0)`). Without b6 the menu never touches the music
    /// (the entry clears b6). PREFERENCES sets b6 when its window returns (`FUN_10024e40`). Bound: 50 passes.
    func testMenuMusicResumeOrRestart() throws {
        let a = try assets()
        var (menu, s, _) = try entered(a)
        var t: UInt32 = 1_001
        for _ in 0..<50 {
            XCTAssertEqual(menu.pass(keys: HeldKeys(), ticks: t, returned: nil, state: &s).output.music, [])
            t += 1
        }
        for alive in [true, false] {
            s.menuMusic = true
            s.musicAlive = alive
            let step = menu.pass(keys: HeldKeys(), ticks: t, returned: nil, state: &s)
            XCTAssertEqual(step.output.music, alive ? [.resume] : [.play(FourCC("inmu")!, loop: true)])
            XCTAssertFalse(s.menuMusic)
            XCTAssertEqual(s.copyrightClock, t)
            t += 1
            XCTAssertEqual(menu.pass(keys: HeldKeys(), ticks: t, returned: nil, state: &s).output.music, [], "once")
            t += 1
        }
        // PREFERENCES by a click: b6 on the return; the next pass restarts or resumes the music.
        let p = Self.button(3)
        let step = menu.pass(keys: HeldKeys(mouse: p, mouseDowns: [p]), ticks: t, returned: nil, state: &s)
        t += 1
        XCTAssertEqual(step.callee, .configDialog)
        XCTAssertFalse(s.menuMusic)
        _ = menu.pass(keys: HeldKeys(), ticks: t, returned: .configDialog(true), state: &s)
        t += 1
        XCTAssertTrue(s.menuMusic)
        s.musicAlive = false
        XCTAssertEqual(menu.pass(keys: HeldKeys(), ticks: t, returned: nil, state: &s).output.music,
                       [.play(FourCC("inmu")!, loop: true)])
    }

    // MARK: - Leaving

    /// The way out (A §2.3; `FUN_10024f90`, the b9 branch of `FUN_100229a0`): `Q`, the menu's Quit and the system's
    /// Quit (which resumes a suspended app first) set b8, and the next active pass flashes QUIT — `incl`, QUIT lit,
    /// 10 ticks, unlit — clears b8 and sets b9; the rest of that pass's loop runs; at the top of the next the menu
    /// presents, fades its elements out (16 passes, D1), frees its list, stops the music with a fade and waits for
    /// it (≤ 600 ticks), and returns; the front end then asks the shell to quit. The registered build shows no
    /// advertisement (no fade to black, no `adve`). The QUIT button leaves without the flash. Bound: 10 passes.
    func testMenuQuitSequence() throws {
        let a = try assets()
        let incl = Self.incl(a)
        let rate = ElementList.fadeRate(floats: a.floats)
        for way in ["Q", "menu Quit", "system Quit while suspended", "QUIT button"] {
            var fe = try frontEnd(a, t0: 1_000)
            var t: UInt32 = 1_001
            var outs: [PassOutput] = []
            func pass(_ keys: HeldKeys = HeldKeys()) -> PassOutput {
                let out = fe.pass(keys: keys, ticks: t)
                t += 1
                outs.append(out)
                return out
            }
            switch way {
            case "Q":
                let q = pass(Self.key(0x71))
                XCTAssertTrue(fe.state.quit, way)
                XCTAssertEqual(q.sounds, [], way)
            case "menu Quit":
                break
            case "system Quit while suspended":
                _ = pass(HeldKeys(events: [.suspend]))
                let r = pass(HeldKeys(events: [.quitRequested]))
                XCTAssertFalse(fe.state.suspended, "\(way): resumed first")
                XCTAssertTrue(fe.state.quit, way)
                XCTAssertEqual(r.requests, [.showCursor], way)
            default:
                let quit = Self.button(6)
                let click = pass(HeldKeys(mouse: quit, mouseDowns: [quit]))
                XCTAssertEqual(click.sounds, [Self.mbro(a), incl], way)
                XCTAssertTrue(fe.state.leave, way)
            }
            if way != "QUIT button" {
                let flash = pass(way == "menu Quit" ? HeldKeys(events: [.quitChosen]) : HeldKeys())
                XCTAssertEqual(flash.sounds, [incl], way)
                XCTAssertEqual(tickWaits(flash.ops, 10), 1, way)
                let k = try XCTUnwrap(flash.ops.firstIndex(of: .hostWait(.ticks(10))))
                XCTAssertTrue(draws(Array(flash.ops[..<k])).contains { $0.face == a.sprites[4] && $0.frame == 6 },
                              "\(way): QUIT lit")
                XCTAssertFalse(draws(Array(flash.ops[k...])).contains { $0.face == a.sprites[4] }, way)
                XCTAssertFalse(fe.state.quit, "\(way): b8 cleared")
                XCTAssertTrue(fe.state.leave, "\(way): b9")
                XCTAssertEqual(flash.music, [], way)
                XCTAssertEqual(flash.requests, [], "\(way): the system Quit's resume work ran once, not again here")
                let rest = pass()
                XCTAssertEqual(rest.ops, [], "\(way): the rest of the loop")
            }
            let list = fe.state.menuElements
            let leave = pass()
            XCTAssertEqual(leave.ops, [.present(.fullScreen)] + list.fadeOut(rate: rate, text: fe.state.text, assets: a), way)
            XCTAssertEqual(leave.music, [], "\(way): the music stops after the fade-out")
            let stop = pass()
            XCTAssertEqual(stop.music, [.stopWithFade], way)
            XCTAssertEqual(stop.ops, [.hostWait(.musicStopped(maxTicks: 600))], way)
            XCTAssertEqual(stop.requests, [], "\(way): not before the wait")
            XCTAssertEqual(fe.state.menuElements, ElementList(), "\(way): the list freed")
            let done = pass()
            XCTAssertEqual(done.requests, [.quit], way)
            XCTAssertTrue(fe.isFinished, way)
            XCTAssertEqual(fe.screens, [], way)
            let passes = ["Q": 6, "menu Quit": 5, "system Quit while suspended": 7, "QUIT button": 4]
            XCTAssertEqual(outs.count, passes[way], "\(way): the passes from the first input to the quit")
            for out in outs {
                XCTAssertFalse(out.ops.contains { if case .fade = $0 { return true } else { return false } }, "\(way): no advert")
                XCTAssertFalse(out.ops.contains { if case let .loadImage(img, _, _) = $0 { return img == FourCC("adve")! } else { return false } }, way)
            }
        }
    }

    // MARK: - The erase question

    /// The SCORES button clicked with Option (key 0x3A) down (`front-end.md` §2.7 row 4; L `10022d8c..` dump
    /// `FUN_100229a0` case 4: `FUN_10049150(0x3a)` → `FUN_10023da0`, `FUN_100498e0(inte 24–27)`, Erase →
    /// `FUN_10004ae0`, `FUN_10023e10`, then `FUN_10024e70`). The release pass: the clock restarts, the suspend handler
    /// (b7 set, the music paused), the question put to the shell and its wait — no screen called yet. The pass after
    /// the answer: the erase applied (Erase = the first button: the default table and both player names; Cancel:
    /// nothing), the resume handler (b7 clear, the cursor, b6, the music resumed: b5 is clear at the menu), then the
    /// SCORES action as a plain click runs it (present, the element fade-out, the scores screen). Bound: 2 answers.
    func testScoresClickWithOptionAsksErase() throws {
        let a = try assets()
        let scores = Self.button(4)
        let question = HighScoreTable.eraseQuestion(a)
        XCTAssertEqual(question.firstButton, "Erase")
        for answer in [QuestionButton.first, .second] {
            var (menu, s, _) = try entered(a)
            s.prefs.highScores[0] = 999_999
            s.prefs.highScoreNames[0] = "Ben"
            s.prefs.playerNames[0] = "Ann"
            let before = s.prefs
            let label = "\(answer)"

            let ask = menu.pass(keys: HeldKeys(held: [0x3a], mouse: scores, mouseDowns: [scores]), ticks: 1_001,
                                returned: nil, state: &s)
            XCTAssertNil(ask.callee, "\(label): the scores screen waits for the answer")
            XCTAssertEqual(ask.output.sounds, [Self.mbro(a), Self.incl(a)], "\(label): the rollover, then the click")
            XCTAssertEqual(ask.output.requests, [.ask(question)], label)
            XCTAssertEqual(ask.output.ops.last, .hostWait(.answer), "\(label): the question's wait ends the pass")
            XCTAssertEqual(ask.output.music, [.pause], "\(label): FUN_10023da0 pauses the music")
            XCTAssertTrue(s.suspended, "\(label): b7 set")
            XCTAssertEqual(s.copyrightClock, 1_001, "\(label): the clock restarts before the action (10022d50)")
            XCTAssertEqual(s.prefs, before, "\(label): nothing erased before the answer")

            let rate = ElementList.fadeRate(floats: a.floats)
            let fadeOut = [RenderOp.present(.fullScreen)] + s.menuElements.fadeOut(rate: rate, text: s.text, assets: a)
            let open = menu.pass(keys: HeldKeys(events: [.answer(answer)]), ticks: 1_100, returned: nil, state: &s)
            XCTAssertEqual(open.callee, .scores, "\(label): then the SCORES action")
            XCTAssertEqual(open.output.ops, fadeOut, "\(label): FUN_10024e70's present and fade-out")
            XCTAssertEqual(open.output.requests, [.showCursor], "\(label): FUN_10023e10's cursor")
            XCTAssertEqual(open.output.music, [.resume], "\(label): FUN_10048220(0)")
            XCTAssertFalse(s.suspended, "\(label): b7 clear")
            XCTAssertTrue(s.menuMusic, "\(label): b6")
            XCTAssertEqual(s.prefs, answer == .first ? HighScoreTable.erase(before) : before, label)
            if answer == .first {
                XCTAssertEqual(s.prefs.playerNames, DeimosPrefs.fresh.playerNames, "the player names reset")
                XCTAssertEqual(s.prefs.highScores, DeimosPrefs.fresh.highScores)
            }

            // The scores screen returns: the wrapper's tail, as after a plain click.
            let back = menu.pass(keys: HeldKeys(), ticks: 1_200, returned: .scores(.leave), state: &s)
            XCTAssertNil(back.callee, label)
            XCTAssertEqual(tickWaits(back.output.ops, 1), 15, "\(label): the tail's fade-in")
        }
    }

    /// The erase question is the mouse path's alone (`front-end.md` §2.7: the `H` / `S` keys open the scores with no
    /// Option test, `FUN_10023b00` → `FUN_10024e70`): `H`, `h`, `S` and `s` typed with Option held, and a SCORES click
    /// without Option, open the scores screen at once and never ask.
    func testScoresKeyWithOptionDoesNotAsk() throws {
        let a = try assets()
        for c: UInt8 in [0x48, 0x68, 0x53, 0x73] {
            var (menu, s, _) = try entered(a)
            let step = menu.pass(keys: HeldKeys(held: [0x3a], keyEvents: [KeyEvent(charCode: c, keyCode: 0)]),
                                 ticks: 1_001, returned: nil, state: &s)
            XCTAssertEqual(step.callee, .scores, "key \(c)")
            XCTAssertFalse(step.output.requests.contains { if case .ask = $0 { true } else { false } }, "key \(c)")
            XCTAssertFalse(step.output.ops.contains(.hostWait(.answer)), "key \(c)")
            XCTAssertEqual(step.output.music, [], "key \(c): no suspend")
            XCTAssertFalse(s.suspended, "key \(c)")
        }
        var (menu, s, _) = try entered(a)
        let scores = Self.button(4)
        let step = menu.pass(keys: HeldKeys(mouse: scores, mouseDowns: [scores]), ticks: 1_001, returned: nil, state: &s)
        XCTAssertEqual(step.callee, .scores, "a click without Option")
        XCTAssertFalse(step.output.requests.contains { if case .ask = $0 { true } else { false } })
        XCTAssertEqual(step.output.music, [])
        XCTAssertFalse(s.suspended)
    }
}
