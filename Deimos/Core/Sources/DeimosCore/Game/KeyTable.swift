import Foundation

/// The prefs key table (`+0x14b8…+0x14ec`, timing-frame §6) as the game's input: the held Mac virtual key
/// codes → each player's `PlayerInput` for one poll. Fresh prefs: P1 ↑ ← → ↓ ⌘ ⌥ Space (0x7E 0x7B 0x7C 0x7D
/// 0x37 0x3A 0x31), P2 kp8 kp4 kp6 kp5 End Fwd-Del PgDn (0x5B 0x56 0x58 0x57 0x77 0x75 0x79). ★ Public in Core
/// (C6 review ruling; plan S5/H1 amended): `DeimosSession.pass(keys:)` maps through it.
///
/// Slot order per player: up, left, right, down, then three buttons. The buttons' meaning is LOW: the table's
/// consumer is the OS X key path the bank has not resolved (engine-loop §8, INDEX #14), and the bank's
/// InputSprocket order differs from the table's (engine-loop §7 film byte: left, right, up, down, fire ground,
/// fire air, select; §8 needs: the two axes, then fire ground, fire air, select). The mapping here is pinned to
/// the guide's defaults (design §7.3): slot 4 ⌘ = fire air, slot 5 ⌥ = fire ground, slot 6 Space = select.
public struct KeyTable: Equatable, Sendable {
    /// The 14 codes, P1's seven then P2's (stored as 4-byte ints on disk — Phase 4).
    public var codes: [UInt16]

    /// The `PlayerInput` bit of each slot, in slot order.
    public static let slotBits: [PlayerInput] = [.up, .left, .right, .down, .fireAir, .fireGround, .select]

    public init(codes: [UInt16]) { self.codes = codes }

    public init(prefs: DeimosPrefs) { self.init(codes: prefs.keyTable) }

    /// Player `player`'s (0 or 1) input: each slot whose code is held. A table shorter than 14 leaves the
    /// missing slots unmapped.
    public func input(_ keys: HeldKeys, player: Int) -> PlayerInput {
        var out: PlayerInput = []
        let base = Self.slotBits.count * player
        for (slot, bit) in Self.slotBits.enumerated() {
            let k = base + slot
            if k < codes.count && keys.held.contains(codes[k]) { out.insert(bit) }
        }
        return out
    }

    /// P1's then P2's input.
    public func inputs(_ keys: HeldKeys) -> [PlayerInput] {
        [input(keys, player: 0), input(keys, player: 1)]
    }
}
