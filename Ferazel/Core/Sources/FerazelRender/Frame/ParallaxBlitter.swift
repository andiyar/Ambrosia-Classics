import Foundation
import FerazelCore

/// The copy of the frame to the screen with the parallax backdrop composited on the way (rendering-omnipx-titles
/// §1.1–§1.5, transcribed as written — Invariant 3): `.PaintFrameWrap` → `.WrapCopyToScreen @ 100174bc` →
/// `.DoubleBlitUniversal @ 10022e34` → `.DoubleBlitPPCParallaxOneLayer @ 10017924`. The Fire variant
/// (`…Fire @ 10018dd4`, header `0x2722 > 0`, levels 52/55, §1.6) and OmniPx (§3) are not built: a level with a
/// flame mode is refused, and `omniPxActive` only makes `.GetPxBackTile` answer 0 (`1003c4f8..1003c514`). The
/// ripple table's producer is not built either, so a level with the ripple flag (header `0x26ca`, levels 11, 18) is
/// refused too (Invariant 6) rather than drawn without its ripple.
///
/// Sources per output byte (§1.2): **F** the source port (the frame `000c`), **M** the mask port `0008` (0xFF where
/// the backdrop may show), and the 8 col × 6 row cell tables **I** (`PTR_DAT_100a1020`) and **K** (`_DAT_100a101c`)
/// of 128×128 faces. A face is named by its slot in the three contiguous pointer tables — PxBack 0..<36
/// (`0x100a4f14`), PxMid image (sheet id) 36..<48 (`0x100a4fa4`), PxMid mask (sheet id+1) 48..<60 (`0x100a4fd4`) —
/// so the PxMid cell −1 reads entry [−1] of its table exactly as the binary does (§2.2: image table [−1] = PxBack 35,
/// mask table [−1] = PxMid image 11). A slot is dereferenced only when a row reads it (the binary stores a pointer
/// for every cell, reads only some).
///
/// The screen is 640×480 8-bit indices, row-major; the 608×384 view lands at (16, 8).
public struct ParallaxBlitter: Sendable {
    public static let screenWidth = 0x280
    public static let screenHeight = 0x1e0
    /// The cell size of both layers.
    static let cell = 0x80
    static let cellBytes = 0x80 * 0x80
    /// Per-row factor arrays cover view rows 0..<480 (`10017c90..10017c98`).
    static let factorRowCount = 0x1e0
    static let backBase = 0, midImageBase = 36, midMaskBase = 48, slotCount = 60

    /// A QuickDraw `Rect` (top, left, bottom, right).
    public struct Rect: Hashable, Sendable {
        public var top: Int, left: Int, bottom: Int, right: Int

        public init(top: Int, left: Int, bottom: Int, right: Int) {
            self.top = top; self.left = left; self.bottom = bottom; self.right = right
        }

        public var width: Int { right - left }

        func offset(dh: Int, dv: Int) -> Rect { Rect(top: top + dv, left: left + dh, bottom: bottom + dv, right: right + dh) }
    }

    /// One drawing call of `.WrapCopyToScreen`: `src` (+ the wrapped second horizontal piece `src2`) of the source
    /// port to `dst` (+ `dst2`) on the screen, through `.DoubleBlitUniversal` (`composited`) or plain `CopyBits`.
    public struct Call: Hashable, Sendable {
        public var src: Rect
        public var src2: Rect?
        public var dst: Rect
        public var dst2: Rect?
        public var composited: Bool
    }

    /// A level whose backdrop this type does not draw.
    public enum Refusal: Error, Equatable {
        /// Header `0x2722 > 0`: `.DoubleBlitUniversal` takes the Fire variant (§1.6), not built.
        case fireVariant(flameMode: Int16)
        /// Header `0x26ca ≠ 0` (levels 11, 18): the rows need the ripple table, whose producer is not built.
        case ripple(flag: UInt8)
    }

    /// One drawn row of a compositor call, for tests and inspection.
    struct RowTrace: Equatable, Sendable {
        /// Screen row.
        var y: Int
        /// View row `r` (`stack 0xb0`): index of the per-row factor arrays.
        var viewRow: Int
        /// Table row `t` (`r19`) and sub-row `s` (`r30`) the row was drawn from.
        var tableRow: Int
        var subRow: Int
        /// Row mode `r16`: true = mid row.
        var mid: Bool
        /// The mode was re-decided (`LAB_1001886c`) just before this row.
        var redecided: Bool
        /// The cell-map row (the y argument, as an int16) table row `t` of I was last filled from.
        var cellRow: Int
    }

    // Level inputs (world-data §3.2).
    let backFactors: [Int16]
    let midFactors: [Int16]
    /// `yb` = header `0xb26c`, `ym` = `0xb26e`.
    let backYFactor: Int
    let midYFactor: Int
    /// Header `0x3268`.
    let pxMidEnable: Int16
    /// Header `0x271e` (0 in all 24 levels) and `0x26ca` — the stack flags `0x86`/`0x85` (`100179a0..100179f0`).
    let parallaxMode: Int16
    let parallaxRipple: UInt8
    let pxBackMap: TileMap
    let pxMidMap: TileMap
    /// `slotCount` faces of `cellBytes` each, back to back.
    let faces: [UInt8]
    let slotLoaded: [Bool]

    /// Game globals `+0x174` (OmniPx on): `.GetPxBackTile` returns 0.
    public var omniPxActive = false
    /// The ripple table `*_DAT_1009ffb8` (i32 per virtual row; each row's x offset is `−(entry >> 8)`), non-zero only
    /// with header `0x26ca` (levels 11, 18). Not produced in Phase 1: its producer is not built and those levels are
    /// refused at init, so it stays empty (reads 0).
    public var rippleTable: [Int32] = []

    /// The blitter for a level with its loaded PxBack and PxMid sets (`TileSets`).
    public init(level: LevelFile, pxBack: PlainFaceSheet, pxMid: TileSets.PxMid<PlainFaceSheet>?) throws {
        var slots = [[UInt8]?](repeating: nil, count: Self.slotCount)
        for (i, f) in pxBack.faces.enumerated() where i < Self.midImageBase { slots[Self.backBase + i] = f }
        if let pxMid {
            for (i, f) in pxMid.image.faces.enumerated() where i < 12 { slots[Self.midImageBase + i] = f }
            for (i, f) in pxMid.mask.faces.enumerated() where i < 12 { slots[Self.midMaskBase + i] = f }
        }
        try self.init(level: level, faceSlots: slots)
    }

    public init(level: LevelFile, sets: TileSets) throws {
        try self.init(level: level, pxBack: sets.pxBack, pxMid: sets.pxMid)
    }

    /// Faces by slot (`slotCount` entries, each nil or `cellBytes` bytes). Every init path ends here, so both
    /// refusals apply to all of them.
    init(level: LevelFile, faceSlots: [[UInt8]?]) throws {
        precondition(faceSlots.count == Self.slotCount, "ParallaxBlitter: \(Self.slotCount) face slots")
        let h = level.header
        guard h.flameMode <= 0 else { throw Refusal.fireVariant(flameMode: h.flameMode) }
        guard h.parallaxRipple == 0 else { throw Refusal.ripple(flag: h.parallaxRipple) }
        backFactors = level.backFactors
        midFactors = level.midFactors
        backYFactor = Int(h.pxBackYFactor)
        midYFactor = Int(h.pxMidYFactor)
        pxMidEnable = h.pxMidEnable
        parallaxMode = h.parallaxMode
        parallaxRipple = h.parallaxRipple
        pxBackMap = level.pxBack
        pxMidMap = level.pxMid
        var faces = [UInt8](repeating: 0, count: Self.slotCount * Self.cellBytes)
        var loaded = [Bool](repeating: false, count: Self.slotCount)
        for (slot, face) in faceSlots.enumerated() {
            guard let face else { continue }
            precondition(face.count == Self.cellBytes, "ParallaxBlitter: slot \(slot) is not 128×128")
            faces.replaceSubrange((slot * Self.cellBytes)..<((slot + 1) * Self.cellBytes), with: face)
            loaded[slot] = true
        }
        self.faces = faces
        slotLoaded = loaded
    }

    // MARK: Pixel rules (§1.2)

    /// Back-row byte (`10018044..1001805c`): the backdrop only through an 0xFF mask byte.
    static func backByte(m: UInt8, f: UInt8, i: UInt8) -> UInt8 { m == 0xff ? i : f }

    /// Back-row word (`100180e8..10018130`): `M == ~0 → I`, `M == 0 → F`, else `F + (M & I)` (one 32-bit add).
    static func backWord(m: UInt32, f: UInt32, i: UInt32) -> UInt32 {
        m == 0xffff_ffff ? i : m == 0 ? f : f &+ (m & i)
    }

    /// Mid-row byte (byte loop with `r11 = 0`, `10017fa0`): the PxMid image where its mask byte is 0.
    static func midByte(k: UInt8, f: UInt8, i: UInt8) -> UInt8 { k == 0 ? i : f }

    /// Mid-row word (`10018198..100181e4`): `K == 0 → I`, `K == ~0 → F`, else `(K & F) + I` (one 32-bit add).
    static func midWord(k: UInt32, f: UInt32, i: UInt32) -> UInt32 {
        k == 0 ? i : k == 0xffff_ffff ? f : (k & f) &+ i
    }

    // MARK: .WrapCopyToScreen

    /// `.WrapCopyToScreen(port, h, v, 0x10, 8, backdrop, …)` (decompile l. 11722–11850): the 608×384 view of the
    /// 640×416 ring at `h' = h − 640·trunc(h/640)`, `v' = v − 416·trunc(v/416)`. The view splits into up to four
    /// pieces — `(v', h')..(416 or v'+384, 640 or h'+608)`, the wrapped columns `0..h'−32`, the wrapped rows `0..v'−32`
    /// and the corner — placed at screen (16, 8). With the backdrop and `h' − 32 ≥ 1` the column pieces ride in one
    /// compositor call as its second horizontal piece, and the ring split gives a second call when `v' − 32 ≥ 1`
    /// (`1001754c`). Otherwise each piece is its own call: `CopyBits` without the backdrop, the compositor with it —
    /// except the corner piece, which the binary always sends through `.DoubleBlitUniversal` (`10017884..100178e4`;
    /// its `CopyBits` at `100178bc` is unreachable), even without the backdrop.
    public static func calls(h: Int, v: Int, backdrop: Bool, left: Int = 0x10, top: Int = 8) -> [Call] {
        let v1 = Int(Int16(truncatingIfNeeded: v - (v / 0x1a0) * 0x1a0))
        let h1 = Int(Int16(truncatingIfNeeded: h - (h / 0x280) * 0x280))
        let rows = v1 - 0x20, cols = h1 - 0x20
        let bottom = rows < 1 ? v1 + 0x180 : 0x1a0
        let right = cols < 1 ? h1 + 0x260 : 0x280
        let r78 = Rect(top: v1, left: h1, bottom: bottom, right: right)
        let r70 = Rect(top: v1, left: 0, bottom: bottom, right: cols)
        let r68 = Rect(top: 0, left: h1, bottom: rows, right: right)
        let r60 = Rect(top: 0, left: 0, bottom: rows, right: cols)
        let dh = left - h1, dv = top - v1
        let dh2 = 0x280 - h1 + left, dv2 = 0x1a0 - v1 + top
        let d78 = r78.offset(dh: dh, dv: dv), d70 = r70.offset(dh: dh2, dv: dv)
        let d68 = r68.offset(dh: dh, dv: dv2), d60 = r60.offset(dh: dh2, dv: dv2)
        if backdrop && cols >= 1 {
            var calls = [Call(src: r78, src2: r70, dst: d78, dst2: d70, composited: true)]
            if rows > 0 { calls.append(Call(src: r68, src2: r60, dst: d68, dst2: d60, composited: true)) }
            return calls
        }
        var calls = [Call(src: r78, src2: nil, dst: d78, dst2: nil, composited: backdrop)]
        if cols > 0 { calls.append(Call(src: r70, src2: nil, dst: d70, dst2: nil, composited: backdrop)) }
        if rows > 0 { calls.append(Call(src: r68, src2: nil, dst: d68, dst2: nil, composited: backdrop)) }
        if rows > 0 && cols > 0 { calls.append(Call(src: r60, src2: nil, dst: d60, dst2: nil, composited: true)) }
        return calls
    }

    /// `.WrapCopyToScreen` for the `DrawOp.copyToScreen` of a frame: `source` is the port copied (the frame `000c`),
    /// `mask` the mask port `0008`; `graphicsMode` prefs+2, `parallax` prefs+4, `backdrop` = prefs+9 == 0.
    public func copyToScreen(source: [UInt8], mask: [UInt8], h: Int, v: Int, graphicsMode: Int, backdrop: Bool,
                             parallax: Int, screen: inout [UInt8]) {
        var none: [[RowTrace]]? = nil
        copyToScreen(source: source, mask: mask, h: h, v: v, graphicsMode: graphicsMode, backdrop: backdrop,
                     parallax: parallax, screen: &screen, trace: &none)
    }

    /// As above, from the ports (`frame` copied, `mask` gating).
    public func copyToScreen(ports: FramePorts, h: Int, v: Int, graphicsMode: Int, backdrop: Bool, parallax: Int,
                             screen: inout [UInt8]) {
        copyToScreen(source: ports.frame, mask: ports.mask, h: h, v: v, graphicsMode: graphicsMode,
                     backdrop: backdrop, parallax: parallax, screen: &screen)
    }

    /// With `trace` non-nil, one `[RowTrace]` per compositor call that drew is appended.
    func copyToScreen(source: [UInt8], mask: [UInt8], h: Int, v: Int, graphicsMode: Int, backdrop: Bool,
                      parallax: Int, screen: inout [UInt8], trace: inout [[RowTrace]]?) {
        precondition(source.count == FramePorts.width * FramePorts.height && mask.count == source.count,
                     "ParallaxBlitter: ports are 640×416")
        precondition(screen.count == Self.screenWidth * Self.screenHeight, "ParallaxBlitter: screen is 640×480")
        for call in Self.calls(h: h, v: v, backdrop: backdrop) {
            if call.composited {
                doubleBlitUniversal(call, source: source, mask: mask, h: h, v: v, graphicsMode: graphicsMode,
                                    parallax: parallax, screen: &screen, trace: &trace)
            } else {
                copyBits(call.src, call.dst, source: source, screen: &screen)
            }
        }
    }

    /// `CopyBits(srcCopy)` of a same-size rect, clipped to the screen.
    func copyBits(_ src: Rect, _ dst: Rect, source: [UInt8], screen: inout [UInt8]) {
        for row in 0..<max(0, src.bottom - src.top) {
            let y = dst.top + row
            guard (0..<Self.screenHeight).contains(y) else { continue }
            for col in 0..<max(0, src.width) {
                let x = dst.left + col
                guard (0..<Self.screenWidth).contains(x) else { continue }
                screen[y * Self.screenWidth + x] = source[(src.top + row) * FramePorts.width + src.left + col]
            }
        }
    }

    /// `.DoubleBlitUniversal @ 10022e34`: rect sanity gates (every top/left/bottom ≥ 0, bottoms < 0x1e1), the
    /// parallax gate (prefs+4 = 3 → nothing, `10022f8c..10022fa8`), then by graphics (prefs+2, `10023024..1002307c`)
    /// 1 → (lineSkip 0, doubled 0), 2 → (0, 1), 3 → (1, 0), anything else → nothing.
    func doubleBlitUniversal(_ call: Call, source: [UInt8], mask: [UInt8], h: Int, v: Int, graphicsMode: Int,
                             parallax: Int, screen: inout [UInt8], trace: inout [[RowTrace]]?) {
        let rects = [call.src, call.dst] + [call.src2, call.dst2].compactMap { $0 }
        guard rects.allSatisfy({ $0.left >= 0 && $0.top >= 0 && $0.bottom >= 0 && $0.bottom < 0x1e1 }) else { return }
        guard parallax != 3 else { return }                 // flame mode ≤ 0: refused at init otherwise
        let lineSkip: Bool, doubled: Bool
        switch graphicsMode {
        case 1: (lineSkip, doubled) = (false, false)
        case 2: (lineSkip, doubled) = (false, true)
        case 3: (lineSkip, doubled) = (true, false)
        default: return
        }
        var rows: [RowTrace]? = trace == nil ? nil : []
        blitOneLayer(source: source, mask: mask, src: call.src, src2: call.src2, dst: call.dst, dst2: call.dst2,
                     lineSkip: lineSkip, doubled: doubled, h: h, v: v, screen: &screen, trace: &rows)
        if let rows { trace?.append(rows) }
    }

    // MARK: .DoubleBlitPPCParallaxOneLayer

    /// `.GetPxBackTile @ 1003c4d8`: 0 while OmniPx is on; else `.ConstrainXY` (int16 arguments, clamp to the map)
    /// and the signed cell.
    func pxBackTile(_ x: Int, _ y: Int) -> Int {
        if omniPxActive { return 0 }
        return Int(Int16(bitPattern: pxBackMap.cell(col: Int(Int16(truncatingIfNeeded: x)), row: Int(Int16(truncatingIfNeeded: y)))))
    }

    /// `.GetPxMidTile @ 1003c59c`: `.ConstrainXY` and the signed cell (0xFFFF → −1; no −1 handling, §2.1).
    func pxMidTile(_ x: Int, _ y: Int) -> Int {
        Int(Int16(bitPattern: pxMidMap.cell(col: Int(Int16(truncatingIfNeeded: x)), row: Int(Int16(truncatingIfNeeded: y)))))
    }

    /// `hdr + 0x326c + 2i` — the PxBack table runs on into the PxMid table (`0x726c`). Outside both the binary reads
    /// neighbouring header bytes; this reads 0 there (no non-Fire shipped level reaches it at `V ∈ [0, 32·H − 384]`;
    /// self-checked bound: the largest index read is (qm + 5)·128 = 5,760, level 22 at V = 3,712).
    func backFactor(_ i: Int) -> Int {
        if (0..<backFactors.count).contains(i) { return Int(backFactors[i]) }
        return midFactor(i - backFactors.count)
    }

    /// `hdr + 0x726c + 2i` (0 outside the table, as `backFactor`).
    func midFactor(_ i: Int) -> Int { (0..<midFactors.count).contains(i) ? Int(midFactors[i]) : 0 }

    func ripple(_ i: Int) -> Int { (0..<rippleTable.count).contains(i) ? Int(rippleTable[i]) : 0 }

    /// The byte split of one horizontal piece in tile space (`10017dd8..10017e40`): `lead = ((x+3)&~3) − x` bytes,
    /// `words = (w − lead) >> 2`, `tail = (w − lead) & 3`, `edge` = words to the cell edge after the lead; all bytes
    /// when `w ≤ 4` (unsigned compare).
    struct Split {
        var phase: Int, lead: Int, words: Int, tail: Int, edge: Int

        init(phase: Int, width: Int) {
            self.phase = phase
            var lead = ((phase + 3) >> 2) * 4 - phase
            let rest = width - lead
            var tail = rest - (rest & ~3)
            var words = Int(UInt32(truncatingIfNeeded: rest - tail) >> 2)
            var end = phase + lead
            if end > 0x7f { end = phase + (lead - 0x80) }
            edge = (0x80 - end) >> 2
            if UInt32(truncatingIfNeeded: width) <= 4 { lead = width; tail = 0; words = 0 }
            self.lead = lead; self.words = words; self.tail = tail
        }
    }

    /// `.DoubleBlitPPCParallaxOneLayer @ 10017924` (r3 source port, r4 `src`, r5 `src2`, r6 `dst`, r7 `dst2`,
    /// r8 `lineSkip`, r9 `doubled`), §1.3 step by step.
    func blitOneLayer(source: [UInt8], mask: [UInt8], src: Rect, src2: Rect?, dst: Rect, dst2: Rect?,
                      lineSkip: Bool, doubled: Bool, h: Int, v: Int, screen: inout [UInt8],
                      trace: inout [RowTrace]?) {
        // Prologue (`10017950..10017a78`): parity of the top as passed, clamps, then the line-skip top made even.
        let parity = dst.top & 1
        var top = dst.top, bottom = dst.bottom
        var top2 = dst2?.top ?? 0
        if top < 0 { top = 0; top2 = 0 }
        if bottom > Self.screenHeight { bottom = Self.screenHeight }
        if lineSkip { top += parity }
        let left = dst.left, left2 = dst2?.left ?? 0
        let step = (lineSkip || doubled) ? 2 : 1
        var forceRedecide = parallaxMode != 0 && parallaxRipple == 0      // stack 0x86
        let lateForce = parallaxMode != 0 && parallaxRipple != 0          // stack 0x85

        // §1.3 step 1 (`10017a7c..10017ae4`): qm, qb with truncating division.
        let v0m = (v * midYFactor) >> 8, v0b = (v * backYFactor) >> 8
        let qm = (top - 8 + v0m) / 0x80, qb = (top - 8 + v0b) / 0x80

        // Step 2 (`10017aec..10017bec`): I = PxBack at the table-row start factor, K = PxMid mask (sheet id+1).
        var tableI = [Int](repeating: 0, count: 8 * 6), tableK = [Int](repeating: 0, count: 8 * 6)
        var cellRows = [Int](repeating: 0, count: 6)
        for col in 0..<8 {
            for row in 0..<6 {
                let xb = (left + ((h * backFactor((qb + row) * 0x80)) >> 8)) - 0x10
                tableI[col * 6 + row] = Self.backBase + pxBackTile(col + xb / 0x80, qb + row)
                let xm = (left + ((h * midFactor((qm + row) * 0x80)) >> 8)) - 0x10
                tableK[col * 6 + row] = Self.midMaskBase + pxMidTile(col + xm / 0x80, qm + row)
                cellRows[row] = Int(Int16(truncatingIfNeeded: qb + row))
            }
        }

        // Step 3 (`10017c2c..10017c98`): per-view-row factors.
        let xbRows = (0..<Self.factorRowCount).map { backFactor($0 + v0b) }
        let rippleRows = (0..<Self.factorRowCount).map { -(ripple($0 + v0b) >> 8) }
        let xmRows = (0..<Self.factorRowCount).map { midFactor($0 + v0m) }
        let zeroRows = [Int](repeating: 0, count: Self.factorRowCount)  // `_DAT_100a100c`, zeroed here

        // Phases and sub-row (`10017c9c..10017d78`).
        var r = top - 8
        var phaseOffset = (rippleRows[r] + ((h * xbRows[r]) >> 8)) % 0x80
        var split1 = Split(phase: (left - 0x10 + phaseOffset) % 0x80, width: src.width)
        var split2 = Split(phase: (left2 - 0x10 + phaseOffset) % 0x80, width: src2?.width ?? 0)
        var s = ((top - 8) + (v0b % 0x80)) % 0x80
        let copyChunks = Int(Int16(truncatingIfNeeded: Int(UInt32(truncatingIfNeeded: src.width + (src2?.width ?? 0)) >> 3))) >> 2

        // Step 4 (`10017ed4..10017f40`): row 0 of I refilled for the current factor (no ripple in the cell x).
        for col in 0..<8 {
            let xb = (left + ((h * xbRows[r]) >> 8)) - 0x10
            tableI[col * 6] = Self.backBase + pxBackTile(col + xb / 0x80, qb)
        }
        cellRows[0] = Int(Int16(truncatingIfNeeded: qb))

        var mid = false                                                   // `li r16,0` at 1001793c
        var t = 0, n = 0
        var y = top
        var redecided = false
        var line = [UInt8](repeating: 0, count: Self.screenWidth + 8)

        source.withUnsafeBufferPointer { sourceBytes in
        mask.withUnsafeBufferPointer { maskBytes in
        faces.withUnsafeBufferPointer { faceBytes in
            while UInt32(truncatingIfNeeded: y) < UInt32(truncatingIfNeeded: bottom) {
                trace?.append(RowTrace(y: y, viewRow: r, tableRow: t, subRow: s, mid: mid, redecided: redecided,
                                       cellRow: cellRows[t]))
                // Step 5: the row, piece 1 then piece 2 (the cell column carries over).
                var column = 0
                compose(row: src.top + (y - top), srcLeft: src.left, lineOffset: 0, split: split1,
                        column: &column, t: t, s: s, mid: mid, tableI: tableI, tableK: tableK,
                        source: sourceBytes, mask: maskBytes, faces: faceBytes, line: &line)
                if let src2 {
                    compose(row: src2.top + (y - top2), srcLeft: src2.left, lineOffset: left2 - left, split: split2,
                            column: &column, t: t, s: s, mid: mid, tableI: tableI, tableK: tableK,
                            source: sourceBytes, mask: maskBytes, faces: faceBytes, line: &line)
                }
                for chunk in 0..<max(0, copyChunks) {
                    let o = y * Self.screenWidth + left + chunk * 0x20
                    screen.replaceSubrange(o..<(o + 0x20), with: line[(chunk * 0x20)..<(chunk * 0x20 + 0x20)])
                    if doubled {
                        let o2 = o + Self.screenWidth
                        screen.replaceSubrange(o2..<(o2 + 0x20), with: line[(chunk * 0x20)..<(chunk * 0x20 + 0x20)])
                    }
                }

                // Sub-row and table row (`1001874c..100187a4`).
                s += step
                if s > 0x7f { t += 1; s -= 0x80 }
                if lateForce && r > 0x280 { forceRedecide = true }      // `100187a8..100187c4`
                // Step 6 (`100187c8..10018868`): re-decide only where a factor changes.
                redecided = false
                if xbRows[r] == xbRows[r + step] && xmRows[r] == xmRows[r + step] && !forceRedecide {
                    n += step
                    r += step
                } else {
                    // `LAB_1001886c`
                    r += step
                    n += step
                    redecided = true
                    mid = xmRows[r] != 0 && pxMidEnable == 1          // `100188ec..1001891c`
                    let yFactorProduct: Int
                    if mid {
                        // `10018a10..10018aa8`: y = int16(k + qm + ((n − qm) >>> 7)), for k < min(2, 6 − t).
                        let base = qm + Int(UInt32(truncatingIfNeeded: n - qm) >> 7)
                        let rowsToFill = min(2, 6 - t)
                        for col in 0..<8 {
                            for k in 0..<max(0, rowsToFill) {
                                let xm = (left + ((h * xmRows[r]) >> 8)) - 0x10
                                let cell = pxMidTile(col + xm / 0x80, k + base)
                                tableI[col * 6 + t + k] = Self.midImageBase + cell
                                tableK[col * 6 + t + k] = Self.midMaskBase + cell
                            }
                        }
                        for k in 0..<max(0, rowsToFill) { cellRows[t + k] = Int(Int16(truncatingIfNeeded: k + base)) }
                        phaseOffset = (zeroRows[r] + ((h * xmRows[r]) >> 8)) % 0x80   // `10018ae4..10018b18`
                        yFactorProduct = v * midYFactor
                    } else {
                        // `10018924..100189b4`: row t of I only, y = int16(qb + t), x with the row's ripple.
                        for col in 0..<8 {
                            let xb = (left + ((h * xbRows[r]) >> 8) + rippleRows[r]) - 0x10
                            tableI[col * 6 + t] = Self.backBase + pxBackTile(col + xb / 0x80, qb + t)
                        }
                        cellRows[t] = Int(Int16(truncatingIfNeeded: qb + t))
                        phaseOffset = (rippleRows[r] + ((h * xbRows[r]) >> 8)) % 0x80  // `100189b8..100189e4`
                        yFactorProduct = v * backYFactor
                    }
                    // `10018b40..10018c48`: phases, sub-row `s = ((T − 8 + (V·y >> 8) mod 128) mod 128 + n) & 0x7f`.
                    split1 = Split(phase: (left - 0x10 + phaseOffset) % 0x80, width: src.width)
                    split2 = Split(phase: (left2 - 0x10 + phaseOffset) % 0x80, width: src2?.width ?? 0)
                    s = ((((top - 8) + ((yFactorProduct >> 8) % 0x80)) % 0x80) + n) & 0x7f
                }
                y += step
            }
        }
        }
        }
    }

    /// One horizontal piece of one row into the line buffer: lead bytes, words, tail bytes (decompile l. 12101–12210 /
    /// 12211–12362). `column` is the cell column (`iVar12`), advanced at every cell edge. In mid rows K comes from the
    /// K table; in back rows M comes from the mask port at the source position.
    // swiftlint:disable:next function_parameter_count
    func compose(row: Int, srcLeft: Int, lineOffset: Int, split: Split, column: inout Int, t: Int, s: Int, mid: Bool,
                 tableI: [Int], tableK: [Int], source: UnsafeBufferPointer<UInt8>, mask: UnsafeBufferPointer<UInt8>,
                 faces: UnsafeBufferPointer<UInt8>, line: inout [UInt8]) {
        var xi = split.phase
        var src = row * FramePorts.width + srcLeft
        var out = lineOffset
        var faceI = faceBase(tableI[column * 6 + t]) + s * Self.cell
        var faceK = mid ? faceBase(tableK[column * 6 + t]) + s * Self.cell : 0
        func nextCell() {
            column += 1
            xi = 0
            faceI = faceBase(tableI[column * 6 + t]) + s * Self.cell
            if mid { faceK = faceBase(tableK[column * 6 + t]) + s * Self.cell }
        }
        func byte() {
            let f = source[src], i = faces[faceI + xi]
            line[out] = mid ? Self.midByte(k: faces[faceK + xi], f: f, i: i) : Self.backByte(m: mask[src], f: f, i: i)
            src += 1; out += 1; xi += 1
            if xi > 0x7f { nextCell() }
        }
        func word(_ p: UnsafeBufferPointer<UInt8>, _ o: Int) -> UInt32 {
            UInt32(p[o]) << 24 | UInt32(p[o + 1]) << 16 | UInt32(p[o + 2]) << 8 | UInt32(p[o + 3])
        }
        for _ in 0..<split.lead { byte() }
        var edge = split.edge
        for _ in 0..<split.words {
            let f = word(source, src), i = word(faces, faceI + xi)
            let w = mid ? Self.midWord(k: word(faces, faceK + xi), f: f, i: i)
                        : Self.backWord(m: word(mask, src), f: f, i: i)
            line[out] = UInt8(w >> 24); line[out + 1] = UInt8(w >> 16 & 0xff)
            line[out + 2] = UInt8(w >> 8 & 0xff); line[out + 3] = UInt8(w & 0xff)
            src += 4; out += 4; xi += 4
            edge -= 1
            if edge == 0 { nextCell(); edge = 0x20 }
        }
        for _ in 0..<split.tail { byte() }
    }

    /// The byte offset of a face slot; a slot the binary would read as an unloaded pointer stops here.
    func faceBase(_ slot: Int) -> Int {
        precondition((0..<Self.slotCount).contains(slot) && slotLoaded[slot],
                     "ParallaxBlitter: cell table slot \(slot) has no face (unreached with shipped data, §2.4–§2.5)")
        return slot * Self.cellBytes
    }
}
