import Foundation

/// The two colour conversions QuickTime/QuickDraw applied when the original drew a GIF plate into a
/// GWorld (`FUN_10021190`, sprite-sound-containers.md §1–§2.1; plan Research note 15). Neither was
/// read in the game binary — both are QuickDraw's documented behaviour, chosen and pinned by tests.
public enum QuickDrawColor {

    /// 24-bit colour → QuickDraw 16-bit direct pixel x1R5G5B5 by **truncation**: `c >> 3` per channel.
    ///
    /// [MED] The GIF palette becomes a QuickDraw CLUT with 16-bit components `c·257`; CopyBits to a
    /// 16-bit GWorld keeps each component's high 5 bits, and `(c·257) >> 11 == c >> 3` for every
    /// 8-bit `c`. The game's own `_COLOR` packer uses the same rule (`trunc(65535·c/255) >> 11`,
    /// INDEX #40 HIGH). Round-to-nearest would change **253** used palette components across the
    /// shipped plates, so the choice is pinned by `SpriteGroupTests.testRGB555IsHighFiveBits`.
    public static func rgb555(_ r: UInt8, _ g: UInt8, _ b: UInt8) -> UInt16 {
        UInt16(r >> 3) << 10 | UInt16(g >> 3) << 5 | UInt16(b >> 3)
    }

    /// The default 8-bit system colour table (`clut` 8), in index order: the 6×6×6 cube over levels
    /// FF CC 99 66 33 00 (index = 36·r + 6·g + b) without its final black (0–214), then 10-step ramps
    /// of red (215–224), green (225–234), blue (235–244) and grey (245–254) over
    /// EE DD BB AA 88 77 55 44 22 11, then black (255).
    public static let systemCLUT8: [(UInt8, UInt8, UInt8)] = {
        let levels: [UInt8] = [0xFF, 0xCC, 0x99, 0x66, 0x33, 0x00]
        let ramp: [UInt8] = [0xEE, 0xDD, 0xBB, 0xAA, 0x88, 0x77, 0x55, 0x44, 0x22, 0x11]
        var t: [(UInt8, UInt8, UInt8)] = []
        for r in levels { for g in levels { for b in levels { t.append((r, g, b)) } } }
        t.removeLast()
        t += ramp.map { ($0, 0, 0) }
        t += ramp.map { (0, $0, 0) }
        t += ramp.map { (0, 0, $0) }
        t += ramp.map { ($0, $0, $0) }
        t.append((0, 0, 0))
        return t
    }()

    /// 24-bit colour → index into `systemCLUT8`, as QuickDraw maps a colour into an 8-bit GWorld:
    /// through a **4-bit inverse table** — the colour selects cell `(r>>4, g>>4, b>>4)`, and each cell
    /// holds the CLUT entry nearest (squared RGB distance) to the cell's colour `(q·17)`, ties → the
    /// lowest index.
    ///
    /// [MED] QuickDraw's inverse-table construction was not read. Planner evidence (2026-10-06): the
    /// 4-bit-cell rule and a full-precision nearest-colour rule give identical frame rects on all 125
    /// alpha plates (2,554 frames); both differ from an RGB compare only on `GLOW`, where the fill
    /// (8,0,255) and the frame body's (0,0,255) land on one index (210) and 5 of 12 rects change
    /// (`SpriteGroupTests.testGlowUsesEightBitScan`).
    public static func systemIndex(_ r: UInt8, _ g: UInt8, _ b: UInt8) -> UInt8 {
        inverseTable[Int(r >> 4) << 8 | Int(g >> 4) << 4 | Int(b >> 4)]
    }

    /// The 4096-cell inverse table, built once.
    static let inverseTable: [UInt8] = {
        let clut = systemCLUT8
        var table = [UInt8](repeating: 0, count: 4096)
        for cell in 0..<4096 {
            let cr = (cell >> 8) * 17, cg = (cell >> 4 & 15) * 17, cb = (cell & 15) * 17
            var best = 0, bestDistance = Int.max
            for (i, e) in clut.enumerated() {
                let dr = cr - Int(e.0), dg = cg - Int(e.1), db = cb - Int(e.2)
                let d = dr * dr + dg * dg + db * db
                if d < bestDistance { bestDistance = d; best = i }
            }
            table[cell] = UInt8(best)
        }
        return table
    }()
}
