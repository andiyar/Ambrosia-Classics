import AppKit

/// The entry point: `NSApplication.shared` with `DeimosController` as its delegate, then run. The window and the
/// one menu are built in code (plan S6, A1); nothing is loaded from a nib.
@main @MainActor enum DeimosMain {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let controller = DeimosController()
        app.delegate = controller          // weak: the controller lives as long as `run()`
        withExtendedLifetime(controller) {
            app.run()
        }
    }
}
