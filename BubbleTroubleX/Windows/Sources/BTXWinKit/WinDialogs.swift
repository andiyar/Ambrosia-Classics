import BubbleTroubleCore
import BubbleTroubleRender
import Foundation

/// The original's dialogs as `WinGameDriver` drives them (W4.5): `DialogSystem` (W6, drawn in-window from the original
/// `DLOG`/`DITL`) is the implementation; `WinAutoDialogs` is the scripted policy that answers at once.
///
/// Host contract (`DialogSystem`'s): while `isShowing` every key and mouse event goes here (canvas coordinates — the
/// 640×480 game screen's; the menu strip above it is negative y), `tick(heldKeys:)` runs once per 1/60 s, and `draw`
/// paints after the game frame. While `isModal` the game clocks stop. Answers go to the front end through
/// `DialogSystem.deliver(_:to:)`; the calls back into the game while a dialog is up go to `delegate`.
public protocol WinDialogs: AnyObject {
    /// Set by the driver before any request (held weakly).
    var delegate: DialogSystemDelegate? { get set }
    /// A dialog is on screen (the menu bar is disabled then — Carbon `ModalDialog` is app-modal).
    var isShowing: Bool { get }
    /// A dialog waits for the user: the driver's clocks stop.
    var isModal: Bool { get }
    /// The front dialog has an edit field with the keyboard focus: the host turns layout-aware text input on.
    var wantsTextInput: Bool { get }
    /// Changes whenever what `draw` paints may have changed (the driver re-presents then).
    var drawKey: Int { get }
    /// Shows the dialog `request` asks for (`.highScoreNameDialog`, `.levelSelectDialog`, `.prefsDialog`,
    /// `.hiScoreEraseDialog`, `.modalDialog`); `completion` gets the answer, possibly before this returns. False for a
    /// request that is not a dialog.
    @discardableResult
    func present(_ request: ShellRequest, prefs: BTXPrefs, completion: @escaping (DialogSystem.Answer) -> Void) -> Bool
    /// `.closeDialog`: dispose DLOG 160 after the front end's hold.
    func close()
    func mouseDown(x: Int, y: Int)
    func mouseMoved(x: Int, y: Int)
    func mouseUp(x: Int, y: Int)
    func keyDown(_ event: DialogKeyEvent)
    func tick(heldKeys: Set<UInt16>)
    func draw(into image: inout RGBAImage, canvasX: Int, canvasY: Int)
}

extension DialogSystem: WinDialogs {
    public var wantsTextInput: Bool {
        guard let front = frontDialog, let n = front.focusedEditItem else { return false }
        return !front.isHidden(n) && front.isActive(n)
    }

    public var drawKey: Int {
        var h = Hasher()
        for d in stack {
            h.combine(ObjectIdentifier(d))
            h.combine(d.revision)
            h.combine(d.caretVisible)
        }
        return h.finalize()
    }
}

/// The scripted dialog policy (W4's stand-in, kept for runs that must not stop at a dialog): every dialog answers at
/// once with its default — Cancel (level select, high-score erase), the prefs unchanged, the default name (the
/// registered name, "Player" in a headless run), dismissed — and nothing is ever on screen. Records what it was asked.
public final class WinAutoDialogs: WinDialogs {
    public weak var delegate: DialogSystemDelegate?
    public private(set) var requests: [ShellRequest] = []
    public private(set) var closes = 0

    public init() {}

    public var isShowing: Bool { false }
    public var isModal: Bool { false }
    public var wantsTextInput: Bool { false }
    public var drawKey: Int { 0 }

    @discardableResult
    public func present(_ request: ShellRequest, prefs: BTXPrefs,
                        completion: @escaping (DialogSystem.Answer) -> Void) -> Bool {
        switch request {
        case .levelSelectDialog, .highScoreNameDialog, .hiScoreEraseDialog, .prefsDialog, .modalDialog:
            requests.append(request)
        default:
            return false
        }
        switch request {
        case .levelSelectDialog: completion(.levelSelect(typed: nil))
        case .highScoreNameDialog(let name): completion(.highScoreName(name))
        case .hiScoreEraseDialog: completion(.hiScoreErase(reset: false))
        case .prefsDialog: completion(.prefs(prefs))
        default: completion(.dismissed)
        }
        return true
    }

    public func close() { closes += 1 }
    public func mouseDown(x: Int, y: Int) {}
    public func mouseMoved(x: Int, y: Int) {}
    public func mouseUp(x: Int, y: Int) {}
    public func keyDown(_ event: DialogKeyEvent) {}
    public func tick(heldKeys: Set<UInt16>) {}
    public func draw(into image: inout RGBAImage, canvasX: Int, canvasY: Int) {}
}
