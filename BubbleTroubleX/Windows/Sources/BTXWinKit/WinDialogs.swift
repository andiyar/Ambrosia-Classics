import BubbleTroubleCore
import Foundation

/// What a dialog answered (the Mac's `BTXDialogs.Answer`); `deliver(to:)` hands it to the front end.
public enum WinDialogAnswer: Equatable, Sendable {
    /// DLOG 160: the number in the field on OK, nil for Cancel.
    case levelSelect(typed: Int?)
    /// DLOG 1000: the field's text on OK.
    case highScoreName(String)
    /// DLOG 1001: Reset (true) or Cancel.
    case hiScoreErase(reset: Bool)
    /// DLOG 190: the prefs after Save, or as they were at open after Cancel.
    case prefs(BTXPrefs)
    /// DLOG 290 / 291 / 3000 / 3001 dismissed.
    case dismissed

    /// `BTXDialogs.deliver(_:to:)`.
    public func deliver(to frontEnd: FrontEnd) -> SessionOutput {
        switch self {
        case .levelSelect(let typed): frontEnd.levelSelectDone(typed: typed)
        case .highScoreName(let name): frontEnd.highScoreNameEntered(name)
        case .hiScoreErase(let reset): frontEnd.hiScoreEraseDone(reset: reset)
        case .prefs(let p): frontEnd.prefsDialogDone(prefs: p)
        case .dismissed: frontEnd.dialogDone()
        }
    }
}

/// The calls a dialog makes back into the game while it is up (the Mac's `BTXDialogs` closures).
public struct WinDialogHooks {
    /// `_PlayMySnd` from inside a dialog; the `Int?` stands in for short 0x33 on this one play.
    public var playSound: (SoundCue, Int?) -> Void = { _, _ in }
    /// The edited prefs, live (prefs dialog); the flag = the original called `_UpdateMusicVolume` here.
    public var livePrefs: (BTXPrefs, Bool) -> Void = { _, _ in }
    /// `isShowing` / `isModal` may have changed: the driver stops / restarts its clocks.
    public var modalStateChanged: () -> Void = {}

    public init() {}
}

/// The original's dialogs (`DLOG`/`DITL`), drawn in-window — W6 implements it; W4 ships `WinDialogsStub`.
public protocol WinDialogs: AnyObject {
    /// Set by the driver before any request.
    var hooks: WinDialogHooks { get set }
    /// A dialog is on screen (the menu bar is disabled then).
    var isShowing: Bool { get }
    /// A dialog waits for the user: the driver's clocks stop.
    var isModal: Bool { get }
    /// Shows the dialog `request` asks for (`.highScoreNameDialog`, `.levelSelectDialog`, `.prefsDialog`,
    /// `.hiScoreEraseDialog`, `.modalDialog`); `completion` gets the answer, possibly before this returns.
    func present(_ request: ShellRequest, prefs: BTXPrefs, completion: @escaping (WinDialogAnswer) -> Void)
    /// `.closeDialog`: dispose DLOG 160 after the front end's hold.
    func close()
}

/// W4's stand-in: every dialog answers at once with its default — Cancel (level select, high-score erase), the
/// prefs unchanged, the default name, dismissed. W6 replaces it. Records what it was asked, for tests.
public final class WinDialogsStub: WinDialogs {
    public var hooks = WinDialogHooks()
    public private(set) var requests: [ShellRequest] = []
    public private(set) var closes = 0

    public init() {}

    public var isShowing: Bool { false }
    public var isModal: Bool { false }

    public func present(_ request: ShellRequest, prefs: BTXPrefs, completion: @escaping (WinDialogAnswer) -> Void) {
        requests.append(request)
        switch request {
        case .levelSelectDialog: completion(.levelSelect(typed: nil))
        case .highScoreNameDialog(let name): completion(.highScoreName(name))
        case .hiScoreEraseDialog: completion(.hiScoreErase(reset: false))
        case .prefsDialog: completion(.prefs(prefs))
        case .modalDialog: completion(.dismissed)
        default: break
        }
    }

    public func close() { closes += 1 }
}
