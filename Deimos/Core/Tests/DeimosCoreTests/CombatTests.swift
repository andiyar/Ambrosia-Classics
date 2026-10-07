import XCTest
import HectorResources
@testable import DeimosCore

/// Combat I (plan C11a): the circle test `FUN_10042f80`, the player-collision and obstacle steps of `FUN_10033850`,
/// entity ↔ entity `FUN_10036cf0`, entity damage `FUN_10014f10` with its per-victim hit delay, and the pickup switch
/// `FUN_10037580` (damage-health-death.md §2–§3, §6; loose-ends-combat.md §3). Shipped units only; `destroyEntity`
/// is C10's hook stub (C11b fills it), so a kill is observed as its flags (+0xcb, +0xd9, +0xda). The collision steps
/// take the entity update's pre-controller state (r18) as an argument; tests pass the current state or a modified
/// copy of it.
final class CombatTests: XCTestCase {
    /// A level-1 world (`le07`, sector 1) with P1 set up, level-started and respawned (state 4) at game time 100.
    private func world(seed: UInt32 = 0x469c2) throws -> GameState {
        let a = try TestAssets.loaded.get()
        var s = GameState(assets: a, prefs: DeimosPrefs.fresh, seed: seed)
        s.flags.numPlayers = 1
        s.flags.sector = 1
        s.flags.level = FourCC("le07")!
        s.scroll.levelStart(rect: MacRect(top: 0, left: 0, bottom: 3600, right: 480))
        try s.setupPlayer(0)
        try s.setupPlayer(1)
        s.playerLevelStart(0)
        s.playerLevelStart(1)
        s.flags.gameTime = 100
        s.respawnPlayer(0, now: 100)
        s.players[0].invulnerable = false
        XCTAssertEqual(s.players[0].lifeState, 4)
        XCTAssertGreaterThan(s.players[0].object.halfHeight, 0)
        return s
    }

    /// One shipped unit spawned through `FUN_10033220` at (x, y), spawned in; any further members this request
    /// created are flagged deleted so they take no part.
    @discardableResult
    private func put(_ s: inout GameState, _ id: String, x: Float, y: Float, player: Int8 = -1) throws -> Int {
        var req = SpawnRequest(unit: FourCC(id)!, x: x, y: y)
        req.player = player
        let before = Set(s.world.groups.flatMap(\.members))
        let r = try XCTUnwrap(s.spawn(req), id)
        for m in s.world.groups.flatMap(\.members) where m != r.entity && !before.contains(m) {
            s.world.entities[m].deleted = true
        }
        s.world.entities[r.entity].object.x = x
        s.world.entities[r.entity].object.y = y
        s.world.entities[r.entity].spawnCountdown = 0
        s.updateHittable(r.entity)
        return r.entity
    }

    private func size(_ s: inout GameState, _ i: Int, _ hw: Int32, _ hh: Int32) {
        s.world.entities[i].object.halfWidth = hw
        s.world.entities[i].object.halfHeight = hh
    }

    private func link(_ s: inout GameState, _ i: Int, owner o: Int) {
        s.world.entities[i].owner = o
        s.world.entities[i].ownerSerial = s.world.entities[o].serial
    }

    private func count(_ s: GameState, _ id: String) -> Int {
        let units = s.assets.definitions.units
        return s.world.entities.indices.filter {
            s.world.inUse[$0] && !s.world.entities[$0].deleted && units[s.world.entities[$0].unit].id == FourCC(id)!
        }.count
    }

    /// The live members of unit `id`, in pool-slot order.
    private func members(_ s: GameState, _ id: String) -> [Int] {
        let units = s.assets.definitions.units
        return s.world.entities.indices.filter {
            s.world.inUse[$0] && !s.world.entities[$0].deleted && units[s.world.entities[$0].unit].id == FourCC(id)!
        }
    }

    /// One player-collision step of a fresh `bu01` sized (ehw, ehh) at (ex, ey) against P1 moved to (px, py) and sized
    /// (phw, phh): a fresh cache, P1's shields and hit timer reset, game time + 2. Returns whether the Buzzsaw was hit.
    private func rams(_ s: inout GameState, p: (Float, Float, Int32, Int32), e: (Float, Float, Int32, Int32),
                      state: ((UnitState) -> UnitState)? = nil) throws -> Bool {
        s.flags.gameTime += 2
        s.players[0].object.x = p.0; s.players[0].object.y = p.1
        s.players[0].object.halfWidth = p.2; s.players[0].object.halfHeight = p.3
        s.players[0].shield = 100
        let b = try put(&s, "bu01", x: e.0, y: e.1)
        size(&s, b, e.2, e.3)
        var cache = s.playerCollisionCache()
        let st = try XCTUnwrap(s.currentState(b))
        s.collideWithPlayers(b, state: state.map { $0(st) } ?? st, cache: &cache, now: s.flags.gameTime)
        return s.world.entities[b].deleted
    }

    /// `FUN_10042f80`: d² is truncated before the root, the compare is strict, d² ≥ 0x4000 takes libm; the radius is
    /// the C-division half height (damage §2.1, §2.3).
    func testCircleStrict() {
        XCTAssertFalse(GameState.circlesOverlap(ax: 0, ay: 0, bx: 3, by: 4, ra: 2.5, rb: 2.5))      // 5 < 5 false
        XCTAssertTrue(GameState.circlesOverlap(ax: 0, ay: 0, bx: 3, by: 4, ra: 2.5, rb: 2.5001))
        XCTAssertFalse(GameState.circlesOverlap(ax: 0, ay: 0, bx: 3, by: 4.1, ra: 2.5, rb: 2.5))    // 25.81 → 25
        XCTAssertTrue(GameState.circlesOverlap(ax: 0, ay: 0, bx: 3, by: 4.1, ra: 2.5, rb: 2.51))
        XCTAssertFalse(GameState.circlesOverlap(ax: 0, ay: 0, bx: 200, by: 0, ra: 100, rb: 100))    // libm branch
        XCTAssertTrue(GameState.circlesOverlap(ax: 0, ay: 0, bx: 200, by: 0, ra: 100, rb: 100.5))
        XCTAssertEqual(GameState.collisionRadius(MacRect(top: 0, left: 0, bottom: 5, right: 0)), 2)
        XCTAssertEqual(GameState.collisionRadius(MacRect(top: 5, left: 0, bottom: 0, right: 0)), -2)  // not −3
    }

    /// The ram (damage §2.3): the entity takes flli 161 = 100 credited to the player's index (a scoring kill), the
    /// player takes the unit's `damage_FLOAT` × 15 %; the owner takes the ram when the state passes hits; the slot
    /// drops when the ship dies. The gates (pre-controller state, harmless, screen bounds, inclusive boxes, half-height
    /// radii) and the obstacle step (§2.4).
    func testPlayerRamDealsHundred() throws {
        var s = try world()
        let px = s.players[0].object.x, py = s.players[0].object.y
        var cache = s.playerCollisionCache()
        XCTAssertEqual(cache.activeCount, 1)
        XCTAssertEqual(cache.right, 448)
        XCTAssertEqual(cache.bottom, 480)
        XCTAssertEqual(cache.slots[0].radius, 21)                                      // the ship's frame (42 px high) × 0.5
        XCTAssertFalse(cache.slots[1].active)

        let shot = try put(&s, "icb ", x: px, y: py, player: 0)
        s.collideWithPlayers(shot, state: s.currentState(shot), cache: &cache, now: 100)
        XCTAssertFalse(s.world.entities[shot].deleted)                                  // harmlessToPlayers
        XCTAssertEqual(s.players[0].shield, 100)

        // The step reads the state it is given (r18), not the entity's current one.
        let b = try put(&s, "bu01", x: px, y: py)
        var st = try XCTUnwrap(s.currentState(b))
        st.stateCollides = false
        s.collideWithPlayers(b, state: st, cache: &cache, now: 100)
        XCTAssertFalse(s.world.entities[b].deleted)
        st.stateCollides = true; st.stateCollidesWithPlayers = false
        s.collideWithPlayers(b, state: st, cache: &cache, now: 100)
        XCTAssertFalse(s.world.entities[b].deleted)
        XCTAssertEqual(s.world.entities[b].lastHit, 0)

        XCTAssertEqual(s.world.entities[b].shields, 0.4)
        s.collideWithPlayers(b, state: s.currentState(b), cache: &cache, now: 100)
        XCTAssertEqual(s.world.entities[b].shields.bitPattern, Float(0).bitPattern)   // 0.4 − 100 → clamped 0.0
        XCTAssertEqual(s.world.entities[b].lastHit, 100)
        XCTAssertTrue(s.world.entities[b].deleted)
        XCTAssertTrue(s.world.entities[b].destroyed)
        XCTAssertEqual(s.world.entities[b].killer, 0)
        XCTAssertEqual(s.players[0].score, 50)                                         // bu01 score_INT × 1
        XCTAssertEqual(s.players[0].shield, 85)                                        // 100 − 1.0 × 15
        XCTAssertEqual(s.players[0].lastHit, 100)                                      // the caller's now
        XCTAssertEqual(cache.activeCount, 1)

        // passHitsToOwner (10034228): the owner (valid link) takes the 100; the entity is spared; the ship still pays.
        let x = try put(&s, "cals", x: 50, y: 50)
        let b2 = try put(&s, "bu01", x: px, y: py)
        link(&s, b2, owner: x)
        var pass = try XCTUnwrap(s.currentState(b2))
        pass.passHitsToOwner = true
        s.collideWithPlayers(b2, state: pass, cache: &cache, now: 102)
        XCTAssertTrue(s.world.entities[x].deleted)                                     // 10 − 100 → 0
        XCTAssertEqual(s.world.entities[x].killer, 0)
        XCTAssertFalse(s.world.entities[b2].deleted)
        XCTAssertEqual(s.world.entities[b2].shields, 0.4)
        XCTAssertEqual(s.world.entities[b2].lastHit, 0)
        XCTAssertEqual(s.players[0].shield, 70)
        s.collideWithPlayers(b2, state: pass, cache: &cache, now: 104)                  // owner deleted → link invalid
        XCTAssertTrue(s.world.entities[b2].deleted)
        XCTAssertEqual(s.players[0].score, 100)
        XCTAssertEqual(s.players[0].shield, 55)

        // Radii are half heights (10034180..10034190, 1003397c..10033998): 20 + 10 = 30.
        XCTAssertFalse(try rams(&s, p: (200, 300, 20, 20), e: (222, 322, 10, 10)))     // √trunc(968) = 31.1
        XCTAssertTrue(try rams(&s, p: (200, 300, 20, 20), e: (221, 321, 10, 10)))      // √882 = 29.7
        // Inclusive boxes (10034140..1003417c): touching edges collide; one pixel apart does not, whatever the circles.
        XCTAssertTrue(try rams(&s, p: (200, 300, 2, 20), e: (204, 300, 2, 10)))        // e.l 202 == p.r 202
        XCTAssertTrue(try rams(&s, p: (200, 300, 2, 20), e: (196, 300, 2, 10)))        // e.r 198 == p.l 198
        XCTAssertFalse(try rams(&s, p: (200, 300, 2, 20), e: (205, 300, 2, 10)))
        XCTAssertFalse(try rams(&s, p: (200, 300, 2, 20), e: (195, 300, 2, 10)))
        // Screen gate (100340bc..100340e8): r ≥ −32, l ≤ 448, b ≥ 0, t ≤ 480.
        XCTAssertTrue(try rams(&s, p: (-36, 300, 20, 20), e: (-36, 300, 4, 4)))        // r = −32
        XCTAssertFalse(try rams(&s, p: (-37, 300, 20, 20), e: (-37, 300, 4, 4)))       // r = −33
        XCTAssertTrue(try rams(&s, p: (452, 300, 20, 20), e: (452, 300, 4, 4)))        // l = 448
        XCTAssertFalse(try rams(&s, p: (453, 300, 20, 20), e: (453, 300, 4, 4)))       // l = 449
        XCTAssertTrue(try rams(&s, p: (200, -4, 20, 20), e: (200, -4, 4, 4)))          // b = 0
        XCTAssertFalse(try rams(&s, p: (200, -5, 20, 20), e: (200, -5, 4, 4)))         // b = −1
        XCTAssertTrue(try rams(&s, p: (200, 484, 20, 20), e: (200, 484, 4, 4)))        // t = 480
        XCTAssertFalse(try rams(&s, p: (200, 485, 20, 20), e: (200, 485, 4, 4)))       // t = 481

        // The obstacle step (100344ec..10034570): a ground tank touching a debris rect (inclusive) stops for good and,
        // with destructCreateObstacle, becomes an obstacle itself; air-flagged, already-stationary or non-colliding
        // entities are left alone.
        let t = try put(&s, "tala", x: 300, y: 200)
        XCTAssertFalse(s.world.entities[t].object.air)
        s.world.entities[t].object.vx = 1.5; s.world.entities[t].object.vy = 2
        let tr = s.boundingBox(t)
        s.debris.add(MacRect(top: tr.bottom + 1, left: tr.left, bottom: tr.bottom + 10, right: tr.right))
        s.collideWithObstacles(t)
        XCTAssertFalse(s.world.entities[t].stationary)                                  // one pixel apart
        s.debris.add(MacRect(top: tr.bottom, left: tr.right, bottom: tr.bottom + 10, right: tr.right + 10))
        let debris = s.debris.count
        s.collideWithObstacles(t)
        XCTAssertTrue(s.world.entities[t].stationary)
        XCTAssertEqual(s.world.entities[t].object.vx, 0)
        XCTAssertEqual(s.world.entities[t].object.vy, 0)
        XCTAssertEqual(s.debris.count, debris + 1)
        XCTAssertEqual(s.debris.rects.last, tr)
        s.collideWithObstacles(t)
        XCTAssertEqual(s.debris.count, debris + 1)                                      // stationary: skipped
        let t2 = try put(&s, "tala", x: 300, y: 200)
        s.world.entities[t2].object.air = true
        s.world.entities[t2].object.vx = 1
        s.collideWithObstacles(t2)
        XCTAssertFalse(s.world.entities[t2].stationary)
        XCTAssertEqual(s.world.entities[t2].object.vx, 1)
        let b3 = try put(&s, "bu01", x: 300, y: 200)                                    // no collidesWithGroundObstacles
        s.world.entities[b3].object.air = false
        s.collideWithObstacles(b3)
        XCTAssertFalse(s.world.entities[b3].stationary)
        XCTAssertEqual(s.debris.count, debris + 1)

        // The ship dies on the ram → its slot drops for the rest of the tick (100342d8..100342f8).
        s.flags.gameTime += 2
        let now = s.flags.gameTime
        s.players[0].object.x = 200; s.players[0].object.y = 300
        s.players[0].object.halfWidth = 20; s.players[0].object.halfHeight = 20
        s.players[0].shield = 10
        var c2 = s.playerCollisionCache()
        let k1 = try put(&s, "bu01", x: 200, y: 300)
        let k2 = try put(&s, "bu01", x: 200, y: 300)
        s.collideWithPlayers(k1, state: s.currentState(k1), cache: &c2, now: now)
        XCTAssertTrue(s.world.entities[k1].deleted)
        XCTAssertNotEqual(s.players[0].lifeState, 4)
        XCTAssertFalse(c2.slots[0].active)
        XCTAssertEqual(c2.activeCount, 0)
        s.collideWithPlayers(k2, state: s.currentState(k2), cache: &c2, now: now)
        XCTAssertFalse(s.world.entities[k2].deleted)
    }

    /// The hit delay belongs to the victim (damage §3 steps 2–3): `now > lastHit + trunc(flli 167 = 1)`. Also the
    /// deleted and already-dead guards (steps 1, 6), the invulnerable-state restore and its sound choice (7, 12), the
    /// collision spawn and its delay (13), the depletion branch (9b) and the kill-score gate `FUN_10006190`.
    func testHitDelayPerVictim() throws {
        var s = try world()
        let p = try put(&s, "plla", x: 100, y: 200)
        XCTAssertEqual(s.world.entities[p].shields.bitPattern, Float(2.6).bitPattern)
        let sounds = s.cues.sounds.count
        XCTAssertEqual(s.damageEntity(p, damage: 0.4, killer: 0, now: 200).bitPattern, (Float(2.6) - Float(2.1999998)).bitPattern)
        XCTAssertEqual(s.world.entities[p].shields.bitPattern, Float(2.1999998).bitPattern)
        XCTAssertEqual(s.world.entities[p].lastHit, 200)
        XCTAssertTrue(s.world.entities[p].object.hitGlowOn)
        XCTAssertEqual(s.world.entities[p].object.hitGlowColour, 0x7fff)
        XCTAssertEqual(s.world.entities[p].object.hitGlowStep, 6)
        XCTAssertEqual(s.cues.sounds.map(\.id).dropFirst(sounds), [FourCC("ppsh")!])   // shieldSound_ID (state +0x348 clear)
        s.damageEntity(p, damage: 0.4, killer: 0, now: 201)                               // refused: 201 > 200 + 1 false
        XCTAssertEqual(s.world.entities[p].shields.bitPattern, Float(2.1999998).bitPattern)
        XCTAssertEqual(s.world.entities[p].lastHit, 200)
        XCTAssertEqual(s.cues.sounds.count, sounds + 1)
        s.damageEntity(p, damage: 0.4, killer: 0, now: 202)
        XCTAssertEqual(s.world.entities[p].shields.bitPattern, Float(1.7999998).bitPattern)
        XCTAssertEqual(s.world.entities[p].lastHit, 202)
        XCTAssertEqual(s.cues.sounds.count, sounds + 2)
        XCTAssertFalse(s.world.entities[p].deleted)

        // Step 1: a deleted entity ignores the hit entirely.
        let d = try put(&s, "plla", x: 100, y: 250)
        s.world.entities[d].deleted = true
        XCTAssertEqual(s.damageEntity(d, damage: 0.4, killer: 0, now: 300), 0)
        XCTAssertEqual(s.world.entities[d].lastHit, 0)
        XCTAssertEqual(s.world.entities[d].shields.bitPattern, Float(2.6).bitPattern)

        // Step 6: shields already ≤ 0.0 (a coin, base 0.0) → lastHit taken, nothing else (no kill, glow, sound).
        let c = try put(&s, "cass", x: 120, y: 250)
        s.world.entities[c].object.hitGlowOn = false
        let snd = s.cues.sounds.count
        s.damageEntity(c, damage: 0.4, killer: 0, now: 300)
        XCTAssertEqual(s.world.entities[c].lastHit, 300)
        XCTAssertFalse(s.world.entities[c].deleted)
        XCTAssertFalse(s.world.entities[c].object.hitGlowOn)
        XCTAssertEqual(s.cues.sounds.count, snd)

        // Steps 7, 12, 13 on `fgnu` S0 (Invulnerable, shieldSound ppsh / unshieldedSound none, collision_Spawn ngsh,
        // RepeatSpawns, delay 20): shields restored; the unshielded record (none) → no cue; ngsh at the gun, owned by it.
        let g = try put(&s, "fgnu", x: 160, y: 260, player: 0)
        let ngsh = count(s, "ngsh")
        let snd2 = s.cues.sounds.count
        s.damageEntity(g, damage: 0.4, killer: 0, now: 400)
        XCTAssertEqual(s.world.entities[g].shields, 2.0)
        XCTAssertTrue(s.world.entities[g].object.hitGlowOn)
        XCTAssertEqual(s.cues.sounds.count, snd2)
        XCTAssertEqual(count(s, "ngsh"), ngsh + 1)
        let n = try XCTUnwrap(members(s, "ngsh").last)
        XCTAssertEqual(s.world.entities[n].owner, g)
        XCTAssertEqual(s.world.entities[n].ownerSerial, s.world.entities[g].serial)
        XCTAssertEqual(s.world.entities[n].ownerPlayer, 0)
        XCTAssertEqual(s.world.entities[g].collisionSpawnTime, 400)
        XCTAssertEqual(s.world.entities[g].collisionSpawnCount, 1)
        s.damageEntity(g, damage: 0.4, killer: 0, now: 419)                              // accepted hit, 419 < 400 + 20
        XCTAssertEqual(s.world.entities[g].lastHit, 419)
        XCTAssertEqual(count(s, "ngsh"), ngsh + 1)
        XCTAssertEqual(s.world.entities[g].collisionSpawnCount, 1)
        s.damageEntity(g, damage: 0.4, killer: 0, now: 440)                              // 440 ≥ 400 + 20 → the repeat spawn
        XCTAssertEqual(count(s, "ngsh"), ngsh + 2)
        XCTAssertEqual(s.world.entities[g].collisionSpawnTime, 440)
        XCTAssertEqual(s.world.entities[g].collisionSpawnCount, 2)
        s.damageEntity(g, damage: 0.4, killer: 0, now: 460)                              // exactly 440 + 20
        XCTAssertEqual(count(s, "ngsh"), ngsh + 3)

        // Step 9: score first, then the depletion state when +0xcd is set (bu01 has none → it stays) instead of destroy.
        let b = try put(&s, "bu01", x: 200, y: 300)
        s.world.entities[b].hasDepletionState = true
        let score = s.players[0].score
        s.damageEntity(b, damage: 0.4, killer: 0, now: 500)
        XCTAssertEqual(s.world.entities[b].shields, 0)
        XCTAssertEqual(s.players[0].score, score + 50)
        XCTAssertFalse(s.world.entities[b].deleted)
        XCTAssertFalse(s.world.entities[b].destroyed)

        // FUN_10006190: only killers 0 and 1 score.
        s.players[1].inGame = true
        s.scoreKill(killer: 1, points: 7)
        XCTAssertEqual(s.players[1].score, 7)
        s.scoreKill(killer: -1, points: 7)
        s.scoreKill(killer: 2, points: 7)
        XCTAssertEqual(s.players[0].score, score + 50)
        XCTAssertEqual(s.players[1].score, 7)
    }

    /// Worked example A on a Buzzsaw (damage §2.5, §3): the shot (A) takes `bu01`'s 1.0 and dies; `bu01` takes 0.4:
    /// 0.4 − 0.4 = 0.0 ≤ 0 → `score_INT` 50 to the shot's owner, then `destroyEntity` with that killer. Also the
    /// entity ↔ entity gates: the pre-controller state, A's bottom guard, half-height radii, inclusive boxes.
    func testBuzzsawDiesToOneIonHit() throws {
        var s = try world()
        let b = try put(&s, "bu01", x: 200, y: 200)
        let shot = try put(&s, "icb ", x: 200, y: 203, player: 0)
        XCTAssertTrue(s.world.entities[b].hittable)
        // The step's Collides gate uses the state it is given (r18).
        var st = try XCTUnwrap(s.currentState(shot))
        st.stateCollides = false
        s.entityCollisionStep(shot, state: st, now: 300)
        XCTAssertFalse(s.world.entities[shot].deleted)
        XCTAssertEqual(s.world.entities[b].shields, 0.4)
        s.entityCollisionStep(shot, state: s.currentState(shot), now: 300)
        XCTAssertEqual(s.world.entities[b].shields.bitPattern, Float(0).bitPattern)
        XCTAssertTrue(s.world.entities[b].deleted)
        XCTAssertTrue(s.world.entities[b].destroyed)
        XCTAssertEqual(s.world.entities[b].killer, 0)
        XCTAssertEqual(s.players[0].score, 50)
        XCTAssertTrue(s.world.entities[shot].deleted)                                    // 0.4 − 1.0 → 0.0
        XCTAssertTrue(s.world.entities[shot].destroyed)
        XCTAssertEqual(s.world.entities[shot].killer, -1)                                // bu01 has no owner player

        // A player projectile above the screen (rect bottom < 0) collides with nothing (10036d64..10036d78).
        let hb = try put(&s, "bu01", x: 100, y: -30)
        let hs = try put(&s, "icb ", x: 100, y: -30, player: 0)
        XCTAssertFalse(s.collideWithEntities(hs, now: 310))
        XCTAssertEqual(s.world.entities[hb].shields, 0.4)
        XCTAssertEqual(s.world.entities[hs].lastHit, 0)

        // Radii are half heights (10036f60..10036fb0): 4 + 10 = 14.
        func pair(_ dx: Float, _ dy: Float, a: (Int32, Int32), b: (Int32, Int32), now: Int32) throws -> Bool {
            let v = try put(&s, "bu01", x: 300 + dx, y: 300 + dy)
            let w = try put(&s, "icb ", x: 300, y: 300, player: 0)
            size(&s, w, a.0, a.1)
            size(&s, v, b.0, b.1)
            s.collideWithEntities(w, now: now)
            let hit = s.world.entities[v].lastHit == now
            s.world.entities[v].deleted = true
            s.world.entities[w].deleted = true
            return hit
        }
        XCTAssertFalse(try pair(10, 10, a: (4, 4), b: (10, 10), now: 320))              // √200 = 14.1
        XCTAssertTrue(try pair(9, 9, a: (4, 4), b: (10, 10), now: 322))                 // √162 = 12.7
        // Inclusive boxes (10036ef8..10036f34).
        XCTAssertTrue(try pair(4, 0, a: (2, 10), b: (2, 10), now: 324))                 // A.r 302 == B.l 302
        XCTAssertTrue(try pair(-4, 0, a: (2, 10), b: (2, 10), now: 326))                // A.l 298 == B.r 298
        XCTAssertFalse(try pair(5, 0, a: (2, 10), b: (2, 10), now: 328))
        XCTAssertFalse(try pair(-5, 0, a: (2, 10), b: (2, 10), now: 330))
    }

    /// Each shot/enemy pair is found once, from the shot's update (damage §2.5 "Consequence"): the enemy's scan cannot
    /// pick the shot (`canBeHitByPlayerProjectile` FALSE); a second shot in the victim's delay window dies without
    /// effect (§3 (b)). Hit particles then the sound draw, in that order; the scan stops once A is deleted; the
    /// B-side `passHitsToOwner` bug sends the shot's damage to the shot's owner.
    func testShotResolvesPairOnce() throws {
        var s = try world()
        let c = try put(&s, "cals", x: 150, y: 150)                                     // air, canBeHit, shields 10
        let shot1 = try put(&s, "icb ", x: 150, y: 150, player: 0)
        let shot2 = try put(&s, "icb ", x: 151, y: 150, player: 0)
        XCTAssertFalse(s.collideWithEntities(c, now: 300))
        XCTAssertEqual(s.world.entities[c].shields, 10)
        XCTAssertFalse(s.world.entities[shot1].deleted)
        XCTAssertEqual(s.world.entities[shot1].shields, 0.4)

        // Steps 11 then 12 on `cals` (hitParticles `tiny`, shieldSound `cohi` pitch 0.95…1.05): an independent replay of
        // the two draws in that order.
        let u = s.assets.definitions.units[s.world.entities[c].unit]
        var rng = s.rng
        var particles = s.particles
        particles.emit(ParticleRequest(x: 150, y: 150, colour: u.hitParticlesColor, delay: 0, ground: false,
                                       type: u.hitParticles), rng: &rng)
        let cue = SoundPlay.record(u.shieldSound, allowMultiple: true, rng: &rng)
        XCTAssertTrue(s.collideWithEntities(shot1, now: 300))
        XCTAssertEqual(s.world.entities[c].shields.bitPattern, (Float(10) - Float(0.4)).bitPattern)
        XCTAssertEqual(s.world.entities[c].lastHit, 300)
        XCTAssertEqual(s.particles, particles)
        XCTAssertEqual(s.cues.sounds.last, cue)
        XCTAssertEqual(cue?.id, FourCC("cohi")!)
        XCTAssertEqual(s.rng, rng)

        XCTAssertTrue(s.collideWithEntities(shot2, now: 301))                           // the shot still takes 1.0
        XCTAssertEqual(s.world.entities[c].shields.bitPattern, (Float(10) - Float(0.4)).bitPattern)
        XCTAssertEqual(s.world.entities[c].lastHit, 300)
        XCTAssertFalse(s.world.entities[c].deleted)
        XCTAssertFalse(s.collideWithEntities(c, now: 302))
        XCTAssertEqual(s.world.entities[c].shields.bitPattern, (Float(10) - Float(0.4)).bitPattern)

        // A deleted by its first hit → the scan stops (100370f0): of two overlapping victims only the first is struck.
        let v1 = try put(&s, "cals", x: 250, y: 150)
        let v2 = try put(&s, "cals", x: 250, y: 150)
        let shot3 = try put(&s, "icb ", x: 250, y: 150, player: 0)
        XCTAssertTrue(s.collideWithEntities(shot3, now: 310))
        XCTAssertEqual(s.world.entities[v1].lastHit, 310)
        XCTAssertEqual(s.world.entities[v2].lastHit, 0)
        XCTAssertEqual(s.world.entities[v2].shields, 10)

        // The B-side bug (10037058..100370cc): B = `pllt` (passHitsToOwner, damage 0.0) struck by a bomb A whose owner
        // link is valid → A's owner takes A's 0.4, credited to A+0xd8; the turret keeps its shields.
        let owner = try put(&s, "bu01", x: 50, y: 400)
        let tur = try put(&s, "pllt", x: 300, y: 300)
        let bomb = try put(&s, "plbo", x: 300, y: 300, player: 0)
        link(&s, bomb, owner: owner)
        let score = s.players[0].score
        XCTAssertFalse(s.collideWithEntities(bomb, now: 320))                           // the bomb takes 0.0 and lives
        XCTAssertEqual(s.world.entities[bomb].lastHit, 320)
        XCTAssertEqual(s.world.entities[bomb].shields, 0.4)
        XCTAssertEqual(s.world.entities[tur].shields, 3)
        XCTAssertEqual(s.world.entities[tur].lastHit, 0)
        XCTAssertTrue(s.world.entities[owner].deleted)                                  // 0.4 − 0.4 → 0.0
        XCTAssertEqual(s.world.entities[owner].killer, 0)
        XCTAssertEqual(s.players[0].score, score + 50)
        // Without an owner the turret takes it on its own shields.
        let bomb2 = try put(&s, "plbo", x: 300, y: 300, player: 0)
        s.collideWithEntities(bomb2, now: 330)
        XCTAssertEqual(s.world.entities[tur].shields.bitPattern, (Float(3) - Float(0.4)).bitPattern)
        XCTAssertEqual(s.world.entities[tur].lastHit, 330)
    }

    /// `FUN_10037580` through the player-collision step (loose-ends-combat §3.1–§3.2, scoring §3.3, §4): coins add
    /// money and glow the ship, `exli` adds a life (capped at 10, `noel` only on a real gain), `mult` steps the
    /// multiplier, `shie` = clamp(shield + value, 0, 100); consumed pickups are destroyed by the player's index and
    /// marked collected, and never hurt the ship. `air `/`grnd` are refused while invulnerable; `spec` does nothing.
    func testPickups() throws {
        var s = try world()
        let px = s.players[0].object.x, py = s.players[0].object.y
        @discardableResult
        func touch(_ id: String) throws -> Int {
            let e = try put(&s, id, x: px, y: py)
            var cache = s.playerCollisionCache()
            s.collideWithPlayers(e, state: s.currentState(e), cache: &cache, now: s.flags.gameTime)
            XCTAssertTrue(s.world.entities[e].deleted, id)
            XCTAssertTrue(s.world.entities[e].collected, id)
            XCTAssertEqual(s.world.entities[e].killer, 0, id)
            XCTAssertEqual(s.world.entities[e].shields, s.assets.definitions.units[s.world.entities[e].unit].shieldsBaseAmount, id)
            return e
        }
        XCTAssertEqual(s.players[0].money, 0)
        s.players[0].object.hitGlowOn = false
        try touch("calg")
        XCTAssertEqual(s.players[0].money, 50)
        XCTAssertTrue(s.players[0].object.hitGlowOn)
        XCTAssertEqual(s.players[0].object.hitGlowColour, 0x7fff)
        XCTAssertEqual(s.players[0].object.hitGlowStep, 6)
        try touch("cass")
        XCTAssertEqual(s.players[0].money, 51)
        XCTAssertEqual(s.players[0].shield, 100)                                          // no ram damage

        s.players[0].lives = 9
        let noel = count(s, "noel")
        try touch("piel")
        XCTAssertEqual(s.players[0].lives, 10)
        XCTAssertEqual(count(s, "noel"), noel + 1)
        try touch("piel")
        XCTAssertEqual(s.players[0].lives, 10)                                            // life_MaxNum
        XCTAssertEqual(count(s, "noel"), noel + 1)

        XCTAssertEqual(s.players[0].multiplier, 1)
        try touch("pimu")
        XCTAssertEqual(s.players[0].multiplier, 2)

        s.players[0].shield = 90
        try touch("pism")
        XCTAssertEqual(s.players[0].shield, 100)
        s.players[0].shield = 50
        try touch("pism")
        XCTAssertEqual(s.players[0].shield, 70)
        s.players[0].shield = 100
        try touch("pish")                                                                 // taken even at 100
        XCTAssertEqual(s.players[0].shield, 100)
        XCTAssertTrue(s.applyPickup(player: 0, type: FourCC("shie")!, value: -200))
        XCTAssertEqual(s.players[0].shield, 0)

        s.players[0].invulnerable = true
        XCTAssertFalse(s.applyPickup(player: 0, type: FourCC("air ")!, value: 0))
        XCTAssertFalse(s.applyPickup(player: 0, type: FourCC("grnd")!, value: 0))
        XCTAssertTrue(s.applyPickup(player: 0, type: FourCC("spec")!, value: 7))
        s.players[0].invulnerable = false
        XCTAssertTrue(s.applyPickup(player: 0, type: FourCC("air ")!, value: 0))
        XCTAssertTrue(s.applyPickup(player: 0, type: FourCC("grnd")!, value: 0))
        XCTAssertEqual(s.players[0].money, 51)
        XCTAssertEqual(s.players[0].lives, 10)
        XCTAssertEqual(s.players[0].multiplier, 2)
    }
}
