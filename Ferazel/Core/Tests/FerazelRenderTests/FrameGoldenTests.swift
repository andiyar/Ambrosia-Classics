import XCTest
import FerazelCore
@testable import FerazelRender
#if canImport(ImageIO)
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
#endif

/// R6 (docs/plans/2026-10-06-ferazel-phase1.md): `FrameRenderer` executing R5's `FrameOps` as `FerazelSession.step`
/// emits them, the Game Screen frame (PICT 129), CLUT → RGBA, and the level-1 frame goldens. Every golden is a
/// self-derived measurement (FNV-1a 64 of the 640×480 indices), recorded in D26. `FERAZEL_PNG_OUT` (a directory)
/// makes the golden tests write their frames as PNGs (ImageIO, test-only). A missing data file is a FAILURE.
final class FrameGoldenTests: XCTestCase {

    nonisolated(unsafe) private static let resources = Result { try FerazelData.open(try FerazelData.dataDirectory()) }

    private func renderer(prefs: FerazelPrefs = FerazelPrefs(),
                          tieBreak: ColorSearch.TieBreak = .lowest) throws -> FrameRenderer {
        try FrameRenderer(resources: try Self.resources.get(), level: 1,
                          search: ColorSearch(model: .ruled, tieBreak: tieBreak),
                          dither: .errorDiffusion, text: StatusBarTests.BoxRasterizer(), prefs: prefs)
    }

    /// The level's session, its Setup lights handed to the renderer (one source: `FerazelSession.lights`).
    private func session(_ renderer: FrameRenderer, prefs: FerazelPrefs = FerazelPrefs()) throws -> FerazelSession {
        let s = try FerazelSession(resources: try Self.resources.get(), prefs: prefs, level: 1,
                                   faceBounds: renderer.faceBounds)
        try renderer.addLights(s.lights)
        return s
    }

    /// `.HandleLights` ran over every Setup light: not new, the previous fields = the current ones, so the next
    /// `.DrawLightsOntoTiles` finds no changed cell.
    private func assertLightsHandled(_ r: FrameRenderer, h: Int, v: Int, line: UInt = #line) {
        let active = r.lights.slots.filter(\.active)
        XCTAssertEqual(active.count, 68, line: line)
        for l in active {
            XCTAssertFalse(l.isNew, line: line)
            XCTAssertEqual(l.previousFace, l.face, line: line)
            XCTAssertEqual([l.previousX, l.previousY, l.previousRadius, l.previousColour],
                           [l.x, l.y, l.radius, l.colour], line: line)
        }
        XCTAssertFalse(r.lights.calcLightOps(h: h, v: v).contains(where: \.changed), line: line)
    }

    private func fnv1a(_ bytes: [UInt8]) -> UInt64 {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for b in bytes { h = (h ^ UInt64(b)) &* 0x0000_0100_0000_01b3 }
        return h
    }

    private func hex(_ v: UInt64) -> String { String(v, radix: 16) }

    /// The frame as a PNG in `$FERAZEL_PNG_OUT/name.png` when the variable is set.
    private func dump(_ r: FrameRenderer, _ name: String) {
        #if canImport(ImageIO)
        guard let dir = ProcessInfo.processInfo.environment["FERAZEL_PNG_OUT"], !dir.isEmpty else { return }
        let words = r.screen.rgba(through: r.screenClut)
        var bytes = [UInt8](); bytes.reserveCapacity(words.count * 4)
        for w in words { bytes += [UInt8(w >> 16 & 0xff), UInt8(w >> 8 & 0xff), UInt8(w & 0xff), 0xff] }
        let w = IndexedFrame.width, h = IndexedFrame.height
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let image = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        else { return XCTFail("PNG: CGImage") }
        let url = URL(fileURLWithPath: dir).appendingPathComponent("\(name).png")
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { return XCTFail("PNG: \(url.path)") }
        CGImageDestinationAddImage(dest, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(dest), "PNG: \(url.path)")
        #endif
    }

    func testIndexedFrameToRGBA() throws {
        let c202 = try ColorLUT.load(id: 202, from: try Self.resources.get(), chain: .level)
        var f = IndexedFrame(fill: 0)
        f[1, 0] = 0xff
        f[0, 1] = 1
        f[639, 479] = 0xff
        let rgba = f.rgba(through: c202)
        XCTAssertEqual(rgba.count, 640 * 480)
        XCTAssertEqual(rgba[0], 0xFFFF_FFFF)                    // entry 0: white
        XCTAssertEqual(rgba[1], 0xFF00_0000)                    // entry 0xff: black
        XCTAssertEqual(rgba[640], 0xFFFF_FF7F)                  // row 1 (row 0 on top): entry 1 = (FFFF, FFFF, 7F7F)
        XCTAssertEqual(rgba[640 * 480 - 1], 0xFF00_0000)
        // The renderer presents through the current screen CLUT, which `.SetScreenClut` sets.
        let r = try renderer()
        try r.apply(FrameOps(draws: [.setScreenClut(id: 202)]))
        XCTAssertEqual(r.screenClut, c202)
        XCTAssertEqual(r.screenClut.entries.map(\.value), (0..<256).map(UInt16.init))
    }

    func testGameScreenFrame129() throws {
        let res = try Self.resources.get()
        let c202 = try ColorLUT.load(id: 202, from: res, chain: .level)
        let search = ColorSearch(model: .ruled)
        let source = try PictureSource.load(id: 129, from: res, chain: .frontEnd)
        guard case .indexed(let p) = source.pixels else { return XCTFail("PICT 129 is indexed") }
        XCTAssertEqual([p.depth, p.width, p.height], [4, 640, 480])
        // Its own 4-bit table searched in the level CLUT (the back screen, `.DrawPICTToBackScreen`), then
        // `.MTRedraw`'s copy to the window (Color2Index of each 202 colour in 202).
        let converted = try ConvertedPicture(source: source, clut: c202, search: search)
        let redraw = c202.entries.map { search.index(of: RGB16($0.red, $0.green, $0.blue), in: c202) }
        let expected = converted.pixels.map { redraw[Int($0)] }
        let r = try renderer()
        try r.apply(FrameOps(draws: [.setScreenClut(id: 202), .drawPicture(id: 129, chain: .frontEnd, h: 0, v: 0)]))
        XCTAssertEqual(r.screen.pixels, expected)
        // PICT 129 converts to canonical indices under every model, so the `.MTRedraw` translation shows only on
        // indices with an earlier duplicate in 202: 7 → 3, 79 → 78, 160 / 254 / 255 → 96 (black), clipped at the edge.
        let dupes = try ConvertedPicture(id: 9, width: 5, height: 1, pixels: [7, 79, 160, 255, 1], clutId: 202)
        r.redrawToWindow(dupes, h: 637, v: 479)
        XCTAssertEqual([r.screen[637, 479], r.screen[638, 479], r.screen[639, 479]], [3, 78, 96])
        r.redrawToWindow(dupes, h: 0, v: 0)
        XCTAssertEqual((0..<5).map { r.screen[$0, 0] }, [3, 78, 96, 96, 1])
        try r.apply(FrameOps(draws: [.drawPicture(id: 129, chain: .frontEnd, h: 0, v: 0)]))
        XCTAssertEqual(r.screen.pixels, expected)
        XCTAssertThrowsError(try r.apply(FrameOps(draws: [.setScreenClut(id: 201)]))) {
            XCTAssertEqual($0 as? FrameRenderer.Refusal, .screenClut(201, tablesBuiltFor: 202))
        }
        // The view (16, 8)–(624, 392) is left for `.WrapCopyToScreen`: after the first step only it and the status bar
        // (y ≥ 392) changed; the frame strips are PICT 129's.
        let s = try session(r)
        try r.apply(s.step(keys: KeyState()))
        for y in 0..<392 { for x in 0..<640 where !((16..<624).contains(x) && (8..<392).contains(y)) {
            XCTAssertEqual(r.screen[x, y], expected[y * 640 + x], "frame (\(x), \(y))")
        } }
        let view = (8..<392).flatMap { y in (16..<624).map { x in (r.screen[x, y], expected[y * 640 + x]) } }
        XCTAssertGreaterThan(view.filter { $0.0 != $0.1 }.count, 0)
    }

    func testFirstFrameOpsOrder() throws {
        // Step 1 as executed: the level start, then one `.PaintFrameWrap` (`.HandleLights` runs before the sprites,
        // l. 9205), the copy, the erase, and the per-frame status bar (nothing changed → nothing drawn).
        let r = try renderer()
        let s = try session(r)
        let ops = s.step(keys: KeyState())
        try r.apply(ops)
        let sprites = ops.draws.compactMap { if case .wrapDrawSprites(let d) = $0 { d.count } else { nil } }.first ?? -1
        let erased = ops.draws.compactMap { if case .wrapEraseSprites(let e, _, _) = $0 { e.count } else { nil } }.first ?? -1
        XCTAssertEqual(r.executed, [
            .screenClut(202), .picture(129), .entireGrid(h: 0, v: 0), .strip(h: 0, v: 0), .entireGrid(h: 0, v: 0),
            .statusBar(full: true),
            .strip(h: 0, v: 0), .lightsOntoTiles, .handleLights, .sprites(sprites), .copy(h: 0, v: 0),
            .erase(erased), .statusBar(full: false),
        ])
        XCTAssertEqual(r.lights.slots.filter(\.active).count, 68)          // the level-1 Setup lights (Effects 1)
        XCTAssertFalse(r.lights.slots.contains { $0.active && $0.isNew })   // `.HandleLights` cleared `+1`
        // "Reduce frame rate": the first iteration skips only the copy; the screen keeps the level-start frame there.
        var reduce = FerazelPrefs()
        reduce.reduceFrameRate = 1
        let rr = try renderer(prefs: reduce)
        let rs = try session(rr, prefs: reduce)
        let skipped = rs.step(keys: KeyState())
        XCTAssertFalse(skipped.drawn)
        try rr.apply(skipped)
        XCTAssertEqual(rr.executed.filter { if case .copy = $0 { true } else { false } }, [])
        XCTAssertEqual(rr.executed.count, r.executed.count - 1)
        try rr.apply(rs.step(keys: KeyState()))
        XCTAssertEqual(rr.executed.filter { if case .copy = $0 { true } else { false } }.count, 1)
    }

    func testFirstFrameGoldenLevel1() throws {
        let r = try renderer()
        let s = try session(r)
        let ops = s.step(keys: KeyState())
        XCTAssertEqual([s.camera.scrollH, s.camera.scrollV], [0, 0])    // R5: level 1 opens at (0, 0) and pans in
        try r.apply(ops)
        assertLightsHandled(r, h: 0, v: 0)
        dump(r, "level1-frame1")
        // Measured 2026-10-10 (R6): the level start + iteration 1 at scroll (0, 0), `.ruled`, error diffusion, the 68
        // Setup lights at Effects 1, the box rasterizer. The player is not drawn yet (his face is set by the Handle,
        // after the draw — R5).
        XCTAssertEqual(hex(fnv1a(r.screen.pixels)), "9db8f32f7e3d88b4")
    }

    func testFirstFrameGoldenLevel1HighestTieBreak() throws {
        // Ben, 2026-10-07 (D26): the duplicate-colour tie-break `.highest` (FG 200's blacks → 255, black in clut
        // 202 too) beside the default above. The scroll and lights are the default frame's.
        let r = try renderer(tieBreak: .highest)
        let s = try session(r)
        let ops = s.step(keys: KeyState())
        XCTAssertEqual([s.camera.scrollH, s.camera.scrollV], [0, 0])
        try r.apply(ops)
        assertLightsHandled(r, h: 0, v: 0)
        dump(r, "level1-frame1-highest")
        // Measured 2026-10-10 (A1): as the default frame 1 but `.highest`.
        XCTAssertEqual(hex(fnv1a(r.screen.pixels)), "9b512587ae1dd08b")
    }

    func testPanFrameGoldens() throws {
        // 60 frames with the right arrow held (the ◇ focus driver), after the first frame.
        let r = try renderer()
        let s = try session(r)
        try r.apply(s.step(keys: KeyState()))
        assertLightsHandled(r, h: 0, v: 0)
        let right = KeyState(pressed: [CameraFocusDriver.arrowRight])
        var chain: [UInt64] = []
        var scrolls: [[Int]] = []
        for _ in 0..<60 {
            try r.apply(s.step(keys: right))
            chain.append(fnv1a(r.screen.pixels))
            scrolls.append([s.camera.scrollH, s.camera.scrollV])
        }
        dump(r, "level1-pan60")
        assertLightsHandled(r, h: scrolls[59][0], v: scrolls[59][1])
        // Measured 2026-10-10 (R6): frames 30 and 60 of the hold (iterations 31 and 61), and the FNV-1a of the 60
        // frame hashes (little-endian bytes). The pan-in has v settled at 10; h starts to move once the eased pair
        // passes 0.
        XCTAssertEqual(scrolls[29], [4, 10])
        XCTAssertEqual(scrolls[59], [226, 10])
        XCTAssertEqual(hex(chain[29]), "f6296c7e706130f3")
        XCTAssertEqual(hex(chain[59]), "e7a951e3eafca30a")
        XCTAssertEqual(hex(fnv1a(chain.flatMap { v in (0..<8).map { UInt8(v >> (8 * $0) & 0xff) } })), "3c5aee2b87819db6")
    }
}
