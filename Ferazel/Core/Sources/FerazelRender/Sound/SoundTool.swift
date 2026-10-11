import Foundation
import HectorAudio

/// The original's "Sound Tool" software mixer, transcribed from the Ferazel 1.0 PEF
/// (`ghidra/ferazel/Ferazel_pef.decompiled.c` = "M l. N", `Ferazel_pef.disasm.txt` = "raw XXXXXXXX";
/// bank sprites-backgrounds-sounds §6.2, plan 2026-10-10-ferazel-phase2 S2):
///
/// - `ST_Open(8, 1, 22050)` (M l. 8282 → `FUN_10090e38` M l. 78031): 8 audible voices (`*_DAT_100a1330`,
///   capped at 16), stereo, output rate 0x56220000 (22050.0, `PTR_DAT_100a133c`). The play list holds 16
///   entries of 0x34 bytes (`_DAT_100a1314`); only the first 8 are summed.
/// - Load `FUN_10091748` (M l. 78397; raw `10091748..1009188c`): `'asnd'`, block count ceil(n/1024) (≥ 1), the
///   header's 16.16 rate, then the samples − 0x80 into a zero-filled buffer of blocks·1024 + 0x400 bytes. n is
///   the handle size − (header + **0x17**) and the copy starts at header + 0x17 (raw `100917c8 addi r28,r28,0x17`),
///   one past the sampled-sound header's 0x16-byte end: **the first sample is dropped** (every shipped `snd `
///   ends exactly at its data, so n = header length − 1).
/// - Play `FUN_10091208` (M l. 78217–78318; raw `10091208..100914f0`), the insert rule and the step.
/// - Stop `FUN_10091504` (every entry whose sound or id matches; list compacted), count `FUN_100916dc`.
/// - The 1024-frame double-buffer callback `FUN_10091c94` (M l. 78597): mix one block (`FUN_10091ddc`,
///   M l. 78656–78720; raw `10091ddc..10091efc`), then every entry's countdown −1, removing those that reach 0
///   (`FUN_10091b44`). A sound therefore lasts a whole number of blocks and a play/stop is heard from the next
///   block.
///
/// Not modelled (no caller in this API): the per-request id/ref (+0x04, always 0 from the game's wrappers), the
/// completion proc (+0x0c/+0x10 → entry +0x1c/+0x28, `FUN_1009f80c`; `.STPlayLoopedSound`'s re-play), the mono
/// path `FUN_10091f00` and its louder-side copy (stereo is on), the system output volume `FUN_10091124`.
///
/// Output: `render(into:frames:)` hands out the 8-bit offset stereo stream as Float32 `(byte − 0x80) / 128`.
/// Threading: every entry point takes one `NSLock` for a few microseconds; `render` never allocates (the sound
/// data, the 16-entry list and the 1024-frame block are allocated once in `init`).
public final class SoundTool: PCMPullSource, @unchecked Sendable {
    /// Play-list length (the 16 × 0x34 array; insert loop `cmpwi r4,0x10`, raw 1009130c).
    public static let listLength = 16
    /// Audible entries: `ST_Open`'s first argument (M l. 8282).
    public static let audibleVoices = 8
    /// The output rate as the Sound Tool keeps it (16.16).
    public static let outputRateFixed: UInt32 = 0x5622_0000
    /// Frames per double-buffer block (`iVar12 = 0x400`, M l. 78680; raw 10091df4).
    public static let blockFrames = 0x400

    public let outputRate: Double = 22050

    /// A sound as its sampled header gives it: `samples` = the header's bytes − 0x80 (element 0 is the one the
    /// Sound Tool drops), `rate` = the header's 16.16 rate.
    struct RawSound {
        let id: Int16
        let rate: UInt32
        let samples: [Int8]
    }

    /// One play-list entry's observable fields (tests).
    struct VoiceState: Equatable {
        var id: Int32
        var snd: Int16
        var priority: UInt16
        var left: UInt16
        var right: UInt16
        var baseStep: Int32
        var step: Int32
        var countdown: Int32
    }

    /// An `'asnd'` buffer in `pool`: `length` = blocks·1024 + 0x400 (the zero padding included).
    private struct Asnd {
        var offset: Int
        var length: Int
        var blocks: Int32
        var rate: UInt32
    }

    /// One 0x34-byte entry. Byte offsets in the original record are given per field.
    private struct Entry {
        var id: Int32 = 0           // +0x00
        var snd: Int16 = 0          // +0x04 sound (0 = empty)
        var asnd = -1               // index into `asnds`
        var countdown: Int32 = 0    // +0x0c blocks left
        var step: Int32 = 0         // +0x10 16.16
        var baseStep: Int32 = 0     // +0x14 16.16
        var acc: UInt32 = 0         // +0x18 source position, 1/256 sample
        var cur = 0                 // +0x20 current sample (index into the asnd data; +0x08 = data start = 0)
        var prev = -1               // +0x24 previous mixed sample pointer (0 = none → −1)
        var left: UInt16 = 0        // +0x2c
        var right: UInt16 = 0       // +0x2e
        var priority: UInt16 = 0    // +0x30
    }

    private let lock = NSLock()
    private let pool: UnsafeMutableBufferPointer<Int8>
    private let asnds: [Asnd]
    private let bySnd: [Int16: Int]

    // Guarded by `lock`.
    private var list: [Entry]
    private var count = 0                    // *_DAT_100a1310
    private var nextId: Int32 = 1            // *_DAT_100a130c: 1, then += 2 (FUN_10091fe4 M l. 78777 ff., `*puVar2 = 1`)
    private let block: UnsafeMutableBufferPointer<UInt16>
    private var blockPos = SoundTool.blockFrames

    init(raw sounds: [RawSound]) {
        var asnds: [Asnd] = []
        var bySnd: [Int16: Int] = [:]
        var total = 0
        var layouts: [(n: Int, blocks: Int32, length: Int)] = []
        for s in sounds {
            // n = size − (hdr + 0x17) = header samples − 1; blocks = (n + 0x3ff) >> 10 (srawi/addze), ≥ 1 for the
            // stored count; the allocation uses the unclamped value (raw 100917d8..10091814).
            let n = max(s.samples.count - 1, 0)
            let ceil = (n + 0x3ff) >> 10
            let length = ceil * 0x400 + 0x400
            layouts.append((n, Int32(max(ceil, 1)), length))
            total += length
        }
        pool = .allocate(capacity: max(total, 1))
        pool.initialize(repeating: 0)
        var offset = 0
        for (s, layout) in zip(sounds, layouts) {
            for i in 0..<layout.n { pool[offset + i] = s.samples[i + 1] }
            if bySnd[s.id] == nil { bySnd[s.id] = asnds.count }
            asnds.append(Asnd(offset: offset, length: layout.length, blocks: layout.blocks, rate: s.rate))
            offset += layout.length
        }
        self.asnds = asnds
        self.bySnd = bySnd
        list = [Entry](repeating: Entry(), count: Self.listLength)
        block = .allocate(capacity: Self.blockFrames)
        block.initialize(repeating: 0x8080)
    }

    /// Every `snd ` of `bank`, from its decoded PCM (`(s − 128) << 8` → `s − 0x80`; no re-decode), at its exact
    /// 16.16 rate. Mono throughout (census); for a stereo sound the first channel would be taken.
    public convenience init(bank: SoundBank) {
        self.init(raw: bank.sounds.map { s in
            let ch = max(s.pcm.channels, 1)
            var samples = [Int8]()
            samples.reserveCapacity(s.pcm.frames)
            for f in 0..<s.pcm.frames { samples.append(Int8(truncatingIfNeeded: s.pcm.samples[f * ch] >> 8)) }
            return RawSound(id: s.id, rate: UInt32(s.pcm.sampleRate * 65536), samples: samples)
        })
    }

    deinit {
        pool.deallocate()
        block.deallocate()
    }

    // MARK: - Control (FUN_10091208, FUN_10091504, FUN_100916dc)

    /// `FUN_10091208` with request {sound `snd`, ref 0, `rate` (16.16, 0x10000 = as recorded), priority, left,
    /// right}. Returns the new entry's id (odd, from 1), or 0 when the sound is unknown or the request lost to
    /// all 16 entries.
    @discardableResult
    public func play(snd: Int16, priority: UInt16, left: UInt16, right: UInt16, rate: Int32 = 0x10000) -> Int32 {
        guard let a = bySnd[snd] else { return 0 }
        let asnd = asnds[a]
        // M l. 78243–78251: priority 0 → 1; each volume > 0x80 → 0x80 (cmplwi, unsigned).
        let prio: UInt16 = priority == 0 ? 1 : priority
        let l: UInt16 = min(left, 0x80)
        let r: UInt16 = min(right, 0x80)
        // Precomputed outside the lock (pure arithmetic): M l. 78272–78278 (raw 10091378..100913c8).
        let base = Self.fixDiv(Int32(bitPattern: asnd.rate >> 8), Int32(bitPattern: Self.outputRateFixed >> 8))
        let step = Self.fixMul(base, rate)
        var countdown = Int32(bitPattern: UInt32(bitPattern: Self.fixDiv(asnd.blocks << 16, step)) >> 16)
        if countdown < 1 { countdown = 1 }   // cmpwi r23,0x1; bge (raw 100913c0)

        lock.lock()
        defer { lock.unlock() }
        // M l. 78254–78263: skip while new.prio < e.prio (cmplw) or new.L+R < e.L+R (cmpw); else insert here.
        var s = 0
        while list[s].snd != 0 {
            let e = list[s]
            if prio < e.priority || Int32(l) + Int32(r) < Int32(e.left) + Int32(e.right) {
                s += 1
                if s >= Self.listLength { break }
            } else {
                break
            }
        }
        guard s < Self.listLength else { return 0 }   // raw 1009131c..10091334: dropped, nothing evicted
        if count > 15 { count = 15 }                  // the 16th entry is overwritten
        var i = count
        while i > s { list[i] = list[i - 1]; i -= 1 } // BlockMoveData(e[s] → e[s+1], (count − s)·0x34)
        let id = nextId
        nextId &+= 2                                  // request ref 0 → *_DAT_100a130c, += 2 (M l. 78294–78298)
        list[s] = Entry(id: id, snd: snd, asnd: a, countdown: countdown, step: step, baseStep: base,
                        acc: 0, cur: 0, prev: -1, left: l, right: r, priority: prio)
        count += 1
        return id
    }

    /// `FUN_10091504(snd)`: removes every entry playing `snd`, closing up the list.
    public func stop(snd: Int16) {
        lock.lock()
        defer { lock.unlock() }
        var i = 0
        while i < count {
            if list[i].snd == snd { remove(at: i) } else { i += 1 }
        }
    }

    /// `FUN_100916dc(snd) != 0`: some entry (audible or not) is playing `snd`.
    public func isPlaying(snd: Int16) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        for i in 0..<count where list[i].snd == snd { return true }
        return false
    }

    func snapshot() -> [VoiceState] {
        lock.lock()
        defer { lock.unlock() }
        return (0..<count).map { i in
            let e = list[i]
            return VoiceState(id: e.id, snd: e.snd, priority: e.priority, left: e.left, right: e.right,
                              baseStep: e.baseStep, step: e.step, countdown: e.countdown)
        }
    }

    // MARK: - Output

    public func render(into buffer: UnsafeMutableBufferPointer<Float>, frames: Int) {
        lock.lock()
        defer { lock.unlock() }
        for f in 0..<frames {
            if blockPos >= Self.blockFrames {
                mixBlock()
                blockPos = 0
            }
            let w = block[blockPos]
            blockPos += 1
            buffer[2 * f] = Float(Int(w >> 8) - 0x80) / 128
            buffer[2 * f + 1] = Float(Int(w & 0xff) - 0x80) / 128
        }
    }

    /// `FUN_10091c94`: one block, then the countdowns (lock held).
    private func mixBlock() {
        for f in 0..<Self.blockFrames { block[f] = mixFrame() }
        var i = 0
        while i < count {
            list[i].countdown &-= 1
            if list[i].countdown == 0 { remove(at: i) } else { i += 1 }   // FUN_10091b44; iVar9 − 1
        }
    }

    /// One frame of `FUN_10091ddc` (lock held).
    private func mixFrame() -> UInt16 {
        var sumL: Int32 = 0
        var sumR: Int32 = 0
        for i in 0..<count {
            let a = asnds[list[i].asnd]
            if i < Self.audibleVoices {
                let cur = list[i].cur
                var v = sample(a, cur)                                    // lbz; extsb
                if cur == list[i].prev {
                    v = (v + sample(a, cur + 1)) >> 1                     // add; srawi 1 (raw 10091e38..10091e44)
                }
                list[i].prev = cur
                sumL &+= (v &* Int32(list[i].left)) >> 7                  // mullw; srawi 7
                sumR &+= (v &* Int32(list[i].right)) >> 7
            }
            // Every entry advances (raw 10091e70..10091e9c): acc += step >> 8 (logical); cur = data + (acc >> 8).
            list[i].acc &+= UInt32(bitPattern: list[i].step) >> 8
            list[i].cur = Int(list[i].acc >> 8)
        }
        sumL = min(max(sumL, -0x7f), 0x7f)
        sumR = min(max(sumR, -0x7f), 0x7f)
        return UInt16(sumL + 0x80) << 8 | UInt16(sumR + 0x80)    // left in the high (first) byte
    }

    /// A data byte; past the allocation (the original reads whatever follows on the heap) → 0.
    private func sample(_ a: Asnd, _ index: Int) -> Int32 {
        index >= 0 && index < a.length ? Int32(pool[a.offset + index]) : 0
    }

    /// `FUN_10091b44` (lock held): close the gap, clear the freed tail entry.
    private func remove(at i: Int) {
        count -= 1
        var j = i
        while j < count { list[j] = list[j + 1]; j += 1 }
        list[count] = Entry()
    }

    // MARK: - Toolbox fixed point

    /// `FixMul`: (a·b) / 65536, rounded to nearest [MED: the Toolbox rounding is not in the dump].
    static func fixMul(_ a: Int32, _ b: Int32) -> Int32 {
        let p = Int64(a) * Int64(b)
        let r = (p + 0x8000) >> 16
        return Int32(clamping: r)
    }

    /// `FixDiv`: (a·65536) / b, rounded to nearest; b = 0 → ±0x7fffffff [MED: Toolbox rounding/overflow].
    static func fixDiv(_ a: Int32, _ b: Int32) -> Int32 {
        guard b != 0 else { return a < 0 ? Int32.min : Int32.max }
        let n = Int64(a) << 16
        let d = Int64(b)
        let q = (n + (((n < 0) != (d < 0)) ? -(abs(d) / 2) : abs(d) / 2)) / d
        return Int32(clamping: q)
    }
}
