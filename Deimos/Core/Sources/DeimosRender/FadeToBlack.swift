import Foundation
import DeimosCore

/// The fade TO black, `FUN_1000b9a0(display, mode)` @ `1000b9a0…1000ba6c` (loose-ends-session §6; listing re-read
/// for R2 — review M2 moved it here from R1). Stepped by the host through `fadeBegin/fadeStep/fadeEnd` (Fades.swift).
///
/// - No set-up: no clone, no snapshot (`1000b9a0…1000b9c8` only reads TickCount and the back buffer `D+0x68`).
/// - `a = 32, 31, …, 0` (`1000b9cc li r27,0x20` … `1000ba50 subic. r27,r27,1; bge`): 33 steps; each a clamped at 0
///   from below (`1000b9d0…1000b9dc`, a no-op on these values).
/// - Each step: `FUN_1001ec80(back, &back.bounds, 0, a)` (`1000b9e0…1000b9fc`; `FUN_1000a560` = &port+0x1c, the
///   bounds) — the back buffer scaled **in place** toward colour 0, so the steps compound:
///   `c ← ⌊c·a/32⌋` per channel on the already-darkened buffer (a = 32 is a no-op, `1001ec8c`); then
///   `FUN_1000c2a0` (make the window current — no pixels), then the present by `mode` (0 `FUN_1000bc60` full screen,
///   1 `FUN_1000bd80` game layout; `1000ba10…1000ba2c`); then spin until TickCount ≥ t0 + 1 (`1000ba34…1000ba44`,
///   the host's clock).
/// - No tear-down.
extension DisplayBuffers {
    /// The to-black levels in step order.
    public static let toBlackLevels: [Int] = Array((0...32).reversed())

    /// `FUN_1000b9a0` holds no state between steps.
    mutating func fadeToBlackBegin() {}

    /// One step's pixel work (the caller presents).
    mutating func fadeToBlackStep(a: Int) {
        let level = max(a, 0)
        CostRect.fill(&back, rect: back.bounds, colour: 0, a: level)
    }
}
