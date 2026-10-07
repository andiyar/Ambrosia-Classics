import Foundation

/// The level's media mask as `FUN_1000fbc0` leaves it (sprite-sound-containers.md §3.1): the raw `im16` grid
/// (96 × 720 for a 480-wide map; row 0 = the top of the map, MED) and the map-to-mask scale
/// `_DAT_100e0134 = mapWidth / maskWidth` (480 / 96 = 5). C7 declares the grid and the scale; the water
/// lookup `FUN_1000fee0` (cell == 0x001f) is C11b's (plan S2). Empty until the level start loads it (C18a).
public struct MediaMask: Equatable, Sendable {
    /// Mask width and height in cells.
    public var width: Int32 = 0
    public var height: Int32 = 0
    /// Row-major cells, `width × height` x1R5G5B5 values.
    public var cells: [UInt16] = []
    /// `_DAT_100e0134`: map pixels per mask cell.
    public var scale: Int32 = 0

    public init() {}

    public init(width: Int32, height: Int32, cells: [UInt16], scale: Int32) {
        self.width = width
        self.height = height
        self.cells = cells
        self.scale = scale
    }
}
