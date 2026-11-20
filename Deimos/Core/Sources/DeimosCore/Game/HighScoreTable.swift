import Foundation

/// The high-score table's two writers outside the file codec (G_Scores.cc, U_Prefs.cc; grounding B §2a, §2b;
/// loose-ends-session.md §3.1): the insertion after a game, `FUN_100214c0(result)` (listing `100214c0..10021940`), and
/// the defaults routine `FUN_10004ae0` that both a fresh settings file and the menu's Option-click erase run. Both are
/// pure: they take a prefs value and return the changed one. The caller (start/return, S3a) runs name entry for the
/// slots the insertion returns, player 1 first, and the erase question lives in `Scores`.
public enum HighScoreTable {
    /// Rows in the table (`prefs+0x1260`, 15 × i32).
    public static let rowCount = 15

    /// What `FUN_100214c0` leaves before its two name-entry calls: the shifted copy **A** (the prefs it then hands to
    /// `FUN_10021bd0`) and each player's row, nil when that player did not qualify (or was pushed off the table).
    public struct Insertion: Equatable, Sendable {
        /// Copy A: the live prefs with the rows shifted and written; nothing else changed.
        public var prefs: DeimosPrefs
        /// `[idx1, idx2]`: player 1's and player 2's row, in that order.
        public var slots: [Int?]

        public init(prefs: DeimosPrefs, slots: [Int?]) {
            self.prefs = prefs
            self.slots = slots
        }
    }

    /// `FUN_100214c0(result)` over the live prefs `prefs` (both copies A and B are `FUN_10004c30` copies of them):
    /// - idx = the first row i (0…14, in order) with `score > A.score[i]` (signed, strict: `cmpw; ble next`, so a tie
    ///   ranks below), tested only for a slot the result marks present (+0 / +1); else −1.
    /// - Both found: idx1 > idx2 → idx1 + 1, −1 if that reaches 15 (`100216a4`); THEN idx2 ≥ idx1 (the adjusted one) →
    ///   idx2 + 1, −1 if ≥ 15 (`100216cc`).
    /// - idx1 found: for i in idx1…13, A[i + 1] = **B**[i] (score, name, sector name — the pristine copy); then B = A
    ///   (memcpy 0x34f0, `1002178c`); idx2 found: for i in idx2…13, A[i + 1] = B[i].
    /// - A[idx1] = {P1 score, A's remembered name +0x1233, `levelName(result +0xc)`}; A[idx2] likewise with +0x1248
    ///   and +0x10.
    ///
    /// The two original quirks follow from that order and are kept (plan ruling 15): (a) P2 above P1 in a different
    /// slot — P1's shift read B before P2's shift moved the rows, so the row just below P1's first slot is lost and
    /// the next one listed twice; (b) both between the same two rows — P1 is placed first even when lower. In a
    /// one-player game the P2 slot is present with score 0 and never qualifies against a positive table.
    ///
    /// `levelName` is `FUN_100120f0(tag, buf, 0)`'s level name (its `#name_STR`, the record's +0x000).
    public static func insert(_ result: SessionResult, into prefs: DeimosPrefs,
                              levelName: (FourCC) -> String) -> Insertion {
        var a = prefs
        func slot(_ p: Int) -> Int? {
            guard result.present.indices.contains(p), result.present[p],
                  result.scores.indices.contains(p) else { return nil }
            let score = result.scores[p]
            return a.highScores.prefix(rowCount).firstIndex { score > $0 }
        }
        var idx1 = slot(0)
        var idx2 = slot(1)
        if let i1 = idx1, let i2 = idx2, i1 > i2 {
            idx1 = i1 + 1 < rowCount ? i1 + 1 : nil
        }
        if let i2 = idx2, let i1 = idx1, i2 >= i1 {
            idx2 = i2 + 1 < rowCount ? i2 + 1 : nil
        }
        var b = prefs
        if let i1 = idx1 { shift(&a, from: b, at: i1) }
        b = a                                                            // 1002178c: B = A
        if let i2 = idx2 { shift(&a, from: b, at: i2) }
        let names = a.playerNames
        for (p, idx) in [idx1, idx2].enumerated() {
            guard let i = idx else { continue }
            a.highScores[i] = result.scores[p]
            a.highScoreNames[i] = names.indices.contains(p) ? names[p] : ""
            a.highScoreSectorNames[i] = result.levels.indices.contains(p) ? levelName(result.levels[p]) : ""
        }
        return Insertion(prefs: a, slots: [idx1, idx2])
    }

    /// `insert(_:into:levelName:)` with the level names of the shipped level definitions (`FUN_100120f0` loads the
    /// `leve` by tag; the first definition with that tag). A tag with no definition gives "" (the original asserts
    /// and leaves its buffer unwritten — unreachable for a present player).
    public static func insert(_ result: SessionResult, into prefs: DeimosPrefs, assets: DeimosAssets) -> Insertion {
        insert(result, into: prefs) { tag in assets.definitions.levels.first { $0.id == tag }?.name ?? "" }
    }

    /// `FUN_10004ae0` — the defaults routine (fresh prefs, and the menu's Option-click erase on "Erase", front-end.md
    /// §2.7): its first loop resets both remembered player names to "Player %i" (dump line 2842; grounding B §2a, §9.1),
    /// then rows 1…15 get score 16000 − 1000·k, the k-th default name and "New Atlantis". Nothing else in the prefs
    /// changes (live prefs only; the disk write is at quit). The values are `DeimosPrefs.fresh`'s, which this routine
    /// also fills.
    ///
    /// Known and kept: the original copies each default name out of a scrambled 21-byte table and unscrambles all 21
    /// bytes, so a short name sits in memory as the name plus 0xFF bytes up to byte 20 (PF review, 2026-11-20); the
    /// replica holds the plain name, as `DeimosPrefs.fresh` does. Those bytes draw nothing (`TextLayout` gives bytes
    /// ≥ 0x80 zero size).
    public static func erase(_ prefs: DeimosPrefs) -> DeimosPrefs {
        var p = prefs
        let fresh = DeimosPrefs.fresh
        p.playerNames = fresh.playerNames
        p.highScores = fresh.highScores
        p.highScoreNames = fresh.highScoreNames
        p.highScoreSectorNames = fresh.highScoreSectorNames
        return p
    }

    /// `for i = idx … 14: if i + 1 < 15: A[i + 1] = from[i]` (`10021700..1002177c`, `100217b0..1002182c`).
    private static func shift(_ a: inout DeimosPrefs, from b: DeimosPrefs, at idx: Int) {
        for i in idx..<(rowCount - 1) {
            a.highScores[i + 1] = b.highScores[i]
            a.highScoreNames[i + 1] = b.highScoreNames[i]
            a.highScoreSectorNames[i + 1] = b.highScoreSectorNames[i]
        }
    }
}
