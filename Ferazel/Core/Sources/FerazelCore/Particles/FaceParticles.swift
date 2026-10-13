import Foundation

/// What the face emitters read of a face record (sprites-backgrounds §2.1): `+0x00` the frame rect, `+0x08` the tight
/// bounds and the RLE token stream (`**(face + 0x10) + 0x10`: big-endian u32 tokens, op = t >> 24 — 0 end, 1 next row,
/// 2 = n literal pixels padded to 4, 3 = skip n). Core has no face pixels: FerazelRender hands them over
/// (`SpriteWorld.particleFaces`, from the faces it loaded) — without a provider the emitters below emit nothing and
/// draw nothing (the RNG gap the Phase-2 stubs had).
public struct ParticleFace: Equatable, Sendable {
    /// (top, left, bottom, right).
    public var frame: [Int16]
    public var bounds: [Int16]
    public var tokens: [UInt8]

    public init(frame: [Int16], bounds: [Int16], tokens: [UInt8]) {
        self.frame = frame
        self.bounds = bounds
        self.tokens = tokens
    }

    /// The token at byte offset p (nil past the end — a truncated stream ends the walk).
    func word(_ p: Int) -> UInt32? {
        guard p >= 0, p + 4 <= tokens.count else { return nil }
        return UInt32(tokens[p]) << 24 | UInt32(tokens[p + 1]) << 16 | UInt32(tokens[p + 2]) << 8 | UInt32(tokens[p + 3])
    }
}

/// The face lookups the emitters need (E1a): a sprite face (`+0xc0`) and an FG tile face (`*_DAT_1009ff88 + 0x34·t`,
/// the level's FG set, tile 0…0x5f).
public struct ParticleFaces: Sendable {
    public var sprite: @Sendable (FaceRef) -> ParticleFace?
    public var fgTile: @Sendable (Int) -> ParticleFace?

    public init(sprite: @escaping @Sendable (FaceRef) -> ParticleFace? = { _ in nil },
                fgTile: @escaping @Sendable (Int) -> ParticleFace? = { _ in nil }) {
        self.sprite = sprite
        self.fgTile = fgTile
    }
}

/// `.ExplodeFaceIntoParticles(face, pos, xStep, yStep, shape, gravity, style) @ 10043448` (decompile l. 38377–38507,
/// raw `10043448..10043798`; particles §5.2). pos = (v, h); centre cV = v + (bounds.top + bounds.bottom) >> 1, cH = h +
/// (bounds.left + bounds.right) >> 1. The walk: a row token — the row is used when the row counter < 1 (then it is
/// yStep − 1), else the counter −1 and the row is skipped; h back to pos.h; v + 1 (so the first row sits at pos.v + 1).
/// A literal run: per pixel, on a used row, the column counter (never reset per row, starts 0) < 1 → emit, counter =
/// xStep − 1; else counter −1; h + 1 per pixel. A skip: h + n. Style 100: R(20), R(750), R(100), R(30) →
/// `NewParticle(−(px + 256), g + R30, (v, h), shape, R100 − 50, 40 − R750, −(98 − R20), 1)`; 101: R(60), R(60), R(16),
/// R(12) → `(−(px + 256), g + R12, …, shape, 50·(h − cH) + R60 − 30, 50·(v − cV) + R60 − 30, −(104 − R16), 1)`; 102:
/// R(60), R(60), R(5), R(2), R(12) → `(1, g + R12, …, R2 + 1, (as 101), R5, 1)`; another style walks without emitting.
public enum ExplodeFace {
    public static func explode(_ w: SpriteWorld, face f: ParticleFace?, v: Int16, h: Int16, xStep: Int16, yStep: Int16,
                               shape: Int16, gravity: Int16, style: Int16) {
        guard let f else { return }
        let cV = Int(Int16(truncatingIfNeeded: Int(v) + ((Int(f.bounds[0]) + Int(f.bounds[2])) >> 1)))
        let cH = Int(Int16(truncatingIfNeeded: Int(h) + ((Int(f.bounds[1]) + Int(f.bounds[3])) >> 1)))
        var used = true                                                  // r13
        var rowCounter: Int16 = 0                                        // r14
        var column: Int16 = 0                                            // r4
        var x = Int(h)                                                   // r31
        var y = v                                                        // r25
        var p = 0
        while let t = f.word(p) {
            p += 4
            let op = t >> 24, n = Int(t & 0xff_ffff)
            switch op {
            case 0:
                return
            case 1:
                if 0 < rowCounter {
                    used = false
                    rowCounter -= 1
                } else {
                    used = true
                    rowCounter = yStep &- 1
                }
                x = Int(h)
                y &+= 1
            case 2:
                for k in 0..<n {
                    if used {
                        if column < 1 {
                            let px = p + k < f.tokens.count ? Int(f.tokens[p + k]) : 0
                            emit(w, px: px, v: Int(y), h: x, cV: cV, cH: cH, shape: shape, gravity: gravity,
                                 style: style)
                            column = xStep &- 1
                        } else {
                            column -= 1
                        }
                    }
                    x += 1
                }
                p += n + (n & 3 == 0 ? 0 : 4 - (n & 3))
            case 3:
                x += n
            default:
                return
            }
        }
    }

    private static func emit(_ w: SpriteWorld, px: Int, v: Int, h: Int, cV: Int, cH: Int, shape: Int16,
                             gravity: Int16, style: Int16) {
        let g = Int(gravity)
        switch style {
        case 100:
            let r20 = Int(w.rng.next(0x14))
            let r750 = Int(w.rng.next(0x2ee))
            let r100 = Int(w.rng.next(100))
            let r30 = Int(w.rng.next(0x1e))
            w.particles.newParticle(kind: -(px + 0x100), gravity: g + r30, v: v, h: h, shape: Int(shape),
                                    vx: r100 - 0x32, vy: 0x28 - r750, delay: -(0x62 - r20), mode: 1)
        case 101, 102:
            let vx = (Int(Int32(truncatingIfNeeded: h)) - Int(Int16(truncatingIfNeeded: cH))) * 0x32
                + Int(w.rng.next(0x3c)) - 0x1e
            let vy = (Int(Int16(truncatingIfNeeded: v)) - cV) * 0x32 + Int(w.rng.next(0x3c)) - 0x1e
            if style == 101 {
                let r16 = Int(w.rng.next(0x10))
                let r12 = Int(w.rng.next(0xc))
                w.particles.newParticle(kind: -(px + 0x100), gravity: g + r12, v: v, h: h, shape: Int(shape), vx: vx,
                                        vy: vy, delay: -(0x68 - r16), mode: 1)
            } else {
                let r5 = Int(w.rng.next(5))
                let r2 = Int(w.rng.next(2))
                let r12 = Int(w.rng.next(0xc))
                w.particles.newParticle(kind: 1, gravity: g + r12, v: v, h: h, shape: r2 + 1, vx: vx, vy: vy,
                                        delay: r5, mode: 1)
            }
        default:
            break
        }
    }
}

/// `.ParticleGlow(face, pos, kind, chance, flip) @ 10043ad0` (decompile l. 38668–38760, raw `10043ad0..10043cb4`;
/// particles §5.6), from `.StandardSpriteCleanup` for `+0x1a8 ≠ 0` with a face. The centre cH = pos.h + (frame.left +
/// frame.right) >> 1. A row token: h = pos.h (+ the frame width `+6` when flipped), v + 1. A literal run of n: for k
/// = n … 1, on its first and last pixel: R(4) (v offset), R(5) (delay), R(100) (discarded), R(150) → vx = 120 + R150,
/// negated when h < cH; R(100) ≤ chance → R(80) → `NewParticle(kind, 0, (v + R4, h), 1, vx, 40 − R80, R5 + 2, 0)`;
/// h ± 1 per pixel (− when flipped). A skip: h ± n.
public enum ParticleGlow {
    public static func glow(_ w: SpriteWorld, face f: ParticleFace?, v: Int16, h: Int16, kind: Int16, chance: Int16,
                            flip: Bool) {
        guard let f else { return }
        let cH = Int16(truncatingIfNeeded: Int(h) + ((Int(f.frame[3]) + Int(f.frame[1])) >> 1))
        var x = Int(h)                                                   // iVar12 (r21)
        var y = v                                                        // sVar11 (r20)
        var p = 0
        while let t = f.word(p) {
            p += 4
            let op = t >> 24, n = Int(t & 0xff_ffff)
            switch op {
            case 0:
                return
            case 1:
                x = Int(h)
                if flip { x += Int(f.frame[3]) }
                y &+= 1
            case 2:
                var k = n
                while k != 0 {
                    if k == n || k == 1 {
                        let dv = w.rng.next(4)
                        let delay = Int(w.rng.next(5))
                        _ = w.rng.next(100)
                        var vx = Int(w.rng.next(0x96)) + 0x78
                        if Int16(truncatingIfNeeded: x) < cH { vx = -vx }
                        if w.rng.next(100) <= chance {
                            let r80 = Int(w.rng.next(0x50))
                            w.particles.newParticle(kind: Int(kind), gravity: 0, v: Int(y &+ dv), h: x, shape: 1,
                                                    vx: vx, vy: 0x28 - r80, delay: delay + 2, mode: 0)
                        }
                    }
                    x += flip ? -1 : 1
                    k -= 1
                }
                p += n + (n & 3 == 0 ? 0 : 4 - (n & 3))
            case 3:
                x += flip ? -n : n
            default:
                return
            }
        }
    }
}
