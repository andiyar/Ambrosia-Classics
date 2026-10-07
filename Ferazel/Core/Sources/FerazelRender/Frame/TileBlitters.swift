import Foundation
import FerazelCore

/// The tile-layer blitters `.RedrawScrollGrid` reaches, each behind its `.Wrap*` ring wrapper (decompile
/// l. 10183–10230, 11449–11720; sprites-backgrounds §2.2 token stream, lighting-tables §2, §8). Every wrapper culls
/// against the scroll point first and then blits at the ring position (x mod 640, y mod 416) plus the up to three
/// wrapped copies; the replica clips each copy to the 640×416 port (the 8-px slop is not modelled).
enum TileBlitters {

    /// The view's top-left in world pixels (`PTR_DAT_1009fe78`, (v, h) shorts).
    struct Scroll: Equatable {
        var h: Int
        var v: Int
    }

    /// What one blit does to each pixel a copy run covers (skip runs leave the port alone in every blitter here).
    enum Op {
        /// `.BlitEncTileUnmasked` / `.BlitEncFaceNoClipX` / `.BlitEncTileFaceNoClipX`, mode 0: the face pixel.
        case copy
        /// `.BlitEncFaceSpecialNoClipX` with a remap table (mode 9 = water table w, lighting-tables §2.1): `t[src]`.
        case table([UInt8])
        /// `.BlitEncBoolTile @ 100230bc` / `.BlitEncBoolTileUnmasked @ 10023260`: 0x00.
        case bool
        /// `.BlitEncEraseBoolTile @ 100233c0` / `.BlitEncEraseBoolTileUnmasked @ 100246b4`: 0xFF.
        case erase
        /// `.BlitEncFaceTileBlend @ 1002a810` (mode 0x14, or 0x15+w with header `0x26c6` = 0) and, with `water`,
        /// `.BlitEncFaceTileBlendSpecial @ 1002aa00`: the face pixel is a weight; d = the port pixel, p = the plain
        /// pattern face's pixel at the same row and column; 0 → p, 1 → `0154[d·0x100 + p]`, 2 → `015c[…]`, else →
        /// `0158[…]`; BlendSpecial then remaps the result through water table w (raw `1002a8cc..1002a944`).
        case blend(pattern: [UInt8], patternWidth: Int, quarter: [UInt8], half: [UInt8], threeQuarter: [UInt8],
                   water: [UInt8]?)
    }

    /// The cull every `.Wrap*` tile wrapper applies before blitting (`.WrapDrawTile`, `.WrapDrawBoolTile`,
    /// `.WrapEraseBoolTile`, `.WrapDrawFace`): h ≤ x + w, v ≤ y + h, x ≤ h + 0x260, y ≤ v + 0x180.
    static func visible(x: Int, y: Int, width: Int, height: Int, scroll: Scroll) -> Bool {
        scroll.h <= x + width && scroll.v <= y + height && x <= scroll.h + 0x260 && y <= scroll.v + 0x180
    }

    /// The wrapper: cull, then blit at (x', y') = the ring position, again at y' − 416 when the face reaches past
    /// the ring's bottom, at x' − 640 when it reaches past its right edge, and at both.
    static func wrapDraw(_ face: EncodedFace, _ op: Op, into port: inout [UInt8], x: Int, y: Int, scroll: Scroll) {
        let w = face.width, h = face.height
        guard visible(x: x, y: y, width: w, height: h, scroll: scroll) else { return }
        let rx = FramePorts.ringX(x), ry = FramePorts.ringY(y)
        let wrapsY = ry - FramePorts.height + h > 0
        let wrapsX = rx - FramePorts.width + w > 0
        blit(face, op, into: &port, x: rx, y: ry)
        if wrapsY { blit(face, op, into: &port, x: rx, y: ry - FramePorts.height) }
        if wrapsX { blit(face, op, into: &port, x: rx - FramePorts.width, y: ry) }
        if wrapsX && wrapsY { blit(face, op, into: &port, x: rx - FramePorts.width, y: ry - FramePorts.height) }
    }

    /// One blit of `face`'s token stream at port position (x, y), clipped to the port.
    static func blit(_ face: EncodedFace, _ op: Op, into port: inout [UInt8], x: Int, y: Int) {
        let W = FramePorts.width, H = FramePorts.height
        var row = -1, col = 0
        // The stream was validated when the face was encoded (`FaceEncoder`); a bad token here is a programming error.
        try! face.walk { token in
            switch token {
            case .row:
                row += 1
                col = 0
            case .skip(let n):
                col += n
            case .copy(let bytes):
                let py = y + row
                if py >= 0 && py < H {
                    let base = py * W
                    for k in 0..<bytes.count {
                        let px = x + col + k
                        guard px >= 0 && px < W else { continue }
                        let src = bytes[k]
                        switch op {
                        case .copy:
                            port[base + px] = src
                        case .table(let t):
                            port[base + px] = t[Int(src)]
                        case .bool:
                            port[base + px] = 0
                        case .erase:
                            port[base + px] = 0xff
                        case .blend(let pattern, let pw, let quarter, let half, let threeQuarter, let water):
                            let d = Int(port[base + px])
                            let p = pattern[row * pw + col + k]
                            let out: UInt8
                            switch src {
                            case 0: out = p
                            case 1: out = quarter[d << 8 | Int(p)]
                            case 2: out = half[d << 8 | Int(p)]
                            default: out = threeQuarter[d << 8 | Int(p)]
                            }
                            port[base + px] = water.map { $0[Int(out)] } ?? out
                        }
                    }
                }
                col += bytes.count
            case .end:
                break
            }
        }
    }

    /// `.WrapRectBlitX @ 100142fc`: copy `rect` (world (top, left, bottom, right)) from `src` to `dst` at the same
    /// ring positions, when it meets the view (h ≤ right, v ≤ bottom, left ≤ h + 640, top ≤ v + 416). The rect is
    /// moved to its ring position (top mod 416, left mod 640, size kept) and copied four times — as is, shifted up
    /// 416, shifted left 640, and both — each clipped to the port (`.BlitRect32s @ 1001f904` sects with 640×416).
    static func wrapRectBlit(from src: [UInt8], to dst: inout [UInt8], top: Int, left: Int, bottom: Int, right: Int,
                             scroll: Scroll) {
        guard scroll.h <= right, scroll.v <= bottom, left <= scroll.h + FramePorts.width,
              top <= scroll.v + FramePorts.height else { return }
        let t = FramePorts.ringY(top), l = FramePorts.ringX(left)
        let b = t + (bottom - top), r = l + (right - left)
        for (dy, dx) in [(0, 0), (-FramePorts.height, 0), (0, -FramePorts.width), (-FramePorts.height, -FramePorts.width)] {
            let y0 = max(t + dy, 0), y1 = min(b + dy, FramePorts.height)
            let x0 = max(l + dx, 0), x1 = min(r + dx, FramePorts.width)
            guard y0 < y1, x0 < x1 else { continue }
            for y in y0..<y1 {
                let o = y * FramePorts.width
                dst.replaceSubrange((o + x0)..<(o + x1), with: src[(o + x0)..<(o + x1)])
            }
        }
    }
}
