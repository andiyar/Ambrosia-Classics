// The saved-game dialogs (plan WF5, D43 Ruling 3): on Windows the native Open / Save dialogs (comdlg32
// `GetOpenFileNameW` / `GetSaveFileNameW`, modal, owned by the game window); on the Mac SDL development build the
// `--save-as FILE` / `--open FILE` answers (`WinAnswerFilePanels`), else cancelled. The request (title, Windows-legal
// default name, start folder, "All files (*.*)") is `WinFileRequests`' — nothing here decides what is asked.
// `import WinSDK` brings commdlg.h (its `Controls.CommDlg` submodule), which links ComDlg32.Lib itself.
import FerazelWinKit
import Foundation
#if os(Windows)
import WinSDK

/// comdlg32's Open / Save dialogs. The answer's path comes back as the dialog wrote it (UTF-16, backslashes).
@MainActor final class WinNativeFilePanels: WinFilePanels {
    /// The file name buffer (UTF-16 units): the long-path maximum.
    static let fileBufferCount = 32_768
    private let log: (String) -> Void

    init(log: @escaping (String) -> Void) {
        self.log = log
    }

    static func flags(_ options: Set<WinFileRequest.Option>) -> DWORD {
        var f: DWORD = 0
        for o in options {
            switch o {
            case .explorer: f |= DWORD(OFN_EXPLORER)
            case .overwritePrompt: f |= DWORD(OFN_OVERWRITEPROMPT)
            case .pathMustExist: f |= DWORD(OFN_PATHMUSTEXIST)
            case .fileMustExist: f |= DWORD(OFN_FILEMUSTEXIST)
            case .noChangeDir: f |= DWORD(OFN_NOCHANGEDIR)
            }
        }
        return f
    }

    /// NUL-terminated UTF-16 (pure Swift, Ruling 18).
    static func wide(_ s: String) -> [WCHAR] { Array(s.utf16) + [0] }

    func run(_ request: WinFileRequest) -> URL? {
        var file = [WCHAR](repeating: 0, count: Self.fileBufferCount)
        let name = Array(WinFileRequests.initialFile(request).utf16)
        if name.count < file.count { file.replaceSubrange(0..<name.count, with: name) }
        // "name\0pattern\0" per filter, then a closing NUL.
        var filter: [WCHAR] = []
        for f in request.filters { filter += Self.wide(f.name) + Self.wide(f.pattern) }
        filter.append(0)
        let title = Self.wide(request.title)
        let folder = Self.wide(request.folder.map(WinStartup.displayPath) ?? "")
        let hasFolder = request.folder != nil
        var ofn = OPENFILENAMEW()
        ofn.lStructSize = DWORD(MemoryLayout<OPENFILENAMEW>.size)   // = sizeof(OPENFILENAMEW): 152 on x64
        ofn.hwndOwner = GetActiveWindow()
        ofn.nFilterIndex = 1
        ofn.Flags = Self.flags(request.options)
        let ok: Bool = filter.withUnsafeBufferPointer { filterPtr in
            title.withUnsafeBufferPointer { titlePtr in
                folder.withUnsafeBufferPointer { folderPtr in
                    file.withUnsafeMutableBufferPointer { filePtr in
                        ofn.lpstrFilter = filterPtr.baseAddress
                        ofn.lpstrTitle = titlePtr.baseAddress
                        ofn.lpstrInitialDir = hasFolder ? folderPtr.baseAddress : nil
                        ofn.lpstrFile = filePtr.baseAddress
                        ofn.nMaxFile = DWORD(filePtr.count)
                        switch request.kind {
                        case .save: return GetSaveFileNameW(&ofn)
                        case .open: return GetOpenFileNameW(&ofn)
                        }
                    }
                }
            }
        }
        guard ok else {
            let code = CommDlgExtendedError()   // 0 = the player cancelled
            if code != 0 { log("the file dialog failed: CommDlgExtendedError \(code)") }
            return nil
        }
        let end = file.firstIndex(of: 0) ?? file.count
        let path = String(decoding: file[..<end], as: UTF16.self)
        return path.isEmpty ? nil : URL(fileURLWithPath: path)
    }
}
#endif

enum WinFileDialogs {
    /// The panels this launch uses: none shown headless (`--frames`: the stub cancels); else Windows' native dialogs,
    /// or the Mac SDL build's command-line answers.
    @MainActor static func panels(_ args: WinArgs, log: @escaping (String) -> Void) -> any WinFilePanels {
        if args.headless { return WinStubFilePanels() }
        #if os(Windows)
        return WinNativeFilePanels(log: log)
        #else
        return WinAnswerFilePanels(args)
        #endif
    }
}
