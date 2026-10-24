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

    func testIdleQueryReadsShellSet() throws {
        let v = SoundVoices(playing: [493])
        XCTAssertTrue(v.isPlaying(493))
        XCTAssertFalse(v.isPlaying(494))
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
    }
}
