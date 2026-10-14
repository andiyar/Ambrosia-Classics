import XCTest
import FerazelCore
@testable import FerazelRender

/// FE0 (docs/plans/2026-10-14-ferazel-phase3.md): the front-end seam — `ScreenSurface` + `ScreenRenderer` (picture,
/// stretched and transparent copies), the timed gamma fades (`ScreenFade`, `.TintFadeProc`) and the music fades
/// (`MusicFade`) — lighting-tables §10, rendering-omnipx-titles §4.3 (BC16, BC28), M l. 31782–31862, 41852–42140.
/// A missing data file is a FAILURE, never a skip.
final class ScreenTests: XCTestCase {

    nonisolated(unsafe) private static let resources = Result { try FerazelData.open(try FerazelData.dataDirectory()) }

    private func fnv1a(_ bytes: [UInt8]) -> UInt64 {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for b in bytes { h = (h ^ UInt64(b)) &* 0x0000_0100_0000_01b3 }
        return h
    }

    private func renderer(clut: Int16 = 130) throws -> ScreenRenderer {
        let r = try Self.resources.get()
        let surface = ScreenSurface(clut: try ColorLUT.load(id: clut, from: r, chain: .frontEnd))
        return ScreenRenderer(surface: surface, resources: r, search: ColorSearch(model: .ruled),
                              text: StatusBarTests.BoxRasterizer())
    }

    /// The surface's indices, then its CLUT's 256 entries (R, G, B big-endian).
    private func image(_ s: ScreenSurface) -> [UInt8] {
        var bytes = s.frame.pixels
        for e in s.clut.entries {
            for c in [e.red, e.green, e.blue] { bytes += [UInt8(c >> 8), UInt8(c & 0xff)] }
        }
        return bytes
    }

    // MARK: - ScreenRenderer

    func testMainMenuScreenGolden() throws {
        let r = try renderer(clut: 0x80)       // a fresh surface under some other CLUT; the op sets 130
        try r.apply([.setScreenClut(id: 130), .drawPicture(id: 130, chain: .frontEnd, h: 0, v: 0)])
        XCTAssertEqual(r.surface.clut.id, 130)
        XCTAssertEqual(r.surface.gamma, .identity)
        // Self-derived golden (FE0 first green, 2026-10-14): FNV-1a 64 of the 640×480 indices followed by the CLUT's
        // 256 entries as 16-bit big-endian R, G, B — PICT 130 converted under clut 130 (`.ruled`, lowest tie-break,
        // error diffusion), then `.MTRedraw`'s Color2Index of each index's own colour.
        XCTAssertEqual(String(fnv1a(image(r.surface)), radix: 16), "ed142fed9e3bdce7")
        XCTAssertGreaterThan(Set(r.surface.frame.pixels).count, 16)          // a picture, not a flat fill
    }

    func testStretchedPanelRows() throws {
        let src = Rect16(top: 0, left: 0, bottom: 110, right: 320)
        func panel(_ s: Int) throws -> ScreenRenderer {
            let r = try renderer()
            try r.apply([.copyPicture(id: 140, chain: .frontEnd, source: src,
                                      dest: Rect16(top: Int16(150 + s), left: 160, bottom: Int16(260 - s), right: 480),
                                      forceClut: nil, transparent: false)])
            return r
        }
        let full = try panel(0)
        // Recorded (self-derived): dest row y samples source row y · 110 / h.
        let expected: [Int: [Int]] = [
            52: [0, 18, 36, 55, 73, 91],
            26: ScreenRenderer.sampleRows(source: 110, dest: 58),
            0: Array(0..<110),
        ]
        XCTAssertEqual(Array(ScreenRenderer.sampleRows(source: 110, dest: 58).prefix(8)), [0, 1, 3, 5, 7, 9, 11, 13])
        XCTAssertEqual(ScreenRenderer.sampleRows(source: 110, dest: 58).last, 108)
        for s in [52, 26, 0] {
            let rows = ScreenRenderer.sampleRows(source: 110, dest: 110 - 2 * s)
            XCTAssertEqual(rows.count, [52: 6, 26: 58, 0: 110][s])
            XCTAssertEqual(rows, expected[s])
            let r = try panel(s)
            for (dy, sy) in rows.enumerated() {
                for x in 160..<480 {
                    XCTAssertEqual(r.surface.frame[x, 150 + s + dy], full.surface.frame[x, 150 + sy],
                                   "s \(s) row \(dy) x \(x)")
                    if r.surface.frame[x, 150 + s + dy] != full.surface.frame[x, 150 + sy] { return }
                }
            }
            // Outside the dest rect the fresh surface is untouched.
            XCTAssertEqual(r.surface.frame[159, 150 + s], 0)
            XCTAssertEqual(r.surface.frame[160, 149 + s], 0)
            XCTAssertEqual(r.surface.frame[160, 260 - s], 0)
        }
        // The panel is not one flat colour (the comparison above means something).
        XCTAssertGreaterThan(Set((160..<480).map { full.surface.frame[$0, 200] }).count, 1)
    }

    func testTransparentCopySkipsWhite() throws {
        let r = try renderer()
        let c200 = try ColorLUT.load(id: 200, from: try Self.resources.get(), chain: .frontEnd)
        XCTAssertEqual(RGB16(c200.entries[0]), RGB16(0xffff, 0xffff, 0xffff))     // clut 200 entry 0 is white
        let others: [UInt8] = [0x23, 0x60, 0x05]
        for i in others { XCTAssertNotEqual(RGB16(c200.entries[Int(i)]), RGB16(0xffff, 0xffff, 0xffff)) }
        let picture = try ConvertedPicture(id: 0, width: 2, height: 2, pixels: [0] + others, clutId: 200)
        let src = Rect16(top: 0, left: 0, bottom: 2, right: 2), dst = Rect16(top: 10, left: 20, bottom: 12, right: 22)
        func colour(_ i: UInt8) -> UInt8 { r.search.index(of: RGB16(c200.entries[Int(i)]), in: r.surface.clut) }

        r.surface.frame = IndexedFrame(fill: 0x33)
        r.copyBits(picture, clut: c200, source: src, dest: dst, transparent: true)
        XCTAssertEqual(r.surface.frame[20, 10], 0x33)                          // the white pixel: skipped
        XCTAssertEqual([r.surface.frame[21, 10], r.surface.frame[20, 11], r.surface.frame[21, 11]], others.map(colour))
        XCTAssertEqual(r.surface.frame[22, 10], 0x33)
        XCTAssertEqual(r.surface.frame[19, 10], 0x33)

        r.surface.frame = IndexedFrame(fill: 0x33)
        r.copyBits(picture, clut: c200, source: src, dest: dst, transparent: false)
        XCTAssertEqual(r.surface.frame[20, 10], colour(0))                     // srcCopy: white is drawn
        XCTAssertNotEqual(colour(0), 0x33)
    }

    // MARK: - ScreenFade

    func testGammaFadeOutTimeline() throws {
        // `.GammaFadeOut`'s ms in the binary's order (BC28): n 3 → 230, not 231.
        XCTAssertEqual([3, 6, 10, 12, 30].map(ScreenFade.fadeOutMilliseconds), [230, 500, 885, 1039, 2656])
        XCTAssertEqual([230, 500, 885, 2656].map { ScreenFade.ticks(milliseconds: $0) }, [14, 30, 54, 160])

        var f = ScreenFade()
        f.noAsyncFade = false
        let black = RGB16(0, 0, 0)
        let tl = f.gammaFadeOut(6, rgb: black)
        XCTAssertEqual(tl.duration, 30)
        XCTAssertEqual(tl.events.map(\.at), Array(0..<30))
        let percents = tl.events.map { e -> Int in
            guard e.output.draws.count == 1, case .screenGamma(.tint(3, let p)) = e.output.draws[0] else { return -1 }
            return p
        }
        // Self-derived: min(100, trunc(100 · (k + 1) ticks / 500 ms)).
        XCTAssertEqual(Array(percents.prefix(6)), [3, 6, 10, 13, 16, 20])
        XCTAssertEqual(percents.last, 100)
        XCTAssertEqual(percents, percents.sorted())
        XCTAssertTrue(f.faded)
        XCTAssertTrue(f.noAsyncFade)                                           // 53d6 = 1 (M l. 31799)
        XCTAssertEqual(f.asyncColour, black)
        XCTAssertEqual(f.gammaFadeOut(6, rgb: black), .none)                   // already faded: no-op
        var g = ScreenFade()
        XCTAssertEqual(g.gammaFadeOut(3, rgb: black).duration, 14)             // 230 ms → 14 ticks
        var off = ScreenFade()
        off.fadingEnabled = false
        XCTAssertEqual(off.gammaFadeOut(6, rgb: black), .none)
        XCTAssertFalse(off.faded)

        // `.TintFadeProc` mode 3 at t = 0.4: red first — R 0, G 0.46, B 0.6 (t rounded to single precision).
        let k = ScreenGamma.tintFactors(mode: 3, percent: 40)
        XCTAssertEqual(k[0], 0)
        XCTAssertEqual(k[1], 0.46, accuracy: 1e-6)
        XCTAssertEqual(k[2], 0.6, accuracy: 1e-6)
        XCTAssertLessThan(k[2], 0.6)                                           // Float(0.4) > 0.4
        let r = try renderer()
        try r.apply([.screenGamma(.tint(mode: 3, percent: 40))])
        let white = r.surface.presentedClut.entries[0]
        XCTAssertEqual(RGB16(r.surface.clut.entries[0]), RGB16(0xffff, 0xffff, 0xffff))
        XCTAssertEqual([white.red, white.green, white.blue], [0, 30146, 39320])
        // The replica scales the unfaded table each tick: 40 % twice is still 40 %.
        try r.apply([.screenGamma(.tint(mode: 3, percent: 40))])
        XCTAssertEqual(r.surface.presentedClut.entries[0].blue, 39320)
        // Driven by ticks: the run blocks for 30 ticks, one op per tick.
        var run = TimelineRun(tl, start: 0xffff_fff0)
        XCTAssertEqual(run.tick(now: 0xffff_fff0).draws.count, 1)
        XCTAssertFalse(run.isDone(now: 0xffff_fff0))
        XCTAssertEqual(run.tick(now: 0xffff_fff0 &+ 29).draws.count, 29)
        XCTAssertTrue(run.isDone(now: 0xffff_fff0 &+ 30))
        XCTAssertFalse(run.isDone(now: 0xffff_fff0 &+ 29))
    }

    func testGammaFadeInSteps() throws {
        XCTAssertEqual(ScreenFade.fadeInPercents(6),
                       [0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18])
        XCTAssertEqual(ScreenFade.fadeInPercents(15).count, 51)               // s = 100 / 45 = 2

        var f = ScreenFade()
        XCTAssertEqual(f.gammaFadeIn(6), .none)                                // not faded: no-op
        f.faded = true
        let tl = f.gammaFadeIn(6)
        XCTAssertFalse(f.faded)
        XCTAssertEqual(tl.duration, 21)
        XCTAssertEqual(tl.events.count, 22)
        for (k, p) in ScreenFade.fadeInPercents(6).enumerated() {
            XCTAssertEqual(tl.events[k].at, k)
            XCTAssertEqual(tl.events[k].output, FrontOutput(draws: [.screenGamma(.fadeToColor(percent: p, rgb: nil))]))
        }
        XCTAssertEqual(tl.events[21].at, 21)
        XCTAssertEqual(tl.events[21].output, FrontOutput(draws: [.screenGamma(.fadeToColor(percent: 100, rgb: nil))],
                                                         requests: [.showCursor]))
        var g = ScreenFade()
        g.faded = true
        let t15 = g.gammaFadeIn(15)
        XCTAssertEqual(t15.duration, 51)
        XCTAssertEqual(t15.events.count, 52)

        // `.GammaFadeInSlow(0x37)` → 1815 ms → 109 ticks, then the snap; < 0x65 ms → 100.
        XCTAssertEqual(ScreenFade.fadeInSlowMilliseconds(0x37), 1815)
        XCTAssertEqual(ScreenFade.fadeInSlowMilliseconds(3), 100)
        var h = ScreenFade()
        h.faded = true
        let slow = h.gammaFadeInSlow(0x37)
        XCTAssertEqual(slow.duration, 109)
        XCTAssertEqual(slow.events.last?.output.draws, [.screenGamma(.fadeToColor(percent: 100, rgb: nil))])
        XCTAssertEqual(slow.events.last?.output.requests, [])

        // On the surface: the compounding steps after a fade-out to black, then the snap to the original gamma.
        let r = try renderer()
        try r.apply([.screenGamma(.tint(mode: 3, percent: 100))])
        XCTAssertEqual(r.surface.presentedClut.entries[0].blue, 0)
        for e in tl.events.dropLast() { try r.apply(e.output.draws) }
        XCTAssertLessThan(r.surface.presentedClut.entries[0].blue, 0xffff)
        try r.apply(tl.events[21].output.draws)
        XCTAssertEqual(r.surface.gamma.apply(r.surface.clut), r.surface.clut)
        XCTAssertEqual(r.surface.presentedClut.entries[0].red, 0xffff)
    }

    // MARK: - MusicFade

    func testMusicFadeVolumes() throws {
        var prefs = FerazelPrefs()
        prefs.musicVolume = 9
        XCTAssertEqual(MusicFade.fullVolume(prefs), 256)
        var m = MusicFade()
        XCTAssertEqual(m.setAIFFMusic(-1), [])                                 // nothing at all, not even .stop
        XCTAssertFalse(m.loaded)
        XCTAssertEqual(m.currentTrack, -1)
        XCTAssertEqual(m.fadeAIFFMusic(direction: 1, ticks: 4, prefs: prefs), .none)   // nothing loaded
        XCTAssertEqual(m.setAIFFMusic(24), [.stop, .play(track: 24)])
        XCTAssertEqual(m.currentTrack, 24)
        XCTAssertTrue(m.musicFaded)                                            // *0448 = 1: starts silent
        XCTAssertEqual(m.setAIFFMusic(40), [.stop, .play(track: 1)])           // > 32 → 1
        XCTAssertEqual(m.setAIFFMusic(24), [.stop, .play(track: 24)])

        // In, t 4: 24 cues 0, 10, 21 … 245 at ticks 0, 4 … 92, then 256 at 96.
        XCTAssertEqual(m.fadeAIFFMusic(direction: 0, ticks: 4, prefs: prefs), .none)   // out while faded: no-op
        let fadeIn = m.fadeAIFFMusic(direction: 1, ticks: 4, prefs: prefs)
        XCTAssertFalse(m.musicFaded)
        XCTAssertEqual(fadeIn.duration, 96)
        XCTAssertEqual(fadeIn.events.map(\.at), Array(stride(from: 0, through: 96, by: 4)))
        let inVolumes = fadeIn.events.flatMap(\.output.music)
        XCTAssertEqual(inVolumes.count, 25)
        XCTAssertEqual(inVolumes, (0..<24).map { MusicCue.volume(256 * $0 / 24) } + [.volume(256)])
        XCTAssertEqual(Array(inVolumes.prefix(3)), [.volume(0), .volume(10), .volume(21)])
        XCTAssertEqual(inVolumes[23], .volume(245))
        XCTAssertEqual(m.volume, 256)
        XCTAssertEqual(m.fadeAIFFMusic(direction: 1, ticks: 4, prefs: prefs), .none)   // already unfaded

        // Out, t 2: 256 · (24 − s) / 24 at ticks 0, 2 … 46, then 0 at 48.
        let fadeOut = m.fadeAIFFMusic(direction: 0, ticks: 2, prefs: prefs)
        XCTAssertTrue(m.musicFaded)
        XCTAssertEqual(fadeOut.duration, 48)
        XCTAssertEqual(fadeOut.events.flatMap(\.output.music),
                       (0..<24).map { MusicCue.volume(256 * (24 - $0) / 24) } + [.volume(0)])
        XCTAssertEqual(Array(fadeOut.events.flatMap(\.output.music).prefix(2)), [.volume(256), .volume(245)])
        XCTAssertEqual(m.volume, 0)
        XCTAssertEqual(m.fadeAIFFMusic(direction: 0, ticks: 2, prefs: prefs), .none)   // already faded

        // Music off (prefs+0x0c = 0): no fade.
        var off = prefs
        off.musicOn = 0
        XCTAssertEqual(m.fadeAIFFMusic(direction: 1, ticks: 4, prefs: off), .none)
        XCTAssertTrue(m.musicFaded)

        // Driven by ticks: the in-fade's cue at tick 92 only once tick 92 comes.
        m.musicFaded = true
        var run = TimelineRun(m.fadeAIFFMusic(direction: 1, ticks: 4, prefs: prefs), start: 1000)
        XCTAssertEqual(run.tick(now: 1000).music, [.volume(0)])
        XCTAssertEqual(run.tick(now: 1003).music, [])
        XCTAssertEqual(run.tick(now: 1004).music, [.volume(10)])
        XCTAssertEqual(run.tick(now: 1095).music.count, 22)
        XCTAssertFalse(run.isDone(now: 1095))
        XCTAssertEqual(run.tick(now: 1096).music, [.volume(256)])
        XCTAssertTrue(run.isDone(now: 1096))

        // The async fade-in (raw `10049c5c`): *0448 cleared at the start, `SetMovieVolume(0)`, then V·i/N per frame
        // until i > N, ending at V.
        m.musicFaded = true
        XCTAssertEqual(m.fadeAIFFMusicAsync(direction: 1, frames: 3, prefs: prefs), [.volume(0)])
        XCTAssertFalse(m.musicFaded)
        let frames = (0..<5).map { _ in m.handleAsyncFade(prefs: prefs) }
        XCTAssertEqual(frames, [[.volume(0)], [.volume(85)], [.volume(170)], [.volume(256)], []])
        XCTAssertTrue(m.asyncDone)
        XCTAssertEqual(m.volume, 256)
    }
}
