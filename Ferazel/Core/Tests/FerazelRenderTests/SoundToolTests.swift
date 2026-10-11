import XCTest
import HectorAudio
import FerazelCore
@testable import FerazelRender

/// S2 (docs/plans/2026-10-10-ferazel-phase2.md): the Sound Tool mixer, transcribed from the dump
/// (`ghidra/ferazel/Ferazel_pef.decompiled.c`, "M l. N"; disasm "raw XXXXXXXX"):
/// `ST_Open(8, 1, 22050)` M l. 8282 (`FUN_10090e38`: 8 → audible count `*_DAT_100a1330`, 1 → stereo);
/// load `FUN_10091748` M l. 78397 (raw `100917c8 addi r28,r28,0x17`: the first header sample is skipped);
/// play `FUN_10091208` M l. 78217–78318; stop `FUN_10091504`; count `FUN_100916dc`; the 1024-frame
/// callback `FUN_10091c94` (mix, then every entry's countdown −1); stereo mix `FUN_10091ddc` M l. 78656–78720
/// (raw `10091ddc..10091efc`). Every expected number below is hand arithmetic from those lines.
/// Synthetic sounds give `samples` as the sampled header's bytes − 0x80 (what `FUN_10091748` stores), so
/// element 0 is the sample the Sound Tool drops.
final class SoundToolTests: XCTestCase {

    private static let r22050: UInt32 = 0x5622_0000
    private static let r11025: UInt32 = 0x2B11_0000

    /// Renders `frames` frames and returns them as the mixer's signed 8-bit values (Float = v / 128, exact).
    private func pull(_ tool: SoundTool, _ frames: Int) -> [(l: Int, r: Int)] {
        var buf = [Float](repeating: 99, count: frames * 2)
        buf.withUnsafeMutableBufferPointer { tool.render(into: $0, frames: frames) }
        return (0..<frames).map { (Int(buf[2 * $0] * 128), Int(buf[2 * $0 + 1] * 128)) }
    }

    /// A sound whose post-skip data is `value` for `blocks` × 1024 samples (header has one extra leading sample).
    private func dc(_ id: Int16, _ value: Int8, blocks: Int) -> SoundTool.RawSound {
        SoundTool.RawSound(id: id, rate: Self.r22050, samples: [0] + [Int8](repeating: value, count: blocks * 1024))
    }

    // 9th entry silent until one ends (M l. 78687 `if (iVar4 < *piVar3)`, *piVar3 = 8; raw 10091e18 cmpw):
    // entries past the 8th still advance (M l. 78698–78699 run for every entry < count) and tick their
    // countdown (FUN_10091c94), but are not summed and do not update their previous-pointer (+0x24).
    func testEightAudible() throws {
        // L1: samples 5 for the first block, 7 for the second, 3 blocks long.
        let l1 = SoundTool.RawSound(id: 1, rate: Self.r22050,
                                    samples: [0] + [Int8](repeating: 5, count: 1024) + [Int8](repeating: 7, count: 2048))
        var raws = [l1, dc(2, 10, blocks: 1)]                   // S: one block → countdown FixDiv(1<<16, 0x10000)>>16 = 1
        for i in 0..<7 { raws.append(dc(Int16(10 + i), 10, blocks: 3)) }
        let tool = SoundTool(raw: raws)
        tool.play(snd: 1, priority: 1, left: 0x80, right: 0x80)   // prio 1: everything prio 2 goes in front
        tool.play(snd: 2, priority: 2, left: 0x80, right: 0x80)
        for i in 0..<7 { tool.play(snd: Int16(10 + i), priority: 2, left: 0x80, right: 0x80) }
        // Equal prio + equal sum → each newer one in front (M l. 78254–78263); L1 (prio 1) is the 9th entry.
        XCTAssertEqual(tool.snapshot().map(\.snd), [16, 15, 14, 13, 12, 11, 10, 2, 1])

        // Block 1: 8 audible × 10 = 80 both sides; L1's 5 is not heard (would be 85).
        let b1 = pull(tool, 1024)
        XCTAssertEqual(Set(b1.map(\.l)), [80]); XCTAssertEqual(Set(b1.map(\.r)), [80])
        // After block 1 S's countdown 1 → 0: removed; L1 moves up to the 8th entry.
        XCTAssertFalse(tool.isPlaying(snd: 2))
        XCTAssertEqual(tool.snapshot().map(\.snd), [16, 15, 14, 13, 12, 11, 10, 1])
        // Block 2: 7 × 10 + L1 at source index 1024 (it advanced while silent: acc = 1024 × 0x100) = 77.
        let b2 = pull(tool, 1024)
        XCTAssertEqual(Set(b2.map(\.l)), [77]); XCTAssertEqual(Set(b2.map(\.r)), [77])
    }

    // Insert rule, FUN_10091208 M l. 78243–78307 (raw 10091248..10091348): prio 0 → 1; L/R > 0x80 → 0x80;
    // skip entry while new.prio < e.prio (cmplw) OR new.L+R < e.L+R (cmpw); insert there; count ≥ 16 → 15 so
    // the 16th drops; reached index 16 → dropped, returns 0. Ids from the counter starting 1, += 2 (FUN_10091fe4).
    func testInsertRule() throws {
        let tool = SoundTool(raw: (1...20).map { dc(Int16($0), 0, blocks: 4) })
        // Equal priority: louder goes first, quieter after, an equal sum goes in front of its equal.
        XCTAssertEqual(tool.play(snd: 1, priority: 2, left: 0x40, right: 0x40), 1)      // sum 0x80
        XCTAssertEqual(tool.play(snd: 2, priority: 2, left: 0x90, right: 0xFF), 3)      // → 0x80/0x80, sum 0x100: front
        XCTAssertEqual(tool.play(snd: 3, priority: 2, left: 0x20, right: 0x20), 5)      // sum 0x40: after both
        XCTAssertEqual(tool.play(snd: 4, priority: 2, left: 0x40, right: 0x40), 7)      // ties snd 1 → before it
        var s = tool.snapshot()
        XCTAssertEqual(s.map(\.snd), [2, 4, 1, 3])
        XCTAssertEqual(s[0].left, 0x80); XCTAssertEqual(s[0].right, 0x80)
        // Lower priority, however loud, is appended (1 < 2 at every entry).
        tool.play(snd: 5, priority: 1, left: 0x80, right: 0x80)
        // Higher priority but quieter is still skipped (the OR): prio 9, sum 0x10 < every sum → appended.
        tool.play(snd: 6, priority: 9, left: 0x08, right: 0x08)
        // Priority 0 → 1: skips the prio-2 entries, ties snd 5 (prio 1, sum 0x100) → in front of it.
        tool.play(snd: 7, priority: 0, left: 0x80, right: 0x80)
        s = tool.snapshot()
        XCTAssertEqual(s.map(\.snd), [2, 4, 1, 3, 7, 5, 6])
        XCTAssertEqual(s[4].priority, 1)
        // Fill to 16 with prio-1 sum-0 sounds: the first is appended, each later one ties it and goes in front.
        for id in 8...16 { tool.play(snd: Int16(id), priority: 1, left: 0, right: 0) }
        s = tool.snapshot()
        XCTAssertEqual(s.map(\.snd), [2, 4, 1, 3, 7, 5, 6, 16, 15, 14, 13, 12, 11, 10, 9, 8])
        // The 17th ties snd 16 at index 7: count 16 → clamped 15, BlockMoveData, inserted, count 16 — the 16th
        // (snd 8) drops.
        XCTAssertEqual(tool.play(snd: 17, priority: 1, left: 0, right: 0), 33)          // 17th id: 1 + 16·2
        s = tool.snapshot()
        XCTAssertEqual(s.map(\.snd), [2, 4, 1, 3, 7, 5, 6, 17, 16, 15, 14, 13, 12, 11, 10, 9])
        XCTAssertFalse(tool.isPlaying(snd: 8))

        // Full and unbeaten → dropped, returns 0, nothing evicted (raw 1009131c..10091334).
        let full = SoundTool(raw: (1...20).map { dc(Int16($0), 0, blocks: 4) })
        for id in 1...16 { full.play(snd: Int16(id), priority: 2, left: 0x80, right: 0x80) }
        XCTAssertEqual(full.play(snd: 17, priority: 1, left: 0x80, right: 0x80), 0)     // 1 < 2 at all 16
        XCTAssertEqual(full.snapshot().count, 16)
        XCTAssertFalse(full.isPlaying(snd: 17))
        XCTAssertTrue(full.isPlaying(snd: 1))
    }

    // Mix, FUN_10091ddc M l. 78691–78713 (raw 10091e58..10091eec): v = (s × vol) >> 7 per side (mullw, srawi 7),
    // summed, clipped to ±0x7f, written as 8-bit offset (+0x80), left in the high byte (+0x2c ← req +0x16, the
    // first .CalcStereoVolume output = the scrollX+200 ear, M l. 40688–40720).
    func testUnityAndClip() throws {
        // Unity: 0x80 passes samples unchanged (s × 0x80 >> 7 = s); −128 alone clips to −127.
        // Right at 0x40: (s × 0x40) >> 7 floors: −3 → −192 >> 7 = −2 (srawi; truncation would give −1).
        let one = SoundTool(raw: [SoundTool.RawSound(id: 1, rate: Self.r22050,
                                                    samples: [99, 10, -20, 127, -128, -3, 0])])
        one.play(snd: 1, priority: 1, left: 0x80, right: 0x40)
        let o = pull(one, 6)
        XCTAssertEqual(o.map(\.l), [10, -20, 127, -127, -3, 0])   // first header sample (99) skipped
        XCTAssertEqual(o.map(\.r), [5, -10, 63, -64, -2, 0])      // 10·64>>7=5, −20·64>>7=−10, 127·64>>7=63, −128·64>>7=−64

        // Two full-scale voices: 100 + 100 = 200 → 127; −100 + −100 → −127.
        let two = SoundTool(raw: [
            SoundTool.RawSound(id: 1, rate: Self.r22050, samples: [0, 100, -100, 60]),
            SoundTool.RawSound(id: 2, rate: Self.r22050, samples: [0, 100, -100, 60]),
        ])
        two.play(snd: 1, priority: 1, left: 0x80, right: 0x80)
        two.play(snd: 2, priority: 1, left: 0x80, right: 0x80)
        let t = pull(two, 4)
        XCTAssertEqual(t.map(\.l), [127, -127, 120, 0])
        XCTAssertEqual(t.map(\.r), [127, -127, 120, 0])

        // Real data through SoundBank (no re-decode): snd 128 'soft impact' header bytes 82 82 81 82 81 82
        // (sprites-backgrounds-sounds §6.1 xxd) → −0x80 = 2 2 1 2 1 2; the Sound Tool drops the first → 2 1 2 1 2.
        // 8896 samples − 1 = 8895 → ceil(8895/1024) = 9 blocks → countdown FixDiv(9<<16, 0x10000)>>16 = 9.
        let bank = try SoundBank(sounds: try FerazelData.open(try FerazelData.dataDirectory()).sounds)
        let real = SoundTool(bank: bank)
        XCTAssertEqual(real.play(snd: 128, priority: 1, left: 0x80, right: 0x80), 1)
        XCTAssertEqual(real.snapshot().first?.countdown, 9)
        let r = pull(real, 5)
        XCTAssertEqual(r.map(\.l), [2, 1, 2, 1, 2]); XCTAssertEqual(r.map(\.r), [2, 1, 2, 1, 2])
    }

    // Step, FUN_10091208 M l. 78272–78278 (raw 10091378..10091424): base = FixDiv(sndRate>>8, 22050<<16>>8),
    // step = FixMul(base, rate); countdown = FixDiv(blocks<<16, step)>>16 (0 → 1). Per frame (M l. 78698–78699):
    // acc += step>>8; cur = data + (acc>>8). The 2-tap average when cur == prev (M l. 78689–78691, raw
    // 10091e2c..10091e44: (s[0] + s[1]) srawi 1).
    func testPitchStep() throws {
        // A fresh tool per case: a stop takes effect from the next 1024-frame block (FUN_10091c94 mixes whole
        // blocks), so a reused tool would replay the already-mixed block.
        func tool() -> SoundTool {
            SoundTool(raw: [
                SoundTool.RawSound(id: 1, rate: Self.r22050, samples: [0, 10, -21, 40, -7]),
                SoundTool.RawSound(id: 2, rate: Self.r11025, samples: [0, 10, -21, 40, -7]),
            ])
        }
        let full = tool()
        full.play(snd: 1, priority: 1, left: 0x80, right: 0x80)
        var s = full.snapshot()[0]
        XCTAssertEqual(s.baseStep, 0x10000); XCTAssertEqual(s.step, 0x10000)        // 0x562200/0x562200 = 1.0
        XCTAssertEqual(s.countdown, 1)                                               // 4 samples → 1 block
        XCTAssertEqual(pull(full, 5).map(\.l), [10, -21, 40, -7, 0])               // one sample per frame, then pad

        let half = tool()
        half.play(snd: 2, priority: 1, left: 0x80, right: 0x80)
        s = half.snapshot()[0]
        XCTAssertEqual(s.baseStep, 0x8000); XCTAssertEqual(s.step, 0x8000)          // 0x2B1100/0x562200 = 0.5
        XCTAssertEqual(s.countdown, 2)                                               // FixDiv(1<<16, 0x8000)>>16 = 2
        // s0; avg(s0,s1) = −11>>1 = −6; s1; 19>>1 = 9; s2; 33>>1 = 16; s3; avg(−7, pad 0) = −7>>1 = −4 (floor).
        XCTAssertEqual(pull(half, 8).map(\.l), [10, -6, -21, 9, 40, 16, -7, -4])

        // The request rate multiplies: 22050 Hz at 0x8000 → step FixMul(0x10000, 0x8000) = 0x8000.
        let slow = tool()
        slow.play(snd: 1, priority: 1, left: 0x80, right: 0x80, rate: 0x8000)
        s = slow.snapshot()[0]
        XCTAssertEqual(s.baseStep, 0x10000); XCTAssertEqual(s.step, 0x8000); XCTAssertEqual(s.countdown, 2)
        XCTAssertEqual(pull(slow, 4).map(\.l), [10, -6, -21, 9])
    }

    // Stop FUN_10091504 (every entry whose sound matches, list compacted), count FUN_100916dc; the game's
    // only-if-idle idiom is `if (FUN_100916dc(snd) == 0) play` (e.g. M l. 2787–2789). A sound ends on its
    // countdown at a 1024-frame boundary (FUN_10091c94).
    func testStopAndOnlyIfIdle() throws {
        let tool = SoundTool(raw: [dc(1, 10, blocks: 1), dc(2, 20, blocks: 3)])
        XCTAssertFalse(tool.isPlaying(snd: 1))
        tool.play(snd: 1, priority: 1, left: 0x80, right: 0x80)
        XCTAssertTrue(tool.isPlaying(snd: 1))
        if !tool.isPlaying(snd: 1) { tool.play(snd: 1, priority: 1, left: 0x80, right: 0x80) }   // gated: not replayed
        XCTAssertEqual(tool.snapshot().map(\.snd), [1])

        // Two plays of the same sound + another; stop removes both matches and compacts.
        tool.play(snd: 1, priority: 1, left: 0x80, right: 0x80)
        tool.play(snd: 2, priority: 1, left: 0x40, right: 0x40)
        XCTAssertEqual(tool.snapshot().map(\.snd), [1, 1, 2])
        tool.stop(snd: 1)
        XCTAssertFalse(tool.isPlaying(snd: 1))
        XCTAssertEqual(tool.snapshot().map(\.snd), [2])
        tool.stop(snd: 1)                                                    // nothing matches: no-op
        XCTAssertEqual(tool.snapshot().map(\.snd), [2])
        XCTAssertEqual(Set(pull(tool, 4).map(\.l)), [10])                     // 20 × 0x40 >> 7 = 10

        // Natural end: snd 1 (one block, countdown 1) is playing during one block and gone after it.
        tool.play(snd: 1, priority: 1, left: 0x80, right: 0x80)              // takes effect at the next block
        _ = pull(tool, 1020)                                                 // finish the current block (4 + 1020)
        XCTAssertTrue(tool.isPlaying(snd: 1))
        let b = pull(tool, 1024)
        XCTAssertEqual(Set(b.map(\.l)), [20])                                 // 10 + 10
        XCTAssertFalse(tool.isPlaying(snd: 1))
        if !tool.isPlaying(snd: 1) { tool.play(snd: 1, priority: 1, left: 0x80, right: 0x80) }   // idle → plays
        XCTAssertTrue(tool.isPlaying(snd: 1))
    }
}
