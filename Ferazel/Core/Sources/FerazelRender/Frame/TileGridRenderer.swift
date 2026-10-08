import Foundation
import FerazelCore

/// The tile layer of `.PaintFrameWrap`: `.SetScrollLocation @ 10012848` → `.RedrawScrollGrid @ 10013498` (and
/// `.RedrawEntireScrollGrid @ 10013fd0`), transcribed from the decompile (l. 9464–10088) — plan R1, "Bank
/// corrections" 9, sprites-backgrounds §3.1–§3.3, lighting-tables §8.
///
/// **Strip-incremental.** Each drawn frame `.SetScrollLocation(h, v)` redraws only the cells newly exposed since the
/// scroll it last drew at (`drawnH`/`drawnV`, `_DAT_1009fe74`/`_DAT_1009fe70`); the whole window is drawn by
/// `redrawEntireScrollGrid` (level start, full redraws). Tiles are drawn into the third port (`FramePorts.tiles`,
/// `0004`), the mask port gets the boolean stamps, and the redrawn rect is then copied into the frame port
/// (`.WrapRectBlitX`).
///
/// Per redrawn cell (col, row), with FG tile t, BG tile b, overlay o1/o2 (`LevelFile` decodes), k = FG kind
/// (`.LookupFGTileKind`, the header table with tiles 0x50..0x5f overwritten by `.LoadTileDefinitions`) mod 100
/// (C remainder), and w = the BG kind − 200 when it is 200..209 (`.IsWaterTile`), else −1:
/// 1. mask cell := 0xFF and tiles cell := 0x00 (PICT 1002's face, erase-bool / bool; "Bank corrections" 9);
/// 2. t < 0: if b ≥ 0, BG face b → tiles, BG bool-stamp → mask, overlay o2 bool-stamps → mask;
///    t ≥ 0: if FG face t has no transparent pixel or b < 0, FG bool-stamp → mask; else BG face b → tiles, BG
///    bool-stamp → mask, and FG bool-stamp → mask when the BG face has a transparent pixel; then the overlay o2
///    bool-stamps; then t < 95: FG face t (tinted through water table w when w ≥ 0 and header `0x26c6` ≠ 0); when
///    0 ≤ k < 95 the blend face k mixed with the pattern tile (mode 0x14, or (w + 0x15) in water — the dry blitter
///    unless `0x26c6` ≠ 0); in water with `0x26c6` = 0 and 0 ≤ k < 95, the FG-water face t through water table w
///    (drawn after the blend); t == 95: the pattern tile (tinted in water when `0x26c6` ≠ 0);
/// 3. overlay: o1 = 100 → FG face o2 (the pattern tile when o2 = 95) → tiles and FG face o2 bool-stamp → mask;
///    o1 = 101 → BG face o2 → tiles and its bool-stamp → mask (no water tint on this path).
/// The per-cell lights (plan R2; lighting-tables "⚑ Phase-1 note (R2)"), each only when prefs Effects (`prefs+6`,
/// `_DAT_1009fe44`) ≠ 3, through `LightRenderer.lightTile` into `0004`: `.LightAnyBGTile(b)` right after the BG face
/// is drawn and stamped (`bl` at raw `100137c8` / `10013c70`, decompile l. 9919 / 10002), `.LightAnyFGTile(t)` (FG
/// face t, any t ≥ 0 incl. 95; `10013d64`, l. 10020) after step 2's FG draws, `.LightAnyFGOverlayFGTile` /
/// `…BGTile(o2)` (`10013ec0` / `10013ee4`, l. 10044 / 10047) after the overlay draw; each gate is `lha r0,6(r16);
/// cmpwi r0,3; beq` (e.g. `100137ac..100137b4`). Effects = 3 is R1's tile layer.
/// The `param_2 ≠ 0` (mask-only) mode of `.RedrawScrollGrid` is not built (its one caller is outside R1).
public struct TileGridRenderer: Sendable {
    public let level: LevelFile
    public let sets: TileSets
    /// `_DAT_1009ffc8`: PICT 185 after `.ProcessFGBlendTileFaces` (weights 0..3).
    public let blend: FaceSheet
    public let tables: LevelTables
    /// `_DAT_100a0108`: `.Load1EncFaceFromPICT(1002, 0, 0, 0)` under clut 801 (`.PreparePaintFrame` l. 8417–8420).
    public let clearFace: EncodedFace
    /// `_DAT_1009fe74`: the h the grid was last drawn at.
    public private(set) var drawnH: Int
    /// `_DAT_1009fe70`: the v the grid was last drawn at.
    public private(set) var drawnV: Int
    /// prefs `+0x06` Effects (`FerazelPrefs.effects`): 3 skips the per-cell lights and `.DrawLightsOntoTiles`.
    public var effects: Int16
    /// The light slots and the darkness the per-cell lights read (`LightRenderer`).
    public var lights: LightRenderer

    /// - Parameters:
    ///   - effects: prefs Effects; the default is `.InitPrefs`' on a modern Mac (1).
    ///   - lights: the light state; nil = no light slot in use over `level` and `tables`.
    public init(level: LevelFile, sets: TileSets, fixed: TileSets.Fixed, tables: LevelTables, clearFace: EncodedFace,
                drawnH: Int, drawnV: Int, effects: Int16 = FerazelPrefs().effects, lights: LightRenderer? = nil) {
        self.level = level
        self.sets = sets
        self.blend = fixed.blend
        self.tables = tables
        self.clearFace = clearFace
        self.drawnH = drawnH
        self.drawnV = drawnV
        self.effects = effects
        self.lights = lights ?? LightRenderer(level: level, tables: tables)
    }

    /// The cell-clear face: PICT 1002 (32×32, 32-bit, all black) converted under clut 801, the "System CLUT"
    /// `.PreparePaintFrame @ 10010868` makes current before loading it (l. 8415–8420; lighting-tables §1.1).
    static func loadClearFace(resources: FerazelResources, search: ColorSearch,
                                     dither: DitherModel = .errorDiffusion) throws -> EncodedFace {
        let clut = try ColorLUT.load(id: 801, from: resources, chain: .frontEnd)
        return try FaceSheet.load(.single(pict: 1002), from: resources, chain: .frontEnd, clut: clut, search: search,
                                  dither: dither).faces[0]
    }

    /// `.GetFGPatternTile @ 1003c0b8`: `(x mod 8) + 8·(y mod 8)`, or `(x mod 6) + 8·(y mod 6)` when header `0x26cb` ≠ 0,
    /// on the unconstrained (col, row) with C's truncating remainder (`srawi`/`addze`, `0x2aaaaaab`) — the bank's
    /// "floor mod" agrees for every col, row ≥ 0, which is every cell the grid draws. (> 63 is the original's fatal
    /// "bad FGPattern"; it cannot arise for col, row ≥ 0.)
    static func patternTile(col: Int, row: Int, periodSix: Bool) -> Int {
        let n = periodSix ? 6 : 8
        return col % n + 8 * (row % n)
    }

    /// The tile-grid draw ops of the seam: `.redrawScrollGrid` → `setScrollLocation` (strip-incremental),
    /// `.redrawEntireScrollGrid` → `redrawEntireScrollGrid` (the whole window). Every other op is not the grid's.
    mutating func apply(_ op: DrawOp, ports: inout FramePorts) {
        switch op {
        case .redrawScrollGrid(let h, let v): setScrollLocation(h: h, v: v, ports: &ports)
        case .redrawEntireScrollGrid(let h, let v): redrawEntireScrollGrid(h: h, v: v, ports: &ports)
        default: break
        }
    }

    /// `.SetScrollLocation(h, v)`: clamp (negative → 0; `(h + 640) >> 5 > 0x200` → h = 0x3da0, `(v + 416) >> 5 > 0x200`
    /// → v = 16000), then redraw the row strip exposed by the v change (at the old h's 21 columns) and the column strip
    /// exposed by the h change (at the old v's 14 rows), and remember (h, v) as drawn. Cells are culled against the
    /// scroll point as passed (`PTR_DAT_1009fe78`).
    public mutating func setScrollLocation(h: Int, v: Int, ports: inout FramePorts) {
        let scroll = TileBlitters.Scroll(h: h, v: v)
        var h = max(h, 0), v = max(v, 0)
        if (h + 0x280) >> 5 > 0x200 { h = 0x3da0 }
        if (v + 0x1a0) >> 5 > 0x200 { v = 16000 }
        let oldH = drawnH, oldV = drawnV
        // SetLongRect(r, 0, 0, −1, −1): rows 0 ... −1, cols 0 ... −1 (empty).
        var rowStrip = (top: 0, left: 0, right: -1, bottom: -1)
        var colStrip = (top: 0, left: 0, right: -1, bottom: -1)
        if v != oldV {
            rowStrip.left = oldH / 32
            rowStrip.right = rowStrip.left + 0x14
            if oldV < v {
                rowStrip.top = oldV / 32 + 0xd
                rowStrip.bottom = v / 32 + 0xc
            } else {
                rowStrip.top = v / 32
                rowStrip.bottom = oldV / 32 - 1
            }
        }
        if h != oldH {
            colStrip.top = oldV / 32
            colStrip.bottom = colStrip.top + 0xd
            if oldH < h {
                colStrip.left = oldH / 32 + 0x14
                colStrip.right = h / 32 + 0x14
            } else {
                colStrip.left = h / 32
                colStrip.right = oldH / 32
            }
        }
        drawnH = h
        drawnV = v
        if rowStrip.top <= rowStrip.bottom {
            redraw(top: rowStrip.top, left: rowStrip.left, right: rowStrip.right, bottom: rowStrip.bottom, scroll: scroll,
                   ports: &ports)
        }
        if colStrip.left <= colStrip.right {
            redraw(top: colStrip.top, left: colStrip.left, right: colStrip.right, bottom: colStrip.bottom, scroll: scroll,
                   ports: &ports)
        }
    }

    /// `.RedrawEntireScrollGrid @ 10013fd0` (`DrawOp.redrawEntireScrollGrid`): rows drawnV/32 ... +13, cols
    /// drawnH/32 ... +20, culled against the scroll point (h, v).
    public func redrawEntireScrollGrid(h: Int, v: Int, ports: inout FramePorts) {
        let top = drawnV / 32, left = drawnH / 32
        redrawScrollGrid(top: top, left: left, right: left + 0x14, bottom: top + 0xd, h: h, v: v, ports: &ports)
    }

    /// `.RedrawScrollGrid(rect, 0)`: rows top ... bottom, cols left ... right (inclusive; empty when top > bottom or
    /// left > right), culled against the scroll point (h, v).
    func redrawScrollGrid(top: Int, left: Int, right: Int, bottom: Int, h: Int, v: Int, ports: inout FramePorts) {
        redraw(top: top, left: left, right: right, bottom: bottom, scroll: TileBlitters.Scroll(h: h, v: v), ports: &ports)
    }

    // MARK: - the transcription

    func redraw(top: Int, left: Int, right: Int, bottom: Int, scroll: TileBlitters.Scroll, ports: inout FramePorts) {
        guard top <= bottom, left <= right else { return }
        let header = level.header
        let width = Int(header.gridWidth), height = Int(header.gridHeight)
        var union: (top: Int, left: Int, bottom: Int, right: Int)?
        for row in top...bottom {
            for col in left...right {
                let x = col << 5, y = row << 5
                if col < width, col >= 0, row < height, row >= 0 {
                    guard drawCell(col: col, row: row, x: x, y: y, scroll: scroll, ports: &ports) else { return }
                }
                let r = (top: y, left: x, bottom: y + 0x20, right: x + 0x20)
                union = union.map { (min($0.top, r.top), min($0.left, r.left), max($0.bottom, r.bottom), max($0.right, r.right)) } ?? r
            }
        }
        if let u = union {
            TileBlitters.wrapRectBlit(from: ports.tiles, to: &ports.frame, top: u.top, left: u.left, bottom: u.bottom,
                                      right: u.right, scroll: scroll)
        }
    }

    /// One cell of `.RedrawScrollGrid`; false where the original reports "FGTileKind out of range" and returns.
    private func drawCell(col: Int, row: Int, x: Int, y: Int, scroll: TileBlitters.Scroll, ports: inout FramePorts) -> Bool {
        let header = level.header
        let t = level.fgTile(col: col, row: row), b = level.bgTile(col: col, row: row)
        let o1 = level.overlay1(col: col, row: row)
        let o2 = o1 > 99 ? level.overlay2(col: col, row: row) : -1
        guard (-1...0x5f).contains(t), (-1...0x5f).contains(b) else { return false }
        let fg = sets.fg.faces, bg = sets.bg.faces

        func draw(_ face: EncodedFace, _ op: TileBlitters.Op = .copy) {
            TileBlitters.wrapDraw(face, op, into: &ports.tiles, x: x, y: y, scroll: scroll)
        }
        func stamp(_ face: EncodedFace) {
            TileBlitters.wrapDraw(face, .bool, into: &ports.mask, x: x, y: y, scroll: scroll)
        }
        let lit = effects != 3
        /// `.LightAny*Tile(…, 10)` → `.WrapLightTile` → `.DrawLightOverTile` into `0004`.
        func light(_ face: EncodedFace) {
            lights.lightTile(face, into: &ports.tiles, x: x, y: y, scroll: scroll)
        }
        /// The overlay o2 face of o1 (100 → FG set, 101 → BG set); nil past the set (no shipped level reaches it).
        func overlayFace() -> EncodedFace? {
            guard o2 >= 0 else { return nil }
            if o1 == 100, o2 < fg.count { return fg[o2] }
            if o1 == 101, o2 < bg.count { return bg[o2] }
            return nil
        }

        // 1. the cell cleared (raw 10013688 / 100136ac).
        TileBlitters.wrapDraw(clearFace, .erase, into: &ports.mask, x: x, y: y, scroll: scroll)
        TileBlitters.wrapDraw(clearFace, .bool, into: &ports.tiles, x: x, y: y, scroll: scroll)

        // 2. BG, the mask stamps, the FG rule.
        if t < 0 {
            if b >= 0 {
                draw(bg[b])
                stamp(bg[b])
                if lit { light(bg[b]) }   // `.LightAnyBGTile` (l. 10002)
                if let o = overlayFace() { stamp(o) }
            }
        } else {
            let fgFace = fg[t]
            if !fgFace.hasTransparentPixel || b < 0 {
                stamp(fgFace)
            } else {
                draw(bg[b])
                stamp(bg[b])
                if bg[b].hasTransparentPixel { stamp(fgFace) }
                if lit { light(bg[b]) }   // `.LightAnyBGTile` (l. 9919)
            }
            if let o = overlayFace() { stamp(o) }

            let kind = level.fgKind(tile: t)
            let k = kind % 100
            let bgKind = level.bgKind(tile: b)
            let w = (200..<210).contains(bgKind) ? bgKind - 200 : -1
            let submerged = header.submergedFaces != 0
            let pattern = Self.patternTile(col: col, row: row, periodSix: header.patternPeriodSix != 0)
            if t < 0x5f {
                if w == -1 || !submerged {
                    draw(fgFace)
                } else {
                    draw(fgFace, .table(water(w)))
                }
                if k >= 0, k < 0x5f {
                    // mode 0x14 | pattern (dry) or (w + 0x15) << 16 | pattern; `.BlitEncFaceX` sends the latter to the
                    // dry blitter unless 0x26c6 ≠ 0 (decompile l. 27043–27050).
                    draw(blend.faces[k], blendOp(pattern: pattern, water: w >= 0 && submerged ? water(w) : nil))
                    if w >= 0, !submerged {
                        draw(sets.fgWater.sheet.faces[t], .table(water(w)))
                    }
                }
            } else {
                let p = sets.pattern.faces[pattern]
                if w == -1 || !submerged { draw(p) } else { draw(p, .table(water(w))) }
            }
            if lit { light(fgFace) }   // `.LightAnyFGTile` (l. 10020): FG face t, the pattern cell's face 95 too
        }

        // 3. overlay.
        if o2 >= 0 {
            if o1 == 100, o2 < fg.count {
                draw(o2 == 0x5f ? sets.pattern.faces[Self.patternTile(col: col, row: row,
                                                                       periodSix: header.patternPeriodSix != 0)]
                                : fg[o2])
                stamp(fg[o2])
                if lit { light(fg[o2]) }   // `.LightAnyFGOverlayFGTile` (l. 10044)
            } else if o1 == 101, o2 < bg.count {
                draw(bg[o2])
                stamp(bg[o2])
                if lit { light(bg[o2]) }   // `.LightAnyFGOverlayBGTile` (l. 10047)
            }
        }
        return true
    }

    /// Water table w (`_DAT_100a0170`). The original indexes w = BG kind − 200 for kinds 200..209 but builds only
    /// w 0..5; no shipped level has a BG kind 206..209 under a drawn FG cell — refused, not invented.
    func water(_ w: Int) -> [UInt8] {
        precondition(w < tables.water.count, "water table w ≥ 6 is outside the census (w = \(w))")
        return tables.water[w]
    }

    func blendOp(pattern: Int, water: [UInt8]?) -> TileBlitters.Op {
        .blend(pattern: sets.patternPlain.faces[pattern], patternWidth: sets.patternPlain.arguments.cellWidth,
               quarter: tables.pair(.quarterSprite), half: tables.pair(.average),
               threeQuarter: tables.pair(.threeQuarterSprite), water: water)
    }
}
