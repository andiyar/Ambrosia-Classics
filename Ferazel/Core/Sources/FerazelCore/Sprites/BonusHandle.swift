import Foundation

/// The one part of `.HandleBonusSprite @ 1005e934` Phase 1 runs: the item light's twinkle (decompile l. 53295–53416,
/// raw `1005f808..1005f914`). Every frame `.HandleSprites` calls the Handle of each active Bonus sprite; one whose type
/// is ≥ 2000 reaches `LAB_1005f808` and, with prefs+6 (Effects) ≠ 3, does
///
///     +0x46 += 1                                  // Int16
///     k = (+0x46 >> 2) % 6                        // srawi 2, then a truncating mod (k < 0 → no call)
///     .ChangeLightFace(+0x9a, PTR_DAT_100a088c[k = 0 → 0, 1 → 1, 2 → 2, 3 → 3, 4 → 2, 5 → 1])
///
/// so the light steps 0x32a → 0x32b → 0x32c → 0x32d → 0x32c → 0x32b, four frames each. `PTR_DAT_100a088c[0..3]`
/// are the light faces 0x32a–0x32d, 72×72 (`.InitEffectSprite` l. 53662–53668). `.ChangeLightFace @ 1001bdbc` ignores
/// a slot outside 0…199 (an item with no light, `+0x9a` = −1), and sets the slot's face and radius `+0x14` = width / 2.
///
/// Phase 1 runs this for the Setups it transcribes that reach the branch with a light: the items 0xc80…0xcb0
/// (`SetupFaces`, l. 52664–52700). Of the other Bonus types ≥ 2000 that fall through to `LAB_1005f808`, none is
/// transcribed. The rest of the Handle is not built: the sphere and 0x53c/0x53d cycles (they also set mode 0xb), the
/// torch flicker (`ChangeLightFace` 0x321 ↔ 0x322, l. 53261–53266), and the motion after `LAB_1005fc30`.
public enum BonusHandle {
    /// `PTR_DAT_100a088c[0..3]`: (pict, width, height).
    public static let twinkleFaces: [(pict: Int16, width: Int, height: Int)] = [
        (0x32a, 0x48, 0x48), (0x32b, 0x48, 0x48), (0x32c, 0x48, 0x48), (0x32d, 0x48, 0x48),
    ]
    /// The array index for each k = 0…5.
    static let twinkleOrder = [0, 1, 2, 3, 2, 1]

    /// Whether `type` takes the twinkle branch among the transcribed Setups (the items).
    public static func twinkles(type: Int16) -> Bool { (0xc80...0xcb0).contains(Int(type)) }

    /// One Handle call for `sprite` (dead sprites return at the top of the Handle, l. 52832): advances `+0x46` and
    /// returns the `.ChangeLightFace` it makes as `DrawOp.changeLightFace`, or nil.
    public static func twinkle(_ sprite: inout SpriteSlot, effects: Int16) -> DrawOp? {
        guard !sprite.dead, twinkles(type: sprite.type), effects != 3 else { return nil }
        sprite.phase &+= 1
        let k = (sprite.phase >> 2) % 6
        guard k >= 0, (0..<200).contains(Int(sprite.light)) else { return nil }
        let f = twinkleFaces[twinkleOrder[Int(k)]]
        return .changeLightFace(slot: Int(sprite.light), pict: f.pict, width: f.width, height: f.height)
    }
}
