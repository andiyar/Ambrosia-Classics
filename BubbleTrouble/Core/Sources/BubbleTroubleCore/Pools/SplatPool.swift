/// One splat slot (0x1e bytes at `_splat`, 12 slots at 0x34700). Field comments give the original offsets.
///
/// Like the original, a slot is never wiped: `_Splats_Init` clears only the active byte and `_Splats_NewSplat`
/// overwrites the fields it sets (a kind other than 0/1 keeps the stale sprite set — replicated).
public struct Splat: Equatable, Sendable {
    public var active = false                 // +0x00
    public var createdFrame: UInt16 = 0       // +0x02
    public var kind: Int8 = 0                 // +0x04 (0 enemy, 1 hero)
    public var rect = QDRect(top: 0, left: 0, bottom: 0, right: 0)        // +0x06 (40 × 40)
    public var prevRect = QDRect(top: 0, left: 0, bottom: 0, right: 0)    // +0x0e
    public var spriteSet: Int16 = 0           // +0x16 (0x26 enemy, 0x27 hero)
    public var frame: Int16 = 0               // +0x18 (1)
    public var startFrame: UInt16 = 0         // +0x1a (the lifetime clock)
    public var visible = false                // +0x1c
    public var dead = false                   // +0x1d

    public init() {}
}

/// The splat pool: `_Splats_Init`, `_Splats_NewSplat`, `_Splats_Process` and the freeing half of
/// `_Splats_DrawToComp`, transcribed from the decompile (Research note 50). No RNG; no active counter.
///
/// Slots are scanned from 0, allocation takes the first free slot, and slots are freed only by `drawPassFree`
/// (Invariant 8).
public struct SplatPool: Sendable {
    public static let capacity = 12

    public internal(set) var slots: [Splat]

    public init() {
        slots = Array(repeating: Splat(), count: Self.capacity)
    }

    /// `_Splats_Init @ 00002c62`: clear every active byte.
    public mutating func reset() {
        for i in slots.indices { slots[i].active = false }
    }

    /// `_Splats_NewSplat(x, y, kind) @ 00002b11`: first free slot of 12: active, created = start = frame, kind,
    /// dead 0, sprite set 0x26 (kind 0) / 0x27 (kind 1), rect (y, x, y + 40, x + 40) + prevRect, frame 1,
    /// visible. No free slot → the original's `_DebugValues` alert (no quit) and nothing else — a no-op here.
    public mutating func newSplat(x: Int16, y: Int16, kind: Int8, frame: UInt16) {
        guard let i = slots.firstIndex(where: { !$0.active }) else { return }
        slots[i].active = true
        slots[i].createdFrame = frame
        slots[i].kind = kind
        slots[i].dead = false
        if kind == 0 {
            slots[i].spriteSet = 0x26
        } else if kind == 1 {
            slots[i].spriteSet = 0x27
        }
        let rect = QDRect(top: y, left: x, bottom: y &+ 0x28, right: x &+ 0x28)
        slots[i].rect = rect
        slots[i].prevRect = rect
        slots[i].frame = 1
        slots[i].startFrame = frame
        slots[i].visible = true
    }

    /// `_Splats_Process @ 00002c0b`: per active slot 0…11 (no active-count guard), `start + 7 < frame` → dead,
    /// invisible.
    public mutating func process(frame: UInt16) {
        for i in slots.indices where slots[i].active {
            if Int(slots[i].startFrame) + 7 < Int(frame) {
                slots[i].dead = true
                slots[i].visible = false
            }
        }
    }

    /// The freeing half of `_Splats_DrawToComp @ 00002c79` (drawing itself is the shell's): per active slot
    /// 0…11, a live splat copies rect → prevRect, a dead one is freed.
    public mutating func drawPassFree() {
        for i in slots.indices where slots[i].active {
            if slots[i].dead {
                slots[i].active = false
            } else {
                slots[i].prevRect = slots[i].rect
            }
        }
    }
}
