import Foundation

/// `.Credits @ 1000e5b4` → `.DoAboutDialog(600, 0x12c3) @ 1007853c` (M l. 7291–7299, 65263–65435): DLOG 600 (its
/// DITL item 1 is PICT 4804, the background) with the PICT 4803 strip (144×811) scrolling up inside a clip. The timing
/// lives here; the App draws DLOG 600 and the strip at `dest(now:)` clipped to `clip` (dialog-local coordinates).
///
/// The loop (M l. 65411–65436): `CopyBits` of the whole strip into the dest rect, `OffsetRect(0, −1)`, step + 1,
/// `Delay(3)`, then the click check; after `stripHeight + 150` steps the rect is reset to the start. The 1-bit GWorld
/// the routine fills with grey lines (M l. 65352–65371) is never copied anywhere — nothing to draw.
public struct CreditsScroll: Equatable, Sendable {
    /// DLOG 600 (`GetNewDialog(param_1 = 600)`) and the strip PICT (`GetPicture(0x12c3)`).
    public static let dialog: Int16 = 600
    public static let stripPicture: Int16 = 0x12c3
    /// `Delay(3)` per 1-px step.
    public static let ticksPerStep = 3

    /// `SetRect(0x22, 0x78, 0xaa, 0x10e)` → `ClipRect` (l 34, t 120, r 170, b 270).
    public let clip = Rect16(top: 0x78, left: 0x22, bottom: 0x10e, right: 0xaa)
    /// The strip's size (picFrame: 144 × 811 for the shipped PICT 4803).
    public let stripWidth: Int
    public let stripHeight: Int
    /// The tick of the first `CopyBits`.
    public let start: UInt32

    public init(start: UInt32, stripWidth: Int = 144, stripHeight: Int = 811) {
        self.start = start
        self.stripWidth = stripWidth
        self.stripHeight = stripHeight
    }

    /// `*psVar6 = height + 0x96`: the steps before the rect is reset.
    public var stepsPerCycle: Int { stripHeight + 0x96 }

    /// The pixels the strip has moved up for the copy made at `now` (step k at `start + 3k`; wraps after 961 steps).
    public func offset(now: UInt32) -> Int {
        let k = Int(now &- start) / Self.ticksPerStep
        return stepsPerCycle > 0 ? k % stepsPerCycle : 0
    }

    /// The strip's dest rect for the copy made at `now`: `SetRect(0x22, 0x10e, w + 0x22, h + 0x10e)` moved up by
    /// `offset(now:)`.
    public func dest(now: UInt32) -> Rect16 {
        let top = 0x10e - offset(now: now)
        return Rect16(top: Int16(truncatingIfNeeded: top), left: 0x22,
                      bottom: Int16(truncatingIfNeeded: top + stripHeight),
                      right: Int16(truncatingIfNeeded: 0x22 + stripWidth))
    }

    /// What a mouse-down does (checked after each step's `Delay(3)`; `FlushEvents(mDownMask)` swallows it): inside the
    /// dialog's port rect the dialog closes, outside `SysBeep(0x19)`.
    public enum Click: Equatable, Sendable { case close, beep }

    public func click(insideDialog: Bool) -> Click { insideDialog ? .close : .beep }
}
