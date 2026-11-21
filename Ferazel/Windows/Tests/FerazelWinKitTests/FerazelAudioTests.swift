import FerazelCore
@testable import FerazelRender
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

    /// 6A-RN: a looped cue (`SoundCue.loops`, `.STPlayLoopedSound` — the rain loop, snd 452) on the Sound Tool through
    /// `FerazelAudio.apply`: when its countdown runs out the entry is re-played at once with its id (`.STLoopCallBack`,
    /// reason 1, M l. 78640–78644 → `FUN_10091208`) and plays its samples again from the start. The countdown pass goes
    /// on at the same index (`iVar9 − 1`, then `+ 1`), so it meets the re-played entry in the same pass and takes one
    /// block off it: after the first pass the loop repeats every countdown − 1 blocks. A plain cue of the same sound is
    /// gone after the first pass; a stop (`FUN_10091504`, reason 2 — ignored) ends the loop.
    func testLoopedCueOnTheMixer() throws {
        let r = try resources()
        let bank = try SoundBank(sounds: r.sounds)
        XCTAssertTrue(bank.sounds.contains { $0.id == 452 }, "snd 452 in the Sounds file")
        func rig(_ sounds: [SoundCue]) -> (FerazelAudio, SoundTool) {
            let mixer = FakeMixer()
            let audio = FerazelAudio(mixer: mixer, musicDirectory: r.musicDirectory, log: { _ in })
            audio.loadSounds(bank, only: nil)
            audio.apply(sounds: sounds, stops: [], stopAt: [])
            return (audio, mixer.tools[0])
        }
        func blocks(_ t: SoundTool, _ n: Int) -> [Float] {
            var buffer = [Float](repeating: 0, count: 2 * SoundTool.blockFrames * n)
            buffer.withUnsafeMutableBufferPointer { t.render(into: $0, frames: SoundTool.blockFrames * n) }
            return buffer
        }
        let loop = SoundCue(snd: 452, priority: 1, left: 65, right: 65, rate: 0x10000, loops: true)
        var plain = loop
        plain.loops = false
        // The entry's full countdown (blocks), and its id.
        let (_, looped) = rig([loop])
        let entry = try XCTUnwrap(looped.snapshot().first)
        XCTAssertTrue(entry.loops)
        XCTAssertEqual([entry.left, entry.right], [65, 65])
        let c = Int(entry.countdown)
        XCTAssertGreaterThan(c, 1)
        // The first pass, then the repeats: re-played with its id, one block already taken by the same pass; every
        // repeat plays the sound's first c − 1 blocks again from its start.
        let first = blocks(looped, c)
        var again = entry
        again.countdown = Int32(c - 1)
        XCTAssertEqual(looped.snapshot(), [again], "re-played once its countdown ran out, in the same pass")
        let period = Array(first.prefix(2 * SoundTool.blockFrames * (c - 1)))
        XCTAssertTrue(blocks(looped, c - 1) == period, "the loop's second pass: the same samples, c − 1 blocks")
        XCTAssertEqual(looped.snapshot(), [again])
        XCTAssertTrue(blocks(looped, c - 1) == period, "and the third")
        XCTAssertTrue(looped.isPlaying(snd: 452))
        XCTAssertEqual(looped.playingSounds(), [452])
        // The same cue unlooped: gone after the first pass.
        let (_, once) = rig([plain])
        XCTAssertTrue(blocks(once, c) == first, "the first pass is the same sound")
        XCTAssertFalse(once.isPlaying(snd: 452))
        XCTAssertTrue(once.snapshot().isEmpty)
        // A stop ends the loop for good.
        let (audio, stopped) = rig([loop])
        _ = blocks(stopped, c / 2)
        audio.apply(sounds: [], stops: [452], stopAt: [0])
        XCTAssertFalse(stopped.isPlaying(snd: 452))
        _ = blocks(stopped, 2 * c)
        XCTAssertTrue(stopped.snapshot().isEmpty, "no re-play after a stop")
        // Beside another entry: the re-play goes through the play rule (priority, then volume) — a louder plain entry
        // of the same priority stays ahead of it.
        let other = try XCTUnwrap(bank.sounds.first { $0.id != 452 }).id
        let (_, both) = rig([loop, SoundCue(snd: other, priority: 1, left: 0x80, right: 0x80, rate: 0x10000)])
        XCTAssertEqual(both.snapshot().map(\.snd), [other, 452])
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
        // …and that tick follows from the sound's sample count: blocks = ⌈(frames − 1) / 1024⌉ (≥ 1), the countdown
        // = blocks scaled by the 16.16 step (rate / 22,050 Hz); a 1024-frame block is mixed whenever the drain
        // reaches a multiple of 1024 frames (the first at frame 0) and the entry goes after its countdown-th block —
        // so on the first tick whose running total ⌊22,050·n / 60⌋ passes (countdown − 1)·1024.
        let sound = try XCTUnwrap(bank.sounds.first { $0.id == snd })
        let blocks = Int64(max((max(sound.pcm.frames - 1, 0) + 0x3ff) >> 10, 1))
        let base = (Int64(UInt32(sound.pcm.sampleRate * 65536) >> 8) << 16) / Int64(SoundTool.outputRateFixed >> 8)
        let countdown = max(Int((((blocks << 16) << 16) / base) >> 16), 1)   // FixDiv, then the 16.16 integer part
        let probe = SoundTool(bank: bank)
        probe.play(snd: snd, priority: 1, left: 0x100, right: 0x100)
        XCTAssertEqual(Int(try XCTUnwrap(probe.snapshot().first).countdown), countdown)
        let runOut = (1...).first { n in 22_050 * n / 60 > (countdown - 1) * SoundTool.blockFrames }!
        XCTAssertEqual(first, runOut, "\(countdown) blocks")
        // The driver's own silent mixer drains once per tick (the frames mode), after the tick's cues: a cue played on a
        // tick whose drain crosses a block boundary has already lost that block when the tick returns (the Sound Tool's
        // frames count from its attach, at the boot's sound load).
        let rig = try Rig(mute: true, mixer: .headless)
        try rig.step()
        try rig.step()
        XCTAssertEqual((rig.driver.silentMixer?.framesDrained), 735)
        /// Blocks the Sound Tool has mixed after `f` frames (one at frame 0, then one per 1024).
        func blocksMixed(_ f: Int) -> Int { f == 0 ? 0 : (f - 1) / SoundTool.blockFrames + 1 }
        var checked = 0
        for _ in 0..<1000 where checked == 0 {
            let before = try XCTUnwrap(rig.driver.silentMixer).streamFrames
            let older = Set(rig.driver.silentMixer?.stream?.snapshot().map(\.id) ?? [])
            let out = try rig.step(rig.flow.state == .mainMenu
                                   ? FrontInput(keys: KeyState(pressed: [MainMenu.newGameKey])) : FrontInput())
            let after = try XCTUnwrap(rig.driver.silentMixer).streamFrames
            let crossed = Int32(blocksMixed(after) - blocksMixed(before))
            guard crossed > 0, let tool = rig.driver.silentMixer?.stream, out.soundStops.isEmpty else { continue }
            for cue in out.sounds where !cue.onlyIfIdle {
                // This tick's new entry for the cue; its full countdown from a fresh tool.
                let entry = tool.snapshot().filter { $0.snd == cue.snd && !older.contains($0.id) }.max { $0.id < $1.id }
                let fresh = SoundTool(bank: bank)
                fresh.play(snd: cue.snd, priority: UInt16(clamping: cue.priority), left: UInt16(clamping: cue.left),
                           right: UInt16(clamping: cue.right), rate: Int32(bitPattern: cue.rate))
                let full = try XCTUnwrap(fresh.snapshot().first).countdown
                if full > crossed {
                    XCTAssertEqual(entry?.countdown, full - crossed, "snd \(cue.snd) at tick \(rig.ticks)")
                } else {
                    XCTAssertNil(entry, "snd \(cue.snd) at tick \(rig.ticks): ran out inside the tick's drain")
                }
                checked += 1
                break
            }
        }
        XCTAssertGreaterThan(checked, 0, "a cue on a block-crossing tick")
    }
}
