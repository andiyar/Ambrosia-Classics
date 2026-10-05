import AkiCore
import Foundation
import HectorShell

/// The only file-system entry point (S4): every original file is loaded from `bundle` by its shipped
/// name — PNGs as `ShellBitmap`s, audio by exact file name, splash/preview/paper images with
/// `NSImage imageNamed:` semantics (the Mac extension in `Mac/AkiAssets+Mac.swift`), strings from the shipped `Localizable.strings`, nib XML from the
/// preferred `.lproj` (falling back to `English.lproj`).
@MainActor final class AkiAssets {
    enum AssetError: Error, Equatable { case missing(String) }

    let bundle: Bundle
    /// The art scale the splash / proverb / paper / preview images load at (`image(_:)`, the platform
    /// extensions): 1 = the original files (exactly as before Remaster), `RemasterSetting.scale` = the
    /// `hd-4x/` files at the originals' point size. Set by `AkiController` with its `artScale`.
    var artScale = 1

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    /// "<name>.png" decoded at its native size, e.g. `png("map")`. With `scale` k > 1 (Remaster, D11):
    /// `hd-4x/<name>.png` as a k-scaled `ShellBitmap` of the original's logical size.
    func png(_ name: String, scale: Int = 1) throws -> ShellBitmap {
        if scale > 1 {
            guard let url = remasterURL(name) else {
                throw ShellBitmapError.unreadable("\(RemasterSetting.directory)/\(name).png")
            }
            return try ShellBitmap(contentsOf: url, scale: scale)
        }
        guard let url = bundle.url(forResource: name, withExtension: "png") else {
            throw ShellBitmapError.unreadable("\(name).png")
        }
        return try ShellBitmap(contentsOf: url)
    }

    /// `hd-4x/<name>.png` in this bundle (nil when absent).
    func remasterURL(_ name: String) -> URL? {
        bundle.url(forResource: name, withExtension: "png", subdirectory: RemasterSetting.directory)
    }

    /// Remaster is available (D11, U3 contract 2) only when `hd-4x/` holds every PNG the GWorlds load and
    /// every level background.
    func hasRemasterArt() -> Bool {
        guard let resources = bundle.resourceURL else { return false }
        let folder = resources.appendingPathComponent(RemasterSetting.directory)
        return RemasterSetting.requiredFiles(gworldPNGs: AkiGWorlds.pngNames).allSatisfy {
            FileManager.default.fileExists(atPath: folder.appendingPathComponent($0).path)
        }
    }

    /// The exact shipped file name, e.g. `url("Aki Theme 3.mp3")`; nil when the bundle lacks it.
    func url(_ fileName: String) -> URL? {
        guard let resources = bundle.resourceURL else { return nil }
        let url = resources.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// The shipped `Localizable.strings` of the preferred localization, keyed by the English text.
    func localized(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    /// `<preferred>.lproj/<relative>`, else `English.lproj/<relative>` — e.g.
    /// `lproj("Preferences.nib/designable.nib")`.
    func lproj(_ relative: String) throws -> Data {
        guard let resources = bundle.resourceURL else { throw AssetError.missing(relative) }
        let preferred = bundle.preferredLocalizations.first ?? "English"
        for localization in [preferred, "English"] {
            let url = resources.appendingPathComponent("\(localization).lproj/\(relative)")
            if FileManager.default.fileExists(atPath: url.path) {
                return try Data(contentsOf: url)
            }
        }
        throw AssetError.missing(relative)
    }

    #if DEBUG
    /// Dev-build launch check only (Known delta 7, S4): the shipped files the app cannot start
    /// without, by name, that this bundle lacks. Compiled out of Release.
    func missingFiles() -> [String] {
        AkiGWorlds.pngNames.map { "\($0).png" }.filter { url($0) == nil }
    }
    #endif
}
