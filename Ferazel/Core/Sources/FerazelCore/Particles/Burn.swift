import Foundation

/// The burn-away (plan S2 `Burn`, EC; draw-effects §4, particles §5.5): `.HandleBurn @ 10043cd8` (M l. 38765–38840,
/// raw `10043cd8..10043ef0`) and `.BurnFaceRow @ 100437d8` (M l. 38514–38663, raw `100437d8..10043aac`), called from
/// `.StandardSpriteCleanup` while `+0x1a2 ≠ 0`. Nothing is erased pixel by pixel: the face is clipped from the top
/// (`+0x1bc`, drawn by `SpriteBlitter`) and each consumed row sparks particles.
///
/// Core has no face records: the opaque top / bottom (face `+8` / `+0xc`), the width (`+6`) and the token stream come
/// from `SpriteWorld.particleFaces` (FerazelRender's). In the dump `+0xc0 ≠ 0` always has its face record (top,
/// bottom), so the burn always advances to the Kill; a face Core cannot see (a headless session, no provider — the
/// Mac and Windows shells always pass the renderer's) is a no-op: no sound, no draw, no state (EC fix round).
/// prefs+6 (Effects, `_DAT_1009fe44 + 6`) is the iteration's live prefs (`SpriteWorld.voices.prefs`).
public enum Burn {
    /// `*PTR_DAT_100a01ec` = snd 462 (`SoundSlots`).
    public static let sound: Int16 = 462

    /// `.HandleBurn(s)` on the Cleanup's copy `s` (written back by the caller), in order:
    /// 1. no face (`+0xc0 == 0`) → nothing; else `+0x1b3 = 1`;
    /// 2. `+0x1a2 == 1` with the hot rect's width ≥ 0x10 or left ≠ right: `+0x8c == 0` → `.STPlay3DSoundRand(462, 1,
    ///    0xab, +0xe)` (its `FastRand(10000)` at the call); else `FastRand(15000)` → `.STPlay3DSoundPitched(462, 1, 0x41,
    ///    +0xe, R + 110000)`;
    /// 3. `0 < +0x1a2 <` the opaque top → `+0x1a2` = the opaque top;
    /// 4. `+0x8d + 1` times: kind = `+0x8e` ? 0xd : 1; `+0x1a2 += 1` — below 0 → return (a delay), 0 → `+0x1a2 = 1`
    ///    and return; `.BurnFaceRow(face, (+0xa, +0xc), 2, +0x1a2, +0x17e, kind)`; Effects == 1 → `FastRand(100)` > 50
    ///    with `+0x8d == 0` → again with spacing 1; `+0x1bc = +0x1a2`;
    /// 5. `+0x1a2 >` the opaque bottom → (type 0x780: +1 then −1, no change) the Kill proc `+0x50`, or `+0xe9 = 1`
    ///    without one (`EnemyCommon.killProc`, by id: the copy is written back before it and re-read after).
    public static func handle(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        guard let f = s.face, let face = w.particleFaces.sprite(f) else { return }
        s.burning = true
        if s.burnRow == 1 {
            let r = s.hotRect
            if 0xf < r.right - r.left || r.left != r.right {
                if !s.burnPitched {
                    w.player.cue(PlayerCue(call: .threeDRand, snd: sound, priority: 1, volume: 0xab, position: s.centre,
                                           rate: w.rng.soundRate()))
                } else {
                    let p = Int32(w.rng.next(15000))
                    w.player.cue(PlayerCue(call: .threeDPitched, snd: sound, priority: 1, volume: 0x41,
                                           position: s.centre, rate: p + 110000))
                }
            }
        }
        let top = face.bounds[0], bottom = face.bounds[2]
        if 0 < s.burnRow && s.burnRow < top { s.burnRow = top }
        let effects = w.voices.prefs.effects
        var k = 0
        while k < Int(s.burnSpeed) + 1 {
            let kind: Int16 = s.burnStyle ? 0xd : 1
            s.burnRow &+= 1
            if s.burnRow < 1 {
                if s.burnRow == 0 { s.burnRow = 1 }
                return
            }
            let v = Int16(truncatingIfNeeded: s.y), h = Int16(truncatingIfNeeded: s.x)
            burnFaceRow(w, face: face, v: v, h: h, spacing: 2, row: s.burnRow, flip: s.mirrored, kind: kind)
            if effects == 1 && 0x32 < w.rng.next(100) && s.burnSpeed == 0 {
                burnFaceRow(w, face: face, v: v, h: h, spacing: 1, row: s.burnRow, flip: s.mirrored, kind: kind)
            }
            s.clip.top = Int(s.burnRow)
            k += 1
        }
        if bottom < s.burnRow {
            // SpriteWorld rule 2: the Kill proc writes the world by id — write the copy back first, re-read after.
            w.active.update(id: s.id) { $0 = s }
            EnemyCommon.killProc(w, id: s.id)
            if let t = w.active.record(id: s.id) { s = t }
        }
    }

    /// `.BurnFaceRow(face, pos, spacing, R, flip, kind)`: walks the RLE tokens (`ParticleFace`) — a row token: the row
    /// counter + 1, v + 1, h = pos.h (+ the frame width `+6` when flipped); a skip: h ± n; only the literal runs of
    /// token row R are visited (the pixel values are never read). Per pixel, with one counter c for the whole call
    /// (starting 0): c > 0 → c − 1; else spawn and c = spacing − 1: R(4) (v offset), R(12) (delay 2 − R12), R(100) →
    /// shape > 86 → 5, > 25 → 2, > 12 → 4, > 0 → 1, 0 → the last shape of this call (the register `r28`, entering as
    /// `kind`, raw `10043924..1004392c`), R(150), R(50), R(25) → `NewParticle(kind, 0x14 − R25, (v + R4, h), shape,
    /// R50 − 0x19, −500 − R150, 2 − R12, 0)`; then R(5) == 1 → a = R(200) + 250 (negated when R(100) > 50), R(250),
    /// R(25) → `NewParticle(4, 0x14 − R25, (v + R4, h), 2, a, −300 − R250, 2 − R12, 0)`. h ± 1 per pixel.
    static func burnFaceRow(_ w: SpriteWorld, face f: ParticleFace, v: Int16, h: Int16, spacing: Int16, row R: Int16,
                            flip: Bool, kind: Int16) {
        var rowCount = 0
        var y = v
        var x = Int(h)
        var c: Int16 = 0
        var shape = Int(kind)
        var p = 0
        while let t = f.word(p) {
            p += 4
            let op = t >> 24, n = Int(t & 0xff_ffff)
            switch op {
            case 0:
                return
            case 1:
                rowCount += 1
                x = Int(h) + (flip ? Int(f.frame[3]) : 0)
                y &+= 1
            case 2:
                if rowCount == Int(R) {
                    for _ in 0..<n {
                        if 0 < c {
                            c -= 1
                        } else {
                            let dv = w.rng.next(4)
                            let pv = Int(y &+ dv), ph = Int(Int16(truncatingIfNeeded: x))
                            let r12 = Int(w.rng.next(0xc))
                            let r100 = w.rng.next(100)
                            if 0x56 < r100 { shape = 5 }
                            else if 0x19 < r100 { shape = 2 }
                            else if 0xc < r100 { shape = 4 }
                            else if 0 < r100 { shape = 1 }
                            let r150 = Int(w.rng.next(0x96))
                            let r50 = Int(w.rng.next(0x32))
                            let r25 = Int(w.rng.next(0x19))
                            w.particles.newParticle(kind: Int(kind), gravity: 0x14 - r25, v: pv, h: ph, shape: shape,
                                                    vx: r50 - 0x19, vy: -500 - r150, delay: 2 - r12, mode: 0)
                            if w.rng.next(5) == 1 {
                                var a = Int(w.rng.next(200)) + 0xfa
                                if 0x32 < w.rng.next(100) { a = -a }
                                let r250 = Int(w.rng.next(0xfa))
                                let r25b = Int(w.rng.next(0x19))
                                w.particles.newParticle(kind: 4, gravity: 0x14 - r25b, v: pv, h: ph, shape: 2, vx: a,
                                                        vy: -300 - r250, delay: 2 - r12, mode: 0)
                            }
                            c = spacing &- 1
                        }
                        x += flip ? -1 : 1
                    }
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
