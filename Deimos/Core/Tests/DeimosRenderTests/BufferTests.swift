import XCTest
import DeimosCore
@testable import DeimosRender

/// R1 — buffers, CopyBits, presents, the fade from black, the blend kernel, RGBA (plan R1;
/// display-window-present §1–§5, loose-ends-session §6, blit-pixel-rules §2).
final class BufferTests: XCTestCase {

    private func rgb(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 { (r << 10) | (g << 5) | b }

    /// A buffer whose every pixel is distinct-ish (x, y folded into the 15 bits).
    private func pattern(width: Int, height: Int, seed: UInt16 = 0) -> Pixmap555 {
        var p = Pixmap555(width: width, height: height)
        for y in 0..<height {
            for x in 0..<width {
                p[x, y] = UInt16(truncatingIfNeeded: (x &* 31 &+ y &* 977 &+ Int(seed) &* 7) & 0x7fff)
            }
        }
        return p
    }

    // FUN_1001e9d0: ⌊(A·a + B·(32 − a))/32⌋ per 5-bit field, no carry between fields.
    func testBlendKernelFloor() {
        XCTAssertEqual(Blend555.blend(0x7FFF, 0x0000, a: 16), 0x3DEF)
        XCTAssertEqual(Blend555.blend(0x7FFF, 0x0000, a: 32), 0x7FFF)
        XCTAssertEqual(Blend555.blend(0x7FFF, 0x0000, a: 0), 0x0000)
        XCTAssertEqual(Blend555.blend(0x1234, 0x5678, a: 32), 0x1234)
        XCTAssertEqual(Blend555.blend(0x1234, 0x5678, a: 0), 0x5678)
        // Per-channel floor, no rounding: 1·1 + 0·31 = 1 → ⌊1/32⌋ = 0 in every field.
        XCTAssertEqual(Blend555.blend(rgb(1, 1, 1), 0, a: 1), 0)
        // 31·31 + 0 = 961 → 30 per field; no field leaks into its neighbour.
        XCTAssertEqual(Blend555.blend(rgb(31, 0, 0), 0, a: 31), rgb(30, 0, 0))
        XCTAssertEqual(Blend555.blend(rgb(0, 31, 0), 0, a: 31), rgb(0, 30, 0))
        XCTAssertEqual(Blend555.blend(rgb(0, 0, 31), 0, a: 31), rgb(0, 0, 30))
        // Mixed: R (20·12 + 5·20)/32 = 10.6 → 10; G (3·12 + 31·20)/32 = 20.5 → 20; B (31·12 + 0)/32 = 11.6 → 11.
        XCTAssertEqual(Blend555.blend(rgb(20, 3, 31), rgb(5, 31, 0), a: 12), rgb(10, 20, 11))
        // Bit 15 of either input is masked off; the output never has it.
        XCTAssertEqual(Blend555.blend(0x8000 | 0x7FFF, 0x8000, a: 16), 0x3DEF)
        // Exhaustive per-channel check against the formula.
        for a in 0...32 {
            for ca in stride(from: 0, through: 31, by: 3) {
                for cb in stride(from: 0, through: 31, by: 5) {
                    let want = UInt16((ca * a + cb * (32 - a)) / 32)
                    let out = Blend555.blend(rgb(UInt16(ca), UInt16(cb), UInt16(ca)),
                                             rgb(UInt16(cb), UInt16(ca), UInt16(cb)), a: a)
                    XCTAssertEqual((out >> 10) & 31, want)
                    XCTAssertEqual(out & 31, want)
                    XCTAssertEqual((out >> 5) & 31, UInt16((cb * a + ca * (32 - a)) / 32))
                }
            }
        }
        // The buffer form. FUN_1001e9d0 shrinks w × h to the rect clipped by the dst bounds but starts all three
        // buffers at the UNCLIPPED top/left (`1001eac8/ead8`, `1001eb0c/eb14`, `1001eb44/eb48`: base + top·rowBytes
        // + 2·left), stepping rowBytes − 2w per row. So a rect hanging off the top/left lands earlier in linear
        // memory; the replica walks the same linear indices and drops those outside the buffer.
        let a = pattern(width: 6, height: 5, seed: 1)
        let b = pattern(width: 6, height: 5, seed: 2)
        func blended(_ rect: MacRect) -> Pixmap555 {
            var d = Pixmap555(width: 6, height: 5)
            Blend555.blend(a, b, into: &d, rect: rect, a: 12)
            return d
        }
        func check(_ d: Pixmap555, written: (Int, Int) -> Bool, _ what: String) {
            for y in 0..<5 {
                for x in 0..<6 {
                    XCTAssertEqual(d[x, y], written(x, y) ? Blend555.blend(a[x, y], b[x, y], a: 12) : 0,
                                   "\(what) (\(x),\(y))")
                }
            }
        }
        // Off the top: clipped w 3 (x 3…5), h 3 (y 0…2); start index −2·6 + 3 = −9 → rows at −9, −3 (outside), 3 →
        // only (3…5, 0) is written.
        check(blended(MacRect(top: -2, left: 3, bottom: 3, right: 9)), written: { x, y in y == 0 && x >= 3 }, "top")
        // Off the left: clipped w 2, h 2; start 1·6 − 2 = 4 → (4…5, 0) and (4…5, 1), not (0…1, 1…2).
        check(blended(MacRect(top: 1, left: -2, bottom: 3, right: 2)),
              written: { x, y in x >= 4 && (y == 0 || y == 1) }, "left")
        // Off the right/bottom only: the start is inside, so this is the plain clipped rect.
        check(blended(MacRect(top: 3, left: 4, bottom: 9, right: 9)), written: { x, y in x >= 4 && y >= 3 }, "right")
    }

    // FUN_10009fd0: src rect nil → src bounds; dst rect nil → the SRC bounds (dst's never consulted);
    // the second identical srcCopy is a no-op.
    func testCopyBitsRectDefaults() {
        var src = pattern(width: 4, height: 3)
        var dst = Pixmap555(width: 8, height: 6)
        XCTAssertEqual(dst.pixels, [UInt16](repeating: 0, count: 48), "buffers are black at creation")
        CopyBits.copyBuffer(from: &src, to: &dst, srcRect: nil, dstRect: nil, interlaced: false)
        for y in 0..<6 {
            for x in 0..<8 {
                XCTAssertEqual(dst[x, y], (x < 4 && y < 3) ? src[x, y] : 0, "(\(x),\(y))")
            }
        }
        // srcRect nil, dstRect given (same size as the src bounds).
        var dst2 = Pixmap555(width: 8, height: 6)
        CopyBits.copyBuffer(from: &src, to: &dst2, srcRect: nil,
                            dstRect: MacRect(top: 2, left: 3, bottom: 5, right: 7), interlaced: false)
        for y in 0..<6 {
            for x in 0..<8 {
                let inside = (3..<7).contains(x) && (2..<5).contains(y)
                XCTAssertEqual(dst2[x, y], inside ? src[x - 3, y - 2] : 0, "(\(x),\(y))")
            }
        }
        // Both rects given; the dst rect hangs off the dst's right/bottom edge → clipped.
        var dst3 = Pixmap555(width: 8, height: 6)
        CopyBits.copyBuffer(from: &src, to: &dst3, srcRect: MacRect(top: 1, left: 1, bottom: 3, right: 4),
                            dstRect: MacRect(top: 5, left: 6, bottom: 7, right: 9), interlaced: false)
        for y in 0..<6 {
            for x in 0..<8 {
                let inside = (6..<8).contains(x) && y == 5
                XCTAssertEqual(dst3[x, y], inside ? src[x - 5, y - 4] : 0, "(\(x),\(y))")
            }
        }
        // The original's second identical CopyBits changes nothing.
        let once = dst3
        CopyBits.copyBuffer(from: &src, to: &dst3, srcRect: MacRect(top: 1, left: 1, bottom: 3, right: 4),
                            dstRect: MacRect(top: 5, left: 6, bottom: 7, right: 9), interlaced: false)
        XCTAssertEqual(dst3, once)
        XCTAssertEqual(src.interlaceParity, 0, "a plain copy never touches the parity")
        // fill (FUN_10009f00, PaintRect portRect).
        var f = Pixmap555(width: 3, height: 2)
        f.fill(0x1234)
        XCTAssertEqual(f.pixels, [UInt16](repeating: 0x1234, count: 6))
        XCTAssertEqual(f.bounds, MacRect(top: 0, left: 0, bottom: 2, right: 3))
    }

    // FUN_100450e0: rows rt + p, rt + p + 2, … of the rect (p = the src buffer's parity, +0x2c); parity ^= 1.
    // (12 rows: the rects stay clear of the halved-bounds clip pinned in testInterlacedCopyClipsLastFieldRow.)
    func testInterlacedCopyParity() {
        var src = pattern(width: 5, height: 12)
        var dst = Pixmap555(width: 5, height: 12)
        dst.fill(0x7C00)
        let sr = MacRect(top: 1, left: 0, bottom: 8, right: 5)   // 7 rows: 1…7
        let dr = MacRect(top: 2, left: 0, bottom: 9, right: 5)   // 7 rows: 2…8
        CopyBits.copyBuffer(from: &src, to: &dst, srcRect: sr, dstRect: dr, interlaced: true)
        XCTAssertEqual(src.interlaceParity, 1)
        XCTAssertEqual(dst.interlaceParity, 0, "only the src buffer's parity toggles")
        // Even parity: rect rows 0, 2, 4, 6 (h 7 odd → (7+1)/2 = 4 rows).
        for y in 0..<9 {
            let k = y - 2
            let copied = k >= 0 && k < 7 && k % 2 == 0
            for x in 0..<5 {
                XCTAssertEqual(dst[x, y], copied ? src[x, 1 + k] : 0x7C00, "even pass (\(x),\(y))")
            }
        }
        // Odd parity: rect rows 1, 3, 5 (h 7 odd → (7−1)/2 = 3 rows); together the two passes cover the rect.
        CopyBits.copyBuffer(from: &src, to: &dst, srcRect: sr, dstRect: dr, interlaced: true)
        XCTAssertEqual(src.interlaceParity, 0)
        for y in 0..<9 {
            let k = y - 2
            for x in 0..<5 {
                XCTAssertEqual(dst[x, y], (k >= 0 && k < 7) ? src[x, 1 + k] : 0x7C00, "both passes (\(x),\(y))")
            }
        }
        // Odd parity on a fresh dst copies only the odd rect rows.
        var dst2 = Pixmap555(width: 5, height: 12)
        src.interlaceParity = 1
        CopyBits.copyBuffer(from: &src, to: &dst2, srcRect: sr, dstRect: dr, interlaced: true)
        for y in 0..<9 {
            let k = y - 2
            let copied = k >= 0 && k < 7 && k % 2 == 1
            XCTAssertEqual(dst2[0, y], copied ? src[0, 1 + k] : 0, "odd pass row \(y)")
        }
    }

    // FUN_100450e0's halving: both bitmaps get top/bottom − 2 (`100453ac`, `100453c0`, `100453d8`, `100453e0`),
    // then bounds and rects are halved (`srawi`, `1004550c…100455dc`) with the rowBytes doubled. A 480-row buffer's
    // halved bounds are [−1, 239) while the full rect halves to [0, 240), so CopyBits clips the last field row: row 478
    // on an even pass, 479 on an odd one. Halved row Y addresses original row 2Y + parity − (rect.top & 1).
    func testInterlacedCopyClipsLastFieldRow() {
        var src = pattern(width: 4, height: 480, seed: 5)
        var dst = Pixmap555(width: 4, height: 480)
        dst.fill(0x7C00)
        CopyBits.copyBuffer(from: &src, to: &dst, srcRect: nil, dstRect: nil, interlaced: true)   // parity 0
        for y in 0..<480 {
            let copied = y % 2 == 0 && y < 478
            XCTAssertEqual(dst[1, y], copied ? src[1, y] : 0x7C00, "even pass row \(y)")
        }
        CopyBits.copyBuffer(from: &src, to: &dst, srcRect: nil, dstRect: nil, interlaced: true)   // parity 1
        for y in 0..<480 {
            XCTAssertEqual(dst[2, y], y < 478 ? src[2, y] : 0x7C00, "both passes row \(y)")
        }
        XCTAssertEqual(src.interlaceParity, 0)
        // A 9-row buffer: halved bounds [−1, 3) → only halved rows 1 and 2 survive. src rect rows 1…7 (top odd),
        // dst rect rows 2…8. Even pass (h 7 padded to 8): src Y 1…4 → rows 1, 3, (5, 7 clipped); dst rows 2, 4.
        // Odd pass (h 7 trimmed to 6): src Y 1…3 → rows 2, 4, (6 clipped); dst rows 3, 5.
        var s9 = pattern(width: 3, height: 9, seed: 6)
        var d9 = Pixmap555(width: 3, height: 9)
        d9.fill(0x7C00)
        let sr = MacRect(top: 1, left: 0, bottom: 8, right: 3), dr = MacRect(top: 2, left: 0, bottom: 9, right: 3)
        CopyBits.copyBuffer(from: &s9, to: &d9, srcRect: sr, dstRect: dr, interlaced: true)
        let evenRows: [Int: Int] = [2: 1, 4: 3]                 // dst row ← src row
        for y in 0..<9 { XCTAssertEqual(d9[0, y], evenRows[y].map { s9[0, $0] } ?? 0x7C00, "9-row even \(y)") }
        d9.fill(0x7C00)
        CopyBits.copyBuffer(from: &s9, to: &d9, srcRect: sr, dstRect: dr, interlaced: true)
        let oddRows: [Int: Int] = [3: 2, 5: 4]
        for y in 0..<9 { XCTAssertEqual(d9[0, y], oddRows[y].map { s9[0, $0] } ?? 0x7C00, "9-row odd \(y)") }
    }

    // FUN_10009fd0 between two buffers of ONE DisplayBuffers (R3's terrain → back): no overlapping inout access
    // (dynamic exclusivity), the src parity still toggles, the dst gets the pixels.
    func testCopyBufferBetweenDisplayBuffers() {
        final class Owner { var buffers = DisplayBuffers() }
        let owner = Owner()
        owner.buffers.terrain = pattern(width: 640, height: 480, seed: 8)
        owner.buffers.copyBuffer(from: .terrain, to: .back, srcRect: nil, dstRect: nil, interlaced: false)
        XCTAssertEqual(owner.buffers.back.pixels, owner.buffers.terrain.pixels)
        XCTAssertEqual(owner.buffers.terrain.interlaceParity, 0)
        owner.buffers.back.fill(0)
        owner.buffers.copyBuffer(from: .terrain, to: .back, srcRect: nil, dstRect: nil, interlaced: true)
        XCTAssertEqual(owner.buffers.terrain.interlaceParity, 1, "the src buffer's parity is written back")
        XCTAssertEqual(owner.buffers.back.interlaceParity, 0)
        XCTAssertEqual(owner.buffers.back[7, 10], owner.buffers.terrain[7, 10])
        XCTAssertEqual(owner.buffers.back[7, 11], 0)
        // Same buffer as src and dst: a no-op on the pixels; the parity toggles once.
        let before = owner.buffers.back.pixels
        owner.buffers.copyBuffer(from: .back, to: .back, srcRect: nil, dstRect: nil, interlaced: true)
        XCTAssertEqual(owner.buffers.back.pixels, before)
        XCTAssertEqual(owner.buffers.back.interlaceParity, 1)
    }

    private func screenAndBack() -> (screen: Pixmap555, back: Pixmap555) {
        var screen = Pixmap555(width: 640, height: 480)
        screen.fill(0x7FFF)                   // so untouched / painted pixels are visible
        return (screen, pattern(width: 640, height: 480, seed: 3))
    }

    // FUN_1000beb0: paint (0,0,480,32) and (0,608,480,640) black; back (0,0,480,416) → (0,32,480,448);
    // back (0,416,480,576) → (0,448,480,608).
    func testGameScreenPresent() {
        let (blank, back) = screenAndBack()
        var screen = blank
        Presents.present(.gameScreen, back: back, screen: &screen)
        for y in stride(from: 0, to: 480, by: 7) {
            for x in 0..<640 {
                let want: UInt16
                switch x {
                case 0..<32, 608..<640: want = 0
                case 32..<448: want = back[x - 32, y]
                default: want = back[x - 32, y]            // 448..<608 ← back 416..<576
                }
                XCTAssertEqual(screen[x, y], want, "(\(x),\(y))")
            }
        }
        XCTAssertEqual(screen[447, 479], back[415, 479])
        XCTAssertEqual(screen[448, 0], back[416, 0])
        XCTAssertEqual(screen[607, 479], back[575, 479])
    }

    // FUN_1000bd80: back (0,0,480,608) → screen (0,32,480,640); screen x 0…31 untouched, nothing painted.
    func testGameLayoutPresent() {
        let (blank, back) = screenAndBack()
        var screen = blank
        Presents.present(.gameLayout, back: back, screen: &screen)
        for y in stride(from: 0, to: 480, by: 5) {
            for x in 0..<640 {
                XCTAssertEqual(screen[x, y], x < 32 ? 0x7FFF : back[x - 32, y], "(\(x),\(y))")
            }
        }
        // FUN_1000bc60: full screen, 1:1.
        let (blank2, back2) = screenAndBack()
        var screen2 = blank2
        Presents.present(.fullScreen, back: back2, screen: &screen2)
        XCTAssertEqual(screen2, back2)
    }

    // FUN_1000ba70: snapshot of back + a black clone; for a = 0, 4, …, 32: back = blend(snapshot, black, a), present.
    func testFadeFromBlackSteps() {
        XCTAssertEqual(DisplayBuffers.fromBlackLevels, [0, 4, 8, 12, 16, 20, 24, 28, 32])
        var d = DisplayBuffers()
        XCTAssertEqual(d.back.width, 640); XCTAssertEqual(d.back.height, 480)
        XCTAssertEqual(d.terrain.width, 640); XCTAssertEqual(d.terrain.height, 480)
        XCTAssertEqual(d.scoreSave.width, 160); XCTAssertEqual(d.scoreSave.height, 480)
        XCTAssertEqual(d.screen.width, 640); XCTAssertEqual(d.screen.height, 480)
        for id in [BufferID.back, .terrain, .scoreSave] {
            XCTAssertTrue(d.buffer(id).pixels.allSatisfy { $0 == 0 }, "\(id) black at creation")
        }
        d.back = pattern(width: 640, height: 480, seed: 9)
        let snapshot = d.back
        d.fadeBegin(.fromBlack)
        var screens: [Pixmap555] = []
        for a in DisplayBuffers.fromBlackLevels {
            d.fadeStep(.fromBlack, a: a, present: .fullScreen)
            screens.append(d.screen)
            for (i, p) in d.back.pixels.enumerated() where i % 97 == 0 {
                let s = snapshot.pixels[i]
                let want = (((s >> 10) & 31) * UInt16(a) / 32) << 10
                    | (((s >> 5) & 31) * UInt16(a) / 32) << 5
                    | ((s & 31) * UInt16(a) / 32)
                XCTAssertEqual(p, want, "a \(a) pixel \(i)")
            }
        }
        d.fadeEnd()
        XCTAssertEqual(screens.count, 9)
        XCTAssertTrue(screens[0].pixels.allSatisfy { $0 == 0 }, "step a = 0 is black")
        XCTAssertEqual(screens[8], snapshot, "step a = 32 equals the snapshot")
        XCTAssertEqual(d.back, snapshot, "the back buffer ends as the snapshot")
        // Mid step a = 16 on a known pixel: ⌊c·16/32⌋.
        XCTAssertEqual(Blend555.blend(0x7FFF, 0, a: 16), 0x3DEF)
        // The fade presents through the named present (game layout leaves x 0…31 alone).
        var g = DisplayBuffers()
        g.screen.fill(0x7FFF)
        g.back = snapshot
        g.fadeBegin(.fromBlack)
        g.fadeStep(.fromBlack, a: 0, present: .gameLayout)
        XCTAssertEqual(g.screen[0, 0], 0x7FFF)
        XCTAssertEqual(g.screen[32, 0], 0)
        g.fadeEnd()
    }

    // Per channel (c << 3) | (c >> 2), alpha 0xFF, 0xAARRGGBB, row 0 top.
    func testRGBAConversion() {
        var p = Pixmap555(width: 3, height: 2)
        p[0, 0] = 0x4B7C
        p[1, 0] = 0x7FFF
        p[2, 0] = 0x0000
        p[0, 1] = 0x7C00
        p[1, 1] = 0x03E0
        p[2, 1] = 0x801F             // bit 15 ignored
        var out = [UInt32](repeating: 0xDEADBEEF, count: 6)
        out.withUnsafeMutableBufferPointer { ScreenRGBA.convert(p, into: $0.baseAddress!) }
        XCTAssertEqual(out, [0xFF94DEE7, 0xFFFFFFFF, 0xFF000000, 0xFFFF0000, 0xFF00FF00, 0xFF0000FF])
    }
}
