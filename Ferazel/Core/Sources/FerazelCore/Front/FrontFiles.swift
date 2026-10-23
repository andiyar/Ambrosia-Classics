import Foundation

/// A saved game the player picked or named (Standard File's `FSSpec` + its name; plan S2, F1a): a file URL and the
/// name shown in the dialogs and kept as the prefs' saved-game name.
public struct SavedGameRef: Equatable, Hashable, Sendable {
    public var url: URL
    public var displayName: String

    public init(url: URL, displayName: String) {
        self.url = url
        self.displayName = displayName
    }
}

/// A failed saved-game write as the original's File Manager result code (plan S2, F1a): `.SaveSG` maps −34 (disk
/// full), −33 (directory full), −44 (volume locked) and anything else to its four strings
/// (`SavedGameFile.writeErrorReport(osErr:)`, SV2).
public struct SaveWriteError: Error, Equatable, Sendable {
    public var osErr: Int16

    public init(osErr: Int16) {
        self.osErr = osErr
    }

    /// `dskFulErr`, `dirFulErr`, `vLckdErr`, `ioErr`.
    public static let diskFull: Int16 = -34
    public static let directoryFull: Int16 = -33
    public static let volumeLocked: Int16 = -44
    public static let ioError: Int16 = -36

    /// A Foundation / POSIX error as the File Manager code the original would have seen (SV2 carry): out of space
    /// (`NSFileWriteOutOfSpaceError`, `ENOSPC`, `EDQUOT`) → −34; read-only volume (`NSFileWriteVolumeReadOnlyError`,
    /// `EROFS`) → −44; anything else → −36 (the general string with its code). −33 has no modern cause (HFS
    /// directories no longer fill) [LOW: the mapping is the replica's; the original only ever saw File Manager codes].
    public init(_ error: Error) {
        let ns = error as NSError
        if ns.domain == NSCocoaErrorDomain {
            switch ns.code {
            case NSFileWriteOutOfSpaceError: self.init(osErr: Self.diskFull); return
            case NSFileWriteVolumeReadOnlyError: self.init(osErr: Self.volumeLocked); return
            default:
                if let u = ns.userInfo[NSUnderlyingErrorKey] as? Error { self.init(u); return }
            }
        } else if ns.domain == NSPOSIXErrorDomain {
            switch Int32(ns.code) {
            case ENOSPC: self.init(osErr: Self.diskFull); return
            #if !os(Windows)
            case EDQUOT: self.init(osErr: Self.diskFull); return    // the Windows C runtime has no EDQUOT
            #endif
            case EROFS: self.init(osErr: Self.volumeLocked); return
            default: break
            }
        }
        self.init(osErr: Self.ioError)
    }
}

/// What a Standard File dialog (`.putFile` / `.getFile` requests) answered, through `GameFlow.fileDone` (F1b uses it).
public enum FileResult: Equatable, Sendable {
    case cancelled
    case chosen(SavedGameRef)
}

/// The Core-side file seam the App implements (plan S2, F1a; Foundation types only — Invariant 1). The App's
/// implementation keeps the prefs and saved games in `~/Library/Application Support/Ambrosia Classics/Ferazel's Wand/`
/// (`PrefsFile`, `SavedGameFile`, SV2); tests pass an in-memory or temporary-directory implementation and never touch
/// that folder (Invariant 8).
public protocol FrontFiles: AnyObject {
    /// `.SetPrefFile` + `.InitPrefs`' `Get1Resource('Pref', 0)`: the stored record, or nil (no file / unreadable →
    /// the caller starts from `FerazelPrefs()`'s defaults).
    func loadPrefs() -> Data?
    /// `ChangedResource` + `WriteResource` of the `'Pref'` record (`PrefsFile.write`).
    func storePrefs(_ record: Data) throws
    /// `.OpenSG`: the saved game's block (`SavedGameFile.read`; its `SavedGameError` cases carry the original's strings).
    func readSavedGame(_ ref: SavedGameRef) throws -> SaveBlock
    /// `.SaveSG`'s write (`SavedGameFile.write`); a failure carries the File Manager code (`SaveWriteError(_:)` maps a
    /// Foundation error).
    func writeSavedGame(_ block: SaveBlock, to ref: SavedGameRef) throws(SaveWriteError)
}
