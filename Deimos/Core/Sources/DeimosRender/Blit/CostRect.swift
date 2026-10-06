import Foundation
import DeimosCore

/// `FUN_1001ec80(port, rect*, colour, a)` @ `1001ec80…1001ee9c` (U_SpriteBlit.cc) — the draw type `COST` and the
/// fade to black: scale a rect of the port in place toward a colour. Read from the listing for R2 (the bank had
/// usage only: hud-scorebar §5, loose-ends-session §6, MED).
///
/// - `a == 32` → return at once (`1001ec8c cmplwi r29,0x20; beq`).
/// - Bounds = the port's bounds rect (`FUN_1000a530`, `1001ecac`) — NOT the command clip (the dispatcher uses the
///   clip only to reject the whole rect, `10019754…100197a8`).
/// - Reject (`1001ecb4…1001ecf0`): `rect.left > b.right || rect.right < b.left || rect.top > b.bottom ||
///   rect.bottom < b.top` → return.
/// - Clamp a copy (`1001ecf4…1001ed3c`): left ↑ b.left, right ↓ b.right, top ↑ b.top, bottom ↓ b.bottom;
///   w = right − left, h = bottom − top; w ≤ 0 or h ≤ 0 → return (`1001ed4c…1001ed60`).
/// - ⚑ The start address uses the **unclamped** rect: `dst = base + rect.top·rowBytes + 2·rect.left`
///   (`1001ed78 lwz r4,0x0(r27)`, `1001ed88 lwz r3,0x4(r27)`, `1001ed8c…1001ed9c`) with the clamped w × h, and
///   after each row `dst += rowBytes − 2w` (`1001eda0`, `1001ee7c`). For a rect inside the bounds (every shipped
///   caller seen) this is the clamped rect; a rect starting left of / above the port lands earlier in linear
///   memory. The replica walks the same linear addresses (rowBytes = 2·width) and drops any outside the buffer.
/// - Kernel per pixel (`1001edc4…1001edf8`, 2-unrolled + tail `1001ee40…1001ee70`): the packed-RGB555 blend with
///   the destination weighted `a` and the colour `32 − a`: `out_c = ⌊(dst_c·a + col_c·(32 − a))/32⌋`
///   (= `Blend555.blend(dst, colour, a)`; bit 15 cleared).
enum CostRect {
    static func fill(_ port: inout Pixmap555, rect: MacRect, colour: UInt16, a: Int) {
        if a == 32 { return }
        let b = port.bounds
        if rect.left > b.right || rect.right < b.left || rect.top > b.bottom || rect.bottom < b.top { return }
        let left = max(rect.left, b.left), right = min(rect.right, b.right)
        let top = max(rect.top, b.top), bottom = min(rect.bottom, b.bottom)
        let w = Int(right) - Int(left), h = Int(bottom) - Int(top)
        guard w > 0, h > 0 else { return }
        let stride = port.width
        var start = Int(rect.top) * stride + Int(rect.left)
        let count = port.pixels.count
        port.pixels.withUnsafeMutableBufferPointer { px in
            for _ in 0..<h {
                for i in start..<(start + w) where i >= 0 && i < count {
                    px[i] = Blend555.blend(px[i], colour, a: a)
                }
                start += stride
            }
        }
    }
}
