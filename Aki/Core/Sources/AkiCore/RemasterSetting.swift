import Foundation

/// The Remaster mode switch (DECISIONS D11, plan `2026-10-04-aki-remaster-art.md` C5/C6): a Bool under its OWN
/// defaults key `RemasteredArt` — never inside the 143-byte `GameSettings` blob — default false (a fresh
/// install plays the Original art). Remaster loads the 4x art set `hd-4x/` (`tools/upscale-aki-art.py`: AI-upscaled
/// pictures, plain-Lanczos tile body, de-dithered backgrounds — Ben's U4 rulings; same file names, every
/// file 4× the original's pixel size) at art scale 4; it is effective only while that set is in the bundle.
public struct RemasterSetting {
    /// The defaults key (not `GameSettings.defaultsKey`).
    public static let defaultsKey = "RemasteredArt"
    /// Backing pixels per logical pixel of the Remaster art set.
    public static let scale = 4
    /// The art set's folder beside the original files (`Contents/Resources/hd-4x/` on Mac, `hd-4x/` on iPad).
    public static let directory = "hd-4x"

    public let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// The stored choice; false when the key is absent (reading writes nothing).
    public var isOn: Bool {
        get { defaults.bool(forKey: Self.defaultsKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.defaultsKey) }
    }

    /// The art scale the app runs at: 4 only when the setting is on AND the art set is available, else 1.
    public static func artScale(isOn: Bool, available: Bool) -> Int {
        isOn && available ? scale : 1
    }

    /// The `hd-4x/` files whose presence makes Remaster available: every PNG the GWorlds load plus every level
    /// background (`background1`…`background17`, swapped in per level), as file names, without repeats.
    public static func requiredFiles(gworldPNGs: [String]) -> [String] {
        var names: [String] = []
        for name in gworldPNGs + (1...17).map({ "background\($0)" }) where !names.contains(name) {
            names.append(name)
        }
        return names.map { "\($0).png" }
    }

    /// The Preferences window with the "Remastered art" row (C6): one checkbox below the nib's lowest
    /// checkbox, the window one row taller. `pitch` is the nib's own checkbox row pitch (the smallest vertical
    /// step between two checkboxes in one column). Frames are AppKit's (bottom-left origin), so the checkboxes
    /// move UP by `pitch` (keeping their distance from the window top) and every control not passed in — OK and
    /// Cancel — keeps its frame (its distance from the bottom). The new box is in the lowest checkbox's column at
    /// its old y (one row below its new position), as tall as it, as wide as the widest nib checkbox, in its
    /// font, unchecked.
    public struct PreferencesRow: Equatable, Sendable {
        public var pitch: Int
        public var window: CocoaNib.Window
        public var checkboxes: [CocoaNib.Control]
        public var remaster: CocoaNib.Control
    }

    public static func preferencesRow(window: CocoaNib.Window, checkboxes: [CocoaNib.Control],
                                      title: String) -> PreferencesRow {
        var pitch = Int.max
        for a in checkboxes {
            for b in checkboxes where b.x == a.x && b.y > a.y {
                pitch = min(pitch, b.y - a.y)
            }
        }
        if pitch == Int.max { pitch = checkboxes.map(\.height).max() ?? 18 }
        var grown = window
        grown.contentHeight += pitch
        let moved = checkboxes.map { box -> CocoaNib.Control in
            var box = box
            box.y += pitch
            return box
        }
        let lowest = checkboxes.min { $0.y < $1.y }
        let remaster = CocoaNib.Control(className: "NSButton", x: lowest?.x ?? 18, y: lowest?.y ?? 0,
                                        width: checkboxes.map(\.width).max() ?? 0, height: lowest?.height ?? 18,
                                        title: title, keyEquivalent: nil, fontName: lowest?.fontName,
                                        fontSize: lowest?.fontSize, isOn: false)
        return PreferencesRow(pitch: pitch, window: grown, checkboxes: moved, remaster: remaster)
    }
}
