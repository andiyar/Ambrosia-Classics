import Foundation
import FerazelCore

/// The 640×480 8-bit screen the original draws on (the main device in 8-bit mode, `.SwitchTo8BitColorMT`): one index
/// per pixel, row-major, row 0 at the top. What the pixels look like is decided only when the frame is presented,
/// through the **current screen CLUT** (design §5): `.SetScreenClut @ 1000faa8` rewrites every `value` field to its
/// index before `SetEntries` (lighting-tables §1.2), so index i shows entry i's colour (`ColorLUT.entries`).
public struct IndexedFrame: Sendable, Equatable {
    public static let width = 0x280
    public static let height = 0x1e0

    /// `width × height` indices, row-major.
    public var pixels: [UInt8]

    public init(fill: UInt8 = 0) {
        pixels = [UInt8](repeating: fill, count: Self.width * Self.height)
    }

    /// The index at (x, y), both inside the frame.
    public subscript(x: Int, y: Int) -> UInt8 {
        get { pixels[y * Self.width + x] }
        set { pixels[y * Self.width + x] = newValue }
    }

    /// The frame as 0xAARRGGBB words (alpha 0xFF), row 0 at the top — the `ShellBitmap.pixels` layout — each index
    /// shown through `clut` (the 16-bit channels' high bytes).
    public func rgba(through clut: ColorLUT) -> [UInt32] {
        let table = clut.entries.map { e -> UInt32 in
            0xff00_0000 | UInt32(e.red >> 8) << 16 | UInt32(e.green >> 8) << 8 | UInt32(e.blue >> 8)
        }
        return pixels.map { table[Int($0)] }
    }
}
