import Foundation

/// The mask flash (plan S2, EF): the count `*_DAT_100a00fc` and the toggle `*_DAT_100a00cc`, stepped once per drawn
/// `.PaintFrameWrap` (M l. 9426–9432, inside the `param_1 != 0` block, before `.DrawParticles`):
/// `count < 1` → toggle 0; else toggle = !toggle and count − 1. While the toggle is on, that pass's
/// `.WrapCopyToScreen` takes the mask port `*_DAT_100a0008` instead of the frame port (M l. 9441–9447;
/// `DrawOp.copyMaskToScreen`) — the alternate-frame silhouette flash, not a screen shake.
///
/// Writers store 3 into the count: `.GenerateRain`'s thunder (M l. 8458), the Smiting cast in `.HandleKeys` (M l.
/// 47593; IU), `.KillPlayerShot`'s seed explosion (M l. 51149; `PlayerShotHits.kill`) and the bosses' deaths (M l.
/// 73488, 74997, 75372, 75525, 76159, 77475; // later: Phase 6). No routine resets either
/// global (they are data-section only), so they run on across levels, deaths, the map and new games: the session's
/// `SpriteWorld` holds them and `LevelCarry.flash` hands them on (EF review fix).
public struct ScreenFlash: Equatable, Sendable {
    /// `*_DAT_100a00fc` (i16).
    public var count: Int16
    /// `*_DAT_100a00cc` (u8): the copy reads the mask port while set.
    public var on: Bool

    public init(count: Int16 = 0, on: Bool = false) {
        self.count = count
        self.on = on
    }

    /// One drawn `.PaintFrameWrap`'s step (M l. 9426–9432).
    public mutating func step() {
        if count < 1 {
            on = false
        } else {
            on.toggle()
            count &-= 1
        }
    }
}
