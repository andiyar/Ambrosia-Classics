import Foundation

/// `.FindUpperLeftCorner @ 1000b5ec` (engine §5; decompile l. 5886–6233), transcribed. Two pairs of shorts:
/// - the eased camera `(h, v)` = `(_DAT_1009fd84 + 2, _DAT_1009fd84)`, never clamped;
/// - the scroll point `PTR_DAT_1009fe78` = `(scrollH, scrollV)`: the eased pair, then the even-v rule, then the clamps.
///
/// Each call: target h = focus x − 0x130 + hdr 0x270a, target v = focus y − 0xc0 + hdr 0x270c (the focus is
/// `(_DAT_1009fd44, _DAT_1009fd40)`, `.PlayerScroll`'s); the 16-px snap `t = (t >> 4) << 4` of the target h when
/// |player vx `_DAT_1009fd3c`| < 0x100 and `cRam100a5114` is set (the extra vetoes — riding platform 0x57a, the water
/// fields `+0x11c`/`+0x120`, auto-scroll modes 1–2, the one-shot `_DAT_1009fd34` — never hold in Phase 1); each axis
/// eases by `max(Δ / 6, 1)` (`* 0x2aaaaaab >> 32`, truncating); the scroll point takes the eased pair (no auto-scroll);
/// graphics 2 / 3 (prefs+2) force an even v; then `0 ≤ h ≤ 32·W − 0x280`, `0 ≤ v ≤ 32·H − 0x180` (`hdr+0xb280` /
/// `+0xb282`). The boss-arena bounds (hdr 0x2724 / 0x272e), auto-scroll (0x272a) and the shake counters
/// (`_DAT_1009ff9c`, `_DAT_1009ffa0`) are not built in Phase 1: a level with an arena bound or auto-scroll is refused.
/// `.MTHandlePxSprites`, called at the end, is the caller's (level 1 has no strip).
///
/// Start (`.GameLoop` l. 5168–5195): the eased pair and the scroll point are set to the sprite origin − 0xd0
/// (x − 208, y − 208), so the view pans in from there.
public struct Camera: Equatable, Sendable {
    public enum Error: Swift.Error, Equatable {
        /// hdr 0x2724 ≠ 0: the boss-arena bounds (not built in Phase 1).
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
    /// `_DAT_1009fd84 + 2` / `_DAT_1009fd84`.
    public private(set) var h: Int
    public private(set) var v: Int
    /// `PTR_DAT_1009fe78 + 2` / `PTR_DAT_1009fe78`.
    public private(set) var scrollH: Int
    public private(set) var scrollV: Int

    /// The camera `.GameLoop` sets up for a sprite origin (x, y) = (hdr 0x2848 − 0x20, hdr 0x2846 − 0x20).
    public init(header: LevelHeader, spriteX: Int, spriteY: Int) throws {
        guard header.arenaBound == 0 else { throw Error.arenaBound(header.arenaBound) }
        guard header.autoScrollEnable == 0 else { throw Error.autoScroll(header.autoScrollEnable) }
        offsetX = Int(header.cameraOffsetX)
        offsetY = Int(header.cameraOffsetY)
        maxH = Int(header.gridWidth) * 0x20 - 0x280
        maxV = Int(header.gridHeight) * 0x20 - 0x180
        h = spriteX - 0xd0
        v = spriteY - 0xd0
        scrollH = h
        scrollV = v
    }

    /// One `.FindUpperLeftCorner`. `snapArmed` is `cRam100a5114` (set by every player Handle, cleared while the
    /// look-ahead decays against the facing); `graphics` is prefs+2.
    public mutating func findUpperLeftCorner(focusX: Int, focusY: Int, playerVX: Int = 0, snapArmed: Bool = true,
                                             graphics: Int16 = 1) {
        var tx = Int(Int16(truncatingIfNeeded: focusX - Self.focusOffsetX + offsetX))
        let ty = Int(Int16(truncatingIfNeeded: focusY - Self.focusOffsetY + offsetY))
        if abs(playerVX) < 0x100 && snapArmed {
            tx = (tx >> 4) << 4
        }
        h = Self.ease(h, toward: tx)
        v = Self.ease(v, toward: ty)
        scrollH = h
        scrollV = v
        if graphics == 3 || graphics == 2 {
            scrollV = (scrollV >> 1) << 1
        }
        // Arena bounds (−32000 / 32000 without an arena): h < −32000 → −32000; h > 32000 − 0x260 → that.
        if scrollH < -32000 { scrollH = -32000 }
        if scrollH > 32000 - 0x260 { scrollH = 32000 - 0x260 }
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
    }

    /// `max(|Δ| / 6, 1)` toward the target (no move when equal).
    static func ease(_ c: Int, toward t: Int) -> Int {
        if c < t { return c + max((t - c) / 6, 1) }
        if t < c { return c - max((c - t) / 6, 1) }
        return c
    }
}
