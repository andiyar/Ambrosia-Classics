import Foundation
import FerazelCore

/// The Enhanced water-face draw of `.WrapDrawWaterEffects @ 10010fac` (raw `10011464..100114e4`; plan E1b): per
/// `WaterFaceDraw` (cell (col, row), FG tile t, liquid kind k), at x = col·32, y = row·32:
/// - `.WrapDrawFace(*_DAT_1009ff78 + t·0x34, *_DAT_100a000c, (y, x), _DAT_100a1580, (y, x), 32, 32, 0x60000 + k, 0)`:
///   the FG-water face t (`.LoadFGWaterTileset`, `TileSets.fgWater`) into the frame port, source point the data word
///   `100a1580` = (0, 0) (never written), through `.BlitEncFaceX` mode 6 = `.BlitEncFaceWaterRipple` with water table
///   k and its mask twin (`SpriteBlitter.blitEncFaceX`), wrapped and clipped at the scroll point as every
///   `.WrapDrawFace` (`SpriteBlitter.wrap`);
/// - `.WrapLightFace(face, port, (0, 0), (y, x), 32, 32, (y, x), 0, 1)`: the light pass with water row 1 — the
///   underwater (rippled) light / darken blitters over the whole face (`SpriteBlitter.lightFace`). The caller passes
///   no Effects test (the draw itself needs Effects 1).
public enum WaterFaceBlitter {
    /// Draws `list` in order with `sprites`' blitters (its tables, light slots and ripple phase) at scroll (h, v).
    public static func draw(_ list: [WaterFaceDraw], faces: FaceSheet, sprites: SpriteBlitter, scroll: (h: Int, v: Int),
                            ports: inout FramePorts) throws {
        for d in list {
            let t = Int(d.tile)
            guard faces.faces.indices.contains(t) else { throw FrameRenderer.Refusal.waterFaceTile(d.tile) }
            let face = faces.faces[t]
            let x = Int(Int16(truncatingIfNeeded: d.cellX << 5)), y = Int(Int16(truncatingIfNeeded: d.cellY << 5))
            let word = UInt32(bitPattern: Int32(d.waterKind) &+ 0x60000)
            try SpriteBlitter.wrap(src: (0, 0), dst: (y, x), w: 0x20, h: 0x20, h0: scroll.h, v0: scroll.v) { s, p, w, h in
                try sprites.blitEncFaceX(face, src: s, dst: p, w: w, h: h, word: word, flip: false, rotation: 0,
                                         scale: 0x100, ports: &ports)
            }
            try sprites.lightFace(face, src: (0, 0), dst: (y, x), w: 0x20, h: 0x20, x: x, y: y, flip: false, waterRow: 1,
                                  h0: scroll.h, v0: scroll.v, ports: &ports)
        }
    }
}
