import XCTest
import HectorResources
@testable import DeimosCore

/// Motion, animation and owner links (units-movement.md §1–§8, spawn-and-waves.md §4; plan C9). Draw orders are
/// checked against `Oracle`, an independent MSL LCG (engine-loop.md §9).
final class MotionTests: XCTestCase {
    struct Oracle {
        var state: UInt32
        var draws = 0
        init(seed: UInt32) { state = seed }
        mutating func rand() -> Int32 {
            state = state &* 1_103_515_245 &+ 12345
            draws += 1
            return Int32((state >> 16) & 0x7fff)
        }
        mutating func r(_ a: Int32, _ b: Int32) -> Int32 { a == b ? a : a + rand() % (b - a + 1) }
    }

    /// A level-1 state; P1 active at (px, py) unless `active` is false.
    private func state(_ assets: DeimosAssets? = nil, seed: UInt32 = 1, active: Bool = true,
                       px: Float = 208, py: Float = 330) throws -> GameState {
        let a = try assets ?? TestAssets.loaded.get()
        var s = GameState(assets: a, prefs: DeimosPrefs.fresh, seed: seed)
        s.flags.sector = 1
        s.scroll.levelStart(rect: MacRect(top: 0, left: 0, bottom: 3600, right: 480))
        if active {
            s.players[0].lifeState = 4
            s.players[0].index = 0
            s.players[0].object.x = px; s.players[0].object.y = py
        }
        return s
    }

    private func unitIndex(_ a: DeimosAssets, _ id: String) throws -> Int {
        try XCTUnwrap(a.unitIndex[FourCC(id)!], id)
    }

    private func stateIndex(_ a: DeimosAssets, _ id: String, _ name: String) throws -> Int {
        let u = a.definitions.units[try unitIndex(a, id)]
        return try XCTUnwrap(u.states.firstIndex { $0.stateName == name }, "\(id) \(name)")
    }

    /// A pool entity of unit `id` with a serial, in state `name` (set directly — no entry draws), at (x, y).
    private func entity(_ s: inout GameState, _ id: String, _ name: String, x: Float = 0, y: Float = 0) throws -> Int {
        let ui = try unitIndex(s.assets, id)
        let i = try XCTUnwrap(s.world.allocate())
        s.assignUnit(i, unit: ui)
        s.world.entities[i].serial = s.world.takeSerial()
        s.world.entities[i].state = Int32(try stateIndex(s.assets, id, name))
        s.world.entities[i].object.x = x
        s.world.entities[i].object.y = y
        return i
    }

    /// Test-only: the shipped assets with one state edited. No shipped state has NumDirections 8 or 7, or a
    /// random-frame state with one frame per direction; `DeimosAssets` / `DefinitionLists` keep their fields
    /// `let`, so the edited list is written through the stored properties' offsets into local copies.
    private func patched(_ a: DeimosAssets, _ id: String, _ name: String,
                         _ edit: (inout UnitState) -> Void) throws -> DeimosAssets {
        let ui = try unitIndex(a, id), si = try stateIndex(a, id, name)
        var units = a.definitions.units
        edit(&units[ui].states[si])
        var defs = a.definitions
        let uo = try XCTUnwrap(MemoryLayout<DefinitionLists>.offset(of: \DefinitionLists.units))
        withUnsafeMutableBytes(of: &defs) {
            $0.baseAddress!.advanced(by: uo).assumingMemoryBound(to: [UnitDefinition].self).pointee = units
        }
        var out = a
        let d = try XCTUnwrap(MemoryLayout<DeimosAssets>.offset(of: \DeimosAssets.definitions))
        withUnsafeMutableBytes(of: &out) {
            $0.baseAddress!.advanced(by: d).assumingMemoryBound(to: DefinitionLists.self).pointee = defs
        }
        return out
    }

    func testIntegrateGroundRidesScroll() throws {
        var s = try state()
        let g = try entity(&s, "pllt", "Wait", x: 50, y: 100)       // ground unit
        let a = try entity(&s, "shur", "Retreat", x: 50, y: 100)    // air unit
        s.world.entities[g].object.air = false
        XCTAssertTrue(s.world.entities[a].object.air)
        for i in [g, a] { s.world.entities[i].object.vx = 0.5; s.world.entities[i].object.vy = 2 }
        s.scroll.scrolled = 1                                        // FUN_1000fed0: one row this tick
        XCTAssertTrue(s.integrateAndCull(g, margin: 128))
        XCTAssertTrue(s.integrateAndCull(a, margin: 128))
        XCTAssertEqual(s.world.entities[g].object.x, 50.5)
        XCTAssertEqual(s.world.entities[g].object.y, 103)            // y += scrolled, then y += vy
        XCTAssertEqual(s.world.entities[a].object.x, 50.5)
        XCTAssertEqual(s.world.entities[a].object.y, 102)            // air: no scroll follow
        s.scroll.scrolled = 0                                        // scroll paused
        XCTAssertTrue(s.integrateAndCull(g, margin: 128))
        XCTAssertEqual(s.world.entities[g].object.y, 105)
        XCTAssertEqual(s.rng.draws, 0)
    }

    func testCullBoundsMode1() throws {
        var s = try state()
        let i = try entity(&s, "shur", "Retreat")
        func keep(_ x: Float, _ y: Float) -> Bool {
            s.world.entities[i].object.x = x; s.world.entities[i].object.y = y
            s.world.entities[i].object.vx = 0; s.world.entities[i].object.vy = 0
            s.world.entities[i].object.halfWidth = 10; s.world.entities[i].object.halfHeight = 10
            return s.integrateAndCull(i, margin: 128)
        }
        XCTAssertTrue(keep(-138, 100))                               // x + hw = −128 ≥ −128
        XCTAssertFalse(keep(-138.5, 100))
        XCTAssertTrue(keep(554, 100))                                // x − hw = 544 ≤ 416 + 128
        XCTAssertFalse(keep(554.5, 100))
        XCTAssertTrue(keep(100, -128))                               // the centre, no half-height on the top test
        XCTAssertFalse(keep(100, -128.5))
        XCTAssertTrue(keep(100, 618))                                // y − hh = 608 ≤ 480 + 128
        XCTAssertFalse(keep(100, 618.5))
    }

    func testShurikenHoldsSixDown() throws {
        var s = try state(px: 208, py: 2400)                         // the player far beyond OnRange 140
        let i = try entity(&s, "shur", "Move South, Wait Range, RULE", x: 208, y: -100)
        s.world.entities[i].heading = 180
        s.world.entities[i].object.vx = 0; s.world.entities[i].object.vy = 6
        s.enterState(i, named: "Move South, Wait Range, RULE", spawning: true, now: 0)   // M 7, D 0 → accel 0
        XCTAssertEqual(s.world.entities[i].accelY, 0)
        XCTAssertEqual(s.world.entities[i].desiredVY, 7)
        let before = s.rng.draws
        for n in 1...40 {
            let out = s.updateMotion(i, now: Int32(n))
            XCTAssertEqual(out, StateEntryOutcome())
            XCTAssertTrue(s.integrateAndCull(i, margin: 128))
            let e = s.world.entities[i]
            XCTAssertEqual(e.object.vx, 0)
            XCTAssertEqual(e.object.vy, 6, "update \(n)")            // FUN_10017a10: vy += 0, stays 6
            XCTAssertEqual(e.object.y, -100 + 6 * Float(n))
            XCTAssertEqual(e.trackedPlayer, 0)
            XCTAssertEqual(e.state, 0)
        }
        XCTAssertEqual(s.rng.draws, before)                          // no draws in a plain move state
    }

    func testRangeTriggerOnUpdate50() throws {
        var s = try state(px: 208, py: 330)
        let i = try entity(&s, "shur", "Move South, Wait Range, RULE", x: 208, y: -100)
        s.world.entities[i].heading = 180
        s.world.entities[i].object.vx = 0; s.world.entities[i].object.vy = 6
        s.enterState(i, named: "Move South, Wait Range, RULE", spawning: true, now: 0)
        let wait = Int32(try stateIndex(s.assets, "shur", "RULE - Wait Anim Done"))
        var switched: Int? = nil
        for n in 1...60 {                                            // bound: the trigger is at update 50
            let e = s.world.entities[i]
            let d = Trig.distance(x0: e.object.x, y0: e.object.y, x1: 208, y1: 330)
            if n == 49 { XCTAssertEqual(d, 142) }
            if n == 50 { XCTAssertEqual(d, 136) }
            s.updateMotion(i, now: Int32(n))
            if s.world.entities[i].state == wait { switched = n; break }
            XCTAssertTrue(s.integrateAndCull(i, margin: 128))
        }
        XCTAssertEqual(switched, 50)
        // The same tick, the new state hunts (M 6, D 0.25): x == tx → ax = −0.25; vy 6.25 clamped to 6.
        let e = s.world.entities[i]
        XCTAssertEqual(e.object.vx, -0.25)
        XCTAssertEqual(e.object.vy, 6)
        XCTAssertEqual(e.stateStart, 50)
    }

    func testHuntTieGoesNegative() throws {
        var s = try state()
        let i = try entity(&s, "shur", "Open", x: 100, y: 100)       // Hunts, M 6, D 0.25
        s.world.entities[i].targetX = 100; s.world.entities[i].targetY = 100
        s.seekTarget(i)
        XCTAssertEqual(s.world.entities[i].accelX, -0.25)            // x == tx → negative
        XCTAssertEqual(s.world.entities[i].accelY, -0.25)
        XCTAssertEqual(s.world.entities[i].object.vx, -0.25)
        XCTAssertEqual(s.world.entities[i].object.vy, -0.25)
        s.world.entities[i].targetX = 101; s.world.entities[i].targetY = 99
        s.seekTarget(i)
        XCTAssertEqual(s.world.entities[i].object.vx, 0)             // x < tx → +D
        XCTAssertEqual(s.world.entities[i].object.vy, -0.5)
        s.world.entities[i].object.vy = -5.9
        s.seekTarget(i)
        XCTAssertEqual(s.world.entities[i].object.vy, -6)            // per-axis clamp at −M
        // Hold (FUN_10017b70) is the opposite sign: x < tx → −HoldDelta. bh02 "Attack" holds.
        let h = try entity(&s, "bh02", "Attack", x: 100, y: 100)
        let st = try XCTUnwrap(s.currentState(h))
        s.holdPosition(h, targetX: 100, targetY: 101)
        XCTAssertEqual(s.world.entities[h].accelX, st.stateHoldDelta)   // x == tx → +HD
        XCTAssertEqual(s.world.entities[h].accelY, -st.stateHoldDelta)  // y < ty → −HD
    }

    func testAnimationStopsOnLastFrame() throws {
        var s = try state()
        let i = try entity(&s, "shur", "RULE - Wait Anim Done")      // 1 direction × 6, delay 0, delta 1, no loop
        s.world.entities[i].heading = 180                            // dir = trunc(1 · 180/360) = 0
        s.world.entities[i].animates = true
        s.world.entities[i].object.frame = 0
        s.world.entities[i].lastFrameStep = -1
        var frames: [Int32] = []
        for now in Int32(0)..<5 { s.stepAnimation(i, now: now); frames.append(s.world.entities[i].object.frame) }
        XCTAssertEqual(frames, [1, 2, 3, 4, 5])
        XCTAssertFalse(s.world.entities[i].animationStopped)
        s.stepAnimation(i, now: 5)                                   // finds frame == last: stopped, frame kept
        XCTAssertTrue(s.world.entities[i].animationStopped)
        XCTAssertEqual(s.world.entities[i].object.frame, 5)
        XCTAssertEqual(s.world.entities[i].lastFrameStep, 5)
        s.stepAnimation(i, now: 6)
        XCTAssertEqual(s.world.entities[i].object.frame, 5)
        // The gate is strict: now > +0xbc + FrameDelay.
        let j = try entity(&s, "shur", "Open")                       // loops: 5 → 0
        s.world.entities[j].heading = 180; s.world.entities[j].animates = true
        s.world.entities[j].object.frame = 5; s.world.entities[j].lastFrameStep = 9
        s.stepAnimation(j, now: 9)
        XCTAssertEqual(s.world.entities[j].object.frame, 5)
        s.stepAnimation(j, now: 10)
        XCTAssertEqual(s.world.entities[j].object.frame, 0)
        XCTAssertEqual(s.rng.draws, 0)
    }

    func testRandomFrameDrawsEveryStep() throws {
        var s = try state(seed: 0x469c2)
        let i = try entity(&s, "plsh", "Expand, Play Sound")         // FPD 8, FrameDelay 0, random frames
        s.world.entities[i].heading = 0; s.world.entities[i].animates = true
        s.world.entities[i].lastFrameStep = -1
        var o = Oracle(seed: 0x469c2)
        for now in Int32(0)..<6 {
            s.stepAnimation(i, now: now)                             // 10015a0c: R(base, last) = R(0, 7)
            XCTAssertEqual(s.world.entities[i].object.frame, o.r(0, 7), "tick \(now)")
            XCTAssertEqual(s.world.entities[i].lastFrameStep, now)
        }
        XCTAssertEqual(s.rng.draws, 6)
        XCTAssertEqual(s.rng.state, o.state)
        s.world.entities[i].animationStopped = true                  // the random path ignores +0xc2
        s.stepAnimation(i, now: 6)
        XCTAssertEqual(s.rng.draws, 7)
        // A random-frame state whose base == last (one frame per direction) makes no draw.
        let a = try patched(try TestAssets.loaded.get(), "plsh", "Expand, Play Sound") { $0.stateFramesPerDirection = 1 }
        var t = try state(a, seed: 0x469c2)
        let k = try entity(&t, "plsh", "Expand, Play Sound")
        t.world.entities[k].heading = 0; t.world.entities[k].animates = true
        t.world.entities[k].lastFrameStep = -1; t.world.entities[k].object.frame = 3
        t.stepAnimation(k, now: 0)
        XCTAssertEqual(t.world.entities[k].object.frame, 0)
        XCTAssertEqual(t.rng.draws, 0)
    }

    func testCyclicMotionTwoDrawsPerTick() throws {
        var s = try state(seed: 7)
        let i = try entity(&s, "casg", "Grow and Dance Around", x: 200, y: 200)   // MaxSpeed 4 → R(2, 4)
        s.world.entities[i].object.vx = 6; s.world.entities[i].object.vy = -0.5
        s.world.entities[i].accelX = 0.1; s.world.entities[i].accelY = -0.3
        var o = Oracle(seed: 7)
        var vx: Float = 6, vy: Float = -0.5, ax: Float = 0.1, ay: Float = -0.3
        var bounced = 0
        for tick in 0..<40 {
            s.cyclicMotion(i)
            let a = o.r(2, 4)                                        // 10017024
            let b = o.r(1, 100)                                      // 10017054
            let l: Float = Float(a) + Float(b) / Float(100)
            if vx > l { vx = l; ax = -ax; bounced += 1 }
            if vx < -l { vx = -l; ax = -ax; bounced += 1 }
            if vy > l { vy = l; ay = -ay; bounced += 1 }
            if vy < -l { vy = -l; ay = -ay; bounced += 1 }
            vx = vx + ax; vy = vy + ay
            let e = s.world.entities[i]
            XCTAssertEqual(e.object.vx.bitPattern, vx.bitPattern, "tick \(tick) vx")
            XCTAssertEqual(e.object.vy.bitPattern, vy.bitPattern, "tick \(tick) vy")
            XCTAssertEqual(e.accelX, ax); XCTAssertEqual(e.accelY, ay)
            XCTAssertEqual(e.desiredVX, e.object.vx); XCTAssertEqual(e.desiredVY, e.object.vy)
            if tick == 0 { XCTAssertEqual(e.accelX, -0.1) }           // vx 6 > L ≤ 5.0 → bounce on the first tick
        }
        XCTAssertGreaterThan(bounced, 1)
        XCTAssertEqual(s.rng.draws, 80)
        XCTAssertEqual(o.draws, 80)
        // Through the controller: a cyclic state makes exactly its two draws per tick (no other site in it).
        let before = s.rng.draws
        for n in 1...5 { s.updateMotion(i, now: Int32(n)) }
        XCTAssertEqual(s.rng.draws, before + 10)
    }

    func testHeadingToFrame() throws {
        let base = try TestAssets.loaded.get()
        let a8 = try patched(base, "pllt", "Track Player & Attack") { $0.stateNumDirections = 8 }
        var s = try state(a8)
        let i = try entity(&s, "pllt", "Track Player & Attack")      // FPD 1
        XCTAssertEqual(s.frame(of: i, forHeading: 22), 0)            // 22/45 = 0.49
        XCTAssertEqual(s.frame(of: i, forHeading: 23), 1)            // 0.51 rounds up
        XCTAssertEqual(s.frame(of: i, forHeading: 350), 0)           // 7.78 → 8 > 7 → 0
        let a7 = try patched(base, "pllt", "Track Player & Attack") { $0.stateNumDirections = 7 }
        var t = try state(a7)
        let j = try entity(&t, "pllt", "Track Player & Attack")
        XCTAssertEqual(t.frame(of: j, forHeading: 25), 0)            // step = 360 / 7 = 51 (C division)
        XCTAssertEqual(t.frame(of: j, forHeading: 26), 1)            // 26/51 = 0.5098
        XCTAssertEqual(t.frame(of: j, forHeading: 76), 1)            // 1.490
        XCTAssertEqual(t.frame(of: j, forHeading: 77), 2)            // 1.5098
        // The turn (FUN_100172d0, 36 directions × 1): one direction step per call, toward the target.
        var u = try state(base, px: 300, py: 100)
        let k = try entity(&u, "pllt", "Track Player & Attack", x: 100, y: 100)
        u.world.entities[k].object.frame = 0                         // facing 0 (up)
        u.world.entities[k].trackedPlayer = 0
        u.world.entities[k].targetX = 300; u.world.entities[k].targetY = 100   // want 90 → frame 9
        u.world.entities[k].lastFrameStep = -1
        XCTAssertFalse(u.turnTowardTarget(k, now: 0))
        XCTAssertEqual(u.world.entities[k].object.frame, 1)
        XCTAssertTrue(u.world.entities[k].rotating)
        XCTAssertFalse(u.turnTowardTarget(k, now: 0))                // strict time gate: no second step
        XCTAssertEqual(u.world.entities[k].object.frame, 1)
        for now in Int32(1)...8 { u.turnTowardTarget(k, now: now) }
        XCTAssertEqual(u.world.entities[k].object.frame, 9)
        XCTAssertTrue(u.turnTowardTarget(k, now: 9))                 // on target: returns 1, no step
        XCTAssertEqual(u.world.entities[k].lastFrameStep, 8)
        u.world.entities[k].targetX = 100; u.world.entities[k].targetY = 0     // want 0: d = −90 → −1 per step
        u.turnTowardTarget(k, now: 10)
        XCTAssertEqual(u.world.entities[k].object.frame, 8)
        u.world.entities[k].object.frame = 0
        u.world.entities[k].targetX = 0; u.world.entities[k].targetY = 100      // want 270: d = 270 → −90 → wrap 35
        u.turnTowardTarget(k, now: 11)
        XCTAssertEqual(u.world.entities[k].object.frame, 35)
        u.world.entities[k].targetX = 100; u.world.entities[k].targetY = 0      // want 0 from 350: d = −350 → +10
        u.turnTowardTarget(k, now: 12)
        XCTAssertEqual(u.world.entities[k].object.frame, 0)          // 36 ≥ total → 0
        u.world.entities[k].object.frame = 35
        // The gate: +0xc4 > 0 holds the turn (and counts down); no player tracked → +0xc1 = 0, no turn.
        u.world.entities[k].rotationPause = 2
        XCTAssertFalse(u.rotationGate(k, now: 13))
        XCTAssertEqual(u.world.entities[k].rotationPause, 1)
        XCTAssertEqual(u.world.entities[k].object.frame, 35)
        u.world.entities[k].trackedPlayer = -1
        XCTAssertFalse(u.rotationGate(k, now: 14))                   // +0xc4 1 → 0, then the turn: no target
        XCTAssertFalse(u.world.entities[k].rotating)
        XCTAssertEqual(u.rng.draws, 0)
    }

    func testLockLinkOrbit() throws {
        var s = try state(px: 208, py: 400)
        let o = try entity(&s, "pllt", "Wait", x: 100, y: 100)
        let c = try entity(&s, "pbpp", "Expand, Brighten, Orbit Owner", x: 120, y: 100)
        s.world.entities[c].owner = o
        s.world.entities[c].ownerSerial = s.world.entities[o].serial
        XCTAssertNotNil(s.ownerPosition(c))
        // Lock (FUN_10037130): pos = owner + offset when the positions differ.
        s.world.entities[c].ownerOffsetX = 5; s.world.entities[c].ownerOffsetY = -3
        s.lockToOwner(c)
        XCTAssertEqual(s.world.entities[c].object.x, 105); XCTAssertEqual(s.world.entities[c].object.y, 97)
        s.world.entities[c].object.x = 100; s.world.entities[c].object.y = 100   // on the owner: unchanged
        s.lockToOwner(c)
        XCTAssertEqual(s.world.entities[c].object.x, 100); XCTAssertEqual(s.world.entities[c].object.y, 100)
        // Link (FUN_10037230): pos −= ownerLast − ownerNow; ownerLast = ownerNow.
        s.world.entities[c].object.x = 50; s.world.entities[c].object.y = 50
        s.world.entities[c].ownerLastX = 90; s.world.entities[c].ownerLastY = 95
        s.linkToOwner(c)
        XCTAssertEqual(s.world.entities[c].object.x, 60); XCTAssertEqual(s.world.entities[c].object.y, 55)
        XCTAssertEqual(s.world.entities[c].ownerLastX, 100); XCTAssertEqual(s.world.entities[c].ownerLastY, 100)
        // Orbit (FUN_10037350): angle += trunc(vx), wrap once; pos = owner + vector(angle, radius); offset = self − owner.
        s.world.entities[c].object.x = 120; s.world.entities[c].object.y = 100
        s.world.entities[c].orbitRadius = 20; s.world.entities[c].orbitAngle = 355
        s.world.entities[c].object.vx = 10.9
        s.orbitOwner(c)
        XCTAssertEqual(s.world.entities[c].orbitAngle, 5)
        let v = Trig.vector(heading: 5, speed: 20)
        let x: Float = 100 + v.x, y: Float = 100 + v.y
        XCTAssertEqual(s.world.entities[c].object.x.bitPattern, x.bitPattern)
        XCTAssertEqual(s.world.entities[c].object.y.bitPattern, y.bitPattern)
        XCTAssertEqual(s.world.entities[c].ownerOffsetX.bitPattern, (x - 100).bitPattern)
        XCTAssertEqual(s.world.entities[c].ownerOffsetY.bitPattern, (y - 100).bitPattern)
        s.world.entities[c].orbitAngle = 355; s.world.entities[c].object.vx = 5   // 360 > 359 → 0
        s.orbitOwner(c)
        XCTAssertEqual(s.world.entities[c].orbitAngle, 0)
        s.world.entities[c].orbitAngle = 3; s.world.entities[c].object.vx = -5.5  // trunc −5: −2 → 358
        s.orbitOwner(c)
        XCTAssertEqual(s.world.entities[c].orbitAngle, 358)
        s.world.entities[c].orbitAngle = 5
        s.world.entities[c].object.vx = -0.9                         // trunc → 0: pos = owner + offset
        s.world.entities[c].ownerOffsetX = 7; s.world.entities[c].ownerOffsetY = 8
        s.orbitOwner(c)
        XCTAssertEqual(s.world.entities[c].orbitAngle, 5)
        XCTAssertEqual(s.world.entities[c].object.x, 107); XCTAssertEqual(s.world.entities[c].object.y, 108)
        // The owning player is the fallback when the link is invalid (owner deleted); nothing without either.
        s.world.entities[o].deleted = true
        XCTAssertNil(s.ownerPosition(c))                             // +0xd8 = −1
        s.world.entities[c].ownerPlayer = 0
        s.world.entities[c].ownerOffsetX = 1; s.world.entities[c].ownerOffsetY = 2
        s.lockToOwner(c)
        XCTAssertEqual(s.world.entities[c].object.x, 209); XCTAssertEqual(s.world.entities[c].object.y, 402)
        s.players[0].lifeState = 2                                   // not active: no position
        s.world.entities[c].object.x = 1
        s.lockToOwner(c)
        XCTAssertEqual(s.world.entities[c].object.x, 1)
        // followOwner gates on the caller's state: pllt "Wait" locks only.
        s.world.entities[o].deleted = false
        let lockState = s.assets.definitions.units[try unitIndex(s.assets, "pllt")].states[try stateIndex(s.assets, "pllt", "Wait")]
        s.world.entities[c].ownerOffsetX = 3; s.world.entities[c].ownerOffsetY = 4
        s.world.entities[c].ownerLastX = 0; s.world.entities[c].ownerLastY = 0
        s.followOwner(c, state: lockState)
        XCTAssertEqual(s.world.entities[c].object.x, 103); XCTAssertEqual(s.world.entities[c].object.y, 104)
        XCTAssertEqual(s.world.entities[c].ownerLastX, 0)            // no link step
        // Owner copies (FUN_10036930): visibility, scale (+0x34 and the triple), hit glow, each by its flag.
        var st = UnitState()
        st.useOwnersVisibility = true; st.visuallyReflectOwnerHits = true
        s.world.entities[o].object.visibility = 42
        s.world.entities[o].object.scale = 0.5
        s.world.entities[o].object.hitGlowOn = true; s.world.entities[o].object.hitGlowLevel = 12
        s.world.entities[o].object.hitGlowFalling = true; s.world.entities[o].object.hitGlowStep = 4
        s.world.entities[o].object.hitGlowColour = 0x7c00
        s.copyFromOwner(c, state: st)
        let e = s.world.entities[c].object
        XCTAssertEqual(e.visibility, 42)
        XCTAssertEqual(e.scale, 1)                                   // useOwnersScale off
        XCTAssertTrue(e.hitGlowOn); XCTAssertEqual(e.hitGlowLevel, 12); XCTAssertTrue(e.hitGlowFalling)
        XCTAssertEqual(e.hitGlowStep, 4); XCTAssertEqual(e.hitGlowColour, 0x7c00)
        st.useOwnersScale = true
        s.copyFromOwner(c, state: st)
        XCTAssertEqual(s.world.entities[c].object.scale, 0.5)
        s.world.entities[o].deleted = true                           // invalid link: no copy
        s.world.entities[o].object.visibility = 7
        s.copyFromOwner(c, state: st)
        XCTAssertEqual(s.world.entities[c].object.visibility, 42)
        XCTAssertEqual(s.rng.draws, 0)
    }
}
