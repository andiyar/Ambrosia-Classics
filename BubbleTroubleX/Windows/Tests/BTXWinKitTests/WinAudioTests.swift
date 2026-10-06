import BTXWinKit
import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import HectorAudio
import XCTest

/// `WinAudio` — the port of the Mac's `BTXAudio` — against a recording output: every cue → voice decision and the
/// D14 volume law. Synthetic PCM (no data needed): every id decodes to a 4-sample mono 22050 Hz sound; music set n
/// is snd 11000 + n.
final class WinAudioTests: XCTestCase {
    private func make(_ out: RecordingAudioOutput) -> WinAudio {
        WinAudio(output: out,
                 pcm: { _ in SndPCM(sampleRate: 22_050, channels: 1, frames: 4, samples: [0, 1, 2, 3]) },
                 musicResourceID: { set in
                     guard (1...4).contains(set) else { throw CocoaError(.fileNoSuchFile) }
                     return 11_000 + set
                 })
    }

    private func cue(_ slot: Int, _ priority: Int = 20) -> SoundCue {
        SoundCue(slot: slot, priority: priority, delayFrames: 0)
    }

    func testEffectsAreUploadedOnce() {
        let out = RecordingAudioOutput()
        _ = make(out)
        XCTAssertEqual(out.calls.count, 48)
        XCTAssertEqual(out.calls.first, .load(id: 9000, count: 4, channels: 1, rate: 22_050))
        XCTAssertEqual(out.calls.last, .load(id: 9047, count: 4, channels: 1, rate: 22_050))
    }

    /// D14.2: the Sound Tool's 0x80 unity → 0x10/0x40/0x100 play at 0x20/0x80/0x100 of the output's law; 1 = off.
    func testEffectVolumeLaw() {
        XCTAssertNil(WinAudio.sfxVolume(pref: 1))
        XCTAssertEqual([2, 3, 4].map { WinAudio.effectOutputVolume(WinAudio.sfxVolume(pref: $0)!) }, [0x20, 0x80, 0x100])
        XCTAssertEqual([1, 2, 3, 4].map(WinAudio.musicVolume(pref:)), [0, 0x40, 0x80, 0x100])
        let out = RecordingAudioOutput()
        let audio = make(out)
        for (pref, volume) in [(2, Float(0x20)), (3, 0x80), (4, 0x100)] {
            out.calls = []; out.playing = []
            audio.sfxVolumePref = pref
            audio.play(cue(5))
            XCTAssertEqual(out.calls, [.play(id: 9005, voice: 0, volume: volume, loops: 1)])
        }
        out.calls = []
        audio.sfxVolumePref = 1
        audio.play(cue(5))
        XCTAssertEqual(out.calls, [], "effects off")
        out.playing = []
        audio.play(cue(13), sfxLevel: 4)                            // the prefs Music popup's snd 13
        XCTAssertEqual(out.calls, [.play(id: 9013, voice: 0, volume: 0x100, loops: 1)])
        out.calls = []
        audio.sfxVolumePref = 3
        audio.play(cue(48))
        XCTAssertEqual(out.calls, [], "slot 48 = snd 9048 is not an effect")
    }

    /// `ST_PlaySoundParam`: free voices first; then the lowest-priority busy voice ≤ the new priority, oldest of
    /// equals; else dropped.
    func testVoiceChoiceAndStealing() {
        let out = RecordingAudioOutput()
        let audio = make(out)
        audio.play(cue(1, 20)); audio.play(cue(2, 10)); audio.play(cue(3, 30)); audio.play(cue(4, 10))
        XCTAssertEqual(out.nonLoadCalls.map { if case let .play(_, v, _, _) = $0 { v } else { -1 } }, [0, 1, 2, 3])
        out.calls = []
        audio.play(cue(5, 1))
        XCTAssertEqual(out.calls, [], "priority 1 steals nothing")
        audio.play(cue(6, 10))                                      // voices 1 and 3 at 10: the older, 1
        XCTAssertEqual(out.calls, [.play(id: 9006, voice: 1, volume: 0x80, loops: 1)])
        out.calls = []
        audio.play(cue(7, 10))                                      // now 3 is the oldest 10
        XCTAssertEqual(out.calls, [.play(id: 9007, voice: 3, volume: 0x80, loops: 1)])
        XCTAssertEqual(WinAudio.chooseVoice(priority: 5, busy: [true, false], priorities: [9, 9], serials: [1, 2]), 1)
    }

    func testHaltStopsEffectVoicesOnly() {
        let out = RecordingAudioOutput()
        let audio = make(out)
        audio.haltEffects()
        XCTAssertEqual(out.nonLoadCalls, [.stop(0), .stop(1), .stop(2), .stop(3)])
    }

    /// `_LoadMusic` / `_StartMusic` (D14.3) / stop / pause / resume / unload / volume on voice 4.
    func testMusicCues() {
        let out = RecordingAudioOutput()
        let audio = make(out)
        out.calls = []
        audio.apply(.start)
        audio.apply(.pause)
        XCTAssertEqual(out.calls, [], "nothing loaded: every cue but load is inert")
        audio.apply(.load(set: 3))
        XCTAssertEqual(audio.musicID, 11_003)
        XCTAssertEqual(out.calls, [.load(id: 11_003, count: 4, channels: 1, rate: 22_050)])
        audio.apply(.load(set: 1))
        XCTAssertEqual(audio.musicID, 11_003, "no-op while loaded")
        out.calls = []
        // Outside a game: title music only with bool 0x40.
        audio.titleMusicPref = false
        audio.apply(.start)
        XCTAssertEqual(out.calls, [.play(id: 11_003, voice: 4, volume: 0, loops: 50)])
        // Busy channel: carries on at the new volume.
        out.calls = []
        audio.titleMusicPref = true
        audio.musicVolumePref = 3
        audio.apply(.start)
        XCTAssertEqual(out.calls, [.setVolume(4, 0x80)])
        out.calls = []
        audio.apply(.volume(0x35))
        audio.apply(.pause)
        audio.apply(.resume)
        audio.apply(.stopNow)
        XCTAssertEqual(out.calls, [.setVolume(4, 0x35), .pause(4), .resume(4), .stop(4)])
        // In a game the music volume applies whatever bool 0x40 says.
        out.calls = []
        audio.titleMusicPref = false
        audio.gameRunning = true
        audio.apply(.start)
        XCTAssertEqual(out.calls, [.play(id: 11_003, voice: 4, volume: 0x80, loops: 50)])
        out.calls = []
        audio.apply(.unload)
        XCTAssertNil(audio.musicID)
        XCTAssertEqual(out.calls, [.stop(4)])
        out.calls = []
        audio.apply(.load(set: 9))
        XCTAssertNil(audio.musicID, "a set without music stays unloaded")
        XCTAssertEqual(out.calls, [])
    }

    /// `_UpdateMusicVolume`: nothing unloaded; idle out of a game → `_StartMusic`; else the channel volume.
    func testUpdateMusicVolume() {
        let out = RecordingAudioOutput()
        let audio = make(out)
        out.calls = []
        audio.updateMusicVolume()
        XCTAssertEqual(out.calls, [])
        audio.apply(.load(set: 2))
        out.calls = []
        audio.updateMusicVolume()
        XCTAssertEqual(out.calls, [.play(id: 11_002, voice: 4, volume: 0x100, loops: 50)])
        out.calls = []
        audio.titleMusicPref = false
        audio.updateMusicVolume()
        XCTAssertEqual(out.calls, [.setVolume(4, 0)])
        out.calls = []
        audio.gameRunning = true
        audio.musicVolumePref = 2
        audio.updateMusicVolume()
        XCTAssertEqual(out.calls, [.setVolume(4, 0x40)])
    }

    /// The real output: `PCMMixer` takes the same calls (offline — never a device).
    func testPCMMixerIsAnOutput() {
        let mixer = PCMMixer(voices: WinAudio.effectVoices + 1, outputRate: 48_000)
        let audio = WinAudio(output: mixer,
                             pcm: { _ in SndPCM(sampleRate: 22_050, channels: 1, frames: 2_205,
                                                samples: Array(repeating: 1_000, count: 2_205)) },
                             musicResourceID: { 11_000 + $0 })
        audio.play(SoundCue(slot: 0, priority: 1, delayFrames: 0))
        XCTAssertTrue(mixer.isPlaying(voice: 0))
        audio.haltEffects()
        XCTAssertFalse(mixer.isPlaying(voice: 0))
    }
}
