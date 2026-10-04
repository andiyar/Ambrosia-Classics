import AkiCore
import UIKit

/// The layer above the canvas (a subview of the shell view, filling it): the Give Up X and every modal
/// overlay. Touches on the layer itself fall through to the shell view; its layout pass places the X and
/// the overlays against `imageRectInPoints` after the shell view has laid out its canvas.
@MainActor final class AkiChromeView: UIView {
    var onLayout: (() -> Void)?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit === self ? nil : hit
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        setNeedsLayout()
    }

    /// The overlays, bottom to top.
    var overlays: [AkiOverlay] { subviews.compactMap { $0 as? AkiOverlay } }
}

/// One modal overlay (plan C4): a backdrop over the whole screen that swallows every touch and key, holding
/// `panel` — built at its LOGICAL size (nib points) — scaled by the canvas's point scale (k / displayScale)
/// and centred on the canvas. While up it is the first responder, so its key commands (Return, Esc) are
/// the only keys that act. `close()` removes it and calls `onClose` exactly once.
@MainActor class AkiOverlay: UIView {
    let panel: UIView
    let logicalSize: CGSize
    /// Set by the host: its modal bookkeeping, then the modal's completion.
    var onClose: (() -> Void)?
    private var closed = false

    init(panel: UIView, logicalSize: CGSize, shadow: Bool = true) {
        self.panel = panel
        self.logicalSize = logicalSize
        super.init(frame: .zero)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
        if shadow {
            panel.layer.shadowColor = UIColor.black.cgColor
            panel.layer.shadowOpacity = 0.5
            panel.layer.shadowRadius = 8
            panel.layer.shadowOffset = CGSize(width: 0, height: 4)
        }
        addSubview(panel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("AkiOverlay is built in code") }

    /// Fills `bounds`; the panel at the canvas scale, centred on `canvas`, its origin on a device pixel.
    func place(in bounds: CGRect, canvas: CGRect, logicalCanvasWidth: Int, displayScale: CGFloat) {
        frame = bounds
        let s = canvas.width / CGFloat(logicalCanvasWidth)
        let w = logicalSize.width * s, h = logicalSize.height * s
        let x = ((canvas.midX - w / 2) * displayScale).rounded(.down) / displayScale
        let y = ((canvas.midY - h / 2) * displayScale).rounded(.down) / displayScale
        panel.transform = .identity
        panel.bounds = CGRect(origin: .zero, size: logicalSize)
        panel.transform = CGAffineTransform(scaleX: s, y: s)
        panel.center = CGPoint(x: x + w / 2, y: y + h / 2)
        Self.setContentScale(panel, displayScale * s)
        panel.layer.shadowPath = UIBezierPath(rect: panel.bounds).cgPath
    }

    /// Text and drawn controls render at the scaled size's pixel density (crisp under the transform).
    private static func setContentScale(_ view: UIView, _ scale: CGFloat) {
        if !(view is UIImageView) { view.contentScaleFactor = scale }
        for sub in view.subviews { setContentScale(sub, scale) }
    }

    /// A shared overlay shown again (Level Description, Preferences): it may close once more.
    func prepareToShow() {
        closed = false
    }

    func close() {
        guard !closed else { return }
        closed = true
        removeFromSuperview()
        let onClose = onClose
        self.onClose = nil
        onClose?()
    }

    /// Whether this overlay is the topmost one (a lower one waits — the Mac's nested modal sessions).
    var isTopOverlay: Bool {
        (superview as? AkiChromeView)?.overlays.last === self
    }

    // A touch anywhere outside the panel's controls lands here: swallowed (subclasses may act on it).
    func backdropTouched() {}
    // A key that no key command took: swallowed (subclasses may act on it).
    func keyPressed() {}

    override var canBecomeFirstResponder: Bool { true }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { backdropTouched() }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { !($0.key?.characters.isEmpty ?? true) }) { keyPressed() }
    }
    override func pressesChanged(_ presses: Set<UIPress>, with event: UIPressesEvent?) {}
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {}
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {}
}

// MARK: - Carbon dialogs

/// `_CreateNewDialog` @ 0x4ef9 (DC:1642) on iPad: the Carbon window `name` of `Aki.nib/objects.xib` as an
/// overlay — a title bar with the window title over the nib's `width × height` content, the controls at
/// their (top-left) nib frames: `paper.png` stretched into image view 200, wrapping static texts (system
/// font 13, 11 for controlSize 1 — Lucida Grande is not on iPadOS), Aqua push buttons, the caution glyph
/// for icon resID 2, separators; the pictures are skipped as on the Mac. The default button (buttonType 1)
/// answers Return, the `not!` button Esc (D6). A press records the HICommand; `'ok  '` sets `g.dialogOK`,
/// `'not!'` clears it (DC:2083) — then the overlay closes and `onCommand` gets the command.
@MainActor final class CarbonDialogOverlay: AkiOverlay {
    private unowned let controller: AkiController
    private var commands: [ObjectIdentifier: String] = [:]
    private var defaultButton: AquaButton?
    private var cancelButton: AquaButton?
    private(set) var command: String?

    init(window: CarbonNib.Window, texts: [Int: String], controller: AkiController) {
        self.controller = controller
        let width = CGFloat(window.width), height = CGFloat(window.height)
        let panel = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height + AquaTitleBar.height))
        panel.backgroundColor = UIColor(white: 0.93, alpha: 1)
        panel.addSubview(AquaTitleBar(width: width, title: window.title))
        let content = UIView(frame: CGRect(x: 0, y: AquaTitleBar.height, width: width, height: height))
        content.clipsToBounds = true
        panel.addSubview(content)
        super.init(panel: panel, logicalSize: panel.bounds.size)

        var controlsByID: [Int: UIView] = [:]
        for control in window.controls {
            guard let view = makeView(control) else { continue }
            content.addSubview(view)
            if let id = control.controlID, controlsByID[id] == nil {
                controlsByID[id] = view                             // GetControlByID: the first match in nib order
            }
        }
        for (id, text) in texts {
            (controlsByID[id] as? TopAlignedLabel)?.text = text    // only static texts take text
        }
    }

    private func makeView(_ c: CarbonNib.Control) -> UIView? {
        let frame = CGRect(x: c.x, y: c.y, width: c.width, height: c.height)
        switch c.kind {
        case "ImageView":
            return PaperView(frame: frame, paper: c.controlID == 200 ? controller.assets.image("paper") : nil)
        case "StaticText":
            let label = TopAlignedLabel(frame: frame)
            label.text = c.title ?? ""
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            label.font = Self.font(controlSize: c.controlSize)
            label.textColor = AquaStyle.text
            label.textAlignment = Self.alignment(c.justification)
            return label
        case "Button":
            let isDefault = c.buttonType == 1
            let button = AquaButton(frame: frame, title: c.title ?? "", font: Self.font(controlSize: c.controlSize),
                                    isDefault: isDefault)
            button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
            if let command = c.command { commands[ObjectIdentifier(button)] = command }
            if isDefault {
                defaultButton = button                              // buttonType 1 = the default button → Return
            } else if c.command == "not!" {
                cancelButton = button                               // the 'not!' (cancel) command → Esc
            }
            return button
        case "Icon":
            let icon = UIImageView(frame: frame)
            icon.contentMode = .scaleAspectFit
            if c.contentResID == 2 {                                // kCautionIcon
                icon.image = UIImage(systemName: "exclamationmark.triangle.fill",
                                     withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.black, .systemYellow]))
            }
            return icon
        case "Separator":
            let line = UIView(frame: CGRect(x: frame.minX, y: frame.midY.rounded(.down), width: frame.width, height: 1))
            line.backgroundColor = UIColor(white: 0.6, alpha: 1)
            return line
        default:
            return nil                                              // the pictures (PICT 315 is not shipped)
        }
    }

    /// The nib font: Lucida Grande 13, small (11) when `controlSize` is 1 — the system font on iPad.
    private static func font(controlSize: Int?) -> UIFont {
        .systemFont(ofSize: controlSize == 1 ? 11 : 13)
    }

    /// TextEdit justification: −1 `teFlushRight`, 1 `teCenter`, else left.
    private static func alignment(_ justification: Int?) -> NSTextAlignment {
        switch justification {
        case -1: .right
        case 1: .center
        default: .left
        }
    }

    override var keyCommands: [UIKeyCommand]? {
        var result: [UIKeyCommand] = []
        if defaultButton != nil {
            result.append(UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(returnKey)))
        }
        if cancelButton != nil {
            result.append(UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(escapeKey)))
        }
        for command in result { command.wantsPriorityOverSystemBehavior = true }
        return result
    }

    @objc private func returnKey() {
        if let defaultButton { buttonPressed(defaultButton) }
    }

    @objc private func escapeKey() {
        if let cancelButton { buttonPressed(cancelButton) }
    }

    @objc private func buttonPressed(_ sender: AquaButton) {
        guard isTopOverlay else { return }
        command = commands[ObjectIdentifier(sender)]
        if command == "ok  " {
            controller.g.dialogOK = true
        } else if command == "not!" {
            controller.g.dialogOK = false                          // DC:2083
        }
        close()
    }
}

// MARK: - Splashes

/// `_ShowSplashScreenWithImage(image, timeout)` on iPad: the image centred on the canvas at the canvas
/// scale (nearest-neighbour, like the canvas), with the splash window's shadow; a tap or a key closes it,
/// and so does `timeout` seconds (0 = never) — the timeout waits while another overlay is above it.
@MainActor final class SplashOverlay: AkiOverlay {
    private var timer: Timer?

    init(image: UIImage, timeout: Int) {
        let view = UIImageView(image: image)
        view.layer.magnificationFilter = .nearest
        view.layer.minificationFilter = .nearest
        super.init(panel: view, logicalSize: image.size)
        if timeout > 0 {
            schedule(after: TimeInterval(timeout))
        }
    }

    private func schedule(after interval: TimeInterval) {
        timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(timeoutFired),
                                     userInfo: nil, repeats: false)
    }

    /// The timeout: closes the splash, or — while another overlay is above it — checks again shortly.
    @objc private func timeoutFired() {
        timer = nil
        guard superview != nil else { return }
        if isTopOverlay {
            done()
        } else {
            schedule(after: 0.25)
        }
    }

    override func backdropTouched() { done() }
    override func keyPressed() { done() }

    /// `-[AkiSplashWindow _done]`: invalidate the timeout, close.
    private func done() {
        guard isTopOverlay else { return }
        timer?.invalidate()
        timer = nil
        close()
    }
}
