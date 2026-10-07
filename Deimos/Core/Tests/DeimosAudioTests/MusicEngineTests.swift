import XCTest
@testable import DeimosAudio
import DeimosCore
import HectorAudio

/// Phase 2 A2 — the music streamer (bank sound-music §6) and `DeimosAudioEngine` (plan S5): one pull source,
/// unity gain (Q4 RULED, D31), the positional halt. Every render is bounded by an explicit `maxFrames` (plan G11).
final class MusicEngineTests: XCTestCase {
    private static let maxFrames = 1 << 16

    // MARK: Fixtures

    /// A synthetic AIFC `ima4` file: `packets` packet-frames of `channels` channels, bytes from a fixed LCG, each
    /// packet's preamble a valid predictor/index; rate as an 80-bit extended.
    /// `chained`: every later packet's preamble is the channel's running state after the previous packet (its
    /// predictor's high 9 bits + its index) — the case where the kit continues at full precision (re-sync carry);
    /// `chainOffset` moves that predictor first (> 0x7F: index equal, predictor too far → the header is loaded).
    /// `firstHeader`: packet 0's preamble for every channel (e.g. an index field > 88, which clamps to 88).
    static func aifc(packets: Int, channels: Int = 2, rate: Double = 44100, seed: UInt32 = 0x1234_5678,
                     chained: Bool = false, chainOffset: Int = 0, firstHeader: UInt16? = nil) -> Data {
        var x = seed
        func next() -> UInt8 { x = x &* 1_103_515_245 &+ 12345; return UInt8(truncatingIfNeeded: x >> 16) }
        let indexTable = [-1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8]
        var body: [UInt8] = []
        var runIndex = [Int](repeating: 0, count: channels)
        for p in 0..<packets {
            for ch in 0..<channels {
                var pre = (UInt16(truncatingIfNeeded: Int(next()) << 8 | Int(next())) & 0xFF80) | UInt16(next() % 89)
                if p == 0, let firstHeader { pre = firstHeader }
                if chained, p > 0 {
                    let pcm = IMA4.decode(body, packetFrames: p, channels: channels)
                    let last = min(max(Int(pcm[(p * 64 - 1) * channels + ch]) + chainOffset, -32768), 32767)
                    pre = UInt16(bitPattern: Int16(last)) & 0xFF80 | UInt16(runIndex[ch])
                }
                body += [UInt8(pre >> 8), UInt8(pre & 0xFF)]
                var index = min(Int(pre & 0x7F), 88)
                for _ in 0..<32 {
                    let b = next()
                    body.append(b)
                    for nib in [Int(b & 0x0F), Int(b >> 4)] { index = min(max(index + indexTable[nib], 0), 88) }
                }
                runIndex[ch] = index
            }
        }
        func be32(_ v: Int) -> [UInt8] { [UInt8(v >> 24 & 0xFF), UInt8(v >> 16 & 0xFF), UInt8(v >> 8 & 0xFF), UInt8(v & 0xFF)] }
        func ext80(_ v: Double) -> [UInt8] {
            let e = Int(v.exponent), m = UInt64(v.significandBitPattern) << 11 | 1 << 63
            let ex = UInt16(16383 + e)
            return [UInt8(ex >> 8), UInt8(ex & 0xFF)] + (0..<8).map { UInt8(truncatingIfNeeded: m >> (56 - 8 * $0)) }
        }
        var comm: [UInt8] = [UInt8(channels >> 8), UInt8(channels & 0xFF)] + be32(packets) + [0, 16] + ext80(rate)
        comm += Array("ima4".utf8) + [0, 0]                               // compression type + empty pstring (padded)
        let ssnd = be32(0) + be32(0) + body
        var chunks: [UInt8] = Array("COMM".utf8) + be32(comm.count) + comm
        chunks += Array("SSND".utf8) + be32(ssnd.count) + ssnd
        return Data(Array("FORM".utf8) + be32(4 + chunks.count) + Array("AIFC".utf8) + chunks)
    }

    /// The kit's decode of a whole (small) file — the oracle.
    static func kitFrames(_ file: Data, packets: Int? = nil) throws -> [Int16] {
        let a = try AIFFAudio(data: file)
        let p = packets ?? a.frameCount
        return IMA4.decode([UInt8](a.soundData.prefix(p * 34 * a.channels)), packetFrames: p, channels: a.channels)
    }

    /// The kit's decode of the sound data repeated `passes` times — one continuous packet stream, decoder state
    /// carried across each wrap (bank §6.3: `FUN_100d0968` refills the same buffer from the SSND start).
    static func kitLooped(_ file: Data, passes: Int) throws -> [Int16] {
        let a = try AIFFAudio(data: file)
        let one = [UInt8](a.soundData.prefix(a.frameCount * 34 * a.channels))
        return IMA4.decode(Array([[UInt8]](repeating: one, count: passes).joined()),
                           packetFrames: a.frameCount * passes, channels: a.channels)
    }

    /// An engine with the given effects and music files (parsed as at init) keyed by tag.
    static func engine(effects: EffectMixer = EffectMixer(), music: [String: Data] = [:]) throws -> DeimosAudioEngine {
        var tracks: [FourCC: MusicTrack] = [:]
        for (tag, file) in music { tracks[FourCC(tag)!] = try MusicTrack(soundFile: file) }
        return DeimosAudioEngine(effects: effects, tracks: tracks)
    }

    /// Renders `frames` frames in chunks of `chunk`.
    static func render(_ e: DeimosAudioEngine, frames: Int, chunk: Int = 333) -> [Float] {
        precondition(frames <= maxFrames, "render bound (plan G11)")
        var out = [Float](repeating: 0, count: 2 * frames)
        var f = 0
        out.withUnsafeMutableBufferPointer { buf in
            while f < frames {
                let n = min(chunk, frames - f)
                e.render(into: UnsafeMutableBufferPointer(rebasing: buf[(2 * f)...]), frames: n)
                f += n
            }
        }
        return out
    }

    private static let assets: Result<DeimosAssets, Error> = Result { try DeimosAssets.load(index: AudioTestData.index()) }

    // MARK: Tests

    func testMusicAmpFullScale255() throws {
        // FUN_100482c0: int pref 1 = 100 → m 128; 50 → 64; 0 → 0; out-of-range clamps (inclusive).
        XCTAssertEqual(MusicStream.level(pref: 100), 128)
        XCTAssertEqual(MusicStream.level(pref: 50), 64)
        XCTAssertEqual(MusicStream.level(pref: 0), 0)
        XCTAssertEqual(MusicStream.level(pref: 250), 128)
        XCTAssertEqual(MusicStream.level(pref: -5), 0)
        // FUN_100d0470 / FUN_100d136c with fade 0x100: amp = min(255, m·0x100 >> 8).
        XCTAssertEqual(MusicStream.amp(level: 128), 128)
        XCTAssertEqual(MusicStream.amp(level: 0x100), 255)                  // the no-sound-init level (data image)
        XCTAssertEqual(MusicStream.amp(level: 0x300), 255)                  // m capped at 0x100 first
        XCTAssertEqual(MusicStream.gain(amp: 128), Float(128) / 255)        // Q3 default: 255 = full scale

        // The engine's music is decoded × 128/255 at the default pref, and follows a `.level` cue.
        let file = Self.aifc(packets: 2)
        let pcm = try Self.kitFrames(file)
        let e = try Self.engine(music: ["mu03": file])
        XCTAssertEqual(e.withState { $0.musicLevel }, 128)
        e.apply(sounds: [], music: [.play(FourCC("mu03")!, loop: true)], haltEffectsAt: nil)
        let out = Self.render(e, frames: 64)
        let g = Float(128) / 255
        for i in 0..<128 { XCTAssertEqual(out[i], Float(pcm[i]) / 32768 * g, "sample \(i)") }
        e.apply(sounds: [], music: [.level(50)], haltEffectsAt: nil)
        let half = Self.render(e, frames: 64)
        for i in 0..<128 { XCTAssertEqual(half[i], Float(pcm[128 + i]) / 32768 * (Float(64) / 255), "sample \(i)") }
    }

    func testMusicLoopsSeamlessly() throws {
        let file = Self.aifc(packets: 2)                                    // 128 frames
        let pcm = try Self.kitFrames(file)
        XCTAssertEqual(pcm.count, 256)
        let looped = try Self.kitLooped(file, passes: 4)
        XCTAssertEqual(Array(looped[256..<512]), pcm)                      // this fixture: the wrap reloads packet 0's header
        var s = MusicStream(track: try MusicTrack(soundFile: file), loop: true)
        var frames: [(Int16, Int16)] = []
        for _ in 0..<(3 * 128 + 5) { frames.append(s.nextFrame()) }         // bounded: 389 frames
        // nextFrame ran 2 ahead at init (the resampler's a/b): compare from the stream's own start.
        for (k, f) in frames.enumerated() {
            let i = k + 2
            XCTAssertEqual(f.0, looped[2 * i], "frame \(i) L"); XCTAssertEqual(f.1, looped[2 * i + 1], "frame \(i) R")
        }
        // Through the output path: the frame after the last is frame 0 (and 1, 2, …), on every pass.
        var t = MusicStream(track: try MusicTrack(soundFile: file), loop: true)
        var out = [Float](repeating: 0, count: 2 * 300)
        out.withUnsafeMutableBufferPointer { t.mix(into: $0, frames: 300, gain: 1) }
        for k in 0..<300 {
            XCTAssertEqual(out[2 * k], Float(looped[2 * k]) / 32768, "out \(k) L")
            XCTAssertEqual(out[2 * k + 1], Float(looped[2 * k + 1]) / 32768, "out \(k) R")
        }
        // The decoder state CARRIES across the wrap: when the last packet's end state satisfies the re-sync rule
        // against packet 0's preamble (index equal, predictor within 0x7F), the next pass's frame 0 continues from
        // the running predictor, not from the preamble. Fixture: a mono 1-packet file whose preamble is (0x7F80, 88) and whose own decode ends at index 88 with a
        // predictor ≠ 0x7F80 within 0x7F of it (bounded seed search).
        var wrapFile: Data?
        for seed in UInt32(1)...4000 {
            let f = Self.aifc(packets: 1, channels: 1, seed: seed, firstHeader: 0x7F80 | 88)
            let a = try AIFFAudio(data: f)
            var index = 88
            for b in a.soundData.dropFirst(2).prefix(32) {
                for nib in [Int(b & 0x0F), Int(b >> 4)] {
                    index = min(max(index + [-1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8][nib], 0), 88)
                }
            }
            let last = Int(try Self.kitFrames(f)[63])
            if index == 88, last != 0x7F80, abs(last - 0x7F80) <= 0x7F { wrapFile = f; break }
        }
        let wf = try XCTUnwrap(wrapFile, "no re-sync fixture within 4000 seeds")
        let wp = try Self.kitFrames(wf)
        let wl = try Self.kitLooped(wf, passes: 3)
        XCTAssertNotEqual(wl[64], wp[0])                                    // the carry is visible at the wrap
        var w = MusicStream(track: try MusicTrack(soundFile: wf), loop: true)
        var wo = [Float](repeating: 0, count: 2 * 130)
        wo.withUnsafeMutableBufferPointer { w.mix(into: $0, frames: 130, gain: 1) }
        for k in 0..<130 { XCTAssertEqual(wo[2 * k], Float(wl[k]) / 32768, "wrap frame \(k)") }
        // A file at half the output rate is linearly resampled to 44.1 kHz, across the loop too.
        let slow = Self.aifc(packets: 2, rate: 22050)
        let sp = try Self.kitLooped(slow, passes: 3)
        var r = MusicStream(track: try MusicTrack(soundFile: slow), loop: true)
        var ro = [Float](repeating: 0, count: 2 * 260)
        ro.withUnsafeMutableBufferPointer { r.mix(into: $0, frames: 260, gain: 1) }
        for k in 0..<260 {
            let i = k / 2, j = i + 1
            let a = Float(sp[2 * i]), b = Float(sp[2 * j])
            let want = k % 2 == 0 ? a / 32768 : (a + (b - a) * 0.5) / 32768
            XCTAssertEqual(ro[2 * k], want, "resampled \(k)")
        }
        // A non-looping stream ends after its last frame and adds nothing more.
        var once = MusicStream(track: try MusicTrack(soundFile: file), loop: false)
        var oo = [Float](repeating: 0, count: 2 * 200)
        oo.withUnsafeMutableBufferPointer { once.mix(into: $0, frames: 200, gain: 1) }
        XCTAssertTrue(once.ended)
        XCTAssertEqual(oo[2 * 127], Float(pcm[254]) / 32768)
        XCTAssertEqual(oo[(2 * 128)...].filter { $0 != 0 }.count, 0)
    }

    func testMusicDecoderMatchesKitIMA4() throws {
        func check(_ file: Data, packets: Int, _ label: String) throws {
            var want = try Self.kitFrames(file, packets: packets)
            if try AIFFAudio(data: file).channels == 1 { want = want.flatMap { [$0, $0] } }   // mono → both sides
            var out = [Float](repeating: 0, count: 2 * 64 * packets)
            var s = MusicStream(track: try MusicTrack(soundFile: file), loop: true)
            out.withUnsafeMutableBufferPointer { s.mix(into: $0, frames: 64 * packets, gain: 1) }
            // Float(Int16)/32768 is exact and invertible: compare as the decoded Int16s, bit for bit.
            let got = out.map { Int16(exactly: $0 * 32768)! }
            XCTAssertEqual(got, want, label)
        }
        try check(Self.aifc(packets: 2), packets: 2, "synthetic")
        try check(Self.aifc(packets: 4, seed: 7, chained: true), packets: 4, "synthetic chained (re-sync carry)")
        try check(Self.aifc(packets: 3, channels: 1, seed: 99), packets: 3, "synthetic mono")
        // Re-sync refused: index equal but the predictor > 0x7F away → the preamble's predictor is loaded.
        let far = Self.aifc(packets: 4, seed: 11, chained: true, chainOffset: 0x100)
        try check(far, packets: 4, "synthetic chained, predictor 0x100 off (header reload)")
        XCTAssertNotEqual(try Self.kitFrames(far), try Self.kitFrames(Self.aifc(packets: 4, seed: 11, chained: true)))
        // A preamble index field > 88 (7 bits: up to 127) clamps to 88.
        try check(Self.aifc(packets: 2, seed: 5, firstHeader: 0x1200 | 120), packets: 2, "header index 120")
        XCTAssertEqual(try Self.kitFrames(Self.aifc(packets: 1, seed: 5, firstHeader: 0x1200 | 120)),
                       try Self.kitFrames(Self.aifc(packets: 1, seed: 5, firstHeader: 0x1200 | 88)))
        // mu03 (Music 3, stereo ima4 44.1 kHz): the first 4 packets only (landmine 11e — never the whole track).
        let mu03 = try AudioTestData.soundFile("mu03")
        let track = try MusicTrack(soundFile: mu03)
        XCTAssertEqual(track.channels, 2)
        XCTAssertEqual(track.packets, 134_892)
        XCTAssertEqual(track.sampleRate, 44100)
        try check(mu03, packets: 4, "mu03")
    }

    func testMusicPauseFreezes() throws {
        let file = Self.aifc(packets: 2)
        let pcm = try Self.kitFrames(file)
        let e = try Self.engine(music: ["ammu": file])
        e.apply(sounds: [], music: [.level(100), .play(FourCC("ammu")!, loop: true)], haltEffectsAt: nil)
        let g = Float(128) / 255
        let first = Self.render(e, frames: 50)
        XCTAssertEqual(first[98], Float(pcm[98]) / 32768 * g)
        e.apply(sounds: [], music: [.pause], haltEffectsAt: nil)
        let paused = Self.render(e, frames: 500)
        XCTAssertEqual(paused.filter { $0 != 0 }.count, 0)                  // nothing out, nothing consumed
        e.apply(sounds: [], music: [.resume], haltEffectsAt: nil)
        let resumed = Self.render(e, frames: 100)
        for k in 0..<100 {
            let i = (50 + k) % 128
            XCTAssertEqual(resumed[2 * k], Float(pcm[2 * i]) / 32768 * g, "resumed frame \(k)")   // same sample on
        }
        // `.play` restarts from 0; `.stop` disposes (resume then does nothing); `none` plays nothing.
        e.apply(sounds: [], music: [.play(FourCC("ammu")!, loop: true)], haltEffectsAt: nil)
        XCTAssertEqual(Self.render(e, frames: 1)[0], Float(pcm[0]) / 32768 * g)
        e.apply(sounds: [], music: [.stop, .resume], haltEffectsAt: nil)
        XCTAssertNil(e.withState { $0.music })
        XCTAssertEqual(Self.render(e, frames: 200).filter { $0 != 0 }.count, 0)
        e.apply(sounds: [], music: [.play(.none, loop: true), .play(FourCC("xxxx")!, loop: true)], haltEffectsAt: nil)
        XCTAssertNil(e.withState { $0.music })
    }

    func testUnityGainNoMasterVolume() throws {
        // The sink has no volume parameter (Q4 RULED, D31): this is its whole signature.
        let apply: (DeimosAudioEngine) -> ([SoundCue], [MusicCue], Int?) -> Void = DeimosAudioEngine.apply
        _ = apply
        // A full-scale effect (volume 100 → gain 0x80) renders exactly as the mixer's own Int16 / 32768 — no gain stage.
        let loud = AudioTestData.synthetic([7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 15, 15, 15, 15], count: 3000)
        var reference = EffectMixer()
        reference.register(FourCC("loud")!, loud)
        var engineMixer = EffectMixer()
        engineMixer.register(FourCC("loud")!, loud)
        let cue = AudioTestData.cue("loud", volume: 100)
        reference.play(cue)
        let e = try Self.engine(effects: engineMixer)
        e.apply(sounds: [cue], music: [], haltEffectsAt: nil)
        let frames = 3 * EffectMixer.blockFrames
        let got = Self.render(e, frames: frames, chunk: 700)
        var want = [Float](repeating: 0, count: 2 * frames)
        want.withUnsafeMutableBufferPointer { reference.render(into: $0, frames: frames) }
        XCTAssertEqual(got, want)
        XCTAssertGreaterThanOrEqual(got.map { abs($0) }.max() ?? 0, Float(32767) / 32768)   // it reaches full scale
        // Music: decoded × amp/255 and nothing else; at m 0x100 (amp 255) that is unity.
        let file = Self.aifc(packets: 1)
        let pcm = try Self.kitFrames(file)
        let m = try Self.engine(music: ["inmu": file])
        m.withState { $0.musicLevel = 0x100 }
        m.apply(sounds: [], music: [.play(FourCC("inmu")!, loop: true)], haltEffectsAt: nil)
        let music = Self.render(m, frames: 64)
        for i in 0..<128 { XCTAssertEqual(music[i], Float(pcm[i]) / 32768, "music sample \(i)") }
        // Effects + music sum, clamped to ±1 (the output's full scale): a full-scale effect under unity music.
        var ref2 = EffectMixer()
        ref2.register(FourCC("loud")!, loud)
        ref2.play(cue)
        var mix2 = EffectMixer()
        mix2.register(FourCC("loud")!, loud)
        let loudMusic = Self.aifc(packets: 2, seed: 3)
        let both = try Self.engine(effects: mix2, music: ["inmu": loudMusic])
        both.withState { $0.musicLevel = 0x100 }
        both.apply(sounds: [cue], music: [.play(FourCC("inmu")!, loop: true)], haltEffectsAt: nil)
        let sum = Self.render(both, frames: 2048, chunk: 500)
        var fx = [Float](repeating: 0, count: 2 * 2048)
        fx.withUnsafeMutableBufferPointer { ref2.render(into: $0, frames: 2048) }
        let lp = try Self.kitLooped(loudMusic, passes: 17)                  // 17 × 128 ≥ 2048 frames
        var clamped = 0
        for i in 0..<(2 * 2048) {
            let raw = fx[i] + Float(lp[i]) / 32768
            if abs(raw) > 1 { clamped += 1 }
            XCTAssertEqual(sum[i], min(max(raw, -1), 1), "sum \(i)")
        }
        XCTAssertGreaterThan(clamped, 0)                                    // the clamp is exercised
    }

    func testPauseClickSurvivesHalt() throws {
        let e = try Self.engine(effects: try AudioTestData.mixer(["cabo", "incl"]))
        let a = AudioTestData.cue("cabo", priority: 70), incl = AudioTestData.cue("incl", priority: 50)
        e.apply(sounds: [a, incl], music: [.pause], haltEffectsAt: 1)
        XCTAssertEqual(e.withState { s in (0..<s.effects.voiceCount).map { s.effects.voice(at: $0).priority } }, [50])
        XCTAssertTrue(e.withState { $0.effects.isPlaying(FourCC("incl")!) })
        XCTAssertFalse(e.withState { $0.effects.isPlaying(FourCC("cabo")!) })
        // A halt at the end of the pass cuts everything; at 0 everything plays after it.
        e.apply(sounds: [a], music: [], haltEffectsAt: 1)
        XCTAssertEqual(e.withState { $0.effects.voiceCount }, 0)
        e.apply(sounds: [a, incl], music: [], haltEffectsAt: 0)
        XCTAssertEqual(e.withState { $0.effects.voiceCount }, 2)
    }

    func testEngineIsAPullSource() throws {
        let assets = try Self.assets.get()
        let e = try DeimosAudioEngine(assets: assets)
        let source: any PCMPullSource = e
        XCTAssertEqual(source.outputRate, 44100)
        // Every mono soun tag is preloaded, the three stereo music tracks are not; 8 audible voices (flli 38).
        XCTAssertEqual(e.withState { $0.effects.audibleVoices }, 8)
        e.apply(sounds: [AudioTestData.cue("incl"), AudioTestData.cue("mu03")], music: [], haltEffectsAt: nil)
        XCTAssertEqual(e.withState { $0.effects.voiceCount }, 1)
        XCTAssertTrue(e.withState { $0.effects.isPlaying(FourCC("incl")!) })
        // `render` fills exactly 2·frames floats and leaves the rest of the buffer alone.
        var buf = [Float](repeating: .nan, count: 2 * 600)
        buf.withUnsafeMutableBufferPointer { source.render(into: $0, frames: 512) }
        XCTAssertEqual(buf[0..<1024].filter(\.isNaN).count, 0)
        XCTAssertEqual(buf[1024...].filter(\.isNaN).count, 176)
        XCTAssertNotEqual(buf[0..<1024].filter { $0 != 0 }.count, 0)        // incl is audible
        // The level music streams from the pak (mu03, every level's `#music_ID`).
        e.apply(sounds: [], music: [.play(FourCC("mu03")!, loop: true)], haltEffectsAt: nil)
        XCTAssertEqual(e.withState { $0.music?.track.packets }, 134_892)
        buf.withUnsafeMutableBufferPointer { source.render(into: $0, frames: 600) }
        XCTAssertEqual(buf.filter(\.isNaN).count, 0)
    }
}
