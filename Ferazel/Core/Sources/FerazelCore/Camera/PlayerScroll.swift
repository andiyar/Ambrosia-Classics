import Foundation

/// The player's camera focus (plan S2 ★, P5; engine §5): `.PlayerScroll @ 1004c528` (raw `1004c528..1004c808`,
/// decompile l. 43754–43851) and the look-ahead row `.HandlePlayerSprite` runs just before it (raw
/// `10051494..1005158c`, l. 46393–46422; triggers-background-2 §8.2). Replaces the Phase-1 ◇ `CameraFocusDriver`.
///
/// The globals live in `PlayerState` under their addresses: focus `(fd44, fd40)` = `focusX/focusY`, centre
/// `(fd94, fd90)` = `centreX/centreY`, ground y `_DAT_100a0740` = `groundCentreY`, latch `DAT_100a5f58` =
/// `scrollLatch`, easing `_DAT_100a06dc` = `scrollEasing`, look-ahead `_DAT_100a0680` = `lookAhead`, `uRam100a5114` =
/// `snapArmed`, the scroll point `PTR_DAT_1009fe78` = `scrollH/scrollV`. No smoothing beyond these (Invariant 7).
public enum PlayerScroll {
    /// The look-ahead cap ±0x5000 (80 px) and the slow decay 0x200 a frame.
    public static let maxLookAhead: Int32 = 0x5000
    public static let decay: Int32 = 0x200

    /// The look-ahead row (l. 46393–46422), vx = the player's `+0x24`, F = `_DAT_100a5f5a`: `uRam100a5114 = 1`;
    /// vx > 0x100 → L += vx >> 2 (srawi), and again while L < 0, cap +0x5000; vx < −0x100 mirrored (again while
    /// L > 0), floor −0x5000; otherwise F 1 and L > 0 → L −= 0x200, F 2 and L < 0 → L += 0x200, each clearing
    /// `uRam100a5114` (the decay may overshoot zero; the overshoot is kept).
    public static func lookAhead(_ p: inout PlayerState, vx: Int32) {
        p.snapArmed = true
        if vx < 0x101 {
            if vx < -0x100 {
                p.lookAhead &+= vx >> 2
                if 0 < p.lookAhead { p.lookAhead &+= vx >> 2 }
                if p.lookAhead < -maxLookAhead { p.lookAhead = -maxLookAhead }
            } else if p.facing == 1 && 0 < p.lookAhead {
                p.lookAhead &-= decay
                p.snapArmed = false
            } else if p.facing == 2 && p.lookAhead < 0 {
                p.snapArmed = false
                p.lookAhead &+= decay
            }
        } else {
            p.lookAhead &+= vx >> 2
            if p.lookAhead < 0 { p.lookAhead &+= vx >> 2 }
            if maxLookAhead < p.lookAhead { p.lookAhead = maxLookAhead }
        }
    }

    /// `.PlayerScroll(s)`; `groundKind` = `s+0xce`, `inWind` = `s+0x92`.
    ///
    /// fd44 = (i16)(fd94 + (L >> 8)) (srawi, raw `1004c580`). The band = `SetRect(h, v, h + 0x260, v + 0x180)` with
    /// top + 0x10 and bottom − 0x60, tested with `PtInRect(fd90, fd94)` (bottom / right exclusive).
    /// - A, freeze (raw `1004c5d0..1004c67c` → `1004c7f0`): not grounded, J `_DAT_100a0678` 0, `05a0`, tumble `05b8`,
    ///   glider `05e0`, rope `0588`, climb `0758`, wind `+0x92`, swim `0714`, ridden `0558`, easing all 0, fd90 ≤
    ///   ground y and in the band → latch 0; the focus y holds.
    /// - B, exact follow (raw `1004c680..1004c708`): the latch, J, tumble, rope, `05a0`, glider, swim, out of the band
    ///   or wind → easing 0, fd40 = fd90.
    /// - C, ease (raw `1004c70c..1004c7ec`): fd40 < fd90 → fd40 += max(Δ / 6, 6) (mulhw 0x2aaaaaab), easing 1, and on
    ///   reaching fd90 easing 0, latch 1, fd40 = fd90; fd40 > fd90 → fd40 −= max((fd40 − ground y) / 7, 5)
    ///   (mulhw 0x92492493, truncating — the distance to the ground y, not to fd90), easing 1, and on reaching the
    ///   ground y latch 1, easing 0, fd40 = ground y.
    public static func scroll(_ p: inout PlayerState, groundKind: UInt8, inWind: Bool) {
        p.focusX = Int16(truncatingIfNeeded: Int32(p.centreX) &+ (p.lookAhead >> 8))
        let top = p.scrollV + 0x10, bottom = p.scrollV + 0x180 - 0x60
        let left = p.scrollH, right = p.scrollH + 0x260
        let y = Int(p.centreY), x = Int(p.centreX)
        let inBand = top <= y && y < bottom && left <= x && x < right
        if groundKind == 0 && p.jumpBase == 0 && !p.flag05a0 && !p.launched && !p.glider && !p.rope
            && p.climb == 0 && !inWind && p.swim == 0 && p.ridden == nil && !p.scrollEasing
            && p.centreY <= p.groundCentreY && inBand {
            p.scrollLatch = false
            return
        }
        if p.scrollLatch || p.jumpBase != 0 || p.launched || p.rope || p.flag05a0 || p.glider || p.swim != 0
            || !inBand || inWind {
            p.scrollEasing = false
            p.focusY = p.centreY
            return
        }
        let focus = Int32(p.focusY), target = Int32(p.centreY)
        if focus < target {
            var step = Int32(Int16(truncatingIfNeeded: (target - focus) / 6))
            if step < 6 { step = 6 }
            p.focusY = Int16(truncatingIfNeeded: focus &+ step)
            p.scrollEasing = true
            if Int32(p.focusY) < target { return }
            p.scrollEasing = false
            p.scrollLatch = true
            p.focusY = p.centreY
        } else if target < focus {
            let ground = Int32(p.groundCentreY)
            var step = Int32(Int16(truncatingIfNeeded: (focus &- ground) / 7))
            if step < 5 { step = 5 }
            p.focusY = Int16(truncatingIfNeeded: focus &- step)
            p.scrollEasing = true
            if ground < Int32(p.focusY) { return }
            p.scrollLatch = true
            p.scrollEasing = false
            p.focusY = p.groundCentreY
        }
    }

    /// The look-ahead row and `.PlayerScroll` for the player sprite `id` (`.HandlePlayerSprite` l. 46393–46423).
    static func handle(world w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id) else { return }
        lookAhead(&w.player, vx: s.vx)
        scroll(&w.player, groundKind: s.groundKind, inWind: s.inWind)
    }
}
