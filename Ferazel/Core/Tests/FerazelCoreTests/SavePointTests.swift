import XCTest
@testable import FerazelCore

/// S1 (docs/plans/2026-10-14-ferazel-phase3.md): the resumable frame (`FrameSuspension`, Invariant 6) and the save
/// point — `.HitPlayerSprite`'s Box arm for type 0x429 (M l. 49471–49504, raw `10057714..10057858`), the hold counter
/// `*_DAT_100a0684` (decay raw `1004de68..1004de98`), `.SavePointSave @ 1000c104` (M l. 6322ff), `.SaveSG @ 10048294`
/// (M l. 41179ff), the success flash and the statue faces (`.HandleBoxSprite` M l. 60191–60195); save-continue §2.1,
/// §3.1, §9.1, §9.2 (BC1, BC6, BC22, BC23). Driven against the committed `Resources/Ferazel` (D26). A missing data
/// file is a FAILURE, never a skip.
final class SavePointTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// The renderer side (Core tests: the session's default face bounds, no particle faces).
    private final class StubServices: LevelServices {
        func prepare(level: Int) throws -> LevelFaces { LevelFaces() }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {}
        func deathEffectStep(_ k: Int) throws {}
    }

    /// Prefs and saved games in memory; every write recorded; `failWrite` makes the saved-game write fail.
    private final class Files: FrontFiles {
        var prefs: Data?
        var blocks: [URL: SaveBlock] = [:]
        var writes: [URL] = []
        var prefsWrites = 0
        var failWrite: Int16?
        func loadPrefs() -> Data? { prefs }
        func storePrefs(_ record: Data) throws {
            prefs = record
            prefsWrites += 1
        }
        func readSavedGame(_ ref: SavedGameRef) throws -> SaveBlock {
            guard let b = blocks[ref.url] else { throw SavedGameError.notASavedGame }
            return b
        }
        func writeSavedGame(_ block: SaveBlock, to ref: SavedGameRef) throws(SaveWriteError) {
            writes.append(ref.url)
            blocks[ref.url] = nil                                   // `FSpDelete` first (`SavedGameFile.write`)
            if let e = failWrite { throw SaveWriteError(osErr: e) }
            blocks[ref.url] = block
        }
    }

    private static let saveType: Int16 = 0x429

    /// The player's start standing on the save point of `record`: his hot rect (0x26, 0x22)–(0x3e, 0x55) one pixel
    /// into the point's (0x21, 0x3f)–(0x33, 99), centred over it.
    private func onPoint(_ p: Placement) -> (x: Int, y: Int) { (Int(p.x) - 8, Int(p.y) + 0x3f - 0x55 + 1) }

    private func session(_ r: FerazelResources, level: Int = 1, record: Int = 24, hosted: Bool = false,
                         prefs: FerazelPrefs = FerazelPrefs(), facingLeft: Bool = false) throws -> FerazelSession {
        let L = try LevelFile.load(from: r, level: Int16(level))
        var carry = LevelCarry()
        if facingLeft {
            // A carried G with `G+0x16` = 1 (not refreshed): `.SetupPlayerSprite` spawns him facing left.
            var g = GameGlobals(header: L.header)
            g.startFacing = 1
            carry.globals = g
        }
        return try FerazelSession(resources: r, prefs: prefs, level: level, carry: carry,
                                  start: onPoint(L.placements[record]), refreshFacing: !facingLeft,
                                  hostedByLevelRun: hosted)
    }

    /// Steps until the save point suspends the frame; the hold counter after each whole step before it.
    private func stepToFire(_ s: FerazelSession, max: Int = 200) -> (holds: [Int16], ops: FrameOps?) {
        var holds: [Int16] = []
        for _ in 0..<max {
            let ops = s.step(keys: KeyState())
            if ops.suspension != nil { return (holds, ops) }
            holds.append(s.player.savePointHold)
        }
        return (holds, nil)
    }

    private func isGammaStep(_ op: DrawOp) -> Bool { if case .gammaStep = op { true } else { false } }

    /// Two partial ops of one iteration as one (the stops re-based on the sounds before them).
    private func joined(_ a: FrameOps, _ b: FrameOps) -> FrameOps {
        var j = a
        j.draws += b.draws
        for (i, snd) in b.soundStops.enumerated() {
            j.soundStops.append(snd)
            j.soundStopAt.append(a.sounds.count + b.soundStopAt[i])
        }
        j.sounds += b.sounds
        j.music += b.music
        j.requests += b.requests
        j.suspension = b.suspension
        return j
    }

    private func make(_ r: FerazelResources, level: Int, record: Int, prefs: FerazelPrefs, files: Files,
                      state: SaveGameState = SaveGameState(), date: UInt32 = 0xb5c0_0000,
                      music: MusicFade = MusicFade()) throws -> LevelRun {
        let L = try LevelFile.load(from: r, level: Int16(level))
        return try LevelRun(resources: r, prefs: prefs, level: level, seed: 1, carry: LevelCarry(), save: SaveBlock(),
                            fade: ScreenFade(), music: music, services: StubServices(),
                            sounds: StageSounds(prefs: prefs, lengths: [:]), start: onPoint(L.placements[record]),
                            date: { date }, files: files, saveState: state)
    }

    /// Ticks `run` until `until` holds; every tick's merged output.
    private func drive(_ run: LevelRun, from t0: UInt32, max: Int = 6000,
                       until: (LevelRun, FrontOutput) -> Bool) throws -> (t: UInt32, outs: [FrontOutput]) {
        var outs: [FrontOutput] = []
        var t = t0
        for _ in 0..<max {
            let o = try run.tick(now: t, input: FrontInput()).merged
            outs.append(o)
            if until(run, o) { return (t, outs) }
            t &+= 1
        }
        XCTFail("the run did not reach the condition in \(max) ticks")
        return (t, outs)
    }

    private func putFile(_ o: FrontOutput) -> PutFileRequest? {
        for r in o.requests { if case .putFile(let p) = r { return p } }
        return nil
    }

    private func tempRef(_ name: String) -> SavedGameRef {
        SavedGameRef(url: FileManager.default.temporaryDirectory.appendingPathComponent("s1-\(UUID().uuidString)"),
                     displayName: name)
    }

    // MARK: -

    func testSavePointRecordsLevels1And2() throws {
        let r = try resources()
        let expected: [Int: [Int]] = [1: [24, 70], 2: [68, 76, 81]]
        for (level, recs) in expected {
            let L = try LevelFile.load(from: r, level: Int16(level))
            XCTAssertEqual(L.placements.filter { $0.type == Self.saveType }.map(\.index), recs, "level \(level)")
            for i in recs {
                let p = L.placements[i]
                XCTAssertEqual(p.p1, 0, "level \(level) rec \(i)")
                let e = try SetupFaces.setup(p, context: SetupFaces.Context(level: L, playerX: 0))
                XCTAssertEqual(e.slot.hotRect, IdleSprites.Rect(top: 0x3f, left: 0x21, bottom: 99, right: 0x33))
                XCTAssertEqual(e.slot.gravity, 0)
                XCTAssertTrue(e.slot.oneWay)
                XCTAssertEqual(e.slot.handler, .box)
                XCTAssertEqual(e.slot.face, FaceRef(pict: Self.saveType, index: 0, set: .encoded))
            }
        }
        let L1 = try LevelFile.load(from: r, level: 1)
        XCTAssertEqual([L1.placements[24].x, L1.placements[24].y], [2377, 878])
        XCTAssertEqual([L1.placements[70].x, L1.placements[70].y], [5134, 435])

        // `.HandleBoxSprite`'s 0x429 arm (M l. 60191–60195): `+0xc0 = face base + p1·0x34` every frame — the face
        // follows the live record (1 statue facing right, 2 facing left); then the shared tail `LAB_1006f948`.
        let s = try session(r)
        let w = s.world
        let e = try SetupFaces.setup(L1.placements[24], context: SetupFaces.Context(level: L1, playerX: 0))
        let id = w.active.insert(e.slot)
        for p1: Int16 in [2, 1, 0] {
            let p = w.records[24]
            w.records[24] = Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: p1, p2: p.p2,
                                      p3: p.p3, p4: p.p4, y: p.y, x: p.x)
            BoxSprite.handle(world: w, id: id)
            XCTAssertEqual(w.active.sprite(id: id)?.face, FaceRef(pict: Self.saveType, index: Int(p1), set: .encoded))
        }
    }

    func testHoldFiresOn15thLanding() throws {
        let r = try resources()
        let s = try session(r)
        // `G+0x16` holding a value no facing has: the fire must overwrite it with the facing (raw `100577b0`).
        s.world.globals.startFacing = 7
        // C after each landing frame: the handler pass moves it toward 0, the landing adds 2 → 2, 3 … 15; the 15th
        // landing makes 16 > 15 (`cmpwi 0xf; ble`, raw `10057768`) and fires inside the special pass.
        let (holds, fired) = stepToFire(s)
        XCTAssertEqual(holds, (2...15).map { Int16($0) })
        let ops = try XCTUnwrap(fired)
        XCTAssertEqual(ops.suspension, .savePoint(record: 24))
        XCTAssertEqual(s.player.savePointHold, -150)
        let pid = try XCTUnwrap(s.world.playerID)
        let facing: Int16 = s.world.active.sprite(id: pid)!.mirrored ? 1 : 0
        XCTAssertEqual(s.world.records[24].p1, facing + 1)
        XCTAssertEqual(s.globals.startFacing, facing)
        // `ShowCursorSafe` (raw `100577a4`) before `.SavePointSave`: the cursor is up while the dialog runs.
        XCTAssertEqual(ops.requests.last, .showCursor)
        XCTAssertNotNil(s.suspension)
        // Cancelled: p1 back to 0 (raw `1005783c`), `HideCursorSafe` (raw `10057858`); the frame finishes.
        let rest = s.resume(.savePoint(saved: false))
        XCTAssertNil(rest.suspension)
        // The pass went on from the next contact: the save point was not hit (landed on) again — C still −150.
        XCTAssertEqual(s.player.savePointHold, -150)
        XCTAssertNil(s.suspension)
        XCTAssertEqual(s.world.records[24].p1, 0)
        XCTAssertEqual(rest.requests.first, .hideCursor)
        XCTAssertTrue(rest.draws.contains { if case .statusBar = $0 { true } else { false } })

        // Facing left (`+0x17e` = 1): p1 = 2, `G+0x16` = 1; saved, the Box Handle shows the statue facing left (face 2)
        // from the next frame's handle pass (save-continue §9.1).
        let left = try session(r, facingLeft: true)
        XCTAssertEqual(left.globals.startFacing, 1)
        let (lholds, lfired) = stepToFire(left)
        XCTAssertEqual(lholds, (2...15).map { Int16($0) })
        XCTAssertNotNil(lfired)
        XCTAssertEqual(left.world.records[24].p1, 2)
        XCTAssertEqual(left.globals.startFacing, 1)
        _ = left.resume(.savePoint(saved: true))
        XCTAssertEqual(left.world.records[24].p1, 2)
        _ = left.step(keys: KeyState())
        let point = try XCTUnwrap(left.active.sprites.first { $0.recordIndex == 24 })
        XCTAssertEqual(point.face, FaceRef(pict: Self.saveType, index: 2, set: .encoded))
        // Facing right: the statue facing right (face 1), `G+0x16` = 0.
        let right = try session(r)
        guard stepToFire(right).ops != nil else { return XCTFail("no fire") }
        _ = right.resume(.savePoint(saved: true))
        _ = right.step(keys: KeyState())
        XCTAssertEqual(right.active.sprites.first { $0.recordIndex == 24 }?.face,
                       FaceRef(pict: Self.saveType, index: 1, set: .encoded))
        XCTAssertEqual(right.globals.startFacing, 0)

        // `resume` continues the session's pass from the next contact, never from the first: the level exit 0xcb1 on
        // the player too, met before the save point in the pass, is hit once in the frame (one snd 421), not again.
        let x = try session(r)
        for _ in 0..<14 { _ = x.step(keys: KeyState()) }
        let L1 = try LevelFile.load(from: r, level: 1)
        var exit = try SetupFaces.setup(L1.placements[66], context: SetupFaces.Context(level: L1, playerX: 0)).slot
        let xp = try XCTUnwrap(x.world.active.sprite(id: try XCTUnwrap(x.world.playerID)))
        exit.x = xp.x
        exit.y = xp.y
        exit.layer = -1000                                              // ahead of the save point in list order
        x.world.active.insert(exit)
        let xb = x.step(keys: KeyState())
        XCTAssertEqual(xb.suspension, .savePoint(record: 24))
        let xa = x.resume(.savePoint(saved: false))
        XCTAssertEqual((xb.sounds + xa.sounds).filter { $0.snd == 421 }.count, 1)
        XCTAssertEqual(xb.sounds.filter { $0.snd == 421 }.count, 1)
    }

    func testRefireOn65thAfterCancel() throws {
        // The arithmetic in both orders of one frame (decay then landing, landing then decay): from −150, +3 a frame
        // until 0 at j = 50, then +1 a frame — the 65th landing frame exceeds 15 (BC22; the bank's "56th" assumed
        // no decay above 0).
        for decayFirst in [true, false] {
            var c: Int16 = -150
            var fired = 0
            for j in 1...200 {
                func decay() { if c > 0 { c -= 1 } else if c < 0 { c += 1 } }
                if decayFirst { decay() }
                c += 2
                if c > 15 { fired = j; break }
                if !decayFirst { decay() }
            }
            XCTAssertEqual(fired, 65, "decayFirst \(decayFirst)")
        }

        let r = try resources()
        let s = try session(r)
        guard stepToFire(s).ops != nil else { return XCTFail("no fire") }
        _ = s.resume(.savePoint(saved: false))
        var holds: [Int16] = []
        var refire: Int?
        for j in 1...100 {
            let ops = s.step(keys: KeyState())
            if ops.suspension != nil { refire = j; break }
            holds.append(s.player.savePointHold)
        }
        XCTAssertEqual(refire, 65)
        XCTAssertEqual(Array(holds.prefix(50)), (1...50).map { Int16(-150 + 3 * $0) })
        XCTAssertEqual(Array(holds.dropFirst(50)), (51...64).map { Int16($0 - 49) })
    }

    func testSuspendAndResumeSameFrame() throws {
        let r = try resources()
        let a = try session(r), b = try session(r)
        for _ in 0..<14 {
            XCTAssertEqual(a.step(keys: KeyState()), b.step(keys: KeyState()))
        }
        // The 15th landing: `a` fires; `b` is held below the threshold (its counter is not drawn or sounded). A sound
        // call made in the frame before the suspension (as a Handle's would be) is handed out with the part before it.
        b.world.player.savePointHold = 0
        let startFacing = b.globals.startFacing
        for s in [a, b] { s.world.player.cue(PlayerCue(call: .reg, snd: 420, priority: 1, volume: 0x100)) }
        let before = a.step(keys: KeyState())
        XCTAssertEqual(before.sounds.map(\.snd), [420])
        XCTAssertEqual(before.suspension, .savePoint(record: 24))
        let whole = b.step(keys: KeyState())
        XCTAssertNil(whole.suspension)
        // The frame so far: the drawn part (through `.WrapCopyToScreen` and the handle pass), not the end.
        XCTAssertTrue(before.draws.contains { if case .copyToScreen = $0 { true } else { false } })
        XCTAssertFalse(before.draws.contains { if case .wrapEraseSprites = $0 { true } else { false } })
        // A step while suspended is a precondition failure (not run here); resume finishes the SAME frame.
        let after = a.resume(.savePoint(saved: false))
        XCTAssertFalse(after.sounds.contains { $0.snd == 420 })
        let j = joined(before, after)
        XCTAssertEqual(j.draws, whole.draws)
        XCTAssertEqual(j.sounds, whole.sounds)
        XCTAssertEqual(j.soundStops, whole.soundStops)
        XCTAssertEqual(j.soundStopAt, whole.soundStopAt)
        XCTAssertEqual(j.music, whole.music)
        XCTAssertEqual(before.drawn, whole.drawn)
        XCTAssertEqual(after.drawn, whole.drawn)
        // The requests: the arm's own `ShowCursorSafe` before the dialog and `HideCursorSafe` after it, nothing else.
        XCTAssertEqual(before.requests.last, .showCursor)
        XCTAssertEqual(after.requests.first, .hideCursor)
        XCTAssertEqual(Array(before.requests.dropLast()) + Array(after.requests.dropFirst()), whole.requests)
        XCTAssertEqual(a.rngSeed, b.rngSeed)
        XCTAssertEqual(a.world.records, b.world.records)
        XCTAssertEqual(a.player.pixelX, b.player.pixelX)
        XCTAssertEqual(a.player.pixelY, b.player.pixelY)
        XCTAssertEqual(a.iterations, b.iterations)
        // The fire wrote `G+0x16` (facing 0 here); the held-off twin kept its own.
        XCTAssertEqual(a.globals.startFacing, 0)
        XCTAssertEqual(b.globals.startFacing, startFacing)
        // The next frames match draw for draw.
        for _ in 0..<3 { XCTAssertEqual(a.step(keys: KeyState()).draws, b.step(keys: KeyState()).draws) }

        // The pass's iteration state across a suspension (`SpriteWorld.continueSpecialPass`): n Box contacts on the
        // player, the call log of an uninterrupted pass vs one suspended at call k and continued — the same calls in
        // the same order, the suspending contact's own hit owed after it, nothing restarted. (4, 1): the sorted
        // dispatch; (18, 16): the 17th contact's at-once call inside the collection walk, the walk going on after it.
        let L1 = try LevelFile.load(from: r, level: 1)
        for (n, k) in [(4, 1), (18, 16)] {
            func pass(suspendAt: Int?) throws -> [String] {
                let w = try session(r).world
                let pid = try XCTUnwrap(w.playerID)
                let P = try XCTUnwrap(w.active.sprite(id: pid))
                var e = try SetupFaces.setup(L1.placements[24], context: SetupFaces.Context(level: L1, playerX: 0)).slot
                e.x = P.x
                e.y = P.y
                for _ in 0..<n { w.active.insert(e) }
                var log: [String] = []
                var calls = 0
                let hitPlayer: (SpriteWorld, Int, Int) -> Void = { w, _, c in
                    log.append("P\(c)")
                    if calls == suspendAt { w.suspension = .savePoint(record: 24) }
                    calls += 1
                }
                let hit: (SpriteWorld, Int, Int) -> Void = { _, c, _ in log.append("H\(c)") }
                var done = w.collideSpecial(hitPlayer: hitPlayer, hit: hit)
                while !done {
                    log.append("|")
                    w.suspension = nil
                    done = w.continueSpecialPass(hitPlayer: hitPlayer, hit: hit)
                }
                return log
            }
            let whole = try pass(suspendAt: nil)
            let cut = try pass(suspendAt: k)
            XCTAssertEqual(whole.filter { $0.hasPrefix("P") }.count, n, "n \(n)")
            XCTAssertEqual(cut.filter { $0 != "|" }, whole, "n \(n)")
            let bar = try XCTUnwrap(cut.firstIndex(of: "|"))
            XCTAssertEqual(cut.filter { $0.hasPrefix("P") }.firstIndex(of: cut[bar - 1]), k)
            if n <= 16 { XCTAssertEqual(cut[bar + 1], "H" + cut[bar - 1].dropFirst()) }       // the owed hit
        }
    }

    func testSaveBlockAtSavePoint() throws {
        let r = try resources()
        let files = Files()
        // The stored prefs differ from the live ones in +0x0e (sound volume): `.UpdateSGString`'s `.MakeCurrPrefs`
        // makes the stored record live.
        var stored = FerazelPrefs()
        stored.soundVolume = FerazelPrefs().soundVolume == 3 ? 4 : 3
        files.prefs = stored.record()
        // An armed async music fade-in (`5be2 = 0`, N huge): `.HandleAsyncAIFFMusicFade` runs once at each iteration's
        // end — never in the part of a frame before a suspension.
        var m = MusicFade()
        m.asyncDone = false
        m.asyncDirection = 1
        m.asyncFrames = 30000
        let run = try make(r, level: 1, record: 24, prefs: FerazelPrefs(), files: files, music: m)
        let (t, outs) = try drive(run, from: 100) { _, o in self.putFile(o) != nil }
        XCTAssertEqual(outs.last?.music, [])
        XCTAssertEqual(outs.dropLast().last { !$0.music.isEmpty }?.music.count, 1)
        let s = try XCTUnwrap(run.session)
        // The entry's `GammaFadeInAsync(0x28)` keeps gate 1 shut for 41 iterations; then 15 landings.
        XCTAssertEqual(run.iterations, 41 + 15)
        XCTAssertEqual(s.suspension, .savePoint(record: 24))
        // `.SavePointSave` at that moment (raw `1000c104…`): level 1, the handler pass's whole-pixel x / y, +6 = 1,
        // `hasSnapshot[1]` = 1 in the block's G and the live one, the snapshot holding record 24 with p1 = facing + 1
        // and x / y − 6.
        let b = run.save
        XCTAssertEqual(b.level, 1)
        XCTAssertEqual(b.playerX, Int32(s.player.pixelX))
        XCTAssertEqual(b.playerY, Int32(s.player.pixelY))
        XCTAssertEqual(b.isCheckpoint, 1)
        XCTAssertEqual([b.preview, b.demo], [0, 0])
        XCTAssertEqual(b.globals.hasSnapshot[1], 1)
        XCTAssertEqual(s.globals.hasSnapshot[1], 1)
        XCTAssertEqual(b.date, 0xb5c0_0000)
        let pid = try XCTUnwrap(s.world.playerID)
        let facing: Int16 = s.world.active.sprite(id: pid)!.mirrored ? 1 : 0
        XCTAssertEqual(b.globals.startFacing, facing)
        let snap = b.snapshots[1][24], live = s.world.records[24]
        XCTAssertEqual(snap.p1, facing + 1)
        XCTAssertEqual([snap.x, snap.y], [live.x - 6, live.y - 6])
        XCTAssertEqual(b.restoreSnapshot(level: 1)[24].p1, facing + 1)
        // `.SaveSG(prefs[1] == 0)`: a first save prompts; the default name already incremented ("@@@@@" → "Ferazel
        // Saved Game", `.IncrementLastSGString`); DITL 1003 item 13's text.
        let req = try XCTUnwrap(putFile(outs.last!))
        XCTAssertEqual(req, PutFileRequest(prompt: "Please name your saved game.", defaultName: "Ferazel Saved Game",
                                           message: "Your saved game will reflect your position as of the most recent checkpoint."))
        XCTAssertEqual(outs.last!.requests.filter { if case .putFile = $0 { true } else { false } }.count, 1)
        // The flow waits for the panel: no iteration meanwhile.
        for k in 1...5 { _ = try run.tick(now: t + UInt32(k), input: FrontInput()) }
        XCTAssertEqual(run.iterations, 56)
        // Saved: the block written as it stood, fe00 / fd54 / fd18 set, the name in prefs and the prefs file.
        let ref = SavedGameRef(url: URL(fileURLWithPath: "/tmp/never-written-s1"), displayName: "My Save")
        run.fileDone(.chosen(ref))
        let done = try run.tick(now: t + 6, input: FrontInput()).merged
        XCTAssertEqual(files.blocks[ref.url], b)
        XCTAssertEqual(run.saveState, SaveGameState(savedThisGame: true, saveFileKnown: true, lastReply: ref))
        XCTAssertEqual(run.livePrefs.savedGameName, "My Save")
        XCTAssertEqual(files.prefs.map(FerazelPrefs.init(record:))?.savedGameName, "My Save")
        XCTAssertEqual(done.prefs?.savedGameName, "My Save")
        XCTAssertEqual(run.livePrefs.soundVolume, stored.soundVolume)
        XCTAssertEqual(done.prefs?.soundVolume, stored.soundVolume)
        XCTAssertEqual(done.music.count, 1)                                  // the resumed iteration's async step
        XCTAssertNil(s.suspension)
        XCTAssertEqual(s.world.records[24].p1, facing + 1)
        // `.SavePointSave`'s tail (raw `1000c804..1000c888`, not paused): `RedrawEntireScrollGrid`, `HideCursorSafe`,
        // `RedrawGameArea`, `UpdateStatusBar(0, 0, 0)` — before the arm's flash.
        let h = s.camera.scrollH, v = s.camera.scrollV
        XCTAssertEqual(Array(done.draws.prefix(3)),
                       [.redrawEntireScrollGrid(h: h, v: v),
                        .copyToScreen(h: h, v: v, graphicsMode: Int(run.prefs.graphics), backdrop: run.prefs.plainCopy == 0),
                        .statusBar(s.globals.statusBar(levelName: s.level.header.name))])
        XCTAssertEqual(done.requests.first, .hideCursor)

        // The flash's fade-in keeps gate 1 shut at the `LevelRun` level too: with p1 cleared by hand the point does not
        // count landings for the 45 iterations after the save frame (the counter only decays), then counts again.
        let p = s.world.records[24]
        s.world.records[24] = Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: 0, p2: p.p2,
                                        p3: p.p3, p4: p.p4, y: p.y, x: p.x)
        XCTAssertEqual(s.player.savePointHold, -150)
        var now = t + 7
        var holds: [Int16] = []
        while run.iterations < 56 + 46 {
            let before = run.iterations
            let o = try run.tick(now: now, input: FrontInput()).merged
            XCTAssertNil(putFile(o))
            if run.iterations > before { holds.append(s.player.savePointHold) }
            now += 1
        }
        XCTAssertEqual(holds, (1...45).map { Int16(-150 + $0) } + [-150 + 46 + 2])
    }

    func testSuccessFlashSequence() throws {
        let r = try resources()
        let s = try session(r, hosted: true)
        guard stepToFire(s).ops != nil else { return XCTFail("no fire") }
        let ops = s.resume(.savePoint(saved: true))
        // snd 420 then 421 (`STPlayRegSound(…, 1, 0x100)`, raw `100577c4..100577ec`).
        XCTAssertEqual(ops.sounds.map(\.snd).filter { $0 == 420 || $0 == 421 }, [420, 421])
        // `GammaFadeOutAsync(2, white)` (it hides the cursor), three `HandleAsyncGammaFade`: 0 %, 50 %, 100 % white;
        // `GammaFadeInAsync(0x2d)`; the frame's own `HandleAsyncGammaFade` takes the fade-in's first step.
        let white = RGB16(red: 0xffff, green: 0xffff, blue: 0xffff)
        let gammas = ops.draws.filter(isGammaStep)
        XCTAssertEqual(gammas, [.gammaStep(numerator: 0, denominator: 2, toward: white),
                                .gammaStep(numerator: 1, denominator: 2, toward: white),
                                .gammaStep(numerator: 2, denominator: 2, toward: white),
                                .gammaStep(numerator: 0, denominator: 0x2d, toward: nil)])
        XCTAssertEqual(ops.requests.filter { $0 == .hideCursor }.count, 2)   // the fade-out's, the arm's end
        XCTAssertFalse(s.world.gammaFade.done)
        // 46 fade-in steps in all (k = 0 … 45), the last ending with `ShowCursorSafe`; a landing on the point meanwhile
        // (p1 cleared by hand to test gate 1 alone) does nothing — `DAT_100a53d6` is 0.
        let p = s.world.records[24]
        s.world.records[24] = Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: 0, p2: p.p2,
                                        p3: p.p3, p4: p.p4, y: p.y, x: p.x)
        var steps = 1
        var shows: [Int] = []
        for k in 1...60 {
            let o = s.step(keys: KeyState())
            XCTAssertNil(o.suspension)
            let g = o.draws.filter(isGammaStep)
            if let op = g.first {
                XCTAssertEqual(op, .gammaStep(numerator: k, denominator: 0x2d, toward: nil))
                steps += 1
            }
            if o.requests.contains(.showCursor) { shows.append(k) }
            if k < 45 { XCTAssertEqual(s.player.savePointHold, Int16(-150 + k), "gate 1 shut at \(k)") }
        }
        XCTAssertEqual(steps, 46)
        XCTAssertEqual(shows, [45])
        XCTAssertTrue(s.world.gammaFade.done)
        XCTAssertFalse(s.world.gammaFade.fadedOut)

        // Fading disabled (`DAT_100a53c2 == 0`): no flash, gate 1 stays open — the point re-arms at once.
        let d = try session(r, hosted: true)
        d.world.gammaFade = AsyncGammaFade(fadedOut: false, done: true, fadingEnabled: false)
        guard stepToFire(d).ops != nil else { return XCTFail("no fire") }
        let flat = d.resume(.savePoint(saved: true))
        XCTAssertFalse(flat.draws.contains(where: isGammaStep))
        XCTAssertEqual(flat.sounds.map(\.snd).filter { $0 == 420 || $0 == 421 }, [420, 421])
        XCTAssertTrue(d.world.gammaFade.done)
        let q = d.world.records[24]
        d.world.records[24] = Placement(index: q.index, flag: q.flag, byte1: q.byte1, type: q.type, p1: 0, p2: q.p2,
                                        p3: q.p3, p4: q.p4, y: q.y, x: q.x)
        _ = d.step(keys: KeyState())
        XCTAssertEqual(d.player.savePointHold, -150 + 3)
    }

    func testReuseSavedGamesSkipsPrompt() throws {
        let r = try resources()
        var prefs = FerazelPrefs()
        prefs.reuseSavedGames = 1
        let files = Files()
        // A first save prompts (fd54 clear).
        let run1 = try make(r, level: 1, record: 24, prefs: prefs, files: files)
        let (t1, _) = try drive(run1, from: 100) { _, o in self.putFile(o) != nil }
        let ref = tempRef("Ferazel Saved Game")
        run1.fileDone(.chosen(ref))
        _ = try run1.tick(now: t1 + 1, input: FrontInput())
        XCTAssertEqual(run1.saveState.saveFileKnown, true)
        XCTAssertEqual(files.writes, [ref.url])
        let name = run1.livePrefs.savedGameName
        XCTAssertEqual(name, "Ferazel Saved Game")

        // The next save in the game (the flow hands fd54 / fd18 and the live prefs on): no `putFile`, the same file
        // written again, prefs+0x42 unchanged (`.UpdateSGString` still runs: the prefs file written again).
        var p2 = prefs
        p2.savedGameName = name
        let prefsWrites = files.prefsWrites
        let run2 = try make(r, level: 2, record: 68, prefs: p2, files: files, state: run1.saveState, date: 7)
        let (_, outs2) = try drive(run2, from: 100) { _, _ in files.writes.count > 1 }
        XCTAssertFalse(outs2.contains { putFile($0) != nil })
        XCTAssertEqual(files.writes, [ref.url, ref.url])
        XCTAssertEqual(files.blocks[ref.url]?.level, 2)
        XCTAssertEqual(files.blocks[ref.url]?.date, 7)
        XCTAssertEqual(run2.livePrefs.savedGameName, name)
        XCTAssertEqual(files.prefsWrites, prefsWrites + 1)
        XCTAssertEqual(run2.saveState, SaveGameState(savedThisGame: true, saveFileKnown: true, lastReply: ref))
        XCTAssertNil(run2.session?.suspension)

        // A failing write after a fresh prompt (BC23): the error report (`ReportError(text, code)`), result 0 → the
        // point re-armed; the order leaves the old file deleted, the new name in prefs and reuse armed (fd54 set).
        let failing = Files()
        failing.failWrite = SaveWriteError.diskFull
        var p3 = FerazelPrefs()
        p3.savedGameName = "Mine 9"
        let run3 = try make(r, level: 1, record: 24, prefs: p3, files: failing)
        let (t3, outs3) = try drive(run3, from: 100) { _, o in self.putFile(o) != nil }
        XCTAssertEqual(putFile(outs3.last!)?.defaultName, "Mine 10")
        let ref3 = tempRef("Elsewhere")
        run3.fileDone(.chosen(ref3))
        let e = try run3.tick(now: t3 + 1, input: FrontInput()).merged
        XCTAssertEqual(e.requests.last, .dialog(.error(text: "The game could not be saved, because the disk is full.",
                                                       code: SaveWriteError.diskFull)))
        XCTAssertEqual(run3.session?.suspension, .savePoint(record: 24))      // still inside the frame
        run3.dialogDone(.ok)
        _ = try run3.tick(now: t3 + 2, input: FrontInput())
        XCTAssertNil(run3.session?.suspension)
        XCTAssertEqual(run3.session?.world.records[24].p1, 0)
        XCTAssertEqual(run3.livePrefs.savedGameName, "Elsewhere")
        XCTAssertEqual(failing.prefs.map(FerazelPrefs.init(record:))?.savedGameName, "Elsewhere")
        XCTAssertEqual(run3.saveState, SaveGameState(savedThisGame: false, saveFileKnown: true, lastReply: ref3))
        XCTAssertNil(failing.blocks[ref3.url])

        // Cancel restores the old name (the only path that does).
        let run4 = try make(r, level: 1, record: 24, prefs: p3, files: Files())
        let (t4, _) = try drive(run4, from: 100) { _, o in self.putFile(o) != nil }
        XCTAssertEqual(run4.livePrefs.savedGameName, "Mine 10")
        run4.fileDone(.cancelled)
        _ = try run4.tick(now: t4 + 1, input: FrontInput())
        XCTAssertEqual(run4.livePrefs.savedGameName, "Mine 9")
        XCTAssertEqual(run4.saveState, SaveGameState())
        XCTAssertEqual(run4.session?.world.records[24].p1, 0)
    }
}
