import Foundation

/// Name entry for one player — `FUN_10021bd0(player, slot, prefs, fromGame)` (grounding B §2c; `front-end.md` §4.3).
/// Called only by the score-table insertion (`FUN_100214c0`), player 1 then player 2, each only if that player
/// qualified. ◇ Phase 4 S1b stub; S4 builds it.
///
/// **Frozen entry.** `init(player:slot:prefs:fromGame:)` — the player (0 or 1), the table row (0…14), the prefs
/// copy A the insertion has already shifted, and `fromGame` (always true from the insertion). **Returns** prefs A as
/// name entry left it — the row's name and the remembered player name written; name entry also copies it into the
/// live prefs on exit (`FUN_100047f0(A)`), and the insertion hands it to the second player's entry.
///
/// **The stub.** Draws nothing and returns `prefs` unchanged at once.
public struct NameEntry: Sendable {
    public typealias Result = DeimosPrefs

    public let player: Int
    public let slot: Int
    public let prefs: DeimosPrefs
    public let fromGame: Bool

    public init(player: Int, slot: Int, prefs: DeimosPrefs, fromGame: Bool = true) {
        self.player = player
        self.slot = slot
        self.prefs = prefs
        self.fromGame = fromGame
    }

    public mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?,
                              state: inout FrontEndState) -> ScreenStep<Result> {
        .finish(prefs)
    }
}
