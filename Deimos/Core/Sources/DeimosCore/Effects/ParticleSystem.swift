import Foundation

/// The argument of `FUN_10043340` (the 0x18-byte emit request, particles-debris-blur §2.2, HIGH).
public struct ParticleRequest: Equatable, Sendable {
    /// +0x00 / +0x04: world position (copied raw into every particle; the draw subtracts the view offset).
    public var x: Float
    public var y: Float
    /// +0x08: the unit-def `pix16` colour (x1R5G5B5).
    public var colour: UInt16
    /// +0x0c: start delay → group +0x468 (all three shipped callers pass 0).
    public var delay: Int32
    /// +0x10: "scrolls with the ground" → group +0x464 (callers: `unit+0x8 == 'grnd'`).
    public var ground: Bool
    /// +0x14: the burst type (§2.3); `none`, 0 or any unknown ID → nothing.
    public var type: FourCC

    public init(x: Float, y: Float, colour: UInt16, delay: Int32 = 0, ground: Bool = false, type: FourCC) {
        self.x = x
        self.y = y
        self.colour = colour
        self.delay = delay
        self.ground = ground
        self.type = type
    }
}

/// One 0x1c-byte particle (§2.4).
public struct Particle: Equatable, Sendable {
    /// P+0x00.
    public var alive: Bool
    /// P+0x02 / +0x04: core and fringe colour of the drawn variant.
    public var core: UInt16
    public var fringe: UInt16
    /// P+0x08: fade 0 (solid) … 32 (u32 in the original; always 0…32 here).
    public var fade: Int32
    /// P+0x0c / +0x10 / +0x14 / +0x18.
    public var x: Float
    public var y: Float
    public var vx: Float
    public var vy: Float

    public init(alive: Bool = true, core: UInt16 = 0, fringe: UInt16 = 0, fade: Int32 = 0,
                x: Float = 0, y: Float = 0, vx: Float = 0, vy: Float = 0) {
        self.alive = alive
        self.core = core
        self.fringe = fringe
        self.fade = fade
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
    }
}

/// One 0x470-byte particle group (§2.4). Only the first `count` of the original's 40 slots can ever be alive
/// (`10043880 stb 0` clears the rest), so `particles` holds exactly `count` entries.
public struct ParticleGroup: Equatable, Sendable {
    /// G+0x464: ground-scroll flag.
    public var ground: Bool
    /// G+0x466: small-speed flag (×3.0, else ×5.0).
    public var smallSpeed: Bool
    /// G+0x467: ring flag (ring table, else burst table).
    public var ring: Bool
    /// G+0x468: start delay, −1 per update; particles move and draw only when ≤ 0.
    public var delay: Int32
    /// G+0x004 + 0x1c·k, k < G+0x46c.
    public var particles: [Particle]

    public init(ground: Bool = false, smallSpeed: Bool = true, ring: Bool = false, delay: Int32 = 0,
                particles: [Particle]) {
        self.ground = ground
        self.smallSpeed = smallSpeed
        self.ring = ring
        self.delay = delay
        self.particles = particles
    }
}

/// A direction-table entry (two floats, §2.5).
public struct ParticleVector: Equatable, Sendable {
    public var x: Float
    public var y: Float
    public init(x: Float, y: Float) { self.x = x; self.y = y }
}

/// G_Particle.cc (particles-debris-blur §2, HIGH unless marked). Purely visual, but every emitted particle draws
/// `R(0,4)` from the GAME generator at the emit (§1 #3) — the only replay-relevant part.
public struct ParticleSystem: Equatable, Sendable {
    /// The burst table `0x101185f0` (`*(r2−0x6e00)`): unit vectors × {1, 0.85, 0.70, 0.55}.
    public let burstTable: [ParticleVector]
    /// The ring table `0x101182d0` (`*(r2−0x6dfc)`): unit vectors.
    public let ringTable: [ParticleVector]
    /// `0x100e026c` (`r2−0x60c4`) / `0x100e0268` (`r2−0x60c8`): the next table entries. Never reset per level,
    /// game, demo or film (§2.1 scan) — they run on from app start.
    public internal(set) var burstIndex: Int32
    public internal(set) var ringIndex: Int32
    /// The group list `0x100e0270`, in append (= update and draw) order.
    public internal(set) var groups: [ParticleGroup] = []
    /// `rand()` calls made by the app-start build from the private seed-1 generator (300 + 2, §1 #1/#2).
    let appStartDraws: UInt64

    /// trunc(flli 54) = 416, trunc(flli 55) = 480 (`FUN_10020250(0x36/0x37)` + `fctiwz`).
    let width: Int32
    let height: Int32
    /// flli 144 `Particle_Gravity` (0.96 — a uniform drag), 145 `ColorVariationAdjust`, 146 `FringeColorAdjust`.
    let drag: Float
    let colourVariation: Float
    let fringeAdjust: Float
    /// trunc(flli 148) `Particle_BlendAmountRate_Long` (1).
    let blendRate: Int32

    /// `FUN_100431f0` at app start: `FUN_10044630` builds both tables (100 × [R(0,W), R(0,H), R(0,3)]), then
    /// `R(0,99)` → burst index, `R(0,99)` → ring index (`10043220..10043244`). All 302 draws come from a
    /// private generator at the image state 1 (`*(u32*)0x100e032c`, §1 / NR 3 MED) — never the game's: they run
    /// before any `srand`. `floats` = the permanent flli.
    public init(floats: [Float]) {
        width = EntityDraw.fctiwz(floats[54])
        height = EntityDraw.fctiwz(floats[55])
        drag = floats[144]
        colourVariation = floats[145]
        fringeAdjust = floats[146]
        blendRate = EntityDraw.fctiwz(floats[148])

        var rng = MSLRandom(seed: 1)
        var burst: [ParticleVector] = []
        var ring: [ParticleVector] = []
        burst.reserveCapacity(100)
        ring.reserveCapacity(100)
        // FUN_10044630 @ 10044630 (listing 10044648..10044818).
        let cx = Float(width) * Float(0.5)                           // 100446c4 fmuls f31 = W·0.5
        let cy = Float(height) * Float(0.5)                          // 100446c8 fmuls f30 = H·0.5
        for _ in 0..<100 {                                           // 1004480c cmpwi r23,0x64
            let px = rng.range(0, width)                             // 100446dc
            let py = rng.range(0, height)                            // 100446f0
            let dy: Float = cy - Float(py)                           // 10044720 fsubs f28
            let dx: Float = cx - Float(px)                           // 1004472c fsubs f29
            let sum = (dy * dy).addingProduct(dx, dx)                // 10044728 fmuls; 10044730 fmadds (fused)
            let len = ParticleSystem.root(EntityDraw.fctiwz(sum))    // 10044734 fctiwz; bl 0x10042f20
            let ux: Float = dx / len                                 // 10044748 fdivs
            let uy: Float = dy / len                                 // 10044758 fdivs
            ring.append(ParticleVector(x: ux, y: uy))                // 1004475c / 10044764
            var b = ParticleVector(x: ux, y: uy)                     // 10044760 / 10044768
            let k = rng.range(Int32(0), Int32(3))   // 1004476c
            let scale: Double?
            switch k {                                               // 10044774..10044794
            case 1: scale = 0.85                                     // lfd 0x18(r29) = 0x3feb333333333333
            case 2: scale = 0.7                                      // lfd 0x20(r29) = 0x3fe6666666666666
            case 3: scale = 0.55                                     // lfd 0x28(r29) = 0x3fe199999999999a
            default: scale = nil
            }
            if let s = scale {                                       // fmul (double); frsp
                b.x = Float(Double(b.x) * s)
                b.y = Float(Double(b.y) * s)
            }
            burst.append(b)
        }
        burstIndex = rng.range(Int32(0), Int32(99))   // 10043228 → stw −0x60c4(r2)
        ringIndex = rng.range(Int32(0), Int32(99))    // 1004323c → stw −0x60c8(r2)
        burstTable = burst
        ringTable = ring
        appStartDraws = rng.draws
    }

    /// `FUN_10042f20` — `n < 0x4000 ? sqrtTable[n] : (float)sqrt(n)`; the table entries are built by the same
    /// expression (`100429cc..10042a00`: `fsubs` → float n, MathLib `sqrt`, `frsp`), so one formula covers both.
    /// ◇ C7's `Trig.root` is the shared owner of this function; this private copy keeps C13 independent of C7.
    // C7: replace with Trig.root (FUN_10042f20)
    static func root(_ n: Int32) -> Float {
        Float(Foundation.sqrt(Double(Float(n))))
    }

    /// The burst-type switch of `FUN_10043340` (`10043388..10043478`, §2.3): count, small-speed flag, ring flag.
    public static func burst(_ type: FourCC) -> (count: Int, smallSpeed: Bool, ring: Bool)? {
        switch type.rawValue {
        case 0x7469_6e79: return (5, true, false)                    // 'tiny'
        case 0x7469_6369: return (5, true, true)                     // 'tici'
        case 0x736d_616c: return (10, true, false)                   // 'smal'
        case 0x736d_6369: return (10, true, true)                    // 'smci'
        case 0x6d65_6420: return (20, false, false)                  // 'med '
        case 0x6d65_6369: return (20, false, true)                   // 'meci'
        case 0x6c61_7267: return (40, false, false)                  // 'larg'
        case 0x6c61_6369: return (40, false, true)                   // 'laci'
        default: return nil                                          // 'none', 0 and every other ID → return
        }
    }

    /// The five colour variants of `FUN_10043340` (listing `10043518..1004373c`, §2.7). Per channel c of the
    /// request colour: `c16 = trunc(65535·(c·0.03125))` (`fsubs`, `fmuls`, `fmuls`, `fctiwz`, `sth`);
    /// `core = trunc(c16 · (float)(1.0 − (double)(float)(i·CVA)))` (`fmuls` f30, double `fsub` from 1.0, `frsp`);
    /// `fringe = trunc(core · FCA)` (`fmuls` f31); each packed by `FUN_10010bd0`.
    public static func colourVariants(_ colour: UInt16, variation: Float, fringeAdjust: Float)
        -> (core: [UInt16], fringe: [UInt16]) {
        let channels: [UInt16] = [colour >> 10 & 0x1f, colour >> 5 & 0x1f, colour & 0x1f]   // rlwinm 22/27/0
        let c16 = channels.map { c -> UInt16 in
            let f: Float = Float(c) * Float(0.03125)                 // fsubs (exact), fmuls f5
            return UInt16(truncatingIfNeeded: EntityDraw.fctiwz(Float(65535.0) * f))  // fmuls f4; fctiwz; sth
        }
        var core: [UInt16] = []
        var fringe: [UInt16] = []
        for i in 0..<5 {                                             // 1004372c cmpwi r23,5
            let iv: Float = Float(i) * variation                     // fsubs (signed magic), fmuls f30
            let factor = Float(1.0 - Double(iv))                     // fsub f3 = 1.0 − f1; frsp
            let c = c16.map { UInt16(truncatingIfNeeded: EntityDraw.fctiwz(Float($0) * factor)) }
            let f = c.map { UInt16(truncatingIfNeeded: EntityDraw.fctiwz(Float($0) * fringeAdjust)) }
            core.append(pack(c))                                     // 1004370c bl 0x10010bd0
            fringe.append(pack(f))                                   // 1004371c bl 0x10010bd0
        }
        return (core, fringe)
    }

    /// `FUN_10010bd0` — 16-bit RGB → x1R5G5B5: `(R>>1 & 0x7c00) | (G>>6 & 0x3e0) | (B>>11)` (`10010bd0..10010bf0`).
    static func pack(_ rgb: [UInt16]) -> UInt16 {
        (rgb[0] >> 1 & 0x7c00) | (rgb[1] >> 6 & 0x3e0) | (rgb[2] >> 11)
    }

    /// `FUN_10043340 @ 10043340` — emit one burst (§2.2–§2.7). An unknown/`none`/0 type returns at once (no
    /// group, no draw, `10043370..10043384`). Otherwise a group is appended (`100434b8 bl 0x100009e0`), then per
    /// particle k < N, in order: alive, position, **`R(0,4)`** on the game generator (`1004378c`), core/fringe of
    /// that variant, fade 0, the next table vector (`idx + 1 ≥ 99 → 0`, `100437e8..100437f8` /
    /// `10043820..10043830`), scaled ×3.0 (small) or ×5.0 (`10043834..10043878`, `fmuls`).
    public mutating func emit(_ req: ParticleRequest, rng: inout MSLRandom) {
        guard let kind = ParticleSystem.burst(req.type) else { return }
        let colours = ParticleSystem.colourVariants(req.colour, variation: colourVariation,
                                                    fringeAdjust: fringeAdjust)
        let speed: Float = kind.smallSpeed ? 3.0 : 5.0               // lfs 0x8(r30) / 0xc(r30) (0x100d73ac/b0)
        var group = ParticleGroup(ground: req.ground, smallSpeed: kind.smallSpeed, ring: kind.ring,
                                  delay: req.delay, particles: [])
        group.particles.reserveCapacity(kind.count)
        for _ in 0..<kind.count {
            let v = Int(rng.range(Int32(0), Int32(4)))
            var p = Particle(alive: true, core: colours.core[v], fringe: colours.fringe[v], fade: 0,
                             x: req.x, y: req.y)
            let vec: ParticleVector
            if kind.ring {
                vec = ringTable[Int(ringIndex)]
                ringIndex = ringIndex + 1 >= 99 ? 0 : ringIndex + 1
            } else {
                vec = burstTable[Int(burstIndex)]
                burstIndex = burstIndex + 1 >= 99 ? 0 : burstIndex + 1
            }
            p.vx = vec.x * speed
            p.vy = vec.y * speed
            group.particles.append(p)
        }
        groups.append(group)
    }

    /// `FUN_100438c0 @ 100438c0` — once per logic tick (world update `10006be0`), §2.8. Per group: delay −1, skip
    /// while > 0. Per alive particle: ground → `y += scrollDelta` (`fadds`); `v *= drag` per axis (`fmuls`);
    /// `x += vx; y += vy`; killed if `x < −32`, `x + 7 > W + 32`, `y < 0` or not `y + 7 ≤ H` (`10043a40..10043aa8`;
    /// the last is `ble`-keeps, so NaN kills); else fade < 32 → `fade += rate`, clamped to 32; fade ≥ 32 → killed.
    /// A group with no live particle left is removed (`10043b58..10043b78`). The fade-in branch (+0x465) is dead.
    /// `scrollDelta` = `FUN_1000fed0` (pixels scrolled this tick).
    public mutating func update(scrollDelta: Int32) {
        let rightKill = Float(width &+ 32)                           // r28 = trunc(flli54) + 0x20
        let bottom = Float(height)                                   // r27
        var kept: [ParticleGroup] = []
        kept.reserveCapacity(groups.count)
        for var g in groups {
            g.delay = g.delay &- 1                                   // 10043988..10043990
            if g.delay > 0 { kept.append(g); continue }              // 1004399c bgt
            var anyAlive = false
            for k in g.particles.indices where g.particles[k].alive {
                var p = g.particles[k]
                if g.ground { p.y = p.y + Float(scrollDelta) }       // 100439d8..10043a00
                p.vx = p.vx * drag                                   // 10043a0c
                p.vy = p.vy * drag                                   // 10043a18
                p.x = p.x + p.vx                                     // 10043a28
                p.y = p.y + p.vy                                     // 10043a38
                let killed = p.x < Float(-32.0)
                    || Float(7.0) + p.x > rightKill
                    || p.y < Float(0.0)
                    || !(Float(7.0) + p.y <= bottom)
                if killed {
                    p.alive = false                                  // 10043ab8..10043abc
                } else if UInt32(bitPattern: p.fade) < 32 {          // 10043ad4 cmplwi 0x20
                    p.fade = p.fade &+ blendRate                     // 10043adc
                    if UInt32(bitPattern: p.fade) > 32 { p.fade = 32 }   // 10043ae8..10043af4
                } else {
                    p.alive = false                                  // 10043afc..10043b00
                }
                if p.alive { anyAlive = true }                       // 10043b40..10043b4c
                g.particles[k] = p
            }
            if anyAlive { kept.append(g) }                           // 10043b58 → FUN_10044840
        }
        groups = kept
    }

    /// `FUN_10043ba0 @ 10043ba0` — the per-presented-frame draw's visibility (§2.9): groups with delay > 0 are
    /// skipped; per alive particle `sx = x − hOffset` (`fsubs`), drawn only if `sx ≥ 0`, `sx + 7 < W`, `y ≥ 0`,
    /// `y + 7 < H` (`10043cc0..10043d1c`); the stamp's top-left is `(trunc sx, trunc y)` (`10043d20..10043d48`).
    /// `hOffset` = `FUN_100100a0` (`ScrollState.offset`).
    public func stamps(hOffset: Int32) -> [ParticleStamp] {
        let off = Float(hOffset)
        let w = Float(width)
        let h = Float(height)
        var out: [ParticleStamp] = []
        for g in groups where g.delay <= 0 {                         // 10043c5c..10043c64
            for p in g.particles where p.alive {
                let sx: Float = p.x - off
                guard sx >= 0, Float(7.0) + sx < w, p.y >= 0, Float(7.0) + p.y < h else { continue }
                out.append(ParticleStamp(x: EntityDraw.fctiwz(sx), y: EntityDraw.fctiwz(p.y),
                                         core: p.core, fringe: p.fringe, fade: p.fade))
            }
        }
        return out
    }

    /// The 7×7 weights of the stamp (§2.9, listing `10043d30..100444e8`), row-major, with whether the pixel
    /// blends the core (E, X) or the fringe (A, B, C, D) colour. A = min(f+22, 31), B = min(f+10, 31),
    /// C = min(f+6, 31), D = E = f, X = f > 6 ? f − 7 : f (unsigned compares). Shared with R4's blitter by contract.
    public static func stampWeights(fade f: Int32) -> [(weight: Int32, core: Bool)] {
        let u = UInt32(bitPattern: f)
        func cap(_ add: UInt32) -> Int32 { let v = u &+ add; return Int32(bitPattern: v > 31 ? 31 : v) }
        let a = cap(22), b = cap(10), c = cap(6)
        let x = Int32(bitPattern: u > 6 ? u &- 7 : u)
        let pattern: [[Character]] = [
            ["A", "A", "B", "B", "B", "A", "A"],
            ["A", "B", "C", "C", "C", "B", "A"],
            ["B", "C", "D", "E", "D", "C", "B"],
            ["B", "C", "E", "X", "E", "C", "B"],
            ["B", "C", "D", "E", "D", "C", "B"],
            ["A", "B", "C", "C", "C", "B", "A"],
            ["A", "A", "B", "B", "B", "A", "A"],
        ]
        return pattern.flatMap { row in
            row.map { ch -> (weight: Int32, core: Bool) in
                switch ch {
                case "A": return (a, false)
                case "B": return (b, false)
                case "C": return (c, false)
                case "D": return (f, false)
                case "E": return (f, true)
                default: return (x, true)
                }
            }
        }
    }

    /// `FUN_100432d0` — per-level reset: free every group. The two table indices are NOT reset.
    public mutating func levelReset() {
        groups = []
    }
}
