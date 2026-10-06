import Foundation
import DeimosCore

/// The 16 per-layer render lists of U_Sprite.cc (blit-pixel-rules §7.1, sprite-geometry-draw §6; HIGH, listing).
///
/// - Storage: a command array per layer (`r2−0x719c`) and a count per layer (`r2−0x7198`). The arrays are kept
///   and reused; only the counts are reset.
/// - `FUN_1001a450 @ 1001a450(cmd)` — append: index = `cmd+0x30` (the layer byte, `1001a46c…1001a470`); when
///   `(count + 1)·0x4c` exceeds the array, it doubles (`1001a490…1001a568`, "Sprite Render List expanded"); the
///   0x4c bytes are copied (`1001a56c…1001a624`) and the copy's `+0x31` set to 1 (`1001a628`), then count + 1
///   (`1001a62c…1001a634`).
/// - `FUN_1001a650 @ 1001a650(L)` — flush: for i in 0..<count[L] (`1001a66c…1001a6d8`): skip face `none`
///   (`1001a690…1001a69c`) and any entry whose layer byte ≠ L (`1001a6a0…1001a6a8`); draw it with `FUN_10019570`
///   (`1001a6b0`); then, when its layer is 0 or 1, its face becomes `none` (`1001a6b4…1001a6c8`). The flush never
///   resets the count.
/// - `FUN_100189f0 @ 100189f0` — clear: zero all 16 counts (`100189f0…10018a38`).
public struct RenderLists: Sendable {
    public static let layerCount = 16

    private var lists: [[DrawCommand]] = Array(repeating: [], count: RenderLists.layerCount)
    private var counts: [Int] = Array(repeating: 0, count: RenderLists.layerCount)

    public init() {}

    /// `FUN_1001a450`. The caller (the dispatcher) has already refused face `none` and alpha 32.
    public mutating func append(_ cmd: DrawCommand) {
        let l = Int(cmd.layer)                              // the layer byte (UInt8)
        precondition(l < Self.layerCount, "RenderLists: layer \(l) ≥ 16")   // the original indexes past the arrays
        var c = cmd
        c.drawNow = true                                    // 1001a628
        let n = counts[l]
        if n < lists[l].count { lists[l][n] = c } else { lists[l].append(c) }
        counts[l] = n + 1                                   // 1001a62c…1001a634
    }

    /// `FUN_1001a650(layer)`: hands each live entry to `draw` in insertion order, consuming layers 0 and 1.
    public mutating func flush(layer: Int, draw: (DrawCommand) -> Void) {
        guard (0..<Self.layerCount).contains(layer) else { return }
        for i in 0..<counts[layer] {
            let c = lists[layer][i]
            if c.face == .none || Int(c.layer) != layer { continue }   // 1001a690…1001a6a8
            draw(c)                                                    // 1001a6b0 FUN_10019570
            if c.layer == 0 || c.layer == 1 { lists[layer][i].face = .none }   // 1001a6b4…1001a6c8
        }
    }

    /// `FUN_100189f0`.
    public mutating func clear() {
        for l in 0..<Self.layerCount { counts[l] = 0 }
    }

    /// The live count of `layer`; 0 outside 0…15 (as `flush` ignores such a layer).
    public func count(layer: Int) -> Int {
        (0..<Self.layerCount).contains(layer) ? counts[layer] : 0
    }

    /// The live entries of `layer`, in insertion order; none outside 0…15 (as `flush` ignores such a layer).
    public func commands(layer: Int) -> [DrawCommand] {
        (0..<Self.layerCount).contains(layer) ? Array(lists[layer].prefix(counts[layer])) : []
    }
}
