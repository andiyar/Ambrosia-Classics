import Foundation
import HectorResources

/// G_EntityGroup.cc's state (spawn-and-waves.md §1.2–§1.3, §8; micro-wave-2026-10-06.md §3.7): the
/// 1000-entity pool, the active group list (PERM first), the id counters, the pending level-object list,
/// the "notice shown once" list and the live ground-target count. ★ LOCKED (plan S2).
///
/// **Index-based API (plan invariant 13).** Entities are addressed by their pool slot (`entities[i]`, i =
/// +0x148); groups by their position in `groups`. Rule code re-reads `entities[i]` after any call that may
/// mutate the world and never holds an `inout Entity` across a `GameState` call.
///
/// **Iteration (Hazards, INDEX #38, loose-ends-combat §4.5).** `FUN_10033850` walks the groups and each
/// group's members re-reading both counts every step (`100345a0`, `100345c0`), so members appended to a
/// group's tail and groups appended to the list's tail during a pass are visited by the same pass; nothing
/// is unlinked until the reaper. `Walk` is that iteration.
///
/// Listing reads for C7:
/// - `FUN_10032e60 @ 10032e60` (level start, `10032e60..1003308c`): entity-limit latch −0x6110 = 0
///   (`GameState.entityLimitWarned`); `FUN_10038450` (pool reset); `FUN_10035b00` (free all groups); a new
///   active list (−0x6108); the "shown once" list (−0x610c) freed entry by entry and recreated; group-id
///   counter −0x6128 = 20000000, entity serial counter −0x612c = 1000, ground count −0x6118 = 0
///   (`10032f88..10032fa4`); the PERM group: allocated, appended, +0x98 = `PERM`, +0xa4/+0xa8/+0xac = 0,
///   +0x94 = counter **post-increment** (PERM = 20000000, the next group 20000001), member list, +0xb4 = 0,
///   +0xb8/+0xb9 = 0 (`10032fec..10033068`); then `FUN_10035900(level)` — the pending list, C8's.
/// - `FUN_10038450 @ 10038450`: pool +0 (hint) = **0**, +4 (count) = 0, every slot's in-use byte = 0
///   (25 × 40 unrolled). The entities themselves are not touched.
/// - `FUN_100385d0 @ 100385d0` / `FUN_10038810 @ 10038810`: as `allocate` / `free`.
/// - Not kept: the module's debug globals −0x611c (read by `FUN_10033220` `100332d8`), −0x6111…−0x6114
///   (read by `FUN_100345f0`), −0x6124 / −0x6120 (tracked-unit IDs, `'none'` from the static initialiser
///   `10032c2c..10032c30`). Their only writers are the G_EntityGroup debug-command handlers after
///   `FUN_10038810` (`10038970…100390a0`; −0x611c's is the `PLAYERACTIVESPAWNS` toggle at `0x10039080`,
///   loose-ends-combat §2.2), registered debug-only and so never created by `FUN_1002d080`
///   (messages-notices-console §5.2): they hold their initial values all game and readers treat them as
///   constants — −0x611c = **1** (`0x100e0214` in the data image; `GameState.playersActiveCheckEnabled`),
///   −0x6111…−0x6114 = 0, −0x6124 / −0x6120 = `'none'`.
public struct EntityWorld: Equatable, Sendable {
    /// `FUN_10038390` preallocates 1000 entities; `10038600 cmpwi r4,0x3e8`.
    public static let capacity = 1000
    /// −0x612c after `FUN_10032e60` (`10032f90 li r3,0x3e8`).
    public static let firstSerial: Int32 = 1000

    /// The pool's entities, by slot (persistent: a freed slot keeps its fields until the next allocation's
    /// reset, which leaves some of them — `Entity.reset`).
    public var entities: [Entity]
    /// The pool's slot in-use bytes (slot + 8).
    public var inUse: [Bool]
    /// Pool +0: the free hint, −1 = none (alloc clears it; free sets it; the level reset stores 0).
    public var freeHint: Int = -1
    /// Pool +4: slots in use.
    public var liveCount: Int = 0
    /// `_DAT_100e0228` (−0x6108): the active group list, PERM first.
    public var groups: [EntityGroup] = []
    /// −0x612c: the next entity serial (+0x9c).
    public var nextSerial: Int32 = EntityWorld.firstSerial
    /// −0x6128: the next group id (+0x94).
    public var nextGroupID: Int32 = EntityGroup.permID
    /// `_DAT_100e022c` (−0x6104): the pending level objects, 0xbc group records in file order
    /// (`FUN_10035900`, level-scroll-objects §6.2; consumed by `FUN_10033090`). Built by C8.
    public var pendingLevelObjects: [EntityGroup] = []
    /// `_DAT_100e0224` (−0x610c): entry notices already shown with `displayNoticeOnceOnly` (63-char copies,
    /// `FUN_10038230` lookup / `FUN_100382f0` add).
    public var noticesShown: [[UInt8]] = []
    /// `_DAT_100e0218` (−0x6118): live ground-accuracy targets (+1 in `FUN_10035cd0` `100360ec`, −1 in
    /// `FUN_10036610` `100366d8`).
    public var groundCount: Int32 = 0

    /// A world as the level start leaves it (the pool built, then `levelReset`).
    public init() {
        entities = Array(repeating: Entity(), count: Self.capacity)
        inUse = Array(repeating: false, count: Self.capacity)
        levelReset()
    }

    /// `FUN_10032e60` without its first store (the entity-limit latch, `GameState.levelResetEntities`) and
    /// without its last call (`FUN_10035900`, C8 — it frees and rebuilds `pendingLevelObjects`, which this
    /// method leaves alone). See the type's comment.
    public mutating func levelReset() {
        freeHint = 0                                                    // 10038450 FUN_10038450
        liveCount = 0
        for i in inUse.indices { inUse[i] = false }
        groups = []                                                     // 10032e90 FUN_10035b00; 10032eb4
        noticesShown = []                                               // 10032ed0..10032f6c
        nextGroupID = EntityGroup.permID                                // 10032f88..10032f94
        nextSerial = Self.firstSerial                                   // 10032f90 / 10032f9c
        groundCount = 0                                                 // 10032fa4
        var perm = EntityGroup()                                        // 10032fa0..10032fe4 (appended)
        perm.unit = EntityGroup.perm                                    // 10032fec..10032ff4
        perm.requested = 0; perm.live = 0; perm.destroyed = 0           // 10033000..10033008
        perm.id = nextGroupID                                           // 1003300c..10033018
        nextGroupID &+= 1
        perm.editorHeading = 0; perm.stationary = false; perm.terrainEffects = false   // 1003305c..10033068
        groups.append(perm)
    }

    /// `FUN_100385d0 @ 100385d0` — allocate a pool entity, returning its slot: count ≥ 1000 → nil
    /// (`10038600..10038614`, after a debug log); the hint if ≠ −1 (`1003879c`), else the first slot whose
    /// in-use byte is 0 (`10038628..10038778`; none → assert and nil); then count + 1, in use, the entity
    /// reset `FUN_100142f0`, +0x148 = slot, hint = −1 (`100387a8..100387dc`).
    public mutating func allocate() -> Int? {
        if liveCount >= Self.capacity { return nil }
        let index: Int
        if freeHint != -1 {
            index = freeHint
        } else {
            guard let first = inUse.firstIndex(of: false) else { return nil }
            index = first
        }
        liveCount += 1
        inUse[index] = true
        entities[index].reset()
        entities[index].slot = index
        freeHint = -1
        return index
    }

    /// `FUN_10038810 @ 10038810` — return slot +0x148 to the pool: in use = 0, count − 1, **hint = that slot**
    /// (the next allocation reuses the most recently freed slot).
    public mutating func free(_ slot: Int) {
        inUse[slot] = false
        liveCount -= 1
        freeHint = slot
    }

    /// `FUN_10035cd0` `10035d78..10035d84` — the serial counter, post-increment.
    public mutating func takeSerial() -> Int32 {
        let s = nextSerial
        nextSerial &+= 1
        return s
    }

    /// `FUN_10033220` `100333a4..10033518` — the group a request of `size` members joins, returning its index
    /// in `groups`. **PERM** (`groups[0]`, `FUN_10000cf0(list, 0)`) iff `size == 1` and (no owner, or the
    /// owner's group id +0xa0 == 20000000): PERM +0xa4 = size (stored), +0xa8 += size. Otherwise a **new group
    /// at the list's tail** (`FUN_100009e0`): +0x98 unit, +0xa4 = +0xa8 = size, +0xac = 0, +0xb4/+0xb8/+0xb9
    /// from the request, +0x94 = the id counter post-increment. The position (+0x9c/+0xa0, `1003351c..
    /// 1003357c`, written to PERM too) and the members are the caller's (C8).
    /// - Parameter ownerGroupID: the owner entity's +0xa0, or nil when request +0x20 is null.
    public mutating func openGroup(unit: FourCC, size: Int32, ownerGroupID: Int32?, editorHeading: Int32,
                                   stationary: Bool, terrainEffects: Bool) -> Int {
        let joinsPerm = size == 1 && (ownerGroupID == nil || ownerGroupID == EntityGroup.permID)
        if joinsPerm {
            groups[0].requested = size                                  // 100333f0
            groups[0].live &+= size                                     // 100333f8..10033400
            return 0
        }
        var g = EntityGroup()                                           // 10033454..1003349c
        g.unit = unit                                                   // 100334a8
        g.requested = size                                              // 100334ac
        g.live = size                                                   // 100334b0
        g.destroyed = 0                                                 // 100334b4
        g.editorHeading = editorHeading                                 // 100334b8..100334bc
        g.stationary = stationary                                       // 100334c0..100334c4
        g.terrainEffects = terrainEffects                               // 100334c8..100334cc
        g.id = nextGroupID                                              // 1003350c..10033518
        nextGroupID &+= 1
        groups.append(g)
        return groups.count - 1
    }

    /// The same-pass iteration of `FUN_10033850` over every group's members, counts re-read at each step.
    public struct Walk: Equatable, Sendable {
        /// Current group index and member index within it.
        public var group = 0
        public var member = 0

        public init() {}

        /// The next member's pool slot, or nil past the last group.
        public mutating func next(in world: EntityWorld) -> Int? {
            while group < world.groups.count {
                let members = world.groups[group].members
                if member < members.count {
                    let slot = members[member]
                    member += 1
                    return slot
                }
                group += 1
                member = 0
            }
            return nil
        }
    }
}
