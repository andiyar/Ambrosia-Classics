import AppKit
import AkiCore

/// `PaperBackgroundView` — `-[PaperBackgroundView drawRect:]` @ 0x2850e (DC:10856): `[NSImage
/// imageNamed:@"paper"]` drawn whole (`fromRect:` {0, 0, size}) into the rect it is asked to draw,
/// `NSCompositeSourceOver`, fraction 1 — i.e. the 420×338 parchment stretched behind Preferences,
/// Level Description and every Carbon dialog's image view 200. The replica stretches it into `bounds`
/// on every draw (Q7).
@MainActor final class PaperBackgroundView: NSView {
    private let paper: NSImage?

    init(frame: NSRect, paper: NSImage?) {
        self.paper = paper
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("PaperBackgroundView is built in code") }

    override func draw(_ dirtyRect: NSRect) {
        guard let paper else { return }
        paper.draw(in: bounds, from: NSRect(origin: .zero, size: paper.size), operation: .sourceOver, fraction: 1)
    }
}

/// `_CreateNewDialog` @ 0x4ef9 (DC:1642): the Carbon dialogs of `Aki.nib` (`objects.xib`, IB 2.x) rebuilt
/// in AppKit (Research note 20, Q8). The window comes from the nib by name (`_CreateWindowFromNib`; a
/// missing window is `_ExitToShell`), `paper.png` goes into image view 200 (`scaleToFit` → stretched),
/// the window is centred on the display (`centerWithCGDisplaySize`), raised to `CGShieldingWindowLevel()`
/// when fullscreen, and run app-modal (`RunAppModalLoopForWindow`); afterwards the main window is made
/// key again. The event handlers (`_NotOpenEventHandler` @ 0x5c84, DC:1984, and its siblings) quit the
/// loop on a button's HICommand; `'ok  '` also sets `g.dialogOK` (g+0x81).
@MainActor enum CarbonDialog {
    /// Builds `name` from Aki.nib/objects.xib, runs it app-modal; returns the HICommand of the button
    /// that closed it ("ok  ", "not!"). `configure` fills dynamic controls by controlID (Stats, P2.11).
    /// P2.11 semantics (no signature change): `controlsByID` keeps the FIRST control per ID in nib subview
    /// order (GetControlByID); `configure` writes text to static texts only.
    static func run(_ name: String, controller: AkiController,
                    configure: ((_ controlsByID: [Int: NSView]) -> Void)? = nil) -> String? {
        let nibWindow: CarbonNib.Window
        do {
            guard let window = try CarbonNib(data: controller.assets.lproj("Aki.nib/objects.xib")).window(named: name) else {
                fatalError("Aki: Aki.nib has no window \"\(name)\"")       // _CreateWindowFromNib ≠ 0 → _ExitToShell
            }
            nibWindow = window
        } catch {
            fatalError("Aki: cannot read Aki.nib: \(error)")
        }

        let runner = CarbonDialogRunner(controller: controller)
        let panel = CarbonDialogPanel(contentRect: NSRect(x: 0, y: 0, width: nibWindow.width, height: nibWindow.height),
                                      styleMask: [.titled], backing: .buffered, defer: false)
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.title = nibWindow.title
        let content = NSView(frame: NSRect(x: 0, y: 0, width: nibWindow.width, height: nibWindow.height))
        panel.contentView = content

        var controlsByID: [Int: NSView] = [:]
        for control in nibWindow.controls {
            guard let view = makeView(control, windowHeight: nibWindow.height, runner: runner, controller: controller) else {
                continue
            }
            content.addSubview(view)
            if let id = control.controlID, controlsByID[id] == nil {
                controlsByID[id] = view                             // GetControlByID: the first match in nib order
            }
        }
        configure?(controlsByID)

        panel.center()                                              // centerWithCGDisplaySize
        if controller.shell.isFullscreen {
            panel.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
            panel.scheduleShieldingLevel()                          // re-applied inside the modal session
        }
        panel.makeKeyAndOrderFront(nil)
        NSApp.runModal(for: panel)
        panel.orderOut(nil)                                         // HideWindow / DisposeWindow
        controller.shell.currentWindow.makeKeyAndOrderFront(nil)
        return runner.command
    }

    // MARK: Control conversion (Carbon top-left frames → AppKit bottom-left: y = H − y − h)

    /// One Carbon control as an AppKit view: image view 200 → `PaperBackgroundView`; static text → a
    /// wrapping label; push button → `NSButton` inflated by the AppKit push-button insets; icon → the
    /// system alert icon for resID 2 (`kCautionIcon`); separator → a separator box. Other kinds are not
    /// in any dialog this replica opens and are skipped.
    private static func makeView(_ c: CarbonNib.Control, windowHeight: Int, runner: CarbonDialogRunner,
                                 controller: AkiController) -> NSView? {
        let frame = NSRect(x: c.x, y: windowHeight - c.y - c.height, width: c.width, height: c.height)
        switch c.kind {
        case "ImageView":
            // Only view 200 receives paper.png (`HIViewFindByID(root, 200)`); every Aki.nib image view is 200.
            return PaperBackgroundView(frame: frame, paper: c.controlID == 200 ? controller.assets.image("paper") : nil)
        case "StaticText":
            let label = NSTextField(wrappingLabelWithString: c.title ?? "")
            label.frame = frame
            label.isSelectable = false
            label.font = lucidaGrande(controlSize: c.controlSize)
            label.textColor = .controlTextColor
            label.alignment = alignment(c.justification)
            return label
        case "Button":
            let button = NSButton(title: c.title ?? "", target: runner, action: #selector(CarbonDialogRunner.buttonPressed(_:)))
            button.bezelStyle = .push
            button.font = lucidaGrande(controlSize: c.controlSize)
            // Carbon frames are the visible bezel; AppKit push buttons carry 6 px of inset on every side.
            button.frame = frame.insetBy(dx: -6, dy: -6)
            if c.buttonType == 1 {
                button.keyEquivalent = "\r"                         // buttonType 1 = the default button → Return
            } else if c.command == "not!" {
                button.keyEquivalent = "\u{1B}"                     // the 'not!' (cancel) command → Esc
            }
            runner.register(button, command: c.command)
            return button
        case "Icon":
            let icon = NSImageView(frame: frame)
            icon.imageScaling = .scaleProportionallyUpOrDown
            icon.image = c.contentResID == 2 ? NSImage(named: NSImage.cautionName) : nil
            return icon
        case "Separator":
            let box = NSBox(frame: frame)
            box.boxType = .separator
            return box
        default:
            return nil
        }
    }

    /// The nib font: Lucida Grande 13, small (11) when `controlSize` is 1 (Q17; system font fallback).
    static func lucidaGrande(controlSize: Int?) -> NSFont {
        let size: CGFloat = controlSize == 1 ? 11 : 13
        return NSFont(name: "LucidaGrande", size: size) ?? .systemFont(ofSize: size)
    }

    /// TextEdit justification: −1 `teFlushRight`, 1 `teCenter`, 0 `teFlushDefault` / −2 `teFlushLeft` → left.
    private static func alignment(_ justification: Int?) -> NSTextAlignment {
        switch justification {
        case -1: .right
        case 1: .center
        default: .left
        }
    }
}

/// The installed event handler: a button press records its HICommand, sets `g.dialogOK` for `'ok  '`,
/// clears it for `'not!'`, and quits the modal loop (`QuitAppModalLoopForWindow`). The LoadLevel, Warning
/// and Stats handlers clear it on `'not!'` (DC:2083) while Unavailable's only sets it; one rule covers all.
@MainActor private final class CarbonDialogRunner: NSObject {
    private unowned let controller: AkiController
    private var commands: [ObjectIdentifier: String] = [:]
    private(set) var command: String?

    init(controller: AkiController) {
        self.controller = controller
    }

    func register(_ button: NSButton, command: String?) {
        if let command { commands[ObjectIdentifier(button)] = command }
    }

    @objc func buttonPressed(_ sender: NSButton) {
        command = commands[ObjectIdentifier(sender)]
        if command == "ok  " {
            controller.g.dialogOK = true
        } else if command == "not!" {
            controller.g.dialogOK = false                      // DC:2083
        }
        NSApp.stopModal()
    }
}

/// The Carbon dialog window (window class 4, movable modal: title bar, no close box). `center()` is
/// `centerWithCGDisplaySize`: the exact centre of its display, so the centring `runModalForWindow:`
/// performs lands in the same place.
@MainActor private final class CarbonDialogPanel: NSPanel {
    override func center() {
        guard let screen = screen ?? NSScreen.main else { return super.center() }
        let s = screen.frame
        setFrameOrigin(NSPoint(x: (s.midX - frame.width / 2).rounded(.down), y: (s.midY - frame.height / 2).rounded(.down)))
    }
}

extension NSWindow {
    /// `-[NSWindow(AkiAdditions) scheduleSetShieldingLevel]` for every window (dialogs, alerts, splashes,
    /// Preferences): after delay 0 in the modal-panel run-loop mode (i.e. inside the modal session that is
    /// about to start), `centerWithCGDisplaySize` and raise to `CGShieldingWindowLevel()` so the window
    /// shows above the fullscreen window.
    func scheduleShieldingLevel() {
        perform(#selector(applyShieldingLevel), with: nil, afterDelay: 0, inModes: [.modalPanel])
    }

    @objc fileprivate func applyShieldingLevel() {
        centerWithCGDisplaySize()
        level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
    }

    /// `-[NSWindow(AkiAdditions) centerWithCGDisplaySize]`: the exact centre of the window's display (its
    /// 800×600-mode correction is not replicated — Known delta 2). `AkiSplashWindow` overrides it.
    @objc func centerWithCGDisplaySize() {
        guard let screen = screen ?? NSScreen.main else { return }
        let s = screen.frame
        setFrameOrigin(NSPoint(x: (s.midX - frame.width / 2).rounded(.down), y: (s.midY - frame.height / 2).rounded(.down)))
    }
}
