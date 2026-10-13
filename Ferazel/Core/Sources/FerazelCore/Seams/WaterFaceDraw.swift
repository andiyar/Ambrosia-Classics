import Foundation

/// One water-face draw of `.WrapDrawWaterEffects @ 10010fac` (plan S3, E1a adds the type, E1b fills it; LOCKED once
/// added — fields may be added, never renamed or retyped): the cached liquid cell (`cellX`, `cellY`) in level cells,
/// its tile and its liquid kind.
public struct WaterFaceDraw: Equatable, Sendable {
    public var cellX: Int
    public var cellY: Int
    public var tile: Int16
    public var waterKind: Int16

    public init(cellX: Int, cellY: Int, tile: Int16, waterKind: Int16) {
        self.cellX = cellX
        self.cellY = cellY
        self.tile = tile
        self.waterKind = waterKind
    }
}
