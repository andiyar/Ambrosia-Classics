import Foundation
import DeimosCore

/// The blocking screen fades, broken into steps the host drives (plan S4: `fadeBegin`, `fadeStep`, `fadeEnd`).
/// The original loops inside one call and spins on `TickCount` between steps; the replica hands each step to the
/// host, which owns the clock: `t0 = TickCount` before the first step; after each step's present, wait until
/// `TickCount ≥ t0 + 1`, then `t0 = TickCount` (`1000bac4`, `1000bb50…1000bb78`).
///
/// R1 carries the fade FROM black (`FUN_1000ba70`, listing `1000ba70…1000bbc0`, loose-ends-session §6, HIGH).
/// The fade TO black (`FUN_1000b9a0`, 33 steps a = 32 … 0, in place by the `FUN_1001ec80` kernel) is R2's
/// (`FadeToBlack.swift`).
extension DisplayBuffers {
    /// The from-black levels: `a = 0, 4, …, 32` (`1000bad4 li r25,0` … `1000bb70 addi r25,r25,4; cmpwi r25,0x20; ble`),
    /// 9 steps; each a is clamped to 0…32 (`1000bad8…1000baf4`, a no-op on these values).
    public static let fromBlackLevels: [Int] = Array(stride(from: 0, through: 32, by: 4))

    /// Start a fade. From black: clone the back buffer (the snapshot, `FUN_10009ac0` at `1000ba90`) and make a second
    /// clone filled with colour 0 (`1000baa4`, `FUN_10009f00` at `1000babc`, colour words `*(r2−0x732c)` = 0).
    public mutating func fadeBegin(_ kind: FadeKind) {
        switch kind {
        case .fromBlack:
            fadeSnapshot = back
            var black = back
            black.fill(0)
            fadeBlack = black
        case .toBlack:
            fatalError("FadeKind.toBlack (FUN_1000b9a0) lands with R2")   // R2 replaces this line (FadeToBlack.swift)
        }
    }

    /// One step at level `a`, then the present the fade was called with (`mode` 0 → `FUN_1000bc60` full screen,
    /// 1 → `FUN_1000bd80` game layout; `1000bb2c…1000bb48`). From black: `back = blend(snapshot, black, a)` over the
    /// back buffer's bounds (`FUN_1001e9d0(snapshot, black, back, &back.bounds, a)` at `1000bb18`) — A = snapshot
    /// weighted by a, so a = 0 is black and a = 32 is the snapshot.
    public mutating func fadeStep(_ kind: FadeKind, a: Int, present kind2: PresentKind) {
        switch kind {
        case .fromBlack:
            guard let snapshot = fadeSnapshot, let black = fadeBlack else {
                preconditionFailure("fadeStep(.fromBlack) without fadeBegin(.fromBlack)")
            }
            let level = min(max(a, 0), 32)
            Blend555.blend(snapshot, black, into: &back, rect: back.bounds, a: level)
        case .toBlack:
            fatalError("FadeKind.toBlack (FUN_1000b9a0) lands with R2")   // R2 replaces this line (FadeToBlack.swift)
        }
        present(kind2)
    }

    /// End the fade: free both clones (`FUN_10009a60(…,1)` ×2, `1000bb80…1000bbac`).
    public mutating func fadeEnd() {
        fadeSnapshot = nil
        fadeBlack = nil
    }
}
