import Foundation

/// ◇ The levels the replica can run (plan S2, F1b; D35 seat stub) — // later: Phase 6 widens it as each level's
/// sprites are transcribed (Phase 4 LV3: level 3 "Western Reaches", LV4: level 4 "Eastern Reaches", every record sets
/// up — D38 Ruling 2; Phase 5 LV5: level 5 "Manditraki Warrior", every record set up, open to the Warrior's arena —
/// his Handle real since 6A-W1, his Hit and Kill real since 6A-W2; at 6A-BL the closed range 1...5 became this explicit
/// sorted list, since a range cannot say "1 to 5, then 10" and the ids 6–9 have no level data; 6A-L10L11: level 10
/// "Unemployed In Greenland" and level 11 "River of Fears", every record set up; 6A-L15: level 15 "Storm Valley", every
/// record set up, its rain, thunder and side push built by 6A-RN; 6A-L18: level 18 "Goblin Chief", every record set up,
/// the Chief whole since 6A-CH1 / 6A-CH2, the ripple built by 6A-RP; 6A-L20: level 20 "Hangnabit", every record set
/// up, its clouds, blades and path maces built by 6A-CL / 6A-BD / 6A-MP, a lit blade on its unlit grid drawn plain
/// (D67.1)). The map's choice of a
/// level not in the list is refused with `notBuiltReport(_:)` (the only invented text, D35) and the map is entered
/// again at the same node; `GameFlow.startLevel` (the hidden `FerazelLevel` switch) must name a level in it. Every
/// reader asks `contains(_:)`.
public enum BuiltLevels {
    /// The built level ids, sorted, no duplicates. Keep this declaration on ONE line of exactly this shape:
    /// `tools/ferazel-built-levels.sh` prints it for the visit sweep and the bot (`BuiltLevelsTests` pins the parse).
    public static let list: [Int] = [1, 2, 3, 4, 5, 10, 11, 15, 18, 20]

    /// Whether level `n` is built (in `list`).
    public static func contains(_ n: Int) -> Bool {
        list.contains(n)
    }

    /// "Level n is not built yet (Phase 6)." — plain Mac Roman, no symbols (D35; D38 Ruling 2 from LV4; LV5).
    public static func notBuiltReport(_ n: Int) -> String {
        "Level \(n) is not built yet (Phase 6)."
    }
}
