import Foundation

/// One slot of the mixer's voice list — the 0x38-byte struct of bank sound-music §3, filled by `FUN_100d18d0`
/// (`100d1a30..100d1ac8`). The completion callback / refcon (`+0x10`, `+0x2C`) are always 0 in Deimos (the play
/// primitive `FUN_10047bf0` passes none, `10047de8`/`10047df0`) and are not modelled.
public struct Voice: Sendable, Equatable {
    /// `+0x00` voice id (the mixer's odd counter, +2 per voice; never 0 for a started voice).
    public var id: UInt32
    /// `+0x04` the sound (here an index into the mixer's sound table; the original holds the `asnd` pointer).
    public var sound: Int
    /// `+0x08` step = `FixMul(ratio, pitch16.16)` (`FUN_1006e250`, `100d1a8c`).
    public var step: UInt32
    /// `+0x0C` `FixDiv(outputRate, soundRate)` (`FUN_1006e2b0`, `100d1a74`) — 1.0 for 44.1 kHz sounds.
    public var ratio: UInt32
    /// `+0x18` IMA predictor (`sth`/`lha`: signed 16-bit).
    public var predictor: Int16
    /// `+0x1A` IMA step index 0…88.
    public var stepIndex: UInt16
    /// `+0x1C` / `+0x20` position / total samples (`asnd+4`).
    public var position: UInt32
    public var total: UInt32
    /// `+0x24` / `+0x28` the last output per side (the interpolation origin).
    public var lastLeft: Int32
    public var lastRight: Int32
    /// `+0x30` / `+0x32` gains, ≤ 0x80 (unity = 0x80).
    public var gainLeft: UInt16
    public var gainRight: UInt16
    /// `+0x34` priority (0 → 1 at insertion).
    public var priority: UInt16
    /// `+0x36` set by the decoder when the input is exhausted; the voice is removed after the block.
    public var finished: Bool

    /// A zeroed slot (`memset` at init `100d1530`, `FUN_10068920` after every removal).
    public static let empty = Voice(id: 0, sound: -1, step: 0, ratio: 0, predictor: 0, stepIndex: 0, position: 0,
                                    total: 0, lastLeft: 0, lastRight: 0, gainLeft: 0, gainRight: 0, priority: 0,
                                    finished: false)

    // MARK: The IMA tables (data image, TOC `r2−0x6258` → 0x100f7a44 and `r2−0x6254` → 0x100f7a84)

    /// Step-index deltas per nibble (16 × Int32 at 0x100f7a44) — the standard IMA table.
    static let indexTable: [Int32] = [-1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8]
    /// Step sizes (89 × Int32 at 0x100f7a84) — the standard IMA table.
    static let stepTable: [Int32] = [
        7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31, 34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 97,
        107, 118, 130, 143, 157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658, 724,
        796, 876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024, 3327, 3660, 4026,
        4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899, 15289, 16818, 18500,
        20350, 22385, 24623, 27086, 29794, 32767,
    ]

    /// `FUN_100d32d0` — decode, gain, resample and saturating-mix ONE voice into `frames` stereo Int16 frames
    /// (`dest`), or advance it silently (`dest == nil`, the voices at index ≥ numChannels: `FUN_100d21a0`
    /// `100d2244 li r4,0`). Returns the `+0x36` flag: true when the input is exhausted. Transcribed from the
    /// listing `100d32d0..100d3528` (disasm-review2.txt):
    ///
    /// * Per input sample (`CTR` = total − position): nibble `pos` (high nibble first, see `IMAContinuous`);
    ///   `stepIndex += indexTable[nib]`, clamped to 0…88 (`add.; bge` → 0, `cmpwi r18,0x58` → 88); the
    ///   difference is `((nib & 7) << 4 | 8) × step >> 6` (`100d3368..100d33a8`: `ori r8,r8,8; mullw; srawi 6`) =
    ///   ⌊(2m+1)·step/8⌋ — **not** the shift-sum of the reference IMA decoder — using the step of the index
    ///   BEFORE this nibble's update; the predictor is clamped to **−32768…32767** (`cmpwi r19,-0x8000` /
    ///   `cmpwi r19,0x7fff`). No re-sync to any packet header: predictor/index carry across the whole sound.
    /// * `acc += step >> 4` (the caller passes `step >> 4`, `FUN_100d21a0` `100d220c`); `acc` and `prev` are
    ///   locals that **start at 0 on every call** (`100d32e4`, `100d32ec`): the fractional phase is lost at
    ///   each 1024-frame block. `n = (acc >> 12) − (prev >> 12)` (logical shifts); `n == 0` → the sample is
    ///   decoded but nothing is written (`cmplwi r14,1; blt`).
    /// * `n ≥ 1`: side value `s = predictor × gain >> 7` (`mullw; srawi 7`); `prev = acc`; then
    ///   `r24 = 256 / n` (unsigned) and outputs `k = 1, 2, …` while `k·r24 ≤ 256`, each
    ///   `last + (k·r24·(s − last) >> 8)` saturating-added into the buffer (±: −32768…32767, `100d3440..100d3488`);
    ///   afterwards `last = s`. A silent voice runs the same frame count (`100d34b4..100d34d8`).
    /// * The buffer filling up ends the call **mid-sample**: the remaining outputs of that input sample are lost
    ///   and `last` is NOT updated (`100d3498 beq 0x100d34f0`, `100d34cc`). Done iff the input is exhausted.
    public mutating func render(_ sound: IMAContinuous, into dest: UnsafeMutablePointer<Int16>?, frames: Int) -> Bool {
        var pred = Int32(predictor)
        var index = Int32(stepIndex)
        var pos = position
        var remaining = total &- position
        var lastL = lastLeft, lastR = lastRight
        let gainL = Int32(gainLeft), gainR = Int32(gainRight)
        let accStep = step >> 4
        var acc: UInt32 = 0, prev: UInt32 = 0
        var framesLeft = frames
        var out = dest
        var stepSize = Self.stepTable[Int(index)]

        decode: while remaining != 0 {
            let nib = sound.nibble(at: pos)
            pos &+= 1
            remaining &-= 1
            index += Self.indexTable[Int(nib)]
            if index < 0 { index = 0 } else if index > 88 { index = 88 }
            let diff = (Int32((nib & 7) << 4 | 8) &* stepSize) >> 6
            if nib & 8 != 0 {
                pred -= diff
                if pred < -32768 { pred = -32768 }
            } else {
                pred += diff
                if pred > 32767 { pred = 32767 }
            }
            acc &+= accStep
            let n = (acc >> 12) &- (prev >> 12)
            if n >= 1 {
                let sL = (pred &* gainL) >> 7, sR = (pred &* gainR) >> 7
                prev = acc
                let r24 = Int32(bitPattern: 256 / n)
                if let d = out {
                    let incL = r24 &* (sL &- lastL), incR = r24 &* (sR &- lastR)
                    var aL = incL, aR = incR, k = r24
                    var p = d
                    while k <= 256 {
                        p[0] = Self.saturate(lastL &+ (aL >> 8) &+ Int32(p[0]))
                        p[1] = Self.saturate(lastR &+ (aR >> 8) &+ Int32(p[1]))
                        p += 2
                        framesLeft -= 1
                        if framesLeft == 0 { out = p; break decode }
                        aL &+= incL; aR &+= incR; k &+= r24
                    }
                    out = p
                } else {
                    var k = r24
                    while k <= 256 {
                        framesLeft -= 1
                        if framesLeft == 0 { break decode }
                        k &+= r24
                    }
                }
                lastL = sL
                lastR = sR
            }
            stepSize = Self.stepTable[Int(index)]
        }

        predictor = Int16(truncatingIfNeeded: pred)
        stepIndex = UInt16(index)
        position = pos
        lastLeft = lastL
        lastRight = lastR
        return remaining == 0
    }

    @inline(__always)
    static func saturate(_ v: Int32) -> Int16 {
        v < -32768 ? -32768 : v > 32767 ? 32767 : Int16(v)
    }
}
