import Foundation

/// The deterministic side of a headless smoke (`--frames` / `--keys`), shared by `BubbleTroubleXWin` and the tests: a
/// fixed-step clock (one TickCount, 1/60 s, per main-loop iteration — so frame dumps are reproducible on any machine)
/// and the script's input, with the modifier state the script implies (the real keyboard is never read).
public struct WinScriptedInput: Sendable {
    public let script: WinKeyScript
    /// The main-loop iteration (0-based); `advance()` moves it on.
    public private(set) var frame = 0
    /// The modifiers held per the script (Caps Lock = its lock state).
    public private(set) var modifiers: WinModifiers = []
    /// The virtual clock starts here (an arbitrary uptime: TickCount 100 000, as a machine up for ~28 minutes).
    public static let baseTick: UInt64 = 100_000

    public init(script: WinKeyScript = WinKeyScript()) {
        self.script = script
    }

    /// The fixed-step clock at the current iteration.
    public var nanoseconds: UInt64 { WinClock.nanoseconds(atTick: Self.baseTick + UInt64(frame)) }

    /// This iteration's events (modifier state updated as they go).
    public mutating func events() -> [WinEvent] {
        var out: [WinEvent] = []
        for action in script.actions(at: frame) {
            switch action {
            case .capsLock(let on):
                if on { modifiers.insert(.capsLock) } else { modifiers.remove(.capsLock) }
            case .event(let e):
                switch e {
                case let .keyDown(code, _, mods, _):
                    modifiers = mods.union(modifiers.intersection(.capsLock))
                    if let m = Self.modifierFlag(code) { modifiers.insert(m) }
                case let .keyUp(code, _):
                    if let m = Self.modifierFlag(code) { modifiers.remove(m) }
                    else { modifiers = modifiers.intersection(.capsLock) }
                default:
                    break
                }
                out.append(e)
            }
        }
        return out
    }

    public mutating func advance() { frame += 1 }

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
