import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import XCTest

/// R1 fix round: the OS X targets (`_PlayGame` draws sprites and restores into the window), `screenToComp`, ghost
/// sprites, and the front-end ops.
final class RenderOpTests: XCTestCase {
    private func make() throws -> (ArtBank, Compositor) {
        let art = ArtBank(data: try RenderTestData.gameData())
        return (art, Compositor(art: art, text: StubRasterizer()))
    }

    private static let full = QDRect(top: 0, left: 0, bottom: 480, right: 640)

    func testScreenTargetsAndScreenToComp() throws {
        let (art, c) = try make()
        let p = try art.pict(912)
        c.apply([.drawMaze(pictID: 912), .fillBlack(target: .screen)])
        // `_RestoreBgnd(0)` on OS X → `_BgndToScreen`: the screen gets bgnd, comp is untouched.
        let compBefore = c.comp
        c.apply(.restoreBgnd(QDRect(top: 40, left: 40, bottom: 80, right: 80), target: .screen))
        XCTAssertEqual(c.screen[40, 40], p[40, 40])
        XCTAssertEqual(c.screen[80, 40], RGBAImage.opaqueBlack)
        XCTAssertEqual(c.comp, compBefore)
        // Sprites into the current port = screen.
        let icon = try art.cicn(25000)
        c.apply(.sprite(set: 1, frame: 1, h: 200, v: 200, mode: .normal, target: .screen))
        XCTAssertEqual(c.comp, compBefore)
        var drawn = 0
        for v in 0..<40 { for h in 0..<40 where icon[h, v] >> 24 != 0 {
            XCTAssertEqual(c.screen[200 + h, 200 + v], icon[h, v]); drawn += 1
        } }
        XCTAssertGreaterThan(drawn, 0)
        // `_ScreenToComp`: screen → comp over the rect only.
        c.apply(.screenToComp(QDRect(top: 200, left: 200, bottom: 240, right: 240)))
        XCTAssertEqual(c.comp[220, 220], c.screen[220, 220])
        XCTAssertEqual(c.comp[241, 220], compBefore[241, 220])
        // Defaults keep the comp path.
        XCTAssertEqual(DrawOp.restoreBgnd(Self.full), DrawOp.restoreBgnd(Self.full, target: .comp))
        XCTAssertEqual(DrawOp.sprite(set: 1, frame: 1, h: 0, v: 0, mode: .normal),
                       DrawOp.sprite(set: 1, frame: 1, h: 0, v: 0, mode: .normal, target: .comp))
    }

    func testGhostAndTranslucentDrawWhite() throws {
        let (art, c) = try make()
        // Set 2 (25100…) carries one pure-white masked pixel: 10.5+ draws it (white stays white when lightened).
        var white: (id: Int, h: Int, v: Int)?
        search: for k in 0..<8 {
            let id = 25100 + k, icon = try art.cicn(id)
            for v in 0..<icon.height { for h in 0..<icon.width where icon[h, v] == 0xFFFF_FFFF { white = (id, h, v); break search } }
        }
        let w = try XCTUnwrap(white)
        for mode in [DrawOp.SpriteMode.transparent, .ghost] {
            c.apply(.fillBlack(target: .comp))
            c.apply(.sprite(set: 2, frame: w.id - 25100 + 1, h: 100, v: 100, mode: mode))
            XCTAssertEqual(c.comp[100 + w.h, 100 + w.v], 0xFFFF_FFFF, "\(mode)")
            let icon = try art.cicn(w.id)
            for v in 0..<40 { for h in 0..<40 where icon[h, v] >> 24 != 0 {
                let p = icon[h, v]
                let want = 0xFF00_0000 | ((255 + (p >> 16 & 0xFF)) >> 1) << 16 | ((255 + (p >> 8 & 0xFF)) >> 1) << 8
                    | (255 + (p & 0xFF)) >> 1
                XCTAssertEqual(c.comp[100 + h, 100 + v], want)
            } }
        }
    }

    func testDarkenRectAndPatternOverlay() throws {
        let (_, c) = try make()
        c.apply([.drawMaze(pictID: 912)])
        let before = c.comp
        c.apply(.darkenRect(QDRect(top: 10, left: 10, bottom: 20, right: 30), target: .comp))
        let p = before[15, 15]
        let want = 0xFF00_0000 | QuickDrawColour.blendTowardBlack(p >> 16 & 0xFF, opColor: 0x7FFF) << 16
            | QuickDrawColour.blendTowardBlack(p >> 8 & 0xFF, opColor: 0x7FFF) << 8
            | QuickDrawColour.blendTowardBlack(p & 0xFF, opColor: 0x7FFF)
        XCTAssertEqual(c.comp[15, 15], want)
        XCTAssertEqual(c.comp[30, 15], before[30, 15])
        XCTAssertEqual(c.comp[15, 20], before[15, 20])
        // patOr with the checker: black where (h + v) is even, untouched elsewhere — over the whole comp.
        c.apply(.fillBlack(target: .comp))
        c.apply(.frameRect(QDRect(top: 0, left: 0, bottom: 2, right: 2), rgb: 0xFFFFFF, target: .comp))
        c.apply(.patternOverlay(index: 4))
        XCTAssertEqual(c.comp[0, 0], RGBAImage.opaqueBlack)
        XCTAssertEqual(c.comp[1, 0], 0xFFFF_FFFF)
        XCTAssertEqual(c.comp[0, 1], 0xFFFF_FFFF)
        XCTAssertEqual(c.comp[1, 1], RGBAImage.opaqueBlack)
    }

    func testPictSliceTransparentAndStretch() throws {
        let (art, c) = try make()
        // `_FlashButton`: PICT 9100 into bgnd at (0,0,300,300), then a transparent bgnd → comp slice.
        let p = try art.pict(9100)
        c.apply([.fillBlack(target: .comp),
                 .pict(id: 9100, dst: QDRect(top: 0, left: 0, bottom: 300, right: 300), target: .bgnd)])
        let src = QDRect(top: 0, left: 150, bottom: 40, right: 300), dst = QDRect(top: 200, left: 100, bottom: 240, right: 250)
        c.apply(.pictSlice(id: 9100, src: src, dst: dst, target: .comp))
        var copied = 0, keyed = 0
        for v in 0..<40 { for h in 0..<150 {
            let s = p[150 + h, v], out = c.comp[100 + h, 200 + v]
            if s & 0xFFFFFF == 0xFFFFFF { XCTAssertEqual(out, RGBAImage.opaqueBlack); keyed += 1 } else {
                XCTAssertEqual(out, s); copied += 1
            }
        } }
        XCTAssertGreaterThan(copied, 0)
        // Stretched slice (2× in both axes): nearest — dst (x, y) reads src (x/2, y/2).
        c.apply(.fillBlack(target: .comp))
        let small = QDRect(top: 0, left: 0, bottom: 20, right: 30)
        c.apply(.pictSlice(id: 9100, src: small, dst: QDRect(top: 100, left: 100, bottom: 140, right: 160), target: .comp))
        for (h, v) in [(0, 0), (1, 1), (13, 7), (59, 39), (30, 20)] {
            let s = p[h / 2, v / 2]
            XCTAssertEqual(c.comp[100 + h, 100 + v], s & 0xFFFFFF == 0xFFFFFF ? RGBAImage.opaqueBlack : s, "(\(h),\(v))")
        }
        XCTAssertEqual(c.comp[160, 120], RGBAImage.opaqueBlack)
        _ = keyed
    }

    func testFullFrameCopyFastPathClips() throws {
        let (_, c) = try make()
        c.apply([.drawMaze(pictID: 912), .fillBlack(target: .screen)])
        // A rect hanging off every edge copies only the in-bounds part, 1:1.
        c.apply(.compToScreen(QDRect(top: -20, left: -30, bottom: 500, right: 700)))
        XCTAssertEqual(c.screen, c.comp)
        c.apply(.fillBlack(target: .screen))
        c.apply(.compToScreen(QDRect(top: 470, left: 630, bottom: 490, right: 650)))
        XCTAssertEqual(c.screen[635, 475], c.comp[635, 475])
        XCTAssertEqual(c.screen[629, 475], RGBAImage.opaqueBlack)
        c.apply(.compToScreen(QDRect(top: 500, left: 0, bottom: 520, right: 640)))           // wholly outside: no-op
    }
}
