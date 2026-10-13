import Foundation

/// The particle pool (particles §1–§3.1; plan E1a): 2000 records of 0x20 bytes at TOC `100a01ac`, the live count
/// `100a019c`, the first-free hint `100a01a0` and the high-water index `100a01a4` (i16 each). `.InitParticles @
/// 1003062c` (`.SetupLevel`) clears only byte +0 of every record — the three shorts are never reset (§1.1), so they run
/// on across levels (`LevelCarry.particles`). Units: positions px·256, velocities 1/256 px per frame.
public struct ParticlePool: Equatable, Sendable {
    /// One 32-byte record (§1.2).
    public struct Record: Equatable, Sendable {
        /// `+0x00`.
        public var alive = false
        /// `+0x02`: starts at −delay, +1 every `.HandleParticles`.
        public var age: Int16 = 0
        /// `+0x04`: the footprint code (§3.2).
        public var shape: Int16 = 0
        /// `+0x06`: the colour kind (§4; negative = ambient-lit).
        public var kind: Int16 = 0
        /// `+0x08`: added to vy after each move.
        public var gravity: Int16 = 0
        /// `+0x0c` / `+0x10` (sign-extended from the 16-bit arguments).
        public var vx: Int32 = 0
        public var vy: Int32 = 0
        /// `+0x14` / `+0x18`: x·256, y·256.
        public var x: Int32 = 0
        public var y: Int32 = 0
        /// `+0x1c`: blend mode — `.NewParticle` stores 0 and nothing else writes it (§1.2), so the translucent arms of
        /// `.DrawParticles` are dead.
        public var blend: UInt8 = 0
        /// `+0x1e`: the collision mode (§2.2).
        public var mode: UInt8 = 0
        // `+0x1d` (the erase mode `.WrapDrawParticle` returns) is FerazelRender's: only the draw writes it and only
        // `.EraseParticles` reads it.
    }

    /// The three i16 globals (§1.1).
    public struct Counters: Equatable, Sendable {
        /// `100a019c`: +1 per allocation, −1 per `.HandleParticles` kill, **−2** per colour-0 kill (§1.4) — it drifts
        /// and wraps.
        public var count: Int16 = 0
        /// `100a01a0`: where `.NewParticle` starts its scan.
        public var hint: Int16 = 0
        /// `100a01a4`: the loops run 0 … hwm.
        public var highWater: Int16 = 0

        public init(count: Int16 = 0, hint: Int16 = 0, highWater: Int16 = 0) {
            self.count = count
            self.hint = hint
            self.highWater = highWater
        }
    }

    /// `cmpwi 0x7d0` (raw `10031eb0`).
    public static let capacity = 2000

    public internal(set) var records = [Record](repeating: Record(), count: ParticlePool.capacity)
    public var counters = Counters()

    public init(counters: Counters = Counters()) {
        self.counters = counters
    }

    /// `.InitParticles @ 1003062c` (l. 28894–28912): byte +0 of every record cleared; the counters kept.
    public mutating func initParticles() {
        for i in records.indices { records[i].alive = false }
    }

    /// The records alive now.
    public var live: Int { records.reduce(0) { $0 + ($1.alive ? 1 : 0) } }

    /// `.NewParticle(kind, gravity, pos, shape, vx, vy, delay, mode) @ 10031e68` (l. 29899–29944; §1.3, §2): scans
    /// from the hint to 1999 for a record with byte +0 == 0; none → −1, nothing made. Found slot i: `+0` 1, age
    /// `−delay`, shape, kind, gravity, x = h << 8, y = v << 8, vx, vy (sign-extended), blend 0, mode; hint = i (the
    /// slot just taken), count += 1, hwm = max(hwm, i). The arguments are the binary's 16-bit (`short`; mode a byte)
    /// parameters: every value is truncated as the caller's `extsh`/`sth` does.
    @discardableResult
    public mutating func newParticle(kind: Int, gravity: Int, v: Int, h: Int, shape: Int, vx: Int, vy: Int, delay: Int,
                                     mode: Int) -> Int {
        var i = Int(counters.hint)
        var found = -1
        while i < Self.capacity {
            if !records[i].alive {
                found = i
                break
            }
            i += 1
        }
        guard found != -1 else { return -1 }
        var r = Record()
        r.alive = true
        r.age = 0 &- Int16(truncatingIfNeeded: delay)                     // `neg r9; sth r9,0x2`
        r.shape = Int16(truncatingIfNeeded: shape)
        r.kind = Int16(truncatingIfNeeded: kind)
        r.gravity = Int16(truncatingIfNeeded: gravity)
        r.x = Int32(Int16(truncatingIfNeeded: h)) << 8
        r.y = Int32(Int16(truncatingIfNeeded: v)) << 8
        r.vx = Int32(Int16(truncatingIfNeeded: vx))
        r.vy = Int32(Int16(truncatingIfNeeded: vy))
        r.blend = 0
        r.mode = UInt8(truncatingIfNeeded: mode)
        records[found] = r
        let s = Int16(found)
        counters.hint = s
        counters.count &+= 1
        if counters.highWater < s { counters.highWater = s }
        return found
    }

    /// `.HandleParticles @ 10031828` (l. 29650–29733, raw `10031828..10031a7c`), last in the sprite phase (after
    /// `.HandleSprites`, before `.WrapEraseSprites`): the bound hwm + 1 is read **once** at entry (`1003184c`). For each
    /// alive record: if age ≥ 0 — x += vx, y += vy, vy += gravity (`10031878..100318a4`), the mode test at the new
    /// position (§2.2; cell = (x >> 13, y >> 13), clamped as `.ConstrainXY`), age > 0x78 → die; a death clears `+0`,
    /// hint = min(hint, i), count −= 1, hwm −= 1 only when i == hwm (`10031a0c..10031a48`). Then age += 1 for every
    /// alive-at-entry record, the one just killed included (`10031a4c`).
    /// - mode 2: FG tile > 0x4f and age > 1;
    /// - mode 3: unless FG < 0x50 and the BG cell is liquid (`.IsWaterTile(.LookupBGTileKind)`), die (the `−2 < age`
    ///   test always passes for age ≥ 0);
    /// - mode 1: FG ≥ 0x51 → die; else liquid BG with vy ≥ 0x2ef → die;
    /// - any other mode: only the age.
    public mutating func handle(tiles: TileGrid) {
        let bound = Int(counters.highWater) + 1
        var i = 0
        while i < bound {
            if records[i].alive {
                var r = records[i]
                if r.age >= 0 {
                    r.x &+= r.vx
                    r.y &+= r.vy
                    r.vy &+= Int32(r.gravity)
                    let col = Int(Int16(truncatingIfNeeded: r.x >> 13))
                    let row = Int(Int16(truncatingIfNeeded: r.y >> 13))
                    var die = false
                    switch r.mode {
                    case 2:
                        if 0x4f < tiles.fgTile(col: col, row: row) && 1 < r.age { die = true }
                    case 3:
                        let fg = tiles.fgTile(col: col, row: row)
                        let water = UnderWater.isWaterTile(tiles.bgKind(tile: tiles.bgTile(col: col, row: row)))
                        if !(fg < 0x50 && water) && -2 < r.age { die = true }
                    case 1:
                        if tiles.fgTile(col: col, row: row) < 0x51 {
                            let water = UnderWater.isWaterTile(tiles.bgKind(tile: tiles.bgTile(col: col, row: row)))
                            if water && 0x2ee < r.vy { die = true }
                        } else {
                            die = true
                        }
                    default:
                        break
                    }
                    if ParticleLife.ageLimit < r.age { die = true }
                    if die {
                        r.alive = false
                        kill(i, twice: false)
                    }
                }
                r.age &+= 1
                records[i] = r
            }
            i += 1
        }
    }

    /// `.DrawParticles @ 10031aa4`'s Core half (l. 29741–29860, raw `10031aa4..10031d48`), drawn iterations only: the
    /// bound hwm + 1 is re-read each step (`10031d24`). For each alive record with age > 0: the colour test
    /// (`ParticleLife.colourIsZero`) → a 0 kills it (count −1, hint = min(hint, i), count −1 again, hwm −1 when i ==
    /// hwm; raw `10031b98..10031be0`) and nothing is drawn; otherwise it is handed to `.WrapDrawParticle` (the returned
    /// list, in index order; FerazelRender draws it). Ages ≤ 0 are skipped (never drawn, never colour-killed).
    public mutating func draw() -> [ParticleDraw] {
        var out: [ParticleDraw] = []
        var i = 0
        while i < Int(counters.highWater) + 1 {
            let r = records[i]
            if r.alive && 0 < r.age {
                if ParticleLife.colourIsZero(kind: r.kind, age: r.age) {
                    records[i].alive = false
                    kill(i, twice: true)
                } else {
                    out.append(ParticleDraw(slot: i, kind: r.kind, age: r.age, shape: r.shape,
                                            v: Int16(truncatingIfNeeded: r.y >> 8),
                                            h: Int16(truncatingIfNeeded: r.x >> 8)))
                }
            }
            i += 1
        }
        return out
    }

    /// A kill's counter writes, in the binary's order (`.HandleParticles`: hint, count, hwm; `.DrawParticles`: count,
    /// hint, count, hwm). The order does not change the result; both orders are kept as read.
    private mutating func kill(_ i: Int, twice: Bool) {
        let s = Int16(i)
        if twice { counters.count &-= 1 }
        if s < counters.hint { counters.hint = s }
        counters.count &-= 1
        if s == counters.highWater { counters.highWater &-= 1 }
    }
}
