import Foundation

/// The accuracy-tally and mission-bonus fields of the game struct G (scoring-bonuses.md §1.2, §6.4;
/// G+0x48…+0x168) as plain stored values. C7 declares them; C17 owns this file afterwards (plan S2).
public struct TallyState: Equatable, Sendable {
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
