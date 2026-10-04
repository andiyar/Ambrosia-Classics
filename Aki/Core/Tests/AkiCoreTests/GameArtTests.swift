import Foundation
import XCTest
@testable import AkiCore

/// P2.8 — the game screen's `_SetRect` transcriptions (R2/R3/R4; sheet layouts assets-census §1).
final class GameArtTests: XCTestCase {

    private func r(_ l: Int, _ t: Int, _ rr: Int, _ b: Int) -> QDRect { QDRect(left: l, top: t, right: rr, bottom: b) }

    func testTileRowsAndFaceRects() {
        XCTAssertEqual(AkiGameArt.facePicture(200), r(0, 0, 38, 50))
        XCTAssertEqual(AkiGameArt.facePicture(241), r(0, 2050, 38, 2100))
        XCTAssertEqual(AkiGameArt.fadeMask(10), r(0, 966, 53, 1035))
    }

    func testTileRectsFromABox() {
        let box = r(377, 440, 428, 500)
        XCTAssertEqual(AkiGameArt.tileRect(box), r(377, 440, 430, 509))
        XCTAssertEqual(AkiGameArt.tileWindowRect(box), r(377, 441, 428, 507))
        XCTAssertEqual(AkiGameArt.bufferRestore(box), r(324, 371, 430, 509))
    }

    func testStoneLayout() {
        XCTAssertNil(AkiGameArt.timeBarStones(raw: 0, length: 0))

        let l0 = AkiGameArt.timeBarStones(raw: 1, length: 0)
        XCTAssertEqual(l0?.k, 0)
        XCTAssertNil(l0?.fullDestination)
        XCTAssertEqual(l0?.capDestination, r(144, 552, 169, 591))
        XCTAssertEqual(l0?.capMask, r(128, 156, 153, 195))

        let l11 = AkiGameArt.timeBarStones(raw: 1, length: 11)
        XCTAssertEqual(l11?.k, 0)
        XCTAssertEqual(l11?.capMask, r(3, 117, 28, 156))

        XCTAssertEqual(AkiGameArt.timeBarStones(raw: 1, length: 23)?.capMask, r(3, 195, 28, 234))

        let l24 = AkiGameArt.timeBarStones(raw: 1, length: 24)
        XCTAssertEqual(l24?.k, 1)
        XCTAssertEqual(l24?.fullDestination, r(144, 552, 169, 591))
        XCTAssertEqual(l24?.capMask, r(128, 156, 153, 195))
        XCTAssertEqual(l24?.fullSource, r(3, 39, 28, 78))
        XCTAssertEqual(l24?.fullMask, r(3, 78, 28, 117))
        XCTAssertEqual(l24?.capSource, r(28, 39, 53, 78))

        let l225 = AkiGameArt.timeBarStones(raw: 1, length: 225)
        XCTAssertEqual(l225?.k, 9)
        XCTAssertEqual(l225?.capMask, r(53, 117, 78, 156))
        XCTAssertEqual(l225?.fullSource, r(3, 39, 228, 78))
        XCTAssertEqual(l225?.fullDestination, r(144, 552, 369, 591))
        XCTAssertEqual(l225?.fullMask, r(3, 78, 228, 117))

        let l450 = AkiGameArt.timeBarStones(raw: 1, length: 450)
        XCTAssertEqual(l450?.k, 17)
        XCTAssertEqual(l450?.capMask, r(3, 195, 28, 234))
    }

    func testDigitsAndPairs() {
        let d0 = AkiGameArt.digit(0)
        XCTAssertEqual(d0.src, r(155, 387, 179, 417))
        XCTAssertEqual(d0.mask, r(180, 387, 204, 417))
        let d1 = AkiGameArt.digit(1)
        XCTAssertEqual(d1.src, r(155, 117, 179, 147))
        XCTAssertEqual(d1.mask, r(180, 117, 204, 147))
        XCTAssertEqual(AkiGameArt.colon, r(155, 417, 179, 447))
        XCTAssertEqual(AkiGameArt.colonMask, r(180, 417, 204, 447))
        let h0 = AkiGameArt.pairsHundredsDigit(0)
        XCTAssertEqual(h0.src, r(155, 87, 179, 117))
        XCTAssertEqual(h0.mask, r(180, 87, 204, 117))
    }

    func testButtonsAndFlash() {
        XCTAssertEqual(AkiGameArt.pressedRestoreSource(3), r(8, 10, 62, 64))
        XCTAssertEqual(AkiGameArt.pressedRestoreDestination(3), r(15, 542, 69, 596))
        let f5 = AkiGameArt.flash(5)
        XCTAssertEqual(f5.spriteSource, AkiGameArt.pausedSprite)
        XCTAssertEqual(f5.window, r(90, 549, 135, 594))

        var phase = AkiGameArt.FlashPhase()
        XCTAssertEqual(phase, AkiGameArt.FlashPhase(rising: true, p: 2))
        var seen: [Int] = []
        for _ in 0..<10 { phase.step(); seen.append(phase.p) }
        XCTAssertEqual(seen, [3, 4, 5, 6, 5, 4, 3, 2, 1, 2])
    }

    func testSlides() {
        XCTAssertEqual([0, 30, 45, 60].map { AkiGameArt.slideIn(ticks: $0) }, [0, 200, 300, 400])
        XCTAssertEqual([0, 30, 60].map { AkiGameArt.slideOut(ticks: $0) }, [400, 200, 0])
        XCTAssertEqual(AkiGameArt.slideIn(ticks: -1), 400)
        XCTAssertEqual(AkiGameArt.slideOut(ticks: -1), 0)
        let rects = AkiGameArt.slideRects(100)
        XCTAssertEqual(rects.count, 3)
        XCTAssertEqual(rects[0].src, r(100, 0, 400, 600)); XCTAssertEqual(rects[0].dst, r(0, 0, 300, 600))
        XCTAssertEqual(rects[1].src, r(300, 0, 500, 600)); XCTAssertEqual(rects[1].dst, r(300, 0, 500, 600))
        XCTAssertEqual(rects[2].src, r(400, 0, 700, 600)); XCTAssertEqual(rects[2].dst, r(500, 0, 800, 600))
    }

    func testOverlaysPlateAndBar() {
        XCTAssertEqual(AkiGameArt.plateDestination, r(7, 532, 793, 600))
        XCTAssertEqual(AkiGameArt.plateMask.left, 786)
        XCTAssertEqual(AkiGameArt.plateMask.right, 1572)
        XCTAssertEqual(AkiGameArt.overlayDestination, r(296, 26, 504, 506))
        XCTAssertEqual(AkiGameArt.timeBarWindow, r(141, 557, 597, 588))
    }
}
