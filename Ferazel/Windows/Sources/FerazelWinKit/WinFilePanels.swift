import FerazelCore
import Foundation

/// The saved-game panels on Windows (D43 Ruling 3): the native Open / Save dialogs (comdlg32, in the executable,
/// WF5), modal and synchronous like the Mac's `NSSavePanel.runModal` — the flow is held still while one is up. WF3
/// ships only `WinStubFilePanels`.
@MainActor public protocol WinFilePanels: AnyObject {
    /// `.SaveSG`'s `CustomPutFile`: title = the prompt, default name = the flow's (made Windows-legal by the panel,
    /// `WinFiles.legalSaveName`), starting in `folder` (created first by the caller).
    func save(_ request: PutFileRequest, folder: URL?) -> FileResult
    /// `.OpenSG`'s `CustomGetFile`: any file (Core refuses a non-save with the original's text), starting in `folder`
    /// when it exists.
    func open(prompt: String, folder: URL?) -> FileResult
}

/// Every panel answers cancelled at once (WF3, and the `--frames` runs).
@MainActor public final class WinStubFilePanels: WinFilePanels {
    /// What was asked, in order ("save <default name>" / "open <prompt>").
    public private(set) var asked: [String] = []

    public init() {}

    public func save(_ request: PutFileRequest, folder: URL?) -> FileResult {
        asked.append("save \(request.defaultName)")
        return .cancelled
    }

    public func open(prompt: String, folder: URL?) -> FileResult {
        asked.append("open \(prompt)")
        return .cancelled
    }
}
