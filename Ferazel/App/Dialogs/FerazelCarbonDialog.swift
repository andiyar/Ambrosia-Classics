import AppKit
import FerazelCore

/// A key event as a `ModalFilterProc` sees it (the event record): the character code (`message & 0xff`, Mac Roman), the
/// virtual key code (`message >> 8 & 0xff`), the modifiers word (`cmdKey` 0x100, `shiftKey` 0x200, `alphaLock` 0x400,
/// `optionKey` 0x800, `controlKey` 0x1000; `btnState` 0x80 set while the button is UP) and whether it is an auto-key.
struct DialogKey {
    let char: UInt8
    let keyCode: Int
    let modifiers: UInt16
    let isRepeat: Bool

    init(_ event: NSEvent) {
        keyCode = Int(event.keyCode)
        modifiers = Self.modifiers(event.modifierFlags)
        isRepeat = event.isARepeat
        let command = event.modifierFlags.contains(.command)
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
        default: source.flatMap { String($0.prefix(1)).data(using: .macOSRoman)?.first } ?? 0
        }
    }

    /// The event record's modifiers word for `flags` (and the button state, read live).
    static func modifiers(_ flags: NSEvent.ModifierFlags) -> UInt16 {
        var m: UInt16 = NSEvent.pressedMouseButtons & 1 == 0 ? 0x80 : 0
        if flags.contains(.command) { m |= 0x100 }
        if flags.contains(.shift) { m |= 0x200 }
        if flags.contains(.capsLock) { m |= 0x400 }
        if flags.contains(.option) { m |= 0x800 }
        if flags.contains(.control) { m |= 0x1000 }
        return m
    }
}

/// One dialog item as the Dialog Manager holds it (R1's `DialogItemList.Item` numbered): the rect in dialog-local
/// coordinates (top-left origin, y down).
struct DialogItem {
    let number: Int
    let item: DialogItemList.Item
    var rect: CGRect {
        CGRect(x: CGFloat(item.rect.left), y: CGFloat(item.rect.top), width: CGFloat(item.rect.width),
               height: CGFloat(item.rect.height))
    }
    var enabled: Bool { !item.disabled }
}

/// A borderless panel that can be key (the dialog takes the keyboard).
final class ClassicDialogPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// One Dialog Manager window built from R1's templates (`GetNewDialog(id)`: the `DLOG` + its `DITL`): an `NSPanel` the
/// size of the DLOG rect (plus the `dBoxProc` frame), the `dctb` content colour, the items at their DITL rects in
/// points, `ParamText` (`^0`…`^3`), `AppendDITL` / `ShortenDITL`, control values, show / hide, `HiliteControl(255)`, the
/// game's own `FrameRoundRect` default ring, and `ModalDialog`'s standard filter (Return / Enter → the default item,
/// its button hilited 8 ticks first). Keys and clicks reach it through `FerazelDialogs`' modal routing.
@MainActor final class FerazelCarbonDialog: NSObject {
    let template: DialogTemplate
    let panel: ClassicDialogPanel
    let root: DialogRootView
    let content: DialogContentView
    private(set) var items: [DialogItem] = []
    private var views: [Int: DialogItemView] = [:]
    private var hidden: Set<Int> = []
    private let resources: FerazelResources
    private let picture: (Int16) -> CGImage?
    /// `ParamText(^0, ^1, ^2, ^3)` at creation.
    let params: [String]

    /// `ModalDialog` returned this item.
    var itemHit: ((Int) -> Void)?
    /// The `ModalFilterProc` for keyDown / autoKey: true = handled. Nil = the standard filter only.
    var keyFilter: ((DialogKey) -> Bool)?
    /// Called once per tick while this dialog is frontmost (the filter's null events).
    var nullEvent: (() -> Void)?
    /// The standard filter's default item (the Dialog Manager's `aDefItem`, 1): Return / Enter press it.
    var defaultItem: Int? = 1
    /// A press made by the dialog's own clock (credits): every mouse-down is the dialog's, not the items'.
    var takesAllClicks = false
    private(set) var flashing = false

    /// `GetNewDialog(id)`: nil when the DLOG or its DITL is missing (the original beeps or quits there).
    init?(dialog id: Int16, resources: FerazelResources, picture: @escaping (Int16) -> CGImage?,
          params: [String] = []) {
        guard let t = try? DialogTemplate.load(from: resources, type: "DLOG", id: id),
              let list = try? DialogItemList.load(from: resources, id: t.itemsID) else { return nil }
        template = t
        self.resources = resources
        self.picture = picture
        self.params = params
        let f = DialogRootView.frameWidth
        let size = CGSize(width: CGFloat(t.bounds.width), height: CGFloat(t.bounds.height))
        let outer = NSRect(x: 0, y: 0, width: size.width + 2 * f, height: size.height + 2 * f)
        panel = ClassicDialogPanel(contentRect: outer, styleMask: [.borderless], backing: .buffered, defer: false)
        root = DialogRootView(frame: outer)
        content = DialogContentView(frame: NSRect(x: f, y: f, width: size.width, height: size.height))
        super.init()
        if let c = Self.contentColor(dctb: resources.resource(type: "dctb", id: id, chain: .frontEnd)?.data) {
            root.content = c
        }
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.hasShadow = true
        panel.isOpaque = true
        panel.backgroundColor = .black
        panel.contentView = root
        root.addSubview(content)
        append(list, renumberFrom: 1)
    }

    /// The `dctb`'s `wContentColor` (part 0): ctSeed(4) ctFlags(2) ctSize(2), then (part, r, g, b) words.
    static func contentColor(dctb: Data?) -> NSColor? {
        guard let d = dctb, d.count >= 8 else { return nil }
        let b = [UInt8](d)
        func u16(_ o: Int) -> UInt16 { UInt16(b[o]) << 8 | UInt16(b[o + 1]) }
        let n = Int(u16(6)) + 1
        for i in 0..<n {
            let o = 8 + 8 * i
            guard o + 8 <= b.count else { break }
            if u16(o) == 0 { return rgbColor(u16(o + 2), u16(o + 4), u16(o + 6)) }
        }
        return nil
    }

    // MARK: - Items

    /// `AppendDITL(dialog, ditl, overlayDITL)`: the items keep their own rects, numbered after the dialog's.
    func append(_ list: DialogItemList, renumberFrom first: Int? = nil) {
        let start = first ?? (items.count + 1)
        for (i, item) in list.items.enumerated() {
            let d = DialogItem(number: start + i, item: item)
            items.append(d)
            let view = makeView(d)
            views[d.number] = view
            content.addSubview(view)
        }
    }

    /// `ShortenDITL` to `count` items.
    func shorten(to count: Int) {
        while items.count > count, let last = items.popLast() {
            views.removeValue(forKey: last.number)?.removeFromSuperview()
            hidden.remove(last.number)
        }
    }

    func item(_ n: Int) -> DialogItem? { items.first { $0.number == n } }
    func view(_ n: Int) -> DialogItemView? { views[n] }

    private func substituted(_ s: String) -> String {
        var out = s
        for (i, p) in params.enumerated() { out = out.replacingOccurrences(of: "^\(i)", with: p) }
        for i in min(params.count, 4)..<4 { out = out.replacingOccurrences(of: "^\(i)", with: "") }
        return out.replacingOccurrences(of: "\r", with: "\n")
    }

    private func makeView(_ d: DialogItem) -> DialogItemView {
        let r = d.rect
        let text = d.item.text ?? ""
        let view: DialogItemView
        switch d.item.kind {
        case .button:
            view = ClassicButton(number: d.number, frame: r, title: substituted(text))
        case .checkBox, .radioButton:
            view = ClassicCheckBox(number: d.number, frame: r, title: substituted(text))
        case .staticText:
            view = ClassicStaticText(number: d.number, frame: r, text: substituted(text))
        case .editText:
            let e = ClassicEditText(number: d.number, frame: r.insetBy(dx: -ClassicEditText.outset,
                                                                      dy: -ClassicEditText.outset))
            e.text = substituted(text)
            view = e
        case .picture:
            let p = ClassicPicture(number: d.number, frame: r)
            if let id = d.item.resourceID { p.image = picture(id) }
            view = p
        case .control:
            let p = ClassicPopup(number: d.number, frame: r)
            if let id = d.item.resourceID, let c = try? ControlTemplate.load(from: resources, id: id),
               let m = try? MenuTemplate.load(from: resources, id: c.menuID) {
                p.titles = m.items.map(\.name)
                p.value = max(1, Int(c.value))
            }
            p.onPick = { [weak self] n, _ in self?.hit(n) }
            view = p
        case .userItem, .helpItem, .icon, .other:
            view = ClassicUserItem(number: d.number, frame: r)
        }
        view.enabled = d.enabled
        if !(view is ClassicPopup) { view.onHit = { [weak self] n in self?.hit(n) } }
        return view
    }

    // MARK: - Values, text, visibility

    /// `SetControlValue`.
    func setValue(_ item: Int, _ v: Int) {
        switch views[item] {
        case let c as ClassicCheckBox: c.value = v
        case let p as ClassicPopup: p.value = v
        default: break
        }
    }

    /// `SetDialogItemText`.
    func setText(_ item: Int, _ s: String) {
        switch views[item] {
        case let e as ClassicEditText: e.text = s
        case let t as ClassicStaticText: t.text = s
        default: break
        }
    }

    /// `SelectDialogItemText(item, 0, 0x7fff)` — the TextEdit focus there (nil: none).
    func select(_ item: Int?) {
        for (n, v) in views { (v as? ClassicEditText)?.selected = n == item }
    }

    /// `ShowDialogItem` / `HideDialogItem`.
    func setHidden(_ item: Int, _ isHidden: Bool) {
        if isHidden { hidden.insert(item) } else { hidden.remove(item) }
        views[item]?.isHidden = isHidden
    }

    /// `HiliteControl(0 / 255)` (and the item's disabled bit, `SetDialogItem(…, 0x84)` — `.UpdateDisabledItems`).
    func setActive(_ item: Int, _ active: Bool) {
        views[item]?.active = active
        views[item]?.enabled = active && (self.item(item)?.enabled ?? true)
    }

    /// The `FrameRoundRect` the game draws round its default button on the update event (`.ConfirmAbortGameDialog`,
    /// `.GenericMessage`, `.PreferencesDialog`): the item rect `InsetRect(−4, −4)`, pen 3 × 3, oval 15 × 15.
    func outlineDefault(_ item: Int) {
        guard let r = self.item(item)?.rect else { return }
        root.decorations.append { cg in
            let o = r.insetBy(dx: -4, dy: -4)
            cg.setStrokeColor(NSColor.black.cgColor)
            cg.setLineWidth(3)
            // A QuickDraw pen frames inside the rect: the path inset by half the pen; corner radius = (oval − pen) / 2.
            cg.addPath(CGPath(roundedRect: o.insetBy(dx: 1.5, dy: 1.5), cornerWidth: 6, cornerHeight: 6, transform: nil))
            cg.strokePath()
        }
        root.needsDisplay = true
    }

    /// The mouse in dialog-local coordinates (`GetMouse` in the dialog port).
    var mouseLocation: CGPoint {
        content.convert(panel.mouseLocationOutsideOfEventStream, from: nil)
    }

    /// The port rect (`dialog + 0x10`): the content area.
    var portRect: CGRect { CGRect(origin: .zero, size: content.bounds.size) }

    // MARK: - Hits

    func hit(_ item: Int) {
        guard !flashing else { return }
        itemHit?(item)
    }

    /// The standard filter's Return / Enter: the button hilited (`HiliteControl(1)`), 8 ticks, unhilited, then the hit.
    func flash(_ item: Int) {
        guard !flashing else { return }
        guard let b = views[item] as? ClassicButton else { hit(item); return }
        flashing = true
        b.setHighlighted(true)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(8 * 1000 / 60))
            b.setHighlighted(false)
            guard let self else { return }
            flashing = false
            hit(item)
        }
    }

    /// `HiliteControl(item, 1)` for the rest of the dialog's life (the Options filter's Return / Esc).
    func hilite(_ item: Int) {
        (views[item] as? ClassicButton)?.setHighlighted(true)
    }

    // MARK: - Keys

    /// `ModalDialog`'s key handling: the filter, then the standard filter (Return / Enter → the default item). Other
    /// keys do nothing here (no dialog of the game leaves an editable field to TextEdit). Always consumed.
    func handleKeyDown(_ event: NSEvent) {
        if flashing { return }
        let key = DialogKey(event)
        if let f = keyFilter, f(key) { return }
        if key.modifiers & 0x100 == 0, key.char == 0x0d || key.char == 0x03, let d = defaultItem { flash(d) }
    }

    // MARK: - Showing

    /// `ShowWindow` + `SelectWindow`: the DLOG's position word 0x280A (`kWindowCenterMainScreen` — every DLOG this
    /// game shows) centres it on the main screen, which for the game was its 640×480 screen: centred on the game image
    /// (`area`, screen coordinates). At `level`.
    func show(over area: NSRect, level: NSWindow.Level) {
        panel.level = level
        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(x: (area.midX - size.width / 2).rounded(), y: (area.midY - size.height / 2).rounded()))
        panel.makeKeyAndOrderFront(nil)
    }

    /// `DisposeDialog`.
    func dispose() {
        panel.orderOut(nil)
    }
}
