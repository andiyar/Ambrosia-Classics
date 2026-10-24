import XCTest
@testable import FerazelCore

/// VS (docs/plans/2026-10-24-ferazel-phase4.md, S2 `SoundVoices`, Ruling 5): the live voice query — `FUN_100916dc(snd)`
/// (M l. 78378, the Sound Tool's count of voices playing `snd`) read at an idle-only call site
/// (`if (!FUN_100916dc(snd)) STPlay3DSoundRand(…)`, e.g. M l. 61047/61056) as the shell's playing set at the
/// iteration's start, plus the iteration's own plays, minus its stops after their last play (the
/// `FrameOps.soundStopAt` call order). A missing data file is a FAILURE, never a skip.
final class SoundVoicesTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    private final class StubServices: LevelServices {
        func prepare(level: Int) throws -> LevelFaces { LevelFaces() }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {}
        func deathEffectStep(_ k: Int) throws {}
    }

    /// The file seam a save point needs (nothing is written: the panel is cancelled).
    private final class NoFiles: FrontFiles {
        func loadPrefs() -> Data? { nil }
        func storePrefs(_ record: Data) throws {}
        func readSavedGame(_ ref: SavedGameRef) throws -> SaveBlock { SaveBlock() }
        func writeSavedGame(_ block: SaveBlock, to ref: SavedGameRef) throws(SaveWriteError) {}
    }

    func testIdleQueryReadsShellSet() throws {
        let v = SoundVoices(playing: [493])
        XCTAssertTrue(v.isPlaying(493))
        XCTAssertFalse(v.isPlaying(494))
        // An unloaded snd (602, a nil handle): `FUN_100916dc(0)` counts every entry, `FUN_10091504(0)` stops every one.
        XCTAssertFalse(SoundSlots.isLoaded(602))
        XCTAssertTrue(v.isPlaying(602))
        XCTAssertFalse(SoundVoices().isPlaying(602))
        XCTAssertEqual(SoundVoices(playing: [493, 494]).applying(sounds: [], stops: [602], stopAt: [0]).playing, [])
        // The session's iteration reads the set the shell passed for it (and the default stays empty).
        let s = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 1, seed: 1)
        _ = s.step(keys: KeyState(), playing: [493])
        XCTAssertTrue(s.world.isSoundPlaying(493))
        XCTAssertFalse(s.world.isSoundPlaying(494))
        _ = s.step(keys: KeyState())
        XCTAssertFalse(s.world.isSoundPlaying(493))
    }

    func testFrameCuesAndStopsCount() throws {
        let s = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 1, seed: 1)
        _ = s.step(keys: KeyState())
        // Mid-iteration: the calls made so far (`PlayerState.soundCalls`, in call order) count.
        XCTAssertFalse(s.world.isSoundPlaying(489))
        s.world.player.cue(PlayerCue(call: .reg, snd: 489, priority: 1, volume: 0x100))
        XCTAssertTrue(s.world.isSoundPlaying(489))                   // played earlier in the iteration
        s.world.player.cue(PlayerCue(call: .stop, snd: 489))
        XCTAssertFalse(s.world.isSoundPlaying(489))                  // then stopped
        s.world.player.cue(PlayerCue(call: .reg, snd: 489, priority: 1, volume: 0x100))
        XCTAssertTrue(s.world.isSoundPlaying(489))                   // a stop then a play
        s.world.player.soundCalls = []
        // A play with sound off takes no voice (every `STPlay*` returns at once).
        var off = FerazelPrefs()
        off.soundOn = 0
        XCTAssertFalse(SoundVoices(prefs: off).isPlaying(489, after: [
            PlayerState.SoundCall(cue: PlayerCue(call: .reg, snd: 489, priority: 1, volume: 0x100), scrollH: 0, scrollV: 0)]))
        // An iteration's emitted ops, ordered by `soundStopAt`: play 489, stop 489, play 490, stop 490 then play it.
        var ops = FrameOps()
        let cue = { (snd: Int16) in SoundCue(snd: snd, priority: 1, left: 0x40, right: 0x40, rate: 0x10000) }
        ops.sounds.append(cue(489))
        ops.stopSound(489)
        ops.sounds.append(cue(490))
        ops.stopSound(490)
        ops.sounds.append(cue(490))
        ops.stopSound(493)
        let after = SoundVoices(playing: [493, 494])
            .applying(sounds: ops.sounds, stops: ops.soundStops, stopAt: ops.soundStopAt)
        XCTAssertEqual(ops.soundStopAt, [1, 2, 3])
        XCTAssertFalse(after.isPlaying(489))
        XCTAssertTrue(after.isPlaying(490))
        XCTAssertFalse(after.isPlaying(493))
        XCTAssertTrue(after.isPlaying(494))
    }

    func testLevelRunPassesPlayingSet() throws {
        let r = try resources()
        let prefs = FerazelPrefs()
        let run = try LevelRun(resources: r, prefs: prefs, level: 2, seed: 1, carry: LevelCarry(), save: SaveBlock(),
                               fade: ScreenFade(), music: MusicFade(), services: StubServices(),
                               sounds: StageSounds(prefs: prefs, lengths: [800: 30, 801: 40, 802: 50, 803: 5,
                                                                           804: 7, 805: 20]),
                               start: nil, refreshFacing: true, skipStageComplete: false)
        var t: UInt32 = 0
        /// Ticks until a tick steps the session; returns that tick's session.
        func stepTick(_ input: FrontInput) throws -> FerazelSession {
            for _ in 0..<4000 {
                _ = try run.tick(now: t, input: input)
                t &+= 1
                if !run.lastSteps.isEmpty, let s = run.session { return s }
            }
            XCTFail("the run did not step")
            throw XCTSkip("unreachable")
        }
        _ = try stepTick(FrontInput())
        let s = try stepTick(FrontInput(playing: [421]))
        XCTAssertEqual(s.world.voices.playing, [421])
        XCTAssertTrue(s.world.isSoundPlaying(421))
        _ = try stepTick(FrontInput())
        XCTAssertFalse(s.world.isSoundPlaying(421))

        // Level 1 runs: the shell set is empty until the ticks that resume a suspended frame, which poll [421].
        let L1 = try LevelFile.load(from: r, level: 1)
        let marked = FrontInput(playing: [421])
        func level1(_ p: FerazelPrefs = FerazelPrefs(), start: (x: Int, y: Int)? = nil,
                    files: FrontFiles? = nil) throws -> LevelRun {
            try LevelRun(resources: r, prefs: p, level: 1, seed: 1, carry: LevelCarry(), save: SaveBlock(),
                         fade: ScreenFade(), music: MusicFade(), services: StubServices(),
                         sounds: StageSounds(prefs: p, lengths: [:]), start: start, files: files)
        }
        func drive(_ run: LevelRun, _ input: (LevelRun) -> FrontInput = { _ in FrontInput() },
                   until: (LevelRun) -> Bool) throws {
            for _ in 0..<6000 {
                _ = try run.tick(now: t, input: input(run))
                t &+= 1
                if until(run) { return }
            }
            XCTFail("the run did not reach the condition")
        }
        /// The tick's last session call was a resume (the frame finished, no further step) and it read [421].
        func assertResumed(_ run: LevelRun, _ what: String) throws {
            let s = try XCTUnwrap(run.session)
            XCTAssertNil(s.suspension, what)
            XCTAssertEqual(run.lastSteps.count, 1, what)
            XCTAssertTrue(s.world.voices.playing.contains(421), "\(what): the resume reads the tick's shell set")
        }
        // A save point (`resume(.savePoint)` after the put-file panel is cancelled).
        let point = L1.placements[24]
        let save = try level1(start: (Int(point.x) - 8, Int(point.y) + 0x3f - 0x55 + 1), files: NoFiles())
        try drive(save) { $0.session?.suspension != nil }
        save.fileDone(.cancelled)
        _ = try save.tick(now: t, input: marked)
        t &+= 1
        try assertResumed(save, "save point")
        // A sign read (`resume(.sign)`), answered with any key.
        let sign = L1.placements[1]
        let talk = try level1(start: (Int(sign.x) - 0x26 + 8, Int(sign.y) + 0x1f - 0x55))
        try drive(talk) { $0.conversation != nil }
        try drive(talk, { FrontInput(keys: KeyState(pressed: $0.conversation?.wait == .anyKey ? [0x01] : []),
                                     playing: [421]) }) { $0.conversation == nil }
        try assertResumed(talk, "sign")
        // A Caps Lock pause (`resume(.gameLoopKeys)`), released.
        let keys = try level1()
        try drive(keys) { $0.session.map { $0.world.gammaFade.done } == true && $0.iterations >= 60 }
        try drive(keys, { _ in FrontInput(capsLock: true) }) { $0.pause != nil }
        try drive(keys, { _ in marked }) { $0.pause == nil }
        try assertResumed(keys, "pause")
        // The pass-through: on a tick that runs a pair (Reduce Frame Rate, an undrawn iteration), the second step reads
        // the first's play (snd 489, cued before the tick) on top of the shell's (empty) set.
        var reduced = FerazelPrefs()
        reduced.reduceFrameRate = 1
        let pair = try level1(reduced)
        var paired = false
        for _ in 0..<6000 where !paired {
            pair.session?.world.player.cue(PlayerCue(call: .reg, snd: 489, priority: 1, volume: 0x100))
            _ = try pair.tick(now: t, input: FrontInput())
            t &+= 1
            if pair.lastSteps.count == 2, pair.lastSteps[0].sounds.contains(where: { $0.snd == 489 }) {
                paired = true
                XCTAssertTrue(try XCTUnwrap(pair.session).world.voices.playing.contains(489))
            }
        }
        XCTAssertTrue(paired, "no paired tick")
    }
}
