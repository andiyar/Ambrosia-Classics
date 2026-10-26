import FerazelCore
import Foundation

/// The saved-game panels on Windows (D43 Ruling 3, plan WF5): the native Open / Save dialogs (comdlg32, in the
/// executable — `FerazelWin/WinFileDialogs.swift`), modal and synchronous like the Mac's `NSSavePanel.runModal` — the
/// flow is held still while one is up. The request is built by `WinFileRequests` (title, Windows-legal default name,
/// start folder, filter); the answer goes back through `WinFileRequests.result`.
@MainActor public protocol WinFilePanels: AnyObject {
    /// Runs one dialog; the chosen file, or nil when cancelled.
    func run(_ request: WinFileRequest) -> URL?
}

/// Every panel answers cancelled at once (the `--frames` runs).
@MainActor public final class WinStubFilePanels: WinFilePanels {
    /// What was asked, in order ("save <default name>" / "open <title>").
    public private(set) var asked: [String] = []

    public init() {}

    public func run(_ request: WinFileRequest) -> URL? {
        switch request.kind {
        case .save: asked.append("save \(request.defaultName)")
        case .open: asked.append("open \(request.title)")
        }
        return nil
    }
}

/// The Mac SDL development build's panels (no comdlg32): `--save-as FILE` answers every Save dialog, `--open FILE`
/// every Open dialog; without one, cancelled.
@MainActor public final class WinAnswerFilePanels: WinFilePanels {
    let saveAs: URL?
    let open: URL?

    public init(_ args: WinArgs) {
        saveAs = args.saveAsPath.map { URL(fileURLWithPath: $0) }
        open = args.openPath.map { URL(fileURLWithPath: $0) }
    }

    public func run(_ request: WinFileRequest) -> URL? {
        switch request.kind {
        case .save: saveAs
        case .open: open
        }
    }
}
