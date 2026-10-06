import Foundation

/// The keyboard as `GetKeys` reads it (HectorShell `ShellKeyState`'s rules, fed by SDL key events): every key held
/// down, modifier keys included (the Mac's flagsChanged put them in), except Caps Lock — a lock, reported only as
/// the `capsLock` flag. SDL sends a key-up for every key (AppKit swallowed those under ⌘), so no ⌘-release probe.
public struct WinKeyState: Sendable, Equatable {
    public private(set) var held: Set<UInt16> = []

    public init() {}

    public static let capsLockCode: UInt16 = 0x39
    /// Shift, Command, Caps Lock, Option, Control (left and right) and fn — the Mac's flagsChanged keys.
    public static let modifierKeyCodes: Set<UInt16> = [0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F]

    public mutating func keyDown(_ code: UInt16) {
        if code != Self.capsLockCode { held.insert(code) }
    }

    public mutating func keyUp(_ code: UInt16) { held.remove(code) }

    /// The window lost the keyboard.
    public mutating func releaseAll() { held.removeAll() }
}

/// Key names for `--keys` scripts: Carbon `kVK_*` code + the unmodified US `characters`.
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
        return t
    }()
}

/// A `--keys` script: timed input for headless smokes. One command per line; `#` starts a comment; blank lines are
/// skipped. `<frame>` is the main-loop iteration (one fixed 1/60 s step each under `--frames`) at whose start the
/// event is delivered.
///
///     <frame> press <key> [mods…]     key down at <frame>, key up at <frame>+1
///     <frame> down <key> [mods…]      key down (held until an `up`)
///     <frame> up <key> [mods…]
///     <frame> click <x> <y>           mouse down at <frame>, up at <frame>+1 (window canvas pixels, menu strip = 0…19)
///     <frame> move <x> <y>            the pointer moves there (no button change)
///     <frame> text <string…>          layout-aware typed text (SDL text input), as after a key: `press a` then
///                                     `text é` on the same frame types "é" with the A key
///     <frame> caps on|off             Caps Lock's lock state (the pause key)
///     <frame> quit                    the window's close box
///
/// `<key>` is a name from `WinKeyNames` (a–z, 0–9, space, return, enter, tab, delete, esc, left, right, up, down,
/// command, shift, capslock, option, control) or a hex key code `0x..`; `mods` are `cmd`, `shift`, `option`,
/// `control`. Ctrl+Q on Windows is `press q cmd`.
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
            func key(_ i: Int) throws -> (code: UInt16, chars: String, mods: WinModifiers) {
                guard words.count > i else { throw ParseError(line: lineNo, message: "missing key") }
                let name = words[i].lowercased()
                let entry: (code: UInt16, chars: String)
                if let e = WinKeyNames.table[name] {
                    entry = e
                } else if name.hasPrefix("0x"), let code = UInt16(name.dropFirst(2), radix: 16) {
                    entry = (code, "")
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
                var chars = entry.chars
                if mods.contains(.shift), chars.count == 1, let c = chars.first, c.isLetter { chars = chars.uppercased() }
                return (entry.code, chars, mods)
            }
            switch words[1].lowercased() {
            case "press":
                let k = try key(2)
                add(frame, .event(.keyDown(keyCode: k.code, characters: k.chars, modifiers: k.mods, isRepeat: false)))
                add(frame + 1, .event(.keyUp(keyCode: k.code, modifiers: k.mods)))
            case "down":
                let k = try key(2)
                add(frame, .event(.keyDown(keyCode: k.code, characters: k.chars, modifiers: k.mods, isRepeat: false)))
            case "up":
                let k = try key(2)
                add(frame, .event(.keyUp(keyCode: k.code, modifiers: k.mods)))
            case "click":
                guard words.count == 4, let x = Int(words[2]), let y = Int(words[3]) else {
                    throw ParseError(line: lineNo, message: "expected `click <x> <y>`")
                }
                add(frame, .event(.mouseMoved(x: x, y: y)))
                add(frame, .event(.mouseDown(x: x, y: y)))
                add(frame + 1, .event(.mouseUp(x: x, y: y)))
            case "move":
                guard words.count == 4, let x = Int(words[2]), let y = Int(words[3]) else {
                    throw ParseError(line: lineNo, message: "expected `move <x> <y>`")
                }
                add(frame, .event(.mouseMoved(x: x, y: y)))
            case "text":
                guard words.count >= 3 else { throw ParseError(line: lineNo, message: "expected `text <string>`") }
                add(frame, .event(.textInput(words[2...].joined(separator: " "))))
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
