import FerazelCore
import Foundation

/// The original's dialogs on Windows (D43 Ruling 4): DLOG 202 confirm, 200 report / error, 6900 Options, 600 Credits,
/// to be drawn in-window over the canvas (WF4a, WF4b). While one is up the flow does not tick (`isShowing`, Ruling 8);
/// the keyboard's keys and the pad's Return / Esc go to it. WF3 ships only `WinStubDialogs`.
@MainActor public protocol WinDialogs: AnyObject {
    /// A dialog waits for the player.
    var isShowing: Bool { get }
    /// Shows `dialog`; `done` is called once with the answer (`GameFlow.dialogDone`) — at once, or when it closes.
    func show(_ dialog: FerazelDialog, done: @escaping (DialogResult) -> Void)
    /// A key-down while `isShowing`.
    func keyDown(_ keyCode: UInt16, modifiers: WinModifiers)
    /// A pad Return / Esc while `isShowing` (the Mac's `padKeyPanel` rule).
    func padKeyDown(_ keyCode: UInt16)
}

/// Every dialog answers its default at once, without showing (WF3, and the `--frames` runs): a confirm Cancel; a
/// report or an error OK; Options Cancel (the prefs unchanged); Credits closed (OK). Never beeps.
@MainActor public final class WinStubDialogs: WinDialogs {
    /// Every dialog asked for, in order.
    public private(set) var shown: [FerazelDialog] = []

    public init() {}

    public var isShowing: Bool { false }

    public func show(_ dialog: FerazelDialog, done: @escaping (DialogResult) -> Void) {
        shown.append(dialog)
        switch dialog {
        case .confirm, .preferences: done(.cancel)
        case .report, .error, .credits: done(.ok)
        }
    }

    public func keyDown(_ keyCode: UInt16, modifiers: WinModifiers) {}
    public func padKeyDown(_ keyCode: UInt16) {}
}
