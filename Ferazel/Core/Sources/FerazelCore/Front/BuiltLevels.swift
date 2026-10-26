import Foundation

/// ◇ The levels the replica can run (plan S2, F1b; D35 seat stub) — // later: Phases 5–6 widen it as each level's
/// sprites are transcribed (Phase 4 LV3: level 3 "Western Reaches", LV4: level 4 "Eastern Reaches", every record sets
/// up — D38 Ruling 2; level 5, Manditraki Warrior, is a boss: Phase 6). The map's choice of a level outside the range
/// is refused with `notBuiltReport(_:)` (the only invented text, D35) and the map is entered again at the same node;
/// `GameFlow.startLevel` (the hidden `FerazelLevel` switch) must name a level inside it.
public enum BuiltLevels {
    public static let range = 1...4

    /// "Level n is not built yet (Phases 5-6)." — plain Mac Roman, no symbols (D35; D38 Ruling 2 from LV4).
    public static func notBuiltReport(_ n: Int) -> String {
        "Level \(n) is not built yet (Phases 5-6)."
    }
}
