import Foundation
import HectorResources

/// Entity damage, the hit delay and the shield-depletion state (damage-health-death.md §3, HIGH; plan C11a).
///
/// Listing reads (`disasm-review3-all.txt`): `FUN_10014f10` (`10014f10..1001527c`), `FUN_10006190`
/// (`10006190..100061d0`), `FUN_10017e70` (`10017e70..10017ee4`). Constants: f31 = `*(r2 − 0x71f8)` =
/// `0x100d6c8c` = 0.0 (the clamp), the compares against `*(r2 − 0x7208) + 8` = `0x100d6cac` = 0.0.
extension GameState {
    /// `FUN_10014f10(e, damage, —, killer, now) @ 10014f10` — entity `i` takes `damage` credited to player index
    /// `killer` at game time `now`; returns the shields absorbed (`old − new`, f31; no caller reads it). In order:
    /// 1. deleted (+0xcb) → return 0.0 (`10014f44..10014f4c`);
    /// 2. hit delay: accepted only if `now > lastHit (+0xb4) + trunc(flli 167)` (`10014f50..10014f74`); 3. lastHit =
    ///    now (`10014f78`);
    /// 4. `old = s; s = old − damage` (`fsubs`, stored), `s < 0.0 → 0.0` (`10014f7c..10014fac`); 5. returned
    ///    `old − s` (`10014fbc`);
    /// 6. `old ≤ 0.0` → return (`10014f94..10014fa0`, `10014fc0`);
    /// 7. the current state `Invulnerable_ShieldsDoNotDepleteOnCollision` (+0x348) → `s = old` (`10014fc4..10014fe0`);
    /// 8. `OnHitChangeStateDelay` ≠ 0, `OnHitChangeTo` non-empty and `now > lastHitStateChange (+0xfc) + delay` →
    ///    +0xfc = now, enter that state (`FUN_100146f0(e, 0, name, now)`; its Delete/Destroy out-bytes are **not
    ///    read**) and return if that deleted the entity (`10014fe4..10015034`). **The state pointer r30 is not
    ///    re-read**: steps 10, 12 and 13 use the state current before the change;
    /// 9. `s ≤ 0.0` (re-read) → `FUN_10006190(killer, score_INT)`, then the shield-depletion state when +0xcd is set
    ///    (`FUN_10017e70`) else `destroyEntity(i, killer, now)` (`FUN_10016300`), return (`10015038..10015094`);
    /// 10. state not `DoNotGlowOnCollision` (+0x354) → hit glow 0x7fff, step 6, not forced (`10015098..100150b4`);
    /// 11. `hitParticles_ID` (+0x2d8) ≠ `none` → `FUN_10043340` {x, y, `hitParticlesColor` (+0x17e), delay 0,
    ///     ground = unit +8 == `grnd`, type} (`100150bc..10015114`);
    /// 12. state +0x348 clear → `shieldSound_ID` (+0x448), else `unshieldedSound_ID` (+0x460), each only when its id
    ///     ≠ `none`, `FUN_100475e0(rec, 1)` (`1001511c..10015168`);
    /// 13. `collision_Spawn_ID` (+0x2e0) ≠ `none`, (`collision_RepeatSpawns` (+0x2e4) or +0xd4 == 0), `now ≥ +0xd0 +
    ///     collision_SpawnDelay` (+0x2e8) → a request from the template `0x100e64b0` (runtime) with +0x00 = the id,
    ///     +0x04/+0x08 = the position, +0x14 = +0xd8, +0x20 = e, +0x24 = +0x9c (`FUN_10033220`), then +0xd0 = now,
    ///     +0xd4 += 1 (`1001516c..1001525c`).
    @discardableResult
    public mutating func damageEntity(_ i: Int, damage: Float, killer: Int8, now: Int32) -> Float {
        guard !world.entities[i].deleted else { return 0 }                  // 10014f44..10014f4c
        let delay = EntityDraw.fctiwz(assets.floats[167])                    // 10014f50..10014f68
        guard now > world.entities[i].lastHit &+ delay else { return 0 }     // 10014f60..10014f74
        world.entities[i].lastHit = now                                      // 10014f78
        let old = world.entities[i].shields                                  // 10014f80
        var s: Float = old - damage                                          // 10014f84..10014f8c
        if s < 0 { s = 0 }                                                   // 10014f9c..10014fac
        world.entities[i].shields = s
        let absorbed: Float = old - s                                        // 10014fbc
        guard !(old <= 0) else { return absorbed }                           // 10014f88..10014fa0, 10014fc0
        let ui = world.entities[i].unit
        let u = assets.definitions.units[ui]
        guard let st = currentState(i) else { return absorbed }              // 10014fc4..10014fd0 (r30)
        if st.stateInvulnerableShieldsDoNotDepleteOnCollision {              // 10014fd4..10014fdc
            world.entities[i].shields = old                                  // 10014fe0
        }
        let changeDelay = st.stateOnHitChangeStateDelay                      // 10014fe4..10014fec
        if changeDelay != 0, !st.stateOnHitChangeTo.isEmpty,                 // 10014ff0..10014ffc
           now > world.entities[i].lastHitStateChange &+ changeDelay {       // 10015000..1001500c
            world.entities[i].lastHitStateChange = now                       // 10015010
            enterState(i, named: st.stateOnHitChangeTo, spawning: false, now: now)   // 10015014..10015028 (out-bytes unread)
            if world.entities[i].deleted { return absorbed }                 // 1001502c..10015034
        }
        if world.entities[i].shields <= 0 {                                  // 10015038..10015048 (cror eq,lt,eq)
            scoreKill(killer: killer, points: u.score)                       // 1001504c..10015058 FUN_10006190
            if world.entities[i].hasDepletionState {                         // 10015060..10015068
                enterShieldDepletionState(i, now: now)                       // 10015084..1001508c FUN_10017e70
            } else {
                destroyEntity(i, killer: killer, now: now)                   // 1001506c..10015078 FUN_10016300
            }
            return absorbed
        }
        if !st.stateDoNotGlowOnCollision {                                   // 10015098..100150a0
            world.entities[i].object.startHitGlow(colour: 0x7fff, step: 6, force: false)   // 100150a4..100150b4
        }
        if u.hitParticles != .none {                                         // 100150bc..100150c8
            let o = world.entities[i].object
            particles.emit(ParticleRequest(x: o.x, y: o.y, colour: u.hitParticlesColor, delay: 0,
                                           ground: u.layer == UnitDefinition.ground, type: u.hitParticles),
                           rng: &rng)                                        // 100150cc..10015114 FUN_10043340
        }
        let sound = st.stateInvulnerableShieldsDoNotDepleteOnCollision ? u.unshieldedSound : u.shieldSound   // 1001511c..10015124
        if sound.id != .none,                                                // 10015128..10015134 / 1001514c..10015158
           let cue = SoundPlay.record(sound, allowMultiple: true, rng: &rng) {   // 10015138..10015140 / 1001515c..10015164
            cues.sounds.append(cue)
        }
        if st.collisionSpawn != .none,                                       // 1001516c..10015178
           st.collisionRepeatSpawns || world.entities[i].collisionSpawnCount == 0,   // 1001517c..10015194
           now >= world.entities[i].collisionSpawnTime &+ st.collisionSpawnDelay {   // 10015198..100151a8
            let e = world.entities[i]
            var req = SpawnRequest.template                                  // 100151ac..10015218 (r2+0x180)
            req.unit = st.collisionSpawn                                     // 1001521c..10015220
            req.x = e.object.x; req.y = e.object.y                           // 10015224..10015230
            req.player = e.ownerPlayer                                       // 10015234..10015238
            req.owner = i                                                    // 1001523c
            req.ownerSerial = e.serial                                       // 10015240..10015244
            spawn(req)                                                       // 10015248 FUN_10033220
            world.entities[i].collisionSpawnTime = now                       // 10015250
            world.entities[i].collisionSpawnCount &+= 1                      // 10015254..1001525c
        }
        return absorbed
    }

    /// `FUN_10006190(killer, pts, raw) @ 10006190` — kill points: `−1 < killer < 2` (signed byte) → `addScore` to
    /// that player with r5 passed through (0 from `FUN_10014f10`); anything else is ignored.
    public mutating func scoreKill(killer: Int8, points: Int32) {
        guard killer > -1, killer < 2 else { return }                       // 10006198..100061ac
        addScore(Int(killer), points)                                        // 100061b0..100061bc FUN_10029a10
    }

    /// `FUN_10017e70(e, now) @ 10017e70` — switch to the first state (0 ..< numStates, unit +0x14) whose
    /// `UseThisStateOnShieldDepletion` (state +0x356) is set, by its name (`FUN_100146f0(e, 0, name, now)`; the
    /// out-bytes are not read); none → nothing. Shields stay 0, so later hits stop at step 6 of `damageEntity`.
    public mutating func enterShieldDepletionState(_ i: Int, now: Int32) {
        let u = assets.definitions.units[world.entities[i].unit]
        for s in 0..<min(Int(u.numStates), u.states.count)                  // 10017ec8..10017ed4
        where u.states[s].stateUseThisStateOnShieldDepletion {               // 10017e88..10017e94
            enterState(i, named: u.states[s].stateName, spawning: false, now: now)   // 10017e98..10017eb4
            return
        }
    }
}
