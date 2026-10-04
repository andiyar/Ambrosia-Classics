@testable import BubbleTroubleCore
import Foundation
import XCTest

/// C4 — the play loop around `stepFrame` (plan 2026-10-04 btx-playable §C4, amendments R3/R4/R7/R8), against
/// `_PlayGame @ 00018247`, `_NewLevel @ 0001735f`, `_LoadLevel @ 00002ef7`, `_StopMusic @ 0001afac`,
/// `_TimeBonus_CountDown @ 00006dcb`, `_PauseGame @ 0001767b`, `_RequestGame @ 0000a9a1`, `_CheckHeroMovement @ 00021f49`.
/// Data-gated on `HECTORKIT_DATA_BTX` (always set under G1).
final class GameSessionTests: XCTestCase {

    // MARK: Helpers

    private func gameData() throws -> BTXGameData {
        try BTXGameData(resourcesDirectory: BTXTestData.resourcesDirectory())
    }

    private func playSession(_ data: BTXGameData, level: Int = 1, prefs: BTXPrefs = .defaults,
                             seed: UInt32 = 0x1234) throws -> GameSession {
        try GameSession(data: data, prefs: prefs, mode: .play, startLevel: level, seed: seed, film: nil)
    }

    /// Ticks (one per call, `now` advancing by 1) while `condition` holds; returns everything emitted.
    @discardableResult
    private func ticks(_ session: GameSession, now: inout UInt32, keys: HeldKeys = HeldKeys(), limit: Int = 5000,
                       while condition: (GameSession) -> Bool) -> SessionOutput {
        var all = SessionOutput()
        var n = 0
        while condition(session) && n < limit {
            all.append(session.tick(now: now, keys: keys))
            now += 1
            n += 1
        }
        XCTAssertLessThan(n, limit, "tick loop did not finish")
        return all
    }

    /// Runs the opening wipe; returns its output.
    @discardableResult
    private func finishWipe(_ session: GameSession, now: inout UInt32) -> SessionOutput {
        ticks(session, now: &now) { $0.phase == .wipe }
    }

    private static let level1Rect = QDRect(top: 0, left: 0, bottom: 480, right: 640)

    // MARK: 1. KeyboardInput

    func testKeyboardInputDefaultSet() {
        var input = KeyboardInput(keySet: BTXPrefs.defaults.currentKeySet)
        XCTAssertEqual(input.keySet, KeySet.builtIn[0])
        input.keys = HeldKeys(codes: [0x7b, 0x31])
        XCTAssertEqual(input.readSample(), FilmSample(up: false, down: false, left: true, right: false, push: true))
        input.keys = HeldKeys(codes: [0x7e, 0x7d, 0x7c])
        XCTAssertEqual(input.readSample(), FilmSample(up: true, down: true, left: false, right: true, push: false))
        input.keys = HeldKeys(codes: [0x00, 0x06], capsLock: true, command: true)
        XCTAssertEqual(input.readSample(), FilmSample(up: false, down: false, left: false, right: false, push: false))
        // Play mode never advances gRecordingCounter; live input never runs out.
        XCTAssertEqual(input.samplesConsumed, 0)
        XCTAssertFalse(input.isExhausted)
    }

    func testKeyboardInputKeySet7Classic() {
        var prefs = BTXPrefs.defaults
        prefs.currentKeySetIndex = 7
        var input = KeyboardInput(keySet: prefs.currentKeySet)
        XCTAssertEqual(input.keySet.name, "Classic")
        input.keys = HeldKeys(codes: [0x06, 0x27])                       // Z, '
        XCTAssertEqual(input.readSample(), FilmSample(up: true, down: false, left: true, right: false, push: false))
        input.keys = HeldKeys(codes: [0x07, 0x2c, 0x31])                 // X, /, Space
        XCTAssertEqual(input.readSample(), FilmSample(up: false, down: true, left: false, right: true, push: true))
        input.keys = HeldKeys(codes: [0x7b, 0x7c, 0x7e, 0x7d])           // the arrows do nothing in set 7
        XCTAssertEqual(input.readSample(), FilmSample(up: false, down: false, left: false, right: false, push: false))
    }

    // MARK: 3. New game

    func testNewGameStartsLevel1ThreeLives() throws {
        let data = try gameData()
        let session = try playSession(data)
        let s = session.state
        XCTAssertEqual(s.level, 1)
        XCTAssertEqual(s.lives, 3)
        XCTAssertEqual(s.score, 0)
        XCTAssertEqual(s.nextExtraLifeScore, 10000)
        XCTAssertEqual(s.multiplier, 1)
        XCTAssertEqual(s.extraLetters, [false, false, false, false, false])
        XCTAssertEqual(s.mode, .play)
        XCTAssertFalse(session.playerIsCheating)
        XCTAssertEqual(session.phase, .wipe)
        XCTAssertFalse(session.wantsFrameTimer)
        // Frames do nothing during the wipe.
        let none = session.frame(keys: HeldKeys())
        XCTAssertEqual(none.requests.first, .disableAbout(true), "pending opening output flushes on the first call")
        XCTAssertEqual(none.requests, [.disableAbout(true), .hideCursor, .savePrefs])
        XCTAssertEqual(none.drawOps.last, .wipe(step: 12))
        XCTAssertEqual(session.state.frame, 0)
        XCTAssertTrue(session.frame(keys: HeldKeys()) == SessionOutput())

        // _RequestGame: any start level > 1 is "cheating" (no high score).
        XCTAssertTrue(try playSession(data, level: 3).playerIsCheating)
    }

    // MARK: 4. Level start

    func testLevelStartCuesGetReadyNotInDemo() throws {
        let data = try gameData()
        var now: UInt32 = 1000
        let session = try playSession(data)
        // _WipeScreen(12): 22 band advances, one per TickCount change after the baseline tick.
        var calls = 0
        while session.phase == .wipe {
            _ = session.tick(now: now, keys: HeldKeys())
            now += 1
            calls += 1
        }
        XCTAssertEqual(calls, 1 + GameSession.wipeAdvances)
        XCTAssertEqual(GameSession.wipeAdvances, 22)
        XCTAssertEqual(session.phase, .playing)
        XCTAssertTrue(session.wantsFrameTimer)
        XCTAssertEqual(session.notices.current, 6, "LEVEL n")
        XCTAssertTrue(session.musicLoaded)

        // Re-run to capture the wipe tail's output exactly.
        let again = try playSession(data)
        now = 0
        let out = finishWipe(again, now: &now)
        XCTAssertEqual(out.music, [.load(set: again.state.levelMusicSet)])
        XCTAssertEqual(again.state.levelMusicSet, 1, "level 1 → Level set 1 music (FI §6a)")
        XCTAssertEqual(out.sounds, [SoundCue(slot: 2, priority: 20, delayFrames: 0)], "_NewLevel 00017658 Get Ready!")
        XCTAssertEqual(Array(out.requests.suffix(2)), [.hideCursor, .enableMenus(false)])
        // The first frame draws the LEVEL 1 notice.
        let first = again.frame(keys: HeldKeys())
        // OS X path (C3): `_DrawNotice` plots into the window; there is no screen-rect flush.
        XCTAssertTrue(first.drawOps.contains(.sprite(set: 0xe, frame: 1, h: 0xfe, v: 221, mode: .normal,
                                                     target: .screen)))
        XCTAssertTrue(first.drawOps.contains(.sprite(set: 0xf, frame: 2, h: 0x166, v: 223, mode: .normal,
                                                     target: .screen)))

        // Demo: GAME OVER notice, no music, no Get Ready — and the frames are exactly FilmReplay's (G4 path).
        let film = try data.levels.film(1)
        let demo = try GameSession(data: data, prefs: .defaults, mode: .demo, startLevel: 9, seed: 9, film: film)
        XCTAssertEqual(demo.state.level, 1)
        let demoOut = finishWipe(demo, now: &now)
        XCTAssertEqual(demo.notices.current, 4)
        XCTAssertTrue(demoOut.music.isEmpty)
        XCTAssertTrue(demoOut.sounds.isEmpty)
        XCTAssertFalse(demoOut.requests.contains(.hideCursor))
        var end: SessionOutput?
        var frames = 0
        while end == nil && frames < 5000 {
            let o = demo.frame(keys: HeldKeys(capsLock: true))     // Caps Lock is ignored in demo
            XCTAssertTrue(o.music.isEmpty, "no music ever in demo")
            XCTAssertEqual(demo.phase == .playing || demo.phase == .ended, true)
            if o.ended != nil { end = o }
            frames += 1
        }
        let replay = try FilmReplay.run(filmID: 1, files: data.levels)
        XCTAssertEqual(Int(demo.state.frame), replay.frames)
        XCTAssertEqual(demo.state.score, replay.score)
        XCTAssertEqual(demo.state.rng.drawCount, replay.totalDraws)
        XCTAssertEqual(demo.state.pendingStops, replay.stops)
        let expected: SessionEnd = replay.stops.contains(.levelCompleted) ? .levelCompleted : .demoStopped(replay.stops)
        XCTAssertEqual(end?.ended, expected)
        XCTAssertEqual(end?.sounds, [SoundCue(slot: 0x1b, priority: 0x1e, delayFrames: 0)], "00019304")
    }

    // MARK: 5. Hero appear

    func testHeroAppearStartsMusic() throws {
        let data = try gameData()
        let session = try playSession(data)
        var now: UInt32 = 0
        finishWipe(session, now: &now)
        var startFrames: [UInt16] = []
        for _ in 0..<80 {
            let out = session.frame(keys: HeldKeys())
            if out.music.contains(.start) { startFrames.append(session.state.frame) }
        }
        // First appearance: stateStart 0 + 0x46 < frame → frame 71.
        XCTAssertEqual(startFrames, [71])
        XCTAssertEqual(session.state.hero.state, 2)
        XCTAssertTrue(session.musicPlaying)
        XCTAssertEqual(session.notices.current, 0, "_PrepareNotice(0) at appear (not demo)")
    }

    // MARK: 6–7. Count-down

    /// Runs a count-down one tick per call; returns (sounds with their tick offsets, ticks to done).
    private func runCountdown(_ state: inout GameState) -> (sounds: [(Int, SoundCue)], ticks: Int) {
        var c = TimeBonusCountdown(state: state)
        var sounds: [(Int, SoundCue)] = []
        var t = 0
        while !c.isDone && t < 100_000 {
            let out = c.run(now: UInt32(5000 + t), state: &state)
            sounds += out.sounds.map { (t, $0) }
            if c.isDone { break }
            t += 1
        }
        return (sounds, t)
    }

    func testCountdownChunksAndSounds() throws {
        var state = try GameState.newGame(level: 1, mode: .play, seed: 1, files: try gameData().levels)
        state.multiplier = 2
        state.timeBonus = 12345
        let (sounds, ticks) = runCountdown(&state)
        // ×2 = 24690 → 74 × 200 (to 9890), 49 × 100 (to 4990), 100 × 50 (to −10: the loop's `0 < bonus` test).
        let chunks = 74 + 49 + 100
        XCTAssertEqual(state.timeBonus, -10)
        XCTAssertEqual(state.score, 74 * 200 + 49 * 100 + 100 * 50)
        XCTAssertEqual(state.lives, 4, "_AddToScore(chunk, 0) still awards the 10000 life")
        XCTAssertEqual(state.multiplier, 2, "the flash restores the multiplier")
        // `_TimeBonus_Draw` (each chunk) ends the flash once `frame > flashTimer + 4` — `_AdvanceFrameCounter` moves
        // the frame on per chunk, so it is off again by the end (C3).
        XCTAssertFalse(state.timeBonusFlash)
        XCTAssertEqual(Int(state.frame), chunks, "_AdvanceFrameCounter once per chunk")
        // Timeline: 3 × (8 + 8) flash ticks, then snd 9 and a 60-tick wait; 3 ticks per chunk; final 15.
        XCTAssertEqual(ticks, 48 + 60 + chunks * 3 + 15)
        XCTAssertEqual(sounds.filter { $0.1.slot == 13 }.count, 2, "the 10000 life's _AddHero pair")
        let slots = sounds.map { $0.1.slot }.filter { $0 != 13 }
        XCTAssertEqual(Array(slots.prefix(5)), [32, 32, 32, 9, 41])
        XCTAssertEqual(slots.dropFirst(5).count, chunks / 3)
        XCTAssertTrue(slots.dropFirst(5).allSatisfy { $0 == 17 })
        let own = sounds.filter { $0.1.slot != 13 }
        XCTAssertTrue(own.allSatisfy { $0.1.priority == 30 && $0.1.delayFrames == 0 })
        XCTAssertEqual(own.map { $0.0 }.prefix(5), [8, 24, 40, 48, 108])
        XCTAssertEqual(own[5].0, 108 + 2 * 3, "snd 17 on the third chunk")
    }

    /// `_AddToScore(chunk, 0)` crossing 10000 → `_AddHero`: its two snd 13 (20, 0) come out with that chunk.
    func testCountdownExtraLifeCuesSnd13Twice() throws {
        var state = try GameState.newGame(level: 1, mode: .play, seed: 1, files: try gameData().levels)
        state.score = 9900
        state.timeBonus = 300
        let (sounds, _) = runCountdown(&state)
        XCTAssertEqual(state.lives, 4)
        XCTAssertEqual(state.score, 10200)
        let extra = SoundCue(slot: 13, priority: 20, delayFrames: 0)
        XCTAssertEqual(sounds.filter { $0.1 == extra }.count, 2)
        // Chunks of 50 at ticks 0, 3, 6 …: the 2nd chunk (tick 3) reaches 10000; the 3rd's snd 17 follows at tick 6.
        XCTAssertEqual(sounds.map { $0.1.slot }, [13, 13, 17, 17])
        XCTAssertEqual(sounds.map { $0.0 }, [3, 3, 6, 15])
        XCTAssertTrue(state.takeSounds().isEmpty, "drained")
    }

    func testCountdownCap99950() throws {
        let files = try gameData().levels
        var state = try GameState.newGame(level: 1, mode: .play, seed: 1, files: files)
        state.multiplier = 5
        state.timeBonus = 30000
        var c = TimeBonusCountdown(state: state)
        var t: UInt32 = 0
        while state.timeBonus == 30000 && t < 200 {
            _ = c.run(now: t, state: &state)
            t += 1
        }
        XCTAssertEqual(state.timeBonus, 99950, "150000 capped at 0x1866e")

        // The "Oh" sounds (multiplier 1: no flash): 0 → 42; 10000 → none (`< 0x2711`); 10050 → 41.
        for (bonus, expected) in [(Int32(0), [42]), (10000, []), (10050, [41])] {
            var s = try GameState.newGame(level: 1, mode: .play, seed: 1, files: files)
            s.timeBonus = bonus
            var cd = TimeBonusCountdown(state: s)
            let first = cd.run(now: 0, state: &s)
            XCTAssertEqual(first.sounds.map(\.slot).filter { $0 != 17 }, expected, "bonus \(bonus)")
        }
    }

    // MARK: 8. Level advance

    func testLevelAdvanceAfterCountdown() throws {
        let data = try gameData()
        let session = try playSession(data)
        var now: UInt32 = 0
        finishWipe(session, now: &now)
        session.state.levelRecord.words[6] = 0          // every enemy already "squished": the level ends at once
        var endFrame: SessionOutput?
        var n = 0
        while session.phase == .playing && n < 200 {
            let o = session.frame(keys: HeldKeys())
            if session.phase != .playing { endFrame = o }
            n += 1
        }
        // End of level at frame 1, +70 → the transition on frame 72 (the hero appeared on 71: music playing).
        XCTAssertEqual(session.state.frame, 72)
        XCTAssertEqual(session.phase, .musicFade)
        XCTAssertEqual(endFrame?.music, [.volume(0x100)], "_StopMusic: pref 4 fades from 0x100, the first now")
        XCTAssertFalse(session.wantsFrameTimer)
        let scoreBefore = session.state.score
        let bonus = session.state.timeBonus
        XCTAssertEqual(bonus, 2500)

        let fade = ticks(session, now: &now) { $0.phase == .musicFade }
        let volumes = fade.music.compactMap { if case .volume(let v) = $0 { v } else { nil } }
        XCTAssertEqual(volumes, Array(stride(from: 0x100 - 5, through: 0, by: -5)))
        XCTAssertEqual(fade.music.last, .stopNow)
        XCTAssertEqual(session.phase, .countdown)

        let rest = ticks(session, now: &now) { $0.phase == .countdown }
        XCTAssertEqual(session.state.score, scoreBefore + bonus)
        XCTAssertEqual(rest.sounds.last, SoundCue(slot: 0x1b, priority: 0x1e, delayFrames: 0), "00018dc9")
        XCTAssertEqual(rest.music, [.unload])
        XCTAssertEqual(rest.requests, [.savePrefs], "_LoadLevel saves prefs every level")
        XCTAssertEqual(rest.drawOps.last, .wipe(step: 12))
        XCTAssertEqual(session.state.level, 2)
        XCTAssertEqual(session.state.frame, 0)

        let tail = finishWipe(session, now: &now)
        XCTAssertEqual(session.phase, .playing)
        XCTAssertEqual(tail.music, [.load(set: session.state.levelMusicSet)])
        XCTAssertEqual(tail.sounds, [SoundCue(slot: 2, priority: 20, delayFrames: 0)])
        XCTAssertFalse(tail.requests.contains(.enableMenus(false)), "menus were disabled at game start only")
        XCTAssertEqual(session.notices.current, 6)
        XCTAssertEqual(session.state.lives, 3)
    }

    // MARK: 9. _LoadLevel

    func testLevel51PicksRandom21to50() throws {
        let data = try gameData()
        var state = try GameState.newGame(level: 50, mode: .play, seed: 0xBEEF, files: data.levels)
        let draws = state.rng.drawCount
        let id = state.levelIDToLoad(51)
        XCTAssertEqual(state.rng.drawCount, draws, "the peek draws nothing")
        XCTAssertTrue((21...50).contains(id))
        XCTAssertEqual(state.levelIDToLoad(50), 50)
        try state.advanceLevel(data: data)
        XCTAssertEqual(state.level, 51)
        var expected = try data.levels.level(id)
        expected.words = GameState.loadLevelWords(expected.words)
        XCTAssertEqual(state.levelRecord, expected)

        // Level 100 → the counter is set to 99.
        var high = try GameState.newGame(level: 99, mode: .play, seed: 7, files: data.levels)
        try high.advanceLevel(data: data)
        XCTAssertEqual(high.level, 99)

        // _LoadLevel raises the level-select maximum (short 0x3a, default 10) to any level < 31 it loads.
        XCTAssertEqual(try playSession(data, level: 25).prefs.levelSelectMax, 25)
        XCTAssertEqual(try playSession(data, level: 31).prefs.levelSelectMax, 10)
        XCTAssertEqual(try playSession(data, level: 4).prefs.levelSelectMax, 10)
    }

    // MARK: 10. Game over

    func testGameOverAfter95Frames() throws {
        let data = try gameData()
        let session = try playSession(data)
        var now: UInt32 = 0
        finishWipe(session, now: &now)
        // The last life is gone and the death animation has just started (state 4 at frame 0).
        session.state.hero.state = 4
        session.state.hero.stateStart = 0
        session.state.lives = 0
        var respawnFrame: UInt16?
        var stopFrame: UInt16?
        var ended: SessionOutput?
        var n = 0
        while ended == nil && n < 400 {
            let o = session.frame(keys: HeldKeys())
            if respawnFrame == nil && session.state.hero.state == 1 { respawnFrame = session.state.frame }
            if stopFrame == nil && !session.state.playing { stopFrame = session.state.frame }
            if o.ended != nil { ended = o }
            n += 1
        }
        XCTAssertEqual(respawnFrame, 66, "state 4 → 1 after 0x41 frames")
        XCTAssertEqual(stopFrame, 66 + 96, "lives < 1: 0x5f frames later gPlayGame = 0")
        XCTAssertEqual(session.state.frame, 162, "the exit runs at the next loop top without a frame")
        XCTAssertEqual(ended?.ended, .gameOver)
        XCTAssertEqual(session.endReason, .gameOver)
        XCTAssertEqual(session.phase, .ended)
        XCTAssertEqual(ended?.sounds, [SoundCue(slot: 0x1b, priority: 0x1e, delayFrames: 0)])
        XCTAssertEqual(ended?.music, [.stopNow, .unload])
        XCTAssertEqual(ended?.requests.first, .enableMenus(true))
        XCTAssertTrue(ended?.requests.contains(.haltAllSound) == true)
        // FIN! went up at the respawn and stays.
        XCTAssertEqual(session.notices.current, 2)
    }

    // MARK: 11. Esc

    func testEscHoldPref() throws {
        let data = try gameData()
        let esc = HeldKeys(codes: [0x35])

        let quick = try playSession(data)
        var now: UInt32 = 0
        finishWipe(quick, now: &now)
        XCTAssertNil(quick.frame(keys: esc).ended)
        XCTAssertEqual(quick.frame(keys: HeldKeys()).ended, .escaped, "ends at the next loop top")

        var prefs = BTXPrefs.defaults
        prefs.holdEscapeToExit = true
        let held = try playSession(data, prefs: prefs)
        finishWipe(held, now: &now)
        for _ in 0..<20 { XCTAssertNil(held.frame(keys: esc).ended) }
        XCTAssertNil(held.frame(keys: HeldKeys()).ended, "release resets gEscapeKeyFrames")
        for _ in 0..<31 { XCTAssertNil(held.frame(keys: esc).ended) }       // 31 > 0x1e → gPlayGame = 0
        let out = held.frame(keys: esc)
        XCTAssertEqual(out.ended, .escaped)
        XCTAssertEqual(held.state.frame, 52)
    }

    // MARK: 12. Pause

    func testCapsLockPausesNotInDemo() throws {
        let data = try gameData()
        let session = try playSession(data)
        var now: UInt32 = 0
        finishWipe(session, now: &now)
        _ = session.frame(keys: HeldKeys())
        let caps = HeldKeys(capsLock: true)
        let entry = session.frame(keys: caps)
        XCTAssertEqual(session.state.frame, 2, "the pause frame itself runs")
        XCTAssertEqual(session.phase, .paused)
        XCTAssertFalse(session.wantsFrameTimer)
        XCTAssertEqual(entry.sounds, [SoundCue(slot: 0x16, priority: 0x1e, delayFrames: 0)])
        XCTAssertEqual(entry.requests, [.disableAbout(true), .haltAllSound, .setCursor(id: 200), .restoreMousePosition,
                                        .showCursor, .enableMenus(true)])
        XCTAssertTrue(entry.music.isEmpty, "music loaded but not yet playing → no _PauseMusic")
        XCTAssertTrue(entry.drawOps.contains(.pict(id: 9030, dst: QDRect(top: 279, left: 155, bottom: 295, right: 485),
                                                   target: .screen)))
        XCTAssertTrue(entry.drawOps.contains(.pict(id: 9031, dst: QDRect(top: 299, left: 190, bottom: 315, right: 450),
                                                   target: .screen)))
        XCTAssertTrue(entry.drawOps.contains(.sprite(set: 0xa, frame: 1, h: 265, v: 221, mode: .normal,
                                                     target: .screen)))
        XCTAssertEqual(session.notices.current, 3)

        // Frames do nothing; ticks with Caps Lock still on stay paused.
        XCTAssertEqual(session.frame(keys: caps), SessionOutput())
        for _ in 0..<10 { XCTAssertEqual(session.tick(now: now, keys: caps), SessionOutput()); now += 1 }
        XCTAssertEqual(session.phase, .paused)
        let exit = session.tick(now: now, keys: HeldKeys())
        XCTAssertEqual(session.phase, .playing)
        XCTAssertEqual(exit.requests, [.disableAbout(false), .enableMenus(false), .hideCursor])
        XCTAssertEqual(exit.music, [.resume, .start], "_ResumeMusic starts a loaded, silent channel")
        XCTAssertEqual(exit.drawOps, [.compToScreen(Self.level1Rect)])
        XCTAssertEqual(session.notices.current, 6, "the previous notice is restored")
        XCTAssertEqual(session.state.frame, 2)

        // Demo: Caps Lock never pauses.
        let demo = try GameSession(data: data, prefs: .defaults, mode: .demo, startLevel: 0, seed: 0,
                                   film: try data.levels.film(1))
        finishWipe(demo, now: &now)
        for _ in 0..<5 {
            let o = demo.frame(keys: caps)
            XCTAssertFalse(o.sounds.contains { $0.slot == 0x16 })
        }
        XCTAssertEqual(demo.phase, .playing)
        XCTAssertEqual(demo.notices.current, 4)
    }

    // MARK: Fix round (orchestrator rulings 1–11)

    /// Ruling (C3 integration): the pause check sits INSIDE the frame at 00018a7e, after the hero state machine — so
    /// on the appearance frame `_PrepareNotice(0)` runs first and PAUSED (3) survives; the notice restored on exit
    /// is the post-appear one (0).
    func testPauseOnAppearFrameKeepsPausedNotice() throws {
        let data = try gameData()
        let session = try playSession(data)
        var now: UInt32 = 0
        finishWipe(session, now: &now)
        for _ in 0..<70 { _ = session.frame(keys: HeldKeys()) }
        XCTAssertEqual(session.notices.current, 6)
        let entry = session.frame(keys: HeldKeys(capsLock: true))   // frame 71: appear + pause
        XCTAssertEqual(session.state.hero.state, 2)
        XCTAssertEqual(session.phase, .paused)
        XCTAssertEqual(session.notices.current, 3)
        XCTAssertTrue(entry.drawOps.contains(.sprite(set: 0xa, frame: 1, h: 265, v: 221, mode: .normal,
                                                     target: .screen)))
        XCTAssertEqual(entry.drawOps.last, .screenToComp(Self.level1Rect))
        _ = session.tick(now: now, keys: HeldKeys())
        XCTAssertEqual(session.phase, .playing)
        XCTAssertEqual(session.notices.current, 0)
    }

    /// C3: `gScoreRect` is reset only by `_ResetScore` (game start), so `_DrawScore`'s cache erase at the next level
    /// still reaches the old right edge; `_gTimeBonusRect` is reset by `_TimeBonus_Reset` in every `_NewLevel`.
    func testScoreRectCarriesAcrossLevelsTimeBonusRectResets() throws {
        let data = try gameData()
        let session = try playSession(data)
        var now: UInt32 = 0
        finishWipe(session, now: &now)
        session.state.score = 1_234_567
        _ = session.state.scoreOps()                                    // right edge 132 + 7·24 = 300
        XCTAssertEqual(session.state.presentation.timeBonusRect.right, 480 + 4 * 23 + 22)
        try session.state.advanceLevel(data: data)
        _ = session.state.levelStartOps()
        XCTAssertEqual(session.state.scoreOps().first,
                       .scoreToComp(QDRect(top: 446, left: 132, bottom: 476, right: 300)))
        XCTAssertEqual(session.state.timeBonusOps().first,
                       .scoreToComp(QDRect(top: 446, left: 480, bottom: 476, right: 480)))
    }

    /// Plays to the hero's appearance (frame 71, music playing).
    private func sessionAtAppear(_ data: BTXGameData, now: inout UInt32) throws -> GameSession {
        let session = try playSession(data)
        finishWipe(session, now: &now)
        for _ in 0..<71 { _ = session.frame(keys: HeldKeys()) }
        XCTAssertTrue(session.musicPlaying)
        return session
    }

    /// Ruling 1: the frame's cues leave through `FrameReport` only — the sim buffer is empty after every frame, so the
    /// count-down's drain never replays the level-ending frame's cues.
    func testFrameDrainsSimSoundBufferAfterReport() throws {
        let data = try gameData()
        let session = try playSession(data)
        var now: UInt32 = 0
        finishWipe(session, now: &now)
        session.state.levelRecord.words[6] = 0
        var heard: [Int] = []
        while session.phase == .playing {
            heard += session.frame(keys: HeldKeys()).sounds.map(\.slot)
            XCTAssertTrue(session.state.takeSounds().isEmpty, "frame \(session.state.frame)")
        }
        XCTAssertTrue(heard.contains(8) && heard.contains(27), "appear cues came through the report")
        let rest = ticks(session, now: &now) { $0.phase != .wipe }
        let allowed: Set<Int> = [9, 13, 17, 27, 32, 41, 42]
        XCTAssertTrue(rest.sounds.allSatisfy { allowed.contains($0.slot) }, "\(rest.sounds.map(\.slot))")
        XCTAssertEqual(rest.sounds.filter { $0.slot == 27 }.count, 1)
    }

    /// Ruling 6: the fade's first volume is set in the frame and holds for one tick change, like every later one.
    func testFadeFirstStepWaitsOneTick() throws {
        let data = try gameData()
        var now: UInt32 = 100
        let session = try sessionAtAppear(data, now: &now)
        session.state.levelRecord.words[6] = 0
        var last = SessionOutput()
        while session.phase == .playing { last = session.frame(keys: HeldKeys()) }
        XCTAssertEqual(last.music, [.volume(0x100)])
        XCTAssertEqual(session.tick(now: now, keys: HeldKeys()).music, [], "baseline tick")
        XCTAssertEqual(session.tick(now: now, keys: HeldKeys()).music, [], "same TickCount")
        XCTAssertEqual(session.tick(now: now + 1, keys: HeldKeys()).music, [.volume(0xfb)])
    }

    /// Ruling 3 + 7: pause entry halts then plays snd 22 — the pause frame's own cues are dropped — and the frame
    /// ends with `_ScreenToComp`.
    func testPauseEntryHaltDropsFrameCues() throws {
        let data = try gameData()
        let session = try playSession(data)
        var now: UInt32 = 0
        finishWipe(session, now: &now)
        for _ in 0..<70 { _ = session.frame(keys: HeldKeys()) }
        let out = session.frame(keys: HeldKeys(capsLock: true))          // frame 71: appear (snd 8 + 27) and pause
        XCTAssertEqual(session.state.frame, 71)
        XCTAssertEqual(out.sounds, [SoundCue(slot: 0x16, priority: 0x1e, delayFrames: 0)])
        XCTAssertEqual(out.music, [.start, .pause])
        XCTAssertEqual(out.drawOps.last, .screenToComp(Self.level1Rect))
        XCTAssertEqual(session.phase, .paused)
    }

    /// Ruling 2 (play): a deactivation during the wipe / fade / count-down is queued and pauses at the next frame;
    /// such a pause ends only on reactivation with Caps Lock off.
    func testDeactivateQueuedDuringBlockingPhasesAndActivateResumes() throws {
        let data = try gameData()
        let session = try playSession(data)
        var now: UInt32 = 0
        _ = session.tick(now: now, keys: HeldKeys())
        session.appDeactivated()                                         // during the wipe
        finishWipe(session, now: &now)
        XCTAssertEqual(session.phase, .playing)
        let entry = session.frame(keys: HeldKeys())
        XCTAssertEqual(session.phase, .paused)
        XCTAssertTrue(entry.requests.contains(.haltAllSound))
        for _ in 0..<5 { _ = session.tick(now: now, keys: HeldKeys()); now += 1 }
        XCTAssertEqual(session.phase, .paused, "Caps Lock off is not enough after a deactivation")
        XCTAssertEqual(session.appActivated(keys: HeldKeys(capsLock: true)), SessionOutput())
        XCTAssertEqual(session.phase, .paused, "reactivated with Caps Lock on stays paused")
        let resumed = session.tick(now: now, keys: HeldKeys())
        XCTAssertEqual(session.phase, .playing)
        XCTAssertTrue(resumed.requests.contains(.hideCursor))

        // During the count-down: queued, the pause comes at the first frame of the next level.
        let s2 = try sessionAtAppear(data, now: &now)
        s2.state.levelRecord.words[6] = 0
        while s2.phase == .playing { _ = s2.frame(keys: HeldKeys()) }
        ticks(s2, now: &now) { $0.phase == .musicFade }
        s2.appDeactivated()
        ticks(s2, now: &now) { $0.phase != .playing }
        XCTAssertEqual(s2.state.level, 2)
        _ = s2.frame(keys: HeldKeys())
        XCTAssertEqual(s2.phase, .paused)
        XCTAssertEqual(s2.state.frame, 1)
    }

    /// Ruling 2 (demo) + demo end: an interruption during the wipe ends the demo at the next loop top (no frame
    /// runs); otherwise a demo ends on the core's stops.
    func testDemoInterruptQueuedAndDemoEnds() throws {
        let data = try gameData()
        var now: UInt32 = 0
        let demo = try GameSession(data: data, prefs: .defaults, mode: .demo, startLevel: 1, seed: 1,
                                   film: try data.levels.film(4))
        _ = demo.tick(now: now, keys: HeldKeys())
        demo.interrupt()
        finishWipe(demo, now: &now)
        let out = demo.frame(keys: HeldKeys())
        XCTAssertEqual(out.ended, .demoInterrupted)
        XCTAssertEqual(demo.state.frame, 0)
        XCTAssertFalse(demo.isInGame)

        // Uninterrupted FILM 4: the hero dies (D8) → the demo ends on the death-animation stop.
        let full = try GameSession(data: data, prefs: .defaults, mode: .demo, startLevel: 1, seed: 1,
                                   film: try data.levels.film(4))
        finishWipe(full, now: &now)
        var end: SessionEnd?
        for _ in 0..<3000 where end == nil { end = full.frame(keys: HeldKeys()).ended }
        XCTAssertEqual(end, .demoStopped([.heroDeathAnimationDone]))

        XCTAssertThrowsError(try GameSession(data: data, prefs: .defaults, mode: .demo, startLevel: 1, seed: 1,
                                             film: nil)) { XCTAssertEqual($0 as? GameSessionError, .demoNeedsFilm) }
    }

    /// Ruling 4: ⌘Q in play fades the music (`_StopMusic`) then quits with `.quit`; no prefs save is requested, and
    /// the session is in game until then.
    func testCommandQFadesThenQuitsWithoutSave() throws {
        let data = try gameData()
        var now: UInt32 = 0
        let session = try sessionAtAppear(data, now: &now)
        XCTAssertTrue(session.isInGame)
        let out = session.frame(keys: HeldKeys(codes: [0x0c], command: true))
        XCTAssertEqual(out.music, [.volume(0x100)])
        XCTAssertEqual(session.phase, .musicFade)
        XCTAssertTrue(session.isInGame)
        let rest = ticks(session, now: &now) { $0.phase != .ended }
        XCTAssertEqual(rest.music.last, .stopNow)
        XCTAssertEqual(rest.requests, [.quitNow])
        XCTAssertEqual(rest.ended, .quit)
        XCTAssertEqual(session.endReason, .quit)
        XCTAssertFalse(session.isInGame)
        XCTAssertFalse((out.requests + rest.requests).contains(.savePrefs))
    }

    /// The original would quit (`_LocationError` etc. → `StopReason.originalWouldAbort`): the game ends with
    /// `.originalWouldQuit`, and the exit sequence ends with `_ScreenToComp` and snd 27.
    func testOriginalWouldQuitEnd() throws {
        let data = try gameData()
        let session = try playSession(data)
        var now: UInt32 = 0
        finishWipe(session, now: &now)
        session.state.pendingStops.insert(.originalWouldAbort("test"))
        XCTAssertNil(session.frame(keys: HeldKeys()).ended)
        let out = session.frame(keys: HeldKeys())
        XCTAssertEqual(out.ended, .originalWouldQuit("test"))
        XCTAssertEqual(out.drawOps, [.screenToComp(Self.level1Rect)])
        XCTAssertEqual(out.requests.last, .disableAbout(false))
    }
}
