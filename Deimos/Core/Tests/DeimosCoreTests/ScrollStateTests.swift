import XCTest
@testable import DeimosCore

/// G_Background's scroll state: level-scroll-objects.md §1–§5, §9 (HIGH), listing `FUN_1000fa90`…`FUN_10010220`.
final class ScrollStateTests: XCTestCase {
    /// `#background_RECT` of every level (top 0, left 0, bottom 3600, right 480; §1).
    private let background = MacRect(top: 0, left: 0, bottom: 3600, right: 480)

    private func started() -> ScrollState {
        var s = ScrollState()
        s.levelStart(rect: background)
        return s
    }

    func testLevelStartWindow() {
        var s = ScrollState()
        s.offset = 7; s.lastShift = 1; s.levelEnded = true; s.scrolled = 3
        s.levelStart(rect: background)
        XCTAssertEqual(s.speed, 1)
        XCTAssertFalse(s.levelEnded)
        XCTAssertEqual(s.scrolled, 0)
        XCTAssertEqual(s.offset, 0)
        XCTAssertEqual(s.lastShift, 0)
        XCTAssertEqual(s.backgroundRect, background)
        XCTAssertEqual(s.window, MacRect(top: 3120, left: 32, bottom: 3600, right: 448))
        XCTAssertEqual(s.progress, 481)
    }

    func testAdvanceOnePixelPerTick() {
        var s = started()
        for k in 1...500 {
            XCTAssertFalse(s.step())
            XCTAssertEqual(s.window.top, 3120 - Int32(k))
            XCTAssertEqual(s.window.bottom, 3600 - Int32(k))
            XCTAssertEqual(s.progress, 481 + Int32(k))
            XCTAssertEqual(s.scrolled, 1)
        }
        XCTAssertEqual(s.window.left, 32)
        XCTAssertEqual(s.window.right, 448)
    }

    func testLevelEndOnScrollTick3119() {
        var s = started()
        for k in 1...3118 {
            XCTAssertFalse(s.step(), "no end at scroll tick \(k)")
        }
        XCTAssertFalse(s.levelEnded)
        XCTAssertEqual(s.progress, 3599)
        XCTAssertTrue(s.step(), "scroll tick 3119 reaches progress 3600")
        XCTAssertTrue(s.levelEnded)
        XCTAssertEqual(s.window.top, 1)
        XCTAssertEqual(s.progress, 3600)
        XCTAssertEqual(s.speed, 0)
        // Sticky: speed stays 0, step returns 1 every tick, nothing scrolls, resume is refused.
        for _ in 0..<5 {
            XCTAssertTrue(s.step())
            XCTAssertEqual(s.scrolled, 0)
            XCTAssertEqual(s.window.top, 1)
        }
        s.resume()
        XCTAssertEqual(s.speed, 0, "FUN_1000ffc0 refuses to resume once ended")
        XCTAssertTrue(s.step())
        XCTAssertEqual(s.window.top, 1)
    }

    func testPauseResume() {
        var s = started()
        XCTAssertFalse(s.step())
        s.pause()
        XCTAssertEqual(s.speed, 0)
        for _ in 0..<10 {
            XCTAssertFalse(s.step(), "paused, not ended → 0")
            XCTAssertEqual(s.scrolled, 0)
        }
        XCTAssertEqual(s.window.top, 3119)
        XCTAssertEqual(s.progress, 482)
        s.resume()
        XCTAssertEqual(s.speed, 1)
        XCTAssertFalse(s.step())
        XCTAssertEqual(s.window.top, 3118)
        XCTAssertEqual(s.progress, 483)
        XCTAssertEqual(s.scrolled, 1)
    }

    func testShiftClamp() {
        var s = started()
        s.shift(right: false)
        XCTAssertEqual(s.offset, -1)
        XCTAssertEqual(s.lastShift, -1)
        for _ in 0..<39 { s.shift(right: false) }
        XCTAssertEqual(s.offset, -32)
        XCTAssertEqual(s.lastShift, 0, "a clamped step stores 0 (100100b8, 100100ec)")
        s.shift(right: true)
        XCTAssertEqual(s.offset, -31)
        XCTAssertEqual(s.lastShift, 1)
        var r = started()
        for _ in 0..<70 { r.shift(right: true) }
        XCTAssertEqual(r.offset, 31)
        XCTAssertEqual(r.lastShift, 0)
        var u = started()
        for _ in 0..<31 { u.shift(right: true) }
        XCTAssertEqual(u.offset, 31)
        XCTAssertEqual(u.lastShift, 1, "the 31st step lands on 31 without clamping")
    }

    func testTerrainBlitRects() {
        var s = started()
        for _ in 0..<5 { _ = s.step() }   // top 3115
        let dst = MacRect(top: 0, left: 0, bottom: 480, right: 416)
        for _ in 0..<40 { s.shift(right: false) }
        XCTAssertEqual(s.offset, -32)
        XCTAssertEqual(s.terrainBlit(interlaced: false),
                       .copy(from: .terrain, to: .back,
                             src: MacRect(top: 3115, left: 0, bottom: 3595, right: 416), dst: dst, interlaced: false))
        for _ in 0..<32 { s.shift(right: true) }
        XCTAssertEqual(s.offset, 0)
        XCTAssertEqual(s.terrainBlit(interlaced: true),
                       .copy(from: .terrain, to: .back,
                             src: MacRect(top: 3115, left: 32, bottom: 3595, right: 448), dst: dst, interlaced: true))
        for _ in 0..<40 { s.shift(right: true) }
        XCTAssertEqual(s.offset, 31)
        XCTAssertEqual(s.terrainBlit(interlaced: false),
                       .copy(from: .terrain, to: .back,
                             src: MacRect(top: 3115, left: 63, bottom: 3595, right: 479), dst: dst, interlaced: false))
    }
}
