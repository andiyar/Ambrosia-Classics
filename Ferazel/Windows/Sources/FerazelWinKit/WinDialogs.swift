import FerazelCore
import Foundation

/// The original's dialogs on Windows (D43 Ruling 4): DLOG 202 confirm, 200 report / error, 6900 Options, 600 Credits,
/// drawn in-window over the canvas (WF4a: `DialogSystem` draws 202 and 200; WF4b adds Options and Credits). While one
/// is up the flow does not tick (`isShowing`, Ruling 8); the keyboard's keys, the mouse and the pad's Return / Esc go
/// to it. `WinStubDialogs` answers every dialog at once (the tests' default).
@MainActor public protocol WinDialogs: AnyObject {
    /// A dialog waits for the player.
    var isShowing: Bool { get }
    /// Shows `dialog`; `done` is called once with the answer (`GameFlow.dialogDone`) — at once, or when it closes.
    func show(_ dialog: FerazelDialog, done: @escaping (DialogResult) -> Void)
    /// A key-down while `isShowing`.
    func keyDown(_ keyCode: UInt16, modifiers: WinModifiers)
    /// A pad Return / Esc while `isShowing` (the Mac's `padKeyPanel` rule).
    func padKeyDown(_ keyCode: UInt16)

    // WF4a — every one has a do-nothing default (`WinStubDialogs` and the tests' dialogs need none of them).

    /// The game's services, once it is booted (`WinGame.boot`): before that no dialog can be built.
    func attach(_ services: WinDialogServices)
    /// Every loop wake while `isShowing`, with TickCount now: the OK button's 8-tick flash runs on it.
    func tick(now: UInt32)
    /// The mouse in canvas pixels (unclamped: the letterbox lies outside 0..<640 × 0..<480) while `isShowing`.
    func mouseDown(x: Int, y: Int)
    func mouseMoved(x: Int, y: Int)
    func mouseUp(x: Int, y: Int)
    /// Bumped on every visual change of the dialogs on screen (the game presents the picture again when it moves).
    var revision: Int { get }
    /// Draws every dialog on screen, back to front, into a 640×480 R, G, B, A frame (Ruling 4, ◇W10).
    func draw(into rgba: inout [UInt8])
}

extension WinDialogs {
    public func attach(_ services: WinDialogServices) {}
    public func tick(now: UInt32) {}
    public func mouseDown(x: Int, y: Int) {}
    public func mouseMoved(x: Int, y: Int) {}
    public func mouseUp(x: Int, y: Int) {}
    public var revision: Int { 0 }
    public func draw(into rgba: inout [UInt8]) {}
}

/// What the dialogs need from the booted game (WF4a): the resources (the DLOG / DITL / dctb, `.frontEnd` chain), a
/// `PICT` as QuickDraw drew it into a dialog (`FerazelDriver.dialogPicture`: under the screen's current CLUT), `SysBeep`
/// (the driver's: nothing when muted, Ruling 20) and TickCount (the flash's clock).
public struct WinDialogServices {
    public var resources: FerazelResources
    public var picture: (Int16) -> (rgba: [UInt8], width: Int, height: Int)?
    public var beep: () -> Void
    public var ticks: () -> UInt32

    public init(resources: FerazelResources, picture: @escaping (Int16) -> (rgba: [UInt8], width: Int, height: Int)?,
                beep: @escaping () -> Void, ticks: @escaping () -> UInt32) {
        self.resources = resources
        self.picture = picture
        self.beep = beep
        self.ticks = ticks
    }
}

/// Every dialog answers its default at once, without showing (WF3; the tests' default): a confirm Cancel; a report or
/// an error OK; Options Cancel (the prefs unchanged); Credits closed (OK). Never beeps.
@MainActor public final class WinStubDialogs: WinDialogs {
    /// Every dialog asked for, in order.
    public private(set) var shown: [FerazelDialog] = []

    public init() {}

    public var isShowing: Bool { false }

    public func show(_ dialog: FerazelDialog, done: @escaping (DialogResult) -> Void) {
        shown.append(dialog)
        done(Self.answer(dialog))
    }

    /// The stub's answer: Cancel for a confirm and Options, OK for the rest.
    public static func answer(_ dialog: FerazelDialog) -> DialogResult {
        switch dialog {
        case .confirm, .preferences: .cancel
        case .report, .error, .credits: .ok
        }
    }

    public func keyDown(_ keyCode: UInt16, modifiers: WinModifiers) {}
    public func padKeyDown(_ keyCode: UInt16) {}
}
