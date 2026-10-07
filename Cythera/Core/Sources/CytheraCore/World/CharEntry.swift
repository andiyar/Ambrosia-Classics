/// A packed world location `level << 24 | x << 12 | y` (CharEntry +0, schedule +4, 0xF00C teleports;
/// `TeleportTo__8TGameSysFsss @ 10050e98`, data-format §3.1/§6.1, HIGH).
public struct WorldLocation: Equatable, Hashable, Sendable {
    public let level: Int
    public let x: Int
    public let y: Int
    public init(level: Int, x: Int, y: Int) { self.level = level; self.x = x; self.y = y }
    public init(packed v: UInt32) { level = Int(v >> 24); x = Int((v >> 12) & 0xFFF); y = Int(v & 0xFFF) }
}

/// One 0x20-byte `CharEntry` (data-format §6.1). Field names per the bank's table; confidence there.
public struct CharEntry: Equatable, Sendable {
    public static let size = 0x20
    public let bytes: [UInt8]

    init(bytes: [UInt8]) { self.bytes = bytes }

    private func u16(_ o: Int) -> UInt16 { be16(bytes, o) }

    public var isEmpty: Bool { bytes.allSatisfy { $0 == 0 } }

    /// +0x00 u32 packed location.
    public var packedLocation: UInt32 {
        be32(bytes, 0)
    }
    public var location: WorldLocation { WorldLocation(packed: packedLocation) }
    /// +0x04 u16 current type (bits 0–9) + frame (bits 10–14), copied to prop i (`CueCharacters`).
    public var typeFrame: UInt16 { u16(4) }
    public var type: Int { Int(typeFrame & 0x3FF) }
    public var frame: Int { Int(typeFrame >> 10) & 0x1F }
    /// +0x06 u16 status flags (bit 0 alive; 0x2 poisoned; 0x40 paralyzed; 0x4000 asleep; …).
    public var status: UInt16 { u16(6) }
    public var isAlive: Bool { status & 1 != 0 }
    /// +0x08 u8 flags: 0x40 party member, 0x80 name known.
    public var flags: UInt8 { bytes[8] }
    public var isPartyMember: Bool { flags & 0x40 != 0 }
    /// +0x09 Body, +0x0A Reflex, +0x0B Mind.
    public var body: UInt8 { bytes[9] }
    public var reflex: UInt8 { bytes[0x0A] }
    public var mind: UInt8 { bytes[0x0B] }
    /// +0x0C u16 Experience.
    public var experience: UInt16 { u16(0x0C) }
    /// +0x0E/+0x0F Health current/max; +0x10/+0x11 Magic current/max.
    public var health: UInt8 { bytes[0x0E] }
    public var healthMax: UInt8 { bytes[0x0F] }
    public var magic: UInt8 { bytes[0x10] }
    public var magicMax: UInt8 { bytes[0x11] }
    /// +0x12 busy ticks (time debt; script field 0x23).
    public var busyTicks: UInt8 { bytes[0x12] }
    /// +0x13 Level.
    public var level: UInt8 { bytes[0x13] }
    /// +0x14 u16 "home" type/frame (restored by `RepositionChar`; MED).
    public var home: UInt16 { u16(0x14) }
    /// +0x16 current schedule activity (MED).
    public var activity: UInt8 { bytes[0x16] }
    /// +0x17 merchant markup, tenths of base price (script field 0x27).
    public var markup: UInt8 { bytes[0x17] }
    /// +0x18 smooth-move sub-step state.
    public var subStep: UInt8 { bytes[0x18] }
    /// +0x19 alignment: 0 neutral, 1 evil, 2 good, 3 feral.
    public var alignment: UInt8 { bytes[0x19] }
    /// +0x1A condition flags bits 0x18–0x1F (MED).
    public var conditionFlagsHigh: UInt8 { bytes[0x1A] }
    /// +0x1B food hours remaining (MED).
    public var food: UInt8 { bytes[0x1B] }
    /// +0x1C Training points.
    public var training: UInt8 { bytes[0x1C] }
    /// +0x1D character class (script field 0x20; MED for the word).
    public var characterClass: UInt8 { bytes[0x1D] }
    /// +0x1E combat behaviour / activity code (< 0xB0 built-in, ≥ 0xB0 user AI slot).
    public var behaviour: UInt8 { bytes[0x1E] }
    /// +0x1F spawn scale % of a spawned monster (entries 0x100–0x1FF; combat.md §4.1).
    public var spawnScale: UInt8 { bytes[0x1F] }
}
