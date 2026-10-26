import FerazelCore
import Foundation

/// The original's Dialog Manager windows drawn inside the game picture (WF4a, D43 Ruling 4) — the Windows port of the
/// Mac's `FerazelDialogs` (`Ferazel/App/Dialogs/FerazelDialogs.swift`, its table is the spec), adapted from BTX's
/// `BTXWinKit/DialogSystem.swift` (BTX's package untouched), answered into `GameFlow.dialogDone` by `WinGame`:
///
/// | request | DLOG | behaviour (the Mac's) |
/// |---|---|---|
/// | `.confirm(text)` | 202 | `ParamText(^0 = text)`; ring round OK; until item 1 (OK → `.ok`) or 2 (Cancel → `.cancel`) |
/// | `.report(text)` | 200 | `ParamText(^0 = text, ^1 = "")`; ring round OK; until item 1 |
/// | `.error(text, code)` | 200 | the same with `^1 = NumToString(code)` |
/// | `.preferences`, `.credits` | 6900, 600 | WF4b: answered at once as `WinStubDialogs` does (Cancel / OK) |
///
/// Modal over the canvas: while one is up the flow does not tick (`isShowing`), every key goes to the front dialog
/// (Return / Enter → OK through the 8-tick flash; Esc and the rest do nothing), a press outside the front dialog's
/// panel — the letterbox included — beeps (`SysBeep` through the driver: nothing when muted, Ruling 20), the pad's
/// Return / Esc arrive as those keys (the Mac's `padKeyPanel`). A DLOG that does not load answers at once (the Mac:
/// a confirm beeps and answers Cancel; a report answers OK).
@MainActor public final class DialogSystem: WinDialogs {
    public let renderer: DialogRenderer
    private var services: WinDialogServices?
    /// Dialogs on screen, front last.
    public private(set) var stack: [DialogWindow] = []
    /// Bumped on every change of the dialogs on screen (opened, closed, redrawn).
    public private(set) var revision = 0

    public init(text: BakedTextRasterizer) {
        renderer = DialogRenderer(text: text)
    }

    public func attach(_ services: WinDialogServices) { self.services = services }

    public var isShowing: Bool { !stack.isEmpty }

    private func beep() { services?.beep() }
    private var now: UInt32 { services?.ticks() ?? 0 }

    // MARK: Requests

    public func show(_ dialog: FerazelDialog, done: @escaping (DialogResult) -> Void) {
        switch dialog {
        case .confirm(let text):
            guard let d = make(202, params: [text]) else { beep(); done(.cancel); return }
            d.outlineDefault(1)
            d.itemHit = { [unowned self, unowned d] item in
                guard item == 1 || item == 2 else { return }
                dismiss(d)
                done(item == 1 ? .ok : .cancel)
            }
            open(d)
        case .report(let text):
            report(text, code: nil, done: done)
        case .error(let text, let code):
            report(text, code: code, done: done)
        case .preferences, .credits:
            done(WinStubDialogs.answer(dialog))     // WF4b
        }
    }

    /// `.GenericMessage(1)` after `.ReportDialog` (`code` nil, `^1` empty) or `.ReportError` (`^1` = the code).
    private func report(_ text: String, code: Int16?, done: @escaping (DialogResult) -> Void) {
        guard let d = make(200, params: [text, code.map { String($0) } ?? ""]) else { done(.ok); return }
        d.outlineDefault(1)
        d.itemHit = { [unowned self, unowned d] item in
            guard item == 1 else { return }
            dismiss(d)
            done(.ok)
        }
        open(d)
    }

    private func make(_ id: Int16, params: [String]) -> DialogWindow? {
        guard let s = services else { return nil }
        return DialogWindow(dialog: id, resources: s.resources, picture: s.picture, params: params)
    }

    // MARK: The modal stack

    /// The DLOGs' position word 0x280A (`kWindowCenterMainScreen`): centred on the 640×480 screen, as the Mac's
    /// `show(over:)` centres the panel on the game image — x rounded, and the bottom-up y rounded (so an odd free
    /// height leaves the extra pixel above).
    static func origin(width: Int, height: Int) -> (x: Int, y: Int) {
        let x = (Double(WinCanvas.width) / 2 - Double(width) / 2).rounded()
        let bottom = (Double(WinCanvas.height) / 2 - Double(height) / 2).rounded()
        return (Int(x), WinCanvas.height - Int(bottom) - height)
    }

    private func open(_ d: DialogWindow) {
        let f = d.frame
        (d.originX, d.originY) = Self.origin(width: f.width, height: f.height)
        d.onChange = { [unowned self] in revision &+= 1 }
        stack.append(d)
        revision &+= 1
    }

    /// `DisposeDialog(d)` and anything in front of it.
    private func dismiss(_ d: DialogWindow) {
        guard let i = stack.firstIndex(where: { $0 === d }) else { return }
        for w in stack[i...] { w.onChange = nil }
        stack.removeSubrange(i...)
        revision &+= 1
    }

    // MARK: Events

    public func keyDown(_ keyCode: UInt16, modifiers: WinModifiers) {
        stack.last?.handleKey(char: DialogWindow.charCode(keyCode: keyCode), command: modifiers.contains(.command),
                              now: now)
    }

    /// The pad's Return / Esc: a key-down with no modifiers posted to the front panel (the Mac's synthesized events).
    public func padKeyDown(_ keyCode: UInt16) { keyDown(keyCode, modifiers: []) }

    public func tick(now: UInt32) { stack.last?.tick(now: now) }

    /// A press: inside the front dialog's panel it is the dialog's (eaten while it flashes); anywhere else it beeps
    /// (an app-modal `ModalDialog`).
    public func mouseDown(x: Int, y: Int) {
        guard let front = stack.last else { return }
        guard front.frame.contains(x, y) else { beep(); return }
        front.mouseDown(x - front.contentX, y - front.contentY)
    }

    public func mouseMoved(x: Int, y: Int) {
        guard let front = stack.last else { return }
        front.mouseMoved(x - front.contentX, y - front.contentY)
    }

    public func mouseUp(x: Int, y: Int) {
        guard let front = stack.last else { return }
        front.mouseUp(x - front.contentX, y - front.contentY)
    }

    public func draw(into rgba: inout [UInt8]) {
        for d in stack { renderer.composite(d, into: &rgba) }
    }
}
