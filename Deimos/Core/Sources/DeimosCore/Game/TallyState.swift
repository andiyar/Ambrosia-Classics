import Foundation

/// The accuracy-tally and mission-bonus fields of the game struct G (scoring-bonuses.md §1.2, §6.4;
/// G+0x48…+0x168) and each player's coin-tally fields (§1.1, §6.5; player +0xd8…+0x1f8) as plain stored
/// values. C7 declares them; C17 owns this file afterwards (plan S2). The coin-tally fields live on the
/// player object in the original; they are kept here so C17 (parallel with C11b, while `Player.swift`
/// belongs to C15's lane) owns them — `coin[p]` is player p's +0xd8…+0x1f8, read by the player draw
/// `FUN_100298c0` (C12) for the coin-tally text.
public struct TallyState: Equatable, Sendable {
    /// One player's coin tally (player object +0xd8…+0x1f8; `FUN_10027670`, `FUN_10027930`).
    public struct CoinTally: Equatable, Sendable {
        /// Player +0xd8: coin-bonus tally state 0–8 (0 = none).
        public var state: UInt8 = 0
        /// Player +0xdc / +0xe8: tally state timer / per-tick timer.
        public var stateTimer: Int32 = 0
        public var tickTimer: Int32 = 0
        /// Player +0xe0: tally text alpha 0…32 (32 = invisible; `FUN_10027630` sets 0x20).
        public var alpha: Int32 = 0
        /// Player +0xe4: coin value this level.
        public var coinValue: Int32 = 0
        /// Player +0xec…: the tally text (C string; bytes before the terminator here).
        public var text: [UInt8] = []
        /// Player +0x1ec / +0x1f0 / +0x1f4: money at tally start / bonus remaining / step.
        public var moneyAtStart: Int32 = 0
        public var bonusRemaining: Int32 = 0
        public var bonusStep: Int32 = 0
        /// Player +0x1f8: the tally text's y offset for the second counter (flli 181).
        public var textYOffset: Int32 = 0

        public init() {}
    }

    /// Player 0 / 1's coin tally.
    public var coin: [CoinTally] = [CoinTally(), CoinTally()]
    /// G+0x48: accuracy tally state 0–10 (jump table `0x100e3cd0`, 11 entries).
    public var state: UInt8 = 0
    /// G+0x4c: tally state timer.
    public var stateTimer: Int32 = 0
    /// G+0x50: tally text alpha (32 = invisible).
    public var alpha: Int32 = 0
    /// G+0x54: per-tick timer.
    public var tickTimer: Int32 = 0
    /// G+0x58 / +0x5c: accuracy bonus remaining / step.
    public var bonusRemaining: Int32 = 0
    public var bonusStep: Int32 = 0
    /// G+0x60…+0x15f: the tally text (C string, 0x100 bytes; bytes before the terminator here).
    public var text: [UInt8] = []
    /// G+0x160: accuracy percent (truncated, `1000735c`).
    public var percent: Int32 = 0
    /// G+0x164 / +0x168: mission-bonus flag / payments made (`10007b80`, `10007c84`).
    public var missionBonus = false
    public var missionPayments: Int32 = 0

    public init() {}
}
