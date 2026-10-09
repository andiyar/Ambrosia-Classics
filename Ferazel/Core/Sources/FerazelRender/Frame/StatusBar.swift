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
/// Phase 1 holds the start values the bar never sees change: max health and magic 0x230 (`.InitGameGlobals`), no
/// suffocation, no pickup flash, and the start inventory (slot 0 spell 0, slot 1 item 0, both count 1; l. 616–625).
/// What `StatusBarState` carries is drawn when it changes, as the originals' caches decide.
public struct StatusBar {
    public static let width = 0x280
    public static let height = 0x58
    /// The bar's top on the screen (`.UpdateStatusBar`'s rect (0, 0x188)–(0x280, 0x1e0)).
    public static let screenTop = 0x188

    /// One inventory slot (`G+0x24 + 10·i`; spells-items §1).
    struct Slot: Equatable {
        var id: Int
        var count: Int
        var spell: Bool
    }

    /// `G+0x0a`, `G+0x0c` (`.InitGameGlobals` l. 799–812).
    static let maxHealth = 0x230, maxMagic = 0x230
    /// `.InitGameGlobals` l. 616–625: 27 slots, slot 0 = spell 0, slot 1 = item 0.
    static let startInventory: [Slot] = [Slot(id: 0, count: 1, spell: true), Slot(id: 0, count: 1, spell: false)]
        + [Slot](repeating: Slot(id: -1, count: 0, spell: false), count: 25)

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
    let inventory: [Slot]

    // `.UpdateHealthMagic`'s statics `_DAT_100ab9c8` (health), `…9d0` (breath), `…9d4` (suffocation), `…9cc` (magic);
    // `.UpdateTextStats`' `…9c0` (score), `…9c4` (coins); nil before the first draw.
    var lastHealth: Int?, lastBreath: Int?, lastSuffocation: Int?, lastMagic: Int?
    var lastScore: Int?, lastCoins: Int?
    var lastSelected: Int?

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
        inventory = Self.startInventory
        port = back.pixels
        // `.InitGameGlobals` l. 852–860: the 30 inventory boxes painted black.
        for i in 0..<30 { paint(Self.box(i), 0xff) }
    }

    /// `.UpdateStatusBar(full ? 0 : 1, 0, 0)` with `state`'s values: full = the level-start call (the whole port
    /// copied, every part drawn); otherwise each part draws only when its values changed.
    public mutating func update(_ state: StatusBarState, full: Bool, screen: inout IndexedFrame) {
        if full { copyToScreen(top: 0, left: 0, bottom: Self.height, right: Self.width, screen: &screen) }
        updateHealthMagic(state, incremental: !full, screen: &screen)
        updateTextStats(state, incremental: !full, screen: &screen)
        // The binary redraws the item stat when param_1 == 0, when Next/Previous (actions 8/7) stepped the selection
        // this call (`bVar1`, its 12-frame repeat counter `*_DAT_1009fd9c` at 0; l. 4885–4918 — the step happens in
        // `.UpdateStatusBar` itself) or while the item flash `PTR_DAT_1009fda8` runs. The seam carries neither the
        // keys nor the flash (both idle in Phase 1), so a changed `selectedSlot` stands for the key step.
        if full || state.selectedSlot != lastSelected { updateItemStat(selected: state.selectedSlot, screen: &screen) }
    }

    // MARK: - `.UpdateHealthMagic`

    mutating func updateHealthMagic(_ s: StatusBarState, incremental: Bool, screen: inout IndexedFrame) {
        let health = min(s.health, Self.maxHealth), magic = min(s.magic, Self.maxMagic), suffocation = 0
        var breath = s.breath
        if incremental && health == lastHealth && magic == lastMagic && suffocation == lastSuffocation
            && breath == lastBreath { return }
        if !(health == lastHealth && breath == lastBreath && incremental) {
            if health < breath { breath = health }
            lastHealth = health; lastBreath = breath; lastSuffocation = suffocation
            let h = Self.bar(health), b = Self.bar(breath), m = Self.maxHealth >> 3
            blitHUD(top: 0, left: h, bottom: 9, right: m, x: 0xd6 + h, y: 7)          // empty
            blitHUD(top: 0x24, left: m, bottom: 0x2d, right: 0xc4, x: 0xd6 + m, y: 7)  // past max
            blitHUD(top: 9, left: 0, bottom: 0x12, right: b, x: 0xd6, y: 7)           // breath
            blitHUD(top: 0x1b, left: b, bottom: 0x24, right: h, x: 0xd6 + b, y: 7)    // health above breath
            copyToScreen(top: 7, left: 0xd4, bottom: 0x10, right: 0x19c, screen: &screen)
        }
        if magic == lastMagic && incremental { return }
        lastMagic = magic
        let m = Self.bar(magic), mm = Self.maxMagic >> 3
        blitHUD(top: 0, left: m, bottom: 9, right: 0xc4, x: m + 0x1ab - 8, y: 7)
        blitHUD(top: 0x24, left: mm, bottom: 0x2d, right: 0xc4, x: 0x1ab + mm - 8, y: 7)
        blitHUD(top: 0x12, left: 0, bottom: 0x1b, right: m, x: 0x1ab - 8, y: 7)
        copyToScreen(top: 7, left: 0x1a8 - 8, bottom: 0x10, right: 0x270 - 8, screen: &screen)
    }

    /// `v >> 3` clamped to 0 … 0xc4.
    static func bar(_ v: Int) -> Int { min(max(Int(Int16(truncatingIfNeeded: v >> 3)), 0), 0xc4) }

    // MARK: - `.UpdateTextStats`

    mutating func updateTextStats(_ s: StatusBarState, incremental: Bool, screen: inout IndexedFrame) {
        if incremental && s.score == lastScore && s.coins == lastCoins { return }
        lastScore = s.score; lastCoins = s.coins
        // SetRect(screen rect) then top/bottom − 0x188 for the port rect; PaintRect black, white text, CopyBits.
        for (rect, pen, string) in [((9, 0x19, 0x15, 0x85), (0x1b, 0x13), String(s.score)),
                                    ((9, 0x94, 0x15, 0xc0), (0x96, 0x13), String(s.coins)),
                                    ((0x24, 0x19, 0x31, 0xc0), (0x1b, 0x2e), s.levelName)] {
            paint(rect, black)
            drawString(string, x: pen.0, y: pen.1)
            copyToScreen(top: rect.0, left: rect.1, bottom: rect.2, right: rect.3, screen: &screen)
        }
    }

    /// `TextFace(1)`, `TextFont(20)`, `TextSize(12)`, `MoveTo(x, y)`, `DrawString` in white (srcOr), clipped to the port.
    mutating func drawString(_ string: String, x: Int, y: Int) {
        let g = text.rasterize(string, font: 20, size: 12, face: 1)
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

    mutating func updateItemStat(selected: Int, screen: inout IndexedFrame) {
        lastSelected = selected
        let sel = inventory[selected]
        precondition(sel.id >= 0, "UpdateItemStat: the selected slot is empty (the source rect leaves the port)")
        precondition(inventory.allSatisfy { $0.count <= 1 }, "UpdateItemStat: counts > 1 are not built (Phase 1)")
        blit(sel.spell ? spellBig : itemBig, top: 0, left: sel.id * 0x2d, bottom: 0x2f, right: sel.id * 0x2d + 0x2c,
             x: 0xd7, y: 0x1e)
        for (i, slot) in inventory.enumerated() where slot.id != -1 {
            let id = slot.id == 2 && slot.spell ? 3 : slot.id     // the `== 2 && +8` → 3 store
            let rowTop = i == selected ? 0 : 0x17
            let b = Self.box(i)
            blit(slot.spell ? spellSmall : itemSmall, top: rowTop, left: id * 0x17, bottom: rowTop + 0x17,
                 right: id * 0x17 + 0x17, x: b.1, y: b.0)
        }
        if let empty = inventory.firstIndex(where: { $0.id == -1 }) { paint(Self.box(empty), black) }
        copyToScreen(top: 0x1e, left: 0xd7, bottom: 0x4c, right: 0x10b, screen: &screen)
        copyToScreen(top: 0x1e, left: 0x108, bottom: 0x4c, right: 0x268, screen: &screen)
    }

    // MARK: - pixels

    /// `CopyBitsCT`: HUD piece rect → port at (x, y), raw (an empty rect copies nothing).
    mutating func blitHUD(top: Int, left: Int, bottom: Int, right: Int, x: Int, y: Int) {
        copy(hud, top: top, left: left, bottom: bottom, right: right, x: x, y: y) { $0 }
    }

    /// `CopyBits` icon rect → port at (x, y), translated.
    mutating func blit(_ p: ConvertedPicture, top: Int, left: Int, bottom: Int, right: Int, x: Int, y: Int) {
        let t = translate
        copy(p, top: top, left: left, bottom: bottom, right: right, x: x, y: y) { t[Int($0)] }
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
