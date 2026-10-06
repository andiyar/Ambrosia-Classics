import BTXWinKit
import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import HectorAudio
import XCTest

/// The data-free pieces of W4: clock, timers, frame canvas, key scripts, clock selection.
final class WinUnitTests: XCTestCase {
    func testTicksFromNanosecondsAndBack() {
        XCTAssertEqual(WinClock.ticks(nanoseconds: 0), 0)
        XCTAssertEqual(WinClock.ticks(nanoseconds: 1_000_000_000), 60)
        XCTAssertEqual(WinClock.ticks(nanoseconds: 16_666_666), 0)
        XCTAssertEqual(WinClock.ticks(nanoseconds: 16_666_667), 1)
        for t: UInt64 in [0, 1, 2, 3, 59, 60, 61, 100_000, 100_001, 1_000_003] {
            let n = WinClock.nanoseconds(atTick: t)
            XCTAssertEqual(UInt64(WinClock.ticks(nanoseconds: n)), t, "tick \(t)")
            if n > 0 { XCTAssertEqual(UInt64(WinClock.ticks(nanoseconds: n - 1)), t - 1, "first ns of tick \(t)") }
        }
        // Wraps at 2³² like TickCount, without overflowing on the way.
        XCTAssertEqual(WinClock.ticks(nanoseconds: (1 << 32) / 60 * 1_000_000_000 + 2_000_000_000),
                       UInt32(truncatingIfNeeded: (UInt64(1) << 32) / 60 * 60 + 120))
    }

    /// NSTimer semantics: first fire one interval after start, at most one fire per poll, missed fires dropped
    /// and the schedule kept.
    func testTimerDropsMissedFires() {
        var t = WinTimer(intervalNanoseconds: 33_000_000)
        XCTAssertFalse(t.poll(now: 0))
        t.start(now: 1_000)
        XCTAssertFalse(t.poll(now: 33_000_000 - 1_000))       // > 1 µs early
        XCTAssertTrue(t.poll(now: 33_001_000))
        XCTAssertFalse(t.poll(now: 33_001_000))
        XCTAssertEqual(t.nextFire, 66_001_000)
        // Late by three intervals: one fire, then the next one on the original schedule.
        XCTAssertTrue(t.poll(now: 140_000_000))
        XCTAssertFalse(t.poll(now: 140_000_000))
        XCTAssertEqual(t.nextFire, 165_001_000)
        t.invalidate()
        XCTAssertFalse(t.poll(now: 1_000_000_000))
        XCTAssertNil(t.nextFire)
    }

    /// The 1/60 s timer on the fixed-step clock fires on every step for an hour (exact schedule + slack).
    func testTickTimerOnFixedStepClockNeverMisses() {
        var t = WinTimer(intervalNanoseconds: 1_000_000_000, per: 60)
        t.start(now: WinClock.nanoseconds(atTick: 100_000))
        for step in 1...(60 * 3600) {
            XCTAssertTrue(t.poll(now: WinClock.nanoseconds(atTick: 100_000 + UInt64(step))), "step \(step)")
            if !t.isRunning { break }
        }
    }

    /// The 0.033 s frame timer on the 1/60 s fixed-step clock averages the original's 30.3 fps.
    func testFrameTimerOnFixedStepClockRate() {
        var t = WinTimer(intervalNanoseconds: 33_000_000)
        t.start(now: WinClock.nanoseconds(atTick: 100_000))
        var fires = 0
        for step in 1...600 where t.poll(now: WinClock.nanoseconds(atTick: 100_000 + UInt64(step))) { fires += 1 }
        XCTAssertEqual(fires, 303)                               // 10 s / 0.033 s
    }

    /// Invariant 4: exactly one clock — none before start / quitting / under a modal dialog; frames while a game
    /// runs frames (the fast one with the frame-limit cheat); else TickCount.
    func testClockSelection() {
        typealias D = WinGameDriver
        XCTAssertEqual(D.wantedClock(started: false, quitting: false, dialogModal: false, wantsFrameTimer: true,
                                     limitFrames: true), .none)
        XCTAssertEqual(D.wantedClock(started: true, quitting: true, dialogModal: false, wantsFrameTimer: false,
                                     limitFrames: nil), .none)
        XCTAssertEqual(D.wantedClock(started: true, quitting: false, dialogModal: true, wantsFrameTimer: true,
                                     limitFrames: true), .none)
        XCTAssertEqual(D.wantedClock(started: true, quitting: false, dialogModal: false, wantsFrameTimer: true,
                                     limitFrames: true), .frame)
        XCTAssertEqual(D.wantedClock(started: true, quitting: false, dialogModal: false, wantsFrameTimer: true,
                                     limitFrames: false), .fastFrame)
        XCTAssertEqual(D.wantedClock(started: true, quitting: false, dialogModal: false, wantsFrameTimer: false,
                                     limitFrames: false), .tick)
        XCTAssertEqual(D.wantedClock(started: true, quitting: false, dialogModal: false, wantsFrameTimer: false,
                                     limitFrames: nil), .tick)
    }

    /// The canvas: a 20 px strip, then the screen; the fade darkens everything; PPM header + RGB.
    func testFrameCanvasLayoutAndFade() {
        var screen = RGBAImage(width: 640, height: 480, fill: 0xFF10_2030)
        screen.pixels[0] = 0xFFFF_0000
        let rgba = WinFrame(screen: screen).rgba
        XCTAssertEqual(rgba.count, 640 * 500 * 4)
        XCTAssertEqual(Array(rgba[0..<4]), [0xFF, 0xFF, 0xFF, 0xFF])
        let top = 640 * 20 * 4
        XCTAssertEqual(Array(rgba[top..<top + 8]), [0xFF, 0, 0, 0xFF, 0x10, 0x20, 0x30, 0xFF])
        let black = WinFrame(screen: screen, fade: 255).rgba
        XCTAssertTrue(stride(from: 0, to: black.count, by: 4).allSatisfy { black[$0] == 0 && black[$0 + 3] == 0xFF })
        let ppm = WinFrame(screen: screen).ppm
        let header = Array("P6\n640 500\n255\n".utf8)
        XCTAssertEqual(Array(ppm[0..<header.count]), header)
        XCTAssertEqual(ppm.count, header.count + 640 * 500 * 3)
    }

    func testKeyScriptParses() throws {
        let s = try WinKeyScript(text: """
            # comment
            10 press return
            20 down left       # held
            25 up left
            30 press q cmd
            40 click 320 260
            50 caps on

            60 quit
            70 press 0x31 shift
            """)
        XCTAssertEqual(s.actions(at: 10), [.event(.keyDown(keyCode: 0x24, characters: "\r", modifiers: [], isRepeat: false))])
        XCTAssertEqual(s.actions(at: 11), [.event(.keyUp(keyCode: 0x24, modifiers: []))])
        XCTAssertEqual(s.actions(at: 20), [.event(.keyDown(keyCode: 0x7B, characters: "\u{F702}", modifiers: [],
                                                            isRepeat: false))])
        XCTAssertEqual(s.actions(at: 30), [.event(.keyDown(keyCode: 0x0C, characters: "q", modifiers: .command,
                                                            isRepeat: false))])
        XCTAssertEqual(s.actions(at: 40), [.event(.mouseMoved(x: 320, y: 260)), .event(.mouseDown(x: 320, y: 260))])
        XCTAssertEqual(s.actions(at: 41), [.event(.mouseUp(x: 320, y: 260))])
        XCTAssertEqual(s.actions(at: 50), [.capsLock(true)])
        XCTAssertEqual(s.actions(at: 60), [.event(.quit)])
        XCTAssertEqual(s.actions(at: 70), [.event(.keyDown(keyCode: 0x31, characters: "", modifiers: .shift,
                                                            isRepeat: false))])
        XCTAssertThrowsError(try WinKeyScript(text: "5 press nosuchkey")) {
            XCTAssertEqual(($0 as? WinKeyScript.ParseError)?.line, 1)
        }
        XCTAssertThrowsError(try WinKeyScript(text: "\nx press a"))
        XCTAssertThrowsError(try WinKeyScript(text: "1 press a hyper"))
    }

    func testScriptedInputTracksModifiersAndClock() throws {
        var input = WinScriptedInput(script: try WinKeyScript(text: "0 caps on\n1 down command\n2 up command\n3 caps off"))
        XCTAssertEqual(WinClock.ticks(nanoseconds: input.nanoseconds), 100_000)
        _ = input.events()
        XCTAssertEqual(input.modifiers, .capsLock)
        input.advance()
        XCTAssertEqual(input.events().count, 1)
        XCTAssertEqual(input.modifiers, [.capsLock, .command])
        input.advance(); _ = input.events()
        XCTAssertEqual(input.modifiers, .capsLock)
        input.advance(); _ = input.events()
        XCTAssertEqual(input.modifiers, [])
        XCTAssertEqual(WinClock.ticks(nanoseconds: input.nanoseconds), 100_003)
    }

    func testKeyStateKeepsCapsLockOutOfHeld() {
        var k = WinKeyState()
        k.keyDown(0x39); k.keyDown(0x7B); k.keyDown(0x37)
        XCTAssertEqual(k.held, [0x7B, 0x37])
        k.keyUp(0x7B)
        XCTAssertEqual(k.held, [0x37])
        k.releaseAll()
        XCTAssertEqual(k.held, [])
    }
}
