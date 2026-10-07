import XCTest
import HectorResources
@testable import DeimosCore

/// The spawn path (spawn-and-waves.md §3, §2.2; waves-and-enemies.md §3–§4; units-movement.md §4, §6;
/// level-scroll-objects.md §2, §3, §6). Draw orders are checked against `Oracle`, an independent MSL LCG.
final class SpawnTests: XCTestCase {
    /// An independent MSL `rand` with the two RandomRange forms (engine-loop.md §9), the draw-order oracle.
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
        mutating func f(_ lo: Float, _ hi: Float) -> Float {
            if lo == hi { return lo }
            let m = lo <= hi ? lo : hi
            let span: Float = hi - lo
            let scaled: Float = span * Float(rand())
            return scaled / Float(32767) + m
        }
    }

    private func state(seed: UInt32 = 1, active: Bool = true, sector: Int32 = 1) throws -> GameState {
        let assets = try TestAssets.loaded.get()
        var s = GameState(assets: assets, prefs: DeimosPrefs.fresh, seed: seed)
        s.flags.sector = sector
        s.scroll.levelStart(rect: MacRect(top: 0, left: 0, bottom: 3600, right: 480))
        if active {
            s.players[0].lifeState = 4
            s.players[0].object.x = 208; s.players[0].object.y = 400
        }
        return s
    }

    private func unit(_ s: GameState, _ id: String) throws -> Int {
        try XCTUnwrap(s.assets.unitIndex[FourCC(id)!], id)
    }

    /// A pool entity of unit `id` in a fresh group at (gx, gy), for the per-step helpers.
    private func bare(_ s: inout GameState, _ id: String, gx: Float = 0, gy: Float = 0) throws -> (Int, Int) {
        let ui = try unit(s, id)
        let g = s.world.openGroup(unit: FourCC(id)!, size: 2, ownerGroupID: nil, editorHeading: 0,
                                  stationary: false, terrainEffects: false)
        s.world.groups[g].x = gx; s.world.groups[g].y = gy
        let i = try XCTUnwrap(s.world.allocate())
        s.world.groups[g].members.append(i)
        s.assignUnit(i, unit: ui)
        return (i, g)
    }

    func testGroupSizeAndAppearsDraws() throws {
        let a = try TestAssets.loaded.get()
        func u(_ id: String) -> UnitDefinition { a.definitions.units[a.unitIndex[FourCC(id)!]!] }
        // bu01: 5…6, appears 100 → one size draw, no appears draws.
        var rng = MSLRandom(seed: 7); var o = Oracle(seed: 7)
        XCTAssertEqual(GameState.groupSize(u("bu01"), rng: &rng), o.r(5, 6))
        XCTAssertEqual(rng.draws, 1); XCTAssertEqual(o.draws, 1)
        // smgr: 1…1, appears 50 → no size draw, one R(0, 100) (the member dropped when > 50).
        rng = MSLRandom(seed: 7); o = Oracle(seed: 7)
        XCTAssertEqual(GameState.groupSize(u("smgr"), rng: &rng), o.r(0, 100) > 50 ? 0 : 1)
        XCTAssertEqual(rng.draws, 1)
        // min clamped to 1, then min′ = min(…, max); appears 40 → one R(0, 100) per member.
        var syn = u("bu01")
        syn.numInGroupMin = -3; syn.numInGroupMax = 4; syn.appearsPercent = 40
        for seed: UInt32 in [1, 2, 3, 99, 0x469c2] {
            rng = MSLRandom(seed: seed); o = Oracle(seed: seed)
            let size = o.r(1, 4)
            var n = size
            for _ in 0..<size where o.r(0, 100) > 40 { n -= 1 }
            XCTAssertEqual(GameState.groupSize(syn, rng: &rng), n)
            XCTAssertEqual(Int(rng.draws), 1 + Int(size))
        }
        // min > max → min′ = max, no size draw; appears 0 drops every member without a draw.
        syn.numInGroupMin = 5; syn.numInGroupMax = 3; syn.appearsPercent = 0
        rng = MSLRandom(seed: 1)
        XCTAssertEqual(GameState.groupSize(syn, rng: &rng), 0)
        XCTAssertEqual(rng.draws, 0)
    }

    func testShurikenRequestFiftyOneDraws() throws {
        var s = try state(seed: 1)
        var req = SpawnRequest(unit: FourCC("shur")!, x: 208, y: -100)
        req.player = -1
        var events: [SpawnEvent] = []
        let out = try XCTUnwrap(s.spawn(req, log: { events.append($0) }))
        XCTAssertEqual(s.rng.draws, 51)
        var o = Oracle(seed: 1)
        let n = o.r(10, 11)
        XCTAssertEqual(n, 10)                                                  // rand 16838 (p08)
        XCTAssertEqual(events.first, .sized(unit: FourCC("shur")!, n: 10))
        XCTAssertEqual(events[1], .group(index: 1, x: 208, y: -100))           // a new group after PERM
        let members = s.world.groups[1].members
        XCTAssertEqual(members.count, 10)
        XCTAssertEqual(out, SpawnResult(entity: members[0], serial: 1000))
        var delay: Int32 = 0
        for (k, i) in members.enumerated() {
            let h = o.r(0, 359)
            let speed = o.f(5, 7)
            let timer = o.r(50, 60)
            let frame = o.r(0, 5)
            delay += o.r(9, 16)
            let e = s.world.entities[i]
            XCTAssertEqual(e.object.x.bitPattern, Float(208).addingProduct(Trig.sin(h), 60).bitPattern, "member \(k) x")
            XCTAssertEqual(e.object.y.bitPattern, Float(-100).addingProduct(Trig.cos(h), 20).bitPattern, "member \(k) y")
            XCTAssertEqual(e.object.vx.bitPattern, (speed * Trig.sin(0)).bitPattern)   // heading 180 → internal 0
            XCTAssertEqual(e.object.vy.bitPattern, (speed * Trig.cos(0)).bitPattern)
            XCTAssertEqual(e.timer, timer)
            XCTAssertEqual(e.object.frame, frame)
            XCTAssertEqual(e.spawnCountdown, delay)                            // running sum, first member included
            XCTAssertEqual(e.heading, 180)
            XCTAssertEqual(e.serial, 1000 + Int32(k))
            XCTAssertEqual(e.state, 0)
            XCTAssertEqual(e.stateStart, 0)
            XCTAssertEqual(e.enterCount[0], 1)
            XCTAssertTrue(e.object.air)
        }
        XCTAssertEqual(o.draws, 51)
        XCTAssertEqual(s.rng.state, o.state)
    }

    func testRefusedRequestStillDrawsSize() throws {
        var s = try state(seed: 1, active: false)
        var events: [SpawnEvent] = []
        XCTAssertNil(s.spawn(SpawnRequest(unit: FourCC("shur")!, x: 208, y: -100), log: { events.append($0) }))
        XCTAssertEqual(s.rng.draws, 1)
        XCTAssertEqual(events, [.sized(unit: FourCC("shur")!, n: 10), .refused(.playersInactive)])
        XCTAssertEqual(s.world.groups.count, 1)
        XCTAssertEqual(s.world.liveCount, 0)
        // Level ending (G+0x39) refuses too, after the same draw.
        s = try state(seed: 1)
        s.flags.levelEnding = true
        XCTAssertNil(s.spawn(SpawnRequest(unit: FourCC("shur")!, x: 208, y: -100)))
        XCTAssertEqual(s.rng.draws, 1)
        // The entity limit: refused after the size draw, the message once per level.
        s = try state(seed: 1)
        s.world.liveCount = 995
        XCTAssertNil(s.spawn(SpawnRequest(unit: FourCC("shur")!, x: 208, y: -100)))
        XCTAssertNil(s.spawn(SpawnRequest(unit: FourCC("shur")!, x: 208, y: -100)))
        XCTAssertEqual(s.rng.draws, 2)
        XCTAssertTrue(s.entityLimitWarned)
        XCTAssertEqual(s.messages.messages.map(\.text), [Array("REACHED ENTITY LIMIT".utf8)])
    }

    func testPlacementRadialAndRect() throws {
        // Radial (fused `fmadds`), over 40 seeds; the oracle also counts the cases a separate multiply-add would
        // round differently, so the bit checks are known to see the fusion.
        var unfusedDiffers = 0
        var s: GameState, i: Int, g: Int, o: Oracle
        for seed: UInt32 in 1...40 {
            // On the ellipse (shur: x ±60, y ±20): R(0, 359).
            s = try state(seed: seed); (i, g) = try bare(&s, "shur", gx: 100.3, gy: -63.7); o = Oracle(seed: seed)
            s.placeMember(i, group: g)
            var h = o.r(0, 359)
            var x = Float(100.3).addingProduct(Trig.sin(h), 60), y = Float(-63.7).addingProduct(Trig.cos(h), 20)
            XCTAssertEqual(s.world.entities[i].object.x.bitPattern, x.bitPattern)
            XCTAssertEqual(s.world.entities[i].object.y.bitPattern, y.bitPattern)
            if x != Float(100.3) + Trig.sin(h) * 60 || y != Float(-63.7) + Trig.cos(h) * 20 { unfusedDiffers += 1 }
            XCTAssertEqual(s.rng.draws, 1)
            // A randomised disc (pbpp: ±30, randomiseInitialLoc): R(0, 359) then F(0, 30) = r.
            s = try state(seed: seed); (i, g) = try bare(&s, "pbpp", gx: 17.3, gy: 250.7); o = Oracle(seed: seed)
            s.placeMember(i, group: g)
            h = o.r(0, 359)
            let r = o.f(0, 30)
            x = Float(17.3).addingProduct(Trig.sin(h), r); y = Float(250.7).addingProduct(Trig.cos(h), r)
            XCTAssertEqual(s.world.entities[i].object.x.bitPattern, x.bitPattern)
            XCTAssertEqual(s.world.entities[i].object.y.bitPattern, y.bitPattern)
            if x != Float(17.3) + Trig.sin(h) * r || y != Float(250.7) + Trig.cos(h) * r { unfusedDiffers += 1 }
            XCTAssertEqual(s.rng.draws, 2)
        }
        XCTAssertGreaterThan(unfusedDiffers, 0)
        // Rectangular, x open (bacc: −150…150, y 0): one int draw, gx + float(r); y = gy + 0.
        s = try state(seed: 3); (i, g) = try bare(&s, "bacc", gx: 200, gy: 10); o = Oracle(seed: 3)
        s.placeMember(i, group: g)
        XCTAssertEqual(s.world.entities[i].object.x, 200 + Float(o.r(-150, 150)))
        XCTAssertEqual(s.world.entities[i].object.y, 10)
        XCTAssertEqual(s.rng.draws, 1)
        // Rectangular, y open (bh02: x 0, y −50…50).
        s = try state(seed: 3); (i, g) = try bare(&s, "bh02", gx: 200, gy: 10); o = Oracle(seed: 3)
        s.placeMember(i, group: g)
        XCTAssertEqual(s.world.entities[i].object.x, 200)
        XCTAssertEqual(s.world.entities[i].object.y, 10 + Float(o.r(-50, 50)))
        XCTAssertEqual(s.rng.draws, 1)
        // Both closed (plla): no draw.
        s = try state(seed: 3); (i, g) = try bare(&s, "plla", gx: 94, gy: -64)
        s.placeMember(i, group: g)
        XCTAssertEqual([s.world.entities[i].object.x, s.world.entities[i].object.y], [94, -64])
        XCTAssertEqual(s.rng.draws, 0)
    }

    func testInitialMotionBranches() throws {
        // Stationary: zero velocity, desired, accel; no speed draw.
        var s = try state(seed: 2)
        var (i, g) = try bare(&s, "bu01")
        s.world.entities[i].stationary = true
        s.world.entities[i].object.vx = 3; s.world.entities[i].accelX = 1
        s.initialMotion(i, group: g, flag: false, heading: 0, owner: nil, multiplier: 1)
        XCTAssertEqual([s.world.entities[i].object.vx, s.world.entities[i].accelX, s.world.entities[i].desiredVX], [0, 0, 0])
        XCTAssertEqual(s.rng.draws, 0)
        // Supplied heading (flag): F(4, 6) then vector(internal(90)); +0x138 untouched here; × 2.0 multiplier.
        s = try state(seed: 2); (i, g) = try bare(&s, "bu01")
        var o = Oracle(seed: 2)
        s.initialMotion(i, group: g, flag: true, heading: 90, owner: nil, multiplier: 2)
        var sp = o.f(4, 6)
        var e = s.world.entities[i]
        XCTAssertEqual(e.object.vx.bitPattern, (sp * Trig.sin(90) * 2).bitPattern)
        XCTAssertEqual(e.object.vy.bitPattern, (sp * Trig.cos(90) * 2).bitPattern)
        XCTAssertEqual([e.spawnVX, e.desiredVX, e.accelX], [e.object.vx, e.object.vx, 0])
        XCTAssertEqual(s.rng.draws, 1)
        // Default heading 180 ± R(−3, 3) (bu01 tolerance 6): speed first, then the tolerance draw.
        s = try state(seed: 9); (i, g) = try bare(&s, "bu01"); o = Oracle(seed: 9)
        s.initialMotion(i, group: g, flag: false, heading: 0, owner: nil, multiplier: 1)
        sp = o.f(4, 6)
        let hd = 180 + o.r(-3, 3)
        e = s.world.entities[i]
        XCTAssertEqual(e.heading, hd)
        XCTAssertEqual(e.object.vx.bitPattern, (sp * Trig.sin(Trig.internalHeading(hd))).bitPattern)
        XCTAssertEqual(e.object.vy.bitPattern, (sp * Trig.cos(Trig.internalHeading(hd))).bitPattern)
        XCTAssertEqual(s.rng.draws, 2)
        // Hunter (mine, speed 1.7 fixed): toward the one active player; with none, toward (208, −100).
        s = try state(seed: 4); (i, g) = try bare(&s, "mine")
        s.world.entities[i].object.x = 100; s.world.entities[i].object.y = 100
        s.players[0].object.x = 130; s.players[0].object.y = 140
        s.initialMotion(i, group: g, flag: false, heading: 0, owner: nil, multiplier: 1)
        var u = GameState.normalised(30, 40)
        XCTAssertEqual(u.x, 0.6); XCTAssertEqual(u.y, 0.8)                     // root(fctiwz(30·30 + 1600)) = 50
        XCTAssertEqual(s.world.entities[i].object.vx.bitPattern, (u.x * Float(1.7)).bitPattern)
        XCTAssertEqual(s.world.entities[i].object.vy.bitPattern, (u.y * Float(1.7)).bitPattern)
        XCTAssertEqual(s.rng.draws, 0)
        s = try state(seed: 4, active: false); (i, g) = try bare(&s, "mine")
        s.world.entities[i].object.x = 208; s.world.entities[i].object.y = 0
        s.initialMotion(i, group: g, flag: false, heading: 0, owner: nil, multiplier: 1)
        u = GameState.normalised(0, -100)
        XCTAssertEqual(s.world.entities[i].object.vy.bitPattern, (u.y * Float(1.7)).bitPattern)
        XCTAssertEqual(s.world.entities[i].object.vy, -1.7)
        // FUN_10042bf0's x term is trunc(dx)·dx: (2.5, 0) → n = fctiwz(2·2.5) = 5, len = root(5).
        u = GameState.normalised(2.5, 0)
        XCTAssertEqual(u.x.bitPattern, (Float(2.5) / Trig.root(5)).bitPattern)
    }

    func testCyclicStartDraws() throws {
        for (y, expected) in [(Float(120), 5), (Float(120.5), 6)] {
            var s = try state(seed: 21)
            let (i, _) = try bare(&s, "cass")
            s.world.entities[i].object.y = y
            var o = Oracle(seed: 21)
            s.cyclicStart(i)
            let mag: Float = o.r(0, 1) != 0 ? 1.0 : 1.4
            let a = Float(o.r(1, 4))
            let f = Float(o.r(1, 100)) / 100
            var vx = a + f
            if o.r(0, 1) != 0 { vx = -vx }
            var vy = Float(o.r(1, 4)) + f
            if y > 120, o.r(0, 1) != 0 { vy = -vy }
            XCTAssertEqual(Int(s.rng.draws), expected, "y \(y)")
            XCTAssertEqual(o.draws, expected)
            let len = Trig.root(EntityDraw.fctiwz((vy * vy).addingProduct(vx, vx)))
            let e = s.world.entities[i]
            XCTAssertEqual(e.object.vx.bitPattern, (vx / len * mag).bitPattern)
            XCTAssertEqual(e.object.vy.bitPattern, (vy / len * mag).bitPattern)
            XCTAssertEqual(e.accelX.bitPattern, Float(0.2 * Double(vx / len)).bitPattern)
            XCTAssertEqual([e.desiredVX, e.spawnVX], [e.object.vx, e.object.vx])
        }
    }

    func testStateEntryArmsSpawnSets() throws {
        var s = try state(seed: 0x469c2)
        let out = try XCTUnwrap(s.spawn(SpawnRequest(unit: FourCC("07s1")!, x: 210, y: -64)))
        XCTAssertEqual(s.rng.draws, 0)                                         // every range closed (worked example 1)
        let i = out.entity
        XCTAssertEqual(s.world.entities[i].timer, 180)
        XCTAssertFalse(s.world.entities[i].hasSpawnSets)
        XCTAssertTrue(s.world.entities[i].hasSpawnRecords)                     // S2 and S4 have one set each
        let rngBefore = s.rng.state
        let t0: Int32 = 207
        s.enterState(i, named: "Pause, Spawn Shurikens", spawning: false, now: t0)
        var o = Oracle(seed: rngBefore)
        let rate = o.r(120, 125)
        XCTAssertEqual(s.rng.draws, 1)                                         // timer 300, face unchanged, volley/delay closed
        let e = s.world.entities[i]
        XCTAssertEqual(e.state, 2)
        XCTAssertEqual(e.stateStart, t0)
        XCTAssertEqual(e.timer, 300)
        XCTAssertTrue(e.hasSpawnSets)
        XCTAssertEqual(e.spawnRecords[2].count, 1)
        let r = e.spawnRecords[2][0]
        XCTAssertEqual(r.rate, rate)
        XCTAssertEqual([r.lastArm, r.volley, r.remaining, r.countdown], [t0, 1, 1, 0])
        XCTAssertTrue(r.active)
        XCTAssertEqual(e.enterCount[2], 1)
        XCTAssertEqual([e.soundCount, e.burstCount], [0, 0])
        // "Delete" / "Destroy" are outcomes, not states; an unknown name changes nothing.
        XCTAssertEqual(s.enterState(i, named: "Delete", spawning: false, now: t0), StateEntryOutcome(delete: true))
        XCTAssertEqual(s.enterState(i, named: "Destroy", spawning: false, now: t0), StateEntryOutcome(destroy: true))
        XCTAssertEqual(s.enterState(i, named: "No State", spawning: false, now: t0 + 1), StateEntryOutcome())
        XCTAssertEqual(s.world.entities[i].stateStart, t0)
    }

    func testShieldsBySector() throws {
        var s = try state(sector: 1)
        let p = try XCTUnwrap(s.spawn(SpawnRequest(unit: FourCC("plla")!, x: 94, y: -64)))
        XCTAssertEqual(s.world.entities[p.entity].shields.bitPattern, Float(2.6).bitPattern)   // 2.5999999 (p13)
        s = try state(sector: 3)
        let b = try XCTUnwrap(s.spawn(SpawnRequest(unit: FourCC("bsgr")!, x: 371, y: -64)))
        XCTAssertEqual(s.world.entities[b.entity].shields.bitPattern, Float(4.8000002).bitPattern)   // 4 + 0.4·2 (p13)
        XCTAssertEqual(s.world.entities[b.entity].shields.bitPattern, 0x4099_999a)
        // Capped at the maximum: bsgr max 7.0 reached by sector 9 (4 + 0.4·8 = 7.2).
        s = try state(sector: 9)
        let c = try XCTUnwrap(s.spawn(SpawnRequest(unit: FourCC("bsgr")!, x: 371, y: -64)))
        XCTAssertEqual(s.world.entities[c.entity].shields, 7)
        // A ground target counts: G+0x3c and the live ground count.
        XCTAssertEqual(s.flags.groundCreated, s.assets.definitions.units[try unit(s, "bsgr")].includeInGroundAccuracyCount ? 1 : 0)
    }

    func testFleeTargets() throws {
        var s = try state(seed: 8)
        let (i, _) = try bare(&s, "bu01")
        s.setFleePoint(i, code: FourCC("soce")!)
        XCTAssertTrue(s.world.entities[i].fleeing)
        XCTAssertEqual([s.world.entities[i].targetX, s.world.entities[i].targetY], [208, 2000])
        XCTAssertEqual(s.rng.draws, 0)
        var o = Oracle(seed: 8)
        s.setFleePoint(i, code: FourCC("nora")!)                               // F(0, 416), north
        XCTAssertEqual(s.world.entities[i].targetX.bitPattern, o.f(0, 416).bitPattern)
        XCTAssertEqual(s.world.entities[i].targetY, -1000)
        s.setFleePoint(i, code: FourCC("wera")!)                               // west, F(0, 480)
        XCTAssertEqual(s.world.entities[i].targetX, -1000)
        XCTAssertEqual(s.world.entities[i].targetY.bitPattern, o.f(0, 480).bitPattern)
        s.setFleePoint(i, code: FourCC("rave")!)                               // R(0, 1) first, then F(0, 416)
        let up = o.r(0, 1) != 0
        XCTAssertEqual(s.world.entities[i].targetX.bitPattern, o.f(0, 416).bitPattern)
        XCTAssertEqual(s.world.entities[i].targetY, up ? -1000 : 2000)
        s.world.entities[i].object.y = 300                                     // opve: y > 240 → north
        s.setFleePoint(i, code: FourCC("opve")!)
        XCTAssertEqual(s.world.entities[i].targetX.bitPattern, o.f(0, 416).bitPattern)
        XCTAssertEqual(s.world.entities[i].targetY, -1000)
        s.setFleePoint(i, code: FourCC("cega")!)
        XCTAssertEqual([s.world.entities[i].targetX, s.world.entities[i].targetY], [208, 240])
        XCTAssertEqual(Int(s.rng.draws), o.draws)
        XCTAssertEqual(o.draws, 5)
        // An unknown code (none) sets only the flag.
        s.world.entities[i].fleeing = false
        s.setFleePoint(i, code: .none)
        XCTAssertTrue(s.world.entities[i].fleeing)
        XCTAssertEqual([s.world.entities[i].targetX, s.world.entities[i].targetY], [208, 240])
    }

    func testFirstLevelObjectSpawnRow() throws {
        var s = try state(seed: 0x469c2, active: false)
        let le07 = try XCTUnwrap(s.assets.definitions.levels.first { $0.id == FourCC("le07")! })
        s.scroll.levelStart(rect: le07.background)
        s.levelStartEntities(level: le07)
        XCTAssertEqual(s.world.pendingLevelObjects.count, 38)
        let bsgr = try XCTUnwrap(s.world.pendingLevelObjects.first { $0.unit == FourCC("bsgr")! })
        XCTAssertEqual([bsgr.x, bsgr.y], [371, 2978])                          // ground: xLoc 403 − 32
        s.spawnLoadPassLevelObjects()
        XCTAssertEqual(s.world.pendingLevelObjects.count, 38)                  // nothing in 3056…3600
        var groups: [(step: Int32, unit: FourCC, x: Float, y: Float)] = []
        var created: [FourCC: Int32] = [:]
        var step: Int32 = 0
        // FUN_10010000 per tick (no entity update, so no pause): advance, then row top − 64 unless ended/paused.
        func run(until bound: Int32) {
            while step < bound {
                s.flags.gameTime = step
                let ended = s.scroll.step()
                if !ended && s.scroll.speed != 0 {
                    var unit = FourCC.none                                     // the log must not read `s`
                    let row = s.scroll.window.top - 64
                    s.spawnLevelObjects(row: row, log: { ev in
                        switch ev {
                        case let .sized(u, _): unit = u
                        case let .group(_, x, y): groups.append((step, unit, x, y))
                        case .member: if created[unit] == nil { created[unit] = step }
                        default: break
                        }
                    })
                }
                step += 1
            }
        }
        run(until: 200)
        let first = try XCTUnwrap(groups.first)
        XCTAssertEqual(first.step, 77)                                         // scroll tick 78 = game time 77
        XCTAssertEqual(first.unit, FourCC("bsgr")!)
        XCTAssertEqual([first.x, first.y], [371, -64])
        XCTAssertEqual(created[FourCC("bsgr")!], 77)
        run(until: 1700)                                                       // the first Level controller
        XCTAssertEqual(created[FourCC("01m1")!], 1660)                         // yLoc 1395: 3055 − 1395
        XCTAssertFalse(s.world.pendingLevelObjects.contains { $0.unit == FourCC("01m1")! })
    }

    func testLoadPassBand() throws {
        var s = try state(active: false)
        var total = 0, spawned = 0
        let levels = s.assets.definitions.levels
        XCTAssertEqual(levels.count, 12)
        for level in levels {
            s.scroll = ScrollState()
            s.scroll.levelStart(rect: level.background)
            s.levelStartEntities(level: level)
            let before = s.world.pendingLevelObjects.count
            total += before
            var rows: [Int32] = []
            s.spawnLoadPassLevelObjects(log: { if case .sized = $0 { rows.append(0) } })
            XCTAssertEqual(before - s.world.pendingLevelObjects.count, rows.count, "\(level.id)")
            spawned += rows.count
            if level.id == FourCC("le07")! { XCTAssertEqual(rows.count, 0) }
            XCTAssertFalse(s.world.pendingLevelObjects.contains { $0.y >= 3056 && $0.y <= 3600 })
        }
        XCTAssertEqual(total, 565)
        XCTAssertEqual(spawned, 13)
    }
}
