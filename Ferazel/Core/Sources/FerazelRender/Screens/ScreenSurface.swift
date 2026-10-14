import Foundation
import FerazelCore

/// The one screen of the game (plan S4, FE0; Hazards "Which screen is current"): the 640×480 8-bit indices, the
/// current screen CLUT (`.SetScreenClut`) and the Monitor-Tool gamma. The level renderer (`FrameRenderer(surface:)`) and
/// the front-end renderer (`ScreenRenderer`) draw on the same surface; the popup and the stage-complete panel draw over
/// whatever is on it. Never a second buffer.
public final class ScreenSurface {
    /// The screen's pixels.
    public var frame: IndexedFrame
    /// The CLUT the screen shows through (index i shows entry i's colour).
    public var clut: ColorLUT
    /// The screen gamma the fades leave.
    public var gamma: ScreenGamma

    public init(clut: ColorLUT, frame: IndexedFrame = IndexedFrame(), gamma: ScreenGamma = .identity) {
        self.clut = clut
        self.frame = frame
        self.gamma = gamma
    }

    /// `clut` through `gamma` — what the screen shows; presentation only.
    public var presentedClut: ColorLUT { gamma.apply(clut) }

    /// The screen as 0xAARRGGBB words (`IndexedFrame.rgba`).
    public func rgba() -> [UInt32] { frame.rgba(through: clut, gamma: gamma) }
}
