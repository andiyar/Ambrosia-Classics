import Foundation

/// ◇ The levels the replica can run (plan S2, F1b; D35 seat stub) — // later: Phase 6 widens it as each level's
/// sprites are transcribed (Phase 4 LV3: level 3 "Western Reaches", LV4: level 4 "Eastern Reaches", every record sets
/// up — D38 Ruling 2; Phase 5 LV5: level 5 "Manditraki Warrior", every record set up, open to the Warrior's arena with
/// the Warrior a ◇ stand-in until Phase 6; at 6A-BL the closed range 1...5 became this explicit sorted list, since a
/// range cannot say "1 to 5, then 10" and the ids 6–9 have no level data). The map's choice of a level not in the list
/// is refused with `notBuiltReport(_:)` (the only invented text, D35) and the map is entered again at the same node;
/// `GameFlow.startLevel` (the hidden `FerazelLevel` switch) must name a level in it. Every reader asks `contains(_:)`.
public enum BuiltLevels {
    /// The built level ids, sorted, no duplicates. Keep this declaration on ONE line of exactly this shape:
    /// `tools/ferazel-built-levels.sh` prints it for the visit sweep and the bot (`BuiltLevelsTests` pins the parse).
    public static let list: [Int] = [1, 2, 3, 4, 5]

    /// Whether level `n` is built (in `list`).
    public static func contains(_ n: Int) -> Bool {
        list.contains(n)
    }

    /// "Level n is not built yet (Phase 6)." — plain Mac Roman, no symbols (D35; D38 Ruling 2 from LV4; LV5).
    public static func notBuiltReport(_ n: Int) -> String {
        "Level \(n) is not built yet (Phase 6)."
    }
}
