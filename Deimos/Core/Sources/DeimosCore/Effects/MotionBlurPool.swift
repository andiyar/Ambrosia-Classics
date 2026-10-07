import Foundation

/// The argument of `FUN_10046840` (built by `FUN_10033850` at `100343a4`; particles-debris-blur §4.3).
public struct MotionBlurRequest: Equatable, Sendable {
    /// The entity's sprite instance (req +0x00 → the entity).
    public var object: GameObject
    /// `stateMotionBlur_InitialVisibilityPercent` (state +0x2f8) → req +0x04.
    public var initialVisibility: Float
    /// `stateMotionBlur_VisibilityDeltaPercent` (state +0x2fc) → req +0x08.
    public var visibilityDelta: Float
    /// `stateMotionBlur_AllowGlowDrawing` (state +0x2ed) → req +0x0c.
    public var allowGlow: Bool

    public init(object: GameObject, initialVisibility: Float, visibilityDelta: Float, allowGlow: Bool = false) {
        self.object = object
        self.initialVisibility = initialVisibility
        self.visibilityDelta = visibilityDelta
        self.allowGlow = allowGlow
    }
}

/// The outcome of `MotionBlurPool.emit`.
public enum MotionBlurEmit: Equatable, Sendable {
    /// A blur was created in this pool slot and appended to the list.
    case emitted(slot: Int)
    /// No blur. `postLimitMessage` is true exactly once per level, on the first refusal at 1000 in use: the caller
    /// posts "Reached Motion Blur Limit" with `FUN_1002dbd0(text, type 1, upper 1, readout 0)`
    /// (`10046ef4..10046f04`; the `FUN_10049550` debug-log line is not modelled).
    case refused(postLimitMessage: Bool)
}

/// G_MotionBlur.cpp — afterimages (particles-debris-blur §4, HIGH). 1000 preallocated sprite objects
/// (`FUN_10046c70`), a free-slot cache and the blur list (`0x100e0284`, draw order = append order). Visual only; the
/// interval draw that gates an emit belongs to the entity update (C12), not here.
public struct MotionBlurPool: Equatable, Sendable {
    public static let capacity = 1000

    /// The pool objects. A slot keeps whatever it last held in the fields an emit does not copy (velocity, and the
    /// hit glow when `allowGlow` is false — the stale-state quirk of §4.3).
    public internal(set) var slots: [GameObject]
    /// Entry +0x0 (in use) of the 0xc-byte pool records.
    public internal(set) var inUse: [Bool]
    /// Pool header +0x4: the number in use.
    public internal(set) var count: Int32 = 0
    /// Pool header +0x0: the cached free index, −1 = scan. Prealloc sets −1; the level reset sets **0** (quirk).
    public internal(set) var cachedFree: Int32 = -1
    /// Pool header +0x8: the limit message was posted this level.
    public internal(set) var limitWarned = false
    /// The blur list: slot indices in append order.
    public internal(set) var list: [Int] = []

    /// `FUN_10046c70` — the app-start prealloc: every slot a fresh sprite (`FUN_100125d0`), none in use, cache −1.
    public init() {
        slots = Array(repeating: GameObject(), count: MotionBlurPool.capacity)
        inUse = Array(repeating: false, count: MotionBlurPool.capacity)
    }

    /// `FUN_100467c0` — per-level reset: empty the list (`FUN_10046ba0`), then `FUN_10046d30`: cache 0, count 0,
    /// warn flag 0, all 1000 slots free (`10046d30..10046e18`). Slot contents stay (stale).
    public mutating func levelReset() {
        list = []
        cachedFree = 0
        count = 0
        limitWarned = false
        for i in inUse.indices { inUse[i] = false }
    }

    /// `FUN_10046840 @ 10046840` with the allocator `FUN_10046eb0`. Allocation (`10046ed0..100470d0`): count ≥ 1000
    /// → refused (the message once per level); else the cached index (used without an in-use check) or the first
    /// free slot of a scan; count +1, in use, cache −1. Then the slot is appended to the list and the entity's
    /// sprite copied (`10046874..100469e8`): +0x18..+0x70 and +0x84..+0x8c, with **+0x1a and +0x38 forced 0**;
    /// the glow fields +0x74..+0x80 only when `allowGlow`; then visibility = Initial, target = 0.0
    /// (`*(float*)0x100d7408`), step = Delta; position via `FUN_100128d0`/`FUN_10012910`. Velocity is not copied.
    public mutating func emit(_ req: MotionBlurRequest) -> MotionBlurEmit {
        if count >= Int32(MotionBlurPool.capacity) {                 // 10046ed4 cmpwi r4,0x3e8
            if limitWarned { return .refused(postLimitMessage: false) }
            limitWarned = true                                       // 10046f10
            return .refused(postLimitMessage: true)
        }
        var index = Int(cachedFree)
        if cachedFree == -1 {                                        // 10046f20
            guard let free = inUse.firstIndex(of: false) else {      // 10046f28..10047078
                return .refused(postLimitMessage: false)             // 10047084 assert; returns 0
            }
            index = free
        }
        count += 1                                                   // 100470a8..100470b4
        inUse[index] = true                                          // 100470c0
        cachedFree = -1                                              // 100470d0
        list.append(index)                                           // 1004686c bl 0x100009e0

        let old = slots[index]
        var b = req.object
        b.vx = old.vx                                                // +0x10/+0x14 not copied
        b.vy = old.vy
        b.adjustShadowForScaling = false                             // 1004688c stb 0,0x1a
        b.drawShadow = false                                         // 10046920 stb 0,0x38
        if !req.allowGlow {                                          // 1004696c..10046974
            b.hitGlowOn = old.hitGlowOn
            b.hitGlowLevel = old.hitGlowLevel
            b.hitGlowColour = old.hitGlowColour
        }
        b.visibility = req.initialVisibility                         // 100469c8
        b.visibilityTarget = 0.0                                     // 100469cc (0x100d7408 = 0.0)
        b.visibilityStep = req.visibilityDelta                       // 100469d4
        slots[index] = b
        return .emitted(slot: index)
    }

    /// `FUN_10046a10 @ 10046a10` — per tick (world update `10006be8`): `vis −= step` (`fsubs`); `vis < target`
    /// (0.0) → unlink and free (`FUN_100470f0`: in use 0, count −1, cache = this index) (`10046a7c..10046ab4`).
    public mutating func update() {
        var kept: [Int] = []
        kept.reserveCapacity(list.count)
        for i in list {
            slots[i].visibility = slots[i].visibility - slots[i].visibilityStep
            if slots[i].visibility < slots[i].visibilityTarget {     // 10046a94 fcmpo; bge keep
                inUse[i] = false
                count -= 1
                cachedFree = Int32(i)
            } else {
                kept.append(i)
            }
        }
        list = kept
    }

    /// `FUN_10046ae0 @ 10046ae0` — draw world (`10007094`, after the entity draw): the existing `EntityDraw.entry`
    /// (`FUN_10012f20`) per blur in list order; an entry at visibility ≤ 0.0 draws nothing.
    public mutating func drawCommands(hOffset: Int32, floats: [Float]) -> [DrawCommand] {
        var out: [DrawCommand] = []
        for i in list {
            out += EntityDraw.entry(&slots[i], hOffset: hOffset, floats: floats)
        }
        return out
    }
}
