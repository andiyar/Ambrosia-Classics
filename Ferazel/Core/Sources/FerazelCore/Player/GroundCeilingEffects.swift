import Foundation

/// `.CheckGroundCeilingHitEffects(s) @ 100544d8` (plan P2; decompile l. 47885–47954, raw `100544d8..10054708`;
/// physics-sprites §8.7): called by `.HitPlayerTileSprite` after each `.WallBounce` / `.WallBounceBG` (and by
/// `.HitPlayerSprite`, W1). Nothing on the glider (`_DAT_100a05e0`).
public enum GroundCeilingEffects {
    /// - **Landing** — `+0xce` ≠ 0, `_DAT_100a0738` (the pre-move ground kind) == 0, not latched (`_DAT_100a0724`):
    ///   v = (i16)(impact >> 7) (`_DAT_100a0660`, srawi); dry (`+0x120` == 0) ∧ impact > 0x400 → the dust sprite
    ///   `MTNewSprite(0x4b1, +0xc + 0x18, (y256 >> 8) + 0x53, 0xb, −1, .SetupEffectSprite)`; launched `05b8` = 0;
    ///   latch; v < 0x30 → 0, > 100 → 100; stop 414 if playing, stop 427 if playing (and `+0xce` ≠ 0); then unless
    ///   riding a 0x58c (`+0xdc`'s `+0xb0`): 2v == 0 → impact > 700 ∧ dry → 601 prio 0x14 vol 0x3c; 2v ≠ 0 ∧ dry → 600
    ///   prio 0x14 vol 2v + 0x14; on the springboard → impact > 0x578 → 603 prio 1 vol 0x55.
    /// - **Ceiling** — not latched (`_DAT_100a0720`), not dying (`_DAT_100a069c`, `lha`), `+0xcf` ≠ 0: latch, 404 prio
    ///   0x14 vol 0xa0.
    /// No HP is written (no fall damage).
    public static func check(_ w: SpriteWorld, id: Int) {
        guard !w.player.glider, let s = w.active.sprite(id: id) else { return }
        if s.groundKind != 0 && w.player.groundLast == 0 && !w.player.landedLatch {
            let impact = w.player.impact
            var v = Int16(truncatingIfNeeded: impact >> 7)
            if s.lastWater == 0 && impact > 0x400 {
                let x = Int(Int16(truncatingIfNeeded: s.x + 0x18))
                let y = Int(Int16(truncatingIfNeeded: (s.y256 >> 8) + 0x53))
                w.newSprite(type: EffectSprite.dust, x: x, y: y, layer: 0xb, handler: .effect) { EffectSprite.setup(&$0) }
            }
            w.player.launched = false                                   // `_DAT_100a05b8`
            w.player.landedLatch = true
            if v < 0x30 {
                v = 0
            } else if 100 < v {
                v = 100
            }
            let twice = Int16(truncatingIfNeeded: Int32(v) << 1)        // `slw; extsh` (raw `100545b4..100545c4`)
            w.player.cue(PlayerCue(call: .stopIfPlaying, snd: 414))   // `_DAT_100a03f8` (Bank correction C7)
            if (w.active.sprite(id: id)?.groundKind ?? 0) != 0 {
                w.player.cue(PlayerCue(call: .stopIfPlaying, snd: 427))   // `_DAT_100a03cc`
            }
            let me = w.active.sprite(id: id) ?? s
            let springboard = me.ridden.flatMap { w.active.record(id: $0) }.map { $0.subtype == 0x58c } ?? false
            if !springboard {
                if twice == 0 {
                    if 700 < impact && me.lastWater == 0 {
                        w.player.cue(PlayerCue(call: .reg, snd: 601, priority: 0x14, volume: 0x3c))   // `a0284`
                    }
                } else if me.lastWater == 0 {
                    w.player.cue(PlayerCue(call: .reg, snd: 600, priority: 0x14,
                                           volume: Int16(truncatingIfNeeded: Int32(twice) + 0x14)))   // `a0288`
                }
            } else if 0x578 < impact {
                w.player.cue(PlayerCue(call: .reg, snd: 603, priority: 1, volume: 0x55))   // `_DAT_100a0280`
            }
        }
        if !w.player.bumpedLatch && w.player.dying == 0 && (w.active.sprite(id: id)?.ceilingHit ?? 0) != 0 {
            w.player.bumpedLatch = true
            w.player.cue(PlayerCue(call: .reg, snd: 404, priority: 0x14, volume: 0xa0))   // `_DAT_100a0408`
        }
    }
}

/// The Effect class (triggers-background-2 §2): `.SetupEffectSprite @ 10060680` and `.HandleEffectSprite @ 10061160`
/// for the effects Phase 2 spawns — the landing dust 1201 (`.CheckGroundCeilingHitEffects`), the crumble overlay 1210
/// (`.MakeCrunchSprite`) and the bubble 1040 (`.EmitBubble`, P4). The other ids (explosions and their particle package,
/// plumes, the countdown's digits, crate debris, …) // later: E1a / Phase 3–5.
public enum EffectSprite {
    /// 0x4b1 'dust cloud' (PICT 1201, 6 × 56×8) and 0x4ba 'crumble overlay' (PICT 1210, 3 × 32×32).
    public static let dust: Int16 = 0x4b1
    public static let crumble: Int16 = 0x4ba

    /// `.SetupEffectSprite`'s common part (l. 53688–53720): `+0x88` 0, `+0x84`/`+0x86` 0 (not kept: no reader),
    /// `+0x46` 0, layer `+0x80` = 0xb (stored before `.MTInsertSprite`, so it is the sort key whatever the caller
    /// passed), the Handle (`.effect`), the hit callback `.HitEffectSprite` (empty, but installed: `+0x5c` ≠ 0), the tile
    /// callback `.HitEffectTileSprite` (no 1201/1210 Handle separates), `+0xa6` 3 (not kept: no Phase-2 reader), hot rect
    /// `SetRect(+0x34, 16, 16, 32, 32)`, face 0, `+0xc = +8`, `+0xa = +6`, 24.8 from them, `+0xe4` 1 (not kept),
    /// `+0x13e` 0 (no splash, E1a). 1201, 1210 and 1040 skip the explosion package (no draws, no light). 1040 (0x410): hot rect
    /// `SetRect(+0x34, 0, −10, 8, −2)` (left 0, top −10, right 8, bottom −2; l. 53736).
    public static func setup(_ s: inout SpriteSlot) {
        s.lightOverlay = false
        s.phase = 0
        s.layer = 0xb
        s.handler = .effect
        s.hasHit = true
        s.hotRect = IdleSprites.Rect(top: 0x10, left: 0x10, bottom: 0x20, right: 0x20)
        s.face = nil
        s.x = s.oldPosition.x
        s.y = s.oldPosition.y
        s.x256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.y)) << 8
        s.splashes = false
        if s.type == PlayerLiquids.bubble { s.hotRect = IdleSprites.Rect(top: -10, left: 0, bottom: -2, right: 8) }
    }

    /// `.HitEffectTileSprite(s, pos, kind, layer) @ 100619a0` (l. 54298–54324), the Effect class's tile callback: BG
    /// (layer 0) liquid (`.IsWaterTile`) with `+0x140 == 0` → `.HandleUnderWater(s, pos)` (its entry `.Splash` —
    /// an Effect's `+0x13e` is 0, so it returns at once). The FG arm (0xc1b's `.WallBounce`) and the crunch arm (`+0xeb` → `.CrunchTile`) belong to effects
    /// Phase 2 does not spawn (// later: E1a / Phase 3–5).
    public static func hitTile(_ solver: TileSolver, id: Int, pos: TilePos, kind: Int, layer: TileLayer) {
        let w = solver.world
        guard layer == .background, UnderWater.isWaterTile(kind),
              let s = w.active.sprite(id: id), !s.underwaterDone else { return }
        UnderWater.handle(world: w, id: id, pos: pos)
    }

    /// The frame width of an effect face (`face +6`) for `.StandardSpriteCleanup`: 56 (1201), 32 (1210), 8 (1040).
    public static func faceWidth(_ f: FaceRef) -> Int {
        switch f.pict {
        case dust: return 0x38
        case crumble: return 0x20
        case PlayerLiquids.bubble: return 8
        case BackgroundSprite.smokeSheet: return 0x30
        default: return 0x80
        }
    }

    /// `.HandleEffectSprite(s)` for 1201 and 1210 (l. 54024–54285): `+0xe9` or `+0x1b2` → return;
    /// `.StandardSpriteHandles`; then
    /// - 1201: `+0x88` 1, `+0x46` += 1; < 6 → face `+0x46` of PICT 1201; else killed, face 0 — so faces 1…5 show and
    ///   the 6th Handle kills it (face 0 is never set).
    /// - 1210: `+0x88` 1; `+0x46` counts down to 0; armed (`+0x16c` 1) at 0 → hp −= 1; hp < 1 → face 0, killed, table
    ///   slot `+0x150` freed, and when hp == 0 ∧ armed: 424 at `+0xe` (`.STPlay3DSound`), `.DestroyCrunchTile(+0x154,
    ///   +0x158, +0x15c, 1, 1, 0)` and the log; else face `+0x14c − hp` (0…2, otherwise `ReportError("Crunch sprite face
    ///   out of range")` and the face is left).
    /// then x += vx, y += vy, the pixel copies `+8 = +0xc`, `+6 = +0xa` from 24.8, `.StandardSpriteCleanup`.
    public static func handle(world w: SpriteWorld, id: Int, faceWidth: (FaceRef) -> Int = EffectSprite.faceWidth) {
        guard let s0 = w.active.record(id: id), !s0.dead, !s0.handleSkip else { return }
        w.standardSpriteHandles(id)
        guard let s = w.active.record(id: id) else { return }
        switch s.type {
        case dust:
            w.active.update(id: id) { p in
                p.lightOverlay = true
                p.phase &+= 1
                if p.phase < 6 {
                    p.face = FaceRef(pict: dust, index: Int(p.phase), set: .encoded)
                } else {
                    p.dead = true
                    p.face = nil
                }
            }
        case crumble:
            w.active.update(id: id) { p in
                p.lightOverlay = true
                if 0 < p.phase { p.phase -= 1 }
                if p.classWord16c == 1 && p.phase == 0 { p.hp &-= 1 }
            }
            let p = w.active.record(id: id)!
            if p.hp < 1 {
                w.active.update(id: id) { q in
                    q.face = nil
                    q.dead = true
                }
                let slot = Int(p.classWord150)
                if w.player.crunchSprites.indices.contains(slot) { w.player.crunchSprites[slot] = nil }
                if p.hp == 0 && p.classWord16c == 1 {
                    w.player.cue(PlayerCue(call: .threeD, snd: 424, priority: 1, volume: 0x100,
                                           position: p.centre))   // `_DAT_100a01e0`
                    CrunchTiles.destroyCrunchTile(w, col: Int(Int16(truncatingIfNeeded: p.classWord154)),
                                                  row: Int(Int16(truncatingIfNeeded: p.classWord158)),
                                                  dir: Int(Int16(truncatingIfNeeded: p.classWord15c)),
                                                  explode: true, clearDir: true)
                    CrunchTiles.log(w, col: Int(Int16(truncatingIfNeeded: p.classWord154)),
                                    row: Int(Int16(truncatingIfNeeded: p.classWord158)))
                }
            } else {
                let f = Int16(truncatingIfNeeded: p.classTimer) &- p.hp
                if (0...2).contains(f) {
                    w.active.update(id: id) { $0.face = FaceRef(pict: crumble, index: Int(f), set: .encoded) }
                }
                // else `.ReportError` — the face is left as it was.
            }
        case PlayerLiquids.bubble:
            // 1040 (l. 54149–54161; raw `10061584..10061604`): `+0x46` += 1, past 7 → 0; face `+0x46 >> 1` of PICT
            // 1040; vy = −500; `.SeparateFromTiles2` with `.HitEffectTileSprite`; out of the liquid (`+0x11c == 0`) →
            // face 0, `.RemoveLight(+0x9a)` (the bubble has none: −1), killed; then straight to the tail (`b
            // 0x100618dc` — the decompile's view-bottom kill, l. 54267, belongs to 0x4b2…0x4b4 only, raw
            // `10061260..1006127c`).
            w.active.update(id: id) { p in
                p.phase &+= 1
                if 7 < p.phase { p.phase = 0 }
                p.face = FaceRef(pict: PlayerLiquids.bubble, index: Int(p.phase >> 1), set: .encoded)
                p.vy = -500
            }
            TileSolver(world: w).separateFromTiles(id, pass: { hitTile($0, id: $1, pos: $2, kind: $3, layer: $4) })
            if w.active.record(id: id)?.waterRow == 0 {
                w.active.update(id: id) { p in
                    p.face = nil
                    p.dead = true
                }
            }
        case BackgroundSprite.smoke:
            // The cannon smoke 0x442 (W2b; the `type < 0xcb2` arm, l. 54203–54255): `+0xb8 = 0x10005`; `+0x46` += 1;
            // the `.ChangeLightFace` / `.RemoveLight` steps at 2, 4, 6, 14, 17, 20, 23 act on `+0x9a` = −1 (the smoke
            // has no light: no-ops, raw `1001bdbc` / `1001bd34`); `+0x46` < 0x1a → face 0x4b0[`+0x46` >> 1], else
            // killed and face 0.
            w.active.update(id: id) { p in
                p.mode = 0x10005
                p.phase &+= 1
                if p.phase < 0x1a {
                    p.face = FaceRef(pict: BackgroundSprite.smokeSheet, index: Int(p.phase >> 1), set: .encoded)
                } else {
                    p.dead = true
                    p.face = nil
                }
            }
        default:
            break   // later: E1a / Phase 3–5 — the other effect ids.
        }
        w.active.update(id: id) { p in
            p.x256 &+= p.vx
            p.y256 &+= p.vy
            let x = SpriteWorld.pixel(p.x256), y = SpriteWorld.pixel(p.y256)
            p.oldPosition = SpriteSlot.Point(x: x, y: y)
            p.x = x
            p.y = y
        }
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
    }
}
