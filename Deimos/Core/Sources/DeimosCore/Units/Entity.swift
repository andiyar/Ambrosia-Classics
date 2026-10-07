import Foundation
import HectorResources

/// One per-entity spawn-set runtime record (0x18 bytes, spawn-and-waves.md §2.1, HIGH): created zeroed by
/// `FUN_100144a0` for every spawn set of every state; armed by `FUN_10017cb0`, run by `FUN_10015b40`.
public struct SpawnRecord: Equatable, Sendable {
    /// +0x00: ticks from one volley's arm to the next (`< 0` → the set is inert).
    public var rate: Int32 = 0
    /// +0x04: game time of the last arm.
    public var lastArm: Int32 = 0
    /// +0x08: requests still to issue in the current volley.
    public var remaining: Int32 = 0
    /// +0x0c: size of the current volley.
    public var volley: Int32 = 0
    /// +0x10: countdown to the next request.
    public var countdown: Int32 = 0
    /// +0x14: active.
    public var active = false

    public init() {}
}

/// One G_Entity (0x1ec bytes; the 1000 are preallocated by `FUN_10038390` and reused through the pool —
/// `EntityWorld`). ★ LOCKED (plan S2): one stored field per offset the bank names (spawn-and-waves §1.3,
/// units-movement §3, damage-health-death §2–§3, sound-music §5, particles-debris-blur §2.6/§4.3,
/// loose-ends-combat §4.2), each with its offset; C7 also scanned every entity-register access of the
/// G_Entity / G_EntityGroup functions in the listing for 0x94…0x1eb (PR notes) — the table below is that
/// set. Defaults are the constructor's (`FUN_100141a0`: `FUN_100125d0` object constructor, +0x94/+0x98
/// and the 20 record-list heads 0, then `FUN_100142f0`); `reset()` is `FUN_100142f0` alone.
///
/// Not kept: +0x98, the unit's lookup-cache pointer (`FUN_100144a0` writes it; `FUN_1003d550` reads it in
/// `FUN_10015550`/`FUN_10015b40` before falling back to the global list) — `DeimosAssets.unitIndex` replaces the
/// cache with the same result. Offsets +0xc5…+0xc7, +0xc9, +0xce, +0xcf are not accessed through an entity
/// register by any function scanned and have no field.
public struct Entity: Equatable, Sendable {
    /// Per-state arrays have one slot per state a unit may define (state s at unit + 0x4e0 + s·0x5e0).
    public static let stateSlots = 20

    /// +0x00…+0x93: the G_GameObject part (+0x36 = draw into the terrain buffer, the wreck stamp).
    public var object = GameObject()
    /// +0x94: the unit definition — an index into `DeimosAssets.definitions.units`; −1 = the null pointer the
    /// constructor stores (`100141c4`). Written at unit assignment (`FUN_100144a0`, C8).
    public var unit: Int = -1
    /// +0x9c: entity serial (id), from the world's counter (`FUN_10035cd0` `10035d78..10035d84`); −1 after reset.
    public var serial: Int32 = -1
    /// +0xa0: the owning group's id (`10035d88..10035d8c`); −1 after reset.
    public var groupID: Int32 = -1
    /// +0xa4: game time the current state started (`FUN_100146f0` 4th argument; restamped while +0xb0 > 0).
    public var stateStart: Int32 = 0
    /// +0xa8: current state index; −1 after reset.
    public var state: Int32 = -1
    /// +0xac: hittable — visibility ≥ 100.0 or `hittableWhenInvisible` (damage §2.6; `10033ea0`).
    public var hittable = false
    /// +0xb0: spawn-in countdown (group delay); the entity is processed once it is ≤ 0 (`10033a54`).
    public var spawnCountdown: Int32 = 0
    /// +0xb4: game time of the last accepted hit (`FUN_10014f10` step 2–3, hit delay).
    public var lastHit: Int32 = 0
    /// +0xb8: the state timer drawn at state entry (`gameTime == start + timer` fires; not reset).
    public var timer: Int32 = 0
    /// +0xbc: game time of the last animation frame step / turn (`FUN_10015930`, `FUN_100172d0`).
    public var lastFrameStep: Int32 = 0
    /// +0xc0: animation playing backwards.
    public var animationBackwards = false
    /// +0xc1: rotating / tracking a target (`FUN_100172d0`, read by `FUN_10017150`, `FUN_10034ee0`).
    public var rotating = false
    /// +0xc2: animation stopped on its last frame (rule #10).
    public var animationStopped = false
    /// +0xc3: the current state has ≥ 1 spawn set (`FUN_10017cb0` `10017d0c`; gate of `FUN_10015b40`).
    public var hasSpawnSets = false
    /// +0xc4: rotation-pause countdown (`TimeToPauseRotationAfterSpawning`).
    public var rotationPause: Int32 = 0
    /// +0xc8: animates (`face ≠ none ∧ FrameDelta > 0`, `FUN_100146f0`).
    public var animates = false
    /// +0xca: collected pickup (stops the coin release, damage §4.3).
    public var collected = false
    /// +0xcb: deleted — flagged only; reaped by `FUN_10036610` after the entity loop.
    public var deleted = false
    /// +0xcc: fleeing (set by `FUN_10017510`, cleared by `FUN_100146f0`).
    public var fleeing = false
    /// +0xcd: the unit has a `UseThisStateOnShieldDepletion` state (`FUN_10035cd0` `10035dac..10035dcc`).
    public var hasDepletionState = false
    /// +0xd0 / +0xd4: last collision spawn time / collision spawns made (`FUN_10014f10` step 13).
    public var collisionSpawnTime: Int32 = 0
    public var collisionSpawnCount: Int32 = 0
    /// +0xd8: owning player index, −1 (0xff) none — inherited along the spawn chain (loose-ends-combat §4.3).
    public var ownerPlayer: Int8 = -1
    /// +0xd9: killer player index, −1 (0xff) = none / timer / rule.
    public var killer: Int8 = -1
    /// +0xda: destroyed (as opposed to silently deleted).
    public var destroyed = false
    /// +0xdc / +0xe0: orbit radius (float) / orbit angle (int degrees, internal convention).
    public var orbitRadius: Float = 0
    public var orbitAngle: Int32 = 0
    /// +0xe4 / +0xe8: state sound — last play time / plays this state visit (sound-music §5).
    public var lastSoundTime: Int32 = 0
    public var soundCount: Int32 = 0
    /// +0xec: game time of the last motion blur (particles-debris-blur §4.3).
    public var lastBlur: Int32 = 0
    /// +0xf0 / +0xf4: state particles — last burst time / bursts this state visit (§2.6).
    public var lastBurst: Int32 = 0
    public var burstCount: Int32 = 0
    /// +0xf8: the shown pickup weapon ID (`FUN_100146f0` cycles it with `FUN_1002adb0`); `none` after reset.
    public var shownWeapon: FourCC = .none
    /// +0xfc: game time of the last on-hit state change (`FUN_10014f10` step 8).
    public var lastHitStateChange: Int32 = 0
    /// +0x100 / +0x104: velocity at spawn (copy, `FUN_10037b50` / `FUN_10037ed0`; not reset).
    public var spawnVX: Float = 0
    public var spawnVY: Float = 0
    /// +0x108 / +0x10c: desired velocity (units-movement §4–§5; not reset).
    public var desiredVX: Float = 0
    public var desiredVY: Float = 0
    /// +0x110 / +0x114: per-axis acceleration (not reset).
    public var accelX: Float = 0
    public var accelY: Float = 0
    /// +0x118: tracked player, −1 none (`FUN_10015280` from `FUN_10005d40`).
    public var trackedPlayer: Int8 = -1
    /// +0x11c / +0x120: target point (nearest player or flee point).
    public var targetX: Float = 0
    public var targetY: Float = 0
    /// +0x124 / +0x128: offset from the owner; +0x12c / +0x130: the owner's last position (spawn-and-waves §4).
    public var ownerOffsetX: Float = 0
    public var ownerOffsetY: Float = 0
    public var ownerLastX: Float = 0
    public var ownerLastY: Float = 0
    /// +0x134: shields (float; spawn value by sector, damage §3; not reset).
    public var shields: Float = 0
    /// +0x138: compass heading in degrees (written at spawn only; not reset).
    public var heading: Int32 = 0
    /// +0x13c: stationary (request +0x1c, or stopped by a ground obstacle).
    public var stationary = false
    /// +0x13d: terrain effects (request +0x1d; read only by `FUN_10015b40` `10015da4`).
    public var terrainEffects = false
    /// +0x13e: has ≥ 1 spawn-set record (`FUN_100144a0` `1001460c`; gates destruct-children, `1003614c`).
    public var hasSpawnRecords = false
    /// +0x140: the owner entity — a pool slot index into `EntityWorld.entities`; nil = null pointer.
    /// The link is valid iff set, the ids agree (+0x144 == owner +0x9c) and the owner is not deleted
    /// (`FUN_10036ab0`).
    public var owner: Int? = nil
    /// +0x144: the owner's serial; −1 after reset (`100143b8`, from `0x100d6c64` = {0, −1}).
    public var ownerSerial: Int32 = -1
    /// +0x148: this entity's pool slot (`FUN_100385d0` `100387d4`); −1 after reset.
    public var slot: Int = -1
    /// +0x14c + 4·s: times state s was entered this life (`FUN_100146f0`; sound-music §5).
    public var enterCount: [Int32] = Array(repeating: 0, count: Entity.stateSlots)
    /// +0x19c + 4·s: state s's spawn-set records (one list per state; `FUN_100144a0` fills, reset frees).
    public var spawnRecords: [[SpawnRecord]] = Array(repeating: [], count: Entity.stateSlots)

    public init() {}

    /// `FUN_100142f0 @ 100142f0` — the entity field reset (pool allocation `100387cc`; constructor). Listing
    /// `100142f0..10014490`: enter counts +0x14c…+0x198 = 0; +0x94 = +0x98 = 0; each record list freed
    /// (`FUN_10017e10`) and its head zeroed; owner {+0x140, +0x144} = {0, −1}; +0x148 = +0x9c = +0xa0 = −1;
    /// +0xa4 = 0; +0xa8 = −1; +0xac, +0xb0, +0xb4, +0xbc, +0xc0, +0xc2, +0xc1, +0xc4, +0xc3, +0xc8, +0xfc,
    /// +0xca, +0xcb, +0xcc = 0; +0xd8 = +0xd9 = −1; +0xda = 0; +0xdc = 0.0 (`0x100d6c8c`); +0xe0, +0xd0,
    /// +0xd4, +0xe4, +0xe8, +0xec, +0xf0, +0xf4 = 0; +0xf8 = `none`; +0xcd = 0; target +0x11c/+0x120, offsets
    /// +0x124…+0x130 = 0.0 (`0x100d67f4`); +0x118 = −1; +0x13c/+0x13d/+0x13e = 0; then `FUN_10012650` (the
    /// object reset, which keeps +0x64 and the hit-glow level/colour +0x78/+0x80 — micro-wave §3.6).
    /// **Not reset** (a reused slot keeps the previous occupant's values, as the pool does): +0xb8 timer,
    /// +0x100…+0x114 velocity copies, +0x134 shields, +0x138 heading.
    public mutating func reset() {
        enterCount = Array(repeating: 0, count: Entity.stateSlots)      // 10014318..10014364
        unit = -1                                                       // 10014368 (+0x98: 1001436c)
        spawnRecords = Array(repeating: [], count: Entity.stateSlots)   // 10014370..10014394
        owner = nil                                                     // 100143a8
        ownerSerial = -1                                                // 100143b8
        slot = -1                                                       // 100143c8
        serial = -1                                                     // 100143d0
        groupID = -1                                                    // 100143d4
        stateStart = 0                                                  // 100143d8
        state = -1                                                      // 100143dc
        hittable = false                                                // 100143e0
        spawnCountdown = 0                                              // 100143e4
        lastHit = 0                                                     // 100143e8
        lastFrameStep = 0                                               // 100143ec
        animationBackwards = false                                      // 100143f0
        animationStopped = false                                        // 100143f4
        rotating = false                                                // 100143f8
        rotationPause = 0                                               // 100143fc
        hasSpawnSets = false                                            // 10014400
        animates = false                                                // 10014404
        lastHitStateChange = 0                                          // 10014408
        collected = false                                               // 1001440c
        deleted = false                                                 // 10014410
        fleeing = false                                                 // 10014414
        ownerPlayer = -1                                                // 10014418
        killer = -1                                                     // 1001441c
        destroyed = false                                               // 10014420
        orbitRadius = 0                                                 // 10014424
        orbitAngle = 0                                                  // 10014428
        collisionSpawnTime = 0                                          // 1001442c
        collisionSpawnCount = 0                                         // 10014430
        lastSoundTime = 0                                               // 10014434
        soundCount = 0                                                  // 10014438
        lastBlur = 0                                                    // 1001443c
        lastBurst = 0                                                   // 10014440
        burstCount = 0                                                  // 10014444
        shownWeapon = .none                                             // 10014448
        hasDepletionState = false                                       // 1001444c
        targetX = 0; targetY = 0                                        // 10014450 / 10014454
        trackedPlayer = -1                                              // 10014458
        ownerOffsetX = 0; ownerOffsetY = 0                              // 1001445c / 10014460
        ownerLastX = 0; ownerLastY = 0                                  // 10014464 / 10014468
        stationary = false                                              // 1001446c
        terrainEffects = false                                          // 10014470
        hasSpawnRecords = false                                         // 10014474
        // 10014478 FUN_10012650: the object reset keeps +0x64, +0x78, +0x80.
        let tint = object.glowTintColour, level = object.hitGlowLevel, colour = object.hitGlowColour
        object = GameObject()
        object.glowTintColour = tint
        object.hitGlowLevel = level
        object.hitGlowColour = colour
    }
}
