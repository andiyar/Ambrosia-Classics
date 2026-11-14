import XCTest
@testable import FerazelCore

/// 6A-W1 (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-W1`; docs/ferazel/phase6-boss-contracts.md
/// §2.3, §2.8, §2.9, §2.11): the Warrior's Handle — `.HandleWarriorSprite` (M l. 73115–73419), `.WarriorLayEgg`
/// (M l. 73080–73092), `.RandomWarriorAttack` (M l. 73095–73112), `.HitWarriorTileSprite` (M l. 73498–73530). Every
/// test opens level 5 (built) as `LevelFiveTests` does — the Warrior record 0 (x 875, y 227, p4 1) — and drives the
/// session, or the Handle alone on the session's world. Every expected draw is re-derived from a copy of the stream.
final class WarriorTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    private func session(seed: Int32 = 1) throws -> FerazelSession {
        try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 5, seed: seed)
    }

    private func warriorID(_ s: FerazelSession) throws -> Int {
        try XCTUnwrap(s.world.active.sprites.first { $0.handler == .warrior }?.id)
    }

    private func slot(_ w: SpriteWorld, _ id: Int) throws -> SpriteSlot { try XCTUnwrap(w.active.record(id: id)) }

    /// One Warrior Handle call (the session's dispatch row, without the rest of the frame).
    private func handle(_ w: SpriteWorld, _ id: Int) {
        Warrior.handle(world: w, id: id, solver: TileSolver(world: w))
    }

    /// The Warrior's crate slots `+0x1d4` / `+0x1d8` / `+0x1dc`.
    private func slots(_ s: SpriteSlot) -> [Int?] { [s.siblings.first, s.siblings.second, s.siblings.third] }

    /// The first seed ≥ 1 whose stream makes `pick` true.
    private func seed(_ pick: (inout FastRand) -> Bool) -> Int32 {
        var s: Int32 = 1
        while true {
            var r = FastRand(seed: s)
            if pick(&r) { return s }
            s += 1
        }
    }

    private func f(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }

    /// The Warrior with the arena locked, in `state`, standing where the level put it, its centre and the player's
    /// centre globals given (the decide's inputs).
    private func locked(_ s: FerazelSession, state: Int16, body: (inout SpriteSlot) -> Void = { _ in }) throws -> Int {
        let id = try warriorID(s)
        s.world.arena.locked = true
        s.world.active.update(id: id) { w in
            w.subtype = state
            body(&w)
        }
        return id
    }

    // MARK: - 1

    func testWarriorCratesFirstFrame() throws {
        let s = try session()
        let id = try warriorID(s)
        let before = try slot(s.world, id)
        XCTAssertEqual(slots(before), [nil, nil, nil])
        XCTAssertEqual(before.classWord16c, 0, "`+0x16c` starts 0")
        XCTAssertFalse(s.world.active.sprites.contains { $0.type == 0x433 })
        _ = s.step(keys: KeyState())
        let w1 = try slot(s.world, id)
        // The first Handle frame: `+0x16c` 0 − 1 < 1 → all three empty slots spawn, in slot order (M l. 73161–73182).
        let ids = slots(w1).compactMap { $0 }
        XCTAssertEqual(ids.count, 3)
        XCTAssertEqual(ids, ids.sorted(), "spawned in slot order")
        XCTAssertEqual(w1.classWord16c, -1, "decremented before the spawns")
        let crates = try ids.map { try slot(s.world, $0) }
        // (home 875 − 0xba / + 0x46 / + 0x146, y 227 − 400 / − 500 / − 400).
        XCTAssertEqual(crates.map { [$0.x, $0.y] }, [[689, -173], [945, -273], [1201, -173]])
        XCTAssertEqual(crates.map { [Int($0.x256), Int($0.y256)] },
                       [[689 << 8, -173 << 8], [945 << 8, -273 << 8], [1201 << 8, -173 << 8]])
        for c in crates {
            XCTAssertEqual(c.type, 0x433)
            XCTAssertEqual(c.handler, .box)
            XCTAssertEqual(c.layer, 2, "the Box Setup's layer (M l. 58939), not the argument 9")
            XCTAssertEqual(c.gravity, 0x100, "the rocks' arm (M l. 59055–59075)")
            XCTAssertEqual(c.hotRect, IdleSprites.Rect(top: 0, left: 4, bottom: 0x1c, right: 0x1c))
            XCTAssertEqual(c.face, f(0x42e, 0), "the boot single 0x42e (M l. 59054–59055)")
            XCTAssertEqual(c.classWord160, 0, "not hovering: `+0x160` ≥ 0")
            XCTAssertEqual(c.recordIndex, -1)
            XCTAssertEqual(c.vy, 0, "not handled on its spawn frame")
        }
        // In front of the Warrior in the list (layer 2 < 0xc): not reached by this frame's walk.
        let order = s.world.active.sprites.map(\.id)
        let wi = try XCTUnwrap(order.firstIndex(of: id))
        for c in ids { XCTAssertLessThan(try XCTUnwrap(order.firstIndex(of: c)), wi) }
        // The head's hot rect SetRect(0x2a, 0x3c, 0x89, 0x88), 10 px wider on the facing side (M l. 73144–73150).
        XCTAssertEqual(w1.hotRect, w1.mirrored ? IdleSprites.Rect(top: 0x3c, left: 0x2a, bottom: 0x88, right: 0x93)
                                               : IdleSprites.Rect(top: 0x3c, left: 0x20, bottom: 0x88, right: 0x89))
        _ = s.step(keys: KeyState())
        let w2 = try slot(s.world, id)
        XCTAssertEqual(slots(w2), slots(w1), "a falling crate keeps its slot")
        XCTAssertEqual(w2.classWord16c, 15, "all three present → `+0x16c = 15` (M l. 73186)")
        XCTAssertEqual(try ids.map { try slot(s.world, $0).vy }, [0x100, 0x100, 0x100], "each handled from frame 2")
        XCTAssertEqual(s.world.refusedSpawns, 0)

        // 2.11 items 1 and 2: `+0xe9` or `+0x1b2` → the Handle returns before `.StandardSpriteHandles` (M l.
        // 73137–73142): no crate, the invulnerability counter not stepped, the hot rect untouched.
        for (label, mark) in [("+0xe9", { (w: inout SpriteSlot) in w.dead = true }),
                              ("+0x1b2", { (w: inout SpriteSlot) in w.handleSkip = true })] {
            let t = try session()
            let tid = try warriorID(t)
            t.world.active.update(id: tid) { w in
                mark(&w)
                w.invulnerable = 5
            }
            let held = try slot(t.world, tid)
            handle(t.world, tid)
            XCTAssertEqual(try slot(t.world, tid), held, "\(label): nothing written")
            XCTAssertFalse(t.world.active.sprites.contains { $0.type == 0x433 }, "\(label): no crate")
        }
    }

    // MARK: - 2

    func testWarriorCrateRespawnAfter14Or15() throws {
        // (a) A crate killed by its own landing (`.HitBoxTileSprite` → `.KillBox`, in its Handle — crates, layer 2,
        // precede him): his Handle the same frame k empties the slot (`+0x16c` 15 → 14); the new crate comes on k + 14.
        // On level 5 the crates come to rest on the BG ledges (kind 103, `.WallBounceBG`: no `.KillBox`) and keep their
        // slots; a test-only FG ledge (level 5's own kind-3 FG tile, in memory) across row 4 under the first crate
        // (columns 21…22, x 672…735) makes its landing an FG hit at speed.
        let s = try session()
        let id = try warriorID(s)
        let g = s.world.tiles
        let solid = try XCTUnwrap(g.fg.cells.first { $0 & 0xff != 0 && g.fgKind(tile: Int($0 & 0xff) - 1) == 3 })
        var cells = g.fg.cells
        for c in 21...22 { cells[4 * g.fg.width + c] = solid }
        s.world.tiles.fg = TileMap(width: g.fg.width, height: g.fg.height, cells: cells)
        var k = 0, gone: [Int] = [], held: [Int?] = []
        for frame in 1...200 {
            let before = try slot(s.world, id)
            _ = s.step(keys: KeyState())
            let w = try slot(s.world, id)
            gone = (0..<3).filter { slots(w)[$0] == nil }
            if frame > 1 && !gone.isEmpty { k = frame; held = slots(before); break }
        }
        XCTAssertGreaterThan(k, 2, "a crate landed")
        XCTAssertEqual(gone, [0], "the first crate, on the ledge")
        var w = try slot(s.world, id)
        XCTAssertEqual(w.classWord16c, 14, "emptied on the frame it died: 15 → 14")
        // The dead crate is still a record with `+0xe9` set — killed by its own Handle this frame, before his.
        XCTAssertNotEqual(try slot(s.world, try XCTUnwrap(held[0])).killCount, 0)
        // The Warrior's current `+0xa` moved: the respawn reads it (M l. 73167, 73173, 73179).
        s.world.active.update(id: id) { $0.y = 200 }
        for frame in (k + 1)...(k + 13) {
            _ = s.step(keys: KeyState())
            w = try slot(s.world, id)
            for i in gone { XCTAssertNil(slots(w)[i], "frame \(frame): not yet") }
            XCTAssertEqual(w.classWord16c, Int32(14 - (frame - k)))
        }
        let spawnedBefore = Set(s.world.active.sprites.filter { $0.type == 0x433 }.map(\.id))
        _ = s.step(keys: KeyState())
        w = try slot(s.world, id)
        let fresh = try gone.map { try XCTUnwrap(slots(w)[$0], "frame k + 14: slot \($0) refilled") }
        XCTAssertEqual(fresh, fresh.sorted(), "in slot order")
        for (i, c) in zip(gone, fresh) {
            XCTAssertFalse(spawnedBefore.contains(c))
            let t = try slot(s.world, c)
            let dx = [-0xba, 0x46, 0x146][i], dy = [-400, -500, -400][i]
            XCTAssertEqual([t.x, t.y], [875 + dx, 200 + dy], "slot \(i): home + d, the current +0xa − h")
        }
        XCTAssertEqual(w.classWord16c, 0, "the refill frame: 1 − 1 = 0")

        // (b) A crate killed in the collide pass (after every Handle of frame k — the crush's or the player arm's
        // `.KillBox`): his next Handle (k + 1) sees it first, so the new crate comes on k + 15.
        let t = try session()
        let tid = try warriorID(t)
        for _ in 0..<3 { _ = t.step(keys: KeyState()) }
        let victim = try XCTUnwrap(slots(try slot(t.world, tid))[1])
        let kb = 3
        BoxSprite.killBox(t.world, id: victim)                    // the collide pass of frame kb
        XCTAssertEqual(slots(try slot(t.world, tid))[1], victim, "frame kb's Handle had already run")
        for frame in (kb + 1)...(kb + 14) {
            _ = t.step(keys: KeyState())
            let v = try slot(t.world, tid)
            if frame == kb + 1 { XCTAssertNil(slots(v)[1]); XCTAssertEqual(v.classWord16c, 14) }
            if frame < kb + 15 { XCTAssertNil(slots(v)[1], "frame \(frame)") }
        }
        _ = t.step(keys: KeyState())
        XCTAssertNotNil(slots(try slot(t.world, tid))[1], "frame kb + 15")

        // (c) No free record (known deviation 6, Ruling 16 widened): the full table refuses the spawn, the slot stays
        // empty and re-tries every frame, `+0x16c` keeps counting below 1, each refusal counted.
        let u = try session()
        let uid = try warriorID(u)
        for _ in 0..<2 { _ = u.step(keys: KeyState()) }
        let lost = try XCTUnwrap(slots(try slot(u.world, uid))[0])
        BoxSprite.killBox(u.world, id: lost)
        var fillers: [Int] = []
        while u.world.active.sprites.count < SpriteWorld.recordCount {
            fillers.append(u.world.active.insert(SpriteSlot(type: 1, x: -5000, y: -5000, layer: 0)))
        }
        XCTAssertEqual(u.world.refusedSpawns, 0)
        u.world.active.update(id: uid) { $0.classWord16c = 1 }
        var counts: [Int32] = []
        for _ in 0..<3 {
            handle(u.world, uid)
            let v = try slot(u.world, uid)
            XCTAssertNil(slots(v)[0], "no record: the slot stays empty")
            counts.append(v.classWord16c)
        }
        XCTAssertEqual(counts, [0, -1, -2], "`+0x16c` counts on below 1")
        XCTAssertEqual(u.world.refusedSpawns, 3, "one refused spawn a frame")
        for f in fillers { _ = u.world.active.remove(id: f) }
        handle(u.world, uid)
        let v = try slot(u.world, uid)
        XCTAssertNotNil(slots(v)[0], "a free record: the slot refilled")
        XCTAssertEqual(v.classWord16c, -3)
        XCTAssertEqual(u.world.refusedSpawns, 3)
    }

    // MARK: - 3

    func testWarriorUnlockedReturnsBeforeGravity() throws {
        let s = try session()
        let id = try warriorID(s)
        XCTAssertFalse(s.world.arena.locked)
        s.world.active.update(id: id) { w in
            w.counterA6 = 3
            w.vx = 1000
            w.vy = 0
            w.hp = 0
            w.face = nil
        }
        let start = try slot(s.world, id)
        var a6: [Int16] = []
        for _ in 0..<5 {
            let seed = s.world.rng.seed
            handle(s.world, id)
            let w = try slot(s.world, id)
            a6.append(w.counterA6)
            XCTAssertEqual(s.world.rng.seed, seed, "no R(100): the decide is not reached")
            XCTAssertEqual([w.x, w.y], [start.x, start.y], "no gravity, no motion")
            XCTAssertEqual([w.vx, w.vy], [1000, 0], "no vx × 0.5, no gravity")
            XCTAssertEqual(w.face, f(Warrior.walkSet, 0), "state 6's face, every frame (M l. 73334)")
            XCTAssertEqual(w.subtype, 6, "no death entry at HP 0 while the arena is open")
            XCTAssertEqual(w.centre, start.centre, "no `.StandardSpriteCleanup`")
        }
        XCTAssertEqual(a6, [2, 1, 0, 0, 0], "`+0xa6` counts to 0 and stays")
        XCTAssertTrue(s.world.player.cues.allSatisfy { $0.snd != 703 }, "no snd 703")

        // 2.11 item 21: locked, every state reaches `.ApplyGravityAndSeparateFromTiles` with gravity 0x122 — here state
        // 0 (no arm) in the air: one frame adds 0x122 to vy.
        let t = try session()
        let tid = try locked(t, state: 0) { w in w.vy = 0 }
        let up = try slot(t.world, tid)
        handle(t.world, tid)
        let down = try slot(t.world, tid)
        XCTAssertEqual(down.vy, 0x122, "gravity 0x122 (M l. 73399)")
        XCTAssertGreaterThan(down.y256, up.y256)
    }

    // MARK: - 4

    func testWarriorDecideDraws() throws {
        // The decide (M l. 73341–73387): r = R(100); T = 0x41 (and face the player) when |playerCY − cy| < 0x50, else
        // 0x13; r > T → state 7, `+0x46 = 1`, face 0x71c[0], `+0xa6 = R(3) + 2`; R(100) > 100 − T → run, else walk and
        // R(100) > 0x50 → `.WarriorLayEgg` (R(2)); then the bound facing. Then vx × 0.5.
        struct Case { let label: String; let near: Bool; let pick: (inout FastRand) -> Bool }
        func walkPick(near: Bool, run: Bool, egg: Bool) -> (inout FastRand) -> Bool {
            let t: Int16 = near ? 0x41 : 0x13
            return { g in
                guard t < g.next(100) else { return false }
                _ = g.next(3)
                let rr = g.next(100)
                if run { return 100 - t < rr }
                guard rr <= 100 - t else { return false }
                return egg == (0x50 < g.next(100))
            }
        }
        let cases = [Case(label: "near run", near: true, pick: walkPick(near: true, run: true, egg: false)),
                     Case(label: "near walk", near: true, pick: walkPick(near: true, run: false, egg: false)),
                     Case(label: "near walk + egg", near: true, pick: walkPick(near: true, run: false, egg: true)),
                     Case(label: "far run", near: false, pick: walkPick(near: false, run: true, egg: false)),
                     Case(label: "far walk", near: false, pick: walkPick(near: false, run: false, egg: false)),
                     Case(label: "far walk + egg", near: false, pick: walkPick(near: false, run: false, egg: true))]
        for c in cases {
            let k = seed(c.pick)
            let s = try session()
            let id = try locked(s, state: 6) { w in
                w.counterA6 = 0
                w.vx = 0x301
                w.mirrored = false
                w.x = 875
                w.centre = SpriteSlot.Point(x: 960, y: 300)
            }
            s.world.player.centreX = 1100                         // right of him: "face the player" = facing right
            s.world.player.centreY = c.near ? 300 + 0x4f : 300 + 0x50
            s.world.rng = FastRand(seed: k)
            var e = FastRand(seed: k)
            let t: Int16 = c.near ? 0x41 : 0x13
            let r = e.next(100)
            let a6 = e.next(3) + 2
            let rr = e.next(100)
            let run = 100 - t < rr
            var timer: Int32 = run ? 1 : 0, egg = false, eggTimer: Int32 = 0
            if !run && 0x50 < e.next(100) {
                egg = true
                eggTimer = Int32(e.next(2)) + 1
                timer = eggTimer
            }
            XCTAssertGreaterThan(r, t, c.label)
            handle(s.world, id)
            let w = try slot(s.world, id)
            XCTAssertEqual(s.world.rng.seed, e.seed, "\(c.label): exactly the decide's draws")
            XCTAssertEqual(w.subtype, 7, c.label)
            XCTAssertEqual(w.phase, 1, c.label)
            XCTAssertEqual(w.face, f(Warrior.walkSet, 0), c.label)
            XCTAssertEqual(w.counterA6, egg ? 5 : a6, "\(c.label): R(3) + 2, or the egg's 5")
            XCTAssertEqual(w.classTimer, timer, "\(c.label): run iff R(100) > 100 − T (35 near, 81 far); egg R(2) + 1")
            XCTAssertEqual(w.classWord154, egg ? 2 : 0, "\(c.label): the egg's `+0x154 = 2` (M l. 73087)")
            if egg { XCTAssertGreaterThan(eggTimer, 0, "the egg turns the walk into a run") }
            XCTAssertEqual(w.mirrored, c.near, "\(c.label): faces the player only when near (x inside the bounds)")
            XCTAssertEqual(w.vx, 0x180, "\(c.label): vx × 0.5 truncated after the decide (M l. 73389)")
        }
        // The bound facing after the choice (M l. 73377–73382): x > `+0x160` → left; x < `+0x15c` → right — over the
        // near "face the player".
        for (x, want) in [(1226, false), (524, true), (1225, true), (525, false)] {
            let k = seed(walkPick(near: true, run: false, egg: false))
            let s = try session()
            let id = try locked(s, state: 6) { w in
                w.counterA6 = 0
                w.x = x
                w.mirrored = !want
                w.centre = SpriteSlot.Point(x: 960, y: 300)
            }
            // Outside the bounds the player stands on the other side (the bound overrides the near facing); inside,
            // the player's side decides.
            let outside = x == 1226 || x == 524
            s.world.player.centreX = outside == want ? 800 : 1100
            s.world.player.centreY = 300
            s.world.rng = FastRand(seed: k)
            handle(s.world, id)
            XCTAssertEqual(try slot(s.world, id).mirrored, want, "x \(x)")
        }
        // The game-over flag (`*_DAT_1009ffa8`) → T = −1: any r walks or runs — even r 0 (M l. 73357–73359).
        let k0 = seed { g in g.next(100) == 0 }
        let s = try session()
        let id = try locked(s, state: 6) { w in
            w.counterA6 = 0
            w.centre = SpriteSlot.Point(x: 960, y: 300)
        }
        s.world.player.centreY = 300
        s.world.playerDead = true
        s.world.rng = FastRand(seed: k0)
        handle(s.world, id)
        XCTAssertEqual(try slot(s.world, id).subtype, 7, "r 0 > −1")
        // Without the flag r 0 attacks.
        let a = try session()
        let aid = try locked(a, state: 6) { w in
            w.counterA6 = 0
            w.centre = SpriteSlot.Point(x: 960, y: 300)
        }
        a.world.player.centreY = 300
        a.world.rng = FastRand(seed: k0)
        handle(a.world, aid)
        XCTAssertEqual(try slot(a.world, aid).subtype, 2)
        // A decide not yet due (`+0xa6` 2 → 1): no draw, vx still halved.
        let n = try session()
        let nid = try locked(n, state: 6) { w in
            w.counterA6 = 2
            w.vx = -0x301
        }
        let seed0 = n.world.rng.seed
        handle(n.world, nid)
        XCTAssertEqual(n.world.rng.seed, seed0)
        XCTAssertEqual([try slot(n.world, nid).counterA6], [1])
        XCTAssertEqual(try slot(n.world, nid).vx, -0x180, "(int)(−769 · 0.5) toward zero")
    }

    // MARK: - 5

    func testWarriorAttackDiscardsR100() throws {
        // r ≤ T → `.RandomWarriorAttack` (M l. 73095–73112): R(100) discarded (raw 10087b7c..10087b84), state 2,
        // `+0x46 = 0`, `+0x154 = 0`, `+0xa6 = 0x10`, `+0x14c = R(2) + 1`.
        for near in [true, false] {
            let t: Int16 = near ? 0x41 : 0x13
            // A seed whose discarded draw and swing draw differ in what they would give, so a skipped discard shows.
            let k = seed { g in
                guard g.next(100) <= t else { return false }
                let d = g.next(100)
                return (d & 1) != g.next(2)
            }
            let s = try session()
            let id = try locked(s, state: 6) { w in
                w.counterA6 = 0
                w.classWord154 = 3
                w.phase = 5
                w.vx = 0x200
                w.mirrored = true
                w.centre = SpriteSlot.Point(x: 960, y: 300)
            }
            s.world.player.centreX = 800
            s.world.player.centreY = near ? 300 : 500
            s.world.rng = FastRand(seed: k)
            var e = FastRand(seed: k)
            _ = e.next(100)
            _ = e.next(100)
            let swings = Int32(e.next(2)) + 1
            handle(s.world, id)
            let w = try slot(s.world, id)
            XCTAssertEqual(s.world.rng.seed, e.seed, "R(100), R(100) discarded, R(2)")
            XCTAssertEqual(w.subtype, 2)
            XCTAssertEqual(w.phase, 0)
            XCTAssertEqual(w.classWord154, 0)
            XCTAssertEqual(w.counterA6, 0x10)
            XCTAssertEqual(w.classTimer, swings, "the third draw, not the second")
            XCTAssertEqual(w.mirrored, !near, near ? "near: faced the player (left)" : "far: facing kept")
            XCTAssertEqual(w.vx, 0x100, "the decide frame's vx × 0.5")
        }
    }

    // MARK: - 6

    func testWarriorSwingTimingAndShot() throws {
        for right in [true, false] {
            let s = try session()
            let id = try locked(s, state: 2) { w in
                w.phase = 0
                w.classTimer = 2
                w.mirrored = right
                w.vx = 0x300
            }
            s.world.player.centreX = right ? 2000 : 0             // "face the player" keeps the facing
            var phases: [Int16] = [], frames = 0, shotID: Int?
            _ = s.world.player.drainFrameOutputs()
            while try slot(s.world, id).subtype == 2 && frames < 60 {
                let w0 = try slot(s.world, id)
                let n = w0.phase
                let seedBefore = s.world.rng.seed
                var e = FastRand(seed: seedBefore)
                let before = Set(s.world.active.sprites.map(\.id))
                handle(s.world, id)
                frames += 1
                phases.append(n)
                let w = try slot(s.world, id)
                let cues = s.world.player.drainFrameOutputs().cues
                XCTAssertEqual(w.vx, TileSolver.fctiwz(Double(w0.vx) * 0.4), "n \(n): vx × 0.4 (M l. 73223)")
                if n < 2 {
                    XCTAssertEqual(w.face, f(Warrior.walkSet, 0), "n \(n)")
                    XCTAssertEqual(w.mirrored, right, "n \(n): faces the player")
                } else {
                    XCTAssertEqual(w.face, f(Warrior.attackSet, Int(n >> 1) - 1), "n \(n): word (n >> 1) of 0x71d")
                }
                if n == 7 {
                    let r = Int32(e.next(6000))
                    XCTAssertEqual(cues, [PlayerCue(call: .threeDPitched, snd: 704, priority: 1, volume: 0x100,
                                                    position: w0.centre, rate: r + 50000)])
                } else {
                    XCTAssertTrue(cues.allSatisfy { $0.snd != 704 }, "n \(n)")
                }
                let made = s.world.active.sprites.map(\.id).filter { !before.contains($0) && $0 != id }
                    .filter { s.world.active.sprite(id: $0)?.type == EnemyShot.warriorShot }
                if n == 9 {
                    XCTAssertEqual(made.count, 1, "the shot on n = 9")
                    shotID = made.first
                    _ = e.next(5)                                  // its Setup's R(5) (M l. 51460)
                    let shot = try slot(s.world, try XCTUnwrap(shotID))
                    let cx = w0.centre.x, cy = w0.centre.y
                    XCTAssertEqual([shot.x, shot.y], [cx + (right ? 0x30 : -0x30) - 0x18, cy - 0x25])
                    XCTAssertEqual(shot.layer, 0, "the argument, kept by the EnemyShot Setup")
                    XCTAssertEqual(shot.vx, right ? 0xb00 : -0xb00)
                    XCTAssertEqual(shot.handler, .enemyShot)
                    XCTAssertEqual(s.world.rng.seed, e.seed, "n 9: the shot Setup's R(5) only")
                } else {
                    XCTAssertTrue(made.isEmpty, "n \(n)")
                }
                if n == 0x11 && w.subtype == 6 {
                    let a6 = e.next(9) + 4
                    XCTAssertEqual(w.counterA6, a6, "the reload R(9) + 4 (M l. 73259)")
                    XCTAssertEqual(s.world.rng.seed, e.seed)
                } else if n != 7 && n != 9 {
                    XCTAssertEqual(s.world.rng.seed, seedBefore, "n \(n): no draw")
                } else if n == 7 {
                    XCTAssertEqual(s.world.rng.seed, e.seed)
                }
            }
            // First swing n 0…17 (18 frames, the shot at the 10th), the second n 1…17 (17 frames).
            XCTAssertEqual(phases, Array(0...17) + Array(1...17), "right \(right)")
            XCTAssertEqual(frames, 35)
            XCTAssertEqual(try slot(s.world, id).subtype, 6)
            XCTAssertNotNil(shotID)
        }
        // Frame order: the shot (layer 0) goes in front of the Warrior (0xc) and is first handled the next frame.
        let s = try session()
        let id = try locked(s, state: 2) { w in
            w.phase = 9
            w.classTimer = 1
            w.mirrored = true
        }
        _ = s.step(keys: KeyState())
        let shot = try XCTUnwrap(s.world.active.sprites.first { $0.type == EnemyShot.warriorShot })
        XCTAssertNil(shot.face, "not handled on its spawn frame (its Handle sets the face)")
        let order = s.world.active.sprites.map(\.id)
        XCTAssertLessThan(try XCTUnwrap(order.firstIndex(of: shot.id)), try XCTUnwrap(order.firstIndex(of: id)))
        _ = s.step(keys: KeyState())
        XCTAssertEqual(try slot(s.world, shot.id).face, f(EnemyShot.warriorShot, 1), "handled from the next frame")
    }

    // MARK: - 7

    func testWarriorWalkRunCycles() throws {
        for run in [false, true] {
            for right in [false, true] {
                let s = try session()
                let id = try locked(s, state: 7) { w in
                    w.classTimer = run ? 1 : 0
                    w.phase = 1
                    w.counterA6 = 1
                    w.mirrored = right
                    w.x = 875
                    w.x256 = 875 << 8
                }
                var frames = 0
                let cycle = run ? 7 : 15
                while try slot(s.world, id).subtype == 7 && frames < 40 {
                    let n = try slot(s.world, id).phase
                    let seedBefore = s.world.rng.seed
                    var e = FastRand(seed: seedBefore)
                    handle(s.world, id)
                    frames += 1
                    let w = try slot(s.world, id)
                    let v: Int32 = run ? 0xc00 : 0x600
                    XCTAssertEqual(w.vx, right ? v : -v, "run \(run) n \(n)")
                    XCTAssertEqual(w.face, f(Warrior.walkSet, run ? Int(n) : Int(n >> 1)),
                                   "run \(run) n \(n): face 0x71c[n] / [n >> 1] (M l. 73286, 73310)")
                    if frames == cycle {
                        XCTAssertEqual(w.subtype, 6)
                        XCTAssertEqual(w.counterA6, e.next(9) + 4, "the reload R(9) + 4 (M l. 73296, 73320)")
                        XCTAssertEqual(s.world.rng.seed, e.seed)
                        XCTAssertEqual(w.phase, 1, "n = 0, then + 1")
                    } else {
                        XCTAssertEqual(s.world.rng.seed, seedBefore)
                        XCTAssertEqual(w.phase, n + 1)
                    }
                }
                XCTAssertEqual(frames, cycle, "run \(run): the cycle")
            }
        }
        // Two cycles with `+0xa6` 2; and the patrol bound forces `+0xa6 = 0` at the cycle's end (M l. 73290–73293).
        let s = try session()
        let id = try locked(s, state: 7) { w in
            w.classTimer = 1
            w.phase = 1
            w.counterA6 = 2
            w.mirrored = true
        }
        var frames = 0
        while try slot(s.world, id).subtype == 7 && frames < 40 { handle(s.world, id); frames += 1 }
        XCTAssertEqual(frames, 14, "two run cycles")
        for (x, left) in [(1300, true), (450, false)] {
            let t = try session()
            let tid = try locked(t, state: 7) { w in
                w.classTimer = 1
                w.phase = 7
                w.counterA6 = 9
                w.mirrored = !left
                w.x = x
                w.x256 = Int32(x) << 8
            }
            var e = FastRand(seed: t.world.rng.seed)
            handle(t.world, tid)
            let w = try slot(t.world, tid)
            XCTAssertEqual(w.subtype, 6, "x \(x): outside [525, 1225] ends the walk")
            XCTAssertEqual(w.counterA6, e.next(9) + 4)
        }
        // Inside the bounds the same cycle end only counts down.
        let i = try session()
        let iid = try locked(i, state: 7) { w in
            w.classTimer = 1
            w.phase = 7
            w.counterA6 = 9
        }
        handle(i.world, iid)
        XCTAssertEqual([try slot(i.world, iid).subtype, try slot(i.world, iid).counterA6], [7, 8])
    }

    // MARK: - 8

    func testWarriorDeathAndGlow() throws {
        // HP < 1 with state ≠ 4 → state 4, `+0x46 = +0xa6 = 0`, snd 703 (3D, 1, 0x100) (M l. 73393–73398).
        let s = try session()
        let id = try locked(s, state: 7) { w in
            w.hp = 0
            w.classTimer = 0
            w.phase = 3
            w.vx = 1000
        }
        _ = s.world.player.drainFrameOutputs()
        handle(s.world, id)
        var w = try slot(s.world, id)
        XCTAssertEqual([w.subtype, w.phase, w.counterA6], [4, 0, 0])
        let cue = try XCTUnwrap(s.world.player.drainFrameOutputs().cues.first { $0.snd == 703 })
        XCTAssertEqual([cue.call == .threeD, cue.priority == 1, cue.volume == 0x100], [true, true, true])
        // Dying (M l. 73268–73279): vx × 0.9, face 0x71e[n >> 2] (n capped at 0x17 → index ≤ 5), `+0xa6` + 1; at 0x2d
        // `+0x1a2 = 1` — dying frame 45.
        s.world.active.update(id: id) { $0.vx = 1000 }
        for frame in 1...45 {
            let w0 = try slot(s.world, id)
            handle(s.world, id)
            w = try slot(s.world, id)
            XCTAssertEqual(w.face, f(Warrior.deathSet, min(frame - 1, 0x17) >> 2), "dying frame \(frame)")
            XCTAssertEqual(w.phase, Int16(min(frame, 0x17)))
            XCTAssertEqual(w.counterA6, Int16(frame))
            if frame == 1 { XCTAssertEqual(w.vx, 900, "vx × 0.9") }
            _ = w0
            if frame < 45 { XCTAssertEqual(w.burnRow, 0, "dying frame \(frame)") }
        }
        XCTAssertNotEqual(w.burnRow, 0, "the burn starts on dying frame 45")
        XCTAssertEqual(w.subtype, 4, "no second death entry")

        // The wounded glow, boss mode only, whatever the lock (M l. 73188–73212): `+0xf0` − 1; 4…6 → 0x10009 and 1…3 →
        // 0x10008 below 1001 HP; ≤ 0 → reload 15 (below 501) or 30, `+0xb8 = 0`.
        let g = try session()
        let gid = try warriorID(g)
        XCTAssertFalse(g.world.arena.locked)
        g.world.active.update(id: gid) { w in
            w.hp = 1000
            w.voicePitch = 8
            w.mode = 0x77
        }
        var modes: [UInt32] = [], timers: [Int32] = []
        for _ in 0..<9 {
            handle(g.world, gid)
            let w = try slot(g.world, gid)
            modes.append(w.mode)
            timers.append(w.voicePitch)
        }
        XCTAssertEqual(timers, [7, 6, 5, 4, 3, 2, 1, 0x1e, 0x1d])
        XCTAssertEqual(modes, [0x77, 0x10009, 0x10009, 0x10009, 0x10008, 0x10008, 0x10008, 0, 0])
        for (hp, period) in [(Int16(500), Int32(0xf)), (Int16(501), Int32(0x1e))] {
            g.world.active.update(id: gid) { w in w.hp = hp; w.voicePitch = 1; w.mode = 0x77 }
            handle(g.world, gid)
            XCTAssertEqual([try slot(g.world, gid).voicePitch], [period], "HP \(hp)")
            XCTAssertEqual(try slot(g.world, gid).mode, 0)
        }
        // Above 1000 HP no tint is written, but the reload still clears `+0xb8`.
        g.world.active.update(id: gid) { w in w.hp = 1001; w.voicePitch = 6; w.mode = 0x77 }
        handle(g.world, gid)
        XCTAssertEqual(try slot(g.world, gid).mode, 0x77)
        g.world.active.update(id: gid) { w in w.voicePitch = 1 }
        handle(g.world, gid)
        XCTAssertEqual(try slot(g.world, gid).mode, 0)

        // 2.11 item 3: p4 = 0 (`+0x170 == 0`): no crate, `+0x16c` untouched, no glow (M l. 73151).
        let p = try session()
        let pid = try warriorID(p)
        p.world.active.update(id: pid) { w in
            w.classWord170 = 0
            w.hp = 100
            w.voicePitch = 3
            w.classWord16c = 7
            w.mode = 0x77
        }
        for _ in 0..<3 { handle(p.world, pid) }
        let q = try slot(p.world, pid)
        XCTAssertEqual([q.voicePitch, q.classWord16c], [3, 7])
        XCTAssertEqual(q.mode, 0x77)
        XCTAssertFalse(p.world.active.sprites.contains { $0.type == 0x433 })
    }

    // MARK: - 9

    func testWarriorTileCallbackIsCrawlerBody() throws {
        // `.HitWarriorTileSprite` (M l. 73498–73530) is the Crawler's body (`CrawlerRoach.hitTile`): the same writes for
        // every layer and kind band — FG any kind and BG < 100 `.WallBounce`, BG 100…199 `.WallBounceBG(kind − 100)`,
        // ≥ 200 water `.HandleUnderWater` unless `+0x140`.
        let cases: [(kind: Int, layer: TileLayer, done: Bool)] = [
            (3, .foreground, false), (150, .foreground, false), (3, .background, false), (99, .background, false),
            (100, .background, false), (0x7f, .background, false), (199, .background, false),
            (200, .background, false), (202, .background, false), (200, .background, true),
        ]
        var changed = 0
        for c in cases {
            let a = try session(), b = try session()
            var ids: [Int] = []
            for t in [a, b] {
                let id = try warriorID(t)
                t.world.active.update(id: id) { w in
                    w.x = 640; w.y = 280; w.x256 = 640 << 8; w.y256 = 280 << 8
                    w.vx = 0x300; w.vy = 0x500
                    w.underwaterDone = c.done
                }
                ids.append(id)
            }
            let before = try slot(a.world, ids[0])
            let pass = try XCTUnwrap(Warrior.pass(before), "the Setup stored `+0x1f8`")
            pass(TileSolver(world: a.world), ids[0], TilePos(x: 672, y: 320), c.kind, c.layer)
            CrawlerRoach.hitTile(TileSolver(world: b.world), id: ids[1], pos: TilePos(x: 672, y: 320), kind: c.kind,
                                 layer: c.layer)
            let wa = try slot(a.world, ids[0]), wb = try slot(b.world, ids[1])
            XCTAssertEqual(wa, wb, "kind \(c.kind) \(c.layer) done \(c.done)")
            if wa != before { changed += 1 }
            if c.done && c.kind >= 200 { XCTAssertEqual(wa, before, "`+0x140` set: no `.HandleUnderWater`") }
        }
        XCTAssertGreaterThan(changed, 4, "the bands write")
        let z = try session()
        var none = try slot(z.world, try warriorID(z))
        none.hasTileHit = false
        XCTAssertNil(Warrior.pass(none), "`+0x1f8` 0 → no callback")
        // The Handle installs it: locked, he falls onto the arena floor and stays there (vy 0 once landed).
        let s = try session()
        let id = try locked(s, state: 0)
        var ys: [Int] = []
        for _ in 0..<120 { handle(s.world, id); ys.append(try slot(s.world, id).y) }
        XCTAssertEqual(Array(Set(ys.suffix(20))).count, 1, "landed")
        XCTAssertEqual(try slot(s.world, id).groundKind != 0, true, "on ground")
    }
}
