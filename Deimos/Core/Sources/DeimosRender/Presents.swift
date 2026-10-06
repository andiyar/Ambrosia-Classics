import Foundation
import DeimosCore

/// The three presents: back buffer → the 640×480 window (display-window-present §5). Each is `srcCopy` through the
/// one screen blit `FUN_1000ac20` (§5.1): no VBL wait, no page flip, no interlacing. Rects below are Mac order
/// (top, left, bottom, right), with the 640×480 DrawSprocket context of 1.0.6 (display rect `D+0xc` = (0,0,480,640),
/// `D+0x64` = 0, the menu-bar offset 0 after set-up).
public enum Presents {
    public static let screenWidth = 640
    public static let screenHeight = 480

    public static func present(_ kind: PresentKind, back: Pixmap555, screen: inout Pixmap555) {
        switch kind {
        case .gameScreen:
            // FUN_1000beb0 (§5.5). Step 3 (the band above the display, only when the screen is wider than 640,
            // `D+0x64`) never runs on the 640×480 context. Step 4: left border and right strip, both F59 = 32 wide.
            screen.fill(MacRect(top: 0, left: 0, bottom: 480, right: 32), colour: 0)
            screen.fill(MacRect(top: 0, left: 608, bottom: 480, right: 640), colour: 0)
            // Step 5: game area, back {0,0,F55 480,F54 416} → `D+0x1c` (0,32,480,448).
            CopyBits.copy(from: back, to: &screen, srcRect: MacRect(top: 0, left: 0, bottom: 480, right: 416),
                          dstRect: MacRect(top: 0, left: 32, bottom: 480, right: 448))
            // Step 6: score bar, back `D+0x3c` (0,416,480,576) → `D+0x2c` (0,448,480,608) — of the back buffer
            // `+0x68`, not the save buffer `+0x70` (`1000c234`).
            CopyBits.copy(from: back, to: &screen, srcRect: MacRect(top: 0, left: 416, bottom: 480, right: 576),
                          dstRect: MacRect(top: 0, left: 448, bottom: 480, right: 608))
        case .gameLayout:
            // FUN_1000bd80 (§5.4): back {0,0,480,F52 − F59 = 608} → {0, D+0x20 = 32, 480, 640}. Screen x 0…31 is not
            // touched and nothing is painted (listing `1000bd8c…1000be84`).
            CopyBits.copy(from: back, to: &screen, srcRect: MacRect(top: 0, left: 0, bottom: 480, right: 608),
                          dstRect: MacRect(top: 0, left: 32, bottom: 480, right: 640))
        case .fullScreen:
            // FUN_1000bc60 (§5.3): back {0,0,F53 480,F52 640} → the display rect (0,0,480,640), 1:1.
            CopyBits.copy(from: back, to: &screen, srcRect: MacRect(top: 0, left: 0, bottom: 480, right: 640),
                          dstRect: MacRect(top: 0, left: 0, bottom: 480, right: 640))
        }
    }
}

/// The display object `D`'s buffers (display-window-present §4) plus the window's pixels: the persistent state
/// `DeimosRenderer` (R3) composes. All black at creation (`FUN_10009f00` colour 0 ×3; the window is painted black
/// by `FUN_1000a640`/`FUN_1000ab50`).
public struct DisplayBuffers: Sendable {
    /// `D+0x68`, the 640×480 work/back buffer.
    public var back = Pixmap555(width: 640, height: 480)
    /// `D+0x6c`, the terrain picture (640×480 at creation; resized to the level map by `.loadTerrain`, R3).
    public var terrain = Pixmap555(width: 640, height: 480)
    /// `D+0x70`, the 160×480 score-bar save buffer (F57 × F58).
    public var scoreSave = Pixmap555(width: 160, height: 480)
    /// The 640×480 window content.
    public var screen = Pixmap555(width: Presents.screenWidth, height: Presents.screenHeight)
    /// The clones a blocking fade holds between `fadeBegin` and `fadeEnd` (Fades.swift).
    var fadeSnapshot: Pixmap555?
    var fadeBlack: Pixmap555?

    public init() {}

    public func buffer(_ id: BufferID) -> Pixmap555 {
        switch id {
        case .back: return back
        case .terrain: return terrain
        case .scoreSave: return scoreSave
        }
    }

    public mutating func present(_ kind: PresentKind) {
        Presents.present(kind, back: back, screen: &screen)
    }
}
