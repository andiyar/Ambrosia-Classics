import XCTest
import HectorResources
@testable import FerazelCore

/// E1a (docs/plans/2026-10-10-ferazel-phase2.md): the particle pool — `.NewParticle @ 10031e68`, `.HandleParticles
/// @ 10031828`, the Core half of `.DrawParticles @ 10031aa4` (the colour-0 kill, `ParticleLife`), `.Splash @ 10042874`
/// and the session's particle ops (particles §1–§5.4). Synthetic tile grids where a test names one; the committed level 1
/// otherwise (D26).
final class ParticleTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// A 16×16 grid: FG tile 0x50 at (1, 1), 0x4f at (2, 1), 0x51 at (3, 1); BG liquid (tile 1, kind 200) on row 2,
    /// cols 0…5, with FG tile 0x50 over (4, 2).
    private func grid() -> TileGrid {
        var fg = [UInt16](repeating: 0, count: 16 * 16)
        fg[1 * 16 + 1] = 0x50 + 1
        fg[1 * 16 + 2] = 0x4f + 1
        fg[1 * 16 + 3] = 0x51 + 1
        fg[2 * 16 + 4] = 0x50 + 1
        var bg = [UInt16](repeating: 0, count: 16 * 16)
        for c in 0...5 { bg[2 * 16 + c] = 1 + 1 }
        var bgKinds = [Int](repeating: 0, count: 0x60)
        bgKinds[1] = 200
        return TileGrid(fg: TileMap(width: 16, height: 16, cells: fg), bg: TileMap(width: 16, height: 16, cells: bg),
                        fgKinds: Array(0..<0x60), bgKinds: bgKinds)
    }

    /// A particle at rest inside cell (col, row) (5 px in), kind 3 (never colour-killed), no gravity.
    @discardableResult
    private func still(_ p: inout ParticlePool, col: Int, row: Int, mode: Int, delay: Int = 0, vy: Int = 0) -> Int {
        p.newParticle(kind: 3, gravity: 0, v: row * 32 + 5, h: col * 32 + 5, shape: 1, vx: 0, vy: vy, delay: delay,
                      mode: mode)
    }

    // MARK: - the five plan tests

    func testAllocationHint() {
        var p = ParticlePool()
        // `.NewParticle` (raw `10031e84..10031f38`): slots 0, 1, 2 from hint 0; hint = the slot taken.
        XCTAssertEqual((0..<3).map { _ in still(&p, col: 8, row: 8, mode: 0) }, [0, 1, 2])
        XCTAssertEqual(p.counters, ParticlePool.Counters(count: 3, hint: 2, highWater: 2))
        // Kill 1 (`.HandleParticles`, age > 0x78): hint = min(hint, 1), count − 1 (once), hwm kept (1 ≠ 2).
        p.records[1].age = 0x79
        p.handle(tiles: grid())
        XCTAssertFalse(p.records[1].alive)
        XCTAssertEqual(p.counters, ParticlePool.Counters(count: 2, hint: 1, highWater: 2))
        // Kill 2 at the high-water mark: hwm − 1.
        p.records[2].age = 0x79
        p.handle(tiles: grid())
        XCTAssertEqual(p.counters, ParticlePool.Counters(count: 1, hint: 1, highWater: 1))
        XCTAssertEqual(p.records.map(\.alive).prefix(4), [true, false, false, false])
        // The scan starts at the hint: slot 1 again (hint 1, hwm max(1, 1)), then 2 (raises hwm).
        XCTAssertEqual(still(&p, col: 8, row: 8, mode: 0), 1)
        XCTAssertEqual(p.counters, ParticlePool.Counters(count: 2, hint: 1, highWater: 1))
        XCTAssertEqual(still(&p, col: 8, row: 8, mode: 0), 2)
        XCTAssertEqual(p.counters, ParticlePool.Counters(count: 3, hint: 2, highWater: 2))
        // A kill below the hwm leaves it; the same slot dying twice in one pass is impossible (+0 is cleared).
        p.records[0].age = 0x79
        p.handle(tiles: grid())
        XCTAssertEqual(p.counters, ParticlePool.Counters(count: 2, hint: 0, highWater: 2))
        // A stale hint (Init never resets it, §1.3): slots below it stay unused.
        var stale = ParticlePool(counters: ParticlePool.Counters(count: -7, hint: 5, highWater: 0))
        XCTAssertEqual(still(&stale, col: 8, row: 8, mode: 0), 5)
        XCTAssertEqual(stale.counters, ParticlePool.Counters(count: -6, hint: 5, highWater: 5))
        // A full pool: −1, nothing made, nothing counted.
        var full = ParticlePool()
        for _ in 0..<ParticlePool.capacity { still(&full, col: 8, row: 8, mode: 0) }
        XCTAssertEqual(full.counters, ParticlePool.Counters(count: 2000, hint: 1999, highWater: 1999))
        XCTAssertEqual(still(&full, col: 8, row: 8, mode: 0), -1)
        XCTAssertEqual(full.counters, ParticlePool.Counters(count: 2000, hint: 1999, highWater: 1999))
        // `.InitParticles`: byte +0 only; the counters run on (§1.1).
        full.initParticles()
        XCTAssertEqual(full.live, 0)
        XCTAssertEqual(full.counters, ParticlePool.Counters(count: 2000, hint: 1999, highWater: 1999))
        // The record as stored (§1.2): 16-bit arguments, age = −delay, x/y = h/v << 8.
        var one = ParticlePool()
        one.newParticle(kind: -0x105, gravity: 0x1_0096, v: -3, h: 0x1_0007, shape: 4, vx: 0x1_8000, vy: -0x1_0001,
                        delay: -50, mode: 0x103)
        let r = one.records[0]
        XCTAssertEqual([r.kind, r.gravity, r.shape, r.age], [-0x105, 0x96, 4, 50])
        XCTAssertEqual([r.vx, r.vy, r.x, r.y], [-0x8000, -1, 7 << 8, -3 << 8])
        XCTAssertEqual([r.mode, r.blend], [3, 0])
    }

    func testColourKillCountsTwice() {
        // `ParticleLife` (particles §4.2–§4.3): the first zero age of each row.
        let lives: [Int: Int16] = [1: 24, 13: 24, 2: 38, 4: 16, 9: 13, 10: 17, 11: 15, 12: 19, 210: 21, 211: 21,
                                   220: 12, 221: 12, 222: 12, 223: 22]
        for k in 0..<0x100 {
            let never: Set = [3, 5, 6, 7, 8, 199, 200, 201, 202, 203, 205, 213, 215]
            XCTAssertEqual(ParticleLife.life[k], lives[k] ?? (never.contains(k) ? 120 : 0), "kind \(k)")
        }
        var p = ParticlePool()
        let specs: [(kind: Int, age: Int16)] = [(14, 1), (2, 37), (2, 38), (3, 119), (3, 120), (-258, 5), (256, 1),
                                                (-512, 1), (14, 0), (14, -3), (14, 1)]
        for s in specs {
            p.newParticle(kind: s.kind, gravity: 0, v: 100 + Int(s.age), h: 50, shape: 2, vx: 0, vy: 0,
                          delay: -Int(s.age), mode: 0)
        }
        XCTAssertEqual(p.counters, ParticlePool.Counters(count: 11, hint: 10, highWater: 10))
        let drawn = p.draw()
        // Kills: 0 (unbuilt row), 2 (age 38 = kind 2's life), 4 (age ≥ 0x78), 6 (256 − 0x100 = 0), 7 (|−512| − 0x100 =
        // 0x100, low byte 0), 10 (unbuilt, at the hwm): six kills × 2 → 11 − 12 = −1 (§1.4). hint 0, hwm 10 → 9.
        XCTAssertEqual(p.counters, ParticlePool.Counters(count: -1, hint: 0, highWater: 9))
        XCTAssertEqual(p.records.prefix(11).map(\.alive),
                       [false, true, false, true, false, true, false, false, true, true, false])
        // Ages ≤ 0 are neither drawn nor killed; the drawn ones in pool order.
        XCTAssertEqual(drawn.map(\.slot), [1, 3, 5])
        XCTAssertEqual(drawn[2], ParticleDraw(slot: 5, kind: -258, age: 5, shape: 2, v: 105, h: 50))
        XCTAssertEqual(drawn[0], ParticleDraw(slot: 1, kind: 2, age: 37, shape: 2, v: 137, h: 50))
        // The draw does not age or move anything.
        XCTAssertEqual(p.records[3].age, 119)
        // The colour test itself.
        XCTAssertFalse(ParticleLife.colourIsZero(kind: -0x101, age: 1))
        XCTAssertTrue(ParticleLife.colourIsZero(kind: 0x200, age: 1))
        XCTAssertTrue(ParticleLife.colourIsZero(kind: 1, age: 24))
        XCTAssertFalse(ParticleLife.colourIsZero(kind: -1, age: 23))
        XCTAssertTrue(ParticleLife.colourIsZero(kind: 0x1ff, age: 0x78))
        // The count is an i16 (`sth`): it wraps.
        var w = ParticlePool(counters: ParticlePool.Counters(count: -0x8000, hint: 0, highWater: 0))
        w.newParticle(kind: 14, gravity: 0, v: 0, h: 0, shape: 1, vx: 0, vy: 0, delay: -1, mode: 0)
        XCTAssertEqual(w.counters.count, -0x7fff)
        _ = w.draw()
        XCTAssertEqual(w.counters, ParticlePool.Counters(count: 0x7fff, hint: 0, highWater: -1))
    }

    func testSkippedDrawNoColourKill() throws {
        var prefs = FerazelPrefs()
        prefs.reduceFrameRate = 1
        let s = try FerazelSession(resources: try resources(), prefs: prefs, level: 1)
        XCTAssertEqual(s.world.particles.counters, ParticlePool.Counters())
        // An unbuilt-row particle (dies at its first draw) and a blood particle, high in the level's air, mode 0.
        s.world.particles.newParticle(kind: 14, gravity: 0, v: 40, h: 300, shape: 1, vx: 0, vy: 0, delay: 0, mode: 0)
        s.world.particles.newParticle(kind: 2, gravity: 0, v: 40, h: 310, shape: 4, vx: 0x100, vy: 0, delay: 0, mode: 0)
        func kinds(_ ops: FrameOps) -> [String] {
            ops.draws.compactMap { op in
                switch op {
                case .wrapDrawWaterEffects(let l): return "water\(l.count)"
                case .wrapDrawSprites: return "sprites"
                case .drawParticles(let l): return "particles\(l.count)"
                case .copyToScreen: return "copy"
                case .eraseParticles: return "eraseP"
                case .wrapEraseSprites: return "erase"
                default: return nil
                }
            }
        }
        // Iteration 1 is skipped: no `.DrawParticles` → no colour kill; `.HandleParticles` still runs (age 0 → 1, the
        // move), and the parity does not flip.
        let first = s.step(keys: KeyState())
        XCTAssertFalse(first.drawn)
        XCTAssertEqual(kinds(first), ["water0", "sprites", "erase"])
        XCTAssertEqual(s.world.particles.counters, ParticlePool.Counters(count: 2, hint: 1, highWater: 1))
        XCTAssertEqual(s.world.particles.records[0].age, 1)
        XCTAssertTrue(s.world.particles.records[0].alive)
        XCTAssertEqual(s.world.particles.records[1].x, 310 << 8 + 0x100)
        XCTAssertFalse(s.world.parity)
        // Iteration 2 is drawn: the kind-14 particle dies in the draw (count − 2), the blood is handed over at age 1;
        // then the handle pass ages the survivor.
        let second = s.step(keys: KeyState())
        XCTAssertTrue(second.drawn)
        XCTAssertEqual(kinds(second), ["water0", "sprites", "particles1", "copy", "eraseP", "erase"])
        let list = second.draws.compactMap { if case .drawParticles(let l) = $0 { l } else { nil } }.first
        XCTAssertEqual(list, [ParticleDraw(slot: 1, kind: 2, age: 1, shape: 4, v: 40, h: 311)])
        XCTAssertEqual(s.world.particles.counters, ParticlePool.Counters(count: 0, hint: 0, highWater: 1))
        XCTAssertFalse(s.world.particles.records[0].alive)
        XCTAssertEqual(s.world.particles.records[1].age, 2)
        XCTAssertTrue(s.world.parity)
        // The counters ride the carry into the next level (`.InitParticles` keeps them), the records do not.
        XCTAssertEqual(s.carry.particles, ParticlePool.Counters(count: 0, hint: 0, highWater: 1))
        let next = try FerazelSession(resources: try resources(), prefs: prefs, level: 2, carry: s.carry)
        XCTAssertEqual(next.world.particles.counters, ParticlePool.Counters(count: 0, hint: 0, highWater: 1))
        XCTAssertEqual(next.world.particles.live, 0)
        XCTAssertEqual(next.world.frameCounter, 0)
        _ = next.step(keys: KeyState())
        XCTAssertEqual(next.world.frameCounter, 1)
    }

    func testParticleMotion() throws {
        let L1 = try LevelFile.load(from: try resources(), level: 1)
        var p = ParticlePool()
        let g = grid()
        // NewParticle(200, 150, (100, 50), 2, −154, −502, 0, 1): x = 50·256 − 154, y = 100·256 − 502, vy += 150.
        p.newParticle(kind: 200, gravity: 150, v: 100, h: 50, shape: 2, vx: -154, vy: -502, delay: 0, mode: 1)
        p.handle(tiles: g)
        XCTAssertEqual([p.records[0].x, p.records[0].y, p.records[0].vy], [12646, 25098, -352])
        XCTAssertEqual(p.records[0].age, 1)
        XCTAssertEqual(p.draw(), [ParticleDraw(slot: 0, kind: 200, age: 1, shape: 2, v: 98, h: 49)])
        // Negative positions draw as `srawi 8` (floor): x −1 → h −1.
        var n = ParticlePool()
        n.newParticle(kind: 3, gravity: 0, v: 0, h: 0, shape: 1, vx: -1, vy: -0x101, delay: 0, mode: 0)
        n.handle(tiles: g)
        XCTAssertEqual(n.draw().map { [$0.h, $0.v] }, [[-1, -2]])

        // A delay freezes it (age −2 → −1 → 0 unmoved), then the age-0 pass moves it.
        var d = ParticlePool()
        d.newParticle(kind: 3, gravity: 7, v: 20, h: 10, shape: 1, vx: 3, vy: 5, delay: 2, mode: 0)
        d.handle(tiles: g)
        d.handle(tiles: g)
        XCTAssertEqual([d.records[0].age, Int16(d.records[0].x), Int16(d.records[0].vy)], [0, 10 << 8, 5])
        d.handle(tiles: g)
        XCTAssertEqual([d.records[0].age, Int16(d.records[0].x - (10 << 8)), Int16(d.records[0].y - (20 << 8))],
                       [1, 3, 5])
        XCTAssertEqual(d.records[0].vy, 12)

        // The collision modes (§2.2) at the moved position; age at the test = the stored age (before + 1).
        func survives(col: Int, row: Int, mode: Int, age: Int16 = 0, vy: Int = 0) -> Bool {
            var q = ParticlePool()
            still(&q, col: col, row: row, mode: mode, vy: vy)
            q.records[0].y -= Int32(vy)                                  // land on (col, row) after the move
            q.records[0].age = age
            q.handle(tiles: g)
            return q.records[0].alive
        }
        // mode 2: FG > 0x4f and age > 1.
        XCTAssertFalse(survives(col: 1, row: 1, mode: 2, age: 2))
        XCTAssertTrue(survives(col: 1, row: 1, mode: 2, age: 1))
        XCTAssertTrue(survives(col: 2, row: 1, mode: 2, age: 5))
        // mode 3: only FG < 0x50 over liquid keeps it.
        XCTAssertTrue(survives(col: 0, row: 2, mode: 3))
        XCTAssertFalse(survives(col: 0, row: 3, mode: 3))
        XCTAssertFalse(survives(col: 4, row: 2, mode: 3))
        XCTAssertFalse(survives(col: 2, row: 1, mode: 3))
        // mode 1: FG ≥ 0x51 dies; else liquid and vy ≥ 0x2ef (after the gravity add) dies.
        XCTAssertFalse(survives(col: 3, row: 1, mode: 1))
        XCTAssertTrue(survives(col: 1, row: 1, mode: 1))
        XCTAssertTrue(survives(col: 4, row: 3, mode: 1, vy: 0x2ef))
        XCTAssertFalse(survives(col: 0, row: 2, mode: 1, vy: 0x2ef))
        XCTAssertTrue(survives(col: 0, row: 2, mode: 1, vy: 0x2ee))
        XCTAssertTrue(survives(col: 4, row: 2, mode: 1))                // FG 0x50 < 0x51, liquid, vy 0
        XCTAssertFalse(survives(col: 4, row: 2, mode: 1, vy: 0x2ef))
        // mode 0 / any other: the age only (> 0x78).
        XCTAssertTrue(survives(col: 3, row: 1, mode: 0))
        XCTAssertTrue(survives(col: 3, row: 1, mode: 7, age: 0x78))
        XCTAssertFalse(survives(col: 0, row: 3, mode: 0, age: 0x79))
        // The bound is read once at entry: a particle at the hwm that dies lowers it, the loop still visits the rest
        // it had (none above here) — and a killed record is still aged (`10031a4c`).
        var k = ParticlePool()
        still(&k, col: 8, row: 8, mode: 0)
        k.records[0].age = 0x79
        k.handle(tiles: g)
        XCTAssertEqual(k.records[0].age, 0x7a)
        XCTAssertEqual(k.counters, ParticlePool.Counters(count: 0, hint: 0, highWater: -1))

        // E1a emitter sites — the face walks (`.ExplodeFaceIntoParticles`, `.ParticleGlow`) on a synthetic face: frame
        // (0, 0, 3, 4), bounds (0, −1, 4, 6); row 0 = 3 literal [10 11 12], row 1 = skip 1 + 2 literal [20 21], row 2 =
        // 4 literal [30 31 32 33].
        func tok(_ op: UInt32, _ n: Int) -> [UInt8] {
            let t = op << 24 | UInt32(n)
            return [UInt8(t >> 24), UInt8(t >> 16 & 0xff), UInt8(t >> 8 & 0xff), UInt8(t & 0xff)]
        }
        let face = ParticleFace(frame: [0, 0, 3, 4], bounds: [0, -1, 4, 6],
                                tokens: tok(1, 8) + tok(2, 3) + [10, 11, 12, 0] + tok(1, 12) + tok(3, 1) + tok(2, 2)
                                    + [20, 21, 0, 0] + tok(1, 8) + tok(2, 4) + [30, 31, 32, 33] + tok(0, 0))
        func explode(_ style: Int16, face f: ParticleFace? = nil) -> SpriteWorld {
            let w = SpriteWorld(level: L1, seed: 1)
            ExplodeFace.explode(w, face: f ?? face, v: 100, h: 50, xStep: 2, yStep: 2, shape: 2, gravity: 100,
                                style: style)
            return w
        }
        // Style 100 (xStep 2, yStep 2): rows 0 and 2 used (the first at v + 1), every 2nd pixel with the column
        // counter carried across rows: (101, 50) px 10, (101, 52) px 12, (103, 51) px 31, (103, 53) px 33.
        let e100 = explode(100)
        let r100 = e100.particles.records.prefix(4)
        XCTAssertEqual(e100.particles.counters.count, 4)
        XCTAssertEqual(r100.map(\.kind), [-266, -268, -287, -289])
        XCTAssertEqual(r100.map { [Int($0.y >> 8), Int($0.x >> 8)] }, [[101, 50], [101, 52], [103, 51], [103, 53]])
        var ref = FastRand(seed: 1)
        let (a20, a750, a100, a30) = (ref.next(0x14), ref.next(0x2ee), ref.next(100), ref.next(0x1e))
        XCTAssertEqual([r100[0].gravity, Int16(r100[0].vx), Int16(r100[0].vy), r100[0].age],
                       [100 + a30, a100 - 50, 40 - a750, 98 - a20])
        XCTAssertEqual(Set(r100.map(\.shape)), [2])
        XCTAssertEqual(Set(r100.map(\.mode)), [1])
        for _ in 0..<12 { _ = ref.next(1) }
        XCTAssertEqual(e100.rng.seed, ref.seed)                            // 4 draws per particle
        // Style 101: radial about (cV, cH) = (100 + 2, 50 + 2); R(60) vx, R(60) vy, R(16) delay, R(12) gravity.
        let e101 = explode(101)
        var r1 = FastRand(seed: 1)
        let (b0, b1, b16, b12) = (Int32(r1.next(0x3c)), Int32(r1.next(0x3c)), r1.next(0x10), r1.next(0xc))
        let p101 = e101.particles.records[0]
        XCTAssertEqual([p101.vx, p101.vy], [(50 - 52) * 50 + b0 - 30, (101 - 102) * 50 + b1 - 30])
        XCTAssertEqual([p101.age, p101.gravity, p101.kind], [104 - b16, 100 + b12, -266])
        XCTAssertEqual(e101.particles.counters.count, 4)
        // Style 102: kind 1, shape R(2) + 1, delay R(5): five draws each.
        let e102 = explode(102)
        var r2 = FastRand(seed: 1)
        _ = (r2.next(0x3c), r2.next(0x3c))
        let (c5, c2, c12) = (r2.next(5), r2.next(2), r2.next(0xc))
        let p102 = e102.particles.records[0]
        XCTAssertEqual([p102.kind, p102.shape, p102.age, p102.gravity], [1, c2 + 1, -c5, 100 + c12])
        for _ in 0..<15 { _ = r2.next(1) }
        XCTAssertEqual(e102.rng.seed, r2.seed)
        // Another style walks without emitting; no face, nothing.
        XCTAssertEqual([explode(99).rng.seed, explode(100, face: ParticleFace(frame: [0, 0, 0, 0], bounds: [0, 0, 0, 0],
                                                                              tokens: tok(0, 0))).rng.seed], [1, 1])
        let none = SpriteWorld(level: L1, seed: 1)
        ExplodeFace.explode(none, face: nil, v: 0, h: 0, xStep: 1, yStep: 1, shape: 1, gravity: 0, style: 100)
        XCTAssertEqual(none.rng.seed, 1)

        // `.ParticleGlow` (kind 220, chance 100): each run's first and last pixel — (101: 50, 52), (102: 51, 52),
        // (103: 50, 53); vx = 120 + R(150), negated left of cH = 50 + (0 + 4) >> 1 = 52; 6 draws each.
        let gw = SpriteWorld(level: L1, seed: 1)
        ParticleGlow.glow(gw, face: face, v: 100, h: 50, kind: 220, chance: 100, flip: false)
        let gl = gw.particles.records.prefix(6)
        XCTAssertEqual(gw.particles.counters.count, 6)
        XCTAssertEqual(gl.map { Int($0.x >> 8) }, [50, 52, 51, 52, 50, 53])
        XCTAssertEqual(gl.map { $0.vx < 0 }, [true, false, true, false, true, false])
        var rg = FastRand(seed: 1)
        let (d4, d5, _, d150, _, d80) = (rg.next(4), rg.next(5), rg.next(100), rg.next(0x96), rg.next(100), rg.next(0x50))
        XCTAssertEqual([Int32(gl[0].y >> 8), gl[0].vx, gl[0].vy], [Int32(101 + d4), -(120 + Int32(d150)), 40 - Int32(d80)])
        XCTAssertEqual([gl[0].age, gl[0].kind, gl[0].shape, gl[0].gravity], [-(d5 + 2), 220, 1, 0])
        XCTAssertEqual(Set(gl.map(\.mode)), [0])
        for _ in 0..<30 { _ = rg.next(1) }
        XCTAssertEqual(gw.rng.seed, rg.seed)
        // Chance −1: the five draws per endpoint, no particle. Flipped: each row starts at h + 4 and walks left.
        let g0 = SpriteWorld(level: L1, seed: 1)
        ParticleGlow.glow(g0, face: face, v: 100, h: 50, kind: 220, chance: -1, flip: false)
        var r0 = FastRand(seed: 1)
        for _ in 0..<30 { _ = r0.next(1) }
        XCTAssertEqual([g0.particles.counters.count, Int16(truncatingIfNeeded: g0.rng.seed == r0.seed ? 1 : 0)], [0, 1])
        let gf = SpriteWorld(level: L1, seed: 1)
        ParticleGlow.glow(gf, face: face, v: 100, h: 50, kind: 220, chance: 100, flip: true)
        XCTAssertEqual(gf.particles.records.prefix(6).map { Int($0.x >> 8) }, [54, 52, 53, 52, 54, 51])
        // From `.StandardSpriteCleanup`: `+0x1a8 ≠ 0` with a face and a provider.
        let sc = SpriteWorld(level: L1, seed: 1)
        sc.particleFaces = ParticleFaces(sprite: { _ in face })
        let gid = sc.newSprite(type: 0, x: 50, y: 100, layer: 10, handler: .player) { s in
            s.x = 50; s.y = 100
            s.face = FaceRef(pict: 1020, index: 0, set: .encoded)
            s.glowKind = 221
            s.glowChance = 100
        }!
        sc.standardSpriteCleanup(gid, faceWidth: { _ in 4 })
        XCTAssertEqual(sc.particles.counters.count, 6)
        XCTAssertEqual(sc.particles.records[0].kind, 221)
        sc.active.update(id: gid) { $0.glowChance = 0 }
        sc.standardSpriteCleanup(gid, faceWidth: { _ in 4 })
        XCTAssertEqual(sc.particles.counters.count, 6)
    }

    func testSplashLevel1() throws {
        let L = try LevelFile.load(from: try resources(), level: 1)
        // BG liquid (tile 1, kind 201) on rows 6…11 of a 16×16 grid; the player-sized sprite (hot rect 0x26…0x3e, the
        // standard rect) at (100, 300), `+0x11c` 40, centre (150, 330), vx 0x200, vy 0x800.
        func world(frame: Int32 = 0, kind: Int16 = 0, handler: SpriteHandler = .player, type: Int16 = 0,
                   rect: IdleSprites.Rect = HandleKeys.standardHotRect) -> (SpriteWorld, Int) {
            let w = SpriteWorld(level: L, seed: 1)
            var bg = [UInt16](repeating: 0, count: 16 * 16)
            for r in 6...11 { for c in 0..<16 { bg[r * 16 + c] = 1 + 1 } }
            var bgKinds = [Int](repeating: 0, count: 0x60)
            bgKinds[1] = 201
            w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: [UInt16](repeating: 0, count: 256)),
                               bg: TileMap(width: 16, height: 16, cells: bg), fgKinds: Array(0..<0x60),
                               bgKinds: bgKinds)
            w.frameCounter = frame
            let id = w.newSprite(type: type, x: 100, y: 300, layer: 10, handler: handler) { s in
                s.x = 100; s.y = 300
                s.hotRect = rect
                s.face = FaceRef(pict: 1020, index: 0, set: .encoded)
                s.vx = 0x200
                s.vy = 0x800
                s.waterRow = 40
                s.waterKind = kind
                s.centre = SpriteSlot.Point(x: 150, y: 330)
            }!
            return (w, id)
        }
        // Sound gate off (frame counter 0 ≤ 3): row (300 + 0 + 40 + 16) >> 5 = 11, walked up to 6 (row 5 is dry);
        // kind 201 (≥ 200 kept); S = 192. Columns 100 + 0x26 − 4 = 134 … < 100 + 0x3e + 4 = 166: 32 × 3 = 96.
        let (w, id) = world()
        Splash.splash(w, id: id, mode: 3)
        XCTAssertEqual(w.particles.counters, ParticlePool.Counters(count: 96, hint: 95, highWater: 95))
        XCTAssertTrue(w.player.cues.isEmpty)
        let r = w.particles.records
        // First column: vx = R(500) 128 + (−0x200 >> 4) − 250 = −154; vy0 = −600 − R(200) 46 − (0x800 >> 3) = −902.
        XCTAssertEqual(r[0].vx, -154)
        XCTAssertEqual([r[0].vy, r[1].vy, r[2].vy], [-502, -702, -902])
        XCTAssertEqual([r[0].shape, r[1].shape, r[2].shape], [2, 4, 1])
        XCTAssertEqual([r[0].age, r[1].age, r[2].age], [0, -1, -2])
        XCTAssertEqual(Set(r.prefix(96).map(\.kind)), [201])
        XCTAssertEqual(Set(r.prefix(96).map(\.gravity)), [150])
        XCTAssertEqual(Set(r.prefix(96).map(\.mode)), [1])
        XCTAssertEqual(Set(r.prefix(96).map(\.y)), [192 << 8])
        XCTAssertEqual([r[0].x, r[3].x, r[95].x], [134 << 8, 135 << 8, 165 << 8])
        // Three draws per column (R(500), R(200), R(1)): 96 in all.
        var ref = FastRand(seed: 1)
        for _ in 0..<96 { _ = ref.next(1) }
        XCTAssertEqual(w.rng.seed, ref.seed)

        // Gate on (frame counter 4, centre in view): the big splash 405 first, its rate drawn before the columns, so
        // the first column's R(500) is the next value: vx −167.
        let (w2, id2) = world(frame: 4)
        Splash.splash(w2, id: id2, mode: 3)
        var ref2 = FastRand(seed: 1)
        let rate = ref2.soundRate()
        XCTAssertEqual(w2.player.cues, [PlayerCue(call: .threeDRand, snd: 405, priority: 1, volume: 0x100,
                                                  position: SpriteSlot.Point(x: 150, y: 330), rate: rate)])
        XCTAssertEqual(w2.particles.records[0].vx, -167)
        XCTAssertEqual(w2.particles.counters.count, 96)
        // A narrow rect (width 0x10 < 0x11): the small 406 at 0x2d; quicksand (`+0x128` 5): 605 for both.
        let narrow = IdleSprites.Rect(top: 0, left: 0, bottom: 0x10, right: 0x10)
        let (w3, id3) = world(frame: 4, rect: narrow)
        Splash.splash(w3, id: id3, mode: 3)
        XCTAssertEqual(w3.player.cues.map { [$0.snd, $0.volume] }, [[406, 0x2d]])
        XCTAssertEqual(w3.particles.counters.count, (0x10 + 8) * 3)
        let (w4, id4) = world(frame: 4, kind: 5)
        Splash.splash(w4, id: id4, mode: 3)
        XCTAssertEqual(w4.player.cues.map { [$0.snd, $0.volume] }, [[605, 0x100]])
        // The gate's edges: frame counter 3; a Platform-handled type ≥ 10 (a type < 10 passes); the centre off view.
        for (fr, handler, type, centre) in [(Int32(3), SpriteHandler.player, Int16(0), SpriteSlot.Point(x: 150, y: 330)),
                                            (4, .platform, 10, SpriteSlot.Point(x: 150, y: 330)),
                                            (4, .player, 0, SpriteSlot.Point(x: 0x271, y: 330)),
                                            (4, .player, 0, SpriteSlot.Point(x: -0x11, y: 330)),
                                            (4, .player, 0, SpriteSlot.Point(x: 150, y: 401)),
                                            (4, .player, 0, SpriteSlot.Point(x: 150, y: -0x11))] {
            let (g, gid) = world(frame: fr, handler: handler, type: type)
            g.active.update(id: gid) { $0.centre = centre }
            Splash.splash(g, id: gid, mode: 3)
            XCTAssertTrue(g.player.cues.isEmpty, "\(fr) \(handler) \(type) \(centre)")
            XCTAssertEqual(g.particles.records[0].vx, -154)
        }
        let (g9, id9) = world(frame: 4, handler: .platform, type: 9)
        g9.active.update(id: id9) { $0.centre = SpriteSlot.Point(x: 0x270, y: 400) }
        Splash.splash(g9, id: id9, mode: 3)
        XCTAssertEqual(g9.player.cues.count, 1)

        // Leaving (mode 4): kind `+0x12a` + 200, at S − 4, only with vy < −0x4b0; the sound needs width > 0x10 only.
        let (l1, lid1) = world(frame: 4)
        l1.active.update(id: lid1) { $0.vy = -0x4b1; $0.previousWaterKind = 2 }
        Splash.splash(l1, id: lid1, mode: 4)
        XCTAssertEqual(l1.player.cues.map { [$0.snd, $0.volume] }, [[406, 0x100]])
        XCTAssertEqual(l1.particles.counters.count, 96)
        XCTAssertEqual(l1.particles.records[0].kind, 202)
        XCTAssertEqual(l1.particles.records[0].y, 188 << 8)
        // vy0 = −600 − R(200) − (short)(−0x4b1 >> 3) = −600 − R + 151.
        var ref3 = FastRand(seed: 1)
        _ = ref3.soundRate()
        let r500 = Int32(ref3.next(500)), r200 = Int32(ref3.next(200))
        XCTAssertEqual(l1.particles.records[0].vx, r500 + (-0x200 >> 4) - 250)
        XCTAssertEqual(l1.particles.records[2].vy, -600 - r200 + 151)
        let (l2, lid2) = world(frame: 4)
        l2.active.update(id: lid2) { $0.vy = -0x4b0 }
        Splash.splash(l2, id: lid2, mode: 4)
        XCTAssertEqual(l2.player.cues.count, 1)
        XCTAssertEqual(l2.particles.counters.count, 0)
        let (l3, lid3) = world(frame: 4, rect: narrow)
        l3.active.update(id: lid3) { $0.vy = -0x2000 }
        Splash.splash(l3, id: lid3, mode: 4)
        XCTAssertEqual(l3.player.cues.count, 0)
        XCTAssertEqual(l3.particles.counters.count, 0)
        XCTAssertEqual(l3.rng.seed, 1)
        // No splash at all without `+0x13e` or a face (the Effect class clears `+0x13e`).
        for change in [{ (s: inout SpriteSlot) in s.splashes = false }, { (s: inout SpriteSlot) in s.face = nil }] {
            let (n, nid) = world(frame: 4)
            n.active.update(id: nid, change)
            Splash.splash(n, id: nid, mode: 3)
            XCTAssertEqual([n.particles.counters.count, Int16(n.player.cues.count)], [0, 0])
            XCTAssertEqual(n.rng.seed, 1)
        }
        var e = SpriteSlot(type: 0x4b1, x: 0, y: 0)
        EffectSprite.setup(&e)
        XCTAssertFalse(e.splashes)
        XCTAssertTrue(SpriteSlot(type: 0, x: 0, y: 0).splashes)
        // `+0x120` stands in when `+0x11c` is 0; a surface cell kind below 200 is raised to 200 (row 12 is dry: kind
        // 0 → 200): W 0, `+0x120` 140 → row (300 + 140 + 16) >> 5 = 14 → dry above → kind 200 at S = 448.
        let (u, uid) = world()
        u.active.update(id: uid) { $0.waterRow = 0; $0.lastWater = 140 }
        Splash.splash(u, id: uid, mode: 3)
        XCTAssertEqual([u.particles.records[0].kind, Int16(u.particles.records[0].y >> 8)], [200, 448])

        // E1a emitter sites. The cannon smoke 0x442's Setup: 45 × (R(2000) vy, R(2000) vx, R(2) shape) →
        // `NewParticle(4, 0x96, (y + 0x18, x + 0x10), R2 + 1, R1 − 1000, R0 − 1000, 0, 1)`.
        let sm = SpriteWorld(level: L, seed: 1)
        var smoke = SpriteSlot(type: 0x442, x: 0, y: 0)
        smoke.oldPosition = SpriteSlot.Point(x: 300, y: 200)
        BackgroundSprite.smokeSetup(sm, &smoke)
        XCTAssertEqual(sm.particles.counters, ParticlePool.Counters(count: 45, hint: 44, highWater: 44))
        var rs = FastRand(seed: 1)
        let (s0, s1, s2) = (Int32(rs.next(2000)), Int32(rs.next(2000)), rs.next(2))
        let p0 = sm.particles.records[0]
        XCTAssertEqual([p0.vy, p0.vx, p0.x, p0.y], [s0 - 1000, s1 - 1000, (300 + 0x10) << 8, (200 + 0x18) << 8])
        XCTAssertEqual([p0.kind, p0.gravity, p0.shape, p0.age, Int16(p0.mode)], [4, 0x96, s2 + 1, 0, 1])
        XCTAssertEqual(smoke.layer, 0x7fbc)
        // `.BoxUW` in the Box tail: left the water this frame (`+0x120 ≠ 0`, `+0x11c == 0` after the SSH copy) →
        // `.Splash(s, 4)` — a 0x30-wide trampoline rising faster than 0x4b0: (0x30 + 8) × 3 particles of kind
        // `+0x12a` + 200.
        func box(_ waterRow: Int32) -> SpriteWorld {
            let (b, _) = world()
            _ = b.newSprite(type: BoxSprite.trampoline, x: 100, y: 300, layer: 5, handler: .box) { s in
                s.x = 100; s.y = 300
                s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x10, right: 0x30)
                s.face = FaceRef(pict: BoxSprite.trampoline, index: 0, set: .encoded)
                s.waterRow = waterRow
                s.previousWaterKind = 1
                s.vy = -0x600
            }
            let id = b.active.sprites.last { $0.type == BoxSprite.trampoline }!.id
            BoxSprite.handle(world: b, id: id)
            return b
        }
        let wet = box(40)
        XCTAssertEqual(wet.particles.counters.count, (0x30 + 8) * 3)
        XCTAssertEqual(wet.particles.records[0].kind, 201)
        XCTAssertEqual(box(0).particles.counters.count, 0)
    }
}
