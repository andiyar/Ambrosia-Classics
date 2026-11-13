import Foundation
import HectorResources

/// What `GameState.spawn` did, in call order — the optional step log of the spawn path (plan invariant 13:
/// logs are closure parameters, never stored).
public enum SpawnEvent: Equatable, Sendable {
    /// `FUN_100369f0` returned `n` (after its size and appears draws).
    case sized(unit: FourCC, n: Int32)
    /// The request stopped here (no group, no member).
    case refused(SpawnRefusal)
    /// The group the members join: its index in `world.groups` and its position after the y conversion.
    case group(index: Int, x: Float, y: Float)
    /// One member created by `FUN_10035cd0`.
    case member(slot: Int, serial: Int32)
}

/// Why `FUN_10033220` returned before creating a group.
public enum SpawnRefusal: Equatable, Sendable {
    /// No unit definition for the request's ID ("ERROR: Couldn't get the Unit…", `100332a4`).
    case unknownUnit
    /// `FUN_100369f0` gave n ≤ 0 (`100332c4 or.; ble`).
    case emptyGroup
    /// `canBeSpawnedOnlyWhenPlayersActive` and no player in state 4 or the level is ending (`100332cc..10033300`).
    case playersInactive
    /// `doNotSpawnIfTypeAlreadyExists` and a member of that unit is in a group list (`10033304..1003331c`).
    case typeExists
    /// pool count + n > 1000 (`10033320..10033360`; the first time per level also posts "Reached Entity Limit").
    case entityLimit
}

/// The spawn path (spawn-and-waves.md §3, waves-and-enemies.md §3–§4, level-scroll-objects.md §6.4; plan C8).
///
/// Listing reads for C8 (`disasm-review3-all.txt`), each draw site with its address, in call order:
/// - `FUN_10033220(req, out, unit) @ 10033220` (`10033220..100335fc`): `'none'` → assert; now = G+0x1c
///   (`10033264 bl FUN_10005ce0`); unit = the argument or `FUN_1003d2f0(req.unit)`, none → log and return;
///   **`n = FUN_100369f0(unit)` first** (`100332c0`), `n ≤ 0` → return; `canBeSpawnedOnlyWhenPlayersActive`
///   (unit+0x12a) → needs the byte −0x611c (`0x100e0214` = **1** in the data image; its only writer is the
///   `PLAYERACTIVESPAWNS` toggle at `0x10039080`, a debug-only console command that `FUN_1002d080` never
///   creates (messages-notices-console §5.2), so 1 all game) and `FUN_10006110` (a player in state 4) and not
///   `FUN_10005cf0` (G+0x39 level ending); `doNotSpawnIfTypeAlreadyExists` (unit+0x118) → `FUN_10036af0`;
///   cap `poolCount + n ≤ 1000` (`1003332c cmpwi 0x3e8; ble`) else the once-per-level message
///   `FUN_1002dbd0("Reached Entity Limit", type 1, upper 1, 0)` (`10033334..1003335c`); then
///   `deleteExistingEntitiesOfThisTypeOwnedByPlayer` (unit+0x119) with req+0x14 ≠ −1 → `FUN_10036be0(unit,
///   player, 0)`; the tracked-unit debug print (`1003338c`, −0x6124 = `'none'` all game — never equal to a
///   spawnable ID); group join/creation (`EntityWorld.openGroup`); group x = req x, y = req y, or
///   `trunc(req y) − window top` when req+0x0c (`10033524..10033570`, int then exact float); members
///   `FUN_10035bf0(group, unit, req, now, flag, heading, out)` with flag/heading = (1, req+0x10) when req+0x0d,
///   else (unit+0x124 `initialHeadingSetInEditor`, req+0x18) (`10033580..100335cc`); entry notice
///   `FUN_100380e0` when `entryNotice_STR` is non-empty (`100335d0..100335e8`).
/// - `FUN_100369f0 @ 100369f0`: `min′ = min(max(numInGroupMin, 1), numInGroupMax)`; **draw `10036a2c`**
///   `R(min′, max)` unless equal; then per member (n of them) unless appears ∈ {0, 100}: **draw `10036a74`**
///   `R(0, 100)`, the member is dropped when the draw > appears; appears 0 drops it with no draw.
/// - `FUN_10035bf0 @ 10035bf0`: the running group delay starts at 0 (`10035c20`); members 0 ..< group+0xa4,
///   the out-parameter passed for member 0 only.
/// - `FUN_10035cd0 @ 10035cd0` (`10035cd0..1003611c`), per member: allocate (`FUN_100385d0`), append to the
///   group, unit assignment `FUN_100144a0`; owner {req+0x20, +0x24} → +0x140/+0x144; layer +0x4c = unit
///   drawLayer; +0xa8 = −1; serial (post-increment); +0xa0 = group id; +0xcb = 0; +0xd8 = req+0x14; +0xd9 = −1;
///   +0xbc = now; +0xc0 = +0xca = 0; +0xcd = any state < numStates with `UseThisStateOnShieldDepletion`
///   (state+0x356); hittable +0xac = (initialVisibilityPercent == 100) or (< 100 and
///   `hittableWhenInvisible`) — a value > 100 gives 0 (`10035e18..10035e38`); accel +0x110/+0x114 = 0.0;
///   shields = base, and when increment > 0.0: `fadds(base, fmuls(inc, float(sector − 1)))` capped at max
///   (`10035e50..10035eb0`); heading +0x138: flag clear → `initialHeading`; else the heading argument and,
///   when `initialHeadingTolerance ≠ 0`, **draw `10035ee4` (D1)** `R(−(tol/2), tol/2)` (C division), one wrap
///   (< 0 → +360, > 359 → −360), still outside 0…359 → 0 (tolerance 0 stores the argument unchanged);
///   +0x13c/+0x13d from the request; placement `FUN_10037930` (`10035f38`); initial motion `FUN_10037b50(group,
///   e, flag, heading, req owner, req+0x28)` (`10035f54`); state 0 by name (unit+0x97c) `FUN_100146f0(e, 1, …,
///   now)` (`10035f74`); +0x19 = unit layer `'air '`; +0x1a = unit `adjustShadowLocForScaling`; owner init
///   `FUN_10033600` (`10035fb4`); group delay: **draw `10035fc8`** `R(groupDelayMin, groupDelayMax)` unless
///   equal (then the min), added to the running sum, +0xb0 = the sum (the first member draws too); state-0
///   `CyclicMotion` → `FUN_10037ed0` (`1003600c`); stationary and `destructCreateObstacle` → the bounding box
///   (`FUN_10012a00`) appended to the debris list (`FUN_1002a6d0`); state-0 `UseParentDirection` with a valid
///   owner link (and the owner has a unit) → frame = `FUN_10016230(e, FUN_100161c0(owner))`, outside 0 ..<
///   frame count → 0 (`10036044..100360d4`); `includeInGroundAccuracyCount` → G+0x3c += 1 (`FUN_100061e0`) and
///   the live ground count −0x6118 += 1; out = {entity, serial}.
extension GameState {
    /// The byte −0x611c (`0x100e0214`) `FUN_10033220` tests before the players-active rule: 1 in the data image,
    /// written only by the `PLAYERACTIVESPAWNS` toggle (`0x10039080`, `1003909c stb`), whose registration passes
    /// debugOnly = 1 so `FUN_1002d080` never creates it (messages-notices-console §5.2): 1 for the whole game.
    static let playersActiveCheckEnabled = true

    /// `FUN_100369f0(unit)` — the group size after the appears rolls (draw sites `10036a2c`, `10036a74`).
    static func groupSize(_ u: UnitDefinition, rng: inout MSLRandom) -> Int32 {
        var lo = u.numInGroupMin
        if lo < 1 { lo = 1 }                                                   // 10036a0c..10036a14
        if lo > u.numInGroupMax { lo = u.numInGroupMax }                       // 10036a18..10036a20
        let size = rng.range(lo, u.numInGroupMax)                              // 10036a24..10036a3c (no draw if equal)
        var n = size
        var k: Int32 = 0
        while k < size {                                                       // 10036a4c..10036a90
            let appears = u.appearsPercent
            if appears != 100 {                                                // 10036a5c
                if appears == 0 {                                              // 10036a64
                    n &-= 1
                } else if rng.range(Int32(0), 100) > appears {                        // 10036a6c..10036a80 (cmpw; ble keeps)
                    n &-= 1
                }
            }
            k &+= 1
        }
        return n
    }

    /// `FUN_10006110` — some player is in life state 4.
    var anyPlayerActive: Bool { players.contains { $0.lifeState == 4 } }

    /// `FUN_10036af0(unit)` — the first group member (any group, list order) whose unit has that ID; members
    /// flagged deleted still count until the reaper unlinks them.
    func firstMember(ofUnit id: FourCC) -> Int? {
        let units = assets.definitions.units
        for g in world.groups {
            for slot in g.members where units[world.entities[slot].unit].id == id { return slot }
        }
        return nil
    }

    /// `FUN_10033220(req, out, unit)` — one spawn request. Returns the first member's `{slot, serial}` (the
    /// out-parameter), or nil when nothing was created. `unit` is a `definitions.units` index when the caller
    /// already has the definition (the third argument), else the request's ID is looked up.
    @discardableResult
    public mutating func spawn(_ req: SpawnRequest, unit given: Int? = nil,
                               log: ((SpawnEvent) -> Void)? = nil) -> SpawnResult? {
        precondition(req.unit != .none, "FUN_10033220: request unit 'none'")    // 10033240..1003325c (assert)
        let now = flags.gameTime                                               // 10033264 FUN_10005ce0
        guard let ui = given ?? assets.unitIndex[req.unit] else {              // 1003326c..100332b4
            log?(.refused(.unknownUnit))
            return nil
        }
        let u = assets.definitions.units[ui]
        let n = Self.groupSize(u, rng: &rng)                                   // 100332c0
        log?(.sized(unit: u.id, n: n))
        guard n > 0 else { log?(.refused(.emptyGroup)); return nil }           // 100332c4..100332c8
        if u.canBeSpawnedOnlyWhenPlayersActive {                               // 100332cc..10033300
            guard Self.playersActiveCheckEnabled, anyPlayerActive, !flags.levelEnding else {
                log?(.refused(.playersInactive))
                return nil
            }
        }
        if u.doNotSpawnIfTypeAlreadyExists, firstMember(ofUnit: req.unit) != nil {   // 10033304..1003331c
            log?(.refused(.typeExists))
            return nil
        }
        if world.liveCount + Int(n) > EntityWorld.capacity {                   // 10033320..10033330
            if !entityLimitWarned {                                            // 10033334..1003335c
                entityLimitWarned = true
                messages.post(text: Array("Reached Entity Limit".utf8), kind: .error, uppercase: true)
            }
            log?(.refused(.entityLimit))
            return nil
        }
        if u.deleteExistingEntitiesOfThisTypeOwnedByPlayer, req.player != -1 {  // 10033364..10033388
            removeEntities(ofUnit: req.unit, ownedBy: req.player)
        }
        let ownerGroup = req.owner.map { world.entities[$0].groupID }          // 100333b0..100333c8
        let g = world.openGroup(unit: req.unit, size: n, ownerGroupID: ownerGroup,
                                editorHeading: req.editorHeading, stationary: req.stationary,
                                terrainEffects: req.terrainEffects)
        world.groups[g].x = req.x                                              // 1003351c..10033520
        if req.yIsMapRow {                                                     // 10033524..10033570
            let row = EntityDraw.fctiwz(req.y)
            world.groups[g].y = Float(row &- scroll.window.top)
        } else {
            world.groups[g].y = req.y                                          // 10033578..1003357c
        }
        log?(.group(index: g, x: world.groups[g].x, y: world.groups[g].y))
        let flag = req.headingSupplied ? true : u.initialHeadingSetInEditor    // 10033580..100335c8
        let heading = req.headingSupplied ? req.heading : req.editorHeading
        let out = createMembers(group: g, unit: ui, request: req, now: now, headingFlag: flag, heading: heading,
                                log: log)
        if !u.entryNotice.isEmpty {                                            // 100335d0..100335e8
            postEntryNotice(unit: ui, now: now)
        }
        return out
    }

    /// `FUN_10035bf0` — the group's members (`group+0xa4` of them), one `FUN_10035cd0` each.
    private mutating func createMembers(group g: Int, unit ui: Int, request req: SpawnRequest, now: Int32,
                                        headingFlag: Bool, heading: Int32,
                                        log: ((SpawnEvent) -> Void)?) -> SpawnResult? {
        var delaySum: Int32 = 0                                                // 10035c20
        var out: SpawnResult?
        var k: Int32 = 0
        while k < world.groups[g].requested {                                  // 10035cb0..10035cb8
            let r = createMember(group: g, unit: ui, request: req, now: now, delaySum: &delaySum,
                                 headingFlag: headingFlag, heading: heading)
            log?(.member(slot: r.entity, serial: r.serial))
            if k == 0 { out = r }                                              // 10035c58 (member 0 only)
            k &+= 1
        }
        return out
    }

    /// `FUN_10035cd0(group, unit, req, now, &delaySum, flag, heading, out)` — one member (see the type comment).
    private mutating func createMember(group g: Int, unit ui: Int, request req: SpawnRequest, now: Int32,
                                       delaySum: inout Int32, headingFlag: Bool, heading headingArg: Int32)
        -> SpawnResult {
        guard let i = world.allocate() else {                                  // 10035d0c..10035d28 (assert)
            preconditionFailure("FUN_10035cd0: entity pool exhausted after the cap check")
        }
        world.groups[g].members.append(i)                                      // 10035d2c..10035d34
        assignUnit(i, unit: ui)                                                // 10035d44 FUN_100144a0
        let u = assets.definitions.units[ui]
        let serial = world.takeSerial()                                        // 10035d78..10035d84
        do {
            var e = world.entities[i]
            e.owner = req.owner                                                // 10035d54..10035d60
            e.ownerSerial = req.ownerSerial                                    // 10035d64..10035d68
            e.object.layer = u.drawLayer                                       // 10035d6c..10035d70
            e.state = -1                                                       // 10035d74
            e.serial = serial
            e.groupID = world.groups[g].id                                     // 10035d88..10035d8c
            e.deleted = false                                                  // 10035d90
            e.ownerPlayer = req.player                                         // 10035d94..10035d98
            e.killer = -1                                                      // 10035d9c
            e.lastFrameStep = now                                              // 10035da0
            e.animationBackwards = false                                       // 10035da4
            e.collected = false                                                // 10035da8
            e.hasDepletionState = false                                        // 10035dac
            for s in 0..<min(Int(u.numStates), u.states.count)                 // 10035db8..10035dec
            where u.states[s].stateUseThisStateOnShieldDepletion {
                e.hasDepletionState = true
                break
            }
            let vis = Float(u.initialVisibilityPercent)                        // 10035df0..10035e14
            e.hittable = vis == 100 || (vis < 100 && u.hittableWhenInvisible)  // 10035e18..10035e38
            e.accelX = 0; e.accelY = 0                                         // 10035e3c..10035e4c
            e.shields = u.shieldsBaseAmount                                    // 10035e50..10035e54
            if u.shieldsLevelIncrement > 0 {                                   // 10035e58..10035e60
                let step: Float = u.shieldsLevelIncrement * Float(flags.sector &- 1)   // 10035e64..10035e94
                e.shields = e.shields + step                                   // 10035e98
                if e.shields > u.shieldsMaxAmount { e.shields = u.shieldsMaxAmount }   // 10035ea0..10035eb0
            }
            world.entities[i] = e
        }
        var heading = headingArg
        if !headingFlag {                                                      // 10035eb4..10035ec4
            world.entities[i].heading = u.initialHeading
        } else {
            let tol = u.initialHeadingTolerance                                // 10035ec8..10035ed0
            if tol != 0 {
                let half = tol / 2                                             // 10035ed4..10035edc (C division)
                heading = heading &+ rng.range(0 &- half, half)                // 10035ee4 (D1)
                if heading < 0 { heading &+= 360 }                             // 10035eec..10035ef8
                else if heading > 359 { heading &-= 360 }                      // 10035efc..10035f04
                if heading < 0 || heading > 359 { heading = 0 }                // 10035f08..10035f18
            }
            world.entities[i].heading = heading                                // 10035f1c
        }
        world.entities[i].stationary = req.stationary                          // 10035f20..10035f2c
        world.entities[i].terrainEffects = req.terrainEffects                  // 10035f30..10035f34
        placeMember(i, group: g)                                               // 10035f38 FUN_10037930
        initialMotion(i, group: g, flag: headingFlag, heading: heading, owner: req.owner,
                      multiplier: req.speedMultiplier)                         // 10035f54 FUN_10037b50
        enterState(i, named: u.states.first?.stateName ?? "", spawning: true, now: now)   // 10035f74 FUN_100146f0
        world.entities[i].object.air = u.layer == UnitDefinition.air          // 10035f88..10035fa0
        world.entities[i].object.adjustShadowForScaling = u.adjustShadowLocForScaling   // 10035fac..10035fb0
        initOwnerRelation(i)                                                   // 10035fb4 FUN_10033600
        let delay = rng.range(u.groupDelayMin, u.groupDelayMax)               // 10035fb8..10035fe8 (10035fc8)
        delaySum = delaySum &+ delay
        world.entities[i].spawnCountdown = delaySum                            // 10035fe0 / 10035ff8
        let state0 = currentState(i)
        if state0?.stateCyclicMotion == true { cyclicStart(i) }                // 10035ffc..1003600c FUN_10037ed0
        if world.entities[i].stationary && u.destructCreateObstacle {          // 10036010..10036040
            debris.add(boundingBox(i))
        }
        if state0?.stateUseParentDirection == true, ownerLinkValid(i),         // 10036044..1003605c
           let o = world.entities[i].owner, world.entities[o].unit >= 0 {      // 10036060..10036074
            let frame = frame(of: i, forHeading: facing(of: o))                // 1003607c..1003608c
            let count = frameCount(world.entities[i].object.face)              // 10036098..1003609c
            world.entities[i].object.frame = frame >= 0 && frame < count ? frame : 0   // 100360a4..100360c0
        }
        if u.includeInGroundAccuracyCount {                                    // 100360d8..100360f4
            flags.groundCreated &+= 1                                          // FUN_100061e0 (G+0x3c)
            world.groundCount &+= 1
        }
        return SpawnResult(entity: i, serial: serial)                          // 100360f8..10036108
    }

    /// `FUN_100144a0(e, unit)` (`100144a0..10014640`): +0x94 = unit; a `hud ` draw layer clears +0x18 (pans
    /// with the view); every state's record list freed and recreated with one zeroed 0x18 record per spawn set
    /// (states past `numStates` have no list); +0x13e = 1 when any record was made.
    mutating func assignUnit(_ i: Int, unit ui: Int) {
        let u = assets.definitions.units[ui]
        world.entities[i].unit = ui                                            // 100144b8
        if u.drawLayer == EntityDraw.hud { world.entities[i].object.pansWithView = false }   // 100144cc..100144e4
        var lists = Array(repeating: [SpawnRecord](), count: Entity.stateSlots)    // 100144f8..1001451c
        for s in 0..<min(u.states.count, Entity.stateSlots) {                  // 10014538..1001462c
            let n = u.states[s].spawnSets.count
            if n > 0 {
                lists[s] = Array(repeating: SpawnRecord(), count: n)           // 100145b0..10014604
                world.entities[i].hasSpawnRecords = true                       // 1001460c
            }
        }
        world.entities[i].spawnRecords = lists
    }

    /// `FUN_10037930(group, e) @ 10037930` — member placement relative to the group position (waves-and-enemies
    /// §4, HIGH; `10037930..10037b4c`). Radial when both offset ranges are open: **draw `10037988`** `R(0, 359)`
    /// (an internal heading, `FUN_10042b30` = (S[h], C[h])); `randomiseInitialLoc` → **draw `100379b8`**
    /// `F(0.0, |xMax|)` = r and (x, y) = (fmadds(S, r, gx), fmadds(C, r, gy)); else on the ellipse
    /// (fmadds(S, |xMax|, gx), fmadds(C, |yMax|, gy)). Rectangular otherwise: x = gx + xMin (`fadds`) when the
    /// x range is closed, else **draw `10037a54`** `R(trunc lo, trunc hi)` (lo/hi = min/max of the pair) and
    /// gx + float(r); then y the same way (**draw `10037ad4`**).
    mutating func placeMember(_ i: Int, group g: Int) {
        let u = assets.definitions.units[world.entities[i].unit]
        let gx = world.groups[g].x, gy = world.groups[g].y
        let xMin = u.xOffsetMin, xMax = u.xOffsetMax, yMin = u.yOffsetMin, yMax = u.yOffsetMax
        var x: Float, y: Float
        if xMin != xMax && yMin != yMax {                                      // 1003796c..1003797c
            let h = rng.range(Int32(0), 359)                                          // 10037980..10037988
            let (cx, cy) = Trig.unitVector(heading: h)                         // 10037994 FUN_10042b30
            if u.randomiseInitialLoc {                                         // 1003799c
                let r = rng.range(Float(0), Swift.abs(xMax))                   // 100379a8..100379b8
                x = gx.addingProduct(cx, r)                                    // 100379cc fmadds
                y = gy.addingProduct(cy, r)                                    // 100379d8 fmadds
            } else {
                x = gx.addingProduct(cx, Swift.abs(xMax))                      // 10037a00 fmadds
                y = gy.addingProduct(cy, Swift.abs(yMax))                      // 10037a0c fmadds
            }
        } else {
            if xMin == xMax {                                                  // 10037a18..10037a1c
                x = gx + xMin                                                  // 10037a8c..10037a94
            } else {
                let (lo, hi) = xMin > xMax ? (xMax, xMin) : (xMin, xMax)       // 10037a20..10037a38
                let r = rng.range(EntityDraw.fctiwz(lo), EntityDraw.fctiwz(hi))   // 10037a3c..10037a54
                x = gx + Float(r)                                              // 10037a5c..10037a80
            }
            if yMin == yMax {                                                  // 10037a98..10037a9c
                y = gy + yMin                                                  // 10037b0c..10037b14
            } else {
                let (lo, hi) = yMin > yMax ? (yMax, yMin) : (yMin, yMax)       // 10037aa0..10037ab8
                let r = rng.range(EntityDraw.fctiwz(lo), EntityDraw.fctiwz(hi))   // 10037abc..10037ad4
                y = gy + Float(r)                                              // 10037adc..10037b00
            }
        }
        world.entities[i].object.x = x                                         // 10037b20 FUN_10012910
        world.entities[i].object.y = y
    }

    /// `FUN_10005ed0(ref, out) @ 10005ed0` — the active player nearest `ref` (loose-ends-combat §7.2): out =
    /// (0, 0) (`0x100d62fc`); one active → its position; two → the smaller `root(fctiwz(fmadds(dx, dx, dy·dy)))`
    /// from ref, ties to P1. Nil when none is active.
    func closestActivePlayer(toX rx: Float, y ry: Float) -> (x: Float, y: Float)? {
        let active = players.indices.filter { players[$0].lifeState == 4 }    // 10005f18..10005f58
        guard let first = active.first else { return nil }
        if active.count == 1 { return (players[first].object.x, players[first].object.y) }   // 10005f64..10005f7c
        var best = -1
        var bestD: Float = 0
        for p in players.indices where players[p].lifeState == 4 {            // 10005fa0..1000604c
            let px = players[p].object.x, py = players[p].object.y
            let dy = py - ry, dx = px - rx                                     // 10005fe0..10005fe8
            let d = Trig.root(EntityDraw.fctiwz((dy * dy).addingProduct(dx, dx)))   // 10005fec..10006000
            if best == -1 { best = p; bestD = d }                              // 1000600c..10006020
            else if d < bestD { best = p; bestD = d }                          // 10006024..10006034
        }
        return (players[best].object.x, players[best].object.y)
    }

    /// `FUN_10042bf0(dx, dy, out) @ 10042bf0` — the unit vector as read: `n = fctiwz(fmadds(float(trunc dx),
    /// dx, fl32(dy·dy)))` (the x term multiplies the **truncated** dx by dx), `len = FUN_10042f20(n)`, out =
    /// (dx / len, dy / len) (`fdivs`).
    static func normalised(_ dx: Float, _ dy: Float) -> (x: Float, y: Float) {
        let sq: Float = dy * dy                                                // 10042c0c fmuls
        let tx = Float(EntityDraw.fctiwz(dx))                                  // 10042c1c..10042c40
        let len = Trig.root(EntityDraw.fctiwz(sq.addingProduct(tx, dx)))       // 10042c44..10042c54
        return (dx / len, dy / len)                                            // 10042c5c..10042c60
    }

    /// `FUN_10037b50(group, e, flag, heading, owner, mult) @ 10037b50` — initial motion (spawn-and-waves §3.3,
    /// `10037b50..10037ec0`). Stationary → velocity, desired and accel (0, 0), no draws. Else **draw `10037bc4`**
    /// speed = `F(initialSpeedMin, initialSpeedMax)`, then: (1) flag or `initialHeadingSetInEditor` → velocity =
    /// `vector(internal(heading), speed)`; (2) `initiallyHuntsClosestPlayer` → target = the active player nearest
    /// (W·0.5, 0.0), or (W·0.5, −100.0) with none; velocity = normalised(target − pos)·speed (`fmuls`); (3)
    /// `doBurst`/`doImplode` → d = pos − group (burst) / group − pos (implode), u = normalised(d), velocity =
    /// (u.x·speed, −(u.y·speed)), +0x138 = compass of `headingOf(u)` — the unit vector itself, not the
    /// y-negated velocity (`10037d14 addi r3,r1,0x40`: the `FUN_10042bf0` result); (4) default → h = the owner's facing
    /// when `useOwnerHeading` and the request has an owner, else `initialHeading` ± **draw `10037db8`**
    /// `R(−(tol/2), tol/2)` (only for the initialHeading source, tol ≠ 0; one wrap, then outside 0…359 → 0);
    /// +0x138 = h, velocity = `vector(internal(h), speed)`. Then mult ≠ 1.0 → velocity ·= mult (`fmuls`);
    /// +0x100/+0x104 = +0x108/+0x10c = velocity, accel = (0.0, 0.0).
    mutating func initialMotion(_ i: Int, group g: Int, flag: Bool, heading: Int32, owner: Int?,
                                multiplier mult: Float, unit override: UnitDefinition? = nil) {
        // `override` stands in for the entity's definition (+0x94) — a test seam for branches no shipped unit takes.
        let u = override ?? assets.definitions.units[world.entities[i].unit]
        if world.entities[i].stationary {                                      // 10037b70..10037bb4
            var e = world.entities[i]
            e.object.vx = 0; e.object.vy = 0
            e.desiredVX = 0; e.desiredVY = 0
            e.accelX = 0; e.accelY = 0
            world.entities[i] = e
            return
        }
        let speed = rng.range(u.initialSpeedMin, u.initialSpeedMax)            // 10037bbc..10037bc4
        var vx: Float, vy: Float
        if flag || u.initialHeadingSetInEditor {                               // 10037bcc..10037be0
            (vx, vy) = Trig.vector(heading: Trig.internalHeading(heading), speed: speed)   // 10037e34..10037e50
        } else if u.initiallyHuntsClosestPlayer {                              // 10037be4..10037bec
            let px = world.entities[i].object.x, py = world.entities[i].object.y
            let w = assets.floats[54]
            let refX: Float = w * Float(0.5)                                   // 10037c00..10037c24
            let t = closestActivePlayer(toX: refX, y: 0) ?? (refX, Float(-100))   // 10037c28..10037c44
            let d = Self.normalised(t.x - px, t.y - py)                        // 10037c48..10037c64
            vx = d.x * speed; vy = d.y * speed                                 // 10037c6c..10037c80
        } else if u.doBurst || u.doImplode {                                   // 10037c88..10037c9c
            let px = world.entities[i].object.x, py = world.entities[i].object.y
            let gx = world.groups[g].x, gy = world.groups[g].y
            let dx: Float, dy: Float
            if u.doBurst { dx = px - gx; dy = py - gy }                        // 10037cb0..10037cd0
            else { dx = gx - px; dy = gy - py }                                // 10037cd8..10037cf8
            let d = Self.normalised(dx, dy)                                    // 10037d08
            vx = d.x * speed                                                   // 10037d18
            vy = -(d.y * speed)                                                // 10037d24..10037d28 fneg
            world.entities[i].heading = Trig.internalHeading(Trig.headingOf(vx: d.x, vy: d.y))   // 10037d14..10037d40
        } else {
            var h: Int32
            var fromInitial: Bool
            if u.useOwnerHeading, let o = owner {                              // 10037d4c..10037d80
                h = facing(of: o); fromInitial = false
            } else {
                h = u.initialHeading; fromInitial = true                       // 10037d5c / 10037d88
            }
            if fromInitial && u.initialHeadingTolerance != 0 {                 // 10037d94..10037da4
                let half = u.initialHeadingTolerance / 2                       // 10037da8..10037db4
                h = h &+ rng.range(0 &- half, half)                            // 10037db8
                if h < 0 { h &+= 360 } else if h > 359 { h &-= 360 }           // 10037dc4..10037de8
                if h < 0 || h > 359 { h = 0 }                                  // 10037dec..10037e04
            }
            world.entities[i].heading = h                                      // 10037e10
            (vx, vy) = Trig.vector(heading: Trig.internalHeading(h), speed: speed)   // 10037e14..10037e28
        }
        if mult != 1.0 {                                                       // 10037e58..10037e78
            vx = vx * mult; vy = vy * mult
        }
        var e = world.entities[i]
        e.object.vx = vx; e.object.vy = vy
        e.spawnVX = vx; e.spawnVY = vy                                         // 10037e84..10037e8c
        e.desiredVX = vx; e.desiredVY = vy                                     // 10037e94..10037e9c
        e.accelX = 0; e.accelY = 0                                             // 10037ea0..10037ea4
        world.entities[i] = e
    }

    /// `FUN_10037ed0(e) @ 10037ed0` — the cyclic-motion start velocity (spawn-and-waves §3.4, `10037ed0..
    /// 100380d8`). Draws in order: **`10037f04`** `R(0,1)` (≠ 0 → mag 1.0, else 1.4), **`10037f28`** a =
    /// `R(1,4)`, **`10037f54`** f = `R(1,100)` / 100.0 (`fdivs`), vx = a + f, **`10037f8c`** `R(0,1)` ≠ 0 → vx =
    /// −vx, **`10037fa8`** vy = `R(1,4)` + f, then when y > float(trunc(H) / 4) (C division) **`10038034`**
    /// `R(0,1)` ≠ 0 → vy = −vy. len = `root(fctiwz(fmadds(vx, vx, vy·vy)))`; ux = vx / len, uy = vy / len;
    /// velocity = (ux·mag, uy·mag) = desired = spawn copy; accel = (fl32(0.2·ux), fl32(0.2·uy)) in double.
    mutating func cyclicStart(_ i: Int) {
        let mag: Float = rng.range(Int32(0), 1) != 0 ? 1.0 : 1.4   // 10037efc..10037f1c (table 0x100d7204 +0x18 / +0x1c)
        let a = Float(rng.range(Int32(1), 4))                                         // 10037f20..10037f50
        let f: Float = Float(rng.range(Int32(1), 100)) / Float(100)                   // 10037f40..10037f84
        var vx: Float = a + f                                                  // 10037f88
        if rng.range(Int32(0), 1) != 0 { vx = -vx }                                   // 10037f70..10037f9c
        var vy: Float = Float(rng.range(Int32(1), 4)) + f                             // 10037fa0..10037fd8
        let y = world.entities[i].object.y                                     // 10037fdc FUN_100128f0
        let h = EntityDraw.fctiwz(assets.floats[55]) / 4                       // 10037fe4..10038010 (srawi; addze)
        if y > Float(h) {                                                      // 10038024..10038028
            if rng.range(Int32(0), 1) != 0 { vy = -vy }                               // 1003802c..10038044
        }
        let len = Trig.root(EntityDraw.fctiwz((vy * vy).addingProduct(vx, vx)))   // 10038048..1003805c
        let ux: Float = vx / len, uy: Float = vy / len                         // 10038064..1003806c
        var e = world.entities[i]
        e.object.vx = ux * mag; e.object.vy = uy * mag                         // 10038070..1003808c
        e.desiredVX = e.object.vx; e.desiredVY = e.object.vy                   // 10038090..1003809c
        e.spawnVX = e.object.vx; e.spawnVY = e.object.vy                       // 100380a0..100380ac
        e.accelX = Float(0.2 * Double(ux)); e.accelY = Float(0.2 * Double(uy))   // 10038068..10038088, 100380b0..b4
        world.entities[i] = e
    }

    /// `FUN_10012a00(e, &rect)` — the bounding box {trunc(y − hh), trunc(x − hw), trunc(y + hh), trunc(x + hw)}.
    func boundingBox(_ i: Int) -> MacRect {
        let o = world.entities[i].object
        let hw = Float(o.halfWidth), hh = Float(o.halfHeight)
        return MacRect(top: EntityDraw.fctiwz(o.y - hh), left: EntityDraw.fctiwz(o.x - hw),
                       bottom: EntityDraw.fctiwz(o.y + hh), right: EntityDraw.fctiwz(o.x + hw))
    }

    /// `FUN_10036be0(unit, player, 0)` (`10036be0..10036ce4`): every group member whose unit ID (+0x94 → +0x4) is
    /// `id` and whose `+0xd8` is `player` → `FUN_10036120(group, e, 0, 0)` (`removeMember`, Combat/Removal — C11b).
    /// Both counts are taken once (`10036c00..10036c0c`, `10036c44..10036c50`).
    mutating func removeEntities(ofUnit id: FourCC, ownedBy player: Int8) {
        let units = assets.definitions.units
        let groupCount = world.groups.count
        var g = 0
        while g < groupCount {
            let memberCount = world.groups[g].members.count
            var k = 0
            while k < memberCount {
                let slot = world.groups[g].members[k]
                if units[world.entities[slot].unit].id == id && world.entities[slot].ownerPlayer == player {   // 10036c88..10036ca8
                    removeMember(group: g, entity: slot, destroyed: false, byPlayer: false)   // 10036cac..10036cb8
                }
                k += 1
            }
            g += 1
        }
    }

    /// `FUN_100380e0(text, unit, now) @ 100380e0` — the entry notice: `"none"` → nothing; with
    /// `displayNoticeOnceOnly` a text already in the shown list is skipped, else added (`FUN_10038230` /
    /// `FUN_100382f0`); post = the template at r2+0x52c4 (alignment `CEGA`) with the text, hold 0, fade-in 1,
    /// delay = `entryNoticeDelay`, sound = `entryNoticeSound` (`FUN_100181e0(rec, now)`).
    mutating func postEntryNotice(unit ui: Int, now: Int32) {
        let u = assets.definitions.units[ui]
        guard u.entryNotice != "none" else { return }                          // 1003810c..10038118
        let text = Array((MacRoman.encode(u.entryNotice, lossy: true) ?? []).prefix(63))
        if u.displayNoticeOnceOnly {                                           // 1003811c..10038148
            if world.noticesShown.contains(text) { return }
            world.noticesShown.append(text)
        }
        notice.post(NoticeSlot.Post(text: text, hold: false, fadeIn: true, delay: u.entryNoticeDelay,
                                    sound: u.entryNoticeSound, alignment: .centerInGameArea), now: now)
    }
}
