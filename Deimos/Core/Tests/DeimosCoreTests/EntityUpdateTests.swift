import XCTest
import HectorResources
@testable import DeimosCore

/// The entity update `FUN_10033850`, the world update `FUN_10006b50`, the group draw `FUN_100345f0` and the player
/// draw `FUN_100298c0` (plan C12; waves-and-enemies.md §3, bosses.md §2, sprite-geometry-draw.md §3.2, §6). Shipped
/// units only; every loop names its bound and fails on reaching it (G11).
final class EntityUpdateTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    /// A bare world at game time `t`: P1 in life state 4 at (208, 400), no other entity, map 480 × 3600.
    private func state(seed: UInt32 = 0x469c2, at t: Int32 = 100) throws -> GameState {
        var s = GameState(assets: try assets(), prefs: DeimosPrefs.fresh, seed: seed)
        s.flags.sector = 1
        s.flags.numPlayers = 1
        s.scroll.levelStart(rect: MacRect(top: 0, left: 0, bottom: 3600, right: 480))
        s.players[0].lifeState = 4
        s.players[0].object.x = 208
        s.players[0].object.y = 400
        s.flags.gameTime = t
        return s
    }

    /// A level-1 world as the session's level start leaves it (`le07`, sector 1, one player set up and level-started),
    /// its placements filtered to `only` (nil = all), the load pass run.
    private func level1(only: String?) throws -> GameState {
        let a = try assets()
        var s = GameState(assets: a, prefs: DeimosPrefs.fresh, seed: 0x469c2)
        s.flags.numPlayers = 1
        s.flags.sector = 1
        s.flags.level = FourCC("le07")!
        let le07 = try XCTUnwrap(a.definitions.levels.first { $0.id == FourCC("le07")! })
        s.scroll.levelStart(rect: le07.background)
        try s.setupPlayer(0)
        try s.setupPlayer(1)
        s.playerLevelStart(0)
        s.playerLevelStart(1)
        if let only {
            s.levelStartEntities(level: le07, include: { $0.unit == FourCC(only)! })
        } else {
            s.levelStartEntities(level: le07)
        }
        s.spawnLoadPassLevelObjects()
        return s
    }

    /// One shipped unit spawned through `FUN_10033220` at (x, y), spawned in (+0xb0 = 0): its first member.
    @discardableResult
    private func put(_ s: inout GameState, _ id: String, x: Float, y: Float) throws -> Int {
        try put(&s, FourCC(id)!, x: x, y: y)
    }

    @discardableResult
    private func put(_ s: inout GameState, _ id: FourCC, x: Float, y: Float) throws -> Int {
        let r = try XCTUnwrap(s.spawn(SpawnRequest(unit: id, x: x, y: y)), "\(id)")
        s.world.entities[r.entity].object.x = x
        s.world.entities[r.entity].object.y = y
        s.world.entities[r.entity].spawnCountdown = 0
        return r.entity
    }

    /// A fresh group of `ids` (one member each, state 0 entered as at spawn), at (x, y) each.
    private func group(_ s: inout GameState, _ ids: [String], x: Float, y: Float) throws -> [Int] {
        let first = FourCC(ids[0])!
        let g = s.world.openGroup(unit: first, size: Int32(ids.count), ownerGroupID: nil, editorHeading: 0,
                                  stationary: false, terrainEffects: false)
        var out: [Int] = []
        for id in ids {
            let ui = try XCTUnwrap(s.assets.unitIndex[FourCC(id)!], id)
            let i = try XCTUnwrap(s.world.allocate())
            s.world.groups[g].members.append(i)
            s.assignUnit(i, unit: ui)
            s.world.entities[i].serial = s.world.takeSerial()
            s.world.entities[i].groupID = s.world.groups[g].id
            s.world.entities[i].object.x = x
            s.world.entities[i].object.y = y
            s.enterState(i, named: s.assets.definitions.units[ui].states[0].stateName, spawning: true,
                         now: s.flags.gameTime)
            s.world.entities[i].object.x = x
            s.world.entities[i].object.y = y
            out.append(i)
        }
        return out
    }

    // MARK: - FUN_10033850

    /// The per-entity step order of `FUN_10033850` (`10033850..100345d8`) for one entity that runs every step (`bocr`
    /// on its first tick: no timer, no rule, kept), incl. the state sound's one pitch draw (`10033c40` → `10047618`);
    /// an entity appended during the pass is visited by the same pass (`100345a0` / `100345c0`); and the census of
    /// invariant 10 — every `AllowOnlyOneInstance` state has sound `none`, so Core's "not playing" is exact.
    func testUpdateStepOrder() throws {
        let a = try assets()
        let only = a.definitions.units.flatMap(\.states).filter(\.stateSoundAllowOnlyOneInstance)
        XCTAssertEqual(only.count, 6)
        XCTAssertTrue(only.allSatisfy { $0.stateEntrySound.id == .none })
        // st0 (`10033e08`) feeds the owner copy, follow-owner, player and entity collisions. Census of why no shipped
        // case can tell st0 from a re-read at those sites: the owner copy runs before the motion controller; every
        // range trigger (`FUN_100146f0`, last name match wins) keeps the six gates those sites read; no state has an
        // on-hit change (delay ≠ 0, name set); a unit's shield-depletion state never changes Collides.
        func gates(_ s: UnitState) -> [Bool] {
            [s.stateCollides, s.stateCollidesWithPlayers, s.passHitsToOwner, s.stateLockToOwnerLoc,
             s.stateLinkToOwnerLoc, s.stateOrbitOwner]
        }
        var triggers = 0
        for u in a.definitions.units {
            let live = u.states.prefix(Int(u.numStates))
            for st in u.states where st.stateOnRange > 0 {
                guard let to = live.last(where: { $0.stateName == st.stateOnRangeChangeTo }) else { continue }
                triggers += 1
                XCTAssertEqual(gates(to), gates(st), "\(u.id) \(st.stateName)")
            }
            if let dep = live.first(where: \.stateUseThisStateOnShieldDepletion) {
                XCTAssertTrue(u.states.allSatisfy { $0.stateCollides == dep.stateCollides }, "\(u.id)")
            }
        }
        XCTAssertEqual(triggers, 21)
        XCTAssertFalse(a.definitions.units.flatMap(\.states).contains {
            $0.stateOnHitChangeStateDelay != 0 && !$0.stateOnHitChangeTo.isEmpty
        })

        var s = try state()
        let b = try put(&s, "bocr", x: 200, y: 300)
        let st = try XCTUnwrap(s.currentState(b))
        let snd = st.stateEntrySound
        XCTAssertEqual(snd.id, FourCC("bocr"))
        XCTAssertNotEqual(snd.minPitch, snd.maxPitch)                         // one draw (FUN_10046580 draws when lo ≠ hi)
        var copy = s.rng
        let pitch = copy.range(snd.minPitch, snd.maxPitch)
        let cue = SoundCue(id: snd.id, priority: snd.priority & 0xff, volume: snd.minVolume, pitch: pitch,
                           allowMultiple: true)
        var steps: [EntityUpdateStep] = []
        let paused = s.updateEntities { steps.append($0) }
        XCTAssertFalse(paused)
        XCTAssertEqual(steps, [
            .playerCache, .countdown(b), .particles(b), .sound(b, cue), .timer(b), .pauseFlag(b, false),
            .animation(b), .rules(b), .ramps(b), .hittable(b), .scale(b), .ownerCopy(b), .destructIfScrolling(b),
            .motion(b), .integrate(b), .followOwner(b), .rotationGate(b), .spawnSets(b), .playerCollision(b),
            .motionBlur(b), .crosshair(b), .obstacle(b), .entityCollision(b), .sweep,
        ])
        XCTAssertEqual(s.rng, copy)                                           // the pitch was the pass's only draw
        XCTAssertEqual(s.cues.sounds.last, cue)
        XCTAssertEqual(s.world.entities[b].soundCount, 1)
        XCTAssertEqual(s.world.entities[b].lastSoundTime, 100)

        // An entity appended mid-pass (a shuriken group from 07s1's spawn set) is visited by that same pass.
        var t = try state(seed: 0x469c2, at: 1000)
        let c = try put(&t, "07s1", x: 210, y: 100)
        t.enterState(c, named: "Pause, Spawn Shurikens", spawning: false, now: 1000)
        var visited = false
        var now: Int32 = 1000
        while now < 1400 && !visited {                                        // bound 400 ticks
            t.flags.gameTime = now
            let before = Set(t.world.groups.flatMap(\.members))
            var log: [EntityUpdateStep] = []
            t.updateEntities { log.append($0) }
            let made = t.world.groups.flatMap(\.members).filter { !before.contains($0) }
            if let m = made.first {
                XCTAssertTrue(log.contains(.countdown(m)), "new member \(m) not visited at \(now)")
                visited = true
            }
            now += 1
        }
        XCTAssertTrue(visited, "no member appended within the bound")

        // The spawn-in countdown (`10033a54..10033a78`): while +0xb0 − 1 > 0 the state start is re-stamped to now and
        // nothing else runs, so a timed state entered at 90 with countdown 3 counts its timer from 101 (the last
        // counting tick), not from 90. no01's "Contract and Die" timer ends in a removal: the tick it fires logs the
        // timer and no animation.
        var w = try state(at: 90)
        let n = try put(&w, "no01", x: 208, y: 240)
        w.enterState(n, named: "Contract and Die", spawning: false, now: 90)
        let delay = w.world.entities[n].timer
        XCTAssertGreaterThan(delay, 12)                                       // fires after the countdown either way
        XCTAssertEqual(w.world.entities[n].stateStart, 90)
        w.world.entities[n].spawnCountdown = 3
        var fired: Int32? = nil
        var tick: Int32 = 100
        while tick < 400 && fired == nil {                                    // bound 300 ticks
            w.flags.gameTime = tick
            var log: [EntityUpdateStep] = []
            w.updateEntities { log.append($0) }
            switch tick {
            case 100, 101:
                XCTAssertEqual(w.world.entities[n].stateStart, tick, "re-stamp at \(tick)")
                XCTAssertEqual(w.world.entities[n].spawnCountdown, 102 - tick)
                XCTAssertFalse(log.contains(.particles(n)), "counting at \(tick)")
            case 102:
                XCTAssertEqual(w.world.entities[n].spawnCountdown, 0)
                XCTAssertEqual(w.world.entities[n].stateStart, 101)          // spawned in: no re-stamp
                XCTAssertTrue(log.contains(.particles(n)))
            default: break
            }
            if log.contains(.timer(n)) && !log.contains(.animation(n)) { fired = tick }
            tick += 1
        }
        XCTAssertNotNil(fired, "no timer within the bound")
        XCTAssertEqual(fired, 101 + delay)
    }

    /// `FUN_10006b50` (`10006b50..10007060`): input clear, console test, ISp read (skipped while the console is open),
    /// P1-active, notices, debris, particles, blurs, players, score bar, game over, scroll step (+ the spawn row),
    /// level end (accuracy tally then coin bonus on later end ticks), entities, then the scroll pause/resume.
    func testUpdateWorldOrder() throws {
        var s = try level1(only: "none")
        var log: [WorldUpdateStep] = []
        s.flags.gameTime = 0
        s.updateWorld(inputs: [[], []]) { log.append($0) }
        let row = s.scroll.window.top - 64
        XCTAssertEqual(log, [
            .inputClear, .consoleTest(open: false), .inputRead, .p1Active(false), .notices, .debris, .particles,
            .blurs, .player(0), .player(1), .scoreBar, .gameOver, .levelEndEvent(.gameOverChecked),
            .scrollStep(atEnd: false), .spawnRow(row), .levelEnd(atEnd: false), .entities(paused: false),
            .scrollResume,
        ])
        // Console open on this tick: no ISp read.
        log = []
        s.flags.gameTime = 1
        s.updateWorld(inputs: [[.left], []], inputWithheld: true) { log.append($0) }
        XCTAssertEqual(Array(log.prefix(3)), [.inputClear, .consoleTest(open: true), .p1Active(false)])
        // P1 reaches state 4: the byte is set before the players run and never cleared.
        s.players[0].lifeState = 4
        log = []
        s.flags.gameTime = 2
        s.updateWorld(inputs: [[], []]) { log.append($0) }
        XCTAssertEqual(log[3], .p1Active(true))
        XCTAssertTrue(s.flags.p1Active)
        // At the map's end: the first tick hands the level end, a later one runs the accuracy tally, then the coins.
        s.scroll.speed = 0
        s.scroll.levelEnded = true
        log = []
        s.flags.gameTime = 3
        s.updateWorld(inputs: [[], []]) { log.append($0) }
        let tail = Array(log.drop { $0 != .scrollStep(atEnd: true) })
        XCTAssertEqual(tail.first, .scrollStep(atEnd: true))
        XCTAssertEqual(tail.dropFirst().first, .levelEnd(atEnd: true))
        XCTAssertTrue(tail.contains(.levelEndEvent(.accuracyTier)))
        XCTAssertEqual(tail.suffix(2), [.entities(paused: false), .scrollResume])
        s.tally.state = 0                                                     // the accuracy tally done
        log = []
        s.flags.gameTime = 4
        s.updateWorld(inputs: [[], []]) { log.append($0) }
        let events: [LevelEndEvent] = log.compactMap { if case let .levelEndEvent(e) = $0 { return e } else { return nil } }
        XCTAssertEqual(events.first, .gameOverChecked)
        XCTAssertEqual(events.dropFirst().first, .accuracyTally(done: true))
        XCTAssertEqual(events.dropFirst(2).first, .coinSetup(0))
        XCTAssertEqual(events.dropFirst(3).first, .coinTally(0, done: false))
        let iTally = try XCTUnwrap(log.firstIndex(of: .levelEndEvent(.accuracyTally(done: true))))
        let iEntities = try XCTUnwrap(log.firstIndex(of: .entities(paused: false)))
        XCTAssertLessThan(iTally, iEntities)
    }

    /// le07 with only `01m1` (yLoc 1395, timers 180 then 800 → Delete), through `updateWorld`: created at 1660 at
    /// (134, −64); its pause state from 1840; the top frozen at 1279 for 1841…2640 (800 ticks); 1278 at 2641; the
    /// level end at 3918 (3118 + 800). Bound 4,200 ticks.
    func testMidControllerPausesScroll() throws {
        var s = try level1(only: "01m1")
        let id = FourCC("01m1")!
        var created: (t: Int32, x: Float, y: Float)? = nil
        var pauseFrom: Int32? = nil
        var tops: [Int32: Int32] = [:]
        var levelEnd: Int32? = nil
        var t: Int32 = 0
        while t < 4200 && levelEnd == nil {                                   // bound 4,200
            s.flags.gameTime = t
            var unit = FourCC.none
            var paused = false
            let now = t
            s.updateWorld(inputs: [[], []]) { step in
                switch step {
                case let .spawn(.sized(u, _)): unit = u
                case let .spawn(.group(_, x, y)): if unit == id && created == nil { created = (now, x, y) }
                case let .entities(p): paused = p
                default: break
                }
            }
            if paused && pauseFrom == nil { pauseFrom = t }
            tops[t] = s.scroll.window.top
            if s.scroll.levelEnded { levelEnd = t }
            t += 1
        }
        XCTAssertNotNil(levelEnd, "no level end within 4,200 ticks")
        XCTAssertEqual(created?.t, 1660)
        XCTAssertEqual(created?.x, 134)
        XCTAssertEqual(created?.y, -64)
        XCTAssertEqual(pauseFrom, 1840)
        var frozen = 0
        for k: Int32 in 1841...2640 where tops[k] == 1279 { frozen += 1 }
        XCTAssertEqual(frozen, 800)
        XCTAssertEqual(tops[1840], 1279)
        XCTAssertEqual(tops[2641], 1278)
        XCTAssertEqual(levelEnd, 3918)
        XCTAssertEqual(s.flags.levelEndTime, 3918)
    }

    /// le07 with only `01b1`: created 2543; its spawn set puts `tapu` at absolute (480, 140) heading 285 at 2583 (one
    /// motion step later by that tick's end); its
    /// state S1 (pauses, rule #5) at 2773; the top frozen from 2774 at 346. Bound 2,900 ticks.
    func testBridgeControllerPausesAtTop346() throws {
        var s = try level1(only: "01b1")
        let id = FourCC("01b1")!, tank = FourCC("tapu")!
        let units = s.assets.definitions.units
        var created: Int32? = nil
        var tankAt: (t: Int32, x: Float, y: Float, heading: Int32)? = nil
        var s1: Int32? = nil
        var tops: [Int32: Int32] = [:]
        var t: Int32 = 0
        while t < 2900 {                                                      // bound 2,900
            s.flags.gameTime = t
            var unit = FourCC.none
            let now = t
            s.updateWorld(inputs: [[], []]) { step in
                switch step {
                case let .spawn(.sized(u, _)): unit = u
                case .spawn(.group): if unit == id && created == nil { created = now }
                default: break
                }
            }
            if tankAt == nil, let m = s.world.groups.flatMap(\.members).first(where: { units[s.world.entities[$0].unit].id == tank }) {
                let e = s.world.entities[m]                                   // first tick it exists: its creation tick
                tankAt = (t, e.object.x, e.object.y, e.heading)
            }
            if s1 == nil, let c = s.world.groups.flatMap(\.members).first(where: { units[s.world.entities[$0].unit].id == id }),
               s.world.entities[c].state == 1 {
                s1 = s.world.entities[c].stateStart
            }
            tops[t] = s.scroll.window.top
            t += 1
        }
        XCTAssertEqual(created, 2543)
        // The tank is spawned at absolute (480, 140) heading 285 (the spawn-set data below is the witness). An entity
        // appended during a pass is visited by the same pass (`100345a0` / `100345c0`), so by the end of tick 2583 —
        // the first tick it exists, read after `updateWorld` returns — it has taken one motion step.
        XCTAssertEqual(tankAt?.t, 2583)
        XCTAssertEqual(tankAt?.x.bitPattern, 1139777639)                      // 479.2531
        XCTAssertEqual(tankAt?.y.bitPattern, 1124912325)                      // 140.79988
        XCTAssertEqual(tankAt?.heading, 285)
        let ctl = try XCTUnwrap(units.first { $0.id == id })                 // the spawn set: (480, 140), 285
        let spawnTank = try XCTUnwrap(ctl.states.first { $0.stateName == "Spawn Tank, Wait" })
        let set = try XCTUnwrap(spawnTank.spawnSets.first { $0.stateSpawnSetSpawn == tank })
        XCTAssertTrue(set.stateSpawnSetAbsoluteCoordinates)
        XCTAssertEqual([set.stateSpawnSetXOffset, set.stateSpawnSetYOffset], [480, 140])
        XCTAssertTrue(set.stateSpawnSetSetHeading)
        XCTAssertEqual(set.stateSpawnSetHeadingDegrees, 285)
        XCTAssertEqual(s1, 2773)
        XCTAssertEqual(tops[2772], 347)                                       // top after tick t = 3120 − (t + 1)
        XCTAssertEqual(tops[2773], 346)                                       // S1's tick still scrolled (step before entities)
        for k: Int32 in 2774..<2900 { XCTAssertEqual(tops[k], 346, "top at \(k)") }
    }

    /// The crosshair lock (`100343ac..100344e8`, the `FUN_1003bab0(h, 1)` call at `100344c4`): the unit not
    /// `harmlessToPlayers` (+0x11a), its layer `grnd` (+0x08), `canBeHitByPlayerProjectile` (+0x11c), the state (r18)
    /// `IsTargetable` (+0x34e); per player p = 0, 1 active in the per-tick cache and not already locked (cache r1+0x3c,
    /// player +0x361 at cache time, set by a lock earlier in the pass): the cached crosshair point inside the entity's
    /// rect of `10034088` — `left ≤ x < right`, `top ≤ y < bottom` (`fcmpo`; `cror eq,gt,eq`/`bge`).
    func testCrosshairLock() throws {
        var base = try state()
        try base.setupPlayer(0)
        base.players[0].lifeState = 4
        base.players[0].object.x = 208
        base.players[0].object.y = 400
        base.players[0].handler.crosshairShown = true
        let units = base.assets.definitions.units
        let ui = try XCTUnwrap(units.indices.first {
            let u = units[$0]
            return u.layer == UnitDefinition.ground && u.canBeHitByPlayerProjectile && !u.harmlessToPlayers
                && (u.states.first?.stateIsTargetable ?? false) && u.states.first?.stateSpriteFace != FourCC.none
        })
        let i = try put(&base, units[ui].id, x: 150, y: 200)
        base.players[0].handler.crosshair.x = 10                              // far away while settling
        base.players[0].handler.crosshair.y = 10
        base.updateEntities()
        XCTAssertFalse(base.players[0].handler.crosshairLocked)
        base.flags.gameTime += 1
        var probe = base
        probe.updateEntities()
        let r = probe.entityRect(i)                                           // the rect 10034088 will compute
        XCTAssertLessThan(r.left, r.right)
        XCTAssertLessThan(r.top, r.bottom)
        let midX = Float(r.left + r.right) / 2, midY = Float(r.top + r.bottom) / 2
        func locks(_ x: Float, _ y: Float, active: Bool = true) -> Bool {
            var s = base
            s.players[0].handler.crosshair.x = x
            s.players[0].handler.crosshair.y = y
            if !active { s.players[0].lifeState = 3 }
            s.players[0].handler.crosshair.frame = 77
            s.updateEntities()
            XCTAssertEqual(s.entityRect(i), r)
            return s.players[0].handler.crosshair.frame == s.players[0].handler.ground.crosshairLockedFrame
                && s.players[0].handler.crosshairLocked
        }
        XCTAssertTrue(locks(midX, midY))
        XCTAssertTrue(locks(Float(r.left), midY))                             // left inclusive
        XCTAssertFalse(locks(Float(r.left) - 0.5, midY))
        XCTAssertFalse(locks(Float(r.right), midY))                           // right exclusive
        XCTAssertTrue(locks(Float(r.right) - 0.5, midY))
        XCTAssertTrue(locks(midX, Float(r.top)))                              // top inclusive
        XCTAssertFalse(locks(midX, Float(r.top) - 0.5))                       // above the top
        XCTAssertFalse(locks(midX, Float(r.bottom)))                          // bottom exclusive
        XCTAssertFalse(locks(midX, midY, active: false))                      // not in the cache (state ≠ 4)
        // Already locked at cache time: no call — the frame keeps its value.
        var pre = base
        pre.players[0].handler.setCrosshairLock(true)
        pre.players[0].handler.crosshair.frame = 77
        pre.players[0].handler.crosshair.x = midX
        pre.players[0].handler.crosshair.y = midY
        pre.updateEntities()
        XCTAssertEqual(pre.players[0].handler.crosshair.frame, 77)
        // Player 2 (p = 1 of the same loop): its crosshair inside the rect locks it; P1's, far away, does not.
        var two = base
        try two.setupPlayer(1)
        two.flags.numPlayers = 2
        two.players[1].lifeState = 4
        two.players[1].object.x = 208
        two.players[1].object.y = 400
        two.players[1].handler.crosshairShown = true
        two.players[1].handler.crosshair.x = midX
        two.players[1].handler.crosshair.y = midY
        two.players[1].handler.crosshair.frame = 77
        two.players[0].handler.crosshair.frame = 77
        two.updateEntities()
        XCTAssertEqual(two.entityRect(i), r)
        XCTAssertTrue(two.players[1].handler.crosshairLocked)
        XCTAssertEqual(two.players[1].handler.crosshair.frame, two.players[1].handler.ground.crosshairLockedFrame)
        XCTAssertFalse(two.players[0].handler.crosshairLocked)
        XCTAssertEqual(two.players[0].handler.crosshair.frame, 77)
        // A harmless unit (bocr) under the crosshair never locks. No shipped harmless unit can be hit by a player
        // projectile or has a targetable state, so the harmless clause cannot be isolated from those two.
        XCTAssertFalse(units.contains {
            $0.harmlessToPlayers && ($0.canBeHitByPlayerProjectile || $0.states.contains(where: \.stateIsTargetable))
        })
        var h = try state()
        try h.setupPlayer(0)
        h.players[0].lifeState = 4
        h.players[0].handler.crosshairShown = true
        let b = try put(&h, "bocr", x: 150, y: 200)
        h.updateEntities()
        let rb = h.entityRect(b)
        h.players[0].handler.crosshair.x = Float(rb.left)
        h.players[0].handler.crosshair.y = Float(rb.top)
        h.flags.gameTime += 1
        h.world.entities[b].timer = 1000                                      // keep it alive this tick
        h.updateEntities()
        XCTAssertFalse(h.players[0].handler.crosshairLocked)
    }

    /// The motion blur (`10034318..100343a8`): `R(Min, Max)` drawn first, then `now > +0xec + R` → +0xec = now and
    /// `FUN_10046840`. no01's "Contract and Die" (Min = Max = 0) leaves one blur every tick. At the pool limit the
    /// first refusal posts "Reached Motion Blur Limit" (type 1, upper, readout 0 — `10046ef4..10046f04`), later ones
    /// nothing.
    func testBlurEmittedEveryTickWithZeroInterval() throws {
        var s = try state()
        let n = try put(&s, "no01", x: 208, y: 240)
        s.enterState(n, named: "Contract and Die", spawning: false, now: 100)
        let st = try XCTUnwrap(s.currentState(n))
        XCTAssertTrue(st.stateMotionBlurRequired)
        XCTAssertEqual([st.stateMotionBlurMinTimeBetweenBlurs, st.stateMotionBlurMaxTimeBetweenBlurs], [0, 0])
        // Census: all 27 shipped blur states have Min = Max = 0, so `R(Min, Max)` never draws and the draw's place
        // before the interval test (`10034348` then `1003435c`) cannot be observed with shipped data.
        let blurStates = s.assets.definitions.units.flatMap(\.states).filter(\.stateMotionBlurRequired)
        XCTAssertEqual(blurStates.count, 27)
        XCTAssertTrue(blurStates.allSatisfy {
            $0.stateMotionBlurMinTimeBetweenBlurs == 0 && $0.stateMotionBlurMaxTimeBetweenBlurs == 0
        })
        var now: Int32 = 100
        while now < 130 {                                                     // bound 30 ticks (the state's timer)
            s.flags.gameTime = now
            let before = s.blurs.list.count
            s.updateEntities()
            XCTAssertEqual(s.blurs.list.count, before + 1, "tick \(now)")
            XCTAssertEqual(s.world.entities[n].lastBlur, now)
            now += 1
        }
        XCTAssertEqual(s.blurs.list.count, 30)
        let blur = s.blurs.slots[s.blurs.list[29]]
        XCTAssertEqual(blur.visibility, st.stateMotionBlurInitialVisibilityPercent)
        XCTAssertEqual(blur.visibilityStep, st.stateMotionBlurVisibilityDeltaPercent)
        // The draw before the interval test (`10034348` then `1003435c`), on a copied state no shipped unit has:
        // Min 5 ≠ Max 9 and +0xec = now — one draw, then the test fails, so no blur and +0xec kept.
        var d = try state()
        let k = try put(&d, "no01", x: 208, y: 240)
        d.enterState(k, named: "Contract and Die", spawning: false, now: 100)
        var wide = try XCTUnwrap(d.currentState(k))
        wide.stateMotionBlurMinTimeBetweenBlurs = 5
        wide.stateMotionBlurMaxTimeBetweenBlurs = 9
        d.world.entities[k].lastBlur = 100
        let rngBefore = d.rng
        var oneDraw = d.rng
        _ = oneDraw.range(Int32(5), Int32(9))
        XCTAssertNotEqual(oneDraw, rngBefore)
        let blursBefore = d.blurs.list.count
        d.motionBlur(k, wide, now: 100)
        XCTAssertEqual(d.rng, oneDraw)                                        // exactly one draw
        XCTAssertEqual(d.blurs.list.count, blursBefore)                       // no blur
        XCTAssertEqual(d.world.entities[k].lastBlur, 100)
        // The limit: refused with the message once, then silently.
        var full = try state()
        let m = try put(&full, "no01", x: 208, y: 240)
        full.enterState(m, named: "Contract and Die", spawning: false, now: 100)
        full.blurs.count = Int32(MotionBlurPool.capacity)
        full.updateEntities()
        XCTAssertEqual(full.messages.messages.count, 1)
        XCTAssertEqual(full.messages.messages.first?.text, Array("REACHED MOTION BLUR LIMIT".utf8))
        XCTAssertEqual(full.messages.messages.first?.kind, .error)
        XCTAssertEqual(full.messages.messages.first?.readout, 0)
        full.flags.gameTime = 101
        full.updateEntities()
        XCTAssertEqual(full.messages.messages.count, 1)
        XCTAssertEqual(full.world.entities[m].lastBlur, 101)                  // stamped even when refused
    }

    // MARK: - FUN_100345f0, FUN_100298c0, the terrain stamp

    /// `FUN_100345f0`: per group (counts once) a shadow pass — face ≠ `none`, `castsShadows` (+0x11e), +0xb0 ≤ 0 →
    /// +0x38 = 1, +0x37 = 0, `FUN_10012f20`, +0x37 = 1 — then a sprite pass — face ≠ `none`, +0xb0 ≤ 0 → +0x38 = 0,
    /// +0x37 = 1, `FUN_10012f20`, +0x38 = 1 (`10034a98..10034b5c`); a +0x36 entity takes the terrain branch.
    func testGroupShadowThenSpritePass() throws {
        var s = try state()
        let floats = s.assets.floats
        let g1 = try group(&s, ["plla", "bocr"], x: 120, y: 200)
        let g2 = try group(&s, ["plla", "plla"], x: 300, y: 260)
        s.world.entities[g2[1]].spawnCountdown = 3                            // not spawned in: skipped by both passes
        let units = s.assets.definitions.units
        XCTAssertTrue(units[s.world.entities[g1[0]].unit].castsShadows)
        XCTAssertFalse(units[s.world.entities[g1[1]].unit].castsShadows)
        XCTAssertTrue(s.world.entities[g1[1]].object.drawToTerrain)          // bocr: stateDrawToTerrain
        func entry(_ i: Int, shadow: Bool) -> [DrawCommand] {
            var o = s.world.entities[i].object
            o.drawShadow = shadow
            o.drawSprite = !shadow
            return EntityDraw.entry(&o, hOffset: 5, floats: floats)
        }
        let expectA = entry(g1[0], shadow: true) + entry(g1[0], shadow: false)
        let expectC = entry(g2[0], shadow: true) + entry(g2[0], shadow: false)
        let cmds = s.groupCommands(hOffset: 5)
        let bocrFace = s.world.entities[g1[1]].object.face
        let stamped = cmds.filter { $0.face == bocrFace }
        XCTAssertEqual(stamped.count, 1)
        XCTAssertEqual(stamped.first?.layer, 1)
        XCTAssertEqual(stamped.first.map { $0.flags & 8 }, 8)
        XCTAssertEqual(s.world.entities[g1[1]].object.lastStampTime, 100)
        XCTAssertEqual(cmds.count, expectA.count + 1 + expectC.count)
        guard cmds.count == expectA.count + 1 + expectC.count, let sA = expectA.first, let sC = expectC.first else { return }
        XCTAssertEqual(sA.flags & 2, 2)                                       // A's shadow first
        XCTAssertEqual(Array(cmds.prefix(expectA.count)), expectA)            // g1: A shadow, A sprite …
        XCTAssertEqual(cmds[expectA.count], stamped[0])                       // … then the crater's sprite
        XCTAssertEqual(Array(cmds.suffix(expectC.count)), expectC)            // g2: C shadow, C sprite; D skipped
        XCTAssertEqual(sC.flags & 2, 2)
        for i in g1 + g2 {
            XCTAssertTrue(s.world.entities[i].object.drawSprite)
            XCTAssertTrue(s.world.entities[i].object.drawShadow)
        }
    }

    /// `FUN_100298c0`: the state-4 sprite pass, then the coin-tally text (`10029930..100299a0`): +0xd8 ≠ 0 and +0xe0 <
    /// 32 (unsigned) → format 30 (`plmc`), text +0xec, BlendAmount = +0xe0, +0x10c = 15, +0x10d = 1, +0x110 = 0,
    /// Loc_Y += +0x1f8, drawn by `FUN_1000d380(rec, 0)`.
    func testPlayerCommandsAndCoinTallyText() throws {
        let a = try assets()
        let layout = try TextLayout(assets: a)
        var w = try TestWorld(assets: a, players: 1)
        w.run(to: 106)
        XCTAssertEqual(w.players[0].lifeState, 4)
        XCTAssertEqual(a.formatIDs[30], FourCC("plmc"))
        var coin = TallyState.CoinTally()
        coin.state = 3
        coin.alpha = 5
        coin.text = Array("Coins: 12".utf8)
        coin.textYOffset = 14
        let req = try XCTUnwrap(EntityDraw.coinTallyTextRequest(coin, formats: a.formats))
        XCTAssertEqual(req.text, coin.text)
        XCTAssertEqual(req.format.locY, a.formats[30].locY + 14)
        XCTAssertEqual(req.format.locX, a.formats[30].locX)
        XCTAssertEqual(req.format.blendAmount, 5)
        XCTAssertEqual(req.layer, 15)
        XCTAssertTrue(req.keepTemplateClip)
        XCTAssertFalse(req.drawNow)
        var p = w.players[0]
        let base = EntityDraw.playerCommands(&p, hOffset: 0, floats: a.floats)
        XCTAssertEqual(base.count, 3)
        let text = layout.draw(req)
        XCTAssertFalse(text.isEmpty)
        let full = EntityDraw.playerCommands(&p, hOffset: 0, floats: a.floats, coinTally: coin, text: layout)
        XCTAssertEqual(full, base + text)
        XCTAssertEqual(EntityDraw.playerOps(&p, hOffset: 0, floats: a.floats), base.map { .draw($0) })
        // nil when the state is 0 or the alpha is 32 (or more, unsigned — a negative alpha too).
        var c = coin
        c.alpha = 32
        XCTAssertNil(EntityDraw.coinTallyTextRequest(c, formats: a.formats))
        c.alpha = -1
        XCTAssertNil(EntityDraw.coinTallyTextRequest(c, formats: a.formats))
        c.alpha = 31
        XCTAssertNotNil(EntityDraw.coinTallyTextRequest(c, formats: a.formats))
        c.state = 0
        XCTAssertNil(EntityDraw.coinTallyTextRequest(c, formats: a.formats))
        XCTAssertEqual(EntityDraw.playerCommands(&p, hOffset: 0, floats: a.floats, coinTally: c, text: layout), base)
        // Not in state 4: nothing at all, the tally text included.
        p.lifeState = 3
        XCTAssertEqual(EntityDraw.playerCommands(&p, hOffset: 0, floats: a.floats, coinTally: coin, text: layout), [])
    }

    /// The terrain stamp's time test (`10013264..100132a4`): the sprite goes to the terrain buffer (layer 1, |8, the
    /// buffer's clip) only when game time > +0x90, which the stamp then sets; otherwise it is a normal command (the
    /// template's layer 7, the object's clip, no |8) at the same x + 32, y + window top. A crater stamped by the draw
    /// pass and drawn again at the same game time draws a normal sprite the second time; so does a +0x36 platform the
    /// draw pass stamped and the sweep stamps again at that game time (its shadow — no time test — still goes to
    /// the terrain); at game time 0 the sweep stamp is refused too (+0x90 starts at 0).
    func testDrawPassStampThenSweepSameTick() throws {
        let terrain = MacRect(top: 0, left: 0, bottom: 3600, right: 480)
        let gameArea = MacRect(top: 0, left: 0, bottom: 480, right: 416)
        var s = try state()
        let b = try put(&s, "bocr", x: 200.6, y: 300.4)
        XCTAssertTrue(s.world.entities[b].object.drawToTerrain)
        let first = s.groupCommands(hOffset: 0).filter { $0.face == FourCC("bocr") }
        XCTAssertEqual(first.count, 1)
        XCTAssertEqual(first.first?.layer, 1)
        XCTAssertEqual(first.first?.clip, terrain)
        XCTAssertEqual(first.first.map { $0.flags & 8 }, 8)
        XCTAssertEqual(first.first?.x, 200 + 32)
        XCTAssertEqual(first.first?.y, 300 + s.scroll.window.top)
        XCTAssertEqual(s.world.entities[b].object.lastStampTime, 100)
        let second = s.groupCommands(hOffset: 0).filter { $0.face == FourCC("bocr") }
        XCTAssertEqual(second.count, 1)
        XCTAssertEqual(second.first?.layer, 7)
        XCTAssertEqual(second.first?.clip, gameArea)
        XCTAssertEqual(second.first.map { $0.flags & 8 }, 0)
        XCTAssertEqual(second.first?.x, 200 + 32)
        XCTAssertEqual(second.first?.y, 300 + s.scroll.window.top)
        XCTAssertEqual(s.world.entities[b].object.lastStampTime, 100)

        // plla (destructDrawToTerrain, castsShadows) with +0x36 set: stamped by the draw pass, then swept at 100.
        let p = try put(&s, "plla", x: 120.2, y: 220.7)
        s.world.entities[p].object.drawToTerrain = true
        _ = s.groupCommands(hOffset: 0)
        XCTAssertEqual(s.world.entities[p].object.lastStampTime, 100)
        s.destroyEntity(p, killer: 0, now: 100)
        s.tickOps = []
        s.sweepDeleted()
        let swept: [DrawCommand] = s.tickOps.compactMap { if case let .draw(c) = $0 { return c } else { return nil } }
        let face = s.world.entities[p].object.face
        let mine = swept.filter { $0.face == face }
        XCTAssertGreaterThanOrEqual(mine.count, 2)
        XCTAssertEqual(mine.first?.layer, 0)                                  // the shadow still stamps
        XCTAssertEqual(mine.first.map { $0.flags & 8 }, 8)
        XCTAssertEqual(mine.first?.clip, terrain)
        let sprite = try XCTUnwrap(mine.dropFirst().first)
        XCTAssertEqual(sprite.layer, 7)
        XCTAssertEqual(sprite.flags & 8, 0)
        XCTAssertEqual(sprite.clip, gameArea)
        XCTAssertEqual(sprite.x, 120 + 32)
        XCTAssertEqual(sprite.y, 220 + s.scroll.window.top)

        // At game time 0 the sweep's sprite stamp is refused (+0x90 = 0 is not < 0).
        var z = try state(at: 0)
        let q = try put(&z, "plla", x: 120, y: 220)
        z.destroyEntity(q, killer: 0, now: 0)
        z.sweepDeleted()
        let zc: [DrawCommand] = z.tickOps.compactMap { if case let .draw(c) = $0 { return c } else { return nil } }
        let zs = try XCTUnwrap(zc.first { $0.flags & 2 == 0 && $0.face == z.world.entities[q].object.face })
        XCTAssertEqual(zs.layer, 7)
        XCTAssertEqual(zs.flags & 8, 0)
        XCTAssertEqual(z.world.entities[q].object.lastStampTime, 0)
    }
}
