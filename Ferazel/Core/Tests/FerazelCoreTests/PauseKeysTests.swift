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

        init(_ r: FerazelResources, prefs: FerazelPrefs = FerazelPrefs()) throws {
            run = try LevelRun(resources: r, prefs: prefs, level: 1, seed: 1, carry: LevelCarry(), save: SaveBlock(),
                               fade: ScreenFade(), music: MusicFade(), services: StubServices(),
                               sounds: StageSounds(prefs: prefs, lengths: [:]))
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
    }

    // MARK: - Pause entry and exit

    func testPauseEntryAndExit() throws {
        let r = try resources()
        let rig = try Rig(r)
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
        // The exit's tail: the menu bar hidden, `RedrawEntireScrollGrid` + `RedrawGameArea`, the cursor hidden — then
        // the same iteration finishes (status bar) and the run steps on.
        let tail = end.out
        XCTAssertTrue(tail.requests.contains(.hideMenuBar))
        XCTAssertTrue(tail.requests.contains(.hideCursor))
        let grid = try XCTUnwrap(tail.draws.firstIndex(of: .redrawEntireScrollGrid(h: s.camera.scrollH,
                                                                                   v: s.camera.scrollV)))
        XCTAssertTrue(isCopy(tail.draws[grid + 1]))
        XCTAssertTrue(tail.draws[(grid + 2)...].contains(where: isStatus))
        XCTAssertEqual(rig.run.iterations, iterationsBefore + 1)
        XCTAssertEqual(end.steps.last?.suspension, nil)
        XCTAssertEqual(s.pauseDebounce, 0)
        try rig.drive(max: 4) { rig, _ in rig.run.iterations == iterationsBefore + 2 }

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
    }

    // MARK: - Esc / ⌘W: abort

    func testEscAbortEndsLevelWithoutFades() throws {
        let r = try resources()
        for keys in [[Self.escape], [Self.command, Self.keyW]] {
            let rig = try Rig(r)
            try rig.settle()
            let musicBefore = rig.ticks.flatMap { $0.out.music }.count
            let ask = try XCTUnwrap(try rig.drive(max: 4, input: { _ in FrontInput(keys: KeyState(pressed: keys)) }) {
                _, k in !self.dialogs(k.out).isEmpty
            })
            XCTAssertEqual(dialogs(ask.out), [.confirm(text: GameLoopKeys.abortText)], "\(keys)")
            XCTAssertTrue(ask.out.requests.contains(.showCursor))
            XCTAssertNotNil(ask.steps.last?.suspension)
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
        XCTAssertEqual(a.t, b.t)
        let iterations = a.run.iterations
        let qa = try a.drive(max: 4, input: { _ in FrontInput(keys: KeyState(pressed: [Self.command, Self.keyQ])) }) {
            rig, _ in rig.run.iterations > iterations
        }
        let qb = try b.drive(max: 4) { rig, _ in rig.run.iterations > iterations }
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
    }
}
