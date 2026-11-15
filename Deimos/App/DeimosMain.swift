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
    /// `-film` given without a tag (the last argument, or followed by another `-` flag) is "" — refused at launch like
    /// an unknown tag; the following flag is then read as itself.
    var film: String?
    /// ◇ `-players N` (plan AP, ruling 1): stands in for the main menu's 2 PLAYER button (Phase 4); only `1` or `2` is
    /// accepted. Kept as typed and refused at launch like a bad film tag (anything else, or no value → ""); nil = no
    /// `-players` (one player). Ignored with `-film` (the film carries its own player count).
    var players: String?
    /// ◇ `-sector N` (plan AP, ruling 1): stands in for the main menu's level select (Phase 4) — start at sector N,
    /// 1…12 (a start above sector 1 has one life: the core's player set-up, `FUN_10026cc0`). Kept as typed and refused
    /// at launch like a bad film tag; nil = no `-sector` (sector 1). Restarts return to it. Ignored with `-film`.
    var sector: String?
    #if DEBUG
    /// DEBUG only (A3's machine check): `-debugCapsLock <seconds>` simulates Caps Lock down through `HeldKeys` from
    /// that many seconds after launch for `debugCapsLockHold` seconds, so the pause wait can be shown reached.
    var debugCapsLockAt: Double?
    static let debugCapsLockHold = 4.0
    #endif

    init(arguments: [String]) {
        var i = 1
        /// The value after flag `i`, or "" (the refused value) when it is missing — the following flag is then read
        /// as itself; `i` steps past what was read.
        func value() -> String {
            if i + 1 < arguments.count, !arguments[i + 1].hasPrefix("-") {
                defer { i += 2 }
                return arguments[i + 1]
            }
            i += 1
            return ""                                       // missing value: the bad-value path
        }
        while i < arguments.count {
            let a = arguments[i]
            if a == "-film" {
                film = value()                              // missing tag: "" — the bad-tag path
                continue
            }
            if a == "-players" {
                players = value()
                continue
            }
            if a == "-sector" {
                sector = value()
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

    /// ◇ `-players`: 1 or 2; nil when absent (one player); throws `BadValue` for anything else.
    func playerCount() throws -> Int {
        try Self.number(players, flag: "-players", in: 1...2) ?? 1
    }

    /// ◇ `-sector`: 1…12; nil when absent (sector 1); throws `BadValue` for anything else.
    func startSector() throws -> Int {
        try Self.number(sector, flag: "-sector", in: 1...12) ?? 1
    }

    /// A `-players` / `-sector` value that is not a whole number in range (or is missing).
    struct BadValue: Error, CustomStringConvertible {
        let flag: String
        let value: String
        let range: ClosedRange<Int>
        var description: String {
            "\(flag) takes a number from \(range.lowerBound) to \(range.upperBound), not “\(value)”"
        }
    }

    private static func number(_ value: String?, flag: String, in range: ClosedRange<Int>) throws -> Int? {
        guard let value else { return nil }
        guard let n = Int(value), range.contains(n) else { throw BadValue(flag: flag, value: value, range: range) }
        return n
    }
}
