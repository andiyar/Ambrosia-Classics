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
    /// ◇ `-players N` (plan AP, ruling 1): stands in for the main menu's 2 PLAYER button (Phase 4); only a number in
    /// `playerRange` is accepted. Kept as typed (a negative number such as `-1` included) and checked at launch: any
    /// other value is refused like a bad film tag, and so is a missing value (the last argument, or followed by
    /// another `-` flag), which is kept as "". nil = no `-players` (one player). Ignored with `-film` (the film carries
    /// its own player count).
    var players: String?
    /// ◇ `-sector N` (plan AP, ruling 1): stands in for the main menu's level select (Phase 4) — start at sector N, a
    /// number in `sectorRange` (a start above sector 1 has one life: the core's player set-up, `FUN_10026cc0`). Kept
    /// and checked as `players` is; nil = no `-sector` (sector 1). Restarts return to it. Ignored with `-film`.
    var sector: String?
    /// The values `-players` and `-sector` accept — the one place the app states them.
    static let playerRange = 1...2
    static let sectorRange = 1...12
    #if DEBUG
    /// DEBUG only (A3's machine check): `-debugCapsLock <seconds>` simulates Caps Lock down through `HeldKeys` from
    /// that many seconds after launch for `debugCapsLockHold` seconds, so the pause wait can be shown reached.
    var debugCapsLockAt: Double?
    static let debugCapsLockHold = 4.0
    #endif

    init(arguments: [String]) {
        var i = 1
        /// The value after flag `i`, or "" (the refused value) when it is missing — the following flag is then read
        /// as itself; `i` steps past what was read. A next argument starting with `-` is another flag, except, for a
        /// `numeric` flag, a negative whole number (`-3`): that is taken as typed, so its refusal can show it.
        func value(numeric: Bool = false) -> String {
            if i + 1 < arguments.count {
                let next = arguments[i + 1]
                if !next.hasPrefix("-") || (numeric && Self.isNegativeNumber(next)) {
                    i += 2
                    return next
                }
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
                players = value(numeric: true)
                continue
            }
            if a == "-sector" {
                sector = value(numeric: true)
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

    /// ◇ `-players`: a number in `playerRange`; 1 when absent; throws `BadValue` for anything else.
    func playerCount() throws -> Int {
        try Self.number(players, flag: "-players", in: Self.playerRange) ?? 1
    }

    /// ◇ `-sector`: a number in `sectorRange`; 1 when absent; throws `BadValue` for anything else.
    func startSector() throws -> Int {
        try Self.number(sector, flag: "-sector", in: Self.sectorRange) ?? 1
    }

    /// `-` followed by one or more ASCII digits and nothing else.
    private static func isNegativeNumber(_ s: String) -> Bool {
        let digits = s.utf8.dropFirst()
        return s.hasPrefix("-") && !digits.isEmpty && digits.allSatisfy { (0x30...0x39).contains($0) }
    }

    /// A `-players` / `-sector` value that is not a whole number in range (or is missing); its description is the
    /// refusal's text, stating the range once.
    struct BadValue: Error, CustomStringConvertible {
        let flag: String
        let value: String
        let range: ClosedRange<Int>
        var description: String {
            let accepted = range.count == 2 ? "\(range.lowerBound) or \(range.upperBound)"
                                            : "a number from \(range.lowerBound) to \(range.upperBound)"
            if value.isEmpty { return "\(flag) needs a value after it: \(accepted)." }
            return "\(flag) takes \(accepted), not “\(value)”."
        }
    }

    private static func number(_ value: String?, flag: String, in range: ClosedRange<Int>) throws -> Int? {
        guard let value else { return nil }
        guard let n = Int(value), range.contains(n) else { throw BadValue(flag: flag, value: value, range: range) }
        return n
    }
}
