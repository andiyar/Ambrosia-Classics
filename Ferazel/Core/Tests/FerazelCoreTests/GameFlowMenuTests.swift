import XCTest
@testable import FerazelCore

/// F1a (docs/plans/2026-10-14-ferazel-phase3.md): `GameFlow` part 1 — the boot (`.main @ 1000ffc0`, M l. 8136–8358),
/// the main menu (`.MainMenu @ 1000e618`, M l. 7303–7445; `.TrackClickOnCommandButton @ 10002c5c`, M l. 1407–1494),
/// `.Quit` (M l. 7449–7487) and the Credits scroll timing (`.DoAboutDialog @ 1007853c`, M l. 65263–65435). Driven tick
/// by tick against the committed `Resources/Ferazel` (D26). A missing data file is a FAILURE, never a skip.
final class GameFlowMenuTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// No file traffic in these tests (Options is not opened).
    private final class NoFiles: FrontFiles {
        func loadPrefs() -> Data? { nil }
        func storePrefs(_ record: Data) throws {}
        func readSavedGame(_ ref: SavedGameRef) throws -> SaveBlock { SaveBlock() }
        func writeSavedGame(_ block: SaveBlock, to ref: SavedGameRef) throws(SaveWriteError) {}
    }

    /// The prefs file as a record in memory; every write-back recorded.
    private final class PrefsFiles: FrontFiles {
        let record: Data
        var stored: [Data] = []
        init(record: Data) { self.record = record }
        func loadPrefs() -> Data? { record }
        func storePrefs(_ record: Data) throws { stored.append(record) }
        func readSavedGame(_ ref: SavedGameRef) throws -> SaveBlock { SaveBlock() }
        func writeSavedGame(_ block: SaveBlock, to ref: SavedGameRef) throws(SaveWriteError) {}
    }

    private final class NoLevels: LevelServices {
        func prepare(level: Int) throws -> LevelFaces { LevelFaces() }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {}
        func deathEffectStep(_ k: Int) throws {}
    }

    private func make(_ r: FerazelResources, prefs: FerazelPrefs = FerazelPrefs(),
                      files: FrontFiles = NoFiles()) -> GameFlow {
        GameFlow(resources: r, prefs: prefs, seed: 1, files: files, levels: NoLevels())
    }

    private struct Tick {
        let t: UInt32
        let out: FrontOutput
    }

    /// Ticks `flow` from `t` until `until` holds (checked after each tick) or `max` ticks; `t` ends on the next tick.
    @discardableResult
    private func drive(_ flow: GameFlow, _ t: inout UInt32, max: Int = 1000,
                       input: (UInt32) -> FrontInput = { _ in FrontInput() },
                       until: (GameFlow) -> Bool) -> [Tick] {
        var ticks: [Tick] = []
        for _ in 0..<max {
            ticks.append(Tick(t: t, out: flow.tick(now: t, input: input(t))))
            t &+= 1
            if until(flow) { break }
        }
        return ticks
    }

    /// Boots `flow` to its first main-menu pass (both loads finish at once, no faces reported).
    private func bootToMenu(_ flow: GameFlow, _ t: inout UInt32) {
        for _ in 0..<5 {
            drive(flow, &t) { f in
                if case .loading = f.state { return true }
                return f.state == .mainMenu
            }
            if case .loading = flow.state { flow.loadFinished() } else { break }
        }
        XCTAssertEqual(flow.state, .mainMenu)
    }

    private func tints(_ o: FrontOutput) -> Int {
        o.draws.filter { if case .screenGamma(.tint) = $0 { return true }; return false }.count
    }

    private func fadeIns(_ o: FrontOutput) -> [Int] {
        o.draws.compactMap { if case .screenGamma(.fadeToColor(let p, nil)) = $0 { return p }; return nil }
    }

    private func pictures(_ o: FrontOutput) -> [Int16] {
        o.draws.compactMap {
            switch $0 {
            case .drawPicture(let id, _, _, _): return id
            case .copyPicture(let id, _, _, _, _, _): return id
            default: return nil
            }
        }
    }

    private func snds(_ o: FrontOutput) -> [Int16] { o.sounds.map(\.snd) }

    // MARK: - Tests

    func testBootSequence() throws {
        let r = try resources()
        let flow = make(r)
        var t: UInt32 = 1000
        let t0 = t

        // `GammaFadeOut(6)` (30 ticks), then PICT 131, the menu bar hidden, track 24 started at volume 0 and faded in
        // (`FadeAIFFMusic(1,6)`: 24 cues over 144 ticks, then V = 9·256/9), then `GammaFadeIn(6)` (21 steps).
        let a = drive(flow, &t) { f in if case .loading = f.state { return true }; return false }
        XCTAssertEqual(flow.state, .loading(.sounds))
        XCTAssertEqual(a.prefix(30).map { tints($0.out) }, [Int](repeating: 1, count: 30))
        let logo = a[30].out
        XCTAssertEqual(pictures(logo), [131])
        XCTAssertEqual(logo.requests.first, .hideMenuBar)
        XCTAssertEqual(logo.music.prefix(2), [.play(track: 24), .volume(0)])
        let musicTicks = a.filter { !$0.out.music.isEmpty }.map { Int($0.t &- t0) }
        XCTAssertEqual(musicTicks, Array(stride(from: 30, through: 30 + 144, by: 6)))
        XCTAssertEqual(a[30 + 144].out.music, [.volume(256)])
        let fadeInTicks = a.filter { !fadeIns($0.out).isEmpty }.map { Int($0.t &- t0) }
        XCTAssertEqual(fadeInTicks, Array(174...195))                // 21 steps + the closing 100 %
        XCTAssertEqual(a.count, 196)                                  // the boot keys polled at 195: none down
        XCTAssertTrue(a.allSatisfy { $0.out.requests.allSatisfy { if case .dialog = $0 { return false }; return true } })

        // The logo stays up for the load time only: nothing until the App says the sounds are loaded.
        for _ in 0..<5 { XCTAssertEqual(flow.tick(now: t, input: FrontInput()), FrontOutput()); t &+= 1 }
        flow.loadFinished()
        let t1 = t
        let b = drive(flow, &t) { f in if case .loading(.faces) = f.state { return true }; return false }
        XCTAssertEqual(b.prefix(30).map { tints($0.out) }, [Int](repeating: 1, count: 30))
        XCTAssertEqual(b[30].out.draws.prefix(2), [.setScreenClut(id: 128), .drawPicture(id: 136, chain: .frontEnd,
                                                                                            h: 0, v: 0)])
        XCTAssertEqual(Int(b.last!.t &- t1), 30 + 21)

        // The 3-D bar (`.Init3DProgBar(36, 440, 190)`): +0x48 per face; redraw only when the width moved ≥ 3 px.
        flow.loadProgress(faces: 14)                                  // w = 190·1008 >> 16 = 2: skipped
        XCTAssertTrue(flow.tick(now: t, input: FrontInput()).draws.isEmpty); t &+= 1
        flow.loadProgress(faces: 15)                                  // w 3: PaintRect (36,440)–(40,449) + the edge
        let bar = flow.tick(now: t, input: FrontInput()); t &+= 1
        XCTAssertEqual(bar.draws.first, .fillRect(left: 36, top: 440, right: 40, bottom: 449,
                                                  rgb: RGB16(0x6666, 0x6666, 0xcccc)))
        XCTAssertEqual(bar.draws.dropFirst().first, .drawLine(h1: 39, v1: 440, h2: 39, v2: 448, rgb: RGB16(0, 0, 0)))
        XCTAssertTrue(bar.present)
        flow.loadProgress(faces: 20)                                  // w 3 → 4: |Δ| + 5 < 8, skipped
        XCTAssertTrue(flow.tick(now: t, input: FrontInput()).draws.isEmpty); t &+= 1
        XCTAssertEqual(flow.progressBar.drawnWidth, 3)                // a skipped call keeps the stored width
        XCTAssertEqual(flow.progressBar.progress, 20 * 0x48)
        // p ≥ 58000 redraws even a small move: w 166 (57400) → 168 is skipped at 57999, drawn at 58000.
        var near = ProgressBar3D()
        XCTAssertFalse(near.update(57400).isEmpty)
        XCTAssertEqual(near.drawnWidth, 166)
        XCTAssertTrue(near.update(57999).isEmpty)
        XCTAssertEqual(near.drawnWidth, 166)
        XCTAssertFalse(near.update(58000).isEmpty)
        XCTAssertEqual(near.drawnWidth, 168)
        // The ramp (`SetColorPerc`): [3] = (0x27, 0x27, 0x51) % → 39·0xffff/100, 81·0xffff/100.
        XCTAssertEqual(ProgressBar3D.ramp[3], RGB16(25558, 25558, 53083))

        // `Update3DProgBar(0x10000)` (full, 190 px), then `.MainMenu`: idle 60 ticks (`WaitNextEvent` sleep 60),
        // `GammaFadeOut(6)`, clut 130 + PICT 130, `GammaFadeIn(6)` → the first menu pass.
        flow.loadFinished()
        let t2 = t
        let c = drive(flow, &t) { $0.state == .mainMenu }
        XCTAssertTrue(c[0].out.draws.contains(.drawLine(h1: 226, v1: 440, h2: 226, v2: 448, rgb: RGB16(0, 0, 0))))
        XCTAssertEqual(c[0].out.draws.first, .drawLine(h1: 36, v1: 440, h2: 36, v2: 449,
                                                       rgb: RGB16(25558, 25558, 53083)))   // the left edge, ramp[3]
        XCTAssertEqual(flow.progressBar.drawnWidth, 190)
        let firstTint = c.firstIndex { tints($0.out) > 0 }!
        XCTAssertEqual(Int(c[firstTint].t &- t2), 60)
        let menu = c.first { pictures($0.out).contains(130) }!
        XCTAssertEqual(Int(menu.t &- t2), 60 + 30)
        XCTAssertEqual(menu.out.draws.prefix(2), [.setScreenClut(id: 130), .drawPicture(id: 130, chain: .frontEnd,
                                                                                          h: 0, v: 0)])
        XCTAssertEqual(menu.out.requests, [.showMenuBarItems(MenuState(menusLive: true, paused: false, musicOn: true,
                                                                       soundOn: true))])
        XCTAssertEqual(Int(c.last!.t &- t2), 60 + 30 + 21)

        // A key down ends the idle early (an event wakes `WaitNextEvent`).
        let early = make(r)
        var u: UInt32 = 0
        drive(early, &u) { f in if case .loading = f.state { return true }; return false }
        early.loadFinished()
        drive(early, &u) { f in if case .loading(.faces) = f.state { return true }; return false }
        early.loadFinished()
        let u2 = u
        let d = drive(early, &u, input: { $0 &- u2 >= 5 ? FrontInput(keys: KeyState(pressed: [0x31])) : FrontInput() }) {
            $0.state == .mainMenu
        }
        XCTAssertEqual(Int(d.first { tints($0.out) > 0 }!.t &- u2), 5)
        // A quit event ends the idle too — and survives it: `WaitNextEvent(0xffff, …, 0x3c)` (M l. 7323) returns the
        // pending activate / update event first, so the menu's first pass dispatches the quit → `.Quit`.
        let eaten = make(r)
        var e: UInt32 = 0
        drive(eaten, &e) { f in if case .loading = f.state { return true }; return false }
        eaten.loadFinished()
        drive(eaten, &e) { f in if case .loading(.faces) = f.state { return true }; return false }
        eaten.loadFinished()
        let e2 = e
        var kept = false
        let q = drive(eaten, &e, input: { t in
            if t &- e2 == 5 { eaten.quitEvent() }
            if t &- e2 == 20 { kept = eaten.appleEvents.quit }                   // the idle over, the fade-out on
            return FrontInput()
        }) { $0.state == .mainMenu }
        XCTAssertEqual(Int(q.first { tints($0.out) > 0 }!.t &- e2), 5)
        XCTAssertTrue(kept, "kept through the idle")
        drive(eaten, &e, max: 200) { $0.state == .quit }
        XCTAssertEqual(eaten.state, .quit)
        XCTAssertTrue(eaten.quitting)
        XCTAssertTrue(eaten.appleEvents.isEmpty)

        // Boot keys N+F (0x2d + 0x03): fading disabled + "Fading disabled."; F1 (0x7a): "Sound loading turned off."
        let keyed = make(r)
        let held = FrontInput(keys: KeyState(pressed: [0x2d, 0x03, 0x7a]))
        var k: UInt32 = 0
        var reports: [(tick: UInt32, request: ShellRequest)] = []
        for _ in 0..<400 {
            let o = keyed.tick(now: k, input: held)
            let d = o.requests.filter { if case .dialog = $0 { return true }; return false }
            reports += d.map { (k, $0) }
            if !d.isEmpty { keyed.dialogDone(.ok) }
            k &+= 1
            if case .loading = keyed.state { break }
        }
        XCTAssertEqual(reports.map(\.request), [.dialog(.report(text: "Fading disabled.")),
                                                .dialog(.report(text: "Sound loading turned off."))])
        XCTAssertEqual(reports.map(\.tick), [195, 196])              // each report blocks until it is answered
        XCTAssertFalse(keyed.fade.fadingEnabled)
        XCTAssertFalse(keyed.soundLoading)
        // F1 empties only `.InitSounds` (M l. 39746); 4803/4804 come from `.InitAppGlobals` (M l. 352–357), which
        // loads them regardless: the menu buttons still click.
        bootToMenu(keyed, &k)
        let credit = FrontInput(keys: KeyState(pressed: [0x08]))
        let click = drive(keyed, &k, max: 11, input: { _ in credit }) { _ in false }
        XCTAssertEqual(snds(click[0].out), [4803])
        XCTAssertEqual(snds(click[10].out), [4804])
    }

    func testMainMenuHotRects() throws {
        // `PointInRect(pt, l, t, r, b)` → `PtInRect`: left/top inside, right/bottom outside; checked 1 → 5.
        let rects: [(l: Int, t: Int, r: Int, b: Int)] = [(427, 263, 581, 305), (434, 305, 626, 345),
                                                         (441, 346, 612, 388), (448, 387, 562, 427),
                                                         (456, 429, 539, 471)]
        for (i, q) in rects.enumerated() {
            let n = i + 1
            XCTAssertEqual(MainMenu.button(h: q.r - 1, v: q.b - 1), n, "button \(n) bottom-right")
            XCTAssertEqual(MainMenu.button(h: q.l, v: q.b - 1), n, "button \(n) bottom-left")
            XCTAssertEqual(MainMenu.button(h: q.r - 1, v: q.t), n == 4 ? 3 : n, "button \(n) top-right")
            XCTAssertNotEqual(MainMenu.button(h: q.r, v: q.b - 1), n)
            XCTAssertNotEqual(MainMenu.button(h: q.l - 1, v: q.b - 1), n)
            XCTAssertNotEqual(MainMenu.button(h: q.l, v: q.b), n == 3 ? 4 : n)   // 3's bottom row 387 is in 4
        }
        XCTAssertEqual(MainMenu.button(h: 448, v: 387), 3)            // 3 and 4 overlap on row 387: Options first
        XCTAssertNil(MainMenu.button(h: 500, v: 428))                  // the gap between 4 and 5
        XCTAssertNil(MainMenu.button(h: 10, v: 10))

        // Pointer over no button: v < 0x15 shows the menu bar, else hides it (each only on a change, as the
        // `*_DAT_100a0220` guard); over a button with the button up, nothing at all.
        let flow = make(try resources())
        var t: UInt32 = 0
        bootToMenu(flow, &t)
        func pass(_ h: Int, _ v: Int) -> FrontOutput {
            defer { t &+= 1 }
            return flow.tick(now: t, input: FrontInput(mouse: (h, v)))
        }
        XCTAssertEqual(pass(100, 20).requests, [.showMenuBar])
        XCTAssertEqual(pass(100, 20).requests, [])
        XCTAssertEqual(pass(100, 21).requests, [.hideMenuBar])
        XCTAssertEqual(pass(100, 21).requests, [])
        XCTAssertEqual(pass(500, 280), FrontOutput())
        XCTAssertEqual(flow.state, .mainMenu)
        // Inactive: neither the mouse nor the keys are read (`DAT_100a5108`).
        let o = flow.tick(now: t, input: FrontInput(keys: KeyState(pressed: [0x2d]), mouse: (100, 5), active: false))
        XCTAssertEqual(o, FrontOutput())
        XCTAssertEqual(flow.state, .mainMenu)
    }

    func testTrackClickKeyboardPath() throws {
        let flow = make(try resources())
        var t: UInt32 = 0
        bootToMenu(flow, &t)
        let t0 = t
        let n = FrontInput(keys: KeyState(pressed: [0x2d]))
        let ticks = drive(flow, &t, max: 40, input: { $0 == t0 ? n : FrontInput() }) { $0.state != .mainMenu }
        XCTAssertEqual(flow.state, .newGame)
        XCTAssertEqual(ticks.count, 11)
        XCTAssertEqual(pictures(ticks[0].out), [4901])
        XCTAssertEqual(snds(ticks[0].out), [4803])
        XCTAssertEqual(ticks[0].out.draws.first, .copyPicture(
            id: 4901, chain: .frontEnd, source: Rect16(top: 0, left: 0, bottom: 42, right: 154),
            dest: Rect16(top: 263, left: 427, bottom: 305, right: 581), forceClut: nil, transparent: false))
        for k in 1..<10 { XCTAssertEqual(ticks[k].out, FrontOutput(), "tick \(k): Delay(10) blocks") }
        XCTAssertEqual(pictures(ticks[10].out), [4911])
        XCTAssertEqual(snds(ticks[10].out), [4804])
        // `STPlayRegSound(…, 10, 0x55)` at prefs+0x0e 7 (scale 196): both sides ((0x55·196) >> 8 as u16) >> 1.
        XCTAssertEqual(ticks[0].out.sounds.first, SoundCue(snd: 4803, priority: 10, left: 32, right: 32,
                                                           rate: 0x10000))
        XCTAssertEqual(flow.defaultWorld, 1)                          // `*fd5c = 1` before `.NewGame`
        XCTAssertFalse(ticks.contains { !fadeIns($0.out).isEmpty })   // the keyboard path has no GammaFadeIn

        // At prefs+0x0e 9 (scale 252) 0x55 and 0x56 part: (0x55·252) >> 8 = 83 → 41 (0x56 would give 42).
        var nine = FerazelPrefs(); nine.soundVolume = 9
        let loud = make(try resources(), prefs: nine)
        var l: UInt32 = 0
        bootToMenu(loud, &l)
        let lc = loud.tick(now: l, input: FrontInput(keys: KeyState(pressed: [0x08])))
        XCTAssertEqual(lc.sounds, [SoundCue(snd: 4803, priority: 10, left: 41, right: 41, rate: 0x10000)])

        // O and R → `.ContinueGame` (button 2), after the 10-tick track.
        for key in [0x1f, 0x0f] {
            let cont = make(try resources())
            var c: UInt32 = 0
            bootToMenu(cont, &c)
            let c0 = c
            let press = FrontInput(keys: KeyState(pressed: [key]))
            let ct = drive(cont, &c, max: 40, input: { $0 == c0 ? press : FrontInput() }) {
                $0.state != .mainMenu
            }
            XCTAssertEqual(cont.state, .continueGame, "key \(key)")
            XCTAssertEqual(pictures(ct[0].out), [4902], "key \(key)")
            XCTAssertEqual(ct.count, 11, "key \(key)")
        }

        // I and P → `.Options` (DLOG 6900); closing writes the re-read record back (`WriteResource`), `.MakeCurrPrefs`
        // reports it, the status-bar redraw flags are set and the loop resumes.
        var stored = FerazelPrefs(); stored.soundVolume = 3
        let pf = PrefsFiles(record: stored.record())
        let opt = make(try resources(), files: pf)
        var o: UInt32 = 0
        bootToMenu(opt, &o)
        for (i, key) in [0x22, 0x23].enumerated() {
            let o0 = o
            let press = FrontInput(keys: KeyState(pressed: [key]))
            let ot = drive(opt, &o, max: 40, input: { $0 == o0 ? press : FrontInput() }) {
                $0.state != .mainMenu
            }
            XCTAssertEqual(opt.state, .options, "key \(key)")
            XCTAssertEqual(pictures(ot[0].out), [4903], "key \(key)")
            XCTAssertEqual(ot.last!.out.requests, [.showCursor, .dialog(.preferences)], "key \(key)")
            let model = try XCTUnwrap(opt.prefsDialog)
            XCTAssertEqual(model.record, stored)
            XCTAssertEqual(pf.stored.count, i)                        // nothing written while the dialog is up
            opt.dialogDone(.ok)
            let closed = opt.tick(now: o, input: FrontInput()); o &+= 1
            XCTAssertEqual(pf.stored.count, i + 1)
            XCTAssertEqual(pf.stored.last, stored.record())
            XCTAssertEqual(closed.prefs, stored)
            XCTAssertTrue(closed.present)
            XCTAssertEqual(opt.state, .mainMenu)
            XCTAssertNil(opt.prefsDialog)
            XCTAssertTrue(opt.statusBarRedrawFe0c)
            XCTAssertTrue(opt.statusBarRedraw511e)
        }

        // Sound off: the same draws, no cue.
        var off = FerazelPrefs(); off.soundOn = 0
        let quiet = make(try resources(), prefs: off)
        var u: UInt32 = 0
        bootToMenu(quiet, &u)
        let q = quiet.tick(now: u, input: FrontInput(keys: KeyState(pressed: [0x08])))
        XCTAssertEqual(pictures(q), [4904])
        XCTAssertTrue(q.sounds.isEmpty)

        // Q: track 5 (PICT 4905 / 4915), then `.Quit`: FadeAIFFMusic(0,1) (24 ticks), `.stop`, GammaFadeOut(6),
        // clut 801, the menu bar shown, `ExitToShell`.
        let quit = make(try resources())
        var w: UInt32 = 0
        bootToMenu(quit, &w)
        XCTAssertEqual(quit.tick(now: w, input: FrontInput(mouse: (100, 20))).requests, [.showMenuBar]); w &+= 1
        let w0 = w
        let qt = drive(quit, &w, max: 200, input: { $0 == w0 ? FrontInput(keys: KeyState(pressed: [0x0c])) : FrontInput() }) {
            $0.state == .quit
        }
        XCTAssertEqual(pictures(qt[0].out), [4905])
        XCTAssertEqual(pictures(qt[10].out), [4915])
        XCTAssertEqual(qt[10].out.music.first, .volume(256))
        XCTAssertEqual(qt[10 + 24].out.music, [.volume(0), .stop])
        // `.HideTheMenuBar` after `FlameDispose`, with the first `GammaFadeOut(6)` step on the same tick.
        XCTAssertEqual(qt[10 + 24].out.requests, [.hideMenuBar])
        XCTAssertEqual(tints(qt[10 + 24].out), 1)
        XCTAssertFalse(qt[..<(10 + 24)].contains { $0.out.requests.contains(.hideMenuBar) })
        XCTAssertEqual(qt.last!.out.requests.suffix(2), [.showMenuBar, .quit])
        XCTAssertEqual(qt.last!.out.draws.last, .setScreenClut(id: 801))
        XCTAssertEqual(Int(qt.last!.t &- w0), 10 + 24 + 30)
        XCTAssertEqual(qt.filter { tints($0.out) > 0 }.count, 30)

        // The system's quit at the main menu (`.DoQuitAppAE`, dispatched by the pass's `.CheckEvent`): the same `.Quit`
        // sequence with no button track — FadeAIFFMusic(0,1), `.stop`, GammaFadeOut(6), clut 801, `ExitToShell`.
        let sys = make(try resources())
        var y: UInt32 = 0
        bootToMenu(sys, &y)
        XCTAssertFalse(sys.quitting)
        sys.quitEvent()
        let y0 = y
        let st = drive(sys, &y, max: 200) { $0.state == .quit }
        XCTAssertTrue(sys.quitting)
        XCTAssertTrue(sys.appleEvents.isEmpty)
        XCTAssertFalse(st.contains { pictures($0.out).contains(4905) }, "no button track")
        XCTAssertEqual(st[0].out.requests.first, .showCursor)
        XCTAssertEqual(st[0].out.music.first, .volume(256))
        XCTAssertEqual(st[24].out.music, [.volume(0), .stop])
        XCTAssertEqual(st.last!.out.requests.suffix(2), [.showMenuBar, .quit])
        XCTAssertEqual(st.last!.out.draws.last, .setScreenClut(id: 801))
        XCTAssertEqual(Int(st.last!.t &- y0), 24 + 30)
    }

    func testMouseTrackSlideOut() throws {
        let flow = make(try resources())
        var t: UInt32 = 0
        bootToMenu(flow, &t)
        // Press in Credits, slide out, back in, out again, release outside: no action.
        let path: [(h: Int, v: Int, down: Bool)] = [(500, 400, true), (500, 400, true), (300, 400, true),
                                                    (300, 400, true), (500, 400, true), (300, 400, true),
                                                    (300, 400, false)]
        var outs: [FrontOutput] = []
        for p in path {
            outs.append(flow.tick(now: t, input: FrontInput(mouse: (p.h, p.v), button: p.down))); t &+= 1
        }
        XCTAssertEqual(outs.map(pictures), [[4904], [], [4914], [], [4904], [4914], []])
        XCTAssertEqual(outs.map(snds), [[4803], [], [4804], [], [4803], [4804], []])
        XCTAssertEqual(flow.state, .mainMenu)
        XCTAssertNil(flow.credits)

        // Press in, release inside: normal + 4804 on the release, then `.Credits` (DLOG 600).
        let a = flow.tick(now: t, input: FrontInput(mouse: (500, 400), button: true)); t &+= 1
        XCTAssertEqual(pictures(a), [4904])
        let b = flow.tick(now: t, input: FrontInput(mouse: (500, 400), button: false)); t &+= 1
        XCTAssertEqual(pictures(b), [4914])
        XCTAssertEqual(snds(b), [4804])
        XCTAssertEqual(b.requests, [.dialog(.credits)])
        XCTAssertEqual(flow.state, .credits)

        // More than 9 entries: snd 199 is absent from every fork (BC19) — silent; the crossing count restarts.
        let r = try resources()
        XCTAssertNil(r.resource(type: "snd ", id: 199, chain: .level))
        let g = make(r)
        var u: UInt32 = 0
        bootToMenu(g, &u)
        var cues: [Int16] = []
        for k in 0..<24 {
            let inside = k % 2 == 0
            cues += snds(g.tick(now: u, input: FrontInput(mouse: inside ? (500, 300) : (10, 300), button: true)))
            u &+= 1
        }
        XCTAssertEqual(cues, [Int16](repeating: 0, count: 24).enumerated().map { $0.offset % 2 == 0 ? 4803 : 4804 })
        _ = g.tick(now: u, input: FrontInput(mouse: (10, 300), button: false))
        XCTAssertEqual(g.state, .mainMenu)

        // The mouse New Game path runs `GammaFadeIn(6)` after `.NewGame` (F1b's); here `.NewGame` is the seam.
        let m = make(try resources())
        var v: UInt32 = 0
        bootToMenu(m, &v)
        _ = m.tick(now: v, input: FrontInput(mouse: (430, 270), button: true)); v &+= 1
        _ = m.tick(now: v, input: FrontInput(mouse: (430, 270), button: false))
        XCTAssertEqual(m.state, .newGame)
        XCTAssertEqual(m.defaultWorld, 1)
    }

    func testXCooldownAndCredits() throws {
        let flow = make(try resources())
        var t: UInt32 = 0
        bootToMenu(flow, &t)
        // X held: the joke, then none for 30 passes (cooldown 30, decremented at the end of every pass — the joke's
        // own pass included), then the joke again. The modal report holds its pass: the pass's end (the decrement)
        // runs on the tick after the answer, so tick 0 = pass 0, tick 1 = pass 0's end, tick k = pass k − 1.
        let x = FrontInput(keys: KeyState(pressed: [0x07]))
        var reportTicks: [Int] = []
        for tick in 0..<45 {
            let o = flow.tick(now: t, input: x); t &+= 1
            if o.requests.contains(where: { if case .dialog = $0 { return true }; return false }) {
                reportTicks.append(tick)
                XCTAssertEqual(o.requests, [.dialog(.report(text: MainMenu.comingSoon))])
                XCTAssertEqual(flow.tick(now: t, input: x), FrontOutput())   // unanswered: nothing moves
                flow.dialogDone(.ok)
            }
        }
        XCTAssertEqual(reportTicks, [0, 31])                          // passes 0 and 30
        XCTAssertEqual(MainMenu.comingSoon, "Coming soon: Ferazel's Destiny; Ferazel's Quest; Ferazel Fighter; "
                       + "Ferazel All-Stars; Go-Kart Ferazel; Ferazel Soccer 2000; Summer Olympics Ferazel...")

        // C: track 4 (10 ticks), then `.Credits`: PICT 4803 (144×811) moves up 1 px per 3 ticks from y 270 inside the
        // clip (l 34, t 120, r 170, b 270), wrapping after 961 steps.
        let t0 = t
        drive(flow, &t, max: 20, input: { $0 == t0 ? FrontInput(keys: KeyState(pressed: [0x08])) : FrontInput() }) {
            $0.state == .credits
        }
        let start = t &- 1
        XCTAssertEqual(Int(start &- t0), 10)
        let credits = try XCTUnwrap(flow.credits)
        XCTAssertEqual(credits.clip, Rect16(top: 120, left: 34, bottom: 270, right: 170))
        XCTAssertEqual(credits.offset(now: start), 0)
        XCTAssertEqual(credits.dest(now: start), Rect16(top: 270, left: 34, bottom: 270 + 811, right: 34 + 144))
        XCTAssertEqual(credits.offset(now: start &+ 2), 0)
        XCTAssertEqual(credits.offset(now: start &+ 3), 1)
        XCTAssertEqual(credits.offset(now: start &+ 300), 100)
        XCTAssertEqual(credits.dest(now: start &+ 300).top, 170)
        XCTAssertEqual(credits.offset(now: start &+ 3 * 960), 960)
        XCTAssertEqual(credits.offset(now: start &+ 3 * 961), 0)
        XCTAssertEqual(credits.click(insideDialog: false), .beep)
        XCTAssertEqual(credits.click(insideDialog: true), .close)
        // The flow waits on the dialog, then the menu loop resumes.
        XCTAssertEqual(flow.tick(now: t, input: FrontInput(keys: KeyState(pressed: [0x08]))), FrontOutput())
        t &+= 1
        flow.dialogDone(.ok)
        _ = flow.tick(now: t, input: FrontInput())
        XCTAssertEqual(flow.state, .mainMenu)
        XCTAssertNil(flow.credits)
    }
}
