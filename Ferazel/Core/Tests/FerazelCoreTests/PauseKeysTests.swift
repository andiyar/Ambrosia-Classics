import XCTest
@testable import FerazelCore

/// P1 (docs/plans/2026-10-14-ferazel-phase3.md): `.CheckGameLoopKeys @ 10007684` (M l. 3861–4030) — called by
/// `.GameLoop` after `.PaintFrameWrap` and before `.UpdateSprites` (M l. 5247–5274) — and `.Pause @ 10006078` (M l.
/// 3136–3270): the ⌘Q / ⌘W / Esc confirms, the nested `.PaintFrameWrap(1, 1)`, the Caps Lock pause (its banner, music,
/// menus and the 10 / 5 counter), and the gates (`*_DAT_1009fde8`, `DAT_100a53d6`). engine §7.2, save-continue §6
/// (BC15, BC26). Driven against the committed `Resources/Ferazel` (D26). A missing data file is a FAILURE, never a skip.
final class PauseKeysTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// The renderer side (Core tests: the session's default face bounds, no particle faces).
    private final class StubServices: LevelServices {
        func prepare(level: Int) throws -> LevelFaces { LevelFaces() }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {}
        func deathEffectStep(_ k: Int) throws {}
    }

    private static let command = 0x37, escape = 0x35, keyQ = 0x0c, keyW = 0x0d

    private struct Tick {
        let t: UInt32
        let out: FrontOutput
        let steps: [FrameOps]
        let iterations: Int
    }

    /// One level-1 run ticked one tick at a time; every tick kept.
    private final class Rig {
        let run: LevelRun
        var t: UInt32 = 1000
        var ticks: [Tick] = []

        init(_ r: FerazelResources, prefs: FerazelPrefs = FerazelPrefs(), lengths: [Int16: Int] = [:]) throws {
            run = try LevelRun(resources: r, prefs: prefs, level: 1, seed: 1, carry: LevelCarry(), save: SaveBlock(),
                               fade: ScreenFade(), music: MusicFade(), services: StubServices(),
                               sounds: StageSounds(prefs: prefs, lengths: lengths))
        }

        @discardableResult
        func tick(_ input: FrontInput = FrontInput()) throws -> Tick {
            let o = try run.tick(now: t, input: input)
            let k = Tick(t: t, out: o.merged, steps: run.lastSteps, iterations: run.iterations)
            ticks.append(k)
            t &+= 1
            return k
        }

        /// Ticks with `input` until `until` holds (checked after each tick).
        @discardableResult
        func drive(max: Int = 6000, input: (Rig) -> FrontInput = { _ in FrontInput() },
                   until: (Rig, Tick) -> Bool) throws -> Tick? {
            for _ in 0..<max {
                let k = try tick(input(self))
                if until(self, k) { return k }
            }
            XCTFail("the run did not reach the condition in \(max) ticks")
            return nil
        }

        /// `n` ticks with `input`.
        func idle(_ n: Int, input: FrontInput = FrontInput()) throws {
            for _ in 0..<n { try tick(input) }
        }

        /// Into the loop, past the entry's 41-iteration async fade-in (`DAT_100a53d6` set again), at a tick right after
        /// an iteration stepped (the next one steps two ticks later).
        func settle() throws {
            try drive { rig, k in
                guard let s = rig.run.session, !k.steps.isEmpty else { return false }
                return s.world.gammaFade.done && rig.run.iterations >= 60
            }
        }
    }

    private func dialogs(_ o: FrontOutput) -> [FerazelDialog] {
        o.requests.compactMap { if case .dialog(let d) = $0 { d } else { nil } }
    }

    private func isCopy(_ op: DrawOp) -> Bool { if case .copyToScreen = op { true } else { false } }
    private func isErase(_ op: DrawOp) -> Bool { if case .wrapEraseSprites = op { true } else { false } }
    private func isStatus(_ op: DrawOp) -> Bool { if case .statusBar = op { true } else { false } }
    private func isGrid(_ op: DrawOp) -> Bool { if case .redrawEntireScrollGrid = op { true } else { false } }
    private func isPaint(_ op: DrawOp) -> Bool { if case .redrawScrollGrid = op { true } else { false } }

    private static func prefs(graphics: Int16) -> FerazelPrefs {
        var p = FerazelPrefs()
        p.graphics = graphics
        return p
    }

    // MARK: - The pause counter

    /// `.Pause`'s loop on its own (the map form: no level CLUT, no level redraw; no music loaded, so no fades block):
    /// the counter starts at 10, −1 per poll while Caps Lock is up and the app active, else back to 5; unpause at 0.
    func testPauseCounter() throws {
        let r = try resources()
        func pause() -> PauseRun {
            var p = PauseRun(resources: r, onMap: true, prefs: FerazelPrefs(), music: MusicFade(), levelClut: nil,
                             scroll: nil, files: nil)
            _ = p.enter()
            _ = p.painted(now: 0)
            return p
        }
        /// The entry test at tick 0, then one poll per tick: the counter after each poll, until unpaused.
        func run(entry: Bool, polls: [(caps: Bool, active: Bool)]) -> (counters: [Int16], unpausedAt: Int?) {
            var p = pause()
            _ = p.tick(now: 0, input: FrontInput(capsLock: entry))
            if !p.paused { return ([], 0) }
            var counters: [Int16] = []
            for (i, poll) in polls.enumerated() {
                _ = p.tick(now: UInt32(i + 1), input: FrontInput(capsLock: poll.caps, active: poll.active))
                counters.append(p.counter)
                XCTAssertEqual(p.polls, i + 1)
                if !p.paused { return (counters, i + 1) }
            }
            return (counters, nil)
        }

        // Caps Lock down for k polls, then up: 5 a poll while down, then 4 … 0 — unpaused on the 5th up poll.
        for k in [1, 3, 7] {
            let down = Array(repeating: (caps: true, active: true), count: k)
            let up = Array(repeating: (caps: false, active: true), count: 20)
            let (c, at) = run(entry: true, polls: down + up)
            XCTAssertEqual(at, k + 5, "k = \(k)")
            XCTAssertEqual(c, Array(repeating: 5, count: k) + [4, 3, 2, 1, 0], "k = \(k)")
        }
        // Up on entry: `CapsLockDown()` false → the flag cleared at once, no poll (and the exit made at once: no music).
        var p0 = pause()
        let o0 = p0.tick(now: 0, input: FrontInput())
        XCTAssertFalse(p0.paused)
        XCTAssertEqual(p0.polls, 0)
        XCTAssertTrue(p0.isDone)
        XCTAssertTrue(o0.requests.contains(.hideMenuBar))
        // Released before the first poll: the counter runs down from 10 — unpaused on the 10th poll.
        let (c10, at10) = run(entry: true, polls: Array(repeating: (caps: false, active: true), count: 20))
        XCTAssertEqual(at10, 10)
        XCTAssertEqual(c10, [9, 8, 7, 6, 5, 4, 3, 2, 1, 0])
        // The app inactive (`DAT_100a5108` 0): the counter held at 5, whatever Caps Lock does; active again → 5 polls.
        let inactive = Array(repeating: (caps: false, active: false), count: 6)
        let (ci, ati) = run(entry: true, polls: inactive + Array(repeating: (caps: false, active: true), count: 20))
        XCTAssertEqual(ati, 11)
        XCTAssertEqual(ci, Array(repeating: 5, count: 6) + [4, 3, 2, 1, 0])

        // File ▸ Abort Game while paused (`.AbortGame`, M l. 6240ff): the confirm; OK → the pause flag cleared and
        // `DAT_100a5106` set; the pause ends at that poll.
        var pa = pause()
        _ = pa.tick(now: 0, input: FrontInput(capsLock: true))
        pa.menuChosen(.abortGame)
        let ask = pa.tick(now: 1, input: FrontInput(capsLock: true))
        XCTAssertEqual(dialogs(ask), [.confirm(text: GameLoopKeys.abortText)])
        XCTAssertTrue(ask.requests.contains(.showCursor))
        XCTAssertTrue(pa.paused)
        _ = pa.tick(now: 2, input: FrontInput(capsLock: true))
        XCTAssertTrue(pa.paused, "the confirm is modal")
        pa.dialogDone(ok: true)
        _ = pa.tick(now: 3, input: FrontInput(capsLock: true))
        XCTAssertFalse(pa.paused)
        XCTAssertTrue(pa.aborted)
        XCTAssertTrue(pa.isDone)

        // A1a: a poll's `.CheckEvent` takes one queued Apple event, oldest first (M l. 3218). An open is taken and does
        // nothing (`.DoOpenDocAE` with `5106` clear, M l. 31221–31225): the poll goes on as any other. The quit →
        // `.Quit` from inside the loop: counted as a poll, the pause stops there — still paused, no exit sequence.
        var pq = pause()
        _ = pq.tick(now: 0, input: FrontInput(capsLock: true))
        let ref = SavedGameRef(url: URL(fileURLWithPath: "/nonexistent/finder"), displayName: "finder")
        pq.appleEvents = PendingAppleEvents([.open(ref), .quit])
        _ = pq.tick(now: 1, input: FrontInput(capsLock: true))
        XCTAssertEqual(pq.appleEvents.events, [.quit])
        XCTAssertEqual(pq.polls, 1)
        XCTAssertEqual(pq.counter, 5)
        XCTAssertFalse(pq.quitDispatched)
        XCTAssertFalse(pq.isDone)
        let qo = pq.tick(now: 2, input: FrontInput(capsLock: false))
        XCTAssertTrue(pq.appleEvents.isEmpty)
        XCTAssertTrue(pq.quitDispatched)
        XCTAssertEqual(pq.polls, 2)
        XCTAssertEqual(pq.counter, 5, "no counter step on the quit")
        XCTAssertTrue(pq.paused)
        XCTAssertTrue(pq.isDone)
        XCTAssertFalse(qo.requests.contains(.hideMenuBar), "no pause exit")

        // A1b: MBAR 128's other picks while paused (`.HandleMenuSelection`, M l. 28795ff). New Game / Restore Game are
        // disabled (`.UpdateMenus` paused): ignored, the poll as any other.
        let caps = FrontInput(capsLock: true)
        var pm = pause()
        XCTAssertFalse(pm.acceptsMenus, "before the loop runs")
        _ = pm.tick(now: 0, input: caps)
        XCTAssertTrue(pm.acceptsMenus)
        pm.menuChosen(.newGame)
        pm.menuChosen(.restoreGame)
        XCTAssertTrue(pm.acceptsMenus)
        XCTAssertEqual(dialogs(pm.tick(now: 1, input: caps)), [])
        XCTAssertEqual(pm.polls, 1)
        // Apple ▸ About → `.Credits`: DLOG 600, modal (no poll, no counter step), its scroll from that tick.
        pm.menuChosen(.about)
        XCTAssertFalse(pm.acceptsMenus)
        let about = pm.tick(now: 2, input: caps)
        XCTAssertEqual(dialogs(about), [.credits])
        XCTAssertEqual(pm.credits?.start, 2)
        XCTAssertEqual(pm.credits?.stripHeight, 811)
        _ = pm.tick(now: 3, input: FrontInput())
        XCTAssertEqual(pm.polls, 1)
        XCTAssertEqual(pm.counter, 5)
        pm.dialogDone(ok: true)
        _ = pm.tick(now: 4, input: caps)
        XCTAssertNil(pm.credits)
        XCTAssertEqual(pm.polls, 2)
        XCTAssertTrue(pm.paused)
        XCTAssertTrue(pm.acceptsMenus)
        // Game ▸ Preferences… → `.Options` with the pause flag set: the record re-read, O1's model (paused, the host's
        // last modifier), OK written back, `.MakeCurrPrefs` (paused: no music restart), `.UpdateMenus`.
        pm.lastModifier = 0x38
        pm.menuChosen(.preferences)
        let opts = pm.tick(now: 5, input: caps)
        XCTAssertEqual(opts.requests, [.showCursor, .dialog(.preferences)])
        var model = try XCTUnwrap(pm.prefsDialog)
        XCTAssertTrue(model.paused)
        XCTAssertEqual(model.lastModifier, 0x38)
        model.hit(3, value: 3)
        XCTAssertEqual(model.hit(8), [], "paused: no volume cue (no music loaded: no stop)")
        model.hit(1)
        pm.prefsDialog = model
        pm.dialogDone(ok: true)
        let closed = pm.tick(now: 6, input: caps)
        XCTAssertNil(pm.prefsDialog)
        XCTAssertEqual(pm.live.live.musicOn, 0)
        XCTAssertEqual(closed.prefs?.musicOn, 0)
        XCTAssertTrue(closed.present)
        XCTAssertEqual(closed.music, [])
        XCTAssertTrue(closed.requests.contains(.showMenuBarItems(MenuState(menusLive: true, paused: true,
                                                                             musicOn: false, soundOn: true))))
        XCTAssertEqual(pm.lastModifier, 0x38)
        XCTAssertEqual(pm.polls, 3)
        XCTAssertTrue(pm.paused)
        // File ▸ Quit → `.Quit` (no confirm), as the quit event: the pause stops there, no exit sequence.
        pm.menuChosen(.quit)
        let quit = pm.tick(now: 7, input: FrontInput())
        XCTAssertTrue(pm.quitDispatched)
        XCTAssertTrue(pm.isDone)
        XCTAssertFalse(pm.acceptsMenus)
        XCTAssertFalse(quit.requests.contains(.hideMenuBar), "no pause exit")
        XCTAssertEqual(pm.polls, 4, "the Quit pick's poll")

        // Preferences… with music loaded and the prefs file: the record written back on every close; the model's live
        // side taken back (Music off in the dialog shut the movie down at once); `.MakeCurrPrefs` paused — Music on
        // again in the dialog restarts nothing.
        final class Prefs: FrontFiles {
            var stored: [Data] = []
            func loadPrefs() -> Data? { stored.last }
            func storePrefs(_ record: Data) throws { stored.append(record) }
            func readSavedGame(_ ref: SavedGameRef) throws -> SaveBlock { SaveBlock() }
            func writeSavedGame(_ block: SaveBlock, to ref: SavedGameRef) throws(SaveWriteError) {}
        }
        let files = Prefs()
        var music = MusicFade()
        _ = music.setAIFFMusic(5)
        var pl = PauseRun(resources: r, onMap: true, prefs: FerazelPrefs(), music: music, levelClut: nil, scroll: nil,
                          files: files)
        _ = pl.enter()
        _ = pl.painted(now: 0)
        var now: UInt32 = 0
        while !pl.acceptsMenus, now < 100 { _ = pl.tick(now: now, input: caps); now += 1 }
        XCTAssertTrue(pl.acceptsMenus)
        func preferences(_ body: (inout PrefsDialogModel) -> Void) throws -> FrontOutput {
            pl.menuChosen(.preferences)
            _ = pl.tick(now: now, input: caps)
            now += 1
            var model = try XCTUnwrap(pl.prefsDialog)
            body(&model)
            pl.prefsDialog = model
            pl.dialogDone(ok: true)
            let o = pl.tick(now: now, input: caps)
            now += 1
            XCTAssertNil(pl.prefsDialog)
            return o
        }
        let off = try preferences { m in
            m.hit(3, value: 3)
            XCTAssertEqual(m.hit(8), [.stop])
            m.hit(1)
        }
        XCTAssertEqual(files.stored.count, 1)
        XCTAssertEqual(files.stored.last.map(FerazelPrefs.init(record:))?.musicOn, 0)
        XCTAssertFalse(pl.live.music.loaded)
        XCTAssertEqual(off.music, [])
        let on = try preferences { m in
            m.hit(3, value: 3)
            m.hit(8)
            m.hit(1)
        }
        XCTAssertEqual(files.stored.count, 2)
        XCTAssertEqual(pl.live.live.musicOn, 1)
        XCTAssertEqual(on.music, [], "paused: the music is not restarted")
        // A cleared model while the dialog is up is ignored (the close needs it): the pause cannot stall.
        pl.menuChosen(.preferences)
        _ = pl.tick(now: now, input: caps)
        now += 1
        pl.prefsDialog = nil
        XCTAssertNotNil(pl.prefsDialog)
        pl.dialogDone(ok: false)
        _ = pl.tick(now: now, input: caps)
        XCTAssertNil(pl.prefsDialog)
        XCTAssertEqual(files.stored.count, 3)
        XCTAssertTrue(pl.acceptsMenus)
    }

    // MARK: - Pause entry and exit

    func testPauseEntryAndExit() throws {
        let r = try resources()
        let rig = try Rig(r)
        rig.run.lastModifier = 0x3a
        try rig.settle()
        let s = try XCTUnwrap(rig.run.session)
        let prefs = FerazelPrefs()
        let V = MusicFade.fullVolume(prefs)
        let levelClut = ColorLUT.screenClutId(rig.run.levelFile.header)
        let iterationsBefore = rig.run.iterations

        // Caps Lock down: the next iteration's `.CheckGameLoopKeys` pauses.
        let entry = try XCTUnwrap(try rig.drive(max: 10, input: { _ in FrontInput(capsLock: true) }) { rig, _ in
            rig.run.pause != nil
        })
        XCTAssertEqual(rig.run.iterations, iterationsBefore + 1, "the pause sits inside one iteration")
        let o = entry.out
        // snd 198 (`STPlayRegSound(uRam100ab9bc = 0xc6, 100, 0x100)`, M l. 3175 / 350).
        XCTAssertEqual(o.sounds.last, SoundCues.regSound(snd: 198, priority: 100, volume: 0x100,
                                                         global: SoundCues.globalVolume(prefs)))
        // The level CLUT, then `.PaintFrameWrap(1, 0)` (a whole drawn pass: copy and erase), then PICT 4921 into
        // (207, 152)–(432, 248) offset by the sprite world's (+0x48, +0x46) = (0, 0).
        let clut = try XCTUnwrap(o.draws.lastIndex(of: .setScreenClut(id: levelClut)))
        let copy = try XCTUnwrap(o.draws.lastIndex(where: isCopy))
        let banner = try XCTUnwrap(o.draws.firstIndex { op in
            if case .copyPicture(4921, .frontEnd, _, let dest, nil, false) = op {
                return dest == Rect16(top: 152, left: 207, bottom: 248, right: 432)
            }
            return false
        })
        XCTAssertLessThan(clut, copy)
        XCTAssertLessThan(copy, banner)
        XCTAssertTrue(o.draws[copy..<banner].contains(where: isErase))
        // Voices 452 and 511 stopped; `FadeAIFFMusic(0, 1)`: V·(24 − s)/24 one tick apart, then 0.
        XCTAssertEqual(Array(o.soundStops.suffix(2)), [452, 511])
        let e = entry.t
        let menus = try XCTUnwrap(try rig.drive(max: 40, input: { _ in FrontInput(capsLock: true) }) { _, k in
            k.out.requests.contains(.showMenuBar)
        })
        let out = rig.ticks.filter { $0.t >= e }.flatMap { k in k.out.music.map { (t: k.t, cue: $0) } }
        XCTAssertEqual(out.map { $0.t }, (0...24).map { e + UInt32($0) })
        XCTAssertEqual(out.map { $0.cue }, (0..<24).map { MusicCue.volume(V * (24 - $0) / 24) } + [.volume(0)])
        XCTAssertEqual(menus.t, e + 24)
        XCTAssertTrue(menus.out.requests.contains(.showMenuBarItems(MenuState(menusLive: true, paused: true,
                                                                               musicOn: true, soundOn: true))))
        XCTAssertTrue(try XCTUnwrap(rig.run.pause).paused)
        // A1b: Game ▸ Preferences… while paused — the pause's `.Options` (paused) through `pausePrefsDialog`, with the
        // run's last captured modifier, which comes back when the pause ends.
        rig.run.menuChosen(.preferences)
        XCTAssertEqual(dialogs(try rig.tick(FrontInput(capsLock: true)).out), [.preferences])
        var pd = try XCTUnwrap(rig.run.pausePrefsDialog)
        XCTAssertTrue(pd.paused)
        XCTAssertEqual(pd.lastModifier, 0x3a)
        _ = pd.idle(modifiers: 0)
        pd.hit(2)
        rig.run.pausePrefsDialog = pd
        rig.run.dialogDone(.cancel)
        try rig.tick(FrontInput(capsLock: true))
        XCTAssertNil(rig.run.pausePrefsDialog)
        XCTAssertTrue(try XCTUnwrap(rig.run.pause).paused)
        XCTAssertEqual(rig.run.lastModifier, 0x3a, "taken back only when the pause ends")

        // Held 10 more polls (no iteration runs), then released: unpaused on the 5th up poll; `FadeAIFFMusic(1, 2)`.
        try rig.idle(10, input: FrontInput(capsLock: true))
        XCTAssertEqual(rig.ticks.suffix(10).flatMap { $0.steps }, [])
        let release = rig.t
        let unpause = try XCTUnwrap(try rig.drive(max: 10) { rig, _ in rig.run.pause?.paused == false })
        XCTAssertEqual(unpause.t, release + 4)
        let end = try XCTUnwrap(try rig.drive(max: 60) { rig, _ in rig.run.pause == nil })
        let back = rig.ticks.filter { $0.t >= unpause.t }.flatMap { k in k.out.music.map { (t: k.t, cue: $0) } }
        XCTAssertEqual(back.map { $0.t }, (0...24).map { unpause.t + UInt32(2 * $0) })
        XCTAssertEqual(back.map { $0.cue }, (0..<24).map { MusicCue.volume(V * $0 / 24) } + [.volume(V)])
        XCTAssertEqual(end.t, unpause.t + 48)
        XCTAssertEqual(rig.run.lastModifier, 0)
        // The exit's tail: the menu bar hidden, `RedrawEntireScrollGrid` + `RedrawGameArea`, the cursor hidden — then
        // the same iteration finishes (status bar) and the run steps on.
        let tail = end.out
        XCTAssertTrue(tail.requests.contains(.hideMenuBar))
        XCTAssertTrue(tail.requests.contains(.hideCursor))
        let grid = try XCTUnwrap(tail.draws.firstIndex(of: .redrawEntireScrollGrid(h: s.camera.scrollH,
                                                                                   v: s.camera.scrollV)))
        XCTAssertTrue(isCopy(tail.draws[grid + 1]), "graphics 1: no `DrawBlackLines`")
        XCTAssertFalse(rig.ticks.filter { $0.t >= e }.flatMap { $0.out.draws }.contains(.drawBlackLines))
        XCTAssertTrue(tail.draws[(grid + 2)...].contains(where: isStatus))
        XCTAssertEqual(rig.run.iterations, iterationsBefore + 1)
        XCTAssertEqual(end.steps.last?.suspension, nil)
        XCTAssertEqual(s.pauseDebounce, 0)
        try rig.drive(max: 4) { rig, _ in rig.run.iterations == iterationsBefore + 2 }

        // Graphics mode 3, File ▸ Abort Game while paused: the confirm, OK → unpaused (`DAT_100a5106`); the exit as
        // ever — `.RedrawGameArea` now `DrawBlackLines` + the line-skipped copy — then the level ends `.aborted`.
        let ab = try Rig(r, prefs: Self.prefs(graphics: 3))
        try ab.settle()
        try ab.drive(max: 60, input: { _ in FrontInput(capsLock: true) }) { _, k in
            k.out.requests.contains(.showMenuBar)
        }
        ab.run.menuChosen(.abortGame)
        let confirm = try ab.tick(FrontInput(capsLock: true))
        XCTAssertEqual(dialogs(confirm.out), [.confirm(text: GameLoopKeys.abortText)])
        try ab.idle(3, input: FrontInput(capsLock: true))
        XCTAssertEqual(ab.run.pause?.paused, true, "the confirm is modal")
        ab.run.dialogDone(.ok)
        try ab.tick(FrontInput(capsLock: true))
        XCTAssertEqual(ab.run.pause?.paused, false)
        XCTAssertEqual(ab.run.pause?.aborted, true)
        let abEnd = try XCTUnwrap(try ab.drive(max: 60, input: { _ in FrontInput(capsLock: true) }) { rig, _ in
            rig.run.pause == nil
        })
        let abs = try XCTUnwrap(ab.run.session)
        let abGrid = try XCTUnwrap(abEnd.out.draws.firstIndex(of: .redrawEntireScrollGrid(h: abs.camera.scrollH,
                                                                                         v: abs.camera.scrollV)))
        XCTAssertEqual(abEnd.out.draws[abGrid + 1], .drawBlackLines)
        XCTAssertTrue(isCopy(abEnd.out.draws[abGrid + 2]))
        XCTAssertTrue(abs.loopAborted)
        try ab.drive(max: 20, input: { _ in FrontInput(capsLock: true) }) { rig, _ in rig.run.end != nil }
        XCTAssertEqual(ab.run.end, .aborted)

        // From the map (`fe2c = 1`): no level CLUT, no `.PaintFrameWrap`, no level redraw; the work port copied back
        // over the banner after.
        let g = GameGlobals.initGameGlobals(previous: nil)
        var fade = ScreenFade()
        fade.faded = true
        let name = try LevelFile.load(from: r, level: 1).header.name
        let map = try WorldMapRun(resources: r, prefs: prefs, globals: g, level: 1, levelName: name, exit1: 0,
                                  exit2: -1, levelComplete: true, seed: 1, fade: fade, music: MusicFade())
        var mt: UInt32 = 5000
        var mapOps: [[MapOp]] = []
        var mapOuts: [FrontOutput] = []
        func mapTick(_ input: FrontInput) {
            let o = map.tick(now: mt, input: input)
            mapOps.append(o.ops)
            mapOuts.append(o.output)
            mt &+= 1
        }
        for _ in 0..<600 where !(map.onMap && map.walkStep == 0 && map.iterations > 40) { mapTick(FrontInput()) }
        XCTAssertTrue(map.onMap)
        let mark = mapOps.count
        for _ in 0..<4 { mapTick(FrontInput(capsLock: true)) }
        XCTAssertNotNil(map.pause)
        for _ in 0..<200 where map.pause != nil { mapTick(FrontInput()) }
        XCTAssertNil(map.pause)
        let during = mapOps[mark...].flatMap { $0 }
        XCTAssertTrue(mapOuts[mark...].flatMap { $0.sounds }.map { $0.snd }.contains(198))
        XCTAssertFalse(during.contains { if case .draw(.setScreenClut, _) = $0 { true } else { false } })
        XCTAssertFalse(during.contains { if case .draw(.redrawEntireScrollGrid, _) = $0 { true } else { false } })
        XCTAssertFalse(during.contains { if case .draw(.copyToScreen, _) = $0 { true } else { false } })
        let mb = try XCTUnwrap(during.firstIndex { op in
            if case .draw(.copyPicture(4921, _, _, let d, _, _), .screen) = op {
                return d == Rect16(top: 152, left: 207, bottom: 248, right: 432)
            }
            return false
        })
        XCTAssertTrue(during[mb...].contains(.copy(from: .work, to: .screen, source: WorldMapRun.viewRect,
                                                   dest: WorldMapRun.toScreen(WorldMapRun.viewRect))))
        XCTAssertFalse(map.loopEndRequested)

        // On the map, Abort Game's OK while paused sets `DAT_100a5106` — the flow's loop ends after the map.
        let map2 = try WorldMapRun(resources: r, prefs: prefs, globals: g, level: 1, levelName: name, exit1: 0,
                                   exit2: -1, levelComplete: true, seed: 1, fade: fade, music: MusicFade())
        var t2: UInt32 = 9000
        func tick2(_ input: FrontInput) -> WorldMapOutput {
            defer { t2 &+= 1 }
            return map2.tick(now: t2, input: input)
        }
        for _ in 0..<600 where !(map2.onMap && map2.walkStep == 0 && map2.iterations > 40) { _ = tick2(FrontInput()) }
        for _ in 0..<60 where !(map2.pause?.polls ?? 0 > 0) { _ = tick2(FrontInput(capsLock: true)) }
        XCTAssertEqual(map2.pause?.paused, true)
        map2.menuChosen(.abortGame)
        let ask2 = tick2(FrontInput(capsLock: true))
        XCTAssertEqual(dialogs(ask2.output), [.confirm(text: GameLoopKeys.abortText)])
        map2.dialogDone(ok: true)
        for _ in 0..<200 where map2.pause != nil { _ = tick2(FrontInput(capsLock: true)) }
        XCTAssertNil(map2.pause)
        XCTAssertTrue(map2.loopEndRequested)
        XCTAssertFalse(map2.aborted, "the map's own abort (`fd4c`) is not set")
    }

    // MARK: - Esc / ⌘W: abort

    func testEscAbortEndsLevelWithoutFades() throws {
        let r = try resources()
        for (keys, graphics) in [([Self.escape], Int16(1)), ([Self.command, Self.keyW], 1), ([Self.escape], 3),
                                 ([Self.command, Self.keyW], 3)] {
            let rig = try Rig(r, prefs: Self.prefs(graphics: graphics))
            try rig.settle()
            let musicBefore = rig.ticks.flatMap { $0.out.music }.count
            let ask = try XCTUnwrap(try rig.drive(max: 4, input: { _ in FrontInput(keys: KeyState(pressed: keys)) }) {
                _, k in !self.dialogs(k.out).isEmpty
            })
            XCTAssertEqual(dialogs(ask.out), [.confirm(text: GameLoopKeys.abortText)], "\(keys)")
            XCTAssertTrue(ask.out.requests.contains(.showCursor))
            XCTAssertNotNil(ask.steps.last?.suspension)
            // `.RestoreWindowBackground`: `DrawBlackLines` in graphics mode 3 only, right after the frame's erase.
            let asked = try XCTUnwrap(ask.steps.last).draws
            XCTAssertEqual(asked.last == .drawBlackLines, graphics == 3, "\(keys) mode \(graphics)")
            XCTAssertEqual(asked.filter { $0 == .drawBlackLines }.count, graphics == 3 ? 1 : 0)
            let iterations = rig.run.iterations
            try rig.idle(5)
            XCTAssertEqual(rig.run.iterations, iterations, "the confirm is modal: no iteration runs")
            rig.run.dialogDone(.ok)
            let ok = try rig.tick()
            // `.PaintFrameWrap(1, 1)` (a whole drawn pass), then `.UpdateStatusBar(0, 0, 0)`.
            let d = ok.out.draws
            let copy = try XCTUnwrap(d.firstIndex(where: isCopy))
            let erase = try XCTUnwrap(d.firstIndex(where: isErase))
            XCTAssertLessThan(copy, erase)
            XCTAssertTrue(d[erase...].contains(where: isStatus))
            // OK: `.PaintFrameWrap(1, 1)`, `DrawBlackLines` (mode 3), `.UpdateStatusBar(0, 0, 0)`.
            let rest = try XCTUnwrap(ok.steps.first).draws
            let okErase = try XCTUnwrap(rest.firstIndex(where: isErase))
            if graphics == 3 {
                XCTAssertEqual(rest[okErase + 1], .drawBlackLines)
                XCTAssertTrue(isStatus(rest[okErase + 2]))
            } else {
                XCTAssertFalse(rest.contains(.drawBlackLines))
                XCTAssertTrue(isStatus(rest[okErase + 1]))
            }
            XCTAssertEqual(rig.run.iterations, iterations, "the same iteration ends")
            let end = try XCTUnwrap(try rig.drive(max: 20) { rig, _ in rig.run.end != nil })
            XCTAssertEqual(rig.run.end, .aborted)
            let after = rig.ticks.flatMap { $0.out.music }.dropFirst(musicBefore)
            // No `FadeAIFFMusic(0, 2)`, no `GammaFadeOut(6)`: the music cut by the exit's `ShutDownAIFFMusic` only.
            XCTAssertEqual(Array(after), [.stop], "\(keys)")
            XCTAssertFalse(rig.ticks.filter { $0.t >= ask.t }.flatMap { $0.out.draws }.contains {
                if case .screenGamma = $0 { true } else { false }
            })
            // The loop's end stops 452 and 511 (`*fe24`, `*fe20`, M l. 5297–5300) after the iteration's own.
            XCTAssertEqual(rig.ticks.filter { $0.t >= ok.t }.flatMap { $0.out.soundStops }.suffix(2), [452, 511])
            XCTAssertTrue(end.out.requests.contains(.showCursor))
        }

        // Esc's Cancel: `.RedrawEntireScrollGrid`, `DrawBlackLines` (mode 3), `.PaintFrameWrap(1, 1)` — a whole drawn
        // pass — `.UpdateStatusBar(0, 0, 0)`; then the iteration ends and the run goes on (⌘W's Cancel has no pass).
        for (keys, graphics) in [([Self.escape], Int16(3)), ([Self.escape], 1), ([Self.command, Self.keyW], 3)] {
            let rig = try Rig(r, prefs: Self.prefs(graphics: graphics))
            try rig.settle()
            let iterations = rig.run.iterations
            try rig.drive(max: 4, input: { _ in FrontInput(keys: KeyState(pressed: keys)) }) { _, k in
                !self.dialogs(k.out).isEmpty
            }
            let s = try XCTUnwrap(rig.run.session)
            let parity = s.world.parity
            rig.run.dialogDone(.cancel)
            let cancel = try rig.tick()
            let rest = try XCTUnwrap(cancel.steps.first).draws
            XCTAssertNil(cancel.steps.last?.suspension)
            XCTAssertEqual(rest.first, .redrawEntireScrollGrid(h: s.camera.scrollH, v: s.camera.scrollV))
            XCTAssertEqual(rest[1] == .drawBlackLines, graphics == 3)
            let escape = keys == [Self.escape]
            XCTAssertEqual(rest.contains(where: isCopy), escape, "\(keys): the pass")
            XCTAssertEqual(rest.contains(where: isErase), escape)
            XCTAssertEqual(rest.contains(where: isPaint), escape)
            // The nested drawn pass flips the parity `_DAT_1009fd30` once.
            XCTAssertEqual(s.world.parity != parity, escape)
            if escape {
                let erase = try XCTUnwrap(rest.firstIndex(where: isErase))
                XCTAssertTrue(isStatus(rest[erase + 1]))
            }
            XCTAssertEqual(rig.run.iterations, iterations + 1)
            try rig.drive(max: 4) { rig, _ in rig.run.iterations == iterations + 2 }
            XCTAssertNil(rig.run.end)
        }
    }

    // MARK: - ⌘Q

    func testCommandQConfirmQuits() throws {
        let r = try resources()
        // OK → `.PaintFrameWrap(1, 1)`, `.UpdateStatusBar`, `.Quit` (never returns): the run ends `.quit` at once.
        let rig = try Rig(r)
        try rig.settle()
        let ask = try XCTUnwrap(try rig.drive(max: 4, input: { _ in
            FrontInput(keys: KeyState(pressed: [Self.command, Self.keyQ]))
        }) { _, k in !self.dialogs(k.out).isEmpty })
        XCTAssertEqual(dialogs(ask.out), [.confirm(text: GameLoopKeys.quitText)])
        rig.run.dialogDone(.ok)
        let ok = try rig.tick()
        XCTAssertEqual(rig.run.end, .quit)
        let copy = try XCTUnwrap(ok.out.draws.firstIndex(where: isCopy))
        XCTAssertTrue(ok.out.draws[copy...].contains(where: isStatus))
        XCTAssertEqual(ok.out.music, [], "no exit sequence: `.Quit` is the flow's")

        // Cancel → `RedrawEntireScrollGrid`, `.UpdateStatusBar(0, 0, 0)` (no `.PaintFrameWrap`), then the same frame
        // goes on: its parts equal a twin's uninterrupted frame with those two draws between them.
        let a = try Rig(r), b = try Rig(r)
        try a.settle()
        try b.settle()
        // CS: ⌘ is USE — held with the Fireball selected it casts (the twin does not); the dagger would stab once the
        // item switch lands. An empty slot does not hold: row 25's repair (M l. 45056–45063) moves it back to slot 0
        // before the next frame. Both run with a Locket (item 7: no spell, no arm in `.HandleKeys`' item switch,
        // M l. 47551–47606) in slot 2, selected, so the held ⌘ casts nothing and uses nothing. IU (seat ruling): the
        // item gate zeroes the idle and fidget counters while ⌘ is held (M l. 47544–47545), so the twin holds ⌘ alone
        // on that frame (no ⌘-key branch) and the two players stay equal.
        for rig in [a, b] {
            rig.run.session?.world.globals.inventory[2] = InventorySlot(id: 7, count: 1, field4: -1, field6: 0,
                                                                        isSpell: 0)
            rig.run.session?.world.globals.selectedSlot = 2
        }
        XCTAssertEqual(a.t, b.t)
        let iterations = a.run.iterations
        let qa = try a.drive(max: 4, input: { _ in FrontInput(keys: KeyState(pressed: [Self.command, Self.keyQ])) }) {
            rig, _ in rig.run.iterations > iterations
        }
        let qb = try b.drive(max: 4, input: { _ in FrontInput(keys: KeyState(pressed: [Self.command])) }) {
            rig, _ in rig.run.iterations > iterations
        }
        let first = try XCTUnwrap(qa?.steps.last)
        let whole = try XCTUnwrap(qb?.steps.last)
        XCTAssertEqual(first.suspension, .gameLoopKeys(.confirmQuit))
        a.run.dialogDone(.cancel)
        let cancel = try a.tick()
        try b.tick()
        let rest = try XCTUnwrap(cancel.steps.last)
        XCTAssertNil(rest.suspension)
        XCTAssertFalse(rest.draws.contains(where: isCopy), "no `.PaintFrameWrap` on ⌘Q's Cancel")
        let s = try XCTUnwrap(a.run.session)
        let inserted: [DrawOp] = [.redrawEntireScrollGrid(h: s.camera.scrollH, v: s.camera.scrollV),
                                  .statusBar(s.globals.statusBar(levelName: s.level.header.name))]
        XCTAssertEqual(Array(rest.draws.prefix(2)), inserted)
        XCTAssertEqual(first.draws + rest.draws.dropFirst(2), whole.draws)
        XCTAssertEqual(first.sounds + rest.sounds, whole.sounds)
        XCTAssertEqual(rest.drawn, whole.drawn)
        XCTAssertEqual(a.run.iterations, iterations + 1)
        // `.UpdateSprites` and the rest of the iteration ran: both runs go on in step.
        try a.idle(6)
        try b.idle(6)
        XCTAssertEqual(a.run.iterations, b.run.iterations)
        XCTAssertEqual(a.run.session?.player, b.run.session?.player)
        XCTAssertEqual(a.ticks.last?.steps, b.ticks.last?.steps)

        // ⌘P: `.Options` over the re-read record; OK with graphics 3 → `.MakeCurrPrefs`: the run's and the session's
        // live prefs, the output's `prefs`; the tail `.SetScrollLocation`, `.RedrawEntireScrollGrid`, the status bar and
        // — the new mode being 3 — `DrawBlackLines`; the next copies line-skip.
        let stageLengths: [Int16: Int] = [800: 30, 801: 40, 802: 50, 803: 5, 804: 7, 805: 20]
        let o = try Rig(r, lengths: stageLengths)
        try o.settle()
        let opt = try XCTUnwrap(try o.drive(max: 4, input: { _ in
            FrontInput(keys: KeyState(pressed: [Self.command, 0x23]))
        }) { _, k in !self.dialogs(k.out).isEmpty })
        XCTAssertEqual(dialogs(opt.out), [.preferences])
        XCTAssertEqual(opt.steps.last?.suspension, FrameSuspension.gameLoopKeys(.options))
        XCTAssertNotNil(o.run.prefsDialog)
        o.run.prefsDialog?.working.graphics = 3
        o.run.prefsDialog?.working.soundOn = 0
        _ = o.run.prefsDialog?.hit(1)
        o.run.dialogDone(.ok)
        let closed = try o.tick()
        let os = try XCTUnwrap(o.run.session)
        XCTAssertNil(o.run.prefsDialog)
        XCTAssertEqual(o.run.prefs.graphics, 3)
        XCTAssertEqual(os.prefs.graphics, 3)
        XCTAssertEqual(o.run.livePrefs.graphics, 3)
        XCTAssertEqual(closed.out.prefs?.graphics, 3)
        let tail = try XCTUnwrap(closed.steps.first).draws
        XCTAssertEqual(Array(tail.prefix(4)), [.redrawScrollGrid(h: os.camera.scrollH, v: os.camera.scrollV),
                                               .redrawEntireScrollGrid(h: os.camera.scrollH, v: os.camera.scrollV),
                                               .statusBar(os.globals.statusBar(levelName: os.level.header.name)),
                                               .drawBlackLines])
        let next = try XCTUnwrap(try o.drive(max: 4) { _, k in k.steps.contains { $0.draws.contains(where: self.isCopy) } })
        XCTAssertTrue(next.steps.flatMap { $0.draws }.contains {
            if case .copyToScreen(_, _, 3, _) = $0 { true } else { false }
        })
        // The stage-complete panel's `.STPlayRegSound`s read the live prefs+0x0b: sound now off → none (a run with
        // sound on plays snd 805 there, `LevelRunTests.testCompleteExitSequence`).
        XCTAssertEqual(os.prefs.soundOn, 0)
        try touchExit(os, record: 66)
        let doneAt = o.t
        try o.drive(max: 400) { rig, _ in rig.run.end != nil }
        XCTAssertEqual(o.run.end, .completed(exit1: 0, exit2: -1))
        XCTAssertTrue(o.ticks.filter { $0.t >= doneAt }.flatMap { $0.out.draws }.contains {
            if case .copyPicture(140, _, _, _, _, _) = $0 { true } else { false }
        }, "the panel ran")
        XCTAssertEqual(o.ticks.filter { $0.t >= doneAt }.flatMap { $0.out.sounds }, [])

        // Graphics mode 3: ⌘Q's ask ends with `DrawBlackLines` (`.RestoreWindowBackground`); OK → the pass, then
        // `DrawBlackLines`, the status bar; Cancel → the grid, `DrawBlackLines`, the status bar.
        for ok in [true, false] {
            let q = try Rig(r, prefs: Self.prefs(graphics: 3))
            try q.settle()
            let qask = try XCTUnwrap(try q.drive(max: 4, input: { _ in
                FrontInput(keys: KeyState(pressed: [Self.command, Self.keyQ]))
            }) { _, k in !self.dialogs(k.out).isEmpty })
            XCTAssertEqual(qask.steps.last?.draws.last, .drawBlackLines)
            q.run.dialogDone(ok ? .ok : .cancel)
            let qs = try XCTUnwrap(q.run.session)
            let rest = try XCTUnwrap(try q.tick().steps.first).draws
            let status = DrawOp.statusBar(qs.globals.statusBar(levelName: qs.level.header.name))
            if ok {
                XCTAssertEqual(q.run.end, .quit)
                let erase = try XCTUnwrap(rest.firstIndex(where: isErase))
                XCTAssertEqual(Array(rest[(erase + 1)...]), [.drawBlackLines, status])
            } else {
                XCTAssertEqual(Array(rest.prefix(3)), [.redrawEntireScrollGrid(h: qs.camera.scrollH, v: qs.camera.scrollV),
                                                       .drawBlackLines, status])
            }
        }

        // `.SavePointSave`'s tail calls `RedrawGameArea` (M l. 6491): `DrawBlackLines` before the line-skipped copy in
        // mode 3 (with `5107`), none in mode 1.
        let h = os.camera.scrollH, v = os.camera.scrollV
        XCTAssertEqual(SavePointSave.redraw(session: os, prefs: Self.prefs(graphics: 3)).draws,
                       [.redrawEntireScrollGrid(h: h, v: v), .drawBlackLines,
                        .copyToScreen(h: h, v: v, graphicsMode: 3, backdrop: true), .statusBar(os.globals.statusBar(
                            levelName: os.level.header.name))])
        XCTAssertFalse(SavePointSave.redraw(session: os, prefs: Self.prefs(graphics: 1)).draws.contains(.drawBlackLines))
    }

    // MARK: - The gates

    /// `if (*_DAT_1009fde8 != 0) return; if (DAT_100a53d6 == 0) return` (M l. 3880–3884): during the entry's
    /// `GammaFadeInAsync(0x28)` (the first 41 iterations) Esc does nothing; once it ends, it asks.
    func testKeysIgnoredWhileFading() throws {
        let r = try resources()
        let rig = try Rig(r)
        try rig.drive { rig, _ in rig.run.iterations >= 1 }
        let esc = FrontInput(keys: KeyState(pressed: [Self.escape]), capsLock: true)
        var fading = 0
        try rig.drive(max: 400, input: { _ in esc }) { rig, k in
            XCTAssertEqual(self.dialogs(k.out), [], "iteration \(rig.run.iterations)")
            XCTAssertTrue(k.steps.allSatisfy { $0.suspension == nil })
            XCTAssertNil(rig.run.pause)
            if let s = rig.run.session, !s.world.gammaFade.done { fading = rig.run.iterations }
            return rig.run.iterations >= 41
        }
        // Still running after 40 iterations; the 41st iteration's `.HandleAsyncGammaFade` (after its keys) ends it.
        XCTAssertEqual(fading, 40)
        let ask = try rig.drive(max: 6, input: { _ in FrontInput(keys: KeyState(pressed: [Self.escape])) }) { _, k in
            !self.dialogs(k.out).isEmpty
        }
        XCTAssertEqual(ask.map { dialogs($0.out) }, [.confirm(text: GameLoopKeys.abortText)])
        XCTAssertEqual(rig.run.iterations, 42)

        // `DAT_100a53d6` on its own: an async fade-OUT running (not faded yet, `*fde8` 0) holds the keys and the pause.
        let out = try Rig(r)
        try out.settle()
        let s = try XCTUnwrap(out.run.session)
        s.world.gammaFade.fadeOut(steps: 20, toward: RGB16(0, 0, 0))
        let start = out.run.iterations
        try out.drive(max: 100, input: { _ in esc }) { rig, k in
            XCTAssertEqual(self.dialogs(k.out), [])
            XCTAssertTrue(k.steps.allSatisfy { $0.suspension == nil })
            XCTAssertNil(rig.run.pause)
            return rig.run.iterations >= start + 10
        }
        XCTAssertFalse(s.world.gammaFade.fadedOut)
        XCTAssertFalse(s.world.gammaFade.done)
    }
}
