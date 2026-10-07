/// One 16-byte 0xF008 creature-species record = script class 0x48 (combat.md §4, HIGH bytes/readers, MED role
/// names). `ObjToMonst__Fs @ 10044a60` scans 128 records keyed by the object type at +0xC, stopping at type 0.
public struct CreatureRecord: Equatable, Sendable {
    public static let size = 16
    public let bytes: [UInt8]

    init(bytes: [UInt8]) { self.bytes = bytes }

    private func u16(_ o: Int) -> UInt16 { UInt16(bytes[o]) << 8 | UInt16(bytes[o + 1]) }

    /// Byte 0: base Body (field 0x2C).
    public var body: UInt8 { bytes[0] }
    /// Byte 1: base Reflex (0x2D).
    public var reflex: UInt8 { bytes[1] }
    /// Byte 2: base Mind (0x2E).
    public var mind: UInt8 { bytes[2] }
    /// Byte 3: natural armour (0x30).
    public var armour: UInt8 { bytes[3] }
    /// Byte 4: natural damage base (0x31).
    public var damage: UInt8 { bytes[4] }
    /// Byte 5: base Health (0x2F).
    public var health: UInt8 { bytes[5] }
    /// Byte 6: alignment → CharEntry +0x19 (0x35).
    public var alignment: UInt8 { bytes[6] }
    /// Byte 7: no reader found (open-items-2026-10-06 §2); 0 in all 50 used records.
    public var byte7: UInt8 { bytes[7] }
    /// Bytes 8–9: flags A (field 0x33).
    public var flagsA: UInt16 { u16(8) }
    /// Bytes 10–11: flags B, resistances (field 0x32).
    public var flagsB: UInt16 { u16(10) }
    /// Bytes 12–13: the object-type key; 0 ends the table.
    public var objectType: UInt16 { u16(12) }
    /// Bytes 14–15: s16 corpse item (type | frame << 10) created on death, 0 = none (field 0x36).
    public var corpse: Int16 { Int16(bitPattern: u16(14)) }
}
