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

        // Predictor and index carry across the dropped packet headers: a 2-packet ima4 whose second header says
        // predictor 0x7F80 / index 88 decodes on from where packet 1 left off.
        var data = [UInt8](repeating: 0x77, count: 68)
        data[0] = 0; data[1] = 0
        data[34] = 0x7F; data[35] = 0x58
        let two = IMAContinuous(ima4: Data(data), rate: 0xAC44_0000)
        XCTAssertEqual(two.sampleCount, 132)
        XCTAssertEqual(two.bytes.count, 66)
        XCTAssertEqual(Array(two.bytes[32..<64]), [UInt8](repeating: 0x77, count: 32))
    }

    func testVolumeToGain() {
        XCTAssertEqual([100, 90, 80, 75, 70, 50].map { EffectMixer.gain(volume: $0) }, [128, 115, 102, 96, 89, 64])
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
