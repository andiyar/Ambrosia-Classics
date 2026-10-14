import XCTest
@testable import FerazelCore

/// M1 (docs/plans/2026-10-14-ferazel-phase3.md): `WorldMapRun` — `.ShowWorldMap @ 1007c494` (M l. 67432–67658) and its
/// callees (`.MakeNodeSprites`, `.UpdateNodeSprites`, `.DrawNewLink`, `.FindPlayerNodeLoc`, `.CheckPlayerNodeMovement`,
/// M l. 66670–67429) as a tick machine. Driven tick by tick against the committed `Resources/Ferazel` (D26). A missing
/// data file is a FAILURE, never a skip.
final class WorldMapRunTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// G after `.NewGame` and the levels played: `unlocked[1]` (`.InitGameGlobals`) plus each `unlocked[L]` the
    /// `.GameLoop` set (M l. 5180).
    private func globals(played: [Int]) -> GameGlobals {
        var g = GameGlobals.initGameGlobals(previous: nil)
        for l in played { g.unlocked[l] = 1 }
        return g
    }

    private func make(_ r: FerazelResources, level: Int16, exit1: Int16, exit2: Int16 = -1, globals g: GameGlobals,
                      prefs: FerazelPrefs = FerazelPrefs(), seed: Int32 = 1,
                      levelComplete: Bool = true) throws -> WorldMapRun {
        var fade = ScreenFade()
        fade.faded = true                                   // the level's completion ends in `GammaFadeOut(6)`
        let name = try LevelFile.load(from: r, level: level).header.name
        return try WorldMapRun(resources: r, prefs: prefs, globals: g, level: level, levelName: name, exit1: exit1,
                               exit2: exit2, levelComplete: levelComplete, seed: seed, fade: fade,
                               music: MusicFade())
    }

    private struct Tick {
        let t: UInt32
        let out: WorldMapOutput
        /// The loop iterations run so far (after the tick).
        let iterations: Int
    }

    /// Ticks `run` from `t0` until `until` holds (checked after each tick) or `max` ticks.
    @discardableResult
    private func drive(_ run: WorldMapRun, from t0: UInt32 = 1000, max: Int = 2000,
                       input: (UInt32) -> FrontInput = { _ in FrontInput() },
                       until: (WorldMapRun) -> Bool) -> [Tick] {
        var ticks: [Tick] = []
        var t = t0
        for _ in 0..<max {
            let o = run.tick(now: t, input: input(t))
            ticks.append(Tick(t: t, out: o, iterations: run.iterations))
            if until(run) { break }
            t &+= 1
        }
        return ticks
    }

    private func markers(_ ops: [MapOp]) -> [(h: Int, v: Int)] {
        ops.compactMap {
            if case .draw(.drawFace(set: .mapMarker, index: _, h: let h, v: let v), port: .work) = $0 { return (h, v) }
            return nil
        }
    }

    private func statusNames(_ ops: [MapOp]) -> [String] {
        ops.compactMap { if case .draw(.statusBar(let s), port: .screen) = $0 { return s.levelName }; return nil }
    }

    private func flashLines(_ ops: [MapOp]) -> [(h1: Int, v1: Int, h2: Int, v2: Int, rgb: RGB16)] {
        ops.compactMap {
            if case .draw(.drawLine(h1: let a, v1: let b, h2: let c, v2: let d, rgb: let rgb), port: .work) = $0 {
                return (a, b, c, d, rgb)
            }
            return nil
        }
    }

    private func keys(_ codes: Int...) -> FrontInput { FrontInput(keys: KeyState(pressed: codes)) }

    /// The tick the loop's first iteration ran.
    private func firstLoopTick(_ ticks: [Tick]) -> Int? { ticks.firstIndex { $0.iterations > 0 } }

    // MARK: - Tests

    func testNodeTableAndNames() throws {
        let r = try resources()
        let map = try WorldMap.load(from: r)
        XCTAssertEqual(map.nodes.count, 24)
        XCTAssertEqual(map.nodes.filter { $0.face == 1 }.map(\.index), [5, 18, 25, 55, 62])
        // `.FindCurrNode` (M l. 67144–67163): the first existing node whose level matches.
        XCTAssertEqual(map.findCurrNode(level: 62)?.index, 60)
        XCTAssertEqual(map.findCurrNode(level: 67)?.index, 62)
        XCTAssertEqual(map.findCurrNode(level: 1)?.index, 1)
        XCTAssertNil(map.findCurrNode(level: 63))
        XCTAssertEqual(map.node(2)?.links.filter { $0 != 0 }, [1, 3, 4])
        XCTAssertNil(map.node(0))
        XCTAssertNil(map.node(128))
        // Node 1 at (h 237, v 307): the table stores (v, h).
        XCTAssertEqual(map.node(1).map { [Int($0.h), Int($0.v)] }, [237, 307])
        // `STR# 1000` (`.InitMapLevelNames`, GetIndString 1-based).
        let run = try make(r, level: 1, exit1: 0, globals: globals(played: [1]))
        XCTAssertEqual(run.levelNames.strings.count, 99)
        XCTAssertEqual(run.levelNames.string(1), "A Scent of Peril")
        XCTAssertEqual(run.levelNames.string(2), "Central Caverns")
        XCTAssertEqual(run.levelNames.string(51), "If You Can't Stand The Heat\u{2026}")
        // The Mlvl spelling differs (BC14): the status bar shows it until the map's name update.
        XCTAssertEqual(run.levelName, "A Scent Of Peril")
    }

    func testDirectionsFromNode2() throws {
        let r = try resources()
        let map = try WorldMap.load(from: r)
        let g = globals(played: [1, 2, 3, 4])
        let prefs = FerazelPrefs()
        func move(_ k: [Int], _ gg: GameGlobals = g) -> Int16 {
            WorldMapRun.checkPlayerNodeMovement(map: map, node: 2, globals: gg, keys: KeyState(pressed: k), prefs: prefs)
        }
        // Arrows (0x7b left, 0x7c right, 0x7e up, 0x7d down) and the default action keys 0–3 (0x56, 0x58, 0x5b, 0x57).
        XCTAssertEqual(move([0x7b]), 1)                       // node 1: above-left, |dv| 23 < |dh| 32 → (left, up)
        XCTAssertEqual(move([0x7c]), 4)                       // node 4: v 329 < 330 → above-right (right, up)
        XCTAssertEqual(move([0x7d]), 3)                       // node 3: below-left (left, down) — pass 2
        XCTAssertEqual(move([0x7e]), 1)                       // pass 2: node 1's secondary up comes first (slot 0)
        XCTAssertEqual(move([0x56]), 1)
        XCTAssertEqual(move([0x58]), 4)
        XCTAssertEqual(move([0x57]), 3)
        XCTAssertEqual(move([0x5b]), 1)
        XCTAssertEqual(move([]), 0)
        // A locked target is skipped: with level 1 locked, up falls to node 4's secondary.
        var locked = g
        locked.unlocked[1] = 0
        XCTAssertEqual(move([0x7e], locked), 4)
        XCTAssertEqual(move([0x7b], locked), 3)               // pass 1: node 3's primary left
        // Primary beats secondary across slots: left + down → node 1 (pass 1), not node 3.
        XCTAssertEqual(move([0x7b, 0x7d]), 1)
    }

    func testWalkTwentyNineFrames() throws {
        let r = try resources()
        let run = try make(r, level: 1, exit1: 0, globals: globals(played: [1]))
        let ticks = drive(run) { $0.iterations >= 31 }
        // The entry frame: the marker at node 1 (h 237 − 20, v 307 − 20).
        XCTAssertEqual(markers(ticks[0].out.ops).map { [$0.h, $0.v] }, [[217, 287]])
        guard let first = firstLoopTick(ticks) else { return XCTFail("the loop never ran") }
        // Every marker draw before the loop (entry, the 50 flashes, the flash end) is at node 1.
        let before = ticks[..<first].flatMap { markers($0.out.ops) }
        XCTAssertTrue(before.allSatisfy { $0.h == 217 && $0.v == 287 })
        // One drawn frame per loop iteration: steps 2…30 (29 frames), then node 2.
        let expected: [(Int, Int)] = [
            (238, 308), (239, 309), (240, 310), (241, 310), (242, 311), (243, 312), (244, 313), (245, 313), (247, 314),
            (248, 315), (249, 316), (250, 316), (251, 317), (252, 318), (253, 319), (254, 320), (255, 320), (256, 321),
            (258, 322), (259, 323), (260, 323), (261, 324), (262, 325), (263, 326), (264, 326), (265, 327), (266, 328),
            (267, 329), (269, 330)]
        let frames = ticks[first...].filter { !markers($0.out.ops).isEmpty }
        XCTAssertGreaterThanOrEqual(frames.count, 31)
        for (k, e) in expected.enumerated() {
            // Frame 0's tick also ends `.DrawNewLink` (two `.DrawNodeSprites` at node 1, M l. 67262–67268).
            let m = markers(frames[k].out.ops)
            XCTAssertEqual(m.count, k == 0 ? 3 : 1, "frame \(k)")
            XCTAssertEqual(m.last.map { [$0.h + 20, $0.v + 20] }, [e.0, e.1], "frame \(k) (step \(k + 2))")
            XCTAssertEqual(frames[k].t, frames[0].t + UInt32(k), "one frame per tick")
        }
        // Frames 30 and 31: at rest on node 2.
        XCTAssertEqual(markers(frames[29].out.ops).map { [$0.h, $0.v] }, [[249, 310]])
        // The name update runs on the step-30 iteration (frame 29 = index 28), not before.
        XCTAssertFalse(statusNames(frames[27].out.ops).contains("Central Caverns"))
        XCTAssertEqual(statusNames(frames[28].out.ops), ["Central Caverns", "Central Caverns"])
        XCTAssertEqual(run.cur, 2)
        XCTAssertEqual(run.walkTarget, 2)
        XCTAssertEqual(run.walkStep, 0)
    }

    func testUnlockAfterLevel1() throws {
        let r = try resources()
        let g = globals(played: [1])
        XCTAssertEqual(g.unlocked[2], 0)
        let run = try make(r, level: 1, exit1: 0, globals: g)
        let ticks = drive(run) { $0.iterations >= 30 }
        XCTAssertEqual(run.globals.unlocked[2], 1)
        XCTAssertEqual(run.exit1, -1)
        XCTAssertEqual(run.exit2, -1)
        // Entry: clut 700, PICT 129, status bar, PICT 7000 into the background, the music, `GammaFadeIn(15)`.
        let entry = ticks[0].out
        XCTAssertEqual(entry.ops.first, .portsClut(id: 700))
        XCTAssertTrue(entry.ops.contains(.draw(.setScreenClut(id: 700), port: .screen)))
        XCTAssertTrue(entry.ops.contains(.draw(.drawPicture(id: 129, chain: .frontEnd, h: 0, v: 0), port: .screen)))
        XCTAssertTrue(entry.ops.contains {
            if case .draw(.copyPicture(id: 7000, chain: .frontEnd, source: _, dest: let d, forceClut: nil,
                                       transparent: false), port: .background) = $0 {
                return d == Rect16(top: 0, left: 0, bottom: 384, right: 608)
            }
            return false
        })
        XCTAssertEqual(entry.output.music, [.play(track: 25), .volume(0)])
        // DrawNewLink: one snd 420, 50 iterations of three lines 2 ticks apart, all of one colour each.
        let all = ticks.flatMap(\.out.output.sounds)
        XCTAssertEqual(all.map(\.snd), [420])
        XCTAssertEqual(all.first?.priority, 1)
        let flashTicks = ticks.filter { !flashLines($0.out.ops).isEmpty }
        XCTAssertEqual(flashTicks.count, 50)
        XCTAssertEqual(flashTicks.first.map { $0.out.output.sounds.map(\.snd) }, [420])
        var rng = FastRand(seed: 1)
        _ = rng.next(15); _ = rng.next(15)                   // nodes 1 and 2
        for (k, t) in flashTicks.enumerated() {
            if k > 0 { XCTAssertEqual(t.t, flashTicks[k - 1].t + 2) }
            let lines = flashLines(t.out.ops)
            let rgb = RGB16(red: UInt16(truncatingIfNeeded: Int(rng.next(32000)) << 1),
                            green: UInt16(truncatingIfNeeded: Int(rng.next(32000)) << 1),
                            blue: UInt16(truncatingIfNeeded: Int(rng.next(32000)) << 1))
            // Centre, −1/−1, +1/+1, node 1 (237, 307) → node 2 (269, 330).
            XCTAssertEqual(lines.map { [$0.h1, $0.v1, $0.h2, $0.v2] },
                           [[237, 307, 269, 330], [236, 306, 268, 329], [238, 308, 270, 331]], "flash \(k)")
            XCTAssertTrue(lines.allSatisfy { $0.rgb == rgb }, "flash \(k)")
            // The dirty rect: bbox ± 10, copied to the screen at (+16, +8).
            XCTAssertTrue(t.out.ops.contains(.copy(from: .work, to: .screen,
                                                   source: Rect16(top: 297, left: 227, bottom: 340, right: 279),
                                                   dest: Rect16(top: 305, left: 243, bottom: 348, right: 295))))
        }
        XCTAssertEqual(run.rng.seed, rng.seed)
        // Then the auto-walk: the name stays the Mlvl spelling until arrival.
        guard let first = firstLoopTick(ticks) else { return XCTFail("the loop never ran") }
        XCTAssertGreaterThanOrEqual(Int(ticks[first].t) - Int(flashTicks[49].t), 2)
        let names = ticks[first...].flatMap { statusNames($0.out.ops) }
        let arrival = try XCTUnwrap(names.firstIndex(of: "Central Caverns"))
        XCTAssertEqual(arrival, 28)                           // 28 walking frames show only `UpdateStatusBar(1,0,0)`
        XCTAssertTrue(names[..<arrival].allSatisfy { $0 == "A Scent Of Peril" })
        XCTAssertEqual(run.cur, 2)
    }

    func testLevel2ExitsUnlock3And4() throws {
        let r = try resources()
        for (exit, node) in [(Int16(1), 3), (Int16(2), 4)] {
            let run = try make(r, level: 2, exit1: exit, globals: globals(played: [1, 2]))
            drive(run) { $0.iterations >= 31 }
            XCTAssertEqual(run.globals.unlocked[node], 1, "exit \(exit)")
            XCTAssertEqual(run.globals.unlocked[node == 3 ? 4 : 3], 0, "exit \(exit)")
            XCTAssertEqual(run.cur, node, "exit \(exit)")
            XCTAssertEqual(run.walkStep, 0)
            XCTAssertEqual(run.levelName, run.levelNames.string(node))
        }
    }

    func testTwoExitsNoAutoWalk() throws {
        let r = try resources()
        let run = try make(r, level: 15, exit1: 1, exit2: 2, globals: globals(played: [1, 2, 4, 5, 10, 15]))
        let ticks = drive(run) { $0.iterations >= 5 }
        XCTAssertEqual(run.globals.unlocked[20], 1)
        XCTAssertEqual(run.globals.unlocked[30], 1)
        XCTAssertEqual(ticks.flatMap(\.out.output.sounds).map(\.snd), [420, 420])
        XCTAssertEqual(ticks.filter { !flashLines($0.out.ops).isEmpty }.count, 100)
        // The marker stays on node 15 (h 358, v 235).
        XCTAssertEqual(run.cur, 15)
        XCTAssertEqual(run.walkTarget, 15)
        XCTAssertEqual(run.walkStep, 0)
        guard let first = firstLoopTick(ticks) else { return XCTFail("the loop never ran") }
        let loopMarkers = ticks[first...].flatMap { markers($0.out.ops) }
        XCTAssertGreaterThanOrEqual(loopMarkers.count, 5)
        XCTAssertTrue(loopMarkers.allSatisfy { $0.h == 338 && $0.v == 215 })
        XCTAssertEqual(statusNames(ticks[first].out.ops).first, run.levelNames.string(15))
    }

    func testMapExitKeys() throws {
        let r = try resources()
        // Idle: Return, Enter, Option (action 5), ⌘ (action 6) end the loop with the current node's level.
        for k in [0x24, 0x4c, 0x3a, 0x37] {
            let run = try make(r, level: 1, exit1: -1, globals: globals(played: [1]))
            let ticks = drive(run) { $0.iterations >= 3 }
            let t = (ticks.last?.t ?? 0) + 1
            drive(run, from: t, input: { _ in self.keys(k) }) { $0.result != nil }
            XCTAssertEqual(run.result, 1, "key \(k)")
            XCTAssertFalse(run.quitRequested)
            XCTAssertTrue(run.sprites.isEmpty, "the node-sprite count is reset on exit (M l. 67652)")
            XCTAssertFalse(run.onMap)
        }
        // Ignored while walking: Return held from the start still walks all 29 frames, then enters level 2.
        do {
            let run = try make(r, level: 1, exit1: 0, globals: globals(played: [1]))
            let ticks = drive(run, input: { _ in self.keys(0x24) }) { $0.result != nil }
            XCTAssertEqual(run.result, 2)
            XCTAssertEqual(run.iterations, 29)
            // The exit's `FadeAIFFMusic(0, 2)`: 48 ticks.
            XCTAssertEqual(ticks.flatMap(\.out.output.music).suffix(25).first, .volume(MusicFade.fullVolume(FerazelPrefs())))
        }
        // Esc → the abort confirm → OK → −1; Cancel → `HideCursorSafe`, the map goes on.
        for ok in [true, false] {
            let run = try make(r, level: 1, exit1: -1, globals: globals(played: [1]))
            let ticks = drive(run) { $0.iterations >= 2 }
            var t = (ticks.last?.t ?? 0) + 1
            let o = run.tick(now: t, input: keys(0x35))
            XCTAssertEqual(o.output.requests,
                           [.showCursor, .dialog(.confirm(text: "Are you sure you want to abort this game?"))])
            t += 1
            XCTAssertEqual(run.tick(now: t, input: FrontInput()).ops, [], "the flow waits on the dialog")
            run.dialogDone(ok: ok)
            t += 1
            let after = run.tick(now: t, input: FrontInput())
            XCTAssertTrue(after.ops.contains(.copy(from: .work, to: .screen, source: WorldMapRun.viewRect,
                                                   dest: Rect16(top: 8, left: 16, bottom: 392, right: 624))))
            if ok {
                drive(run, from: t + 1) { $0.result != nil }
                XCTAssertEqual(run.result, -1)
                XCTAssertTrue(run.aborted)
                XCTAssertFalse(run.quitRequested)
            } else {
                XCTAssertEqual(after.output.requests.first, .hideCursor)
                XCTAssertNil(run.result)
                XCTAssertFalse(run.aborted)
            }
        }
        // ⌘Q down in the same iteration → the quit confirm → OK: abort + the quit flag. Esc+Q reaches it too.
        for combo in [[0x37, 0x0c], [0x35, 0x0c]] {
            let run = try make(r, level: 1, exit1: -1, globals: globals(played: [1]))
            let ticks = drive(run) { $0.iterations >= 2 }
            var t = (ticks.last?.t ?? 0) + 1
            let o = run.tick(now: t, input: FrontInput(keys: KeyState(pressed: combo)))
            XCTAssertEqual(o.output.requests, [.showCursor, .dialog(.confirm(text: "Are you sure you want to quit?"))])
            run.dialogDone(ok: true)
            t += 1
            drive(run, from: t) { $0.result != nil }
            XCTAssertEqual(run.result, -1)
            XCTAssertTrue(run.quitRequested)
        }
        // The held-⌘ quirk: ⌘ alone one tick, Q the next → the level is entered, no confirm.
        do {
            let run = try make(r, level: 1, exit1: -1, globals: globals(played: [1]))
            let ticks = drive(run) { $0.iterations >= 2 }
            let t = (ticks.last?.t ?? 0) + 1
            let o = run.tick(now: t, input: keys(0x37))
            XCTAssertFalse(o.output.requests.contains { if case .dialog = $0 { return true }; return false })
            drive(run, from: t + 1, input: { _ in self.keys(0x37, 0x0c) }) { $0.result != nil }
            XCTAssertEqual(run.result, 1)
            XCTAssertFalse(run.quitRequested)
        }
        // A second map entry starts with only its own node sprites (ambient + 2 nodes + marker).
        let second = try make(r, level: 1, exit1: -1, globals: globals(played: [1, 2]))
        let o = second.tick(now: 5000, input: FrontInput())
        XCTAssertEqual(second.sprites.count, 4)
        XCTAssertEqual(markers(o.ops).count, 1)
        // `*_DAT_100a0088` clear → "Error showing world map", returns 1.
        let bad = try make(r, level: 1, exit1: -1, globals: globals(played: [1]), levelComplete: false)
        XCTAssertEqual(bad.tick(now: 1, input: FrontInput()).output.requests,
                       [.dialog(.error(text: "Error showing world map", code: 0))])
        bad.dialogDone(ok: true)
        _ = bad.tick(now: 2, input: FrontInput())
        XCTAssertEqual(bad.result, 1)
    }

    func testMapDrawsPerVisibleNode() throws {
        let r = try resources()
        let run = try make(r, level: 1, exit1: 0, globals: globals(played: [1]))
        let entry = run.tick(now: 1000, input: FrontInput())
        // After level 1: nodes 1 and 2 visible → two `FastRand(15)` (node order), before the 150 flash draws.
        var rng = FastRand(seed: 1)
        let c1 = rng.next(15), c2 = rng.next(15)
        XCTAssertEqual(run.sprites.map(\.type), [100, 0, 0, 0x45])
        XCTAssertEqual(run.sprites.map(\.counter), [-3, c1 + 1, c2 + 1, 0])
        XCTAssertNil(run.sprites[0].face)                    // the ambient's −3: no face
        XCTAssertEqual(run.sprites[1].face?.set, .mapNode)
        XCTAssertEqual(run.sprites[1].face?.index, Int(c1 + 1) >> 1)
        XCTAssertEqual(run.sprites[1].h, 217)
        XCTAssertEqual(run.sprites[1].v, 287)
        XCTAssertEqual(run.sprites[2].h, 249)
        XCTAssertEqual(run.sprites[2].v, 310)
        // The first frame: three faces into the work port (no ambient), no link redraw.
        let faces = entry.ops.compactMap { op -> FrontFaceSet? in
            if case .draw(.drawFace(set: let s, index: _, h: _, v: _), port: .work) = op { return s }
            return nil
        }
        XCTAssertEqual(faces, [.mapNode, .mapNode, .mapMarker])
        XCTAssertFalse(entry.ops.contains { if case .redrawLinks = $0 { return true }; return false })
        // The link 1–2 drawn into the background from both ends.
        let links = entry.ops.compactMap { op -> MapLink? in if case .drawLink(let l) = op { return l }; return nil }
        XCTAssertEqual(links, [MapLink(h1: 237, v1: 307, h2: 269, v2: 330), MapLink(h1: 269, v1: 330, h2: 237, v2: 307)])
        // The flashes then draw 150 more.
        drive(run, from: 1001) { $0.iterations >= 1 }
        for _ in 0..<150 { _ = rng.next(32000) }
        XCTAssertEqual(run.rng.seed, rng.seed)
        XCTAssertEqual(run.rng.seed, 0x7b05_2a62)             // self-derived on first green (seed 1, 152 draws)
        // From about the fourth frame on, the ambient has a face and every draw redraws the links.
        drive(run, from: 2000) { $0.iterations >= 6 }
        XCTAssertNotNil(run.sprites[0].face)
        XCTAssertTrue(run.sprites[0].redrawsLinks)
    }
}
