import Foundation

/// The Background class (`PTR_PTR_100a0480` = `.HandleBackgroundSprite`; triggers-background §2.2, §2.5, §2.11), part 1
/// (W2a): the radial bars and balls 1480–1489 (0x5c8…0x5d1) with their mace chains, and the Handle's per-frame re-face
/// from the class caches (plants 0xa8c…, tunnels 3000…). Part 2 (W2b, below): cannons 0x442… (p1 0) and their
/// captives (`.TurnIntoCannoned`, `.HandleCannonedSprite`), springs 0x47e…0x481 (`.SuperSpring`), the wall tunnels'
/// occluder window, passages 0xb54 / 0xb55 (the Handle's face; the jump is `HitPlayerSprite`'s), and
/// `.HitBackgroundSprite`. // later: fire 0x4b8 / 0x4bb…0x4bd, 0x730…0x733, 0x73f / 0x740, 0x76c…0x76f,
/// 0xb4a…0xb4d, 0xbf4, trees 0xc08…0xc0f — none placed on levels 1–2.
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

    /// The types whose `.HandleBackgroundSprite` arm is not built: their Handle is not run (as before W2a), so
    /// nothing of it — `.StandardSpriteHandles` included — changes them. // later: fire, spikes, 0x73f / 0x740,
    /// 0x76c…0x76f, clouds, 0xbf4, trees (Phase 3; none placed on levels 1–2, so `SetupFaces` refuses them).
    static func isUnbuiltArm(_ t: Int16) -> Bool {
        t == 0x4b8 || (0x4bb...0x4bd).contains(t) || (0x730...0x733).contains(t) || (0x73f...0x740).contains(t)
            || (0x76c...0x76f).contains(t) || (0xb4a...0xb4d).contains(t) || t == 0xbf4 || (0xc08...0xc0f).contains(t)
    }

    /// Modes 12…14's layer and harmful flag from the depth D (radial `+0x40`; l. 63167–63180, raw
    /// `100743a4..100743bc`): D < 0x80 → layer 0x7ef4 (in front) and harmful, except mode 12 (the pendulum) while
    /// D < 0x60; D ≥ 0x80 → layer −300 (behind), harmless. So a pendulum hurts **iff 0x60 ≤ D < 0x80**.
    public static func depthBand(mode: Int16, depth d: Int16) -> (layer: Int16, harmful: Bool) {
        if d < 0x80 { return (frontLayer, !(mode == 0xc && d < 0x60)) }
        return (behindLayer, false)
    }

    /// `.HandleBackgroundSprite @ 10073afc` (decompile l. 62887–63560) as far as W2a / W2b build it: `+0xe9` / `+0x1b2`
    /// → return; `.StandardSpriteHandles`; the type arm — cannons 0x442…0x44b (`cannon`), springs 0x47e…0x481
    /// (`spring`), passages 0xb54 / 0xb55 (`passage`) and the two below; `.StandardSpriteCleanup` (`LAB_10074e14`).
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
        guard !isUnbuiltArm(t) else { return }
        w.standardSpriteHandles(id)
        if maces.contains(t) {
            w.active.update(id: id) { $0.face = FaceRef(pict: t, index: 0, set: .encoded) }
            mace(w, id: id)
        } else if (0x442...0x44b).contains(t) {
            cannon(w, id: id)
        } else if springs.contains(t) {
            spring(w, id: id)
        } else if passages.contains(t) {
            passage(w, id: id)
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

// MARK: - W2b: cannons, springs, passages, wall tunnels

extension BackgroundSprite {
    /// The cannons the Setup arms (`0x441 < type < 1099`, l. 62057–62058); the Handle's arm is 0x442…0x44b.
    public static let cannons: ClosedRange<Int16> = 0x442...0x44a
    /// The springs with a Setup and Handle arm (0x47e…0x481; 0x482…0x487 have none — triggers-background §2.3).
    public static let springs: ClosedRange<Int16> = 0x47e...0x481
    /// The passages 2900 / 2901.
    public static let passages: ClosedRange<Int16> = 0xb54...0xb55
    /// The wall tunnels 3000…3009 (the arms read `2999 < type < 0xbc2`).
    public static let tunnels: ClosedRange<Int16> = 3000...0xbc1
    /// `.SetupEffectSprite`'s cannon smoke (type 0x442 of the Effect class; triggers-background-2 §2.2).
    public static let smoke: Int16 = 0x442
    /// The smoke's face set (`.InitEffectSprite` l. 53646: `LoadEncFaceSetFromPICT(0x4b0, 13, 48, 48, 13, …)`).
    public static let smokeSheet: Int16 = 0x4b0
    /// The player's tumble set 1015 (`_DAT_100a079c`), faced at a launch.
    static let tumble: Int16 = 1015

    /// The placement record a Background sprite reads (`*(*_DAT_100a0058) + +0x48·0x10`): the game's records, with the
    /// Setups' write-backs (`SpriteWorld.records`); nil for a sprite without one (`+0x48` = −1 reads outside the table in
    /// the original — no Phase-2 sprite does).
    static func record(_ w: SpriteWorld, _ s: SpriteSlot) -> Placement? {
        let i = Int(s.recordIndex)
        guard w.records.indices.contains(i) else { return nil }
        return w.records[i]
    }

    /// `+0x4c == handler`: an idled record (`+0x4c` = 0, `handleCleared`) matches no Handle.
    @inline(__always) static func runs(_ s: SpriteSlot, _ handler: SpriteHandler) -> Bool {
        !s.handleCleared && s.handler == handler
    }

    // MARK: Setup

    /// The cannon arm of `.SetupBackgroundSprite` (l. 62057–62184) for p1 0 (`SetupFaces` refuses the others): aim
    /// `+0x46 = (type − 0x442)·4`; layer 1000; home `+0x14c` = x, `+0x150` = y; `+0x154` 0; p1 ≤ 0: `+0x14/+0x1c` from
    /// `+0xc/+0xa`, (p1 ≠ 0: `.SetupProgrammedPath` — not built), `+8 = +0xc`, `+6 = +0xa`, the aim again; launch speed
    /// `+0x164` = 9000 for p1 0 (`li r0,0x2328 @ 10071c3c`, M l. 62114), else 0x1fa4; hot rect
    /// `SetRect(0x35, 0x38, 0x61, 0x5b)`; the hit callback `.HitBackgroundSprite` (`+0x5c`); `+0x16c` = the BG cell
    /// (x >> 5, y >> 5) is water (`.IsWaterTile` 200…209). The face is the Handle's.
    public static func setupCannon(_ s: inout SpriteSlot, record p: Placement, level L: LevelFile) {
        s.phase = Int16(truncatingIfNeeded: (Int(s.type) - 0x442) * 4)
        s.layer = 1000
        s.classTimer = Int32(Int16(truncatingIfNeeded: s.x))
        s.classWord150 = Int32(Int16(truncatingIfNeeded: s.y))
        s.classWord154 = 0
        s.x256 = Int32(Int16(truncatingIfNeeded: s.x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: s.y)) << 8
        s.oldPosition = SpriteSlot.Point(x: SpriteWorld.pixel(s.x256), y: SpriteWorld.pixel(s.y256))
        s.launchSpeed = p.p1 == 0 ? 9000 : 0x1fa4
        s.hotRect = IdleSprites.Rect(top: 0x38, left: 0x35, bottom: 0x5b, right: 0x61)
        s.hasHit = true
        let k = L.bgKind(tile: L.bgTile(col: Int(Int16(truncatingIfNeeded: s.x)) >> 5,
                                        row: Int(Int16(truncatingIfNeeded: s.y)) >> 5))
        s.classWord16c = (200..<210).contains(k) ? 1 : 0
    }

    /// The spring arms (l. 62046–62054, 62186–62219): the hit callback, `+0x1ba = 32000` (the `.InitSprite` value), hot rect 0x47e
    /// `SetRect(4, 10, 0x38, 0x3c)`, 0x47f `(4, 0, 0x38, 0x32)`, 0x480 `(0, 4, 0x32, 0x2e)`, 0x481 `(10, 4, 0x3c, 0x2e)`;
    /// on a frozen-water level (hdr 0x26cd ≠ 0) `+0xb8 = 0x10018`. The face is the Handle's.
    public static func setupSpring(_ s: inout SpriteSlot, level L: LevelFile) {
        s.hasHit = true
        s.clip.bottom = 32000
        switch s.type {
        case 0x47e: s.hotRect = IdleSprites.Rect(top: 10, left: 4, bottom: 0x3c, right: 0x38)
        case 0x47f: s.hotRect = IdleSprites.Rect(top: 0, left: 4, bottom: 0x32, right: 0x38)
        case 0x480: s.hotRect = IdleSprites.Rect(top: 4, left: 0, bottom: 0x2e, right: 0x32)
        default: s.hotRect = IdleSprites.Rect(top: 4, left: 10, bottom: 0x2e, right: 0x3c)
        }
        if L.header.inLiquid != 0 { s.mode = 0x10018 }
    }

    /// The passage arms (l. 62433–62437 for 0xb54, 62585–62589 for 0xb55): the cached face (`.setupCached`), hot rect
    /// 0xb54 `SetRect(0x20, 0x28, 0x24, 0x57)`, 0xb55 `SetRect(0x2c, 0x28, 0x2e, 100)` (thin thresholds); no hit
    /// callback (the player pass's Background arm does the jump).
    public static func setupPassage(_ s: inout SpriteSlot) {
        if s.type == 0xb54 {
            s.hotRect = IdleSprites.Rect(top: 0x28, left: 0x20, bottom: 0x57, right: 0x24)
        } else {
            s.hotRect = IdleSprites.Rect(top: 0x28, left: 0x2c, bottom: 100, right: 0x2e)
        }
    }

    /// The wall-tunnel tail (l. 62620–62627): hot rect `SetRect(−8, −10, (type − 3000)·0x20 + 0x88, 0x96)`, layer 0,
    /// the cached face, the hit callback `.HitBackgroundSprite`.
    public static func setupTunnel(_ s: inout SpriteSlot) {
        s.hotRect = IdleSprites.Rect(top: -10, left: -8, bottom: 0x96, right: (Int(s.type) - 3000) * 0x20 + 0x88)
        s.layer = 0
        s.hasHit = true
    }

    // MARK: Handle arms

    /// The cannon arm of `.HandleBackgroundSprite` (l. 62944–63069), p1 0 (the only cannons Core sets up):
    /// - `+0x16c` ≠ 0 → `+0x120 = +0x11c = 1` (submerged);
    /// - p1 0: while the pixel position differs from home (`+0xc ≠ +0x14c` or `+0xa ≠ +0x150`): `+0x14 = (int)(0.8·x256
    ///   + 0.2·(home x << 8))` (doubles `100a1b18` 0.8, `100a1b10` 0.2; fctiwz), the same for y, the pixel copies — the
    ///   recoil eases home; // later: p1 1…100 and > 106 (`.HandleProgrammedPath`), 101…106 (rotation, the 485 cue gated
    ///   on the sound playing) — refused at Setup;
    /// - the aim `+0x46` wrapped into 0…31; ≥ 0x12 → mirrored and folded to 0x21 − aim (0 → not mirrored);
    /// - aim mod 4 == 0: k = aim / 4, k ≥ 5 → mirrored, face 8 − k, else not; rotation `+0x1aa` 0, face set 0x442[k],
    ///   `+0xb8` 0; otherwise face 0x442[0], not mirrored, rotation `2·r` with r = ((0x20 − folded)·0xb4 / 16) / 2 (C
    ///   division), − 0xb4 past 0xb3;
    /// - `+0x88 = 0`.
    static func cannon(_ w: SpriteWorld, id: Int) {
        guard let s0 = w.active.record(id: id) else { return }
        let p1 = record(w, s0)?.p1 ?? 0
        if s0.classWord16c != 0 {
            w.active.update(id: id) { c in
                c.lastWater = 1
                c.waterRow = 1
            }
        }
        if p1 == 0 {
            w.active.update(id: id) { c in
                guard c.x != Int(c.classTimer) || c.y != Int(c.classWord150) else { return }
                c.x256 = TileSolver.fctiwz(0.8 * Double(c.x256) + 0.2 * Double(c.classTimer << 8))
                c.y256 = TileSolver.fctiwz(0.8 * Double(c.y256) + 0.2 * Double(c.classWord150 << 8))
                c.x = SpriteWorld.pixel(c.x256)
                c.y = SpriteWorld.pixel(c.y256)
            }
        }
        // later: p1 ≠ 0 — `.HandleProgrammedPath` (1…100, > 106) and the rotating arm (101…106), refused at Setup.
        w.active.update(id: id) { c in
            while c.phase < 0 { c.phase &+= 0x20 }
            while 0x1f < c.phase { c.phase &-= 0x20 }
            var a = c.phase
            if a < 0x12 {
                c.mirrored = false
            } else {
                c.mirrored = true
                a = 0x21 - a
            }
            if a == 0 { c.mirrored = false }
            let aim = Int32(c.phase)
            if aim % 4 == 0 {
                var k = Int16(aim / 4)
                if k < 5 {
                    c.mirrored = false
                } else {
                    c.mirrored = true
                    k = 8 - k
                }
                c.rotation = 0
                c.face = FaceRef(pict: 0x442, index: Int(k), set: .encoded)
                c.mode = 0
            } else {
                let u = Int32(Int16(truncatingIfNeeded: 0x20 - Int32(a))) * 0xb4
                var r = Int16(truncatingIfNeeded: (u / 16) / 2)
                c.face = FaceRef(pict: 0x442, index: 0, set: .encoded)
                c.mirrored = false
                if 0xb3 < r { r -= 0xb4 }
                c.rotation = r << 1
            }
            c.lightOverlay = false
        }
    }

    /// The spring arm (l. 63072–63100): `+0x46` −1, clamped to 0…3; face `+0x46` of 0x47e / 0x47f / 0x480 (0x481: the
    /// 0x480 set, mirrored `+0x17e = 1`). The hit sets 4, so a fired spring shows faces 3, 2, 1, 0 and re-arms at 0.
    static func spring(_ w: SpriteWorld, id: Int) {
        w.active.update(id: id) { c in
            c.phase &-= 1
            if c.phase < 0 { c.phase = 0 }
            if 3 < c.phase { c.phase = 3 }
            let set: Int16 = c.type == 0x481 ? 0x480 : c.type
            c.face = FaceRef(pict: set, index: Int(c.phase), set: .encoded)
            if c.type == 0x481 { c.mirrored = true }
        }
    }

    /// The passage arms (l. 63281–63288, 63532–63535): 0xb54 → the cached face when its record's p3 is 0, else no face
    /// (an invisible passage); 0xb55 → its cached face.
    static func passage(_ w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id) else { return }
        let p3 = record(w, s)?.p3 ?? 0
        w.active.update(id: id) { c in
            if c.type == 0xb54 {
                c.face = p3 == 0 ? FaceRef(pict: 0xb54, index: 0, set: .encoded) : nil
            } else {
                c.face = FaceRef(pict: 0xb55, index: 0, set: .encoded)
            }
        }
    }

    // MARK: `.HitBackgroundSprite`

    /// `.HitBackgroundSprite(bg, other) @ 10075044` (decompile l. 63660–63745), the hit callback of cannons, springs
    /// and wall tunnels (the only Background types that install it, triggers-background §2.1):
    /// - **tunnel** 3000…0xbc1 (l. 63733–63743): an `other` whose Handle is not the Background's gets the occluder
    ///   window `+0x1be = bg.left + (x256 >> 8) + 0x2e`, `+0x1c0 = bg.right + x − 0x2f`, `+0x1c4 = bg.top + y − 0x2c`,
    ///   `+0x1c2 = bg.bottom + y + 0x27` (bg's `+0x34` rect, x/y its 24.8 position) — for 3002 at (x, y): x + 38 …
    ///   x + 153, y − 54 … y + 189. Nothing resets it (`.InitSprite`'s 32000s only).
    /// - **spring** 0x47e…0x487 (l. 63716–63731): a player shot is killed (`.KillPlayerShot(other, 1, 1)`) and an enemy
    ///   shot (`.KillEnemyShot`) — // later: Phase 4 (no shots in Phase 2); then, if other is not itself a Background
    ///   0x47e…0x487, the spring's `+0x46` is 0, other's `+0xe9` is 0 and its Handle is not the Effect's: `+0x46 = 4`,
    ///   `.SuperSpring(bg, other)`.
    /// - **cannon** 0x442…0x44b (l. 63679–63714): other's Handle is none of Background, Statue (`01f8`), Cannoned
    ///   (`045c`), Button (`0ac4`), EnemyShot (`0488`), Effect (`0460`); its type none of 0x41f, 0x434, 0x771, 0x772,
    ///   0xb7c, 0x5c3, 0x5c4; `+0x130 ≥ 0` → (a player shot at a 105 / 106 cannon is steered — // later: Phase 4, and
    ///   those cannons are refused at Setup) `.TurnIntoCannoned(other, bg)`, then bg `+0x154 = 6` (write-only).
    ///   Statue and EnemyShot Handles do not exist in Phase 2 (// later: Phase 4–5); a Button is an `inert` sprite of
    ///   the Button class.
    public static func hit(_ w: SpriteWorld, id: Int, other oID: Int) {
        guard let bg = w.active.record(id: id), let o = w.active.record(id: oID) else { return }
        let t = bg.type
        if tunnels.contains(t) {
            guard !runs(o, .background) else { return }
            let x = SpriteWorld.pixel(bg.x256), y = SpriteWorld.pixel(bg.y256)
            let r = bg.hotRect
            w.active.update(id: oID) { c in
                c.occluder.left = Int16(truncatingIfNeeded: r.left + x + 0x2e)
                c.occluder.right = Int16(truncatingIfNeeded: r.right + x - 0x2f)
                c.occluder.top = Int16(truncatingIfNeeded: r.top + y - 0x2c)
                c.occluder.bottom = Int16(truncatingIfNeeded: r.bottom + y + 0x27)
            }
        } else if (0x47e...0x487).contains(t) {
            // later: Phase 4 — `.KillPlayerShot(other, 1, 1)` / `.KillEnemyShot(other)` (no shots in Phase 2).
            let otherSpring = runs(o, .background) && (0x47e...0x487).contains(o.type)
            guard !otherSpring, bg.phase == 0, !o.dead, !runs(o, .effect) else { return }
            w.active.update(id: id) { $0.phase = 4 }
            superSpring(w, spring: id, hitter: oID)
        } else if (0x442...0x44b).contains(t) {
            // An idled record (`+0x4c` 0, `handleCleared`, listed until `.UpdateSprites`) matches none of the excluded
            // Handles: it is captured like any other, and its saved Handle (0) comes back at the launch.
            if !o.handleCleared {
                switch o.handler {
                case .background, .cannoned, .effect: return
                case .inert:
                    if SpriteClassTable.classify(type: o.type, p1Negative: false)?.0 == .button { return }
                default: break
                }
            }
            guard ![0x41f, 0x434, 0x771, 0x772, 0xb7c, 0x5c3, 0x5c4].contains(o.type), o.reentry >= 0 else { return }
            turnIntoCannoned(w, captive: oID, cannon: id)
            w.active.update(id: id) { $0.classWord154 = 6 }
        }
    }

    /// `.SuperSpring(spring, hitter) @ 10074e60` (decompile l. 63564–63637; physics-sprites §8.3):
    /// - the spring's centre within 300 px horizontally and 200 px vertically of the view centre (`PTR_DAT_1009fe78` +
    ///   (0x130, 0xd0); `|Δ| < 300 ∧ |Δ| < 200`) → `FUN_10091504(493)` (stop) then `.STPlay3DSoundRand(493, 1, 0x100,
    ///   spring +0xe)` with its `FastRand(10000)` drawn here (Invariant 4); farther, no cue and no draw;
    /// - spring `+0x1c2 = 32000` (the occluder edge's `.InitSprite` value: a no-op);
    /// - 0x47e: J `_DAT_100a0678 = 1`, the air counter `_DAT_100a0718 = 2`, hitter vx += 0, vy = −0x2292;
    ///   0x47f: J = 1, vx += 0, vy = 0xa28; 0x480 / 0x481: a hitter with the player's Handle (`PTR_PTR_100a052c`) →
    ///   climb `_DAT_100a0758 = 0`, launched `_DAT_100a05b8 = 1`; vx = ±0x1900, vy = −0xd48; any other: += 0.
    static func superSpring(_ w: SpriteWorld, spring id: Int, hitter oID: Int) {
        guard let k = w.active.record(id: id), let o = w.active.record(id: oID) else { return }
        var dx = w.player.scrollH + 0x130 - Int(Int16(truncatingIfNeeded: k.centre.x))
        if dx < 1 { dx = -dx }
        var dy = w.player.scrollV + 0xd0 - Int(Int16(truncatingIfNeeded: k.centre.y))
        if dy < 1 { dy = -dy }
        if dx < 300 && dy < 200 {
            w.player.cues.append(PlayerCue(call: .stop, snd: 493))                         // `_DAT_100a02f8`
            w.player.cues.append(PlayerCue(call: .threeDRand, snd: 493, priority: 1, volume: 0x100, position: k.centre,
                                           rate: w.rng.soundRate()))
        }
        w.active.update(id: id) { $0.occluder.bottom = 32000 }
        var vx: Int32 = 0, vy: Int32 = 0, setX = false, setY = false
        switch k.type {
        case 0x480, 0x481:
            if runs(o, .player) {
                w.player.climb = 0
                w.player.launched = true
            }
            vx = k.type == 0x480 ? 0x1900 : -0x1900
            vy = -0xd48
            setX = true
            setY = true
        case 0x47e:
            w.player.jumpBase = 1
            w.player.airCounter = 2
            vy = -0x2292
            setY = true
        case 0x47f:
            w.player.jumpBase = 1
            vy = 0xa28
            setY = true
        default:
            break
        }
        w.active.update(id: oID) { c in
            c.vx = setX ? vx : c.vx &+ vx
            c.vy = setY ? vy : c.vy &+ vy
        }
    }

    // MARK: cannon captives

    /// `.TurnIntoCannoned(captive, cannon) @ 10058594` (decompile l. 49930–49974): d = the captive's centre − its
    /// origin (`+0x10 − +0xc`, `+0xe − +0xa`, i16); refused for a dead player (HP `+0xa4` < 1) and a Bonus with
    /// `+0x168 == 1` (// later: Phase 4 — Core has no Bonus Handle nor `+0x168`); else
    /// `.STPlay3DSoundRand(484, 1, 0x97, captive +0xe)` (`_DAT_100a030c`, its rate drawn here), the Handle / hit / tile
    /// callbacks saved to `+0x1ec/+0x1f0/+0x1f4`, `+0x130 = 15`, the Handle `.HandleCannonedSprite`, both callbacks 0,
    /// v = 0, `+0x1e4` = the cannon, the origin = the cannon's centre − d (24.8 from it), the centre = origin + d; a light
    /// `+0x9a ≠ −1` is removed (`light = −1`; // later: Core has no light-removal seam — no capturable Phase-2 sprite
    /// carries a light); the player → launched `_DAT_100a05b8 = 1`.
    public static func turnIntoCannoned(_ w: SpriteWorld, captive cID: Int, cannon kID: Int) {
        guard let c = w.active.record(id: cID), let k = w.active.record(id: kID) else { return }
        let dx = h(c.centre.x - c.x), dy = h(c.centre.y - c.y)
        let isPlayer = cID == w.playerID
        guard !isPlayer || 0 < c.hp else { return }
        w.player.cues.append(PlayerCue(call: .threeDRand, snd: 484, priority: 1, volume: 0x97, position: c.centre,
                                       rate: w.rng.soundRate()))
        w.active.update(id: cID) { s in
            s.savedHandler = s.handler
            s.savedHandleCleared = s.handleCleared                          // a saved `+0x4c` of 0
            s.handleCleared = false
            s.savedHasHit = s.hasHit
            s.savedHasTileHit = s.hasTileHit
            s.reentry = 0xf
            s.handler = .cannoned
            s.hasHit = false
            s.hasTileHit = false
            s.vy = 0
            s.vx = 0
            s.cannon = kID
            s.x = h(k.centre.x - dx)
            s.y = h(k.centre.y - dy)
            s.x256 = Int32(s.x) << 8
            s.y256 = Int32(s.y) << 8
            s.centre.x = h(s.x + dx)
            s.centre.y = h(s.y + dy)
            if s.light != -1 { s.light = -1 }
        }
        if isPlayer { w.player.launched = true }
    }

    /// `.HandleCannonedSprite(s) @ 10058710` (decompile l. 49976–50223), the captive's Handle:
    /// 1. d = centre − origin; face 0; pinned to the cannon's centre − d (24.8 from it), centre = origin + d.
    /// 2. The player: `_DAT_100a05a0 = 1`, the centre globals `fd94`/`fd90`, `.PlayerScroll`, HP < 1 → `+0x130 = −1`,
    ///    `.DoubleSpeedTrail` (// later: Phase 4).
    /// 3. The hold: the player in a path cannon (record p1 < 0): `05a0 = 1`, and below 2 `+0x130` steps only while
    ///    **jump** (action 5) is pressed; everything else −1 a frame. v = 0, `+0x80 = 2` (the sort key stored, no relink).
    /// 4. `+0x130 < 1` and the cannon's aim mod 4 == 0 → **fire**, S = the cannon's `+0x164`: re-entry `+0x130` = −5
    ///    (player) / −35; v by aim / 4 (`fire`); three smokes (`smokes`); the recoil (cannon p1 ≥ 0): cannon 24.8
    ///    position = (int)−(1.6·v − pos) (`100a19b0`); type 0x5a → gravity 0x15e; the captive's position += v; vy > 0 →
    ///    v = ((int)(vx·0.7), (int)(vy·0.55)) (`100a19a8`, `100a19a0`); `+0x24/+0x2c` = v;
    ///    `.STPlay3DSoundRand(483, 1, 0x100, +0xe)` (`_DAT_100a0310`); the saved Handle / callbacks restored; the player:
    ///    launched, face tumble 1015[`_DAT_100a05b4`], swim `0714` 0, spin `0668` 0, climb `0758` 0, `.PlayerScroll`,
    ///    `+8 = +0xc = fe68` and `+6 = +0xa = fe64` from 24.8, the centre from the hot rect into `fd94`/`fd90`.
    public static func handleCannoned(world w: SpriteWorld, id: Int, keys: InputActions) {
        guard let c0 = w.active.record(id: id), let kID = c0.cannon, let k0 = w.active.record(id: kID) else { return }
        let isPlayer = id == w.playerID
        let dx = h(c0.centre.x - c0.x), dy = h(c0.centre.y - c0.y)
        w.active.update(id: id) { s in
            s.face = nil
            s.x = h(k0.centre.x - dx)
            s.y = h(k0.centre.y - dy)
            s.x256 = Int32(s.x) << 8
            s.y256 = Int32(s.y) << 8
            s.centre.x = h(s.x + dx)
            s.centre.y = h(s.y + dy)
        }
        if isPlayer, let s = w.active.record(id: id) {
            w.player.flag05a0 = true
            w.player.centreX = Int16(truncatingIfNeeded: s.centre.x)
            w.player.centreY = Int16(truncatingIfNeeded: s.centre.y)
            PlayerScroll.scroll(&w.player, groundKind: s.groundKind, inWind: s.inWind)
            if s.hp < 1 { w.active.update(id: id) { $0.reentry = -1 } }
            // later: Phase 4 — `.DoubleSpeedTrail(s)` (the trail sprites' faces; no Phase-2 Double Speed).
        }
        let pathCannon = (record(w, k0)?.p1 ?? 0) < 0
        if isPlayer && pathCannon {
            w.player.flag05a0 = true
            w.active.update(id: id) { s in
                if s.reentry < 2 {
                    if keys.contains(.jump) { s.reentry &-= 1 }
                } else {
                    s.reentry &-= 1
                }
            }
        } else {
            w.active.update(id: id) { $0.reentry &-= 1 }
        }
        w.active.update(id: id) { s in
            s.vy = 0
            s.vx = 0
            s.layer = 2
        }
        guard let c = w.active.record(id: id), c.reentry < 1, let k = w.active.record(id: kID) else { return }
        let aim = Int32(k.phase)
        guard aim % 4 == 0 else { return }
        fire(w, captive: id, cannon: kID, isPlayer: isPlayer)
    }

    /// The launch vector for aim / 4 = `octant` and speed S (l. 50074–50113; doubles `100a19e8` 0.707, `100a19e0`
    /// 0.235, `100a19d8` 0.8, `100a19d0` 0.35; each product fctiwz): 0 (0, −S); 1 (0.707S, 0.707·−S); 2 (S, 0.235·−S);
    /// 3 (0.8S, 0.35S); 4 (0, S); 5 (0.8·−S, 0.35S); 6 (−S, 0.235·−S); 7 (0.707·−S, the same); any other (0, 0).
    public static func launchVector(octant: Int32, speed s: Int32) -> (vx: Int32, vy: Int32) {
        let S = Double(s), nS = Double(0 &- s)
        let f = TileSolver.fctiwz
        switch octant {
        case 0: return (0, 0 &- s)
        case 1: return (f(0.707 * S), f(0.707 * nS))
        case 2: return (s, f(0.235 * nS))
        case 3: return (f(0.8 * S), f(0.35 * S))
        case 4: return (0, s)
        case 5: return (f(0.8 * nS), f(0.35 * S))
        case 6: return (0 &- s, f(0.235 * nS))
        case 7:
            let v = f(0.707 * nS)
            return (v, v)
        default: return (0, 0)
        }
    }

    /// The launch (step 4 of `handleCannoned`).
    static func fire(_ w: SpriteWorld, captive id: Int, cannon kID: Int, isPlayer: Bool) {
        guard let k = w.active.record(id: kID), let c = w.active.record(id: id) else { return }
        let S = k.launchSpeed
        w.active.update(id: id) { $0.reentry = isPlayer ? -5 : -0x23 }
        var (vx, vy) = launchVector(octant: Int32(k.phase) >> 2, speed: S)
        smokes(w, cannon: k, vx: vx, vy: vy)
        if 0 <= (record(w, k)?.p1 ?? 0) {
            w.active.update(id: kID) { s in
                s.x256 = TileSolver.fctiwz(-(1.6 * Double(vx) - Double(s.x256)))
                s.y256 = TileSolver.fctiwz(-(1.6 * Double(vy) - Double(s.y256)))
                s.x = SpriteWorld.pixel(s.x256)
                s.y = SpriteWorld.pixel(s.y256)
            }
        }
        let launchVX = vx, launchVY = vy
        if 0 < vy {
            vx = TileSolver.fctiwz(Double(vx) * 0.7)
            vy = TileSolver.fctiwz(Double(vy) * 0.55)
        }
        let storedVX = vx, storedVY = vy
        w.active.update(id: id) { s in
            if s.type == 0x5a { s.gravity = 0x15e }
            s.x256 &+= launchVX
            s.y256 &+= launchVY
            s.x = SpriteWorld.pixel(s.x256)
            s.y = SpriteWorld.pixel(s.y256)
            s.vx = storedVX
            s.vy = storedVY
        }
        w.player.cues.append(PlayerCue(call: .threeDRand, snd: 483, priority: 1, volume: 0x100, position: c.centre,
                                       rate: w.rng.soundRate()))                          // `_DAT_100a0310`
        w.active.update(id: id) { s in
            s.handler = s.savedHandler ?? s.handler
            s.handleCleared = s.savedHandleCleared
            s.hasHit = s.savedHasHit
            s.hasTileHit = s.savedHasTileHit
        }
        guard isPlayer else { return }
        w.player.launched = true
        let frame = w.player.tumbleFrame
        w.active.update(id: id) { $0.face = FaceRef(pict: tumble, index: Int(frame), set: .encoded) }
        w.player.swim = 0
        w.player.spin = false
        w.player.climb = 0
        if let s = w.active.record(id: id) {
            PlayerScroll.scroll(&w.player, groundKind: s.groundKind, inWind: s.inWind)
        }
        w.active.update(id: id) { s in
            let x = SpriteWorld.pixel(s.x256), y = SpriteWorld.pixel(s.y256)
            s.oldPosition = SpriteSlot.Point(x: x, y: y)
            s.x = x
            s.y = y
            let r = s.hotRect
            s.centre.x = h(s.x + r.left + h((r.right - r.left) >> 1))
            s.centre.y = h(s.y + r.top + h((r.bottom - r.top) >> 1))
        }
        if let s = w.active.record(id: id) {
            w.player.pixelX = Int16(truncatingIfNeeded: s.x)
            w.player.pixelY = Int16(truncatingIfNeeded: s.y)
            w.player.centreX = Int16(truncatingIfNeeded: s.centre.x)
            w.player.centreY = Int16(truncatingIfNeeded: s.centre.y)
        }
    }

    /// The three smokes of a launch (l. 50114–50150): at (x, y) = ((int)(1.5·vx·(1/256) + cannon +0x10 − 24),
    /// (int)(1.5·vy·(1/256) + cannon +0xe − 24)) (doubles `100a19c8` 1.5, `100a19c0` 1/256, `100a19b8` 24), each
    /// `MTNewSprite(0x442, …, .SetupEffectSprite)` (`smokeSetup`) followed by `+0x17e = FastRand(2)`, `+0x46 =
    /// FastRand(4)` and `.ChangeLightColor(+0x9a, 0)` (no light: a no-op, `1001becc`): the first at (x, y), layer 0xb;
    /// then dy = `FastRand(8)`, dx = `FastRand(8)` and the second at (x − dx, y − dy); again dy, dx and the third at
    /// (x + dx, y + dy) — both at the cannon's layer + 1 (the Setup stores 0x7fbc over every one).
    static func smokes(_ w: SpriteWorld, cannon k: SpriteSlot, vx: Int32, vy: Int32) {
        let x = Int(TileSolver.fctiwz((1.5 * Double(vx) * 0.00390625 + Double(h(k.centre.x))) - 24.0))
        let y = Int(TileSolver.fctiwz((1.5 * Double(vy) * 0.00390625 + Double(h(k.centre.y))) - 24.0))
        func make(_ sx: Int, _ sy: Int, layer: Int16) {
            let id = w.newSprite(type: smoke, x: h(sx), y: h(sy), layer: layer, handler: .effect) { s in
                smokeSetup(w, &s)
            }
            let mirrored = w.rng.next(2)
            let phase = w.rng.next(4)
            if let id {
                w.active.update(id: id) { s in
                    s.mirrored = mirrored != 0
                    s.phase = phase
                }
            }
        }
        let x16 = h(x), y16 = h(y)
        make(x, y, layer: 0xb)
        let layer = Int16(truncatingIfNeeded: k.layer &+ 1)
        var ddy = Int(w.rng.next(8))
        var ddx = Int(w.rng.next(8))
        make(x16 - ddx, y16 - ddy, layer: layer)
        ddy = Int(w.rng.next(8))
        ddx = Int(w.rng.next(8))
        make(x16 + ddx, y16 + ddy, layer: layer)
    }

    /// `.SetupEffectSprite` for the smoke 0x442 (l. 53688–53800): the common part (`EffectSprite.setup`), then the
    /// explosion package — light position (y + 0x18, x + 0x18), particle kind 4 (type 5 / 0x442), and 45 ×
    /// (`FastRand(2000)`, `FastRand(2000)`, `FastRand(2)`) → `.NewParticle(4, 0x96, (y + 0x18, x + 0x10), r2 + 1,
    /// r1 − 1000, r0 − 1000, 0, 1)` (// later: E1a — the particles; the draws are made here, in this order); no 0x4b6
    /// and no `.AddLight` for 0x442; layer `+0x80 = 0x7fbc`.
    static func smokeSetup(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        EffectSprite.setup(&s)
        for _ in 0..<0x2d {
            _ = w.rng.next(2000)
            _ = w.rng.next(2000)
            _ = w.rng.next(2)
            // later: E1a — `.NewParticle(4, 0x96, …)`.
        }
        s.layer = 0x7fbc
    }
}
