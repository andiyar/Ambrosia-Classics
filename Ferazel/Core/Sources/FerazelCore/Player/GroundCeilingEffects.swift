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


/// The Effect class (triggers-background-2 §2): `.SetupEffectSprite @ 10060680` (M l. 53688–53863) and
/// `.HandleEffectSprite @ 10061160` (M l. 54024–54286). Spawned so far: the landing dust 1201
/// (`.CheckGroundCeilingHitEffects`), the crumble overlay 1210 (`.MakeCrunchSprite`), the bubble 1040 (`.EmitBubble`),
/// the cannon smoke 1090 (`BackgroundSprite.smokes`), the countdown 1220 (`FerazelSession`); EF adds the explosion ids
/// 0…15, 1207, 3201, the plume 1206, the debris 3099 and the balloons ≥ 3250 (`setup(_:_:effects:lights:)`, `spawn`) for
/// their spawners (CS / SH: `.KillPlayerShot`, `.KillEnemyShot`; BX1: `.KillCrate`; BX2: `.CreateBalloonSprite`).
/// Not built (no spawner on the built levels; the bank found none for most): 1202…1205, 1251, 1830, −1 and the
/// countdown's `.UpdateDigits` // later: their spawners' tasks (Phase 5–6). The 1207 against Crawler / Walker / Roach /
/// Frog (their Hit routines) and against crates (`.HitBoxSprite`: −10 on any frame, then `.KillPlayerShot`;
/// pickups-boxes-2 §7) // later: Phase 5 ◇ / BX1.
public enum EffectSprite {
    /// 0x4b1 'dust cloud' (PICT 1201, 6 × 56×8) and 0x4ba 'crumble overlay' (PICT 1210, 3 × 32×32).
    public static let dust: Int16 = 0x4b1
    public static let crumble: Int16 = 0x4ba
    /// 0x4b6 'smoke plume' (PICT 1206, 34 × 64×116, `.InitEffectSprite` M l. 53658).
    public static let plume: Int16 = 0x4b6
    /// 0x4b7 'big explosion' (PICT 1207, 13 × 96×96, M l. 53652).
    public static let bigExplosion: Int16 = 0x4b7
    /// 0xc1b crate debris (PICT 3099, 16 × 24×24, 8 per row, M l. 53660).
    public static let debris: Int16 = 0xc1b
    /// The explosion faces (PICT 1200 = 0x4b0, 13 × 48×48, M l. 53650): ids 0…15, 1090, 3201, −1.
    public static let explosionSheet: Int16 = 0x4b0
    /// The explosion light's first face, `PTR_DAT_100a088c[3]` = PICT 813 (72×72, M l. 53668).
    static let explosionLight = LightFaceRef(pict: 0x32d, width: 0x48, height: 0x48)

    /// `.SetupEffectSprite`'s common part (l. 53688–53736): `+0x88` 0, `+0x84`/`+0x86` 0 (not kept: no reader),
    /// `+0x46` 0, layer `+0x80` = 0xb (stored before `.MTInsertSprite`, so it is the sort key whatever the caller
    /// passed), the Handle (`.effect`), the hit callback `.HitEffectSprite` (empty, but installed: `+0x5c` ≠ 0), the tile
    /// callback `.HitEffectTileSprite`, `+0xa6` 3 (not kept: no reader yet), hot rect
    /// `SetRect(+0x34, 16, 16, 32, 32)`, face 0, `+0xc = +8`, `+0xa = +6`, 24.8 from them, `+0xe4` 1 (not kept),
    /// `+0x13e` 0 (no splash, E1a). 1040 (0x410): hot rect `SetRect(+0x34, 0, −10, 8, −2)` (left 0, top −10, right 8,
    /// bottom −2; l. 53736). The type arms and the explosion package are `setup(_:_:effects:lights:)`'s; the callers that
    /// use this part alone make types in the package's skip list (1201, 1210, 1040, 1220) or add their own arm (1090,
    /// `BackgroundSprite.smokeSetup`).
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

    /// The ids the explosion package skips (M l. 53745–53751): 1201…1206, 1220, 1040, 1430, 1251, 1210, 3099, 1440,
    /// 1435, 1830, and every id ≥ 3200.
    static func skipsPackage(_ t: Int16) -> Bool {
        (0x4b1...0x4b6).contains(t) || [0x4c4, 0x410, 0x596, 0x4e3, 0x4ba, 0xc1b, 0x5a0, 0x59b, 0x726].contains(t)
            || 0xc80 <= t
    }

    /// The whole `.SetupEffectSprite` (M l. 53688–53863) for the ids EF builds, run inside `.MTNewSprite` (before
    /// the insert): the common part, then in the dump's order
    /// - 0x4b7: `SetRect(+0x34, 8, 8, 0x58, 0x58)` (left 8, top 8, right 88, bottom 88), `+0xeb = 2` (l. 53738–53741);
    /// - 0x4b6: the plume count `*PTR_DAT_100a0904` + 1 (l. 53742–53744);
    /// - **the explosion package** unless `skipsPackage` (l. 53745–53795): kind 4 for 5 and 0x442, 9 for 2, else 1; 45 ×
    ///   (`FastRand(2000)` r0, `FastRand(2000)` r1, `FastRand(2)` r2) → `.NewParticle(kind, 0x96, (y + 0x18, x + 0x10),
    ///   r2 + 1, r1 − 1000, r0 − 1000, 0, 1)` — (y + 0x30, x + 0x20) for 0x4b7 (l. 53765–53783); then, unless 0x4b7,
    ///   0x442 or −1, with prefs+6 == 1 and fewer than 3 plumes, `MTNewSprite(0x4b6, x − 8, y − 0x5a, 0x14, −1,
    ///   Setup)` (l. 53785–53790; its Setup is this one — layer 0xb, counted); then, unless 0x442,
    ///   `+0x9a = .AddLight(PICT 813, (y + 0x18, x + 0x18), 0, 0, 0, 0x16)` — (y + 0x30, x + 0x30) for 0x4b7
    ///   (l. 53753–53758, 53791–53793). x / y are `+0xc` / `+0xa` as the common part left them.
    /// - 0xcb2 → layer 100, > 0xcb2 → 0x65 (l. 53796–53801); 0x442 → 0x7fbc (l. 53802–53804);
    /// - 0xc1b: `FastRand(100)` < 0x33 → `+0x14c` 1, else 0; `+0x46 = FastRand(8)`; gravity `+0x110` 0x5a; the tile
    ///   callback re-stored (the same); `SetRect(+0x34, 10, 10, 0xe, 0xe)` (l. 53812–53825).
    /// The 0x5a0 geyser segment's arm (l. 53805–53811) // later: the geyser task; 0x4c4's is `FerazelSession`'s.
    public static func setup(_ w: SpriteWorld, _ s: inout SpriteSlot, effects: Int16, lights: inout LightTable) {
        setup(&s)
        let t = s.type
        if t == bigExplosion {
            s.hotRect = IdleSprites.Rect(top: 8, left: 8, bottom: 0x58, right: 0x58)
            s.crunches = 2
        }
        if t == plume { w.plumeCount &+= 1 }
        if !skipsPackage(t) {
            let big = t == bigExplosion
            let x = Int(Int16(truncatingIfNeeded: s.x)), y = Int(Int16(truncatingIfNeeded: s.y))
            let kind = t == 5 || t == BackgroundSprite.smoke ? 4 : t == 2 ? 9 : 1
            for _ in 0..<0x2d {
                let r0 = Int(w.rng.next(2000))
                let r1 = Int(w.rng.next(2000))
                let r2 = Int(w.rng.next(2))
                w.particles.newParticle(kind: kind, gravity: 0x96, v: y + (big ? 0x30 : 0x18), h: x + (big ? 0x20 : 0x10),
                                        shape: r2 + 1, vx: r1 - 1000, vy: r0 - 1000, delay: 0, mode: 1)
            }
            if t != bigExplosion && t != BackgroundSprite.smoke && t != -1 && effects == 1 && w.plumeCount < 3 {
                w.newSprite(type: plume, x: x - 8, y: y - 0x5a, layer: 0x14, handler: .effect) { p in
                    setup(w, &p, effects: effects, lights: &lights)
                }
            }
            if t != BackgroundSprite.smoke {
                let d: Int16 = big ? 0x30 : 0x18
                s.light = lights.add(face: explosionLight, x: Int16(truncatingIfNeeded: x) &+ d,
                                     y: Int16(truncatingIfNeeded: y) &+ d, vx: 0, vy: 0, accelY: 0, colour: 0x16)
            }
        }
        if t == 0xcb2 {
            s.layer = 100
        } else if 0xcb2 < t {
            s.layer = 0x65
        }
        if t == BackgroundSprite.smoke { s.layer = 0x7fbc }
        if t == debris {
            s.classTimer = w.rng.next(100) < 0x33 ? 1 : 0
            s.phase = w.rng.next(8)
            s.gravity = 0x5a
            s.hotRect = IdleSprites.Rect(top: 10, left: 10, bottom: 0xe, right: 0xe)
        }
    }

    /// `MTNewSprite(type, x, y, layer, −1, .SetupEffectSprite)` with the whole Setup (`setup(_:_:effects:lights:)`):
    /// nil when no record is free (Ruling 16: no Setup, no draws). `effects` is prefs+6, `lights` the session's table.
    @discardableResult
    public static func spawn(_ w: SpriteWorld, type: Int16, x: Int, y: Int, layer: Int16, effects: Int16,
                             lights: inout LightTable) -> Int? {
        w.newSprite(type: type, x: x, y: y, layer: layer, handler: .effect) { s in
            setup(w, &s, effects: effects, lights: &lights)
        }
    }

    /// `.HitEffectTileSprite(s, pos, kind, layer) @ 100619a0` (M l. 54298–54324; raw `100619a0..10061a9c`), the
    /// Effect class's tile callback:
    /// - FG (layer 1), 0xc1b only: `.WallBounce(s, kind, &pos, &(+0xe − +0xa, +0x10 − +0xc), 0x80, +0x34, 0, 0x80)`
    ///   (raw `100619d0..10061a10`: r7 0x80, r9 0, r10 0x80); a hit → `+0x16c` += 1;
    /// - BG (layer 0) liquid (`.IsWaterTile`) with `+0x140 == 0` → `.HandleUnderWater(s, pos)` (its entry `.Splash` —
    ///   an Effect's `+0x13e` is 0, so it returns at once);
    /// - crunch (layer 2) with `+0xeb` ≠ 0 → `.CrunchTile(pos, +0xeb)` (raw `10061a74..10061a84`: r4 = `+0xeb`).
    public static func hitTile(_ solver: TileSolver, id: Int, pos posIn: TilePos, kind: Int, layer: TileLayer) {
        let w = solver.world
        guard let s = w.active.sprite(id: id) else { return }
        switch layer {
        case .foreground:
            guard s.type == debris else { return }
            var pos = posIn
            let vCentre = Int(Int16(truncatingIfNeeded: s.centre.y - s.y))
            if solver.wallBounce(id, kind: kind, tile: &pos, vCentre: vCentre, factor: 0x80, rect: s.hotRect,
                                 bounce: true) {
                w.active.update(id: id) { $0.classWord16c &+= 1 }
            }
        case .background:
            guard UnderWater.isWaterTile(kind), !s.underwaterDone else { return }
            UnderWater.handle(world: w, id: id, pos: posIn)
        case .crunch:
            guard s.crunches != 0 else { return }
            CrunchTiles.crunchTile(w, pos: posIn, strength: s.crunches)
        }
    }

    /// The frame width of an effect face (`face +6`) for `.StandardSpriteCleanup`: 56 (1201), 32 (1210), 8 (1040),
    /// 48 (1200), 96 (1207), 64 (1206), 24 (3099).
    public static func faceWidth(_ f: FaceRef) -> Int {
        switch f.pict {
        case dust: return 0x38
        case crumble: return 0x20
        case PlayerLiquids.bubble: return 8
        case explosionSheet: return 0x30
        case bigExplosion: return 0x60
        case plume: return 0x40
        case debris: return 0x18
        default: return 0x80
        }
    }

    /// The light schedule of the 26-frame explosions (M l. 54217–54238): `+0x46` → the index into
    /// `PTR_DAT_100a088c` (PICTs 810…813); 0x17 removes the light.
    static let lightSchedule: [Int16: Int] = [2: 2, 4: 1, 6: 0, 0xe: 1, 0x11: 2, 0x14: 3]

    /// `.HandleEffectSprite(s)` (M l. 54024–54286): `+0xe9` or `+0x1b2` → return; `.StandardSpriteHandles`; then by id
    /// - 1201: `+0x88` 1, `+0x46` += 1; < 6 → face `+0x46` of PICT 1201; else killed, face 0 — so faces 1…5 show and
    ///   the 6th Handle kills it (face 0 is never set).
    /// - 1206 (l. 54079–54092): `+0x88` 0, `+0xb8 = 0xb0004`, `+0x46` += 1; < 0x22 → face `+0x46` of PICT 1206; else
    ///   killed, face 0, the plume count − 1.
    /// - 1210: `+0x88` 1; `+0x46` counts down to 0; armed (`+0x16c` 1) at 0 → hp −= 1; hp < 1 → face 0, killed, table
    ///   slot `+0x150` freed, and when hp == 0 ∧ armed: 424 at `+0xe` (`.STPlay3DSound`), `.DestroyCrunchTile(+0x154,
    ///   +0x158, +0x15c, 1, 1, 0)` and the log; else face `+0x14c − hp` (0…2, otherwise `ReportError("Crunch sprite face
    ///   out of range")` and the face is left).
    /// - 1040, 3099 and every other id below 3250 (below); 3250 and up: no branch (the balloons stand still).
    /// then x += vx, y += vy, the pixel copies `+8 = +0xc`, `+6 = +0xa` from 24.8 (not for 0x596, l. 54274),
    /// `.StandardSpriteCleanup`.
    ///
    /// This form (no light table) is the test-only one: its light calls go to a scratch table.
    public static func handle(world w: SpriteWorld, id: Int, effects: Int16 = 1,
                              faceWidth: (FaceRef) -> Int = EffectSprite.faceWidth) {
        var scratch = LightTable()
        handle(world: w, id: id, lights: &scratch, effects: effects, faceWidth: faceWidth)
    }

    /// LT: `handle` with its `.AddLight` / `.RemoveLight` / `.ChangeLightFace` calls made on `lights` (the session's
    /// `lightTable`). EF: `effects` is prefs+6 (`_DAT_1009fe44 + 6`, the debris fade).
    public static func handle(world w: SpriteWorld, id: Int, lights: inout LightTable, effects: Int16 = 1,
                              faceWidth: (FaceRef) -> Int = EffectSprite.faceWidth) {
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
        case plume:
            w.active.update(id: id) { p in
                p.lightOverlay = false
                p.mode = 0xb0004
                p.phase &+= 1
                if p.phase < 0x22 {
                    p.face = FaceRef(pict: plume, index: Int(p.phase), set: .encoded)
                } else {
                    p.dead = true
                    p.face = nil
                }
            }
            if w.active.record(id: id)?.dead == true { w.plumeCount &-= 1 }
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
            // face 0, `.RemoveLight(+0x9a)` (the bubble has none: −1, a no-op), killed; then straight to the tail (`b
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
                    lights.remove(&p.light)
                    p.dead = true
                }
            }
        case debris:
            // 3099 (l. 54163–54198): `+0x46` += 1, past 7 → 0; `.ApplyGravityAndSeparateFromTiles` (its tile callback
            // counts the FG bounces); vy += `+0x110`; face `+0x46` (+ 8 when `+0x14c`, the second row) of PICT 3099;
            // `+0x16c` > 3 → killed (the face stays); prefs+6 == 1 → `+0xb8` by `+0x16c`: 1 → 0xb0001, 0 → 0,
            // 2 → 0xb0000, else (≥ 3 or < 0) 0xb0002.
            w.active.update(id: id) { p in
                p.phase &+= 1
                if 7 < p.phase { p.phase = 0 }
            }
            TileSolver(world: w).applyGravityAndSeparate(id, pass: { hitTile($0, id: $1, pos: $2, kind: $3, layer: $4) })
            w.active.update(id: id) { p in
                p.vy &+= Int32(p.gravity)
                p.face = FaceRef(pict: debris, index: Int(p.phase) + (p.classTimer == 0 ? 0 : 8), set: .encoded)
                if 3 < p.classWord16c { p.dead = true }
                if effects == 1 {
                    switch p.classWord16c {
                    case 1: p.mode = 0xb0001
                    case 0: p.mode = 0
                    case 2: p.mode = 0xb0000
                    default: p.mode = 0xb0002
                    }
                }
            }
        case 0x4b2...0x4b5, 0x4c4, 0x4e3, 0x726, -1:
            // 1202…1204 (static faces, killed below the view), 1205, the countdown's `.UpdateDigits` (its faces stay 0
            // while `iRam100a5110` < −0x1d — always so far), 1251, 1830, −1: // later: their spawners' tasks.
            break
        default:
            if s.type < 0xcb2 { explosion(w, id: id, lights: &lights) }
            // ≥ 0xcb2 (the balloons 3250 / 3250 + n): no branch (l. 54209: `iVar6 < 0xcb2` fails).
        }
        w.active.update(id: id) { p in
            p.x256 &+= p.vx
            p.y256 &+= p.vy
            guard p.type != 0x596 else { return }
            let x = SpriteWorld.pixel(p.x256), y = SpriteWorld.pixel(p.y256)
            p.oldPosition = SpriteSlot.Point(x: x, y: y)
            p.x = x
            p.y = y
        }
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
    }

    /// The `type < 0xcb2` arm (l. 54209–54255) — ids 0…15, 1090 (the cannon smoke), 1207, 3201 and every other id
    /// below 3250 without its own arm: 0 < id < 0x10 → `+0xb8 = 0x10000 + id`; 0x442 → 0x10005; `+0x46` += 1; the
    /// light schedule on `+0x9a` (`lightSchedule`: `.ChangeLightFace(+0x9a, PTR_DAT_100a088c[i])`, 0x17 →
    /// `.RemoveLight(+0x9a)`; a −1 slot makes them no-ops, raw `1001bdbc` / `1001bd34`); `+0x46` < 0x1a → face
    /// `+0x46 >> 1` of PICT 1200 — for 0x4b7 first `.ApplyGravityAndSeparateFromTiles`, then PICT 1207's (the `+4 == −1`
    /// test inside is dead: −1 has its own arm) — else killed and face 0.
    static func explosion(_ w: SpriteWorld, id: Int, lights: inout LightTable) {
        w.active.update(id: id) { p in
            if 0 < p.type && p.type < 0x10 { p.mode = 0x10000 + UInt32(p.type) }
            if p.type == BackgroundSprite.smoke { p.mode = 0x10005 }
            p.phase &+= 1
            if let i = lightSchedule[p.phase] {
                let f = BonusHandle.twinkleFaces[i]
                lights.changeFace(p.light, LightFaceRef(pict: f.pict, width: f.width, height: f.height))
            } else if p.phase == 0x17 {
                lights.remove(&p.light)
            }
        }
        guard let s = w.active.record(id: id) else { return }
        guard s.phase < 0x1a else {
            w.active.update(id: id) { p in
                p.dead = true
                p.face = nil
            }
            return
        }
        if s.type == bigExplosion {
            TileSolver(world: w).applyGravityAndSeparate(id, pass: { hitTile($0, id: $1, pos: $2, kind: $3, layer: $4) })
        }
        w.active.update(id: id) { p in
            p.face = FaceRef(pict: p.type == bigExplosion ? bigExplosion : explosionSheet, index: Int(p.phase >> 1),
                             set: .encoded)
        }
    }
}
