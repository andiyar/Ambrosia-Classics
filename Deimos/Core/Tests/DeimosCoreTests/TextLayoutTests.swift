import XCTest
import HectorResources
@testable import DeimosCore

/// G_Text glyph map, digit cache and layout (text-metrics-lists.md §1–§2, hud-scorebar.md §9).
final class TextLayoutTests: XCTestCase {
    static let layout: Result<TextLayout, Error> = Result { try TextLayout(assets: PlayerPhase1Tests.loaded.get()) }

    func testGlyphMap() {
        let cases: [(UInt8, Int)] = [
            (UInt8(ascii: "A"), 0), (UInt8(ascii: "a"), 26), (UInt8(ascii: "1"), 52), (UInt8(ascii: "0"), 61),
            (UInt8(ascii: "("), 69), (UInt8(ascii: "["), 69), (UInt8(ascii: "{"), 69), (UInt8(ascii: " "), 90), (0x80, 90),
        ]
        for (c, f) in cases { XCTAssertEqual(GlyphMap.frame(c), f, "char \(c)") }
        XCTAssertEqual(GlyphMap.frame(UInt8(ascii: "~")), 89)
        XCTAssertEqual(GlyphMap.frame(0x7f), 90)
        XCTAssertEqual(GlyphMap.frame(0xff), 90)
    }

    func testDigitCacheQuirk() throws {
        let t = try Self.layout.get()
        XCTAssertEqual(t.font, FourCC("tesm"))
        XCTAssertEqual(t.frameSizes[52...61].map(\.width), [5, 6, 7, 7, 7, 7, 6, 7, 7, 7])
        XCTAssertEqual(t.frameSizes[52...61].map(\.height), Array(repeating: 13, count: 10))
        // First strictly widest digit frame is 54 ('3'), but the label is off by one → '2' (frame 53, 6 px).
        XCTAssertEqual(t.monoChar, UInt8(ascii: "2"))
        XCTAssertEqual(t.measure(t.monoChar, scale: 1).size.width, 6)
        XCTAssertEqual(t.digitMax, TextLayout.Size(width: 7, height: 13))
        // Space = frame 90, 4 px, never drawn; a byte ≥ 0x80 advances 0 at scale 1.
        XCTAssertEqual(t.measure(0x20, scale: 1).size, TextLayout.Size(width: 4, height: 13))
        XCTAssertEqual(t.measure(0x80, scale: 1).size, .zero)
        var f = TextFormat(text: [])
        f.locX = 10; f.locY = 20
        let cmds = t.draw(TextRequest(format: f, text: "1 1"))
        XCTAssertEqual(cmds.count, 2)
        // LEFT, spacing 0: '1' (5 px) at 10, space 4 px, '1' at 19.
        XCTAssertEqual(cmds.map { $0.x - Int32(5 / 2) }, [10, 19])
    }

    func testScoreAndLivesLayout() throws {
        let a = try PlayerPhase1Tests.loaded.get()
        let draw = try ScoreBarDraw(assets: a)
        let w = try PlayerPhase1Tests.World(assets: a, players: 1)
        let t = try Self.layout.get()
        func left(_ c: DrawCommand) -> Int32 { c.x - t.frameSizes[c.frame].width / 2 }
        func top(_ c: DrawCommand) -> Int32 { c.y - t.frameSizes[c.frame].height / 2 }

        // P1 score "0000000" (sbs1: CENT 494, mono cell 6 + spacing 4 → W 70, start 459).
        let score = draw.score(0, w.bar.records[0])
        XCTAssertEqual(score.count, 7)
        XCTAssertEqual(score.map(left), [463, 473, 483, 493, 503, 513, 523])
        for c in score {
            XCTAssertEqual(top(c), 83)
            XCTAssertEqual(c.frame, 61)
            XCTAssertEqual(c.face, FourCC("tesm"))
            XCTAssertEqual(c.flags, 4)
            XCTAssertEqual(c.colour, 0x4B7C)
            XCTAssertEqual(c.alpha, 0)
            XCTAssertTrue(c.drawNow)
            XCTAssertEqual(c.layer, 8)
            XCTAssertEqual(c.clip, EntityDraw.backBufferBounds)
        }
        XCTAssertEqual(t.layout(TextRequest(format: a.formats[43], text: "0000000"), draw: false).bounds.left, 459)

        // P1 lives "2" (3 lives − 1; sbl1 CENT 499 → start 496), frame 53.
        let lives = draw.livesCount(0, w.bar.records[0])
        XCTAssertEqual(lives.count, 1)
        XCTAssertEqual(left(lives[0]), 496)
        XCTAssertEqual(top(lives[0]), 50)
        XCTAssertEqual(lives[0].frame, 53)

        // P2 (not in game, dimmed): score at top 318, alpha 16; lives "0" at 495, top 285, alpha 16, normal format.
        let p2score = draw.score(1, w.bar.records[1])
        XCTAssertEqual(p2score.map(top), Array(repeating: 318, count: 7))
        XCTAssertEqual(p2score.map(\.alpha), Array(repeating: 16, count: 7))
        let p2lives = draw.livesCount(1, w.bar.records[1])
        XCTAssertEqual(p2lives.count, 1)
        XCTAssertEqual(left(p2lives[0]), 495)
        XCTAssertEqual(top(p2lives[0]), 285)
        XCTAssertEqual(p2lives[0].alpha, 16)
        XCTAssertEqual(p2lives[0].frame, 61)
        XCTAssertEqual(p2lives[0].colour, a.formats[46].coloriseColor)

        // Hud worked example: score 123456 → "0123456", same lefts; 2 lives → "1" at 496; 1 life → red "0".
        var r = w.bar.records[0]
        r.lastScore = 123456
        XCTAssertEqual(draw.score(0, r).map(\.frame), [61, 52, 53, 54, 55, 56, 57])
        XCTAssertEqual(draw.score(0, r).map(left), [463, 473, 483, 493, 503, 513, 523])
        r.lastLives = 2
        XCTAssertEqual(draw.livesCount(0, r).map(left), [496])
        r.lastLives = 1
        let last = draw.livesCount(0, r)
        XCTAssertEqual(last.map(\.frame), [61])
        XCTAssertEqual(last.map(\.colour), [0x7C00])
    }
}
