import AppKit
import FerazelCore
import HectorShell

/// DLOG 600, the credits — `.Credits @ 1000e5b4` → `.DoAboutDialog(600, 0x12c3) @ 1007853c` (M l. 65263–65435) over
/// Core's `CreditsScroll`: `GetNewDialog(600)` (the `dctb` 600 grey), `ShowWindow`, `DrawDialog` (item 1, PICT 4804, the
/// background at (0, 0)–(200, 276)), then the loop: `CopyBits` of the whole PICT 4803 strip into its dest rect under the
/// clip (l 34, t 120, r 170, b 270), the rect moved up 1 px, `Delay(3)`, then `Button()`: down with the pointer inside
/// the port rect → the dialog closes; outside → `SysBeep`; `FlushEvents(mDownMask)` swallows the click either way. After
/// `stripHeight + 150` steps the rect goes back to the start. Nothing erases between copies: what a copy leaves outside
/// the next one stays on the window (a persistent canvas here).
///
/// Approximate [LOW]: the strip is converted straight under the screen CLUT (the original drew it into an 8-bit GWorld
/// with the default colour table first, then `CopyBits` to the window under the screen CLUT).
@MainActor final class CreditsDialog {
    private unowned let dialogs: FerazelDialogs
    private let dialog: FerazelCarbonDialog
    private let scroll: CreditsScroll
    private let completion: () -> Void
    private let canvas: CreditsCanvas
    private let strip: CGImage?
    /// The next step to copy (k = 0 at `scroll.start`).
    private var next = 0
    private var closed = false

    init?(dialogs: FerazelDialogs, scroll: CreditsScroll, completion: @escaping () -> Void) {
        guard let d = dialogs.make(CreditsScroll.dialog) else { return nil }
        self.dialogs = dialogs
        dialog = d
        self.scroll = scroll
        self.completion = completion
        strip = dialogs.picture(CreditsScroll.stripPicture)
        let size = d.content.bounds.size
        canvas = CreditsCanvas(frame: NSRect(origin: .zero, size: size))
        // `DrawDialog`: the content colour, then item 1 (the PICT) — onto the persistent canvas, the items' own views
        // hidden.
        canvas.paint { cg in
            cg.setFillColor(d.root.content.cgColor)
            cg.fill(CGRect(origin: .zero, size: size))
            for item in d.items {
                if case .picture = item.item.kind, let id = item.item.resourceID, let image = dialogs.picture(id) {
                    Self.draw(image, in: item.rect, cg)
                }
                d.view(item.number)?.isHidden = true
            }
        }
        d.content.addSubview(canvas)
        d.defaultItem = nil
        d.takesAllClicks = true
        d.nullEvent = { [weak self] in self?.step() }
    }

    func open() {
        dialogs.open(dialog)
        step()
    }

    /// Draws `image` into `rect` (flipped, top-left origin) unsmoothed.
    static func draw(_ image: CGImage, in rect: CGRect, _ cg: CGContext) {
        cg.saveGState()
        cg.interpolationQuality = .none
        cg.translateBy(x: rect.minX, y: rect.maxY)
        cg.scaleBy(x: 1, y: -1)
        cg.draw(image, in: CGRect(origin: .zero, size: rect.size))
        cg.restoreGState()
    }

    /// Every copy due by now, each after the button check that follows the previous copy's `Delay(3)`.
    private func step() {
        guard !closed else { return }
        let due = Int(ShellClock.ticks() &- scroll.start) / CreditsScroll.ticksPerStep
        var drawn = false
        while next <= due, !closed {
            if next > 0, NSEvent.pressedMouseButtons & 1 != 0 {
                if dialog.portRect.contains(dialog.mouseLocation) {
                    close()
                    return
                }
                NSSound.beep()
            }
            copy(step: next)
            drawn = true
            next += 1
        }
        if drawn { canvas.needsDisplay = true }
    }

    /// `CopyBits(strip → dest)` under the clip.
    private func copy(step k: Int) {
        guard let strip else { return }
        let r = scroll.dest(now: scroll.start &+ UInt32(truncatingIfNeeded: k * CreditsScroll.ticksPerStep))
        let c = scroll.clip
        canvas.paint { cg in
            cg.saveGState()
            cg.clip(to: CGRect(x: CGFloat(c.left), y: CGFloat(c.top), width: CGFloat(Int(c.right) - Int(c.left)),
                               height: CGFloat(Int(c.bottom) - Int(c.top))))
            Self.draw(strip, in: CGRect(x: CGFloat(r.left), y: CGFloat(r.top), width: CGFloat(Int(r.right) - Int(r.left)),
                                        height: CGFloat(Int(r.bottom) - Int(r.top))), cg)
            cg.restoreGState()
        }
    }

    private func close() {
        closed = true
        dialogs.dismiss(dialog)
        completion()
    }
}

/// The credits window's pixels, kept between copies (1 px = 1 point, top-left origin).
final class CreditsCanvas: NSView {
    private let context: CGContext?
    override var isFlipped: Bool { true }

    override init(frame: NSRect) {
        let w = max(1, Int(frame.width)), h = max(1, Int(frame.height))
        context = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        // Top-left origin, y down — as the dialog's port.
        context?.translateBy(x: 0, y: CGFloat(h))
        context?.scaleBy(x: 1, y: -1)
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    func paint(_ body: (CGContext) -> Void) {
        guard let context else { return }
        body(context)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let image = context?.makeImage(), let cg = NSGraphicsContext.current?.cgContext else { return }
        CreditsDialog.draw(image, in: bounds, cg)
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
