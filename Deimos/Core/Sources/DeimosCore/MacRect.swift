import Foundation

/// A QuickDraw `Rect` in its field order (top, left, bottom, right). The text `_RECT` values are
/// written (left, top, right, bottom) and re-ordered by the reader (plan Research note 12); sprite
/// frame rects come straight from the plate scan (`FUN_1001f340`, sprite-sound-containers.md §2.2).
public struct MacRect: Equatable, Hashable, Sendable {
    public var top: Int32
    public var left: Int32
    public var bottom: Int32
    public var right: Int32

    public init(top: Int32, left: Int32, bottom: Int32, right: Int32) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }
}
