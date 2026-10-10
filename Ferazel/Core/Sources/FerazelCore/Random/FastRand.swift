import Foundation

/// `.FastRand @ 100340e0` (decompile l. 31282–31313, raw `100340e0..100341b8`): the game's one random stream, seed
/// `_DAT_100a17e8`. Consumed in the binary's call order from level start (plan Invariant 4): the Setups first
/// (`SetupFaces`), then per frame.
///
/// - n ≠ 0 (raw `1003411c..1003419c`): one Park–Miller step, seed = 16807·seed mod (2³¹ − 1), computed with 16-bit
///   halves; lo = seed & 0xffff; **lo == 0x8000 → lo = 0** (`rlwinm r6,r6,0,0,15`, the stored seed keeps it);
///   result = (Int16)((extsh(n) · lo) >> 16) — 0 … n − 1 for n > 0.
/// - n == 0 (raw `100340fc..10034118`): seed = `LMGetTime()` + `LMGetTicks()` (`.InitAppGlobals` l. 334 calls
///   `FastRand(0)`); the return value is the caller's r30 (`unaff_r30`), undefined — 0 here.
public struct FastRand: Sendable {
    /// `LMGetTime()` (seconds since 1904-01-01) and `LMGetTicks()` (1/60 s since start-up).
    public typealias Clock = @Sendable () -> (secondsSince1904: UInt32, ticks: UInt32)

    /// `_DAT_100a17e8`.
    public var seed: Int32
    private let clock: Clock

    public init(seed: Int32, clock: @escaping Clock = FastRand.systemClock) {
        self.seed = seed
        self.clock = clock
    }

    /// Time + Ticks as `.FastRand(0)` stores it (`add r0,r3,r31`, 32-bit wrap).
    public static func clockSeed(secondsSince1904: UInt32, ticks: UInt32) -> Int32 {
        Int32(bitPattern: secondsSince1904 &+ ticks)
    }

    /// The host clock: seconds since 1904 from the wall clock, ticks from the system uptime.
    public static let systemClock: Clock = {
        let since1904 = Date().timeIntervalSince1970 + 2_082_844_800
        let ticks = ProcessInfo.processInfo.systemUptime * 60
        return (UInt32(truncatingIfNeeded: Int64(since1904)), UInt32(truncatingIfNeeded: Int64(ticks)))
    }

    /// `FastRand(n)`.
    public mutating func next(_ n: Int16) -> Int16 {
        guard n != 0 else {
            let c = clock()
            seed = Self.clockSeed(secondsSince1904: c.secondsSince1904, ticks: c.ticks)
            return 0
        }
        let s = UInt32(bitPattern: seed)
        let lo = (s & 0xffff) &* 0x41a7                              // r6
        let hi = (s >> 16) &* 0x41a7 &+ (lo >> 16)                   // r7
        let r5 = ((hi &+ hi) >> 16) & 0xffff                         // (2·r7) rotl 16 & 0xffff
        let h = hi & 0x7fff
        var r6 = (lo & 0xffff) &- 0x8000_0000 &+ 1                   // subis 0x8000, addi 1
        r6 = r6 &+ ((h << 16) &+ (h >> 16) &+ r5)
        if Int32(bitPattern: r6) < 0 { r6 = r6 &- 0x8000_0000 &- 1 }  // + 0x7fffffff
        seed = Int32(bitPattern: r6)
        var low = r6 & 0xffff
        if low == 0x8000 { low = 0 }
        let product = Int32(n) &* Int32(low)                         // mullw
        return Int16(truncatingIfNeeded: product >> 16)              // rlwinm 16,16,31 then extsh
    }

    /// The `.STPlay3DSoundRand` rate: `FastRand(10000) + 0x10000 − 0x1389` (raw `10047d60..10047d90`), drawn even
    /// with sound off (plan Invariant 4).
    public mutating func soundRate() -> Int32 {
        Int32(next(10000)) + 0xec77
    }
}
