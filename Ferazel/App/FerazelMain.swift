import AppKit

/// The entry point: `NSApplication.shared` with `FerazelController` as its delegate, then run. The window and the one
/// menu are built in code (plan S5, A1); nothing is loaded from a nib.
@main @MainActor enum FerazelMain {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        // The original drew on a classic Mac; the replica's window chrome stays Aqua (D4.1).
        app.appearance = NSAppearance(named: .aqua)
        let controller = FerazelController()
        app.delegate = controller          // weak: the controller lives as long as `run()`
        withExtendedLifetime(controller) {
            app.run()
        }
    }
}
