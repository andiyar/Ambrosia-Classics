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
/// BN: the whole Handle is `BonusSprite.handle` (`LAB_1005f808` is `BonusSprite.loot`); this type stays as a thin
/// forward for the Phase-1 callers and tests — the twinkle of an item (0xc80…0xcb0) on one sprite.
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
        guard !sprite.dead, twinkles(type: sprite.type) else { return nil }
        let slot = sprite.light
        var op: DrawOp?
        BonusSprite.loot(&sprite, effects: effects) { f in
            guard let f, (0..<LightTable.slotCount).contains(Int(slot)) else { return }
            op = .changeLightFace(slot: Int(slot), pict: f.pict, width: f.width, height: f.height)
        }
        return op
    }

    /// LT: the Handle call with its `.ChangeLightFace` also made on Core's light table (the single source of truth);
    /// the returned op carries the same call to the renderer's copy for the redrawn cells of this frame.
    public static func twinkle(_ sprite: inout SpriteSlot, effects: Int16, lights: inout LightTable) -> DrawOp? {
        let op = twinkle(&sprite, effects: effects)
        if case .changeLightFace(let slot, let pict, let width, let height)? = op {
            lights.changeFace(Int16(slot), LightFaceRef(pict: pict, width: width, height: height))
        }
        return op
    }
}
