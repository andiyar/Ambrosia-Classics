import XCTest
@testable import FerazelCore

/// F1b (docs/plans/2026-10-14-ferazel-phase3.md): `GameFlow` part 2 — `.NewGame @ 1000b11c` (M l. 5704–5874),
/// `.ContinueGame @ 1000d004` (M l. 6663–7102, the default branch), the level ⇄ map loop (`LevelRun` ⇄ `WorldMapRun`),
/// death → `.AskToContinue` (`DeathScreen`) → `fd48` → Continue with the last reply, and the refusals (bank
/// save-continue §4, §5). Driven tick by tick from the boot, headless with scripted input, against the committed
/// `Resources/Ferazel` (D26). A missing data file is a FAILURE, never a skip.
final class GameFlowGameTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// Saved games in memory, by URL; every read recorded.
    private final class Saves: FrontFiles {
        var blocks: [URL: SaveBlock] = [:]
        var reads: [URL] = []
        func loadPrefs() -> Data? { nil }
        func storePrefs(_ record: Data) throws {}
        func readSavedGame(_ ref: SavedGameRef) throws -> SaveBlock {
            reads.append(ref.url)
            guard let b = blocks[ref.url] else { throw SavedGameError.notASavedGame }
            return b
        }
        var written: [URL: SaveBlock] = [:]
        var failWrite: Int16?
        func writeSavedGame(_ block: SaveBlock, to ref: SavedGameRef) throws(SaveWriteError) {
            if let e = failWrite { throw SaveWriteError(osErr: e) }
            written[ref.url] = block
        }
    }

    /// The renderer side, recorded; `failAttach` makes `attach` throw (a renderer failure inside `LevelRun.tick`).
    private final class Levels: LevelServices {
        struct Failure: Error {}
        var prepared: [Int] = []
        var failAttach = false
        func prepare(level: Int) throws -> LevelFaces { prepared.append(level); return LevelFaces() }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws { if failAttach { throw Failure() } }
        func deathEffectStep(_ k: Int) throws {}
    }

    private struct Tick {
        let t: UInt32
        let out: FrontOutput
        let segments: [FlowSegment]
    }

    private final class Rig {
        let flow: GameFlow
        let files = Saves()
        let levels = Levels()
        var t: UInt32 = 1000
        var log: [Tick] = []
        /// The last tick's output (for the `until` tests).
        var last = FrontOutput()

        init(_ r: FerazelResources, startLevel: Int = 1) {
            flow = GameFlow(resources: r, prefs: FerazelPrefs(), seed: 1, files: files, levels: levels)
            flow.startLevel = startLevel
        }

        /// Ticks until `until` holds (checked after each tick) or `max` ticks; answers the loads at once.
        @discardableResult
        func drive(max: Int = 6000, input: (GameFlow) -> FrontInput = { _ in FrontInput() },
                   until: (GameFlow) -> Bool) -> [Tick] {
            var ticks: [Tick] = []
            for _ in 0..<max {
                if case .loading = flow.state { flow.loadFinished() }
                let out = flow.tick(now: t, input: input(flow))
                let k = Tick(t: t, out: out, segments: flow.segments)
                last = out
                ticks.append(k)
                log.append(k)
                t &+= 1
                if until(flow) { return ticks }
            }
            XCTFail("the flow did not reach the condition in \(max) ticks (state \(flow.state))")
            return ticks
        }

        func toMenu() {
            drive { $0.state == .mainMenu }
        }

        /// One menu pass with `key` down (the keyboard track: 10 ticks), then up.
        func press(_ key: Int) {
            drive(max: 1, input: { _ in FrontInput(keys: KeyState(pressed: [key])) }) { _ in true }
        }
    }

    private func pictures(_ o: [DrawOp]) -> [Int16] {
        o.compactMap {
            switch $0 {
            case .drawPicture(let id, _, _, _): return id
            case .copyPicture(let id, _, _, _, _, _): return id
            default: return nil
            }
        }
    }

    private func draws(_ ticks: [Tick]) -> [DrawOp] { ticks.flatMap { $0.out.draws } }
    private func music(_ ticks: [Tick]) -> [(t: UInt32, cue: MusicCue)] { ticks.flatMap { k in k.out.music.map { (k.t, $0) } } }
    private func dialogs(_ ticks: [Tick]) -> [FerazelDialog] {
        ticks.flatMap { $0.out.requests }.compactMap { if case .dialog(let d) = $0 { return d }; return nil }
    }
    private func tints(_ ticks: [Tick]) -> Int {
        draws(ticks).filter { if case .screenGamma(.tint) = $0 { return true }; return false }.count
    }

    private func asked(_ o: FrontOutput) -> Bool {
        o.requests.contains { if case .dialog = $0 { return true }; return false }
    }

    private func askedFile(_ o: FrontOutput) -> Bool {
        o.requests.contains { if case .getFile = $0 { return true }; return false }
    }

    private func isRunning(_ f: GameFlow, level n: Int, iterations: Int = 45) -> Bool {
        guard let run = f.levelRun, run.levelNumber == n else { return false }
        return run.iterations >= iterations
    }

    private func onIdleMap(_ f: GameFlow) -> Bool {
        guard let m = f.worldMap else { return false }
        return m.iterations >= 2 && m.walkStep == 0 && m.result == nil
    }

    /// The menu return's draws and music (`GammaFadeOut(6)`, `.DrawMainMenu`, track 24 + its fade-in, `GammaFadeIn(6)`).
    private func checkMenuReturn(_ ticks: [Tick], _ flow: GameFlow, continuing: Bool = false,
                                 file: StaticString = #filePath, line: UInt = #line) {
        // `.UpdateMenus` after the music fade-in (New Game: 96 ticks after the menu is drawn) or before it (Continue: on
        // the drawing tick); then `GammaFadeIn(6)` and `ShowCursorSafe` on its last tick.
        let drawn = ticks.last { $0.out.draws.contains(.setScreenClut(id: 130)) }?.t
        let menus = ticks.last { $0.out.requests.contains { if case .showMenuBarItems = $0 { return true }; return false } }?.t
        XCTAssertNotNil(drawn, file: file, line: line)
        if let drawn { XCTAssertEqual(menus, drawn + (continuing ? 0 : 96), file: file, line: line) }
        XCTAssertEqual(ticks.last?.out.requests.last, .showCursor, file: file, line: line)
        if let menus { XCTAssertEqual(ticks.last?.t, menus + 21 + (continuing ? 96 : 0), file: file, line: line) }
        let d = draws(ticks)
        let clut = d.lastIndex(of: .setScreenClut(id: 130))
        XCTAssertNotNil(clut, "the main menu redrawn", file: file, line: line)
        XCTAssertEqual(d.last { if case .drawPicture = $0 { return true }; return false },
                       .drawPicture(id: 130, chain: .frontEnd, h: 0, v: 0), file: file, line: line)
        let m = music(ticks).map(\.cue)
        let play = m.lastIndex(of: .play(track: 24))
        XCTAssertNotNil(play, file: file, line: line)
        if let play {
            XCTAssertEqual(Array(m[play...].prefix(25)), [.play(track: 24)] + (0..<24).map { .volume(256 * $0 / 24) },
                           file: file, line: line)
        }
        XCTAssertEqual(flow.state, .mainMenu, file: file, line: line)
        XCTAssertFalse(flow.fade.faded, file: file, line: line)
        XCTAssertNil(flow.levelRun, file: file, line: line)
        XCTAssertNil(flow.worldMap, file: file, line: line)
    }

    private func kill(_ s: FerazelSession) throws {
        let pid = try XCTUnwrap(s.world.playerID)
        s.world.active.update(id: pid) { $0.hp = 0 }
        s.world.globals.health = 0
        s.world.player.gameOver = true
    }

    /// A checkpoint save as `.SavePointSave` writes it at level 1's save point (record 24, its face p1 2), with a
    /// start facing no level header has and some coins.
    private func checkpoint(_ r: FerazelResources, level: Int16 = 1, facing: Int16 = 7) throws -> SaveBlock {
        let L = try LevelFile.load(from: r, level: 1)
        var records = L.placements
        let p = records[24]
        records[24] = Placement(index: 24, flag: p.flag, byte1: p.byte1, type: p.type, p1: 2, p2: p.p2, p3: p.p3,
                                p4: p.p4, y: p.y, x: p.x)
        var g = GameGlobals.initGameGlobals(previous: nil)
        g.startFacing = facing
        g.coins = 23
        var save = SaveBlock()
        save.savePointSave(level: 1, x: 2371, y: 872, stamp: try WorldFile.load(from: r).stamp, date: 0, globals: &g,
                           records: records)
        save.level = level
        return save
    }

    // MARK: - Tests

    func testNewGameStartsLevel1() throws {
        let r = try resources()
        let rig = Rig(r)
        let flow = rig.flow
        rig.toMenu()
        // State a previous game left: a checkpoint save in the block, the died flag, a G with a crunch-pair and a
        // facing, node sprites on the map.
        flow.saveBlock = try checkpoint(r)
        XCTAssertEqual(flow.saveBlock.isCheckpoint, 1)
        flow.died = true
        flow.globals.coins = 99
        flow.globals.startFacing = 5
        flow.mapSprites = [MapSprite(h: 10, v: 20, type: 0, counter: 0)]
        rig.press(0x2d)                                                    // N
        let ticks = rig.drive { self.isRunning($0, level: 1, iterations: 1) }
        XCTAssertEqual(flow.state, .newGame)
        let run = try XCTUnwrap(flow.levelRun)
        let s = try XCTUnwrap(run.session)
        // `GameFlow.initGameGlobals()`: SV1's G + the tail (`*ffa8` and the others 0, then `save+6 = 0`), fe00 = fd54 = 0.
        XCTAssertFalse(flow.died)
        XCTAssertEqual(flow.saveBlock.isCheckpoint, 0)
        XCTAssertFalse(flow.savedThisGame)
        XCTAssertFalse(flow.saveFileKnown)
        XCTAssertTrue(flow.mapSprites.isEmpty, "`.InitPlayerMapData`: the node-sprite count 0 (M l. 864)")
        XCTAssertEqual(flow.defaultWorld, 1)
        XCTAssertEqual(flow.levelNumber, 1)
        var expected = GameGlobals.initGameGlobals(previous: nil)
        expected.startFacing = 5
        expected = GameGlobals.initGameGlobals(previous: expected)
        XCTAssertEqual(s.globals.coins, expected.coins)
        XCTAssertEqual(s.globals.health, expected.health)
        XCTAssertEqual(s.globals.inventory, expected.inventory)
        XCTAssertEqual(s.globals.unlocked[1], 1)
        // `G+0x16 ← hdr[0x26c8]` every level (M l. 5821).
        XCTAssertEqual(s.globals.startFacing, Int16(s.level.header.startFacingLeft))
        // The start: hdr+0x2848 − 32, hdr+0x2846 − 32; param_4 = 1.
        XCTAssertEqual([s.startX, s.startY], [Int(s.level.header.startX) - 32, Int(s.level.header.startY) - 32])
        // The menu's music: `FadeAIFFMusic(0,4)` + `ShutDownAIFFMusic` in `.NewGame`'s loop body (96 ticks, then
        // `.stop`); `.GameLoop`'s own (M l. 5161–5163) then finds no music — one fade, one stop, before track 1.
        let m = music(ticks)
        let fade = m.prefix(26)
        XCTAssertEqual(fade.map(\.cue), (0..<24).map { .volume(256 * (24 - $0) / 24) } + [.volume(0), .stop])
        XCTAssertEqual(fade.map(\.t).first.map { fade.last!.t - $0 }, 96)
        XCTAssertEqual(m.filter { $0.cue == .stop }.count, 1)
        XCTAssertEqual(m.first { if case .play = $0.cue { return true }; return false }?.cue,
                       .play(track: Int(s.level.header.music)))
        // Level 1's chapter card ran (clut 281 on the screen renderer), and the level's draws went to the level one.
        XCTAssertTrue(ticks.flatMap(\.segments).contains { if case .screen(let d) = $0 { return d.contains(.setScreenClut(id: 281)) }; return false })
        XCTAssertTrue(ticks.flatMap(\.segments).contains { if case .level(let d) = $0 { return d.contains { if case .redrawEntireScrollGrid = $0 { return true }; return false } }; return false })
        XCTAssertEqual(rig.levels.prepared, [1])

        // Option held at New Game (no debug flag; the level switch at its default 1): "Ferazel sez:\rNo more
        // cheating!" (0x100a2e31), then level 1.
        let rig2 = Rig(r)
        rig2.toMenu()
        let ask = rig2.drive(input: { _ in FrontInput(keys: KeyState(pressed: [0x2d, 0x3a])) }) { _ in self.asked(rig2.last) }
        XCTAssertEqual(dialogs(ask).last, .report(text: "Ferazel sez:\rNo more cheating!"))
        XCTAssertNil(rig2.flow.levelRun)
        rig2.flow.dialogDone(.ok)
        rig2.drive { self.isRunning($0, level: 1, iterations: 1) }
        XCTAssertEqual(rig2.flow.levelNumber, 1)
        XCTAssertEqual(rig2.levels.prepared, [1])
        // The hidden `FerazelLevel` switch starts at its level (∈ BuiltLevels) instead, Option or not; a level outside
        // BuiltLevels (3 and 0) starts level 1.
        XCTAssertEqual(BuiltLevels.range, 1...2)
        for (start, option, expected) in [(2, true, 2), (3, false, 1), (0, false, 1)] {
            let rig3 = Rig(r, startLevel: start)
            rig3.toMenu()
            let keys = option ? [0x2d, 0x3a] : [0x2d]
            let a = rig3.drive(input: { f in FrontInput(keys: KeyState(pressed: f.state == .mainMenu ? keys : [])) }) {
                f in self.asked(rig3.last) || self.isRunning(f, level: expected, iterations: 1)
            }
            XCTAssertEqual(dialogs(a), option ? [.report(text: GameFlow.noMoreCheating)] : [], "start \(start)")
            if option { rig3.flow.dialogDone(.ok); rig3.drive { self.isRunning($0, level: expected, iterations: 1) } }
            XCTAssertEqual(rig3.flow.levelNumber, expected, "start \(start)")
            XCTAssertEqual(rig3.levels.prepared, [expected], "start \(start)")
        }
    }

    func testLevel1ToMapToLevel2() throws {
        let r = try resources()
        let rig = Rig(r)
        let flow = rig.flow
        rig.toMenu()
        rig.press(0x2d)
        rig.drive { self.isRunning($0, level: 1) }
        let s1 = try XCTUnwrap(flow.levelRun?.session)
        s1.world.globals.coins = 17
        s1.world.active.update(id: try XCTUnwrap(s1.world.playerID)) { $0.hp = 333 }
        try touchExit(s1, record: 66)
        // Exit → `.EndLevelSGUpdate` → the stats panel (PICT 140) → the map (clut 700, PICT 7000) → the auto-walk to 2.
        let toMap = rig.drive { self.onIdleMap($0) }
        XCTAssertTrue(pictures(draws(toMap)).contains(140))
        XCTAssertEqual(flow.saveBlock.isCheckpoint, 1)
        XCTAssertEqual(flow.saveBlock.level, 1)
        let map = try XCTUnwrap(flow.worldMap)
        XCTAssertEqual(map.cur, try XCTUnwrap(map.map.findCurrNode(level: 2)).index)
        XCTAssertEqual(map.globals.unlocked[2], 1)
        XCTAssertTrue(toMap.flatMap(\.segments).contains { if case .map(let ops) = $0 { return ops.contains(.portsClut(id: 700)) }; return false })
        XCTAssertEqual(flow.state, .newGame)
        // The segments are lossless: on every tick so far the `.screen` + `.level` segments' draws, in order, are the
        // output's draw list (the map's ops live only in `.map` segments, and the map was drawn).
        for k in rig.log {
            let flat = k.segments.flatMap { g -> [DrawOp] in
                switch g {
                case .screen(let d), .level(let d): return d
                case .map: return []
                }
            }
            XCTAssertEqual(flat, k.out.draws, "tick \(k.t)")
        }
        XCTAssertTrue(rig.log.contains { k in k.segments.contains { if case .map(let o) = $0 { return !o.isEmpty }; return false } })
        // Return → level 2 entered with G carried (HP, coins); `save+0xc/+0x10 ← L2 hdr+0x2848 − 32 / +0x2846 − 32`.
        rig.drive(input: { _ in FrontInput(keys: KeyState(pressed: [0x24])) }) { $0.worldMap == nil }
        rig.drive { self.isRunning($0, level: 2) }
        XCTAssertEqual([flow.saveBlock.playerX, flow.saveBlock.playerY], [901 - 32, 256 - 32])
        let s2 = try XCTUnwrap(flow.levelRun?.session)
        XCTAssertEqual(s2.globals.coins, 17)
        XCTAssertEqual(s2.globals.health, 333)
        XCTAssertEqual(s2.globals.unlocked[2], 1)
        XCTAssertEqual(flow.levelNumber, 2)
        XCTAssertEqual(flow.exit1, -1)
        XCTAssertEqual(flow.exit2, -1)
        XCTAssertEqual(rig.levels.prepared, [1, 2])
        // Level 2's exit p1 1 (record 39) → the map → the auto-walk to node 3 → Return → the "not built yet" report
        // (the only invented text, D35), still on the map, nothing new unlocked.
        try touchExit(s2, record: 39)
        rig.drive { self.onIdleMap($0) }
        let m2 = try XCTUnwrap(flow.worldMap)
        XCTAssertEqual(m2.cur, try XCTUnwrap(m2.map.findCurrNode(level: 3)).index)
        let unlocked = m2.globals.unlocked
        let ask = rig.drive(input: { f in FrontInput(keys: KeyState(pressed: f.worldMap?.result == nil ? [0x24] : [])) }) {
            _ in self.asked(rig.last)
        }
        XCTAssertEqual(dialogs(ask).last, .report(text: "Level 3 is not built yet (Phases 4-6)."))
        XCTAssertNil(flow.levelRun)
        flow.dialogDone(.ok)
        rig.drive { self.onIdleMap($0) }
        let m3 = try XCTUnwrap(flow.worldMap)
        XCTAssertFalse(m3 === m2)
        XCTAssertEqual(m3.cur, m2.cur)
        XCTAssertEqual(m3.globals.unlocked, unlocked)
        XCTAssertEqual(rig.levels.prepared, [1, 2])
        XCTAssertEqual(flow.state, .newGame)
    }

    func testMapAbortReturnsToMenu() throws {
        let r = try resources()
        let rig = Rig(r)
        let flow = rig.flow
        rig.toMenu()
        rig.press(0x2d)
        rig.drive { self.isRunning($0, level: 1) }
        try touchExit(try XCTUnwrap(flow.levelRun?.session), record: 66)
        rig.drive { self.onIdleMap($0) }
        let exitSpot = [flow.saveBlock.playerX, flow.saveBlock.playerY]
        // Esc → "Are you sure you want to abort this game?" → OK → −1.
        let ask = rig.drive(max: 1, input: { _ in FrontInput(keys: KeyState(pressed: [0x35])) }) { _ in true }
        XCTAssertEqual(dialogs(ask), [.confirm(text: "Are you sure you want to abort this game?")])
        flow.dialogDone(.ok)
        let back = rig.drive { $0.state == .mainMenu }
        // The map's `FadeAIFFMusic(0,2)`, then `.NewGame`'s `GammaFadeOut(10)` (885 ms → 54 ticks), then the menu
        // return (its `GammaFadeOut(6)` finds the screen faded: nothing), track 24 faded in, `GammaFadeIn(6)`.
        XCTAssertEqual(tints(back), ScreenFade.ticks(milliseconds: ScreenFade.fadeOutMilliseconds(10)))
        XCTAssertEqual(tints(back), 54)
        checkMenuReturn(back, flow)
        XCTAssertFalse(flow.continueRequested)
        XCTAssertTrue(flow.aborted)
        // Not aborted is false: the save position is the level-1 exit's (no write of the level's start − 32 — level 1
        // is still `feac` after the −1).
        XCTAssertEqual(flow.saveBlock.level, 1)
        XCTAssertEqual(flow.levelNumber, 1)
        let h1 = try LevelFile.load(from: r, level: 1).header
        XCTAssertNotEqual([flow.saveBlock.playerX, flow.saveBlock.playerY],
                          [Int32(h1.startX) - 32, Int32(h1.startY) - 32])
        XCTAssertEqual([flow.saveBlock.playerX, flow.saveBlock.playerY], exitSpot)
        // The tileset globals and the class face cache run on from game to game (L1 carry); the node sprites are gone.
        XCTAssertEqual(flow.levelCarry.tilesetLevel, 1)
        XCTAssertFalse(flow.levelCarry.cachedFaces.loadedSets.isEmpty)
        XCTAssertTrue(flow.mapSprites.isEmpty)
        // The menu works again: N starts a fresh game at level 1 (no death screen; `G` re-initialised).
        rig.press(0x2d)
        rig.drive { self.isRunning($0, level: 1, iterations: 1) }
        XCTAssertEqual(flow.levelRun?.session?.globals.unlocked[2], 0)
        XCTAssertEqual(flow.levelRun?.carry.cachedFaces, flow.levelCarry.cachedFaces)

        // A map whose current node is not found (`.FindCurrNode`: "Current node could not be found!" + `ExitToShell`):
        // no result, `quitRequested` — the flow quits and nothing more happens.
        let rig2 = Rig(r)
        rig2.toMenu()
        rig2.press(0x2d)
        rig2.drive { self.isRunning($0, level: 1) }
        try touchExit(try XCTUnwrap(rig2.flow.levelRun?.session), record: 66)
        rig2.drive { $0.worldMap != nil }
        let m = try XCTUnwrap(rig2.flow.worldMap)
        rig2.flow.worldMap = try WorldMapRun(resources: r, prefs: FerazelPrefs(), globals: m.globals, level: 63,
                                             levelName: "", exit1: 0, exit2: -1, levelComplete: true, seed: 1,
                                             fade: m.fade, music: m.music)
        let lost = rig2.drive { _ in self.asked(rig2.last) }
        XCTAssertEqual(dialogs(lost), [.error(text: WorldMapRun.nodeNotFound, code: 0)])
        rig2.flow.dialogDone(.ok)
        let quit = rig2.drive { $0.state == .quit }
        XCTAssertEqual(quit.last?.out.requests, [.quit])
        XCTAssertNil(rig2.flow.worldMap)
        XCTAssertTrue(rig2.flow.quitRequested)
        for _ in 0..<5 { XCTAssertEqual(rig2.flow.tick(now: rig2.t, input: FrontInput()), FrontOutput()); rig2.t += 1 }
    }

    func testDeathWithoutSaveGoesToMenu() throws {
        let r = try resources()
        let rig = Rig(r)
        let flow = rig.flow
        rig.toMenu()
        rig.press(0x2d)
        rig.drive { self.isRunning($0, level: 1) }
        try kill(try XCTUnwrap(flow.levelRun?.session))
        let back = rig.drive { $0.state == .mainMenu }
        // `fe00 == 0`: `.AskToContinue` returns false with no drawing (no clut 132, no PICT 138) → the menu return.
        XCTAssertFalse(draws(back).contains(.setScreenClut(id: DeathScreen.clutId)))
        XCTAssertFalse(pictures(draws(back)).contains(DeathScreen.backgroundPicture))
        checkMenuReturn(back, flow)
        XCTAssertFalse(flow.continueRequested)
        XCTAssertTrue(flow.died)
        XCTAssertNil(flow.deathScreen)
        XCTAssertEqual(flow.lastAskToContinue, false, "`.AskToContinue` ran (and said no)")
        // The menu loop goes on: no Continue is started by itself.
        for _ in 0..<30 { rig.drive(max: 1) { _ in true } }
        XCTAssertEqual(flow.state, .mainMenu)
        XCTAssertTrue(rig.files.reads.isEmpty)

        // New Game's death test is G+4 < 1, not `ffa8`: the player dies (`ffa8` set), then G+4 is put back to 1
        // during `.DeathEffect` — `.AskToContinue` is never called.
        let rig2 = Rig(r)
        rig2.toMenu()
        rig2.press(0x2d)
        rig2.drive { self.isRunning($0, level: 1) }
        let s2 = try XCTUnwrap(rig2.flow.levelRun?.session)
        try kill(s2)
        rig2.drive { $0.levelRun?.died == true }
        s2.world.globals.health = 1
        let back2 = rig2.drive { $0.state == .mainMenu }
        checkMenuReturn(back2, rig2.flow)
        XCTAssertTrue(rig2.flow.died)
        XCTAssertNil(rig2.flow.lastAskToContinue)

        // A level whose renderer throws inside `LevelRun.tick` (`attach`): the level-load report (0x100a2e76), then
        // the loop's end and the menu return (G+4 is the fresh game's: no death).
        let rig3 = Rig(r)
        rig3.levels.failAttach = true
        rig3.toMenu()
        rig3.press(0x2d)
        let failed = rig3.drive { _ in self.asked(rig3.last) }
        XCTAssertEqual(dialogs(failed), [.report(text: GameFlow.levelLoadError)])
        XCTAssertEqual(rig3.levels.prepared, [1])
        XCTAssertNil(rig3.flow.levelRun)
        rig3.flow.dialogDone(.ok)
        let back3 = rig3.drive { $0.state == .mainMenu }
        checkMenuReturn(back3, rig3.flow)
        XCTAssertNil(rig3.flow.lastAskToContinue)
        XCTAssertTrue(rig3.flow.loopEnded)
    }

    func testContinueRefusals() throws {
        let r = try resources()
        let rig = Rig(r)
        let flow = rig.flow
        rig.toMenu()
        func url(_ n: String) -> URL { URL(fileURLWithPath: "/nonexistent/\(n)") }
        var preview = try checkpoint(r)
        preview.preview = 1
        var demo = try checkpoint(r)
        demo.demo = 1
        let eighty = try checkpoint(r, level: 80)
        var both = try checkpoint(r, level: 80)
        both.demo = 1
        var previewDemo = try checkpoint(r)
        previewDemo.preview = 1
        previewDemo.demo = 1
        var all = try checkpoint(r, level: 80)
        all.preview = 1
        all.demo = 1
        rig.files.blocks = [url("preview"): preview, url("demo"): demo, url("eighty"): eighty, url("both"): both,
                            url("previewDemo"): previewDemo, url("all"): all]
        let previewText = "Sorry, this saved game was saved with a preview version of Ferazel and can not be used with this version."
        let demoText = "Sorry, this saved game was saved with a demo version of Ferazel and can not be used with this version."
        for (name, expected) in [("preview", [previewText]), ("demo", [demoText]), ("eighty", [demoText]),
                                 ("both", [demoText, demoText]), ("previewDemo", [previewText, demoText]),
                                 ("all", [previewText, demoText, demoText])] {
            rig.press(0x0f)                                                // R
            let ask = rig.drive { _ in self.askedFile(rig.last) }
            XCTAssertEqual(ask.last?.out.requests.last,
                           .getFile(prompt: "Please select the saved game from which you would like to continue."))
            flow.fileDone(.chosen(SavedGameRef(url: url(name), displayName: name)))
            var seen: [FerazelDialog] = []
            let ticks = rig.drive { f in
                if f.state == .mainMenu { return true }
                let d = self.dialogs([Tick(t: 0, out: rig.last, segments: [])])
                if !d.isEmpty { seen += d; f.dialogDone(.ok) }
                return false
            }
            XCTAssertEqual(seen, expected.map { .report(text: $0) }, name)
            XCTAssertNil(flow.levelRun, name)
            XCTAssertTrue(rig.levels.prepared.isEmpty, name)
            XCTAssertFalse(music(ticks).contains { $0.cue == .stop }, "\(name): the menu music plays on")
            // OpenSG succeeded: the reply is kept, fe00 / fd54 set, G ← save+0x18.
            XCTAssertEqual(flow.lastReply?.url, url(name))
            XCTAssertTrue(flow.savedThisGame)
            XCTAssertTrue(flow.saveFileKnown)
            XCTAssertEqual(flow.globals.coins, 23)
        }
        // Cancel in the file dialog: back to the menu, nothing reported; a file that is no saved game → SV2's text.
        rig.press(0x1f)                                                    // O
        rig.drive { _ in self.askedFile(rig.last) }
        flow.fileDone(.cancelled)
        let cancel = rig.drive { $0.state == .mainMenu }
        XCTAssertTrue(dialogs(cancel).isEmpty)
        rig.press(0x1f)
        rig.drive { _ in self.askedFile(rig.last) }
        flow.fileDone(.chosen(SavedGameRef(url: url("junk"), displayName: "junk")))
        let junk = rig.drive { _ in self.asked(rig.last) }
        XCTAssertEqual(dialogs(junk), [.report(text: SavedGameError.notASavedGame.message)])
        flow.dialogDone(.ok)
        rig.drive { $0.state == .mainMenu }
        XCTAssertNil(flow.levelRun)
    }

    func testContinueFromCheckpoint() throws {
        let r = try resources()
        let rig = Rig(r)
        let flow = rig.flow
        rig.toMenu()
        let ref = SavedGameRef(url: URL(fileURLWithPath: "/nonexistent/cp"), displayName: "cp")
        let save = try checkpoint(r)
        rig.files.blocks[ref.url] = save
        flow.mapSprites = [MapSprite(h: 10, v: 20, type: 0, counter: 0)]
        rig.press(0x0f)
        rig.drive { _ in self.askedFile(rig.last) }
        flow.fileDone(.chosen(ref))
        let entry = rig.drive { self.isRunning($0, level: 1, iterations: 1) }
        XCTAssertEqual(flow.state, .continueGame)
        let s = try XCTUnwrap(flow.levelRun?.session)
        // One `FadeAIFFMusic(0,2)` (+ the shutdown) before the loop (M l. 7040–7041): 24 cues 2 ticks apart, `.stop`;
        // `.GameLoop`'s own fade finds no music. Then the level's track.
        let m = music(entry)
        XCTAssertEqual(m.prefix(26).map(\.cue), (0..<24).map { .volume(256 * (24 - $0) / 24) } + [.volume(0), .stop])
        XCTAssertEqual(m[24].t - m[0].t, 48)
        XCTAssertEqual(m.filter { $0.cue == .stop }.count, 1)
        // Level 1 at the saved x / y with the snapshot (the save point at face 2), no chapter card, G from the file —
        // `G+0x16` not refreshed (save+6 = 1).
        XCTAssertEqual([s.startX, s.startY], [2371, 872])
        XCTAssertTrue(try XCTUnwrap(flow.levelRun).revisit)
        XCTAssertEqual(s.world.records[24].p1, 2)
        // `restoreSnapshot(save+8)` puts the 6 back on x and y: the records stand where the level file has them.
        let L1 = try LevelFile.load(from: r, level: 1)
        XCTAssertEqual(s.world.records.map(\.x), L1.placements.map(\.x))
        XCTAssertEqual(s.world.records.map(\.y), L1.placements.map(\.y))
        XCTAssertTrue(flow.mapSprites.isEmpty, "`.InitGameGlobals`' `.InitPlayerMapData` (M l. 864) on Continue too")
        XCTAssertFalse(draws(entry).contains(.setScreenClut(id: 281)))
        XCTAssertEqual(s.globals.startFacing, 7)
        XCTAssertEqual(s.globals.coins, 23)
        XCTAssertTrue(flow.savedThisGame)
        XCTAssertEqual(flow.lastReply, ref)
        XCTAssertEqual(flow.defaultWorld, 1)
        // On to level 2 through the map: no music fade-out per level (the map's own fade aside), and `G+0x16` not
        // refreshed on the next level either (M l. 7044–7064: no `0x26c8` access).
        rig.drive { self.isRunning($0, level: 1, iterations: 45) }
        try touchExit(try XCTUnwrap(flow.levelRun?.session), record: 66)
        rig.drive { self.onIdleMap($0) }
        let mapFades = rig.log.count
        rig.drive(input: { _ in FrontInput(keys: KeyState(pressed: [0x24])) }) { $0.worldMap == nil }
        let toL2 = rig.drive { self.isRunning($0, level: 2, iterations: 1) }
        let s2 = try XCTUnwrap(flow.levelRun?.session)
        XCTAssertEqual(s2.globals.startFacing, 7)
        XCTAssertEqual([s2.startX, s2.startY], [901 - 32, 256 - 32])          // save+0xc / +0x10 after the map
        let l2Music = rig.log[mapFades...].flatMap { $0.out.music }
        // Only the map's exit fade (24 + 1 cues), the map track's stop, and level 2's track and fade-in.
        XCTAssertEqual(l2Music.filter { $0 == .stop }.count, 1)
        XCTAssertEqual(music(toL2).filter { if case .play = $0.cue { return true }; return false }.map(\.cue),
                       [.play(track: 3)])

        // Death with a save this game → the death screen (clut 132, PICT 138) → Return → WandGlow → `fd48` → the menu
        // loop's Continue with the last reply: the file read again, level 1 at the saved spot.
        // Continue's death test is `ffa8`, not G+4: G+4 put back to 1 during `.DeathEffect` still asks.
        rig.drive { self.isRunning($0, level: 2, iterations: 45) }
        try kill(s2)
        rig.drive { $0.levelRun?.died == true }
        s2.world.globals.health = 1
        let dying = rig.drive { f in f.deathScreen != nil && rig.last.draws.contains(.setScreenClut(id: DeathScreen.clutId)) }
        XCTAssertTrue(pictures(draws(dying)).contains(DeathScreen.backgroundPicture))
        XCTAssertEqual(rig.files.reads, [ref.url])
        let glow = rig.drive(input: { f in FrontInput(keys: KeyState(pressed: f.deathScreen?.chosen == nil ? [0x24] : [])) }) {
            $0.deathScreen == nil
        }
        XCTAssertEqual(pictures(draws(glow)).filter { (172...177).contains($0) },
                       [172, 173, 174, 175, 176, 177, 176, 175, 174, 173, 172])  // WandGlow
        XCTAssertTrue(flow.continueRequested)                               // `fd48`: the menu pass runs Continue
        XCTAssertEqual(flow.lastAskToContinue, true)
        let again = rig.drive { self.isRunning($0, level: 1, iterations: 1) }
        XCTAssertEqual(rig.files.reads, [ref.url, ref.url])
        XCTAssertFalse(dialogs(again).contains { if case .report = $0 { return true }; return false })
        XCTAssertFalse(again.flatMap { $0.out.requests }.contains { if case .getFile = $0 { return true }; return false })
        let s3 = try XCTUnwrap(flow.levelRun?.session)
        XCTAssertEqual([s3.startX, s3.startY], [2371, 872])
        XCTAssertEqual(s3.globals.coins, 23)
        XCTAssertEqual(s3.world.records[24].p1, 2)
        XCTAssertFalse(flow.died)
        // Dying again and choosing Abort (Esc) → TurnGray (151 CLUT frames) → Continue's menu return.
        rig.drive { self.isRunning($0, level: 1, iterations: 45) }
        try kill(s3)
        rig.drive { f in f.deathScreen != nil && rig.last.draws.contains(.setScreenClut(id: DeathScreen.clutId)) }
        let gray = rig.drive(input: { f in FrontInput(keys: KeyState(pressed: f.deathScreen?.chosen == nil ? [0x35] : [])) }) {
            $0.state == .mainMenu
        }
        XCTAssertEqual(flow.lastAskToContinue, false)
        XCTAssertEqual(draws(gray).filter { if case .screenGamma(.clut) = $0 { return true }; return false }.count, 151)
        checkMenuReturn(gray, flow, continuing: true)
        XCTAssertFalse(flow.continueRequested)
        XCTAssertEqual(rig.files.reads.count, 2)
        // New Game after a Continue clears `fe00` (and `fd54`, save+6): a death then goes straight to the menu.
        XCTAssertTrue(flow.savedThisGame)
        rig.press(0x2d)
        rig.drive { self.isRunning($0, level: 1) }
        XCTAssertFalse(flow.savedThisGame)
        XCTAssertFalse(flow.saveFileKnown)
        XCTAssertEqual(flow.saveBlock.isCheckpoint, 0)
        try kill(try XCTUnwrap(flow.levelRun?.session))
        let fresh = rig.drive { $0.state == .mainMenu }
        XCTAssertFalse(draws(fresh).contains(.setScreenClut(id: DeathScreen.clutId)))
        checkMenuReturn(fresh, flow)
        XCTAssertEqual(rig.files.reads.count, 2)

        // A block naming level 9 (no `Mlvl` 9): "An unexpected error occurred -- the level could not be loaded from the
        // world file!" (0x100a2e76, design §9 d), then the menu.
        let rig2 = Rig(r)
        rig2.toMenu()
        let ref9 = SavedGameRef(url: URL(fileURLWithPath: "/nonexistent/nine"), displayName: "nine")
        rig2.files.blocks[ref9.url] = try checkpoint(r, level: 9)
        rig2.press(0x0f)
        rig2.drive { _ in self.askedFile(rig2.last) }
        rig2.flow.fileDone(.chosen(ref9))
        let missing = rig2.drive { _ in self.asked(rig2.last) }
        XCTAssertEqual(dialogs(missing),
                       [.report(text: "An unexpected error occurred -- the level could not be loaded from the world file!")])
        rig2.flow.dialogDone(.ok)
        rig2.drive { $0.state == .mainMenu }
        XCTAssertNil(rig2.flow.levelRun)
        XCTAssertTrue(rig2.levels.prepared.isEmpty)

        // S1: a save point inside a GameFlow game. A checkpoint whose snapshot leaves record 24 unused (p1 0) and puts
        // the player on it: the flow hands `LevelRun` its file seam and fe00 / fd54 / fd18; the save panel's reply
        // goes to the level (never to the flow's own `fileAnswer`); the flags and live prefs come back at the level's end.
        func standing(_ rig: Rig, _ name: String) throws -> (SavedGameRef, FerazelSession) {
            var cp = try checkpoint(r)
            let q = cp.snapshots[1][24]
            cp.snapshots[1][24] = Placement(index: 24, flag: q.flag, byte1: q.byte1, type: q.type, p1: 0, p2: q.p2,
                                            p3: q.p3, p4: q.p4, y: q.y, x: q.x)
            cp.playerX = Int32(L1.placements[24].x) - 8
            cp.playerY = Int32(L1.placements[24].y) - 21
            let opened = SavedGameRef(url: URL(fileURLWithPath: "/nonexistent/\(name)"), displayName: name)
            rig.files.blocks[opened.url] = cp
            rig.toMenu()
            rig.press(0x0f)
            rig.drive { _ in self.askedFile(rig.last) }
            rig.flow.fileDone(.chosen(opened))
            rig.drive { _ in rig.last.requests.contains { if case .putFile = $0 { return true }; return false } }
            return (opened, try XCTUnwrap(rig.flow.levelRun?.session))
        }
        let rig3 = Rig(r)
        let (opened3, s4) = try standing(rig3, "cp3")
        XCTAssertEqual(s4.suspension, .savePoint(record: 24))
        XCTAssertEqual(rig3.flow.levelRun?.saveState, SaveGameState(savedThisGame: true, saveFileKnown: true,
                                                                    lastReply: opened3))
        let mine = SavedGameRef(url: URL(fileURLWithPath: "/nonexistent/mine"), displayName: "Mine")
        rig3.flow.fileDone(.chosen(mine))
        XCTAssertNil(rig3.flow.fileAnswer, "a level's panel reply never reaches Continue's `.OpenSG`")
        rig3.drive(max: 1) { _ in true }
        XCTAssertNil(s4.suspension)
        XCTAssertEqual(rig3.files.written[mine.url]?.level, 1)
        XCTAssertEqual(rig3.files.written[mine.url]?.snapshots[1][24].p1, s4.world.records[24].p1)
        XCTAssertNotEqual(s4.world.records[24].p1, 0)
        rig3.drive { self.isRunning($0, level: 1, iterations: 120) }
        try touchExit(try XCTUnwrap(rig3.flow.levelRun?.session), record: 66)
        rig3.drive { self.onIdleMap($0) }
        XCTAssertTrue(rig3.flow.savedThisGame)
        XCTAssertTrue(rig3.flow.saveFileKnown)
        XCTAssertEqual(rig3.flow.lastReply, mine)
        XCTAssertEqual(rig3.flow.toggles.live.savedGameName, "Mine")
        // Cancelled: nothing written, the point re-armed, fd18 still the file Continue opened.
        let rig4 = Rig(r)
        let (opened4, s5) = try standing(rig4, "cp4")
        rig4.flow.fileDone(.cancelled)
        XCTAssertNil(rig4.flow.fileAnswer)
        rig4.drive(max: 1) { _ in true }
        XCTAssertNil(s5.suspension)
        XCTAssertTrue(rig4.files.written.isEmpty)
        XCTAssertEqual(s5.world.records[24].p1, 0)
        XCTAssertEqual(rig4.flow.levelRun?.saveState.lastReply, opened4)
        XCTAssertEqual(rig4.flow.toggles.live.savedGameName, FerazelPrefs().savedGameName)
        // A failing write: the level's error report reaches the App through the flow, and its answer goes back to the
        // level (`GameFlow.dialogDone` while a level runs), which then finishes the frame with the point re-armed.
        let rig5 = Rig(r)
        rig5.files.failWrite = SaveWriteError.volumeLocked
        let (_, s6) = try standing(rig5, "cp5")
        let other = SavedGameRef(url: URL(fileURLWithPath: "/nonexistent/other"), displayName: "Other")
        rig5.flow.fileDone(.chosen(other))
        rig5.drive(max: 1) { _ in true }
        XCTAssertEqual(rig5.last.requests.last,
                       .dialog(.error(text: "The game could not be saved, because the volume is locked.",
                                      code: SaveWriteError.volumeLocked)))
        XCTAssertEqual(s6.suspension, .savePoint(record: 24))
        rig5.flow.dialogDone(.ok)
        rig5.drive(max: 1) { _ in true }
        XCTAssertNil(s6.suspension)
        XCTAssertEqual(s6.world.records[24].p1, 0)
        XCTAssertTrue(rig5.files.written.isEmpty)
        XCTAssertEqual(rig5.flow.levelRun?.saveState.lastReply, other)
    }
}
