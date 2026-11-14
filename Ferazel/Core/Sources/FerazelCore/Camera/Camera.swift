import Foundation

/// `.FindUpperLeftCorner @ 1000b5ec` (engine §5; decompile l. 5886–6233), transcribed. Two pairs of shorts:
/// - the eased camera `(h, v)` = `(_DAT_1009fd84 + 2, _DAT_1009fd84)`, never clamped;
/// - the scroll point `PTR_DAT_1009fe78` = `(scrollH, scrollV)`: the eased pair, then the even-v rule, then the clamps.
///
/// Each call: target h = focus x − 0x130 + hdr 0x270a, target v = focus y − 0xc0 + hdr 0x270c (the focus is
/// `(_DAT_1009fd44, _DAT_1009fd40)`, `.PlayerScroll`'s); the 16-px snap `t = (t >> 4) << 4` of the target h when
/// |player vx `_DAT_1009fd3c`| < 0x100 and `cRam100a5114` is set, unless vetoed (raw `1000b894..1000b944`, l. 6037–6050): the
/// player `*_DAT_1009fdd8` rides (`+0xdc`) a sprite of type 0x57a, its water fields `+0x11c`/`+0x120` are non-zero,
/// auto-scroll modes 1–2 (refused here), or the one-shot `*_DAT_1009fd34` is set — which this test clears (P5); each axis
/// eases by `max(Δ / 6, 1)` (`* 0x2aaaaaab >> 32`, truncating); the scroll point takes the eased pair (no auto-scroll);
/// graphics 2 / 3 (prefs+2) force an even v; then `0 ≤ h ≤ 32·W − 0x280`, `0 ≤ v ≤ 32·H − 0x180` (`hdr+0xb280` /
/// `+0xb282`). LV5: the boss-arena bounds (hdr 0x2724 / 0x272e, `BossArena.cameraBounds`, M l. 5937–6028) clamp the
/// scroll point's h before the map clamp (M l. 6168–6173). Auto-scroll (0x272a) is not built: a level with auto-scroll
/// is refused. EF: the shake `_DAT_1009ffa0` (`shake`), applied to the scroll point's v before the even-v rule.
/// `.MTHandlePxSprites`, called at the end, is the caller's (level 1 has no strip).
///
/// Start (`.GameLoop` l. 5168–5195): the eased pair and the scroll point are set to the sprite origin − 0xd0
/// (x − 208, y − 208), so the view pans in from there.
public struct Camera: Equatable, Sendable {
    public enum Error: Swift.Error, Equatable {
        /// hdr 0x2724 ≠ 0: the boss-arena bounds — refused until LV5 built them; no longer thrown (the case is kept,
        /// Invariant 9).
        case arenaBound(Int16)
        /// hdr 0x272a ≠ 0: auto-scroll (not built in Phase 1).
        case autoScroll(Int16)
    }

    /// target = focus − (0x130, 0xc0) + the header offsets.
    public static let focusOffsetX = 0x130
    public static let focusOffsetY = 0xc0

    /// hdr 0x270a / 0x270c.
    public let offsetX: Int
    public let offsetY: Int
    /// `32·W − 0x280`, `32·H − 0x180`.
    public let maxH: Int
    public let maxV: Int
    /// LV5: hdr 0x2724 / 0x272e, the arena bounds `BossArena.cameraBounds` reads.
    public let arenaBound: Int16
    public let secondArenaBound: Int16
    /// `_DAT_1009fd84 + 2` / `_DAT_1009fd84`.
    public private(set) var h: Int
    public private(set) var v: Int
    /// `PTR_DAT_1009fe78 + 2` / `PTR_DAT_1009fe78`.
    public private(set) var scrollH: Int
    public private(set) var scrollV: Int
    /// EF: `*_DAT_1009ffa0`, the screen shake (engine §5). Zeroed by `.InitGameGlobals` (M l. 821) and by nothing else;
    /// writers set it (the seed explosion 0x14, M l. 51150 — built, `SpriteWorld.shakeStore`; the bosses 0x1e / 0x16,
    /// M l. 73488…77475 — the Warrior's built in 6A-W2, `Warrior.kill`; the others // later: Phase 6);
    /// `FindUpperLeftCorner` counts it down (M l. 6161). A shake still running at
    /// a level end runs on into the next level (`LevelCarry.shake`, EF review fix); the flow zeroes it in
    /// `GameFlow.initGameGlobals`.
    public var shake: Int16 = 0

    /// The camera `.GameLoop` sets up for a sprite origin (x, y) = (hdr 0x2848 − 0x20, hdr 0x2846 − 0x20).
    public init(header: LevelHeader, spriteX: Int, spriteY: Int) throws {
        guard header.autoScrollEnable == 0 else { throw Error.autoScroll(header.autoScrollEnable) }
        offsetX = Int(header.cameraOffsetX)
        offsetY = Int(header.cameraOffsetY)
        maxH = Int(header.gridWidth) * 0x20 - 0x280
        maxV = Int(header.gridHeight) * 0x20 - 0x180
        arenaBound = header.arenaBound
        secondArenaBound = header.secondArenaBound
        h = spriteX - 0xd0
        v = spriteY - 0xd0
        scrollH = h
        scrollV = v
    }

    /// The ridden type that vetoes the snap (`+4 == 0x57a`, l. 6040).
    public static let snapVetoRiddenType: Int16 = 0x57a

    /// One `.FindUpperLeftCorner`. `snapArmed` is `cRam100a5114` (set by every player Handle, cleared while the
    /// look-ahead decays against the facing); it defaults to true, including before any Handle has run (the level-start
    /// call and iteration 1, whose initial value is unread) — no level-1 effect: both targets clamp to h = 0 either
    /// way. `graphics` is prefs+2. The snap vetoes (P5): `ridingVeto` = the player's ridden sprite is a 0x57a,
    /// `inWater` = its `+0x11c` or `+0x120` ≠ 0, `latch` = `*_DAT_1009fd34`.
    /// EF: `counter` is the paint counter `*_DAT_1009fd2c` (`SpriteWorld.paintCounter`), `reduceFrameRate` prefs+0 —
    /// the shake's parity test (below).
    /// - Returns: `*_DAT_1009fd34` after the call — cleared when the snap test ran (|vx| < 0x100 and armed), else as
    ///   passed.
    @discardableResult
    public mutating func findUpperLeftCorner(focusX: Int, focusY: Int, playerVX: Int = 0, snapArmed: Bool = true,
                                             ridingVeto: Bool = false, inWater: Bool = false, latch: Bool = false,
                                             counter: UInt32 = 0, reduceFrameRate: Bool = false,
                                             graphics: Int16 = 1) -> Bool {
        var none = BossArena()
        return findUpperLeftCorner(focusX: focusX, focusY: focusY, playerVX: playerVX, snapArmed: snapArmed,
                                   ridingVeto: ridingVeto, inWater: inWater, latch: latch, counter: counter,
                                   reduceFrameRate: reduceFrameRate, graphics: graphics, arena: &none)
    }

    /// LV5: the call with the arena globals (`BossArena`): the bounds and the pan step first (M l. 5937–6028), the clamp
    /// of the scroll point's h to them after the even-v rule (M l. 6168–6173).
    @discardableResult
    public mutating func findUpperLeftCorner(focusX: Int, focusY: Int, playerVX: Int = 0, snapArmed: Bool = true,
                                             ridingVeto: Bool = false, inWater: Bool = false, latch: Bool = false,
                                             counter: UInt32 = 0, reduceFrameRate: Bool = false,
                                             graphics: Int16 = 1, arena: inout BossArena) -> Bool {
        let (lo, hi) = arena.cameraBounds(arenaBound: arenaBound, secondBound: secondArenaBound)
        var tx = Int(Int16(truncatingIfNeeded: focusX - Self.focusOffsetX + offsetX))
        let ty = Int(Int16(truncatingIfNeeded: focusY - Self.focusOffsetY + offsetY))
        var latchOut = latch
        if abs(playerVX) < 0x100 && snapArmed {
            // Auto-scroll modes 1–2 (`*_DAT_1009fec4`, `_DAT_1009fec0`) would veto too: refused by `init`.
            let snap = !ridingVeto && !inWater && !latch
            latchOut = false
            if snap { tx = (tx >> 4) << 4 }
        }
        h = Self.ease(h, toward: tx)
        v = Self.ease(v, toward: ty)
        scrollH = h
        scrollV = v
        // The shake (M l. 6147–6161): while `_DAT_1009ffa0` > 0, the counter `& 1` (`& 3` with prefs+0 set) == 0 →
        // v −= shake >> 1, else v += shake >> 1 (`srawi`, i16 stores); shake − 1.
        if 0 < shake {
            let parity = reduceFrameRate ? counter & 3 : counter & 1
            let d = Int(shake >> 1)
            scrollV = Int(Int16(truncatingIfNeeded: parity == 0 ? scrollV - d : scrollV + d))
            shake &-= 1
        }
        if graphics == 3 || graphics == 2 {
            scrollV = (scrollV >> 1) << 1
        }
        // Arena bounds (−32000 / 32000 without an arena): h < lo → lo; h > hi − 0x260 → that (i16 store).
        if scrollH < Int(lo) { scrollH = Int(lo) }
        if Int(hi) - 0x260 < scrollH { scrollH = Int(Int16(truncatingIfNeeded: Int(hi) - 0x260)) }
        if scrollH < 0 {
            scrollH = 0
        } else if scrollH > maxH {
            scrollH = maxH
        }
        if scrollV < 0 {
            scrollV = 0
        } else if scrollV > maxV {
            scrollV = maxV
        }
        return latchOut
    }

    /// The passage jump's snap (`.HitPlayerSprite` l. 49659–49664, W2b): the eased pair `_DAT_1009fd84` and the scroll
    /// point `PTR_DAT_1009fe78` both set to (player x − 0x142, player y − 0xc0) as i16 — no clamp (the caller's
    /// 90 `.FindUpperLeftCorner` passes then ease and clamp).
    public mutating func snap(playerX: Int, playerY: Int) {
        h = Int(Int16(truncatingIfNeeded: playerX - 0x142))
        v = Int(Int16(truncatingIfNeeded: playerY - 0xc0))
        scrollH = h
        scrollV = v
    }

    /// `max(|Δ| / 6, 1)` toward the target (no move when equal).
    static func ease(_ c: Int, toward t: Int) -> Int {
        if c < t { return c + max((t - c) / 6, 1) }
        if t < c { return c - max((c - t) / 6, 1) }
        return c
    }
}
