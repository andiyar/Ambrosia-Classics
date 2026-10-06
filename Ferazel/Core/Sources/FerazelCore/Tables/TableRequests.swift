import Foundation

/// A QuickDraw `RGBColor`: three 16-bit channels (the request every table builder hands `Color2Index`).
public struct RGB16: Hashable, Sendable {
    public var red: UInt16
    public var green: UInt16
    public var blue: UInt16

    public init(red: UInt16, green: UInt16, blue: UInt16) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public init(_ red: UInt16, _ green: UInt16, _ blue: UInt16) {
        self.init(red: red, green: green, blue: blue)
    }

    /// Entry `i` of a CLUT, without its value field.
    public init(_ entry: ColorLUT.Entry) {
        self.init(red: entry.red, green: entry.green, blue: entry.blue)
    }
}

/// The requested 16-bit RGB of every computed colour table (lighting-tables §3–§7), as the original's builders
/// compute it before `Color2Index`. Pure arithmetic, transcribed from the bank [HIGH]; never an index — choosing
/// the index is `FerazelRender.ColorSearch`'s job (design §6, DECISIONS D26). Every table takes the CLUT its
/// builder reads (the working copy for tint/water/redden/pair, the level+base CLUT for ambient/light, §1.3).
public enum TableRequests {

    /// One table entry as the builder leaves it.
    public enum Entry: Hashable, Sendable {
        /// `Color2Index(rgb)` is stored.
        case request(RGB16)
        /// The index is stored directly: the identity fill, a fixed-index row, or a table never written (zero).
        case index(UInt8)
        /// `Color2Index(rgb)` is called and then the store is overwritten with `index` (redden A entry 0xff).
        case overridden(RGB16, index: UInt8)

        /// The colour handed to `Color2Index`, if the builder makes that call for this entry.
        public var request: RGB16? {
            switch self {
            case .request(let c), .overridden(let c, _): return c
            case .index: return nil
            }
        }
    }

    // MARK: - §3 tint bank (`.BuildTintTable`, 25 tables of 256)

    /// Tables 0x10..0x15 touch only these indices; every other index maps to itself (§3.1 "sel").
    public static let selIndices: [Int] = [0x24, 0x3b, 0x3f, 0x40, 0x4e, 0x53, 0x57, 0x5b, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76]
    /// Tables whose entries are RGB requests built from the CLUT (0xa is random; 0 identity; the rest fixed-index).
    public static let computedTints: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0xb, 0xc, 0xd, 0xe, 0x10, 0x11, 0x16]
    public static let tintCount = 25

    /// `lum = (R+G+B)/3`, truncating (`mulhw 0x55555556`, §3.1).
    @inline(__always) static func lum(_ c: RGB16) -> Int { (Int(c.red) + Int(c.green) + Int(c.blue)) / 3 }

    @inline(__always) static func clamp16(_ v: Int) -> UInt16 { UInt16(max(0, min(0xffff, v))) }

    /// `fctiwz` then `sth`: truncate toward zero, keep the low 16 bits.
    @inline(__always) static func wrap16(_ v: Int) -> UInt16 { UInt16(truncatingIfNeeded: v) }

    /// Tint table `k` (0..0x18) on `clut` (lighting-tables §3.1). `random(5000)` stands for `.FastRand(5000)`;
    /// table 0xa draws B first, then R, for each of entries 0..0xfe — no other table calls it.
    public static func tint(_ k: Int, clut: ColorLUT, random: (Int16) -> UInt16) -> [Entry] {
        precondition((0..<tintCount).contains(k), "tint table \(k)")
        let sel = Set(selIndices)
        return (0..<256).map { i -> Entry in
            let c = RGB16(clut.entries[i])
            let identity = Entry.index(UInt8(i))
            switch k {
            case 0:
                return identity
            case 1, 2, 3, 4, 5, 8, 9, 0xa, 0xb, 0xc:
                guard i <= 0xfe else { return identity }   // loops `blt 0xff`; entry 0xff keeps the identity fill
                if k == 0xa {
                    let b = random(5000)
                    let r = random(5000)
                    return .request(RGB16(r, UInt16(lum(c)), b))
                }
                return .request(tintRequest(k, c))
            case 6, 7, 0xd, 0xe, 0x16:
                return .request(tintRequest(k, c))
            case 0x10, 0x11:
                return sel.contains(i) ? .request(tintRequest(k, c)) : identity
            case 0x12, 0x13, 0x14, 0x15:
                return sel.contains(i) ? .index(fixedIndex(k, c)) : identity
            default:   // 0xf, 0x17, 0x18: every index
                return .index(fixedIndex(k, c))
            }
        }
    }

    /// The requested colour of a computed tint table (§3.1 rows; constants f64, `tools/const.py`).
    static func tintRequest(_ k: Int, _ c: RGB16) -> RGB16 {
        let R = Int(c.red), G = Int(c.green), B = Int(c.blue), L = lum(c)
        switch k {
        case 1:
            return RGB16(UInt16(min(L + 10000, 0xffff)), 0, 0)
        case 2:
            let v = L + 10000
            if v <= 0xffff { return RGB16(UInt16(v), UInt16(v), 0) }
            return RGB16(0xffff, 0xffff, UInt16(min(4 * (v - 0xffff), 0xffff)))
        case 3:
            return RGB16(0, UInt16(L >> 1), UInt16(min(2 * L, 0xffff)))
        case 4:
            return RGB16(UInt16(R >> 1), UInt16(G >> 1), UInt16(min(2 * L, 0xffff)))
        case 5:
            let g = UInt16(min(L + 16000, 0xffff))
            return RGB16(g, g, g)
        case 6:
            return RGB16(UInt16(R >> 1), UInt16(G >> 1), UInt16(B >> 1))
        case 7:
            return RGB16(UInt16(R >> 2), UInt16(G >> 2), UInt16(B >> 2))
        case 8:   // ·1.5 (100a1728), clamp
            return RGB16(clamp16(Int(Double(R) * 1.5)), clamp16(Int(Double(G) * 1.5)), clamp16(Int(Double(B) * 1.5)))
        case 9:   // ·2.5 (100a16a8), clamp
            return RGB16(clamp16(Int(Double(R) * 2.5)), clamp16(Int(Double(G) * 2.5)), clamp16(Int(Double(B) * 2.5)))
        case 0xb:
            return RGB16(UInt16(L), UInt16(L), UInt16(L))
        case 0xc:
            return RGB16(0xffff, UInt16(L), 0)
        case 0xd:
            return RGB16(c.red, UInt16((G + 0xffff) >> 1), UInt16((B + 0xffff) >> 1))
        case 0xe:   // sepia
            return RGB16(UInt16((L + (L >> 1)) >> 1), UInt16(((L >> 1) + (L >> 2)) >> 1), 0)
        case 0x10:  // gold: no clamp, `sth` keeps the low 16 bits (100a16a0 1.7, 100a1698 1.2)
            return RGB16(wrap16(Int(1.7 * Double(L))), wrap16(Int(1.2 * Double(L))), 0)
        case 0x11:  // cyan
            return RGB16(0, clamp16(Int(2.5 * Double(L - 8000))), UInt16(min(Int(1.7 * Double(L)), 65535)))
        case 0x16:  // ·0.75 (100a16b0), no clamp needed
            return RGB16(UInt16(Int(Double(R) * 0.75)), UInt16(Int(Double(G) * 0.75)), UInt16(Int(Double(B) * 0.75)))
        default:
            preconditionFailure("tint table \(k) is not a computed table")
        }
    }

    /// The stored index of a fixed-index tint row (§3.1: 0xf, 0x12..0x15, 0x17, 0x18; jump tables in the raw column).
    static func fixedIndex(_ k: Int, _ c: RGB16) -> UInt8 {
        let L = lum(c)
        switch k {
        case 0xf:
            switch L >> 12 {
            case 0, 1: return 0x43
            case 2, 3: return 0x8d
            case 4, 5: return 0x8c
            case 6, 7: return 0x8b
            case 8, 9: return 0x8a
            case 10, 11: return 0x89
            case 12, 13: return 0x88
            default: return 0x8d
            }
        case 0x12, 0x18:
            return tealIndex(max(0, min(0xffff, 2 * L - 0x4000)) >> 12)
        case 0x13:
            switch max(0, min(0xffff, 2 * L - 0x4000)) >> 12 {
            case 0: return 0xff
            case 1: return 0xa0
            case 2, 3: return 0x8d
            case 4, 5: return 0x8c
            case 6, 7: return 0x8b
            case 8, 9: return 0x8a
            case 10, 11: return 0x89
            default: return 0x88
            }
        case 0x14:
            switch max(0, min(0xffff, 2 * L - 0x4000)) >> 13 {
            case 0, 1: return 0x7b
            case 2: return 0x7a
            case 3: return 0x79
            case 4: return 0x78
            case 5: return 0x77
            case 6: return 0x67
            default: return 0x66
            }
        case 0x15:
            return UInt8(0x9f - max(0, min(0xffff, 2 * L - 0x4000)) / 0x1a2c)
        case 0x17:
            switch max(0, min(0xffff, 2 * L - 32000)) >> 12 {
            case 0: return 0xff
            case 1: return 0x35
            case 2, 3: return 0x76
            case 4, 5: return 0x75
            case 6, 7: return 0x74
            case 8, 9: return 0x73
            case 10, 11: return 0x72
            case 12, 13: return 0x71
            default: return 0x2a
            }
        default:
            preconditionFailure("tint table \(k) is not a fixed-index table")
        }
    }

    private static func tealIndex(_ x: Int) -> UInt8 {
        switch x {
        case 0: return 0x9f
        case 1, 2: return 0x83
        case 3, 4: return 0x82
        case 5, 6: return 0x81
        case 7, 8: return 0x80
        case 9, 10: return 0x7f
        case 11, 12: return 0x7e
        case 13, 14: return 0x7d
        default: return 0x7c
        }
    }

    // MARK: - §4 water tables (`.BuildWaterTintTable`, w 0..5, entries 0..0xff)

    public static let waterCount = 6
    /// The water tables the builder writes; table 4 never is (all index 0).
    public static let computedWaters: [Int] = [0, 1, 2, 3, 5]

    /// Water table `w` (0..5) on `clut` (lighting-tables §4). Table 4 is never written: its zero-filled storage
    /// maps every entry to index 0.
    public static func water(_ w: Int, clut: ColorLUT) -> [Entry] {
        precondition((0..<waterCount).contains(w), "water table \(w)")
        return (0..<256).map { i -> Entry in
            w == 4 ? .index(0) : .request(waterRequest(w, RGB16(clut.entries[i])))
        }
    }

    static func waterRequest(_ w: Int, _ c: RGB16) -> RGB16 {
        let R = Int(c.red), G = Int(c.green), B = Int(c.blue), L = lum(c)
        switch w {
        case 0:
            return RGB16(UInt16(R >> 1), UInt16(G >> 1), UInt16(min(2 * L, 0xffff)))
        case 1:
            // t = 2·⌊L·m/0xffff⌋ ≤ 0xffff; out = trunc(0.15·c + 0.85·t) — the raw is `fmul 0.85·t` then
            // `fmadd 0.15·c + that` (100a1708 0.15, 100a1700 0.85; 10020620..1002064c).
            func t(_ m: Int) -> Double { Double(min(2 * ((L * m) / 0xffff), 0xffff)) }
            func out(_ ch: Int, _ m: Int) -> UInt16 { wrap16(Int((0.85 * t(m)).addingProduct(0.15, Double(ch)))) }
            return RGB16(out(R, 0x5f00), out(G, 0x8d00), out(B, 0x2c00))
        case 2:   // 100a16f8 0.7
            return RGB16(UInt16(Int(0.7 * Double(min(2 * L, 0xffff)))), UInt16(G >> 2), UInt16(B >> 3))
        case 3:
            let v = UInt16(min(min(2 * L, 0xffff) + 4000, 0xffff))
            return RGB16(v, UInt16(G >> 2), v)
        case 5:   // trunc(0.25·c) then + 29998.08 / 24760.32 / 10475.52, truncated, clamped (100a16f0/16e8/16e0/16d8)
            func q(_ ch: Int, _ add: Double) -> UInt16 { clamp16(Int(Double(Int(0.25 * Double(ch))) + add)) }
            return RGB16(q(R, 29998.08), q(G, 24760.32), q(B, 10475.52))
        default:
            preconditionFailure("water table \(w) is not written")
        }
    }

    // MARK: - §5 hurt-flash tables (`.BuildReddenTable`)

    /// Redden A table `n` (0..7, mode 3): blend toward red `(2·lum) & 0xfffe` — bit 16 dropped, so bright colours
    /// wrap — with weight (n+1)/8; entry 0xff is forced to index 0xff after its `Color2Index` (§5).
    public static func reddenA(_ n: Int, clut: ColorLUT) -> [Entry] {
        precondition((0..<8).contains(n), "redden A table \(n)")
        return (0..<256).map { i -> Entry in
            let c = RGB16(clut.entries[i])
            let L2 = (2 * lum(c)) & 0xfffe
            // (Swift's `>>` binds tighter than `*`: every product is parenthesised before its shift.)
            let rgb = RGB16(wrap16((((n + 1) * L2) >> 3) + (((7 - n) * Int(c.red)) >> 3)),
                            wrap16(((7 - n) * Int(c.green)) >> 3),
                            wrap16(((7 - n) * Int(c.blue)) >> 3))
            return i == 0xff ? .overridden(rgb, index: 0xff) : .request(rgb)
        }
    }

    /// Redden B table `n` (0..15, mode 4): blend toward pale yellow with weight (n+1)/16 (§5).
    public static func reddenB(_ n: Int, clut: ColorLUT) -> [Entry] {
        precondition((0..<16).contains(n), "redden B table \(n)")
        return (0..<256).map { i -> Entry in
            let c = RGB16(clut.entries[i])
            let s = lum(c) + 0xffff
            let k = ((n + 1) * ((s >> 1) & 0xffff)) >> 4
            return .request(RGB16(wrap16(k + (((15 - n) * Int(c.red)) >> 4)),
                                  wrap16(k + (((15 - n) * Int(c.green)) >> 4)),
                                  wrap16((((n + 1) * (s >> 2)) >> 4) + (((15 - n) * Int(c.blue)) >> 4))))
        }
    }

    // MARK: - §6.1 pair tables `T[src·0x100 + dst]` (row = sprite pixel, column = screen pixel)

    public enum Pair: CaseIterable, Sendable {
        /// `_DAT_100a0160`: min(src + dst, 0xffff) [HIGH].
        case additive
        /// `_DAT_100a015c`: (src + dst) >> 1 [HIGH].
        case average
        /// `_DAT_100a0158`: src>>1 + src>>2 + dst>>2, ¾ sprite [HIGH].
        case threeQuarterSprite
        /// `_DAT_100a0154`: src>>2 + dst>>1 + dst>>2, ¼ sprite [HIGH].
        case quarterSprite
        /// `_DAT_100a0150`: (dst + lum(src)) >> 1 [MED].
        case spriteGreyAverage
    }

    /// One pair-table request.
    public static func pair(_ p: Pair, src: RGB16, dst: RGB16) -> RGB16 {
        func ch(_ s: UInt16, _ d: UInt16, _ ls: Int) -> UInt16 {
            let s = Int(s), d = Int(d)
            switch p {
            case .additive: return UInt16(min(s + d, 0xffff))
            case .average: return UInt16((s + d) >> 1)
            case .threeQuarterSprite: return UInt16((s >> 1) + (s >> 2) + (d >> 2))
            case .quarterSprite: return UInt16((s >> 2) + (d >> 1) + (d >> 2))
            case .spriteGreyAverage: return UInt16((d + ls) >> 1)
            }
        }
        let ls = lum(src)
        return RGB16(ch(src.red, dst.red, ls), ch(src.green, dst.green, ls), ch(src.blue, dst.blue, ls))
    }

    /// The 65,536 requests of pair table `p`, entry `src·0x100 + dst`.
    public static func pair(_ p: Pair, clut: ColorLUT) -> [RGB16] {
        let colors = clut.entries.map(RGB16.init)
        var out: [RGB16] = []
        out.reserveCapacity(0x10000)
        for s in colors { for d in colors { out.append(pair(p, src: s, dst: d)) } }
        return out
    }

    // MARK: - §7 lighting (`.CalcAmbientDarken`, `.CalcLightingTable`)

    /// `.CalcAmbientDarken(c, L, D) @ 1001ab74` in **single precision** (§7.2; constants f32 1.0, 10.0, 0.0625):
    /// D = 0 returns `c`; else f = 1 − (L+1)/10, s = D·0.0625, each channel trunc(c − f·(c·s)) (`fctiwz`), stored
    /// mod 0x10000 (`sth`) — L = 10 brightens and wraps.
    public static func darken(_ c: RGB16, light L: Int, darkness D: Int) -> RGB16 {
        if D == 0 { return c }
        let f = Float(1) - Float(L + 1) / Float(10)
        let s = Float(D) * Float(0.0625)
        func ch(_ v: UInt16) -> UInt16 {
            let x = Float(v)
            return wrap16(Int(x - f * (x * s)))
        }
        return RGB16(ch(c.red), ch(c.green), ch(c.blue))
    }

    public static let darknessLevels = 16
    public static let lightGroups = 10
    public static let lightIntensities = 11

    /// Ambient table row D (0..15): `[D·0x100 + i] = Color2Index(darken(c_i, 0, D))` (§7.3).
    public static func ambient(darkness D: Int, clut: ColorLUT) -> [RGB16] {
        precondition((0..<darknessLevels).contains(D), "darkness \(D)")
        return clut.entries.map { darken(RGB16($0), light: 0, darkness: D) }
    }

    /// One light-table request: colour group g (0..9), intensity k (0..10), darkness D (0..15), on colour c
    /// (§7.3; `.CalcLightingTable @ 1001acc4`). d = darken(c, k, D), then the group rule. Multipliers are f64
    /// (100a1628 0.1, 1630 0.01, 1638 0.05, 1640 0.025, 1650 0.09) built with `fmadd`/`fnmsub`, and groups 5, 7
    /// add their integer term with `fmadd` (1001b4dc/b508, 1001b81c/b858).
    public static func light(group g: Int, intensity k: Int, darkness D: Int, color c: RGB16) -> RGB16 {
        precondition((0..<lightGroups).contains(g) && (0..<lightIntensities).contains(k), "light group \(g) k \(k)")
        let d = darken(c, light: k, darkness: D)
        let R = Int(d.red), G = Int(d.green), B = Int(d.blue)
        let kd = Double(k)
        func addClamp(_ v: Int, _ a: Int) -> UInt16 { UInt16(min(v + a, 0xffff)) }   // `cmpwi 0xffff; blt` else 0xffff
        func subFloor(_ v: Int, _ a: Int) -> UInt16 { let x = v - a; return x < 1 ? 0 : UInt16(x) }
        func fpClamp(_ x: Double) -> UInt16 { let v = Int(x); return v >= 0x10000 ? 0xffff : (v < 0 ? 0 : UInt16(v)) }
        switch g {
        case 0:
            return RGB16(addClamp(R, 1900 * k), addClamp(G, 1900 * k), addClamp(B, 1900 * k))
        case 1:
            let m = (1.0).addingProduct(-0.09, kd)
            func ch(_ v: Int) -> UInt16 {
                let x = Double(v) * m
                return Double(Float(x)) <= 0 ? 0 : wrap16(Int(x))
            }
            return RGB16(ch(R), ch(G), ch(B))
        case 2:
            return RGB16(addClamp(R, 2200 * k), addClamp(G, 1100 * k), d.blue)
        case 3:
            return RGB16(addClamp(R, 500 * k), addClamp(G, 1000 * k), addClamp(B, 3000 * k))
        case 4:
            return RGB16(addClamp(R, 3000 * k), subFloor(G, 300 * k), subFloor(B, 300 * k))
        case 5:
            let mr = (1.0).addingProduct(0.025, kd), mg = (1.0).addingProduct(0.05, kd), mb = (1.0).addingProduct(0.01, kd)
            return RGB16(fpClamp(Double(1250 * k).addingProduct(Double(R), mr)),
                         fpClamp(Double(2500 * k).addingProduct(Double(G), mg)),
                         fpClamp(Double(B) * mb))
        case 6:   // G + 1500k is only floored at 0, so it wraps (`1001b690 cmpwi 0; ble`)
            let gv = G + 1500 * k
            return RGB16(addClamp(R, 1500 * k), gv < 1 ? 0 : wrap16(gv), subFloor(B, 300 * k))
        case 7:
            let mr = (1.0).addingProduct(0.05, kd), mg = (1.0).addingProduct(0.025, kd), mb = (1.0).addingProduct(0.1, kd)
            return RGB16(fpClamp(Double(2000 * k).addingProduct(Double(R), mr)),
                         fpClamp(Double(G) * mg),
                         fpClamp(Double(4000 * k).addingProduct(Double(B), mb)))
        case 8:
            return d
        default:   // 9
            let m = (1.0).addingProduct(0.1, kd)
            return RGB16(fpClamp(Double(R) * m), fpClamp(Double(G) * m), fpClamp(Double(B) * m))
        }
    }

    /// Light table `[D·0x6e00 + (g·11 + k)·0x100 + i]` row (§7.3) on the level+base CLUT.
    public static func light(group g: Int, intensity k: Int, darkness D: Int, clut: ColorLUT) -> [RGB16] {
        precondition((0..<darknessLevels).contains(D), "darkness \(D)")
        return clut.entries.map { light(group: g, intensity: k, darkness: D, color: RGB16($0)) }
    }
}
