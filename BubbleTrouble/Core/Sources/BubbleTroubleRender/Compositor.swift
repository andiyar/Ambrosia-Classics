import BubbleTroubleCore
import Foundation

/// Executes the core's `DrawOp`s on persistent offscreen buffers with QuickDraw semantics (plan Invariant 2: the
/// ops are the original's QuickDraw call sites; artefacts included). The buffers mirror the original's GWorlds
/// (`_CreateGWorlds @ 0001ec98`): `bgnd`, `comp` (640×480), `score` (640×40, `_PrepareScoreBar`'s cache),
/// `spriteWorld` (546×112: the Letters strips + the info-box background stash, `_CreateSpriteGWorld`), and
/// `screen` (the window, 640×480) which the App presents.
///
/// On OS X the original's `_PlayGame` draws its sprites straight into the window (`_SetToScreen` in force,
/// `_RestoreBgnd(0)` → `_BgndToScreen`) and only the HUD goes through comp; the ops say which buffer via `target`.
///
/// Not `Sendable`; used on the App's main actor. The buffers are value types: read `screen` to present it and drop
/// the copy before the next `apply` — holding it across frames makes the next write copy the whole buffer (COW).
public final class Compositor {
    public static let width = 640, height = 480
    /// Playfield height: `_RestoreBgndRect` clips to it, the score bar lives below it (FI §6a).
    public static let playfieldHeight = 440

    public private(set) var bgnd: RGBAImage
    public private(set) var comp: RGBAImage
    public private(set) var screen: RGBAImage
    public private(set) var score: RGBAImage
    public private(set) var spriteWorld: RGBAImage

    public let letters = LettersFont()

    private let art: ArtBank
    private let text: any TextRasterizer
    /// The step of the last `.wipe` op (`applyWipe` continues it).
    public private(set) var wipeStep: Int?

    /// `_TransSpriteToComp`'s lightening factor and offset (`_ASWPlotCIconHandle @ 000148cb`:
    /// `DOUBLE_00033fb8` = −0.5, `DOUBLE_00033fc0` = 255.0).
    static let transFactor = -0.5, transOffset = 255.0
    /// `_DrawInterfaceText`'s frame colour, `RGBForeColor(0xffff, 0x9999, 0)`.
    static let infoFrameRGB: UInt32 = 0xFF9900
    /// `gTextRect` = SetRect(0x9d, 0x1a9, 0x1e2, 0x1bd) and `gSrcTextRect` (sprite GWorld rows 92…112, same
    /// size) — `_CreateSpriteGWorld @ 0001eb37`.
    public static let textRect = QDRect(top: 0x1a9, left: 0x9d, bottom: 0x1bd, right: 0x1e2)
    public static let srcTextRect = QDRect(top: 0x5c, left: 0, bottom: 0x5c + (0x1bd - 0x1a9), right: 0x1e2 - 0x9d)

    public init(art: ArtBank, text: any TextRasterizer) {
        self.art = art
        self.text = text
        bgnd = RGBAImage(width: Self.width, height: Self.height)
        comp = RGBAImage(width: Self.width, height: Self.height)
        screen = RGBAImage(width: Self.width, height: Self.height)
        score = RGBAImage(width: Self.width, height: 40)
        spriteWorld = RGBAImage(width: 0x222, height: 0x5c + 20, fill: RGBAImage.opaqueWhite)
        loadLetters()
    }

    /// `_LoadLetters @ 0001e2ff`: erase the sprite GWorld (BackColor white), PICT 9001 at its frame (0,0),
    /// PICT 9002 offset 46 down. Their 0x0099 regions leave the space around the glyphs white.
    private func loadLetters() {
        spriteWorld = RGBAImage(width: spriteWorld.width, height: spriteWorld.height, fill: RGBAImage.opaqueWhite)
        for (id, dy) in [(9001, 0), (9002, LettersFont.highlightOffset)] {
            guard let p = try? art.pict(id) else { continue }
            Self.drawPicture(p, in: QDRect(top: Int16(dy), left: 0, bottom: Int16(dy + p.height),
                                           right: Int16(p.width)), into: &spriteWorld)
        }
    }

    // MARK: - Ops

    public func apply(_ ops: [DrawOp]) {
        for op in ops { apply(op) }
    }

    public func apply(_ op: DrawOp) {
        switch op {
        case let .drawMaze(pictID):
            drawMaze(pictID: pictID)
        case let .restoreBgnd(rect, target):
            restoreBgnd(rect, target: target)
        case let .sprite(set, frame, h, v, mode, target):
            guard let icon = art.sprite(set: set, frame: frame) else { return }
            withTarget(target) { buffer in
                switch mode {
                case .normal: Self.plotIcon(icon, h: h, v: v, into: &buffer)
                case .transparent, .ghost: Self.plotIconTranslucent(icon, h: h, v: v, into: &buffer)
                }
            }
        case let .spriteToBgnd(set, frame, h, v):
            guard let icon = art.sprite(set: set, frame: frame) else { return }
            Self.plotIcon(icon, h: h, v: v, into: &bgnd)
        case .prepareScoreBar:
            prepareScoreBar()
        case let .scoreToComp(rect):
            // `_ScoreToComp(src, dst)`: every call site passes dst in comp (y 446…476) and src = dst moved up by
            // 440 into the 640×40 score GWorld (`_DrawScore @ 00028168`, `_Multiplier_Draw`, time bonus …).
            var src = rect
            src.offset(dx: 0, dy: -Int16(Self.playfieldHeight))
            Self.copyBits(from: score, src, to: &comp, rect, transparent: false)
        case let .compToScreen(rect):
            Self.copyBits(from: comp, rect, to: &screen, rect, transparent: false)
        case let .screenToComp(rect):
            Self.copyBits(from: screen, rect, to: &comp, rect, transparent: false)
        case let .pict(id, dst, target):
            guard let p = try? art.pict(id) else { return }
            withTarget(target) { Self.drawPicture(p, in: dst, into: &$0) }
        case let .pictSlice(_, src, dst, target):
            // `_BgndToCompTransparent @ 00015028`: CopyBits bgnd → comp, mode 0x24 (transparent: source pixels
            // equal to the BackColor, white, are not copied). `id` is informational: the bgnd holds whatever the
            // preceding `.pict(…, target: .bgnd)` drew.
            let source = bgnd
            withTarget(target) { Self.copyBits(from: source, src, to: &$0, dst, transparent: true) }
        case let .string(text, h, v, highlighted, fixedPitch, target):
            let source = spriteWorld
            let placements = letters.layout(text, h: h, v: v, highlighted: highlighted, fixedPitch: fixedPitch)
            withTarget(target) { buffer in
                for p in placements { Self.copyBits(from: source, p.src, to: &buffer, p.dst, transparent: true) }
            }
        case let .infoText(string, colour):
            infoText(string, colour: colour)
        case let .darkenRect(rect, target):
            withTarget(target) { Self.blendRectTowardBlack(rect, opColor: 0x7FFF, in: &$0) }
        case let .frameRect(rect, rgb, target):
            withTarget(target) { Self.frameRect(rect, rgb: rgb, in: &$0) }
        case let .fillBlack(target):
            withTarget(target) { Self.fill(&$0, RGBAImage.opaqueBlack) }
        case let .patternOverlay(index):
            patternOverlay(index: index)
        case let .wipe(step):
            beginWipe(step: step)
        case let .fps(n):
            drawFPS(n)
        case .compToSpriteWorld, .spriteWorldToComp, .compToBgnd, .wipeOut, .fillRect:
            // C6 front-end ops (SeamTypes) — not drawn yet; R1 follow-up implements them.
            break
        }
    }

    private func withTarget(_ target: DrawTarget, _ body: (inout RGBAImage) -> Void) {
        switch target {
        case .bgnd: body(&bgnd)
        case .comp: body(&comp)
        case .screen: body(&screen)
        case .score: body(&score)
        }
    }

    // MARK: - Level start

    /// `_DrawMaze @ 00025daa`'s picture part: `_PaintBgndGWorld` / `_PaintCompGWorld` (PaintRect black over the
    /// port bounds), then `_DrawAndCentrePict(LEVL w1)` into bgnd and into comp. (The score bar and the maze-cell
    /// sprites — into comp only — are the following `.prepareScoreBar` / `.sprite` ops.)
    private func drawMaze(pictID: Int) {
        Self.fill(&bgnd, RGBAImage.opaqueBlack)
        Self.fill(&comp, RGBAImage.opaqueBlack)
        guard let p = try? art.pict(pictID) else { return }
        let dst = Self.centredRect(width: p.width, height: p.height)
        Self.drawPicture(p, in: dst, into: &bgnd)
        Self.drawPicture(p, in: dst, into: &comp)
    }

    /// `_DrawAndCentrePict @ 0000bd14`: left = (640 − w) / 2, top = (480 − h) / 2 (C truncating division).
    public static func centredRect(width w: Int, height h: Int) -> QDRect {
        let left = (Self.width - w) / 2, top = (Self.height - h) / 2
        return QDRect(top: Int16(truncatingIfNeeded: top), left: Int16(truncatingIfNeeded: left),
                      bottom: Int16(truncatingIfNeeded: top + h), right: Int16(truncatingIfNeeded: left + w))
    }

    /// `_PrepareScoreBar @ 00025c65`, in comp: PaintRect (0,440,640,480) with `OpColor 0x7fff`, `PenMode(blend)`,
    /// black; then `ForeColor(greenColor)`, `PenSize(1,2)`, MoveTo(0,440) LineTo(640,440) — rows 440 and 441
    /// green across the width; then `_CompToScore`: comp (0,440,640,480) → score (0,0,640,40).
    private func prepareScoreBar() {
        let bar = QDRect(top: 440, left: 0, bottom: 480, right: 640)
        Self.blendRectTowardBlack(bar, opColor: 0x7FFF, in: &comp)
        Self.paintRect(QDRect(top: 440, left: 0, bottom: 442, right: 641), rgb: QuickDrawColour.green, in: &comp)
        Self.copyBits(from: comp, bar, to: &score, QDRect(top: 0, left: 0, bottom: 40, right: 640), transparent: false)
    }

    // MARK: - Dirty-rect restore

    /// `_RestoreBgndRect @ 00015bb6` → `_BgndToComp`, transcribed with its clipping quirks: the rect is dropped
    /// unless right ≥ 0, left < 641, top < 441, bottom ≥ 0; then `left < 0 → left = 0` ELSE `right > 640 →
    /// right = 640`, and `top < 0 → top = 0` ELSE `bottom > 440 → bottom = 440` (so a rect straddling an edge keeps
    /// its far side unclipped, as the original did — CopyBits then clips to the GWorld); copied only when
    /// non-empty. Source and destination are the same rect; `target` .comp = `_BgndToComp`, .screen =
    /// `_BgndToScreen` (the OS X double-buffered branch at 00015cda).
    private func restoreBgnd(_ rect: QDRect, target: DrawTarget) {
        var top = Int(rect.top), left = Int(rect.left), bottom = Int(rect.bottom), right = Int(rect.right)
        guard right >= 0, left < 0x281, top < 0x1b9, bottom >= 0 else { return }
        if left < 0 { left = 0 } else if right > 0x280 { right = 0x280 }
        if top < 0 { top = 0 } else if bottom > 0x1b8 { bottom = 0x1b8 }
        guard right > left, bottom > top else { return }
        let r = QDRect(top: Int16(top), left: Int16(left), bottom: Int16(bottom), right: Int16(right))
        let source = bgnd
        withTarget(target) { Self.copyBits(from: source, r, to: &$0, r, transparent: false) }
    }

    // MARK: - Front-end pieces

    /// `_DrawInterfaceText @ 0000898d` from the `_WorldSpriteToComp` on: sprite GWorld `gSrcTextRect` → comp
    /// `gTextRect` (srcCopy); PaintRect `gTextRect` blended 0x8fff toward black; a 1-px frame in (0xffff,0x9999,0)
    /// through the rect's corner points (MoveTo/LineTo: right and bottom lines land ON right/bottom); the string in
    /// Geneva 9, centred, baseline `bottom − 7`, colour = classic constant `colour` (0x111 cyan, 0x45 yellow).
    /// The sprite GWorld stash it reads is filled by `_DrawMainMenu`'s `_CompToSpriteGWorld` (no `DrawOp` yet).
    private func infoText(_ string: String, colour: Int) {
        let r = Self.textRect
        Self.copyBits(from: spriteWorld, Self.srcTextRect, to: &comp, r, transparent: false)
        Self.blendRectTowardBlack(r, opColor: 0x8FFF, in: &comp)
        let t = Int(r.top), l = Int(r.left), b = Int(r.bottom), rt = Int(r.right)
        Self.paintRect(QDRect(top: Int16(t), left: Int16(l), bottom: Int16(t + 1), right: Int16(rt + 1)),
                       rgb: Self.infoFrameRGB, in: &comp)
        Self.paintRect(QDRect(top: Int16(t), left: Int16(rt), bottom: Int16(b + 1), right: Int16(rt + 1)),
                       rgb: Self.infoFrameRGB, in: &comp)
        Self.paintRect(QDRect(top: Int16(b), left: Int16(l), bottom: Int16(b + 1), right: Int16(rt + 1)),
                       rgb: Self.infoFrameRGB, in: &comp)
        Self.paintRect(QDRect(top: Int16(t), left: Int16(l), bottom: Int16(b + 1), right: Int16(l + 1)),
                       rgb: Self.infoFrameRGB, in: &comp)
        let rgb = QuickDrawColour.rgb(constant: colour) ?? QuickDrawColour.white
        text.rasterize(string, font: "Geneva", size: 9, rgb: rgb, into: &comp, at: (h: l, v: b - 7), centredIn: r)
    }

    /// The high-score overlay (`_CheckHighScore` path at `DC` 23608): `GetIndPattern(pat, 0, 4)`, `PenMode(patOr)`,
    /// `PaintRect` over the whole comp — black wherever the pattern bit is 1, the rest untouched. The System
    /// `PAT# 0` bits are not in the game's files (Q12): the default is the 50 % checker 0xAA/0x55 for every
    /// index, pattern-aligned to the port origin. Ben compares.
    private func patternOverlay(index: Int) {
        _ = index
        let w = comp.width, hgt = comp.height
        comp.pixels.withUnsafeMutableBufferPointer { d in
            for v in 0..<hgt {
                let bits: UInt8 = v & 1 == 0 ? 0xAA : 0x55
                let row = v * w
                for h in 0..<w where bits & (0x80 >> UInt8(h & 7)) != 0 { d[row + h] = RGBAImage.opaqueBlack }
            }
        }
    }

    /// `_DrawFPS @ 00016f72`, on the screen: PaintRect (L440 T455 R490 B471 — the game rect's left + 440…490,
    /// bottom − 25…−9) in the current ForeColor (black), MoveTo(444, 467), "FPS: " in white, then the number in
    /// red when < 30 else white. The port's font is the window's default (passed as "System" 12).
    private func drawFPS(_ n: Int) {
        Self.paintRect(QDRect(top: 455, left: 440, bottom: 471, right: 490), rgb: QuickDrawColour.black, in: &screen)
        let label = "FPS: ", number = String(n)
        text.rasterize(label, font: "System", size: 12, rgb: QuickDrawColour.white, into: &screen,
                       at: (h: 444, v: 467), centredIn: nil)
        let h = 444 + text.width(label, font: "System", size: 12)
        text.rasterize(number, font: "System", size: 12, rgb: n < 30 ? QuickDrawColour.red : QuickDrawColour.white,
                       into: &screen, at: (h: h, v: 467), centredIn: nil)
    }

    // MARK: - Wipe

    /// `_WipeScreen @ 000076d3`: the number of band advances after the initial pair — the loop adds `step` per
    /// TickCount change until the sum reaches `2·step + 240`.
    public static func wipeSteps(_ step: Int) -> Int {
        guard step > 0 else { return 0 }
        var swept = 0, n = 0
        while swept < step * 2 + 0xF0 { swept += step; n += 1 }
        return n
    }

    /// The pre-loop part of `_WipeScreen`: comp → screen over rows [0, step) and [480 − step, 480).
    private func beginWipe(step: Int) {
        wipeStep = step
        applyWipe(row: 0)
    }

    /// Band advance `row` (1…`wipeSteps(step)`; 0 = the initial pair `.wipe` already copied) of the last `.wipe`
    /// op: comp → screen over rows [row·step, row·step + step) and [480 − step − row·step, 480 − row·step). The App
    /// calls it once per tick (the original advanced whenever TickCount had moved on).
    public func applyWipe(row: Int) {
        guard let step = wipeStep else { return }
        let top = QDRect(top: Int16(truncatingIfNeeded: row * step), left: 0,
                         bottom: Int16(truncatingIfNeeded: row * step + step), right: 640)
        let bottom = QDRect(top: Int16(truncatingIfNeeded: 480 - step - row * step), left: 0,
                            bottom: Int16(truncatingIfNeeded: 480 - row * step), right: 640)
        Self.copyBits(from: comp, top, to: &screen, top, transparent: false)
        Self.copyBits(from: comp, bottom, to: &screen, bottom, transparent: false)
    }

    // MARK: - QuickDraw primitives

    /// `CopyBits` srcCopy (mode 0) or transparent (mode 0x24: a source pixel equal to the BackColor — white at
    /// every call site — is not copied). Equal-size rects copy 1:1 (srcCopy: one row move per row); different
    /// sizes stretch (nearest, as QuickDraw's srcCopy scaling). Clipped to both buffers. Every buffer the
    /// compositor owns is opaque, so srcCopy moves pixels as they are.
    static func copyBits(from src: RGBAImage, _ srcRect: QDRect, to dst: inout RGBAImage, _ dstRect: QDRect,
                         transparent: Bool) {
        let dl = Int(dstRect.left), dt = Int(dstRect.top), dw = Int(dstRect.right) - dl, dh = Int(dstRect.bottom) - dt
        let sl = Int(srcRect.left), st = Int(srcRect.top), sw = Int(srcRect.right) - sl, sh = Int(srcRect.bottom) - st
        guard dw > 0, dh > 0, sw > 0, sh > 0 else { return }
        let sWidth = src.width, sHeight = src.height, dWidth = dst.width, dHeight = dst.height
        if dw == sw && dh == sh {
            // 1:1 — clip the destination so the matching source stays inside its buffer too.
            let x0 = max(dl, 0, dl - sl), x1 = min(dl + dw, dWidth, dl - sl + sWidth)
            let y0 = max(dt, 0, dt - st), y1 = min(dt + dh, dHeight, dt - st + sHeight)
            guard x0 < x1, y0 < y1 else { return }
            let count = x1 - x0, dx = sl - dl, dy = st - dt
            src.pixels.withUnsafeBufferPointer { s in
                dst.pixels.withUnsafeMutableBufferPointer { d in
                    guard let sBase = s.baseAddress, let dBase = d.baseAddress else { return }
                    for y in y0..<y1 {
                        let from = sBase + ((y + dy) * sWidth + x0 + dx), to = dBase + (y * dWidth + x0)
                        if !transparent { to.update(from: from, count: count); continue }
                        for i in 0..<count where from[i] & 0x00FF_FFFF != 0x00FF_FFFF { to[i] = from[i] | 0xFF00_0000 }
                    }
                }
            }
            return
        }
        let x0 = max(dl, 0), x1 = min(dl + dw, dWidth), y0 = max(dt, 0), y1 = min(dt + dh, dHeight)
        guard x0 < x1, y0 < y1 else { return }
        src.pixels.withUnsafeBufferPointer { s in
            dst.pixels.withUnsafeMutableBufferPointer { d in
                for y in y0..<y1 {
                    let sy = st + (y - dt) * sh / dh
                    guard sy >= 0, sy < sHeight else { continue }
                    for x in x0..<x1 {
                        let sx = sl + (x - dl) * sw / dw
                        guard sx >= 0, sx < sWidth else { continue }
                        let p = s[sy * sWidth + sx]
                        if transparent && p & 0x00FF_FFFF == 0x00FF_FFFF { continue }
                        d[y * dWidth + x] = p | 0xFF00_0000
                    }
                }
            }
        }
    }

    /// Every pixel of `image` set to `value`, in place (no allocation).
    static func fill(_ image: inout RGBAImage, _ value: UInt32) {
        image.pixels.withUnsafeMutableBufferPointer { $0.update(repeating: value) }
    }

    /// `PlotCIcon` (`_SpriteToComp @ 00015398` / `_SpriteToBgnd @ 00015567` → `_ASWPlotCIcon @ 000147c4`, which on
    /// every OS X but 10.4 calls `PlotCIcon` itself): the icon's pixels where its mask is set, at (h, v), clipped.
    static func plotIcon(_ icon: RGBAImage, h: Int, v: Int, into dst: inout RGBAImage) {
        blit(icon, h: h, v: v, into: &dst, lighten: false)
    }

    /// `_TransSpriteToComp @ 0001566e` → `_ASWPlotCIconHandle(r, 0, 1, icon) @ 000148cb` (and, for `.ghost`,
    /// `_PlotCIconHandle(r, 0, 3, icon)`): the masked icon pixels lightened halfway to white — the binary's own
    /// arithmetic, `(int)((255 − c) · −0.5 + 255.0)` = `(255 + c) >> 1` per colour byte. On 10.5+ (the OS X the
    /// replica follows) the system transform draws every masked pixel, pure white included; only the 10.4 branch
    /// (erase-white trans GWorld + CopyBits mode 0x24) dropped white ones. Ghost (`kTransformOpen`) lightens the
    /// same way (reviewer measurement, orchestrator ruling).
    static func plotIconTranslucent(_ icon: RGBAImage, h: Int, v: Int, into dst: inout RGBAImage) {
        blit(icon, h: h, v: v, into: &dst, lighten: true)
    }

    /// Masked blit: every icon pixel with alpha ≠ 0 inside `dst` is written opaque — as is, or lightened
    /// `(255 + c) >> 1` per channel.
    private static func blit(_ icon: RGBAImage, h: Int, v: Int, into dst: inout RGBAImage, lighten: Bool) {
        let x0 = max(h, 0), x1 = min(h + icon.width, dst.width), y0 = max(v, 0), y1 = min(v + icon.height, dst.height)
        guard x0 < x1, y0 < y1 else { return }
        let iw = icon.width, dw = dst.width
        icon.pixels.withUnsafeBufferPointer { s in
            dst.pixels.withUnsafeMutableBufferPointer { d in
                for y in y0..<y1 {
                    let sRow = (y - v) * iw - h, dRow = y * dw
                    for x in x0..<x1 {
                        let p = s[sRow + x]
                        guard p >> 24 != 0 else { continue }
                        d[dRow + x] = lighten
                            ? 0xFF00_0000 | ((0xFF + (p >> 16 & 0xFF)) >> 1) << 16 | ((0xFF + (p >> 8 & 0xFF)) >> 1) << 8
                                | (0xFF + (p & 0xFF)) >> 1
                            : p | 0xFF00_0000
                    }
                }
            }
        }
    }

    /// `DrawPicture(pict, dst)`: scaled to `dst` (nearest), composited by the picture's alpha — 0xFF replaces,
    /// 0 keeps the destination (outside a 0x0099 region), in between blends by the 0x8201 matte sample.
    static func drawPicture(_ pict: RGBAImage, in dstRect: QDRect, into dst: inout RGBAImage) {
        let dl = Int(dstRect.left), dt = Int(dstRect.top), dw = Int(dstRect.right) - dl, dh = Int(dstRect.bottom) - dt
        guard dw > 0, dh > 0 else { return }
        let x0 = max(dl, 0), x1 = min(dl + dw, dst.width), y0 = max(dt, 0), y1 = min(dt + dh, dst.height)
        guard x0 < x1, y0 < y1 else { return }
        let pw = pict.width, ph = pict.height, dWidth = dst.width
        pict.pixels.withUnsafeBufferPointer { s in
            dst.pixels.withUnsafeMutableBufferPointer { d in
                for y in y0..<y1 {
                    let sy = dh == ph ? y - dt : (y - dt) * ph / dh
                    for x in x0..<x1 {
                        let sx = dw == pw ? x - dl : (x - dl) * pw / dw
                        let p = s[sy * pw + sx]
                        let a = p >> 24
                        if a == 0xFF { d[y * dWidth + x] = p; continue }
                        if a == 0 { continue }
                        let q = d[y * dWidth + x]
                        func mix(_ shift: UInt32) -> UInt32 {
                            let sc = p >> shift & 0xFF, dc = q >> shift & 0xFF
                            return (sc * a + dc * (255 - a) + 127) / 255
                        }
                        d[y * dWidth + x] = 0xFF00_0000 | mix(16) << 16 | mix(8) << 8 | mix(0)
                    }
                }
            }
        }
    }

    /// `PaintRect` in `rgb` (0xRRGGBB), clipped.
    static func paintRect(_ rect: QDRect, rgb: UInt32, in dst: inout RGBAImage) {
        let x0 = max(Int(rect.left), 0), x1 = min(Int(rect.right), dst.width)
        let y0 = max(Int(rect.top), 0), y1 = min(Int(rect.bottom), dst.height)
        guard x0 < x1, y0 < y1 else { return }
        let w = dst.width, value = 0xFF00_0000 | rgb
        dst.pixels.withUnsafeMutableBufferPointer { d in
            guard let base = d.baseAddress else { return }
            for y in y0..<y1 { (base + (y * w + x0)).update(repeating: value, count: x1 - x0) }
        }
    }

    /// The blend tables of the two `OpColor`s the game uses.
    private static let blend7FFF = (0..<256).map { QuickDrawColour.blendTowardBlack(UInt32($0), opColor: 0x7FFF) }
    private static let blend8FFF = (0..<256).map { QuickDrawColour.blendTowardBlack(UInt32($0), opColor: 0x8FFF) }

    /// `PaintRect` black with `PenMode(blend)` and an equal-component `OpColor` (`QuickDrawColour.blendTowardBlack`).
    static func blendRectTowardBlack(_ rect: QDRect, opColor: UInt32, in dst: inout RGBAImage) {
        let x0 = max(Int(rect.left), 0), x1 = min(Int(rect.right), dst.width)
        let y0 = max(Int(rect.top), 0), y1 = min(Int(rect.bottom), dst.height)
        guard x0 < x1, y0 < y1 else { return }
        let table = opColor == 0x7FFF ? blend7FFF : opColor == 0x8FFF ? blend8FFF
            : (0..<256).map { QuickDrawColour.blendTowardBlack(UInt32($0), opColor: opColor) }
        let w = dst.width
        table.withUnsafeBufferPointer { lut in
            dst.pixels.withUnsafeMutableBufferPointer { d in
                for y in y0..<y1 {
                    for i in (y * w + x0)..<(y * w + x1) {
                        let p = d[i]
                        d[i] = 0xFF00_0000 | lut[Int(p >> 16 & 0xFF)] << 16 | lut[Int(p >> 8 & 0xFF)] << 8
                            | lut[Int(p & 0xFF)]
                    }
                }
            }
        }
    }

    /// `FrameRect` with a 1×1 pen: the rect's outermost pixel ring (right/bottom exclusive).
    static func frameRect(_ rect: QDRect, rgb: UInt32, in dst: inout RGBAImage) {
        let t = rect.top, l = rect.left, b = rect.bottom, r = rect.right
        guard r > l, b > t else { return }
        paintRect(QDRect(top: t, left: l, bottom: t + 1, right: r), rgb: rgb, in: &dst)
        paintRect(QDRect(top: b - 1, left: l, bottom: b, right: r), rgb: rgb, in: &dst)
        paintRect(QDRect(top: t, left: l, bottom: b, right: l + 1), rgb: rgb, in: &dst)
        paintRect(QDRect(top: t, left: r - 1, bottom: b, right: r), rgb: rgb, in: &dst)
    }
}
