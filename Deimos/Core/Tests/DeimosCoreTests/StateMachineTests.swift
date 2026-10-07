import XCTest
import HectorResources
@testable import DeimosCore

/// The state machine (plan C10): the state timer of `FUN_10033850` (`10033c58..10033d6c`), the scroll-pause flag
/// read after it (`10033d70`, bosses.md §2.2), the 17 rule conditions `FUN_10015550` (waves-and-enemies.md §3,
/// micro-wave §3.1, spawn-and-waves §6), the spawn-set executor `FUN_10015b40` (spawn-and-waves §2.3–§2.5) and the
/// power-up release state `FUN_10034ce0` → `FUN_10014670` (micro-wave §3.3). Shipped units only (le07's live rules:
/// `01b1` #5, `gebd` #14, `pllc`/`tapc` #2 — plan p16).
final class StateMachineTests: XCTestCase {
    /// An independent MSL `rand` with RandomRange (engine-loop.md §9).
    struct Oracle {
        var state: UInt32
        init(seed: UInt32) { state = seed }
        mutating func rand() -> Int32 {
            state = state &* 1_103_515_245 &+ 12345
            return Int32((state >> 16) & 0x7fff)
        }
        mutating func r(_ a: Int32, _ b: Int32) -> Int32 { a == b ? a : a + rand() % (b - a + 1) }
    }

    private func state(seed: UInt32 = 1, active: Bool = true) throws -> GameState {
        let assets = try TestAssets.loaded.get()
        var s = GameState(assets: assets, prefs: DeimosPrefs.fresh, seed: seed)
        s.flags.sector = 1
        s.scroll.levelStart(rect: MacRect(top: 0, left: 0, bottom: 3600, right: 480))
        if active {
            s.players[0].lifeState = 4
            s.players[0].object.x = 208; s.players[0].object.y = 400
        }
        return s
    }

    /// A pool entity of unit `id` at (x, y) in a fresh group, unit assigned, with a serial, no state entered.
    @discardableResult
    private func place(_ s: inout GameState, _ id: String, x: Float = 100, y: Float = 100,
                       countdown: Int32 = 0) throws -> Int {
        let ui = try XCTUnwrap(s.assets.unitIndex[FourCC(id)!], id)
        let g = s.world.openGroup(unit: FourCC(id)!, size: 2, ownerGroupID: nil, editorHeading: 0,
                                  stationary: false, terrainEffects: false)
        let i = try XCTUnwrap(s.world.allocate())
        s.world.groups[g].members.append(i)
        s.assignUnit(i, unit: ui)
        s.world.entities[i].serial = s.world.takeSerial()
        s.world.entities[i].groupID = s.world.groups[g].id
        s.world.entities[i].object.x = x
        s.world.entities[i].object.y = y
        s.world.entities[i].spawnCountdown = countdown
        return i
    }

    private func stateIndex(_ s: GameState, _ i: Int, _ name: String) -> Int32 {
        let u = s.assets.definitions.units[s.world.entities[i].unit]
        return Int32(u.states.lastIndex { $0.stateName == name } ?? -99)
    }

    private func rule(_ unit: String, _ condition: String, range: Int32 = 0) -> UnitRule {
        var r = UnitRule()
        r.stateRuleUnit = FourCC(unit)!
        r.stateRuleCondition = condition
        r.stateRuleRange = range
        r.stateRuleAction = "Delete"
        return r
    }

    // MARK: - Timer

    func testTimerTargets() throws {
        var s = try state()
        // "Delete": 01m1 S1 timer 800 → Delete — +0xcb, killer 0xff, not destroyed (10033c90..10033c9c).
        let m = try place(&s, "01m1")
        s.enterState(m, named: "Pause 30 secs, spawn Buzzsaws", spawning: true, now: 0)
        XCTAssertEqual(s.world.entities[m].timer, 800)
        s.world.entities[m].killer = 1
        XCTAssertFalse(s.stepStateTimer(m, now: 799))
        XCTAssertFalse(s.world.entities[m].deleted)
        XCTAssertTrue(s.stepStateTimer(m, now: 800))
        XCTAssertTrue(s.world.entities[m].deleted)
        XCTAssertEqual(s.world.entities[m].killer, -1)
        XCTAssertFalse(s.world.entities[m].destroyed)
        // "Destroy": bocr S0 timer 1 → Destroy — the destroy hook with killer 0xff (10033cbc..10033cc8).
        let b = try place(&s, "bocr")
        s.enterState(b, named: s.assets.definitions.units[s.world.entities[b].unit].states[0].stateName,
                     spawning: true, now: 10)
        XCTAssertEqual(s.world.entities[b].timer, 1)
        s.world.entities[b].killer = 1
        XCTAssertTrue(s.stepStateTimer(b, now: 11))
        XCTAssertTrue(s.world.entities[b].deleted)
        XCTAssertTrue(s.world.entities[b].destroyed)
        XCTAssertEqual(s.world.entities[b].killer, -1)
        // "none" / empty / a name that is no state ("No State", gebd S0): no change, no draw.
        let gd = try place(&s, "gebd")
        s.enterState(gd, named: "RULE - Check for Flags", spawning: true, now: 20)
        let before = s.world.entities[gd]
        let draws = s.rng.draws
        XCTAssertFalse(s.applyTimerTarget(gd, "none", now: 20))
        XCTAssertFalse(s.applyTimerTarget(gd, "", now: 20))
        XCTAssertFalse(s.stepStateTimer(gd, now: 20))                         // timer 0 → "No State"
        XCTAssertEqual(s.world.entities[gd], before)
        XCTAssertEqual(s.rng.draws, draws)
        // A name: 07s1 S0 timer 180 → "Pause Scrolling, Wait", entered at now.
        let c = try place(&s, "07s1")
        s.enterState(c, named: "Wait Until Pausing", spawning: true, now: 0)
        XCTAssertFalse(s.stepStateTimer(c, now: 180))
        XCTAssertEqual(s.world.entities[c].state, stateIndex(s, c, "Pause Scrolling, Wait"))
        XCTAssertEqual(s.world.entities[c].stateStart, 180)
        XCTAssertEqual(s.world.entities[c].enterCount[1], 1)
        XCTAssertFalse(s.world.entities[c].deleted)
    }

    func testTimerFiresAtStartPlusDraw() throws {
        var s = try state(seed: 0x469c2)
        let c = try place(&s, "07s1")
        var o = Oracle(seed: 0x469c2)
        s.enterState(c, named: "Pause Scrolling, Wait", spawning: false, now: 100)
        let timer = o.r(20, 30)                                                // 100148dc: the first draw of the entry
        XCTAssertEqual(s.world.entities[c].timer, timer)
        let s1 = stateIndex(s, c, "Pause Scrolling, Wait")
        var t: Int32 = 100
        while t < 100 + timer {                                                // equality only (10033c70 cmpw; bne)
            XCTAssertFalse(s.stepStateTimer(c, now: t))
            XCTAssertEqual(s.world.entities[c].state, s1, "tick \(t)")
            t += 1
        }
        XCTAssertFalse(s.stepStateTimer(c, now: 100 + timer))
        XCTAssertEqual(s.world.entities[c].state, stateIndex(s, c, "Pause, Spawn Shurikens"))
        XCTAssertEqual(s.world.entities[c].stateStart, 100 + timer)
        XCTAssertEqual(s.world.entities[c].timer, 300)
        // S2's spawn set armed at entry (10017d64): rate R(120, 125) is the next draw.
        XCTAssertEqual(s.world.entities[c].spawnRecords[2][0].rate, o.r(120, 125))
        // Past the instant nothing fires again (a late tick is not ≥).
        XCTAssertFalse(s.stepStateTimer(c, now: 100 + timer + 301))
        XCTAssertEqual(s.world.entities[c].state, stateIndex(s, c, "Pause, Spawn Shurikens"))
    }

    // MARK: - Rules

    func testRuleTable() throws {
        // The 17 strings in table order (`0x100d6824`, 64-byte stride; jump table r2+0x380 → case k).
        XCTAssertEqual(RuleCondition.allCases.map(\.string), [
            "Is Tracking Player", "Is Not Tracking Player", "Is Active", "Is Not Active",
            "No Destroyable Air Entities Are Active", "No Destroyable Ground Entities Are Active",
            "No Destroyable Air or Ground Entities Are Active", "No Players Are Active",
            "This Entity is Within Range of a Player", "This Entity is Not Within Range of a Player",
            "This Entity's Animation Has Stopped", "This Entity's Visibility is at Required Level",
            "This Entity's Tint is at Required Level", "This Entity's Scale is at Required Level",
            "Number of This Type of Entity Active", "Are Fewer of These Entities Active",
            "Are More of These Entities Active"])
        XCTAssertEqual(RuleCondition.allCases.map(\.rawValue), Array(0...16))
        XCTAssertNil(RuleCondition(string: "Is Tracking Players"))
        var s = try state()
        let e = try place(&s, "07s1", x: 208, y: 300)
        XCTAssertNil(s.ruleCondition(e, rule("NULL", "Bogus")))                // unknown → the rule is disabled
        // #7 No Players Are Active.
        XCTAssertEqual(s.ruleCondition(e, rule("NULL", "No Players Are Active")), false)
        // #8 / #9: range 0 → both false (100156c0 li r3,0 before the dispatch); strict dist < range.
        for c in ["This Entity is Within Range of a Player", "This Entity is Not Within Range of a Player"] {
            XCTAssertEqual(s.ruleCondition(e, rule("NULL", c, range: 0)), false, c)
        }
        XCTAssertEqual(s.ruleCondition(e, rule("NULL", "This Entity is Within Range of a Player", range: 100)), false)
        XCTAssertEqual(s.ruleCondition(e, rule("NULL", "This Entity is Not Within Range of a Player", range: 100)), true)
        XCTAssertEqual(s.ruleCondition(e, rule("NULL", "This Entity is Within Range of a Player", range: 101)), true)
        // #10–#13: the entity's own fields.
        XCTAssertEqual(s.ruleCondition(e, rule("NULL", "This Entity's Animation Has Stopped")), false)
        s.world.entities[e].animationStopped = true
        XCTAssertEqual(s.ruleCondition(e, rule("NULL", "This Entity's Animation Has Stopped")), true)
        s.world.entities[e].object.visibility = 50; s.world.entities[e].object.visibilityTarget = 50
        XCTAssertEqual(s.ruleCondition(e, rule("NULL", "This Entity's Visibility is at Required Level")), true)
        s.world.entities[e].object.visibilityTarget = 51
        XCTAssertEqual(s.ruleCondition(e, rule("NULL", "This Entity's Visibility is at Required Level")), false)
        s.world.entities[e].object.glow = 3; s.world.entities[e].object.glowTarget = 4
        XCTAssertEqual(s.ruleCondition(e, rule("NULL", "This Entity's Tint is at Required Level")), false)
        s.world.entities[e].object.scale = 0.5; s.world.entities[e].object.scaleTarget = 0.5
        XCTAssertEqual(s.ruleCondition(e, rule("NULL", "This Entity's Scale is at Required Level")), true)
        // #4 / #6: any air-accuracy entity, pending or off screen, holds them false.
        XCTAssertEqual(s.ruleCondition(e, rule("NULL", "No Destroyable Air Entities Are Active")), true)
        XCTAssertEqual(s.ruleCondition(e, rule("NULL", "No Destroyable Air or Ground Entities Are Active")), true)
        try place(&s, "bu01", x: -500, y: -500, countdown: 40)
        XCTAssertEqual(s.ruleCondition(e, rule("NULL", "No Destroyable Air Entities Are Active")), false)
        XCTAssertEqual(s.ruleCondition(e, rule("NULL", "No Destroyable Air or Ground Entities Are Active")), false)
        XCTAssertEqual(s.ruleCondition(e, rule("NULL", "No Destroyable Ground Entities Are Active")), true)
        // applyRules: shur S0 "No Players Are Active" → "Keep Moving South", only when no player is in state 4.
        let sh = try place(&s, "shur")
        s.enterState(sh, named: "Move South, Wait Range, RULE", spawning: true, now: 0)
        XCTAssertFalse(s.applyRules(sh, now: 5))
        XCTAssertEqual(s.world.entities[sh].state, 0)
        s.players[0].lifeState = 3
        XCTAssertEqual(s.ruleCondition(e, rule("NULL", "No Players Are Active")), true)
        XCTAssertFalse(s.applyRules(sh, now: 6))
        XCTAssertEqual(s.world.entities[sh].state, stateIndex(s, sh, "Keep Moving South"))
        XCTAssertEqual(s.world.entities[sh].stateStart, 6)
    }

    func testCountRulesSigned() throws {
        var s = try state()
        let gd = try place(&s, "gebd")
        s.enterState(gd, named: "RULE - Check for Flags", spawning: true, now: 0)
        let a = try place(&s, "gedf")
        XCTAssertEqual(s.activeCount(ofUnit: FourCC("gedf")!), 1)
        XCTAssertEqual(s.ruleCondition(gd, rule("gedf", "Number of This Type of Entity Active", range: 2)), false)
        XCTAssertEqual(s.ruleCondition(gd, rule("gedf", "Are Fewer of These Entities Active", range: 2)), true)
        XCTAssertEqual(s.ruleCondition(gd, rule("gedf", "Are More of These Entities Active", range: 2)), false)
        XCTAssertFalse(s.applyRules(gd, now: 1))
        XCTAssertEqual(s.world.entities[gd].state, 0)
        let pending = try place(&s, "gedf", countdown: 3)                       // +0xb0 > 0 does not count
        XCTAssertEqual(s.activeCount(ofUnit: FourCC("gedf")!), 1)
        s.world.entities[pending].spawnCountdown = 0
        s.world.entities[a].deleted = true                                     // no +0xcb test: still counted
        XCTAssertEqual(s.activeCount(ofUnit: FourCC("gedf")!), 2)
        XCTAssertEqual(s.ruleCondition(gd, rule("gedf", "Number of This Type of Entity Active", range: 2)), true)
        XCTAssertEqual(s.ruleCondition(gd, rule("gedf", "Are Fewer of These Entities Active", range: 2)), false)
        XCTAssertEqual(s.ruleCondition(gd, rule("gedf", "Are More of These Entities Active", range: 2)), false)
        XCTAssertEqual(s.ruleCondition(gd, rule("gedf", "Are More of These Entities Active", range: 1)), true)
        XCTAssertEqual(s.ruleCondition(gd, rule("gedf", "Are More of These Entities Active", range: -1)), true)   // signed
        XCTAssertEqual(s.ruleCondition(gd, rule("gedf", "Are Fewer of These Entities Active", range: -1)), false)
        // #14 is equality (10015880 subf; cntlzw): count 3 vs range 2 is false, not ≥.
        let third = try place(&s, "gedf")
        XCTAssertEqual(s.activeCount(ofUnit: FourCC("gedf")!), 3)
        XCTAssertEqual(s.ruleCondition(gd, rule("gedf", "Number of This Type of Entity Active", range: 2)), false)
        XCTAssertEqual(s.ruleCondition(gd, rule("gedf", "Are More of These Entities Active", range: 2)), true)
        XCTAssertFalse(s.applyRules(gd, now: 2))
        XCTAssertEqual(s.world.entities[gd].state, 0)
        s.world.entities[third].spawnCountdown = 1                              // back to 2 counted
        XCTAssertEqual(s.activeCount(ofUnit: .none), 0)
        // le07's gebd: the #14 rule (gedf, range 2) fires → "Spawn Bonus, Delete".
        XCTAssertFalse(s.applyRules(gd, now: 2))
        XCTAssertEqual(s.world.entities[gd].state, stateIndex(s, gd, "Spawn Bonus, Delete"))
        XCTAssertEqual(s.world.entities[gd].stateStart, 2)
    }

    func testNoDestroyableGroundNeedsOnScreen() throws {
        var s = try state()
        let ctl = try place(&s, "01b1")
        s.enterState(ctl, named: "Pause Until RULE, Spawn Buzzsa, Tank", spawning: true, now: 0)
        let g = try place(&s, "plla", x: 420, y: 100)                          // includeInGroundAccuracyCount
        let r5 = rule("NULL", "No Destroyable Ground Entities Are Active")
        XCTAssertEqual(s.ruleCondition(ctl, r5), true)                          // x 420 > trunc(416): off screen
        for (x, y, held) in [(Float(400), Float(100), true), (416, 100, true), (416.5, 100, false), (0, 0, true),
                             (-0.5, 100, false), (100, 480, true), (100, 480.5, false), (100, -0.5, false)] {
            s.world.entities[g].object.x = x; s.world.entities[g].object.y = y
            XCTAssertEqual(s.ruleCondition(ctl, r5), !held, "(\(x), \(y))")
            XCTAssertEqual(s.isOnScreen(g), held, "(\(x), \(y))")
        }
        s.world.entities[g].object.x = 400; s.world.entities[g].object.y = 100
        s.world.entities[g].spawnCountdown = 30                                // no spawn-delay test in FUN_100353e0
        XCTAssertFalse(s.applyRules(ctl, now: 10))
        XCTAssertFalse(s.world.entities[ctl].deleted)
        s.world.entities[g].object.x = 420
        // le07's 01b1: rule #5 → "Delete" — flagged like the timer's Delete (10033dc4..10033dd0).
        XCTAssertTrue(s.applyRules(ctl, now: 11))
        XCTAssertTrue(s.world.entities[ctl].deleted)
        XCTAssertEqual(s.world.entities[ctl].killer, -1)
        XCTAssertFalse(s.world.entities[ctl].destroyed)
    }

    func testTrackingVersusActive() throws {
        var s = try state()
        let pc = try place(&s, "pllc", x: 100, y: 130)
        s.enterState(pc, named: "Process Rule", spawning: true, now: 0)
        let t = try place(&s, "pltf", x: 100, y: 100, countdown: 1)            // distance 30
        let track = { (r: Int32) in self.rule("pltf", "Is Tracking Player", range: r) }
        let active = { (r: Int32) in self.rule("pltf", "Is Active", range: r) }
        XCTAssertEqual(s.ruleCondition(pc, active(30)), false)                 // still pending (+0xb0 > 0)
        XCTAssertEqual(s.ruleCondition(pc, rule("pltf", "Is Not Active", range: 30)), true)
        s.world.entities[t].spawnCountdown = 0
        XCTAssertEqual(s.ruleCondition(pc, active(30)), true)                  // dist ≤ range, inclusive
        XCTAssertEqual(s.ruleCondition(pc, active(29)), false)
        XCTAssertEqual(s.ruleCondition(pc, active(0)), true)                   // range 0: any distance
        XCTAssertEqual(s.ruleCondition(pc, track(30)), false)                  // +0xc1 not set
        XCTAssertEqual(s.ruleCondition(pc, rule("pltf", "Is Not Tracking Player", range: 30)), true)
        s.world.entities[t].rotating = true
        XCTAssertEqual(s.ruleCondition(pc, track(30)), true)
        XCTAssertEqual(s.ruleCondition(pc, track(29)), false)
        XCTAssertEqual(s.ruleCondition(pc, track(0)), true)
        XCTAssertEqual(s.ruleCondition(pc, rule("none", "Is Active")), false)
        // le07's pllc: #2 (pltf, 30) → "Rule Reponse - Spawn Light".
        XCTAssertFalse(s.applyRules(pc, now: 3))
        XCTAssertEqual(s.world.entities[pc].state, stateIndex(s, pc, "Rule Reponse - Spawn Light"))
    }

    func testPauseFlagFromNewState() throws {
        var s = try state()
        // The timer switches 07s1 S0 → S1 (pauses) and the new state's flag counts the same tick (10033d60..10033d80).
        let c = try place(&s, "07s1")
        s.enterState(c, named: "Wait Until Pausing", spawning: true, now: 0)
        XCTAssertFalse(s.pausesScrolling(c))
        XCTAssertFalse(s.stepStateTimer(c, now: 179))
        XCTAssertFalse(s.pausesScrolling(c))
        XCTAssertFalse(s.stepStateTimer(c, now: 180))
        XCTAssertTrue(s.pausesScrolling(c))
        // 01b1 S1 pauses and its rule deletes it: the flag is read before the rules → one paused tick.
        let b = try place(&s, "01b1")
        s.enterState(b, named: "Pause Until RULE, Spawn Buzzsa, Tank", spawning: true, now: 0)
        var paused = false
        var removed = s.stepStateTimer(b, now: 5)
        XCTAssertFalse(removed)
        if s.pausesScrolling(b) { paused = true }
        removed = s.applyRules(b, now: 5)
        XCTAssertTrue(paused)
        XCTAssertTrue(removed)
        // A timer Delete removes the entity before the flag is read (10033ca0 b 0x10034598).
        let m = try place(&s, "01m1")
        s.enterState(m, named: "Pause 30 secs, spawn Buzzsaws", spawning: true, now: 0)
        XCTAssertTrue(s.stepStateTimer(m, now: 800))
    }

    // MARK: - Spawn sets

    func testShurikenControllerThreeGroups() throws {
        var s = try state(seed: 0x469c2)
        let c = try place(&s, "07s1", x: 210, y: 100)
        let t0: Int32 = 1000
        s.flags.gameTime = t0
        s.enterState(c, named: "Pause, Spawn Shurikens", spawning: false, now: t0)
        let s2 = Int(stateIndex(s, c, "Pause, Spawn Shurikens"))
        var rates = [s.world.entities[c].spawnRecords[s2][0].rate]            // r1 (10017d64)
        var lastArm = s.world.entities[c].spawnRecords[s2][0].lastArm
        XCTAssertEqual(lastArm, t0)
        func shurGroups(_ s: GameState) -> [Int] {
            s.world.groups.indices.filter { s.world.groups[$0].unit == FourCC("shur")! }
        }
        var requests: [Int32] = []
        var t = t0
        while t < t0 + 400 {                                                    // bound 400 ticks
            s.flags.gameTime = t
            let before = shurGroups(s).count
            XCTAssertFalse(s.stepStateTimer(c, now: t))
            s.runSpawnSets(c, now: t)
            if shurGroups(s).count > before { requests.append(t) }
            if Int(s.world.entities[c].state) == s2 {
                let rec = s.world.entities[c].spawnRecords[s2][0]
                if rec.lastArm != lastArm {                                    // re-arm: rate redrawn (10015d30)
                    XCTAssertEqual(rec.lastArm, t)
                    XCTAssertEqual(t, lastArm + rates.last!)
                    rates.append(rec.rate)
                    lastArm = rec.lastArm
                }
            }
            t += 1
        }
        XCTAssertEqual(requests.count, 3)
        guard requests.count == 3, rates.count >= 2 else { return XCTFail("rates \(rates)") }
        XCTAssertEqual(requests, [t0, t0 + rates[0] + 1, t0 + rates[0] + rates[1] + 1])
        for r in rates { XCTAssertTrue((120...125).contains(r)) }
        XCTAssertEqual(s.world.entities[c].state, stateIndex(s, c, "Pause"))  // T0 + 300
        XCTAssertFalse(s.world.entities[c].hasSpawnSets)
        for g in shurGroups(s) {                                                // absolute (208, −100), owner = c
            XCTAssertEqual(s.world.groups[g].x, 208)
            XCTAssertEqual(s.world.groups[g].y, -100)
            let m = s.world.entities[s.world.groups[g].members[0]]
            XCTAssertEqual(m.owner, c)
            XCTAssertEqual(m.ownerSerial, s.world.entities[c].serial)
            XCTAssertEqual(m.ownerPlayer, -1)
        }

        // Rotated offset + SetHeading (betu S1 set (−5, −18), heading 356): the facing plus HeadingDegrees, one
        // wrap, rotates the offset (10015f88..10015fb8) — fused fmsubs/fmadds, then fctiwz (10016070..100160f0).
        var r = try state(seed: 7)
        let tu = try place(&r, "betu", x: 200, y: 150)
        r.enterState(tu, named: r.assets.definitions.units[r.world.entities[tu].unit].states[1].stateName,
                     spawning: true, now: 0)
        let st = try XCTUnwrap(r.currentState(tu))
        let k = try XCTUnwrap(st.spawnSets.firstIndex {
            $0.stateSpawnSetXOffset == -5 && $0.stateSpawnSetHeadingDegrees == 356 })
        let bebu = r.assets.definitions.units[r.assets.unitIndex[FourCC("bebu")!]!]
        XCTAssertFalse(bebu.terrainEffect)
        XCTAssertEqual(st.stateNumDirections, 36); XCTAssertEqual(st.stateFramesPerDirection, 1)
        r.world.entities[tu].object.frame = 9                                  // facing 90
        r.world.entities[tu].object.scale = 1
        for j in r.world.entities[tu].spawnRecords[1].indices {
            var rec = r.world.entities[tu].spawnRecords[1][j]
            rec.active = j == k; rec.rate = 0; rec.remaining = 1; rec.volley = 1; rec.countdown = 0
            r.world.entities[tu].spawnRecords[1][j] = rec
        }
        r.world.entities[tu].hasSpawnSets = true
        let groupsBefore = r.world.groups.count
        XCTAssertEqual(bebu.numInGroupMin, 1); XCTAssertEqual(bebu.numInGroupMax, 1)
        XCTAssertEqual(bebu.appearsPercent, 100); XCTAssertEqual(bebu.initialHeadingTolerance, 6)
        var ob = Oracle(seed: r.rng.state)
        r.runSpawnSets(tu, now: 1)
        guard r.world.groups.count == groupsBefore + 1 else { return XCTFail("no bebu group") }
        // h = 90 + 356 − 360 = 86: offset (−5, −18) rotated by 86° → (+17, −6) (dx = trunc(−5·cos 86 + 18·sin 86),
        // dy = trunc(−18·cos 86 − 5·sin 86)); rotating by the facing alone (90°) would give (218, 145).
        let g = r.world.groups[groupsBefore]
        XCTAssertEqual(g.x, 217)
        XCTAssertEqual(g.y, 144)
        XCTAssertEqual(r.world.entities[tu].spawnRecords[1][k].remaining, 0)
        // The request heading is the same sum (10015fac stw r19 → req+0x10; 1001614c skips HeadingDegrees): the
        // member (flag set by +0x0d) gets 86 ± D1 (`10035ee4`, bebu tolerance 6 → R(−3, 3), the request's first
        // draw: group 1…1 and appears 100 make none). HeadingDegrees alone would give 356 + D1.
        let member = r.world.entities[g.members[0]]
        _ = ob.r(st.spawnSets[k].stateSpawnSetDelayBetweenEntitiesMin, st.spawnSets[k].stateSpawnSetDelayBetweenEntitiesMax)   // 10015cb8
        XCTAssertEqual(member.heading, 86 + ob.r(-3, 3))

        // An executor model on le07's geyser (geys S0 → gesm: rate 30–60, volley 1–2, delay 3–5, repeat): every
        // re-arm draws delay → volley → rate (10015d00, 10015d14, 10015d30); every in-volley tick decrements a
        // positive countdown (10015c8c) and issues at ≤ 0 with the delay redrawn first (10015cb8).
        var q = try state(seed: 0x469c2)
        let gy = try place(&q, "geys", x: 200, y: 200)
        let gu = q.assets.definitions.units[q.world.entities[gy].unit]
        q.enterState(gy, named: gu.states[0].stateName, spawning: true, now: 0)
        let gst = try XCTUnwrap(q.currentState(gy))
        let gk = try XCTUnwrap(gst.spawnSets.firstIndex { $0.stateSpawnSetSpawn == FourCC("gesm")! })
        let gs = gst.spawnSets[gk]
        XCTAssertEqual([gs.stateSpawnSetRateMin, gs.stateSpawnSetRateMax, gs.stateSpawnSetNumInVolleyMin,
                        gs.stateSpawnSetNumInVolleyMax, gs.stateSpawnSetDelayBetweenEntitiesMin,
                        gs.stateSpawnSetDelayBetweenEntitiesMax], [30, 60, 1, 2, 3, 5])
        for j in q.world.entities[gy].spawnRecords[0].indices where j != gk {
            q.world.entities[gy].spawnRecords[0][j].active = false
        }
        var rearms = 0, issued = 0, tick: Int32 = 1
        while tick < 600 && q.world.entities[gy].state == 0 {                  // bound 600 ticks
            q.flags.gameTime = tick
            let pre = q.world.entities[gy].spawnRecords[0][gk]
            var o = Oracle(seed: q.rng.state)
            q.runSpawnSets(gy, now: tick)
            let post = q.world.entities[gy].spawnRecords[0][gk]
            if pre.remaining > 0 {
                let dec = pre.countdown > 0 ? pre.countdown - 1 : pre.countdown
                if dec > 0 {
                    XCTAssertEqual(post.countdown, dec, "tick \(tick)")
                    XCTAssertEqual(post.remaining, pre.remaining, "tick \(tick)")
                } else {
                    XCTAssertEqual(post.remaining, pre.remaining - 1, "tick \(tick)")
                    XCTAssertEqual(post.countdown, o.r(3, 5), "tick \(tick)")
                    issued += 1
                }
            } else if tick >= pre.lastArm + pre.rate {
                XCTAssertEqual(post.lastArm, tick)
                XCTAssertEqual(post.countdown, o.r(3, 5), "tick \(tick)")
                XCTAssertEqual(post.volley, o.r(1, 2), "tick \(tick)")
                XCTAssertEqual(post.remaining, post.volley)
                XCTAssertEqual(post.rate, o.r(30, 60), "tick \(tick)")
                rearms += 1
            } else {
                XCTAssertEqual(post, pre, "tick \(tick)")
            }
            tick += 1
        }
        XCTAssertGreaterThanOrEqual(rearms, 5)
        XCTAssertGreaterThanOrEqual(issued, 6)
        // Fleeing without SpawnIfFleeing freezes the set (10015c14..10015c28): nothing advances.
        q.world.entities[gy].fleeing = true
        q.world.entities[gy].spawnRecords[0][gk].remaining = 1
        q.world.entities[gy].spawnRecords[0][gk].countdown = 2
        let draws = q.rng.draws
        q.runSpawnSets(gy, now: tick)
        XCTAssertEqual(q.world.entities[gy].spawnRecords[0][gk].countdown, 2)
        XCTAssertEqual(q.rng.draws, draws)

        // Gates on other shipped sets.
        var v = try state(seed: 3)
        func armOnly(_ s: inout GameState, _ i: Int, state si: Int, set k: Int, remaining: Int32, volley: Int32) {
            for j in s.world.entities[i].spawnRecords[si].indices {
                var rec = s.world.entities[i].spawnRecords[si][j]
                rec.active = j == k; rec.rate = 0; rec.remaining = remaining; rec.volley = volley; rec.countdown = 0
                rec.lastArm = 0
                s.world.entities[i].spawnRecords[si][j] = rec
            }
            s.world.entities[i].hasSpawnSets = true
        }
        func groups(_ s: GameState, _ id: String) -> Int { s.world.groups.filter { $0.unit == FourCC(id)! }.count }
        // bu01 S0 → b1gl has SpawnIfFleeing: a fleeing spawner still issues.
        let bu = try place(&v, "bu01", x: 100, y: 100)
        v.enterState(bu, named: "Spawn Glow, Approach Player", spawning: true, now: 0)
        armOnly(&v, bu, state: 0, set: 0, remaining: 1, volley: 1)
        v.world.entities[bu].fleeing = true
        let buLive = v.world.liveCount
        v.runSpawnSets(bu, now: 1)
        XCTAssertEqual(groups(v, "b1gl"), 1)
        XCTAssertGreaterThan(v.world.liveCount, buLive)
        XCTAssertEqual(v.world.entities[bu].spawnRecords[0][0].remaining, 0)
        // tapu S0 sets 2/3 → tatr (terrainEffect): only a non-stationary spawner with terrain effects requests
        // (10015d8c..10015dac); the countdown was redrawn and remaining spent either way.
        let tp = try place(&v, "tapu", x: 100, y: 100)
        v.enterState(tp, named: v.assets.definitions.units[v.world.entities[tp].unit].states[0].stateName,
                     spawning: true, now: 0)
        XCTAssertTrue(v.assets.definitions.units[v.assets.unitIndex[FourCC("tatr")!]!].terrainEffect)
        let tatrSet = 2
        XCTAssertEqual(v.currentState(tp)?.spawnSets[tatrSet].stateSpawnSetSpawn, FourCC("tatr")!)
        let liveBefore = v.world.liveCount
        for (stationary, terrain, spawns) in [(true, true, false), (false, false, false), (false, true, true)] {
            armOnly(&v, tp, state: 0, set: tatrSet, remaining: 1, volley: 1)
            v.world.entities[tp].stationary = stationary; v.world.entities[tp].terrainEffects = terrain
            let before = v.world.liveCount
            v.runSpawnSets(tp, now: 1)
            XCTAssertEqual(v.world.liveCount > before, spawns, "stationary \(stationary) terrain \(terrain)")
            XCTAssertEqual(v.world.entities[tp].spawnRecords[0][tatrSet].remaining, 0)
        }
        XCTAssertGreaterThan(v.world.liveCount, liveBefore)
        // pllt S1 → pllb (Don'tSpawnOffscreen, volley 6): off screen with the volley not started → remaining 0,
        // no draw (10015c2c..10015c6c); mid-volley it is not cancelled.
        let pt = try place(&v, "pllt", x: 450, y: 100)
        v.enterState(pt, named: v.assets.definitions.units[v.world.entities[pt].unit].states[1].stateName,
                     spawning: true, now: 0)
        XCTAssertTrue(try XCTUnwrap(v.currentState(pt)).spawnSets[0].stateSpawnSetDontSpawnOffscreen)
        armOnly(&v, pt, state: 1, set: 0, remaining: 6, volley: 6)
        var d0 = v.rng.draws
        v.runSpawnSets(pt, now: 1)
        XCTAssertEqual(v.world.entities[pt].spawnRecords[1][0].remaining, 0)
        XCTAssertEqual(v.rng.draws, d0)
        armOnly(&v, pt, state: 1, set: 0, remaining: 5, volley: 6)
        v.world.entities[pt].spawnRecords[1][0].countdown = 3
        v.runSpawnSets(pt, now: 1)
        XCTAssertEqual(v.world.entities[pt].spawnRecords[1][0].remaining, 5)
        XCTAssertEqual(v.world.entities[pt].spawnRecords[1][0].countdown, 2)
        // plla S0 (RepeatSpawns FALSE): once the volley is spent the set goes inactive (10015cc8..10015cdc).
        let pl = try place(&v, "plla", x: 100, y: 100)
        v.enterState(pl, named: "Spawn Children", spawning: true, now: 0)
        armOnly(&v, pl, state: 0, set: 0, remaining: 0, volley: 1)
        d0 = v.rng.draws
        v.runSpawnSets(pl, now: 5)
        XCTAssertFalse(v.world.entities[pl].spawnRecords[0][0].active)
        XCTAssertEqual(v.rng.draws, d0)
    }

    // MARK: - Power-up release

    func testPowerupReleaseState() throws {
        var s = try state()
        let p = try place(&s, "bgpo")
        s.enterState(p, named: "Expand, Spawn Effects", spawning: true, now: 0)
        let other = try place(&s, "07s1")
        s.enterState(other, named: "Wait Until Pausing", spawning: true, now: 0)
        let pBefore = s.world.entities[p], oBefore = s.world.entities[other]
        s.releasePowerup(serial: 99_999, now: 500)                             // no entity with that serial
        XCTAssertEqual(s.world.entities[p], pBefore)
        s.releasePowerup(serial: s.world.entities[other].serial, now: 500)     // no flagged state: nothing
        XCTAssertEqual(s.world.entities[other], oBefore)
        s.releasePowerup(serial: s.world.entities[p].serial, now: 500)         // FUN_10034ce0 → FUN_10014670
        XCTAssertEqual(s.world.entities[p].state, stateIndex(s, p, "_Powerup Release, Dwindle & Del"))
        XCTAssertEqual(s.world.entities[p].stateStart, 500)                    // now → +0xa4
        XCTAssertEqual(s.world.entities[p].timer, 50)
        XCTAssertEqual(s.world.entities[p].enterCount[2], 1)
        // Then the timer deletes it at 550.
        XCTAssertTrue(s.stepStateTimer(p, now: 550))
        XCTAssertTrue(s.world.entities[p].deleted)
    }
}
