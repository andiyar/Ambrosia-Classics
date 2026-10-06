import Foundation

/// Character → font frame, `FUN_1000e8d0 @ 1000e8d0` (text-metrics-lists.md §1.1, data-tags.md §5, HIGH).
/// ★ LOCKED name (plan S2). `extsb; subi 0x21; cmplwi 0x5d; bgt → li r3,0x5a`: chars 0x21…0x7e go through
/// the jump table at `0x100e542c` (r2 − 0xf04); every other byte — space, control bytes, DEL and (being
/// sign-extended) every byte ≥ 0x80 — is frame 90. The table below was read from the data image: each
/// entry's target is a `li r3,N; blr`.
public enum GlyphMap {
    /// The fall-through frame (`1000ebc4 li r3,0x5a`): an invisible 4 × 13 cell in `tesm`.
    public static let defaultFrame = 90

    /// Frames for chars 0x21…0x7e, in order (`!` … `~`).
    static let table: [Int] = [
        62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76,          // ! " # $ % & ' ( ) * + , - . /
        61, 52, 53, 54, 55, 56, 57, 58, 59, 60,                              // 0 1 … 9
        77, 78, 79, 80, 81, 82, 83,                                          // : ; < = > ? @
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,   // A–Z
        69, 84, 70, 85, 86, 87,                                              // [ \ ] ^ _ `
        26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, // a–z
        69, 88, 70, 89,                                                      // { | } ~
    ]

    /// The frame of byte `c` in the font group.
    public static func frame(_ c: UInt8) -> Int {
        let i = Int(c) - 0x21
        guard i >= 0, i <= 0x5d else { return defaultFrame }
        return table[i]
    }
}
