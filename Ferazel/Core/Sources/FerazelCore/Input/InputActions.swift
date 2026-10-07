import Foundation

/// The nine game actions `.IsInputKeyPressed(i) @ 1004a134` answers, i = 0..8 (engine §7.1): bit i set = action i
/// pressed. InputSprocket (prefs+0xa) is not built (design §3.3), so an action is its prefs key code in the `GetKeys`
/// map.
public struct InputActions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt16

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    public static let left = InputActions(rawValue: 1 << 0)
    public static let right = InputActions(rawValue: 1 << 1)
    /// Up / climb.
    public static let up = InputActions(rawValue: 1 << 2)
    /// Down / duck.
    public static let down = InputActions(rawValue: 1 << 3)
    public static let run = InputActions(rawValue: 1 << 4)
    /// Jump / swim.
    public static let jump = InputActions(rawValue: 1 << 5)
    /// Use item / cast.
    public static let use = InputActions(rawValue: 1 << 6)
    public static let previousItem = InputActions(rawValue: 1 << 7)
    public static let nextItem = InputActions(rawValue: 1 << 8)

    /// Action i (0..8) in `.IsInputKeyPressed` numbering.
    public static func action(_ i: Int) -> InputActions {
        precondition((0..<FerazelPrefs.actionCount).contains(i), "action \(i)")
        return InputActions(rawValue: 1 << UInt16(i))
    }

    /// `.IsInputKeyPressed(i)` for i = 0..8 without InputSprocket: `IsPressed(prefs[0x12 + 2i])`.
    public init(keys: KeyState, prefs: FerazelPrefs) {
        var raw: UInt16 = 0
        for (i, code) in prefs.keys.enumerated() where i < FerazelPrefs.actionCount && keys.isPressed(Int(code)) {
            raw |= 1 << UInt16(i)
        }
        self.init(rawValue: raw)
    }
}
