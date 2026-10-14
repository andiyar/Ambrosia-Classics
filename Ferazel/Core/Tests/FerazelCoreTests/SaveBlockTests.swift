import XCTest
import HectorResources
@testable import FerazelCore

/// SV1 (docs/plans/2026-10-14-ferazel-phase3.md): the game globals `G` (0x19978 B) and the save block (0xebe58 B) as
/// the PPC lays them out — `.InitGameGlobals @ 10001498` (M l. 582–825), `.SavePointSave @ 1000c104` (M l. 6322ff,
/// raw `1000c104…`), `.EndLevelSGUpdate @ 1000c8d8` (M l. 6501ff), the snapshot restore (M l. 2405–2409, 6744–6747);
/// save-continue §3.3, engine §9.
final class SaveBlockTests: XCTestCase {

    private func level1() throws -> LevelFile {
        try LevelFile.load(from: try FerazelData.open(try FerazelData.dataDirectory()), level: 1)
    }

    private func u8(_ d: Data, _ o: Int) -> UInt8 { d[d.startIndex + o] }
    private func u16(_ d: Data, _ o: Int) -> UInt16 { UInt16(u8(d, o)) << 8 | UInt16(u8(d, o + 1)) }
    private func i16(_ d: Data, _ o: Int) -> Int16 { Int16(bitPattern: u16(d, o)) }
    private func u32(_ d: Data, _ o: Int) -> UInt32 { UInt32(u16(d, o)) << 16 | UInt32(u16(d, o + 2)) }
    private func put16(_ d: inout Data, _ o: Int, _ v: Int16) {
        let u = UInt16(bitPattern: v)
        d[o] = UInt8(u >> 8); d[o + 1] = UInt8(u & 0xff)
    }
    private func put32(_ d: inout Data, _ o: Int, _ v: UInt32) {
        put16(&d, o, Int16(bitPattern: UInt16(v >> 16))); put16(&d, o + 2, Int16(bitPattern: UInt16(v & 0xffff)))
    }

    func testInitGameGlobalsImage() throws {
        let g = GameGlobals.initGameGlobals(previous: nil)
        let image = g.image()
        XCTAssertEqual(image.count, 104_824)
        XCTAssertEqual(GameGlobals.byteCount, 0x19978)
        XCTAssertEqual(u16(image, 4), 0x0230)
        XCTAssertEqual([u16(image, 6), u16(image, 0xa), u16(image, 0xc), u16(image, 0xe)], [0x230, 0x230, 0x230, 0x230])
        XCTAssertEqual(u16(image, 0x12), 3)
        XCTAssertEqual(u16(image, 0x240), 1)
        XCTAssertEqual(u16(image, 0x23e), 0)
        XCTAssertEqual([UInt8](image[0x24..<0x2e]), [0x00, 0x00, 0x00, 0x01, 0xFF, 0xFF, 0x00, 0x00, 0x01, 0x00])
        XCTAssertEqual([UInt8](image[0x2e..<0x38]), [0x00, 0x00, 0x00, 0x01, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00])
        for k in 2..<27 {
            XCTAssertEqual([UInt8](image[(0x24 + 10 * k)..<(0x2e + 10 * k)]),
                           [0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00], "slot \(k)")
        }
        XCTAssertEqual([UInt8](image[0x12d8..<0x60f8]), [UInt8](repeating: 0xff, count: 20000))
        XCTAssertEqual(u16(image, 0xad6), 0)
        // Everything else of a first game's G is 0 (nil previous; gaps never stored).
        var rest = image
        rest[4..<0x10] = Data(count: 12); rest[0x12..<0x14] = Data(count: 2); rest[0x24..<0x132] = Data(count: 0x10e)
        rest[0x240..<0x242] = Data(count: 2); rest[0x12d8..<0x60f8] = Data(count: 20000)
        XCTAssertEqual(rest, Data(count: GameGlobals.byteCount))
        XCTAssertEqual(g, GameGlobals(header: try level1().header).with { $0.startFacing = 0 })

        // `previous` supplies what the routine never writes (+0x16, +0x20, +0x22, the crunch pairs); all else resets.
        var old = g
        old.startFacing = 1; old.darknessOverride = 7; old.savedDarkness = 9; old.score = 1234; old.coins = 40
        old.crunchLog = [CrunchLogEntry(level: 2, col: 5, row: 6)]
        old.hasSnapshot[3] = 1; old.worldFlags[10] = 1; old.inventory[2] = InventorySlot(id: 4, count: 2, field4: -1,
                                                                                       field6: 0, isSpell: 0)
        let fresh = GameGlobals.initGameGlobals(previous: old)
        XCTAssertEqual([fresh.startFacing, Int16(fresh.darknessOverride), fresh.savedDarkness], [1, 7, 9])
        XCTAssertEqual(fresh.crunchLog, [])
        XCTAssertEqual([fresh.crunchRows[0], fresh.crunchCols[0], Int16(fresh.crunchLevels[0])], [6, 5, -1])
        var expect = g
        expect.startFacing = 1; expect.darknessOverride = 7; expect.savedDarkness = 9
        expect.crunchRows[0] = 6; expect.crunchCols[0] = 5
        XCTAssertEqual(fresh, expect)
    }

    func testGameGlobalsRoundTrip() throws {
        var g = GameGlobals.initGameGlobals(previous: nil)
        // Every scalar a distinct non-default value, so a field read and written at the same wrong offset (which
        // the round trip alone cannot see) fails the raw-offset asserts below.
        g.score = 0x01020304; g.health = 0x1104; g.breath = 0x1206; g.suffocation = 0x1308; g.maxHealth = 0x140a
        g.maxMagic = 0x150c; g.magic = 0x160e; g.coins = 0x1710; g.unread12 = 0x1812; g.xichrons = 0x1914
        g.startFacing = 0x1a16; g.darknessOverride = 0xab; g.savedDarkness = -3; g.selectedSlot = 0x1d72
        g.omniPxActive = 0x5d
        g.inventory[26] = InventorySlot(id: 7, count: 99, field4: 3, field6: -2, isSpell: 1)
        g.hasSnapshot[99] = 1; g.unlocked[42] = 1; g.achieved[4][99] = 21; g.achieved[0][0] = 22
        g.totals[2][50] = 23; g.totals[4][99] = 24; g.worldFlags[1023] = 25; g.worldFlags[0] = 26
        g.crunchLog = [CrunchLogEntry(level: 3, col: 100, row: -1), CrunchLogEntry(level: -2, col: 1, row: 2)]
        g.crunchRows[19999] = 27; g.crunchCols[19999] = 28; g.crunchLevels[19999] = 29
        let image = g.image()
        XCTAssertEqual(image.count, GameGlobals.byteCount)
        XCTAssertEqual(try GameGlobals(image: image), g)
        XCTAssertEqual(try GameGlobals(image: image).image(), image)
        XCTAssertEqual(u32(image, 0), 0x01020304)
        XCTAssertEqual([0x04, 0x06, 0x08, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14, 0x16].map { u16(image, $0) },
                       [0x1104, 0x1206, 0x1308, 0x140a, 0x150c, 0x160e, 0x1710, 0x1812, 0x1914, 0x1a16],
                       "health, breath, suffocation, maxHealth, maxMagic, magic, coins, +0x12, xichrons, startFacing")
        XCTAssertEqual(u8(image, 0x20), 0xab)
        XCTAssertEqual(i16(image, 0x22), -3)
        XCTAssertEqual(u16(image, 0x172), 0x1d72)
        XCTAssertEqual(u8(image, 0x174), 0x5d)
        XCTAssertEqual(u16(image, 0xad6), 2)
        XCTAssertEqual([UInt8(bitPattern: 3), UInt8(bitPattern: -2)], [u8(image, 0x12d8), u8(image, 0x12d9)])
        XCTAssertEqual([i16(image, 0x60f8), i16(image, 0x60fa), i16(image, 0x60fc), i16(image, 0x60fe)], [-1, 100, 2, 1])
        XCTAssertEqual(u16(image, 0x176 + 2 * 99), 1)
        XCTAssertEqual(u16(image, 0x23e + 2 * 42), 1)
        XCTAssertEqual(u16(image, 0x306 + 200 * 4 + 2 * 99), 21)
        XCTAssertEqual(u16(image, 0x6ee + 200 * 2 + 2 * 50), 23)
        XCTAssertEqual(u16(image, 0xad8 + 2 * 1023), 25)
        XCTAssertEqual([UInt8](image[(0x24 + 260)..<(0x24 + 270)]), [0, 7, 0, 99, 0, 3, 0xff, 0xfe, 1, 0])
        XCTAssertEqual([u16(image, 0x19974), u16(image, 0x19976), UInt16(u8(image, 0x12d8 + 19999))], [27, 28, 29])
        XCTAssertThrowsError(try GameGlobals(image: image.dropLast()))
    }

    func testCrunchLogImage() throws {
        var g = GameGlobals.initGameGlobals(previous: nil)
        g.crunchLog = [CrunchLogEntry(level: 1, col: 119, row: 36), CrunchLogEntry(level: 1, col: 120, row: 36),
                       CrunchLogEntry(level: 2, col: 3, row: 4)]
        let image = g.image()
        XCTAssertEqual(u16(image, 0xad6), 3)
        XCTAssertEqual([UInt8](image[0x12d8..<0x12dc]), [1, 1, 2, 0xff])
        XCTAssertEqual([u16(image, 0x60f8), u16(image, 0x60fa)], [36, 119])
        XCTAssertEqual([u16(image, 0x60fc), u16(image, 0x60fe)], [36, 120])
        XCTAssertEqual([u16(image, 0x6100), u16(image, 0x6102)], [4, 3])
        XCTAssertEqual([u16(image, 0x6104), u16(image, 0x6106)], [0, 0])
        XCTAssertEqual(try GameGlobals(image: image).crunchLog, g.crunchLog)
    }

    func testSaveBlockLayout() throws {
        XCTAssertEqual(SaveBlock.byteCount, 966_232)
        var d = Data(count: SaveBlock.byteCount)
        put32(&d, 0, 0xCAFEF00D); d[4] = 1; d[5] = 2; d[6] = 1; put16(&d, 8, 7)
        put32(&d, 0xc, UInt32(bitPattern: -5)); put32(&d, 0x10, 0x00012345)
        var g = GameGlobals.initGameGlobals(previous: nil)
        g.score = 999; g.hasSnapshot[7] = 1
        d.replaceSubrange(0x18..<(0x18 + GameGlobals.byteCount), with: g.image())
        put32(&d, 0x19990, 0xB0B0B0B0)
        let rec = 0x19998 + 0x2000 * 7 + 16 * 510
        d[rec] = 1; d[rec + 1] = 0; put16(&d, rec + 2, 1058); put16(&d, rec + 4, 1); put16(&d, rec + 6, 2)
        put16(&d, rec + 8, 3); put16(&d, rec + 10, 4); put16(&d, rec + 12, 100); put16(&d, rec + 14, 200)
        let name: [UInt8] = [5] + Array("Mwld2".utf8)
        d.replaceSubrange(0xe7d98..<(0xe7d98 + name.count), with: name)

        let b = try SaveBlock(image: d)
        XCTAssertEqual(b.worldStamp, 0xCAFEF00D)
        XCTAssertEqual([b.preview, b.demo, b.isCheckpoint], [1, 2, 1])
        XCTAssertEqual(b.level, 7)
        XCTAssertEqual([b.playerX, b.playerY], [-5, 0x12345])
        XCTAssertEqual(b.globals, g)
        XCTAssertEqual(b.date, 0xB0B0B0B0)
        XCTAssertEqual(b.snapshots.count, 100)
        XCTAssertEqual(b.snapshots[7].count, 511)
        XCTAssertEqual(b.snapshots[7][510], Placement(index: 510, flag: 1, byte1: 0, type: 1058, p1: 1, p2: 2, p3: 3,
                                                       p4: 4, y: 100, x: 200))
        XCTAssertEqual(b.snapshots[0][0], Placement(index: 0, flag: 0, byte1: 0, type: 0, p1: 0, p2: 0, p3: 0, p4: 0,
                                                     y: 0, x: 0))
        XCTAssertEqual(b.worldName, Array("Mwld2".utf8))
        XCTAssertEqual(b.image(), d)
        XCTAssertEqual(SaveBlock().image(), Data(count: SaveBlock.byteCount))
    }

    func testSavePointSaveWritesSnapshotMinus6() throws {
        let level = try level1()
        let records = level.placements
        XCTAssertEqual([records[24].x, records[24].y], [2377, 878])
        var g = GameGlobals.initGameGlobals(previous: nil)
        g.score = 4321
        XCTAssertEqual(g.hasSnapshot[1], 0)
        var b = SaveBlock()
        b.preview = 1; b.demo = 1
        b.savePointSave(level: 1, x: -2, y: 300, stamp: 0x11223344, date: 0x55667788, globals: &g, records: records)
        // The live G gets the flag; the copy is taken after it (raw 1000c1c0 before the copy loop 1000c1cc..c1e0).
        XCTAssertEqual(g.hasSnapshot[1], 1)
        XCTAssertEqual(b.globals, g)
        let image = b.image()
        XCTAssertEqual(u32(image, 0), 0x11223344)
        XCTAssertEqual([u8(image, 4), u8(image, 5), u8(image, 6)], [0, 0, 1])
        XCTAssertEqual(u16(image, 8), 1)
        XCTAssertEqual([u32(image, 0xc), u32(image, 0x10)], [0xfffffffe, 300])
        XCTAssertEqual(u16(image, 0x18 + 0x176 + 2), 1)
        XCTAssertEqual(u32(image, 0x18), 4321)
        XCTAssertEqual(u32(image, 0x19990), 0x55667788)
        let rec = 0x19998 + 0x2000 + 16 * 24
        XCTAssertEqual([i16(image, rec + 0xc), i16(image, rec + 0xe)], [872, 2371])
        XCTAssertEqual(i16(image, rec + 2), records[24].type)
        XCTAssertEqual([UInt8](image[(0x19998 + 0x2000 + 16 * 511)..<(0x19998 + 0x2000 * 2)]),
                       [UInt8](repeating: 0, count: 16))

        // `.EndLevelSGUpdate`: the same core without the +4/+5 stores.
        var e = SaveBlock()
        e.preview = 1; e.demo = 1
        var g2 = GameGlobals.initGameGlobals(previous: nil)
        e.endLevelSGUpdate(level: 2, x: 10, y: 20, stamp: 1, date: 2, globals: &g2, records: records)
        XCTAssertEqual([e.preview, e.demo, e.isCheckpoint], [1, 1, 1])
        XCTAssertEqual(g2.hasSnapshot[2], 1)
        XCTAssertEqual(e.globals.hasSnapshot[2], 1)
        XCTAssertEqual([e.level, Int16(e.playerX), Int16(e.playerY)], [2, 10, 20])
        XCTAssertEqual([e.snapshots[2][24].x, e.snapshots[2][24].y], [2371, 872])
    }

    func testRestoreSnapshotPlus6() throws {
        let records = try level1().placements
        var g = GameGlobals.initGameGlobals(previous: nil)
        var b = SaveBlock()
        b.savePointSave(level: 1, x: 0, y: 0, stamp: 0, date: 0, globals: &g, records: records)
        XCTAssertEqual(b.restoreSnapshot(level: 1), records)
        let reread = try SaveBlock(image: b.image())
        XCTAssertEqual(reread, b)
        XCTAssertEqual(reread.restoreSnapshot(level: 1), records)
    }
}

private extension GameGlobals {
    func with(_ edit: (inout GameGlobals) -> Void) -> GameGlobals {
        var g = self
        edit(&g)
        return g
    }
}
