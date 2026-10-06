import AppKit

/// The entry point: `NSApplication.shared` with `AkiAppDelegate` as its delegate, then run. The 1.2
/// app had `NSMainNibFile` = MainMenu.nib; the replica builds its window and (P1.9) its menus in code
/// from the shipped nib XML, so nothing is loaded from a nib here.
@main @MainActor enum AkiMain {
    static func main() {
        // AppKit appends Start Dictation… and Emoji & Symbols to the Edit menu; MainMenu.nib has neither.
        // Registered (not written) defaults switch both off without touching the app's domain.
        UserDefaults.standard.register(defaults: ["NSDisabledDictationMenuItem": true,
                                                  "NSDisabledCharacterPaletteMenuItem": true])
        let app = NSApplication.shared
        // The 2008 binary always drew Aqua; dark mode would turn the parchment dialogs' labels white.
        app.appearance = NSAppearance(named: .aqua)
        let delegate = AkiAppDelegate()
        app.delegate = delegate            // weak: the delegate lives as long as `run()`
        withExtendedLifetime(delegate) {
            app.run()
        }
    }
}
