import Foundation

/// The statistics half of `_p` (docs/aki/rules.md §14, file-formats.md §2.2): the win block of
/// `_CustomGameScreen`, the loss and give-up counters, and the Stats dialog fill. Every write is
/// guarded by `level < 12` (custom levels 13…17 record nothing, levels.md §3); the counters are the
/// original's 16-bit adds (`&+`, Int16 wrap).
public enum Stats {                                             // P2.7 — rules §14, file-formats §2.2 stats dialog
    /// `_CustomGameScreen` win block DC:7479–7501: level < 12 → wins[level] += 1 (incl. Practice);
    /// not Practice → best[level] = elapsed (g+0xb4) if 0, else the smaller; not Practice ∧ level < 11 →
    /// unlocked[level + 1] = 1. (The guide-flag clear g+0x22b at DC:7503 is the App's.)
    public static func recordWin(_ s: inout GameSettings, level: Int, elapsed: Int, difficulty: Difficulty) {
        let practice = difficulty == .practice
        if level < 12 {
            s.wins[level] = s.wins[level] &+ 1
            if !practice {
                let t = Int32(truncatingIfNeeded: elapsed)
                if s.bestTimes[level] == 0 {
                    s.bestTimes[level] = t
                } else if t < s.bestTimes[level] {
                    s.bestTimes[level] = t
                }
            }
        }
        if !practice && level < 11 {
            s.unlocked[level + 1] = 1
        }
    }

    /// The stacked / time-out loss, `_CustomGameScreen` DC:6229: level < 12 → losses[level] += 1 (p+0x230).
    public static func recordLoss(_ s: inout GameSettings, level: Int) {
        guard level < 12 else { return }
        s.losses[level] = s.losses[level] &+ 1
    }

    /// Give Up, `-[Controller abortGame]` DC:996: level < 12 → giveUps[level] += 1 (p+0x248).
    public static func recordGiveUp(_ s: inout GameSettings, level: Int) {
        guard level < 12 else { return }
        s.giveUps[level] = s.giveUps[level] &+ 1
    }

    /// One level's line of the Stats dialog.
    public struct Row: Equatable, Sendable {
        public var wins: Int, losses: Int, giveUps: Int, bestMinutes: Int, bestSeconds: Int
        public init(wins: Int, losses: Int, giveUps: Int, bestMinutes: Int, bestSeconds: Int) {
            self.wins = wins
            self.losses = losses
            self.giveUps = giveUps
            self.bestMinutes = bestMinutes
            self.bestSeconds = bestSeconds
        }
    }

    /// `_CreateNewDialog(0x3c)` DC:1717–1780: minutes = (short)(best / 60); seconds =
    /// (short)((short)best − 60·minutes); totals are the 16-bit sums `local_b2/b0/ae`.
    public static func table(_ s: GameSettings) -> (rows: [Row], totalWins: Int, totalLosses: Int, totalGiveUps: Int) {
        var rows: [Row] = []
        var totalWins: Int16 = 0, totalLosses: Int16 = 0, totalGiveUps: Int16 = 0
        for i in 0..<12 {
            let best = s.bestTimes[i]
            let minutes = Int16(truncatingIfNeeded: best / 60)
            let seconds = Int16(truncatingIfNeeded: best) &- 60 &* minutes
            rows.append(Row(wins: Int(s.wins[i]), losses: Int(s.losses[i]), giveUps: Int(s.giveUps[i]),
                            bestMinutes: Int(minutes), bestSeconds: Int(seconds)))
            totalWins = totalWins &+ s.wins[i]
            totalGiveUps = totalGiveUps &+ s.giveUps[i]
            totalLosses = totalLosses &+ s.losses[i]
        }
        return (rows, Int(totalWins), Int(totalLosses), Int(totalGiveUps))
    }
}

/// The 13–17 slot (docs/aki/levels.md §3): five decorations for user-made `.aki` levels, never layouts.
public enum AkiLevels {                                         // P2.7 — the 13–17 slot (levels §3); the ONE _RandomBackground
    /// Levels 0…11 are the built-in layouts; every stat write is guarded by `level < 0xc`.
    public static func isBuiltIn(_ level: Int) -> Bool { level < 12 }

    /// `_RandomBackground` DC:7404: `srand(TickCount()); rand() % 5 + 13`. The caller stores the result
    /// in both `g.levelIndex` (g+0x90) and `g.background` (g+0x8e).
    public static func randomDecoration<R: RandomNumberGenerator>(using rng: inout R) -> Int {
        Int(rng.next() % 5) + 13
    }

    /// The Stats nib's control IDs (DC:1717–1780, plan R8): level i fills minutes+i, seconds+i,
    /// wins+i, losses+i, giveUps+i; the three totals are 40 (wins), 41 (losses), 42 (give-ups).
    public static let statsControlIDs: (minutes: Int, seconds: Int, wins: Int, losses: Int, giveUps: Int, totals: [Int]) =
        (minutes: 401, seconds: 413, wins: 1, losses: 13, giveUps: 25, totals: [40, 41, 42])
}
