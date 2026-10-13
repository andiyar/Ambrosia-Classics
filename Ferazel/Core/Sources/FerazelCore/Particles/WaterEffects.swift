import Foundation

/// `.FillCachedTileArray @ 10010d30` (decompile l. 8541–8630, raw `10010d30..10010f80`) and `.WrapDrawWaterEffects @
/// 10010fac` (l. 8634–8875, raw `10010fac..100116f0`) — plan E1b. `.PaintFrameWrap` calls it every iteration, drawn or
/// not (l. 9206, after `.HandleLights`, before `.WrapDrawSprites`; outside the `param_1` block, so a skipped iteration
/// runs it too, with the parity `_DAT_1009fd30` it did not flip).
///
/// **The cache** (`_DAT_100a00f0`, 14 rows × 21 cells × 11 i32; row stride 0xe7 ints): the window's cells from the
/// origin (col `sRam100a3826`, row `sRam100a3824`); `*_DAT_100a00f4` (`PlayerState.tileCacheValid`) says it is valid.
/// `.WrapDrawWaterEffects` refills it when the origin differs from (`_DAT_1009fe74 >> 5`, `_DAT_1009fe70 >> 5`) — the
/// grid's drawn pair, arithmetic shifts — or the flag is clear (only `.DestroyCrunchTile` clears it, M l. 39072); any
/// other map write leaves the cached tiles stale, as written.
///
/// **The walk**: rows top = v / 32 … top + 13, columns left = h / 32 … left + 20 (C division — `srawi`+`addze`, raw
/// `10011028..10011034`), the cell pointer stepping from the cache base whatever the origin; a cell outside the grid
/// (col ≥ hdr `0xb280` or < 0, row ≥ `0xb282` or < 0) is skipped, its pointer still advanced. Per visible cell, in this
/// order (every `FastRand` at its call site, plan Invariant 4):
/// 1. the emitters, only when BG kind ≥ 0, the cell is liquid and prefs Effects ≤ 2:
///    - **bubbles** when (`+0x10` = 0 **or row < `_DAT_1009fe70`**) and 0 < `+0x14` < 5 (BG kinds 201…204). The second
///      test compares the cell's **row** with the drawn v in **pixels** (raw `10011150..1001115c`, `cmpw r14,r0`): it
///      holds whenever v > row, so below the very top of a level the "no liquid above" gate is open in every liquid
///      cell [the row-vs-pixel quirk, HIGH]. Chance c = 24 (Effects 1) or 18; h = cell x + 4 + R(24), v = `+0x24`;
///      depth `+0x28` > 4 → c = c / (depth − 4) (`divw`); kind 3 → vy = −300 − R(200), gravity −5; kinds 1, 2 →
///      vy = −500 − R(300), gravity −20; kind 4 → vy 0, gravity 0, no draw; then R(100) < c →
///      `NewParticle(−bgKind, gravity, (v, h), 2, 0, vy, 0, 3)`. (Its 200 → 199 → 200 swap is dead: kind 200 is liquid
///      kind 0.)
///    - **motes** when BG kind ∈ {200, 203, 205}: chance 28 (Effects 1) or 22; h = cell x + 2 + R(28), then v = cell y
///      + 2 + R(28); R(100) < chance → c = hdr `0x2714` (0 for 203); c > 0: vx = c + (R(c >> 1) − (c >> 2)); c < 0:
///      vx = c − (R(|c| >> 1) − (|c| >> 2)); shape 7, or 1 with vx 0 when c = 0 (no draw); 205: vy = R(64) + 160,
///      shape 4; `NewParticle(−(bgKind + 10), 0, (v, h), shape, vx, vy, 0, 3)`.
/// 2. the **Enhanced water face** when FG tile `+0x00` < 0x5f, the cell is liquid, the parity is set, 0 ≤ FG kind
///    `+0x04` < 0x60, Effects == 1 and hdr `0x26c6` == 0 (`100113fc..100114e4`): `.WrapDrawFace(FG-water face t
///    (`*_DAT_1009ff78`), frame port, …, mode 0x60000 + `+0x14`)` then `.WrapLightFace(…, water row 1)` — a
///    `WaterFaceDraw`, which FerazelRender blits (`WaterFaceBlitter`). No `FastRand`.
/// 3. **wind dust** when 0 ≤ overlay-1 tile `+0x1c` < 0x24 (the wind direction): s = `.GetFGOverlay2Tile` (a fresh
///    read); chance = min((s >> 1) + 20, 65); R(100) < chance → R(s), the impulse `.LookupModedImpulse((o1 + 18) mod
///    36, s·15 + R(s))`, h = cell x + R(27) + 3, then v = cell y + R(27) + 3; shape 7 (o1 < 3, > 33, 16…20), 4 (7…11,
///    25…29), else 1 — or 2 when hdr `0x26c9` ≠ 0 — stored in the frame's `local_6a`; R(100) > 50 → shape =
///    `local_6a` (`dustShape`); `NewParticle(10, 0, (v, h), shape, impulse h, impulse v, 0, 2)`. s = 0 → `FastRand(0)`
///    reseeds the stream from the clock (as written; no shipped level reaches it: wind exists only on levels 10, 20
///    and 52, none with strength 0).
public struct WaterEffects: Equatable, Sendable {

    /// One cache record (11 i32, 0x2c bytes; particles NOT RESOLVED 4, closed E1b).
    public struct Cell: Equatable, Sendable {
        /// `+0x00`: `.GetFGTile(col, row)`.
        public var fgTile: Int32 = 0
        /// `+0x04`: `.LookupFGTileKind(+0x00)`.
        public var fgKind: Int32 = 0
        /// `+0x08`: `.LookupBGTileKind(.GetBGTile(col, row))`.
        public var bgKind: Int32 = 0
        /// `+0x0c`: `.IsWaterTile(+0x08) & 0xff`.
        public var isWater: Int32 = 0
        /// `+0x10`: `.IsWaterTile` of the BG kind one row up (`+0x18`).
        public var waterAbove: Int32 = 0
        /// `+0x14`: `.GetWaterTileKind(+0x08)` = BG kind − 200 (i16).
        public var waterKind: Int32 = 0
        /// `+0x18`: the BG kind of (col, row − 1).
        public var bgKindAbove: Int32 = 0
        /// `+0x1c`: `.GetFGOverlay1Tile(col, row)`.
        public var overlay1: Int32 = 0
        /// `+0x20`: `.GetFGOverlay2Tile(col, row)` (cached; the dust re-reads the map).
        public var overlay2: Int32 = 0
        /// `+0x24`: the bubble start v = (r − 1)·32 + 0x32, r the depth walk's end row; written only when 0 < `+0x14`
        /// < 5 (else the previous fill's value stays).
        public var bubbleV: Int32 = 0
        /// `+0x28`: the depth walk's count (1 + steps); written as `+0x24`.
        public var depth: Int32 = 0

        public init() {}
    }

    /// What one walk reads besides the cache (the prefs, the parity and the level header).
    public struct Env: Equatable, Sendable {
        /// prefs `+6` (Effects).
        public var effects: Int16
        /// `*_DAT_1009fd30` (`SpriteWorld.parity`) as `.WrapDrawWaterEffects` sees it — before this iteration's flip.
        public var parity: Bool
        /// hdr `0x26c6` (`LevelHeader.submergedFaces`).
        public var submergedFaces: UInt8
        /// hdr `0x2714` (`LevelHeader.waterCurrent`).
        public var current: Int16
        /// hdr `0x26c9` (`LevelHeader.waterSurfaceEffect`): the wind-dust shape 2 instead of 1.
        public var surfaceFlag: UInt8

        public init(effects: Int16, parity: Bool, submergedFaces: UInt8, current: Int16, surfaceFlag: UInt8) {
            self.effects = effects
            self.parity = parity
            self.submergedFaces = submergedFaces
            self.current = current
            self.surfaceFlag = surfaceFlag
        }
    }

    public static let columns = 0x15
    public static let rows = 0xe

    /// `_DAT_100a00f0`, row-major (row · 21 + column).
    public internal(set) var cells = [Cell](repeating: Cell(), count: WaterEffects.columns * WaterEffects.rows)
    /// `sRam100a3826` / `sRam100a3824`: the origin of the last fill.
    public internal(set) var originCol: Int16 = 0
    public internal(set) var originRow: Int16 = 0
    /// `local_6a` (stack `0x76`) of `.WrapDrawWaterEffects`: written only by the dust's flag branch and read by its
    /// R(100) > 50 arm, so a dust cell with shape 7 or 4 before any flag-branch cell reads whatever the stack held.
    /// The port keeps it across calls (0 at a session's start) where the binary reads an uninitialised stack value
    /// [LOW; no level-1/2 cell has wind].
    public var dustShape: Int16 = 0

    public init() {}

    /// The cache and origin a previous level left (`LevelCarry`, E1b review fix); `dustShape` is a stack local, 0.
    public init(cells: [Cell], originCol: Int16, originRow: Int16) {
        self.cells = cells
        self.originCol = originCol
        self.originRow = originRow
    }

    /// `.FillCachedTileArray(col, row)`: the origin stored, `*_DAT_100a00f4 = 1`, then the 14 × 21 records. The depth
    /// walk (0 < `+0x14` < 5; raw `10010e8c..10010f3c`): r = the cell's row, n = 0, depth = 1; while the BG cell
    /// (col, **r + the window row index**) is liquid and n < 10: FG tile of (**origin col**, r) ≥ 0x50 → n = 999,
    /// r −= 1; n += 1, r += 1, depth += 1; origin row ≥ hdr `0xb282` → n = 999, r −= 2. Then `+0x24` = (r − 1)·32 +
    /// 0x32, `+0x28` = depth. (The liquid test adds the window row index to an already absolute row, and the solid test
    /// reads the origin column, as written.)
    /// - Parameters: `overlay` = (`.GetFGOverlay1Tile`, `.GetFGOverlay2Tile`) of a cell; `height` = hdr `0xb282`.
    public mutating func fill(col: Int16, row: Int16, tiles: TileGrid, overlay: (Int, Int) -> (Int, Int), height: Int,
                              valid: inout Bool) {
        originRow = row
        originCol = col
        valid = true
        func water(_ c: Int, _ r: Int) -> Bool {
            UnderWater.isWaterTile(tiles.bgKind(tile: tiles.bgTile(col: Int(Int16(truncatingIfNeeded: c)),
                                                                   row: Int(Int16(truncatingIfNeeded: r)))))
        }
        var y = Int(row)
        for ri in 0..<Self.rows {
            var x = Int(col)
            for ci in 0..<Self.columns {
                let c16 = Int(Int16(truncatingIfNeeded: x)), r16 = Int(Int16(truncatingIfNeeded: y))
                var e = Cell()
                e.fgTile = Int32(Int16(truncatingIfNeeded: tiles.fgTile(col: c16, row: r16)))
                e.fgKind = Int32(Int16(truncatingIfNeeded: tiles.fgKind(tile: Int(Int16(truncatingIfNeeded: e.fgTile)))))
                e.bgKind = Int32(Int16(truncatingIfNeeded: tiles.bgKind(tile: tiles.bgTile(col: c16, row: r16))))
                e.isWater = UnderWater.isWaterTile(Int(e.bgKind)) ? 1 : 0
                e.waterKind = Int32(UnderWater.waterKind(Int(Int16(truncatingIfNeeded: e.bgKind))))
                let above = Int(Int16(truncatingIfNeeded: y - 1))
                e.bgKindAbove = Int32(Int16(truncatingIfNeeded: tiles.bgKind(tile: tiles.bgTile(col: c16, row: above))))
                e.waterAbove = UnderWater.isWaterTile(Int(e.bgKindAbove)) ? 1 : 0
                let o = overlay(c16, r16)
                e.overlay1 = Int32(Int16(truncatingIfNeeded: o.0))
                e.overlay2 = Int32(Int16(truncatingIfNeeded: o.1))
                let i = ri * Self.columns + ci
                if 0 < e.waterKind && e.waterKind < 5 {
                    var r = y, depth: Int32 = 1, n = 0
                    while water(c16, r + ri) && n < 10 {
                        if tiles.fgTile(col: Int(col), row: Int(Int16(truncatingIfNeeded: r))) >= 0x50 {
                            n = 999
                            r -= 1
                        }
                        n += 1
                        r += 1
                        depth += 1
                        if Int(row) >= height {
                            n = 999
                            r -= 2
                        }
                    }
                    e.bubbleV = Int32(truncatingIfNeeded: (r - 1) << 5) &+ 0x32
                    e.depth = depth
                } else {
                    e.bubbleV = cells[i].bubbleV
                    e.depth = cells[i].depth
                }
                cells[i] = e
                x += 1
            }
            y += 1
        }
    }

    /// `.SetScrollLocation`'s clamp of the pair it stores in `_DAT_1009fe74` / `_DAT_1009fe70` (l. 9487–9498, i16
    /// arguments): negative → 0; `(h + 0x280) >> 5 > 0x200` → 0x3da0; `(v + 0x1a0) >> 5 > 0x200` → 16000.
    public static func drawnPair(h: Int, v: Int) -> (h: Int, v: Int) {
        var h = Int(Int16(truncatingIfNeeded: h)), v = Int(Int16(truncatingIfNeeded: v))
        if h < 0 { h = 0 }
        if v < 0 { v = 0 }
        if (h + 0x280) >> 5 > 0x200 { h = 0x3da0 }
        if (v + 0x1a0) >> 5 > 0x200 { v = 16000 }
        return (h, v)
    }

    /// `.WrapDrawWaterEffects()` at the session's scroll point (h, v) (`.SetScrollLocation` stores it as the drawn
    /// pair just before): the refill test, the walk; the particles go into `world.particles`, the draws come back.
    public mutating func run(world w: SpriteWorld, h: Int, v: Int, effects: Int16) -> [WaterFaceDraw] {
        let d = Self.drawnPair(h: h, v: v)
        let L = w.level
        if Int(originCol) != d.h >> 5 || Int(originRow) != d.v >> 5 || !w.player.tileCacheValid {
            fill(col: Int16(truncatingIfNeeded: d.h >> 5), row: Int16(truncatingIfNeeded: d.v >> 5), tiles: w.tiles,
                 overlay: { (L.overlay1(col: $0, row: $1), L.overlay2(col: $0, row: $1)) },
                 height: Int(L.header.gridHeight), valid: &w.player.tileCacheValid)
        }
        let env = Env(effects: effects, parity: w.parity, submergedFaces: L.header.submergedFaces,
                      current: L.header.waterCurrent, surfaceFlag: L.header.waterSurfaceEffect)
        return walk(scroll: d, width: Int(L.header.gridWidth), height: Int(L.header.gridHeight), env: env,
                    overlay2: { L.overlay2(col: $0, row: $1) }, rng: &w.rng, particles: &w.particles)
    }

    /// The walk over the window at drawn pair `scroll` (see the type).
    public mutating func walk(scroll: (h: Int, v: Int), width: Int, height: Int, env: Env,
                              overlay2: (Int, Int) -> Int, rng: inout FastRand,
                              particles: inout ParticlePool) -> [WaterFaceDraw] {
        // `srawi`+`addze`: C division toward zero; `SetRect` takes i16.
        let left = Int(Int16(truncatingIfNeeded: scroll.h / 32)), top = Int(Int16(truncatingIfNeeded: scroll.v / 32))
        var out: [WaterFaceDraw] = []
        for ri in 0..<Self.rows {
            let row = top + ri
            for ci in 0..<Self.columns {
                let col = left + ci
                guard col < width, col >= 0, row < height, row >= 0 else { continue }
                if let f = Self.cell(cells[ci + ri * Self.columns], col: col, row: row, scrollV: scroll.v, env: env,
                                     overlay2: { overlay2(col, row) }, rng: &rng, particles: &particles,
                                     dustShape: &dustShape) {
                    out.append(f)
                }
            }
        }
        return out
    }

    /// One visible cell of the walk (steps 1–3 of the type).
    public static func cell(_ e: Cell, col: Int, row: Int, scrollV: Int, env: Env, overlay2: () -> Int,
                            rng: inout FastRand, particles: inout ParticlePool, dustShape: inout Int16) -> WaterFaceDraw? {
        let x = Int(Int16(truncatingIfNeeded: col << 5)), y = Int(Int16(truncatingIfNeeded: row << 5))
        let bg = Int(Int16(truncatingIfNeeded: e.bgKind))
        let kind = Int(e.waterKind)
        if bg >= 0 && e.isWater != 0 && env.effects <= 2 {
            if (e.waterAbove == 0 || row < scrollV) && 0 < kind && kind < 5 {
                bubble(e, x: x, bg: bg, kind: kind, effects: env.effects, rng: &rng, particles: &particles)
            }
            if bg == 200 || bg == 203 || bg == 205 {
                mote(bg: bg, x: x, y: y, effects: env.effects, current: env.current, rng: &rng, particles: &particles)
            }
        }
        var face: WaterFaceDraw?
        let tile = Int(Int16(truncatingIfNeeded: e.fgTile)), fgKind = Int(Int16(truncatingIfNeeded: e.fgKind))
        if tile < 0x5f && e.isWater != 0 && env.parity && fgKind >= 0 && fgKind < 0x60 && env.effects == 1
            && env.submergedFaces == 0 {
            face = WaterFaceDraw(cellX: col, cellY: row, tile: Int16(tile), waterKind: Int16(truncatingIfNeeded: kind))
        }
        let o1 = Int(e.overlay1)
        if o1 > -1 && o1 < 0x24 {
            dust(o1: o1, s: Int(Int16(truncatingIfNeeded: overlay2())), x: x, y: y, surfaceFlag: env.surfaceFlag,
                 rng: &rng, particles: &particles, dustShape: &dustShape)
        }
        return face
    }

    /// The bubble emitter (raw `10011170..1001126c`).
    static func bubble(_ e: Cell, x: Int, bg: Int, kind: Int, effects: Int16, rng: inout FastRand,
                       particles: inout ParticlePool) {
        let depth = Int(Int16(truncatingIfNeeded: e.depth))
        var chance = effects == 1 ? 0x18 : 0x12
        let h = x + 4 + Int(rng.next(0x18))
        let v = Int(Int16(truncatingIfNeeded: e.bubbleV))
        if depth > 4 { chance = Int(Int16(truncatingIfNeeded: chance / (depth - 4))) }
        var gravity = 0, vy = 0
        // `kind == 0` is dead: the caller's guard (`0 < kind < 5`, in `cell`) lets only 1…4 in — kept as decompiled.
        if kind == 3 || kind == 0 {
            vy = -300 - Int(rng.next(200))
            gravity = -5
        } else if kind > 0 && kind < 3 {
            vy = -500 - Int(rng.next(300))
            gravity = -20
        }
        if Int(rng.next(100)) < chance {
            particles.newParticle(kind: -bg, gravity: gravity, v: v, h: h, shape: 2, vx: 0, vy: vy, delay: 0, mode: 3)
        }
    }

    /// The current mote emitter (raw `10011270..100113f4`).
    static func mote(bg: Int, x: Int, y: Int, effects: Int16, current: Int16, rng: inout FastRand,
                     particles: inout ParticlePool) {
        let chance = effects == 1 ? 0x1c : 0x16
        let h = x + 2 + Int(rng.next(0x1c))
        let v = Int(Int16(truncatingIfNeeded: y + 2 + Int(rng.next(0x1c))))
        guard Int(rng.next(100)) < chance else { return }
        var vy = 0, shape = 7
        let c = bg == 203 ? 0 : Int(current)
        var vx = c
        if c > 0 {
            vx = c + (Int(rng.next(Int16(truncatingIfNeeded: c >> 1))) - (c >> 2))
        } else if c < 0 {
            let a = -c
            vx = c - (Int(rng.next(Int16(truncatingIfNeeded: a >> 1))) - (a >> 2))
        } else {
            shape = 1
        }
        if bg == 205 {
            vy = Int(rng.next(0x40)) + 0xa0
            shape = 4
        }
        particles.newParticle(kind: -(bg + 10), gravity: 0, v: v, h: h, shape: shape, vx: vx, vy: vy, delay: 0, mode: 3)
    }

    /// The wind-dust emitter (raw `100114ec..10011680`); `s` = the fresh overlay-2 tile (i16).
    static func dust(o1: Int, s: Int, x: Int, y: Int, surfaceFlag: UInt8, rng: inout FastRand,
                     particles: inout ParticlePool, dustShape: inout Int16) {
        var chance = (s >> 1) + 0x14
        if chance >= 0x41 { chance = 0x41 }
        guard Int(rng.next(100)) < chance else { return }
        // s = 0: `FastRand(0)` reseeds from the clock and returns the caller's r30 — here the cell pointer (raw
        // `10011144`); the port returns 0. Unreachable on every shipped level (wind only on levels 10, 20 and 52, none
        // with strength 0).
        let r = Int(rng.next(Int16(truncatingIfNeeded: s)))
        let a = o1 + 0x12
        let impulse = lookupModedImpulse(mode: Int16(truncatingIfNeeded: a - (a / 0x24) * 0x24),
                                         amount: Int16(truncatingIfNeeded: s * 0xf + r))
        let h = Int(rng.next(0x1b)) + x + 3
        let v = Int(rng.next(0x1b)) + y + 3
        var shape: Int
        if o1 < 3 || o1 > 0x21 || (o1 > 0xf && o1 < 0x15) {
            shape = 7
        } else if (o1 > 6 && o1 < 0xc) || (o1 > 0x18 && o1 < 0x1e) {
            shape = 4
        } else {
            dustShape = surfaceFlag == 0 ? 1 : 2
            shape = Int(dustShape)
        }
        if Int(rng.next(100)) > 0x32 { shape = Int(dustShape) }
        particles.newParticle(kind: 10, gravity: 0, v: v, h: h, shape: shape, vx: Int(impulse.h), vy: Int(impulse.v),
                              delay: 0, mode: 2)
    }

    /// `.LookupModedImpulse(out, mode, s) @ 100404a4` (decompile l. 37020–37410, raw `100404a4..10041790`): the base
    /// point `_DAT_100a17dc` (data (0, 0); never written) moved by s along direction `mode`·10° (jump table at TOC
    /// −0x211c, 36 entries; `cmplwi 0x23`, so any other mode leaves the base). Modes 0, 9, 18, 27: h − s, v + s, h + s,
    /// v − s (i16 adds); the others `fctiwz` of a fused `fmadd` (base + k·s) or `fnmsub` (base − k·s) with k the data
    /// doubles 0.174, 0.342, 0.5, 0.643, 0.766, 0.866, 0.94, 0.985 (`100a18c0`, `18b0`, `18a0`, `1890`, `1898`, `18a8`,
    /// `18b8`, `18c8`), stored as i16.
    public static func lookupModedImpulse(mode: Int16, amount s: Int16) -> (v: Int16, h: Int16) {
        // (v coefficient, h coefficient) per mode: ± index into `k` (1-based; 0 = untouched), from the decompile's
        // cases (checked against the jump table: entry 18 → `100404cc` h += s, entry 19 → `100404dc` h fmadd 0.985,
        // v fnmsub 0.174).
        let k: [Double] = [0, 0.174, 0.342, 0.5, 0.643, 0.766, 0.866, 0.94, 0.985]
        guard (0..<36).contains(Int(mode)) else { return (0, 0) }
        let m = Int(mode)
        switch m {
        case 0: return (0, 0 &- s)
        case 9: return (s, 0)
        case 18: return (0, s)
        case 27: return (0 &- s, 0)
        default: break
        }
        // Quadrant q = m / 9, step j = m % 9 (1…8): v gets k[j] (q 0, 1 +; q 2, 3 −), h gets k[9 − j] (q 0, 3 −;
        // q 1, 2 +).
        let q = m / 9, j = m % 9
        let vSign: Double = q < 2 ? 1 : -1
        let hSign: Double = (q == 1 || q == 2) ? 1 : -1
        let vk = q == 0 || q == 2 ? k[j] : k[9 - j]
        let hk = q == 0 || q == 2 ? k[9 - j] : k[j]
        func axis(_ coefficient: Double, _ sign: Double) -> Int16 {
            // fmadd: 0 + k·s; fnmsub: −(k·s − 0) — one rounding either way; `fctiwz` truncates.
            let p = (0.0 as Double).addingProduct(sign * coefficient, Double(s))
            return Int16(truncatingIfNeeded: Int32(p.rounded(.towardZero)))
        }
        return (axis(vk, vSign), axis(hk, hSign))
    }
}
