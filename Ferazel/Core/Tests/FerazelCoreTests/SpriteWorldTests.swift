import XCTest
import HectorResources
@testable import FerazelCore

/// F2 (docs/plans/2026-10-10-ferazel-phase2.md): the sprite physics world — the handle pass and the layer-change
/// guard (`.MTHandleSprites @ 1003259c`, `.MTChangeSpriteLayer @ 10033288`, platforms-ropes-radial-2 §8.2), the
/// solids (`.PlatformBounce @ 100377c4` → `.RectBounce @ 1003e490`, physics-sprites §8.1) and
/// `.StandardSpriteHandles @ 10036854` (carry, water current) — against the committed level 1 (its header 0x2714
/// water current is 550).
final class SpriteWorldTests: XCTestCase {

    private func world() throws -> SpriteWorld {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        return SpriteWorld(level: try LevelFile.load(from: r, level: 1))
    }

    /// A solid at (100, 200) with hot rect 0…16 × 0…64, and a mover with hot rect 0…32 × 0…16 at (110, y).
    private func solidAndMover(_ w: SpriteWorld, moverY: Int, vy: Int32) -> (mover: Int, solid: Int) {
        let solid = w.newSprite(type: 1400, x: 100, y: 200, layer: -1, handler: .platform) {
            $0.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 16, right: 64)
        }!
        let mover = w.newSprite(type: 0x45, x: 110, y: moverY, layer: 10, handler: .player) {
            $0.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 32, right: 16)
            $0.vy = vy
        }!
        return (mover, solid)
    }

    private func land(_ w: SpriteWorld, _ ids: (mover: Int, solid: Int)) -> Int16 {
        let r = w.active.sprite(id: ids.mover)!.hotRect
        return w.platformBounce(mover: ids.mover, solid: ids.solid, factor: 0, rect: r, bounce: false)
    }

    func testChangeLayerSameLayerIsNoOp() throws {
        let w = try world()
        let a = w.newSprite(type: 1400, x: 0, y: 0, layer: 0, handler: .platform)!
        let b = w.newSprite(type: 1400, x: 0, y: 0, layer: 0, handler: .platform)!
        let c = w.newSprite(type: 1400, x: 0, y: 0, layer: 0, handler: .platform)!
        w.changeLayer(id: a, layer: 0)                        // `cmpw; beq` (raw 100332a4..100332a8): nothing moves
        XCTAssertEqual(w.active.sprites.map(\.id), [a, b, c])
        w.changeLayer(id: a, layer: 1)                        // remove + insert: the tail
        XCTAssertEqual(w.active.sprites.map(\.id), [b, c, a])
        XCTAssertEqual(w.active.sprite(id: a)?.layer, 1)
    }

    func testChangeLayerToFrontReHandlesInSameFrame() throws {
        let w = try world()
        let a = w.newSprite(type: 1400, x: 0, y: 0, layer: 0, handler: .platform)!
        let b = w.newSprite(type: 1400, x: 0, y: 0, layer: 0, handler: .platform)!
        let p = w.newSprite(type: 0x45, x: 0, y: 0, layer: 10, handler: .player)!
        var seen: [Int] = []
        w.handleSprites { world, id in
            seen.append(id)
            if id == a && seen.count == 1 { world.changeLayer(id: a, layer: 20) }   // to a layer above everything
        }
        // `next` (b) was loaded before a's Handle; a now sits after p, so the walk reaches it again.
        XCTAssertEqual(seen, [a, b, p, a])
        XCTAssertEqual(seen.filter { $0 == a }.count, 2)
        // A same-layer change inside the pass is the no-op: handled once.
        var once: [Int] = []
        w.handleSprites { world, id in
            once.append(id)
            if id == b { world.changeLayer(id: b, layer: 0) }
        }
        XCTAssertEqual(once, [b, p, a])
    }

    func testRectBounceLandingNeedsPositiveVy() throws {
        let w1 = try world()
        let down = solidAndMover(w1, moverY: 170, vy: 0x1b8)
        XCTAssertEqual(land(w1, down), 1)                     // vy > 0 from above (M l. 36296–36300)
        let m1 = w1.active.sprite(id: down.mover)!
        XCTAssertEqual(m1.vy, 0)
        XCTAssertEqual(m1.y, 168)                             // bottom on the top: 200 − 32
        XCTAssertEqual(m1.y256, 168 << 8)
        XCTAssertEqual(m1.groundKind, 3)
        XCTAssertEqual(m1.onSprite, 1)
        XCTAssertEqual(m1.ridden, down.solid)
        let s1 = w1.active.sprite(id: down.solid)!
        XCTAssertEqual(s1.rider, down.mover)
        XCTAssertTrue(s1.ridingLatch)

        let w2 = try world()
        let up = solidAndMover(w2, moverY: 170, vy: -0x100)
        XCTAssertEqual(land(w2, up), 0)
        let m2 = w2.active.sprite(id: up.mover)!
        XCTAssertEqual(m2.vy, -0x100)
        XCTAssertNil(m2.ridden)
        XCTAssertEqual(m2.groundKind, 0)
    }

    func testOneWaySlackIs8() throws {
        // vy 0x1000 (16 px): previous bottom = y − 16 + 32; the top is 200.
        for (y, lands) in [(192, true), (193, false)] {
            let w = try world()
            let ids = solidAndMover(w, moverY: y, vy: 0x1000)
            w.active.update(id: ids.solid) { $0.oneWay = true }
            XCTAssertEqual(land(w, ids), lands ? 1 : 0, "previous bottom \(y + 16)")
            let m = w.active.sprite(id: ids.mover)!
            XCTAssertEqual(m.oneWayLanded, lands)
            XCTAssertEqual(m.y, lands ? 168 : y)
        }
    }

    func testLandingSagAdds13aShare() throws {
        let w = try world()
        let ids = solidAndMover(w, moverY: 170, vy: 0x400)
        w.active.update(id: ids.solid) { $0.sag = 0x50 }
        XCTAssertEqual(land(w, ids), 1)
        XCTAssertEqual(w.active.sprite(id: ids.solid)?.vy, 320)   // 0x400 · 0x50 >> 8
        // Entry vy 0x200 is not > 0x200: no sag.
        let w2 = try world()
        let ids2 = solidAndMover(w2, moverY: 170, vy: 0x200)
        w2.active.update(id: ids2.solid) { $0.sag = 0x50 }
        XCTAssertEqual(land(w2, ids2), 1)
        XCTAssertEqual(w2.active.sprite(id: ids2.solid)?.vy, 0)
    }

    func testLandingRestoresMoverX() throws {
        let w = try world()
        let ids = solidAndMover(w, moverY: 170, vy: 0x1b8)
        w.active.update(id: ids.mover) { m in
            m.x256 = (110 << 8) + 0xc0
            m.y256 = (170 << 8) + 0x40
            m.vx = 0x300
        }
        XCTAssertEqual(land(w, ids), 1)
        let m = w.active.sprite(id: ids.mover)!
        XCTAssertEqual(m.x256, (110 << 8) + 0xc0)             // the entry 24.8 x, fraction kept
        XCTAssertEqual(m.x, 110)
        XCTAssertEqual(m.vx, 0x300)
        XCTAssertEqual(m.y256, 168 << 8)                      // y snapped: its fraction dropped
    }

    func testCarryAddsDrawnDeltaPlusOnePixel() throws {
        let w = try world()
        let solid = w.newSprite(type: 1400, x: 100, y: 200, layer: -1, handler: .platform) {
            $0.face = FaceRef(pict: 1400, index: 0, set: .encoded)
        }!
        let sib = w.newSprite(type: 1400, x: 300, y: 50, layer: -1, handler: .platform)!
        let rider = w.newSprite(type: 0x45, x: 110, y: 168, layer: 10, handler: .player) { s in
            s.siblings.first = sib
        }!
        _ = w.active.wrapDrawSprites()                        // the solid's `+0xc6`/`+0xc4` = (100, 200)
        w.active.update(id: solid) { $0.x = 105 }             // +5 px since the draw
        w.active.update(id: rider) { $0.ridden = solid }
        w.standardSpriteHandles(rider)
        let r = w.active.sprite(id: rider)!
        XCTAssertEqual(r.x256, 115 << 8)
        XCTAssertEqual(r.y256, 169 << 8)                      // + 0x100
        XCTAssertEqual([r.x, r.y], [115, 169])
        XCTAssertEqual(r.groundKind, 3)
        XCTAssertEqual(w.active.sprite(id: sib)?.x, 305)      // `+0x1d4` carried by dx only
        XCTAssertEqual(w.active.sprite(id: sib)?.y, 50)
    }

    func testCurrentRampsOver33Frames() throws {
        let w = try world()
        XCTAssertEqual(w.level.header.waterCurrent, 550)
        let s = w.newSprite(type: 1400, x: 0, y: 0, layer: 0, handler: .platform)!
        var pushes: [Int32] = []
        for _ in 0..<36 {
            w.active.update(id: s) { $0.waterRow = 1 }          // in water (kind 0) as the tile pass leaves it
            let before = w.active.sprite(id: s)!.x256
            w.standardSpriteHandles(s)
            let after = w.active.sprite(id: s)!
            pushes.append(after.x256 - before)
            XCTAssertEqual(after.waterRow, 0)
            XCTAssertEqual(after.lastWater, 1)
        }
        XCTAssertEqual(Array(pushes.prefix(5)), [16, 33, 50, 66, 83])   // 550·n / 33
        XCTAssertEqual(pushes[31], 533)                       // n 32
        XCTAssertEqual(Array(pushes[32...]), [550, 550, 550, 550])   // n 33 on
        // Riding: no push (the ramp still counts).
        let w2 = try world()
        let r = w2.newSprite(type: 1400, x: 0, y: 0, layer: 0, handler: .platform)!
        let solid = w2.newSprite(type: 1400, x: 0, y: 0, layer: -1, handler: .platform)!
        w2.active.update(id: r) { $0.waterRow = 1; $0.ridden = solid }
        let before = w2.active.sprite(id: r)!.x256
        w2.standardSpriteHandles(r)
        XCTAssertEqual(w2.active.sprite(id: r)!.x256 - before, 0)   // the carry adds 0 (solid not moved)
        XCTAssertEqual(w2.active.sprite(id: r)!.currentRamp, 1)
    }
}
