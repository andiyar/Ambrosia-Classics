import FerazelCore
import FerazelRender
@testable import FerazelWinKit
import Foundation
import XCTest

/// The shared shell half (WF1, Ruling 1) driven headless on the real data: the boot, the main menu, New Game's first
/// level frame, the present (RGBA and the Mac's ARGB words, MacGamma), the dialog pictures, the level services and the
/// boot's two loads. Frames use `StubGlyphRasterizer`, the fixed seed and clock, and the silent mixer (Ruling 20).
@MainActor final class FerazelDriverTests: XCTestCase {
    /// Self-measured (WF1, 2026-10-26) in the headless frames setup (Ruling 20: muted, the silent mixer draining the
    /// Sound Tool per tick, the fixed seed and clock, stub text): the tick on which the flow first stands in the main
    /// menu, counted from the first tick, and the presented frame there.
    static let bootTicks = 360
    static let mainMenuFNV: UInt64 = 0xae2b_1ee0_8c08_9b2a
    /// New Game (N held in the menu): ticks from the first held tick to level 1's first presented frame, and its FNV.
    static let newGameTicks = 107
    static let levelOneFNV: UInt64 = 0xc99c_e8e8_5b4b_d8f7

    func testBootReachesMainMenuAndPresents() throws {
        let rig = try Rig(mute: true, mixer: .headless)
        try rig.toMainMenu()
        XCTAssertEqual(rig.counters.mixerFactoryCalls, 0)
        XCTAssertEqual(rig.driver.silentMixer?.ticks, rig.ticks, "the silent mixer drained every tick")
        let rgba = try XCTUnwrap(rig.lastRGBA)
        XCTAssertEqual(rgba.count, FerazelDriver.width * FerazelDriver.height * 4)
        XCTAssertEqual(rig.ticks, Self.bootTicks, "boot → main menu ticks")
        XCTAssertEqual(hex(fnv1a64(rgba)), hex(Self.mainMenuFNV), "main menu RGBA FNV")
        // The Mac's ARGB words are the same pixels: 0xff alpha, then r, g, b.
        let words = UnsafeMutablePointer<UInt32>.allocate(capacity: FerazelDriver.width * FerazelDriver.height)
        defer { words.deallocate() }
        rig.driver.presentARGB(into: words)
        for i in stride(from: 0, to: FerazelDriver.width * FerazelDriver.height, by: 97) {
            let w = words[i]
            XCTAssertEqual(w >> 24, 0xff)
            XCTAssertEqual([UInt8(w >> 16 & 0xff), UInt8(w >> 8 & 0xff), UInt8(w & 0xff), 0xff],
                           Array(rgba[4 * i..<4 * i + 4]), "pixel \(i)")
        }
        // The prefs: none stored → the defaults, written at once (`.InitPrefs`).
        XCTAssertEqual(rig.files.stored.count, 1)
        XCTAssertTrue(rig.counters.logs.isEmpty, "\(rig.counters.logs)")
    }

    func testMacGammaGoesThroughThePalette() throws {
        XCTAssertEqual(FerazelDriver.macGammaLUT.count, 256)
        XCTAssertEqual(FerazelDriver.macGammaLUT[0], 0)
        XCTAssertEqual(FerazelDriver.macGammaLUT[255], 255)
        XCTAssertEqual(FerazelDriver.macGammaLUT[128], 145)   // 255·(128/255)^(1.8/2.2), rounded
        XCTAssertEqual(FerazelDriver.macGammaLUT[64], 82)
        XCTAssertEqual(FerazelDriver.macGammaLUT[1], 3)
        let off = try Rig(mute: true)
        let on = try Rig(mute: true, macGamma: true)
        try off.toMainMenu()
        try on.toMainMenu()
        let a = try XCTUnwrap(off.lastRGBA)
        let b = try XCTUnwrap(on.lastRGBA)
        XCTAssertEqual(a.count, b.count)
        var changed = 0
        for i in 0..<a.count {
            let want = i % 4 == 3 ? 0xff : FerazelDriver.macGammaLUT[Int(a[i])]
            if b[i] != want { XCTFail("byte \(i): \(b[i]) ≠ \(want)"); break }
            if a[i] != b[i] { changed += 1 }
        }
        XCTAssertGreaterThan(changed, 0)
        // The dialog pictures go through the same LUT (the credits background, PICT 4804, has mid-tones; the strip is
        // black and white only).
        let p = try XCTUnwrap(off.driver.dialogPicture(4804))
        let q = try XCTUnwrap(on.driver.dialogPicture(4804))
        // The picture has mid-tones (the LUT moves them; 0 and 255 are its fixed points), so gamma must change it.
        let midTones = p.rgba.enumerated().filter { i, v in i % 4 != 3 && v != 0 && v != 255 }.count
        XCTAssertGreaterThan(midTones, 0)
        XCTAssertNotEqual(q.rgba, p.rgba, "MacGamma reaches the dialog pictures")
        XCTAssertEqual(q.rgba, p.rgba.enumerated().map { i, v in i % 4 == 3 ? v : FerazelDriver.macGammaLUT[Int(v)] })
    }

    func testNewGameReachesLevelOneFirstFrame() throws {
        let rig = try Rig(mute: true, mixer: .headless)
        try rig.toMainMenu()
        let start = rig.ticks
        try rig.drive(input: { _ in FrontInput(keys: KeyState(pressed: [MainMenu.newGameKey])) }) {
            $0.flow.levelRun != nil && $0.lastOutput.present
        }
        XCTAssertNotNil(rig.driver.silentMixer)
        XCTAssertEqual(rig.flow.state, .newGame)
        XCTAssertEqual(rig.flow.levelRun?.levelNumber, 1)
        XCTAssertEqual(rig.ticks - start, Self.newGameTicks, "N → level 1's first presented frame")
        XCTAssertEqual(hex(fnv1a64(try XCTUnwrap(rig.lastRGBA))), hex(Self.levelOneFNV), "level 1 first frame FNV")
        // `configureLevelRun`: the run got the conversation measures (the stub's widths) before its popup drew.
        XCTAssertEqual(rig.flow.levelRun?.conversationText.charWidth(0x41), StubGlyphRasterizer.advance)
    }

    func testDialogPictureUnderTheCurrentClut() throws {
        let rig = try Rig(mute: true)
        func check(_ id: Int16) throws -> [UInt8] {
            let got = try XCTUnwrap(rig.driver.dialogPicture(id))
            let source = try PictureSource.load(id: id, from: rig.driver.resources, chain: .frontEnd)
            let picture = try ConvertedPicture(source: source, clut: rig.driver.surface.clut, search: rig.driver.search)
            XCTAssertEqual(got.width, picture.width)
            XCTAssertEqual(got.height, picture.height)
            XCTAssertEqual(got.rgba.count, picture.width * picture.height * 4)
            let entries = rig.driver.surface.clut.entries
            for (i, v) in picture.pixels.enumerated() {
                let e = entries[Int(v)]
                let want = [UInt8(e.red >> 8), UInt8(e.green >> 8), UInt8(e.blue >> 8), 0xff]
                if Array(got.rgba[4 * i..<4 * i + 4]) != want { XCTFail("pixel \(i)"); break }
            }
            return got.rgba
        }
        let boot = try check(CreditsScroll.stripPicture)            // under the system CLUT (0x321)
        try rig.toMainMenu()                                         // the menu's CLUT 130
        let menu = try check(CreditsScroll.stripPicture)
        XCTAssertNotEqual(boot, menu, "converted under the screen's current CLUT")
        XCTAssertNil(rig.driver.dialogPicture(-1))
    }

    func testPrepareAndAttachThroughTheDriver() throws {
        let rig = try Rig(mute: true)
        let services: LevelServices = rig.driver
        XCTAssertThrowsError(try services.attach(lights: [], tintTableDraws: []))   // no renderer yet
        XCTAssertThrowsError(try services.deathEffectStep(0))
        let faces = try services.prepare(level: 1)
        XCTAssertNotNil(faces.faceBounds)
        XCTAssertNotNil(rig.driver.levelRenderer)
        XCTAssertNotNil(rig.driver.conversationRenderer)
        XCTAssertThrowsError(try services.attach(lights: [], tintTableDraws: []))   // 510 draws or nothing
        try services.attach(lights: [], tintTableDraws: [Int16](repeating: 0, count: 0xff * 2))
        try services.deathEffectStep(0)
        XCTAssertThrowsError(try services.deathEffectStep(DeathEffect.steps))
    }

    func testLoadFacesReportsTwentyFiveFaces() throws {
        let rig = try Rig(mute: true)
        var faces = false
        for _ in 0..<6000 {
            var input = FrontInput()
            input.playing = rig.driver.playingSounds()
            _ = try rig.driver.tick(now: rig.t, input: input)
            rig.t &+= 1
            if case .loading(.faces) = rig.flow.state {
                let before = rig.flow.progressBar.progress
                rig.driver.serviceLoad()
                XCTAssertEqual(rig.flow.progressBar.progress - before, 25 * ProgressBar3D.perFace)
                faces = true
                break
            }
            rig.driver.serviceLoad()
        }
        XCTAssertTrue(faces)
        XCTAssertTrue(rig.counters.logs.isEmpty, "\(rig.counters.logs)")
    }

    func testLoadSoundsWithF1LoadsTheFourOnly() throws {
        let mixer = FakeMixer()
        let rig = try Rig(mixer: .fake(mixer))
        // F1 held through the boot's sound load (`.InitSounds` loads none; `.InitAppGlobals`' four still load).
        try rig.drive(input: { _ in FrontInput(keys: KeyState(pressed: [BootSequence.soundLoadingKey])) }) { r in
            if case .loading(.faces) = r.flow.state { return true }
            return r.flow.state == .mainMenu
        }
        XCTAssertFalse(rig.flow.soundLoading)
        let four: Set<Int16> = [PauseRun.sound, 4801, MainMenu.enterSound, MainMenu.exitSound]
        XCTAssertEqual(Set(rig.flow.soundLengths.keys), four)
        XCTAssertEqual(mixer.calls.filter { $0 == "attach" }.count, 1)
        let tool = try XCTUnwrap(mixer.tools.first)
        let audio = try XCTUnwrap(rig.driver.audio)
        let other = try XCTUnwrap(SoundBank(sounds: rig.driver.resources.sounds).sounds.map(\.id).first { !four.contains($0) })
        audio.apply(sounds: [SoundCue(snd: other, priority: 1, left: 0x100, right: 0x100, rate: 0x10000),
                             SoundCue(snd: MainMenu.enterSound, priority: 1, left: 0x100, right: 0x100, rate: 0x10000)],
                    stops: [], stopAt: [])
        XCTAssertFalse(tool.isPlaying(snd: other), "a sound not loaded plays nothing")
        XCTAssertTrue(tool.isPlaying(snd: MainMenu.enterSound))
    }
}
