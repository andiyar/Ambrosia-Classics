/// One air-bubble slot (0x26 bytes at `_gBubbles`, 8 slots at 0x34d40). Field comments give the original offsets.
///
/// Like the original, a slot is never wiped: `_Bubbles_Init` clears only the active byte and `_Bubbles_New`
/// overwrites the fields it sets (Invariant 18 — replicated).
public struct AirBubble: Equatable, Sendable {
    public var active = false                 // +0x00
    public var startFrame: UInt16 = 0         // +0x02 (frame counter at creation; the delay clock)
    public var animTimer: UInt16 = 0          // +0x04 (frame of the last animation step)
    public var animPeriod: Int16 = 0          // +0x06 (GetRandomFast(5,9))
    public var size: Int8 = 0                 // +0x08 (0–3)
    public var rect = QDRect(top: 0, left: 0, bottom: 0, right: 0)        // +0x0a
    public var prevRect = QDRect(top: 0, left: 0, bottom: 0, right: 0)    // +0x12
    public var snakeIndex: Int8 = 0           // +0x1a (into `_gBubbles_SnakingTable`, wraps at 19)
    public var riseSpeed: Int8 = 0            // +0x1b
    public var spriteSet: Int16 = 0           // +0x1c (0x2d–0x30)
    public var frame: Int16 = 0               // +0x1e (animation frame 1…3)
    public var visible = false                // +0x20
    public var dead = false                   // +0x21
    public var delayed = false                // +0x22
    public var delay: Int16 = 0               // +0x24

    public init() {}
}

/// The air-bubble pool: `_Bubbles_Init` (+ `_Bubbles_CreateRandomLUT`), `_Bubbles`, `_Bubbles_NewGroup`,
/// `_Bubbles_New`, `_Bubbles_Process` and the freeing half of `_Bubbles_DrawToComp`, transcribed from the
/// decompile (Research notes 15 and 48). Self-contained: frame counter, hero record, prefs and RNG come in as
/// parameters. Sounds (`_PlayMySnd` at the end of groups 4–0xb) are the shell's.
///
/// Slots are scanned from 0, allocation takes the first free slot, and slots are freed only by `drawPassFree`
/// (Invariant 8). `_Bubbles_New` returns before its `(5,9)` draw when 8 bubbles are alive.
public struct AirBubblePool: Sendable {
    public static let capacity = 8
    /// Table lengths from the symbol layout (`nm -n`): x 0x34e80–0x34ec2 (33 shorts), drift 0x34ec2–0x34ed7
    /// (21 bytes), vertical 0x34ed7–0x34eec (21 bytes), delay 0x34eec–0x34f06 (13 shorts), groups
    /// 0x34f06–0x34f1b (21 bytes).
    static let xLocCount = 33
    static let driftCount = 21
    static let verticalCount = 21
    static let delayCount = 13
    static let groupCount = 21
    /// `_gBubbles_SnakingTable` (19 × i8 at `__data` 0x3414a: `01 01 01 01 00 ff ×8 00 01 01 01 01 00`).
    static let snakingTable: [Int8] = [1, 1, 1, 1, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 1, 1, 1, 1, 0]

    public internal(set) var slots: [AirBubble]
    /// `_gBubbles_NumActive`.
    public internal(set) var activeCount: Int
    /// `_gBubbles_RandXLocTable` (33 × `(0x28,0x1e0)`).
    public internal(set) var xLoc: [Int16]
    /// `_gBubbles_RandDriftTable` (21 × `(0,4)`: 0 none, 1 −1, 2 −2, 3 +1, 4 +2).
    public internal(set) var drift: [Int8]
    /// `_gBubbles_RandVerticalTable` (21 × `(2,5)`, clamped per size by `_Bubbles_New`).
    public internal(set) var vertical: [Int8]
    /// `_gBubbles_RandDelayTable` (13 × `(0x19,0x5a)`).
    public internal(set) var delayTable: [Int16]
    /// `_gBubbles_RandGroupsTable` (21 × `(0,0xe)` mapped to groups 0–8).
    public internal(set) var groups: [Int8]
    public internal(set) var xIndex: Int
    public internal(set) var driftIndex: Int
    public internal(set) var verticalIndex: Int
    public internal(set) var delayIndex: Int
    public internal(set) var groupIndex: Int
    /// `_gBubbles_TimeLastGroupLaunched`.
    public internal(set) var timeLastGroupLaunched: UInt16
    /// `_gBubbles_DelayTilNextGroup`.
    public internal(set) var delayTilNextGroup: Int16

    public init() {
        slots = Array(repeating: AirBubble(), count: Self.capacity)
        activeCount = 0
        xLoc = Array(repeating: 0, count: Self.xLocCount)
        drift = Array(repeating: 0, count: Self.driftCount)
        vertical = Array(repeating: 0, count: Self.verticalCount)
        delayTable = Array(repeating: 0, count: Self.delayCount)
        groups = Array(repeating: 0, count: Self.groupCount)
        xIndex = 0; driftIndex = 0; verticalIndex = 0; delayIndex = 0; groupIndex = 0
        timeLastGroupLaunched = 0
        delayTilNextGroup = 0
    }

    /// `_Bubbles_Init @ 00016cda`: clear every active byte, then `_Bubbles_CreateRandomLUT @ 000161f6` —
    /// 33 × `(0x28,0x1e0)`, 21 × `(0,4)`, 21 × `(2,5)`, 13 × `(0x19,0x5a)`, 21 × `(0,0xe)` = 109 draws, every
    /// index 0 — then `NumActive = 0; TimeLastGroupLaunched = 0; DelayTilNextGroup = 0x1e`.
    public mutating func reset(rng: inout GameRandom) {
        for i in slots.indices { slots[i].active = false }
        for i in 0..<Self.xLocCount { xLoc[i] = Int16(truncatingIfNeeded: rng.fast(0x28, 0x1e0)) }
        xIndex = 0
        for i in 0..<Self.driftCount { drift[i] = Int8(truncatingIfNeeded: rng.fast(0, 4)) }
        driftIndex = 0
        for i in 0..<Self.verticalCount { vertical[i] = Int8(truncatingIfNeeded: rng.fast(2, 5)) }
        verticalIndex = 0
        for i in 0..<Self.delayCount { delayTable[i] = Int16(truncatingIfNeeded: rng.fast(0x19, 0x5a)) }
        delayIndex = 0
        for i in 0..<Self.groupCount {
            let group: Int8
            switch rng.fast(0, 0xe) {
            case 0, 1: group = 0
            case 2, 3: group = 1
            case 4, 5: group = 2
            case 6: group = 3
            case 7, 8: group = 4
            case 0xb: group = 6
            case 0xc, 0xd: group = 7
            case 0xe: group = 8
            default: group = 5      // 9, 10
            }
            groups[i] = group
        }
        groupIndex = 0
        activeCount = 0
        timeLastGroupLaunched = 0
        delayTilNextGroup = 0x1e
    }

    /// `_Bubbles @ 000169e2`, the per-frame launcher. Pref 0x36 off → return. Waits while
    /// `frame <= last + delay`. Then, if the hero is in state 2, aligned and `hero+0x0c + 0x8c < frame`: facing
    /// left → group 9 at (hero.left, hero.top), facing right → group 10 at (hero.right, hero.top), and
    /// `hero+0x0c = frame`; any other facing falls through to the random launch, as does every other case:
    /// group `groups[gIdx]` at (`xLoc[xIdx]`, 0x181), xIdx wrapping after 32 and gIdx after 20. Either way
    /// `last = frame; delay = delayTable[dIdx]` (dIdx wraps after 12).
    public mutating func launch(frame: UInt16, hero: inout HeroAnchor, prefs: CosmeticPrefs, rng: inout GameRandom) {
        if !prefs.airBubbles { return }
        if Int(frame) <= Int(timeLastGroupLaunched) + Int(delayTilNextGroup) { return }
        var mouth: (x: Int16, y: Int16, group: Int)?
        if hero.state == 2 && hero.aligned && Int(hero.lastBubbleFrame) + 0x8c < Int(frame) {
            switch hero.facing {
            case .left: mouth = (hero.rect.left, hero.rect.top, 9)
            case .right: mouth = (hero.rect.right, hero.rect.top, 10)
            default: mouth = nil
            }
        }
        if let mouth {
            newGroup(x: mouth.x, y: mouth.y, group: mouth.group, frame: frame, prefs: prefs, rng: &rng)
            hero.lastBubbleFrame = frame
        } else {
            let xi = xIndex
            xIndex += 1
            if 0x20 < xIndex { xIndex = 0 }
            let gi = groupIndex
            groupIndex = groupIndex + 1 < Self.groupCount ? groupIndex + 1 : 0
            newGroup(x: xLoc[xi], y: 0x181, group: Int(groups[gi]), frame: frame, prefs: prefs, rng: &rng)
        }
        let di = delayIndex
        delayIndex = delayIndex + 1 < Self.delayCount ? delayIndex + 1 : 0
        timeLastGroupLaunched = frame
        delayTilNextGroup = delayTable[di]
    }

    /// `_Bubbles_NewGroup(x, y, group) @ 0001657e`. Pref 0x36 off → return. Each row is one
    /// `_Bubbles_New(x', y', size, delay)` in call order (groups 0–3 → 1 bubble; 4–6 → 2; 7 → 3; 8 → 4;
    /// 9, 10 → 3 with delays 0/2/4; 0xb → 5 with delays 0/2/3/4/6); groups ≥ 0xc do nothing. The group is the
    /// original's byte (`undefined1`) parameter.
    public mutating func newGroup(x: Int16, y: Int16, group: Int, frame: UInt16, prefs: CosmeticPrefs,
                                  rng: inout GameRandom) {
        if !prefs.airBubbles { return }
        func b(_ ox: Int16, _ oy: Int16, _ size: Int8, _ delay: Int16) {
            newBubble(x: x &+ ox, y: y &+ oy, size: size, delay: delay, frame: frame, rng: &rng)
        }
        switch UInt8(truncatingIfNeeded: group) {
        case 0: b(0, 0, 0, 0)
        case 1: b(0, 0, 1, 0)
        case 2: b(0, 0, 2, 0)
        case 3: b(0, 0, 3, 0)
        case 4: b(8, 0, 0, 0); b(0x14, 8, 0, 0)
        case 5: b(0, 0, 0, 0); b(0x14, 8, 2, 0)
        case 6: b(0, 0, 3, 0); b(0x14, 0x10, 2, 0)
        case 7: b(8, 0, 0, 0); b(0x14, 8, 1, 0); b(0x14, 0x29, 0, 0)
        case 8: b(8, 0, 1, 0); b(8, 0x10, 3, 0); b(0x14, 0x29, 1, 0); b(1, 4, 0, 0)
        case 9: b(-8, 0xc, 0, 0); b(-0xc, 10, 1, 2); b(-0x10, 8, 2, 4)        // hero mouth, facing left
        case 10: b(0, 0xc, 0, 0); b(0, 10, 1, 2); b(0, 8, 2, 4)              // hero mouth, facing right
        case 0xb:                                                             // hero death
            b(8, 8, 2, 0); b(10, 10, 1, 2); b(10, 10, 1, 3); b(0xc, 0xc, 0, 4); b(0xc, 0xc, 0, 6)
        default: return
        }
    }

    /// `_Bubbles_New(x, y, size, delay) @ 00016349`, in the original's order: `NumActive == 8` → return
    /// (**before** the draw) → first free slot → claim (active, start = animTimer = frame) → `animPeriod =
    /// GetRandomFast(5,9)` → size, dead 0, visible 1 → sprite set / side by size (0 → 0x2d/18, 1 → 0x2e/23,
    /// 2 → 0x2f/29, 3 → 0x30/43; any other size returns with the slot claimed but not counted — replicated) →
    /// rect (y, x, y + side, x + side) + prevRect → snake index 0 → rise speed `vertical[vIdx]` clamped
    /// (size 0: ≥ 4 → 3; size 1: > 4 → 4; sizes 2/3: ≤ 2 → 3), vIdx wraps after 20 → delay/delayed/visible →
    /// `NumActive++`.
    public mutating func newBubble(x: Int16, y: Int16, size: Int8, delay: Int16, frame: UInt16,
                                   rng: inout GameRandom) {
        if activeCount == Self.capacity { return }
        // No free slot below the cap: the original shows "NewBubble() - Shouldn't have got this far." and quits
        // (`_CleanUp`). Unreachable while every claimed slot is counted (sizes 0–3, which every caller passes).
        guard let i = slots.firstIndex(where: { !$0.active }) else { return }
        slots[i].active = true
        slots[i].startFrame = frame
        slots[i].animTimer = frame
        slots[i].animPeriod = Int16(truncatingIfNeeded: rng.fast(5, 9))
        slots[i].size = size
        slots[i].dead = false
        slots[i].visible = true
        let side: Int16
        switch size {
        case 0: slots[i].spriteSet = 0x2d; side = 0x12
        case 1: slots[i].spriteSet = 0x2e; side = 0x17
        case 2: slots[i].spriteSet = 0x2f; side = 0x1d
        case 3: slots[i].spriteSet = 0x30; side = 0x2b
        default: return     // slot stays claimed, NumActive not incremented (decompile `return;`)
        }
        slots[i].frame = 1
        let rect = QDRect(top: y, left: x, bottom: y &+ side, right: x &+ side)
        slots[i].rect = rect
        slots[i].prevRect = rect
        slots[i].snakeIndex = 0
        var speed = vertical[verticalIndex]
        switch size {
        case 0: if 4 <= speed { speed = 3 }
        case 1: if 4 < speed { speed = 4 }
        default: if speed <= 2 { speed = 3 }      // sizes 2, 3
        }
        slots[i].riseSpeed = speed
        verticalIndex = verticalIndex + 1 < Self.verticalCount ? verticalIndex + 1 : 0
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

    /// `_Bubbles_Process @ 00016b1a`. Skipped entirely when `NumActive == 0`. Per active slot 0…7: a delayed
    /// bubble waits until `delay + start < frame` (then visible) — no movement and **no drift-index advance**
    /// that call or before; otherwise: animation (`animTimer + animPeriod < frame` → animTimer = frame, frame
    /// cycles 1…3), rise (top and bottom −= speed), snaking x (table index wraps after 18), drift x (global
    /// index, wraps after 20; a drift value outside 0–4 returns from the whole pass — never produced by the
    /// table), **dead when bottom < 0** (C7), then the x clamp to 5…635 (width taken as a `char`, as the
    /// original).
    public mutating func process(frame: UInt16) {
        if activeCount == 0 { return }
        for i in slots.indices where slots[i].active {
            var s = slots[i]
            if s.delayed {
                if Int(s.delay) + Int(s.startFrame) < Int(frame) {
                    s.delayed = false
                    s.visible = true
                }
                slots[i] = s
                continue
            }
            if Int(s.animTimer) + Int(s.animPeriod) < Int(frame) {
                s.animTimer = frame
                let next = s.frame &+ 1
                s.frame = next < 4 ? next : 1
            }
            let speed = Int16(s.riseSpeed)
            s.rect.top &-= speed
            s.rect.bottom &-= speed
            let snake = Int16(Self.snakingTable[Int(s.snakeIndex)])
            let nextSnake = s.snakeIndex &+ 1
            s.snakeIndex = nextSnake < 0x13 ? nextSnake : 0
            s.rect.left &+= snake
            s.rect.right &+= snake
            let di = driftIndex
            driftIndex = driftIndex + 1 < Self.driftCount ? driftIndex + 1 : 0
            switch drift[di] {
            case 0: break
            case 1: s.rect.left &-= 1; s.rect.right &-= 1
            case 2: s.rect.left &-= 2; s.rect.right &-= 2
            case 3: s.rect.left &+= 1; s.rect.right &+= 1
            case 4: s.rect.left &+= 2; s.rect.right &+= 2
            default:
                slots[i] = s
                return      // decompile `default: goto switchD_00016c10_default` (function return)
            }
            if s.rect.bottom < 0 { s.dead = true }
            let width = Int16(Int8(truncatingIfNeeded: s.rect.right &- s.rect.left))
            if s.rect.left < 5 {
                s.rect.left = 5
                s.rect.right = width &+ 5
            } else if 0x27b < s.rect.right {
                s.rect.right = 0x27b
                s.rect.left = 0x27b &- width
            }
            slots[i] = s
        }
    }

    /// The freeing half of `_Bubbles_DrawToComp @ 00016d25` (drawing itself is the shell's): skipped when
    /// `NumActive == 0`; per active slot 0…7, a live bubble copies rect → prevRect, a dead one is freed and
    /// `NumActive -= 1`.
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
