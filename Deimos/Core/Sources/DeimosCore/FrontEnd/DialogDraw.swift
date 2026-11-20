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
// origin; S7's controls window (DITL 191) reuses the frame, buttons, text, measuring, hit-testing and tracking.

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
    private let glyphs: [Glyph?]

    /// The glyph of Mac Roman byte `c`; nil when the face has none (drawn as nothing, advancing nothing).
    public func glyph(_ c: UInt8) -> Glyph? { glyphs[Int(c)] }

    /// The pen advance of `text` (`TextWidth`).
    public func width(_ text: [UInt8]) -> Int32 {
        text.reduce(Int32(0)) { $0 + (glyphs[Int($1)]?.advance ?? 0) }
    }

    /// Geneva 9 plain. Source: the committed CoreText bake `BubbleTroubleX/Windows/Resources/Fonts/Geneva-9.btxfont`;
    /// rule: each glyph's phase-0 bitmap, a pixel kept when its coverage is at least half (≥ 128 of 255), cropped to
    /// its set pixels; the advance rounded; ascent 9 (the face's 9.0), descent 3 (2.25 rounded up). Covers printable
    /// ASCII and the ellipsis 0xC9 — every character of DITL 190/191 and STR# 130/131. Baked once by a scratch script
    /// outside the repo. Per glyph: `CC AA LL TT WW HH` (byte, advance, left, top as signed bytes, width, height) then
    /// HH rows of four hex digits; a glyph with no pixels is `CC AA 000000`.
    public static let geneva9 = DialogFont(ascent: 9, descent: 3, table: """
        2003000000 210301f901078000800080008000800000008000 220401f90302a000a000
        230601f9040740005000f0000000b000a0002000 240601f90407700080008000600030001000f000
        250800f908076000a40088006600150025000200 260700f906073000400030006400140088007c00 270301f9010280008000
        280401f9020840008000800080008000800080004000 290401f9020880004000400040004000400040008000
        2a0501f903034000e0004000 2b0601fd0401f000 2c0301ff010280008000 2d0301fd0201c000 2e0301ff01018000
        2f0501fa030520000000400000008000 300601f904076000900090000000900090006000
        310602f90207c000400040004000400040004000 320601f90407f00010001000200040008000f000
        330601f90407e00010002000600010001000e000 340601f904073000300050009000f00010001000
        350601f90407f00080008000600010001000e000 360601f90407700080008000f000900090007000
        370601f90406f00010002000200040004000 380601f90407f00090009000600090009000f000
        390601f90407e00090009000b00010001000e000 3a0301fb010580000000000000008000
        3b0301fb0106800000000000000080008000 3c0601fc04042000c00060001000 3d0601fc0403f0000000f000
        3e0601fc04044000300060008000 3f0501f90305e0002000200040004000 400801f9060748008400100050007c0080005000
        410700f906071000300028000800780044008400 420601f90407e00090009000e00090009000f000
        430600f905073800400040008000400040003800 440601f90507f00090008800880088009000e000
        450501f90407e00080008000e00080008000f000 460501f90307e00080008000e000800080008000
        470600f9060738004000400080004c0044003800 480601f90507880088008800f800880088008800
        490201f901078000800080008000800080008000 4a0401f90307200020002000200020002000c000
        4b0601f904079000a000c000c000e000a0009000 4c0501f90407800080008000800080008000f000
        4d0701f9050688008800c800500070002000 4e0601f9050788008800c8002800280018000800
        4f0700f906073800440044008400440044003800 500501f90407e00090009000a000800080008000
        510700f90709380044004400840044004400380008000600 520501f90407e00090009000e000a000a0009000
        530501f90407f00080008000600010001000f000 540600f90507f800200020002000200020002000 550601fe04028000f000
        560700f906078400440040004800280030001000 570900f908078900590051005400460026002200
        580500f905074800400030002000300050008800 590500f905078800480030002000200020002000
        5a0500f90507780010001000200040004000f800 5b0401f9020980008000800080008000800080008000c000
        5c0501fa030580000000400000002000 5d0401f9020940004000400040004000400040004000c000
        5e0601fa04046000600090009000 5f0601000401f000 600502f901018000 610501fb0305e00000006000a000e000
        620501fb0405e000900090009000e000 630500fb040570004000800040007000 640500f905070800080078004800880048007800
        650500fb050530004800f00000007000 660401f90207c0008000c0008000800080008000
        670500fb05077800480088000800780008007000 680501fb0405e0009000100010001000 6902000000
        6a0200f90209400000004000400040004000400040008000 6b0501fb03052000c000c00040002000 6c02000000
        6d0801fb0602ec009000 6e0501fb0405e0009000100010001000 6f0500fb050570004800880048007000
        700501fb0405e000900010009000e000 710500fb05077800480088004800780008000800 720301fb0203c00080008000
        730501fb0305e0000000e0002000e000 740401fa02068000c0008000800080004000 750501fb04051000100010001000f000
        760500fb050588004000500070002000 770700fb0705920010006c006c006c00 780501fb03052000e0004000e0002000
        790500fb0507880040005000300020002000c000 7a0501fb0305e000200040008000e000
        7b0401f90206400000004000000080004000 7c02000000 7d0401f9020580000000000000004000 7e0601fd0401f000
        c90901ff07019200
        """)

    init(ascent: Int32, descent: Int32, table: String) {
        self.ascent = ascent
        self.descent = descent
        var glyphs = [Glyph?](repeating: nil, count: 256)
        func byte(_ s: Substring, _ i: Int) -> UInt8 {
            let a = s.index(s.startIndex, offsetBy: 2 * i)
            return UInt8(s[a..<s.index(a, offsetBy: 2)], radix: 16)!
        }
        for entry in table.split(whereSeparator: { $0 == " " || $0 == "\n" }) {
            let c = byte(entry, 0), advance = Int32(byte(entry, 1))
            guard entry.count > 10 else {
                glyphs[Int(c)] = Glyph(advance: advance, left: 0, top: 0, width: 0, rows: [])
                continue
            }
            let height = Int(byte(entry, 5))
            let rows = (0..<height).map { r in UInt16(byte(entry, 6 + 2 * r)) << 8 | UInt16(byte(entry, 7 + 2 * r)) }
            glyphs[Int(c)] = Glyph(advance: advance, left: Int32(Int8(bitPattern: byte(entry, 2))),
                                   top: Int32(Int8(bitPattern: byte(entry, 3))), width: Int32(byte(entry, 4)),
                                   rows: rows)
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
            guard let g = font.glyph(c) else { continue }
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

    /// Saves the picture under an outermost window (back → the save buffer, its rect only). Only the outermost
    /// window saves: a window called from inside one (S7's controls window) draws over its caller, which repaints
    /// itself when the call returns.
    public static func saveUnder(_ frame: MacRect) -> RenderOp {
        .copy(from: .back, to: .terrain, src: frame, dst: frame, interlaced: false)
    }

    /// Closes an outermost window: the picture under it back (save buffer → back), the save buffer made whole again
    /// (the screens that call a dialog — the boot and the menu — keep the `back` image there, `FUN_10009fd0`), the
    /// window's rect blitted to the screen.
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
