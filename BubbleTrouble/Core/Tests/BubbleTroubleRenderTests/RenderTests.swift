import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import HectorAudio
import XCTest

/// Plan 2026-10-04-btx-playable task R1. Data-gated on `HECTORKIT_DATA_BTX`; goldens are self-derived from the
/// original's resources (FNV-1a of a buffer + named pixel probes).
final class RenderTests: XCTestCase {
    private func make() throws -> (BTXGameData, ArtBank, Compositor) {
        let data = try RenderTestData.gameData()
        let art = ArtBank(data: data)
        return (data, art, Compositor(art: art, text: StubRasterizer()))
    }

    private static let full = QDRect(top: 0, left: 0, bottom: 480, right: 640)

    // MARK: - Decoding

    func testAllSpritesDecode331() throws {
        let (data, art, _) = try make()
        let spriteFile = art.cicnIDs.filter { data.fileName(containingType: "cicn", id: $0) == BTXGameData.spritesFileName }
        XCTAssertEqual(spriteFile.count, 331)
        // Every cicn of the five files decodes (331 sprites + cicn 128, 1000–1002 in the app file, R9).
        XCTAssertEqual(art.cicnIDs.count, 335)
        for id in art.cicnIDs { XCTAssertNoThrow(try art.cicn(id), "cicn \(id)") }
        XCTAssertNoThrow(try art.prewarm())
        // The flat loaded-sprite array: 52 sets, 325 frames, every one a decodable cicn.
        XCTAssertEqual(art.setOffset.count, 52)
        XCTAssertEqual(art.flatCICN.count, 325)
        XCTAssertEqual(art.spriteCICNID(set: 1, frame: 1), 25000)
        XCTAssertEqual(art.spriteCICNID(set: 0x34, frame: 1), 31700)
        XCTAssertEqual(try art.cicn(25000).width, 40)
    }

    func testPauseMattePictsDecode() throws {
        let (_, art, comp) = try make()
        for (id, w) in [(9030, 330), (9031, 260)] {
            XCTAssertEqual(try art.pictDecodePath(id), .quickTimeMatte)
            let p = try art.pict(id)
            XCTAssertEqual(p.width, w)
            XCTAssertEqual(p.height, 16)
            let alphas = Set(p.pixels.map { $0 >> 24 })
            XCTAssertTrue(alphas.contains(0) && alphas.contains(0xFF), "pict \(id) matte is a real mask")
        }
        for id in [9077, 7000, 2910] { XCTAssertEqual(try art.pictDecodePath(id), .quickTimeMatte, "PICT \(id)") }
        for id in [9001, 9002, 9012, 9020] { XCTAssertEqual(try art.pictDecodePath(id), .packBitsRegion, "PICT \(id)") }
        // The PAUSED lines (`_PauseGame`, C4 item 7): where the matte is 0 the comp keeps its pixel.
        comp.apply([.fillBlack(target: .comp), .pict(id: 9030, dst: QDRect(top: 279, left: 155, bottom: 295, right: 485),
                                                       target: .comp)])
        let p = try art.pict(9030)
        var kept = 0, replaced = 0
        for v in 0..<16 {
            for h in 0..<330 {
                let a = p[h, v] >> 24, out = comp.comp[155 + h, 279 + v]
                if a == 0 { XCTAssertEqual(out, RGBAImage.opaqueBlack); kept += 1 }
                if a == 0xFF { XCTAssertEqual(out, p[h, v]); replaced += 1 }
            }
        }
        XCTAssertGreaterThan(kept, 0)
        XCTAssertGreaterThan(replaced, 0)
        XCTAssertEqual(comp.comp[154, 279], RGBAImage.opaqueBlack)
    }

    func testSoundBankDecodes52() throws {
        let data = try RenderTestData.gameData()
        let bank = SoundBankPCM(data: data)
        XCTAssertEqual(SoundBankPCM.allIDs.count, 52)
        for id in SoundBankPCM.allIDs {
            let pcm = try bank.pcm(id)
            XCTAssertGreaterThan(pcm.frames, 0, "snd \(id)")
            XCTAssertEqual(pcm.samples.count, pcm.frames * pcm.channels, "snd \(id)")
            XCTAssertTrue((1...2).contains(pcm.channels), "snd \(id)")
            XCTAssertTrue(pcm.sampleRate > 4000 && pcm.sampleRate < 50000, "snd \(id) rate \(pcm.sampleRate)")
        }
        XCTAssertEqual(data.fileName(containingType: "snd ", id: 9047), BTXGameData.appFileName)
        XCTAssertEqual(try bank.effect(slot: 5), try bank.pcm(9005))
        XCTAssertNoThrow(try bank.prewarm())
    }

    // MARK: - Level picture, score bar

    func testCentredPict912Level1() throws {
        let (data, art, comp) = try make()
        XCTAssertEqual(try data.presentation.background(level: 1), 912)
        XCTAssertEqual(Compositor.centredRect(width: 640, height: 480), Self.full)
        XCTAssertEqual(Compositor.centredRect(width: 300, height: 300),
                       QDRect(top: 90, left: 170, bottom: 390, right: 470))
        XCTAssertEqual(Compositor.centredRect(width: 99, height: 151),            // C division truncates
                       QDRect(top: 164, left: 270, bottom: 315, right: 369))
        comp.apply(.drawMaze(pictID: 912))
        let p = try art.pict(912)
        XCTAssertEqual(comp.comp, p)
        XCTAssertEqual(comp.bgnd, p)
        XCTAssertEqual(comp.comp.fnv1a, 0xbe1b9a33da34aec0)
        // A level-4 picture (QuickTime PICT 13001) centres the same way.
        comp.apply(.drawMaze(pictID: try data.presentation.background(level: 4)))
        XCTAssertEqual(comp.bgnd, try art.pict(13001))
    }

    func testScoreBarBlendAndGreenLine() throws {
        let (_, art, comp) = try make()
        comp.apply([.drawMaze(pictID: 912), .prepareScoreBar])
        let p = try art.pict(912)
        func darker(_ x: UInt32) -> UInt32 {
            0xFF00_0000 | QuickDrawColour.blendTowardBlack(x >> 16 & 0xFF, opColor: 0x7FFF) << 16
                | QuickDrawColour.blendTowardBlack(x >> 8 & 0xFF, opColor: 0x7FFF) << 8
                | QuickDrawColour.blendTowardBlack(x & 0xFF, opColor: 0x7FFF)
        }
        XCTAssertEqual(QuickDrawColour.blendTowardBlack(255, opColor: 0x7FFF), 128)
        XCTAssertEqual(QuickDrawColour.blendTowardBlack(0, opColor: 0x7FFF), 0)
        for h in [0, 1, 320, 639] {
            XCTAssertEqual(comp.comp[h, 440], 0xFF00_8011, "green line row 440 x\(h)")
            XCTAssertEqual(comp.comp[h, 441], 0xFF00_8011, "green line row 441 x\(h)")
            XCTAssertEqual(comp.comp[h, 439], p[h, 439], "playfield untouched x\(h)")
            for v in [442, 460, 479] { XCTAssertEqual(comp.comp[h, v], darker(p[h, v]), "tint (\(h),\(v))") }
        }
        // The score GWorld caches comp rows 440…479; bgnd keeps the untinted picture.
        for v in 0..<40 { for h in stride(from: 0, to: 640, by: 37) { XCTAssertEqual(comp.score[h, v], comp.comp[h, 440 + v]) } }
        XCTAssertEqual(comp.bgnd[100, 460], p[100, 460])
        // `_ScoreToComp`: dst in comp, src = dst − 440 in the score GWorld.
        comp.apply(.fillBlack(target: .comp))
        comp.apply(.scoreToComp(QDRect(top: 0x1be, left: 0x84, bottom: 0x1dc, right: 0x150)))
        XCTAssertEqual(comp.comp[0x84, 0x1be], comp.score[0x84, 6])
        XCTAssertEqual(comp.comp[0x14f, 0x1db], comp.score[0x14f, 35])
        XCTAssertEqual(comp.comp[0x83, 0x1be], RGBAImage.opaqueBlack)
        XCTAssertEqual(comp.comp[0x84, 0x1bd], RGBAImage.opaqueBlack)
    }

    // MARK: - Sprites

    func testSpriteMaskKeyed() throws {
        let (_, art, comp) = try make()
        comp.apply(.fillBlack(target: .comp))
        let ground: UInt32 = 0xFF12_3456
        // A known ground under the sprite: one-row frame rects fill rows 100…199, columns 80…199.
        for v in 100..<200 {
            comp.apply(.frameRect(QDRect(top: Int16(v), left: 80, bottom: Int16(v + 1), right: 200), rgb: 0x123456,
                                  target: .comp))
        }
        let icon = try art.cicn(25000)                       // hero idle, set 1 frame 1
        comp.apply(.sprite(set: 1, frame: 1, h: 100, v: 120, mode: .normal))
        var masked = 0, open = 0
        for v in 0..<40 {
            for h in 0..<40 {
                let p = icon[h, v], out = comp.comp[100 + h, 120 + v]
                if p >> 24 == 0 { XCTAssertEqual(out, ground); open += 1 } else { XCTAssertEqual(out, p); masked += 1 }
            }
        }
        XCTAssertGreaterThan(masked, 0)
        XCTAssertGreaterThan(open, 0)
        let before = comp.comp
        // Frame 0 draws frame 1 (`if (0 < f) f − 1`); a frame past the set's count draws on into the flat array
        // (set 1 has 4 frames: frame 5 = set 2 frame 1 = cicn 25100); out-of-range sets draw nothing, no trap;
        // sets 53…100 read the zero-filled offset table (offset 0 → set 1).
        XCTAssertEqual(art.spriteCICNID(set: 1, frame: 0), 25000)
        XCTAssertEqual(art.spriteCICNID(set: 1, frame: 5), 25100)
        XCTAssertEqual(art.spriteCICNID(set: 2, frame: -1), 25003)
        XCTAssertEqual(art.spriteCICNID(set: 53, frame: 2), 25001)
        XCTAssertNil(art.spriteCICNID(set: 0, frame: 1))
        XCTAssertNil(art.spriteCICNID(set: 101, frame: 1))
        XCTAssertNil(art.spriteCICNID(set: 0x34, frame: 30))
        XCTAssertNil(art.spriteCICNID(set: 1, frame: -1))
        comp.apply([.sprite(set: 0, frame: 1, h: 100, v: 120, mode: .normal),
                    .sprite(set: 0x34, frame: 99, h: 100, v: 120, mode: .normal)])
        XCTAssertEqual(comp.comp, before)
        // `_TransSpriteToComp`: masked pixels lightened halfway to white, (255 + c) >> 1 — pure white drawn too
        // (10.5+; set 2 frame 1.. holds a white pixel, checked below).
        comp.apply(.sprite(set: 1, frame: 1, h: 300, v: 300, mode: .transparent))
        for v in 0..<40 {
            for h in 0..<40 {
                let p = icon[h, v], out = comp.comp[300 + h, 300 + v]
                if p >> 24 == 0 { XCTAssertEqual(out, RGBAImage.opaqueBlack); continue }
                let r = (255 + (p >> 16 & 0xFF)) >> 1, g = (255 + (p >> 8 & 0xFF)) >> 1, b = (255 + (p & 0xFF)) >> 1
                let want = 0xFF00_0000 | r << 16 | g << 8 | b
                XCTAssertEqual(out, want)
            }
        }
        // `_SpriteToBgnd` plots into bgnd only.
        let compBefore = comp.comp
        comp.apply(.spriteToBgnd(set: 1, frame: 1, h: 0, v: 0))
        XCTAssertEqual(comp.comp, compBefore)
        XCTAssertEqual(comp.bgnd[20, 20], icon[20, 20] >> 24 == 0 ? RGBAImage.opaqueBlack : icon[20, 20])
    }

    func testRestoreBgndCopiesOnlyRect() throws {
        let (_, art, comp) = try make()
        comp.apply([.drawMaze(pictID: 912), .fillBlack(target: .comp)])
        let p = try art.pict(912)
        comp.apply(.restoreBgnd(QDRect(top: 100, left: 200, bottom: 140, right: 240)))
        XCTAssertEqual(comp.comp[200, 100], p[200, 100])
        XCTAssertEqual(comp.comp[239, 139], p[239, 139])
        XCTAssertEqual(comp.comp[240, 120], RGBAImage.opaqueBlack)
        XCTAssertEqual(comp.comp[199, 120], RGBAImage.opaqueBlack)
        XCTAssertEqual(comp.comp[220, 140], RGBAImage.opaqueBlack)
        XCTAssertEqual(comp.comp[220, 99], RGBAImage.opaqueBlack)
        // Bottom clipped to 440 (the score bar is never restored from bgnd)…
        comp.apply(.restoreBgnd(QDRect(top: 420, left: 0, bottom: 470, right: 40)))
        XCTAssertEqual(comp.comp[10, 439], p[10, 439])
        XCTAssertEqual(comp.comp[10, 440], RGBAImage.opaqueBlack)
        // …unless the rect also starts above row 0: `top < 0 → top = 0` ELSE the bottom clip (quirk kept).
        comp.apply(.restoreBgnd(QDRect(top: -10, left: 600, bottom: 460, right: 610)))
        XCTAssertEqual(comp.comp[605, 0], p[605, 0])
        XCTAssertEqual(comp.comp[605, 450], p[605, 450])
        // Rects wholly outside are dropped (top ≥ 441).
        comp.apply(.restoreBgnd(QDRect(top: 441, left: 300, bottom: 470, right: 320)))
        XCTAssertEqual(comp.comp[310, 450], RGBAImage.opaqueBlack)
    }

    // MARK: - Frames

    /// Level 1's first frame from C3's `levelStartOps` (`_DrawMaze @ 00025daa`): PICT LEVL.w1 into bgnd + comp, the
    /// score bar, the maze-cell sprites of level 1 as the core builds it (seed 1: jewels placed), then comp → screen.
    func testLevel1FirstFrameGolden() throws {
        let (data, art, comp) = try make()
        var state = try GameState.newGame(level: 1, mode: .play, seed: 1, files: data.levels)
        XCTAssertEqual(state.levelRecord.words[1], Int16(try data.presentation.background(level: 1)))
        let ops = state.levelStartOps() + [.compToScreen(Self.full)]
        XCTAssertEqual(ops.filter { if case .sprite = $0 { return true } else { return false } }.count,
                       state.maze.cells.filter { [10, 15, 16, 20, 30, 52].contains($0) }.count)
        comp.apply(ops)
        XCTAssertEqual(comp.screen, comp.comp)
        if let dir = ProcessInfo.processInfo.environment["BTX_RENDER_PNG_DIR"] {
            XCTAssertTrue(PNGWriter.write(comp.screen, to: URL(fileURLWithPath: dir).appendingPathComponent("level1-frame1.png")))
        }
        XCTAssertEqual(comp.screen.fnv1a, 0xf657cbfaf90e3ea9)
        // Named probes: a maze bubble cell (sprite pixel), the green line, the tinted bar.
        XCTAssertEqual(state.maze[0, 0], 10)
        let bubble = try art.cicn(try XCTUnwrap(art.spriteCICNID(set: 0x11, frame: 1)))
        XCTAssertEqual(bubble[20, 20] >> 24, 0xFF)
        XCTAssertEqual(comp.screen[20, 20], bubble[20, 20])
        XCTAssertEqual(comp.screen[0, 440], 0xFF00_8011)
        XCTAssertEqual(comp.screen[300, 470], comp.score[300, 30])
    }

    func testWipeRevealsBandsStep12() throws {
        let (_, _, comp) = try make()
        XCTAssertEqual(Compositor.wipeSteps(12), 22)
        comp.apply([.drawMaze(pictID: 912), .prepareScoreBar, .wipe(step: 12)])
        XCTAssertEqual(comp.screen[5, 11], comp.comp[5, 11])
        XCTAssertEqual(comp.screen[5, 468], comp.comp[5, 468])
        XCTAssertEqual(comp.screen[5, 12], RGBAImage.opaqueBlack)
        XCTAssertEqual(comp.screen[5, 467], RGBAImage.opaqueBlack)
        for row in 1...18 { comp.applyWipe(row: row) }
        // After 18 advances the bands cover [0, 228) and [252, 480): rows 228…251 still dark.
        XCTAssertEqual(comp.screen[5, 227], comp.comp[5, 227])
        XCTAssertEqual(comp.screen[5, 252], comp.comp[5, 252])
        for v in 228..<252 { XCTAssertEqual(comp.screen[320, v], RGBAImage.opaqueBlack, "row \(v)") }
        comp.applyWipe(row: 19)
        comp.applyWipe(row: 20)
        XCTAssertEqual(comp.screen, comp.comp)
    }

    func testLettersFontHighScoresHeader() throws {
        let (_, art, comp) = try make()
        let font = comp.letters
        XCTAssertEqual(font.width(UInt8(ascii: "A")), 14)
        XCTAssertEqual(font.width(UInt8(ascii: "a")), 14)
        XCTAssertEqual(font.width(UInt8(ascii: "W")), 21)
        XCTAssertEqual(font.width(UInt8(ascii: "1")), 7)
        XCTAssertEqual(font.width(UInt8(ascii: " ")), 7)
        XCTAssertEqual(font.width(UInt8(ascii: "#")), 0)
        XCTAssertEqual(font.glyphs[Int(UInt8(ascii: "0"))], QDRect(top: 23, left: 0xbd, bottom: 46, right: 0xca))
        // Centred (h = −1): (640 − Σ widths) / 2.
        let text = "HIGH SCORES"
        let total = LettersFont.bytes(text).reduce(0) { $0 + font.width($1) }
        let placed = font.layout(text, h: -1, v: 40, highlighted: false, fixedPitch: nil)
        XCTAssertEqual(placed.count, 11)
        XCTAssertEqual(Int(placed[0].dst.left), (640 - total) / 2)
        XCTAssertEqual(Int(placed[10].dst.right), (640 - total) / 2 + total)
        XCTAssertEqual(placed[0].src, font.glyphs[Int(UInt8(ascii: "H"))])
        let hi = font.layout("12", h: 100, v: 0, highlighted: true, fixedPitch: 15)
        XCTAssertEqual(hi.map { Int($0.dst.left) }, [100, 115])
        XCTAssertEqual(hi[0].src.top, 23 + 46)
        // The sprite GWorld holds PICT 9001 over 9002; the string copies glyph pixels, never the white.
        let p9001 = try art.pict(9001)
        XCTAssertEqual(comp.spriteWorld[7, 10], p9001[7, 10] >> 24 == 0 ? RGBAImage.opaqueWhite : p9001[7, 10])
        comp.apply([.fillBlack(target: .comp),
                    .string(text: text, h: -1, v: 40, highlighted: false, fixedPitch: nil, target: .comp)])
        var ink = 0
        for g in placed {
            for v in Int(g.dst.top)..<Int(g.dst.bottom) {
                for h in Int(g.dst.left)..<Int(g.dst.right) {
                    let s = comp.spriteWorld[h - Int(g.dst.left) + Int(g.src.left), v - Int(g.dst.top) + Int(g.src.top)]
                    let out = comp.comp[h, v]
                    if s & 0xFFFFFF == 0xFFFFFF { XCTAssertEqual(out, RGBAImage.opaqueBlack) } else {
                        XCTAssertEqual(out, s); ink += 1
                    }
                }
            }
        }
        XCTAssertGreaterThan(ink, 200)
        if let dir = ProcessInfo.processInfo.environment["BTX_RENDER_PNG_DIR"] {
            XCTAssertTrue(PNGWriter.write(comp.comp, to: URL(fileURLWithPath: dir).appendingPathComponent("letters.png")))
        }
        XCTAssertEqual(comp.comp.fnv1a, 0xe3efff62ef1458bc)
    }
}
