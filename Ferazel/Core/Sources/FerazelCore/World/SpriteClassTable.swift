/// The 23 Setup callbacks `.GenerateSprite @ 10003478` can select (world-data §3.5; TOC slots
/// 0x1009ff38..0x1009fee0, names from the PEF traceback tables).
public enum SpriteClass: String, Sendable, CaseIterable {
    case bonus, box, background, platform, button, walker, crawler, roach, blob, bat, gremlin, floater, frog,
         salamander, warrior, wizard, effect, dillo, crab, chief, demon, xichra, rope
}

/// Whether `.GenerateSprite` spawns the sprite at once (`MTNewSprite`) or queues it as an idle sprite
/// (`.AddIdleSprite`, activated later by `.HandleIdleSprites`).
public enum Spawn: Sendable, Equatable {
    case now, idle
}

/// Sprite type → (class, spawn): `.GenerateSprite`'s handler selection, transcribed arm by arm in the original's
/// test order (world-data §3.5; mechanical cross-check `docs/ferazel/tools/gensprite_map.py`). Order matters:
/// 1830 (0x726) is caught by the 1700..1839 sub-chain (Wizard), so the later `0x726 → Effect` arm is dead and kept
/// only as written. Types no arm selects spawn nothing → nil.
public enum SpriteClassTable {
    /// - Parameter p1Negative: the record's param 1 is < 0 (only 1090..1099 read it: Background, spawned now).
    public static func classify(type: Int16, p1Negative: Bool) -> (SpriteClass, Spawn)? {
        let s = Int(type)
        /// The original's unsigned-range idiom `(u16)(t − base) < n`.
        func below(_ base: Int, _ n: Int) -> Bool { ((s - base) & 0xffff) < n }
        func r(_ lo: Int, _ hi: Int) -> Bool { lo <= s && s <= hi }

        if below(0x41f, 2) || below(0x422, 2) || s == 0x517 || r(0x50a, 0x513) { return (.bonus, .idle) }
        if below(0x438, 2) { return (.box, .now) }
        if s == 0x4b8 { return (.background, .idle) }
        if r(0x532, 0x53b) { return (.bonus, .now) }
        if r(0x53c, 0x546) { return (.bonus, .now) }
        if s == 0x51b { return (.bonus, .idle) }
        if r(0x578, 0x595) { return (.platform, .now) }
        if r(0x5a0, 0x5a9) { return (.box, .idle) }
        if r(0x5aa, 0x5b3) { return (.box, .now) }
        if r(0x5b4, 0x5bd) { return (.box, .idle) }      // (0x5ba also adds an idle 0x5bb — a Setup side effect)
        if r(0x5be, 0x5c7) { return (.box, .idle) }
        if r(0x5c8, 0x5d1) { return (.background, .now) }
        if r(0x47e, 0x487) { return (.background, .idle) }
        if r(0x5d2, 0x5db) { return (.box, .now) }
        // The big chain (default handler Box).
        if below(0x424, 3) || s == 0x429 || r(0x4e2, 0x4ff) { return (.box, .idle) }
        if r(0x528, 0x531) { return (.button, .idle) }
        if r(2000, 0x801) { return (.bonus, .idle) }
        if below(0x42e, 3) || s == 0x433 || s == 0xbfe { return (.box, .idle) }
        if r(0x442, 1099) { return (.background, p1Negative ? .now : .idle) }
        if r(0x6a4, 0x72f) {
            if s <= 0x6ad { return (.walker, .idle) }
            if s == 0x6b0 { return (.crawler, .idle) }
            if s == 0x6b8 { return (.roach, .idle) }
            if r(0x6c2, 0x6cb) { return (.blob, .idle) }
            if r(0x6cc, 0x6d5) { return (.bat, .idle) }
            if r(0x6d6, 0x6df) { return (.walker, .idle) }
            if r(0x6e0, 0x6e9) { return (.walker, .idle) }
            if r(0x6ea, 0x6f3) { return (.gremlin, .now) }
            if r(0x6f4, 0x6fd) { return (.floater, .idle) }
            if r(0x6fe, 0x707) { return (.floater, .idle) }
            if r(0x708, 0x711) { return (.frog, .idle) }
            if r(0x712, 0x71b) { return (.salamander, .idle) }
            if r(0x71c, 0x725) { return (.warrior, .now) }
            if 0x725 < s && s < 0x730 { return (.wizard, .idle) }
            return nil   // 0x6ae, 0x6af, 0x6b1..0x6b7, 0x6b9..0x6c1: no handler
        }
        if s == 0x726 { return (.effect, .idle) }       // dead: 0x726 was taken by the sub-chain above
        if below(0x730, 4) { return (.background, .now) }
        if r(0x73a, 0x73e) { return (.bat, .idle) }
        if r(0x73f, 0x743) { return (.background, .idle) }
        if r(0x744, 0x74d) { return (.bat, .idle) }
        if r(0x74e, 0x757) { return (.dillo, .idle) }
        if r(0x762, 0x76b) { return (.crab, .idle) }
        if r(0x76c, 0x775) { return (.background, .idle) }
        if r(0x776, 0x77f) { return (.chief, .idle) }
        if r(0x780, 0x789) { return (.demon, .now) }
        if r(0x7c6, 1999) { return (.xichra, .now) }
        if r(0xa8c, 0xaef) { return (.background, .idle) }
        if r(0xaf5, 0xb35) { return (.box, .idle) }
        if r(0xb36, 0xb49) { return (.box, .idle) }
        if r(0xb4a, 0xb53) { return (.background, .now) }
        if r(0xc08, 0xc11) { return (.background, .idle) }
        if r(0xc12, 0xc1b) { return (.box, .idle) }
        if below(0xb54, 2) { return (.background, .idle) }
        if r(0xb56, 0xb5d) { return (.box, .idle) }
        if below(0xb5e, 2) { return (.box, .idle) }
        if s == 0x51c || r(0xb68, 0xb85) { return (.box, .idle) }
        if r(0xb87, 2999) { return (.box, .idle) }
        if r(3000, 0xbcb) { return (.background, .idle) }
        if r(0xbcc, 0xbdf) { return (.rope, .idle) }
        if s == 0xbea { return (.bonus, .idle) }
        if s == 0xbf4 { return (.background, .idle) }
        if r(0xc1c, 0xc25) { return (.bonus, .idle) }
        if r(0xc80, 0xcb0) { return (.bonus, .idle) }
        if s == 0xcb1 { return (.background, .idle) }
        return nil
    }
}
