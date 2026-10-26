import FerazelCore
import Foundation

/// Draws a `DialogWindow` into the 640×480 game picture (WF4a, D43 Ruling 4, ◇W10) as the Mac's classic-style views
/// draw it (`Ferazel/App/Dialogs/DialogViews.swift`: black outlines on the `dctb` grey, the system font 12, the OK
/// ring) — not BTX's Aqua look (`BTXWinKit/DialogRenderer.swift`, whose shape helpers are adapted here). The text is
/// the baked dialog face, font 0 face 1 at 12 pt (`BakedTextRasterizer`, Ruling 2) — the Mac's `ClassicFont` pick
/// (Charcoal / Chicago absent: `.boldSystemFont(ofSize: 12)`), measured equal (WinDialogTests 11). Shapes are
/// anti-aliased by analytic coverage at pixel centres, as CoreGraphics strokes the Mac's paths.
///
/// | Mac view | here |
/// |---|---|
/// | `DialogRootView` | black outer rect; 1 px in, the frame grey 0xDDDDDD; 4 px in, black; 6 px in, the content colour |
/// | `ClassicButton` | rounded rect (radius min(8, h/2 − 1) on the path inset ½), white (black when hilited), 1 px black outline; the title centred by its width, `((h − 15) / 2).rounded()` from the top, white when hilited |
/// | `ClassicStaticText` | word-wrapped in the item width, lines 15 px apart, baseline 12 below each line's top, clipped to the rect |
/// | `ClassicPicture` | the PICT scaled into the item rect, nearest neighbour |
/// | `outlineDefault` | the item rect `InsetRect(−4, −4)`, pen 3, corner radius 6 on the path inset 1.5 |
/// | `ClassicCheckBox` (WF4b) | a 12-px white box at (2, ((h − 12) / 2).rounded()), 1-px outline (2 px while pressed), an X corner to corner when set; the title 5 px after the box, centred like a button's |
/// | `ClassicPopup` (WF4b) | the box (w − 1) × (h − 1) white, 1-px outline, a 1-px black shadow right and below (from 2 px in), a 10 × 5 down triangle 6 px from the right, the current item's name at x 13 clipped short of the triangle |
/// | `ClassicEditText` (WF4b) | a white rect 3 px outside the item with a 1-px black outline; the text at the item's top left; selected: the text's width in the `HiliteColor` (empty: the blinking 1-px insertion point) |
/// | `.DrawGreyOutline` (WF4b) | Options' item 5: a white 1-px frame of the rect, then the rect moved (−1, −1) framed in 0x505050, under the items |
/// | an open popup menu (WF4b) | ◇ the Mac's is an `NSMenu`: here a white box, 1-px black outline and shadow, 18-px rows, the current item checked, the row under the mouse inverted |
///
/// An inactive control (`HiliteControl(255)`) is outlined and lettered in `NSColor.gray`; a hidden item is not drawn;
/// a dialog that paints its own content (`canvas`, the credits) shows those pixels instead of its items.
///
/// Not drawn: the Mac panel's macOS window shadow (a modern window's, not the dBoxProc's).
@MainActor public final class DialogRenderer {
    public static let font: Int16 = 0, size: Int16 = 12, face: Int16 = 1
    /// `NSLayoutManager.defaultLineHeight` / `defaultBaselineOffset` of the Mac's pick (measured, test 11).
    public static let lineHeight = 15, ascent = 12
    static let black: UInt32 = 0x000000, white: UInt32 = 0xFFFFFF
    static let frameGrey: UInt32 = 0xDDDDDD
    /// `.DrawGreyOutline`'s RGB (0x5000, 0x5000, 0x5000).
    static let outlineGrey: UInt32 = 0x505050
    /// `NSColor.gray` (the dimmed text and outline of an inactive item).
    static let dimmed: UInt32 = 0x808080

    public let text: BakedTextRasterizer

    public init(text: BakedTextRasterizer) { self.text = text }

    /// The string's advance in the dialog face (the Mac's `NSAttributedString.size().width`), fractional.
    public func width(_ s: String) -> Double {
        guard let f = text.face(Self.font, Self.size, Self.face) else { return 0 }
        return text.layout(s, in: f).advance
    }

    /// The OK ring's rect: `InsetRect(item, −4, −4)`.
    public static func ringRect(_ r: DialogRect) -> DialogRect { r.insetBy(-4, -4) }

    // MARK: Onto the picture

    /// Draws `w` at its origin into `rgba` (640×480 R, G, B, A rows; clipped).
    func composite(_ w: DialogWindow, into rgba: inout [UInt8], width: Int = WinCanvas.width,
                   height: Int = WinCanvas.height) {
        Self.put(render(w), atX: w.originX, y: w.originY, into: &rgba, width: width, height: height)
        if let m = w.menu {
            Self.put(renderMenu(m, of: w), atX: w.contentX + m.rect.x, y: w.contentY + m.rect.y, into: &rgba,
                     width: width, height: height)
        }
    }

    /// A pixel the menu image leaves as it is (its shadow's missing corners).
    static let clearKey: UInt32 = 0xFF00_0000

    private static func put(_ body: Image, atX ox: Int, y oy: Int, into rgba: inout [UInt8], width: Int, height: Int) {
        for row in 0..<body.height {
            let y = oy + row
            guard y >= 0, y < height else { continue }
            for col in 0..<body.width {
                let x = ox + col
                guard x >= 0, x < width else { continue }
                let c = body.pixels[row * body.width + col]
                guard c != clearKey else { continue }
                let at = 4 * (y * width + x)
                rgba[at] = UInt8(c >> 16 & 0xFF)
                rgba[at + 1] = UInt8(c >> 8 & 0xFF)
                rgba[at + 2] = UInt8(c & 0xFF)
                rgba[at + 3] = 0xFF
            }
        }
    }

    /// An opaque 0xRRGGBB image.
    struct Image {
        let width: Int, height: Int
        var pixels: [UInt32]

        init(width: Int, height: Int, fill: UInt32) {
            self.width = width
            self.height = height
            pixels = [UInt32](repeating: fill, count: width * height)
        }

        subscript(x: Int, y: Int) -> UInt32 {
            get { pixels[y * width + x] }
            set { pixels[y * width + x] = newValue }
        }
    }

    /// The panel, frame included: the frame, the shown items in item order, then the rings.
    func render(_ w: DialogWindow) -> Image {
        let f = w.frame, fw = DialogWindow.frameWidth
        var img = Image(width: f.width, height: f.height, fill: Self.black)
        Self.fill(&img, DialogRect(x: 1, y: 1, width: f.width - 2, height: f.height - 2), Self.frameGrey)
        Self.fill(&img, DialogRect(x: fw - 2, y: fw - 2, width: f.width - 2 * (fw - 2), height: f.height - 2 * (fw - 2)),
                  Self.black)
        Self.fill(&img, DialogRect(x: fw, y: fw, width: f.width - 2 * fw, height: f.height - 2 * fw), w.contentRGB)
        if let c = w.canvas {
            for y in 0..<min(c.height, f.height - 2 * fw) {
                for x in 0..<min(c.width, f.width - 2 * fw) { img[fw + x, fw + y] = c[x, y] }
            }
        } else {
            for n in w.greyOutlines {
                guard let r = w.item(n)?.rect else { continue }
                Self.frameRect(&img, r.offsetBy(fw, fw), Self.white)
                Self.frameRect(&img, r.offsetBy(fw - 1, fw - 1), Self.outlineGrey)
            }
            for item in w.items where !w.isHidden(item.number) { draw(item, of: w, into: &img, dx: fw, dy: fw) }
        }
        for n in w.outlines {
            guard let r = w.item(n)?.rect else { continue }
            let o = Self.ringRect(r).offsetBy(fw, fw)
            Self.strokeRoundRect(&img, Self.box(o), radius: 7.5, width: 3, rgb: Self.black)
        }
        return img
    }

    private func draw(_ item: DialogItem, of w: DialogWindow, into img: inout Image, dx: Int, dy: Int) {
        let r = item.rect.offsetBy(dx, dy)
        let ink = w.isActive(item.number) ? Self.black : Self.dimmed
        switch item.item.kind {
        case .button:
            let lit = w.isHighlighted(item.number)
            let radius = Double(min(8, r.height / 2 - 1)) + 0.5
            Self.fillRoundRect(&img, Self.box(r), radius: radius, rgb: lit ? Self.black : Self.white)
            Self.strokeRoundRect(&img, Self.box(r), radius: radius, width: 1, rgb: ink)
            let title = w.text(item.number)
            let x = r.x + Int(((Double(r.width) - width(title)) / 2).rounded())
            let top = r.y + Int((Double(r.height - Self.lineHeight) / 2).rounded())
            draw(title, x: x, baseline: top + Self.ascent, rgb: lit ? Self.white : ink, clip: nil, into: &img)
        case .checkBox, .radioButton:
            let b = DialogRect(x: r.x + 2, y: r.y + Int((Double(r.height - 12) / 2).rounded()), width: 12, height: 12)
            Self.fill(&img, b, Self.white)
            let pen = w.isPressed(item.number) ? 2 : 1
            for i in 0..<pen { Self.frameRect(&img, b.insetBy(i, i), ink) }
            if w.value(item.number) != 0 {
                Self.line(&img, Double(b.x), Double(b.y), Double(b.maxX), Double(b.maxY), ink)
                Self.line(&img, Double(b.maxX), Double(b.y), Double(b.x), Double(b.maxY), ink)
            }
            let top = r.y + Int((Double(r.height - Self.lineHeight) / 2).rounded())
            draw(w.text(item.number), x: b.maxX + 5, baseline: top + Self.ascent, rgb: ink, clip: r, into: &img)
        case .control:
            let b = DialogRect(x: r.x, y: r.y, width: r.width - 1, height: r.height - 1)
            Self.fill(&img, DialogRect(x: r.x + 2, y: b.maxY, width: b.width - 1, height: 1), Self.black)
            Self.fill(&img, DialogRect(x: b.maxX, y: r.y + 2, width: 1, height: b.height - 1), Self.black)
            Self.fill(&img, b, Self.white)
            Self.frameRect(&img, b, ink)
            let tx = b.width - 10 - 6, ty = Int((Double(b.height) / 2 - 2).rounded())
            Self.fillTriangle(&img, (Double(r.x + tx), Double(r.y + ty)), (Double(r.x + tx + 10), Double(r.y + ty)),
                              (Double(r.x + tx + 5), Double(r.y + ty + 5)), ink)
            let titles = w.popupTitles[item.number] ?? []
            let v = w.value(item.number)
            guard v >= 1, v <= titles.count else { break }
            let top = r.y + Int((Double(b.height - Self.lineHeight) / 2).rounded())
            let clip = DialogRect(x: r.x + 4, y: r.y, width: max(0, tx - 8), height: b.height)
            draw(titles[v - 1], x: r.x + 13, baseline: top + Self.ascent, rgb: ink, clip: clip, into: &img)
        case .editText:
            let frame = r.insetBy(-3, -3)
            Self.fill(&img, frame, Self.white)
            Self.frameRect(&img, frame, Self.black)
            let s = w.text(item.number)
            if w.selected == item.number {
                if s.isEmpty {
                    if w.caretVisible {
                        Self.fill(&img, DialogRect(x: r.x, y: r.y, width: 1, height: Self.lineHeight), Self.black)
                    }
                } else {
                    let wide = min(Int(width(s).rounded(.up)), r.width)
                    Self.fill(&img, DialogRect(x: r.x, y: r.y, width: wide, height: Self.lineHeight), w.hiliteRGB)
                }
            }
            draw(s, x: r.x, baseline: r.y + Self.ascent, rgb: Self.black, clip: r, into: &img)
        case .staticText:
            for (i, line) in wrap(w.text(item.number), width: r.width).enumerated() {
                draw(line, x: r.x, baseline: r.y + Self.ascent + i * Self.lineHeight, rgb: Self.black, clip: r,
                     into: &img)
            }
        case .picture:
            if let p = w.pictures[item.number] { Self.blit(&img, p, into: r) }
        default:
            break   // user items draw nothing of their own (Options' item 5: `greyOutlines`)
        }
    }

    /// The front dialog's open popup menu, in canvas pixels (it may hang outside the panel).
    func renderMenu(_ m: DialogPopupMenu, of w: DialogWindow) -> Image {
        var img = Image(width: m.rect.width + 1, height: m.rect.height + 1, fill: Self.black)
        let box = DialogRect(x: 0, y: 0, width: m.rect.width, height: m.rect.height)
        Self.fill(&img, DialogRect(x: 0, y: m.rect.height, width: 1, height: 1), Self.clearKey)
        Self.fill(&img, DialogRect(x: m.rect.width, y: 0, width: 1, height: 1), Self.clearKey)
        Self.fill(&img, box.insetBy(1, 1), Self.white)
        let titles = w.popupTitles[m.item] ?? []
        let current = w.value(m.item) - 1
        for (i, row) in m.rows.enumerated() where i < titles.count {
            let rr = DialogRect(x: row.x - m.rect.x, y: row.y - m.rect.y, width: row.width, height: row.height)
            let lit = m.highlighted == i
            if lit { Self.fill(&img, DialogRect(x: 1, y: rr.y, width: box.width - 2, height: rr.height), Self.black) }
            let ink = lit ? Self.white : Self.black
            let top = rr.y + (rr.height - Self.lineHeight) / 2
            if i == current {
                // The check mark: a short stroke down-right, then a long one up-right.
                let cx = 5.0, cy = Double(top) + 8
                Self.line(&img, cx, cy, cx + 3, cy + 3, ink)
                Self.line(&img, cx + 3, cy + 3, cx + 9, cy - 4, ink)
            }
            draw(titles[i], x: DialogWindow.menuTextInset, baseline: top + Self.ascent, rgb: ink,
                 clip: DialogRect(x: 1, y: rr.y, width: box.width - 2, height: rr.height), into: &img)
        }
        return img
    }

    // MARK: Text

    /// The Mac's `NSStringDrawing` word wrap (`.byWordWrapping`, no line-fragment padding) in `width` px: line ends
    /// break; a line takes words while it fits without its trailing spaces; a word wider than a line breaks by
    /// characters. Lines are returned without their trailing spaces.
    func wrap(_ s: String, width maxWidth: Int) -> [String] {
        let limit = Double(maxWidth)
        var lines: [String] = []
        for paragraph in s.split(separator: "\n", omittingEmptySubsequences: false) {
            var line = ""
            var word = ""
            func fits(_ t: String) -> Bool { width(Self.trailingTrimmed(t)) <= limit }
            func flushWord() {
                guard !word.isEmpty else { return }
                if line.isEmpty || fits(line + word) {
                    line += word
                } else {
                    lines.append(Self.trailingTrimmed(line))
                    line = word
                }
                while !fits(line), line.count > 1 {
                    var head = ""
                    for c in line {
                        if !fits(head + String(c)), !head.isEmpty { break }
                        head.append(c)
                    }
                    lines.append(head)
                    line = String(line.dropFirst(head.count))
                }
                word = ""
            }
            for c in paragraph {
                word.append(c)
                if c == " " { flushWord() }
            }
            flushWord()
            lines.append(Self.trailingTrimmed(line))
        }
        return lines
    }

    static func trailingTrimmed(_ s: String) -> String {
        var t = s
        while t.last == " " { t.removeLast() }
        return t
    }

    /// `s` with its pen at (x, baseline), in `rgb`, clipped to `clip` when given.
    func draw(_ s: String, x: Int, baseline: Int, rgb: UInt32, clip: DialogRect?, into img: inout Image) {
        guard !s.isEmpty else { return }
        let m = text.rasterize(s, font: Self.font, size: Self.size, face: Self.face)
        let bounds = clip ?? DialogRect(x: 0, y: 0, width: img.width, height: img.height)
        for row in 0..<m.height {
            let py = baseline + m.top + row
            guard py >= max(0, bounds.y), py < min(img.height, bounds.maxY) else { continue }
            for col in 0..<m.width {
                let c = m.coverage[row * m.width + col]
                guard c != 0 else { continue }
                let px = x + m.left + col
                guard px >= max(0, bounds.x), px < min(img.width, bounds.maxX) else { continue }
                img[px, py] = c == 255 ? rgb : Self.mix(img[px, py], rgb, Double(c) / 255)
            }
        }
    }

    // MARK: Shapes (adapted from BTX's: analytic coverage at pixel centres)

    typealias Box = (x0: Double, y0: Double, x1: Double, y1: Double)

    static func box(_ r: DialogRect) -> Box { (Double(r.x), Double(r.y), Double(r.maxX), Double(r.maxY)) }

    /// Coverage (0…1) of the pixel centred at (px, py) by the rounded rect `b`.
    static func coverage(_ px: Double, _ py: Double, _ b: Box, _ radius: Double) -> Double {
        let hw = (b.x1 - b.x0) / 2, hh = (b.y1 - b.y0) / 2
        guard hw > 0, hh > 0 else { return 0 }
        let r = max(0, min(radius, min(hw, hh)))
        let dx = abs(px - (b.x0 + hw)) - (hw - r), dy = abs(py - (b.y0 + hh)) - (hh - r)
        let outside = (max(dx, 0) * max(dx, 0) + max(dy, 0) * max(dy, 0)).squareRoot()
        let sdf = outside + min(max(dx, dy), 0) - r
        return max(0, min(1, 0.5 - sdf))
    }

    static func mix(_ dst: UInt32, _ rgb: UInt32, _ a: Double) -> UInt32 {
        func ch(_ shift: UInt32) -> UInt32 {
            let d = Double((dst >> shift) & 0xFF), s = Double((rgb >> shift) & 0xFF)
            return UInt32((s * a + d * (1 - a)).rounded()) << shift
        }
        return ch(16) | ch(8) | ch(0)
    }

    /// `FrameRect` with a 1-px pen: the rect's own edge pixels (the Mac strokes the rect inset ½).
    static func frameRect(_ img: inout Image, _ r: DialogRect, _ rgb: UInt32) {
        guard r.width > 0, r.height > 0 else { return }
        fill(&img, DialogRect(x: r.x, y: r.y, width: r.width, height: 1), rgb)
        fill(&img, DialogRect(x: r.x, y: r.maxY - 1, width: r.width, height: 1), rgb)
        fill(&img, DialogRect(x: r.x, y: r.y, width: 1, height: r.height), rgb)
        fill(&img, DialogRect(x: r.maxX - 1, y: r.y, width: 1, height: r.height), rgb)
    }

    /// A 1-px line from (x0, y0) to (x1, y1) (pixel-edge coordinates), anti-aliased by the distance of each pixel
    /// centre to the segment (CoreGraphics' 1-px stroke).
    static func line(_ img: inout Image, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ rgb: UInt32) {
        let dx = x1 - x0, dy = y1 - y0, len2 = dx * dx + dy * dy
        guard len2 > 0 else { return }
        let xs = max(0, Int(min(x0, x1).rounded(.down)) - 1)..<min(img.width, Int(max(x0, x1).rounded(.up)) + 1)
        let ys = max(0, Int(min(y0, y1).rounded(.down)) - 1)..<min(img.height, Int(max(y0, y1).rounded(.up)) + 1)
        for y in ys {
            for x in xs {
                let px = Double(x) + 0.5, py = Double(y) + 0.5
                let t = max(0, min(1, ((px - x0) * dx + (py - y0) * dy) / len2))
                let ex = x0 + t * dx - px, ey = y0 + t * dy - py
                let a = max(0, min(1, 1 - (ex * ex + ey * ey).squareRoot()))
                if a > 0 { img[x, y] = a >= 1 ? rgb : mix(img[x, y], rgb, a) }
            }
        }
    }

    /// A filled triangle, anti-aliased by 4 × 4 samples a pixel.
    static func fillTriangle(_ img: inout Image, _ a: (Double, Double), _ b: (Double, Double), _ c: (Double, Double),
                             _ rgb: UInt32) {
        func edge(_ p: (Double, Double), _ q: (Double, Double), _ x: Double, _ y: Double) -> Double {
            (q.0 - p.0) * (y - p.1) - (q.1 - p.1) * (x - p.0)
        }
        let area = edge(a, b, c.0, c.1)
        guard area != 0 else { return }
        let xs = max(0, Int(min(a.0, b.0, c.0)))..<min(img.width, Int(max(a.0, b.0, c.0).rounded(.up)))
        let ys = max(0, Int(min(a.1, b.1, c.1)))..<min(img.height, Int(max(a.1, b.1, c.1).rounded(.up)))
        for y in ys {
            for x in xs {
                var n = 0
                for sy in 0..<4 {
                    for sx in 0..<4 {
                        let px = Double(x) + (Double(sx) + 0.5) / 4, py = Double(y) + (Double(sy) + 0.5) / 4
                        let w0 = edge(b, c, px, py), w1 = edge(c, a, px, py), w2 = edge(a, b, px, py)
                        if area > 0 ? (w0 >= 0 && w1 >= 0 && w2 >= 0) : (w0 <= 0 && w1 <= 0 && w2 <= 0) { n += 1 }
                    }
                }
                if n > 0 { img[x, y] = n == 16 ? rgb : mix(img[x, y], rgb, Double(n) / 16) }
            }
        }
    }

    static func fill(_ img: inout Image, _ r: DialogRect, _ rgb: UInt32) {
        for y in max(r.y, 0)..<max(min(r.maxY, img.height), max(r.y, 0)) {
            for x in max(r.x, 0)..<max(min(r.maxX, img.width), max(r.x, 0)) { img[x, y] = rgb }
        }
    }

    private static func span(_ b: Box, _ img: Image) -> (Range<Int>, Range<Int>) {
        let x0 = max(0, Int((b.x0 - 1).rounded(.down))), x1 = min(img.width, Int((b.x1 + 1).rounded(.up)))
        let y0 = max(0, Int((b.y0 - 1).rounded(.down))), y1 = min(img.height, Int((b.y1 + 1).rounded(.up)))
        return (x0..<max(x0, x1), y0..<max(y0, y1))
    }

    static func fillRoundRect(_ img: inout Image, _ b: Box, radius: Double, rgb: UInt32) {
        let (xs, ys) = span(b, img)
        for y in ys {
            for x in xs {
                let a = coverage(Double(x) + 0.5, Double(y) + 0.5, b, radius)
                if a > 0 { img[x, y] = a >= 1 ? rgb : mix(img[x, y], rgb, a) }
            }
        }
    }

    /// A frame `width` px wide just inside `b` (outer corner `radius`, inner `radius − width`) — a CoreGraphics
    /// stroke of the path inset by width / 2, as the Mac strokes it.
    static func strokeRoundRect(_ img: inout Image, _ b: Box, radius: Double, width: Double, rgb: UInt32) {
        let inner = (b.x0 + width, b.y0 + width, b.x1 - width, b.y1 - width)
        let (xs, ys) = span(b, img)
        for y in ys {
            for x in xs {
                let cx = Double(x) + 0.5, cy = Double(y) + 0.5
                let a = coverage(cx, cy, b, radius) - coverage(cx, cy, inner, max(0, radius - width))
                if a > 0 { img[x, y] = a >= 1 ? rgb : mix(img[x, y], rgb, a) }
            }
        }
    }

    /// `DrawPicture` of `src` into `r`, scaled nearest-neighbour (`interpolationQuality = .none`).
    static func blit(_ img: inout Image, _ src: (rgba: [UInt8], width: Int, height: Int), into r: DialogRect) {
        guard r.width > 0, r.height > 0, src.width > 0, src.height > 0 else { return }
        for row in 0..<r.height {
            let y = r.y + row
            guard y >= 0, y < img.height else { continue }
            let sy = row * src.height / r.height
            for col in 0..<r.width {
                let x = r.x + col
                guard x >= 0, x < img.width else { continue }
                let at = 4 * (sy * src.width + col * src.width / r.width)
                img[x, y] = UInt32(src.rgba[at]) << 16 | UInt32(src.rgba[at + 1]) << 8 | UInt32(src.rgba[at + 2])
            }
        }
    }
}

extension DialogRect {
    func offsetBy(_ dx: Int, _ dy: Int) -> DialogRect { DialogRect(x: x + dx, y: y + dy, width: width, height: height) }
}
