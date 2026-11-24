import XCTest
@testable import FerazelCore

/// 6A-MP (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-MP`; docs/ferazel/phase6-engine-contracts.md
/// §2.10, E19): the programmed-path maces — the radial bars and balls 0x5c8…0x5d1 with mode `+0xb0` 1 (up and down) or
/// 2 (left and right). The Setup arm of `.SetupBackgroundSprite` (M l. 62337–62360, after the common stores and the
/// record write-backs M l. 62312–62336) runs `.SetupProgrammedPath(s, −1, 0)` (M l. 39288–39381, the one
/// `ProgrammedPath`); the Handle arm (M l. 63137–63146) re-faces the sprite and runs `.HandleProgrammedPath` (M l.
/// 39384–39462) and `.ApplyGravityAndSeparateFromTiles`; the radial and its chain belong to modes 10–14 only (M l.
/// 62362–62427, 63147–63187). The Setup is read per record from the level files (levels 20 and 22 place them;
/// `SetupFaces.setup`, no level opened) and on synthetic records; the Handle runs on synthetic paths and level records in
/// level 20's world. A missing data file is a FAILURE, never a skip.
final class MacePathTests: XCTestCase {

    private typealias Rect = IdleSprites.Rect

    /// The game data, opened once (`LevelFixture.base`; the Handle loop asks for it every frame).
    private func resources() throws -> FerazelResources { try LevelFixture.base.get() }

    /// The mace records of `level` (0x5c8…0x5d1) with p1 = `mode`, from the level file.
    private func paths(_ level: Int, mode: Int16) throws -> (LevelFile, [Placement]) {
        let L = try LevelFile.load(from: try resources(), level: Int16(level))
        return (L, L.activePlacements.filter { BackgroundSprite.maces.contains($0.type) && $0.p1 == mode })
    }

    private func rec(type: Int16 = 1485, p1: Int16 = 1, p2: Int16 = 0x20, p3: Int16 = 0x100, p4: Int16 = 0,
                     index: Int = 266, x: Int16 = 1000, y: Int16 = 1000) -> Placement {
        Placement(index: index, flag: 1, byte1: 0, type: type, p1: p1, p2: p2, p3: p3, p4: p4, y: y, x: x)
    }

    /// Level 20's world (its records as `w.records`).
    private func world() throws -> SpriteWorld {
        SpriteWorld(level: try LevelFile.load(from: try resources(), level: 20))
    }

    /// A mace set up for record `p` (`SetupFaces.setup`) and spawned into `w` as `spawnLevelSprites` spawns one (the
    /// insert, then `BackgroundSprite.makeRadial`); `w.records[p.index]` = the record as the Setup left it.
    private func mace(_ w: SpriteWorld, _ p: Placement) throws -> Int {
        let e = try SetupFaces.setup(p, context: SetupFaces.Context(level: w.level, playerX: 0))
        if w.records.indices.contains(p.index) { w.records[p.index] = e.record }
        let id = w.active.insert(e.slot)
        BackgroundSprite.makeRadial(w, id: id, record: e.record)
        return id
    }

    /// One Handle of sprite `id`.
    @discardableResult
    private func handle(_ w: SpriteWorld, _ id: Int) throws -> SpriteSlot {
        let r = try resources()
        BackgroundSprite.handle(world: w, id: id) { FerazelSession.frameRect($0, resources: r).right }
        return try XCTUnwrap(w.active.sprite(id: id))
    }

    /// The Setup's stores every mode-1 / mode-2 mace shares (M l. 62312–62342 and `setupCommon`).
    private func assertCommon(_ e: SetupFaces.Entry, _ p: Placement, mode: Int16, _ what: String,
                              file: StaticString = #filePath, line: UInt = #line) {
        let s = e.slot
        XCTAssertEqual(e.spriteClass, .background, what, file: file, line: line)
        XCTAssertEqual(s.subtype, mode, what, file: file, line: line)                       // `+0xb0` = p1 (M l. 62324)
        XCTAssertEqual(s.classWord170, 1, what, file: file, line: line)                     // `+0x170 = 1` (M l. 62340)
        XCTAssertFalse(s.oneWay, "\(what): +0x185 = 0 (M l. 62341)", file: file, line: line)
        XCTAssertTrue(s.keepRecord, "\(what): +0x188 = 1 (M l. 62342)", file: file, line: line)
        XCTAssertEqual([s.pathMode, s.pathSpeed, s.pathDirection], [Int32(mode), Int32(e.record.p3), 1], what,
                       file: file, line: line)
        // `+0x5c` / `+0x1f8` 0 (M l. 62313–62314); the rect from 0x5cd on (M l. 62315–62320).
        XCTAssertEqual([s.hasHit, s.hasTileHit], [false, false], what, file: file, line: line)
        XCTAssertEqual(s.hotRect, p.type < BackgroundSprite.firstBall
                       ? Rect(top: 0x2c, left: 0x12, bottom: 0x44, right: 0x6e)
                       : Rect(top: 0x16, left: 0x16, bottom: 0x4e, right: 0x4e), what, file: file, line: line)
        // The common head (`setupCommon`), and none of the mode 10–14 stores: `+0xa6` stays 3 (M l. 62386 is the
        // radial branch's), no radial block.
        XCTAssertEqual([Int(s.layer), Int(s.hp), Int(s.counterA6)], [1, 6, 3], what, file: file, line: line)
        XCTAssertNil(s.radial, what, file: file, line: line)
        XCTAssertEqual(e.source, .setupCached, what, file: file, line: line)
    }

    // MARK: - the Setup arm (M l. 62337–62360)

    func testMacePathSetupModeOne() throws {
        // The data (ENG §2.10 "Switch", re-read): mode 1 ×16 on level 20 and ×23 on level 22, every one the ball 1485;
        // every p2 and p3 non-zero (the write-backs leave them); p4 non-zero on six of each level.
        var census: [Int: [Int]] = [:]
        for level in [20, 22] {
            let (L, list) = try paths(level, mode: 1)
            census[level] = [list.count, list.filter { $0.type != 1485 }.count, list.filter { $0.p4 != 0 }.count]
            let c = SetupFaces.Context(level: L, playerX: 0)
            for p in list {
                let what = "level \(level) record \(p.index)"
                XCTAssertTrue(p.p2 != 0 && p.p3 != 0, what)
                var rng = FastRand(seed: 7)
                let e = try SetupFaces.setup(p, context: c, rng: &rng)
                XCTAssertEqual(rng.seed, FastRand(seed: 7).seed, "\(what): no random draw")
                XCTAssertEqual(e.record, p, "\(what): nothing to write back")
                assertCommon(e, p, mode: 1, what)
                let s = e.slot
                // `.SetupProgrammedPath` mode 1 (M l. 39330–39340): the bounds from `+0x1c` **before** the p4 offset
                // (M l. 62343, then 62344–62348): near = y·256 + 8·p3, far = y·256 + 256·p2 − 8·p3; vy = p3, vx 0,
                // `+0x13a` 0. Then `+0x1c += 256·p4`; `+0xa` = `+6` = y + p4, `+0xc` = `+8` = x (M l. 62354–62359).
                let y256 = Int32(p.y) << 8
                XCTAssertEqual(s.pathLow, y256 + 8 * Int32(p.p3), what)
                XCTAssertEqual(s.pathHigh, y256 + 256 * Int32(p.p2) - 8 * Int32(p.p3), what)
                XCTAssertEqual([s.vy, s.vx, Int32(s.sag)], [Int32(p.p3), 0, 0], what)
                XCTAssertEqual([s.y256, s.x256], [y256 + 256 * Int32(p.p4), Int32(p.x) << 8], what)
                XCTAssertEqual([s.x, s.y], [Int(p.x), Int(p.y) + Int(p.p4)], what)
                XCTAssertEqual(s.oldPosition, SpriteSlot.Point(x: Int(p.x), y: Int(p.y) + Int(p.p4)), what)
                // The bounds come before the offset: a mace whose p4 = p2 starts beyond its far bound.
                if p.p4 == p.p2 { XCTAssertGreaterThan(s.y256, s.pathHigh, what) }
            }
        }
        XCTAssertEqual(census, [20: [16, 0, 6], 22: [23, 0, 6]])
        XCTAssertEqual(try paths(20, mode: 1).1.filter { $0.p4 == $0.p2 }.count, 5)

        let w = try world()
        let c = SetupFaces.Context(level: w.level, playerX: 0)
        // The write-backs come first (M l. 62329–62336 before 62343): p2 0 → 0x8c and p3 0 → 0x1e are the path's.
        let e0 = try SetupFaces.setup(rec(p2: 0, p3: 0), context: c)
        XCTAssertEqual([e0.record.p2, e0.record.p3], [0x8c, 0x1e])
        XCTAssertEqual([e0.slot.pathSpeed, e0.slot.vy], [0x1e, 0x1e])
        // y 1000 · 256 = 256000; + 8 · 0x1e = 256240; + 0x8c · 256 − 8 · 0x1e = 291600.
        XCTAssertEqual([e0.slot.pathLow, e0.slot.pathHigh], [256240, 291600])
        // A negative offset (synthetic): up from the record, the bounds unchanged (256000 + 8·256; + 32·256 − 8·256).
        let e1 = try SetupFaces.setup(rec(p4: -50), context: c)
        XCTAssertEqual([e1.slot.x, e1.slot.y, Int(e1.slot.y256)], [1000, 950, 243200])
        XCTAssertEqual([e1.slot.pathLow, e1.slot.pathHigh], [258048, 262144])
        // The pixel copies are 16-bit (`(short)(+0x1c >> 8)`): y 30000 + p4 5000 → −30536.
        let e2 = try SetupFaces.setup(rec(p4: 5000, y: 30000), context: c)
        XCTAssertEqual([Int(e2.slot.y256), e2.slot.y, e2.slot.oldPosition.y], [8960000, -30536, -30536])
        // A bar (0x5c8, synthetic: no level places a bar on a path) takes the bar's rect and the same path.
        let e3 = try SetupFaces.setup(rec(type: 1480), context: c)
        assertCommon(e3, rec(type: 1480), mode: 1, "the bar")
        XCTAssertEqual([e3.slot.pathLow, e3.slot.pathHigh], [258048, 262144])
    }

    func testMacePathSetupModeTwo() throws {
        // Mode 2 ×6 on level 22 (none on 20), every one 1485 with p4 0.
        let (L20, none) = try paths(20, mode: 2)
        XCTAssertEqual(none.count, 0)
        _ = L20
        let (L, list) = try paths(22, mode: 2)
        XCTAssertEqual(list.map { [$0.index, Int($0.type), Int($0.p4)] },
                       [[314, 1485, 0], [315, 1485, 0], [346, 1485, 0], [374, 1485, 0], [396, 1485, 0], [466, 1485, 0]])
        let c = SetupFaces.Context(level: L, playerX: 0)
        for p in list {
            let what = "level 22 record \(p.index)"
            var rng = FastRand(seed: 7)
            let e = try SetupFaces.setup(p, context: c, rng: &rng)
            XCTAssertEqual(rng.seed, FastRand(seed: 7).seed, "\(what): no random draw")
            XCTAssertEqual(e.record, p, what)
            assertCommon(e, p, mode: 2, what)
            // `.SetupProgrammedPath` mode 2 (M l. 39342–39351): the same bounds on `+0x14`; vx = p3, vy 0; `+0x13a`
            // not written (stays 0).
            let x256 = Int32(p.x) << 8
            XCTAssertEqual(e.slot.pathLow, x256 + 8 * Int32(p.p3), what)
            XCTAssertEqual(e.slot.pathHigh, x256 + 256 * Int32(p.p2) - 8 * Int32(p.p3), what)
            XCTAssertEqual([e.slot.vx, e.slot.vy], [Int32(p.p3), 0], what)
            XCTAssertEqual([e.slot.x, e.slot.y], [Int(p.x), Int(p.y)], what)
        }
        // The offset moves x (M l. 62349–62353), after the bounds; y untouched.
        let w = try world()
        let wc = SetupFaces.Context(level: w.level, playerX: 0)
        let e = try SetupFaces.setup(rec(p1: 2, p2: 0x40, p3: 0x200, p4: 100), context: wc)
        XCTAssertEqual([e.slot.x, e.slot.y, Int(e.slot.x256), Int(e.slot.y256)], [1100, 1000, 281600, 256000])
        XCTAssertEqual(e.slot.oldPosition, SpriteSlot.Point(x: 1100, y: 1000))
        // x 1000 · 256 = 256000; + 8 · 0x200 = 260096; + 0x40 · 256 − 8 · 0x200 = 268288.
        XCTAssertEqual([e.slot.pathLow, e.slot.pathHigh], [260096, 268288])
        XCTAssertEqual([e.slot.vx, e.slot.vy], [0x200, 0])

        // Only 1 and 2 take the arm (`sVar21 < 3 && 0 < sVar21`, M l. 62339): modes 3…9, 15 and a negative p1 take no
        // branch — no path, no flag, not one-way (synthetic: no level places them).
        for m: Int16 in [3, 9, 15, -1] {
            let s = try SetupFaces.setup(rec(p1: m), context: wc).slot
            XCTAssertEqual([s.pathMode, s.pathDirection, s.classWord170, s.vy], [0, 0, 0, 0], "mode \(m)")
            XCTAssertEqual([s.keepRecord, s.oneWay], [false, false], "mode \(m)")
            XCTAssertEqual([s.x, s.y], [1000, 1000], "mode \(m)")
        }
    }

    // MARK: - the Handle arm (M l. 63137–63146)

    func testMacePathHandleMoves() throws {
        let w = try world()
        // A synthetic mode-1 path at (1000, 1000): p2 32, p3 0x100 — near bound y 1008, far bound 1024, 1 px a frame.
        let id = try mace(w, rec())
        var trace: [[Int32]] = []
        for k in 1...232 {
            w.active.update(id: id) { $0.face = nil }
            let s = try handle(w, id)
            // Every Handle: the face from the cache single (M l. 63138–63139); x and the flags untouched; no layer
            // change, no rotation, `+0x194` 0 (`.HandleProgrammedPath`).
            XCTAssertEqual(s.face, FaceRef(pict: 1485, index: 0, set: .encoded), "Handle \(k)")
            XCTAssertEqual([s.x, Int(s.vx), Int(s.layer), Int(s.rotation), Int(s.jumpBonus)], [1000, 0, 1, 0, 0],
                           "Handle \(k)")
            XCTAssertEqual([s.classWord170, Int32(s.counterA6)], [1, 3], "Handle \(k)")
            XCTAssertEqual(s.y, SpriteWorld.pixel(s.y256), "Handle \(k)")
            XCTAssertEqual(s.oldPosition, SpriteSlot.Point(x: s.x, y: s.y), "Handle \(k)")
            trace.append([s.y256, s.vy, s.pathDirection])
        }
        // The shuttle (derived from the dump by hand: `.HandleProgrammedPath` then `+0x1c += vy` with gravity 0): down
        // at 1 px a frame; the far bound is passed on Handle 25 (y 1025 > 1024), so Handle 26 turns (direction −1, vy
        // still 0x100); then vy − 0x10 a frame (p3 >> 4) to −0x100; the near bound passed on Handle 76, Handle 77 turns
        // back; Handle 128 turns again in the state of Handle 26 — a period of 102 Handles.
        let turns = trace.indices.dropFirst().filter { trace[$0][2] != trace[$0 - 1][2] }.map { $0 + 1 }
        XCTAssertEqual(turns, [26, 77, 128, 179, 230])
        XCTAssertEqual(trace[25], [262656, 256, -1])
        XCTAssertEqual(trace[76], [257536, -256, 1])
        XCTAssertEqual(trace[127], trace[25])
        for k in 26..<(232 - 102) { XCTAssertEqual(trace[k + 102], trace[k], "Handle \(k + 1)") }
        let ys = trace.map { Int($0[0] >> 8) }
        XCTAssertEqual(Array(ys.prefix(26)), Array(1001...1026))
        XCTAssertEqual([ys.min(), ys.max()], [998, 1033])
        // Between the turns vy steps by exactly p3 >> 4, never past ±p3.
        for k in 1..<trace.count where trace[k][2] == trace[k - 1][2] {
            let dv = trace[k][1] - trace[k - 1][1]
            XCTAssertTrue(dv == 0 || abs(dv) == 0x10, "Handle \(k + 1)")
            XCTAssertLessThanOrEqual(abs(trace[k][1]), 0x100, "Handle \(k + 1)")
        }

        // Mode 2: the same on x; y never moves.
        let id2 = try mace(w, rec(p1: 2, index: 267))
        var xs: [Int] = []
        for _ in 1...130 {
            let s = try handle(w, id2)
            XCTAssertEqual([s.y, Int(s.vy)], [1000, 0])
            xs.append(s.x)
        }
        XCTAssertEqual(Array(xs.prefix(26)), Array(1001...1026))
        XCTAssertEqual([xs.min(), xs.max()], [998, 1033])

        // Level 20's record 266 (y 436, p2 440, p3 2600, p4 0) and record 267 beside it (p4 440 — it starts at its far
        // end, beyond the far bound, so its first Handle turns it): one full shuttle each, 124 Handles a period.
        let (L, list) = try paths(20, mode: 1)
        let w20 = SpriteWorld(level: L)
        func shuttle(_ index: Int) throws -> (turns: [Int], ys: [Int]) {
            let p = try XCTUnwrap(list.first { $0.index == index })
            let m = try mace(w20, p)
            var d: [Int32] = [], ys: [Int] = []
            for _ in 1...200 {
                let s = try handle(w20, m)
                d.append(s.pathDirection)
                ys.append(s.y)
            }
            return (d.indices.dropFirst().filter { d[$0] != d[$0 - 1] }.map { $0 + 1 }, ys)
        }
        let a = try shuttle(266), b = try shuttle(267)
        XCTAssertEqual(a.turns, [37, 99, 161])
        XCTAssertEqual([a.ys.first, a.ys.min(), a.ys.max()], [446, 421, 888])
        XCTAssertEqual(b.turns, [70, 132, 194])
        XCTAssertEqual([b.ys.first, b.ys.min(), b.ys.max()], [886, 424, 962])
        for k in 36..<76 { XCTAssertEqual(a.ys[k + 124], a.ys[k], "record 266, Handle \(k + 1): periodic") }
    }

    // MARK: - no chain, no radial, no spoke update (M l. 62362–62427, 63147–63187; E19)

    func testMacePathMakesNoChain() throws {
        // Level 20 spawned whole, as `.SetupLevelSprites` does from seed 1 (nothing left out — every record set up):
        // the 16 path balls have no radial block and make no chain; the only chains are the four radial bars 1480
        // (mode 10, p2 150 → 150 / 16 = 9 spokes each).
        let L = try LevelFile.load(from: try resources(), level: 20)
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header))
        var rng = FastRand(seed: 1)
        let sp = try SetupFaces.spawnLevelSprites(context: c, rng: &rng) { _ in .noFace }
        let balls = sp.active.sprites.filter { $0.type == 1485 }
        XCTAssertEqual(balls.count, 16, "every path ball spawned now")
        XCTAssertTrue(balls.allSatisfy { $0.radial == nil && $0.pathMode == 1 && $0.siblings == SpriteSlot.Siblings() })
        let bars = sp.active.sprites.filter { $0.type == 1480 }
        XCTAssertEqual(bars.map { Int($0.subtype) }, [10, 10, 10, 10])
        XCTAssertTrue(bars.allSatisfy { $0.radial != nil })
        let chains = sp.active.sprites.filter { $0.handler == .chain }
        XCTAssertEqual(chains.count, 36)
        XCTAssertEqual(Set(chains.map(\.type)), [ChainSprite.maceChain])

        // Level 22's 29 path balls, one by one in level 20's world: the spawn's `makeRadial` adds nothing (a mode-10
        // ball of 22 beside them makes its spokes — the control).
        let (L22, one) = try paths(22, mode: 1)
        let two = try paths(22, mode: 2).1
        let w = SpriteWorld(level: L22)
        for p in one + two {
            let before = w.active.sprites.count
            let id = try mace(w, p)
            XCTAssertEqual(w.active.sprites.count, before + 1, "record \(p.index): the ball only")
            XCTAssertNil(try XCTUnwrap(w.active.sprite(id: id)).radial, "record \(p.index)")
        }
        XCTAssertEqual(one.count + two.count, 29)
        let ten = try XCTUnwrap(L22.activePlacements.first { $0.type == 1485 && $0.p1 == 10 })
        let before = w.active.sprites.count
        _ = try mace(w, ten)
        XCTAssertGreaterThan(w.active.sprites.count, before + 1, "a mode-10 ball makes its chain")

        // The Handle updates no spoke and runs no radial step (M l. 63141–63146): 150 Handles of a path ball in the
        // spawned level-20 world leave every other sprite — the bars' chains included — as they were.
        let w20 = SpriteWorld(level: L, active: sp.active)
        let ball = try XCTUnwrap(w20.active.sprites.first { $0.type == 1485 && $0.recordIndex == 266 })
        let id = ball.id
        XCTAssertEqual(ball.y, 436)
        let others = w20.active.sprites.filter { $0.id != id }
        for _ in 0..<150 { try handle(w20, id) }
        XCTAssertEqual(w20.active.sprites.filter { $0.id != id }, others)
        let s = try XCTUnwrap(w20.active.sprite(id: id))
        XCTAssertNil(s.radial)
        XCTAssertNotEqual(s.y, 436, "it moved")
    }

    // MARK: - the write-back flag `+0x188` (M l. 62342)

    func testMacePathWriteBackFlag() throws {
        // Every path mace of levels 20 and 22 keeps its record (`+0x188 = 1`) and sets no other save flag.
        var n = 0
        for level in [20, 22] {
            for mode: Int16 in [1, 2] {
                let (L, list) = try paths(level, mode: mode)
                let c = SetupFaces.Context(level: L, playerX: 0)
                for p in list {
                    let s = try SetupFaces.setup(p, context: c).slot
                    XCTAssertEqual([s.keepRecord, s.noWriteBack189, s.noWriteBack18a, s.keepRecordAtKill,
                                    s.killedForGood], [true, false, false, false, false], "level \(level) record \(p.index)")
                    n += 1
                }
            }
        }
        XCTAssertEqual(n, 16 + 29)

        // `.UpdateSprites` (M l. 4959): a moved path mace leaves its record's position as placed; the same sprite
        // with the flag cleared writes its y back (the twin — the flag is what keeps it).
        func moved(keep: Bool) throws -> Placement {
            let w = try world()
            let p = try XCTUnwrap(w.records.first { $0.index == 266 })
            let id = try mace(w, p)
            if !keep { w.active.update(id: id) { $0.keepRecord = false } }
            for _ in 0..<10 { try handle(w, id) }
            var lights = LightTable()
            w.updateSprites(lights: &lights)
            return w.records[266]
        }
        let kept = try moved(keep: true), written = try moved(keep: false)
        XCTAssertEqual([kept.x, kept.y], [10436, 436])
        XCTAssertEqual(written.x, 10436)
        XCTAssertNotEqual(written.y, 436)
    }
}
