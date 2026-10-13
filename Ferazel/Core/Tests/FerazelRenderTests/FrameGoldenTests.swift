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

    /// The level's session, its Setup lights and `.BuildTintTable` draws handed to the renderer (one source each:
    /// `FerazelSession.lights`, `FerazelSession.tintTableDraws` — the session's one stream).
    private func session(_ renderer: FrameRenderer, prefs: FerazelPrefs = FerazelPrefs()) throws -> FerazelSession {
        let s = try FerazelSession(resources: try Self.resources.get(), prefs: prefs, level: 1,
                                   faceBounds: renderer.faceBounds)
        try renderer.addLights(s.lights)
        try renderer.buildTintTable(s.tintTableDraws)
        return s
    }

    /// `.HandleLights` ran over every Setup light: not new, the previous fields = the current ones, so the next
    /// `.DrawLightsOntoTiles` finds no changed cell — except the slots in `reFaced`, which a Handle re-faced after the
    /// draw (`.HandleBonusSprite`'s twinkle, `.ChangeLightFace`): their drawn face is `drawn`, the current one `now`
    /// (radius unchanged, 72×72 faces), and exactly the op cells listing one of them are flagged changed.
    private func assertLightsHandled(_ r: FrameRenderer, h: Int, v: Int, reFaced: [Int: (drawn: Int16, now: Int16)] = [:],
                                     line: UInt = #line) {
        let active = r.lights.slots.enumerated().filter { $0.element.active }
        XCTAssertEqual(active.count, 68, line: line)
        for (i, l) in active {
            XCTAssertFalse(l.isNew, line: line)
            if let f = reFaced[i] {
                XCTAssertEqual(l.previousFace?.pict, f.drawn, "slot \(i)", line: line)
                XCTAssertEqual(l.face?.pict, f.now, "slot \(i)", line: line)
            } else {
                XCTAssertEqual(l.previousFace, l.face, "slot \(i)", line: line)
            }
            XCTAssertEqual([l.previousX, l.previousY, l.previousRadius, l.previousColour],
                           [l.x, l.y, l.radius, l.colour], line: line)
        }
        for op in r.lights.calcLightOps(h: h, v: v) {
            XCTAssertEqual(op.changed, !Set(op.lights).isDisjoint(with: reFaced.keys), "cell \(op.col),\(op.row)",
                           line: line)
        }
    }

    /// Light 24 (the potion 0xc84) after step 1 under seed 1: the Setup's `+0x46 = FastRand(0x10)` = 6, the twinkle
    /// makes it 7 → k = (7 >> 2) mod 6 = 1 → 0x32b, after the draw that used the Setup face 0x32a.
    private static let potionStep1: [Int: (drawn: Int16, now: Int16)] = [24: (0x32a, 0x32b)]

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
        // The renderer presents through the current screen CLUT, which `.SetScreenClut` sets. Before the session's
        // `.BuildTintTable` draws are handed over it refuses to run (E2 review: table 0xa must not stay zero).
        let r = try renderer()
        XCTAssertThrowsError(try r.apply(FrameOps(draws: [.setScreenClut(id: 202)]))) {
            XCTAssertEqual($0 as? FrameRenderer.Refusal, .tintTableNotBuilt)
        }
        XCTAssertFalse(r.tintTableBuilt)
        _ = try session(r)
        XCTAssertTrue(r.tintTableBuilt)
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
        let s = try session(r)
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
        try r.apply(s.step(keys: KeyState()))
        for y in 0..<392 { for x in 0..<640 where !((16..<624).contains(x) && (8..<392).contains(y)) {
            XCTAssertEqual(r.screen[x, y], expected[y * 640 + x], "frame (\(x), \(y))")
        } }
        let view = (8..<392).flatMap { y in (16..<624).map { x in (r.screen[x, y], expected[y * 640 + x]) } }
        XCTAssertGreaterThan(view.filter { $0.0 != $0.1 }.count, 0)
    }

    func testFirstFrameOpsOrder() throws {
        // Step 1 as executed: the level start, then one `.PaintFrameWrap` (`.HandleLights` runs before the water
        // effects and the sprites, l. 9205–9207), the copy, the erase, and the per-frame status bar (nothing changed →
        // nothing drawn).
        let r = try renderer()
        let s = try session(r)
        let ops = s.step(keys: KeyState())
        try r.apply(ops)
        let sprites = ops.draws.compactMap { if case .wrapDrawSprites(let d) = $0 { d.count } else { nil } }.first ?? -1
        let erased = ops.draws.compactMap { if case .wrapEraseSprites(let e, _, _) = $0 { e.count } else { nil } }.first ?? -1
        XCTAssertEqual(r.executed, [
            .screenClut(202), .picture(129), .entireGrid(h: 0, v: 0), .strip(h: 0, v: 0), .entireGrid(h: 0, v: 0),
            .statusBar(full: true),
            .strip(h: 0, v: 0), .lightsOntoTiles, .handleLights, .waterEffects(0), .sprites(sprites), .particles(0),
            .copy(h: 0, v: 0), .eraseParticles, .lightFace(24), .erase(erased), .statusBar(full: false),
        ])
        XCTAssertEqual(r.lights.slots.filter(\.active).count, 68)          // the level-1 Setup lights (Effects 1)
        // The ripple phase `*_DAT_1009fd74`: 0x200 at level start (l. 5217), + 0x100 after the erase (`100127ec..f4`).
        XCTAssertEqual(r.sprites.ripplePhase, 0x300)
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
        XCTAssertEqual(rr.executed.count, r.executed.count - 3)              // no copy, no particle draw or erase
        XCTAssertEqual(rr.sprites.ripplePhase, 0x300)                     // a skipped iteration still erases
        try rr.apply(rs.step(keys: KeyState()))
        XCTAssertEqual(rr.executed.filter { if case .copy = $0 { true } else { false } }.count, 1)
        XCTAssertEqual(rr.sprites.ripplePhase, 0x400)
    }

    func testFirstFrameGoldenLevel1() throws {
        let r = try renderer()
        let s = try session(r)
        let ops = s.step(keys: KeyState())
        XCTAssertEqual([s.camera.scrollH, s.camera.scrollV], [0, 0])    // R5: level 1 opens at (0, 0) and pans in
        // E2 Part A: tint table 0xa from the session's 510 `.BuildTintTable` draws (B, R per entry 0..0xfe), the
        // other tables untouched; no level-1 sprite draws mode 1 sub 0xa, so the frame hash does not see it.
        let c202 = try ColorLUT.load(id: 202, from: try Self.resources.get(), chain: .level)
        var d = s.tintTableDraws.makeIterator()
        let requested = TableRequests.tint(0xa, clut: c202) { _ in UInt16(d.next()!) }
        XCTAssertEqual(Array(r.tables.tint[0xa].prefix(0xff)),
                       r.search.indices(of: requested.prefix(0xff).compactMap(\.request), in: c202))
        XCTAssertEqual(r.tables.tint[0xa][0xff], 0xff)
        XCTAssertEqual(r.sprites.tables, r.tables)
        XCTAssertThrowsError(try r.buildTintTable([])) {
            XCTAssertEqual($0 as? FrameRenderer.Refusal, .tintTableDraws(0))
        }
        try r.apply(ops)
        assertLightsHandled(r, h: 0, v: 0, reFaced: Self.potionStep1)
        dump(r, "level1-frame1")
        // Measured 2026-10-10 (R6): the level start + iteration 1 at scroll (0, 0), `.ruled`, error diffusion, the 68
        // Setup lights at Effects 1, the box rasterizer. The player is not drawn yet (his face is set by the Handle,
        // after the draw — R5).
        XCTAssertEqual(hex(fnv1a(r.screen.pixels)), "9db8f32f7e3d88b4")

        // E1b: the Enhanced water-face draw (`WaterFaceBlitter`, raw `10011464..100114e4`). No liquid shows in any
        // level-1 golden frame (the window is rows 0…13; the first pools are on rows 19–20), so the op is applied
        // here: cell (3, 0) (FG tile t, the cell `ParticleTests.testWaterFaceParity` finds), liquid kind 1, at the
        // frame-1 scroll (0, 0) — FG-water face t through mode 0x60001 (the ripple, water table 1, the mask twin),
        // then the light with water row 1. Only the cell's rows change, within its columns ± the ripple; the
        // kind picks the table; the ports are pinned.
        let before = r.ports
        let t = Int16(r.level.fgTile(col: 3, row: 0))
        let draw = WaterFaceDraw(cellX: 3, cellY: 0, tile: t, waterKind: 1)
        try r.apply(FrameOps(draws: [.wrapDrawWaterEffects([draw])]))
        XCTAssertEqual(r.executed, [.handleLights, .waterEffects(1)])
        let w = FramePorts.width
        let changed = r.ports.frame.indices.filter { r.ports.frame[$0] != before.frame[$0] }
        let masked = r.ports.mask.indices.filter { r.ports.mask[$0] != before.mask[$0] }
        XCTAssertGreaterThan(changed.count, 0)
        let span = SpriteBlitter.rippleOffsets.min()!...SpriteBlitter.rippleOffsets.max()!
        for i in changed + masked {
            XCTAssertTrue((0..<32).contains(i / w), "row \(i / w)")
            XCTAssertTrue((96 + span.lowerBound...127 + span.upperBound).contains(i % w), "col \(i % w)")
        }
        XCTAssertTrue(masked.allSatisfy { r.ports.mask[$0] == 0 })
        XCTAssertEqual(r.ports.tiles, before.tiles)
        var k0 = before, k1 = before
        try WaterFaceBlitter.draw([WaterFaceDraw(cellX: 3, cellY: 0, tile: t, waterKind: 0)],
                                  faces: r.grid.sets.fgWater.sheet, sprites: r.sprites, scroll: r.scroll, ports: &k0)
        try WaterFaceBlitter.draw([draw], faces: r.grid.sets.fgWater.sheet, sprites: r.sprites, scroll: r.scroll,
                                  ports: &k1)
        XCTAssertEqual(k1, r.ports)
        XCTAssertNotEqual(k0.frame, k1.frame)
        // The mask there is already 0 (the grid's FG stamp); over an all-0xff mask the twin clears the silhouette.
        var m = before
        m.mask = [UInt8](repeating: 0xff, count: m.mask.count)
        try WaterFaceBlitter.draw([draw], faces: r.grid.sets.fgWater.sheet, sprites: r.sprites, scroll: r.scroll,
                                  ports: &m)
        let zeroed = m.mask.indices.filter { m.mask[$0] == 0 }
        XCTAssertTrue(zeroed.allSatisfy { (0..<32).contains($0 / w) })
        XCTAssertEqual([Int(t), changed.count, masked.count, zeroed.count], [40, 292, 0, 292])
        XCTAssertEqual(hex(fnv1a(r.ports.frame + r.ports.mask)), "2ed3103e74e4550b")
        // Under a light (the first active slot whose point is in the frame-1 view; level 1's hdr 0x2706 is 0, so an
        // unlit face gets no darken pass): the light pass runs with water row 1 — the underwater (rippled) light
        // blitter, which differs from the dry one.
        let lit = r.lights.slots.first { $0.active && (0..<0x260).contains($0.x) && (0..<0x180).contains($0.y) }!
        let ld = WaterFaceDraw(cellX: lit.x >> 5, cellY: lit.y >> 5, tile: t, waterKind: 1)
        var l1 = before
        try WaterFaceBlitter.draw([ld], faces: r.grid.sets.fgWater.sheet, sprites: r.sprites, scroll: r.scroll,
                                  ports: &l1)
        var dry = before
        let face = r.grid.sets.fgWater.sheet.faces[Int(t)]
        try r.sprites.blitEncFaceX(face, src: (0, 0), dst: (ld.cellY << 5, ld.cellX << 5), w: 32, h: 32, word: 0x60001,
                                   flip: false, rotation: 0, scale: 0x100, ports: &dry)
        var above = dry
        try r.sprites.lightFace(face, src: (0, 0), dst: (ld.cellY << 5, ld.cellX << 5), w: 32, h: 32,
                                x: ld.cellX << 5, y: ld.cellY << 5, flip: false, waterRow: 1, h0: 0, v0: 0, ports: &dry)
        try r.sprites.lightFace(face, src: (0, 0), dst: (ld.cellY << 5, ld.cellX << 5), w: 32, h: 32,
                                x: ld.cellX << 5, y: ld.cellY << 5, flip: false, waterRow: 0, h0: 0, v0: 0, ports: &above)
        XCTAssertEqual(l1, dry)
        XCTAssertNotEqual(l1.frame, above.frame)
        XCTAssertEqual([ld.cellX, ld.cellY], [9, 4])
        XCTAssertEqual(hex(fnv1a(l1.frame)), "4f18ef875172bfe")
        XCTAssertThrowsError(try WaterFaceBlitter.draw([WaterFaceDraw(cellX: 3, cellY: 0, tile: 0x60, waterKind: 1)],
                                                       faces: r.grid.sets.fgWater.sheet, sprites: r.sprites,
                                                       scroll: r.scroll, ports: &k1)) {
            XCTAssertEqual($0 as? FrameRenderer.Refusal, .waterFaceTile(0x60))
        }
    }

    func testFirstFrameGoldenLevel1HighestTieBreak() throws {
        // Ben, 2026-10-07 (D26): the duplicate-colour tie-break `.highest` (FG 200's blacks → 255, black in clut
        // 202 too) beside the default above. The scroll and lights are the default frame's.
        let r = try renderer(tieBreak: .highest)
        let s = try session(r)
        let ops = s.step(keys: KeyState())
        XCTAssertEqual([s.camera.scrollH, s.camera.scrollV], [0, 0])
        try r.apply(ops)
        assertLightsHandled(r, h: 0, v: 0, reFaced: Self.potionStep1)
        dump(r, "level1-frame1-highest")
        // Measured 2026-10-10 (A1 fix round): as the default frame 1 but `.highest`, inverse-table cell ties included.
        XCTAssertEqual(hex(fnv1a(r.screen.pixels)), "b80b0efd384ffdb9")
    }

    func testPanFrameGoldens() throws {
        // 60 frames with keypad 6 held (action 1, the original default — P3; it walks the player, and since P5 his
        // `.PlayerScroll` moves the camera focus), after the first frame.
        let r = try renderer()
        let s = try session(r)
        try r.apply(s.step(keys: KeyState()))
        assertLightsHandled(r, h: 0, v: 0, reFaced: Self.potionStep1)
        let right = KeyState(pressed: [0x58])
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
        // passes 0. Re-measured 2026-10-10 with the potion light's twinkle (`BonusHandle`; was f6296c7e706130f3 /
        // e7a951e3eafca30a / 3c5aee2b87819db6, light 24 held on 0x32a); frame 1 is unchanged. Re-measured 2026-10-10
        // (F1) with the twinkle's start phase from the Setup's `FastRand(0x10)` = 6 under seed 1 (was 686024aba05c6660
        // / 18c4e45ebeee8e88 / 51d5f367bd111589 with phase 0); frame 1's hash is unchanged.
        // ◈ P5: the camera follows the player (was [4, 10] / [226, 10] under the ◇ focus driver): he walks into the
        // pit and clings at x 146, so the target h (focus x − 0x130) stays below 0 → h clamps to 0; v follows his
        // centre y down into the pit.
        XCTAssertEqual(scrolls[29], [0, 19])
        XCTAssertEqual(scrolls[59], [0, 19])
        // ◈ Re-measured 2026-10-13 (P3, twice): the real player walks (keypad 6) instead of the ◇ pose walking in place —
        // he walks off the start ledge into the pit (cols 5–8) and clings to its far wall (1012); the camera is still
        // the ◇ focus driver's, so the scrolls are unchanged (was e493fc8b09f84ed5 / 3ec51d436e278776 /
        // 6e034d02ef78d7fb; frame 60 is unchanged — the player is off-screen by then). ◈ Re-measured 2026-10-13 (P5,
        // twice): `.PlayerScroll` replaces the ◇ focus driver, so the view stays on the player (was be2b8e2e6631b1a7 /
        // 3ec51d436e278776 / 967803e69d2ceaf6).
        XCTAssertEqual(hex(chain[29]), "172596fa2f3b6c58")
        XCTAssertEqual(hex(chain[59]), "cc9786ba763d383a")
        XCTAssertEqual(hex(fnv1a(chain.flatMap { v in (0..<8).map { UInt8(v >> (8 * $0) & 0xff) } })), "b4230ba5a643c5b5")
    }

    func testItemLightTwinkleDimsTheTable() throws {
        // `.ChangeLightFace @ 1001bdbc`: the slot's face and radius; a slot outside 0…199 is ignored.
        let r = try renderer()
        let s = try session(r)
        try r.apply(s.step(keys: KeyState()))
        XCTAssertEqual(r.lights.slots[24].face?.pict, 0x32b)        // seed 1: phase 6 → 7, k = 1
        try r.apply(FrameOps(draws: [.changeLightFace(slot: 24, pict: 0x32c, width: 0x48, height: 0x48),
                                     .changeLightFace(slot: 200, pict: 0x32d, width: 0x48, height: 0x48)]))
        XCTAssertEqual(r.lights.slots[24].face?.pict, 0x32c)
        XCTAssertEqual(r.lights.slots[24].radius, 36)
        XCTAssertEqual(r.executed, [.lightFace(24), .lightFace(200)])

        // Let's Play 02:12 (colour-measurement-2026-10-10 Q3): the table 0xb6f under the potion's light 24. Through
        // the twinkle its face spends 3 of every 6 phases on 0x32c/0x32d, far dimmer than the Setup's 0x32a, so the
        // table under the light is darker than with 0x32a held (what Phase 1 drew before `BonusHandle`).
        func tableLuma(forcing pict: Int16?) throws -> Int {
            let r = try renderer()
            let s = try session(r)
            // Seed 1: the Setup phase is 6, so step 13 leaves phase 19 → k = (19 >> 2) mod 6 = 4 → 0x32c.
            for _ in 0..<13 { try r.apply(s.step(keys: KeyState())) }
            XCTAssertEqual(r.lights.slots[24].face?.pict, 0x32c)
            if let pict {
                try r.apply(FrameOps(draws: [.changeLightFace(slot: 24, pict: pict, width: 0x48, height: 0x48)]))
            }
            try r.apply(s.step(keys: KeyState()))
            let h = s.camera.scrollH, v = s.camera.scrollV
            var sum = 0
            for wy in 134..<160 { for wx in 270..<330 {
                let c = r.screenClut.entries[Int(r.screen[16 + wx - h, 8 + wy - v])]
                sum += Int(c.red >> 8) + Int(c.green >> 8) + Int(c.blue >> 8)
            } }
            return sum
        }
        let twinkled = try tableLuma(forcing: nil), held = try tableLuma(forcing: 0x32a)
        XCTAssertLessThan(Double(twinkled), Double(held) * 0.9)
    }
}

