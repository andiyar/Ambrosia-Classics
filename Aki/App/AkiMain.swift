import AppKit

/// The entry point: `NSApplication.shared` with `AkiController` as its delegate, then run. The 1.2
/// app had `NSMainNibFile` = MainMenu.nib; the replica builds its window and (P1.9) its menus in code
/// from the shipped nib XML, so nothing is loaded from a nib here.
@main @MainActor enum AkiMain {
    static func main() {
        let app = NSApplication.shared
        let controller = AkiController()
        app.delegate = controller          // weak: the controller lives as long as `run()`
        withExtendedLifetime(controller) {
            app.run()
        }
    }
}
