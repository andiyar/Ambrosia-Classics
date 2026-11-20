import XCTest
@testable import DeimosCore
@testable import DeimosRender

/// Phase 4 S3b LS — the level select's hover strip through the real blitter. The strip `FUN_1002f7a0` builds
/// (`1002f8e4..1002f9b4`) takes the back buffer's bounds as its clip (`1002f920 addi r4,r1,0x154` → `1002f934 bl
/// 0x1000a530`; X `1002fd00..1002fd14`) and is drawn now (+0x31 = 1, `1002f998`), so it shows on the right-hand
/// preview as on the other two — the seat's ruling of 2026-11-20, correcting plan ruling 15 / grounding A risk 7.
/// The flash wash (`1002fb94..1002fc10`) keeps the template clip {0, 0, 480, 416}. Bounded: one entry and a few
/// frames per case (G11).
final class LevelSelectDrawTests: XCTestCase {

    /// Run passes through a renderer (the host's waits are skipped: nothing here is timed).
    private func apply(_ s: ScreenStep<Int?>, _ r: DeimosRenderer) {
        for op in s.output.ops where !RenderOp.isHostOp(op) { r.apply(op) }
    }

    func testHoverStripRightPreviewDrawn() throws {
        let a = try ShippedAssets.get()
        let f29 = a.formats[29]
        XCTAssertEqual(f29.coloriseColor, 0x03ff, "lsbo: cyan 00ffff")
        XCTAssertEqual(f29.blendAmount, 20)
        XCTAssertEqual([f29.locX, f29.locY], [-1, -1])

        var plain: [Int: (top: UInt16, left: UInt16)] = [:]
        for hovered in [nil, 0, 1, 2] as [Int?] {
            let r = DeimosRenderer(assets: a)
            var state = try FrontEndState(assets: a, prefs: .fresh)
            var ls = LevelSelect()
            apply(ls.pass(keys: HeldKeys(), ticks: 0, returned: nil, state: &state), r)
            let rects = ls.previews.map(\.rect)
            var keys = HeldKeys()
            if let i = hovered {
                let p = rects[i]
                keys.mouse = MousePoint(h: p.left + 20, v: p.top + 20)
            }
            let s = ls.pass(keys: keys, ticks: 2, returned: nil, state: &state)
            apply(s, r)
            let strips = s.output.ops.compactMap { op -> DrawCommand? in
                if case let .draw(c) = op, c.face == FourCC("COST")!, c.drawNow { return c }
                return nil
            }
            let back = r.buffer(.back)
            for (i, p) in rects.enumerated() {
                // The 1-px border the strip leaves around the preview (the copy covers its inside).
                let top = back[Int(p.left) + 30, Int(p.top) - 1], left = back[Int(p.left) - 1, Int(p.top) + 30]
                guard let h = hovered else { plain[i] = (top, left); continue }
                let base = try XCTUnwrap(plain[i])
                if i == h {
                    XCTAssertEqual(top, Blend555.blend(base.top, 0x03ff, a: 20), "preview \(i): top edge")
                    XCTAssertEqual(left, Blend555.blend(base.left, 0x03ff, a: 20), "preview \(i): left edge")
                    XCTAssertNotEqual(top, base.top, "preview \(i): the strip shows")
                } else {
                    XCTAssertEqual(top, base.top, "preview \(i) not hovered")
                    XCTAssertEqual(left, base.left, "preview \(i) not hovered")
                }
            }
            guard let h = hovered else { XCTAssertTrue(strips.isEmpty); continue }
            let p = rects[h]
            XCTAssertEqual(strips.count, 1)
            let c = try XCTUnwrap(strips.first)
            XCTAssertEqual(c.costRect, MacRect(top: p.top - 1, left: p.left - 1, bottom: p.bottom + 1, right: p.right + 1))
            XCTAssertEqual(c.clip, MacRect(top: 0, left: 0, bottom: 480, right: 640))
            XCTAssertEqual(c.alpha, 20)
            XCTAssertEqual(c.costColour, 0x03ff)
            if h == 2 {
                XCTAssertEqual(c.costRect, MacRect(top: 75, left: 436, bottom: 383, right: 584), "148×308 at x 436")
                XCTAssertEqual(SpriteBlitter.select(c, frame: nil).path, .cost, "not rejected")
            }
        }

        // The accept flash's wash keeps the template clip (x < 416) over the middle preview.
        var state = try FrontEndState(assets: a, prefs: .fresh)
        var ls = LevelSelect()
        _ = ls.pass(keys: HeldKeys(), ticks: 0, returned: nil, state: &state)
        _ = ls.pass(keys: HeldKeys(held: [0x31]), ticks: 2, returned: nil, state: &state)
        let s = ls.pass(keys: HeldKeys(), ticks: 4, returned: nil, state: &state)
        let wash = s.output.ops.compactMap { op -> DrawCommand? in
            if case let .draw(c) = op, c.face == FourCC("COST")!, c.drawNow { return c }
            return nil
        }
        XCTAssertEqual(wash.map(\.clip), [SpriteBlitter.gameAreaClip])
        XCTAssertEqual(wash.map(\.costRect), [ls.previews[1].rect])
    }
}
