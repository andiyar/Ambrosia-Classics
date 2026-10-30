import XCTest
import FerazelCore
@testable import FerazelRender

/// M2 (docs/plans/2026-10-14-ferazel-phase3.md): the world map's drawing — `MapRenderer` executing M1's `MapOp`s:
/// `.InitMapFaces @ 1007ac38` (M l. 66617–66640), `.DrawLink @ 1007b7c8` / `.DrawLinkScratch @ 1007b998` (M l.
/// 67057–67133), `.DrawNodeSprites` / `.EraseNodeSprites` / `.CopyNodeSpritesToScreen` (M l. 66855–66958), the slop-8
/// blit ports (`.NewBlitPortSlop @ 10034650`, M l. 31446–31523). Driven by `WorldMapRun` against the committed
/// `Resources/Ferazel` (D26). A missing data file is a FAILURE, never a skip.
final class MapRenderTests: XCTestCase {

    nonisolated(unsafe) private static let resources = Result { try FerazelData.open(try FerazelData.dataDirectory()) }

    private func fnv1a(_ bytes: [UInt8]) -> UInt64 {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for b in bytes { h = (h ^ UInt64(b)) &* 0x0000_0100_0000_01b3 }
        return h
    }

    /// The surface's indices, then its CLUT's 256 entries (R, G, B big-endian) — as `ScreenTests`.
    private func image(_ s: ScreenSurface) -> [UInt8] {
        var bytes = s.frame.pixels
        for e in s.clut.entries {
            for c in [e.red, e.green, e.blue] { bytes += [UInt8(c >> 8), UInt8(c & 0xff)] }
        }
        return bytes
    }

    /// A map renderer on a fresh surface under clut 130 (the main menu's; the map's first op sets 700).
    private func renderer() throws -> MapRenderer {
        let r = try Self.resources.get()
        let surface = ScreenSurface(clut: try ColorLUT.load(id: 130, from: r, chain: .frontEnd))
        return MapRenderer(screen: ScreenRenderer(surface: surface, resources: r, search: ColorSearch(model: .ruled),
                                                  text: StatusBarTests.BoxRasterizer()))
    }

    /// `.ShowWorldMap` after level 1 (exit1 0 → level 2 unlocked), seed 1, from a faded screen.
    private func mapAfterLevel1() throws -> WorldMapRun {
        let r = try Self.resources.get()
        var g = GameGlobals.initGameGlobals(previous: nil)
        g.unlocked[1] = 1
        var fade = ScreenFade()
        fade.faded = true
        let name = try LevelFile.load(from: r, level: 1).header.name
        return try WorldMapRun(resources: r, prefs: FerazelPrefs(), globals: g, level: 1, levelName: name, exit1: 0,
                               exit2: -1, levelComplete: true, seed: 1, fade: fade, music: MusicFade())
    }

    private func clut700() throws -> ColorLUT {
        try ColorLUT.load(id: WorldMapRun.mapClut, from: try Self.resources.get(), chain: .frontEnd)
    }

    // MARK: - Tests

    func testMapFirstFrameGolden() throws {
        let run = try mapAfterLevel1()
        let m = try renderer()
        let out = run.tick(now: 1000, input: FrontInput())
        XCTAssertTrue(out.output.present)
        try m.apply(out.ops)
        XCTAssertEqual(m.screen.surface.clut.id, 700)
        XCTAssertGreaterThan(Set(m.screen.surface.frame.pixels).count, 16)
        // Self-derived golden (M2 first green, 2026-10-14): FNV-1a 64 of the 640×480 indices followed by the CLUT's
        // 256 entries as 16-bit big-endian R, G, B — the first tick of `.ShowWorldMap` after level 1 (seed 1): PICT 129
        // under clut 700, the status bar, PICT 7000 in the background with the 1–2 link, the node / marker / ambient
        // sprites (`.ruled`, lowest tie-break, error diffusion; `BoxRasterizer` text).
        // Re-pinned 2026-10-30 (map status bar fix): the old value "38563faaa2276f05" pinned the status bar's clut-199
        // indices read raw through clut 700 (the blue speckle); now they are translated from clut 200 into clut 700.
        XCTAssertEqual(String(fnv1a(image(m.screen.surface)), radix: 16), "eaed376517e32afd")

        // The ambient sprite (type 100) is never erased: `.EraseNodeSprites` skips it (M l. 66888–66917). Its counter
        // starts at −4 (no face), so run on until it is drawn; no background → work copy ever covers its rect, and
        // after each frame its face's pixels (where they differ from the background) are still in the work port.
        let ambient = try m.face(.mapAmbient, 0)
        var ambientFrames = 0
        for t in UInt32(1001)..<UInt32(1400) {
            let ops = run.tick(now: t, input: FrontInput()).ops
            try m.apply(ops)
            var drawn: (index: Int, h: Int, v: Int)?
            for op in ops {
                if case .draw(.drawFace(set: .mapAmbient, let i, let h, let v), port: .work) = op { drawn = (i, h, v) }
            }
            guard let a = drawn else { continue }
            ambientFrames += 1
            let rect = Rect16(top: Int16(a.v + 4), left: Int16(a.h + 4), bottom: Int16(a.v + ambient.height + 12),
                              right: Int16(a.h + ambient.width + 12))
            for op in ops {
                if case .copy(from: .background, to: .work, let s, _) = op {
                    XCTAssertNotEqual(s, rect, "tick \(t): the ambient sprite's rect erased")
                }
            }
            let face = try m.face(.mapAmbient, a.index)
            let pixels = try face.decode()
            var opaque = [Bool](repeating: false, count: face.width * face.height)
            var row = -1, col = 0
            for token in try face.tokens() {
                switch token {
                case .row: row += 1; col = 0
                case .skip(let n): col += n
                case .copy(let bytes):
                    for k in 0..<bytes.count { opaque[row * face.width + col + k] = true }
                    col += bytes.count
                case .end: break
                }
            }
            var differing = 0
            for r in 0..<face.height {
                for c in 0..<face.width where opaque[r * face.width + c] {
                    let (x, y) = (a.h + 8 + c, a.v + 8 + r)
                    guard m.background[x, y] != pixels[r * face.width + c] else { continue }
                    differing += 1
                    XCTAssertEqual(m.work[x, y], pixels[r * face.width + c], "tick \(t) ambient cell \(r), \(c)")
                }
            }
            XCTAssertGreaterThan(differing, 0)
        }
        XCTAssertGreaterThan(ambientFrames, 0)
    }

    /// The status bar on the map (M l. 67505, 67539): `*_DAT_100a0088` (level complete) is set, so `.CopyBitsCT @
    /// 1000001c` leaves the seeds alone and the status port → screen copy translates — each port pixel's colour under
    /// the port's clut 200 matched into clut 700 — the grey stone bar the original shows, not clut-199 indices read
    /// through clut 700 (the blue speckle). Reference: the in-level path (`StatusBar` raw on a screen under clut 200)
    /// with the same calls, each colour then matched into clut 700.
    func testMapStatusBarIsTheInLevelBarMatchedIntoClut700() throws {
        let r = try Self.resources.get()
        let run = try mapAfterLevel1()
        let m = try renderer()
        let ops = run.tick(now: 1000, input: FrontInput()).ops
        try m.apply(ops)
        let c200 = try ColorLUT.load(id: 200, from: r, chain: .level)
        let c700 = try clut700()
        let search = ColorSearch(model: .ruled)
        var reference = try StatusBar(resources: r, screenClut: c200, search: search, dither: .errorDiffusion,
                                      text: StatusBarTests.BoxRasterizer())
        var frame = IndexedFrame()
        var bars = 0
        for op in ops {
            if case .draw(.statusBar(let state), port: .screen) = op { reference.update(state, screen: &frame); bars += 1 }
        }
        XCTAssertEqual(bars, 2)
        let into700 = search.prepared(for: c700)
        let screen = m.screen.surface.frame
        var mismatches = 0
        for y in StatusBar.screenTop..<IndexedFrame.height {
            for x in 0..<IndexedFrame.width {
                let e = c200.entries[Int(frame[x, y])]
                let want = c700.entries[Int(into700.index(of: RGB16(e.red, e.green, e.blue)))]
                if c700.entries[Int(screen[x, y])].rgb != want.rgb { mismatches += 1 }
            }
        }
        XCTAssertEqual(mismatches, 0)
        // The stone: PICT 132's commonest pixel (clut 199/200 index 157, 0x4c4c4c) stays a grey on the map — clut 700's
        // nearest is 0x435549 (channels within 24); the unfixed bar showed it as clut 700's own entry 157, 0x1457bd.
        var stones = 0, notGrey = 0
        for y in StatusBar.screenTop..<IndexedFrame.height {
            for x in 0..<IndexedFrame.width where frame[x, y] == 157 {
                let s = c700.entries[Int(screen[x, y])]
                let (r, g, b) = (Int(s.red >> 8), Int(s.green >> 8), Int(s.blue >> 8))
                if max(r, g, b) - min(r, g, b) >= 24 { notGrey += 1 }
                stones += 1
            }
        }
        XCTAssertGreaterThan(stones, 1000)
        XCTAssertEqual(notGrey, 0)
        // Pins worked apart from `ColorSearch` (D44 run 38, Q15 item 7): clut 200's and 700's colours read from the
        // data, the nearest clut-700 entry by squared 8-bit RGB distance (ties to the lower index) — the stone grey
        // 157 (0x4c4c4c → entry 74, 0x435549: distance 171, the next 726), white 0 → 0, and clut 200's blacks (96,
        // 160…255) → 255, clut 700's only black.
        func nearest700(_ i: Int) -> Int {
            let e = c200.entries[i]
            func d(_ j: Int) -> Int {
                let f = c700.entries[j]
                return [(e.red, f.red), (e.green, f.green), (e.blue, f.blue)]
                    .map { (Int($0.0 >> 8) - Int($0.1 >> 8)) * (Int($0.0 >> 8) - Int($0.1 >> 8)) }.reduce(0, +)
            }
            return c700.entries.indices.min { d($0) < d($1) || (d($0) == d($1) && $0 < $1) } ?? -1
        }
        let blacks = c200.entries.indices.filter { c200.entries[$0].red | c200.entries[$0].green | c200.entries[$0].blue == 0 }
        XCTAssertEqual(blacks, [96] + Array(160...255))
        XCTAssertEqual([nearest700(157), nearest700(0)], [74, 0])
        XCTAssertEqual(Set(blacks.map(nearest700)), [255])
        var pinned = 0
        for y in StatusBar.screenTop..<IndexedFrame.height {
            for x in 0..<IndexedFrame.width {
                let want: UInt8? = frame[x, y] == 157 ? 74 : frame[x, y] == 0 ? 0 : blacks.contains(Int(frame[x, y])) ? 255 : nil
                guard let want else { continue }
                XCTAssertEqual(screen[x, y], want, "(\(x), \(y))")
                pinned += 1
                if screen[x, y] != want { return }
            }
        }
        XCTAssertGreaterThan(pinned, 1000)
    }

    func testLinkPixels() throws {
        let run = try mapAfterLevel1()
        let m = try renderer()
        let c700 = try clut700()
        let search = ColorSearch(model: .ruled)
        let black = search.index(of: RGB16(0, 0, 0), in: c700)
        let white = search.index(of: RGB16(0xffff, 0xffff, 0xffff), in: c700)
        XCTAssertNotEqual(black, white)
        // Node 1 (h 237, v 307) → node 2 (h 269, v 330): dx 32, dy 23.
        try m.apply(run.tick(now: 1000, input: FrontInput()).ops)
        let centre = MapRenderer.linePixels(h1: 237, v1: 307, h2: 269, v2: 330)
        XCTAssertEqual(centre.count, 33)
        // The flat runs of the centre line (two pixels on one row): away from the node faces (h ± 12 of 237 and 269).
        let flats = zip(centre, centre.dropFirst()).filter { $0.0.y == $0.1.y && $0.0.x >= 250 && $0.1.x <= 256 }
        XCTAssertFalse(flats.isEmpty)
        for (p, q) in flats {
            // Both white (the white centre line drawn last), each flanked by the black ±1 lines: p's +1/+1 copy and
            // q's −1/−1 copy — on a diagonal step the white centre covers one of them instead.
            XCTAssertEqual(m.background[p.x, p.y], white, "\(p)")
            XCTAssertEqual(m.background[q.x, q.y], white, "\(q)")
            XCTAssertEqual(m.background[p.x + 1, p.y + 1], black, "\(p) +1/+1")
            XCTAssertEqual(m.background[q.x - 1, q.y - 1], black, "\(q) −1/−1")
            // On the screen at (+16, +8) (the view copy).
            XCTAssertEqual(m.screen.surface.frame[p.x + 16, p.y + 8], white)
            XCTAssertEqual(m.screen.surface.frame[p.x + 17, p.y + 9], black)
            XCTAssertEqual(m.screen.surface.frame[q.x + 15, q.y + 7], black)
        }
        // A `.DrawNewLink` flash: the three lines of one iteration in its one colour (centre, −1/−1, +1/+1), on the
        // screen (the dirty rect is copied before `.EraseNodeSprites` restores the sprite rects of the work port).
        var t: UInt32 = 1001
        var lines: [(Int, Int, Int, Int, RGB16)] = []
        while lines.isEmpty, t < 1300 {
            let ops = run.tick(now: t, input: FrontInput()).ops
            try m.apply(ops)
            lines = ops.compactMap {
                if case .draw(.drawLine(let a, let b, let c, let d, let rgb), port: .work) = $0 { return (a, b, c, d, rgb) }
                return nil
            }
            t += 1
        }
        XCTAssertEqual(lines.count, 3)
        guard let rgb = lines.first?.4 else { return }
        XCTAssertTrue(lines.allSatisfy { $0.4 == rgb })
        let flash = search.index(of: rgb, in: c700)
        XCTAssertNotEqual(flash, white)
        for d in [0, -1, 1] {
            for p in MapRenderer.linePixels(h1: 237 + d, v1: 307 + d, h2: 269 + d, v2: 330 + d)
            where (250...256).contains(p.x) {
                XCTAssertEqual(m.screen.surface.frame[p.x + 16, p.y + 8], flash, "screen line \(d) \(p)")
            }
        }
    }

    func testNodeFaceCentred() throws {
        let m = try renderer()
        let (h, v) = (237, 307)                                     // node 1
        // `.AddNodeSprite(h − 20, v − 20, …)`; `.CopyNodeSpritesToScreen`'s rect (x + 4, y + 4, x + w + 12, y + h + 12).
        let x = h - 20, y = v - 20
        let rect = Rect16(top: Int16(y + 4), left: Int16(x + 4), bottom: Int16(y + 24 + 12), right: Int16(x + 24 + 12))
        try m.apply([.portsClut(id: WorldMapRun.mapClut), .draw(.setScreenClut(id: WorldMapRun.mapClut), port: .screen),
                     .draw(.drawFace(set: .mapNode, index: 0, h: x, v: y), port: .work),
                     .copy(from: .work, to: .screen, source: rect,
                           dest: Rect16(top: rect.top + 8, left: rect.left + 16, bottom: rect.bottom + 8,
                                        right: rect.right + 16))])
        let face = try m.face(.mapNode, 0)
        XCTAssertEqual(face.width, 24)
        XCTAssertEqual(face.height, 24)
        // The face's opaque pixels, from its token stream.
        var opaque = [Bool](repeating: false, count: 24 * 24)
        var row = -1, col = 0
        for token in try face.tokens() {
            switch token {
            case .row: row += 1; col = 0
            case .skip(let n): col += n
            case .copy(let bytes): for k in 0..<bytes.count { opaque[row * 24 + col + k] = true }; col += bytes.count
            case .end: break
            }
        }
        XCTAssertTrue(opaque.contains(true))
        let pixels = try face.decode()
        let screen = m.screen.surface.frame
        // Face cell (r, c) lands on screen (h + 16 − 12 + c, v + 8 − 12 + r): the face spans h+16−12 … h+16+11,
        // v+8−12 … v+8+11 — centred on the node's screen point (h + 16, v + 8).
        for r in 0..<24 {
            for c in 0..<24 where opaque[r * 24 + c] {
                XCTAssertEqual(screen[h + 16 - 12 + c, v + 8 - 12 + r], pixels[r * 24 + c], "cell \(r), \(c)")
            }
        }
        // Nothing of the face outside: the copied rect's margin shows the work port's untouched contents.
        for xx in (h + 16 - 16)..<(h + 16 + 16) {
            XCTAssertEqual(screen[xx, v + 8 - 16], 0)
            XCTAssertEqual(screen[xx, v + 8 + 15], 0)
        }
        for yy in (v + 8 - 16)..<(v + 8 + 16) {
            XCTAssertEqual(screen[h + 16 - 16, yy], 0)
            XCTAssertEqual(screen[h + 16 + 15, yy], 0)
        }
    }
}
