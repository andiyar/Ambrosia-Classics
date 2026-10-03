/// One `_AddTile(double x, double y, short L)` call of a built-in layout (`_AddTile` @ 0x146bc,
/// docs/aki/levels-layouts.md): `x2 = 2x`, `y2 = 2y` (the half-units `_AddTile` stores) and the source
/// layer argument `L` (1 = top … 7 = bottom; the board stores z = 7 − L).
public struct LayoutPlacement: Equatable, Sendable {
    public let x2: Int
    public let y2: Int
    public let layerArg: Int

    public init(x2: Int, y2: Int, layerArg: Int) {
        self.x2 = x2
        self.y2 = y2
        self.layerArg = layerArg
    }
}

/// A built-in layout: what one `_LayoutN` function does — 144 `_AddTile` calls in call order, then
/// g+0x94 (subtracted from tile x pixels), g+0x98 (added to tile y pixels) and g+0x8e (background number).
public struct Layout: Sendable {
    public let functionName: String
    public let placements: [LayoutPlacement]
    public let offsetX: Int
    public let offsetY: Int
    public let background: Int

    public init(functionName: String, placements: [LayoutPlacement], offsetX: Int, offsetY: Int, background: Int) {
        self.functionName = functionName
        self.placements = placements
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.background = background
    }
}

/// The 12 built-in layouts and the 144-tile face set.
public enum Layouts {
    /// `_LoadLayout` @ 0x132f1 (docs/aki/levels.md §1): level index g+0x90 (0…11) → its `_LayoutN`. The
    /// dispatch is not in name order (index 5 → `_Layout10`, 7 → `_Layout11`, 9 → `_Layout6`, 10 → `_Layout8`);
    /// the background always equals index + 1. Tables are generated from the bank (`LayoutTables.swift`).
    public static func forLevel(_ index: Int) -> Layout {
        precondition(tables.indices.contains(index), "Aki has 12 built-in layouts (0…11), not \(index)")
        let t = tables[index]
        let placements = stride(from: 0, to: t.triples.count, by: 3).map {
            LayoutPlacement(x2: t.triples[$0], y2: t.triples[$0 + 1], layerArg: t.triples[$0 + 2])
        }
        return Layout(functionName: t.functionName, placements: placements,
                      offsetX: t.offsetX, offsetY: t.offsetY, background: t.background)
    }

    /// `_C.97.126381` @ 0x33dc0 in binary order (docs/aki/rules.md §4.1): the faces `_ShuffleCustomTiles`
    /// deals — 200…204 ×4, 205…212 ×1 (the eight seasons, which all match one another), 213…241 ×4.
    public static let faceMultiset: [Int] = [
        202, 213, 226, 215, 227, 200, 214, 221, 227, 205, 201, 222, 229, 204, 231, 218, 232, 214, 223, 220, 232, 206, 231, 201,
        233, 229, 204, 231, 227, 220, 232, 207, 231, 218, 233, 201, 235, 227, 208, 236, 223, 232, 204, 235, 220, 202, 217, 234,
        226, 200, 213, 236, 209, 222, 234, 204, 237, 228, 210, 237, 219, 241, 211, 200, 229, 234, 218, 239, 221, 212, 200, 237,
        216, 239, 228, 214, 239, 223, 215, 236, 234, 217, 228, 223, 214, 220, 239, 216, 222, 225, 222, 226, 224, 202, 229, 236,
        216, 238, 235, 217, 240, 224, 202, 238, 218, 240, 213, 240, 219, 238, 226, 203, 215, 240, 221, 230, 213, 233, 230, 228,
        201, 238, 225, 219, 233, 203, 241, 235, 224, 241, 215, 241, 225, 230, 224, 230, 203, 237, 225, 217, 219, 221, 203, 216,
    ]
}

/// One generated level table (`LayoutTables.swift`): the `_LayoutN` header values and its `_AddTile`
/// calls as flat (x2, y2, L) triples — flat Ints because Swift type-checks 1728 struct literals slowly.
struct LayoutTable: Sendable {
    let level: Int
    let functionName: String
    let offsetX: Int
    let offsetY: Int
    let background: Int
    let triples: [Int]
}
