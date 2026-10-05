import BubbleTroubleCore
import Foundation

/// The "Letters" bitmap font of the high-score table: PICT 9001 (normal) and 9002 (highlighted), each a 546×46
/// strip — letters on rows 0…23, digits/punctuation on rows 23…46 — drawn into the sprite GWorld by
/// `_LoadLetters @ 0001e2ff` (9001 at its frame, 9002 offset 46 down; the GWorld erased white first) and cut by
/// the glyph rects `_InitLetterRects @ 0001d6e9` sets (closes U4 part 1). Drawn by `_DrawCustomString @
/// 0001e4c0` → `_DrawLetter @ 0001e3be` → `_SpriteToCompTransparent @ 0001518d` (CopyBits mode 0x24 with
/// BackColor white: the white around each glyph is not copied).
public struct LettersFont: Equatable, Sendable {
    /// `gLetters`: 128 rects, indexed by the (signed) character code; unset entries are (0,0,0,0) (width 0).
    public let glyphs: [QDRect]

    /// Rows of the sprite GWorld the highlighted strip starts at (`_OffsetRect(r, 0, 0x2e)`).
    public static let highlightOffset = 46

    public init() {
        var g = Array(repeating: QDRect(top: 0, left: 0, bottom: 0, right: 0), count: 128)
        // `_SetRect(r, left, top, right, bottom)`, transcribed in the decompile's order.
        func set(_ c: Int, _ l: Int16, _ t: Int16, _ r: Int16, _ b: Int16) {
            g[c] = QDRect(top: t, left: l, bottom: b, right: r)
        }
        // Row 1: 'A'…'Z' (gLetters + 0x208 … 0x2d0), copied to 'a'…'z' (+0x308 … 0x3d4).
        let upper: [(Int16, Int16)] = [
            (0x00, 0x0e), (0x15, 0x22), (0x2a, 0x38), (0x3f, 0x4c), (0x54, 0x60), (0x69, 0x76), (0x7e, 0x8f),
            (0x93, 0xa0), (0xa8, 0xb0), (0xbd, 0xc9), (0xd2, 0xe2), (0xe7, 0xf2), (0xfc, 0x111), (0x111, 0x120),
            (0x126, 0x135), (0x13b, 0x14a), (0x150, 0x160), (0x165, 0x174), (0x17a, 0x189), (399, 0x19e),
            (0x1a4, 0x1b4), (0x1b9, 0x1c7), (0x1ce, 0x1e3), (0x1e3, 499), (0x1f8, 0x208), (0x20d, 0x21f),
        ]
        for (i, lr) in upper.enumerated() {
            set(0x41 + i, lr.0, 0, lr.1, 0x17)
            set(0x61 + i, lr.0, 0, lr.1, 0x17)
        }
        // Row 2 (top 0x17, bottom 0x2e), each at its own gLetters offset / 8.
        set(0x31, 5, 0x17, 0x0c, 0x2e)          // '1'  +0x188
        set(0x32, 0x15, 0x17, 0x23, 0x2e)       // '2'  +400
        set(0x33, 0x2a, 0x17, 0x38, 0x2e)       // '3'  +0x198
        set(0x34, 0x3f, 0x17, 0x51, 0x2e)       // '4'  +0x1a0
        set(0x35, 0x54, 0x17, 0x62, 0x2e)       // '5'  +0x1a8
        set(0x36, 0x69, 0x17, 0x77, 0x2e)       // '6'  +0x1b0
        set(0x37, 0x7e, 0x17, 0x8d, 0x2e)       // '7'  +0x1b8
        set(0x38, 0x93, 0x17, 0xa1, 0x2e)       // '8'  +0x1c0
        set(0x39, 0xa8, 0x17, 0xb6, 0x2e)       // '9'  +0x1c8
        set(0x30, 0xbd, 0x17, 0xca, 0x2e)       // '0'  +0x180
        set(0x2c, 0xd2, 0x17, 0xda, 0x2e)       // ','  +0x160
        set(0x2e, 0xe7, 0x17, 0xee, 0x2e)       // '.'  +0x170
        set(0x2f, 0xfc, 0x17, 0x10b, 0x2e)      // '/'  +0x178
        set(0x3f, 0x111, 0x17, 0x11e, 0x2e)     // '?'  +0x1f8
        set(0x3b, 0x126, 0x17, 0x12e, 0x2e)     // ';'  +0x1d8
        set(0x3a, 0x13b, 0x17, 0x142, 0x2e)     // ':'  +0x1d0
        set(0x27, 0x150, 0x17, 0x157, 0x2e)     // '\'' +0x138
        set(0x22, 0x165, 0x17, 0x16f, 0x2e)     // '"'  +0x110
        set(0x21, 0x17a, 0x17, 0x184, 0x2e)     // '!'  +0x108
        set(0x2a, 399, 0x17, 0x19e, 0x2e)       // '*'  +0x150
        set(0x28, 0x1a4, 0x17, 0x1ae, 0x2e)     // '('  +0x140
        set(0x29, 0x1b9, 0x17, 0x1c3, 0x2e)     // ')'  +0x148
        set(0x2d, 0x1ce, 0x17, 0x1da, 0x2e)     // '-'  +0x168
        set(0x3d, 0x1e3, 0x17, 0x1ee, 0x2e)     // '='  +0x1e8
        set(0x2b, 0x1f8, 0x17, 0x204, 0x2e)     // '+'  +0x158
        set(0x20, 0x20d, 0x17, 0x214, 0x2e)     // ' '  +0x100
        glyphs = g
    }

    /// The bytes `_DrawCustomString` walks: the text as MacRoman (C string, unconvertible characters → '?').
    public static func bytes(_ text: String) -> [UInt8] {
        if let d = text.data(using: .macOSRoman, allowLossyConversion: true) { return [UInt8](d) }
        return Array(text.utf8)
    }

    /// `_GetLetterWidth @ 0001e3a4`: right − left of the glyph rect.
    public func width(_ byte: UInt8) -> Int {
        guard byte < 0x80 else { return 0 }
        let r = glyphs[Int(byte)]
        return Int(r.right) - Int(r.left)
    }

    /// One glyph placement: copy `src` of the sprite GWorld to `dst` of the target.
    public struct Placement: Equatable, Sendable {
        public let src: QDRect
        public let dst: QDRect
    }

    /// `_DrawCustomString(text, h, v, highlighted, fixedPitch)`: `h == −1` centres on 640 with C's
    /// truncating `(640 − width) / 2` (width = Σ glyph widths of the non-negative chars); chars ≥ 0x80 (negative
    /// `char`) are skipped; each glyph lands at (h, v) with its own rect size and advances h by its width, or by
    /// `fixedPitch` (15 at the only call sites) — `_DrawLetter` writes the next h through `param_4` as a ushort.
    public func layout(_ text: String, h: Int, v: Int, highlighted: Bool, fixedPitch: Int?) -> [Placement] {
        var out: [Placement] = []
        forEachPlacement(text, h: h, v: v, highlighted: highlighted, fixedPitch: fixedPitch) { out.append($0) }
        return out
    }

    /// `layout` without building an array (the compositor's per-op path). An all-ASCII string is walked as its
    /// UTF-8 bytes (identical to MacRoman there) with no conversion allocation.
    public func forEachPlacement(_ text: String, h: Int, v: Int, highlighted: Bool, fixedPitch: Int?,
                                 _ body: (Placement) -> Void) {
        if text.utf8.allSatisfy({ $0 < 0x80 }) {
            place(text.utf8, h: h, v: v, highlighted: highlighted, fixedPitch: fixedPitch, body)
        } else {
            place(Self.bytes(text), h: h, v: v, highlighted: highlighted, fixedPitch: fixedPitch, body)
        }
    }

    private func place<C: Collection>(_ bytes: C, h: Int, v: Int, highlighted: Bool, fixedPitch: Int?,
                                      _ body: (Placement) -> Void) where C.Element == UInt8 {
        var x = h
        if Int16(truncatingIfNeeded: h) == -1 {
            var total: Int16 = 0
            for b in bytes where b < 0x80 { total &+= Int16(truncatingIfNeeded: width(b)) }
            x = Int((640 - Int32(total)) / 2)
        }
        for b in bytes where b < 0x80 {
            var src = glyphs[Int(b)]
            let w = Int(src.right) - Int(src.left), hgt = Int(src.bottom) - Int(src.top)
            let next = Int(UInt16(truncatingIfNeeded: x + w))         // (ushort)(h + width)
            if highlighted { src.offset(dx: 0, dy: Int16(Self.highlightOffset)) }
            let dst = QDRect(top: Int16(truncatingIfNeeded: v), left: Int16(truncatingIfNeeded: x),
                             bottom: Int16(truncatingIfNeeded: v + hgt), right: Int16(truncatingIfNeeded: next))
            body(Placement(src: src, dst: dst))
            if let pitch = fixedPitch { x += pitch } else { x = Int(Int16(truncatingIfNeeded: next)) }
        }
    }
}
