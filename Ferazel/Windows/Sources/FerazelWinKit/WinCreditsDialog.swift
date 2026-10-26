import FerazelCore
import Foundation

/// DLOG 600, the credits, drawn in the game picture (WF4b, D43 Ruling 4, ◇W10) — the Windows port of the Mac's
/// `CreditsDialog` (`Ferazel/App/Dialogs/CreditsDialog.swift`: `.Credits @ 1000e5b4` → `.DoAboutDialog(600, 0x12c3)
/// @ 1007853c`, M l. 65263–65435) over Core's `CreditsScroll`: `GetNewDialog(600)` (the `dctb` 600 grey), `DrawDialog`
/// (item 1, PICT 4804, the background), then the loop at game ticks: `CopyBits` of the whole PICT 4803 strip into its
/// dest rect under the clip (l 34, t 120, r 170, b 270), the rect moved up 1 px, `Delay(3)`, then `Button()`: down with
/// the pointer inside the port rect → the dialog closes; outside → `SysBeep` (nothing when muted, Ruling 20);
/// `FlushEvents(mDownMask)` swallows the click either way. Nothing erases between copies: the window's pixels persist
/// (`DialogWindow.canvas`). Both pictures as QuickDraw drew them into a dialog: `dialogPicture`, under the screen's
/// current CLUT (the Mac's [LOW]: the original drew the strip into an 8-bit GWorld with the default table first).
///
/// `Button()` is the live button at each 3-tick check: a press released between two checks is missed, as in the
/// original.
@MainActor final class WinCreditsDialog {
    private unowned let system: DialogSystem
    private let services: WinDialogServices
    let dialog: DialogWindow
    private let scroll: CreditsScroll
    private let completion: () -> Void
    private let strip: (rgba: [UInt8], width: Int, height: Int)?
    /// The next step to copy (k = 0 at `scroll.start`).
    private var next = 0
    private var closed = false

    init?(system: DialogSystem, services: WinDialogServices, scroll: CreditsScroll, completion: @escaping () -> Void) {
        guard let d = system.make(CreditsScroll.dialog) else { return nil }
        self.system = system
        self.services = services
        self.scroll = scroll
        self.completion = completion
        dialog = d
        strip = services.picture(CreditsScroll.stripPicture)
        // `DrawDialog`: the content colour, then item 1 (the PICT) — onto the persistent canvas.
        var canvas = DialogRenderer.Image(width: d.template.bounds.width, height: d.template.bounds.height,
                                          fill: d.contentRGB)
        for item in d.items where item.item.kind == .picture {
            if let p = d.pictures[item.number] { DialogRenderer.blit(&canvas, p, into: item.rect) }
        }
        d.canvas = canvas
        d.defaultItem = nil
        d.takesAllClicks = true
        d.nullEvent = { [weak self] in self?.step() }
    }

    func open() {
        system.open(dialog)
        step()
    }

    /// The port rect (`dialog + 0x10`): the content area.
    private var portRect: DialogRect {
        DialogRect(x: 0, y: 0, width: dialog.template.bounds.width, height: dialog.template.bounds.height)
    }

    /// Every copy due by now, each after the button check that follows the previous copy's `Delay(3)`.
    private func step() {
        guard !closed else { return }
        let due = Int(services.ticks() &- scroll.start) / CreditsScroll.ticksPerStep
        var drawn = false
        while next <= due, !closed {
            if next > 0, let at = button() {
                switch scroll.click(insideDialog: portRect.contains(at.x, at.y)) {
                case .close:
                    close()
                    return
                case .beep:
                    system.beep()
                }
            }
            copy(step: next)
            drawn = true
            next += 1
        }
        if drawn { dialog.invalidate() }
    }

    /// `Button()` (then `GetMouse`): where the pointer is while the button is down; nil when up.
    private func button() -> (x: Int, y: Int)? {
        dialog.buttonDown ? dialog.pointer : nil
    }

    /// `CopyBits(strip → dest)` under the clip, 1:1.
    private func copy(step k: Int) {
        guard let strip, var canvas = dialog.canvas else { return }
        dialog.canvas = nil                                            // one owner: written in place
        defer { dialog.canvas = canvas }
        let r = scroll.dest(now: scroll.start &+ UInt32(truncatingIfNeeded: k * CreditsScroll.ticksPerStep))
        let c = scroll.clip
        let x0 = max(Int(c.left), Int(r.left), 0), x1 = min(Int(c.right), Int(r.right), canvas.width)
        let y0 = max(Int(c.top), Int(r.top), 0), y1 = min(Int(c.bottom), Int(r.bottom), canvas.height)
        guard x0 < x1, y0 < y1 else { return }
        for y in y0..<y1 {
            let sy = y - Int(r.top)
            guard sy >= 0, sy < strip.height else { continue }
            for x in x0..<x1 {
                let sx = x - Int(r.left)
                guard sx >= 0, sx < strip.width else { continue }
                let at = 4 * (sy * strip.width + sx)
                canvas[x, y] = UInt32(strip.rgba[at]) << 16 | UInt32(strip.rgba[at + 1]) << 8 | UInt32(strip.rgba[at + 2])
            }
        }
    }

    private func close() {
        closed = true
        dialog.nullEvent = nil
        system.dismiss(dialog)
        completion()
    }
}
