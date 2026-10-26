import Foundation

/// `.MosaicScreenBlit(cell, mode3) @ 100196e8` (M l. 12854–12943; TP), on 640×480 index buffers: the screen
/// (`_DAT_1009fd0c` base, `_DAT_1009fd10` row bytes) from port `_DAT_100a0004`, whose row table (`+0x60`, read at
/// `+0x80` = row 8 on) holds `.MosaicTransition`'s copy of the frame at (16, 8). For rows r = 0, cell, 2·cell … < 384:
/// screen row 8 + r, from x 16, takes `608 / cell` blocks (integer division) of `cell` bytes, each the port's pixel at
/// (16 + k·cell, 8 + r) — the rest of that row keeps its pixels; then each of the block's next `cell − 1` rows (while
/// < 384) is a copy of that screen row's 608 bytes (0x13 × 8 words, x 16…623). The second argument is never read (r4
/// is overwritten at raw `10019708`).
public enum Mosaic {
    /// The view: 608×384 at (16, 8).
    public static let left = 0x10, top = 8, width = 0x260, height = 0x180

    public static func blit(cell: Int, source: [UInt8], screen: inout [UInt8]) {
        let w = IndexedFrame.width
        precondition(source.count == w * IndexedFrame.height && screen.count == source.count,
                     "Mosaic: buffers are 640×480")
        guard 0 < cell else { return }
        let blocks = width / cell
        var r = 0
        while r < height {
            let row = (top + r) * w
            for k in 0..<blocks {
                let x = left + k * cell
                let b = source[row + x]
                for i in 0..<cell { screen[row + x + i] = b }
            }
            var n = 1
            while n < cell && r + n < height {
                let dst = (top + r + n) * w + left
                for i in 0..<width { screen[dst + i] = screen[row + left + i] }
                n += 1
            }
            r += cell
        }
    }
}
