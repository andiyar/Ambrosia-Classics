import Foundation

/// One player's controls for one tick, bit for bit the film's per-player input byte
/// (engine-loop §7): left 0, right 1, up 2, down 3, fire ground 4, fire air 5, select 6.
/// ★ LOCKED seam (plan S3).
public struct PlayerInput: OptionSet, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let left = PlayerInput(rawValue: 1 << 0)
    public static let right = PlayerInput(rawValue: 1 << 1)
    public static let up = PlayerInput(rawValue: 1 << 2)
    public static let down = PlayerInput(rawValue: 1 << 3)
    public static let fireGround = PlayerInput(rawValue: 1 << 4)
    public static let fireAir = PlayerInput(rawValue: 1 << 5)
    public static let select = PlayerInput(rawValue: 1 << 6)
}
