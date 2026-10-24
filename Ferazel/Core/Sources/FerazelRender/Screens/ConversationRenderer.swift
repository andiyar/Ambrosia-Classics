import Foundation
import FerazelCore

/// Draws what `ConversationRun` (C1) emits for a conversation or a sign (plan S4, C2; conversations-mcnv §6, BC20,
/// BC30) on the level's screen — the shared `ScreenSurface` of the level's `FrameRenderer`:
/// - `copyPicture`, transparent (`.DrawConvPic @ 10078ee4` + `.CopyConvToScreen @ 100797e4`, `.EraseConvNameAndText @
///   100798cc`): the conversation GWorld. `.InitConversation` (from `.InitTiles` at boot, M l. 8343 → 927, before any
///   `.SetupLevel` fills `*_DAT_1009ff8c`) makes it `NewGWorld(8, (0, 0, 387, 308), *_DAT_1009ff8c = nil, 0, 0)`
///   (M l. 65548): depth 8 with a nil ctab — the system's default 8-bit table (`systemClut`). PICT 4000 (and in a
///   level the portrait, `.DrawConvPic`) is `DrawPicture`d into it (`_DrawPicInGWorld`; 32-bit mode 64 = ditherCopy),
///   so it is converted under `systemClut`; then `CopyBits(GWorld, screen, …, 0x24)`: the white test on the GWorld
///   index (white = index 0), every other pixel by colour (`Color2Index`) into the screen CLUT (raw `10079870`).
///   PICT 4000's 18,627 pure-white pixels show the game view through. [MED: the GWorld's own inverse table and
///   ditherCopy are ROM code; the replica converts with the level's `ColorSearch` / `DitherModel` under `systemClut`.]
/// - `copyPicture`, opaque (`.DrawConvPicToScreen @ 10078f34`: `_DrawPicInRect` on the screen port): `ScreenRenderer`'s
///   — the portrait converted under the screen CLUT.
/// - `drawText(run)`: QuickDraw `DrawChar` per byte, srcOr — only glyph pixels change, to `Color2Index(run.rgb)` in the
///   screen CLUT (`ColorSearch`) — the pen advancing by `CharWidth` (`.DrawStringCharByCharOrig @ 1007912c`'s loop; the
///   name's `DrawString` in a bitmap font is the same sum). The positions are Core's: name centred in 180 px from
///   x 0x13, baseline 0x114; text from x 0x9a, first baseline 0x1d + 0xe = 43, line step 18 — all frame-local, so on
///   the screen the origin (126, 46) is added (the first text baseline is 89); the trail greys (10 − age)·4000.
/// - `restoreView` (the end's `_WrapCopyToScreen(*_DAT_100a000c, scroll, 0x10, 8, prefs+9 == 0, prefs+2 == 3, 0)`,
///   M l. 66019 / 66542 — the same arguments as `.PaintFrameWrap`'s copy): the level's frame port copied to the screen
///   at the renderer's scroll point (`PTR_DAT_1009fe78`) with the live prefs, as `FrameRenderer`'s `copyToScreen` op.
/// - `drawBlackLines` (graphics mode 3, before the restore): `FrameRenderer`'s.
/// - Every other front-end op: `ScreenRenderer`'s (the level ops refused there).
public final class ConversationRenderer {
    /// The level's renderer: its surface is the screen, its ports and scroll point the game view `restoreView` copies.
    public let frame: FrameRenderer
    /// The front-end executor on the same surface (`.level` chain: PICT 4000 and the portraits are Sprites').
    public let screen: ScreenRenderer
    /// The live prefs (graphics mode prefs+2, parallax prefs+4, plain copy prefs+9) for `restoreView`.
    public var prefs: FerazelPrefs
    public let text: any TextRasterizer

    public init(frame: FrameRenderer, text: any TextRasterizer, prefs: FerazelPrefs? = nil) {
        self.frame = frame
        self.text = text
        self.prefs = prefs ?? frame.prefs
        screen = ScreenRenderer(surface: frame.surface, resources: frame.resources, search: frame.search,
                                dither: frame.dither, text: text, chain: .level)
    }

    /// The default 8-bit system colour table (`clut` 8) — what `NewGWorld` with a nil ctab at depth 8 gets: the
    /// 6×6×6 cube over FF CC 99 66 33 00 (index = 36·r + 6·g + b) without its final black (0–214), then 10-step ramps of
    /// red (215–224), green (225–234), blue (235–244) and grey (245–254) over EE DD BB AA 88 77 55 44 22 11, then black
    /// (255). The same table as `DeimosCore.QuickDrawColor.systemCLUT8` (Inside Macintosh: Imaging With QuickDraw,
    /// the standard 8-bit colour table); built here because FerazelRender does not depend on DeimosCore. The game's
    /// clut 801 "System CLUT" holds the same 256 colours (`ConversationRenderTests`); the GWorld takes the system's.
    public static let systemClut: ColorLUT = {
        let levels: [UInt16] = [0xff, 0xcc, 0x99, 0x66, 0x33, 0x00]
        let ramp: [UInt16] = [0xee, 0xdd, 0xbb, 0xaa, 0x88, 0x77, 0x55, 0x44, 0x22, 0x11]
        var t: [(UInt16, UInt16, UInt16)] = []
        for r in levels { for g in levels { for b in levels { t.append((r, g, b)) } } }
        t.removeLast()
        t += ramp.map { ($0, 0, 0) } + ramp.map { (0, $0, 0) } + ramp.map { (0, 0, $0) } + ramp.map { ($0, $0, $0) }
        t.append((0, 0, 0))
        var b: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0xff]
        func put16(_ v: UInt16) { b.append(UInt8(v >> 8)); b.append(UInt8(v & 0xff)) }
        for (i, c) in t.enumerated() {
            put16(UInt16(i)); put16(c.0 * 0x101); put16(c.1 * 0x101); put16(c.2 * 0x101)
        }
        return try! ColorLUT(id: 8, name: "System 8-bit", data: Data(b))
    }()

    /// Executes the conversation's ops in order.
    /// - Throws: `ScreenRenderer.Refusal.levelOp` for a level op other than `drawBlackLines`; `ColorLUTError` /
    ///   `PictureSourceError` for a missing CLUT or picture; `FrameRenderer.Refusal` from `drawBlackLines`.
    public func apply(_ ops: [DrawOp]) throws {
        for op in ops {
            switch op {
            case .drawText(let run):
                drawText(run)
            case .restoreView:
                let f = frame, p = prefs
                f.parallax.copyToScreen(ports: f.ports, h: f.scroll.h, v: f.scroll.v, graphicsMode: Int(p.graphics),
                                        backdrop: p.plainCopy == 0, parallax: Int(p.parallax),
                                        screen: &f.surface.frame.pixels)
            case .drawBlackLines:
                try frame.apply(FrameOps(draws: [.drawBlackLines]))
            case .copyPicture(let id, let chain, let source, let dest, nil, true):
                let clut = Self.systemClut
                let picture = try ConvertedPicture(source: try PictureSource.load(id: id, from: frame.resources,
                                                                                  chain: chain),
                                                   clut: clut, search: frame.search, dither: frame.dither)
                screen.copyBits(picture, clut: clut, source: source, dest: dest, transparent: true)
            default:
                try screen.apply([op])
            }
        }
    }

    /// `DrawChar` per byte at the pen, advancing by `CharWidth`; srcOr in `Color2Index(run.rgb)`, clipped to the screen.
    private func drawText(_ run: TextRun) {
        let surface = frame.surface
        let index = frame.search.index(of: run.rgb, in: surface.clut)
        var pen = run.h
        for b in run.bytes {
            let g = text.rasterize(byte: b, font: run.font, size: run.size, face: run.face)
            precondition(g.bits.count == g.width * g.height, "TextRasterizer: \(g.width)×\(g.height) mask")
            for y in 0..<g.height {
                let py = run.v + g.top + y
                guard (0..<IndexedFrame.height).contains(py) else { continue }
                for x in 0..<g.width where g.bits[y * g.width + x] {
                    let px = pen + g.left + x
                    if (0..<IndexedFrame.width).contains(px) { surface.frame[px, py] = index }
                }
            }
            pen += text.charWidth(b, font: run.font, size: run.size, face: run.face)
        }
    }
}

/// The conversation's text measures from a `TextRasterizer` (plan S4 `TextLayout`, C2): Times (20) 18 plain
/// `CharWidth` per byte for Core's 214-px wrap (`ConversationRun.wrap`, `.DrawConvTextString`) and TextEdit's wrapped
/// height for the response rows (`.CalcWrappedStringInBoxHeight @ 10034ce8`, M l. 31656ff). The widths are measured
/// once into a table, so the result is `Sendable` whatever the rasterizer.
public enum TextLayout {
    /// `TextFont(0x14)`, `TextSize(0x12)`, face 0 (`.DrawConvTextString`, `.DrawConvNameString`).
    public static let font: Int16 = 0x14
    public static let size: Int16 = 0x12
    /// The response box: `SetRect(0, 0, 0xd6, 400)` (raw `10079cd8`).
    public static let boxWidth = 0xd6

    /// `ConversationText` for `ConversationRun` / `LevelRun.conversationText`.
    public static func conversationText(_ rasterizer: any TextRasterizer) -> ConversationText {
        let widths = (0...255).map { rasterizer.charWidth(UInt8($0), font: font, size: size, face: 0) }
        let info = rasterizer.fontInfo(font: font, size: size, face: 0)
        let lineHeight = info.ascent + info.descent + info.leading
        let measure: @Sendable (UInt8) -> Int = { b in widths[Int(b)] }
        return ConversationText(charWidth: measure,
                                wrappedHeight: { bytes in (lineCount(bytes, width: measure) + 1) * lineHeight })
    }

    /// `TECalText`'s `nLines` for `text` in a `boxWidth`-wide destRect: a CR (0x0d) ends a line; otherwise a line takes
    /// characters while the width up to the end of each non-space character fits, spaces hanging past the edge; on
    /// overflow it breaks after the last space (a word wider than the box alone breaks before the overflowing
    /// character, at least one per line). Empty text: 0 lines. [MED: TextEdit's line breaking is ROM code (the Roman
    /// word break); the shipped responses are short single words or phrases.]
    public static func lineCount(_ text: [UInt8], width: (UInt8) -> Int, boxWidth: Int = boxWidth) -> Int {
        var lines = 0, i = 0
        let n = text.count
        while i < n {
            lines += 1
            var w = 0, j = i
            var lastBreak: Int?
            var next = n
            while j < n {
                let c = text[j]
                if c == 0x0d {
                    next = j + 1
                    break
                }
                if c == 0x20 {
                    w += width(c)
                    j += 1
                    lastBreak = j
                    continue
                }
                if w + width(c) > boxWidth {
                    next = lastBreak ?? max(j, i + 1)
                    break
                }
                w += width(c)
                j += 1
            }
            i = next
        }
        return lines
    }
}
