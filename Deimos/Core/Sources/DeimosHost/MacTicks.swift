import Foundation

/// The rate of the Mac `TickCount` the replica emulates (plan S5, Q1). The original reads `TickCount` (`FUN_100497f0`
/// = the `TickCount` glue, timing-frame §2.3) for its limiter, its fades and its seed; the rate is the only free
/// parameter of the replica's clock.
public enum TickRate: Double, Sendable {
    /// The classic Mac tick, 60.15 Hz (timing-frame §4) — the default (Q1).
    case classic = 60.15
    /// Mac OS X's `TickCount`, 60 Hz.
    case osx = 60.0

    /// Ticks per second.
    public var perSecond: Double { rawValue }
}

/// `TickCount` from a host clock in seconds.
public enum MacTicks {
    /// `UInt32(truncatingIfNeeded: UInt64(⌊seconds · rate⌋))` — the tick count wraps like the original's 32-bit
    /// `TickCount`. `seconds` must be ≥ 0.
    public static func ticks(seconds: Double, rate: Double) -> UInt32 {
        UInt32(truncatingIfNeeded: UInt64((seconds * rate).rounded(.down)))
    }
}
