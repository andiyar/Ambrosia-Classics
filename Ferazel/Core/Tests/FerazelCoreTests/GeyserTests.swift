import XCTest
@testable import FerazelCore

/// GY (docs/plans/2026-10-30-ferazel-phase5.md; geysers.md): the geysers 1440…1449 — `.SetupBoxSprite`'s head arm and
/// geyser arm (M l. 59107–59185), `.HandleBoxSprite`'s eruption arm and triple re-targeting (M l. 60379–60483),
/// `.HandleGeyserColumn` (M l. 59731–59917), `.SetupEffectSprite`'s 0x5a0 arm (M l. 53805–53811), `.HitPlayerSprite`'s
/// head hurt (M l. 49312–49335) and the 0x5a0 part of its Effect test (M l. 49763–49799), `.KillBox` (M l.
/// 61502–61517). Geysers are placed only on levels 10, 50 and 51: every placement here is made by hand over level 3's
/// header and an empty synthetic 60×30 grid. Every expected draw is re-derived from a copy of the stream.
final class GeyserTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    nonisolated(unsafe) private static let level3 = Result {
        try LevelFile.load(from: try FerazelData.open(try FerazelData.dataDirectory()), level: 3)
    }

    private func world(player: Bool = false) throws -> (SpriteWorld, Int?) {
        let w = SpriteWorld(level: try Self.level3.get())
        let empty = [UInt16](repeating: 0, count: 60 * 30)
        w.tiles = TileGrid(fg: TileMap(width: 60, height: 30, cells: empty), bg: TileMap(width: 60, height: 30, cells: empty),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        w.levelIndex = 3
        guard player else { return (w, nil) }
        let p = try XCTUnwrap(Player.spawn(world: w, x: 1200, y: 300))
        w.playerID = p
        return (w, p)
    }

    private func place(_ type: Int16, x: Int16 = 400, y: Int16 = 600, p1: Int16 = 0, p2: Int16 = 0, p3: Int16 = 0,
                       p4: Int16 = 0) -> Placement {
        Placement(index: 0, flag: 1, byte1: 0, type: type, p1: p1, p2: p2, p3: p3, p4: p4, y: y, x: x)
    }

    /// `SetupFaces`' Setup on the world's stream; the triple's children are inserted before the parent and its links
    /// mapped, as `.SetupLevelSprites` does (`Entry.children`).
    private func geyser(_ w: SpriteWorld, _ p: Placement) throws -> (id: Int, entry: SetupFaces.Entry, kids: [Int]) {
        w.records = [p]
        let c = SetupFaces.Context(level: w.level, playerX: 0, records: w.records)
        var lights = LightTable()
        let e = try SetupFaces.setup(p, context: c, lights: &lights, rng: &w.rng)
        let kids = e.children.map { w.active.insert($0) }
        var s = e.slot
        if let f = s.siblings.first { s.siblings.first = kids[f] }
        if let f = s.siblings.second { s.siblings.second = kids[f] }
        return (w.active.insert(s), e, kids)
    }

    private func slot(_ w: SpriteWorld, _ id: Int?) throws -> SpriteSlot { try XCTUnwrap(id.flatMap(w.active.record)) }

    /// One Box Handle at level frame `C` (the Box dispatch row's test form).
    private func frame(_ w: SpriteWorld, _ id: Int, _ C: Int32) {
        w.frameCounter = C
        BoxSprite.handle(world: w, id: id)
    }

    /// `.HandleGeyserColumn` alone with the column at height `h`, velocity `v`.
    private func column(_ w: SpriteWorld, _ id: Int, h: Int32, v: Int32 = 0) {
        w.active.update(id: id) { s in
            s.geyserHeight = h
            s.geyserVelocity = v
        }
        var lights = LightTable()
        Geyser.column(w, id: id, lights: &lights, effects: 1)
    }

    private func block(_ w: SpriteWorld, _ id: Int) throws -> SpriteSlot.GeyserBlock {
        try XCTUnwrap(try slot(w, id).geyserColumn)
    }

    private func seed(_ pick: (inout FastRand) -> Bool) -> Int32 {
        var s: Int32 = 1
        while true {
            var r = FastRand(seed: s)
            if pick(&r) { return s }
            s += 1
        }
    }

    private func f(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }

    /// The dump's rules for one eruption step (M l. 60381–60420), as a model to compare the port against.
    private struct Model {
        var h: Int32 = 0, v: Int32 = 0, fall: Int32
        let target: Int32, on: Int32, off: Int32
        init(p1: Int32, on: Int32, off: Int32) { target = p1 << 8; fall = target; self.on = on; self.off = off }
        mutating func step(_ C: UInt32) {
            let t = Int32(C % UInt32(on + off + 1))
            if t < on {
                v = min(Int32(0.12 * Double(target - h)), 0x600)
                h += v
                fall = target
            } else {
                v = Int32(0.12 * Double(h - fall))
                if -0x100 < v { v = -0x100 }
                if v < -0x700 { v = -0x700 }
                h += v
            }
            if h < 0 { h = 0 }
        }
    }

    /// The R(100) branch draws a spray model saw, the segments' and the head's.
    private struct Seen { var seg: [Int16] = [], head: [Int16] = [] }

    /// The dump's spray order for one `.HandleGeyserColumn` call (M l. 59829–59914), as a model: per live segment R(3)
    /// first, then — on screen — R(3) + 3 tries of r = R(32), r ≥ `+0x1bc` → R(100) < 0x33 ? (x + 10 − R(5), −40 − R(100))
    /// : (x + 14 + R(5), 40 + R(100)), vy = 200 − R(1000) − v, delay R(10); then the head: R(6) + 10 + head y, R(4)
    /// dropped, R(100) < 0x33 ? (x + 12 − R(12), −70 − R(170)) : (x + 12 + R(12), 70 + R(170)), vy = 250 − R(1300) − v,
    /// delay R(10).
    private func sprayModel(_ r: inout FastRand, x: Int, segs: [(y: Int, clip: Int)], onScreen: Bool, headY: Int?,
                            v: Int32, kind: Int16, seen: inout Seen) -> [ParticlePool.Record] {
        var out: [ParticlePool.Record] = []
        func part(_ y: Int, _ px: Int, _ vx: Int32, _ vy: Int32, _ delay: Int16) {
            var p = ParticlePool.Record()
            p.alive = true
            p.age = 0 - delay
            p.shape = 4
            p.kind = kind + 200
            p.gravity = 0xbe
            p.x = Int32(px) << 8
            p.y = Int32(y) << 8
            p.vx = vx
            p.vy = vy
            p.mode = 1
            out.append(p)
        }
        for (segY, clip) in segs {
            let k = Int(r.next(3))
            guard onScreen else { continue }
            for _ in 0..<(k + 3) {
                let rr = Int(r.next(32))
                guard clip <= rr else { continue }
                let b = r.next(100)
                seen.seg.append(b)
                let px: Int, vx: Int32
                if b < 0x33 {
                    px = x + 10 - Int(r.next(5))
                    vx = -40 - Int32(r.next(100))
                } else {
                    px = x + 14 + Int(r.next(5))
                    vx = 40 + Int32(r.next(100))
                }
                let vy = 200 - Int32(r.next(1000)) - v
                part(segY + rr, px, vx, vy, r.next(10))
            }
        }
        guard let headY else { return out }
        let a = Int(r.next(6))
        _ = r.next(4)
        let b = r.next(100)
        seen.head.append(b)
        let px: Int, vx: Int32
        if b < 0x33 {
            px = x + 12 - Int(r.next(12))
            vx = -0x46 - Int32(r.next(0xaa))
        } else {
            px = x + 12 + Int(r.next(12))
            vx = 0x46 + Int32(r.next(0xaa))
        }
        let vy = 0xfa - Int32(r.next(0x514)) - v
        part(headY + a + 10, px, vx, vy, r.next(10))
        return out
    }

    // MARK: -

    func testGeyserSetupDefaults() throws {
        // The geyser arm (M l. 59116–59185, raw 1006bbdc..1006bde8): the cache marks, SetRect(0, 2, 0x18, 0x18), no tile
        // callback, one-way, gravity 0, layer 0, `+0x189 = 1`, `+0x150 = y`; p1 << 8 (0 → 0x6400) to `+0x154`, `+0xf4`,
        // `+0x16c`; p2 / p3 (0 → 60); p4 → `+0xa6`; height and velocity 0; the idle pads (top p1 px, left / right 64);
        // `+0x46 = R(4)`; the 0x44-byte block; kind = type − 0x5a0, `+0x170 = 0`, type 0x5a0.
        for t: Int16 in 0x5a0...0x5a4 {
            for want: Int16 in [0, 3] {
                let (w, _) = try world()
                w.rng = FastRand(seed: seed { $0.next(4) == want })
                var x = w.rng
                XCTAssertEqual(x.next(4), want)
                let (id, e, kids) = try geyser(w, place(t, p4: 37))
                XCTAssertEqual(w.rng.seed, x.seed, "one draw")
                let s = try slot(w, id)
                let tag = "type \(t)"
                XCTAssertEqual([Int(s.type), Int(s.geyserKind), Int(s.geyserTriple)], [0x5a0, Int(t - 0x5a0), 0], tag)
                XCTAssertEqual([s.geyserTarget, s.geyserFall, s.geyserBaseTarget], [0x6400, 0x6400, 0x6400], tag)
                XCTAssertEqual([s.geyserOn, s.geyserOff, s.geyserHeight, s.geyserVelocity], [60, 60, 0, 0], tag)
                XCTAssertEqual([Int(s.counterA6), Int(s.phase), Int(s.geyserBaseY)], [37, Int(want), 600], tag)
                XCTAssertEqual(s.margins, SpriteSlot.Margins(left: 0x40, right: 0x40, top: 100, bottom: 0), tag)
                XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 2, left: 0, bottom: 0x18, right: 0x18))
                XCTAssertEqual([s.oneWay, s.hasHit, s.hasTileHit, s.handler == .box, s.mayIdle],
                               [true, true, false, true, true], tag)
                XCTAssertEqual([Int(s.gravity), Int(s.layer), Int(s.hp), Int(s.classWordAC)], [0, 0, 600, 0], tag)
                XCTAssertEqual(s.geyserColumn, SpriteSlot.GeyserBlock(), tag)
                XCTAssertEqual(SpriteSlot.GeyserBlock().segments.count, 16)
                // The write-back flags: `+0x189 = 1` (M l. 59127) and nothing else.
                XCTAssertEqual([s.keepRecord, s.noWriteBack189, s.noWriteBack18a, s.keepRecordAtKill, s.killedForGood],
                               [false, true, false, false, false], tag)
                XCTAssertEqual([s.x, s.y, Int(s.x256 >> 8), Int(s.y256 >> 8)], [400, 600, 400, 600])
                XCTAssertEqual(kids, [])
                XCTAssertEqual([e.source == .handle ? 1 : 0, e.faceIndex], [1, 0], tag)
                XCTAssertEqual(e.sheet, SetupFaces.Sheet(pict: 0x5a0, count: 12, cellWidth: 0x18, cellHeight: 0x10,
                                                         columns: 4, clut: 200))
                // `+0x189` keeps the renamed type off the record (`.UpdateSprites` M l. 4959–4967).
                var l = LightTable()
                w.updateSprites(lights: &l)
                XCTAssertEqual(w.records[0].type, t, tag)
            }
        }
        // Given params: p1 120 → 0x7800, top pad 120; p2 90, p3 45; a negative p1 keeps its sign through the pad.
        let (w, _) = try world()
        let (id, _, _) = try geyser(w, place(0x5a2, p1: 120, p2: 90, p3: 45))
        let s = try slot(w, id)
        XCTAssertEqual([s.geyserTarget, s.geyserOn, s.geyserOff, Int32(s.margins.top)], [0x7800, 90, 45, 120])
        let (wn, _) = try world()
        let (nid, _, _) = try geyser(wn, place(0x5a2, p1: -5))
        XCTAssertEqual([try slot(wn, nid).geyserTarget, Int32(try slot(wn, nid).margins.top)], [-0x500, -5])
        // The head arm, tested first (M l. 59107–59115): placed 1449 is the head — SetRect(8, 8, 0x28, 0x20), one-way, no
        // tile callback, gravity 0, push mass and sag 0, the Box head's layer 2; no draw, no block, no marks.
        let (wh, _) = try world()
        let r0 = wh.rng
        let (hid, he, _) = try geyser(wh, place(0x5a9))
        let hs = try slot(wh, hid)
        XCTAssertEqual(wh.rng.seed, r0.seed)
        XCTAssertEqual(hs.hotRect, IdleSprites.Rect(top: 8, left: 8, bottom: 0x20, right: 0x28))
        XCTAssertEqual([hs.oneWay, hs.hasTileHit, hs.hasHit, hs.noWriteBack189], [true, false, true, false])
        XCTAssertEqual([Int(hs.gravity), Int(hs.pushMass), Int(hs.sag), Int(hs.layer), Int(hs.type)], [0, 0, 0, 2, 0x5a9])
        XCTAssertNil(hs.geyserColumn)
        XCTAssertEqual(he.source, .none)
        // The faces (`.InitBoxSprite` M l. 58813–58815): 1440 12 × 24×16 (4 a row), 1441 6 × 48×32, 1442 6 × 20×32 — each
        // geyser Setup marks all three (M l. 59117–59120); the head marks nothing.
        for t: Int16 in 0x5a0...0x5a8 { XCTAssertEqual(CachedFaces.marks(type: t).sets, [0x5a0, 0x5a1, 0x5a2], "\(t)") }
        XCTAssertEqual(CachedFaces.marks(type: 0x5a9).sets, [])
        // The `CachedFaces` records (`_DAT_100a12b4`, flag 0): 1440 12 faces, 1441 and 1442 6 each.
        let at = try XCTUnwrap(CachedFaces.sets.firstIndex { $0.pict == 0x5a0 })
        XCTAssertEqual(CachedFaces.sets[at...at + 2].map(\.pict), [0x5a0, 0x5a1, 0x5a2])
        XCTAssertEqual(CachedFaces.sets[at...at + 2].map(\.faces), [12, 6, 6])
        XCTAssertEqual(SetupFaces.sheet(pict: 0x5a1), SetupFaces.Sheet(pict: 0x5a1, count: 6, cellWidth: 0x30,
                                                                       cellHeight: 0x20, columns: 6, clut: 200))
        XCTAssertEqual(SetupFaces.sheet(pict: 0x5a2), SetupFaces.Sheet(pict: 0x5a2, count: 6, cellWidth: 0x14,
                                                                       cellHeight: 0x20, columns: 6, clut: 200))
        XCTAssertTrue(BoxSprite.handleBuilt(0x5a0) && BoxSprite.handleBuilt(0x5a5) && BoxSprite.handleBuilt(0x5a9))
    }

    func testEruptionPhase() throws {
        // `t = C mod (on + off + 1)` (`divwu`, raw 1006df3c) into `+0xa6` — p4 is overwritten; rising (t < on): v =
        // trunc(0.12·(target − h)) capped 0x600, `+0xf4 = target`; falling: v = trunc(0.12·(h − `+0xf4`)) clamped to
        // [−0x700, −0x100]; h += v; h < 0 → 0 (M l. 60381–60420).
        let (w, _) = try world()
        let (id, _, _) = try geyser(w, place(0x5a2, p4: 37))
        var m = Model(p1: 100, on: 60, off: 60)
        var hs: [Int32] = []
        for C in 0..<Int32(363) {
            frame(w, id, C)
            m.step(UInt32(C))
            let s = try slot(w, id)
            XCTAssertEqual([Int32(s.counterA6), s.geyserHeight, s.geyserVelocity], [C % 121, m.h, m.v], "C \(C)")
            hs.append(s.geyserHeight)
        }
        // The worked cycle for 100/60/60 (geysers.md §3): top 25578 (99.9 px) at t 59, ≥ 50 % at the 9th frame, falling
        // to 0 on the 32nd falling call (t 91), the rise again at t 0.
        XCTAssertEqual(hs.prefix(121).max(), 25578)
        XCTAssertEqual(Array(hs[7...9]), [12288, 13824, 15237])
        XCTAssertEqual([hs[59], hs[60], hs[90], hs[91], hs[121]], [25578, 25322, 687, 0, 1536])
        XCTAssertEqual(try slot(w, id).geyserFall, 0x6400)
        XCTAssertEqual(w.player.cues, [], "the dead CalcStereoVolume at t 0 plays nothing (§6)")
        // 190/60/40: never collapses — the first cycle bottoms at 5106, every later one at 5416 (21.2 px); top 48560
        // (189.7 px); ≥ 50 % at the 13th frame once in step.
        let (w2, _) = try world()
        let (id2, _, _) = try geyser(w2, place(0x5a2, p1: 190, p2: 60, p3: 40))
        var m2 = Model(p1: 190, on: 60, off: 40)
        var h2: [Int32] = []
        for C in 0..<Int32(505) {
            frame(w2, id2, C)
            m2.step(UInt32(C))
            XCTAssertEqual(try slot(w2, id2).geyserHeight, m2.h, "C \(C)")
            h2.append(m2.h)
        }
        XCTAssertEqual(h2[0..<101].min(), 1536)
        XCTAssertEqual(h2[60..<101].min(), 5106)
        XCTAssertEqual(h2[404..<505].min(), 5416)
        XCTAssertEqual(h2.max(), 48560)
        XCTAssertEqual(h2[404..<505].firstIndex { $0 * 2 >= 190 << 8 }.map { $0 - 404 + 1 }, 13)
        XCTAssertTrue(try slot(w2, id2).mayIdle == false, "never collapses: never idles")

        // Unsigned phase: C = 0xfffffff0 with on 40 / off 80 → 4294967280 mod 121 = 43 (falling); signed it would be −16.
        let (w3, _) = try world()
        let (id3, _, _) = try geyser(w3, place(0x5a2, p2: 40, p3: 80))
        w3.active.update(id: id3) { s in s.geyserHeight = 0x2000; s.geyserFall = 0x6400 }
        frame(w3, id3, Int32(bitPattern: 0xfffffff0))
        XCTAssertEqual([Int32(try slot(w3, id3).counterA6), try slot(w3, id3).geyserVelocity], [43, -0x700])

        // Thresholds, by setting the fields and calling one step at t 0 (rising) or t 61 (falling).
        func step(h: Int32, target: Int32 = 0x6400, fall: Int32 = 0x6400, C: Int32) throws -> SpriteSlot {
            let (t, _) = try world()
            let (g, _, _) = try geyser(t, place(0x5a2))
            t.active.update(id: g) { s in s.geyserHeight = h; s.geyserTarget = target; s.geyserFall = fall }
            frame(t, g, C)
            return try slot(t, g)
        }
        XCTAssertEqual(try step(h: 0x6400 - 12809, C: 0).geyserVelocity, 0x600)    // 1537.08 → capped
        XCTAssertEqual(try step(h: 0x6400 - 12792, C: 0).geyserVelocity, 1535)     // 1535.04 → kept
        XCTAssertEqual(try step(h: 0x6400 + 1000, C: 0).geyserVelocity, -120)      // no lower clamp rising
        XCTAssertEqual(try step(h: 0x6400 - 2140, C: 61).geyserVelocity, -256)     // −256.8 → −256 kept
        XCTAssertEqual(try step(h: 0x6400 - 2125, C: 61).geyserVelocity, -0x100)   // −255 → clamped
        XCTAssertEqual(try step(h: 0x6400 - 14930, C: 61).geyserVelocity, -1791)   // −1791.6 → kept
        XCTAssertEqual(try step(h: 0x6400 - 15259, C: 61).geyserVelocity, -0x700)  // −1831 → clamped
        let floor = try step(h: 100, C: 61)
        XCTAssertEqual([floor.geyserVelocity, floor.geyserHeight], [-0x700, 0])     // h < 0 → 0
        XCTAssertEqual(try step(h: 0x100, fall: 0x100, C: 0).geyserFall, 0x6400, "rising stores +0xf4 = target")
        XCTAssertEqual(try step(h: 0x100, fall: 0x100, C: 61).geyserFall, 0x100, "falling keeps it")
        // The fall reads `+0xf4`, not `+0x154`: trunc(0.12·(0x1000 − 0x6400)) = −2580 → −0x700.
        let fallRef = try step(h: 0x1000, target: 0x1000, fall: 0x6400, C: 61)
        XCTAssertEqual([fallRef.geyserVelocity, fallRef.geyserHeight], [-0x700, 0x900])

        // The base face: `+0x46` + 1, past 7 → 0; cache 1440 entry (`+0x46 >> 1`) + 4·kind. Kinds 3 / 4 index past the
        // 12-face cache: drawn as nothing (◇ NR 3, unplaced).
        for (t, seq) in [(Int16(0x5a2), [8, 9, 9, 10, 10, 11, 11, 8, 8]), (0x5a0, [0, 1, 1, 2, 2, 3, 3, 0, 0])] {
            let (wf, _) = try world()
            let (fid, _, _) = try geyser(wf, place(t))
            wf.active.update(id: fid) { $0.phase = 0 }
            var got: [Int] = []
            for C in 0..<Int32(9) {
                frame(wf, fid, C)
                got.append(try slot(wf, fid).face?.index ?? -1)
                XCTAssertEqual(try slot(wf, fid).face?.pict, 0x5a0)
            }
            XCTAssertEqual(got, seq, "type \(t)")
        }
        for t: Int16 in [0x5a3, 0x5a4] {
            let (wf, _) = try world()
            let (fid, _, _) = try geyser(wf, place(t))
            frame(wf, fid, 0)
            XCTAssertNil(try slot(wf, fid).face, "type \(t)")
        }
        // Kind 3 with the phase wrapping 7 → 0: entry 0 + 12 — one past the cache, still nothing.
        let (w3f, _) = try world()
        let (f3, _, _) = try geyser(w3f, place(0x5a3))
        w3f.active.update(id: f3) { $0.phase = 7 }
        frame(w3f, f3, 0)
        XCTAssertEqual(try slot(w3f, f3).phase, 0)
        XCTAssertNil(try slot(w3f, f3).face, "cell 12")
    }

    /// The period-0 guard in the eruption arm (`LAB_1006df20`, M l. 60379–60483): with on + off = −1 the divisor
    /// on + off + 1 is 0, which `divwu` leaves undefined; the port takes the quotient as 0, so `+0xa6` = Int16(C) — the
    /// level frame counter's low half — and nothing traps. Unreachable from shipped data: no geyser placement on levels
    /// 10, 50 or 51 gives on + off = −1; the placement here is made by hand.
    func testEruptionPeriodZeroGuard() throws {
        let (w, _) = try world()
        let (id, _, _) = try geyser(w, place(0x5a2, p2: 40, p3: -41))
        XCTAssertEqual([try slot(w, id).geyserOn, try slot(w, id).geyserOff], [40, -41])
        // C = 0x12345: Int16(C) = 0x2345 = 9029, not < on 40 → the falling branch.
        let C1 = Int32(0x12345)
        frame(w, id, C1)
        XCTAssertEqual(try slot(w, id).counterA6, Int16(truncatingIfNeeded: C1))
        XCTAssertEqual(try slot(w, id).counterA6, 0x2345)
        // C = 0x80000010: Int16(C) = 16 < 40 → the rising branch stores `+0xf4 = target`.
        let C2 = Int32(bitPattern: 0x8000_0010)
        w.active.update(id: id) { s in s.geyserFall = 0x100 }
        frame(w, id, C2)
        XCTAssertEqual(try slot(w, id).counterA6, Int16(truncatingIfNeeded: C2))
        XCTAssertEqual(try slot(w, id).counterA6, 16)
        XCTAssertEqual(try slot(w, id).geyserFall, try slot(w, id).geyserTarget, "rising at t 16")
    }

    func testColumnSegmentsAndHead() throws {
        let (w, _) = try world()
        let (id, _, _) = try geyser(w, place(0x5a2))
        // First column call at 16 px rising: the head `MTNewSprite(0x5a9, x − 12, y, 0xb, −1, .SetupBoxSprite)` (M l.
        // 59785) — its Setup's head stores layer 2 —, face 0 this frame, so n = 0; solid on all sides (h ≤ 0x1000, v >
        // 0); at (x − 12, y − h_px − 4); kind copied; lava tint 0x1000c; `+0x1c6 = 0`.
        column(w, id, h: 0x1000, v: 1)
        var b = try block(w, id)
        let head = try XCTUnwrap(b.head)
        var hd = try slot(w, head)
        XCTAssertEqual([Int(hd.type), hd.x, hd.y, Int(hd.layer), Int(hd.recordIndex)], [0x5a9, 388, 580, 2, -1])
        // `.MTNewSprite`'s fixed-point copies keep the spawn point (x − 12, y); only `+0xc` / `+0xa` move.
        XCTAssertEqual([hd.x256, hd.y256], [388 << 8, 600 << 8])
        XCTAssertEqual([hd.face == nil, hd.oneWay, hd.handler == .box], [true, false, true])
        XCTAssertEqual([Int(hd.geyserKind), Int(hd.mode)], [2, 0x1000c])
        XCTAssertEqual(hd.hotRect, IdleSprites.Rect(top: 8, left: 8, bottom: 0x20, right: 0x28))
        XCTAssertEqual(b.segments.compactMap { $0 }, [])
        XCTAssertFalse(try slot(w, id).mayIdle)
        // Second call: the head's `+0x46` → 1, face cache 1441 entry 0; n = (16 + 31) >> 5 = 1: segment 0 `MTNewSprite(
        // 0x5a0, x + 1, y, 1, −1, .SetupEffectSprite)` at y − 22, face cache 1442 entry 0, kind and tint copied, `+0x1bc`
        // = 32·1 − 16. The segment's Setup arm (M l. 53805–53811): `.HandleGeyserSegSprite`, no hit / tile callback,
        // SetRect(4, 0x18, 0x10, 0x20), layer 1.
        column(w, id, h: 0x1000, v: 1)
        b = try block(w, id)
        hd = try slot(w, head)
        XCTAssertEqual([Int(hd.phase), hd.face?.index ?? -1, Int(hd.face?.pict ?? 0)], [1, 0, 0x5a1])
        let s0 = try slot(w, b.segments[0])
        XCTAssertEqual([s0.x, s0.y, Int(s0.layer), Int(s0.type), Int(s0.geyserKind), Int(s0.mode), s0.clip.top],
                       [401, 578, 1, 0x5a0, 2, 0x1000c, 16])
        XCTAssertEqual(s0.face, f(0x5a2, 0))
        XCTAssertEqual([s0.x256, s0.y256], [401 << 8, 600 << 8], "the spawn point (x + 1, y)")
        XCTAssertEqual([s0.handler == .geyserSegment, s0.hasHit, s0.hasTileHit, s0.lightOverlay],
                       [true, false, false, false])
        XCTAssertEqual(s0.hotRect, IdleSprites.Rect(top: 0x18, left: 4, bottom: 0x20, right: 0x10))
        XCTAssertTrue(EffectSprite.skipsPackage(0x5a0))
        // The head's solidity, both sides of h ≤ 0x1000 ∧ v > 0.
        column(w, id, h: 0x1001, v: 1)
        XCTAssertTrue(try slot(w, head).oneWay)
        column(w, id, h: 0x1000, v: 0)
        XCTAssertTrue(try slot(w, head).oneWay)
        column(w, id, h: 0xf00, v: 0x40)
        XCTAssertFalse(try slot(w, head).oneWay)
        // The head's `+0x46` wraps past 11; its face is entry `+0x46 >> 1`.
        w.active.update(id: head) { $0.phase = 10 }
        column(w, id, h: 0x2000)
        XCTAssertEqual([Int(try slot(w, head).phase), try slot(w, head).face?.index ?? -1], [11, 5])
        column(w, id, h: 0x2000)
        XCTAssertEqual([Int(try slot(w, head).phase), try slot(w, head).face?.index ?? -1], [0, 0])
        // 100 px: n = 4, segments at y − 22 − 32·i, the top one clipped 128 − 100 rows, faces from the head's phase.
        w.active.update(id: head) { $0.phase = 4 }
        column(w, id, h: 0x6400)
        b = try block(w, id)
        let four = try b.segments.prefix(4).map { try slot(w, $0) }
        XCTAssertEqual(four.map(\.y), [578, 546, 514, 482])
        XCTAssertEqual(four.map(\.clip.top), [0, 0, 0, 28])
        XCTAssertEqual(four.map { $0.face?.index ?? -1 }, [2, 2, 2, 2])
        XCTAssertEqual(b.segments.dropFirst(4).compactMap { $0 }, [])
        XCTAssertEqual(try slot(w, head).y, 600 - 100 - 4)
        // 40 px: n = 2 — segments 2 and 3 killed (`+0xe9 = 1`, face 0, slot 0).
        let gone = [b.segments[2]!, b.segments[3]!]
        column(w, id, h: 0x2800)
        b = try block(w, id)
        XCTAssertEqual(b.segments.compactMap { $0 }.count, 2)
        for g in gone { XCTAssertEqual([try slot(w, g).dead, try slot(w, g).face == nil], [true, true]) }
        // 33 px: n = (33 + 31) >> 5 = 2, the top one clipped 64 − 33 = 31 rows.
        column(w, id, h: 33 << 8)
        b = try block(w, id)
        XCTAssertEqual(b.segments.compactMap { $0 }.count, 2)
        XCTAssertEqual(try slot(w, b.segments[1]).clip.top, 31)
        // 600 px: n = 19, 16 slots.
        column(w, id, h: 600 << 8)
        XCTAssertEqual(try block(w, id).segments.compactMap { $0 }.count, 16)
        // Below 4 px the head hides (head y > base y − 8 → face 0) and n = 0: every segment killed; at 4 px it shows.
        let segs = try block(w, id).segments.compactMap { $0 }
        column(w, id, h: 0x3ff)
        XCTAssertEqual([try slot(w, head).y, try slot(w, head).face == nil ? 1 : 0], [593, 1])
        XCTAssertEqual(try block(w, id).segments.compactMap { $0 }, [])
        for g in segs { XCTAssertTrue(try slot(w, g).dead) }
        column(w, id, h: 0x400)
        XCTAssertEqual(try slot(w, head).y, 592)
        XCTAssertNotNil(try slot(w, head).face)
        XCTAssertEqual(try block(w, id).segments.compactMap { $0 }.count, 1)
        // h 1 (above the collapse test's h < 1): the head stays, at y − 0 − 4, hidden; n 0; `+0x1c6 = 0`.
        column(w, id, h: 1)
        XCTAssertEqual([try slot(w, head).dead ? 1 : 0, try slot(w, head).y], [0, 596])
        XCTAssertNil(try slot(w, head).face)
        XCTAssertEqual(try block(w, id).segments.compactMap { $0 }, [])
        XCTAssertEqual(try block(w, id).head, head)
        XCTAssertFalse(try slot(w, id).mayIdle)
        // The tints by kind: 1 → 0x10017, 0 → 0, 3 / 4 unchanged; the segments copy the head's.
        for (k, before, after) in [(Int32(1), UInt32(0), UInt32(0x10017)), (0, 0x1000c, 0), (3, 0x1234, 0x1234),
                                   (4, 0x1234, 0x1234)] {
            w.active.update(id: id) { $0.geyserKind = k }
            w.active.update(id: head) { $0.mode = before }
            column(w, id, h: 0x2000)
            XCTAssertEqual([try slot(w, head).mode, try slot(w, try block(w, id).segments[0]).mode], [after, after])
            XCTAssertEqual(try slot(w, head).geyserKind, k)
        }
        // h < 1: the head (`+0xe9 = 1`, its face kept) and every segment (`+0xe9 = 1`, face 0) killed, slots cleared,
        // `+0x1c6 = 1`.
        let lastSegs = try block(w, id).segments.compactMap { $0 }
        column(w, id, h: 0)
        XCTAssertEqual(try block(w, id), SpriteSlot.GeyserBlock())
        XCTAssertEqual([try slot(w, head).dead, try slot(w, head).face != nil], [true, true])
        for g in lastSegs { XCTAssertEqual([try slot(w, g).dead, try slot(w, g).face == nil], [true, true]) }
        XCTAssertTrue(try slot(w, id).mayIdle)

        // `.KillBox` (M l. 61502–61517): the 16 segment slots and the head killed (`+0xe9 = 1`) and cleared.
        column(w, id, h: 0x2000)
        column(w, id, h: 0x2000)
        let kb = try block(w, id)
        let kh = try XCTUnwrap(kb.head), ks = kb.segments.compactMap { $0 }
        XCTAssertEqual(ks.count, 1)
        BoxSprite.killBox(w, id: id)
        XCTAssertEqual(try block(w, id), SpriteSlot.GeyserBlock())
        XCTAssertTrue(try slot(w, id).dead)
        XCTAssertEqual([try slot(w, kh).dead, try slot(w, ks[0]).dead, try slot(w, ks[0]).face != nil], [true, true, true])

        // The spray's RNG order (M l. 59843–59914, raw 1006d2a4..1006d394, 1006d3f8..1006d4e0): per live segment R(3)
        // first (drawn on- or off-screen), then — the column rect (x, y − h_px, x + 64, y) meeting the view (h, v, h + 608,
        // v + 384) — R(3) + 3 tries: r = R(32); r ≥ `+0x1bc` → R(100) ≤ 50 ? (px x + 10 − R(5), vx −40 − R(100)) :
        // (px x + 14 + R(5), vx 40 + R(100)); vy = 200 − R(1000) − v; `.NewParticle(kind + 200, 190, (seg y + r, px), 4, vx,
        // vy, R(10), 1)`. Then the head, every frame: R(6) + 10 + head y, R(4) dropped, R(100) ≤ 50 ? (x + 12 − R(12), −70 −
        // R(170)) : (x + 12 + R(12), 70 + R(170)); vy = 250 − R(1300) − v.
        for onScreen in [true, false] {
            let (s, _) = try world()
            let (g, _, _) = try geyser(s, place(0x5a1))           // acid: kind 1 → particles of kind 201
            var seen = Seen()
            var r0 = s.rng
            column(s, g, h: 0x3800, v: 0x40)                      // head made (face 0, n 0): its draws only
            let first = sprayModel(&r0, x: 400, segs: [], onScreen: true, headY: 540, v: 0x40, kind: 1, seen: &seen)
            XCTAssertEqual([s.particles.live, first.count], [1, 1], "the new head's particle only")
            XCTAssertEqual(Array(s.particles.records.prefix(1)), first)
            XCTAssertEqual(s.rng.seed, r0.seed)
            s.particles = ParticlePool()
            s.player.scrollH = 300
            s.player.scrollV = onScreen ? 300 : 0                 // the column spans y 544…600
            var r = s.rng
            column(s, g, h: 0x3800, v: 0x40)                      // 56 px: n = 2, top clip 64 − 56 = 8
            let want = sprayModel(&r, x: 400, segs: [(578, 0), (546, 8)], onScreen: onScreen, headY: 540, v: 0x40,
                                  kind: 1, seen: &seen)
            XCTAssertEqual(Array(s.particles.records.prefix(want.count)), want, "on screen \(onScreen)")
            XCTAssertEqual(s.particles.live, want.count)
            XCTAssertEqual(s.rng.seed, r.seed)
        }
        // One frame as literal numbers, from a hand run of the dump's order (M l. 59829–59914) with seed 0x1234567 at
        // 56 px, v 0x40, acid, on screen: (y, px, vx, vy, delay) — eight segment particles, then the head's.
        do {
            let (s, _) = try world()
            let (g, _, _) = try geyser(s, place(0x5a1))
            column(s, g, h: 0x3800, v: 0x40)
            s.player.scrollH = 300
            s.player.scrollV = 300
            s.particles = ParticlePool()
            s.rng = FastRand(seed: 0x1234567)
            column(s, g, h: 0x3800, v: 0x40)
            let got = s.particles.records.prefix(s.particles.live).map {
                [Int($0.y >> 8), Int($0.x >> 8), Int($0.vx), Int($0.vy), -Int($0.age)]
            }
            XCTAssertEqual(got, [[609, 406, -45, -571, 3], [584, 417, 46, -339, 2], [592, 407, -105, 133, 3],
                                 [597, 418, 50, -154, 4], [568, 418, 70, -727, 0], [577, 407, -117, -589, 8],
                                 [556, 408, -92, -694, 6], [565, 414, 87, -334, 2], [551, 420, 117, -490, 2]])
            XCTAssertEqual(s.rng.seed, 0x14034c86)
        }
        // 400 frames each at 56 px (top clip 8) and 33 px (top clip 31) against the model: the draws 50 and 51 either
        // side of each R(100) < 0x33 occur, for the segments and the head.
        for (hgt, segs) in [(Int32(0x3800), [(y: 578, clip: 0), (y: 546, clip: 8)]), (0x2100, [(578, 0), (546, 31)])] {
            let (s, _) = try world()
            let (g, _, _) = try geyser(s, place(0x5a1))
            column(s, g, h: hgt, v: 0x40)
            s.player.scrollH = 300
            s.player.scrollV = 300
            var seen = Seen()
            for i in 0..<400 {
                s.particles = ParticlePool()
                var r = s.rng
                column(s, g, h: hgt, v: 0x40)
                let want = sprayModel(&r, x: 400, segs: segs, onScreen: true, headY: 600 - Int(hgt >> 8) - 4, v: 0x40,
                                      kind: 1, seen: &seen)
                if Array(s.particles.records.prefix(want.count)) != want || s.particles.live != want.count
                    || s.rng.seed != r.seed {
                    XCTFail("h \(hgt) frame \(i)")
                    break
                }
            }
            for want: Int16 in [50, 51] {
                XCTAssertTrue(seen.seg.contains(want), "h \(hgt): segment draw \(want)")
                XCTAssertTrue(seen.head.contains(want), "h \(hgt): head draw \(want)")
            }
        }
        // The view rect (h, v, h + 608, v + 384) against the column rect (400, 544, 464, 600), `SectRect` (touching is
        // no overlap): the segment particles (all but the head's) at each edge.
        func segParticles(_ sh: Int, _ sv: Int) throws -> Int {
            let (s, _) = try world()
            let (g, _, _) = try geyser(s, place(0x5a1))
            column(s, g, h: 0x3800, v: 0x40)
            s.player.scrollH = sh
            s.player.scrollV = sv
            s.particles = ParticlePool()
            column(s, g, h: 0x3800, v: 0x40)
            return s.particles.live - 1
        }
        for (sh, sv, some) in [(300, 160, false), (300, 161, true), (-208, 300, false), (-207, 300, true),
                               (464, 300, false), (463, 300, true), (300, 600, false), (300, 599, true),
                               (0, 500, true)] {
            XCTAssertEqual(try segParticles(sh, sv) > 0, some, "scroll (\(sh), \(sv))")
        }

        // Through the session: a geyser near the player, rising every frame (p2 1000, p3 1), run by the Box dispatch row;
        // the head, then the segments, appear; the segments' own dispatch row is the empty `.HandleGeyserSegSprite`.
        let sess = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 3, seed: 1)
        let sw = sess.world
        _ = sess.step(keys: KeyState())                         // the first step places the player
        let me = try slot(sw, try XCTUnwrap(sw.playerID))
        let gp = Placement(index: 0, flag: 1, byte1: 0, type: 0x5a2, p1: 0, p2: 1000, p3: 1, p4: 0,
                           y: Int16(me.y - 40), x: Int16(me.x + 250))
        var gs = SpriteSlot(type: 0x5a2, x: Int(gp.x), y: Int(gp.y), recordIndex: -1)
        _ = Geyser.setup(&gs, record: gp, level: sw.level, rng: &sw.rng)
        let gid = sw.active.insert(gs)
        _ = sess.step(keys: KeyState())
        let g1 = try slot(sw, gid)
        XCTAssertGreaterThan(g1.geyserHeight, 0)
        let shead = try XCTUnwrap(g1.geyserColumn?.head)
        _ = sess.step(keys: KeyState())
        _ = sess.step(keys: KeyState())
        let g3 = try slot(sw, gid)
        let hp = Int(g3.geyserHeight >> 8)
        XCTAssertEqual(try slot(sw, shead).y, g3.y - hp - 4)
        let live = try XCTUnwrap(g3.geyserColumn).segments.compactMap { $0 }
        XCTAssertEqual(live.count, (hp + 31) >> 5)
        let seg = live[0]
        sw.active.update(id: seg) { $0.vx = 0x400; $0.invulnerable = 5 }
        let before = try slot(sw, seg).x256
        _ = sess.step(keys: KeyState())
        XCTAssertEqual(try slot(sw, seg).x256, before, "no StandardSpriteHandles: the segment Handle is empty")
        XCTAssertEqual(try slot(sw, seg).invulnerable, 5, "no StandardSpriteHandles: `+0x116` not counted down")

        // No free record (Ruling 16): `.MTNewSprite` fails, no head — n 0, no segment, no draw.
        let (fw, _) = try world()
        let (fid, _, _) = try geyser(fw, place(0x5a2))
        while fw.active.sprites.count < SpriteWorld.recordCount { _ = fw.active.insert(SpriteSlot(type: 1, x: 0, y: 0)) }
        let fr = fw.rng
        column(fw, fid, h: 0x2000, v: 1)
        XCTAssertEqual(try block(fw, fid), SpriteSlot.GeyserBlock())
        XCTAssertEqual([fw.rng.seed, Int32(fw.particles.live)], [fr.seed, 0])
        XCTAssertFalse(try slot(fw, fid).mayIdle)
    }

    func testHeadHurtsByKind() throws {
        // `.HitPlayerSprite`'s Box arm after a landing (M l. 49308–49335): a head 0x5a9 with `+0x14c` > 0 → 0x70 (kind 2:
        // 0x150), `.HurtSprite(player, d, ±400, −0x640, 0x3c, 0xc)` (+400 when the head's centre x is left of the
        // player's), a hurt → the stun; kind 1 skipped by the walk-on power-up for liquid 1; kind 2 by the walk-on for
        // liquid 2 or the Fire Charm (item 0x18). Kind 0 harmless; kinds 3 / 4 take the 0x70 default (unplaced).
        func land(kind: Int32, headLeft: Bool = true, headX: Int? = nil, walkOn: Int16? = nil, staleKind: Int16? = nil,
                  charm: Bool = false, invul: Int16 = 0, rising: Bool = false) throws -> (SpriteSlot, Int16) {
            let (w, p) = try world(player: true)
            let pid = try XCTUnwrap(p)
            let hid = try XCTUnwrap(Geyser.newHead(w, x: 1188, y: 400))
            w.active.update(id: hid) { s in
                s.geyserKind = kind
                s.face = FaceRef(pict: Geyser.headSet, index: 0, set: .encoded)
                s.centre = SpriteSlot.Point(x: headX ?? (headLeft ? 1200 : 1300), y: 420)
            }
            if let k = walkOn {
                w.player.walkOnLiquid = true
                w.player.walkOnLiquidKind = k
            }
            if let k = staleKind {                              // the power-up off, its liquid kind left behind
                w.player.walkOnLiquid = false
                w.player.walkOnLiquidKind = k
            }
            if charm { w.globals.inventory[0] = InventorySlot(id: 0x18, count: 1, field4: -1, field6: 0, isSpell: 0) }
            let r = HandleKeys.standardHotRect
            w.active.update(id: pid) { s in
                s.hp = 0x300
                s.invulnerable = invul
                s.flash = 0
                s.x = 1196 - r.left
                s.y = 408 + 4 - r.bottom
                s.x256 = Int32(s.x) << 8
                s.y256 = Int32(s.y) << 8
                s.vx = 0
                s.vy = rising ? -0x400 : 0x300
                s.groundKind = 0
                s.ridden = nil
                s.centre = SpriteSlot.Point(x: 1250, y: s.y + 0x3b)
            }
            w.player.stun = 0
            HitPlayerSprite.hit(w, player: pid, other: hid)
            return (try slot(w, pid), w.player.stun)
        }
        let (k0, st0) = try land(kind: 0)
        XCTAssertEqual([k0.hp, Int16(k0.vx), k0.invulnerable, st0], [0x300, 0, 0, 0])
        XCTAssertEqual(k0.ridden.map { _ in 1 }, 1, "a landing: the water head is a plain platform")
        for (k, d) in [(Int32(1), Int16(0x70)), (2, 0x150), (3, 0x70), (4, 0x70)] {
            let (s, st) = try land(kind: k)
            XCTAssertEqual([s.hp, Int16(s.vx), Int16(s.vy), s.invulnerable, s.flash, st],
                           [0x300 - d, 400, -0x640, 0x3c, 0xc, 1], "kind \(k)")
            let (sr, _) = try land(kind: k, headLeft: false)
            XCTAssertEqual(Int16(sr.vx), -400, "kind \(k) right")
        }
        // The immunities, both sides.
        XCTAssertEqual(try land(kind: 1, walkOn: 1).0.hp, 0x300)
        XCTAssertEqual(try land(kind: 1, walkOn: 2).0.hp, 0x300 - 0x70)
        XCTAssertEqual(try land(kind: 1, charm: true).0.hp, 0x300 - 0x70)
        XCTAssertEqual(try land(kind: 2, walkOn: 2).0.hp, 0x300)
        XCTAssertEqual(try land(kind: 2, walkOn: 1).0.hp, 0x300 - 0x150)
        XCTAssertEqual(try land(kind: 2, charm: true).0.hp, 0x300)
        // The walk-on kind counts only with the power-up on: a stale kind is no immunity.
        XCTAssertEqual(try land(kind: 2, staleKind: 2).0.hp, 0x300 - 0x150)
        XCTAssertEqual(try land(kind: 1, staleKind: 1).0.hp, 0x300 - 0x70)
        // Equal centres: not left of the player → −400.
        XCTAssertEqual(Int16(try land(kind: 2, headX: 1250).0.vx), -400)
        // An invulnerable player takes nothing and is not stunned; no landing, no hurt.
        let (iv, ivs) = try land(kind: 2, invul: 5)
        XCTAssertEqual([iv.hp, ivs], [0x300, 0])
        XCTAssertEqual(try land(kind: 2, rising: true).0.hp, 0x300)
        // Through the session: the player falling onto a lava head (its top 4 px under his feet after the fall) is hurt
        // in the session's player pass — 0x150, the head right of him → −400, −0x640, invulnerable 60, the stun.
        let sess = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 3, seed: 1)
        let sw = sess.world
        _ = sess.step(keys: KeyState())                         // the first step places the player
        let pid = try XCTUnwrap(sw.playerID)
        let me = try slot(sw, pid)
        let r = HandleKeys.standardHotRect
        let hid = try XCTUnwrap(Geyser.newHead(sw, x: me.x + r.left - 8, y: me.y + r.bottom - 4 - 8 - 3))
        sw.active.update(id: hid) { s in
            s.geyserKind = 2
            s.face = FaceRef(pict: Geyser.headSet, index: 0, set: .encoded)
        }
        sw.active.update(id: pid) { s in s.hp = 0x300; s.invulnerable = 0; s.vx = 0; s.vy = 0x300 }
        _ = sess.step(keys: KeyState())
        let hurt = try slot(sw, pid)
        XCTAssertEqual([hurt.hp, Int16(hurt.vx), Int16(hurt.vy), hurt.invulnerable, sw.player.stun],
                       [0x300 - 0x150, -400, -0x640, 0x3c, 1])
    }

    func testSegmentHazard() throws {
        // The Effect test's 0x5a0 part (M l. 49763–49799): any handler reaching it with type 0x5a0 and `+0x14c` ≥ 1 →
        // 0x70 (kind 2: 0x150, its walk-on and Fire Charm immunities; kind 1 its walk-on), `.HurtSprite(player, d, ±300,
        // −0x640, 0x3c, 0xc)` — no scream, no coin loss —, a hurt → the stun.
        func touch(kind: Int32, left: Bool = true, centreX: Int? = nil, walkOn: Int16? = nil, staleKind: Int16? = nil,
                   charm: Bool = false, type: Int16? = nil, handler: SpriteHandler? = nil,
                   phase: Int16? = nil) throws -> (SpriteSlot, Int16, SpriteWorld) {
            let (w, p) = try world(player: true)
            let pid = try XCTUnwrap(p)
            var lights = LightTable()
            let g = try XCTUnwrap(EffectSprite.spawn(w, type: Geyser.base, x: 1210, y: 330, layer: 1, effects: 1,
                                                     lights: &lights))
            XCTAssertEqual(try slot(w, g).handler, .geyserSegment)
            w.active.update(id: g) { s in
                s.geyserKind = kind
                s.centre = SpriteSlot.Point(x: centreX ?? (left ? 1200 : 1300), y: 370)
                if let type { s.type = type }
                if let handler { s.handler = handler }
                if let phase { s.phase = phase }
            }
            if let k = walkOn {
                w.player.walkOnLiquid = true
                w.player.walkOnLiquidKind = k
            }
            if let k = staleKind {
                w.player.walkOnLiquid = false
                w.player.walkOnLiquidKind = k
            }
            if charm { w.globals.inventory[0] = InventorySlot(id: 0x18, count: 1, field4: -1, field6: 0, isSpell: 0) }
            w.active.update(id: pid) { s in
                s.hp = 0x300; s.invulnerable = 0; s.flash = 0; s.vx = 0; s.vy = 0
                s.centre = SpriteSlot.Point(x: 1250, y: 360)
            }
            w.player.stun = 0
            HitPlayerSprite.hit(w, player: pid, other: g)
            return (try slot(w, pid), w.player.stun, w)
        }
        XCTAssertEqual(try touch(kind: 0).0.hp, 0x300)
        for (k, d) in [(Int32(1), Int16(0x70)), (2, 0x150), (3, 0x70)] {
            let (s, st, w) = try touch(kind: k)
            XCTAssertEqual([s.hp, Int16(s.vx), Int16(s.vy), s.invulnerable, s.flash, st],
                           [0x300 - d, 300, -0x640, 0x3c, 0xc, 1], "kind \(k)")
            XCTAssertEqual(w.player.cues, [], "kind \(k): no scream")
            XCTAssertEqual(w.active.sprites.filter { $0.handler == .bonus }.count, 0, "kind \(k): no coins")
            XCTAssertEqual(Int16(try touch(kind: k, left: false).0.vx), -300)
        }
        XCTAssertEqual(try touch(kind: 1, walkOn: 1).0.hp, 0x300)
        XCTAssertEqual(try touch(kind: 1, charm: true).0.hp, 0x300 - 0x70)
        XCTAssertEqual(try touch(kind: 2, walkOn: 2).0.hp, 0x300)
        XCTAssertEqual(try touch(kind: 2, walkOn: 1).0.hp, 0x300 - 0x150)
        XCTAssertEqual(try touch(kind: 2, charm: true).0.hp, 0x300)
        XCTAssertEqual(try touch(kind: 2, staleKind: 2).0.hp, 0x300 - 0x150, "a stale walk-on kind: no immunity")
        XCTAssertEqual(try touch(kind: 1, staleKind: 1).0.hp, 0x300 - 0x70)
        XCTAssertEqual(Int16(try touch(kind: 2, centreX: 1250).0.vx), -300, "equal centres")
        // An Effect-class 0x4b7 still takes its own branch; a 0x4b7 under another handler does not.
        XCTAssertEqual(try touch(kind: 0, type: 0x4b7, handler: .effect, phase: 7).0.hp, 0x300 - 0x70)
        XCTAssertEqual(try touch(kind: 1, type: 0x4b7, handler: .geyserSegment, phase: 0).0.hp, 0x300)
        // Nor does a 0x4b7 past phase 7, or any other type (the debris 0xc1b), whatever its `+0x14c`.
        XCTAssertEqual(try touch(kind: 1, type: 0x4b7, handler: .effect, phase: 8).0.hp, 0x300)
        XCTAssertEqual(try touch(kind: 1, type: 0xc1b, handler: .effect).0.hp, 0x300)
        // Enemies: the Walker form hurts on kind 1 / 2, the Crawler / Frog form (`+0x14c == 1 || +0x150 == 2`) only on
        // kind 1 — a segment's `+0x150` is 0 (enemies-ground §2.3).
        let (we, _) = try world()
        var l = LightTable()
        let eg = try XCTUnwrap(EffectSprite.spawn(we, type: Geyser.base, x: 100, y: 100, layer: 1, effects: 1, lights: &l))
        for (k, walker, crawler) in [(Int32(0), false, false), (1, true, true), (2, true, false), (3, false, false)] {
            we.active.update(id: eg) { $0.geyserKind = k }
            let s = try slot(we, eg)
            XCTAssertEqual([EnemyCommon.environmentalHazard(s), EnemyCommon.environmentalHazard(s, crawlerFields: true)],
                           [walker, crawler], "kind \(k)")
        }
        // Through the session: a lava segment over the player hurts him in the player pass.
        let sess = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 3, seed: 1)
        let sw = sess.world
        let pid = try XCTUnwrap(sw.playerID)
        _ = sess.step(keys: KeyState())                         // the first step places the player
        let me = try slot(sw, pid)
        var sl = LightTable()
        let sg = try XCTUnwrap(EffectSprite.spawn(sw, type: Geyser.base, x: me.x + 0x28, y: me.y + 0x18, layer: 1,
                                                  effects: 1, lights: &sl))
        sw.active.update(id: sg) { s in
            s.geyserKind = 2
            s.hotRect = IdleSprites.Rect(top: -0x100, left: -0x100, bottom: 0x100, right: 0x100)
        }
        sw.active.update(id: pid) { s in s.hp = 0x300; s.invulnerable = 0 }
        _ = sess.step(keys: KeyState())
        let after = try slot(sw, pid)
        XCTAssertEqual(after.hp, 0x300 - 0x150)
        XCTAssertGreaterThan(after.invulnerable, 0x3a)
    }

    func testTripleChildrenKind0() throws {
        // Types ≥ 0x5a5 (M l. 59163–59183): kind = type − 0x5a5, `+0x170 = 1`, type 0x5a5, `+0xac = −1`; two children
        // `MTNewSprite(0x5a0, x + 0x48 / x + 0x90, y, layer, rec index, .SetupBoxSprite)` → `+0x1d4` / `+0x1d8`, each
        // `+0x188 = 1`, the second `+0xac = −1`. They re-enter the arm as 0x5a0: kind 0, their own R(4) and block.
        let (w, _) = try world()
        var r = w.rng
        let draws = [r.next(4), r.next(4), r.next(4)]
        let (id, e, kids) = try geyser(w, place(0x5a7, p1: 0, p2: 0, p3: 0))
        XCTAssertEqual(w.rng.seed, r.seed, "three draws: parent, then each child")
        let s = try slot(w, id)
        XCTAssertEqual([Int(s.type), Int(s.geyserKind), Int(s.geyserTriple), Int(s.classWordAC)], [0x5a5, 2, 1, -1])
        XCTAssertEqual(e.children.count, 2)
        XCTAssertEqual([s.siblings.first, s.siblings.second], [kids[0], kids[1]])
        XCTAssertEqual(Int(s.phase), Int(draws[0]))
        for (i, (k, dx, ac)) in zip(kids, [72, 144]).map({ ($0, $1, $1 == 144 ? Int32(-1) : 0) }).enumerated() {
            let c = try slot(w, k)
            XCTAssertEqual([Int(c.type), Int(c.geyserKind), Int(c.geyserTriple), Int(c.classWordAC), c.x, c.y],
                           [0x5a0, 0, 0, Int(ac), 400 + dx, 600], "child \(i)")
            XCTAssertEqual([c.keepRecord, c.noWriteBack189], [true, true])
            XCTAssertEqual([Int(c.recordIndex), Int(c.layer), Int(c.phase)], [0, 0, Int(draws[i + 1])])
            XCTAssertEqual(c.geyserColumn, SpriteSlot.GeyserBlock())
        }
        // The last placed type 0x5a8: the triple of kind 3, two children.
        let (w8, _) = try world()
        let (id8, e8, kids8) = try geyser(w8, place(0x5a8))
        XCTAssertEqual([Int(try slot(w8, id8).type), Int(try slot(w8, id8).geyserKind), e8.children.count, kids8.count],
                       [0x5a5, 3, 2, 2])
        // The re-targeting (M l. 60425–60481), rising only: each head ridden this frame (`+0x186`) by a rider other than
        // the player counts as covered (its flag cleared); B = `+0x16c`, L = trunc(max(50.0, 0.33·B)), c = the count;
        // each column's `+0x154` = L if covered, else B + c·(B − L).
        func heads(_ w: SpriteWorld, _ ids: [Int]) throws -> [Int] {
            for g in ids {
                column(w, g, h: 0x2000)
                column(w, g, h: 0x2000)
            }
            return try ids.map { try XCTUnwrap(try block(w, $0).head) }
        }
        let (tw, tp) = try world(player: true)
        let (tid, _, tk) = try geyser(tw, place(0x5a5))
        let hs = try heads(tw, [tid] + tk)
        tw.active.update(id: hs[1]) { $0.ridingLatch = true; $0.rider = 9999 }   // a crate on the first child's jet
        tw.active.update(id: hs[2]) { $0.ridingLatch = true; $0.rider = tp }     // the player never counts
        frame(tw, tid, 0)
        let L: Int32 = 8448, B: Int32 = 0x6400
        XCTAssertEqual(try ([tid] + tk).map { try slot(tw, $0).geyserTarget }, [B + (B - L), L, B + (B - L)])
        XCTAssertEqual(try hs.map { try slot(tw, $0).ridingLatch }, [false, false, true])
        // Two covered: c = 2.
        tw.active.update(id: hs[0]) { $0.ridingLatch = true; $0.rider = 9999 }
        tw.active.update(id: hs[1]) { $0.ridingLatch = true; $0.rider = 9999 }
        frame(tw, tid, 1)
        XCTAssertEqual(try ([tid] + tk).map { try slot(tw, $0).geyserTarget }, [L, L, B + 2 * (B - L)])
        // None covered: all B.
        frame(tw, tid, 2)
        XCTAssertEqual(try ([tid] + tk).map { try slot(tw, $0).geyserTarget }, [B, B, B])
        // Falling (t ≥ on): no re-targeting, the flags kept.
        tw.active.update(id: hs[1]) { $0.ridingLatch = true; $0.rider = 9999 }
        tw.active.update(id: tk[0]) { $0.geyserTarget = 77 }
        frame(tw, tid, 61)
        XCTAssertEqual([try slot(tw, tk[0]).geyserTarget, try slot(tw, hs[1]).ridingLatch ? 1 : 0], [77, 1])
        // max(50, 0.33·B) both sides: p1 −1 → B −256, 0.33·B < 50 → L 50; one covered → the others −256 + (−256 − 50).
        let (nw, _) = try world(player: true)
        let (nid, _, nk) = try geyser(nw, place(0x5a5, p1: -1))
        let nh = try heads(nw, [nid] + nk)
        nw.active.update(id: nh[0]) { $0.ridingLatch = true; $0.rider = 9999 }
        frame(nw, nid, 0)
        XCTAssertEqual(try ([nid] + nk).map { try slot(nw, $0).geyserTarget }, [50, -256 - 306, -256 - 306])
        // p1 1 → B 256, 0.33·256 = 84.48 → L 84.
        let (pw, _) = try world(player: true)
        let (pid, _, pk) = try geyser(pw, place(0x5a5, p1: 1))
        let ph = try heads(pw, [pid] + pk)
        pw.active.update(id: ph[2]) { $0.ridingLatch = true; $0.rider = 9999 }
        frame(pw, pid, 0)
        XCTAssertEqual(try ([pid] + pk).map { try slot(pw, $0).geyserTarget }, [256 + 172, 256 + 172, 84])
        // A single geyser never re-targets: its ridden head keeps the target and the flag.
        let (sw1, _) = try world(player: true)
        let (sid, _, _) = try geyser(sw1, place(0x5a2))
        let sh = try heads(sw1, [sid])
        sw1.active.update(id: sh[0]) { $0.ridingLatch = true; $0.rider = 9999 }
        frame(sw1, sid, 0)
        XCTAssertEqual(try slot(sw1, sid).geyserTarget, 0x6400)
        XCTAssertTrue(try slot(sw1, sh[0]).ridingLatch)
        // `.KillBox` on the triple (type 0x5a5 is in 0x5a0…0x5a8): its own head and segment killed, the block cleared.
        let (kw, _) = try world()
        let (kid, _, _) = try geyser(kw, place(0x5a5))
        let kh = try heads(kw, [kid])[0]
        let kseg = try XCTUnwrap(try block(kw, kid).segments[0])
        BoxSprite.killBox(kw, id: kid)
        XCTAssertEqual(try block(kw, kid), SpriteSlot.GeyserBlock())
        XCTAssertEqual([try slot(kw, kh).dead, try slot(kw, kseg).dead], [true, true])
    }

    func testIdleReactivationKeepsBlock() throws {
        // NR 2 (Ruling 9): `.IdleToActiveSprite` (M l. 4215–4268) runs no Setup — no R(4), no second `AllocateGameMem` —
        // restores the saved bytes, `+0xe9 = 0`, `+0xa8` = the idle index; `.MTKillSprite` frees nothing, so the `+0x9c`
        // block idles with the record and is reused.
        let (w, _) = try world()
        let p = place(0x5a2, p2: 30, p3: 200)
        w.records = [p]
        let c = SetupFaces.Context(level: w.level, playerX: 0, records: w.records)
        var lights = LightTable()
        let e = try SetupFaces.setup(p, context: c, lights: &lights, rng: &w.rng)
        let k = try XCTUnwrap(w.idle.add(e.slot, faceRect: .noFace))
        let near = { (w: SpriteWorld) in w.idle.handle(h: 200, v: 400, playerHotRect: nil, active: &w.active) { _ in .noFace } }
        let far = { (w: SpriteWorld) in w.idle.handle(h: 4000, v: 4000, playerHotRect: nil, active: &w.active) { _ in .noFace } }
        var seed0 = w.rng.seed
        XCTAssertEqual(near(w).activated, [k])
        XCTAssertEqual(w.rng.seed, seed0, "no Setup draw")
        let id = try XCTUnwrap(w.idle.entries[k]?.activeID)
        var s = try slot(w, id)
        XCTAssertEqual([s.dead, s.handleCleared], [false, false])
        XCTAssertEqual(Int(s.idleEntry), k)
        XCTAssertEqual(s.geyserColumn, SpriteSlot.GeyserBlock())
        XCTAssertEqual(s.phase, e.slot.phase)
        // Erupting: `+0x1c6 = 0` — out of the window it stays active, its head in the block.
        frame(w, id, 0)
        frame(w, id, 1)
        let head = try XCTUnwrap(try block(w, id).head)
        XCTAssertEqual(far(w).deactivated, [])
        // Collapsed (t ≥ 30 and down to 0): the head and segments killed, `+0x1c6 = 1`; then it idles.
        var C: Int32 = 2
        while try slot(w, id).geyserHeight > 0 || C < 31 {
            frame(w, id, C)
            C += 1
            guard C < 400 else { return XCTFail("never collapsed") }
        }
        XCTAssertTrue(try slot(w, head).dead)
        s = try slot(w, id)
        XCTAssertEqual([s.mayIdle], [true])
        XCTAssertEqual(far(w).deactivated, [k])
        let saved = try XCTUnwrap(w.idle.entries[k]?.saved)
        XCTAssertEqual(saved.geyserColumn, SpriteSlot.GeyserBlock())
        var l2 = LightTable()
        w.updateSprites(lights: &l2)
        // Back on screen: the same record bytes, the block kept, no draw; `+0xa8` = k again.
        seed0 = w.rng.seed
        XCTAssertEqual(near(w).activated, [k])
        XCTAssertEqual(w.rng.seed, seed0)
        let id2 = try XCTUnwrap(w.idle.entries[k]?.activeID)
        let s2 = try slot(w, id2)
        XCTAssertEqual([Int(s2.idleEntry), s2.dead ? 1 : 0], [k, 0])
        XCTAssertEqual(s2.geyserColumn, saved.geyserColumn)
        XCTAssertEqual([s2.phase, s2.counterA6], [saved.phase, saved.counterA6])
        XCTAssertEqual([s2.geyserTarget, s2.geyserOn, s2.geyserOff], [0x6400, 30, 200])
        // The reused block takes the next head.
        w.active.update(id: id2) { $0.geyserHeight = 0x2000 }
        var l3 = LightTable()
        Geyser.column(w, id: id2, lights: &l3, effects: 1)
        XCTAssertNotNil(try block(w, id2).head)
    }
}
