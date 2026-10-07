import Foundation
import DeimosCore

/// The particle draw's per-stamp body, `FUN_10043ba0` (particles-debris-blur §2.9; listing `10043d20..100444ec`).
///
/// Each stamp writes a 7×7 square into the back buffer (`*(*(r2−0x7904)+0x68)` via `FUN_1000a4a0`, rowBytes =
/// 2·width) with its **top-left** at (x, y) (`10043d48 mullw` row·rowBytes + col·2). Per pixel
/// `dst' = (dst·w + col·(32 − w)) >> 5` in the spread-555 form `(c & 0x7c1f) | (c & 0x3e0) << 15` — the game's one
/// blend kernel (`Blend555.blend`, same pack/unpack: `10043da8…10043dd4`). With f = fade (`lwz r4,8(r6)`):
/// ```
/// row0: A A B B B A A      A = min(f+22,31) fringe   B = min(f+10,31) fringe
/// row1: A B C C C B A      C = min(f+6,31)  fringe
/// row2: B C D E D C B      D = f fringe      E = f core
/// row3: B C E X E C B      X = (f > 6 ? f − 7 : f) core   (centre)
/// row4: B C D E D C B
/// row5: A B C C C B A
/// row6: A A B B B A A
/// ```
/// r6 is the particle slot + 4 (`10043c80 addi r6,r30,0x4; add r6,r29,r6`, the alive byte at `0(r6)`); from it the
/// fringe is the `+4` word (`10043d54 lhz r20,4(r6)`, spread at `10043dac`), the core the `+2` word
/// (`10043d4c lhz r12,2(r6)`, spread only at `10044040`) — offsets from r6, not from the slot start. D blends the fringe: row 2 col 2 (`10044014..10044034`)
/// adds r11 = fringe·(32 − f) (`10043fc4`); E and X are the only core pixels (plan review leg A I-5). The caps
/// and the centre test are unsigned (`cmplwi`, `10043d30…10043d98`) and the weights wrap mod 2³² as `Blend555`
/// does, so an out-of-range fade follows the original's word arithmetic.
///
/// The visibility test is Core's: the original stamps only when `sx ≥ 0`, `sx + 7 < W`, `sy ≥ 0`, `sy + 7 < H` on the
/// float position (`10043c94…10043d1c`) and Core emits only those stamps. A stamp whose 7×7 square does not lie
/// inside the buffer (reachable only through a Core bug — the original would write outside the buffer) is skipped.
public enum ParticleStamps {
    /// One stamp pixel: `dst` weighted by `weight`, `colour` by `32 − weight`.
    @inline(__always)
    public static func blend(dst: UInt16, colour: UInt16, weight: UInt32) -> UInt16 {
        Blend555.blend(dst, colour, a: Int(Int32(bitPattern: weight)))
    }

    /// The 7×7 pattern, row-major: 0 = A, 1 = B, 2 = C, 3 = D, 4 = E, 5 = X. A/B/C/D take the fringe, E/X the core.
    private static let pattern: [UInt8] = [
        0, 0, 1, 1, 1, 0, 0,
        0, 1, 2, 2, 2, 1, 0,
        1, 2, 3, 4, 3, 2, 1,
        1, 2, 4, 5, 4, 2, 1,
        1, 2, 3, 4, 3, 2, 1,
        0, 1, 2, 2, 2, 1, 0,
        0, 0, 1, 1, 1, 0, 0,
    ]

    /// Stamps every entry in order into `back`.
    public static func stamp(_ stamps: [ParticleStamp], into back: inout Pixmap555) {
        for s in stamps { stamp(s, into: &back) }
    }

    /// One stamp. Nothing is allocated per stamp: the weights are locals, the pattern a static table.
    public static func stamp(_ s: ParticleStamp, into back: inout Pixmap555) {
        let x = Int(s.x), y = Int(s.y)
        guard x >= 0, y >= 0, x + 7 <= back.width, y + 7 <= back.height else { return }
        let f = UInt32(bitPattern: s.fade)
        let wA = min(f &+ 22, 31)                   // 10043d7c…10043d88
        let wB = min(f &+ 10, 31)                   // 10043d6c…10043d78
        let wC = min(f &+ 6, 31)                    // 10043d8c…10043d98
        let wX = f > 6 ? f &- 7 : f                 // 10043d30 cmplwi r4,6; ble; 10043d68 subi r31,r4,7
        let width = back.width
        pattern.withUnsafeBufferPointer { pat in
            back.pixels.withUnsafeMutableBufferPointer { px in
                for row in 0..<7 {
                    let base = (y + row) * width + x
                    for col in 0..<7 {
                        let colour: UInt16, w: UInt32
                        switch pat[row * 7 + col] {
                        case 0: (colour, w) = (s.fringe, wA)
                        case 1: (colour, w) = (s.fringe, wB)
                        case 2: (colour, w) = (s.fringe, wC)
                        case 3: (colour, w) = (s.fringe, f)     // D
                        case 4: (colour, w) = (s.core, f)       // E
                        default: (colour, w) = (s.core, wX)     // X
                        }
                        px[base + col] = blend(dst: px[base + col], colour: colour, weight: w)
                    }
                }
            }
        }
    }
}
