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
/// | `.preferences` | 6900 | WF4b: `WinPrefsDialog` over `GameFlow.prefsDialog` (O1), the Mac's `PrefsDialogView` |
/// | `.credits` | 600 | WF4b: `WinCreditsDialog` over `GameFlow.credits`, the Mac's `CreditsDialog` |
///
/// Modal over the canvas: while one is up the flow does not tick (`isShowing`), every key goes to the front dialog
/// (DLOG 202 / 200: Return / Enter → OK through the 8-tick flash, Esc and the rest do nothing; Options: its filter),
/// a press outside the front dialog's panel — the letterbox included — beeps (`SysBeep` through the driver: nothing
/// when muted, Ruling 20) except over the credits, whose own loop reads the button; the pad's Return / Esc arrive as
/// those keys at a plain message only (the Mac's `padKeyPanel`: never Options or Credits, D37). The front dialog gets
/// a null event once per tick. A DLOG that does not load answers at once (the Mac: a confirm beeps and answers
/// Cancel; a report answers OK; Options answers Cancel; Credits beeps and answers OK).
@MainActor public final class DialogSystem: WinDialogs {
    public let renderer: DialogRenderer
    private var services: WinDialogServices?
    /// Dialogs on screen, front last.
    public private(set) var stack: [DialogWindow] = []
    /// Bumped on every change of the dialogs on screen (opened, closed, redrawn).
    public private(set) var revision = 0
    /// The open Options and Credits controllers (their dialogs' closures hold them weakly).
    private var prefs: WinPrefsDialog?
    private var credits: WinCreditsDialog?
    /// The tick of the last null event.
    private var lastNull: UInt32?
    /// The mouse button, as the event record's `btnState` reads it.
    private var buttonDown = false

    public init(text: BakedTextRasterizer) {
        renderer = DialogRenderer(text: text)
    }

    public func attach(_ services: WinDialogServices) { self.services = services }

    public var isShowing: Bool { !stack.isEmpty }

    func beep() { services?.beep() }
    var now: UInt32 { services?.ticks() ?? 0 }

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
        case .preferences:
            // `.PreferencesDialog` over the flow's model; the answer once its `result` is set (and the dialog gone).
            guard let s = services, s.prefs() != nil,
                  let p = WinPrefsDialog(system: self, services: s, completion: { [weak self] result in
                      self?.prefs = nil
                      done(result)
                  }) else { done(.cancel); return }
            prefs = p
            p.open()
        case .credits:
            // `.DoAboutDialog(600, 4803)` over the flow's scroll (a stale request: one starting now).
            guard let s = services,
                  let c = WinCreditsDialog(system: self, services: s, scroll: s.credits() ?? CreditsScroll(start: now),
                                           completion: { [weak self] in
                                               self?.credits = nil
                                               done(.ok)
                                           }) else { beep(); done(.ok); return }
            credits = c
            c.open()
        }
    }

    /// `.GenericMessage(1)` after `.ReportDialog` (`code` nil, `^1` empty) or `.ReportError` (`^1` = the code).
    func report(_ text: String, code: Int16?, done: @escaping (DialogResult) -> Void) {
        guard let d = make(200, params: [text, code.map { String($0) } ?? ""]) else { done(.ok); return }
        d.outlineDefault(1)
        d.itemHit = { [unowned self, unowned d] item in
            guard item == 1 else { return }
            dismiss(d)
            done(.ok)
        }
        open(d)
    }

    func make(_ id: Int16, params: [String] = []) -> DialogWindow? {
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

    func open(_ d: DialogWindow) {
        let f = d.frame
        (d.originX, d.originY) = Self.origin(width: f.width, height: f.height)
        d.measure = { [unowned self] in renderer.width($0) }
        d.onChange = { [unowned self] in revision &+= 1 }
        stack.append(d)
        revision &+= 1
    }

    /// `DisposeDialog(d)` and anything in front of it.
    func dismiss(_ d: DialogWindow) {
        guard let i = stack.firstIndex(where: { $0 === d }) else { return }
        for w in stack[i...] { w.onChange = nil }
        stack.removeSubrange(i...)
        revision &+= 1
    }

    // MARK: Events

    public func keyDown(_ keyCode: UInt16, modifiers: WinModifiers) {
        keyDown(keyCode, modifiers: modifiers, isRepeat: false)
    }

    /// A key-down as the event record (character code, key code, modifiers word, auto-key) to the front dialog.
    public func keyDown(_ keyCode: UInt16, modifiers: WinModifiers, isRepeat: Bool) {
        let key = DialogKeyEvent(char: DialogWindow.charCode(keyCode: keyCode, shift: modifiers.contains(.shift)),
                                 keyCode: Int(keyCode),
                                 modifiers: DialogKeyEvent.modifiers(modifiers, buttonDown: buttonDown),
                                 isRepeat: isRepeat)
        stack.last?.handleKey(key, now: now)
    }

    /// The pad's Return / Esc: a key-down with no modifiers posted to the front panel (the Mac's synthesized events)
    /// — only when it is a plain message (`padKeyPanel`: Options and Credits stay mouse / keyboard, D37).
    public func padKeyDown(_ keyCode: UInt16) {
        guard stack.last?.takesPadKeys == true else { return }
        keyDown(keyCode, modifiers: [])
    }

    /// Every wake: the flash's clock, then — once per new tick — the front dialog's null event (the Mac's 1/60 s
    /// timer: Options' modifier capture and caret, the credits' scroll); none while a popup menu is open
    /// (`PopUpMenuSelect` tracks modally in the original).
    public func tick(now: UInt32) {
        stack.last?.tick(now: now)
        guard now != lastNull, stack.last?.menu == nil else { return }
        lastNull = now
        stack.last?.nullEvent?()
    }

    /// A press: over the credits it is their loop's (`Button()`); inside the front dialog's panel or its open menu it
    /// is the dialog's (eaten while it flashes); anywhere else it beeps (an app-modal `ModalDialog`).
    public func mouseDown(x: Int, y: Int) {
        buttonDown = true
        guard let front = stack.last else { return }
        if front.takesAllClicks {
            front.pointer = (x - front.contentX, y - front.contentY)
            front.buttonDown = true
            return
        }
        guard front.containsCanvas(x, y) else { beep(); return }
        front.mouseDown(x - front.contentX, y - front.contentY)
    }

    public func mouseMoved(x: Int, y: Int) {
        guard let front = stack.last else { return }
        if front.takesAllClicks {
            front.pointer = (x - front.contentX, y - front.contentY)
            return
        }
        front.mouseMoved(x - front.contentX, y - front.contentY)
    }

    public func mouseUp(x: Int, y: Int) {
        buttonDown = false
        guard let front = stack.last else { return }
        if front.takesAllClicks {
            front.pointer = (x - front.contentX, y - front.contentY)
            front.buttonDown = false
            return
        }
        front.mouseUp(x - front.contentX, y - front.contentY)
    }

    public func draw(into rgba: inout [UInt8]) {
        for d in stack { renderer.composite(d, into: &rgba) }
    }
}
