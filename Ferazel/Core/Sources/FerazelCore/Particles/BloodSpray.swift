import Foundation

/// `.BloodSpray(victim, attacker, count, speed, spread, kind) @ 100425f8` (decompile l. 37892–37958, raw
/// `100425f8..10042850`; particles §5.3). `.HurtPlayer`'s call (`bl` at `100549f4`, l. 48051) is
/// `.BloodSpray(player, attacker, 0x28, 500, 0x96, 2)`.
///
/// 1. Both hot rects `+0x34` offset by (`+0xc`, `+0xa`) are intersected (`.SectRectFast` = `SectRect`); empty → nothing.
/// 2. The start point = the overlap's centre: v = top + ((bottom − top) >> 1), h = left + ((right − left) >> 1)
///    (16-bit; raw `100426d4..100426f0`, `10042680..100426b8`).
/// 3. dir = `.FindDesiredDirectionGeneric(victim +0xe, attacker centre)` (`direction`); `FUN_100417bc(dir, speed)`
///    (`vector`) gives (x, y) as f32; both negated and truncated (`fneg`, `fctiwz`, raw `10042738..1004275c`).
/// 4. For i in 0 ..< count: delay = i >> 3 (count ≤ 0x96), i >> 4 (≤ 0x12c), else i >> 5; the point moves halfway to
///    the victim's centre: h = `(short)(h + +0x10) >> 1`, v = `(short)(v + +0xe) >> 1`; vy = (int)(−y) + R(spread) −
///    (spread >> 1) (drawn first), vx = (int)(−x) + R(spread) − (spread >> 1);
///    `NewParticle(kind, 0xbe, (v, h), 4, vx, vy, delay, 1)`.
public enum BloodSpray {
    public static func spray(_ w: SpriteWorld, victim vID: Int, attacker aID: Int, count: Int16, speed: Int16,
                             spread: Int16, kind: Int16) {
        guard let v = w.active.record(id: vID), let a = w.active.record(id: aID) else { return }
        func world(_ s: SpriteSlot) -> IdleSprites.Rect {
            let x = Int(Int16(truncatingIfNeeded: s.x)), y = Int(Int16(truncatingIfNeeded: s.y))
            return IdleSprites.Rect(top: s.hotRect.top + y, left: s.hotRect.left + x, bottom: s.hotRect.bottom + y,
                                    right: s.hotRect.right + x)
        }
        let r1 = world(v), r2 = world(a)
        let top = max(r1.top, r2.top), left = max(r1.left, r2.left)
        let bottom = min(r1.bottom, r2.bottom), right = min(r1.right, r2.right)
        guard top < bottom, left < right else { return }
        func h16(_ x: Int) -> Int16 { Int16(truncatingIfNeeded: x) }
        var pv = h16(top + ((bottom - top) >> 1))
        var ph = h16(left + ((right - left) >> 1))
        let victim = (v: h16(v.centre.y), h: h16(v.centre.x))
        let attacker = (v: h16(a.centre.y), h: h16(a.centre.x))
        let dir = direction(target: victim, from: attacker)
        let vec = vector(dir, magnitude: Float(speed))
        let nx = Int32((-vec.x).rounded(.towardZero)), ny = Int32((-vec.y).rounded(.towardZero))
        let half = Int32(spread >> 1)
        var i: Int16 = 0
        while i < count {
            let delay: Int16 = count <= 0x96 ? i >> 3 : (count <= 0x12c ? i >> 4 : i >> 5)
            ph = (ph &+ victim.h) >> 1
            pv = (pv &+ victim.v) >> 1
            let vy = ny &+ Int32(w.rng.next(spread)) &- half
            let vx = nx &+ Int32(w.rng.next(spread)) &- half
            w.particles.newParticle(kind: Int(kind), gravity: 0xbe, v: Int(pv), h: Int(ph), shape: 4, vx: Int(vx),
                                    vy: Int(vy), delay: Int(delay), mode: 1)
            i += 1
        }
    }

    /// `.FindDesiredDirectionGeneric(p1, p2) @ 10042038` (l. 37688–37800): the 10° sector index 0…35 (0 left, 9 down,
    /// 18 right, 27 up) of the vector p2 → p1… as read: p2.h == p1.h → p2.h + 1, p2.v == p1.v → p2.v + 1; dy = p1.v −
    /// p2.v, dx = p2.h − p1.h as f32; t = (double)(dy / dx) (f32 divide); then by the signs of dy (≤ 0 / > 0) and dx
    /// the thresholds tan 5°…85° (doubles `100a1800..100a1880`, the 45° pair f32 `100a1820`/`100a1948`, widened).
    static func direction(target p1: (v: Int16, h: Int16), from p2: (v: Int16, h: Int16)) -> Int {
        var h2 = p2.h, v2 = p2.v
        if h2 == p1.h { h2 &+= 1 }
        if v2 == p1.v { v2 &+= 1 }
        let dy = Float(Int32(p1.v) - Int32(v2))
        let dx = Float(Int32(h2) - Int32(p1.h))
        let t = Double(dy / dx)
        // `100a1840`, `1838`, `1830`, `1828`, (f32) `1820`, `1818`, `1810`, `1808`, `1800`.
        let neg = ([UInt64]([0xc026_dc28_f5c2_8f5c, 0xc00d_db22_d0e5_6042, 0xc001_27ef_9db2_2d0e, 0xbff6_d97f_62b6_ae7d,
                             0, 0xbfe6_6809_d495_182b, 0xbfdd_d7db_f487_fcb9, 0xbfd1_2546_0aa6_4c30,
                             0xbfb6_6666_6666_6666])).map { Double(bitPattern: $0) }
        let negTable = neg.enumerated().map { $0.offset == 4 ? Double(Float(bitPattern: 0xbf80_0000)) : $0.element }
        // `100a1880`, `1878`, `1870`, `1868`, (f32) `1948`, `1860`, `1858`, `1850`, `1848`.
        let pos = ([UInt64]([0x3fb6_6666_6666_6666, 0x3fd1_1eb8_51eb_851f, 0x3fdd_d7db_f487_fcb9, 0x3fe6_6809_d495_182b,
                             0, 0x3ff6_d97f_62b6_ae7d, 0x4001_27ef_9db2_2d0e, 0x400d_db22_d0e5_6042,
                             0x4026_dc28_f5c2_8f5c])).map { Double(bitPattern: $0) }
        let posTable = pos.enumerated().map { $0.offset == 4 ? Double(Float(bitPattern: 0x3f80_0000)) : $0.element }
        func sector(_ table: [Double], base: Int, last: Int) -> Int {
            for (k, c) in table.enumerated() where t < c { return base + k }
            return last
        }
        if dy <= 0 {
            if 0 <= dx { return sector(negTable, base: 0x1b, last: 0) }
            return sector(posTable, base: 0x12, last: 0x1b)
        }
        if dx <= 0 { return sector(negTable, base: 9, last: 0x12) }
        return sector(posTable, base: 0, last: 9)
    }

    /// `FUN_100417bc(dir, m, &x, &y) @ 100417bc` (l. 37417–37580, raw `100417bc..`): x = y = 0 (`lfs 100a1888`), then
    /// by dir the f32 vector of length m in 10° steps — each component `frsp(fmadd/fnmsub(c, m, 0))` with the doubles
    /// c = sin/cos `100a1890..100a18c8` (0.643, 0.766, 0.5, 0.866, 0.342, 0.94, 0.174, 0.985); dir 0 → x = −m, 9 → y = m,
    /// 18 → x = m, 27 → y = −m; dir > 35 → (0, 0).
    static func vector(_ dir: Int, magnitude m: Float) -> (x: Float, y: Float) {
        // sin(10k°) for k = 0…8 as stored: 0, `100a18c0`, `18b0`, `18a0`, `1890`, `1898`, `18a8`, `18b8`, `18c8`;
        // cos(10k°) = sin(10(9 − k)°).
        let sin = ([UInt64]([0, 0x3fc6_45a1_cac0_8312, 0x3fd5_e353_f7ce_d917, 0x3fe0_0000_0000_0000,
                             0x3fe4_9374_bc6a_7efa, 0x3fe8_8312_6e97_8d50, 0x3feb_b645_a1ca_c083,
                             0x3fee_147a_e147_ae14, 0x3fef_851e_b851_eb85])).map { Double(bitPattern: $0) }
        let md = Double(m)
        func p(_ k: Int) -> Float { Float(sin[k] * md + 0) }             // `fmadd c, m, 0; frsp`
        func n(_ k: Int) -> Float { Float(-(sin[k] * md - 0)) }          // `fnmsub c, m, 0; frsp`
        switch dir {
        case 0: return (0 - m, 0)                                        // `fsubs`
        case 1...8: return (n(9 - dir), p(dir))
        case 9: return (0, 0 + m)                                        // `fadds`
        case 10...17: return (p(dir - 9), p(18 - dir))
        case 18: return (0 + m, 0)
        case 19...26: return (p(27 - dir), n(dir - 18))
        case 27: return (0, 0 - m)
        case 28...35: return (n(dir - 27), n(36 - dir))
        default: return (0, 0)
        }
    }
}
