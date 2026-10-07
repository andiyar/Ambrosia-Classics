/// One 8-byte schedule entry (data-format §6.3, HIGH layout).
public struct ScheduleEntry: Equatable, Sendable {
    public static let size = 8
    /// +0 hour (0..23) the entry starts.
    public let hour: UInt8
    /// +1 activity code → CharEntry +0x16 / prop +7.
    public let activity: UInt8
    /// +2 condition opcode (`EvalCondition`, rules.md §3).
    public let conditionOp: UInt8
    /// +3 condition argument.
    public let conditionArg: UInt8
    /// +4 u32 packed location; 0 = block header.
    public let packedLocation: UInt32
    public var location: WorldLocation { WorldLocation(packed: packedLocation) }
}

/// 0xF00B, the schedules (data-format §6.3, HIGH): 256 × i16 counts (0x200 bytes), then each character's
/// `count` 8-byte entries in order (`LoadGlobals__Fv @ 10005798` tail). `WorldGlobals` refuses a negative count
/// and a segment that is not exactly `0x200 + 8·Σcount` (617 entries, 5,448 B shipped).
public struct ScheduleTable: Equatable, Sendable {
    public let counts: [Int16]
    /// Per character 0..255.
    public let entries: [[ScheduleEntry]]
    init(counts: [Int16], entries: [[ScheduleEntry]]) { self.counts = counts; self.entries = entries }
}
