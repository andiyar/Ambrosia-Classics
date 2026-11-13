import XCTest
@testable import DeimosCore
@testable import DeimosRender

/// R4 — the particle stamp `FUN_10043ba0` (particles-debris-blur §2.9; listing `10043ba0..10044500`).
final class ParticleStampTests: XCTestCase {

    /// `dst' = (dst·w + col·(32 − w)) >> 5` in the spread-555 form (`10043da8..10043dd4`): white under black at
    /// w 16 is half grey per channel, 15/15/15 = 0x3DEF.
    func testStampKernelSpread555() {
        XCTAssertEqual(ParticleStamps.blend(dst: 0x7FFF, colour: 0, weight: 16), 0x3DEF)
        XCTAssertEqual(ParticleStamps.blend(dst: 0x7FFF, colour: 0, weight: 32), 0x7FFF)
        XCTAssertEqual(ParticleStamps.blend(dst: 0x7FFF, colour: 0x1234, weight: 0), 0x1234)
    }

    /// The 7×7 weight table of §2.9 at f = 0, 7 and 26 (A/B/C all at the 31 cap), and at f = −1 (the unsigned
    /// `cmplwi` caps see 0xFFFFFFFF: the adds wrap to A 21, B 9, C 5; D/E weigh 0xFFFFFFFF, X 0xFFFFFFF8), stamped
    /// top-left at (x, y) into the back buffer. D pixels take the FRINGE colour (`10044014..10044034` blends
    /// r11 = fringe·(32 − f)); E and X the core (spread from `10044040`). Pixels outside the square are untouched;
    /// a square that does not fit the 640×480 buffer is skipped (x = W − 7 drawn, W − 6 not; the y twin).
    func testStampPatternAtFade0And7() throws {
        let pattern = ["AABBBAA", "ABCCCBA", "BCDEDCB", "BCEXECB", "BCDEDCB", "ABCCCBA", "AABBBAA"]
        let dst: UInt16 = 0x4210, core: UInt16 = 0x7A5E, fringe: UInt16 = 0x0123
        let cases: [(fade: Int32, x: Int32, y: Int32, w: [Character: UInt32])] = [
            (0, 100, 50, ["A": 22, "B": 10, "C": 6, "D": 0, "E": 0, "X": 0]),
            (7, 3, 9, ["A": 29, "B": 17, "C": 13, "D": 7, "E": 7, "X": 0]),
            (26, 200, 300, ["A": 31, "B": 31, "C": 31, "D": 26, "E": 26, "X": 19]),
            (-1, 400, 100, ["A": 21, "B": 9, "C": 5, "D": 0xFFFF_FFFF, "E": 0xFFFF_FFFF, "X": 0xFFFF_FFF8]),
        ]
        for c in cases {
            let (fade, x, y) = (c.fade, c.x, c.y)
            let r = DeimosRenderer(assets: try ShippedAssets.get())
            r.apply(.fill(.back, colour: dst))
            r.apply(.particles([ParticleStamp(x: x, y: y, core: core, fringe: fringe, fade: fade)]))
            for (row, line) in pattern.enumerated() {
                for (col, letter) in line.enumerated() {
                    let colour = (letter == "E" || letter == "X") ? core : fringe
                    let w = c.w[letter]!
                    let got = r.buffer(.back)[Int(x) + col, Int(y) + row]
                    XCTAssertEqual(got, Self.spreadWord(dst, colour, w), "f \(fade) row \(row) col \(col) (\(letter))")
                    if w <= 32 {
                        XCTAssertEqual(got, Self.perChannel(dst, colour, Int(w)), "f \(fade) row \(row) col \(col)")
                    }
                }
            }
            if fade == 0 {   // D is the fringe, E/X the core
                XCTAssertEqual(r.buffer(.back)[Int(x) + 2, Int(y) + 2], fringe)
                XCTAssertEqual(r.buffer(.back)[Int(x) + 3, Int(y) + 2], core)
            }
            if fade == 7 { XCTAssertEqual(r.buffer(.back)[Int(x) + 3, Int(y) + 3], core, "X snaps back solid") }
            // Untouched around the square.
            XCTAssertEqual(r.buffer(.back)[Int(x) + 7, Int(y) + 3], dst)
            XCTAssertEqual(r.buffer(.back)[Int(x) + 3, Int(y) + 7], dst)
            XCTAssertEqual(r.buffer(.back)[Int(x) - 1, Int(y)], dst)
        }

        // The fit guard: the last column / row that fits is drawn, one further is skipped.
        let r = DeimosRenderer(assets: try ShippedAssets.get())
        r.apply(.fill(.back, colour: dst))
        let (W, H) = (Int32(r.buffer(.back).width), Int32(r.buffer(.back).height))
        let blank = r.buffer(.back)
        for (x, y) in [(W - 6, 10), (10, H - 6), (-1, 10), (10, -1)] {
            r.apply(.particles([ParticleStamp(x: x, y: y, core: core, fringe: fringe, fade: 0)]))
            XCTAssertEqual(r.buffer(.back), blank, "stamp at (\(x), \(y)) is skipped")
        }
        r.apply(.particles([ParticleStamp(x: W - 7, y: 10, core: core, fringe: fringe, fade: 0)]))
        XCTAssertEqual(r.buffer(.back)[Int(W) - 1, 13], Self.perChannel(dst, fringe, 10), "x = W − 7 drawn (col 6 B)")
        r.apply(.particles([ParticleStamp(x: 10, y: H - 7, core: core, fringe: fringe, fade: 0)]))
        XCTAssertEqual(r.buffer(.back)[13, Int(H) - 1], Self.perChannel(dst, fringe, 10), "y = H − 7 drawn (row 6 B)")
    }

    /// The listing's word form, written out independently: spread `(c & 0x7c1f) | (c & 0x3e0) << 15`, both `mullw`
    /// mod 2³², unpack `(s >> 5) & 0x7c1f | (s >> 20) & 0x3e0` (`10043da8…10043dd4`).
    private static func spreadWord(_ d: UInt16, _ c: UInt16, _ w: UInt32) -> UInt16 {
        func spread(_ v: UInt16) -> UInt32 { (UInt32(v) & 0x7c1f) | ((UInt32(v) & 0x3e0) << 15) }
        let sum = spread(d) &* w &+ spread(c) &* (32 &- w)
        return UInt16(((sum >> 5) & 0x7c1f) | ((sum >> 20) & 0x3e0))
    }

    /// The kernel computed independently per 5-bit channel: `⌊(d·w + c·(32 − w))/32⌋`.
    private static func perChannel(_ d: UInt16, _ c: UInt16, _ w: Int) -> UInt16 {
        var out: UInt16 = 0
        for s: UInt16 in [0, 5, 10] {
            out |= UInt16((Int((d >> s) & 0x1f) * w + Int((c >> s) & 0x1f) * (32 - w)) >> 5) << s
        }
        return out
    }

    /// Every `RenderOp` case is listed (the exhaustive switch below fails to compile when a case is added);
    /// `isHostOp` is true for exactly `.fade`, `.limit`, `.pauseWait`, and every other op applies on a fresh
    /// renderer without trapping. The host ops are not sent (`apply` traps on them by contract).
    func testIsHostOpMatchesRendererTraps() throws {
        let assets = try ShippedAssets.get()
        let level = try XCTUnwrap(assets.definitions.levels.first)
        var cost = DrawCommand.template
        cost.face = FourCC("COST")!
        cost.costRect = MacRect(top: 10, left: 10, bottom: 20, right: 20)
        cost.costColour = 0x1111
        cost.drawNow = true
        let rect = MacRect(top: 0, left: 0, bottom: 10, right: 10)
        let all: [RenderOp] = [
            .loadTerrain(image: level.backgroundImage),
            .fill(.back, colour: 0x0421),
            .loadImage(image: ScoreBarDraw.image, into: .scoreSave, dst: ScoreBarDraw.saveBounds),
            .copy(from: .back, to: .scoreSave, src: rect, dst: rect, interlaced: false),
            .draw(cost),
            .clearLayers,
            .flushLayers(6...15),
            .screenBlit(src: rect, dst: rect),
            .fade(.toBlack, .gameScreen),
            .limit,
            .present(.gameScreen),
            .particles([ParticleStamp(x: 0, y: 0, core: 0x7FFF, fringe: 0x03E0, fade: 4)]),
            .pauseWait(.gameScreen),
        ]
        func name(_ op: RenderOp) -> String {
            switch op {
            case .loadTerrain: return "loadTerrain"
            case .fill: return "fill"
            case .loadImage: return "loadImage"
            case .copy: return "copy"
            case .draw: return "draw"
            case .clearLayers: return "clearLayers"
            case .flushLayers: return "flushLayers"
            case .screenBlit: return "screenBlit"
            case .fade: return "fade"
            case .limit: return "limit"
            case .present: return "present"
            case .particles: return "particles"
            case .pauseWait: return "pauseWait"
            }
        }
        XCTAssertEqual(Set(all.map(name)).count, 13, "one instance of every case")
        XCTAssertEqual(Set(all.filter(RenderOp.isHostOp).map(name)), ["fade", "limit", "pauseWait"])

        let r = DeimosRenderer(assets: assets)
        for op in all where !RenderOp.isHostOp(op) { r.apply(op) }
        XCTAssertNotEqual(r.buffer(.back)[0, 0], 0x0421, "the particle stamp reached the back buffer")
    }
}
