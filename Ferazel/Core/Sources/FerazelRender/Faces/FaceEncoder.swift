import Foundation

/// `.EncodeRect @ 1002dd70` (sprites-backgrounds §2.2, main dump l. 27455–27624) transcribed: one rect of an
/// 8-bit port encoded row by row.
///
/// Per row: an op-1 token whose n is the byte length of the row's tokens that follow; then, left to right, a
/// pixel 0 opens/extends a skip run (and sets the "has a 0 pixel" flag, face `+0x18`), any other value
/// opens/extends a literal run. A skip run is written (op 3, n) when an opaque pixel ends it — a skip still open
/// at the row's end is **not written**. A literal run is written (op 2, n, then the bytes, zero-padded to a
/// 4-byte boundary) when a 0 pixel or the row's end closes it. After the last row, op 0.
///
/// Bounds (`+0x08`): top = first row with an opaque pixel; bottom = last such row + 1; left = the least column
/// of a row's first opaque pixel − 1; right = the greatest opaque column + 2; then left and top clamped ≥ 0
/// (right and bottom are not clamped). With no opaque pixel the encoder leaves left = 0x7fff − 1 and right = 2,
/// and never writes top/bottom: the loaders do not clear `+0x08..+0x0e` (`NewPtr`), so top and bottom are
/// whatever the record held — modelled as 0 (top 0, bottom 0 + 1) [LOW: unwritten memory].
public enum FaceEncoder {
    /// Encodes `rect` of a `width × height` index buffer (pixels outside the buffer read 0 — a cell reaching
    /// past the frame, design §11). The face's frame is (0,0,h,w) as the set loaders write it.
    public static func encode(pixels: [UInt8], width: Int, height: Int, rect: EncodedFace.Rect,
                              sourceId: Int16) -> EncodedFace {
        precondition(pixels.count == width * height, "pixels \(pixels.count) ≠ \(width)×\(height)")
        let h = Int(rect.bottom) - Int(rect.top), w = Int(rect.right) - Int(rect.left)
        var out: [UInt8] = []
        out.reserveCapacity(max(0x1000, 4 * h + 3 * w * h + 0x14))
        var sawZero = false
        var top: Int16 = 0, bottom: Int16 = 0                   // the unwritten record memory, modelled as 0
        var sawOpaque = false
        var minLeft: Int16 = 0x7fff, maxRight: Int16 = 0

        func put32(_ v: UInt32, at i: Int) {
            out[i] = UInt8(v >> 24); out[i + 1] = UInt8(v >> 16 & 0xff)
            out[i + 2] = UInt8(v >> 8 & 0xff); out[i + 3] = UInt8(v & 0xff)
        }
        func append32(_ v: UInt32) { out.append(contentsOf: [0, 0, 0, 0]); put32(v, at: out.count - 4) }

        for row in 0..<max(0, h) {
            let rowHeader = out.count
            append32(0)                                         // patched below
            var literal = false, skipping = false, firstOpaqueInRow = true
            var run = 0, literalToken = 0
            func closeLiteral() {
                put32(0x0200_0000 | UInt32(run), at: literalToken)
                if run & 3 != 0 { out.append(contentsOf: [UInt8](repeating: 0, count: 4 - (run & 3))) }
            }
            let sy = Int(rect.top) + row
            for col in 0..<max(0, w) {
                let sx = Int(rect.left) + col
                let v: UInt8 = (sy >= 0 && sy < height && sx >= 0 && sx < width) ? pixels[sy * width + sx] : 0
                if v == 0 {
                    sawZero = true
                    if literal {
                        closeLiteral()
                        literal = false
                    }
                    if skipping { run += 1 } else { skipping = true; run = 1 }
                } else {
                    if !sawOpaque { top = Int16(truncatingIfNeeded: row); sawOpaque = true }
                    bottom = Int16(truncatingIfNeeded: row)
                    if firstOpaqueInRow {
                        if col < Int(minLeft) { minLeft = Int16(truncatingIfNeeded: col) }
                        firstOpaqueInRow = false
                    }
                    if Int(maxRight) < col { maxRight = Int16(truncatingIfNeeded: col) }
                    if skipping {
                        append32(0x0300_0000 | UInt32(run))
                        skipping = false
                    }
                    if literal {
                        run += 1
                        out.append(v)
                    } else {
                        literal = true
                        literalToken = out.count
                        append32(0)
                        out.append(v)
                        run = 1
                    }
                }
            }
            if literal { closeLiteral() }
            put32(0x0100_0000 | UInt32(out.count - rowHeader - 4), at: rowHeader)
        }
        append32(0)

        var left = minLeft &- 1
        let right = maxRight &+ 2
        bottom = bottom &+ 1
        if left < 0 { left = 0 }
        if top < 0 { top = 0 }
        return EncodedFace(frame: EncodedFace.Rect(top: 0, left: 0, bottom: Int16(truncatingIfNeeded: h),
                                                   right: Int16(truncatingIfNeeded: w)),
                           bounds: EncodedFace.Rect(top: top, left: left, bottom: bottom, right: right),
                           data: out, hasTransparentPixel: sawZero, scale: 0x100, sourceId: sourceId)
    }
}
