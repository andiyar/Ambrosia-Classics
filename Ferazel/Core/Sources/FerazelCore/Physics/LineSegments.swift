import Foundation

/// The two segment routines of the rotating blade's player arm (6A-BD; phase6-engine-contracts §2.9 item 4). Their only
/// caller is `.HitPlayerSprite`'s 0xbf4 arm (M l. 49710), so no level without a blade reaches them.
public enum LineSegments {
    /// `.SectLineSegs(a, b, c, d, e, f, g, h) @ 10045340` (M l. 39507–39561): segment (a, b)–(c, d) against (e, f)–(g, h),
    /// all i32 with wrapping products (`mullw`). k = c·b − a·d; s1 = (d − b)·e + (a − c)·f + k, s2 = (d − b)·g + (a − c)·h
    /// + k; both non-zero and of the same sign → false (the second segment lies on one side of the first's line). Then
    /// the same with the roles swapped (k = g·f − e·h, over (a, b) and (c, d)). Otherwise true: a zero product (an end on
    /// the other's line) counts as a crossing, and so do collinear segments that do not overlap (every product 0).
    public static func sectLineSegs(_ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32, _ e: Int32, _ f: Int32,
                                    _ g: Int32, _ h: Int32) -> Bool {
        var k = c &* b &- a &* d
        var s1 = (d &- b) &* e &+ (a &- c) &* f &+ k
        var s2 = (d &- b) &* g &+ (a &- c) &* h &+ k
        if s1 != 0 && s2 != 0 && (s1 < 0) == (s2 < 0) { return false }
        k = g &* f &- e &* h
        s1 = (h &- f) &* a &+ (e &- g) &* b &+ k
        s2 = (h &- f) &* c &+ (e &- g) &* d &+ k
        if s1 != 0 && s2 != 0 && (s1 < 0) == (s2 < 0) { return false }
        return true
    }

    /// `.SectRectLineSeg(rect, x1, y1, x2, y2) @ 10045468` (M l. 39562–39601): the segment against the rect's top edge
    /// (left, top)–(right, top), then the bottom (left, bottom)–(right, bottom), the left (left, top)–(left, bottom) and
    /// the right (right, top)–(right, bottom) — the first hit wins. No containment test: a segment wholly inside the
    /// rect does not hit. The rect's edges are the 16-bit fields as stored (`Rect` holds them sign-extended).
    public static func sectRectLineSeg(_ r: IdleSprites.Rect, _ x1: Int32, _ y1: Int32, _ x2: Int32,
                                       _ y2: Int32) -> Bool {
        let t = Int32(Int16(truncatingIfNeeded: r.top)), l = Int32(Int16(truncatingIfNeeded: r.left))
        let b = Int32(Int16(truncatingIfNeeded: r.bottom)), rt = Int32(Int16(truncatingIfNeeded: r.right))
        return sectLineSegs(x1, y1, x2, y2, l, t, rt, t)
            || sectLineSegs(x1, y1, x2, y2, l, b, rt, b)
            || sectLineSegs(x1, y1, x2, y2, l, t, l, b)
            || sectLineSegs(x1, y1, x2, y2, rt, t, rt, b)
    }
}
