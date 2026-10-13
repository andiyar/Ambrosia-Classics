import Foundation

/// `.HandleUnderWater @ 10042e30` (decompile l. 38127–38221; physics-sprites §8.6), `.IsWaterTile @ 100430c8`
/// (l. 38225–38233) and `.GetWaterTileKind @ 1004310c` (l. 38238–38242): the water branch of every tile callback (the
/// BG pass, layer 0, with `+0x140 == 0`; 21 callers — Phase 2 has the player's `.HitPlayerTileSprite` (the end pass
/// only) and the Effect class's `.HitEffectTileSprite`). Plan P4.
public enum UnderWater {
    /// `.IsWaterTile(kind)`: `199 < kind < 0xd2` on the i16 BG kind (200…209).
    @inline(__always) public static func isWaterTile(_ kind: Int) -> Bool {
        let k = Int16(truncatingIfNeeded: kind)
        return 199 < k && k < 0xd2
    }

    /// `.GetWaterTileKind(kind)`: kind − 200, stored as i16 at `+0x128` (0 water, 1 acid, 2 lava-red, 3 healing,
    /// 5 quicksand; player-states §3).
    @inline(__always) public static func waterKind(_ kind: Int) -> Int16 { Int16(truncatingIfNeeded: kind - 200) }

    /// The surface walk (l. 38158–38170): from the hit cell's row r, while the BG cell one row up
    /// (`.GetBGTile(col, r − 1)` → `.LookupBGTileKind` → `.IsWaterTile`) is liquid, r −= 1; the surface y is
    /// `(short)r · 0x20`. Reads are clamped as `.ConstrainXY` clamps (`TileGrid`), so a liquid column reaching row 0
    /// never ends — as written (no level 1/2 column does).
    public static func surfaceY(_ tiles: TileGrid, col: Int, row: Int) -> Int {
        var r = row
        while isWaterTile(tiles.bgKind(tile: tiles.bgTile(col: col, row: r - 1))) { r -= 1 }
        return Int(Int16(truncatingIfNeeded: r)) * 0x20
    }

    /// `.HandleUnderWater(s, pos)`; pos = the cell's (Y, X) as the tile callback received it:
    /// - inset = the first i16 of the face `+0xc0` (else of the last face `+0xc8`, else 0) — a face record's `+0x00` is
    ///   its frame rect (0, 0, h, w) (sprites-backgrounds-sounds §2; `EncodedFace`), so its first i16 is 0 for every
    ///   face [MED: the plan's "the face's first i16"];
    /// - `+0xc = (short)((uint)x256 >> 8)`, `+0xa = (short)((uint)y256 >> 8)`;
    /// - row = `(short)(pos >> 0x15)` (= Y >> 5), col = `(short)X >> 5`; S = `surfaceY(col, row)`;
    ///   `+0x11c = S − +0xa − inset`; `+0x128` = the hit cell's liquid kind;
    /// - entering (`+0x120 == 0`): `.Splash(s, 3)` (`splash`), then `+0x148 = S`;
    /// - `+0x11c < 1` → 1 (fully submerged);
    /// - kind 5 (quicksand; no level 1/2 cell — built as read): `+0x144 += 0xc0`, `+0xa += 1`, floor F = `+0x148 +
    ///   (+0x144 >> 8)`, `y256 += 0x100`; with b = the hot rect's bottom `+0x38`: `+0xa + b < F` or vy < 1 → (vy < 0 →
    ///   `+0x144 = min(+0x144, +0xa + b + 8 − +0x148)`, < 0 → 0, else `<< 8` — whole px against the 1/256 depth, as
    ///   written); else `+0xa = (short)F − b`, vy 0, `+0xce = 3`, `y256 = +0xa << 8`; then `+0x11c = +0x148 − +0xa −
    ///   inset`, at least 1;
    /// - `+0x19e > 0` → `.HandleFlotation(s, S)`;
    /// - `+0x140 = 1`.
    /// - Parameter splash: `.Splash(s, 3) @ 10042874` (l. 38175) — the entry splash's particles and their `FastRand`
    ///   draws (`Splash`, E1a).
    public static func handle(world w: SpriteWorld, id: Int, pos: TilePos,
                              splash: (SpriteWorld, Int) -> Void = { w, id in Splash.splash(w, id: id, mode: 3) }) {
        guard var s = w.active.record(id: id) else { return }
        let inset: Int32 = 0                                            // `**(short **)(s + 0xc0)`: frame rect top
        let row = Int(Int16(truncatingIfNeeded: pos.y) >> 5)            // `(short)((int)param_2 >> 0x15)`
        let col = Int(Int16(truncatingIfNeeded: pos.x) >> 5)            // `(short)param_2 >> 5`
        s.x = SpriteWorld.pixel(s.x256)
        s.y = SpriteWorld.pixel(s.y256)
        let surface = Int32(surfaceY(w.tiles, col: col, row: row))
        s.waterRow = surface &- Int32(Int16(truncatingIfNeeded: s.y)) &- inset
        s.waterKind = waterKind(w.tiles.bgKind(tile: w.tiles.bgTile(col: col, row: row)))
        if s.lastWater == 0 {
            // `.Splash(s, 3)` runs on the record as written so far, before the `+0x148` store.
            let before = s
            w.active.update(id: id) { $0 = before }
            splash(w, id)
            guard let after = w.active.record(id: id) else { return }
            s = after
            s.quicksandSurface = surface
        }
        if s.waterRow < 1 { s.waterRow = 1 }
        if s.waterKind == 5 {
            s.quicksandDepth &+= 0xc0
            s.y = Int(Int16(truncatingIfNeeded: s.y + 1))
            let floor = s.quicksandSurface &+ (s.quicksandDepth >> 8)
            s.y256 &+= 0x100
            let b = Int32(Int16(truncatingIfNeeded: s.hotRect.bottom))
            let y = Int32(Int16(truncatingIfNeeded: s.y))
            if y &+ b < floor || s.vy < 1 {
                if s.vy < 0 {
                    let pull = (y &+ b &+ 8) &- s.quicksandSurface
                    s.quicksandDepth = min(s.quicksandDepth, pull)
                    if s.quicksandDepth < 0 { s.quicksandDepth = 0 } else { s.quicksandDepth <<= 8 }
                }
            } else {
                s.y = Int(Int16(truncatingIfNeeded: Int(Int16(truncatingIfNeeded: floor)) - Int(b)))
                s.vy = 0
                s.groundKind = 3
                s.y256 = Int32(Int16(truncatingIfNeeded: s.y)) << 8
            }
            s.waterRow = s.quicksandSurface &- Int32(Int16(truncatingIfNeeded: s.y)) &- inset
            if s.waterRow < 1 { s.waterRow = 1 }
        }
        let out = s
        w.active.update(id: id) { $0 = out }
        if 0 < out.buoyancy { Flotation.handle(world: w, id: id, surfaceY: surface) }
        w.active.update(id: id) { $0.underwaterDone = true }
    }
}
