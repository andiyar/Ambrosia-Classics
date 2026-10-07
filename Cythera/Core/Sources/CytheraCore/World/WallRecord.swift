/// One 10-byte 0xF00D wall-face substitution record {u16 tile, u16 alt[4]} (data-format §5, HIGH code / MED
/// reading): `__ct__7TViewerFs @ 10062684` asserts tile ≤ 0x2000 and points `tbl[tile]` at `alt`; `Render`
/// substitutes alt[0..3] by which neighbour (N, E, S, W) is visible.
public struct WallRecord: Equatable, Sendable {
    public static let size = 10
    public let tile: UInt16
    /// N, E, S, W.
    public let alternates: [UInt16]
    init(tile: UInt16, alternates: [UInt16]) { self.tile = tile; self.alternates = alternates }
}
