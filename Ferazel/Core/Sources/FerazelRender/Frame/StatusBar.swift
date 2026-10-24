import Foundation
import FerazelCore

/// The status bar: the 640×88 status port `0x100ab9d8` and `.UpdateStatusBar @ 100095dc` (decompile l. 4842) with
/// `.UpdateHealthMagic @ 10008430` (l. 4361), `.UpdateTextStats @ 10008c6c` (l. 4594) and `.UpdateItemStat @
/// 10008f90` (l. 4674), as read in spells-items §6 "⚑ Phase-1 note (R6)":
///
/// - the port is PICT 132 converted under clut **199** (`.InitAppGlobals` l. 470–472; `.ChangeBlitPortClut` to 200
///   afterwards keeps the pixels), plus `.InitGameGlobals`' 30 black inventory boxes (l. 852–860; 0xFF here [MED]);
/// - `.CopyBitsCT @ 1000001c` (seed copied, so no colour translation) moves the HUD piece (PICT 133 under 200) into the
///   port and the port to the screen; the first CT copy gives the port the screen's seed, so the later plain
///   `CopyBits` port → screen are raw as well [MED];
/// - text and the black `PaintRect`s take their indices from the current GDevice — the screen, under the level CLUT
///   (`SetPort` does not switch devices) [MED];
/// - the item / spell icons (PICTs 700..703 under 200) are `CopyBits`'d with differing seeds, so translated:
///   `Color2Index`(RGB under 200) against the screen CLUT [MED].
///
/// HU (plan S4): everything is drawn from `StatusBarState` — G's inventory, maxima and suffocation, the flash counters
/// and the call (`StatusBarCall`): param_1 0 → the whole port copied and every part drawn; otherwise each part draws
/// only when the originals' caches say it changed; `.UpdateItemStat` as `StatusBarState.drawsItems` decides; the
/// direct `.UpdateItemStat()` / `.UpdateTextStats(0)` draw only that part. The colourised copies (`RGBForeColor(c)`
/// then an indexed `CopyBits` srcCopy with c ≠ black: the health / magic flashes, the suffocation tick, the item flash)
/// combine the pixel values as QuickDraw's colourising does on indexed pixels, `(src & fg) | (~src & bg)`, fg =
/// `Color2Index(c)` and bg = white against the screen device [MED: QuickDraw colourise]; c black is a plain copy.
public struct StatusBar {
    public static let width = 0x280
    public static let height = 0x58
    /// The bar's top on the screen (`.UpdateStatusBar`'s rect (0, 0x188)–(0x280, 0x1e0)).
    public static let screenTop = 0x188

    /// The status port `0x100ab9d8`, row-major 640×88.
    public private(set) var port: [UInt8]
    /// `0x100ab9dc`: PICT 133 (196×45) under clut 200.
    let hud: ConvertedPicture
    /// `9e0` / `9e4` / `9e8` / `9ec`: PICTs 702, 703, 700, 701 under clut 200.
    let itemBig: ConvertedPicture, itemSmall: ConvertedPicture, spellBig: ConvertedPicture, spellSmall: ConvertedPicture
    /// `Color2Index`(clut 200 entry i) against the screen CLUT (the translating `CopyBits`).
    let translate: [UInt8]
    /// `ForeColor(blackColor)` / `RGBForeColor(white)` under the screen CLUT.
    public let black: UInt8
    public let white: UInt8
    let text: any TextRasterizer
    /// The screen device's search (`Color2Index` of the colourising colours).
    let prepared: ColorSearch.Prepared

    // `.UpdateHealthMagic`'s statics `_DAT_100ab9c8` (health), `…9d0` (breath), `…9d4` (suffocation), `…9cc` (magic);
    // `.UpdateTextStats`' `…9c0` (score), `…9c4` (coins); nil before the first draw.
    var lastHealth: Int?, lastBreath: Int?, lastSuffocation: Int?, lastMagic: Int?
    var lastScore: Int?, lastCoins: Int?

    /// - Parameter screenClut: the level CLUT the screen device holds (`.SetScreenClut`).
    public init(resources: FerazelResources, screenClut: ColorLUT, search: ColorSearch,
                dither: DitherModel = .errorDiffusion, text: any TextRasterizer) throws {
        let c199 = try ColorLUT.load(id: 199, from: resources, chain: .level)
        let c200 = try ColorLUT.load(id: 200, from: resources, chain: .level)
        func picture(_ id: Int16, _ clut: ColorLUT) throws -> ConvertedPicture {
            try ConvertedPicture(source: try PictureSource.load(id: id, from: resources, chain: .frontEnd), clut: clut,
                                 search: search, dither: dither)
        }
        let back = try picture(132, c199)
        precondition(back.width == Self.width && back.height == Self.height, "PICT 132 is the 640×88 status port")
        hud = try picture(133, c200)
        itemBig = try picture(702, c200)
        itemSmall = try picture(703, c200)
        spellBig = try picture(700, c200)
        spellSmall = try picture(701, c200)
        let prepared = search.prepared(for: screenClut)
        translate = c200.entries.map { prepared.index(of: RGB16($0.red, $0.green, $0.blue)) }
        black = prepared.index(of: RGB16(0, 0, 0))
        white = prepared.index(of: RGB16(0xffff, 0xffff, 0xffff))
        self.text = text
        self.prepared = prepared
        port = back.pixels
        // `.InitGameGlobals` l. 852–860: the 30 inventory boxes painted black.
        for i in 0..<30 { paint(Self.box(i), 0xff) }
    }

    /// The op's call (`StatusBarState.call`): a direct `.UpdateTextStats(0)` or `.UpdateItemStat()` draws that part
    /// only; otherwise `.UpdateStatusBar(param_1, param_2, param_3)` (`update(_:full:screen:)`, full = param_1 0).
    public mutating func update(_ state: StatusBarState, screen: inout IndexedFrame) {
        if state.call.textOnly { return updateTextStats(state, incremental: false, screen: &screen) }
        if state.call.itemsOnly { return updateItemStat(state, screen: &screen) }
        update(state, full: !state.call.partial, screen: &screen)
    }

    /// `.UpdateStatusBar(full ? 0 : 1, …)` (M l. 4842–4921) with `state`'s values: param_1 0 copies the whole port to
    /// the screen; `.UpdateHealthMagic(param_3 ? 1 : param_1)`; `.UpdateTextStats(param_1)`; then — Core has made the
    /// key step (`state.call.stepped`) — `.UpdateItemStat` unless (not stepped ∧ param_1 ≠ 0 ∧ param_2 == 0 ∧ no item
    /// flash) (`StatusBarState.drawsItems`, with param_1 = `!full`).
    public mutating func update(_ state: StatusBarState, full: Bool, screen: inout IndexedFrame) {
        if full { copyToScreen(top: 0, left: 0, bottom: Self.height, right: Self.width, screen: &screen) }
        updateHealthMagic(state, incremental: !full || state.call.forceBars, screen: &screen)
        updateTextStats(state, incremental: !full, screen: &screen)
        var gate = state
        gate.call.partial = !full
        if gate.drawsItems { updateItemStat(state, screen: &screen) }
    }

    // MARK: - `.UpdateHealthMagic`

    /// `.UpdateHealthMagic(incremental) @ 10008430` (M l. 4361–4580). G+4 / G+0xe above their maxima are read as the
    /// maxima (the routine stores them — a G write Core does not make, reported), the breath above the health as the
    /// health. Health part: skipped when health, magic, suffocation and breath equal the caches, `incremental`, and
    /// neither flash runs (the whole routine returns), or when health and breath equal theirs, `incremental` and no
    /// health flash (M l. 4417–4424). Magic part: skipped when the magic equals its cache, `incremental`, and no magic
    /// flash (M l. 4517–4521).
    mutating func updateHealthMagic(_ s: StatusBarState, incremental: Bool, screen: inout IndexedFrame) {
        let health = min(s.health, s.maxHealth), magic = min(s.magic, s.maxMagic), suffocation = s.suffocation
        var breath = s.breath
        if health == lastHealth && magic == lastMagic && suffocation == lastSuffocation && breath == lastBreath
            && incremental && s.healthFlash < 1 && s.magicFlash < 1 { return }
        if !(health == lastHealth && breath == lastBreath && incremental && s.healthFlash < 1) {
            if health < breath { breath = health }
            lastHealth = health; lastBreath = breath; lastSuffocation = suffocation
            let h = Self.bar(health), b = Self.bar(breath), m = Int(Int16(truncatingIfNeeded: s.maxHealth) >> 3)
            blitHUD(top: 0, left: h, bottom: 9, right: m, x: 0xd6 + h, y: 7)          // empty
            blitHUD(top: 0x24, left: m, bottom: 0x2d, right: 0xc4, x: 0xd6 + m, y: 7)  // past max
            // The breath, colourised by the health flash: s = flash − 1 (≥ 0), RGB (3000 s ×3) (M l. 4465–4481).
            blitHUD(top: 9, left: 0, bottom: 0x12, right: b, x: 0xd6, y: 7,
                    fore: s.healthFlash < 1 ? nil : Self.grey(max(s.healthFlash - 1, 0) * 3000))
            // The health above the breath: with no breath left and the suffocation counting, colourised by (its
            // count mod 10)·3000 grey (M l. 4486–4505; the tick sound at 9 is Core's — not built, reported).
            let tick = breath < 1 && 0 < suffocation ? Self.grey(suffocation % 10 * 3000) : nil
            blitHUD(top: 0x1b, left: b, bottom: 0x24, right: h, x: 0xd6 + b, y: 7, fore: tick)
            copyToScreen(top: 7, left: 0xd4, bottom: 0x10, right: 0x19c, screen: &screen)
        }
        if magic == lastMagic && incremental && s.magicFlash < 1 { return }
        lastMagic = magic
        let m = Self.bar(magic), mm = Int(Int16(truncatingIfNeeded: s.maxMagic) >> 3)
        blitHUD(top: 0, left: m, bottom: 9, right: 0xc4, x: m + 0x1ab - 8, y: 7)
        blitHUD(top: 0x24, left: mm, bottom: 0x2d, right: 0xc4, x: 0x1ab + mm - 8, y: 7)
        // The magic, colourised by the magic flash (M l. 4548–4564).
        blitHUD(top: 0x12, left: 0, bottom: 0x1b, right: m, x: 0x1ab - 8, y: 7,
                fore: s.magicFlash < 1 ? nil : Self.grey(max(s.magicFlash - 1, 0) * 3000))
        copyToScreen(top: 7, left: 0x1a8 - 8, bottom: 0x10, right: 0x270 - 8, screen: &screen)
    }

    /// `v >> 3` clamped to 0 … 0xc4.
    static func bar(_ v: Int) -> Int { min(max(Int(Int16(truncatingIfNeeded: v >> 3)), 0), 0xc4) }

    /// `RGBForeColor(v, v, v)` with v the routine's 16-bit short.
    static func grey(_ v: Int) -> RGB16 {
        let c = UInt16(truncatingIfNeeded: v)
        return RGB16(c, c, c)
    }

    // MARK: - `.UpdateTextStats`

    mutating func updateTextStats(_ s: StatusBarState, incremental: Bool, screen: inout IndexedFrame) {
        if incremental && s.score == lastScore && s.coins == lastCoins { return }
        lastScore = s.score; lastCoins = s.coins
        // SetRect(screen rect) then top/bottom − 0x188 for the port rect; PaintRect black, white text, CopyBits.
        for (rect, pen, string) in [((9, 0x19, 0x15, 0x85), (0x1b, 0x13), String(s.score)),
                                    ((9, 0x94, 0x15, 0xc0), (0x96, 0x13), String(s.coins)),
                                    ((0x24, 0x19, 0x31, 0xc0), (0x1b, 0x2e), s.levelName)] {
            paint(rect, black)
            drawString(string, x: pen.0, y: pen.1, font: 20, size: 12, face: 1)
            copyToScreen(top: rect.0, left: rect.1, bottom: rect.2, right: rect.3, screen: &screen)
        }
    }

    /// `TextFace(face)`, `TextFont(font)`, `TextSize(size)`, `MoveTo(x, y)`, `DrawString` in white (srcOr), clipped to
    /// the port: `.UpdateTextStats`' bold Times (20) 12; `.UpdateItemStat`'s Geneva (3) plain 9 and bold 8.
    mutating func drawString(_ string: String, x: Int, y: Int, font: Int16, size: Int16, face: Int16) {
        let g = text.rasterize(string, font: font, size: size, face: face)
        precondition(g.bits.count == g.width * g.height, "TextRasterizer: \(g.width)×\(g.height) mask")
        for r in 0..<g.height {
            let py = y + g.top + r
            guard (0..<Self.height).contains(py) else { continue }
            for c in 0..<g.width where g.bits[r * g.width + c] {
                let px = x + g.left + c
                if (0..<Self.width).contains(px) { port[py * Self.width + px] = white }
            }
        }
    }

    // MARK: - `.UpdateItemStat`

    /// Inventory box i: (31 + 23·(i / 15), 266 + 23·(i mod 15)), 23×23 (top, left, bottom, right).
    static func box(_ i: Int) -> (Int, Int, Int, Int) {
        let top = 0x1f + 0x17 * (i / 15), left = 0x10a + 0x17 * (i % 15)
        return (top, left, top + 0x17, left + 0x17)
    }

    /// `.UpdateItemStat @ 10008f90` (M l. 4674–4841), the selection as Core's key step left it:
    /// - the selected slot's big icon (src (0, id·45)–(47, id·45 + 44) of 700 when `+8` == 1, else 702) at (0xd7,
    ///   0x1e), from the slot as read (M l. 4708–4718); its count > 1 in Geneva (font 3) plain 9 pt white — "x" (pstr
    ///   0x100a1531) at (0xf5, 0x3e), the number at (0xfb, 0x3e); from 10 on (0xf2 / 0xf8) (M l. 4719–4745);
    /// - each slot: id 2 with `+8 ≠ 0` → 3 (the G write is Core's, `StatusBarCalls`); a non-empty slot's small icon (rows
    ///   23…46, 0…23 when selected; 701 when `+8` == 1, else 703) into box i — colourised while the item flash runs
    ///   for this slot: s = flash − 1 (≥ 0), mode 0 → RGB (0x5dc s ×3), mode 1 → (3000 s, 0, 0), another mode → plain
    ///   (M l. 4767–4790) — then its count > 1 in Geneva bold 8 pt white: "x" at (left + 0xe, bottom), the number at
    ///   (left + 0x12, bottom); from 10 on (+9 / +0xc) (M l. 4791–4814);
    /// - only the **first** empty slot's box painted black (`sVar11 = 0x1b` ends the loop, M l. 4818–4830);
    /// - status x 0xd7…0x10b and 0x108…0x268, y 0x1e…0x4c → the screen (M l. 4831–4838).
    mutating func updateItemStat(_ s: StatusBarState, screen: inout IndexedFrame) {
        let inventory = s.inventory, selected = s.selectedSlot
        precondition(inventory.indices.contains(selected) && inventory[selected].id >= 0,
                     "UpdateItemStat: the selected slot is empty (the source rect leaves the port)")
        let sel = inventory[selected], selId = Int(sel.id)
        blit(sel.isSpell == 1 ? spellBig : itemBig, top: 0, left: selId * 0x2d, bottom: 0x2f,
             right: selId * 0x2d + 0x2c, x: 0xd7, y: 0x1e)
        if 1 < sel.count {
            let small = sel.count < 10
            drawString("x", x: small ? 0xf5 : 0xf2, y: 0x3e, font: 3, size: 9, face: 0)
            drawString(String(sel.count), x: small ? 0xfb : 0xf8, y: 0x3e, font: 3, size: 9, face: 0)
        }
        for (i, slot) in inventory.enumerated() {
            let id = slot.id == 2 && slot.isSpell != 0 ? 3 : Int(slot.id)
            guard id != -1 else { continue }
            let rowTop = i == selected ? 0 : 0x17
            let b = Self.box(i)
            var fore: RGB16?
            if 1 <= s.itemFlash && s.itemFlashSlot == i {
                let k = max(s.itemFlash - 1, 0)
                switch s.itemFlashMode {
                case 0: fore = Self.grey(k * 0x5dc)
                case 1: fore = RGB16(UInt16(truncatingIfNeeded: k * 3000), 0, 0)
                default: fore = nil
                }
            }
            blit(slot.isSpell == 1 ? spellSmall : itemSmall, top: rowTop, left: id * 0x17, bottom: rowTop + 0x17,
                 right: id * 0x17 + 0x17, x: b.1, y: b.0, fore: fore)
            if 1 < slot.count {
                let small = slot.count < 10
                drawString("x", x: b.1 + (small ? 0xe : 9), y: b.2, font: 3, size: 8, face: 1)
                drawString(String(slot.count), x: b.1 + (small ? 0x12 : 0xc), y: b.2, font: 3, size: 8, face: 1)
            }
        }
        if let empty = inventory.firstIndex(where: { $0.id == -1 }) { paint(Self.box(empty), black) }
        copyToScreen(top: 0x1e, left: 0xd7, bottom: 0x4c, right: 0x10b, screen: &screen)
        copyToScreen(top: 0x1e, left: 0x108, bottom: 0x4c, right: 0x268, screen: &screen)
    }

    // MARK: - pixels

    /// `CopyBitsCT`: HUD piece rect → port at (x, y), raw (an empty rect copies nothing); `fore` non-nil and not black
    /// → colourised.
    mutating func blitHUD(top: Int, left: Int, bottom: Int, right: Int, x: Int, y: Int, fore: RGB16? = nil) {
        let c = colourise(fore)
        copy(hud, top: top, left: left, bottom: bottom, right: right, x: x, y: y) { c($0) }
    }

    /// `CopyBits` icon rect → port at (x, y), translated; `fore` non-nil and not black → colourised.
    mutating func blit(_ p: ConvertedPicture, top: Int, left: Int, bottom: Int, right: Int, x: Int, y: Int,
                       fore: RGB16? = nil) {
        let t = translate, c = colourise(fore)
        copy(p, top: top, left: left, bottom: bottom, right: right, x: x, y: y) { c(t[Int($0)]) }
    }

    /// QuickDraw's colourising of an indexed srcCopy with foreground `fore` and background white: `(src & fg) | (~src &
    /// bg)` on the pixel values, fg = `Color2Index(fore)` on the screen device [MED]; black (or nil) → identity.
    func colourise(_ fore: RGB16?) -> (UInt8) -> UInt8 {
        guard let f = fore, f != RGB16(0, 0, 0) else { return { $0 } }
        let fg = prepared.index(of: f), bg = white
        return { ($0 & fg) | (~$0 & bg) }
    }

    private mutating func copy(_ p: ConvertedPicture, top: Int, left: Int, bottom: Int, right: Int, x: Int, y: Int,
                               _ map: (UInt8) -> UInt8) {
        guard bottom > top, right > left else { return }
        precondition(top >= 0 && left >= 0 && bottom <= p.height && right <= p.width,
                     "StatusBar: source rect outside PICT \(p.id)")
        for r in 0..<(bottom - top) {
            let py = y + r
            guard (0..<Self.height).contains(py) else { continue }
            for c in 0..<(right - left) {
                let px = x + c
                guard (0..<Self.width).contains(px) else { continue }
                port[py * Self.width + px] = map(p.pixels[(top + r) * p.width + left + c])
            }
        }
    }

    /// `PaintRect` (top, left, bottom, right) in the port.
    mutating func paint(_ r: (Int, Int, Int, Int), _ index: UInt8) {
        for y in max(r.0, 0)..<min(r.2, Self.height) {
            for x in max(r.1, 0)..<min(r.3, Self.width) { port[y * Self.width + x] = index }
        }
    }

    /// The port rect (top, left, bottom, right) → the screen at + (0, 392), raw.
    func copyToScreen(top: Int, left: Int, bottom: Int, right: Int, screen: inout IndexedFrame) {
        for y in top..<bottom {
            for x in left..<right { screen[x, y + Self.screenTop] = port[y * Self.width + x] }
        }
    }
}
