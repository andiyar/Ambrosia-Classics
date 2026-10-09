import Foundation

/// ◇ Phase-1 stub (plan S2; replaced by `.PlayerScroll @ 1004c528` in Phase 2): the keys move the camera's focus.
///
/// Two points, as the binary keeps them (⚑ plan "Bank corrections to append" item 10):
/// - `point` = `(_DAT_1009fd94, _DAT_1009fd90)`, the player's hot-rect centre: `.GameLoop` sets it to the sprite
///   origin + (0x32, 0x3b) (l. 5149–5150) and the Handle rewrites it every frame (l. 46376–46388). Here it starts there
///   and the keys move it, in 1/256 px.
/// - `focus` = `(_DAT_1009fd44, _DAT_1009fd40)`, what `.FindUpperLeftCorner` reads: `.SetupPlayerSprite` sets it to
///   the sprite origin (`+8`/`+6`, l. 42834–42840); `.PlayerScroll` sets `fd44 = fd94 + (look-ahead >> 8)` and, on
///   the ground with `DAT_100a5f58` set (`.ClearPlayerVars`), `fd40 = fd90` (l. 43794, 43809–43816). The stub copies
///   the point with no look-ahead, in the Handle's place (`.PaintFrameWrap` → `.HandleSprites`, after the draw).
///
/// Held left / right / up / down — the arrow keys or the action keys 0..3 (keypad 4 / 6 / 8 / 5 by default) — move the
/// point 0x76c (1900) per frame, 0xc80 (3200) with run (action 4) held: the walk / run maxima `_DAT_100a600a/600c`
/// (main l. 44561–44564). The point is kept inside the map.
public struct CameraFocusDriver: Equatable, Sendable {
    public static let walkSpeed = 0x76c
    public static let runSpeed = 0xc80
    /// Mac virtual key codes of the arrow keys.
    public static let arrowLeft = 0x7b
    public static let arrowRight = 0x7c
    public static let arrowDown = 0x7d
    public static let arrowUp = 0x7e

    /// The held directions and run, from the arrows or the prefs' action keys 0..4.
    public struct Held: Equatable, Sendable {
        public var left = false, right = false, up = false, down = false, run = false

        public init(keys: KeyState, prefs: FerazelPrefs) {
            let a = InputActions(keys: keys, prefs: prefs)
            left = a.contains(.left) || keys.isPressed(CameraFocusDriver.arrowLeft)
            right = a.contains(.right) || keys.isPressed(CameraFocusDriver.arrowRight)
            up = a.contains(.up) || keys.isPressed(CameraFocusDriver.arrowUp)
            down = a.contains(.down) || keys.isPressed(CameraFocusDriver.arrowDown)
            run = a.contains(.run)
        }
    }

    /// `fd94` / `fd90` × 256.
    public private(set) var pointX256: Int
    public private(set) var pointY256: Int
    /// `fd44` / `fd40`.
    public private(set) var focusX: Int
    public private(set) var focusY: Int
    /// The stub's horizontal velocity (1/256 px per frame) — what `.FindUpperLeftCorner`'s snap test reads as vx.
    public private(set) var vx = 0
    /// The point's bounds (the map in px).
    public let width: Int
    public let height: Int

    public var pointX: Int { pointX256 >> 8 }
    public var pointY: Int { pointY256 >> 8 }

    /// The level start for sprite origin (x, y) on a map of `width` × `height` px.
    public init(spriteX: Int, spriteY: Int, width: Int = 200 * 32, height: Int = 50 * 32) {
        pointX256 = (spriteX + 0x32) << 8
        pointY256 = (spriteY + 0x3b) << 8
        focusX = spriteX
        focusY = spriteY
        self.width = width
        self.height = height
    }

    /// One Handle frame: move the point by the held keys, then copy it to the focus.
    public mutating func step(keys: KeyState, prefs: FerazelPrefs) {
        step(Held(keys: keys, prefs: prefs))
    }

    public mutating func step(_ held: Held) {
        let speed = held.run ? Self.runSpeed : Self.walkSpeed
        vx = (held.right ? speed : 0) - (held.left ? speed : 0)
        let vy = (held.down ? speed : 0) - (held.up ? speed : 0)
        pointX256 = min(max(pointX256 + vx, 0), (width << 8) - 1)
        pointY256 = min(max(pointY256 + vy, 0), (height << 8) - 1)
        focusX = pointX
        focusY = pointY
    }
}
