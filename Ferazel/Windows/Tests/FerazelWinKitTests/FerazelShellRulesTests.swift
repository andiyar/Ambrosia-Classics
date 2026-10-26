import FerazelCore
import FerazelRender
@testable import FerazelWinKit
import Foundation
import XCTest

/// The driver's tables (moved from the Mac controller unchanged), the mute switch's two effects (Ruling 20, G-MUTE) and
/// the shared files' symlink coverage (Ruling 1).
@MainActor final class FerazelShellRulesTests: XCTestCase {
    func testIsConversationOpTable() {
        let rect = Rect16(top: 0, left: 0, bottom: 10, right: 10)
        let text = TextRun(bytes: [0x41], font: 20, size: 18, face: 0, h: 0, v: 0, rgb: RGB16(red: 0, green: 0, blue: 0))
        let rows: [(DrawOp, Bool)] = [
            (.drawText(text), true),
            (.restoreView, true),
            (.drawBlackLines, true),
            (.copyPicture(id: 1, chain: .level, source: rect, dest: rect, forceClut: nil, transparent: true), true),
            (.copyPicture(id: 1, chain: .level, source: rect, dest: rect, forceClut: 130, transparent: true), false),
            (.copyPicture(id: 1, chain: .level, source: rect, dest: rect, forceClut: nil, transparent: false), false),
            (.drawPicture(id: 130, chain: .frontEnd, h: 0, v: 0), false),
            (.setScreenClut(id: 130), false),
            (.fillRect(left: 0, top: 0, right: 1, bottom: 1, rgb: RGB16(red: 0, green: 0, blue: 0)), false),
            (.eraseParticles, false),
        ]
        for (op, want) in rows { XCTAssertEqual(FerazelDriver.isConversationOp(op), want, "\(op)") }
    }

    func testKeyMapCodeTable() {
        // Right Shift, Option, Control, ⌘ fold to the left keys; everything else passes through.
        let rows: [(Int, Int)] = [(0x3c, 0x38), (0x3d, 0x3a), (0x3e, 0x3b), (0x36, 0x37),
                                  (0x38, 0x38), (0x3a, 0x3a), (0x3b, 0x3b), (0x37, 0x37), (0x00, 0x00), (0x2d, 0x2d),
                                  (0x7a, 0x7a), (0x39, 0x39), (0x7f, 0x7f)]
        for (code, want) in rows { XCTAssertEqual(FerazelDriver.keyMapCode(code), want, "0x\(String(code, radix: 16))") }
    }

    func testMixerFactoryIsNeverCalledWhenMuted() throws {
        let muted = try Rig(mute: true, mixer: .fake(FakeMixer()))
        try muted.toMainMenu()
        try muted.step(FrontInput(keys: KeyState(pressed: [MainMenu.newGameKey])))
        try muted.drive { $0.flow.levelRun != nil && $0.lastOutput.present }
        XCTAssertEqual(muted.counters.mixerFactoryCalls, 0, "muted: no mixer through boot + New Game")
        XCTAssertTrue(muted.driver.playingSounds().isEmpty)

        // The headless frames mode, muted: still no factory call, but the silent mixer drains the Sound Tool, so
        // "playing" follows the sounds (Ruling 20).
        let frames = try Rig(mute: true, mixer: .headless)
        try frames.toMainMenu()
        var heard = false
        try frames.drive(max: 100, input: { _ in FrontInput(keys: KeyState(pressed: [MainMenu.newGameKey])) }) { r in
            heard = !r.driver.playingSounds().isEmpty
            return heard
        }
        XCTAssertEqual(frames.counters.mixerFactoryCalls, 0, "headless + muted: the factory is never called")
        XCTAssertNotNil(frames.driver.silentMixer)
        XCTAssertTrue(heard, "the menu's button sound is seen playing")
        frames.driver.beep()
        XCTAssertEqual(frames.counters.beeps, 0)

        // Headless and unmuted: the frames mode still never calls the factory; its own silent mixer is installed.
        let headlessLoud = try Rig(mixer: .headless)
        XCTAssertEqual(headlessLoud.counters.mixerFactoryCalls, 0, "headless + unmuted: the factory is never called")
        XCTAssertNotNil(headlessLoud.driver.silentMixer)

        let fake = FakeMixer()
        let loud = try Rig(mixer: .fake(fake))
        XCTAssertEqual(loud.counters.mixerFactoryCalls, 1, "unmuted: exactly one mixer, at boot")
        try loud.toMainMenu()
        XCTAssertEqual(loud.counters.mixerFactoryCalls, 1)
        XCTAssertTrue(fake.calls.contains("attach"))
        XCTAssertTrue(fake.calls.contains { $0.hasPrefix("play 0 v0") }, "the menu music reached the mixer")
    }

    func testBeeperIsGatedByMute() throws {
        let muted = try Rig(mute: true, boot: false)
        muted.driver.beep()
        XCTAssertEqual(muted.counters.beeps, 0)
        let loud = try Rig(boot: false)
        loud.driver.beep()
        XCTAssertEqual(loud.counters.beeps, 1)
    }

    /// Every `Ferazel/Shared/*.swift` is in `FerazelWinKit` as a relative git symlink to itself (BTX D36 precedent).
    func testEverySharedFileHasItsSymlink() throws {
        let here = URL(fileURLWithPath: #filePath)
        let ferazel = here.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
        let shared = ferazel.appendingPathComponent("Shared")
        let kit = ferazel.appendingPathComponent("Windows/Sources/FerazelWinKit")
        let fm = FileManager.default
        let names = try fm.contentsOfDirectory(atPath: shared.path).filter { $0.hasSuffix(".swift") }.sorted()
        XCTAssertTrue(names.contains("FerazelDriver.swift"))
        XCTAssertTrue(names.contains("FerazelAudio.swift"))
        for name in names {
            let link = kit.appendingPathComponent(name).path
            let dest = try? fm.destinationOfSymbolicLink(atPath: link)
            XCTAssertEqual(dest, "../../../Shared/\(name)", "\(name): FerazelWinKit symlink")
        }
    }
}
