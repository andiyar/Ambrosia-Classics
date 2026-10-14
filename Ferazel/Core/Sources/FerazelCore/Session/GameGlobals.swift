import Foundation

/// One crunched tile in the game globals' log (`G+0x12d8+n` = the level byte `(char)*_DAT_1009feac`,
/// `G+0x60f8+4n` = row, `G+0x60fa+4n` = column; `.CrunchTile` raw `10044bc8..10044c14`).
public struct CrunchLogEntry: Equatable, Sendable {
    public var level: Int8
    public var col: Int16
    public var row: Int16

    public init(level: Int8, col: Int16, row: Int16) {
        self.level = level
        self.col = col
        self.row = row
    }
}

/// The game-globals block `G` (`_DAT_1009ffc0`; engine §9, save-continue §3.3) — all 0x19978 bytes by named field,
/// as the PPC lays them out (big-endian; `image()` / `init(image:)`). Never-accessed bytes are gaps: not stored, written
/// 0 (Phase 3 Invariant 7): `+0x18..+0x1f`, `+0x21`, byte `+9` of each inventory slot (see `InventorySlot`), `+0x132..+0x171`, `+0x175`.
/// No pointers in G. Start values: `.InitGameGlobals @ 10001498` (M l. 582–825; `initGameGlobals(previous:)`).
/// `+0x16` (start facing) is the header's 0x26c8, copied by `.NewGame` before `.GameLoop` (M l. 5821).
public struct GameGlobals: Equatable, Sendable {
    public static let byteCount = 0x19978
    /// Inventory slots at `+0x24` (27 × 10 B).
    public static let inventorySlots = 27
    /// Per-level arrays (`hasSnapshot`, `unlocked`, each row of `achieved` / `totals`): 100 i16.
    public static let levelSlots = 100
    /// Rows of `achieved` / `totals` (stride 200 B; `.InitGameGlobals` zeroes all 5, M l. 725–761).
    public static let counterRows = 5
    /// `worldFlags` at `+0xad8`: 1024 i16 (M l. 712–723).
    public static let worldFlagCount = 1024
    /// The crunch log's capacity (`+0xad6` count < 20000).
    public static let crunchCapacity = 20000

    /// `+0x00` (u32 in the binary; `stw`, drawn by `.UpdateTextStats`).
    public var score: Int32 = 0
    /// `+0x04`.
    public var health: Int16 = 0
    /// `+0x06` (oxygen).
    public var breath: Int16 = 0
    /// `+0x08` suffocation countdown.
    public var suffocation: Int16 = 0
    /// `+0x0a`.
    public var maxHealth: Int16 = 0
    /// `+0x0c`.
    public var maxMagic: Int16 = 0
    /// `+0x0e`.
    public var magic: Int16 = 0
    /// `+0x10`.
    public var coins: Int16 = 0
    /// `+0x12` (write-only, save-continue §8.1).
    public var unread12: Int16 = 0
    /// `+0x14` gold-Xichron counter.
    public var xichrons: Int16 = 0
    /// `+0x16` start facing (≠ 0 → left). Not written by `.InitGameGlobals`.
    public var startFacing: Int16 = 0
    /// `+0x20` u8 darkness override (`.SetupLevel`, M l. 2376–2381). Not written by `.InitGameGlobals`.
    public var darknessOverride: UInt8 = 0
    /// `+0x22` saved darkness (`.SetupLevel`; read by `.HitPlayerSprite`). Not written by `.InitGameGlobals`.
    public var savedDarkness: Int16 = 0
    /// `+0x24 + 10·k`, `k < 27` (spells-items §1).
    public var inventory = [InventorySlot](repeating: InventorySlot(id: 0, count: 0, field4: 0, field6: 0, isSpell: 0),
                                           count: GameGlobals.inventorySlots)
    /// `+0x172` selected inventory slot.
    public var selectedSlot: Int16 = 0
    /// `+0x174` u8 OmniPx active.
    public var omniPxActive: UInt8 = 0
    /// `+0x176 + 2·L` "level L has a record snapshot in the save block" (engine §9; set by `SaveBlock`'s writers).
    public var hasSnapshot = [Int16](repeating: 0, count: GameGlobals.levelSlots)
    /// `+0x23e + 2·L` level unlocked.
    public var unlocked = [Int16](repeating: 0, count: GameGlobals.levelSlots)
    /// `+0x306 + 200·k + 2·L` per-level achieved counters (rows 0–2 used in play; rows 3–4 are written only by
    /// `.InitGameGlobals`' zero loop).
    public var achieved = [[Int16]](repeating: [Int16](repeating: 0, count: GameGlobals.levelSlots),
                                    count: GameGlobals.counterRows)
    /// `+0x6ee + 200·k + 2·L` per-level totals (same row use as `achieved`).
    public var totals = [[Int16]](repeating: [Int16](repeating: 0, count: GameGlobals.levelSlots),
                                  count: GameGlobals.counterRows)
    /// `+0xad8 + 2·n` world flags (trigger sprite 1058).
    public var worldFlags = [Int16](repeating: 0, count: GameGlobals.worldFlagCount)
    /// `+0xad6` the crunch log's count (`crunchLog` reads and writes it).
    public var crunchCount: Int16 = 0
    /// `+0x12d8 + n` the level byte of crunch entry n (`(char)*_DAT_1009feac`); `.InitGameGlobals` fills 0xff (−1).
    /// All 20000 kept: slots ≥ `crunchCount` hold whatever the binary left there (0xff after init).
    public var crunchLevels = [Int8](repeating: 0, count: GameGlobals.crunchCapacity)
    /// `+0x60f8 + 4n` row of crunch entry n. Never written by `.InitGameGlobals` (a new game keeps the old pairs).
    public var crunchRows = [Int16](repeating: 0, count: GameGlobals.crunchCapacity)
    /// `+0x60fa + 4n` column of crunch entry n.
    public var crunchCols = [Int16](repeating: 0, count: GameGlobals.crunchCapacity)

    /// The crunched-tile log (`+0xad6` count < 20000; `+0x12d8+n` level byte, `+0x60f8+4n` row, `+0x60fa+4n` column),
    /// appended by `.CrunchTile` and the crumble overlay's Handle (P2) — re-applied on revisits (engine §9; W4 /
    /// Phase 3 level re-entry reads it). A view of the first `crunchCount` slots of the three arrays: setting it writes
    /// those slots and the count and leaves the slots past the new count as they were — the binary's own behaviour
    /// (`.CrunchTile` writes slot `count` then bumps it; only `.InitGameGlobals` refills the level bytes).
    public var crunchLog: [CrunchLogEntry] {
        get {
            let n = max(0, min(Int(crunchCount), GameGlobals.crunchCapacity))
            return (0..<n).map { CrunchLogEntry(level: crunchLevels[$0], col: crunchCols[$0], row: crunchRows[$0]) }
        }
        set {
            precondition(newValue.count <= GameGlobals.crunchCapacity, "crunch log over 20000")
            for (i, e) in newValue.enumerated() {
                crunchLevels[i] = e.level
                crunchRows[i] = e.row
                crunchCols[i] = e.col
            }
            crunchCount = Int16(newValue.count)
        }
    }

    /// `.CrunchTile`'s append (raw `10044bc8..10044c14`): while the count is < 20000, writes the one slot at the
    /// count (level byte, row, column) and bumps the count; at 20000 nothing is logged. O(1) — the same result as
    /// `crunchLog.append(entry)` behind that guard, without rebuilding the log.
    public mutating func appendCrunch(_ entry: CrunchLogEntry) {
        let n = max(0, min(Int(crunchCount), GameGlobals.crunchCapacity))
        guard n < GameGlobals.crunchCapacity else { return }
        crunchLevels[n] = entry.level
        crunchRows[n] = entry.row
        crunchCols[n] = entry.col
        crunchCount = Int16(n + 1)
    }

    /// The cleared block (every field 0) — what `initGameGlobals(previous: nil)` starts from, and G inside a
    /// `NewHandleClear`'d save block.
    init() {}

    /// `.InitGameGlobals`' start values (a first game: `previous` nil), `+0x16` from the level header (`.NewGame`,
    /// M l. 5821).
    public init(header: LevelHeader) {
        self = GameGlobals.initGameGlobals(previous: nil)
        startFacing = Int16(header.startFacingLeft)
    }

    /// `.InitGameGlobals @ 10001498` (M l. 582–825), the G part, in the routine's order: inventory slot 0 {0, 1, −1,
    /// 0, spell 1}, slot 1 {0, 1, −1, 0, 0}, slots 2…26 {−1, 0, −1, 0, 0} (l. 616–677); `hasSnapshot`, `unlocked`,
    /// `worldFlags`, `achieved`, `totals` 0 (l. 678–761); `unlocked[1]` (+0x240) 1 (l. 762); crunch count 0 (l. 784)
    /// and level bytes 0xff × 20000 (l. 785–796); `omniPxActive` 0 (l. 797); max magic = max health 0x230, health =
    /// breath = max health, suffocation 0, magic = max magic, coins 0, `+0x12` 3, selected slot 0, Xichrons 0
    /// (l. 799–814); score `G+0` 0 (l. 818, raw `10001a3c stw r24,0x0(r4)`). Never written, so taken from `previous`
    /// (nil → 0, the very first game): `+0x16`, `+0x20`, `+0x22`, the crunch row/column pairs.
    ///
    /// The routine's tail (l. 815–825) also performs 8 stores outside G, in this order — NOT done here (F1b's
    /// `GameFlow.initGameGlobals()` performs them): `*ffac`, `*ffb0`, `*ffb4` (the secrets / Xichrons / enemies
    /// tallies), [G+0 = 0, done here], `*ffa8` (died), `*ffa4`, `*ffa0`, `*ff9c`, then `save+6 = 0`
    /// (`SaveBlock.isCheckpoint`) when the save block exists (`*_DAT_100a0054 ≠ nil` — always after `.InitAppGlobals`'
    /// `NewHandleClear(0xebe58)`, M l. 345). The non-G clears before it (`*_DAT_1009ffc4`, l. 615; the `ffbc`/`ffb8`
    /// 0x2000-word blocks, l. 763–783) are likewise not G's.
    public static func initGameGlobals(previous: GameGlobals?) -> GameGlobals {
        var g = GameGlobals()
        if let p = previous {
            g.startFacing = p.startFacing
            g.darknessOverride = p.darknessOverride
            g.savedDarkness = p.savedDarkness
            g.crunchRows = p.crunchRows
            g.crunchCols = p.crunchCols
        }
        g.inventory[0] = InventorySlot(id: 0, count: 1, field4: -1, field6: 0, isSpell: 1)
        g.inventory[1] = InventorySlot(id: 0, count: 1, field4: -1, field6: 0, isSpell: 0)
        for k in 2..<inventorySlots { g.inventory[k] = .empty }
        g.unlocked[1] = 1
        g.crunchCount = 0
        g.crunchLevels = [Int8](repeating: -1, count: crunchCapacity)
        g.omniPxActive = 0
        g.maxMagic = 0x230
        g.maxHealth = 0x230
        g.health = g.maxHealth
        g.breath = g.maxHealth
        g.suffocation = 0
        g.magic = g.maxMagic
        g.coins = 0
        g.unread12 = 3
        g.selectedSlot = 0
        g.xichrons = 0
        g.score = 0
        return g
    }

    /// Reads every field back from a G image (≥ 0x19978 bytes; gaps are not stored).
    public init(image: Data) throws {
        let b = BigEndianBytes(image, type: "G", id: 0)
        try self.init(b, at: 0)
    }

    /// Reads G at `base` of a larger image (the save block's copy at +0x18).
    init(_ b: BigEndianBytes, at base: Int) throws {
        self.init()
        score = Int32(bitPattern: try b.u32(base + 0x00))
        health = try b.i16(base + 0x04)
        breath = try b.i16(base + 0x06)
        suffocation = try b.i16(base + 0x08)
        maxHealth = try b.i16(base + 0x0a)
        maxMagic = try b.i16(base + 0x0c)
        magic = try b.i16(base + 0x0e)
        coins = try b.i16(base + 0x10)
        unread12 = try b.i16(base + 0x12)
        xichrons = try b.i16(base + 0x14)
        startFacing = try b.i16(base + 0x16)
        darknessOverride = try b.u8(base + 0x20)
        savedDarkness = try b.i16(base + 0x22)
        for k in 0..<GameGlobals.inventorySlots {
            let o = base + 0x24 + InventorySlot.byteCount * k
            inventory[k] = InventorySlot(id: try b.i16(o), count: try b.i16(o + 2), field4: try b.i16(o + 4),
                                         field6: try b.i16(o + 6), isSpell: try b.u8(o + 8))
        }
        selectedSlot = try b.i16(base + 0x172)
        omniPxActive = try b.u8(base + 0x174)
        hasSnapshot = try b.i16Array(at: base + 0x176, count: GameGlobals.levelSlots)
        unlocked = try b.i16Array(at: base + 0x23e, count: GameGlobals.levelSlots)
        for k in 0..<GameGlobals.counterRows {
            achieved[k] = try b.i16Array(at: base + 0x306 + 200 * k, count: GameGlobals.levelSlots)
            totals[k] = try b.i16Array(at: base + 0x6ee + 200 * k, count: GameGlobals.levelSlots)
        }
        crunchCount = try b.i16(base + 0xad6)
        worldFlags = try b.i16Array(at: base + 0xad8, count: GameGlobals.worldFlagCount)
        let levels = base + 0x12d8, pairs = base + 0x60f8
        _ = try b.u8(base + GameGlobals.byteCount - 1)
        for n in 0..<GameGlobals.crunchCapacity {
            crunchLevels[n] = Int8(bitPattern: b.bytes[levels + n])
            crunchRows[n] = Int16(bitPattern: UInt16(b.bytes[pairs + 4 * n]) << 8 | UInt16(b.bytes[pairs + 4 * n + 1]))
            crunchCols[n] = Int16(bitPattern: UInt16(b.bytes[pairs + 4 * n + 2]) << 8
                                  | UInt16(b.bytes[pairs + 4 * n + 3]))
        }
    }

    /// The 0x19978-byte big-endian image, every field at its offset, gaps 0.
    public func image() -> Data {
        var w = BigEndianWriter(count: GameGlobals.byteCount)
        write(into: &w, at: 0)
        return Data(w.bytes)
    }

    /// Writes G at `base` of a larger image (the save block's copy at +0x18).
    func write(into w: inout BigEndianWriter, at base: Int) {
        precondition(inventory.count == GameGlobals.inventorySlots && hasSnapshot.count == GameGlobals.levelSlots
                     && unlocked.count == GameGlobals.levelSlots && worldFlags.count == GameGlobals.worldFlagCount
                     && achieved.count == GameGlobals.counterRows && totals.count == GameGlobals.counterRows
                     && (achieved + totals).allSatisfy { $0.count == GameGlobals.levelSlots }
                     && [crunchLevels.count, crunchRows.count, crunchCols.count]
                         .allSatisfy { $0 == GameGlobals.crunchCapacity }, "G arrays keep the binary's sizes")
        w.u32(base + 0x00, UInt32(bitPattern: score))
        w.i16(base + 0x04, health)
        w.i16(base + 0x06, breath)
        w.i16(base + 0x08, suffocation)
        w.i16(base + 0x0a, maxHealth)
        w.i16(base + 0x0c, maxMagic)
        w.i16(base + 0x0e, magic)
        w.i16(base + 0x10, coins)
        w.i16(base + 0x12, unread12)
        w.i16(base + 0x14, xichrons)
        w.i16(base + 0x16, startFacing)
        w.u8(base + 0x20, darknessOverride)
        w.i16(base + 0x22, savedDarkness)
        for (k, s) in inventory.enumerated() {
            let o = base + 0x24 + InventorySlot.byteCount * k
            w.i16(o, s.id)
            w.i16(o + 2, s.count)
            w.i16(o + 4, s.field4)
            w.i16(o + 6, s.field6)
            w.u8(o + 8, s.isSpell)
        }
        w.i16(base + 0x172, selectedSlot)
        w.u8(base + 0x174, omniPxActive)
        w.i16Array(base + 0x176, hasSnapshot)
        w.i16Array(base + 0x23e, unlocked)
        for k in 0..<GameGlobals.counterRows {
            w.i16Array(base + 0x306 + 200 * k, achieved[k])
            w.i16Array(base + 0x6ee + 200 * k, totals[k])
        }
        w.i16(base + 0xad6, crunchCount)
        w.i16Array(base + 0xad8, worldFlags)
        for n in 0..<GameGlobals.crunchCapacity {
            w.u8(base + 0x12d8 + n, UInt8(bitPattern: crunchLevels[n]))
            w.i16(base + 0x60f8 + 4 * n, crunchRows[n])
            w.i16(base + 0x60fa + 4 * n, crunchCols[n])
        }
    }

    /// What `.UpdateStatusBar` draws.
    public func statusBar(levelName: String) -> StatusBarState {
        StatusBarState(score: Int(score), coins: Int(coins), health: Int(health), breath: Int(breath),
                       magic: Int(magic), levelName: levelName, selectedSlot: Int(selectedSlot))
    }
}
