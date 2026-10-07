import Foundation
import HectorResources

/// The 17 rule conditions, in the order of the string table `FUN_10015550` compares against (`*(r2−0x7210)` →
/// `0x100d6824`, 64-byte stride; 17 entries, `1001565c cmpwi r18,0x11`) — the index is the jump-table case
/// (`r2+0x380` → `100156dc`, `100156f4`, `10015718`, `10015730`, `10015754`, `1001576c`, `10015784`, `100157b4`,
/// `100157cc`, `100157f0`, `10015820`, `10015828`, `10015840`, `10015858`, `10015870`, `10015890`, `100158b8`;
/// strings and targets read from the data image for C10).
public enum RuleCondition: Int, CaseIterable, Sendable {
    case isTracking, isNotTracking, isActive, isNotActive
    case noAir, noGround, noAirOrGround, noPlayers
    case withinRange, notWithinRange
    case animationStopped, visibilityAtRequired, tintAtRequired, scaleAtRequired
    case countEquals, countFewer, countMore

    /// The condition string as the table holds it.
    public var string: String { Self.table[rawValue] }

    /// The table entry equal to `string` (`strcmp` over the 17), nil = "Unknown Rule Unit Condition".
    public init?(string: String) {
        guard let k = Self.table.firstIndex(of: string) else { return nil }
        self.init(rawValue: k)
    }

    static let table = [
        "Is Tracking Player", "Is Not Tracking Player", "Is Active", "Is Not Active",
        "No Destroyable Air Entities Are Active", "No Destroyable Ground Entities Are Active",
        "No Destroyable Air or Ground Entities Are Active", "No Players Are Active",
        "This Entity is Within Range of a Player", "This Entity is Not Within Range of a Player",
        "This Entity's Animation Has Stopped", "This Entity's Visibility is at Required Level",
        "This Entity's Tint is at Required Level", "This Entity's Scale is at Required Level",
        "Number of This Type of Entity Active", "Are Fewer of These Entities Active",
        "Are More of These Entities Active",
    ]
}

/// The rules evaluator `FUN_10015550(e, now, &del, &destroy) @ 10015550` and its condition callees
/// (waves-and-enemies.md §3, micro-wave-2026-10-06.md §3.1, spawn-and-waves.md §6, bosses.md §3.1; plan C10).
///
/// Listing read for C10 (`10015550..10015924`): both out-bytes = 0; the state block is fixed at entry
/// (`10015588..10015598`); for r = 0…4 (`10015904..10015910`, stride 0x88 from state+0x28):
/// - rule unit (+0x00) `none` → next (`100155a8..100155b0`);
/// - `FUN_1003d550(unit, e+0x98)` = 0 → the rule's unit is **overwritten with `none`** in the definition and
///   "FILE: Unknown Rule Unit ID" is logged (`100155cc..10015610`) — inert from then on, so the replica skips it
///   (the data is immutable here; every shipped rule unit exists — `NULL` is unit 0);
/// - an empty condition (+0x04 first byte 0) → next (`1001561c..10015624`);
/// - the condition string matched over the table (`10015638..10015664`, first match); none → logged and the
///   condition's first byte zeroed (`10015670..100156a4`) — inert from then on, skipped here;
/// - pos = the entity's (x, y) (`FUN_100128d0`, `100156ac..100156b4`); r3 = 0 before the dispatch
///   (`100156c0`), which is the result of #8/#9 when range +0x84 = 0 (`100157d0`, `100157f4` `beq` to the test);
/// - true → `FUN_100146f0(e, 0, rule+0x44, now, &del, &destroy)` and **stop** (`100158e4..10015900`): the first
///   true rule wins. No draws of its own.
/// `FUN_10033850` calls it only when the state's +0x24 (the count of rules whose unit ≠ `none`) ≥ 1
/// (`10033d94..10033d9c`), then handles the out-bytes like the timer's (`10033db8..10033df8`).
extension GameState {
    /// `10033d94..10033e08` — the rules of entity `i`'s current state, if it has any active (+0x24 > 0). Returns
    /// true when the entity was deleted or destroyed by the entered state (the caller skips the rest of its
    /// update).
    @discardableResult
    public mutating func applyRules(_ i: Int, now: Int32) -> Bool {
        guard let st = currentState(i), st.activeRuleCount > 0 else { return false }   // 10033d94..10033d9c
        for r in st.rules.prefix(UnitState.ruleSlots) {                        // 1001559c..10015910
            guard r.stateRuleUnit != .none else { continue }                   // 100155a8..100155b0
            guard ruleCondition(i, r) == true else { continue }                // 100156ac..100158e0
            let outcome = enterState(i, named: r.stateRuleAction, spawning: false, now: now)   // 100158e4..100158fc
            return removeByStateMachine(i, outcome, now: now)                  // 10033db8..10033e08
        }
        return false
    }

    /// One rule's condition for entity `i` (`100156ac..100158d8`); nil when the unit (`FUN_1003d550`) or the
    /// condition string is unknown — the original disables such a rule (see the type comment).
    func ruleCondition(_ i: Int, _ r: UnitRule) -> Bool? {
        // `none` passes: `applyRules` skips it before here (100155a8), but a direct call evaluates the callees'
        // own `none` handling (false / 0, `10034f04`, `10035094`, `10035208`).
        guard r.stateRuleUnit == .none || assets.unitIndex[r.stateRuleUnit] != nil else { return nil }
        guard let c = RuleCondition(string: r.stateRuleCondition) else { return nil }
        let unit = r.stateRuleUnit, range = r.stateRuleRange
        let x = world.entities[i].object.x, y = world.entities[i].object.y   // 100156ac..100156b4
        let o = world.entities[i].object
        switch c {
        case .isTracking: return isTracking(unit: unit, x: x, y: y, range: range)          // 100156dc..100156f0
        case .isNotTracking: return !isTracking(unit: unit, x: x, y: y, range: range)      // 100156f4..10015714
        case .isActive: return isActive(unit: unit, x: x, y: y, range: range)              // 10015718..1001572c
        case .isNotActive: return !isActive(unit: unit, x: x, y: y, range: range)          // 10015730..10015750
        case .noAir: return !anyAirAccuracyEntity()                                         // 10015754..10015768
        case .noGround: return !anyGroundAccuracyEntityOnScreen()                           // 1001576c..10015780
        case .noAirOrGround:                                                                // 10015784..100157b0
            return !anyAirAccuracyEntity() && !anyGroundAccuracyEntityOnScreen()
        case .noPlayers: return !anyPlayerActive                                            // 100157b4..100157c8
        case .withinRange:                                                                  // 100157cc..100157ec
            guard range != 0 else { return false }
            return ruleWithinRangeOfPlayer(i, range: range)
        case .notWithinRange:                                                               // 100157f0..1001581c
            guard range != 0 else { return false }
            return !ruleWithinRangeOfPlayer(i, range: range)
        case .animationStopped: return world.entities[i].animationStopped                  // 10015820 (+0xc2)
        case .visibilityAtRequired: return o.visibility == o.visibilityTarget              // 10015828..10015838
        case .tintAtRequired: return o.glow == o.glowTarget                                // 10015840..10015850
        case .scaleAtRequired: return o.scale == o.scaleTarget                             // 10015858..10015868
        case .countEquals: return activeCount(ofUnit: unit) == range                       // 10015870..10015888
        case .countFewer: return activeCount(ofUnit: unit) < range                         // 10015890..100158b0 (signed)
        case .countMore: return activeCount(ofUnit: unit) > range                          // 100158b8..100158d8 (signed)
        }
    }

    /// Every member of every active group, in list order (the walk of `FUN_10034ee0`, `FUN_10035070`,
    /// `FUN_100351f0`, `FUN_100352f0`, `FUN_100353e0`: groups `*(r2−0x6108)`, members `group+0xb0`). Members
    /// flagged deleted are still listed until the reaper unlinks them.
    private func allMembers() -> [Int] {
        world.groups.flatMap(\.members)
    }

    private func unitID(_ slot: Int) -> FourCC {
        assets.definitions.units[world.entities[slot].unit].id
    }

    /// `FUN_10034ee0(unit, pos, range) @ 10034ee0` — "Is Tracking Player": `none` → false (`10034f04..10034f10`);
    /// some member of that unit ID (`10034f98`) with +0xb0 ≤ 0 (`10034fa4`), +0xc1 set (`10034fb0`) and range 0
    /// (`10034fbc`) or `FUN_10042e90(pos, member) ≤ float(range)` (`10034fd4..10035000` `fcmpo; cror eq,lt,eq`).
    func isTracking(unit: FourCC, x: Float, y: Float, range: Int32) -> Bool {
        guard unit != .none else { return false }
        return allMembers().contains { m in
            unitID(m) == unit && world.entities[m].spawnCountdown <= 0 && world.entities[m].rotating
                && withinInclusive(m, x: x, y: y, range: range)
        }
    }

    /// `FUN_10035070(unit, pos, range) @ 10035070` — "Is Active": `FUN_10034ee0` without the +0xc1 test
    /// (`10035094..10035188`).
    func isActive(unit: FourCC, x: Float, y: Float, range: Int32) -> Bool {
        guard unit != .none else { return false }
        return allMembers().contains { m in
            unitID(m) == unit && world.entities[m].spawnCountdown <= 0 && withinInclusive(m, x: x, y: y, range: range)
        }
    }

    /// The range clause of `FUN_10034ee0` / `FUN_10035070`: range 0 → true; else dist ≤ float(range) (the
    /// `fcmpo` of the single distance against `fsubs`(magic) = float(range)).
    private func withinInclusive(_ m: Int, x: Float, y: Float, range: Int32) -> Bool {
        guard range != 0 else { return true }
        let d = Trig.distance(x0: x, y0: y, x1: world.entities[m].object.x, y1: world.entities[m].object.y)
        return d <= Float(range)
    }

    /// `FUN_100351f0(unit) @ 100351f0` — members of that unit ID with +0xb0 ≤ 0 (`1003529c..100352b8`); `none` →
    /// 0 (`10035208..10035214`). No deleted or on-screen test.
    func activeCount(ofUnit unit: FourCC) -> Int32 {
        guard unit != .none else { return 0 }
        var n: Int32 = 0
        for m in allMembers() where unitID(m) == unit && world.entities[m].spawnCountdown <= 0 { n &+= 1 }
        return n
    }

    /// `FUN_100352f0() @ 100352f0` — some member's unit has `includeInAirAccuracyCount` (+0x133, `10035390`). No
    /// spawn-delay, deleted or on-screen test.
    func anyAirAccuracyEntity() -> Bool {
        allMembers().contains { assets.definitions.units[world.entities[$0].unit].includeInAirAccuracyCount }
    }

    /// `FUN_100353e0() @ 100353e0` — some member's unit has `includeInGroundAccuracyCount` (+0x134, `10035480`)
    /// **and** it is on screen (`1003548c bl FUN_10016bd0`).
    func anyGroundAccuracyEntityOnScreen() -> Bool {
        allMembers().contains {
            assets.definitions.units[world.entities[$0].unit].includeInGroundAccuracyCount && isOnScreen($0)
        }
    }

    /// `FUN_10016bd0(e) @ 10016bd0` — `0.0 ≤ x ≤ float(trunc(PermFloat 54))` and `0.0 ≤ y ≤
    /// float(trunc(PermFloat 55))`, inclusive (`10016bf4 fcmpo; blt`, `10016c38 fcmpo; bgt`, `10016c48 fcmpo;
    /// blt`, `10016c8c fcmpo; ble`; 0.0 = `*(float*)0x100d6c8c`).
    func isOnScreen(_ i: Int) -> Bool {
        let x = world.entities[i].object.x, y = world.entities[i].object.y
        guard x >= 0 else { return false }
        guard x <= Float(EntityDraw.fctiwz(assets.floats[54])) else { return false }
        guard y >= 0 else { return false }
        return y <= Float(EntityDraw.fctiwz(assets.floats[55]))
    }

    /// `FUN_10017ef0(e, range, &tgt, &no) @ 10017ef0` for range ≠ 0 — "Within Range of a Player":
    /// `FUN_10005d40` found an active player (`10017f1c`) and its distance < float(range) (**strict**,
    /// `10017f50 fcmpo; bge`). The motion controller's range trigger (C9) calls the same function; this copy is
    /// the rules' (parallel wave — one may replace the other at C12).
    private func ruleWithinRangeOfPlayer(_ i: Int, range: Int32) -> Bool {
        guard let d = ruleNearestActivePlayerDistance(i) else { return false }
        return d < Float(range)
    }

    /// `FUN_10005d40(e, &tgt, &dist, &no) @ 10005d40` — the distance to the nearest player in life state 4
    /// (`FUN_10026c60(p, 4)`, P1 then P2): dy = py − ey, dx = px − ex (`fsubs`), d = `root(fctiwz(fmadds(dx, dx,
    /// fl32(dy·dy))))` (`10005dd8..10005e04`); the first found is kept, a later one only when strictly nearer
    /// (`10005e40 fcmpo; bge`). Nil when none is active (`10005e78`).
    private func ruleNearestActivePlayerDistance(_ i: Int) -> Float? {
        let ex = world.entities[i].object.x, ey = world.entities[i].object.y
        var best: Float? = nil
        for p in players.indices where players[p].lifeState == 4 {
            let dy: Float = players[p].object.y - ey
            let dx: Float = players[p].object.x - ex
            let d = Trig.root(EntityDraw.fctiwz((dy * dy).addingProduct(dx, dx)))
            if let b = best { if d < b { best = d } } else { best = d }
        }
        return best
    }
}
