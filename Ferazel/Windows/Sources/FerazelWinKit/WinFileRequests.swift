import FerazelCore
import Foundation

/// One native Open / Save dialog as the Windows shell asks it (plan WF5, D43 Rulings 3, 10): built here from the
/// flow's request (testable on the Mac), run by the executable's comdlg32 panels (`GetSaveFileNameW` /
/// `GetOpenFileNameW`, `FerazelWin/WinFileDialogs.swift`).
public struct WinFileRequest: Equatable, Sendable {
    public enum Kind: Equatable, Sendable { case save, open }

    /// The dialog's `OFN_*` flags, by name (the executable maps them to comdlg32's bits).
    public enum Option: Hashable, Sendable {
        case explorer, overwritePrompt, pathMustExist, fileMustExist, noChangeDir
    }

    public var kind: Kind
    /// The dialog's title: the flow's prompt ("Please name your saved game." / the open prompt).
    public var title: String
    /// The file name field's start value: the flow's default name made Windows-legal (Save); "" (Open).
    public var defaultName: String
    /// The folder the dialog starts in; nil = the dialog's own choice.
    public var folder: URL?
    /// The type filter: "All files (*.*)" only (the Mac panel takes any file; Core refuses a non-save itself).
    public var filters: [WinFileFilter]
    public var options: Set<Option>

    public init(kind: Kind, title: String, defaultName: String, folder: URL?, filters: [WinFileFilter],
                options: Set<Option>) {
        self.kind = kind
        self.title = title
        self.defaultName = defaultName
        self.folder = folder
        self.filters = filters
        self.options = options
    }
}

/// A comdlg32 filter pair: the shown name and the pattern.
public struct WinFileFilter: Equatable, Sendable {
    public var name: String
    public var pattern: String

    public init(name: String, pattern: String) {
        self.name = name
        self.pattern = pattern
    }
}

/// The requests and the answers (the Mac's `showSavePanel` / `showOpenPanel`, `FerazelController.swift:373–410`).
public enum WinFileRequests {
    public static let allFiles = WinFileFilter(name: "All files (*.*)", pattern: "*.*")
    static let common: Set<WinFileRequest.Option> = [.explorer, .overwritePrompt, .pathMustExist, .noChangeDir]

    /// `.SaveSG`'s `CustomPutFile`: title = the prompt, the default name made Windows-legal (Ruling 10), starting in
    /// the saves folder — created first, as the Mac's `ensureFolder()` (a folder that cannot be made is logged and
    /// the dialog starts in its own). `PutFileRequest.message` is not shown: comdlg32 has no message line (◇W9).
    @MainActor public static func save(_ r: PutFileRequest, files: WinFiles,
                                       log: (String) -> Void = { _ in }) -> WinFileRequest {
        let folder: URL?
        do { folder = try files.ensureSavesFolder() } catch {
            log("saves folder: \(error)")
            folder = nil
        }
        return WinFileRequest(kind: .save, title: r.prompt, defaultName: WinFiles.legalSaveName(r.defaultName),
                              folder: folder, filters: [allFiles], options: common)
    }

    /// `.OpenSG`'s `CustomGetFile`: title = the prompt, any file, starting in the saves folder only when it already
    /// exists — never created (the Mac's open panel).
    public static func open(prompt: String, files: WinFiles) -> WinFileRequest {
        let folder = files.savesFolder.flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil }
        return WinFileRequest(kind: .open, title: prompt, defaultName: "", folder: folder, filters: [allFiles],
                              options: common.union([.fileMustExist]))
    }

    /// The dialog's answer for `GameFlow.fileDone`: the chosen file, or cancelled (nil).
    public static func result(_ chosen: URL?) -> FileResult {
        guard let url = chosen else { return .cancelled }
        return .chosen(SavedGameRef(url: url, displayName: url.lastPathComponent))
    }
}
