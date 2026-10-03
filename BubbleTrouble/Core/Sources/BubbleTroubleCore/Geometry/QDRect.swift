/// A QuickDraw `Rect` in its native field order (top, left, bottom, right), 16-bit signed like the
/// original. Arithmetic wraps as the original's `short` arithmetic does.
public struct QDRect: Equatable, Hashable, Sendable {
    public var top, left, bottom, right: Int16

    public init(top: Int16, left: Int16, bottom: Int16, right: Int16) {
        self.top = top; self.left = left; self.bottom = bottom; self.right = right
    }

    /// The 40×40 maze cell at (col, row): (row·40, col·40, row·40 + 40, col·40 + 40).
    public static func cell(col: Int, row: Int) -> QDRect {
        let top = Int16(truncatingIfNeeded: row * 40), left = Int16(truncatingIfNeeded: col * 40)
        return QDRect(top: top, left: left, bottom: top &+ 40, right: left &+ 40)
    }

    /// `_RectsCollide @ 0000c398` — strict on every side, so edge-sharing rects do not collide:
    /// `a.left < b.right && b.left < a.right && a.top < b.bottom && b.top < a.bottom`.
    public func collides(_ other: QDRect) -> Bool {
        left < other.right && other.left < right && top < other.bottom && other.top < bottom
    }

    /// `_MyInsetRect @ 0000c3f1`: left += dx, right -= dx, top += dy, bottom -= dy.
    public mutating func inset(dx: Int16, dy: Int16) {
        left &+= dx; right &-= dx; top &+= dy; bottom &-= dy
    }

    /// `_MyOffsetRect @ 0000c3d2` / QuickDraw `OffsetRect`: left/right += dx, top/bottom += dy.
    public mutating func offset(dx: Int16, dy: Int16) {
        left &+= dx; right &+= dx; top &+= dy; bottom &+= dy
    }
}
