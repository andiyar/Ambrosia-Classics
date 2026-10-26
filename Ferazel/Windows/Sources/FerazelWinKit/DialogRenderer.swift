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
///
/// Not drawn: the Mac panel's macOS window shadow (a modern window's, not the dBoxProc's).
@MainActor public final class DialogRenderer {
    public static let font: Int16 = 0, size: Int16 = 12, face: Int16 = 1
    /// `NSLayoutManager.defaultLineHeight` / `defaultBaselineOffset` of the Mac's pick (measured, test 11).
    public static let lineHeight = 15, ascent = 12
    static let black: UInt32 = 0x000000, white: UInt32 = 0xFFFFFF
    static let frameGrey: UInt32 = 0xDDDDDD
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
        let body = render(w)
        for row in 0..<body.height {
            let y = w.originY + row
            guard y >= 0, y < height else { continue }
            for col in 0..<body.width {
                let x = w.originX + col
                guard x >= 0, x < width else { continue }
                let c = body.pixels[row * body.width + col], at = 4 * (y * width + x)
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
        for item in w.items { draw(item, of: w, into: &img, dx: fw, dy: fw) }
        for n in w.outlines {
            guard let r = w.item(n)?.rect else { continue }
            let o = Self.ringRect(r).offsetBy(fw, fw)
            Self.strokeRoundRect(&img, Self.box(o), radius: 7.5, width: 3, rgb: Self.black)
        }
        return img
    }

    private func draw(_ item: DialogItem, of w: DialogWindow, into img: inout Image, dx: Int, dy: Int) {
        let r = item.rect.offsetBy(dx, dy)
        switch item.item.kind {
        case .button:
            let lit = w.isHighlighted(item.number)
            let radius = Double(min(8, r.height / 2 - 1)) + 0.5
            Self.fillRoundRect(&img, Self.box(r), radius: radius, rgb: lit ? Self.black : Self.white)
            Self.strokeRoundRect(&img, Self.box(r), radius: radius, width: 1, rgb: Self.black)
            let title = w.text(item.number)
            let x = r.x + Int(((Double(r.width) - width(title)) / 2).rounded())
            let top = r.y + Int((Double(r.height - Self.lineHeight) / 2).rounded())
            draw(title, x: x, baseline: top + Self.ascent, rgb: lit ? Self.white : Self.black, clip: nil, into: &img)
        case .staticText:
            for (i, line) in wrap(w.text(item.number), width: r.width).enumerated() {
                draw(line, x: r.x, baseline: r.y + Self.ascent + i * Self.lineHeight, rgb: Self.black, clip: r,
                     into: &img)
            }
        case .picture:
            if let p = w.pictures[item.number] { Self.blit(&img, p, into: r) }
        default:
            break   // DITL 202 / 200 hold buttons, a picture and static text only (WF4b adds the rest)
        }
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
