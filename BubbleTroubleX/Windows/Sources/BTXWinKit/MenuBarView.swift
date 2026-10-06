import BubbleTroubleCore
import BubbleTroubleRender
import Foundation

/// A rectangle in the window's logical pixels (origin top-left).
public struct MenuRect: Equatable, Sendable {
    public var x, y, width, height: Int
    public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }
    public var maxX: Int { x + width }
    public var maxY: Int { y + height }
    public func contains(_ px: Int, _ py: Int) -> Bool { px >= x && px < maxX && py >= y && py < maxY }
}

/// One row of a drop-down: an item or a separator.
public struct MenuRow: Equatable, Sendable {
    public var entry: Int
    public var frame: MenuRect
    public var isSeparator: Bool
}

public struct MenuDropdown: Equatable, Sendable {
    public var frame: MenuRect
    public var rows: [MenuRow]
    /// Submenus by the entry index of their parent item.
    public var submenus: [Int: MenuDropdown]

    /// The row under the point (nil over the padding or outside).
    public func row(at x: Int, _ y: Int) -> MenuRow? {
        guard frame.contains(x, y) else { return nil }
        return rows.first { $0.frame.contains(x, y) }
    }
}

/// Where everything is: the titles in the bar and every menu's drop-down (each opens under its title).
public struct MenuGeometry: Equatable, Sendable {
    public var barHeight: Int
    public var titles: [MenuRect]
    public var dropdowns: [MenuDropdown]

    public func title(at x: Int, _ y: Int) -> Int? { titles.firstIndex { $0.contains(x, y) } }
}

/// Draws the bar into the top `barHeight` rows of the window buffer (640 × 500 logical: the 20 px strip, then the
/// 640 × 480 canvas) and the open menu over the canvas.
///
/// The look — the Mac replica's menus as Ben sees them (Aqua forced light, D4.1, on current macOS), flattened to
/// pixels: a near-white bar with a light hairline under it; black System 12 titles, the application menu's bold
/// (System Bold 12); the open title on a rounded light-grey pill (black text); the drop-down a rounded near-white
/// panel with a grey outline and a soft shadow; the item under the pointer on a rounded accent-blue bar with white
/// text; disabled items light grey; separators a thin grey rule; ✓ marks in a left column; key equivalents
/// right-aligned in grey as "Ctrl+F" / "Ctrl+Shift+A" / "Ctrl+Alt+M"; a submenu's chevron at the right.
public struct MenuBarView {
    public let text: any TextRasterizer

    public init(text: any TextRasterizer) { self.text = text }

    // MARK: Metrics

    public static let barHeight = 20
    static let font = "System", boldFont = "System-Bold", fontSize = 12
    static let barStartX = 10, titlePad = 9
    static let barBaseline = 14
    static let rowHeight = 20, separatorHeight = 9, rowBaseline = 14
    static let topPad = 5, bottomPad = 5
    static let checkColumn = 22, shortcutGap = 28, rightPad = 14, arrowColumn = 20
    static let cornerRadius = 6.0

    // MARK: Colours (0xRRGGBB)

    static let barColor: UInt32 = 0xF6F6F6, barLine: UInt32 = 0xD2D2D2
    static let titlePill: UInt32 = 0xDCDCDC
    static let panelColor: UInt32 = 0xF4F4F4, panelOutline: UInt32 = 0xC2C2C2
    static let highlight: UInt32 = 0x0A64E0
    static let textColor: UInt32 = 0x000000, disabledColor: UInt32 = 0xA8A8A8
    static let shortcutColor: UInt32 = 0x737373, highlightText: UInt32 = 0xFFFFFF
    static let separatorColor: UInt32 = 0xD6D6D6

    // MARK: Text

    /// The key-equivalent column's text: Windows order, Ctrl first ("Ctrl+Shift+A").
    public static func shortcut(_ key: Character?, _ modifiers: MenuModifiers) -> String? {
        guard let key else { return nil }
        var parts: [String] = []
        if modifiers.contains(.command) { parts.append("Ctrl") }
        if modifiers.contains(.option) { parts.append("Alt") }
        if modifiers.contains(.shift) || key.isUppercase { parts.append("Shift") }
        guard !parts.isEmpty else { return nil }
        return (parts + [key.uppercased()]).joined(separator: "+")
    }

    private func width(_ s: String, bold: Bool = false) -> Int {
        text.width(s, font: bold ? Self.boldFont : Self.font, size: Self.fontSize)
    }

    // MARK: Geometry

    /// The layout of `bar` in a `width` × `height` window.
    public func geometry(for bar: MenuBar, width: Int, height: Int) -> MenuGeometry {
        var titles: [MenuRect] = []
        var x = Self.barStartX
        for menu in bar.menus {
            let w = self.width(menu.title, bold: menu.bold) + 2 * Self.titlePad
            titles.append(MenuRect(x: x, y: 0, width: w, height: Self.barHeight))
            x += w
        }
        let dropdowns = bar.menus.enumerated().map { i, menu in
            dropdown(menu, x: titles[i].x, y: Self.barHeight, windowWidth: width, windowHeight: height)
        }
        return MenuGeometry(barHeight: Self.barHeight, titles: titles, dropdowns: dropdowns)
    }

    /// The width a drop-down needs: the ✓ column, the widest title (its ⌥ alternate's too), the gap and the widest
    /// key equivalent, or a submenu chevron.
    private func dropdownWidth(_ menu: BarMenu) -> Int {
        var titleW = 0, keyW = 0, arrow = false
        for case let .item(item) in menu.entries {
            titleW = max(titleW, width(item.title))
            if let s = Self.shortcut(item.key, item.effectiveModifiers) { keyW = max(keyW, width(s)) }
            if let alt = item.alternate {
                titleW = max(titleW, width(alt.title))
                if let s = Self.shortcut(alt.key, alt.effectiveModifiers) { keyW = max(keyW, width(s)) }
            }
            if item.submenu != nil { arrow = true }
        }
        var w = Self.checkColumn + titleW + Self.rightPad
        if keyW > 0 { w += Self.shortcutGap + keyW }
        if arrow { w += Self.arrowColumn }
        return w
    }

    private func dropdown(_ menu: BarMenu, x: Int, y: Int, windowWidth: Int, windowHeight: Int,
                          parent: MenuRect? = nil) -> MenuDropdown {
        let w = dropdownWidth(menu)
        var h = Self.topPad + Self.bottomPad
        for e in menu.entries { h += e == .separator ? Self.separatorHeight : Self.rowHeight }
        var fx = x, fy = y
        if let parent {
            // A submenu opens to the right of its parent, its first row level with the parent row; to the left if
            // it would leave the window; moved up if it would run off the bottom.
            fx = parent.maxX - 3
            if fx + w > windowWidth { fx = parent.x - w + 3 }
            if fx < 0 { fx = windowWidth - w }                // no room either side: over the parent
        } else if fx + w > windowWidth {
            fx = windowWidth - w
        }
        if fy + h > windowHeight { fy = max(Self.barHeight, windowHeight - h) }
        fx = max(0, fx)
        var rows: [MenuRow] = []
        var ry = fy + Self.topPad
        for (i, e) in menu.entries.enumerated() {
            let rh = e == .separator ? Self.separatorHeight : Self.rowHeight
            rows.append(MenuRow(entry: i, frame: MenuRect(x: fx, y: ry, width: w, height: rh),
                                isSeparator: e == .separator))
            ry += rh
        }
        var subs: [Int: MenuDropdown] = [:]
        for (i, e) in menu.entries.enumerated() {
            guard let sub = e.item?.submenu else { continue }
            let row = rows[i].frame
            subs[i] = dropdown(sub, x: 0, y: row.y - Self.topPad, windowWidth: windowWidth,
                               windowHeight: windowHeight,
                               parent: MenuRect(x: fx, y: row.y, width: w, height: row.height))
        }
        return MenuDropdown(frame: MenuRect(x: fx, y: fy, width: w, height: h), rows: rows, submenus: subs)
    }

    // MARK: Drawing

    /// Draws the bar into rows 0 ..< 20 of `image`, then the open menu (and its open submenu) from `tracker`.
    public func draw(_ bar: MenuBar, tracker: MenuTracker, into image: inout RGBAImage) {
        let g = geometry(for: bar, width: image.width, height: image.height)
        let menus = bar.menus
        // The bar.
        fill(&image, MenuRect(x: 0, y: 0, width: image.width, height: Self.barHeight - 1), Self.barColor)
        fill(&image, MenuRect(x: 0, y: Self.barHeight - 1, width: image.width, height: 1), Self.barLine)
        for (i, menu) in menus.enumerated() {
            let t = g.titles[i]
            if tracker.openMenu == i {
                roundedRect(&image, MenuRect(x: t.x, y: 2, width: t.width, height: Self.barHeight - 4), radius: 4,
                            Self.titlePill, alpha: 255)
            }
            text.rasterize(menu.title, font: menu.bold ? Self.boldFont : Self.font, size: Self.fontSize,
                           rgb: Self.textColor, into: &image, at: (t.x + Self.titlePad, Self.barBaseline),
                           centredIn: nil)
        }
        guard let open = tracker.openMenu, menus.indices.contains(open) else { return }
        let d = g.dropdowns[open]
        drawDropdown(menus[open], d, highlighted: tracker.highlighted, bar: bar, option: tracker.optionHeld,
                     into: &image)
        if let parent = tracker.openSubmenu, let sub = menus[open].entries[parent].item?.submenu,
           let sd = d.submenus[parent] {
            drawDropdown(sub, sd, highlighted: tracker.subHighlighted, bar: bar, option: tracker.optionHeld,
                         into: &image)
        }
    }

    private func drawDropdown(_ menu: BarMenu, _ d: MenuDropdown, highlighted: Int?, bar: MenuBar, option: Bool,
                              into image: inout RGBAImage) {
        let f = d.frame
        // Soft shadow: stacked translucent black panels, growing and lower.
        for k in stride(from: 6, through: 1, by: -1) {
            roundedRect(&image, MenuRect(x: f.x - k, y: f.y - k + 4, width: f.width + 2 * k, height: f.height + 2 * k),
                        radius: Self.cornerRadius + Double(k), 0x000000, alpha: 7)
        }
        roundedRect(&image, f, radius: Self.cornerRadius, Self.panelOutline, alpha: 255)
        roundedRect(&image, MenuRect(x: f.x + 1, y: f.y + 1, width: f.width - 2, height: f.height - 2),
                    radius: Self.cornerRadius - 1, Self.panelColor, alpha: 255)
        for row in d.rows {
            let r = row.frame
            guard let item = menu.entries[row.entry].item else {
                fill(&image, MenuRect(x: r.x + 10, y: r.y + r.height / 2, width: r.width - 20, height: 1),
                     Self.separatorColor)
                continue
            }
            let shown = MenuTracker.shown(item, option: option)
            let enabled = bar.isEnabled(shown.rule)
            let lit = highlighted == row.entry && enabled
            if lit {
                roundedRect(&image, MenuRect(x: r.x + 5, y: r.y, width: r.width - 10, height: r.height), radius: 4,
                            Self.highlight, alpha: 255)
            }
            let ink = lit ? Self.highlightText : enabled ? Self.textColor : Self.disabledColor
            if item.checked {
                glyph(&image, Self.checkMark, x: r.x + 8, y: r.y + 6, ink)
            }
            text.rasterize(shown.title, font: Self.font, size: Self.fontSize, rgb: ink, into: &image,
                           at: (r.x + Self.checkColumn, r.y + Self.rowBaseline), centredIn: nil)
            if let s = Self.shortcut(shown.key, shown.modifiers) {
                let keyInk = lit ? Self.highlightText : enabled ? Self.shortcutColor : Self.disabledColor
                text.rasterize(s, font: Self.font, size: Self.fontSize, rgb: keyInk, into: &image,
                               at: (r.maxX - Self.rightPad - width(s), r.y + Self.rowBaseline), centredIn: nil)
            }
            if item.submenu != nil {
                glyph(&image, Self.chevron, x: r.maxX - Self.rightPad - 4, y: r.y + 6, ink)
            }
        }
    }

    // MARK: Pixels

    /// ✓ (9 × 7) and › (4 × 7), drawn as coverage so they take the ink colour.
    static let checkMark = [
        "........#",
        ".......##",
        "......##.",
        "#....##..",
        "##..##...",
        ".####....",
        "..##.....",
    ]
    static let chevron = ["#...", "##..", ".##.", "..##", ".##.", "##..", "#..."]

    private func glyph(_ image: inout RGBAImage, _ rows: [String], x: Int, y: Int, _ rgb: UInt32) {
        for (r, line) in rows.enumerated() {
            for (c, ch) in line.enumerated() where ch == "#" { blend(&image, x + c, y + r, rgb, 255) }
        }
    }

    private func fill(_ image: inout RGBAImage, _ r: MenuRect, _ rgb: UInt32) {
        for y in max(0, r.y)..<min(image.height, r.maxY) {
            for x in max(0, r.x)..<min(image.width, r.maxX) { image[x, y] = 0xFF00_0000 | rgb }
        }
    }

    /// A filled rounded rectangle, edges antialiased by 4 × 4 supersampling, blended at `alpha` × coverage.
    private func roundedRect(_ image: inout RGBAImage, _ r: MenuRect, radius: Double, _ rgb: UInt32, alpha: Int) {
        guard r.width > 0, r.height > 0 else { return }
        let rad = min(radius, Double(min(r.width, r.height)) / 2)
        let x0 = Double(r.x), y0 = Double(r.y), x1 = Double(r.maxX), y1 = Double(r.maxY)
        func inside(_ px: Double, _ py: Double) -> Bool {
            let cx = min(max(px, x0 + rad), x1 - rad), cy = min(max(py, y0 + rad), y1 - rad)
            let dx = px - cx, dy = py - cy
            return dx * dx + dy * dy <= rad * rad
        }
        let corner = Int(rad.rounded(.up))
        for y in max(0, r.y)..<min(image.height, r.maxY) {
            for x in max(0, r.x)..<min(image.width, r.maxX) {
                var cover = 16
                let nearCorner = (x < r.x + corner || x >= r.maxX - corner) && (y < r.y + corner || y >= r.maxY - corner)
                if nearCorner {
                    cover = 0
                    for sy in 0..<4 {
                        for sx in 0..<4 where inside(Double(x) + (Double(sx) + 0.5) / 4, Double(y) + (Double(sy) + 0.5) / 4) {
                            cover += 1
                        }
                    }
                }
                guard cover > 0 else { continue }
                blend(&image, x, y, rgb, UInt32(alpha * cover / 16))
            }
        }
    }

    private func blend(_ image: inout RGBAImage, _ x: Int, _ y: Int, _ rgb: UInt32, _ a: UInt32) {
        guard x >= 0, y >= 0, x < image.width, y < image.height, a > 0 else { return }
        let dst = image[x, y]
        func mix(_ shift: UInt32) -> UInt32 {
            let s = (rgb >> shift) & 0xFF, d = (dst >> shift) & 0xFF
            return ((s * a + d * (255 - a) + 127) / 255) << shift
        }
        image[x, y] = 0xFF00_0000 | mix(16) | mix(8) | mix(0)
    }
}
