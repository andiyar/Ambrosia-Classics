import Foundation

// The headless `--keys` scripts (plan WF3), adapted from BTX `BTXWinKit/WinInput.swift` (`WinKeyNames`,
// `WinKeyScript`) and `WinScripted.swift` (`WinScriptedInput`): the same syntax, with Ferazel's loop — one line's
// `<frame>` is a loop WAKE (1/240 s; a game tick every 4), and a `press` lasts one game tick so the polled game sees it.

/// Key names for `--keys` scripts: Carbon `kVK_*` code + the unmodified US character.
public enum WinKeyNames {
    public static let table: [String: (code: UInt16, chars: String)] = {
        var t: [String: (UInt16, String)] = [:]
        let letters: [(Character, UInt16)] = [
            ("a", 0x00), ("s", 0x01), ("d", 0x02), ("f", 0x03), ("h", 0x04), ("g", 0x05), ("z", 0x06), ("x", 0x07),
            ("c", 0x08), ("v", 0x09), ("b", 0x0B), ("q", 0x0C), ("w", 0x0D), ("e", 0x0E), ("r", 0x0F), ("y", 0x10),
            ("t", 0x11), ("o", 0x1F), ("u", 0x20), ("i", 0x22), ("p", 0x23), ("l", 0x25), ("j", 0x26), ("k", 0x28),
            ("n", 0x2D), ("m", 0x2E),
        ]
        for (c, code) in letters { t[String(c)] = (code, String(c)) }
        let digits: [UInt16] = [0x1D, 0x12, 0x13, 0x14, 0x15, 0x17, 0x16, 0x1A, 0x1C, 0x19]
        for (n, code) in digits.enumerated() { t[String(n)] = (code, String(n)) }
        t["space"] = (0x31, " ")
        t["return"] = (0x24, "\r")
        t["enter"] = (0x4C, "\u{03}")
        t["tab"] = (0x30, "\t")
        t["delete"] = (0x33, "\u{7F}")
        t["esc"] = (0x35, "\u{1B}")
        t["left"] = (0x7B, "\u{F702}")
        t["right"] = (0x7C, "\u{F703}")
        t["down"] = (0x7D, "\u{F701}")
        t["up"] = (0x7E, "\u{F700}")
        t["command"] = (0x37, "")
        t["shift"] = (0x38, "")
        t["capslock"] = (0x39, "")
        t["option"] = (0x3A, "")
        t["control"] = (0x3B, "")
        t["rcommand"] = (0x36, "")
        t["rshift"] = (0x3C, "")
        t["roption"] = (0x3D, "")
        t["rcontrol"] = (0x3E, "")
        return t
    }()
}

/// A `--keys` script: timed input for headless runs. One command per line; `#` starts a comment; blank lines are
/// skipped. `<frame>` is the loop wake (0-based; 240 a second under `--frames`, a game tick every 4) at whose start the
/// event is delivered.
///
///     <frame> press <key> [mods…]     key down at <frame>, key up at <frame>+4 (one game tick)
///     <frame> down <key> [mods…]      key down (held until an `up`)
///     <frame> up <key> [mods…]
///     <frame> click <x> <y>           pointer there + button down at <frame>, up at <frame>+4 (canvas pixels)
///     <frame> move <x> <y>            the pointer moves there (no button change)
///     <frame> caps on|off             Caps Lock's lock state (the pause key)
///     <frame> quit                    the window's close box
///
/// `<key>` is a name from `WinKeyNames` (a–z, 0–9, space, return, enter, tab, delete, esc, left, right, up, down,
/// command, shift, capslock, option, control, rcommand, rshift, roption, rcontrol) or a hex key code `0x..`; `mods`
/// are `cmd`/`ctrl` (Ctrl = ⌘), `shift`, `option`/`alt`, `control` (the Windows key). Ctrl+Q is `press q ctrl`.
public struct WinKeyScript: Sendable, Equatable {
    public enum Action: Sendable, Equatable {
        case event(WinEvent)
        case capsLock(Bool)
    }

    public struct ParseError: Error, Equatable, CustomStringConvertible {
        public let line: Int
        public let message: String
        public var description: String { "--keys line \(line): \(message)" }
    }

    /// Wakes a `press` / `click` lasts: one game tick.
    public static let pressWakes = 4

    /// Actions by frame, in file order.
    public private(set) var actions: [Int: [Action]] = [:]

    public init() {}

    public init(text: String) throws {
        for (index, raw) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let lineNo = index + 1
            let line = raw.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first ?? ""
            let words = line.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\r" }).map(String.init)
            if words.isEmpty { continue }
            guard words.count >= 2, let frame = Int(words[0]), frame >= 0 else {
                throw ParseError(line: lineNo, message: "expected `<frame> <command> …`")
            }
            func key(_ i: Int) throws -> (code: UInt16, mods: WinModifiers) {
                guard words.count > i else { throw ParseError(line: lineNo, message: "missing key") }
                let name = words[i].lowercased()
                let code: UInt16
                if let e = WinKeyNames.table[name] {
                    code = e.code
                } else if name.hasPrefix("0x"), let c = UInt16(name.dropFirst(2), radix: 16) {
                    code = c
                } else {
                    throw ParseError(line: lineNo, message: "unknown key \(words[i])")
                }
                var mods: WinModifiers = []
                for m in words.dropFirst(i + 1) {
                    switch m.lowercased() {
                    case "cmd", "command", "ctrl": mods.insert(.command)
                    case "shift": mods.insert(.shift)
                    case "option", "alt": mods.insert(.option)
                    case "control": mods.insert(.control)
                    default: throw ParseError(line: lineNo, message: "unknown modifier \(m)")
                    }
                }
                return (code, mods)
            }
            func point() throws -> (Int, Int) {
                guard words.count == 4, let x = Int(words[2]), let y = Int(words[3]) else {
                    throw ParseError(line: lineNo, message: "expected `\(words[1]) <x> <y>`")
                }
                return (x, y)
            }
            switch words[1].lowercased() {
            case "press":
                let k = try key(2)
                add(frame, .event(.keyDown(keyCode: k.code, modifiers: k.mods, isRepeat: false)))
                add(frame + Self.pressWakes, .event(.keyUp(keyCode: k.code)))
            case "down":
                let k = try key(2)
                add(frame, .event(.keyDown(keyCode: k.code, modifiers: k.mods, isRepeat: false)))
            case "up":
                let k = try key(2)
                add(frame, .event(.keyUp(keyCode: k.code)))
            case "click":
                let (x, y) = try point()
                add(frame, .event(.mouseMoved(x: x, y: y)))
                add(frame, .event(.mouseDown(x: x, y: y)))
                add(frame + Self.pressWakes, .event(.mouseUp(x: x, y: y)))
            case "move":
                let (x, y) = try point()
                add(frame, .event(.mouseMoved(x: x, y: y)))
            case "caps":
                guard words.count == 3, words[2] == "on" || words[2] == "off" else {
                    throw ParseError(line: lineNo, message: "expected `caps on|off`")
                }
                add(frame, .capsLock(words[2] == "on"))
            case "quit":
                add(frame, .event(.quit))
            default:
                throw ParseError(line: lineNo, message: "unknown command \(words[1])")
            }
        }
    }

    private mutating func add(_ frame: Int, _ action: Action) {
        actions[frame, default: []].append(action)
    }

    /// The actions due at `frame`.
    public func actions(at frame: Int) -> [Action] { actions[frame] ?? [] }
}

/// The deterministic side of a headless run (`--frames` / `--keys`, Ruling 20), shared by `FerazelWin` and the tests:
/// a fixed-step clock — exactly 1/240 s per loop wake, a game tick every 4, from `baseTick` — and the script's input,
/// with the modifier state the script implies (the real keyboard is never read).
public struct WinScriptedInput: Sendable {
    public let script: WinKeyScript
    /// The loop wake (0-based); `advance()` moves it on.
    public private(set) var frame = 0
    /// The modifiers held per the script (Caps Lock = its lock state).
    public private(set) var modifiers: WinModifiers = []
    /// TickCount at the first wake (the shared driver tests' first tick, `Rig`).
    public static let baseTick: UInt32 = 1000
    public static let wakesPerTick = 4
    public static let wakesPerSecond = 240

    public init(script: WinKeyScript = WinKeyScript()) {
        self.script = script
    }

    /// TickCount at the current wake.
    public var ticks: UInt32 { Self.baseTick &+ UInt32(truncatingIfNeeded: frame / Self.wakesPerTick) }

    /// Seconds since the first wake (the pad's hold timer).
    public var seconds: Double { Double(frame) / Double(Self.wakesPerSecond) }

    /// This wake's events (the modifier state updated as they go).
    public mutating func events() -> [WinEvent] {
        var out: [WinEvent] = []
        for action in script.actions(at: frame) {
            switch action {
            case .capsLock(let on):
                if on { modifiers.insert(.capsLock) } else { modifiers.remove(.capsLock) }
            case .event(let e):
                switch e {
                case let .keyDown(code, mods, _):
                    modifiers = mods.union(modifiers.intersection(.capsLock))
                    if let m = Self.modifierFlag(code) { modifiers.insert(m) }
                case let .keyUp(code):
                    if let m = Self.modifierFlag(code) { modifiers.remove(m) }
                default:
                    break
                }
                out.append(e)
            }
        }
        return out
    }

    public mutating func advance() { frame += 1 }

    /// Moves the clock on `n` wakes without delivering their events (a test's late wake).
    public mutating func skip(_ n: Int) { frame += n }

    private static func modifierFlag(_ code: UInt16) -> WinModifiers? {
        switch code {
        case 0x37, 0x36: .command
        case 0x38, 0x3C: .shift
        case 0x3A, 0x3D: .option
        case 0x3B, 0x3E: .control
        default: nil
        }
    }
}
