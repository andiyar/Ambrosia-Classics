import XCTest
import HectorResources
@testable import DeimosCore

/// G_Text glyph map, digit cache and layout (text-metrics-lists.md §1–§2, hud-scorebar.md §9).
final class TextLayoutTests: XCTestCase {
    static let layout: Result<TextLayout, Error> = Result { try TextLayout(assets: TestAssets.loaded.get()) }

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
        // LEFT, template spacing 1 (+0x11c), added before every char (`1000e598 add r28,r28,r27`): '1' (5 px)
        // at 10 + 1 = 11, space 4 px at 16 + 1 = 17, '1' at 21 + 1 = 22.
        XCTAssertEqual(cmds.map { $0.x - Int32(5 / 2) }, [11, 22])
    }

    /// RIGH / CEBU / CEGA (`FUN_1000e270`, hud-scorebar §9, text-metrics-lists §1.5): W = Σ (spacing + w) in
    /// single precision; RIGH start = fctiwz(X − W), CEBU fctiwz((F52 640 − W)·0.5), CEGA fctiwz((F54 416 − W)·0.5)
    /// (X ignored); bounds = (Y, start, Y + max h, x + 1).
    func testRightAndCentredAlignments() throws {
        let t = try Self.layout.get()
        XCTAssertEqual(t.floats[52], 640)
        XCTAssertEqual(t.floats[54], 416)
        var f = TextFormat(text: [])                                 // template: spacing 1
        f.locX = 100; f.locY = 20
        // "11": W = (1 + 5) + (1 + 5) = 12 → start 88; cells 89, 95; x ends at 100.
        f.format = .right
        let right = t.layout(TextRequest(format: f, text: "11"), draw: true)
        XCTAssertEqual(right.bounds, MacRect(top: 20, left: 88, bottom: 33, right: 101))
        XCTAssertEqual(right.commands.map(\.x), [89 + 2, 95 + 2])
        // "123": W = (1 + 5) + (1 + 6) + (1 + 7) = 21.
        f.format = .centerInBuffer                                   // (640 − 21)·0.5 = 309.5 → 309
        XCTAssertEqual(t.layout(TextRequest(format: f, text: "123"), draw: false).bounds,
                       MacRect(top: 20, left: 309, bottom: 33, right: 331))
        f.format = .centerInGameArea                                 // (416 − 21)·0.5 = 197.5 → 197
        XCTAssertEqual(t.layout(TextRequest(format: f, text: "123"), draw: false).bounds,
                       MacRect(top: 20, left: 197, bottom: 33, right: 219))
        f.format = .center                                           // 100 − 0.5·21 = 89.5 → 89
        XCTAssertEqual(t.layout(TextRequest(format: f, text: "123"), draw: false).bounds.left, 89)
    }

    /// The colour strip's grow and minimum width (text-metrics-lists §2.3, `1000d56c…1000d68c`): left −= H,
    /// right += H, top −= V, bottom += V; narrower than minW → LEFT right = left + minW, RIGH left = right − minW,
    /// CENT/CEBU/CEGA left = **Loc X** − minW/2; lower than minH → bottom = top + minH. Always queued.
    func testColourStripMinWidth() throws {
        let a = try TestAssets.loaded.get()
        let t = try Self.layout.get()
        // `meno` (format 35): LEFT at 30,10, H/V 3/3, minW 126, blend 16. "11" measures (10, 30, 23, 41).
        XCTAssertEqual(a.formatIDs[35], FourCC("meno"))
        let meno = t.draw(TextRequest(format: a.formats[35], text: "11"))
        XCTAssertEqual(meno.count, 3)
        XCTAssertEqual(meno[0].face, FourCC("COST"))
        XCTAssertEqual(meno[0].costRect, MacRect(top: 7, left: 27, bottom: 26, right: 27 + 126))
        XCTAssertEqual(meno[0].alpha, 16)
        XCTAssertFalse(meno[0].drawNow)
        // `brpr` (format 52): LEFT at 416,87, no grow, minW 0, blend 14 — the strip is the bounds.
        XCTAssertEqual(a.formatIDs[52], FourCC("brpr"))
        let brpr = t.draw(TextRequest(format: a.formats[52], text: "11"))
        XCTAssertEqual(brpr.first?.costRect, MacRect(top: 87, left: 416, bottom: 100, right: 427))
        XCTAssertEqual(brpr.first?.alpha, 14)
        // Template strip (H/V 3/3), minW 50, minH 20, "11" at X 100, Y 20 (W 12).
        var f = TextFormat(text: [])
        f.locX = 100; f.locY = 20
        f.colorStripDo = true
        f.colorStripMinWidth = 50
        f.colorStripMinHeight = 20
        f.format = .right                                            // (20, 88, 33, 101) → (17, 85, 36, 104)
        XCTAssertEqual(t.draw(TextRequest(format: f, text: "11")).first?.costRect,
                       MacRect(top: 17, left: 54, bottom: 37, right: 104))
        f.format = .centerInBuffer                                   // text at 314, strip at X − 25
        XCTAssertEqual(t.draw(TextRequest(format: f, text: "11")).first?.costRect,
                       MacRect(top: 17, left: 75, bottom: 37, right: 125))
    }

    func testScoreAndLivesLayout() throws {
        let a = try TestAssets.loaded.get()
        let draw = try ScoreBarDraw(assets: a)
        let w = try TestWorld(assets: a, players: 1)
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
