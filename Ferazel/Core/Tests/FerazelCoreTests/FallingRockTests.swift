import XCTest
@testable import FerazelCore

/// 6A-FR (docs/superpowers/plans/2026-11-04-ferazel-remainder.md; phase6-engine-contracts §2.12, phase6-boss-contracts
/// §2.7): the falling rocks' arm of `.HitPlayerSprite`'s Box branch (M l. 49170–49188). A 0x434 with `+0x160 < 0`
/// returns at once; a 0x433 / 0x434 with `+0x160 ≥ 0` whose centre y (`+0xe`, short) is strictly above the player's
/// and whose vy (`+0x2c`) is above 599 → `.HurtPlayer(player, rock, 0x38 / 0x70, 1, 0x1e / 0x3c, 0)` + `.KillBox(rock)`
/// and return; every other case falls through to the rest of the Box arm. No rock is placed on any level (the Warrior,
/// the Wizard and Xichra spawn them), so each rock here is a synthetic Box slot beside a spawned player over level 1's
/// header and an empty grid. "Falls through" is proven against a twin scene whose rock is the boulder 0x42e — a Box
/// that matches no special arm — and "hurts" against a twin that calls `.HurtPlayer` + `.KillBox` by hand.
final class FallingRockTests: XCTestCase {

    nonisolated(unsafe) private static let level1 = Result {
        try LevelFile.load(from: try FerazelData.open(try FerazelData.dataDirectory()), level: 1)
    }

    /// The rock's hot rect (the boulders' 4, 0, 0x1c, 0x1c) and the player's position: his hot-rect centre is (250, 259).
    private static let rockRect = IdleSprites.Rect(top: 4, left: 0, bottom: 0x1c, right: 0x1c)
    private static let playerAt = (x: 200, y: 200)

    private struct Scene {
        let w: SpriteWorld
        let player: Int
        let rock: Int
    }

    /// A player at `playerAt` (hp 0x400, not invulnerable, vy 300) and a Box `type` whose top-left is (236, `rockY`),
    /// its centre from its rect (y = `rockY` + 16), `+0x160 = c160`, vy `vy`.
    private func scene(_ type: Int16, c160: Int32, rockY: Int, vy: Int32) throws -> Scene {
        let w = SpriteWorld(level: try Self.level1.get())
        let empty = [UInt16](repeating: 0, count: 16 * 16)
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: empty), bg: TileMap(width: 16, height: 16, cells: empty),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        let pid = try XCTUnwrap(Player.spawn(world: w, x: Self.playerAt.x, y: Self.playerAt.y))
        w.playerID = pid
        w.active.update(id: pid) { s in
            s.x = Self.playerAt.x
            s.y = Self.playerAt.y
            s.x256 = Int32(s.x) << 8
            s.y256 = Int32(s.y) << 8
            s.oldPosition = SpriteSlot.Point(x: s.x, y: s.y)
            s.hp = 0x400
            s.invulnerable = 0
            s.vx = 0
            s.vy = 300
            s.groundKind = 0
            s.hotRect = HandleKeys.standardHotRect
            s.centre = SpriteSlot.Point(x: s.x + 0x32, y: s.y + 0x3b)
        }
        var r = SpriteSlot(type: type, x: 236, y: rockY)
        r.handler = .box
        r.hasHit = true
        r.hasTileHit = true
        r.hp = 1
        r.gravity = 0x96
        r.layer = 2
        r.recordIndex = -1
        r.x256 = Int32(236) << 8
        r.y256 = Int32(rockY) << 8
        r.oldPosition = SpriteSlot.Point(x: 236, y: rockY)
        r.hotRect = Self.rockRect
        r.centre = SpriteSlot.Point(x: 236 + 0xe, y: rockY + 4 + 0xc)
        r.classWord160 = c160
        r.vy = vy
        return Scene(w: w, player: pid, rock: w.active.insert(r))
    }

    /// Everything the arm can touch: the slots, the player globals, the stream, the particle store's count.
    private func state(_ s: Scene) -> (ActiveList, PlayerState, Int32, Int16) {
        (s.w.active, s.w.player, s.w.rng.seed, s.w.particles.counters.count)
    }

    /// The scene after `.HitPlayerSprite(player, rock)`.
    private func hit(_ type: Int16, c160: Int32, rockY: Int, vy: Int32) throws -> Scene {
        let s = try scene(type, c160: c160, rockY: rockY, vy: vy)
        HitPlayerSprite.hit(s.w, player: s.player, other: s.rock)
        return s
    }

    /// Asserts the rock hurt and broke: the scene equals a twin given `.HurtPlayer(player, rock, damage, 1, invul, 0)`
    /// and `.KillBox(rock)` by hand and nothing else (no `.PlatformBounce`, no later arm); the player lost `damage`.
    private func assertHurts(_ type: Int16, c160: Int32, rockY: Int, vy: Int32, damage: Int16, invul: Int16,
                             file: StaticString = #filePath, line: UInt = #line) throws {
        let got = try hit(type, c160: c160, rockY: rockY, vy: vy)
        let want = try scene(type, c160: c160, rockY: rockY, vy: vy)
        HurtPlayer.hurt(want.w, player: want.player, attacker: want.rock, damage: damage, blood: true,
                        invulnerable: invul, coins: 0)
        BoxSprite.killBox(want.w, id: want.rock)
        let g = state(got), e = state(want)
        XCTAssertEqual(g.0, e.0, "slots", file: file, line: line)
        XCTAssertEqual(g.1, e.1, "player globals", file: file, line: line)
        XCTAssertEqual(g.2, e.2, "stream", file: file, line: line)
        XCTAssertEqual(g.3, e.3, "particles", file: file, line: line)
        let p = try XCTUnwrap(got.w.active.record(id: got.player), file: file, line: line)
        XCTAssertEqual(p.hp, 0x400 - damage, file: file, line: line)
        XCTAssertEqual(p.invulnerable, invul, file: file, line: line)
        XCTAssertEqual(got.w.active.record(id: got.rock)?.dead, true, file: file, line: line)
        XCTAssertEqual(got.w.player.cues.last?.snd, 424, file: file, line: line)   // `.KillBox`'s break sound
    }

    /// Asserts the arm fell through: the scene equals the boulder-0x42e twin's (only the rock's type differs), the player
    /// is unhurt and the rock unbroken.
    private func assertFallsThrough(_ type: Int16, c160: Int32, rockY: Int, vy: Int32,
                                    file: StaticString = #filePath, line: UInt = #line) throws {
        let got = try hit(type, c160: c160, rockY: rockY, vy: vy)
        let twin = try hit(0x42e, c160: c160, rockY: rockY, vy: vy)
        twin.w.active.update(id: twin.rock) { $0.type = type }
        let g = state(got), e = state(twin)
        XCTAssertEqual(g.0, e.0, "slots", file: file, line: line)
        XCTAssertEqual(g.1, e.1, "player globals", file: file, line: line)
        XCTAssertEqual(g.2, e.2, "stream", file: file, line: line)
        XCTAssertEqual(g.3, e.3, "particles", file: file, line: line)
        XCTAssertEqual(got.w.active.record(id: got.player)?.hp, 0x400, file: file, line: line)
        XCTAssertEqual(got.w.active.record(id: got.rock)?.dead, false, file: file, line: line)
    }

    /// Above the player: the rock's centre y 230 < 259. Below him (landing on it): centre y 294 > 259.
    private let above = 214
    private let below = 278

    func testRock433HurtsWhenFallingOnPlayer() throws {
        // M l. 49173–49179: 0x433, `+0x160 ≥ 0`, centre y 230 < 259, vy 2000 > 599 → `.HurtPlayer(…, 0x38, 1, 0x1e, 0)`
        // + `.KillBox`, return.
        try assertHurts(0x433, c160: 0, rockY: above, vy: 2000, damage: 0x38, invul: 0x1e)
        try assertHurts(0x433, c160: 7, rockY: above, vy: 600, damage: 0x38, invul: 0x1e)
        // The compare is on shorts, signed (`*(short *)(rock + 0xe) < *(short *)(player + 0xe)`): a rock whose centre
        // is above the level's top (the Warrior's crates spawn at y −173 / −273) is above the player.
        try assertHurts(0x433, c160: 0, rockY: -20, vy: 2000, damage: 0x38, invul: 0x1e)
        // An invulnerable player: `.HurtPlayer` lands nothing, but `.KillBox` runs and the arm returns all the same.
        let s = try scene(0x433, c160: 0, rockY: above, vy: 2000)
        s.w.active.update(id: s.player) { $0.invulnerable = 5 }
        HitPlayerSprite.hit(s.w, player: s.player, other: s.rock)
        XCTAssertEqual(s.w.active.record(id: s.player)?.hp, 0x400)
        XCTAssertEqual(s.w.active.record(id: s.player)?.invulnerable, 5)
        XCTAssertEqual(s.w.active.record(id: s.rock)?.dead, true)
        XCTAssertEqual(s.w.player.cues.map(\.snd), [424])
    }

    func testRock434HurtsHarder() throws {
        // M l. 49181–49187: 0x434 with `+0x160 ≥ 0` — the same test, `.HurtPlayer(…, 0x70, 1, 0x3c, 0)` + `.KillBox`.
        try assertHurts(0x434, c160: 0, rockY: above, vy: 2000, damage: 0x70, invul: 0x3c)
        try assertHurts(0x434, c160: 3, rockY: above, vy: 600, damage: 0x70, invul: 0x3c)
        // Harder than 0x433's in both strengths.
        let a = try hit(0x433, c160: 0, rockY: above, vy: 2000), b = try hit(0x434, c160: 0, rockY: above, vy: 2000)
        let pa = try XCTUnwrap(a.w.active.record(id: a.player)), pb = try XCTUnwrap(b.w.active.record(id: b.player))
        XCTAssertEqual([Int(0x400 - pa.hp), Int(pa.invulnerable)], [0x38, 0x1e])
        XCTAssertEqual([Int(0x400 - pb.hp), Int(pb.invulnerable)], [0x70, 0x3c])
    }

    func testRock434NegativeReturnsEarly() throws {
        // M l. 49170–49172: 0x434 with `+0x160 < 0` (a Wizard's hovering rock) → return before every other arm: no
        // hurt, no `.PlatformBounce`, nothing written, no draw — whether it would hurt or the player would land on it.
        for (rockY, vy, c160) in [(above, Int32(2000), Int32(-1)), (below, 0, -1), (below, 0, -40), (above, 2000, -40)] {
            let s = try scene(0x434, c160: c160, rockY: rockY, vy: vy)
            let before = state(s)
            HitPlayerSprite.hit(s.w, player: s.player, other: s.rock)
            let after = state(s)
            XCTAssertEqual(after.0, before.0, "rockY \(rockY) vy \(vy) +0x160 \(c160)")
            XCTAssertEqual(after.1, before.1)
            XCTAssertEqual(after.2, before.2)
            XCTAssertEqual(after.3, before.3)
            // The same scene with a boulder 0x42e falls through to `.PlatformBounce` and moves the player.
            let twin = try scene(0x42e, c160: c160, rockY: rockY, vy: vy)
            let p0 = twin.w.active.record(id: twin.player)
            HitPlayerSprite.hit(twin.w, player: twin.player, other: twin.rock)
            XCTAssertNotEqual(twin.w.active.record(id: twin.player), p0, "rockY \(rockY): the geometry acts")
        }
    }

    func testRockSlowOrBelowFallsThrough() throws {
        for t: Int16 in [0x433, 0x434] {
            // Slow (vy ≤ 599, the rock resting or rising) above the player: on to `.PlatformBounce`.
            try assertFallsThrough(t, c160: 0, rockY: above, vy: 0)
            try assertFallsThrough(t, c160: 0, rockY: above, vy: -2000)
            // Below him — he lands on it — however fast it falls: on to `.PlatformBounce` (he rides it).
            try assertFallsThrough(t, c160: 0, rockY: below, vy: 2000)
            let s = try hit(t, c160: 0, rockY: below, vy: 2000)
            XCTAssertEqual(s.w.active.record(id: s.player)?.ridden, s.rock)
        }
    }

    func testRockBoundaries() throws {
        // A 0x433 with `+0x160 < 0` matches none of the three arms (M l. 49173 `-1 < +0x160` fails, 49181 and 49189 the
        // type) and falls through, even falling fast onto the player.
        try assertFallsThrough(0x433, c160: -1, rockY: above, vy: 2000)
        try assertFallsThrough(0x433, c160: -40, rockY: above, vy: 2000)
        // `-1 < +0x160`: 0 is in.
        try assertHurts(0x433, c160: 0, rockY: above, vy: 2000, damage: 0x38, invul: 0x1e)
        try assertHurts(0x434, c160: 0, rockY: above, vy: 2000, damage: 0x70, invul: 0x3c)
        // The strict `<` on the centre y (M l. 49174, 49182): equal (rock y 243 → centre 259) falls through, one pixel
        // higher hurts.
        for (t, damage, invul): (Int16, Int16, Int16) in [(0x433, 0x38, 0x1e), (0x434, 0x70, 0x3c)] {
            try assertFallsThrough(t, c160: 0, rockY: 243, vy: 2000)
            try assertHurts(t, c160: 0, rockY: 242, vy: 2000, damage: damage, invul: invul)
            // The threshold `599 < vy` (M l. 49175, 49183): 599 falls through, 600 hurts.
            try assertFallsThrough(t, c160: 0, rockY: above, vy: 599)
            try assertHurts(t, c160: 0, rockY: above, vy: 600, damage: damage, invul: invul)
        }
    }
}
