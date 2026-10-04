import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import XCTest

/// R1 follow-up: the five front-end `DrawOp`s C6 added.
final class FrontEndOpTests: XCTestCase {
    private func make() throws -> (ArtBank, Compositor) {
        let art = ArtBank(data: try RenderTestData.gameData())
        return (art, Compositor(art: art, text: StubRasterizer()))
    }

    func testCompToSpriteWorldStashAndBack() throws {
        let (art, c) = try make()
        let p = try art.pict(912)
        c.apply(.drawMaze(pictID: 912))
        let lettersBefore = c.spriteWorld[7, 10]
        // `_DrawMainMenu`'s stash: gTextRect (comp) → gSrcTextRect (sprite GWorld rows 92…112).
        c.apply(.compToSpriteWorld(src: Compositor.textRect, dst: Compositor.srcTextRect))
        XCTAssertEqual(c.spriteWorld[0, 92], p[157, 425])
        XCTAssertEqual(c.spriteWorld[324, 111], p[481, 444])
        XCTAssertEqual(c.spriteWorld[7, 10], lettersBefore)                   // the Letters strips untouched
        // …and back (`_SpriteGWorldToCompGWorld`), onto a black comp: only the rect returns.
        c.apply([.fillBlack(target: .comp), .spriteWorldToComp(src: Compositor.srcTextRect, dst: Compositor.textRect)])
        XCTAssertEqual(c.comp[157, 425], p[157, 425])
        XCTAssertEqual(c.comp[481, 444], p[481, 444])
        XCTAssertEqual(c.comp[156, 425], RGBAImage.opaqueBlack)
        XCTAssertEqual(c.comp[157, 445], RGBAImage.opaqueBlack)
    }

    func testCompToBgndCopiesOnlyRect() throws {
        let (art, c) = try make()
        let p = try art.pict(912)
        c.apply([.drawMaze(pictID: 912), .fillBlack(target: .comp)])
        c.apply(.compToBgnd(QDRect(top: 50, left: 60, bottom: 70, right: 90)))
        XCTAssertEqual(c.bgnd[60, 50], RGBAImage.opaqueBlack)
        XCTAssertEqual(c.bgnd[89, 69], RGBAImage.opaqueBlack)
        XCTAssertEqual(c.bgnd[90, 60], p[90, 60])
        XCTAssertEqual(c.bgnd[60, 70], p[60, 70])
    }

    func testWipeOutCentreBandsStep4() throws {
        let (_, c) = try make()
        XCTAssertEqual(Compositor.wipeOutSteps(4), 63)
        XCTAssertEqual(Compositor.wipeOutSteps(12), 23)
        c.apply([.drawMaze(pictID: 912), .fillBlack(target: .screen), .wipeOut(step: 4)])
        // The initial pair: rows 236…243 revealed, 235 and 244 still black.
        XCTAssertEqual(c.screen[100, 236], c.comp[100, 236])
        XCTAssertEqual(c.screen[100, 243], c.comp[100, 243])
        XCTAssertEqual(c.screen[100, 235], RGBAImage.opaqueBlack)
        XCTAssertEqual(c.screen[100, 244], RGBAImage.opaqueBlack)
        for row in 1...10 { c.applyWipeOut(row: row) }
        XCTAssertEqual(c.screen[100, 196], c.comp[100, 196])
        XCTAssertEqual(c.screen[100, 283], c.comp[100, 283])
        XCTAssertEqual(c.screen[100, 195], RGBAImage.opaqueBlack)
        XCTAssertEqual(c.screen[100, 284], RGBAImage.opaqueBlack)
        for row in 11...63 { c.applyWipeOut(row: row) }                        // the last bands are fully clipped
        XCTAssertEqual(c.screen, c.comp)
    }

    func testFillRectSolidAndOnePixel() throws {
        let (_, c) = try make()
        c.apply([.fillBlack(target: .screen), .fillRect(QDRect(top: 10, left: 20, bottom: 14, right: 30), rgb: 0x336699,
                                                        target: .screen)])
        XCTAssertEqual(c.screen[20, 10], 0xFF33_6699)
        XCTAssertEqual(c.screen[29, 13], 0xFF33_6699)
        XCTAssertEqual(c.screen[30, 13], RGBAImage.opaqueBlack)
        XCTAssertEqual(c.screen[29, 14], RGBAImage.opaqueBlack)
        // A 1 × 1 rect = one pixel (the progress bar's `_SetCPixel` corners).
        c.apply(.fillRect(QDRect(top: 100, left: 100, bottom: 101, right: 101), rgb: 0xFFFFFF, target: .comp))
        XCTAssertEqual(c.comp[100, 100], 0xFFFF_FFFF)
        XCTAssertNotEqual(c.comp[101, 100], 0xFFFF_FFFF)
        XCTAssertNotEqual(c.comp[100, 101], 0xFFFF_FFFF)
    }

    func testStringPlacementsWithoutArrayMatchLayout() throws {
        let (_, c) = try make()
        let font = c.letters
        for (text, pitch) in [("HIGH SCORES", nil as Int?), ("12345", 15), ("Élan", nil)] {
            var walked: [LettersFont.Placement] = []
            font.forEachPlacement(text, h: -1, v: 30, highlighted: true, fixedPitch: pitch) { walked.append($0) }
            XCTAssertEqual(walked, font.layout(text, h: -1, v: 30, highlighted: true, fixedPitch: pitch), text)
        }
    }
}
