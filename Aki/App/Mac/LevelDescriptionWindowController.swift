import AppKit
import AkiCore

/// `LevelDescriptionWindowController` (method-map §1; Research note 6; levels.md §3–4): the window of
/// `LevelDescription.nib` — the level's 237×181 preview, its title and description, a "Display Level
/// Description" checkbox, Continue / Cancel — shown before a level while p+0x214 is set. Built once from
/// the nib's `designable.nib` XML (`-init` @ 0x29f79, `initWithWindowNibName:@"LevelDescription"`) and
/// shared, so the checkbox keeps its state across shows within a session; it starts as archived (OFF, Q5).
@MainActor final class LevelDescriptionWindowController: NSObject {
    /// `_sharedController` (the static @ 0x124872 in `+runModalWithTitle:description:image:`).
    private static var shared: LevelDescriptionWindowController?

    private unowned let controller: AkiController
    private let window: NSWindow
    private let imageView: NSImageView                         // _imageView (ivar 0x2c)
    private let titleTextField: NSTextField                    // _titleTextField (ivar 0x30)
    private let descriptionTextField: NSTextField              // _descriptionTextField (ivar 0x34)
    private let checkbox: NSButton                             // _checkbox (ivar 0x28)

    /// `+[LevelDescriptionWindowController runModalWithLayout:custom:]` @ 0x29d40 (levels.md §3, read
    /// from `otool`): n = layout + 1; title `level%d_custom_title` when `custom`, else `level%d_title`;
    /// description `level%d_description`; image `preview%d`; then `+runModalWithTitle:description:image:`
    /// @ 0x29e86 (DC:11369): the shared instance, `_setupWithTitle:description:image:` @ 0x2a0a7 (DC:11446),
    /// `scheduleSetShieldingLevel` when fullscreen, `runModalForWindow:` (AppKit centres it — Q6).
    static func runModal(layout: Int, custom: Bool, app: AkiAppDelegate) {
        let controller = app.controller
        let n = layout + 1
        let assets = controller.assets!
        let title = assets.localized(custom ? "level\(n)_custom_title" : "level\(n)_title")
        let description = assets.localized("level\(n)_description")
        let image = assets.image("preview\(n)")

        let instance: LevelDescriptionWindowController
        if let existing = shared {
            instance = existing
        } else {
            instance = LevelDescriptionWindowController(controller: controller)
            shared = instance
        }
        instance.titleTextField.stringValue = title
        instance.descriptionTextField.stringValue = description
        instance.imageView.image = image
        if app.shell.isFullscreen {
            instance.window.scheduleShieldingLevel()
        }
        NSApp.runModal(for: instance.window)
    }

    /// The window and its controls from `LevelDescription.nib` XML: title, content size and style mask;
    /// `PaperBackgroundView` content (the nib's custom class); outlets `_imageView`, `_titleTextField`,
    /// `_descriptionTextField`, `_checkbox` and the buttons wired to `continue:` / `cancel:` with their nib
    /// frames, titles, fonts and key equivalents. An unreadable nib is fatal, as the original's
    /// `runModalForWindow:nil` would be.
    private init(controller: AkiController) {
        self.controller = controller
        let nib: CocoaNib
        do {
            nib = try CocoaNib(data: controller.assets.lproj("LevelDescription.nib/designable.nib"))
        } catch {
            fatalError("Aki: cannot read LevelDescription.nib: \(error)")
        }
        guard let w = nib.window, let image = nib.control(outlet: "_imageView"),
              let title = nib.control(outlet: "_titleTextField"), let text = nib.control(outlet: "_descriptionTextField"),
              let box = nib.control(outlet: "_checkbox"), let cont = nib.control(action: "continue:"),
              let cancel = nib.control(action: "cancel:")
        else { fatalError("Aki: LevelDescription.nib lacks its window or controls") }

        let size = NSRect(x: 0, y: 0, width: w.contentWidth, height: w.contentHeight)
        window = NSWindow(contentRect: size, styleMask: NSWindow.StyleMask(rawValue: UInt(w.styleMask)),
                          backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        window.title = w.title
        let content = PaperBackgroundView(frame: size, paper: controller.assets.image("paper"))
        window.contentView = content

        imageView = NSImageView(frame: Self.frame(image))
        imageView.imageScaling = .scaleProportionallyDown            // NSScale 0
        imageView.imageAlignment = .alignCenter                      // NSAlign 0
        imageView.imageFrameStyle = .none                            // NSStyle 0
        imageView.isEditable = false

        titleTextField = NSTextField(labelWithString: "")
        Self.style(titleTextField, title)
        descriptionTextField = NSTextField(wrappingLabelWithString: "")
        Self.style(descriptionTextField, text)

        checkbox = NSButton(checkboxWithTitle: box.title ?? "", target: nil, action: nil)
        checkbox.frame = Self.frame(box)
        checkbox.font = Self.font(box)
        checkbox.state = box.isOn ? .on : .off                       // archived OFF (Q5); _setupWithTitle: never sets it

        super.init()

        let continueButton = Self.pushButton(cont, target: self, action: #selector(continueLevel(_:)))
        let cancelButton = Self.pushButton(cancel, target: self, action: #selector(cancel(_:)))
        for view in [imageView, checkbox, continueButton, cancelButton, titleTextField, descriptionTextField] as [NSView] {
            content.addSubview(view)                                 // nib subview order
        }
    }

    /// `-[LevelDescriptionWindowController cancel:]` @ 0x29fcd (DC:11417): g+0x7c = 1, `stopModalWithCode:0`,
    /// the window ordered out.
    @objc func cancel(_ sender: Any?) {
        controller.g.cancelStart = true
        NSApp.stopModal(withCode: NSApplication.ModalResponse(rawValue: 0))
        window.orderOut(nil)
    }

    /// `-[LevelDescriptionWindowController continue:]` @ 0x2a02e (DC:11430): p+0x214 = (checkbox state == 1),
    /// `stopModalWithCode:1`, the window ordered out. (No `_SavePrefs` here.)
    @objc func continueLevel(_ sender: Any?) {
        controller.p.showDescription = checkbox.state == .on ? 1 : 0
        NSApp.stopModal(withCode: NSApplication.ModalResponse(rawValue: 1))
        window.orderOut(nil)
    }

    // MARK: Nib conversion (IB3 frames are already AppKit's, bottom-left)

    private static func frame(_ c: CocoaNib.Control) -> NSRect {
        NSRect(x: c.x, y: c.y, width: c.width, height: c.height)
    }

    private static func font(_ c: CocoaNib.Control) -> NSFont {
        let size = CGFloat(c.fontSize ?? 13)
        return c.fontName.flatMap { NSFont(name: $0, size: size) } ?? .systemFont(ofSize: size)
    }

    /// A nib text field as a non-editable, non-bezelled label in the nib font and `controlTextColor`.
    private static func style(_ field: NSTextField, _ c: CocoaNib.Control) {
        field.frame = frame(c)
        field.font = font(c)
        field.textColor = .controlTextColor
        field.isSelectable = false
    }

    private static func pushButton(_ c: CocoaNib.Control, target: AnyObject, action: Selector) -> NSButton {
        let button = NSButton(title: c.title ?? "", target: target, action: action)
        button.bezelStyle = .push
        button.frame = frame(c)
        button.font = font(c)
        button.keyEquivalent = c.keyEquivalent ?? ""
        return button
    }
}
