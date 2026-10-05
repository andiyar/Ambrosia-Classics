import Foundation

/// One control key set: a name (< 10 characters in the prefs UI, stored as a 12-byte C string) and five Mac
/// virtual key codes in the order `_SetKeySetPref @ 00027030` / `_GetKeySetPref @ 00027140` store them and
/// `_InitControls` reads them: left, right, up, down, push (the "fire" key — the hero pushes blocks).
/// Prefs blob slot n = 1…20 at `0x2be + 22(n−1)` (data-formats §9).
public struct KeySet: Equatable, Sendable {
    public var name: String
    public var left: UInt16
    public var right: UInt16
    public var up: UInt16
    public var down: UInt16
    public var push: UInt16

    public init(name: String, left: UInt16, right: UInt16, up: UInt16, down: UInt16, push: UInt16) {
        self.name = name
        self.left = left
        self.right = right
        self.up = up
        self.down = down
        self.push = push
    }

    /// The five codes in stored order: left, right, up, down, push.
    public var codes: [UInt16] { [left, right, up, down, push] }

    /// Sets 1–8 as `_AlexPrefsKeysInit @ 0000f790` writes them (FI §4). Index 0 = set 1.
    public static let builtIn: [KeySet] = [
        KeySet(name: "Default", left: 0x7b, right: 0x7c, up: 0x7e, down: 0x7d, push: 0x31),   // ← → ↑ ↓ Space
        KeySet(name: "Keypad 1", left: 0x56, right: 0x58, up: 0x5b, down: 0x54, push: 0x31),  // kp4 kp6 kp8 kp2 Space
        KeySet(name: "Keypad 2", left: 0x56, right: 0x58, up: 0x5b, down: 0x57, push: 0x31),  // kp4 kp6 kp8 kp5 Space
        KeySet(name: "Keypad 3", left: 0x56, right: 0x58, up: 0x5b, down: 0x54, push: 0x52),  // kp4 kp6 kp8 kp2 kp0
        KeySet(name: "Keypad 4", left: 0x56, right: 0x58, up: 0x5b, down: 0x57, push: 0x52),  // kp4 kp6 kp8 kp5 kp0
        KeySet(name: "Keyboard", left: 0x26, right: 0x25, up: 0x22, down: 0x28, push: 0x31),  // J L I K Space
        KeySet(name: "Classic", left: 0x06, right: 0x07, up: 0x27, down: 0x2c, push: 0x31),   // Z X ' / Space
        KeySet(name: "Spectrum", left: 0x0c, right: 0x0d, up: 0x0e, down: 0x0f, push: 0x11),  // Q W E R T
    ]
}
