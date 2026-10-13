import XCTest
import FerazelCore
@testable import FerazelRender

/// E1a (docs/plans/2026-10-10-ferazel-phase2.md): `ParticleRenderer` — the `.InitParticleColors @ 100306b4` rows
/// against Core's colour-0 table (`ParticleLife`), sample indices of bank particles §4.3 (CLUT 202, the exact-nearest
/// model), `.WrapDrawParticle @ 10015948`'s footprints and mask rule (§3.2), and `.EraseParticles @ 10031d6c`'s
/// restore (§3.3), the ring wrap included.
final class ParticleRenderTests: XCTestCase {

    func testParticleRendererRowsAndErase() throws {
        let res = try FerazelData.open(try FerazelData.dataDirectory())
        let system = try ColorLUT.load(id: 801, from: res, chain: .frontEnd)
        var exact202: [[UInt8]] = []
        for level: Int16 in [1, 2] {
            let L = try LevelFile.load(from: res, level: level)
            let clutID = ColorLUT.screenClutId(L.header)
            let clut = try ColorLUT.load(id: clutID, from: res, chain: .level)
            for model in [ColorSearch.Model.exactNearest, .ruled] {
                let rows = ParticleRenderer.colourRows(system: system, screenClut: clut,
                                                       search: ColorSearch(model: model))
                XCTAssertEqual([rows.count, Set(rows.map(\.count)).first ?? 0], [0x100, 0x78])
                // Core's colour-0 test and these rows agree on every (kind, age ≥ 1): a row's first 0 is the life.
                var mismatches: [String] = []
                var alive: [ParticleDraw] = []
                for k in 0..<0x100 {
                    for a in 1..<0x78 {
                        let core = ParticleLife.colourIsZero(kind: Int16(k), age: Int16(a))
                        if (rows[k][a] == 0) != core { mismatches.append("L\(level) \(model) k\(k) a\(a)") }
                        if !core { alive.append(ParticleDraw(slot: 0, kind: Int16(k), age: Int16(a), shape: 1, v: -100,
                                                             h: -100)) }
                    }
                }
                XCTAssertEqual(mismatches, [])
                // So nothing Core hands over is a row-0 colour (drawn off the view: no pixel is touched).
                var r = ParticleRenderer(rows: rows, ambient: Array(0...255), effects: 1)
                var ports = FramePorts()
                r.draw(alive, scroll: (h: 0, v: 0), ports: &ports)
                XCTAssertEqual(r.rowDisagreements, 0, "L\(level) \(model)")
                XCTAssertEqual(ports, FramePorts())
                r.draw([ParticleDraw(slot: 0, kind: 14, age: 1, shape: 1, v: 0, h: 0)], scroll: (h: 0, v: 0),
                       ports: &ports)
                XCTAssertEqual(r.rowDisagreements, 1)
                if clutID == 202, model == .exactNearest { exact202 = rows }
            }
        }
        // Level 1 is on CLUT 202: bank §4.3's sample indices (kind: [age: index]). Kind 12 differs from the bank's
        // "t1–11 78" below t 10: (20 − t)·0x1900 is stored with `sth` (raw 10030d38–10030d3c), so t 1 asks for green
        // 121600 & 0xffff = 56064 → 46; t 10 (64000) is the first 78.
        let samples: [Int: [Int: UInt8]] = [
            1: [1: 1, 4: 2, 8: 4, 12: 9, 16: 77, 20: 68], 2: [1: 76, 24: 77, 30: 174], 3: [1: 59, 4: 64, 8: 69],
            4: [1: 151, 2: 153, 8: 176, 12: 193], 10: [1: 158, 4: 155, 8: 151, 16: 159], 11: [1: 137, 12: 141],
            12: [1: 46, 10: 78, 11: 78, 12: 46], 200: [1: 29, 16: 59, 24: 69], 201: [1: 113, 5: 114, 10: 115, 15: 116],
            220: [1: 29, 8: 59], 221: [1: 78, 4: 46], 222: [1: 76, 8: 174],
        ]
        XCTAssertEqual(exact202.count, 0x100)
        for (k, ages) in samples { for (a, i) in ages { XCTAssertEqual(exact202[k][a], i, "kind \(k) age \(a)") } }

        // `.WrapDrawParticle`'s footprints (§3.2) at (v 50, h 100), mask all 0xff → drawn, mask cleared under the
        // drawn pixels, `+0x1d` 1; `.EraseParticles` (`FUN_10015fb8`) restores them from the tile port, mask 0xff.
        let w = FramePorts.width
        func fresh(mask: UInt8) -> FramePorts {
            var p = FramePorts(fill: mask)
            p.frame = [UInt8](repeating: 0, count: p.frame.count)
            p.tiles = (0..<p.tiles.count).map { UInt8(truncatingIfNeeded: $0 * 7 + 1) | 0x80 }
            return p
        }
        func pixels(_ p: FramePorts) -> Set<[Int]> {
            Set(p.frame.indices.filter { p.frame[$0] != 0 }.map { [$0 % w, $0 / w] })
        }
        func rects(_ rows: [String], x: Int, y: Int) -> Set<[Int]> {
            var s = Set<[Int]>()
            for (dy, row) in rows.enumerated() { for (dx, c) in row.enumerated() where c == "#" { s.insert([x + dx, y + dy]) } }
            return s
        }
        let shapes: [Int16: [String]] = [1: ["#"], 2: ["##", "##"], 3: [".##.", "####", "####", ".##."], 4: ["#", "#"],
                                         5: ["##", "##", "##", "##"], 6: ["####"], 7: ["##"]]
        for (shape, rows) in shapes {
            var p = fresh(mask: 0xff)
            var r = ParticleRenderer(rows: [], ambient: [], effects: 1)
            r.draw([ParticleDraw(slot: 3, kind: 0x109, age: 1, shape: shape, v: 50, h: 100)], scroll: (h: 0, v: 0),
                   ports: &p)
            let foot = rects(rows, x: 100, y: 50)
            XCTAssertEqual(pixels(p), foot, "shape \(shape)")
            XCTAssertEqual(Set(foot.map { p.frame[$0[1] * w + $0[0]] }), [9])
            XCTAssertEqual(Set(p.mask.indices.filter { p.mask[$0] == 0 }.map { [$0 % w, $0 / w] }), foot)
            XCTAssertEqual(r.drawn.map(\.erase), [1])
            r.erase(scroll: (h: 0, v: 0), ports: &p)
            XCTAssertEqual(p.mask, [UInt8](repeating: 0xff, count: p.mask.count))
            for q in foot { XCTAssertEqual(p.frame[q[1] * w + q[0]], p.tiles[q[1] * w + q[0]], "shape \(shape) \(q)") }
            XCTAssertEqual(Set(p.frame.indices.filter { p.frame[$0] != 0 }.map { [$0 % w, $0 / w] }), foot)
        }
        // Mask all 0 → drawn, mask kept, `+0x1d` 2; shape 3's mode-2 erase (`FUN_10016440`) restores the whole 4×4.
        do {
            var p = fresh(mask: 0)
            var r = ParticleRenderer(rows: [], ambient: [], effects: 1)
            r.draw([ParticleDraw(slot: 0, kind: 0x109, age: 1, shape: 3, v: 50, h: 100)], scroll: (h: 0, v: 0),
                   ports: &p)
            XCTAssertEqual(pixels(p), rects(shapes[3]!, x: 100, y: 50))
            XCTAssertEqual(r.drawn.map(\.erase), [2])
            XCTAssertEqual(p.mask, [UInt8](repeating: 0, count: p.mask.count))
            p.frame[50 * w + 100] = 0x55                                      // a corner outside the footprint
            r.erase(scroll: (h: 0, v: 0), ports: &p)
            XCTAssertEqual(pixels(p), rects(["####", "####", "####", "####"], x: 100, y: 50))
            XCTAssertEqual(p.frame[50 * w + 100], p.tiles[50 * w + 100])
            XCTAssertEqual(p.mask, [UInt8](repeating: 0, count: p.mask.count))
        }
        // Mixed mask → not drawn, `+0x1d` 0, nothing erased. Shape 3 tests all 16 bytes (a corner counts); shape 1
        // tests one byte and is never suppressed (≠ 0xff → 2).
        for (shape, hole, mode) in [(Int16(2), [101, 51], UInt8(0)), (3, [100, 50], 0), (1, [100, 50], 2)] {
            var p = fresh(mask: 0xff)
            p.mask[hole[1] * w + hole[0]] = 0x80
            let before = p
            let m = ParticleRenderer.wrapDrawParticle(9, shape: shape, v: 50, h: 100, scroll: (h: 0, v: 0), ports: &p)
            XCTAssertEqual(m, mode, "shape \(shape)")
            if mode == 0 { XCTAssertEqual(p, before) } else { XCTAssertEqual(pixels(p), [[100, 50]]) }
        }
        // Shape 0 / > 7: no case — r3 (the colour) comes back, nothing drawn (`bgt 0x10015f88`, jump word 0x15f88).
        for shape: Int16 in [0, 8] {
            var p = fresh(mask: 0xff)
            XCTAssertEqual(ParticleRenderer.wrapDrawParticle(9, shape: shape, v: 50, h: 100, scroll: (h: 0, v: 0),
                                                             ports: &p), 9)
            XCTAssertEqual(pixels(p), [])
        }
        // The view and ring (raw `10015968..10015a8c`): 2 px left of the view clamps onto its edge; off the view
        // returns the colour; ring x 0x27f (in the view at H 0x40) is off the ring's usable part → 0.
        do {
            var p = fresh(mask: 0xff)
            XCTAssertEqual(ParticleRenderer.wrapDrawParticle(9, shape: 1, v: 50, h: 0x3e, scroll: (h: 0x40, v: 0),
                                                             ports: &p), 1)
            XCTAssertEqual(pixels(p), [[0x40, 50]])
            var q = fresh(mask: 0xff)
            XCTAssertEqual(ParticleRenderer.wrapDrawParticle(9, shape: 1, v: 50, h: 0x3d, scroll: (h: 0x40, v: 0),
                                                             ports: &q), 9)
            XCTAssertEqual(ParticleRenderer.wrapDrawParticle(9, shape: 2, v: 50, h: 0x27f, scroll: (h: 0x40, v: 0),
                                                             ports: &q), 0)
            XCTAssertEqual(pixels(q), [])
        }
        // The ring wrap: world (h 0x280 + 10, v 0x1a0 + 20) at scroll (0x280, 0x1a0) lives at ring (10, 20); the erase
        // restores exactly those pixels.
        do {
            var p = fresh(mask: 0xff)
            var r = ParticleRenderer(rows: [], ambient: [], effects: 1)
            let scroll = (h: 0x280, v: 0x1a0)
            r.draw([ParticleDraw(slot: 0, kind: 0x109, age: 1, shape: 5, v: 0x1a0 + 20, h: 0x280 + 10)], scroll: scroll,
                   ports: &p)
            let foot = rects(shapes[5]!, x: 10, y: 20)
            XCTAssertEqual(pixels(p), foot)
            r.erase(scroll: scroll, ports: &p)
            for q in foot { XCTAssertEqual(p.frame[q[1] * w + q[0]], p.tiles[q[1] * w + q[0]]) }
            XCTAssertEqual(p.mask, [UInt8](repeating: 0xff, count: p.mask.count))
        }
    }
}
