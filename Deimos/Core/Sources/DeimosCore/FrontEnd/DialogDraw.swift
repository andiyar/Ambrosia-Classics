import Foundation

// Phase 4 S6 DG (plan rulings 8, 9; question 6's default): the game's own drawing of the Dialog Manager's windows
// and controls, so the two settings windows reach the screen through the same draw path as every other screen (and
// Windows reuses them). Everything is solid rectangles: a `.draw` of face `COST` with alpha 0 (`FUN_1001ec80` writes
// the colour as is: the destination weighted 0, the colour 32), drawn now, with the full-screen clip on every command
// (the template's {0, 0, 480, 416} would drop everything right of x 416). Text is Geneva 9 (`dftb 190` / `191`) from
// the 1-bit table below, emitted as horizontal runs. The look is the classic grey Mac dialog of Ferazel's shell
// (`Ferazel/App/Dialogs/DialogViews.swift`): the dBoxProc frame, white rounded push buttons, 12-pixel check boxes,
// etched group boxes; the volume controls are plain sliders (CNTL 2000/2001 are not in the fork).
//
// These are general: rects come from a parsed `DITL` (`DialogItem.rect`, window-local) offset by the window's content
// origin; S7's controls window (DITL 191) reuses the frame, buttons, text, measuring, hit-testing and tracking, and
// runs its loop on `ModalDialogRunner` (the end of this file), as the configuration window does.

/// One face of 1-bit glyphs, keyed by the Mac Roman byte.
public struct DialogFont: Sendable {
    public struct Glyph: Equatable, Sendable {
        /// The pen advance, in pixels.
        public let advance: Int32
        /// The first column, from the pen.
        public let left: Int32
        /// The first row, from the baseline (negative = above; row 0 is the first row below the baseline).
        public let top: Int32
        public let width: Int32
        /// One word per row, top first; bit 15 = the first column.
        public let rows: [UInt16]
    }

    /// Pixels above the baseline, below it, and the line height (ascent + descent).
    public let ascent: Int32
    public let descent: Int32
    public var lineHeight: Int32 { ascent + descent }
    /// All 256 bytes: a byte the strike has no glyph for holds the missing glyph.
    private let glyphs: [Glyph]

    /// The glyph of Mac Roman byte `c`; the face's missing glyph when it has none (QuickDraw's rule for a strike),
    /// so there is always one.
    public func glyph(_ c: UInt8) -> Glyph { glyphs[Int(c)] }

    /// The pen advance of `text` (`TextWidth`).
    public func width(_ text: [UInt8]) -> Int32 {
        text.reduce(Int32(0)) { $0 + glyphs[Int($1)].advance }
    }

    /// Geneva 9 plain: Apple's own bitmap strike from System 7.5.3, `NFNT` 1025 of the Geneva suitcase, decoded once
    /// by a scratch script outside the repo from Castles' byte-for-byte copy
    /// (`Native Ports/Mac Classics/Castles/Core/Sources/CastlesCore/Text/Fonts/geneva-9.nfnt`, 2,152 bytes; shipping
    /// Apple's classic system fonts where faithful: Ben, 2026-10-25). NFNT fields used: firstChar 0, lastChar 217,
    /// kernMax 0, ascent 10, descent 2, leading 0, fRectHeight 12; each glyph's image is its columns of the bit image
    /// (location table, `loc[c] ..< loc[c + 1]`, all 12 rows), its advance the low byte and its image offset the high
    /// byte of the offset/width table. As QuickDraw draws it, the pen sits on the baseline, the image's left column
    /// is `pen + kernMax + offset` and its top row `baseline − ascent`. Kept as is, only the blank rows above and
    /// below the ink dropped. Covers every character the strike holds (0x00–0xD9 less those the offset/width table
    /// marks 0xFFFF; above 0x7F, Mac Roman codes); any other character draws the strike's missing glyph (`missing`).
    /// Per glyph: `CC AA LL TT WW HH` (byte, advance, left = kernMax + offset, top = first ink row − ascent, as signed
    /// bytes, image width, rows) then HH rows of four hex digits, bit 15 the image's first column; a glyph with no
    /// ink is `CC AA 000000`. The missing glyph (the offset/width table's entry after lastChar) uses the same form
    /// with byte 00.
    public static let geneva9 = DialogFont(ascent: 10, descent: 2,
                                           missing: "000700f90707fc0084008400840084008400fc00", table: """
        0000000000 0100000000 0200000000 0300000000 0400000000 0500000000 0906000000 0d00000000 1c07000000 2003000000
        210301f901078000800080008000800000008000 220501f90302a000a000 230701f805055000f8005000f8005000
        240600f8050920007000a800a00070002800a80070002000 250900f908077f00920094006e00190029004600
        260800f8070830004800500020005400880094006200 270301f9010280008000
        280400f80309200040008000800080008000800040002000 290400f80309800040002000200020002000200040008000
        2a0701f9050550002000f80020005000 2b0600fa050520002000f80020002000 2c0401ff0203400040008000 2d0500fc0401f000
        2e0301ff01018000 2f0601f8040810001000200020004000400080008000 300600f905077000880088008800880088007000
        310601f902074000c00040004000400040004000 320600f90507700088000800100020004000f800
        330600f90507f800100020007000080088007000 340600f905071000300050009000f80010001000
        350600f90507f8008000f0000800080088007000 360600f90507300040008000f000880088007000
        370600f90507f800080010001000200020002000 380600f905077000880088007000880088007000
        390600f905077000880088007800080010006000 3a0402fb010580000000000000008000
        3b0401fb02074000000000000000400040008000 3c0501fa030520004000800040002000 3d0600fb0503f8000000f800
        3e0501fa030580004000200040008000 3f0601f904076000900010002000400000004000
        400800f90708380044009a00aa00aa009c0040003800 410701f905072000200050005000f80088008800
        420600f90507f00088008800f00088008800f000 430600f905077000880080008000800088007000
        440600f90507e00090008800880088009000e000 450500f90407f00080008000e00080008000f000
        460500f90407f00080008000e000800080008000 470600f905077000880080009800880088007000
        480600f90507880088008800f800880088008800 490301f901078000800080008000800080008000
        4a0600f905070800080008000800880088007000 4b0600f9050788009000a000c000a00090008800
        4c0500f90407800080008000800080008000f000 4d0800f907078200c600aa009200820082008200
        4e0600f90507c800c800a800a800980098008800 4f0600f905077000880088008800880088007000
        500600f90507f00088008800f000800080008000 510600f9050870008800880088008800a80070001000
        520600f90507f00088008800f000a00090008800 530600f905077000880080007000080088007000
        540600f90507f800200020002000200020002000 550600f905078800880088008800880088007000
        560600f905078800880088005000500020002000 570800f907078200820054005400280028002800
        580600f905078800880050002000500088008800 590600f905078800880050002000200020002000
        5a0500f90407f00010002000400080008000f000 5b0401f80209c0008000800080008000800080008000c000
        5c0601f8040880008000400040002000200010001000 5d0401f80209c0004000400040004000400040004000c000
        5e0400f903024000a000 5f0600ff0601fc00 600300f9020280004000 610500fb040560001000700090007000
        620500f9040780008000e000900090009000e000 630500fb040560009000800090006000
        640500f904071000100070009000900090007000 650500fb040560009000f00080006000
        660400f9040730004000e0004000400040004000 670500fb04077000900090009000700010006000
        680500f9040780008000e0009000900090009000 690300f9020740000000c0004000400040004000
        6a0400f9030920000000600020002000200020002000c000 6b0500f90407800080009000a000c000a0009000
        6c0300f90207c000400040004000400040004000 6d0800fb0705ec009200920092009200 6e0500fb0405e0009000900090009000
        6f0500fb040560009000900090006000 700500fb0407e000900090009000e00080008000
        710500fb04077000900090009000700010001000 720500fb0405b000c000800080008000 730500fb04057000800060001000e000
        740400f9030740004000e0004000400040002000 750500fb040590009000900090007000 760600fb050588005000500020002000
        770800fb070582005400540028002800 780600fb050588005000200050008800 790600fb04079000900090009000700010006000
        7a0500fb0405f000200040008000f000 7b0400f80309200040004000400080004000400040002000
        7c0200f80109800080008000800080008000800080008000 7d0400f80309800040004000400020004000400040008000
        7e0600f905026800b000 7f00000000 800701f70509500000002000200050005000f80088008800
        810701f6050a7000880070002000200050005000f80088008800 820600f90509700088008000800080008800700020004000
        830500f6040a200040000000f00080008000e00080008000f000 840600f6050a6800b0000000c800c800a800a800980098008800
        850600f70509500000007000880088008800880088007000 860600f70509500000008800880088008800880088007000
        870500f8040820004000000070009000900090007000 880500f8040840002000000070009000900090007000
        890500f8040820005000000070009000900090007000 8a0500f904075000000070009000900090007000
        8b0500f804085000a000000070009000900090007000 8c0500f70409600090006000000070009000900090007000
        8d0500fb04076000900080009000600020004000 8e0500f8040820004000000060009000f00080007000
        8f0500f8040840002000000060009000f00080006000 900500f804084000a000000060009000f00080006000
        910500f904079000000060009000f00080007000 920300f80208400080000000c0004000400040004000
        930300f80208800040000000c0004000400040004000 940400f803084000a0000000c0004000400040004000
        950400f90307a0000000c0004000400040004000 960500f804085000a0000000e0009000900090009000
        970500f8040820004000000060009000900090006000 980500f8040840002000000060009000900090006000
        990500f804084000a000000060009000900090006000 9a0500f904079000000060009000900090006000
        9b0500f804085000a000000060009000900090006000 9c0500f8040820004000000090009000900090007000
        9d0500f8040840002000000090009000900090007000 9e0500f804084000a000000090009000900090007000
        9f0500f904079000000090009000900090007000 a00400f803054000e000400040004000 a10500f804046000900090006000
        a20600f9050720007000a800a000a80070002000 a30600f90507300040004000e00040004800f000
        a40600f80509700088008000700088007000080088007000 a50600fa05057000f800f800f8007000
        a60600f905077800a800a800a800780028002800 a70600f90507700088008800b00088008800b000
        a80900f808083c004200b900a500b900a50042003c00 a90900f808083c0042009900a100a100990042003c00
        aa0900f90804f1005b0055005100 ab0401f9020240008000 ac0400f90301a000 ad0600fa05051000f8002000f8004000
        ae0900f908071f00280028007e00480088008f00 af0700f907073a0044004c00540064004400b800
        b00a00fa090563009480888094806300 b10600fa050620002000f80020002000f800 b20500fa040620004000800040002000f000
        b30500fa040640002000100020004000f000 b40600f9050788005000f8002000f80020002000
        b50600fa050890009000900090009000e80080008000 b60500f90407c000200050009000900090006000
        b70600f90507f80048002000100020004800f800 b80700f90607fc00480048004800480048004800
        b90800f9070702007c00a4002400240024004800 ba0501f7030b20004000400040004000400040004000400040008000
        bb0500f9040670009000900070000000f000 bc0500f9040660009000900060000000f000
        bd0800f8070838004400820082008200440028006c00 be0901fb07057c0092009e0090007c00
        bf0600fa060634004800580068004800b000 c00601f904072000000020004000800090006000
        c10301f901078000000080008000800080008000 c20500fc0403f00010001000 c30800f807080600040008000800d000500020002000
        c40501f7030b2000400040004000e000400040004000400040008000 c50600fa050508007000880070008000
        c60701fa050620002000500050008800f800 c70800fb060524004800900048002400 c80801fb060590004800240048009000
        c90800ff07019200 ca06000000 cb0701f70509200010002000200050005000f80088008800
        cc0701f6050a6800b00000002000200050005000f80088008800 cd0600f6050a6800b00000007000880088008800880088007000
        ce0900f908077f00880088008e00880088007f00 cf0800fb07056c0092009e0090007c00 d00500fd0401f000 d10700fd0601fc00
        d20701f804035000a000a000 d30702f8040350005000a000 d40401f80203400080008000 d50401f80203400040008000
        d60600fa050520000000f80000002000 d70800f907071000280044008200440028001000
        d80600f90509900000008800880088008800780008007000 d90900fa08067c008200870083007c004400
        """)

    init(ascent: Int32, descent: Int32, missing: String, table: String) {
        self.ascent = ascent
        self.descent = descent
        func byte(_ s: Substring, _ i: Int) -> UInt8 {
            let a = s.index(s.startIndex, offsetBy: 2 * i)
            return UInt8(s[a..<s.index(a, offsetBy: 2)], radix: 16)!
        }
        func glyph(_ entry: Substring) -> Glyph {
            let advance = Int32(byte(entry, 1))
            guard entry.count > 10 else { return Glyph(advance: advance, left: 0, top: 0, width: 0, rows: []) }
            let height = Int(byte(entry, 5))
            let rows = (0..<height).map { r in UInt16(byte(entry, 6 + 2 * r)) << 8 | UInt16(byte(entry, 7 + 2 * r)) }
            return Glyph(advance: advance, left: Int32(Int8(bitPattern: byte(entry, 2))),
                         top: Int32(Int8(bitPattern: byte(entry, 3))), width: Int32(byte(entry, 4)), rows: rows)
        }
        let missingGlyph = glyph(Substring(missing))
        var glyphs = [Glyph](repeating: missingGlyph, count: 256)
        for entry in table.split(whereSeparator: { $0 == " " || $0 == "\n" }) {
            glyphs[Int(byte(entry, 0))] = glyph(entry)
        }
        self.glyphs = glyphs
    }
}

/// The drawn window and controls.
public enum DialogDraw {
    /// The colours (x1R5G5B5), from the 16-bit QuickDraw colours of Ferazel's classic dialog look.
    public enum Colour {
        /// The content (`dctb` / Platinum dialog grey, 0xEEEE).
        public static let content: UInt16 = 0x77BD
        /// The frame's grey band (0xDDDD).
        public static let frameGrey: UInt16 = 0x6F7B
        public static let black: UInt16 = 0x0000
        public static let white: UInt16 = 0x7FFF
        /// Live text.
        public static let text: UInt16 = 0x0000
        /// Greyed (deactivated) text and outlines (`NSColor.gray`, 0x8080).
        public static let greyText: UInt16 = 0x4210
        /// The etched line's dark half (0x5000, Ferazel's `.DrawGreyOutline`).
        public static let shadow: UInt16 = 0x294A
        /// A slider's groove (0xAAAA).
        public static let groove: UInt16 = 0x56B5
    }

    /// The whole 640 × 480 picture: every command's clip.
    public static let screenClip = MacRect(top: 0, left: 0, bottom: 480, right: 640)
    /// The dBoxProc frame's width outside the content (1 black, 3 grey, 2 black).
    public static let frameWidth: Int32 = 6

    // MARK: - Primitives

    /// One solid rectangle (nil for an empty one).
    public static func rect(_ r: MacRect, _ colour: UInt16) -> RenderOp? {
        guard r.right > r.left, r.bottom > r.top else { return nil }
        return .draw(DrawCommand(face: FourCC(rawValue: 0x434F_5354), alpha: 0, clip: screenClip, drawNow: true,
                                 costRect: r, costColour: colour))
    }

    /// A frame `thickness` pixels wide inside `r` (`FrameRect` with that pen).
    public static func frame(_ r: MacRect, _ colour: UInt16, thickness t: Int32 = 1) -> [RenderOp] {
        [rect(MacRect(top: r.top, left: r.left, bottom: r.top + t, right: r.right), colour),
         rect(MacRect(top: r.bottom - t, left: r.left, bottom: r.bottom, right: r.right), colour),
         rect(MacRect(top: r.top + t, left: r.left, bottom: r.bottom - t, right: r.left + t), colour),
         rect(MacRect(top: r.top + t, left: r.right - t, bottom: r.bottom - t, right: r.right), colour)].compactMap { $0 }
    }

    /// The pixels of a w × h shape, emitted as one run per row segment.
    static func runs(in r: MacRect, _ colour: UInt16, _ inside: (Int32, Int32) -> Bool) -> [RenderOp] {
        var ops: [RenderOp] = []
        let w = r.right - r.left, h = r.bottom - r.top
        guard w > 0, h > 0 else { return ops }
        for y in 0..<h {
            var x: Int32 = 0
            while x < w {
                guard inside(x, y) else { x += 1; continue }
                var e = x + 1
                while e < w && inside(e, y) { e += 1 }
                if let op = rect(MacRect(top: r.top + y, left: r.left + x, bottom: r.top + y + 1, right: r.left + e),
                                 colour) { ops.append(op) }
                x = e
            }
        }
        return ops
    }

    /// Whether pixel (x, y) of a w × h rect lies in its rounded rect of corner radius `radius` (pixel centres).
    static func inRoundRect(_ x: Int32, _ y: Int32, w: Int32, h: Int32, radius: Int32) -> Bool {
        guard x >= 0, y >= 0, x < w, y < h else { return false }
        let r = Double(radius), px = Double(x) + 0.5, py = Double(y) + 0.5
        let cx = min(max(px, r), Double(w) - r), cy = min(max(py, r), Double(h) - r)
        return (px - cx) * (px - cx) + (py - cy) * (py - cy) <= r * r
    }

    /// A rounded rect filled with `fill` and outlined one pixel wide in `outline` (`FillRoundRect`, `FrameRoundRect`).
    public static func roundRect(_ r: MacRect, radius: Int32, fill: UInt16?, outline: UInt16?) -> [RenderOp] {
        let w = r.right - r.left, h = r.bottom - r.top
        let isIn = { (x: Int32, y: Int32) in inRoundRect(x, y, w: w, h: h, radius: radius) }
        let edge = { (x: Int32, y: Int32) in
            isIn(x, y) && !(isIn(x - 1, y) && isIn(x + 1, y) && isIn(x, y - 1) && isIn(x, y + 1))
        }
        var ops: [RenderOp] = []
        if let fill { ops += runs(in: r, fill) { x, y in isIn(x, y) && (outline == nil || !edge(x, y)) } }
        if let outline { ops += runs(in: r, outline, edge) }
        return ops
    }

    // MARK: - Text

    /// `text` with its baseline at `baseline` (the first row below the glyphs' bodies) from pen `x`, as runs, kept
    /// inside `clip` (a TextBox's rect; the screen when nil).
    public static func text(_ text: [UInt8], x: Int32, baseline: Int32, colour: UInt16, clip: MacRect? = nil,
                            font: DialogFont = .geneva9) -> [RenderOp] {
        let w = font.width(text)
        guard w > 0 else { return [] }
        // One bitmap of the whole line, then its row runs (adjacent glyphs merge).
        let top = baseline - font.ascent, h = font.lineHeight
        var bits = [[Bool]](repeating: [Bool](repeating: false, count: Int(w) + 16), count: Int(h))
        var pen: Int32 = 0
        for c in text {
            let g = font.glyph(c)
            for (i, row) in g.rows.enumerated() {
                let y = Int(font.ascent + g.top) + i
                guard y >= 0, y < Int(h) else { continue }
                for k in 0..<Int(g.width) where row & (0x8000 >> UInt16(k)) != 0 {
                    let x = Int(pen + g.left) + k
                    if x >= 0 && x < bits[y].count { bits[y][x] = true }
                }
            }
            pen += g.advance
        }
        let box = clip ?? screenClip
        let area = MacRect(top: top, left: x, bottom: top + h, right: x + w + 16)
        return runs(in: area, colour) { px, py in
            let gx = x + px, gy = top + py
            return bits[Int(py)][Int(px)] && gx >= box.left && gx < box.right && gy >= box.top && gy < box.bottom
        }
    }

    /// Static text in `rect` as the Dialog Manager's `TETextBox` lays it out (left-justified): words wrapped at
    /// spaces to the rect's width, the first baseline `ascent` below its top, one `lineHeight` per line, clipped to it.
    public static func textBox(_ text: [UInt8], in rect: MacRect, colour: UInt16,
                               font: DialogFont = .geneva9) -> [RenderOp] {
        var ops: [RenderOp] = []
        var baseline = rect.top + font.ascent
        for line in wrap(text, width: rect.right - rect.left, font: font) {
            guard baseline - font.ascent < rect.bottom else { break }
            ops += self.text(line, x: rect.left, baseline: baseline, colour: colour, clip: rect, font: font)
            baseline += font.lineHeight
        }
        return ops
    }

    /// `text` broken into lines no wider than `width` at spaces (a word wider than the line stands alone); a CR breaks.
    public static func wrap(_ text: [UInt8], width: Int32, font: DialogFont = .geneva9) -> [[UInt8]] {
        var lines: [[UInt8]] = []
        for para in text.split(separator: 0x0D, omittingEmptySubsequences: false) {
            var line: [UInt8] = []
            for word in para.split(separator: 0x20, omittingEmptySubsequences: false) {
                let candidate = line.isEmpty ? Array(word) : line + [0x20] + word
                if !line.isEmpty && font.width(candidate) > width {
                    lines.append(line)
                    line = Array(word)
                } else {
                    line = candidate
                }
            }
            lines.append(line)
        }
        return lines
    }

    // MARK: - The window

    /// The rect `bounds` (a DLOG's) takes when centred on the 640 × 480 picture (question 6; DLOG position 0x280A).
    public static func centred(_ bounds: MacRect, in screen: MacRect = screenClip) -> MacRect {
        let w = bounds.right - bounds.left, h = bounds.bottom - bounds.top
        let left = screen.left + (screen.right - screen.left - w) / 2
        let top = screen.top + (screen.bottom - screen.top - h) / 2
        return MacRect(top: top, left: left, bottom: top + h, right: left + w)
    }

    /// The window's whole rect: the content and its dBoxProc frame.
    public static func frameRect(content: MacRect) -> MacRect {
        inset(content, -frameWidth)
    }

    /// The dBoxProc window (procID 1, no title bar): 1 pixel black, 3 grey, 2 black around the content, the content
    /// filled.
    public static func window(content: MacRect) -> [RenderOp] {
        let f = frameRect(content: content)
        return [rect(f, Colour.black), rect(inset(f, 1), Colour.frameGrey), rect(inset(f, 4), Colour.black),
                rect(content, Colour.content)].compactMap { $0 }
    }

    /// Saves the picture under an outermost window (back → the save buffer, its rect only). The save-under rule:
    /// only the outermost window saves and restores; a window called from inside one (S7's controls window) draws
    /// over its parent and restores nothing, and the parent redraws itself whole when the call returns
    /// (`ModalDialogRunner.invalidate()`).
    public static func saveUnder(_ frame: MacRect) -> RenderOp {
        .copy(from: .back, to: .terrain, src: frame, dst: frame, interlaced: false)
    }

    /// Closes an outermost window: the picture under it back (save buffer → back), the save buffer refilled with the
    /// `back` image (`FUN_10009fd0`, as the menu fills it), the window's rect blitted to the screen.
    ///
    /// From the menu the save buffer held the `back` image already, so it is whole again. At boot the window opens
    /// before anything is drawn: back and the save buffer are still the fresh buffers' black, so the window is seen
    /// on a black screen, saves black and puts black back — the player sees black where it was. The save buffer then
    /// holds the `back` image earlier than the original's, which is harmless: nothing reads it before the boot's
    /// loading screen loads the same image into it again (`Boot` pass 5, X 10000564).
    public static func restoreUnder(_ frame: MacRect) -> [RenderOp] {
        [.copy(from: .terrain, to: .back, src: frame, dst: frame, interlaced: false),
         .loadImage(image: FourCC(rawValue: 0x6261_636B), into: .terrain, dst: screenClip),
         .screenBlit(src: frame, dst: frame)]
    }

    // MARK: - Controls

    /// How a push button is drawn.
    public enum ButtonLook: Equatable, Sendable {
        case normal, pressed, inactive
    }

    /// A push button (`pushButProc`): a white rounded rect (corner radius 8, or half the height less 1) outlined in
    /// black, its title centred; pressed = black with white text; inactive = grey outline and text. The default button
    /// carries the 3-pixel ring 4 pixels outside it (`FrameRoundRect` of the rect inset −4, oval 16, pen 3).
    public static func pushButton(_ r: MacRect, title: [UInt8], look: ButtonLook, isDefault: Bool = false,
                                  font: DialogFont = .geneva9) -> [RenderOp] {
        var ops: [RenderOp] = []
        let h = r.bottom - r.top
        if isDefault {
            let ring = inset(r, -4)
            let rw = ring.right - ring.left, rh = ring.bottom - ring.top
            ops += runs(in: ring, look == .inactive ? Colour.greyText : Colour.black) { x, y in
                inRoundRect(x, y, w: rw, h: rh, radius: 8)
                    && !inRoundRect(x - 3, y - 3, w: rw - 6, h: rh - 6, radius: 5)
            }
        }
        let fill = look == .pressed ? Colour.black : Colour.white
        let outline = look == .inactive ? Colour.greyText : Colour.black
        ops += roundRect(r, radius: min(8, h / 2 - 1), fill: fill, outline: outline)
        let colour = look == .pressed ? Colour.white : look == .inactive ? Colour.greyText : Colour.text
        let x = r.left + (r.right - r.left - font.width(title)) / 2
        let baseline = r.top + (h - font.lineHeight) / 2 + font.ascent
        ops += text(title, x: x, baseline: baseline, colour: colour, clip: r, font: font)
        return ops
    }

    /// A check box (`checkBoxProc`): a 12-pixel white box 2 pixels in from the left, vertically centred, outlined in
    /// black (2 pixels while pressed; grey when inactive), an X when checked; the title 5 pixels after the box.
    public static func checkBox(_ r: MacRect, title: [UInt8], checked: Bool, pressed: Bool, active: Bool,
                                font: DialogFont = .geneva9) -> [RenderOp] {
        let h = r.bottom - r.top
        let top = r.top + (h - 12) / 2
        let box = MacRect(top: top, left: r.left + 2, bottom: top + 12, right: r.left + 14)
        let ink = active ? Colour.black : Colour.greyText
        var ops = [rect(box, Colour.white)].compactMap { $0 }
        ops += frame(box, ink, thickness: pressed ? 2 : 1)
        if checked {
            ops += runs(in: inset(box, 2), ink) { x, y in x == y || x == 7 - y }
        }
        let baseline = r.top + (h - font.lineHeight) / 2 + font.ascent
        ops += text(title, x: box.right + 5, baseline: baseline, colour: active ? Colour.text : Colour.greyText,
                    clip: r, font: font)
        return ops
    }

    /// A group box (proc 164, text title): an etched rect (white, and grey 1 pixel up and left) whose top line runs
    /// through the middle of the title; the title 10 pixels in, on the content colour.
    public static func groupBox(_ r: MacRect, title: [UInt8], active: Bool, font: DialogFont = .geneva9) -> [RenderOp] {
        let line = r.top + font.lineHeight / 2
        let body = MacRect(top: line, left: r.left, bottom: r.bottom, right: r.right)
        var ops = frame(MacRect(top: body.top + 1, left: body.left + 1, bottom: body.bottom, right: body.right), Colour.white)
        ops += frame(MacRect(top: body.top, left: body.left, bottom: body.bottom - 1, right: body.right - 1), Colour.shadow)
        if !title.isEmpty {
            let x = r.left + 10, w = font.width(title)
            if let gap = rect(MacRect(top: r.top, left: x - 2, bottom: r.top + font.lineHeight, right: x + w + 2),
                              Colour.content) { ops.append(gap) }
            ops += text(title, x: x, baseline: r.top + font.ascent, colour: active ? Colour.text : Colour.greyText,
                        font: font)
        }
        return ops
    }

    /// A plain horizontal slider: a 4-pixel groove between the thumb's half-widths, vertically centred, and an
    /// 11 × 15 thumb at the value's place; inactive = grey groove outline and thumb.
    public static func slider(_ r: MacRect, value: Int, min lo: Int, max hi: Int, active: Bool) -> [RenderOp] {
        let cy = (r.top + r.bottom) / 2
        let groove = MacRect(top: cy - 2, left: r.left + thumbHalf, bottom: cy + 2, right: r.right - thumbHalf)
        let ink = active ? Colour.shadow : Colour.greyText
        var ops = [rect(groove, active ? Colour.groove : Colour.content)].compactMap { $0 }
        ops += frame(groove, ink)
        let t = sliderThumb(r, value: value, min: lo, max: hi)
        ops += [rect(t, active ? Colour.white : Colour.content)].compactMap { $0 }
        ops += frame(t, active ? Colour.black : Colour.greyText)
        return ops
    }

    static let thumbHalf: Int32 = 5
    static let thumbHeight: Int32 = 15

    /// The thumb's rect for `value` in `r`: its centre at left + 5 + (width − 11) · (value − min) / (max − min).
    public static func sliderThumb(_ r: MacRect, value: Int, min lo: Int, max hi: Int) -> MacRect {
        let span = Int64(r.right - r.left - 2 * thumbHalf - 1)
        let v = Int64(Swift.min(Swift.max(value, lo), hi) - lo), range = Int64(Swift.max(hi - lo, 1))
        let cx = r.left + thumbHalf + Int32(span * v / range)
        let top = (r.top + r.bottom) / 2 - thumbHeight / 2
        return MacRect(top: top, left: cx - thumbHalf, bottom: top + thumbHeight, right: cx + thumbHalf + 1)
    }

    /// The value whose thumb centre is nearest to `x`, pinned to min…max.
    public static func sliderValue(_ r: MacRect, x: Int32, min lo: Int, max hi: Int) -> Int {
        let span = Int64(r.right - r.left - 2 * thumbHalf - 1)
        guard span > 0 else { return lo }
        let d = Int64(x - (r.left + thumbHalf)), range = Int64(hi - lo)
        let v = (d * range * 2 + span) / (span * 2)                 // rounded to nearest (d ≥ 0)
        return d < 0 ? lo : Swift.min(Swift.max(lo + Int(v), lo), hi)
    }

    // MARK: - Geometry, hit-testing, tracking

    /// `r` moved by `origin` (window-local → the picture).
    public static func offset(_ r: MacRect, by origin: MousePoint) -> MacRect {
        MacRect(top: r.top + origin.v, left: r.left + origin.h, bottom: r.bottom + origin.v, right: r.right + origin.h)
    }

    /// `InsetRect`.
    public static func inset(_ r: MacRect, _ d: Int32) -> MacRect {
        MacRect(top: r.top + d, left: r.left + d, bottom: r.bottom - d, right: r.right - d)
    }

    /// `PtInRect`: left ≤ h < right and top ≤ v < bottom.
    public static func contains(_ r: MacRect, _ p: MousePoint?) -> Bool {
        guard let p else { return false }
        return p.h >= r.left && p.h < r.right && p.v >= r.top && p.v < r.bottom
    }

    /// The item under `p` among those `candidate` accepts (the clickable, live, shown ones), the last in item order
    /// when several hold it — the innermost, as the Dialog Manager's control hierarchy finds it (a group box precedes
    /// the controls it holds). Rects are window-local; `origin` is the content's top left in the picture.
    public static func hit(_ p: MousePoint, items: [DialogItem], origin: MousePoint,
                           candidate: (DialogItem) -> Bool) -> Int? {
        items.last { candidate($0) && contains(offset($0.rect, by: origin), p) }?.number
    }

    /// A press on a control followed until the button comes up (`TrackControl` on a button or check box): `inside`
    /// = the mouse is over the control (the control is drawn highlighted).
    public struct Press: Equatable, Sendable {
        public let item: Int
        /// The control's rect in the picture.
        public let rect: MacRect
        public private(set) var inside: Bool

        public init(item: Int, rect: MacRect, at p: MousePoint) {
            self.item = item
            self.rect = rect
            inside = DialogDraw.contains(rect, p)
        }

        /// One poll: the mouse at `mouse` (nil = unchanged), the button `down`. Returns nil while it is held, else
        /// whether it came up over the control (the item is hit).
        public mutating func poll(mouse: MousePoint?, down: Bool) -> Bool? {
            if let mouse { inside = DialogDraw.contains(rect, mouse) }
            if down { return nil }
            let hit = inside
            inside = false
            return hit
        }
    }
}

// MARK: - The modal loop

/// `ModalDialog` for a window the game draws itself (plan ruling 8): the Dialog Manager's half of a modal window —
/// the queued input, the press, the standard keys, the item-by-item draw and the redraw-only-on-change check — shared
/// by the configuration window (DITL 190) and S7's controls window (DITL 191). It holds no window's own numbers: the
/// screen opens it from its parsed `DITL` with its default and cancel items, sets the item states (`inactive`,
/// `hidden`, `values`, `labels`, `ownItems`, `screenFiltersKeys`), and feeds it every pass, in this order:
///
///     if nested window returned { runner.invalidate() }          // it drew over this one
///     runner.begin(keys: keys)
///     for _ in 0...runner.turnsLeft {
///         guard let action = runner.next(keys: keys, &out) else { break }
///         // .hit(n): ModalDialog returned item n — the screen's item action (it may finish or call)
///         // .ownPress / .ownPoll: the screen's own item (below)
///         // .key(k, command): a key the runner did not use (below)
///     }
///     // the screen's per-pass work on `keys` itself (e.g. modifier edges from `keys.held`)
///     if runner.needsRedraw() { out.ops += runner.draw { item, rect, active in nil } }
///
/// **What it does** (the standard filter and `ModalDialog`, Inside Macintosh: Macintosh Toolbox Essentials ch. 6):
/// - The pass's key events, then its mouse-downs, join a queue; events behind a held press wait for its release.
/// - Return or Enter → the default item; Esc or ⌘. → the cancel item when there is one (`standardKey`). Every
///   other key — and Esc / ⌘. when there is no cancel item — comes back as `.key(event, command:)`, the `KeyEvent`
///   exactly as the seam delivered it (char code, virtual key code, autoKey flag; `command` = ⌘ held in the pass),
///   one per turn in arrival order, interleaved with the clicks as they were queued. A screen that takes no typing
///   ignores it (the configuration window does).
/// - `screenFiltersKeys` (off by default): the screen's filter sees every key FIRST — Return, Enter, Esc and ⌘.
///   included — as `.key`, and the runner gives none of them a standard meaning. A screen that declines a key asks
///   `standardKey(_:command:)` for the item it would have hit and acts on that itself. This is the original controls
///   window's filter (grounding C §3a, X 10043f90): keyDown / autoKey events are consumed by the key capture, so
///   Return / Esc / Tab / arrows / F-keys are bindable and never press Save or Cancel. Modifier keys alone make no
///   key event; the original reads them as `GetKeys` edges on null events — the screen reads them from the pass's
///   `keys.held` itself, which `begin` / `next` leave alone.
/// - A click outside the window beeps (`SysBeep`, a `.beep` request). A click inside the window on no live item —
///   the 6-pixel frame, the bare content, a greyed or disabled item — does nothing: no item, no beep (the click is
///   in the front window, so `ModalDialog` takes it and finds no control).
/// - A click on a live, enabled, shown push button or check box is tracked (`TrackControl`) until the button comes
///   up: drawn highlighted while the mouse is over it, the item reported only when it comes up over it. A press is
///   polled once in the turn that starts it.
/// - Bounded: each turn polls the press once (and ends the pass's input while it is held) or consumes one event; at
///   most the queue + 2 turns a pass (`turnsLeft`, set by `begin`).
///
/// **Extension point — item kinds the runner does not know** (the configuration window's sliders; S7's edit-text
/// field, focus ring, tab control and picture). Put the item's number in `ownItems`: a click on it comes back as
/// `.ownPress(item:at:)` — the screen tracks it itself and polls it at once — then as `.ownPoll(item:)` once in each
/// later pass while it is held; the screen calls `endOwnPress()` when the button comes up (at once, for a click
/// that only moves focus) and decides whether the item was hit. Any live, enabled, shown item can be one, whatever
/// its kind (edit text, a `CNTL` such as the tab control); the innermost holding the point wins, so a field inside
/// the tab control's rect takes its own clicks. To draw, `draw(own:)` asks the screen first for every shown item, in
/// item order, over the frame and content: the screen returns that item's ops (any `RenderOp` — the `DialogDraw`
/// primitives, `.drawPicture` for a `PICT` item, its own focus ring or tabs), or nil to let the runner draw it (push
/// buttons, check boxes, static text; any other kind left to nil is not drawn). The closure may read the screen's
/// own state (which field has focus, which tab is up). The runner redraws only when its own item state changes
/// (`needsRedraw`; a field's text kept in `labels` counts); when state it cannot see changes — focus moved, the
/// tab — the screen calls `invalidate()` and the whole window is drawn at the next check.
///
/// **Save-under rule.** Only the outermost window saves and restores the picture under it (`DialogDraw.saveUnder`
/// at open, `DialogDraw.restoreUnder` at close — the screen emits them, the runner does not). A window opened from
/// inside another draws over its parent and restores nothing; when it returns, the parent calls `invalidate()` and
/// redraws itself whole.
public struct ModalDialogRunner: Sendable {
    /// What a turn produced for the screen.
    public enum Action: Equatable, Sendable {
        /// `ModalDialog` returned item `n`.
        case hit(Int)
        /// A press began on item `n`, one of `ownItems`, at `at`: the screen's to track (poll it now).
        case ownPress(item: Int, at: MousePoint)
        /// The screen's own press on item `n` is still being followed: poll it once.
        case ownPoll(item: Int)
        /// A key the runner did not use (or, with `screenFiltersKeys`, any key), as the seam delivered it;
        /// `command` = ⌘ held in the pass.
        case key(KeyEvent, command: Bool)
    }

    /// What a press is following.
    public enum Tracking: Equatable, Sendable {
        /// A push button or check box, tracked here.
        case press(DialogDraw.Press)
        /// One of `ownItems`, tracked by the screen.
        case own(item: Int)
    }

    /// One queued input.
    enum Event: Equatable, Sendable {
        case key(KeyEvent, command: Bool)
        case click(MousePoint)
    }

    /// Everything the drawn picture depends on: a change redraws.
    struct Look: Equatable, Sendable {
        var inactive: Set<Int>
        var hidden: Set<Int>
        var values: [Int: Int]
        var labels: [Int: [UInt8]]
        var tracking: Tracking?
    }

    /// The parsed `DITL`'s items (rects window-local).
    public let items: [DialogItem]
    /// The content rect in the picture, and the whole window (content and frame): what the screen saves and restores.
    public let content: MacRect
    public let windowRect: MacRect
    /// The content's top left in the picture.
    public var origin: MousePoint { MousePoint(h: content.left, v: content.top) }
    /// Return and Enter hit it; it carries the default ring.
    public let defaultItem: Int
    /// Esc and ⌘. hit it; nil = none (they do nothing).
    public var cancelItem: Int?
    /// Deactivated items (drawn grey, take no click).
    public var inactive: Set<Int> = []
    /// Hidden items (not drawn, take no click).
    public var hidden: Set<Int> = []
    /// Control values (check boxes 0/1; the screen's own controls whatever they hold).
    public var values: [Int: Int] = [:]
    /// Item texts set at run time (`SetDialogItemText`); the `DITL`'s text otherwise.
    public var labels: [Int: [UInt8]] = [:]
    /// The extension point: items the screen tracks and (usually) draws itself.
    public var ownItems: Set<Int> = []
    /// The screen's filter sees every key first, Return / Enter / Esc / ⌘. included, as `.key` (S7's key capture);
    /// off = those keys hit the default and cancel items.
    public var screenFiltersKeys = false
    public private(set) var tracking: Tracking?
    /// Turns left this pass (see `begin`).
    public private(set) var turnsLeft = 0
    private var queue: [Event] = []
    /// The screen's own press has had its poll this pass.
    private var ownPolled = false
    /// The picture last drawn; nil = draw at the next check.
    private var drawn: Look?

    public init(items: [DialogItem], content: MacRect, defaultItem: Int, cancelItem: Int?) {
        self.items = items
        self.content = content
        windowRect = DialogDraw.frameRect(content: content)
        self.defaultItem = defaultItem
        self.cancelItem = cancelItem
    }

    // MARK: Item state

    /// Item `n` is live (not deactivated).
    public func isActive(_ n: Int) -> Bool { !inactive.contains(n) }
    /// Item `n`'s control value.
    public func value(_ n: Int) -> Int { values[n] ?? 0 }
    /// Item `n`'s text as shown (set at run time, else the `DITL`'s).
    public func label(_ n: Int) -> [UInt8] { labels[n] ?? item(n)?.text ?? [] }
    /// Item `n` (1-based), nil when there is none.
    public func item(_ n: Int) -> DialogItem? { items.indices.contains(n - 1) ? items[n - 1] : nil }
    /// Item `n`'s rect in the picture.
    public func rect(_ n: Int) -> MacRect? { item(n).map { DialogDraw.offset($0.rect, by: origin) } }

    // MARK: Input

    /// Starts a pass: its key events (with Command held or not), then its mouse-downs, join the queue.
    public mutating func begin(keys: HeldKeys) {
        let command = keys.held.contains(0x37) || keys.held.contains(0x36)
        queue += keys.keyEvents.map { Event.key($0, command: command) }
        queue += keys.mouseDowns.map(Event.click)
        turnsLeft = queue.count + 2
        ownPolled = false
    }

    /// The next thing for the screen to act on this pass, or nil when the pass's input is done (or waits behind a
    /// held press). Each call uses at least one turn.
    public mutating func next(keys: HeldKeys, _ out: inout PassOutput) -> Action? {
        for _ in 0..<max(turnsLeft, 0) {
            turnsLeft -= 1
            switch tracking {
            case var .press(press)?:
                guard let inside = press.poll(mouse: keys.mouse, down: keys.mouseButton) else {
                    tracking = .press(press)
                    return stop()
                }
                tracking = nil
                if inside { return .hit(press.item) }
                continue
            case let .own(n)?:
                if ownPolled { return stop() }                          // still held after its poll: the rest waits
                ownPolled = true
                return .ownPoll(item: n)
            case nil:
                break
            }
            guard !queue.isEmpty else { return stop() }
            switch queue.removeFirst() {
            case let .key(k, command):
                if !screenFiltersKeys, let n = standardKey(k, command: command) { return .hit(n) }
                return .key(k, command: command)
            case let .click(p):
                guard DialogDraw.contains(windowRect, p) else {         // outside the modal window
                    out.requests.append(.beep)
                    continue
                }
                // Inside the window (its frame included) on no live item: nothing.
                guard let n = DialogDraw.hit(p, items: items, origin: origin, candidate: takesClick) else { continue }
                if ownItems.contains(n) {
                    tracking = .own(item: n)
                    ownPolled = true                                    // the screen polls it with the press
                    return .ownPress(item: n, at: p)
                }
                var press = DialogDraw.Press(item: n, rect: rect(n) ?? content, at: p)
                guard let inside = press.poll(mouse: keys.mouse, down: keys.mouseButton) else {
                    tracking = .press(press)
                    return stop()
                }
                if inside { return .hit(n) }
            }
        }
        turnsLeft = 0
        return nil
    }

    /// The item key `k` stands for in the standard filter: Return or Enter → the default item; Esc or ⌘. → the
    /// cancel item when there is one; nil for any other key.
    public func standardKey(_ k: KeyEvent, command: Bool) -> Int? {
        if k.charCode == 0x0D || k.charCode == 0x03 { return defaultItem }                       // Return, Enter
        if let c = cancelItem, k.charCode == 0x1B || (command && k.charCode == 0x2E) { return c } // Esc, ⌘.
        return nil
    }

    /// The pass's input ends here.
    private mutating func stop() -> Action? {
        turnsLeft = 0
        return nil
    }

    /// A live, enabled, shown push button or check box, or one of the screen's own items.
    private func takesClick(_ item: DialogItem) -> Bool {
        item.enabled && !hidden.contains(item.number) && !inactive.contains(item.number)
            && (ownItems.contains(item.number) || item.kind == .button || item.kind == .checkBox)
    }

    /// The screen's own press is over (the button came up).
    public mutating func endOwnPress() {
        if case .own? = tracking { tracking = nil }
    }

    /// The window is closing: no press, no queued input.
    public mutating func close() {
        tracking = nil
        queue = []
        turnsLeft = 0
    }

    // MARK: Drawing

    /// Draw at the next check (a nested window drew over this one).
    public mutating func invalidate() { drawn = nil }

    /// Whether the picture changed since it was last drawn; true records it as drawn (the screen then draws).
    public mutating func needsRedraw() -> Bool {
        let now = Look(inactive: inactive, hidden: hidden, values: values, labels: labels, tracking: tracking)
        guard now != drawn else { return false }
        drawn = now
        return true
    }

    /// The whole window — frame, content, every shown item in item order — then its rect blitted to the screen.
    /// `own` is the extension point: the ops of an item the screen draws itself (given the item, its rect in the
    /// picture and whether it is live), or nil for the runner's own drawing.
    public func draw(own: (DialogItem, MacRect, Bool) -> [RenderOp]?) -> [RenderOp] {
        var ops = DialogDraw.window(content: content)
        var pressed: Int?
        if case let .press(p)? = tracking, p.inside { pressed = p.item }
        for item in items where !hidden.contains(item.number) {
            let n = item.number, r = DialogDraw.offset(item.rect, by: origin), active = isActive(n)
            if let mine = own(item, r, active) {
                ops += mine
                continue
            }
            switch item.kind {
            case .button:
                let look: DialogDraw.ButtonLook = !active ? .inactive : pressed == n ? .pressed : .normal
                ops += DialogDraw.pushButton(r, title: item.text, look: look, isDefault: n == defaultItem)
            case .checkBox:
                ops += DialogDraw.checkBox(r, title: item.text, checked: value(n) != 0, pressed: pressed == n,
                                           active: active)
            case .staticText:
                ops += DialogDraw.textBox(label(n), in: r,
                                          colour: active ? DialogDraw.Colour.text : DialogDraw.Colour.greyText)
            default:
                break
            }
        }
        ops.append(.screenBlit(src: windowRect, dst: windowRect))
        return ops
    }
}
