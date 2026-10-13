import Foundation

/// `.Splash(s, mode) @ 10042874` (decompile l. 37966–38071; particles §5.4): 3 = entering a liquid (from
/// `.HandleUnderWater`'s entry and the swim arm), 4 = leaving it (`.StandardSpriteCleanup`, `.BoxUW`).
///
/// Only when `+0x13e ≠ 0` and the sprite has a face. The sounds: snd = 605 (`_DAT_100a0204`, `FUN_10091748(0x25d)`)
/// for both when `+0x128 == 5` (quicksand), else the small 406 (`_DAT_100a0208`) and the big 405 (`_DAT_100a020c`);
/// the gate (l. 37998–38004): the centre `+0x10` within scroll h − 0x10 … h + 0x270, `+0xe` within v − 0x10 … v +
/// 400, the level frame counter `*_DAT_1009fd98` > 3, and (`+0x4c` ≠ `.HandlePlatformSprite` or type `+4` < 10).
/// The surface: row = `(short)((+0xa + face +0 + (short)W + 0x10) >> 5)` with W = `+0x11c`, or `+0x120` when 0 (the
/// face's first i16 is its frame rect's top, 0 — `UnderWater`); while the BG cell one row up (col = `+0x10 >> 5`) is
/// liquid, row −= 1; kind = the BG kind of (col, row), raised to 200 if lower; S = `(short)row · 0x20`.
/// - 3: the gate → `.STPlay3DSoundRand(hot-rect width < 0x11 ? small : big, 1, small ? 0x2d : 0x100, +0xe)` (the
///   rate drawn at its call site, `FastRand.soundRate()`); then for every column h from `+0xc + left − 4` while
///   `< +0xc + right + 4`: vx = R(500) + (−vx_s >> 4) − 250, vy0 = `(short)((−600 − R(200)) − (short)(vy_s >> 3))`,
///   `NewParticle(kind, 150, (S, h), 2, vx, vy0 + 400, 0, 1)`, `(…, 4, vx, vy0 + 200, 1, 1)`, `(…, 1, vx, vy0, 2, 1)`,
///   then R(1) (always 0) is the column step's extra.
/// - 4, only when the hot rect is wider than 0x10: the gate → `.STPlay3DSoundRand(small, 1, 0x100, +0xe)`; kind =
///   `+0x12a + 200`; only when vy < −0x4b0 the same columns at (S − 4, h).
public enum Splash {
    /// The snd ids of `_DAT_100a0204` / `_DAT_100a0208` / `_DAT_100a020c` (l. 39765–39768, 39997–39998).
    public static let quicksandSnd: Int16 = 605
    public static let smallSnd: Int16 = 406
    public static let bigSnd: Int16 = 405

    public static func splash(_ w: SpriteWorld, id: Int, mode: Int16) {
        guard let s = w.active.record(id: id), s.splashes, s.face != nil else { return }
        var water = s.waterRow
        if water == 0 { water = s.lastWater }
        let small: Int16, big: Int16
        if s.waterKind == 5 {
            small = quicksandSnd
            big = quicksandSnd
        } else {
            small = smallSnd
            big = bigSnd
        }
        let cx = Int(Int16(truncatingIfNeeded: s.centre.x)), cy = Int(Int16(truncatingIfNeeded: s.centre.y))
        let gate = (w.player.scrollH - 0x10 <= cx && cx <= w.player.scrollH + 0x270)
            && (w.player.scrollV - 0x10 <= cy && cy <= w.player.scrollV + 400 && 3 < w.frameCounter)
        let inset = 0                                                    // `**(short **)(s + 0xc0)`: frame rect top
        let y = Int(Int16(truncatingIfNeeded: s.y))
        var row = Int(Int16(truncatingIfNeeded: (y + inset + Int(Int16(truncatingIfNeeded: water)) + 0x10) >> 5))
        let col = Int(Int16(truncatingIfNeeded: s.centre.x) >> 5)
        while UnderWater.isWaterTile(w.tiles.bgKind(tile: w.tiles.bgTile(col: col, row: row - 1))) { row -= 1 }
        var kind = Int16(truncatingIfNeeded: w.tiles.bgKind(tile: w.tiles.bgTile(col: col, row: row)))
        if kind < 200 { kind = 200 }
        let surface = Int16(truncatingIfNeeded: row &* 0x20)
        let sounds = (s.handler != .platform || s.type < 10) && gate
        let width = Int(Int16(truncatingIfNeeded: s.hotRect.right)) - Int(Int16(truncatingIfNeeded: s.hotRect.left))
        func cue(_ snd: Int16, _ volume: Int16) {
            w.player.cues.append(PlayerCue(call: .threeDRand, snd: snd, priority: 1, volume: volume,
                                           position: s.centre, rate: w.rng.soundRate()))
        }
        if mode == 3 {
            if sounds {
                if width < 0x11 { cue(small, 0x2d) } else { cue(big, 0x100) }
            }
            columns(w, s, kind: Int(kind), v: Int(surface))
        } else if mode == 4 && 0x10 < width {
            if sounds { cue(small, 0x100) }
            let leaving = Int(s.previousWaterKind) + 200
            if s.vy < -0x4b0 {
                columns(w, s, kind: leaving, v: Int(Int16(truncatingIfNeeded: Int(surface) - 4)))
            }
        }
    }

    /// The column loop (raw `10042a58..10042b3c`, `10042bd0..10042cb4`): h starts at the 16-bit `+0xc + left − 4` and
    /// runs while `(int)h < +0xc + right + 4` (an int sum). h is kept as an Int here and truncated to 16 bits where it
    /// is used (`newParticle`), so a bound past 0x7fff ends the loop instead of wrapping h forever (the original's
    /// short h would spin there); in range every value is the same.
    private static func columns(_ w: SpriteWorld, _ s: SpriteSlot, kind: Int, v: Int) {
        let x = Int(Int16(truncatingIfNeeded: s.x))
        let end = x + Int(Int16(truncatingIfNeeded: s.hotRect.right)) + 4
        var h = Int(Int16(truncatingIfNeeded: x + Int(Int16(truncatingIfNeeded: s.hotRect.left)) - 4))
        while h < end {
            let vx = Int(w.rng.next(500)) + Int((0 &- s.vx) >> 4) - 0xfa
            let r = Int(w.rng.next(200))
            let vy0 = Int(Int16(truncatingIfNeeded: (-600 - r) - Int(Int16(truncatingIfNeeded: s.vy >> 3))))
            w.particles.newParticle(kind: kind, gravity: 0x96, v: v, h: h, shape: 2, vx: vx, vy: vy0 + 400,
                                    delay: 0, mode: 1)
            w.particles.newParticle(kind: kind, gravity: 0x96, v: v, h: h, shape: 4, vx: vx, vy: vy0 + 200,
                                    delay: 1, mode: 1)
            w.particles.newParticle(kind: kind, gravity: 0x96, v: v, h: h, shape: 1, vx: vx, vy: vy0,
                                    delay: 2, mode: 1)
            h += Int(w.rng.next(1)) + 1
        }
    }
}
