import XCTest
@testable import FerazelCore

/// US (docs/plans/2026-10-24-ferazel-phase4.md): `.UpdateSprites @ 1000982c` in full (M l. 4934–5037; raw
/// `1000982c..10009b78`; spells-detail-2 §5, pickups-boxes §1.10) — the 0x6ea re-type, the record write-back
/// (`+6` type, `+0x12` x, `+0x10` y unless `+0x188` / `+0x18a` / `+0x189`, index 0…0x1fe), the `+0xe9` count-up
/// (1 → 4, callbacks, type −|t|, face, light, record `+4`), the killed-for-good record clear (`+0xea`), the final
/// kill (light, 0x41f restored, record `+4` unless `+0x18b`, the idle entry `+0xa8`) and the walk's restart from the
/// head after every `.MTKillSprite`.
final class UpdateSpritesTests: XCTestCase {

    private let face = FaceRef(pict: 1201, index: 0, set: .encoded)
    private let lightFace = LightFaceRef(pict: 0x32a, width: 0x48, height: 0x48)

    private func world(records extra: Int = 0) throws -> SpriteWorld {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let L = try LevelFile.load(from: r, level: 1)
        var recs = L.placements
        for _ in 0..<extra { recs.append(placement(recs.count)) }
        return SpriteWorld(level: L, records: recs)
    }

    /// A known record image at `index`: flag 1, type 99, p1 0x55, (x 5, y 6).
    private func placement(_ index: Int, flag: UInt8 = 1) -> Placement {
        Placement(index: index, flag: flag, byte1: 0, type: 99, p1: 0x55, p2: 0, p3: 0, p4: 0, y: 6, x: 5)
    }

    private func setRecord(_ w: SpriteWorld, _ i: Int, flag: UInt8 = 1) { w.records[i] = placement(i, flag: flag) }

    @discardableResult
    private func add(_ w: SpriteWorld, type: Int16, x: Int = 40, y: Int = 50, record: Int16 = -1,
                     _ body: (inout SpriteSlot) -> Void = { _ in }) -> Int {
        var s = SpriteSlot(type: type, x: x, y: y, recordIndex: record)
        body(&s)
        return w.active.insert(s)
    }

    func testKillRequestUnlinksOnFourthPass() throws {
        let w = try world()
        var lights = LightTable()
        let slot = lights.add(face: lightFace, x: 1, y: 2, vx: 0, vy: 0, accelY: 0, colour: 0)
        setRecord(w, 7)
        let t: Int16 = 1201
        let d = add(w, type: t, record: 7) { s in
            s.killCount = 1
            s.face = self.face
            s.hasHit = true
            s.hasTileHit = true
            s.light = slot
        }
        // Fill the record table: 700 listed, no room for `newSprite`.
        for _ in 0..<(SpriteWorld.recordCount - 1) { add(w, type: 100) }
        XCTAssertNil(w.newSprite(type: 100, x: 0, y: 0, layer: 0, handler: .inert))
        for (pass, expected) in [UInt8(2), 3, 4].enumerated() {
            w.updateSprites(lights: &lights)
            let s = try XCTUnwrap(w.active.sprite(id: d), "pass \(pass + 1): still listed")
            XCTAssertEqual(s.killCount, expected, "pass \(pass + 1)")
            XCTAssertTrue(s.dead)
            XCTAssertEqual(s.type, -t, "type = −|type| (stays negative on later passes)")
            XCTAssertNil(s.face)
            XCTAssertFalse(s.hasHit)
            XCTAssertFalse(s.hasTileHit)
            XCTAssertEqual(s.light, -1)
            XCTAssertEqual(w.records[7].flag, 0, "record +4 = 0 (no +0x188)")
            XCTAssertEqual(w.records[7].type, pass == 0 ? t : -t, "the write-back precedes the count-up")
        }
        XCTAssertTrue(lights.slots[Int(slot)].removing)
        XCTAssertEqual(lights.count, 0, "one RemoveLight only (+0x9a = −1 after the first)")
        w.updateSprites(lights: &lights)
        XCTAssertNil(w.active.sprite(id: d), "pass 4: unlinked")
        XCTAssertEqual(w.active.record(id: d)?.type, -t, "only ±0x41f is restored")
        XCTAssertEqual(w.active.sprites.count, SpriteWorld.recordCount - 1)
        XCTAssertNotNil(w.newSprite(type: 100, x: 0, y: 0, layer: 0, handler: .inert), "its slot is free")

        // The walk restarts from the head after a kill: [B (+0xe9 1), A (+0xe9 4)] counts B up twice in one call.
        let w2 = try world()
        var l2 = LightTable()
        let b = add(w2, type: 1201) { $0.killCount = 1 }
        let a = add(w2, type: 1201) { $0.killCount = 4 }
        w2.updateSprites(lights: &l2)
        XCTAssertNil(w2.active.sprite(id: a))
        XCTAssertEqual(w2.active.sprite(id: b)?.killCount, 3)
    }

    func testRecordWriteBack() throws {
        let w = try world(records: 1)
        XCTAssertEqual(w.records.count, 0x200)
        var lights = LightTable()
        let t: Int16 = 1400
        for i in [7, 8, 9, 10, 11, 0x1ff] { setRecord(w, i) }
        add(w, type: t, x: 300, y: 120, record: 7)
        add(w, type: t, x: 300, y: 120, record: 8) { $0.keepRecord = true }
        add(w, type: t, x: 300, y: 120, record: 9) { $0.noWriteBack189 = true }
        add(w, type: t, x: 300, y: 120, record: 10) { $0.noWriteBack18a = true }
        add(w, type: t, x: 300, y: 120, record: 0x1ff)
        // A rope: `.SetupRopeSprite` sets `+0x188` (M l. 71107) — its record is never rewritten.
        var rope = SpriteSlot(type: 3020, x: 300, y: 120, recordIndex: 11)
        RopeSprite.setup(&rope, record: w.records[11])
        w.active.insert(rope)
        w.updateSprites(lights: &lights)
        let r = w.records[7]
        XCTAssertEqual([r.x, r.y, r.type], [300, 120, t])
        XCTAssertEqual([Int16(r.flag), r.p1, Int16(r.index)], [1, 0x55, 7], "the other bytes kept")
        for i in [8, 9, 10, 11, 0x1ff] {
            XCTAssertEqual(w.records[i], placement(i), "record \(i) unchanged")
        }
        XCTAssertEqual(w.active.sprites.count, 6, "no kill request: all listed")
    }

    func testKilledForGoodClearsRecord() throws {
        let w = try world()
        var lights = LightTable()
        for i in [7, 8, 9] { setRecord(w, i) }
        let k = add(w, type: 1400, record: 7) { $0.killedForGood = true }
        add(w, type: 1400, record: 8) { $0.killedForGood = true; $0.keepRecord = true }
        add(w, type: 1400, record: 9)
        w.updateSprites(lights: &lights)
        XCTAssertEqual(w.records[7].flag, 0, "+0xea with +0xe9 0: record +4 = 0 the same pass")
        XCTAssertEqual(w.records[8].flag, 1, "+0x188 keeps it")
        XCTAssertEqual(w.records[9].flag, 1, "no +0xea: kept")
        let s = try XCTUnwrap(w.active.sprite(id: k), "still listed")
        XCTAssertEqual(s.killCount, 0)
        XCTAssertEqual(s.type, 1400)
        XCTAssertEqual(w.active.sprites.count, 3)
    }

    func testKeepRecordFlags() throws {
        let w = try world()
        var lights = LightTable()
        for i in [7, 8, 9] { setRecord(w, i) }
        for k in 0..<14 {
            w.idle.add(SpriteSlot(type: 1400, x: 10 * k, y: 10, recordIndex: -1), faceRect: .noFace)
        }
        // `+0x188`: the count-up passes leave `+4 = 1`; the final pass tests `+0x18b` only, so it clears it.
        let a = add(w, type: 1400, record: 7) { $0.killCount = 1; $0.keepRecord = true }
        for _ in 0..<3 {
            w.updateSprites(lights: &lights)
            XCTAssertEqual(w.records[7].flag, 1)
        }
        XCTAssertEqual(w.active.sprite(id: a)?.killCount, 4)
        // `+0x18b`: the final pass leaves `+4 = 1`; idle entry 12 (record valid) freed; a record-less sprite's
        // idle entry 11 is not (the clear is inside the record-index test, raw `100099e4..10009a50`).
        let b = add(w, type: 1400, record: 8) { $0.killCount = 4; $0.keepRecordAtKill = true; $0.idleEntry = 12 }
        let c = add(w, type: 1400, record: -1) { $0.killCount = 4; $0.idleEntry = 11 }
        let e = add(w, type: 1400, record: 9) { $0.killCount = 4; $0.idleEntry = 13 }
        w.updateSprites(lights: &lights)
        for id in [a, b, c, e] { XCTAssertNil(w.active.sprite(id: id)) }
        XCTAssertEqual(w.records[7].flag, 0, "+0x188 is not read at the final pass")
        XCTAssertEqual(w.records[8].flag, 1, "+0x18b keeps it")
        XCTAssertEqual(w.records[9].flag, 0)
        XCTAssertNil(w.idle.entries[12])
        XCTAssertNil(w.idle.entries[13])
        XCTAssertNotNil(w.idle.entries[11])
        XCTAssertNotNil(w.idle.entries[10])
        // `.IdleToActiveSprite` stores the entry index in `+0xa8` (M l. 4265).
        let on = w.idle.handle(h: 0, v: 0, playerHotRect: nil, active: &w.active, faceRect: { _ in .noFace })
        XCTAssertTrue(on.activated.contains(5))
        let live = try XCTUnwrap(w.idle.entries[5]?.activeID)
        XCTAssertEqual(w.active.sprite(id: live)?.idleEntry, 5)
        // Idled with `+0xe9` 2 and a sub-pixel x: `.IdleToActiveSprite` stores `+0xe9 = 0` (M l. 4264) and
        // `+0x14 = x << 8` (l. 4262), so it comes back alive and whole-pixel, and stays listed.
        w.active.update(id: live) { $0.killCount = 2; $0.x256 = Int32($0.x) << 8 + 0x80 }
        w.idle.handle(h: 100_000, v: 100_000, playerHotRect: nil, active: &w.active, faceRect: { _ in .noFace })
        w.updateSprites(lights: &lights)
        XCTAssertNil(w.active.sprite(id: live), "idled: killed")
        w.idle.handle(h: 0, v: 0, playerHotRect: nil, active: &w.active, faceRect: { _ in .noFace })
        let back = try XCTUnwrap(w.idle.entries[5]?.activeID)
        w.updateSprites(lights: &lights)
        let b5 = try XCTUnwrap(w.active.sprite(id: back), "not unlinked")
        XCTAssertEqual(b5.killCount, 0)
        XCTAssertEqual(b5.x256, Int32(b5.x) << 8)
        // The free's bound (raw `10009a38..10009a44`: 0 ≤ `+0xa8` ≤ 0x1ff): entry 0x1ff freed, 0x200 ignored.
        while w.idle.add(SpriteSlot(type: 1400, x: 0, y: 0), faceRect: .noFace) != nil {}
        setRecord(w, 7)
        add(w, type: 1400, record: 7) { $0.killCount = 4; $0.idleEntry = 0x1ff }
        add(w, type: 1400, record: 7) { $0.killCount = 4; $0.idleEntry = 0x200 }
        add(w, type: 1400, record: 7) { $0.killCount = 4; $0.idleEntry = -1 }
        let used = w.idle.entries.filter { $0 != nil }.count
        w.updateSprites(lights: &lights)
        XCTAssertNil(w.idle.entries[0x1ff])
        XCTAssertEqual(w.idle.entries.filter { $0 != nil }.count, used - 1)
    }

    func testXichronTypeRestoredAndIdledRecordKilled() throws {
        let w = try world()
        var lights = LightTable()
        setRecord(w, 7)
        setRecord(w, 8)
        let x = add(w, type: 0x41f, record: 7) { $0.killCount = 1 }
        w.updateSprites(lights: &lights)
        XCTAssertEqual(w.active.sprite(id: x)?.type, -0x41f)
        w.updateSprites(lights: &lights)
        w.updateSprites(lights: &lights)
        w.updateSprites(lights: &lights)
        XCTAssertNil(w.active.sprite(id: x))
        XCTAssertEqual(w.active.record(id: x)?.type, 0x41f, "restored when unlinked")
        XCTAssertEqual(w.records[7].type, -0x41f, "the write-back ran before the restore")

        // An idled record (`+0x4c` 0, `+0xe9` 0): unlinked on the first pass, its light and record flag untouched.
        let slot = lights.add(face: lightFace, x: 1, y: 2, vx: 0, vy: 0, accelY: 0, colour: 0)
        let idled = add(w, type: 1400, record: 8) { $0.handleCleared = true; $0.light = slot }
        // An idled record with a kill request (`+0xe9` 2, Handle 0): the final branch at once — light removed.
        let slot2 = lights.add(face: lightFace, x: 1, y: 2, vx: 0, vy: 0, accelY: 0, colour: 0)
        let idledDying = add(w, type: 1400) { $0.handleCleared = true; $0.killCount = 2; $0.light = slot2 }
        let six = add(w, type: 0x6ea)
        w.updateSprites(lights: &lights)
        XCTAssertNil(w.active.sprite(id: idled))
        XCTAssertNil(w.active.sprite(id: idledDying))
        XCTAssertEqual(w.active.record(id: idled)?.light, slot, "+0xe9 0: no RemoveLight")
        XCTAssertFalse(lights.slots[Int(slot)].removing)
        XCTAssertEqual(w.active.record(id: idledDying)?.light, -1)
        XCTAssertTrue(lights.slots[Int(slot2)].removing)
        XCTAssertEqual(w.active.record(id: idledDying)?.type, 1400, "the final branch does not negate")
        XCTAssertEqual(w.records[8].flag, 1, "+0xe9 0: the final branch skips the record flag")
        XCTAssertEqual(w.active.sprite(id: six)?.type, 0x6ea, "0x6eb then −1: stays 0x6ea")
    }
}
