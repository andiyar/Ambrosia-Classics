import XCTest
import HectorResources
@testable import DeimosCore

/// Score-bar draw ops (hud-scorebar.md §4–§5, §7): `FUN_10031400`'s loads + `FUN_10031ae0`'s elements.
final class ScoreBarDrawTests: XCTestCase {
    /// The exact level-start op list of a solo game (screen blits off), in the listing's order: P1 score,
    /// symbol, count, weapon slots 0–2, shield, power; then P2 the same, dimmed (no icons).
    func testScoreBarLevelStartOps() throws {
        let a = try TestAssets.loaded.get()
        let w = try TestWorld(assets: a, players: 1)
        let ops = try ScoreBarDraw(assets: a).levelStartOps(state: w.bar)

        func rect(_ t: Int32, _ l: Int32, _ b: Int32, _ r: Int32) -> MacRect { MacRect(top: t, left: l, bottom: b, right: r) }
        func restore(_ local: MacRect) -> RenderOp {
            .copy(from: .scoreSave, to: .back, src: local,
                  dst: rect(local.top, local.left + 416, local.bottom, local.right + 416), interlaced: false)
        }
        func hud(_ face: String, _ frame: Int, _ x: Int32, _ y: Int32, flags: UInt32 = 0, alpha: UInt32 = 0,
                 scale: Float = 1, layer: UInt8 = 7, colour: UInt16 = 0x7fff) -> RenderOp {
            .draw(DrawCommand(face: FourCC(face)!, frame: frame, x: x, y: y, flags: flags, scale: scale, alpha: alpha,
                              clip: rect(0, 0, 480, 640), layer: layer, drawNow: true, colour: colour))
        }
        func digits(_ frame: Int, _ xs: [Int32], _ y: Int32, alpha: UInt32) -> [RenderOp] {
            xs.map { hud("tesm", frame, $0, y, flags: 4, alpha: alpha, layer: 8, colour: 0x4B7C) }
        }
        func cost(_ r: MacRect) -> RenderOp {
            .draw(DrawCommand(face: FourCC("COST")!, alpha: 8, clip: rect(0, 0, 480, 640), drawNow: true,
                              costRect: r, costColour: 0))
        }
        let scoreXs: [Int32] = [466, 476, 486, 496, 506, 516, 526]     // glyph lefts 463…523 + 7/2

        var expected: [RenderOp] = [
            .loadImage(image: FourCC("scor")!, into: .back, dst: rect(0, 416, 480, 576)),
            .loadImage(image: FourCC("scor")!, into: .scoreSave, dst: rect(0, 0, 480, 160)),
        ]
        // P1 (active).
        expected.append(restore(rect(81, 25, 95, 135)))
        expected += digits(61, scoreXs, 89, alpha: 0)                  // "0000000", top 83
        expected.append(restore(rect(22, 98, 62, 138)))
        expected.append(hud("play", 0, 534, 41))                       // 38×38 → 515..552 × 22..59
        expected.append(restore(rect(19, 56, 63, 102)))
        expected.append(hud("tesm", 53, 499, 56, flags: 4, layer: 8, colour: 0x4B7C))   // "2" at 496, top 50
        expected.append(restore(rect(181, 33, 216, 65)))
        expected.append(hud("wesy", 0, 467, 199, flags: 1, alpha: 6))  // slot 0
        expected.append(restore(rect(188, 76, 210, 95)))               // slot 1: none
        expected.append(restore(rect(188, 103, 210, 124)))             // slot 2: none
        expected.append(restore(rect(117, 31, 132, 127)))
        expected.append(hud("shme", 0, 495, 124))                      // 96×13 → 447..542
        expected.append(cost(rect(117, 447, 132, 543)))                // fill 0 → from x 447
        expected.append(restore(rect(152, 31, 167, 127)))
        expected.append(hud("shme", 1, 495, 159))
        expected.append(cost(rect(152, 447, 167, 543)))
        // P2 (not in game: dimmed, no icons, never blitted).
        expected.append(restore(rect(317, 25, 333, 135)))
        expected += digits(61, scoreXs, 324, alpha: 16)                // top 318
        expected.append(restore(rect(257, 98, 297, 138)))
        expected.append(hud("play", 1, 534, 276, flags: 1, alpha: 16))
        expected.append(restore(rect(263, 56, 307, 102)))
        expected.append(hud("tesm", 61, 498, 291, flags: 4, alpha: 16, layer: 8, colour: 0x4B7C))  // "0" at 495, top 285
        expected.append(restore(rect(416, 33, 451, 65)))
        expected.append(restore(rect(423, 76, 445, 95)))
        expected.append(restore(rect(423, 103, 445, 124)))
        expected.append(restore(rect(353, 31, 368, 127)))
        expected.append(hud("shme", 0, 495, 359))
        expected.append(cost(rect(353, 447, 368, 543)))
        expected.append(restore(rect(388, 31, 403, 127)))
        expected.append(hud("shme", 1, 495, 394))
        expected.append(cost(rect(388, 447, 403, 543)))

        XCTAssertEqual(ops.count, expected.count)
        for (i, (got, want)) in zip(ops, expected).enumerated() { XCTAssertEqual(got, want, "op \(i)") }
        XCTAssertFalse(ops.contains { if case .screenBlit = $0 { return true } else { return false } })

        // With the screen blits on (after the game appears), each element ends with its blit, + (0, 448).
        var bar = w.bar
        bar.records[1].dirty = []
        bar.records[0].dirty = [.livesSymbol]
        let blit = try ScoreBarDraw(assets: a).drawOps(state: bar, blitToScreen: true)
        XCTAssertEqual(blit, [restore(rect(22, 98, 62, 138)), hud("play", 0, 534, 41),
                              .screenBlit(src: rect(22, 514, 62, 554), dst: rect(22, 546, 62, 586))])
        // A part-full meter: fill = fctiwz(0.625f × 96) = 60 → COST from 507.
        bar.records[0].dirty = [.shield]
        bar.records[0].shownShield = 62.5
        let m = try ScoreBarDraw(assets: a).drawOps(state: bar, blitToScreen: false)
        XCTAssertEqual(m.last, cost(rect(117, 507, 132, 543)))
    }
}
