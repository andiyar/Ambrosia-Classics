import Foundation

/// G_Background.cc's scroll globals (level-scroll-objects.md §1–§5, §9, HIGH): the vertical scroll at
/// 1 px per logic tick, the level end at progress = map bottom, and the horizontal view shift in
/// [−32, 31]. Field comments name the original globals (r2 displacement, TOC r2 = 0x100e6330).
/// The console-only globals (`0x100e012c` spawning disabled, `0x100e013c` unread byte) are not kept.
public struct ScrollState: Equatable, Sendable {
    /// PermFloat 54 VisibleGameWidth (`gafl` item 54).
    static let visibleWidth: Int32 = 416
    /// PermFloat 55 VisibleGameHeight (`gafl` item 55).
    static let visibleHeight: Int32 = 480

    /// `0x100e0128` (−0x6208): px per tick; 1 running, 0 paused.
    public var speed: Int32 = 0
    /// `0x100e0130` (−0x6200): old top − new top this tick.
    public var scrolled: Int32 = 0
    /// `0x100e0140` (−0x61f0): the last horizontal step taken (−1/0/+1; 0 when that step was clamped).
    public var lastShift: Int32 = 0
    /// `0x100e0144` (−0x61ec): horizontal view offset, [−32, 31].
    public var offset: Int32 = 0
    /// `0x100e0148` (−0x61e8): level-end flag (sticky).
    public var levelEnded = false
    /// `0x100e014c` (−0x61e4): rows travelled + 481, clamped to [0, background bottom].
    public var progress: Int32 = 0
    /// `0x100e5abc` (r2−0x874): copy of `#background_RECT`.
    public var backgroundRect = MacRect(top: 0, left: 0, bottom: 0, right: 0)
    /// `0x100e5acc` (r2−0x864): the visible window in map rows.
    public var window = MacRect(top: 0, left: 0, bottom: 0, right: 0)
    /// The terrain buffer's portRect bottom (`FUN_1000a530` on display+0x6c), used by the reverse guard.
    /// `FUN_1000fbc0` sizes that buffer to the map image and asserts image size == RECT, so it is the
    /// RECT's height.
    public var mapBottom: Int32 = 0

    public init() {}

    /// `FUN_1000fa90` (level start). The map load `FUN_1000fbc0` is the caller's `.loadTerrain` op.
    public mutating func levelStart(rect: MacRect) {
        speed = 1                                   // 1000faac/fab8
        levelEnded = false                          // 1000fabc
        scrolled = 0                                // 1000fac0
        offset = 0                                  // 1000fac4
        lastShift = 0                               // 1000fac8
        mapBottom = rect.bottom - rect.top
        backgroundRect = rect                       // 1000fad4…fb04
        window.left = 32                            // 1000fae4/fafc
        if window.left < 0 { window.left = 0 }      // 1000fb08…fb14
        window.top = rect.bottom - Self.visibleHeight              // 1000fb38/fb3c
        window.right = window.left + Self.visibleWidth             // 1000fb5c/fb60
        window.bottom = window.top + Self.visibleHeight            // 1000fb80/fb84
        progress = Self.visibleHeight + 1                          // 1000fb9c/fba0
    }

    /// `FUN_10010220` (advance).
    public mutating func advance() {
        guard speed != 0 else { scrolled = 0; return }             // 1001023c…10010250
        let oldTop = window.top
        window.top = oldTop - speed                                 // 10010260/10010268
        progress += speed                                           // 1001026c
        window.bottom -= speed                                      // 10010280/10010284
        if progress > backgroundRect.bottom {                       // 10010278/10010288
            progress = backgroundRect.bottom
        } else if progress < 0 {                                    // 10010294…100102a0
            progress = 0
        }
        if window.top <= 0 {                                        // 100102a8/100102ac
            window.top = 0
            window.bottom = Self.visibleHeight                      // 100102b8…100102d0
        }
        if window.bottom > mapBottom {                              // 100102e8…100102f4 (reverse guard)
            window.bottom = mapBottom
            window.top = mapBottom - Self.visibleHeight             // 100102fc…1001031c
        }
        scrolled = oldTop - window.top                              // 10010320…10010328
    }

    /// `FUN_10010000` (per-tick scroll step); returns the level-end result.
    /// The spawn-row call (`10010068…10010080`: unless spawning is disabled, `FUN_10033090(top − 64)`)
    /// is Phase 2 — no entities are built in Phase 1.
    public mutating func step() -> Bool {
        advance()                                                   // 10010014
        if speed == 0 { return levelEnded }                         // 10010018…10010034
        if progress >= backgroundRect.bottom {                      // 1001003c…10010048
            progress = backgroundRect.bottom                        // 10010050
            levelEnded = true                                       // 10010058
            speed = 0                                               // 10010060
            return true
        }
        return false
    }

    /// `FUN_1000ffe0`: speed = 0.
    public mutating func pause() {
        speed = 0
    }

    /// `FUN_1000ffc0`: speed = 1, refused once the level has ended.
    public mutating func resume() {
        guard !levelEnded else { return }
        speed = 1
    }

    /// `FUN_100100b0`: one pixel left or right, clamped to [−32, 31]. The step global is zeroed first
    /// (100100b8) and set to ±1 only when no clamp happened.
    public mutating func shift(right: Bool) {
        lastShift = 0
        let step: Int32 = right ? 1 : -1
        offset += step
        if step >= 0 {
            if offset > 31 { offset = 31 } else { lastShift = 1 }
        } else {
            if offset < -32 { offset = -32 } else { lastShift = -1 }
        }
    }

    /// `FUN_10010120`: the terrain → back blit. Source = (top, max(0, offset + 32), window bottom,
    /// that left + 416); destination = (0, 0, 480, 416); mode = byte pref 5 (`FUN_10004ef0(5)`, the
    /// interlace toggle).
    public func terrainBlit(interlaced: Bool) -> RenderOp {
        let left = max(0, offset + 32)                              // 10010138…1001016c
        let src = MacRect(top: window.top, left: left, bottom: window.bottom,
                          right: left + Self.visibleWidth)         // 10010170…100101a0
        let dst = MacRect(top: 0, left: 0, bottom: Self.visibleHeight, right: Self.visibleWidth)
        return .copy(from: .terrain, to: .back, src: src, dst: dst, interlaced: interlaced)
    }
}
