import XCTest
@testable import FerazelCore

/// LT (docs/plans/2026-10-24-ferazel-phase4.md, S2 `LightTable`, S3 `DrawOp.lightTable`): the 200 light slots at
/// `_DAT_100a0128` as Core state — `.AddLight @ 1001bc08`, `.RemoveLight`, `.ChangeLightFace`, `.SetLightPos`,
/// `.ChangeLightSpeed`, `.ChangeLightColor`, `.RemoveAllLights`, `.HandleLights` (M l. 14275–14556; lighting-tables
/// §7.4). A missing data file is a FAILURE, never a skip.
final class LightTableTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    private let face = LightFaceRef(pict: 0x32a, width: 0x48, height: 0x48)

    func testAddTakesFirstFreeSlot() {
        var t = LightTable()
        XCTAssertEqual(t.add(face: face, x: 10, y: 20, vx: 0, vy: 0, accelY: 0, colour: 99), 0)
        XCTAssertEqual(t.add(face: face, x: 30, y: 40, vx: 0, vy: 0, accelY: 0, colour: 0x21), 1)
        XCTAssertEqual(t.count, 2)
        let s1 = t.slots[1]
        XCTAssertEqual([s1.active, s1.isNew, s1.removing], [true, true, false])
        XCTAssertEqual(s1.face, face)
        XCTAssertNil(s1.previousFace)
        XCTAssertEqual([s1.x, s1.y, s1.radius, s1.colour], [30, 40, 0x24, 0x21])
        XCTAssertEqual([s1.x256, s1.y256], [30 << 8, 40 << 8])
        // `.RemoveLight`: `+2 = 1`, face nil, radius 0, count − 1, the caller's slot −1 — but `+0` stays set until the
        // next `.HandleLights`, so the slot is not free yet: the next add takes slot 2.
        var slot: Int16 = 0
        t.remove(&slot)
        XCTAssertEqual(slot, -1)
        XCTAssertEqual([t.slots[0].active, t.slots[0].removing], [true, true])
        XCTAssertNil(t.slots[0].face)
        XCTAssertEqual(t.slots[0].radius, 0)
        XCTAssertEqual(t.count, 1)
        XCTAssertEqual(t.add(face: face, x: 50, y: 60, vx: 0, vy: 0, accelY: 0, colour: 99), 2)
        XCTAssertEqual(t.count, 2)
        // A slot outside 0…199 changes nothing but the caller's −1.
        var bad: Int16 = 200
        let before = t
        t.remove(&bad)
        XCTAssertEqual(bad, -1)
        XCTAssertEqual(t, before)
        // `.HandleLights` clears the pending slot (`+0` = 0); the next add takes it (the first free one) and resets
        // `+2`.
        t.handleLights()
        XCTAssertFalse(t.slots[0].active)
        XCTAssertFalse(t.slots[1].isNew)
        XCTAssertEqual(t.add(face: face, x: 70, y: 80, vx: 0, vy: 0, accelY: 0, colour: 0x4d), 0)
        XCTAssertEqual([t.slots[0].active, t.slots[0].isNew, t.slots[0].removing], [true, true, false])
        XCTAssertEqual([t.slots[0].x, t.slots[0].y, t.slots[0].colour], [70, 80, 0x4d])
        XCTAssertEqual(t.count, 3)
        // `.RemoveAllLights`: every slot's `+0`, `+2`, `+4`, `+0x14` and the count.
        t.removeAll()
        XCTAssertEqual(t.count, 0)
        XCTAssertTrue(t.slots.allSatisfy { !$0.active && !$0.removing && $0.face == nil && $0.radius == 0 })
        XCTAssertEqual(t.add(face: face, x: 1, y: 2, vx: 0, vy: 0, accelY: 0, colour: 99), 0)
    }

    func testAddFullOrNilFace() {
        var t = LightTable()
        for i in 0..<200 {
            XCTAssertEqual(t.add(face: face, x: Int16(i), y: 0, vx: 0, vy: 0, accelY: 0, colour: 99), Int16(i))
        }
        XCTAssertEqual(t.count, 200)
        // Full: −1 (`iVar5` stays −1) and nothing stored (the original's `ReportError(…, 200)`).
        let full = t
        XCTAssertEqual(t.add(face: face, x: 500, y: 500, vx: 0, vy: 0, accelY: 0, colour: 0x21), -1)
        XCTAssertEqual(t, full)
        XCTAssertEqual(t.add(face: nil, x: 500, y: 500, vx: 0, vy: 0, accelY: 0, colour: 0x21), -1)
        XCTAssertEqual(t, full)
        // A nil face with a free slot: nothing stored, the count unchanged — but `.AddLight` returns `iVar5`, the first
        // free slot (raw `1001bc58..1001bd08`: `beq` to the `ReportError` path, then `or r3,r31,r31`), not −1.
        var u = LightTable()
        _ = u.add(face: face, x: 0, y: 0, vx: 0, vy: 0, accelY: 0, colour: 99)
        _ = u.add(face: face, x: 0, y: 0, vx: 0, vy: 0, accelY: 0, colour: 99)
        let two = u
        XCTAssertEqual(u.add(face: nil, x: 9, y: 9, vx: 0, vy: 0, accelY: 0, colour: 99), 2)
        XCTAssertEqual(u, two)
        XCTAssertFalse(u.slots[2].active)
        XCTAssertEqual(u.count, 2)
    }

    func testHandleLightsIntegratesSpeed() {
        var t = LightTable()
        XCTAssertEqual(t.add(face: face, x: 100, y: 50, vx: 0x180, vy: -0x100, accelY: 0x20, colour: 0x2c), 0)
        XCTAssertEqual(t.add(face: face, x: 7, y: 8, vx: 0x100, vy: 0x100, accelY: 0, colour: 99), 1)
        var gone: Int16 = 1
        t.remove(&gone)
        t.handleLights()
        let s = t.slots[0]
        XCTAssertEqual(s.x256, 100 * 256 + 0x180)
        XCTAssertEqual(s.y256, 50 * 256 - 0x100)
        XCTAssertEqual([s.x, s.y], [101, 49])
        XCTAssertEqual(s.vy, -0x100 + 0x20)                     // `+0x28 += +0x2c` after the y step
        XCTAssertEqual(s.vx, 0x180)
        XCTAssertEqual([s.previousX, s.previousY, s.previousRadius, s.previousColour], [100, 50, 0x24, 0x2c])
        XCTAssertEqual(s.previousFace, face)
        XCTAssertFalse(s.isNew)
        // The removed slot goes inactive and does not move.
        XCTAssertFalse(t.slots[1].active)
        XCTAssertEqual([t.slots[1].x, t.slots[1].y], [7, 8])
        // A second step uses the accelerated vy; the previous fields are the first step's point.
        t.handleLights()
        XCTAssertEqual([t.slots[0].x, t.slots[0].y], [103, 48])       // 26368 >> 8, 12320 >> 8
        XCTAssertEqual([t.slots[0].previousX, t.slots[0].previousY], [101, 49])
        // The setters: each ignores a slot outside 0…199; `.SetLightPos` rewrites the fixed point too.
        let before = t
        t.setPos(-1, x: 1, y: 1)
        t.changeSpeed(200, vx: 1, vy: 1)
        t.changeColor(-1, 5)
        t.changeFace(200, LightFaceRef(pict: 0x321, width: 0xc0, height: 0xc0))
        XCTAssertEqual(t, before)
        t.setPos(0, x: 300, y: 200)
        XCTAssertEqual([t.slots[0].x, t.slots[0].y], [300, 200])
        XCTAssertEqual([t.slots[0].x256, t.slots[0].y256], [300 << 8, 200 << 8])
        XCTAssertEqual([t.slots[0].previousX, t.slots[0].previousY], [101, 49])
        t.changeSpeed(0, vx: 0, vy: 0)
        t.changeColor(0, 0x42)
        t.changeFace(0, LightFaceRef(pict: 0x321, width: 0xc0, height: 0xc0))
        XCTAssertEqual([t.slots[0].vx, t.slots[0].vy], [0, 0])
        XCTAssertEqual(t.slots[0].colour, 0x42)
        XCTAssertEqual(t.slots[0].radius, 0x60)
        XCTAssertEqual(t.slots[0].face?.pict, 0x321)
    }

    func testSetupLightsGoThroughTable() throws {
        var prefs = FerazelPrefs()
        prefs.effects = 1
        let s = try FerazelSession(resources: try resources(), prefs: prefs, level: 1, seed: 1)
        // The 68 Setup lights (D26 R4) in slots 0…67, `.SetupLevelSprites` order, as `.AddLight` left them.
        XCTAssertEqual(s.lights.count, 68)
        XCTAssertEqual(s.lightTable.count, 68)
        for (i, l) in s.lights.enumerated() {
            let t = s.lightTable.slots[i]
            XCTAssertEqual([t.active, t.isNew, t.removing], [true, true, false], "slot \(i)")
            XCTAssertEqual(t.face, LightFaceRef(pict: l.pict, width: l.width, height: l.height), "slot \(i)")
            XCTAssertEqual([Int(t.x), Int(t.y), Int(t.radius), Int(t.colour)], [l.x, l.y, l.radius, l.colour],
                           "slot \(i)")
        }
        XCTAssertTrue(s.lightTable.slots[68...].allSatisfy { !$0.active && $0.face == nil })
        XCTAssertEqual(s.lightTable.slots[24].face?.pict, 0x32a)
        // The first iteration: `.lightTable` right after its `.redrawScrollGrid` and before `.drawLightsOntoTiles`,
        // carrying the table before this frame's `.HandleLights`; Core then runs `.HandleLights` itself, and the
        // potion's twinkle (`.ChangeLightFace`) lands in the table too.
        let before = s.lightTable
        let ops = s.step(keys: KeyState()).draws
        guard let k = ops.firstIndex(where: { if case .lightTable = $0 { true } else { false } }) else {
            return XCTFail("no lightTable op")
        }
        XCTAssertEqual(ops.filter { if case .lightTable = $0 { true } else { false } }.count, 1)
        XCTAssertEqual(ops[k], .lightTable(before))
        guard case .redrawScrollGrid = ops[k - 1] else { return XCTFail("\(ops[k - 1])") }
        XCTAssertEqual(ops[..<k].filter { if case .redrawScrollGrid = $0 { true } else { false } }.count, 2)
        XCTAssertEqual(ops[k + 1], .drawLightsOntoTiles)
        XCTAssertEqual(s.lightTable.count, 68)
        // `+0x9a` holds the slot `.AddLight` returned: the potion's light is slot 24 (its twinkle's slot).
        XCTAssertTrue(s.active.sprites.contains { (0xc80...0xcb0).contains(Int($0.type)) && $0.light == 24 })
        XCTAssertTrue(s.lightTable.slots[0..<68].allSatisfy { $0.active && !$0.isNew })
        XCTAssertEqual(s.lightTable.slots[24].face?.pict, 0x32b)            // seed 1: 6 → 7, k 1 (SessionTests)
        XCTAssertEqual(s.lightTable.slots[24].previousFace?.pict, 0x32a)
        // Effects 3: 24 lights, and the op is still emitted though `.DrawLightsOntoTiles` is skipped.
        prefs.effects = 3
        let e3 = try FerazelSession(resources: try resources(), prefs: prefs, level: 1, seed: 1)
        XCTAssertEqual(e3.lightTable.count, 24)
        let ops3 = e3.step(keys: KeyState()).draws
        guard let k3 = ops3.firstIndex(where: { if case .lightTable = $0 { true } else { false } }) else {
            return XCTFail("no lightTable op at Effects 3")
        }
        XCTAssertFalse(ops3.contains(.drawLightsOntoTiles))
        guard case .wrapDrawWaterEffects = ops3[k3 + 1] else { return XCTFail("\(ops3[k3 + 1])") }
    }
}
