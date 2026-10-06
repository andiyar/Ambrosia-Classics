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

    /// `_ShuffleCustomTiles(char reuse)` @ 0x12763 (rules §5). Each attempt copies `Layouts.faceMultiset` into
    /// 144 slots; with `reuse` all 144 are zeroed and the CURRENT tiles' faces (list order) copied into slots
    /// 0…N−1 — inside the retry loop, so attempt 2 starts from attempt 1's result (DC:7118). Each tile in
    /// list order redraws `rand() % 144` until the slot is non-zero, takes that face, zeroes the slot and
    /// clears hint/selected. Then `_SetVisibleTiles`, `_SetOpenTiles`, `_CountOpenPairs`; repeat while the
    /// count is 0 (no retry cap, as the original) and return it (g+0x60). The original re-seeds
    /// `srand(TickCount())` per attempt; the replica takes any generator — the sequence is unreproducible.
    public mutating func deal<R: RandomNumberGenerator>(reuse: Bool, using rng: inout R) -> Int {   // P2.3
        var pairs: Int
        repeat {
            var slots = Layouts.faceMultiset
            if reuse {
                slots = Array(repeating: 0, count: 144)
                for (i, tile) in tiles.enumerated() { slots[i] = tile.face }
            }
            for i in tiles.indices {
                var slot: Int
                repeat { slot = Int(rng.next() % 144) } while slots[slot] == 0
                tiles[i].face = slots[slot]
                tiles[i].isHinted = false
                tiles[i].isSelected = false
                slots[slot] = 0
            }
            setVisibleTiles()
            setOpenTiles()
            pairs = countOpenPairs()
        } while pairs == 0
        return pairs
    }

    /// `_CountOpenPairs` @ 0xe5e4 (rules §6) — the original's approximation, not a true matching. Over open,
    /// unremoved tiles: m(t) = other open unremoved tiles matching t (rules §4.2); A = #{m > 0}, B = #{m == 2};
    /// B == 6 ⇒ A −= 2; A odd ⇒ A −= 1; result (short)(A × 0.5). Exact for pairs and one or two open triples,
    /// over-counts three triples; g+0x60 == 0 is the "no more pairs" trigger, so the formula is replicated.
    public func countOpenPairs() -> Int {                                         // P2.3
        let faces = tiles.filter { $0.isOpen && !$0.isRemoved }.map(\.face)
        var a = 0, b = 0
        for (i, face) in faces.enumerated() {
            var m = 0
            for (j, other) in faces.enumerated() where j != i && Board.matches(face, other) { m += 1 }
            if m > 0 { a += 1 }
            if m == 2 { b += 1 }
        }
        if b == 6 { a -= 2 }
        if a % 2 != 0 { a -= 1 }
        return a / 2
    }

    /// Tiles not yet removed (g+0x62 after a match, rules §8 step 5).
    public var unremovedCount: Int { tiles.reduce(0) { $0 + ($1.isRemoved ? 0 : 1) } }                    // P2.2
    /// Open tiles not yet removed (rules §8 step 7, the stacked-loss test).
    public var openUnremovedCount: Int { tiles.reduce(0) { $0 + ($1.isOpen && !$1.isRemoved ? 1 : 0) } }  // P2.2
}
