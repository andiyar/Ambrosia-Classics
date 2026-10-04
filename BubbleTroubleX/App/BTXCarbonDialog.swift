import AppKit
import BubbleTroubleCore
import BubbleTroubleRender

/// A key event as a Carbon `ModalFilterProc` sees it: the event record's `charCode` (`message & 0xff`), its virtual
/// key code (`message >> 8 & 0xff`) and whether ⌘ was down (`modifiers & cmdKey`, the `+0xf & 1` test every BTX
/// filter makes).
struct DialogKey {
    let char: UInt8
    let keyCode: UInt16
    let command: Bool

    /// The classic character code AppKit's `NSEvent.characters` maps to private-use function keys: arrows
    /// 0x1c–0x1f, Delete 0x08, Forward Delete 0x7f, Home 0x01, End 0x04, Page Up/Down 0x0b/0x0c, Help 0x05,
    /// F-keys 0x10. ⌘ keys carry the unmodified character (Carbon's `charCode` ignores ⌘).
    init(_ event: NSEvent) {
        keyCode = event.keyCode
        command = event.modifierFlags.contains(.command)
        let source = command ? event.charactersIgnoringModifiers : event.characters
        let scalar = source?.unicodeScalars.first?.value ?? 0
        char = switch scalar {
        case 0xF702: 0x1c
        case 0xF703: 0x1d
        case 0xF700: 0x1e
        case 0xF701: 0x1f
        case 0x7f: 0x08
        case 0xF728: 0x7f
        case 0xF729: 0x01
        case 0xF72B: 0x04
        case 0xF72C: 0x0b
        case 0xF72D: 0x0c
        case 0xF746: 0x05
        case 0xF704...0xF726: 0x10
        case 0..<0x80: UInt8(scalar)
        default:
            // MacRoman byte of a non-ASCII character (the Carbon charCode), else 0.
            source.flatMap { String($0.prefix(1)).data(using: .macOSRoman)?.first } ?? 0
        }
    }

    /// ⌘ + the char upper-cased as the filters do (`c + 0x9f < 0x1a` → `c − 0x20`).
    var commandUppercased: UInt8 { char &+ 0x9f < 0x1a ? char &- 0x20 : char }
}

/// The font Carbon drew dialog text and Aqua controls in on Mac OS X: the system font, Lucida Grande 13 (no BTX
/// `DLOG` has a `dctb`/`ictb`, and every `dlgx` reads 0x0009 = theme background + theme controls — D4.1 Aqua).
@MainActor enum DialogFont {
    static let system: NSFont = NSFont(name: "Lucida Grande", size: 13) ?? .systemFont(ofSize: 13)
}

/// A Carbon dialog window (`dBoxProc`, no title bar): an Aqua panel that can be key.
final class CarbonDialogPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// The dialog's content: flipped (dialog-local QuickDraw coordinates), theme background, plus what the original
/// paints itself with QuickDraw on update events (`_OutlineItem`'s ring, `_TouchUpPrefsDialog`'s frames).
final class DialogRootView: NSView {
    var decorations: [(CGContext) -> Void] = []
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        bounds.fill()
        guard let cg = NSGraphicsContext.current?.cgContext else { return }
        for d in decorations { d(cg) }
    }
}

/// A `PICT` item: `DrawPicture` into the item rect (scaled to it, no smoothing — CopyBits).
final class DialogPictureView: NSView {
    var image: CGImage? { didSet { needsDisplay = true } }
    var darkened = false { didSet { needsDisplay = true } }
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let image, let cg = NSGraphicsContext.current?.cgContext else { return }
        cg.saveGState()
        cg.interpolationQuality = .none
        // CGContext draws images bottom-up; flip back inside this flipped view.
        cg.translateBy(x: 0, y: bounds.height)
        cg.scaleBy(x: 1, y: -1)
        cg.beginTransparencyLayer(auxiliaryInfo: nil)
        cg.draw(image, in: CGRect(origin: .zero, size: bounds.size))
        if darkened {
            // `PlotCIconHandle(…, kTransformSelected)`: the selected (darkened) icon, inside its own mask.
            cg.setBlendMode(.sourceAtop)
            cg.setFillColor(NSColor.black.withAlphaComponent(0.5).cgColor)
            cg.fill(CGRect(origin: .zero, size: bounds.size))
        }
        cg.endTransparencyLayer()
        cg.restoreGState()
    }

    // Disabled items take no clicks: `FindDialogItem` passes them to the item under them.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

/// A static-text item (always disabled in BTX): `TETextBox` of its text in the item rect; takes no clicks.
final class DialogStaticText: NSTextField {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

/// A user item: no drawing of its own; an enabled one makes `ModalDialog` return its number on a click.
final class DialogUserItemView: NSView {
    var onMouseDown: (() -> Void)?
    override var isFlipped: Bool { true }
    override func mouseDown(with event: NSEvent) { onMouseDown?() }
    override func hitTest(_ point: NSPoint) -> NSView? { onMouseDown == nil ? nil : super.hitTest(point) }
}

/// An edit-text item; a click in it (after the field takes it) makes `ModalDialog` return its number.
final class DialogEditField: NSTextField {
    var onMouseDown: (() -> Void)?
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        onMouseDown?()
    }
}

/// One Carbon dialog built from its `DLOG`/`ALRT` + `DITL` (Dialog Manager semantics, as BTX uses them):
/// items in dialog coordinates, `ParamText` substitution, `SetDialogDefaultItem`/`SetDialogCancelItem`, a modal
/// filter for keys, `_FlashMyDialogItem` (button hilited 8 ticks, then the hit), `AppendDITL`/`ShortenDITL`,
/// show / hide / activate items, control values. Events reach it through `BTXDialogs`' modal event routing.
@MainActor final class CarbonDialog: NSObject {
    let template: DialogTemplate
    let panel: CarbonDialogPanel
    let root: DialogRootView
    private(set) var items: [DialogItem]
    private var views: [Int: NSView] = [:]
    /// Control values (`GetControlValue`): checkbox 0/1, popup 1-based item.
    private var values: [Int: Int] = [:]
    private var hidden: Set<Int> = []
    private let data: BTXGameData
    private let art: ArtBank
    /// `ParamText(^0, ^1, ^2, ^3)` at creation.
    let params: [String]

    /// `SetDialogDefaultItem`: Aqua default button; Return / Enter press it when the filter lets the key through.
    var defaultItem: Int? { didSet { applyDefault() } }
    /// `SetDialogCancelItem`: Esc / ⌘. press it when the filter lets the key through.
    var cancelItem: Int?
    /// The `ModalFilterProc` for keyDown / autoKey: true = handled (the event goes no further).
    var keyFilter: ((DialogKey) -> Bool)?
    /// Called once per tick while this dialog is frontmost (the filter's null events).
    var nullEvent: (() -> Void)?
    /// `ModalDialog` returned this item.
    var itemHit: ((Int) -> Void)?
    /// `_WaitUntilKeyOrMousePress` dialogs (DLOG 290/291): any key or click anywhere ends it.
    var endsOnAnyPress = false
    /// `_Delay(8)` inside `_FlashMyDialogItem` blocks everything.
    private(set) var flashing = false

    init(template: DialogTemplate, data: BTXGameData, art: ArtBank, params: [String] = []) {
        self.template = template
        self.data = data
        self.art = art
        self.params = params
        items = []
        let rect = NSRect(origin: .zero, size: template.size)
        panel = CarbonDialogPanel(contentRect: rect, styleMask: [.titled, .fullSizeContentView],
                                  backing: .buffered, defer: false)
        root = DialogRootView(frame: rect)
        super.init()
        panel.appearance = NSAppearance(named: .aqua)
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        for b: NSWindow.ButtonType in [.closeButton, .miniaturizeButton, .zoomButton] {
            panel.standardWindowButton(b)?.isHidden = true
        }
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.acceptsMouseMovedEvents = true
        panel.contentView = root
        append(template.items)
        if template.alertStages != nil { addAlertIcon() }
    }

    // MARK: - Items

    /// `AppendDITL(dialog, ditl, overlayDITL)`: the items keep their own rects, numbered after the dialog's.
    func append(_ newItems: [DialogItem]) {
        for item in newItems {
            items.append(item)
            let view = makeView(item)
            views[item.number] = view
            root.addSubview(view)
        }
    }

    /// `ShortenDITL` to `count` items.
    func shorten(to count: Int) {
        while items.count > count, let last = items.popLast() {
            views.removeValue(forKey: last.number)?.removeFromSuperview()
            values.removeValue(forKey: last.number)
            hidden.remove(last.number)
        }
    }

    func item(_ n: Int) -> DialogItem? { items.first { $0.number == n } }

    private func substituted(_ s: String) -> String {
        var out = s
        for (i, p) in params.enumerated() { out = out.replacingOccurrences(of: "^\(i)", with: p) }
        return out
    }

    private func makeView(_ item: DialogItem) -> NSView {
        let r = item.rect
        switch item.kind {
        case .button:
            let b = NSButton(title: substituted(item.text), target: self, action: #selector(buttonHit(_:)))
            b.bezelStyle = .push
            b.font = DialogFont.system
            b.tag = item.number
            b.frame = b.frame(forAlignmentRect: r)
            return b
        case .checkBox, .radio:
            let b = item.kind == .checkBox
                ? NSButton(checkboxWithTitle: substituted(item.text), target: self, action: #selector(checkHit(_:)))
                : NSButton(radioButtonWithTitle: substituted(item.text), target: self, action: #selector(checkHit(_:)))
            b.font = DialogFont.system
            b.tag = item.number
            b.frame = b.frame(forAlignmentRect: r)
            values[item.number] = 0
            return b
        case .staticText:
            let t = DialogStaticText(wrappingLabelWithString: substituted(item.text))
            t.font = DialogFont.system
            t.textColor = .labelColor
            t.frame = r
            t.isSelectable = false
            return t
        case .editText:
            let t = DialogEditField(string: substituted(item.text))
            t.font = DialogFont.system
            t.isBezeled = true
            t.bezelStyle = .squareBezel
            t.isEditable = true
            t.isSelectable = true
            t.usesSingleLineMode = true
            t.lineBreakMode = .byClipping
            t.cell?.isScrollable = true
            // Carbon draws the Aqua edit frame 3 px outside the item rect.
            t.frame = r.insetBy(dx: -3, dy: -3)
            t.tag = item.number
            if item.enabled {
                let n = item.number
                t.onMouseDown = { [weak self] in self?.hit(n) }
            }
            return t
        case .picture(let id):
            let v = DialogPictureView(frame: r)
            v.image = (try? art.pict(id)).flatMap(BTXDialogResources.cgImage)
            return v
        case .control(let cntl):
            return makePopup(item, cntl: cntl)
        case .user, .icon, .other:
            let v = DialogUserItemView(frame: r)
            if item.enabled {
                let n = item.number
                v.onMouseDown = { [weak self] in self?.hit(n) }
            }
            return v
        }
    }

    /// A `popupMenuProc` control: its title (system font, `titleWidth` px) left of the Aqua popup button.
    private func makePopup(_ item: DialogItem, cntl: Int) -> NSView {
        let r = item.rect
        let container = NSView(frame: r)
        guard let c = BTXDialogResources.popupControl(cntl, data: data) else { return container }
        let width = CGFloat(c.titleWidth)
        let label = NSTextField(labelWithString: c.title)
        label.font = DialogFont.system
        label.frame = NSRect(x: 0, y: 0, width: width, height: r.height)
        label.alignment = .left
        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        popup.font = DialogFont.system
        popup.autoenablesItems = false
        popup.target = self
        popup.action = #selector(popupHit(_:))
        popup.tag = item.number
        popup.frame = popup.frame(forAlignmentRect: NSRect(x: width, y: 0, width: r.width - width, height: r.height))
        container.addSubview(label)
        container.addSubview(popup)
        fill(popup, titles: BTXDialogResources.menuItems(c.menuID, data: data))
        // Label baseline: centre it on the popup's rect (the CDEF draws the title vertically centred).
        let h = label.intrinsicContentSize.height
        label.frame = NSRect(x: 0, y: (r.height - h) / 2, width: width, height: h)
        values[item.number] = 1
        return container
    }

    private func popupButton(_ item: Int) -> NSPopUpButton? {
        views[item]?.subviews.compactMap { $0 as? NSPopUpButton }.first
    }

    /// The popup's menu items; `"-"` / `"(-"` become separators (Menu Manager metacharacters).
    func setMenu(_ item: Int, titles: [String]) {
        guard let popup = popupButton(item) else { return }
        fill(popup, titles: titles)
        if let v = values[item], v >= 1, v <= popup.numberOfItems { popup.selectItem(at: v - 1) }
    }

    private func fill(_ popup: NSPopUpButton, titles: [String]) {
        popup.removeAllItems()
        for t in titles {
            if t == "-" || t == "(-" {
                popup.menu?.addItem(.separator())
            } else {
                popup.menu?.addItem(withTitle: t, action: nil, keyEquivalent: "")
            }
        }
    }

    // MARK: - Values, text, visibility

    func value(_ item: Int) -> Int { values[item] ?? 0 }

    /// `SetControlValue`.
    func setValue(_ item: Int, _ v: Int) {
        values[item] = v
        if let popup = popupButton(item) {
            if v >= 1, v <= popup.numberOfItems { popup.selectItem(at: v - 1) }
        } else if let b = views[item] as? NSButton {
            b.state = v != 0 ? .on : .off
        }
    }

    /// `GetDialogItemText` (an edit item mid-edit reads its field editor).
    func text(_ item: Int) -> String {
        guard let t = views[item] as? NSTextField else { return "" }
        if let editor = t.currentEditor() { return editor.string }
        return t.stringValue
    }

    /// `SetDialogItemText`.
    func setText(_ item: Int, _ s: String) {
        guard let t = views[item] as? NSTextField else { return }
        if let editor = t.currentEditor() as? NSTextView {
            editor.string = s
        }
        t.stringValue = s
    }

    /// The edit item that has the TextEdit focus, if any.
    var focusedEditItem: Int? {
        for (n, v) in views {
            if let t = v as? DialogEditField, t.currentEditor() != nil { return n }
        }
        return nil
    }

    /// The focused edit item's selection length (`teSelEnd − teSelStart`).
    var selectionLength: Int {
        guard let n = focusedEditItem, let t = views[n] as? NSTextField,
              let editor = t.currentEditor() else { return 0 }
        return editor.selectedRange.length
    }

    /// `SelectDialogItemText(dialog, item, start, end)` — also moves the TextEdit focus there.
    func selectText(_ item: Int, from start: Int = 0, to end: Int = 0x7fff) {
        guard let t = views[item] as? NSTextField else { return }
        if t.currentEditor() == nil { panel.makeFirstResponder(t) }
        guard let editor = t.currentEditor() else { return }
        let length = (editor.string as NSString).length
        let s = min(max(start, 0), length), e = min(max(end, s), length)
        editor.selectedRange = NSRange(location: s, length: e - s)
    }

    /// `ShowDialogItem` / `HideDialogItem`.
    func setHidden(_ item: Int, _ isHidden: Bool) {
        if isHidden { hidden.insert(item) } else { hidden.remove(item) }
        guard let v = views[item] else { return }
        if isHidden, let t = v as? NSTextField, t.currentEditor() != nil { panel.makeFirstResponder(nil) }
        v.isHidden = isHidden
    }

    /// `ActivateControl` / `DeactivateControl` (`_ActivateItem` / `_DeactivateItem`).
    func setActive(_ item: Int, _ active: Bool) {
        if let popup = popupButton(item) { popup.isEnabled = active }
        if let c = views[item] as? NSControl { c.isEnabled = active }
    }

    /// The first (lowest-numbered) shown item whose rect holds `point` (dialog coordinates) — `_MouseInWhichPrefsItem`'s
    /// `GetDialogItem` + `PtInRect` scan. Hidden items are skipped: `HideDialogItem` moves their rects off by 16384.
    func item(at point: CGPoint) -> Int? {
        for item in items where !hidden.contains(item.number) {
            let r = item.rect
            if point.x >= r.minX, point.x < r.maxX, point.y >= r.minY, point.y < r.maxY { return item.number }
        }
        return nil
    }

    /// The mouse in dialog coordinates (`GetMouse` in the dialog port).
    var mouseLocation: CGPoint {
        root.convert(panel.mouseLocationOutsideOfEventStream, from: nil)
    }

    // MARK: - Default ring / alert icon

    private func applyDefault() {
        for (n, v) in views {
            guard let b = v as? NSButton, b.bezelStyle == .push else { continue }
            b.keyEquivalent = n == defaultItem ? "\r" : ""
        }
    }

    /// `_OutlineItem(dialog, item)` on every update event (`_NewSetDlgFilter`, `_HiScoreEraseFilter`): `InsetRect(−4,
    /// −4)`, black pen 3×3, `FrameRoundRect` with oval (height / 2 + 2).
    func outline(_ item: Int) {
        guard let r = self.item(item)?.rect else { return }
        root.decorations.append { cg in
            let o = r.insetBy(dx: -4, dy: -4)
            let oval = CGFloat(Int(o.height) / 2 + 2)
            cg.setStrokeColor(NSColor.black.cgColor)
            cg.setLineWidth(3)
            // A QuickDraw 3×3 pen frames inside the rect: stroke the path inset by half the pen.
            let path = CGPath(roundedRect: o.insetBy(dx: 1.5, dy: 1.5), cornerWidth: (oval - 3) / 2,
                              cornerHeight: (oval - 3) / 2, transform: nil)
            cg.addPath(path)
            cg.strokePath()
        }
        root.needsDisplay = true
    }

    /// `NoteAlert` / `StopAlert` on Mac OS X draw the application icon at (left 20, top 10), 32×32.
    private func addAlertIcon() {
        let v = NSImageView(frame: NSRect(x: 20, y: 10, width: 32, height: 32))
        v.image = NSApp?.applicationIconImage
        v.imageScaling = .scaleProportionallyUpOrDown
        root.addSubview(v)
    }

    // MARK: - Hits

    @objc private func buttonHit(_ sender: NSButton) { hit(sender.tag) }

    @objc private func checkHit(_ sender: NSButton) {
        // Carbon does not toggle a dialog checkbox: ModalDialog returns the item and the app sets the value.
        sender.state = value(sender.tag) != 0 ? .on : .off
        hit(sender.tag)
    }

    @objc private func popupHit(_ sender: NSPopUpButton) {
        values[sender.tag] = sender.indexOfSelectedItem + 1
        hit(sender.tag)
    }

    private func hit(_ item: Int) {
        guard !flashing else { return }
        itemHit?(item)
    }

    /// `_FlashMyDialogItem`: `HiliteControl(1)`, `Delay(8)`, `HiliteControl(0)` — then `ModalDialog` returns `item`.
    func flash(_ item: Int) {
        guard !flashing else { return }
        guard let b = views[item] as? NSButton else { hit(item); return }
        flashing = true
        b.highlight(true)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(8 * 1000 / 60))
            b.highlight(false)
            guard let self else { return }
            flashing = false
            hit(item)
        }
    }

    // MARK: - Keys (ModalDialog: filter, then the standard filter, then TextEdit)

    /// Returns true when the key event is consumed here; false lets it through to the focused edit field.
    func handleKeyDown(_ event: NSEvent) -> Bool {
        if flashing { return true }
        let key = DialogKey(event)
        if let f = keyFilter, f(key) { return true }
        // The standard filter (`SetDialogDefaultItem` / `SetDialogCancelItem`).
        if !key.command, key.char == 0x0d || key.char == 0x03 {
            if let d = defaultItem { flash(d) }
            return true
        }
        if (!key.command && key.char == 0x1b) || (key.command && key.char == UInt8(ascii: ".")) {
            if let c = cancelItem { flash(c) }
            return true
        }
        // App-modal: no menu command reaches the app while a dialog is up, and TextEdit takes no ⌘ keys.
        if key.command { return true }
        if key.char == 0x09 {
            tabToNextEditField()
            return true
        }
        guard focusedEditItem != nil else { return true }
        // TextEdit: printable characters, Delete and the arrows edit; other control characters are dropped.
        let editing = key.char >= 0x20 && key.char != 0x7f || [0x08, 0x1c, 0x1d, 0x1e, 0x1f].contains(key.char)
        return !editing
    }

    /// Dialog Manager Tab: the next shown edit item, all of its text selected.
    private func tabToNextEditField() {
        let edits = items.filter { $0.kind == .editText && !hidden.contains($0.number) }.map(\.number)
        guard !edits.isEmpty else { return }
        let current = focusedEditItem.flatMap { edits.firstIndex(of: $0) } ?? -1
        selectText(edits[(current + 1) % edits.count])
    }

    // MARK: - Showing

    /// Shows the dialog at the `alertPosition…` place (horizontally centred, a third of the free height above it)
    /// on the main screen, at `level` (BTX: `CGShieldingWindowLevel` in full screen, floating windowed — FI §1d).
    func show(level: NSWindow.Level, fullScreen: Bool) {
        panel.level = level
        if let screen = NSScreen.main {
            let area = fullScreen ? screen.frame : screen.visibleFrame
            let size = template.size
            let x = (area.midX - size.width / 2).rounded()
            let top = area.maxY - ((area.height - size.height) / 3).rounded()
            panel.setFrame(NSRect(x: x, y: top - size.height, width: size.width, height: size.height), display: true)
        }
        panel.makeKeyAndOrderFront(nil)
    }

    /// `DisposeDialog`.
    func dispose() {
        panel.makeFirstResponder(nil)
        panel.orderOut(nil)
    }
}
