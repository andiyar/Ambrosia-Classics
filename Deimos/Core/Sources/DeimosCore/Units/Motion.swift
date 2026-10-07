import Foundation
import HectorResources

/// `FUN_10005d40`'s outputs: found, the player's position, the distance and the player number (+0xcc).
public struct NearestPlayer: Equatable, Sendable {
    public var found: Bool
    public var x: Float
    public var y: Float
    public var distance: Float
    /// `FUN_10026c90` = player +0xcc; −1 when none is active.
    public var player: Int8

    public init(found: Bool, x: Float, y: Float, distance: Float, player: Int8) {
        self.found = found; self.x = x; self.y = y; self.distance = distance; self.player = player
    }
}

/// The motion controller and its callees, and the position integrator (units-movement.md §1, §2.1, §5, §7;
/// plan C9). Listings read for C9: `FUN_10015280` (`10015280..1001554c`), `FUN_10016cc0` (`10016cc0..10016d9c`),
/// `FUN_10017b70` (`10017b70..10017c34`), `FUN_10017c40` (`10017c40..10017ca4`), `FUN_10016fe0`
/// (`10016fe0..10017144`), `FUN_10017a10` (`10017a10..10017b64`), `FUN_10016da0` (`10016da0..10016fd4`),
/// `FUN_10017ef0` (`10017ef0..10017f74`), `FUN_10005d40` (`10005d40..10005ec0`), `FUN_10012ca0`
/// (`10012ca0..10012f18`). Every float operation is single precision (`fadds`/`fsubs`/`fmuls`/`fdivs`).
///
/// **RNG draws (C9 owns them, invariant 6):** the controller's only own sites are the cyclic motion's two
/// int draws per tick, `10017024` a = `R(trunc(Max)/2, trunc(Max))` then `10017054` b = `R(1, 100)`. The
/// range trigger's state entry (C8's `enterState`) and the no-player flee (`setFleePoint`) make theirs inside
/// the controller call, in that position.
extension GameState {
    /// `FUN_10005d40(e, &tgt, &dist, &no) @ 10005d40` — the nearest active player (state 4, `FUN_10026c60`) to the
    /// entity: for players 0, 1 `d = root(fctiwz(fmadds(dx, dx, dy·dy)))` with `dy = py − y`, `dx = px − x`
    /// (`10005dd8..10005e04`); the first kept, replaced only on strictly smaller d (`10005e40 fcmpo; bge` — ties to
    /// P1). Not found: the original's position out is the uninitialised stack slot `local_64[−1]` (units NR 3,
    /// never read — gameplay-leftovers §7.3); here (0, 0), distance 0, player −1 (`10005e90`).
    func nearestActivePlayer(to i: Int) -> NearestPlayer {
        let ex = world.entities[i].object.x, ey = world.entities[i].object.y
        var best: NearestPlayer? = nil
        for p in 0..<min(2, players.count) where players[p].lifeState == 4 {      // 10005da0..10005e64
            let d = Trig.distance(x0: ex, y0: ey, x1: players[p].object.x, y1: players[p].object.y)
            if best == nil || d < best!.distance {
                best = NearestPlayer(found: true, x: players[p].object.x, y: players[p].object.y, distance: d,
                                     player: players[p].index)
            }
        }
        return best ?? NearestPlayer(found: false, x: 0, y: 0, distance: 0, player: -1)
    }

    /// `FUN_10017ef0(e, range, &tgt, &no) @ 10017ef0` — rule conditions #8/#9: an active player exists, `range ≠ 0`
    /// and `dist < float(range)` (`10017f50 fcmpo; bge`, strict). No entity field is written.
    func playerWithinRange(_ i: Int, range: Int32) -> Bool {
        let n = nearestActivePlayer(to: i)
        guard n.found, range != 0 else { return false }                        // 10017f1c..10017f28
        return n.distance < Float(range)                                       // 10017f2c..10017f54
    }

    /// `FUN_10015280(e, now, &del, &destroy) @ 10015280` — the motion controller (units-movement §5):
    /// 1. Fleeing (+0xcc): seek with the flee speeds (`FUN_10016cc0`), turn (`FUN_100172d0`), return.
    /// 2. `FUN_10005d40`. None: +0x118 = −1; `DeleteOnNoActivePlayers` → del; `DestructOnNoActivePlayers` →
    ///    destroy; unit `fleesNorth` → flee `nora`; `fleesSouth` → `sora`; each returns. Else fall through.
    /// 3. `CyclicMotion` → `FUN_10016fe0` (two draws); unit `constrainInGameArea` → `FUN_10016da0`.
    /// 4. +0x11c/+0x120 = the target, +0x118 = the player number (`100153bc..100153d8`).
    /// 5. A player found: `OnRange == 0.0` (`fcmpu`) or `dist ≥ OnRange` (`fcmpo; bge`) → hunt = `Hunts`. Else
    ///    `OnRangeChangeTo` `"Delete"` → del, `"Destroy"` → destroy (return); empty → the old state's hold test;
    ///    ≠ `"none"` → `FUN_100146f0(e, 0, name, now)` (del/destroy → return), re-read the state, its
    ///    `ReverseDirectionOnReaction` → `FUN_10017c40`. Then (the current state) `HoldPositionToTarget` →
    ///    `FUN_10017b70`, hunt = 0; else hunt = `Hunts`. No player: hunt = 0.
    /// 6. Fleeing re-read (a flee state entered in step 5 counts): `!fleeing ∧ hunt` → seek; else ramp
    ///    (`FUN_10017a10`).
    @discardableResult
    public mutating func updateMotion(_ i: Int, now: Int32) -> StateEntryOutcome {
        if world.entities[i].fleeing {                                         // 100152b0..100152d4
            seekTarget(i)
            turnTowardTarget(i, now: now)
            return StateEntryOutcome()
        }
        guard let st = currentState(i) else { return StateEntryOutcome() }
        let u = assets.definitions.units[world.entities[i].unit]
        let near = nearestActivePlayer(to: i)                                  // 100152f8
        if !near.found {                                                       // 10015300..10015388
            world.entities[i].trackedPlayer = -1
            if st.stateDeleteOnNoActivePlayers { return StateEntryOutcome(delete: true) }
            if st.stateDestructOnNoActivePlayers { return StateEntryOutcome(destroy: true) }
            if u.fleesNorthOnNoActivePlayers { setFleePoint(i, code: FourCC("nora")!); return StateEntryOutcome() }
            if u.fleesSouthOnNoActivePlayers { setFleePoint(i, code: FourCC("sora")!); return StateEntryOutcome() }
        }
        if st.stateCyclicMotion { cyclicMotion(i) }                            // 1001538c..100153a0
        if u.constrainInGameArea { constrainInGameArea(i) }                    // 100153a4..100153b8
        // +0x11c/+0x120 = the caller's out-point (r1+0x40/+0x44). With no active player `FUN_10005d40` copies its own
        // never-written distance slots (r1+0x3c / r1+0x40 of its frame, `10005e68..10005e84` with index −1) — i.e.
        // uninitialised stack in the original. Never read while +0x118 = −1 (gameplay-leftovers §7.3); (0, 0) here.
        world.entities[i].targetX = near.x                                     // 100153bc..100153c8
        world.entities[i].targetY = near.y                                     // 100153cc..100153d0
        world.entities[i].trackedPlayer = near.player                          // 100153d4..100153d8
        var hunt = false                                                       // 100153c4 li r3,0
        if near.found {                                                        // 100153dc
            if st.stateOnRange == 0 || !(near.distance < st.stateOnRange) {    // 100153e0..100153fc
                hunt = st.stateHunts                                           // 10015508
            } else {
                let name = st.stateOnRangeChangeTo
                if name == "Delete" { return StateEntryOutcome(delete: true) } // 10015400..10015420
                if name == "Destroy" { return StateEntryOutcome(destroy: true) }   // 10015424..10015444
                var cur = st
                if !name.isEmpty && name != "none" {                           // 1001544c..1001546c
                    let out = enterState(i, named: name, spawning: false, now: now)   // 10015488
                    if out.delete || out.destroy { return out }                // 1001548c..100154a0
                    cur = currentState(i) ?? st                                // 100154a4..100154bc
                    if cur.stateReverseDirectionOnReaction {                   // 100154b8..100154d4
                        reverseOnReaction(i, targetX: near.x, targetY: near.y, distance: near.distance)
                    }
                }
                if cur.stateHoldPositionToTarget {                             // 100154dc..100154f8
                    holdPosition(i, targetX: near.x, targetY: near.y)
                    hunt = false
                } else {
                    hunt = cur.stateHunts                                      // 10015500
                }
            }
        }
        if !world.entities[i].fleeing && hunt {                                // 1001550c..1001551c
            seekTarget(i)                                                      // 10015524
        } else {
            rampToDesired(i)                                                   // 10015534
        }
        return StateEntryOutcome()
    }

    /// `FUN_10016cc0(e) @ 10016cc0` — seek the target (+0x11c/+0x120): M, D = fleeing ? `FleeSpeed`/`FleeDelta`
    /// : `MaxSpeed`/`Delta`; per axis accel = x < tx ? +D : −D (`fcmpo; bge` — a tie goes negative), v += accel,
    /// clamped to [−M, M] (`> M → M`, else `< −M → −M`). Bang-bang, no damping.
    mutating func seekTarget(_ i: Int) {
        guard let st = currentState(i) else { return }
        var e = world.entities[i]
        let m: Float = e.fleeing ? st.stateFleeSpeed : st.stateMaxSpeed        // 10016cdc..10016cf0
        let d: Float = e.fleeing ? st.stateFleeDelta : st.stateDelta
        e.accelX = e.object.x < e.targetX ? d : -d                             // 10016cf4..10016d10
        e.accelY = e.object.y < e.targetY ? d : -d                             // 10016d14..10016d30
        e.object.vx = Self.clampedStep(e.object.vx, e.accelX, m)               // 10016d34..10016d64
        e.object.vy = Self.clampedStep(e.object.vy, e.accelY, m)               // 10016d68..10016d98
        world.entities[i] = e
    }

    /// `FUN_10017b70(e, &tgt) @ 10017b70` — hold position: `HoldMaxSpeed` / `HoldDelta` with the opposite sign
    /// (x < tx → −HD, else +HD — `10017b98 bge`, `10017b9c fneg`), then the same clamped step.
    mutating func holdPosition(_ i: Int, targetX tx: Float, targetY ty: Float) {
        guard let st = currentState(i) else { return }
        var e = world.entities[i]
        let m = st.stateHoldMaxSpeed, d = st.stateHoldDelta                    // 10017b90..10017b94
        e.accelX = e.object.x < tx ? -d : d                                    // 10017b84..10017ba8
        e.accelY = e.object.y < ty ? -d : d                                    // 10017bac..10017bc8
        e.object.vx = Self.clampedStep(e.object.vx, e.accelX, m)               // 10017bcc..10017bfc
        e.object.vy = Self.clampedStep(e.object.vy, e.accelY, m)               // 10017c00..10017c30
        world.entities[i] = e
    }

    /// v + a (`fadds`), then `> m → m`, else `< −m → −m` (`fneg`).
    private static func clampedStep(_ v: Float, _ a: Float, _ m: Float) -> Float {
        let n: Float = v + a
        if n > m { return m }
        if n < -m { return -m }
        return n
    }

    /// `FUN_10017c40(e, &tgt, f1 = dist) @ 10017c40` — reverse on reaction: d = tgt − pos (`fsubs`); dist ≠ 0.0
    /// (`fcmpu`) → d /= dist (`fdivs`); desired = (−(dx·M), −(dy·M)) (`fmuls`, `fneg`) with the current state's
    /// `MaxSpeed`. Only the desired velocity changes. No shipped state sets the key (census 0 of 1167).
    mutating func reverseOnReaction(_ i: Int, targetX tx: Float, targetY ty: Float, distance: Float) {
        guard let st = currentState(i) else { return }
        var dx: Float = tx - world.entities[i].object.x                        // 10017c5c
        var dy: Float = ty - world.entities[i].object.y                        // 10017c60
        if distance != 0 { dx = dx / distance; dy = dy / distance }            // 10017c50..10017c6c
        world.entities[i].desiredVX = -(dx * st.stateMaxSpeed)                 // 10017c84..10017c90
        world.entities[i].desiredVY = -(dy * st.stateMaxSpeed)                 // 10017c94..10017ca0
    }

    /// `FUN_10016fe0(e) @ 10016fe0` — cyclic motion (units-movement §5.5), **two draws every tick**: m =
    /// `fctiwz(MaxSpeed)` (`10017008..10017014`), **draw `10017024`** a = `R(m/2, m)` (C division: `rlwinm; add;
    /// srawi`), **draw `10017054`** b = `R(1, 100)`; L = float(a) + float(b) / 100.0 (`fdivs` by `*(float*)
    /// (0x100d6c8c + 0x10)` = 100.0, `fadds`). Per axis, x then y: `v > L` → v = L, accel = −accel; then (re-read)
    /// `v < −L` → v = −L, accel = −accel (`10017090..100170fc`); then v += accel (both axes), desired = v.
    mutating func cyclicMotion(_ i: Int) {
        guard let st = currentState(i) else { return }
        let m = EntityDraw.fctiwz(st.stateMaxSpeed)                            // 10017008..10017014
        let a = Float(rng.range(m / 2, m))                                     // 10017018..10017050
        let b = Float(rng.range(Int32(1), 100))                                // 10017040..10017080
        let l: Float = a + b / Float(100)                                      // 10017088..1001708c
        var e = world.entities[i]
        if e.object.vx > l { e.object.vx = l; e.accelX = -e.accelX }           // 10017090..100170a4
        if e.object.vx < -l { e.object.vx = -l; e.accelX = -e.accelX }         // 100170a8..100170c4
        if e.object.vy > l { e.object.vy = l; e.accelY = -e.accelY }           // 100170c8..100170e0
        if e.object.vy < -l { e.object.vy = -l; e.accelY = -e.accelY }         // 100170e4..100170fc
        e.object.vx = e.object.vx + e.accelX                                   // 10017100..1001710c
        e.object.vy = e.object.vy + e.accelY                                   // 10017110..1001711c
        e.desiredVX = e.object.vx                                              // 10017120..10017124
        e.desiredVY = e.object.vy                                              // 10017128..1001712c
        world.entities[i] = e
    }

    /// `FUN_10017a10(e) @ 10017a10` — ramp to desired (units-movement §5.6): `isStationary` (+0x13c) → v, desired,
    /// accel = (0.0, 0.0) (`0x100d67f4`). Else the current state's `OrbitOwner` → only vx steps toward `MaxSpeed`
    /// by `Delta` (`vx < M` → vx += D, `> M → M`; `vx > M` → vx −= D, `< M → M`; `10017b18..10017b60` — vx is the
    /// orbit rate). Else per axis: `v < desired` → v += accel, `> desired → desired`; `v > desired` → v += accel,
    /// `< desired → desired`; equal → unchanged (`10017a64..10017b14`).
    mutating func rampToDesired(_ i: Int) {
        var e = world.entities[i]
        if e.stationary {                                                      // 10017a10..10017a40
            e.object.vx = 0; e.object.vy = 0
            e.desiredVX = 0; e.desiredVY = 0
            e.accelX = 0; e.accelY = 0
            world.entities[i] = e
            return
        }
        guard let st = currentState(i) else { return }
        if st.stateOrbitOwner {                                                // 10017a58..10017a60
            let m = st.stateMaxSpeed, d = st.stateDelta
            if e.object.vx < m {                                               // 10017b24..10017b44
                e.object.vx = e.object.vx + d
                if e.object.vx > m { e.object.vx = m }
            } else if e.object.vx > m {                                        // 10017b48..10017b64
                e.object.vx = e.object.vx - d
                if e.object.vx < m { e.object.vx = m }
            }
            world.entities[i] = e
            return
        }
        e.object.vx = Self.ramp(e.object.vx, e.accelX, e.desiredVX)            // 10017a64..10017ab8
        e.object.vy = Self.ramp(e.object.vy, e.accelY, e.desiredVY)            // 10017abc..10017b14
        world.entities[i] = e
    }

    private static func ramp(_ v: Float, _ a: Float, _ want: Float) -> Float {
        if v < want {
            let n: Float = v + a
            return n > want ? want : n
        }
        if v > want {
            let n: Float = v + a
            return n < want ? want : n
        }
        return v
    }

    /// `FUN_10016da0(e) @ 10016da0` — constrain in the game area (units-movement §5.7): W = `fctiwz(PermFloat 54)`,
    /// H = `fctiwz(PermFloat 55)`; each hit negates v, accel and desired on that axis and places the entity:
    /// `x < −32.0` → x = −32.0 (the centre); `x + float(+0x24) > float(W + 32)` → x = float(W − w′ + 32) —
    /// **the scaled frame width +0x24, not the half width** (`10016e28 lwz r6,0x24(r31)`); `y − float(hh) < 0.0` →
    /// y = float(hh); `y + float(hh) > float(H)` → y = float(H − hh) (hh = +0x30). Table `0x100d6c8c`:
    /// +0x0 = 0.0, +0xc = −32.0. Runs before the integration of the same tick.
    mutating func constrainInGameArea(_ i: Int) {
        let w = EntityDraw.fctiwz(assets.floats[54])                           // 10016dac..10016dd8
        let h = EntityDraw.fctiwz(assets.floats[55])                           // 10016dd0..10016df8
        var e = world.entities[i]
        func flipX() { e.object.vx = -e.object.vx; e.accelX = -e.accelX; e.desiredVX = -e.desiredVX }
        func flipY() { e.object.vy = -e.object.vy; e.accelY = -e.accelY; e.desiredVY = -e.desiredVY }
        let left = Float(-32)
        if e.object.x < left { flipX(); e.object.x = left }                    // 10016de8..10016e24
        let sw = e.object.scaledWidth
        if e.object.x + Float(sw) > Float(w &+ 32) {                           // 10016e28..10016e70
            flipX(); e.object.x = Float(w &- sw &+ 32)                         // 10016e74..10016eb4
        }
        let hh = e.object.halfHeight
        if e.object.y - Float(hh) < 0 {                                        // 10016eb8..10016eec
            flipY(); e.object.y = Float(hh)                                    // 10016ef0..10016f2c
        }
        if e.object.y + Float(hh) > Float(h) {                                 // 10016f30..10016f74
            flipY(); e.object.y = Float(h &- hh)                               // 10016f78..10016fb8
        }
        world.entities[i] = e
    }

    /// `FUN_10012ca0(e, margin, mode 1) @ 10012ca0` — integrate and cull (units-movement §2.1, §7; the only caller,
    /// `FUN_10033850` `10033ff8`, passes 0x80, 1). Ground (+0x19 = 0): y += float(scrolled this tick)
    /// (`FUN_1000fed0` = `ScrollState.scrolled`, `10012ccc..10012cfc`); then x += vx, y += vy (`fadds`). Keep iff
    /// `x + float(hw) ≥ float(−m)` (`blt` culls), `x − float(hw) ≤ float(W + m)` (`bgt`), **`y ≥ float(−m)`** (the
    /// centre — no half-height on the top test, `10012df0`), `y − float(hh) ≤ float(H + m)` (`ble` keeps — an
    /// unordered compare culls), W/H = `fctiwz(PermFloat 54/55)`. Returns false = off the field; the caller flags
    /// the silent delete (+0xcb = 1, +0xd9 = 0xff, `10034008..10034014`). Mode 0 (−32 / 0 bounds) has no caller
    /// and is not modelled.
    public mutating func integrateAndCull(_ i: Int, margin m: Int32 = 128) -> Bool {
        var o = world.entities[i].object
        if !o.air {                                                            // 10012cc0..10012cc8
            o.y = o.y + Float(scroll.scrolled)                                 // 10012ccc..10012cfc
        }
        o.x = o.x + o.vx                                                       // 10012d00..10012d10
        o.y = o.y + o.vy                                                       // 10012d14..10012d20
        world.entities[i].object = o
        let w = EntityDraw.fctiwz(assets.floats[54])                           // 10012d24..10012d38
        let h = EntityDraw.fctiwz(assets.floats[55])                           // 10012d3c..10012d54
        let hw = Float(o.halfWidth), hh = Float(o.halfHeight)
        if o.x + hw < Float(0 &- m) { return false }                           // 10012d5c..10012da4
        if o.x - hw > Float(w &+ m) { return false }                           // 10012da8..10012dd8
        if o.y < Float(0 &- m) { return false }                                // 10012ddc..10012df4
        if !(o.y - hh <= Float(h &+ m)) { return false }                       // 10012df8..10012e30
        return true
    }
}
