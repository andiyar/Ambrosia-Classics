/// One tile record — the 0x28-byte block `_AddTile` @ 0x146bc mallocs (docs/aki/rules.md §1.1).
/// Coordinates are in HALF-UNITS (tile+0x10 = 2x, tile+0x08 = 2y); a tile is 2 × 2 half-units.
public struct Tile: Equatable, Sendable {                                         // P2.2
    /// tile+0x10 (x), tile+0x08 (y) in half-units; tile+0x00 layer, 0 = bottom … 6 = top.
    public var x: Int, y: Int, z: Int
    /// tile+0x02, 200…241 once dealt (`_ShuffleCustomTiles`); 0 until then.
    public var face: Int
    /// tile+0x04, 0…10 during the match fade (`_RedrawMatchedTiles`).
    public var fadeFrame: Int
    /// tile+0x18 open, +0x19 visible, +0x1a hint, +0x1b selected, +0x1c removed, +0x1d fading.
    public var isOpen: Bool, isVisible: Bool, isHinted: Bool, isSelected: Bool, isRemoved: Bool, isFading: Bool

    /// `_AddTile` initialises visible = 1 and every other field to 0.
    public init(x: Int, y: Int, z: Int) {                                         // P2.2
        self.x = x; self.y = y; self.z = z
        face = 0; fadeFrame = 0
        isOpen = false; isVisible = true; isHinted = false; isSelected = false; isRemoved = false; isFading = false
    }
}

/// The game board: the `_gCGFirstPtr` … `_gCGLastPtr` tile list in list order, plus the layout's draw
/// offsets g+0x94 (subtracted from tile x pixels) and g+0x98 (added to tile y pixels).
public struct Board: Equatable, Sendable {
    public var tiles: [Tile]                                                      // P2.2
    public var offsetX: Int, offsetY: Int                                         // P2.2

    /// `_LoadLayout` → `_LayoutN`: one `_AddTile(x, y, L)` per placement, in call order (rules §1.1–§1.2).
    /// The placements already carry the half-units `_AddTile` stores; z = 7 − L.
    public init(layout: Layout) {                                                 // P2.2
        tiles = layout.placements.map { Tile(x: $0.x2, y: $0.y2, z: 7 - $0.layerArg) }
        offsetX = layout.offsetX
        offsetY = layout.offsetY
    }

    /// The match test of `_SelectCGTile` @ 0x13eec (rules §4.2), shared by `_CountOpenPairs` and
    /// `_ShowNextCGHint`: identical faces, or both among the eight seasons 205…212 — the original's
    /// `(ushort)(face − 0xcd) < 8`, so a face below 205 wraps high and never counts as a season.
    public static func matches(_ a: Int, _ b: Int) -> Bool {                      // P2.2
        a == b || (isSeason(a) && isSeason(b))
    }

    private static func isSeason(_ face: Int) -> Bool { (0..<8).contains(face - 205) }

    /// `_SetVisibleTiles` @ 0x12328 (rules §2): a tile is covered iff some NOT-removed tile lies exactly one
    /// layer above with |Δx| ≤ 1 and |Δy| ≤ 1 half-units. Only z + 1 is examined (a gap layer leaves the tile
    /// visible). Removed tiles are processed too; their flag is never read.
    public mutating func setVisibleTiles() {                                      // P2.2
        let snapshot = tiles
        for i in tiles.indices {
            let t = snapshot[i]
            tiles[i].isVisible = !snapshot.contains { u in
                !u.isRemoved && u.z == t.z + 1 && abs(u.x - t.x) <= 1 && abs(u.y - t.y) <= 1
            }
        }
    }

    /// `_SetOpenTiles` @ 0x1245e (rules §3): open := visible AND (no not-removed same-layer tile at x − 2 with
    /// |Δy| ≤ 1, OR none at x + 2 with |Δy| ≤ 1). The neighbour need not be visible; x ± 1 never blocks.
    public mutating func setOpenTiles() {                                         // P2.2
        let snapshot = tiles
        for i in tiles.indices {
            let t = snapshot[i]
            guard t.isVisible else { tiles[i].isOpen = false; continue }
            func blocked(atX x: Int) -> Bool {
                snapshot.contains { u in !u.isRemoved && u.z == t.z && u.x == x && abs(u.y - t.y) <= 1 }
            }
            tiles[i].isOpen = !blocked(atX: t.x - 2) || !blocked(atX: t.x + 2)
        }
    }

    /// The hit box of tile `index` (rules §7) — see `pixelBox(of:offsetX:offsetY:)`.
    public func pixelBox(of index: Int) -> QDRect {                               // P2.2
        Board.pixelBox(of: tiles[index], offsetX: offsetX, offsetY: offsetY)
    }

    /// `_SelectCGTile` @ 0x13eec pixel box (rules §7): left = (short)(int)(46.0·x·0.5) + 5z − g+0x94,
    /// top = (short)(int)(55.0·y·0.5) − 10z + g+0x98; hit iff left ≤ h ≤ left + 50 and top ≤ v ≤ top + 59,
    /// returned as the half-open QDRect (left, top, left + 51, top + 60). The (int) cast truncates toward
    /// zero (27.5 · 15 = 412.5 → 412). Static so fade snapshots can place tiles no longer on the board.
    public static func pixelBox(of tile: Tile, offsetX: Int, offsetY: Int) -> QDRect {   // P2.2
        let left = 23 * tile.x + 5 * tile.z - offsetX
        let top = Int((27.5 * Double(tile.y)).rounded(.towardZero)) - 10 * tile.z + offsetY
        return QDRect(left: left, top: top, right: left + 51, bottom: top + 60)
    }

    /// `_RedrawMatchedTiles` @ 0x13af5 step 2 (rules §8): `_DeleteTile` every tile already marked removed —
    /// the previous pair goes for good; the rest keep their list order.
    public mutating func deleteRemoved() {                                        // P2.2
        tiles.removeAll { $0.isRemoved }
    }

    /// Tiles not yet removed (g+0x62 after a match, rules §8 step 5).
    public var unremovedCount: Int { tiles.reduce(0) { $0 + ($1.isRemoved ? 0 : 1) } }                    // P2.2
    /// Open tiles not yet removed (rules §8 step 7, the stacked-loss test).
    public var openUnremovedCount: Int { tiles.reduce(0) { $0 + ($1.isOpen && !$1.isRemoved ? 1 : 0) } }  // P2.2
}
