import Foundation
import HectorResources

/// One step of `FUN_10033850` reached for an entity (its pool slot), for order tests (plan C12 `testUpdateStepOrder`;
/// step logs are closure parameters, never stored — invariant 13). A step is logged where the listing reaches its
/// call site, whether or not the callee's own gates let it act.
public enum EntityUpdateStep: Equatable, Sendable {
    /// `10033894..100339c4` — the per-tick player cache, once before the loop.
    case playerCache
    /// `10033a54..10033a78` — +0xb0 − 1 (> 0: the state start re-stamped and the entity done for this tick).
    case countdown(Int)
    /// `10033a7c..10033b60` — the state particles.
    case particles(Int)
    /// `10033b64..10033c54` — the state sound and the cue it recorded (nil = none this tick).
    case sound(Int, SoundCue?)
    /// `10033c58..10033d6c` — the state timer.
    case timer(Int)
    /// `10033d70..10033d80` — the state's `statePauseVerticalScrolling` read.
    case pauseFlag(Int, Bool)
    /// `10033d84..10033d8c` — `FUN_10015930`.
    case animation(Int)
    /// `10033d94..10033e08` — the rules (`FUN_10015550` when the state's +0x24 > 0).
    case rules(Int)
    /// `10033e0c..10033e98` — visibility / tint targets, colourise, tint colour, `FUN_10012750`.
    case ramps(Int)
    /// `10033ea0..10033ec8` — +0xac.
    case hittable(Int)
    /// `10033ecc..10033f08` — scale target / step, `FUN_10012840`, `FUN_10012940`, `FUN_10012c10`.
    case scale(Int)
    /// `10033f10..10033f58` — `FUN_10036930`.
    case ownerCopy(Int)
    /// `10033f5c..10033f8c` — `stateDestructIfVerticalScrollingNotPaused`.
    case destructIfScrolling(Int)
    /// `10033f90..10033fe8` — `FUN_10015280`.
    case motion(Int)
    /// `10033fec..10034018` — `FUN_10012ca0(e, 0x80, 1)`.
    case integrate(Int)
    /// `1003401c..10034054` — lock / link / orbit.
    case followOwner(Int)
    /// `10015b64` — `FUN_10017150`, the first call of `FUN_10015b40` (`10034060`).
    case rotationGate(Int)
    /// `10015b6c..1001619c` — the rest of `FUN_10015b40`.
    case spawnSets(Int)
    /// `10034068..10034314` — the player collisions.
    case playerCollision(Int)
    /// `10034318..100343a8` — the motion blur.
    case motionBlur(Int)
    /// `100343ac..100344e8` — the crosshair lock.
    case crosshair(Int)
    /// `100344ec..10034570` — the ground obstacles.
    case obstacle(Int)
    /// `10034574..10034594` — entity ↔ entity.
    case entityCollision(Int)
    /// `100345d4` — `FUN_10036610`, after the loop.
    case sweep
}

/// The entity update `FUN_10033850(now) @ 10033850` (listing `10033850..100345ec`, read end to end for C12; the dump
/// block `// ==== FUN_10033850`). Returns its byte r1+0x140: some entity reached the pause test in a state with
/// `statePauseVerticalScrolling` (the world update then pauses the scroll, `1000702c..10007048`).
///
/// **Order** (`now` = r17 = G+0x1c):
/// 1. `1003387c..10033890` byte = 0; fewer than one active group → return 0 (no cache, no sweep).
/// 2. `10033894..100339c4` the player cache (`playerCollisionCache`): r24 = trunc(flli 54) + 32, r23 = trunc(flli 55),
///    per player in state 4: rect, crosshair point, +0x361, position, radius.
/// 3. `100339c8..100345d0` every group, every member, both counts re-read per step (`100345a0`, `100345c0` — `Walk`:
///    an entity or group appended during the pass is visited by the same pass). Per entity (r19), r18 = its state
///    (`FUN_10014650`, `10033a4c`), r31 = its unit:
///    1. `10033a54..10033a78` +0xb0 −= 1; still > 0 → +0xa4 = now and done.
///    2. `10033a7c..10033b60` state particles: `stateParticles` ≠ `none` and (Repeat: +0xf0 == 0 or now ≥ +0xf0 +
///       RepeatDelay; else +0xf4 == 0) → (MaxNumBursts == 0 or +0xf4 < Max → `FUN_10043340` {position, colour,
///       delay 0, ground = unit layer `grnd`, type}); +0xf4 += 1, +0xf0 = now.
///    3. `10033b64..10033c54` state sound: id ≠ `none` and (Loop: +0xe4 == 0 or now ≥ +0xe4 + LoopDelay; else
///       enterCount[state] == 1 → +0xe8 == 0; else RepeatOnStateChange → +0xe8 == 0) → `AllowOnlyOneInstance` asks
///       `FUN_100476e0` (the mixer) — **"not playing" here** (invariant 10: dead in shipped data, census-asserted) —
///       then (MaxNumToPlay == 0 or +0xe8 < Max → `FUN_100475e0(state, 1)` = `SoundPlay.record`, its one pitch draw
///       `10047618`); +0xe8 += 1, +0xe4 = now. Every entity, every tick.
///    4. `10033c58..10033d6c` the timer (`stepStateTimer`): Delete / Destroy / a state entry that deletes or destroys
///       → done (`b 0x10034598`); else r18 re-read.
///    5. `10033d70..10033d80` the pause test on r18 (the timer's new state counts).
///    6. `10033d8c` `FUN_10015930` (`stepAnimation`).
///    7. `10033d94..10033e08` the state's +0x24 > 0 → `FUN_10015550` (`applyRules`): delete / destroy → done; else
///       r18 re-read — **st0**, the state every later r18 read uses, even after the motion controller changes it.
///    8. `10033e0c..10033e98` +0x6c/+0x70 = float(RequiredVisibility / VisibilityDelta), +0x54 = DoColorise,
///       +0x5c/+0x60 = float(Tint / TintDelta), +0x64 = TintColor; `FUN_10012750` (`stepRamps`).
///    9. `10033ea0..10033ec8` +0xac (`updateHittable`).
///    10. `10033ecc..10033f08` +0x88/+0x8c = `FUN_1001a260`(RequiredScale / ScaleDelta); `FUN_10012840`,
///        `FUN_10012940`, `FUN_10012c10`.
///    11. `10033f10..10033f58` `FUN_10036930` (`copyFromOwner`, st0).
///    12. `10033f5c..10033f8c` st0 `DestructIfVerticalScrollingNotPaused` and `FUN_1000fff0` (speed == 0) false →
///        `FUN_10016300(e, −1, now)`, done.
///    13. `10033f90..10033fe8` `FUN_10015280` (`updateMotion`): delete → +0xcb = 1, +0xd9 = −1; destroy →
///        `FUN_10016300(e, −1, now)`; either → done.
///    14. `10033fec..10034018` `FUN_10012ca0(e, 0x80, 1)` (`integrateAndCull`) false → +0xcb = 1, +0xd9 = −1 (silent),
///        done.
///    15. `1003401c..10034054` lock / link / orbit on st0 (`followOwner`).
///    16. `10034060` `FUN_10015b40`: `FUN_10017150` (`rotationGate`, result unused, `10015b64`), then the spawn sets
///        (`runSpawnSets`).
///    17. `10034068..10034070` deleted → done. `10034074..10034088` the rect `FUN_10012ad0` (kept for step 20).
///    18. `10034090..10034314` the player collisions on st0 (`collideWithPlayers`; drops a slot whose player left
///        state 4).
///    19. `10034318..10034320` deleted → done. `10034324..100343a8` motion blur: st0 `MotionBlur_Required` and face ≠
///        `none` → **draw** `R(MinTime, MaxTime)` (`10034348`), now > +0xec + R (`cmpw; ble`) → +0xec = now,
///        `FUN_10046840` {entity, InitialVisibility, VisibilityDelta, AllowGlowDrawing}; its first refusal at the
///        limit posts "Reached Motion Blur Limit" (type 1, upper 1, readout 0 — `10046ef4..10046f04`).
///    20. `100343ac..100344e8` **the crosshair lock — the `FUN_1003bab0(h, 1)` call site `100344c4`**: unit not
///        `harmlessToPlayers` (+0x11a, `100343ac`), unit layer `grnd` (`100343b8..100343c8`), unit
///        `canBeHitByPlayerProjectile` (+0x11c, `100343cc`), st0 `IsTargetable` (+0x34e, `100343d8`); then per player
///        p = 0, 1: the cache slot active (r1+0x40) and its lock byte (r1+0x3c: player +0x361 at cache time) clear,
///        the cached crosshair point (r1+0xc4) with `float(left) ≤ x` (`10034440 fcmpo; cror eq,gt,eq; bne`), `x <
///        float(right)` (`10034464 fcmpo; bge`), `float(top) ≤ y` (`10034488`), `y < float(bottom)` (`100344ac`) on the
///        step-17 rect → `FUN_1003bab0(player + 0x240, 1)` and the lock byte = 1 (`100344b4..100344d0`).
///    21. `100344ec..10034570` the ground obstacles (`collideWithObstacles`).
///    22. `10034574..10034594` not deleted and st0 `Collides` → `FUN_10036cf0` (`entityCollisionStep`).
/// 4. `100345d4` `FUN_10036610` (`sweepDeleted`), then the byte (`100345d8`).
extension GameState {
    /// `FUN_10033850` at game time `flags.gameTime` (see the type comment). Returns the pause flag.
    @discardableResult
    public mutating func updateEntities(log: ((EntityUpdateStep) -> Void)? = nil) -> Bool {
        let now = flags.gameTime                                             // r17 (the caller's G+0x1c)
        var paused = false                                                   // 1003387c stb r0,0x140(r1)
        guard world.groups.count >= 1 else { return false }                  // 10033880..10033890
        var cache = playerCollisionCache()                                   // 10033894..100339c4
        log?(.playerCache)
        var walk = EntityWorld.Walk()                                        // 100339c8..100339e4
        while let i = walk.next(in: world) {                                 // 100339e8..100345d0
            updateEntity(i, now: now, cache: &cache, paused: &paused, log: log)
        }
        sweepDeleted()                                                       // 100345d4 FUN_10036610
        log?(.sweep)
        return paused                                                        // 100345d8
    }

    /// One member's update (`10033a44..10034594`; the steps of the type comment). Every exit is the listing's
    /// `b 0x10034598`.
    private mutating func updateEntity(_ i: Int, now: Int32, cache: inout PlayerCollisionCache, paused: inout Bool,
                                       log: ((EntityUpdateStep) -> Void)?) {
        // 1. Spawn-in countdown.
        world.entities[i].spawnCountdown &-= 1                               // 10033a54..10033a64
        log?(.countdown(i))
        guard world.entities[i].spawnCountdown <= 0 else {                   // 10033a68..10033a70 (cmpwi; ble)
            world.entities[i].stateStart = now                               // 10033a74
            return
        }
        // The original reads unit + 0x4e0 + state·0x5e0 unchecked; a state outside the unit's states (never in shipped
        // data) is not updated here.
        guard let st = currentState(i) else { return }                       // 10033a4c FUN_10014650 (r18)
        let u = assets.definitions.units[world.entities[i].unit]             // 10033a5c (r31)

        // 2. State particles.
        stateParticles(i, st, u, now: now)                                   // 10033a7c..10033b60
        log?(.particles(i))

        // 3. State sound.
        let cue = stateSound(i, st, now: now)                                // 10033b64..10033c54
        log?(.sound(i, cue))

        // 4. Timer.
        log?(.timer(i))
        if stepStateTimer(i, now: now) { return }                            // 10033c58..10033d6c

        // 5. Pause test (the timer's new state, re-read at 10033d60..10033d6c).
        let pauses = pausesScrolling(i)                                      // 10033d70..10033d78
        if pauses { paused = true }                                          // 10033d7c..10033d80
        log?(.pauseFlag(i, pauses))

        // 6. Animation.
        stepAnimation(i, now: now)                                           // 10033d84..10033d8c FUN_10015930
        log?(.animation(i))

        // 7. Rules (the +0x24 gate is applyRules' first test).
        log?(.rules(i))
        if applyRules(i, now: now) { return }                                // 10033d94..10033df8

        // st0: r18 after the timer / rules re-reads (10033e00..10033e08) — every later r18 read.
        guard let st0 = currentState(i) else { return }

        // 8. Visibility / tint targets and the ramps.
        do {                                                                 // 10033e0c..10033e98
            var o = world.entities[i].object
            o.visibilityTarget = Float(st0.stateRequiredVisibilityPercent)   // 10033e0c..10033e38 (int → float, fsubs)
            o.visibilityStep = Float(st0.stateVisibilityDeltaPercent)        // 10033e3c..10033e54
            o.hideSprite = st0.stateDoColorise                               // 10033e58..10033e5c (+0x34d → +0x54)
            o.glowTarget = Float(st0.stateTintPercent)                       // 10033e60..10033e74
            o.glowStep = Float(st0.stateTintDeltaPercent)                    // 10033e78..10033e8c
            o.glowTintColour = st0.stateTintColor                            // 10033e90..10033e94
            o.stepRamps()                                                    // 10033e98 FUN_10012750
            world.entities[i].object = o
        }
        log?(.ramps(i))

        // 9. Hittable.
        updateHittable(i)                                                    // 10033ea0..10033ec8
        log?(.hittable(i))

        // 10. Scale target / step, the scale ramp, the size, the hit glow.
        world.entities[i].object.scaleTarget = Self.percentScale(st0.stateRequiredScalePercent)   // 10033ecc..10033ed8
        world.entities[i].object.scaleStep = Self.percentScale(st0.stateScaleDeltaPercent)        // 10033edc..10033ee8
        world.entities[i].object.stepScale()                                 // 10033ef0 FUN_10012840
        refreshEntitySize(i)                                                 // 10033efc FUN_10012940
        world.entities[i].object.stepHitGlow()                               // 10033f08 FUN_10012c10
        log?(.scale(i))

        // 11. Owner copies.
        copyFromOwner(i, state: st0)                                         // 10033f10..10033f58
        log?(.ownerCopy(i))

        // 12. Destruct if the scroll is not paused.
        log?(.destructIfScrolling(i))
        if st0.stateDestructIfVerticalScrollingNotPaused && scroll.speed != 0 {   // 10033f5c..10033f74 (FUN_1000fff0)
            destroyEntity(i, killer: -1, now: now)                           // 10033f78..10033f84
            return
        }

        // 13. The motion controller.
        log?(.motion(i))
        let outcome = updateMotion(i, now: now)                              // 10033f90..10033fa0 FUN_10015280
        if removeByStateMachine(i, outcome, now: now) { return }             // 10033fa8..10033fe8

        // 14. Integrate and cull — off the field: the silent delete.
        log?(.integrate(i))
        if !integrateAndCull(i, margin: 0x80) {                              // 10033fec..10034004 FUN_10012ca0(e, 0x80, 1)
            world.entities[i].deleted = true                                 // 10034008..1003400c
            world.entities[i].killer = -1                                    // 10034010..10034014
            return
        }

        // 15. Lock / link / orbit.
        followOwner(i, state: st0)                                           // 1003401c..10034054
        log?(.followOwner(i))

        // 16. FUN_10015b40: the rotation gate, then the spawn sets.
        rotationGate(i, now: now)                                            // 10034060 → 10015b64 FUN_10017150
        log?(.rotationGate(i))
        runSpawnSets(i, now: now)                                            // 10015b6c..1001619c
        log?(.spawnSets(i))

        // 17. Deleted → done; the rect for the crosshair test.
        guard !world.entities[i].deleted else { return }                     // 10034068..10034070
        let rect = entityRect(i)                                             // 10034074..10034088 FUN_10012ad0

        // 18. Player collisions.
        collideWithPlayers(i, state: st0, cache: &cache, now: now)           // 10034090..10034314
        log?(.playerCollision(i))

        // 19. Deleted → done; the motion blur.
        guard !world.entities[i].deleted else { return }                     // 10034318..10034320
        motionBlur(i, st0, now: now)                                         // 10034324..100343a8
        log?(.motionBlur(i))

        // 20. The crosshair lock.
        crosshairLock(i, st0, u, rect: rect, cache: &cache)                  // 100343ac..100344e8
        log?(.crosshair(i))

        // 21. Ground obstacles.
        collideWithObstacles(i)                                              // 100344ec..10034570
        log?(.obstacle(i))

        // 22. Entity ↔ entity.
        entityCollisionStep(i, state: st0, now: now)                         // 10034574..10034594
        log?(.entityCollision(i))
    }

    /// Step 2 (`10033a7c..10033b60`).
    private mutating func stateParticles(_ i: Int, _ st: UnitState, _ u: UnitDefinition, now: Int32) {
        guard st.stateParticles != .none else { return }                     // 10033a7c..10033a8c
        let e = world.entities[i]
        let go: Bool
        if st.stateParticlesRepeat {                                         // 10033a90..10033a98
            go = e.lastBurst == 0 || !(now < e.lastBurst &+ st.stateParticlesRepeatDelay)   // 10033a9c..10033ab8
        } else {
            go = e.burstCount == 0                                           // 10033ac0..10033acc
        }
        guard go else { return }                                             // 10033ad0..10033ad4
        let maxBursts = st.stateParticlesMaxNumBursts
        if maxBursts == 0 || e.burstCount < maxBursts {                      // 10033ad8..10033aec
            let req = ParticleRequest(x: e.object.x, y: e.object.y, colour: st.stateParticlesColor, delay: 0,
                                      ground: u.layer == UnitDefinition.ground, type: st.stateParticles)   // 10033af0..10033b48
            particles.emit(req, rng: &rng)                                   // 10033b4c FUN_10043340
        }
        world.entities[i].burstCount &+= 1                                   // 10033b54..10033b5c
        world.entities[i].lastBurst = now                                    // 10033b60
    }

    /// Step 3 (`10033b64..10033c54`). Returns the cue recorded, if any.
    private mutating func stateSound(_ i: Int, _ st: UnitState, now: Int32) -> SoundCue? {
        let e = world.entities[i]
        let snd = st.stateEntrySound
        var play = false
        if snd.id != .none {                                                 // 10033b64..10033b74
            if st.stateSoundLoop {                                           // 10033b78..10033b80
                play = e.lastSoundTime == 0 || !(now < e.lastSoundTime &+ st.stateSoundLoopDelay)   // 10033b84..10033ba0
            } else {
                let s = Int(e.state)
                let entered = e.enterCount.indices.contains(s) ? e.enterCount[s] : 0
                if entered == 1 {                                            // 10033ba8..10033bbc
                    play = e.soundCount == 0                                 // 10033bc0..10033bcc
                } else if st.stateSoundRepeatOnStateChange {                 // 10033bd4..10033bdc
                    play = e.soundCount == 0                                 // 10033be0..10033bec
                }
            }
        }
        guard play else { return nil }                                       // 10033bf0..10033bf4
        // 10033bf8..10033c14: AllowOnlyOneInstance → FUN_100476e0 (is this sound playing?) — "not playing" (invariant 10).
        var cue: SoundCue? = nil
        let maxPlays = st.stateSoundMaxNumToPlay
        if maxPlays == 0 || e.soundCount < maxPlays {                        // 10033c20..10033c34
            cue = SoundPlay.record(snd, allowMultiple: true, rng: &rng)      // 10033c38..10033c40 FUN_100475e0(state, 1)
            if let cue { cues.sounds.append(cue) }
        }
        world.entities[i].soundCount &+= 1                                   // 10033c48..10033c50
        world.entities[i].lastSoundTime = now                                // 10033c54
        return cue
    }

    /// Step 19 (`10034324..100343a8`).
    private mutating func motionBlur(_ i: Int, _ st0: UnitState, now: Int32) {
        guard st0.stateMotionBlurRequired, world.entities[i].object.face != .none else { return }   // 10034324..1003433c
        let r = rng.range(st0.stateMotionBlurMinTimeBetweenBlurs, st0.stateMotionBlurMaxTimeBetweenBlurs)   // 10034340..10034348
        guard now > world.entities[i].lastBlur &+ r else { return }          // 10034350..1003435c (cmpw; ble)
        world.entities[i].lastBlur = now                                     // 10034360
        let req = MotionBlurRequest(object: world.entities[i].object,
                                    initialVisibility: st0.stateMotionBlurInitialVisibilityPercent,
                                    visibilityDelta: st0.stateMotionBlurVisibilityDeltaPercent,
                                    allowGlow: st0.stateMotionBlurAllowGlowDrawing)   // 10034364..100343a0
        if case .refused(postLimitMessage: true) = blurs.emit(req) {         // 100343a4 FUN_10046840
            messages.post(text: Array("Reached Motion Blur Limit".utf8), kind: .error, uppercase: true,
                          readout: 0)                                        // 10046ef4..10046f04 FUN_1002dbd0(…, 1, 1, 0)
        }
    }

    /// Step 20 (`100343ac..100344e8`; the condition is the type comment's).
    private mutating func crosshairLock(_ i: Int, _ st0: UnitState, _ u: UnitDefinition, rect: MacRect,
                                        cache: inout PlayerCollisionCache) {
        guard !u.harmlessToPlayers,                                          // 100343ac..100343b4
              u.layer == UnitDefinition.ground,                              // 100343b8..100343c8
              u.canBeHitByPlayerProjectile,                                  // 100343cc..100343d4
              st0.stateIsTargetable else { return }                          // 100343d8..100343e0
        for p in 0..<2 {                                                     // 100343e4..100344e8
            guard cache.slots[p].active, !cache.slots[p].crosshairFlag else { continue }   // 100343f8..10034410
            let x = cache.slots[p].crosshairX, y = cache.slots[p].crosshairY
            guard x >= Float(rect.left),                                     // 10034414..10034448
                  x < Float(rect.right),                                     // 1003444c..10034468
                  y >= Float(rect.top),                                      // 1003446c..10034490
                  y < Float(rect.bottom) else { continue }                   // 10034494..100344b0
            players[p].handler.setCrosshairLock(true)                        // 100344b4..100344c4 FUN_1003bab0(h, 1)
            cache.slots[p].crosshairFlag = true                              // 100344cc..100344d0
        }
    }
}
