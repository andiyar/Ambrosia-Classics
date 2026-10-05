import AppKit

/// The entry point: `NSApplication.shared` with `BTXController` as its delegate, then run. The 1.1 app loaded
/// `main.nib` for its menu bar; the replica builds its window and menus in code, so nothing is loaded from a nib.
@main @MainActor enum BTXMain {
    static func main() {
        // AppKit appends Start Dictation… and Emoji & Symbols to an Edit menu; the original's nib has neither
        // (D4.3). Registered (not written) defaults switch both off without touching the app's domain.
        UserDefaults.standard.register(defaults: ["NSDisabledDictationMenuItem": true,
                                                  "NSDisabledCharacterPaletteMenuItem": true])
        let app = NSApplication.shared
        // The 2008 binary always drew Aqua (D4.1).
        app.appearance = NSAppearance(named: .aqua)
        let controller = BTXController()
        app.delegate = controller          // weak: the controller lives as long as `run()`
        withExtendedLifetime(controller) {
            app.run()
        }
    }
}
