import Foundation
import HectorResources

/// One text-format record as `FUN_1000d380` takes it (0x148 bytes, hud-scorebar.md §9): the `tefo` fields,
/// the text (`+0x000`, sprintf target) and the template bytes no `tefo` key sets (text-metrics-lists.md §2.1:
/// `+0x10c` layer 8, `+0x10d` clip select 0, `+0x110` draw-now 1, `+0x118` scale 1.0). Callers write those
/// three bytes the way the original's callers do (e.g. the coin tally: layer 15, own clip, queued).
public struct TextRequest: Equatable, Sendable {
    public var format: TextFormat
    /// Text bytes (Mac Roman), up to the first NUL (`strlen`, `FUN_10057760`).
    public var text: [UInt8]
    /// `+0x10c`: render layer → draw command +0x30.
    public var layer: UInt8 = 8
    /// `+0x10d`: 1 keeps the template clip (the game area {0, 0, 480, 416}); 0 clips to the back buffer.
    public var keepTemplateClip = false
    /// `+0x110`: draw command +0x31 (1 draws now; 0 queues on `layer`).
    public var drawNow = true
    /// `+0x118`: glyph scale.
    public var scale: Float = 1

    public init(format: TextFormat, text: [UInt8]) {
        self.format = format
        self.text = Array(text.prefix { $0 != 0 })
    }

    public init(format: TextFormat, text: String) {
        self.init(format: format, text: MacRoman.encode(text, lossy: true) ?? [])
    }
}

/// G_Text.cc's layout and glyph draw (hud-scorebar.md §9, text-metrics-lists.md §1.2–§2.4, HIGH). ★ LOCKED name
/// (plan S2). Built over the font's frame sizes (`*(0x100e0120)` = `idli tesp` item 0 = `tesm`).
///
/// Listing reads for plan C5 (`disasm-review3-all.txt`):
/// - `FUN_1000d380` (`1000d380..1000d6c0`): empty text → nothing. Digit cache when the cached max w or h is 0
///   (`1000d3c4..1000d474`): max h = h('1'), max w = 0, then for i 0…9 frame f('1') + i; a strictly wider frame
///   sets `DAT_100e0124 = '0' + i` — with `tesm` widths 5, 6, 7, … that is '2' (frame 53, 6 px): the
///   monospaced cell is 6, not 7 (an original quirk, kept). The cache is global and filled once from fixed
///   data, so it is computed at `init` here. Then: shadow pass if `+0x10f` (`FUN_1000e270(…, 1)` with the
///   shadow flag), `+0x10f` cleared (`1000d4c4`); colour strip if `+0x12c` (`1000d4d0..1000d694`: a `COST`
///   command from the text template, alpha +0x138, colour +0x13c, **+0x31 = 0** (always queued), clip by
///   +0x10d, layer +0x10c, rect = measured bounds grown by H/V offsets, min width by alignment — CENT CEBU
///   CEGA: left = Loc X − minW/2 (C division) —, min height); then the text (`FUN_1000e270(…, 1)`).
/// - `FUN_1000e270` (`1000e270..1000e66c`): width pass for every alignment but LEFT —
///   `W = 0.0f; W += (float)spacing; W += (float)w` per char (two `fadds`), w = the mono char's width when
///   monospaced, measured at the format scale; start x: CENT `fctiwz(X − 0.5·W)` (`fnmsubs`), RIGH
///   `fctiwz(X − W)`, CEBU `fctiwz(((float)fctiwz(F52) − W)·0.5)`, CEGA the same with F54, unknown → logs,
///   start = X; LEFT: X. Draw pass: `cell = x + spacing`; monospaced → measure the mono char (draw flag off),
///   draw the real char, `x = cell + monoW`; else draw, `x = cell + w`. Bounds = (Y, start, Y + max h, x + 1).
/// - `FUN_1000e670` (`1000e670..1000e8c4`): measure the char at the record scale; return unless drawing;
///   **space (0x20) is never drawn** (`1000e6e0`); command from the text template `0x100e5298` (layer 7,
///   colour 0x7fff, scale 1.0, clip {0,0,480,416} after `FUN_1000f720`); clip = back-buffer bounds unless
///   +0x10d. No shadow: x = cell + w/2, y = Y + h/2 (C division), face font, frame, flags 0, alpha = blend,
///   +0x31 = +0x110, layer = +0x10c; colourise → flags 4 + colour, else blend ≠ 0 → flags 1. Shadow:
///   x/y + `fctiwz(F19/F20)`, flags 2, alpha = max(`FUN_1004d5c0(F21)`, blend) (unsigned). Scale stored only
///   when ≠ 1.0. Dead in 1.0.6 (no `tefo` sets `#DrawShadows_BOOL`) but transcribed.
/// MED (gate card): the `tesm` frame widths (plate scan, text-metrics-lists.md §1.4).
public struct TextLayout: Sendable {
    /// A glyph frame's width and height.
    public struct Size: Equatable, Sendable {
        public var width: Int32
        public var height: Int32
        public init(width: Int32, height: Int32) { self.width = width; self.height = height }
        public static let zero = Size(width: 0, height: 0)
    }

    /// The font sprite group (`*(0x100e0120)`).
    public let font: FourCC
    /// The font's frame sizes at scale 1.0 (`FUN_10019ca0`).
    public let frameSizes: [Size]
    /// `*(0x100df024)`: the per-ASCII size cache, chars 0…127 (`FUN_1000ec70`).
    public let cache: [Size]
    /// `DAT_100e0124`: the monospaced cell's char ('2').
    public let monoChar: UInt8
    /// `*(0x100df044)`: the digit max {w, h}.
    public let digitMax: Size
    /// PermFloats used by the layout: F19/F20/F21 (shadow), F52/F54 (CEBU/CEGA widths).
    let floats: [Float]

    public init(font: FourCC, frameSizes: [Size], floats: [Float]) {
        self.font = font
        self.frameSizes = frameSizes
        self.floats = floats
        func size(_ frame: Int) -> Size { frameSizes.indices.contains(frame) ? frameSizes[frame] : .zero }
        cache = (0..<128).map { size(GlyphMap.frame(UInt8($0))) }   // 1000ec70..1000ece4
        // FUN_1000d380 first call (1000d3e8..1000d474, verified): measure '1' at the constant scale 1.0
        // (`r26` = TOC−0x72f8 → 0x100d63f0 = 1.0f) → max h = h('1'); max w starts from the cached w (0 on the
        // only fill); then frames f('1') + 0…9 by `FUN_10019ca0`, each strictly wider (`cmpw; ble`) setting w and
        // the label '0' + i, each strictly taller setting h.
        let one = GlyphMap.frame(0x31)
        var maxW: Int32 = 0
        var maxH = cache[0x31].height
        var label: UInt8 = 0x31
        for i in 0..<10 {
            let s = size(one + i)
            if s.width > maxW { maxW = s.width; label = UInt8(0x30 + i) }
            if s.height > maxH { maxH = s.height }
        }
        digitMax = Size(width: maxW, height: maxH)
        monoChar = label
    }

    /// Over the shipped data: font `idli tesp` item 0, frames decoded from its sprite group.
    public init(assets: DeimosAssets) throws {
        guard let font = assets.fonts.first else {
            throw DeimosAssetsError.shortList(id: "tesp", expected: 1, actual: 0)
        }
        let g = try assets.spriteGroup(font)
        self.init(font: font, frameSizes: g.frames.map { Size(width: Int32($0.width), height: Int32($0.height)) },
                  floats: assets.floats)
    }

    /// `FUN_1000ebd0(font, c, scale, out)` — (frame, size): scale 1.0 → the cache (chars ≥ 0x80 → {0, 0},
    /// `FUN_1000ed10`); otherwise `FUN_10019ca0(font, frame, s)` = trunc(w·s), trunc(h·s).
    public func measure(_ c: UInt8, scale: Float) -> (frame: Int, size: Size) {
        let frame = GlyphMap.frame(c)
        if scale == 1 {
            return (frame, c < 0x80 ? cache[Int(c)] : .zero)
        }
        let s = frameSizes.indices.contains(frame) ? frameSizes[frame] : .zero
        return (frame, Size(width: EntityDraw.fctiwz(Float(s.width) * scale),
                            height: EntityDraw.fctiwz(Float(s.height) * scale)))
    }

    /// `FUN_1000e270 @ 1000e270(font, fmt, rectOut, draw)` — layout and (when `draw`) the glyph commands.
    /// `shadow` = the record's `+0x10f` byte (the shadow pass of `FUN_1000d380`).
    public func layout(_ t: TextRequest, draw: Bool, shadow: Bool = false) -> (bounds: MacRect, commands: [DrawCommand]) {
        let f = t.format
        guard !t.text.isEmpty else { return (MacRect(top: 0, left: 0, bottom: 0, right: 0), []) }
        let spacing = f.spaceBetweenChars                            // +0x11c
        var start = f.locX                                           // 1000e2e0
        if f.format != .left {                                       // 1000e2f0..1000e300
            var w = Float(0)                                         // 1000e30c
            for c in t.text {                                        // 1000e328..1000e398
                let m = measure(f.monospaced ? monoChar : c, scale: t.scale).size
                w = w + Float(spacing)                               // fadds
                w = w + Float(m.width)                               // fadds
            }
            switch f.format {
            case .center: start = EntityDraw.fctiwz(Float(f.locX) - Float(0.5) * w)            // 1000e3e8..1000e414
            case .right: start = EntityDraw.fctiwz(Float(f.locX) - w)                         // 1000e424..1000e44c
            case .centerInBuffer:                                                              // 1000e45c..1000e4a0
                start = EntityDraw.fctiwz((Float(EntityDraw.fctiwz(floats[52])) - w) * Float(0.5))
            case .centerInGameArea:                                                            // 1000e4b0..1000e4f4
                start = EntityDraw.fctiwz((Float(EntityDraw.fctiwz(floats[54])) - w) * Float(0.5))
            case .left: break
            }
        }
        var x = start
        var maxH: Int32 = 0
        var out: [DrawCommand] = []
        for c in t.text {                                            // 1000e598..1000e634
            let cell = x &+ spacing
            if f.monospaced {                                        // 1000e5d0..1000e60c
                let mono = measure(monoChar, scale: t.scale).size
                let (cmd, s) = glyph(c, cell: cell, t, draw: draw, shadow: shadow)
                if let cmd { out.append(cmd) }
                x = cell &+ mono.width
                maxH = max(maxH, s.height)
            } else {                                                 // 1000e5ac..1000e5c8
                let (cmd, s) = glyph(c, cell: cell, t, draw: draw, shadow: shadow)
                if let cmd { out.append(cmd) }
                x = cell &+ s.width
                maxH = max(maxH, s.height)
            }
        }
        let bounds = MacRect(top: f.locY, left: start, bottom: f.locY &+ maxH, right: x &+ 1)   // 1000e638..1000e650
        return (bounds, out)
    }

    /// `FUN_1000e670 @ 1000e670(record, out)` — one glyph (see the type's comment).
    func glyph(_ c: UInt8, cell: Int32, _ t: TextRequest, draw: Bool, shadow: Bool) -> (DrawCommand?, Size) {
        let (frame, s) = measure(c, scale: t.scale)                  // 1000e694..1000e6b0
        guard draw, c != 0x20 else { return (nil, s) }               // 1000e6b4..1000e6f0
        let f = t.format
        var cmd = DrawCommand.template                               // 0x100e5298 (runtime)
        if !t.keepTemplateClip { cmd.clip = EntityDraw.backBufferBounds }   // 1000e72c..1000e744
        let hw = s.width / 2, hh = s.height / 2                      // 1000e6c4..1000e6ec
        cmd.face = font
        cmd.frame = frame
        cmd.drawNow = t.drawNow                                      // +0x31 = +0x110
        cmd.layer = t.layer                                          // +0x30 = +0x10c
        let blend = UInt32(bitPattern: f.blendAmount)
        if !shadow {                                                 // 1000e758..1000e7d4
            cmd.x = cell &+ hw
            cmd.y = f.locY &+ hh
            cmd.flags = 0
            cmd.alpha = blend
            if f.coloriseDo {
                cmd.colour = f.coloriseColor
                cmd.flags = 4
            } else if blend != 0 {
                cmd.flags = 1
            }
        } else {                                                     // 1000e7ec..1000e898
            let a21 = EntityDraw.toUnsigned(Double(floats[21]))
            cmd.x = cell &+ (hw &+ EntityDraw.fctiwz(floats[19]))
            cmd.y = f.locY &+ (hh &+ EntityDraw.fctiwz(floats[20]))
            cmd.flags = 2
            cmd.alpha = max(blend, a21)
        }
        if t.scale != 1 { cmd.scale = t.scale }                      // 1000e7d8..1000e7e4
        return (cmd, s)
    }

    /// `FUN_1000d380 @ 1000d380(fmt, rectOut)` — draw text: the shadow pass (if `#DrawShadows`), the colour
    /// strip (if `#ColorStrip_Do`, always queued), then the text. Returns the commands in call order.
    public func draw(_ t: TextRequest) -> [DrawCommand] {
        guard !t.text.isEmpty else { return [] }                     // 1000d3b8..1000d3c0
        var out: [DrawCommand] = []
        let f = t.format
        if f.drawShadows {                                           // 1000d49c..1000d4b8
            out += layout(t, draw: true, shadow: true).commands
        }
        if f.colorStripDo {                                          // 1000d4bc..1000d694
            var cmd = DrawCommand.template
            cmd.face = FourCC("COST")!
            cmd.alpha = UInt32(bitPattern: f.colorStripBlendAmount)
            cmd.drawNow = false
            cmd.costColour = f.colorStripColor
            if !t.keepTemplateClip { cmd.clip = EntityDraw.backBufferBounds }
            cmd.layer = t.layer
            var r = layout(t, draw: false).bounds
            let h = f.colorStripHOffset, v = f.colorStripVOffset
            r.left = r.left &- h; r.right = r.right &+ h
            r.top = r.top &- v; r.bottom = r.bottom &+ v
            let minW = f.colorStripMinWidth
            if r.right &- r.left < minW {
                switch f.format {
                case .left: r.right = r.left &+ minW
                case .center, .centerInBuffer, .centerInGameArea:
                    r.left = f.locX &- minW / 2
                    r.right = r.left &+ minW
                case .right: r.left = r.right &- minW
                }
            }
            if r.bottom &- r.top < f.colorStripMinHeight { r.bottom = r.top &+ f.colorStripMinHeight }
            cmd.costRect = r
            out.append(cmd)
        }
        out += layout(t, draw: true).commands                        // 1000d69c..1000d6ac
        return out
    }
}
