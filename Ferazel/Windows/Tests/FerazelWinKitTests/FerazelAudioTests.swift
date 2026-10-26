import FerazelCore
import FerazelRender
@testable import FerazelWinKit
import Foundation
import XCTest

/// `FerazelAudio` (moved from the Mac app unchanged, over `FerazelMixer`) on a fake mixer, and the headless frames
/// mode's silent mixer (Ruling 20). No audio device is opened.
@MainActor final class FerazelAudioTests: XCTestCase {
    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    private func cue(_ snd: Int16, idle: Bool = false) -> SoundCue {
        SoundCue(snd: snd, priority: 1, left: 0x100, right: 0x100, rate: 0x10000, onlyIfIdle: idle)
    }

    func testApplyOrderStopsBeforePlayIdleOnlyAndTrailingStops() throws {
        let r = try resources()
        let bank = try SoundBank(sounds: r.sounds)
        let a = bank.sounds[0].id
        let b = bank.sounds[1].id
        /// One fresh audio + tool per case; returns the tool after `apply`.
        func run(_ sounds: [SoundCue], _ stops: [Int16], _ stopAt: [Int]) -> SoundTool {
            let mixer = FakeMixer()
            let audio = FerazelAudio(mixer: mixer, musicDirectory: r.musicDirectory, log: { _ in })
            audio.loadSounds(bank, only: nil)
            audio.apply(sounds: sounds, stops: stops, stopAt: stopAt)
            return mixer.tools[0]
        }
        func playing(_ t: SoundTool) -> Set<Int16> { t.playingSounds() }
        // A stop placed before play 1 ends play 0's sound.
        XCTAssertEqual(playing(run([cue(a), cue(b)], [a], [1])), [b])
        // A stop placed before play 0 finds nothing yet.
        XCTAssertEqual(playing(run([cue(a), cue(b)], [a], [0])), [a, b])
        // A stop placed after the last play.
        XCTAssertEqual(playing(run([cue(a), cue(b)], [a], [2])), [b])
        // A stop recorded without its place goes last (the second stop, B).
        XCTAssertEqual(playing(run([cue(a), cue(b)], [a, b], [0])), [a])
        // `onlyIfIdle`: not made while an entry plays its snd — the mix equals one A; two A's mix louder.
        func mix(_ t: SoundTool) -> [Float] {
            var buffer = [Float](repeating: 0, count: 2 * SoundTool.blockFrames)
            buffer.withUnsafeMutableBufferPointer { t.render(into: $0, frames: SoundTool.blockFrames) }
            return buffer
        }
        let one = mix(run([cue(a)], [], []))
        XCTAssertEqual(mix(run([cue(a), cue(a, idle: true)], [], [])), one)
        XCTAssertNotEqual(mix(run([cue(a), cue(a)], [], [])), one)
        // After a stop the idle-only cue plays again.
        XCTAssertEqual(playing(run([cue(a), cue(a, idle: true)], [a], [1])), [a])
        // No Sound Tool (no mixer): nothing, no trap.
        FerazelAudio(mixer: nil, musicDirectory: r.musicDirectory, log: { _ in })
            .apply(sounds: [cue(a)], stops: [a], stopAt: [0])
    }

    func testResolveTrack() throws {
        let dir = try resources().musicDirectory
        let exists = { (n: Int) in
            FileManager.default.fileExists(atPath: dir.appendingPathComponent(MusicTrack.fileName(n)).path)
        }
        let rows: [(Int, Int?)] = [(-1, nil), (0, 1), (1, 1), (24, 24), (33, 1), (21, 20), (27, 26), (32, 30), (-2, 1)]
        for (n, want) in rows { XCTAssertEqual(FerazelAudio.resolveTrack(n, exists: exists), want, "track \(n)") }
        XCTAssertNil(FerazelAudio.resolveTrack(5, exists: { _ in false }), "none opens")
        XCTAssertEqual(FerazelAudio.resolveTrack(5, exists: { $0 == 1 }), 1)
    }

    func testMusicCueSequenceOnTheMixer() throws {
        let r = try resources()
        let mixer = FakeMixer()
        var logs: [String] = []
        let audio = FerazelAudio(mixer: mixer, musicDirectory: r.musicDirectory, log: { logs.append($0) })
        audio.handle(.play(track: 24))
        audio.handle(.volume(128))
        audio.handle(.play(track: 24))     // the same track: no reload
        audio.handle(.play(track: 21))     // absent → 20
        audio.handle(.stop)
        audio.handle(.play(track: -1))     // plays nothing
        audio.stopAll()
        let calls = mixer.calls.map { $0.hasPrefix("load ") ? String($0.split(separator: " ").prefix(2).joined(separator: " ")) : $0 }
        XCTAssertEqual(calls, [
            "stop v0", "load 0", "play 0 v0 vol0 loopsmax",
            "volume v0 128",
            "stop v0", "play 0 v0 vol0 loopsmax",
            "stop v0", "load 0", "play 0 v0 vol0 loopsmax",
            "stop v0",
            "stop v0",
            "stopAll",
        ])
        XCTAssertTrue(logs.isEmpty, "\(logs)")
        // No mixer: every cue is a no-op.
        let silent = FerazelAudio(mixer: nil, musicDirectory: r.musicDirectory, log: { _ in })
        silent.handle(.play(track: 24))
        silent.stopAll()
        XCTAssertTrue(silent.playingSounds().isEmpty)
    }

    func testSilentMixerDrainsTheSoundToolPerTick() throws {
        let bank = try SoundBank(sounds: try resources().sounds)
        func attached() -> (FerazelSilentMixer, SoundTool) {
            let m = FerazelSilentMixer()
            let t = SoundTool(bank: bank)
            m.attach(stream: t)
            return (m, t)
        }
        let (m, _) = attached()
        XCTAssertEqual((0..<4).map { _ in m.tick() }, [367, 368, 367, 368])
        let (m60, _) = attached()
        XCTAssertEqual((0..<60).map { _ in m60.tick() }.reduce(0, +), 22_050)
        XCTAssertEqual(m60.framesDrained, 22_050)
        // A cue stops "playing" on the tick its samples run out — the same tick every run.
        let snd = try XCTUnwrap(bank.sounds.max { $0.pcm.frames < $1.pcm.frames }).id   // the longest
        func ticksUntilSilent() -> Int {
            let (m, t) = attached()
            _ = t.play(snd: snd, priority: 1, left: 0x100, right: 0x100)
            for n in 1...6000 {
                m.tick()
                if !t.isPlaying(snd: snd) { return n }
            }
            return -1
        }
        let first = ticksUntilSilent()
        XCTAssertGreaterThan(first, 1)
        XCTAssertEqual(ticksUntilSilent(), first)
        // The driver's own silent mixer drains once per tick (the frames mode).
        let rig = try Rig()
        try rig.step()
        try rig.step()
        XCTAssertEqual((rig.driver.silentMixer?.framesDrained), 735)
    }
}
