import Foundation
import FerazelCore

/// One of the 200 light slots at `_DAT_100a0128` (0x30 bytes each; lighting-tables §7.4). Phase 1 never fills one
/// (no placed type on level 1 adds a light in its Setup; effects add them later — `.AddLight`/`.HandleLights` are not
/// built here).
public struct LightSlot: Sendable, Equatable {
    /// `+0x00`.
    public var active = false
    /// `+0x01` (read by `.HasLightChanged`).
    public var isNew = false
    /// `+0x02`.
    public var removePending = false
    /// `+0x04` (the original compares the face pointers; the replica compares the faces).
    public var face: LightFace?
    /// `+0x08`.
    public var previousFace: LightFace?
    /// `+0x0c` / `+0x0e`: the centre (Point v, h).
    public var y = 0
    public var x = 0
    /// `+0x10` / `+0x12`.
    public var previousY = 0
    public var previousX = 0
    /// `+0x14` (face width / 2 at `.AddLight`).
    public var radius = 0
    /// `+0x16`.
    public var previousRadius = 0
    /// `+0x18`: the colour group's first table row, g·11 (§7.3); the blitters use its low byte.
    public var colour = 0
    /// `+0x1a` (compared with `+0x18` by `.HasLightChanged`).
    public var previousColour = 0

    public init() {}
}

/// One cell of the 20×13 light-op grid `_DAT_100a0120` (0x444 bytes per column, 0x54 per cell; `.AddLightOp @
/// 1001c2c0`): `+0` the OR of the lights' "changed" flags, `+2` the count, `+4…` the slot indices. (`+0x14 + 8n` also
/// stores each light's rect; nothing reads it. The original has room for 8 entries and does not check — a 9th
/// overwrites the rect list, beyond that the next cell; the replica keeps a list.)
public struct LightOp: Sendable, Equatable {
    /// Grid column / row: world cell − scroll cell (`h >> 5`, `v >> 5`).
    public var col: Int
    public var row: Int
    /// `+0`: any light listed here has changed (`.DrawLightOps` redraws only these cells).
    public var changed: Bool
    /// `+4…`: slot indices, in slot order.
    public var lights: [Int]
}

/// Per-cell darkness and lights on tiles (lighting-tables §7; "⚑ Phase-1 note (R2)" there):
///
/// - `.RedrawScrollGrid` (when prefs Effects ≠ 3) calls `.LightAnyBGTile`/`.LightAnyFGTile`/`.LightAnyFGOverlay*Tile`
///   per drawn face → `.WrapLightTile @ 10016c8c` (the tile cull, one blit at the ring position, no wrapped copies)
///   → `.DrawLightOverTile @ 1001c934` with its last argument 10 (`lightTile`);
/// - `.PaintFrameWrap` (Effects ≠ 3, l. 9202) calls `.DrawLightsOntoTiles @ 1001c8e4`: clear the op grid
///   (`FUN_1001c1cc`), `.CalcLightOps @ 1001c45c`, `.DrawLightOps @ 1001c6f4` (`TileGridRenderer.drawLightsOntoTiles`).
///
/// D = `.GetAmbDarkVal @ 1001aaf8` = 0 when header `0x2706` is 0, else `.GetLightTile @ 1003c2b4` = the BG-map cell's
/// high byte − 1 (cell (x >> 5, y >> 5), clamped by `.ConstrainXY`). Tables: ambient `_DAT_100a0130[D·0x100 + i]`,
/// light `_DAT_100a0134[D·0x6e00 + t·0x100 + i]` (`LevelTables`).
public struct LightRenderer: Sendable {
    public static let slotCount = 200
    /// The op grid: 20 columns × 13 rows (`FUN_1001c1cc`, `.DrawLightOps`).
    public static let opColumns = 0x14
    public static let opRows = 0xd

    public let level: LevelFile
    let ambient: [[UInt8]]
    let light: [UInt8]
    /// `_DAT_100a0128`.
    public var slots: [LightSlot]

    public init(level: LevelFile, tables: LevelTables) {
        self.level = level
        ambient = tables.ambient
        light = tables.light
        slots = [LightSlot](repeating: LightSlot(), count: Self.slotCount)
    }

    /// `.GetAmbDarkVal(x, y)`: 0 when header `0x2706` is 0, else `.GetLightTile(x >> 5, y >> 5)` (−1 … 254).
    public func darkness(x: Int, y: Int) -> Int {
        level.header.darknessEnable == 0 ? 0 : level.lightByte(col: x >> 5, row: y >> 5)
    }

    /// The 256 bytes at `_DAT_100a0130 + D·0x100`. D = −1 reads the 256 bytes before the ambient table, which is the
    /// light table's last row (`10169d6c` = `100fbd6c` + 16·0x6e00: slab 15, group 9, k 10) [HIGH arithmetic]; any
    /// other D outside 0…15 reads past it and is refused (no shipped level enables darkness over such a byte).
    func ambientSlab(_ D: Int) -> [UInt8] {
        if (0..<ambient.count).contains(D) { return ambient[D] }
        precondition(D == -1, "ambient darkness D = \(D) is outside the census")
        let base = light.count - 0x100
        return Array(light[base..<(base + 0x100)])
    }

    // MARK: - the per-cell path (`.RedrawScrollGrid`)

    /// `.WrapLightTile(face, port, (0,0), point, 0x20, 0x20, point, 10)`: the tile cull, then `.DrawLightOverTile` at
    /// the ring position only.
    func lightTile(_ face: EncodedFace, into port: inout [UInt8], x: Int, y: Int, scroll: TileBlitters.Scroll) {
        guard TileBlitters.visible(x: x, y: y, scroll: scroll) else { return }
        drawLightOverTile(face, into: &port, ringX: FramePorts.ringX(x), ringY: FramePorts.ringY(y), x: x, y: y)
    }

    /// `.DrawLightOverTile(face, port, (0,0), ring, 0x20, 0x20, (x, y), 10)`: D of the cell; with the last argument
    /// 10 every active slot with a face is a candidate (the "changed" test is forced true and the mode is 1); each
    /// whose face rect, centred on the light, meets the tile face's bounds `+0x08` at (x, y) is blitted — the first
    /// with `.BlitLightOverFaceClip`, the rest with `.BlitAfterLightOverFaceClip`. None and D ≠ 0:
    /// `.BlitAmbDarkenOverFaceNoClip` (the copy-run pixels of the port remapped through ambient slab D).
    func drawLightOverTile(_ face: EncodedFace, into port: inout [UInt8], ringX: Int, ringY: Int, x: Int, y: Int) {
        let D = darkness(x: x, y: y)
        var lit = false
        for slot in slots where slot.active {
            guard let lf = slot.face else { continue }
            lit = blitLight(slot, lf, face, into: &port, ringX: ringX, ringY: ringY, x: x, y: y, D: D, after: lit) || lit
        }
        if !lit && D != 0 {
            Self.ambientDarken(face, ambientSlab(D), into: &port, x: ringX, y: ringY)
        }
    }

    /// The intersection test and the first/after blit of one light over a tile face at world (x, y); true when the
    /// rects met.
    private func blitLight(_ slot: LightSlot, _ lf: LightFace, _ face: EncodedFace, into port: inout [UInt8],
                           ringX: Int, ringY: Int, x: Int, y: Int, D: Int, after: Bool) -> Bool {
        let top = slot.y - slot.radius, left = slot.x - slot.radius
        let lightRect = Self.offset(lf.rect, dh: left, dv: top)
        let tileRect = Self.offset(face.bounds, dh: x, dv: y)
        guard Self.sect(lightRect, tileRect) != nil else { return false }
        if after {
            blitAfterLight(face, lf, colour: slot.colour, into: &port, x: ringX, y: ringY, offRow: y - top,
                           offCol: x - left)
        } else {
            blitLight(face, lf, colour: slot.colour, D: D, into: &port, x: ringX, y: ringY, offRow: y - top,
                      offCol: x - left)
        }
        return true
    }

    // MARK: - the op-grid path (`.DrawLightsOntoTiles`)

    /// `.HasLightChanged @ 1001c390`: unchanged only when position, face, colour (`+0x18` vs `+0x1a`) are all as
    /// before and `+1` (new) is 0. The radius is not compared.
    static func hasChanged(_ s: LightSlot) -> Bool {
        !(s.y == s.previousY && s.x == s.previousX && s.face == s.previousFace && s.colour == s.previousColour
          && !s.isNew)
    }

    /// `FUN_1001c1cc` (clear) + `.CalcLightOps @ 1001c45c` at scroll (h, v): the 20×13 grid, column-major
    /// (index col·13 + row).
    func opGrid(h: Int, v: Int) -> [LightOp] {
        var grid = (0..<Self.opColumns).flatMap { c in
            (0..<Self.opRows).map { LightOp(col: c, row: $0, changed: false, lights: []) }
        }
        // SetRect(r, (h >> 5)·32, (v >> 5)·32, +0x280, +0x1a0).
        let left = (h >> 5) * 32, top = (v >> 5) * 32
        let view = EncodedFace.Rect(top: Int16(truncatingIfNeeded: top), left: Int16(truncatingIfNeeded: left),
                                    bottom: Int16(truncatingIfNeeded: top + 0x1a0),
                                    right: Int16(truncatingIfNeeded: left + 0x280))
        for (i, s) in slots.enumerated() where s.active {
            let changed = Self.hasChanged(s)
            let current = s.face.map { Self.offset($0.rect, dh: s.x - s.radius, dv: s.y - s.radius) }
            let previous = s.previousFace.map {
                Self.offset($0.rect, dh: s.previousX - s.previousRadius, dv: s.previousY - s.previousRadius)
            }
            let rect: EncodedFace.Rect?
            if !changed {
                rect = current
            } else if let c = current {
                rect = previous.map { Self.union(c, $0) } ?? c
            } else {
                rect = previous
            }
            guard let r = rect, let s = Self.sect(r, view) else { continue }
            // Both edges inclusive: cols left >> 5 … right >> 5, rows top >> 5 … bottom >> 5 (`1001c6a0..`).
            for col in (Int(s.left) >> 5)...(Int(s.right) >> 5) {
                for row in (Int(s.top) >> 5)...(Int(s.bottom) >> 5) {
                    // `.AddLightOp`: relative to the scroll cell, dropped outside 0…19 × 0…12.
                    let gc = col - (h >> 5), gr = row - (v >> 5)
                    guard (0..<Self.opColumns).contains(gc), (0..<Self.opRows).contains(gr) else { continue }
                    grid[gc * Self.opRows + gr].lights.append(i)
                    if changed { grid[gc * Self.opRows + gr].changed = true }
                }
            }
        }
        return grid
    }

    /// The non-empty cells of the op grid at scroll (h, v) (`.CalcLightOps`), column-major.
    public func calcLightOps(h: Int, v: Int) -> [LightOp] {
        opGrid(h: h, v: v).filter { !$0.lights.isEmpty }
    }

    /// `.WrapLightOpTile @ 10016d80`: the tile cull, then `.DrawLightOpOverTile` at the ring position and at the up
    /// to three wrapped copies (as `.WrapDrawTile`).
    func lightOpTile(_ face: EncodedFace, into port: inout [UInt8], x: Int, y: Int, scroll: TileBlitters.Scroll,
                     grid: [LightOp]) {
        guard TileBlitters.visible(x: x, y: y, scroll: scroll) else { return }
        let rx = FramePorts.ringX(x), ry = FramePorts.ringY(y), n = TileBlitters.cell
        let wrapsY = ry - FramePorts.height + n > 0, wrapsX = rx - FramePorts.width + n > 0
        func draw(_ px: Int, _ py: Int) {
            drawLightOpOverTile(face, into: &port, ringX: px, ringY: py, x: x, y: y, scroll: scroll, grid: grid)
        }
        draw(rx, ry)
        if wrapsY { draw(rx, ry - FramePorts.height) }
        if wrapsX { draw(rx - FramePorts.width, ry) }
        if wrapsX && wrapsY { draw(rx - FramePorts.width, ry - FramePorts.height) }
    }

    /// `.DrawLightOpOverTile @ 1001cc70`: D of the cell; the lights listed in its op cell (grid cell (x >> 5) −
    /// (h >> 5), (y >> 5) − (v >> 5); nothing outside the grid) that are active with a face and meet the tile face
    /// are blitted first/after as in `.DrawLightOverTile`; none and header `0x2706` > 0:
    /// `.BlitAmbDarkenOverFaceClip` through slab D — D = 0 included.
    func drawLightOpOverTile(_ face: EncodedFace, into port: inout [UInt8], ringX: Int, ringY: Int, x: Int, y: Int,
                             scroll: TileBlitters.Scroll, grid: [LightOp]) {
        let D = darkness(x: x, y: y)
        let gc = (x >> 5) - (scroll.h >> 5), gr = (y >> 5) - (scroll.v >> 5)
        guard (0..<Self.opColumns).contains(gc), (0..<Self.opRows).contains(gr) else { return }
        var lit = false
        for i in grid[gc * Self.opRows + gr].lights where (0..<Self.slotCount).contains(i) {
            let slot = slots[i]
            guard slot.active, let lf = slot.face else { continue }
            lit = blitLight(slot, lf, face, into: &port, ringX: ringX, ringY: ringY, x: x, y: y, D: D, after: lit) || lit
        }
        if !lit && level.header.darknessEnable > 0 {
            Self.ambientDarken(face, ambientSlab(D), into: &port, x: ringX, y: ringY)
        }
    }

    // MARK: - the blitters

    /// `.BlitAmbDarkenOverFaceNoClip @ 1001e6a0` / `…Clip @ 1001e1ac` (ripple flag 0): every port pixel under a copy
    /// run of the face becomes `slab[pixel]` — the face's own pixels are not read; skip runs leave the port alone.
    static func ambientDarken(_ face: EncodedFace, _ slab: [UInt8], into port: inout [UInt8], x: Int, y: Int) {
        slab.withUnsafeBufferPointer { a in
            port.withUnsafeMutableBufferPointer { out in
                forEachCopyRun(face, x: x, y: y) { o, n, _, _ in
                    for j in 0..<n { out[o + j] = a[Int(out[o + j])] }
                }
            }
        }
    }

    /// `.BlitLightOverFaceClip @ 1001d8e8` (source origin (0,0), ripple 0): the light face sits so that the tile's
    /// face pixel (r, c) reads light pixel (offRow + r, offCol + c). Per copy run (raw `1001db20..1001dbb8`): when
    /// the light row is ≤ 0 or ≥ the light face's height − 1 (`cmpwi r29,1; ble` / `cmpw r29,+0x54; bge` with r29 =
    /// light row + 1), or the run starts at a light column ≥ its width, the whole run → ambient slab D; else per
    /// pixel: column < 0 or ≥ width → ambient; light pixel p = 0 → ambient; else `light[D][(p + colour − 0xf5)·0x100
    /// + dst]` (colour = `+0x18` low byte).
    func blitLight(_ face: EncodedFace, _ lf: LightFace, colour: Int, D: Int, into port: inout [UInt8], x: Int, y: Int,
                   offRow: Int, offCol: Int) {
        precondition((0..<ambient.count).contains(D), "light over darkness D = \(D) is outside the census")
        let amb = ambient[D], base = D * 0x6e00, colour = colour & 0xff
        let table = light
        port.withUnsafeMutableBufferPointer { out in
            Self.forEachCopyRun(face, x: x, y: y) { o, n, r, c in
                let lr = offRow + r
                if lr <= 0 || lr + 1 >= lf.height || offCol + c >= lf.width {
                    for j in 0..<n { out[o + j] = amb[Int(out[o + j])] }
                    return
                }
                for j in 0..<n {
                    let lc = offCol + c + j, d = Int(out[o + j])
                    guard lc >= 0, lc < lf.width else { out[o + j] = amb[d]; continue }
                    let p = Int(lf.pixel(row: lr, col: lc))
                    out[o + j] = p == 0 ? amb[d] : table[Self.lightIndex(base + (p + colour - 0xf5) * 0x100 + d, table)]
                }
            }
        }
    }

    /// `.BlitAfterLightOverFaceClip @ 1001dd8c` (second and later lights on the same face; raw `1001dfe4..`): the D = 0
    /// slab; runs on light rows < 0 are left alone and the blit ends at the first light row ≥ the height; per pixel
    /// in light columns 0 … width − 1: p (0 read as 0xf5) → `light[0][(p + colour − 0xf5)·0x100 + dst]`; the rest is
    /// left alone.
    func blitAfterLight(_ face: EncodedFace, _ lf: LightFace, colour: Int, into port: inout [UInt8], x: Int, y: Int,
                        offRow: Int, offCol: Int) {
        let colour = colour & 0xff
        let table = light
        port.withUnsafeMutableBufferPointer { out in
            Self.forEachCopyRun(face, x: x, y: y) { o, n, r, c in
                let lr = offRow + r
                guard lr >= 0, lr < lf.height else { return }   // rows only grow: ≥ height ends the blit
                for j in 0..<n {
                    let lc = offCol + c + j
                    guard lc >= 0, lc < lf.width else { continue }
                    var p = Int(lf.pixel(row: lr, col: lc))
                    if p == 0 { p = 0xf5 }
                    out[o + j] = table[Self.lightIndex((p + colour - 0xf5) * 0x100 + Int(out[o + j]), table)]
                }
            }
        }
    }

    /// A light-table index the original reads inside the table; anything else (a light pixel below 0xf5 with a
    /// small colour, or past slab 15) reads other memory and is refused.
    @inline(__always) private static func lightIndex(_ i: Int, _ table: [UInt8]) -> Int {
        precondition(i >= 0 && i < table.count, "light-table index \(i) is outside the table")
        return i
    }

    /// Walks a face's token stream in place and calls `run(portIndex, count, faceRow, faceCol)` for each copy run
    /// when the face sits at port position (x, y), clipped to the 640×416 port (the 8-px slop is not modelled; a
    /// 32-px tile at a ring position never reaches past the port: 640 and 416 are multiples of 32).
    static func forEachCopyRun(_ face: EncodedFace, x: Int, y: Int, _ run: (Int, Int, Int, Int) -> Void) {
        let W = FramePorts.width, H = FramePorts.height
        face.data.withUnsafeBufferPointer { data in
            var p = 0, row = -1, col = 0
            while p + 4 <= data.count {
                let op = data[p], n = Int(data[p + 1]) << 16 | Int(data[p + 2]) << 8 | Int(data[p + 3])
                p += 4
                switch op {
                case 1:
                    row += 1
                    col = 0
                case 3:
                    col += n
                case 2:
                    let py = y + row
                    if py >= 0 && py < H {
                        let x0 = max(x + col, 0), x1 = min(x + col + n, W)
                        if x0 < x1 { run(py * W + x0, x1 - x0, row, x0 - x) }
                    }
                    col += n
                    p += (n + 3) & ~3
                default:
                    return   // 0: end (an encoder-written stream has no op ≥ 4)
                }
            }
        }
    }

    // MARK: - QuickDraw rects

    static func offset(_ r: EncodedFace.Rect, dh: Int, dv: Int) -> EncodedFace.Rect {
        EncodedFace.Rect(top: Int16(truncatingIfNeeded: Int(r.top) + dv), left: Int16(truncatingIfNeeded: Int(r.left) + dh),
                         bottom: Int16(truncatingIfNeeded: Int(r.bottom) + dv),
                         right: Int16(truncatingIfNeeded: Int(r.right) + dh))
    }

    /// `SectRect`: nil when the intersection is empty.
    static func sect(_ a: EncodedFace.Rect, _ b: EncodedFace.Rect) -> EncodedFace.Rect? {
        let r = EncodedFace.Rect(top: max(a.top, b.top), left: max(a.left, b.left), bottom: min(a.bottom, b.bottom),
                                 right: min(a.right, b.right))
        return r.top < r.bottom && r.left < r.right ? r : nil
    }

    /// `UnionRect`.
    static func union(_ a: EncodedFace.Rect, _ b: EncodedFace.Rect) -> EncodedFace.Rect {
        EncodedFace.Rect(top: min(a.top, b.top), left: min(a.left, b.left), bottom: max(a.bottom, b.bottom),
                         right: max(a.right, b.right))
    }
}

// MARK: - `.DrawLightOps` and the plain tile redraws it calls

extension TileGridRenderer {

    /// `.PaintFrameWrap` l. 9202–9203: `.DrawLightsOntoTiles @ 1001c8e4` unless prefs Effects == 3 — clear the op
    /// grid, `.CalcLightOps`, then `.DrawLightOps @ 1001c6f4` at scroll (h, v): for each grid cell whose flag is set,
    /// world cell (col + h >> 5, row + v >> 5) with an FG tile, a BG tile or an overlay o2 (o2 is read only when
    /// o1 > 99; otherwise the register keeps the last o2 read in this pass — the replica starts it at −1 [MED: its
    /// value on entry is the caller's]) is redrawn into `0004` without clearing it — `.PlainWrapBGTile` +
    /// `.DrawLightOpBGTile`, `.PlainWrapFGTile` + `.DrawLightOpFGTile`, `.PlainWrapFGOverlayTile` +
    /// `.DrawLightOpFGOverlayTile` — and copied to `000c` (`.WrapRectBlitX`). With no light, nothing.
    public func drawLightsOntoTiles(h: Int, v: Int, ports: inout FramePorts) {
        guard effects != 3 else { return }
        let scroll = TileBlitters.Scroll(h: h, v: v)
        let grid = lights.opGrid(h: h, v: v)
        guard grid.contains(where: \.changed) else { return }
        var o2 = -1
        for cell in grid where cell.changed {
            let col = cell.col + (h >> 5), row = cell.row + (v >> 5)
            let t = level.fgTile(col: col, row: row), b = level.bgTile(col: col, row: row)
            let o1 = level.overlay1(col: col, row: row)
            if o1 > 99 { o2 = level.overlay2(col: col, row: row) }
            guard t != -1 || b >= 0 || o2 != -1 else { continue }
            let x = col << 5, y = row << 5
            plainWrapBGTile(col: col, row: row, scroll: scroll, ports: &ports)
            if b >= 0 { lights.lightOpTile(sets.bg.faces[b], into: &ports.tiles, x: x, y: y, scroll: scroll, grid: grid) }
            plainWrapFGTile(col: col, row: row, scroll: scroll, ports: &ports)
            if t >= 0 { lights.lightOpTile(sets.fg.faces[t], into: &ports.tiles, x: x, y: y, scroll: scroll, grid: grid) }
            plainWrapFGOverlayTile(col: col, row: row, scroll: scroll, ports: &ports)
            if o1 > 99 {
                lights.lightOpTile(overlayFace(o1: o1, o2: level.overlay2(col: col, row: row)), into: &ports.tiles,
                                   x: x, y: y, scroll: scroll, grid: grid)
            }
            TileBlitters.wrapRectBlit(from: ports.tiles, to: &ports.frame, top: y, left: x, bottom: y + 0x20,
                                      right: x + 0x20, scroll: scroll)
        }
    }

    /// The overlay face of o1 (100 → FG set, 101 → BG set) — what `.PlainWrapFGOverlayTile @ 10012f84` and
    /// `.DrawLightOpFGOverlayTile @ 10013358` index without a range check; any other o1 or an o2 outside the set reads
    /// an unset register / outside the array and is refused (no shipped level has one).
    private func overlayFace(o1: Int, o2: Int) -> EncodedFace {
        let set = o1 == 100 ? sets.fg.faces : o1 == 101 ? sets.bg.faces : []
        precondition((0..<set.count).contains(o2), "overlay o1 \(o1) / o2 \(o2) is outside the census")
        return set[o2]
    }

    /// The water kind w of the cell's BG tile (`.IsWaterTile` → `.GetWaterTileKind`): BG kind − 200 for 200…209, else −1.
    private func waterKind(bgTile b: Int) -> Int {
        let kind = level.bgKind(tile: b)
        return (200..<210).contains(kind) ? kind - 200 : -1
    }

    /// `.PlainWrapBGTile @ 10012ea8`: the BG face into `0004` (b outside −1…95 is the original's ReportError).
    func plainWrapBGTile(col: Int, row: Int, scroll: TileBlitters.Scroll, ports: inout FramePorts) {
        let b = level.bgTile(col: col, row: row)
        guard (0...0x5f).contains(b) else { return }
        TileBlitters.wrapDraw(sets.bg.faces[b], .copy, into: &ports.tiles, x: col << 5, y: row << 5, scroll: scroll)
    }

    /// `.PlainWrapFGTile @ 10012ab4` (decompile l. 9557–9650, raw `10012b30..10012e68`) — not `.RedrawScrollGrid`'s
    /// FG rule: t < 95: the FG face (plain; in water with header `0x26c6` = 0 then the FG-water face through water
    /// table w — before the blend and whatever the kind; with `0x26c6` ≠ 0 the FG face through table w), then for
    /// 0 ≤ k < 95 the blend face k with mode (w + 0x15) (the dry blitter unless `0x26c6` ≠ 0); t = 95: the pattern
    /// tile (tinted in water when `0x26c6` ≠ 0); then, when the BG face has a transparent pixel, the FG face's
    /// boolean stamp into `0008`. No cell clear.
    func plainWrapFGTile(col: Int, row: Int, scroll: TileBlitters.Scroll, ports: inout FramePorts) {
        let t = level.fgTile(col: col, row: row), b = level.bgTile(col: col, row: row)
        guard (-1...0x5f).contains(t), (-1...0x5f).contains(b), t >= 0 else { return }
        let x = col << 5, y = row << 5
        func draw(_ face: EncodedFace, _ op: TileBlitters.Op = .copy) {
            TileBlitters.wrapDraw(face, op, into: &ports.tiles, x: x, y: y, scroll: scroll)
        }
        let w = waterKind(bgTile: b)
        let submerged = level.header.submergedFaces != 0
        let pattern = Self.patternTile(col: col, row: row, periodSix: level.header.patternPeriodSix != 0)
        if t < 0x5f {
            let k = level.fgKind(tile: t) % 100
            let fgFace = sets.fg.faces[t]
            if w == -1 {
                draw(fgFace)
            } else if !submerged {
                draw(fgFace)
                draw(sets.fgWater.sheet.faces[t], .table(water(w)))
            } else {
                draw(fgFace, .table(water(w)))
            }
            if k >= 0, k < 0x5f {
                draw(blend.faces[k], blendOp(pattern: pattern, water: w >= 0 && submerged ? water(w) : nil))
            }
        } else if w == -1 || !submerged {
            draw(sets.pattern.faces[pattern])
        } else {
            draw(sets.pattern.faces[pattern], .table(water(w)))
        }
        if b >= 0, sets.bg.faces[b].hasTransparentPixel {
            TileBlitters.wrapDraw(sets.fg.faces[t], .bool, into: &ports.mask, x: x, y: y, scroll: scroll)
        }
    }

    /// `.PlainWrapFGOverlayTile @ 10012f84` (l. 9679–9740): o1 > 99: o2 < 95 → the overlay face, through water table
    /// w whenever the cell is water (header `0x26c6` not consulted); o2 ≥ 95 → the pattern tile (tinted in water when
    /// `0x26c6` ≠ 0). No mask stamp.
    func plainWrapFGOverlayTile(col: Int, row: Int, scroll: TileBlitters.Scroll, ports: inout FramePorts) {
        let o1 = level.overlay1(col: col, row: row)
        guard o1 > 99 else { return }
        let o2 = level.overlay2(col: col, row: row)
        let x = col << 5, y = row << 5
        let w = waterKind(bgTile: level.bgTile(col: col, row: row))
        func draw(_ face: EncodedFace, _ op: TileBlitters.Op) {
            TileBlitters.wrapDraw(face, op, into: &ports.tiles, x: x, y: y, scroll: scroll)
        }
        if o2 < 0x5f {
            let face = overlayFace(o1: o1, o2: o2)
            draw(face, w == -1 ? .copy : .table(water(w)))
        } else {
            let p = sets.pattern.faces[Self.patternTile(col: col, row: row, periodSix: level.header.patternPeriodSix != 0)]
            draw(p, w == -1 || level.header.submergedFaces == 0 ? .copy : .table(water(w)))
        }
    }
}
