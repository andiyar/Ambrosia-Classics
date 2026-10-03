/// One score-point slot (0x18 bytes at `_points`, 8 slots at 0x34620). Field comments give the original offsets.
/// The per-slot licence-trap threshold (`+0x12`) lives in `PointPool.thresholds` (index = slot).
public struct ScorePoint: Equatable, Sendable {
    public var active = false                 // +0x00
    public var rect = QDRect(top: 0, left: 0, bottom: 0, right: 0)        // +0x02 (y+8, x, y+36, x+48)
    public var spriteSet: Int16 = 0           // +0x0a (0x34)
    public var frame: Int16 = 0               // +0x0c (which score sprite; the `char` argument, sign-extended)
    public var counter: UInt16 = 0            // +0x0e (delay clock, then lifetime clock)
    public var delay: Int16 = 0               // +0x10
    public var delayed = false                // +0x14
    public var visible = false                // +0x15
    public var trap = false                   // +0x16 (licence trap armed: draw pass draws (0,0x14))
    public var dead = false                   // +0x17

    public init() {}
}

/// The score-point pool: `_InitPoints`, `_NewPoint`, `_ProcessPoints` and the non-drawing half of
/// `_DrawPointsToComp`, transcribed from the decompile (Research notes 16 and 49). Self-contained: level,
/// licence flag and RNG come in as parameters.
///
/// Slots are scanned from 0, allocation takes the first free slot, and slots are freed only by `drawPass`
/// (Invariant 8). No RNG in the modelled licence state (`gPointsNotReg` false, Invariant 11) beyond the 8
/// threshold draws of `reset`.
public struct PointPool: Sendable {
    public static let capacity = 8

    public internal(set) var slots: [ScorePoint]
    /// `_gNumActivePoints`.
    public internal(set) var activeCount: Int
    /// The per-slot `+0x12` thresholds, `GetRandomFast(2,6) + 0x12` (20…24); set only by `reset`.
    public internal(set) var thresholds: [Int16]

    public init() {
        slots = Array(repeating: ScorePoint(), count: Self.capacity)
        activeCount = 0
        thresholds = Array(repeating: 0, count: Self.capacity)
    }

    /// `_ResetPoint @ 000023c4` minus its licence side effect: clears active and the trap flag and decrements
    /// `_gNumActivePoints`. (The original also recomputes `gPointsNotReg` from `_RT3_GetDisplayCopies() ==
    /// "N/A"` here; the replica takes that flag as a `newPoint` argument — Invariant 11.)
    mutating func resetPoint(_ i: Int) {
        slots[i].active = false
        slots[i].trap = false
        activeCount -= 1
    }

    /// `_InitPoints @ 0000241b`: per slot 0…7 `_ResetPoint` then `threshold = GetRandomFast(2,6) + 0x12`
    /// (8 draws), then `_gNumActivePoints = 0`.
    public mutating func reset(rng: inout GameRandom) {
        for i in 0..<Self.capacity {
            resetPoint(i)
            thresholds[i] = Int16(truncatingIfNeeded: rng.fast(2, 6)) &+ 0x12
        }
        activeCount = 0
    }

    /// `_NewPoint(x, y, sprite, delay) @ 00002468`: `_gNumActivePoints == 8` → return; `x −= 4`, clamped to
    /// 0 (`x < 0`) or 0x250 (`640 < x + 48`); first free slot: active, sprite set 0x34, frame = the `char`
    /// sprite argument, counter 0, dead 0, rect (y + 8, x, y + 36, x + 48); trap armed when
    /// `threshold <= level && gPointsNotReg` (never cleared here — `_ResetPoint` clears it); delay < 1 → visible
    /// now, else delayed; `_gNumActivePoints++`.
    public mutating func newPoint(x: Int16, y: Int16, sprite: Int16, delay: Int16, level: Int, notRegistered: Bool) {
        if activeCount == Self.capacity { return }
        var left = x &- 4
        if left < 0 {
            left = 0
        } else if 0x280 < Int(left) + 0x30 {
            left = 0x250
        }
        guard let i = slots.firstIndex(where: { !$0.active }) else { return }
        slots[i].active = true
        slots[i].spriteSet = 0x34
        slots[i].frame = Int16(Int8(truncatingIfNeeded: sprite))
        slots[i].counter = 0
        slots[i].dead = false
        slots[i].rect = QDRect(top: y &+ 8, left: left, bottom: y &+ 0x24, right: left &+ 0x30)
        if Int(thresholds[i]) <= level && notRegistered {
            slots[i].trap = true
        }
        slots[i].delay = delay
        if delay < 1 {
            slots[i].delayed = false
            slots[i].visible = true
        } else {
            slots[i].delayed = true
            slots[i].visible = false
        }
        activeCount += 1
    }

    /// `_ProcessPoints @ 00002585`. Skipped when `_gNumActivePoints == 0`. Per active slot 0…7: a visible
    /// (undelayed) point rises 1 px while `top > 0`, then `counter += 1`, `counter > 0x1e` → dead, invisible
    /// (so it dies on its 31st call); a delayed point counts `counter += 1` and, once `delay < counter`, resets
    /// the counter and becomes visible.
    public mutating func process() {
        if activeCount == 0 { return }
        for i in slots.indices where slots[i].active {
            if !slots[i].delayed {
                if 0 < slots[i].rect.top {
                    slots[i].rect.offset(dx: 0, dy: -1)
                }
                slots[i].counter = slots[i].counter &+ 1
                if 0x1e < slots[i].counter {
                    slots[i].dead = true
                    slots[i].visible = false
                }
            } else {
                slots[i].counter = slots[i].counter &+ 1
                if Int(slots[i].delay) < Int(slots[i].counter) {
                    slots[i].counter = 0
                    slots[i].delayed = false
                    slots[i].visible = true
                }
            }
        }
    }

    /// The non-drawing half of `_DrawPointsToComp @ 00002641`: skipped when `_gNumActivePoints == 0`; per active
    /// slot 0…7, a trap-armed point draws `GetRandomFast(0,0x14)` (the only draw-pass RNG site), then a dead
    /// point is freed (`_ResetPoint`). A trap draw of 1 makes the original `_StdError(…"hacked copy"…)` →
    /// `_CleanUp` (it quits); the replica returns `true` then (`StopReason.originalWouldAbort` is the caller's)
    /// and finishes the pass. Never reached in the modelled licence state (`gPointsNotReg` false).
    @discardableResult
    public mutating func drawPass(rng: inout GameRandom) -> Bool {
        if activeCount == 0 { return false }
        var wouldAbort = false
        for i in slots.indices where slots[i].active {
            if slots[i].trap {
                if rng.fast(0, 0x14) == 1 { wouldAbort = true }
            }
            if slots[i].dead {
                resetPoint(i)
            }
        }
        return wouldAbort
    }
}
