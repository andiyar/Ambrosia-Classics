import AppKit

// The Dialog Manager's items as the classic Mac drew them (plan A1b; adapted from `BubbleTroubleX/App/BTXCarbonDialog.swift`,
// whose items are Aqua — Ferazel's Wand ran on Mac OS 8/9, so its controls are drawn here in the classic style: black
// outlines on the dialog's `dctb` grey, the system font). Every view is flipped: dialog-local QuickDraw coordinates.
// Approximate [LOW, Ben's eye]: the Appearance Manager's Platinum bevels are reduced to flat outlines, and the system
// font (Charcoal / Chicago 12) is stood in for when absent.

/// The classic system font (Charcoal on Mac OS 8/9, Chicago before), 12 pt — every dialog item's text (no DLOG has an
/// `ictb`). Neither ships with macOS: the bold system font stands in.
@MainActor enum ClassicFont {
    static let system: NSFont = NSFont(name: "Charcoal", size: 12) ?? NSFont(name: "Chicago", size: 12)
        ?? .boldSystemFont(ofSize: 12)

    static var attributes: [NSAttributedString.Key: Any] { [.font: system, .foregroundColor: NSColor.black] }
    static var dimmed: [NSAttributedString.Key: Any] { [.font: system, .foregroundColor: NSColor.gray] }

    /// The baseline for a line of text whose box top is `top` (`ascent` below it, QuickDraw's `MoveTo(h, top + ascent)`).
    static func baseline(top: CGFloat) -> CGFloat { top + ceil(system.ascender) }
}

/// A 16-bit QuickDraw `RGBColor` as an `NSColor`.
func rgbColor(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> NSColor {
    NSColor(srgbRed: CGFloat(r) / 65535, green: CGFloat(g) / 65535, blue: CGFloat(b) / 65535, alpha: 1)
}

/// The dialog's content: the `dctb` content colour (`wContentColor`), the window frame (`dBoxProc`, proc 1: a 1-px black
/// line, the frame's grey, a 2-px black line) around the content, and what the game paints with QuickDraw itself on
/// the update event (`FrameRoundRect` default rings).
final class DialogRootView: NSView {
    /// The frame's width outside the content rect (the panel is that much larger on each side).
    static let frameWidth: CGFloat = 6
    var content: NSColor = rgbColor(0xeeee, 0xeeee, 0xeeee)
    var decorations: [(CGContext) -> Void] = []
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let cg = NSGraphicsContext.current?.cgContext else { return }
        cg.setFillColor(NSColor.black.cgColor)
        cg.fill(bounds)
        let f = Self.frameWidth
        cg.setFillColor(rgbColor(0xdddd, 0xdddd, 0xdddd).cgColor)
        cg.fill(bounds.insetBy(dx: 1, dy: 1))
        cg.setFillColor(NSColor.black.cgColor)
        cg.fill(bounds.insetBy(dx: f - 2, dy: f - 2))
        cg.setFillColor(content.cgColor)
        cg.fill(bounds.insetBy(dx: f, dy: f))
        cg.saveGState()
        cg.translateBy(x: f, y: f)
        for d in decorations { d(cg) }
        cg.restoreGState()
    }
}

/// The content area inside the frame: dialog-local coordinates, (0, 0) at the content's top left.
final class DialogContentView: NSView {
    override var isFlipped: Bool { true }
}

/// Base of the item views: a hit reports the item number (`ModalDialog` returning it).
class DialogItemView: NSView {
    let number: Int
    var enabled = true { didSet { needsDisplay = true } }
    /// `HiliteControl(255)`: drawn dimmed, takes no clicks.
    var active = true { didSet { needsDisplay = true } }
    var onHit: ((Int) -> Void)?
    override var isFlipped: Bool { true }

    init(number: Int, frame: NSRect) {
        self.number = number
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    /// `TrackControl`: tracks the press while the button is down; true when released inside.
    func track(_ event: NSEvent, highlight: (Bool) -> Void) -> Bool {
        var inside = true
        highlight(true)
        while let e = window?.nextEvent(matching: [.leftMouseUp, .leftMouseDragged]) {
            let p = convert(e.locationInWindow, from: nil)
            let now = bounds.contains(p)
            if now != inside {
                inside = now
                highlight(now)
            }
            if e.type == .leftMouseUp { break }
        }
        highlight(false)
        return inside
    }
}

/// A push button (`pushButProc`): a rounded rect, black outline, the title centred; inverted while pressed.
final class ClassicButton: DialogItemView {
    let title: String
    private(set) var highlighted = false

    init(number: Int, frame: NSRect, title: String) {
        self.title = title
        super.init(number: number, frame: frame)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    func setHighlighted(_ h: Bool) {
        highlighted = h
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let cg = NSGraphicsContext.current?.cgContext else { return }
        let r = bounds.insetBy(dx: 0.5, dy: 0.5)
        let radius = min(8, bounds.height / 2 - 1)
        let path = CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)
        cg.addPath(path)
        cg.setFillColor((highlighted ? NSColor.black : NSColor.white).cgColor)
        cg.fillPath()
        cg.addPath(path)
        cg.setStrokeColor((active ? NSColor.black : NSColor.gray).cgColor)
        cg.setLineWidth(1)
        cg.strokePath()
        var attrs = active ? ClassicFont.attributes : ClassicFont.dimmed
        if highlighted { attrs[.foregroundColor] = NSColor.white }
        let s = NSAttributedString(string: title, attributes: attrs)
        let size = s.size()
        s.draw(at: NSPoint(x: ((bounds.width - size.width) / 2).rounded(), y: ((bounds.height - size.height) / 2).rounded()))
    }

    override func mouseDown(with event: NSEvent) {
        guard enabled, active else { return }
        if track(event, highlight: setHighlighted) { onHit?(number) }
    }
}

/// A check box (`checkBoxProc`): a 12-px box at the left, vertically centred, an X when checked; the title after it.
final class ClassicCheckBox: DialogItemView {
    let title: String
    var value = 0 { didSet { needsDisplay = true } }
    private var highlighted = false

    init(number: Int, frame: NSRect, title: String) {
        self.title = title
        super.init(number: number, frame: frame)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    override func draw(_ dirtyRect: NSRect) {
        guard let cg = NSGraphicsContext.current?.cgContext else { return }
        let box = NSRect(x: 2, y: ((bounds.height - 12) / 2).rounded(), width: 12, height: 12)
        cg.setFillColor(NSColor.white.cgColor)
        cg.fill(box)
        cg.setStrokeColor((active ? NSColor.black : NSColor.gray).cgColor)
        cg.setLineWidth(highlighted ? 2 : 1)
        cg.stroke(box.insetBy(dx: highlighted ? 1 : 0.5, dy: highlighted ? 1 : 0.5))
        if value != 0 {
            cg.setLineWidth(1)
            cg.move(to: CGPoint(x: box.minX, y: box.minY))
            cg.addLine(to: CGPoint(x: box.maxX, y: box.maxY))
            cg.move(to: CGPoint(x: box.maxX, y: box.minY))
            cg.addLine(to: CGPoint(x: box.minX, y: box.maxY))
            cg.strokePath()
        }
        let s = NSAttributedString(string: title, attributes: active ? ClassicFont.attributes : ClassicFont.dimmed)
        s.draw(at: NSPoint(x: box.maxX + 5, y: ((bounds.height - s.size().height) / 2).rounded()))
    }

    override func mouseDown(with event: NSEvent) {
        guard enabled, active else { return }
        let hit = track(event) { [weak self] h in
            self?.highlighted = h
            self?.needsDisplay = true
        }
        if hit { onHit?(number) }
    }
}

/// A popup menu control (`popupMenuProc`, CNTL 600–605: no title, `max` 0): a box with a drop shadow, the current
/// item's text and a down triangle; a press pops the `MENU` up over the box with the current item marked
/// (`TrackControl` with the default action). The value is 1-based.
final class ClassicPopup: DialogItemView {
    var titles: [String] = [] { didSet { needsDisplay = true } }
    var value = 1 { didSet { needsDisplay = true } }
    /// Called after a pick (the value set) — `ModalDialog` returns the item.
    var onPick: ((Int, Int) -> Void)?

    override func draw(_ dirtyRect: NSRect) {
        guard let cg = NSGraphicsContext.current?.cgContext else { return }
        let box = NSRect(x: 0, y: 0, width: bounds.width - 1, height: bounds.height - 1)
        cg.setFillColor(NSColor.black.cgColor)
        cg.fill(NSRect(x: 2, y: box.maxY, width: box.width - 1, height: 1))       // the shadow
        cg.fill(NSRect(x: box.maxX, y: 2, width: 1, height: box.height - 1))
        cg.setFillColor(NSColor.white.cgColor)
        cg.fill(box)
        cg.setStrokeColor((active ? NSColor.black : NSColor.gray).cgColor)
        cg.setLineWidth(1)
        cg.stroke(box.insetBy(dx: 0.5, dy: 0.5))
        let tri = CGFloat(10)
        let tx = box.maxX - tri - 6, ty = (box.height / 2 - 2).rounded()
        cg.setFillColor((active ? NSColor.black : NSColor.gray).cgColor)
        cg.move(to: CGPoint(x: tx, y: ty))
        cg.addLine(to: CGPoint(x: tx + tri, y: ty))
        cg.addLine(to: CGPoint(x: tx + tri / 2, y: ty + tri / 2))
        cg.closePath()
        cg.fillPath()
        guard value >= 1, value <= titles.count else { return }
        let s = NSAttributedString(string: titles[value - 1], attributes: active ? ClassicFont.attributes
                                                                                  : ClassicFont.dimmed)
        cg.saveGState()
        cg.clip(to: NSRect(x: 4, y: 0, width: max(0, tx - 8), height: box.height))
        s.draw(at: NSPoint(x: 13, y: ((box.height - s.size().height) / 2).rounded()))
        cg.restoreGState()
    }

    override func mouseDown(with event: NSEvent) {
        guard enabled, active, !titles.isEmpty else { return }
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.font = ClassicFont.system
        for (i, t) in titles.enumerated() {
            let item = NSMenuItem(title: t, action: #selector(picked(_:)), keyEquivalent: "")
            item.target = self
            item.tag = i + 1
            item.state = i + 1 == value ? .on : .off
            menu.addItem(item)
        }
        menu.minimumWidth = bounds.width
        let current = value >= 1 && value <= titles.count ? menu.item(at: value - 1) : nil
        menu.popUp(positioning: current, at: NSPoint(x: 0, y: bounds.height - 2), in: self)
    }

    @objc private func picked(_ sender: NSMenuItem) {
        value = sender.tag
        onPick?(number, sender.tag)
    }
}

/// A static text item (`statText`): its text (after `ParamText`) in the item rect, wrapped as `TETextBox` does.
final class ClassicStaticText: DialogItemView {
    var text: String { didSet { needsDisplay = true } }

    init(number: Int, frame: NSRect, text: String) {
        self.text = text
        super.init(number: number, frame: frame)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    override func draw(_ dirtyRect: NSRect) {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        var attrs = ClassicFont.attributes
        attrs[.paragraphStyle] = style
        NSAttributedString(string: text, attributes: attrs).draw(with: bounds, options: [.usesLineFragmentOrigin])
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

/// An edit text item (`editText`) as TextEdit drew it in a dialog: a 1-px frame 3 px outside the item rect, the text
/// from the rect's top left; `SelectDialogItemText(item, 0, 0x7fff)` highlights the whole text in the `HiliteColor`
/// (an empty one shows the blinking insertion point). The text only ever changes through the dialog (O1's key capture).
final class ClassicEditText: DialogItemView {
    /// The item rect inside this view (the view is the rect outset by 4: the frame and its white margin).
    static let outset: CGFloat = 4
    var text = "" { didSet { needsDisplay = true } }
    var selected = false { didSet { needsDisplay = true } }
    var caretVisible = true { didSet { if selected && text.isEmpty { needsDisplay = true } } }
    /// The dialog's `HiliteColor` while it is up.
    var hilite: NSColor = rgbColor(30000, 30000, 65535)

    override func draw(_ dirtyRect: NSRect) {
        guard let cg = NSGraphicsContext.current?.cgContext else { return }
        let frame = bounds.insetBy(dx: 1, dy: 1)
        cg.setFillColor(NSColor.white.cgColor)
        cg.fill(frame)
        cg.setStrokeColor(NSColor.black.cgColor)
        cg.setLineWidth(1)
        cg.stroke(frame.insetBy(dx: 0.5, dy: 0.5))
        let o = Self.outset
        let s = NSAttributedString(string: text, attributes: ClassicFont.attributes)
        let lineHeight = ceil(ClassicFont.system.ascender - ClassicFont.system.descender)
        if selected {
            if text.isEmpty {
                if caretVisible {
                    cg.setFillColor(NSColor.black.cgColor)
                    cg.fill(NSRect(x: o, y: o, width: 1, height: lineHeight))
                }
            } else {
                cg.setFillColor(hilite.cgColor)
                cg.fill(NSRect(x: o, y: o, width: min(ceil(s.size().width), bounds.width - 2 * o), height: lineHeight))
            }
        }
        cg.saveGState()
        cg.clip(to: bounds.insetBy(dx: o, dy: o))
        s.draw(at: NSPoint(x: o, y: o))
        cg.restoreGState()
    }

    override func mouseDown(with event: NSEvent) {
        guard enabled else { return }
        onHit?(number)
    }
}

/// A picture item (`picItem`): `DrawPicture` into the item rect (scaled to it, no smoothing).
final class ClassicPicture: DialogItemView {
    var image: CGImage? { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        guard let image, let cg = NSGraphicsContext.current?.cgContext else { return }
        cg.saveGState()
        cg.interpolationQuality = .none
        cg.translateBy(x: 0, y: bounds.height)
        cg.scaleBy(x: 1, y: -1)
        cg.draw(image, in: CGRect(origin: .zero, size: bounds.size))
        cg.restoreGState()
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

/// A user item: drawn by its proc (`draw`, nil = nothing); an enabled one returns its number on a click.
final class ClassicUserItem: DialogItemView {
    var drawProc: ((CGContext, NSRect) -> Void)? { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        guard let drawProc, let cg = NSGraphicsContext.current?.cgContext else { return }
        drawProc(cg, bounds)
    }

    override func mouseDown(with event: NSEvent) {
        if enabled { onHit?(number) }
    }

    override func hitTest(_ point: NSPoint) -> NSView? { enabled ? super.hitTest(point) : nil }
}
