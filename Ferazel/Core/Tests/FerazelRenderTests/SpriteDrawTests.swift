import XCTest
import FerazelCore
@testable import FerazelRender

/// R4 (docs/plans/2026-10-06-ferazel-phase1.md): `.WrapDrawSprites @ 100144c8` steps 1–8 for the level-1 Setup modes
/// (draw-effects §1.1–§1.3, §2.2, §3) and `.WrapEraseSprites @ 10014a58`, on synthetic faces over the committed
/// level 1's tables and tile grid (D26). A missing data file is a FAILURE, never a skip.
final class SpriteDrawTests: XCTestCase {

    private static let shared = Result { try TileGridTests.Fixture() }
    private func fixture() throws -> TileGridTests.Fixture { try Self.shared.get() }

    /// An 8×6 face: pixel (r, c) = 0x20 + 8r + c, except (0, 0), (2, 3), (5, 7) transparent (0).
    private static let w = 8, h = 6
    private static func pixel(_ r: Int, _ c: Int) -> UInt8 {
        [(0, 0), (2, 3), (5, 7)].contains { $0 == (r, c) } ? 0 : UInt8(0x20 + 8 * r + c)
    }
    private static let ref = FaceRef(pict: 9001, index: 0, set: .encoded)

    private func faces() throws -> SpriteBlitter.Faces {
        let px = (0..<Self.h).flatMap { r in (0..<Self.w).map { c in Self.pixel(r, c) } }
        let face = try FaceEncoder.encode(pixels: px, width: Self.w, height: Self.h,
                                          rect: EncodedFace.Rect(top: 0, left: 0, bottom: Int16(Self.h),
                                                                 right: Int16(Self.w)), sourceId: 9001)
        let a = try FaceSheet.Arguments(pict: 9001, count: 1, cellWidth: Self.w, cellHeight: Self.h, columns: 1)
        return SpriteBlitter.Faces(sheets: [9001: FaceSheet(arguments: a, faces: [face], shortCells: [:], clutId: 202)])
    }

    private func blitter(_ f: TileGridTests.Fixture, effects: Int16 = 3) throws -> SpriteBlitter {
        SpriteBlitter(level: f.level, tables: f.tables, faces: try faces(), effects: effects)
    }

    /// World pixel (x, y) of a port.
    private func at(_ port: [UInt8], _ x: Int, _ y: Int) -> UInt8 { port[FramePorts.ringOffset(x: x, y: y)] }

    /// Every face pixel (r, c) that `expected(r, c)` says lands at world (x0 + col(c), y0 + r), with the frame and
    /// mask contents expected there; every other pixel of the 3-px margin box keeps the fill.
    private func assertDrawn(_ ports: FramePorts, x0: Int, y0: Int, rows: Range<Int>, cols: Range<Int>, flip: Bool,
                             fill: UInt8, value: (UInt8) -> UInt8 = { $0 }, line: UInt = #line) {
        for y in (y0 - 3)..<(y0 + Self.h + 3) {
            for x in (x0 - 3)..<(x0 + Self.w + 3) {
                let r = y - y0, dc = x - x0
                let c = flip ? Self.w - 1 - dc : dc
                let inside = rows.contains(r) && (0..<Self.w).contains(dc) && cols.contains(dc)
                let p = inside ? Self.pixel(r, c) : 0
                let frame = at(ports.frame, x, y), mask = at(ports.mask, x, y)
                if inside && p != 0 {
                    XCTAssertEqual(frame, value(p), "frame (\(x), \(y))", line: line)
                    XCTAssertEqual(mask, 0, "mask (\(x), \(y))", line: line)
                } else {
                    XCTAssertEqual(frame, fill, "frame (\(x), \(y)) untouched", line: line)
                    XCTAssertEqual(mask, fill, "mask (\(x), \(y)) untouched", line: line)
                }
            }
        }
    }

    func testWrapDrawSpritesClipAndMaskPass() throws {
        let f = try fixture()
        let b = try blitter(f)
        let fill: UInt8 = 0x77
        func draw(_ d: SpriteDraw, h: Int = 0, v: Int = 0) throws -> FramePorts {
            var ports = FramePorts(fill: fill)
            try b.wrapDrawSprites([d], h: h, v: v, ports: &ports)
            return ports
        }
        let open = SpriteClip(left: 0, right: 32000, bottom: 32000, top: 0)

        // Steps 1–4: the whole face; the mask pass writes 0 under the silhouette only.
        assertDrawn(try draw(SpriteDraw(face: Self.ref, x: 100, y: 50, clip: open)), x0: 100, y0: 50, rows: 0..<6,
                    cols: 0..<8, flip: false, fill: fill)
        // Step 2: clips are face-local edges — rows [top, min(bottom, h)), columns [left, min(right, w)) — drawn where
        // the unclipped face has them.
        let clipped = SpriteClip(left: 2, right: 6, bottom: 4, top: 1)
        assertDrawn(try draw(SpriteDraw(face: Self.ref, x: 100, y: 50, clip: clipped)), x0: 100, y0: 50, rows: 1..<4,
                    cols: 2..<6, flip: false, fill: fill)
        // `+0x17e`: mirrored in its frame; the clip window is taken in the mirrored image.
        assertDrawn(try draw(SpriteDraw(face: Self.ref, x: 100, y: 50, mirrored: true, clip: open)), x0: 100, y0: 50,
                    rows: 0..<6, cols: 0..<8, flip: true, fill: fill)
        assertDrawn(try draw(SpriteDraw(face: Self.ref, x: 100, y: 50, mirrored: true, clip: clipped)), x0: 100,
                    y0: 50, rows: 1..<4, cols: 2..<6, flip: true, fill: fill)
        // The default `SpriteClip()` (right = bottom = 0) draws nothing — Setups leave 32000 (`.InitSprite`).
        assertDrawn(try draw(SpriteDraw(face: Self.ref, x: 100, y: 50)), x0: 100, y0: 50, rows: 0..<0, cols: 0..<0,
                    flip: false, fill: fill)

        // Step 3, the ring: world (636, 412) at scroll (600, 400) is ring (636, 412) and wraps to columns 0..3 and
        // rows 0..1 — four `.BlitEncFaceX` calls; every pixel at its world position mod (640, 416).
        assertDrawn(try draw(SpriteDraw(face: Self.ref, x: 636, y: 412, clip: open), h: 600, v: 400), x0: 636,
                    y0: 412, rows: 0..<6, cols: 0..<8, flip: false, fill: fill)
        // The view clip: left of scroll h and above scroll v nothing (the source moves); the right edge is
        // h + 0x280 (`10015260`), the cull h + 0x260 — so a face starting at h + 0x260 − 2 still draws all 8 columns,
        // and at h + 0x260 + 1 none.
        assertDrawn(try draw(SpriteDraw(face: Self.ref, x: 297, y: 98, clip: open), h: 300, v: 100), x0: 297, y0: 98,
                    rows: 2..<6, cols: 3..<8, flip: false, fill: fill)
        assertDrawn(try draw(SpriteDraw(face: Self.ref, x: 300 + 0x260 - 2, y: 150, clip: open), h: 300, v: 100),
                    x0: 300 + 0x260 - 2, y0: 150, rows: 0..<6, cols: 0..<8, flip: false, fill: fill)
        assertDrawn(try draw(SpriteDraw(face: Self.ref, x: 300 + 0x260 + 1, y: 150, clip: open), h: 300, v: 100),
                    x0: 300 + 0x260 + 1, y0: 150, rows: 0..<0, cols: 0..<0, flip: false, fill: fill)
        // The bottom edge is v + 0x180: a face whose top is 2 rows above it draws rows 0, 1.
        assertDrawn(try draw(SpriteDraw(face: Self.ref, x: 400, y: 100 + 0x180 - 2, clip: open), h: 300, v: 100),
                    x0: 400, y0: 100 + 0x180 - 2, rows: 0..<2, cols: 0..<8, flip: false, fill: fill)

        // Refused by name: hurt flash (mode 3), translucency (0xb, e.g. a `+0x89` word with L = −1), the water split.
        var ports = FramePorts(fill: fill)
        XCTAssertThrowsError(try b.wrapDrawSprites([SpriteDraw(face: Self.ref, x: 0, y: 0, mode: 0x30002, clip: open)],
                                                   h: 0, v: 0, ports: &ports)) {
            XCTAssertEqual($0 as? SpriteBlitter.Refusal, .mode(0x30002))
        }
        var lit = SpriteSlot(type: 1, x: 0, y: 0, face: Self.ref); lit.dynamicLight = true
        XCTAssertEqual(lit.applyDynamicLight(lightTile: -1, fakeLight: 2), 0xbff02)
        XCTAssertThrowsError(try b.wrapDrawSprites([SpriteDraw(face: Self.ref, x: 0, y: 0, mode: 0xbff02, clip: open)],
                                                   h: 0, v: 0, ports: &ports))
        XCTAssertThrowsError(try b.wrapDrawSprites([SpriteDraw(face: Self.ref, x: 0, y: 0, clip: open, waterRow: 1)],
                                                   h: 0, v: 0, ports: &ports)) {
            XCTAssertEqual($0 as? SpriteBlitter.Refusal, .waterSplit(1))
        }

        // Step 7, the light pass (`+0x88`, Effects ≠ 3, level-1 header 0x2706 = 5 > 0, no light slot): every frame
        // pixel under the copy runs remapped through ambient slab D = `.GetAmbDarkVal(x + w/2, y + h/2)`.
        let lit1 = try blitter(f, effects: 1)
        var dark = FramePorts(fill: fill)
        try lit1.wrapDrawSprites([SpriteDraw(face: Self.ref, x: 100, y: 50, clip: open, lightOverlay: true)], h: 0,
                                 v: 0, ports: &dark)
        let D = f.level.lightByte(col: (100 + Self.w / 2) >> 5, row: (50 + Self.h / 2) >> 5)
        let slab = lit1.lights.ambientSlab(D)
        assertDrawn(dark, x0: 100, y0: 50, rows: 0..<6, cols: 0..<8, flip: false, fill: fill, value: { slab[Int($0)] })
        // Effects 3 skips it.
        assertDrawn(try draw(SpriteDraw(face: Self.ref, x: 100, y: 50, clip: open, lightOverlay: true)), x0: 100,
                    y0: 50, rows: 0..<6, cols: 0..<8, flip: false, fill: fill)

        // `.WrapEraseSprites` (R1's precondition): a sprite drawn last frame at (100, 50) and now at (110, 50) —
        // frame ← tiles port `0004` and mask ← 0xFF under the old footprint (the old face's copy runs), then the
        // mask-only `.RedrawScrollGrid(cells, 1)` over the erased rect ∩ the ring window, >> 5 (inclusive).
        var slot = SpriteSlot(type: 1, x: 100, y: 50, face: Self.ref)
        slot.recordDrawn()
        slot.x = 110
        var erasePorts = FramePorts(fill: fill)
        for k in erasePorts.tiles.indices { erasePorts.tiles[k] = UInt8(truncatingIfNeeded: k &* 7) }
        let cells = try b.wrapEraseSprites([slot], h: 0, v: 0, ports: &erasePorts)
        XCTAssertEqual(cells.count, 1)
        XCTAssertEqual(cells.first?.top, 50 >> 5); XCTAssertEqual(cells.first?.left, 100 >> 5)
        XCTAssertEqual(cells.first?.bottom, (50 + 6) >> 5); XCTAssertEqual(cells.first?.right, (100 + 8) >> 5)
        for r in 0..<Self.h {
            for c in 0..<Self.w {
                let o = FramePorts.ringOffset(x: 100 + c, y: 50 + r)
                if Self.pixel(r, c) != 0 {
                    XCTAssertEqual(erasePorts.frame[o], erasePorts.tiles[o], "erased (\(r), \(c))")
                    XCTAssertEqual(erasePorts.mask[o], 0xff, "mask (\(r), \(c))")
                } else {
                    XCTAssertEqual(erasePorts.frame[o], fill); XCTAssertEqual(erasePorts.mask[o], fill)
                }
            }
        }
        // An unchanged sprite away from the edge strips is not erased (the rect is the face bounds offset by the
        // scroll, as written: (0, 1, 6, 8) + (h, v) lies within 16 px of the view's top-left edges, so move the view
        // so that the bounds meet no strip: impossible for a face this small — every face-local rect within 16 px of
        // (0, 0) meets the top/left strips). So the erase fires for it too:
        var still = SpriteSlot(type: 1, x: 100, y: 50, face: Self.ref)
        still.recordDrawn()
        var stillPorts = FramePorts(fill: fill)
        XCTAssertEqual(try b.wrapEraseSprites([still], h: 0, v: 0, ports: &stillPorts).count, 1)
        // …while a sprite with no last-frame face is skipped.
        XCTAssertEqual(try b.wrapEraseSprites([SpriteSlot(type: 1, x: 0, y: 0, face: Self.ref)], h: 0, v: 0,
                                              ports: &stillPorts).count, 0)

        // The mask-only re-stamp on the real grid: under an erased footprint over level-1 tiles the mask comes back as
        // the full redraw left it (start window, scroll (0, 10); a sprite over FG cells at (64, 288)).
        let grid = f.renderer(drawnH: 0, drawnV: 10)
        var full = FramePorts()
        grid.redrawEntireScrollGrid(h: 0, v: 10, ports: &full)
        var drawnOver = full
        let big = SpriteDraw(face: Self.ref, x: 64, y: 288, clip: open)
        try b.wrapDrawSprites([big], h: 0, v: 10, ports: &drawnOver)
        var gone = SpriteSlot(type: 1, x: 64, y: 288, face: Self.ref)
        gone.recordDrawn()
        gone.dead = true
        try b.wrapEraseSprites([gone], h: 0, v: 10, ports: &drawnOver, grid: grid)
        XCTAssertEqual(drawnOver.mask, full.mask)
        XCTAssertEqual(drawnOver.frame, full.frame)
    }

    func testSpecialTableModes() throws {
        let f = try fixture()
        let b = try blitter(f)
        let open = SpriteClip(left: 0, right: 32000, bottom: 32000, top: 0)
        func draw(_ mode: UInt32, mirrored: Bool = false) throws -> FramePorts {
            var ports = FramePorts(fill: 0x55)
            try b.wrapDrawSprites([SpriteDraw(face: Self.ref, x: 200, y: 100, mode: mode, mirrored: mirrored,
                                              clip: open)], h: 0, v: 0, ports: &ports)
            return ports
        }
        // Mode 1: tint table sub (every level-1 tint: 0x10006 / 0x10007 plants and outcrops, 0x10010 Walker tier 1,
        // 0x10016 plants and decorations).
        for sub in [6, 7, 0x10, 0x16] {
            let t = f.tables.tint[sub]
            assertDrawn(try draw(0x10000 | UInt32(sub)), x0: 200, y0: 100, rows: 0..<6, cols: 0..<8, flip: false,
                        fill: 0x55, value: { t[Int($0)] })
        }
        assertDrawn(try draw(0x10006, mirrored: true), x0: 200, y0: 100, rows: 0..<6, cols: 0..<8, flip: true,
                    fill: 0x55, value: { f.tables.tint[6][Int($0)] })
        // Mode 9: water table 0 (teleporters, chests and Crabs placed in water).
        assertDrawn(try draw(0x90000), x0: 200, y0: 100, rows: 0..<6, cols: 0..<8, flip: false, fill: 0x55,
                    value: { f.tables.water[0][Int($0)] })
        // Mode 0xc (`+0x89`): F = 0 → ambient L; F ≠ 0 → light L·0x6e00 + F·0x100.
        var slot = SpriteSlot(type: 1, x: 0, y: 0, face: Self.ref); slot.dynamicLight = true
        XCTAssertEqual(slot.applyDynamicLight(lightTile: 0, fakeLight: 0), 0)
        XCTAssertEqual(slot.mode, 0)
        XCTAssertEqual(slot.applyDynamicLight(lightTile: 3, fakeLight: 0), 0xc0300)
        XCTAssertEqual(slot.applyDynamicLight(lightTile: 2, fakeLight: 5), 0xc0205)
        assertDrawn(try draw(0xc0300), x0: 200, y0: 100, rows: 0..<6, cols: 0..<8, flip: false, fill: 0x55,
                    value: { f.tables.ambient[3][Int($0)] })
        assertDrawn(try draw(0xc0205), x0: 200, y0: 100, rows: 0..<6, cols: 0..<8, flip: false, fill: 0x55,
                    value: { f.tables.light[2 * 0x6e00 + 5 * 0x100 + Int($0)] })
        // The undefined Special tables (2, 7, 0xf..0x13) and the other modes are refused.
        for word: UInt32 in [0x20000, 0x70000, 0x50003, 0x60000, 0x80000, 0xa0080, 0xd0000, 0xe0005, 0x140000] {
            var ports = FramePorts()
            XCTAssertThrowsError(try b.wrapDrawSprites([SpriteDraw(face: Self.ref, x: 0, y: 0, mode: word, clip: open)],
                                                       h: 0, v: 0, ports: &ports), "mode \(String(word, radix: 16))")
        }

        // Level 1's placed sprites: every sheet `SetupFaces` names loads under its CLUT and every Phase-1 face
        // resolves; the start window draws without a refusal.
        let c = SetupFaces.Context(level: f.level, playerX: SetupFaces.Context.levelStartPlayerX(f.level.header))
        let entries = try f.level.activePlacements.map { try SetupFaces.setup($0, context: c) }
        let sprites = try SpriteBlitter.Faces(Set(entries.compactMap(\.sheet)), resources: f.resources,
                                              search: ColorSearch(model: .ruled))
        for e in entries { if let ref = e.slot.face { XCTAssertNotNil(sprites.face(ref), "type \(e.type)") } }
        XCTAssertEqual(sprites.sheets[1307]?.clutId, 200)
        XCTAssertEqual(sprites.sheets[2710]?.clutId, 202)
        var spawned = try SetupFaces.spawnLevelSprites(context: c)
        spawned.idle.handle(h: 0, v: 10, playerHotRect: nil, active: &spawned.active) { _ in .noFace }
        let draws = spawned.active.wrapDrawSprites()
        var ports = FramePorts()
        try SpriteBlitter(level: f.level, tables: f.tables, faces: sprites)
            .wrapDrawSprites(draws, h: 0, v: 10, ports: &ports)
        XCTAssertEqual(draws.count, 10 + 13 - 1)   // the 1059 trigger in the window has no face
    }
}
