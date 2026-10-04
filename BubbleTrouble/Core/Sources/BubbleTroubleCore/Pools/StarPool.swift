/// One star slot (0x38 bytes at `_star`, 60 slots at 0x38640). Field comments give the original offsets.
///
/// Like the original, a slot is never wiped: `_InitStars` clears only the active byte and `_NewStar` overwrites
/// the fields it sets, so stale values survive in fields a path does not touch (Invariant 18 — replicated).
public struct Star: Equatable, Sendable {
    public var active = false                 // +0x00
    public var startFrame: UInt16 = 0         // +0x02 (frame counter at creation)
    public var kind: Int16 = 0                // +0x04 (1–7)
    public var motion: Int16 = 0              // +0x06 (0 still, 2 orbit, 3–10 fixed vectors, 0xb hop)
    public var rect = QDRect(top: 0, left: 0, bottom: 0, right: 0)        // +0x08
    public var prevRect = QDRect(top: 0, left: 0, bottom: 0, right: 0)    // +0x10
    public var width: Int16 = 0               // +0x18
    public var height: Int16 = 0              // +0x1a
    public var spriteSet: Int16 = 0           // +0x1c (0x28–0x2c)
    public var frame: Int16 = 0               // +0x1e (animation frame, 1…; > 5 → dead)
    public var animCounter: UInt16 = 0        // +0x20
    public var delay: Int16 = 0               // +0x22
    public var delayed = false                // +0x24
    public var visible = false                // +0x25
    public var dead = false                   // +0x26
    public var dx: Int16 = 0                  // +0x28
    public var dy: Int16 = 0                  // +0x2a
    public var period: Int16 = 0              // +0x2c
    public var orbitIndex: Int16 = 0          // +0x2e (motion 2 only)
    public var orbitOrigin = QDRect(top: 0, left: 0, bottom: 0, right: 0) // +0x30 (motion 2 only)

    public init() {}
}

/// The star pool: `_InitStars`, `_NewStar`, `_NewStarGroup`, `_ProcessStars` and the freeing half of
/// `_DrawStarsToComp`, transcribed from the decompile (Research notes 46–47). Self-contained: everything it reads
/// from the world (frame counter, hero rect, prefs, RNG) comes in as parameters.
///
/// Slots are scanned from 0, allocation takes the first free slot, and slots are freed only by `drawPassFree`
/// (Invariant 8). `_NewStar` clips before its motion-0xb draw (Invariant 6).
public struct StarPool: Sendable {
    public static let capacity = 60
    /// `gStarsLocationLookup` length (0x2a bytes / 2).
    static let locationLookupCount = 21

    public internal(set) var slots: [Star]
    /// `gNumActiveStars`.
    public internal(set) var activeCount: Int
    /// `gStarsLocationLookup` (21 shorts in −8…8), read by the speed-up groups 6–9.
    public internal(set) var locationLookup: [Int16]
    /// `gStarsLocationIndex` (wraps at 21).
    public internal(set) var locationIndex: Int

    public init() {
        slots = Array(repeating: Star(), count: Self.capacity)
        activeCount = 0
        locationLookup = Array(repeating: 0, count: Self.locationLookupCount)
        locationIndex = 0
    }

    /// `_InitStars @ 00004db8`: clear every active byte, `gNumActiveStars = 0`, then
    /// `_CreateStarRandomLocLookupTable @ 0000323e`: index 0; 21 × { v = (0,8); if (0,1) != 0 { v = −v } } — 42 draws.
    public mutating func reset(rng: inout GameRandom) {
        for i in slots.indices { slots[i].active = false }
        activeCount = 0
        locationIndex = 0
        for i in 0..<Self.locationLookupCount {
            var v = Int16(truncatingIfNeeded: rng.fast(0, 8))
            if rng.fast(0, 1) != 0 { v = 0 &- v }
            locationLookup[i] = v
        }
    }

    /// `_NewStar(x, y, kind, delay, motion, orbitIndex) @ 0000329a`, in the original's order:
    /// 60-cap → first free slot (none → return) → claim (active, start frame, frame 1, counter 0, kind) → size by
    /// kind (an unknown kind returns with the slot claimed but not counted — replicated) → rect + prevRect →
    /// **playfield clip** (`left < 0 || 640 < right || top < 0 || 440 < bottom` → free, return; no draw, not
    /// counted) → motion setup (0xb: dy −10, period 7, dx = `(0,1) == 0 ? −5 : 5`; 2: orbit origin/index, dy 0,
    /// period 4, dx 0; else dy 0, period 2, dx 0) → dead 0, delay, delayed/visible → `gNumActiveStars++`.
    public mutating func newStar(x: Int16, y: Int16, kind: Int16, delay: Int16, motion: Int16,
                                 orbitIndex: Int16, frame: UInt16, rng: inout GameRandom) {
        if activeCount == Self.capacity { return }
        guard let i = slots.firstIndex(where: { !$0.active }) else { return }
        var left = x, top = y
        slots[i].active = true
        slots[i].startFrame = frame
        slots[i].frame = 1
        slots[i].animCounter = 0
        slots[i].kind = kind
        switch kind {
        case 1, 2, 3:
            slots[i].width = 0x1a; slots[i].height = 0x1a; slots[i].spriteSet = 0x28
        case 4:
            slots[i].width = 0x1a; slots[i].height = 0x1a; slots[i].spriteSet = 0x29
        case 5:
            slots[i].width = 0x1a; slots[i].height = 0x1a; slots[i].spriteSet = 0x2a
        case 6:
            slots[i].width = 0x1a; slots[i].height = 0x1a; slots[i].spriteSet = 0x2b
        case 7:
            left = x &+ 1
            top = y &+ 1
            slots[i].width = 0x26; slots[i].height = 0x26; slots[i].spriteSet = 0x2c
        default:
            return      // slot stays claimed, gNumActiveStars not incremented (decompile `default: return;`)
        }
        let rect = QDRect(top: top, left: left,
                          bottom: top &+ slots[i].height, right: left &+ slots[i].width)
        slots[i].rect = rect
        slots[i].prevRect = rect
        if rect.left < 0 || 0x280 < rect.right || rect.top < 0 || 0x1b8 < rect.bottom {
            slots[i].active = false     // Invariant 6: freed before any draw; never counted
            return
        }
        slots[i].motion = motion
        if motion == 2 {
            slots[i].orbitOrigin = rect
            slots[i].orbitIndex = orbitIndex
            slots[i].dy = 0
            slots[i].period = 4
            slots[i].dx = 0
        } else if motion == 0xb {
            slots[i].dy = -10
            slots[i].period = 7
            slots[i].dx = rng.fast(0, 1) == 0 ? -5 : 5
        } else {
            slots[i].dy = 0
            slots[i].period = 2
            slots[i].dx = 0
        }
        slots[i].dead = false
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

    /// `_NewStarGroup(x, y, group) @ 000035b5`. Pref 0x35 off → return for every group but 0xf / 0x10.
    /// Each row is one `_NewStar(x + dx, y + dy, kind, delay, motion, −1)` in call order; the last row of each
    /// group is the shared tail call at `LAB_00004af8`. Group 10 (orbit burst, pause cheat `SPIN 1`) is deferred
    /// to the BTX play-loop plan; groups ≥ 0x11 do nothing.
    public mutating func newGroup(x: Int16, y: Int16, group: Int, hero: HeroAnchor, frame: UInt16,
                                  prefs: CosmeticPrefs, rng: inout GameRandom) {
        if group != 0xf && group != 0x10 && !prefs.stars { return }
        func star(_ sx: Int16, _ sy: Int16, _ kind: Int16, _ delay: Int16, _ motion: Int16) {
            newStar(x: sx, y: sy, kind: kind, delay: delay, motion: motion, orbitIndex: -1, frame: frame, rng: &rng)
        }
        func at(_ ox: Int16, _ oy: Int16, _ kind: Int16, _ delay: Int16, _ motion: Int16) {
            star(x &+ ox, y &+ oy, kind, delay, motion)
        }
        switch group {
        case 0:     // hero appear / jewel join: 8 still stars, staggered delays
            at(-8, -8, 2, 0, 0); at(-20, -3, 2, 2, 0); at(6, 6, 2, 6, 0); at(2, 22, 2, 12, 0)
            at(28, 16, 2, 2, 0); at(32, -8, 2, 9, 0); at(26, 28, 2, 6, 0)
            at(9, 9, 2, 18, 0)
        case 1:     // no callers (C3)
            at(-8, -8, 2, 0, 0)
            at(6, 6, 2, 3, 0)
        case 2:     // bonus / jewel bonus / last bubble: 8 stars from (x+6, y+6), motions 3…10
            for motion in Int16(3)...10 { at(6, 6, 2, 0, motion) }
        case 3, 4, 5:   // squish / egg kill: kinds 4 / 5 / 6
            let kind = Int16(group + 1)
            at(-8, -8, kind, 0, 0xb); at(6, 6, kind, 3, 0xb); at(-16, 20, kind, 0, 0xb)
            at(6, 20, kind, 3, 0xb)
        case 6, 7, 8, 9:    // speed-up (dead path): one still star beside the hero, jittered by the lookup
            let top = hero.rect.top, left = hero.rect.left
            let jitter = locationLookup[locationIndex]
            locationIndex = locationIndex + 1 == Self.locationLookupCount ? 0 : locationIndex + 1
            switch group {
            case 6: star(left &+ 6 &+ jitter, top &+ 0x1a, 2, 0, 0)
            case 7: star(left &+ 6 &+ jitter, top &- 0xd, 2, 0, 0)
            case 8: star(left &+ 0x1e, top &+ 6 &+ jitter, 2, 0, 0)
            default: star(left &- 0x11, top &+ 6 &+ jitter, 2, 0, 0)
            }
        case 10:
            preconditionFailure("_NewStarGroup group 10 (orbit burst, pause cheat SPIN 1) is deferred to the BTX play-loop plan")
        case 0xb, 0xc, 0xd:     // no callers (C3): kinds 4 / 5 / 6
            let kind = Int16(group - 7)
            at(-8, -8, kind, 0, 0xb); at(6, 6, kind, 3, 0xb); at(-16, 20, kind, 0, 0xb); at(6, 20, kind, 3, 0xb)
            at(2, 14, kind, 4, 0xb)
        case 0xe:   // hero squash: 13 explicit + the tail = 14 hop stars (C2)
            at(-8, -8, 2, 0, 0xb); at(6, 6, 2, 3, 0xb); at(-16, 20, 2, 0, 0xb); at(6, 20, 2, 3, 0xb)
            at(2, 14, 2, 4, 0xb); at(0, 0, 2, 4, 0xb); at(10, -2, 2, 4, 0xb)
            at(-8, -8, 2, 2, 0xb); at(6, 6, 2, 5, 0xb); at(-16, 20, 2, 6, 0xb); at(6, 20, 2, 4, 0xb)
            at(2, 14, 2, 7, 0xb); at(0, 0, 2, 8, 0xb)
            at(10, -2, 2, 8, 0xb)
        case 0xf:   // small blast: 3×3 kind-7 grid at ±40, centre undelayed
            at(-40, -40, 7, 2, 0); at(0, -40, 7, 2, 0); at(40, -40, 7, 2, 0)
            at(-40, 0, 7, 2, 0); at(0, 0, 7, 0, 0); at(40, 0, 7, 2, 0)
            at(-40, 40, 7, 2, 0); at(0, 40, 7, 2, 0)
            at(40, 40, 7, 2, 0)
        case 0x10:  // big blast: 5×5 kind-7 grid at ±80 minus the corners
            at(-40, -80, 7, 7, 0); at(0, -80, 7, 7, 0); at(40, -80, 7, 7, 0)
            at(-80, -40, 7, 7, 0); at(-40, -40, 7, 3, 0); at(0, -40, 7, 3, 0); at(40, -40, 7, 3, 0); at(80, -40, 7, 7, 0)
            at(-80, 0, 7, 7, 0); at(-40, 0, 7, 3, 0); at(0, 0, 7, 0, 0); at(40, 0, 7, 3, 0); at(80, 0, 7, 7, 0)
            at(-80, 40, 7, 7, 0); at(-40, 40, 7, 3, 0); at(0, 40, 7, 3, 0); at(40, 40, 7, 3, 0); at(80, 40, 7, 7, 0)
            at(-40, 80, 7, 7, 0); at(0, 80, 7, 7, 0)
            at(40, 80, 7, 7, 0)
        default:
            return
        }
    }

    /// `_ProcessStars @ 00004b05`. Skipped entirely when `gNumActiveStars == 0`. Per active slot 0…59: a delayed
    /// star waits until `start + delay < frame` (then becomes visible; no animation step that call); motion 3–10
    /// offsets by a fixed (dh, dv); motion 0xb: dy += 1 clamped to ±18, offset by (dx, dy), then the four edge
    /// tests (bounce, or dead when beyond one star size); then `counter += 1`, and `period < counter` → counter 0,
    /// frame += 1, frame > 5 → dead. Dead stars keep being processed until the draw pass frees them.
    public mutating func process(frame: UInt16) {
        if activeCount == 0 { return }
        for i in slots.indices where slots[i].active {
            if slots[i].delayed {
                if Int(slots[i].delay) + Int(slots[i].startFrame) < Int(frame) {
                    slots[i].delayed = false
                    slots[i].visible = true
                }
                continue
            }
            switch slots[i].motion {
            case 2:
                preconditionFailure("_ProcessStars motion 2 (orbit, gOrbit_Table) is deferred to the BTX play-loop plan")
            case 3: slots[i].rect.offset(dx: 0, dy: -4)
            case 4: slots[i].rect.offset(dx: 3, dy: -3)
            case 5: slots[i].rect.offset(dx: 4, dy: 0)
            case 6: slots[i].rect.offset(dx: 3, dy: 3)
            case 7: slots[i].rect.offset(dx: 0, dy: 4)
            case 8: slots[i].rect.offset(dx: -3, dy: 3)
            case 9: slots[i].rect.offset(dx: -4, dy: 0)
            case 10: slots[i].rect.offset(dx: -3, dy: -3)
            case 0xb:
                var s = slots[i]
                s.dy = s.dy &+ 1
                if s.dy < -0x12 { s.dy = -0x12 } else if 0x12 < s.dy { s.dy = 0x12 }
                s.rect.offset(dx: s.dx, dy: s.dy)
                if s.rect.left < 0 {
                    if -Int(s.width) < Int(s.rect.left) { s.dx = 0 &- s.dx } else { s.visible = false; s.dead = true }
                }
                if s.rect.top < 0 {
                    if -Int(s.height) < Int(s.rect.top) { s.dy = 0 &- s.dy } else { s.visible = false; s.dead = true }
                }
                if 0x27f < s.rect.right {
                    if Int(s.width) + 0x280 < Int(s.rect.right) { s.visible = false; s.dead = true } else { s.dx = 0 &- s.dx }
                }
                if 0x1b7 < s.rect.bottom {
                    if Int(s.height) + 0x1b8 < Int(s.rect.bottom) { s.visible = false; s.dead = true } else { s.dy = 0 &- s.dy }
                }
                slots[i] = s
            default:
                break
            }
            slots[i].animCounter = slots[i].animCounter &+ 1
            if Int(slots[i].period) < Int(slots[i].animCounter) {
                slots[i].animCounter = 0
                slots[i].frame = slots[i].frame &+ 1
                if 5 < slots[i].frame {
                    slots[i].dead = true
                    slots[i].visible = false
                }
            }
        }
    }

    /// The freeing half of `_DrawStarsToComp @ 00004de0` (its plots are recorded by `GameState.runDrawPass`, C3): skipped when
    /// `gNumActiveStars == 0`; per active slot 0…59, a live star copies rect → prevRect, a dead one is freed and
    /// `gNumActiveStars -= 1`.
    public mutating func drawPassFree() {
        if activeCount == 0 { return }
        for i in slots.indices where slots[i].active {
            if slots[i].dead {
                slots[i].active = false
                activeCount -= 1
            } else {
                slots[i].prevRect = slots[i].rect
            }
        }
    }
}
