import Foundation
import FerazelCore

/// The particles' pixels (particles §3–§4; plan E1a, S4): the colour rows `.InitParticleColors @ 100306b4` builds at
/// level start, the draw half of `.DrawParticles @ 10031aa4` with `.WrapDrawParticle @ 10015948`, and
/// `.EraseParticles @ 10031d6c` with `FUN_10015fb8` / `FUN_10016440`. Core decides which particles live (its colour-0
/// kill, `ParticleLife`) and hands the survivors over (`DrawOp.drawParticles`); this type resolves their colours and
/// draws into the frame port against the mask port, remembering each record's erase mode `+0x1d` for the erase.
public struct ParticleRenderer: Sendable {
    /// `row[kind][age]`, 256 × 120 (TOC `100a01a8`).
    public let rows: [[UInt8]]
    /// The ambient table row `_DAT_100a0130[hdr+0x2706]` that lights negative kinds (§3.1 step 4).
    public let ambient: [UInt8]
    /// prefs+6: Reduced (3) draws negative kinds unlit (raw `10031b3c..10031b4c`).
    public let effects: Int16
    /// What the last `draw` handed `.WrapDrawParticle` and what it returned (`+0x1d`), in pool order.
    public private(set) var drawn: [(shape: Int16, v: Int16, h: Int16, erase: UInt8)] = []
    /// Particles Core handed over whose row here says 0 (the original would have killed them): not drawn. The E1b
    /// cross-check of `ParticleLife` against these rows; 0 when the two agree.
    public private(set) var rowDisagreements = 0

    public init(rows: [[UInt8]], ambient: [UInt8], effects: Int16) {
        self.rows = rows
        self.ambient = ambient
        self.effects = effects
    }

    /// The level's renderer: the rows against `screenClut` (the level+base CLUT `.SetScreenClut` installed just before
    /// `.InitParticles`, `.SetupLevel` l. 2571–2572), the ambient row of `darkness` (hdr `0x2706`).
    public init(system: ColorLUT, screenClut: ColorLUT, search: ColorSearch, tables: LevelTables, darkness: Int16,
                effects: Int16) {
        let d = tables.ambient.indices.contains(Int(darkness)) ? Int(darkness) : 0
        self.init(rows: Self.colourRows(system: system, screenClut: screenClut, search: search),
                  ambient: tables.ambient[d], effects: effects)
    }

    // MARK: - `.InitParticleColors`

    private enum Cell {
        case index(UInt8)
        case request(RGB16)
        /// Kind 215, s < 20: an index-0 result becomes 0x96 (raw `100314f8..10031504`).
        case request215(RGB16)
    }

    /// `.InitParticleColors @ 100306b4` (l. 28917–29644; particles §4.2): every row zeroed, then the recipes. "e" is
    /// an entry of clut 801 ("System CLUT", `*h + 8e + 10`); every RGB goes through `Color2Index` (`search`) against
    /// the screen CLUT. t = age, s = t >> 1; 16-bit channel stores truncate.
    public static func colourRows(system: ColorLUT, screenClut: ColorLUT, search: ColorSearch) -> [[UInt8]] {
        var cells = [[Cell]](repeating: [Cell](repeating: .index(0), count: 0x78), count: 0x100)
        func u(_ v: Int) -> UInt16 { UInt16(truncatingIfNeeded: v) }
        func e(_ i: Int) -> RGB16 {
            let c = system.entries[i]
            return RGB16(red: c.red, green: c.green, blue: c.blue)
        }
        func plusBlue(_ c: RGB16) -> RGB16 {
            var c = c
            if c.blue < 55000 { c.blue &+= 10000 }
            return c
        }
        func fire(_ t: Int) -> Int {
            switch t >> 1 {
            case 0, 1: return 3
            case 2, 3: return 5
            case 4: return 0xb
            case 5: return 0x11
            case 6: return 0x17
            case 7: return 0x1d
            default:
                let x = Int(Int16(truncatingIfNeeded: ((t >> 1) - 7) * 2 + 0xd7))
                return 0xdf < x ? 0 : x
            }
        }
        func byT(_ t: Int) -> Int { t < 4 ? 0x78 : (t < 8 ? 0x7e : (t < 12 ? 0xa8 : 0xeb)) }
        let f32p68 = Double(Float(bitPattern: 0x3f2e_147b))               // `lfs 100a1790`
        let f32p8 = Double(Float(bitPattern: 0x3f4c_cccd))                // `lfs 100a1760`
        var last205 = RGB16(red: 0, green: 0, blue: 0), last215 = RGB16(red: 0, green: 0, blue: 0)
        var g210 = Int16(32000), g211 = Int16(32000)
        for t in 0..<0x78 {
            let s = t >> 1
            cells[1][t] = .request(e(fire(t)))
            var k2 = t < 0x15 ? 0xd7 : ((t - 0x14) >> 1) + 0xd7
            if 0xdf < k2 { k2 = 0 }
            cells[2][t] = .request(e(k2))
            // Kind 3 (and kind 200's first write, overwritten below): e by t; r = g >> 1, g = g >> 2, b kept.
            let c3 = e(byT(t))
            cells[3][t] = .request(RGB16(red: c3.green >> 1, green: c3.green >> 2, blue: c3.blue))
            var k4 = s + 0xf6
            if 0xfd < k4 { k4 = 0 }
            cells[4][t] = .request(e(k4))
            cells[5][t] = .request(RGB16(red: 0, green: 37000, blue: 58000))
            cells[6][t] = .request(RGB16(red: 0, green: 0x70e4, blue: 0xcabc))
            cells[7][t] = .request(RGB16(red: 0, green: 10000, blue: 0x83a4))
            cells[8][t] = .request(RGB16(red: 0, green: 7000, blue: 22000))
            // 9: u = (int)(1.5·t); u < 0x13 → r = (20 − u)·0xc80, g = (int)(r · 0.75).
            let u9 = Int(Int16(truncatingIfNeeded: Int32(1.5 * Double(t))))
            if u9 < 0x13 {
                let r = u((0x14 - u9) * 0xc80)
                cells[9][t] = .request(RGB16(red: r, green: u(Int(Int32(Double(r) * 0.75))), blue: 0))
            }
            cells[11][t] = t / 3 < 5 ? .index(UInt8(0x89 + t / 3)) : .index(0)
            cells[10][t] = .index(t < 9 ? UInt8(0x9f - t) : (t < 0x11 ? UInt8(0x9f - (0x10 - t)) : 0))
            if t < 0x13 { cells[12][t] = .request(RGB16(red: 0, green: u((0x14 - t) * 0x1900), blue: 0)) }
            let k13 = fire(t)
            var c13 = e(k13)
            if k13 != 0 { c13 = RGB16(red: c13.blue, green: c13.green, blue: c13.red) }
            cells[13][t] = .request(c13)
            var g199 = 0, b199 = -0x4c50
            if s < 0x15 {
                b199 = (0x14 - s) * 0x3b6 - 0x4c50
                if s < 5 { g199 = (4 - s) * 0x2580 }
            }
            cells[199][t] = .request(RGB16(red: u(g199), green: u(g199), blue: u(b199)))
            let k200 = s < 4 ? 0x78 : (s < 8 ? 0x7e : (s < 0xc ? 0xa8 : 0xeb))
            cells[200][t] = .request(plusBlue(e(k200)))
            cells[201][t] = .index(UInt8(0x71 + min(t / 5, 3)))
            let r202 = s < 0xb ? u((10 - s) * 0xaf0 + 32000) : 32000
            cells[202][t] = .request(RGB16(red: r202, green: u(Int(Int32(0.4 * Double(r202)))), blue: 0))
            cells[203][t] = .request(RGB16(red: r202, green: 0, blue: r202))
            if s < 10 {
                var f = Double(Float(Double(Float(10 - s)) / 10.0))
                if f < 0.68 { f = f32p68 }
                last205 = RGB16(red: u(Int(Int32(48384 * f))), green: u(Int(Int32(39936 * f))),
                                blue: u(Int(Int32(16896 * f))))
            }
            cells[205][t] = .request(last205)
            if t < 0xb {
                let g = 2 < t ? u((t - 2) * 0x1194) : 0
                cells[210][t] = .request(RGB16(red: g, green: g, blue: UInt16(bitPattern: g210)))
                cells[211][t] = .request(RGB16(red: 0, green: UInt16(bitPattern: g211), blue: 0))
            } else if t < 0x15 {
                let g = t < 0x12 ? u((0x12 - t) * 0x1194) : 0
                cells[210][t] = .request(RGB16(red: g, green: g, blue: u((0x14 - t) * 0xc80 + 32000)))
                cells[211][t] = .request(RGB16(red: 0, green: u((0x14 - t) * 0xc80 + 32000), blue: 0))
            }
            g210 &+= 0xc80
            g211 &+= 0xc80
            cells[213][t] = .index([0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8c, 0x8b, 0x8a][s & 7])
            if s < 0x14 {
                let n = s < 10 ? 10 - s : s - 10
                var f = Double(Float(Double(Float(Double(Float(n)) / 10.0)) + 0.2))
                if f < 0.8 { f = f32p8 }
                func clamp(_ x: Double) -> UInt16 {
                    var v = Int32(x)
                    if v < 1 { v = 0 }
                    if 0xfffe < v { v = 0xffff }
                    return UInt16(v)
                }
                last215 = RGB16(red: clamp(48384 * f), green: clamp(39936 * f), blue: clamp(16896 * f))
                cells[215][t] = .request215(last215)
            } else {
                cells[215][t] = .request(last215)
            }
            if t < 0xc { cells[220][t] = .request(plusBlue(e(byT(t)))) }
            let c5 = u((5 - s) * 0x1900 + 32000)
            if s < 6 {
                cells[221][t] = .request(RGB16(red: 0, green: c5, blue: 0))
                cells[222][t] = .request(RGB16(red: c5, green: 0, blue: 0))
            }
            if s < 0xb {
                let r = s < 6 ? c5 : 32000
                let g = s < 3 ? u((2 - s) * 0x1900) : 0
                cells[223][t] = .request(RGB16(red: r, green: g, blue: r))
            }
        }
        var requests: [RGB16] = []
        for row in cells {
            for c in row {
                switch c {
                case .request(let rgb), .request215(let rgb): requests.append(rgb)
                case .index: break
                }
            }
        }
        var resolved = search.indices(of: requests, in: screenClut).makeIterator()
        return cells.map { row in
            row.map { c in
                switch c {
                case .index(let i): return i
                case .request: return resolved.next()!
                case .request215:
                    let i = resolved.next()!
                    return i == 0 ? 0x96 : i
                }
            }
        }
    }

    // MARK: - drawing

    /// `.DrawParticles`' draw half for the survivors Core handed over (pool order): c = `row[|kind|][age]` (k <
    /// 0x100) or `|kind| − 0x100` (low byte); a negative kind with prefs+6 ≠ 3 draws `ambient[c]`; the blend arms are
    /// dead (`+0x1c` is always 0); `+0x1d = .WrapDrawParticle(c, shape, (v, h))`.
    public mutating func draw(_ list: [ParticleDraw], scroll: (h: Int, v: Int), ports: inout FramePorts) {
        drawn = []
        for p in list {
            let k = p.kind < 0 ? 0 &- p.kind : p.kind
            var c: UInt8 = 0
            if p.age < ParticleLife.ageLimit, 0 < p.age {
                if k < 0x100 {
                    if k >= 0 { c = rows[Int(k)][Int(p.age)] }
                } else {
                    c = UInt8(truncatingIfNeeded: Int(k) - 0x100)
                }
            }
            guard c != 0 else {
                rowDisagreements += 1
                continue
            }
            let colour = p.kind < 0 && effects != 3 ? ambient[Int(c)] : c
            let erase = Self.wrapDrawParticle(colour, shape: p.shape, v: p.v, h: p.h, scroll: scroll, ports: &ports)
            drawn.append((p.shape, p.v, p.h, erase))
        }
    }

    /// `.EraseParticles`: each record the last draw handed over, by its `+0x1d`: 1 → `FUN_10015fb8` (the footprint from
    /// the tile port, mask back to 0xff), 2 → `FUN_10016440` (the pixels only; shape 3 the whole 4×4 square).
    public mutating func erase(scroll: (h: Int, v: Int), ports: inout FramePorts) {
        for d in drawn where d.erase == 1 || d.erase == 2 {
            guard let (x, y) = Self.ring(shape: d.shape, v: d.v, h: d.h, scroll: scroll, reject: false) else { continue }
            let w = FramePorts.width
            func restore(_ dx: Int, _ dy: Int) {
                let o = (y + dy) * w + x + dx
                ports.frame[o] = ports.tiles[o]
                if d.erase == 1 { ports.mask[o] = 0xff }
            }
            let cells = d.erase == 2 && d.shape == 3
                ? (0..<4).flatMap { dy in (0..<4).map { (dx: $0, dy: dy) } } : Self.footprint(d.shape)
            for c in cells { restore(c.dx, c.dy) }
        }
    }

    /// The pixels of shape 1…7 relative to the ring point (§3.2); none for 0 or > 7.
    static func footprint(_ shape: Int16) -> [(dx: Int, dy: Int)] {
        func box(_ w: Int, _ h: Int) -> [(dx: Int, dy: Int)] { (0..<h).flatMap { dy in (0..<w).map { (dx: $0, dy: dy) } } }
        switch shape {
        case 1: return box(1, 1)
        case 2: return box(2, 2)
        case 3: return [(1, 0), (2, 0)] + box(4, 2).map { (dx: $0.dx, dy: $0.dy + 1) } + [(1, 3), (2, 3)]
        case 4: return box(1, 2)
        case 5: return box(2, 4)
        case 6: return box(4, 1)
        case 7: return box(2, 1)
        default: return []
        }
    }

    /// The mask bytes a shape tests (§3.2): its footprint, except shape 3 (all 16 of the 4×4 square, raw
    /// `10015e48..`) and shape 1 (one byte, never "mixed").
    static func tested(_ shape: Int16) -> [(dx: Int, dy: Int)] {
        shape == 3 ? (0..<4).flatMap { dy in (0..<4).map { (dx: $0, dy: dy) } } : footprint(shape)
    }

    /// `.WrapDrawParticle`'s / the erases' view test, clamp and ring wrap (raw `10015968..10015a8c`): nil when the
    /// point is off the view (h + 2 < H, v + 2 < V, h > H + 0x260, v > V + 0x180) or — `reject` — off the ring's
    /// usable part (x 0…0x27e, y 0…0x19e; 0x27c / 0x19c for shapes 3, 5, 6).
    static func ring(shape: Int16, v: Int16, h: Int16, scroll: (h: Int, v: Int), reject: Bool) -> (x: Int, y: Int)? {
        let H = Int(Int16(truncatingIfNeeded: scroll.h)), V = Int(Int16(truncatingIfNeeded: scroll.v))
        var x = Int(h), y = Int(v)
        guard H <= x + 2, V <= y + 2, x <= H + 0x260, y <= V + 0x180 else { return nil }
        if x < H { x = H }
        if y < V { y = V }
        x = Int(Int16(truncatingIfNeeded: x % 0x280))                    // truncating remainders (`mulhw`)
        y = Int(Int16(truncatingIfNeeded: y % 0x1a0))
        if reject {
            let wide = shape == 3 || shape == 5 || shape == 6
            guard 0 <= x, 0 <= y, x <= (wide ? 0x27c : 0x27e), y <= (wide ? 0x19c : 0x19e) else { return nil }
        }
        return (x, y)
    }

    /// `.WrapDrawParticle(c, shape, (v, h)) @ 10015948`: off the view → returns c unchanged (`blt/bgt 0x10015f88`, r3
    /// untouched); off the ring → 0; shape 0 or > 7 → c (no case); else the mask rule — every tested mask byte 0xff →
    /// draw, clear the drawn pixels' mask bytes, 1; every byte 0 → draw, 2; mixed → 0 (shape 1: 0xff → 1, else 2).
    static func wrapDrawParticle(_ c: UInt8, shape: Int16, v: Int16, h: Int16, scroll: (h: Int, v: Int),
                                 ports: inout FramePorts) -> UInt8 {
        guard ring(shape: shape, v: v, h: h, scroll: scroll, reject: false) != nil else { return c }
        guard let (x, y) = ring(shape: shape, v: v, h: h, scroll: scroll, reject: true) else { return 0 }
        guard (1...7).contains(shape) else { return c }
        let w = FramePorts.width
        let masks = tested(shape).map { ports.mask[(y + $0.dy) * w + x + $0.dx] }
        let mode: UInt8
        if shape == 1 {
            mode = masks[0] == 0xff ? 1 : 2
        } else if masks.allSatisfy({ $0 == 0xff }) {
            mode = 1
        } else if masks.allSatisfy({ $0 == 0 }) {
            mode = 2
        } else {
            return 0
        }
        for d in footprint(shape) {
            let o = (y + d.dy) * w + x + d.dx
            ports.frame[o] = c
            if mode == 1 { ports.mask[o] = 0 }
        }
        return mode
    }
}
