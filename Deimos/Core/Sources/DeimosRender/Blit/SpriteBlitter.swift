import Foundation
import DeimosCore

/// The sprite draw dispatcher `FUN_10019570` (U_Sprite.cc; blit-pixel-rules §1, sprite-geometry-draw §3.3; listing
/// `10019570…10019acc`, re-read for R2) and the per-pixel rules its 30 leaves share (blit-pixel-rules §2–§5).
///
/// The dispatcher, in listing order:
/// 1. face `none` → nothing (`10019590…1001959c`); alpha `+0x1c` == 32 → nothing (`100195a0…100195a8`);
/// 2. draw-now `+0x31` == 0 → append to the render list `FUN_1001a450` and return (`100195ac…100195bc`) — that is
///    the renderer's business (R3); `SpriteBlitter` always draws, as the flush `FUN_1001a650` does with the
///    appended copies (`FUN_1001a450` sets `+0x31` = 1);
/// 3. face `COST` (`100195c4…100195ec`): not scaled, X/Y/w/h from the `COST` rect `+0x38…+0x44`
///    (`100196e4…10019704`), no frame; otherwise the frame (`+0x00`, else looked up by face/frame — the caller
///    resolves it here) and `scaled = (scale ≠ 1.0f)` (`100195cc…10019600`, `fcmpu`); unscaled X/Y become the top-left
///    `X − w/2`, `Y − h/2` (C division, `100196c0…100196dc`);
/// 4. the port: the terrain buffer with flag 8, else the back buffer (`10019708…10019734`);
/// 5. unscaled (and `COST`) classification against the command clip (`10019754…100197a8`): inside iff
///    `X ≥ clipL && X+w < clipR && Y ≥ clipT && Y+h < clipB`; rejected iff `X+w < clipL || X ≥ clipR ||
///    Y+h < clipT || Y ≥ clipB`; else clipped. Scaled commands are never rejected here;
/// 6. `COST` → `FUN_1001ec80(port, &cmd.costRect, cmd.costColour, cmd.alpha)` (`100197ac…100197c8`, CostRect.swift);
/// 7. mode = 1 if flags & 1, 2 if & 2, 3 if & 4, else 0 (`100197cc…100197fc`);
/// 8. scaled: `FUN_1001a6f0` (unclipped) when the clip is exactly {0,0,480,416} (`0x100d6d0c`, `10019818…10019844`),
///    else `FUN_1001aa90` (clipped) — ScaledLeaves.swift; unscaled: the inside leaf or its clipped twin by mode
///    (`10019900…10019ab4`) — UnscaledLeaves.swift.
///
/// The map path is taken when the frame has an alpha map (`frame+0x12`) — the global switches `DAT_100e0172` /
/// `DAT_100e0181` are 1 for the whole 1.0.6 session (blit-pixel-rules §6), so they are not modelled.
///
/// Replica guard (not in the original): a pixel whose destination falls outside the port is not written (the
/// original would write outside the buffer or wrap through rowBytes). No shipped Phase-1 draw reaches it.
public enum SpriteBlitter {

    /// Which leaf family the dispatcher picks.
    public enum Path: Equatable, Sendable {
        case nothing
        /// `FUN_1001ec80`, the face `COST` rect.
        case cost
        /// `FUN_1001d9f0`/`db50`/`dd20`/`df00` (inside) or the twins `FUN_1001e0d0`/`e2b0`/`e4f0`/`e770` (clipped).
        case unscaled(mode: Int, clipped: Bool)
        /// `FUN_1001a6f0` (clip == game area: clamped leaves) or `FUN_1001aa90` (any other clip: per-pixel clip).
        case scaled(mode: Int, clipped: Bool)
    }

    public struct Selection: Equatable, Sendable {
        public var path: Path
        /// The port: `.terrain` with flag 8, else `.back`.
        public var target: BufferID
    }

    /// The `COST` face 'COST' (`lis r3,0x434f; addi r0,r3,0x5354`, `100195c4`).
    public static let costFace = FourCC(rawValue: 0x434f_5354)

    /// The rect `0x100d6d0c` = {0, 0, 480, 416}: the only clip that selects the unclipped scaled leaves.
    public static let gameAreaClip = MacRect(top: 0, left: 0, bottom: 480, right: 416)

    /// Mode from the flag word: bit 1 wins over 2, and 2 over 4 (`100197d4…100197fc`).
    public static func mode(flags: UInt32) -> Int {
        if flags & 1 != 0 { return 1 }
        if flags & 2 != 0 { return 2 }
        if flags & 4 != 0 { return 3 }
        return 0
    }

    /// The dispatcher's decision for `cmd` (its frame already resolved; nil for `COST` or a missing frame — the
    /// original asserts on a missing frame, `100196a8`, and the replica draws nothing).
    public static func select(_ cmd: DrawCommand, frame: SpriteFrame?) -> Selection {
        let target: BufferID = cmd.flags & 8 != 0 ? .terrain : .back
        func sel(_ p: Path) -> Selection { Selection(path: p, target: target) }
        if cmd.face == .none || cmd.alpha == 32 { return sel(.nothing) }
        if cmd.face == costFace {
            let r = cmd.costRect ?? MacRect(top: 0, left: 0, bottom: 0, right: 0)
            let c = classify(left: r.left, top: r.top, width: r.right &- r.left, height: r.bottom &- r.top, clip: cmd.clip)
            return sel(c == nil ? .nothing : .cost)
        }
        guard let f = frame else { return sel(.nothing) }
        let mode = mode(flags: cmd.flags)
        if cmd.scale != 1.0 {
            return sel(.scaled(mode: mode, clipped: cmd.clip != gameAreaClip))
        }
        let (left, top) = unscaledTopLeft(cmd, f)
        guard let clipped = classify(left: left, top: top, width: Int32(f.width), height: Int32(f.height),
                                     clip: cmd.clip) else { return sel(.nothing) }
        return sel(.unscaled(mode: mode, clipped: clipped))
    }

    /// Execute `cmd` on its port (`.terrain` with flag 8, else `.back`) inside `buffers`.
    public static func draw(_ cmd: DrawCommand, frame: SpriteFrame?, buffers: inout DisplayBuffers) {
        if cmd.flags & 8 != 0 {
            draw(cmd, frame: frame, into: &buffers.terrain)
        } else {
            draw(cmd, frame: frame, into: &buffers.back)
        }
    }

    /// Execute `cmd` on `port` (the caller has picked the port by flag 8).
    public static func draw(_ cmd: DrawCommand, frame: SpriteFrame?, into port: inout Pixmap555) {
        let s = select(cmd, frame: frame)
        let alpha = Int(cmd.alpha)
        switch s.path {
        case .nothing:
            return
        case .cost:
            CostRect.fill(&port, rect: cmd.costRect ?? MacRect(top: 0, left: 0, bottom: 0, right: 0),
                          colour: cmd.costColour, a: alpha)
        case let .unscaled(mode, clipped):
            guard let f = frame else { return }
            let (left, top) = unscaledTopLeft(cmd, f)
            UnscaledLeaves.blit(f, into: &port, left: Int(left), top: Int(top), mode: mode, alpha: alpha,
                                colour: cmd.colour, clip: clipped ? cmd.clip : nil)
        case let .scaled(mode, clipped):
            guard let f = frame else { return }
            ScaledLeaves.blit(f, into: &port, x: cmd.x, y: cmd.y, scale: cmd.scale, mode: mode, alpha: alpha,
                              colour: cmd.colour, clip: clipped ? cmd.clip : nil)
        }
    }

    /// Unscaled top-left: `X − w/2`, `Y − h/2` with C (truncating) division; w, h > 0 so it is a floor
    /// (`100196c0 rlwinm …; add; srawi`).
    static func unscaledTopLeft(_ cmd: DrawCommand, _ f: SpriteFrame) -> (Int32, Int32) {
        (cmd.x &- Int32(f.width) / 2, cmd.y &- Int32(f.height) / 2)
    }

    /// `10019754…100197a8`: nil = rejected, false = inside, true = clipped.
    static func classify(left x: Int32, top y: Int32, width w: Int32, height h: Int32, clip: MacRect) -> Bool? {
        var clipped = false
        if !(x >= clip.left && x &+ w < clip.right) {
            if x &+ w < clip.left || x >= clip.right { return nil }
            clipped = true
        }
        if !(y >= clip.top && y &+ h < clip.bottom) {
            if y &+ h < clip.top || y >= clip.bottom { return nil }
            clipped = true
        }
        return clipped
    }

    // MARK: - Per-pixel rules (blit-pixel-rules §2–§3, §5.4)

    /// `0.032f` — the TOC constant `0x100d6db4` (and its scaled-leaf copy `0x100d6d78`), bytes `3d03126f`.
    static let shadowK = Float(bitPattern: 0x3d03_126f)

    /// Mode 2's partial-alpha rule (blit-pixel-rules §3.1, `1001ddd8…1001de24`):
    /// `α = trunc(fl32(p · fl32(0.032f · p) + a))` — `fmuls`, then one `fmadds` (fused, one rounding), then
    /// `FUN_1004d5c0` (truncate to unsigned).
    public static func shadowAlpha(p: Int, a: Int) -> UInt32 {
        let fp = Float(p)
        let k = shadowK * fp
        return UInt32(Float(a).addingProduct(fp, k))
    }

    /// One map-path pixel. `p` is the map value (32 skip; the caller handles 1000), `a` the command alpha, `src`
    /// the frame pixel, `colour` the tint colour. `scaledClamp`: the scaled mode 1/3 leaves clamp `a + p` to 32
    /// and blend (`1001bc7c…1001bc88`) where the unscaled ones skip (`1001dc18 … bge`); the blend at 32 keeps the
    /// destination's 15 bits and clears bit 15, exactly as the original kernel does. Returns nil = not written.
    @inline(__always)
    static func mapPixel(mode: Int, p: Int, a: Int, src: UInt16, dst: UInt16, colour: UInt16,
                         scaledClamp: Bool) -> UInt16? {
        if p == 32 { return nil }
        switch mode {
        case 0:   // FUN_1001d9f0: p 0 copy (`1001da80 sth`), else blend α = p (`1001daa0`); no command alpha.
            return p == 0 ? src : Blend555.blend(dst, src, a: p)
        case 1:   // FUN_1001db50: p 0 → α = a (`1001dbf8`); else α = a + p, skip ≥ 32 (`1001dc18`).
            if p == 0 { return Blend555.blend(dst, src, a: a) }
            let al = a + p
            if al >= 32 { return scaledClamp ? Blend555.blend(dst, src, a: 32) : nil }
            return Blend555.blend(dst, src, a: al)
        case 2:   // FUN_1001dd20: p 0 → dst·a/32 (`1001ddc0`); else §3.1 float α, skip ≥ 32 (`1001de24`).
            if p == 0 { return Blend555.blend(dst, 0, a: a) }
            let al = shadowAlpha(p: p, a: a)
            return al >= 32 ? nil : Blend555.blend(dst, 0, a: Int(al))
        case 3:   // FUN_1001df00: colour for src; p 0 → α = a (`1001dfa8`); else α = a + p, skip ≥ 32 (`1001dfc8`).
            if p == 0 { return Blend555.blend(dst, colour, a: a) }
            let al = a + p
            if al >= 32 { return scaledClamp ? Blend555.blend(dst, colour, a: 32) : nil }
            return Blend555.blend(dst, colour, a: al)
        default:
            return nil
        }
    }

    /// One key-path pixel (no map): drawn iff `src ≠ key` (frame `+0x10`). Mode 0 copies (`1001db0c`), mode 1
    /// blends at a (`1001dccc`), mode 2 darkens `dst·a/32` (`1001deb8`), mode 3 tints at a (`1001e080`).
    @inline(__always)
    static func keyPixel(mode: Int, a: Int, src: UInt16, key: UInt16, dst: UInt16, colour: UInt16) -> UInt16? {
        if src == key { return nil }
        switch mode {
        case 0: return src
        case 1: return Blend555.blend(dst, src, a: a)
        case 2: return Blend555.blend(dst, 0, a: a)
        case 3: return Blend555.blend(dst, colour, a: a)
        default: return nil
        }
    }
}
