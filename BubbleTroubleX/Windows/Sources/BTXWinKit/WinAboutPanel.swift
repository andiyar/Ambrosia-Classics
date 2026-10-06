import BubbleTroubleCore
import BubbleTroubleRender
import Foundation

/// Bubble Trouble X ▸ About, in-window (W4.5). The Mac item (`BTXMenus.about`) sets the hand cursor and opens AppKit's
/// standard About panel: the application icon, the name in bold, "Version 1.1.0", the credits from
/// `English.lproj/AboutCredits1.rtf` and the copyright line from `InfoPlist.strings`. It is not modal — the game runs
/// on behind it — and it closes with its close button.
///
/// Here the panel is drawn over the canvas in the same light look as the dialogs (`DialogRenderer`'s shapes, the baked
/// faces), centred horizontally, a third of the free height above. Deviations, platform-only: the icon is the data's
/// `cicn 128` at 2× (the `.icns` is not in the Windows data); the credits are transcribed from the RTF (no RTF reader
/// off Apple); a click outside the panel closes it and goes on to whatever is under it (on the Mac the click makes the
/// game window key and the panel falls behind it); Esc closes it too. While it is open the keys are its own (the game
/// window is not key), except the menu bar's Ctrl shortcuts.
public final class WinAboutPanel {
    public static let width = 284
    public static let titleBarHeight = 28
    static let name = "Bubble Trouble X"
    static let version = "Version 1.1.0"
    /// `AboutCredits1.rtf` (tab-aligned role / name rows).
    static let credits: [(role: String, name: String)] = [
        ("Programming:", "Alex Metcalf"), ("", "David Wareing"), ("", ""),
        ("Artwork:", "Marcus Conge"), ("", "Alex Metcalf"), ("", "David Wareing"), ("", ""),
        ("Additional Programming:", "Kent Sutherland"),
    ]
    /// `NSHumanReadableCopyright` (`InfoPlist.strings`).
    static let copyright = ["©1995-2008 Ambrosia Software, Inc.", "All rights reserved worldwide."]

    static let iconSize = 64, creditRow = 13

    public let height: Int
    /// The panel's top-left on the 640×480 canvas.
    public let originX: Int, originY: Int

    private let text: BitmapFontRasterizer
    private let icon: RGBAImage?
    private var cache: RGBAImage?

    public init(text: BitmapFontRasterizer, icon: RGBAImage?) {
        self.text = text
        self.icon = icon
        height = Self.creditsTop + Self.credits.count * Self.creditRow + 52
        originX = (DialogSystem.canvasWidth - Self.width) / 2
        originY = max(0, (DialogSystem.canvasHeight - height) / 3)
    }

    static let iconTop = titleBarHeight + 8
    static let nameBaseline = iconTop + iconSize + 20
    static let versionBaseline = nameBaseline + 18
    static let creditsTop = versionBaseline + 14

    /// The close button's centre and radius in panel coordinates (the red one of the three title-bar buttons).
    static let closeCentre = (x: 14.0, y: 14.0), buttonRadius = 6.0

    /// (x, y) on the canvas is on the panel.
    public func contains(x: Int, y: Int) -> Bool {
        x >= originX && x < originX + Self.width && y >= originY && y < originY + height
    }

    /// (x, y) on the canvas is on the close button.
    public func isOnCloseButton(x: Int, y: Int) -> Bool {
        let dx = Double(x - originX) + 0.5 - Self.closeCentre.x, dy = Double(y - originY) + 0.5 - Self.closeCentre.y
        return dx * dx + dy * dy <= (Self.buttonRadius + 1) * (Self.buttonRadius + 1)
    }

    /// The panel's own pixels (opaque, `width × height`).
    func body() -> RGBAImage {
        if let cache { return cache }
        var img = RGBAImage(width: Self.width, height: height, fill: 0xFF00_0000 | 0xECECEC)
        // Title bar buttons: close (red), minimize and zoom (disabled grey) — the About panel's.
        let colours: [UInt32] = [0xFF5F57, 0xDCDCDC, 0xDCDCDC]
        for (i, c) in colours.enumerated() {
            let cx = Self.closeCentre.x + Double(i) * 20, cy = Self.closeCentre.y, r = Self.buttonRadius
            DialogRenderer.fillRoundRect(&img, (cx - r, cy - r, cx + r, cy + r), radius: r, rgb: c)
            DialogRenderer.strokeRoundRect(&img, (cx - r, cy - r, cx + r, cy + r), radius: r, width: 1, rgb: 0x000000,
                                           alpha: 0.12)
        }
        if let icon {
            DialogRenderer.blit(&img, icon, into: DialogRect(x: (Self.width - Self.iconSize) / 2, y: Self.iconTop,
                                                             width: Self.iconSize, height: Self.iconSize),
                                darkened: false)
        }
        centred(Self.name, font: "System-Bold", size: 12, baseline: Self.nameBaseline, into: &img)
        centred(Self.version, font: "Geneva", size: 10, baseline: Self.versionBaseline, into: &img, rgb: 0x5A5A5A)
        let mid = Self.width / 2
        for (i, row) in Self.credits.enumerated() {
            let baseline = Self.creditsTop + (i + 1) * Self.creditRow
            if !row.role.isEmpty {
                let w = text.width(row.role, font: "Geneva", size: 10)
                text.rasterize(row.role, font: "Geneva", size: 10, rgb: 0x5A5A5A, into: &img,
                               at: (mid - 4 - w, baseline), centredIn: nil)
            }
            if !row.name.isEmpty {
                text.rasterize(row.name, font: "Geneva", size: 10, rgb: 0x000000, into: &img, at: (mid + 4, baseline),
                               centredIn: nil)
            }
        }
        let bottom = Self.creditsTop + Self.credits.count * Self.creditRow
        for (i, line) in Self.copyright.enumerated() {
            centred(line, font: "Geneva", size: 9, baseline: bottom + 22 + i * 12, into: &img, rgb: 0x5A5A5A)
        }
        cache = img
        return img
    }

    private func centred(_ s: String, font: String, size: Int, baseline: Int, into img: inout RGBAImage,
                         rgb: UInt32 = 0x000000) {
        let w = text.width(s, font: font, size: size)
        text.rasterize(s, font: font, size: size, rgb: rgb, into: &img, at: ((Self.width - w) / 2, baseline),
                       centredIn: nil)
    }

    /// Composites the panel (shadow, rounded body, hairline frame) onto `image` whose canvas origin is at
    /// (`canvasX`, `canvasY`).
    public func draw(into image: inout RGBAImage, canvasX: Int, canvasY: Int) {
        let b = body()
        let x = canvasX + originX, y = canvasY + originY
        let frame = (x0: Double(x), y0: Double(y), x1: Double(x + b.width), y1: Double(y + b.height))
        DialogRenderer.shadow(&image, (frame.x0, frame.y0 + 6, frame.x1, frame.y1 + 6),
                              radius: DialogRenderer.cornerRadius, spread: 14, alpha: 0.22)
        for row in 0..<b.height {
            let py = y + row
            guard py >= 0, py < image.height else { continue }
            for col in 0..<b.width {
                let px = x + col
                guard px >= 0, px < image.width else { continue }
                let corner = (row < 12 || row >= b.height - 12) && (col < 12 || col >= b.width - 12)
                let a = corner ? DialogRenderer.coverage(Double(px) + 0.5, Double(py) + 0.5, frame,
                                                          DialogRenderer.cornerRadius) : 1
                guard a > 0 else { continue }
                let s = b[col, row]
                image[px, py] = a >= 1 ? (0xFF00_0000 | s) : DialogRenderer.mix(image[px, py], s & 0xFF_FFFF, a)
            }
        }
        DialogRenderer.strokeRoundRect(&image, frame, radius: DialogRenderer.cornerRadius, width: 1, rgb: 0x000000,
                                       alpha: 0.22)
    }
}
