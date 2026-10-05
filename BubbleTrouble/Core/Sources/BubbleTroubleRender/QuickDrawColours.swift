/// Colour QuickDraw's mapping of the eight classic `ForeColor`/`BackColor` constants to RGB (Inside Macintosh:
/// Imaging With QuickDraw, "The Eight-Color System"), reduced to 8 bits per channel (the high byte of each
/// 16-bit component). 0xRRGGBB.
public enum QuickDrawColour {
    /// `blackColor` 33.
    public static let black: UInt32 = 0x000000
    /// `whiteColor` 30.
    public static let white: UInt32 = 0xFFFFFF
    /// `redColor` 205 = $DD6B $08C2 $06A2.
    public static let red: UInt32 = 0xDD0806
    /// `greenColor` 341 = $0000 $8000 $11B0.
    public static let green: UInt32 = 0x008011
    /// `blueColor` 409 = $0000 $0000 $D400.
    public static let blue: UInt32 = 0x0000D4
    /// `cyanColor` 273 = $0241 $AB54 $EAFF.
    public static let cyan: UInt32 = 0x02ABEA
    /// `magentaColor` 137 = $F2D7 $0856 $84EC.
    public static let magenta: UInt32 = 0xF20884
    /// `yellowColor` 69 = $FC00 $F37D $052F.
    public static let yellow: UInt32 = 0xFCF305

    /// The RGB of a classic colour constant (33, 30, 205, 341, 409, 273, 137, 69); nil for any other value.
    public static func rgb(constant: Int) -> UInt32? {
        switch constant {
        case 33: return black
        case 30: return white
        case 205: return red
        case 341: return green
        case 409: return blue
        case 273: return cyan
        case 137: return magenta
        case 69: return yellow
        default: return nil
        }
    }

    /// QuickDraw `PenMode(blend)` of a black source over `channel` with `OpColor` weight `opColor` (all three
    /// components equal at every call site: 0x7fff in `_PrepareScoreBar`, 0x8fff in `_DrawInterfaceText`):
    /// `dst16 · (0xFFFF − w) / 0xFFFF` on the 16-bit component (`c · 0x101`), back to 8 bits by its high byte.
    /// The 16-bit arithmetic is QuickDraw's documented blend; its exact rounding inside the 2008 Carbon QD is not
    /// in the game's binary (≤ 1 LSB uncertainty, informed default).
    public static func blendTowardBlack(_ channel: UInt32, opColor: UInt32) -> UInt32 {
        let c16 = channel * 0x101
        return (c16 * (0xFFFF - opColor) / 0xFFFF) >> 8
    }
}
