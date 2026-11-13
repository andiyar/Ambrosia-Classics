import XCTest
@testable import DeimosAudio
import DeimosCore

/// Phase 2 A1 — the continuous-IMA conversion (`FUN_100d1d90`) and the game's 16-voice / 8-audible effects mixer
/// (`FUN_100d18d0`, `FUN_100d21a0`, `FUN_100d32d0`, `FUN_10047bf0`); bank sound-music §2.2–§3.2.
/// Every mixing loop is bounded (`maxBlocks` / `maxFrames`, plan G11).
final class EffectMixerTests: XCTestCase {

    /// The SSND body after its offset field (= `FUN_100d2400`'s `bytes`), read straight from the file.
    private func ssndBody(_ file: Data) throws -> [UInt8] {
        let b = [UInt8](file)
        func u32(_ o: Int) -> Int { Int(b[o]) << 24 | Int(b[o + 1]) << 16 | Int(b[o + 2]) << 8 | Int(b[o + 3]) }
        var o = 12
        while o + 8 <= b.count {
            let id = String(decoding: b[o..<o + 4], as: UTF8.self), size = u32(o + 4)
            if id == "SSND" {
                let start = o + 16 + u32(o + 8)
                return Array(b[start..<(o + 8 + size)])
            }
            o += 8 + size + (size & 1)
        }
        XCTFail("no SSND chunk"); return []
    }

    func testContinuousConversion() throws {
        let file = try AudioTestData.soundFile("icbu")
        let raw = try ssndBody(file)
        let packets = 239
        XCTAssertEqual(raw.count, packets * 34)
        let s = try AudioTestData.sound("icbu")
        XCTAssertEqual(s.sampleCount, 15_774)
        XCTAssertEqual(s.sampleCount, UInt32(66 * packets))
        XCTAssertEqual(s.rate, 0xAC44_0000)
        XCTAssertEqual(s.bytes.count, raw.count - raw.count / 34)          // 33·P: the block after its header
        for p in 0..<packets {
            for j in 0..<32 {                                               // header word (2 bytes) dropped
                let b = raw[p * 34 + 2 + j]
                XCTAssertEqual(s.bytes[p * 32 + j], (b << 4) | (b >> 4), "packet \(p) byte \(j)")   // nibbles swapped
            }
        }
        XCTAssertEqual(s.bytes[(packets * 32)...].filter { $0 != 0 }.count, 0)   // the 2·P-sample zero tail
        // Decode order = Apple's (low nibble of each original byte first).
        XCTAssertEqual(s.nibble(at: 0), raw[2] & 0x0F)
        XCTAssertEqual(s.nibble(at: 1), raw[2] >> 4)

        // The load gates on the same file: COMM sampleSize must be 16 for the ima4 path (`100d1db4`), and a rate
        // of 0 is refused (never shipped).
        var comm = 12
        while String(decoding: file[comm..<comm + 4], as: UTF8.self) != "COMM" {
            let size = Int(file[comm + 4]) << 24 | Int(file[comm + 5]) << 16 | Int(file[comm + 6]) << 8 | Int(file[comm + 7])
            comm += 8 + size + (size & 1)
        }
        XCTAssertEqual(Int(file[comm + 14]) << 8 | Int(file[comm + 15]), 16)
        var size4 = file
        size4[comm + 15] = 4
        XCTAssertThrowsError(try IMAContinuous(soundFile: size4)) {
            XCTAssertEqual($0 as? IMAContinuousError, .imaSampleSize(4))
        }
        var rate0 = file
        for k in 16..<26 { rate0[comm + k] = 0 }
        XCTAssertThrowsError(try IMAContinuous(soundFile: rate0)) {
            XCTAssertEqual($0 as? IMAContinuousError, .invalidRate(0))
        }
    }

    func testIMADecodeClamps() throws {
        func voice(_ sound: IMAContinuous) -> Voice {
            var v = Voice.empty
            v.sound = 0; v.step = 0x10000; v.ratio = 0x10000; v.total = sound.sampleCount
            v.gainLeft = 0x80; v.gainRight = 0x80; v.priority = 50
            return v
        }
        var out = [Int16](repeating: 0, count: 2 * EffectMixer.blockFrames)

        // Nibble 7 from index 0: ⌊(2·7+1)·step/8⌋ per sample (not the reference decoder's 11 at step 7), index +8.
        let up = AudioTestData.synthetic([7], count: 40)
        var v = voice(up)
        let done = out.withUnsafeMutableBufferPointer { v.render(up, into: $0.baseAddress!, frames: EffectMixer.blockFrames) }
        XCTAssertTrue(done)
        XCTAssertEqual(Array(out[0..<8]), [13, 13, 43, 43, 106, 106, 242, 242])   // L = R = predictor at gain 0x80
        XCTAssertEqual(v.stepIndex, 88)                                     // index clamp 88
        XCTAssertEqual(v.predictor, 32767)                                  // predictor clamp +32767
        XCTAssertEqual(out[2 * 39], 32767)

        // Nibble 0xF: predictor clamps at −32768 (`cmpwi r19,-0x8000`), not −32767.
        out = [Int16](repeating: 0, count: out.count)
        let down = AudioTestData.synthetic([0xF], count: 40)
        v = voice(down)
        _ = out.withUnsafeMutableBufferPointer { v.render(down, into: $0.baseAddress!, frames: EffectMixer.blockFrames) }
        XCTAssertEqual(v.predictor, -32768)
        XCTAssertEqual(v.stepIndex, 88)
        XCTAssertEqual(out[2 * 39], -32768)

        // Nibble 0 from index 0: index clamps at 0, the difference ⌊7/8⌋ = 0 — silence.
        out = [Int16](repeating: 0, count: out.count)
        let flat = AudioTestData.synthetic([0], count: 40)
        v = voice(flat)
        _ = out.withUnsafeMutableBufferPointer { v.render(flat, into: $0.baseAddress!, frames: EffectMixer.blockFrames) }
        XCTAssertEqual(v.stepIndex, 0)
        XCTAssertEqual(v.predictor, 0)
        XCTAssertEqual(out.filter { $0 != 0 }.count, 0)

        // Predictor and index carry across the dropped packet headers: packet 1 is all nibble 0 (predictor 0,
        // index 0); packet 2's header says predictor 0x7F80 / index 88 but is never read — its nibbles 1 add
        // ⌊3·7/8⌋ = 2 each from predictor 0 at index 0.
        var data = [UInt8](repeating: 0x00, count: 68)
        for k in 36..<68 { data[k] = 0x11 }
        data[34] = 0x7F; data[35] = 0x80 | 0x58
        let two = IMAContinuous(ima4: Data(data), rate: 0xAC44_0000)
        XCTAssertEqual(two.sampleCount, 132)
        XCTAssertEqual(two.bytes.count, 66)
        out = [Int16](repeating: 0, count: out.count)
        v = voice(two)
        XCTAssertTrue(out.withUnsafeMutableBufferPointer { v.render(two, into: $0.baseAddress!, frames: EffectMixer.blockFrames) })
        XCTAssertEqual(out[2 * 63], 0)                                      // last sample of packet 1
        XCTAssertEqual(Array(out[(2 * 64)..<(2 * 67)].enumerated().filter { $0.offset % 2 == 0 }.map(\.element)),
                       [2, 4, 6])                                           // samples 65–67: carried, not re-synced
        XCTAssertEqual(out[2 * 127], 128)                                   // 64 × 2 at the end of packet 2
        XCTAssertEqual(out[2 * 131], 128)                                   // the 2·P zero-nibble tail holds it
        XCTAssertEqual(v.predictor, 128)
        XCTAssertEqual(v.stepIndex, 0)

        // frames 0 writes nothing (the original would run unbounded) and leaves the voice as it was.
        let fresh = voice(up)
        v = fresh
        var guardBuf: [Int16] = [7, 7]
        XCTAssertFalse(guardBuf.withUnsafeMutableBufferPointer { v.render(up, into: $0.baseAddress!, frames: 0) })
        XCTAssertEqual(guardBuf, [7, 7])
        XCTAssertEqual(v, fresh)
    }

    func testVolumeToGain() {
        XCTAssertEqual([100, 90, 80, 75, 70, 50].map { EffectMixer.gain(volume: $0) }, [128, 115, 102, 96, 89, 64])

        // The gain is applied to the decoded sample BEFORE interpolation (`100d33ec mullw; srawi 7`, then the
        // `r24` steps from `last`): predictors 2, 4, 6, 8 at gain 89 → 1, 2, 4, 5; pitch 2 → two frames each.
        var m = EffectMixer()
        m.register(FourCC("ramp")!, AudioTestData.synthetic([1], count: 4))
        m.play(AudioTestData.cue("ramp", volume: 70, pitch: 2))
        m.mixBlock()
        XCTAssertEqual(stride(from: 0, to: 16, by: 2).map { m.block[$0] }, [0, 1, 1, 2, 3, 4, 4, 5])
        XCTAssertEqual(m.block[16], 0)

        // Above 100 % the request's gain (150 → 192) is clamped to 0x80 by the mixer (`100d1930`, `100d1944`).
        XCTAssertEqual(EffectMixer.gain(volume: 150), 192)
        m.play(AudioTestData.cue("ramp", volume: 150))
        XCTAssertEqual(m.voice(at: 0).gainLeft, 0x80)
        XCTAssertEqual(m.voice(at: 0).gainRight, 0x80)
    }

    func testInsertionRanking() throws {
        var m = try AudioTestData.mixer(["cabo", "exsl", "icre", "icbu"])
        let cabo = m.play(AudioTestData.cue("cabo", priority: 70))
        let exsl = m.play(AudioTestData.cue("exsl", priority: 50))
        let icre = m.play(AudioTestData.cue("icre", priority: 50))
        XCTAssertEqual([cabo, exsl, icre], [1, 3, 5])                      // the odd counter from 1, +2
        XCTAssertEqual(m.voiceIDs, [1, 5, 3])                               // [cabo, icre, exsl]
        let b1 = m.play(AudioTestData.cue("icbu", priority: 45, volume: 90, pitch: 0.9))
        let b2 = m.play(AudioTestData.cue("icbu", priority: 45, volume: 90, pitch: 1.1))
        XCTAssertEqual(m.voiceIDs, [1, 5, 3, b2!, b1!])                     // [cabo, icre, exsl, icbu₂, icbu₁]
        XCTAssertEqual(m.voice(at: 3).gainLeft, 115)
        XCTAssertEqual(m.voice(at: 3).gainRight, 115)
        XCTAssertEqual(m.voice(at: 3).priority, 45)
        XCTAssertEqual(m.voice(at: 0).gainLeft + m.voice(at: 0).gainRight, 256)
        // Pitch 1.1 → (int)(65536.0f·1.1f) = 72089; step = FixMul(FixDiv(44100, 44100), 72089).
        XCTAssertEqual(m.voice(at: 3).ratio, 0x10000)
        XCTAssertEqual(m.voice(at: 3).step, 72089)

        // Priority 150 clamps to 100 (`10047c54`) and leads; priority 0 becomes 1 (`100d191c`) and trails.
        let top = m.play(AudioTestData.cue("exsl", priority: 150))
        XCTAssertEqual(m.voiceIDs.first, top)
        XCTAssertEqual(m.voice(at: 0).priority, 100)
        let low = m.play(AudioTestData.cue("exsl", priority: 0))
        XCTAssertEqual(m.voiceIDs.last, low)
        XCTAssertEqual(m.voice(at: m.voiceCount - 1).priority, 1)
        // The priority is the low byte: 0x132 → 0x32 = 50 — newest-first among equals: in front of icre.
        let byte = m.play(AudioTestData.cue("exsl", priority: 0x132))
        XCTAssertEqual(m.voice(at: m.voiceIDs.firstIndex(of: byte!)!).priority, 50)
        XCTAssertEqual(m.voiceIDs, [top!, 1, byte!, 5, 3, b2!, b1!, low!])
    }

    func testSixteenVoicesEvictOrRefuse() {
        var m = EffectMixer()
        let long = AudioTestData.synthetic([0], count: 50_000)
        for t in ["lng1", "low1", "low2", "nevr"] { m.register(FourCC(t)!, long) }
        for _ in 0..<16 { m.play(AudioTestData.cue("lng1", priority: 50)) }
        XCTAssertEqual(m.voiceCount, 16)
        XCTAssertEqual(m.voiceIDs, Array(stride(from: 31, through: 1, by: -2)).map(UInt32.init))

        // An equal-ranked 17th goes in front and the 16th (lowest-ranked, oldest) voice is overwritten.
        XCTAssertEqual(m.play(AudioTestData.cue("lng1", priority: 50)), 33)
        XCTAssertEqual(m.voiceCount, 16)
        XCTAssertEqual(m.voiceIDs, Array(stride(from: 33, through: 3, by: -2)).map(UInt32.init))

        // Below all 16 → refused (0), nothing evicted. Both keys count: priority 60 with gain sum 128 < 256 still loses.
        let before = m.voiceIDs
        XCTAssertEqual(m.play(AudioTestData.cue("low1", priority: 10)), 0)
        XCTAssertEqual(m.play(AudioTestData.cue("low2", priority: 60, volume: 50)), 0)
        XCTAssertEqual(m.voiceIDs, before)
        // A refused start stores 0 as the record's last voice: is-playing then counts EVERY voice (bank §2.4 bug).
        XCTAssertTrue(m.isPlaying(FourCC("low1")!))
        XCTAssertFalse(m.isPlaying(FourCC("nevr")!))                         // never played: −1 matches nothing
        m.stopAll()
        XCTAssertEqual(m.voiceCount, 0)
        XCTAssertFalse(m.isPlaying(FourCC("low1")!))
    }

    func testOnlyTopEightAudible() {
        let loud = AudioTestData.synthetic([1], count: 4000)                 // predictor 2, 4, 6, … — never silent
        let quiet = AudioTestData.synthetic([0], count: 5000)
        let short = AudioTestData.synthetic([0], count: 100)
        func mixer() -> EffectMixer {
            var m = EffectMixer(numChannels: 8)
            m.register(FourCC("loud")!, loud)
            m.register(FourCC("quie")!, quiet)
            m.register(FourCC("shrt")!, short)
            return m
        }
        var solo = mixer()
        solo.play(AudioTestData.cue("loud", priority: 10))
        solo.mixBlock()
        solo.mixBlock()
        let soloBlock2 = solo.block

        var m = mixer()
        m.play(AudioTestData.cue("loud", priority: 10))
        for _ in 0..<7 { m.play(AudioTestData.cue("quie", priority: 50)) }
        m.play(AudioTestData.cue("shrt", priority: 50))
        XCTAssertEqual(m.voiceCount, 9)
        XCTAssertEqual(m.voice(at: 8).id, 1)                                 // loud is 9th: not audible
        m.mixBlock()
        XCTAssertEqual(m.block.filter { $0 != 0 }.count, 0)                  // it contributes 0 …
        XCTAssertEqual(m.voiceCount, 8)                                      // … the short voice ended and was removed
        XCTAssertEqual(m.voice(at: 7).id, 1)                                 // loud moved up into the top 8
        XCTAssertEqual(m.voice(at: 7).position, 1024)                        // it kept advancing silently
        m.mixBlock()
        XCTAssertEqual(m.block, soloBlock2)                                  // heard from mid-sample, as if never muted
        XCTAssertNotEqual(m.block[0], 0)
    }

    func testPitchIsSpeedInverse() {
        func frames(pitch: Float) -> Int {
            var m = EffectMixer()
            m.register(FourCC("ramp")!, AudioTestData.synthetic([1], count: 1000))
            m.play(AudioTestData.cue("ramp", pitch: pitch))
            let out = m.drain(maxBlocks: 8)
            return stride(from: 0, to: out.count, by: 2).filter { out[$0] != 0 }.count
        }
        XCTAssertEqual(frames(pitch: 1.0), 1000)
        XCTAssertEqual(frames(pitch: 2.0), 2000)                             // p > 1: longer (and lower)
        XCTAssertEqual(frames(pitch: 0.5), 500)                              // p < 1: shorter (and higher)

        // The rate ratio is FixDiv(44100, soundRate) (`100d1a74`): a 22050 Hz sound steps 2.0 at pitch 1.
        var half = EffectMixer()
        half.register(FourCC("half")!, IMAContinuous(nibbleBytes: AudioTestData.synthetic([1], count: 1000).bytes,
                                                     sampleCount: 1000, rate: 0x5622_0000))
        half.play(AudioTestData.cue("half"))
        XCTAssertEqual(half.voice(at: 0).ratio, 0x20000)
        XCTAssertEqual(half.voice(at: 0).step, 0x20000)
        let halfOut = half.drain(maxBlocks: 8)
        XCTAssertEqual(stride(from: 0, to: halfOut.count, by: 2).filter { halfOut[$0] != 0 }.count, 2000)

        // A block that fills on the last output of a sample leaves `last` un-updated (`100d3498 beq 0x100d34f0`):
        // pitch 2, predictor 2k — frame 1024 is sample 512's second output; block 2 starts at sample 513 and
        // interpolates from sample 511's 1022 → 1022 + (128·4 >> 8) = 1024 (not 1025 from 1024).
        var brk = EffectMixer()
        brk.register(FourCC("ramp")!, AudioTestData.synthetic([1], count: 600))
        brk.play(AudioTestData.cue("ramp", pitch: 2))
        brk.mixBlock()
        XCTAssertEqual(brk.block[2 * 1023], 1024)                            // sample 512 = 1024, its 2nd output
        brk.mixBlock()
        XCTAssertEqual(Array(stride(from: 0, to: 4, by: 2).map { brk.block[$0] }), [1024, 1026])

        // The accumulator restarts at 0 every block (`100d32ec li r0,0`): pitch 0.75 (step 0xC00) writes samples
        // k with k mod 4 ≠ 1, so block 1 ends at sample 1366; block 2 counts from 1367 again — 1367 is skipped and
        // its first frame is sample 1368 = 2736 (a carried phase would write 1367 = 2734).
        var phase = EffectMixer()
        phase.register(FourCC("ramp")!, AudioTestData.synthetic([1], count: 2000))
        phase.play(AudioTestData.cue("ramp", pitch: 0.75))
        XCTAssertEqual(phase.voice(at: 0).step, 0xC000)
        phase.mixBlock()
        XCTAssertEqual(Array(stride(from: 0, to: 6, by: 2).map { phase.block[$0] }), [4, 6, 8])   // samples 2, 3, 4
        XCTAssertEqual(phase.block[2 * 1023], 2732)                          // sample 1366
        phase.mixBlock()
        XCTAssertEqual(phase.block[0], 2736)
    }

    func testAllowMultipleFalseBlocksRestart() {
        var m = EffectMixer()
        m.register(FourCC("clik")!, AudioTestData.synthetic([0], count: 100))
        m.register(FourCC("othr")!, AudioTestData.synthetic([0], count: 100))
        let clik = FourCC("clik")!
        XCTAssertFalse(m.isPlaying(clik))
        let first = m.play(AudioTestData.cue("clik", allowMultiple: false))
        XCTAssertNotNil(first)
        XCTAssertTrue(m.isPlaying(clik))
        XCTAssertNil(m.play(AudioTestData.cue("clik", allowMultiple: false)))   // no restart while it lives
        XCTAssertEqual(m.voiceCount, 1)
        let second = m.play(AudioTestData.cue("clik", allowMultiple: true))     // allowMultiple: overlaps freely
        XCTAssertEqual(m.voiceCount, 2)
        XCTAssertNil(m.play(AudioTestData.cue("clik", allowMultiple: false)))   // the LAST instance (second) lives
        XCTAssertNotNil(m.play(AudioTestData.cue("othr", allowMultiple: false)))  // per id
        XCTAssertNil(m.play(AudioTestData.cue("none", allowMultiple: true)))      // `none` never plays
        _ = m.drain(maxBlocks: 4)
        XCTAssertFalse(m.isPlaying(clik))
        let third = m.play(AudioTestData.cue("clik", allowMultiple: false))
        XCTAssertNotNil(third)
        XCTAssertNotEqual(third, second)
        XCTAssertNotEqual(third, first)
    }
}
