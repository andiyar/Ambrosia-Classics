import Foundation

/// A QuickDraw `Rect` — `{top, left, bottom, right}`, 16-bit, right and bottom exclusive (plan S2, FE0; LOCKED).
public struct Rect16: Equatable, Hashable, Sendable {
    public var top: Int16
    public var left: Int16
    public var bottom: Int16
    public var right: Int16

    public init(top: Int16, left: Int16, bottom: Int16, right: Int16) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }

    /// `right − left` (may be ≤ 0: an empty rect).
    public var width: Int { Int(right) - Int(left) }
    /// `bottom − top` (may be ≤ 0: an empty rect).
    public var height: Int { Int(bottom) - Int(top) }
}
