import FerazelCore
import Foundation

/// `FerazelWin`'s command line (plan WF3, D43 Rulings 10–12, 20):
///
///     FerazelWin [--data DIR] [--fonts DIR] [--prefs FILE] [--saves DIR] [--mute]
///                [--frames N [--dump FILE.ppm] [--keys SCRIPT] [--seed N]]
///                [-FerazelLevel N] [-ColorTieBreak lowest] [-MacGamma YES] [-FerazelMute YES] [SAVED-GAME]
///
/// `--` options are this build's; `-Key value` pairs are the Mac's hidden switches (Ruling 11), read as the Mac's
/// `UserDefaults` argument domain reads its command line (measured, WF1): a key takes the next argument as its value
/// unless that starts with "-" (then the key is unset and that argument is read as a new key); a key with no value
/// is unset; the values go through `FerazelSettings.arguments` (the measured string reads: "2abc" → 0, "y" → false,
/// only "yes" / "true" / "1" are true). A later pair for the same key wins. Any other argument is a saved game to open
/// (the first; Windows' "open with"). Never `UserDefaults` (D16.3, Ruling 18).
public struct WinArgs: Sendable {
    /// `--data`: the original data folder (default `Data\` beside the executable).
    public var dataPath: String?
    /// `--fonts`: the baked faces (default `<data>\Fonts`).
    public var fontsPath: String?
    /// `--prefs`: the prefs file (default the prefs folder's `PrefsFile.fileName`; in memory in `--frames` mode).
    public var prefsPath: String?
    /// `--saves`: the saved games' start folder (default the prefs folder).
    public var savesPath: String?
    /// `--mute` (Ruling 20).
    public var muteFlag = false
    /// `--frames N`: headless — N loop wakes of exactly 1/240 s each.
    public var frames: Int?
    /// `--dump FILE.ppm`: the last presented 640×480 frame, written after the frames.
    public var dumpPath: String?
    /// `--keys SCRIPT`: a `WinKeyScript` file.
    public var keysPath: String?
    /// `--seed N`: the flow's seed in `--frames` mode (decimal, or hex with 0x).
    public var seed: Int32?
    /// The saved game to open (the first argument that is no option).
    public var document: String?
    /// The `-Key value` pairs, as the argument domain holds them.
    public var defaults: [String: String] = [:]
    /// The hidden switches (`FerazelSettings.parse` over `defaults` and the environment; `--mute` mutes too).
    var settings = FerazelSettings()

    public init() {}

    /// `--frames` mode: no window shown to anyone, dummy drivers, the silent mixer, pinned clocks.
    public var headless: Bool { frames != nil }
    /// The game is muted (`--mute`, `-FerazelMute YES`, `FERAZEL_MUTE=1`).
    public var muted: Bool { settings.mute }

    public struct UsageError: Error, Equatable, CustomStringConvertible {
        public let message: String
        public var description: String { message }
    }

    public static let usage = "usage: FerazelWin [--data DIR] [--fonts DIR] [--prefs FILE] [--saves DIR] [--mute] "
        + "[--frames N [--dump FILE.ppm] [--keys SCRIPT] [--seed N]] [-FerazelLevel N] [-ColorTieBreak lowest] "
        + "[-MacGamma YES] [-FerazelMute YES] [SAVED-GAME]"

    /// Parses the arguments after the program name. A bad option throws (`FerazelWin` exits 64 with the message).
    public static func parse(_ arguments: [String], environment: [String: String]) throws(UsageError) -> WinArgs {
        var a = WinArgs()
        var rest = arguments[...]
        func value(_ flag: String) throws(UsageError) -> String {
            guard let v = rest.popFirst() else { throw UsageError(message: "\(flag) needs a value") }
            return v
        }
        while let arg = rest.popFirst() {
            switch arg {
            case "--data": a.dataPath = try value(arg)
            case "--fonts": a.fontsPath = try value(arg)
            case "--prefs": a.prefsPath = try value(arg)
            case "--saves": a.savesPath = try value(arg)
            case "--mute": a.muteFlag = true
            case "--frames":
                guard let n = Int(try value(arg)), n > 0 else { throw UsageError(message: "--frames needs a count > 0") }
                a.frames = n
            case "--dump": a.dumpPath = try value(arg)
            case "--keys": a.keysPath = try value(arg)
            case "--seed":
                guard let n = Self.seedValue(try value(arg)) else {
                    throw UsageError(message: "--seed needs a 32-bit integer")
                }
                a.seed = n
            default:
                if arg.hasPrefix("--") { throw UsageError(message: "unknown option \(arg)\n\(usage)") }
                if arg.hasPrefix("-") {
                    // The argument domain: `-Key value`; a value starting with "-" is the next key, not a value.
                    let key = String(arg.dropFirst())
                    if let next = rest.first, !next.hasPrefix("-") {
                        rest = rest.dropFirst()
                        if !key.isEmpty { a.defaults[key] = next }
                    }
                } else if a.document == nil {
                    a.document = arg
                }
            }
        }
        if a.frames == nil, a.dumpPath != nil || a.keysPath != nil || a.seed != nil {
            throw UsageError(message: "--dump, --keys and --seed need --frames")
        }
        a.settings = FerazelSettings.parse(lookup: FerazelSettings.arguments(a.defaults), environment: environment)
        if a.muteFlag { a.settings.mute = true }
        return a
    }

    private static func seedValue(_ s: String) -> Int32? {
        if s.hasPrefix("0x") || s.hasPrefix("0X") {
            return UInt32(s.dropFirst(2), radix: 16).map { Int32(bitPattern: $0) }
        }
        return Int32(s)
    }
}
