import Foundation
import HectorResources

/// The per-entity draw-command builders of G_GameObject.cc (sprite-geometry-draw.md §3–§6, HIGH): the draw
/// entry `FUN_10012f20`, the sprite command `FUN_10012fa0` (+ its tint and hit passes), the shadow command
/// `FUN_10013460`, visibility → alpha `FUN_10010c20`, and the player's draw `FUN_100298c0`. ★ LOCKED name
/// (plan S2). Every builder returns the commands in call order; a command with `drawNow` false is the
/// original's queue call `FUN_10018a40` (→ `FUN_1001a450`), with `drawNow` true its direct `FUN_10019570`.
///
/// Listing reads for plan C5 (`disasm-review3-all.txt`):
/// - `FUN_10012650` (`10012650..10012748`, micro-wave §3.6): +0x18 = 1, +0x19 = 1, +0x1a = 0, +0x37 = 1,
///   +0x38 = 1, +0x4c = `defa`, +0x68 = 100.0 — `GameObject`'s defaults (C4) agree store for store.
/// - The crosshair (handler +0x8c): constructed by the handler constructor `FUN_1003acc0` (`1003acd0..1003ace0`:
///   `FUN_100125d0` → `FUN_10012650`, then handler +0x120/+0x121 = 0, +0x122 = −1). `FUN_1003ade0` writes only
///   its layer (`1003ae64`, handler +0xd8 = `plui` → sprite layer 13); `FUN_1003af90` only its visibility
///   triple (`1003b148..1003b15c`); the handler tick clears its +0x38 every tick (`1003ba0c`). A scan of every
///   `st*` at handler offsets +0xa4/+0xa5/+0xa6/+0xc1/+0xc3/+0xc4/+0xc8..+0xd4 in `0x1003a800–0x1003d800` finds
///   no other store. So: layer `plui` (13), +0x18 = 1 (pans with the view), +0x19 = 1, +0x35 = 0 (queued),
///   clip {0, 0, 480, 416}, and **no shadow** once the handler has ticked [HIGH]. C4's reset-default start agrees.
/// - `FUN_1003bd00` (`1003bd0c..1003bd1c`): `FUN_10012f20(handler + 0x8c)` only when handler +0x120.
/// - `FUN_100298c0` (`100298d4..1002992c`): state 4 only — crosshair; +0x38 = 1, +0x37 = 0, entry; +0x37 = 1,
///   +0x38 = 0, entry; +0x38 = 1. The coin tally (`10029930…`) is not reached in Phase 1 (+0xd8 = 0).
/// - Constant pools: `r2−0x7248` → `0x100d67c4` doubles {0.0, 2^52+2^31, 100.0, 32.0, 1.0, 2^52};
///   `r2−0x7240` → `0x100d67a8` floats {0.0, 100.0, 1.0, −32.0, 0.03125, 32.0, 0.5};
///   `r2−0x7284` → `0x100d6444` floats {255.0, 65535.0, 100.0, 32.0, 0.0} (`FUN_10010c20`).
///
/// Not modelled (no Phase-1 caller): the terrain-stamp path (+0x36: x + 32, y + windowTop, layer 1 / shadow
/// layer 0, flags |8, clip = terrain buffer, `+0x90` = game time) — `GameObject` carries no +0x90; Phase 2.
public enum EntityDraw {
    /// `FUN_1000a530(D+0x68)`: the 640×480 back buffer's bounds {0, 0, 480, 640} (display-window-present §1).
    public static let backBufferBounds = MacRect(top: 0, left: 0, bottom: 480, right: 640)

    /// `FUN_10010c20 @ 10010c20(v)` — visibility → alpha [HIGH, `10010c2c..10010c80`]: `(float)v / 100.0f
    /// × 32.0f − 32.0f` (`fdivs`, `fmuls`, `fsubs`, single), absolute value, `FUN_1004d5c0` (double →
    /// unsigned, truncation), min 32. `v` = `fctiwz(+0x68)` at the caller.
    public static func visibilityAlpha(_ v: Int32) -> UInt32 {
        var f = Float(v) / Float(100)
        f = f * Float(32)
        f = f - Float(32)
        if f < 0 { f = -f }
        return min(32, toUnsigned(Double(f)))
    }

    /// `FUN_1004d5c0`: MSL double → unsigned int (`< 0 → 0`, `≥ 2^32 → 0xFFFFFFFF`, truncation).
    static func toUnsigned(_ d: Double) -> UInt32 {
        if !(d > 0) { return 0 }
        if d >= 4_294_967_296 { return .max }
        return UInt32(d.rounded(.towardZero))
    }

    /// `fctiwz` of a single: truncation toward zero, saturating like the PPC instruction.
    static func fctiwz(_ f: Float) -> Int32 {
        if f.isNaN { return Int32.min }
        if f >= 2_147_483_648 { return .max }
        if f <= -2_147_483_649 { return .min }
        return Int32(f.rounded(.towardZero))
    }

    /// The sprite-layer table of `FUN_10012fa0` (`100130e8..10013260`): `defa` → 7 air / 3 ground; `grou` 3,
    /// `grhi` 5, `ailo` 7, `aihi` 8, `plwe` 9, `play` 10, `plsh` 11, `plef` 12, `plui` 13, `atmo` 14, `hud ` 15;
    /// any other 4CC keeps the template's 7.
    public static func spriteLayer(_ layer: FourCC, air: Bool) -> UInt8 {
        switch layer.description {
        case "defa": return air ? 7 : 3
        case "grou": return 3
        case "grhi": return 5
        case "ailo": return 7
        case "aihi": return 8
        case "plwe": return 9
        case "play": return 10
        case "plsh": return 11
        case "plef": return 12
        case "plui": return 13
        case "atmo": return 14
        case "hud ": return 15
        default: return 7
        }
    }

    /// An empty or `none` +0x4c becomes `defa` (written back to the entity: `100130c4..100130e4`,
    /// `100135b0..100135d0`).
    static func normaliseLayer(_ e: inout GameObject) {
        if e.layer.rawValue == 0 || e.layer == .none { e.layer = FourCC("defa")! }
    }

    /// The fields both builders copy from the entity into the runtime template (`0x100e63e4`, layer 7,
    /// colour 0x7fff, scale 1.0): face/frame (+0x1c/+0x20), clip (+0x3c..+0x48), draw-now (+0x35).
    static func base(_ e: GameObject) -> DrawCommand {
        var c = DrawCommand.template
        c.face = e.face
        c.frame = Int(e.frame)
        c.clip = e.clip
        c.drawNow = e.drawNow
        return c
    }

    /// `FUN_10012fa0 @ 10012fa0(e)` — the sprite command and its tint / hit passes [HIGH]:
    /// x = `fctiwz(+0x00)` − hOffset (when +0x18; `1001305c..10013074`), y = `fctiwz(+0x04)`, scale +0x84,
    /// layer from `spriteLayer`; +0x68 ≠ 100.0 (`fcmpu` vs the double 100.0) → flags |1, alpha =
    /// `visibilityAlpha(fctiwz(+0x68))` (`100132a8..100132d8`). Main pass unless +0x54. Tint pass when
    /// +0x58 > 0.0 (`10013310..100133d0`): flags = 4, colour +0x64, alpha = |32·(g/100)·(1 − a0/32) − 32| with
    /// the listing's mixed precision. Hit pass when +0x74 (`100133d8..10013438`): flags = 4, alpha +0x78,
    /// colour +0x80.
    public static func spriteCommands(_ e: inout GameObject, hOffset: Int32) -> [DrawCommand] {
        let off = e.pansWithView ? hOffset : 0                       // 10012fe0..10012ff8
        var c = base(e)
        c.x = fctiwz(e.x) &- off                                     // 1001305c..10013074
        c.y = fctiwz(e.y)                                            // 10013078..1001308c
        c.scale = e.scale                                            // 10013090
        normaliseLayer(&e)
        c.layer = spriteLayer(e.layer, air: e.air)
        if Double(e.visibility) != 100.0 {                           // 100132a8..100132b4
            c.flags |= 1
            c.alpha = visibilityAlpha(fctiwz(e.visibility))
        }
        var out: [DrawCommand] = []
        if !e.hideSprite { out.append(c) }                           // 100132dc..10013308
        if e.tint > 0 {                                              // 10013310..1001331c (+0x58)
            let t1 = Float(32.0 * (Double(e.tint) / 100.0))          // fdiv, fmul, frsp
            let t2 = Float(c.alpha) * Float(0.03125)                 // fsubs bias, fmuls
            let t3 = Float(1.0 - Double(t2))                         // fsub, frsp
            var r = t1 * t3                                          // fmuls
            r = r - Float(32)                                        // fsubs
            if r < 0 { r = -r }
            var tc = c
            tc.alpha = toUnsigned(Double(r))
            tc.flags = 4                                             // 10013380..100133a4
            tc.colour = e.tintColour                                 // 100133a8 (+0x64)
            out.append(tc)
            c = tc
        }
        if e.glowOn {                                                // 100133d8 (+0x74)
            var hc = c
            hc.flags = 4
            hc.alpha = UInt32(bitPattern: e.glowLevel)               // 10013408 (+0x78)
            hc.colour = e.glowColour                                 // 10013410 (+0x80)
            out.append(hc)
        }
        return out
    }

    /// `FUN_10013460 @ 10013460(e)` — the shadow command [HIGH]: flags |2 (`10013518`); alpha 20, or
    /// max(20, `visibilityAlpha`) when +0x68 ≠ 100.0 (`100134f8..100135ac`). Rows by +0x4c (§5.2):
    /// `defa` air and `ailo aihi plwe play plsh plef plui atmo hud ` → layer 6, scale 0.5·s, offset
    /// `trunc(k · trunc(flli 48/49))` with k = the command scale when +0x1a else 0.5; `defa` ground and `grou`
    /// → layer 2, `grhi` → layer 4, scale s, offset `trunc(s · trunc(flli 50/51))`; any other 4CC keeps
    /// layer 7 with the +0x19 row. x = `fctiwz(e.x + dx − hOffset)`, y = `fctiwz(e.y + dy)` (`fadds`/`fsubs`
    /// single, `100137fc..10013874`).
    public static func shadowCommand(_ e: inout GameObject, hOffset: Int32, floats: [Float]) -> DrawCommand {
        let off = e.pansWithView ? hOffset : 0                       // 100134a0..100134c0
        var c = base(e)
        c.flags |= 2                                                 // 10013518
        var alpha: UInt32 = 20                                       // 100134f8
        if Double(e.visibility) != 100.0 {                           // 10013580..10013588
            alpha = max(20, visibilityAlpha(fctiwz(e.visibility)))   // 10013598..100135a8
        }
        c.alpha = alpha
        normaliseLayer(&e)
        let half = Float(0.5)                                        // r31+0x18
        func scaled(_ k: Float, _ i: Int) -> Int32 {                 // trunc(k · (float)trunc(flli i))
            fctiwz(k * Float(fctiwz(floats[i])))
        }
        let airRow: Bool
        var layer: UInt8? = nil
        switch e.layer.description {
        case "defa": airRow = e.air; layer = e.air ? 6 : 2
        case "grou": airRow = false; layer = 2
        case "grhi": airRow = false; layer = 4
        case "ailo", "aihi", "plwe", "play", "plsh", "plef", "plui", "atmo", "hud ": airRow = true; layer = 6
        default: airRow = e.air                                      // 10013950: template layer 7
        }
        let dx: Int32, dy: Int32
        if airRow {
            c.scale = half * e.scale                                 // fmuls 0.5 · +0x84
            let k = e.adjustShadowForScaling ? c.scale : half        // +0x1a
            dx = scaled(k, 48); dy = scaled(k, 49)
        } else {
            c.scale = e.scale
            dx = scaled(c.scale, 50); dy = scaled(c.scale, 51)
        }
        if let layer { c.layer = layer }
        var fx = e.x + Float(dx)                                     // fadds
        fx = fx - Float(off)                                         // fsubs
        c.x = fctiwz(fx)
        c.y = fctiwz(e.y + Float(dy))
        return c
    }

    /// `FUN_10012f20 @ 10012f20(e)` — the draw entry [HIGH, `10012f34..10012f84`]: nothing when +0x68 ≤ 0.0;
    /// shadow `FUN_10013460` when +0x38 and the SHADOWS byte (`FUN_10006220`, 1 all session in 1.0.6, §3.2);
    /// sprite `FUN_10012fa0` when +0x37. `floats` = the permanent flli (shadow offsets 48–51). `hOffset` = `FUN_100100a0` = `_DAT_100e0144` (`ScrollState.offset`).
    public static func entry(_ e: inout GameObject, hOffset: Int32, floats: [Float]) -> [DrawCommand] {
        guard e.visibility > 0 else { return [] }                    // 10012f3c..10012f48 (cror eq,lt,eq)
        var out: [DrawCommand] = []
        if e.drawShadow { out.append(shadowCommand(&e, hOffset: hOffset, floats: floats)) }   // 10012f4c..10012f6c
        if e.drawSprite { out += spriteCommands(&e, hOffset: hOffset) }                       // 10012f74..10012f84
        return out
    }

    /// `FUN_100298c0 @ 100298c0(player)` — the player's draw (micro-wave §3.9, HIGH): only in life state 4 —
    /// the crosshair (`FUN_1003bd00`: entry on handler +0x8c when +0x120), a shadow-only entry (+0x38 = 1,
    /// +0x37 = 0), a sprite-only entry (+0x37 = 1, +0x38 = 0), then +0x38 = 1.
    public static func playerOps(_ p: inout Player, hOffset: Int32, floats: [Float]) -> [RenderOp] {
        guard p.lifeState == 4 else { return [] }                    // 100298d4..100298dc
        var out: [DrawCommand] = []
        if p.handler.crosshairShown {                                // 1003bd0c
            out += entry(&p.handler.crosshair, hOffset: hOffset, floats: floats)
        }
        p.object.drawShadow = true; p.object.drawSprite = false      // 100298ec..100298fc
        out += entry(&p.object, hOffset: hOffset, floats: floats)
        p.object.drawSprite = true; p.object.drawShadow = false      // 10029908..10029918
        out += entry(&p.object, hOffset: hOffset, floats: floats)
        p.object.drawShadow = true                                   // 10029928..1002992c
        return out.map { .draw($0) }
    }
}
