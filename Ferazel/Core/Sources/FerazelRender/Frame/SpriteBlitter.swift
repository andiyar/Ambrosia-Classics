import Foundation
import FerazelCore

/// `.WrapDrawSprites @ 100144c8` (decompile l. 10221–10396; draw-effects §1.1) for the modes the level-1 Setups store,
/// `.WrapEraseSprites @ 10014a58` (l. 10398–10618), and the blitters they reach — `.WrapDrawFace @ 100151c4`,
/// `.BlitEncFaceX @ 1002c908` (§1.2: NoClip/Clip, Flip, Special, the mask pass), `.WrapLightFace @ 100156c8` →
/// `.DrawLightOverFace @ 1001cf38` → `.BlitAmbDarkenOverFace(Flip)Clip` (§3), `.WrapBackScratchFace @ 10015454`,
/// `.WrapEraseBoolFace @ 10016784` and the mask-only `.RedrawScrollGrid(rect, 1)`.
///
/// Per sprite (`SpriteDraw`, active-list order):
/// 1. the cull: the face's opaque bounds (`+8`) offset by `(_DAT_1009fe74, _DAT_1009fe70)` (the grid's drawn h, v)
///    against `(0, 0, 0x260, 0x180)` offset by the **same** pair (raw `10014544..1001457c`) — as written the two offsets
///    cancel, so only a face whose bounds miss (0, 0, 608, 384) in face-local px is skipped;
/// 2. source window rows `[+0x1bc, min(+0x1ba, h))`, columns `[+0x1b6, min(+0x1b8, w))`, the destination moved by
///    (`+0x1bc`, `+0x1b6`) (`10014600..10014684`);
/// 3. `.WrapDrawFace`: skipped when it misses the view (dst h + w < scroll h, dst v + h < scroll v, dst h > h + 0x260,
///    dst v > v + 0x180); clipped to v + 0x180 below and **h + 0x280** on the right (`1001525c`, `10015260..1001526c`),
///    then at the left/top scroll edge; then one `.BlitEncFaceX` at the ring position (dst mod 640, mod 416, C
///    truncation) and again at v − 416, h − 640 and both when it reaches past the ring (`10015338..10015418`);
/// 4. `.BlitEncFaceX`: mode `+0xb8 >> 16`, sub `& 0xffff`; mode 0 copies, modes 1 / 9 / 0xc remap through tint
///    table sub / water table 0 / ambient L or light (L, F) (`.BlitEncFaceSpecial*`, draw-effects §2.2), mirrored by
///    `+0x17e` (the face is flipped in its frame, then windowed); then the **mask pass**: the silhouette as 0 into the
///    mask port `0008` with the same geometry (`1002d18c..1002d2c0`);
/// 5. the light pass when `+0x88` ∧ prefs Effects ≠ 3 ∧ mode ≠ 0xe (`1001493c..1001499c`): `.WrapLightFace` clips as
///    step 3 and per ring copy `.DrawLightOverFace`: D = `.GetAmbDarkVal(x + w'/2, y + h'/2)` with the clipped w', h'
///    (l. 15103–15106); with no light slot meeting the face and header `0x2706` > 0, `.BlitAmbDarkenOverFaceClip`
///    remaps every frame pixel under the face's copy runs through ambient slab D.
///
/// Not reached by a level-1 Setup and refused by name (`Refusal`): hurt flash (3, 4), diffuse (5), ripple and the
/// water split (6, `+0x11c`), behind-tiles (8), squash (0xa), translucency (0xb, 0xd — table `0148` not built),
/// silhouette (0xe), tile blends (≥ 0x14), the undefined Special tables (2, 7, 0xf..0x13), a light slot in use.
/// Rotation and scale are not in the seam (`SpriteDraw`); Phase 1 never sets them.
public struct SpriteBlitter: Sendable {

    public enum Refusal: Error, Equatable {
        /// A draw mode no level-1 Setup stores (`mode` = the whole `+0xb8` word).
        case mode(UInt32)
        /// `+0x11c` ≠ 0 (the water split, mode 6 rows).
        case waterSplit(Int)
        /// A light slot is active: the per-sprite light blitters are not built (no level-1 Setup adds a light that
        /// Phase 1 models).
        case lights
        /// The ambient table for this darkness (outside 0 … 15 and −1).
        case darkness(Int)
        /// `SpriteSlot.previous` with a rotation or a non-unit scale.
        case transform
    }

    /// The face sets the sprites draw from (`SetupFaces.Sheet`s), loaded once.
    public struct Faces: Sendable {
        public private(set) var sheets: [Int16: FaceSheet] = [:]

        public init(sheets: [Int16: FaceSheet]) { self.sheets = sheets }

        /// Each sheet loaded as its `.Init<Class>Sprite` / cache call does: `GetPicture` on the front-end chain
        /// (Sprites → Sounds → Titles → app), converted under the sheet's CLUT.
        public init<S: Sequence>(_ wanted: S, resources: FerazelResources, search: ColorSearch,
                                 dither: DitherModel = .errorDiffusion) throws where S.Element == SetupFaces.Sheet {
            var cluts: [Int16: ColorLUT] = [:]
            for s in wanted where sheets[s.pict] == nil {
                let clut: ColorLUT
                if let c = cluts[s.clut] { clut = c } else {
                    clut = try ColorLUT.load(id: s.clut, from: resources, chain: .level)
                    cluts[s.clut] = clut
                }
                let loader: FaceSheet.Loader = s.single
                    ? .single(pict: s.pict)
                    : .set(try FaceSheet.Arguments(pict: s.pict, count: s.count, cellWidth: s.cellWidth,
                                                   cellHeight: s.cellHeight, columns: s.columns))
                sheets[s.pict] = try FaceSheet.load(loader, from: resources, chain: .frontEnd, clut: clut,
                                                    search: search, dither: dither)
            }
        }

        public func face(_ ref: FaceRef) -> EncodedFace? {
            guard let s = sheets[ref.pict], s.faces.indices.contains(ref.index) else { return nil }
            return s.faces[ref.index]
        }
    }

    public let level: LevelFile
    public let tables: LevelTables
    public let faces: Faces
    /// prefs `+6` Effects (3 skips the light pass).
    public var effects: Int16
    /// The light slots `.DrawLightOverFace` walks and the darkness it reads.
    public var lights: LightRenderer

    public init(level: LevelFile, tables: LevelTables, faces: Faces, effects: Int16 = FerazelPrefs().effects,
                lights: LightRenderer? = nil) {
        self.level = level
        self.tables = tables
        self.faces = faces
        self.effects = effects
        self.lights = lights ?? LightRenderer(level: level, tables: tables)
    }

    // MARK: - `.WrapDrawSprites`

    /// The draw pass over `draws` (active-list order) at scroll (h, v) (`PTR_DAT_1009fe78`); `drawn` is the grid's
    /// `_DAT_1009fe74` / `_DAT_1009fe70` pair the cull offsets by. A `FaceRef` with no loaded face draws nothing.
    public func wrapDrawSprites(_ draws: [SpriteDraw], h: Int, v: Int, drawn: (h: Int, v: Int)? = nil,
                                ports: inout FramePorts) throws {
        let off = drawn ?? (h, v)
        let view = Rect(top: off.v, left: off.h, bottom: off.v + 0x180, right: off.h + 0x260)
        for d in draws {
            guard let face = faces.face(d.face) else { continue }
            guard Rect(face.bounds).offset(dh: off.h, dv: off.v).intersects(view) else { continue }
            let fw = face.width, fh = face.height
            let top = d.clip.top, left = d.clip.left
            var hgt = fh - top, wid = fw - left
            if d.clip.bottom < fh { hgt -= fh - d.clip.bottom }
            if d.clip.right < fw { wid -= fw - d.clip.right }
            guard d.waterRow == 0 else { throw Refusal.waterSplit(d.waterRow) }
            let op = try special(d.mode)
            Self.wrap(src: (top, left), dst: (d.y + top, d.x + left), w: wid, h: hgt, h0: h, v0: v) { s, t, w, hh in
                Self.blit(face, into: &ports.frame, src: s, dst: t, w: w, h: hh, flip: d.mirrored, reject: true, op)
                Self.blit(face, into: &ports.mask, src: s, dst: t, w: w, h: hh, flip: d.mirrored, reject: true) { _, _ in 0 }
            }
            if d.lightOverlay && effects != 3 && d.mode >> 16 != 0xe {
                try lightFace(face, src: (top, left), dst: (d.y + top, d.x + left), w: wid, h: hgt, x: d.x, y: d.y,
                              flip: d.mirrored, h0: h, v0: v, ports: &ports)
            }
        }
    }

    /// The per-pixel rule of `.BlitEncFaceX` for `word` (draw-effects §1.2, §2.2): mode 0 copies; 1 → tint table
    /// sub (`_DAT_100a0140 + sub·0x100`); 9 → water table 0 (`_DAT_100a0170`, sub always 0 from the writers; the
    /// table is `sub`); 0xc → F = sub low byte, L = sub >> 8 signed: F = 0 → ambient L (`_DAT_100a0130 + L·0x100`),
    /// else light `_DAT_100a0134 + L·0x6e00 + F·0x100`.
    func special(_ word: UInt32) throws -> (UInt8, UInt8) -> UInt8 {
        let mode = Int(word >> 16), sub = Int(Int16(truncatingIfNeeded: word & 0xffff))
        switch mode {
        case 0:
            return { s, _ in s }
        case 1:
            guard tables.tint.indices.contains(sub) else { throw Refusal.mode(word) }
            let t = tables.tint[sub]
            return { s, _ in t[Int(s)] }
        case 9:
            guard tables.water.indices.contains(sub) else { throw Refusal.mode(word) }
            let t = tables.water[sub]
            return { s, _ in t[Int(s)] }
        case 0xc:
            let L = sub >> 8, F = sub & 0xff
            guard tables.ambient.indices.contains(L) else { throw Refusal.darkness(L) }
            if F == 0 {
                let t = tables.ambient[L]
                return { s, _ in t[Int(s)] }
            }
            let base = L * 0x6e00 + F * 0x100
            guard base + 0x100 <= tables.light.count else { throw Refusal.mode(word) }
            let light = tables.light
            return { s, _ in light[base + Int(s)] }
        default:
            throw Refusal.mode(word)
        }
    }

    /// `.WrapLightFace` + `.DrawLightOverFace` (no light slot) for one sprite.
    private func lightFace(_ face: EncodedFace, src: (Int, Int), dst: (Int, Int), w: Int, h: Int, x: Int, y: Int,
                           flip: Bool, h0: Int, v0: Int, ports: inout FramePorts) throws {
        guard !lights.slots.contains(where: { $0.active }) else { throw Refusal.lights }
        var failure: Refusal?
        Self.wrap(src: src, dst: dst, w: w, h: h, h0: h0, v0: v0) { s, t, ww, hh in
            guard failure == nil else { return }
            let D = lights.darkness(x: x + (ww >> 1), y: y + (hh >> 1))
            guard level.header.darknessEnable > 0 else { return }
            guard D == -1 || tables.ambient.indices.contains(D) else { failure = .darkness(D); return }
            let slab = lights.ambientSlab(D)
            Self.blit(face, into: &ports.frame, src: s, dst: t, w: ww, h: hh, flip: flip, reject: false) { _, p in
                slab[Int(p)]
            }
        }
        if let failure { throw failure }
    }

    // MARK: - `.WrapEraseSprites`

    /// The dirty-rect restore after a frame, over `sprites` in active-list order at scroll (h, v): for each sprite
    /// with a last-frame face (`+0xc8`), the rect test, the change test, then `.WrapBackScratchFace` (frame ← tiles
    /// port `0004` under the last-frame face at the last-frame position), `.WrapEraseBoolFace` (mask ← 0xFF there) and
    /// `.RedrawScrollGrid(cells, 1)` over the cells the erased rect covers (with `grid`: the mask-only re-stamp).
    /// Returns the cell rects re-stamped (top row, left col, bottom row, right col; inclusive).
    ///
    /// Read as written (raw `10014a80..10014c34`): the rect tested against the ring window `((h >> 5)·32, (v >> 5)·32,
    /// +640, +416)` and the four 32-px edge strips of the view is the last face's opaque bounds (mirrored when `+0x17f`)
    /// offset by the **scroll** (h, v) (`10014c08..10014c14`), not by the sprite's position — so the edge test fires
    /// for any face whose bounds lie within 16 px of a face-local edge of (0, 0, 608, 384).
    @discardableResult
    public func wrapEraseSprites(_ sprites: [SpriteSlot], h: Int, v: Int, ports: inout FramePorts,
                                 grid: TileGridRenderer? = nil) throws -> [(top: Int, left: Int, bottom: Int, right: Int)] {
        let ring = Rect(top: (v >> 5) << 5, left: (h >> 5) << 5, bottom: ((v >> 5) << 5) + 0x1a0,
                        right: ((h >> 5) << 5) + 0x280)
        let view = Rect(top: v, left: h, bottom: v + 0x180, right: h + 0x260)
        let strips = [Rect(top: view.top - 0x10, left: view.left, bottom: view.top + 0x10, right: view.right),
                      Rect(top: view.top, left: view.left - 0x10, bottom: view.bottom, right: view.left + 0x10),
                      Rect(top: view.bottom - 0x10, left: view.left, bottom: view.bottom + 0x10, right: view.right),
                      Rect(top: view.top, left: view.right - 0x10, bottom: view.bottom, right: view.right + 0x10)]
        var restamped: [(top: Int, left: Int, bottom: Int, right: Int)] = []
        for s in sprites {
            guard let prev = s.previous, let face = faces.face(prev.face) else { continue }
            guard s.previousRotation == 0, s.previousScale == 0x100 else {
                throw Refusal.transform
            }
            guard s.previousWaterRow == 0 else { throw Refusal.waterSplit(Int(s.previousWaterRow)) }
            var bounds = Rect(face.bounds)
            if prev.mirrored {
                bounds = Rect(top: bounds.top, left: Int(face.frame.left) + face.width - Int(face.bounds.right),
                              bottom: bounds.bottom, right: face.width - Int(face.bounds.left))
            }
            let tested = bounds.offset(dh: h, dv: v)
            guard tested.intersects(ring) else { continue }
            let nearEdge = strips.contains { tested.intersects($0) }
            let prevMode = Int(prev.mode >> 16)
            let changed = s.x != prev.x || s.y != prev.y || s.face != prev.face || s.mirrored != prev.mirrored
                || prevMode == 0xb || prevMode == 5 || s.previousWaterRow != 0 || s.burning || nearEdge
                || s.face == nil || s.clip.left != 0 || s.clip.top != 0 || s.clip.right != 32000
                || s.clip.bottom != 32000 || s.rotation != 0 || s.previousRotation != 0 || s.scale != 0x100 || s.dead
            guard changed else { continue }
            let erased = bounds.offset(dh: prev.x, dv: prev.y)
            let fw = face.width, fh = face.height
            Self.wrap(src: (0, 0), dst: (prev.y, prev.x), w: fw, h: fh, h0: h, v0: v) { sp, t, w, hh in
                let tiles = ports.tiles
                Self.blit(face, into: &ports.frame, src: sp, dst: t, w: w, h: hh, flip: prev.mirrored, reject: true,
                          index: { o, _, _ in tiles[o] })
            }
            Self.wrap(src: (0, 0), dst: (prev.y, prev.x), w: fw, h: fh, h0: h, v0: v) { sp, t, w, hh in
                Self.blit(face, into: &ports.mask, src: sp, dst: t, w: w, h: hh, flip: prev.mirrored, reject: true) { _, _ in
                    0xff
                }
            }
            guard let cells = erased.intersection(ring) else { continue }   // [MED: SectRectFast's empty result]
            let r = (top: cells.top >> 5, left: cells.left >> 5, bottom: cells.bottom >> 5, right: cells.right >> 5)
            grid?.redrawScrollGridMask(top: r.top, left: r.left, right: r.right, bottom: r.bottom, h: h, v: v,
                                       ports: &ports)
            restamped.append(r)
        }
        return restamped
    }

    // MARK: - geometry

    /// A QuickDraw rect (top, left, bottom, right), half-open.
    struct Rect: Equatable {
        var top: Int, left: Int, bottom: Int, right: Int

        init(top: Int, left: Int, bottom: Int, right: Int) {
            self.top = top; self.left = left; self.bottom = bottom; self.right = right
        }

        init(_ r: EncodedFace.Rect) {
            self.init(top: Int(r.top), left: Int(r.left), bottom: Int(r.bottom), right: Int(r.right))
        }

        func offset(dh: Int, dv: Int) -> Rect { Rect(top: top + dv, left: left + dh, bottom: bottom + dv, right: right + dh) }

        func intersection(_ o: Rect) -> Rect? {
            let r = Rect(top: max(top, o.top), left: max(left, o.left), bottom: min(bottom, o.bottom),
                         right: min(right, o.right))
            return r.top < r.bottom && r.left < r.right ? r : nil
        }

        func intersects(_ o: Rect) -> Bool { intersection(o) != nil }
    }

    /// The `.Wrap*Face` wrapper (`.WrapDrawFace` with the frame port, `.WrapLightFace`, `.WrapBackScratchFace`,
    /// `.WrapEraseBoolFace` — the same code): the view test and clip against scroll (h0, v0), then `body(src, dst, w,
    /// h)` at the ring position and its up-to-three wrapped copies. Points are (v, h).
    static func wrap(src: (Int, Int), dst: (Int, Int), w: Int, h: Int, h0: Int, v0: Int,
                     _ body: ((Int, Int), (Int, Int), Int, Int) -> Void) {
        var (sv, sh) = src, (dv, dh) = dst, w = w, h = h
        guard dh + w >= h0, dv + h >= v0, dh <= h0 + 0x260, dv <= v0 + 0x180 else { return }
        if dv + h > v0 + 0x180 { h = v0 + 0x180 - dv }
        if dh + w > h0 + 0x280 { w = h0 + 0x280 - dh }
        if dh < h0 { let d = h0 - dh; w -= d; sh += d; dh = h0 }
        if dv < v0 { let d = v0 - dv; h -= d; sv += d; dv = v0 }
        let rh = dh % FramePorts.width, rv = dv % FramePorts.height   // C truncation (`mulhw 0x66666667` / `0x4ec4ec4f`)
        body((sv, sh), (rv, rh), w, h)
        if rv - FramePorts.height + h > 0 { body((sv, sh), (rv - FramePorts.height, rh), w, h) }
        if rh - FramePorts.width + w > 0 { body((sv, sh), (rv, rh - FramePorts.width), w, h) }
        if rh - FramePorts.width + w > 0 && rv - FramePorts.height + h > 0 {
            body((sv, sh), (rv - FramePorts.height, rh - FramePorts.width), w, h)
        }
    }

    /// One `.BlitEncFace*` call: the face's source window (rows `[sv, sv + h)`, columns `[sh, sh + w)`; with `flip`
    /// the face mirrored in its frame first, `.BlitEncFaceFlipClip @ 10028f48`: face column c lands at
    /// dh − sh + width − 1 − c) at port position (dv, dh), clipped to the 640×416 port as `.BlitEncFaceClipX @ 10024998`
    /// clips (left/top edge moves the source, right/bottom edge shortens the window). `reject`: `.BlitEncFaceX`'s
    /// entry test (dh + face width < 0, dv + face height < 0, dh > 640, dv > 416 → nothing). Each copy-run pixel
    /// becomes `op(source pixel, port pixel)`; skips leave the port alone.
    static func blit(_ face: EncodedFace, into port: inout [UInt8], src: (Int, Int), dst: (Int, Int), w: Int, h: Int,
                     flip: Bool, reject: Bool, _ op: (UInt8, UInt8) -> UInt8) {
        blit(face, into: &port, src: src, dst: dst, w: w, h: h, flip: flip, reject: reject,
             index: { _, s, old in op(s, old) })
    }

    /// As above with `index(portIndex, source pixel, port pixel)`.
    static func blit(_ face: EncodedFace, into port: inout [UInt8], src: (Int, Int), dst: (Int, Int), w: Int, h: Int,
                     flip: Bool, reject: Bool, index: (Int, UInt8, UInt8) -> UInt8) {
        let W = FramePorts.width, H = FramePorts.height
        let fw = face.width, fh = face.height
        var (sv, sh) = src, (dv, dh) = dst, w = w, h = h
        if reject { guard dh + fw >= 0, dv + fh >= 0, dh <= W, dv <= H else { return } }
        if dh < 0 { sh -= dh; w += dh; dh = 0 }
        if dv < 0 { h += dv; sv -= dv; dv = 0 }
        if W <= dh + w { w = W - dh }
        if H <= dv + h { h = H - dv }
        guard w > 0, h > 0 else { return }
        let ox = dh - sh, oy = dv - sv               // face (0, 0) in port coordinates
        // Face columns drawn: [sh, sh + w) unflipped, [fw − sh − w, fw − sh) flipped.
        let c0 = flip ? fw - sh - w : sh, c1 = flip ? fw - sh : sh + w
        face.data.withUnsafeBufferPointer { data in
            port.withUnsafeMutableBufferPointer { out in
                var p = 0, row = -1, col = 0
                while p + 4 <= data.count {
                    let tok = data[p], n = Int(data[p + 1]) << 16 | Int(data[p + 2]) << 8 | Int(data[p + 3])
                    p += 4
                    switch tok {
                    case 1:
                        row += 1
                        col = 0
                        if row >= sv + h { return }
                    case 3:
                        col += n
                    case 2:
                        if row >= sv {
                            let a = max(col, c0), b = min(col + n, c1)
                            if a < b {
                                let py = oy + row
                                for c in a..<b {
                                    let px = flip ? ox + fw - 1 - c : ox + c
                                    let o = py * W + px
                                    out[o] = index(o, data[p + c - col], out[o])
                                }
                            }
                        }
                        col += n
                        p += (n + 3) & ~3
                    default:
                        return
                    }
                }
            }
        }
    }
}

// MARK: - `.RedrawScrollGrid(rect, 1)`: the mask-only re-stamp `.WrapEraseSprites` calls

extension TileGridRenderer {

    /// `.RedrawScrollGrid(rect, param_2 ≠ 0)` (decompile l. 9812–10088, the `param_2` arms): per cell (col, row)
    /// with FG tile t, BG tile b and overlay o1/o2, only boolean stamps into the mask port, no cell clear, no tile
    /// draw, no light, no copy to the frame: b < 0 ∧ t ≥ 0 → the FG rule (FG face without a transparent pixel or b < 0
    /// → FG stamp) then the overlay o2 stamp; b ≥ 0 → BG stamp, the FG stamp when t ≥ 0 and the BG face has a
    /// transparent pixel, the overlay o2 stamp; then (every cell with o1 = 100 / 101) the overlay stamp again.
    func redrawScrollGridMask(top: Int, left: Int, right: Int, bottom: Int, h: Int, v: Int, ports: inout FramePorts) {
        guard top <= bottom, left <= right else { return }
        let scroll = TileBlitters.Scroll(h: h, v: v)
        let width = Int(level.header.gridWidth), height = Int(level.header.gridHeight)
        let fg = sets.fg.faces, bg = sets.bg.faces
        for row in top...bottom {
            for col in left...right where col >= 0 && col < width && row >= 0 && row < height {
                let x = col << 5, y = row << 5
                let t = level.fgTile(col: col, row: row), b = level.bgTile(col: col, row: row)
                let o1 = level.overlay1(col: col, row: row)
                let o2 = o1 > 99 ? level.overlay2(col: col, row: row) : -1
                guard (-1...0x5f).contains(t), (-1...0x5f).contains(b) else { return }
                func stamp(_ face: EncodedFace) {
                    TileBlitters.wrapDraw(face, .bool, into: &ports.mask, x: x, y: y, scroll: scroll)
                }
                func overlay() {
                    guard o2 >= 0 else { return }
                    if o1 == 100, o2 < fg.count { stamp(fg[o2]) } else if o1 == 101, o2 < bg.count { stamp(bg[o2]) }
                }
                if b < 0 && t >= 0 {
                    stamp(fg[t])   // `!fg[t].hasTransparentPixel || b < 0`: b < 0 holds
                    overlay()
                } else if b >= 0 {
                    stamp(bg[b])
                    if t >= 0 && bg[b].hasTransparentPixel { stamp(fg[t]) }
                    overlay()
                }
                overlay()
            }
        }
    }
}
