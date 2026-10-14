import Foundation

/// One 10-byte inventory slot at `G+0x24 + 10·k`, `k < 27` (spells-items §1; `.InitGameGlobals` M l. 615–673,
/// `.HasItem @ 1004c0e0`, `.RemoveItem @ 10045594`). Byte `+9` is never accessed (a gap: written 0, not stored).
public struct InventorySlot: Equatable, Sendable {
    /// `+0` id (−1 = empty; spell and item ids are separate namespaces).
    public var id: Int16
    /// `+2` count (clamped to 99 on pickup).
    public var count: Int16
    /// `+4` (−1 at init; no reader traced).
    public var field4: Int16
    /// `+6` (0 at init).
    public var field6: Int16
    /// `+8` u8: 1 = spell slot, 0 = item slot.
    public var isSpell: UInt8

    public static let byteCount = 10

    public init(id: Int16, count: Int16, field4: Int16, field6: Int16, isSpell: UInt8) {
        self.id = id
        self.count = count
        self.field4 = field4
        self.field6 = field6
        self.isSpell = isSpell
    }

    /// The empty slot `.InitGameGlobals` writes into slots 2…26: {−1, 0, −1, 0, 0}.
    public static let empty = InventorySlot(id: -1, count: 0, field4: -1, field6: 0, isSpell: 0)
}
