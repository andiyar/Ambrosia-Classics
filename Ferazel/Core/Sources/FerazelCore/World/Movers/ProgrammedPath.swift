import Foundation

/// The programmed path (physics §8.5): `.SetupProgrammedPath @ 10044c58` (M l. 39288–39381) and `.HandleProgrammedPath
/// @ 10044fe8` (M l. 39384–39468). Modes 1 (vertical) and 2 (horizontal) shuttle between two 24.8 bounds; 3 is stores
/// only (its Handle has no arm); 10 / 11 swing on a radial (`makeRadial`, the world `handle`). One home for every caller
/// (audit ruling 3): the path bats (BA), and later the Background p1 < 0 and mace modes 1–2 (M l. 62072, 62343, 62976,
/// 63143) and the Gremlin (M l. 69226, 69307). No Bat places 10 / 11 today: `SetupFaces` refuses them.
public enum ProgrammedPath {
    /// `.SetupProgrammedPath(s, −1, 0)` (M l. 39288–39381) — `record` the live record of `+0x48` (nil = −1): mode
    /// `+0xf0` = |p1| (100…199 → − 100, which also zeroes the radial speed — `makeRadial`), `+0xfc` = p3; `+0xf8 = 1`;
    /// then mode 3: rect (7, 0, 0x46, 0x1e), `+0x19e = 0x50`, gravity 0x15e, `+0x13a = 0x2d`, `+0x138 = 0x3c`, `+0xf8 =
    /// 0`; mode 1: (with a record) `+0x100 = +0x1c + 8·p3`, `+0x104 = +0x1c + 256·p2 − 8·p3`, vy = `+0xfc`, vx = 0,
    /// `+0x13a = 0`; mode 2:
    /// the same on `+0x14`, vx = `+0xfc`, vy = 0; modes 10 / 11 (with a record): `+0xf8 = 0`, then `.MakeRadial` —
    /// `makeRadial`, which the caller runs after the insert.
    public static func setup(_ s: inout SpriteSlot, record p: Placement?) {
        if let p {
            s.pathMode = Int32(p.p1 < 1 ? -p.p1 : p.p1)
            if 99 < s.pathMode && s.pathMode < 200 { s.pathMode -= 100 }
            s.pathSpeed = Int32(p.p3)
        }
        s.pathDirection = 1
        let mode = s.pathMode
        if mode == 3 {
            s.hotRect = IdleSprites.Rect(top: 0, left: 7, bottom: 0x1e, right: 0x46)
            s.buoyancy = 0x50
            s.gravity = 0x15e
            s.sag = 0x2d
            s.pushMass = 0x3c
            s.pathDirection = 0
        } else if mode < 3 {
            if mode == 1 {
                if let p {
                    s.pathLow = s.y256 &+ s.pathSpeed &* 8
                    s.pathHigh = s.y256 &+ Int32(p.p2) &* 0x100 &+ s.pathSpeed &* -8
                }
                s.vy = s.pathSpeed
                s.vx = 0
                s.sag = 0
            } else if 0 < mode {
                if let p {
                    s.pathLow = s.x256 &+ s.pathSpeed &* 8
                    s.pathHigh = s.x256 &+ Int32(p.p2) &* 0x100 &+ s.pathSpeed &* -8
                }
                s.vx = s.pathSpeed
                s.vy = 0
            }
        } else if mode < 0xc && 9 < mode && p != nil {
            s.pathDirection = 0
        }
    }

    /// `.HandleProgrammedPath(s)` (M l. 39384–39468): mode 2 — direction 1: past `+0x104` (`+0x104 < +0x14`) → −1, else
    /// vx + `+0xfc >> 4` while below `+0xfc`, capped at `+0xfc`; direction ≠ 1: before `+0x100` → 1, else vx − `+0xfc
    /// >> 4` while above −`+0xfc`, floored at −`+0xfc`; then `+0x194 = 0`. Mode 1 the same on `+0x1c` / vy. Modes 10 /
    /// 11 (M l. 39448–39459): `+0xf8` < 0 → + 1, else 0; vy = vx = 0; `+0x194 = 0` — the radial step between them is
    /// the world `handle`'s. Any other mode: nothing.
    public static func handle(_ s: inout SpriteSlot) {
        let mode = s.pathMode
        func run(_ pos: Int32, _ v: inout Int32) {
            if s.pathDirection == 1 {
                if s.pathHigh < pos {
                    s.pathDirection = -1
                } else {
                    if v < s.pathSpeed { v &+= s.pathSpeed >> 4 }
                    if s.pathSpeed < v { v = s.pathSpeed }
                }
            } else if pos < s.pathLow {
                s.pathDirection = 1
            } else {
                if 0 &- s.pathSpeed < v { v &-= s.pathSpeed >> 4 }
                if v < 0 &- s.pathSpeed { v = 0 &- s.pathSpeed }
            }
            s.jumpBonus = 0
        }
        if mode == 2 {
            var v = s.vx
            run(s.x256, &v)
            s.vx = v
        } else if mode == 1 {
            var v = s.vy
            run(s.y256, &v)
            s.vy = v
        } else if mode == 10 || mode == 11 {
            if s.pathDirection < 0 {
                s.pathDirection &+= 1
            } else {
                s.pathDirection = 0
            }
            s.vy = 0
            s.vx = 0
            s.jumpBonus = 0                                             // after the radial calls in the dump; they never touch it
        }
    }

    /// The Setup's radial tail for modes 10 / 11 with a record (M l. 39354–39378), made by the caller right after
    /// the insert (as `BackgroundSprite.makeRadial`; `setup` has no world): `.MakeRadial(s, +0x10, +0xe, r = p2,
    /// speed = p3 — 0 when |p1| is 100…199, the Setup's `bVar1` cleared (M l. 39310–39313) —, angle = p4, g 0 (mode 10)
    /// / 0x1e (11), damp 0, hub damp 0, persp 0)`. `.MakeRadiusSprites` is left out: it runs only when the Setup's
    /// second argument ≠ −1, and every caller passes −1. Any other mode, or no record (`+0x48 == −1`): nothing.
    public static func makeRadial(_ w: SpriteWorld, id: Int, record p: Placement?) {
        guard let p, let s = w.active.record(id: id), s.pathMode == 10 || s.pathMode == 11 else { return }
        let raw = p.p1 < 1 ? 0 &- p.p1 : p.p1
        let full = !(99 < raw && raw < 200)
        RadialMotion.make(w, id: id, cx: Int16(truncatingIfNeeded: s.centre.x), cy: Int16(truncatingIfNeeded: s.centre.y),
                          radius: p.p2, speed: full ? p.p3 : 0, angle: p.p4, gravity: s.pathMode == 10 ? 0 : 0x1e,
                          damp: 0, hubDamp: 0, persp: 0)
    }

    /// `.HandleProgrammedPath(s)` on the sprite `id` of `w`, `s` its working copy (the caller's, written back here
    /// and re-read when the radial step runs): `handle(&s)`, then for modes 10 / 11 `.UpdateRadialPos(s)` and
    /// `.UpdateRadiusSprites(s, 0, 0)` (M l. 39457–39458; `RadialMotion`, no-ops without a block).
    public static func handle(_ w: SpriteWorld, id: Int, slot s: inout SpriteSlot) {
        handle(&s)
        guard s.pathMode == 10 || s.pathMode == 11 else { return }
        w.active.update(id: id) { [s] in $0 = s }
        RadialMotion.updatePosition(w, id: id)
        RadialMotion.updateSpokes(w, id: id, slopeMode: false, base: 0)
        if let t = w.active.record(id: id) { s = t }
    }
}
