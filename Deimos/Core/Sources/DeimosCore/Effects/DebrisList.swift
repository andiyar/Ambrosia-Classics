import Foundation

/// G_Debris.cc — the ground-obstacle rectangles (particles-debris-blur §3, HIGH). Invisible int rects
/// `{top, left, bottom, right}` (16 bytes) in the list `0x100e01cc`; they ride the terrain scroll, are never removed
/// before the level reset, and stop ground units. No RNG anywhere in the module.
public struct DebrisList: Equatable, Sendable {
    /// The list, in append order.
    public private(set) var rects: [MacRect] = []

    public init() {}

    /// `FUN_1002a6d0 @ 1002a6d0` — append a copy of the rect (`1002a718..1002a744`).
    public mutating func add(_ rect: MacRect) {
        rects.append(rect)
    }

    /// `FUN_1002a770 @ 1002a770` — per tick (world update `10006bd8`): `top += d; bottom += d` with
    /// d = `FUN_1000fed0()`, the pixels scrolled this tick (`1002a7e4..1002a7fc`, `add` wraps).
    public mutating func update(scrollDelta d: Int32) {
        for i in rects.indices {
            rects[i].top = rects[i].top &+ d
            rects[i].bottom = rects[i].bottom &+ d
        }
    }

    /// `FUN_1002a830 @ 1002a830` — 1 if `e` touches any obstacle, inclusive on all four sides, signed
    /// (`1002a8a4..1002a8e4`): `e.bottom ≥ d.top && e.top ≤ d.bottom && e.right ≥ d.left && e.left ≤ d.right`.
    public func hits(_ e: MacRect) -> Bool {
        rects.contains { d in
            e.bottom >= d.top && e.top <= d.bottom && e.right >= d.left && e.left <= d.right
        }
    }

    /// `FUN_1002a920` — the count (the NUMDEBRIS readout).
    public var count: Int { rects.count }

    /// `FUN_1002a660` — per-level reset: free all.
    public mutating func levelReset() {
        rects = []
    }
}
