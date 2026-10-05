import AkiCore
import Foundation
import HectorShell
import ImageIO

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
    /// every level background, each EXACTLY `RemasterSetting.scale` × its original's pixel size (read from the
    /// PNG headers through ImageIO properties — no decode; U3 review).
    func hasRemasterArt() -> Bool {
        guard let resources = bundle.resourceURL else { return false }
        let folder = resources.appendingPathComponent(RemasterSetting.directory)
        let k = RemasterSetting.scale
        for file in RemasterSetting.requiredFiles(gworldPNGs: AkiGWorlds.pngNames) {
            guard let original = Self.pixelSize(resources.appendingPathComponent(file)),
                  let hd = Self.pixelSize(folder.appendingPathComponent(file)),
                  hd.width == original.width * k, hd.height == original.height * k else {
                print("Aki: Remaster unavailable — \(RemasterSetting.directory)/\(file) is missing or not \(k)× its original")
                return false
            }
        }
        return true
    }

    /// A PNG's pixel size from its header (ImageIO properties, no full decode); nil when absent or unreadable.
    static func pixelSize(_ url: URL) -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
              let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue else { return nil }
        return (width, height)
    }

    /// An art PNG loaded after launch (the level background): `png(name, scale:)`, but when the `hd-4x/` file
    /// fails to load, the ORIGINAL at k = 1 for this bitmap (HectorShell copies between bitmaps of different k
    /// are defined — nearest), logged once per file. Never fails because of hd art; throws only when the
    /// original itself is unreadable.
    func artPNG(_ name: String, scale: Int) throws -> ShellBitmap {
        guard scale > 1 else { return try png(name) }
        do {
            return try png(name, scale: scale)
        } catch {
            noteRemasterFallback("\(name).png", error)
            return try png(name)
        }
    }

    /// The `hd-4x/` files that have already fallen back to their originals (each is logged once).
    private var loggedFallbacks: Set<String> = []

    /// Logs, once per file, that an `hd-4x/` file failed to load and its original is used instead.
    func noteRemasterFallback(_ file: String, _ error: Error? = nil) {
        guard loggedFallbacks.insert(file).inserted else { return }
        print("Aki: cannot load \(RemasterSetting.directory)/\(file), using the original\(error.map { ": \($0)" } ?? "")")
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
