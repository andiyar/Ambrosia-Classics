import Foundation

/// ◇ The levels the replica can run (plan S2, F1b; D35 seat stub) — // later: Phases 4–6 widen it as each level's
/// sprites are transcribed (Phase 4 LV3: level 3 "Western Reaches", every record sets up — D38 Ruling 2). The map's choice of a level outside the range is refused with `notBuiltReport(_:)` (the
/// only invented text, D35) and the map is entered again at the same node; `GameFlow.startLevel` (the hidden
/// `FerazelLevel` switch) must name a level inside it.
public enum BuiltLevels {
    public static let range = 1...3

    /// "Level n is not built yet (Phases 4-6)." — plain Mac Roman, no symbols (D35).
    public static func notBuiltReport(_ n: Int) -> String {
        "Level \(n) is not built yet (Phases 4-6)."
    }
}
