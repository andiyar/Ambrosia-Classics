import Foundation
import HectorResources

/// The score bar's draw side (G_ScoreBar.cc; hud-scorebar.md §4–§5, §7): the level-start image loads of
/// `FUN_10031400` and the per-element draw `FUN_10031ae0`, as `RenderOp`s in the original's call order.
/// ★ LOCKED name (plan S2). The state is `ScoreBarState` (C4); everything here reads one record only.
///
/// Listing reads for plan C5 (`disasm-review3-all.txt`):
/// - `FUN_10031400` (`1003142c..100316d8`): back buffer ← `scor` at `D+0x3c` (`FUN_1000c320`) = {0, 416, 480,
///   576}; save buffer `D+0x70` ← `scor` at its own bounds {0, 0, 480, 160}; the whole-bar screen blit only
///   when `DAT_100e01ff` (off: the caller brackets it with `FUN_10031ad0(0)`); icons, IDs, flags (C4's
///   `ScoreBarState.levelStart`); then `FUN_10031ae0`.
/// - `FUN_10031ae0` (`10031b00..10031d4c`), per player P1 then P2, each element only when its dirty byte is
///   set, in this order: score `FUN_10031d70` (+0x128), lives symbol `FUN_10031ea0` (+0x129), lives count
///   `FUN_10032050` (+0x12a), weapons inline (+0x12b: for slot 0, 1, 2 — restore R3+k, `FUN_100327b0` only
///   when `+0x12f` and the slot face ≠ `none`, blit R3+k), shield `FUN_10032250` (+0x12c, value +0x20),
///   power `FUN_10032500` (+0x12d, value +0x24).
/// - Each element: restore = `FUN_10009fd0(D+0x70, D+0x68, local, buffer, 0)`; draw; then `FUN_10032a70`
///   when `DAT_100e01ff` = `FUN_1000bbd0(src = buffer rect, dst = local + (D+0x2c top 0, D+0x30 left 448))`.
/// - Sprite commands copy the HUD template `0x100eb228` (layer 7, colour 0x7fff, scale 1.0 — data image,
///   `FUN_10032b20` writes only x, y, clip), clip = back-buffer bounds (`FUN_1000a530(D+0x68)`), +0x31 = 1.
///   Lives symbol (`10031f44..10032000`): F112/F113 (P1) / F114/F115 (P2) via `fctiwz`; dim → flags |1,
///   alpha 16. Icon (`100327b0..10032a40`): flags 1; slot 0 F128/129 | F134/135, alpha `FUN_1004d5c0(F141)`;
///   slot 1 F130/131 | F136/137, slot 2 F132/133 | F138/139, scale F142, alpha `FUN_1004d5c0(F140)`.
///   Meter (`10032250..100324e4`): the sprite at F116/117 | F118/119 (power F122–125) — **no dim** —; then
///   v clamped (> 100.0 → 100.0, < 0.0 → 0.0); v < 100.0 → a `COST` command: alpha / colour = tefo 41
///   `sbsh` (power 42 `sbpm`) strip blend / colour, rect {top, left + fill, bottom, right} of the buffer rect,
///   `fill = fctiwz((v / 100.0f) · (float)(right − left))` (`fdivs`, `fsubs`, `fmuls`, single).
/// - Text (`10031d70..10031e60`, `10032050..10032210`): score = tefo 43 / 44, `"%0.7i"` of +0x18; count
///   n = max(+0x1c − 1, 0) capped at `fctiwz(F143)` when that is > 0, tefo 45 / 46, or 47 / 48 (red) when
///   active and n == 0, `"%i"`; dim → blend += (32 − blend) / 2 (C division), cap 32; `+0x110` = 1.
public struct ScoreBarDraw: Sendable {
    let text: TextLayout
    let formats: [TextFormat]
    let floats: [Float]

    /// `D+0x2c` top/left: the score bar on the 640×480 screen (hud-scorebar §1).
    public static let screenOrigin = (top: Int32(0), left: Int32(448))
    /// `D+0x3c`: the score bar in the back buffer.
    public static let backBarRect = MacRect(top: 0, left: 416, bottom: 480, right: 576)
    /// `D+0x70` bounds: the 160×480 save buffer.
    public static let saveBounds = MacRect(top: 0, left: 0, bottom: 480, right: 160)
    /// `'scor'`, the 160×480 `Scorebar` TGA.
    public static let image = FourCC("scor")!

    public init(text: TextLayout, formats: [TextFormat], floats: [Float]) {
        self.text = text
        self.formats = formats
        self.floats = floats
    }

    public init(assets: DeimosAssets) throws {
        self.init(text: try TextLayout(assets: assets), formats: assets.formats, floats: assets.floats)
    }

    /// `FUN_10031400`'s draw side: the two `scor` loads, then `FUN_10031ae0` with the screen blits off.
    /// `state` must already have had `ScoreBarState.levelStart` (all dirty).
    public func levelStartOps(state: ScoreBarState) -> [RenderOp] {
        [.loadImage(image: Self.image, into: .back, dst: Self.backBarRect),        // 10031444..10031488
         .loadImage(image: Self.image, into: .scoreSave, dst: Self.saveBounds)]    // 10031490..100314c4
            + drawOps(state: state, blitToScreen: false)                           // 100316d8
    }

    /// `FUN_10031ae0 @ 10031ae0` — every dirty element of P1 then P2. `blitToScreen` = `DAT_100e01ff`.
    public func drawOps(state: ScoreBarState, blitToScreen: Bool) -> [RenderOp] {
        var ops: [RenderOp] = []
        for (p, r) in state.records.prefix(2).enumerated() {
            func element(_ k: Int, _ draws: [DrawCommand]) {
                ops.append(.copy(from: .scoreSave, to: .back, src: r.localRects[k], dst: r.bufferRects[k],
                                 interlaced: false))
                ops += draws.map { .draw($0) }
                if blitToScreen { ops.append(.screenBlit(src: r.bufferRects[k], dst: Self.screenRect(r.localRects[k]))) }
            }
            if r.dirty.contains(.score) { element(0, score(p, r)) }                // 10031b04..10031b24
            if r.dirty.contains(.livesSymbol) { element(1, [livesSymbol(p, r)]) }  // 10031b28..10031b4c
            if r.dirty.contains(.livesCount) { element(2, livesCount(p, r)) }      // 10031b50..10031b70
            if r.dirty.contains(.weapons) {                                        // 10031b74..10031cec
                for slot in 0..<3 {
                    let icon = r.icons[slot]
                    let draws = (r.drawActive && icon.face != .none) ? [self.icon(p, slot: slot, icon)] : []
                    element(3 + slot, draws)
                }
            }
            if r.dirty.contains(.shield) {                                         // 10031cf0..10031d14
                element(6, meter(p, r, element: 6, value: r.shownShield, icon: r.shieldMeter, fmt: 41, flli: 116))
            }
            if r.dirty.contains(.power) {                                          // 10031d18..10031d3c
                element(7, meter(p, r, element: 7, value: r.shownPower, icon: r.powerMeter, fmt: 42, flli: 122))
            }
        }
        return ops
    }

    /// `FUN_10032a70`: local rect + (`D+0x2c`, `D+0x30`).
    static func screenRect(_ l: MacRect) -> MacRect {
        MacRect(top: l.top &+ screenOrigin.top, left: l.left &+ screenOrigin.left,
                bottom: l.bottom &+ screenOrigin.top, right: l.right &+ screenOrigin.left)
    }

    /// The HUD template `0x100eb228` with the back-buffer clip and +0x31 = 1.
    static var hudCommand: DrawCommand {
        var c = DrawCommand.template
        c.clip = EntityDraw.backBufferBounds
        c.drawNow = true
        return c
    }

    func flli(_ i: Int) -> Int32 { EntityDraw.fctiwz(floats[i]) }

    /// Dimmed text blend: `blend + (32 − blend) / 2` (C division), capped at 32.
    static func dim(_ b: Int32) -> Int32 {
        let v = b &+ (32 &- b) / 2
        return UInt32(bitPattern: v) > 32 ? 32 : v                   // cmplwi; ble
    }

    /// `FUN_10031d70` — the score.
    func score(_ p: Int, _ r: ScoreBarState.Record) -> [DrawCommand] {
        var f = formats[p == 0 ? 43 : 44]                            // 10031de0..10031dfc
        if !r.drawActive { f.blendAmount = Self.dim(f.blendAmount) } // 10031e08..10031e3c
        var t = TextRequest(format: f, text: Self.zeroPadded7(r.lastScore))   // "%0.7i"
        t.drawNow = true                                             // 10031e0c (+0x110)
        return text.draw(t)
    }

    /// `"%0.7i"`: at least 7 digits, a leading `-` for negatives (MSL printf precision).
    static func zeroPadded7(_ v: Int32) -> String {
        let m = String(v.magnitude)
        let digits = String(repeating: "0", count: max(0, 7 - m.count)) + m
        return v < 0 ? "-" + digits : digits
    }

    /// `FUN_10031ea0` — the lives symbol.
    func livesSymbol(_ p: Int, _ r: ScoreBarState.Record) -> DrawCommand {
        var c = Self.hudCommand
        c.face = r.livesSymbol.face
        c.frame = Int(r.livesSymbol.frame)
        c.x = flli(p == 0 ? 112 : 114)
        c.y = flli(p == 0 ? 113 : 115)
        if !r.drawActive {                                           // 10031fe4..10031ffc
            c.alpha = 16
            c.flags |= 1
        }
        return c
    }

    /// `FUN_10032050` — the reserve-lives count.
    func livesCount(_ p: Int, _ r: ScoreBarState.Record) -> [DrawCommand] {
        var n = r.lastLives &- 1                                     // 10032058..1003207c
        if n < 0 { n = 0 }
        let cap = flli(143)                                          // 10032080..100320a8
        if cap > 0 && n > cap { n = cap }
        let red = r.drawActive && n == 0                             // 10032148..1003215c
        var f = formats[(p == 0 ? 45 : 46) + (red ? 2 : 0)]
        if !r.drawActive { f.blendAmount = Self.dim(f.blendAmount) } // 100321b4..100321e4
        var t = TextRequest(format: f, text: String(n))              // "%i"
        t.drawNow = true                                             // 100321ec..100321f0
        return text.draw(t)
    }

    /// `FUN_100327b0` — one weapon icon.
    func icon(_ p: Int, slot: Int, _ icon: ScoreBarState.Icon) -> DrawCommand {
        var c = Self.hudCommand
        c.face = icon.face
        c.frame = Int(icon.frame)
        c.flags = 1                                                  // 10032840
        let base = (p == 0 ? 128 : 134) + 2 * slot
        c.x = flli(base)
        c.y = flli(base + 1)
        if slot == 0 {
            c.alpha = EntityDraw.toUnsigned(Double(floats[141]))     // 100328e0..100328f0
        } else {
            c.scale = floats[142]                                    // 10032974..10032980
            c.alpha = EntityDraw.toUnsigned(Double(floats[140]))     // 10032984..10032994
        }
        return c
    }

    /// `FUN_10032250` / `FUN_10032500` — a meter and its darkening `COST` rect over buffer rect `element`
    /// (6 shield, 7 power).
    func meter(_ p: Int, _ r: ScoreBarState.Record, element: Int, value: Float, icon: ScoreBarState.Icon, fmt: Int,
               flli base: Int) -> [DrawCommand] {
        var c = Self.hudCommand
        c.face = icon.face
        c.frame = Int(icon.frame)
        c.x = flli(base + (p == 0 ? 0 : 2))
        c.y = flli(base + (p == 0 ? 1 : 3))
        var out = [c]
        var v = value
        if Double(v) > 100.0 { v = 100 } else if Double(v) < 0.0 { v = 0 }   // 100323a8..100323c8
        guard Double(v) < 100.0 else { return out }                  // 100323cc..100323d4
        let b = r.bufferRects[element]
        let f = formats[fmt]
        let ratio = v / Float(100)                                   // fdivs
        let width = Float(b.right &- b.left)                         // fsubs (int → single)
        let fill = EntityDraw.fctiwz(ratio * width)                  // fmuls; fctiwz
        var cost = Self.hudCommand
        cost.face = FourCC("COST")!
        cost.alpha = UInt32(bitPattern: f.colorStripBlendAmount)     // +0x138
        cost.costColour = f.colorStripColor                          // +0x13c
        cost.costRect = MacRect(top: b.top, left: b.left &+ fill, bottom: b.bottom, right: b.right)
        out.append(cost)
        return out
    }
}
