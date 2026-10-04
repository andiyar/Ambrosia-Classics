@testable import BubbleTroubleCore
import Foundation
import XCTest

/// Plan 2026-10-04 btx-playable, task T0 as amended by R1: the LOCKED seam types (S2) land with no behaviour so the
/// lanes can code against them in parallel. `FrameReport.sounds` / `.drawOps` stay empty until C2 / C3.
final class SeamTypesTests: XCTestCase {

    /// Every seam value type compares by value (S2: `Equatable, Sendable`).
    func testSeamTypesEquatable() {
        XCTAssertEqual(SoundCue(slot: 5, priority: 20, delayFrames: 0), SoundCue(slot: 5, priority: 20, delayFrames: 0))
        XCTAssertNotEqual(SoundCue(slot: 5, priority: 20, delayFrames: 0), SoundCue(slot: 7, priority: 20, delayFrames: 0))

        XCTAssertEqual(MusicCue.load(set: 2), .load(set: 2))
        XCTAssertNotEqual(MusicCue.load(set: 2), .load(set: 3))
        XCTAssertNotEqual(MusicCue.volume(0x100), .volume(0xfb))
        let music: [MusicCue] = [.start, .stopFade, .stopNow, .pause, .resume, .unload]
        XCTAssertEqual(Set(music.map { "\($0)" }).count, music.count)

        let r = QDRect(top: 228, left: 165, bottom: 262, right: 315)
        let ops: [DrawOp] = [
            .drawMaze(pictID: 912), .restoreBgnd(r), .sprite(set: 0x11, frame: 1, h: 40, v: 80, mode: .normal),
            .sprite(set: 0x11, frame: 1, h: 40, v: 80, mode: .transparent), .spriteToBgnd(set: 0x11, frame: 1, h: 40, v: 80),
            .prepareScoreBar, .compToScreen(r), .pict(id: 9030, dst: r), .pictSlice(id: 9100, src: r, dst: r),
            .string(text: "BEN", h: 10, v: 20, highlighted: true), .infoText("Version 1.1.0", colour: 0x111),
            .darkenRect(r), .frameRect(r, rgb: 0xff9900), .fillBlack, .patternOverlay(index: 1), .wipe(step: 12), .fps(30),
        ]
        for (i, a) in ops.enumerated() {
            for (j, b) in ops.enumerated() {
                if i == j { XCTAssertEqual(a, b) } else { XCTAssertNotEqual(a, b, "\(a) vs \(b)") }
            }
        }

        XCTAssertEqual(HeldKeys(codes: [0x7b, 0x31], capsLock: false, command: false),
                       HeldKeys(codes: [0x31, 0x7b], capsLock: false, command: false))
        XCTAssertNotEqual(HeldKeys(codes: [0x7b], capsLock: true, command: false), HeldKeys(codes: [0x7b]))
        XCTAssertEqual(HeldKeys(), HeldKeys(codes: [], capsLock: false, command: false))

        XCTAssertEqual(KeyModifiers(command: true),
                       KeyModifiers(command: true, shift: false, option: false, control: false, capsLock: false))
        XCTAssertNotEqual(KeyModifiers(shift: true), KeyModifiers(option: true))

        XCTAssertEqual(ShellRequest.highScoreEntry(rank: 3), .highScoreEntry(rank: 3))
        XCTAssertNotEqual(ShellRequest.enableMenus(true), .enableMenus(false))
        let requests: [ShellRequest] = [.hideCursor, .showCursor, .haltAllSound, .quitNow, .savePrefs]
        XCTAssertEqual(Set(requests.map { "\($0)" }).count, requests.count)

        XCTAssertEqual(SessionEnd.levelCompleted, .levelCompleted)
        XCTAssertNotEqual(SessionEnd.gameOver, .escaped)
        XCTAssertNotEqual(GameMode.play, GameMode.demo)

        let out = SessionOutput(sounds: [SoundCue(slot: 2, priority: 30, delayFrames: 0)], music: [.start],
                                drawOps: [.fillBlack], requests: [.hideCursor], ended: nil)
        XCTAssertEqual(out, out)
        XCTAssertNotEqual(out, SessionOutput())
        XCTAssertEqual(SessionOutput(), SessionOutput(sounds: [], music: [], drawOps: [], requests: [], ended: nil))
        XCTAssertNotEqual(SessionOutput(ended: .gameOver), SessionOutput())
    }

    /// `FrameReport` gains `sounds` and `drawOps`, empty until C2 / C3 fill them; a real `stepFrame` leaves both empty.
    func testFrameReportDefaultsEmpty() {
        var maze = try! Maze(data: Data(count: Maze.byteCount))
        maze[2, 2] = CellCode.normal
        var config = SessionConfig()
        config.prefs.airBubbles = false
        var state = GameState.testWorld(maze: maze, totalEnemies: 1, maxActive: 0, pool: [1, 0, 0, 0, 0, 0],
                                        config: config)
        let idle = FilmSample(up: false, down: false, left: false, right: false, push: false)
        var input = ScriptedInput(samples: Array(repeating: idle, count: 5))
        for _ in 0..<3 {
            let report = state.stepFrame(input: &input)
            XCTAssertEqual(report.sounds, [])
            XCTAssertEqual(report.drawOps, [])
        }
    }
}
