import XCTest
import HectorResources
@testable import DeimosCore

/// Combat I (plan C11a): the circle test `FUN_10042f80`, the player-collision step of `FUN_10033850`, entity ↔ entity
/// `FUN_10036cf0`, entity damage `FUN_10014f10` with its per-victim hit delay, and the pickup switch `FUN_10037580`
/// (damage-health-death.md §2–§3, §6; loose-ends-combat.md §3). Shipped units only; `destroyEntity` is C10's hook
/// stub (C11b fills it), so a kill is observed as its flags (+0xcb, +0xd9, +0xda).
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

    private func count(_ s: GameState, _ id: String) -> Int {
        let units = s.assets.definitions.units
        return s.world.entities.indices.filter {
            s.world.inUse[$0] && !s.world.entities[$0].deleted && units[s.world.entities[$0].unit].id == FourCC(id)!
        }.count
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
    /// player takes the unit's `damage_FLOAT` × 15 %. A harmless unit is never tested.
    func testPlayerRamDealsHundred() throws {
        var s = try world()
        let px = s.players[0].object.x, py = s.players[0].object.y
        var cache = s.playerCollisionCache()
        XCTAssertEqual(cache.activeCount, 1)
        XCTAssertEqual(cache.right, 448)
        XCTAssertEqual(cache.bottom, 480)
        let r = cache.slots[0].rect
        XCTAssertEqual(cache.slots[0].radius, Float(r.bottom - r.top) * 0.5)
        XCTAssertFalse(cache.slots[1].active)

        let shot = try put(&s, "icb ", x: px, y: py, player: 0)
        s.collideWithPlayers(shot, cache: &cache, now: 100)
        XCTAssertFalse(s.world.entities[shot].deleted)
        XCTAssertEqual(s.players[0].shield, 100)

        let b = try put(&s, "bu01", x: px, y: py)
        XCTAssertEqual(s.world.entities[b].shields, 0.4)
        s.collideWithPlayers(b, cache: &cache, now: 100)
        XCTAssertEqual(s.world.entities[b].shields.bitPattern, Float(0).bitPattern)   // 0.4 − 100 → clamped 0.0
        XCTAssertEqual(s.world.entities[b].lastHit, 100)
        XCTAssertTrue(s.world.entities[b].deleted)
        XCTAssertTrue(s.world.entities[b].destroyed)
        XCTAssertEqual(s.world.entities[b].killer, 0)
        XCTAssertEqual(s.players[0].score, 50)                                         // bu01 score_INT × 1
        XCTAssertEqual(s.players[0].shield, 85)                                        // 100 − 1.0 × 15
        XCTAssertEqual(cache.activeCount, 1)
    }

    /// The hit delay belongs to the victim (damage §3 steps 2–3): `now > lastHit + trunc(flli 167 = 1)`.
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
    }

    /// Worked example A on a Buzzsaw (damage §2.5, §3): the shot (A) takes `bu01`'s 1.0 and dies; `bu01` takes 0.4:
    /// 0.4 − 0.4 = 0.0 ≤ 0 → `score_INT` 50 to the shot's owner, then `destroyEntity` with that killer.
    func testBuzzsawDiesToOneIonHit() throws {
        var s = try world()
        let b = try put(&s, "bu01", x: 200, y: 200)
        let shot = try put(&s, "icb ", x: 200, y: 203, player: 0)
        XCTAssertTrue(s.world.entities[b].hittable)
        XCTAssertTrue(s.collideWithEntities(shot, now: 300))
        XCTAssertEqual(s.world.entities[b].shields.bitPattern, Float(0).bitPattern)
        XCTAssertTrue(s.world.entities[b].deleted)
        XCTAssertTrue(s.world.entities[b].destroyed)
        XCTAssertEqual(s.world.entities[b].killer, 0)
        XCTAssertEqual(s.players[0].score, 50)
        XCTAssertTrue(s.world.entities[shot].deleted)                                    // 0.4 − 1.0 → 0.0
        XCTAssertTrue(s.world.entities[shot].destroyed)
        XCTAssertEqual(s.world.entities[shot].killer, -1)                                // bu01 has no owner player
    }

    /// Each shot/enemy pair is found once, from the shot's update (damage §2.5 "Consequence"): the enemy's scan cannot
    /// pick the shot (`canBeHitByPlayerProjectile` FALSE); a second shot in the victim's delay window dies without
    /// effect (§3 (b)).
    func testShotResolvesPairOnce() throws {
        var s = try world()
        let c = try put(&s, "cals", x: 150, y: 150)                                     // air, canBeHit, shields 10
        let shot1 = try put(&s, "icb ", x: 150, y: 150, player: 0)
        let shot2 = try put(&s, "icb ", x: 151, y: 150, player: 0)
        XCTAssertFalse(s.collideWithEntities(c, now: 300))
        XCTAssertEqual(s.world.entities[c].shields, 10)
        XCTAssertFalse(s.world.entities[shot1].deleted)
        XCTAssertEqual(s.world.entities[shot1].shields, 0.4)

        let bursts = s.particles.groups.count
        XCTAssertTrue(s.collideWithEntities(shot1, now: 300))
        XCTAssertEqual(s.world.entities[c].shields.bitPattern, (Float(10) - Float(0.4)).bitPattern)
        XCTAssertEqual(s.world.entities[c].lastHit, 300)
        XCTAssertEqual(s.particles.groups.count, bursts + 1)                            // hitParticles `tiny` (step 11)
        XCTAssertEqual(s.particles.groups.last?.ground, false)
        XCTAssertEqual(s.cues.sounds.last?.id, FourCC("cohi")!)                         // shieldSound_ID (step 12)

        XCTAssertTrue(s.collideWithEntities(shot2, now: 301))                           // the shot still takes 1.0
        XCTAssertEqual(s.world.entities[c].shields.bitPattern, (Float(10) - Float(0.4)).bitPattern)
        XCTAssertEqual(s.world.entities[c].lastHit, 300)
        XCTAssertFalse(s.world.entities[c].deleted)
        XCTAssertFalse(s.collideWithEntities(c, now: 302))
        XCTAssertEqual(s.world.entities[c].shields.bitPattern, (Float(10) - Float(0.4)).bitPattern)
    }

    /// `FUN_10037580` through the player-collision step (loose-ends-combat §3.1–§3.2, scoring §3.3, §4): coins add
    /// money and glow the ship, `exli` adds a life (capped at 10, `noel` only on a real gain), `mult` steps the
    /// multiplier, `shie` = clamp(shield + value, 0, 100); consumed pickups are destroyed by the player's index and
    /// marked collected, and never hurt the ship. `air `/`grnd` are refused while invulnerable; `spec` does nothing.
    func testPickups() throws {
        var s = try world()
        let px = s.players[0].object.x, py = s.players[0].object.y
        func touch(_ id: String) throws -> Int {
            let e = try put(&s, id, x: px, y: py)
            var cache = s.playerCollisionCache()
            s.collideWithPlayers(e, cache: &cache, now: s.flags.gameTime)
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
