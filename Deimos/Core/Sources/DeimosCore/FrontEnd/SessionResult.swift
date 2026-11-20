import Foundation

/// What a game session hands back to the front end when it ends (Phase 4, plan S1a; grounding B §1c): the 0x18-byte
/// result `FUN_100234d0` zeroes (`10023610..10023638`) and `FUN_100051a0` fills after its loop (`10005b38..10005c18`),
/// plus what the replica's front end needs to know that the original kept in `FUN_100234d0`'s registers or the film
/// object: how the session ended, whether it was a film, the sector it started at, and the recorded film.
///
/// The fill (`10005b38..10005c04`, per player slot i = 0, 1, both players existing in every session):
/// - **present[i]** (result +0 / +1) = `FUN_10026c90(p) != −1` (`10005b54..10005b70`: `extsb`, `subfic −1` /
///   `addi 1`, `or`, sign bit) — the player's index byte +0xcc, which the set-up writes for BOTH players
///   (`10026438`), so a one-player game reports player 2's slot present too.
/// - present → **score[i]** (+4 / +8) = `FUN_100299f0(p)`, the decoded score (+0xb0 − 0x5532a3e; `10005b80..10005b90`);
///   **level[i]** (+0xc / +0x10) = `FUN_10029cb0(p)`, player +0xc0, the level at its last level start
///   (`10005b94..10005ba0`); **cheated** (+0x15) = 1 if `FUN_10029be0(p)`, player +0xbd (`10005ba4..10005bbc`).
/// - absent → score 0, level `none` (`10005bc4..10005bd8`).
/// - **allLevels** (+0x14) = G+0x0d (`10005c08..10005c10`). [+0x16 = G+0x0e, the unregistered cut-off
///   (`10005c14..10005c18`): never set in the registered build — not carried.]
public struct SessionResult: Equatable, Sendable {
    /// How the session ended — the rule that cleared G+0x08 first in the ending pass's own order.
    public enum End: Equatable, Sendable {
        /// The tick's game over: no player in game (`10006d68..10006d98`, or the level end's completion with nobody
        /// in game, `10007264`).
        case gameOver
        /// The begin frame's quit (`1000591c`, `FUN_100064c0`): Esc (or +0x02, never set in 1.0.6) — for a film too.
        case escape
        /// The campaign end: the last sector's completion found level `none` (`10006620..100066c8`). `allLevels`
        /// says whether it was the whole campaign (G+0x0d).
        case finale
        /// A film's end other than Esc: its recording ran out (`FUN_10009750`, `10005a24..10005a48`), its one level
        /// was completed (`100071e8..100071f8`) or its pilots were lost.
        case filmEnded
        /// The film did not load (`FUN_100069b0` failed → `FUN_100064c0`, `100056dc..100056f0`): no loop ran and the
        /// result is still zero.
        case filmLoadFailed
    }

    public var end: End
    /// The session played a film (G+0x20).
    public var isFilm: Bool
    /// The sector the session started at (the film's level's sector, or the start's).
    public var startSector: Int
    /// Result +0 / +1, by player slot.
    public var present: [Bool]
    /// Result +4 / +8, by player slot.
    public var scores: [Int32]
    /// Result +0xc / +0x10, by player slot.
    public var levels: [FourCC]
    /// Result +0x14: G+0x0d, every level completed (the finale).
    public var allLevels: Bool
    /// Result +0x15: a present player cheated (+0xbd).
    public var cheated: Bool
    /// The recorded film's file bytes (the Last Film, `FUN_100095b0(film, 'last')`) — empty until the recorder
    /// lands (plan S5).
    public var recordedFilm: [UInt8]

    public init(end: End, isFilm: Bool, startSector: Int, present: [Bool], scores: [Int32], levels: [FourCC],
                allLevels: Bool, cheated: Bool, recordedFilm: [UInt8] = []) {
        self.end = end
        self.isFilm = isFilm
        self.startSector = startSector
        self.present = present
        self.scores = scores
        self.levels = levels
        self.allLevels = allLevels
        self.cheated = cheated
        self.recordedFilm = recordedFilm
    }

    /// The result a film that failed to load leaves: still zero (`10023610..10023638`) — no slot present, scores 0,
    /// levels 0 (not `none`: nothing wrote them), no flags.
    public static func filmLoadFailed(startSector: Int) -> SessionResult {
        SessionResult(end: .filmLoadFailed, isFilm: true, startSector: startSector, present: [false, false],
                      scores: [0, 0], levels: [FourCC(rawValue: 0), FourCC(rawValue: 0)], allLevels: false,
                      cheated: false)
    }
}
