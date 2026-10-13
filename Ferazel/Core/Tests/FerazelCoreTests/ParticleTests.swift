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
        // Re-taking slot 0 below the hwm keeps it (`if (*psVar3 < iVar6)`, M l. 29944: raised only, never lowered).
        XCTAssertEqual(still(&p, col: 8, row: 8, mode: 0), 0)
        XCTAssertEqual(p.counters, ParticlePool.Counters(count: 3, hint: 0, highWater: 2))
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
        // An unbuilt-row particle (dies at its first draw) already at age 1 — a colour-0 age, so any `.DrawParticles`
        // would kill it — and a blood particle, high in the level's air, mode 0.
        s.world.particles.newParticle(kind: 14, gravity: 0, v: 40, h: 300, shape: 1, vx: 0, vy: 0, delay: -1, mode: 0)
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
        // Iteration 1 is skipped: no `.DrawParticles` → the age-1 kind-14 particle is not colour-killed;
        // `.HandleParticles` still runs (ages 1 → 2 and 0 → 1, the moves), and the parity does not flip.
        let first = s.step(keys: KeyState())
        XCTAssertFalse(first.drawn)
        XCTAssertEqual(kinds(first), ["water0", "sprites", "erase"])
        XCTAssertEqual(s.world.particles.counters, ParticlePool.Counters(count: 2, hint: 1, highWater: 1))
        XCTAssertEqual(s.world.particles.records[0].age, 2)
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
        // The flip is `+0x17e` (l. 32667): mirrored, each row starts at h + 4 and walks left (slots 6…11).
        sc.active.update(id: gid) { $0.glowChance = 100; $0.mirrored = true }
        sc.standardSpriteCleanup(gid, faceWidth: { _ in 4 })
        XCTAssertEqual(sc.particles.records[6..<12].map { Int($0.x >> 8) }, [54, 52, 53, 52, 54, 51])
        // cH is the FRAME's centre (`face +2`, `+6`: 50 + (0 + 4) >> 1 = 52), not the bounds': bounds (0, 2, 4, 8)
        // would make it 55 and send the pixels at 52 and 53 left.
        var shifted = face
        shifted.bounds = [0, 2, 4, 8]
        let gb = SpriteWorld(level: L1, seed: 1)
        ParticleGlow.glow(gb, face: shifted, v: 100, h: 50, kind: 220, chance: 100, flip: false)
        XCTAssertEqual(gb.particles.records.prefix(6).map { $0.vx < 0 }, [true, false, true, false, true, false])
        // The chance test is `R(100) <= chance` (l. 38720): seed 1's first endpoint draws R(4) 1, R(5) 1, R(100) 67,
        // R(150) 7, R(100) 71 — chance 71 still emits it at (101 + 1, 50), vx −(120 + 7).
        let gc = SpriteWorld(level: L1, seed: 1)
        ParticleGlow.glow(gc, face: face, v: 100, h: 50, kind: 220, chance: 71, flip: false)
        let c0 = gc.particles.records[0]
        XCTAssertEqual([c0.x >> 8, c0.y >> 8, c0.vx], [50, 102, -127])
        XCTAssertEqual(c0.age, -3)

        // `.BloodSpray` (M l. 37892–37958) from `.HurtPlayer` (`bl` 100549f4: (player, attacker, 0x28, 500, 0x96, 2)).
        // The player's hot rect (34, 38, 85, 62) at (2000, 1000) and the attacker's (22, 22, 78, 78) there overlap in
        // (1034, 2038, 1078, 2062): start (v, h) = (1034 + 22, 2038 + 12) = (1056, 2050). Victim centre (1059, 2058),
        // attacker centre (1049, 2070): dy = 10, dx = 12, t = 0.833 → tan 35° ≤ t < tan 45° → dir 4 →
        // `FUN_100417bc` case 4: (x, y) = (−0.766·500, 0.643·500) = (−383, 321.5) → `fneg`, `fctiwz`: (383, −321).
        let bw = SpriteWorld(level: L1, seed: 1)
        let pid = try XCTUnwrap(Player.spawn(world: bw, x: 2000, y: 1000))
        bw.playerID = pid
        bw.active.update(id: pid) { s in
            s.x = 2000; s.y = 1000
            s.hp = 0x230
            s.centre = SpriteSlot.Point(x: 2058, y: 1059)
        }
        let aid = try XCTUnwrap(bw.newSprite(type: 0, x: 2000, y: 1000, layer: 10, handler: .background) { s in
            s.x = 2000; s.y = 1000
            s.hotRect = IdleSprites.Rect(top: 22, left: 22, bottom: 78, right: 78)
            s.hp = 1
            s.centre = SpriteSlot.Point(x: 2070, y: 1049)
        })
        XCTAssertEqual(bw.active.record(id: pid)?.hotRect, IdleSprites.Rect(top: 34, left: 38, bottom: 85, right: 62))
        HurtPlayer.hurt(bw, player: pid, attacker: aid, damage: 1, blood: true, invulnerable: 0, coins: 0)
        XCTAssertEqual(bw.particles.counters, ParticlePool.Counters(count: 40, hint: 39, highWater: 39))
        // Per i: delay i >> 3 (count ≤ 0x96); the point first moves halfway to the victim's centre — h (2050 + 2058)
        // >> 1 = 2054, 2056, 2057, 2057 …; v (1056 + 1059) >> 1 = 1057, 1058, 1058 …; then vy = −321 + R(150) − 75
        // (drawn first), vx = 383 + R(150) − 75. Seed 1's R(150): 38, 34, 101, 7, …
        func rec(_ i: Int) -> [Int32] {
            let r = bw.particles.records[i]
            return [r.x >> 8, r.y >> 8, r.vx, r.vy, Int32(r.age), Int32(r.shape), Int32(r.kind), Int32(r.gravity),
                    Int32(r.mode)]
        }
        XCTAssertEqual(rec(0), [2054, 1057, 383 + 34 - 75, -321 + 38 - 75, 0, 4, 2, 0xbe, 1])
        XCTAssertEqual(rec(1), [2056, 1058, 383 + 7 - 75, -321 + 101 - 75, 0, 4, 2, 0xbe, 1])
        XCTAssertEqual(rec(8)[4], -1)
        var rb = FastRand(seed: 1)
        for _ in 0..<78 { _ = rb.next(0x96) }
        let (b78, b79) = (Int32(rb.next(0x96)), Int32(rb.next(0x96)))
        XCTAssertEqual(rec(39), [2057, 1058, 383 + b79 - 75, -321 + b78 - 75, -4, 4, 2, 0xbe, 1])
        // `.FindDesiredDirectionGeneric` by quadrant about p1 = (0, 0) (|t| = 0.5 → the 4th threshold of each table),
        // the equal-coordinates nudge (p2 = p1 → (1, 1): t = −1, not < −1 → 0x20), and a near-horizontal dir 0.
        let o0: (v: Int16, h: Int16) = (0, 0)
        XCTAssertEqual([(-10, 20), (10, 20), (10, -20), (-10, -20), (0, 0), (0, 20)].map { (v: Int16, h: Int16) in
            BloodSpray.direction(target: o0, from: (v, h))
        }, [3, 0x21, 0x15, 0xf, 0x20, 0])
        // `FUN_100417bc`'s signs per quadrant (m 500).
        for (dir, x, y) in [(0, -500, 0), (3, -433, 250), (9, 0, 500), (13, 321.5, 383), (18, 500, 0),
                            (22, 383, -321.5), (27, 0, -500), (32, -383, -321.5), (36, 0, 0)] as [(Int, Float, Float)] {
            let v = BloodSpray.vector(dir, magnitude: 500)
            XCTAssertEqual(v.x, x, accuracy: 0.001, "dir \(dir)")
            XCTAssertEqual(v.y, y, accuracy: 0.001, "dir \(dir)")
        }
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
        // The arithmetic's edges (M l. 37998–38051). vx = R(500) + (−vx_s >> 4) − 250 is an arithmetic shift of the
        // negated int: vx_s 0x201 → −0x201 >> 4 = −33 (a divide would give −32) → 128 − 33 − 250.
        let (o, oid) = world()
        o.active.update(id: oid) { $0.vx = 0x201 }
        Splash.splash(o, id: oid, mode: 3)
        XCTAssertEqual(o.particles.records[0].vx, -155)
        // The column bound is an int sum: x 0x7fd0 runs h 32754 … 32785 (32 columns) — the 15th column, 32768, is
        // stored as the 16-bit −32768 — and the loop ends there.
        let (xe, xeid) = world()
        xe.active.update(id: xeid) { $0.x = 0x7fd0 }
        Splash.splash(xe, id: xeid, mode: 3)
        XCTAssertEqual(xe.particles.counters.count, 96)
        XCTAssertEqual([xe.particles.records[39].x >> 8, xe.particles.records[42].x >> 8], [32767, -32768])
        // The gate's lower edges are inclusive: the centre at (scroll − 0x10, scroll − 0x10) sounds.
        let (e0, eid0) = world(frame: 4)
        e0.active.update(id: eid0) { $0.centre = SpriteSlot.Point(x: -0x10, y: -0x10) }
        Splash.splash(e0, id: eid0, mode: 3)
        XCTAssertEqual(e0.player.cues.map(\.snd), [405])
        // A part-dry grid (BG liquid on `wet(col)` only): the walk's column is the centre `+0x10 >> 5` = 150 >> 5 = 4,
        // not x `+0xc` (100 >> 5 = 3). Column 4 is wet on rows 9…11 only: row 11 → 9 (row 8 dry) → S = 288 (column
        // 3, wet up to row 6, would give 192).
        func reshape(_ w: SpriteWorld, wet: (Int) -> ClosedRange<Int>) {
            var bg = [UInt16](repeating: 0, count: 16 * 16)
            for c in 0..<16 { for r in wet(c) { bg[r * 16 + c] = 1 + 1 } }
            var bgKinds = [Int](repeating: 0, count: 0x60)
            bgKinds[1] = 201
            w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: [UInt16](repeating: 0, count: 256)),
                               bg: TileMap(width: 16, height: 16, cells: bg), fgKinds: Array(0..<0x60),
                               bgKinds: bgKinds)
        }
        let (pc, pcid) = world()
        reshape(pc) { $0 == 4 ? 9...11 : 6...11 }
        Splash.splash(pc, id: pcid, mode: 3)
        XCTAssertEqual([pc.particles.records[0].y >> 8, Int32(pc.particles.records[0].kind)], [288, 201])
        // The start row adds 0x10: W 4 → (300 + 4 + 0x10) >> 5 = 10 (wet; row 9 dry) → S = 320, kind 201 (with
        // + 0xf: row 9, dry → kind 200 at 288).
        let (sf, sfid) = world()
        reshape(sf) { _ in 10...11 }
        sf.active.update(id: sfid) { $0.waterRow = 4 }
        Splash.splash(sf, id: sfid, mode: 3)
        XCTAssertEqual([sf.particles.records[0].y >> 8, Int32(sf.particles.records[0].kind)], [320, 201])
        // `+0x12a` is `+0x128` as `.WrapDrawSprites`' tail copied it (l. 10391): kind 3 drawn, then dry → 203.
        let (pk, pkid) = world(kind: 3)
        _ = pk.active.wrapDrawSprites()
        pk.active.update(id: pkid) { $0.waterKind = 0; $0.vy = -0x4b1 }
        XCTAssertEqual(pk.active.record(id: pkid)?.previousWaterKind, 3)
        Splash.splash(pk, id: pkid, mode: 4)
        XCTAssertEqual(pk.particles.records[0].kind, 203)
        // `.StandardSpriteCleanup`'s own exit splash (l. 32645, the default `exitSplash`): left the water this frame
        // (`+0x120` 40, `+0x11c` 0), rising faster than 0x4b0 → the 96 leaving particles at S − 4 = 188.
        let (sc, scid) = world()
        sc.active.update(id: scid) { $0.waterRow = 0; $0.lastWater = 40; $0.vy = -0x4b1 }
        sc.standardSpriteCleanup(scid, faceWidth: { _ in 4 })
        XCTAssertEqual(sc.particles.counters.count, 96)
        XCTAssertEqual(sc.particles.records[0].y, 188 << 8)

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
        func box(_ waterRow: Int32, gate: (lastWater: Int32, waterRow: Int32)? = nil) -> SpriteWorld {
            let (b, _) = world()
            _ = b.newSprite(type: BoxSprite.trampoline, x: 100, y: 300, layer: 5, handler: .box) { s in
                s.x = 100; s.y = 300
                s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x10, right: 0x30)
                s.face = FaceRef(pict: BoxSprite.trampoline, index: 0, set: .encoded)
                s.waterRow = waterRow
                if let gate {
                    // `+0x118` ≥ 0x1d: `.StandardSpriteHandles` skips its `+0x120 ← +0x11c`, `+0x11c = 0`.
                    s.waterGate = 0x1d
                    s.lastWater = gate.lastWater
                    s.waterRow = gate.waterRow
                }
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
        // `.BoxUW` also needs `+0x11c == 0` (M l. 59994): still in the water (`+0x120` 40, `+0x11c` 40) → no splash.
        XCTAssertEqual(box(0, gate: (40, 40)).particles.counters.count, 0)
        XCTAssertEqual(box(0, gate: (40, 0)).particles.counters.count, (0x30 + 8) * 3)
    }

    // MARK: - E1b: `.FillCachedTileArray @ 10010d30` / `.WrapDrawWaterEffects @ 10010fac`

    /// A liquid cache record (BG kind `bg`, liquid kind bg − 200), FG empty, no wind.
    private func liquid(_ bg: Int32, above: Int32 = 0, bubbleV: Int32 = 650, depth: Int32 = 1,
                        fg: Int32 = -1, fgKind: Int32 = -1, o1: Int32 = -1) -> WaterEffects.Cell {
        var e = WaterEffects.Cell()
        e.fgTile = fg
        e.fgKind = fgKind
        e.bgKind = bg
        e.isWater = UnderWater.isWaterTile(Int(bg)) ? 1 : 0
        e.waterKind = bg - 200
        e.waterAbove = above
        e.overlay1 = o1
        e.overlay2 = -1
        e.bubbleV = bubbleV
        e.depth = depth
        return e
    }

    private func env(_ effects: Int16 = 1, parity: Bool = false, submerged: UInt8 = 0, current: Int16 = 550,
                     surface: UInt8 = 0) -> WaterEffects.Env {
        WaterEffects.Env(effects: effects, parity: parity, submergedFaces: submerged, current: current,
                         surfaceFlag: surface)
    }

    /// One visible cell (`WaterEffects.cell`) at (col, row) under drawn v `scrollV`, from seed `seed`.
    private func one(_ e: WaterEffects.Cell, col: Int = 60, row: Int = 19, scrollV: Int = 0,
                     env: WaterEffects.Env, seed: Int32, s: Int = -1, dustShape: Int16 = 0)
        -> (pool: ParticlePool, rng: FastRand, face: WaterFaceDraw?, dustShape: Int16) {
        var rng = FastRand(seed: seed)
        var pool = ParticlePool()
        var shape = dustShape
        let f = WaterEffects.cell(e, col: col, row: row, scrollV: scrollV, env: env, overlay2: { s }, rng: &rng,
                                  particles: &pool, dustShape: &shape)
        return (pool, rng, f, shape)
    }

    /// The draws `ns` from `seed` (the reference stream).
    private func draws(_ seed: Int32, _ ns: [Int16]) -> (values: [Int], after: Int32) {
        var r = FastRand(seed: seed)
        let v = ns.map { Int(r.next($0)) }
        return (v, r.seed)
    }

    /// The first seed ≥ 1 whose draw `index` of `ns` falls in `range`.
    private func seed(_ ns: [Int16], _ index: Int, in range: Range<Int>) -> Int32 {
        var s: Int32 = 1
        while !range.contains(draws(s, ns).values[index]) { s += 1 }
        return s
    }

    func testMoteVelocityLevel1() throws {
        let res = try resources()
        let L1 = try LevelFile.load(from: res, level: 1)
        // Level 1: current hdr 0x2714 = 550, the surface flag 0x26c9 and 0x26c6 clear.
        XCTAssertEqual([Int(L1.header.waterCurrent), Int(L1.header.waterSurfaceEffect), Int(L1.header.submergedFaces)],
                       [550, 0, 0])
        let x = 60 * 32, y = 19 * 32

        // Motes (raw `10011270..100113f4`), kind 200 at (60, 19): h = x + 2 + R(28), v = y + 2 + R(28), R(100) < 28 →
        // vx = 550 + R(275) − 137, kind −210, shape 7, gravity 0, vy 0, mode 3, delay 0.
        let moteDraws: [Int16] = [28, 28, 100, 275]
        let s1 = seed(moteDraws, 2, in: 0..<28)
        let d1 = draws(s1, moteDraws)
        let m = one(liquid(200), env: env(current: L1.header.waterCurrent), seed: s1)
        let p = m.pool.records[0]
        XCTAssertEqual(m.pool.counters, ParticlePool.Counters(count: 1, hint: 0, highWater: 0))
        XCTAssertEqual([Int(p.kind), Int(p.shape), Int(p.gravity), Int(p.vy), Int(p.mode), Int(p.age)], [-210, 7, 0, 0, 3, 0])
        XCTAssertEqual(Int(p.vx), 550 + d1.values[3] - 137)
        XCTAssertEqual([Int(p.x >> 8), Int(p.y >> 8)], [x + 2 + d1.values[0], y + 2 + d1.values[1]])
        XCTAssertEqual(m.rng.seed, d1.after)
        XCTAssertNil(m.face)
        // The seeded case, pinned.
        XCTAssertEqual([Int(s1), Int(p.vx), Int(p.x >> 8), Int(p.y >> 8)], [3, 452, 1943, 629])
        // The range over 3000 seeds: 550 ± 137, both ends reached.
        var vxs = Set<Int32>()
        for sd: Int32 in 1...3000 {
            let r = one(liquid(200), env: env(), seed: sd)
            if r.pool.counters.count == 1 { vxs.insert(r.pool.records[0].vx) }
        }
        XCTAssertEqual([vxs.min(), vxs.max()], [413, 687])
        // A negative current: vx = c − (R(|c| >> 1) − (|c| >> 2)) → −550 ± 137; odd currents pin the shifts
        // (7: 7 + R(3) − 1 ∈ 6…8; −7: −7 − (R(3) − 1) ∈ −8…−6 — an arithmetic −7 >> 1 would draw R(−4)).
        for (c, want) in [(Int16(-550), [-687, -413]), (7, [6, 7, 8]), (-7, [-8, -7, -6])] as [(Int16, [Int32])] {
            var got = Set<Int32>()
            for sd: Int32 in 1...3000 {
                let r = one(liquid(200), env: env(current: c), seed: sd)
                if r.pool.counters.count == 1 { got.insert(r.pool.records[0].vx) }
            }
            XCTAssertEqual(c == -550 ? [got.min()!, got.max()!] : got.sorted(), want, "current \(c)")
        }
        // Chance 28 at Effects 1, 22 at Effects 2 (a third draw of 22…27 emits only at 1); 28 itself emits nothing.
        let s22 = seed(moteDraws, 2, in: 22..<28), s28 = seed(moteDraws, 2, in: 28..<29)
        XCTAssertEqual(one(liquid(200), env: env(1), seed: s22).pool.counters.count, 1)
        let e2 = one(liquid(200), env: env(2), seed: s22)
        XCTAssertEqual(e2.pool.counters.count, 0)
        XCTAssertEqual(e2.rng.seed, draws(s22, [28, 28, 100]).after)       // no R(275) without the particle
        XCTAssertEqual(one(liquid(200), env: env(1), seed: s28).pool.counters.count, 0)
        XCTAssertEqual(one(liquid(200), env: env(2), seed: seed(moteDraws, 2, in: 0..<22)).pool.counters.count, 1)
        // Effects 3: no emitter runs — no draw at all.
        XCTAssertEqual(one(liquid(200), env: env(3), seed: s1).rng.seed, s1)
        // Current 0: shape 1, vx 0, no velocity draw. Kind 203 (healing) ignores the current: −213, shape 1, vx 0.
        let z = one(liquid(200), env: env(current: 0), seed: s1)
        XCTAssertEqual([Int(z.pool.records[0].shape), Int(z.pool.records[0].vx)], [1, 0])
        XCTAssertEqual(z.rng.seed, draws(s1, [28, 28, 100]).after)
        // 203 also bubbles (liquid kind 3) first: R(24), R(200), R(100), then the mote's draws.
        let healDraws: [Int16] = [24, 200, 100, 28, 28, 100]
        let sh = seed(healDraws, 5, in: 0..<28)
        let hd = draws(sh, healDraws)
        let heal = one(liquid(203, depth: 1), env: env(), seed: sh)
        let motes = heal.pool.records.prefix(Int(heal.pool.counters.count)).filter { $0.kind == -213 }
        XCTAssertEqual(motes.map { [Int($0.shape), Int($0.vx), Int($0.vy)] }, [[1, 0, 0]])
        XCTAssertEqual(heal.rng.seed, hd.after)
        // 205: kind −215, shape 4, vy = R(64) + 160 drawn after the current's.
        let lavaDraws: [Int16] = [28, 28, 100, 275, 64]
        let sl = seed(lavaDraws, 2, in: 0..<28)
        let ld = draws(sl, lavaDraws)
        let lava = one(liquid(205), env: env(), seed: sl).pool.records[0]
        XCTAssertEqual([Int(lava.kind), Int(lava.shape), Int(lava.vx), Int(lava.vy)],
                       [-215, 4, 550 + ld.values[3] - 137, ld.values[4] + 160])
        // Acid 201 makes no mote (bubbles only, below).
        XCTAssertFalse(one(liquid(201), env: env(), seed: s1).pool.records.contains { $0.alive && $0.kind == -211 })

        // Bubbles (raw `10011170..1001126c`), liquid kinds 1…4 with (`+0x10` = 0 or row < drawn v px): h = x + 4 +
        // R(24), v = `+0x24`; kinds 1, 2: vy = −500 − R(300), gravity −20; 3: −300 − R(200), −5; 4: 0, 0 (no draw);
        // R(100) < chance → kind −bg, shape 2, vx 0, mode 3.
        let acidDraws: [Int16] = [24, 300, 100]
        let sa = seed(acidDraws, 2, in: 0..<18)
        let ad = draws(sa, acidDraws)
        for bg: Int32 in [201, 202] {
            let b = one(liquid(bg), env: env(), seed: sa)
            let r = b.pool.records[0]
            XCTAssertEqual([Int(r.kind), Int(r.shape), Int(r.gravity), Int(r.vx), Int(r.vy), Int(r.mode)],
                           [-Int(bg), 2, -20, 0, -500 - ad.values[1], 3], "bg \(bg)")
            XCTAssertEqual([Int(r.x >> 8), Int(r.y >> 8)], [x + 4 + ad.values[0], 650])
            XCTAssertEqual(b.rng.seed, ad.after)
        }
        XCTAssertEqual([Int(sa), ad.values[0], ad.values[1]], [3, 18, 207])
        let healBubble = heal.pool.records.prefix(Int(heal.pool.counters.count)).filter { $0.kind == -203 }
        if hd.values[2] < 24 {
            XCTAssertEqual(healBubble.map { [Int($0.gravity), Int($0.vy)] }, [[-5, -300 - hd.values[1]]])
        } else {
            XCTAssertEqual(healBubble.count, 0)
        }
        let s3 = seed([24, 200, 100], 2, in: 0..<24)
        let b3 = one(liquid(203), env: env(), seed: s3).pool.records[0]
        XCTAssertEqual([Int(b3.kind), Int(b3.gravity), Int(b3.vy)], [-203, -5, -300 - draws(s3, [24, 200, 100]).values[1]])
        let s4 = seed([24, 100], 1, in: 0..<24)
        let b4 = one(liquid(204), env: env(), seed: s4)
        XCTAssertEqual([Int(b4.pool.records[0].kind), Int(b4.pool.records[0].gravity), Int(b4.pool.records[0].vy)],
                       [-204, 0, 0])
        XCTAssertEqual(b4.rng.seed, draws(s4, [24, 100]).after)
        // The chance: 24 at Effects 1, 18 at Effects 2; depth `+0x28` > 4 divides it by (depth − 4): 6 → 12 (9 at
        // Effects 2), 7 → 8, 5 → 24, 4 → 24.
        func emits(_ effects: Int16, depth: Int32, third: Int) -> Bool {
            let sd = seed(acidDraws, 2, in: third..<(third + 1))
            return one(liquid(201, depth: depth), env: env(effects), seed: sd).pool.counters.count == 1
        }
        XCTAssertEqual([emits(1, depth: 1, third: 23), emits(1, depth: 1, third: 24), emits(2, depth: 1, third: 17),
                        emits(2, depth: 1, third: 18)], [true, false, true, false])
        XCTAssertEqual([emits(1, depth: 6, third: 11), emits(1, depth: 6, third: 12), emits(2, depth: 6, third: 8),
                        emits(2, depth: 6, third: 9)], [true, false, true, false])
        XCTAssertEqual([emits(1, depth: 7, third: 7), emits(1, depth: 7, third: 8), emits(1, depth: 5, third: 23),
                        emits(1, depth: 4, third: 23)], [true, false, true, true])
        // The row-vs-pixel gate (raw `10011150..1001115c`): liquid above (`+0x10` 1) blocks the bubble only while
        // the cell's ROW is ≥ the drawn v in PIXELS — row 19 under v 19 px: no draw at all; under v 20 px (still
        // tile row 0 on screen): the bubble's draws happen.
        XCTAssertEqual(one(liquid(201, above: 1), scrollV: 19, env: env(), seed: sa).rng.seed, sa)
        XCTAssertEqual(one(liquid(201, above: 1), scrollV: 20, env: env(), seed: sa).rng.seed, ad.after)
        XCTAssertEqual(one(liquid(201, above: 1), scrollV: 20, env: env(), seed: sa).pool.counters.count, 1)
        // Gates: Effects 3, a dry cell, a negative BG kind.
        XCTAssertEqual(one(liquid(201), env: env(3), seed: sa).rng.seed, sa)
        var dry = liquid(201)
        dry.isWater = 0
        XCTAssertEqual(one(dry, env: env(), seed: sa).rng.seed, sa)
        var negative = liquid(201)
        negative.bgKind = -1
        XCTAssertEqual(one(negative, env: env(), seed: sa).rng.seed, sa)

        // Wind dust (raw `100114ec..10011680`): 0 ≤ overlay 1 < 0x24, s = overlay 2: R(100) < min((s >> 1) + 20, 65)
        // → R(s), impulse `.LookupModedImpulse((o1 + 18) mod 36, 15·s + R(s))`, h = x + R(27) + 3, v = y + R(27) + 3,
        // the shape, R(100) > 50 → `local_6a`; kind 10, mode 2.
        let dustDraws: [Int16] = [100, 10, 27, 27, 100]
        let sd0 = seed(dustDraws, 0, in: 0..<25)
        var sd = sd0
        while draws(sd, dustDraws).values[0] >= 25 || draws(sd, dustDraws).values[4] > 50 { sd += 1 }
        let dd = draws(sd, dustDraws)
        let dust = one(liquid(0, o1: 0), env: env(), seed: sd, s: 10)
        let q = dust.pool.records[0]
        XCTAssertEqual([Int(q.kind), Int(q.shape), Int(q.gravity), Int(q.vx), Int(q.vy), Int(q.mode)],
                       [10, 7, 0, 150 + dd.values[1], 0, 2])
        XCTAssertEqual([Int(q.x >> 8), Int(q.y >> 8)], [x + dd.values[2] + 3, y + dd.values[3] + 3])
        XCTAssertEqual(dust.rng.seed, dd.after)
        // The chance: s 10 → 25; s 88 → 64; s 90 and 100 → 65 (capped).
        func dusts(_ s: Int, first: Int) -> Bool {
            let k = seed([100], 0, in: first..<(first + 1))
            return one(liquid(0, o1: 0), env: env(), seed: k, s: s).pool.counters.count == 1
        }
        XCTAssertEqual([dusts(10, first: 24), dusts(10, first: 25), dusts(88, first: 63), dusts(88, first: 64),
                        dusts(90, first: 64), dusts(90, first: 65), dusts(100, first: 64), dusts(100, first: 65)],
                       [true, false, true, false, true, false, true, false])
        // The shape by direction o1 (last draw ≤ 50), surface flag 0 → 1, set → 2; the last draw > 50 → `local_6a`.
        let shapes: [Int32: Int16] = [0: 7, 2: 7, 3: 1, 6: 1, 7: 4, 11: 4, 12: 1, 15: 1, 16: 7, 20: 7, 21: 1, 24: 1,
                                      25: 4, 29: 4, 30: 1, 33: 1, 34: 7, 35: 7]
        let sHigh = { () -> Int32 in
            var k: Int32 = 1
            while draws(k, dustDraws).values[0] >= 25 || draws(k, dustDraws).values[4] <= 50 { k += 1 }
            return k
        }()
        for (o1, shape) in shapes {
            XCTAssertEqual(one(liquid(0, o1: o1), env: env(), seed: sd, s: 10).pool.records[0].shape, shape, "o1 \(o1)")
            XCTAssertEqual(one(liquid(0, o1: o1), env: env(surface: 1), seed: sd, s: 10).pool.records[0].shape,
                           shape == 1 ? 2 : shape, "o1 \(o1)")
            let hi = one(liquid(0, o1: o1), env: env(), seed: sHigh, s: 10, dustShape: 9)
            XCTAssertEqual(hi.pool.records[0].shape, shape == 1 ? 1 : 9, "o1 \(o1)")
            XCTAssertEqual(hi.dustShape, shape == 1 ? 1 : 9)
        }
        // The last draw's edge: 50 keeps the direction's shape, 51 takes `local_6a`.
        for (last, shape) in [(50, Int16(7)), (51, 9)] {
            var k: Int32 = 1
            while draws(k, dustDraws).values[0] >= 25 || draws(k, dustDraws).values[4] != last { k += 1 }
            XCTAssertEqual(one(liquid(0, o1: 0), env: env(), seed: k, s: 10, dustShape: 9).pool.records[0].shape, shape)
        }
        XCTAssertEqual(one(liquid(0, o1: -1), env: env(), seed: sd, s: 10).rng.seed, sd)
        XCTAssertEqual(one(liquid(0, o1: 36), env: env(), seed: sd, s: 10).rng.seed, sd)
        // Directions: o1 18 → mode 0 (h − a), 9 → 27 (v − a), 27 → 9 (v + a), 1 → 19 (h + 0.985a, v − 0.174a).
        let a = 150 + dd.values[1]
        for (o1, vx, vy) in [(Int32(18), -a, 0), (9, 0, -a), (27, 0, a),
                             (1, Int(Double(a) * 0.985), -Int(Double(a) * 0.174))] {
            let r = one(liquid(0, o1: o1), env: env(), seed: sd, s: 10).pool.records[0]
            XCTAssertEqual([Int(r.vx), Int(r.vy)], [vx, vy], "o1 \(o1)")
        }
        // `.LookupModedImpulse` (raw `100404a4`): (v, h) from base (0, 0); `fctiwz` truncates toward zero.
        let imp: [(Int16, Int16, Int16, Int16)] = [(0, 100, 0, -100), (1, 100, 17, -98), (3, 5, 2, -4), (4, 100, 64, -76),
                                                   (9, 100, 100, 0), (10, 100, 98, 17), (13, 100, 76, 64),
                                                   (18, 100, 0, 100), (19, 100, -17, 98), (22, 100, -64, 76),
                                                   (27, 100, -100, 0), (28, 100, -98, -17), (35, 100, -17, -98),
                                                   (36, 100, 0, 0), (-1, 100, 0, 0), (20, -50, 17, -47)]
        for (mode, amount, v, h) in imp {
            let r = WaterEffects.lookupModedImpulse(mode: mode, amount: amount)
            XCTAssertEqual([r.v, r.h], [v, h], "mode \(mode) amount \(amount)")
        }

        // `.FillCachedTileArray`: a 16×16 grid, BG liquid kind 201 at column 3 rows 2…9, FG solid 0x50 at (0, 6).
        func grid(liquidRows: ClosedRange<Int>, solidAt: (Int, Int)?) -> TileGrid {
            var fg = [UInt16](repeating: 0, count: 256)
            if let (c, r) = solidAt { fg[r * 16 + c] = 0x50 + 1 }
            fg[2 * 16 + 3] = 5 + 1
            var bg = [UInt16](repeating: 0, count: 256)
            for r in liquidRows { bg[r * 16 + 3] = 1 + 1 }
            var kinds = [Int](repeating: 0, count: 0x60)
            kinds[1] = 201
            var fgKinds = Array(0..<0x60)
            fgKinds[5] = 0x44
            return TileGrid(fg: TileMap(width: 16, height: 16, cells: fg), bg: TileMap(width: 16, height: 16, cells: bg),
                            fgKinds: fgKinds, bgKinds: kinds)
        }
        var cache = WaterEffects()
        var valid = false
        cache.fill(col: 0, row: 0, tiles: grid(liquidRows: 2...9, solidAt: (0, 6)),
                   overlay: { c, r in (c == 3 && r == 2 ? 7 : -1, c == 3 && r == 2 ? 40 : -1) }, height: 16, valid: &valid)
        XCTAssertTrue(valid)
        XCTAssertEqual([cache.originCol, cache.originRow], [0, 0])
        let c32 = cache.cells[2 * 21 + 3]
        XCTAssertEqual([c32.fgTile, c32.fgKind, c32.bgKind, c32.isWater, c32.waterAbove, c32.waterKind, c32.bgKindAbove,
                        c32.overlay1, c32.overlay2], [5, 0x44, 201, 1, 0, 1, -1, 7, 40])
        // The depth walk tests the liquid at row r + the window row index and the solid at the ORIGIN column:
        // (3, 2) walks rows 4…8 for liquid, meets the solid at (0, 6) → `+0x24` (6 − 1)·32 + 50 = 210, `+0x28` 6;
        // (3, 3) → 210, 5; (3, 9) tests row 18 (clamped 15, dry) → no step: 8·32 + 50 = 306, 1.
        XCTAssertEqual([c32.bubbleV, c32.depth], [210, 6])
        XCTAssertEqual([cache.cells[3 * 21 + 3].bubbleV, cache.cells[3 * 21 + 3].depth, cache.cells[3 * 21 + 3].waterAbove],
                       [210, 5, 1])
        XCTAssertEqual([cache.cells[9 * 21 + 3].bubbleV, cache.cells[9 * 21 + 3].depth], [306, 1])
        // Without the solid: (3, 2) steps while rows 4…9 are liquid: r 2 → 8 (row 10 dry), depth 7 → 7·32 + 50 = 274.
        cache.fill(col: 0, row: 0, tiles: grid(liquidRows: 2...9, solidAt: nil), overlay: { _, _ in (-1, -1) },
                   height: 16, valid: &valid)
        XCTAssertEqual([cache.cells[2 * 21 + 3].bubbleV, cache.cells[2 * 21 + 3].depth], [274, 7])
        // A dry refill keeps `+0x24`/`+0x28` (written only for liquid kinds 1…4).
        cache.fill(col: 0, row: 0, tiles: grid(liquidRows: 12...12, solidAt: nil), overlay: { _, _ in (-1, -1) },
                   height: 16, valid: &valid)
        XCTAssertEqual([cache.cells[2 * 21 + 3].bubbleV, cache.cells[2 * 21 + 3].depth, cache.cells[2 * 21 + 3].waterKind],
                       [274, 7, -201])
        // Origin row ≥ hdr 0xb282 (16): every step ends the walk with r − 2 — (3, ri 0) at origin row 16 (clamped
        // reads): r 16 → 17 → 15, depth 2 → 14·32 + 50 = 498.
        cache.fill(col: 0, row: 16, tiles: grid(liquidRows: 10...15, solidAt: nil), overlay: { _, _ in (-1, -1) },
                   height: 16, valid: &valid)
        XCTAssertEqual([cache.cells[3].bubbleV, cache.cells[3].depth], [498, 2])

        // `.SetScrollLocation`'s clamp of the drawn pair.
        for (h, v, dh, dv) in [(-5, -5, 0, 0), (0x3d9f, 0x3e7f, 0x3d9f, 0x3e7f), (0x3da0, 0x3e80, 0x3da0, 16000),
                               (0x3da1, 0x3e81, 0x3da0, 16000)] {
            let d = WaterEffects.drawnPair(h: h, v: v)
            XCTAssertEqual([d.h, d.v], [dh, dv], "\(h) \(v)")
        }

        // The walk's window and bounds: rows v / 32 … + 13, columns h / 32 … + 20 (C division), the cache stepped from
        // its base; cells outside the grid skipped. Every cell liquid 200 with FG 0x50, the tile = its cache index.
        var w = WaterEffects()
        for i in w.cells.indices { w.cells[i] = liquid(200, fg: Int32(i % 0x5f), fgKind: 0x50) }
        var rng = FastRand(seed: 1)
        var pool = ParticlePool()
        func faces(_ h: Int, _ v: Int, width: Int, height: Int) -> [WaterFaceDraw] {
            w.walk(scroll: (h, v), width: width, height: height, env: env(1, parity: true), overlay2: { _, _ in -1 },
                   rng: &rng, particles: &pool)
        }
        XCTAssertEqual(faces(0, 0, width: 200, height: 50).count, 21 * 14)
        XCTAssertEqual(faces(0, 0, width: 3, height: 2).map { [$0.cellX, $0.cellY, Int($0.tile)] },
                       [[0, 0, 0], [1, 0, 1], [2, 0, 2], [0, 1, 21], [1, 1, 22], [2, 1, 23]])
        XCTAssertEqual(faces(-64, -33, width: 3, height: 1).map { [$0.cellX, $0.cellY, Int($0.tile)] },
                       [[0, 0, 23], [1, 0, 24], [2, 0, 25]])
        XCTAssertEqual(faces(32 * 190 + 31, 32 * 40, width: 200, height: 50).map(\.cellX).max(), 199)
        XCTAssertEqual(faces(32 * 190 + 31, 32 * 40, width: 200, height: 50).count, 10 * 10)

        // Level 1 at the pool under the start ledge (rows 19–20, cols 56–81; drawn pair (1792, 320), seed 1): the
        // refill, the motes (kind −210, shape 7, 550 ± 137) and, the parity clear, no face.
        let world = SpriteWorld(level: L1, seed: 1)
        var we = WaterEffects()
        XCTAssertTrue(we.run(world: world, h: 1792, v: 320, effects: 1).isEmpty)
        XCTAssertTrue(world.player.tileCacheValid)
        XCTAssertEqual([we.originCol, we.originRow], [56, 10])
        let made = world.particles.records.prefix(Int(world.particles.counters.count))
        XCTAssertGreaterThan(made.count, 0)
        XCTAssertEqual(Set(made.map(\.kind)), [-210])
        XCTAssertEqual(Set(made.map(\.shape)), [7])
        XCTAssertTrue(made.allSatisfy { (413...687).contains($0.vx) })
        XCTAssertEqual([made.count, Int(made[0].vx), Int(made[0].x >> 8), Int(made[0].y >> 8), Int(world.rng.seed)],
                       [11, 417, 1873, 611, 382_955_828])
        // The parity set: the Enhanced faces of the visible liquid cells with 0 ≤ FG kind < 0x60 and FG < 0x5f.
        world.parity = true
        let l1faces = we.run(world: world, h: 1792, v: 320, effects: 1)
        func expected(cols: ClosedRange<Int>) -> [WaterFaceDraw] {
            var out: [WaterFaceDraw] = []
            for row in 10...23 {
                for col in cols {
                    let t = world.tiles.fgTile(col: col, row: row), k = world.tiles.fgKind(tile: t)
                    let b = world.tiles.bgKind(tile: world.tiles.bgTile(col: col, row: row))
                    if UnderWater.isWaterTile(b) && t < 0x5f && k >= 0 && k < 0x60 {
                        out.append(WaterFaceDraw(cellX: col, cellY: row, tile: Int16(t), waterKind: Int16(b - 200)))
                    }
                }
            }
            return out
        }
        let want = expected(cols: 56...76)
        XCTAssertEqual(l1faces, want)
        XCTAssertEqual(l1faces.count, 22)
        // The cache is not refilled while the origin and the flag hold — a map write leaves it stale — but is after
        // `.DestroyCrunchTile` clears the flag, and when the drawn pair crosses a tile.
        world.tiles.bgKinds = world.tiles.bgKinds.map { $0 == 200 ? 0 : $0 }
        XCTAssertEqual(we.run(world: world, h: 1792 + 31, v: 320 + 31, effects: 1), want)
        world.player.tileCacheValid = false
        XCTAssertEqual(we.run(world: world, h: 1792, v: 320, effects: 1), [])
        world.tiles = TileGrid(level: L1)
        XCTAssertEqual(we.run(world: world, h: 1792, v: 320, effects: 1), [])      // origin and flag hold: stale
        XCTAssertEqual(we.run(world: world, h: 1792 + 32, v: 320, effects: 1), expected(cols: 57...77))
        XCTAssertEqual([we.originCol, we.originRow], [57, 10])
    }

    func testWaterFaceParity() throws {
        let res = try resources()
        // Level 1 with one BG tile's kind made liquid 200 (no liquid shows at the start otherwise) — the BG tile of the
        // first start-window cell (row-major) whose FG tile is 0…0x5e with FG kind 0…0x5f: the Enhanced faces are the
        // window's cells over that tile with such an FG. Set before the first iteration (the cache fills then).
        func session(_ prefs: FerazelPrefs, carry: LevelCarry = LevelCarry()) throws -> (FerazelSession, [WaterFaceDraw]) {
            let s = try FerazelSession(resources: res, prefs: prefs, level: 1, carry: carry)
            func qualifies(_ col: Int, _ row: Int) -> Bool {
                let t = s.world.tiles.fgTile(col: col, row: row), k = s.world.tiles.fgKind(tile: t)
                return s.world.tiles.bgTile(col: col, row: row) >= 0 && t >= 0 && t < 0x5f && k >= 0 && k < 0x60
            }
            let first = (0..<14 * 21).first { qualifies($0 % 21, $0 / 21) }!
            let b = s.world.tiles.bgTile(col: first % 21, row: first / 21)
            XCTAssertEqual([first, b], [3, 92])
            s.world.tiles.bgKinds[b] = 200
            var want: [WaterFaceDraw] = []
            for row in 0..<14 {
                for col in 0..<21 {
                    let t = s.world.tiles.fgTile(col: col, row: row), k = s.world.tiles.fgKind(tile: t)
                    if s.world.tiles.bgTile(col: col, row: row) == b && t < 0x5f && k >= 0 && k < 0x60 {
                        want.append(WaterFaceDraw(cellX: col, cellY: row, tile: Int16(t), waterKind: 0))
                    }
                }
            }
            return (s, want)
        }
        func faces(_ ops: FrameOps) -> [WaterFaceDraw]? {
            ops.draws.compactMap { if case .wrapDrawWaterEffects(let l) = $0 { l } else { nil } }.first
        }
        // Effects 1, every iteration drawn: the faces on iterations 2, 4, 6, 8 (parity set before the flip).
        let (s, want) = try session(FerazelPrefs())
        XCTAssertGreaterThan(want.count, 0)
        XCTAssertEqual(want.count, 12)
        var got: [Bool] = []
        for _ in 0..<8 {
            let before = s.world.parity
            let ops = s.step(keys: KeyState())
            let f = faces(ops)
            XCTAssertLessThan(s.camera.scrollH, 32)
            XCTAssertLessThan(s.camera.scrollV, 32)
            XCTAssertEqual(f, before ? want : [])
            XCTAssertEqual(s.world.parity, !before)
            got.append(!(f ?? []).isEmpty)
        }
        XCTAssertEqual(got, [false, true, false, true, false, true, false, true])
        // The op sits after the tile layer's lights and before the sprites (l. 9203–9207).
        let order = s.step(keys: KeyState()).draws.compactMap { op -> String? in
            switch op {
            case .drawLightsOntoTiles: return "lights"
            case .wrapDrawWaterEffects: return "water"
            case .wrapDrawSprites: return "sprites"
            case .drawParticles: return "particles"
            default: return nil
            }
        }
        XCTAssertEqual(order, ["lights", "water", "sprites", "particles"])
        // "Reduce frame rate": the call runs on skipped iterations too (outside `.PaintFrameWrap`'s `param_1` block)
        // with the parity it did not flip — faces on skipped 3, 7 and drawn 4, 8; none on 1, 2, 5, 6.
        var reduce = FerazelPrefs()
        reduce.reduceFrameRate = 1
        let (r, rwant) = try session(reduce)
        var pattern: [String] = []
        for _ in 0..<8 {
            let before = r.world.parity
            let ops = r.step(keys: KeyState())
            XCTAssertEqual(faces(ops), before ? rwant : [])
            XCTAssertEqual(r.world.parity, ops.drawn ? !before : before)
            pattern.append((ops.drawn ? "D" : "s") + ((faces(ops) ?? []).isEmpty ? "" : "+"))
        }
        XCTAssertEqual(pattern, ["s", "D", "s+", "D+", "s", "D", "s+", "D+"])
        // Effects 2 and 3: no face ever (and Effects 3 runs no emitter).
        for effects: Int16 in [2, 3] {
            var p = FerazelPrefs()
            p.effects = effects
            let (e, _) = try session(p)
            for _ in 0..<4 { XCTAssertEqual(faces(e.step(keys: KeyState())), [], "Effects \(effects)") }
        }
        // The parity runs on from the previous level (`LevelCarry`): set → faces on iteration 1.
        let (c, cwant) = try session(FerazelPrefs(), carry: LevelCarry(parity: true))
        XCTAssertEqual(faces(c.step(keys: KeyState())), cwant)
        // hdr 0x26c6 ≠ 0 (only level 11 ships it): no face.
        var e = liquid(200, fg: 5, fgKind: 5)
        XCTAssertEqual(one(e, env: env(parity: true), seed: 1).face,
                       WaterFaceDraw(cellX: 60, cellY: 19, tile: 5, waterKind: 0))
        XCTAssertNil(one(e, env: env(parity: true, submerged: 1), seed: 1).face)
        XCTAssertNil(one(e, env: env(parity: false), seed: 1).face)
        XCTAssertNil(one(e, env: env(2, parity: true), seed: 1).face)
        XCTAssertNil(one(e, env: env(3, parity: true), seed: 1).face)
        // FG tile < 0x5f; 0 ≤ FG kind < 0x60; a liquid cell; the liquid kind rides along.
        for (fg, kind, liquidCell, wanted) in [(Int32(0x5e), Int32(0x5e), true, true), (0x5f, 0x5f, true, false),
                                               (5, 0x5f, true, true), (5, 0x60, true, false), (5, -1, true, false),
                                               (5, 0, true, true), (5, 5, false, false)] {
            e = liquid(liquidCell ? 201 : 0, fg: fg, fgKind: kind)
            let f = one(e, env: env(parity: true), seed: 1).face
            XCTAssertEqual(f, wanted ? WaterFaceDraw(cellX: 60, cellY: 19, tile: Int16(fg), waterKind: 1) : nil,
                           "fg \(fg) kind \(kind) \(liquidCell)")
        }
    }
}
