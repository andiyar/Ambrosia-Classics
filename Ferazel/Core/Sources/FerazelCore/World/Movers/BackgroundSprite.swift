import Foundation

/// The Background class (`PTR_PTR_100a0480` = `.HandleBackgroundSprite`; triggers-background §2.2, §2.5, §2.11), part 1
/// (W2a): the radial bars and balls 1480–1489 (0x5c8…0x5d1) with their mace chains, and the Handle's per-frame re-face
/// from the class caches (plants 0xa8c…, tunnels 3000…). // later: W2b — cannons 0x442…, springs 0x47e…0x481, fire
/// 0x4b8 / 0x4bb…0x4bd, 0x730…0x733, 0x73f / 0x740, 0x76c…0x76f, 0xb4a…0xb4d, passages 0xb54 / 0xb55, 0xbf4, trees
/// 0xc08…0xc0f.
public enum BackgroundSprite {
    /// The radial bars (0x5c8…0x5cc) and balls (0x5cd…0x5d1).
    public static let maces: ClosedRange<Int16> = 0x5c8...0x5d1
    /// The first ball type: below it the Handle forces the centre and the Setup's rect is the bar's.
    public static let firstBall: Int16 = 0x5cd
    /// `.MTChangeSpriteLayer(s, 0x7ef4)` in front of everything / `(s, −300)` behind (raw `100743a4..100743bc`).
    public static let frontLayer: Int16 = 0x7ef4
    public static let behindLayer: Int16 = -300

    @inline(__always) static func h(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }

    // MARK: - Setup

    /// `.SetupBackgroundSprite @ 10071710` (decompile l. 61919–61987, the common head, for every Background type):
    /// `.InitSprite`; `+0x84 = +0x86 = 0` (no reader); layer `+0x80 = 1`; the Handle; hit `+0x5c` and tile `+0x1f8`
    /// callbacks 0 (arms re-set them — // later: W2b); `+0xa6 = 3`; HP `+0xa4 = 6`; `+0x8a = 0` (no water current);
    /// the position from the spawn copy (`SetupFaces`).
    public static func setupCommon(_ s: inout SpriteSlot) {
        s.layer = 1
        s.handler = .background
        s.hasHit = false
        s.hasTileHit = false
        s.counterA6 = 3
        s.hp = 6
        s.currentApplies = false
    }

    /// The 0x5c8…0x5d1 arm of `.SetupBackgroundSprite` (l. 62312–62427) on the record `p` — the part that needs no
    /// list (the radial block and its spokes are `makeRadial`, after the insert). Returns the record as the Setup
    /// leaves it (written back):
    /// - `+0x5c`, `+0x1f8` 0; rect `SetRect(0x12, 0x2c, 0x6e, 0x44)` below 0x5cd, else `(0x16, 0x16, 0x4e, 0x4e)`;
    ///   the class-cache face (`+0xc0 = PTR_DAT_100a09f4[type − 0x5c8] + 4`, flagged for `.LoadCachedSpriteFaces`).
    /// - mode `+0xb0` = p1, 0 → 0xb; **p2 0 → 0x8c and p3 0 → 0x1e written back to the record**.
    /// - modes 1, 2: the programmed path (`SetupFaces` refuses them — // later: no level 1–2 placement).
    /// - modes 10…14: `+0x188 = 1` (the record write-back flag; Core has no write-back — // later: Phase 3),
    ///   one-way `+0x185 = 1`; with a record (`+0x48 ≠ −1`): persp = 1 for modes 12, 13, 2 for 14, else 0; persp ≠ 0
    ///   clears `+0x88`; `+0xa6 = 0`, `+0x1f8 = 0`.
    public static func setupMace(_ s: inout SpriteSlot, record p: Placement) -> Placement {
        s.hasHit = false
        s.hasTileHit = false
        if s.type < firstBall {
            s.hotRect = IdleSprites.Rect(top: 0x2c, left: 0x12, bottom: 0x44, right: 0x6e)
        } else {
            s.hotRect = IdleSprites.Rect(top: 0x16, left: 0x16, bottom: 0x4e, right: 0x4e)
        }
        s.subtype = p.p1 == 0 ? 0xb : p.p1
        let rec = Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: p.p1,
                            p2: p.p2 == 0 ? 0x8c : p.p2, p3: p.p3 == 0 ? 0x1e : p.p3, p4: p.p4, y: p.y, x: p.x)
        let mode = s.subtype
        if 9 < mode && mode < 0xf {
            s.oneWay = true
            if s.recordIndex != -1 {
                if persp(mode: mode) != 0 { s.lightOverlay = false }
                s.counterA6 = 0
                s.hasTileHit = false
            }
        }
        return rec
    }

    /// The Setup's projection for modes 10…14 (`iVar20`, l. 62364–62375): 12, 13 → 1 (x fixed), 14 → 2 (y fixed),
    /// else 0 (plane).
    static func persp(mode: Int16) -> Int16 {
        if mode == 0xc || mode == 0xd { return 1 }
        if mode == 0xe { return 2 }
        return 0
    }

    /// The radial part of the 0x5c8…0x5d1 Setup (l. 62376–62425) for the sprite `id` from its written-back record
    /// `rec` — modes 10…14 with a record only; a no-op for any other sprite:
    /// - modes 10, 13, 14: `.MakeRadial(s, x + 0x32, y + 0x32, r = p2, speed = p3, angle = p4, g 0, damp 0, hub damp 0,
    ///   persp)`; 11, 12: `(…, r = p2, speed 0, angle = p4, g = p3, 0, 0, persp)`;
    /// - `.MakeRadiusSprites(s, p2 / 16 (C division), layer 0, 0x59a (0x59c for mode 14), size 0x18,
    ///   .SetupChainSprite)` — the same call for every persp (the persp-0 arm's type ≥ 0x735 alternative, p2 / 20, is
    ///   unreachable from 0x5c8…0x5d1).
    ///
    /// The original makes the spokes inside the Setup, before `.MTNewSprite` inserts the ball (layer 1); Core makes
    /// them right after the insert. The list is the same: the spokes (layer 0) go in front of the first sprite of a
    /// greater layer either way (`ActiveList` insert rule), and the ball is never before them.
    public static func makeRadial(_ w: SpriteWorld, id: Int, record rec: Placement) {
        guard let s = w.active.record(id: id), maces.contains(s.type), s.recordIndex != -1 else { return }
        let mode = s.subtype
        guard 9 < mode && mode < 0xf else { return }
        let pp = persp(mode: mode)
        let cx = Int16(truncatingIfNeeded: s.x + 0x32), cy = Int16(truncatingIfNeeded: s.y + 0x32)
        if mode == 10 || mode == 0xd || mode == 0xe {
            RadialMotion.make(w, id: id, cx: cx, cy: cy, radius: rec.p2, speed: rec.p3, angle: rec.p4, gravity: 0,
                              damp: 0, hubDamp: 0, persp: pp)
        } else {
            RadialMotion.make(w, id: id, cx: cx, cy: cy, radius: rec.p2, speed: 0, angle: rec.p4, gravity: rec.p3,
                              damp: 0, hubDamp: 0, persp: pp)
        }
        let type = mode == 0xe ? ChainSprite.maceChain2 : ChainSprite.maceChain
        RadialMotion.makeSpokes(w, id: id, count: rec.p2 / 16, layer: 0, type: type, size: 0x18, handler: .chain,
                                setup: ChainSprite.setup)
    }

    // MARK: - Handle

    /// The types whose `.HandleBackgroundSprite` arm is W2b's: their Handle is not run yet (as before W2a), so
    /// nothing of it — `.StandardSpriteHandles` included — changes them. // later: W2b.
    static func isW2bArm(_ t: Int16) -> Bool {
        (0x442...0x44b).contains(t) || (0x47e...0x481).contains(t) || t == 0x4b8 || (0x4bb...0x4bd).contains(t)
            || (0x730...0x733).contains(t) || (0x73f...0x740).contains(t) || (0x76c...0x76f).contains(t)
            || (0xb4a...0xb4d).contains(t) || t == 0xb54 || t == 0xb55 || t == 0xbf4 || (0xc08...0xc0f).contains(t)
    }

    /// Modes 12…14's layer and harmful flag from the depth D (radial `+0x40`; l. 63167–63180, raw
    /// `100743a4..100743bc`): D < 0x80 → layer 0x7ef4 (in front) and harmful, except mode 12 (the pendulum) while
    /// D < 0x60; D ≥ 0x80 → layer −300 (behind), harmless. So a pendulum hurts **iff 0x60 ≤ D < 0x80**.
    public static func depthBand(mode: Int16, depth d: Int16) -> (layer: Int16, harmful: Bool) {
        if d < 0x80 { return (frontLayer, !(mode == 0xc && d < 0x60)) }
        return (behindLayer, false)
    }

    /// `.HandleBackgroundSprite @ 10073afc` (decompile l. 62887–63560) as far as W2a builds it: `+0xe9` / `+0x1b2` →
    /// return; `.StandardSpriteHandles`; the type arm; `.StandardSpriteCleanup` (`LAB_10074e14`).
    /// - 0x5c8…0x5d1 (l. 63136–63186): **the face re-set every frame** from the class cache (`+0xc0 =
    ///   PTR_DAT_100a09f4[type − 0x5c8] + 4`); modes 1, 2 → `.HandleProgrammedPath` + `.ApplyGravityAndSeparate`
    ///   (// later: no level 1–2 placement; the Setup refuses them); modes 10…14: `+0xa6` < 0 counts up, else 0;
    ///   vx = vy = 0; below 0x5cd the centre `+0x10 = +0xc + 0x40`, `+0xe = +0xa + 0x32`; `.UpdateRadialPos`;
    ///   `.UpdateRadiusSprites(s, 0, 0)`; `+0x194 = 0`; modes 10, 11: `+0x170 = 1`, rotation `+0x1aa = (angle >> 8)
    ///   + 90` (− 360 past 359), `+0x88 = 0`, `+0x89 = 1`; modes 12…14: `depthBand` — the layer through
    ///   `.MTChangeSpriteLayer` (the F2 no-op guard), so the frame a ball comes **in front** moves it to the list's
    ///   tail and `.MTHandleSprites` handles it **twice** (Invariant 7).
    /// - The tail for every type no arm takes (l. 63549–63556): plants 0xa8c…0xaef → `+0xc0 = _DAT_100a0ad8[type −
    ///   0xa8c] + 4`, tunnels 3000…0xbc1 → `_DAT_100a0adc[type − 3000] + 4` (the caches hold 30 plants and 6 tunnels:
    ///   a higher type reads past them [LOW: none placed on levels 1–2]). This is what replaces the Phase-1 Setup faces
    ///   of 1485, 2710, 2713, 2714 and 3002 (`SetupFaces` `.setupCached`) from the first Handle frame on.
    public static func handle(world w: SpriteWorld, id: Int, faceWidth: (FaceRef) -> Int) {
        guard let s0 = w.active.record(id: id), !s0.dead, !s0.handleSkip else { return }
        let t = s0.type
        guard !isW2bArm(t) else { return }
        w.standardSpriteHandles(id)
        if maces.contains(t) {
            w.active.update(id: id) { $0.face = FaceRef(pict: t, index: 0, set: .encoded) }
            mace(w, id: id)
        } else if (0xa8c...0xaef).contains(t) || (3000...0xbc1).contains(t) {
            w.active.update(id: id) { $0.face = FaceRef(pict: t, index: 0, set: .encoded) }
        }
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
    }

    /// The 0x5c8…0x5d1 mode arms (l. 63141–63183).
    static func mace(_ w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id) else { return }
        let mode = s.subtype
        if mode < 10 {
            // later: modes 1, 2 (`.HandleProgrammedPath`, `.ApplyGravityAndSeparateFromTiles`) — refused at Setup.
            return
        }
        guard mode < 0xf else { return }
        w.active.update(id: id) { c in
            c.counterA6 = c.counterA6 < 0 ? c.counterA6 + 1 : 0
            c.vy = 0
            c.vx = 0
            if c.type < firstBall {
                c.centre.x = h(c.x + 0x40)
                c.centre.y = h(c.y + 0x32)
            }
        }
        RadialMotion.updatePosition(w, id: id)
        RadialMotion.updateSpokes(w, id: id, slopeMode: false, base: 0)
        w.active.update(id: id) { $0.jumpBonus = 0 }
        if mode == 10 || mode == 0xb {
            w.active.update(id: id) { c in
                c.classWord170 = 1
                var r = Int16(truncatingIfNeeded: UInt32(bitPattern: c.radial?.angle ?? 0) >> 8) &+ 0x5a
                if 0x167 < r { r &-= 0x168 }
                c.rotation = r
                c.lightOverlay = false
                c.dynamicLight = true
            }
        } else {
            let d = w.active.record(id: id)?.radial?.depth ?? 0
            let band = depthBand(mode: mode, depth: d)
            w.changeLayer(id: id, layer: band.layer)
            w.active.update(id: id) { $0.classWord170 = band.harmful ? 1 : 0 }
        }
    }
}
