import Foundation

/// The save block (`_DAT_100a0054`, `NewHandleClear(0xebe58)` in `.InitAppGlobals`, M l. 345) = the body of a saved
/// game's `'FWSg'` id 0 resource (save-continue §3.3, engine §9). Big-endian, every field at its offset; the bytes no
/// routine accesses are gaps — not stored, written 0 (Phase 3 Invariant 7): `+0x07`, `+0x0a..+0x0b`, `+0x14..+0x17`,
/// `+0x19994..+0x19997`, the 512th 16-byte slot of each level's snapshot, `0xe1998..0xe7d97` (levels ≥ 100), the bytes
/// of the world-name field past its length, `0xe7e98..0xebe57`.
public struct SaveBlock: Equatable, Sendable {
    public static let byteCount = 0xebe58
    /// Offset of the G copy (`addi r5,r3,0x10` + `stwu r3,0x8(r5)`: first store at +0x18, raw `1000c1cc..1000c1e0`).
    public static let globalsOffset = 0x18
    public static let dateOffset = 0x19990
    /// Level L's snapshot: `0x19998 + 0x2000·L + 16·i`, `L < 100`, `i < 511`.
    public static let snapshotOffset = 0x19998
    public static let snapshotStride = 0x2000
    public static let snapshotLevels = 100
    public static let worldNameOffset = 0xe7d98

    /// `+0x00` u32 the world stamp (`Mwld+0x100`, `WorldFile.stamp`).
    public var worldStamp: UInt32 = 0
    /// `+0x04` u8 "preview version" flag (resume refuses 1).
    public var preview: UInt8 = 0
    /// `+0x05` u8 "demo version" flag (resume refuses 1).
    public var demo: UInt8 = 0
    /// `+0x06` u8: 1 = checkpoint / level-end save (restore the snapshot); `.InitGameGlobals`' tail writes 0 (F1b).
    public var isCheckpoint: UInt8 = 0
    /// `+0x08` i16 level number.
    public var level: Int16 = 0
    /// `+0x0c` i32 player x (sprite top-left px; the i16 global sign-extended).
    public var playerX: Int32 = 0
    /// `+0x10` i32 player y.
    public var playerY: Int32 = 0
    /// `+0x18` the copy of G (0x19978 B).
    public var globals: GameGlobals
    /// `+0x19990` u32 `GetDateTime` (seconds since 1904).
    public var date: UInt32 = 0
    /// `snapshots[L][i]` = the record stored at `0x19998 + 0x2000·L + 16·i` (100 × 511), as stored (x/y −6);
    /// `restoreSnapshot(level:)` adds the 6 back. `index` = i.
    public var snapshots: [[Placement]]
    /// `+0xe7d98` pstr world file name, its Mac Roman bytes (no length byte). Read by `.ContinueGame`'s fallback branch;
    /// written only by `.DoSaveGame`, which is unreachable in 1.0.3 (DITL 202 has 4 items, raw `100068b4`, BC26) — so no
    /// writer here touches it.
    public var worldName: [UInt8] = []

    /// The cleared block (`NewHandleClear`): every byte 0, G included.
    public init() {
        globals = GameGlobals()
        snapshots = (0..<SaveBlock.snapshotLevels).map { _ in
            (0..<LevelFile.placementCount).map {
                Placement(index: $0, flag: 0, byte1: 0, type: 0, p1: 0, p2: 0, p3: 0, p4: 0, y: 0, x: 0)
            }
        }
    }

    /// Reads every field back from a save-block image (≥ 0xebe58 bytes; no other check — the original makes none).
    public init(image: Data) throws {
        let b = BigEndianBytes(image, type: "FWSg", id: 0)
        _ = try b.u8(SaveBlock.byteCount - 1)
        worldStamp = try b.u32(0x00)
        preview = try b.u8(0x04)
        demo = try b.u8(0x05)
        isCheckpoint = try b.u8(0x06)
        level = try b.i16(0x08)
        playerX = Int32(bitPattern: try b.u32(0x0c))
        playerY = Int32(bitPattern: try b.u32(0x10))
        globals = try GameGlobals(b, at: SaveBlock.globalsOffset)
        date = try b.u32(SaveBlock.dateOffset)
        snapshots = try (0..<SaveBlock.snapshotLevels).map { L in
            try (0..<LevelFile.placementCount).map { i in
                try Placement(b, at: SaveBlock.snapshotOffset + SaveBlock.snapshotStride * L + 16 * i, index: i)
            }
        }
        let n = Int(try b.u8(SaveBlock.worldNameOffset))
        worldName = Array(b.bytes[(SaveBlock.worldNameOffset + 1)..<(SaveBlock.worldNameOffset + 1 + n)])
    }

    /// The 0xebe58-byte big-endian image, every field at its offset, gaps 0.
    public func image() -> Data {
        precondition(snapshots.count == SaveBlock.snapshotLevels
                     && snapshots.allSatisfy { $0.count == LevelFile.placementCount }, "snapshots must be 100 × 511")
        precondition(worldName.count <= 255, "world name over 255 bytes")
        var w = BigEndianWriter(count: SaveBlock.byteCount)
        w.u32(0x00, worldStamp)
        w.u8(0x04, preview)
        w.u8(0x05, demo)
        w.u8(0x06, isCheckpoint)
        w.i16(0x08, level)
        w.u32(0x0c, UInt32(bitPattern: playerX))
        w.u32(0x10, UInt32(bitPattern: playerY))
        globals.write(into: &w, at: SaveBlock.globalsOffset)
        w.u32(SaveBlock.dateOffset, date)
        for (L, records) in snapshots.enumerated() {
            for (i, r) in records.enumerated() {
                r.write(into: &w, at: SaveBlock.snapshotOffset + SaveBlock.snapshotStride * L + 16 * i)
            }
        }
        w.u8(SaveBlock.worldNameOffset, UInt8(worldName.count))
        for (k, c) in worldName.enumerated() { w.u8(SaveBlock.worldNameOffset + 1 + k, c) }
        return Data(w.bytes)
    }

    /// `.SavePointSave @ 1000c104` (M l. 6322ff; raw `1000c104…`), the block part, in raw order: stamp (`1000c16c`),
    /// date, `+6 = 1` (`1000c1a0`), `+8 = level` (`1000c1b0`), the live `globals.hasSnapshot[L] = 1` (`1000c1c0`)
    /// **before** the G copy (`1000c1cc..1000c1e0`, so the copy carries the flag), x / y sign-extended (`1000c204`,
    /// `1000c214`), `+4 = +5 = 0` (`1000c220`, `1000c22c`), then the 511 live records (`world.records`) with x (+0xe)
    /// and y (+0xc) each −6 (`1000c2a4..1000c2d8`). The file write (`SaveSG`) and the redraw are the caller's.
    public mutating func savePointSave(level: Int16, x: Int16, y: Int16, stamp: UInt32, date: UInt32,
                                       globals: inout GameGlobals, records: [Placement]) {
        writeSnapshotSave(level: level, x: x, y: y, stamp: stamp, date: date, globals: &globals, records: records,
                          clearsVersionFlags: true)
    }

    /// `.EndLevelSGUpdate @ 1000c8d8` (M l. 6501ff): `savePointSave` without the `+4/+5` stores (and without
    /// `InputActivate` / `SaveSG` — memory only).
    public mutating func endLevelSGUpdate(level: Int16, x: Int16, y: Int16, stamp: UInt32, date: UInt32,
                                          globals: inout GameGlobals, records: [Placement]) {
        writeSnapshotSave(level: level, x: x, y: y, stamp: stamp, date: date, globals: &globals, records: records,
                          clearsVersionFlags: false)
    }

    /// The level-L snapshot as the game restores it: the 511 stored records with +6 on x and y (`.SetupLevel`
    /// M l. 2405–2409, `.ContinueGame` M l. 6744–6747).
    public func restoreSnapshot(level: Int16) -> [Placement] {
        snapshots[Int(level)].map { $0.moved(by: 6) }
    }

    private mutating func writeSnapshotSave(level L: Int16, x: Int16, y: Int16, stamp: UInt32, date: UInt32,
                                            globals g: inout GameGlobals, records: [Placement],
                                            clearsVersionFlags: Bool) {
        precondition((0..<SaveBlock.snapshotLevels).contains(Int(L)), "level outside the 100 snapshot slots")
        precondition(records.count == LevelFile.placementCount, "the 511 live records")
        worldStamp = stamp
        self.date = date
        isCheckpoint = 1
        level = L
        g.hasSnapshot[Int(L)] = 1
        globals = g
        playerX = Int32(x)
        playerY = Int32(y)
        if clearsVersionFlags {
            preview = 0
            demo = 0
        }
        snapshots[Int(L)] = records.enumerated().map { i, r in r.reindexed(i).moved(by: -6) }
    }
}

/// Big-endian stores into a zero-filled byte image (the writer side of `BigEndianBytes`).
struct BigEndianWriter {
    var bytes: [UInt8]

    init(count: Int) { bytes = [UInt8](repeating: 0, count: count) }

    mutating func u8(_ o: Int, _ v: UInt8) { bytes[o] = v }

    mutating func u16(_ o: Int, _ v: UInt16) {
        bytes[o] = UInt8(v >> 8)
        bytes[o + 1] = UInt8(v & 0xff)
    }

    mutating func i16(_ o: Int, _ v: Int16) { u16(o, UInt16(bitPattern: v)) }

    mutating func u32(_ o: Int, _ v: UInt32) {
        u16(o, UInt16(v >> 16))
        u16(o + 2, UInt16(v & 0xffff))
    }

    mutating func i16Array(_ o: Int, _ values: [Int16]) {
        for (k, v) in values.enumerated() { i16(o + 2 * k, v) }
    }
}
