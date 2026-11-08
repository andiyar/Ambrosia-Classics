import Foundation

/// The boss-arena globals (bosses §1.2–§1.3; LV5): what `.SetupLevelSprites`, a boss Setup and Kill,
/// `.PlayerConstraints`, `.FindUpperLeftCorner`, the gate 2940's p1 −1 arm and `.GameLoop`'s boss-music rule share.
/// - `noBossAlive` — `*_DAT_1009fed0` (u8): `.SetupLevelSprites` sets it 1 before spawning (M l. 2019); a boss Setup
///   with its boss flag (record p4) set writes 0 (the Warrior, M l. 73035–73042); the boss Kill writes 1 again
///   (`.KillWarrior` M l. 73490–73492 // later: Phase 6).
/// - `locked` — `*PTR_DAT_1009fed4` (u8), the arena lock: cleared by `.SetupLevelSprites` (M l. 2016), set by
///   `.PlayerConstraints` (M l. 44036–44056).
/// - `panCounter` — `*_DAT_1009ff9c` (i16), the camera pan: `.PlayerConstraints` stores −40 on the lock (M l. 44048);
///   `.FindUpperLeftCorner` counts it up while negative and shifts both scroll bounds by 16·|counter| (M l. 6011–6028);
///   zeroed by `.InitGameGlobals` (M l. 806, 822) and by nothing else, so it runs on across levels
///   (`LevelCarry.panCounter`, LV5 fix round).
public struct BossArena: Equatable, Sendable {
    public var noBossAlive: UInt8 = 1
    public var locked = false
    public var panCounter: Int16 = 0

    public init(noBossAlive: UInt8 = 1, locked: Bool = false, panCounter: Int16 = 0) {
        self.noBossAlive = noBossAlive
        self.locked = locked
        self.panCounter = panCounter
    }

    /// `.SetupLevelSprites`' arena writes before its passes (M l. 2016–2019): `fed4 = 0`, `fed0 = 1`.
    public mutating func setupLevelSprites() {
        locked = false
        noBossAlive = 1
    }

    /// `|v + 60|` (v < 0) / `|v − 60|` (v > 0) — `.PlayerConstraints`' lock line for hdr `+0x2724` = v (i16 sum, then
    /// `neg` when < 1).
    static func lockLine(_ v: Int16) -> Int32 {
        let s = v < 0 ? v &+ 0x3c : v &- 0x3c
        return s < 1 ? -Int32(s) : Int32(s)
    }

    /// `.PlayerConstraints`' arena part (M l. 44035–44100; raw `1004cc10..1004cd8c`) for hdr `+0x2724` = `v` on the
    /// player's x `+0xc`: with `v ≠ 0` and `noBossAlive == 0` — v < 0: x < |v + 60| → (unlocked: the pan counter −40)
    /// lock; else locked with x > |v + 60| → x = |v + 60|; v > 0 the mirror (x > |v − 60| locks, x < it clamps once
    /// locked). Returns the clamped x (the caller stores `+0x14 = x << 8`), nil when x is left alone.
    public mutating func playerConstraints(arenaBound v: Int16, x: Int16) -> Int16? {
        guard v != 0, noBossAlive == 0 else { return nil }
        let line = Self.lockLine(v)
        let px = Int32(x)
        let entering = v < 0 ? px < line : line < px
        if entering {
            if !locked { panCounter = -0x28 }
            locked = true
            return nil
        }
        let beyond = v < 0 ? line < px : px < line
        guard beyond, locked else { return nil }
        return Int16(truncatingIfNeeded: line)
    }

    /// `.FindUpperLeftCorner`'s bounds on the scroll point's h (M l. 5937–6028): `lo` (`sVar25`) and `hi` (`sVar26`),
    /// applied as `h < lo → lo`, `h > hi − 0x260 → hi − 0x260` (M l. 6168–6173) before the map clamp. Without an arena
    /// (v = 0 or `noBossAlive` ≠ 0) −32000 / 32000. v < 0: unlocked lo = |v|; locked hi = |v|, lo = |v| − 0x260 while
    /// the pan counter (read before this call's step) is negative, else −32000, then a second bound s = hdr `+0x272e` ≠
    /// 0 with lo ≤ |s| → lo = |s|. v > 0: unlocked hi = |v|; locked lo = |v|, hi = 0x7f60 (counter < 0) / 32000, then
    /// |s| ≤ hi → hi = |s|. Then the pan step (whatever the arena): counter < 0 → counter + 1, and both bounds shift by
    /// 16·|counter| (the stepped value; i16 sums) — up for v < 0, down otherwise.
    public mutating func cameraBounds(arenaBound v: Int16, secondBound s: Int16) -> (lo: Int16, hi: Int16) {
        var hi: Int16 = 32000, lo: Int16 = -32000
        let a = v < 1 ? 0 &- v : v
        let second = Int32(s < 1 ? 0 &- s : s)
        if v != 0 && noBossAlive == 0 {
            if v < 0 {
                if !locked {
                    hi = 32000
                    lo = a
                } else {
                    lo = panCounter < 0 ? a &- 0x260 : -32000
                    hi = a
                    if s != 0, Int32(lo) <= second { lo = s < 1 ? 0 &- s : s }
                }
            } else if !locked {
                hi = a
                lo = -32000
            } else {
                hi = panCounter < 0 ? 0x7f60 : 32000
                lo = a
                if s != 0, second <= Int32(hi) { hi = s < 1 ? 0 &- s : s }
            }
        }
        if panCounter < 0 {
            panCounter &+= 1
            let shift = Int16(truncatingIfNeeded: Int32(abs(Int32(panCounter))) << 4)
            if v < 0 {
                hi &+= shift
                lo &+= shift
            } else {
                hi &-= shift
                lo &-= shift
            }
        }
        return (lo, hi)
    }
}
