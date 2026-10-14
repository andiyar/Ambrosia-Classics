import Foundation

/// The player's tile callback `+0x1f8` = `.HitPlayerTileSprite(s, pos, kind, layer) @ 10054ca8` (plan P2; decompile
/// l. 48113–48358, raw `10054ca8..10055408`; player-states §5, physics §3.1). `Player.handle` installs it by default;
/// the tile solver calls it from each `.SeparateFromTiles2` (three passes per frame: pre-move row 19, the move row 27,
/// the end pass row 40 — the only one with `PTR_DAT_100a0704` set, so the only one that reaches the water arm).
///
/// At entry the hot rect `+0x34` and its centre offsets (`sStack_70` x = l + (r − l) >> 1, `sStack_72` y = t + (b − t)
/// >> 1; srawi) are taken once (raw `10054ce8..10054d34`). Spirit form (`_DAT_100a0578`, `lha`: the high half of the
/// long — no Phase-2 writer) returns at once. Then, by layer:
/// - **BG (layer 0)**, after the walk-on-liquid rewrite (`PTR_DAT_100a0648` ∧ BG ∧ `kind − 200 == 063c` → layer 1, kind
///   3, `pos.y −= 16`; raw `10054d4c..10054d94`; // later: Phase 4 — no Phase-2 writer): kind < 100 → `.WallBounce`
///   + `.CheckGroundCeilingHitEffects`; < 200 → `.WallBounceBG(kind − 100)`, a hit while `+0xce` ≠ 0 sets the one-way
///   timer `04cc = 0xf`, then the effects; 600 / 601 → nothing; `.IsWaterTile` (200…209) ∧ the water pass ∧ `+0x140`
///   == 0 → `.HandleUnderWater(s, pos)` (P4).
/// - **FG (layer 1)**: the cling test, the post-jump guard `04d8 > 0` → return (no `.WallBounce`, no effects), then
///   `.WallBounce(s, kind, &pos, &sStack_72, 0, +0x34, 0, 0)`, the carpet arm on a hit, and the effects.
/// - **Crunch (layer 2)**: `+0xeb` = (`060c` == 0 ∧ vy > 0x9c4), `.CrunchTile(pos, +0xeb)`, and on a crunch with
///   `+0xeb` the −0.9 bounce off the 2×2 block (`.RectBounceFake2`) with the spin on DOWN.
///
/// Keys: each `.IsInputKeyPressed` reads the frame's one snapshot (plan Hazards) — the callback captures it.
public enum PlayerTiles {
    /// −0.9 (f64 `dRam100a1a20` = `0xbfeccccccccccccd`): the crunch bounce factor (raw `1005531c lfd f2,-0x5e20(r2)`).
    static let crunchBounce = Double(bitPattern: 0xbfec_cccc_cccc_cccd)
    /// `_DAT_100a624c`: the rect `(−2, −2, 0x22, 0x22)` (top, left, bottom, right) `.RectBounceFake2` separates the
    /// player from, around the crunch point.
    static let crunchRect = IdleSprites.Rect(top: -2, left: -2, bottom: 0x22, right: 0x22)

    /// `.HitPlayerTileSprite` with this frame's keys, as a `TileHit`.
    public static func hit(keys: InputActions) -> TileHit {
        { solver, id, cell, kind, layer in
            hitPlayerTileSprite(solver, id: id, pos: cell, kind: kind, layer: layer, keys: keys)
        }
    }

    /// `.HitPlayerTileSprite(s, pos, kind, layer)`.
    public static func hitPlayerTileSprite(_ solver: TileSolver, id: Int, pos posIn: TilePos, kind kindIn: Int,
                                           layer layerIn: TileLayer, keys: InputActions) {
        let w = solver.world
        guard let s0 = w.active.sprite(id: id) else { return }
        let h = TileSolver.short16
        let r = s0.hotRect
        let cx = h(r.left + ((r.right - r.left) >> 1))                 // `sStack_70`
        let cy = h(r.top + ((r.bottom - r.top) >> 1))                  // `sStack_72`
        // Spirit form: `lha` of the long `_DAT_100a0578` (raw `10054d3c..10054d48`). // later: Phase 4.
        if Int16(truncatingIfNeeded: w.player.spiritTimer >> 16) > 0 { return }
        var pos = posIn
        var kind = kindIn
        var layer = layerIn
        if w.player.walkOnLiquid && layer == .background
            && Int16(truncatingIfNeeded: kind - 200) == w.player.walkOnLiquidKind {
            layer = .foreground
            kind = 3
            pos.y = h(pos.y - 0x10)
        }
        switch layer {
        case .foreground:
            foreground(solver, id: id, pos: pos, kind: kind, cx: cx, cy: cy, keys: keys)
        case .crunch:
            crunch(solver, id: id, pos: pos, cx: cx, cy: cy, keys: keys)
        case .background:
            let k = Int(Int16(truncatingIfNeeded: kind))
            if k < 100 {
                solver.wallBounce(id, kind: kind, tile: &pos, vCentre: cy, factor: 0, rect: r, bounce: false)
                GroundCeilingEffects.check(w, id: id)
            } else if k < 200 {
                let hit = solver.wallBounceBG(id, kind: kind - 100, tile: &pos, vCentre: cy, factor: 0, rect: r,
                                              bounce: false)
                if hit && (w.active.sprite(id: id)?.groundKind ?? 0) != 0 { w.player.oneWayTimer = 0xf }
                GroundCeilingEffects.check(w, id: id)
            } else if UInt16(truncatingIfNeeded: kind - 600) < 2 {
                return
            } else if LiquidTiles.range.contains(k), w.player.waterPass, !(w.active.sprite(id: id)?.underwaterDone ?? true) {
                // `.HandleUnderWater(s, pos) @ 10042e30` (P4); its entry `.Splash(s, 3)` (E1a).
                UnderWater.handle(world: w, id: id, pos: pos)
            }
        }
    }

    /// The FG arm (raw `10054da4..10055180`).
    static func foreground(_ solver: TileSolver, id: Int, pos posIn: TilePos, kind: Int, cx: Int, cy: Int,
                           keys: InputActions) {
        let w = solver.world
        let h = TileSolver.short16
        guard let s = w.active.sprite(id: id) else { return }
        var pos = posIn
        // kind mod 100 (C remainder, `mulhw` by 0x51eb851f), and dy = ((y256 >> 8) + cy) − (Y + 16) as i16.
        let k = Int(Int16(truncatingIfNeeded: kind)) % 100
        let dy = h(Int(s.y256 >> 8) + cy - (pos.y + 0x10))
        var cling = false                                               // bVar1
        var ledge = false                                               // bVar2
        var side: Int16 = 0                                             // r23
        let wasClimbing = w.player.lastClimb != 0                       // `PTR_DAT_100a0754`
        if s.vx < 0 {
            if keys.contains(.left) || wasClimbing {
                if k == 0 {
                    cling = true
                } else if k == 4 || k == 0x14 || k == 0x2d {
                    ledge = true
                    if dy > 0 { cling = true }
                } else if k == 5 && dy < 4 {
                    cling = true
                }
                side = 1
            }
        } else if s.vx > 0, keys.contains(.right) || wasClimbing {
            if k == 2 {
                cling = true
            } else if k == 7 || k == 0x13 || k == 0x2f {
                ledge = true
                if dy > 0 { cling = true }
            } else if k == 6 && dy < 4 {
                cling = true
            }
            side = 2
        }
        if cling && w.player.groundLast == 0 && !w.player.rope && w.player.noCling == 0 && !w.player.glider {
            if !wasClimbing {
                w.player.jumpCounter = 0                                // `_DAT_100a0764`
                let rate = w.rng.soundRate()                            // `.STPlay3DSoundRand` (raw `10054f70`)
                w.player.cue(PlayerCue(call: .threeDRand, snd: 455, priority: 1, volume: 0x3c,
                                       position: s.centre, rate: rate))   // `_DAT_100a0374`
            }
            w.player.climb = 1
            w.player.facing = side                                      // `_DAT_100a5f5a = r23 & 0xff`
            w.player.launched = false                                   // `_DAT_100a05b8`
            w.player.swim = 0                                           // `_DAT_100a0714`
            let left = s.vx < 0
            w.player.wallSide = left ? 1 : 2                            // `PTR_DAT_100a074c`
            w.active.update(id: id) { $0.mirrored = left }              // `+0x17e`
            if ledge && w.player.pullUp == 0 {
                if w.tiles.fgTile(col: pos.x >> 5, row: (pos.y >> 5) - 1) == -1 {
                    let y = w.active.sprite(id: id)!.y256
                    if h(Int(y >> 8) + cy - 4 - (pos.y + 0x10)) < 1 {
                        w.player.pullUp = 1                             // `_DAT_100a06a0`
                        w.player.cue(PlayerCue(call: .reg, snd: 416, priority: 1, volume: 0xab))   // `a03f0`
                    }
                } else {
                    w.active.update(id: id) { p in
                        p.y256 &+= 1000
                        let py = SpriteWorld.pixel(p.y256)
                        p.oldPosition.y = py                            // `+6`
                        p.y = py                                        // `+0xa`
                        p.vy = 0
                    }
                    w.player.climb = 1
                }
            }
            w.active.update(id: id) { p in
                p.vy = 0
                p.vx = 0
            }
        }
        // The post-jump guard (raw `1005508c..10055098`): no `.WallBounce`, no effects while it runs.
        if w.player.postJumpGuard > 0 { return }
        let r = w.active.sprite(id: id)!.hotRect
        let hit = solver.wallBounce(id, kind: kind, tile: &pos, vCentre: cy, factor: 0, rect: r, bounce: false)
        if hit {
            w.player.carpetLock = 2                                     // `*_DAT_100a059c = 2`
            if w.player.carpet, let carpetID = w.player.ridden, let me = w.active.sprite(id: id),
               let c = w.active.record(id: carpetID) {
                // The carpet arm (raw `100550e8..10055174`): ride it, its top under the feet, and stop it when vx <
                // 0x100 (the signed-compare idiom `eqv`/`subfc`/`addze`). // Phase 4 builds the carpet.
                w.active.update(id: id) { $0.ridden = carpetID }
                let top = Int(Int16(truncatingIfNeeded: me.y + me.hotRect.bottom - c.hotRect.top))
                w.active.update(id: carpetID) { p in
                    p.y = top
                    p.y256 = Int32(top) << 8
                    if me.vx < 0x100 { p.vx = 0 }
                }
            }
        }
        GroundCeilingEffects.check(w, id: id)
    }

    /// The crunch arm (raw `10055284..100553f4`).
    static func crunch(_ solver: TileSolver, id: Int, pos posIn: TilePos, cx: Int, cy: Int, keys: InputActions) {
        let w = solver.world
        let h = TileSolver.short16
        guard let s = w.active.sprite(id: id) else { return }
        let strength: UInt8 = (w.player.crunchCooldown == 0 && s.vy > 0x9c4) ? 1 : 0   // `PTR_DAT_100a060c`
        w.active.update(id: id) { $0.crunches = strength }
        guard CrunchTiles.crunchTile(w, pos: posIn, strength: strength) != 0 else { return }
        // The decompile omits it: `pos += (16, 16)` before the bounce (raw `100552cc..100552f0`) — the 36×36 rect is
        // centred on the 2×2 block.
        let pos = TilePos(x: h(posIn.x + 0x10), y: h(posIn.y + 0x10))
        guard let s1 = w.active.sprite(id: id), s1.crunches != 0 else { return }
        let bounced = TileSolver.fctiwz(crunchBounce * Double(s1.vy))   // `fmul; fctiwz` (raw `1005531c..10055340`)
        rectBounceFake2(w, id: id, pos: pos, rect: crunchRect, cx: cx, cy: cy, hotRect: s1.hotRect)
        w.active.update(id: id) { p in
            p.x256 = Int32(p.x) << 8
            p.y256 = Int32(p.y) << 8
        }
        if keys.contains(.down) {
            w.player.cue(PlayerCue(call: .reg, snd: 427, priority: 1, volume: 0xba))   // `_DAT_100a03cc`
            w.player.spin = true
            w.active.update(id: id) { p in
                p.vy = bounced
                if 0 < p.vy { p.vy = 0 &- p.vy }
            }
        } else {
            w.player.spin = false
            w.player.cue(PlayerCue(call: .stopIfPlaying, snd: 427))
            w.active.update(id: id) { $0.vy = 0 }
        }
        w.player.crunchCooldown = 5
        w.active.update(id: id) { $0.groundKind = 0 }
    }

    /// `.RectBounceFake2(s, pos, rect, centre, factor 0, hotRect) @ 1003ecc0` (decompile l. 36444–36540): the solid
    /// `pos + rect` against the mover's hot rect at `+0xc`/`+0xa` (`.SectRectFast`); on a hit the mover leaves along
    /// the shallower axis by its centre (`+0xc + cx`, `+0xa + cy`) against the solid's centre, and the 24.8 position is
    /// re-synced for an integer that changed. The `+0x84`/`+0x86` scaling by the factor (0) is not kept: no Phase-2
    /// writer, they stay 0 and ×0 keeps them 0.
    static func rectBounceFake2(_ w: SpriteWorld, id: Int, pos: TilePos, rect q: IdleSprites.Rect, cx: Int, cy: Int,
                                hotRect m: IdleSprites.Rect) {
        let h = TileSolver.short16
        guard let s = w.active.sprite(id: id) else { return }
        let solid = IdleSprites.Rect(top: h(pos.y + q.top), left: h(pos.x + q.left), bottom: h(pos.y + q.bottom),
                                     right: h(pos.x + q.right))
        let mover = IdleSprites.Rect(top: h(s.y + m.top), left: h(s.x + m.left), bottom: h(s.y + m.bottom),
                                     right: h(s.x + m.right))
        guard mover.intersects(solid) else { return }
        let x0 = s.x, y0 = s.y
        let mx = h(x0 + cx), my = h(y0 + cy)                            // sVar7, sVar5
        let sx = h(pos.x + q.left + ((q.right - q.left) >> 1))          // sVar6
        let sy = h(pos.y + q.top + ((q.bottom - q.top) >> 1))           // sVar4
        var x = x0, y = y0
        if mx < sx {
            if my < sy {
                if h(sy - my) < h(sx - mx) { x = h(solid.left - m.right) } else { y = h(solid.top - m.bottom) }
            } else if h(my - sy) < h(sx - mx) {
                x = h(solid.left - m.right)
            } else {
                y = h(solid.bottom - m.top)
            }
        } else if my < sy {
            if h(sy - my) < h(mx - sx) { x = h(solid.right - m.left) } else { y = h(solid.top - m.bottom) }
        } else if h(my - sy) < h(mx - sx) {
            x = h(solid.right - m.left)
        } else {
            y = h(solid.bottom - m.top)
        }
        w.active.update(id: id) { p in
            p.x = x
            p.y = y
            if x0 != x { p.x256 = Int32(x) << 8 }
            if y0 != y { p.y256 = Int32(y) << 8 }
        }
    }
}

/// Crunchable FG tiles (plan P2; triggers-background-2 §2.3): `.CrunchTile @ 10044928`, the crumble-overlay table
/// (`.FindCrunchSprite @ 10044788`, `.MakeCrunchSprite @ 1004481c`), `.DestroyCrunchTile @ 100445b0`,
/// `.ReshapeCrunchedTile @ 10043f14` and the map writes `.ChangeFGTile` / `.SetFGCrunchDirTile`, each emitting
/// `DrawOp.setTile` into `PlayerState.tileOps`.
///
/// An FG cell's bits 12–15 are the crunch direction (`.GetFGCrunchDirTile`), bits 8–11 the crunch kind
/// (`.GetFGCrunchKindTile`). A crunch cell (tx, ty) stands for the 2×2 block (tx…tx+1, ty…ty+1).
public enum CrunchTiles {
    /// `.CrunchTile(pos, strength)` (raw `10044928..10044c34`). Returns the routine's byte: 0 without a direction
    /// nibble; the crunch kind when strength is 0 and the kind is not 3 (the early exit returns the `.GetFGCrunchKindTile`
    /// register); else 1. Kind 0 breaks at once; kinds 1…4 take hits through the crumble overlay (hp 2): kind 2 / 4 need
    /// strength 2 / 4 (weaker → 423 only while not playing); kind 3 arms the overlay, which collapses on its own
    /// (`EffectSprite`) — even at strength 0.
    @discardableResult
    public static func crunchTile(_ w: SpriteWorld, pos: TilePos, strength: UInt8) -> UInt8 {
        let tx = Int(Int16(truncatingIfNeeded: pos.x >> 5)), ty = Int(Int16(truncatingIfNeeded: pos.y >> 5))  // srawi
        let dir = w.tiles.crunchDir(col: tx, row: ty)
        guard Int16(truncatingIfNeeded: dir) != 0 else { return 0 }
        let kind = Int16(truncatingIfNeeded: crunchKind(w, col: tx, row: ty))
        let p = Int16(strength)
        guard p != 0 || kind == 3 else { return UInt8(truncatingIfNeeded: kind) }
        var destroy = kind == 0
        if kind == 2 && p == 2 { destroy = true }
        if kind == 4 && p >= 4 { destroy = true }
        if p == 2 && kind < 4 { destroy = true }
        let point = SpriteSlot.Point(x: pos.x, y: pos.y)
        if UInt16(bitPattern: kind &- 1) <= 3 {
            var spr = findCrunchSprite(w, col: tx, row: ty)
            if (kind == 2 && p < 2) || (kind == 4 && p < 4) {
                // `if (!FUN_100916dc(423)) .STPlay3DSound(423, 1, 0x100, pos)` (raw `10044a50..10044a74`).
                w.player.cue(PlayerCue(call: .threeD, snd: 423, priority: 1, volume: 0x100, position: point,
                                       onlyIfIdle: true))
            } else if !destroy {
                if spr == nil && kind != 2 && kind != 4 {
                    spr = makeCrunchSprite(w, col: tx, row: ty, hp: 2)
                    if let o = spr {
                        w.active.update(id: o) { s in
                            s.classWord154 = Int32(tx)
                            s.classWord158 = Int32(ty)
                            s.classWord15c = Int32(Int16(truncatingIfNeeded: dir))
                            if kind == 3 { s.classWord16c = 1 }
                        }
                    }
                } else if let o = spr, w.active.record(id: o)?.phase == 0 {
                    w.active.update(id: o) { $0.hp &-= 1 }
                }
                if let o = spr, let rec = w.active.record(id: o) {
                    if rec.hp <= 0 {
                        destroy = true
                    } else if rec.phase == 0 {
                        w.player.cue(PlayerCue(call: .threeD, snd: 423, priority: 1, volume: 0x100,
                                               position: point))   // `_DAT_100a01e4`
                        let r = w.rng.next(3)                           // raw `10044b4c`
                        w.active.update(id: o) { s in
                            s.phase = r &+ 1
                            if kind == 3 { s.phase = 0xf }
                        }
                    }
                }
            }
        }
        if destroy {
            if let o = findCrunchSprite(w, col: tx, row: ty) { w.active.update(id: o) { $0.dead = true } }
            w.player.cue(PlayerCue(call: .threeD, snd: 424, priority: 1, volume: 0x100, position: point))
            destroyCrunchTile(w, col: tx, row: ty, dir: dir, explode: true, clearDir: true)
            log(w, col: tx, row: ty)
        }
        return 1
    }

    /// `.GetFGCrunchKindTile @ 1003bffc`: bits 8–11 of the (clamped) FG cell.
    static func crunchKind(_ w: SpriteWorld, col: Int, row: Int) -> Int {
        Int((w.tiles.fg.cell(col: col, row: row) >> 8) & 0xf)
    }

    /// The crunched-tile log (`G+0xad6` < 20000): level byte, row, column (raw `10044bc8..10044c14`).
    static func log(_ w: SpriteWorld, col: Int, row: Int) {
        guard w.globals.crunchLog.count < 20000 else { return }
        w.globals.crunchLog.append(CrunchLogEntry(level: Int8(truncatingIfNeeded: w.level.id),
                                                 col: Int16(truncatingIfNeeded: col),
                                                 row: Int16(truncatingIfNeeded: row)))
    }

    /// `.FindCrunchSprite(tx, ty)`: the first table slot whose sprite's pixel copy `+0xc`/`+0xa` is (tx·32 + 16,
    /// ty·32 + 16). An empty slot never matches [LOW: the original dereferences the null entry — low memory].
    static func findCrunchSprite(_ w: SpriteWorld, col: Int, row: Int) -> Int? {
        let x = Int(Int16(truncatingIfNeeded: col * 0x20 + 0x10)), y = Int(Int16(truncatingIfNeeded: row * 0x20 + 0x10))
        for slot in w.player.crunchSprites {
            guard let o = slot, let s = w.active.record(id: o) else { continue }
            if s.x == x && s.y == y { return o }
        }
        return nil
    }

    /// `.MakeCrunchSprite(tx, ty, hp)` (decompile l. 39137–39180): effect 1210 at (tx·32 + 16, ty·32 + 16) layer 0x32
    /// with `.SetupEffectSprite` — which stores layer 0xb before `.MTInsertSprite`, so the overlay sorts on layer 0xb;
    /// `+0xa4 = +0x14c = hp`, `+0x154 = tx`, `+0x158 = ty`; the first free table slot (`+0x150`), or, with all 40 in use,
    /// slot 0's sprite is killed and replaced (`+0x150 = 0`).
    static func makeCrunchSprite(_ w: SpriteWorld, col: Int, row: Int, hp: Int16) -> Int? {
        guard let o = w.newSprite(type: EffectSprite.crumble, x: Int(Int16(truncatingIfNeeded: col * 0x20 + 0x10)),
                                  y: Int(Int16(truncatingIfNeeded: row * 0x20 + 0x10)), layer: 0x32, handler: .effect,
                                  setup: { EffectSprite.setup(&$0) }) else { return nil }
        w.active.update(id: o) { s in
            s.hp = hp
            s.classTimer = Int32(hp)
            s.classWord154 = Int32(col)
            s.classWord158 = Int32(row)
        }
        if let slot = w.player.crunchSprites.firstIndex(where: { $0 == nil }) {
            w.player.crunchSprites[slot] = o
            w.active.update(id: o) { $0.classWord150 = Int32(slot) }
        } else {
            if let old = w.player.crunchSprites[0] { w.active.update(id: old) { $0.dead = true } }
            w.player.crunchSprites[0] = o
            w.active.update(id: o) { $0.classWord150 = 0 }
        }
        return o
    }

    /// `.DestroyCrunchTile(tx, ty, dir, explode, clearDir)` (raw `100445b0..100446f0`): the water-effects cache flag
    /// `*_DAT_100a00f4 = 0`; with `explode`, `.ExplodeCrunchedTile` on (tx, ty), (tx+1, ty), (tx, ty+1), (tx+1, ty+1)
    /// `.ExplodeCrunchedTile(col, row) @ 100444f0` (M l. 39042–39056): FG tile t of the cell, 0 ≤ t < 0x60 →
    /// `.ExplodeFaceIntoParticles(FG face t, (row << 5, col << 5), 2, 2, 2, 100, 100)` (E1a: 4 `FastRand` per emitted
    /// pixel, the faces from `particleFaces.fgTile`); then `.ReshapeCrunchedTile` at positions 5, 7, 6, 8 of the block (old tiles read
    /// cell by cell); with `clearDir`, the direction nibble of (tx, ty) → 0. `dir` is only passed on.
    static func destroyCrunchTile(_ w: SpriteWorld, col: Int, row: Int, dir: Int, explode: Bool, clearDir: Bool) {
        let tx = Int(Int16(truncatingIfNeeded: col)), ty = Int(Int16(truncatingIfNeeded: row))
        let tx1 = Int(Int16(truncatingIfNeeded: tx + 1)), ty1 = Int(Int16(truncatingIfNeeded: ty + 1))
        w.player.tileCacheValid = false
        if explode {
            // `.ExplodeCrunchedTile` ×4 (raw `10044608..10044634`) → `.ExplodeFaceIntoParticles` for each of the four
            // cells holding a tile 0…0x5f.
            for (c, r) in [(tx, ty), (tx1, ty), (tx, ty1), (tx1, ty1)] {
                let t = w.tiles.fgTile(col: c, row: r)
                guard 0 <= t && t < 0x60 else { continue }
                ExplodeFace.explode(w, face: w.particleFaces.fgTile(t), v: Int16(truncatingIfNeeded: r << 5),
                                    h: Int16(truncatingIfNeeded: c << 5), xStep: 2, yStep: 2, shape: 2, gravity: 100,
                                    style: 100)
            }
        }
        reshape(w, col: tx, row: ty, block: (tx, ty), position: 5, dir: dir, explode: explode, clearDir: clearDir)
        reshape(w, col: tx1, row: ty, block: (tx, ty), position: 7, dir: dir, explode: explode, clearDir: clearDir)
        reshape(w, col: tx, row: ty1, block: (tx, ty), position: 6, dir: dir, explode: explode, clearDir: clearDir)
        reshape(w, col: tx1, row: ty1, block: (tx, ty), position: 8, dir: dir, explode: explode, clearDir: clearDir)
        if clearDir { setFGCrunchDir(w, col: tx, row: ty, 0) }
    }

    /// `.ReshapeCrunchedTile(col, row, tx, ty, position, dir, explode, clearDir)` (raw `10043f14..100444c4`, the branch
    /// tree read from the disasm): k = the cell's tile when ≥ 0x50, else `.LookupFGTileKind(tile)`, hundreds stripped
    /// while > 100; then per position (5 = top-left, 7 = top-right, 6 = bottom-left, 8 = bottom-right) the new tile, and
    /// for the cascades a `.DestroyCrunchTile` of the neighbouring block (its 6th argument 1 is unused).
    static func reshape(_ w: SpriteWorld, col: Int, row: Int, block: (Int, Int), position: Int, dir: Int,
                        explode: Bool, clearDir: Bool) {
        let tile = Int16(truncatingIfNeeded: w.tiles.fgTile(col: col, row: row))
        var k = tile < 0x50 ? Int16(truncatingIfNeeded: w.tiles.fgKind(tile: Int(tile))) : tile
        while k > 100 { k &-= 100 }
        let (tx, ty) = block
        func change(_ t: Int) { changeFGTile(w, col: col, row: row, tile: t) }
        func cascade(_ c: Int, _ r: Int) {
            destroyCrunchTile(w, col: c, row: r, dir: dir, explode: explode, clearDir: clearDir)
        }
        switch position {
        case 5:
            switch k {
            case 2: change(6)
            case 3: change(4)
            case 7: change(-1)
            case 8: change(1)
            case 9: change(6); cascade(tx - 1, ty)
            case 0xa: change(0)
            case 0x18: change(0x14)
            case 0x1c: change(0x10)
            case 0x1e, 0x2a: change(0x12)
            case 0x5f: change(0xb)
            default: break
            }
        case 7:
            switch k {
            case 0: change(5)
            case 3: change(7)
            case 4: change(-1)
            case 9: change(2)
            case 0xa: change(5); cascade(tx + 1, ty)
            case 0xb: change(1)
            case 0x1f: change(0x13)
            case 0x5f: change(8)
            default: break
            }
        case 6:
            switch k {
            case 0xb: change(0)
            case 1: change(5)
            case 2: change(7)
            case 6: change(-1)
            case 8: change(5); cascade(tx, ty + 1)
            case 9: change(3)
            case 0x1b, 0x2e: change(0x17)
            case 0x1d: change(0x11)
            case 0x5f: change(0xa)
            default: break
            }
        case 8:
            switch k {
            case 0: change(4)
            case 1: change(6)
            case 5: change(-1)
            case 8: change(2)
            case 0xa: change(3)
            case 0xb: change(4); cascade(tx + 1, ty)
            case 0x1a: change(0x16)
            case 0x1c: change(0x10)
            case 0x5f: change(9)
            default: break
            }
        default:
            break
        }
    }

    /// The (col, row) `.ConstrainXY` makes of a map access: clamped into the grid.
    static func constrain(_ w: SpriteWorld, col: Int, row: Int) -> (Int, Int) {
        let m = w.tiles.fg
        return (min(max(col, 0), max(m.width - 1, 0)), min(max(row, 0), max(m.height - 1, 0)))
    }

    /// Writes one FG cell of `world.tiles` and records `DrawOp.setTile`.
    static func write(_ w: SpriteWorld, col: Int, row: Int, _ value: (UInt16) -> UInt16) {
        let m = w.tiles.fg
        guard m.width > 0, m.height > 0 else { return }
        let (c, r) = constrain(w, col: col, row: row)
        var cells = m.cells
        let v = value(cells[r * m.width + c])
        cells[r * m.width + c] = v
        w.tiles.fg = TileMap(width: m.width, height: m.height, cells: cells)
        w.player.tileOps.append(.setTile(col: c, row: r, fg: v))
    }

    /// `.ChangeFGTile(col, row, t) @ 100433e0` = `.SetFGTile` (`(cell & 0xff00) + (short)(char)(t + 1)`, raw
    /// `1003c648`) + `.ChangedTile` (the one-cell `.RedrawScrollGrid` — the renderer's on `setTile`).
    static func changeFGTile(_ w: SpriteWorld, col: Int, row: Int, tile t: Int) {
        write(w, col: col, row: row) { old in
            UInt16(truncatingIfNeeded: Int(old & 0xff00) + Int(Int8(truncatingIfNeeded: t + 1)))
        }
    }

    /// `.SetFGCrunchDirTile(col, row, d) @ 1003c710`: d clamped 0…15, `(cell & 0xfff) + d·0x1000`.
    static func setFGCrunchDir(_ w: SpriteWorld, col: Int, row: Int, _ d: Int) {
        let d = UInt16(min(max(d, 0), 0xf))
        write(w, col: col, row: row) { old in (old & 0x0fff) &+ d &* 0x1000 }
    }
}
