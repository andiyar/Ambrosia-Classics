import Foundation

/// The tile maps and kind tables the tile solver reads (`.GetFGTile`, `.GetBGTile`, `.GetFGCrunchDirTile`,
/// `.LookupFGTileKind`, `.LookupBGTileKind`; world-data §3.3). Reads take (column, row) clamped into the map as
/// `.ConstrainXY` does (`TileMap.cell`). Built from a level, or synthetic for tests.
public struct TileGrid: Sendable, Equatable {
    public var fg: TileMap
    public var bg: TileMap
    /// The runtime FG kind table, tile 0…95 (`_DAT_100a0218`: header 0x28e0 with 0x50…0x5f = the tile number).
    public var fgKinds: [Int]
    /// The BG kind table, tile 0…95 (`_DAT_100a0214`: header 0x29a0).
    public var bgKinds: [Int]

    public init(fg: TileMap, bg: TileMap, fgKinds: [Int], bgKinds: [Int]) {
        precondition(fgKinds.count == 0x60 && bgKinds.count == 0x60, "TileGrid kind tables are 96 entries")
        self.fg = fg
        self.bg = bg
        self.fgKinds = fgKinds
        self.bgKinds = bgKinds
    }

    public init(level: LevelFile) {
        self.init(fg: level.fg, bg: level.bg, fgKinds: (0..<0x60).map { level.fgKind(tile: $0) },
                  bgKinds: (0..<0x60).map { level.bgKind(tile: $0) })
    }

    /// `.GetFGTile`: bits 0–7 − 1 (−1 = none).
    public func fgTile(col: Int, row: Int) -> Int { Int(fg.cell(col: col, row: row) & 0xff) - 1 }
    /// `.GetBGTile`: low byte − 1 (−1 = none).
    public func bgTile(col: Int, row: Int) -> Int { Int(bg.cell(col: col, row: row) & 0xff) - 1 }
    /// `.GetFGCrunchDirTile @ 1003bf40`: bits 12–15 of the FG cell.
    public func crunchDir(col: Int, row: Int) -> Int { Int(fg.cell(col: col, row: row) >> 12) }
    /// `.LookupFGTileKind @ 10041fe8`: −1 outside 0…0x5f.
    public func fgKind(tile: Int) -> Int { (0..<0x60).contains(tile) ? fgKinds[tile] : -1 }
    /// `.LookupBGTileKind @ 10041f98`: −1 outside 0…0x5f (so an empty BG cell, tile −1, has kind −1).
    public func bgKind(tile: Int) -> Int { (0..<0x60).contains(tile) ? bgKinds[tile] : -1 }
}

/// A tile cell's top-left in world px — the `(Y, X)` point `.SeparateFromTiles2` passes the tile callback by value
/// (`CONCAT22(cellY, cellX)`) and the callback passes on to `.WallBounce` by address (`param_3`).
public struct TilePos: Equatable, Sendable {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) { self.x = x; self.y = y }
}

/// The tile callback's last argument (`FUN_1009f80c(s, pos, kind, layer)`, physics §3.1).
public enum TileLayer: Int, Equatable, Sendable {
    /// BG kind (`layer 0`; every non-zero kind, −1 included).
    case background = 0
    /// FG kind (`layer 1`).
    case foreground = 1
    /// A crunch-direction nibble (`layer 2`; the `kind` argument is the nibble).
    case crunch = 2
}

/// A sprite's tile callback `+0x1f8` (`.HitPlayerTileSprite`, … — one per handler, written by the task that builds the
/// handler). Arguments: the solver, the sprite, the cell, the kind (or crunch nibble) and the layer.
public typealias TileHit = (TileSolver, _ id: Int, _ cell: TilePos, _ kind: Int, _ layer: TileLayer) -> Void

/// The tile solver (plan S2, F3; physics §2–§3, player-states-2 §9–§14): `.SeparateFromTiles2`, `.WallBounce`,
/// `.WallBounceBG` and the integration helpers that call them. It reads and writes the sprites of `world` in place,
/// and reads the world's one tile map `world.tiles` (F3 review: no private copy — P2's `.CrunchTile` writes the same
/// map the next separation reads).
///
/// ⚠️ Exclusivity (see `SpriteWorld`): never call a solver routine from inside `world.active.update(id:) { … }` (a
/// run-time exclusivity trap), and never write back a `SpriteSlot` copy taken before a solver call (it silently
/// undoes the solver and its tile callbacks). Tile callbacks are called outside any `update` closure, so they may
/// read and write `world` freely; the solver re-reads the sprite after each callback and recursion.
public final class TileSolver {
    public let world: SpriteWorld
    /// `DAT_100a4794`, built from the kind tables of `world.tiles` at init (`.InitTileHotRects` runs once per level,
    /// after `.LoadTileDefinitions`; the kind tables do not change during play — a crunch changes cells, not kinds).
    public let hotRects: TileHotRects

    public init(world: SpriteWorld) {
        self.world = world
        let kinds = world.tiles
        hotRects = TileHotRects(fgKind: kinds.fgKind(tile:))
    }

    /// `(short)v`: the 16-bit truncation the dump applies to every coordinate sum (`extsh`).
    @inline(__always) static func short16(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }

    /// Every sprite write of the solver goes through here (bumps `world.solverWrites`, the hazard-2 debug aid).
    @inline(__always) func put(_ id: Int, _ body: (inout SpriteSlot) -> Void) {
        world.active.update(id: id, body)
        world.solverWrites &+= 1
    }

    /// `.SeparateFromTiles2 @ 1003c804` (decompile l. 35130ff.; raw `1003c804..1003cec8`; physics §3.1):
    /// 1. **At entry, every call**: `+0x8 = +0xc = (i16)(+0x14 >> 8)`, `+0x6 = +0xa = (i16)(+0x1c >> 8)` (raw
    ///    `1003c82c..1003c844`); `+0x181 = 0`. Without a tile callback (`+0x1f8 == 0`, `pass == nil`) nothing else.
    /// 2. The hot rect `(y + top, x + left, y + bottom, x + right)` is built **once**, before the loop (stack `0x7a`,
    ///    raw `1003c878..1003c8b4`), and is not refreshed when a callback moves the sprite (Bank correction A12).
    /// 3. Cell (c, r) = hot-rect centre / 32 (i16, C division: `srawi 5; addze`); visited (c,r), (c−1,r−1), (c,r−1),
    ///    (c+1,r−1), (c−1,r), (c+1,r), (c−1,r+1), (c,r+1), (c+1,r+1).
    /// 4. Per cell (X = 32c, Y = 32r, i16): FG tile t, kind `.LookupFGTileKind(t)` ≠ −1 and the rect meets the tile's
    ///    hot rect (`perTile[t]` at (X, Y)) → if `+0xeb` (re-read per cell): for the 2×2 cells (c−1…c, r−1…r), column
    ///    outer, every crunch nibble > 0 whose 32×32 box at (+16, +16) meets the rect → `callback(cell, nibble, 2)`;
    ///    then `callback((X, Y), kind, 1)`. BG kind ≠ 0 (−1 included) and the rect meets the full 32×32 cell →
    ///    `callback((X, Y), kind, 0)`.
    /// 5. The second 9-cell loop under `+0xe4` computes rects and discards them (dead, physics §3.1) — not built.
    ///
    /// - Parameter pass: the sprite's tile callback `+0x1f8` (nil = 0). // later: the handlers' callbacks (P2
    ///   `.HitPlayerTileSprite`, W1–W3 movers) — the crunch nibble's `.CrunchTile` is P2's, reached through them.
    public func separateFromTiles(_ id: Int, pass: TileHit?) {
        let h = Self.short16
        guard var s = world.active.sprite(id: id) else { return }
        let px = SpriteWorld.pixel(s.x256), py = SpriteWorld.pixel(s.y256)
        s.oldPosition = SpriteSlot.Point(x: px, y: py)
        s.x = px
        s.y = py
        s.slideLatch = false
        put(id) { $0 = s }
        guard let pass else { return }

        let r = s.hotRect
        let rect = IdleSprites.Rect(top: h(s.y + r.top), left: h(s.x + r.left), bottom: h(s.y + r.bottom),
                                    right: h(s.x + r.right))
        let c = h(s.x + r.left + ((r.right - r.left) >> 1)) / 32       // `srawi 5; addze`: C division
        let row = h(s.y + r.top + ((r.bottom - r.top) >> 1)) / 32
        let cells = [(c, row), (c - 1, row - 1), (c, row - 1), (c + 1, row - 1), (c - 1, row), (c + 1, row),
                     (c - 1, row + 1), (c, row + 1), (c + 1, row + 1)]
        for (col, rw) in cells {
            let X = h(col << 5), Y = h(rw << 5)
            let fgTile = world.tiles.fgTile(col: col, row: rw)
            let bgTile = world.tiles.bgTile(col: col, row: rw)
            let fgKind = Int(Int16(truncatingIfNeeded: world.tiles.fgKind(tile: fgTile)))
            let bgKind = Int(Int16(truncatingIfNeeded: world.tiles.bgKind(tile: bgTile)))
            if fgKind != -1 {
                let e = hotRects.perTile[fgTile]
                let tileRect = IdleSprites.Rect(top: h(Y + e.top), left: h(X + e.left), bottom: h(Y + e.bottom),
                                                right: h(X + e.right))
                if rect.intersects(tileRect) {
                    if (world.active.sprite(id: id)?.crunches ?? 0) != 0 {
                        for i in 0..<2 {
                            let cc = col - 1 + i
                            let cx = h(cc << 5)
                            for j in 0..<2 {
                                let rr = rw - 1 + j
                                let cy = h(rr << 5)
                                let dir = Int(Int16(truncatingIfNeeded: world.tiles.crunchDir(col: cc, row: rr)))
                                guard dir > 0 else { continue }
                                let box = IdleSprites.Rect(top: h(cy + 0x10), left: h(cx + 0x10), bottom: h(cy + 0x30),
                                                           right: h(cx + 0x30))
                                if rect.intersects(box) { pass(self, id, TilePos(x: cx, y: cy), dir, .crunch) }
                            }
                        }
                    }
                    pass(self, id, TilePos(x: X, y: Y), fgKind, .foreground)
                }
            }
            if bgKind != 0 {
                let full = IdleSprites.Rect(top: Y, left: X, bottom: h(Y + 0x20), right: h(X + 0x20))
                if rect.intersects(full) { pass(self, id, TilePos(x: X, y: Y), bgKind, .background) }
            }
        }
    }
}
