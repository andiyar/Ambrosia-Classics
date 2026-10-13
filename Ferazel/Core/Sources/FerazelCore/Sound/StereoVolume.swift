import Foundation

/// `.CalcStereoVolume @ 10047738` and `.PEDistance @ 10047648` (S1; decompile l. 40636–40765; sprites-backgrounds-sounds
/// §6.3): the stereo pair of a positional sound from the scroll point `PTR_DAT_1009fe78` = (v, h).
public enum StereoVolume {
    /// `.PEDistance(a, b)`: max(|a|, |b|) + min(|a|, |b|) / 3 (C division; both non-negative here).
    public static func peDistance(_ a: Int, _ b: Int) -> Int {
        let x = abs(a), y = abs(b)
        return max(x, y) + min(x, y) / 3
    }

    /// `.CalcStereoVolume(&out, vol, pos)`: two ears at (h + 200, v + 0xc0) and (h + 0x198, v + 0xc0), each ear
    /// d = `.PEDistance(|ear − x|, |ear − y|)` (the sums and the position in shorts), g = d < 0x401 ? (0x400 − d) >> 3
    /// : 0; L = (short)(g_L · vol >> 7), R likewise; the louder side gains and the quieter loses s = 2·|L − R| +
    /// (2·|L − R| >> 1) (shorts); R then L clamped to 0..0x100. `volume` is the caller's already-scaled
    /// `(short)((vol · global) >> 8)`; `position` = the `+0xe` word (y high, x low).
    public static func calc(volume: Int16, position: SpriteSlot.Point, scrollH: Int, scrollV: Int)
        -> (left: Int16, right: Int16) {
        func s16(_ n: Int) -> Int { Int(Int16(truncatingIfNeeded: n)) }
        let x = s16(position.x), y = s16(position.y)
        let dy = abs(s16(scrollV + 0xc0) - y)
        func gain(_ ear: Int) -> Int {
            let d = peDistance(abs(s16(scrollH + ear) - x), dy)
            return d < 0x401 ? (0x400 - d) >> 3 : 0
        }
        let vol = Int(volume)
        var l = Int16(truncatingIfNeeded: (gain(200) * vol) >> 7)
        var r = Int16(truncatingIfNeeded: (gain(0x198) * vol) >> 7)
        if l < r {
            var s = Int16(truncatingIfNeeded: Int(r &- l) * 2)
            s = s &+ (s >> 1)
            l = l &- s
            r = r &+ s
        } else if r < l {
            var s = Int16(truncatingIfNeeded: Int(l &- r) * 2)
            s = s &+ (s >> 1)
            l = l &+ s
            r = r &- s
        }
        if 0x100 < r { r = 0x100 } else if r < 0 { r = 0 }
        if 0x100 < l { l = 0x100 } else if l < 0 { l = 0 }
        return (l, r)
    }
}
