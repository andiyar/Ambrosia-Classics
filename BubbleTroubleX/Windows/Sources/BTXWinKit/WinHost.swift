import BubbleTroubleRender
import Foundation

// The platform seam of the Windows port (plan W4): what `WinGameDriver` needs from a window, an input queue, a clock,
// a cursor and a sound device. `BubbleTroubleXWin` implements it with HectorSDL; the tests implement it with a
// scripted host. Everything here is Foundation-only (no SDL types), so the driver is `swift test`-able on the Mac.

/// The modifier keys, as the Mac names them (HectorSDL maps Ctrl → `.command`, Alt → `.option`, the Windows key →
/// `.control` — DECISIONS D15 "Ctrl for ⌘", D18.5).
public struct WinModifiers: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let shift = WinModifiers(rawValue: 1 << 0)
    public static let command = WinModifiers(rawValue: 1 << 1)
    public static let option = WinModifiers(rawValue: 1 << 2)
    public static let control = WinModifiers(rawValue: 1 << 3)
    public static let capsLock = WinModifiers(rawValue: 1 << 4)
}

/// One input event in Mac terms (the shape of HectorSDL's `HostEvent`, restated here so BTXWinKit needs no SDL).
/// Key codes are Carbon `kVK_*`; `characters` is what `NSEvent.characters` would carry; mouse coordinates are
/// pixels of the whole 640×500 window canvas (the 20 px menu strip on top, then the 640×480 game screen).
public enum WinEvent: Sendable, Hashable {
    case keyDown(keyCode: UInt16, characters: String, modifiers: WinModifiers, isRepeat: Bool)
    case keyUp(keyCode: UInt16, modifiers: WinModifiers)
    case mouseDown(x: Int, y: Int)
    case mouseUp(x: Int, y: Int)
    case mouseMoved(x: Int, y: Int)
    /// The window's close box / an OS quit request — the Mac's quit Apple event.
    case quit
    case focusLost
    case focusGained
}

/// The cursor the game asked for (`_SetMyCCursor(200)` = the hand from `crsr 200`, `_InitCursor` = the arrow;
/// `_WatchCursor` keeps the arrow, as the Mac replica does).
public enum WinCursor: Sendable, Hashable {
    case arrow
    case hand
}

/// The window canvas: the 640×480 game screen under a 20 px strip reserved for the in-window menu bar (W5).
public enum WinCanvas {
    public static let width = Compositor.width
    public static let menuStripHeight = 20
    public static let height = Compositor.height + menuStripHeight
    /// The strip's colour until W5 draws the menu bar (0xRRGGBB): plain white.
    public static let blankStrip: UInt32 = 0xFFFFFF
}

/// One presented frame: the compositor's screen plus the display fade. `rgba` builds the 640×500 RGBA8 canvas
/// (top row first, alpha 0xFF) only when a host asks for bytes.
public struct WinFrame: Sendable {
    /// The game screen, 640×480, 0xAARRGGBB.
    public let screen: RGBAImage
    /// `CGDisplayFade`'s darkness, 0 (clear) … 255 (black), applied to the whole window.
    public let fade: Int

    public init(screen: RGBAImage, fade: Int = 0) {
        self.screen = screen
        self.fade = max(0, min(255, fade))
    }

    public var rgba: [UInt8] {
        let w = WinCanvas.width, strip = WinCanvas.menuStripHeight
        var out = [UInt8](repeating: 0xFF, count: w * WinCanvas.height * 4)
        let keep = 255 - fade
        func put(_ i: Int, _ argb: UInt32) {
            let r = Int((argb >> 16) & 0xFF), g = Int((argb >> 8) & 0xFF), b = Int(argb & 0xFF)
            out[i] = UInt8(r * keep / 255)
            out[i + 1] = UInt8(g * keep / 255)
            out[i + 2] = UInt8(b * keep / 255)
            out[i + 3] = 0xFF
        }
        for i in 0..<(w * strip) { put(i * 4, WinCanvas.blankStrip) }
        screen.pixels.withUnsafeBufferPointer { px in
            for i in 0..<min(px.count, w * Compositor.height) { put((w * strip + i) * 4, px[i]) }
        }
        return out
    }

    /// Binary PPM (P6) of `rgba` — the `--dump` format (HectorSDL's smoke uses the same).
    public var ppm: [UInt8] {
        let rgba = self.rgba
        var out = Array("P6\n\(WinCanvas.width) \(WinCanvas.height)\n255\n".utf8)
        out.reserveCapacity(out.count + WinCanvas.width * WinCanvas.height * 3)
        for p in 0..<(WinCanvas.width * WinCanvas.height) { out.append(contentsOf: rgba[p * 4 ..< p * 4 + 3]) }
        return out
    }
}

/// What the driver needs from the platform. Single-threaded: every call comes from the game's main loop.
public protocol WinHost: AnyObject {
    /// Monotonic nanoseconds (only differences matter). A scripted host returns a fixed-step virtual clock.
    var nanoseconds: UInt64 { get }
    /// The modifier keys held now (Caps Lock = its lock state), polled like `GetKeys` once per clock fire.
    var modifiers: WinModifiers { get }
    /// Drains the input queue.
    func pollEvents() -> [WinEvent]
    /// Shows one frame.
    func present(_ frame: WinFrame)
    /// `_HideMyCursor` / `_ShowMyCursor` (idempotent at the driver).
    func setCursorVisible(_ visible: Bool)
    /// `_SetMyCCursor` / `_InitCursor`.
    func setCursor(_ cursor: WinCursor)
    /// The play-mode mouse capture (the Mac warps the pointer to the centre and decouples it) on / off; the host
    /// remembers where the pointer was (`gSavedMousePosition`).
    func setMouseCaptured(_ captured: Bool)
    /// `.restoreMousePosition`: the pointer back where the capture found it.
    func restoreMousePosition()
    /// `_SysBeep(1)`.
    func beep()
    /// The driver has finished (prefs saved or not, by the quit rules): close the window and leave the loop.
    func quit()
}

/// TickCount (1/60 s) from monotonic nanoseconds, without overflow, wrapping at 2³² like the Toolbox's.
public enum WinClock {
    public static let nanosPerSecond: UInt64 = 1_000_000_000

    public static func ticks(nanoseconds n: UInt64) -> UInt32 {
        let whole = n / nanosPerSecond, rest = n % nanosPerSecond
        return UInt32(truncatingIfNeeded: whole &* 60 &+ rest * 60 / nanosPerSecond)
    }

    /// The first nanosecond at which `ticks(nanoseconds:)` reaches `tick` — the fixed-step clock's n-th step.
    public static func nanoseconds(atTick tick: UInt64) -> UInt64 {
        let whole = tick / 60, rest = tick % 60
        return whole * nanosPerSecond + (rest * nanosPerSecond + 59) / 60
    }
}

/// A repeating timer as `NSTimer` (HectorShell `ShellIdleTimer`) behaves: the first fire one interval after
/// `start`, then on the original schedule (fire k at start + k·interval, computed exactly — 1/60 s is not a whole
/// number of nanoseconds); when the loop comes late it fires once and the missed fires are dropped (the original's
/// `gTimerFired` flag — never caught up). A fire counts as due up to `slack` (1 µs) early, so a fixed-step clock
/// that lands on the schedule's rounding never misses one.
public struct WinTimer: Sendable, Equatable {
    /// The interval is `numerator / denominator` nanoseconds.
    public let numerator: UInt64
    public let denominator: UInt64
    public static let slack: UInt64 = 1_000
    private var startedAt: UInt64?
    private var count: UInt64 = 0

    public init(intervalNanoseconds: UInt64, per denominator: UInt64 = 1) {
        precondition(intervalNanoseconds > 0 && denominator > 0)
        numerator = intervalNanoseconds
        self.denominator = denominator
    }

    public var isRunning: Bool { startedAt != nil }

    /// When the next fire is due (nil when stopped).
    public var nextFire: UInt64? {
        guard let s = startedAt else { return nil }
        return s + count * numerator / denominator
    }

    public mutating func start(now: UInt64) {
        startedAt = now
        count = 1
    }

    public mutating func invalidate() { startedAt = nil }

    /// True (once) when a fire is due at `now`; the next fire moves past `now` on the original schedule.
    public mutating func poll(now: UInt64) -> Bool {
        guard let s = startedAt, let next = nextFire, now + Self.slack >= next else { return false }
        count = (now + Self.slack - s) * denominator / numerator + 1
        return true
    }
}
