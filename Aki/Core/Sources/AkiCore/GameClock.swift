/// The time state of `_g` (docs/aki/rules.md §10 state table, §11, §13): a8 start tick · ac penalty ·
/// b0 bonus · b4 elapsed · b8 remaining · bc remaining frozen at "no more pairs" · c0 freeze tick.
/// Times are seconds except the two ticks (QuickDraw `_TickCount`, 60 per second, rules §0).
///
/// Pure arithmetic: the callers' guards (paused, `g+0x60 ≠ 0`, "none if b8 == 0") live in `AkiGame`.
public struct GameClock: Equatable, Sendable {                 // P2.4 — rules §10/§11/§13
    /// a8 — the tick the level clock counts from.
    public var baseTick: UInt32                                 // P2.4
    /// ac — accumulated penalty seconds.
    public var penalty: Int                                     // P2.4
    /// b0 — accumulated bonus seconds.
    public var bonus: Int                                       // P2.4
    /// b4 — elapsed seconds, `(now − a8)/60`.
    public var elapsed: Int                                     // P2.4
    /// b8 — remaining seconds.
    public var remaining: Int                                   // P2.4
    /// bc — b8 frozen on entering "no more pairs" (rules §11).
    public var frozenRemaining: Int                             // P2.4
    /// c0 — the tick the clock was frozen/paused at; 0 when running.
    public var freezeTick: UInt32                               // P2.4

    /// The level time limit, `0x96` (rules §10).
    public static let limitSeconds = 150                        // P2.4
    /// The remaining-time cap, `300` (rules §10).
    public static let capSeconds = 300                          // P2.4

    /// Level start — `_AnimationMapScreenToCustom` @ 0x10f5f tail: a8 = now, ac = b0 = b4 = c0 = 0, b8 = 150.
    public init(start now: UInt32) {                            // P2.4
        baseTick = now
        penalty = 0
        bonus = 0
        elapsed = 0
        remaining = Self.limitSeconds
        frozenRemaining = 0
        freezeTick = 0
    }

    /// The per-tick formula of `_CustomGameScreen` @ 0x12dbc: b4 = (now − a8)/60 (C truncation, signed
    /// 32-bit tick difference); b8 = 150 − ((b4 + ac) − b0).
    public mutating func update(now: UInt32) {                  // P2.4
        elapsed = Int(Int32(bitPattern: now &- baseTick)) / 60
        remaining = Self.limitSeconds - ((elapsed + penalty) - bonus)
    }

    /// The shared preamble of `_RedrawCustomTimeBar` @ 0xefa0 and tail of `_RedrawCustomGameScreen`:
    /// Practice (raw p+0x20c == 3) resets a8 = now; then if b8 > 300, ac += b8 − 300 (b8 itself is
    /// left until the next `update`).
    public mutating func applyTimeBarAdjustments(now: UInt32, difficultyRaw: Int16) {   // P2.4
        if difficultyRaw == 3 { baseTick = now }
        if remaining > Self.capSeconds { penalty += remaining - Self.capSeconds }
    }

    /// `_RedrawCustomTimeBar` @ 0xefa0: `9000 − ((t − a8) + 60·ac − 60·b0)`.
    public func timeBarRaw(at tick: UInt32) -> Int {            // P2.4
        9000 - (Int(Int32(bitPattern: tick &- baseTick)) + 60 * penalty - 60 * bonus)
    }

    /// The bar length in pixels, `min(450, raw × 450 / 18000)` (C truncation; may be negative).
    /// Callers pass `paused ? freezeTick : now`.
    public func timeBarLength(now: UInt32) -> Int {             // P2.4
        min(450, timeBarRaw(at: now) * 450 / 18000)
    }

    /// `_PauseGame` @ 0xd34b / "no more pairs": c0 = now unless already frozen.
    public mutating func freeze(now: UInt32) {                  // P2.4
        if freezeTick == 0 { freezeTick = now }
    }

    /// Unpause / leave "no more pairs": a8 += now − c0, c0 = 0 (unguarded, rules §11, §13).
    public mutating func thaw(now: UInt32) {                    // P2.4
        baseTick &+= now &- freezeTick
        freezeTick = 0
    }

    /// Entering "no more pairs" (`_RedrawNoMorePairs` @ 0x10854, rules §11): bc := b8; freeze.
    public mutating func enterNoMorePairs(now: UInt32) {        // P2.4
        frozenRemaining = remaining
        freeze(now: now)
    }

    /// Match bonus (`_SelectCGTile` switch, rules §10): Hard 3 / Medium 6 / Easy 12 / Practice 0.
    public static func matchBonus(_ d: Difficulty) -> Int {     // P2.4
        switch d {
        case .hard: 3
        case .medium: 6
        case .easy: 12
        case .practice: 0
        }
    }

    /// Hint penalty (`_ShowNextCGHint`, rules §10): b8/2, b8/4, b8/8, 0 (C truncating division).
    public static func hintPenalty(remaining: Int, _ d: Difficulty) -> Int {   // P2.4
        switch d {
        case .hard: remaining / 2
        case .medium: remaining / 4
        case .easy: remaining / 8
        case .practice: 0
        }
    }

    /// Reshuffle penalty (`_ReshuffleCustomTiles` @ 0x133ff, rules §10): 3·b8/4, b8/2, b8/4, 0.
    public static func reshufflePenalty(remaining: Int, _ d: Difficulty) -> Int {   // P2.4
        switch d {
        case .hard: (3 * remaining) / 4
        case .medium: remaining / 2
        case .easy: remaining / 4
        case .practice: 0
        }
    }

    /// Undo penalty (`_UndoLastCGMove` @ 0x128cb, rules §10/§12): 3, 6, 12, 0.
    public static func undoPenalty(_ d: Difficulty) -> Int {    // P2.4
        switch d {
        case .hard: 3
        case .medium: 6
        case .easy: 12
        case .practice: 0
        }
    }
}
