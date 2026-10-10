import Foundation

/// `.InitTileHotRects @ 10002824` (decompile l. 1299–1395; physics §3.2): the 0x14-byte entries at `DAT_100a4794`.
/// Rects are QuickDraw (top, left, bottom, right) in tile-local px; the dump's `SetRect(r, l, t, r, b)` order is
/// translated here.
///
/// - `perTile[t]` = entry `t`'s `+4` rect, for FG tile 0…95, chosen by `kind(t) mod 100` (the `while (k > 99) k −= 100`
///   loop; a negative kind takes the full rect). `.SeparateFromTiles2` reads it by **tile**; `.WallBounce` /
///   `.WallBounceBG` read it by **kind** (`mulli r3,k,0x14`, raw `10037b8c..10037bc0`) — the as-written quirk of
///   player-states-2 §14 item 1, kept by indexing this one table with both.
/// - `perKind[k]` = entry `k`'s `+0xc` rect, kind 0…63 — read only by `.SeparateFromTiles2`'s dead second loop
///   (`+0xe4`, raw `1003ce74..1003cea0`); built for fidelity, unused.
/// - The third table (`DAT_100a4314`, 96 × 0xc bytes, inset 6 px for 3…5 else 2 px) has no reader (physics §3.2) and is
///   not kept.
public struct TileHotRects: Equatable, Sendable {
    public typealias Rect = IdleSprites.Rect

    public let perTile: [Rect]
    public let perKind: [Rect]

    /// `fgKind(t)` = `.LookupFGTileKind(t)` (the level's runtime FG table; −1 outside 0…95).
    public init(fgKind: (Int) -> Int) {
        // `SetRect(r, l, t, r, b)`.
        func set(_ l: Int, _ t: Int, _ r: Int, _ b: Int) -> Rect { Rect(top: t, left: l, bottom: b, right: r) }
        var tiles: [Rect] = []
        tiles.reserveCapacity(96)
        for t in 0..<0x60 {
            var k = fgKind(t)
            while k > 99 { k -= 100 }
            switch k {
            case 0: tiles.append(set(0, 0, 0x10, 0x20))
            case 1: tiles.append(set(0, 0, 0x20, 0x10))
            case 2: tiles.append(set(0x10, 0, 0x20, 0x20))
            case 3: tiles.append(set(0, 0x10, 0x20, 0x30))
            case 4: tiles.append(set(0, 0x10, 0x10, 0x20))
            case 5: tiles.append(set(0, 0, 0x10, 0x10))
            case 6: tiles.append(set(0x10, 0, 0x20, 0x10))
            case 7: tiles.append(set(0x10, 0x10, 0x20, 0x30))
            case 0x2d: tiles.append(set(0, 0, 0x10, 0x30))
            case 0x2f: tiles.append(set(0x10, 0, 0x20, 0x30))
            default: tiles.append(set(0, 0, 0x20, 0x30))              // `LAB_10002a18`: < 0, 8…0x2c, 0x2e, ≥ 0x30
            }
        }
        var kinds: [Rect] = []
        kinds.reserveCapacity(0x40)
        for k in 0..<0x40 {
            switch k {
            case 0: kinds.append(set(0, 0, 0x10, 0x20))
            case 1: kinds.append(set(0, 0, 0x20, 0x10))
            case 2: kinds.append(set(0x10, 0, 0x20, 0x20))
            case 3: kinds.append(set(0, 0x10, 0x20, 0x20))
            case 4: kinds.append(set(0, 0x10, 0x10, 0x20))
            case 5: kinds.append(set(0, 0, 0x10, 0x10))
            case 6: kinds.append(set(0x10, 0, 0x20, 0x10))
            case 7: kinds.append(set(0x10, 0x10, 0x20, 0x20))
            default: kinds.append(set(0, 0, 0x20, 0x20))
            }
        }
        perTile = tiles
        perKind = kinds
    }

    /// The level's table (`.LoadTileDefinitions` then `.InitTileHotRects`).
    public init(level: LevelFile) {
        self.init(fgKind: { level.fgKind(tile: $0) })
    }
}
