import XCTest
import HectorResources
@testable import FerazelCore

/// 6A-WD (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-WD`; docs/ferazel/phase6-engine-contracts.md
/// §2.2): wind cells — `.StandardSpriteHandles`' wind branch (M l. 32489–32574, raw `100369b0..10036c5c`), on every
/// sprite with a wind scale `+0x90 > 0`. Synthetic cells: level 1's `Mlvl` (no wind cell, water current 550) with
/// overlay cells patched in memory; the census reads the 24 shipped levels. A missing data file is a FAILURE, never a
/// skip.
final class WindTests: XCTestCase {

    /// One overlay cell: `o1` / `o2` as `.GetFGOverlay1Tile` / `2Tile` return them (the stored bytes are value + 1).
    private struct Cell { let col: Int; let row: Int; let o1: Int; let o2: Int }

    /// Level 1 with `cells` written into its overlay map (in memory; the data file is untouched).
    private func world(_ cells: [Cell]) throws -> SpriteWorld {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let mlvl = try XCTUnwrap(r.world.resource(type: "Mlvl", id: 1))
        let file = try LevelFile(resource: mlvl)
        XCTAssertEqual(file.header.waterCurrent, 550)
        let w2 = Int(file.header.gridWidth), h2 = Int(file.header.gridHeight)
        let base = LevelFile.headerSize + 2 * (Int(file.header.pxBackWidth) * Int(file.header.pxBackHeight)
                                               + Int(file.header.pxMidWidth) * Int(file.header.pxMidHeight)) + 6 * w2 * h2
        var d = mlvl.data
        for c in cells {
            let o = d.startIndex + base + 2 * (c.row * w2 + c.col)
            d[o] = UInt8(truncatingIfNeeded: c.o2 + 1)
            d[o + 1] = UInt8(truncatingIfNeeded: c.o1 + 1)
        }
        let level = try LevelFile(id: 1, data: d)
        for c in cells {
            XCTAssertEqual([level.overlay1(col: c.col, row: c.row), level.overlay2(col: c.col, row: c.row)], [c.o1, c.o2])
        }
        return SpriteWorld(level: level)
    }

    /// A sprite whose centre (`+0x10`, `+0xe`) is in cell (col, row), at rest, with wind scale `scale`.
    private func sprite(_ w: SpriteWorld, col: Int, row: Int, scale: Int16 = 0x100, vx: Int32 = 0,
                        vy: Int32 = 0) -> Int {
        w.newSprite(type: 1400, x: col * 32, y: row * 32, layer: 0, handler: .platform) { s in
            s.x = col * 32; s.y = row * 32
            s.x256 = Int32(col * 32) << 8; s.y256 = Int32(row * 32) << 8
            s.centre = SpriteSlot.Point(x: col * 32 + 16, y: row * 32 + 16)
            s.windScale = scale
            s.vx = vx; s.vy = vy
        }!
    }

    private func set(_ w: SpriteWorld, _ id: Int, vx: Int32, vy: Int32) {
        w.active.update(id: id) { $0.vx = vx; $0.vy = vy }
    }

    private func move(_ w: SpriteWorld, _ id: Int, col: Int, row: Int) {
        w.active.update(id: id) { $0.centre = SpriteSlot.Point(x: col * 32 + 16, y: row * 32 + 16) }
    }

    /// One `.StandardSpriteHandles` step: the x256 and vy deltas, the slot after.
    private func step(_ w: SpriteWorld, _ id: Int) -> (dx: Int32, dvy: Int32, s: SpriteSlot) {
        let before = w.active.sprite(id: id)!
        w.standardSpriteHandles(id)
        let after = w.active.sprite(id: id)!
        return (after.x256 - before.x256, after.vy - before.vy, after)
    }

    // MARK: - The gates

    func testWindGatesEachQuadrant() throws {
        // The table (raw `10036a58..10036b44`, the signed-compare idiom; ENG §2.2 step 4), each row at its edges.
        typealias G = (x: Bool, y: Bool)
        func g(_ v: Int16, _ h: Int16, _ vx: Int32, _ vy: Int32) -> [Bool] {
            let r: G = SpriteWorld.windGates(v: v, h: h, vx: vx, vy: vy)
            return [r.x, r.y]
        }
        // h ≥ 0, v ≥ 0: x-gate h ≥ vx, y-gate v ≥ vy.
        XCTAssertEqual(g(0, 150, 150, 0), [true, true])
        XCTAssertEqual(g(0, 150, 151, 1), [false, false])
        XCTAssertEqual(g(0, 150, -5000, 1), [true, false])
        // h ≥ 0, v < 0: x-gate h ≥ vx, y-gate vy ≥ v.
        XCTAssertEqual(g(-114, 96, 96, -114), [true, true])
        XCTAssertEqual(g(-114, 96, 97, -115), [false, false])
        // h < 0, v ≥ 0: x-gate vx ≥ h, y-gate v ≥ vy (unreachable from a cell: o1 0…15 give modes 18…33, none with
        // h < 0 and v ≥ 0 — the gate routine's row, as the binary has it).
        XCTAssertEqual(g(50, -30, -30, 50), [true, true])
        XCTAssertEqual(g(50, -30, -31, 51), [false, false])
        // v = 0 with h < 0 takes this row, not the crossed one: the binary's sign test is `v < 0` (signed;
        // `10036a68 cmpwi r8,0x0; bge 0x10036aa4` — v ≥ 0 branches to this row).
        XCTAssertEqual(g(0, -30, -30, 1), [true, false])
        // h < 0, v < 0: crossed — x-gate vy ≥ v, y-gate vx ≥ h.
        XCTAssertEqual(g(-147, -26, -27, -147), [true, false])
        XCTAssertEqual(g(-147, -26, -26, -148), [false, true])
        // Signed, not unsigned: a negative velocity against a positive impulse.
        XCTAssertEqual(g(0, 150, -1, -1), [true, true])

        // Through cells (each reachable row): o1 0 → mode 18 (v 0, h +s); o1 5 → mode 23 (v < 0, h > 0).
        let w = try world([Cell(col: 10, row: 10, o1: 0, o2: 10), Cell(col: 20, row: 10, o1: 5, o2: 10)])
        XCTAssertEqual([WaterEffects.lookupModedImpulse(mode: 18, amount: 150).v,
                        WaterEffects.lookupModedImpulse(mode: 18, amount: 150).h], [0, 150])
        XCTAssertEqual([WaterEffects.lookupModedImpulse(mode: 23, amount: 150).v,
                        WaterEffects.lookupModedImpulse(mode: 23, amount: 150).h], [-114, 96])
        let push23 = WaterEffects.lookupModedImpulse(mode: 23, amount: 140)
        XCTAssertEqual([push23.v, push23.h], [-107, 90])
        // o1 0: vx = h opens x (the push ramps: 140·1 / 33 = 4); vy 1 > v 0 closes y.
        let a = sprite(w, col: 10, row: 10, vx: 150, vy: 1)
        var r = step(w, a)
        XCTAssertEqual([r.dx, r.dvy], [4, 0])
        XCTAssertTrue(r.s.inWind)
        // vx one past h closes x; vy 0 opens y (v′ = 0): no visible push, but the ramp and the flag still move.
        set(w, a, vx: 151, vy: 0)
        r = step(w, a)
        XCTAssertEqual([r.dx, r.dvy], [0, 0])
        XCTAssertEqual(r.s.windRamp, 2)
        XCTAssertTrue(r.s.inWind)
        // Both closed: nothing — no ramp, no flag.
        set(w, a, vx: 151, vy: 1)
        r = step(w, a)
        XCTAssertEqual([r.dx, r.dvy], [0, 0])
        XCTAssertEqual(r.s.windRamp, 2)
        XCTAssertFalse(r.s.inWind)
        // o1 5: x-gate h 96 ≥ vx, y-gate vy ≥ v −114.
        let b = sprite(w, col: 20, row: 10, vx: 96, vy: -114)
        r = step(w, b)
        XCTAssertEqual([r.dx, r.dvy], [90 / 33, -107])
        set(w, b, vx: 97, vy: -115)
        r = step(w, b)
        XCTAssertEqual([r.dx, r.dvy], [0, 0])
        XCTAssertFalse(r.s.inWind)
        set(w, b, vx: 97, vy: -114)
        r = step(w, b)
        XCTAssertEqual([r.dx, r.dvy], [0, -107])
        XCTAssertEqual(r.s.windRamp, 2)
    }

    func testWindCrossedGatesOnDiagonalUpLeft() throws {
        // o1 10 → mode 28: test (v, h) = (−147, −26) at 15·10; push (−137, −24) at 14·10. Crossed as written
        // (raw `10036a98` takes the vy test into the x-gate, `10036a9c` the vx test into the y-gate).
        let w = try world([Cell(col: 10, row: 10, o1: 10, o2: 10)])
        let t = WaterEffects.lookupModedImpulse(mode: 28, amount: 150)
        let p = WaterEffects.lookupModedImpulse(mode: 28, amount: 140)
        XCTAssertEqual([t.v, t.h, p.v, p.h], [-147, -26, -137, -24])
        // vx 0 ≥ h (−26) but vy −148 < v: an uncrossed gate would push x and hold vy; as written vy gets the push and
        // x does not move.
        let a = sprite(w, col: 10, row: 10, vx: 0, vy: -148)
        var r = step(w, a)
        XCTAssertEqual([r.dx, r.dvy], [0, -137])
        XCTAssertTrue(r.s.inWind)
        XCTAssertEqual(r.s.windRamp, 1)
        XCTAssertEqual(r.s.windLast, -24)
        // vx −27 < h but vy −147 ≥ v: as written x is pushed (−24·2 / 33 = −1, C division) and vy is not.
        set(w, a, vx: -27, vy: -147)
        r = step(w, a)
        XCTAssertEqual([r.dx, r.dvy], [-1, 0])
        XCTAssertEqual(r.s.windRamp, 2)
        // Both tests pass: both pushes.
        set(w, a, vx: 0, vy: 0)
        r = step(w, a)
        XCTAssertEqual([r.dx, r.dvy], [-24 * 3 / 33, -137])
        // o1 9 → mode 27 (h 0, v −s): not crossed — x-gate 0 ≥ vx, y-gate vy ≥ v.
        let w9 = try world([Cell(col: 10, row: 10, o1: 9, o2: 20)])
        let t9 = WaterEffects.lookupModedImpulse(mode: 27, amount: 300)
        XCTAssertEqual([t9.v, t9.h], [-300, 0])
        let c = sprite(w9, col: 10, row: 10, vx: 1, vy: -300)
        r = step(w9, c)
        XCTAssertEqual([r.dx, r.dvy], [0, -280])
        set(w9, c, vx: 0, vy: -301)
        r = step(w9, c)
        XCTAssertEqual([r.dx, r.dvy], [0, 0])
        XCTAssertTrue(r.s.inWind)
    }

    // MARK: - The ramp, the scale, the strength

    func testWindRampUpAndOff() throws {
        // o1 0, o2 20: push h′ = 14·20 = 280, v′ = 0. In wind 36 frames, then out (o1 −1) 36 frames.
        let w = try world([Cell(col: 10, row: 10, o1: 0, o2: 20)])
        let a = sprite(w, col: 10, row: 10)
        var pushes: [Int32] = [], ramps: [Int16] = [], lasts: [Int16] = []
        for _ in 0..<36 {
            set(w, a, vx: 0, vy: 0)
            let r = step(w, a)
            pushes.append(r.dx); ramps.append(r.s.windRamp); lasts.append(r.s.windLast)
        }
        XCTAssertEqual(pushes, (1...33).map { Int32(280 * $0 / 33) } + [280, 280, 280])
        XCTAssertEqual(Array(pushes.prefix(4)), [8, 16, 25, 33])
        XCTAssertEqual(ramps, (1...33).map { Int16($0) } + [33, 33, 33])
        XCTAssertEqual(Set(lasts), [280], "+0x98 stored un-ramped (M l. 32563)")
        move(w, a, col: 30, row: 10)
        pushes = []; ramps = []
        for _ in 0..<36 {
            let r = step(w, a)
            pushes.append(r.dx); ramps.append(r.s.windRamp)
            XCTAssertFalse(r.s.inWind)
            XCTAssertEqual(r.s.windLast, 280, "the leaving arm reuses +0x98 (M l. 32496–32498)")
        }
        XCTAssertEqual(pushes, (0...32).reversed().map { Int32(280 * $0 / 33) } + [0, 0, 0])
        XCTAssertEqual(ramps, (0...32).reversed().map { Int16($0) } + [0, 0, 0])

        // A negative push divides toward zero (C division): o1 12 → mode 30, push (v′, h′) = (−242, −140).
        let wn = try world([Cell(col: 10, row: 10, o1: 12, o2: 20)])
        let p = WaterEffects.lookupModedImpulse(mode: 30, amount: 280)
        XCTAssertEqual([p.v, p.h], [-242, -140])
        let b = sprite(wn, col: 10, row: 10)
        var down: [Int32] = []
        for _ in 0..<33 {
            set(wn, b, vx: 0, vy: 0)
            down.append(step(wn, b).dx)
        }
        XCTAssertEqual(down[0], -4, "−140 / 33 truncates to −4 (a floor would give −5)")
        XCTAssertEqual(down, (1...33).map { Int32(-140 * $0 / 33) })
        move(wn, b, col: 30, row: 10)
        XCTAssertEqual(step(wn, b).dx, -135, "−140·32 / 33 = −135.8 → −135")
        // The leaving arm with the ramp already 0 adds nothing and keeps +0x98.
        let c = sprite(wn, col: 30, row: 10)
        wn.active.update(id: c) { $0.windLast = -140 }
        let r = step(wn, c)
        XCTAssertEqual([r.dx, Int32(r.s.windRamp), Int32(r.s.windLast)], [0, 0, -140])
    }

    func testWindScaleBelow255() throws {
        // o1 0, o2 20 (h′ 280) and o1 12, o2 20 (v′ −242, h′ −140); the ramp held at 33 so the push is h′ itself.
        let w = try world([Cell(col: 10, row: 10, o1: 0, o2: 20), Cell(col: 20, row: 10, o1: 12, o2: 20)])
        func push(col: Int, scale: Int16) -> [Int32] {
            let id = sprite(w, col: col, row: 10, scale: scale)
            w.active.update(id: id) { $0.windRamp = 33 }
            let r = step(w, id)
            return [r.dx, r.dvy, Int32(r.s.windLast)]
        }
        XCTAssertEqual(push(col: 10, scale: 0x100), [280, 0, 280])           // the player's scale: no shift
        XCTAssertEqual(push(col: 10, scale: 0xff), [280, 0, 280], "0xff is not below 0xff: no shift (M l. 32552)")
        XCTAssertEqual(push(col: 10, scale: 0xfe), [(280 * 254) >> 8, 0, 277])
        XCTAssertEqual(push(col: 10, scale: 0x80), [140, 0, 140])
        XCTAssertEqual(push(col: 10, scale: 1), [1, 0, 1])
        // Arithmetic shifts on negatives: −140·0x81 = −18060 >> 8 = −71 (a division would give −70); −242·0x81 =
        // −31218 >> 8 = −122 (a division would give −121).
        XCTAssertEqual(push(col: 20, scale: 0x81), [-71, -122, -71])
        XCTAssertEqual(push(col: 20, scale: 0x100), [-140, -242, -140])
        // Scale ≤ 0: immune — the branch is skipped (`lha 0x90; cmpwi 0; ble`, raw `100369b0..100369b8`).
        for scale: Int16 in [0, -1] {
            let id = sprite(w, col: 10, row: 10, scale: scale)
            w.active.update(id: id) { $0.windRamp = 5; $0.windLast = 99 }
            let r = step(w, id)
            XCTAssertEqual([r.dx, r.dvy, Int32(r.s.windRamp), Int32(r.s.windLast)], [0, 0, 5, 99])
            XCTAssertFalse(r.s.inWind)
        }
    }

    func testWindNeedsPositiveStrength() throws {
        // o1 in 0…15 with o2 ≤ 0: no push and no ramp-down (`extsh. r0,r3; ble` to the end, raw `10036a08..10036a0c`).
        let w = try world([Cell(col: 10, row: 10, o1: 0, o2: 0), Cell(col: 11, row: 10, o1: 9, o2: -1),
                           Cell(col: 12, row: 10, o1: 15, o2: 1), Cell(col: 13, row: 10, o1: 16, o2: 50),
                           Cell(col: 14, row: 10, o1: 0, o2: 254)])
        for col in [10, 11] {
            let id = sprite(w, col: col, row: 10)
            w.active.update(id: id) { $0.windRamp = 10; $0.windLast = 280 }
            let r = step(w, id)
            XCTAssertEqual([r.dx, r.dvy, Int32(r.s.windRamp), Int32(r.s.windLast)], [0, 0, 10, 280])
            XCTAssertFalse(r.s.inWind)
        }
        // o2 1 is enough (o1 15 → mode 33, push (−7, −12) at 14).
        let p = WaterEffects.lookupModedImpulse(mode: 33, amount: 14)
        XCTAssertEqual([p.v, p.h], [-7, -12])
        let one = sprite(w, col: 12, row: 10)
        XCTAssertTrue(step(w, one).s.inWind)
        // o1 16 (dust only, o2 50) is outside 0…15: the leaving arm runs.
        let dust = sprite(w, col: 13, row: 10)
        w.active.update(id: dust) { $0.windRamp = 10; $0.windLast = 280 }
        let r = step(w, dust)
        XCTAssertEqual([r.dx, Int32(r.s.windRamp)], [280 * 9 / 33, 9])
        XCTAssertFalse(r.s.inWind)
        // The largest strength the byte holds (254): 15·254 = 3810 fits an i16; push 14·254 = 3556.
        let big = sprite(w, col: 14, row: 10)
        w.active.update(id: big) { $0.windRamp = 33 }
        XCTAssertEqual(step(w, big).dx, 3556)
    }

    func testWindSetsInWindFlag() throws {
        let w = try world([Cell(col: 10, row: 10, o1: 9, o2: 20)])
        let a = sprite(w, col: 10, row: 10)
        // `+0x92 = 0` at the top of every `.StandardSpriteHandles` (M l. 32460), wind scale or not.
        let immune = sprite(w, col: 10, row: 10, scale: 0)
        w.active.update(id: immune) { $0.inWind = true }
        XCTAssertFalse(step(w, immune).s.inWind)
        var r = step(w, a)
        XCTAssertTrue(r.s.inWind)
        XCTAssertEqual(r.dvy, -280)
        // The player's air counter reads it (`.HandlePlayerSprite`'s airborne arm, M l. 46106–46109): falling at
        // c ≥ 10 counts up only out of wind, and in wind c > 14 counts down.
        w.playerID = a
        w.player.airCounter = 20
        w.active.update(id: a) { $0.vy = 0x100 }
        _ = PlayerStates.airborne(w, id: a)
        XCTAssertEqual(w.player.airCounter, 19)
        // Out of wind the next frame: the flag is cleared at the top and not re-earned.
        move(w, a, col: 30, row: 10)
        r = step(w, a)
        XCTAssertFalse(r.s.inWind)
        w.player.airCounter = 20
        w.active.update(id: a) { $0.vy = 0x100 }
        _ = PlayerStates.airborne(w, id: a)
        XCTAssertEqual(w.player.airCounter, 21)
        // The cell is the centre's (`+0x10`, `+0xe`; raw `100369bc lha r3,0x10(r27)`, `100369c0 lha r0,0xe(r27)`), not
        // the pixel copies' (`+0xc`, `+0xa`): y on the wind cell's row, centre one row below — no wind; and the
        // reverse — wind.
        let below = sprite(w, col: 10, row: 10)
        w.active.update(id: below) { $0.centre = SpriteSlot.Point(x: 10 * 32 + 16, y: 11 * 32 + 16) }
        XCTAssertFalse(step(w, below).s.inWind)
        let above = sprite(w, col: 10, row: 9)
        w.active.update(id: above) { $0.centre = SpriteSlot.Point(x: 10 * 32 + 16, y: 10 * 32 + 16) }
        XCTAssertTrue(step(w, above).s.inWind)

        // The branch's place (ENG §2.2): before the ride carry — the carry's pixel copy `+0xc` already holds the wind's
        // push. "After the water current" is not pinned here and cannot be: the current only adds to x256 and writes
        // its own fields, the wind reads the centre, vx and vy, so the two steps commute (the 6A-WD review moved the
        // wind before the current and no test could tell). The rider below makes the current push 0; it shows only
        // that both run in the one step.
        let wc = try world([Cell(col: 10, row: 10, o1: 0, o2: 20)])
        let solid = wc.newSprite(type: 1400, x: 320, y: 352, layer: -1, handler: .platform) { $0.x = 320; $0.y = 352 }!
        _ = wc.active.wrapDrawSprites()
        let rider = sprite(wc, col: 10, row: 10)
        wc.active.update(id: rider) { $0.windRamp = 33; $0.waterRow = 1; $0.currentRamp = 33; $0.ridden = solid }
        let before = wc.active.sprite(id: rider)!
        wc.standardSpriteHandles(rider)
        let after = wc.active.sprite(id: rider)!
        // The current pushes 0 while riding; the wind 280; the carry 0 (the solid did not move) — and x = x256 >> 8.
        XCTAssertEqual(after.x256 - before.x256, 280)
        XCTAssertEqual(after.x, Int((before.x256 + 280) >> 8))
        XCTAssertEqual(after.currentRamp, 33)
        XCTAssertEqual(after.lastWater, 1)
        XCTAssertTrue(after.inWind)
    }

    // MARK: - The census

    func testWindCellCensus() throws {
        // The 24 levels' overlay cells with o1 in 0…15 and o2 > 0 (LL §10.1, ENG §2.2), read from the level files.
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let levels = r.world.resources(of: "Mlvl").sorted { $0.id < $1.id }
        XCTAssertEqual(levels.count, 24)
        var wind: [Int16: Int] = [:], crossed: [Int16: Int] = [:], weak: [Int16: Int] = [:]
        var split: [Int16: [String: Int]] = [:]
        for res in levels {
            let l = try LevelFile(resource: res)
            for row in 0..<l.overlay.height {
                for col in 0..<l.overlay.width {
                    let o1 = l.overlay1(col: col, row: row)
                    guard 0 <= o1 && o1 <= 15 else { continue }
                    let o2 = l.overlay2(col: col, row: row)
                    guard o2 > 0 else { weak[l.id, default: 0] += 1; continue }
                    wind[l.id, default: 0] += 1
                    if o1 >= 10 { crossed[l.id, default: 0] += 1 }
                    split[l.id, default: [:]]["\(o1)/\(o2)", default: 0] += 1
                }
            }
        }
        XCTAssertEqual(wind, [10: 103, 20: 2899], "no other level has a wind cell (levels 1–5 none)")
        XCTAssertEqual(crossed, [10: 4, 20: 36], "o1 10…15: the crossed gates")
        XCTAssertEqual(weak, [:], "no cell with o1 in 0…15 and o2 ≤ 0")
        XCTAssertEqual(split[10], ["9/20": 28, "9/50": 71, "10/50": 4])
        XCTAssertEqual(split[20]?["12/50"], 36)
        XCTAssertEqual(split[20]?.keys.compactMap { Int($0.split(separator: "/")[0]) }.max(), 12)
    }
}
