import Foundation

/// The keyboard as `GetKeys` returns it: a 128-bit map of Mac virtual key codes, 16 bytes; key `k` is bit `k & 7`
/// of byte `k >> 3` (`IsPressed`, engine §7.1). The shell fills it each step; Core never reads a keyboard.
public struct KeyState: Equatable, Sendable {
    public static let byteCount = 16

    /// The `KeyMap` bytes.
    public private(set) var bytes: [UInt8]

    public init() {
        bytes = [UInt8](repeating: 0, count: Self.byteCount)
    }

    /// A key map with these key codes (0..127) down.
    public init(pressed keyCodes: [Int]) {
        self.init()
        for k in keyCodes { press(k) }
    }

    /// `IsPressed(k)`; key codes outside 0..127 are never down.
    public func isPressed(_ keyCode: Int) -> Bool {
        guard (0..<(Self.byteCount * 8)).contains(keyCode) else { return false }
        return bytes[keyCode >> 3] >> (keyCode & 7) & 1 != 0
    }

    public mutating func press(_ keyCode: Int) {
        guard (0..<(Self.byteCount * 8)).contains(keyCode) else { return }
        bytes[keyCode >> 3] |= 1 << UInt8(keyCode & 7)
    }

    public mutating func release(_ keyCode: Int) {
        guard (0..<(Self.byteCount * 8)).contains(keyCode) else { return }
        bytes[keyCode >> 3] &= ~(1 << UInt8(keyCode & 7))
    }
}
