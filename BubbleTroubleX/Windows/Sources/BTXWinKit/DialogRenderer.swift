import BubbleTroubleCore
import BubbleTroubleRender
import Foundation

/// Draws a `DialogWindow` the way the Mac replica's `CarbonDialog` looks (`BubbleTroubleX/App/BTXCarbonDialog.swift`):
/// Carbon dialogs on Mac OS X with theme background and theme controls (every BTX `dlgx` reads 0x0009, D4.1 Aqua), i.e.
/// the light Aqua controls of the Mac running the replica — white window, light-grey push buttons, the accent-blue
/// default button, rounded edit fields with the focus ring, checkboxes, popup buttons with chevrons — drawn here with
/// the baked System 12 face (`BitmapFontRasterizer`) and anti-aliased shapes. Colours were sampled from AppKit
/// renders of the same controls (light appearance).
public final class DialogRenderer {
    public let rasterizer: BitmapFontRasterizer
    static let fontName = "System", fontSize = 12
    let ascent: Int, lineHeight: Int

    // Light-Aqua palette (0xRRGGBB).
    static let windowBackground: UInt32 = 0xFFFFFF
    static let textColour: UInt32 = 0x000000
    static let disabledText: UInt32 = 0xB0B0B0
    static let buttonFill: UInt32 = 0xEBEBEB
    static let buttonPressed: UInt32 = 0xD2D2D2
    static let accent: UInt32 = 0x007AFF
    static let accentPressed: UInt32 = 0x0062CC
    static let fieldBorder: UInt32 = 0xD9D9D9
    static let selection: UInt32 = 0xB3D7FF
    static let chevron: UInt32 = 0x262626
    static let menuFill: UInt32 = 0xF9F9F9
    static let menuBorder: UInt32 = 0xC4C4C4
    static let separator: UInt32 = 0xDADADA
    /// The window's corner radius and frame.
    static let cornerRadius = 10.0

    public init(rasterizer: BitmapFontRasterizer) {
        self.rasterizer = rasterizer
        let face = rasterizer.face(Self.fontName, size: Self.fontSize)
        ascent = Int((face?.ascent ?? 12).rounded(.up))
        lineHeight = Int(((face?.ascent ?? 12) + (face?.descent ?? 3)).rounded(.up))
    }

    public convenience init(fontsDirectory: URL) throws {
        self.init(rasterizer: try BitmapFontRasterizer(fontsDirectory: fontsDirectory))
    }

    public func width(_ s: String) -> Int { rasterizer.width(s, font: Self.fontName, size: Self.fontSize) }

    /// Baseline that centres a single line of text vertically in a rect of `height` (cap height ≈ 9 px).
    func centredBaseline(_ top: Int, _ height: Int) -> Int { top + (height + 9) / 2 }

    // MARK: - The dialog body

    /// The dialog's content (template size, opaque): background, then every shown item in item order, the app's
    /// decorations (frames, `_OutlineItem` rings, plotted icons), the alert icon. Cached by the window's revision.
    public func render(_ w: DialogWindow) -> RGBAImage {
        w.measure = { [unowned self] in width($0) }
        let key = w.revision &* 2 &+ (w.caretVisible ? 1 : 0)
        if let c = w.cache, c.key == key { return c.image }
        var img = RGBAImage(width: max(1, w.template.width), height: max(1, w.template.height),
                            fill: 0xFF00_0000 | Self.windowBackground)
        for item in w.items where !w.isHidden(item.number) { draw(item, of: w, into: &img) }
        for f in w.frames {
            let r = f.rect
            Self.fill(&img, DialogRect(x: r.x, y: r.y, width: r.width, height: 1), f.rgb)
            Self.fill(&img, DialogRect(x: r.x, y: r.maxY - 1, width: r.width, height: 1), f.rgb)
            Self.fill(&img, DialogRect(x: r.x, y: r.y, width: 1, height: r.height), f.rgb)
            Self.fill(&img, DialogRect(x: r.maxX - 1, y: r.y, width: 1, height: r.height), f.rgb)
        }
        for n in w.outlines {
            guard let r = w.item(n)?.rect else { continue }
            // `_OutlineItem`: `InsetRect(−4, −4)`, pen 3×3, `FrameRoundRect` with oval (height / 2 + 2).
            let o = r.insetBy(-4, -4)
            let oval = Double(o.height / 2 + 2)
            Self.strokeRoundRect(&img, Self.box(o), radius: oval / 2, width: 3, rgb: 0x000000)
        }
        for o in w.overlays {
            Self.blit(&img, o.image, into: o.rect, darkened: o.darkened)
        }
        if let icon = w.alertIcon {
            Self.blit(&img, icon, into: DialogRect(x: 20, y: 10, width: 32, height: 32), darkened: false)
        }
        w.cache = (key, img)
        return img
    }

    private func draw(_ item: DialogItem, of w: DialogWindow, into img: inout RGBAImage) {
        let r = item.rect
        let active = w.isActive(item.number)
        switch item.kind {
        case .button:
            let pressed = w.flashItem == item.number || w.tracking == .control(item: item.number, inside: true)
            let isDefault = w.defaultItem == item.number && active
            let fill = isDefault ? (pressed ? Self.accentPressed : Self.accent)
                                 : (pressed ? Self.buttonPressed : Self.buttonFill)
            Self.fillRoundRect(&img, Self.box(r), radius: 5, rgb: fill)
            let title = w.text(item.number)
            let colour = !active ? Self.disabledText : isDefault ? 0xFFFFFF : Self.textColour
            text(title, x: r.x + (r.width - width(title)) / 2, baseline: centredBaseline(r.y, r.height), colour,
                 clip: r, into: &img)
        case .checkBox, .radio:
            let pressed = w.tracking == .control(item: item.number, inside: true)
            let on = w.value(item.number) != 0
            let size = 14
            let bx = r.x + 1, by = r.y + (r.height - size) / 2
            let b = Self.box(DialogRect(x: bx, y: by, width: size, height: size))
            let radius = item.kind == .radio ? Double(size) / 2 : 3.5
            if on {
                Self.fillRoundRect(&img, b, radius: radius, rgb: pressed ? Self.accentPressed : Self.accent)
                if item.kind == .checkBox {
                    let x = Double(bx), y = Double(by)
                    Self.strokeSegment(&img, (x + 3.5, y + 7.5), (x + 6, y + 10.5), width: 2, rgb: 0xFFFFFF)
                    Self.strokeSegment(&img, (x + 6, y + 10.5), (x + 10.5, y + 3.5), width: 2, rgb: 0xFFFFFF)
                } else {
                    Self.fillRoundRect(&img, (b.x0 + 4, b.y0 + 4, b.x1 - 4, b.y1 - 4), radius: 3, rgb: 0xFFFFFF)
                }
            } else {
                Self.fillRoundRect(&img, b, radius: radius, rgb: pressed ? Self.buttonPressed : Self.buttonFill)
            }
            text(w.text(item.number), x: r.x + 22, baseline: centredBaseline(r.y, r.height),
                 active ? Self.textColour : Self.disabledText, clip: nil, into: &img)
        case .staticText:
            let lines = wrap(w.text(item.number), width: r.width - 4)
            for (i, line) in lines.enumerated() {
                text(line, x: r.x + 2, baseline: r.y + ascent + i * lineHeight, Self.textColour, clip: r, into: &img)
            }
        case .editText:
            drawEditField(item, of: w, into: &img)
        case .picture:
            if let p = w.pictures[item.number] { Self.blit(&img, p, into: r, darkened: false) }
        case .control:
            drawPopup(item, of: w, active: active, into: &img)
        case .user, .icon, .other:
            break
        }
    }

    private func drawEditField(_ item: DialogItem, of w: DialogWindow, into img: inout RGBAImage) {
        let r = item.rect
        let focused = w.focusedEditItem == item.number
        let bezel = r.insetBy(-3, -3)
        if focused {
            // The Aqua focus ring around the first responder.
            Self.strokeRoundRect(&img, Self.box(bezel.insetBy(-3, -3)), radius: 8, width: 3.5, rgb: Self.accent,
                                 alpha: 0.5)
        }
        Self.fillRoundRect(&img, Self.box(bezel), radius: 5, rgb: 0xFFFFFF)
        Self.strokeRoundRect(&img, Self.box(bezel), radius: 5, width: 1, rgb: Self.fieldBorder)
        let chars = Array(w.text(item.number))
        let scroll = focused ? w.scrollToCaret(item) : (w.scroll[item.number] ?? 0)
        let x0 = r.x + DialogWindow.editTextInset - scroll
        let clip = DialogRect(x: r.x, y: r.y - 2, width: r.width, height: r.height + 4)
        if focused, let sel = w.selection, !sel.isEmpty {
            let a = x0 + width(String(chars[0..<sel.lowerBound]))
            let b = x0 + width(String(chars[0..<sel.upperBound]))
            let left = max(a, clip.x), right = min(b, clip.maxX)
            if right > left { Self.fill(&img, DialogRect(x: left, y: r.y, width: right - left, height: r.height),
                                        Self.selection) }
        }
        text(String(chars), x: x0, baseline: centredBaseline(r.y, r.height), Self.textColour, clip: clip,
             into: &img)
        if focused, w.caretVisible, let sel = w.selection {
            let cx = x0 + width(String(chars[0..<sel.upperBound]))
            if cx >= clip.x, cx < clip.maxX {
                Self.fill(&img, DialogRect(x: cx, y: r.y, width: 1, height: r.height), Self.textColour)
            }
        }
    }

    private func drawPopup(_ item: DialogItem, of w: DialogWindow, active: Bool, into img: inout RGBAImage) {
        guard let p = w.popups[item.number] else { return }
        let r = item.rect
        let colour = active ? Self.textColour : Self.disabledText
        // The CDEF's title, left of the button, vertically centred.
        text(p.control.title, x: r.x, baseline: centredBaseline(r.y, r.height), colour,
             clip: DialogRect(x: r.x, y: r.y - 2, width: p.control.titleWidth, height: r.height + 4), into: &img)
        let b = w.popupButtonRect(item)
        var open = false
        if case .popup(let m) = w.tracking, m.item == item.number { open = true }
        Self.fillRoundRect(&img, Self.box(b), radius: 5, rgb: open ? Self.buttonPressed : Self.buttonFill)
        let v = w.value(item.number)
        let title = v >= 1 && v <= p.titles.count && !DialogWindow.isSeparator(p.titles[v - 1]) ? p.titles[v - 1] : ""
        text(title, x: b.x + 12, baseline: centredBaseline(b.y, b.height), colour,
             clip: DialogRect(x: b.x, y: b.y - 2, width: b.width - 24, height: b.height + 4), into: &img)
        let cx = Double(b.maxX) - 14.5, cy = Double(b.y) + Double(b.height) / 2
        let ch: UInt32 = active ? Self.chevron : Self.disabledText
        Self.strokeSegment(&img, (cx - 3, cy - 1.5), (cx, cy - 4.5), width: 1.4, rgb: ch)
        Self.strokeSegment(&img, (cx, cy - 4.5), (cx + 3, cy - 1.5), width: 1.4, rgb: ch)
        Self.strokeSegment(&img, (cx - 3, cy + 1.5), (cx, cy + 4.5), width: 1.4, rgb: ch)
        Self.strokeSegment(&img, (cx, cy + 4.5), (cx + 3, cy + 1.5), width: 1.4, rgb: ch)
    }

    // MARK: - Onto the canvas

    /// Composites `w` onto `image` whose canvas origin (the canvas's 0,0) is at (`canvasX`, `canvasY`): the window's
    /// shadow and frame, its body, and its open popup menu (which may reach outside the dialog).
    public func composite(_ w: DialogWindow, into image: inout RGBAImage, canvasX: Int, canvasY: Int) {
        let body = render(w)
        let x = canvasX + w.originX, y = canvasY + w.originY
        let frame = (x0: Double(x), y0: Double(y), x1: Double(x + body.width), y1: Double(y + body.height))
        Self.shadow(&image, (frame.x0, frame.y0 + 6, frame.x1, frame.y1 + 6), radius: Self.cornerRadius,
                    spread: 14, alpha: 0.22)
        // The body inside the rounded window shape.
        for row in 0..<body.height {
            let py = y + row
            guard py >= 0, py < image.height else { continue }
            for col in 0..<body.width {
                let px = x + col
                guard px >= 0, px < image.width else { continue }
                let corner = (row < 12 || row >= body.height - 12) && (col < 12 || col >= body.width - 12)
                let a = corner ? Self.coverage(Double(px) + 0.5, Double(py) + 0.5, frame, Self.cornerRadius) : 1
                guard a > 0 else { continue }
                let s = body[col, row]
                image[px, py] = a >= 1 ? (0xFF00_0000 | s) : Self.mix(image[px, py], s & 0xFF_FFFF, a)
            }
        }
        Self.strokeRoundRect(&image, frame, radius: Self.cornerRadius, width: 1, rgb: 0x000000, alpha: 0.22)
        if case .popup(let m) = w.tracking { drawMenu(m, of: w, into: &image, dx: x, dy: y) }
    }

    private func drawMenu(_ m: DialogWindow.PopupMenu, of w: DialogWindow, into img: inout RGBAImage, dx: Int, dy: Int) {
        guard let p = w.popups[m.item] else { return }
        let r = m.rect.offsetBy(dx, dy)
        let b = Self.box(r)
        Self.shadow(&img, (b.x0, b.y0 + 4, b.x1, b.y1 + 4), radius: 8, spread: 10, alpha: 0.2)
        Self.fillRoundRect(&img, b, radius: 8, rgb: Self.menuFill)
        Self.strokeRoundRect(&img, b, radius: 8, width: 1, rgb: Self.menuBorder)
        let current = w.value(m.item) - 1
        for (i, row) in m.rows.enumerated() where i < p.titles.count {
            let rr = row.offsetBy(dx, dy)
            let t = p.titles[i]
            if DialogWindow.isSeparator(t) {
                Self.fill(&img, DialogRect(x: rr.x + 10, y: rr.y + rr.height / 2, width: rr.width - 20, height: 1),
                          Self.separator)
                continue
            }
            let lit = m.highlighted == i
            if lit {
                Self.fillRoundRect(&img, Self.box(rr.insetBy(5, 0)), radius: 4, rgb: Self.accent)
            }
            let colour: UInt32 = lit ? 0xFFFFFF : Self.textColour
            if i == current {
                let x = Double(rr.x) + 9, y = Double(rr.y) + Double(rr.height) / 2
                Self.strokeSegment(&img, (x, y), (x + 2.5, y + 3), width: 1.6, rgb: colour)
                Self.strokeSegment(&img, (x + 2.5, y + 3), (x + 7, y - 4), width: 1.6, rgb: colour)
            }
            text(t, x: rr.x + 22, baseline: centredBaseline(rr.y, rr.height), colour, clip: nil, into: &img)
        }
    }

    // MARK: - Text

    /// `TETextBox`-style word wrap: CR / newline breaks, then greedy words; a word wider than the line is broken.
    func wrap(_ s: String, width maxWidth: Int) -> [String] {
        var lines: [String] = []
        for paragraph in s.split(separator: "\n", omittingEmptySubsequences: false) {
            var line = ""
            var word = ""
            func flushWord() {
                guard !word.isEmpty else { return }
                let candidate = line + word
                if line.isEmpty || width(candidate.trimmingTrailingSpaces) <= maxWidth {
                    line = candidate
                } else {
                    lines.append(line.trimmingTrailingSpaces)
                    line = word.trimmingLeadingSpaces
                }
                // A single word wider than the line: break it by characters.
                while width(line.trimmingTrailingSpaces) > maxWidth, line.count > 1 {
                    var head = ""
                    for c in line {
                        if width(head + String(c)) > maxWidth, !head.isEmpty { break }
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
            lines.append(line.trimmingTrailingSpaces)
        }
        return lines
    }

    /// Draws `s` with its pen at (x, baseline), clipped to `clip` when given.
    func text(_ s: String, x: Int, baseline: Int, _ rgb: UInt32, clip: DialogRect?, into img: inout RGBAImage) {
        guard !s.isEmpty else { return }
        guard let clip else {
            rasterizer.rasterize(s, font: Self.fontName, size: Self.fontSize, rgb: rgb, into: &img,
                                 at: (x, baseline), centredIn: nil)
            return
        }
        let x0 = max(clip.x, 0), y0 = max(clip.y, 0)
        let x1 = min(clip.maxX, img.width), y1 = min(clip.maxY, img.height)
        guard x1 > x0, y1 > y0 else { return }
        var sub = RGBAImage(width: x1 - x0, height: y1 - y0)
        for row in 0..<sub.height { for col in 0..<sub.width { sub[col, row] = img[x0 + col, y0 + row] } }
        rasterizer.rasterize(s, font: Self.fontName, size: Self.fontSize, rgb: rgb, into: &sub,
                             at: (x - x0, baseline - y0), centredIn: nil)
        for row in 0..<sub.height { for col in 0..<sub.width { img[x0 + col, y0 + row] = sub[col, row] } }
    }

    // MARK: - Shapes (anti-aliased, analytic coverage at pixel centres)

    typealias Box = (x0: Double, y0: Double, x1: Double, y1: Double)

    static func box(_ r: DialogRect) -> Box { (Double(r.minX), Double(r.minY), Double(r.maxX), Double(r.maxY)) }

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
        return 0xFF00_0000 | ch(16) | ch(8) | ch(0)
    }

    static func fill(_ img: inout RGBAImage, _ r: DialogRect, _ rgb: UInt32) {
        for y in max(r.minY, 0)..<max(min(r.maxY, img.height), max(r.minY, 0)) {
            for x in max(r.minX, 0)..<max(min(r.maxX, img.width), max(r.minX, 0)) { img[x, y] = 0xFF00_0000 | rgb }
        }
    }

    private static func span(_ b: Box, pad: Double, _ img: RGBAImage) -> (Range<Int>, Range<Int>) {
        let x0 = max(0, Int((b.x0 - pad).rounded(.down))), x1 = min(img.width, Int((b.x1 + pad).rounded(.up)))
        let y0 = max(0, Int((b.y0 - pad).rounded(.down))), y1 = min(img.height, Int((b.y1 + pad).rounded(.up)))
        return (x0..<max(x0, x1), y0..<max(y0, y1))
    }

    static func fillRoundRect(_ img: inout RGBAImage, _ b: Box, radius: Double, rgb: UInt32, alpha: Double = 1) {
        let (xs, ys) = span(b, pad: 1, img)
        for y in ys {
            for x in xs {
                let a = coverage(Double(x) + 0.5, Double(y) + 0.5, b, radius) * alpha
                if a > 0 { img[x, y] = mix(img[x, y], rgb, a) }
            }
        }
    }

    /// A frame `width` px wide just inside `b` (QuickDraw pens frame inside the rect).
    static func strokeRoundRect(_ img: inout RGBAImage, _ b: Box, radius: Double, width: Double, rgb: UInt32,
                                alpha: Double = 1) {
        let inner = (b.x0 + width, b.y0 + width, b.x1 - width, b.y1 - width)
        let (xs, ys) = span(b, pad: 1, img)
        for y in ys {
            for x in xs {
                let cx = Double(x) + 0.5, cy = Double(y) + 0.5
                let a = (coverage(cx, cy, b, radius) - coverage(cx, cy, inner, max(0, radius - width))) * alpha
                if a > 0 { img[x, y] = mix(img[x, y], rgb, a) }
            }
        }
    }

    /// A round-capped line from `p` to `q`.
    static func strokeSegment(_ img: inout RGBAImage, _ p: (Double, Double), _ q: (Double, Double), width: Double,
                              rgb: UInt32) {
        let half = width / 2
        let b: Box = (min(p.0, q.0) - half, min(p.1, q.1) - half, max(p.0, q.0) + half, max(p.1, q.1) + half)
        let (xs, ys) = span(b, pad: 1, img)
        let vx = q.0 - p.0, vy = q.1 - p.1
        let len2 = max(vx * vx + vy * vy, 1e-9)
        for y in ys {
            for x in xs {
                let cx = Double(x) + 0.5, cy = Double(y) + 0.5
                let t = max(0, min(1, ((cx - p.0) * vx + (cy - p.1) * vy) / len2))
                let ex = cx - (p.0 + t * vx), ey = cy - (p.1 + t * vy)
                let a = max(0, min(1, half + 0.5 - (ex * ex + ey * ey).squareRoot()))
                if a > 0 { img[x, y] = mix(img[x, y], rgb, a) }
            }
        }
    }

    /// A soft drop shadow outside the rounded rect `b`.
    static func shadow(_ img: inout RGBAImage, _ b: Box, radius: Double, spread: Double, alpha: Double) {
        let (xs, ys) = span(b, pad: spread, img)
        let hw = (b.x1 - b.x0) / 2, hh = (b.y1 - b.y0) / 2
        for y in ys {
            for x in xs {
                let px = Double(x) + 0.5, py = Double(y) + 0.5
                let dx = abs(px - (b.x0 + hw)) - (hw - radius), dy = abs(py - (b.y0 + hh)) - (hh - radius)
                let d = (max(dx, 0) * max(dx, 0) + max(dy, 0) * max(dy, 0)).squareRoot() + min(max(dx, dy), 0) - radius
                guard d < spread else { continue }
                let t = max(0, min(1, 1 - (d + spread * 0.25) / (spread * 1.25)))
                let a = alpha * t * t
                if a > 0 { img[x, y] = mix(img[x, y], 0x000000, a) }
            }
        }
    }

    /// `DrawPicture` / `PlotCIconHandle` of `src` into `r` (scaled nearest-neighbour, the source's alpha as its
    /// mask); `darkened` = `kTransformSelected` (half-dark inside the mask).
    static func blit(_ img: inout RGBAImage, _ src: RGBAImage, into r: DialogRect, darkened: Bool) {
        guard r.width > 0, r.height > 0 else { return }
        for row in 0..<r.height {
            let y = r.y + row
            guard y >= 0, y < img.height else { continue }
            let sy = row * src.height / r.height
            for col in 0..<r.width {
                let x = r.x + col
                guard x >= 0, x < img.width else { continue }
                var s = src[col * src.width / r.width, sy]
                let a = s >> 24
                guard a != 0 else { continue }
                if darkened {
                    s = (s & 0xFF00_0000) | (((s >> 16) & 0xFF) / 2) << 16 | (((s >> 8) & 0xFF) / 2) << 8 | (s & 0xFF) / 2
                }
                img[x, y] = a == 0xFF ? (0xFF00_0000 | s) : mix(img[x, y], s & 0xFF_FFFF, Double(a) / 255)
            }
        }
    }
}

private extension String {
    var trimmingTrailingSpaces: String {
        var s = self
        while s.last == " " { s.removeLast() }
        return s
    }

    var trimmingLeadingSpaces: String { String(drop { $0 == " " }) }
}
