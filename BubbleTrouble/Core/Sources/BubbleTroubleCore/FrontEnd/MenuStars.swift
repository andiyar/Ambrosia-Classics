// The main menu's mouse-trail stars (plan 2026-10-04 btx-playable C6; FI §1b), transcribed from `_ResetMenuStars
// @ 000106df` and `_ProcessMenuStars @ 0001075d`. 30 slots of 12 bytes (`gMenuStars`: frame, h, v, pad, time),
// a ring index `gNextMenuStar`, `gLastMenuStarTime` and `gLastMenuStarPoint` (mouse − 13, 13 = half of 26).

/// `gMenuStars` and its bookkeeping.
public struct MenuStars: Equatable, Sendable {
    public struct Star: Equatable, Sendable {
        /// 0 = free; 1…6 = the sprite frame (6 is drawn as nothing: the erase frame).
        public var frame: Int
        public var h: Int
        public var v: Int
        public var time: UInt32
    }

    public static let slotCount = 0x1e
    /// Sprite set 0x28 — 26 × 26 stars.
    public static let spriteSet = 0x28
    public static let size = 0x1a

    public private(set) var stars = [Star](repeating: Star(frame: 0, h: 0, v: 0, time: 0), count: slotCount)
    public private(set) var next = 0
    public private(set) var lastTime: UInt32 = 0
    public private(set) var lastPoint = (h: 0, v: 0)

    public init() {}

    public static func == (a: MenuStars, b: MenuStars) -> Bool {
        a.stars == b.stars && a.next == b.next && a.lastTime == b.lastTime && a.lastPoint == b.lastPoint
    }

    /// `_ResetMenuStars`: every slot cleared, ring index 0, `gLastMenuStarTime = TickCount`, last point = mouse − 13.
    public mutating func reset(now: UInt32, mouse: MousePoint) {
        for i in stars.indices { stars[i] = Star(frame: 0, h: 0, v: 0, time: 0) }
        next = 0
        lastTime = now
        lastPoint = (mouse.h - 13, mouse.v - 13)
    }

    /// One `_ProcessMenuStars` call: maybe spawn (two `GetRandomFast(0, 0x14)` draws on the process stream), then
    /// the draw ops (erase comp → bgnd, plot into bgnd, bgnd → screen), then the per-star frame advance.
    public mutating func process(now: UInt32, mouse: MousePoint, random: inout GameRandom) -> [DrawOp] {
        // Spawn: more than 1 tick since the last spawn and the mouse (− 13) has moved.
        if 1 < now &- lastTime {
            let h = mouse.h - 13, v = mouse.v - 13
            if h != lastPoint.h || v != lastPoint.v {
                let dh = random.fast(0, 0x14)
                let dv = random.fast(0, 0x14)
                let sh = Int(Int16(truncatingIfNeeded: dh - 10 + h))
                let sv = Int(Int16(truncatingIfNeeded: dv - 10 + v))
                let ch = sh < 0x267 ? max(0, sh) : 0x266
                let cv = sv < 0x1c7 ? max(0, sv) : 0x1c6
                stars[next] = Star(frame: 1, h: ch, v: cv, time: now)
                next = next + 1 < Self.slotCount ? next + 1 : 0
                lastTime = now
                lastPoint = (mouse.h - 13, mouse.v - 13)
            }
        }
        var ops: [DrawOp] = []
        for s in stars where s.frame != 0 {
            ops.append(.compToBgnd(Self.rect(s)))
        }
        for s in stars where s.frame != 0 && s.frame != 6 {
            ops.append(.spriteToBgnd(set: Self.spriteSet, frame: s.frame, h: s.h, v: s.v))
        }
        for s in stars where s.frame != 0 {
            ops.append(.restoreBgnd(Self.rect(s), target: .screen))   // `_BgndToScreen @ 0001525d`
        }
        // Frame advance: more than 3 ticks on this frame → next frame; past 6 → free.
        for i in stars.indices where stars[i].frame != 0 && 3 < now &- stars[i].time {
            stars[i].frame += 1
            stars[i].time = now
            if 6 < stars[i].frame { stars[i].frame = 0 }
        }
        return ops
    }

    static func rect(_ s: Star) -> QDRect {
        QDRect(top: Int16(s.v), left: Int16(s.h), bottom: Int16(s.v + size), right: Int16(s.h + size))
    }
}
