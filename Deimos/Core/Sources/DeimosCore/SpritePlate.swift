import Foundation

/// A sprite-plate scan failure: the original's data-error asserts in U_SpritePlate.cc
/// (`FUN_1001f1c0`; sprite-sound-containers.md §2.2). `assertText` is the asserted expression as the
/// 1.0.6 binary's string pool carries it.
public enum SpritePlateError: Error, Equatable, Sendable {
    /// `alphaIndices.count != width × height` (a caller error, not an original assert).
    case indexCountMismatch(count: Int, width: Int, height: Int)
    /// Plate narrower than 3 or shorter than 2 (the three row-0 key pixels and a strip row are read).
    case plateTooSmall(width: Int, height: Int)
    /// Row-0 key pixels: fill (0,0) equals grid (1,0) — `FALSE`, line 0x6b.
    case fillEqualsGrid
    /// Row-0 key pixels: grid (1,0) equals key (2,0) — `FALSE`, line 0x71.
    case gridEqualsKey
    /// The scan found no frame — `outRectListPtr->GetNumLinks() > 0`.
    case noFrames

    /// The assert's expression text (this port's text where the binary carries none).
    public var assertText: String {
        switch self {
        case .indexCountMismatch: return "alphaIndices.count == width * height"
        case .plateTooSmall: return "plateWidth >= 3 and plateHeight >= 2"
        case .fillEqualsGrid, .gridEqualsKey: return "FALSE"
        case .noFrames: return "outRectListPtr->GetNumLinks() > 0"
        }
    }
}

/// The sprite-plate frame scan (U_SpritePlate.cc `FUN_1001f140/1f1c0/1f340/1f4e0/1f540/1f5b0`;
/// sprite-sound-containers.md §2.2; plan Research note 17), run — as the original runs it — on the
/// **8-bit** alpha plate: each pixel is the system-CLUT index of its palette colour
/// (`QuickDrawColor.systemIndex`), not its RGB (plan invariant 5, Known delta 4).
///
/// - Row 0: `p0` = (0,0) fill, `p1` = (1,0) grid, `p2` = (2,0) key; `p0 ≠ p1`, `p1 ≠ p2`.
/// - Strips: from row 1 down, a strip is a run of rows whose column-0 pixel ≠ grid; strips are
///   separated by grid rows (a row whose column 0 is grid is skipped).
/// - Cells: within a strip, a cell is a run of columns with no grid pixel in any strip row.
/// - Trim: rows and columns entirely equal to the cell's top-left pixel are dropped, giving the
///   content size `w × h`; an all-fill cell yields no frame.
/// - Rect (top, left, bottom, right) = (stripTop + stripH − h − 1, cellLeft + 1, top + h, left + w):
///   bottom-left anchored in the cell with a 1-pixel inset (`FUN_1001f340`, read verbatim).
/// - Order: strips top → bottom, cells left → right.
///
/// The frame-size (≤ 300 × 256) and frame-count (< 0xFFFF) asserts belong to the group loader
/// (`SpriteGroup`).
public enum SpritePlate {
    public static func frameRects(alphaIndices px: [UInt8], width w: Int, height h: Int) throws -> [MacRect] {
        guard w >= 0, h >= 0, px.count == w * h else {
            throw SpritePlateError.indexCountMismatch(count: px.count, width: w, height: h)
        }
        guard w >= 3, h >= 2 else { throw SpritePlateError.plateTooSmall(width: w, height: h) }
        let fill = px[0], grid = px[1], key = px[2]
        guard fill != grid else { throw SpritePlateError.fillEqualsGrid }
        guard grid != key else { throw SpritePlateError.gridEqualsKey }

        var rects: [MacRect] = []
        px.withUnsafeBufferPointer { p in
            func at(_ x: Int, _ y: Int) -> UInt8 { p[y * w + x] }
            var row = 1
            while row < h {
                var sh = 0
                while row + sh < h && at(0, row + sh) != grid { sh += 1 }
                if sh < 1 { row += 1; continue }
                var col = 0
                while col < w {
                    var cw = 0
                    columns: while col + cw < w {
                        for y in row..<(row + sh) where at(col + cw, y) == grid { break columns }
                        cw += 1
                    }
                    if cw < 1 { col += 1; continue }
                    let bg = at(col, row)
                    var minY = Int.max, maxY = -1, minX = Int.max, maxX = -1
                    for y in row..<(row + sh) {
                        for x in col..<(col + cw) where at(x, y) != bg {
                            minY = min(minY, y); maxY = max(maxY, y)
                            minX = min(minX, x); maxX = max(maxX, x)
                        }
                    }
                    if maxY >= 0 {
                        let fh = maxY - minY + 1, fw = maxX - minX + 1
                        let top = row + sh - fh - 1, left = col + 1
                        rects.append(MacRect(top: Int32(top), left: Int32(left),
                                             bottom: Int32(top + fh), right: Int32(left + fw)))
                    }
                    col += cw
                }
                row += sh + 1
            }
        }
        guard !rects.isEmpty else { throw SpritePlateError.noFrames }
        return rects
    }
}
