import AppKit

/// The entry point: `NSApplication.shared` with `DeimosController` as its delegate, then run. The window and the
/// one menu are built in code (plan S6, A1); nothing is loaded from a nib.
@main @MainActor enum DeimosMain {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let controller = DeimosController(options: LaunchOptions(arguments: CommandLine.arguments))
        app.delegate = controller          // weak: the controller lives as long as `run()`
        withExtendedLifetime(controller) {
            app.run()
        }
    }
}

/// The launch arguments the app reads (plan A3). Everything else on the command line (Cocoa's `-NS…` defaults
/// pairs, a Finder `-psn_…`) is left alone.
struct LaunchOptions {
    /// ◇ `-film deNN` (plan stand-in 5): the shipped demo film to play instead of a new game; nil = no `-film`.
    /// `-film` given without a tag is "" — refused at launch like an unknown tag.
    var film: String?
    #if DEBUG
    /// DEBUG only (A3's machine check): `-debugCapsLock <seconds>` simulates Caps Lock down through `HeldKeys` from
    /// that many seconds after launch for `debugCapsLockHold` seconds, so the pause wait can be shown reached.
    var debugCapsLockAt: Double?
    static let debugCapsLockHold = 4.0
    #endif

    init(arguments: [String]) {
        var i = 1
        while i < arguments.count {
            let a = arguments[i]
            if a == "-film" {
                film = i + 1 < arguments.count ? arguments[i + 1] : ""
                i += 2
                continue
            }
            #if DEBUG
            if a == "-debugCapsLock", i + 1 < arguments.count {
                debugCapsLockAt = Double(arguments[i + 1])
                i += 2
                continue
            }
            #endif
            i += 1
        }
    }
}
