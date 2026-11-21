import AppKit

/// The entry point: `NSApplication.shared` with `DeimosController` as its delegate, then run. The window and the
/// one menu are built in code (plan S6, A1); nothing is loaded from a nib.
@main @MainActor enum DeimosMain {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let controller = DeimosController(options: LaunchOptions(arguments: CommandLine.arguments,
                                                                 environment: ProcessInfo.processInfo.environment,
                                                                 keyLogDefault: UserDefaults.standard.bool(forKey: "keylog")))
        app.delegate = controller          // weak: the controller lives as long as `run()`
        withExtendedLifetime(controller) {
            app.run()
        }
    }
}

/// The launch arguments the app reads. A launch with none boots to the main menu, as the original (Phase 4 S8a);
/// the old `-players` and `-sector` stand-ins are gone (plan ruling 10, Ben). Everything else on the command line
/// (Cocoa's `-NS…` defaults pairs, a Finder `-psn_…`) is left alone.
struct LaunchOptions {
    /// ◇ Hidden `-film deNN` (ruling 10): the shipped demo film the menu plays as soon as it is up, as a demo, then
    /// the menu again; nil = no `-film`. `-film` given without a tag (the last argument, or followed by another `-`
    /// flag) is "" — refused at launch like an unknown tag (the alert shows in Release too); the following flag is
    /// then read as itself.
    var film: String?
    /// ◇ Hidden mute switch (DECISIONS D42: a launch for a boot check must open no audio output): `-mute`, or the
    /// environment variable `DEIMOS_MUTE` set to anything but "" or "0". The app then opens no sound output and runs
    /// as the original does with no sound system (`FUN_10047160`'s "Sound not available" path: the publisher logo
    /// holds 130 ticks instead of waiting for its sound), and makes no system beep.
    var mute = false
    /// ◇ Hidden key log (the bomb-freeze diagnosis, Ben's first playtest): `-keylog`, or the user default `keylog`
    /// (`defaults write com.ambrosiaclassics.deimos keylog -bool YES`, for a double-click launch; handed in as
    /// `keyLogDefault`). The app then records the key events and keyboard focus it sees to
    /// `~/Library/Logs/Deimos Rising/keys.log` (`KeyLog`); off, nothing is installed.
    var keyLog = false
    #if DEBUG
    /// DEBUG only (A3's machine check): `-debugCapsLock <seconds>` simulates Caps Lock down through `HeldKeys` from
    /// that many seconds after launch for `debugCapsLockHold` seconds, so the pause wait can be shown reached.
    var debugCapsLockAt: Double?
    static let debugCapsLockHold = 4.0
    #endif

    init(arguments: [String], environment: [String: String] = [:], keyLogDefault: Bool = false) {
        if let value = environment["DEIMOS_MUTE"], !value.isEmpty, value != "0" { mute = true }
        keyLog = keyLogDefault
        var i = 1
        while i < arguments.count {
            let a = arguments[i]
            if a == "-film" {
                // The tag after it, or "" (the refused value) when it is missing — the following flag is then read
                // as itself.
                if i + 1 < arguments.count, !arguments[i + 1].hasPrefix("-") {
                    film = arguments[i + 1]
                    i += 2
                } else {
                    film = ""
                    i += 1
                }
                continue
            }
            if a == "-mute" {
                mute = true
                i += 1
                continue
            }
            if a == "-keylog" {
                keyLog = true
                i += 1
                continue
            }
            #if DEBUG
            if a == "-debugCapsLock" {
                // Its number, if one follows; a following flag is read as itself (ruling 10: no longer swallowed).
                if i + 1 < arguments.count, let seconds = Double(arguments[i + 1]), !arguments[i + 1].hasPrefix("-") {
                    debugCapsLockAt = seconds
                    i += 2
                } else {
                    i += 1
                }
                continue
            }
            #endif
            i += 1
        }
    }
}
