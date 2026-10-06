import Foundation

/// The 0x38-byte frame-controller object each loop keeps on its stack (timing-frame.md §1–§2.5, HIGH):
/// the tick flag and speed divider, frames presented, the FPS-window frame counter and the Esc hold.
/// Phase 1 carries only this arithmetic; the FPS monitor (`FUN_100305e0`/`FUN_10030640`), the limiter
/// wait, auto-interlace, Caps-Lock pause and the presents are not here (the limiter/present are
/// `RenderOp`s; the rest is Phase 2). Esc only REPORTS quit: the pass in which it is detected still
/// completes — stopping the session is the caller's (review M1).
public struct FrameController: Equatable, Sendable {
    /// +0x00 paused (Caps Lock). Never set in Phase 1.
    public var paused = false
    /// +0x01 film playback (no pause allowed).
    public var filmPlayback = false
    /// +0x02 quit chosen on the pause screen — always false in 1.0.6 (timing-frame §1 ⚑ C9).
    public var quitChosen = false
    /// +0x03 auto-interlace allowed.
    public var autoInterlaceAllowed = false
    /// +0x04 game-screen layout (true → `FUN_1000beb0`, false → `FUN_1000bc60`).
    public var gameScreenLayout = false
    /// +0x08 frames presented (`FUN_10030bc0` +1, `10030d34..d3c`).
    public var framesPresented: Int32 = 0
    /// +0x14 Esc-hold counter (`FUN_100307c0`).
    public var escHold: Int32 = 0
    /// +0x20 frames counted in the current FPS window (`10030d40..d48`).
    public var windowFrames: Int32 = 0
    /// +0x2c speed divider — only ever 0 in 1.0.6 (timing-frame §3).
    public var speedDivider: Int32 = 0
    /// +0x30 divider countdown.
    public var dividerCountdown: Int32 = 0
    /// +0x34 tick-next-frame flag.
    public var tickNextFrame = false
    /// `PermFloat 32` (FPS_MaxRate, = 30) as `fctiwz` truncates it: the Esc-hold limit
    /// (`1003081c bl 0x10020250` with r3 = 0x20). Not a field of the original object.
    public let fpsMaxRate: Int32

    /// What begin frame hands the loop.
    public struct Begin: Equatable, Sendable {
        /// `*param_2` = the tick flag (+0x34): run the world update this pass.
        public var tick: Bool
        /// The quit flag: Esc (`FUN_100307c0`) or +0x02.
        public var quit: Bool
        /// The return value, +0x08 (the game stores it at game +0x30, `10005910`).
        public var framesPresented: Int32
    }

    /// `FUN_10030190`/`FUN_10030df0` — zero every field (`10030e0c..10030e54`).
    public init(fpsMaxRate: Int32) { self.fpsMaxRate = fpsMaxRate }

    /// `FUN_10030210` — start session: zero, set +1/+4/+3, then the divider reset `FUN_10030790`.
    /// (Its other calls — layer queues, console, messages, FPS-monitor init, FlushEvents — are not
    /// controller arithmetic.)
    public mutating func startSession(filmPlayback: Bool, gameScreenLayout: Bool, autoInterlaceAllowed: Bool) {
        self = FrameController(fpsMaxRate: fpsMaxRate)
        self.filmPlayback = filmPlayback
        self.gameScreenLayout = gameScreenLayout
        self.autoInterlaceAllowed = autoInterlaceAllowed
        resetDivider()
    }

    /// `FUN_10030790` — +0x2c = 0, +0x30 = 0, +0x34 = 1 (`10030790..100307a0`).
    public mutating func resetDivider() {
        speedDivider = 0
        dividerCountdown = 0
        tickNextFrame = true
    }

    /// `FUN_100307c0 @ 100307c0` — Esc (key 0x35): up → +0x14 = 0, no quit; down with byte pref 8 off →
    /// quit at once; down with pref 8 on → +0x14 += 1, quit when +0x14 > PermFloat 32 (`10030834 cmpw;
    /// ble`).
    public mutating func escCheck(escDown: Bool, escHoldPref: Bool) -> Bool {
        guard escDown else { escHold = 0; return false }
        guard escHoldPref else { return true }
        escHold &+= 1
        return escHold > fpsMaxRate
    }

    /// `FUN_10030360` — begin frame, the controller's part: quit = Esc or +0x02; returns the tick flag
    /// and +0x08.
    public mutating func beginFrame(escDown: Bool, escHoldPref: Bool) -> Begin {
        let quit = escCheck(escDown: escDown, escHoldPref: escHoldPref) || quitChosen
        return Begin(tick: tickNextFrame, quit: quit, framesPresented: framesPresented)
    }

    /// `FUN_10030bc0` steps 4–5 — counters (+0x08 += 1, +0x20 += 1, `10030d34..10030d48`), then the
    /// divider decides the next frame's tick (`10030d4c..10030d80`): countdown 0 → tick, countdown =
    /// divider; else no tick and, unless divider == 999, countdown −= 1.
    public mutating func endFrame() {
        framesPresented &+= 1
        windowFrames &+= 1
        if dividerCountdown == 0 {
            tickNextFrame = true
            dividerCountdown = speedDivider
        } else {
            tickNextFrame = false
            if speedDivider != 999 { dividerCountdown &-= 1 }
        }
    }

    /// `FUN_10030570` — the end-frame wrapper: `FUN_10030bc0`, then `FUN_100307c0` again with the result
    /// discarded (timing-frame §2.4). The pause screen and FPS monitor that follow are Phase 2.
    public mutating func endFrameWrapper(escDown: Bool, escHoldPref: Bool) {
        endFrame()
        _ = escCheck(escDown: escDown, escHoldPref: escHoldPref)
    }
}
