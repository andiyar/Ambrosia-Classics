import XCTest
@testable import FerazelCore

/// L1 (docs/plans/2026-10-14-ferazel-phase3.md): `LevelRun` — `.GameLoop @ 10009d48` (M l. 5093–5325) around a hosted
/// `FerazelSession`, with `.SetupLevel @ 1000430c` (M l. 2189–2590): the entry sequence (music fade-out, popup, load
/// bars, the revisit restore / first-visit totals, fades, the music fade-in, the chapter gate, the async fade-in), the
/// 2-tick cadence (Invariant 4) and the death / complete exits. Driven tick by tick against the committed
/// `Resources/Ferazel` (D26). A missing data file is a FAILURE, never a skip.
final class LevelRunTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// The renderer side, recorded (Core tests: the session's default face bounds, no particle faces).
    private final class StubServices: LevelServices {
        var faces = LevelFaces()
        var now: UInt32 = 0
        var prepared: [(tick: UInt32, level: Int)] = []
        var attached: [(tick: UInt32, lights: Int, draws: Int)] = []
        var deathSteps: [(tick: UInt32, k: Int)] = []

        func prepare(level: Int) throws -> LevelFaces {
            prepared.append((now, level))
            return faces
        }

        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {
            attached.append((now, lights.count, tintTableDraws.count))
        }

        func deathEffectStep(_ k: Int) throws { deathSteps.append((now, k)) }
    }

    private struct Tick {
        let t: UInt32
        let out: FrontOutput
        /// The iterations this tick stepped.
        let steps: [FrameOps]
    }

    private static let lengths: [Int16: Int] = [800: 30, 801: 40, 802: 50, 803: 5, 804: 7, 805: 20]

    private func make(_ r: FerazelResources, level: Int, carry: LevelCarry = LevelCarry(), save: SaveBlock = SaveBlock(),
                      prefs: FerazelPrefs = FerazelPrefs(), music: MusicFade = MusicFade(),
                      stub: StubServices) throws -> LevelRun {
        try LevelRun(resources: r, prefs: prefs, level: level, seed: 1, carry: carry, save: save, fade: ScreenFade(),
                     music: music, services: stub, sounds: StageSounds(prefs: prefs, lengths: Self.lengths))
    }

    /// Ticks `run` from `t0` once per tick until `until` holds (checked after each tick).
    private func drive(_ run: LevelRun, _ stub: StubServices, from t0: UInt32, max: Int = 4000,
                       input: (UInt32) -> FrontInput = { _ in FrontInput() },
                       until: (LevelRun) -> Bool) throws -> [Tick] {
        var ticks: [Tick] = []
        var t = t0
        for _ in 0..<max {
            stub.now = t
            let out = try run.tick(now: t, input: input(t))
            ticks.append(Tick(t: t, out: out, steps: run.lastSteps))
            if until(run) { return ticks }
            t &+= 1
        }
        XCTFail("the run did not reach the condition in \(max) ticks")
        return ticks
    }

    /// The load-bar widths (`.UpdateStageLoad`'s `PaintRect` (172, 213, 172 + w, 224), l, t, r, b) in order.
    private func bars(_ ticks: [Tick]) -> [Int] {
        ticks.flatMap { $0.out.draws }.compactMap { op in
            if case .fillRect(0xac, 0xd5, let right, 0xe0, _) = op { return right - 0xac } else { return nil }
        }
    }

    private func musicCues(_ ticks: [Tick]) -> [(t: UInt32, cue: MusicCue)] {
        ticks.flatMap { k in k.out.music.map { (k.t, $0) } }
    }

    private func isGammaStep(_ op: DrawOp) -> Bool { if case .gammaStep = op { true } else { false } }

    /// The menu's music playing at full volume (`SetAIFFMusic(24)` + its fade-in), as at a New Game.
    private func menuMusic(_ prefs: FerazelPrefs = FerazelPrefs()) -> MusicFade {
        var m = MusicFade()
        _ = m.setAIFFMusic(24)
        _ = m.fadeAIFFMusic(direction: 1, ticks: 4, prefs: prefs)
        return m
    }

    /// Inserts the level exit of record `rec` (its Setup) and puts the player inside its rect, then runs the player
    /// pass's contact (`HitPlayerSprite.hit`) — as `LevelFlowTests.touchExit`.
    private func touchExit(_ s: FerazelSession, record rec: Int) throws {
        let c = SetupFaces.Context(level: s.level, playerX: 0)
        let e = try SetupFaces.setup(s.level.placements[rec], context: c)
        let exit = s.world.active.insert(e.slot)
        let pid = try XCTUnwrap(s.world.playerID)
        s.world.active.update(id: pid) { $0.x = e.slot.x; $0.y = e.slot.y }
        HitPlayerSprite.hit(s.world, player: pid, other: exit)
    }

    /// The save point (record 24, type 0x429) wherever the Setups put it (active or idle).
    private func savePoint(_ s: FerazelSession) -> SpriteSlot? {
        s.active.sprites.first { $0.recordIndex == 24 } ?? s.idle.entries.compactMap { $0?.saved }
            .first { $0.recordIndex == 24 }
    }

    // MARK: -

    func testEntrySequenceOrder() throws {
        let r = try resources()
        let stub = StubServices()
        var g = GameGlobals.initGameGlobals(previous: nil)
        g.unlocked[1] = 0
        let run = try make(r, level: 1, carry: LevelCarry(parity: false, crunchLog: [], globals: g), music: menuMusic(),
                           stub: stub)
        let t0: UInt32 = 1000
        let ticks = try drive(run, stub, from: t0) { $0.iterations >= 1 }
        func at(_ t: UInt32) -> FrontOutput { ticks[Int(t - t0)].out }

        // `FadeAIFFMusic(0, 4)` (M l. 5161): V·(24 − s)/24 every 4 ticks, then 0 and `ShutDownAIFFMusic` at 96.
        let cues = musicCues(ticks)
        let fadeOut = cues.prefix(25)
        XCTAssertEqual(fadeOut.map { $0.t }, (0..<25).map { t0 + UInt32(4 * $0) })
        XCTAssertEqual(fadeOut.map { $0.cue }, (0..<24).map { MusicCue.volume(256 * (24 - $0) / 24) } + [.volume(0)])
        XCTAssertEqual(cues[25].t, t0 + 96)
        XCTAssertEqual(cues[25].cue, .stop)
        // `.PopupStageLoad` (L2): 16 one-tick frames from 96.
        let popups = ticks.filter { $0.out.draws.contains { if case .copyPicture(142, _, _, _, _, _) = $0 { true } else { false } } }
        XCTAssertEqual(popups.map { $0.t }, (96..<112).map { t0 + UInt32($0) })
        // `.SetupLevel` at 112: the renderer opened before the session, the lights / tint draws after it.
        XCTAssertEqual(stub.prepared.map { $0.tick }, [t0 + 112])
        XCTAssertEqual(stub.attached.map { [Int($0.tick), $0.draws] }, [[Int(t0) + 112, 510]])
        // The bars, all at 112: `.LoadLevelTilesets` 15/20/25/35/40 %, 50 %, the 30 cached face loads (n 90, q 180 —
        // self-derived, `CachedFaces`: p 96 … 162 for twelve sets, 163 … 180 for eighteen singles), 100 % twice.
        let cached = [156, 166, 175, 185, 195, 208, 218, 223, 226, 240, 255, 263,
                      265, 266, 268, 270, 271, 273, 275, 276, 278, 279, 281, 283, 284, 286, 288, 289, 291, 293]
        XCTAssertEqual(bars(ticks), [43, 58, 73, 102, 117, 146] + cached + [293, 293])
        XCTAssertEqual(bars([ticks[112]]).count, 38)
        // `unlocked[1]` set (before the player spawn, M l. 5180).
        XCTAssertEqual(run.session?.globals.unlocked[1], 1)
        // `GammaFadeOut(6)`: 30 `.TintFadeProc` ticks 112 … 141.
        let tints = ticks.filter { $0.out.draws.contains { if case .screenGamma(.tint(3, _)) = $0 { true } else { false } } }
        XCTAssertEqual(tints.map { $0.t }.prefix(30), ArraySlice((112..<142).map { t0 + UInt32($0) }))
        // At 142: the level CLUT, PICT 129, the zeroed redraw (`.SetupLevel` tail), `HideCursorSafe`, the start ops,
        // then `SetAIFFMusic(1)` + the fade-in's first volume.
        let s = try XCTUnwrap(run.session)
        let e = at(t0 + 142)
        XCTAssertEqual(Array(e.draws.prefix(6)), [.setScreenClut(id: 202), .drawPicture(id: 129, chain: .frontEnd, h: 0, v: 0),
                                                  .redrawEntireScrollGrid(h: 0, v: 0),
                                                  .redrawScrollGrid(h: s.camera.scrollH, v: s.camera.scrollV),
                                                  .redrawEntireScrollGrid(h: s.camera.scrollH, v: s.camera.scrollV),
                                                  .statusBar(s.globals.statusBar(levelName: s.level.header.name))])
        XCTAssertEqual(e.requests, [.hideCursor])
        XCTAssertEqual(e.music, [.play(track: 1), .volume(0)])
        // Exactly one `.play` before the first step, and `FadeAIFFMusic(1, 4)`'s 24 steps over 96 ticks, then V.
        XCTAssertEqual(cues.filter { if case .play = $0.cue { true } else { false } }.map { $0.cue }, [.play(track: 1)])
        let fadeIn = cues.filter { $0.t >= t0 + 142 }
        XCTAssertEqual(fadeIn.dropFirst().map { $0.t }, (0..<25).map { t0 + 142 + UInt32(4 * $0) })
        XCTAssertEqual(fadeIn.dropFirst().map { $0.cue }, (0..<24).map { MusicCue.volume(256 * $0 / 24) } + [.volume(256)])
        // Then (`InputActivate(1, 1)`, no op) the chapter card at 238: clut 281, PICT 4610.
        XCTAssertEqual(Array(at(t0 + 238).draws.prefix(1)), [.setScreenClut(id: 281)])
        // The first step: no start ops in it, the async fade-in's first step at its end.
        let first = try XCTUnwrap(ticks.last)
        XCTAssertGreaterThan(first.t, t0 + 238 + 109 + 1200)
        XCTAssertEqual(first.steps.count, 1)
        XCTAssertEqual(first.steps[0].draws.first, .redrawScrollGrid(h: s.camera.scrollH, v: s.camera.scrollV))
        XCTAssertFalse(first.steps[0].draws.contains { if case .setScreenClut = $0 { true } else { false } })
        XCTAssertTrue(first.steps[0].music.isEmpty)
        XCTAssertEqual(first.steps[0].draws.last, .gammaStep(numerator: 0, denominator: 0x28, toward: nil))
        // `GammaFadeInAsync(0x28)`: one step in each of the first 41 iterations, none after.
        let more = try drive(run, stub, from: first.t + 1) { $0.iterations >= 45 }
        let all = [first] + more
        let withGamma = all.flatMap { $0.steps }.map { $0.draws.contains(where: isGammaStep) }
        XCTAssertEqual(withGamma, Array(repeating: true, count: 41) + Array(repeating: false, count: 4))

        // The restart fast path (same level, tilesets kept, M l. 2252): 25 %, 50 %, the six flag-1 singles reloaded
        // (the CLUT ids stay −1 / 202 — self-derived, `CachedFaces`), 100 % twice.
        let stub2 = StubServices()
        let again = try make(r, level: 1, carry: run.carry, stub: stub2)
        let t1: UInt32 = 9000
        let ticks2 = try drive(again, stub2, from: t1) { $0.session != nil }
        XCTAssertEqual(bars(ticks2), [73, 146, 170, 195, 219, 244, 268, 293, 293, 293])
        XCTAssertEqual(ticks2.last?.t, t1 + 16)                       // no music loaded: the popup starts at once
    }

    func testCadenceTwoTicks() throws {
        let r = try resources()
        for reduce in [false, true] {
            var prefs = FerazelPrefs()
            prefs.reduceFrameRate = reduce ? 1 : 0
            let stub = StubServices()
            let run = try make(r, level: 2, prefs: prefs, stub: stub)        // level 2: no chapter card
            let start = try drive(run, stub, from: 50) { $0.iterations >= 1 }
            let t = try XCTUnwrap(start.last).t
            let pair = reduce ? 2 : 1
            XCTAssertEqual(start.last?.steps.map { $0.drawn }, reduce ? [false, true] : [true])
            // Steps at t, t + 2, t + 4 … (prefs+0 = 0); skipped + drawn pairs at t, t + 4 … (prefs+0 ≠ 0).
            var stepped: [UInt32] = []
            for k in UInt32(1)...12 {
                stub.now = t + k
                _ = try run.tick(now: t + k, input: FrontInput())
                if !run.lastSteps.isEmpty {
                    XCTAssertEqual(run.lastSteps.count, pair)
                    stepped.append(k)
                }
            }
            XCTAssertEqual(stepped, reduce ? [4, 8, 12] : [2, 4, 6, 8, 10, 12])
            // A 30-tick block (no tick delivered): one iteration (pair) when it ends, no catch-up, the cadence
            // measured from there.
            let before = run.iterations
            _ = try run.tick(now: t + 42, input: FrontInput())
            XCTAssertEqual(run.iterations, before + pair)
            _ = try run.tick(now: t + 43, input: FrontInput())
            _ = try run.tick(now: t + 43 + (reduce ? 2 : 0), input: FrontInput())
            XCTAssertEqual(run.iterations, before + pair)
            _ = try run.tick(now: t + 42 + (reduce ? 4 : 2), input: FrontInput())
            XCTAssertEqual(run.iterations, before + 2 * pair)
        }
    }

    func testFirstVisitTotalsLevel1() throws {
        let r = try resources()
        let stub = StubServices()
        var g = GameGlobals.initGameGlobals(previous: nil)
        g.achieved[0][1] = 7
        g.achieved[2][1] = 3
        let run = try make(r, level: 1, carry: LevelCarry(parity: false, crunchLog: [], globals: g), stub: stub)
        _ = try drive(run, stub, from: 0) { $0.session != nil }
        let s = try XCTUnwrap(run.session)
        XCTAssertFalse(run.revisit)
        // `.SetupLevelSprites`' tallies on level 1 (self-derived from the placements and the Setup sites,
        // `SetupFaces.Tallies`): enemies 15 (Walker 1700 ×2, 1705 ×4, 1760 ×1; Crawler 1712 ×3; Roach 1720 ×5),
        // Xichrons 43 (0x41f), secrets 10 (0x423).
        XCTAssertEqual(s.tallies, SetupFaces.Tallies(secrets: 10, xichrons: 43, enemies: 15))
        XCTAssertEqual([s.globals.totals[0][1], s.globals.totals[1][1], s.globals.totals[2][1]], [15, 43, 10])
        XCTAssertEqual([s.globals.achieved[0][1], s.globals.achieved[1][1], s.globals.achieved[2][1]], [0, 0, 0])
        // `G+0x20 = 0`, `G+0x22 ← hdr+0x2706` (5 on level 1), `G+0x174 = 0`.
        XCTAssertEqual(s.globals.darknessOverride, 0)
        XCTAssertEqual(s.globals.savedDarkness, 5)
        XCTAssertEqual(s.globals.omniPxActive, 0)
    }

    func testRevisitKeepsCountersAndSnapshot() throws {
        let r = try resources()
        let L = try LevelFile.load(from: r, level: 1)
        var records = L.placements
        let p = records[24]
        XCTAssertEqual(p.type, 0x429)
        records[24] = Placement(index: 24, flag: p.flag, byte1: p.byte1, type: p.type, p1: 2, p2: p.p2, p3: p.p3,
                                p4: p.p4, y: p.y, x: p.x)
        var g = GameGlobals.initGameGlobals(previous: nil)
        g.achieved[0][1] = 4
        g.totals[0][1] = 99
        g.totals[1][1] = 50
        var save = SaveBlock()
        save.savePointSave(level: 1, x: 2371, y: 872, stamp: 0, date: 0, globals: &g, records: records)
        XCTAssertEqual(g.hasSnapshot[1], 1)
        let stub = StubServices()
        let run = try make(r, level: 1, carry: LevelCarry(parity: false, crunchLog: [], globals: g), save: save,
                           stub: stub)
        let ticks = try drive(run, stub, from: 0) { $0.iterations >= 1 }
        let s = try XCTUnwrap(run.session)
        XCTAssertTrue(run.revisit)
        // The snapshot's records (+6 back) rebuilt the level: the save point shows face 2.
        XCTAssertEqual(s.world.records[24].p1, 2)
        XCTAssertEqual(savePoint(s)?.face?.index, 2)
        // Counters kept; no chapter card (`hasSnapshot[1] == 1`): the loop starts as the music fade-in ends.
        XCTAssertEqual([s.globals.achieved[0][1], s.globals.totals[0][1], s.globals.totals[1][1]], [4, 99, 50])
        XCTAssertFalse(ticks.flatMap { $0.out.draws }.contains(.setScreenClut(id: 281)))
        XCTAssertLessThan(try XCTUnwrap(ticks.last).t, 16 + 30 + 96 + 1)
    }

    func testCrunchReapplyDrawsNothing() throws {
        let r = try resources()
        let L = try LevelFile.load(from: r, level: 1)
        var g = GameGlobals.initGameGlobals(previous: nil)
        g.crunchLog = [CrunchLogEntry(level: 1, col: 119, row: 36), CrunchLogEntry(level: 2, col: 10, row: 10)]
        var save = SaveBlock()
        save.savePointSave(level: 1, x: 0, y: 0, stamp: 0, date: 0, globals: &g, records: L.placements)
        // Every FG tile has a face with pixels (one 4-pixel literal run), so an `.ExplodeCrunchedTile` would emit
        // particles and draw `FastRand` (E1a).
        let face = ParticleFace(frame: [0, 0, 32, 32], bounds: [0, 0, 32, 32], tokens: [2, 0, 0, 4, 9, 9, 9, 9, 0, 0, 0, 0])
        let faces = LevelFaces(particleFaces: ParticleFaces(fgTile: { _ in face }))
        let stub = StubServices()
        stub.faces = faces
        let run = try make(r, level: 1, carry: LevelCarry(parity: false, crunchLog: g.crunchLog, globals: g),
                           save: save, stub: stub)
        var ticks = try drive(run, stub, from: 0) { $0.session != nil }
        let s = try XCTUnwrap(run.session)
        // No `.ExplodeCrunchedTile`, so no particle and no `FastRand`: the stream after the level start is a fresh
        // level-1 start's (seed 1 → 0x2c1b1519).
        let stub2 = StubServices()
        stub2.faces = faces
        let freshRun = try make(r, level: 1, stub: stub2)
        _ = try drive(freshRun, stub2, from: 0) { $0.session != nil }
        let fresh = try XCTUnwrap(freshRun.session)
        XCTAssertEqual(fresh.rngSeed, 0x2c1b1519)
        XCTAssertEqual(s.rngSeed, 0x2c1b1519)
        XCTAssertEqual(s.seedAfterSetups, fresh.seedAfterSetups)
        XCTAssertEqual(s.world.particles.counters, fresh.world.particles.counters)
        ticks += try drive(run, stub, from: ticks.last!.t + 1) { $0.iterations >= 1 }
        // `.DestroyCrunchTile(119, 36, dir, 0, 1, 0)` (raw `10004874..1000487c`): the four cells reshaped as the
        // play-time crunch reshapes them (PlayerTileTests: 4, 7, 10, 9), the direction cleared — level 2's entry not.
        let tileOps = s.setupLevelTileOps
        let cells = tileOps.compactMap { op -> [Int]? in
            if case .setTile(let c, let rr, _) = op { return [c, rr] } else { return nil }
        }
        XCTAssertFalse(tileOps.isEmpty)
        XCTAssertEqual(cells.count, tileOps.count)
        XCTAssertEqual(Set(cells), [[119, 36], [120, 36], [119, 37], [120, 37]])
        XCTAssertEqual([s.world.tiles.fgTile(col: 119, row: 36), s.world.tiles.fgTile(col: 120, row: 36),
                        s.world.tiles.fgTile(col: 119, row: 37), s.world.tiles.fgTile(col: 120, row: 37)], [4, 7, 10, 9])
        XCTAssertEqual(s.world.tiles.crunchDir(col: 119, row: 36), 0)
        // Emitted before the first redraw (the level CLUT + `.RedrawEntireScrollGrid(0, 0)`), on the setup tick, and
        // not again in the first step.
        let draws = ticks.flatMap { $0.out.draws }
        let firstSet = try XCTUnwrap(draws.firstIndex { if case .setTile = $0 { true } else { false } })
        let firstRedraw = try XCTUnwrap(draws.firstIndex(of: .redrawEntireScrollGrid(h: 0, v: 0)))
        XCTAssertLessThan(firstSet, firstRedraw)
        XCTAssertEqual(draws.filter { if case .setTile = $0 { true } else { false } }.count, tileOps.count)
    }

    func testF4ClearsSnapshotFlag() throws {
        let r = try resources()
        let L = try LevelFile.load(from: r, level: 1)
        var records = L.placements
        let p = records[24]
        records[24] = Placement(index: 24, flag: p.flag, byte1: p.byte1, type: p.type, p1: 2, p2: p.p2, p3: p.p3,
                                p4: p.p4, y: p.y, x: p.x)
        var g = GameGlobals.initGameGlobals(previous: nil)
        var save = SaveBlock()
        save.savePointSave(level: 1, x: 0, y: 0, stamp: 0, date: 0, globals: &g, records: records)
        let stub = StubServices()
        let run = try make(r, level: 1, carry: LevelCarry(parity: false, crunchLog: [], globals: g), save: save,
                           stub: stub)
        // Key 0x76 (F4) held while `.SetupLevel` polls it (`IsPressed(0x76)`, M l. 2378): `hasSnapshot[1] = 0`.
        let ticks = try drive(run, stub, from: 0, input: { _ in FrontInput(keys: KeyState(pressed: [0x76])) }) {
            $0.iterations >= 1
        }
        let s = try XCTUnwrap(run.session)
        XCTAssertEqual(s.globals.hasSnapshot[1], 0)
        XCTAssertFalse(run.revisit)
        // So the first-visit path: the file's records (save point face 0), the totals, the chapter card.
        XCTAssertEqual(savePoint(s)?.face?.index, 0)
        XCTAssertEqual(s.globals.totals[1][1], 43)
        XCTAssertTrue(ticks.flatMap { $0.out.draws }.contains(.setScreenClut(id: 281)))
        // Not held: the flag stays and the snapshot is restored.
        let stub2 = StubServices()
        let run2 = try make(r, level: 1, carry: LevelCarry(parity: false, crunchLog: [], globals: g), save: save,
                            stub: stub2)
        _ = try drive(run2, stub2, from: 0) { $0.session != nil }
        XCTAssertEqual(run2.session?.globals.hasSnapshot[1], 1)
        XCTAssertTrue(run2.revisit)
    }

    func testDeathExitSequence() throws {
        let r = try resources()
        let stub = StubServices()
        let run = try make(r, level: 2, music: menuMusic(), stub: stub)
        var ticks = try drive(run, stub, from: 0) { $0.iterations >= 45 }
        let s = try XCTUnwrap(run.session)
        // The game over with G+4 < 1 (the dying arm's end, `PlayerStates`): HP 0 on the sprite and in G.
        let pid = try XCTUnwrap(s.world.playerID)
        s.world.active.update(id: pid) { $0.hp = 0 }
        s.world.globals.health = 0
        s.world.player.gameOver = true
        ticks = try drive(run, stub, from: ticks.last!.t + 2) { $0.end != nil }
        let te = ticks[0].t                                           // the iteration that ended the loop
        XCTAssertEqual(ticks[0].steps.count, 1)
        // The after-loop stops (M l. 5298–5299) close the iteration's stops.
        XCTAssertEqual(ticks[0].steps[0].soundStops.suffix(2), [452, 511])
        // Its 2-tick wait, then `FadeAIFFMusic(0, 2)`: 24 volumes 2 ticks apart, 0 at 48.
        let cues = musicCues(ticks)
        XCTAssertEqual(cues.prefix(25).map { $0.t }, (0..<25).map { te + 2 + UInt32(2 * $0) })
        XCTAssertEqual(cues.prefix(25).map { $0.cue }, (0..<24).map { MusicCue.volume(256 * (24 - $0) / 24) } + [.volume(0)])
        // `.DeathEffect`: `GammaFadeOutAsync(0x30)` (its `HideCursorSafe`), 50 one-tick steps, a gamma step in each of
        // the first 49 (k ≤ 0x30), then `ShutDownAIFFMusic` and `ShowCursorSafe`.
        XCTAssertEqual(stub.deathSteps.map { $0.k }, Array(0..<50))
        XCTAssertEqual(stub.deathSteps.map { $0.tick }, (0..<50).map { te + 50 + UInt32($0) })
        let wipe = ticks.filter { $0.t >= te + 50 && $0.t < te + 100 }
        XCTAssertEqual(wipe.map { $0.out.draws.filter(isGammaStep).count }, Array(repeating: 1, count: 49) + [0])
        XCTAssertEqual(wipe.first?.out.draws.first, .gammaStep(numerator: 0, denominator: 0x30, toward: RGB16(0, 0, 0)))
        XCTAssertEqual(wipe.first?.out.requests, [.hideCursor])
        XCTAssertEqual(ticks.last?.t, te + 100)
        XCTAssertEqual(ticks.last?.out.music, [.stop])
        XCTAssertEqual(ticks.last?.out.requests, [.showCursor])
        XCTAssertEqual(cues.count, 26)
        XCTAssertTrue(run.died)
        XCTAssertTrue(s.world.playerDead)
        XCTAssertEqual(run.end, .died)
        XCTAssertFalse(ticks.flatMap { $0.out.requests }.contains(.deathEffect))
        XCTAssertNil(s.ended)
    }

    func testCompleteExitSequence() throws {
        let r = try resources()
        let stub = StubServices()
        let run = try make(r, level: 1, music: menuMusic(), stub: stub)
        var ticks = try drive(run, stub, from: 0) { $0.iterations >= 45 }
        let s = try XCTUnwrap(run.session)
        try touchExit(s, record: 66)
        ticks = try drive(run, stub, from: ticks.last!.t + 2) { $0.end != nil }
        let te = ticks[0].t
        XCTAssertEqual(ticks[0].steps.count, 1)
        XCTAssertEqual(ticks[0].steps[0].soundStops.suffix(5), [452, 511, 452, 453, 511])
        // `.EndLevelSGUpdate` after the iteration's wait: `+6 = 1`, `+8 = 1`, `hasSnapshot[1] = 1` in the live G and
        // the copy, x / y = the `.GameLoop` start.
        XCTAssertEqual(run.save.isCheckpoint, 1)
        XCTAssertEqual(run.save.level, 1)
        XCTAssertEqual(run.save.globals.hasSnapshot[1], 1)
        XCTAssertEqual(s.globals.hasSnapshot[1], 1)
        XCTAssertEqual([run.save.playerX, run.save.playerY], [Int32(s.startX), Int32(s.startY)])
        XCTAssertEqual(run.save.worldStamp, try WorldFile.load(from: r).stamp)
        XCTAssertEqual(run.save.restoreSnapshot(level: 1), s.world.records)
        // `.StageCompleteEffect` (L2) from te + 2, then `FadeAIFFMusic(0, 2)` 48 ticks, `GammaFadeOut(6)` 30 ticks,
        // `ShutDownAIFFMusic` + `ShowCursorSafe`.
        let panel = StageScreens.stageCompleteEffect(globals: s.globals, level: 1,
                                                     sounds: StageSounds(prefs: FerazelPrefs(), lengths: Self.lengths))
        let d = UInt32(panel.duration)
        let panelTicks = ticks.filter { $0.out.draws.contains { if case .copyPicture(140, _, _, _, _, _) = $0 { true } else { false } } }
        XCTAssertEqual(panelTicks.map { $0.t }, (0..<27).map { te + 2 + UInt32($0) })
        XCTAssertEqual(ticks.first { $0.t == te + 2 }?.out.sounds.count, 1)  // snd 805
        let cues = musicCues(ticks)
        XCTAssertEqual(cues.prefix(25).map { $0.t }, (0..<25).map { te + 2 + d + UInt32(2 * $0) })
        XCTAssertEqual(cues.prefix(25).map { $0.cue }, (0..<24).map { MusicCue.volume(256 * (24 - $0) / 24) } + [.volume(0)])
        let tints = ticks.filter { $0.out.draws.contains { if case .screenGamma(.tint(3, _)) = $0 { true } else { false } } }
        XCTAssertEqual(tints.map { $0.t }, (0..<30).map { te + 2 + d + 48 + UInt32($0) })
        XCTAssertEqual(ticks.last?.t, te + 2 + d + 48 + 30)
        XCTAssertEqual(ticks.last?.out.music, [.stop])
        XCTAssertEqual(ticks.last?.out.requests, [.showCursor])
        // L1's rec 66 (p1 0, p2 0): exit1 0, exit2 untouched (−1); no `.loadLevel` request.
        XCTAssertEqual(run.end, .completed(exit1: 0, exit2: -1))
        XCTAssertFalse(ticks.flatMap { $0.out.requests }.contains { if case .loadLevel = $0 { true } else { false } })
        XCTAssertFalse(run.died)
    }
}
