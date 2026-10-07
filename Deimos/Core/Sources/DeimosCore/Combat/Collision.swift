import Foundation
import HectorResources

/// The per-tick player cache of `FUN_10033850` (`10033894..100339c4`, damage-health-death §2.3, HIGH): built once
/// per tick before the entity loop, read by every entity's player-collision step (and by the crosshair test of
/// C12, `100343ac..100344e8`). A local value of the entity update — never stored on `GameState`.
public struct PlayerCollisionCache: Equatable, Sendable {
    /// One player slot (`FUN_10005d20(p)`, p = 0, 1).
    public struct Slot: Equatable, Sendable {
        /// The slot counts (player state +0xc6 == 4 when the cache was built; cleared when the player leaves
        /// state 4 during a hit — `100342f0..100342f8`). Stack array r1+0x40.
        public var active = false
        /// `FUN_10012a00(player)` — the player's Mac rect (r1+0xfc + 16·p).
        public var rect = MacRect(top: 0, left: 0, bottom: 0, right: 0)
        /// `FUN_100128d0(player +0x2cc)` — the crosshair position (r1+0xc4 + 8·p).
        public var crosshairX: Float = 0
        public var crosshairY: Float = 0
        /// Player +0x361 (handler +0x121) at cache time (r1+0x3c + p).
        public var crosshairFlag = false
        /// `FUN_100128d0(player)` — the ship's position (r1+0xd4 + 8·p).
        public var x: Float = 0
        public var y: Float = 0
        /// `float(bottom − top) × 0.5` (`1003397c..10033998`: int → float, `fmuls` by `0x100d7204` = 0.5).
        public var radius: Float = 0

        public init() {}
    }

    public var slots: [Slot] = [Slot(), Slot()]
    /// r22: the active slots (`10033928 addi r22,r22,0x1`; −1 per dropped slot, `100342f8`).
    public var activeCount: Int32 = 0
    /// r24 = trunc(flli 54 VisibleGameWidth) + 32 (`10033894..100338b0`) — 448 in the shipped data.
    public var right: Int32 = 0
    /// r23 = trunc(flli 55) (`100338a4..100338d4`) — 480.
    public var bottom: Int32 = 0

    public init() {}
}

/// Collisions (damage-health-death.md §2; loose-ends-combat §3.1; plan C11a). Every hit is an inclusive
/// bounding-box overlap, then the circle test `FUN_10042f80` with radius = half the bounding-box height.
///
/// Listing reads (`disasm-review3-all.txt`): `FUN_10042f80` (`10042f80..1004302c`), the player cache and the
/// player-collision step of `FUN_10033850` (`10033894..100339c4`, `10034068..10034314`), the hittable flag
/// (`10033ea0..10033ec8`), the obstacle step (`100344ec..10034570`) and the entity ↔ entity call (`10034574..
/// 10034594`), `FUN_10036cf0` (`10036cf0..10037128`).
extension GameState {
    /// `FUN_10042f80(posA, —, posB, rA, rB)` — `dy = A.y − B.y`, `dx = A.x − B.x` (`fsubs`), `d² = trunc(fmadds(dx,
    /// dx, dy·dy))` (`fmuls` then the fused add, `fctiwz`), `dist = d² < 0x4000 ? sqrtTable[d²] : (float)sqrt(
    /// (double)(float)d²)` (`10042fc8..10043008`) — `Trig.root`; returns `dist < rA + rB` (`fadds`, `fcmpo` LT bit:
    /// **strict**).
    public static func circlesOverlap(ax: Float, ay: Float, bx: Float, by: Float, ra: Float, rb: Float) -> Bool {
        let dy: Float = ay - by                                          // 10042f9c..10042fa8
        let dx: Float = ax - bx                                          // 10042fa4..10042fb0
        let sum = (dy * dy).addingProduct(dx, dx)                        // 10042fb4..10042fb8
        let dist = Trig.root(EntityDraw.fctiwz(sum))                     // 10042fbc..10043008
        return dist < ra + rb                                            // 1004300c..10043018
    }

    /// `FUN_10012ad0(e, &l, &t, &r, &b)` — the same four values as `FUN_10012a00` (`boundingBox`), as the listing
    /// computes them (`10012ad0..10012b98`); the Mac rect is the shared value type.
    func entityRect(_ i: Int) -> MacRect { boundingBox(i) }

    /// The signed half of a rect's height (`subf; rlwinm r0,r3,1,31,31; add; srawi r0,r0,1` — C division,
    /// `10034180..10034190`, `10036f60..10036f8c`) as a float (exact).
    static func collisionRadius(_ r: MacRect) -> Float {
        Float((r.bottom &- r.top) / 2)
    }

    /// The per-tick player cache, `10033894..100339c4` (see `PlayerCollisionCache`). Built only when the active
    /// group list is not empty (`10033880..10033890`: count < 1 skips the whole update — the caller's test).
    public func playerCollisionCache() -> PlayerCollisionCache {
        var c = PlayerCollisionCache()
        c.right = EntityDraw.fctiwz(assets.floats[54]) &+ 32             // 10033894..100338b0
        c.bottom = EntityDraw.fctiwz(assets.floats[55])                  // 100338a4..100338d4
        for p in 0..<2 {                                                 // 100338d8..100339c4
            guard players.indices.contains(p), players[p].lifeState == 4 else { continue }   // 100338e0..10033900
            var s = PlayerCollisionCache.Slot()
            s.active = true                                              // 10033914..1003391c
            c.activeCount &+= 1                                          // 10033928
            let o = players[p].object
            let hw = Float(o.halfWidth), hh = Float(o.halfHeight)        // 1003392c FUN_10012a00
            s.rect = MacRect(top: EntityDraw.fctiwz(o.y - hh), left: EntityDraw.fctiwz(o.x - hw),
                             bottom: EntityDraw.fctiwz(o.y + hh), right: EntityDraw.fctiwz(o.x + hw))
            s.crosshairX = players[p].handler.crosshair.x                // 10033934..10033940
            s.crosshairY = players[p].handler.crosshair.y
            s.crosshairFlag = players[p].handler.crosshairLocked         // 10033948..10033954
            s.x = o.x; s.y = o.y                                         // 10033958..10033960
            s.radius = Float(s.rect.bottom &- s.rect.top) * Float(0.5)   // 10033968..1003399c
            c.slots[p] = s
        }
        return c
    }

    /// The hittable flag `+0xac` (damage §2.6, `10033ea0..10033ec8`): set, then cleared unless visibility
    /// (+0x68) ≥ 100.0 (`fcmpo; bge` — unordered keeps it) or the unit is `hittableWhenInvisible` (+0x121).
    public mutating func updateHittable(_ i: Int) {
        let vis = world.entities[i].object.visibility
        let u = assets.definitions.units[world.entities[i].unit]
        world.entities[i].hittable = !(vis < 100) || u.hittableWhenInvisible
    }

    /// The player-collision step of `FUN_10033850` for entity `i` at game time `now` (damage §2.3, loose-ends-combat
    /// §3.1; listing `10034074..10034314`). The caller has checked the entity is spawned in and not deleted
    /// (`10034068`). **`state` is the entity update's r18** — the state read before the motion controller
    /// (`10033e08`), never re-read here: a state change during the update (timer, rule, range trigger) does not
    /// reach this step until the next tick. nil (a state index outside the unit's states; the original has no
    /// check and would read past the unit) → no test. Rect `FUN_10012ad0`; tested only if `cache.activeCount > 0`,
    /// the state `Collides` (+0x347), the
    /// unit not `harmlessToPlayers` (+0x11a), the state `CollidesWithPlayers` (+0x34f), and `r ≥ −32`, `l ≤
    /// cache.right`, `b ≥ 0`, `t ≤ cache.bottom`. Then per slot p = 0, 1, while the entity is not deleted
    /// (`10034110`): an active slot, the inclusive box overlap (`e.b ≥ p.t`, `e.t ≤ p.b`, `e.r ≥ p.l`, `e.l ≤ p.r`),
    /// the circle test (player position and radius vs the entity's, radius = signed half height); on a hit:
    /// - `pickup_Type_ID` ≠ `none` → `collectPickup`; consumed → `destroyEntity(i, killer: player index (+0xcc), now)`
    ///   then `+0xca` = 1 (`100341d0..10034224`);
    /// - else the ram: flli 161 (100) to the owner when the state `passHitsToOwner` (+0x32b) and the owner link is
    ///   valid (`FUN_10036ab0`), else to the entity, credited to the player index (`10034228..100342b8`); then the
    ///   player takes the unit's `damage_FLOAT` (`100342bc..100342d0`); the player out of state 4 → the slot drops
    ///   (`100342d8..100342f8`).
    public mutating func collideWithPlayers(_ i: Int, state st: UnitState?, cache: inout PlayerCollisionCache,
                                            now: Int32) {
        let er = entityRect(i)                                           // 10034074..10034088 FUN_10012ad0
        guard cache.activeCount > 0, let st, st.stateCollides else { return }     // 10034090..100340a0 (r18)
        let ui = world.entities[i].unit                                  // r31
        guard !assets.definitions.units[ui].harmlessToPlayers, st.stateCollidesWithPlayers else { return }   // 100340a4..100340b8
        guard er.right >= -32, er.left <= cache.right, er.bottom >= 0, er.top <= cache.bottom else { return }   // 100340bc..100340e8
        let ex = world.entities[i].object.x, ey = world.entities[i].object.y      // 100340ec..100340f4
        let er2 = Self.collisionRadius(er)                               // 10034180..100341bc
        for p in 0..<2 {                                                 // 100340fc..10034314
            guard !world.entities[i].deleted else { return }             // 10034110..10034118
            let slot = cache.slots[p]
            guard slot.active else { continue }                          // 1003411c..10034124
            let pr = slot.rect
            guard er.bottom >= pr.top, er.top <= pr.bottom, er.right >= pr.left, er.left <= pr.right
            else { continue }                                            // 10034128..1003417c
            guard Self.circlesOverlap(ax: slot.x, ay: slot.y, bx: ex, by: ey, ra: slot.radius, rb: er2)
            else { continue }                                            // 100341c0..100341cc
            if assets.definitions.units[ui].pickupType != .none {        // 100341d0..100341dc
                if collectPickup(player: p, entity: i) {                 // 100341e0..100341f8 FUN_10037580
                    destroyEntity(i, killer: players[p].index, now: now) // 100341fc..10034214 FUN_10026c90, FUN_10016300
                    world.entities[i].collected = true                   // 1003421c..10034220
                }
                continue
            }
            let ram = assets.floats[161]                                 // 1003425c..10034260 / 1003429c..100342a0
            var passed = false
            if st.passHitsToOwner, ownerLinkValid(i), let o = world.entities[i].owner {   // 10034228..10034244
                damageEntity(o, damage: ram, killer: players[p].index, now: now)          // 10034248..10034274
                passed = true
            }
            if !passed {                                                 // 10034280..10034284
                damageEntity(i, damage: ram, killer: players[p].index, now: now)          // 10034288..100342b4
            }
            playerHit(p, damage: assets.definitions.units[ui].damage, now: now)   // 100342bc..100342d0 FUN_10027100
            if players[p].lifeState != 4 {                               // 100342d8..100342ec FUN_10026c50
                cache.slots[p].active = false                            // 100342f0..100342f4
                cache.activeCount &-= 1                                  // 100342f8
            }
        }
    }

    /// The ground-obstacle step of `FUN_10033850` (damage §2.4, `100344ec..10034570`): entity not stationary
    /// (+0x13c), not an air-group entity (object +0x19), the unit `collidesWithGroundObstacles` (+0x128), and its
    /// Mac rect touches a debris rect (`FUN_1002a830`) → velocity (+0x10/+0x14) = 0.0, +0x13c = 1, and with
    /// `destructCreateObstacle` (+0x4b3) its rect (recomputed, `10034558..10034560`) is appended (`FUN_1002a6d0`).
    public mutating func collideWithObstacles(_ i: Int) {
        guard !world.entities[i].stationary, !world.entities[i].object.air else { return }   // 100344ec..10034500
        let u = assets.definitions.units[world.entities[i].unit]
        guard u.collidesWithGroundObstacles else { return }              // 10034504..1003450c
        guard debris.hits(boundingBox(i)) else { return }                // 10034510..10034530
        world.entities[i].object.vx = 0                                  // 10034534..10034544 (0x100d7194 {0, 0})
        world.entities[i].object.vy = 0
        world.entities[i].stationary = true                              // 10034548
        if u.destructCreateObstacle {                                    // 1003454c..10034554
            debris.add(boundingBox(i))                                   // 10034558..1003456c
        }
    }

    /// The entity ↔ entity step of `FUN_10033850` (`10034574..10034594`): entity `a` not deleted and **`state`** (the
    /// update's r18, read before the motion controller at `10033e08` — not re-read) `Collides` (+0x347) →
    /// `collideWithEntities(a, now)`. nil state (out of range; the original has no check) → nothing.
    public mutating func entityCollisionStep(_ a: Int, state st: UnitState?, now: Int32) {
        guard !world.entities[a].deleted, let st, st.stateCollides else { return }   // 10034574..10034588
        collideWithEntities(a, now: now)                                 // 1003458c..10034594
    }

    /// `FUN_10036cf0(A, now) @ 10036cf0` — entity ↔ entity for A = entity `a` (damage §2.5, HIGH; listing
    /// `10036cf0..10037128`). Returns A's deleted byte (`10037114`). The caller runs it last in A's update when A
    /// is not deleted and its state `Collides` (`10034574..10034594`).
    /// - Empty group list → return (`10036d0c..10036d20`). A's state, rect, serial, layer (unit +8), harmless and
    ///   playerProjectile are read once (`10036d24..10036da0`); a playerProjectile A needs `A.b ≥ 0`
    ///   (`10036d64..10036d78`).
    /// - **Counts taken once**: the group count at entry (r26, `10036d18`) and each group's member count when the
    ///   group is reached (r31, `10036dc8`) — entities or groups created by a hit during the scan are not visited.
    /// - B is a candidate (`10036e18..10036ebc`): B's state `Collides`; not deleted; hittable (+0xac); serial ≠ A's;
    ///   same layer; exactly one of A/B `harmlessToPlayers`; spawned in (`+0xb0 ≤ 0`); A playerProjectile → B
    ///   `canBeHitByPlayerProjectile`, else B both `canBeHitByPlayerProjectile` and `playerProjectile`. A
    ///   playerProjectile B needs `B.b ≥ 0` (`10036edc..10036ef4`).
    /// - Inclusive box overlap (`A.b ≥ B.t`, `A.t ≤ B.b`, `A.r ≥ B.l`, `A.l ≤ B.r`), the circle test (A's position
    ///   and radius vs B's).
    /// - Hit: A takes `B.damage` credited to `B+0xd8` — to A's owner instead when A's state (read at entry)
    ///   `passHitsToOwner` and A's owner link is valid (`10036fc4..10037054`); then B's state is re-read and, when it
    ///   `passHitsToOwner` and **A's** owner link is valid, **A's owner** takes `A.damage` (the listing's copy-paste
    ///   bug, kept — `10037058..100370cc`), else B takes `A.damage`, credited to `A+0xd8` (`100370d0..100370ec`).
    ///   A deleted → stop (`100370f0..100370f8`).
    @discardableResult
    public mutating func collideWithEntities(_ a: Int, now: Int32) -> Bool {
        let groupCount = world.groups.count                              // 10036d0c..10036d18 (taken once)
        guard groupCount >= 1 else { return world.entities[a].deleted }  // 10036d1c..10036d20
        let uaIndex = world.entities[a].unit                             // 10036d24 (r27)
        let units = assets.definitions.units
        let aPasses = statePassesHits(a)                                 // 10036d28..10036d38 FUN_10014650 (r28, read once)
        let ar = entityRect(a)                                           // 10036d40..10036d5c
        let aProjectile = units[uaIndex].playerProjectile                // 10036d9c (r30)
        if aProjectile && ar.bottom < 0 { return world.entities[a].deleted }   // 10036d64..10036d78
        let ax = world.entities[a].object.x, ay = world.entities[a].object.y   // 10036d7c..10036d84
        let serialA = world.entities[a].serial                           // 10036d94 (r24)
        let aHarmless = units[uaIndex].harmlessToPlayers                 // 10036d98 (r29)
        let aLayer = units[uaIndex].layer                                // 10036da0 (r23)
        let aDamage = units[uaIndex].damage                              // read at 100370bc / 100370d8 (constant)
        let ra = Self.collisionRadius(ar)                                // 10036f48..10036fac
        var g = 0
        while g < groupCount, g < world.groups.count {                   // 10036da8..10037110
            let memberCount = world.groups[g].members.count              // 10036db8..10036dc8 (taken once)
            var k = 0
            while k < memberCount, k < world.groups[g].members.count {   // 10036dec..10037104 (lists only grow mid-pass)
                let b = world.groups[g].members[k]
                k += 1
                guard stateCollides(b) else { continue }                 // 10036e0c..10036e20
                guard !world.entities[b].deleted, world.entities[b].hittable,
                      world.entities[b].serial != serialA else { continue }          // 10036e24..10036e44
                let ub = world.entities[b].unit
                guard units[ub].layer == aLayer else { continue }        // 10036e48..10036e54
                guard aHarmless != units[ub].harmlessToPlayers else { continue }     // 10036e58..10036e7c
                guard world.entities[b].spawnCountdown <= 0 else { continue }        // 10036e80..10036e88
                if aProjectile {                                         // 10036e8c..10036e9c
                    guard units[ub].canBeHitByPlayerProjectile else { continue }
                } else {                                                 // 10036ea0..10036ebc
                    guard units[ub].canBeHitByPlayerProjectile, units[ub].playerProjectile else { continue }
                }
                let br = entityRect(b)                                   // 10036ec0..10036ed4
                if units[ub].playerProjectile && br.bottom < 0 { continue }          // 10036edc..10036ef4
                guard ar.bottom >= br.top, ar.top <= br.bottom, ar.right >= br.left, ar.left <= br.right
                else { continue }                                        // 10036ef8..10036f34
                let bx = world.entities[b].object.x, by = world.entities[b].object.y // 10036f38..10036f40
                guard Self.circlesOverlap(ax: ax, ay: ay, bx: bx, by: by, ra: ra, rb: Self.collisionRadius(br))
                else { continue }                                        // 10036f48..10036fc0
                let bDamage = units[ub].damage
                // 1. A takes B's damage, credited to B+0xd8.
                var passed = false
                if aPasses, ownerLinkValid(a), let o = world.entities[a].owner {     // 10036fc4..10037010
                    damageEntity(o, damage: bDamage, killer: world.entities[b].ownerPlayer, now: now)   // 10037014..10037028
                    passed = true
                }
                if !passed {                                             // 10037034..10037038
                    damageEntity(a, damage: bDamage, killer: world.entities[b].ownerPlayer, now: now)   // 1003703c..10037050
                }
                // 2. B takes A's damage, credited to A+0xd8 — B's passHitsToOwner redirects to A's owner (bug kept).
                passed = false
                if statePassesHits(b), ownerLinkValid(a), let o = world.entities[a].owner {  // 10037058..100370b0 (B re-read)
                    damageEntity(o, damage: aDamage, killer: world.entities[a].ownerPlayer, now: now)   // 100370b4..100370c4
                    passed = true
                }
                if !passed {                                             // 100370d0..100370d4
                    damageEntity(b, damage: aDamage, killer: world.entities[a].ownerPlayer, now: now)   // 100370d8..100370e8
                }
                if world.entities[a].deleted { return true }             // 100370f0..100370f8
            }
            g += 1
        }
        return world.entities[a].deleted                                 // 10037114
    }

    /// `FUN_10014650(e)+0x347` / `+0x32b` read in place (no copy of the state). A state index outside the unit's
    /// states reads false — the original has no check (it would read past the unit; out of range only).
    private func stateCollides(_ i: Int) -> Bool {
        let u = world.entities[i].unit, st = Int(world.entities[i].state)
        guard u >= 0, assets.definitions.units[u].states.indices.contains(st) else { return false }
        return assets.definitions.units[u].states[st].stateCollides
    }

    private func statePassesHits(_ i: Int) -> Bool {
        let u = world.entities[i].unit, st = Int(world.entities[i].state)
        guard u >= 0, assets.definitions.units[u].states.indices.contains(st) else { return false }
        return assets.definitions.units[u].states[st].passHitsToOwner
    }
}
