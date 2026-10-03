import AppKit
import HectorShell

/// The only file-system entry point (S4): every original file is loaded from `bundle` by its shipped
/// name — PNGs as `ShellBitmap`s, audio by exact file name, splash/preview/paper images with
/// `NSImage imageNamed:` semantics, strings from the shipped `Localizable.strings`, nib XML from the
/// preferred `.lproj` (falling back to `English.lproj`).
@MainActor final class AkiAssets {
    enum AssetError: Error, Equatable { case missing(String) }

    let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    /// "<name>.png" decoded at its native size, e.g. `png("map")`.
    func png(_ name: String) throws -> ShellBitmap {
        guard let url = bundle.url(forResource: name, withExtension: "png") else {
            throw ShellBitmapError.unreadable("\(name).png")
        }
        return try ShellBitmap(contentsOf: url)
    }

    /// The exact shipped file name, e.g. `url("Aki Theme 3.mp3")`; nil when the bundle lacks it.
    func url(_ fileName: String) -> URL? {
        guard let resources = bundle.resourceURL else { return nil }
        let url = resources.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// `[NSImage imageNamed:]` semantics over this bundle (nil when absent).
    func image(_ name: String) -> NSImage? {
        bundle.image(forResource: name)
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
