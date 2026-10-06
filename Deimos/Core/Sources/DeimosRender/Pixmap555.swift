import Foundation
import DeimosCore

/// One of the game's 16-bit offscreen buffers (the 0x30-byte M_PixelBuffer object, display-window-present §1):
/// `width` × `height` x1R5G5B5 pixels, row 0 at the top, rowBytes = 2·width. Bit 15 is never read by the kernels.
///
/// Every buffer is black at creation: `FUN_10009bd0` erases it and the display set-up then fills each of the three
/// with RGB(0,0,0) (`FUN_10009f00`, colour words at `0x100d6390` = 0; display-window-present §4).
public struct Pixmap555: Equatable, Sendable {
    public let width: Int
    public let height: Int
    /// Row-major, row 0 top, `width` pixels per row.
    public var pixels: [UInt16]
    /// `+0x2c`: the interlace field parity, 0 at creation, toggled by every interlaced copy FROM this buffer
    /// (`FUN_100450e0` `100455e8…100455f4`; display-window-present §1, §2.1).
    public var interlaceParity: UInt32 = 0

    public init(width: Int, height: Int) {
        precondition(width >= 0 && height >= 0, "Pixmap555: negative size \(width)×\(height)")
        self.width = width
        self.height = height
        self.pixels = [UInt16](repeating: 0, count: width * height)
    }

    /// The bounds rect (`+0x1c..+0x28`): top 0, left 0, bottom = height, right = width.
    public var bounds: MacRect { MacRect(top: 0, left: 0, bottom: Int32(height), right: Int32(width)) }

    public subscript(x: Int, y: Int) -> UInt16 {
        get { pixels[y * width + x] }
        set { pixels[y * width + x] = newValue }
    }

    /// `FUN_10009f00`: `RGBForeColor` + `PaintRect(portRect)` — every pixel becomes `colour`.
    public mutating func fill(_ colour: UInt16) {
        pixels.withUnsafeMutableBufferPointer { $0.update(repeating: colour) }
    }

    /// `PaintRect(rect)` in `colour`, clipped to the bounds.
    public mutating func fill(_ rect: MacRect, colour: UInt16) {
        let r = rect.clipped(to: bounds)
        guard r.right > r.left, r.bottom > r.top else { return }
        let w = width, x0 = Int(r.left), n = Int(r.right) - x0
        pixels.withUnsafeMutableBufferPointer { px in
            guard let base = px.baseAddress else { return }
            for y in Int(r.top)..<Int(r.bottom) { (base + y * w + x0).update(repeating: colour, count: n) }
        }
    }
}

extension MacRect {
    /// The intersection with `other` (may come out empty: right ≤ left or bottom ≤ top).
    func clipped(to other: MacRect) -> MacRect {
        MacRect(top: max(top, other.top), left: max(left, other.left),
                bottom: min(bottom, other.bottom), right: min(right, other.right))
    }

    var rectWidth: Int32 { right - left }
    var rectHeight: Int32 { bottom - top }
}
