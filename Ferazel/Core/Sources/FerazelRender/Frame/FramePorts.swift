import Foundation

/// The three persistent 640×416 8-bit back ports `.InitAppGlobals` makes with `.NewBlitPortSlop(0x280, 0x1a0, 0, 8)`
/// (decompile l. 455–468; engine §3), addressed as a ring: world pixel (x, y) lives at (x mod 640, y mod 416)
/// (rendering-omnipx-titles §1.1):
///
/// - `frame` — `_DAT_100a000c`: tiles + sprites + particles, the source of the copy to the screen;
/// - `mask` — `_DAT_100a0008`: the backdrop gate, 0xFF where the parallax may show, 0x00 under opaque tile pixels
///   (plan "Bank corrections" 9: `.RedrawScrollGrid` erases each redrawn cell to 0xFF, every boolean stamp writes 0x00);
/// - `tiles` — `_DAT_100a0004`, the third port: `.RedrawScrollGrid` draws the tile layer here (each redrawn cell first
///   cleared to 0x00) and copies the redrawn rect into `frame` with `.WrapRectBlitX`; `.WrapEraseSprites` restores
///   `frame` from it (R4).
///
/// The 8-pixel slop around each port is not modelled: every blit here is clipped to the 640×416 port. `.NewBlitPortSlop`
/// paints a fresh port with QuickDraw's gray pattern; the replica starts every port at `fill` (0 by default) — no
/// redrawn cell shows the initial contents, since each one is cleared first.
public struct FramePorts: Sendable, Equatable {
    public static let width = 0x280
    public static let height = 0x1a0

    /// `_DAT_100a000c`, row-major 640×416.
    public var frame: [UInt8]
    /// `_DAT_100a0008`, row-major 640×416.
    public var mask: [UInt8]
    /// `_DAT_100a0004`, row-major 640×416.
    public var tiles: [UInt8]

    public init(fill: UInt8 = 0) {
        let blank = [UInt8](repeating: fill, count: Self.width * Self.height)
        frame = blank
        mask = blank
        tiles = blank
    }

    /// The ring column of world x: `x − 640·trunc(x/640)` (the `0x66666667` divide in `.WrapDrawTile @ 100169f4`,
    /// a truncating remainder — equal to x mod 640 for every x ≥ 0, which is every tile the grid draws).
    public static func ringX(_ x: Int) -> Int { x - width * (x / width) }

    /// The ring row of world y: `y − 416·trunc(y/416)` (the `0x4ec4ec4f` divide).
    public static func ringY(_ y: Int) -> Int { y - height * (y / height) }

    /// The byte offset of world pixel (x, y) in a port (x, y ≥ 0).
    public static func ringOffset(x: Int, y: Int) -> Int { ringY(y) * width + ringX(x) }
}
